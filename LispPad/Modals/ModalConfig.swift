//
//  ModalConfig.swift
//  LispPad
//
//  Created by Matthias Zenger on 11/04/2026.
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

import Foundation

enum ModalConfig: Identifiable, Equatable {
  case textInput(TextInputModalConfig)
  case choice(ChoiceModalConfig)
  case datePickerAlert(DateInputModalConfig)
  
  var id: UUID {
    switch self {
      case .textInput(let config):
        return config.id
      case .choice(let config):
        return config.id
      case .datePickerAlert(let config):
        return config.id
    }
  }
}

struct ChoiceModalConfig: Identifiable, Equatable {
  let id = UUID()
  let title: String
  let message: String
  let options: [String]
  let selected: String?
  let cancel: String?
  let confirm: String
  let onCancel: () -> Void
  let onConfirm: (String) -> Void
  
  init(title: String,
       message: String,
       options: [String] = [],
       selected: String? = nil,
       cancel: String? = "Cancel",
       confirm: String? = nil,
       onCancel: @escaping () -> Void,
       onConfirm: @escaping (String) -> Void) {
    self.title = title
    self.message = message
    self.options = options
    self.selected = selected
    self.cancel = cancel
    self.confirm = confirm ?? (options.count == 0 ? "OK" : "Select")
    self.onCancel = onCancel
    self.onConfirm = onConfirm
  }
  
  static func == (lhs: ChoiceModalConfig, rhs: ChoiceModalConfig) -> Bool {
    return lhs.id == rhs.id
  }
}

struct TextInputModalConfig: Identifiable, Equatable {
  let id = UUID()
  let title: String
  let message: String
  let placeholder: String
  let initial: String
  let cancel: String
  let confirm: String
  let onCancel: () -> Void
  let onConfirm: (String) -> Void
  
  init(title: String,
       message: String,
       placeholder: String? = nil,
       initial: String? = nil,
       cancel: String? = nil,
       confirm: String? = nil,
       onCancel: @escaping () -> Void,
       onConfirm: @escaping (String) -> Void) {
    self.title = title
    self.message = message
    self.placeholder = placeholder ?? ""
    self.initial = initial ?? ""
    self.cancel = cancel ?? "Cancel"
    self.confirm = confirm ?? "OK"
    self.onCancel = onCancel
    self.onConfirm = onConfirm
  }
  
  static func == (lhs: TextInputModalConfig, rhs: TextInputModalConfig) -> Bool {
    return lhs.id == rhs.id
  }
}

struct DateInputModalConfig: Identifiable, Equatable {
  let id = UUID()
  let title: String?
  let message: String?
  let initial: FlexDatePicker.Value
  let bounds: Range<Date>?
  let timezone: TimeZone
  let cancel: String
  let confirm: String
  let onCancel: () -> Void
  let onConfirm: (FlexDatePicker.Value) -> Void
  
  init(title: String?,
       message: String?,
       initial: FlexDatePicker.Value,
       bounds: Range<Date>? = nil,
       timezone: TimeZone = .current,
       cancel: String? = nil,
       confirm: String? = nil,
       onCancel: @escaping () -> Void,
       onConfirm: @escaping (FlexDatePicker.Value) -> Void) {
    self.title = title
    self.message = message
    self.initial = initial
    self.bounds = bounds
    self.timezone = timezone
    self.cancel = cancel ?? "Cancel"
    self.confirm = confirm ?? "Select"
    self.onCancel = onCancel
    self.onConfirm = onConfirm
  }
  
  static func == (lhs: DateInputModalConfig, rhs: DateInputModalConfig) -> Bool {
    return lhs.id == rhs.id
  }
}
