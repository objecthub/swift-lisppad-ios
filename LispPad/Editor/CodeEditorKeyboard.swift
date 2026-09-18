//
//  CodeEditorKeyboard.swift
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
import GameController

final class CodeEditorKeyboard {
  
  enum KeyTag: Int {
    case dismissKeyboard
    case toggleKeyboard
    case dash
    case times
    case quote
    case doubleQuote
    case parenLeft
    case parenRight
    case equals
    case question
    case exclamation
    case bracket
    case hash
    case backquote
    case underscore
    case indent
    case undent
    case comment
    case uncomment
    case cursorLeft
    case cursorRight
    case cursorUp
    case cursorDown
    case undo
    case redo
  }
  
  enum KeyboardSize: Equatable {
    case small
    case medium
    case large
  }
  
  static let iPhoneButtonSpace = CGFloat(5)
  
  /// Set to true if this is a keyboard for the console
  let console: Bool
  
  /// Keyboards are editor type-specific. This property defines for what type the current
  /// keyboard was set up.
  var editorType: FileExtensions.EditorType
  
  /// Tracks whether cursor navigation keys are currently visible
  var showingCursorKeys: Bool = false
  
  init(console: Bool, editorType: FileExtensions.EditorType) {
    self.console = console
    self.editorType = editorType
  }
  
  private var shouldUseExtendedKeyboard: Bool {
    return (self.console ? UserSettings.standard.consoleExtendedKeyboard
                         : UserSettings.standard.extendedKeyboard) &&
           (UIDevice.current.userInterfaceIdiom != .pad ||
            !(UserSettings.standard.disableExtendedKeyboard && GCKeyboard.coalesced != nil))
  }
  
  private func currentEditorType(for textView: CodeEditorTextView) -> FileExtensions.EditorType {
    guard let currentEditorType = (textView.textStorage.delegate as? CodeEditorTextStorageDelegate)?
                                    .editorType else {
      return self.editorType
    }
    return currentEditorType
  }
  
  private func iPadKeyboard(for textView: CodeEditorTextView) -> UIBarButtonItemGroup {
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
  
  private func iPhoneKeyboardItems(for textView: CodeEditorTextView) -> [UIView] {
    let smallestSize = min(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
    let kbd: KeyboardSize
    if smallestSize >= 400 {
      kbd = smallestSize >= 450 ? .large : .medium
    } else {
      kbd = .small
    }
    let items: [UIView]
    if self.editorType == .scheme {
      if self.showingCursorKeys {
        let indent = self.iconButton("increase.indent", tag: .indent, to: textView)
        let undent = self.iconButton("decrease.indent", tag: .undent, to: textView)
        let comment = self.iconButton("text.bubble", tag: .comment, to: textView)
        let uncomment = self.iconButton("bubble.left", tag: .uncomment, to: textView)
        let cursorLeft = self.textButton("←", tag: .cursorLeft, to: textView)
        let cursorRight = self.textButton("→", tag: .cursorRight, to: textView)
        let cursorUp = self.textButton("↑", tag: .cursorUp, to: textView)
        let cursorDown = self.textButton("↓", tag: .cursorDown, to: textView)
        let cursorNav = self.iconButton("arrow.up.arrow.down.circle.fill",
                                        pressed: "arrow.up.arrow.down.circle",
                                        dark: true,
                                        inset: false,
                                        tag: .toggleKeyboard,
                                        to: textView)
        let close = self.iconButton("keyboard.chevron.compact.down",
                                    pressed: "keyboard",
                                    dark: true,
                                    inset: false,
                                    tag: .dismissKeyboard,
                                    to: textView)
        items = [self.fixedSpace(),
                 indent, self.fixedSpace(),
                 undent, self.fixedSpace(),
                 comment, self.fixedSpace(),
                 uncomment, self.fixedSpace(),
                 cursorLeft, self.fixedSpace(),
                 cursorRight, self.fixedSpace(),
                 cursorUp, self.fixedSpace(),
                 cursorDown, self.flexibleSpace(),
                 cursorNav, self.fixedSpace(),
                 close, self.fixedSpace()]
      } else {
        let dash = self.textButton("–", tag: .dash, to: textView)
        let times = self.textButton("*", tag: .times, to: textView)
        let quote = self.textButton("'", tag: .quote, to: textView)
        let doubleQuote = self.textButton("\"", tag: .doubleQuote, to: textView)
        let parenLeft = self.textButton("(", tag: .parenLeft, to: textView)
        let parenRight = self.textButton(")", tag: .parenRight, to: textView)
        let equals = self.textButton("=", tag: .equals, to: textView)
        let question = self.textButton("?", tag: .question, to: textView)
        let exclamation = self.textButton("!", tag: .exclamation, to: textView)
        let hash = self.textButton("#", tag: .hash, to: textView)
        let cursorNav = self.iconButton("arrow.up.arrow.down.circle",
                                        pressed: "arrow.up.arrow.down.circle.fill",
                                        dark: true,
                                        inset: false,
                                        tag: .toggleKeyboard,
                                        to: textView)
        let close = self.iconButton("keyboard.chevron.compact.down",
                                    pressed: "keyboard",
                                    dark: true,
                                    inset: false,
                                    tag: .dismissKeyboard,
                                    to: textView)
        var leading: [UIView] = [
          self.fixedSpace(),
          dash, self.fixedSpace(),
          times, self.fixedSpace(),
          quote, self.fixedSpace(),
          doubleQuote, self.fixedSpace(),
          parenLeft, self.fixedSpace(),
          parenRight, self.fixedSpace(),
          equals, self.fixedSpace(),
        ]
        if kbd == .large {
          leading.append(hash)
          leading.append(self.fixedSpace())
        }
        if kbd == .large || kbd == .medium {
          leading.append(exclamation)
          leading.append(self.fixedSpace())
        }
        items = leading +
                [question, self.flexibleSpace(),
                 cursorNav, self.fixedSpace(),
                 close, self.fixedSpace()]
      }
    } else if self.showingCursorKeys {
      let undo = self.iconButton("arrow.uturn.backward", tag: .undo, to: textView)
      let redo = self.iconButton("arrow.uturn.forward", tag: .redo, to: textView)
      let indent = self.iconButton("increase.indent", tag: .indent, to: textView)
      let undent = self.iconButton("decrease.indent", tag: .undent, to: textView)
      let cursorLeft = self.textButton("←", tag: .cursorLeft, to: textView)
      let cursorRight = self.textButton("→", tag: .cursorRight, to: textView)
      let cursorUp = self.textButton("↑", tag: .cursorUp, to: textView)
      let cursorDown = self.textButton("↓", tag: .cursorDown, to: textView)
      let cursorNav = self.iconButton("arrow.up.arrow.down.circle.fill",
                                      pressed: "arrow.up.arrow.down.circle",
                                      dark: true,
                                      inset: false,
                                      tag: .toggleKeyboard,
                                      to: textView)
      let close = self.iconButton("keyboard.chevron.compact.down",
                                  pressed: "keyboard",
                                  dark: true,
                                  inset: false,
                                  tag: .dismissKeyboard,
                                  to: textView)
      items = [self.fixedSpace(),
               undo, self.fixedSpace(),
               redo, self.fixedSpace(),
               indent, self.fixedSpace(),
               undent, self.fixedSpace(),
               cursorLeft, self.fixedSpace(),
               cursorRight, self.fixedSpace(),
               cursorUp, self.fixedSpace(),
               cursorDown, self.flexibleSpace(),
               cursorNav, self.fixedSpace(),
               close, self.fixedSpace()]
    } else {
      let hash = self.textButton("#", tag: .hash, to: textView)
      let dash = self.textButton("–", tag: .dash, to: textView)
      let underscore = self.textButton("_", tag: .underscore, to: textView)
      let times = self.textButton("*", tag: .times, to: textView)
      let backquote = self.textButton("`", tag: .backquote, to: textView)
      let doubleQuote = self.textButton("\"", tag: .doubleQuote, to: textView)
      let question = self.textButton("?", tag: .question, to: textView)
      let bracket = self.textButton(">", tag: .bracket, to: textView)
      let parenLeft = self.textButton("(", tag: .parenLeft, to: textView)
      let parenRight = self.textButton(")", tag: .parenRight, to: textView)
      let cursorNav = self.iconButton("arrow.up.arrow.down.circle",
                                      pressed: "arrow.up.arrow.down.circle.fill",
                                      dark: true,
                                      inset: false,
                                      tag: .toggleKeyboard,
                                      to: textView)
      let close = self.iconButton("keyboard.chevron.compact.down",
                                  pressed: "keyboard",
                                  dark: true,
                                  inset: false,
                                  tag: .dismissKeyboard,
                                  to: textView)
      var leading: [UIView] = [
        self.fixedSpace(),
        hash, self.fixedSpace(),
        dash, self.fixedSpace(),
        underscore, self.fixedSpace(),
        times, self.fixedSpace(),
        backquote, self.fixedSpace(),
        doubleQuote, self.fixedSpace(),
      ]
      if kbd == .large || kbd == .medium {
        leading.append(bracket)
        leading.append(self.fixedSpace())
      }
      if kbd == .large {
        leading.append(question)
        leading.append(self.fixedSpace())
      }
      items = leading +
              [parenLeft, self.fixedSpace(),
               parenRight, self.flexibleSpace(),
               cursorNav, self.fixedSpace(),
               close, self.fixedSpace()]
    }
    return items
  }

  private func fixedSpace(_ width: CGFloat = CodeEditorKeyboard.iPhoneButtonSpace) -> UIView {
    let spacer = UIView()
    spacer.translatesAutoresizingMaskIntoConstraints = false
    spacer.widthAnchor.constraint(equalToConstant: width).isActive = true
    spacer.setContentHuggingPriority(.required, for: .horizontal)
    spacer.setContentCompressionResistancePriority(.required, for: .horizontal)
    return spacer
  }

  private func flexibleSpace() -> UIView {
    let spacer = UIView()
    spacer.translatesAutoresizingMaskIntoConstraints = false
    spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
    spacer.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    return spacer
  }

  /// The iPhone accessory view is created once per keyboard and reused for every toggle/editor
  /// type change; swapping in a brand-new `UIInputView` on every update confuses the system's
  /// self-sizing accessory view transition (iOS 27 briefly reserves the old view's height,
  /// leaving a visible gap above the new content).
  private var iPhoneAccessoryView: UIView?
  private var iPhoneAccessoryStack: UIStackView?

  private func updateIPhoneAccessoryView(for textView: CodeEditorTextView) {
    let items = self.iPhoneKeyboardItems(for: textView)
    if let stack = self.iPhoneAccessoryStack {
      for view in stack.arrangedSubviews {
        stack.removeArrangedSubview(view)
        view.removeFromSuperview()
      }
      for view in items {
        stack.addArrangedSubview(view)
      }
    } else {
      let inputView = UIInputView(frame: CGRect(x: 0, y: 0,
                                                width: UIScreen.main.bounds.width, height: 44),
                                  inputViewStyle: .keyboard)
      inputView.allowsSelfSizing = true
      inputView.autoresizingMask = UIView.AutoresizingMask.flexibleRightMargin.union(.flexibleWidth)
      inputView.translatesAutoresizingMaskIntoConstraints = false
      inputView.isUserInteractionEnabled = true
      let stack = UIStackView(arrangedSubviews: items)
      stack.axis = .horizontal
      stack.alignment = .center
      stack.distribution = .fill
      stack.translatesAutoresizingMaskIntoConstraints = false
      inputView.addSubview(stack)
      NSLayoutConstraint.activate([
        stack.leadingAnchor.constraint(equalTo: inputView.leadingAnchor),
        stack.trailingAnchor.constraint(equalTo: inputView.trailingAnchor),
        stack.centerYAnchor.constraint(equalTo: inputView.centerYAnchor),
        inputView.heightAnchor.constraint(equalToConstant: 44)
      ])
      self.iPhoneAccessoryView = inputView
      self.iPhoneAccessoryStack = stack
    }
    textView.inputAccessoryView = self.iPhoneAccessoryView
  }
  
  func setup(for textView: CodeEditorTextView) {
    if UIDevice.current.userInterfaceIdiom == .pad {
      if self.shouldUseExtendedKeyboard {
        let currentEditorType = self.currentEditorType(for: textView)
        if textView.inputAssistantItem.trailingBarButtonGroups.isEmpty ||
           textView.inputAssistantItem.trailingBarButtonGroups.last!.barButtonItems.count < 7 {
          self.editorType = currentEditorType
          textView.inputAssistantItem.trailingBarButtonGroups.append(self.iPadKeyboard(for: textView))
        } else if currentEditorType != self.editorType {
          self.editorType = currentEditorType
          if let last = textView.inputAssistantItem.trailingBarButtonGroups.last,
             last.barButtonItems.count >= 7 {
            textView.inputAssistantItem.trailingBarButtonGroups.removeLast()
          }
          textView.inputAssistantItem.trailingBarButtonGroups.append(self.iPadKeyboard(for: textView))
          textView.reloadInputViews()
        }
      } else if let last = textView.inputAssistantItem.trailingBarButtonGroups.last,
                last.barButtonItems.count >= 7 {
        textView.inputAssistantItem.trailingBarButtonGroups.removeLast()
        textView.reloadInputViews()
      }
    } else if self.shouldUseExtendedKeyboard {
      let currentEditorType = self.currentEditorType(for: textView)
      if textView.inputAccessoryView == nil {
        self.editorType = currentEditorType
        self.updateIPhoneAccessoryView(for: textView)
        textView.reloadInputViews()
        // The following hack makes sure the other views adjust correctly
        /* if textView.isFirstResponder {
          textView.resignFirstResponder()
        } else {
          textView.becomeFirstResponder()
        } */
      } else if currentEditorType != self.editorType {
        self.editorType = currentEditorType
        self.updateIPhoneAccessoryView(for: textView)
        textView.reloadInputViews()
      }
    } else if textView.inputAccessoryView != nil {
      textView.inputAccessoryView = nil
      textView.reloadInputViews()
    }
  }
  
  func toggleKeyboard(for textView: CodeEditorTextView) {
    self.showingCursorKeys.toggle()
    if UIDevice.current.userInterfaceIdiom == .pad {
      if let last = textView.inputAssistantItem.trailingBarButtonGroups.last,
         last.barButtonItems.count >= 7 {
        let numGroups = textView.inputAssistantItem.trailingBarButtonGroups.count
        textView.inputAssistantItem.trailingBarButtonGroups[numGroups - 1] =
          self.iPadKeyboard(for: textView)
        textView.reloadInputViews()
      }
    } else {
      self.updateIPhoneAccessoryView(for: textView)
      textView.reloadInputViews()
    }
  }
  
  private func textButton(_ title: String,
                          tag: KeyTag,
                          to textView: CodeEditorTextView) -> UIButton {
    let button = UIButton(type: .roundedRect)
    button.tag = tag.rawValue
    button.heightAnchor.constraint(equalToConstant: 32).isActive = true
    button.widthAnchor.constraint(equalToConstant: 31).isActive = true
    button.setTitle(title, for: .normal)
    button.setTitleColor(.label, for: .normal)
    button.setTitleColor(UIColor(named: "KeyHighlightColor"), for: .highlighted)
    button.backgroundColor = UIColor(named: "KeyColor")
    button.translatesAutoresizingMaskIntoConstraints = false
    return self.styleButton(button, to: textView)
  }
  
  private func iconButton(_ name: String,
                          pressed hl: String? = nil,
                          dark: Bool = false,
                          inset: Bool = true,
                          tag: KeyTag,
                          to textView: CodeEditorTextView) -> UIButton {
    let imgConfig = UIImage.SymbolConfiguration(pointSize: 15, weight: .regular, scale: .default)
    let button = UIButton(type: .roundedRect)
    // var config = UIButton.Configuration.plain()
    // config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)
    // button.configuration = config
    button.tag = tag.rawValue
    if inset {
      button.heightAnchor.constraint(equalToConstant: 32).isActive = true
      button.widthAnchor.constraint(equalToConstant: 31).isActive = true
      button.setImage(UIImage(systemName: name, withConfiguration: imgConfig)!, for: .normal)
      if let hl {
        button.setImage(UIImage(systemName: hl, withConfiguration: imgConfig)!, for: .highlighted)
      }
    } else {
      button.heightAnchor.constraint(equalToConstant: 32).isActive = true
      button.widthAnchor.constraint(equalToConstant: 30).isActive = true
      button.setImage(UIImage(systemName: name)!, for: .normal)
      if let hl {
        button.setImage(UIImage(systemName: hl)!, for: .highlighted)
      }
    }
    button.tintColor = .label
    button.backgroundColor = UIColor(named: dark ? "DarkKeyColor" : "KeyColor")
    button.translatesAutoresizingMaskIntoConstraints = false
    return self.styleButton(button, to: textView)
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
    // var config = UIButton.Configuration.plain()
    // config.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4)
    // button.configuration = config
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

  private func styleButton(_ button: UIButton, to textView: CodeEditorTextView) -> UIButton {
    button.layer.borderWidth = 1.0 / UIScreen.main.scale
    button.layer.cornerRadius = 5
    button.layer.borderColor = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0).cgColor
    button.addTarget(textView,
                     action: #selector(textView.keyboardButtonPressed(_:)),
                     for: .touchUpInside)
    return button
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
