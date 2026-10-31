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
import CryptoKit

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
  var info = Info(title: "Untitled", new: true, editorType: .scheme) {
    didSet {
      self.fileManager?.editorDocumentInfo = self.info
    }
  }

  /// Textual content
  var text = ""

  /// Identifies a text by its content without keeping the text.
  typealias Fingerprint = SHA256Digest

  static func fingerprint(of text: String) -> Fingerprint {
    var text = text
    return text.withUTF8 { SHA256.hash(data: UnsafeRawBufferPointer($0)) }
  }

  /// The fingerprint of the text as it was last read from or written to the file. It differs
  /// from the fingerprint of `text` as long as there are edits which are not saved yet. The
  /// document is never marked as changed, so `UIDocument` cannot tell on its own whether
  /// reloading the file would lose edits. A fingerprint takes 32 bytes, whereas a copy of the
  /// text would double the memory for it as soon as the user types.
  private(set) var savedFingerprint = TextDocument.fingerprint(of: "")

  /// Becomes true once the document has content from its file. From then on, `load` is a
  /// reload of a file that was changed by somebody else.
  private var hasLoaded = false

  /// The fingerprint of the text handed over by the latest save; it becomes
  /// `savedFingerprint` if the save succeeds.
  private var writtenFingerprint: Fingerprint? = nil

  /// The fingerprint of the content of the file if it changed on disk while there were unsaved
  /// edits. The document stays in conflict until the user chooses a version.
  private(set) var conflictFingerprint: Fingerprint? = nil

  var hasConflict: Bool {
    return self.conflictFingerprint != nil
  }

  /// Reads the file for reloads, one at a time and in order.
  private let reloadQueue = DispatchQueue(label: "net.objecthub.LispPad.document-reload",
                                          qos: .userInitiated)

  /// What to do with the document if its file changed on disk.
  enum ExternalChange {
    /// The document stays as it is.
    case ignore
    /// There are no edits to lose: the document takes over the content of the file.
    case adopt
    /// Both the document and the file changed: the user has to decide.
    case conflict
  }

  static func resolve(local: Fingerprint, saved: Fingerprint, disk: Fingerprint) -> ExternalChange {
    if disk == saved {
      return .ignore
    } else if local == saved || local == disk {
      return .adopt
    } else {
      return .conflict
    }
  }

  /// The content of the file, decoded.
  private struct DiskContent {
    let text: String
    let fingerprint: Fingerprint
  }

  /// Returns nil if `data` is not UTF-8.
  private static func decode(_ data: Data) -> DiskContent? {
    guard let text = String(data: data, encoding: .utf8) else {
      return nil
    }
    return DiskContent(text: text, fingerprint: Self.fingerprint(of: text))
  }

  /// Currently selected range
  var selectedRange = NSRange(location: 0, length: 0)

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
  
  var size: Int? {
    if let size = try? self.fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
      return size
    } else {
      return nil
    }
  }
  
  var pathString: String {
    let res = (PortableURL(self.fileURL)?.relativePath as NSString?)?.deletingLastPathComponent ?? "/"
    if res.isEmpty {
      return "/"
    } else {
      return res
    }
  }
  
  var sizeString: String {
    // let size = try? self.fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize
    // let size = self.text.count
    let size = self.text.utf8.count
    if size < 10000 {
      return "\(size) B"
    } else {
      return "\(String(format: "%.2f", Double(size) / 1024.0)) KB"
    }
  }
  
  /// An open document is a file presenter. Before another process can read or write the file,
  /// e.g. for the Quick Look preview in the Files app, it has to wait until the document has
  /// handed the file over. The document does not respond while the app is in the background,
  /// which leaves the other process waiting until the user returns to the app. Hence, the
  /// document steps aside while the app is in the background.
  private var filePresenterSuspended = false
  private var filePresenterSuspensionPending = false

  /// Saves the document and then steps aside as file presenter. The document is the presenter
  /// of its own save; if it stepped aside while the save is still running, the save's claim
  /// on the file would stay open and block other processes from writing the file for as long
  /// as the app is suspended. Hence, this waits for the save to complete. If the app returns
  /// to the foreground in the meantime, the document remains a presenter.
  func saveAndSuspendFilePresenter(completion: @escaping () -> Void = {}) {
    self.filePresenterSuspensionPending = true
    guard !self.hasConflict else {
      // The user has not decided yet which version to keep; saving would overwrite the
      // one they have not seen. Nothing is in flight, so stepping aside right away is safe.
      self.suspendFilePresenter()
      completion()
      return
    }
    self.saveFile { _ in
      if self.filePresenterSuspensionPending {
        self.suspendFilePresenter()
      }
      completion()
    }
  }

  func suspendFilePresenter() {
    guard !self.filePresenterSuspended, !self.documentState.contains(.closed) else {
      return
    }
    self.filePresenterSuspended = true
    NSFileCoordinator.removeFilePresenter(self)
  }

  func resumeFilePresenter() {
    self.filePresenterSuspensionPending = false
    guard self.filePresenterSuspended else {
      return
    }
    self.filePresenterSuspended = false
    if !self.documentState.contains(.closed) {
      NSFileCoordinator.addFilePresenter(self)
      // Presenters are not told about changes made while they were not registered.
      self.reloadIfChangedOnDisk()
    }
  }

  /// Reads the file again; `reconcile` decides what happens if its content is not what the
  /// document last saw. This does not use `UIDocument.revert(toContentsOf:)`, which fails if
  /// `UIDocument` itself is reverting at the same time.
  func reloadIfChangedOnDisk(completion: @escaping () -> Void = {}) {
    guard self.hasLoaded, !self.documentState.contains(.closed) else {
      completion()
      return
    }
    let url = self.fileURL
    self.reloadQueue.async {
      var content: DiskContent? = nil
      var coordinatorError: NSError?
      NSFileCoordinator(filePresenter: self).coordinate(readingItemAt: url,
                                                        options: [],
                                                        error: &coordinatorError) { readURL in
        if let data = try? Data(contentsOf: readURL) {
          content = Self.decode(data)
        }
      }
      DispatchQueue.main.async {
        self.reconcile(with: content)
        completion()
      }
    }
  }

  /// Changes that were not made with file coordination (e.g. by git clients) are not
  /// reloaded by `UIDocument`, so look at the file whenever the presenter is told about one.
  override func presentedItemDidChange() {
    super.presentedItemDidChange()
    DispatchQueue.main.async {
      self.reloadIfChangedOnDisk()
    }
  }

  /// Settles a conflict between unsaved edits and a changed file. If the user keeps their
  /// version, the file counts as seen, so the next save overwrites it. Otherwise the file is
  /// read again, which also catches a newer change, after the edits are declared saved so
  /// that the reload takes the file over. Until then, the conflict keeps automatic saves from
  /// overwriting the file.
  func resolveConflict(keepLocal: Bool, completion: @escaping () -> Void = {}) {
    guard let disk = self.conflictFingerprint else {
      completion()
      return
    }
    if keepLocal {
      self.savedFingerprint = disk
      self.endConflict()
      completion()
    } else {
      self.savedFingerprint = Self.fingerprint(of: self.text)
      self.reloadIfChangedOnDisk {
        self.endConflict()
        completion()
      }
    }
  }

  private func endConflict() {
    self.conflictFingerprint = nil
    self.fileManager?.editorDocumentConflict = false
  }

  private func adopt(_ disk: DiskContent, notify: Bool) {
    let changed = self.text != disk.text
    self.text = disk.text
    self.savedFingerprint = disk.fingerprint
    let length = (disk.text as NSString).length
    let location = min(self.selectedRange.location, length)
    self.selectedRange = NSRange(location: location,
                                 length: min(self.selectedRange.length, length - location))
    if notify && changed {
      self.fileManager?.editorDocumentReloaded()
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
  
  /// Called when the document is opened, and again when `UIDocument` reads the file anew
  /// because somebody else changed it.
  override func load(fromContents contents: Any, ofType typeName: String?) throws {
    if let data = contents as? Data {
      self.reconcile(with: Self.decode(data))
    }
  }

  /// Brings the document in line with the content of its file, unless that would lose edits
  /// which are not saved yet. `disk` is nil if the file is not UTF-8 or could not be read.
  private func reconcile(with disk: DiskContent?) {
    let reload = self.hasLoaded
    self.hasLoaded = true
    guard let disk else {
      // A file which is not UTF-8 opens as an empty text. Do not replace a text by that
      // if another app saved the file with another encoding in the meantime.
      if !reload {
        self.adopt(DiskContent(text: "", fingerprint: Self.fingerprint(of: "")), notify: false)
      }
      return
    }
    guard disk.fingerprint != self.savedFingerprint else {
      return
    }
    switch Self.resolve(local: Self.fingerprint(of: self.text),
                        saved: self.savedFingerprint,
                        disk: disk.fingerprint) {
      case .ignore:
        break
      case .adopt:
        self.adopt(disk, notify: reload)
      case .conflict:
        self.conflictFingerprint = disk.fingerprint
        self.fileManager?.editorDocumentConflict = true
    }
  }

  override func contents(forType typeName: String) throws -> Any {
    let data = self.text.data(using: .utf8) ?? Data()
    self.writtenFingerprint = SHA256.hash(data: data)
    return data
  }

  override func save(to url: URL,
                     for saveOperation: UIDocument.SaveOperation,
                     completionHandler: ((Bool) -> Void)? = nil) {
    super.save(to: url, for: saveOperation) { success in
      if success, let fingerprint = self.writtenFingerprint {
        self.savedFingerprint = fingerprint
        self.hasLoaded = true
      }
      completionHandler?(success)
    }
  }
}
