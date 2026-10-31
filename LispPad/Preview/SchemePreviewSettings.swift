//
//  SchemePreviewSettings.swift
//  LispPad
//
//  Shared between the LispPad app and the "LispPad QuickLook" extension.
//
//  Copyright © 2026 Matthias Zenger. All rights reserved.
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

import UIKit

/// The editor settings that determine how Quick Look previews Scheme code. The app publishes
/// them to the app group `SchemePreview.appGroup`, from where the extension reads them. The
/// extension cannot see the app's own user defaults.
struct SchemePreviewSettings: Codable, Equatable {

  /// An RGBA color
  struct RGBA: Codable, Equatable {
    var red: Double
    var green: Double
    var blue: Double
    var alpha: Double = 1.0

    init(_ red: Double, _ green: Double, _ blue: Double, _ alpha: Double = 1.0) {
      self.red = red
      self.green = green
      self.blue = blue
      self.alpha = alpha
    }

    init(_ color: UIColor) {
      var red: CGFloat = 0.0
      var green: CGFloat = 0.0
      var blue: CGFloat = 0.0
      var alpha: CGFloat = 0.0
      if !color.getRed(&red, green: &green, blue: &blue, alpha: &alpha),
         let srgb = CGColorSpace(name: CGColorSpace.sRGB),
         let converted = color.cgColor.converted(to: srgb, intent: .defaultIntent, options: nil),
         let components = converted.components,
         components.count >= 4 {
        red = components[0]
        green = components[1]
        blue = components[2]
        alpha = components[3]
      }
      self.init(Double(red), Double(green), Double(blue), Double(alpha))
    }

    var uiColor: UIColor {
      return UIColor(red: self.red, green: self.green, blue: self.blue, alpha: self.alpha)
    }
  }

  /// A color for the light and for the dark appearance
  struct Colors: Codable, Equatable {
    var light: RGBA
    var dark: RGBA

    init(light: RGBA, dark: RGBA) {
      self.light = light
      self.dark = dark
    }

    init(light: UIColor, dark: UIColor) {
      self.init(light: RGBA(light), dark: RGBA(dark))
    }

    /// A color that changes with the appearance
    var uiColor: UIColor {
      let light = self.light.uiColor
      let dark = self.dark.uiColor
      return UIColor { traits in traits.userInterfaceStyle == .dark ? dark : light }
    }
  }

  /// Is syntax highlighting enabled?
  var highlightSyntax: Bool

  /// Are documented identifiers highlighted?
  var markupIdent: Bool

  /// The PostScript name of the font, or `nil` for the system's monospaced font
  var fontName: String?

  /// The font size in points
  var fontSize: Double

  var text: Colors
  var parens: Colors
  var literals: Colors
  var comments: Colors
  var docuIdent: Colors

  /// The settings used before the app has published any. They correspond to the defaults of
  /// the editor.
  static let `default` = SchemePreviewSettings(
    highlightSyntax: true,
    markupIdent: true,
    fontName: nil,
    fontSize: 13.0,
    text: Colors(light: RGBA(0.0, 0.0, 0.0), dark: RGBA(1.0, 1.0, 1.0)),
    parens: Colors(light: RGBA(0.6, 0.35, 0.2), dark: RGBA(0.85, 0.75, 0.45)),
    literals: Colors(light: RGBA(0.0, 0.6, 0.0), dark: RGBA(0.7, 0.8, 0.3)),
    comments: Colors(light: RGBA(1.0, 0.1, 0.1), dark: RGBA(1.0, 0.55, 0.45)),
    docuIdent: Colors(light: RGBA(0.2, 0.2, 1.0), dark: RGBA(0.5, 0.8, 1.0)))

  private static let key = "Preview.schemeSettings"

  /// The user defaults shared between the app and the extension
  static var sharedDefaults: UserDefaults? {
    return UserDefaults(suiteName: SchemePreview.appGroup)
  }

  /// Returns the published settings, or the defaults if there are none.
  static func load(from defaults: UserDefaults? = SchemePreviewSettings.sharedDefaults)
      -> SchemePreviewSettings {
    guard let data = defaults?.data(forKey: Self.key),
          let settings = try? JSONDecoder().decode(SchemePreviewSettings.self, from: data) else {
      return .default
    }
    return settings
  }

  /// Publishes the settings. Nothing is written if they are published already.
  func store(in defaults: UserDefaults? = SchemePreviewSettings.sharedDefaults) {
    let encoder = JSONEncoder()
    encoder.outputFormatting = .sortedKeys
    guard let defaults, let data = try? encoder.encode(self) else {
      return
    }
    if defaults.data(forKey: Self.key) != data {
      defaults.set(data, forKey: Self.key)
    }
  }

  /// The colors for highlighting code.
  var palette: SchemeSyntaxPalette {
    return SchemeSyntaxPalette(text: self.text.uiColor,
                               parens: self.parens.uiColor,
                               literals: self.literals.uiColor,
                               comments: self.comments.uiColor,
                               docuIdent: self.docuIdent.uiColor)
  }

  /// The font for showing code. It is scaled like the font of the editor.
  var font: UIFont {
    let size = CGFloat(self.fontSize)
    let font = self.fontName.flatMap { UIFont(name: $0, size: size) }
             ?? UIFont.monospacedSystemFont(ofSize: size, weight: .regular)
    return UIFontMetrics(forTextStyle: .body).scaledFont(for: font)
  }
}
