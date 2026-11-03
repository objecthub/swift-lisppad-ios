//
//  LispPadUI.swift
//  LispPad
//
//  Created by Matthias Zenger on 25/09/2021.
//  Copyright © 2021-2023 Matthias Zenger. All rights reserved.
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

import Foundation
import SwiftUI
import UIKit

struct LispPadUI {
  
  // Padding on top of panels
  static let panelTopPadding: CGFloat = 0
  
  // Size of items in the toolbar
  static let toolbarItemSize: CGFloat = 16
  
  // Size of items in the definitions panel
  static let definitionsSize: CGFloat = 15
  
  // Size of categories in the definitions panel
  static let definitionsCategorySize: CGFloat = 12
  
  // Size of file name in the toolbar
  static let fileNameFontSize: CGFloat = 14
  
  // Space between items in toolbar
  static let toolbarSeparator: CGFloat = 10
  
  // Color used for menu indicators in toolbar
  static let menuIndicatorColor: UIColor = UIColor(named: "DarkKeyColor") ?? UIColor.lightGray
  
  // Toolbar item font
  static let toolbarFont: SwiftUI.Font = {
    return .system(size: LispPadUI.toolbarItemSize, weight: .regular)
  }()
  
  // Toolbar font for icons
  static let toolbarIconFont: SwiftUI.Font = {
    return .system(size: LispPadUI.toolbarItemSize, weight: .regular)
  }()
  
  // Toolbar item font for switch items
  static let toolbarSwitchFont: SwiftUI.Font = {
    return .system(size: LispPadUI.toolbarItemSize, weight: .regular)
  }()
  
  // Font for definition items
  static let definitionsFont: SwiftUI.Font = {
    return .system(size: LispPadUI.definitionsSize, weight: .regular)
  }()
  
  // Font for definition category items
  static let definitionsCategoryFont: SwiftUI.Font = {
    return .system(size: LispPadUI.definitionsCategorySize, weight: .regular)
  }()
  
  // Small editor file name font
  static let fileNameFont: SwiftUI.Font = {
    return .system(size: LispPadUI.fileNameFontSize, weight: .regular)
  }()
  
  // Large editor file name font
  static let largeFileNameFont: SwiftUI.Font = {
    return .system(size: LispPadUI.toolbarItemSize, weight: .regular)
  }()
  
  // Number of characters from which a title in the toolbar is shown in the small font
  static let longToolbarTitleLength: Int = 15
  
  // Font for titles in the toolbar; long titles are shown in a smaller font
  static func toolbarTitleFont(for title: String) -> SwiftUI.Font {
    return title.count >= LispPadUI.longToolbarTitleLength
        ? LispPadUI.fileNameFont
        : LispPadUI.largeFileNameFont
  }
  
  // Horizontal space taken up in the navigation bar by a single toolbar button, including margins
  static let toolbarButtonWidth: CGFloat = 66
  
  // Horizontal space kept free around a title in the navigation bar
  static let toolbarTitleSlack: CGFloat = 8

  // Vertical padding inside a list row at the default text size (see `denseListRow()`). With
  // the 17 pt body font, a row is 2 pt taller for every point of padding: 12 gives rows of
  // about 44 pt, as on iOS 18, while the system default on iOS 26 and later is about 52 pt.
  static let listRowVerticalPadding: CGFloat = 12

  // Minimum height of a list row at the default text size (see `denseList()`)
  static let listRowMinHeight: CGFloat = 36

  static func configure() {
    let coloredAppearance = UINavigationBarAppearance()
    coloredAppearance.configureWithOpaqueBackground()
    coloredAppearance.backgroundColor = UIColor(named: "NavigationBarColor")
    // coloredAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
    // coloredAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
    UINavigationBar.appearance().standardAppearance = coloredAppearance
    UINavigationBar.appearance().compactAppearance = coloredAppearance
    UINavigationBar.appearance().scrollEdgeAppearance = coloredAppearance
    // UINavigationBar.appearance().barTintColor = UIColor(named: "NavigationBarColor")
  }
}

/// Sets the minimum row height of a list, scaled like `.body` text.
///
/// Since iOS 26, lists use roomier default row metrics than before. This restores a denser
/// layout there; earlier versions keep their system defaults. Use it together with
/// `denseListRow()`, which has to be applied to the rows (not the list). When a list is nested
/// in a form, the form takes over its rows and has to apply this modifier, too.
private struct DenseList: ViewModifier {
  @ScaledMetric(relativeTo: .body) private var minRowHeight = LispPadUI.listRowMinHeight

  @ViewBuilder
  func body(content: Content) -> some View {
    if #available(iOS 26.0, *) {
      content.environment(\.defaultMinListRowHeight, self.minRowHeight)
    } else {
      content
    }
  }
}

/// Sets the vertical padding of a list row, scaled like `.body` text. The horizontal insets
/// remain the ones of the system. Has to be applied to the content of a row (or to a
/// `ForEach` or `Section`), not to the list itself. The exception is a list nested in a form:
/// there, it has to be applied to the nested list, since applying it to its rows has no effect.
/// Earlier than iOS 26 it does nothing.
private struct DenseListRow: ViewModifier {
  @ScaledMetric(relativeTo: .body) private var padding = LispPadUI.listRowVerticalPadding

  @ViewBuilder
  func body(content: Content) -> some View {
    if #available(iOS 26.0, *) {
      content.listRowInsets(.vertical, self.padding)
    } else {
      content
    }
  }
}

extension View {

  /// Makes the rows of this list denser, depending on the dynamic text size.
  func denseList() -> some View {
    return self.modifier(DenseList())
  }

  /// Makes this list row denser, depending on the dynamic text size.
  func denseListRow() -> some View {
    return self.modifier(DenseListRow())
  }
}

/// Lays out the controls of a toolbar item group.
///
/// An `HStack` gives control over the spacing of the controls. When an iOS app runs on a Mac,
/// the toolbar shows only the first control of such a stack and clips the rest. There, the
/// controls are handed to the toolbar directly, which groups them like the stack does. Note
/// that modifiers applied to this view are then applied to each of the controls; use
/// `when(iOSAppOnMac:_:)` to attach something (e.g. a presentation) only once.
struct ToolbarControls<Content: View>: View {
  let spacing: CGFloat
  let content: Content
  
  init(spacing: CGFloat = LispPadUI.toolbarSeparator, @ViewBuilder content: () -> Content) {
    self.spacing = spacing
    self.content = content()
  }
  
  var body: some View {
    if ProcessInfo.processInfo.isiOSAppOnMac {
      self.content
    } else {
      HStack(alignment: .center, spacing: self.spacing) {
        self.content
      }
    }
  }
}

extension View {
  /// Applies `transform` if the app runs as an iOS app on a Mac (`iOSAppOnMac == true`) or
  /// everywhere else (`iOSAppOnMac == false`).
  @ViewBuilder
  func when<Result: View>(iOSAppOnMac: Bool, _ transform: (Self) -> Result) -> some View {
    if ProcessInfo.processInfo.isiOSAppOnMac == iOSAppOnMac {
      transform(self)
    } else {
      self
    }
  }
}
