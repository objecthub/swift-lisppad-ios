//
//  CodeEditorTextView.swift
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

import UIKit

class CodeEditorTextView: UITextView {

  /// The width of the gutter
  static let gutterWidth: CGFloat = 31.0

  /// The gutter bezier path
  static let gutterPath: UIBezierPath = UIBezierPath(rect:
                                          CGRect(x: 0.0, y: 0.0,
                                                 width: CodeEditorTextView.gutterWidth,
                                                 height: CGFloat.greatestFiniteMagnitude))

  /// Direct access to the text storage delegate
  let textStorageDelegate: CodeEditorTextStorageDelegate

  /// Show line numbers?
  private var internalShowLineNumbers: Bool

  /// When was the last syntax highlighting settings change?
  var syntaxHighlightingUpdate: Date

  var showLineNumbers: Bool {
    get {
      return self.internalShowLineNumbers
    }
    set(newVal) {
      if self.internalShowLineNumbers != newVal {
        let lm = self.layoutManager as! CodeEditorLayoutManager
        lm.showLineNumbers = newVal
        self.internalShowLineNumbers = newVal
        if newVal {
          self.textContainer.exclusionPaths = [Self.gutterPath]
        } else {
          self.textContainer.exclusionPaths.removeAll()
        }
        self.setNeedsDisplay()
      }
    }
  }

  var codingFont: UIFont {
    get {
      let lm = self.layoutManager as! CodeEditorLayoutManager
      return lm.codingFont
    }
    set(newFont) {
      let lm = self.layoutManager as! CodeEditorLayoutManager
      if !lm.codingFont.isEqual(newFont) {
        lm.codingFont = newFont
        self.setNeedsDisplay()
      }
    }
  }
  
  var codingTextColor: UIColor {
    get {
      let lm = self.layoutManager as! CodeEditorLayoutManager
      return lm.codingTextColor
    }
    set(newColor) {
      let lm = self.layoutManager as! CodeEditorLayoutManager
      if !lm.codingTextColor.isEqual(newColor) {
        lm.codingTextColor = newColor
        self.setNeedsDisplay()
      }
    }
  }
  
  var codingBorderColor: UIColor = .lightGray {
    didSet {
      self.setNeedsDisplay()
    }
  }
  
  var codingBackgroundColor: UIColor = .secondarySystemBackground {
    didSet {
      self.setNeedsDisplay()
    }
  }
  
  init(frame: CGRect,
       editorType: FileExtensions.EditorType,
       docManager: DocumentationManager) {
    let ts = NSTextStorage()
    let td = CodeEditorTextStorageDelegate(editorType: editorType,
                                           docManager: docManager)
    let lm = CodeEditorLayoutManager()
    let tc = NSTextContainer(size: CGSize(width: CGFloat.greatestFiniteMagnitude,
                                          height: CGFloat.greatestFiniteMagnitude))
    tc.widthTracksTextView = true
    if lm.showLineNumbers {
      tc.exclusionPaths = [Self.gutterPath]
    }
    lm.addTextContainer(tc)
    ts.addLayoutManager(lm)
    ts.delegate = td
    self.textStorageDelegate = td
    self.internalShowLineNumbers = lm.showLineNumbers
    self.syntaxHighlightingUpdate = UserSettings.standard.syntaxHighlightingUpdate
    super.init(frame: frame, textContainer: tc)
    self.backgroundColor = .clear
    self.contentMode = .redraw
  }
  
  required init(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  /* DOES NOT WORK! Why?
   
  private lazy var codeEditorTokenizer = CodeEditorTextTokenizer(textInput: self)

  override var tokenizer: UITextInputTokenizer {
    return self.codeEditorTokenizer
  }
  */
  
  override func draw(_ rect: CGRect) {
    if self.showLineNumbers,
       let context: CGContext = UIGraphicsGetCurrentContext() {
      let bounds = self.bounds
      context.setFillColor(self.codingBackgroundColor.cgColor)
      context.fill(CGRect(x: bounds.origin.x,
                          y: bounds.origin.y,
                          width: CodeEditorTextView.gutterWidth,
                          height: bounds.size.height))
      context.setStrokeColor(self.codingBorderColor.cgColor);
      context.setLineWidth(0.2);
      context.stroke(CGRect(x: bounds.origin.x + CodeEditorTextView.gutterWidth - 0.8,
                            y: bounds.origin.y,
                            width: 0.2,
                            height: bounds.height))
      self.layoutManager.drawBackground(forGlyphRange: NSRange(location: 0, length: 0),
                                        at: CGPoint(x: 0, y: 8))
    }
    super.draw(rect)
  }
  
  @objc func keyboardButtonPressed(_ sender: UIButton) {
    switch sender.tag {
      case CodeEditorKeyboard.KeyTag.dash.rawValue:
        self.insertText("-")
      case CodeEditorKeyboard.KeyTag.times.rawValue:
        self.insertText("*")
      case CodeEditorKeyboard.KeyTag.quote.rawValue:
        self.insertText("'")
      case CodeEditorKeyboard.KeyTag.doubleQuote.rawValue:
        self.insertText("\"")
      case CodeEditorKeyboard.KeyTag.parenLeft.rawValue:
        self.insertText("(")
      case CodeEditorKeyboard.KeyTag.parenRight.rawValue:
        self.insertText(")")
      case CodeEditorKeyboard.KeyTag.equals.rawValue:
        self.insertText("=")
      case CodeEditorKeyboard.KeyTag.question.rawValue:
        self.insertText("?")
      case CodeEditorKeyboard.KeyTag.hash.rawValue:
        self.insertText("#")
      default:
        self.resignFirstResponder()
    }
  }
}
