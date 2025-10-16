//
//  LispPadApp.swift
//  LispPad
//
//  Created by Matthias Zenger on 14/03/2021.
//  Copyright © 2021-2023 Matthias Zenger. All rights reserved.
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
import LispKit

///
/// Entry point for LispPad app. Global services are defined and initialized in
/// `LispPadGlobals` and injected via a view modifier into the main view. This allows
/// services to depend on each other and be initialized in an environment independent
/// of SwiftUI.
///
@main struct LispPadApp: App {

  // Environment references
  @SwiftUI.Environment(\.scenePhase) private var scenePhase
  
  // Application-level state
  @StateObject private var globals = LispPadGlobals()
  @StateObject private var settings = UserSettings.standard
  @State private var urlToOpen: URL? = nil
  
  // Global UI setup
  init() {
    LispPadUI.configure()
  }
  
  // The scene powering the app
  var body: some Scene {
    WindowGroup {
      MainView(urlToOpen: $urlToOpen)
        .preferredColorScheme(self.settings.appearance.colorScheme)
        .environmentObject(KeyCommandHandler.empty)
        .environmentObject(self.globals)
        .onOpenURL { url in
          if url.scheme == "lisppad" && url.host == "oauth" {
            _ = HTTPOAuthLibrary.authRequestManager.redirect(url: url)
          } else {
            self.urlToOpen = url
          }
        }
    }
    .onChange(of: scenePhase) { oldValue, newValue in
      switch newValue {
        case .active:
          self.globals.histManager.setupFilePresenters()
        case .inactive:
          break
        case .background:
          if let doc = self.globals.fileManager.editorDocument, !doc.info.new {
            self.globals.histManager.trackRecentFile(doc.fileURL)
          }
          self.globals.histManager.suspendFilePresenters()
          self.globals.fileManager.editorDocument?.saveFile()
          self.globals.histManager.saveCommandHistory()
          self.globals.histManager.saveSearchHistory()
          self.globals.histManager.saveFilesHistory()
          self.globals.histManager.saveFavorites()
        default:
          break
      }
    }
  }
}
