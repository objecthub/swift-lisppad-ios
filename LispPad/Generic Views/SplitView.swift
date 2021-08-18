//
//  SplitView.swift
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

import Foundation
import UIKit
import SwiftUI

enum SplitViewMode: Int {
  case normal = 0
  case swapped = 1
  case primaryOnly = 2
  case secondaryOnly = 3
}

struct SplitView<Master: View, Detail: View>: View {
  let viewControllers: [UIViewController]
  let master: Master
  let detail: Detail

  init(@ViewBuilder master: () -> Master,
       @ViewBuilder detail: () -> Detail) {
    let master = master()
    let detail = detail()
    self.viewControllers = [KeyboardEnabledHostingController(rootView: master),
                            KeyboardEnabledHostingController(rootView: detail)]
    self.master = master
    self.detail = detail
  }

  var body: some View {
    SplitViewController(viewControllers: self.viewControllers)
  }
}

struct SplitViewController: UIViewControllerRepresentable {
  @Environment(\.splitViewMasterWidthFraction) var masterWidthFraction: Double
  @Environment(\.splitViewMode) var mode: SplitViewMode
  var viewControllers: [UIViewController]

  func makeUIViewController(context: Context) -> SideBySideViewController {
    let sbsController = SideBySideViewController()
    sbsController.leftViewController = self.viewControllers[0]
    sbsController.rightViewController = self.viewControllers[1]
    return sbsController
  }

  func updateUIViewController(_ sbsController: SideBySideViewController, context: Context) {
    sbsController.preferredLeftColumnFraction = CGFloat(self.masterWidthFraction)
    switch self.mode {
      case .normal:
        sbsController.preferredDisplayMode = .sideBySide
        if sbsController.displayFocus == .right {
          sbsController.showLeftView(true)
        }
      case .swapped:
        sbsController.preferredDisplayMode = .sideBySide
        if sbsController.displayFocus == .left {
          sbsController.showRightView(true)
        }
      case .primaryOnly:
        sbsController.preferredDisplayMode = .one
        if sbsController.displayFocus == .right {
          sbsController.showLeftView(true)
        }
      case .secondaryOnly:
        sbsController.preferredDisplayMode = .one
        if sbsController.displayFocus == .left {
          sbsController.showRightView(true)
        }
    }
  }
}

struct MasterWidthFraction : EnvironmentKey {
  static var defaultValue: Double = 0.5
}

struct SplitViewModeKey : EnvironmentKey {
  static var defaultValue: SplitViewMode = .normal
}

extension EnvironmentValues {
  var splitViewMasterWidthFraction: Double {
    get {
      self[MasterWidthFraction.self]
    }
    set {
      self[MasterWidthFraction.self] = newValue
    }
  }

  var splitViewMode: SplitViewMode {
    get {
      self[SplitViewModeKey.self]
    }
    set {
      self[SplitViewModeKey.self] = newValue
    }
  }
}

extension View {
  func splitViewMasterWidthFraction(_ fraction: Double) -> some View {
    self.environment(\.splitViewMasterWidthFraction, fraction)
  }

  func splitViewMode(_ mode: SplitViewMode) -> some View {
    self.environment(\.splitViewMode, mode)
  }
}
