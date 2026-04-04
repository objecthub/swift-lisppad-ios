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
  let cancelLabel: String?
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
                      message: self.message,
                      options: self.options,
                      cancelLabel: self.cancelLabel,
                      confirmLabel: self.confirmLabel,
                      selection: self.$currentSelection,
                      onCancel: self.dismiss,
                      onConfirm: self.confirm)
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
  let cancelLabel: String?
  let confirmLabel: String
  
  @Binding var selection: String
  
  let onCancel: () -> Void
  let onConfirm: () -> Void
  
  @FocusState private var isFocused: Bool
  
  private let dialogWidth: CGFloat = 270
  private let cornerRadius: CGFloat = 14
  private let dividerColor = Color(white: 0.5, opacity: 0.35)
  
  var body: some View {
    ZStack {
      // Dimming backdrop
      Color.black.opacity(0.2)
        .ignoresSafeArea()
        .onTapGesture { }
        .focusable()
        .focused($isFocused)
      // Dialog card
      VStack(spacing: 0) {
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
        // Navigation buttons
        Button {
          for i in self.options.indices {
            if self.options[i] == self.selection {
              self.selection = self.options[(i + 1) % self.options.count]
              break
            }
          }
        } label: {
          EmptyView()
        }
        .keyboardShortcut(.downArrow, modifiers: [])
        Button {
          for i in self.options.indices {
            if self.options[i] == self.selection {
              self.selection = self.options[(i - 1 + self.options.count) % self.options.count]
              break
            }
          }
        } label: {
          EmptyView()
        }
        .keyboardShortcut(.upArrow, modifiers: [])
        // Choices
        Divider()
          .background(self.dividerColor)
        VStack(spacing: 0) {
          ForEach(self.options, id: \.self) { option in
            VStack(spacing: 0) {
              OptionRow(label: option, isSelected: option == selection) {
                self.selection = option
              }
              Divider()
                .background(self.dividerColor)
            }
          }
        }
        // Buttons
        HStack(spacing: 0) {
          if let cancelLabel {
            AlertButton(label: cancelLabel, role: .cancel, action: onCancel)
              .keyboardShortcut(KeyEquivalent.escape, modifiers: [])
            Rectangle()
              .fill(self.dividerColor)
              .frame(width: 0.5)
          }
          AlertButton(label: confirmLabel, role: .confirm, action: onConfirm)
            .keyboardShortcut(KeyEquivalent.return, modifiers: [])
        }
        .frame(height: 44)
      }
      .frame(width: self.dialogWidth)
      .background(.regularMaterial)
      .clipShape(RoundedRectangle(cornerRadius: self.cornerRadius))
      //.shadow(color: .black.opacity(0.25), radius: 30, y: 10)
      .onAppear {
        self.isFocused = true
      }
    }
    .transition(.opacity.combined(with: .scale(scale: 1.08)))
    .animation(.spring(response: 0.28, dampingFraction: 0.82), value: true)
  }
}

private struct OptionRow: View {
  let label: String
  let isSelected: Bool
  let onTap: () -> Void
  
  var body: some View {
    Button(action: onTap) {
      HStack {
        Text(self.label)
          .font(.body)
          .foregroundStyle(.primary)
        Spacer()
        if self.isSelected {
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
      .contentShape(Rectangle())
    }
    .buttonStyle(AlertButtonStyle())
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
                         cancelLabel: String? = "Cancel",
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
