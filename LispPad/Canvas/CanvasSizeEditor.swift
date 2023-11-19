//
//  CanvasSizeEditor.swift
//  LispPad
//
//  Created by Matthias Zenger on 15/11/2023.
//

import SwiftUI

struct CanvasSizeEditor: View {
  @Environment(\.dismiss) var dismiss
  @State var width: CGFloat
  @State var height: CGFloat
  @State var scale: CGFloat
  let update: (CGSize, CGFloat) -> Void
  
  init(width: CGFloat,
       height: CGFloat,
       scale: CGFloat,
       update: @escaping (CGSize, CGFloat) -> Void) {
    self._width = State(initialValue: width)
    self._height = State(initialValue: height)
    self._scale = State(initialValue: scale)
    self.update = update
  }
  
  let formatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.locale = Locale.current
    return formatter
  }()
  
  var body: some View {
    ZStack(alignment: .center) {
      Color(.systemGroupedBackground).ignoresSafeArea()
      VStack(alignment: .leading, spacing: 8) {
        HStack(alignment: .center, spacing: 8) {
          Text("Size:")
            .frame(width: 50, alignment: .trailing)
          TextField("Width", value: self.$width, formatter: formatter)
            .textFieldStyle(.roundedBorder)
            .multilineTextAlignment(.trailing)
            .frame(idealWidth: 45, maxWidth: 65)
            .keyboardType(.decimalPad)
          Text("⨉")
          TextField("Height", value: self.$height, formatter: formatter)
            .textFieldStyle(.roundedBorder)
            .multilineTextAlignment(.trailing)
            .frame(idealWidth: 45, maxWidth: 65)
            .keyboardType(.decimalPad)
          
        }
        HStack(alignment: .center, spacing: 8) {
          Text("Scale:")
            .multilineTextAlignment(.trailing)
            .frame(width: 50, alignment: .trailing)
          TextField("Scale", value: self.$scale, formatter: formatter)
            .textFieldStyle(.roundedBorder)
            .multilineTextAlignment(.trailing)
            .frame(idealWidth: 45, maxWidth: 65)
            .keyboardType(.decimalPad)
          Button {
            self.dismiss()
            self.update(CGSize(width: self.width, height: self.height), self.scale)
          } label: {
            Text("Done")
              .bold()
              .frame(width: 62, alignment: .trailing)
          }
          .padding(.horizontal, 12)
        }
      }
      
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}
