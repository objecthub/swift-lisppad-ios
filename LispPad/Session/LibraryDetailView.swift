//
//  LibraryDetailView.swift
//  LispPad
//
//  Created by Matthias Zenger on 21/03/2021.
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
import LispKit

struct LibraryDetailView: View {
  @EnvironmentObject var docManager: DocumentationManager
  @StateObject var controller = WebViewController()
  let libProxy: LibraryManager.LibraryProxy
  
  var body: some View {
    switch self.docManager.libraryDocumentation(for: self.libProxy.components) {
      case .markdown(let block):
        ScrollView(.vertical) {
          MarkdownText(block)
            .padding(12)
        }
        .navigationTitle(self.libProxy.name)
      case .htmlFile(let url):
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
        .navigationTitle(self.libProxy.name)
        .navigationBarBackButtonHidden(false)
        .toolbar {
          ToolbarItemGroup(placement: .navigationBarTrailing) {
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
      default:
        Text("Documentation not available.")
          .padding(12)
          .navigationTitle(self.libProxy.name)
    }
  }
}
