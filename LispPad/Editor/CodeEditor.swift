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
import MarkdownKit

struct CodeEditor: UIViewRepresentable {
  typealias Coordinator = CodeEditorTextViewDelegate
  
  @EnvironmentObject var docManager: DocumentationManager
  @EnvironmentObject var fileManager: FileManager
  @EnvironmentObject var settings: UserSettings

  @Binding var text: String
  @Binding var selectedRange: NSRange
  @Binding var focused: Bool
  @Binding var position: NSRange?
  @Binding var forceUpdate: Bool
  @Binding var update: ((CodeEditorTextView) -> Void)?
  @Binding var editorType: FileExtensions.EditorType
  @Binding var searchMatchCount: Int
  @ObservedObject var keyboardObserver: KeyboardObserver

  let searchPattern: SearchPattern
  let defineAction: ((Block) -> Void)?
  
  public func makeCoordinator() -> Coordinator {
    return CodeEditorTextViewDelegate(text: _text,
                                      selectedRange: _selectedRange,
                                      focused: _focused,
                                      fileManager: self.fileManager)
  }
  
  public func makeUIView(context: Context) -> CodeEditorTextView {
    let textView = CodeEditorTextView(frame: CGRect(x: 0,
                                                    y: 0,
                                                    width: 100000,
                                                    height: 1000000),
                                      console: false,
                                      editorType: self.editorType,
                                      docManager: self.docManager,
                                      defineAction: self.defineAction)
    textView.isScrollEnabled = true
    textView.isEditable = true
    textView.isSelectable = true
    textView.isUserInteractionEnabled = true
    textView.contentInsetAdjustmentBehavior = .automatic
    textView.keyboardDismissMode = // UIDevice.current.userInterfaceIdiom == .pad ? .none :
                                   .interactive
    textView.smartQuotesType = .no
    textView.smartDashesType = .no
    textView.smartInsertDeleteType = .no
    textView.textAlignment = .left
    textView.keyboardType = .default
    textView.autocapitalizationType = .none
    textView.autocorrectionType = .no
    textView.spellCheckingType = .no
    if #available(iOS 18.0, *) {
      textView.writingToolsBehavior = .none
    }
    textView.font = self.settings.editorFont
    textView.textColor = UIColor(named: "CodeEditorTextColor")
    let textInputTraits = textView.value(forKey: "textInputTraits") as? NSObject
    textInputTraits?.setValue(textView.tintColor, forKey: "insertionPointColor")
    textView.becomeFirstResponder()
    textView.text = self.text
    textView.selectedRange = self.selectedRange
    // Deferred to the next run loop turn (like the `forceUpdate`/`position` resets
    // below) since this closure can also fire synchronously from `updateUIView`
    // (e.g. `setSearchHighlight` clearing the term), and mutating a `@Binding` while
    // SwiftUI is still in the middle of that view update is undefined behavior.
    textView.searchMatchCountChanged = { count in
      DispatchQueue.main.async {
        self.searchMatchCount = count
      }
    }
    DispatchQueue.main.async {
      if let doc = self.fileManager.editorDocument {
        textView.becomeFirstResponder()
        textView.setContentOffset(doc.lastContentOffset, animated: false)
      }
      textView.delegate = context.coordinator
    }
    return textView
  }

  private func extend(_ range: NSRange, by lines: Int = 4, in textView: CodeEditorTextView) -> NSRange {
    guard lines > 0, range.location >= lines || range.length != 0 else {
      return range
    }
    let text = textView.text as NSString
    var i = range.location - 1
    var n = lines
    while n > 0 && i >= 0 {
      if text.character(at: i) == NEWLINE {
        n -= 1
      }
      i -= 1
    }
    if i < 0 {
      i = 0
    }
    var j = range.location + range.length
    n = lines
    while n > 0 && j < text.length {
      if text.character(at: j) == NEWLINE {
        n -= 1
      }
      j += 1
    }
    return NSRange(location: max(i, 0), length: j - i)
  }
  
  public func updateUIView(_ textView: CodeEditorTextView, context: Context) {
    textView.keyboard.setup(for: textView)
    if self.fileManager.requireEditorUpdate() {
      textView.text = self.text
      textView.refreshSearchHighlights()
      textView.selectedRange = NSRange(location: 0, length: 0)
      DispatchQueue.main.async {
        textView.becomeFirstResponder()
        textView.scrollRangeToVisible(self.extend(textView.selectedRange, in: textView))
      }
    }
    if textView.font != self.settings.editorFont {
      textView.font = self.settings.editorFont
    }
    if textView.showLineNumbers != self.settings.showLineNumbers {
      textView.showLineNumbers = self.settings.showLineNumbers
    }
    if textView.highlightCurrentLine != self.settings.highlightCurrentLine {
      textView.highlightCurrentLine = self.settings.highlightCurrentLine
    }
    textView.setSearchHighlight(pattern: self.searchPattern)
    if self.editorType != textView.textStorageDelegate.editorType {
      textView.textStorageDelegate.editorType = self.editorType
      textView.textStorageDelegate.highlight(textView.textStorage)
    } else if textView.syntaxHighlightingUpdate != self.settings.syntaxHighlightingUpdate {
      textView.textStorageDelegate.highlight(textView.textStorage)
    }
    if let pos = self.position {
      if self.forceUpdate {
        if let range = textView.textRange(from: textView.beginningOfDocument,
                                          to: textView.endOfDocument) {
          textView.replace(range, withText: self.text)
        } else {
          textView.text = self.text
        }
        textView.refreshSearchHighlights()
      }
      if UIDevice.current.userInterfaceIdiom == .pad {
        DispatchQueue.main.async {
          textView.becomeFirstResponder()
          textView.selectedRange = pos
          textView.scrollRangeToVisible(self.extend(pos, in: textView))
          self.position = nil
          self.forceUpdate = false
        }
      } else {
        DispatchQueue.main.async {
          textView.becomeFirstResponder()
          let keyboardViewEndFrame = textView.convert(self.keyboardObserver.rect,
                                                      from: textView.window)
          let bottomInset = keyboardViewEndFrame.height > 25.0 ?
            (keyboardViewEndFrame.height - (textView.window?.safeAreaInsets.bottom ?? 25.0)) : 0.0
          textView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: bottomInset, right: 0)
          textView.scrollIndicatorInsets = textView.contentInset
          textView.selectedRange = pos
          let pos = self.extend(pos, in: textView)
          textView.scrollRangeToVisible(pos)
          if let rect = self.textRangeRect(for: pos, in: textView),
             (rect.minY - textView.bounds.minY) > (textView.bounds.height - bottomInset) {
            let bounds = CGRect(x: textView.bounds.minX,
                                y: textView.bounds.minY + bottomInset,
                                width: textView.bounds.width,
                                height: textView.bounds.height - 4)
            textView.layoutIfNeeded()
            textView.scrollRectToVisible(bounds, animated: false)
          }
          self.position = nil
          self.forceUpdate = false
        }
      }
    } else if self.forceUpdate {
      textView.text = self.text
      textView.refreshSearchHighlights()
      DispatchQueue.main.async {
        self.forceUpdate = false
      }
    } else if let update = self.update {
      DispatchQueue.main.async {
        if self.update != nil {
          self.update = nil
          update(textView)
        }
      }
    } else /* if UIDevice.current.userInterfaceIdiom != .pad */ {
      let keyboardViewEndFrame = textView.convert(self.keyboardObserver.rect,
                                                  from: textView.window)
      let bottomInset = keyboardViewEndFrame.height > 25.0 ?
        (keyboardViewEndFrame.height - (textView.window?.safeAreaInsets.bottom ?? 25.0)) : 0.0
      // Only adjust the insets and scroll the selection into view if the keyboard
      // changed; `updateUIView` gets invoked for many unrelated state changes (e.g.
      // clearing the search term), and the editor must not jump back to the cursor
      // for those if the user scrolled elsewhere.
      if textView.contentInset.bottom < bottomInset {
        textView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: bottomInset, right: 0)
        textView.scrollIndicatorInsets = textView.contentInset
        textView.scrollRangeToVisible(self.extend(textView.selectedRange, in: textView))
      } else {
        textView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: bottomInset, right: 0)
        textView.scrollIndicatorInsets = textView.contentInset
      }
    }
  }
  
  private func textRangeRect(for range: NSRange, in textView: UITextView) -> CGRect? {
    guard let trange = self.textRange(from: range, in: textView) else {
      return nil
    }
    return textView.firstRect(for: trange)
  }
  
  private func textRange(from range: NSRange, in textView: UITextView) -> UITextRange? {
    let beginning = textView.beginningOfDocument
    guard let start = textView.position(from: beginning, offset: range.location),
          let end = textView.position(from: start, offset: range.length) else {
      return nil
    }
    return textView.textRange(from: start, to: end)
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
