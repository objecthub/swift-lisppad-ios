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
  
  var body: some View {
    List {
      Picker("Severity", selection: $minSeverityFilter) {
        Text("Debug").font(LispPadUI.definitionsFont).tag(Severity.debug)
        Text("Info").font(LispPadUI.definitionsFont).tag(Severity.info)
        Text("Warning").font(LispPadUI.definitionsFont).tag(Severity.warning)
        Text("Error").font(LispPadUI.definitionsFont).tag(Severity.error)
        Text("Fatal").font(LispPadUI.definitionsFont).tag(Severity.fatal)
      }
      .font(LispPadUI.definitionsFont)
      .pickerStyle(.menu)
      .frame(height: 22)
      .alignmentGuide(.listRowSeparatorLeading) { d in -20 }
      TextField("Filter", text: $logMessageFilter)
        .font(LispPadUI.definitionsFont)
        .autocapitalization(.none)
        .disableAutocorrection(true)
        .frame(height: 22)
        .alignmentGuide(.listRowSeparatorLeading) { d in -20 }
      Toggle("Filter Tag", isOn: $filterTag)
        .font(LispPadUI.definitionsFont)
        .frame(height: 22)
        .alignmentGuide(.listRowSeparatorLeading) { d in -20 }
      Toggle("Filter Message", isOn: $filterMessage)
        .font(LispPadUI.definitionsFont)
        .frame(height: 22)
        .alignmentGuide(.listRowSeparatorLeading) { d in -20 }
      HStack(alignment: .center, spacing: 0.0) {
        Button("Reset", role: .destructive) {
          self.minSeverityFilter = .debug
          self.logMessageFilter = ""
          self.filterMessage = true
          self.filterTag = true
        }
        .font(LispPadUI.definitionsFont)
        .buttonStyle(.borderless)
        Spacer()
        Button("Cancel", role: .destructive) {
          self.minSeverityFilter = self.settings.logSeverityFilter
          self.logMessageFilter = self.settings.logMessageFilter
          self.filterMessage = self.settings.logFilterMessages
          self.filterTag = self.settings.logFilterTags
          self.showLogFilterPopOver = false
        }
        .font(LispPadUI.definitionsFont)
        .buttonStyle(.borderless)
      }
      .frame(height: 22)
      .alignmentGuide(.listRowSeparatorLeading) { d in -20 }
      .listRowBackground(Color(UIColor.systemGroupedBackground))
    }
    .listStyle(.plain)
    .scrollDisabled(true)
    .environment(\.defaultMinListRowHeight, 22)
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
