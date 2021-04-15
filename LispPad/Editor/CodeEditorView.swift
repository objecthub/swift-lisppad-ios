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
  
  @EnvironmentObject var fileManager: FileManager
  @EnvironmentObject var histManager: HistoryManager
  @EnvironmentObject var interpreter: Interpreter
  
  @State var position: NSRange? = nil
  @State var searchHistory: [String] = []
  @State var showSearchField: Bool = false
  @State var definitions: DefinitionMenu? = nil
  @State var documentPickerAction: InterpreterView.DocumentPickerAction? = nil
  @State var showAbortAlert = false
  @State var notSavedAlertAction: NotSavedAlertAction? = nil
  @State var showFileMover = false
  @State var fileMoverAction: (() -> Void)? = nil
  @State var forceEditorUpdate = false
  
  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      if self.showSearchField {
        SearchField(showSearchField: $showSearchField,
                    forceEditorUpdate: $forceEditorUpdate,
                    searchHistory: $searchHistory,
                    maxHistory: 10) { str, initial in
          let doc = self.fileManager.editorDocument
          let text = (doc?.text ?? "") as NSString
          let pos = initial ? 0 : (doc?.selectedRange.location ?? 0) +
                                    ((doc?.selectedRange.length ?? 0) > 0 ? 1 : 0)
          let result = text.range(of: str,
                                  options: [.diacriticInsensitive],
                                  range: NSRange(location: pos, length: text.length - pos),
                                  locale: nil)
          if result.location != NSNotFound {
            self.position = result
            return true
          } else {
            return false
          }
        }
        .font(.callout)
        Divider()
      }
      CodeEditor(text: .init(
                         get: { self.fileManager.editorDocument?.text ?? "" },
                         set: { if let doc = self.fileManager.editorDocument { doc.text = $0 }}),
                 selectedRange: .init(
                                  get: { self.fileManager.editorDocument?.selectedRange ??
                                           NSRange(location: 0, length: 0) },
                                  set: { if let doc = self.fileManager.editorDocument {
                                           doc.selectedRange = $0
                                         }
                                       }),
                 position: $position,
                 forceUpdate: $forceEditorUpdate)
        .defaultFont(.monospacedSystemFont(ofSize: 12, weight: .regular))
        .autocorrectionType(.no)
        .autocapitalizationType(.none)
        .multilineTextAlignment(.leading)
        .keyboardType(.default)
      Divider()
    }
    .navigationBarHidden(false)
    .navigationBarTitle(self.fileManager.editorDocument?.title ?? "Untitled", displayMode: .inline)
    .navigationBarBackButtonHidden(true)
    .navigationBarItems(
      leading: HStack(alignment: .center, spacing: 14)  {
        Button(action: {
          self.presentationMode.wrappedValue.dismiss()
        }) {
          Image(systemName: "terminal.fill")
          // .font(InterpreterView.toolbarFont)
        }
        Menu {
          Button(action: {
            if (self.fileManager.editorDocument?.new ?? false) &&
               !(self.fileManager.editorDocument?.text.isEmpty ?? true) {
              self.notSavedAlertAction = .newFile
            } else {
              self.fileManager.newEditorDocument(action: { success in
                self.forceEditorUpdate = true
              })
            }
          }) {
            Label("New", systemImage: "square.and.pencil")
          }
          Button(action: {
            if (self.fileManager.editorDocument?.new ?? false) &&
               !(self.fileManager.editorDocument?.text.isEmpty ?? true) {
              self.notSavedAlertAction = .editFile
            } else {
              self.documentPickerAction = .editFile
            }
          }) {
            Label("Open…", systemImage: "doc.badge.plus")
          }
          Button(action: {
            self.showFileMover = true
          }) {
            Label((self.fileManager.editorDocument?.new ?? true) ?
                     "Save…" : "Save As…", systemImage: "arrow.down.doc")
          }
          Divider()
          if !self.histManager.recentlyEdited.isEmpty {
            ForEach(self.histManager.recentlyEdited, id: \.self) { purl in
              if let url = purl.url {
                Button(action: {
                  self.fileManager.loadEditorDocument(
                    source: url,
                    makeUntitled: !purl.mutable,
                    action: { success in self.forceEditorUpdate = true })
                }) {
                  Label(url.lastPathComponent, systemImage: "doc.text")
                }
              }
            }
            Divider()
          }
          Button(action: {
            self.documentPickerAction = .organizeFiles
          }) {
            Label("Organize…", systemImage: "doc.on.doc")
          }
        } label: {
          Image(systemName: "doc")
          // .font(InterpreterView.toolbarFont)
        }
        .alert(item: $notSavedAlertAction) { alertAction in
          if alertAction == .newFile {
            return self.notSavedAlert(save: {
                                        self.fileMoverAction = {
                                          self.fileManager.newEditorDocument(action: { success in
                                            self.forceEditorUpdate = true
                                          })
                                        }
                                        self.showFileMover = true },
                                      discard: {
                                        self.fileManager.editorDocument?.text = ""
                                        self.fileManager.editorDocument?.saveFile(action: { succ in
                                          self.forceEditorUpdate = true })})
          } else {
            return self.notSavedAlert(save: {
                                        self.fileMoverAction = {
                                          self.documentPickerAction = .editFile
                                        }
                                        self.showFileMover = true },
                                      discard: {
                                        self.fileManager.editorDocument?.text = ""
                                        self.documentPickerAction = .editFile })
          }
        }
        .sheet(item: $documentPickerAction,
               onDismiss: { },
               content: { action in
                 DocumentPicker(
                  "Select file to edit",
                  fileType: .file,
                  action: { url, mutable in
                    switch action {
                      case .editFile:
                        self.fileManager.loadEditorDocument(
                          source: url,
                          makeUntitled: !mutable,
                          action: { success in self.forceEditorUpdate = true })
                      default:
                        print("selected \(url)")
                        break
                    }
                  })
                  .environmentObject(self.fileManager) // There must be a bug; it's needed for no reason
               })
        if self.interpreter.isReady {
          Button(action: {
            if !(self.fileManager.editorDocument?.text.isEmpty ?? true) {
              self.interpreter.append(output: ConsoleOutput(kind: .command, text: "<execute code from editor>"))
              self.interpreter.evaluate(self.fileManager.editorDocument?.text ?? "",
                                        url: self.fileManager.editorDocument?.fileURL)
              self.presentationMode.wrappedValue.dismiss()
            }
          }) {
            Image(systemName: "play")
            // .font(InterpreterView.toolbarFont)
          }
        } else {
          Button(action: {
            self.showAbortAlert = true
          }) {
            Image(systemName: "stop.circle")
            // .font(InterpreterView.toolbarFont)
          }
          .alert(isPresented: $showAbortAlert) {
            Alert(title: Text("Abort evaluation?"),
                  primaryButton: .cancel(),
                  secondaryButton: .destructive(Text("Abort"), action: {
                    self.interpreter.context?.machine.abort()
                  }))
          }
        }
      },
      trailing:
        HStack(alignment: .center, spacing: 12) {
          Button(action: {
            
          }) {
            Image(systemName: "list.bullet.indent")
            // .font(InterpreterView.toolbarFont)
          }
          .disabled(self.showSearchField)
          Button(action: {
            self.definitions = self.determineDefinitions(self.fileManager.editorDocument?.text
                                                          ?? "")
          }) {
            Image(systemName: "f.cursive")
            // .font(InterpreterView.toolbarFont)
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
            // .font(InterpreterView.toolbarFont)
          }
          .disabled(self.showSearchField)
        })
    .fileMover(isPresented: $showFileMover,
               file: self.fileManager.editorDocument?.fileURL,
               onCompletion: { result in
                switch result {
                  case .success(let newURL):
                    self.fileManager.editorDocument?.recomputeTitle(newURL)
                    self.fileManager.editorDocument?.new = false
                    if let action = self.fileMoverAction {
                      self.fileMoverAction = nil
                      action()
                    }
                  case .failure(let error):
                    print("error = \(error)")
                }
               })
    .onDisappear(perform: {
      self.fileManager.editorDocument?.saveFile()
      self.histManager.saveFilesHistory()
      self.histManager.saveFavorites()
    })
  }
  
  func notSavedAlert(save: @escaping () -> Void, discard: @escaping () -> Void) -> Alert {
    return Alert(title: Text("Discard or save document?"),
                 message: Text("The current document is not saved yet. " +
                               "Discard or save the current document?"),
                 primaryButton: .default(Text("Save"), action: save),
                 secondaryButton: .destructive(Text("Discard"), action: discard))
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

enum NotSavedAlertAction: Int, Identifiable {
  case newFile = 0
  case editFile = 1
    
  var id: Int {
    self.rawValue
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
