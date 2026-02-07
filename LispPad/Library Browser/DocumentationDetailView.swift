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
  @StateObject var controller = WebViewController()
  @State var block: Block? = nil
  @State var url: URL? = nil
  @State var toggle: Bool = true
  
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
      if self.url != nil {
        ToolbarItemGroup(placement: .topBarLeading) {
          HStack(alignment: .center, spacing: LispPadUI.toolbarSeparator) {
            Button(action: {
              self.controller.goBack = true
            }) {
              Image(systemName: "chevron.left")
                .font(LispPadUI.toolbarFont)
            }
            .disabled(!self.controller.canGoBack)
            Button(action: {
              self.controller.goForward = true
            }) {
              Image(systemName: "chevron.right")
                .font(LispPadUI.toolbarFont)
            }
            .disabled(!self.controller.canGoForward)
          }
        }
      }
      if self.sizeClass == .compact ||
          (self.columnVisibility != .doubleColumn &&
           self.columnVisibility != .all) {
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
