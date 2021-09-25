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
  
  private static func choose<T>(iOS14: T, iOS15: T) -> T {
    if #available(iOS 15, *) {
      return iOS15
    } else {
      return iOS14
    }
  }
  
  // Padding on top of panels
  static let panelTopPadding: CGFloat = Self.choose(iOS14: 16, iOS15: 0)
  
  // Size of items in the toolbar
  static let toolbarItemSize: CGFloat = Self.choose(iOS14: 20, iOS15: 16)
  
  // Space between items in toolbar
  static let toolbarSeparator: CGFloat = Self.choose(iOS14: 16, iOS15: 10)
  
  // Toolbar item font
  static let toolbarFont: SwiftUI.Font = {
    if #available(iOS 15, *) {
      return .system(size: LispPadUI.toolbarItemSize, weight: .regular)
    } else {
      return .system(size: LispPadUI.toolbarItemSize, weight: .light)
    }
  }()  
  
  // Toolbar item font for switch items
  static let toolbarSwitchFont: SwiftUI.Font = {
    if #available(iOS 15, *) {
      return .system(size: LispPadUI.toolbarItemSize, weight: .semibold)
    } else {
      return .system(size: LispPadUI.toolbarItemSize, weight: .regular)
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
