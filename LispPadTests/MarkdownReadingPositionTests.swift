//
//  MarkdownReadingPositionTests.swift
//  LispPadTests
//
//  Created by Matthias Zenger on 30/10/2026.
//

import Testing
import UIKit
import MarkdownKit
@testable import LispPad


/// A text view in a scroll view in a window, like `MarkdownText` in a scroll view of SwiftUI.
@MainActor
private final class Fixture {
  typealias TextView = MarkdownTextView.TextView

  let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 640, height: 600))
  let scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: 640, height: 600))
  let textView = TextView.makeTextKit1()
  let lineCount = 400

  init(width: CGFloat) {
    let text = (0..<self.lineCount).map { line in
      "Paragraph \(line): the quick brown fox jumps over the lazy dog, again and again, " +
      "until the line has to wrap at some point."
    }.joined(separator: "\n")
    self.textView.isScrollEnabled = false
    self.textView.isEditable = false
    self.textView.textContainerInset = .zero
    self.textView.textContainer.lineFragmentPadding = 0
    self.window.isHidden = false
    self.window.addSubview(self.scrollView)
    self.scrollView.addSubview(self.textView)
    self.textView.setContent(
        NSAttributedString(string: text, attributes: [.font: UIFont.systemFont(ofSize: 15)]),
        content: MarkdownTextContent(block: nil, revision: nil))
    self.layout(width: width)
  }

  /// Lays out the text for `width`, the way the container of the view does it.
  func layout(width: CGFloat) {
    self.textView.maxLayoutWidth = width
    let height = self.textView.intrinsicContentSize.height
    self.textView.frame = CGRect(x: 0, y: 0, width: width, height: height)
    self.scrollView.contentSize = CGSize(width: width, height: height)
    self.textView.layoutIfNeeded()
  }

  /// The number of the paragraph at `index`.
  func paragraph(at index: Int) -> Int? {
    let text = self.textView.textStorage.string as NSString
    let line = text.substring(with: text.lineRange(for: NSRange(location: index, length: 0)))
    return line.split(separator: " ").dropFirst().first.flatMap {
      Int($0.dropLast())
    }
  }
}

@MainActor
@Suite("Reading position")
struct MarkdownReadingPositionTests {

  @Test("The reader stays at the same paragraph if the text is laid out for another width")
  func placeSurvivesWidthChange() throws {
    let fixture = Fixture(width: 320)
    fixture.scrollView.contentOffset = CGPoint(x: 0, y: 2500)
    let place = try #require(fixture.textView.currentPlace())
    #expect(!place.atTop)
    let paragraph = try #require(fixture.paragraph(at: place.index))
    #expect(paragraph > 10)

    fixture.layout(width: 640)
    fixture.textView.restore(place, oldWidth: 320)
    let restored = try #require(fixture.textView.currentPlace())
    #expect(fixture.paragraph(at: restored.index) == paragraph)

    // and back; the text is taller now
    fixture.layout(width: 320)
    fixture.textView.restore(restored, oldWidth: 640)
    let again = try #require(fixture.textView.currentPlace())
    #expect(fixture.paragraph(at: again.index) == paragraph)
  }

  @Test("The reader stays at the same paragraph while the width keeps changing")
  func placeSurvivesWidthSteps() throws {
    let fixture = Fixture(width: 320)
    fixture.scrollView.contentOffset = CGPoint(x: 0, y: 2500)
    let place = try #require(fixture.textView.currentPlace())
    let paragraph = try #require(fixture.paragraph(at: place.index))

    fixture.textView.keepPlaceForWidthChange()
    fixture.layout(width: 400)
    fixture.textView.restore(place, oldWidth: 320)

    // The text is laid out for the next width before the view is told about it, but the scroll
    // view is still at the offset that was set for the previous one
    for width: CGFloat in [480, 560, 440] {
      fixture.layout(width: width)
      fixture.textView.keepPlaceForWidthChange()
      let current = try #require(fixture.textView.currentPlace())
      #expect(fixture.paragraph(at: current.index) == paragraph)
    }
  }

  @Test("A document that replaces another one is shown from its start")
  func replacedDocumentStartsAtTop() throws {
    let owner = MutableBlock()
    let define = ExtendedMarkdownParser.standard.parse("# define")
    let defineAgain = ExtendedMarkdownParser.standard.parse("# define")
    let defineLibrary = ExtendedMarkdownParser.standard.parse("# define-library")
    func content(_ block: Block, _ version: Int) -> MarkdownTextContent {
      return MarkdownTextContent(block: block,
                                 revision: .init(owner: ObjectIdentifier(owner), version: version))
    }
    let fixture = Fixture(width: 320)
    let text = NSAttributedString(attributedString: fixture.textView.attributedText)
    fixture.textView.setContent(text, content: content(define, 1))
    fixture.scrollView.contentOffset = CGPoint(x: 0, y: 2500)

    // the same document, e.g. with the diagrams that were rendered in the meantime
    fixture.textView.setContent(text, content: content(define, 1))
    #expect(fixture.scrollView.contentOffset.y == 2500)

    // an equal document that replaced it in place
    fixture.textView.setContent(text, content: content(defineAgain, 2))
    #expect(fixture.scrollView.contentOffset.y == 2500)

    // another document
    fixture.textView.setContent(text, content: content(defineLibrary, 3))
    #expect(fixture.scrollView.contentOffset.y == 0)
  }

  @Test("A reader at the start of the text stays there")
  func startStaysStart() throws {
    let fixture = Fixture(width: 320)
    let place = try #require(fixture.textView.currentPlace())
    #expect(place.atTop)
    fixture.layout(width: 640)
    fixture.textView.restore(place, oldWidth: 320)
    #expect(fixture.scrollView.contentOffset.y == 0)
  }

  @Test("The reader is put back in a view that is created again")
  func placeSurvivesNewView() throws {
    let old = Fixture(width: 320)
    old.scrollView.contentOffset = CGPoint(x: 0, y: 4000)
    let place = try #require(old.textView.currentPlace())
    let paragraph = try #require(old.paragraph(at: place.index))

    let new = Fixture(width: 640)
    #expect(new.scrollView.contentOffset.y == 0)
    new.textView.restore(place, oldWidth: nil)
    let restored = try #require(new.textView.currentPlace())
    #expect(new.paragraph(at: restored.index) == paragraph)
  }

  @Test("A place beyond the end of the text is reached as far as possible")
  func placeIsClamped() throws {
    let fixture = Fixture(width: 320)
    let height = fixture.scrollView.contentSize.height
    fixture.scrollView.contentOffset = CGPoint(x: 0, y: height - 600)
    let place = try #require(fixture.textView.currentPlace())
    fixture.layout(width: 640)
    fixture.textView.restore(place, oldWidth: 320)
    let highest = fixture.scrollView.contentSize.height - fixture.scrollView.bounds.height
    #expect(fixture.scrollView.contentOffset.y <= highest + 0.5)
    #expect(fixture.scrollView.contentOffset.y > 0)
  }

  @Test("The place is forgotten when the position is reset")
  func reset() {
    let position = MarkdownReadingPosition()
    #expect(position.place == nil)
    position.reset()
    #expect(position.place == nil)
  }

  @Test("A text view reserves room for a spinner until it has text")
  func loadingReservesHeight() {
    let textView = MarkdownTextView.TextView.makeTextKit1()
    textView.maxLayoutWidth = 320
    let empty = textView.intrinsicContentSize.height
    textView.beginLoading()
    #expect(textView.isLoading)
    #expect(textView.intrinsicContentSize.height > empty)
    textView.setContent(NSAttributedString(string: "Text"),
                        content: MarkdownTextContent(block: nil, revision: nil))
    #expect(!textView.isLoading)
    #expect(textView.intrinsicContentSize.height < 44)
  }
}
