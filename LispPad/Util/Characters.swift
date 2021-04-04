//
//  Characters.swift
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

import Foundation

func textLocation(forLine target: Int, in text: String) -> Int {
  var line = 1
  var column = 1
  var currentLoc = 0
  for ch in text.utf16 {
    if line == target {
      return currentLoc
    } else if ch == NEWLINE {
      line += 1
      column = 1
    } else {
      column += 1
    }
    currentLoc += 1
  }
  return currentLoc
}

func cursorPosition(in text: String, forLoc targetLoc: Int) -> (Int, Int) {
  var line = 1
  var column = 1
  var currentLoc = 0
  for ch in text.utf16 {
    if currentLoc == targetLoc {
      return (line, column)
    } else if ch == NEWLINE {
      line += 1
      column = 1
    } else {
      column += 1
    }
    currentLoc += 1
  }
  return (line, column)
}

func lineNumber(in text: String, forLoc targetLoc: Int) -> Int {
  var line = 1
  var currentLoc = 0
  for ch in text.utf16 {
    if currentLoc == targetLoc {
      return line
    } else if ch == NEWLINE {
      line += 1
    }
    currentLoc += 1
  }
  return line
}

func lineNumberRange(in text: String, forRange range: NSRange) -> (Int, Int) {
  var start = 1
  var line = 1
  var currentLoc = 0
  for ch in text.utf16 {
    if currentLoc == range.lowerBound {
      start = line
    }
    if currentLoc == range.upperBound {
      return (start, line)
    } else if ch == NEWLINE {
      line += 1
    }
    currentLoc += 1
  }
  return (line, line)
}

func isSpace(_ ch: UniChar) -> Bool {
  guard let scalar = UnicodeScalar(ch) else {
    return false
  }
  return WHITESPACES.contains(scalar)
}

func isSpaceOnly(_ ch: UniChar) -> Bool {
  guard let scalar = UnicodeScalar(ch) else {
    return false
  }
  return WHITESPACES_ONLY.contains(scalar)
}

func isLetter(_ ch: UniChar) -> Bool {
  guard let scalar = UnicodeScalar(ch) else {
    return false
  }
  return LETTERS.contains(scalar)
}

func isDigit(_ ch: UniChar) -> Bool {
  guard let scalar = UnicodeScalar(ch) else {
    return false
  }
  return DIGITS.contains(scalar)
}

func isInitialIdent(_ ch: UniChar) -> Bool {
  guard let scalar = UnicodeScalar(ch) else {
    return false
  }
  return LETTERS.contains(scalar) || INITIALS.contains(scalar)
}

func isSubsequentIdent(_ ch: UniChar) -> Bool {
  guard let scalar = UnicodeScalar(ch) else {
    return false
  }
  return isInitialIdent(ch) || isDigit(ch) || SUBSEQUENTS.contains(scalar)
}

func isSpecialInitialIdent(_ ch: UniChar) -> Bool {
  guard let scalar = UnicodeScalar(ch) else {
    return false
  }
  return SUBSEQUENTS.contains(scalar)
}

func asCharacter(_ ch: UniChar) -> Character {
  if let scalar = Unicode.Scalar(ch) {
    return Character(scalar)
  } else {
    return " "
  }
}

func asString(_ ch: UniChar) -> String {
  if let scalar = Unicode.Scalar(ch) {
    return String(scalar)
  } else {
    return " "
  }
}


let WHITESPACES_ONLY  = CharacterSet.whitespaces
let WHITESPACES  = CharacterSet.whitespacesAndNewlines
let DIGITS       = CharacterSet(charactersIn: "0123456789")
let LETTERS      = CharacterSet.letters
let INITIALS     = CharacterSet(charactersIn: "!$%&*/:<=>?^_~")
let SUBSEQUENTS  = CharacterSet(charactersIn: "+-.@")

let SPACE     = " ".utf16.first!
let TAB       = "\t".utf16.first!
let SEMI      = ";".utf16.first!
let DQUOTE    = "\"".utf16.first!
let NEWLINE   = "\n".utf16.first!
let RPAREN    = ")".utf16.first!
let RBRACKET  = "]".utf16.first!
let RBRACE    = "}".utf16.first!
let LPAREN    = "(".utf16.first!
let LBRACKET  = "[".utf16.first!
let LBRACE    = "{".utf16.first!
let BAR       = "|".utf16.first!
let HASH      = "#".utf16.first!
let QUOTE     = "'".utf16.first!
let BQUOTE    = "`".utf16.first!
let COMMA     = ",".utf16.first!
let DOT       = ".".utf16.first!
let DASH      = "-".utf16.first!
let USCORE    = "_".utf16.first!
let STAR      = "*".utf16.first!
let EQUAL     = "=".utf16.first!
let GREATERE  = ">".utf16.first!
let BACKSLASH = "\\".utf16.first!
let D0        = "0".utf16.first!
let D1        = "1".utf16.first!
let D2        = "2".utf16.first!
let D3        = "3".utf16.first!
let D4        = "4".utf16.first!
let D5        = "5".utf16.first!
let D6        = "6".utf16.first!
let D7        = "7".utf16.first!
let D8        = "8".utf16.first!
let D9        = "9".utf16.first!
let CD        = "d".utf16.first!
let CE        = "e".utf16.first!
let CF        = "f".utf16.first!
let CI        = "i".utf16.first!
let CN        = "n".utf16.first!
