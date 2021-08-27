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
  
  enum Direction: Equatable {
    case first
    case forward
    case backward
  }
  
  @EnvironmentObject var histManager: HistoryManager
  
  @State var replaceMode: Bool = false
  @State var showNext: Bool = false
  @State var searchText: String = ""
  @State var lastSearchText: String = ""
  @State var replaceText: String = ""
  @State var lastReplaceText: String = ""
  @Binding var showSearchField: Bool
  let search: (String, Direction) -> Bool
  let replace: (String, String, ((Bool) -> Void)?) -> Void
  let replaceAll: (String, String) -> Void
  
  var body: some View {
    VStack(alignment: .leading, spacing: 0.0) {
      HStack {
        HStack {
          Menu {
            Button(action: {
              withAnimation(.default) {
                self.replaceMode = !self.replaceMode
                self.showNext = false
                self.lastSearchText = ""
                self.lastReplaceText = ""
              }
            }) {
              Label(self.replaceMode ? "Search" : "Search/Replace",
                    systemImage: self.replaceMode ? "magnifyingglass" : "arrow.triangle.swap")
            }
            if !self.histManager.searchHistory.isEmpty {
              Divider()
            }
            ForEach(self.histManager.searchHistory, id: \.self) { entry in
              Button(action: {
                withAnimation(.default) {
                  self.searchText = entry.searchText
                  if let replaceText = entry.replaceText {
                    self.replaceText = replaceText
                    self.replaceMode = true
                  } else {
                    self.replaceMode = false
                  }
                  self.showNext = false
                  self.lastSearchText = ""
                  self.lastReplaceText = ""
                }
              }) {
                Label(title: { Text(entry.description) },
                      icon: { Image(systemName: entry.searchOnly ?  "magnifyingglass"
                                                                 : "arrow.triangle.swap") })
              }
            }
          } label: {
            Image(systemName: "magnifyingglass").font(.callout)
          }
          TextField("Search", text: $searchText, onEditingChanged: { isEditing in
            self.showSearchField = true
          }, onCommit: {
            if !self.searchText.isEmpty {
              let term = self.searchText
              let repl = self.replaceText
              self.histManager.rememberSearch(
                SearchHistoryEntry(searchText: term,
                                   replaceText: self.replaceMode ? repl : nil))
              let more = self.search(term, .first)
              withAnimation(.default) {
                self.lastSearchText = term
                self.lastReplaceText = repl
                self.showNext = more
              }
            }
          })
          .font(.callout)
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
              .font(.callout)
              .opacity(self.searchText == "" ? 0 : 1)
          }
        }
        .padding(EdgeInsets(top: 6, leading: 6, bottom: 6, trailing: 6))
        .foregroundColor(.secondary)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        Button(action: {
          if !self.searchText.isEmpty {
            self.lastSearchText = self.searchText
            self.lastReplaceText = self.replaceText
            _ = self.search(self.searchText, .backward)
          }
        }, label: {
          Image(systemName: "chevron.backward")
        })
        .padding(.leading, 12)
        .padding(.trailing, 4)
        .keyCommand("g", modifiers: [.command, .shift], title: "Find previous")
        .disabled(self.searchText.isEmpty)
        Button(action: {
          if !self.searchText.isEmpty {
            let term = self.searchText
            let repl = self.replaceText
            let more = self.search(self.searchText, .forward)
            self.lastSearchText = term
            self.lastReplaceText = repl
            self.showNext = more
          }
        }, label: {
          Image(systemName: "chevron.forward")
        })
        .padding(.horizontal, 4)
        .keyCommand("g", modifiers: .command, title: "Find next")
        .disabled(self.searchText.isEmpty)
        Button("Cancel") {
          UIApplication.shared.endEditing(true)
          withAnimation(.default) {
            self.showSearchField = false
            self.showNext = false
          }
        }
        .padding(.leading, 4)
        .padding(.trailing, 0)
        .font(.callout)
        .foregroundColor(Color(.systemBlue))
      }
      .padding(EdgeInsets(top: 8, leading: 8,
                          bottom: self.replaceMode ? 6 : 8, trailing: 8))
      .animation(.default)
      if self.replaceMode {
        HStack {
          HStack {
            Image(systemName: "pencil").font(.callout)
            TextField("Replace", text: $replaceText, onEditingChanged: { isEditing in
              self.showSearchField = true
            }, onCommit: {
              if !self.searchText.isEmpty {
                let term = self.searchText
                let repl = self.replaceText
                self.histManager.rememberSearch(
                  SearchHistoryEntry(searchText: term,
                                     replaceText: self.replaceMode ? repl : nil))
                let more = self.search(term, .first)
                withAnimation(.default) {
                  self.lastSearchText = term
                  self.lastReplaceText = repl
                  self.showNext = more
                }
              }
            })
            .font(.callout)
            .foregroundColor(.primary)
            .autocapitalization(.none)
            .disableAutocorrection(true)
            Button(action: {
              withAnimation(.default) {
                self.replaceText = ""
                self.showNext = false
              }
            }) {
              Image(systemName: "xmark.circle.fill")
                .font(.callout)
                .opacity(self.replaceText == "" ? 0 : 1)
            }
          }
          .padding(EdgeInsets(top: 6, leading: 6, bottom: 6, trailing: 6))
          .foregroundColor(.secondary)
          .background(Color(.secondarySystemBackground))
          .cornerRadius(12)
          Button(action: { }) {
            Image(systemName: "repeat")
            .padding(.leading, 12)
            .padding(.trailing, 4)
            .onTapGesture {
              self.replace(self.searchText, self.replaceText) { more in
                DispatchQueue.main.async {
                  withAnimation(.default) {
                    self.showNext = more
                  }
                }
              }
            }
            .onLongPressGesture(minimumDuration: 1.0) {
              self.replaceAll(self.searchText, self.replaceText)
              withAnimation(.default) {
                self.lastSearchText = ""
                self.lastReplaceText = ""
                self.showNext = false
              }
            }
          }
          .disabled(!showNext ||
                      self.searchText.isEmpty ||
                      self.searchText != self.lastSearchText ||
                      self.replaceText != self.lastReplaceText)
          Button(action: {
            _ = self.replace(self.searchText, self.replaceText, nil)
            withAnimation(.default) {
              self.lastSearchText = ""
              self.lastReplaceText = ""
              self.showNext = false
            }
          }, label: {
            Image(systemName: "repeat.1")
          })
          .padding(.horizontal, 4)
          .disabled(self.searchText.isEmpty ||
                      self.searchText != self.lastSearchText ||
                      self.replaceText != self.lastReplaceText)
        }
        .padding(EdgeInsets(top: 0, leading: 8, bottom: 8, trailing: 8))
        .animation(.default)
      }
    }
    .onDisappear {
      self.histManager.saveSearchHistory()
    }
  }
}
