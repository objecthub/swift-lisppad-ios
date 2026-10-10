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
  
  /// Horizontal space taken up in the navigation bar by the back/forward buttons for web content.
  private static let webNavigationButtonsWidth: CGFloat = 80
  
  /// Horizontal space taken up in the navigation bar by the zoom menu for web content.
  private static let zoomMenuWidth: CGFloat = 60
  
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
            .lineLimit(2)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: self.titleMaxWidth)
        }
      }
      if self.url != nil {
        ToolbarItemGroup(placement: .topBarLeading) {
          HStack(alignment: .center, spacing: 10) {
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
          HStack(alignment: .center, spacing: 8) {
            if self.url != nil {
              Menu {
                Button("50%") {
                  self.controller.zoom = 0.5
                }
                Button("75%") {
                  self.controller.zoom = 0.75
                }
                Button("100%") {
                  self.controller.zoom = 1.0
                }
                Button("125%") {
                  self.controller.zoom = 1.25
                }
                Button("150%") {
                  self.controller.zoom = 1.5
                }
                Button("175%") {
                  self.controller.zoom = 1.75
                }
                Button("200%") {
                  self.controller.zoom = 2.0
                }
              } label: {
                Text("\(Int(self.controller.zoom * 100.0))%")
                  .font(LispPadUI.toolbarFont)
              }
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
          .padding(.trailing, 4)
        }
      } else if self.url != nil {
        ToolbarItemGroup(placement: .topBarTrailing) {
          Menu {
            Button("50%") {
              self.controller.zoom = 0.5
            }
            Button("75%") {
              self.controller.zoom = 0.75
            }
            Button("100%") {
              self.controller.zoom = 1.0
            }
            Button("125%") {
              self.controller.zoom = 1.25
            }
            Button("150%") {
              self.controller.zoom = 1.5
            }
            Button("175%") {
              self.controller.zoom = 1.75
            }
            Button("200%") {
              self.controller.zoom = 2.0
            }
          } label: {
            Text("\(Int(self.controller.zoom * 100.0))%")
              .font(LispPadUI.toolbarFont)
          }
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
