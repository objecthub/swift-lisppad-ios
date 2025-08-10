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
import QuickLook

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
  @EnvironmentObject var histManager: HistoryManager
  
  @Binding var showShareSheet: Bool
  @Binding var showFileImporter: Bool
  @Binding var urlToMove: (URL, Bool)?
  @State var selectedUrl: URL? = nil
  @State var editUrl: URL? = nil
  @State var editName: String = ""
  @State var selectedUrls: Set<URL> = []
  @State var previewUrl: URL? = nil
  @State var alertAction: AlertAction? = nil
  @State var fileName: String = "Untitled.scm"
  @State var folder: URL? = nil
  @State var headerSize: CGSize = .zero
  
  var sourceDescription: Text {
    if let portableURL = PortableURL(self.urlToMove?.0) {
      return Text((self.urlToMove?.1 ?? false) ? "COPY:\n" : "MOVE:\n") +
             Text(Image(systemName: portableURL.base?.imageName ?? "folder")) + 
             Text("  \(portableURL.relativePath)").bold()
    } else {
      return Text((self.urlToMove?.1 ?? false) ? "COPY:\n" : "MOVE:\n") +
      Text("?").bold()
    }
  }
  
  var targetDescription: Text {
    if let folder = self.folder {
      if let portableURL = PortableURL(folder.appendingPathComponent(self.fileName)) {
        return Text("TO:\n") +
               Text(Image(systemName: portableURL.base?.imageName ?? "folder")) + 
               Text("  \(portableURL.relativePath)").bold()
      }
      return Text("TO:\n") +
             Text("?").bold()
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
        self.moveOrCopyFile(to: newUrl)
      }
    }
  }
  
  func moveOrCopyFile(to newUrl: URL) {
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
      } else if PortableURL(url: oldUrl) == self.histManager.currentlyEdited {
        self.fileManager.editorDocument?.moveFileTo(newUrl) { canonicalNewUrl in
          if canonicalNewUrl == nil {
            self.alertAction = .failedMovingFile
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
    ZStack(alignment: .top) {
      Color(.systemGroupedBackground).ignoresSafeArea()
      Form {
        Section {
          TextField("", text: $fileName, onEditingChanged: { isEditing in }, onCommit: self.tapSave)
            .autocapitalization(.none)
            .disableAutocorrection(true)
        } header: {
          Text("File")
            .padding(.top, self.headerSize.height)
        }
        Section {
          FileHierarchyBrowser(self.fileManager.userRootDirectories,
                               options: [.directories, .mutable],
                               showShareSheet: $showShareSheet,
                               showFileImporter: $showFileImporter,
                               urlToMove: $urlToMove,
                               selectedUrl: $selectedUrl,
                               editUrl: $editUrl,
                               editName: $editName,
                               selectedUrls: $selectedUrls,
                               previewUrl: $previewUrl,
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
        } header: {
          Text("Folder")
        }
      }
      VStack(alignment: .leading, spacing: 0) {
        HStack(alignment: .top, spacing: 16) {
          Spacer()
          Button {
            withAnimation {
              self.urlToMove = nil
            }
          } label: {
            Text("Cancel")
          }
          Button(action: self.tapSave) {
            Text("Save").bold()
          }
          .disabled(self.folder == nil || self.fileName.isEmpty)
        }
        .font(.system(size: 17))
        .padding()
        VStack(alignment: .leading, spacing: 8) {
          self.sourceDescription
          self.targetDescription
        }
        .font(.footnote)
        .foregroundColor(.secondary)
        .padding(EdgeInsets(top: -16, leading: 20, bottom: 16, trailing: 16))
        Divider()
      }
      .background(
        GeometryReader { geometry in
          Color(.secondarySystemBackground).opacity(0.85)
            .onAppear {
              self.headerSize = geometry.size
            }.onChange(of: geometry.size) { newSize in
              self.headerSize = newSize
            }
        })
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
                          self.moveOrCopyFile(to: url)
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
    .quickLookPreview(self.$previewUrl)
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
