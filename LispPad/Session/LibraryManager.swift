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
  @Published var libraries: [Library] = []
  
  func add(library: Library) {
    let name = library.name.description
    var lo = 0
    var hi = self.libraries.count - 1
    while lo <= hi {
      let mid = (lo + hi)/2
      let current = self.libraries[mid].name.description
      switch name.localizedStandardCompare(current) {
        case .orderedDescending:
          lo = mid + 1
        case .orderedAscending:
          hi = mid - 1
        default:
          self.libraries[mid] = library
          return
      }
    }
    self.libraries.insert(library, at: lo)
  }
  
  func reset() {
    self.libraries.removeAll()
  }
}
