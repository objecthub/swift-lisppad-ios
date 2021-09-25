//
//  DocumentView.swift
//  LispPad
//
//  Created by Matthias Zenger on 10/04/2021.
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

struct DocumentView: View {
  let title: String
  let url: URL
  
  var body: some View {
    Sheet(backgroundColor: Color(.secondarySystemBackground)) {
      GeometryReader { geometry in
        VStack {
          PDFViewer(url: self.url, viewSize: geometry.size)
              .navigationTitle(self.title)
              .navigationBarHidden(false)
        }
      }
    }
  }
}

struct DocumentView_Previews: PreviewProvider {
  static var baseUrl = Bundle.main.url(forResource: "lisppad_ref",
                                       withExtension: "pdf",
                                       subdirectory: "Documentation/Documents")!
  static var previews: some View {
      DocumentView(title: "Library Reference",
                   url: Self.baseUrl)
  }
}
