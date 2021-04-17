//
//  PreferencesView.swift
//  LispPad
//
//  Created by Matthias Zenger on 06/04/2021.
//

import SwiftUI

struct PreferencesView: View {
  @State var myColor: CGColor = CGColor(red: 0, green: 0, blue: 0, alpha: 0)
  
  var body: some View {
    Form {
      Text("Preferences")
      ColorPicker("Background color", selection: $myColor, supportsOpacity: false)
    }
    .navigationTitle("Preferences")
  }
}

struct PreferencesView_Previews: PreviewProvider {
  static var previews: some View {
    PreferencesView()
  }
}
