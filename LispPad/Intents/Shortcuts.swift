//
//  Shortcuts.swift
//  LispPad
//
//  Created by Matthias Zenger on 20/03/2026.
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

import AppIntents

/// Defines App Shortcuts available in the Shortcuts app
struct Shortcuts: AppShortcutsProvider {
  
  static var appShortcuts: [AppShortcut] {
    AppShortcut(
      intent: RunProgram(),
      phrases: [
        "Run a \(.applicationName) program.",
        "Execute \(.applicationName) code."
      ],
      shortTitle: "Run Program",
      systemImageName: "chevron.left.slash.chevron.right"
    )
  }
  
  static var shortcutTileColor: ShortcutTileColor {
    .yellow
  }
}
