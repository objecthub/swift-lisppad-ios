//
//  Organizer.swift
//  LispPad
//
//  Created by Matthias Zenger on 01/04/2021.
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
import QuickLook

struct Organizer: View {

  /// Determines how the organizer is presented.
  enum Style {
    /// The organizer is itself presented as a sheet. The share sheet and the move view replace
    /// the content of the organizer.
    case sheet
    /// The organizer is the target of a navigation. The share sheet and the move view are
    /// presented as sheets on top of the organizer.
    case navigationTarget
  }

  @Environment(\.dismiss) var dismiss
  @EnvironmentObject var globals: LispPadGlobals
  @EnvironmentObject var fileManager: FileManager
  @EnvironmentObject var histManager: HistoryManager

  let style: Style
  let splitViewMode: SideBySideMode?
  
  @State var showShareSheet: Bool = false
  @State var showFileImporter: Bool = false
  @State var searchAndImport: Bool = false
  @State var urlToMove: (URL, Bool)? = nil
  @StateObject var context = FileHierarchyBrowser.BrowserContext()
  @State var previewUrl: URL? = nil
  @State var showError: Bool = false

  init(style: Style = .sheet, splitViewMode: SideBySideMode? = nil) {
    self.style = style
    self.splitViewMode = splitViewMode
  }
  
  private var closeButton: Bool {
    return self.style == .sheet
  }

  /// Presents the share sheet on top of the organizer, if it is a navigation target.
  private var presentShareSheet: Binding<Bool> {
    return Binding(get: { self.style == .navigationTarget &&
                          self.showShareSheet &&
                          self.context.selectedUrl != nil },
                   set: { if !$0 { self.showShareSheet = false } })
  }

  /// Presents the move view on top of the organizer, if it is a navigation target.
  private var presentMove: Binding<Bool> {
    return Binding(get: { self.style == .navigationTarget && self.urlToMove != nil },
                   set: { if !$0 { self.urlToMove = nil } })
  }

  private var browser: some View {
    Sheet(closeButton: self.closeButton) {
      Form {
        Section {
          FileHierarchyBrowser(self.fileManager.usageRootDirectories,
                               options: [.organizer],
                               showShareSheet: $showShareSheet,
                               showFileImporter: $showFileImporter,
                               urlToMove: $urlToMove,
                               context: self.context,
                               previewUrl: $previewUrl,
                               onSelection: { url in })
          .font(.body)
        } header: {
          Text("Usage")
            .padding(.top, 30)
        }
        Section {
          FileHierarchyBrowser(self.fileManager.userRootDirectories,
                               options: [.mutable, .organizer],
                               showShareSheet: $showShareSheet,
                               showFileImporter: $showFileImporter,
                               urlToMove: $urlToMove,
                               context: self.context,
                               previewUrl: $previewUrl,
                               onSelection: { url in })
            .font(.body)
        } header: {
          Text("Locations")
        }
        Section {
          FileHierarchyBrowser(self.fileManager.systemRootDirectories,
                               options: [.organizer],
                               showShareSheet: $showShareSheet,
                               showFileImporter: $showFileImporter,
                               urlToMove: $urlToMove,
                               context: self.context,
                               previewUrl: $previewUrl,
                               onSelection: { url in })
            .font(.body)
        } header: {
          Text("System")
        }
      }
      .transition(.move(edge: .top))
    }
  }

  var body: some View {
    ZStack {
      Color(.systemGroupedBackground).ignoresSafeArea()
      VStack(alignment: .center, spacing: 0) {
        if self.style == .navigationTarget {
          self.browser
        } else if self.showShareSheet, let url = self.context.selectedUrl {
          ShareSheet(activityItems: [url])
        } else if self.urlToMove == nil {
          self.browser
        } else {
          Move(showShareSheet: $showShareSheet,
               showFileImporter: $showFileImporter,
               urlToMove: $urlToMove)
            .transition(.move(edge: .bottom))
        }
      }
      .padding(.top, self.closeButton ? 0 : -16)
    }
    .sheet(isPresented: self.presentShareSheet) {
      if let url = self.context.selectedUrl {
        ShareSheet(activityItems: [url])
          .sheetPlacement((self.splitViewMode?.isSideBySide ?? false) ?
                             ((self.splitViewMode?.isSwapped ?? false) ? .leading : .trailing)
                           : .automatic)
          .presentationDragIndicator(.visible)
          .presentationDetents([.medium, .large])
          .modifier(ToolbarVerticalBehaviorModifier(disallow: MainView.disableVerticalToolbar))
          .modifier(self.globals.services)
      }
    }
    .sheet(isPresented: self.presentMove, onDismiss: { self.context.invalidateCaches() }) {
      Move(showShareSheet: $showShareSheet,
           showFileImporter: $showFileImporter,
           urlToMove: $urlToMove)
        .sheetPlacement((self.splitViewMode?.isSideBySide ?? false) ?
                         ((self.splitViewMode?.isSwapped ?? false) ? .leading : .trailing)
                       : .automatic)
        .presentationDragIndicator(.visible)
        .presentationDetents([.medium, .large])
        .modifier(ToolbarVerticalBehaviorModifier(disallow: MainView.disableVerticalToolbar))
        .modifier(self.globals.services)
    }
    .onChange(of: self.context.errorMessage) { _, new in
      self.showError = new != nil
    }
    .fileImporter(isPresented: $showFileImporter,
                  allowedContentTypes: [.plainText, .lispPadProgram, .lispPadLibrary],
                  allowsMultipleSelection: true) { result in
      let sai = self.searchAndImport
      self.searchAndImport = false
      switch result {
        case .success(let urls):
          if !urls.isEmpty {
            if !sai {
              if let target = self.context.selectedUrl {
                self.copy(ArraySlice(urls), to: target, copied: 0, failed: [])
              }
            } else {
              self.dismiss()
            }
          }
        case .failure(let error):
          self.context.errorMessage =
            .init(title: "Import Failure", message: error.localizedDescription)
      }
    }
    .quickLookPreview(self.$previewUrl)
    .alert(self.context.errorMessage?.title ?? "Failure",
           isPresented: self.$showError,
           actions: { Button("Cancel", role: .cancel) { self.context.errorMessage = nil } },
           message: { Text(self.context.errorMessage?.message ?? "Unknown error.") })
  }
  
  func copy(_ slice: ArraySlice<URL>, to target: URL, copied: Int, failed: [(String, URL)]) {
    var urls = slice
    if urls.count > 0 && copied < 50 {
      let url = urls.removeFirst() 
      if url.startAccessingSecurityScopedResource() {
        self.fileManager.copy(url, to: target.appending(path: url.lastPathComponent)) { result in
          url.stopAccessingSecurityScopedResource()
          if case .failure(let error) = result {
            self.copy(urls, to: target, copied: copied + 1,
                      failed: failed + [(error.localizedDescription, url)])
          } else {
            self.copy(urls, to: target, copied: copied + 1, failed: failed)
          }
        }
      } else {
        self.copy(urls, to: target, copied: copied + 1, failed: failed + [("Access denied.", url)])
      }
    } else {
      if copied > failed.count {
        self.context.invalidateCaches()
      }
      switch failed.count {
        case 0:
          break
        case 1:
          self.context.errorMessage =
            .init(title: "Import Failure",
                  message: "Failed to import “\(failed.first!.1.lastPathComponent)“. " +
                           failed.first!.0)
        default:
          self.context.errorMessage =
              .init(title: "Import Failure",
                    message: "Failed to import \(failed.count) files, " +
                             "including “\(failed.first!.1.lastPathComponent)“. " +
                             failed.first!.0)
      }
    }
  }
}
