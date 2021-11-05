//
//  TaskSerializer.swift
//  LispPad
//
//  Created by Matthias Zenger on 05/11/2021.
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

public final class TaskSerializer: Thread {
  
  /// Condition to synchronize access to `tasks`.
  private let condition = NSCondition()
  
  /// The tasks queue.
  private var tasks = [() -> Void]()
  
  public init(stackSize: Int = 8_388_608, qos: QualityOfService = .userInitiated) {
    super.init()
    self.stackSize = stackSize
    self.qualityOfService = qos
  }
  
  /// Don't call directly; this is the main method of the serializer thread.
  public override func main() {
    while !self.isCancelled {
      self.condition.lock()
      while self.tasks.isEmpty {
        self.condition.wait()
      }
      let task = self.tasks.removeFirst()
      self.condition.unlock()
      task()
    }
    self.condition.lock()
    self.tasks.removeAll()
    self.condition.unlock()
  }
  
  /// Schedule a task in this serializer thread.
  public func schedule(task: @escaping () -> Void) {
    self.condition.lock()
    self.tasks.append(task)
    self.condition.signal()
    self.condition.unlock()
  }
}
