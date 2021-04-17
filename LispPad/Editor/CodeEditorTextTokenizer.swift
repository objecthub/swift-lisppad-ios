//
//  CodeEditorTextTokenizer.swift
//  LispPad
//
//  Created by Matthias Zenger on 16/04/2021.
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

class CodeEditorTextTokenizer: UITextInputStringTokenizer {
  
  // Seperate on symbols (except underscore) or whitespace
  static let wordSeperators: CharacterSet = {
    var charSet: CharacterSet = LETTERS
    charSet.formUnion(INITIALS)
    charSet.formUnion(DIGITS)
    charSet.formUnion(SUBSEQUENTS)
    return charSet
  }()
  
  let textInput: UIResponder & UITextInput
  
  override init(textInput: UIResponder & UITextInput) {
    self.textInput = textInput
    super.init(textInput: textInput)
  }
  
  // Returns range of the enclosing text unit of the given granularity, or nil if there is no
  // such enclosing unit. Whether a boundary position is enclosed depends on the given direction,
  // using the same rule as isPosition:withinTextUnit:inDirection:
  override func rangeEnclosingPosition(_ position: UITextPosition,
                                       with granularity: UITextGranularity,
                                       inDirection direction: UITextDirection) -> UITextRange? {
    if granularity == .word {
      let loc = self.textInput.offset(from: self.textInput.beginningOfDocument, to: position)
      let length = self.textInput.offset(from: self.textInput.beginningOfDocument,
                                         to: self.textInput.endOfDocument)
      if loc != NSNotFound,
         let textRange = self.textInput.textRange(from: self.textInput.beginningOfDocument,
                                                  to: self.textInput.endOfDocument),
         let text = self.textInput.text(in: textRange) as NSString? {
        var wordStart = text.rangeOfCharacter(from: CodeEditorTextTokenizer.wordSeperators,
                                              options: [.backwards],
                                              range: NSMakeRange(0, loc)).location
        var wordEnd = text.rangeOfCharacter(from: CodeEditorTextTokenizer.wordSeperators,
                                            options: [],
                                            range: NSMakeRange(loc, length-loc)).location
        if wordStart == NSNotFound {
          wordStart = 0
        } else {
          wordStart += 1
        }
        if wordEnd == NSNotFound {
          wordEnd = length
        }
        let wordRange = NSMakeRange(wordStart, wordEnd - wordStart)
        return self.textRange(from: wordRange)
      }
    }
    return super.rangeEnclosingPosition(position, with: granularity, inDirection: direction)
  }
  
  private func textRange(from range: NSRange) -> UITextRange? {
    let beginning = self.textInput.beginningOfDocument
    guard let start = self.textInput.position(from: beginning, offset: range.location),
          let end = self.textInput.position(from: start, offset: range.length) else {
      return nil
    }
    return self.textInput.textRange(from: start, to: end)
  }
  
  override func isPosition(_ position: UITextPosition,
                           atBoundary granularity: UITextGranularity,
                           inDirection direction: UITextDirection) -> Bool {
    return super.isPosition(position, atBoundary: granularity, inDirection: direction)
  }
  
  override func isPosition(_ position: UITextPosition,
                           withinTextUnit granularity: UITextGranularity,
                           inDirection direction: UITextDirection) -> Bool {
    return super.isPosition(position, withinTextUnit: granularity, inDirection: direction)
  }
  
  override func position(from position: UITextPosition,
                         toBoundary granularity: UITextGranularity,
                         inDirection direction: UITextDirection) -> UITextPosition? {
    return super.position(from: position, toBoundary: granularity, inDirection: direction)
  }
}
