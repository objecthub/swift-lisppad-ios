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
import UniformTypeIdentifiers

struct CodeEditorView: View {
  
  enum SheetAction: Identifiable {
    case renameFile
    case moveFile
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
        case .moveFile:
          return 11
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
    case deleteFile
    case openFile(URL)
    case notSaved
    case couldNotDuplicate
    case replaceAll(String, String)
    
    var id: Int {
      switch self {
        case .newFile:
          return 0
        case .editFile:
          return 1
        case .deleteFile:
          return 2
        case .openFile(_):
          return 3
        case .notSaved:
          return 4
        case .couldNotDuplicate:
          return 5
        case .replaceAll(_, _):
          return 6
      }
    }
  }

  @EnvironmentObject var globals: LispPadGlobals
  @EnvironmentObject var docManager: DocumentationManager
  @EnvironmentObject var fileManager: FileManager
  @EnvironmentObject var histManager: HistoryManager
  @EnvironmentObject var interpreter: Interpreter
  @EnvironmentObject var settings: UserSettings

  let splitView: Bool

  @Binding var path: NavigationPath
  @Binding var splitViewMode: SideBySideMode
  @Binding var masterWidthFraction: CGFloat
  @Binding var urlToOpen: URL?
  @Binding var editorPosition: NSRange?
  @Binding var editorFocused: Bool
  @Binding var forceEditorUpdate: Bool
  @Binding var updateEditor: ((CodeEditorTextView) -> Void)?
  @Binding var updateConsole: ((CodeEditorTextView) -> Void)?
  
  @StateObject var keyboardObserver = KeyboardObserver()
  @StateObject var cardContent = MutableBlock()
  @State var showCard: Bool = false
  @State var searchText: String = ""
  @State var replaceText: String = ""
  @State var showSearchField: Bool = false
  @State var replaceModeSearch: Bool = false
  @State var caseSensitiveSearch: Bool = true
  @State var showSheet: SheetAction? = nil
  @State var showModal: SheetAction? = nil
  @State var showAbortAlert = false
  @State var showFileNotFoundAlert = false
  @State var notSavedAlertAction: NotSavedAlertAction? = nil
  @State var editorType: FileExtensions.EditorType = .scheme
  
  var keyboardShortcuts: some View {
    ZStack {
      if !self.splitViewMode.isSideBySide || self.editorFocused {
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
          Button(action: self.selectExpression) {
            EmptyView()
          }
          .keyCommand("e", modifiers: .command, title: "Select expression")
          Button(action: self.defineIdentifier) {
            EmptyView()
          }
          .keyCommand("d", modifiers: .command, title: "Define identifier")
          Button(action: {
            self.dismissCard()
            self.updateEditor = { textView in
              textView.undoManager?.undo()
            }
          }) {
            EmptyView()
          }
          .keyCommand("b", modifiers: .command)
          Button(action: {
            self.dismissCard()
            self.updateEditor = { textView in
              textView.undoManager?.redo()
            }
          }) {
            EmptyView()
          }
          .keyCommand("b", modifiers: [.command, .shift])
        }
      }
      Button(action: self.runInterpreter) {
        EmptyView()
      }
      .keyCommand("r", modifiers: .command, title: "Evaluate document")
      Button(action: self.stopInterpreter) {
        EmptyView()
      }
      .keyCommand("t", modifiers: .command, title: "Terminate evaluation")
      Button(action: {
        self.dismissCard()
        self.showSearchField.toggle()
      }) {
        EmptyView()
      }
      .keyCommand("f", modifiers: .command, title: "Find")
      .alert(isPresented: $showAbortAlert, content: self.abortAlert)
      Button(action: {
        self.dismissCard()
        if !self.showSearchField {
          self.showSearchField = true
          self.replaceModeSearch = true
        } else {
          self.replaceModeSearch.toggle()
        }
      }) {
        EmptyView()
      }
      .keyCommand("f", modifiers: [.command, .shift], title: "Find/Replace")
      .alert(isPresented: $showAbortAlert, content: self.abortAlert)
      Button(action: self.switchAcross) {
        EmptyView()
      }
      .keyboardShortcut("s", modifiers: .command)
    }
  }
  
  var body: some View {
    GeometryReader { geometry in
      VStack(alignment: .leading, spacing: 0) {
        self.keyboardShortcuts
        if self.showSearchField {
          VStack(alignment: .leading, spacing: 0) {
            SearchField(searchText: $searchText,
                        replaceText: $replaceText,
                        showSearchField: $showSearchField,
                        replaceMode: $replaceModeSearch,
                        caseSensitive: $caseSensitiveSearch,
                        search: { str, direction in
                          self.dismissCard()
                          if let doc = self.fileManager.editorDocument {
                            let text = NSString(string: doc.text)
                            let pos = direction == .first ? 0 : doc.selectedRange.location +
                                                                (doc.selectedRange.length > 0 ? 1 : 0)
                            let result = direction == .backward
                              ? text.range(of: str,
                                           options:
                                             self.caseSensitiveSearch
                                               ? [.diacriticInsensitive, .backwards]
                                               : [.diacriticInsensitive, .backwards, .caseInsensitive],
                                           range: NSRange(location: 0, length: pos),
                                           locale: nil)
                              : text.range(of: str,
                                           options: self.caseSensitiveSearch
                                                      ? [.diacriticInsensitive]
                                                      : [.diacriticInsensitive, .caseInsensitive],
                                           range: NSRange(location: pos, length: text.length - pos),
                                           locale: nil)
                            if result.location != NSNotFound {
                              self.editorPosition = result
                              return true
                            } else {
                              return false
                            }
                          } else {
                            return false
                          }
                        },
                        replace: { str, repl, cont in
                          self.dismissCard()
                          self.updateEditor = { textView in
                            let formerRange = textView.selectedRange
                            if formerRange.length > 0 {
                              if let range = textView.selectedTextRange {
                                textView.replace(range, withText: repl)
                              } else {
                                textView.textStorage.replaceCharacters(in: textView.selectedRange,
                                                                       with: repl)
                              }
                            }
                            if let cont = cont {
                              let pos = formerRange.location + (formerRange.length > 0 ? 1 : 0)
                              let text = textView.text as NSString
                              let result = text.range(
                                             of: str,
                                             options: self.caseSensitiveSearch
                                                        ? [.diacriticInsensitive]
                                                        : [.diacriticInsensitive, .caseInsensitive],
                                             range: NSRange(location: pos, length: text.length - pos),
                                             locale: nil)
                              if result.location != NSNotFound {
                                self.editorPosition = result
                                cont(true)
                              } else {
                                self.editorPosition = NSRange(location: formerRange.location,
                                                              length: NSString(string: repl).length)
                                cont(false)
                              }
                            } else {
                              self.editorPosition = NSRange(location: formerRange.location,
                                                            length: NSString(string: repl).length)
                            }
                          }
                        },
                        replaceAll: { str, repl in
                          self.dismissCard()
                          self.notSavedAlertAction = .replaceAll(str, repl)
                        })
            Divider()
          }
          .transition(.move(edge: .top))
        }
        CodeEditor(text: .init(get: { self.fileManager.editorDocument?.text ?? "" },
                               set: { if let doc = self.fileManager.editorDocument {doc.text = $0}}),
                   selectedRange: .init(
                                    get: { self.fileManager.editorDocument?.selectedRange ??
                                             NSRange(location: 0, length: 0) },
                                    set: { if let doc = self.fileManager.editorDocument {
                                             doc.selectedRange = $0
                                         }}),
                   focused: $editorFocused,
                   position: $editorPosition,
                   forceUpdate: $forceEditorUpdate,
                   update: $updateEditor,
                   editorType: $editorType,
                   keyboardObserver: self.keyboardObserver,
                   defineAction: { block in
                    self.showCard = true
                    self.cardContent.block = block
                   })
          .multilineTextAlignment(.leading)
          .ignoresSafeArea(edges: .bottom)
          .slideOverCard(isPresented: $showCard, onDismiss: { self.cardContent.block = nil }) {
            OptionalScrollView {
              MutableMarkdownText(self.cardContent, rightPadding: 26)
                .modifier(self.globals.services)
                .padding(.horizontal, 10)
                .padding(.top, 10)
                .padding(.bottom, -10)
            }
          }
          .onAppear {
            self.editorType = self.fileManager.editorDocumentInfo.editorType
            switch self.splitViewMode {
              case .rightOnRight, .rightOnLeft:
                self.updateEditor = { textView in
                  textView.becomeFirstResponder()
                }
              default:
                break
            }
          }
          .onChange(of: self.fileManager.editorDocumentInfo.editorType) {
            self.editorType = self.fileManager.editorDocumentInfo.editorType
          }
      }
      .navigationBarTitleDisplayMode(.inline)
      .navigationBarBackButtonHidden(true)
      .toolbar {
        ToolbarItemGroup(placement: .navigationBarLeading) {
          HStack(alignment: .center, spacing: LispPadUI.toolbarSeparator)  {
            SideBySideNavigator(leftSide: false,
                                allowSplit: self.splitView,
                                mode: self.$splitViewMode,
                                fraction: self.$masterWidthFraction)
            Menu {
              Button {
                self.dismissCard()
                if (self.fileManager.editorDocumentInfo.new) &&
                   !(self.fileManager.editorDocument?.text.isEmpty ?? true) {
                  self.notSavedAlertAction = .newFile
                } else {
                  self.fileManager.newEditorDocument { success in
                    self.forceEditorUpdate = true
                  }
                }
              } label: {
                Label("New", systemImage: "square.and.pencil")
              }
              Button {
                self.dismissCard()
                self.histManager.verifyFileLists()
                if (self.fileManager.editorDocumentInfo.new) &&
                   !(self.fileManager.editorDocument?.text.isEmpty ?? true) {
                  self.notSavedAlertAction = .editFile
                } else {
                  self.showModal = .editFile
                }
              } label: {
                Label("Open…", systemImage: "tray.and.arrow.up")
              }
              Button {
                self.dismissCard()
                self.fileManager.editorDocument?.saveFile { success in
                  self.showModal = .saveFile
                }
              } label: {
                Label(self.fileManager.editorDocumentInfo.new ? "Save…" : "Save As…",
                      systemImage: "tray.and.arrow.down")
              }
              Button {
                self.dismissCard()
                self.histManager.verifyFileLists()
                self.showModal = .organizeFiles
              } label: {
                Label("Organize…", systemImage: "doc.text.magnifyingglass")
              }
              if !self.histManager.recentlyEdited.isEmpty {
                Section("RECENT FILES") {
                  ForEach(self.histManager.recentlyEdited, id: \.self) { purl in
                    if let url = purl.url {
                      Button(action: {
                        self.dismissCard()
                        if purl.fileExists {
                          self.fileManager.loadEditorDocument(source: url, makeUntitled: !purl.mutable)
                        } else {
                          self.histManager.verifyRecentFiles()
                          self.showFileNotFoundAlert = true
                        }
                      }) {
                        Label(url.lastPathComponent, systemImage: purl.base?.imageName ?? "folder")
                      }
                    }
                  }
                }
              }
            } label: {
              Image(systemName: "doc")
                .font(LispPadUI.toolbarFont)
            }
            .alert(isPresented: $showFileNotFoundAlert, content: self.fileNotFoundAlert)
            if self.interpreter.isReady {
              Button(action: self.runInterpreter) {
                Image(systemName: self.editorType == .scheme ? "play" : "play.display")
                  .font(LispPadUI.toolbarFont)
              }
              .disabled((self.editorType != .scheme) && (self.editorType != .markdown))
            } else {
              Button(action: self.stopInterpreter) {
                Image(systemName: "stop.circle")
                  .foregroundColor(Color.red)
                  .font(LispPadUI.toolbarFont)
              }
              .alert(isPresented: $showAbortAlert, content: self.abortAlert)
            }
          }
        }
        ToolbarItemGroup(placement: .principal) {
          Menu {
            Button {
              self.dismissCard()
              if let path = PortableURL(self.fileManager.editorDocument?.fileURL)?.relativePath {
                UIPasteboard.general.string = path
              }
            } label: {
              Label(self.fileManager.editorDocument?.fileURL.lastPathComponent ?? "Unknown",
                    systemImage: PortableURL(self.fileManager.editorDocument?.fileURL)?.base?.imageName ?? "link")
              Text((self.fileManager.editorDocument?.pathString ?? "/") + 
                   " • " + (self.fileManager.editorDocument?.sizeString ?? "? B"))
            }
            .disabled(self.fileManager.editorDocumentInfo.new)
            ControlGroup {
              Button {
                self.dismissCard()
                self.fileManager.editorDocument?.saveFile { success in
                  self.showModal = .moveFile
                }
              } label: {
                Label(self.fileManager.editorDocumentInfo.new ? "Save…" : "Move To…",
                      systemImage: self.fileManager.editorDocumentInfo.new
                                     ? "tray.and.arrow.down" : "folder")
              }
              Button {
                self.dismissCard()
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
              } label: {
                Label("Duplicate", systemImage: "plus.rectangle.on.rectangle")
              }
              .disabled(self.fileManager.editorDocumentInfo.new)
              Button(role: .destructive) {
                self.dismissCard()
                self.notSavedAlertAction = .deleteFile
              } label: {
                Label("Delete", systemImage: "trash")
              }
              .disabled(self.fileManager.editorDocumentInfo.new)
            }
            Button {
              self.dismissCard()
              self.showModal = .renameFile
            } label: {
              Label("Rename…", systemImage: "pencil")
            }
            .disabled(self.fileManager.editorDocumentInfo.new)
            Button {
              self.dismissCard()
              self.histManager.toggleFavorite(self.fileManager.editorDocument?.fileURL)
            } label: {
              if self.histManager.isFavorite(self.fileManager.editorDocument?.fileURL) {
                Label("Unstar", systemImage: "star.fill")
              } else {
                Label("Star", systemImage: "star")
              }
            }
            .disabled(!self.histManager.canBeFavorite(self.fileManager.editorDocument?.fileURL))
            if let url = self.fileManager.editorDocument?.fileURL {
              ShareLink(item: url)
                .disabled(self.fileManager.editorDocumentInfo.new)
            }
            Button {
              if let url = self.fileManager.editorDocument?.fileURL {
                UIPasteboard.general.string = url.path
              }
            } label: {
              Label("Copy Path", systemImage: "doc.on.clipboard")
            }
            .disabled(self.fileManager.editorDocumentInfo.new)
            Divider()
            Menu {
              Toggle("Show line numbers", isOn: $settings.showLineNumbers)
              Toggle("Highlight current line", isOn: $settings.highlightCurrentLine)
              Toggle("Highlight parenthesis", isOn: $settings.highlightMatchingParen)
              if self.editorType == .scheme {
                Divider()
                Toggle("Indent automatically", isOn: $settings.schemeAutoIndent)
                Toggle("Highlight syntax", isOn: $settings.schemeHighlightSyntax)
                Toggle("Markup identifiers", isOn: $settings.schemeMarkupIdent)
              } else if self.editorType == .markdown {
                Divider()
                Toggle("Indent automatically", isOn: $settings.markdownAutoIndent)
                Toggle("Highlight syntax", isOn: $settings.markdownHighlightSyntax)
              }
            } label: {
              Label("Settings", systemImage: "switch.2")
            }
          } label: {
            HStack(alignment: .center, spacing: 4) {
              if geometry.size.width >= 380 {
                Text(self.fileManager.editorDocumentInfo.title)
                  .font(geometry.size.width < 540 ? LispPadUI.fileNameFont
                                                  : LispPadUI.largeFileNameFont)
                  .bold()
                  .foregroundColor(.primary)
                  .truncationMode(.middle)
                  .multilineTextAlignment(.center)
                  .lineLimit(2)
                  .fixedSize(horizontal: false, vertical: true)
                  .frame(maxWidth: geometry.size.width - 290)
              }
              Text(Image(systemName: "chevron.down.circle.fill"))
                .font(.caption)
                .bold()
                .foregroundColor(self.editorFocused && self.splitViewMode.isSideBySide
                                   ? Color.green : Color(LispPadUI.menuIndicatorColor))
            }
          }
        }
        ToolbarItemGroup(placement: .navigationBarTrailing) {
          HStack(alignment: .center, spacing: LispPadUI.toolbarSeparator) {
            /*
            Menu {
              Button {
                self.dismissCard()
                withAnimation(.default) {
                  self.replaceModeSearch = false
                  self.showSearchField = true
                }
              } label: {
                Label("Search", systemImage: "magnifyingglass")
              }
              .disabled(self.showSearchField && !self.replaceModeSearch)
              Button {
                self.dismissCard()
                withAnimation(.default) {
                  self.replaceModeSearch = true
                  self.showSearchField = true
                }
              } label: {
                Label("Search/Replace", systemImage: "repeat")
              }
              .disabled(self.showSearchField && self.replaceModeSearch)
            } label: {
              Image(systemName: "magnifyingglass")
                .font(LispPadUI.toolbarFont)
            } primaryAction: {
              self.dismissCard()
              withAnimation(.default) {
                self.showSearchField = true
              }
            }
            .foregroundColor(self.showSearchField ? .gray : .accentColor)
            */
            Button {
              self.dismissCard()
              if self.showSearchField {
                if self.replaceModeSearch {
                  withAnimation(.default) {
                    self.showSearchField = false
                  }
                  self.replaceModeSearch = false
                } else {
                  withAnimation(.default) {
                    self.replaceModeSearch = true
                  }
                }
              } else {
                withAnimation(.default) {
                  self.showSearchField = true
                }
              }
            } label: {
              Image(systemName: "magnifyingglass")
                .font(LispPadUI.toolbarFont)
            }
            Button {
              self.dismissCard()
              guard let doc = self.fileManager.editorDocument else {
                return
              }
              if doc.info.editorType == .scheme {
                if let defs = DefinitionView.parseDefinitions(doc.text) {
                  self.showModal = .showDefinitions(defs)
                }
              } else if doc.info.editorType == .markdown {
                if let structure = DocStructureView.parseDocStructure(doc.text) {
                  self.showModal = .showDocStructure(structure)
                }
              }
            } label: {
              Image(systemName: self.editorType == .scheme ? "f.cursive" : "list.bullet.indent")
                .font(LispPadUI.toolbarFont)
            }
            .disabled(self.editorType != .scheme && self.editorType != .markdown)
            Menu {
              ControlGroup {
                Button {
                  self.dismissCard()
                  self.updateEditor = { textView in
                    textView.undoManager?.undo()
                  }
                } label: {
                  Label("Undo", systemImage: "arrow.uturn.backward")
                }
                Button {
                  self.dismissCard()
                  self.updateEditor = { textView in
                    textView.undoManager?.redo()
                  }
                } label: {
                  Label("Redo", systemImage: "arrow.uturn.forward")
                }
                Button {
                  self.selectExpression()
                } label: {
                  Label("Select", systemImage: "parentheses")
                }
              }
              Group {
                Button(action: self.autoIndentEditor) {
                  Label("Auto Indent", systemImage: "text.badge.checkmark")
                }
                .disabled(self.editorType != .scheme)
                Button(action: self.indentEditor) {
                  Label("Increase Indent", systemImage: "increase.indent")
                }
                Button(action: self.outdentEditor) {
                  Label("Decrease Indent", systemImage: "decrease.indent")
                }
              }
              Divider()
              Group {
                Button(action: self.commentEditor) {
                  Label("Comment", systemImage: "text.bubble")
                }
                .disabled(self.editorType != .scheme)
                Button(action: self.uncommentEditor) {
                  Label("Uncomment", systemImage: "bubble.left")
                }
                .disabled(self.editorType != .scheme)
              }
              Divider()
              Menu {
                Button(action: self.selectLines) {
                  Label("Select", systemImage: "selection.pin.in.out")
                }
                Button(action: self.duplicateLines) {
                  Label("Duplicate", systemImage: "plus.circle")
                }
                Button(action: self.deleteLines) {
                  Label("Delete", systemImage: "minus.circle")
                }
              } label: {
                Label("Lines", systemImage: "text.redaction")
              }
            } label: {
              Image(systemName: "ellipsis.circle")
                .font(LispPadUI.toolbarFont)
            }
          }
        }
      }
      .sheet(item: $showModal, content: self.sheetView)
      .fullScreenCover(item: $showSheet, content: self.sheetView)
      .alert(item: $notSavedAlertAction) { alertAction in
        switch alertAction {
          case .newFile:
            return self.notSavedAlert(
                     save: { self.showModal = .saveBeforeNew },
                     discard: { self.fileManager.editorDocument?.text = ""
                                self.fileManager.editorDocument?.saveFile { succ in
                                  self.forceEditorUpdate = true
                              }})
          case .deleteFile:
            return Alert(title: Text("Delete open file?"),
                         message: Text("Do you want to proceed deleting the file currently open in the editor?"),
                         primaryButton: .default(Text("Cancel"), action: { }),
                         secondaryButton: .destructive(Text("Delete"), action: {
                           let url = self.histManager.currentlyEdited?.url
                           self.fileManager.newEditorDocument { success in
                             self.forceEditorUpdate = true
                             if let url {
                               self.fileManager.delete(url, complete: { success in })
                             }
                           }
                         }))
          case .editFile:
            return self.notSavedAlert(
                     save: { self.showModal = .saveBeforeEdit },
                     discard: { self.fileManager.editorDocument?.text = ""
                                self.showModal = .editFile })
          case .openFile(let url):
            return self.notSavedOnOpenAlert(
                     save: { self.showModal = .saveBeforeOpen(url) },
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
          case .replaceAll(let str, let repl):
            return self.replaceAll(str, repl)
            
        }
      }
      .onChange(of: self.urlToOpen) { _, optUrl in
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
        self.histManager.saveSearchHistory()
        self.histManager.saveFilesHistory()
        self.histManager.saveFavorites()
      }
    }
  }
  
  @ViewBuilder private func sheetView(_ sheet: SheetAction) -> some View {
    switch sheet {
      case .renameFile:
        SaveAs(url: self.fileManager.editorDocument?.saveAsURL,
               firstSave: self.fileManager.editorDocumentInfo.new,
               lockFolder: true) { url in
          self.fileManager.editorDocument?.moveFileTo(url) { newURL in
            if newURL == nil {
              self.notSavedAlertAction = .notSaved
            }
          }
          return true
        }
        .transition(.move(edge: .top))
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
        .modifier(self.globals.services)
      case .moveFile:
        SaveAs(url: self.fileManager.editorDocument?.saveAsURL,
               firstSave: self.fileManager.editorDocumentInfo.new,
               lockFolder: false) { url in
          self.fileManager.editorDocument?.moveFileTo(url) { newURL in
            if newURL == nil {
              self.notSavedAlertAction = .notSaved
            }
          }
          return true
        }
        .transition(.move(edge: .top))
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
        .modifier(self.globals.services)
      case .saveFile:
        SaveAs(url: self.fileManager.editorDocument?.saveAsURL,
               firstSave: self.fileManager.editorDocumentInfo.new) { url in
          self.fileManager.editorDocument?.saveFileAs(url) { newURL in
            if newURL == nil {
              self.notSavedAlertAction = .notSaved
            }
          }
          return true
        }
        .modifier(self.globals.services)
      case .editFile:
        Open(title: "Open") { url, mutable in
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
          return true
        }
        .modifier(self.globals.services)
      case .saveBeforeEdit:
        SaveAs(url: self.fileManager.editorDocument?.saveAsURL,
               firstSave: self.fileManager.editorDocumentInfo.new) { url in
          self.fileManager.editorDocument?.saveFileAs(url) { newURL in
            if newURL == nil {
              self.notSavedAlertAction = .notSaved
            } else {
              self.showModal = .editFile
            }
          }
          return true
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
          return true
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
  
  private func dismissCard() {
    self.showCard = false
  }
  
  private func switchAcross() {
    if self.splitViewMode.isSideBySide {
      if self.editorFocused {
        self.updateConsole = { textView in
          textView.becomeFirstResponder()
        }
      } else {
        self.updateEditor = { textView in
          textView.becomeFirstResponder()
        }
      }
    } else {
      // self.showCard = false
      self.splitViewMode.toggle()
    }
  }
  
  private func replaceAll(_ str: String, _ repl: String) -> Alert {
    return Alert(title: Text("Replace all"),
                 message: Text("Replace all occurences of \"\(str)\" in the remaining document?"),
                 primaryButton: .default(Text("No")),
                 secondaryButton: .destructive(Text("Yes"), action: {
                  self.updateEditor = { textView in
                    if let txt = textView.text,
                       let textRange = textView.selectedTextRange {
                      let range = textView.selectedRange
                      let text = NSMutableString(string: txt)
                      text.replaceOccurrences(
                        of: str,
                        with: repl, 
                        options: self.caseSensitiveSearch
                                   ? [.diacriticInsensitive]
                                   : [.diacriticInsensitive, .caseInsensitive], 
                        range: NSRange(location: range.location,
                                       length: text.length - range.location))
                      if let replRange = textView.textRange(from: textRange.start,
                                                            to: textView.endOfDocument) {
                        textView.replace(replRange,
                                         withText: text.substring(from: range.location))
                        textView.selectedRange = NSRange(location: textView.textStorage.length,
                                                         length: 0)
                      }
                    }
                  }
                 }))
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
    self.dismissCard()
    if let doc = self.fileManager.editorDocument,
       let range = TextFormatter.selectEnclosingExpr(string: doc.text as NSString,
                                                     selectedRange: doc.selectedRange,
                                                     smart: doc.info.editorType == .scheme) {
      doc.selectedRange = range
      self.forceEditorUpdate = true
      self.editorPosition = range
    }
  }

  private func defineIdentifier() {
    if let doc = self.fileManager.editorDocument,
       let name = TextFormatter.selectedName(in: doc.text, for: doc.selectedRange),
       let documentation = self.docManager.documentation(for: name) {
      self.showCard = true
      self.cardContent.block = documentation
    }
  }

  private func indentEditor() {
    self.dismissCard()
    self.updateEditor = { textView in
      let selRange = TextFormatter.indent(textView: textView, with: " ")
      textView.selectedRange = selRange
      if let delegate = textView.delegate as? ConsoleEditorTextViewDelegate {
        delegate.text = textView.textStorage.string
        delegate.selectedRange = selRange
      }
    }
  }
  
  private func outdentEditor() {
    self.dismissCard()
    self.updateEditor = { textView in
      if let selRange = TextFormatter.outdent(textView: textView, with: " ") {
        textView.selectedRange = selRange
        if let delegate = textView.delegate as? ConsoleEditorTextViewDelegate {
          delegate.text = textView.textStorage.string
          delegate.selectedRange = selRange
        }
      }
    }
  }
  
  private func commentEditor() {
    self.dismissCard()
    self.updateEditor = { textView in
      let selRange = TextFormatter.indent(textView: textView, with: ";")
      textView.selectedRange = selRange
      if let delegate = textView.delegate as? ConsoleEditorTextViewDelegate {
        delegate.text = textView.textStorage.string
        delegate.selectedRange = selRange
      }
    }
  }
  
  private func uncommentEditor() {
    self.dismissCard()
    self.updateEditor = { textView in
      if let selRange = TextFormatter.outdent(textView: textView, with: ";") {
        textView.selectedRange = selRange
        if let delegate = textView.delegate as? ConsoleEditorTextViewDelegate {
          delegate.text = textView.textStorage.string
          delegate.selectedRange = selRange
        }
      }
    }
  }
  
  private func autoIndentEditor() {
    self.dismissCard()
    self.updateEditor = { textView in
      let text = textView.text as NSString
      let selectedRange = textView.selectedRange
      if let (str, replRange, selRange) = TextFormatter.autoIndentLines(
                                            text,
                                            range: selectedRange,
                                            tabWidth: UserSettings.standard.indentSize) {
        textView.selectedRange = replRange
        if let textRange = textView.selectedTextRange {
          textView.undoManager?.beginUndoGrouping()
          textView.replace(textRange, withText: str)
          textView.selectedRange = selRange
          textView.undoManager?.endUndoGrouping()
          if let delegate = textView.delegate as? ConsoleEditorTextViewDelegate {
            delegate.text = textView.textStorage.string
            delegate.selectedRange = selRange
          }
        } else {
          textView.selectedRange = selectedRange
        }
      }
    }
  }
  
  private func selectLines() {
    self.dismissCard()
    if let doc = self.fileManager.editorDocument {
      let str = doc.text as NSString
      let selectedRange = doc.selectedRange
      var start = selectedRange.location
      var end = start + selectedRange.length
      while start > 0 && str.character(at: start - 1) != NEWLINE {
        start -= 1
      }
      while end < str.length && str.character(at: end) != NEWLINE {
        end += 1
      }
      if end < str.length {
        end += 1
      }
      self.forceEditorUpdate = true
      self.editorPosition = NSRange(location: start, length: end - start)
    }
  }
  
  private func duplicateLines() {
    self.dismissCard()
    self.updateEditor = { textView in
      let str = textView.text as NSString
      let selectedRange = textView.selectedRange
      let selRange = TextFormatter.curLineRange(str, selectedRange)
      let replStr = str.substring(with: selRange)
      let replRange = NSRange(location: selRange.location + selRange.length, length: 0)
      textView.selectedRange = replRange
      if let textRange = textView.selectedTextRange {
        textView.undoManager?.beginUndoGrouping()
        textView.replace(textRange, withText: replStr)
        textView.selectedRange = replRange
        textView.undoManager?.endUndoGrouping()
        if let delegate = textView.delegate as? ConsoleEditorTextViewDelegate {
          delegate.text = textView.textStorage.string
          delegate.selectedRange = replRange
        }
      } else {
        textView.selectedRange = selectedRange
      }
    }
  }
  
  private func deleteLines() {
    self.dismissCard()
    self.updateEditor = { textView in
      let selectedRange = textView.selectedRange
      let selRange = TextFormatter.curLineRange(textView.text as NSString, selectedRange)
      textView.selectedRange = selRange
      if let textRange = textView.selectedTextRange {
        textView.undoManager?.beginUndoGrouping()
        textView.replace(textRange, withText: "")
        textView.selectedRange = NSRange(location: selRange.location, length: 0)
        textView.undoManager?.endUndoGrouping()
        if let delegate = textView.delegate as? ConsoleEditorTextViewDelegate {
          delegate.text = textView.textStorage.string
          delegate.selectedRange = textView.selectedRange
        }
      } else {
        textView.selectedRange = selectedRange
      }
    }
  }

  private func runInterpreter() {
    self.dismissCard()
    if self.editorType == .scheme {
      let message = self.fileManager.editorDocumentInfo.new ?
        "<execute editor buffer>" :
        "<execute \"\(self.fileManager.editorDocumentInfo.title)\">"
      if UserSettings.standard.logCommands {
        SessionLog.standard.addLogEntry(severity: .info,
                                        tag: "repl/load",
                                        message: message)
      }
      self.interpreter.console.append(output: .command(message))
      self.interpreter.evaluate(self.fileManager.editorDocument?.text ?? "",
                                url: self.fileManager.editorDocument?.fileURL)
      switch self.splitViewMode {
        case .rightOnRight:
          withAnimation {
            self.splitViewMode = .leftOnLeft
          }
        case .rightOnLeft:
          withAnimation {
            self.splitViewMode = .leftOnRight
          }
        default:
          break
      }
    } else if self.editorType == .markdown {
      let block = MarkdownParser.standard.parse(self.fileManager.editorDocument?.text ?? "")
      self.showModal = .markdownPreview(block)
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
                   self.interpreter.context?.evaluator.abort()
                 }))
  }
  
  private func fileNotFoundAlert() -> Alert {
    return Alert(title: Text("File not found"))
  }
}
