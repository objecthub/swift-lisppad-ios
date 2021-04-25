//
//  DirectoryTracker.swift
//  LispPad
//
//  Created by Matthias Zenger on 25/04/2021.
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
