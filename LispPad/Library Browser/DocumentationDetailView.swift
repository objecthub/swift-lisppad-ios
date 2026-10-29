//
//  DocumentationDetailView.swift
//  LispPad
//
//  Created by Matthias Zenger on 31/10/2025.
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
import MarkdownKit

struct DocumentationDetailView: View {
  @Environment(\.horizontalSizeClass) var sizeClass
  @Environment(\.colorScheme) var colorScheme
  
  @EnvironmentObject var docManager: DocumentationManager
  @EnvironmentObject var globals: LispPadGlobals

  @Binding var columnVisibility: NavigationSplitViewVisibility
  @Binding var selectedLib: LibraryManager.LibraryProxy?
  @Binding var selectedIdent: String?
  @Binding var docShown: Bool
  
  /// The title of the detail column and the width of the navigation bar it is shown in.
  let title: String
  let barWidth: CGFloat
  
  @StateObject var controller = WebViewController()
  @State var block: Block? = nil
  @State var url: URL? = nil
  @State var toggle: Bool = true
  @State var zoomListShown: Bool = false

  /// Horizontal space taken up in the navigation bar by the back/forward buttons for web content.
  private static let webNavigationButtonsWidth: CGFloat = 80
  
  /// Horizontal space taken up in the navigation bar by the zoom menu for web content.
  private static let zoomMenuWidth: CGFloat = 36

  /// Upper bound for the width of the title in the navigation bar.
  private static let maxTitleWidth: CGFloat = 320
  
  /// Lower bound for the width of the title in the navigation bar. If less space is available,
  /// the default title of the navigation bar, which doesn't wrap, is shown instead.
  private static let minTitleWidth: CGFloat = 80
  
  /// Returns true if the detail column is shown on its own (i.e. there is no sidebar column next
  /// to it). In this case, the navigation bar has a button for getting back to the sidebar column
  /// and a button for closing the documentation browser.
  private var isStandalone: Bool {
    return self.sizeClass == .compact ||
           (self.columnVisibility != .doubleColumn && self.columnVisibility != .all)
  }
  
  /// Returns the maximum width of the title in the navigation bar, which is the width that is
  /// left after subtracting the space needed for the toolbar buttons. Titles that do not fit into
  /// this width wrap into two lines.
  private var titleMaxWidth: CGFloat {
    let hasWeb = self.url != nil
    let leading = (self.isStandalone ? LispPadUI.toolbarButtonWidth : 0) +
                  (hasWeb ? DocumentationDetailView.webNavigationButtonsWidth : 0)
    let trailing = (self.isStandalone ? LispPadUI.toolbarButtonWidth : 0) +
                   (hasWeb ? DocumentationDetailView.zoomMenuWidth : 0)
    // The title is centered in the navigation bar; so the busier side limits both sides.
    return min(self.barWidth - 2 * max(leading, trailing) - LispPadUI.toolbarTitleSlack,
               DocumentationDetailView.maxTitleWidth)
  }
  
  /// The zoom levels offered for web content.
  private static let zoomLevels: [CGFloat] = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0]

  /// Width of the list of zoom levels. A system menu would be much wider than its entries, so the
  /// list is shown in a popover of its own.
  private static let zoomListWidth: CGFloat = 112

  /// The zoom levels listed in the zoom menu. A pinch gesture can result in a zoom level that is
  /// not one of the offered levels. In this case, the current zoom level is listed in addition,
  /// such that it is always shown in the menu.
  private var zoomChoices: [CGFloat] {
    let zoom = self.controller.zoom
    if DocumentationDetailView.zoomLevels.contains(where: { abs($0 - zoom) < 0.01 }) {
      return DocumentationDetailView.zoomLevels
    }
    return (DocumentationDetailView.zoomLevels + [zoom]).sorted()
  }

  private func percent(_ zoom: CGFloat) -> String {
    return "\(Int((zoom * 100.0).rounded()))%"
  }

  /// A button for changing the zoom level of web content. The button only shows an icon to save
  /// space in the navigation bar. The current zoom level is marked in the list the button opens.
  private var zoomMenu: some View {
    Button {
      self.zoomListShown = true
    } label: {
      ViewThatFits(in: .horizontal) {
        Text("\(self.percent(self.controller.zoom))")
          .font(LispPadUI.toolbarFont)
        Image(systemName: "textformat.size")
          .font(LispPadUI.toolbarIconFont)
          .accessibilityLabel("Zoom \(self.percent(self.controller.zoom))")
      }
    }
    .popover(isPresented: self.$zoomListShown) {
      VStack(spacing: 0) {
        ForEach(self.zoomChoices, id: \.self) { zoom in
          Button {
            self.controller.zoom = zoom
            self.zoomListShown = false
          } label: {
            HStack(spacing: 6) {
              Text(self.percent(zoom))
              Spacer(minLength: 0)
              if abs(self.controller.zoom - zoom) < 0.01 {
                Image(systemName: "checkmark")
              }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
          }
          .buttonStyle(.plain)
        }
      }
      .frame(width: DocumentationDetailView.zoomListWidth)
      .padding(.vertical, 6)
      .presentationCompactAdaptation(.popover)
    }
  }

  var body: some View {
    ZStack {
      if let block {
        if toggle {
          ScrollView(.vertical) {
            MarkdownText(block)
              .padding(16)
          }
        } else {
          ScrollView(.vertical) {
            MarkdownText(block)
              .padding(16)
          }
        }
      } else if toggle, let url {
        ZStack {
          WebView(controller: self.controller, resource: .file(url, nil), action: {
            notification in
          })
          if self.controller.isLoading {
            ProgressView()
              .progressViewStyle(CircularProgressViewStyle())
          }
        }
        .ignoresSafeArea()
      } else if let url {
        ZStack {
          WebView(controller: self.controller, resource: .file(url, nil), action: {
            notification in
          })
          if self.controller.isLoading {
            ProgressView()
              .progressViewStyle(CircularProgressViewStyle())
          }
        }
        .ignoresSafeArea()
      } else {
        HStack {
          Spacer()
          Image(systemName: "network.slash")
            .resizable()
            .scaledToFit()
            .frame(width: 42, height: 42)
            .foregroundStyle(Color.gray)
            .padding(3)
          Text("Documentation not available.")
            .font(.headline)
            .foregroundStyle(Color.gray)
            .padding(3)
          Spacer()
        }
        .padding(6)
      }
    }
    .toolbar {
      if self.titleMaxWidth >= DocumentationDetailView.minTitleWidth {
        ToolbarItem(placement: .principal) {
          Text(self.title)
            .font(LispPadUI.toolbarTitleFont(for: self.title))
            .bold()
            .foregroundColor(.primary)
            .truncationMode(.middle)
            .multilineTextAlignment(.center)
            .allowsTightening(true)
            .lineLimit(2)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: self.titleMaxWidth)
        }
      }
      if self.url != nil {
        ToolbarItemGroup(placement: .topBarLeading) {
          HStack(alignment: .center, spacing: 8) {
            Button(action: {
              self.controller.goBack = true
            }) {
              Image(systemName: "chevron.left")
                .font(LispPadUI.toolbarIconFont)
            }
            .disabled(!self.controller.canGoBack)
            Button(action: {
              self.controller.goForward = true
            }) {
              Image(systemName: "chevron.right")
                .font(LispPadUI.toolbarIconFont)
            }
            .disabled(!self.controller.canGoForward)
          }
          .padding(.horizontal, 6)
        }
      }
      if self.isStandalone {
        ToolbarItemGroup(placement: .topBarTrailing) {
          // A single item takes up less space than two separate ones. If the navigation bar runs
          // out of space, it moves all of its items into an overflow menu, which is hard to use.
          HStack(alignment: .center, spacing: 6) {
            if self.url != nil {
              self.zoomMenu
            }
            Button {
              withAnimation {
                self.docShown = false
              }
            } label: {
              Image(systemName: "xmark")
                .font(LispPadUI.toolbarIconFont)
            }
          }
        }
      } else if self.url != nil {
        ToolbarItemGroup(placement: .topBarTrailing) {
          self.zoomMenu
        }
      }
    }
    .onChange(of: self.selectedLib) {
      if let selectedLib {
        switch self.docManager.libraryDocumentation(for: selectedLib.components) {
          case .markdown(let block):
            self.toggle.toggle()
            self.block = block
            self.url = nil
          case .htmlFile(let url):
            if url != self.url {
              self.toggle.toggle()
            }
            self.block = nil
            self.url = url
          default:
            self.block = nil
            self.url = nil
        }
      } else {
        self.block = nil
        self.url = nil
      }
      self.selectedIdent = nil
    }
    .onChange(of: self.selectedIdent) {
      if let selectedIdent {
        if !selectedIdent.isEmpty {
          self.toggle.toggle()
          self.block = self.docManager.documentation(for: selectedIdent)
          self.url = nil
        } else if let selectedLib {
          switch self.docManager.libraryDocumentation(for: selectedLib.components) {
            case .markdown(let block):
              self.toggle.toggle()
              self.block = block
              self.url = nil
            case .htmlFile(let url):
              if url != self.url {
                self.toggle.toggle()
              }
              self.block = nil
              self.url = url
            default:
              self.block = nil
              self.url = nil
          }
        } else {
          self.block = nil
          self.url = nil
        }
      }
    }
    .onAppear {
      if let selectedIdent, !selectedIdent.isEmpty {
        self.block = self.docManager.documentation(for: selectedIdent)
        self.url = nil
      } else if let selectedLib {
        switch self.docManager.libraryDocumentation(for: selectedLib.components) {
          case .markdown(let block):
            self.block = block
            self.url = nil
          case .htmlFile(let url):
            if url != self.url {
              self.toggle.toggle()
            }
            self.block = nil
            self.url = url
          default:
            self.block = nil
            self.url = nil
        }
      } else {
        self.block = nil
        self.url = nil
      }
    }
  }
}
