//
//  FileHierarchyViewer.swift
//  LispPad
//
//  Created by Matthias Zenger on 02/04/2021.
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

struct FileHierarchyBrowser: View {
  
  struct Options: OptionSet {
    let rawValue: Int
    static let files = Options(rawValue: 1 << 0)
    static let directories   = Options(rawValue: 1 << 1)
    static let mutable = Options(rawValue: 1 << 2)
    static let organizer = Options(rawValue: 1 << 3)
  }
  
  class Refresher: ObservableObject {
    func updateView() {
      self.objectWillChange.send()
    }
  }

  // Extract state from the environment
  @Environment(\.presentationMode) var presentationMode
  @EnvironmentObject var fileManager: FileManager
  @EnvironmentObject var histManager: HistoryManager
  
  // This is a hack to be able to refresh the view on demand (this is needed because the
  // file hierarchy gets computed on demand and the hierarchy might change for mutable
  // hierarchy views). Need to figure out a better way to do this.
  @StateObject var refresher = Refresher()
  
  // Internal state
  private let roots: [FileHierarchy]
  private let options: Options
  private let onSelection: ((URL) -> Void)?
  
  // Bindings to communicate with the context of the view
  
  /// Other modal views defined outside
  @Binding var showShareSheet: Bool
  @Binding var showFileImporter: Bool
  @Binding var urlToMove: (URL, Bool)?
  
  /// The URL used by file mover, file importer and file sharer
  @Binding var selectedUrl: URL?
  
  /// Rename support
  @Binding var editUrl: URL?
  @Binding var editName: String
  
  /// Selection support
  @Binding var selectedUrls: Set<URL>
  
  /// Constructor
  init(_ namedRefs: [NamedRef],
       options: Options,
       showShareSheet: Binding<Bool>,
       showFileImporter: Binding<Bool>,
       urlToMove: Binding<(URL, Bool)?>,
       selectedUrl: Binding<URL?>,
       editUrl: Binding<URL?>,
       editName: Binding<String>,
       selectedUrls: Binding<Set<URL>>,
       onSelection: ((URL) -> Void)? = nil) {
    self.options = options
    self.onSelection = onSelection
    self._showShareSheet = showShareSheet
    self._showFileImporter = showFileImporter
    self._urlToMove = urlToMove
    self._selectedUrl = selectedUrl
    self._editUrl = editUrl
    self._editName = editName
    self._selectedUrls = selectedUrls
    var roots: [FileHierarchy] = []
    for namedRef in namedRefs {
      if let r = FileHierarchy(
                   namedRef,
                   filter: options.contains(.files) ||
                             !options.contains(.directories) ? .file : .directory,
                   extensions: options.contains(.organizer) &&
                               !options.contains(.files) &&
                               !options.contains(.directories) ? nil
                                                               : FileExtensions.editorSupport) {
        roots.append(r)
      }
    }
    self.roots = roots
  }
  
  func isSelected(_ hierarchy: FileHierarchy) -> Bool {
    guard let url = hierarchy.url else {
      return false
    }
    return self.selectedUrls.contains(url)
  }
  
  func isSelectedContainer(_ hierarchy: FileHierarchy) -> Bool {
    guard !self.selectedUrls.isEmpty,
          let path = hierarchy.url?.path else {
      return false
    }
    for url in self.selectedUrls {
      if url.path.hasPrefix(path) {
        return true
      }
    }
    return false
  }
  
  func rowContent(_ hierarchy: FileHierarchy) -> some View {
    HStack {
      if self.editUrl != nil && self.editUrl == hierarchy.url {
        ZStack {
          RoundedRectangle(cornerRadius: 8)
            .fill(Color(UIColor.secondarySystemFill))
          HStack {
            Label("", systemImage: hierarchy.systemImage)
              .foregroundColor(.red)
              .padding(.trailing, -8)
              .padding(.top, -2)
            TextField("", text: $editName, onEditingChanged: { isEditing in }, onCommit: {
              if !self.editName.isEmpty,
                 let url = self.editUrl {
                if let doc = self.fileManager.editorDocument,
                   url.absoluteURL == doc.fileURL {
                  doc.rename(to: self.editName) { newURL in
                    if newURL != nil {
                      hierarchy.parent?.reset()
                    }
                    self.editUrl = nil
                    self.editName = ""
                  }
                } else {
                  self.fileManager.rename(url, to: self.editName) { newURL in
                    if newURL != nil {
                      hierarchy.parent?.reset()
                      if self.selectedUrls.contains(url) {
                        self.selectedUrls.remove(url)
                        self.selectedUrls.insert(newURL!)
                        self.refresher.updateView()
                      }
                    }
                    self.editUrl = nil
                    self.editName = ""
                  }
                }
              }
            })
            .autocapitalization(.none)
            .disableAutocorrection(true)
            Button(action: {
              self.editName = ""
            }) {
              Image(systemName: "xmark.circle.fill")
                .foregroundColor(.gray)
                .opacity(self.editName.isEmpty ? 0 : 1)
            }
            .buttonStyle(BorderlessButtonStyle())
            Spacer(minLength: 4)
            Button(action: {
              self.editUrl = nil
              self.editName = ""
            }) {
              Image(systemName: "arrow.uturn.backward.circle.fill")
                .foregroundColor(.gray)
            }
            .buttonStyle(BorderlessButtonStyle())
            .padding(.trailing, 4)
          }
        }
      } else {
        Button(action: {
          if let action = self.onSelection,
             let url = hierarchy.url {
            action(url)
          }
        }) {
          ZStack {
            if self.isSelected(hierarchy) {
              RoundedRectangle(cornerRadius: 8)
                .fill(Color(UIColor.tertiarySystemFill))
            }
            HStack {
              Label(title: {
                      Text(hierarchy.name)
                        .foregroundColor(.primary)
                    },
                    icon: {
                      Image(systemName: hierarchy.systemImage)
                        .foregroundColor(self.isSelectedContainer(hierarchy) ? .green : .primary)
                    })
              Spacer()
            }
          }
        }
        .disabled((hierarchy.type == .file) && !self.options.contains(.files) ||
                    (hierarchy.type == .directory) && !self.options.contains(.directories) ||
                    self.onSelection == nil ||
                    self.editUrl != nil)
        .contextMenu {
          if self.editUrl == nil {
            if self.options.contains(.mutable) && (hierarchy.kind != .file) {
              Button(action: {
                if let url = hierarchy.url,
                   let dir = self.fileManager.makeDirectory(at: url) {
                  hierarchy.container?.reset()
                  self.editName = dir.lastPathComponent
                  self.editUrl = dir
                }
              }) {
                Label("New Folder", systemImage: "folder.badge.plus")
              }
              .disabled(hierarchy.type == .collection)
              if self.options.contains(.organizer) {
                Button(action: {
                  self.showFileImporter = true
                  self.selectedUrl = hierarchy.url
                }) {
                  Label("Import Files…", systemImage: "square.and.arrow.down.on.square")
                }
                Divider()
              }
            }
            if self.options.contains(.mutable) &&
                (hierarchy.kind == .file || hierarchy.kind == .directory) {
              Button(action: {
                self.editName = hierarchy.name
                self.editUrl = hierarchy.url
              }) {
                Label("Rename", systemImage: "pencil")
              }
              if self.options.contains(.organizer) {
                Button(action: {
                  if let parent = hierarchy.parent,
                     let url = hierarchy.url {
                    if self.fileManager.duplicate(url) {
                      parent.reset()
                      self.refresher.updateView()
                    }
                  }
                }) {
                  Label("Duplicate", systemImage: "plus.rectangle.on.rectangle")
                }
                Button(action: {
                  if let url = hierarchy.url {
                    withAnimation(.default) {
                      self.urlToMove = (url, false)
                    }
                  }
                }) {
                  Label("Move…", systemImage: "folder")
                }
              }
            }
            if hierarchy.kind == .file || hierarchy.kind == .directory {
              Button(action: {
                if let url = hierarchy.url {
                  withAnimation(.default) {
                    self.urlToMove = (url, true)
                  }
                }
              }) {
                Label("Copy…", systemImage: "doc.on.doc")
              }
            }
            if self.options.contains([.mutable, .organizer]) &&
                (hierarchy.kind == .file || hierarchy.kind == .directory) {
              Button(action: {
                if let parent = hierarchy.parent,
                   let url = hierarchy.url {
                  self.fileManager.delete(url) { success in
                    if success {
                      parent.reset()
                      self.refresher.updateView()
                    }
                  }
                }
              }) {
                Label("Delete", systemImage: "trash")
                  .foregroundColor(.red)
              }
            }
            if hierarchy.parent != nil || hierarchy.kind == .file || hierarchy.kind == .directory {
              Divider()
            }
            if hierarchy.parent != nil {
              Button(action: {
                self.histManager.toggleFavorite(hierarchy.url)
              }) {
                if self.histManager.isFavorite(hierarchy.url) {
                  Label("Unstar", systemImage: "star.fill")
                } else {
                  Label("Star", systemImage: "star")
                }
              }
            }
            if hierarchy.kind == .file {
              Button(action: {
                self.selectedUrl = hierarchy.url
                self.showShareSheet = true
              }) {
                Label("Share", systemImage: "square.and.arrow.up")
              }
            }
          }
        }
      }
    }
  }
  
  var body: some View {
    List(self.roots,
         children: \.children,
         rowContent: self.rowContent)
    .resignKeyboardOnDragGesture()
    .listStyle(DefaultListStyle())
  }
}
