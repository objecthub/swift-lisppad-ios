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
import MarkdownKit
import MobileCoreServices

struct CodeEditorView: View {
  
  enum SheetAction: Identifiable {
    case renameFile
    case saveFile
    case editFile
    case organizeFiles
    case saveBeforeNew
    case saveBeforeEdit
    case saveBeforeOpen(URL)
    case showDefinitions(DefinitionView.Definitions)
    case showDocStructure(DocStructureView.DocStructure)
    case markdownPreview(Block)
    case showDocumentation(Block)
    
    var id: Int {
      switch self {
        case .renameFile:
          return 0
        case .saveFile:
          return 1
        case .editFile:
          return 2
        case .organizeFiles:
          return 3
        case .saveBeforeNew:
          return 4
        case .saveBeforeEdit:
          return 5
        case .saveBeforeOpen(_):
          return 6
        case .showDefinitions(_):
          return 7
        case .showDocStructure(_):
          return 8
        case .markdownPreview(_):
          return 9
        case .showDocumentation(_):
          return 10
      }
    }
  }
  
  enum NotSavedAlertAction: Identifiable {
    case newFile
    case editFile
    case openFile(URL)
    case notSaved
    case couldNotDuplicate
    
    var id: Int {
      switch self {
        case .newFile:
          return 0
        case .editFile:
          return 1
        case .openFile(_):
          return 2
        case .notSaved:
          return 3
        case .couldNotDuplicate:
          return 4
      }
    }
  }
  
  @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

  @EnvironmentObject var globals: LispPadGlobals
  @EnvironmentObject var docManager: DocumentationManager
  @EnvironmentObject var fileManager: FileManager
  @EnvironmentObject var histManager: HistoryManager
  @EnvironmentObject var interpreter: Interpreter
  @EnvironmentObject var settings: UserSettings

  let splitView: Bool

  @Binding var splitViewMode: SplitViewMode
  @Binding var masterWidthFraction: Double
  @Binding var urlToOpen: URL?
  @Binding var editorPosition: NSRange?
  @Binding var forceEditorUpdate: Bool
  
  @StateObject var keyboardObserver = KeyboardObserver()
  @State var searchHistory: [String] = []
  @State var showSearchField: Bool = false
  @State var showSheet: SheetAction? = nil
  @State var showAbortAlert = false
  @State var notSavedAlertAction: NotSavedAlertAction? = nil
  @State var editorType: FileExtensions.EditorType = .scheme
  @State var undoEditor: Bool? = nil
  
  var keyboardShortcuts: some View {
    ZStack {
      ZStack {
        Button(action: self.indentEditor) {
          EmptyView()
        }
        .keyCommand("]", modifiers: .command, title: "Indent line")
        Button(action: self.outdentEditor) {
          EmptyView()
        }
        .keyCommand("[", modifiers: .command, title: "Outdent line")
        Button(action: self.commentEditor) {
          EmptyView()
        }
        .keyCommand(";", modifiers: .command, title: "Comment line")
        Button(action: self.uncommentEditor) {
          EmptyView()
        }
        .keyCommand(";", modifiers: [.shift, .command], title: "Uncomment line")
        Button(action: self.autoIndentEditor) {
          EmptyView()
        }
        .keyCommand("i", modifiers: .command, title: "Auto-indent")
      }
      Button(action: self.selectExpression) {
        EmptyView()
      }
      .keyCommand("e", modifiers: .command, title: "Select expression")
      Button(action: self.defineIdentifier) {
        EmptyView()
      }
      .keyCommand("d", modifiers: .command, title: "Define identifier")
      Button(action: self.runInterpreter) {
        EmptyView()
      }
      .keyCommand("r", modifiers: .command, title: "Evaluate document")
      Button(action: self.stopInterpreter) {
        EmptyView()
      }
      .keyCommand("t", modifiers: .command, title: "Terminate evaluation")
      Button(action: { self.showSearchField = !self.showSearchField }) {
        EmptyView()
      }
      .keyCommand("f", modifiers: .command, title: "Find")
      .alert(isPresented: $showAbortAlert, content: self.abortAlert)
      if !self.splitView {
        Button(action: {
          self.presentationMode.wrappedValue.dismiss()
        }) {
          EmptyView()
        }
        .keyboardShortcut("m", modifiers: .command)
      }
    }
  }
  
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
            self.editorPosition = result
            return true
          } else {
            return false
          }
        }
        .font(.body)
        .transition(.move(edge: .top))
        Divider()
      }
      self.keyboardShortcuts
      CodeEditor(text: .init(get: { self.fileManager.editorDocument?.text ?? "" },
                             set: { if let doc = self.fileManager.editorDocument {doc.text = $0}}),
                 selectedRange: .init(
                                  get: { self.fileManager.editorDocument?.selectedRange ??
                                           NSRange(location: 0, length: 0) },
                                  set: { if let doc = self.fileManager.editorDocument {
                                           doc.selectedRange = $0
                                       }}),
                 position: $editorPosition,
                 forceUpdate: $forceEditorUpdate,
                 undo: $undoEditor,
                 editorType: $editorType,
                 keyboardObserver: self.keyboardObserver,
                 defineAction: { block in
                  self.showSheet = .showDocumentation(block)
                 })
        .multilineTextAlignment(.leading)
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onAppear {
          self.editorType = self.fileManager.editorDocumentInfo.editorType
        }
        .onChange(of: self.fileManager.editorDocumentInfo.editorType) { value in
          self.editorType = self.fileManager.editorDocumentInfo.editorType
        }
    }
    .navigationBarHidden(false)
    .navigationBarTitleDisplayMode(.inline)
    .navigationBarBackButtonHidden(true)
    .toolbar {
      ToolbarItemGroup(placement: .navigationBarLeading) {
        HStack(alignment: .center, spacing: 16)  {
          NavigationControl(splitView: self.splitView,
                            masterView: false,
                            splitViewMode: $splitViewMode,
                            masterWidthFraction: $masterWidthFraction) {
            self.presentationMode.wrappedValue.dismiss()
          } splitViewAction: {
            self.fileManager.editorDocument?.saveFile()
            self.histManager.saveFilesHistory()
            self.histManager.saveFavorites()
          }
          Menu(content: {
            Button(action: {
              if (self.fileManager.editorDocumentInfo.new) &&
                 !(self.fileManager.editorDocument?.text.isEmpty ?? true) {
                self.notSavedAlertAction = .newFile
              } else {
                self.fileManager.newEditorDocument()
              }
            }) {
              Label("New", systemImage: "square.and.pencil")
            }
            Button(action: {
              if (self.fileManager.editorDocumentInfo.new) &&
                 !(self.fileManager.editorDocument?.text.isEmpty ?? true) {
                self.notSavedAlertAction = .editFile
              } else {
                self.showSheet = .editFile
              }
            }) {
              Label("Open…", systemImage: "tray.and.arrow.up")
            }
            Button(action: {
              self.fileManager.editorDocument?.saveFile { success in
                self.showSheet = .saveFile
              }
            }) {
              Label(self.fileManager.editorDocumentInfo.new ? "Save…" : "Save As…",
                    systemImage: "tray.and.arrow.down")
            }
            Button(action: {
              self.showSheet = .organizeFiles
            }) {
              Label("Organize…", systemImage: "doc.text.magnifyingglass")
            }
            if !self.histManager.recentlyEdited.isEmpty {
              Divider()
              ForEach(self.histManager.recentlyEdited, id: \.self) { purl in
                if let url = purl.url {
                  Button(action: {
                    self.fileManager.loadEditorDocument(source: url, makeUntitled: !purl.mutable)
                  }) {
                    Label(url.lastPathComponent, systemImage: purl.base?.imageName ?? "folder")
                  }
                }
              }
            }
          }, label: {
            Image(systemName: "doc")
              .font(InterpreterView.toolbarFont)
          })
          if self.interpreter.isReady {
            Button(action: self.runInterpreter) {
              Image(systemName: self.editorType == .scheme ? "play" : "display")
                .font(InterpreterView.toolbarFont)
            }
            .disabled((self.editorType != .scheme) && (self.editorType != .markdown))
          } else {
            Button(action: self.stopInterpreter) {
              Image(systemName: "stop.circle")
                .foregroundColor(Color.red)
                .font(InterpreterView.toolbarFont)
            }
            .alert(isPresented: $showAbortAlert, content: self.abortAlert)
          }
        }
      }
      ToolbarItemGroup(placement: .principal) {
        Menu {
          Button(action: {
            if let path = PortableURL(self.fileManager.editorDocument?.fileURL)?.relativePath {
              UIPasteboard.general.setValue(path, forPasteboardType: kUTTypePlainText as String)
            }
          }) {
            Label(PortableURL(self.fileManager.editorDocument?.fileURL)?.relativePath ?? "Unknown",
                  systemImage: PortableURL(self.fileManager.editorDocument?.fileURL)?.base?.imageName ?? "link")
          }
          .disabled(self.fileManager.editorDocumentInfo.new)
          Divider()
          Button(action: {
            self.fileManager.editorDocument?.saveFile { success in
              self.showSheet = .saveFile
            }
          }) {
            Label(self.fileManager.editorDocumentInfo.new ? "Save…" : "Save As…",
                  systemImage: "tray.and.arrow.down")
          }
          Button(action: {
            self.showSheet = .renameFile
          }) {
            Label("Rename", systemImage: "pencil")
          }
          .disabled(self.fileManager.editorDocumentInfo.new)
          Button(action: {
            if let doc = self.fileManager.editorDocument, !doc.info.new {
              doc.saveFile { success in
                if success {
                  self.fileManager.loadEditorDocument(
                    source: doc.fileURL,
                    makeUntitled: true,
                    action: { success in
                      if !success {
                        self.notSavedAlertAction = .couldNotDuplicate
                      }
                    })
                } else {
                  self.notSavedAlertAction = .couldNotDuplicate
                }
              }
            }
          }) {
            Label("Duplicate", systemImage: "plus.rectangle.on.rectangle")
          }
          .disabled(self.fileManager.editorDocumentInfo.new)
          Divider()
          Button(action: {
            self.histManager.toggleFavorite(self.fileManager.editorDocument?.fileURL)
          }) {
            if self.histManager.isFavorite(self.fileManager.editorDocument?.fileURL) {
              Label("Unstar", systemImage: "star.fill")
            } else {
              Label("Star", systemImage: "star")
            }
          }
          .disabled(!self.histManager.canBeFavorite(self.fileManager.editorDocument?.fileURL))
        } label: {
          Text(self.fileManager.editorDocumentInfo.title)
            .font(.body)
            .bold()
            .foregroundColor(.primary)
        }
      }
      ToolbarItemGroup(placement: .navigationBarTrailing) {
        HStack(alignment: .center, spacing: 16) {
          Menu(content: {
            Button(action: {
              self.undoEditor = true
            }) {
              Label("Undo", systemImage: "arrow.uturn.backward")
            }
            Button(action: {
              self.undoEditor = false
            }) {
              Label("Redo", systemImage: "arrow.uturn.forward")
            }
            Divider()
            Button(action: self.autoIndentEditor) {
              Label("Auto Indent", systemImage: "list.bullet.indent")
            }
            .disabled(self.editorType != .scheme)
            Button(action: self.indentEditor) {
              Label("Increase Indent", systemImage: "increase.indent")
            }
            Button(action: self.outdentEditor) {
              Label("Decrease Indent", systemImage: "decrease.indent")
            }
            Divider()
            Button(action: self.commentEditor) {
              Label("Comment", systemImage: "text.bubble")
            }
            .disabled(self.editorType != .scheme)
            Button(action: self.uncommentEditor) {
              Label("Uncomment", systemImage: "bubble.left")
            }
            .disabled(self.editorType != .scheme)
          }) {
            Image(systemName: "text.alignright")
              .font(InterpreterView.toolbarFont)
          }
          Button(action: {
            guard let doc = self.fileManager.editorDocument else {
              return
            }
            if doc.info.editorType == .scheme {
              if let defs = DefinitionView.parseDefinitions(doc.text) {
                self.showSheet = .showDefinitions(defs)
              }
            } else if doc.info.editorType == .markdown {
              if let structure = DocStructureView.parseDocStructure(doc.text) {
                self.showSheet = .showDocStructure(structure)
              }
            }
          }) {
            Image(systemName: "f.cursive")
              .font(InterpreterView.toolbarFont)
          }
          .disabled(self.editorType != .scheme && self.editorType != .markdown)
          Button(action: {
            withAnimation(.default) {
              self.showSearchField = true
            }
          }) {
            Image(systemName: "magnifyingglass")
              .font(InterpreterView.toolbarFont)
          }
          .disabled(self.showSearchField)
        }
      }
    }
    .sheet(item: $showSheet, onDismiss: { }) { sheet in
      switch sheet {
        case .renameFile:
          SaveAs(url: self.fileManager.editorDocument?.saveAsURL,
                 firstSave: self.fileManager.editorDocumentInfo.new,
                 lockFolder: true) { url in
            self.fileManager.editorDocument?.saveFileAs(url) { newURL in
              if newURL == nil {
                self.notSavedAlertAction = .notSaved
              }
            }
          }
          .modifier(self.globals.services)
        case .saveFile:
          SaveAs(url: self.fileManager.editorDocument?.saveAsURL,
                 firstSave: self.fileManager.editorDocumentInfo.new) { url in
            self.fileManager.editorDocument?.saveFileAs(url) { newURL in
              if newURL == nil {
                self.notSavedAlertAction = .notSaved
              }
            }
          }
          .modifier(self.globals.services)
        case .editFile:
          Open() { url, mutable in
            self.fileManager.loadEditorDocument(source: url, makeUntitled: !mutable)
            return true
          }
          .modifier(self.globals.services)
        case .organizeFiles:
          Organizer().modifier(self.globals.services)
        case .saveBeforeNew:
          SaveAs(url: self.fileManager.editorDocument?.saveAsURL,
                 firstSave: self.fileManager.editorDocumentInfo.new) { url in
            self.fileManager.editorDocument?.saveFileAs(url) { newURL in
              if newURL == nil {
                self.notSavedAlertAction = .notSaved
              } else {
                self.fileManager.newEditorDocument()
              }
            }
          }
          .modifier(self.globals.services)
        case .saveBeforeEdit:
          SaveAs(url: self.fileManager.editorDocument?.saveAsURL,
                 firstSave: self.fileManager.editorDocumentInfo.new) { url in
            self.fileManager.editorDocument?.saveFileAs(url) { newURL in
              if newURL == nil {
                self.notSavedAlertAction = .notSaved
              } else {
                self.showSheet = .editFile
              }
            }
          }
          .modifier(self.globals.services)
        case .saveBeforeOpen(let ourl):
          SaveAs(url: self.fileManager.editorDocument?.saveAsURL,
                 firstSave: self.fileManager.editorDocumentInfo.new) { url in
            self.fileManager.editorDocument?.saveFileAs(url) { newURL in
              if newURL == nil {
                self.notSavedAlertAction = .notSaved
              } else {
                self.fileManager.loadEditorDocument(
                  source: ourl,
                  makeUntitled: false,
                  action: { success in })
              }
            }
          }
          .modifier(self.globals.services)
        case .showDefinitions(let definitions):
          DefinitionView(defitions: definitions, position: $editorPosition)
            .modifier(self.globals.services)
        case .showDocStructure(let structure):
          DocStructureView(structure: structure, position: $editorPosition)
            .modifier(self.globals.services)
        case .markdownPreview(let block):
          MarkdownViewer(markdown: block)
            .modifier(self.globals.services)
        case .showDocumentation(let doc):
          MarkdownViewer(markdown: doc)
            .modifier(self.globals.services)
      }
    }
    .alert(item: $notSavedAlertAction) { alertAction in
      switch alertAction {
        case .newFile:
          return self.notSavedAlert(
                   save: { self.showSheet = .saveBeforeNew },
                   discard: { self.fileManager.editorDocument?.text = ""
                              self.fileManager.editorDocument?.saveFile { succ in
                                self.forceEditorUpdate = true
                            }})
        case .editFile:
          return self.notSavedAlert(
                   save: { self.showSheet = .saveBeforeEdit },
                   discard: { self.fileManager.editorDocument?.text = ""
                              self.showSheet = .editFile })
        case .openFile(let url):
          return self.notSavedOnOpenAlert(
                   save: { self.showSheet = .saveBeforeOpen(url) },
                   discard: {
                    self.fileManager.loadEditorDocument(
                      source: url,
                      makeUntitled: false,
                      action: { success in })
                   })
        case .notSaved:
          return self.couldNotSave()
        case .couldNotDuplicate:
          return self.couldNotDuplicate()
      }
    }
    .onChange(of: self.urlToOpen) { optUrl in
      if let url = optUrl {
        if (self.fileManager.editorDocumentInfo.new) &&
           !(self.fileManager.editorDocument?.text.isEmpty ?? true) {
          self.notSavedAlertAction = .openFile(url)
        } else {
          self.fileManager.loadEditorDocument(source: url, makeUntitled: false)
        }
        DispatchQueue.main.async {
          self.urlToOpen = nil
        }
      }
    }
    .onDisappear {
      self.fileManager.editorDocument?.saveFile()
      self.histManager.saveFilesHistory()
      self.histManager.saveFavorites()
    }
  }
  
  private func couldNotSave() -> Alert {
    return Alert(title: Text("File not saved"),
                 message: Text("Could not save file. Retry saving using a different name or path."),
                 dismissButton: .default(Text("OK")))
  }
  
  private func couldNotDuplicate() -> Alert {
    return Alert(title: Text("Document not duplicated"),
                 message: Text("Could not duplicate the current document."),
                 dismissButton: .default(Text("OK")))
  }
  
  private func notSavedAlert(save: @escaping () -> Void, discard: @escaping () -> Void) -> Alert {
    return Alert(title: Text("Discard or save document?"),
                 message: Text("The current document is not saved yet. " +
                               "Discard or save the current document?"),
                 primaryButton: .default(Text("Save"), action: save),
                 secondaryButton: .destructive(Text("Discard"), action: discard))
  }
  
  func notSavedOnOpenAlert(save: @escaping () -> Void, discard: @escaping () -> Void) -> Alert {
    return Alert(title: Text("Discard or save document?"),
                 message: Text("LispPad was asked to open a new file, but the current document " +
                               "is not saved yet. Discard or save the current document?"),
                 primaryButton: .default(Text("Save"), action: save),
                 secondaryButton: .destructive(Text("Discard"), action: discard))
  }

  private func selectExpression() {
    if let doc = self.fileManager.editorDocument,
       let range = TextFormatter.selectEnclosingExpr(string: doc.text as NSString,
                                                     selectedRange: doc.selectedRange) {
      doc.selectedRange = range
      self.forceEditorUpdate = true
      self.editorPosition = range
    }
  }

  private func defineIdentifier() {
    if let doc = self.fileManager.editorDocument,
       let name = TextFormatter.selectedName(in: doc.text, for: doc.selectedRange),
       let documentation = self.docManager.documentation(for: name) {
      self.showSheet = .showDocumentation(documentation)
    }
  }

  private func indentEditor() {
    if let doc = self.fileManager.editorDocument {
      let text = NSMutableString(string: doc.text)
      let selRange = TextFormatter.indent(string: text,
                                          selectedRange: doc.selectedRange,
                                          with: " ")
      doc.text = text as String
      doc.selectedRange = selRange
      self.forceEditorUpdate = true
      self.editorPosition = selRange
    }
  }
  
  private func outdentEditor() {
    if let doc = self.fileManager.editorDocument {
      let text = NSMutableString(string: doc.text)
      if let selRange = TextFormatter.outdent(string: text,
                                                   selectedRange: doc.selectedRange,
                                                   with: " ") {
        doc.text = text as String
        doc.selectedRange = selRange
        self.forceEditorUpdate = true
        self.editorPosition = selRange
      }
    }
  }
  
  private func commentEditor() {
    if let doc = self.fileManager.editorDocument {
      let text = NSMutableString(string: doc.text)
      let selRange = TextFormatter.indent(string: text,
                                          selectedRange: doc.selectedRange,
                                          with: ";")
      doc.text = text as String
      doc.selectedRange = selRange
      self.forceEditorUpdate = true
      self.editorPosition = selRange
    }
  }
  
  private func uncommentEditor() {
    if let doc = self.fileManager.editorDocument {
      let text = NSMutableString(string: doc.text)
      if let selRange = TextFormatter.outdent(string: text,
                                                   selectedRange: doc.selectedRange,
                                                   with: ";") {
        doc.text = text as String
        doc.selectedRange = selRange
        self.forceEditorUpdate = true
        self.editorPosition = selRange
      }
    }
  }
  
  private func autoIndentEditor() {
    if let doc = self.fileManager.editorDocument {
      let text = doc.text as NSString
      if let (str, replRange, selRange) = TextFormatter.autoIndentLines(
                                            text,
                                            range: doc.selectedRange,
                                            tabWidth: UserSettings.standard.indentSize) {
        doc.text = text.replacingCharacters(in: replRange, with: str)
        doc.selectedRange = selRange
        self.forceEditorUpdate = true
        self.editorPosition = selRange
      }
    }
  }

  private func runInterpreter() {
    if self.editorType == .scheme {
      self.interpreter.append(output: .command("<execute code from editor>"))
      self.interpreter.evaluate(self.fileManager.editorDocument?.text ?? "",
                                url: self.fileManager.editorDocument?.fileURL)
      if self.splitView && self.splitViewMode == .secondaryOnly {
        withAnimation(.linear) {
          self.splitViewMode = .primaryOnly
        }
      } else if !self.splitView {
        self.presentationMode.wrappedValue.dismiss()
      }
    } else if self.editorType == .markdown {
      let block = MarkdownParser.standard.parse(self.fileManager.editorDocument?.text ?? "")
      self.showSheet = .markdownPreview(block)
    }
  }
  
  private func stopInterpreter() {
    if !self.interpreter.isReady {
      self.showAbortAlert = true
    }
  }

  private func abortAlert() -> Alert {
    return Alert(title: Text("Terminate evaluation?"),
                 primaryButton: .cancel(),
                 secondaryButton: .destructive(Text("Terminate"), action: {
                   self.interpreter.context?.machine.abort()
                 }))
  }
}
