//
//  Console.swift
//  LispPad
//
//  Created by Matthias Zenger on 05/12/2021.
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

final class Console: ObservableObject, CustomStringConvertible {
  @Published var content: [ConsoleOutput] = []
  
  var isEmpty: Bool {
    self.content.isEmpty
  }
  
  func append(output: ConsoleOutput) {
    let max = UserSettings.standard.maxConsoleHistory
    while self.content.count >= (max + 50) {
      self.content.removeFirst(self.content.count - max)
    }
    if let last = self.content.last,
       case .output = last.kind,
       last.text.last == "\n" {
      self.content[self.content.count - 1].text = String(last.text.dropLast())
    }
    self.content.append(output)
  }
  
  func print(_ str: String, capOutput: Bool = true) {
    if self.content.isEmpty {
      self.append(output: .output(str))
    } else if let last = self.content.last,
              last.kind == .output {
      if !capOutput || last.text.count < 1000 {
        self.content[self.content.count - 1].text += str
      } else if str.first == "\n" {
        self.append(output: .output(String(str.dropFirst())))
      } else if last.text.last == "\n" {
        let str = String(self.content[self.content.count - 1].text.dropLast())
        self.content[self.content.count - 1].text = str
        self.append(output: .output(str))
      } else {
        self.append(output: .output(str))
      }
    } else {
      self.append(output: .output(str))
    }
  }
  
  func removeLast() {
    self.content.removeLast()
  }
  
  func reset() {
    self.content.removeAll()
  }
  
  var lastOutputId: UUID? {
    return self.content.isEmpty ? nil : self.content[self.content.endIndex - 1].id
  }
  
  var lastOutputLine: String? {
    if case .output = self.content.last?.kind {
      let text = self.content.last!.text
      if !text.isEmpty,
         !text.hasSuffix("\n"),
         let i = text.lastIndex(of: "\n") {
        return String(text[text.index(after: i)...])
      } else {
        return text
      }
    } else {
      return nil
    }
  }
  
  var description: String {
    var res = ""
    for output in self.content {
      if output.kind != .empty {
        res += output.description
        res += "\n"
      }
    }
    return res
  }
}
