//
//  MarkdownTextRendererTests.swift
//  LispPadTests
//
//  Created by Matthias Zenger on 30/10/2026.
//

import Testing
import SwiftUI
import MarkdownKit
@testable import LispPad


/// What the stub passes of a test did.
@MainActor
private final class Recorder {
  var quickCalls = 0
  var prepareCalls = 0
  var fullCalls = 0
  var prepareFinished = false
  var texts: [String] = []

  /// The result of the preparation: true if it rendered something.
  var rendered = false

  /// How long the passes take, in seconds. Waiting does not react to cancellation, like a
  /// generator which is busy in a web view.
  var quickDelay = 0.0
  var prepareDelay = 0.0

  /// If set, the delay of the n-th call of the first pass instead of `quickDelay`.
  var quickDelays: [Double] = []

  private func wait(_ seconds: Double) async {
    if seconds > 0 {
      await withCheckedContinuation { continuation in
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
          continuation.resume()
        }
      }
    }
  }

  func passes() -> MarkdownTextRenderer.Passes {
    return MarkdownTextRenderer.Passes(
      quick: { _ in
        self.quickCalls += 1
        let call = self.quickCalls
        await self.wait(call <= self.quickDelays.count ? self.quickDelays[call - 1]
                                                       : self.quickDelay)
        return NSAttributedString(string: "quick #\(call)")
      },
      prepare: { _ in
        self.prepareCalls += 1
        await self.wait(self.prepareDelay)
        self.prepareFinished = true
        return self.rendered
      },
      full: { _ in
        self.fullCalls += 1
        return NSAttributedString(string: "full #\(self.fullCalls)")
      })
  }

  func renderer(cache: MarkdownTextCache? = nil) -> MarkdownTextRenderer {
    let renderer = MarkdownTextRenderer(cache: cache ?? MarkdownTextCache(capacity: 4),
                                        passes: { _ in self.passes() })
    renderer.onText = { text in
      self.texts.append(text.string)
    }
    return renderer
  }
}

@MainActor
private func request(_ markdown: String?,
                     colorScheme: ColorScheme = .light) -> MarkdownTextRequest {
  let block = markdown.map { ExtendedMarkdownParser.standard.parse($0) }
  return MarkdownTextRequest(content: MarkdownTextContent(block: block, revision: nil),
                             colorScheme: colorScheme,
                             rightPadding: 0,
                             fonts: DocumentationFonts(text: 15, code: 13, library: 14))
}

@MainActor
private func waitUntil(_ condition: () -> Bool) async -> Bool {
  let deadline = ContinuousClock.now + .seconds(3)
  while !condition() {
    if ContinuousClock.now > deadline {
      return false
    }
    try? await Task.sleep(for: .milliseconds(5))
  }
  return true
}

@MainActor
@Suite("Markdown text renderer")
struct MarkdownTextRendererTests {

  @Test("The first text is shown before the preparation is done")
  func firstTextComesFirst() async throws {
    let recorder = Recorder()
    recorder.rendered = true
    recorder.prepareDelay = 0.2
    let renderer = recorder.renderer()
    renderer.update(request("# Title"))
    #expect(await waitUntil { recorder.texts.count == 1 })
    #expect(recorder.texts[0].hasPrefix("quick"))
    #expect(!recorder.prepareFinished)
    #expect(await waitUntil { recorder.texts.count == 2 })
    #expect(recorder.texts[1].hasPrefix("full"))
    #expect(recorder.prepareFinished)
  }

  @Test("Nothing is generated again if nothing was rendered")
  func noSecondGeneration() async throws {
    let recorder = Recorder()
    recorder.rendered = false
    let renderer = recorder.renderer()
    renderer.update(request("# Title\n\nSome text with a local ![image](images/a.png)."))
    #expect(await waitUntil { recorder.prepareFinished })
    try await Task.sleep(for: .milliseconds(50))
    #expect(recorder.texts.count == 1)
    #expect(recorder.fullCalls == 0)
  }

  @Test("A document with remote images is generated again")
  func remoteImagesNeedFinalPass() async throws {
    let recorder = Recorder()
    recorder.rendered = false
    let renderer = recorder.renderer()
    renderer.update(request("Text ![image](https://example.com/a.png)."))
    #expect(await waitUntil { recorder.texts.count == 2 })
    #expect(recorder.fullCalls == 1)
  }

  @Test("The same request is ignored, a different one is not")
  func sameRequestIsIgnored() async throws {
    let recorder = Recorder()
    let renderer = recorder.renderer()
    renderer.update(request("# Title"))
    renderer.update(request("# Title"))
    #expect(await waitUntil { recorder.prepareFinished })
    #expect(recorder.quickCalls == 1)
    renderer.update(request("# Title", colorScheme: .dark))
    #expect(await waitUntil { recorder.quickCalls == 2 })
    renderer.update(request("# Other"))
    #expect(await waitUntil { recorder.quickCalls == 3 })
  }

  @Test("The result of a superseded request is never shown")
  func supersededRequestIsNotShown() async throws {
    let recorder = Recorder()
    // The first request finishes its first pass after the second one
    recorder.quickDelays = [0.15, 0.01]
    let renderer = recorder.renderer()
    renderer.update(request("# First document"))
    renderer.update(request("# Second document"))
    #expect(await waitUntil { recorder.prepareFinished })
    try await Task.sleep(for: .milliseconds(300))
    #expect(recorder.quickCalls == 2)
    #expect(recorder.texts == ["quick #2"])
  }

  @Test("A cancelled renderer shows nothing and starts again with the next request")
  func cancelledRendererStartsAgain() async throws {
    let recorder = Recorder()
    recorder.quickDelay = 0.1
    let renderer = recorder.renderer()
    renderer.update(request("# Title"))
    renderer.cancel()
    try await Task.sleep(for: .milliseconds(250))
    #expect(recorder.texts.isEmpty)
    renderer.update(request("# Title"))
    #expect(await waitUntil { recorder.texts.count == 1 })
  }

  @Test("A view that is created again gets the final text at once")
  func cacheServesFinalText() async throws {
    let cache = MarkdownTextCache(capacity: 4)
    let first = Recorder()
    first.rendered = true
    let renderer = first.renderer(cache: cache)
    renderer.update(request("# Title"))
    #expect(await waitUntil { first.texts.count == 2 })
    let second = Recorder()
    let another = second.renderer(cache: cache)
    another.update(request("# Title"))
    #expect(second.texts.count == 1)
    #expect(second.texts[0].hasPrefix("full"))
    #expect(second.quickCalls == 0)
  }

  @Test("The cache keeps the last documents only")
  func cacheIsBounded() async throws {
    let cache = MarkdownTextCache(capacity: 2)
    let text = NSAttributedString(string: "text")
    cache.store(text, for: request("one"))
    cache.store(text, for: request("two"))
    cache.store(text, for: request("three"))
    #expect(cache.text(for: request("one")) == nil)
    #expect(cache.text(for: request("two")) != nil)
    #expect(cache.text(for: request("three")) != nil)
  }

  @Test("Documents that are replaced in place are not cached")
  func mutableContentIsNotCached() async throws {
    let cache = MarkdownTextCache(capacity: 2)
    let owner = MutableBlock()
    let content = MarkdownTextContent(block: ExtendedMarkdownParser.standard.parse("text"),
                                      revision: .init(owner: ObjectIdentifier(owner), version: 1))
    let mutable = MarkdownTextRequest(content: content,
                                      colorScheme: .light,
                                      rightPadding: 0,
                                      fonts: DocumentationFonts(text: 15, code: 13, library: 14))
    cache.store(NSAttributedString(string: "text"), for: mutable)
    #expect(cache.text(for: mutable) == nil)
  }

  @Test("Missing content is reported")
  func missingContent() async throws {
    let recorder = Recorder()
    let renderer = recorder.renderer()
    renderer.update(request(nil))
    #expect(recorder.texts == ["Content not available"])
    #expect(recorder.quickCalls == 0)
  }

  @Test("Content that is replaced in place is identified by its version")
  func contentRevisions() async throws {
    let owner = MutableBlock()
    let other = MutableBlock()
    let block = ExtendedMarkdownParser.standard.parse("text")
    func content(_ owner: MutableBlock, _ version: Int) -> MarkdownTextContent {
      return MarkdownTextContent(block: block,
                                 revision: .init(owner: ObjectIdentifier(owner), version: version))
    }
    #expect(content(owner, 1).isSame(as: content(owner, 1)))
    #expect(!content(owner, 1).isSame(as: content(owner, 2)))
    #expect(!content(owner, 1).isSame(as: content(other, 1)))
    #expect(!content(owner, 1).isSame(as: MarkdownTextContent(block: block, revision: nil)))
  }
}

@Suite("Remote images")
struct RemoteImagesTests {

  private func parse(_ markdown: String) -> Block {
    return ExtendedMarkdownParser.standard.parse(markdown)
  }

  @Test("Images from the web are found in all kinds of blocks")
  func findsRemoteImages() {
    let remote = "![x](https://example.com/a.png)"
    #expect(parse(remote).containsRemoteImages)
    #expect(parse("![x](HTTP://example.com/a.png)").containsRemoteImages)
    #expect(parse("# Title \(remote)").containsRemoteImages)
    #expect(parse("* item\n* item with \(remote)").containsRemoteImages)
    #expect(parse("1. one\n   * nested \(remote)").containsRemoteImages)
    #expect(parse("> quote *with \(remote)*").containsRemoteImages)
    #expect(parse("[a link \(remote)](https://example.com)").containsRemoteImages)
    #expect(parse("| A | B |\n|---|---|\n| 1 | \(remote) |").containsRemoteImages)
  }

  @Test("Local images and other content are not remote")
  func ignoresLocalImages() {
    #expect(!parse("![x](images/a.png)").containsRemoteImages)
    #expect(!parse("![x](file:///tmp/a.png)").containsRemoteImages)
    #expect(!parse("![x]()").containsRemoteImages)
    #expect(!parse("A [link](https://example.com/a.png) and `code`").containsRemoteImages)
    #expect(!parse("```\n![x](https://example.com/a.png)\n```").containsRemoteImages)
    #expect(!parse("").containsRemoteImages)
  }
}
