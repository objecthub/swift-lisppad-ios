//
//  CodeEditorView.swift
//  LispPad
//
//  Created by Matthias Zenger on 28/03/2021.
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

struct CodeEditorView: View {
  @State var text: String = "This is a test"
  @State var showSearchField: Bool = false
  
  var body: some View {
    VStack {
      if self.showSearchField {
        SearchField(showCancel: $showSearchField) { str in
          return true
        }
        .font(.subheadline)
        Divider()
        Spacer(minLength: -8)
      }
      CodeEditor(text: $text,
                 onEditingChanged: {},
                 onCommit: {},
                 onTextChange: { str in })
        .defaultFont(.monospacedSystemFont(ofSize: 13, weight: .regular))
        .autocorrectionType(.no)
        .autocapitalizationType(.none)
        .multilineTextAlignment(.leading)
        .keyboardType(.default)
    }
    .navigationBarHidden(false)
    // .navigationBarTitle("Untitled.scm", displayMode: .inline)
    .navigationBarItems(
      trailing:
        HStack(alignment: .center, spacing: 16) {
            Button(action: {
              withAnimation(.default) {
                self.showSearchField = true
              }
            }) {
              Image(systemName: "magnifyingglass")
                .font(Font.system(size: InterpreterView.toolbarItemSize, weight: .light))
            }
            .disabled(self.showSearchField)
        })
  }
}

struct CodeEditorView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationView {
      CodeEditorView()
        .environmentObject(DocumentationManager())
    }
  }
}
