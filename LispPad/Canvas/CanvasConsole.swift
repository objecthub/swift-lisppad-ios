//
//  CanvasConsole.swift
//  LispPad
//
//  Created by Matthias Zenger on 18/11/2023.
//  Copyright © 2023 Matthias Zenger. All rights reserved.
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

struct CanvasConsole: View {
  @EnvironmentObject var settings: UserSettings
  @ObservedObject var console: Console
  
  var body: some View {
    if let entry = console.content.last, entry.isResult {
      VStack(alignment: .leading, spacing: 0.0) {
        Divider()
          .ignoresSafeArea(.container, edges: [.leading, .trailing])
        ConsoleOutputView(entry: entry.textOutput,
                          font: self.settings.consoleFont,
                          graphicsBackground: self.settings.consoleGraphicsBackgroundColor,
                          width: 0)
        .allowsTightening(true)
        .lineLimit(8)
        .padding(.vertical, 8)
        .background(Color(.tertiarySystemBackground).opacity(0.85)
                      .ignoresSafeArea(.container, edges: [.leading, .trailing]))
        Divider()
          .ignoresSafeArea(.container, edges: [.leading, .trailing])
      }
    }
  }
}
