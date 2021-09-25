//
//  Open.swift
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

struct Open: View {
  @Environment(\.presentationMode) var presentationMode
  @EnvironmentObject var fileManager: FileManager
  
  @State var showShareSheet: Bool = false
  @State var showFileImporter: Bool = false
  @State var urlToMove: (URL, Bool)? = nil
  @State var searchAndImport: Bool = false
  @State var selectedUrl: URL? = nil
  @State var editUrl: URL? = nil
  @State var editName: String = ""
  @State var selectedUrls: Set<URL> = []
  
  let directories: Bool
  let onSelection: ((URL, Bool) -> Bool)?
  
  init(directories: Bool = false, onSelection: ((URL, Bool) -> Bool)? = nil) {
    self.directories = directories
    self.onSelection = onSelection
  }
  
  var body: some View {
    VStack(alignment: .center, spacing: 0) {
      if self.showShareSheet, let url = self.selectedUrl {
        ShareSheet(activityItems: [url])
          .transition(.move(edge: .top))
      } else if self.urlToMove == nil {
        ZStack {
          Color(.systemGroupedBackground).ignoresSafeArea()
          VStack(alignment: .center, spacing: 0.0) {
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
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 8)
            Form {
              Section(header: Text("Usage")) {
                FileHierarchyBrowser(self.fileManager.usageRootDirectories,
                                     options: self.directories ? [.directories] : [.files],
                                     showShareSheet: $showShareSheet,
                                     showFileImporter: $showFileImporter,
                                     urlToMove: $urlToMove,
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
              Section(header: Text("Locations")) {
                FileHierarchyBrowser(self.fileManager.userRootDirectories,
                                     options: self.directories ? [.directories, .mutable, .organizer]
                                                               : [.files, .mutable, .organizer],
                                     showShareSheet: $showShareSheet,
                                     showFileImporter: $showFileImporter,
                                     urlToMove: $urlToMove,
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
                FileHierarchyBrowser(self.fileManager.systemRootDirectories,
                                     options: self.directories ? [.directories, .organizer]
                                                               : [.files, .organizer],
                                     showShareSheet: $showShareSheet,
                                     showFileImporter: $showFileImporter,
                                     urlToMove: $urlToMove,
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
        }
        .transition(.move(edge: .top))
      } else {
        Move(showShareSheet: $showShareSheet,
             showFileImporter: $showFileImporter,
             urlToMove: $urlToMove)
          .transition(.move(edge: .bottom))
      }
    }
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
                    self.fileManager.copy(selectedFile, to: target) { url in
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
