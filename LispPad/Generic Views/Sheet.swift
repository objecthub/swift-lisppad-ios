//
//  Sheet.swift
//  LispPad
//
//  Created by Matthias Zenger on 24/07/2021.
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

struct Sheet<Content: View>: View {
  @Environment(\.dismiss) var dismiss

  let backgroundColor: Color?
  let content: Content

  init(backgroundColor: Color? = nil, @ViewBuilder content: () -> Content) {
    self.backgroundColor = backgroundColor
    self.content = content()
  }

  var body: some View {
    ZStack(alignment: Alignment(horizontal: .trailing, vertical: .top)) {
      if let color = self.backgroundColor {
        color.ignoresSafeArea()
      }
      VStack(alignment: .center, spacing: 0) {
        self.content
      }
      Button(action: {
        self.dismiss()
      }) {
        ExitButton()
      }
      .keyCommand(UIKeyCommand.inputEscape, modifiers: [], title: "Close sheet")
      .padding()
    }
  }
}

public struct ExitButton: View {
  let size: CGFloat
  
  init(size: CGFloat? = nil) {
    self.size = size ?? (UIDevice.current.userInterfaceIdiom == .pad ? 28.0 : 24.0)
  }
  
  public var body: some View {
    Image(systemName: "xmark.circle.fill")
      .resizable()
      .scaledToFit()
      .frame(height: self.size)
      .foregroundColor(Color(UIColor.lightGray))
      .accessibility(label: Text("Close"))
      .accessibility(hint: Text("Tap to close the sheet"))
      .accessibility(addTraits: .isButton)
      .accessibility(removeTraits: .isImage)
  }
}
