//
//  TextDocument.swift
//  LispPad
//
//  Created by Matthias Zenger on 06/04/2021.
//

import UIKit
import SwiftUI

final class TextDocument: UIDocument, ObservableObject, Identifiable {
  @Published var text: String = ""
  @Published var title: String = "Untitled"
  var new: Bool = true
  
  var id: URL {
    return self.fileURL
  }
  
  func recomputeTitle(_ url: URL? = nil) {
    self.title = (url ?? self.fileURL).deletingPathExtension().lastPathComponent
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
  
  func moveFile(to url: URL) {
    let oldUrl = self.fileURL
    DispatchQueue.global(qos: .default).async {
      var coordinatorError: NSError?
      let fileCoordinator = NSFileCoordinator(filePresenter: nil)
      fileCoordinator.coordinate(writingItemAt: oldUrl,
                                 options: .forMoving,
                                 writingItemAt: url,
                                 options: .forReplacing,
                                 error: &coordinatorError) { newURL1, newURL2 in
        let fileManager = Foundation.FileManager.default
        fileCoordinator.item(at: oldUrl, willMoveTo: url)
        do {
          try fileManager.moveItem(at: newURL1, to: newURL2)
          fileCoordinator.item(at: oldUrl, didMoveTo: url)
        } catch {
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
