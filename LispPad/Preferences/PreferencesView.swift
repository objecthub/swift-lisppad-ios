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
            Text("Tiny").tag(UserSettings.tinyFontSize)
            Text("Small").tag(UserSettings.smallFontSize)
            Text("Medium").tag(UserSettings.mediumFontSize)
            Text("Large").tag(UserSettings.largeFontSize)
            Text("X-Large").tag(UserSettings.xlargeFontSize)
          }
          Stepper(value: $settings.maxConsoleHistory, in: 500...5000, step: 100) {
            Text("Console history:")
            Spacer(minLength: 16)
            Text("\(settings.maxConsoleHistory)").foregroundColor(.gray)
          }
        }
        Section(header: Text("Input")) {
          Picker(selection: $settings.inputFontSize, label: Text("Font size")) {
            Text("Tiny").tag(UserSettings.tinyFontSize)
            Text("Small").tag(UserSettings.smallFontSize)
            Text("Medium").tag(UserSettings.mediumFontSize)
            Text("Large").tag(UserSettings.largeFontSize)
            Text("X-Large").tag(UserSettings.xlargeFontSize)
          }
          Stepper(value: $settings.maxCommandHistory, in: 5...100, step: 5) {
            Text("Command history:")
            Spacer(minLength: 16)
            Text("\(settings.maxCommandHistory)").foregroundColor(.gray)
          }
          Toggle("Require balanced parenthesis", isOn: $settings.balancedParenthesis)
        }
      }
      .tabItem {
        Label("Console", systemImage: "terminal")
      }
      .tag(0)
      Form {
        Section(header: Text("Files")) {
          Stepper(value: $settings.maxRecentFiles, in: 2...40, step: 1) {
            Text("Recent files:")
            Spacer(minLength: 16)
            Text("\(settings.maxRecentFiles)").foregroundColor(.gray)
          }
        }
        Section(header: Text("Text")) {
          Picker(selection: $settings.editorFontSize, label: Text("Font size")) {
            Text("Tiny").tag(UserSettings.tinyFontSize)
            Text("Small").tag(UserSettings.smallFontSize)
            Text("Medium").tag(UserSettings.mediumFontSize)
            Text("Large").tag(UserSettings.largeFontSize)
            Text("X-Large").tag(UserSettings.xlargeFontSize)
          }
          Stepper(value: $settings.indentSize, in: 1...8, step: 1) {
            Text("Indentation size:")
            Spacer(minLength: 16)
            Text("\(settings.indentSize)").foregroundColor(.gray)
          }
        }
        Section(header: Text("Interface")) {
          Toggle("Show line numbers", isOn: $settings.showLineNumbers)
          Toggle("Highlight matching parenthesis", isOn: $settings.highlightMatchingParen)
        }
        Section(header: Text("Scheme")) {
          Toggle("Indent automatically", isOn: $settings.schemeAutoIndent)
          Toggle("Highlight syntax", isOn: $settings.schemeHighlightSyntax)
          Toggle("Markup known identifiers", isOn: $settings.schemeMarkupIdent)
        }
        Section(header: Text("Markdown")) {
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
          ColorPicker("Identifiers with documentation", selection: $settings.docuIdentColor,
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
        Label("Syntax", systemImage: "scroll")
      }
      .tag(2)
    }
    .navigationTitle("Preferences")
  }
}
