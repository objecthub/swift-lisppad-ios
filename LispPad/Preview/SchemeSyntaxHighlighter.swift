//
//  SchemeSyntaxHighlighter.swift
//  LispPad
//
//  Shared between the LispPad app and the "LispPad QuickLook" extension.
//
//  Copyright © 2026 Matthias Zenger. All rights reserved.
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

/// The colors used for highlighting Scheme code.
struct SchemeSyntaxPalette {
  let text: UIColor
  let parens: UIColor
  let literals: UIColor
  let comments: UIColor
  let docuIdent: UIColor
}

/// Colors Scheme code by setting the `foregroundColor` attribute. The code editor and the
/// Quick Look extension both use it, so that they highlight code in the same way.
struct SchemeSyntaxHighlighter {
  private static let initialIdentCharacters = CharacterSet(charactersIn: "!$%&*/:<=>?^_~@")
  private static let subsequentIdentCharacters = CharacterSet(charactersIn: "+-.")
  private static let digitCharacters = CharacterSet(charactersIn: "0123456789")

  /// The colors to use.
  let palette: SchemeSyntaxPalette

  /// Determines which identifiers get the color for documented identifiers. Identifiers are not
  /// marked up at all if this is `nil`.
  let isDocumented: ((String) -> Bool)?

  /// Highlights the characters of `range` in `text`, which is the attributed version of `str`.
  func highlight(_ text: NSMutableAttributedString, _ str: NSString, _ range: NSRange) {
    var start = range.location
    let end = range.location + range.length
    var commentStart = Int.min
    var stringStart = Int.min
    var numberStart = Int.min
    var symbolStart = Int.min
    text.addAttribute(.foregroundColor, value: self.palette.text, range: range)
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
              text.addAttribute(
                .foregroundColor,
                value: self.palette.literals,
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
            text.addAttribute(
              .foregroundColor,
              value: self.palette.literals,
              range: NSRange(location: stringStart, length: start - stringStart + 1))
            stringStart = .min
          } else if symbolStart >= 0 {
            self.markupIdentifier(text, str, symbolStart, start)
            symbolStart = .min
            stringStart = start
          } else {
            stringStart = start
          }
        case NEWLINE:
          if commentStart >= 0 {
            text.addAttribute(
              .foregroundColor,
              value: self.palette.comments,
              range: NSRange(location: commentStart, length: start - commentStart))
            commentStart = .min
          } else if stringStart >= 0 {
            text.addAttribute(
              .foregroundColor,
              value: self.palette.literals,
              range: NSRange(location: stringStart, length: start - stringStart))
            stringStart = .min
          } else if symbolStart >= 0 {
            self.markupIdentifier(text, str, symbolStart, start)
            symbolStart = .min
          }
        case SEMI:
          if commentStart < 0 && stringStart < 0 {
            if symbolStart >= 0 {
              self.markupIdentifier(text, str, symbolStart, start)
              symbolStart = .min
            }
            commentStart = start
          }
        case LPAREN, RPAREN, LBRACE, RBRACE, LBRACKET, RBRACKET, HASH, QUOTE,
             BQUOTE, COMMA, BACKSLASH, BAR:
          if commentStart < 0 && stringStart < 0 {
            if symbolStart >= 0 {
              self.markupIdentifier(text, str, symbolStart, start)
              symbolStart = .min
            }
            text.addAttribute(
              .foregroundColor,
              value: self.palette.parens,
              range: NSRange(location: start, length: 1))
          }
        default:
          if symbolStart >= 0 {
            if let sc = UnicodeScalar(ch),
               !CharacterSet.letters.contains(sc),
               !Self.initialIdentCharacters.contains(sc),
               !Self.subsequentIdentCharacters.contains(sc),
               !Self.digitCharacters.contains(sc) {
              self.markupIdentifier(text, str, symbolStart, start)
              symbolStart = .min
            }
          } else if self.isDocumented != nil,
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
      text.addAttribute(
        .foregroundColor,
        value: self.palette.comments,
        range: NSRange(location: commentStart, length: start - commentStart))
    } else if stringStart >= 0 {
      text.addAttribute(
        .foregroundColor,
        value: self.palette.literals,
        range: NSRange(location: stringStart, length: start - stringStart))
    } else if numberStart >= 0 {
      text.addAttribute(
        .foregroundColor,
        value: self.palette.literals,
        range: NSRange(location: numberStart, length: start - numberStart))
    } else if symbolStart >= 0 {
      self.markupIdentifier(text, str, symbolStart, start)
    }
  }

  /// Gives the identifier in `str` from `start` to `end` the color for documented identifiers
  /// if it is documented.
  private func markupIdentifier(_ text: NSMutableAttributedString,
                                _ str: NSString,
                                _ start: Int,
                                _ end: Int) {
    if let isDocumented = self.isDocumented {
      let range = NSRange(location: start, length: end - start)
      if isDocumented(str.substring(with: range)) {
        text.addAttribute(.foregroundColor, value: self.palette.docuIdent, range: range)
      }
    }
  }
}
