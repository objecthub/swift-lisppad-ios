//
//  SearchField.swift
//  LispPad
//
//  Created by Matthias Zenger on 05/04/2021.
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

struct SearchField: View {
  @State var showNext: Bool = false
  @State var searchText: String = ""
  @State var lastSearchText: String = ""
  @Binding var showSearchField: Bool
  @Binding var forceEditorUpdate: Bool
  @Binding var searchHistory: [String]
  let maxHistory: Int
  let search: (String, Bool) -> Bool
  
  func insert(term: String) {
    var i = 0
    while i < self.searchHistory.count && term != self.searchHistory[i] {
      i += 1
    }
    if i < self.searchHistory.count {
      self.searchHistory.remove(at: i)
    }
    self.searchHistory.insert(term, at: 0)
    if self.searchHistory.count > self.maxHistory {
      self.searchHistory.removeLast()
    }
  }
  
  var body: some View {
    HStack {
      HStack {
        Menu {
          ForEach(self.searchHistory, id: \.self) { term in
            Button(action: {
              self.searchText = term
            }) {
              Text(term)
            }
          }
        } label: {
          Image(systemName: "magnifyingglass")
        }
        TextField("Search", text: $searchText, onEditingChanged: { isEditing in
          self.showSearchField = true
        }, onCommit: {
          if !self.searchText.isEmpty {
            let term = self.searchText
            self.insert(term: term)
            let more = self.search(term, true)
            withAnimation(.default) {
              self.lastSearchText = term
              self.showNext = more
            }
          }
        })
        .foregroundColor(.primary)
        .autocapitalization(.none)
        .disableAutocorrection(true)
        Button(action: {
          withAnimation(.default) {
            self.searchText = ""
            self.lastSearchText = ""
            self.showNext = false
          }
        }) {
          Image(systemName: "xmark.circle.fill")
            .opacity(self.searchText == "" ? 0 : 1)
        }
      }
      .padding(EdgeInsets(top: 6, leading: 6, bottom: 6, trailing: 6))
      .foregroundColor(.secondary)
      .background(Color(.secondarySystemBackground))
      .cornerRadius(12)
      if showNext && showSearchField && self.searchText == self.lastSearchText {
        Button("Next") {
          UIApplication.shared.endEditing(true)
          if !self.searchText.isEmpty {
            let more = self.search(self.searchText, false)
            withAnimation(.default) {
              self.showNext = more
            }
          }
        }
        .foregroundColor(Color(.systemBlue))
      }
      if showSearchField  {
        Button("Cancel") {
          UIApplication.shared.endEditing(true)
          withAnimation(.default) {
            self.searchText = ""
            self.showSearchField = false
            self.showNext = false
            self.forceEditorUpdate = true
          }
        }
        .foregroundColor(Color(.systemBlue))
      }
    }
    .padding(8)
    .animation(.default)
  }
}

struct SearchField_Previews: PreviewProvider {
  @State static var showCancel = true
  @State static var forceEditorUpdate = false
  @State static var history: [String] = ["One", "Two", "Three", "Four"]
  static var previews: some View {
    SearchField(showSearchField: $showCancel,
                forceEditorUpdate: $forceEditorUpdate,
                searchHistory: $history,
                maxHistory: 10) { str, initial in
       return true
    }
  }
}
