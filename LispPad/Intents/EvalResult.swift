//
//  EvalResult.swift
//  LispPad
//
//  Created by Matthias Zenger on 21/03/2026.
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

import AppIntents
import LispKit

struct EvalResult: TransientAppEntity {
  static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Evaluation Result")
  
  @Property(title: "String Results")
  var strings: [String]
  
  @Property(title: "File Results")
  var files: [IntentFile]
  
  @Property(title: "Evaluation Transcript")
  var transcript: String
  
  init() {
    self.strings = []
    self.files = []
    self.transcript = ""
  }
  
  init(console: Console, res: Expr) {
    let appResult = AppletResult()
    appResult.include(res)
    var strings: [String] = []
    for str in appResult.strings {
      strings.append(str ?? "")
    }
    var files: [IntentFile] = []
    for file in appResult.files {
      files.append(file ?? IntentFile(data: Data(), filename: ""))
    }
    self.strings = strings
    self.files = files
    self.transcript = console.description
  }
  
  var displayRepresentation: DisplayRepresentation {
    let firstLine = self.strings.first ?? "Terminated"
    var firstImage: DisplayRepresentation.Image? = nil
    for file in self.files {
      if let image = file.displayRepresentation.image {
        firstImage = image
        break
      }
    }
    var transcript = self.transcript
    if transcript.count > 300 {
      transcript = String(transcript.prefix(299)) + " ⃨"
    }
    return DisplayRepresentation(title: "\(firstLine)",
                                 subtitle: "\(transcript)",
                                 image: firstImage)
  }
}

struct EvalFailure: Error, CustomLocalizedStringResourceConvertible, CustomStringConvertible {
  let message: String
  let transcript: String
  
  var localizedStringResource: LocalizedStringResource {
    return "\(self.message)"
  }
  
  var description: String {
    return self.message
  }
  
  var localizedDescription: String {
    return self.message
  }
}
