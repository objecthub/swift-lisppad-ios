//
//  FontMap.swift
//  LispPad
//
//  Created by Matthias Zenger on 20/02/2022.
//

import Foundation
import SwiftUI
import UIKit

struct FontMap {
  
  enum FontSize {
    case tiny
    case small
    case compact
    case regular
    case medium
    case large
    case huge
    
    init(_ string: String) {
      switch string {
        case "font-tiny":
          self = .tiny
        case "font-small", "Tiny":
          self = .small
        case "font-compact", "Small":
          self = .compact
        case "font-medium", "Medium":
          self = .medium
        case "font-large", "Large":
          self = .large
        case "font-huge", "Huge", "X-Large":
          self = .huge
        default:
          self = .regular
      }
    }
    
    var string: String {
      switch self {
        case .tiny:
          return "font-tiny"
        case .small:
          return "font-small"
        case .compact:
          return "font-compact"
        case .regular:
          return "font-regular"
        case .medium:
          return "font-medium"
        case .large:
          return "font-large"
        case .huge:
          return "font-huge"
      }
    }
    
    var size: CGFloat {
      switch self {
        case .tiny:
          return 11.0
        case .small:
          return 12.0
        case .compact:
          return 13.0
        case .regular:
          return 14.0
        case .medium:
          return 15.0
        case .large:
          return 16.0
        case .huge:
          return 18.0
      }
    }
  }
  
  let fonts: [String : String]
  
  init(_ mapping: (String, String)...) {
    var fonts: [String : String] = [:]
    for (displayName, fontName) in mapping {
      if UIFont(name: fontName, size: FontSize.regular.size) != nil {
        fonts[displayName] = fontName
      }
    }
    fonts["System"] = ""
    self.fonts = fonts
  }
  
  func uiFont(name: String = "System", size: FontSize) -> UIFont {
    let fontName = self.fonts[name]
    let font = fontName?.isEmpty ?? true
             ? UIFont.monospacedSystemFont(ofSize: size.size, weight: .regular)
             : (UIFont(name: self.fonts[name]!, size: size.size) ??
                  UIFont.monospacedSystemFont(ofSize: size.size, weight: .regular))
    let fontMetrics = UIFontMetrics(forTextStyle: .body)
    return fontMetrics.scaledFont(for: font)
  }
  
  func font(name: String = "System", size: FontSize) -> Font {
    return Font(self.uiFont(name: name, size: size))
  }
}
