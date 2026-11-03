//
//  DocStructureView.swift
//  LispPad
//
//  Created by Matthias Zenger on 10/05/2021.
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

import SwiftUI
import MarkdownKit

struct DocStructure {
  
  struct Header: Identifiable {
    let id = UUID()
    let title: String
    let level: Int
    let range: NSRange
  }

  let headers: [Header]
  
  var isEmpty: Bool {
    return self.headers.isEmpty
  }
  
  static func parseDocStructure(_ text: String,
                                maxCount: Int = 20000,
                                maxDefs: Int = 200,
                                maxLen: Int = 60) -> DocStructure? {
    let str = text as NSString
    var headers: [Header] = []
    var index = 0
    let len = min(str.length, maxCount)
    func skipSpaces() {
      while index < len {
        guard let scalar = UnicodeScalar(str.character(at: index)),
              WHITESPACES_ONLY.contains(scalar) else {
          return
        }
        index += 1
      }
    }
    func skipLine() {
      while index < len {
        if str.character(at: index) == NEWLINE {
          return
        }
        index += 1
      }
    }
    while index + 2 < len && headers.count < maxDefs {
      skipSpaces()
      var level = 0
      let start = index
      while index < len && str.character(at: index) == HASH {
        level += 1
        index += 1
      }
      if index < len && level > 0,
         let scalar = UnicodeScalar(str.character(at: index)),
         WHITESPACES.contains(scalar) {
        skipLine()
        var title = str.substring(with: NSRange(location: start + level + 1,
                                                length: index - start - level - 1))
                       .trimmingCharacters(in: WHITESPACES)
        if !title.isEmpty {
          if title.count > maxLen {
            title = String(title[..<title.index(title.startIndex, offsetBy: maxLen)]) + "…"
          }
          headers.append(Header(title: title,
                                level: level,
                                range: NSRange(location: start, length: index - start)))
          if headers.count >= maxDefs {
            break
          }
        }
      } else {
        skipLine()
      }
      if index < len {
        index += 1
      }
    }
    return headers.count > 0 ? DocStructure(headers: headers) : nil
  }
}
