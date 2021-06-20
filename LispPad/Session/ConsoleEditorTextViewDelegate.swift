//
//  ConsoleEditorTextViewDelegate.swift
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

import UIKit
import SwiftUI

class ConsoleEditorTextViewDelegate: EditorTextViewDelegate {
  var calculatedHeight: Binding<CGFloat>
  
  init(text: Binding<String>, selectedRange: Binding<NSRange>, calculatedHeight: Binding<CGFloat>) {
    self.calculatedHeight = calculatedHeight
    super.init(text: text, selectedRange: selectedRange)
  }
  
  override public func textViewDidChange(_ textView: UITextView) {
    self.text = textView.text ?? ""
    self.selectedRange = textView.selectedRange
    ConsoleEditor.recalculateHeight(textView: textView, result: calculatedHeight)
    guard textView.markedTextRange == nil else {
      return
    }
    self.lastSelectedRange = textView.selectedRange
  }
}
