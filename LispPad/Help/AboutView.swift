//
//  AboutView.swift
//  LispPad
//
//  Created by Matthias Zenger on 16/04/2021.
//  Copyright © 2021-2023 Matthias Zenger. All rights reserved.
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
  static let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
  static let buildVersion = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
  static let copyright = Bundle.main.infoDictionary?["NSHumanReadableCopyright"] as? String
  static let creditsUrl = Bundle.main.url(forResource: "Credits", withExtension: "rtf")

  let aboutText: NSAttributedString = {
    if let url = AboutView.creditsUrl,
       let astr = try? NSMutableAttributedString(
                         url: url,
                         options: [.documentType: NSAttributedString.DocumentType.rtf],
                         documentAttributes: nil) {
      astr.addAttribute(.foregroundColor,
                        value: UIColor.secondaryLabel,
                        range: NSRange(location: 0, length: astr.length))
      return astr
    }
    return NSAttributedString(string: "")
  }()

  var body: some View {
    Sheet(backgroundColor: Color(.tertiarySystemBackground)) {
      ZStack(alignment: .top) {
        ScrollView(.vertical, showsIndicators: false) {
          RichText(self.aboutText)
            .padding(.horizontal, 24)
            .padding(.top, 170)
        }
        HStack(alignment: .center, spacing: 16) {
          Image("SmallLogo")
            .resizable()
            .scaledToFit()
            .frame(width: 100, height: 100)
          VStack(alignment: .leading, spacing: 4) {
            Text("LispPad")
              .font(.system(size: 21, weight: .bold))
              .padding(.top, 12)
            (Text("Version ") +
             Text(AboutView.appVersion ?? "?") +
             Text(" (") + Text(AboutView.buildVersion ?? "?") + Text(")"))
            .font(.system(size: 12.5))
            Text(AboutView.copyright ?? "Copyright © Matthias Zenger. All rights reserved.")
              .font(.system(size: 11.5))
              .padding(.top, 12)
          }
          .padding(.trailing, 15)
          .padding(.bottom, 18)
          .frame(width: 190, height: 130, alignment: .center)
          .padding(.leading, 8)
        }
        .padding(.top, 32)
        .frame(maxWidth: .infinity)
        .background(Color(.tertiarySystemBackground).opacity(0.85))
      }.transition(.identity)
    }
  }
}

struct AboutView_Previews: PreviewProvider {
  static var previews: some View {
    AboutView()
  }
}
