//
//  RunProgram.swift
//  LispPad
//
//  Created by Matthias Zenger on 20/03/2026.
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
import SwiftUI
import LispKit

struct RunProgram: AppIntent {
  
  enum RunError: Error, CustomLocalizedStringResourceConvertible, CustomStringConvertible {
    case codeNotProvided
    case programNotFound(IntentFile?)
    
    var localizedStringResource: LocalizedStringResource {
      switch self {
        case .codeNotProvided:
          return "No code provided"
        case .programNotFound(let file):
          if let file {
            return "Program not found: \(file.filename)"
          } else {
            return "Program not found"
          }
      }
    }
    
    var description: String {
      switch self {
        case .codeNotProvided:
          return "No code provided"
        case .programNotFound(let file):
          if let file {
            return "Program not found: \(file.filename)"
          } else {
            return "Program not found"
          }
      }
    }
    
    var localizedDescription: String {
      return self.description
    }
  }
  
  enum Source: String, AppEnum {
    case code
    case program
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Source"
    
    static var caseDisplayRepresentations: [Source : DisplayRepresentation] = [
      .code: "Code",
      .program: "Program"
    ]
  }
  
  enum ChoiceItemStyle: Equatable {
    case plain
    case destructive
    case cancel
  }
  
  struct ChoiceItem: Equatable {
    let title: String
    let style: ChoiceItemStyle
  }
  
  /// The title of the intent
  static var title: LocalizedStringResource = "Run Program"
  
  /// The description of the intent
  static var description = IntentDescription("Executes a Scheme program with LispPad's interpreter.")

  @Parameter(title: "Source", description: "Is the code provided directly or loaded from a file?")
  var source: Source
  
  @Parameter(title: "Code",
             description: "The source code of the Scheme program to execute.",
             inputOptions: String.IntentInputOptions(capitalizationType: .none,
                                                     multiline: true,
                                                     autocorrect: false,
                                                     smartQuotes: false,
                                                     smartDashes: false))
  var code: String?
  
  @Parameter(title: "Program", description: "The file containing the program to execute.")
  var program: IntentFile?
  
  @Parameter(title: "Argument 1",
             description: "First string argument for the program.",
             inputOptions: String.IntentInputOptions(capitalizationType: .none,
                                                     multiline: false,
                                                     autocorrect: false,
                                                     smartQuotes: false,
                                                     smartDashes: false))
  var string1: String?
  
  @Parameter(title: "Argument 2",
             description: "Second string argument for the program.",
             inputOptions: String.IntentInputOptions(capitalizationType: .none,
                                                     multiline: false,
                                                     autocorrect: false,
                                                     smartQuotes: false,
                                                     smartDashes: false))
  var string2: String?
  
  @Parameter(title: "Argument 3",
             description: "Third string argument for the program.",
             inputOptions: String.IntentInputOptions(capitalizationType: .none,
                                                     multiline: false,
                                                     autocorrect: false,
                                                     smartQuotes: false,
                                                     smartDashes: false))
  var string3: String?
  
  @Parameter(title: "Argument 4",
             description: "Fourth string argument for the program.",
             inputOptions: String.IntentInputOptions(capitalizationType: .none,
                                                     multiline: false,
                                                     autocorrect: false,
                                                     smartQuotes: false,
                                                     smartDashes: false))
  var string4: String?
  
  @Parameter(title: "Attachment 1", description: "First attachment for the program.")
  var file1: IntentFile?
  
  @Parameter(title: "Attachment 2", description: "Second attachment for the program.")
  var file2: IntentFile?
  
  @Parameter(title: "Attachment 3", description: "Third attachment for the program.")
  var file3: IntentFile?
  
  @Parameter(title: "Attachment 4", description: "Fourth attachment for the program.")
  var file4: IntentFile?
  
  @Parameter(title: "Console Input",
             description: "Console input, separated by newlines.",
             inputOptions: String.IntentInputOptions(capitalizationType: .none,
                                                     multiline: false,
                                                     autocorrect: false,
                                                     smartQuotes: false,
                                                     smartDashes: false),
             inputConnectionBehavior: .never)
  var input: String?
  
  @Parameter(title: "iCloud Drive",
             description: "Enable LispPad folder on iCloud Drive.",
             default: false)
  var foldersOnICloudDrive: Bool
  
  static var parameterSummary: some ParameterSummary {
    Switch(\RunProgram.$source) {
      Case(Source.program) {
        Summary("Run \(\.$source) \(\.$program)") {
          \.$string1
          \.$string2
          \.$string3
          \.$string4
          \.$file1
          \.$file2
          \.$file3
          \.$file4
          \.$input
          \.$foldersOnICloudDrive
        }
      }
      DefaultCase {
        Summary("Run \(\.$source) \(\.$code)") {
          \.$string1
          \.$string2
          \.$string3
          \.$string4
          \.$file1
          \.$file2
          \.$file3
          \.$file4
          \.$input
          \.$foldersOnICloudDrive
        }
      }
    }
  }
  
  func confirmationDialog(prompt: String, classic: Bool = false) async -> Bool {
    do {
      if !classic, #available(iOS 26.0, *) {
        do {
          try await requestConfirmation(dialog: IntentDialog(stringLiteral: prompt))
          return true
        } catch {
          return false
        }
      } else {
        let res = try await $input.requestConfirmation(for: "",
                                                       dialog: IntentDialog(stringLiteral: prompt))
        self.input = nil
        return res
      }
    } catch {
      return false
    }
  }
  
  func choiceDialog(prompt: String, options: [ChoiceItem], classic: Bool = false) async -> Int? {
    do {
      if !classic, #available(iOS 26.0, *) {
        let alternatives: [IntentChoiceOption] = options.map { opt in
          IntentChoiceOption(title: "\(opt.title)",
                             style: opt.style == .cancel
                             ? .cancel
                             : opt.style == .destructive ? .destructive : .default)
        }
        let choice = try await requestChoice(between: alternatives,
                                             dialog: IntentDialog(stringLiteral: prompt))
        for i in alternatives.indices {
          if alternatives[i] == choice {
            return i
          }
        }
        return nil // Should never happen
      } else {
        let alternatives: [String] = options.map { opt in opt.title }
        let choice = try await $input.requestDisambiguation(
          among: alternatives, dialog: IntentDialog(stringLiteral: prompt))
        self.input = nil
        for i in alternatives.indices {
          if alternatives[i] == choice {
            return i
          }
        }
        return nil // Should never happen
      }
    } catch {
      return nil
    }
  }
  
  func readDialog(prompt: String) async -> String? {
    do {
      let result = try await $input.requestValue(IntentDialog(stringLiteral: prompt))
      self.input = nil
      return result
    } catch {
      return nil
    }
  }

  func perform() async throws -> some IntentResult & ReturnsValue<EvalResult> & ShowsSnippetView {
    // Determine what code to execute
    let code: String
    switch self.source {
      case .code:
        guard let str = self.code else {
          throw RunError.codeNotProvided
        }
        code = str
      case .program:
        guard let data = self.program?.data,
              let str = String(data: data, encoding: .utf8) else {
          throw RunError.programNotFound(self.program)
        }
        code = str
    }
    // Create a console
    let console = Console()
    // Bridge between sync and async contexts to allow entering text from the console
    let bridge = InputBridge(initial: self.input ?? "")
    self.input = nil
    // Create a task to handle async input requests
    let inputTask = Task {
      while !Task.isCancelled {
        // Wait for the interpreter to request input
        bridge.waitForInputRequest()
        // Request input from the user
        do {
          var prompt = console.lastOutputLine ?? "Console input:"
          if prompt.count > 200 {
            prompt = String(prompt.prefix(199)) + " ⃨"
          }
          let userInput = try await $input.requestValue(IntentDialog(stringLiteral: prompt))
          self.input = nil
          bridge.provideInput(userInput)
        } catch {
          // If user cancels or error occurs, provide empty string
          bridge.provideInput(nil)
          break
        }
      }
    }
    let strings: [String?] = [string1, string2, string3, string4]
    let files: [IntentFile?] = [file1, file2, file3, file4]
    // Create interpreter with a synchronous input closure
    let interpreter = IntentInterpreter(console: console,
                                        strings: strings,
                                        files: files,
                                        name: "<shortcut>",
                                        foldersOnDevice: true,
                                        foldersOnICloud: self.foldersOnICloudDrive,
                                        confirmationDialog: self.confirmationDialog,
                                        choiceDialog: self.choiceDialog,
                                        readDialog: self.readDialog) {
      if let res = bridge.getSyncInput() {
        return res + "\n"
      } else {
        return nil
      }
    }
    // Evaluate program
    let res = interpreter.evaluate(code)
    // Cancel the input task when done
    inputTask.cancel()
    // Either propagate the error or return the result
    switch res {
      case .none:
        throw EvalFailure(message: "Unknown error", transcript: console.description)
      case .error(let err):
        if let context = interpreter.context {
          throw EvalFailure(message: err.printableDescription(context: context),
                            transcript: console.description)
        } else {
          throw EvalFailure(message: err.description,
                            transcript: console.description)
        }
      default:
        let viewConsole: Console
        if case .object(let obj) = res!, let result = obj as? AppletResult {
          if let resultView = result.view {
            viewConsole = Console()
            viewConsole.content = resultView
          } else {
            viewConsole = console
          }
        } else {
          viewConsole = console
        }
        if viewConsole.isEmpty {
          return .result(value: EvalResult(console: console, res: res!))
        } else if viewConsole.content.count == 1 {
          switch viewConsole.content[0].kind {
            case .empty, .result:
              return .result(value: EvalResult(console: console, res: res!))
            default:
              return .result(value: EvalResult(console: console, res: res!),
                             view: IntentConsoleView(console: viewConsole))
          }
        } else {
          return .result(value: EvalResult(console: console, res: res!),
                         view: IntentConsoleView(console: viewConsole))
        }
    }
  }
  
  final private class InputBridge: @unchecked Sendable {
    private var input: String?
    private let requestSemaphore = DispatchSemaphore(value: 0)
    private let responseSemaphore = DispatchSemaphore(value: 0)
    private let lock = NSLock()
    
    init(initial: String) {
      self.input = initial
    }
    
    func getSyncInput() -> String? {
      self.lock.lock()
      // If we have unconsumed input, return it
      if self.input == nil {
        self.lock.unlock()
        return nil
      } else if !(self.input!.isEmpty) {
        let result = self.input
        self.input = ""
        self.lock.unlock()
        return result
      } else {
        self.lock.unlock()
      }
      // Signal the async task that we need input
      self.requestSemaphore.signal()
      // Wait for the async task to provide input
      self.responseSemaphore.wait()
      self.lock.lock()
      let result = input
      self.input = result == nil ? nil : ""
      self.lock.unlock()
      return result
    }
    
    func waitForInputRequest() {
      self.requestSemaphore.wait()
    }
    
    func provideInput(_ input: String?) {
      self.lock.lock()
      self.input = input
      self.lock.unlock()
      self.responseSemaphore.signal()
    }
  }
}
