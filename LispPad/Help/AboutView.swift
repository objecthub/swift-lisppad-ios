//
//  AboutView.swift
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

struct AboutView: View {
  @Environment(\.presentationMode) var presentationMode
  
  static let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
  static let buildVersion = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
  static let copyright = Bundle.main.infoDictionary?["NSHumanReadableCopyright"] as? String
  static let creditsUrl = Bundle.main.url(forResource: "Credits", withExtension: "rtf")
  
  let aboutText: NSAttributedString = {
    if let url = AboutView.creditsUrl,
       let astr = try? NSAttributedString(
                         url: url,
                         options: [.documentType: NSAttributedString.DocumentType.rtf],
                         documentAttributes: nil) {
      return astr
    }
    return NSAttributedString(string: "")
  }()
  
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
      .padding()
      .edgesIgnoringSafeArea(.all)
      HStack(alignment: .center, spacing: 16) {
        Image("SmallLogo")
          .resizable()
          .scaledToFit()
          .frame(width: 100, height: 100)
        VStack(alignment: .leading, spacing: 4) {
          Text("LispPad")
            .font(.title2)
            .padding(.top, 12)
          (Text("Version ") +
           Text(AboutView.appVersion ?? "?") +
           Text(" (") + Text(AboutView.buildVersion ?? "?") + Text(")"))
            .font(.footnote)
          Text(AboutView.copyright ?? "Copyright © Matthias Zenger. All rights reserved.")
            .font(.caption)
            .padding(.top, 12)
        }
        .padding(.trailing, 20)
        .frame(width: 170, height: 110, alignment: .center)
        .padding(.leading, 8)
        .padding(.bottom, 16)
      }
      ScrollView {
        RichText(self.aboutText).padding(24)
      }
    }
  }
}

struct AboutView_Previews: PreviewProvider {
  static var previews: some View {
    AboutView()
  }
}
