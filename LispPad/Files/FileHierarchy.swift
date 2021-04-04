//
//  FileHierarchy.swift
//  LispPad
//
//  Created by Matthias Zenger on 02/04/2021.
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

struct FileHierarchy: Hashable {
  
  enum Kind: Hashable {
    case file
    case directory
    case root(String, String)
  }
  
  final class Children {
    let url: URL
    private var cache: [FileHierarchy]? = nil
    
    init(_ url: URL) {
      self.url = url
    }
    
    var children: [FileHierarchy] {
      if self.cache == nil {
        if let contents = try? Foundation.FileManager.default.contentsOfDirectory(
                                 at: self.url,
                                 includingPropertiesForKeys: nil,
                                 options: [.skipsPackageDescendants, .skipsHiddenFiles]) {
          let sortedContents = contents.sorted { a, b in
            return a.lastPathComponent.localizedStandardCompare(b.lastPathComponent)
                     == .orderedAscending
          }
          var res: [FileHierarchy] = []
          for url in sortedContents {
            if let child = FileHierarchy(url, parent: self) {
              res.append(child)
            }
          }
          self.cache = res
        } else {
          self.cache = []
        }
      }
      return self.cache ?? []
    }
    
    func reset() {
      self.cache = nil
    }
  }
  
  let url: URL
  let kind: Kind
  let container: Children?
  unowned let parent: Children?
  
  var children: [FileHierarchy]? {
    self.container?.children
  }
  
  init?(_ url: URL, parent: Children? = nil) {
    var dir: ObjCBool = false
    if Foundation.FileManager.default.fileExists(atPath: url.absoluteURL.path, isDirectory: &dir) {
      self.url = url
      self.kind = dir.boolValue ? .directory : .file
      self.container = dir.boolValue ? Children(url) : nil
      self.parent = parent
    } else {
      return nil
    }
  }
  
  init?(_ namedUrl: FileManager.NamedURL, parent: Children? = nil) {
    var dir: ObjCBool = false
    if Foundation.FileManager.default.fileExists(atPath: namedUrl.url.absoluteURL.path,
                                                 isDirectory: &dir) {
      self.url = namedUrl.url
      self.kind = dir.boolValue ? .root(namedUrl.name, namedUrl.image) : .file
      self.container = dir.boolValue ? Children(url) : nil
      self.parent = parent
    } else {
      return nil
    }
  }
  
  var name: String {
    switch self.kind {
      case .file, .directory:
        return self.url.lastPathComponent
      case .root(let name, _):
        return name
    }
  }
  
  var type: FileType {
    switch self.kind {
      case .file:
        return .file
      default:
        return .directory
    }
  }
  
  var systemImage: String {
    switch self.kind {
      case .file:
        switch self.url.pathExtension {
          case "scm", "sps", "ss", "sld", "sls", "lisp", "rkt", "md", "markdown", "txt":
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
      case .directory:
        return "folder"
      case .root(_, let image):
        return image
    }
  }
  
  func hash(into hasher: inout Hasher) {
    hasher.combine(self.url)
  }
  
  static func <(lhs: FileHierarchy, rhs: FileHierarchy) -> Bool {
    return lhs.url.path.localizedStandardCompare(rhs.url.path)
             == .orderedAscending
  }
  
  static func ==(lhs: FileHierarchy, rhs: FileHierarchy) -> Bool {
    return lhs.url == rhs.url
  }
}
