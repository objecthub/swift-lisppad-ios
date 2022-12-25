//
//  LogView.swift
//  LispPad
//
//  Created by Matthias Zenger on 27/10/2021.
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
import UniformTypeIdentifiers

struct LogView: View {
  static let timeFont = Font.system(size: 10.0, weight: .semibold, design: .monospaced)
  static let tagFont = Font.system(size: 9.0, weight: .regular, design: .monospaced)
  static let iconFont = Font.system(size: 20).weight(.light)
  let font: Font
  
  @EnvironmentObject var settings: UserSettings
  @EnvironmentObject var sessionLog: SessionLog
  @AppStorage("Log.logShowTime") var showTime: Bool = true
  @AppStorage("Log.logShowTags") var showTags: Bool = false
  @State var showLogFilterPopOver: Bool = false
  @Binding var input: String
  @Binding var showSheet: InterpreterView.SheetAction?
  @Binding var showModal: InterpreterView.SheetAction?
  
  func color(severity: Severity) -> Color {
    switch severity {
      case .debug:
        return .secondary
      case .info:
        return .blue
      case .warning:
        return .orange
      case .error:
        return .red
      case .fatal:
        return .purple
    }
  }
  
  var logFilterExplanation: String {
    if self.settings.logMessageFilter.isEmpty {
      if self.settings.logSeverityFilter == .debug {
        return "All"
      } else {
        return "≥ \(self.settings.logSeverityFilter)"
      }
    } else if self.settings.logSeverityFilter == .debug {
      return self.settings.logMessageFilter
    } else {
      return "≥ \(self.settings.logSeverityFilter), \(self.settings.logMessageFilter)"
    }
  }
  
  var body: some View {
    ZStack(alignment: .topLeading) {
      ScrollViewReader { scrollViewProxy in
        ScrollView(.vertical, showsIndicators: true) {
          Spacer(minLength: 35)
          LazyVStack(alignment: .leading, spacing: 0) {
            ForEach(self.sessionLog.filteredLogEntries, id: \.id) { entry in
              HStack(alignment: .center, spacing: 8.0) {
                if self.showTags {
                  VStack(alignment: .leading, spacing: 0.0) {
                    if self.showTime {
                      Text(entry.timeString)
                        .font(Self.timeFont)
                        .foregroundColor(self.color(severity: entry.severity))
                        .fixedSize(horizontal: false, vertical: false)
                    }
                    if self.showTags && !entry.tag.isEmpty {
                      Text(entry.tag)
                        .font(Self.tagFont)
                        .foregroundColor(self.color(severity: entry.severity))
                        .frame(maxWidth: 69, maxHeight: 10, alignment: .leading)
                    }
                    Spacer(minLength: 0)
                  }
                  .frame(maxWidth: 70, alignment: .leading)
                  .padding(.top, 1)
                } else if self.showTime {
                  VStack(alignment: .leading, spacing: 0.0) {
                    Text(entry.timeString)
                      .font(Self.timeFont)
                      .foregroundColor(self.color(severity: entry.severity))
                      .fixedSize(horizontal: false, vertical: false)
                      .frame(maxWidth: 50, alignment: .leading)
                    Spacer(minLength: 0)
                  }
                  .padding(.top, 1)
                } else {
                  VStack(alignment: .leading, spacing: 0.0) {
                    Text("•")
                      .font(self.font)
                      .foregroundColor(self.color(severity: entry.severity))
                    Spacer(minLength: 0)
                  }
                  .padding(.top, 1)
                }
                Text(entry.message)
                  .font(self.font)
              }
              .contextMenu {
                Button(action: {
                  UIPasteboard.general.setValue(entry.message,
                                                forPasteboardType: UTType.utf8PlainText.identifier)
                }) {
                  Label("Copy Message", systemImage: "doc.on.clipboard")
                }
                if entry.message.count <= 800 {
                  Button(action: {
                    self.input = entry.message
                  }) {
                    Label("Copy to Input", systemImage: "dock.arrow.down.rectangle")
                  }
                }
                Divider()
                Button(action: {
                  self.presentSheet(.shareText(entry.message))
                }) {
                  Label("Share Message", systemImage: "square.and.arrow.up")
                }
              }
              .padding(.leading, 6)
              .padding(.vertical, 1)
            }
          }
          .onChange(of: self.sessionLog.filteredLogEntries.count) { _ in
            if self.sessionLog.filteredLogEntries.count > 0 {
              withAnimation {
                scrollViewProxy.scrollTo(
                  self.sessionLog.filteredLogEntries[
                    self.sessionLog.filteredLogEntries.endIndex - 1].id,
                  anchor: .bottomTrailing)
              }
            }
          }
        }
      }
      .background(Color(.secondarySystemBackground)
                    .ignoresSafeArea(.container, edges: [.leading, .trailing]))
      VStack(alignment: .leading, spacing: 0) {
        Divider().offset(x: 0.0, y: -1.0)
          .ignoresSafeArea(.container, edges: [.leading, .trailing])
        HStack(alignment: .center, spacing: 0) {
          Text("Log:")
            .font(.footnote)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
          GeometryReader { geometry in
            Text(self.logFilterExplanation)
              .font(.footnote)
              .fixedSize(horizontal: false, vertical: false)
              .frame(maxWidth: geometry.size.width, maxHeight: 25, alignment: .leading)
          }
          .frame(maxHeight: 25, alignment: .center)
          Spacer(minLength: 0)
          CustomPopOver(showPopover: $showLogFilterPopOver,
                        popoverSize: CGSize(width: 280, height: 220)) {
            LogFilterView(showLogFilterPopOver: $showLogFilterPopOver,
                          minSeverityFilter: self.settings.logSeverityFilter,
                          logMessageFilter: self.settings.logMessageFilter,
                          filterMessage: self.settings.logFilterMessages,
                          filterTag: self.settings.logFilterTags)
              .environmentObject(self.settings)
              .environmentObject(self.sessionLog)
          } label: {
            Button(action: {
              self.showLogFilterPopOver = true
            }) {
              Image(systemName: "line.3.horizontal.decrease.circle")
                .font(LogView.iconFont)
                .padding(.horizontal, 4)
            }
          }
          Menu {
            Button(action: {
              self.showTime.toggle()
            }) {
              Label("Show Time", systemImage: self.showTime ? "checkmark.square" : "square")
            }
            Button(action: {
              self.showTags.toggle()
            }) {
              Label("Show Tag", systemImage: self.showTags ? "checkmark.square" : "square")
            }
            Divider()
            Button(action: {
              UIPasteboard.general.setValue(self.sessionLog.exportMessages(),
                                            forPasteboardType: UTType.utf8PlainText.identifier)
            }) {
              Label("Copy Messages", systemImage: "doc.on.clipboard")
            }
            Button(action: {
              self.presentSheet(.shareText(self.sessionLog.exportMessages()))
            }) {
              Label("Share Messages", systemImage: "square.and.arrow.up.on.square")
            }
            Button(action: {
              self.presentSheet(.shareText(self.sessionLog.export()))
            }) {
              Label("Share Log", systemImage: "square.and.arrow.up")
            }
            Divider()
            Button(action: {
              self.sessionLog.clear(all: true)
            }) {
              Label("Clear Log", systemImage: "trash")
            }
          } label: {
            Image(systemName: "ellipsis.circle")
              .font(LogView.iconFont)
              .padding(.horizontal, 8)
          }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .background(Color(.tertiarySystemBackground).opacity(0.85)
                      .ignoresSafeArea(.container, edges: [.leading, .trailing]))
        Divider()
          .ignoresSafeArea(.container, edges: [.leading, .trailing])
      }
    }
    .transition(.move(edge: .bottom))
  }
  
  private func presentSheet(_ action: InterpreterView.SheetAction) {
    if UIDevice.current.userInterfaceIdiom == .pad {
      self.showModal = action
    } else {
      self.showSheet = action
    }
  }
}
