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

  /// Dependencies of the library.
  public override func dependencies() {
  }
  
  /// Declarations of the library.
  public override func declarations() {
    self.define(Procedure("save-bitmap-in-library", self.saveBitmapInLibrary))
    self.define(Procedure("project-directory", self.projectDirectory))
    self.define(Procedure("screen-size", self.screenSize))
    self.define(Procedure("dark-mode?", self.isDarkMode))
    self.define(Procedure("sleep", self.sleep))
  }
  
  public override func initializations() {
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
}
