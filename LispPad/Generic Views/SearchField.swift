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

  /// The height of the combined search/replace text field rows.
  private let controlHeight: CGFloat = 36

  /// The height of each icon button row (search nav pair, replace action group) when
  /// both are stacked on top of each other, 4pt shorter than `controlHeight` so that,
  /// together with the 8pt gap between them, their combined height still lines up with
  /// `combinedFieldBox`. Only used while the replace field is visible; with a single
  /// button row, it uses the full `controlHeight` instead, matching the single field row.
  private let buttonGroupHeight: CGFloat = 32

  /// The height of an icon button row for the current mode: `buttonGroupHeight` once
  /// the two button groups are stacked (replace mode), `controlHeight` otherwise.
  private var buttonRowHeight: CGFloat {
    self.replaceMode ? self.buttonGroupHeight : self.controlHeight
  }

  /// The default width of an icon inside a button group, and the horizontal padding
  /// applied on each side of a button within a group. Used both to lay out the icons
  /// themselves and to work out how wide a differently-sized group's icons need to be
  /// to match another group's total width (see `searchNavIconWidth`).
  private static let iconWidth: CGFloat = 30
  private static let iconPadding: CGFloat = 4

  /// The width to use for each of the two search navigation icons. Once the replace
  /// action group (three icons) is visible, the search navigation pair (two icons)
  /// is widened so both glass pills span the same total width, matching Liquid
  /// Glass's habit of aligning grouped controls; otherwise it's the default width.
  private var searchNavIconWidth: CGFloat {
    guard self.replaceMode else { return Self.iconWidth }
    let replaceGroupWidth = 3 * (Self.iconWidth + 2 * Self.iconPadding)
    return replaceGroupWidth / 2 - 2 * Self.iconPadding
  }

  /// A glyph sized to sit inside a shared Liquid Glass capsule (see `glassGroup`) on
  /// iOS 26+, falling back to a plain, unsized glyph on older versions. `legacyName`
  /// lets the pre-26 fallback use a different (usually more self-contained) symbol
  /// than the one used inside a Liquid Glass capsule; it defaults to `systemName`.
  /// Any gesture gets attached by the caller on top of the returned view.
  @ViewBuilder
  private func pairIcon(_ systemName: String,
                         legacyName: String? = nil,
                         width: CGFloat = Self.iconWidth) -> some View {
    if #available(iOS 26.0, *) {
      Image(systemName: systemName)
        .font(.system(size: 14, weight: .semibold))
        .frame(width: width, height: self.buttonRowHeight)
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

  private var searchFieldRow: some View {
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
    .frame(height: self.controlHeight)
  }

  private var replaceFieldRow: some View {
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
    .frame(height: self.controlHeight)
  }

  /// Combines the search field, and (once replace mode is active) the replace field
  /// right below it, into a single box of matching width with a thin divider between
  /// the two rows — a Liquid Glass capsule on iOS 26+, falling back to the former
  /// flat, filled rounded rectangle.
  private var combinedFieldBox: some View {
    let rows = VStack(alignment: .leading, spacing: 0) {
      self.searchFieldRow
      if self.replaceMode {
        Divider()
        self.replaceFieldRow
      }
    }
    .padding(.horizontal, 6)
    .foregroundColor(.secondary)
    return Group {
      if #available(iOS 26.0, *) {
        rows.glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
      } else {
        rows
          .background(Color(.secondarySystemBackground))
          .cornerRadius(12)
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
      self.pairIcon("chevron.backward", width: self.searchNavIconWidth)
    })
    .padding(.horizontal, Self.iconPadding)
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
      self.pairIcon("chevron.forward", width: self.searchNavIconWidth)
    })
    .padding(.horizontal, Self.iconPadding)
    .keyCommand("g", modifiers: .command, title: "Find next")
    .disabled(self.searchText.isEmpty)
  }

  private var searchNavButtons: some View {
    self.glassGroup {
      self.searchBackwardButton
      self.searchForwardButton
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
    .padding(.horizontal, Self.iconPadding)
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
    .padding(.horizontal, Self.iconPadding)
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
    .padding(.horizontal, Self.iconPadding)
    .disabled(self.searchText.isEmpty)
  }

  private var replaceButtons: some View {
    self.glassGroup {
      self.replaceOnceButton
      self.replaceNextButton
      self.replaceAllButton
    }
  }

  /// The controls to the right of `combinedFieldBox`: the search navigation pair
  /// pinned to the top, and (once replace mode is active) the replace action group
  /// pinned to the bottom, 8pt apart. The exit button sits alongside both, vertically
  /// centered across their combined height.
  private var trailingControls: some View {
    HStack(alignment: .center, spacing: 0) {
      VStack(alignment: .leading, spacing: 8) {
        self.searchNavButtons
          .frame(height: self.buttonRowHeight)
        if self.replaceMode {
          HStack(spacing: 0) {
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
          .frame(height: self.buttonGroupHeight)
        }
      }
      Button {
        UIApplication.shared.endEditing(true)
        withAnimation(.default) {
          self.showSearchField = false
          self.showNext = false
        }
      } label: {
        ExitButton()
      }
      .padding(.leading, 12)
    }
  }

  var body: some View {
    HStack(alignment: .top, spacing: 0) {
      self.combinedFieldBox
      self.trailingControls
    }
    .padding(8)
    .onDisappear {
      self.histManager.saveSearchHistory()
    }
  }
}
