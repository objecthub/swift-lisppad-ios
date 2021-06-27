//
//  ResignKeyboard.swift
//  LispPad
//
//  Created by Matthias Zenger on 26/03/2021.
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

import Combine
import SwiftUI
import UIKit

extension UIApplication {
  func endEditing(_ force: Bool) {
    self.windows
        .filter{$0.isKeyWindow}
        .first?
        .endEditing(force)
  }
}

struct ResignKeyboardOnDragGesture: ViewModifier {
  let enable: Bool
  
  var dismissGesture: some Gesture {
    DragGesture(minimumDistance: 6.0, coordinateSpace: .local).onChanged { value in
      if (value.translation.height > 40.0 &&
          abs(value.translation.width) < value.translation.height * 0.6) ||
         (value.predictedEndTranslation.height > 100.0 &&
            abs(value.predictedEndTranslation.width) < value.predictedEndTranslation.height * 0.6) {
        UIApplication.shared.endEditing(true)
      }
    }
  }
  
  func body(content: Content) -> some View {
    if enable {
      content.gesture(dismissGesture)
    } else {
      content
    }
  }
}

extension View {
  func resignKeyboardOnDragGesture(enable: Bool = true) -> some View {
    return self.modifier(ResignKeyboardOnDragGesture(enable: enable))
  }
}

extension View {
  @ViewBuilder func hidden(_ shouldHide: Bool) -> some View {
    switch shouldHide {
      case true:
        self.hidden()
      case false:
        self
    }
  }
}

class KeyboardObserver: ObservableObject {
  @Published var rect: CGRect = .zero
  
  init() {
    self.listenForKeyboardNotifications()
  }
  
  private func listenForKeyboardNotifications() {
    NotificationCenter.default.addObserver(forName: UIResponder.keyboardDidShowNotification,
                                           object: nil,
                                           queue: .main) { notification in
      guard let userInfo = notification.userInfo,
            let keyboardRect = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else {
        return
      }
      self.rect = keyboardRect.cgRectValue
    }
    NotificationCenter.default.addObserver(forName: UIResponder.keyboardDidHideNotification,
                                           object: nil,
                                           queue: .main) { notification in
      self.rect = .zero
    }
  }
}
