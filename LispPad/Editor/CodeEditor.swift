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

  @Binding var text: String
  @Binding var selectedRange: NSRange
  @Binding var position: NSRange?
  @Binding var forceUpdate: Bool
  
  var autocapitalizationType: UITextAutocapitalizationType = .sentences
  var autocorrectionType: UITextAutocorrectionType = .default
  private(set) var backgroundColor: UIColor? = nil
  private(set) var color: UIColor? = nil
  private(set) var font: UIFont? = nil
  private(set) var insertionPointColor: UIColor? = nil
  var keyboardType: UIKeyboardType = .default
  
  public init(text: Binding<String>,
              selectedRange: Binding<NSRange>,
              position: Binding<NSRange?>,
              forceUpdate: Binding<Bool>) {
    self._text = text
    self._selectedRange = selectedRange
    self._position = position
    self._forceUpdate = forceUpdate
  }

  public func makeCoordinator() -> Coordinator {
    return CodeEditorTextViewDelegate(text: _text,
                                      selectedRange: _selectedRange,
                                      fileManager: self.fileManager)
  }
  
  public func makeUIView(context: Context) -> UITextView {
    let textView = CodeEditorTextView(frame: CGRect(x: 0,
                                                    y: 0,
                                                    width: CGFloat.greatestFiniteMagnitude,
                                                    height: CGFloat.greatestFiniteMagnitude),
                                      docManager: docManager)
    textView.isScrollEnabled = true
    textView.isEditable = true
    textView.isSelectable = true
    textView.isUserInteractionEnabled = true
    textView.smartQuotesType = .no
    textView.smartDashesType = .no
    textView.smartInsertDeleteType = .no
    textView.textAlignment = .left // or .natural ?
    textView.keyboardType = keyboardType
    textView.autocapitalizationType = autocapitalizationType
    textView.autocorrectionType = autocorrectionType
    if let color = self.backgroundColor {
      textView.backgroundColor = color
    }
    if let font = self.font {
      textView.font = font
    }
    textView.textColor = UIColor(named: "CodeEditorTextColor")
    textView.tintColor = insertionPointColor ?? textView.tintColor
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

  public func updateUIView(_ uiView: UITextView, context: Context) {
    if let pos = self.position {
      if self.forceUpdate {
        uiView.text = self.text
      }
      uiView.selectedRange = pos
      DispatchQueue.main.async {
        uiView.becomeFirstResponder()
        uiView.selectedRange = pos
        uiView.scrollRangeToVisible(pos)
        self.position = nil
        self.forceUpdate = false
      }
    } else if self.forceUpdate {
      uiView.text = self.text
      /* uiView.selectedRange = self.selectedRange
      var offset: CGPoint? = nil
      if let doc = self.fileManager.editorDocument {
        offset = doc.lastContentOffset
        print("content offset = \(offset!)")
        uiView.setContentOffset(offset!, animated: false)
      } */
      DispatchQueue.main.async {
        // uiView.becomeFirstResponder()
        /* if offset != nil {
          print("  -> setContentOffset(\(offset!))")
          uiView.setContentOffset(offset!, animated: false)
        } */
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

/// CodeEditor-specific modifiers
extension CodeEditor {
  public func autocapitalizationType(_ type: UITextAutocapitalizationType) -> Self {
    var new = self
    new.autocapitalizationType = type
    return new
  }
  
  public func autocorrectionType(_ type: UITextAutocorrectionType) -> Self {
    var new = self
    new.autocorrectionType = type
    return new
  }
  
  public func backgroundColor(_ color: UIColor) -> Self {
    var new = self
    new.backgroundColor = color
    return new
  }
  
  public func defaultColor(_ color: UIColor) -> Self {
    var new = self
    new.color = color
    return new
  }
  
  public func defaultFont(_ font: UIFont) -> Self {
    var new = self
    new.font = font
    return new
  }
  
  public func keyboardType(_ type: UIKeyboardType) -> Self {
    var new = self
    new.keyboardType = type
    return new
  }
  
  public func insertionPointColor(_ color: UIColor) -> Self {
    var new = self
    new.insertionPointColor = color
    return new
  }
}
