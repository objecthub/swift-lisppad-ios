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
  private static let maxFilesHistoryMax = 50
  
  private static let favoritesUserDefaultsKey = "Files.favorites"
  private static let maxFavoritesUserDefaultsKey = "Files.maxFavorites"
  private static let maxFavoritesMax = 20
  
  private let encoder: PropertyListEncoder = {
    let encoder = PropertyListEncoder()
    encoder.outputFormat = .binary
    return encoder
  }()
  
  @Published var consoleHistory: [String] = {
    return UserDefaults.standard.object(forKey: HistoryManager.consoleHistoryUserDefaultsKey)
             as? [String] ?? ["(string-append (os-name) \" \" (os-release))"]
  }()
  
  @Published var recentlyEdited: [PortableURL] = {
    if let data = UserDefaults.standard.value(forKey:
                    HistoryManager.filesHistoryUserDefaultsKey) as? Data,
       let purls = try? PropertyListDecoder().decode(Array<PortableURL>.self, from: data) {
      var res: [PortableURL] = []
      for purl in purls {
        if purl.itemExists {
          res.append(purl)
        }
      }
      return res
    } else {
      return []
    }
  }()
  
  @Published var favoriteFiles: [PortableURL] = {
    if let data = UserDefaults.standard.value(forKey:
                    HistoryManager.favoritesUserDefaultsKey) as? Data,
       let purls = try? PropertyListDecoder().decode(Array<PortableURL>.self, from: data) {
      var res: [PortableURL] = []
      for purl in purls {
        if purl.itemExists {
          res.append(purl)
        }
      }
      return res
    } else {
      return []
    }
  }()
  
  // Console History
  
  private(set) var maxConsoleHistory: Int = {
    let maxCount = UserDefaults.standard.integer(forKey:
                                                  HistoryManager.maxConsoleHistoryUserDefaultsKey)
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
      UserDefaults.standard.set(self.consoleHistory, forKey:
                                  HistoryManager.consoleHistoryUserDefaultsKey)
      self.consoleHistoryRequiresSaving = false
    }
  }
  
  // Files history
  
  private(set) var maxFilesHistory: Int = {
    let maxCount = UserDefaults.standard.integer(forKey:
                                                  HistoryManager.maxFilesHistoryUserDefaultsKey)
    return maxCount == 0 ? 8 : maxCount
  }()
  
  private var filesHistoryRequiresSaving: Bool = false
  
  func trackRecentFile(_ url: URL) {
    let purl = PortableURL(url: url)
    loop: for i in self.recentlyEdited.indices {
      if self.recentlyEdited[i] == purl {
        self.recentlyEdited.remove(at: i)
        break loop
      }
    }
    self.recentlyEdited.insert(purl, at: 0)
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
      UserDefaults.standard.set(try? self.encoder.encode(self.recentlyEdited),
                                forKey: HistoryManager.filesHistoryUserDefaultsKey)
      self.filesHistoryRequiresSaving = false
    }
  }
  
  // Favorites
  
  private(set) var maxFavorites: Int = {
    let maxCount = UserDefaults.standard.integer(forKey:
                                                  HistoryManager.maxFavoritesUserDefaultsKey)
    return maxCount == 0 ? 8 : maxCount
  }()
  
  private var favoritesRequiresSaving: Bool = false
  
  func registerFavorite(_ url: URL) {
    let purl = PortableURL(url: url)
    loop: for i in self.favoriteFiles.indices {
      if self.favoriteFiles[i] == purl {
        self.favoriteFiles.remove(at: i)
        break loop
      }
    }
    self.favoriteFiles.insert(purl, at: 0)
    if self.maxFavorites < self.favoriteFiles.count {
      self.favoriteFiles.removeLast(self.favoriteFiles.count - self.maxFavorites)
    }
    self.favoritesRequiresSaving = true
  }
  
  func setMaxFavoritesCount(to max: Int) {
    if max > 0 && max <= HistoryManager.maxFavoritesMax {
      UserDefaults.standard.set(max, forKey: HistoryManager.maxFavoritesUserDefaultsKey)
      self.maxFavorites = max
      if max < self.favoriteFiles.count {
        self.favoriteFiles.removeLast(self.favoriteFiles.count - max)
        self.favoritesRequiresSaving = true
      }
    }
  }
  
  func saveFavorites() {
    if self.favoritesRequiresSaving {
      UserDefaults.standard.set(try? self.encoder.encode(self.favoriteFiles),
                                forKey: HistoryManager.favoritesUserDefaultsKey)
      self.favoritesRequiresSaving = false
    }
  }
}
