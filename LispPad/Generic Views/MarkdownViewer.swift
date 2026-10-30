//
//  MarkdownViewer.swift
//  LispPad
//
//  Created by Matthias Zenger on 11/05/2021.
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
import SwiftUI
import LispKit
import MarkdownKit

struct MarkdownViewer: View {
  let markdown: Block

  /// Where the reader is in `markdown`. The sheet is created again when the geometry changes, e.g.
  /// when the device is rotated. This is what brings the reader back to where they were.
  var position: MarkdownReadingPosition? = nil

  var body: some View {
    ScrollSheet {
      MarkdownText(self.markdown, position: self.position)
    }
    .modifier(ToolbarVerticalBehaviorModifier(disallow: MainView.disableVerticalToolbar))
  }
}
