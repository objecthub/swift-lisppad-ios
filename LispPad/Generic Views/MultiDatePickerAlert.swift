//
//  MultiDatePickerAlert.swift
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

/// A modal dialog that visually matches the system Alert style
/// and lets the user pick a single date, multiple dates, or a date range
/// using a calendar. Backed by FlexDatePicker.
///
/// Single date usage:
///
///     .datePickerAlert(
///         isPresented: $showAlert,
///         title: "Select Date",
///         message: "Choose a date.",
///         initialDate: currentDate,
///         confirmLabel: "Apply"
///     ) { date in
///         currentDate = date
///     }
///
/// Multiple dates usage:
///
///     .multiDatePickerAlert(
///         isPresented: $showAlert,
///         title: "Select Dates",
///         message: "Choose one or more dates.",
///         initialDates: currentDates,
///         confirmLabel: "Apply"
///     ) { dates in
///         currentDates = dates
///     }
///
/// Date range usage:
///
///     .dateRangePickerAlert(
///         isPresented: $showAlert,
///         title: "Select Range",
///         message: "Choose a start and end date.",
///         initialRange: currentRange,
///         confirmLabel: "Apply"
///     ) { range in
///         currentRange = range
///     }
struct MultiDatePickerAlert: ViewModifier {
  
  enum Initial {
    case single(Date?)
    case range(ClosedRange<Date>?)
    case multiple(Set<DateComponents>?)
    
    var title: String {
      switch self {
        case .single(_):
          return "Select Date"
        case .range(_):
          return "Select Date Range"
        case .multiple(_):
          return "Select Dates"
      }
    }
  }
  
  enum Result {
    case none
    case single(Date)
    case range(ClosedRange<Date>)
    case multiple(Set<DateComponents>)
    
    var date: Date? {
      switch self {
        case .none:
          return nil
        case .single(let d):
          return d
        case .range(let r):
          if r.lowerBound == r.upperBound {
            return r.lowerBound
          } else {
            return nil
          }
        case .multiple(let s):
          if s.count == 1, let d = s.first?.date {
            return d
          } else {
            return nil
          }
      }
    }
    
    var dateRange: ClosedRange<Date>? {
      switch self {
        case .none:
          return nil
        case .single(let d):
          return ClosedRange(uncheckedBounds: (d, d))
        case .range(let r):
          return r
        case .multiple(let s):
          if s.count == 1, let d = s.first?.date {
            return ClosedRange(uncheckedBounds: (d, d))
          } else if s.count == 2,
                    let d = s.first?.date,
                    let e = Calendar.current.date(byAdding: .day, value: 1, to: d),
                    s.contains(Calendar.current.dateComponents(in: .current, from: d)) {
            return ClosedRange(uncheckedBounds: (min(d, e), max(d, e)))
          } else {
            return nil
          }
      }
    }
    
    var selection: Set<DateComponents> {
      if case .multiple(let s) = self {
        return s
      } else {
        return []
      }
    }
  }
  
  @Binding var isPresented: Bool
  let title: String
  let message: String?
  let initial: Initial
  let bounds: Range<Date>?
  let timezone: TimeZone
  let cancelLabel: String
  let confirmLabel: String
  let onCancel: () -> Void
  let onConfirm: (Result) -> Void
  
  @State private var date: Date? = nil
  @State private var range: ClosedRange<Date>? = nil
  @State private var selection: Set<DateComponents> = []
  
  func body(content: Content) -> some View {
    content
      .plainFullScreenCover(isPresented: $isPresented) {
        DatePickerOverlay(
          title: title,
          message: message,
          mode: mode,
          bounds: bounds,
          cancelLabel: cancelLabel,
          confirmLabel: confirmLabel,
          onCancel: dismiss,
          onConfirm: confirm
        )
        .environment(\.timeZone, self.timezone)
      }
      .onChange(of: self.isPresented) {
        self.date = nil
        self.range = nil
        self.selection = []
      }
  }
  
  var mode: DatePickerSelectionMode {
    switch self.initial {
      case .single(_):
        return .single($date)
      case .range(_):
        return .range($range)
      case .multiple(_):
        return .multi($selection)
    }
  }
  
  private func dismiss() {
    self.onCancel()
    self.isPresented = false
  }
  
  private func confirm() {
    let result: Result
    switch self.initial {
      case .single(_):
        if let date {
          result = .single(date)
        } else {
          result = .none
        }
      case .range(_):
        if let range {
          result = .range(range)
        } else {
          result = .none
        }
      case .multiple(_):
        result = .multiple(self.selection)
    }
    self.onConfirm(result)
    self.isPresented = false
  }
}

private struct DatePickerOverlay: View {
  @SwiftUI.Environment(\.calendar) private var calendar
  @SwiftUI.Environment(\.timeZone) private var timezone
  
  let title: String
  let message: String?
  let mode: DatePickerSelectionMode
  let bounds: Range<Date>?
  let cancelLabel: String
  let confirmLabel: String
  let onCancel: () -> Void
  let onConfirm: () -> Void
  
  @State private var selection: Set<DateComponents> = []
  @FocusState private var isFocused: Bool
  private let dialogWidth: CGFloat = 320
  private let cornerRadius: CGFloat = 14
  private let dividerColor = Color(white: 0.5, opacity: 0.35)
  @ScaledMetric private var calendarHeight: CGFloat = 290
  
  var body: some View {
    ZStack {
      Color.black.opacity(0.2)
        .ignoresSafeArea()
        .onTapGesture { }
        .focusable()
        .focused($isFocused)
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
        Divider()
          .background(self.dividerColor)
        FlexDatePicker("", mode: mode, in: bounds, selection: $selection)
          .labelsHidden()
          .padding(.horizontal, 8)
          .padding(.vertical, 8)
          .frame(height: self.calendarHeight)
        self.selectionSummary
        Divider()
          .background(self.dividerColor)
        HStack(spacing: 0) {
          AlertButton(label: "Clear", role: .reset) {
            self.mode.clear()
            self.selection = []
          }
          .keyboardShortcut(.escape, modifiers: [])
          Rectangle()
            .fill(dividerColor)
            .frame(width: 0.5)
          AlertButton(label: cancelLabel, role: .cancel, action: onCancel)
            .keyboardShortcut(.escape, modifiers: [])
          Rectangle()
            .fill(dividerColor)
            .frame(width: 0.5)
          AlertButton(label: confirmLabel, role: .confirm, action: onConfirm)
            .keyboardShortcut(.return, modifiers: [])
        }
        .frame(height: 44)
      }
      .frame(width: dialogWidth)
      .background(.regularMaterial)
      .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
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
    Group {
      switch mode {
        case .single:
          if let date = selection.first.flatMap({ self.calendar.date(from: $0) }) {
            Text(date.formatted(date: .abbreviated, time: .omitted))
          } else {
            Text("No date selected")
          }
        case .multi:
          let dates = selection.compactMap { self.calendar.date(from: $0) }.sorted()
          if dates.isEmpty {
            Text("No dates selected")
          } else if dates.count == 1, let first = dates.first {
            Text(first.formatted(date: .abbreviated, time: .omitted))
          } else {
            Text(dates.map { $0.formatted(date: .numeric, time: .omitted) }
                      .joined(separator: ", "))
              .lineLimit(3)
          }
        case .range:
          let sorted = selection.compactMap { self.calendar.date(from: $0) }.sorted()
          if let start = sorted.first, let end = sorted.last {
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
    .font(.subheadline)
    .foregroundStyle(.secondary)
    .padding(.horizontal, 4)
    .padding(.bottom, 8)
  }
}

extension View {
  
  /// Presents a single-date picker alert over this view.
  func datePickerAlert(
    isPresented: Binding<Bool>,
    title: String,
    message: String? = nil,
    initialDate: Date?,
    cancelLabel: String = "Cancel",
    confirmLabel: String = "OK",
    onConfirm: @escaping (MultiDatePickerAlert.Result) -> Void
  ) -> some View {
    modifier(MultiDatePickerAlert(
      isPresented: isPresented,
      title: title,
      message: message,
      initial: .single(initialDate),
      bounds: nil,
      timezone: .current,
      cancelLabel: cancelLabel,
      confirmLabel: confirmLabel,
      onCancel: { },
      onConfirm: onConfirm
    ))
  }
  
    /// Presents a multi-date picker alert over this view.
  func multiDatePickerAlert(
    isPresented: Binding<Bool>,
    title: String,
    message: String? = nil,
    initialDates: Set<DateComponents>,
    cancelLabel: String = "Cancel",
    confirmLabel: String = "OK",
    onConfirm: @escaping (MultiDatePickerAlert.Result) -> Void
  ) -> some View {
    modifier(MultiDatePickerAlert(
      isPresented: isPresented,
      title: title,
      message: message,
      initial: .multiple(initialDates),
      bounds: nil,
      timezone: .current,
      cancelLabel: cancelLabel,
      confirmLabel: confirmLabel,
      onCancel: { },
      onConfirm: onConfirm
    ))
  }
  
    /// Presents a date range picker alert over this view.
  func dateRangePickerAlert(
    isPresented: Binding<Bool>,
    title: String,
    message: String? = nil,
    initialRange: ClosedRange<Date>?,
    cancelLabel: String = "Cancel",
    confirmLabel: String = "OK",
    onConfirm: @escaping (MultiDatePickerAlert.Result) -> Void
  ) -> some View {
    modifier(MultiDatePickerAlert(
      isPresented: isPresented,
      title: title,
      message: message,
      initial: .range(initialRange),
      bounds: nil,
      timezone: .current,
      cancelLabel: cancelLabel,
      confirmLabel: confirmLabel,
      onCancel: { },
      onConfirm: onConfirm
    ))
  }
  
  func flexDatePickerAlert(
    isPresented: Binding<Bool>,
    title: String? = nil,
    message: String? = nil,
    initial: MultiDatePickerAlert.Initial,
    bounds: Range<Date>? = nil,
    timezone: TimeZone = .current,
    cancelLabel: String? = nil,
    confirmLabel: String? = nil,
    onCancel: @escaping () -> Void,
    onConfirm: @escaping (MultiDatePickerAlert.Result) -> Void) -> some View {
    modifier(MultiDatePickerAlert(
      isPresented: isPresented,
      title: initial.title,
      message: message,
      initial: initial,
      bounds: bounds,
      timezone: timezone,
      cancelLabel: cancelLabel ?? "Cancel",
      confirmLabel: confirmLabel ?? "OK",
      onCancel: onCancel,
      onConfirm: onConfirm
    ))
  }
}

#Preview("Single Date") {
  @Previewable @State var show = false
  @Previewable @State var date: Date? = .now
  
  VStack(spacing: 20) {
    Button("Select Date…") { show = true }
    if let date {
      Text(date.formatted(date: .long, time: .omitted))
        .foregroundStyle(.secondary)
    }
  }
  .frame(maxWidth: .infinity, maxHeight: .infinity)
  .datePickerAlert(
    isPresented: $show,
    title: "Select Date",
    message: "Choose a date.",
    initialDate: date,
    confirmLabel: "Apply"
  ) { date = $0.date }
}

#Preview("Multiple Dates") {
  @Previewable @State var show = false
  @Previewable @State var dates: Set<DateComponents> = []
  
  VStack(spacing: 20) {
    Button("Select Dates…") { show = true }
    Text("\(dates.count) date(s) selected")
      .foregroundStyle(.secondary)
  }
  .frame(maxWidth: .infinity, maxHeight: .infinity)
  .multiDatePickerAlert(
    isPresented: $show,
    title: "Select Dates",
    message: "Choose one or more dates.",
    initialDates: dates,
    confirmLabel: "Apply"
  ) { dates = $0.selection }
}

#Preview("Date Range") {
  @Previewable @State var show = false
  @Previewable @State var range: ClosedRange<Date>? = nil
  
  VStack(spacing: 20) {
    Button("Select Range…") { show = true }
    if let range {
      Text("\(range.lowerBound.formatted(date: .abbreviated, time: .omitted)) – \(range.upperBound.formatted(date: .abbreviated, time: .omitted))")
        .foregroundStyle(.secondary)
    }
  }
  .frame(maxWidth: .infinity, maxHeight: .infinity)
  .dateRangePickerAlert(
    isPresented: $show,
    title: "Select Range",
    message: "Choose a start and end date.",
    initialRange: range,
    confirmLabel: "Apply",
  ) { range = $0.dateRange }
}
