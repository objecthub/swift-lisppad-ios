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


struct FileHierarchyView: View {
  
  // Extract state from the environment
  @Environment(\.presentationMode) var presentationMode
  @EnvironmentObject var fileManager: FileManager
  
  // This is a hack to be able to refresh the view on demand (this is needed because the
  // file hierarchy gets computed on demand and the hierarchy might change for mutable
  // hierarchy views). Need to figure out a better way to do this.
  @StateObject var refresher = Refresher()
  
  // Internal state
  private let roots: [FileHierarchy]
  private let fileType: FileType
  private let mutable: Bool
  private let action: ((URL, Bool) -> Void)?
  
  // Bindings to communicate with the context of the view
  @Binding var showFileMover: Bool
  @Binding var showFileImporter: Bool
  @Binding var showFileSharer: Bool
  @Binding var selectedUrl: URL?
  @Binding var editUrl: URL?
  @Binding var editName: String
  
  /// Constructor
  init(_ namedRefs: [NamedRef],
       fileType: FileType = .all,
       mutable: Bool = true,
       showFileMover: Binding<Bool>,
       showFileImporter: Binding<Bool>,
       showFileSharer: Binding<Bool>,
       selectedUrl: Binding<URL?>,
       editUrl: Binding<URL?>,
       editName: Binding<String>,
       action: ((URL, Bool) -> Void)? = nil) {
    self.fileType = fileType
    self.mutable = mutable
    self.action = action
    self._showFileMover = showFileMover
    self._showFileImporter = showFileImporter
    self._showFileSharer = showFileSharer
    self._selectedUrl = selectedUrl
    self._editUrl = editUrl
    self._editName = editName
    var roots: [FileHierarchy] = []
    for namedRef in namedRefs {
      if let root = FileHierarchy(namedRef) {
        roots.append(root)
      }
    }
    self.roots = roots
  }
  
  func rowContent(_ hierarchy: FileHierarchy) -> some View {
    HStack {
      if self.editUrl != nil && self.editUrl! == hierarchy.url {
        HStack {
          Label("", systemImage: hierarchy.systemImage)
            .foregroundColor(.red)
            .padding(.trailing, -8)
            .padding(.top, -2)
          TextField("", text: $editName, onEditingChanged: { isEditing in }, onCommit: {
            if !self.editName.isEmpty,
               let url = self.editUrl {
              _ = self.fileManager.rename(url, to: self.editName)
              hierarchy.parent?.reset()
              self.editUrl = nil
              self.editName = ""
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
          Spacer()
          Button(action: {
            self.editUrl = nil
            self.editName = ""
          }) {
            Image(systemName: "arrow.uturn.backward.circle.fill")
              .foregroundColor(.gray)
          }
          .buttonStyle(BorderlessButtonStyle())
        }
      } else {
        Button(action: {
          if let action = self.action,
             let url = hierarchy.url {
            DispatchQueue.main.async {
              action(url, self.mutable)
            }
            self.presentationMode.wrappedValue.dismiss()
          }
        }) {
          HStack {
            Label(title: { Text(hierarchy.name).foregroundColor(.primary) },
                  icon: { Image(systemName: hierarchy.systemImage) })
            Spacer()
          }
        }
        .disabled(!self.fileType.contains(hierarchy.type) ||
                  self.action == nil ||
                  self.editUrl != nil)
        .contextMenu {
          if self.editUrl == nil {
            if self.mutable && hierarchy.kind != .file {
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
              Button(action: {
                self.showFileImporter = true
                self.selectedUrl = hierarchy.url
              }) {
                Label("Import Files", systemImage: "square.and.arrow.down.on.square")
              }
              Divider()
            }
            if self.mutable {
              Button(action: {
                self.editName = hierarchy.name
                self.editUrl = hierarchy.url
              }) {
                Label("Rename", systemImage: "pencil")
              }
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
                self.showFileMover = true
                self.selectedUrl = hierarchy.url
              }) {
                Label("Move", systemImage: "folder")
              }
            }
            if self.mutable && (hierarchy.kind == .file || hierarchy.kind == .directory) {
              Button(action: {
                if let parent = hierarchy.parent,
                   let url = hierarchy.url {
                  if self.fileManager.delete(url) {
                    parent.reset()
                    self.refresher.updateView()
                  }
                }
              }) {
                Label("Delete", systemImage: "trash")
                  .foregroundColor(.red)
              }
            }
            if self.mutable {
              Divider()
            }
            Button(action: {
              self.showFileSharer = true
              self.selectedUrl = hierarchy.url
            }) {
              Label("Share", systemImage: "square.and.arrow.up")
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

public class Refresher: ObservableObject {
  func updateView() {
    self.objectWillChange.send()
  }
}
