//
//  OpenView.swift
//  LispPad
//
//  Created by Matthias Zenger on 01/04/2021.
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

struct OpenView: View {
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
  
  let selectDirectory: Bool
  let onSelection: ((URL, Bool) -> Bool)?
  
  init(selectDirectory: Bool, onSelection: ((URL, Bool) -> Bool)? = nil) {
    self.selectDirectory = selectDirectory
    self.onSelection = onSelection
  }
  
  var body: some View {
    VStack(alignment: .center, spacing: 0) {
      HStack {
        Button(action: {
          self.showFileImporter = true
          self.searchAndImport = true
        }) {
          Text("Search & Import")
        }
        Spacer()
        Button(action: {
          self.presentationMode.wrappedValue.dismiss()
        }) {
          Text("Cancel")
        }
      }
      .font(.body)
      .padding()
      .edgesIgnoringSafeArea(.all)
      .background(Color(UIColor.secondarySystemBackground))
      Form {
        Section(header: Text("Usage")) {
          FileHierarchyView(self.fileManager.usageRootDirectories,
                            selectDirectory: self.selectDirectory,
                            mutable: false,
                            showFileMover: $showFileMover,
                            showFileImporter: $showFileImporter,
                            showFileSharer: $showFileSharer,
                            selectedUrl: $selectedUrl,
                            editUrl: $editUrl,
                            editName: $editName,
                            selectedUrls: $selectedUrls,
                            onSelection: { url in
                              if let action = self.onSelection, action(url, false) {
                                self.presentationMode.wrappedValue.dismiss()
                              }
                            })
            .font(.body)
        }
        Section(header: Text("User")) {
          FileHierarchyView(self.fileManager.userRootDirectories,
                            selectDirectory: self.selectDirectory,
                            mutable: true,
                            showFileMover: $showFileMover,
                            showFileImporter: $showFileImporter,
                            showFileSharer: $showFileSharer,
                            selectedUrl: $selectedUrl,
                            editUrl: $editUrl,
                            editName: $editName,
                            selectedUrls: $selectedUrls,
                            onSelection: { url in
                              if let action = self.onSelection, action(url, true) {
                                self.presentationMode.wrappedValue.dismiss()
                              }
                            })
            .font(.body)
        }
        Section(header: Text("System")) {
          FileHierarchyView(self.fileManager.systemRootDirectories,
                            selectDirectory: self.selectDirectory,
                            mutable: false,
                            showFileMover: $showFileMover,
                            showFileImporter: $showFileImporter,
                            showFileSharer: $showFileSharer,
                            selectedUrl: $selectedUrl,
                            editUrl: $editUrl,
                            editName: $editName,
                            selectedUrls: $selectedUrls,
                            onSelection: { url in
                              if let action = self.onSelection, action(url, false) {
                                self.presentationMode.wrappedValue.dismiss()
                              }
                            })
            .font(.body)
        }
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
  }
}

struct OpenView_Previews: PreviewProvider {
  static var previews: some View {
    OpenView(selectDirectory: false)
      .environmentObject(FileManager())
      .environmentObject(HistoryManager())
  }
}
