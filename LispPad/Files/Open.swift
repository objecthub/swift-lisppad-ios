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
import QuickLook

struct Open: View {
  @Environment(\.dismiss) var dismiss
  @EnvironmentObject var fileManager: FileManager
  @EnvironmentObject var histManager: HistoryManager
  
  @State var showShareSheet: Bool = false
  @State var showFileImporter: Bool = false
  @State var urlToMove: (URL, Bool)? = nil
  @State var searchAndImport: Bool = false
  @StateObject var context = FileHierarchyBrowser.BrowserContext()
  @State var previewUrl: URL? = nil
  @State var showError: Bool = false
  
  let title: String
  let directories: Bool
  let onSelection: ((URL, Bool) -> Bool)?
  
  init(title: String, directories: Bool = false, onSelection: ((URL, Bool) -> Bool)? = nil) {
    self.title = title
    self.directories = directories
    self.onSelection = onSelection
  }
  
  var body: some View {
    VStack(alignment: .center, spacing: 0) {
      if self.showShareSheet, let url = self.context.selectedUrl {
        ShareSheet(activityItems: [url])
          .transition(.move(edge: .top))
      } else if self.urlToMove == nil {
        ZStack(alignment: .top) {
          Color(.systemGroupedBackground).ignoresSafeArea()
          Form {
            Section {
              FileHierarchyBrowser(self.fileManager.usageRootDirectories,
                                   options: self.directories ? [.directories] : [.files],
                                   showShareSheet: $showShareSheet,
                                   showFileImporter: $showFileImporter,
                                   urlToMove: $urlToMove,
                                   context: self.context,
                                   previewUrl: $previewUrl,
                                   onSelection: { url in
                                     if let action = self.onSelection {
                                       let purl = PortableURL(url)
                                       if action(url, purl?.mutable ?? false) {
                                         self.dismiss()
                                       }
                                     }
                                   })
                .font(.body)
            } header: {
              Text("Usage")
                .padding(.top, 44)
            }
            Section {
              FileHierarchyBrowser(self.fileManager.userRootDirectories,
                                   options: self.directories ? [.directories, .mutable, .organizer]
                                                             : [.files, .mutable, .organizer],
                                   showShareSheet: $showShareSheet,
                                   showFileImporter: $showFileImporter,
                                   urlToMove: $urlToMove,
                                   context: self.context,
                                   previewUrl: $previewUrl,
                                   onSelection: { url in
                                     if let action = self.onSelection, action(url, true) {
                                       self.dismiss()
                                     }
                                   })
                .font(.body)
            } header: {
              Text("Locations")
            }
            Section {
              FileHierarchyBrowser(self.fileManager.systemRootDirectories,
                                   options: self.directories ? [.directories, .organizer]
                                                             : [.files, .organizer],
                                   showShareSheet: $showShareSheet,
                                   showFileImporter: $showFileImporter,
                                   urlToMove: $urlToMove,
                                   context: self.context,
                                   previewUrl: $previewUrl,
                                   onSelection: { url in
                                     if let action = self.onSelection, action(url, false) {
                                       self.dismiss()
                                     }
                                   })
                .font(.body)
            } header: {
              Text("System")
            }
          }
          VStack(alignment: .center, spacing: 0) {
            HStack {
              Button {
                self.showFileImporter = true
                self.searchAndImport = true
              } label: {
                Text("Browse")
              }
              Spacer()
              Text(self.title).bold()
              Spacer()
              Button {
                self.dismiss()
              } label: {
                Text("Cancel").bold()
              }
            }
            .font(.system(size: 17))
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(Color(.secondarySystemBackground).opacity(0.85))
            // Divider()
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
    .onChange(of: self.context.errorMessage) { _, new in
      self.showError = new != nil
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
              if let target = self.context.selectedUrl {
                self.copy(ArraySlice(urls), to: target, copied: 0, failed: [])
              }
            } else if let url = urls.first, let action = self.onSelection, action(url, false) {
              self.dismiss()
            }
          }
        case .failure(let error):
          self.context.errorMessage =
            .init(title: "Load Failure", message: error.localizedDescription)
      }
    }
    .quickLookPreview(self.$previewUrl)
  }
  
  func copy(_ slice: ArraySlice<URL>, to target: URL, copied: Int, failed: [(String, URL)]) {
    var urls = slice
    if urls.count > 0 && copied < 50 {
      let url = urls.removeFirst() 
      if url.startAccessingSecurityScopedResource() {
        self.fileManager.copy(url, to: target.appending(path: url.lastPathComponent)) { result in
          url.stopAccessingSecurityScopedResource()
          if case .failure(let error) = result {
            self.copy(urls, to: target, copied: copied + 1,
                      failed: failed + [(error.localizedDescription, url)])
          } else {
            self.copy(urls, to: target, copied: copied + 1, failed: failed)
          }
        }
      } else {
        self.copy(urls, to: target, copied: copied + 1, failed: failed + [("Access denied.", url)])
      }
    } else {
      if copied > failed.count {
        self.context.invalidateCaches()
      }
      switch failed.count {
        case 0:
          break
        case 1:
          self.context.errorMessage =
            .init(title: "Import Failure",
                  message: "Failed to import “\(failed.first!.1.lastPathComponent)“. " +
                           failed.first!.0)
        default:
          self.context.errorMessage =
              .init(title: "Import Failure",
                    message: "Failed to import \(failed.count) files, " +
                             "including “\(failed.first!.1.lastPathComponent)“. " +
                             failed.first!.0)
      }
    }
  }
}
