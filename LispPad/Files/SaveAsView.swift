//
//  SaveAsView.swift
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

struct SaveAsView: View {
  
  enum AlertAction: Int, Identifiable {
    case overrideDirectory = 0
    case overrideFile = 1
    
    var id: Int {
      self.rawValue
    }
  }
  
  @Environment(\.presentationMode) var presentationMode
  @EnvironmentObject var fileManager: FileManager
  
  @State var showFileMover: Bool = false
  @State var showFileImporter: Bool = false
  @State var showFileSharer: Bool = false
  @State var searchAndImport: Bool = false
  @State var selectedUrl: URL? = nil
  @State var editUrl: URL? = nil
  @State var editName: String = ""
  @State var selectedUrls: Set<URL> = []
  @State var alertAction: AlertAction? = nil
  
  @State var fileName: String = "Untitled.scm"
  @State var folder: URL? = nil
  let url: URL?
  let firstSave: Bool
  let lockFolder: Bool
  let onSave: (URL) -> Void
  
  init(url: URL?,
       firstSave: Bool = false,
       lockFolder: Bool = false,
       onSave: @escaping (URL) -> Void) {
    self.url = url
    self.firstSave = firstSave
    self.lockFolder = lockFolder && url != nil
    self.onSave = onSave
  }
  
  var targetDescription: Text {
    if let folder = self.folder {
      if let portableURL = PortableURL(folder.appendingPathComponent(self.fileName)) {
        return Text("SAVE AS:\n") +
               Text(Image(systemName: portableURL.base?.imageName ?? "folder")) + 
               Text("  \(portableURL.relativeString)").bold()
      }
      return Text("SAVE AS:\n?")
    } else {
      return Text("Select folder below")
    }
  }
  
  func tapSave() {
    if !self.fileName.isEmpty,
       let url = self.folder?.appendingPathComponent(self.fileName) {
      let item = self.fileManager.item(at: url)
      if item == .directory {
        self.alertAction = .overrideDirectory
      } else if item == .file && (self.firstSave || url != self.url) {
        self.alertAction = .overrideFile
      } else {
        self.presentationMode.wrappedValue.dismiss()
        self.onSave(url)
      }
    }
  }
  
  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack(alignment: .top, spacing: 16) {
        Spacer()
        Button(action: {
          self.presentationMode.wrappedValue.dismiss()
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
      .edgesIgnoringSafeArea(.all)
      .background(Color(.secondarySystemBackground))
      HStack(alignment: .top, spacing: 16) {
        self.targetDescription
          .font(.footnote)
          .foregroundColor(.secondary)
        Spacer(minLength: 0)
      }
      .padding(EdgeInsets(top: -16, leading: 20, bottom: 16, trailing: 16))
      .background(Color(.secondarySystemBackground))
      Form {
        Section(header: Text("File")) {
          TextField("", text: $fileName, onEditingChanged: { isEditing in }, onCommit: self.tapSave)
            .autocapitalization(.none)
            .disableAutocorrection(true)
        }
        if !self.lockFolder {
          Section(header: Text("Folder")) {
            FileHierarchyView(self.fileManager.userRootDirectories,
                              selectDirectory: true,
                              mutable: true,
                              showFileMover: $showFileMover,
                              showFileImporter: $showFileImporter,
                              showFileSharer: $showFileSharer,
                              selectedUrl: $selectedUrl,
                              editUrl: $editUrl,
                              editName: $editName,
                              selectedUrls: $selectedUrls,
                              onSelection: { url in
                                self.selectedUrls.removeAll()
                                self.selectedUrls.insert(url)
                                self.folder = url
                              })
              .font(.body)
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
                          self.presentationMode.wrappedValue.dismiss()
                          self.onSave(url)
                        }
                       }))
      }
    }
    .sheet(isPresented: $showFileSharer) {
      if let url = self.selectedUrl {
        ShareSheet(activityItems: [url])
      }
    }
    .fileMover(isPresented: $showFileMover,
                file: self.selectedUrl,
                onCompletion: { res in self.selectedUrl = nil })
    .fileImporter(isPresented: $showFileImporter,
                  allowedContentTypes: [.plainText],
                  allowsMultipleSelection: true) { result in
      let sai = self.searchAndImport
      self.searchAndImport = false
      switch result {
        case .success(let urls):
          if !urls.isEmpty {
            if !sai {
              do {
                guard let selectedFile: URL = try result.get().first else {
                  return
                }
                if selectedFile.startAccessingSecurityScopedResource() {
                  defer {
                    selectedFile.stopAccessingSecurityScopedResource()
                  }
                  if let target = self.selectedUrl {
                    if !self.fileManager.copy(selectedFile, into: target) {
                      // Handle copy failed
                    }
                  }
                } else {
                  // Handle denied access
                }
              } catch {
                // Handle general failure
              }
            } else {
              
              self.presentationMode.wrappedValue.dismiss()
            }
          }
        case .failure(_):
          break
      }
    }
    .onAppear {
      if let url = self.url {
        self.fileName = url.lastPathComponent
        self.folder = url.deletingLastPathComponent()
        if let folder = self.folder {
          self.selectedUrls = [folder]
        }
      }
    }
  }
}

struct SaveAsView_Previews: PreviewProvider {
  @State static var fileName: String = "test.txt"
  
  static var previews: some View {
    SaveAsView(url: nil, onSave: { url in })
      .environmentObject(FileManager())
  }
}
