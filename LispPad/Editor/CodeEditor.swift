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
  @ObservedObject var keyboardObserver: KeyboardObserver
  
  public func makeCoordinator() -> Coordinator {
    return CodeEditorTextViewDelegate(text: _text,
                                      selectedRange: _selectedRange,
                                      fileManager: self.fileManager)
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
    button.addTarget(textView, action: #selector(textView.keyboardButtonPressed(_:)), for: .touchUpInside)
    let item = UIBarButtonItem(customView: button)
    item.tag = tag.rawValue
    return item
  }
  
  private func setupKeyboard(for textView: CodeEditorTextView) {
    if UIDevice.current.userInterfaceIdiom == .pad {
      if self.settings.extendedKeyboard {
        guard textView.inputAssistantItem.trailingBarButtonGroups.isEmpty ||
              textView.inputAssistantItem.trailingBarButtonGroups.last!
                      .barButtonItems.count != 8 else {
          return
        }
        let dash = self.textButton("-", tag: .dash, to: textView)
        let times = self.textButton("*", tag: .times, to: textView)
        let quote = self.textButton("'", tag: .quote, to: textView)
        let doubleQuote = self.textButton("\"", tag: .doubleQuote, to: textView)
        let parenLeft = self.textButton("(", tag: .parenLeft, to: textView)
        let parenRight = self.textButton(")", tag: .parenRight, to: textView)
        let equals = self.textButton("=", tag: .equals, to: textView)
        let question = self.textButton("?", tag: .question, to: textView)
        let items = UIBarButtonItemGroup(barButtonItems: [dash, times, quote, doubleQuote,
                                                          parenLeft, parenRight, equals, question],
                                         representativeItem: nil)
        textView.inputAssistantItem.trailingBarButtonGroups.append(items)
      } else if let last = textView.inputAssistantItem.trailingBarButtonGroups.last,
                last.barButtonItems.count == 8 {
        textView.inputAssistantItem.trailingBarButtonGroups.removeLast()
      }
    } else {
      if self.settings.extendedKeyboard {
        if let accessoryView = textView.inputAccessoryView {
          if accessoryView.isHidden {
            accessoryView.isHidden = false
            textView.isUserInteractionEnabled = true
          }
          return
        }
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
        let bar = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 35))
        bar.barStyle = .default
        bar.isTranslucent = false
        bar.barTintColor = UIColor(named: "KeyboardColor")
        bar.autoresizingMask = UIView.AutoresizingMask.flexibleRightMargin.union(.flexibleWidth)
        bar.setItems([dash, UIBarButtonItem.fixedSpace(6), times, UIBarButtonItem.fixedSpace(6),
                      quote, UIBarButtonItem.fixedSpace(6), doubleQuote,
                      UIBarButtonItem.fixedSpace(6), parenLeft, UIBarButtonItem.fixedSpace(6),
                      parenRight, UIBarButtonItem.fixedSpace(6), equals,
                      UIBarButtonItem.fixedSpace(6), question, UIBarButtonItem.flexibleSpace(),
                      ibutton], animated: false)
        bar.isUserInteractionEnabled = true
        bar.sizeToFit()
        textView.inputAccessoryView = bar
        // bar.frame = CGRect(x: 0, y: 0, width: 13 * (32 + 6) + 8, height: bar.frame.size.height)
        /* let scrollView = UIScrollView()
        scrollView.frame = bar.frame
        scrollView.bounds = bar.bounds
        scrollView.autoresizingMask = UIView.AutoresizingMask.flexibleWidth.union(UIView.AutoresizingMask.flexibleRightMargin)
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.bounces = false
        scrollView.contentSize = bar.frame.size
        scrollView.addSubview(bar) */
        // textView.inputAccessoryView = scrollView
      } else if let accessoryView = textView.inputAccessoryView {
        if !accessoryView.isHidden {
          accessoryView.isHidden = true
          textView.isUserInteractionEnabled = false
        }
      }
    }
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
    textView.font = self.settings.editorFont
    textView.textColor = UIColor(named: "CodeEditorTextColor")
    let textInputTraits = textView.value(forKey: "textInputTraits") as? NSObject
    textInputTraits?.setValue(textView.tintColor, forKey: "insertionPointColor")
    // self.setupKeyboard(for: textView)
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
    self.setupKeyboard(for: textView)
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
      if UIDevice.current.userInterfaceIdiom == .pad {
        textView.becomeFirstResponder()
        textView.selectedRange = pos
        textView.scrollRangeToVisible(pos)
        DispatchQueue.main.async {
          self.position = nil
          self.forceUpdate = false
        }
      } else {
        textView.becomeFirstResponder()
        let keyboardViewEndFrame = textView.convert(self.keyboardObserver.rect,
                                                    from: textView.window)
        let bottomInset = keyboardViewEndFrame.height > 25.0 ?
          (keyboardViewEndFrame.height - (textView.window?.safeAreaInsets.bottom ?? 25.0)) : 0.0
        textView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: bottomInset, right: 0)
        textView.scrollIndicatorInsets = textView.contentInset
        textView.selectedRange = pos
        textView.scrollRangeToVisible(pos)
        DispatchQueue.main.async {
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
      DispatchQueue.main.async {
        self.forceUpdate = false
      }
    } else if UIDevice.current.userInterfaceIdiom != .pad {
      let keyboardViewEndFrame = textView.convert(self.keyboardObserver.rect,
                                                  from: textView.window)
      let bottomInset = keyboardViewEndFrame.height > 25.0 ?
        (keyboardViewEndFrame.height - (textView.window?.safeAreaInsets.bottom ?? 25.0)) : 0.0
      textView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: bottomInset, right: 0)
      textView.scrollIndicatorInsets = textView.contentInset
      textView.scrollRangeToVisible(textView.selectedRange)
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
