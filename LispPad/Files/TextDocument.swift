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

  struct Info {
    let title: String
    let new: Bool
    let editorType: FileExtensions.EditorType
  }

  /// Reference to the file manager
  weak var fileManager: FileManager? = nil {
    didSet {
      self.fileManager?.editorDocumentInfo = self.info
    }
  }

  /// Manage appearance of document
  @Published var info = Info(title: "Untitled", new: true, editorType: .scheme) {
    didSet {
      self.fileManager?.editorDocumentInfo = self.info
    }
  }

  /// Textual content
  @Published var text = ""

  /// Currently selected range
  @Published var selectedRange = NSRange(location: 0, length: 0)

  /// Buffer used by editor
  var lastContentOffset = CGPoint(x: 0, y: 0)

  var id: URL {
    return self.fileURL
  }
  
  func recomputeInfo(for url: URL? = nil, new: Bool) {
    self.info = Info(title: (url ?? self.fileURL).deletingPathExtension().lastPathComponent,
                     new: new,
                     editorType: FileExtensions.editorType(for: url ?? self.fileURL))
  }
  
  var saveAsURL: URL? {
    if self.info.new {
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
  
  var size: Int64? {
    do {
      let attribute = try Foundation.FileManager.default.attributesOfItem(atPath:
                                                                            self.fileURL.path())
      if let size = attribute[FileAttributeKey.size] as? NSNumber {
        return size.int64Value
      } else {
        return nil
      }
    } catch {
      return nil
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
    self.saveFile { success in 
      if success {
        if self.info.new {
          self.moveFile(to: url, complete: complete)
        } else {
          self.copyFile(to: url, complete: complete)
        }
        self.fileManager?.histManager.trackRecentFile(url)
      } else {
        complete(nil)
      }
    }
  }
  
  func moveFileTo(_ url: URL, complete: @escaping (URL?) -> Void) {
    self.saveFile { success in 
      if success {
        self.moveFile(to: url, complete: complete)
        self.fileManager?.histManager.trackRecentFile(url)
      } else {
        complete(nil)
      }
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
    self.fileManager?.histManager.trackCurrentFile(url)
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
            self.recomputeInfo(for: newURL2, new: false)
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
    self.fileManager?.histManager.trackCurrentFile(url)
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
            self.recomputeInfo(for: newURL2, new: false)
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
