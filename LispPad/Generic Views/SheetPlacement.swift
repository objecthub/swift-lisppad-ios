//
//  SheetPlacement.swift
//  LispPad iOS
//
//  Created by Matthias Zenger on 28/10/2026.
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

import SwiftUI


enum SheetPlacement {
  case automatic
  case center
  case leading
  case trailing
}

extension View {
  /// Applies `presentationPlacement` on iOS 27+, no-op on earlier versions.
  @ViewBuilder
  func sheetPlacement(_ placement: SheetPlacement) -> some View {
    if #available(iOS 27, *) {
      switch placement {
        case .automatic:
          self.presentationPlacement(.automatic)
        case .center:
          self.presentationPlacement(.center)
        case .leading:
          self.presentationPlacement(.leading)
        case .trailing:
          self.presentationPlacement(.trailing)
      }
    } else {
      self
    }
  }
}
