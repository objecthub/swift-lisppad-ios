//
//  DocumentationManager.swift
//  LispPad
//
//  Created by Matthias Zenger on 23/03/2021.
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
import MarkdownKit
import UIKit

final class DocumentationManager: ObservableObject {

  private class LibraryDocumentation {
    fileprivate var content: Block? = nil
    private(set) fileprivate var symbolDocs: [String : (String, Blocks)] = [:]
    
    func enter(for sym: String, ofType type: String, doc: Blocks) {
      self.symbolDocs[sym] = (type, doc)
    }

    func doc(for sym: String) -> (String, Blocks)? {
      return self.symbolDocs[sym]
    }
  }
  
  @Published var initialized: Bool = false
  
  private var documentation: [[String] : LibraryDocumentation] = [:]
  private var completions: [String] = []
  private var symbols: Set<String> = []
  
  /// The initializer loads the documentation dictionary and extracts all information
  /// from the linked files.
  init() {
    DispatchQueue.global(qos: .userInitiated).async {
      if let url = Bundle.main.url(forResource: "Documentation", withExtension: "plist"),
         let docConfig = NSDictionary(contentsOf: url),
         let builtinDocs = docConfig.value(forKey: "builtin") as? [String : Any],
         let baseUrl = Bundle.main.url(forResource: "Libraries",
                                       withExtension: nil,
                                       subdirectory: "Documentation") {
        self.loadMarkdownFiles(builtinDocs, baseUrl: baseUrl)
      }
      for libDocs in self.documentation.values {
        for symbol in libDocs.symbolDocs.keys {
          self.insertCompletion(symbol)
          self.insertSymbol(symbol)
        }
      }
      DispatchQueue.main.async {
        self.initialized = true
      }
    }
  }
  
  /// Returns the documentation for the given library name
  func libraryDocumentation(for expr: Expr) -> Block? {
    return self.documentation[self.libName(expr)]?.content
  }
  
  /// Returns a documentation for the given symbol name
  func documentation(for name: String) -> Block? {
    var documentation = Blocks()
    for (lib, libDocs) in self.documentation {
      if let (type, docs) = libDocs.doc(for: name) {
        if !documentation.isEmpty {
          documentation.append(.paragraph(Text()))
        }
        var text = Text(.text("(\(lib.joined(separator: " ")))"))
        text.append(fragment: .text(Substring(type)))
        documentation.append(.heading(6, text))
        documentation.append(contentsOf: docs)
      }
    }
    guard !documentation.isEmpty else {
      return nil
    }
    return .document(documentation)
  }
  
  /// Returns true if there is documentation for the given symbol name
  func hasDocumentation(for name: String) -> Bool {
    for (_, libDocs) in self.documentation {
      if libDocs.doc(for: name) != nil {
        return true
      }
    }
    return false
  }
  
  /// Returns completions for the given name
  func completion(for name: String) -> [String] {
    let start = self.completionIndex(for: name).0
    var end = start
    while end < self.completions.count && self.completions[end].hasPrefix(name) {
      end += 1
    }
    return [String](self.completions[start..<end])
  }

  /// Returns `true` if documentation is available for the given symbol name
  func documentationAvailable(for name: String) -> Bool {
    return self.symbols.contains(name)
  }
  
  // Helper functions for Documentations

  private func loadMarkdownFiles(_ docPlist: [String : Any], baseUrl: URL) {
    for (lib, path) in docPlist {
      if let path = path as? String {
        self.loadMarkdownFile(baseUrl.appendingPathComponent(path), for: lib)
      }
    }
  }

  private func loadMarkdownFile(_ url: URL, for lib: String) {
    guard let content = try? String(contentsOf: url) else {
      return
    }
    let libName = lib.components(separatedBy: " ")
    let libDocs: LibraryDocumentation
    if let docs = self.documentation[libName] {
      libDocs = docs
    } else {
      libDocs = LibraryDocumentation()
      self.documentation[libName] = libDocs
    }
    let normalizedContent =
      content.replacingOccurrences(of: "<span style=\"float:right;text-align:rigth;\">",
                                   with: "&nbsp;&nbsp;&nbsp;")
             .replacingOccurrences(of: "</span>  ", with: "  ")
    let markdown = MarkdownParser.standard.parse(normalizedContent)
    guard case .document(_) = markdown else {
      return
    }
    libDocs.content = markdown
    self.insertDefinitionDocs(MarkdownParser.standard.parse(content), into: libDocs)
  }

  private func isolateName(_ str: Substring) -> String {
    let name =
      String(str.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).prefix(while: {
              (ch: Character) -> Bool in
                !CharacterSet.whitespacesAndNewlines.contains(ch.unicodeScalars.first!)
            }))
    return name
  }

  private func nameAndType(_ text: Text) -> (Substring, Substring)? {
    guard text.count >= 6,
          case .strong(let signature) = text[0] else {
      return nil
    }
    if signature.count == 1 {
      guard case .text(let nameStr) = signature[0],
            case .text(_) = text[1],
            case .html(let spanOpen) = text[2],
            spanOpen.starts(with: "span style="),
            case .delimiter("[", 1, _) = text[3],
            case .text(let typeStr) = text[4],
            case .delimiter("]", 1, _) = text[5] else {
        return nil
      }
      return (nameStr, typeStr)
    }
    guard signature.count >= 3,
          case .delimiter("(", 1, _) = signature[0],
          case .text(let nameStr) = signature[1],
          case .delimiter(")", 1, _) = signature.last!,
          case .text(_) = text[1],
          case .html(let spanOpen) = text[2],
          spanOpen.starts(with: "span style="),
          case .delimiter("[", 1, _) = text[3],
          case .text(let typeStr) = text[4],
          case .delimiter("]", 1, _) = text[5] else {
      return nil
    }
    return (nameStr, typeStr)
  }

  private func signature(_ text: Text) -> ([String], String, Text)? {
    guard let (nameStr, typeStr) = self.nameAndType(text) else {
      return nil
    }
    var sigtext = Text(text.first!)
    var names: [String] = []
    names.append(self.isolateName(nameStr))
    var i = 6
    while i < text.count - 1 {
      if case .hardLineBreak = text[i],
         case .strong(let signature) = text[i + 1] {
        if signature.count >= 3,
           case .delimiter("(", 1, _) = signature[0],
           case .text(let nameStr) = signature[1],
           case .delimiter(")", 1, _) = signature.last!,
           !nameStr.contains("...") {
          names.append(self.isolateName(nameStr))
          sigtext.append(fragment: .hardLineBreak)
          sigtext.append(fragment: text[i + 1])
          i += 1
        } else if signature.count == 1,
               case .text(let nameStr) = signature[0] {
          names.append(self.isolateName(nameStr))
          sigtext.append(fragment: .hardLineBreak)
          sigtext.append(fragment: text[i + 1])
          i += 1
        }
      }
      i += 1
    }
    let type = typeStr.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    return (names, type, sigtext)
  }

  private func terminating(_ block: Block) -> Bool {
    switch block {
      case .paragraph(let text):
        return self.nameAndType(text) != nil
      case .thematicBreak,
           .heading(_, _),
           .referenceDef(_, _, _):
        return true
      default:
        return false
    }
  }

  private func insertDefinitionDocs(_ doc: Block, into libDocs: LibraryDocumentation) {
    guard case .document(let blocks) = doc else {
      return
    }
    var index = blocks.startIndex
    while index < blocks.endIndex {
      if case .paragraph(let text) = blocks[index],
         let (names, type, sigtext) = self.signature(text) {
        var docs = Blocks()
        docs.append(.paragraph(sigtext))
        index = blocks.index(after: index)
        while index < blocks.endIndex && !terminating(blocks[index]) {
          docs.append(blocks[index])
          index = blocks.index(after: index)
        }
        for name in names {
          libDocs.enter(for: name, ofType: type, doc: docs)
        }
        continue
      }
      index = blocks.index(after: index)
    }
  }
  
  // Helper functions for completions
  
  private func insertCompletion(_ str: String) {
    let (index, exists) = self.completionIndex(for: str)
    if !exists {
      self.completions.insert(str, at: index)
    }
  }
  
  private func completionIndex(for str: String) -> (Int, Bool) {
    var lo = 0
    var hi = self.completions.count - 1
    while lo <= hi {
      let mid = (lo + hi)/2
      if self.completions[mid] < str {
        lo = mid + 1
      } else if str < self.completions[mid] {
        hi = mid - 1
      } else {
        return (mid, true)
      }
    }
    return (lo, false)
  }

  // Helper functions for symbols and expressions

  private func insertSymbol(_ str: String) {
    self.symbols.insert(str)
  }
  
  private func libName(_ expr: Expr) -> [String] {
    var res: [String] = []
    var list = expr
    while case .pair(let component, let next) = list {
      res.append(component.description)
      list = next
    }
    return res
  }
}
