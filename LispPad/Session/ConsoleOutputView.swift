//
//  ConsoleOutputView.swift
//  LispPad
//
//  Created by Matthias Zenger on 18/11/2023.
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
import LispKit

struct ConsoleOutputView: View {
  let entry: ConsoleOutput
  let font: SwiftUI.Font
  let graphicsBackground: SwiftUI.Color
  let width: CGFloat
  
  func errorText(image: String, text: String?) -> Text {
    return text == nil ? Text("") : Text("\n") +
                                    Text(Image(systemName: image)) +
                                    Text(" " + text!)
  }
  
  var body: some View {
    HStack(alignment: .top, spacing: 0) {
      if entry.kind == .command {
        Text("▶︎")
          .font(self.font)
          .frame(alignment: .topLeading)
          .padding(EdgeInsets(top: 3, leading: 4, bottom: 5, trailing: 3))
      } else if entry.isError {
        Text("⚠️")
          .font(self.font)
          .frame(alignment: .topLeading)
          .padding(.leading, 2)
      }
      switch entry.kind {
        case .empty:
          Divider().frame(width: 10, height: 1)
        case .drawingResult(_, let image):
          VStack(alignment: .leading, spacing: 2) {
            Text(entry.text)
              .font(self.font)
              .fontWeight(.regular)
              .foregroundColor(ConsoleView.resultColor)
              .frame(maxWidth: .infinity, alignment: .topLeading)
              .fixedSize(horizontal: false, vertical: true)
            Image(uiImage: image)
              .resizable()
              .frame(maxWidth: min(image.size.width, width * 0.98),
                     maxHeight: min(image.size.width, width * 0.98) /
                                image.size.width * image.size.height)
              .background(self.graphicsBackground)
              .padding(.vertical, 4)
          }
          .padding(.horizontal, 4)
        case .error(let context):
          (Text(entry.text).foregroundColor(.red) +
            self.errorText(image: "mappin.and.ellipse", text: context?.position) +
            self.errorText(image: "building.columns", text: context?.library) +
            self.errorText(image: "location", text: context?.stackTrace))
          .font(self.font)
          .fontWeight(.regular)
          .foregroundColor(.secondary)
          .frame(maxWidth: .infinity, alignment: .topLeading)
          .fixedSize(horizontal: false, vertical: true)
          .padding(.leading, 4)
        default:
          Text(entry.text)
            .font(self.font)
            .fontWeight(entry.kind == .info ? .bold : .regular)
            .foregroundColor(entry.kind == .result ? ConsoleView.resultColor :
                              (entry.kind == .output ? .secondary : .primary))
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 4)
            .padding(.vertical, entry.kind == .command ? 4 : (entry.kind == .output ? 1 : 0))
      }
    }
  }
}
