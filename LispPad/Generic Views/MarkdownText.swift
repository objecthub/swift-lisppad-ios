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
import class LispKit.MarkdownLibrary


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

  /// A text view which puts the markers of list items on the baseline of the first line of
  /// their items after each layout: the first line depends on the width of the text.
  final class TextView: UITextView {
    
    /// The markers of lists in the text. The layout of a text view is only touched if there are
    /// any (using its layout manager makes it use TextKit 1, as lists need anyway).
    var pairs: [ListMarkers.Pair] = []
    
    /// Set to true while markers are being adjusted.
    private var isAligning = false
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
      super.init(frame: frame, textContainer: textContainer)
    }

    required init?(coder: NSCoder) {
      super.init(coder: coder)
    }

    /// Creates a text view with a TextKit 1 text system, which is needed for aligning list
    /// markers. Do not use `init(usingTextLayoutManager: false)` for this: it initializes the
    /// view without calling the designated initializer of this class. The stored properties
    /// above (e.g. `pairs`) stay zeroed and `layoutSubviews` crashes when reading them.
    static func makeTextKit1() -> TextView {
      let container = NSTextContainer(size: CGSize(width: 0,
                                                   height: CGFloat.greatestFiniteMagnitude))
      container.widthTracksTextView = true
      let layoutManager = NSLayoutManager()
      layoutManager.addTextContainer(container)
      let storage = NSTextStorage()
      storage.addLayoutManager(layoutManager)
      return TextView(frame: .zero, textContainer: container)
    }

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
    
    override func layoutSubviews() {
      super.layoutSubviews()
      if !self.pairs.isEmpty && !self.isAligning {
        self.isAligning = true
        defer {
          self.isAligning = false
        }
        let layout = self.layoutManager
        layout.ensureLayout(for: self.textContainer)
        ListMarkers.align(self.textStorage, layoutManager: layout, pairs: pairs)
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
  
  private class DocumentationStringGenerator: MathAttributedStringGenerator, @unchecked Sendable {
    static let localBaseUrl = Bundle.main.url(
                                  forResource: "thread-states",
                                  withExtension: "png",
                                  subdirectory: "Documentation/Libraries/images")?
                                .deletingLastPathComponent()
                                .deletingLastPathComponent()
    
    static let highlighter: SyntaxHighlighter? = {
      if let highlighterJSUrl = Bundle(for: MarkdownLibrary.self).url(
                                  forResource: "highlight.min",
                                  withExtension: "js",
                                  subdirectory: "Root/LispKit/Assets/JavaScript/Highlight") {
        return SyntaxHighlighter(highlightJSURL: highlighterJSUrl,
                                 themeDirectory: Bundle(for: MarkdownLibrary.self).url(
                                   forResource: "Themes",
                                   withExtension: nil,
                                   subdirectory: "Root/LispKit/Assets/JavaScript/Highlight"))
      } else {
        return nil
      }
    }()
    
    static let mermaidRenderer: MermaidRenderer? = {
      if let mermaidURL = Bundle(for: MarkdownLibrary.self).url(
                            forResource: "mermaid.min",
                            withExtension: "js",
                            subdirectory: "Root/LispKit/Assets/JavaScript/Mermaid") {
        return MermaidRenderer(mermaidJSURL: mermaidURL,
                               cachesScript: true,
                               idleTime: MermaidRenderer.defaultIdleTime,
                               maxCachedDiagrams: MermaidRenderer.defaultMaxCachedDiagrams,
                               maxCacheBytes: MermaidRenderer.defaultMaxCacheBytes)
      } else {
        return nil
      }
    }()
    
    static let mathRenderer: MathRenderer? = {
      if let katexURL = Bundle(for: MarkdownLibrary.self).url(
                          forResource: "KaTeX",
                          withExtension: nil,
                          subdirectory: "Root/LispKit/Assets/JavaScript") {
        return MathRenderer(katexFolder: katexURL,
                            idleTime: MathRenderer.defaultIdleTime,
                            maxCachedFormulas: MathRenderer.defaultMaxCachedFormulas,
                            maxCacheBytes: MathRenderer.defaultMaxCacheBytes)
      } else {
        return nil
      }
    }()
    
    let rightPadding: Int
    
    init(fontColor: String,
         codeFontColor: String,
         codeBlockFontColor: String,
         codeBlockBackground: String,
         syntaxHighlighting: SyntaxHighlightingConfig,
         borderColor: String,
         blockquoteColor: String,
         h1Color: String,
         h2Color: String,
         h3Color: String,
         h4Color: String,
         rightPadding: Int,
         maxLayoutWidth: CGFloat,
         mermaidTheme: MermaidConfig.Theme) {
      self.rightPadding = rightPadding
      super.init(version: .OS26,
                 fontSize: UserSettings.standard.documentationTextFontSize,
                 fontFamily: MarkdownTextView.textFont,
                 fontColor: fontColor,
                 codeFontSize: UserSettings.standard.documentationCodeFontSize,
                 codeFontFamily: MarkdownTextView.codeFont,
                 codeFontColor: codeFontColor,
                 codeBlockFontSize: UserSettings.standard.documentationCodeFontSize,
                 codeBlockFontColor: codeBlockFontColor,
                 codeBlockBackground: codeBlockBackground,
                 syntaxHighlighting: syntaxHighlighting,
                 syntaxHighlighter: DocumentationStringGenerator.highlighter,
                 mermaid: MermaidConfig(theme: mermaidTheme,
                                        themeVariables: [:],
                                        fontFamily: nil,
                                        scale: 2,
                                        width: maxLayoutWidth,
                                        margin: 8,
                                        maxWidth: 400,
                                        spacing: 16,
                                        timeout: 5),
                 mermaidRenderer: DocumentationStringGenerator.mermaidRenderer,
                 math: MathConfig(katex: KaTeXOptions(output: .htmlAndMathml,
                                                      macros: [:],
                                                      maxExpand: 1000,
                                                      maxSize: nil,
                                                      minRuleThickness: nil,
                                                      maxLength: 10000),
                                  scale: 3,
                                  spacing: 8,
                                  maxWidth: nil,
                                  timeout: 10),
                 mathRenderer: DocumentationStringGenerator.mathRenderer,
                 borderColor: borderColor,
                 blockquoteColor: blockquoteColor,
                 h1Color: h1Color,
                 h2Color: h2Color,
                 h3Color: h3Color,
                 h4Color: h4Color,
                 maxImageWidth: "\(maxLayoutWidth)px",
                 imageBaseUrl: Self.localBaseUrl,
                 alignListMarkers: true,
                 renderingOptions: RenderingOptions(baseUrl: nil,
                                                    timeout: RenderingOptions.defaultTimeout,
                                                    localImages: .any,
                                                    remoteImages: .any,
                                                    imageExtensions: RenderingOptions.defaultImageExtensions,
                                                    safeMode: false,
                                                    textSizeMultiplier: nil))
    }
    
    private class DocumentationHtmlGenerator: MathOS26HtmlGenerator, @unchecked Sendable {
      let rightPadding: Int
      
      public override init(outer: AttributedStringGenerator, renderingOptions: RenderingOptions) {
        self.rightPadding = (outer as! DocumentationStringGenerator).rightPadding
        super.init(outer: outer, renderingOptions: renderingOptions)
      }
      
      open override func generate(block: Block, parent: Parent, tight: Bool = false) -> String {
        switch block {
          case .heading(let n, let text):
            guard n == 6,
                  text.count == 2,
                  case .text(let lib) = text[0],
                  case .text(let type) = text[1] else {
              return super.generate(block: block, parent: parent, tight: tight)
            }
            return "<table style=\"border-bottom: 0.5px solid #ccc; margin-bottom: 3px;\" " +
                   "width=\"100%\"><tbody>" +
                   "<tr style=\"height: 15px; font-family: " + MarkdownTextView.libraryFont +
                   "; font-size: \(UserSettings.standard.documentationLibraryFontSize); " +
                   "font-style: italic;\">" +
                   "<td style=\"text-align: left;\">" + lib + "</td>" +
                   "<td style=\"text-align: right;padding-right: \(self.rightPadding)px;\">" +
                   type + "</td></tr></tbody></table><br/>\n"
          default:
            return super.generate(block: block, parent: parent, tight: tight)
        }
      }
    }
    
    open override func htmlGenerator(options: RenderingOptions? = nil) -> InternalHtmlGenerator {
      return DocumentationHtmlGenerator(outer: self,
                                        renderingOptions: options ?? self.renderingOptions)
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
    let view = TextView.makeTextKit1()
    view.textColor = .label
    view.backgroundColor = .clear
    view.textContainerInset = .zero
    view.isEditable = false
    view.isScrollEnabled = false
    view.isSelectable = true
    view.textContainerInset = .zero
    view.textContainer.lineFragmentPadding = 0
    view.textContainer.lineBreakMode = .byWordWrapping
    view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    view.delegate = context.coordinator
    /* view.linkTextAttributes = [
      .foregroundColor: UIColor.systemBlue,
      .underlineStyle: NSUnderlineStyle.single.rawValue
    ] */
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
          let generator =
            context.coordinator.colorScheme == .dark ?
                DocumentationStringGenerator(
                  fontColor: "#fff",
                  codeFontColor: "#ccddff",
                  codeBlockFontColor: "#aaddff",
                  codeBlockBackground: "#333",
                  syntaxHighlighting: .defaultDark,
                  borderColor: "#333",
                  blockquoteColor: "#fff",
                  h1Color: "#aa1111",
                  h2Color: "#007aff",
                  h3Color: "#007aff",
                  h4Color: "#007aff",
                  rightPadding: self.rightPadding,
                  maxLayoutWidth: self.maxLayoutWidth,
                  mermaidTheme: .dark)
              : DocumentationStringGenerator(
                  fontColor: "#000",
                  codeFontColor: "#0000aa",
                  codeBlockFontColor: "#000099",
                  codeBlockBackground: "#eee",
                  syntaxHighlighting: .default,
                  borderColor: "#eee",
                  blockquoteColor: "#000",
                  h1Color: "#aa1111",
                  h2Color: "#007aff",
                  h3Color: "#007aff",
                  h4Color: "#007aff",
                  rightPadding: self.rightPadding,
                  maxLayoutWidth: self.maxLayoutWidth,
                  mermaidTheme: .default)
          generator.generateAsync(doc: md, scaleImages: true) { result in
            switch result {
              case .success(let attributedString):
                uiView.attributedText = attributedString
                uiView.pairs = ListMarkers.pairs(in: attributedString)
              case .failure(let error):
                uiView.attributedText = NSAttributedString(string: error.localizedDescription)
            }
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
