//
//  DateInputModal.swift
//  LispPad
//
//  Created by Matthias Zenger on 09/04/2026.
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
/// A modal dialog that visually matches the system Alert style
/// and lets the user pick a single date, multiple dates, or a date range
/// using a calendar. Backed by FlexDatePicker.
/// 
struct DateInputModal: View {
  @Environment(\.calendar) private var calendar
  @Environment(\.timeZone) private var timezone
  
  let title: String?
  let message: String?
  @Binding var selection: FlexDatePicker.Value
  let bounds: Range<Date>?
  let cancelLabel: String
  let confirmLabel: String
  let onCancel: () -> Void
  let onConfirm: (FlexDatePicker.Value) -> Void
  
  @FocusState private var isFocused: Bool
  @ScaledMetric private var calendarHeight: CGFloat = 290
  
  private static let dialogWidth: CGFloat = 320
  private static let cornerRadius: CGFloat = 14
  private static let dividerColor = Color(white: 0.5, opacity: 0.35)
  
  var body: some View {
    ZStack {
      Color.black.opacity(0.2)
        .ignoresSafeArea()
        .onTapGesture { }
        .focusable()
        .focused($isFocused)
      VStack(spacing: 0) {
        VStack(spacing: 4) {
          Text(self.title ?? self.selection.title)
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
        Divider()
          .background(Self.dividerColor)
        FlexDatePicker("", value: $selection, in: bounds)
          .labelsHidden()
          .padding(.horizontal, 8)
          .padding(.vertical, 8)
          .frame(height: self.calendarHeight)
        self.selectionSummary
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .padding(.horizontal, 4)
          .padding(.bottom, 8)
        Divider()
          .background(Self.dividerColor)
        HStack(spacing: 0) {
          AlertButton(label: "Clear", role: .reset) {
            self.selection = self.selection.cleared
          }
          .keyboardShortcut(.escape, modifiers: [])
          Rectangle()
            .fill(Self.dividerColor)
            .frame(width: 0.5)
          AlertButton(label: cancelLabel, role: .cancel) {
            onCancel()
            self.selection = self.selection.cleared
          }
          .keyboardShortcut(.escape, modifiers: [])
          Rectangle()
            .fill(Self.dividerColor)
            .frame(width: 0.5)
          AlertButton(label: confirmLabel, role: .confirm) {
            onConfirm(self.selection)
            self.selection = self.selection.cleared
          }
          .keyboardShortcut(.return, modifiers: [])
          .disabled(!self.selection.isValid)
        }
        .frame(height: 44)
      }
      .frame(width: Self.dialogWidth)
      .background(.regularMaterial)
      .clipShape(RoundedRectangle(cornerRadius: Self.cornerRadius))
      // .shadow(color: .black.opacity(0.25), radius: 30, y: 10)
      .onAppear {
        isFocused = true
      }
    }
    .transition(.opacity.combined(with: .scale(scale: 1.08)))
    .animation(.spring(response: 0.28, dampingFraction: 0.82), value: true)
  }
  
  @ViewBuilder
  private var selectionSummary: some View {
    switch self.selection {
      case .single(let date):
        if let date {
          Text(date.formatted(date: .abbreviated, time: .omitted))
        } else {
          Text("No date selected")
        }
      case .multi(let dates):
        let dates = dates.compactMap { self.calendar.date(from: $0) }.sorted()
        if dates.isEmpty {
          Text("No dates selected")
        } else if dates.count == 1, let first = dates.first {
          Text(first.formatted(date: .abbreviated, time: .omitted))
        } else {
          Text(dates.map { $0.formatted(date: .numeric, time: .omitted) }
                    .joined(separator: ", "))
            .lineLimit(3)
        }
      case .range(let range):
        if let start = range?.lowerBound, let end = range?.upperBound {
          if start == end {
            Text(start.formatted(date: .abbreviated, time: .omitted))
          } else {
            Text("\(start.formatted(date: .abbreviated, time: .omitted)) –" +
                 " \(end.formatted(date: .abbreviated, time: .omitted))")
          }
        } else {
          Text("No range selected")
        }
    }
  }
}
