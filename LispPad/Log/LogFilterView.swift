//
//  LogFilterView.swift
//  LispPad
//
//  Created by Matthias Zenger on 28/10/2021.
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

struct LogFilterView: View {
  @EnvironmentObject var settings: UserSettings
  @EnvironmentObject var sessionLog: SessionLog
  @Binding var showLogFilterPopOver: Bool
  @State var minSeverityFilter: Severity
  @State var logMessageFilter: String
  @State var filterMessage: Bool
  @State var filterTag: Bool
  
  init(showLogFilterPopOver: Binding<Bool>,
       minSeverityFilter: Severity,
       logMessageFilter: String,
       filterMessage: Bool,
       filterTag: Bool) {
    self._showLogFilterPopOver = showLogFilterPopOver
    self._minSeverityFilter = State(initialValue: minSeverityFilter)
    self._logMessageFilter = State(initialValue: logMessageFilter)
    self._filterMessage = State(initialValue: filterMessage)
    self._filterTag = State(initialValue: filterTag)
  }

  private var rowSeparator: some View {
    Rectangle()
      .fill(Color(UIColor.separator))
      .frame(height: 1 / UIScreen.main.scale)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack(alignment: .center, spacing: 0) {
        Button(role: .destructive) {
          self.minSeverityFilter = .debug
          self.logMessageFilter = ""
          self.filterMessage = true
          self.filterTag = true
        } label: {
          ResetButton(size: 26, legacySize: 20)
        }
        Spacer()
        Button(role: .destructive) {
          self.minSeverityFilter = self.settings.logSeverityFilter
          self.logMessageFilter = self.settings.logMessageFilter
          self.filterMessage = self.settings.logFilterMessages
          self.filterTag = self.settings.logFilterTags
          self.showLogFilterPopOver = false
        } label: {
          ExitButton(size: 26, legacySize: 20)
        }
      }
      .padding(.init(top: 10, leading: 14, bottom: 8, trailing: 14))
      self.rowSeparator
      HStack(alignment: .center, spacing: 0) {
        Text("Severity")
        Spacer()
        Picker("Severity", selection: $minSeverityFilter) {
          Text("Debug").tag(Severity.debug)
          Text("Info").tag(Severity.info)
          Text("Warning").tag(Severity.warning)
          Text("Error").tag(Severity.error)
          Text("Fatal").tag(Severity.fatal)
        }
        .pickerStyle(.menu)
        .labelsHidden()
      }
      .padding(.horizontal, 14)
      .padding(.vertical, 6)
      self.rowSeparator.padding(.leading, 8)
      TextField("Filter", text: $logMessageFilter)
        .autocapitalization(.none)
        .disableAutocorrection(true)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
      self.rowSeparator.padding(.leading, 8)
      Toggle("Filter Tag", isOn: $filterTag)
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
      self.rowSeparator.padding(.leading, 8)
      Toggle("Filter Message", isOn: $filterMessage)
        .padding(.init(top: 6, leading: 14, bottom: 16, trailing: 14))
    }
    .font(.body)
    .fixedSize(horizontal: false, vertical: true)
    .onDisappear {
      let searchText = self.logMessageFilter
                         .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
      self.settings.logSeverityFilter = self.minSeverityFilter
      self.settings.logMessageFilter = searchText
      self.settings.logFilterMessages = self.filterMessage
      self.settings.logFilterTags = self.filterTag
      self.sessionLog.set(severity: self.minSeverityFilter,
                          search: searchText,
                          tag: self.filterTag,
                          message: self.filterMessage)
    }
  }
}
