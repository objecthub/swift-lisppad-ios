//
//  SearchMatchCountOverlay.swift
//  LispPad
//
//  Created by Matthias Zenger on 22/09/2026.
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

import SwiftUI

/// A small, semi-transparent badge showing how many segments of the document match the
/// active search term. Intended to be pinned to the top-trailing corner of the editor's
/// text view via `.overlay`, mirroring `CursorLocationOverlay` at the bottom-trailing
/// corner.
///
/// The embedding view is expected to only include this overlay while there's at least
/// one match (see `CodeEditorView`) -- an empty search, or a term with zero matches,
/// means there are no search highlights in the text either, so a "0 matches" badge
/// would just be redundant with what's already visible.
struct SearchMatchCountOverlay: View {
  @Environment(\.colorScheme) private var colorScheme

  let matchCount: Int

  var body: some View {
    Group {
      if #available(iOS 26.0, *) {
        self.label.glassEffect(.regular, in: Capsule())
      } else {
        self.label.background(.ultraThinMaterial, in: Capsule())
      }
    }
    // Force the opposite color scheme so the badge's material/text stay legible
    // regardless of the surrounding editor content or the app's own appearance.
    .colorScheme(self.colorScheme == .dark ? .light : .dark)
    .allowsHitTesting(false)
  }

  private var label: some View {
    Text(self.matchCount == 1 ? "1 match" : "\(self.matchCount) matches")
      .font(.caption.monospacedDigit())
      .bold()
      .foregroundColor(.primary)
      .padding(.horizontal, 10)
      .padding(.vertical, 5)
  }
}
