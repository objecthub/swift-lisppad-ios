//
//  IntField.swift
//  LispPad
//
//  Created by Matthias Zenger on 25/12/2022.
//  Copyright © 2022 Matthias Zenger. All rights reserved.
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
import SwiftUI
import Combine

struct IntField : View {
  @FocusState var isFocused: Bool
  @Binding var value: Int
  @State var initial: String
  @State var text: String = ""
  let min: Int
  let max: Int
  
  init(value: Binding<Int>, min: Int = 0, max: Int = Int.max) {
    self._value = value
    self.initial = String(value.wrappedValue)
    self.text = String(value.wrappedValue)
    self.min = min
    self.max = max
  }
  
  var body: some View {
    TextField(self.initial, text: $text)
      .multilineTextAlignment(.trailing)
      .submitLabel(.done)
      .focused($isFocused)
      .onReceive(Just(text)) { newValue in
        if newValue == initial {
          // keep things as they are
        } else if let x = Int(newValue), x >= self.min, x <= self.max {
          if x != value {
            value = x
            initial = String(x)
          }
        } else {
          let filtered = newValue.filter { $0.isNumber }
          if newValue != filtered {
            text = filtered
          }
        }
      }
      .onChange(of: isFocused) { newIsFocused in
        if !newIsFocused {
          if let x = Int(text), x >= self.min, x <= self.max {
           // keep things as they are 
          } else {
            self.text = self.initial
          }
        }
      }
      .onChange(of: value) { x in
        self.initial = String(x)
        self.text = String(x)
      }
  }
}
