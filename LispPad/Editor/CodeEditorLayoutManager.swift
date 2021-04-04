//
//  CodeEditorLayoutManager.swift
//  LispPad
//
//  This code is based on the approach taken by the Objective-C library _TextKit LineNumbers_
//  by Mark Alldritt (see https://github.com/alldritt/TextKit_LineNumbers).
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

class CodeEditorLayoutManager: NSLayoutManager {
  
  var codingFont = UIFont.systemFont(ofSize: 10.0)
  var codingTextColor = UIColor.secondaryLabel
  var lastLineLoc = 0
  var lastLineNum = 0
  
  private func lineNumber(for charRange: NSRange, in textStorage: NSTextStorage) -> Int {
    // NSString does not provide a means of efficiently determining the line number of a
    // range of text. This code attempts to optimize what would normally be a series linear
    // searches by keeping track of the last line number found and uses that as the
    // starting point for next line number search. This works (mostly) because we
    // are generally asked for continguous increasing sequences of line numbers. Also,
    // this code is called in the course of drawing a pagefull of text, and so even when
    // moving back, the number of lines to search for is relativly low, even in really
    // long bodies of text.
    //
    // This all falls down when the user edits the text, and can potentially invalidate the
    // cached line number which causes a (potentially lengthy) search from the beginning
    // of the string.
    if charRange.location == self.lastLineLoc {
      return self.lastLineNum
    } else if charRange.location < self.lastLineLoc {
      // We need to look backwards from the last known line for the new line range.
      // This generally happens when the text in the UITextView scrolls downward, revaling
      // lines before/above the ones previously drawn.
      let s = textStorage.string as NSString
      var lineNum = self.lastLineNum
      s.enumerateSubstrings(in: NSMakeRange(charRange.location,
                                            self.lastLineLoc - charRange.location),
                            options: [.byParagraphs, .substringNotRequired, .reverse]) {
        substring, substringRange, enclosingRange, stop in
          if enclosingRange.location <= charRange.location {
            stop.pointee = true
          }
          lineNum -= 1
      }
      self.lastLineLoc = charRange.location
      self.lastLineNum = lineNum
      return lineNum
    } else {
      // We need to look forward from the last known line for the new line range.
      // This generally happens when the text in the UITextView scrolls upwards, revealing
      // lines that follow the ones previously drawn.
      let s = textStorage.string as NSString
      var lineNum = self.lastLineNum
      s.enumerateSubstrings(in: NSMakeRange(self.lastLineLoc,
                                            charRange.location - self.lastLineLoc),
                            options: [.byParagraphs, .substringNotRequired]) {
        substring, substringRange, enclosingRange, stop in
          if enclosingRange.location >= charRange.location {
            stop.pointee = true
          }
          lineNum += 1
      }
      self.lastLineLoc = charRange.location
      self.lastLineNum = lineNum
      return lineNum
    }
  }
  
  override func processEditing(for textStorage: NSTextStorage,
                               edited editMask: NSTextStorage.EditActions,
                               range newCharRange: NSRange,
                               changeInLength delta: Int,
                               invalidatedRange invalidatedCharRange: NSRange) {
    super.processEditing(for: textStorage,
                         edited: editMask,
                         range: newCharRange,
                         changeInLength: delta,
                         invalidatedRange: invalidatedCharRange)
    if invalidatedCharRange.location < self.lastLineLoc {
      // When the backing store is edited ahead the cached line location, invalidate the
      // cache and force a complete recalculation.  We cannot be much smarter than this because
      // we don't know how many lines have been deleted since the text has already been
      // removed from the backing store.
      self.lastLineLoc = 0
      self.lastLineNum = 0
    }
  }
  
  override func drawBackground(forGlyphRange glyphsToShow: NSRange, at origin: CGPoint) {
    super.drawBackground(forGlyphRange: glyphsToShow, at: origin)
    // Draw line numbers. The background for line number gutter is drawn by the
    // CodeEditorTextView class.
    guard let textStorage = self.textStorage else {
      return
    }
    let atts: [NSAttributedString.Key : Any] = [
      .font : self.codingFont,
      .foregroundColor : self.codingTextColor
    ]
    var gutterRect = CGRect.zero
    var lineNumber = 0
    self.enumerateLineFragments(forGlyphRange: glyphsToShow) {
      rect, usedRect, textContainer, glyphRange, stop in
        let charRange = self.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)
        let lineRange = (textStorage.string as NSString).paragraphRange(for: charRange)
        // Only draw line numbers for the line's first line fragment. Subsequent fragments
        // are wrapped portions of the line and don't get the line number.
        if charRange.location == lineRange.location {
          gutterRect = CGRect(x: 0, y: rect.origin.y, width: 40.0, height: rect.size.height)
                         .offsetBy(dx: origin.x, dy: origin.y)
          lineNumber = self.lineNumber(for: charRange, in: textStorage)
          let ln = NSString(format: "%ld", UInt64(lineNumber + 1))
          let size = ln.size(withAttributes: atts)
          ln.draw(in: gutterRect.offsetBy(dx: gutterRect.width - 4 - size.width,
                                          dy: (gutterRect.height - size.height) / 2.0),
                  withAttributes: atts)
        }
    }
    // Deal with the special case of an empty last line where enumerateLineFragmentsForGlyphRange
    // has no line fragments to draw.
    // Doesn't work: if NSMaxRange(glyphsToShow) > self.numberOfGlyphs {
    if textStorage.string.isEmpty || textStorage.string.hasSuffix("\n") {
      let ln = NSString(format: "%ld", UInt64(lineNumber + 2))
      let size = ln.size(withAttributes: atts)
      gutterRect = gutterRect.offsetBy(dx: 0.0, dy: gutterRect.height)
      ln.draw(in: gutterRect.offsetBy(dx: gutterRect.width - 4 - size.width,
                                      dy: (gutterRect.height - size.height) / 2.0),
              withAttributes: atts)
    }
  }
}
