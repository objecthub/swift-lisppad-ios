//
//  DefinitionView.swift
//  LispPad
//
//  Created by Matthias Zenger on 05/04/2021.
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

import SwiftUI

struct DefinitionView: View {

  enum DefinitionType: String {
    case value = "values"
    case record = "record-type"
    case syntax = "syntax"
    case type = "type"
  }

  struct Definitions: Identifiable {
    let id = UUID()
    let values: [(String, Int)]
    let syntax: [(String, Int)]
    let records: [(String, Int)]
    let types: [(String, Int)]

    var isEmpty: Bool {
      return self.values.isEmpty &&
             self.syntax.isEmpty &&
             self.records.isEmpty &&
             self.types.isEmpty
    }
  }

  @Environment(\.dismiss) var dismiss
  let defitions: Definitions
  @Binding var position: NSRange?

  var body: some View {
    ZStack(alignment: Alignment(horizontal: .trailing, vertical: .top)) {
      Color(.systemGroupedBackground).ignoresSafeArea()
      Form {
        if self.defitions.values.count > 0 {
          Section {
            ForEach(self.defitions.values, id: \.1) { tuple in
              Button(action: { self.position = NSRange(location: tuple.1, length: 0)
                               self.dismiss() }) {
                Text(tuple.0).font(.body)
              }
            }
          } header: {
            Text("Values")
              .padding(.top, 20)
          }
        }
        if self.defitions.syntax.count > 0 {
          Section {
            ForEach(self.defitions.syntax, id: \.1) { tuple in
              Button(action: { self.position = NSRange(location: tuple.1, length: 0)
                               self.dismiss() }) {
                Text(tuple.0).font(.body)
              }
            }
          } header: {
            Text("Syntax")
              .padding(.top, self.defitions.values.count == 0 ? 20 : 0)
          }
        }
        if self.defitions.records.count > 0 {
          Section {
            ForEach(self.defitions.records, id: \.1) { tuple in
              Button(action: { self.position = NSRange(location: tuple.1, length: 0)
                               self.dismiss() }) {
                Text(tuple.0).font(.body)
              }
            }
          } header: {
            Text("Records")
              .padding(.top, self.defitions.values.count + self.defitions.syntax.count == 0
                               ? 20 : 0)
          }
        }
        if self.defitions.types.count > 0 {
          Section {
            ForEach(self.defitions.types, id: \.1) { tuple in
              Button(action: { self.position = NSRange(location: tuple.1, length: 0)
                               self.dismiss() }) {
                Text(tuple.0).font(.body)
              }
            }
          } header: {
            Text("Types")
              .padding(.top, self.defitions.values.count + self.defitions.syntax.count
                               + self.defitions.records.count == 0
                               ? 20 : 0)
          }
        }
      }
      .padding(.top, LispPadUI.panelTopPadding)
      Button(action: {
        self.dismiss()
      }) {
        ExitButton()
      }
      .keyboardShortcut(KeyEquivalent.escape, modifiers: [])
      // .keyCommand(UIKeyCommand.inputEscape, modifiers: [], title: "Close sheet")
      .padding()
    }
  }

  static func parseDefinitions(_ text: String,
                               maxCount: Int = 20000,
                               maxDefs: Int = 200,
                               maxLen: Int = 60) -> Definitions? {
    let str = text as NSString
    var valueDefs: [(String, Int)] = []
    var syntaxDefs: [(String, Int)] = []
    var recordDefs: [(String, Int)] = []
    var typeDefs: [(String, Int)] = []
    var foundDefs = 0
    var index = 0
    let len = min(str.length, maxCount)
    func skipSpaces() {
      while index < len {
        let ch = str.character(at: index)
        if ch == SEMI {
          index += 1
          while index < len && str.character(at: index) != NEWLINE {
            index += 1
          }
          if index < len {
            index += 1
          }
          continue
        }
        guard let scalar = UnicodeScalar(str.character(at: index)),
              WHITESPACES.contains(scalar) else {
          return
        }
        index += 1
      }
    }
    func parseIdent() -> String? {
      guard index < len else {
        return nil
      }
      let start = index
      let ch = str.character(at: index)
      if isSpecialInitialIdent(ch) {
        guard index + 1 < len else {
          index += 1
          return asString(ch)
        }
        let ch2 = str.character(at: index + 1)
        if isDigit(ch2) {
          return nil
        } else if isInitialIdent(ch2) || isSpecialInitialIdent(ch2) {
          index += 1
        } else {
          index += 1
          return asString(ch)
        }
      } else if !isInitialIdent(ch) {
        return nil
      }
      index += 1
      while index < len && isSubsequentIdent(str.character(at: index)) {
        index += 1
      }
      return str.substring(with: NSRange(location: start, length: index - start))
    }
    // Parse text
    loop: while index + 9 < len && foundDefs < maxDefs {
      if str.character(at: index) == SEMI {
        skipSpaces()
        continue
      } else if str.character(at: index) == LPAREN {
        index += 1
        skipSpaces()
        if index + 8 < len &&
           str.character(at: index) == CD &&
           str.character(at: index + 1) == CE &&
           str.character(at: index + 2) == CF &&
           str.character(at: index + 3) == CI &&
           str.character(at: index + 4) == CN &&
           str.character(at: index + 5) == CE {
          var signatures: [(Int, String)] = []
          var deftype: DefinitionType = .value
          var location = index
          if isSpace(str.character(at: index + 6)) {
            index += 6
            skipSpaces()
            location = index
            if index < len && isInitialIdent(str.character(at: index)) {
              guard let sig = parseIdent() else {
                continue
              }
              signatures.append((location, sig))
            } else if index + 2 < len && str.character(at: index) == LPAREN {
              let save = index
              index += 1
              skipSpaces()
              var signature = ""
              var first = true
              while index < len && str.character(at: index) != RPAREN {
                var sig: String
                if str.character(at: index) == DOT {
                  sig = "."
                  index += 1
                } else {
                  guard let s = parseIdent() else {
                    index = save
                    continue loop
                  }
                  sig = s
                }
                if first {
                  signature = "("
                  first = false
                } else {
                  signature += " "
                }
                signature += sig
                skipSpaces()
              }
              if first || index == len {
                index = save
                continue
              }
              index += 1
              signature += ")"
              signatures.append((location, signature))
            } else {
              continue
            }
          } else if str.character(at: index + 6) == DASH {
            index += 7
            guard let defkind = parseIdent() else {
              continue
            }
            if defkind == DefinitionType.syntax.rawValue {
              deftype = .syntax
            } else if defkind == DefinitionType.record.rawValue {
              deftype = .record
            } else if defkind == DefinitionType.value.rawValue {
              deftype = .value
            } else if defkind == DefinitionType.type.rawValue {
              deftype = .type
            } else {
              continue
            }
            skipSpaces()
            guard index < len else {
              continue
            }
            location = index
            if deftype == .type {
              if str.character(at: index) == LPAREN {
                index += 1
                skipSpaces()
                location = index
                guard let sig = parseIdent() else {
                  continue
                }
                signatures.append((location, sig))
              } else {
                guard let sig = parseIdent() else {
                  continue
                }
                signatures.append((location, sig))
              }
            } else if deftype == .value {
              if str.character(at: index) == LPAREN {
                index += 1
                skipSpaces()
                while index + 2 < len && str.character(at: index) != RPAREN {
                  location = index
                  guard let sig = parseIdent() else {
                    break
                  }
                  signatures.append((location, sig))
                  skipSpaces()
                }
                if index < len && str.character(at: index) == RPAREN {
                  index += 1
                } else {
                  continue
                }
              } else {
                continue
              }
            } else {
              guard let sig = parseIdent() else {
                continue
              }
              signatures.append((location, sig))
            }
          } else {
            continue
          }
          var parens = 1
          while index < len && parens > 0 {
            if str.character(at: index) == RPAREN {
              parens -= 1
            } else if str.character(at: index) == LPAREN {
              parens += 1
            }
            index += 1
          }
          if parens == 0 {
            for (location, sig) in signatures {
              var signature = sig
              if signature.count > maxLen {
                signature = String(signature[..<signature.index(signature.startIndex,
                                                                offsetBy: maxLen)]) + "…"
                if signature.utf16.first! == LPAREN {
                  signature += ")"
                }
              }
              switch deftype {
                case .value:
                  valueDefs.append((signature, location))
                case .record:
                  recordDefs.append((signature, location))
                case .syntax:
                  syntaxDefs.append((signature, location))
                case .type:
                  typeDefs.append((signature, location))
              }
              foundDefs += 1
            }
          }
          continue
        }
      }
      index += 1
    }
    if (valueDefs.count + syntaxDefs.count + recordDefs.count + typeDefs.count) > 0 {
      return Definitions(values: valueDefs,
                            syntax: syntaxDefs,
                            records: recordDefs,
                            types: typeDefs)
    } else {
      return nil
    }
  }
}

struct DefinitionView_Previews: PreviewProvider {
  @State static var position: NSRange? = nil
  static var previews: some View {
    DefinitionView(
      defitions: DefinitionView.Definitions(values: [("One", 1),("Two", 2)],
                                               syntax: [("Three", 3)],
                                               records: [],
                                               types: [("Four", 4), ("Five", 5), ("Six", 6)]),
      position: $position)
  }
}
