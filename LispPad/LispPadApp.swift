//
//  LispPadApp.swift
//  LispPad
//
//  Created by Matthias Zenger on 14/03/2021.
//  Copyright © 2021 Matthias Zenger. All rights reserved.
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

@main struct LispPadApp: App {
  
  // Environment references
  @Environment(\.scenePhase) private var scenePhase
  
  // Application-level state
  @StateObject private var interpreter = Interpreter()
  @StateObject private var docManager = DocumentationManager()
  @StateObject private var histManager = HistoryManager()
  @StateObject private var fileManager = FileManager()
  
  // The scene powering the app
  var body: some Scene {
    WindowGroup {
      InterpreterView()
        .environmentObject(self.interpreter)
        .environmentObject(self.docManager)
        .environmentObject(self.histManager)
        .environmentObject(self.fileManager)
    }
    .onChange(of: scenePhase, perform: { phase in
      switch phase {
        case .active:
          self.fileManager.histManager = self.histManager
        case .inactive:
          break
        case .background:
          self.fileManager.editorDocument?.saveFile()
          self.histManager.saveConsoleHistory()
          self.histManager.saveFilesHistory()
          self.histManager.saveFavorites()
        default:
          break
      }
    })
    
    /* Do not use a second scene yet
    DocumentGroup(newDocument: LispPadDocument()) { file in
      ContentView(document: file.$document)
    }
    */
  }
}
