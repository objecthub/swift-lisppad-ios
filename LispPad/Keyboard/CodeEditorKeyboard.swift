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

/// Identifies the individual keys that can appear on an extended code editor keyboard,
/// independent of whether they are rendered for iPad or iPhone.
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

/// An extended keyboard accessory for `CodeEditorTextView`, providing quick access to
/// characters and editing commands that are cumbersome to reach on the system keyboard.
/// `iPadKeyboard` and `iPhoneKeyboard` implement this protocol for their respective idioms;
/// use `makeCodeEditorKeyboard(console:editorType:)` to instantiate the right one.
protocol CodeEditorKeyboard: AnyObject {

  /// Set to true if this is a keyboard for the console
  var console: Bool { get }

  /// Keyboards are editor type-specific. This property defines for what type the current
  /// keyboard was set up.
  var editorType: FileExtensions.EditorType { get set }

  /// Installs or refreshes the keyboard accessory on `textView`.
  func setup(for textView: CodeEditorTextView)

  /// Switches between the default key set and the cursor navigation key set.
  func toggleKeyboard(for textView: CodeEditorTextView)
}

extension CodeEditorKeyboard {

  var shouldUseExtendedKeyboard: Bool {
    return (self.console ? UserSettings.standard.consoleExtendedKeyboard
                         : UserSettings.standard.extendedKeyboard) &&
           (UIDevice.current.userInterfaceIdiom != .pad ||
            !(UserSettings.standard.disableExtendedKeyboard && GCKeyboard.coalesced != nil))
  }

  func currentEditorType(for textView: CodeEditorTextView) -> FileExtensions.EditorType {
    guard let currentEditorType = (textView.textStorage.delegate as? CodeEditorTextStorageDelegate)?
                                    .editorType else {
      return self.editorType
    }
    return currentEditorType
  }

  func styleButton(_ button: UIButton, to textView: CodeEditorTextView) -> UIButton {
    button.layer.borderWidth = 1.0 / UIScreen.main.scale
    button.layer.cornerRadius = 5
    button.layer.borderColor = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0).cgColor
    button.addTarget(textView,
                     action: #selector(textView.keyboardButtonPressed(_:)),
                     for: .touchUpInside)
    return button
  }
}

/// Creates the `CodeEditorKeyboard` implementation appropriate for the current device idiom.
func makeCodeEditorKeyboard(console: Bool,
                         editorType: FileExtensions.EditorType) -> CodeEditorKeyboard {
  if UIDevice.current.userInterfaceIdiom == .pad {
    return iPadKeyboard(console: console, editorType: editorType)
  } else {
    return iPhoneKeyboard(console: console, editorType: editorType)
  }
}
