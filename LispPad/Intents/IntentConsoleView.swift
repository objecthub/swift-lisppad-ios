//
//  IntentConsoleView.swift
//  LispPad
//
//  Created by Matthias Zenger on 21/04/2026.
//

import SwiftUI

struct IntentConsoleView: View {
  @ObservedObject var console: Console
  @State private var width: CGFloat = min(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
  let font: SwiftUI.Font = .system(size: 14, weight: .regular)
  
  func errorText(image: String, text: String?) -> Text {
    return text == nil ? Text("") : Text("\n") + Text(Image(systemName: image)) + Text(" " + text!)
  }
  
  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      ForEach(self.console.content, id: \.id) { entry in
        HStack(alignment: .top, spacing: 0) {
          if entry.kind == .command {
            Text("▶︎")
              .font(self.font)
              .frame(alignment: .topLeading)
              .padding(EdgeInsets(top: 3, leading: 8, bottom: 5, trailing: 0))
          } else if entry.isError {
            Text("⚠️")
              .font(self.font)
              .frame(alignment: .topLeading)
              .padding(.leading, 8)
          }
          switch entry.kind {
            case .empty:
              Divider().frame(width: 10, height: 1)
            case .drawingResult(_, let image):
              VStack(alignment: .leading, spacing: 2) {
                /* Text(entry.text)
                  .font(self.font)
                  .fontWeight(.regular)
                  .foregroundColor(ConsoleView.resultColor)
                  .frame(maxWidth: .infinity, alignment: .topLeading)
                  .fixedSize(horizontal: false, vertical: true) */
                Image(uiImage: image)
                  .resizable()
                  .frame(maxWidth: min(image.size.width, self.width * 0.98),
                         maxHeight: min(image.size.width, self.width * 0.98) /
                                    image.size.width * image.size.height)
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
              .padding(.horizontal, 8)
            default:
              Text(entry.text)
                .font(self.font)
                .fontWeight(entry.kind == .info ? .bold : .regular)
                .foregroundColor(entry.kind == .result ? ConsoleView.resultColor : .primary)
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
          }
        }
      }
    }
    .background(
      GeometryReader { proxy in
        Color.clear
          .onAppear {
            self.width = proxy.size.width
          }
          .onChange(of: proxy.size.width) { _, newWidth in
            self.width = newWidth
          }
      }
    )
  }
}
