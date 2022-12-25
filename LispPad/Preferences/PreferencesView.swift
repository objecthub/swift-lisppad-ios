//
//  PreferencesView.swift
//  LispPad
//
//  Created by Matthias Zenger on 06/04/2021.
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

import SwiftUI

///
/// `PreferencesView` implements the preferences UI of LispPad consisting of three tabs:
/// "Console", "Editor", and "Syntax".
/// 
struct PreferencesView: View {
  @EnvironmentObject var settings: UserSettings
  @Binding var selectedTab: Int
  
  var body: some View {
    TabView(selection: $selectedTab) {
      Form {
        Section(header: Text("Console")) {
          Picker(selection: $settings.consoleFontSize, label: Text("Font size")) {
            Text("Tiny").tag(FontMap.FontSize.tiny)
            Text("Small").tag(FontMap.FontSize.small)
            Text("Compact").tag(FontMap.FontSize.compact)
            Text("Regular").tag(FontMap.FontSize.regular)
            Text("Medium").tag(FontMap.FontSize.medium)
            Text("Large").tag(FontMap.FontSize.large)
            Text("Huge").tag(FontMap.FontSize.huge)
          }
          Toggle("Tight spacing", isOn: $settings.consoleTightSpacing)
          Picker(selection: $settings.consoleBackgroundColor, label: Text("Graphics background")) {
            Text("White").tag(UserSettings.whiteBackground)
            Text("Black").tag(UserSettings.blackBackground)
            Text("System").tag(UserSettings.systemBackground)
          }
          Stepper(value: $settings.maxConsoleHistory, in: 500...5000, step: 100) {
            HStack(alignment: .center, spacing: 16.0) {
              Text("Console history:")
              Text("\(settings.maxConsoleHistory)").foregroundColor(.gray)
            }
          }
        }
        Section(header: Text("Input")) {
          Picker(selection: $settings.inputFontSize, label: Text("Font size")) {
            Text("Tiny").tag(FontMap.FontSize.tiny)
            Text("Small").tag(FontMap.FontSize.small)
            Text("Compact").tag(FontMap.FontSize.compact)
            Text("Regular").tag(FontMap.FontSize.regular)
            Text("Medium").tag(FontMap.FontSize.medium)
            Text("Large").tag(FontMap.FontSize.large)
            Text("Huge").tag(FontMap.FontSize.huge)
          }
          Toggle("Require balanced parenthesis", isOn: $settings.balancedParenthesis)
          Toggle("Highlight matching parenthesis", isOn: $settings.consoleHighlightMatchingParen)
          Toggle("Extended keyboard", isOn: $settings.consoleExtendedKeyboard)
          Stepper(value: $settings.maxCommandHistory, in: 5...100, step: 5) {
            HStack(alignment: .center, spacing: 16.0) {
              Text("Command history:")
              Text("\(settings.maxCommandHistory)").foregroundColor(.gray)
            }
          }
        }
        Section(header: Text("Scheme Mode")) {
          Toggle("Indent automatically", isOn: $settings.consoleAutoIndent)
          Toggle("Highlight syntax", isOn: $settings.consoleHighlightSyntax)
          Toggle("Markup known identifiers", isOn: $settings.consoleMarkupIdent)
        }
      }
      .tabItem {
        Label("Console", systemImage: "terminal")
      }
      .tag(0)
      Form {
        Section(header: Text("Files")) {
          Stepper(value: $settings.maxRecentFiles, in: 2...40, step: 1) {
            HStack(alignment: .center, spacing: 16.0) {
              Text("Recent files:")
              Text("\(settings.maxRecentFiles)").foregroundColor(.gray)
            }
          }
        }
        Section(header: Text("Text")) {
          Picker(selection: $settings.editorFontSize, label: Text("Font size")) {
            Text("Tiny").tag(FontMap.FontSize.tiny)
            Text("Small").tag(FontMap.FontSize.small)
            Text("Compact").tag(FontMap.FontSize.compact)
            Text("Regular").tag(FontMap.FontSize.regular)
            Text("Medium").tag(FontMap.FontSize.medium)
            Text("Large").tag(FontMap.FontSize.large)
            Text("Huge").tag(FontMap.FontSize.huge)
          }
          Stepper(value: $settings.indentSize, in: 1...8, step: 1) {
            HStack(alignment: .center, spacing: 16.0) {
              Text("Indentation size:")
              Text("\(settings.indentSize)").foregroundColor(.gray)
            }
          }
        }
        Section(header: Text("Interface")) {
          Toggle("Show line numbers", isOn: $settings.showLineNumbers)
          Toggle("Highlight current line", isOn: $settings.highlightCurrentLine)
          Toggle("Highlight matching parenthesis", isOn: $settings.highlightMatchingParen)
          Toggle("Extended keyboard", isOn: $settings.extendedKeyboard)
        }
        Section(header: Text("Scheme Mode")) {
          Toggle("Indent automatically", isOn: $settings.schemeAutoIndent)
          Toggle("Highlight syntax", isOn: $settings.schemeHighlightSyntax)
          Toggle("Markup known identifiers", isOn: $settings.schemeMarkupIdent)
        }
        Section(header: Text("Markdown Mode")) {
          Toggle("Indent automatically", isOn: $settings.markdownAutoIndent)
          Toggle("Highlight syntax", isOn: $settings.markdownHighlightSyntax)
        }
      }
      .tabItem { 
        Label("Editor", systemImage: "square.and.pencil")
      }
      .tag(1)
      Form {
        Section(header: Text("Scheme")) {
          ColorPicker("Parenthesis", selection: $settings.parensColor, supportsOpacity: false)
          ColorPicker("Literals", selection: $settings.literalsColor, supportsOpacity: false)
          ColorPicker("Comments", selection: $settings.commentsColor, supportsOpacity: false)
          ColorPicker("Documented identifiers", selection: $settings.docuIdentColor,
                      supportsOpacity: false)
        }
        Section(header: Text("Markdown")) {
          ColorPicker("Headers", selection: $settings.headerColor, supportsOpacity: false)
          ColorPicker("Subheaders", selection: $settings.subheaderColor, supportsOpacity: false)
          ColorPicker("Emphasis", selection: $settings.emphasisColor, supportsOpacity: false)
          ColorPicker("Bullets", selection: $settings.bulletsColor, supportsOpacity: false)
          ColorPicker("Blockquotes", selection: $settings.blockquoteColor, supportsOpacity: false)
          ColorPicker("Code", selection: $settings.codeColor, supportsOpacity: false)
        }
      }
      .tabItem {
        Label("Syntax", systemImage: "paintpalette")
      }
      .tag(2)
      Form {
        Section(header: Text("Log")) {
          Toggle("Commands and results", isOn: $settings.logCommands)
          Toggle("Garbage collection", isOn: $settings.logGarbageCollection)
          Stepper(value: $settings.logMaxHistory, in: 500...50000, step: 500) {
            HStack(alignment: .center, spacing: 16.0) {
              Text("Log history:")
              Text("\(settings.logMaxHistory)").foregroundColor(.gray)
            }
          }
        }
        Section(header: Text("Install Folders")) {
          Toggle("iCloud Drive", isOn: $settings.foldersOnICloud)
          switch UIDevice.current.userInterfaceIdiom {
            case .phone:
              Toggle("On My iPhone", isOn: $settings.foldersOnDevice)
            case .pad:
              Toggle("On My iPad", isOn: $settings.foldersOnDevice)
            default:
              Toggle("On My Device", isOn: $settings.foldersOnDevice)
          }
        }
        Section(header: Text("Fonts")) {
          Picker(selection: $settings.codingFont,
                 label: Text("Code font")) {
            ForEach(UserSettings.monospacedFontMap.fonts.keys.sorted(by: >),
                    id: \.self,
                    content: { key in
              Text(key).tag(key)
            })
          }
          Picker(selection: $settings.documentationFontSize,
                 label: Text("Documentation font size")) {
            Text("Small").tag(UserSettings.smallFontSize)
            Text("Medium").tag(UserSettings.mediumFontSize)
            Text("Large").tag(UserSettings.largeFontSize)
          }
        }
      }
      .tabItem {
        Label("Misc", systemImage: "switch.2")
      }
      .tag(3)
      .onDisappear {
        SessionLog.standard.setMaxLogEntries(self.settings.logMaxHistory)
      }
    }
    .navigationBarTitleDisplayMode(.inline)
    .navigationTitle("Preferences")
  }
}
