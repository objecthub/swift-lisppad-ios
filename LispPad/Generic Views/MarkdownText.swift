//
//  MarkdownText.swift
//  LispPad
//
//  Created by Matthias Zenger on 26/03/2021.
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
import MarkdownKit

struct MarkdownText: View {
  @State var intrinsicContentSize: CGSize? = nil

  let markdownText: Block?
  
  init(_ markdownText: Block?) {
    self.markdownText = markdownText
  }
  
  var body: some View {
    GeometryReader { geometry in
      MarkdownTextView(
        markdownText: self.markdownText,
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

struct MarkdownTextView: UIViewRepresentable {
  
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
    var openURLProc: OpenURLAction? = nil
    var colorScheme: ColorScheme = .light
    func textView(_ view: UITextView,
                  shouldInteractWith url: URL,
                  in range: NSRange,
                  interaction ia: UITextItemInteraction) -> Bool {
      self.openURLProc?(url)
      return false
    }
  }
  
  private class DocumentationStringGenerator: AttributedStringGenerator   {
    private class DocumentationHtmlGenerator: InternalHtmlGenerator {
      open override func generate(block: Block, tight: Bool = false) -> String {
        switch block {
          case .heading(let n, let text):
            guard n == 6,
                  text.count == 2,
                  case .text(let lib) = text[0],
                  case .text(let type) = text[1] else {
              return super.generate(block: block, tight: tight)
            }
            return "<table style=\"border-bottom: 0.5px solid #bbb; margin-bottom: 3px;\"><tbody>" +
                   "<tr style=\"height: 15px; font-size: 11px;" +
                   "           font-style: italic;\"><td style=\"width: 70%; text-align: left;\">" +
                   lib + "</td><td style=\"width: 150px; text-align: right;\">" + type +
                   "</td></tr></tbody></table><br/>\n"
          default:
            return super.generate(block: block, tight: tight)
        }
      }
    }
    
    open override var htmlGenerator: HtmlGenerator {
      return DocumentationHtmlGenerator(outer: self)
    }
    
    open override var codeBoxStyle: String {
      return "background: \(self.codeBlockBackground);" +
             "width: 100%;" +
             "border: 1px solid \(self.borderColor);" +
             "padding: 0.3em;"
    }
  }
  
  private static let textFont = "\"Helvetica Neue\",Helvetica,sans-serif"
  private static let codeFont = "\"Menlo\",\"Consolas\",\"Courier New\",Courier,monospace"
  private static let textFontSize: Float = 13.0
  private static let codeFontSize: Float = 11.0
  
  private static let lightGen = DocumentationStringGenerator(
                                  fontSize: MarkdownTextView.textFontSize,
                                  fontFamily: MarkdownTextView.textFont,
                                  fontColor: "#000",
                                  codeFontSize: MarkdownTextView.codeFontSize,
                                  codeFontFamily: MarkdownTextView.codeFont,
                                  codeFontColor: "#0000aa",
                                  codeBlockFontSize: MarkdownTextView.codeFontSize,
                                  codeBlockFontColor: "#000099",
                                  codeBlockBackground: "#eee",
                                  borderColor: "#eee",
                                  blockquoteColor: "#000",
                                  h1Color: "#007aff",
                                  h2Color: "#007aff",
                                  h3Color: "#007aff",
                                  h4Color: "#007aff")
  
  private static let darkGen = DocumentationStringGenerator(
                                  fontSize: MarkdownTextView.textFontSize,
                                  fontFamily: MarkdownTextView.textFont,
                                  fontColor: "#fff",
                                  codeFontSize: MarkdownTextView.codeFontSize,
                                  codeFontFamily: MarkdownTextView.codeFont,
                                  codeFontColor: "#ccddff",
                                  codeBlockFontSize: MarkdownTextView.codeFontSize,
                                  codeBlockFontColor: "#aaddff",
                                  codeBlockBackground: "#333",
                                  borderColor: "#333",
                                  blockquoteColor: "#fff",
                                  h1Color: "#007aff",
                                  h2Color: "#007aff",
                                  h3Color: "#007aff",
                                  h4Color: "#007aff")
  
  let markdownText: Block?
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
    return view
  }

  func updateUIView(_ uiView: TextView, context: Context) {
    if context.environment.scenePhase != .background {
      if uiView.attributedText.length == 0 ||
         context.coordinator.colorScheme != context.environment.colorScheme {
        context.coordinator.colorScheme = context.environment.colorScheme
        if let md = self.markdownText {
          uiView.attributedText =
            (context.coordinator.colorScheme == .dark ? MarkdownTextView.darkGen :
                                                        MarkdownTextView.lightGen).generate(doc: md)
        } else {
          uiView.attributedText = NSAttributedString(string: "Content not available")
        }
      }
    }
    uiView.maxLayoutWidth = self.maxLayoutWidth
    uiView.textContainer.lineBreakMode = .byWordWrapping
    context.coordinator.openURLProc = context.environment.openURL
    DispatchQueue.main.async {
      self.intrinsicContentSize = uiView.intrinsicContentSize
    }
  }
}
