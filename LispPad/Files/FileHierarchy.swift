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

struct FileHierarchy: Hashable, Identifiable {
  
  enum Kind: Hashable {
    case file
    case directory
    case root(String, String)
  }
  
  final class Children {
    let kind: NamedRef.Kind
    private var cache: [FileHierarchy]? = nil
    
    init(_ kind: NamedRef.Kind) {
      self.kind = kind
    }
    
    var children: [FileHierarchy] {
      if self.cache == nil {
        switch kind {
          case .url(let url):
            if let contents = try? Foundation.FileManager.default.contentsOfDirectory(
                                     at: url,
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
          case .collection(let gen):
            var res: [FileHierarchy] = []
            let urls = gen()
            for url in urls {
              if let child = FileHierarchy(url, parent: self) {
                res.append(child)
              }
            }
            self.cache = res
        }
      }
      return self.cache ?? []
    }
    
    func reset() {
      self.cache = nil
    }
  }
  
  let url: URL?
  let kind: Kind
  let container: Children?
  unowned let parent: Children?
  
  var id: String {
    return self.url?.absoluteString ?? self.name
  }
  
  var children: [FileHierarchy]? {
    self.container?.children
  }
  
  init?(_ url: URL, parent: Children? = nil) {
    var dir: ObjCBool = false
    if Foundation.FileManager.default.fileExists(atPath: url.absoluteURL.path, isDirectory: &dir) {
      self.url = url
      self.kind = dir.boolValue ? .directory : .file
      self.container = dir.boolValue ? Children(.url(url)) : nil
      self.parent = parent
    } else {
      return nil
    }
  }
  
  init?(_ namedRef: NamedRef, parent: Children? = nil) {
    switch namedRef.kind {
      case .collection(_):
        self.url = nil
        self.kind = .root(namedRef.name, namedRef.image)
        self.container = Children(namedRef.kind)
        self.parent = parent
      case .url(let url):
        var dir: ObjCBool = false
        if Foundation.FileManager.default.fileExists(atPath: url.absoluteURL.path,
                                                     isDirectory: &dir) {
          self.url = url
          self.kind = dir.boolValue ? .root(namedRef.name, namedRef.image) : .file
          self.container = dir.boolValue ? Children(namedRef.kind) : nil
          self.parent = parent
        } else {
          return nil
        }
    }
  }
  
  var name: String {
    switch self.kind {
      case .file, .directory:
        return self.url?.lastPathComponent ?? "<unknown>"
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
        if let url = self.url {
          switch url.pathExtension {
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
        } else {
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
    hasher.combine(self.kind)
  }
  
  /*
  static func <(lhs: FileHierarchy, rhs: FileHierarchy) -> Bool {
    return lhs.url.path.localizedStandardCompare(rhs.url.path)
             == .orderedAscending
  }
  */
  
  static func ==(lhs: FileHierarchy, rhs: FileHierarchy) -> Bool {
    if case .root(let lname, _) = lhs.kind {
      if case .root(let rname, _) = rhs.kind {
        return lname == rname
      }
      return false
    } else if case .root(_, _) = rhs.kind {
      return false
    } else {
      return lhs.url == rhs.url
    }
  }
}
