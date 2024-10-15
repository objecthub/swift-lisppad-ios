//
//  MainView.swift
//  LispPad
//
//  Created by Matthias Zenger on 08/05/2021.
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
  
  /// Is this executing on an iPad?
  static let splitView = UIDevice.current.userInterfaceIdiom == .pad
  
  /// The current split view mode of the application. This state is persisted between
  /// application runs.
  @State private var splitViewMode: SideBySideMode = {
    let mode = SideBySideMode(rawValue:
                 UserDefaults.standard.integer(forKey: MainView.splitViewModeKey)) ?? .normal
    if MainView.splitView {
      return mode
    } else {
      switch mode {
        case .normal, .leftOnRight, .leftOnLeft:
          return .leftOnLeft
        case .swapped:
          return .rightOnLeft
        case .rightOnRight, .rightOnLeft:
          return .rightOnRight
      }
    }
  }()
  
  /// The current master width fraction (i.e. the width of the left-most view in a split
  /// view environment). This state is persisted between application runs.
  @State private var masterWidthFraction: CGFloat = {
    let fraction = UserDefaults.standard.double(forKey: MainView.splitViewWidthFractionKey)
    return fraction > 0.0 && fraction < 1.0 ? fraction : 0.5
  }()
  
  /// Used to position the cursor of the editor at the given location. This state variable
  /// will be reset once the cursor was positioned.
  @State private var editorPosition: NSRange? = nil
  
  @State private var editorFocused: Bool = true

  /// Setting this to `true` will force an editor update. The variable is automatically reset.
  @State private var forceEditorUpdate: Bool = false
  
  /// Support updating the editor and console text views
  @State private var updateEditor: ((CodeEditorTextView) -> Void)? = nil
  @State private var updateConsole: ((CodeEditorTextView) -> Void)? = nil
  
  /// All state powering the interpreter; it is initialized here to make sure that changes to
  /// the view tree do not result in interpreter state getting reset.
  @StateObject private var interpreterState = InterpreterState()
  
  /// View definition
  var body: some View {
    ZStack {
      Color("NavigationBarColor").ignoresSafeArea()
      SideBySide(
        mode: self.$splitViewMode,
        fraction: self.$masterWidthFraction,
        visibleThickness: 0.5,
        left: {
          NavigationStack {
            InterpreterView(splitView: MainView.splitView,
                            splitViewMode: self.$splitViewMode,
                            masterWidthFraction: self.$masterWidthFraction,
                            urlToOpen: self.$urlToOpen,
                            updateEditor: self.$updateEditor,
                            updateConsole: self.$updateConsole,
                            state: self.interpreterState)
          }
          .modifier(self.globals.services)
        },
        right: {
          NavigationStack {
            CodeEditorView(splitView: MainView.splitView,
                           splitViewMode: self.$splitViewMode,
                           masterWidthFraction: self.$masterWidthFraction,
                           urlToOpen: self.$urlToOpen,
                           editorPosition: self.$editorPosition,
                           editorFocused: self.$editorFocused,
                           forceEditorUpdate: self.$forceEditorUpdate,
                           updateEditor: self.$updateEditor,
                           updateConsole: self.$updateConsole)
          }
          .modifier(self.globals.services)
        }
      )
      .ignoresSafeArea()
      .onChange(of: self.splitViewMode) { mode in
        UserDefaults.standard.set(mode.rawValue, forKey: MainView.splitViewModeKey)
      }
      .onChange(of: self.masterWidthFraction) { fraction in
        UserDefaults.standard.set(fraction, forKey: MainView.splitViewWidthFractionKey)
      }
    }
  }
}
