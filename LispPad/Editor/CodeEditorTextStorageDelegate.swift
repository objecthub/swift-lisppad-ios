//
//  CodeEditorTextStorageDelegate.swift
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
import LispKit

final class CodeEditorTextStorageDelegate: NSObject, NSTextStorageDelegate {
  
  private static let initialIdentCharacters = CharacterSet(charactersIn: "!$%&*/:<=>?^_~@")
  private static let subsequentIdentCharacters = CharacterSet(charactersIn: "+-.")
  private static let digitCharacters = CharacterSet(charactersIn: "0123456789")
  
  let textColor = UIColor(named: "CodeEditorTextColor") ??
                  UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1)
  let codeBackground = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 0.25)
  
  /// The type of the editor (Scheme, Markdown, or Other)
  var editorType: FileExtensions.EditorType
  
  /// A reference to the documentation manager
  let docManager: DocumentationManager
  
  init(editorType: FileExtensions.EditorType, docManager: DocumentationManager) {
    self.editorType = editorType
    self.docManager = docManager
  }
  
  private func markupIdentifier(_ ident: String) -> Bool {
    return self.docManager.documentationAvailable(for: ident)
  }

  private func highlightSchemeSyntax(_ textStorage: NSTextStorage,
                                     _ str: NSString,
                                     _ range: NSRange) {
    var start = range.location
    let end = range.location + range.length
    var commentStart = Int.min
    var stringStart = Int.min
    var numberStart = Int.min
    var symbolStart = Int.min
    textStorage.addAttribute(.foregroundColor, value: self.textColor, range: range)
    while start < end {
      let ch = str.character(at: start)
      if symbolStart < 0 {
        switch ch {
          case D0, D1, D2, D3, D4, D5, D6, D7, D8, D9:
            guard commentStart < 0 && stringStart < 0 && numberStart < 0 else {
              start += 1
              continue
            }
            numberStart = start
          default:
            if numberStart >= 0 {
              textStorage.addAttribute(
                .foregroundColor,
                value: UIColor(cgColor: UserSettings.standard.literalsColor),
                range: NSRange(location: numberStart, length: start - numberStart))
              numberStart = .min
            }
        }
      }
      switch ch {
        case DQUOTE:
          guard commentStart < 0 else {
            break
          }
          if stringStart >= 0 {
            textStorage.addAttribute(
              .foregroundColor,
              value: UIColor(cgColor: UserSettings.standard.literalsColor),
              range: NSRange(location: stringStart, length: start - stringStart + 1))
            stringStart = .min
          } else if symbolStart >= 0 {
            let range = NSRange(location: symbolStart, length: start - symbolStart)
            if self.markupIdentifier(str.substring(with: range)) {
              textStorage.addAttribute(.foregroundColor, value: UIColor(cgColor: UserSettings.standard.docuIdentColor), range: range)
            }
            symbolStart = .min
            stringStart = start
          } else {
            stringStart = start
          }
        case NEWLINE:
          if commentStart >= 0 {
            textStorage.addAttribute(
              .foregroundColor,
              value: UIColor(cgColor: UserSettings.standard.commentsColor),
              range: NSRange(location: commentStart, length: start - commentStart))
            commentStart = .min
          } else if stringStart >= 0 {
            textStorage.addAttribute(
              .foregroundColor,
              value: UIColor(cgColor: UserSettings.standard.literalsColor),
              range: NSRange(location: stringStart, length: start - stringStart))
            stringStart = .min
          } else if symbolStart >= 0 {
            let range = NSRange(location: symbolStart, length: start - symbolStart)
            if self.markupIdentifier(str.substring(with: range)) {
              textStorage.addAttribute(.foregroundColor,
                                       value: UIColor(cgColor: UserSettings.standard.docuIdentColor),
                                       range: range)
            }
            symbolStart = .min
          }
        case SEMI:
          if commentStart < 0 && stringStart < 0 {
            if symbolStart >= 0 {
              let range = NSRange(location: symbolStart, length: start - symbolStart)
              if self.markupIdentifier(str.substring(with: range)) {
                textStorage.addAttribute(.foregroundColor, value: UIColor(cgColor: UserSettings.standard.docuIdentColor), range: range)
              }
              symbolStart = .min
            }
            commentStart = start
          }
        case LPAREN, RPAREN, LBRACE, RBRACE, LBRACKET, RBRACKET, HASH, QUOTE,
             BQUOTE, COMMA, BACKSLASH, BAR:
          if commentStart < 0 && stringStart < 0 {
            if symbolStart >= 0 {
              let range = NSRange(location: symbolStart, length: start - symbolStart)
              if self.markupIdentifier(str.substring(with: range)) {
                textStorage.addAttribute(.foregroundColor, value: UIColor(cgColor: UserSettings.standard.docuIdentColor), range: range)
              }
              symbolStart = .min
            }
            textStorage.addAttribute(
              .foregroundColor,
              value: UIColor(cgColor: UserSettings.standard.parensColor),
              range: NSRange(location: start, length: 1))
          }
        default:
          if symbolStart >= 0 {
            if let sc = UnicodeScalar(ch),
               !CharacterSet.letters.contains(sc),
               !Self.initialIdentCharacters.contains(sc),
               !Self.subsequentIdentCharacters.contains(sc),
               !Self.digitCharacters.contains(sc) {
              let range = NSRange(location: symbolStart, length: start - symbolStart)
              if self.markupIdentifier(str.substring(with: range)) {
                textStorage.addAttribute(.foregroundColor, value: UIColor(cgColor: UserSettings.standard.docuIdentColor), range: range)
              }
              symbolStart = .min
            }
          } else if UserSettings.standard.schemeMarkupIdent,
                    commentStart < 0,
                    stringStart < 0,
                    let sc = UnicodeScalar(ch),
                    CharacterSet.letters.contains(sc) || Self.initialIdentCharacters.contains(sc) {
            symbolStart = start
          }
          break
      }
      start += 1
    }
    if commentStart >= 0 {
      textStorage.addAttribute(
        .foregroundColor,
        value: UIColor(cgColor: UserSettings.standard.commentsColor),
        range: NSRange(location: commentStart, length: start - commentStart))
    } else if stringStart >= 0 {
      textStorage.addAttribute(
        .foregroundColor,
        value: UIColor(cgColor: UserSettings.standard.literalsColor),
        range: NSRange(location: stringStart, length: start - stringStart))
    } else if numberStart >= 0 {
      textStorage.addAttribute(
        .foregroundColor,
        value: UIColor(cgColor: UserSettings.standard.literalsColor),
        range: NSRange(location: numberStart, length: start - numberStart))
    } else if symbolStart >= 0 {
      let range = NSRange(location: symbolStart, length: start - symbolStart)
      if self.markupIdentifier(str.substring(with: range)) {
        textStorage.addAttribute(.foregroundColor, value: UIColor(cgColor: UserSettings.standard.docuIdentColor), range: range)
      }
    }
  }
  
  private func codeBlockOpen(_ str: NSString, _ end: Int) -> Bool {
    var open = false
    var emptyPrefix = true
    var start = self.skipSpaces(in: str, from: 0, end: end)
    while start < end {
      let ch = str.character(at: start)
      switch ch {
        case NEWLINE:
          start = self.skipSpaces(in: str, from: start + 1, end: end)
          guard start < end else {
            return open
          }
          emptyPrefix = true
          continue
        case BQUOTE:
          if emptyPrefix &&
             start + 2 < end &&
             str.character(at: start + 1) == BQUOTE &&
             str.character(at: start + 2) == BQUOTE {
            open = !open
            start += 2
          }
        default:
          break
      }
      start += 1
      emptyPrefix = false
    }
    return open
  }
  
  private func highlightMarkdownSyntax(_ textStorage: NSTextStorage,
                                       _ str: NSString,
                                       _ range: NSRange) {
    textStorage.addAttribute(.foregroundColor, value: self.textColor, range: range)
    var start = range.location
    let end = range.location + range.length
    var escaped = false
    var emptyPrefix: Bool
    if self.codeBlockOpen(str, range.location) {
      let endblock = self.skipCodeBlock(in: str, from: start, end: end) ?? (end - 1)
      let highlightRange = NSRange(location: start, length: endblock - start + 1)
      textStorage.addAttribute(.foregroundColor,
                               value: UIColor(cgColor: UserSettings.standard.codeColor),
                               range: highlightRange)
      /* textStorage.addAttribute(.backgroundColor,
                               value: self.codeBackground,
                               range: str.lineRange(for: highlightRange)) */
      start = endblock + 1
      emptyPrefix = false
    } else {
      while start < end && isSpaceOnly(str.character(at: start)) {
        start += 1
      }
      emptyPrefix = true
    }
    while start < end {
      let ch = str.character(at: start)
      switch ch {
        case BACKSLASH:
          escaped = !escaped
        case NEWLINE:
          start = self.skipSpaces(in: str, from: start + 1, end: end)
          guard start < end else {
            return
          }
          emptyPrefix = true
          escaped = false
          continue
        case HASH:
          if emptyPrefix && start + 1 < end {
            let beginHeader = start
            start += 1
            let isTopHeader = str.character(at: start) != HASH
            while start < end && str.character(at: start) != NEWLINE {
              start += 1
            }
            textStorage.addAttribute(
              .foregroundColor,
              value: UIColor(cgColor: isTopHeader ? UserSettings.standard.headerColor
                                                  : UserSettings.standard.subheaderColor),
              range: NSRange(location: beginHeader, length: start - beginHeader))
            start -= 1
          }
          escaped = false
        case GREATERE:
          if emptyPrefix && start + 1 < end && isSpaceOnly(str.character(at: start + 1)) {
            let beginBlockquote = start
            while start < end && str.character(at: start) != NEWLINE {
              start += 1
            }
            textStorage.addAttribute(
              .foregroundColor,
              value: UIColor(cgColor: UserSettings.standard.blockquoteColor),
              range: NSRange(location: beginBlockquote, length: start - beginBlockquote))
            start = beginBlockquote + 1
          }
        case D0, D1, D2, D3, D4, D5, D6, D7, D8, D9:
          if emptyPrefix && start + 2 < end {
            let beginBullet = start
            start += 1
            scan: while start < end {
              switch str.character(at: start) {
                case D0, D1, D2, D3, D4, D5, D6, D7, D8, D9:
                  break
                default:
                  break scan
              }
              start += 1
            }
            if start + 1 < end &&
               str.character(at: start) == DOT &&
               isSpaceOnly(str.character(at: start + 1)) {
              textStorage.addAttribute(
                .foregroundColor,
                value: UIColor(cgColor: UserSettings.standard.bulletsColor),
                range: NSRange(location: beginBullet, length: start - beginBullet + 1))
            }
          }
          escaped = false
        case DASH:
          if emptyPrefix && start + 1 < end && isSpaceOnly(str.character(at: start + 1)) {
            if let lend = self.lineEnd(in: str, char: DASH, start: start, end: end) {
              textStorage.addAttribute(.foregroundColor,
                                       value: UIColor(cgColor: UserSettings.standard.subheaderColor),
                                       range: NSRange(location: start, length: lend - start))
              start = lend - 1
            } else {
              textStorage.addAttribute(.foregroundColor,
                                       value: UIColor(cgColor: UserSettings.standard.bulletsColor),
                                       range: NSRange(location: start, length: 1))
            }
          } else if emptyPrefix && start + 2 < end,
                 let lend = self.lineEnd(in: str, char: DASH, start: start, end: end) {
            textStorage.addAttribute(.foregroundColor,
                                     value: UIColor(cgColor: UserSettings.standard.subheaderColor),
                                     range: NSRange(location: start, length: lend - start))
            start = lend - 1
          }
          escaped = false
        case STAR:
          if emptyPrefix && start + 1 < end && isSpaceOnly(str.character(at: start + 1)) {
            if let lend = self.lineEnd(in: str, char: STAR, start: start, end: end) {
              textStorage.addAttribute(.foregroundColor,
                                       value: UIColor(cgColor: UserSettings.standard.headerColor),
                                       range: NSRange(location: start, length: lend - start))
              start = lend - 1
            } else {
              textStorage.addAttribute(.foregroundColor,
                                       value: UIColor(cgColor: UserSettings.standard.bulletsColor),
                                       range: NSRange(location: start, length: 1))
            }
          } else if !escaped,
                    let i = self.findInParagraph(STAR, in: str, start: start + 1, end: end) {
            if start > 1 && i + 1 < end &&
               str.character(at: start - 1) == STAR && str.character(at: i + 1) == STAR {
              textStorage.addAttribute(.foregroundColor,
                                       value: UIColor(cgColor: UserSettings.standard.emphasisColor),
                                       range: NSRange(location: start - 1, length: i - start + 3))
            } else {
              textStorage.addAttribute(.foregroundColor,
                                       value: UIColor(cgColor: UserSettings.standard.emphasisColor),
                                       range: NSRange(location: start, length: i - start + 1))
            }
            start = i
          } else if emptyPrefix && start + 2 < end,
                    let lend = self.lineEnd(in: str, char: STAR, start: start, end: end) {
            textStorage.addAttribute(.foregroundColor,
                                     value: UIColor(cgColor: UserSettings.standard.headerColor),
                                    range: NSRange(location: start, length: lend - start))
            start = lend - 1
          }
          escaped = false
        case USCORE:
          if !escaped, let i = self.findInParagraph(USCORE, in: str, start: start + 1, end: end) {
            if start > 1 && i + 1 < end &&
              str.character(at: start - 1) == USCORE && str.character(at: i + 1) == USCORE {
              textStorage.addAttribute(.foregroundColor,
                                       value: UIColor(cgColor: UserSettings.standard.emphasisColor),
                                       range: NSRange(location: start - 1, length: i - start + 3))
            } else {
              textStorage.addAttribute(.foregroundColor,
                                       value: UIColor(cgColor: UserSettings.standard.emphasisColor),
                                       range: NSRange(location: start, length: i - start + 1))
            }
            start = i
          } else if emptyPrefix && start + 2 < end,
                    let lend = self.lineEnd(in: str, char: USCORE, start: start, end: end) {
            textStorage.addAttribute(.foregroundColor,
                                     value: UIColor(cgColor: UserSettings.standard.subheaderColor),
                                     range: NSRange(location: start, length: lend - start))
            start = lend - 1
          }
          escaped = false
        case BQUOTE:
          if emptyPrefix &&
             start + 2 < end &&
             str.character(at: start + 1) == BQUOTE &&
             str.character(at: start + 2) == BQUOTE {
            let endblock = self.skipCodeBlock(in: str, from: start + 3, end: end) ?? (end - 1)
            let highlightRange = NSRange(location: start, length: endblock - start + 1)
            textStorage.addAttribute(.foregroundColor,
                                     value: UIColor(cgColor: UserSettings.standard.codeColor),
                                     range: highlightRange)
            /* textStorage.addAttribute(.backgroundColor,
                                     value: self.codeBackground,
                                     range: str.lineRange(for: highlightRange)) */
            start = endblock
          } else if !escaped,
                    let i = self.findInParagraph(BQUOTE, in: str, start: start + 1, end: end) {
            textStorage.addAttribute(.foregroundColor,
                                     value: UIColor(cgColor: UserSettings.standard.codeColor),
                                     range: NSRange(location: start, length: i - start + 1))
            start = i
          }
          escaped = false
        case EQUAL:
          if emptyPrefix && start + 1 < end && str.character(at: start + 1) == EQUAL {
            var i = start + 1
            while i < end && str.character(at: i) == EQUAL {
              i += 1
            }
            while i < end && isSpaceOnly(str.character(at: i)) {
              i += 1
            }
            if i == end || str.character(at: i) == NEWLINE {
              textStorage.addAttribute(.foregroundColor,
                                       value: UIColor(cgColor: UserSettings.standard.headerColor),
                                       range: NSRange(location: start, length: i - start))
              start = i - 1
            }
          }
          escaped = false
        default:
          escaped = false
      }
      start += 1
      emptyPrefix = false
    }
  }
  
  private func lineEnd(in str: NSString, char: unichar, start: Int, end: Int) -> Int? {
    var i = start + 1
    var stars = 1
    while i < end {
      let ch = str.character(at: i)
      if ch == char {
        stars += 1
      } else if !isSpaceOnly(ch) {
        break
      }
      i += 1
    }
    if stars > 2 && (i == end || str.character(at: i) == NEWLINE) {
      return i
    } else {
      return nil
    }
  }
  
  private func skipSpaces(in str: NSString, from n: Int, end: Int) -> Int {
    var start = n
    while start < end && isSpaceOnly(str.character(at: start)) {
      start += 1
    }
    return start
  }
  
  private func skipCodeBlock(in str: NSString, from n: Int, end: Int) -> Int? {
    var start = n
    var emptyPrefix = false
    while start < end {
      switch str.character(at: start) {
        case NEWLINE:
          start = self.skipSpaces(in: str, from: start + 1, end: end)
          guard start < end else {
            return nil
          }
          emptyPrefix = true
          continue
        case BQUOTE:
          if emptyPrefix &&
             start + 2 < end &&
             str.character(at: start + 1) == BQUOTE &&
             str.character(at: start + 2) == BQUOTE {
            return start + 2
          }
        default:
          break
      }
      start += 1
      emptyPrefix = false
    }
    return nil
  }
  
  private func findInParagraph(_ tch: unichar, in str: NSString, start: Int, end: Int) -> Int? {
    guard start + 1 < end else {
      return nil // not enough space to find in paragraph
    }
    guard !isSpace(str.character(at: start)) else {
      return nil // range cannot start with a whitespace
    }
    var escaped = false
    var i = start
    var pch = SPACE
    var ch = SPACE
    while i < end {
      pch = ch
      ch = str.character(at: i)
      switch ch {
        case tch:
          if escaped {
            escaped = false
            i += 1
          } else {
            return isSpace(pch) ? nil : i
          }
        case BACKSLASH:
          escaped = !escaped
          i += 1
        case NEWLINE:
          escaped = false
          i += 1
          guard i < end else {
            return nil // text ended
          }
          pch = ch
          ch = str.character(at: i)
          // scan next line
          while i < end && isSpaceOnly(ch) {
            i += 1
            pch = ch
            ch = str.character(at: i)
          }
          guard i < end else {
            return nil // text ended
          }
          switch ch {
            case tch:
              return nil // target character preceeded by whitespace
            case HASH:
              return nil // new header
            case NEWLINE:
              return nil // new paragraph
            default:
              continue
          }
        default:
          escaped = false
          i += 1
      }
    }
    return nil // text ended
  }
  
  func highlight(_ textStorage: NSTextStorage) {
    let str = textStorage.string as NSString
    let range = NSRange(location: 0, length: textStorage.length)
    switch self.editorType {
      case .scheme:
        if UserSettings.standard.schemeHighlightSyntax {
          textStorage.removeAttribute(.foregroundColor, range: range)
          self.highlightSchemeSyntax(textStorage, str, range)
        }
      case .markdown:
        if UserSettings.standard.markdownHighlightSyntax {
          textStorage.removeAttribute(.foregroundColor, range: range)
          self.highlightMarkdownSyntax(textStorage, str, range)
        }
      case .other:
        textStorage.removeAttribute(.foregroundColor, range: range)
        break
    }
  }
  
  private func extendedParagraphRange(in str: NSString, editedRange: NSRange) -> NSRange {
    let range = str.paragraphRange(for: editedRange)
    let prevRange = range.location > 0
                  ? str.paragraphRange(for: NSRange(location: range.location - 1, length: 0))
                  : NSRange(location: range.location, length: 0)
    return NSRange(location: prevRange.location,
                   length: str.length - prevRange.location)
  }
  
  @objc func textStorage(_ textStorage: NSTextStorage,
                         didProcessEditing editedMask: NSTextStorage.EditActions,
                         range editRange: NSRange,
                         changeInLength delta: Int) {
    // Check that syntax highlighting is enabled
    guard (self.editorType == .scheme && UserSettings.standard.schemeHighlightSyntax) ||
          (self.editorType == .markdown && UserSettings.standard.markdownHighlightSyntax) else {
      return
    }
    // Find the range for which to redo the syntax highlighting
    let str = textStorage.string as NSString
    let range: NSRange
    if self.editorType == .scheme {
      range = str.lineRange(for: editRange)
    } else {
      range = self.extendedParagraphRange(in: str, editedRange: editRange)
    }
    // Remove attribution in edited range
    textStorage.removeAttribute(.foregroundColor, range: range)
    // Add syntax highlighting
    if self.editorType == .scheme {
      self.highlightSchemeSyntax(textStorage, str, range)
    } else {
      self.highlightMarkdownSyntax(textStorage, str, range)
    }
  }
}
