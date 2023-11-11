//
//  AsyncResult.swift
//  LispPad
//
//  Created by Matthias Zenger on 11/11/2023.
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
