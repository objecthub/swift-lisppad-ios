//
//  OptionalScrollView.swift
//  LispPad
//
//  Created by Matthias Zenger on 01/10/2021.
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

struct OptionalScrollView<Content: View>: View {
  @State private var noscroll = false
  @State private var height: CGFloat? = nil
  let maxHeight: CGFloat
  let content: Content
  
  init(maxHeight: CGFloat = 500, @ViewBuilder content: () -> Content) {
    self.maxHeight = maxHeight
    self.content = content()
  }

  var body: some View {
    GeometryReader { gp in
      ScrollView {
        content
        .background(GeometryReader { inner in
          Color.clear
            .preference(key: ViewHeightKey.self, value: inner.frame(in: .local).size.height)
        })
      }
      .preference(key: NoScrollKey.self, value: self.height == nil
                                                  ? false : self.height! < gp.size.height + 1.0)
      .onPreferenceChange(ViewHeightKey.self) { height in
        self.height = height
      }
      .onPreferenceChange(NoScrollKey.self) { noscroll in
        self.noscroll = noscroll
      }
      .disabled(self.noscroll)
    }
    .frame(maxHeight: self.height == nil ? nil : min(self.height!, self.maxHeight))
  }
}

struct ViewHeightKey: PreferenceKey {
  static var defaultValue: CGFloat = .zero
  static func reduce(value: inout Value, nextValue: () -> Value) {
    value = value + nextValue()
  }
}

struct NoScrollKey: PreferenceKey {
  static var defaultValue: Bool = false
  static func reduce(value: inout Value, nextValue: () -> Value) {
    value = value || nextValue()
  }
}
