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
  @StateObject private var intrinsicContentSize = MutableSize()
  private let markdownText: Block?
  
  init(_ markdownText: Block?) {
    self.markdownText = markdownText
  }
  
  var body: some View {
    GeometryReader { geometry in
      MarkdownTextView(markdownText: self.markdownText,
                       maxLayoutWidth: geometry.size.width -
                                       geometry.safeAreaInsets.leading -
                                       geometry.safeAreaInsets.trailing,
                       intrinsicContentSize: self.intrinsicContentSize)
    }
    .frame(idealWidth: self.intrinsicContentSize.size?.width,
           idealHeight: self.intrinsicContentSize.size?.height)
    .fixedSize(horizontal: false, vertical: true)
  }
}

struct MarkdownTextView: UIViewRepresentable {
  private static let textFont = "system-ui, -apple-system, 'Helvetica Neue', Helvetica, sans-serif"
  private static let codeFont = "'SF Mono', SFMono-Regular, ui-monospace, Menlo, Consolas, monospace"
  private static let libraryFont = "system-ui, -apple-system, 'Helvetica Neue', Helvetica, sans-serif"

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
            return "<table style=\"border-bottom: 0.5px solid #ccc; margin-bottom: 3px;\" " +
                   "width=\"100%\"><tbody>" +
                   "<tr style=\"height: 15px; font-family: " + MarkdownTextView.libraryFont +
                   "; font-size: \(UserSettings.standard.documentationLibraryFontSize); font-style: italic;\">" +
                   "<td style=\"text-align: left;\">" + lib + "</td>" +
                   "<td style=\"text-align: right;\">" + type + "</td></tr></tbody></table><br/>\n"
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
  
  let markdownText: Block?
  let maxLayoutWidth: CGFloat
  let intrinsicContentSize: MutableSize
  
  func makeCoordinator() -> Coordinator {
    return Coordinator()
  }
  
  func makeUIView(context: Context) -> TextView {
    let view = TextView()
    view.textColor = .label
    view.backgroundColor = .clear
    view.textContainerInset = .zero
    view.isEditable = false
    view.isScrollEnabled = false
    view.isSelectable = true
    view.textContainer.lineFragmentPadding = 0
    view.textContainerInset = .zero
    view.delegate = context.coordinator
    return view
  }

  func updateUIView(_ uiView: TextView, context: Context) {
    if context.environment.scenePhase != .background {
      if uiView.attributedText.length == 0 ||
         context.coordinator.colorScheme != context.environment.colorScheme {
        context.coordinator.colorScheme = context.environment.colorScheme
        if let md = self.markdownText {
          DispatchQueue.main.async {
            uiView.attributedText =
              (context.coordinator.colorScheme == .dark ?
                DocumentationStringGenerator(
                  fontSize: UserSettings.standard.documentationTextFontSize,
                  fontFamily: MarkdownTextView.textFont,
                  fontColor: "#fff",
                  codeFontSize: UserSettings.standard.documentationCodeFontSize,
                  codeFontFamily: MarkdownTextView.codeFont,
                  codeFontColor: "#ccddff",
                  codeBlockFontSize: UserSettings.standard.documentationCodeFontSize,
                  codeBlockFontColor: "#aaddff",
                  codeBlockBackground: "#333",
                  borderColor: "#333",
                  blockquoteColor: "#fff",
                  h1Color: "#007aff",
                  h2Color: "#007aff",
                  h3Color: "#007aff",
                  h4Color: "#007aff") :
                DocumentationStringGenerator(
                  fontSize: UserSettings.standard.documentationTextFontSize,
                  fontFamily: MarkdownTextView.textFont,
                  fontColor: "#000",
                  codeFontSize: UserSettings.standard.documentationCodeFontSize,
                  codeFontFamily: MarkdownTextView.codeFont,
                  codeFontColor: "#0000aa",
                  codeBlockFontSize: UserSettings.standard.documentationCodeFontSize,
                  codeBlockFontColor: "#000099",
                  codeBlockBackground: "#eee",
                  borderColor: "#eee",
                  blockquoteColor: "#000",
                  h1Color: "#007aff",
                  h2Color: "#007aff",
                  h3Color: "#007aff",
                  h4Color: "#007aff")).generate(doc: md)
            self.intrinsicContentSize.size = uiView.intrinsicContentSize
          }
        } else {
          uiView.attributedText = NSAttributedString(string: "Content not available")
        }
      }
    }
    uiView.maxLayoutWidth = self.maxLayoutWidth
    uiView.textContainer.maximumNumberOfLines = context.environment.lineLimit ?? 0
    uiView.textContainer.lineBreakMode = .byWordWrapping
    context.coordinator.openURLProc = context.environment.openURL
    self.intrinsicContentSize.size = uiView.intrinsicContentSize
  }
}
