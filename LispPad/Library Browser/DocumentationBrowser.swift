  //
  //  DocumentationBrowser.swift
  //  LispPad
  //
  //  Created by Matthias Zenger on 25/10/2025.
  //  Copyright © 2025 Matthias Zenger. All rights reserved.
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

  struct DocumentationBrowser: View {
    @Environment(\.horizontalSizeClass) var sizeClass
    @Environment(\.colorScheme) var colorScheme
    
    @EnvironmentObject var interpreter: Interpreter
    @EnvironmentObject var docManager: DocumentationManager
    
    @Binding var selectedLib: LibraryManager.LibraryProxy?
    @Binding var selectedIdent: String?
    @Binding var docShown: Bool
    
    @State private var columnVisibility = NavigationSplitViewVisibility.doubleColumn
    @State private var preferredColumn = NavigationSplitViewColumn.sidebar
    @State private var searchLib: String = ""
    @State private var searchIdent: String = ""
    @State private var showLoadedLibraries: Bool = false
    @State private var showLibraryBrowser: Bool = true
    @State private var toggleSidebar: Bool = false
    @State private var selectedLibIdents: [String] = []
    
    var body: some View {
      GeometryReader { geometry in
        let view = NavigationSplitView(columnVisibility: self.$columnVisibility,
                                       preferredCompactColumn: self.$preferredColumn) {
          ZStack {
            if self.showLibraryBrowser {
              List(self.interpreter.libManager.libraries.filter { proxy in 
                    (!self.showLoadedLibraries || proxy.isLoaded) &&
                    (self.searchLib.isEmpty ||
                      proxy.name.range(of: self.searchLib, options: .caseInsensitive) != nil)
                   },
                   id: \.name) { proxy in
                Button {
                  withAnimation {
                    self.selectedLibIdents = self.docManager.libraryExports(
                      for: proxy.components,
                      merging: proxy) ?? []
                    self.selectedLib = proxy
                    if !self.selectedLibIdents.isEmpty {
                      self.toggleSidebar.toggle()
                    }
                  }
                } label: {
                  HStack(spacing: 12) {
                    Text(proxy.name)
                      .font(.body)
                    Spacer()
                    Text(proxy.state)
                      .font(.caption)
                      .foregroundStyle(.secondary)
                  }
                }
                .foregroundStyle(proxy == self.selectedLib ? Color.white : .primary)
                .listRowBackground(proxy == self.selectedLib ? Color.green : Color.clear)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                  Button("Import", systemImage: "square.and.arrow.down") {
                    self.interpreter.import(proxy.components)
                  }
                  .tint(.blue)
                }
                // .disabled(self.docManager.libraryDocumentation(for: proxy.components) == nil)
              }
              .refreshable {
                self.interpreter.libManager.updateLibraries()
              }
              .listStyle(.plain)
              .searchable(text: $searchLib)
              .navigationBarTitleDisplayMode(.inline)
              /* .gesture(DragGesture()
                .onEnded { value in
                  if value.startLocation.x > value.location.x + 24 {
                    if self.selectedLib != nil {
                      self.toggleSidebar.toggle()
                    }
                  }
                }
              ) */
              .onChange(of: self.selectedLib) { _, _ in
                 self.selectedIdent = nil
              }
              .onChange(of: self.toggleSidebar) { _, _ in
                withAnimation {
                  self.showLibraryBrowser = false
                }
              }
              .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                  Button {
                    if self.selectedLib != nil {
                      self.toggleSidebar.toggle()
                    }
                  } label: {
                    Image(systemName: "chevron.right")
                  }
                  .disabled(self.selectedLib == nil)
                }
                ToolbarItemGroup(placement: .principal) {
                  Menu {
                    Toggle(isOn: self.$showLoadedLibraries) {
                      Label("Only Loaded", systemImage: "line.3.horizontal.decrease")
                    }
                  } label: {
                    HStack(alignment: .center, spacing: 4) {
                      if geometry.size.width >= 380 {
                        Text("Libraries")
                          .font(.body)
                          .bold()
                          .foregroundColor(.primary)
                      }
                      Text(Image(systemName: "chevron.down.circle.fill"))
                        .font(.caption)
                        .bold()
                        .foregroundColor(Color(LispPadUI.menuIndicatorColor))
                    }
                  }
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                  Button {
                    withAnimation {
                      self.docShown = false
                    }
                  } label: {
                    Image(systemName: "xmark.circle.fill")
                      .foregroundStyle(self.colorScheme == .light ? .white : .black, .gray)
                    // Image(systemName: "apple.terminal.on.rectangle.fill")
                  }
                }
              }
              .transition(.move(edge: .leading))
            } else {
              List(self.selectedLibIdents.filter { ident in
                     (self.searchIdent.isEmpty ||
                       ident.range(of: self.searchIdent, options: .caseInsensitive) != nil)
                   },
                   id: \.self, selection: $selectedIdent) { ident in
                NavigationLink(ident, value: ident)
              }
              .listStyle(.plain)
              .searchable(text: $searchIdent)
              .navigationBarTitleDisplayMode(.inline)
              .gesture(DragGesture()
                .onEnded { value in
                  if value.startLocation.x < value.location.x - 24 {
                    withAnimation {
                      self.showLibraryBrowser = true
                    }
                  }
                  if value.startLocation.x > value.location.x + 24 {
                    if (columnVisibility == .doubleColumn ||
                        columnVisibility == .all) {
                      withAnimation {
                        columnVisibility = .detailOnly
                      }
                    }
                  }
                })
              .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                  Button {
                    withAnimation {
                      self.showLibraryBrowser = true
                    }
                  } label: {
                    Image(systemName: "chevron.left")
                  }
                  .padding(.init(top: 0, leading: -2, bottom: 0, trailing: 0))
                }
                ToolbarItem(placement: .principal) {
                  Button {
                    withAnimation {
                      self.selectedIdent = ""
                      if self.sizeClass == .compact || geometry.size.width < 700 {
                        self.columnVisibility = .detailOnly
                      }
                    }
                  } label: {
                    HStack(alignment: .center, spacing: 3) {
                      if geometry.size.width >= 280 {
                        Text(self.selectedLib?.name ?? "Identifiers")
                          .font((self.selectedLib?.name ?? "Identifiers").count >= 20
                                  ? LispPadUI.fileNameFont
                                  : LispPadUI.largeFileNameFont)
                          .bold()
                          .foregroundColor(.primary)
                          .truncationMode(.middle)
                          .multilineTextAlignment(.center)
                          .lineLimit(2)
                          .fixedSize(horizontal: false, vertical: true)
                      }
                      Text(Image(systemName: "book.closed"))
                        .font(.caption)
                        .bold()
                        .foregroundStyle(.tint)
                    }
                    .frame(maxWidth: 180)
                  }
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                  HStack(alignment: .center, spacing: LispPadUI.toolbarSeparator) {
                    Button {
                      withAnimation {
                        self.docShown = false
                      }
                    } label: {
                      Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(self.colorScheme == .light ? .white : .black, .gray)
                      // Image(systemName: "apple.terminal.on.rectangle.fill")
                    }
                  }
                }
              }
              .transition(.move(edge: .trailing))
            }
          }
          .navigationSplitViewColumnWidth(min: 280, ideal: 310, max: 380)
        } detail: {
          DocumentationDetailView(columnVisibility: self.$columnVisibility,
                                  selectedLib: self.$selectedLib,
                                  selectedIdent: self.$selectedIdent,
                                  docShown: self.$docShown)
          .navigationTitle((self.selectedIdent?.isEmpty ?? true)
                             ? (self.selectedLib?.name ?? "Documentation")
                             : (self.selectedIdent ?? self.selectedLib?.name ?? "Documentation"))
          .navigationBarTitleDisplayMode(.inline)
          .navigationSplitViewColumnWidth(min: 280, ideal: 500, max: 900)
        }
        if geometry.size.width < 580 {
          view
            .navigationSplitViewStyle(.prominentDetail)
            .tint(Color.green)
        } else {
          view
            .navigationSplitViewStyle(.balanced)
            .tint(Color.green)
        }
      }
    }
  }
