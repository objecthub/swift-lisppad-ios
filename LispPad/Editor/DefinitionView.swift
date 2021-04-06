//
//  DefinitionView.swift
//  LispPad
//
//  Created by Matthias Zenger on 05/04/2021.
//

import SwiftUI

struct DefinitionView: View {
  @Environment(\.presentationMode) var presentationMode
  let defitions: DefinitionMenu
  @Binding var position: NSRange?
  
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
      .padding(.horizontal)
      .padding(.top)
      .edgesIgnoringSafeArea(.all)
      .background(Color(UIColor.secondarySystemBackground))
      Form {
        if self.defitions.values.count > 0 {
          Section(header: Text("Values")) {
            ForEach(self.defitions.values, id: \.1) { tuple in
              Button(action: { self.position = NSRange(location: tuple.1, length: 0)
                               self.presentationMode.wrappedValue.dismiss() }) {
                Text(tuple.0).font(.callout)
              }
            }
          }
        }
        if self.defitions.syntax.count > 0 {
          Section(header: Text("Syntax")) {
            ForEach(self.defitions.syntax, id: \.1) { tuple in
              Button(action: { self.position = NSRange(location: tuple.1, length: 0)
                               self.presentationMode.wrappedValue.dismiss() }) {
                Text(tuple.0).font(.callout)
              }
            }
          }
        }
        if self.defitions.records.count > 0 {
          Section(header: Text("Records")) {
            ForEach(self.defitions.records, id: \.1) { tuple in
              Button(action: { self.position = NSRange(location: tuple.1, length: 0)
                               self.presentationMode.wrappedValue.dismiss() }) {
                Text(tuple.0).font(.callout)
              }
            }
          }
        }
        if self.defitions.types.count > 0 {
          Section(header: Text("Types")) {
            ForEach(self.defitions.types, id: \.1) { tuple in
              Button(action: { self.position = NSRange(location: tuple.1, length: 0)
                               self.presentationMode.wrappedValue.dismiss() }) {
                Text(tuple.0).font(.callout)
              }
            }
          }
        }
      }
    }
  }
}

struct DefinitionView_Previews: PreviewProvider {
  @State static var position: NSRange? = nil
  static var previews: some View {
    DefinitionView(
      defitions: DefinitionMenu(values: [("One", 1),("Two", 2)],
                                syntax: [("Three", 3)],
                                records: [],
                                types: [("Four", 4), ("Five", 5), ("Six", 6)]),
      position: $position)
  }
}

