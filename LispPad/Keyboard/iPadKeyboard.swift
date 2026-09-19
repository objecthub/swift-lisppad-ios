//
//  iPadKeyboard.swift
//  LispPad
//
//  Created by Matthias Zenger on 19/06/2021.
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
import UIKit

/// `CodeEditorKeyboard` implementation for iPad, rendering keys as a movable
/// `UIBarButtonItemGroup` attached to the text view's input assistant item.
final class iPadKeyboard: CodeEditorKeyboard {

  let console: Bool
  var editorType: FileExtensions.EditorType

  /// Tracks whether cursor navigation keys are currently visible
  private var showingCursorKeys: Bool = false

  init(console: Bool, editorType: FileExtensions.EditorType) {
    self.console = console
    self.editorType = editorType
  }

  func setup(for textView: CodeEditorTextView) {
    if self.shouldUseExtendedKeyboard {
      let currentEditorType = self.currentEditorType(for: textView)
      if textView.inputAssistantItem.trailingBarButtonGroups.isEmpty ||
         textView.inputAssistantItem.trailingBarButtonGroups.last!.barButtonItems.count < 7 {
        self.editorType = currentEditorType
        textView.inputAssistantItem.trailingBarButtonGroups.append(self.barButtonGroup(for: textView))
      } else if currentEditorType != self.editorType {
        self.editorType = currentEditorType
        if let last = textView.inputAssistantItem.trailingBarButtonGroups.last,
           last.barButtonItems.count >= 7 {
          textView.inputAssistantItem.trailingBarButtonGroups.removeLast()
        }
        textView.inputAssistantItem.trailingBarButtonGroups.append(self.barButtonGroup(for: textView))
        textView.reloadInputViews()
      }
    } else if let last = textView.inputAssistantItem.trailingBarButtonGroups.last,
              last.barButtonItems.count >= 7 {
      textView.inputAssistantItem.trailingBarButtonGroups.removeLast()
      textView.reloadInputViews()
    }
  }

  func toggleKeyboard(for textView: CodeEditorTextView) {
    self.showingCursorKeys.toggle()
    if let last = textView.inputAssistantItem.trailingBarButtonGroups.last,
       last.barButtonItems.count >= 7 {
      let numGroups = textView.inputAssistantItem.trailingBarButtonGroups.count
      textView.inputAssistantItem.trailingBarButtonGroups[numGroups - 1] =
        self.barButtonGroup(for: textView)
      textView.reloadInputViews()
    }
  }

  private func barButtonGroup(for textView: CodeEditorTextView) -> UIBarButtonItemGroup {
    if self.editorType == .scheme {
      if self.showingCursorKeys {
        let indent = self.ipadIconButton("increase.indent", tag: .indent, to: textView)
        let undent = self.ipadIconButton("decrease.indent", tag: .undent, to: textView)
        let comment = self.ipadIconButton("text.bubble", tag: .comment, to: textView)
        let uncomment = self.ipadIconButton("bubble.left", tag: .uncomment, to: textView)
        let cursorLeft = self.ipadButton("←", tag: .cursorLeft, to: textView)
        let cursorRight = self.ipadButton("→", tag: .cursorRight, to: textView)
        let cursorUp = self.ipadButton("↑", tag: .cursorUp, to: textView)
        let cursorDown = self.ipadButton("↓", tag: .cursorDown, to: textView)
        let cursorNav = self.ipadIconButton("arrow.up.arrow.down.circle.fill",
                                            pressed: "arrow.up.arrow.down.circle",
                                            dark: true,
                                            inset: false,
                                            tag: .toggleKeyboard,
                                            to: textView)
        return .movableGroup(customizationIdentifier: "Scheme keyboard",
                             representativeItem: nil,
                             items: [indent, undent, comment, uncomment,
                                     cursorLeft, cursorRight, cursorUp,
                                     cursorDown, cursorNav])
      } else {
        let dash = self.ipadButton("–", tag: .dash, to: textView)
        let times = self.ipadButton("*", tag: .times, to: textView)
        let quote = self.ipadButton("'", tag: .quote, to: textView)
        let doubleQuote = self.ipadButton("\"", tag: .doubleQuote, to: textView)
        let parenLeft = self.ipadButton("(", tag: .parenLeft, to: textView)
        let parenRight = self.ipadButton(")", tag: .parenRight, to: textView)
        let equals = self.ipadButton("=", tag: .equals, to: textView)
        let question = self.ipadButton("?", tag: .question, to: textView)
        let cursorNav = self.ipadIconButton("arrow.up.arrow.down.circle",
                                            pressed: "arrow.up.arrow.down.circle.fill",
                                            dark: true,
                                            inset: false,
                                            tag: .toggleKeyboard,
                                            to: textView)
        return .movableGroup(customizationIdentifier: "Scheme keyboard",
                             representativeItem: nil,
                             items: [dash, times, quote, doubleQuote,
                                     parenLeft, parenRight, equals,
                                     question, cursorNav])
      }
    } else if self.showingCursorKeys {
      let indent = self.ipadIconButton("increase.indent", tag: .indent, to: textView)
      let undent = self.ipadIconButton("decrease.indent", tag: .undent, to: textView)
      let cursorLeft = self.ipadButton("←", tag: .cursorLeft, to: textView)
      let cursorRight = self.ipadButton("→", tag: .cursorRight, to: textView)
      let cursorUp = self.ipadButton("↑", tag: .cursorUp, to: textView)
      let cursorDown = self.ipadButton("↓", tag: .cursorDown, to: textView)
      let cursorNav = self.ipadIconButton("arrow.up.arrow.down.circle.fill",
                                          pressed: "arrow.up.arrow.down.circle",
                                          dark: true,
                                          inset: false,
                                          tag: .toggleKeyboard,
                                          to: textView)
      return .movableGroup(customizationIdentifier: "Scheme keyboard",
                           representativeItem: nil,
                           items: [indent, undent,
                                   cursorLeft, cursorRight, cursorUp,
                                   cursorDown, cursorNav])
    } else {
      let hash = self.ipadButton("#", tag: .hash, to: textView)
      let dash = self.ipadButton("–", tag: .dash, to: textView)
      let underscore = self.ipadButton("_", tag: .underscore, to: textView)
      let times = self.ipadButton("*", tag: .times, to: textView)
      let backquote = self.ipadButton("`", tag: .backquote, to: textView)
      let doubleQuote = self.ipadButton("\"", tag: .doubleQuote, to: textView)
      let parenLeft = self.ipadButton("(", tag: .parenLeft, to: textView)
      let parenRight = self.ipadButton(")", tag: .parenRight, to: textView)
      let cursorNav = self.ipadIconButton("arrow.up.arrow.down.circle",
                                      pressed: "arrow.up.arrow.down.circle.fill",
                                      dark: true,
                                      inset: false,
                                      tag: .toggleKeyboard,
                                      to: textView)
      return .movableGroup(customizationIdentifier: "Text keyboard",
                           representativeItem: nil,
                           items: [hash, dash, underscore, times,
                                   backquote, doubleQuote,
                                   parenLeft, parenRight, cursorNav])
    }
  }

  private func ipadButton(_ title: String,
                          tag: KeyTag,
                          to textView: CodeEditorTextView) -> UIBarButtonItem {
    let button = UIButton(type: .roundedRect)
    button.tag = tag.rawValue
    button.setTitle(title, for: .normal)
    button.setTitleColor(.label, for: .normal)
    button.setTitleColor(UIColor(named: "KeyHighlightColor"), for: .highlighted)
    button.backgroundColor = UIColor(named: "PadKeyColor")
    button.titleLabel?.font = .systemFont(ofSize: 15)
    button.heightAnchor.constraint(equalToConstant: 40).isActive = true
    button.widthAnchor.constraint(equalToConstant: 44).isActive = true
    button.translatesAutoresizingMaskIntoConstraints = false
    return self.buttonItem(button, container: true, tag: tag, to: textView)
  }

  private func ipadIconButton(_ name: String,
                              pressed hl: String? = nil,
                              dark: Bool = false,
                              inset: Bool = true,
                              tag: KeyTag,
                              to textView: CodeEditorTextView) -> UIBarButtonItem {
    let imgConfig = UIImage.SymbolConfiguration(pointSize: 15, weight: .regular, scale: .default)
    let button = UIButton(type: .roundedRect)
    button.tag = tag.rawValue
    if inset {
      button.heightAnchor.constraint(equalToConstant: 40).isActive = true
      button.widthAnchor.constraint(equalToConstant: 44).isActive = true
      button.setImage(UIImage(systemName: name, withConfiguration: imgConfig)!, for: .normal)
      if let hl {
        button.setImage(UIImage(systemName: hl, withConfiguration: imgConfig)!, for: .highlighted)
      }
    } else {
      button.heightAnchor.constraint(equalToConstant: 32).isActive = true
      button.widthAnchor.constraint(equalToConstant: 44).isActive = true
      button.setImage(UIImage(systemName: name)!, for: .normal)
      if let hl {
        button.setImage(UIImage(systemName: hl)!, for: .highlighted)
      }
    }
    button.tintColor = .label
    button.backgroundColor = UIColor(named: dark ? "PadDarkKeyColor" : "PadKeyColor")
    button.translatesAutoresizingMaskIntoConstraints = false
    return self.buttonItem(button, container: true, tag: tag, to: textView)
  }

  private func buttonItem(_ button: UIButton,
                          container: Bool = false,
                          tag: KeyTag,
                          to textView: CodeEditorTextView) -> UIBarButtonItem {
    _ = self.styleButton(button, to: textView)
    let item: UIBarButtonItem
    if container {
      let container = UIView()
      container.translatesAutoresizingMaskIntoConstraints = false
      container.addSubview(button)
      NSLayoutConstraint.activate([
        button.centerYAnchor.constraint(equalTo: container.centerYAnchor),
        button.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 4),
        button.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -4),
        button.heightAnchor.constraint(equalToConstant: 40),
        container.heightAnchor.constraint(equalToConstant: 44)
      ])
      item = UIBarButtonItem(customView: container)
    } else {
      item = UIBarButtonItem(customView: button)
    }
    item.tag = tag.rawValue
    return item
  }
}
