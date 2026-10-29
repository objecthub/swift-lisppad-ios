//
//  FileManagerView.swift
//  LispPad iOS
//
//  Created by Matthias Zenger on 29/10/2026.
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

struct FileManagerView: View {
  @Environment(\.dismiss) private var dismiss
  
  var body: some View {
    Organizer(closeButton: false)
      .navigationTitle("File Manager")
      .navigationBarTitleDisplayMode(.inline)
      .navigationBarBackButtonHidden(false)
  }
}
