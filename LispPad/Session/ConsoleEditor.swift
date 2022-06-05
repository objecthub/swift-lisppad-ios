//
//  ConsoleEditor.swift
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

import SwiftUI
import UIKit
import MarkdownKit

struct ConsoleEditor: UIViewRepresentable {
  typealias Coordinator = ConsoleEditorTextViewDelegate
  
  @State var editorType: FileExtensions.EditorType = .scheme

  @EnvironmentObject var docManager: DocumentationManager
  @EnvironmentObject var settings: UserSettings
  
  @Binding var text: String
  @Binding var selectedRange: NSRange
  @Binding var calculatedHeight: CGFloat
  @Binding var update: ((CodeEditorTextView) -> Void)?
  @ObservedObject var keyboardObserver: KeyboardObserver
  
  let defineAction: ((Block) -> Void)?
  
  public func makeCoordinator() -> Coordinator {
    return ConsoleEditorTextViewDelegate(text: _text,
                                         selectedRange: $selectedRange,
                                         calculatedHeight: _calculatedHeight)
  }
  
  public func makeUIView(context: Context) -> CodeEditorTextView {
    let textView = CodeEditorTextView(frame: CGRect(x: 0,
                                                    y: 0,
                                                    width: 100000,
                                                    height: 1000000),
                                      console: true,
                                      editorType: self.editorType,
                                      docManager: self.docManager,
                                      defineAction: self.defineAction)
    textView.delegate = context.coordinator
    textView.showLineNumbers = false
    textView.highlightCurrentLine = false
    textView.isScrollEnabled = false
    textView.isEditable = true
    textView.isSelectable = true
    textView.isUserInteractionEnabled = true
    textView.contentInsetAdjustmentBehavior = .automatic
    textView.keyboardDismissMode = UIDevice.current.userInterfaceIdiom == .pad ? .none
                                                                               : .interactive
    textView.smartQuotesType = .no
    textView.smartDashesType = .no
    textView.smartInsertDeleteType = .no
    textView.textAlignment = .left
    textView.keyboardType = .default
    textView.autocapitalizationType = .none
    textView.autocorrectionType = .no
    textView.spellCheckingType = .no
    textView.font = self.settings.inputFont
    textView.textColor = UIColor(named: "CodeEditorTextColor")
    textView.backgroundColor = .clear
    let textInputTraits = textView.value(forKey: "textInputTraits") as? NSObject
    textInputTraits?.setValue(textView.tintColor, forKey: "insertionPointColor")
    textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    textView.becomeFirstResponder()
    textView.text = self.text
    textView.selectedRange = self.selectedRange
    textView.setupEditMenu()
    return textView
  }

  public func updateUIView(_ textView: CodeEditorTextView, context: Context) {
    textView.keyboard.setup(for: textView)
    if textView.font != self.settings.inputFont {
      textView.font = self.settings.inputFont
    }
    if textView.text != self.text {
      if textView.text.isEmpty {
        textView.textStorage.removeAttribute(.backgroundColor,
          range: NSRange(location: 0, length: textView.textStorage.length))
      }
      textView.text = self.text
    }
    if textView.selectedRange != self.selectedRange {
      textView.selectedRange = self.selectedRange
    }
    if textView.syntaxHighlightingUpdate != self.settings.syntaxHighlightingUpdate {
      textView.textStorageDelegate.highlight(textView.textStorage)
    }
    if let update = self.update {
      update(textView)
      DispatchQueue.main.async {
        self.update = nil
      }
    }
    ConsoleEditor.recalculateHeight(textView: textView, result: self._calculatedHeight)
  }
  
  static func consoleHight(textView: UITextView) -> (CGFloat, Bool) {
    let newSize = textView.sizeThatFits(CGSize(width: textView.frame.size.width,
                                               height: CGFloat.greatestFiniteMagnitude))
    let heightMax: CGFloat
    if let currentOrigin = textView.superview?.convert(textView.frame.origin, to: nil) {
      heightMax = (currentOrigin.y + textView.frame.height) * 0.5
    } else {
      heightMax = 240
    }
    return newSize.height > heightMax ? (heightMax, true) : (newSize.height, false)
  }
  
  static func recalculateHeight(textView: UITextView, result: Binding<CGFloat>) {
    let (height, scrollEnabled) = Self.consoleHight(textView: textView)
    if result.wrappedValue != height {
      DispatchQueue.main.async {
        textView.isScrollEnabled = scrollEnabled
        result.wrappedValue = height
      }
    }
  }
}
