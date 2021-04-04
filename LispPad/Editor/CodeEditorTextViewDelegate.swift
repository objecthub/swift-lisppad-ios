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

class CodeEditorTextViewDelegate: NSObject, UITextViewDelegate {
  var parent: CodeEditor
  
  init(_ codeEditor: CodeEditor) {
    self.parent = codeEditor
  }
  
  public func textViewDidChange(_ textView: UITextView) {
    guard textView.markedTextRange == nil else {
      return
    }
    DispatchQueue.main.async {
      self.parent.text = textView.text ?? ""
    }
  }
  
  public func textViewDidChangeSelection(_ textView: UITextView) {
    guard let onSelectionChange = parent.onSelectionChange else {
      return
    }
    onSelectionChange([textView.selectedRange])
  }
  
  public func textViewDidBeginEditing(_ textView: UITextView) {
    parent.onEditingChanged()
  }
  
  public func textViewDidEndEditing(_ textView: UITextView) {
    parent.onCommit()
  }
  
  private func lispIndent(_ str: NSString, _ selectedRange: NSRange) -> String {
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
    if text == "\n" {
      let indent = lispIndent(textView.textStorage.string as NSString, range)
      if let replaceStart = textView.position(from: textView.beginningOfDocument,
                                              offset: range.location),
          let replaceEnd = textView.position(from: replaceStart, offset: range.length),
          let textRange = textView.textRange(from: replaceStart, to: replaceEnd) {
        // textView.undoManager?.beginUndoGrouping()
        textView.replace(textRange, withText: "\n" + indent)
        // textView.undoManager?.endUndoGrouping()
        return false
      }
    }
    return true
  }
}
