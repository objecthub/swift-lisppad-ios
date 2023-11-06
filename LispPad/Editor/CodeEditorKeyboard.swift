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
    case dash
    case times
    case quote
    case doubleQuote
    case parenLeft
    case parenRight
    case equals
    case question
    case hash
    case backquote
    case underscore
  }
  
  /// Set to true if this is a keyboard for the console
  let console: Bool
  
  /// Keyboards are editor type-specific. This property defines for what type the current
  /// keyboard was set up.
  var editorType: FileExtensions.EditorType
  
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
      let dash = self.keyboardButton("Key.dash", tag: .dash, to: textView)
      let times = self.keyboardButton("Key.star", tag: .times, to: textView)
      let quote = self.keyboardButton("Key.quote", tag: .quote, to: textView)
      let doubleQuote = self.keyboardButton("Key.doublequote", tag: .doubleQuote, to: textView)
      let parenLeft = self.keyboardButton("Key.lparen", tag: .parenLeft, to: textView)
      let parenRight = self.keyboardButton("Key.rparen", tag: .parenRight, to: textView)
      let equals = self.keyboardButton("Key.equals", tag: .equals, to: textView)
      let question = self.keyboardButton("Key.questionmark", tag: .question, to: textView)
      let hash = self.keyboardButton("Key.hash", tag: .hash, to: textView)
      return .movableGroup(customizationIdentifier: "Scheme keyboard",
                           representativeItem: nil,
                           items: [dash, times, quote, doubleQuote,
                                   parenLeft, parenRight, equals,
                                   question, hash])
    } else {
      let dash = self.keyboardButton("Key.dash", tag: .dash, to: textView)
      let times = self.keyboardButton("Key.star", tag: .times, to: textView)
      let quote = self.keyboardButton("Key.quote", tag: .quote, to: textView)
      let doubleQuote = self.keyboardButton("Key.doublequote", tag: .doubleQuote, to: textView)
      let parenLeft = self.keyboardButton("Key.lparen", tag: .parenLeft, to: textView)
      let parenRight = self.keyboardButton("Key.rparen", tag: .parenRight, to: textView)
      let backquote = self.keyboardButton("Key.backquote", tag: .backquote, to: textView)
      let underscore = self.keyboardButton("Key.underscore", tag: .underscore, to: textView)
      let hash = self.keyboardButton("Key.hash", tag: .hash, to: textView)
      return .movableGroup(customizationIdentifier: "Text keyboard",
                           representativeItem: nil,
                           items: [dash, times, quote, doubleQuote,
                                   parenLeft, parenRight, backquote,
                                   underscore, hash])
    }
  }
  
  private func iPhoneKeyboard(for textView: CodeEditorTextView) -> UIToolbar {
    let bar = UIToolbar(frame: CGRect(x: 0, y: 0,
                                      width: UIScreen.main.bounds.width, height: 35))
    bar.barStyle = .default
    bar.isTranslucent = false
    bar.barTintColor = UIColor(named: "KeyboardColor")
    bar.autoresizingMask = UIView.AutoresizingMask.flexibleRightMargin.union(.flexibleWidth)
    if self.editorType == .scheme {
      let dash = self.textButton("-", tag: .dash, to: textView)
      let times = self.textButton("*", tag: .times, to: textView)
      let quote = self.textButton("'", tag: .quote, to: textView)
      let doubleQuote = self.textButton("\"", tag: .doubleQuote, to: textView)
      let parenLeft = self.textButton("(", tag: .parenLeft, to: textView)
      let parenRight = self.textButton(")", tag: .parenRight, to: textView)
      let equals = self.textButton("=", tag: .equals, to: textView)
      let question = self.textButton("?", tag: .question, to: textView)
      let ibutton = self.imageButton(UIImage(systemName: "keyboard.chevron.compact.down"),
                                     tag: .dismissKeyboard,
                                     pressed: UIImage(systemName: "keyboard"),
                                     to: textView)
      bar.setItems([dash, UIBarButtonItem.fixedSpace(6),
                    times, UIBarButtonItem.fixedSpace(6),
                    quote, UIBarButtonItem.fixedSpace(6),
                    doubleQuote, UIBarButtonItem.fixedSpace(6),
                    parenLeft, UIBarButtonItem.fixedSpace(6),
                    parenRight, UIBarButtonItem.fixedSpace(6),
                    equals, UIBarButtonItem.fixedSpace(6),
                    question, UIBarButtonItem.flexibleSpace(),
                    ibutton], animated: false)
    } else {
      let hash = self.textButton("#", tag: .hash, to: textView)
      let dash = self.textButton("-", tag: .dash, to: textView)
      let times = self.textButton("*", tag: .times, to: textView)
      let backquote = self.textButton("`", tag: .backquote, to: textView)
      let quote = self.textButton("'", tag: .quote, to: textView)
      let doubleQuote = self.textButton("\"", tag: .doubleQuote, to: textView)
      let parenLeft = self.textButton("(", tag: .parenLeft, to: textView)
      let parenRight = self.textButton(")", tag: .parenRight, to: textView)
      let ibutton = self.imageButton(UIImage(systemName: "keyboard.chevron.compact.down"),
                                     tag: .dismissKeyboard,
                                     pressed: UIImage(systemName: "keyboard"),
                                     to: textView)
      bar.setItems([hash, UIBarButtonItem.fixedSpace(6),
                    dash, UIBarButtonItem.fixedSpace(6),
                    times, UIBarButtonItem.fixedSpace(6),
                    backquote, UIBarButtonItem.fixedSpace(6),
                    quote, UIBarButtonItem.fixedSpace(6),
                    doubleQuote, UIBarButtonItem.fixedSpace(6),
                    parenLeft, UIBarButtonItem.fixedSpace(6),
                    parenRight, UIBarButtonItem.flexibleSpace(),
                    ibutton], animated: false)
    }
    bar.isUserInteractionEnabled = true
    bar.sizeToFit()
    return bar
  }
  
  func setup(for textView: CodeEditorTextView) {
    if UIDevice.current.userInterfaceIdiom == .pad {
      if self.shouldUseExtendedKeyboard {
        let currentEditorType = self.currentEditorType(for: textView)
        if textView.inputAssistantItem.trailingBarButtonGroups.isEmpty ||
           textView.inputAssistantItem.trailingBarButtonGroups.last!.barButtonItems.count != 9 {
          self.editorType = currentEditorType
          textView.inputAssistantItem.trailingBarButtonGroups.append(
            self.iPadKeyboard(for: textView))
        } else if currentEditorType != self.editorType {
          self.editorType = currentEditorType
          textView.inputAssistantItem.trailingBarButtonGroups.removeLast()
          textView.inputAssistantItem.trailingBarButtonGroups.append(
            self.iPadKeyboard(for: textView))
        }
      } else if let last = textView.inputAssistantItem.trailingBarButtonGroups.last,
                last.barButtonItems.count == 9 {
        textView.inputAssistantItem.trailingBarButtonGroups.removeLast()
      }
    } else {
      if self.shouldUseExtendedKeyboard {
        let currentEditorType = self.currentEditorType(for: textView)
        if textView.inputAccessoryView == nil {
          self.editorType = currentEditorType
          textView.inputAccessoryView = self.iPhoneKeyboard(for: textView)
          // The following hack makes sure the other views adjust correctly
          if textView.isFirstResponder {
            textView.resignFirstResponder()
          } else {
            textView.becomeFirstResponder()
          }
        } else if currentEditorType != self.editorType {
          self.editorType = currentEditorType
          textView.inputAccessoryView = self.iPhoneKeyboard(for: textView)
          textView.reloadInputViews()
        }
        // bar.frame = CGRect(x: 0, y: 0, width: 13 * (32 + 6) + 8, height: bar.frame.size.height)
        /* let scrollView = UIScrollView()
        scrollView.frame = bar.frame
        scrollView.bounds = bar.bounds
        scrollView.autoresizingMask = UIView.AutoresizingMask.flexibleWidth.union(
         UIView.AutoresizingMask.flexibleRightMargin)
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.bounces = false
        scrollView.contentSize = bar.frame.size
        scrollView.addSubview(bar)
        textView.inputAccessoryView = scrollView */
      } else if textView.inputAccessoryView != nil {
        textView.inputAccessoryView = nil
        textView.reloadInputViews()
      }
    }
  }
  
  private func keyboardButton(_ name: String,
                              tag: KeyTag,
                              to textView: CodeEditorTextView) -> UIBarButtonItem {
    let item = UIBarButtonItem(image: UIImage(named: name)?.withRenderingMode(.alwaysTemplate),
                               style: .plain,
                               target: textView,
                               action: #selector(textView.keyboardButtonPressed(_:)))
    item.tag = tag.rawValue
    return item
  }
  
  private func textButton(_ title: String,
                          tag: KeyTag,
                          to textView: CodeEditorTextView) -> UIBarButtonItem {
    let button = UIButton(type: .roundedRect)
    button.tag = tag.rawValue
    button.frame.size.width = 32
    button.frame.size.height = 34
    button.setTitle(title, for: .normal)
    button.setTitleColor(.label, for: .normal)
    button.setTitleColor(UIColor(named: "KeyHighlightColor"), for: .highlighted)
    button.backgroundColor = UIColor(named: "KeyColor")
    return self.buttonItem(button, tag: tag, to: textView)
  }
  
  private func imageButton(_ image: UIImage?,
                           tag: KeyTag,
                           pressed pimage: UIImage? = nil,
                           to textView: CodeEditorTextView) -> UIBarButtonItem {
    let button = UIButton(type: .custom)
    button.tag = tag.rawValue
    button.frame.size.width = 34
    button.frame.size.height = 34
    button.setImage(image, for: .normal)
    button.setImage(pimage, for: .highlighted)
    button.tintColor = .label
    button.backgroundColor = UIColor(named: "DarkKeyColor")
    return self.buttonItem(button, tag: tag, to: textView)
  }
  
  private func buttonItem(_ button: UIButton,
                          tag: KeyTag,
                          to textView: CodeEditorTextView) -> UIBarButtonItem {
    button.autoresizingMask = UIView.AutoresizingMask.flexibleWidth
                             // .union(UIView.AutoresizingMask.flexibleHeight)
                             .union(UIView.AutoresizingMask.flexibleLeftMargin)
                             // .union(UIView.AutoresizingMask.flexibleRightMargin)
                             // .union(UIView.AutoresizingMask.flexibleTopMargin)
                             // .union(UIView.AutoresizingMask.flexibleBottomMargin)
    button.layer.borderWidth = 0
    button.layer.cornerRadius = 5
    button.layer.borderColor = UIColor.systemGray2.cgColor
    button.layer.shadowRadius = 0
    button.layer.shadowColor = UIColor.black.cgColor
    button.layer.shadowOffset = CGSize(width: 0.0, height: 1.0)
    button.layer.shadowOpacity = 0.4
    button.addTarget(textView,
                     action: #selector(textView.keyboardButtonPressed(_:)),
                     for: .touchUpInside)
    let item = UIBarButtonItem(customView: button)
    item.tag = tag.rawValue
    return item
  }
}
