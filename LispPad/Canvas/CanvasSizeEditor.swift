//
//  CanvasSizeEditor.swift
//  LispPad
//
//  Created by Matthias Zenger on 15/11/2023.
//  Copyright © 2023 Matthias Zenger. All rights reserved.
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

struct CanvasSizeEditor: View {
  @Environment(\.dismiss) var dismiss
  @State var cancelled: Bool = false
  @State var name: String
  @State var width: CGFloat
  @State var height: CGFloat
  @State var scale: CGFloat
  let update: (String, CGSize, CGFloat) -> Void
  let initialName: String
  let initialWidth: CGFloat
  let initialHeight: CGFloat
  let initialScale: CGFloat
  
  init(name: String,
       width: CGFloat,
       height: CGFloat,
       scale: CGFloat,
       update: @escaping (String, CGSize, CGFloat) -> Void) {
    self.initialName = name
    self.initialWidth = width
    self.initialHeight = height
    self.initialScale = scale
    self._name = State(initialValue: name)
    self._width = State(initialValue: width)
    self._height = State(initialValue: height)
    self._scale = State(initialValue: scale)
    self.update = update
  }
  
  let formatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.locale = Locale.current
    return formatter
  }()

  private var rowSeparator: some View {
    Rectangle()
      .fill(Color(UIColor.separator))
      .frame(height: 1 / UIScreen.main.scale)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack(alignment: .center, spacing: 0) {
        Button(role: .destructive) {
          self.name = self.initialName
          self.width = self.initialWidth
          self.height = self.initialHeight
          self.scale = self.initialScale
        } label: {
          ResetButton(size: 26, legacySize: 20)
        }
        Spacer()
        Button(role: .destructive) {
          self.cancelled = true
          self.dismiss()
        } label: {
          ExitButton(size: 26, legacySize: 20)
        }
      }
      .padding(.init(top: 10, leading: 14, bottom: 8, trailing: 14))
      self.rowSeparator
      TextField("Canvas Name", text: self.$name, prompt: Text("Canvas Name"))
        .autocapitalization(.none)
        .disableAutocorrection(true)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
      self.rowSeparator.padding(.leading, 8)
      HStack(alignment: .center, spacing: 8) {
        Text("Size:")
        Spacer()
        TextField("Width", value: self.$width, formatter: formatter)
          .multilineTextAlignment(.trailing)
          .frame(idealWidth: 30, maxWidth: 50)
          .keyboardType(.decimalPad)
        Text("⨉")
        TextField("Height", value: self.$height, formatter: formatter)
          .multilineTextAlignment(.trailing)
          .frame(idealWidth: 30, maxWidth: 50)
          .keyboardType(.decimalPad)
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 8)
      self.rowSeparator.padding(.leading, 8)
      HStack(alignment: .center, spacing: 8) {
        Text("Scale:")
        Spacer()
        TextField("Factor", value: self.$scale, formatter: formatter)
          .multilineTextAlignment(.trailing)
          .keyboardType(.decimalPad)
      }
      .padding(.init(top: 8, leading: 16, bottom: 18, trailing: 16))
    }
    .font(.body)
    .fixedSize(horizontal: false, vertical: true)
    .onAppear {
      self.cancelled = false
    }
    .onDisappear {
      if self.width < 10 {
        self.width = 10
      }
      if self.width > 50000 {
        self.width = 50000
      }
      if self.height < 10 {
        self.height = 10
      }
      if self.height > 50000 {
        self.height = 50000
      }
      if self.scale <= 0.0 {
        self.scale = 1.0
      }
      if self.scale > 1000.0 {
        self.scale = 1000.0
      }
      if self.name.isEmpty {
        if self.initialName.isEmpty {
          self.name = "Unnamed"
        } else {
          self.name = self.initialName
        }
      }
      if self.name.count > 100 {
        self.name = String(self.name.prefix(100))
      }
      if !self.cancelled {
        self.update(self.name, CGSize(width: self.width, height: self.height), self.scale)
      }
    }
  }
}
