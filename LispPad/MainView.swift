//
//  MainView.swift
//  LispPad
//
//  Created by Matthias Zenger on 08/05/2021.
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

struct MainView: View {

  // There's a bug somewhere in SwiftUI which leads to some environment objects not being
  // passed through. Make this explicit for now where needed.
  @EnvironmentObject var docManager: DocumentationManager
  @EnvironmentObject var fileManager: FileManager
  @EnvironmentObject var interpreter: Interpreter
  @EnvironmentObject var histManager: HistoryManager
  @EnvironmentObject var settings: UserSettings

  // UserDefault keys
  static let splitViewModeKey = "SplitView.mode"
  static let splitViewWidthFractionKey = "SplitView.widthFraction"

  // Navigational state
  @State private var splitViewMode: SplitViewMode =
    SplitViewMode(rawValue: UserDefaults.standard.integer(forKey: MainView.splitViewModeKey)) ??
    .normal
  @State private var masterWidthFraction: Double = {
    let fraction = UserDefaults.standard.double(forKey: MainView.splitViewWidthFractionKey)
    return fraction > 0.0 && fraction < 1.0 ? fraction : 0.5
  }()

  // Editor state
  @State private var editorPosition: NSRange? = nil
  @State private var forceEditorUpdate: Bool = false

  var body: some View {
    if UIDevice.current.userInterfaceIdiom == .pad {
      GeometryReader { geo in
        SplitView {
            NavigationView {
              InterpreterView(splitView: true,
                              splitViewMode: $splitViewMode,
                              masterWidthFraction: $masterWidthFraction,
                              editorPosition: $editorPosition,
                              forceEditorUpdate: $forceEditorUpdate)
                .environmentObject(self.settings)
                .environmentObject(self.interpreter)
                .environmentObject(self.docManager)
                .environmentObject(self.histManager)
                .environmentObject(self.fileManager)
            }
            .navigationViewStyle(StackNavigationViewStyle())
        } detail: {
          NavigationView {
            CodeEditorView(splitView: true,
                           splitViewMode: $splitViewMode,
                           masterWidthFraction: $masterWidthFraction,
                           editorPosition: $editorPosition,
                           forceEditorUpdate: $forceEditorUpdate)
              .environmentObject(self.settings)
              .environmentObject(self.interpreter)
              .environmentObject(self.docManager)
              .environmentObject(self.histManager)
              .environmentObject(self.fileManager)
          }
          .navigationViewStyle(StackNavigationViewStyle())
        }
        .splitViewPreferredDisplayMode(.oneBesideSecondary)
        .splitViewMasterWidthFraction(self.masterWidthFraction)
        .splitViewMode(self.splitViewMode)
      }
      .onChange(of: self.splitViewMode) { mode in
        UserDefaults.standard.set(mode.rawValue, forKey: MainView.splitViewModeKey)
      }
      .onChange(of: self.masterWidthFraction) { fraction in
        UserDefaults.standard.set(fraction, forKey: MainView.splitViewWidthFractionKey)
      }
    } else {
      NavigationView {
        InterpreterView(splitView: false,
                        splitViewMode: $splitViewMode,
                        masterWidthFraction: $masterWidthFraction,
                        editorPosition: $editorPosition,
                        forceEditorUpdate: $forceEditorUpdate)
          .environmentObject(self.settings)
          .environmentObject(self.interpreter)
          .environmentObject(self.docManager)
          .environmentObject(self.histManager)
          .environmentObject(self.fileManager)
      }
      .navigationViewStyle(StackNavigationViewStyle())
    }
  }
}

struct MainView_Previews: PreviewProvider {
  static var previews: some View {
    MainView()
  }
}
