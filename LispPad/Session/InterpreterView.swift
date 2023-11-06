//
//  InterpreterView.swift
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

import SwiftUI
import PhotosUI
import LispKit
import MarkdownKit

struct InterpreterView: View {
  
  // Navigation targets
  enum NavigationTargets: Hashable {
    case libraryBrowser
    case environmentBrowser
    case settings
  }
  
  // Sheet identifiers
  enum SheetAction: Identifiable, Equatable {
    case loadFile
    case organizeFiles
    case shareConsole
    case shareImage(UIImage)
    case shareText(String)
    case showAbout
    case showShortcuts
    case showPDF(String, URL)
    case saveBeforeOpen(URL)
    case showDocumentation(Block)
    
    var id: Int {
      switch self {
        case .loadFile:
          return 0
        case .organizeFiles:
          return 1
        case .shareConsole:
          return 2
        case .shareImage(_):
          return 3
        case .shareText(_):
          return 4
        case .showAbout:
          return 5
        case .showShortcuts:
          return 6
        case .showPDF(_, _):
          return 7
        case .saveBeforeOpen(_):
          return 8
        case .showDocumentation(_):
          return 9
      }
    }
  }
  
  // Alert identifiers
  enum AlertAction: Identifiable {
    case abortEvaluation
    case notSaved
    case openURL(URL)
    
    var id: Int {
      switch self {
        case .abortEvaluation:
          return 0
        case .notSaved:
          return 1
        case .openURL(_):
          return 2
      }
    }
  }
  
  // Environment objects
  @EnvironmentObject var globals: LispPadGlobals
  @EnvironmentObject var docManager: DocumentationManager
  @EnvironmentObject var fileManager: FileManager
  @EnvironmentObject var interpreter: Interpreter
  @EnvironmentObject var histManager: HistoryManager
  @EnvironmentObject var settings: UserSettings
  
  // Parameters
  let splitView: Bool
  
  // External state
  @Binding var splitViewMode: SideBySideMode
  @Binding var masterWidthFraction: CGFloat
  @Binding var urlToOpen: URL?
  @ObservedObject var state: InterpreterState
  
  // Control flow
  @State var showResetActionSheet = false
  @State var showSheet: SheetAction? = nil
  @State var showModal: SheetAction? = nil
  @State var alertAction: AlertAction? = nil
  @State var showCard: Bool = false
  @StateObject var cardContent = MutableBlock()
  @State var showPhotosPicker: Bool = false
  @State var pickedPhotos: [PhotosPickerItem] = []
  
  // Views
  
  private var keyboardShortcuts: some View {
    ZStack {
      Button(action: self.selectExpression) {
        EmptyView()
      }
      .keyCommand("e", modifiers: .command, title: "Select expression")
      Button(action: self.defineIdentifier) {
        EmptyView()
      }
      .keyCommand("d", modifiers: .command, title: "Define identifier")
      Button(action: {
        if !self.interpreter.isReady {
          self.alertAction = .abortEvaluation
        }
      }) {
        EmptyView()
      }
      .keyCommand("t", modifiers: .command, title: "Terminate evaluation")
      if !self.splitView {
        Button(action: self.switchToEditor) {
          EmptyView()
        }
        .keyCommand("s", modifiers: .command, title: "Switch to editor")
        //.keyboardShortcut("s", modifiers: .command)
      }
    }
  }

  @ViewBuilder private func sheetView(_ sheet: SheetAction) -> some View {
    switch sheet {
      case .loadFile:
        Open() { url, mutable in
          if self.interpreter.isReady {
            self.execute(url)
          }
          return true
        }
        .modifier(self.globals.services)
      case .organizeFiles:
        Organizer()
          .modifier(self.globals.services)
      case .shareConsole:
        ZStack {
          Color(.secondarySystemBackground).ignoresSafeArea()
          ShareSheet(activityItems: [self.interpreter.console.description as NSString])
        }
      case .shareImage(let image):
        ZStack {
          Color(.secondarySystemBackground).ignoresSafeArea()
          ShareSheet(activityItems: [image])
        }
      case .shareText(let text):
        ZStack {
          Color(.secondarySystemBackground).ignoresSafeArea()
          ShareSheet(activityItems: [text as NSString])
        }
      case .showAbout:
        AboutView()
          .modifier(self.globals.services)
      case .showShortcuts:
        RTFTextView(Bundle.main.url(forResource: "KeyboardShortcuts", withExtension: "rtf"))
          .modifier(self.globals.services)
      case .showPDF(let name, let url):
        DocumentView(title: name, url: url)
          .modifier(self.globals.services)
      case .saveBeforeOpen(let ourl):
        SaveAs(url: self.fileManager.editorDocument?.saveAsURL,
               firstSave: self.fileManager.editorDocumentInfo.new) { url in
          self.fileManager.editorDocument?.saveFileAs(url) { newURL in
            if newURL == nil {
              self.alertAction = .notSaved
            } else {
              self.fileManager.loadEditorDocument(
                source: ourl,
                makeUntitled: false,
                action: { success in
                  if success {
                    self.switchToEditor()
                  }})
            }
          }
        }
        .modifier(self.globals.services)
      case .showDocumentation(let doc):
        MarkdownViewer(markdown: doc)
          .modifier(self.globals.services)
    }
  }

  // The main view
  var body: some View {
    GeometryReader { geometry in
      VStack(alignment: .leading, spacing: 0) {
        self.keyboardShortcuts
        ZStack {
          ConsoleView(
            font: settings.consoleFont,
            infoFont: settings.consoleInfoFont,
            action: {
              let old = self.state.consoleInput
              self.state.consoleInput = ""
              let input: String
              if self.interpreter.isReady {
                input = InterpreterView.canonicalizeInput(old)
                self.interpreter.console.append(output: .command(input))
                self.histManager.addCommandEntry(input)
              } else {
                input = old
              }
              self.interpreter.evaluate(input) {
                self.state.consoleInput = old
                self.interpreter.console.removeLast()
              }
            },
            splitViewMode: self.$splitViewMode,
            console: interpreter.console,
            contentBatch: $interpreter.contentBatch,
            history: $histManager.commandHistory,
            state: self.state,
            readingStatus: $interpreter.readingStatus,
            ready: $interpreter.isReady,
            showSheet: self.$showSheet,
            showModal: self.$showModal,
            showCard: self.$showCard,
            cardContent: self.cardContent)
          if let header = self.state.showProgressView {
           ProgressView(header)
            .frame(width: 200, height: 120)
            .background(Color.secondary.colorInvert())
            .foregroundColor(Color.primary)
            .cornerRadius(20)
          }
        }
      }
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItemGroup(placement: .navigationBarLeading) {
          HStack(alignment: .center, spacing: LispPadUI.toolbarSeparator) {
            SideBySideNavigator(leftSide: true,
                                allowSplit: self.splitView,
                                mode: self.$splitViewMode,
                                fraction: self.$masterWidthFraction)
            if self.interpreter.isReady {
              Menu {
                Button(action: {
                  withAnimation {
                    self.state.consoleTab = 0
                  }
                }) {
                  Label("Show Log", systemImage: "scroll")
                }
                .disabled(self.state.consoleTab == 0)
                Button(action: {
                  withAnimation {
                    self.state.consoleTab = 1
                  }
                }) {
                  Label("Show Console", systemImage: "terminal")
                }
                .disabled(self.state.consoleTab == 1)
                /* TODO: Graphics
                Button(action: {
                  withAnimation {
                    self.consoleTab = 2
                  }
                }) {
                  Label("Show Graphics", systemImage: "photo.on.rectangle.angled")
                }
                .disabled(self.consoleTab == 2)
                 */
                Divider()
                Button(action: {
                  self.showModal = .shareConsole
                }) {
                  Label("Share Console", systemImage: "square.and.arrow.up")
                }
                .disabled(self.interpreter.console.isEmpty)
                Button(action: {
                  self.interpreter.console.reset()
                }) {
                  Label("Clear Console", systemImage: "trash")
                }
                .disabled(self.interpreter.console.isEmpty)
                Button(action: {
                  self.showResetActionSheet = true
                }) {
                  Label("Reset Interpreter…", systemImage: "arrow.3.trianglepath")
                }
                Divider()
                Button(action: {
                  self.histManager.verifyFileLists()
                  self.showModal = .organizeFiles
                }) {
                  Label("Organize Files…", systemImage: "doc.text.magnifyingglass")
                }
              } label: {
                Image(systemName: "terminal")
                  .font(LispPadUI.toolbarFont)
              }
            } else {
              Button(action: {
                self.alertAction = .abortEvaluation
              }) {
                Image(systemName: "stop.circle")
                  .foregroundColor(Color.red)
                  .font(LispPadUI.toolbarFont)
              }
            }
            Button(action: {
              self.histManager.verifyFileLists()
              self.showModal = .loadFile
            }) {
              Image(systemName: "arrow.down.doc")
                .font(LispPadUI.toolbarFont)
            }
            .contextMenu {
              if self.interpreter.isReady {
                ForEach(self.histManager.recentlyEdited, id: \.self) { purl in
                  if let url = purl.url {
                    Button(action: { self.execute(url) }) {
                      Label(url.lastPathComponent, systemImage: purl.base?.imageName ?? "folder")
                    }
                  }
                }
              }
            }
            .disabled(!self.interpreter.isReady)
          }
          .actionSheet(isPresented: self.$showResetActionSheet) {
            ActionSheet(title: Text("Reset"),
                        message: Text("Clear console and reset interpreter?"),
                        buttons: [.destructive(Text("Reset interpreter"), action: {
                                    _ = self.interpreter.reset()
                                  }),
                                  .destructive(Text("Reset console & interpreter"), action: {
                                    self.interpreter.console.reset()
                                    _ = self.interpreter.reset()
                                  }),
                                  .cancel()])
          }
        }
        ToolbarItemGroup(placement: .principal) {
          Menu {
            Button(action: {
              self.showModal = .showAbout
            }) {
              Label("About…", systemImage: "questionmark.circle")
            }
            Divider()
            Button(action: {
              if let url = URL(string: "https://www.lisppad.app/applications/lisppad-go") {
                UIApplication.shared.open(url)
              }
            }) {
              Label("Manual…", systemImage: "book")
            }
            Button(action: {
              self.showModal = .showShortcuts
            }) {
              Label("Keyboard Shortcuts…", systemImage: "keyboard")
            }
            Button(action: {
              if let url = self.docManager.r7rsSpec.url {
                self.showSheet = .showPDF(self.docManager.r7rsSpec.name, url)
              }
            }) {
              Label("Language Spec…", systemImage: "doc.richtext")
            }
            Button(action: {
              if let url = self.docManager.lispPadRef.url {
                self.showSheet = .showPDF(self.docManager.lispPadRef.name, url)
              }
            }) {
              Label("Library Reference…", systemImage: "doc.richtext")
            }
          } label: {
            /* Let's not display a logo here for now.
               Image("SmallLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 28.0,height: 28.0)
                .padding(.bottom, -3) */
            HStack(alignment: .center, spacing: 4) {
              if geometry.size.width >= 380 {
                Text("LispPad")
                  .font(.body)
                  .bold()
                  .foregroundColor(.primary)
              }
              Text(Image(systemName: "chevron.down.circle.fill"))
                .font(.caption)
                .bold()
                .foregroundColor(Color(LispPadUI.menuIndicatorColor))
            }
          }
        }
        ToolbarItemGroup(placement: .navigationBarTrailing) {
          HStack(alignment: .center, spacing: LispPadUI.toolbarSeparator) {
            NavigationLink(value: NavigationTargets.settings) {
              Image(systemName: "gearshape")
                .font(LispPadUI.toolbarFont)
            }
            NavigationLink(value: NavigationTargets.libraryBrowser) {
              Image(systemName: "building.columns")
                .font(LispPadUI.toolbarFont)
            }
            .disabled(!self.docManager.initialized)
            NavigationLink(value: NavigationTargets.environmentBrowser) {
              Image(systemName: "square.stack.3d.up")
                .font(LispPadUI.toolbarFont)
            }
            .disabled(!self.docManager.initialized)
          }
        }
      }
      .navigationDestination(for: NavigationTargets.self) { target in
        switch target {
          case .libraryBrowser:
            LibraryView(libManager: interpreter.libManager)
          case .environmentBrowser:
            EnvironmentView(envManager: interpreter.envManager)
          case .settings:
            PreferencesView(selectedTab: self.$state.selectedPreferencesTab)
        }
      }
      .sheet(item: self.$showModal, content: self.sheetView)
      .fullScreenCover(item: self.$showSheet, content: self.sheetView)
      .photosPicker(isPresented: self.$showPhotosPicker,
                    selection: self.$pickedPhotos,
                    maxSelectionCount: self.interpreter.showPhotosPicker?.maxSelectionCount ?? 1,
                    selectionBehavior: .default,
                    matching: self.interpreter.showPhotosPicker?.matching ?? .images,
                    preferredItemEncoding: .automatic,
                    photoLibrary: .shared())
      .alert(item: self.$alertAction) { alertAction in
        switch alertAction {
          case .abortEvaluation:
            return Alert(title: Text("Terminate evaluation?"),
                         primaryButton: .cancel(),
                         secondaryButton: .destructive(Text("Terminate"), action: {
                           self.interpreter.context?.evaluator.abort()
                         }))
          case .notSaved:
            return Alert(title: Text("Document not saved"),
                         message: Text("Could not save the currently open document. " +
                                        "Retry saving using a different name or path."),
                         dismissButton: .default(Text("OK")))
          case .openURL(let url):
            return self.notSavedAlert(
                     save: { self.showSheet = .saveBeforeOpen(url) },
                     discard: {
                      self.fileManager.loadEditorDocument(
                        source: url,
                        makeUntitled: false,
                        action: { success in
                          if success {
                            self.switchToEditor()
                          }})
                     })
        }
      }
      .onChange(of: self.interpreter.showPhotosPicker) { value in
        if value != nil {
          self.showPhotosPicker = true
          self.pickedPhotos = [.init(itemIdentifier: "___")]
        }
      }
      .onChange(of: self.pickedPhotos) { selectedPhotos in
        if selectedPhotos.isEmpty {
          self.interpreter.showPhotosPicker?.imageManager.completeLoadImageFromLibrary()
          self.interpreter.showPhotosPicker = nil
        } else if self.interpreter.showPhotosPicker == nil ||
                    (selectedPhotos.count == 1 && selectedPhotos[0].itemIdentifier == "___") {
          // Don't do anything
        } else {
          Task {
            do {
              var res: [UIImage?] = []
              for photo in selectedPhotos {
                if let data = try await photo.loadTransferable(type: Data.self) {
                  res.append(UIImage(data: data))
                } else {
                  res.append(nil)
                }
              }
              self.interpreter.showPhotosPicker?
                .imageManager.completeLoadImageFromLibrary(images: res)
            } catch let e {
              self.interpreter.showPhotosPicker?
                .imageManager.completeLoadImageFromLibrary(error: e)
            }
            self.interpreter.showPhotosPicker = nil
            self.pickedPhotos = []
          }
        }
      }
      .onChange(of: self.urlToOpen) { optUrl in
        if let url = optUrl {
          if (self.fileManager.editorDocumentInfo.new) &&
             !(self.fileManager.editorDocument?.text.isEmpty ?? true) {
            self.alertAction = .openURL(url)
          } else {
            self.switchToEditor()
            self.fileManager.loadEditorDocument(source: url, makeUntitled: false)
          }
          DispatchQueue.main.async {
            self.urlToOpen = nil
          }
        }
      }
    }
  }
  
  func notSavedAlert(save: @escaping () -> Void, discard: @escaping () -> Void) -> Alert {
    return Alert(title: Text("Discard or save document?"),
                 message: Text("LispPad was asked to open a new file, but the current document " +
                               "is not saved yet. Discard or save the current document?"),
                 primaryButton: .default(Text("Save"), action: save),
                 secondaryButton: .destructive(Text("Discard"), action: discard))
  }
  
  private func switchToEditor() {
    switch self.splitViewMode {
      case .normal, .swapped, .leftOnLeft, .leftOnRight:
        return
      case .rightOnRight:
        self.splitViewMode = .leftOnLeft
      case .rightOnLeft:
        self.splitViewMode = .leftOnRight
    }
  }
  
  private func execute(_ url: URL?) {
    if let url = url {
      let input = InterpreterView.canonicalizeInput(
                    "(load \"\(self.fileManager.canonicalPath(for: url))\")")
      self.interpreter.console.append(output: .command(input))
      self.histManager.addCommandEntry(input)
      self.histManager.trackRecentFile(url)
      self.interpreter.load(url)
    }
  }

  private func selectExpression() {
    if let range = TextFormatter.selectEnclosingExpr(string: self.state.consoleInput as NSString,
                                                     selectedRange: self.state.consoleInputRange) {
      self.state.consoleInputRange = range
    }
  }

  private func defineIdentifier() {
    if let name = TextFormatter.selectedName(in: self.state.consoleInput,
                                             for: self.state.consoleInputRange),
       let documentation = self.docManager.documentation(for: name) {
      self.showCard = true
      self.cardContent.block = documentation
    }
  }

  static func canonicalizeInput(_ input: String) -> String {
    let str = input.trimmingCharacters(in: .whitespacesAndNewlines)
    var res = ""
    for ch in str {
      switch ch {
        case "‘":
          res += "'"
        case "“", "”", "„":
          res += "\""
        default:
          res.append(ch)
      }
    }
    return res
  }
}
