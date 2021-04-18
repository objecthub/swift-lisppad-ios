//
//  TextDocument.swift
//  LispPad
//
//  Created by Matthias Zenger on 06/04/2021.
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

import UIKit
import SwiftUI

final class TextDocument: UIDocument, ObservableObject, Identifiable {
  
  weak var fileManager: FileManager? = nil
  
  // Manage appearance of text document
  @Published var title = "Untitled" {
    didSet {
      self.fileManager?.editorDocumentTitle = self.title
    }
  }
  
  @Published var new: Bool = true {
    didSet {
      self.fileManager?.editorDocumentNew = self.new
    }
  }
  
  // State of text document
  @Published var text = ""
  @Published var selectedRange = NSRange(location: 0, length: 0)
  
  var lastContentOffset = CGPoint(x: 0, y: 0)
  
  var id: URL {
    return self.fileURL
  }
  
  func recomputeTitle(_ url: URL? = nil) {
    self.title = (url ?? self.fileURL).deletingPathExtension().lastPathComponent
  }
  
  var saveAsURL: URL? {
    if self.new {
      return PortableURL.Base.documents.url?.appendingPathComponent("Untitled.scm")
    } else {
      return self.fileURL
    }
  }
  
  var fileExists: Bool {
    if let _ = try? self.fileURL.resourceValues(forKeys: [.isUbiquitousItemKey]).isUbiquitousItem {
      return (try? self.fileURL.checkPromisedItemIsReachable()) ?? false
    } else {
      return (try? self.fileURL.checkResourceIsReachable()) ?? false
    }
  }
  
  func loadFile(action: @escaping ((Bool) -> Void) = { success in }) {
    if self.fileExists {
      self.open(completionHandler: action)
    } else {
      self.save(to: self.fileURL, for: .forCreating, completionHandler: action)
    }
  }
  
  func saveFile(action: @escaping ((Bool) -> Void) = { success in }) {
    self.save(to: self.fileURL, for: .forOverwriting, completionHandler: action)
  }
  
  func saveFileAs(_ url: URL, complete: @escaping (URL?) -> Void) {
    if self.new {
      self.moveFile(to: url, complete: complete)
    } else {
      self.copyFile(to: url, complete: complete)
    }
  }
  
  func rename(to name: String, complete: @escaping (URL?) -> Void) {
    self.moveFile(to: self.fileURL.deletingLastPathComponent().appendingPathComponent(name),
                  complete: complete)
  }
  
  func moveFile(to url: URL, complete: @escaping (URL?) -> Void) {
    let oldUrl = self.fileURL
    guard url != oldUrl else {
      self.saveFile { success in
        complete(success ? url : nil)
      }
      return
    }
    DispatchQueue.global(qos: .default).async {
      var coordinatorError: NSError?
      let fileCoordinator = NSFileCoordinator(filePresenter: self)
      fileCoordinator.coordinate(writingItemAt: oldUrl,
                                 options: .forMoving,
                                 writingItemAt: url,
                                 options: .forReplacing,
                                 error: &coordinatorError) { newURL1, newURL2 in
        let fileManager = Foundation.FileManager()
        do {
          _ = try? fileManager.removeItem(at: newURL2)
          try fileManager.moveItem(at: newURL1, to: newURL2)
          self.presentedItemDidMove(to: newURL2)
          DispatchQueue.main.async {
            self.recomputeTitle(newURL2)
            self.new = false
            complete(newURL2)
          }
        } catch {
          DispatchQueue.main.async {
            complete(nil)
          }
        }
      }
    }
  }
  
  func copyFile(to url: URL, complete: @escaping (URL?) -> Void) {
    let oldUrl = self.fileURL
    guard url != oldUrl else {
      self.saveFile { success in
        complete(success ? url : nil)
      }
      return
    }
    DispatchQueue.global(qos: .default).async {
      var coordinatorError: NSError?
      let fileCoordinator = NSFileCoordinator(filePresenter: self)
      fileCoordinator.coordinate(readingItemAt: oldUrl,
                                 options: [],
                                 writingItemAt: url,
                                 options: .forReplacing,
                                 error: &coordinatorError) { newURL1, newURL2 in
        let fileManager = Foundation.FileManager()
        do {
          _ = try? fileManager.removeItem(at: newURL2)
          try fileManager.copyItem(at: newURL1, to: newURL2)
          self.presentedItemDidMove(to: newURL2)
          DispatchQueue.main.async {
            self.recomputeTitle(newURL2)
            self.new = false
            complete(newURL2)
          }
        } catch {
          DispatchQueue.main.async {
            complete(nil)
          }
        }
      }
    }
  }
  
  override func load(fromContents contents: Any, ofType typeName: String?) throws {
    if let data = contents as? Data {
      self.text = String(data: data, encoding: .utf8) ?? ""
    }
  }
  
  override func contents(forType typeName: String) throws -> Any {
    return self.text.data(using: .utf8) ?? Data()
  }
}
