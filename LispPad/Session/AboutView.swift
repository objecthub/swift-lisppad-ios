//
//  AboutView.swift
//  LispPad
//
//  Created by Matthias Zenger on 16/04/2021.
//

import SwiftUI

struct AboutView: View {
  @Environment(\.presentationMode) var presentationMode
  
  static let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
  static let buildVersion = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
  static let creditsUrl = Bundle.main.url(forResource: "Credits", withExtension: "rtf")
  
  let aboutText: NSAttributedString = {
    if let url = AboutView.creditsUrl,
       let astr = try? NSAttributedString(url: url,
                                          options: [.documentType: NSAttributedString.DocumentType.rtf],
                                          documentAttributes: nil) {
      return astr
    }
    return NSAttributedString(string: "LispPad is based on the LispKit engine which provides a " +
                                      "R7RS-compliant Scheme implementation. LispKit comes with " +
                                      "a broad range of Scheme libraries, including standard " +
                                      "libraries defined via the Scheme Requests for " +
                                      "Implementation process (SRFI).")
  }()
  
  var body: some View {
    VStack(alignment: .center, spacing: 0) {
      HStack(alignment: .top, spacing: 0) {
        Spacer()
        Button(action: {
          self.presentationMode.wrappedValue.dismiss()
        }) {
          Text("Cancel")
            .padding(.trailing, 16)
        }
      }
      .offset(x: 0.0, y: -40.0)
      HStack(alignment: .center, spacing: 16) {
        Image("SmallLogo")
          .resizable()
          .scaledToFit()
          .frame(width: 100, height: 100)
        VStack(alignment: .leading, spacing: 4) {
          Text("LispPad")
            .font(.title2)
          (Text("Version ") +
           Text(AboutView.appVersion ?? "?") +
           Text(" (") + Text(AboutView.buildVersion ?? "?") + Text(")"))
            .font(.footnote)
        }
        .frame(width: 150, height: 100, alignment: .center)
        .padding(.leading, 8)
      }
      RichText(self.aboutText).padding(24)
    }
  }
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView()
    }
}
