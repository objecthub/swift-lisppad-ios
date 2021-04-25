//
//  DirectoryTracker.swift
//  LispPad
//
//  Created by Matthias Zenger on 25/04/2021.
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

class DirectoryTracker: NSObject, NSFilePresenter {
  var presentedItemURL: URL?
  var presentedItemOperationQueue: OperationQueue = OperationQueue.main
  var onMove: ((URL, URL) -> Void)? = nil
  var onDelete: ((URL) -> Void)? = nil
  
  init?(_ url: URL?) {
    guard let url = url else {
      return nil
    }
    self.presentedItemURL = url
  }
  
  func presentedSubitemDidChange(at url: URL) {
    if !Foundation.FileManager.default.fileExists(atPath: url.absoluteURL.path) {
      self.onDelete?(url)
    }
  }
  
  func presentedSubitem(at oldURL: URL, didMoveTo newURL: URL) {
    self.onMove?(oldURL, newURL)
  }
  
  func accommodatePresentedSubitemDeletion(at url: URL, 
                                           completionHandler: @escaping (Error?) -> Void) {
    self.onDelete?(url)
    completionHandler(nil)
  }
}
