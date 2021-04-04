//
//  ShareSheet.swift
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

import SwiftUI
import UIKit

struct ShareSheet: UIViewControllerRepresentable {
  typealias Callback = (_ activityType: UIActivity.ActivityType?,
                        _ completed: Bool,
                        _ returnedItems: [Any]?, _ error: Error?) -> Void
  
  let activityItems: [Any]
  let applicationActivities: [UIActivity]? = nil
  let excludedActivityTypes: [UIActivity.ActivityType]? = nil
  let callback: Callback? = nil
  
  func makeUIViewController(context: Context) -> UIActivityViewController {
    let controller = UIActivityViewController(activityItems: activityItems,
                                              applicationActivities: applicationActivities)
    controller.excludedActivityTypes = excludedActivityTypes
    controller.completionWithItemsHandler = callback
    return controller
  }
  
  func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
  }
}
