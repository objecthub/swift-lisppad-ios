//
//  Appearance.swift
//  LispPad
//
//  Created by Matthias Zenger on 17/10/2024.
//

import SwiftUI

enum Appearance: Int {
  case system = 0
  case light = 1
  case dark = 2
  
  init(value: Int) {
    switch value {
      case 1:
        self = .light
      case 2:
        self = .dark
      default:
        self = .system
    }
  }
  
  var colorScheme: ColorScheme? {
    switch self {
      case .system:
        return nil
      case .light:
        return .light
      case .dark:
        return .dark
    }
  }
}
