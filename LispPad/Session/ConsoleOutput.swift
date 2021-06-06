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
    if let image = iconImage(for: drawing) {
      return ConsoleOutput(.drawingResult(Drawing(copy: drawing), image),
                           Expr.object(drawing).description)
    } else {
      return ConsoleOutput(.result, Expr.object(drawing).description)
    }
  }
  
  var description: String {
    switch self.kind {
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
}

struct ErrorContext: CustomStringConvertible, Equatable {
  let position: String?
  let library: String?
  let stackTrace: String?
  
  init(position: String? = nil, library: String? = nil, stackTrace: String? = nil) {
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
