//
//  SaveAs.swift
//  LispPad
//
//  Created by Matthias Zenger on 18/04/2021.
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

struct Move: View {
  
  enum AlertAction: Int, Identifiable {
    case overrideDirectory = 0
    case overrideFile = 1
    case failedMovingFile = 2
    case failedCopyingFile = 3
    var id: Int {
      self.rawValue
    }
  }
  
  @EnvironmentObject var fileManager: FileManager
  
  @Binding var showShareSheet: Bool
  @Binding var showFileImporter: Bool
  @Binding var urlToMove: (URL, Bool)?
  @State var selectedUrl: URL? = nil
  @State var editUrl: URL? = nil
  @State var editName: String = ""
  @State var selectedUrls: Set<URL> = []
  @State var alertAction: AlertAction? = nil
  
  @State var fileName: String = "Untitled.scm"
  @State var folder: URL? = nil
  
  var sourceDescription: Text {
    if let portableURL = PortableURL(self.urlToMove?.0) {
      return Text("MOVE:\n") +
             Text(Image(systemName: portableURL.base?.imageName ?? "folder")) + 
             Text("  \(portableURL.relativePath)").bold()
    } else {
      return Text("MOVE:\n?")
    }
  }
  
  var targetDescription: Text {
    if let folder = self.folder {
      if let portableURL = PortableURL(folder.appendingPathComponent(self.fileName)) {
        return Text("TO:\n") +
               Text(Image(systemName: portableURL.base?.imageName ?? "folder")) + 
               Text("  \(portableURL.relativePath)").bold()
      }
      return Text("TO:\n?")
    } else {
      return Text("Select destination folder below")
    }
  }
  
  func tapSave() {
    if !self.fileName.isEmpty,
       let oldUrl = self.urlToMove?.0,
       let newUrl = self.folder?.appendingPathComponent(self.fileName) {
      let item = self.fileManager.item(at: newUrl)
      if item == .directory {
        self.alertAction = .overrideDirectory
      } else if item == .file && newUrl != oldUrl {
        self.alertAction = .overrideFile
      } else {
        self.moveFile(to: newUrl)
      }
    }
  }
  
  func moveFile(to newUrl: URL) {
    if let (oldUrl, copy) = self.urlToMove {
      if copy {
        self.fileManager.copy(oldUrl, to: newUrl) { canonicalNewUrl in
          if canonicalNewUrl == nil {
            self.alertAction = .failedCopyingFile
          } else {
            withAnimation(.default) {
              self.urlToMove = nil
            }
          }
        }
      } else {
        self.fileManager.move(oldUrl, to: newUrl) { canonicalNewUrl in
          if canonicalNewUrl == nil {
            self.alertAction = .failedMovingFile
          } else {
            withAnimation(.default) {
              self.urlToMove = nil
            }
          }
        }
      }
    }
  }
  
  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack(alignment: .top, spacing: 16) {
        Spacer()
        Button(action: {
          withAnimation(.default) {
            self.urlToMove = nil
          }
        }) {
          Text("Cancel")
        }
        Button(action: self.tapSave) {
          Text("Save")
        }
        .disabled(self.folder == nil || self.fileName.isEmpty)
      }
      .font(.body)
      .padding()
      //.ignoresSafeArea()
      .background(Color(.systemGroupedBackground))
      HStack(alignment: .top, spacing: 16) {
        VStack(alignment: .leading, spacing: 8) {
          self.sourceDescription
          self.targetDescription
        }
        Spacer(minLength: 0)
      }
      .font(.footnote)
      .foregroundColor(.secondary)
      .padding(EdgeInsets(top: -16, leading: 20, bottom: 16, trailing: 16))
      .background(Color(.systemGroupedBackground))
      Form {
        Section(header: Text("File")) {
          TextField("", text: $fileName, onEditingChanged: { isEditing in }, onCommit: self.tapSave)
            .autocapitalization(.none)
            .disableAutocorrection(true)
        }
        Section(header: Text("Folder")) {
          FileHierarchyBrowser(self.fileManager.userRootDirectories,
                               options: [.directories, .mutable],
                               showShareSheet: $showShareSheet,
                               showFileImporter: $showFileImporter,
                               urlToMove: $urlToMove,
                               selectedUrl: $selectedUrl,
                               editUrl: $editUrl,
                               editName: $editName,
                               selectedUrls: $selectedUrls,
                               onSelection: { url in
                                 self.selectedUrls.removeAll()
                                 self.selectedUrls.insert(url)
                               })
            .font(.body)
            .onChange(of: self.selectedUrls) { value in
              if let folder = self.selectedUrls.first {
                self.folder = folder
              }
            }
        }
      }
    }
    .alert(item: $alertAction) { alertAction in
      switch alertAction {
        case .overrideDirectory:
          return Alert(title: Text("Cannot overwrite directory"),
                       message: Text("Change your file name or file path."),
                       dismissButton: .default(Text("OK")))
        case .overrideFile:
          return Alert(title: Text("Overwrite existing file?"),
                       message: Text("Cancel operation or confirm overwriting existing file."),
                       primaryButton: .default(Text("Cancel"), action: { }),
                       secondaryButton: .destructive(Text("Overwrite"), action: {
                        if !self.fileName.isEmpty,
                           let url = self.folder?.appendingPathComponent(self.fileName) {
                          self.moveFile(to: url)
                        }
                       }))
        case .failedMovingFile:
          return Alert(title: Text("Could not move item"),
                       message: Text("It was not possible to move the item. No changes were made."),
                       dismissButton: .default(Text("OK"), action: {
                         withAnimation(.default) {
                           self.urlToMove = nil
                         }
                       }))
        case .failedCopyingFile:
          return Alert(title: Text("Could not copy item"),
                       message: Text("It was not possible to copy the item successfully."),
                       dismissButton: .default(Text("OK"), action: {
                         withAnimation(.default) {
                           self.urlToMove = nil
                         }
                       }))
      }
    }
    .onAppear {
      if let url = self.urlToMove?.0 {
        self.fileName = url.lastPathComponent
        self.folder = url.deletingLastPathComponent()
        if let folder = self.folder {
          self.selectedUrls = [folder]
        }
      }
    }
  }
}
