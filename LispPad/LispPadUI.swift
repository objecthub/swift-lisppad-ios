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
    return .system(size: LispPadUI.toolbarItemSize, weight: .semibold)
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
