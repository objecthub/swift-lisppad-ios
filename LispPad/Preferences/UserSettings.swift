//
//  UserSettings.swift
//  LispPad
//
//  Created by Matthias Zenger on 01/05/2021.
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

import Foundation
import SwiftUI
import UIKit

///
/// Class `UserSettings` defines all defaults and default persistency logic for the settings
/// of LispPad.
/// 
final class UserSettings: ObservableObject {
  
  // UserDefault keys
  private static let foldersOnICloudKey = "Folders.iCloud"
  private static let foldersOnDeviceKey = "Folders.device"
  private static let consoleFontSizeKey = "Console.fontSize"
  private static let consoleTightSpacingKey = "Console.tightSpacing"
  private static let consoleBackgroundColorKey = "Console.graphicsBackgroundColor"
  private static let maxConsoleHistoryKey = "Console.maxConsoleHistory"
  private static let inputFontSizeKey = "Console.inputFontSize"
  private static let inputTightSpacingKey = "Console.inputTightSpacing"
  private static let documentationFontSizeKey = "Documentation.fontSize"
  private static let consoleHighlightMatchingParenKey = "Console.highlightMatchingParen"
  private static let consoleExtendedKeyboardKey = "Console.extendedKeyboard"
  private static let consoleAutoIndentKey = "Console.schemeAutoIndent"
  private static let consoleHighlightSyntaxKey = "Console.schemeHighlightSyntax"
  private static let consoleMarkupIdentKey = "Console.schemeMarkupIdent"
  private static let balancedParenthesisKey = "Console.balancedParenthesis"
  private static let maxCommandHistoryKey = "Console.maxCommandHistory"
  private static let logSeverityFilterKey = "Log.severityFilter"
  private static let logMessageFilterKey = "Log.messageFilter"
  private static let logFilterTagsKey = "Log.filterTags"
  private static let logFilterMessagesKey = "Log.filterMessages"
  private static let logCommandsKey = "Log.commands"
  private static let logGarbageCollectionKey = "Log.garbageCollection"
  private static let logMaxHistoryKey = "Log.maxHistory"
  private static let editorFontSizeKey = "Editor.fontSize"
  private static let indentSizeKey = "Editor.indentSize"
  private static let showLineNumbersKey = "Editor.showLineNumbers"
  private static let highlightMatchingParenKey = "Editor.highlightMatchingParen"
  private static let highlightCurrentLineKey = "Editor.highlightCurrentLine"
  private static let extendedKeyboardKey = "Editor.extendedKeyboard"
  private static let maxRecentFilesKey = "Editor.maxRecentFiles"
  private static let schemeAutoIndentKey = "Editor.schemeAutoIndent"
  private static let schemeHighlightSyntaxKey = "Editor.schemeHighlightSyntax"
  private static let schemeMarkupIdentKey = "Editor.schemeMarkupIdent"
  private static let markdownAutoIndentKey = "Editor.markdownAutoIndent"
  private static let markdownHighlightSyntaxKey = "Editor.markdownHighlightSyntax"
  private static let docuIdentColorKey = "Editor.docuIdentColor"
  private static let parensColorKey = "Editor.parensColor"
  private static let literalsColorKey = "Editor.literalsColor"
  private static let commentsColorKey = "Editor.commentsColor"
  private static let headerColorKey = "Editor.headerColor"
  private static let subheaderColorKey = "Editor.subheaderColor"
  private static let emphasisColorKey = "Editor.emphasisColor"
  private static let bulletsColorKey = "Editor.bulletsColor"
  private static let blockquoteColorKey = "Editor.blockquoteColor"
  private static let codeColorKey = "Editor.codeColor"
  private static let codingFontKey = "General.codingFont"
  
  // Font sizes
  static let tinyFontSize = "Tiny"
  static let smallFontSize = "Small"
  static let mediumFontSize = "Medium"
  static let largeFontSize = "Large"
  static let hugeFontSize = "Huge"
  static let xlargeFontSize = "X-Large"
  
  /// Regular font map
  /*
  private static let fontMap: [String : Font] = [
    UserSettings.tinyFontSize   : .system(.caption, design: .default),
    UserSettings.smallFontSize  : .system(.footnote, design: .default),
    UserSettings.mediumFontSize : .system(.subheadline, design: .default),
    UserSettings.largeFontSize  : .system(.callout, design: .default),
    UserSettings.xlargeFontSize : .system(.body, design: .default),
    UserSettings.hugeFontSize   : .system(.body, design: .default)
  ]
  */
  
  static let monospacedFontMap = FontMap(("Courier", "CourierNewPSMT"),
                                         ("Menlo", "Menlo-Regular"),
                                         ("Source Code Pro", "SourceCodePro-Regular"),
                                         ("Roboto Mono", "RobotoMono-Regular"),
                                         ("Fira Code", "FiraCode-Regular"),
                                         ("Iosevka", "Iosevka"),
                                         ("Iosevka Extended", "Iosevka-Extended"),
                                         ("Inconsolata", "Inconsolata-Regular"))
  
  /// Monospaced font map
  /* private static let monospacedFontMap: [String : Font] = [
    UserSettings.tinyFontSize   : .system(.caption, design: .monospaced),
    UserSettings.smallFontSize  : .system(.footnote, design: .monospaced),
    UserSettings.mediumFontSize : .system(.subheadline, design: .monospaced),
    UserSettings.largeFontSize  : .system(.callout, design: .monospaced),
    UserSettings.xlargeFontSize : .system(.body, design: .monospaced),
    UserSettings.hugeFontSize   : .system(.body, design: .monospaced)
  ]
  
  /// Monospaced UIFont map
  private static let monospacedUIFontMap: [String : UIFont] = [
    UserSettings.tinyFontSize   : .monospacedSystemFont(
                                    ofSize: UIFont.preferredFont(forTextStyle: .caption1).pointSize,
                                    weight: .regular),
    UserSettings.smallFontSize  : .monospacedSystemFont(
                                    ofSize: UIFont.preferredFont(forTextStyle: .footnote).pointSize,
                                    weight: .regular),
    UserSettings.mediumFontSize : .monospacedSystemFont(
                                    ofSize: UIFont.preferredFont(forTextStyle: .subheadline)
                                      .pointSize,
                                    weight: .regular),
    UserSettings.largeFontSize  : .monospacedSystemFont(
                                    ofSize: UIFont.preferredFont(forTextStyle: .callout).pointSize,
                                    weight: .regular),
    UserSettings.xlargeFontSize : .monospacedSystemFont(
                                    ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize,
                                    weight: .regular),
    UserSettings.hugeFontSize   : .monospacedSystemFont(
                                    ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize,
                                    weight: .regular)
  ] */
  
  
  /// Graphics background
  static let whiteBackground = "white"
  static let blackBackground = "black"
  static let systemBackground = "system"
  
  private static let backgroundColorMap: [String : Color] = [
    UserSettings.whiteBackground : Color.white,
    UserSettings.blackBackground : Color.black,
    UserSettings.systemBackground : Color.clear
  ]
  
  /// The user settings object
  static let standard = UserSettings()
  
  @Published var foldersOnICloud: Bool {
    didSet {
      UserDefaults.standard.set(self.foldersOnICloud, forKey: Self.foldersOnICloudKey)
    }
  }
  
  @Published var foldersOnDevice: Bool {
    didSet {
      UserDefaults.standard.set(self.foldersOnDevice, forKey: Self.foldersOnDeviceKey)
    }
  }
  
  @Published var consoleFontSize: FontMap.FontSize {
    didSet {
      UserDefaults.standard.set(self.consoleFontSize.string, forKey: Self.consoleFontSizeKey)
    }
  }
  
  @Published var consoleTightSpacing: Bool {
    didSet {
      UserDefaults.standard.set(self.consoleTightSpacing, forKey: Self.consoleTightSpacingKey)
    }
  }
  
  @Published var consoleBackgroundColor: String {
    didSet {
      UserDefaults.standard.set(self.consoleBackgroundColor, forKey: Self.consoleBackgroundColorKey)
    }
  }
  
  @Published var maxConsoleHistory: Int {
    didSet {
      UserDefaults.standard.set(self.maxConsoleHistory, forKey: Self.maxConsoleHistoryKey)
    }
  }
  
  @Published var inputFontSize: FontMap.FontSize {
    didSet {
      UserDefaults.standard.set(self.inputFontSize.string, forKey: Self.inputFontSizeKey)
    }
  }
  
  @Published var inputTightSpacing: Bool {
    didSet {
      UserDefaults.standard.set(self.inputTightSpacing, forKey: Self.inputTightSpacingKey)
    }
  }
  
  @Published var balancedParenthesis: Bool {
    didSet {
      UserDefaults.standard.set(self.balancedParenthesis, forKey: Self.balancedParenthesisKey)
    }
  }
  
  @Published var maxCommandHistory: Int {
    didSet {
      UserDefaults.standard.set(self.maxCommandHistory, forKey: Self.maxCommandHistoryKey)
    }
  }
  
  @Published var logSeverityFilter: Severity {
    didSet {
      UserDefaults.standard.set(self.logSeverityFilter.description,
                                forKey: Self.logSeverityFilterKey)
    }
  }
  
  @Published var logMessageFilter: String {
    didSet {
      UserDefaults.standard.set(self.logMessageFilter, forKey: Self.logMessageFilterKey)
    }
  }
  
  @Published var logFilterTags: Bool {
    didSet {
      UserDefaults.standard.set(self.logFilterTags, forKey: Self.logFilterTagsKey)
    }
  }
  
  @Published var logFilterMessages: Bool {
    didSet {
      UserDefaults.standard.set(self.logFilterMessages, forKey: Self.logFilterMessagesKey)
    }
  }
  
  @Published var logCommands: Bool {
    didSet {
      UserDefaults.standard.set(self.logCommands, forKey: Self.logCommandsKey)
    }
  }
  
  @Published var logGarbageCollection: Bool {
    didSet {
      UserDefaults.standard.set(self.logGarbageCollection, forKey: Self.logGarbageCollectionKey)
    }
  }
  
  @Published var logMaxHistory: Int {
    didSet {
      UserDefaults.standard.set(self.logMaxHistory, forKey: Self.logMaxHistoryKey)
    }
  }
  
  @Published var documentationFontSize: String {
    didSet {
      UserDefaults.standard.set(self.documentationFontSize, forKey: Self.documentationFontSizeKey)
    }
  }
  
  @Published var consoleHighlightMatchingParen: Bool {
    didSet {
      UserDefaults.standard.set(self.consoleHighlightMatchingParen,
                                forKey: Self.consoleHighlightMatchingParenKey)
    }
  }
  
  @Published var consoleExtendedKeyboard: Bool {
    didSet {
      UserDefaults.standard.set(self.consoleExtendedKeyboard,
                                forKey: Self.consoleExtendedKeyboardKey)
    }
  }
  
  @Published var consoleAutoIndent: Bool {
    didSet {
      UserDefaults.standard.set(self.consoleAutoIndent, forKey: Self.consoleAutoIndentKey)
    }
  }
  
  @Published var consoleHighlightSyntax: Bool {
    didSet {
      self.syntaxHighlightingUpdate = Date()
      UserDefaults.standard.set(self.consoleHighlightSyntax, forKey: Self.consoleHighlightSyntaxKey)
    }
  }
  
  @Published var consoleMarkupIdent: Bool {
    didSet {
      UserDefaults.standard.set(self.consoleMarkupIdent, forKey: Self.consoleMarkupIdentKey)
    }
  }
  
  @Published var editorFontSize: FontMap.FontSize {
    didSet {
      UserDefaults.standard.set(self.editorFontSize.string, forKey: Self.editorFontSizeKey)
    }
  }
  
  @Published var indentSize: Int {
    didSet {
      UserDefaults.standard.set(self.indentSize, forKey: Self.indentSizeKey)
    }
  }
  
  @Published var showLineNumbers: Bool {
    didSet {
      UserDefaults.standard.set(self.showLineNumbers, forKey: Self.showLineNumbersKey)
    }
  }
  
  @Published var highlightMatchingParen: Bool {
    didSet {
      UserDefaults.standard.set(self.highlightMatchingParen, forKey: Self.highlightMatchingParenKey)
    }
  }
  
  @Published var highlightCurrentLine: Bool {
    didSet {
      UserDefaults.standard.set(self.highlightCurrentLine, forKey: Self.highlightCurrentLineKey)
    }
  }
  
  @Published var extendedKeyboard: Bool {
    didSet {
      UserDefaults.standard.set(self.extendedKeyboard, forKey: Self.extendedKeyboardKey)
    }
  }
  
  @Published var maxRecentFiles: Int {
    didSet {
      UserDefaults.standard.set(self.maxRecentFiles, forKey: Self.maxRecentFilesKey)
    }
  }
  
  @Published var schemeAutoIndent: Bool {
    didSet {
      UserDefaults.standard.set(self.schemeAutoIndent, forKey: Self.schemeAutoIndentKey)
    }
  }
  
  @Published var schemeHighlightSyntax: Bool {
    didSet {
      self.syntaxHighlightingUpdate = Date()
      UserDefaults.standard.set(self.schemeHighlightSyntax, forKey: Self.schemeHighlightSyntaxKey)
    }
  }
  
  @Published var schemeMarkupIdent: Bool {
    didSet {
      UserDefaults.standard.set(self.schemeMarkupIdent, forKey: Self.schemeMarkupIdentKey)
    }
  }
  
  @Published var markdownAutoIndent: Bool {
    didSet {
      UserDefaults.standard.set(self.markdownAutoIndent, forKey: Self.markdownAutoIndentKey)
    }
  }
  
  @Published var markdownHighlightSyntax: Bool {
    didSet {
      self.syntaxHighlightingUpdate = Date()
      UserDefaults.standard.set(self.markdownHighlightSyntax, forKey:
                                  Self.markdownHighlightSyntaxKey)
    }
  }
  
  @Published var docuIdentColor: CGColor {
    didSet {
      self.syntaxHighlightingUpdate = Date()
      UserDefaults.standard.set(self.docuIdentColor, forKey: Self.docuIdentColorKey)
    }
  }
  
  @Published var parensColor: CGColor {
    didSet {
      self.syntaxHighlightingUpdate = Date()
      UserDefaults.standard.set(self.parensColor, forKey: Self.parensColorKey)
    }
  }
  
  @Published var literalsColor: CGColor {
    didSet {
      self.syntaxHighlightingUpdate = Date()
      UserDefaults.standard.set(self.literalsColor, forKey: Self.literalsColorKey)
    }
  }
  
  @Published var commentsColor: CGColor {
    didSet {
      self.syntaxHighlightingUpdate = Date()
      UserDefaults.standard.set(self.commentsColor, forKey: Self.commentsColorKey)
    }
  }
  
  @Published var headerColor: CGColor {
    didSet {
      self.syntaxHighlightingUpdate = Date()
      UserDefaults.standard.set(self.headerColor, forKey: Self.headerColorKey)
    }
  }
  
  @Published var subheaderColor: CGColor {
    didSet {
      self.syntaxHighlightingUpdate = Date()
      UserDefaults.standard.set(self.subheaderColor, forKey: Self.subheaderColorKey)
    }
  }
  
  @Published var emphasisColor: CGColor {
    didSet {
      self.syntaxHighlightingUpdate = Date()
      UserDefaults.standard.set(self.emphasisColor, forKey: Self.emphasisColorKey)
    }
  }
  
  @Published var bulletsColor: CGColor {
    didSet {
      self.syntaxHighlightingUpdate = Date()
      UserDefaults.standard.set(self.bulletsColor, forKey: Self.bulletsColorKey)
    }
  }
  
  @Published var blockquoteColor: CGColor {
    didSet {
      self.syntaxHighlightingUpdate = Date()
      UserDefaults.standard.set(self.blockquoteColor, forKey: Self.blockquoteColorKey)
    }
  }
  
  @Published var codeColor: CGColor {
    didSet {
      self.syntaxHighlightingUpdate = Date()
      UserDefaults.standard.set(self.codeColor, forKey: Self.codeColorKey)
    }
  }
  
  @Published var codingFont: String {
    didSet {
      UserDefaults.standard.set(self.codingFont, forKey: Self.codingFontKey)
    }
  }
  
  var consoleGraphicsBackgroundColor: Color {
    return Self.backgroundColorMap[self.consoleBackgroundColor] ?? .clear
  }
  
  var consoleFont: Font {
    return Self.monospacedFontMap.font(name: self.codingFont, size: self.consoleFontSize)
             .leading(self.consoleTightSpacing ? .tight : .standard)
  }
  
  var consoleInfoFont: Font {
    return Self.monospacedFontMap.font(name: self.codingFont, size: self.consoleFontSize)
             .leading(self.consoleTightSpacing ? .tight : .standard)
  }
  
  var inputFont: UIFont {
    return Self.monospacedFontMap.uiFont(name: self.codingFont, size: self.inputFontSize)
  }
  
  var editorFont: UIFont {
    return Self.monospacedFontMap.uiFont(name: self.codingFont, size: self.editorFontSize)
  }
  
  var documentationTextFontSize: Float {
    switch self.documentationFontSize {
      case UserSettings.smallFontSize:
        return 13.0
      case UserSettings.largeFontSize:
        return 17.0
      default:
        return 15.0
    }
  }
  
  var documentationCodeFontSize: Float {
    switch self.documentationFontSize {
      case UserSettings.smallFontSize:
        return 11.0
      case UserSettings.largeFontSize:
        return 15.0
      default:
        return 13.0
    }
  }
  
  var documentationLibraryFontSize: Float {
    switch self.documentationFontSize {
      case UserSettings.smallFontSize:
        return 12.0
      case UserSettings.largeFontSize:
        return 16.0
      default:
        return 14.0
    }
  }
  
  var syntaxHighlightingUpdate = Date()
  
  private init() {
    self.foldersOnICloud = UserDefaults.standard.boolean(forKey: Self.foldersOnICloudKey)
    self.foldersOnDevice = UserDefaults.standard.boolean(forKey: Self.foldersOnDeviceKey)
    self.consoleFontSize = .init(UserDefaults.standard.str(forKey: Self.consoleFontSizeKey,
                                                           FontMap.FontSize.compact.string))
    self.consoleTightSpacing = UserDefaults.standard.boolean(forKey: Self.consoleTightSpacingKey,
                                                             false)
    self.consoleBackgroundColor = UserDefaults.standard.str(
      forKey: Self.consoleBackgroundColorKey, UserSettings.whiteBackground)
    self.maxConsoleHistory = UserDefaults.standard.int(forKey: Self.maxConsoleHistoryKey, 1000)
    self.inputFontSize = .init(UserDefaults.standard.str(forKey: Self.inputFontSizeKey,
                                                         FontMap.FontSize.compact.string))
    self.inputTightSpacing = UserDefaults.standard.boolean(forKey: Self.inputTightSpacingKey,
                                                           false)
    self.balancedParenthesis = UserDefaults.standard.boolean(forKey: Self.balancedParenthesisKey)
    self.maxCommandHistory = UserDefaults.standard.int(forKey: Self.maxCommandHistoryKey, 30)
    self.logSeverityFilter = Severity(UserDefaults.standard.str(forKey:
                                        Self.logSeverityFilterKey, "Default"))
    self.logMessageFilter = UserDefaults.standard.str(forKey: Self.logMessageFilterKey, "")
    self.logFilterTags = UserDefaults.standard.boolean(forKey: Self.logFilterTagsKey)
    self.logFilterMessages = UserDefaults.standard.boolean(forKey: Self.logFilterMessagesKey)
    self.logCommands = UserDefaults.standard.boolean(forKey: Self.logCommandsKey)
    self.logGarbageCollection = UserDefaults.standard.boolean(forKey: Self.logGarbageCollectionKey)
    self.logMaxHistory = UserDefaults.standard.int(forKey: Self.logMaxHistoryKey, 10000)
    self.documentationFontSize = UserDefaults.standard.str(
      forKey: Self.documentationFontSizeKey, UIDevice.current.userInterfaceIdiom == .pad ?
                                               UserSettings.mediumFontSize :
                                               UserSettings.smallFontSize)
    self.consoleHighlightMatchingParen = UserDefaults.standard.boolean(forKey:
                                                              Self.consoleHighlightMatchingParenKey)
    self.consoleExtendedKeyboard = UserDefaults.standard.boolean(forKey:
                                                                  Self.consoleExtendedKeyboardKey)
    self.consoleAutoIndent = UserDefaults.standard.boolean(forKey: Self.consoleAutoIndentKey)
    self.consoleHighlightSyntax = UserDefaults.standard.boolean(forKey:
                                                                Self.consoleHighlightSyntaxKey)
    self.consoleMarkupIdent = UserDefaults.standard.boolean(forKey: Self.consoleMarkupIdentKey)
    self.editorFontSize = .init(UserDefaults.standard.str(forKey: Self.editorFontSizeKey,
                                                          FontMap.FontSize.compact.string))
    self.indentSize = UserDefaults.standard.int(forKey: Self.indentSizeKey, 2)
    self.showLineNumbers = UserDefaults.standard.boolean(forKey: Self.showLineNumbersKey)
    self.highlightMatchingParen = UserDefaults.standard.boolean(forKey:
                                                                  Self.highlightMatchingParenKey)
    self.highlightCurrentLine = UserDefaults.standard.boolean(forKey: Self.highlightCurrentLineKey,
                                                              false)
    self.extendedKeyboard = UserDefaults.standard.boolean(forKey: Self.extendedKeyboardKey)
    self.maxRecentFiles = UserDefaults.standard.int(forKey: Self.maxRecentFilesKey, 10)
    self.schemeAutoIndent = UserDefaults.standard.boolean(forKey: Self.schemeAutoIndentKey)
    self.schemeHighlightSyntax = UserDefaults.standard.boolean(forKey:
                                                                Self.schemeHighlightSyntaxKey)
    self.schemeMarkupIdent = UserDefaults.standard.boolean(forKey: Self.schemeMarkupIdentKey)
    self.markdownAutoIndent = UserDefaults.standard.boolean(forKey: Self.markdownAutoIndentKey)
    self.markdownHighlightSyntax = UserDefaults.standard.boolean(forKey:
                                                                  Self.markdownHighlightSyntaxKey)
    self.docuIdentColor = UserDefaults.standard.color(forKey: Self.docuIdentColorKey,
                                                      red: 0.2, green: 0.2, blue: 1.0)
    self.parensColor = UserDefaults.standard.color(forKey: Self.parensColorKey,
                                                   red: 0.6, green: 0.35, blue: 0.2)
    self.literalsColor = UserDefaults.standard.color(forKey: Self.literalsColorKey,
                                                     red: 0.0, green: 0.6, blue: 0.0)
    self.commentsColor = UserDefaults.standard.color(forKey: Self.commentsColorKey,
                                                     red: 1.0, green: 0.1, blue: 0.1)
    self.headerColor = UserDefaults.standard.color(forKey: Self.headerColorKey,
                                                   red: 0.0, green: 0.0, blue: 0.9)
    self.subheaderColor = UserDefaults.standard.color(forKey: Self.subheaderColorKey,
                                                      red: 0.2, green: 0.4, blue: 1.0)
    self.emphasisColor = UserDefaults.standard.color(forKey: Self.emphasisColorKey,
                                                     red: 0.0, green: 0.55, blue: 0.0)
    self.bulletsColor = UserDefaults.standard.color(forKey: Self.bulletsColorKey,
                                                    red: 0.8, green: 0.4, blue: 0.8)
    self.blockquoteColor = UserDefaults.standard.color(forKey: Self.blockquoteColorKey,
                                                       red: 0.7, green: 0.3, blue: 0.5)    
    self.codeColor = UserDefaults.standard.color(forKey: Self.codeColorKey, UIColor.gray)
    self.codingFont = UserDefaults.standard.str(forKey: Self.codingFontKey, "System")
  }
}
