//
//  FileManager.swift
//  LispPad
//
//  Created by Matthias Zenger on 01/04/2021.
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
import UIKit
import LispKit

///
/// Class `FileManager` provides access to all files related to LispPad.
/// 
class FileManager: ObservableObject {
  
  /// The history manager.
  var histManager: HistoryManager? = nil
  
  /// The default iOS file manager.
  let sysFileManager = Foundation.FileManager.default
  
  /// Builtin resources
  let systemRootDirectories: [NamedRef] = {
    var roots: [NamedRef] = [
      NamedRef(name: "LispPad",
               image: "folder.badge.gear",
               url: URL(fileURLWithPath: "Root", relativeTo: Bundle.main.bundleURL.absoluteURL))
    ]
    if let base = Context.bundle?.bundleURL.absoluteURL {
      roots.append(NamedRef(name: "LispKit",
                            image: "folder.badge.gear",
                            url: URL(fileURLWithPath: Context.rootDirectory, relativeTo: base)))
    }
    return roots
  }()
  
  /// User-defined resources
  private(set) var userRootDirectories: [NamedRef] = []
  
  /// Favorite and recently edited resources
  private(set) var usageRootDirectories: [NamedRef] = []
  
  /// The URL of the application support directory, if available
  private(set) var applicationSupportURL: URL? = nil
  
  /// The document currently loaded into the editor
  @Published var editorDocument: TextDocument? = nil
  @Published var editorDocumentTitle: String = "Untitled"
  @Published var editorDocumentNew: Bool = true
  
  var baseURLs: [(URL, Int)] = []

  /// Constructor, responsible for defining the named resources as well as for setting them up
  /// initially.
  init() {
    DispatchQueue.global(qos: .default).async {
      let sysFileManager = Foundation.FileManager()
      if let url = FileManager.icloudDirectory() {
        self.userRootDirectories.append(NamedRef(name: "iCloud Drive",
                                                 image: "icloud",
                                                 url: url))
        _ = self.createExtensionDirectories(in: url, using: sysFileManager)
      }
      if let url = FileManager.documentsDirectory() {
        let name: String
        let image: String
        switch UIDevice.current.userInterfaceIdiom {
          case .phone:
            name = "On My iPhone"
            image = "iphone"
          case .pad:
            name = "On My iPad"
            image = "ipad"
          default:
            name = "On My Device"
            image = "desktopcomputer"
        }
        self.userRootDirectories.append(NamedRef(name: name, image: image, url: url))
        _ = self.createExtensionDirectories(in: url, using: sysFileManager)
      }
    }
    self.usageRootDirectories.append(NamedRef(name: "Recent", image: "clock") { [weak self] in
      return self?.histManager?.recentlyEdited ?? []
    })
    self.usageRootDirectories.append(NamedRef(name: "Favorites", image: "star") { [weak self] in
      return self?.histManager?.favoriteFiles ?? []
    })
    if let appDir = FileManager.appSupportDirectory() {
      self.applicationSupportURL = appDir
      self.newEditorDocument(action: { success in })
    }
    self.baseURLs.append((URL(fileURLWithPath: Context.rootDirectory,
                              relativeTo: Context.bundle!.bundleURL.absoluteURL), 0))
    self.baseURLs.append((URL(fileURLWithPath: "Root",
                              relativeTo: Bundle.main.bundleURL.absoluteURL), 1))
    if let url = FileManager.documentsDirectory() {
      self.baseURLs.append((url, 2))
    }
    if let url = FileManager.icloudDirectory() {
      self.baseURLs.append((url, 3))
    }
    if let url = FileManager.appSupportDirectory() {
      self.baseURLs.append((url, 4))
    }
  }
  
  func isApplicationSupportURL(_ url: URL) -> Bool {
    if let appDirectory = self.applicationSupportURL {
      return url.isContained(in: appDirectory)
    }
    return false
  }
  
  func canonicalPath(for url: URL) -> String {
    var roots: [String] = []
    for namedRef in self.systemRootDirectories {
      if let url = namedRef.url {
        roots.append(url.absoluteURL.path)
      }
    }
    for namedRef in self.userRootDirectories {
      if let url = namedRef.url {
        roots.append(url.absoluteURL.path)
      }
    }
    let path = url.absoluteURL.path
    for root in roots {
      if path.hasPrefix(root) {
        return String(path[path.index(path.startIndex, offsetBy: root.count + 1)...])
      }
    }
    return path
  }
  
  func isWritable(_ url: URL) -> Bool {
    return self.sysFileManager.isWritableFile(atPath: url.absoluteURL.path)
  }
  
  /// Creates the following directories under the given `container` URL:
  ///   - `Libraries`
  ///   - `Assets`:
  ///       - `Images`
  ///       - `Audio`
  ///       - `Documents`
  ///       - `Datasets`
  ///       - `ColorLists`
  func createExtensionDirectories(in container: URL,
                                  using sysFileManager: Foundation.FileManager) -> Bool {
    let libDir = self.createExtensionDirectory(in: container,
                                               name: "Libraries",
                                               using: sysFileManager)
    if let assetDir = self.createExtensionDirectory(in: container,
                                                    name: "Assets",
                                                    using: sysFileManager) {
      _ = self.createExtensionDirectory(in: assetDir, name: "Images", using: sysFileManager)
      _ = self.createExtensionDirectory(in: assetDir, name: "Audio", using: sysFileManager)
      _ = self.createExtensionDirectory(in: assetDir, name: "Documents", using: sysFileManager)
      _ = self.createExtensionDirectory(in: assetDir, name: "Datasets", using: sysFileManager)
      _ = self.createExtensionDirectory(in: assetDir, name: "ColorLists", using: sysFileManager)
      return libDir != nil
    } else {
      return false
    }
  }
  
  /// Creates a new directory with the given name under the `container` URL.
  func createExtensionDirectory(in container: URL,
                                name: String,
                                using sysFileManager: Foundation.FileManager) -> URL? {
    let root = container.appendingPathComponent(name, isDirectory: true)
    var dir: ObjCBool = false
    guard sysFileManager.fileExists(atPath: container.absoluteURL.path, isDirectory: &dir),
          dir.boolValue,
          !sysFileManager.fileExists(atPath: root.absoluteURL.path) else {
      return nil
    }
    do {
      try sysFileManager.createDirectory(at: root, withIntermediateDirectories: false)
      return root
    } catch {
      return nil
    }
  }
  
  func item(at url: URL) -> FileType {
    var dir: ObjCBool = false
    if self.sysFileManager.fileExists(atPath: url.absoluteURL.path, isDirectory: &dir) {
      return dir.boolValue ? .directory : .file
    } else {
      return []
    }
  }
  
  func makeDirectory(at url: URL, name base: String = "New Folder") -> URL? {
    do {
      var folderUrl = url.appendingPathComponent(base)
      if self.sysFileManager.fileExists(atPath: folderUrl.absoluteURL.path) {
        var i = 0
        repeat {
          i += 1
          if i > 100 {
            return nil
          }
          folderUrl = url.appendingPathComponent(base + " \(i)")
        } while self.sysFileManager.fileExists(atPath: folderUrl.absoluteURL.path)
      }
      try self.sysFileManager.createDirectory(at: folderUrl,
                                              withIntermediateDirectories: false,
                                              attributes: nil)
      return folderUrl
    } catch {
      return nil
    }
  }
  
  func copy(_ url: URL, into dir: URL) -> Bool {
    do {
      let name = url.lastPathComponent
      let dest = dir.appendingPathComponent(name)
      try self.sysFileManager.copyItem(at: url, to: dest)
      return true
    } catch {
      return false
    }
  }
  
  func duplicate(_ url: URL) -> Bool {
    let name = url.deletingPathExtension().lastPathComponent
    let ext = url.pathExtension
    var target: URL? = nil
    if name.count >= 3 && name.last!.isNumber {
      let idx = name.index(name.endIndex, offsetBy: -2)
      if name[idx].isWhitespace, let n = Int(String(name.last!)) {
        target = url.deletingLastPathComponent()
                    .appendingPathComponent(String("\(name[name.startIndex..<idx]) \(n + 1)"))
                    .appendingPathExtension(ext)
      }
    }
    if target == nil {
      target = url.deletingLastPathComponent()
                  .appendingPathComponent(name + " 2")
                  .appendingPathExtension(ext)
    }
    if let target = target {
      do {
        try self.sysFileManager.copyItem(at: url, to: target)
        return true
      } catch {
        return false
      }
    }
    return false
  }
  
  func rename(_ url: URL, to name: String, complete: @escaping (URL?) -> Void) {
    let target = url.deletingLastPathComponent().appendingPathComponent(name)
    DispatchQueue.global(qos: .default).async {
      var coordinatorError: NSError?
      let fileCoordinator = NSFileCoordinator(filePresenter: nil)
      fileCoordinator.coordinate(writingItemAt: url,
                                 options: .forMoving,
                                 writingItemAt: target,
                                 options: .forReplacing,
                                 error: &coordinatorError) { newURL1, newURL2 in
        let fileManager = Foundation.FileManager()
        fileCoordinator.item(at: newURL1, willMoveTo: newURL2)
        do {
          try fileManager.moveItem(at: newURL1, to: newURL2)
          fileCoordinator.item(at: newURL1, didMoveTo: newURL2)
          DispatchQueue.main.async {
            complete(coordinatorError == nil ? newURL2 : nil)
          }
        } catch {
          DispatchQueue.main.async {
            complete(nil)
          }
        }
      }
    }
  }
  
  func delete(_ url: URL) -> Bool {
    do {
      try self.sysFileManager.removeItem(at: url)
      return true
    } catch {
      return false
    }
  }
  
  func newEditorDocument(action: @escaping (Bool) -> Void) {
    self.loadEditorDocument(action: action)
  }
  
  func completeURL(_ url: URL?) -> URL? {
    if url == nil, let appDir = self.applicationSupportURL {
      return appDir.appendingPathComponent("Untitled.scm")
    }
    return url
  }
  
  func loadEditorDocument(source: URL? = nil,
                          makeUntitled: Bool = true,
                          action: @escaping (Bool) -> Void) {
    let sourceUrl: URL
    if let url = self.completeURL(source) {
      sourceUrl = url
    } else {
      return
    }
    let targetUrl: URL
    if let url = self.completeURL(makeUntitled ? nil : source) {
      targetUrl = url
    } else {
      return
    }
    if sourceUrl != targetUrl {
      do {
        if sourceUrl.startAccessingSecurityScopedResource() {
          defer {
            sourceUrl.stopAccessingSecurityScopedResource()
          }
          try self.sysFileManager.removeItem(at: targetUrl)
          try self.sysFileManager.copyItem(at: sourceUrl, to: targetUrl)
        } else {
          try self.sysFileManager.removeItem(at: targetUrl)
          try self.sysFileManager.copyItem(at: sourceUrl, to: targetUrl)
        }
        self.histManager?.trackRecentFile(sourceUrl)
      } catch {
        return
      }
    }
    if let document = self.editorDocument, document.fileURL != targetUrl {
      if !document.new {
        self.histManager?.trackRecentFile(document.fileURL)
      }
      document.saveFile { success in
        document.close(completionHandler: { success in
          self.editorDocument = TextDocument(fileURL: targetUrl)
          self.editorDocument?.fileManager = self
          self.editorDocument?.new = makeUntitled
          self.editorDocument?.recomputeTitle(targetUrl)
          self.editorDocument?.loadFile(action: action)
        })
      }
    } else {
      self.editorDocument = TextDocument(fileURL: targetUrl)
      self.editorDocument?.fileManager = self
      self.editorDocument?.new = makeUntitled
      self.editorDocument?.recomputeTitle(targetUrl)
      self.editorDocument?.loadFile(action: action)
    }
  }
  
  /// Returns the "iCloud Drive" URL if available.
  static func icloudDirectory() -> URL? {
    return Foundation.FileManager.default.url(forUbiquityContainerIdentifier: nil)?
                                               .appendingPathComponent("Documents")
  }
  
  /// Returns the "On my iPhone" URL if available (creating it if it does not exist already).
  static func documentsDirectory() -> URL? {
    return try? Foundation.FileManager.default.url(for: .documentDirectory,
                                                   in: .userDomainMask,
                                                   appropriateFor: nil,
                                                   create: true)
  }

  /// Returns the internal application support URL if available (creating it if it does not
  /// exist already).
  static func appSupportDirectory() -> URL? {
    return try? Foundation.FileManager.default.url(for: .applicationSupportDirectory,
                                                   in: .userDomainMask,
                                                   appropriateFor: nil,
                                                   create: true)
  }
  
  /// Returns a cache URL if available.
  static func cacheDirectory() -> URL? {
    return Foundation.FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
  }
  
  /*
  Swift.print("documents = \(self.documentsDirectory()!)")
  Swift.print("appSupport = \(self.appSupportDirectory()!)")
  Swift.print("cacheSupport = \(self.cacheDirectory()!)")
  Swift.print("icloud = \(self.icloudDirectory())")
  let str = "This is a short\ntext message"
  let url = self.icloudDirectory()!.appendingPathComponent("message.txt")
  do {
    try str.write(to: url, atomically: true, encoding: .utf8)
    let input = try String(contentsOf: url)
    Swift.print("content = \(input)")
  } catch let error {
    print(error.localizedDescription)
  }
 */
}

struct FileType: OptionSet {
  let rawValue: Int
  static let file = FileType(rawValue: 1 << 0)
  static let directory = FileType(rawValue: 1 << 1)
  static let collection = FileType(rawValue: 1 << 2)
  static let all: FileType = [.file, .directory, .collection]
}
