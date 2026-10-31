//
//  PreviewConstants.swift
//  LispPad
//
//  Shared between the LispPad app and the "LispPad QuickLook" extension.
//
//  Copyright © 2026 Matthias Zenger. All rights reserved.
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

/// Identifiers shared by the app and its Quick Look extension.
enum SchemePreview {

  /// The app group through which the app hands editor settings to the Quick Look extension.
  /// This is deliberately a group of its own; `group.net.objecthub.LispPad` is not used.
  static let appGroup = "group.net.objecthub.LispPad.preview"

  /// The file in the app group's container that lists the identifiers for which the app has
  /// documentation, one per line.
  static var documentedSymbolsURL: URL? {
    // The app has a `FileManager` of its own, which is why Foundation's has to be qualified.
    return Foundation.FileManager.default
      .containerURL(forSecurityApplicationGroupIdentifier: SchemePreview.appGroup)?
      .appendingPathComponent("documented-symbols.txt")
  }
}
