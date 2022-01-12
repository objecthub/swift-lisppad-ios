//
//  Interpreter.swift
//  LispPad
//
//  Created by Matthias Zenger on 14/03/2021.
//  Copyright © 2021 Matthias Zenger. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation
import Combine
import LispKit

final class Interpreter: ContextDelegate, ObservableObject {
  
  // Bundle references
  static let lispKitResourcePath = LispKitContext.rootDirectory
  static let lispKitExamplePath = LispKitContext.rootDirectory + "/Examples"
  static let lispPadResourcePath = "Root"
  static let lispPadLibrariesPath = "Root/Libraries"
  static let lispPadAssetsPath = "Root/Assets"
  static let lispPadExamplePath = "Root/Examples"
  
  /// Reading status of console
  enum ReadingStatus: Equatable, CustomStringConvertible {
    case reject
    case accept
    case read(String)
    
    var description: String {
      switch self {
        case .reject:
          return "reject"
        case .accept:
          return "accept"
        case .read(let str):
          return "read(\(str))"
      }
    }
  }
  
  final class Context: LispKit.Context {
    public init(delegate: ContextDelegate) {
      super.init(delegate: delegate,
                 implementationName: LispKitContext.implementationName,
                 implementationVersion: LispKitContext.implementationVersion,
                 commandLineArguments: CommandLine.arguments,
                 initialHomePath: PortableURL.Base.documents.url?.path ??
                                  PortableURL.Base.icloud.url?.path,
                 includeInternalResources: true,
                 includeDocumentPath: "LispKit",
                 assetPath: nil,
                 gcDelay: 5.0,
                 features: Interpreter.lispKitFeatures)
    }
  }
  
  /// Class initializer
  private static func initClass() {
    // Register internal libraries
    LibraryRegistry.register(SystemLibrary.self)
    LibraryRegistry.register(AudioLibrary.self)
    LibraryRegistry.register(LocationLibrary.self)
  }
  
  /// Features of LispKit instances created by this interpreter
  public static let lispKitFeatures: [String] = {
    // Initialize the `Interpreter` class
    Interpreter.initClass()
    // Prepare feature set
    var features: [String] = ["lisppad"]
    if let provisionPath = Bundle.main.path(forResource: "embedded", ofType: "mobileprovision"),
       Foundation.FileManager.default.fileExists(atPath: provisionPath) {
      features.append("appstore")
    }
    return features
  }()
  
  /// Published state
  @Published var isReady: Bool = false
  @Published var readingStatus: ReadingStatus = .reject
  @Published var contentBatch: Int = 0
  
  /// Dependencies
  let console = Console()
  let libManager = LibraryManager()
  let envManager = EnvironmentManager()
  
  /// The context of the interpreter
  var context: Context? = nil
  
  /// Condition synchronizing changes to the published state variables
  let readingCondition = NSCondition()
  
  /// The task serializer used for Interpreter-related processing tasks
  private var serializer: TaskSerializer
  
  init() {
    self.serializer = TaskSerializer()
    self.serializer.schedule(task: self.initialize)
    self.serializer.start()
  }
  
  func completeContentBatch() {
    self.contentBatch &+= 1
  }
  
  func reset() -> Bool {
    guard self.isReady else {
      return false
    }
    self.context = nil
    self.serializer.schedule(task: self.initialize)
    return true
  }
  
  var isInitialized: Bool {
    return self.context != nil
  }
  
  func evaluate(_ command: String, reset: @escaping () -> Void) {
    self.readingCondition.lock()
    defer {
      self.readingCondition.signal()
      self.readingCondition.unlock()
    }
    guard self.isReady else {
      if self.readingStatus == .accept {
        self.readingStatus = .read(command)
        self.console.print(command + "\n")
      }
      return
    }
    self.isReady = false
    self.readingStatus = .reject
    self.serializer.schedule { [weak self] in
      if UserSettings.standard.logCommands {
        SessionLog.standard.addLogEntry(
          severity: .info,
          tag: "repl/exec",
          message: command.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines))
      }
      let res = self?.execute { machine in
        try machine.eval(str: command,
                         sourceId: SourceManager.consoleSourceId,
                         in: machine.context.global, as: "<repl>")
      }
      if UserSettings.standard.logCommands, let outputs = res {
        for output in outputs {
          if let (err, type, message) = output.logMessage {
            SessionLog.standard.addLogEntry(severity: err ? .error : .info,
                                            tag: type,
                                            message: message)
          }
        }
      }
      DispatchQueue.main.sync {
        self?.isReady = true
        self?.readingStatus = .accept
        if let res = res {
          if res.isEmpty {
            self?.console.append(output: .empty)
          } else {
            for op in res {
              self?.console.append(output: op)
            }
          }
        } else {
          reset()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
          self?.completeContentBatch()
        }
      }
    }
  }
  
  func evaluate(_ text: String, url: URL?) {
    self.readingCondition.lock()
    defer {
      self.readingCondition.signal()
      self.readingCondition.unlock()
    }
    guard self.isReady else {
      return
    }
    self.isReady = false
    self.readingStatus = .reject
    self.serializer.schedule { [weak self] in
      let res = self?.execute { machine in
        var sourceId = SourceManager.consoleSourceId
        if let url = url {
          sourceId = machine.context.sources.obtainSourceId(for: url)
        }
        return try machine.eval(str: text, sourceId: sourceId)
      }
      self?.append(result: res)
    }
  }
  
  func load(_ url: URL) {
    self.readingCondition.lock()
    defer {
      self.readingCondition.signal()
      self.readingCondition.unlock()
    }
    guard self.isReady else {
      return
    }
    self.isReady = false
    self.readingStatus = .reject
    self.serializer.schedule { [weak self] in
      let res = self?.execute { machine in
        try machine.eval(file: url.absoluteURL.path)
      }
      self?.append(result: res)
    }
  }
  
  func `import`(_ lib: [String]) {
    self.readingCondition.lock()
    defer {
      self.readingCondition.signal()
      self.readingCondition.unlock()
    }
    guard self.isReady else {
      return
    }
    self.isReady = false
    self.readingStatus = .reject
    self.serializer.schedule { [weak self] in
      let res = self?.execute { machine in
        try machine.context.environment.import(lib)
        return .void
      }
      self?.append(result: res)
    }
  }
  
  private func append(result: [ConsoleOutput]?) {
    DispatchQueue.main.sync {
      self.isReady = true
      self.readingStatus = .accept
      if let res = result {
        for op in res {
          self.console.append(output: op)
        }
      }
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        self.completeContentBatch()
      }
    }
  }
  
  private func initialize() {
    self.context = nil
    DispatchQueue.main.sync {
      self.isReady = false
      self.readingStatus = .reject
    }
    self.libManager.reset()
    self.envManager.reset()
    let context = Context(delegate: self)
    // Setup search paths
    if let internalUrl = Bundle.main.resourceURL?
                           .appendingPathComponent(Interpreter.lispPadLibrariesPath,
                                                   isDirectory: true),
       context.fileHandler.isDirectory(atPath: internalUrl.path) {
      _ = context.fileHandler.prependLibrarySearchPath(internalUrl.path)
    }
    if UserSettings.standard.foldersOnICloud,
       let librariesPath = PortableURL.Base.icloud.url?.appendingPathComponent("Libraries/").path {
      _ = context.fileHandler.prependLibrarySearchPath(librariesPath)
    }
    if UserSettings.standard.foldersOnDevice,
       let librariesPath = PortableURL.Base.documents.url?.appendingPathComponent("Libraries/").path {
      _ = context.fileHandler.prependLibrarySearchPath(librariesPath)
    }
    if let internalUrl = Bundle.main.resourceURL?
                           .appendingPathComponent(Interpreter.lispPadAssetsPath,
                                                   isDirectory: true),
       context.fileHandler.isDirectory(atPath: internalUrl.path) {
      _ = context.fileHandler.prependAssetSearchPath(internalUrl.path)
    }
    if UserSettings.standard.foldersOnICloud,
       let assetsPath = PortableURL.Base.icloud.url?.appendingPathComponent("Assets/").path {
      _ = context.fileHandler.prependAssetSearchPath(assetsPath)
    }
    if UserSettings.standard.foldersOnDevice,
       let assetsPath = PortableURL.Base.documents.url?.appendingPathComponent("Assets/").path {
      _ = context.fileHandler.prependAssetSearchPath(assetsPath)
    }
    if let internalUrl = Bundle.main.resourceURL?
                           .appendingPathComponent(Interpreter.lispPadResourcePath,
                                                   isDirectory: true),
       context.fileHandler.isDirectory(atPath: internalUrl.path) {
      _ = context.fileHandler.addSearchPath(internalUrl.path)
    }
    if UserSettings.standard.foldersOnICloud,
       let homePath = PortableURL.Base.icloud.url?.path {
      _ = context.fileHandler.addSearchPath(homePath)
    }
    if UserSettings.standard.foldersOnDevice,
       let homePath = PortableURL.Base.documents.url?.path {
      _ = context.fileHandler.addSearchPath(homePath)
    }
    // Attach file handler to library manager
    self.libManager.attachFileHandler(context.fileHandler)
    // Bootstrap context
    do {
      try context.bootstrap(forRepl: true)
    } catch {
      preconditionFailure("cannot import required lispkit libraries")
    }
    // Evaluate prelude
    let preludePath = Bundle.main.path(forResource: "Prelude",
                                       ofType: "scm",
                                       inDirectory: Interpreter.lispPadResourcePath) ??
                      LispKitContext.defaultPreludePath
    self.context = context
    do {
      _ = try context.evaluator.machine.eval(file: preludePath)
    } catch let error {
      DispatchQueue.main.sync {
        self.console.append(output: .error(error.localizedDescription,
                                           context: ErrorContext(stackTrace: "init")))
        self.isReady = true
        self.readingStatus = .accept
      }
      return
    }
    // Schedule a library list update
    self.libManager.scheduleLibraryUpdate()
    // The interpreter is ready now
    DispatchQueue.main.sync {
      self.isReady = true
      self.readingStatus = .accept
    }
  }
  
  private func execute(action: (VirtualMachine) throws -> Expr) -> [ConsoleOutput]? {
    guard let context = self.context else {
      return nil
    }
    let res = context.evaluator.execute { machine in
      try action(machine)
    }
    if context.evaluator.exitTriggered {
      // Check if we should close this interpreter
    }
    switch res {
      case .error(let err):
        if UserSettings.standard.balancedParenthesis,
           case .syntax(let error) = err.descriptor,
           context.sources.consoleIsSource(sourceId: err.pos.sourceId),
           error == .closingParenthesisMissing || error == .unexpectedClosingParenthesis {
          return nil
        } else {
          return [.error(self.errorMessage(err, in: context),
                         context: self.errorLocation(err, in: context))]
        }
      case .void:
        return []
      case .values(let expr):
        var message = ""
        var drawings: [Drawing] = []
        var allDrawings = true
        var next = expr
        while case .pair(let x, let rest) = next {
          if message.isEmpty {
            message = x.description
          } else {
            message += "\n"
            message += x.description
          }
          if case .object(let obj) = x, let drawing = obj as? Drawing {
            drawings.append(drawing)
          } else {
            allDrawings = false
          }
          next = rest
        }
        context.update(withReplResult: res)
        if allDrawings {
          if drawings.isEmpty {
            return []
          } else if drawings.count > 4 {
            return [.result(message)]
          } else {
            var res: [ConsoleOutput] = []
            for drawing in drawings {
              res.append(.drawingResult(drawing))
            }
            return res
          }
        } else {
          return [.result(message)]
        }
      case .object(let obj) where obj is Drawing:
        context.update(withReplResult: res)
        return [.drawingResult(obj as! Drawing)]
      default:
        context.update(withReplResult: res)
        return [.result(res.description)]
    }
  }
  
  private func errorMessage(_ err: RuntimeError, in context: Context) -> String {
    return err.printableDescription(context: context,
                                    typeOpen: "〚",
                                    typeClose: "〛 ",
                                    irritantHeader: "\n     • ",
                                    irritantSeparator: "\n     • ",
                                    positionHeader: nil,
                                    libraryHeader: nil,
                                    stackTraceHeader: nil)
  }
  
  private func errorLocation(_ err: RuntimeError, in context: Context) -> ErrorContext {
    var position: String? = nil
    if !err.pos.isUnknown {
      if let filename = context.sources.sourcePath(for: err.pos.sourceId) {
        position = "\(err.pos.description):\(filename)"
      } else {
        position = err.pos.description
      }
    }
    var library: String? = nil
    if let libraryName = err.library?.description {
      library = libraryName
    }
    guard let stackTrace = err.stackTrace, stackTrace.count > 0 else {
      return ErrorContext(type: err.descriptor.shortTypeDescription,
                          position: position,
                          library: library)
    }
    var res = ""
    var sep = ""
    for proc in stackTrace {
      res += sep
      res += proc.name
      sep = " ← "
    }
    return ErrorContext(type: err.descriptor.shortTypeDescription,
                        position: position,
                        library: library,
                        stackTrace: res)
  }
  
  /// Prints the given string into the console window.
  func print(_ str: String) {
    DispatchQueue.main.async {
      self.console.print(str)
    }
  }
  
  /// Reads a string from the console window.
  func read() -> String? {
    DispatchQueue.main.sync {
      self.readingStatus = .accept
    }
    self.readingCondition.lock()
    defer {
      self.readingCondition.signal()
      self.readingCondition.unlock()
    }
    // Wait for self.readingStatus turning into .read(...)
    while !self.isReady && self.readingStatus == .accept {
      self.readingCondition.wait()
    }
    if case .read(let text) = self.readingStatus {
      DispatchQueue.main.sync {
        self.readingStatus = .reject
      }
      return text + "\n"
    } else {
      DispatchQueue.main.sync {
        self.readingStatus = .reject
      }
      return nil
    }
  }
  
  public func trace(call proc: Procedure,
                    args: Exprs,
                    tailCall: Bool,
                    in machine: VirtualMachine) {
    var builder = StringBuilder()
    var offset = tailCall ? 0 : 1
    let callStack = machine.getStackTrace()
    if machine.context.evaluator.traceCalls == .byProc {
      offset += self.countTracedProcedures(callStack)
    } else {
      offset += callStack.count
    }
    let procname = proc.originalName ?? proc.name
    builder.append(tailCall ? "↪︎" : "⟶", width: offset * 2, alignRight: true)
    builder.append(" (", procname)
    for arg in args {
      builder.append(" ", arg.description)
    }
    builder.append(")")
    if let currentProc = callStack.first {
      builder.append(" in ", currentProc.originalName ?? currentProc.name)
    }
    SessionLog.standard.addLogEntry(severity: .debug,
                                    tag: "trace/call/\(procname)",
                                    message: builder.description)
  }
  
  public func trace(return proc: Procedure,
                    result: Expr,
                    tailCall: Bool,
                    in machine: VirtualMachine) {
    var builder = StringBuilder()
    var offset = tailCall ? 0 : 1
    let callStack = machine.getStackTrace()
    if machine.context.evaluator.traceCalls == .byProc {
      offset += self.countTracedProcedures(callStack)
    } else {
      offset += callStack.count
    }
    let procname = proc.originalName ?? proc.name
    builder.append("⟵", width: offset * 2, alignRight: true)
    builder.append(" ", result.description)
    builder.append(" from ", procname)
    if callStack.count > 1 {
      let currentProc = callStack[1]
      builder.append(" in ", currentProc.originalName ?? currentProc.name)
    }
    SessionLog.standard.addLogEntry(severity: .debug,
                                    tag: "trace/retn/\(procname)",
                                    message: builder.description)
  }
  
  /// This is called whenever a new library is loaded
  func loaded(library lib: Library, by: LispKit.LibraryManager) {
    DispatchQueue.main.sync {
      self.libManager.add(library: lib)
    }
  }
  
  /// This is called whenever a symbol is bound in an environment
  func bound(symbol: Symbol, in: Environment) {
    self.envManager.add(symbol: symbol)
  }

  /// This is called whenever garbage collection was called
  func garbageCollected(objectPool: ManagedObjectPool, time: Double, objectsBefore: Int) {
    if UserSettings.standard.logGarbageCollection {
      SessionLog.standard.addLogEntry(
        severity: .info,
        tag: "repl/gc/\(objectPool.cycles)",
        message: "collected \(objectsBefore - objectPool.numManagedObjects) objects in " +
                 "\(String(format: "%.2f", time * 1000.0))ms; " +
                 "\(objectPool.numManagedObjects) remain")
    }
  }
  
  /// This is called when the execution of the virtual machine got aborted.
  func aborted() {
    
  }
  
  /// This is called by the `exit` function of LispKit.
  func emergencyExit(obj: Expr?) {
    
  }
}
