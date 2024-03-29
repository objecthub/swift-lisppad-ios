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
  
  // Size of file name in the toolbar
  static let fileNameFontSize: CGFloat = 14
  
  // Space between items in toolbar
  static let toolbarSeparator: CGFloat = 9
  
  // Color used for menu indicators in toolbar
  static let menuIndicatorColor: UIColor = UIColor(named: "DarkKeyColor") ?? UIColor.lightGray
  
  // Toolbar item font
  static let toolbarFont: SwiftUI.Font = {
    return .system(size: LispPadUI.toolbarItemSize, weight: .regular)
  }()
  
  // Toolbar item font for switch items
  static let toolbarSwitchFont: SwiftUI.Font = {
    return .system(size: LispPadUI.toolbarItemSize, weight: .regular)
  }()
  
  // Small editor file name font
  static let fileNameFont: SwiftUI.Font = {
    return .system(size: LispPadUI.fileNameFontSize, weight: .regular)
  }()
  
  // Large editor file name font
  static let largeFileNameFont: SwiftUI.Font = {
    return .system(size: LispPadUI.toolbarItemSize, weight: .regular)
  }()
  
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
