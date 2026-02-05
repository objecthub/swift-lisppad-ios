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
  
  struct ErrorMessage: Equatable {
    let title: String
    let message: String
  }
  
  class BrowserContext: ObservableObject {
    @Published var selectedUrl: URL? = nil
    @Published var editUrl: URL? = nil
    @Published var editName: String = ""
    @Published var selectedUrls: Set<URL> = []
    @Published var errorMessage: ErrorMessage? = nil
    
    var fileHierarchies: [() -> FileHierarchy.Children?] = []
    
    func register(hierarchy: FileHierarchy) {
      weak let hierarchy: FileHierarchy.Children? = hierarchy.container
      self.fileHierarchies.append { hierarchy }
    }
    
    func invalidateCaches() {
      for hierarchy in self.fileHierarchies {
        hierarchy()?.reset()
      }
      self.updateView()
    }
    
    func updateView() {
      UIApplication.shared.endEditing(true)
      self.objectWillChange.send()
    }
  }
  
  // Extract state from the environment
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
  
  /// Browser context
  @ObservedObject var context: BrowserContext
  
  /// Preview support
  @Binding var previewUrl: URL?
  
  /// Constructor
  init(_ namedRefs: [NamedRef],
       options: Options,
       showShareSheet: Binding<Bool>,
       showFileImporter: Binding<Bool>,
       urlToMove: Binding<(URL, Bool)?>,
       context: BrowserContext,
       previewUrl: Binding<URL?>,
       onSelection: ((URL) -> Void)? = nil) {
    self.options = options
    self.onSelection = onSelection
    self._showShareSheet = showShareSheet
    self._showFileImporter = showFileImporter
    self._urlToMove = urlToMove
    self.context = context
    self._previewUrl = previewUrl
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
        context.register(hierarchy: r)
      }
    }
    self.roots = roots
  }
  
  func isSelected(_ hierarchy: FileHierarchy) -> Bool {
    guard let url = hierarchy.url else {
      return false
    }
    return self.context.selectedUrls.contains(url)
  }
  
  func isSelectedContainer(_ hierarchy: FileHierarchy) -> Bool {
    guard !self.context.selectedUrls.isEmpty,
          let path = hierarchy.url?.path else {
      return false
    }
    for url in self.context.selectedUrls {
      if url.path.hasPrefix(path) {
        return true
      }
    }
    return false
  }
  
  @ViewBuilder
  func attachMenu<T: View>(_ hierarchy: FileHierarchy,
                           @ViewBuilder content: () -> T) -> some View {
    content()
      .contextMenu {
        if self.context.editUrl == nil {
          if self.options.contains(.mutable) && (hierarchy.kind != .file) {
            Button {
              if let url = hierarchy.url,
                 let dir = self.fileManager.makeDirectory(at: url) {
                hierarchy.container?.reset()
                self.context.editName = dir.lastPathComponent
                self.context.editUrl = dir
              }
            } label: {
              Label("New Folder", systemImage: "folder.badge.plus")
            }
            .disabled(hierarchy.type == .collection)
            if self.options.contains(.organizer) {
              Button {
                self.showFileImporter = true
                self.context.selectedUrl = hierarchy.url
              } label: {
                Label("Import Files…", systemImage: "square.and.arrow.down.on.square")
              }
              Divider()
            }
          }
          if self.options.contains(.mutable) &&
              (hierarchy.kind == .file || hierarchy.kind == .directory) {
            Button {
              self.context.editName = hierarchy.name
              self.context.editUrl = hierarchy.url
            } label: {
              Label("Rename", systemImage: "pencil")
            }
            if self.options.contains(.organizer) {
              Button {
                if let parent = hierarchy.parent,
                   let url = hierarchy.url {
                  if self.fileManager.duplicate(url) {
                    parent.reset()
                    self.refresher.updateView()
                  }
                }
              } label: {
                Label("Duplicate", systemImage: "plus.rectangle.on.rectangle")
              }
              Button {
                if let url = hierarchy.url {
                  withAnimation {
                    self.urlToMove = (url, false)
                  }
                }
              } label: {
                Label("Move…", systemImage: "folder")
              }
            }
          }
          if hierarchy.kind == .file || hierarchy.kind == .directory {
            Button {
              if let url = hierarchy.url {
                withAnimation {
                  self.urlToMove = (url, true)
                }
              }
            } label: {
              Label("Copy…", systemImage: "doc.on.doc")
            }
          }
          if self.options.contains([.mutable, .organizer]) &&
              (hierarchy.kind == .file || hierarchy.kind == .directory) {
            Button(role: .destructive) {
              if let parent = hierarchy.parent,
                 let url = hierarchy.url {
                self.fileManager.delete(url) { success in
                  if success {
                    parent.reset()
                    self.context.invalidateCaches()
                  }
                }
              }
            } label: {
              Label("Delete", systemImage: "trash")
                .foregroundColor(.red)
            }
            .disabled(hierarchy.url == nil
                        ? true
                        : PortableURL(url: hierarchy.url!) == self.histManager.currentlyEdited)
          }
          Divider()
          if hierarchy.parent != nil {
            Button {
              self.histManager.toggleFavorite(hierarchy.url)
              self.context.invalidateCaches()
            } label: {
              if self.histManager.isFavorite(hierarchy.url) {
                Label("Unstar", systemImage: "star.fill")
              } else {
                Label("Star", systemImage: "star")
              }
            }
          }
          if hierarchy.kind == .file, let url = hierarchy.url {
            ShareLink(item: url)
          }
          Button {
            if let url = hierarchy.url {
              UIPasteboard.general.string = url.path
            }
          } label: {
            Label("Copy Path", systemImage: "doc.on.clipboard")
          }
        }
      }
  }
  
  func rowContent(_ hierarchy: FileHierarchy) -> some View {
    HStack {
      if self.context.editUrl != nil && self.context.editUrl == hierarchy.url {
        ZStack {
          RoundedRectangle(cornerRadius: 8)
            .fill(Color(UIColor.secondarySystemFill))
          HStack {
            Label("", systemImage: hierarchy.systemImage)
              .foregroundColor(.red)
              .padding(.trailing, -8)
            TextField("", text: $context.editName, onCommit: {
              if !self.context.editName.isEmpty,
                 let url = self.context.editUrl {
                UIApplication.shared.endEditing(true)
                if let doc = self.fileManager.editorDocument,
                   url.absoluteURL == doc.fileURL {
                  doc.rename(to: self.context.editName) { newURL in
                    if newURL != nil {
                      hierarchy.parent?.reset()
                    }
                    self.context.editUrl = nil
                    self.context.editName = ""
                  }
                } else {
                  self.fileManager.rename(url, to: self.context.editName) { result in
                    switch result {
                      case .success(let newURL):
                        hierarchy.parent?.reset()
                        if self.context.selectedUrls.contains(url) {
                          self.context.selectedUrls.remove(url)
                          self.context.selectedUrls.insert(newURL)
                          self.refresher.updateView()
                        }
                      case .failure(let error):
                        self.context.errorMessage = .init(title: "Rename Failure",
                                                          message: error.localizedDescription)
                    }
                    self.context.editUrl = nil
                    self.context.editName = ""
                  }
                }
              }
            })
            .autocapitalization(.none)
            .disableAutocorrection(true)
            .padding(.top, -1.5)
            Button {
              self.context.editName = ""
            } label: {
              Image(systemName: "xmark.circle.fill")
                .foregroundColor(.gray)
                .opacity(self.context.editName.isEmpty ? 0 : 1)
            }
            .buttonStyle(.borderless)
            Spacer(minLength: 4)
            Button(action: {
              self.context.editUrl = nil
              self.context.editName = ""
            }) {
              Image(systemName: "arrow.uturn.backward.circle.fill")
                .foregroundColor(.gray)
            }
            .buttonStyle(.borderless)
            .padding(.trailing, 4)
          }
        }
      } else {
        if (hierarchy.type == .file) && !self.options.contains(.files) ||
            (hierarchy.type == .directory) && !self.options.contains(.directories) ||
            self.onSelection == nil ||
            self.context.editUrl != nil {
          self.attachMenu(hierarchy) {
            ZStack {
              if self.isSelected(hierarchy) {
                RoundedRectangle(cornerRadius: 8)
                  .fill(Color(UIColor.tertiarySystemFill))
              }
              HStack {
                Label {
                  Text(hierarchy.name)
                    .foregroundColor(.primary)
                } icon: {
                  Image(systemName: hierarchy.systemImage)
                    .foregroundColor(self.isSelectedContainer(hierarchy) ? .green : .primary)
                }
                Spacer()
                if hierarchy.type == .file {
                  Button {
                    self.previewUrl = hierarchy.url
                  } label: {
                    Image(systemName: "eye")
                      .foregroundColor(.gray)
                  }
                  .buttonStyle(.borderless)
                  .padding(.trailing, -4)
                }
              }
            }
          }
        } else {
          self.attachMenu(hierarchy) {
            Button {
              if let action = self.onSelection,
                 let url = hierarchy.url {
                action(url)
              }
            } label: {
              ZStack {
                if self.isSelected(hierarchy) {
                  RoundedRectangle(cornerRadius: 8)
                    .fill(Color(UIColor.tertiarySystemFill))
                }
                HStack {
                  Label {
                    Text(hierarchy.name)
                      .foregroundColor(.primary)
                  } icon: {
                    Image(systemName: hierarchy.systemImage)
                      .foregroundColor(self.isSelectedContainer(hierarchy) ? .green : .primary)
                  }
                  Spacer()
                  if hierarchy.type == .file {
                    Button {
                      self.previewUrl = hierarchy.url
                    } label: {
                      Image(systemName: "eye")
                        .foregroundColor(.gray)
                    }
                    .buttonStyle(.borderless)
                    .padding(.trailing, -4)
                  }
                }
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
    .listStyle(.automatic)
    .scrollDismissesKeyboard(.interactively)
  }
}
