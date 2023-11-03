//
//  RTFTextView.swift
//  LispPad
//
//  Created by Matthias Zenger on 16/04/2021.
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

struct RTFTextView: View {
  let text: NSAttributedString

  init(_ fileUrl: URL?) {
    if let url = fileUrl,
       let astr = try? NSAttributedString(
                         url: url,
                         options: [.documentType: NSAttributedString.DocumentType.rtf],
                         documentAttributes: nil) {
      self.text = astr
    } else {
      self.text = NSAttributedString(string: "Text not found")
    }
  }

  var body: some View {
    ScrollSheet {
      RichText(self.text)
    }
  }
}
