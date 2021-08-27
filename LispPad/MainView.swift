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

///
/// This struct defines the root view of LispPad.
///
struct MainView: View {

  /// The registry of all global services
  @EnvironmentObject var globals: LispPadGlobals

  /// URL of a file to load
  @Binding var urlToOpen: URL?
  
  // UserDefault keys
  static let splitViewModeKey = "SplitView.mode"
  static let splitViewWidthFractionKey = "SplitView.widthFraction"

  /// The current split view mode of the application. This state is persisted between
  /// application runs.
  @State private var splitViewMode: SplitViewMode =
    SplitViewMode(rawValue: UserDefaults.standard.integer(forKey: MainView.splitViewModeKey)) ??
    .normal

  /// The current master width fraction (i.e. the width of the left-most view in a split
  /// view environment). This state is persisted between application runs.
  @State private var masterWidthFraction: Double = {
    let fraction = UserDefaults.standard.double(forKey: MainView.splitViewWidthFractionKey)
    return fraction > 0.0 && fraction < 1.0 ? fraction : 0.5
  }()
  
  /// Used to position the cursor of the editor at the given location. This state variable
  /// will be reset once the cursor was positioned.
  @State private var editorPosition: NSRange? = nil

  /// Setting this to `true` will force an editor update. The variable is automatically reset.
  @State private var forceEditorUpdate: Bool = false
  
  /// The definition of the view.
  var body: some View {
    if self.splitView {
      ZStack {
        Color("NavigationBarColor").ignoresSafeArea()
        SplitView {
          NavigationView {
            InterpreterView(splitView: true,
                            splitViewMode: $splitViewMode,
                            masterWidthFraction: $masterWidthFraction,
                            urlToOpen: $urlToOpen,
                            editorPosition: $editorPosition,
                            forceEditorUpdate: $forceEditorUpdate)
          }
          .navigationViewStyle(StackNavigationViewStyle())
          .modifier(self.globals.services)
        } detail: {
          NavigationView {
            CodeEditorView(splitView: true,
                           splitViewMode: $splitViewMode,
                           masterWidthFraction: $masterWidthFraction,
                           urlToOpen: $urlToOpen,
                           editorPosition: $editorPosition,
                           forceEditorUpdate: $forceEditorUpdate)
          }
          .navigationViewStyle(StackNavigationViewStyle())
          .modifier(self.globals.services)
        }
        .splitViewMasterWidthFraction(self.masterWidthFraction)
        .splitViewMode(self.splitViewMode)
        .onChange(of: self.splitViewMode) { mode in
          UserDefaults.standard.set(mode.rawValue, forKey: MainView.splitViewModeKey)
        }
        .onChange(of: self.masterWidthFraction) { fraction in
          UserDefaults.standard.set(fraction, forKey: MainView.splitViewWidthFractionKey)
        }
      }
    } else {
      NavigationView {
        InterpreterView(splitView: false,
                        splitViewMode: $splitViewMode,
                        masterWidthFraction: $masterWidthFraction,
                        urlToOpen: $urlToOpen,
                        editorPosition: $editorPosition,
                        forceEditorUpdate: $forceEditorUpdate)
      }
      .navigationViewStyle(StackNavigationViewStyle())
      .modifier(self.globals.services)
    }
  }
  
  private var splitView: Bool {
    return UIDevice.current.userInterfaceIdiom == .pad
  }
}
