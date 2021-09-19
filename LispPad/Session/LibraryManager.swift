//
//  LibraryManager.swift
//  LispPad
//
//  Created by Matthias Zenger on 19/03/2021.
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
import Combine
import LispKit

final class LibraryManager: ObservableObject {
  
  struct LibraryProxy: Hashable, CustomStringConvertible {
    let name: String
    let library: Library?
    
    fileprivate init(scanned: String) {
      self.name = scanned
      self.library = nil
    }
    
    fileprivate init(loaded: Library) {
      self.name = loaded.name.description
      self.library = loaded
    }
    
    var isLoaded: Bool {
      return self.library != nil
    }
    
    var state: String {
      if let library = self.library {
        return library.state.description
      } else {
        return "found"
      }
    }
    
    var components: [String] {
      let strs = name[name.index(after: name.startIndex)..<name.index(before: name.endIndex)]
                   .split(separator: " ")
      var res: [String] = []
      for str in strs {
        res.append(String(str))
      }
      return res
    }
    
    var description: String {
      return self.name
    }
    
    static func ==(lhs: LibraryProxy, rhs: LibraryProxy) -> Bool {
      return lhs.name == rhs.name
    }
  }
  
  @Published var libraries: [LibraryProxy] = []
  private weak var fileHandler: FileHandler? = nil
  
  func attachFileHandler(_ lm: FileHandler) {
    self.fileHandler = lm
  }
  
  func add(library: Library) {
    let name = library.name.description
    var lo = 0
    var hi = self.libraries.count - 1
    while lo <= hi {
      let mid = (lo + hi)/2
      let current = self.libraries[mid].name
      switch name.localizedStandardCompare(current) {
        case .orderedDescending:
          lo = mid + 1
        case .orderedAscending:
          hi = mid - 1
        default:
          self.libraries[mid] = .init(loaded: library)
          return
      }
    }
    self.libraries.insert(.init(loaded: library), at: lo)
  }
  
  func updatedLibraries() -> [LibraryProxy] {
    var updated: [LibraryProxy] = []
    for proxy in self.libraries {
      if proxy.library != nil {
        updated.append(proxy)
      }
    }
    func addIfNew(_ scanned: String) {
      let name = "(" + scanned + ")"
      var lo = 0
      var hi = updated.count - 1
      while lo <= hi {
        let mid = (lo + hi)/2
        let current = updated[mid].name
        switch name.localizedStandardCompare(current) {
          case .orderedDescending:
            lo = mid + 1
          case .orderedAscending:
            hi = mid - 1
          default:
            return
        }
      }
      updated.insert(.init(scanned: name), at: lo)
    }
    let libs = self.scanLibraryTrees()
    for lib in libs {
      addIfNew(lib)
    }
    return updated
  }
  
  func scheduleLibraryUpdate() {
    DispatchQueue.global(qos: .background).async {
      let updatedLibraries = self.updatedLibraries()
      DispatchQueue.main.async {
        self.libraries = updatedLibraries
      }
    }
  }
  
  func updateLibraries() {
    self.libraries = self.updatedLibraries()
  }
  
  private func scanLibraryTrees() -> Set<String> {
    let fileManager = Foundation.FileManager.default
    var res: Set<String> = []
    guard let rootUrls = self.fileHandler?.librarySearchUrls else {
      return res
    }
    func scan(url: URL, name: String?) {
      guard let items = try? fileManager.contentsOfDirectory(atPath: url.path) else {
        return
      }
      for item in items {
        var itemUrl = url.appendingPathComponent(item)
        var isDir: ObjCBool = false
        if fileManager.fileExists(atPath: itemUrl.path, isDirectory: &isDir) {
          if isDir.boolValue {
            scan(url: itemUrl, name: name == nil ? item : name! + " " + item)
          } else if itemUrl.pathExtension == "sld" {
            itemUrl.deletePathExtension()
            if let name = name {
              res.insert(name + " " + itemUrl.lastPathComponent)
            } else {
              res.insert(itemUrl.lastPathComponent)
            }
          }
        }
      }
    }
    for rootUrl in rootUrls {
      scan(url: rootUrl, name: nil)
    }
    return res
  }
  
  func reset() {
    self.fileHandler = nil
    self.libraries.removeAll()
  }
}
