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

enum DatePickerSelectionMode {
  case single(Binding<Date?>)
  case multi(Binding<Set<DateComponents>>)
  case range(Binding<ClosedRange<Date>?>)
  
  func clear() {
    switch self {
      case .single(let date):
        date.wrappedValue = nil
      case .multi(let dates):
        dates.wrappedValue.removeAll()
      case .range(let range):
        range.wrappedValue = nil
    }
  }
}

struct FlexDatePicker: View {
  let title: String
  let mode: DatePickerSelectionMode
  let bounds: Range<Date>?
  
  @Binding private var selection: Set<DateComponents>
  
  init(_ title: String = "",
       mode: DatePickerSelectionMode,
       in bounds: Range<Date>? = nil,
       selection: Binding<Set<DateComponents>>) {
    self.title = title
    self.mode = mode
    self.bounds = bounds
    self._selection = selection
  }
  
  var body: some View {
    picker
    .onAppear {
      syncFromMode()
    }
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
      set: { newValue in
        selection = constrained(newValue)
        pushToMode()
      }
    )
  }
  
  private func constrained(_ raw: Set<DateComponents>) -> Set<DateComponents> {
    let filtered = bounds.map { range in
      raw.filter { components in
        guard let date = Calendar.current.date(from: components) else {
          return false
        }
        return range.contains(date)
      }
    } ?? raw
    switch mode {
      case .single:
        guard let newest = filtered.subtracting(selection).first ?? filtered.first else {
          return []
        }
        return [newest]
      case .multi:
        return filtered
      case .range:
        // Derive the new anchor from whatever date was just added or removed.
        let added = filtered.subtracting(selection)
        let removed = selection.subtracting(filtered)
        // Determine the new anchor date: prefer a newly tapped date, fall back to
        // the opposite end of whatever was just deselected.
        let anchorComponents: DateComponents? = added.first ?? removed.first
        guard let anchor = anchorComponents.flatMap({ Calendar.current.date(from: $0) }) else {
          return []
        }
        // The fixed end is whichever existing endpoint is not the anchor.
        let existingDates = selection.compactMap { Calendar.current.date(from: $0) }.sorted()
        let fixedEnd: Date? = existingDates.first == anchor || existingDates.isEmpty
                            ? existingDates.last
                            : existingDates.first
        guard let fixed = fixedEnd else {
          // Only one anchor so far — store just that date.
          return [Calendar.current.dateComponents([.year, .month, .day], from: anchor)]
        }
        let rangeStart = min(anchor, fixed)
        let rangeEnd = max(anchor, fixed)
        let clamped = clampedRange(from: rangeStart, to: rangeEnd)
        return allDays(in: clamped)
    }
  }
  
  private func clampedRange(from start: Date, to end: Date) -> ClosedRange<Date> {
    guard let bounds else { return start ... end }
    let clampedStart = max(start, bounds.lowerBound)
    let clampedEnd = min(end, bounds.upperBound)
    return clampedStart <= clampedEnd ? clampedStart...clampedEnd : clampedStart...clampedStart
  }
  
  private func allDays(in range: ClosedRange<Date>) -> Set<DateComponents> {
    var result: Set<DateComponents> = []
    var current = range.lowerBound
    while current <= range.upperBound {
      result.insert(Calendar.current.dateComponents([.year, .month, .day], from: current))
      guard let next = Calendar.current.date(byAdding: .day, value: 1, to: current) else { break }
      current = next
    }
    return result
  }
  
  private func pushToMode() {
    switch mode {
      case .single(let binding):
        binding.wrappedValue = selection.first.flatMap { Calendar.current.date(from: $0) }
      case .multi(let binding):
        binding.wrappedValue = selection
      case .range(let binding):
        let sorted = selection.compactMap { Calendar.current.date(from: $0) }.sorted()
        if let start = sorted.first, let end = sorted.last {
          binding.wrappedValue = start...end
        } else {
          binding.wrappedValue = nil
        }
    }
  }
  
  private func syncFromMode() {
    switch mode {
      case .single(let binding):
        selection = binding.wrappedValue.map {
          [Calendar.current.dateComponents([.year, .month, .day], from: $0)]
        } ?? []
      case .multi(let binding):
        selection = binding.wrappedValue
      case .range(let binding):
        guard let range = binding.wrappedValue else { selection = []; return }
        let start = bounds.map { max(range.lowerBound, $0.lowerBound) } ?? range.lowerBound
        let end = bounds.map { min(range.upperBound, $0.upperBound) } ?? range.upperBound
        guard start <= end else { selection = []; return }
        selection = allDays(in: start ... end)
    }
  }
}
