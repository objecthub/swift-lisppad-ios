//
//  FileExtensions.swift
//  LispPad
//
//  Created by Matthias Zenger on 30/04/2021.
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

struct FileExtensions {
  
  enum EditorType: Int, Equatable {
    case scheme
    case markdown
    case other
  }
  
  static let editorSupport: Set<String> = ["sld", "scm", "sps", "sls", "ss", "sc", "sch",
                                           "lisp", "rkt", "txt", "md", "markdown"]
  
  static func editorType(for url: URL?) -> EditorType {
    guard let url = url else {
      return .scheme
    }
    switch url.pathExtension {
      case "scm", "sps", "ss", "sld", "sls", "sc", "sch",
           "lisp", "rkt":
        return .scheme
      case "md", "markdown", "txt":
        return .markdown
      default:
        return .other
    }
  }
  
  static func systemImage(for url: URL) -> String {
    switch url.pathExtension {
      case "scm", "sps", "ss", "sld", "sls", "sc", "sch",
           "lisp", "rkt", "md", "markdown", "txt":
        return "doc.text"
      case "png", "jpg", "jpeg":
        return "photo"
      case "pdf", "pages":
        return "doc.richtext"
      case "mp3", "m4a", "m4b":
        return "hifispeaker"
      case "mp4":
        return "film"
      case "zip":
        return "doc.zipper"
      default:
        return "doc"
    }
  }
}
