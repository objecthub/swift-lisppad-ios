//
//  EnvironmentView.swift
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

struct EnvironmentView: View {
  @EnvironmentObject var docManager: DocumentationManager
  @ObservedObject var envManager: EnvironmentManager
  @State var searchText: String = ""
  @State var showCancel: Bool = false
  @State var showLispPadRef: Bool = false
  
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
      .font(.callout)
      .padding(.horizontal)
      .padding(.top, self.showCancel ? 0 : 8)
      .navigationBarHidden(showCancel)
      // .animation(.default)
      Divider()
      List {
        ForEach(self.envManager.bindings.filter { symbol in
          self.searchText.isEmpty || symbol.identifier.contains(self.searchText)
        }, id: \.self) { symbol in
          NavigationLink(
            destination: LazyView(EnvironmentDetailView(symbol: symbol))) {
            Text(symbol.description)
              .font(.callout)
          }
          .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 8))
          .disabled(!self.docManager.hasDocumentation(for: symbol.identifier))
        }
      }
      .padding(.top, -8)
      .resignKeyboardOnDragGesture()
      .listStyle(DefaultListStyle())
      .navigationTitle("Environment")
      .navigationBarItems(
        trailing: HStack(alignment: .center, spacing: 16) {
          Button(action: { self.showLispPadRef = true }) {
            Image(systemName: "info.circle")
              .font(Font.system(size: InterpreterView.toolbarItemSize, weight: .light))
          }
          .sheet(isPresented: $showLispPadRef) {
            DocumentView(title: docManager.lispPadRef.name, url: docManager.lispPadRef.url)
          }
        })
    }
  }
}
