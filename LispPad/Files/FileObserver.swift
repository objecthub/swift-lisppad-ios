//
//  FileObserver.swift
//  LispPad
//
//  Created by Matthias Zenger on 28/08/2021.
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

/// 
/// A `FileObserver` object tracks changes in the iCloud container and makes sure that changed
/// files are updated as quickly as possible (e.g. by downloading the file), making iOS behave
/// similarly like macOS.
/// 
class FileObserver {
  
  static let `default` = FileObserver(containerIdentifier: nil)
  
  /// The status of files
  enum SyncStatus: CustomStringConvertible {
    case unknown
    case current
    case outdated
    case missing
    
    init(_ uds: String?) {
      if let status = uds {
        switch status {
          case NSMetadataUbiquitousItemDownloadingStatusCurrent:
            self = .current
          case NSMetadataUbiquitousItemDownloadingStatusDownloaded:
            self = .outdated
          case NSMetadataUbiquitousItemDownloadingStatusNotDownloaded:
            self = .missing
          default:
            self = .unknown
        }
      } else {
        self = .unknown
      }
    }
    
    var description: String {
      switch self {
        case .unknown:
          return "unknown"
        case .current:
          return "current"
        case .outdated:
          return "outdated"
        case .missing:
          return "missing"
      }
    }
  }
  
  /// The metadata query to monitor the iCloud metadata
  private let metadataQuery = NSMetadataQuery()
  
  /// The latest file sync state
  private(set) var fileSyncStatus: [URL : SyncStatus] = [:]
  
  init?(containerIdentifier: String?) {
    // Make sure that iCloud is enabled
    guard Foundation.FileManager.default.ubiquityIdentityToken != nil else {
      return nil
    }
    // Set up a metadata query to collect changes to files in the iCloud container
    metadataQuery.notificationBatchingInterval = 1
    metadataQuery.searchScopes = [NSMetadataQueryUbiquitousDocumentsScope,
                                  NSMetadataQueryAccessibleUbiquitousExternalDocumentsScope]
    metadataQuery.predicate = NSPredicate(format: "%K LIKE %@", NSMetadataItemFSNameKey, "*")
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(initialQueryResults),
                                           name: .NSMetadataQueryDidFinishGathering,
                                           object: nil)
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(updateQueryResults),
                                           name: .NSMetadataQueryDidUpdate,
                                           object: nil)
    // Start the metadata query
    metadataQuery.start()
  }
  
  /// Stop query if it is still running
  deinit {
    if metadataQuery.isStarted {
      metadataQuery.stop()
    }
  }
  
  /// Return file urls matching the filter `current`. Setting `current` to nil is equivalent
  /// to not using a filter.
  func observedFiles(_ current: Bool?) -> [URL] {
    var res: [URL] = []
    for (url, status) in self.fileSyncStatus {
      if let current = current {
        if current && status == .current {
          res.append(url)
        } else if !current && status != .current {
          res.append(url)
        }
      } else {
        res.append(url)
      }
    }
    return res
  }
  
  /// Process initial query results
  @objc func initialQueryResults(notification: NSNotification) {
    metadataQuery.disableUpdates()
    self.fileSyncStatus.removeAll()
    self.processResults { url, status in
      self.fileSyncStatus[url] = status
      if status != .current {
        _ = try? Foundation.FileManager.default.startDownloadingUbiquitousItem(at: url)
      }
    }
    metadataQuery.enableUpdates()
  }
  
  /// Update query results
  @objc func updateQueryResults(notification: NSNotification) {
    metadataQuery.disableUpdates()
    defer {
      metadataQuery.enableUpdates()
    }
    var updatedFileSyncStatus: [URL : SyncStatus] = [:]
    self.processResults { url, status in
      updatedFileSyncStatus[url] = status
      if let formerStatus = self.fileSyncStatus[url] {
        if (status == .outdated || status == .missing) &&
           (formerStatus == .current || formerStatus == .unknown) {
          _ = try? Foundation.FileManager.default.startDownloadingUbiquitousItem(at: url)
        }
      } else {
        _ = try? Foundation.FileManager.default.startDownloadingUbiquitousItem(at: url)
      }
    }
    self.fileSyncStatus = updatedFileSyncStatus
  }
  
  private static let resourceKeys: [URLResourceKey] = [.isDirectoryKey, .isPackageKey]
  
  private func processResults(_ proc: (URL, SyncStatus) -> Void) {
    if let items = metadataQuery.results as? [NSMetadataItem] {
      for item in items {
        // Make sure this item has a valid URL and file name
        guard let url = item.value(forAttribute: NSMetadataItemURLKey) as? URL,
              item.value(forAttribute: NSMetadataItemFSNameKey) != nil else {
          continue
        }
        // Make sure this item is not a directory (but allow packages)
        if let resourceValues = try? (url as NSURL).resourceValues(
                                       forKeys: FileObserver.resourceKeys),
           let isDirectory = resourceValues[URLResourceKey.isDirectoryKey] as? Bool,
           isDirectory,
           let isPackage = resourceValues[URLResourceKey.isPackageKey] as? Bool,
           !isPackage {
          continue
        }
        // Retrieve the download status
        let status = SyncStatus(item.value(forAttribute:
                                            NSMetadataUbiquitousItemDownloadingStatusKey)
                                as? String)
        proc(url, status)
      }
    }
  }
}
