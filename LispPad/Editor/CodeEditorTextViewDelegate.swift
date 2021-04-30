//
//  CodeEditorTextViewDelegate.swift
//  LispPad
//
//  Created by Matthias Zenger on 04/04/2021.
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

class CodeEditorTextViewDelegate: NSObject, UITextViewDelegate {
  @Binding var text: String
  @Binding var selectedRange: NSRange
  let fileManager: FileManager
  var lastSelectedRange = NSRange(location: 0, length: 0)
  
  let parenBackground = UIColor(red: 0.87, green: 0.87, blue: 0.0, alpha: 1)
  
  init(text: Binding<String>, selectedRange: Binding<NSRange>, fileManager: FileManager) {
    self._text = text
    self._selectedRange = selectedRange
    self.fileManager = fileManager
  }
  
  public func textViewDidChange(_ textView: UITextView) {
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
      self.lastSelectedRange = textView.selectedRange
      DispatchQueue.main.async {
        self.selectedRange = textView.selectedRange
      }
    }
  }
  
  public func scrollViewDidScroll(_ scrollView: UIScrollView) {
    self.fileManager.editorDocument?.lastContentOffset = scrollView.contentOffset
  }
  
  private func schemeIndent(_ str: NSString, _ selectedRange: NSRange) -> String {
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
          indent.append(String(repeating: " ", count: lastPos - oldStart + 2))
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
          indent = String(repeating: " ", count: str.character(at: start + 1) == LPAREN ? 1 : 2)
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
  
  private func markdownIndent(_ str: NSString, _ selectedRange: NSRange) -> String {
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
  
  public func textView(_ textView: UITextView,
                       shouldChangeTextIn range: NSRange,
                       replacementText text: String) -> Bool {
    switch text {
      case "\n":
        let indent: String
        switch self.fileManager.editorDocument?.editorType ?? .scheme {
          case .scheme:
            indent = schemeIndent(textView.textStorage.string as NSString, range)
          case .markdown:
            indent = markdownIndent(textView.textStorage.string as NSString, range)
          case .other:
            indent = ""
        }
        if let replaceStart = textView.position(from: textView.beginningOfDocument,
                                                offset: range.location),
            let replaceEnd = textView.position(from: replaceStart, offset: range.length),
            let textRange = textView.textRange(from: replaceStart, to: replaceEnd) {
          // textView.undoManager?.beginUndoGrouping()
          textView.replace(textRange, withText: "\n" + indent)
          // textView.undoManager?.endUndoGrouping()
          return false
        }
        return true
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
        return true
    }
  }
  
  private func highlight(_ ch: UniChar,
                         _ this: UniChar,
                         back: Bool,
                         in textView: UITextView,
                         at range: NSRange,
                         text: String) -> Bool {
    if let replaceStart = textView.position(from: textView.beginningOfDocument,
                                            offset: range.location),
        let replaceEnd = textView.position(from: replaceStart, offset: range.length),
        let textRange = textView.textRange(from: replaceStart, to: replaceEnd) {
      textView.replace(textRange, withText: text)
      let str = textView.text as NSString
      let loc = back ? self.find(ch, matching: this, from: range.location, to: 0, in: str)
                         : self.find(ch, matching: this, from: range.location, to: str.length,
                                     in: str)
      if loc >= 0 {
        let storage = textView.textStorage
        storage.removeAttribute(.backgroundColor,
                                range: NSRange(location: 0, length: storage.length))
        storage.addAttribute(.backgroundColor,
                             value: self.parenBackground,
                             range: NSRange(location: loc, length: 1))
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, qos: .userInitiated, flags: []) {
          storage.removeAttribute(.backgroundColor,
                                  range: NSRange(location: 0, length: storage.length))
        }
      }
      return false
    }
    return true
  }
  
  /// Find matching parenthesis between the indices `from` and `to`. If `from` is less than `to`,
  /// then search forward, if `to` is less than `from`, search backward.
  private func find(_ ch: UniChar,
                    matching with: UniChar,
                    from: Int,
                    to: Int,
                    in str: NSString) -> Int {
    var open = 0
    if to < from {
      var i = from - 1
      while i >= to {
        if str.character(at: i) == with {
          open += 1
        } else if str.character(at: i) == ch {
          if open == 0 {
            return i
          }
          open -= 1
        }
        i -= 1
      }
    } else if to > from {
      var i = from + 1
      while i < to {
        if str.character(at: i) == with {
          open += 1
        } else if str.character(at: i) == ch {
          if open == 0 {
            return i
          }
          open -= 1
        }
        i += 1
      }
    }
    return -1
  }
}
