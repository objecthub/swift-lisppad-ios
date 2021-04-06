//
//  CodeEditorView.swift
//  LispPad
//
//  Created by Matthias Zenger on 28/03/2021.
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

struct CodeEditorView: View {
  @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

  @State var text: String = "This is a test"
  @State var position: NSRange? = nil
  @State var searchHistory: [String] = []
  @State var showSearchField: Bool = false
  @State var definitions: DefinitionMenu? = nil
  @State var documentPickerAction: InterpreterView.DocumentPickerAction? = nil
  
  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      if self.showSearchField {
        SearchField(showSearchField: $showSearchField,
                    searchHistory: $searchHistory,
                    maxHistory: 10) { str, initial in
          let text = self.text as NSString
          let result = text.range(of: str,
                                  options: [.diacriticInsensitive],
                                  range: NSRange(location: 0, length: text.length), locale: nil)
          if result.location != NSNotFound {
            self.position = result
            return true
          } else {
            return false
          }
        }
        .font(.subheadline)
        Divider()
      }
      CodeEditor(text: $text, position: $position)
        .defaultFont(.monospacedSystemFont(ofSize: 13, weight: .regular))
        .autocorrectionType(.no)
        .autocapitalizationType(.none)
        .multilineTextAlignment(.leading)
        .keyboardType(.default)
      Divider()
    }
    .navigationBarHidden(false)
    .navigationBarTitle("Untitled.scm", displayMode: .inline)
    .navigationBarBackButtonHidden(true)
    .navigationBarItems(
      leading: HStack(alignment: .center, spacing: 14)  {
        Button(action: {
          self.presentationMode.wrappedValue.dismiss()
        }) {
          Image(systemName: "terminal")
            .font(Font.system(size: InterpreterView.toolbarItemSize, weight: .light))
        }
        Menu {
          Button(action: {
            
          }) {
              Label("New File", systemImage: "square.and.pencil")
          }
          Button(action: {
            self.documentPickerAction = .editFile
          }) {
              Label("Edit File…", systemImage: "doc.text")
          }
          Button(action: {
            self.documentPickerAction = .executeFile
          }) {
              Label("Execute File…", systemImage: "arrow.down.doc")
          }
          Divider()
          Button(action: {
            self.documentPickerAction = .organizeFiles
          }) {
            Label("Organize Files…", systemImage: "doc.on.doc")
          }
        } label: {
          Image(systemName: "doc")
            .font(.system(size: InterpreterView.toolbarItemSize, weight: .light))
        }
        .sheet(item: $documentPickerAction,
               onDismiss: { },
               content: { action in
                 DocumentPicker("Select file to edit",
                                fileType: .file,
                                action: { url in print("selected \(url)") })})
      },
      trailing:
        HStack(alignment: .center, spacing: 12) {
          Button(action: {
            
          }) {
            Image(systemName: "list.bullet.indent")
              .font(Font.system(size: InterpreterView.toolbarItemSize, weight: .light))
          }
          .disabled(self.showSearchField)
          Button(action: {
            self.definitions = self.determineDefinitions(self.text)
          }) {
            Image(systemName: "f.cursive")
              .font(Font.system(size: InterpreterView.toolbarItemSize, weight: .light))
          }
          .disabled(self.showSearchField)
          .sheet(item: $definitions) { defs in 
            DefinitionView(defitions: defs, position: $position)
          }
          Button(action: {
            withAnimation(.default) {
              self.showSearchField = true
            }
          }) {
            Image(systemName: "magnifyingglass")
              .font(Font.system(size: InterpreterView.toolbarItemSize, weight: .light))
          }
          .disabled(self.showSearchField)
        })
  }
  
  func determineDefinitions(_ text: String,
                            maxCount: Int = 10000,
                            maxDefs: Int = 100,
                            maxLen: Int = 60) -> DefinitionMenu? {
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
      return DefinitionMenu(values: valueDefs,
                            syntax: syntaxDefs,
                            records: recordDefs,
                            types: typeDefs)
    } else {
      return nil
    }
  }
}

enum DefinitionType: String {
  case value = "values"
  case record = "record-type"
  case syntax = "syntax"
  case type = "type"
}

struct DefinitionMenu: Identifiable {
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

struct CodeEditorView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationView {
      CodeEditorView()
        .environmentObject(DocumentationManager())
    }
  }
}
