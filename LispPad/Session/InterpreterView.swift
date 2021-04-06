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
  // Static parameters
  static let toolbarItemSize: CGFloat = 20
  
  // User settings and defaults
  @AppStorage("Console.maxHistory") private var maxHistory: Int = 20
  
  // Environment, observed and bound objects
  @EnvironmentObject var docManager: DocumentationManager
  @ObservedObject var interpreter: Interpreter
  @ObservedObject var historyManager: HistoryManager
  
  // Internal state
  @State private var consoleInput = ""
  @State private var showAbortAlert = false
  @State private var showResetActionSheet = false
  @State private var showShareSheet = false
  @State private var showImportSheet = false
  @State private var showDocumentPicker = false
  
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
          Image(systemName: "ellipsis.circle")
            .font(Font.system(size: InterpreterView.toolbarItemSize, weight: .light))
        }
        if self.interpreter.isReady {
          Button(action: {
            self.showResetActionSheet = true
          }) {
            Image(systemName: "trash")
              .font(Font.system(size: InterpreterView.toolbarItemSize, weight: .light))
          }
          .actionSheet(isPresented: $showResetActionSheet) {
            ActionSheet(title: Text("Reset"),
                        message: Text("Discard console output or reset interpreter?"),
                        buttons: [.default(Text("Reset console"), action: {
                                    self.interpreter.consoleContent.removeAll()
                                  }),
                                  .destructive(Text("Reset interpreter"), action: {
                                    _ = self.interpreter.reset()
                                  }),
                                  .destructive(Text("Reset console & interpreter"), action: {
                                    self.interpreter.consoleContent.removeAll()
                                    _ = self.interpreter.reset()
                                  }),
                                  .cancel()])
          }
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
        /* Button(action: {
          self.showDocumentPicker = true
        }) {
          Image(systemName: "doc")
            .font(Font.system(size: InterpreterView.toolbarItemSize, weight: .light))
        }
        .sheet(isPresented: $showDocumentPicker) {
          DocumentPicker()
        } */
        Menu {
          Button(action: {
            self.showImportSheet.toggle()
          }) {
              Label("Load file", systemImage: "plus.circle")
          }
          Button(action: {
            self.showDocumentPicker = true
          }) {
              Label("Load LispKit file", systemImage: "minus.circle")
          }
          Button(action: {
              
          }) {
              Label("Load LispPad file", systemImage: "pencil.circle")
          }
        } label: {
          Image(systemName: "doc" /* "doc.badge.plus" */)
            .font(Font.system(size: InterpreterView.toolbarItemSize, weight: .light))
        }
        .sheet(isPresented: $showDocumentPicker) {
          DocumentPicker("Select program to load",
                         fileType: .file,
                         action: { url in print("selected \(url)") })
        }
        NavigationLink(destination: LazyView(
          LibraryView(libManager: interpreter.libManager))) {
          Image(systemName: "building.columns")
            .font(Font.system(size: InterpreterView.toolbarItemSize, weight: .light))
        }
        .disabled(!self.docManager.initialized)
        NavigationLink(destination: LazyView(
          EnvironmentView(envManager: interpreter.envManager))) {
          Image(systemName: "square.3.stack.3d") // function
            .font(Font.system(size: InterpreterView.toolbarItemSize, weight: .light))
        }
      })
    .fileImporter(isPresented: $showImportSheet,
                  allowedContentTypes: [.plainText],
                  allowsMultipleSelection: true) { result in
      do {
        print("returned")
        guard let selectedFile: URL = try result.get().first else { return }
        if selectedFile.startAccessingSecurityScopedResource() {
          defer {
            selectedFile.stopAccessingSecurityScopedResource()
          }
          print("file found")
          guard let input = String(data: try Data(contentsOf: selectedFile), encoding: .utf8) else {
            return
          }
          print("data read: \(input)")
        } else {
          // Handle denied access
          print("access denied")
        }
      } catch {
        // Handle failure.
        print("Unable to read file contents")
        print(error.localizedDescription)
      }
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
