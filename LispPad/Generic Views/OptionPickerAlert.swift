//
//  OptionPickerAlert.swift
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

/// A modal dialog that visually matches the system Alert style
/// and lets the user pick one option from a list.
///
/// Usage:
///     .optionPickerAlert(
///         isPresented: $showAlert,
///         title: "Sort By",
///         message: "Choose a sort order.",
///         options: ["Name", "Date", "Size"],
///         selected: currentSort,
///         confirmLabel: "Apply"
///     ) { chosen in
///         currentSort = chosen
///     }
struct OptionPickerAlert: ViewModifier {
  
  @Binding var isPresented: Bool
  let title: String
  let message: String?
  let options: [String]
  let selected: String?
  let cancelLabel: String
  let confirmLabel: String
  let onCancel: () -> Void
  let onConfirm: (String) -> Void
  
  @State private var currentSelection: String = ""
  
  func body(content: Content) -> some View {
    content
      .onChange(of: isPresented) { _, presented in
        if presented {
          currentSelection = selected ?? options.first ?? ""
        }
      }
      .plainFullScreenCover(isPresented: $isPresented) {
        OptionOverlay(title: title,
                      message: message,
                      options: options,
                      cancelLabel: cancelLabel,
                      confirmLabel: confirmLabel,
                      selection: $currentSelection,
                      onCancel: dismiss,
                      onConfirm: confirm)
      }
  }
  
  private func dismiss() {
    self.isPresented = false
    self.onCancel()
  }
  
  private func confirm() {
    let result = currentSelection
    self.isPresented = false
    self.onConfirm(result)
  }
}

private struct OptionOverlay: View {
  let title: String
  let message: String?
  let options: [String]
  let cancelLabel: String
  let confirmLabel: String
  
  @Binding var selection: String
  
  let onCancel: () -> Void
  let onConfirm: () -> Void
  
  private let dialogWidth: CGFloat = 270
  private let cornerRadius: CGFloat = 14
  private let dividerColor = Color(white: 0.5, opacity: 0.35)
  
  var body: some View {
    ZStack {
      // Dimming backdrop
      Color.black.opacity(0.2)
        .ignoresSafeArea()
        .onTapGesture { }
      // Dialog card
      VStack(spacing: 0) {
        headerSection
        Divider()
          .background(dividerColor)
        optionList
        buttonRow
      }
      .frame(width: dialogWidth)
      .background(.regularMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
      //.shadow(color: .black.opacity(0.25), radius: 30, y: 10)
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
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 20)
  }
  
  private var optionList: some View {
    VStack(spacing: 0) {
      ForEach(options, id: \.self) { option in
        VStack(spacing: 0) {
          OptionRow(label: option, isSelected: option == selection) {
            self.selection = option
          }
          Divider()
            .background(dividerColor)
        }
      }
    }
  }
  
  private var buttonRow: some View {
    HStack(spacing: 0) {
      AlertButton(label: cancelLabel, role: .cancel, action: onCancel)
      Rectangle()
        .fill(dividerColor)
        .frame(width: 0.5)
      AlertButton(label: confirmLabel, role: .confirm, action: onConfirm)
    }
    .frame(height: 44)
  }
}

private struct OptionRow: View {
  let label: String
  let isSelected: Bool
  let onTap: () -> Void
  
  @State private var isPressed = false
  
  var body: some View {
    Button(action: onTap) {
      HStack {
        Text(label)
          .font(.body)
          .foregroundStyle(.primary)
        Spacer()
        if isSelected {
          Image(systemName: "checkmark")
            .font(.body.weight(.semibold))
            .foregroundStyle(.tint)
        } else {
          Image(systemName: "checkmark")
            .font(.body.weight(.semibold))
            .foregroundStyle(.clear)
        }
      }
      .padding(.leading, 16)
      .padding(.trailing, 8)
      .padding(.vertical, 8)
      .background(isPressed ? Color.accentColor : Color.clear)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    ._onButtonGesture(pressing: { isPressed = $0 }, perform: {})
  }
}

private struct AlertButton: View {
  
  enum Role {
    case cancel
    case confirm
  }
  
  let label: String
  let role: Role
  let action: () -> Void
  
  @State private var isPressed = false
  
  var body: some View {
    Button(action: action) {
      Text(label)
        .font(role == .confirm ? .body.weight(.semibold) : .body)
        .foregroundStyle(.tint)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .background(isPressed ? Color(white: 0.5, opacity: 0.2) : Color.clear)
    ._onButtonGesture(pressing: { isPressed = $0 }, perform: {})
  }
}

extension View {
  
  /// Presents an option-picker alert over this view.
  ///
  /// - Parameters:
  ///   - isPresented: Binding that controls presentation.
  ///   - title: Bold headline shown at the top of the dialog.
  ///   - message: Optional secondary text below the title.
  ///   - options: The list of string options to choose from.
  ///   - selected: The option that appears pre-selected when the dialog opens.
  ///   - cancelLabel: Label for the cancel button (default "Cancel").
  ///   - confirmLabel: Label for the confirm button (default "OK").
  ///   - onConfirm: Called with the chosen option when the user confirms.
  func optionPickerAlert(isPresented: Binding<Bool>,
                         title: String,
                         message: String? = nil,
                         options: [String],
                         selected: String? = nil,
                         cancelLabel: String = "Cancel",
                         confirmLabel: String = "OK",
                         onCancel: @escaping () -> Void,
                         onConfirm: @escaping (String) -> Void) -> some View {
    self.modifier(OptionPickerAlert(isPresented: isPresented,
                                    title: title,
                                    message: message,
                                    options: options,
                                    selected: selected,
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
    Button("Sort by…") { show = true }
    if !result.isEmpty {
      Text("Chosen: \(result)")
        .foregroundStyle(.secondary)
    }
  }
  .frame(maxWidth: .infinity, maxHeight: .infinity)
  .optionPickerAlert(
    isPresented: $show,
    title: "Sort By",
    message: "Choose a sort order.",
    options: ["Name", "Date Modified", "Date Created And Many More Arguments you can't think of", "Size"],
    selected: result.isEmpty ? "Name" : result,
    confirmLabel: "Select",
    onCancel: { },
    onConfirm: { result = $0 })
}
