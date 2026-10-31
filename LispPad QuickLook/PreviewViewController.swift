//
//  PreviewViewController.swift
//  LispPad QuickLook
//
//  Copyright © 2026 Matthias Zenger. All rights reserved.
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

import UIKit
import QuickLook
import CoreText

/// Previews Scheme programs and libraries with the syntax highlighting of the LispPad editor.
final class PreviewViewController: UIViewController, QLPreviewingController {
  private let textView = UITextView()

  override func viewDidLoad() {
    super.viewDidLoad()
    self.view.backgroundColor = .systemBackground
    self.textView.backgroundColor = .systemBackground
    self.textView.isEditable = false
    self.textView.isSelectable = true
    self.textView.alwaysBounceVertical = true
    self.textView.dataDetectorTypes = []
    self.textView.textContainerInset = UIEdgeInsets(top: 12, left: 8, bottom: 12, right: 8)
    self.textView.frame = self.view.bounds
    self.textView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    if #available(iOS 26.0, *) {
      // The code starts right below the toolbar; there is nothing to fade out there.
      self.textView.topEdgeEffect.isHidden = true
    }
    self.view.addSubview(self.textView)
  }

  func preparePreviewOfFile(at url: URL) async throws {
    self.textView.attributedText = try await Self.highlightedText(of: url)
  }

  /// Reads the file and colors it like the editor does. This runs off the main actor, which
  /// is why the helpers below are `nonisolated`; the view controller itself is main-actor bound.
  @concurrent
  private static func highlightedText(of url: URL) async throws -> NSAttributedString {
    let settings = SchemePreviewSettings.load()
    Self.registerFonts(of: settings)
    let (string, truncated) = try Self.readText(from: url)
    let font = settings.font
    let palette = settings.palette
    let text = NSMutableAttributedString(string: string, attributes: [.font: font])
    let range = NSRange(location: 0, length: text.length)
    if settings.highlightSyntax {
      let symbols = settings.markupIdent ? Self.documentedSymbols() : nil
      SchemeSyntaxHighlighter(palette: palette,
                              isDocumented: symbols.map { symbols in { symbols.contains($0) } })
        .highlight(text, text.string as NSString, range)
    } else {
      text.addAttribute(.foregroundColor, value: palette.text, range: range)
    }
    if truncated {
      text.append(NSAttributedString(string: "\n\u{2026} preview truncated\n",
                                     attributes: [.font: font,
                                                  .foregroundColor: UIColor.secondaryLabel]))
    }
    return text
  }

  /// The number of bytes of a file that are previewed at most.
  private nonisolated static let maxBytes = 1_000_000

  /// Reads the file at `url`, but no more than `maxBytes` bytes of it. `truncated` tells
  /// whether the file is longer.
  private nonisolated static func readText(from url: URL) throws
      -> (text: String, truncated: Bool) {
    let handle = try FileHandle(forReadingFrom: url)
    defer {
      try? handle.close()
    }
    let data = try handle.read(upToCount: Self.maxBytes + 1) ?? Data()
    let truncated = data.count > Self.maxBytes
    return (Self.decode(truncated ? data.prefix(Self.maxBytes) : data, truncated: truncated),
            truncated)
  }

  /// Decodes the content of a file. UTF-8 and UTF-16 (with a byte order mark) are recognized;
  /// everything else is treated as Windows-1252. A leading byte order mark is dropped and all
  /// line endings become `\n`. If `truncated` is set, `data` may end in the middle of a
  /// character.
  private nonisolated static func decode(_ data: Data, truncated: Bool) -> String {
    var string: String? = nil
    if data.starts(with: [0xFF, 0xFE]) || data.starts(with: [0xFE, 0xFF]) {
      string = String(data: data, encoding: .utf16)
    } else {
      string = String(data: data, encoding: .utf8)
      if string == nil && truncated {
        var bytes = data
        for _ in 0..<3 {
          bytes = bytes.dropLast()
          if let valid = String(data: bytes, encoding: .utf8) {
            string = valid
            break
          }
        }
      }
    }
    var text = string
            ?? String(data: data, encoding: .windowsCP1252)
            ?? String(data: data, encoding: .isoLatin1)
            ?? ""
    if text.hasPrefix("\u{FEFF}") {
      text.removeFirst()
    }
    return text.replacingOccurrences(of: "\r\n", with: "\n")
               .replacingOccurrences(of: "\r", with: "\n")
  }

  /// The identifiers for which the app has documentation, if the app has published them.
  private nonisolated static func documentedSymbols() -> Set<String>? {
    guard let url = SchemePreview.documentedSymbolsURL,
          let content = try? String(contentsOf: url, encoding: .utf8) else {
      return nil
    }
    return Set(content.split(separator: "\n").map { String($0) })
  }

  /// Makes the editor font available to the extension. The app bundles its fonts, but an
  /// extension does not see them unless it registers them itself.
  private nonisolated static func registerFonts(of settings: SchemePreviewSettings) {
    guard let name = settings.fontName, UIFont(name: name, size: 12.0) == nil else {
      return
    }
    // This extension is located at <app>/PlugIns/<extension>.appex
    let appURL = Bundle.main.bundleURL.deletingLastPathComponent().deletingLastPathComponent()
    guard let app = Bundle(url: appURL),
          let files = app.object(forInfoDictionaryKey: "UIAppFonts") as? [String] else {
      return
    }
    for file in files {
      if let url = app.url(forResource: file, withExtension: nil) {
        CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
      }
    }
  }
}
