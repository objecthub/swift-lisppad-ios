//
//  RichText.swift
//  LispPad
//
//  Created by Matthias Zenger on 20/03/2021.
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

struct RichText: View {
  @State var intrinsicContentSize: CGSize? = nil

  private let text: NSAttributedString
  private let interpretAttributes: Bool
  
  public init(_ text: String) {
    self.text = NSAttributedString(string: text)
    self.interpretAttributes = true
  }
  
  public init(_ text: String,
              attributes: [NSAttributedString.Key : Any]? = nil) {
    self.text = NSAttributedString(string: text, attributes: attributes)
    self.interpretAttributes = false
  }
  
  public init(_ text: NSAttributedString) {
    self.text = text
    self.interpretAttributes = false
  }

  var body: some View {
    GeometryReader { geometry in
      AttributedText(
        text: text,
        interpretAttributes: self.interpretAttributes,
        maxLayoutWidth: geometry.size.width -
                        geometry.safeAreaInsets.leading -
                        geometry.safeAreaInsets.trailing,
        intrinsicContentSize: $intrinsicContentSize
      )
    }
    .frame(idealWidth: self.intrinsicContentSize?.width,
           idealHeight: self.intrinsicContentSize?.height)
    .fixedSize(horizontal: false, vertical: true)
  }
}

struct AttributedText: UIViewRepresentable {
  
  final class TextView: UITextView {
    var maxLayoutWidth: CGFloat = 0 {
      didSet {
        if self.maxLayoutWidth != oldValue {
          self.invalidateIntrinsicContentSize()
        }
      }
    }
    
    override var intrinsicContentSize: CGSize {
      if self.maxLayoutWidth > 0 {
        return self.sizeThatFits(CGSize(width: maxLayoutWidth, height: .greatestFiniteMagnitude))
      } else {
        return super.intrinsicContentSize
      }
    }
  }
  
  final class Coordinator: NSObject, UITextViewDelegate {
    var openURLProc: OpenURLAction?

    func textView(_ view: UITextView,
                  shouldInteractWith url: URL,
                  in range: NSRange,
                  interaction ia: UITextItemInteraction) -> Bool {
      self.openURLProc?(url)
      return false
    }
  }
  
  let text: NSAttributedString
  let interpretAttributes: Bool
  let maxLayoutWidth: CGFloat
  @Binding var intrinsicContentSize: CGSize?

  func makeCoordinator() -> Coordinator {
    return Coordinator()
  }
  
  func makeUIView(context: Context) -> TextView {
    let view = TextView()
    view.delegate = context.coordinator
    view.textColor = .label
    view.backgroundColor = .clear
    view.textContainerInset = .zero
    view.isEditable = false
    view.isScrollEnabled = false
    view.isSelectable = true
    view.textContainer.lineFragmentPadding = 0
    view.textContainerInset = .zero
    // view.textContainer.maximumNumberOfLines = context.environment.lineLimit ?? 0
    return view
  }

  func updateUIView(_ uiView: TextView, context: Context) {
    uiView.attributedText = self.text
    uiView.maxLayoutWidth = self.maxLayoutWidth
    if self.interpretAttributes, let font = context.environment.font {
      uiView.font = self.preferredFont(from: font)
    }
    if self.interpretAttributes {
      uiView.textContainer.lineBreakMode =
        self.preferredTruncationMode(from: context.environment.truncationMode)
    } else {
      uiView.textContainer.lineBreakMode = .byWordWrapping
    }
    // uiView.contentScaleFactor = context.environment.displayScale
    // uiView.textContainer.maximumNumberOfLines = context.environment.lineLimit ?? 0
    context.coordinator.openURLProc = context.environment.openURL
    DispatchQueue.main.async {
      self.intrinsicContentSize = uiView.intrinsicContentSize
    }
  }
  
  func preferredTruncationMode(from mode: Text.TruncationMode) -> NSLineBreakMode {
    switch mode {
      case .middle:
         return .byTruncatingMiddle
      case .head:
        return .byTruncatingHead
      case .tail:
        return .byTruncatingTail
      @unknown default:
        return .byWordWrapping
    }
  }
  
  func preferredFont(from font: Font) -> UIFont {
    switch font {
      case .largeTitle:
        return UIFont.preferredFont(forTextStyle: .largeTitle)
      case .title:
        return UIFont.preferredFont(forTextStyle: .title1)
      case .title2:
        return UIFont.preferredFont(forTextStyle: .title2)
      case .title3:
        return UIFont.preferredFont(forTextStyle: .title3)
      case .headline:
        return UIFont.preferredFont(forTextStyle: .headline)
      case .subheadline:
        return UIFont.preferredFont(forTextStyle: .subheadline)
      case .callout:
        return UIFont.preferredFont(forTextStyle: .callout)
      case .caption:
        return UIFont.preferredFont(forTextStyle: .caption1)
      case .caption2:
        return UIFont.preferredFont(forTextStyle: .caption2)
      case .footnote:
        return UIFont.preferredFont(forTextStyle: .footnote)
      case .body:
        return UIFont.preferredFont(forTextStyle: .body)
      default:
        return UIFont.preferredFont(forTextStyle: .body)
    }
  }
}

struct AttributedText_Previews: PreviewProvider {
  static var previews: some View {
    RichText(NSAttributedString(string: "Hello World!\nWelcome!\nAnd one more..."))
      .font(.body)
      .border(Color.black, width: 1)
      .padding()
  }
}
