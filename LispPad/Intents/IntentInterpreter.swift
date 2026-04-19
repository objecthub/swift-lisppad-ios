//
//  IntentInterpreter.swift
//  LispPad
//
//  Created by Matthias Zenger on 21/03/2026.
//  Copyright © 2026 Matthias Zenger. All rights reserved.
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
import AppIntents
import LispKit

final class IntentInterpreter: ContextDelegate {
  
  // Bundle references
  static let lispKitResourcePath = LispKitContext.rootDirectory
  static let lispKitExamplePath = LispKitContext.rootDirectory + "/Examples"
  static let lispPadResourcePath = "Root"
  static let lispPadLibrariesPath = "Root/Libraries"
  static let lispPadAssetsPath = "Root/Assets"
  static let lispPadExamplePath = "Root/Examples"
  
  final class Context: LispKit.Context {
    let strings: [String?]
    let files: [IntentFile?]
    let confirmationDialog: (String, Bool) async -> Bool
    let choiceDialog: (String, [RunProgram.ChoiceItem], Bool) async -> Int?
    let readDialog: (String) async -> String?
    
    public init(delegate: ContextDelegate,
                maxStackSize: Int,
                strings: [String?],
                files: [IntentFile?],
                confirmationDialog: @escaping (String, Bool) async -> Bool,
                choiceDialog: @escaping (String, [RunProgram.ChoiceItem], Bool) async -> Int?,
                readDialog: @escaping (String) async -> String?) {
      self.strings = strings
      self.files = files
      self.confirmationDialog = confirmationDialog
      self.choiceDialog = choiceDialog
      self.readDialog = readDialog
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
                 features: IntentInterpreter.lispKitFeatures,
                 limitStack: maxStackSize * 1000)
    }
  }
  
  /// Class initializer
  private static func initClass() {
    // Configure libraries
    HTTPOAuthLibrary.libraryConfig = LispPadOAuthConfig.self
  }
  
  /// Features of LispKit instances created by this interpreter
  public static let lispKitFeatures: [String] = {
    // Initialize the `Interpreter` class
    IntentInterpreter.initClass()
    // Prepare feature set
    var features: [String] = ["applet"]
    if let provisionPath = Bundle.main.path(forResource: "embedded", ofType: "mobileprovision"),
       Foundation.FileManager.default.fileExists(atPath: provisionPath) {
      features.append("appstore")
    }
    return features
  }()
  
  let console: Console
  
  let name: String
  
  /// Maximum stack size
  let maxStackSize: Int
  
  /// Maximum call trace size
  let maxCallTrace: Int
  
  /// Log commands?
  let logCommands: Bool
  
  /// Execute the prelude file before evaluating expressions
  let executePrelude: Bool

  /// Include folders on the device
  let foldersOnDevice: Bool
  
  /// Include folders on iCloud
  let foldersOnICloud: Bool
  
  let logGarbageCollection: Bool
  
  let formatString: String?
  
  let formatWidth: Int?
  
  let indentSize: Int
  
  let input: () -> String?
  
  /// The context of the interpreter
  var context: Context? = nil
  
  init(console: Console = Console(),
       strings: [String?],
       files: [IntentFile?],
       name: String = "<repl>",
       maxStackSize: Int = 10000,
       maxCallTrace: Int = 20,
       logCommands: Bool = false,
       executePrelude: Bool = false,
       foldersOnDevice: Bool = true,
       foldersOnICloud: Bool = false,
       logGarbageCollection: Bool = false,
       formatString: String? = nil,
       formatWidth: Int? = nil,
       indentSize: Int = 80,
       confirmationDialog: @escaping (String, Bool) async -> Bool,
       choiceDialog: @escaping (String, [RunProgram.ChoiceItem], Bool) async -> Int?,
       readDialog: @escaping (String) async -> String?,
       input: (() -> String?)? = nil) {
    self.console = console
    self.name = name
    self.maxStackSize = maxStackSize
    self.maxCallTrace = maxCallTrace
    self.logCommands = logCommands
    self.executePrelude = executePrelude
    self.foldersOnDevice = foldersOnDevice
    self.foldersOnICloud = foldersOnICloud
    self.logGarbageCollection = logGarbageCollection
    self.formatString = formatString
    self.formatWidth = formatWidth
    self.indentSize = indentSize
    if let input {
      self.input = input
    } else {
      self.input = { return nil }
    }
    self.initialize(strings: strings,
                    files: files,
                    confirmationDialog: confirmationDialog,
                    choiceDialog: choiceDialog,
                    readDialog: readDialog)
  }
  
  var isInitialized: Bool {
    return self.context != nil
  }
  
  func evaluate(_ command: String) -> Expr? {
    if self.logCommands {
      SessionLog.standard.addLogEntry(
        severity: .info,
        tag: "repl/exec",
        message: command.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines))
    }
    let res = self.execute { machine in
      try machine.eval(str: command,
                       sourceId: SourceManager.consoleSourceId,
                       in: machine.context.global,
                       as: self.name)
    }
    if let res, let outputs = self.output(for: res) {
      if self.logCommands {
        for output in outputs {
          if let (err, type, message) = output.logMessage {
            SessionLog.standard.addLogEntry(severity: err ? .error : .info,
                                            tag: type,
                                            message: message)
          }
        }
      }
      if outputs.isEmpty {
        self.console.append(output: .empty)
      } else {
        for op in outputs {
          self.console.append(output: op)
        }
      }
    }
    return res
  }
  
  func load(_ url: URL) -> Expr? {
    let res = self.execute { machine in
      try machine.eval(file: url.absoluteURL.path)
    }
    if let res, let outputs = self.output(for: res) {
      self.append(result: outputs)
      if self.logCommands {
        for output in outputs {
          if let (err, type, message) = output.logMessage {
            SessionLog.standard.addLogEntry(severity: err ? .error : .info,
                                            tag: type,
                                            message: message)
          }
        }
      }
    }
    return res
  }
  
  private func output(for res: Expr) -> [ConsoleOutput]? {
    guard let context = self.context else {
      return nil
    }
    switch res {
      case .error(let err):
        return [.error(self.errorMessage(err, in: context),
                       context: self.errorLocation(err, in: context))]
      case .void:
        return []
      case .values(let expr):
        var message = ""
        var drawings: [Drawing] = []
        var allDrawings = true
        var next = expr
        while case .pair(let x, let rest) = next {
          if message.isEmpty {
            message = self.format(expr: x, in: context)
          } else {
            message += "\n"
            message += self.format(expr: x, in: context)
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
          } else if drawings.count > 3 {
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
        return [.result(self.format(expr: res, in: context))]
    }
  }
  
  private func append(result: [ConsoleOutput]?) {
    if let res = result {
      for op in res {
        self.console.append(output: op)
      }
    }
  }
  
  private func initialize(strings: [String?],
                          files: [IntentFile?],
                          confirmationDialog: @escaping (String, Bool) async -> Bool,
                          choiceDialog: @escaping (String, [RunProgram.ChoiceItem], Bool) async -> Int?,
                          readDialog: @escaping (String) async -> String?) {
    self.context = nil
    let context = Context(delegate: self,
                          maxStackSize: self.maxStackSize,
                          strings: strings,
                          files: files,
                          confirmationDialog: confirmationDialog,
                          choiceDialog: choiceDialog,
                          readDialog: readDialog)
    context.evaluator.maxCallStack = self.maxCallTrace
    // Set up search paths for libraries
    if let internalUrl = Bundle.main.resourceURL?
                           .appendingPathComponent(IntentInterpreter.lispPadLibrariesPath,
                                                   isDirectory: true),
       context.fileHandler.isDirectory(atPath: internalUrl.path) {
      _ = context.fileHandler.prependLibrarySearchPath(internalUrl.path)
    }
    if self.foldersOnICloud,
       let librariesPath = PortableURL.Base.icloud.url?.appendingPathComponent("Libraries/").path {
      _ = context.fileHandler.prependLibrarySearchPath(librariesPath)
    }
    if self.foldersOnDevice,
       let librariesPath = PortableURL.Base.documents.url?.appendingPathComponent("Libraries/").path {
      _ = context.fileHandler.prependLibrarySearchPath(librariesPath)
    }
    // Set up search paths for assets
    if let internalUrl = Bundle.main.resourceURL?
                           .appendingPathComponent(IntentInterpreter.lispPadAssetsPath,
                                                   isDirectory: true),
       context.fileHandler.isDirectory(atPath: internalUrl.path) {
      _ = context.fileHandler.prependAssetSearchPath(internalUrl.path)
    }
    if self.foldersOnICloud,
       let assetsPath = PortableURL.Base.icloud.url?.appendingPathComponent("Assets/").path {
      _ = context.fileHandler.prependAssetSearchPath(assetsPath)
    }
    if self.foldersOnDevice,
       let assetsPath = PortableURL.Base.documents.url?.appendingPathComponent("Assets/").path {
      _ = context.fileHandler.prependAssetSearchPath(assetsPath)
    }
    // Set up search paths for programs
    if let internalUrl = Bundle.main.resourceURL?
                           .appendingPathComponent(IntentInterpreter.lispPadResourcePath,
                                                   isDirectory: true),
       context.fileHandler.isDirectory(atPath: internalUrl.path) {
      _ = context.fileHandler.prependSearchPath(internalUrl.path)
    }
    if self.foldersOnICloud,
       let homePath = PortableURL.Base.icloud.url?.path {
      _ = context.fileHandler.prependSearchPath(homePath)
    }
    if self.foldersOnDevice,
       let homePath = PortableURL.Base.documents.url?.path {
      _ = context.fileHandler.prependSearchPath(homePath)
    }
    // Bootstrap context
    do {
      try context.bootstrap(forRepl: true)
    } catch {
      preconditionFailure("cannot import required lispkit libraries")
    }
    // Evaluate prelude
    let preludePath = context.fileHandler.filePath(forFile: "Prelude") ??
                      Bundle.main.path(forResource: "Prelude",
                                       ofType: "scm",
                                       inDirectory: IntentInterpreter.lispPadResourcePath) ??
                      LispKitContext.defaultPreludePath
    self.context = context
    do {
      _ = try context.evaluator.machine.eval(file: preludePath)
    } catch let error {
     self.console.append(output: .error(error.localizedDescription,
                                        context: ErrorContext(stackTrace: "init")))
      return
    }
  }
  
  private func format(expr: Expr, in context: Context) -> String {
    if let formatString,
       let str = try? context.formatter.format(formatString,
                                               config: context.formatter.replFormatConfig,
                                               locale: Locale.current,
                                               tabsize: self.indentSize,
                                               linewidth: self.formatWidth ?? 80,
                                               arguments: [expr]) {
      return str
    } else {
      return expr.description
    }
  }
  
  private func execute(action: (VirtualMachine) throws -> Expr) -> Expr? {
    guard let context = self.context else {
      return nil
    }
    let res = context.evaluator.execute { machine in
      try action(machine)
    }
    if context.evaluator.exitTriggered {
      // Check if we should close this interpreter
    }
    return res
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
    if let callTrace = err.callTrace {
      for call in callTrace {
        res += sep
        res += call
        sep = " ← "
      }
      if stackTrace.count > callTrace.count {
        res += sep
        if stackTrace.count == callTrace.count + 1 {
          res += "+1 call"
        } else {
          res += "+\(stackTrace.count - callTrace.count) calls"
        }
      }
    } else {
      for proc in stackTrace {
        res += sep
        res += proc.name
        sep = " ← "
      }
    }
    return ErrorContext(type: err.descriptor.shortTypeDescription,
                        position: position,
                        library: library,
                        stackTrace: res)
  }
  
  /// Prints the given string into the console window.
  func print(_ str: String) {
    self.console.print(str, capOutput: false)
  }
  
  /// Reads a string from the user
  func read() -> String? {
    return self.input()
  }
  
  /// This is called whenever a new library is loaded
  func loaded(library lib: Library, by: LispKit.LibraryManager) {
    
  }
  
  /// This is called whenever a symbol is bound in an environment
  func bound(symbol: Symbol, in: LispKit.Environment) {
    
  }

  /// This is called whenever garbage collection was called
  func garbageCollected(objectPool: ManagedObjectPool, time: Double, objectsBefore: Int) {
    if self.logGarbageCollection {
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
