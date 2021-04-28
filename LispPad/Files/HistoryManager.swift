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
  private static let maxFilesHistoryMax = 15
  
  private static let favoritesUserDefaultsKey = "Files.favorites"
  private static let maxFavoritesUserDefaultsKey = "Files.maxFavorites"
  private static let maxFavoritesMax = 50
  
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
  
  let documentsTracker = DirectoryTracker(PortableURL.Base.documents.url)
  let icloudTracker = DirectoryTracker(PortableURL.Base.icloud.url)
  
  init() {
    self.documentsTracker?.onDelete = { [weak self] url in
      let purl = PortableURL(url: url)
      _ = self?.removeRecentFile(purl)
      _ = self?.removeFavorite(purl)
    }
    self.documentsTracker?.onMove = { [weak self] oldURL, newURL in
      let oldPurl = PortableURL(url: oldURL)
      let newPurl = PortableURL(url: newURL)
      if let i = self?.removeRecentFile(oldPurl) {
        self?.recentlyEdited.insert(newPurl, at: i)
      }
      if let i = self?.removeFavorite(oldPurl) {
        self?.favoriteFiles.insert(newPurl, at: i)
      }
    }
    self.icloudTracker?.onDelete = { [weak self] url in
      let purl = PortableURL(url: url)
      _ = self?.removeRecentFile(purl)
      _ = self?.removeFavorite(purl)
    }
    self.icloudTracker?.onMove = { [weak self] oldURL, newURL in
      let oldPurl = PortableURL(url: oldURL)
      let newPurl = PortableURL(url: newURL)
      if let i = self?.removeRecentFile(oldPurl) {
        self?.recentlyEdited.insert(newPurl, at: i)
      }
      if let i = self?.removeFavorite(oldPurl) {
        self?.favoriteFiles.insert(newPurl, at: i)
      }
    }
  }
  
  deinit {
    if let filePresenter = self.documentsTracker {
      NSFileCoordinator.removeFilePresenter(filePresenter)
    }
    if let filePresenter = self.icloudTracker {
      NSFileCoordinator.removeFilePresenter(filePresenter)
    }
  }
  
  func setupFilePresenters() {
    if let filePresenter = self.documentsTracker {
      NSFileCoordinator.addFilePresenter(filePresenter)
    }
    if let filePresenter = self.icloudTracker {
      NSFileCoordinator.addFilePresenter(filePresenter)
    }
  }
  
  func suspendFilePresenters() {
    if let filePresenter = self.documentsTracker {
      NSFileCoordinator.removeFilePresenter(filePresenter)
    }
    if let filePresenter = self.icloudTracker {
      NSFileCoordinator.removeFilePresenter(filePresenter)
    }
  }
  
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
    _ = self.removeRecentFile(purl)
    self.recentlyEdited.insert(purl, at: 0)
    if self.maxFilesHistory < self.recentlyEdited.count {
      self.recentlyEdited.removeLast(self.recentlyEdited.count - self.maxFilesHistory)
    }
    self.filesHistoryRequiresSaving = true
  }
  
  func removeRecentFile(_ purl: PortableURL) -> Int? {
    for i in self.recentlyEdited.indices {
      if self.recentlyEdited[i] == purl {
        self.recentlyEdited.remove(at: i)
        self.filesHistoryRequiresSaving = true
        return i
      }
    }
    return nil
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
  
  func isFavorite(_ url: URL?) -> Bool {
    guard let purl = PortableURL(url) else {
      return false
    }
    for i in self.favoriteFiles.indices {
      if self.favoriteFiles[i] == purl {
        return true
      }
    }
    return false
  }
  
  func canBeFavorite(_ url: URL?) -> Bool {
    guard let purl = PortableURL(url) else {
      return false
    }
    return purl.base != .application
  }
  
  func toggleFavorite(_ url: URL?) {
    guard let url = url else {
      return
    }
    let purl = PortableURL(url: url)
    if self.removeFavorite(purl) == nil {
      self.favoriteFiles.insert(purl, at: 0)
      if self.maxFavorites < self.favoriteFiles.count {
        self.favoriteFiles.removeLast(self.favoriteFiles.count - self.maxFavorites)
      }
      self.favoritesRequiresSaving = true
    }
  }
  
  func registerFavorite(_ url: URL) {
    let purl = PortableURL(url: url)
    _ = self.removeFavorite(purl)
    self.favoriteFiles.insert(purl, at: 0)
    if self.maxFavorites < self.favoriteFiles.count {
      self.favoriteFiles.removeLast(self.favoriteFiles.count - self.maxFavorites)
    }
    self.favoritesRequiresSaving = true
  }
  
  func removeFavorite(_ purl: PortableURL) -> Int? {
    for i in self.favoriteFiles.indices {
      if self.favoriteFiles[i] == purl {
        self.favoriteFiles.remove(at: i)
        self.favoritesRequiresSaving = true
        return i
      }
    }
    return nil
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
