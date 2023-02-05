//
//  LispPadUI.swift
//  LispPad
//
//  Created by Matthias Zenger on 25/09/2021.
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
  
  private static func choose<T>(iOS15: T, iOS16: T) -> T {
    if #available(iOS 16, *) {
      return iOS16
    } else {
      return iOS15
    }
  }
  
  // Padding on top of panels
  static let panelTopPadding: CGFloat = Self.choose(iOS15: 0, iOS16: 0)
  
  // Size of items in the toolbar
  static let toolbarItemSize: CGFloat = Self.choose(iOS15: 16, iOS16: 16)
  
  // Size of file name in the toolbar
  static let fileNameFontSize: CGFloat = Self.choose(iOS15: 14, iOS16: 14)
  
  // Space between items in toolbar
  static let toolbarSeparator: CGFloat = Self.choose(iOS15: 10, iOS16: 9)
  
  // Color used for menu indicators in toolbar
  static let menuIndicatorColor: UIColor = UIColor(named: "DarkKeyColor") ?? UIColor.lightGray
  
  // Toolbar item font
  static let toolbarFont: SwiftUI.Font = {
    if #available(iOS 16, *) {
      return .system(size: LispPadUI.toolbarItemSize, weight: .regular)
    } else if #available(iOS 15, *) {
      return .system(size: LispPadUI.toolbarItemSize, weight: .regular)
    } else {
      return .system(size: LispPadUI.toolbarItemSize, weight: .light)
    }
  }()
  
  // Toolbar item font for switch items
  static let toolbarSwitchFont: SwiftUI.Font = {
    if #available(iOS 16, *) {
      return .system(size: LispPadUI.toolbarItemSize, weight: .semibold)
    } else if #available(iOS 15, *) {
      return .system(size: LispPadUI.toolbarItemSize, weight: .semibold)
    } else {
      return .system(size: LispPadUI.toolbarItemSize, weight: .regular)
    }
  }()
  
  // Small editor file name font
  static let fileNameFont: SwiftUI.Font = {
    if #available(iOS 16, *) {
      return .system(size: LispPadUI.fileNameFontSize, weight: .regular)
    } else if #available(iOS 15, *) {
      return .system(size: LispPadUI.fileNameFontSize, weight: .regular)
    } else {
      return .system(size: LispPadUI.fileNameFontSize, weight: .light)
    }
  }()
  
  // Large editor file name font
  static let largeFileNameFont: SwiftUI.Font = {
    if #available(iOS 16, *) {
      return .system(size: LispPadUI.toolbarItemSize, weight: .regular)
    } else if #available(iOS 15, *) {
      return .system(size: LispPadUI.toolbarItemSize, weight: .regular)
    } else {
      return .system(size: LispPadUI.toolbarItemSize, weight: .light)
    }
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
