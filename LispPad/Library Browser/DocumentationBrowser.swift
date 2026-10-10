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
    
    @Environment(\.containerGeometry) private var containerGeometry
    
    @ObservedObject var state: DocumentationBrowserState
    
    /// The current split view mode and master width fraction of the main view; both are needed to
    /// determine how much room the navigation bar offers for the toolbar title.
    let splitViewMode: SideBySideMode
    let masterWidthFraction: CGFloat
    
    /// Horizontal space taken up in the navigation bar by the leading and trailing toolbar buttons
    /// (including their margins) plus some slack. Whatever is left is available for the title.
    private static let toolbarButtonsWidth: CGFloat =
        2 * LispPadUI.toolbarButtonWidth + LispPadUI.toolbarTitleSlack
    
    /// Upper bound for the width of the library name in the navigation bar.
    private static let maxLibraryTitleWidth: CGFloat = 200
    
    /// Lower bound for the width of the library name in the navigation bar.
    private static let minLibraryTitleWidth: CGFloat = 60
    
    /// Minimum width of the browser pane at which the sidebar and detail columns are shown side by
    /// side (balanced style). Below this width, the sidebar fills the whole pane.
    private static let splitLayoutMinWidth: CGFloat = 580
    
    /// Minimum, ideal and maximum width of the sidebar column in the split layout.
    private static let sidebarMinWidth: CGFloat = 280
    private static let sidebarIdealWidth: CGFloat = 310
    private static let sidebarMaxWidth: CGFloat = 380
    
    /// The width of the navigation bar across the whole browser pane, not counting the areas that
    /// are reserved by the system (e.g. for a camera cutout).
    private var paneNavigationBarWidth: CGFloat {
      return self.containerGeometry.navigationBarWidth(
                 interpreter: true,
                 splitViewMode: self.splitViewMode,
                 masterWidthFraction: self.masterWidthFraction)
    }
    
    /// The title of the detail column: the selected identifier or, if there is none, the selected
    /// library.
    private var detailTitle: String {
      if self.state.selectedIdent?.isEmpty ?? true {
        return self.state.selectedLib?.name ?? "Libraries"
      } else {
        return self.state.selectedIdent ?? self.state.selectedLib?.name ?? "Documentation"
      }
    }
    
    /// Returns the width of the navigation bar of the detail column. In the split layout, the
    /// detail column shares the pane with the sidebar column, unless the latter is hidden.
    private func detailNavigationBarWidth(paneWidth: CGFloat) -> CGFloat {
      var barWidth = self.paneNavigationBarWidth
      if paneWidth >= DocumentationBrowser.splitLayoutMinWidth &&
         (self.state.columnVisibility == .doubleColumn || self.state.columnVisibility == .all) {
        barWidth -= DocumentationBrowser.sidebarIdealWidth
      }
      return barWidth
    }
    
    /// Returns the maximum width of the library name shown in the principal toolbar item of the
    /// identifier list. Names that do not fit into this width wrap into two lines.
    private func libraryTitleMaxWidth(paneWidth: CGFloat) -> CGFloat {
      var barWidth = self.paneNavigationBarWidth
      if paneWidth >= DocumentationBrowser.splitLayoutMinWidth {
        // With the balanced split view style, the navigation bar is only as wide as the sidebar
        // column (see `navigationSplitViewColumnWidth` below).
        barWidth = min(barWidth, DocumentationBrowser.sidebarIdealWidth)
      }
      return max(min(barWidth - DocumentationBrowser.toolbarButtonsWidth,
                     DocumentationBrowser.maxLibraryTitleWidth),
                 DocumentationBrowser.minLibraryTitleWidth)
    }
    
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
                    if !self.state.selectedLibIdents.isEmpty ||
                       (self.docManager.libraryDocumentation(for: proxy.components) != nil) {
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
                      .font(LispPadUI.toolbarIconFont)
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
                    Image(systemName: "xmark")
                      .font(LispPadUI.toolbarIconFont)
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
                      .font(LispPadUI.toolbarIconFont)
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
                          .font(LispPadUI.toolbarTitleFont(
                                  for: self.state.selectedLib?.name ?? "Identifiers"))
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
                    .frame(maxWidth: self.libraryTitleMaxWidth(paneWidth: geometry.size.width))
                  }
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                  Button {
                    withAnimation {
                      self.state.docShown = false
                    }
                  } label: {
                    Image(systemName: "xmark")
                      .font(LispPadUI.toolbarIconFont)
                  }
                }
              }
              .transition(.move(edge: .trailing))
            }
          }
          .navigationSplitViewColumnWidth(min: DocumentationBrowser.sidebarMinWidth,
                                          ideal: DocumentationBrowser.sidebarIdealWidth,
                                          max: DocumentationBrowser.sidebarMaxWidth)
        } detail: {
          DocumentationDetailView(columnVisibility: $state.columnVisibility,
                                  selectedLib: $state.selectedLib,
                                  selectedIdent: $state.selectedIdent,
                                  docShown: $state.docShown,
                                  title: self.detailTitle,
                                  barWidth: self.detailNavigationBarWidth(
                                              paneWidth: geometry.size.width))
          .navigationTitle(self.detailTitle)
          .navigationBarTitleDisplayMode(.inline)
          .navigationSplitViewColumnWidth(min: 280, ideal: 500, max: 900)
        }
        if geometry.size.width < DocumentationBrowser.splitLayoutMinWidth {
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
