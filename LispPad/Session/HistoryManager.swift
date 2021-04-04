//
//  HistoryManager.swift
//  LispPad
//
//  Created by Matthias Zenger on 27/03/2021.
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

import SwiftUI

final class HistoryManager: ObservableObject {
  private static let historyUserDefaultsKey = "Console.history"
  private static let maxHistoryUserDefaultsKey = "Console.maxHistory"
  private static let maxHistoryMax = 100
  
  @Published var consoleHistory: [String] = {
    return UserDefaults.standard.object(forKey: HistoryManager.historyUserDefaultsKey)
             as? [String] ?? ["(string-append (os-name) \" \" (os-release))"]
  }()
  
  private(set) var maxHistory: Int = {
    let maxCount = UserDefaults.standard.integer(forKey: HistoryManager.maxHistoryUserDefaultsKey)
    return maxCount == 0 ? 20 : maxCount
  }()
  
  private var historyRequiresSaving: Bool = false
  
  func addConsoleEntry(_ str: String) {
    self.consoleHistory.append(str)
    if self.maxHistory < self.consoleHistory.count {
      self.consoleHistory.removeFirst(self.consoleHistory.count - self.maxHistory)
    }
    self.historyRequiresSaving = true
  }
  
  func setMaxHistoryCount(to max: Int) {
    if max > 0 && max <= HistoryManager.maxHistoryMax {
      UserDefaults.standard.set(max, forKey: HistoryManager.maxHistoryUserDefaultsKey)
      self.maxHistory = max
      if max < self.consoleHistory.count {
        self.consoleHistory.removeFirst(self.consoleHistory.count - max)
        self.historyRequiresSaving = true
      }
    }
  }
  
  func saveConsoleHistory() {
    if self.historyRequiresSaving {
      UserDefaults.standard.set(self.consoleHistory, forKey: HistoryManager.historyUserDefaultsKey)
      self.historyRequiresSaving = false
    }
  }
}
