//
//  EnvironmentView.swift
//  LispPad
//
//  Created by Matthias Zenger on 19/03/2021.
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
import LispKit

struct EnvironmentView: View {
  @EnvironmentObject var docManager: DocumentationManager
  @ObservedObject var envManager: EnvironmentManager
  @State var searchText: String = ""
  @State var showLispPadRef: Bool = false
  
  var body: some View {
    List {
      ForEach(self.envManager.bindings.filter { symbol in
        self.searchText.isEmpty ||
        symbol.identifier.range(of: self.searchText, options: .caseInsensitive) != nil
      }, id: \.self) { symbol in
        NavigationLink(value: symbol) {
          Text(symbol.description)
            .font(.body)
        }
        .disabled(!self.docManager.hasDocumentation(for: symbol.identifier))
      }
    }
    .listStyle(.plain)
    .searchable(text: $searchText)
    .resignKeyboardOnDragGesture()
    .navigationBarTitleDisplayMode(.inline)
    .navigationTitle("Environment")
    .navigationBarBackButtonHidden(false)
    .toolbar {
      ToolbarItemGroup(placement: .navigationBarTrailing) {
        HStack(alignment: .center, spacing: LispPadUI.toolbarSeparator) {
          Button(action: {
            self.showLispPadRef = self.docManager.lispPadRef.url != nil
          }) {
            Image(systemName: "info.circle")
              .font(LispPadUI.toolbarFont)
          }
        }
      }
    }
    .fullScreenCover(isPresented: $showLispPadRef) {
      DocumentView(title: docManager.lispPadRef.name, url: docManager.lispPadRef.url!)
    }
    .navigationDestination(for: Symbol.self) { symbol in
      EnvironmentDetailView(symbol: symbol)
    }
  }
}
