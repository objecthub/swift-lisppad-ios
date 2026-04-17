//
//  FlexDatePicker.swift
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


struct FlexDatePicker: View {
  
  enum Value: Equatable {
    case single(Date?)
    case multi(Set<DateComponents>)
    case range(ClosedRange<Date>?)
    
    var cleared: Value {
      switch self {
        case .single(_):
          return .single(nil)
        case .multi(_):
          return .multi([])
        case .range(_):
          return .range(nil)
      }
    }
    
    var isValid: Bool {
      switch self {
        case .single(let date):
          return date != nil
        case .multi(_):
          return true
        case .range(let range):
          return range != nil
      }
    }
    
    var title: String {
      switch self {
        case .single(_):
          return "Select Date"
        case .range(_):
          return "Select Date Range"
        case .multi(_):
          return "Select Dates"
      }
    }
    
    func expanded(with bounds: Range<Date>? = nil,
                  using calendar: Calendar = .current) -> Set<DateComponents> {
      switch self {
        case .single(let date):
          return date.map { [calendar.dateComponents([.year, .month, .day], from: $0)] } ?? []
        case .multi(let dates):
          return dates
        case .range(let range):
          guard let range else { return [] }
          let start = bounds.map { max(range.lowerBound, $0.lowerBound) } ?? range.lowerBound
          let end = bounds.map { min(range.upperBound, $0.upperBound) } ?? range.upperBound
          guard start <= end else { return [] }
          return FlexDatePicker.allDays(in: start ... end, using: calendar)
      }
    }
  }
  
  @Environment(\.calendar) private var calendar
  @Environment(\.timeZone) private var timezone
  
  let title: String
  @Binding var value: Value
  let bounds: Range<Date>?
  
  @State private var selection: Set<DateComponents> = []
  
  init(_ title: String = "", value: Binding<Value>, in bounds: Range<Date>? = nil) {
    self.title = title
    self._value = value
    self.bounds = bounds
  }
  
  var body: some View {
    picker
      .onAppear { syncFromValue() }
      .onChange(of: value) { syncFromValue() }
      .onChange(of: selection) { pushToValue() }
  }
  
  @ViewBuilder
  private var picker: some View {
    if let bounds {
      MultiDatePicker(title, selection: selectionBinding, in: bounds)
    } else {
      MultiDatePicker(title, selection: selectionBinding)
    }
  }
  
  private var selectionBinding: Binding<Set<DateComponents>> {
    Binding(
      get: { selection },
      set: { selection = constrained($0) }
    )
  }
  
  private func constrained(_ raw: Set<DateComponents>) -> Set<DateComponents> {
    let filtered = bounds.map { range in
      raw.filter { components in
        guard let date = self.calendar.date(from: components) else { return false }
        return range.contains(date)
      }
    } ?? raw
    switch value {
      case .single:
        // If raw equals the current selection, the user tapped the selected date — deselect it.
        if filtered == selection {
          return []
        }
        guard let newest = filtered.subtracting(selection).first ?? filtered.first else { return [] }
        return [newest]
      case .multi:
        return filtered
      case .range:
        let added = filtered.subtracting(selection)
        let removed = selection.subtracting(filtered)
        let anchorComponents: DateComponents? = added.first ?? removed.first
        guard let anchor = anchorComponents.flatMap({ self.calendar.date(from: $0) }) else {
          return []
        }
        let existingDates = selection.compactMap { self.calendar.date(from: $0) }.sorted()
        let fixedEnd: Date? = existingDates.first == anchor || existingDates.isEmpty
                            ? existingDates.last
                            : existingDates.first
        guard let fixed = fixedEnd else {
          return [self.calendar.dateComponents([.year, .month, .day], from: anchor)]
        }
        return Self.allDays(in: clampedRange(from: min(anchor, fixed), to: max(anchor, fixed)),
                            using: self.calendar)
    }
  }
  
  private func clampedRange(from start: Date, to end: Date) -> ClosedRange<Date> {
    guard let bounds else { return start ... end }
    let clampedStart = max(start, bounds.lowerBound)
    let clampedEnd   = min(end, bounds.upperBound)
    return clampedStart <= clampedEnd ? clampedStart ... clampedEnd : clampedStart ... clampedStart
  }
  
  private static func allDays(in range: ClosedRange<Date>,
                              using calendar: Calendar) -> Set<DateComponents> {
    var result: Set<DateComponents> = []
    var cur = range.lowerBound
    while cur <= range.upperBound {
      result.insert(calendar.dateComponents([.year, .month, .day], from: cur))
      guard let next = calendar.date(byAdding: .day, value: 1, to: cur) else {
        break
      }
      cur = next
    }
    return result
  }
  
  private func pushToValue() {
    switch self.value {
      case .single:
        let date = selection.first.flatMap { self.calendar.date(from: $0) }
        value = .single(date)
      case .multi:
        value = .multi(selection)
      case .range:
        let sorted = selection.compactMap { self.calendar.date(from: $0) }.sorted()
        if let start = sorted.first, let end = sorted.last {
          value = .range(start ... end)
        } else {
          value = .range(nil)
        }
    }
  }
  
  private func syncFromValue() {
    let new = self.value.expanded(with: self.bounds, using: self.calendar)
    guard self.selection != new else {
      return
    }
    self.selection = new
  }
}
