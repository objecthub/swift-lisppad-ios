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
  @State private var textSize: CGSize? = nil
  private var intrinsicContentSize = MutableSize()
  private let mutableBlock = MutableBlock()
  private let rightPadding: Int
  
  init(_ markdownText: Block?, rightPadding: Int = 0) {
    self.rightPadding = rightPadding
    self.mutableBlock.block = markdownText
  }
  
  var body: some View {
    GeometryReader { geometry in
      MarkdownTextView(mutableBlock: self.mutableBlock,
                       maxLayoutWidth: geometry.size.width -
                                       geometry.safeAreaInsets.leading -
                                       geometry.safeAreaInsets.trailing,
                       intrinsicContentSize: self.intrinsicContentSize,
                       rightPadding: self.rightPadding)
    }
    .frame(idealWidth: self.textSize?.width, idealHeight: self.textSize?.height)
    .fixedSize(horizontal: false, vertical: true)
    .onReceive(self.intrinsicContentSize.$size) { size in
      self.textSize = size
    }
  }
}

struct MutableMarkdownText: View {
  @State private var textSize: CGSize? = nil
  @ObservedObject private var mutableBlock: MutableBlock
  private var intrinsicContentSize = MutableSize()
  private let rightPadding: Int
  
  init(_ mutableBlock: MutableBlock, rightPadding: Int = 0) {
    self.mutableBlock = mutableBlock
    self.rightPadding = rightPadding
  }
  
  var body: some View {
    GeometryReader { geometry in
      MarkdownTextView(mutableBlock: self.mutableBlock,
                       maxLayoutWidth: geometry.size.width -
                                       geometry.safeAreaInsets.leading -
                                       geometry.safeAreaInsets.trailing,
                       intrinsicContentSize: self.intrinsicContentSize,
                       rightPadding: self.rightPadding)
    }
    .frame(idealWidth: self.textSize?.width, idealHeight: self.textSize?.height)
    .fixedSize(horizontal: false, vertical: true)
    .onReceive(self.intrinsicContentSize.$size) { size in
      self.textSize = size
    }
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
    var version: Int = 0
    
    func textView(_ textView: UITextView,
                  primaryActionFor textItem: UITextItem,
                  defaultAction: UIAction) -> UIAction? {
      if case .link(let url) = textItem.content {
        return UIAction { _ in
          self.openURLProc?(url)
        }
      }
      return defaultAction
    }
  }
  
  private class DocumentationStringGenerator: AttributedStringGenerator   {
    static let localBaseUrl = Bundle.main.url(
                                  forResource: "thread-states",
                                  withExtension: "png",
                                  subdirectory: "Documentation/Libraries/images")?
                                .deletingLastPathComponent()
                                .deletingLastPathComponent()
    
    let rightPadding: Int
    
    init(fontColor: String,
         codeFontColor: String,
         codeBlockFontColor: String,
         codeBlockBackground: String,
         borderColor: String,
         blockquoteColor: String,
         h1Color: String,
         h2Color: String,
         h3Color: String,
         h4Color: String,
         rightPadding: Int,
         maxLayoutWidth: CGFloat) {
      self.rightPadding = rightPadding
      super.init(fontSize: UserSettings.standard.documentationTextFontSize,
                 fontFamily: MarkdownTextView.textFont,
                 fontColor: fontColor,
                 codeFontSize: UserSettings.standard.documentationCodeFontSize,
                 codeFontFamily: MarkdownTextView.codeFont,
                 codeFontColor: codeFontColor,
                 codeBlockFontSize: UserSettings.standard.documentationCodeFontSize,
                 codeBlockFontColor: codeBlockFontColor,
                 codeBlockBackground: codeBlockBackground,
                 borderColor: borderColor,
                 blockquoteColor: blockquoteColor,
                 h1Color: h1Color,
                 h2Color: h2Color,
                 h3Color: h3Color,
                 h4Color: h4Color,
                 maxImageWidth: "\(maxLayoutWidth)",
                 imageBaseUrl: Self.localBaseUrl)
    }
    
    private class DocumentationHtmlGenerator: InternalHtmlGenerator {
      let rightPadding: Int
      
      public override init(outer: AttributedStringGenerator) {
        self.rightPadding = (outer as! DocumentationStringGenerator).rightPadding
        super.init(outer: outer)
      }
      
      open override func generate(block: Block, parent: Parent, tight: Bool = false) -> String {
        switch block {
          case .heading(let n, let text):
            guard n == 6,
                  text.count == 2,
                  case .text(let lib) = text[0],
                  case .text(let type) = text[1] else {
              if n == 2 {
                return "<br/>\n" + super.generate(block: block, parent: parent, tight: tight)
              } else {
                return super.generate(block: block, parent: parent, tight: tight)
              }
            }
            return "<table style=\"border-bottom: 0.5px solid #ccc; margin-bottom: 3px;\" " +
                   "width=\"100%\"><tbody>" +
                   "<tr style=\"height: 15px; font-family: " + MarkdownTextView.libraryFont +
                   "; font-size: \(UserSettings.standard.documentationLibraryFontSize); " +
                   "font-style: italic;\">" +
                   "<td style=\"text-align: left;\">" + lib + "</td>" +
                   "<td style=\"text-align: right;padding-right: \(self.rightPadding)px;\">" +
                   type + "</td></tr></tbody></table><br/>\n"
          case .list(_, let tight, let blocks):
            if case .block(.listItem(_, _, _), _) = parent {
              return "<table style=\"font-size: \(UserSettings.standard.documentationTextFontSize)" +
                     "px; width: 100%;\"><tbody>\n" +
                     self.generate(blocks: blocks, parent: .block(block, parent), tight: tight) +
                     "</tbody></table>\n"
            } else {
              return "<table style=\"font-size: \(UserSettings.standard.documentationTextFontSize)" +
                     "px; width: 100%; margin-bottom: 5em;\"><tbody>\n" +
                     self.generate(blocks: blocks, parent: .block(block, parent), tight: tight) +
                     "</tbody></table><br/>\n"
            }
          case .listItem(.ordered(let n, let ch), _, let blocks):
            if tight, let text = blocks.text {
              return "<tr style=\"margin-left: 8px;vertical-align: top;\"><td style=\"width: 4.5em;text-align: right;\">\(n)\(ch)&nbsp;</td><td style=\"vertical-align: top;\"> " + self.generate(text: text) + "</td></tr>\n"
            } else {
              return "<tr style=\"margin-left: 8px;\"><td style=\"width: 4.5em;text-align: right;\">\(n)\(ch)&nbsp;</td><td style=\"vertical-align: top;\"> " +
                     self.generate(blocks: blocks, parent: .block(block, parent), tight: tight) +
                     "</td></tr>\n"
            }
          case .listItem(_, _, let blocks):
            if tight, let text = blocks.text {
              return "<tr style=\"margin-left: 8px;vertical-align: top;\"><td style=\"width: 2em;text-align: center\"><b>•</b></td><td style=\"vertical-align: top;\"> " + self.generate(text: text) + "</td></tr>\n"
            } else {
              return "<tr style=\"margin-left: 8px;\"><td style=\"width: 2em;text-align: center\"><b>•</b></td><td style=\"vertical-align: top;\"> " +
                     self.generate(blocks: blocks, parent: .block(block, parent), tight: tight) +
                     "</td></tr>\n"
            }
          default:
            return super.generate(block: block, parent: parent, tight: tight)
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
  
  @ObservedObject var mutableBlock: MutableBlock
  let maxLayoutWidth: CGFloat
  let intrinsicContentSize: MutableSize
  let rightPadding: Int
  
  func makeCoordinator() -> Coordinator {
    return Coordinator()
  }
  
  func makeUIView(context: Context) -> TextView {
    let view = TextView(usingTextLayoutManager: false)
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
         context.coordinator.colorScheme != context.environment.colorScheme ||
         context.coordinator.version != self.mutableBlock.version {
        context.coordinator.colorScheme = context.environment.colorScheme
        context.coordinator.version = self.mutableBlock.version
        if let md = self.mutableBlock.block {
          DispatchQueue.main.async {
            uiView.attributedText =
              (context.coordinator.colorScheme == .dark ?
                DocumentationStringGenerator(
                  fontColor: "#fff",
                  codeFontColor: "#ccddff",
                  codeBlockFontColor: "#aaddff",
                  codeBlockBackground: "#333",
                  borderColor: "#333",
                  blockquoteColor: "#fff",
                  h1Color: "#aa1111",
                  h2Color: "#007aff",
                  h3Color: "#007aff",
                  h4Color: "#007aff",
                  rightPadding: self.rightPadding,
                  maxLayoutWidth: self.maxLayoutWidth) :
                DocumentationStringGenerator(
                  fontColor: "#000",
                  codeFontColor: "#0000aa",
                  codeBlockFontColor: "#000099",
                  codeBlockBackground: "#eee",
                  borderColor: "#eee",
                  blockquoteColor: "#000",
                  h1Color: "#aa1111",
                  h2Color: "#007aff",
                  h3Color: "#007aff",
                  h4Color: "#007aff",
                  rightPadding: self.rightPadding,
                  maxLayoutWidth: self.maxLayoutWidth)).generate(doc: md)
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
