//
//  EnvironmentManager.swift
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

final class EnvironmentManager: ObservableObject {
  @Published var bindings: [Symbol] = []
  
  func add(symbol: Symbol) {
    EnvironmentManager.insert(symbol: symbol, into: &self.bindings)
  }
  
  private static func insert(symbol: Symbol, into bindings: inout [Symbol]) {
    let identifier = symbol.identifier
    var lo = 0
    var hi = bindings.count - 1
    while lo <= hi {
      let mid = (lo + hi) / 2
      let current = bindings[mid].identifier
      if current < identifier {
        lo = mid + 1
      } else if identifier < current {
        hi = mid - 1
      } else {
        lo = mid
        break
      }
    }
    bindings.insert(symbol, at: lo)
  }
  
  func reset() {
    self.bindings.removeAll()
  }
}
