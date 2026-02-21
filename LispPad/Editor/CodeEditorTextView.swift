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
import MarkdownKit

class CodeEditorTextView: UITextView, UIEditMenuInteractionDelegate {

  /// The width of the gutter
  static let gutterWidth: CGFloat = 31.0

  /// The gutter bezier path
  static let gutterPath: UIBezierPath = UIBezierPath(rect:
                                          CGRect(x: 0.0, y: 0.0,
                                                 width: CodeEditorTextView.gutterWidth,
                                                 height: CGFloat.greatestFiniteMagnitude))

  /// Direct access to the text storage delegate
  let textStorageDelegate: CodeEditorTextStorageDelegate

  /// Action executed when "define" is selected from the input menu and the selected
  /// identifier has documentation.
  let defineAction: ((Block) -> Void)?
  
  /// Action executed when "return" is pressed on a hardware keyboard
  let returnAction: (() -> Void)?
  
  /// Returns true if the returnAction should be used
  let customReturn: () -> Bool
  
  /// Show line numbers?
  private var internalShowLineNumbers: Bool
  
  /// Highlight current line?
  private var internalHighlightCurrentLine: Bool

  /// When was the last syntax highlighting settings change?
  var syntaxHighlightingUpdate: Date

  let keyboard: CodeEditorKeyboard

  var highlightCurrentLine: Bool {
    get {
      return self.internalHighlightCurrentLine
    }
    set(newVal) {
      if self.internalHighlightCurrentLine != newVal {
        let lm = self.layoutManager as! CodeEditorLayoutManager
        lm.highlightCurrentLine = newVal
        self.internalHighlightCurrentLine = newVal
        self.setNeedsDisplay()
      }
    }
  }
  
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
       console: Bool,
       editorType: FileExtensions.EditorType,
       docManager: DocumentationManager,
       defineAction: ((Block) -> Void)? = nil,
       returnAction: (() -> Void)? = nil,
       customReturn: @escaping () -> Bool = { false }) {
    let ts = NSTextStorage()
    let td = CodeEditorTextStorageDelegate(console: console,
                                           editorType: editorType,
                                           docManager: docManager)
    let lm = CodeEditorLayoutManager(console: console)
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
    self.internalHighlightCurrentLine = lm.highlightCurrentLine
    self.syntaxHighlightingUpdate = UserSettings.standard.syntaxHighlightingUpdate
    self.defineAction = defineAction
    self.returnAction = returnAction
    self.customReturn = customReturn
    self.keyboard = CodeEditorKeyboard(console: console, editorType: editorType)
    super.init(frame: frame, textContainer: tc)
    lm.textView = self
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
  
  override var keyCommands: [UIKeyCommand]? {
    if self.customReturn() {
      if let commands = super.keyCommands {
        return commands + [
          UIKeyCommand(input: "\r", 
                       modifierFlags: [],
                       action: #selector(handleReturn))
        ]
      } else {
        return [
          UIKeyCommand(input: "\r", 
                       modifierFlags: [],
                       action: #selector(handleReturn))
        ]
      }
    } else {
      return super.keyCommands
    }
  }
  
  @objc private func handleReturn() {
    if let action = self.returnAction {
      self.textStorage.removeAttribute(.backgroundColor,
                                       range: NSRange(location: 0, length: self.textStorage.length))
      action()
    }
  }
  
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

  func selectedName(for range: NSRange? = nil) -> String? {
    let range = self.nameRange(for: range)
    guard case 1...50 = range.length else {
      return nil
    }
    let name = self.textStorage.attributedSubstring(from: range)
                               .string
                               .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    return name.isEmpty ? nil : name
  }

  func nameRange(for range: NSRange? = nil) -> NSRange {
    if let range = range {
      return range
    } else {
      let range = self.selectedRange
      return range.length == 0 ? TextFormatter.nameRange(in: self.text as NSString,
                                                         at: range.location) : range
    }
  }

  @objc func keyboardButtonPressed(_ sender: UIButton) {
    switch sender.tag {
      case CodeEditorKeyboard.KeyTag.toggleKeyboard.rawValue:
        self.keyboard.toggleKeyboard(for: self)
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
      case CodeEditorKeyboard.KeyTag.backquote.rawValue:
        self.insertText("`")
      case CodeEditorKeyboard.KeyTag.underscore.rawValue:
        self.insertText("_")
      case CodeEditorKeyboard.KeyTag.indent.rawValue:
        self.indent()
      case CodeEditorKeyboard.KeyTag.undent.rawValue:
        self.outdent()
      case CodeEditorKeyboard.KeyTag.comment.rawValue:
        self.comment()
      case CodeEditorKeyboard.KeyTag.uncomment.rawValue:
        self.uncomment()
      case CodeEditorKeyboard.KeyTag.cursorLeft.rawValue:
        self.moveCursor(direction: .left)
      case CodeEditorKeyboard.KeyTag.cursorRight.rawValue:
        self.moveCursor(direction: .right)
      case CodeEditorKeyboard.KeyTag.cursorUp.rawValue:
        self.moveCursor(direction: .up)
      case CodeEditorKeyboard.KeyTag.cursorDown.rawValue:
        self.moveCursor(direction: .down)
      case CodeEditorKeyboard.KeyTag.undo.rawValue:
        self.undoManager?.undo()
      case CodeEditorKeyboard.KeyTag.redo.rawValue:
        self.undoManager?.redo()
      default:
        self.resignFirstResponder()
    }
  }
  
  private enum CursorDirection {
    case left, right, up, down
  }
  
  private func moveCursor(direction: CursorDirection) {
    let currentPosition = self.selectedRange.location
    var newPosition: Int?
    switch direction {
      case .left:
        if currentPosition > 0 {
          newPosition = currentPosition - 1
        }
      case .right:
        if currentPosition < self.text.count {
          newPosition = currentPosition + 1
        }
      case .up:
        if let position = self.position(from: self.beginningOfDocument, offset: currentPosition),
           let targetPosition = self.position(from: position, in: .up, offset: 1) {
          newPosition = self.offset(from: self.beginningOfDocument, to: targetPosition)
        }
      case .down:
        if let position = self.position(from: self.beginningOfDocument, offset: currentPosition),
           let targetPosition = self.position(from: position, in: .down, offset: 1) {
          newPosition = self.offset(from: self.beginningOfDocument, to: targetPosition)
        }
    }
    if let newPosition = newPosition {
      self.selectedRange = NSRange(location: newPosition, length: 0)
      if self.position(from: self.beginningOfDocument, offset: newPosition) != nil {
        self.scrollRangeToVisible(NSRange(location: newPosition, length: 0))
      }
    }
  }
  
  override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
    switch action {
      case  #selector(UIResponderStandardEditActions.toggleBoldface(_:)),
            #selector(UIResponderStandardEditActions.toggleItalics(_:)),
            #selector(UIResponderStandardEditActions.toggleUnderline(_:)),
            #selector(UIResponderStandardEditActions.decreaseSize(_:)),
            #selector(UIResponderStandardEditActions.increaseSize(_:)),
            #selector(UIResponderStandardEditActions.makeTextWritingDirectionRightToLeft(_:)),
            #selector(UIResponderStandardEditActions.makeTextWritingDirectionLeftToRight(_:)):
        return false
      default:
        return super.canPerformAction(action, withSender: sender)
    }
  }
  
  override func editMenu(for textRange: UITextRange, suggestedActions: [UIMenuElement]) -> UIMenu? {
    var editMenu: UIMenu? = nil
    var shareMenu: UIMenu? = nil
    for elem in suggestedActions {
      if let menu = elem as? UIMenu {
        if menu.identifier == UIMenu.Identifier("com.apple.menu.standard-edit") {
          editMenu = menu
        } else if menu.identifier == UIMenu.Identifier("com.apple.menu.share") {
          shareMenu = menu
        }
      }
    }
    var actions: [UIMenuElement] = []
    if let editMenu {
      actions.append(editMenu)
    }
    if self.defineAction != nil,
       let name = self.selectedName(),
       let tsdelegate = self.textStorage.delegate as? CodeEditorTextStorageDelegate,
       tsdelegate.docManager.hasDocumentation(for: name) {
      actions.append(UIAction(title: "Define",
                              image: UIImage(systemName: "questionmark")) { [weak self] action in
        self?.define()
      })
    }
    if self.text.count > 0 {
      actions.append(UIMenu(identifier: UIMenu.Identifier("net.objecthub.lisppad.shift"),
                            options: .displayInline,
                            children: [
        UIAction(title: "Indent",
                 image: UIImage(systemName: "increase.indent")) { [weak self] action in
          self?.indent()
        },
        UIAction(title: "Outdent",
                 image: UIImage(systemName: "decrease.indent")) { [weak self] action in
          self?.outdent()
        },
        UIAction(title: "Comment",
                 image: UIImage(systemName: "text.bubble")) { [weak self] action in
          self?.comment()
        },
        UIAction(title: "Uncomment",
                 image: UIImage(systemName: "bubble.left")) { [weak self] action in
          self?.uncomment()
        }
      ]))
    }
    if let shareMenu {
      actions.append(shareMenu)
    }
    return UIMenu(children: actions)
  }

  func define() {
    guard let action = self.defineAction,
          let name = self.selectedName(),
          let tsdelegate = self.textStorage.delegate as? CodeEditorTextStorageDelegate,
          let documentation = tsdelegate.docManager.documentation(for: name) else {
      return
    }
    action(documentation)
  }

  func indent() {
    let selRange = TextFormatter.indent(textView: self, with: " ")
    self.selectedRange = selRange
    if let delegate = self.delegate as? ConsoleEditorTextViewDelegate {
      delegate.text = self.textStorage.string
      delegate.selectedRange = selRange
    }
  }

  func outdent() {
    if let selRange = TextFormatter.outdent(textView: self, with: " ") {
      self.selectedRange = selRange
      if let delegate = self.delegate as? ConsoleEditorTextViewDelegate {
        self.selectedRange = selRange
        delegate.text = self.textStorage.string
        delegate.selectedRange = selRange
      }
    }
  }

  func comment() {
    let selRange = TextFormatter.indent(textView: self, with: ";")
    self.selectedRange = selRange
    if let delegate = self.delegate as? ConsoleEditorTextViewDelegate {
      delegate.text = self.textStorage.string
      delegate.selectedRange = selRange
    }
  }

  func uncomment() {
    if let selRange = TextFormatter.outdent(textView: self, with: ";") {
      self.selectedRange = selRange
      if let delegate = self.delegate as? ConsoleEditorTextViewDelegate {
        delegate.text = self.textStorage.string
        delegate.selectedRange = selRange
      }
    }
  }
}
