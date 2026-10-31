//
//  SchemeSyntaxHighlightingTests.swift
//  LispPadTests
//
//  Created by Matthias Zenger on 30/10/2026.
//

import Testing
import UIKit
@testable import LispPad

/// Pins down how the editor colors Scheme code. The expected strings have one letter per UTF-16
/// code unit of the sample: `t` text, `p` parentheses and other delimiters, `l` literals (strings
/// and numbers), `c` comments, `i` documented identifiers.
///
/// The expectations were recorded from the editor's highlighter before it was moved into a shared
/// type, so they describe what it does rather than what it should do (digits inside identifiers
/// and the continuation line of a multi-line string, for instance, are colored as they always
/// were).
@MainActor
struct SchemeSyntaxHighlightingTests {

  static let samples: [String] = [
    "(define (square x) (* x x)) ; squares",
    "(display \"hello world\") 42 3.14 -7",
    "'(a b #t #\\a) `(x ,y) #(1 2)",
    "{a [b]} |sym with spaces|",
    "(define x 1)\n; a comment\n(display \"multi\nline\")\n",
    "(display \"unterminated",
    "x1 2bar foo-bar! <=?",
    "; only a comment",
    "",
  ]

  static let expected: [String] = [
    "ptttttttpttttttttptptttttpptccccccccc",
    "pttttttttlllllllllllllptlltltllttl",
    "ppttttpttpptptppttptptppltlp",
    "pttptpptptttttttttttttttp",
    "ptttttttttlptccccccccccctpttttttttlllllltttttllt",
    "pttttttttlllllllllllll",
    "tltltttttttttttttttt",
    "cccccccccccccccc",
    "",
  ]

  /// One letter per UTF-16 unit, derived from the `foregroundColor` attribute.
  static func roles(of text: NSAttributedString, palette: SchemeSyntaxPalette) -> String {
    var result = ""
    for i in 0..<text.length {
      let color = text.attribute(.foregroundColor, at: i, effectiveRange: nil) as? UIColor
      if color === palette.text {
        result += "t"
      } else if color === palette.parens {
        result += "p"
      } else if color === palette.literals {
        result += "l"
      } else if color === palette.comments {
        result += "c"
      } else if color === palette.docuIdent {
        result += "i"
      } else {
        result += "?"
      }
    }
    return result
  }

  /// The roles of the characters in an attributed string highlighted by the editor.
  static func roles(of text: NSAttributedString) -> String {
    let settings = UserSettings.standard
    return roles(of: text, palette: SchemeSyntaxPalette(text: settings.textColor,
                                                        parens: settings.parensColor,
                                                        literals: settings.literalsColor,
                                                        comments: settings.commentsColor,
                                                        docuIdent: settings.docuIdentColor))
  }

  static let palette = SchemeSyntaxPalette(text: UIColor(white: 0.1, alpha: 1.0),
                                           parens: UIColor(white: 0.2, alpha: 1.0),
                                           literals: UIColor(white: 0.3, alpha: 1.0),
                                           comments: UIColor(white: 0.4, alpha: 1.0),
                                           docuIdent: UIColor(white: 0.5, alpha: 1.0))

  /// Highlights `code` with `SchemeSyntaxHighlighter` directly. Identifiers in `documented` are
  /// marked up; the identifier markup is off if `documented` is `nil`.
  static func highlight(_ code: String, documented: Set<String>?) -> String {
    let text = NSMutableAttributedString(string: code)
    let isDocumented: ((String) -> Bool)? = documented.map { set in { set.contains($0) } }
    SchemeSyntaxHighlighter(palette: Self.palette, isDocumented: isDocumented)
      .highlight(text, code as NSString, NSRange(location: 0, length: text.length))
    return Self.roles(of: text, palette: Self.palette)
  }

  /// Runs `body` with syntax highlighting switched on and the lookup of documented identifiers
  /// switched off, so that the outcome does not depend on the documentation that was loaded.
  static func withPlainHighlighting<T>(_ body: () -> T) -> T {
    let settings = UserSettings.standard
    let highlight = settings.schemeHighlightSyntax
    let markup = settings.schemeMarkupIdent
    settings.schemeHighlightSyntax = true
    settings.schemeMarkupIdent = false
    defer {
      settings.schemeHighlightSyntax = highlight
      settings.schemeMarkupIdent = markup
    }
    return body()
  }

  static let docManager = DocumentationManager()

  @Test func editorHighlighting() {
    let result = Self.withPlainHighlighting { () -> [String] in
      let delegate = CodeEditorTextStorageDelegate(console: false,
                                                   editorType: .scheme,
                                                   docManager: Self.docManager)
      return Self.samples.map { sample in
        let storage = NSTextStorage(string: sample)
        delegate.highlight(storage)
        return Self.roles(of: storage)
      }
    }
    #expect(result.count == Self.expected.count)
    for (sample, (roles, expected)) in zip(Self.samples, zip(result, Self.expected)) {
      #expect(roles == expected, "unexpected roles for \(sample.debugDescription)")
    }
  }

  @Test func withoutIdentifierMarkup() {
    #expect(Self.highlight("(define (f x) x)", documented: nil)
              == "p" + "ttttttt" + "p" + "ttt" + "p" + "tt" + "p")
  }

  @Test func documentedIdentifiers() {
    let code = "(define (square x) (* x x)) ; squares"
    #expect(Self.highlight(code, documented: ["define", "*"])
              == "p" + "iiiiii" + "t" + "p" + "tttttttt" + "p" + "t" + "p" + "i" + "tttt" + "pp"
               + "t" + "ccccccccc")
  }

  @Test func documentedIdentifierAtEndOfTextAndLine() {
    #expect(Self.highlight("foo", documented: ["foo"]) == "iii")
    #expect(Self.highlight("foo\nbar", documented: ["foo"]) == "iiitttt")
    #expect(Self.highlight("foo\"x\"", documented: ["foo"]) == "iii" + "lll")
  }

  @Test func identifiersInStringsAndCommentsAreNotMarkedUp() {
    #expect(Self.highlight("\"define\" ; define", documented: ["define"])
              == "llllllll" + "t" + "cccccccc")
  }
}
