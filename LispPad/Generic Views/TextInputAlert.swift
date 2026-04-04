//
//  TextInputAlert.swift
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

/// A modal dialog that visually matches the system Alert style but supports a
/// single-line text field with a Cancel and an OK button.
///
/// Usage:
///     .textInputAlert(
///       isPresented: $showAlert,
///       title: "Rename",
///       message: "Enter a new name for this item.",
///       placeholder: "Name",
///       initialText: item.name,
///       confirmLabel: "Rename"
///     ) { newText in
///       item.name = newText
///     }


struct TextInputAlert: ViewModifier {
  
  @Binding var isPresented: Bool
  let title: String
  let message: String?
  let placeholder: String
  let initialText: String
  let cancelLabel: String
  let confirmLabel: String
  let onCancel: () -> Void
  let onConfirm: (String) -> Void
  
  @State private var text: String = ""
  
  func body(content: Content) -> some View {
    content
      .onChange(of: isPresented) { _, presented in
        if presented {
          text = initialText
        }
      }
      .plainFullScreenCover(isPresented: $isPresented) {
        ZStack {
          AlertOverlay(title: title,
                       message: message,
                       placeholder: placeholder,
                       cancelLabel: cancelLabel,
                       confirmLabel: confirmLabel,
                       text: $text,
                       onCancel: dismiss,
                       onConfirm: confirm)
        }
        .presentationBackground(.clear) // Keep the dimming layer visible
      }
  }
  
  private func dismiss() {
    isPresented = false
    self.onCancel()
  }
  
  private func confirm() {
    let result = text
    self.isPresented = false
    self.onConfirm(result)
  }
}

private struct AlertOverlay: View {
  let title: String
  let message: String?
  let placeholder: String
  let cancelLabel: String
  let confirmLabel: String
  
  @Binding var text: String
  @FocusState private var fieldFocused: Bool
  
  let onCancel: () -> Void
  let onConfirm: () -> Void
  
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

extension View {
  
  /// Presents a text input alert over this view.
  ///
  /// - Parameters:
  ///   - isPresented: Binding that controls presentation.
  ///   - title: Bold headline shown at the top of the dialog.
  ///   - message: Optional secondary text below the title.
  ///   - placeholder: Placeholder shown inside the text field when empty.
  ///   - initialText: Text pre-filled into the field when the dialog appears.
  ///   - cancelLabel: Label for the cancel button (default "Cancel").
  ///   - confirmLabel: Label for the confirm button (default "OK").
  ///   - onConfirm: Called with the current field text when the user confirms.
  func textInputAlert(isPresented: Binding<Bool>,
                      title: String,
                      message: String? = nil,
                      placeholder: String = "",
                      initialText: String = "",
                      cancelLabel: String = "Cancel",
                      confirmLabel: String = "OK",
                      onCancel: @escaping () -> Void,
                      onConfirm: @escaping (String) -> Void) -> some View {
    self.modifier(TextInputAlert(isPresented: isPresented,
                                 title: title,
                                 message: message,
                                 placeholder: placeholder,
                                 initialText: initialText,
                                 cancelLabel: cancelLabel,
                                 confirmLabel: confirmLabel,
                                 onCancel: onCancel,
                                 onConfirm: onConfirm))
  }
}

#Preview {
  @Previewable @State var show = false
  @Previewable @State var result = ""
  
  VStack(spacing: 20) {
    Button("Rename item…") { show = true }
    if !result.isEmpty {
      Text("Confirmed: \(result)")
        .foregroundStyle(.secondary)
    }
  }
  .frame(maxWidth: .infinity, maxHeight: .infinity)
  .textInputAlert(
    isPresented: $show,
    title: "Rename",
    message: "Enter a new name for this item.",
    placeholder: "Name",
    initialText: "My Document",
    confirmLabel: "Rename",
    onCancel: { result = "CANCELLED" },
    onConfirm: { result = $0 }
  )
}
