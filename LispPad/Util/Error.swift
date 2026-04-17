//
//  Error.swift
//  LispPad
//
//  Created by Matthias Zenger on 17/04/2026.
//  Copyright © 2026 ObjectHub. All rights reserved.
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

extension Error {
  public func richDescription(inclReason: Bool = true, inclRecovery: Bool = true) -> String {
    // Prefer LocalizedError's errorDescription if available
    if let localizedError = self as? LocalizedError,
       let description = localizedError.errorDescription {
      return description
    }
    // Fall back to NSError for domain/code/userInfo details
    let nsError = self as NSError
    let domainAndCode = "[\(nsError.domain) \(nsError.code)]"
    var description = nsError.localizedDescription.isEmpty
                    ? domainAndCode
                    : "\(nsError.localizedDescription) \(domainAndCode)."
    // Include failure reason if present and different from localizedDescription
    if inclReason,
       let reason = nsError.localizedFailureReason,
       reason != nsError.localizedDescription {
      description += " \(reason)."
    }
    // Include recovery suggestion if present
    if inclRecovery,
       let recovery = nsError.localizedRecoverySuggestion {
      description += " \(recovery)."
    }
    return description
  }
}
