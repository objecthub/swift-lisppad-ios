//
//  LibraryView.swift
//  LispPad
//
//  Created by Matthias Zenger on 19/03/2021.
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

struct LibraryView: View {
  @EnvironmentObject var interpreter: Interpreter
  @EnvironmentObject var docManager: DocumentationManager
  @ObservedObject var libManager: LibraryManager
  @State var tapped: LibraryManager.LibraryProxy? = nil
  @State var searchText: String = ""
  @State var showAllLibraries: Bool = true
  
  var body: some View {
    List {
      ForEach(self.libManager.libraries.filter { proxy in 
        (self.showAllLibraries || proxy.isLoaded) &&
        (self.searchText.isEmpty ||
         proxy.name.range(of: self.searchText, options: .caseInsensitive) != nil)
      }, id: \.name) { proxy in
        NavigationLink(
          destination: LazyView(LibraryDetailView(libProxy: proxy)),
          tag: proxy,
          selection: self.$tapped) {
          HStack(spacing: 12) {
            Text(proxy.name)
              .font(.body)
              .foregroundColor(.primary)
            Spacer()
            Text(proxy.state)
              .font(.caption)
              .foregroundColor(.secondary)
          }
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
          Button(action: { self.interpreter.import(proxy.components) }) {
            Image(systemName: "square.and.arrow.down")
          }
        }
        .disabled(self.docManager.libraryDocumentation(for: proxy.components) == nil)
      }
    }
    .listStyle(.plain)
    .searchable(text: $searchText)
    .resignKeyboardOnDragGesture()
    .navigationBarTitleDisplayMode(.inline)
    .navigationTitle(self.showAllLibraries ? "Libraries" : "Loaded Libraries")
    .navigationBarBackButtonHidden(false)
    .toolbar {
      ToolbarItemGroup(placement: .navigationBarTrailing) {
        HStack(alignment: .center, spacing: LispPadUI.toolbarSeparator) {
          Button(action: {
            self.libManager.updateLibraries()
          }) {
            Image(systemName: "arrow.clockwise")
              .font(LispPadUI.toolbarFont)
          }
          Menu {
            Button(action: {
              self.showAllLibraries = true
            }) {
              Label("All", systemImage: self.showAllLibraries ? "checkmark" : "")
            }
            Button(action: {
              self.showAllLibraries = false
            }) {
              Label("Loaded", systemImage: self.showAllLibraries ? "" : "checkmark")
            }
          } label: {
            Image(systemName: "slider.horizontal.3")
              .font(LispPadUI.toolbarFont)
          }
        }
      }
    }
  }
}
