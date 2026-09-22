//
//  DocumentView.swift
//  LispPad
//
//  Created by Matthias Zenger on 10/04/2021.
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
import PDFKit

struct DocumentView: View {
  let title: String
  let url: URL
  @State private var document: PDFDocument?
  @State private var showSearch: Bool = false
  @State private var searchText: String = ""
  @FocusState private var searchFieldFocused: Bool
  @StateObject private var controller = PDFViewer.Controller()
  
  init(title: String, url: URL) {
    self.title = title
    self.url = url
    self._document = State(initialValue: PDFDocument(url: url))
  }
  
  var body: some View {
    Sheet(backgroundColor: Color(.secondarySystemBackground)) {
      GeometryReader { geometry in
        VStack {
          PDFViewer(document: self.document,
                    viewSize: geometry.size,
                    controller: self.controller,
                    showsPageLabel: !self.showSearch)
              .navigationTitle(self.title)
              .navigationBarHidden(false)
        }
      }
      .overlay(alignment: .topLeading) {
        HStack(spacing: 12) {
          if self.showSearch {
            self.searchBar
          } else {
            self.toolbarButtons
          }
        }
        .padding()
        // Leave room for the close button of the sheet
        .padding(.trailing, self.showSearch ? 48 : 0)
      }
    }
  }
  
  @ViewBuilder
  private var toolbarButtons: some View {
    Button {
      withAnimation {
        self.showSearch = true
      }
      self.searchFieldFocused = true
    } label: {
      SheetIconButton(systemName: "magnifyingglass",
                      legacyName: "magnifyingglass.circle.fill",
                      label: "Search",
                      hint: "Tap to search the document")
    }
    .buttonStyle(.plain)
    .keyboardShortcut("f", modifiers: .command)
    if let outline = self.document?.outlineRoot, outline.numberOfChildren > 0 {
      Menu {
        OutlineMenuContent(outline: outline, controller: self.controller)
      } label: {
        SheetIconButton(systemName: "list.bullet",
                        legacyName: "list.bullet.circle.fill",
                        label: "Outline",
                        hint: "Tap to show the outline of the document")
      }
      .menuIndicator(.hidden)
      .buttonStyle(.plain)
    }
    ShareLink(item: self.url, subject: Text(self.title)) {
      SheetIconButton(systemName: "square.and.arrow.up",
                      legacyName: "square.and.arrow.up.circle.fill",
                      label: "Share",
                      hint: "Tap to share the document")
    }
    .buttonStyle(.plain)
  }
  
  @ViewBuilder
  private var searchBar: some View {
    Button {
      self.closeSearch()
    } label: {
      SheetIconButton(systemName: "magnifyingglass",
                      legacyName: "magnifyingglass.circle.fill",
                      label: "Close Search",
                      hint: "Tap to close the search bar",
                      highlighted: true)
    }
    .buttonStyle(.plain)
    .keyboardShortcut("f", modifiers: .command)
    HStack(spacing: 6) {
      TextField("Search", text: self.$searchText)
        .focused(self.$searchFieldFocused)
        .submitLabel(.search)
        .autocorrectionDisabled(true)
        .textInputAutocapitalization(.never)
        .onSubmit {
          // Pressing return again for the same term moves on to the next match
          if self.searchText == self.controller.searchTerm {
            self.controller.nextMatch()
          } else {
            self.controller.search(self.searchText)
          }
          self.searchFieldFocused = true
        }
      self.searchStatus
      if !self.searchText.isEmpty {
        Button {
          self.searchText = ""
          self.controller.clearSearch()
          self.searchFieldFocused = true
        } label: {
          Image(systemName: "xmark.circle.fill")
            .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
        .accessibility(label: Text("Clear"))
      }
    }
    .padding(.horizontal, 12)
    .frame(height: 32)
    .frame(maxWidth: .infinity)
    .modifier(CapsuleBackground())
    HStack(spacing: 0) {
      Button {
        self.controller.previousMatch()
      } label: {
        Image(systemName: "chevron.up")
          .font(.system(size: 14, weight: .semibold))
          .frame(width: 32, height: 32)
          .contentShape(Rectangle())
      }
      .keyboardShortcut("g", modifiers: [.command, .shift])
      .accessibility(label: Text("Previous Match"))
      Button {
        self.controller.nextMatch()
      } label: {
        Image(systemName: "chevron.down")
          .font(.system(size: 14, weight: .semibold))
          .frame(width: 32, height: 32)
          .contentShape(Rectangle())
      }
      .keyboardShortcut("g", modifiers: .command)
      .accessibility(label: Text("Next Match"))
    }
    .buttonStyle(.plain)
    .foregroundStyle(self.controller.matches.isEmpty ? .tertiary : .secondary)
    .disabled(self.controller.matches.isEmpty)
    .padding(.horizontal, 4)
    .modifier(CapsuleBackground())
  }
  
  @ViewBuilder
  private var searchStatus: some View {
    let count = self.controller.matches.count
    if count > 0 {
      Text(self.controller.currentMatch.map { "\($0 + 1) of \(count)" } ?? "\(count) matches")
        .font(.caption.monospacedDigit())
        .foregroundStyle(.secondary)
        .fixedSize()
    }
    if self.controller.searching {
      ProgressView()
        .controlSize(.small)
    } else if count == 0 && self.controller.searchTerm != nil {
      Text("No matches")
        .font(.caption)
        .foregroundStyle(.secondary)
        .fixedSize()
    }
  }
  
  private func closeSearch() {
    self.searchFieldFocused = false
    self.controller.clearSearch()
    withAnimation {
      self.showSearch = false
    }
  }
}

/// Gives a control a capsule-shaped background: Liquid Glass on iOS 26+, a plain
/// material on older versions.
private struct CapsuleBackground: ViewModifier {
  func body(content: Content) -> some View {
    if #available(iOS 26.0, *) {
      content.glassEffect(.regular.interactive(), in: Capsule())
    } else {
      content.background(.regularMaterial, in: Capsule())
    }
  }
}

/// Recursively renders the children of a PDF outline node as menu entries. Nodes with
/// children become submenus whose first entry jumps to the node itself (if it has a target).
struct OutlineMenuContent: View {
  let outline: PDFOutline
  let controller: PDFViewer.Controller
  
  var body: some View {
    ForEach(0..<self.outline.numberOfChildren, id: \.self) { index in
      if let child = self.outline.child(at: index) {
        let label = OutlineMenuContent.label(of: child)
        if child.numberOfChildren > 0 {
          Menu(label) {
            if PDFViewer.Controller.destination(of: child) != nil {
              Button(label) {
                self.controller.go(to: child)
              }
              Divider()
            }
            OutlineMenuContent(outline: child, controller: self.controller)
          }
        } else {
          Button(label) {
            self.controller.go(to: child)
          }
        }
      }
    }
  }
  
  private static func label(of outline: PDFOutline) -> String {
    if let label = outline.label?.trimmingCharacters(in: .whitespacesAndNewlines),
       !label.isEmpty {
      return label
    }
    return "Untitled"
  }
}

struct SheetIconButton: View {
  let systemName: String
  let legacyName: String
  let label: String
  let hint: String
  let highlighted: Bool
  let size: CGFloat

  init(systemName: String,
       legacyName: String,
       label: String,
       hint: String,
       highlighted: Bool = false,
       size: CGFloat? = nil,
       legacySize: CGFloat? = nil) {
    self.systemName = systemName
    self.legacyName = legacyName
    self.label = label
    self.hint = hint
    self.highlighted = highlighted
    if #available(iOS 26.0, *) {
      self.size = size ?? 32.0
    } else {
      self.size = legacySize ?? size ?? 25.0
    }
  }

  var body: some View {
    if #available(iOS 26.0, *) {
      Image(systemName: self.systemName)
        .font(.system(size: self.size * 0.5, weight: .semibold))
        .foregroundStyle(self.highlighted ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
        .frame(width: self.size, height: self.size)
        .glassEffect(.regular.interactive(), in: Circle())
        .accessibility(label: Text(self.label))
        .accessibility(hint: Text(self.hint))
        .accessibility(removeTraits: .isImage)
    } else {
      Image(systemName: self.legacyName)
        .resizable()
        .scaledToFit()
        .frame(height: self.size)
        .foregroundColor(self.highlighted ? .accentColor : Color(UIColor.lightGray))
        .accessibility(label: Text(self.label))
        .accessibility(hint: Text(self.hint))
        .accessibility(removeTraits: .isImage)
    }
  }
}
