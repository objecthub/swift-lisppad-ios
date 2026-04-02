//
//  EvalIntent.swift
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

import AppIntents
import Foundation
import LispKit

struct EvalIntent: AppIntent {
  /// The title of the intent
  static var title: LocalizedStringResource = "Evaluate program"
  
  /// The description of the intent
  static var description = IntentDescription("Takes the source code of a Scheme program and evaluates it, returning the result of the last expression.")
  
  @Parameter(title: "Program", description: "The source code of the Scheme program to execute.")
  var program: String
  
  @Parameter(title: "Argument 1", description: "First string argument for the program.")
  var string1: String?
  
  @Parameter(title: "Argument 2", description: "Second string argument for the program.")
  var string2: String?
  
  @Parameter(title: "Argument 3", description: "Third string argument for the program.")
  var string3: String?
  
  @Parameter(title: "Argument 4", description: "Fourth string argument for the program.")
  var string4: String?
  
  @Parameter(title: "File 1", description: "Binary arguments for the program.")
  var file1: IntentFile?
  
  @Parameter(title: "File 2", description: "Binary arguments for the program.")
  var file2: IntentFile?
  
  @Parameter(title: "File 3", description: "Binary arguments for the program.")
  var file3: IntentFile?
  
  @Parameter(title: "File 4", description: "Binary arguments for the program.")
  var file4: IntentFile?
  
  @Parameter(title: "Console input", description: "Console input...")
  var input: String?
  
  func perform() async throws -> some IntentResult & ReturnsValue<EvalResult> {
    // Create a console
    let console = Console()
    // Bridge between sync and async contexts to allow entering text from the console
    let bridge = InputBridge(initial: input ?? "")
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
          input = nil
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
                                        name: "<shortcut>") {
      if let res = bridge.getSyncInput() {
        return res + "\n"
      } else {
        return nil
      }
    }
    // Evaluate program
    let res = interpreter.evaluate(program)
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
        return .result(value: EvalResult(console: console, res: res!))
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
