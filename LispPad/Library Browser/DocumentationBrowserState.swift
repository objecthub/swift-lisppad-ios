//
//  DocumentationBrowserState.swift
//  LispPad
//
//  Created by Matthias Zenger on 06/11/2025.
//

import SwiftUI

class DocumentationBrowserState: ObservableObject {
  @Published var selectedLib: LibraryManager.LibraryProxy? = nil
  @Published var selectedIdent: String? = nil
  @Published var docShown: Bool = false
  @Published var columnVisibility = NavigationSplitViewVisibility.doubleColumn
  @Published var preferredColumn = NavigationSplitViewColumn.sidebar
  @Published var searchLib: String = ""
  @Published var searchIdent: String = ""
  @Published var showLoadedLibraries: Bool = false
  @Published var showLibraryBrowser: Bool = true
  @Published var toggleSidebar: Bool = false
  @Published var selectedLibIdents: [String] = []

  /// Where the reader is in the documentation of the selected library or identifier. This
  /// survives the detail column being created again, e.g. when the device is rotated.
  let readingPosition = MarkdownReadingPosition()

  func detailTitle() -> String {
    if self.selectedIdent?.isEmpty ?? true {
      return self.selectedLib?.name ?? "Documentation"
    } else {
      return self.selectedIdent ?? self.selectedLib?.name ?? "Documentation"
    }
  }
  
  func identifierTitleFont() -> Font {
    let name = self.selectedLib?.name ?? "Identifiers"
    return name.count >= 20 ? LispPadUI.fileNameFont : LispPadUI.largeFileNameFont
  }
}
