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
  @State var swiped: LibraryManager.LibraryProxy? = nil
  @State var swipeOffset: CGFloat = 0.0
  @State var searchText: String = ""
  @State var showCancel: Bool = false
  @State var showAllLibraries: Bool = true
  
  var body: some View {
    VStack {
      HStack {
        HStack {
            Image(systemName: "magnifyingglass")
            TextField("Search", text: $searchText, onEditingChanged: { isEditing in
              self.showCancel = true
            }, onCommit: {
            })
            .foregroundColor(.primary)
            .autocapitalization(.none)
            .disableAutocorrection(true)
            Button(action: {
              self.searchText = ""
            }) {
              Image(systemName: "xmark.circle.fill")
              .opacity(searchText == "" ? 0 : 1)
            }
        }
        .padding(EdgeInsets(top: 6, leading: 6, bottom: 6, trailing: 6))
        .foregroundColor(.secondary)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        if showCancel  {
          Button("Cancel") {
            UIApplication.shared.endEditing(true)
            self.searchText = ""
            self.showCancel = false
          }
          .foregroundColor(Color(.systemBlue))
        }
      }
      .font(.body)
      .padding(.horizontal)
      .padding(.top, self.showCancel ? 0 : 8)
      .navigationBarHidden(showCancel)
      // .animation(.default)
      Divider()
      ScrollView(.vertical) {
        LazyVStack(alignment: .leading, spacing: 0) {
          ForEach(self.libManager.libraries.filter { proxy in 
            (self.showAllLibraries || proxy.isLoaded) &&
            (self.searchText.isEmpty || proxy.name.contains(self.searchText))
          }, id: \.name) { proxy in
            ZStack {
              HStack {
                Color.blue.frame(width: 70).opacity(swiped == proxy ? 1 : 0)
                Spacer()
              }
              HStack {
                Button(action: {
                  self.interpreter.import(proxy.components)
                  withAnimation(.default) {
                    self.tapped = nil
                    self.swiped = nil
                    self.swipeOffset = 0
                  }
                }) {
                  Image(systemName: "square.and.arrow.down")
                    .font(.headline)
                    .foregroundColor(.white)
                }
                .frame(width: 70)
                Spacer()
              }
              .disabled(!self.interpreter.isReady)
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
                  Image(systemName: "chevron.right")
                    .font(Font.system(size: 14, weight: .semibold))
                    .foregroundColor(
                      Color(self.docManager.libraryDocumentation(for: proxy.components) == nil ?
                              .systemBackground :
                              .tertiaryLabel))
                }
                .padding(EdgeInsets(top: 13, leading: 16, bottom: 13, trailing: 8))
                .background(Color(.systemBackground))
                .contentShape(Rectangle())
              }
              .disabled(true)
              .onTapGesture(count: 1) {
                if self.docManager.libraryDocumentation(for: proxy.components) != nil {
                  self.tapped = proxy
                  withAnimation(.default) {
                    self.swipeOffset = 0
                    self.swiped = nil
                  }
                }
              }
              .offset(x: self.swiped == proxy ? self.swipeOffset : 0)
              .gesture(
                DragGesture().onChanged { value in
                  withAnimation(.default) {
                    if value.translation.width > 60 {
                      self.swipeOffset = value.translation.width > 180 ? 180 : value.translation.width
                      self.swiped = proxy
                    } else if value.translation.width < 0 {
                      self.swipeOffset = 0
                      self.swiped = nil
                    } else {
                      self.swipeOffset = value.translation.width
                    }
                  }
                }
                .onEnded { value in
                  withAnimation(.default) {
                    if value.translation.width > 60 {
                      self.swiped = proxy
                      self.swipeOffset = 70
                    } else {
                      self.swiped = nil
                      self.swipeOffset = 0
                    }
                  }
                }
              )
            }
            Divider()
              .padding(.leading, 16)
          }
        }
      }
      .offset(y: -8) // Not sure why this is needed
      .edgesIgnoringSafeArea(.all)
    }
    .navigationTitle(self.showAllLibraries ? "Libraries" : "Loaded Libraries")
    .toolbar {
      ToolbarItemGroup(placement: .navigationBarTrailing) {
        HStack(alignment: .center, spacing: 16) {
          Button(action: {
            self.libManager.updateLibraries()
          }) {
            Image(systemName: "arrow.clockwise")
              .font(InterpreterView.toolbarFont)
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
              .font(InterpreterView.toolbarFont)
          }
        }
      }
    }
  }
}
