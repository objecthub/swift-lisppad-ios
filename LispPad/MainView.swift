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
  
  /// Insights into the container LispPad is running in
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass
  @Environment(\.verticalSizeClass) private var verticalSizeClass
  
  /// The registry of all global services and the interpreter
  @EnvironmentObject private var globals: LispPadGlobals
  @EnvironmentObject private var interpreter: Interpreter
  
  /// URL of a file to load
  @Binding var urlToOpen: URL?
  
  // UserDefault keys
  private static let splitViewModeKey = "SplitView.mode"
  private static let singleViewModeKey = "SingleView.mode"
  private static let splitViewWidthFractionKey = "SplitView.widthFraction"
  
  /// A few UI-related global constants
  static let forceAllowSplit = UIDevice.current.userInterfaceIdiom == .pad
  static let disableVerticalToolbar = true
  
  /// The current split view mode of the application. This state is persisted between
  /// application runs.
  @State private var splitViewMode: SideBySideMode = {
    let mode = MainView.forceAllowSplit
             ? (SideBySideMode(rawValue:
                 UserDefaults.standard.integer(forKey: MainView.splitViewModeKey)) ?? .normal)
             : (SideBySideMode(rawValue:
                 UserDefaults.standard.integer(forKey: MainView.singleViewModeKey)) ?? .normal)
    if MainView.forceAllowSplit {
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
  
  /// True if the editor is in focus
  @State private var editorFocused: Bool = true

  /// Setting this to `true` will force an editor update. The variable is automatically reset.
  @State private var forceEditorUpdate: Bool = false
  
  /// Support updating the editor and console text views
  @State private var updateEditor: ((CodeEditorTextView) -> Void)? = nil
  @State private var updateConsole: ((CodeEditorTextView) -> Void)? = nil
  
  /// Navigation paths for the two navigation stacks
  @State private var interpreterPath = NavigationPath()
  @State private var editorPath = NavigationPath()
  
  /// All state powering the interpreter; it is initialized here to make sure that changes to
  /// the view tree do not result in interpreter state getting reset.
  @StateObject private var interpreterState = InterpreterState()
  
  /// All state powering the documentation browser; it is initialized here to make sure that
  /// changes to the view tree do not result in documentation browser state getting reset.
  @StateObject private var documentationBrowserState = DocumentationBrowserState()
  
  @State var containerGeometry: ContainerGeometry = .zero
  @State var allowSplit: Bool = MainView.forceAllowSplit
  @State var showAlert: Bool = false
  @State var datePickerValue: FlexDatePicker.Value = .single(nil)
  @State var choiceValue: String = ""
  @State var textValue: String = ""
  
  /// View definition
  var body: some View {
    SideBySide(
      mode: self.$splitViewMode,
      fraction: self.$masterWidthFraction,
      visibleThickness: 0.5,
      left: {
        ZStack {
          if self.documentationBrowserState.docShown {
            DocumentationBrowser(state: self.documentationBrowserState)
              .modifier(self.globals.services)
              .modifier(ToolbarVerticalBehaviorModifier(disallow: MainView.disableVerticalToolbar))
              .transition(.move(edge: .leading))
          } else {
            NavigationStack(path: self.$interpreterPath) {
              InterpreterView(allowSplit: self.allowSplit,
                              path: self.$interpreterPath,
                              splitViewMode: self.$splitViewMode,
                              masterWidthFraction: self.$masterWidthFraction,
                              urlToOpen: self.$urlToOpen,
                              updateEditor: self.$updateEditor,
                              updateConsole: self.$updateConsole,
                              docShown: $documentationBrowserState.docShown,
                              state: self.interpreterState)
            }
            .modifier(self.globals.services)
            .modifier(ToolbarVerticalBehaviorModifier(disallow: MainView.disableVerticalToolbar))
          }
        }
        .clipShape(.rect) // Without this, NavigationSplitView will extend beyond its borders
      },
      right: {
        NavigationStack(path: self.$editorPath) {
          CodeEditorView(allowSplit: self.allowSplit,
                         path: self.$editorPath,
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
        .modifier(ToolbarVerticalBehaviorModifier(disallow: MainView.disableVerticalToolbar))
      }
    )
    .ignoresSafeArea()
    .environment(\.containerGeometry, self.containerGeometry)
    .onGeometryChange(for: ContainerGeometry.self) { proxy in
      var regions: [CGRect] = []
      if #available(anyAppleOS 27.1, *) {
        let reserved = proxy.reservedRegions(kind: .occlusion, options: [])
        for region in reserved {
          let frame = region.frame
          // The reserved rect is the frame minus its margins.
          /* let reserved = CGRect(
            x: frame.minX + region.margins.leading,
            y: frame.minY + region.margins.top,
            width: max(frame.width - region.margins.leading - region.margins.trailing, 0),
            height: max(frame.height - region.margins.top - region.margins.bottom, 0)
          ) */
          regions.append(frame)
        }
      }
      return ContainerGeometry(size: proxy.size,
                               safeAreaInsets: proxy.safeAreaInsets,
                               reserved: regions)
    } action: { newGeometry in
      self.containerGeometry = newGeometry
      self.updateAllowSplit()
    }
    .plainFullScreenCover(isPresented: $showAlert) {
      self.alertView
    }
    .onChange(of: self.interpreter.alertConfig) { oldValue, newValue in
      switch newValue {
        case .none:
          break
        case .textInput(let config):
          self.showAlert = true
          self.textValue = config.initial
        case .choice(let config):
          self.showAlert = true
          self.choiceValue = config.selected ?? config.options.first ?? ""
        case .datePickerAlert(let config):
          self.showAlert = true
          self.datePickerValue = config.initial
      }
    }
    .onChange(of: self.allowSplit) { _, new in
      var transaction = Transaction(animation: .none)
      transaction.disablesAnimations = true
      if new {
        // Transition from split not allowed to allowed
        if UserSettings.standard.linkRotationFoldingChanges {
          let target = SideBySideMode(rawValue: UserDefaults.standard.integer(forKey:
                                                  MainView.splitViewModeKey)) ?? self.splitViewMode
          switch target {
            case .normal, .swapped:
              withTransaction(transaction) {
                self.splitViewMode = target
              }
            case .leftOnLeft, .rightOnRight:
              UserDefaults.standard.set(self.splitViewMode.rawValue,
                                        forKey: MainView.splitViewModeKey)
            case .leftOnRight, .rightOnLeft:
              switch self.splitViewMode {
                case .leftOnLeft:
                  withTransaction(transaction) {
                    self.splitViewMode = .leftOnRight
                  }
                case .rightOnRight:
                  withTransaction(transaction) {
                    self.splitViewMode = .rightOnLeft
                  }
                default:
                  break
              }
              UserDefaults.standard.set(self.splitViewMode.rawValue,
                                        forKey: MainView.splitViewModeKey)
          }
        } else {
          withTransaction(transaction) {
            self.splitViewMode = SideBySideMode(rawValue: UserDefaults.standard.integer(forKey: MainView.splitViewModeKey)) ?? self.splitViewMode
          }
        }
      } else {
        // Transition from split allowed to not allowed
        if UserSettings.standard.linkRotationFoldingChanges {
          if self.splitViewMode.isSideBySide {
            withTransaction(transaction) {
              self.splitViewMode = SideBySideMode(rawValue: UserDefaults.standard.integer(forKey: MainView.singleViewModeKey)) ?? .normal
            }
          } else {
            switch self.splitViewMode {
              case .normal, .swapped:
                withTransaction(transaction) {
                  self.splitViewMode = SideBySideMode(rawValue: UserDefaults.standard.integer(forKey: MainView.singleViewModeKey)) ?? .normal
                }
              case .leftOnLeft, .rightOnRight:
                UserDefaults.standard.set(self.splitViewMode.rawValue,
                                          forKey: MainView.singleViewModeKey)
              case .leftOnRight:
                withTransaction(transaction) {
                  self.splitViewMode = .leftOnLeft
                }
                UserDefaults.standard.set(self.splitViewMode.rawValue,
                                          forKey: MainView.singleViewModeKey)
              case .rightOnLeft:
                withTransaction(transaction) {
                  self.splitViewMode = .rightOnRight
                }
                UserDefaults.standard.set(self.splitViewMode.rawValue,
                                          forKey: MainView.singleViewModeKey)
            }
          }
        } else {
          withTransaction(transaction) {
            self.splitViewMode = SideBySideMode(rawValue: UserDefaults.standard.integer(forKey: MainView.singleViewModeKey)) ?? .normal
          }
        }
      }
    }
    .onChange(of: self.splitViewMode) { _, mode in
      if self.allowSplit {
        UserDefaults.standard.set(mode.rawValue, forKey: MainView.splitViewModeKey)
      } else {
        UserDefaults.standard.set(mode.rawValue, forKey: MainView.singleViewModeKey)
      }
    }
    .onChange(of: self.masterWidthFraction) { _, fraction in
      UserDefaults.standard.set(fraction, forKey: MainView.splitViewWidthFractionKey)
    }
  }
  
  private func updateAllowSplit() {
    let size = self.containerGeometry.containerSize
    self.allowSplit =
         (MainView.forceAllowSplit && size.width >= 750 && size.height >= 750)
      || (self.horizontalSizeClass == .regular && size.width >= 900)
      || (size.width >= 1000)
  }
  
  @ViewBuilder
  private var alertView: some View {
    switch self.interpreter.alertConfig {
      case .none:
        EmptyView()
      case .textInput(let alert):
        TextInputModal(
          title: alert.title,
          message: alert.message,
          placeholder: alert.placeholder,
          text: $textValue,
          cancelLabel: alert.cancel,
          confirmLabel: alert.confirm,
          onCancel: {
            self.showAlert = false
            self.interpreter.alertConfig = nil
            alert.onCancel()
          },
          onConfirm: {
            let result = self.textValue
            self.showAlert = false
            self.interpreter.alertConfig = nil
            alert.onConfirm(result)
          }
        )
      case .choice(let alert):
        ChoiceModal(
          title: alert.title,
          message: alert.message,
          options: alert.options,
          selection: $choiceValue,
          cancelLabel: alert.cancel,
          confirmLabel: alert.confirm,
          onCancel: {
            self.showAlert = false
            self.interpreter.alertConfig = nil
            alert.onCancel()
          },
          onConfirm: {
            let result = self.choiceValue
            self.showAlert = false
            self.interpreter.alertConfig = nil
            alert.onConfirm(result)
          }
        )
      case .datePickerAlert(let alert):
        DateInputModal(
          title: alert.title,
          message: alert.message,
          selection: $datePickerValue,
          bounds: alert.bounds,
          cancelLabel: alert.cancel,
          confirmLabel: alert.confirm,
          onCancel: {
            self.showAlert = false
            self.interpreter.alertConfig = nil
            alert.onCancel()
          },
          onConfirm: { (result: FlexDatePicker.Value) in
            self.showAlert = false
            self.interpreter.alertConfig = nil
            alert.onConfirm(result)
          }
        )
        .environment(\.timeZone, alert.timezone)
    }
  }
}

/// Helper ViewModifier to conditionally apply toolbarVerticalBehavior on iOS 27.1+
private struct ToolbarVerticalBehaviorModifier: ViewModifier {
  let disallow: Bool
  
  func body(content: Content) -> some View {
    if self.disallow {
      if #available(iOS 27.1, *) {
        content.toolbarVerticalBehavior(.disabled)
      } else {
        content
      }
    } else {
      content
    }
  }
}
