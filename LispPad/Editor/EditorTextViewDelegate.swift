//
//  EditorTextViewDelegate.swift
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

class EditorTextViewDelegate: NSObject, UITextViewDelegate {
  
  static let parenBackground = UIColor(named: "ParenMatchingColor") ??
                                 UIColor(red: 0.87, green: 0.87, blue: 0.0, alpha: 1)
  
  @Binding var text: String
  @Binding var selectedRange: NSRange
  
  var lastSelectedRange: NSRange
  var backgroundDirty: Bool
  
  init(text: Binding<String>, selectedRange: Binding<NSRange>, lastSelectedRange: NSRange) {
    self._text = text
    self._selectedRange = selectedRange
    self.lastSelectedRange = lastSelectedRange
    self.backgroundDirty = false
  }
  
  open var highlightMatchingParen: Bool {
    return UserSettings.standard.highlightMatchingParen
  }
  
  open func textViewDidChange(_ textView: UITextView) {
    guard textView.markedTextRange == nil else {
      return
    }
    self.lastSelectedRange = textView.selectedRange
    DispatchQueue.main.async {
      self.text = textView.text ?? ""
      self.selectedRange = textView.selectedRange
    }
  }
  
  public func textViewDidChangeSelection(_ textView: UITextView) {
    if self.lastSelectedRange != textView.selectedRange {
      let nstext = textView.text as NSString
      if let layoutManager = textView.layoutManager as? CodeEditorLayoutManager,
         layoutManager.highlightCurrentLine {
        if self.lastSelectedRange.upperBound <= nstext.length {
          let lastLineRange = nstext.lineRange(for: self.lastSelectedRange)
          if textView.selectedRange.upperBound <= nstext.length {
            let newLineRange = nstext.lineRange(for: textView.selectedRange)
            if lastLineRange != newLineRange {
              layoutManager.invalidateDisplay(forCharacterRange: newLineRange)
              layoutManager.invalidateDisplay(forCharacterRange: lastLineRange)
            }
          }
        }
      }
      self.lastSelectedRange = textView.selectedRange
      DispatchQueue.main.async {
        self.selectedRange = textView.selectedRange
      }
      if self.lastSelectedRange.length == 0 {
        let beginning = textView.beginningOfDocument
        if self.lastSelectedRange.location > 0 {
          guard let start = textView.position(from: beginning,
                                              offset: self.lastSelectedRange.location - 1),
                let end = textView.position(from: start, offset: 1),
                let range = textView.textRange(from: start, to: end) else {
            return
          }
          switch textView.text(in: range) {
            case "(":
              self.highlight(RPAREN, LPAREN, back: false, in: textView,
                             at: self.lastSelectedRange.location)
            case "[":
              self.highlight(RBRACKET, LBRACKET, back: false, in: textView,
                             at: self.lastSelectedRange.location)
            case "{":
              self.highlight(RBRACE, LBRACE, back: false, in: textView,
                             at: self.lastSelectedRange.location)
            case ")":
              self.highlight(LPAREN, RPAREN, back: true, in: textView,
                             at: self.lastSelectedRange.location - 1)
            case "]":
              self.highlight(LBRACKET, RBRACKET, back: true, in: textView,
                             at: self.lastSelectedRange.location - 1)
            case "}":
              self.highlight(LBRACE, RBRACE, back: true, in: textView,
                             at: self.lastSelectedRange.location - 1)
            default:
              break
          }
        }
      }
    }
  }
  
  func schemeIndent(_ str: NSString, _ selectedRange: NSRange) -> String {
    // Find the beginning of the current line
    var start = selectedRange.location
    while start > 0 && str.character(at: start - 1) != NEWLINE {
      start -= 1
    }
    let lineStart = start
    // Construct indentation string
    var indent = ""
    loop: while start < selectedRange.location {
      switch str.character(at: start) {
        case SPACE:
          indent.append(" ")
        case TAB:
          indent.append("\t")
        default:
          break loop
      }
      start += 1
    }
    // Is this a comment-only line?
    if start < selectedRange.location && str.character(at: start) == SEMI {
      indent.append(";")
      start += 1
      while start < selectedRange.location && str.character(at: start) == SEMI {
        indent.append(";")
        start += 1
      }
      loop: while start < selectedRange.location {
        switch str.character(at: start) {
          case SPACE:
            indent.append(" ")
          case TAB:
            indent.append("\t")
          default:
            break loop
        }
        start += 1
      }
    } else {
      // Count open parenthesis in remaining line
      var parenBalance = 0
      var openParenPos = ContiguousArray<Int>()
      let oldStart = start
      while start < selectedRange.location {
        switch str.character(at: start) {
          case LPAREN:
            parenBalance += 1
            openParenPos.append(start)
          case RPAREN:
            parenBalance -= 1
            if openParenPos.count > 0 {
              openParenPos.removeLast()
            }
          default:
            break
        }
        start += 1
      }
      // Smart indentation based on open parenthesis
      if let lastPos = openParenPos.last {
        if lastPos + 1 < selectedRange.location && str.character(at: lastPos + 1) == LPAREN {
          indent.append(String(repeating: " ", count: lastPos - oldStart + 1))
        } else {
          indent.append(String(repeating: " ", count: lastPos - oldStart +
                                                      UserSettings.standard.indentSize))
        }
      // Smart indentation based on closed parenthesis
      } else if parenBalance < 0 {
        var maxSearch = 2000
        var lastParenPos = -1
        var 
        start = lineStart - 1
        while start > 0 && parenBalance <= 0 {
          maxSearch -= 1
          if maxSearch == 0 {
            if lastParenPos >= 0 {
              break
            } else {
              return indent
            }
          }
          start -= 1
          switch str.character(at: start) {
            case LPAREN:
              parenBalance += 1
            case RPAREN:
              parenBalance -= 1
            default:
              break
          }
          if parenBalance == 0 && lastParenPos < 0 {
            lastParenPos = start
          }
        }
        if parenBalance > 0 {
          indent = String(repeating: " ",
                          count: str.character(at: start + 1) == LPAREN
                                   ? 1 : UserSettings.standard.indentSize)
        } else if lastParenPos >= 0 {
          indent = ""
          start = lastParenPos
        } else {
          indent = ""
        }
        while start > 0 && str.character(at: start - 1) != NEWLINE {
          start -= 1
          switch str.character(at: start) {
            case TAB:
              indent.insert("\t", at: indent.startIndex)
            default:
              indent.insert(" ", at: indent.startIndex)
          }
        }
      }
    }
    return indent
  }
  
  func markdownIndent(_ str: NSString, _ selectedRange: NSRange) -> String {
    // Find the beginning of the current line
    var start = selectedRange.location
    while start > 0 && str.character(at: start - 1) != NEWLINE {
      start -= 1
    }
    // Construct indentation string
    var indent = ""
    loop: while start < selectedRange.location {
      switch str.character(at: start) {
        case SPACE:
          indent.append(" ")
        case TAB:
          indent.append("\t")
        default:
          break loop
      }
      start += 1
    }
    guard start < selectedRange.location else {
      return indent
    }
    switch str.character(at: start) {
      case GREATERE: // Blockquote
        indent.append(">")
        start += 1
        loop: while start < selectedRange.location {
          switch str.character(at: start) {
            case SPACE:
              indent.append(" ")
            case TAB:
              indent.append("\t")
            default:
              break loop
            }
            start += 1
        }
      case DASH, STAR: // Bullet point
        guard start + 2 < selectedRange.location && isSpaceOnly(str.character(at: start + 1)) else {
          break
        }
        indent.append(" ")
        start += 1
        loop: while start < selectedRange.location {
          switch str.character(at: start) {
            case SPACE:
              indent.append(" ")
            case TAB:
              indent.append("\t")
            default:
              break loop
          }
          start += 1
        }
      case D0, D1, D2, D3, D4, D5, D6, D7, D8, D9:  // Enumeration item
        var enumItemIndent = " "
        start += 1
        scan: while start < selectedRange.location {
          switch str.character(at: start) {
            case D0, D1, D2, D3, D4, D5, D6, D7, D8, D9:
              enumItemIndent.append(" ")
              start += 1
            default:
              break scan
          }
        }
        guard start + 2 < selectedRange.location &&
              str.character(at: start) == DOT &&
              isSpaceOnly(str.character(at: start + 1)) else {
          break
        }
        indent += enumItemIndent
        indent += " "
        start += 1
        loop: while start < selectedRange.location {
          switch str.character(at: start) {
            case SPACE:
              indent.append(" ")
            case TAB:
              indent.append("\t")
            default:
              break loop
          }
          start += 1
        }
      default:
        break
    }
    return indent
  }
  
  open func textView(_ textView: UITextView,
                     shouldChangeTextIn range: NSRange,
                     replacementText text: String) -> Bool {
    switch text {
      case ")":
        return self.highlight(LPAREN, RPAREN, back: true, in: textView, at: range, text: text)
      case "(":
        return self.highlight(RPAREN, LPAREN, back: false, in: textView, at: range, text: text)
      case "]":
        return self.highlight(LBRACKET, RBRACKET, back: true, in: textView, at: range, text: text)
      case "[":
        return self.highlight(RBRACKET, LBRACKET, back: false, in: textView, at: range, text: text)
      case "}":
        return self.highlight(LBRACE, RBRACE, back: true, in: textView, at: range, text: text)
      case "{":
        return self.highlight(RBRACE, LBRACE, back: false, in: textView, at: range, text: text)
      default:
        if self.backgroundDirty {
          textView.textStorage.removeAttribute(.backgroundColor,
                                               range: NSRange(location: 0,
                                                              length: textView.textStorage.length))
          self.backgroundDirty = false
        }
        return true
    }
  }
  
  func highlight(_ ch: UniChar,
                 _ this: UniChar,
                 back: Bool,
                 in textView: UITextView,
                 at range: NSRange,
                 text: String?) -> Bool {
    if self.highlightMatchingParen,
       let replaceStart = textView.position(from: textView.beginningOfDocument,
                                           offset: range.location),
       let replaceEnd = textView.position(from: replaceStart, offset: range.length),
       let textRange = textView.textRange(from: replaceStart, to: replaceEnd) {
      if let str = text {
        textView.replace(textRange, withText: str)
      }
      self.highlight(ch, this, back: back, in: textView, at: range.location)
      return false
    }
    return true
  }
  
  func highlight(_ ch: UniChar,
                 _ this: UniChar,
                 back: Bool,
                 in textView: UITextView,
                 at iloc: Int) {
    if self.highlightMatchingParen {
      let str = textView.text as NSString
      let loc = back ? TextFormatter.find(ch, matching: this, from: iloc, to: 0, in: str)
                     : TextFormatter.find(ch, matching: this, from: iloc, to: str.length, in: str)
      if loc >= 0 {
        let storage = textView.textStorage
        storage.removeAttribute(.backgroundColor,
                                range: NSRange(location: 0, length: storage.length))
        storage.addAttribute(.backgroundColor,
                             value: Self.parenBackground,
                             range: NSRange(location: loc, length: 1))
        self.backgroundDirty = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6, qos: .userInitiated, flags: []) {
          if self.backgroundDirty {
            storage.removeAttribute(.backgroundColor,
                                    range: NSRange(location: 0, length: storage.length))
            self.backgroundDirty = false
          }
        }
      }
    }
  }
}
