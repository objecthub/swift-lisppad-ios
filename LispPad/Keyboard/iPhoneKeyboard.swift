//
//  iPhoneKeyboard.swift
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

/// `CodeEditorKeyboard` implementation for iPhone, rendering keys as a horizontal
/// `UIStackView` installed as the text view's `inputAccessoryView`.
final class iPhoneKeyboard: CodeEditorKeyboard {

  private enum KeyboardSize: Equatable {
    case small
    case medium
    case large
  }

  static let buttonSpace = CGFloat(5)

  /// How far the accessory bar's glass background extends below the button row, into the
  /// otherwise-unblurred seam above the system keyboard's own (top-rounded) glass background.
  static let backgroundBleed = CGFloat(20)

  let console: Bool
  var editorType: FileExtensions.EditorType

  /// Tracks whether cursor navigation keys are currently visible
  private var showingCursorKeys: Bool = false

  /// The iPhone accessory view is created once per keyboard and reused for every toggle/editor
  /// type change; swapping in a brand-new `UIInputView` on every update confuses the system's
  /// self-sizing accessory view transition (iOS 27 briefly reserves the old view's height,
  /// leaving a visible gap above the new content). This is also why `allowsSelfSizing` is left
  /// off below: our accessory view's height never actually changes (only its button row does),
  /// so there is nothing to negotiate, and opting into self-sizing negotiation is what causes
  /// iOS to (sometimes) reserve the outgoing accessory view's height a second time when first
  /// responder moves to a *different* text view whose own accessory view has the same height.
  private var accessoryView: UIView?
  private var accessoryStack: UIStackView?

  init(console: Bool, editorType: FileExtensions.EditorType) {
    self.console = console
    self.editorType = editorType
  }

  func setup(for textView: CodeEditorTextView) {
    if self.shouldUseExtendedKeyboard {
      let currentEditorType = self.currentEditorType(for: textView)
      if textView.inputAccessoryView == nil {
        self.editorType = currentEditorType
        self.updateAccessoryView(for: textView)
        textView.reloadInputViews()
      } else if currentEditorType != self.editorType {
        self.editorType = currentEditorType
        self.updateAccessoryView(for: textView)
        textView.reloadInputViews()
      }
    } else if textView.inputAccessoryView != nil {
      textView.inputAccessoryView = nil
      textView.reloadInputViews()
    }
  }

  func toggleKeyboard(for textView: CodeEditorTextView) {
    self.showingCursorKeys.toggle()
    self.updateAccessoryView(for: textView)
    textView.reloadInputViews()
  }
  
  private func updateAccessoryView(for textView: CodeEditorTextView) {
    let items = self.keyboardItems(for: textView)
    if let stack = self.accessoryStack {
      for view in stack.arrangedSubviews {
        stack.removeArrangedSubview(view)
        view.removeFromSuperview()
      }
      for view in items {
        stack.addArrangedSubview(view)
      }
    } else {
      let stack = UIStackView(arrangedSubviews: items)
      stack.axis = .horizontal
      stack.alignment = .center
      stack.distribution = .fill
      stack.translatesAutoresizingMaskIntoConstraints = false
      let inputView = UIInputView(frame: CGRect(x: 0,
                                                y: 0,
                                                width: UIScreen.main.bounds.width,
                                                height: 44),
                                  inputViewStyle: .keyboard)
      inputView.autoresizingMask = UIView.AutoresizingMask.flexibleRightMargin.union(.flexibleWidth)
      inputView.translatesAutoresizingMaskIntoConstraints = false
      inputView.isUserInteractionEnabled = true
      // Subviews are allowed to paint outside `inputView`'s own bounds so `backgroundView`
      // below can bleed into the sliver that is otherwise left unblurred between this bar
      // and the system keyboard's own (top-rounded) glass background underneath it.
      inputView.clipsToBounds = false
      let backgroundView = self.accessoryBackgroundView()
      backgroundView.translatesAutoresizingMaskIntoConstraints = false
      inputView.addSubview(backgroundView)
      inputView.addSubview(stack)
      NSLayoutConstraint.activate([
        backgroundView.leadingAnchor.constraint(equalTo: inputView.leadingAnchor),
        backgroundView.trailingAnchor.constraint(equalTo: inputView.trailingAnchor),
        backgroundView.topAnchor.constraint(equalTo: inputView.topAnchor),
        backgroundView.bottomAnchor.constraint(equalTo: inputView.bottomAnchor,
                                               constant: iPhoneKeyboard.backgroundBleed),
        stack.leadingAnchor.constraint(equalTo: inputView.leadingAnchor),
        stack.trailingAnchor.constraint(equalTo: inputView.trailingAnchor),
        stack.centerYAnchor.constraint(equalTo: inputView.centerYAnchor),
        inputView.heightAnchor.constraint(equalToConstant: 44)
      ])
      self.accessoryView = inputView
      self.accessoryStack = stack
    }
    textView.inputAccessoryView = self.accessoryView
  }

  /// A background matching the system keyboard's own glass material as closely as possible:
  /// `UIGlassEffect` on iOS 26+, falling back to a comparably translucent blur on older versions.
  private func accessoryBackgroundView() -> UIVisualEffectView {
    if #available(iOS 26.0, *) {
      return UIVisualEffectView(effect: UIGlassEffect(style: .regular))
    } else {
      return UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
    }
  }

  private func keyboardItems(for textView: CodeEditorTextView) -> [UIView] {
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

  private func fixedSpace(_ width: CGFloat = iPhoneKeyboard.buttonSpace) -> UIView {
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
}
