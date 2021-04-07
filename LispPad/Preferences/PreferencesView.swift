//
//  PreferencesView.swift
//  LispPad
//
//  Created by Matthias Zenger on 06/04/2021.
//

import SwiftUI

struct PreferencesView: View {
  var body: some View {
    Form {
      Text("Preferences")
    }
    .navigationTitle("Preferences")
  }
}

struct PreferencesView_Previews: PreviewProvider {
  static var previews: some View {
    PreferencesView()
  }
}
