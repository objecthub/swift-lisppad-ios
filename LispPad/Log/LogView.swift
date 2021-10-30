//
//  LogView.swift
//  LispPad
//
//  Created by Matthias Zenger on 27/10/2021.
//

import SwiftUI
import MobileCoreServices

struct LogView: View {
  static let timeFont = Font.system(size: 10.0, weight: .semibold, design: .monospaced)
  static let tagFont = Font.system(size: 9.0, weight: .regular, design: .monospaced)
  static let iconFont = Font.system(size: 20).weight(.light)
  let font: Font
  
  @EnvironmentObject var settings: UserSettings
  @EnvironmentObject var sessionLog: SessionLog
  @GestureState private var viewOffset: CGFloat = 0.0
  @AppStorage("Log.logShowTime") var showTime: Bool = true
  @AppStorage("Log.logShowTags") var showTags: Bool = false
  @State var showLogFilterPopOver: Bool = false
  @Binding var input: String
  @Binding var showSheet: InterpreterView.SheetAction?
  @Binding var showLog: Bool
  
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
                                                forPasteboardType: kUTTypePlainText as String)
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
                  self.showSheet = .shareText(entry.message)
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
                  anchor: .bottomLeading)
              }
            }
          }
        }
      }
      .background(Color(.secondarySystemBackground)
                    .ignoresSafeArea(.container, edges: [.leading, .trailing]))
      .offset(x: 0, y: self.viewOffset/pow(2, abs(self.viewOffset) / 800 + 1))
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
                                            forPasteboardType: kUTTypePlainText as String)
            }) {
              Label("Copy Messages", systemImage: "doc.on.clipboard")
            }
            Button(action: {
              self.showSheet = .shareText(self.sessionLog.exportMessages())
            }) {
              Label("Share Messages", systemImage: "square.and.arrow.up.on.square")
            }
            Button(action: {
              self.showSheet = .shareText(self.sessionLog.export())
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
      .offset(x: 0, y: self.viewOffset/pow(2, abs(self.viewOffset) / 800 + 1))
      .gesture(
        DragGesture()
          .updating($viewOffset) { value, state, transaction in
            state = value.translation.height
          }
          .onEnded() { value in
            if value.predictedEndTranslation.height > 200 {
              self.showLog = false
            }
          }
      )
    }
    .transition(.move(edge: .bottom))
  }
}
