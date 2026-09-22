//
//  CursorLocationOverlay.swift
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

/// A small, semi-transparent badge showing the cursor's current line and column. Intended
/// to be pinned to the bottom-trailing corner of the editor's text view via `.overlay`.
///
/// Line/column is only ever computed while this view is actually part of the hierarchy
/// (i.e. while the "Show cursor location" setting is on): the embedding view re-renders
/// with a fresh `selectedRange` on every selection change regardless, but that's just an
/// `NSRange` -- the O(document length) line/column scan happens here, in response, so it
/// never runs for editors that don't display this overlay.
struct CursorLocationOverlay: View {
  @Environment(\.colorScheme) private var colorScheme
  
  let text: String
  let selectedRange: NSRange
  
  @State private var line: Int = 1
  @State private var column: Int = 1
  
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
    .onChange(of: self.selectedRange, initial: true) { _, range in
      (self.line, self.column) = CursorLocationOverlay.lineAndColumn(self.text as NSString,
                                                                     at: range.location)
    }
  }
  
  private var label: some View {
    Text("L:\(self.line)  C:\(self.column)")
      .font(.caption.monospacedDigit())
      .bold()
      .foregroundColor(.primary)
      .padding(.horizontal, 10)
      .padding(.vertical, 5)
  }
  
  /// Returns the 1-based line and column corresponding to `location` in `str`. `location`
  /// is clamped into `str`'s range so this remains well-defined for a stale/out-of-range
  /// cursor position (e.g. while the text is being replaced).
  private static func lineAndColumn(_ str: NSString, at location: Int) -> (line: Int, column: Int) {
    let loc = min(max(location, 0), str.length)
    var line = 1
    var lineStart = 0
    var i = 0
    while i < loc {
      if str.character(at: i) == NEWLINE {
        line += 1
        lineStart = i + 1
      }
      i += 1
    }
    return (line, loc - lineStart + 1)
  }
}
