//
//  MutableSize.swift
//  LispPad
//
//  Created by Matthias Zenger on 11/05/2021.
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

///
/// This is just a small helper class to implement propagation of information
/// from custom SwiftUI-wrapped UIKit widgets.
///
import SwiftUI
import MarkdownKit

final class MutableSize: ObservableObject {
  @Published var size: CGSize? = nil
}

final class MutableBlock: ObservableObject {
  @Published private(set) var version: Int = 0
  var block: Block? = nil {
    didSet {
      self.version = self.version &+ 1
    }
  }
}
