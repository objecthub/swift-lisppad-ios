//
//  AsyncResult.swift
//  LispPad
//
//  Created by Matthias Zenger on 11/11/2023.
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

final class AsyncResult<T> {
  enum State {
    case waiting
    case aborted
    case error(Error)
    case result(T)
  }
  
  private let condition = NSCondition()
  private var state: State = .waiting
  
  func set(value res: T) {
    self.condition.lock()
    defer {
      self.condition.unlock()
    }
    self.state = .result(res)
    self.condition.signal()
  }
  
  func set(error err: Error) {
    self.condition.lock()
    defer {
      self.condition.unlock()
    }
    self.state = .error(err)
    self.condition.signal()
  }
  
  func abort() {
    self.condition.lock()
    defer {
      self.condition.unlock()
    }
    if case .waiting = state {
      self.state = .aborted
    }
    self.state = .aborted
    self.condition.signal()
  }
  
  func value(aborted: T) throws -> T {
    self.condition.lock()
    defer {
      self.condition.unlock()
    }
    while case .waiting = self.state {
      self.condition.wait()
    }
    switch self.state {
      case .aborted, .waiting:
        return aborted
      case .error(let err):
        throw err
      case .result(let res):
        return res
    }
  }
}
