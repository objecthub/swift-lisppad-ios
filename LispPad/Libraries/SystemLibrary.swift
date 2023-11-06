//
//  SystemLibrary.swift
//  LispPad
//
//  Created by Matthias Zenger on 22/03/2021.
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
import PhotosUI

///
/// This class implements the LispPad-specific library `(lisppad system)`.
///
public final class SystemLibrary: NativeLibrary {
  internal weak var interpreter: Interpreter? = nil
  
  private let bursts: Symbol            // Assets with multiple high-speed photos
  private let cinematicVideos: Symbol   // Videos with a shallow depth of field and focus transitions
  private let depthEffectPhotos: Symbol // Photos with depth information
  private let images: Symbol            // Images including Live Photos
  private let livePhotos: Symbol        // Live Photos
  private let panoramas: Symbol         // Panorama photos
  private let screenRecordings: Symbol  // Screen recordings
  private let screenshots: Symbol       // Screenshots
  private let slomoVideos: Symbol       // Slow-motion videos
  private let timelapseVideos: Symbol   // Time-lapse videos
  private let videos: Symbol            // Videos
  private let or: Symbol                // Or operator
  private let and: Symbol               // And operator
  private let not: Symbol               // Not operator
  
  /// Name of the library.
  public override class var name: [String] {
    return ["lisppad", "system"]
  }
  
  /// Initialization
  public required init(in context: Context) throws {
    self.bursts = context.symbols.intern("bursts")
    self.cinematicVideos = context.symbols.intern("cinematic-videos")
    self.depthEffectPhotos = context.symbols.intern("depth-effect-photos")
    self.images = context.symbols.intern("images")
    self.livePhotos = context.symbols.intern("live-photos")
    self.panoramas = context.symbols.intern("panoramas")
    self.screenRecordings = context.symbols.intern("screen-recordings")
    self.screenshots = context.symbols.intern("screenshots")
    self.slomoVideos = context.symbols.intern("slomo-videos")
    self.timelapseVideos = context.symbols.intern("timelapse-videos")
    self.videos = context.symbols.intern("videos")
    self.and = context.symbols.intern("and")
    self.or = context.symbols.intern("or")
    self.not = context.symbols.intern("not")
    try super.init(in: context)
  }
  
  /// Declarations of the library.
  public override func declarations() {
    self.define(Procedure("open-in-files-app", self.openInFilesApp))
    self.define(Procedure("save-bitmap-in-library", self.saveBitmapInLibrary))
    self.define(Procedure("load-bitmap-from-library", self.loadBitmapFromLibrary))
    self.define(Procedure("project-directory", self.projectDirectory))
    self.define(Procedure("icloud-directory", self.icloudDirectory))
    self.define(Procedure("screen-size", self.screenSize))
    self.define(Procedure("dark-mode?", self.isDarkMode))
    self.define(Procedure("icloud-list", self.iCloudList))
    self.define(Procedure("session-log", self.sessionLog))
  }
  
  private func openInFilesApp(expr: Expr) throws -> Expr {
    let path = self.context.fileHandler.path(
                 try expr.asPath(),
                 relativeTo: self.context.evaluator.currentDirectoryPath)
    if let url = URL(string: "shareddocuments://\(path)") {
      DispatchQueue.main.async {
        UIApplication.shared.open(url)
      }
    }
    return .void
  }
  
  private func saveBitmapInLibrary(expr: Expr) throws -> Expr {
    guard case .object(let obj) = expr,
          let imageBox = obj as? NativeImage else {
      throw RuntimeError.type(expr, expected: [NativeImage.type])
    }
    let imageManager = ImageManager()
    try imageManager.writeImageToLibrary(imageBox.value)
    return .true
  }
  
  private func photoFilter(_ expr: Expr) throws -> PHPickerFilter {
    switch expr {
      case .symbol(let sym):
        switch sym {
          case self.bursts:
            return .bursts
          case self.cinematicVideos:
            return .cinematicVideos
          case self.depthEffectPhotos:
            return .depthEffectPhotos
          case self.images:
            return .images
          case self.livePhotos:
            return .livePhotos
          case self.panoramas:
            return .panoramas
          case self.screenRecordings:
            return .screenRecordings
          case self.screenshots:
            return .screenshots
          case self.slomoVideos:
            return .slomoVideos
          case self.timelapseVideos:
            return .timelapseVideos
          case self.videos:
            return .videos
          default:
            throw RuntimeError.custom("error", "not a valid photos filter", [expr])
        }
      case .pair(.symbol(self.not), .pair(let operand, .null)):
        return PHPickerFilter.not(try self.photoFilter(operand))
      case .pair(.symbol(self.and), var list):
        var filters: [PHPickerFilter] = []
        while case .pair(let head, let tail) = list {
          filters.append(try self.photoFilter(head))
          list = tail
        }
        guard case .null = list else {
          throw RuntimeError.custom("error", "not a valid 'and' photos filter", [expr])
        }
        return PHPickerFilter.all(of: filters)
      case .pair(.symbol(self.or), var list):
        var filters: [PHPickerFilter] = []
        while case .pair(let head, let tail) = list {
          filters.append(try self.photoFilter(head))
          list = tail
        }
        guard case .null = list else {
          throw RuntimeError.custom("error", "not a valid 'or' photos filter", [expr])
        }
        return PHPickerFilter.any(of: filters)
      default:
        throw RuntimeError.custom("error", "not a valid photos filter expression", [expr])
    }
  }
  
  private func loadBitmapFromLibrary(_ maxImages: Expr?, _ filter: Expr?) throws -> Expr {
    let n: Int = try maxImages?.asInt(above: 1, below: 1000) ?? 1
    let f: PHPickerFilter = filter == nil ? .images : try self.photoFilter(filter!)
    let imageManager = ImageManager()
    DispatchQueue.main.sync {
      self.interpreter?.showPhotosPicker = Interpreter.PhotosPickerConfig(
        maxSelectionCount: n,
        matching: f,
        imageManager: imageManager)
    }
    let images = try imageManager.loadImagesFromLibrary()
    var res: [Expr] = []
    for image in images {
      if let image {
        res.append(.object(NativeImage(image)))
      } else {
        res.append(.false)
      }
    }
    return .makeList(Arguments(res))
  }
  
  private func projectDirectory() -> Expr {
    if let path = PortableURL.Base.documents.url?.absoluteURL.path {
      return .makeString(path)
    } else {
      return .false
    }
  }
  
  private func icloudDirectory() -> Expr {
    if let path = PortableURL.Base.icloud.url?.absoluteURL.path {
      return .makeString(path)
    } else {
      return .false
    }
  }
  
  private func screenSize(docid: Expr?) throws -> Expr {
    let screen = UIScreen.main.bounds
    return .pair(.flonum(Double(screen.width)), .flonum(Double(screen.height)))
  }
  
  private func isDarkMode() -> Expr {
    return .makeBoolean(UITraitCollection.current.userInterfaceStyle == .dark)
  }
  
  private func iCloudList(_ expr: Expr?) throws -> Expr {
    if let urls = FileObserver.default?.observedFiles(expr?.isTrue) {
      var res = Expr.null
      for url in urls {
        if let portableUrl = PortableURL(url) {
          res = .pair(.makeString(portableUrl.relativePath), res)
        }
      }
      return res
    } else {
      return .false
    }
  }
  
  private func sessionLog(tme: Expr, sev: Expr, message: Expr, tag: Expr?) throws -> Expr {
    let time: Double? = tme.isFalse ? nil : try tme.asDouble()
    let sym = try sev.asSymbol()
    let severity: Severity
    switch sym.identifier {
      case "debug":
        severity = .debug
      case "info":
        severity = .info
      case "warn":
        severity = .warning
      case "error":
        severity = .error
      case "fatal":
        severity = .fatal
      default:
        throw RuntimeError.custom("error", "invalid severity", [sev])
    }
    SessionLog.standard.addLogEntry(time: time,
                                    severity: severity,
                                    tag: try tag?.asString() ?? "",
                                    message: try message.asString())
    return .void
  }
}
