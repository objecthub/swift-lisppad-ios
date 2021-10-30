//
//  LogFilterView.swift
//  LispPad
//
//  Created by Matthias Zenger on 28/10/2021.
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
    NavigationView {
      Form {
        Picker(selection: $minSeverityFilter, label: Text("Severity")) {
          Text("Debug").tag(Severity.debug)
          Text("Info").tag(Severity.info)
          Text("Warning").tag(Severity.warning)
          Text("Error").tag(Severity.error)
          Text("Fatal").tag(Severity.fatal)
        }
        TextField("Filter", text: $logMessageFilter)
        .autocapitalization(.none)
        .disableAutocorrection(true)
        Toggle("Filter Tag", isOn: $filterTag)
        Toggle("Filter Message", isOn: $filterMessage)
      }
      .navigationBarTitleDisplayMode(.inline)
      .navigationTitle("Log Filter")
      .toolbar {
        ToolbarItemGroup(placement: .navigationBarLeading) {
          HStack(alignment: .center, spacing: LispPadUI.toolbarSeparator) {
            Button(action: {
              self.minSeverityFilter = .debug
              self.logMessageFilter = ""
              self.filterMessage = true
              self.filterTag = true
            }) {
              Text("Reset")
            }
          }
        }
        ToolbarItemGroup(placement: .navigationBarTrailing) {
          HStack(alignment: .center, spacing: LispPadUI.toolbarSeparator) {
            Button(action: {
              self.showLogFilterPopOver = false
            }) {
              Text("Close")
            }
          }
        }
      }
    }
    .navigationViewStyle(.stack)
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
