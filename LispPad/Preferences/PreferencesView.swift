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
/// `PreferencesView` implements the settings UI of LispPad consisting of four tabs:
/// "Console", "Editor", "Syntax", and "Misc".
/// 
struct PreferencesView: View {
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass
  @EnvironmentObject var settings: UserSettings
  @EnvironmentObject var interpreter: Interpreter
  @Binding var selectedTab: Int
  @State private var modeSelector: Int = 0
  @State private var resetParameters: Bool = false
  @State private var currentSizeClass: UserInterfaceSizeClass = .compact
  
  var body: some View {
    TabView(selection: $selectedTab) {
      Form {
        Section(header: Text("Console")) {
          Picker("Font size", selection: $settings.consoleFontSize) {
            Text("Tiny").tag(FontMap.FontSize.tiny)
            Text("Small").tag(FontMap.FontSize.small)
            Text("Compact").tag(FontMap.FontSize.compact)
            Text("Regular").tag(FontMap.FontSize.regular)
            Text("Medium").tag(FontMap.FontSize.medium)
            Text("Large").tag(FontMap.FontSize.large)
            Text("Huge").tag(FontMap.FontSize.huge)
          }
          .defaultPickerStyle()
          Toggle("Tight spacing", isOn: $settings.consoleTightSpacing)
          Picker("Graphics background", selection: $settings.consoleBackgroundColor) {
            Text("White").tag(UserSettings.whiteBackground)
            Text("Black").tag(UserSettings.blackBackground)
            Text("System").tag(UserSettings.systemBackground)
          }
          .defaultPickerStyle()
          Toggle("Inline graphics", isOn: $settings.consoleInlineGraphics)
          Toggle("Custom formatting", isOn: $settings.consoleCustomFormatting)
          Stepper(value: $settings.maxConsoleHistory, in: 500...5000, step: 100) {
            Text("Console history: ") + Text(" \(settings.maxConsoleHistory)").foregroundColor(.gray)
          }
        }
        Section(header: Text("Input")) {
          Picker("Font size", selection: $settings.inputFontSize) {
            Text("Tiny").tag(FontMap.FontSize.tiny)
            Text("Small").tag(FontMap.FontSize.small)
            Text("Compact").tag(FontMap.FontSize.compact)
            Text("Regular").tag(FontMap.FontSize.regular)
            Text("Medium").tag(FontMap.FontSize.medium)
            Text("Large").tag(FontMap.FontSize.large)
            Text("Huge").tag(FontMap.FontSize.huge)
          }
          .defaultPickerStyle()
          Toggle("Require balanced parenthesis", isOn: $settings.balancedParenthesis)
          Toggle("Highlight matching parenthesis", isOn: $settings.consoleHighlightMatchingParen)
          Toggle("Extended keyboard", isOn: $settings.consoleExtendedKeyboard)
          Toggle("Execute on return", isOn: $settings.consoleExecOnReturn)
          Stepper(value: $settings.maxCommandHistory, in: 5...100, step: 5) {
            Text("Command history: ") + Text(" \(settings.maxCommandHistory)").foregroundColor(.gray)
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
      .environment(\.horizontalSizeClass, self.currentSizeClass)
      Form {
        Section(header: Text("Files")) {
          Toggle("Remember last edited file", isOn: $settings.rememberLastEditedFile)
          Stepper(value: $settings.maxRecentFiles, in: 2...40, step: 1) {
            Text("Recent files: ") + Text(" \(settings.maxRecentFiles)").foregroundColor(.gray)
          }
        }
        Section(header: Text("Text")) {
          Picker("Font size", selection: $settings.editorFontSize) {
            Text("Tiny").tag(FontMap.FontSize.tiny)
            Text("Small").tag(FontMap.FontSize.small)
            Text("Compact").tag(FontMap.FontSize.compact)
            Text("Regular").tag(FontMap.FontSize.regular)
            Text("Medium").tag(FontMap.FontSize.medium)
            Text("Large").tag(FontMap.FontSize.large)
            Text("Huge").tag(FontMap.FontSize.huge)
          }
          .defaultPickerStyle()
          Stepper(value: $settings.indentSize, in: 1...8, step: 1) {
            Text("Indentation size: ") + Text(" \(settings.indentSize)").foregroundColor(.gray)
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
      .environment(\.horizontalSizeClass, self.currentSizeClass)
      VStack {
        Form {
          Picker("", selection: self.$modeSelector) {
            Text("Light Mode").tag(0)
            Text("Dark Mode").tag(1)
          }
          .pickerStyle(.segmented)
          .listRowInsets(.init())
          .listRowBackground(Color.clear)
          if self.modeSelector == 0 {
            Section {
              ColorPicker("Text", selection: bridge($settings.textLightColor), supportsOpacity: false)
            }
            Section(header: Text("Scheme")) {
              ColorPicker("Parenthesis", selection: bridge($settings.parensLightColor), supportsOpacity: false)
              ColorPicker("Literals", selection: bridge($settings.literalsLightColor), supportsOpacity: false)
              ColorPicker("Comments", selection: bridge($settings.commentsLightColor), supportsOpacity: false)
              ColorPicker("Documented identifiers", selection: bridge($settings.docuIdentLightColor), supportsOpacity: false)
            }
            Section(header: Text("Markdown")) {
              ColorPicker("Headers", selection: bridge($settings.headerLightColor), supportsOpacity: false)
              ColorPicker("Subheaders", selection: bridge($settings.subheaderLightColor), supportsOpacity: false)
              ColorPicker("Emphasis", selection: bridge($settings.emphasisLightColor), supportsOpacity: false)
              ColorPicker("Bullets", selection: bridge($settings.bulletsLightColor), supportsOpacity: false)
              ColorPicker("Blockquotes", selection: bridge($settings.blockquoteLightColor), supportsOpacity: false)
              ColorPicker("Code", selection: bridge($settings.codeLightColor), supportsOpacity: false)
            }
          } else {
            Section {
              ColorPicker("Text", selection: bridge($settings.textDarkColor), supportsOpacity: false)
            }
            Section(header: Text("Scheme")) {
              ColorPicker("Parenthesis", selection: bridge($settings.parensDarkColor), supportsOpacity: false)
              ColorPicker("Literals", selection: bridge($settings.literalsDarkColor), supportsOpacity: false)
              ColorPicker("Comments", selection: bridge($settings.commentsDarkColor), supportsOpacity: false)
              ColorPicker("Documented identifiers", selection: bridge($settings.docuIdentDarkColor), supportsOpacity: false)
            }
            Section(header: Text("Markdown")) {
              ColorPicker("Headers", selection: bridge($settings.headerDarkColor), supportsOpacity: false)
              ColorPicker("Subheaders", selection: bridge($settings.subheaderDarkColor), supportsOpacity: false)
              ColorPicker("Emphasis", selection: bridge($settings.emphasisDarkColor), supportsOpacity: false)
              ColorPicker("Bullets", selection: bridge($settings.bulletsDarkColor), supportsOpacity: false)
              ColorPicker("Blockquotes", selection: bridge($settings.blockquoteDarkColor), supportsOpacity: false)
              ColorPicker("Code", selection: bridge($settings.codeDarkColor), supportsOpacity: false)
            }
          }
        }
      }
      .tabItem {
        Label("Syntax", systemImage: "paintpalette")
      }
      .tag(2)
      .environment(\.horizontalSizeClass, self.currentSizeClass)
      Form {
        Section(header: Text("Interpreter")) {
          HStack {
            Text("Max stack size [K entries]: ")
            Spacer()
            IntField(value: $settings.maxStackSize, min: 10, max: 1000000)
            .frame(maxWidth: 110)
          }
          HStack {
            Text("Traced procedure calls: ")
            Spacer()
            IntField(value: $settings.maxCallTrace, min: 0, max: 1000)
            .frame(maxWidth: 110)
          }
          HStack {
            Spacer()
            Button("Reset parameters") {
              settings.maxStackSize = 10000
              settings.maxCallTrace = 20
            }
          }
        }
        Section(header: Text("Log")) {
          Toggle("Commands and results", isOn: $settings.logCommands)
          Toggle("Garbage collection", isOn: $settings.logGarbageCollection)
          Stepper(value: $settings.logMaxHistory, in: 500...50000, step: 500) {
            Text("Log history: ") + Text(" \(settings.logMaxHistory)").foregroundColor(.gray)
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
        Section(header: Text("Application Experience")) {
          Picker("Appearance", selection: $settings.appearance) {
            Text("System").tag(Appearance.system)
            Text("Light").tag(Appearance.light)
            Text("Dark").tag(Appearance.dark)
          }
          .defaultPickerStyle()
          Toggle("Disable extended hardware keyboard", isOn: $settings.disableExtendedKeyboard)
        }
        Section(header: Text("Fonts")) {
          Picker("Code font", selection: $settings.codingFont) {
            ForEach(UserSettings.monospacedFontMap.fonts.keys.sorted(by: >),
                    id: \.self,
                    content: { key in
              Text(key).tag(key)
            })
          }
          .defaultPickerStyle()
          Picker("Documentation font size", selection: $settings.documentationFontSize) {
            Text("Small").tag(UserSettings.smallFontSize)
            Text("Medium").tag(UserSettings.mediumFontSize)
            Text("Large").tag(UserSettings.largeFontSize)
          }
          .defaultPickerStyle()
        }
      }
      .tabItem {
        Label("Misc", systemImage: "switch.2")
      }
      .tag(3)
      .onDisappear {
        SessionLog.standard.setMaxLogEntries(self.settings.logMaxHistory)
        self.interpreter.context?.evaluator.maxCallStack = self.settings.maxCallTrace
        _ = self.interpreter.context?.evaluator.evalMachine.setStackLimit(to:
                                                                self.settings.maxStackSize * 1000)
      }
      .environment(\.horizontalSizeClass, self.currentSizeClass)
    }
    .tabViewStyle(.automatic)
    .navigationBarTitleDisplayMode(.inline)
    .navigationTitle("Settings")
    .transformEnvironment(\.horizontalSizeClass, transform: { sizeClass in
      let current = sizeClass
      DispatchQueue.main.async {
        self.currentSizeClass = current ?? .compact
      }
      sizeClass = .compact
    })
  }
  
  private func bridge(_ binding: Binding<UIColor>) -> Binding<Color> {
    return Binding(
      get: { Color(binding.wrappedValue) },
      set: { binding.wrappedValue = UIColor($0) }
    )
  }
}

extension Picker {
  @ViewBuilder func defaultPickerStyle() -> some View {
    if #available(iOS 16.0, *) {
      self.pickerStyle(.menu)
    } else {
      self
    }
  }
}
