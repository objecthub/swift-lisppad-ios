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

  @State var showNext: Bool = false
  @State var lastSearchText: String = ""
  @State var lastReplaceText: String = ""
  @State var appearing: Bool = true
  @Binding var searchText: String
  @Binding var replaceText: String
  @Binding var showSearchField: Bool
  @Binding var replaceMode: Bool
  @Binding var caseSensitive: Bool
  let search: (String, Direction) -> Bool
  let replace: (String, String, ((Bool) -> Void)?) -> Void
  let replaceAll: (String, String) -> Void

  /// The shared height of every Liquid Glass surface in this view (the search/replace
  /// text fields as well as the icon button pairs), so they all line up like segments
  /// of one continuous control, the way Liquid Glass toolbars do.
  private let controlHeight: CGFloat = 36

  /// A glyph sized to sit inside a shared Liquid Glass capsule (see `glassGroup`) on
  /// iOS 26+, falling back to a plain, unsized glyph on older versions. `legacyName`
  /// lets the pre-26 fallback use a different (usually more self-contained) symbol
  /// than the one used inside a Liquid Glass capsule; it defaults to `systemName`.
  /// Any gesture gets attached by the caller on top of the returned view.
  @ViewBuilder
  private func pairIcon(_ systemName: String,
                         legacyName: String? = nil,
                         width: CGFloat = 30) -> some View {
    if #available(iOS 26.0, *) {
      Image(systemName: systemName)
        .font(.system(size: 14, weight: .semibold))
        .frame(width: width, height: self.controlHeight)
    } else {
      Image(systemName: legacyName ?? systemName)
    }
  }

  /// Combines a group of related icon buttons into a single Liquid Glass capsule on
  /// iOS 26+, so they read as one grouped control instead of separate glass shapes.
  /// Falls back to the plain, individually padded buttons on older versions.
  @ViewBuilder
  private func glassGroup<Content: View>(@ViewBuilder content: () -> Content) -> some View {
    if #available(iOS 26.0, *) {
      HStack(spacing: 0) {
        content()
      }
      .glassEffect(.regular.interactive(), in: Capsule())
      .padding(.leading, 8)
    } else {
      HStack(spacing: 0) {
        content()
      }
      .padding(.leading, 8)
    }
  }

  /// Wraps the content of a search/replace text field row with a Liquid Glass
  /// capsule on iOS 26+, falling back to the former flat, filled rounded rectangle.
  @ViewBuilder
  private func glassCapsule<Content: View>(@ViewBuilder content: () -> Content) -> some View {
    if #available(iOS 26.0, *) {
      content()
        .padding(.horizontal, 6)
        .frame(height: self.controlHeight)
        .foregroundColor(.secondary)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    } else {
      content()
        .padding(EdgeInsets(top: 6, leading: 6, bottom: 6, trailing: 6))
        .foregroundColor(.secondary)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
  }

  private var searchIcon: some View {
    Group {
      if self.appearing { // This is a huge hack; without this, the transition won't work
        Image(systemName: "magnifyingglass")
          .foregroundColor(.accentColor)
          .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
              self.appearing = false
            }
          }
      } else {
        Menu {
          Toggle(isOn: Binding(get: { self.replaceMode },
                               set: { v in withAnimation {
                                        self.replaceMode.toggle()
                                        self.showNext = false
                                        self.lastSearchText = ""
                                        self.lastReplaceText = ""
                                      }
                                    })) {
            Label("Replace", systemImage: "repeat")
          }
          Toggle(isOn: self.$caseSensitive) {
            Label("Case Sensitive", systemImage: "textformat")
          }
          if !self.histManager.searchHistory.isEmpty {
            Section("SEARCH HISTORY") {
              ForEach(self.histManager.searchHistory, id: \.self) { entry in
                Button {
                  withAnimation {
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
                } label: {
                  Label(title: { Text(entry.description) },
                        icon: { Image(systemName: entry.searchOnly ? "magnifyingglass"
                                      : "repeat") })
                }
              }
            }
          }
        } label: {
          Image(systemName: "magnifyingglass")
            .foregroundColor(.accentColor)
        }
      }
    }
  }

  private var searchCapsule: some View {
    self.glassCapsule {
      HStack {
        self.searchIcon
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
        .keyboardType(.default)
        .disableAutocorrection(true)
        .autocapitalization(.none)
        .foregroundColor(.primary)
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
    }
  }

  private var searchBackwardButton: some View {
    Button(action: {
      if !self.searchText.isEmpty {
        let term = self.searchText
        let repl = self.replaceText
        self.histManager.rememberSearch(
          SearchHistoryEntry(searchText: term,
                             replaceText: self.replaceMode ? repl : nil))
        let more = self.search(term, .backward)
        withAnimation(.default) {
          self.lastSearchText = term
          self.lastReplaceText = repl
          self.showNext = more
        }
      }
    }, label: {
      self.pairIcon("chevron.backward")
    })
    .padding(.horizontal, 4)
    .keyCommand("g", modifiers: [.command, .shift], title: "Find previous")
    .disabled(self.searchText.isEmpty)
  }

  private var searchForwardButton: some View {
    Button(action: {
      if !self.searchText.isEmpty {
        let term = self.searchText
        let repl = self.replaceText
        self.histManager.rememberSearch(
          SearchHistoryEntry(searchText: term,
                             replaceText: self.replaceMode ? repl : nil))
        let more = self.search(self.searchText, .forward)
        withAnimation(.default) {
          self.lastSearchText = term
          self.lastReplaceText = repl
          self.showNext = more
        }
      }
    }, label: {
      self.pairIcon("chevron.forward")
    })
    .padding(.horizontal, 4)
    .keyCommand("g", modifiers: .command, title: "Find next")
    .disabled(self.searchText.isEmpty)
  }

  private var searchNavButtons: some View {
    self.glassGroup {
      self.searchBackwardButton
      self.searchForwardButton
    }
  }

  private var replaceCapsule: some View {
    self.glassCapsule {
      HStack {
        Image(systemName: "pencil")
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
        .disableAutocorrection(true)
        .autocapitalization(.none)
        .foregroundColor(.primary)
        Button(action: {
          withAnimation(.default) {
            self.replaceText = ""
            self.showNext = false
          }
        }) {
          Image(systemName: "xmark.circle.fill")
            .opacity(self.replaceText == "" ? 0 : 1)
        }
      }
    }
  }

  private var replaceOnceButton: some View {
    Button(action: {
      _ = self.replace(self.searchText, self.replaceText, nil)
      withAnimation(.default) {
        self.lastSearchText = ""
        self.lastReplaceText = ""
        self.showNext = false
      }
    }, label: {
      self.pairIcon("repeat.1")
    })
    .padding(.horizontal, 4)
    .disabled(self.searchText.isEmpty ||
                self.searchText != self.lastSearchText ||
                self.replaceText != self.lastReplaceText)
  }

  private var replaceNextButton: some View {
    Button(action: { }) {
      self.pairIcon("repeat")
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
    .padding(.horizontal, 4)
    .disabled(!showNext ||
                self.searchText.isEmpty ||
                self.searchText != self.lastSearchText ||
                self.replaceText != self.lastReplaceText)
  }

  private var replaceAllButton: some View {
    Button(action: {
      self.replaceAll(self.searchText, self.replaceText)
      withAnimation(.default) {
        self.lastSearchText = ""
        self.lastReplaceText = ""
        self.showNext = false
      }
    }, label: {
      self.pairIcon("repeat.badge.xmark", legacyName: "repeat.circle")
    })
    .padding(.horizontal, 4)
    .disabled(self.searchText.isEmpty)
  }

  private var replaceButtons: some View {
    self.glassGroup {
      self.replaceOnceButton
      self.replaceNextButton
      self.replaceAllButton
    }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 0.0) {
      HStack {
        self.searchCapsule
        self.searchNavButtons
        Spacer(minLength: 8)
        Button("Cancel") {
          UIApplication.shared.endEditing(true)
          withAnimation(.default) {
            self.showSearchField = false
            self.showNext = false
          }
        }
        .padding(.leading, 4)
        .padding(.trailing, 0)
      }
      .padding(EdgeInsets(top: 8, leading: 8,
                          bottom: self.replaceMode ? 6 : 8, trailing: 8))
      // .animation(.default)
      if self.replaceMode {
        HStack {
          self.replaceCapsule
          Button(action: {
            self.replace(self.searchText, self.replaceText) { more in
              DispatchQueue.main.async {
                withAnimation(.default) {
                  self.showNext = more
                }
              }
            }
          }) {
            EmptyView()
          }
          .keyCommand("y", modifiers: .command, title: "Replace and find next")
          .disabled(!showNext ||
                      self.searchText.isEmpty ||
                      self.searchText != self.lastSearchText ||
                      self.replaceText != self.lastReplaceText)
          Button(action: {
            self.replaceAll(self.searchText, self.replaceText)
            withAnimation(.default) {
              self.lastSearchText = ""
              self.lastReplaceText = ""
              self.showNext = false
            }
          }) {
            EmptyView()
          }
          .keyCommand("y", modifiers: [.command, .shift], title: "Replace all")
          .disabled(self.searchText.isEmpty)
          self.replaceButtons
        }
        .padding(EdgeInsets(top: 0, leading: 8, bottom: 8, trailing: 8))
        // .animation(.default)
      }
    }
    .onDisappear {
      self.histManager.saveSearchHistory()
    }
  }
}
