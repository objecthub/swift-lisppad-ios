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

///
/// This class implements the LispPad-specific library `(lisppad system)`.
///
public final class SystemLibrary: NativeLibrary {
  
  /// Name of the library.
  public override class var name: [String] {
    return ["lisppad", "system"]
  }
  
  /// Initialization
  public required init(in context: Context) throws {
    try super.init(in: context)
  }
    
  /// Declarations of the library.
  public override func declarations() {
    self.define(Procedure("open-in-files-app", self.openInFilesApp))
    self.define(Procedure("save-bitmap-in-library", self.saveBitmapInLibrary))
    self.define(Procedure("project-directory", self.projectDirectory))
    self.define(Procedure("icloud-directory", self.icloudDirectory))
    self.define(Procedure("screen-size", self.screenSize))
    self.define(Procedure("dark-mode?", self.isDarkMode))
    self.define(Procedure("sleep", self.sleep))
    self.define(Procedure("icloud-list", self.iCloudList))
    self.define(Procedure("session-log", self.sessionLog))
  }
  
  private func openInFilesApp(expr: Expr) throws -> Expr {
    let path = self.context.fileHandler.path(try expr.asPath(),
                                             relativeTo: self.context.machine.currentDirectoryPath)
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
  
  private func sleep(_ expr: Expr) throws -> Expr {
    var remaining = try expr.asDouble(coerce: true)
    let endTime = Timer.currentTimeInSec + remaining
    while remaining > 0.0 && !self.context.machine.isAbortionRequested() {
      Thread.sleep(forTimeInterval: min(remaining, 0.5))
      remaining = endTime - Timer.currentTimeInSec
    }
    return .void
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
