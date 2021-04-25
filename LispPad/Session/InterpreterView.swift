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
import LispKit

struct InterpreterView: View {
  
  enum SheetAction: Identifiable {
    case loadFile
    case shareConsole
    case showAbout
    case showPDF(String, URL)
    
    var id: Int {
      switch self {
        case .loadFile:
          return 0
        case .shareConsole:
          return 1
        case .showAbout:
          return 2
        case .showPDF(_, _):
          return 3
      }
    }
  }
  
  // Static parameters
  static let toolbarItemSize: CGFloat = 20
  static let toolbarFont: SwiftUI.Font = .system(size: InterpreterView.toolbarItemSize,
                                                 weight: .light)
  
  // Environment, observed and bound objects
  @EnvironmentObject var docManager: DocumentationManager
  @EnvironmentObject var fileManager: FileManager
  @EnvironmentObject var interpreter: Interpreter
  @EnvironmentObject var historyManager: HistoryManager
  
  // Internal state
  @State private var consoleInput = ""
  @State private var showAbortAlert = false
  @State private var showResetActionSheet = false
  @State private var showPreferences = false
  @State private var showSheet: SheetAction? = nil
  
  @State var fileName: String = ""
  
  
  // The main view
  var master: some View {
    VStack(alignment: .leading, spacing: 0) {
      ConsoleView(
          font: .system(.footnote, design: .monospaced),
          infoFont: .system(.footnote),
          action: {
            let old = self.consoleInput
            self.consoleInput = ""
            let input: String
            if self.interpreter.isReady {
              input = InterpreterView.canonicalizeInput(old)
              self.interpreter.append(output: ConsoleOutput(kind: .command, text: input))
              self.historyManager.addConsoleEntry(input)
            } else {
              input = old
            }
            self.interpreter.evaluate(input, reset: {
              self.consoleInput = old
              self.interpreter.consoleContent.removeLast()
            })
          },
          content: $interpreter.consoleContent,
          history: $historyManager.consoleHistory,
          input: $consoleInput,
          readingStatus: $interpreter.readingStatus,
          ready: $interpreter.isReady)
      Spacer()
    }
    .navigationBarTitleDisplayMode(.inline)
    .navigationTitle("LispPad")
    .toolbar {
      ToolbarItemGroup(placement: .navigationBarLeading) {
        HStack(alignment: .center, spacing: 16) {
          NavigationLink(destination: LazyView(CodeEditorView())) {
            Image(systemName: "pencil.circle.fill")
              .foregroundColor(.primary)
              .font(.system(size: InterpreterView.toolbarItemSize, weight: .bold))
          }
          Button(action: {
            self.showSheet = .loadFile
          }) {
            Image(systemName: "arrow.down.doc")
              .font(InterpreterView.toolbarFont)
          }
          .disabled(!self.interpreter.isReady)
          Button(action: {
            self.showSheet = .shareConsole
          }) {
            Image(systemName: "square.and.arrow.up")
              .font(InterpreterView.toolbarFont)
          }
          .disabled(self.interpreter.consoleContent.isEmpty)
        }
      }
      ToolbarItemGroup(placement: .principal) {
        Menu {
          Button(action: {
            self.showSheet = .showAbout
          }) {
            Label("About…", systemImage: "questionmark.square")
          }
          Divider()
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
          Text("LispPad")
            .font(.body)
            .bold()
            .foregroundColor(.primary)
        }
      }
      ToolbarItemGroup(placement: .navigationBarTrailing) {
        HStack(alignment: .center, spacing: 16) {
          if self.interpreter.isReady {
            Menu {
              Button(action: {
                self.interpreter.consoleContent.removeAll()
              }) {
                  Label("Clear Console", systemImage: "clear")
              }
              Button(action: {
                self.showResetActionSheet = true
              }) {
                  Label("Reset Interpreter…", systemImage: "trash")
              }
              Divider()
              Button(action: {
                self.showPreferences = true
              }) {
                Label("Preferences…", systemImage: "switch.2")
              }
            } label: {
              Image(systemName: "gearshape")
                .font(InterpreterView.toolbarFont)
            }
            .background(
              NavigationLink(destination: LazyView(PreferencesView()), isActive: $showPreferences) {
                EmptyView()
              })
          } else {
            Button(action: {
              self.showAbortAlert = true
            }) {
              Image(systemName: "stop.circle")
                .foregroundColor(Color.red)
                .font(InterpreterView.toolbarFont)
            }
          }
          NavigationLink(destination: LazyView(
            LibraryView(libManager: interpreter.libManager))) {
            Image(systemName: "building.columns")
              .font(InterpreterView.toolbarFont)
          }
          .disabled(!self.docManager.initialized)
          NavigationLink(destination: LazyView(
            EnvironmentView(envManager: interpreter.envManager))) {
            Image(systemName: "square.stack.3d.up")
              .font(InterpreterView.toolbarFont)
          }
        }
      }
    }
    .sheet(item: $showSheet, onDismiss: { }) { sheet in
      switch sheet {
        case .loadFile:
          DocumentPicker("Select file to load",
                         kind: .open,
                         selectDirectory: false,
                         fileName: $fileName) { url, mutable in
            if self.interpreter.isReady {
              let input = InterpreterView.canonicalizeInput(
                            "(load \"\(self.fileManager.canonicalPath(for: url))\")")
              self.interpreter.append(output: ConsoleOutput(kind: .command, text: input))
              self.historyManager.addConsoleEntry(input)
              self.interpreter.load(url)
            }
            return true
          }
        case .shareConsole:
          ShareSheet(activityItems: [self.interpreter.consoleAsText() as NSString])
        case .showAbout:
          AboutView()
        case .showPDF(let name, let url):
          DocumentView(title: name, url: url)
      }
    }
    .actionSheet(isPresented: $showResetActionSheet) {
      ActionSheet(title: Text("Reset"),
                  message: Text("Clear console and reset interpreter?"),
                  buttons: [.destructive(Text("Reset interpreter"), action: {
                              _ = self.interpreter.reset()
                            }),
                            .destructive(Text("Reset console & interpreter"), action: {
                              self.interpreter.consoleContent.removeAll()
                              _ = self.interpreter.reset()
                            }),
                            .cancel()])
    }
    .alert(isPresented: $showAbortAlert) {
      Alert(title: Text("Abort evaluation?"),
            primaryButton: .cancel(),
            secondaryButton: .destructive(Text("Abort"), action: {
              self.interpreter.context?.machine.abort()
            }))
    }
  }
  
  var body: some View {
    GeometryReader { geo in
      if UIDevice.current.userInterfaceIdiom == .pad {
        NavigationView {
          self.master
        }
        .navigationViewStyle(StackNavigationViewStyle())
      } else {
        NavigationView {
          self.master
        }
        .navigationViewStyle(StackNavigationViewStyle())
      }
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
