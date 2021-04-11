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
  private static let consoleHistoryUserDefaultsKey = "Console.history"
  private static let maxConsoleHistoryUserDefaultsKey = "Console.maxHistory"
  private static let maxConsoleHistoryMax = 100
  
  private static let filesHistoryUserDefaultsKey = "Files.history"
  private static let maxFilesHistoryUserDefaultsKey = "Files.maxHistory"
  private static let maxFilesHistoryMax = 20
  
  @Published var consoleHistory: [String] = {
    return UserDefaults.standard.object(forKey: HistoryManager.consoleHistoryUserDefaultsKey)
             as? [String] ?? ["(string-append (os-name) \" \" (os-release))"]
  }()
  
  @Published var recentlyEdited: [URL] = {
    let strs = UserDefaults.standard.object(forKey: HistoryManager.filesHistoryUserDefaultsKey)
                 as? [String] ?? []
    var res: [URL] = []
    for str in strs {
      if let url = URL(string: str) {
        res.append(url)
      }
    }
    return res
  }()
  
  @Published var favoriteFiles: [URL] = []
  
  // Console History
  
  private(set) var maxConsoleHistory: Int = {
    let maxCount = UserDefaults.standard.integer(forKey: HistoryManager.maxConsoleHistoryUserDefaultsKey)
    return maxCount == 0 ? 20 : maxCount
  }()
  
  private var consoleHistoryRequiresSaving: Bool = false
  
  func addConsoleEntry(_ str: String) {
    self.consoleHistory.append(str)
    if self.maxConsoleHistory < self.consoleHistory.count {
      self.consoleHistory.removeFirst(self.consoleHistory.count - self.maxConsoleHistory)
    }
    self.consoleHistoryRequiresSaving = true
  }
  
  func setMaxConsoleHistoryCount(to max: Int) {
    if max > 0 && max <= HistoryManager.maxConsoleHistoryMax {
      UserDefaults.standard.set(max, forKey: HistoryManager.maxConsoleHistoryUserDefaultsKey)
      self.maxConsoleHistory = max
      if max < self.consoleHistory.count {
        self.consoleHistory.removeFirst(self.consoleHistory.count - max)
        self.consoleHistoryRequiresSaving = true
      }
    }
  }
  
  func saveConsoleHistory() {
    if self.consoleHistoryRequiresSaving {
      UserDefaults.standard.set(self.consoleHistory, forKey: HistoryManager.consoleHistoryUserDefaultsKey)
      self.consoleHistoryRequiresSaving = false
    }
  }
  
  // Files history
  
  private(set) var maxFilesHistory: Int = {
    let maxCount = UserDefaults.standard.integer(forKey: HistoryManager.maxFilesHistoryUserDefaultsKey)
    return maxCount == 0 ? 8 : maxCount
  }()
  
  private var filesHistoryRequiresSaving: Bool = false
  
  func addFileEntry(_ url: URL) {
    loop: for i in self.recentlyEdited.indices {
      if self.recentlyEdited[i] == url {
        self.recentlyEdited.remove(at: i)
        break loop
      }
    }
    self.recentlyEdited.insert(url, at: 0)
    if self.maxFilesHistory < self.recentlyEdited.count {
      self.recentlyEdited.removeLast(self.recentlyEdited.count - self.maxFilesHistory)
    }
    self.filesHistoryRequiresSaving = true
  }
  
  func setMaxFilesHistoryCount(to max: Int) {
    if max > 0 && max <= HistoryManager.maxFilesHistoryMax {
      UserDefaults.standard.set(max, forKey: HistoryManager.maxFilesHistoryUserDefaultsKey)
      self.maxFilesHistory = max
      if max < self.recentlyEdited.count {
        self.recentlyEdited.removeLast(self.recentlyEdited.count - max)
        self.filesHistoryRequiresSaving = true
      }
    }
  }
  
  func saveFilesHistory() {
    if self.filesHistoryRequiresSaving {
      var strs: [String] = []
      for url in self.recentlyEdited {
        strs.append(url.absoluteString)
      }
      UserDefaults.standard.set(strs, forKey: HistoryManager.filesHistoryUserDefaultsKey)
      self.filesHistoryRequiresSaving = false
    }
  }
}
