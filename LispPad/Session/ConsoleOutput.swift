//
//  ConsoleOutput.swift
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
import UIKit
import LispKit

struct ConsoleOutput: CustomStringConvertible, Identifiable, Equatable {
  
  enum Kind: Equatable {
    case empty
    case info
    case command
    case output
    case error(ErrorContext?)
    case result
    case drawingResult(Drawing, UIImage)
  }
  
  let id = UUID()
  let kind: Kind
  var text: String
  
  private init(_ kind: Kind, _ text: String) {
    self.kind = kind
    self.text = text
  }
  
  static var empty: ConsoleOutput {
    return ConsoleOutput(.empty, "")
  }
  
  static func info(_ text: String) -> ConsoleOutput {
    return ConsoleOutput(.info, text)
  }
  
  static func command(_ text: String) -> ConsoleOutput {
    return ConsoleOutput(.command, text)
  }
  
  static func output(_ text: String) -> ConsoleOutput {
    return ConsoleOutput(.output, text)
  }
  
  static func error(_ text: String, context: ErrorContext? = nil) -> ConsoleOutput {
    return ConsoleOutput(.error(context), text)
  }
  
  static func result(_ text: String = "") -> ConsoleOutput {
    return ConsoleOutput(.result, text)
  }
  
  static func drawingResult(_ drawing: Drawing) -> ConsoleOutput {
    if drawing.numInstructions > 0, let image = iconImage(for: drawing) {
      return ConsoleOutput(.drawingResult(Drawing(copy: drawing), image),
                           Expr.object(drawing).description)
    } else {
      return ConsoleOutput(.result, Expr.object(drawing).description)
    }
  }
  
  var textOutput: ConsoleOutput {
    if case .drawingResult(_, _) = self.kind {
      return ConsoleOutput(.result, self.text)
    } else {
      return self
    }
  }
  
  var logMessage: (Bool, String, String)? {
    switch self.kind {
      case .error(let ctxt):
        var res = self.text
        if let context = ctxt, !context.description.isEmpty {
          res += "\n" + context.description
        }
        if let type = ctxt?.type {
          return (true, "repl/err/\(type)", res)
        } else {
          return (true, "repl/err", res)
        }
      case .result,
           .drawingResult(_, _):
        return (false, "repl/res", self.text)
      default:
        return nil
    }
  }
  
  var description: String {
    switch self.kind {
      case .empty:
        return ""
      case .info:
        return "ℹ️ " + self.text
      case .command:
        return "▶︎ " + self.text
      case .output:
        return self.text
      case .error(let ctxt):
        var res = "⚠️ "
        res += self.text
        if let context = ctxt, !context.description.isEmpty {
          res += "\n" + context.description
        }
        return res
      case .result:
        return self.text
      case .drawingResult(_, _):
        return self.text
    }
  }
  
  var isError: Bool {
    guard case .error(_) = self.kind else {
      return false
    }
    return true
  }
  
  var isResult: Bool {
    switch self.kind {
      case .result, .drawingResult(_, _), .error(_):
        return true
      default:
        return false
    }
  }
}

struct ErrorContext: CustomStringConvertible, Equatable {
  let type: String?
  let position: String?
  let library: String?
  let stackTrace: String?
  
  init(type: String? = nil,
       position: String? = nil,
       library: String? = nil,
       stackTrace: String? = nil) {
    self.type = type
    self.position = position
    self.library = library
    self.stackTrace = stackTrace
  }
  
  var description: String {
    var res = ""
    if let pos = self.position {
      res += "position: \(pos)"
    }
    if let lib = self.library {
      if !res.isEmpty {
        res += "\n"
      }
      res += "library: \(lib)"
    }
    if let stack = self.stackTrace {
      if !res.isEmpty {
        res += "\n"
      }
      res += "stack trace: \(stack)"
    }
    return res
  }
}
