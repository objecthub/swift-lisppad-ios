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
  @State var searchText: String = ""
  @State var showLoadedLibraries: Bool = false
  
  var body: some View {
      List(self.libManager.libraries.filter { proxy in 
             (!self.showLoadedLibraries || proxy.isLoaded) &&
             (self.searchText.isEmpty ||
                proxy.name.range(of: self.searchText, options: .caseInsensitive) != nil)
           },
           id: \.name) { proxy in
        NavigationLink(value: proxy) {
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
        .disabled(self.docManager.libraryDocumentation(for: proxy.components) == nil)
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
          Button(action: { self.interpreter.import(proxy.components) }) {
            Image(systemName: "square.and.arrow.down")
          }.tint(.blue)
        }
      }
     .refreshable {
       self.libManager.updateLibraries()
     }
     .listStyle(.plain)
     .searchable(text: $searchText)
     .navigationBarTitleDisplayMode(.inline)
     .navigationTitle(self.showLoadedLibraries ? "Loaded Libraries" : "Libraries")
     .navigationBarBackButtonHidden(false)
     .toolbar {
       ToolbarItemGroup(placement: .navigationBarTrailing) {
         HStack(alignment: .center, spacing: LispPadUI.toolbarSeparator) {
           Menu {
             Toggle(isOn: self.$showLoadedLibraries) {
               Label("Only Loaded", systemImage: "memorychip")
             }
           } label: {
             Image(systemName: "slider.horizontal.3")
               .font(LispPadUI.toolbarFont)
           }
         }
       }
     }
    .navigationDestination(for: LibraryManager.LibraryProxy.self) { proxy in
      LibraryDetailView(libProxy: proxy)
    }
  }
}
