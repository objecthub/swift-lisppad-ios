//
//  CodeEditor.swift
//  LispPad
//
//  Created by Matthias Zenger on 28/03/2021.
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

struct CodeEditor: UIViewRepresentable {
  typealias Coordinator = CodeEditorTextViewDelegate
  
  @EnvironmentObject var docManager: DocumentationManager
  @EnvironmentObject var fileManager: FileManager
  @EnvironmentObject var settings: UserSettings

  @Binding var text: String
  @Binding var selectedRange: NSRange
  @Binding var position: NSRange?
  @Binding var forceUpdate: Bool
  @Binding var editorType: FileExtensions.EditorType
  
  public init(text: Binding<String>,
              selectedRange: Binding<NSRange>,
              position: Binding<NSRange?>,
              forceUpdate: Binding<Bool>,
              editorType: Binding<FileExtensions.EditorType>) {
    self._text = text
    self._selectedRange = selectedRange
    self._position = position
    self._forceUpdate = forceUpdate
    self._editorType = editorType
  }

  public func makeCoordinator() -> Coordinator {
    return CodeEditorTextViewDelegate(text: _text,
                                      selectedRange: _selectedRange,
                                      fileManager: self.fileManager)
  }
  
  public func makeUIView(context: Context) -> CodeEditorTextView {
    let textView = CodeEditorTextView(frame: CGRect(x: 0,
                                                    y: 0,
                                                    width: 100000,
                                                    height: 1000000),
                                      editorType: self.editorType,
                                      docManager: docManager)
    textView.isScrollEnabled = true
    textView.isEditable = true
    textView.isSelectable = true
    textView.isUserInteractionEnabled = true
    textView.smartQuotesType = .no
    textView.smartDashesType = .no
    textView.smartInsertDeleteType = .no
    textView.textAlignment = .left
    textView.keyboardType = .default
    textView.autocapitalizationType = .none
    textView.autocorrectionType = .no
    textView.font = self.settings.editorFont
    textView.textColor = UIColor(named: "CodeEditorTextColor")
    let textInputTraits = textView.value(forKey: "textInputTraits") as? NSObject
    textInputTraits?.setValue(textView.tintColor, forKey: "insertionPointColor")
    textView.becomeFirstResponder()
    textView.text = self.text
    textView.selectedRange = self.selectedRange
    DispatchQueue.main.async {
      if let doc = self.fileManager.editorDocument {
        textView.becomeFirstResponder()
        textView.setContentOffset(doc.lastContentOffset, animated: false)
      }
      textView.delegate = context.coordinator
    }
    return textView
  }

  public func updateUIView(_ textView: CodeEditorTextView, context: Context) {
    if self.fileManager.requireEditorUpdate() {
      textView.text = self.text
      textView.selectedRange = NSRange(location: 0, length: 0)
      DispatchQueue.main.async {
        textView.becomeFirstResponder()
        textView.scrollRangeToVisible(textView.selectedRange)
      }
    }
    if textView.font != self.settings.editorFont {
      textView.font = self.settings.editorFont
    }
    if textView.showLineNumbers != self.settings.showLineNumbers {
      textView.showLineNumbers = self.settings.showLineNumbers
    }
    if self.editorType != textView.textStorageDelegate.editorType {
      textView.textStorageDelegate.editorType = self.editorType
      textView.textStorageDelegate.highlight(textView.textStorage)
    } else if textView.syntaxHighlightingUpdate != self.settings.syntaxHighlightingUpdate {
      textView.textStorageDelegate.highlight(textView.textStorage)
    }
    if let pos = self.position {
      if self.forceUpdate {
        textView.text = self.text
      }
      textView.selectedRange = pos
      DispatchQueue.main.async {
        textView.becomeFirstResponder()
        textView.selectedRange = pos
        textView.scrollRangeToVisible(pos)
        self.position = nil
        self.forceUpdate = false
      }
    } else if self.forceUpdate {
      textView.text = self.text
      DispatchQueue.main.async {
        self.forceUpdate = false
      }
    }
  }
  
  private func visibleRange(of textView: UITextView) -> NSRange {
    let bounds = textView.bounds
    let origin = CGPoint(x: 10, y: 10)
    guard let startCharacterRange = textView.characterRange(at: origin) else {
      return NSRange(location: 0, length: 0)
    }
    let startPosition = startCharacterRange.start
    let endPoint = CGPoint(x: bounds.maxX, y: bounds.maxY)
    guard let endCharacterRange = textView.characterRange(at: endPoint) else {
      return NSRange(location: 0, length: 0)
    }
    let endPosition = endCharacterRange.end
    let startIndex = textView.offset(from: textView.beginningOfDocument, to: startPosition)
    let endIndex = textView.offset(from: startPosition, to: endPosition)
    return NSRange(location: startIndex, length: endIndex)
  }
}
