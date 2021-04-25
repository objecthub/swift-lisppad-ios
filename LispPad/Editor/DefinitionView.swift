//
//  DefinitionView.swift
//  LispPad
//
//  Created by Matthias Zenger on 05/04/2021.
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

struct DefinitionView: View {
  @Environment(\.presentationMode) var presentationMode
  let defitions: DefinitionMenu
  @Binding var position: NSRange?
  
  var body: some View {
    VStack(alignment: .center, spacing: 0) {
      HStack {
        Spacer()
        Button(action: {
          self.presentationMode.wrappedValue.dismiss()
        }) {
          Text("Cancel")
        }
      }
      .font(.body)
      .padding(.horizontal)
      .padding(.top)
      .edgesIgnoringSafeArea(.all)
      .background(Color(UIColor.secondarySystemBackground))
      Form {
        if self.defitions.values.count > 0 {
          Section(header: Text("Values")) {
            ForEach(self.defitions.values, id: \.1) { tuple in
              Button(action: { self.position = NSRange(location: tuple.1, length: 0)
                               self.presentationMode.wrappedValue.dismiss() }) {
                Text(tuple.0).font(.body)
              }
            }
          }
        }
        if self.defitions.syntax.count > 0 {
          Section(header: Text("Syntax")) {
            ForEach(self.defitions.syntax, id: \.1) { tuple in
              Button(action: { self.position = NSRange(location: tuple.1, length: 0)
                               self.presentationMode.wrappedValue.dismiss() }) {
                Text(tuple.0).font(.body)
              }
            }
          }
        }
        if self.defitions.records.count > 0 {
          Section(header: Text("Records")) {
            ForEach(self.defitions.records, id: \.1) { tuple in
              Button(action: { self.position = NSRange(location: tuple.1, length: 0)
                               self.presentationMode.wrappedValue.dismiss() }) {
                Text(tuple.0).font(.body)
              }
            }
          }
        }
        if self.defitions.types.count > 0 {
          Section(header: Text("Types")) {
            ForEach(self.defitions.types, id: \.1) { tuple in
              Button(action: { self.position = NSRange(location: tuple.1, length: 0)
                               self.presentationMode.wrappedValue.dismiss() }) {
                Text(tuple.0).font(.body)
              }
            }
          }
        }
      }
    }
  }
}

struct DefinitionView_Previews: PreviewProvider {
  @State static var position: NSRange? = nil
  static var previews: some View {
    DefinitionView(
      defitions: DefinitionMenu(values: [("One", 1),("Two", 2)],
                                syntax: [("Three", 3)],
                                records: [],
                                types: [("Four", 4), ("Five", 5), ("Six", 6)]),
      position: $position)
  }
}

