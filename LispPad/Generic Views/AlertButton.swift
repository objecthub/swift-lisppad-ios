//
//  AlertButton.swift
//  LispPad
//
//  Created by Matthias Zenger on 04/04/2026.
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

struct AlertButton: View {
  
  enum Role {
    case cancel
    case confirm
  }
  
  let label: String
  let role: Role
  let action: () -> Void
  
  var body: some View {
    Button(action: action) {
      Text(label)
        .font(role == .confirm ? .body.weight(.semibold) : .body)
        .foregroundStyle(.tint)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
    }
    .buttonStyle(AlertButtonStyle())
  }
}

struct AlertButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .background(configuration.isPressed ? Color(white: 0.5, opacity: 0.2) : Color.clear)
  }
}
