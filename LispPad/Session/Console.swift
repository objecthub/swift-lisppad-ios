//
//  Console.swift
//  LispPad
//
//  Created by Matthias Zenger on 05/12/2021.
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
  
  func print(_ str: String) {
    if self.content.isEmpty {
      self.append(output: .output(str))
    } else if let last = self.content.last,
              last.kind == .output {
      if last.text.count < 1000 {
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
