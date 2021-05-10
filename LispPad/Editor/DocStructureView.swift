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

struct DocStructureView: View {

  struct Header: Identifiable {
    let id = UUID()
    let title: String
    let level: Int
    let range: NSRange
  }

  struct DocStructure {
    let headers: [Header]
  }

  @Environment(\.presentationMode) var presentationMode
  let structure: DocStructure
  @Binding var position: NSRange?

  var body: some View {
    VStack(alignment: .center, spacing: 0) {
      HStack {
        Spacer()
        Button(action: {
          self.presentationMode.wrappedValue.dismiss()
        }) {
          Text("Cancel")
        }
      }
      .font(.body)
      .padding(.horizontal)
      .padding(.top)
      .edgesIgnoringSafeArea(.all)
      .background(Color(.systemGroupedBackground))
      Form {
        if self.structure.headers.count > 0 {
          ForEach(self.structure.headers) { header in
            Button(action: { self.position = header.range
                             self.presentationMode.wrappedValue.dismiss() }) {
              HStack {
                Image(systemName: self.image(for: header.level))
                Spacer().frame(minWidth: 16.0, maxWidth: CGFloat(header.level) * 16.0)
                Text(header.title)
              }
            }
          }
          .font(.body)
        }
      }
    }
  }

  private func image(for level: Int) -> String {
    switch level {
      case 1:
        return "1.square"
      case 2:
        return "2.square"
      case 3:
        return "3.square"
      case 4:
        return "4.square"
      case 5:
        return "5.square"
      case 6:
        return "6.square"
      default:
        return "h.square"
    }
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

struct DocStructureView_Previews: PreviewProvider {
  @State static var position: NSRange? = nil
  static var previews: some View {
    DocStructureView(
      structure: DocStructureView.DocStructure(
        headers: [
          DocStructureView.Header(title: "1st header", level: 1, range: NSRange(location: 0, length: 1)),
          DocStructureView.Header(title: "2nd header", level: 2, range: NSRange(location: 1, length: 2)),
          DocStructureView.Header(title: "3rd header", level: 3, range: NSRange(location: 2, length: 3))
        ]),
      position: $position)
  }
}
