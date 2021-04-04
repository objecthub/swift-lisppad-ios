//
//  ConsoleScrollView.swift
//  LispPad
// 
//  Created by Matthias Zenger on 05/03/2021.
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

import SwiftUI

struct ConsoleScrollView<Content: View>: View {
  let axes: Axis.Set
  let showsIndicators: Bool
  let offsetChanged: (CGFloat) -> Void
  let content: Content
  
  init(_ axes: Axis.Set = .vertical,
       showsIndicators: Bool = true,
       offsetChanged: @escaping (CGFloat) -> Void = { _ in },
       @ViewBuilder content: () -> Content) {
    self.axes = axes
    self.showsIndicators = showsIndicators
    self.offsetChanged = offsetChanged
    self.content = content()
  }
  
  var body: some View {
    ScrollView(axes, showsIndicators: showsIndicators) {
      GeometryReader { geometry in
        Color.clear.preference(key: ScrollOffsetPreferenceKey.self,
                               value: geometry.frame(in: .named("consoleScrollView")).minY)
      }.frame(width: 0, height: 0)
      content
    }
    .coordinateSpace(name: "consoleScrollView")
    .onPreferenceChange(ScrollOffsetPreferenceKey.self, perform: offsetChanged)
    .resignKeyboardOnDragGesture()
  }
}

private struct ScrollOffsetPreferenceKey: PreferenceKey {
  static var defaultValue: CGFloat = .zero
  static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
    value += nextValue()
  }
}
