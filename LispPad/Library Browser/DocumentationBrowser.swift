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
    
    @ObservedObject var state: DocumentationBrowserState
    
    var body: some View {
      GeometryReader { geometry in
        let view = NavigationSplitView(columnVisibility: $state.columnVisibility,
                                       preferredCompactColumn: $state.preferredColumn) {
          ZStack {
            if self.state.showLibraryBrowser {
              List(self.interpreter.libManager.libraries.filter { proxy in 
                    (!self.state.showLoadedLibraries || proxy.isLoaded) &&
                    (self.state.searchLib.isEmpty ||
                       proxy.name.range(of: self.state.searchLib, options: .caseInsensitive) != nil)
                   },
                   id: \.name) { proxy in
                Button {
                  withAnimation {
                    self.state.selectedLibIdents =
                      self.docManager.libraryExports(for: proxy.components, merging: proxy) ?? []
                    self.state.selectedLib = proxy
                    if !self.state.selectedLibIdents.isEmpty {
                      self.state.toggleSidebar.toggle()
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
                .foregroundStyle(proxy == self.state.selectedLib ? Color.white : .primary)
                .listRowBackground(proxy == self.state.selectedLib ? Color.green : Color.clear)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                  Button("Import", systemImage: "square.and.arrow.down") {
                    self.interpreter.import(proxy.components)
                  }
                  .tint(.blue)
                }
              }
              .refreshable {
                self.interpreter.libManager.updateLibraries()
              }
              .listStyle(.plain)
              .searchable(text: $state.searchLib)
              .navigationBarTitleDisplayMode(.inline)
              .onChange(of: self.state.selectedLib) { _, _ in
                self.state.selectedIdent = nil
              }
              .onChange(of: self.state.toggleSidebar) { _, _ in
                withAnimation {
                  self.state.showLibraryBrowser = false
                }
              }
              .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                  Button {
                    if self.state.selectedLib != nil {
                      self.state.toggleSidebar.toggle()
                    }
                  } label: {
                    Image(systemName: "chevron.right")
                  }
                  .disabled(self.state.selectedLib == nil)
                }
                ToolbarItemGroup(placement: .principal) {
                  Menu {
                    Toggle(isOn: $state.showLoadedLibraries) {
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
                      self.state.docShown = false
                    }
                  } label: {
                    Image(systemName: "xmark.circle.fill")
                      .foregroundStyle(self.colorScheme == .light ? .white : .black, .gray)
                  }
                }
              }
              .transition(.move(edge: .leading))
            } else {
              List(self.state.selectedLibIdents.filter { ident in
                       (self.state.searchIdent.isEmpty ||
                        ident.range(of: self.state.searchIdent, options: .caseInsensitive) != nil)
                   },
                   id: \.self,
                   selection: $state.selectedIdent) { ident in
                NavigationLink(ident, value: ident)
              }
              .listStyle(.plain)
              .searchable(text: $state.searchIdent)
              .navigationBarTitleDisplayMode(.inline)
              .gesture(DragGesture()
                .onEnded { value in
                  if value.startLocation.x < value.location.x - 24 {
                    withAnimation {
                      self.state.showLibraryBrowser = true
                    }
                  }
                  if value.startLocation.x > value.location.x + 24 {
                    if (self.state.columnVisibility == .doubleColumn ||
                        self.state.columnVisibility == .all) {
                      withAnimation {
                        self.state.columnVisibility = .detailOnly
                      }
                    }
                  }
                })
              .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                  Button {
                    withAnimation {
                      self.state.showLibraryBrowser = true
                    }
                  } label: {
                    Image(systemName: "chevron.left")
                  }
                  .padding(.init(top: 0, leading: -2, bottom: 0, trailing: 0))
                }
                ToolbarItem(placement: .principal) {
                  Button {
                    withAnimation {
                      self.state.selectedIdent = ""
                      if self.sizeClass == .compact || geometry.size.width < 700 {
                        self.state.columnVisibility = .detailOnly
                      }
                    }
                  } label: {
                    HStack(alignment: .center, spacing: 3) {
                      if geometry.size.width >= 280 {
                        Text(self.state.selectedLib?.name ?? "Identifiers")
                          .font((self.state.selectedLib?.name ?? "Identifiers").count >= 20
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
                        self.state.docShown = false
                      }
                    } label: {
                      Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(self.colorScheme == .light ? .white : .black, .gray)
                    }
                  }
                }
              }
              .transition(.move(edge: .trailing))
            }
          }
          .navigationSplitViewColumnWidth(min: 280, ideal: 310, max: 380)
        } detail: {
          DocumentationDetailView(columnVisibility: $state.columnVisibility,
                                  selectedLib: $state.selectedLib,
                                  selectedIdent: $state.selectedIdent,
                                  docShown: $state.docShown)
          .navigationTitle((self.state.selectedIdent?.isEmpty ?? true)
                             ? (self.state.selectedLib?.name ?? "Documentation")
                             : (self.state.selectedIdent ?? self.state.selectedLib?.name ?? "Documentation"))
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
