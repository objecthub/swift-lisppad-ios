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
  
  enum DocumentPickerAction: Int, Identifiable {
    case editFile = 0
    case executeFile = 1
    case organizeFiles = 2
    
    var id: Int {
      self.rawValue
    }
  }
  
  // Static parameters
  static let toolbarItemSize: CGFloat = 20
  
  // Environment, observed and bound objects
  @EnvironmentObject var docManager: DocumentationManager
  @EnvironmentObject var fileManager: FileManager
  @EnvironmentObject var interpreter: Interpreter
  @ObservedObject var historyManager: HistoryManager
  
  // Internal state
  @State private var consoleInput = ""
  @State private var showAbortAlert = false
  @State private var showResetActionSheet = false
  @State private var showShareSheet = false
  @State private var showImportSheet = false
  @State private var showPreferences = false
  @State private var documentPickerAction: DocumentPickerAction? = nil
  @State private var documentationUrl: NamedRef? = nil
  
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
    .navigationBarTitle("LispPad", displayMode: .inline)
    .navigationBarItems(
      leading: HStack(alignment: .center, spacing: 16) {
        NavigationLink(destination: LazyView(CodeEditorView())) {
          Image(systemName: "pencil.circle.fill")
            .font(Font.system(size: InterpreterView.toolbarItemSize, weight: .light))
        }
        Button(action: {
          self.documentPickerAction = .executeFile
        }) {
          Image(systemName: "arrow.down.doc")
            .font(Font.system(size: InterpreterView.toolbarItemSize, weight: .light))
        }
        .disabled(!self.interpreter.isReady)
        .sheet(item: $documentPickerAction,
               onDismiss: { },
               content: { action in
                 DocumentPicker(
                  "Select file to load",
                  fileType: .file,
                  action: { url, mutable in
                    if self.interpreter.isReady {
                      let input = InterpreterView.canonicalizeInput(
                                    "(load \"\(self.fileManager.canonicalPath(for: url))\")")
                      self.interpreter.append(output: ConsoleOutput(kind: .command, text: input))
                      self.historyManager.addConsoleEntry(input)
                      self.interpreter.load(url)
                    }
                  })
                  .environmentObject(self.fileManager) // There must be a bug; it's needed for no reason
               })
        Button(action: {
          self.showShareSheet = true
        }) {
          Image(systemName: "square.and.arrow.up")
            .font(Font.system(size: InterpreterView.toolbarItemSize, weight: .light))
        }
        .disabled(self.interpreter.consoleContent.isEmpty)
        .sheet(isPresented: $showShareSheet) {
          ShareSheet(activityItems: [self.interpreter.consoleAsText() as NSString])
        }
      },
      trailing: HStack(alignment: .center, spacing: 16) {
        if self.interpreter.isReady {
          Menu {
            Button(action: {
              self.documentationUrl = self.docManager.r7rsSpec
            }) {
              Label("Language Spec…", systemImage: "doc.richtext")
            }
            Button(action: {
              self.documentationUrl = self.docManager.lispPadRef
            }) {
              Label("Library Reference…", systemImage: "doc.richtext")
            }
            Divider()
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
              .font(.system(size: InterpreterView.toolbarItemSize, weight: .light))
          }
          .sheet(item: $documentationUrl) { docUrl in
            if let url = docUrl.url {
              DocumentView(title: docUrl.name, url: url)
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
          .background(
            NavigationLink(destination: LazyView(PreferencesView()), isActive: $showPreferences) {
              EmptyView()
            })
        } else {
          Button(action: {
            self.showAbortAlert = true
          }) {
            Image(systemName: "stop.circle")
              .font(Font.system(size: InterpreterView.toolbarItemSize, weight: .light))
          }
          .alert(isPresented: $showAbortAlert) {
            Alert(title: Text("Abort evaluation?"),
                  primaryButton: .cancel(),
                  secondaryButton: .destructive(Text("Abort"), action: {
                    self.interpreter.context?.machine.abort()
                  }))
          }
        }
        NavigationLink(destination: LazyView(
          LibraryView(libManager: interpreter.libManager))) {
          Image(systemName: "building.columns")
            .font(Font.system(size: InterpreterView.toolbarItemSize, weight: .light))
        }
        .disabled(!self.docManager.initialized)
        NavigationLink(destination: LazyView(
          EnvironmentView(envManager: interpreter.envManager))) {
          Image(systemName: "square.stack.3d.up") // function - square.stack.3d.up.badge.a - square.3.stack.3d
            .font(Font.system(size: InterpreterView.toolbarItemSize, weight: .light))
        }
      })
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
