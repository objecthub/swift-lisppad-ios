//
//  LispPadDocument.swift
//  LispPad
//
//  Created by Matthias Zenger on 14/03/2021.
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
import UniformTypeIdentifiers

struct LispPadDocument: FileDocument {
  
  static let readableContentTypes: [UTType] = [
    .plainText,
    .schemeProgram,
    .schemeLibrary
  ]

  var text = ""
  
  init(initialText: String = "") {
    self.text = initialText
  }

  init(configuration: ReadConfiguration) throws {
    guard let data = configuration.file.regularFileContents,
          let string = String(data: data, encoding: .utf8) else {
      throw CocoaError(.fileReadCorruptFile)
    }
    self.text = string
  }
  
  func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
    let data = text.data(using: .utf8)!
    return FileWrapper(regularFileWithContents: data)
  }
}

extension UTType {
  static let schemeProgram = UTType(importedAs: "net.objecthub.scheme-program")
  static let schemeLibrary = UTType(importedAs: "net.objecthub.scheme-library")
}
