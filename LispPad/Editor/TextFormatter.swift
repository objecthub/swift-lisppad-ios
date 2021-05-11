//
//  TextFormatter.swift
//  LispPad
//
//  Created by Matthias Zenger on 29/04/2021.
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

import Foundation

struct TextFormatter {
  
  private static let (nested, fixed) = { () -> (Set<String>, Set<String>) in
    var nested = Set<String>()
    var fixed = Set<String>()
    if let url = Bundle.main.url(forResource: "IndentationRules", withExtension: "plist"),
       let indentationConfig = NSDictionary(contentsOf: url),
       let nestedIndent = indentationConfig.value(forKey: "nested indentation") as? [Any],
       let fixedIndent = indentationConfig.value(forKey: "fixed indentation") as? [Any] {
      for str in nestedIndent {
        if let ident = str as? String {
          nested.insert(ident)
        }
      }
      for str in fixedIndent {
        if let ident = str as? String {
          fixed.insert(ident)
        }
      }
    }
    return (nested, fixed)
  }()
  
  private static func argsUseNestedIndent(_ ident: String) -> Bool {
    return self.nested.contains(ident)
  }
  
  private static func argsUseFixedIndent(_ ident: String) -> Bool {
    return self.fixed.contains(ident)
  }
  
  private static func expandRange(_ range: NSRange, in str: NSString) -> NSRange {
    var start = range.location
    guard start >= 0 && start <= str.length else {
      return NSRange(location: 0, length: 0)
    }
    if start > 0 {
      start -= 1
      while start >= 0 && str.character(at: start) != NEWLINE {
        start -= 1
      }
      start += 1
    }
    let len = str.length
    var end = range.location + range.length
    while end < len && str.character(at: end) != NEWLINE {
      end += 1
    }
    return NSRange(location: start, length: end - start)
  }
  
  static func autoIndentLines(_ str: NSString,
                              range: NSRange,
                              tabWidth: Int) -> (String, NSRange, NSRange)? {
    let selectedRange = Self.expandRange(range.length == 0 ? NSRange(location: 0, length: str.length)
                                                           : range, in: str)
    let len = selectedRange.location + selectedRange.length
    var openParens = ContiguousArray<(Int, Bool)>()
    var index = 0
    func skipSpaces() {
      while index < len {
        let ch = str.character(at: index)
        if ch == SEMI {
          index += 1
          while index < len && str.character(at: index) != NEWLINE {
            index += 1
          }
          return
        } else if ch == NEWLINE {
          return
        }
        guard let scalar = UnicodeScalar(ch), WHITESPACES.contains(scalar) else {
          return
        }
        index += 1
      }
    }
    func parseIdent() -> String? {
      guard index < len else {
        return nil
      }
      let start = index
      let ch = str.character(at: index)
      if isSpecialInitialIdent(ch) {
        guard index + 1 < len else {
          index += 1
          return asString(ch)
        }
        let ch2 = str.character(at: index + 1)
        if isDigit(ch2) {
          return nil
        } else if isInitialIdent(ch2) || isSpecialInitialIdent(ch2) {
          index += 1
        } else {
          index += 1
          return asString(ch)
        }
      } else if !isInitialIdent(ch) {
        return nil
      }
      index += 1
      while index < len && isSubsequentIdent(str.character(at: index)) {
        index += 1
      }
      return str.substring(with: NSRange(location: start, length: index - start))
    }
    func parseLine(indent: Int) {
      let start = index
      loop: while index < len {
        let ch = str.character(at: index)
        switch ch {
          case SEMI:
            skipSpaces()
          case DQUOTE:
            index += 1
            while index < len {
              switch str.character(at: index) {
                case DQUOTE:
                  index += 1
                  continue loop
                case NEWLINE:
                  continue loop
                case BACKSLASH:
                  index += 1
                  if index < len {
                    index += 1
                  }
                default:
                  index += 1
              }
            }
          case LPAREN:
            var pos = index - start + indent
            var nestedIndent = false
            index += 1
            skipSpaces()
            if let ident = parseIdent() {
              skipSpaces()
              if index < str.length && str.character(at: index) == NEWLINE ||
                 Self.argsUseFixedIndent(ident) {
                pos += 2
              } else {
                pos = index - start + indent
              }
              nestedIndent = Self.argsUseNestedIndent(ident)
            } else if let outerParen = openParens.last, outerParen.1 {
              pos += 2
            } else {
              pos += 1
            }
            openParens.append((pos, nestedIndent))
          case RPAREN:
            if !openParens.isEmpty {
              openParens.removeLast()
            }
            index += 1
          case NEWLINE:
            index += 1
            return
          default:
            index += 1
        }
      }
    }
    let replacementStr = NSMutableString()
    var replacementFrom = -1
    var line = 1
    var requiresReplacement = false
    while index < len {
      // Manage replacement range
      if selectedRange.contains(index) && replacementFrom < 0 {
        replacementFrom = index
      }
      var actualIndent = 0
      // Determine current indentation
      scan: while index < len {
        switch str.character(at: index) {
          case SPACE:
            actualIndent += 1
          case TAB:
            actualIndent += tabWidth + (actualIndent % tabWidth)
          default:
            break scan
        }
        index += 1
      }
      // Determine corrected indentation
      let correctedIndent = openParens.last?.0 ?? 0
      // Parse rest of the line
      let contentStart = index
      parseLine(indent: replacementFrom >= 0 ? correctedIndent : actualIndent)
      // Create replacement line
      if replacementFrom >= 0 {
        requiresReplacement = requiresReplacement || correctedIndent != actualIndent
        replacementStr.append(String(repeating: " ", count: correctedIndent))
        replacementStr.append(
          str.substring(with: NSRange(location: contentStart, length: index - contentStart)))
      }
      line += 1
    }
    // Determine replacement range and replacement string
    if requiresReplacement {
      let replacementRange = NSRange(location: replacementFrom, length: len - replacementFrom)
      let newSelectedRange = NSRange(location: replacementFrom,
                                     length: range.length == 0 ? 0 : replacementStr.length)
      return (replacementStr as String, replacementRange, newSelectedRange)
    } else {
      return nil
    }
  }
  
  static func indentLines(_ str: NSMutableString,
                          selectedRange: NSRange,
                          with character: String) -> NSRange? {
    // Find the beginning of the current line
    var start = selectedRange.location
    var end = start + selectedRange.length
    while start > 0 && str.character(at: start - 1) != NEWLINE {
      start -= 1
    }
    str.replaceCharacters(in: NSRange(location: start, length: 0), with: character)
    end += 1
    // Indent remaining lines
    while start < end {
      while start < end  && str.character(at: start) != NEWLINE {
        start += 1
      }
      guard start < end else {
        break
      }
      start += 1
      str.replaceCharacters(in: NSRange(location: start, length: 0), with: character)
      end += 1
    }
    // Determine new selection
    return NSRange(location: selectedRange.location + 1,
                   length: end - selectedRange.location - 1)
  }
  
  static func outdentLines(_ str: NSMutableString,
                           selectedRange: NSRange,
                           with character: String) -> NSRange? {
    let char = character.utf16.first!
    // Find the beginning of the current line
    var start = selectedRange.location
    var end = start + selectedRange.length
    while start > 0 && str.character(at: start - 1) != NEWLINE {
      start -= 1
    }
    var correction = 0
    // Remove first space if it exists
    if str.character(at: start) == char {
      str.replaceCharacters(in: NSRange(location: start, length: 1), with: "")
      end -= 1
      if selectedRange.location > 0 {
        correction = 1
      }
    }
    // Undent remaining lines
    while start < end {
      while start < end  && str.character(at: start) != NEWLINE {
        start += 1
      }
      guard start < end else {
        break
      }
      start += 1
      if start < end && str.character(at: start) == char {
        str.replaceCharacters(in: NSRange(location: start, length: 1), with: "")
        end -= 1
      }
    }
    // Did something change?
    guard end < selectedRange.location + selectedRange.length else {
      return nil
    }
    // Determine replacement range and replacement string
    return NSRange(location: selectedRange.location - correction,
                   length: end - selectedRange.location + correction)
  }
}