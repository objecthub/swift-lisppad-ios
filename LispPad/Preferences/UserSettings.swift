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
  private static let consoleInlineGraphics = "Console.inlineGraphics"
  private static let consoleCustomFormatting = "Console.customFormatting"
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
  private static let rememberLastEditedFileKey = "Editor.rememberLastEditedFile"  
  private static let maxRecentFilesKey = "Editor.maxRecentFiles"
  private static let schemeAutoIndentKey = "Editor.schemeAutoIndent"
  private static let schemeHighlightSyntaxKey = "Editor.schemeHighlightSyntax"
  private static let schemeMarkupIdentKey = "Editor.schemeMarkupIdent"
  private static let markdownAutoIndentKey = "Editor.markdownAutoIndent"
  private static let markdownHighlightSyntaxKey = "Editor.markdownHighlightSyntax"
  private static let textColorKey = "Editor.textColor"
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
  private static let textDarkColorKey = "Editor.textDarkColor"
  private static let docuIdentDarkColorKey = "Editor.docuIdentDarkColor"
  private static let parensDarkColorKey = "Editor.parensDarkColor"
  private static let literalsDarkColorKey = "Editor.literalsDarkColor"
  private static let commentsDarkColorKey = "Editor.commentsDarkColor"
  private static let headerDarkColorKey = "Editor.headerDarkColor"
  private static let subheaderDarkColorKey = "Editor.subheaderDarkColor"
  private static let emphasisDarkColorKey = "Editor.emphasisDarkColor"
  private static let bulletsDarkColorKey = "Editor.bulletsDarkColor"
  private static let blockquoteDarkColorKey = "Editor.blockquoteDarkColor"
  private static let codeDarkColorKey = "Editor.codeDarkColor"
  private static let codingFontKey = "General.codingFont"
  private static let disableExtendedKeyboardKey = "Keyboard.disableExtendedKeyboard"
  private static let maxStackSizeKey = "Interpreter.maxStackSize"
  private static let maxCallTraceKey = "Interpreter.maxCallTrace"
  private static let appearanceKey = "General.appearance"
  
  // Documentation font sizes
  static let smallFontSize = "Small"
  static let mediumFontSize = "Medium"
  static let largeFontSize = "Large"
  
  // Available monospaced fonts
  static let monospacedFontMap = FontMap(("Courier", "CourierNewPSMT"),
                                         ("Menlo", "Menlo-Regular"),
                                         ("Source Code Pro", "SourceCodePro-Regular"),
                                         ("Roboto Mono", "RobotoMono-Regular"),
                                         ("Fira Code", "FiraCode-Regular"),
                                         ("JetBrains Mono", "JetBrainsMono-Regular"),
                                         ("JetBrains Mono Light", "JetBrainsMono-Light"),
                                         ("Iosevka", "Iosevka"),
                                         ("Iosevka Extended", "Iosevka-Extended"),
                                         ("Inconsolata", "Inconsolata-Regular"))
  
  // Graphics background
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
  
  @Published var consoleInlineGraphics: Bool {
    didSet {
      UserDefaults.standard.set(self.consoleInlineGraphics, forKey: Self.consoleInlineGraphics)
    }
  }
  
  @Published var consoleCustomFormatting: Bool {
    didSet {
      UserDefaults.standard.set(self.consoleCustomFormatting, forKey: Self.consoleCustomFormatting)
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
  
  @Published var rememberLastEditedFile: Bool {
    didSet {
      UserDefaults.standard.set(self.rememberLastEditedFile, forKey: Self.rememberLastEditedFileKey)
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
  
  @Published var textLightColor: UIColor {
    didSet {
      self.syntaxHighlightingUpdate = .now
      UserDefaults.standard.set(self.textLightColor, forKey: Self.textColorKey)
    }
  }
  
  @Published var docuIdentLightColor: UIColor {
    didSet {
      self.syntaxHighlightingUpdate = Date()
      UserDefaults.standard.set(self.docuIdentLightColor, forKey: Self.docuIdentColorKey)
    }
  }
  
  @Published var parensLightColor: UIColor {
    didSet {
      self.syntaxHighlightingUpdate = Date()
      UserDefaults.standard.set(self.parensLightColor, forKey: Self.parensColorKey)
    }
  }
  
  @Published var literalsLightColor: UIColor {
    didSet {
      self.syntaxHighlightingUpdate = Date()
      UserDefaults.standard.set(self.literalsLightColor, forKey: Self.literalsColorKey)
    }
  }
  
  @Published var commentsLightColor: UIColor {
    didSet {
      self.syntaxHighlightingUpdate = Date()
      UserDefaults.standard.set(self.commentsLightColor, forKey: Self.commentsColorKey)
    }
  }
  
  @Published var headerLightColor: UIColor {
    didSet {
      self.syntaxHighlightingUpdate = Date()
      UserDefaults.standard.set(self.headerLightColor, forKey: Self.headerColorKey)
    }
  }
  
  @Published var subheaderLightColor: UIColor {
    didSet {
      self.syntaxHighlightingUpdate = Date()
      UserDefaults.standard.set(self.subheaderLightColor, forKey: Self.subheaderColorKey)
    }
  }
  
  @Published var emphasisLightColor: UIColor {
    didSet {
      self.syntaxHighlightingUpdate = Date()
      UserDefaults.standard.set(self.emphasisLightColor, forKey: Self.emphasisColorKey)
    }
  }
  
  @Published var bulletsLightColor: UIColor {
    didSet {
      self.syntaxHighlightingUpdate = Date()
      UserDefaults.standard.set(self.bulletsLightColor, forKey: Self.bulletsColorKey)
    }
  }
  
  @Published var blockquoteLightColor: UIColor {
    didSet {
      self.syntaxHighlightingUpdate = Date()
      UserDefaults.standard.set(self.blockquoteLightColor, forKey: Self.blockquoteColorKey)
    }
  }
  
  @Published var codeLightColor: UIColor {
    didSet {
      self.syntaxHighlightingUpdate = Date()
      UserDefaults.standard.set(self.codeLightColor, forKey: Self.codeColorKey)
    }
  }
  
  @Published var textDarkColor: UIColor {
    didSet {
      self.syntaxHighlightingUpdate = .now
      UserDefaults.standard.set(self.textDarkColor, forKey: Self.textDarkColorKey)
    }
  }
  
  @Published var docuIdentDarkColor: UIColor {
    didSet {
      self.syntaxHighlightingUpdate = Date()
      UserDefaults.standard.set(self.docuIdentDarkColor, forKey: Self.docuIdentDarkColorKey)
    }
  }
  
  @Published var parensDarkColor: UIColor {
    didSet {
      self.syntaxHighlightingUpdate = Date()
      UserDefaults.standard.set(self.parensDarkColor, forKey: Self.parensDarkColorKey)
    }
  }
  
  @Published var literalsDarkColor: UIColor {
    didSet {
      self.syntaxHighlightingUpdate = Date()
      UserDefaults.standard.set(self.literalsDarkColor, forKey: Self.literalsDarkColorKey)
    }
  }
  
  @Published var commentsDarkColor: UIColor {
    didSet {
      self.syntaxHighlightingUpdate = Date()
      UserDefaults.standard.set(self.commentsDarkColor, forKey: Self.commentsDarkColorKey)
    }
  }
  
  @Published var headerDarkColor: UIColor {
    didSet {
      self.syntaxHighlightingUpdate = Date()
      UserDefaults.standard.set(self.headerDarkColor, forKey: Self.headerDarkColorKey)
    }
  }
  
  @Published var subheaderDarkColor: UIColor {
    didSet {
      self.syntaxHighlightingUpdate = Date()
      UserDefaults.standard.set(self.subheaderDarkColor, forKey: Self.subheaderDarkColorKey)
    }
  }
  
  @Published var emphasisDarkColor: UIColor {
    didSet {
      self.syntaxHighlightingUpdate = Date()
      UserDefaults.standard.set(self.emphasisDarkColor, forKey: Self.emphasisDarkColorKey)
    }
  }
  
  @Published var bulletsDarkColor: UIColor {
    didSet {
      self.syntaxHighlightingUpdate = Date()
      UserDefaults.standard.set(self.bulletsDarkColor, forKey: Self.bulletsDarkColorKey)
    }
  }
  
  @Published var blockquoteDarkColor: UIColor {
    didSet {
      self.syntaxHighlightingUpdate = Date()
      UserDefaults.standard.set(self.blockquoteDarkColor, forKey: Self.blockquoteDarkColorKey)
    }
  }
  
  @Published var codeDarkColor: UIColor {
    didSet {
      self.syntaxHighlightingUpdate = Date()
      UserDefaults.standard.set(self.codeDarkColor, forKey: Self.codeDarkColorKey)
    }
  }
  
  @Published var codingFont: String {
    didSet {
      UserDefaults.standard.set(self.codingFont, forKey: Self.codingFontKey)
    }
  }
  
  @Published var disableExtendedKeyboard: Bool {
    didSet {
      UserDefaults.standard.set(self.disableExtendedKeyboard,
                                forKey: Self.disableExtendedKeyboardKey)
    }
  }
  
  @Published var maxStackSize: Int {
    didSet {
      UserDefaults.standard.set(self.maxStackSize, forKey: Self.maxStackSizeKey)
    }
  }
  
  @Published var maxCallTrace: Int {
    didSet {
      UserDefaults.standard.set(self.maxCallTrace, forKey: Self.maxCallTraceKey)
    }
  }
  
  @Published var appearance: Appearance {
    didSet {
      UserDefaults.standard.set(self.appearance.rawValue, forKey: Self.appearanceKey)
    }
  }
  
  var consoleGraphicsBackgroundColor: Color {
    return Self.backgroundColorMap[self.consoleBackgroundColor] ?? .clear
  }
  
  var consoleFont: Font {
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
  
  // UIColor objects changing their value dynamically based on mode (dark vs. light)
  
  private(set) var textColor: UIColor = .black
  private(set) var docuIdentColor: UIColor = .black
  private(set) var parensColor: UIColor = .black
  private(set) var literalsColor: UIColor = .black
  private(set) var commentsColor: UIColor = .black
  private(set) var headerColor: UIColor = .black
  private(set) var subheaderColor: UIColor = .black
  private(set) var emphasisColor: UIColor = .black
  private(set) var bulletsColor: UIColor = .black
  private(set) var blockquoteColor: UIColor = .black
  private(set) var codeColor: UIColor = .black
  
  var syntaxHighlightingUpdate: Date = .now
  
  private init() {
    self.foldersOnICloud = UserDefaults.standard.boolean(forKey: Self.foldersOnICloudKey)
    self.foldersOnDevice = UserDefaults.standard.boolean(forKey: Self.foldersOnDeviceKey)
    self.consoleFontSize = .init(UserDefaults.standard.str(forKey: Self.consoleFontSizeKey,
                                                           FontMap.FontSize.compact.string))
    self.consoleTightSpacing = UserDefaults.standard.boolean(forKey: Self.consoleTightSpacingKey,
                                                             false)
    self.consoleBackgroundColor = UserDefaults.standard.str(
      forKey: Self.consoleBackgroundColorKey, UserSettings.whiteBackground)
    self.consoleInlineGraphics = UserDefaults.standard.boolean(forKey: Self.consoleInlineGraphics,
                                                               true)
    self.consoleCustomFormatting = UserDefaults.standard.boolean(forKey: Self.consoleCustomFormatting,
                                                                 true)
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
    self.rememberLastEditedFile = UserDefaults.standard.boolean(forKey:
                                                                  Self.rememberLastEditedFileKey)
    self.maxRecentFiles = UserDefaults.standard.int(forKey: Self.maxRecentFilesKey, 10)
    self.schemeAutoIndent = UserDefaults.standard.boolean(forKey: Self.schemeAutoIndentKey)
    self.schemeHighlightSyntax = UserDefaults.standard.boolean(forKey:
                                                                Self.schemeHighlightSyntaxKey)
    self.schemeMarkupIdent = UserDefaults.standard.boolean(forKey: Self.schemeMarkupIdentKey)
    self.markdownAutoIndent = UserDefaults.standard.boolean(forKey: Self.markdownAutoIndentKey)
    self.markdownHighlightSyntax = UserDefaults.standard.boolean(forKey:
                                                                  Self.markdownHighlightSyntaxKey)
    self.textLightColor = UserDefaults.standard.color(forKey: Self.textColorKey,
                                                 red: 0.0, green: 0.0, blue: 0.0)
    self.docuIdentLightColor = UserDefaults.standard.color(forKey: Self.docuIdentColorKey,
                                                      red: 0.2, green: 0.2, blue: 1.0)
    self.parensLightColor = UserDefaults.standard.color(forKey: Self.parensColorKey,
                                                   red: 0.6, green: 0.35, blue: 0.2)
    self.literalsLightColor = UserDefaults.standard.color(forKey: Self.literalsColorKey,
                                                     red: 0.0, green: 0.6, blue: 0.0)
    self.commentsLightColor = UserDefaults.standard.color(forKey: Self.commentsColorKey,
                                                     red: 1.0, green: 0.1, blue: 0.1)
    self.headerLightColor = UserDefaults.standard.color(forKey: Self.headerColorKey,
                                                   red: 0.0, green: 0.0, blue: 0.9)
    self.subheaderLightColor = UserDefaults.standard.color(forKey: Self.subheaderColorKey,
                                                      red: 0.2, green: 0.4, blue: 1.0)
    self.emphasisLightColor = UserDefaults.standard.color(forKey: Self.emphasisColorKey,
                                                     red: 0.0, green: 0.55, blue: 0.0)
    self.bulletsLightColor = UserDefaults.standard.color(forKey: Self.bulletsColorKey,
                                                    red: 0.8, green: 0.4, blue: 0.8)
    self.blockquoteLightColor = UserDefaults.standard.color(forKey: Self.blockquoteColorKey,
                                                       red: 0.7, green: 0.3, blue: 0.5)
    self.codeLightColor = UserDefaults.standard.color(forKey: Self.codeColorKey, UIColor.gray)
    self.textDarkColor = UserDefaults.standard.color(forKey: Self.textDarkColorKey,
                                                     alternateKey: Self.textColorKey,
                                                     red: 1.0, green: 1.0, blue: 1.0)
    self.docuIdentDarkColor = UserDefaults.standard.color(forKey: Self.docuIdentDarkColorKey,
                                                          alternateKey: Self.docuIdentColorKey,
                                                          red: 0.2, green: 0.2, blue: 1.0)
    self.parensDarkColor = UserDefaults.standard.color(forKey: Self.parensDarkColorKey,
                                                       alternateKey: Self.parensColorKey,
                                                       red: 0.6, green: 0.35, blue: 0.2)
    self.literalsDarkColor = UserDefaults.standard.color(forKey: Self.literalsDarkColorKey,
                                                         alternateKey: Self.literalsColorKey,
                                                         red: 0.0, green: 0.6, blue: 0.0)
    self.commentsDarkColor = UserDefaults.standard.color(forKey: Self.commentsDarkColorKey,
                                                         alternateKey: Self.commentsColorKey,
                                                         red: 1.0, green: 0.1, blue: 0.1)
    self.headerDarkColor = UserDefaults.standard.color(forKey: Self.headerDarkColorKey,
                                                       alternateKey: Self.headerColorKey,
                                                       red: 0.0, green: 0.0, blue: 0.9)
    self.subheaderDarkColor = UserDefaults.standard.color(forKey: Self.subheaderDarkColorKey,
                                                          alternateKey: Self.subheaderColorKey,
                                                          red: 0.2, green: 0.4, blue: 1.0)
    self.emphasisDarkColor = UserDefaults.standard.color(forKey: Self.emphasisDarkColorKey,
                                                         alternateKey: Self.emphasisColorKey,
                                                         red: 0.0, green: 0.55, blue: 0.0)
    self.bulletsDarkColor = UserDefaults.standard.color(forKey: Self.bulletsDarkColorKey,
                                                        alternateKey: Self.bulletsColorKey,
                                                        red: 0.8, green: 0.4, blue: 0.8)
    self.blockquoteDarkColor = UserDefaults.standard.color(forKey: Self.blockquoteDarkColorKey,
                                                           alternateKey: Self.blockquoteColorKey,
                                                           red: 0.7, green: 0.3, blue: 0.5)
    self.codeDarkColor = UserDefaults.standard.color(forKey: Self.codeDarkColorKey,
                                                     alternateKey: Self.codeColorKey,
                                                     UIColor.gray)
    self.codingFont = UserDefaults.standard.str(forKey: Self.codingFontKey, "System")
    self.disableExtendedKeyboard = UserDefaults.standard.boolean(forKey:
                                                                 Self.disableExtendedKeyboardKey)
    self.maxStackSize = UserDefaults.standard.int(forKey: Self.maxStackSizeKey, 10000)
    self.maxCallTrace = UserDefaults.standard.int(forKey: Self.maxCallTraceKey, 20)
    self.appearance = Appearance(value: UserDefaults.standard.int(forKey: Self.appearanceKey, 0))
    self.textColor = UIColor { [unowned self] traits in
      return traits.userInterfaceStyle == .dark ? self.textDarkColor : self.textLightColor
    }
    self.docuIdentColor = UIColor { [unowned self] traits in
      return traits.userInterfaceStyle == .dark ? self.docuIdentDarkColor : self.docuIdentLightColor
    }
    self.parensColor = UIColor { [unowned self] traits in
      return traits.userInterfaceStyle == .dark ? self.parensDarkColor : self.parensLightColor
    }
    self.literalsColor = UIColor { [unowned self] traits in
      return traits.userInterfaceStyle == .dark ? self.literalsDarkColor : self.literalsLightColor
    }
    self.commentsColor = UIColor { [unowned self] traits in
      return traits.userInterfaceStyle == .dark ? self.commentsDarkColor : self.commentsLightColor
    }
    self.headerColor = UIColor { [unowned self] traits in
      return traits.userInterfaceStyle == .dark ? self.headerDarkColor : self.headerLightColor
    }
    self.subheaderColor = UIColor { [unowned self] traits in
      return traits.userInterfaceStyle == .dark ? self.subheaderDarkColor : self.subheaderLightColor
    }
    self.emphasisColor = UIColor { [unowned self] traits in
      return traits.userInterfaceStyle == .dark ? self.emphasisDarkColor : self.emphasisLightColor
    }
    self.bulletsColor = UIColor { [unowned self] traits in
      return traits.userInterfaceStyle == .dark ? self.bulletsDarkColor : self.bulletsLightColor
    }
    self.blockquoteColor = UIColor { [unowned self] traits in
      return traits.userInterfaceStyle == .dark ? self.blockquoteDarkColor : self.blockquoteLightColor
    }
    self.codeColor = UIColor { [unowned self] traits in
      return traits.userInterfaceStyle == .dark ? self.codeDarkColor : self.codeLightColor
    }
  }
}
