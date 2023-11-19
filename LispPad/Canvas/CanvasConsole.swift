//
//  CanvasConsole.swift
//  LispPad
//
//  Created by Matthias Zenger on 18/11/2023.
//

import SwiftUI

struct CanvasConsole: View {
  private static let insets = EdgeInsets(top: 6, leading: 2, bottom: 6, trailing: 2)
  @EnvironmentObject var settings: UserSettings
  @ObservedObject var console: Console
  
  var body: some View {
    if let entry = console.content.last, entry.isResult {
      VStack(alignment: .center, spacing: 0) {
        Divider()
        ConsoleOutputView(entry: entry.textOutput,
                          font: self.settings.consoleFont,
                          graphicsBackground: self.settings.consoleGraphicsBackgroundColor,
                          width: 0)
        .allowsTightening(true)
        .lineLimit(8)
        .padding(CanvasConsole.insets)
        .background(Color(.tertiarySystemBackground).opacity(0.85))
        .animation(.snappy, value: console.content.last)
      }
    }
  }
}
