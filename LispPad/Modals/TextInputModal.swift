//
//  TextInputModal.swift
//  LispPad
//
//  Created by Matthias Zenger on 03/04/2026.
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

/// 
/// A modal dialog that visually matches the system Alert style but supports a
/// single-line text field with a Cancel and an OK button.
///
struct TextInputModal: View {
  let title: String
  let message: String?
  let placeholder: String
  @Binding var text: String
  let cancelLabel: String
  let confirmLabel: String
  let onCancel: () -> Void
  let onConfirm: () -> Void
  
  @FocusState private var fieldFocused: Bool

  private let dialogWidth: CGFloat = 270
  private let cornerRadius: CGFloat = 14
  private let dividerColor = Color(white: 0.5, opacity: 0.35)
  
  var body: some View {
    ZStack {
      Color.black.opacity(0.2)
        .ignoresSafeArea()
        .onTapGesture { } // absorb taps
      VStack(spacing: 0) {
        headerSection
        Divider().background(dividerColor)
        buttonRow
      }
      .frame(width: dialogWidth)
      .background(.regularMaterial)
      .clipShape(RoundedRectangle(cornerRadius: self.cornerRadius))
      // .shadow(color: .black.opacity(0.25), radius: 30, y: 10)
      .padding(.bottom, 16)
      .onAppear { // Select the text field when the alert appears
        fieldFocused = true
      }
      .onDisappear {
        fieldFocused = false
      }
    }
    .transition(.opacity.combined(with: .scale(scale: 1.08)))
    .animation(.spring(response: 0.28, dampingFraction: 0.82), value: true)
  }
  
  private var headerSection: some View {
    VStack(spacing: 4) {
      Text(title)
        .font(.headline)
        .multilineTextAlignment(.center)
      if let message {
        Text(message)
          .font(.footnote)
          .foregroundStyle(.primary)
          .multilineTextAlignment(.center)
      }
      TextField(placeholder, text: $text)
        .focused($fieldFocused)
        .autocapitalization(.none)
        .disableAutocorrection(true)
        .textFieldStyle(.plain)
        .font(.body)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
          RoundedRectangle(cornerRadius: 7)
            .fill(Color(white: 0.5, opacity: 0.15))
            .overlay(RoundedRectangle(cornerRadius: 7)
                       .strokeBorder(Color(white: 0.5, opacity: 0.3), lineWidth: 0.5))
        )
        .padding(.top, 6)
        .onSubmit(self.onConfirm)
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 20)
  }
  
  private var buttonRow: some View {
    HStack(spacing: 0) {
      AlertButton(label: cancelLabel, role: .cancel, action: onCancel)
        .keyboardShortcut(KeyEquivalent.escape, modifiers: [])
      Rectangle()
        .fill(dividerColor)
        .frame(width: 0.5)
      AlertButton(label: confirmLabel, role: .confirm, action: onConfirm)
    }
    .frame(height: 44)
  }
}
