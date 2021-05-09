//
//  LispPadGlobals.swift
//  LispPad
//
//  Created by Matthias Zenger on 09/05/2021.
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

///
/// Registry of all global services. A singleton object of this class is created as a
/// state object in `LispPadApp`.
/// 
final class LispPadGlobals: ObservableObject {

  let settings = UserSettings.standard
  let histManager = HistoryManager()
  let fileManager = FileManager()
  let docManager = DocumentationManager()
  let interpreter = Interpreter()

  init() {
    self.fileManager.histManager = self.histManager
  }

  var services: Services {
    return Services(globals: self,
                    settings: self.settings,
                    histManager: self.histManager,
                    fileManager: self.fileManager,
                    docManager: self.docManager,
                    interpreter: self.interpreter)
  }

  struct Services: ViewModifier {
    let globals: LispPadGlobals
    let settings: UserSettings
    let histManager: HistoryManager
    let fileManager: FileManager
    let docManager: DocumentationManager
    let interpreter: Interpreter

    func body(content: Content) -> some View {
      content
        .accentColor(.blue)
        .environmentObject(self.globals)
        .environmentObject(self.settings)
        .environmentObject(self.histManager)
        .environmentObject(self.fileManager)
        .environmentObject(self.docManager)
        .environmentObject(self.interpreter)
    }
  }
}
