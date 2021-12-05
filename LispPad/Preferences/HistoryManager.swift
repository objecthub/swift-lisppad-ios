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
  private static let commandHistoryUserDefaultsKey = "Console.history"
  private static let filesHistoryUserDefaultsKey = "Files.history"
  private static let searchHistoryUserDefaultsKey = "Files.searchHistory"
  private static let favoritesUserDefaultsKey = "Files.favorites"
  private static let maxFavoritesUserDefaultsKey = "Files.maxFavorites"
  private static let maxFavoritesMax = 50
  
  private let encoder: PropertyListEncoder = {
    let encoder = PropertyListEncoder()
    encoder.outputFormat = .binary
    return encoder
  }()
  
  @Published var commandHistory: [String] = {
    return UserDefaults.standard.object(forKey: HistoryManager.commandHistoryUserDefaultsKey)
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
  
  @Published var searchHistory: [SearchHistoryEntry] = {
    if let data = UserDefaults.standard.value(forKey:
                    HistoryManager.searchHistoryUserDefaultsKey) as? Data,
       let entries = try? PropertyListDecoder().decode(Array<SearchHistoryEntry>.self, from: data) {
      return entries
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
  
  var maxCommandHistory: Int {
    return UserSettings.standard.maxCommandHistory
  }
  
  private var commandHistoryRequiresSaving: Bool = false
  
  func addCommandEntry(_ input: String) {
    let str = input.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    if self.commandHistory.isEmpty || str != self.commandHistory.first! {
      self.commandHistory.removeAll { command in command == str }
      self.commandHistory.insert(str, at: 0)
      if self.maxCommandHistory < self.commandHistory.count {
        self.commandHistory.removeLast(self.commandHistory.count - self.maxCommandHistory)
      }
      self.commandHistoryRequiresSaving = true
    }
  }
  
  func saveCommandHistory() {
    if self.commandHistoryRequiresSaving {
      UserDefaults.standard.set(self.commandHistory, forKey:
                                  HistoryManager.commandHistoryUserDefaultsKey)
      self.commandHistoryRequiresSaving = false
    }
  }
  
  // Files history
  
  var maxFilesHistory: Int {
    return UserSettings.standard.maxRecentFiles
  }
  
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
  
  func saveFilesHistory() {
    if self.filesHistoryRequiresSaving {
      UserDefaults.standard.set(try? self.encoder.encode(self.recentlyEdited),
                                forKey: HistoryManager.filesHistoryUserDefaultsKey)
      self.filesHistoryRequiresSaving = false
    }
  }
  
  // Search history
  
  var maxSearchHistory: Int {
    return 20
  }
  
  private var searchHistoryRequiresSaving: Bool = false
  
  func rememberSearch(_ entry: SearchHistoryEntry) {
    self.removeRecentSearch(entry)
    self.searchHistory.insert(entry, at: 0)
    if self.maxSearchHistory < self.searchHistory.count {
      self.searchHistory.removeLast(self.searchHistory.count - self.maxSearchHistory)
    }
    self.searchHistoryRequiresSaving = true
  }
  
  func removeRecentSearch(_ entry: SearchHistoryEntry) {
    for i in self.searchHistory.indices {
      if self.searchHistory[i] == entry {
        self.searchHistory.remove(at: i)
        self.searchHistoryRequiresSaving = true
        return
      }
    }
  }
  
  func saveSearchHistory() {
    if self.searchHistoryRequiresSaving {
      UserDefaults.standard.set(try? self.encoder.encode(self.searchHistory),
                                forKey: HistoryManager.searchHistoryUserDefaultsKey)
      self.searchHistoryRequiresSaving = false
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

struct SearchHistoryEntry: Hashable, Codable, CustomStringConvertible {
  let searchText: String
  let replaceText: String?
  
  var searchOnly: Bool {
    return self.replaceText == nil
  }
  
  var description: String {
    if let replaceText = self.replaceText {
      return "\(self.searchText) ▶︎ \(replaceText)"
    } else {
      return self.searchText
    }
  }
}
