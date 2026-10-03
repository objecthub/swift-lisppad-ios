//
//  InterpreterState.swift
//  LispPad
//
//  Created by Matthias Zenger on 02/11/2023.
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
import MarkdownKit

class InterpreterState: ObservableObject {
  @Published var consoleInput = ""
  @Published var consoleInputRange = NSRange(location: 0, length: 0)
  @Published var focused: Bool = false
  @Published var shouldFocus: Bool = false
  @Published var consoleTab: Int = 1
  @Published var selectedPreferencesTab = 0
  @Published var showProgressView: String? = nil

  // Scroll positions of the console output and the log. These are deliberately not
  // published: they change continuously while scrolling, and they only need to survive
  // the destruction of the views when the interpreter pane is hidden.
  var consoleScrollY: CGFloat? = nil
  var consoleAtBottom: Bool = true
  var logScrollY: CGFloat? = nil
  var logAtBottom: Bool = true
  // Whether new console output scrolls the console to its end. Set when the end of the
  // output becomes visible, and cleared when the user scrolls it out of view.
  var consoleFollowsOutput: Bool = true
  var consoleUserScrolling: Bool = false
  var logFollowsOutput: Bool = true
  var logUserScrolling: Bool = false
}

/// Remembers the scroll position of a `ScrollView` in an object that outlives the view, and
/// restores it when the view is recreated (e.g. when the interpreter pane gets hidden and
/// shown again). If the view was scrolled to the end, it sticks to the end.
struct RememberScrollPosition: ViewModifier {
  private struct Info: Equatable {
    let y: CGFloat
    let atBottom: Bool
  }

  let state: InterpreterState
  let y: ReferenceWritableKeyPath<InterpreterState, CGFloat?>
  let atBottom: ReferenceWritableKeyPath<InterpreterState, Bool>
  @State private var position = ScrollPosition()
  @State private var restored = false

  func body(content: Content) -> some View {
    content
      .scrollPosition(self.$position)
      .onScrollGeometryChange(for: Info.self) { geo in
        let maxY = geo.contentSize.height + geo.contentInsets.bottom - geo.containerSize.height
        return Info(y: geo.contentOffset.y, atBottom: geo.contentOffset.y >= maxY - 2)
      } action: { old, info in
        // Ignore the initial geometry (offset 0) until the saved position was restored.
        guard self.restored else {
          return
        }
        self.state[keyPath: self.y] = info.y
        // If the offset did not change but we are no longer at the bottom, the content
        // has grown. Keep the flag so that auto-scrolling to new output still happens.
        if info.y != old.y || info.atBottom {
          self.state[keyPath: self.atBottom] = info.atBottom
        }
      }
      .task {
        guard !self.restored else {
          return
        }
        // Let the lazy content lay out first
        await Task.yield()
        if self.state[keyPath: self.atBottom] {
          self.position.scrollTo(edge: .bottom)
        } else if let y = self.state[keyPath: self.y] {
          self.position.scrollTo(y: y)
        }
        await Task.yield()
        self.restored = true
      }
  }
}

extension View {
  func rememberScrollPosition(
    in state: InterpreterState,
    y: ReferenceWritableKeyPath<InterpreterState, CGFloat?>,
    atBottom: ReferenceWritableKeyPath<InterpreterState, Bool>) -> some View {
    return self.modifier(RememberScrollPosition(state: state, y: y, atBottom: atBottom))
  }
}
