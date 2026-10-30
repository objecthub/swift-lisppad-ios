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


// MARK: - Views

/// Shows a Markdown document as formatted text. The text is generated in up to three passes (see
/// `MarkdownTextRenderer`), so it is visible long before Mermaid diagrams, formulas and remote
/// images are ready. The view sizes itself to its text and has to be placed in a scroll view.
///
/// If the width of the view changes, the reader stays at the same place of the text. If SwiftUI
/// creates the view again for the same document, e.g. because a rotation replaces the surrounding
/// navigation, `position` brings the reader back to where they were.
struct MarkdownText: View {
  private let block: Block?
  private let rightPadding: Int
  private let position: MarkdownReadingPosition?

  init(_ markdownText: Block?,
       rightPadding: Int = 0,
       position: MarkdownReadingPosition? = nil) {
    self.block = markdownText
    self.rightPadding = rightPadding
    self.position = position
  }

  var body: some View {
    MarkdownTextContainer(content: MarkdownTextContent(block: self.block, revision: nil),
                          rightPadding: self.rightPadding,
                          position: self.position)
  }
}

/// Like `MarkdownText`, but for a document that is replaced in place. The reader keeps their
/// place when the view is created again for the same version of the document; if the document
/// is replaced, the reader starts at the beginning of the new one.
struct MutableMarkdownText: View {
  @ObservedObject private var mutableBlock: MutableBlock
  private let rightPadding: Int

  init(_ mutableBlock: MutableBlock, rightPadding: Int = 0) {
    self.mutableBlock = mutableBlock
    self.rightPadding = rightPadding
  }

  var body: some View {
    MarkdownTextContainer(
      content: MarkdownTextContent(block: self.mutableBlock.block,
                                   revision: .init(owner: ObjectIdentifier(self.mutableBlock),
                                                   version: self.mutableBlock.version)),
      rightPadding: self.rightPadding,
      position: self.mutableBlock.readingPosition)
  }
}

/// Remembers where a reader is in a Markdown document. The owner of a view that SwiftUI may
/// create again for the same document hands the same instance to every `MarkdownText` it shows
/// in that place, and resets it when the document is replaced by a different one.
final class MarkdownReadingPosition {

  /// A place in a document: the character at the top of the visible area, and how far down in
  /// its line the top of the visible area is.
  struct Place {
    let content: MarkdownTextContent
    let index: Int
    let fraction: CGFloat

    /// True if the document is scrolled to its start.
    let atTop: Bool
  }

  private(set) var place: Place? = nil

  init() {}

  /// Forgets the place, such that the next view shows the document from its start.
  func reset() {
    self.place = nil
  }

  fileprivate func record(_ place: Place) {
    self.place = place
  }
}

/// Gives the text view the width of its surroundings and takes its height from it.
private struct MarkdownTextContainer: View {
  @StateObject private var intrinsicContentSize = MutableSize()
  let content: MarkdownTextContent
  let rightPadding: Int
  let position: MarkdownReadingPosition?

  var body: some View {
    GeometryReader { geometry in
      MarkdownTextView(content: self.content,
                       maxLayoutWidth: geometry.size.width -
                                       geometry.safeAreaInsets.leading -
                                       geometry.safeAreaInsets.trailing,
                       intrinsicContentSize: self.intrinsicContentSize,
                       rightPadding: self.rightPadding,
                       position: self.position)
    }
    .frame(idealWidth: self.intrinsicContentSize.size?.width,
           idealHeight: self.intrinsicContentSize.size?.height)
    .fixedSize(horizontal: false, vertical: true)
  }
}

struct MarkdownTextView: UIViewRepresentable {

  /// A text view which puts the markers of list items on the baseline of the first line of
  /// their items after each layout: the first line depends on the width of the text.
  final class TextView: UITextView {

    /// The markers of lists in the text. The layout of a text view is only touched if there are
    /// any (using its layout manager makes it use TextKit 1, as lists need anyway).
    var pairs: [ListMarkers.Pair] = []

    /// Set to true while markers are being adjusted.
    private var isAligning = false

    /// The height that is kept free for the spinner until there is text.
    private static let loadingHeight: CGFloat = 44

    /// How long it takes until the spinner appears. Texts that are there quickly do not flicker.
    private static let spinnerDelay: TimeInterval = 0.2

    /// How long a place that is to be restored is waited for the layout to catch up.
    private static let restoreTimeout: TimeInterval = 1.5

    /// How long the sizes of this view and its scroll view must stay the same before they count
    /// as settled, if the scroll view does not reach the end of this view.
    private static let settleTime: TimeInterval = 0.1

    /// True from the request for the first text until it is there.
    private(set) var isLoading = false
    private let spinner = UIActivityIndicatorView(style: .medium)
    private var spinnerStart: DispatchWorkItem? = nil

    /// The document of the text that is shown.
    private(set) var shownContent: MarkdownTextContent? = nil

    /// Receives the place of the reader while they scroll.
    var position: MarkdownReadingPosition? = nil {
      didSet {
        self.observeScrollView()
      }
    }

    /// The scroll view this view is in, and the observation of its offset.
    private weak var scrollView: UIScrollView? = nil
    private var offsetObservation: NSKeyValueObservation? = nil

    /// A place the scroll view is to be put at once the layout allows it, and when to give up.
    /// `oldWidth` is the width this view had when the place was taken, if the place is to be
    /// restored after the width changed.
    private var pending: (place: MarkdownReadingPosition.Place, oldWidth: CGFloat?)? = nil
    private var pendingDeadline: TimeInterval = 0

    /// The place the scroll view was last put at after a width change, the width of this view
    /// then, and until when the reader can be assumed to still be there. The width keeps changing
    /// while the reader drags a divider. What the view shows then is a layout for one width at an
    /// offset that was set for another one, so it does not tell where the reader is.
    private var restored: (place: MarkdownReadingPosition.Place, width: CGFloat, until: TimeInterval)? = nil

    /// The sizes of this view and of its scroll view when they were last found to be out of step,
    /// and since when they have not changed. See `moveScrollView(to:oldWidth:)`.
    private var settling: (state: CGSize, since: TimeInterval)? = nil

    /// Set to true while the scroll view is moved to a place.
    private var isRestoring = false

    override init(frame: CGRect, textContainer: NSTextContainer?) {
      super.init(frame: frame, textContainer: textContainer)
      self.spinner.hidesWhenStopped = true
      self.addSubview(self.spinner)
    }

    required init?(coder: NSCoder) {
      super.init(coder: coder)
      self.spinner.hidesWhenStopped = true
      self.addSubview(self.spinner)
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
      guard self.maxLayoutWidth > 0 else {
        return super.intrinsicContentSize
      }
      var size = self.sizeThatFits(CGSize(width: maxLayoutWidth,
                                          height: .greatestFiniteMagnitude))
      if self.isLoading {
        size.height = max(size.height, TextView.loadingHeight)
      }
      return size
    }

    /// Shows `text`, the text of `content`, and the list markers in it. If this replaces the text
    /// of another document, the reader starts at the beginning of the new one. A new text for the
    /// same document, e.g. with the diagrams that were rendered in the meantime, keeps the place;
    /// so does a document that was replaced in place by an equal one.
    func setContent(_ text: NSAttributedString, content: MarkdownTextContent?) {
      self.endLoading()
      var replaced = false
      if let shown = self.shownContent, let content {
        replaced = !shown.hasSameText(as: content)
      }
      self.shownContent = content
      self.restored = nil
      self.attributedText = text
      self.pairs = ListMarkers.pairs(in: text)
      self.invalidateIntrinsicContentSize()
      if replaced {
        self.scrollToStart()
      }
    }

    override func didMoveToWindow() {
      super.didMoveToWindow()
      self.observeScrollView()
      self.retryRestore()
    }

    override func layoutSubviews() {
      super.layoutSubviews()
      self.spinner.center = CGPoint(x: self.bounds.midX, y: TextView.loadingHeight / 2)
      if !self.pairs.isEmpty && !self.isAligning {
        self.isAligning = true
        defer {
          self.isAligning = false
        }
        let layout = self.layoutManager
        layout.ensureLayout(for: self.textContainer)
        ListMarkers.align(self.textStorage, layoutManager: layout, pairs: pairs)
      }
      self.retryRestore()
    }

    // MARK: Waiting for the first text

    /// Reserves room for a spinner, which appears if the text takes a moment.
    func beginLoading() {
      guard !self.isLoading else {
        return
      }
      self.isLoading = true
      self.invalidateIntrinsicContentSize()
      let start = DispatchWorkItem { [weak self] in
        if let self, self.isLoading {
          self.spinner.startAnimating()
        }
      }
      self.spinnerStart = start
      DispatchQueue.main.asyncAfter(deadline: .now() + TextView.spinnerDelay, execute: start)
    }

    private func endLoading() {
      guard self.isLoading else {
        return
      }
      self.isLoading = false
      self.spinnerStart?.cancel()
      self.spinnerStart = nil
      self.spinner.stopAnimating()
      self.invalidateIntrinsicContentSize()
    }

    // MARK: Reading position

    /// Finds the scroll view this view is in. Its offset is observed if the place of the reader
    /// is to be remembered.
    private func observeScrollView() {
      self.offsetObservation = nil
      self.scrollView = nil
      guard self.window != nil else {
        return
      }
      var ancestor = self.superview
      while let view = ancestor {
        if let scrollView = view as? UIScrollView {
          self.scrollView = scrollView
          break
        }
        ancestor = view.superview
      }
      if self.position != nil {
        self.offsetObservation = self.scrollView?.observe(\.contentOffset, options: []) {
          [weak self] scrollView, _ in
          MainActor.assumeIsolated {
            self?.scrolled(scrollView)
          }
        }
      }
    }

    /// Remembers the place of the reader when they move the text. Moves by the system, which
    /// happen when the geometry changes, are not what the reader wants to get back to.
    private func scrolled(_ scrollView: UIScrollView) {
      guard !self.isRestoring,
            scrollView.isTracking || scrollView.isDragging || scrollView.isDecelerating else {
        return
      }
      self.pending = nil
      self.restored = nil
      if let place = self.currentPlace() {
        self.position?.record(place)
      }
    }

    /// Returns the place at the top of the visible area of the scroll view.
    func currentPlace() -> MarkdownReadingPosition.Place? {
      guard let scrollView = self.scrollView,
            let content = self.shownContent,
            self.textStorage.length > 0,
            self.bounds.width > 0 else {
        return nil
      }
      let visibleTop = CGPoint(x: scrollView.bounds.minX,
                               y: scrollView.bounds.minY + scrollView.adjustedContentInset.top)
      let y = scrollView.convert(visibleTop, to: self).y - self.textContainerInset.top
      if y <= 0 {
        return MarkdownReadingPosition.Place(content: content, index: 0, fraction: 0, atTop: true)
      }
      let layout = self.layoutManager
      layout.ensureLayout(for: self.textContainer)
      let point = CGPoint(x: 0, y: min(y, self.bounds.height - 1))
      let index = layout.characterIndex(for: point,
                                        in: self.textContainer,
                                        fractionOfDistanceBetweenInsertionPoints: nil)
      let line = layout.lineFragmentRect(forGlyphAt: layout.glyphIndexForCharacter(at: index),
                                         effectiveRange: nil)
      let fraction = line.height > 0 ? min(max((point.y - line.minY) / line.height, 0), 1) : 0
      return MarkdownReadingPosition.Place(content: content,
                                           index: index,
                                           fraction: fraction,
                                           atTop: false)
    }

    /// Puts the scroll view at the start of the text, and forgets what was to be restored.
    private func scrollToStart() {
      self.pending = nil
      self.restored = nil
      guard let scrollView = self.scrollView else {
        return
      }
      self.isRestoring = true
      scrollView.setContentOffset(CGPoint(x: scrollView.contentOffset.x,
                                          y: -scrollView.adjustedContentInset.top),
                                  animated: false)
      self.isRestoring = false
    }

    /// Takes the place of the reader, to put them back to it after the width of this view
    /// changed.
    func keepPlaceForWidthChange() {
      if self.pending != nil {
        // The width is still changing, e.g. while the reader drags a divider: the place taken
        // first is the one to get back to, and the layout needs more time to settle
        self.pendingDeadline = CACurrentMediaTime() + TextView.restoreTimeout
        return
      }
      if let restored = self.restored, CACurrentMediaTime() < restored.until {
        self.restore(restored.place, oldWidth: restored.width)
        return
      }
      if let place = self.currentPlace() {
        self.restore(place, oldWidth: self.bounds.width)
      }
    }

    /// Puts the scroll view at `place` as soon as the layout of this view has caught up.
    func restore(_ place: MarkdownReadingPosition.Place, oldWidth: CGFloat?) {
      self.pending = (place, oldWidth)
      self.pendingDeadline = CACurrentMediaTime() + TextView.restoreTimeout
      self.settling = nil
      self.retryRestore()
    }

    private func retryRestore() {
      guard let pending = self.pending else {
        return
      }
      if CACurrentMediaTime() > self.pendingDeadline {
        self.pending = nil
      } else if let scrollView = self.scrollView,
                scrollView.isTracking || scrollView.isDragging || scrollView.isDecelerating {
        self.pending = nil
      } else if self.moveScrollView(to: pending.place, oldWidth: pending.oldWidth) {
        self.pending = nil
      } else {
        // SwiftUI sizes the views a moment later
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
          self?.retryRestore()
        }
      }
    }

    /// Moves the scroll view such that `place` is at the top of its visible area. Returns false
    /// if the layout is not ready for that yet.
    private func moveScrollView(to place: MarkdownReadingPosition.Place,
                                oldWidth: CGFloat?) -> Bool {
      guard let scrollView = self.scrollView,
            self.window != nil,
            self.textStorage.length > 0,
            self.bounds.width > 0 else {
        return false
      }
      if let oldWidth, abs(self.bounds.width - oldWidth) < 0.5 {
        // The new width has not arrived yet
        return false
      }
      let layout = self.layoutManager
      layout.ensureLayout(for: self.textContainer)
      let frame = self.convert(self.bounds, to: scrollView)
      guard layout.usedRect(for: self.textContainer).maxY <= self.bounds.height + 1 else {
        // This view has not been resized for the text yet
        return false
      }
      if scrollView.contentSize.height < frame.maxY - 1 {
        // The scroll view has not been resized for this view yet. It might also end short of this
        // view on purpose, e.g. if a negative padding cuts off a margin. In this case, the layout
        // is ready once the sizes have not changed for a moment.
        let state = CGSize(width: self.bounds.height, height: scrollView.contentSize.height)
        let now = CACurrentMediaTime()
        guard let settling = self.settling, settling.state == state else {
          self.settling = (state, now)
          return false
        }
        guard now - settling.since >= TextView.settleTime else {
          return false
        }
      }
      self.settling = nil
      let inset = scrollView.adjustedContentInset
      var offset = -inset.top
      if !place.atTop {
        let index = min(place.index, self.textStorage.length - 1)
        let line = layout.lineFragmentRect(forGlyphAt: layout.glyphIndexForCharacter(at: index),
                                           effectiveRange: nil)
        let y = line.minY + place.fraction * line.height + self.textContainerInset.top
        offset = self.convert(CGPoint(x: 0, y: y), to: scrollView).y - inset.top
      }
      let lowest = -inset.top
      let highest = max(scrollView.contentSize.height - scrollView.bounds.height + inset.bottom,
                        lowest)
      offset = min(max(offset, lowest), highest)
      self.isRestoring = true
      scrollView.setContentOffset(CGPoint(x: scrollView.contentOffset.x, y: offset),
                                  animated: false)
      self.isRestoring = false
      self.restored = (place, self.bounds.width, CACurrentMediaTime() + TextView.restoreTimeout)
      return true
    }
  }

  @MainActor
  final class Coordinator: NSObject, UITextViewDelegate {
    var openURLProc: OpenURLAction? = nil

    /// Receives the size of the text whenever it has changed.
    var sizeSink: MutableSize? = nil

    /// The view that shows the text.
    weak var textView: TextView? = nil

    /// Generates the text of the view; the result is shown with `show(_:)`.
    let renderer: MarkdownTextRenderer

    /// The document the text is requested for, and where the reader is in it.
    var requestedContent: MarkdownTextContent? = nil
    var position: MarkdownReadingPosition? = nil

    private var sizeUpdatePending = false

    override init() {
      self.renderer = MarkdownTextRenderer(passes: { DocumentationPasses.passes(for: $0) })
      super.init()
      self.renderer.onText = { [weak self] text in
        self?.show(text)
      }
    }

    private func show(_ text: NSAttributedString) {
      guard let textView = self.textView else {
        return
      }
      let isFirst = textView.shownContent == nil
      textView.setContent(text, content: self.requestedContent)
      if isFirst,
         let place = self.position?.place,
         let content = self.requestedContent,
         place.content.hasSameText(as: content) {
        // The view was created again for the document the reader was in
        textView.restore(place, oldWidth: nil)
      }
      self.scheduleSizeUpdate()
    }

    /// Publishes the size of the text after the current update of the view hierarchy (it must
    /// not be published from within `updateUIView`).
    func scheduleSizeUpdate() {
      guard !self.sizeUpdatePending else {
        return
      }
      self.sizeUpdatePending = true
      Task { @MainActor [weak self] in
        guard let self else {
          return
        }
        self.sizeUpdatePending = false
        if let textView = self.textView, let sink = self.sizeSink {
          let size = textView.intrinsicContentSize
          if sink.size != size {
            sink.size = size
          }
        }
      }
    }

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

  let content: MarkdownTextContent
  let maxLayoutWidth: CGFloat
  let intrinsicContentSize: MutableSize
  let rightPadding: Int
  let position: MarkdownReadingPosition?

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
    view.position = self.position
    context.coordinator.textView = view
    /* view.linkTextAttributes = [
      .foregroundColor: UIColor.systemBlue,
      .underlineStyle: NSUnderlineStyle.single.rawValue
    ] */
    return view
  }

  static func dismantleUIView(_ uiView: TextView, coordinator: Coordinator) {
    coordinator.renderer.cancel()
  }

  func updateUIView(_ uiView: TextView, context: Context) {
    let coordinator = context.coordinator
    coordinator.textView = uiView
    coordinator.sizeSink = self.intrinsicContentSize
    coordinator.openURLProc = context.environment.openURL
    coordinator.requestedContent = self.content
    coordinator.position = self.position
    uiView.position = self.position
    // Web views, which render diagrams, formulas and images, do not work in the background. The
    // request is only registered once it can be served, so the view renders after returning.
    if context.environment.scenePhase != .background {
      coordinator.renderer.update(MarkdownTextRequest(content: self.content,
                                                      colorScheme: context.environment.colorScheme,
                                                      rightPadding: self.rightPadding,
                                                      fonts: .current))
      if uiView.textStorage.length == 0 {
        // There is nothing to show until the first pass is done
        uiView.beginLoading()
        coordinator.scheduleSizeUpdate()
      }
    }
    // The text does not depend on the geometry: it only has to be laid out again, and the reader
    // is put back to where they were in the text
    if uiView.maxLayoutWidth > 0 && abs(uiView.maxLayoutWidth - self.maxLayoutWidth) >= 0.5 {
      uiView.keepPlaceForWidthChange()
    }
    let lineLimit = context.environment.lineLimit ?? 0
    let needsMeasuring = uiView.maxLayoutWidth != self.maxLayoutWidth ||
                         uiView.textContainer.maximumNumberOfLines != lineLimit
    uiView.maxLayoutWidth = self.maxLayoutWidth
    uiView.textContainer.maximumNumberOfLines = lineLimit
    uiView.textContainer.lineBreakMode = .byWordWrapping
    if needsMeasuring {
      coordinator.scheduleSizeUpdate()
    }
  }
}


// MARK: - Requests

/// The Markdown document of a view.
struct MarkdownTextContent {

  /// Identifies a `MutableBlock` and the state of its document.
  struct Revision: Equatable {
    let owner: ObjectIdentifier
    let version: Int
  }

  let block: Block?

  /// Set if the document is replaced in place; then the revision decides whether the document
  /// is the same, otherwise the documents are compared.
  let revision: Revision?

  func isSame(as other: MarkdownTextContent) -> Bool {
    switch (self.revision, other.revision) {
      case (nil, nil):
        return self.block == other.block
      case (let this?, let that?):
        return this == that
      default:
        return false
    }
  }

  /// True if both show the same text, even if the document was replaced in place by an equal one.
  func hasSameText(as other: MarkdownTextContent) -> Bool {
    return self.isSame(as: other) || self.block == other.block
  }
}

/// The documentation font sizes, which are part of the generated text.
struct DocumentationFonts: Equatable {
  let text: Float
  let code: Float
  let library: Float

  static var current: DocumentationFonts {
    return DocumentationFonts(text: UserSettings.standard.documentationTextFontSize,
                              code: UserSettings.standard.documentationCodeFontSize,
                              library: UserSettings.standard.documentationLibraryFontSize)
  }
}

/// Everything that makes a different text. The geometry of the view is not part of it: the text
/// is laid out for any width by the text view.
struct MarkdownTextRequest {
  let content: MarkdownTextContent
  let colorScheme: ColorScheme
  let rightPadding: Int
  let fonts: DocumentationFonts

  func isSame(as other: MarkdownTextRequest) -> Bool {
    return self.colorScheme == other.colorScheme &&
           self.rightPadding == other.rightPadding &&
           self.fonts == other.fonts &&
           self.content.isSame(as: other.content)
  }
}


// MARK: - Renderer

/// Generates the text of a view in up to three passes, so that it appears quickly:
///
///  1. `quick` generates the text without waiting for anything: Mermaid diagrams and formulas
///     that have not been rendered yet are shown as code, remote images are left out.
///  2. `prepare` renders the diagrams and formulas in the background.
///  3. If that rendered something, or if the document has remote images, `full` generates the
///     text again, now with everything, and replaces the first text.
///
/// If the diagrams and formulas are cached already and there are no remote images, the first text
/// is the final one. A request that is the same as the current one is ignored, a different one
/// cancels the current one, and the result of a cancelled request is never shown.
@MainActor
final class MarkdownTextRenderer {

  /// The generators for the passes. The text is `NSAttributedString` because that is what a
  /// generator returns.
  struct Passes {
    var quick: (Block) async throws -> NSAttributedString
    var prepare: (Block) async -> Bool
    var full: (Block) async throws -> NSAttributedString
  }

  private let cache: MarkdownTextCache
  private let makePasses: (MarkdownTextRequest) -> Passes
  private var current: MarkdownTextRequest? = nil
  private var task: Task<Void, Never>? = nil
  private var generation = 0

  /// Called with each text that is to be shown.
  var onText: ((NSAttributedString) -> Void)? = nil

  init(cache: MarkdownTextCache? = nil, passes: @escaping (MarkdownTextRequest) -> Passes) {
    self.cache = cache ?? .shared
    self.makePasses = passes
  }

  /// Makes sure that the text for `request` is, or will be, shown.
  func update(_ request: MarkdownTextRequest) {
    if let current = self.current, current.isSame(as: request) {
      return
    }
    self.task?.cancel()
    self.task = nil
    self.generation += 1
    self.current = request
    if let text = self.cache.text(for: request) {
      self.onText?(text)
    } else if let block = request.content.block {
      let generation = self.generation
      let passes = self.makePasses(request)
      self.task = Task { [weak self] in
        await self?.run(request, block: block, passes: passes, generation: generation)
      }
    } else {
      self.onText?(NSAttributedString(string: "Content not available"))
    }
  }

  /// Stops generating. A later `update` starts again.
  func cancel() {
    self.task?.cancel()
    self.task = nil
    self.generation += 1
    self.current = nil
  }

  private func isCurrent(_ generation: Int) -> Bool {
    return self.generation == generation && !Task.isCancelled
  }

  private func run(_ request: MarkdownTextRequest,
                   block: Block,
                   passes: Passes,
                   generation: Int) async {
    let first: NSAttributedString
    do {
      first = try await passes.quick(block)
    } catch {
      if self.isCurrent(generation) {
        self.onText?(NSAttributedString(string: error.localizedDescription))
      }
      return
    }
    guard self.isCurrent(generation) else {
      return
    }
    self.onText?(first)
    let rendered = await passes.prepare(block)
    guard self.isCurrent(generation) else {
      return
    }
    guard rendered || block.containsRemoteImages else {
      self.cache.store(first, for: request)
      return
    }
    do {
      let final = try await passes.full(block)
      guard self.isCurrent(generation) else {
        return
      }
      self.onText?(final)
      self.cache.store(final, for: request)
    } catch {
      // The first text stays; it has everything but the diagrams, formulas and remote images
    }
  }
}

/// Keeps the final texts of the last documents, so that a view that is created again (for
/// example by navigating back) shows its text at once. Only documents given as values are
/// cached, since the identity of a document that is replaced in place says nothing about it.
@MainActor
final class MarkdownTextCache {
  static let shared = MarkdownTextCache(capacity: 4)

  private let capacity: Int
  private var entries: [(request: MarkdownTextRequest, text: NSAttributedString)] = []
  private var memoryWarning: NSObjectProtocol? = nil

  init(capacity: Int) {
    self.capacity = capacity
    self.memoryWarning = NotificationCenter.default.addObserver(
        forName: UIApplication.didReceiveMemoryWarningNotification,
        object: nil,
        queue: .main) { [weak self] _ in
      MainActor.assumeIsolated {
        self?.entries.removeAll()
      }
    }
  }

  deinit {
    if let observer = self.memoryWarning {
      NotificationCenter.default.removeObserver(observer)
    }
  }

  func text(for request: MarkdownTextRequest) -> NSAttributedString? {
    guard request.content.revision == nil,
          let index = self.entries.firstIndex(where: { $0.request.isSame(as: request) }) else {
      return nil
    }
    let entry = self.entries.remove(at: index)
    self.entries.append(entry)
    return entry.text
  }

  func store(_ text: NSAttributedString, for request: MarkdownTextRequest) {
    guard request.content.revision == nil, request.content.block != nil else {
      return
    }
    self.entries.removeAll { $0.request.isSame(as: request) }
    self.entries.append((request, text))
    if self.entries.count > self.capacity {
      self.entries.removeFirst(self.entries.count - self.capacity)
    }
  }
}


// MARK: - Remote images

extension Block {

  /// True if the block contains an image that is loaded from the web. Such images are not
  /// loaded by the first pass.
  var containsRemoteImages: Bool {
    switch self {
      case .document(let blocks),
           .blockquote(let blocks),
           .list(_, _, let blocks),
           .listItem(_, _, let blocks):
        return blocks.contains { $0.containsRemoteImages }
      case .paragraph(let text),
           .heading(_, let text):
        return text.containsRemoteImages
      case .table(let header, _, let rows):
        return header.contains { $0.containsRemoteImages } ||
               rows.contains { row in row.contains { $0.containsRemoteImages } }
      case .definitionList(let definitions):
        return definitions.contains { definition in
          definition.item.containsRemoteImages ||
          definition.descriptions.contains { $0.containsRemoteImages }
        }
      default:
        return false
    }
  }
}

extension MarkdownKit.Text {
  var containsRemoteImages: Bool {
    return self.contains { $0.containsRemoteImages }
  }
}

extension TextFragment {
  var containsRemoteImages: Bool {
    switch self {
      case .emph(let text),
           .strong(let text),
           .underline(let text),
           .strikethrough(let text),
           .link(let text, _, _):
        return text.containsRemoteImages
      case .image(_, let uri, _):
        guard let uri = uri?.lowercased() else {
          return false
        }
        return uri.hasPrefix("http://") || uri.hasPrefix("https://")
      default:
        return false
    }
  }
}


// MARK: - Generators

private enum DocumentationFont {
  static let text = "system-ui, -apple-system, 'Helvetica Neue', Helvetica, sans-serif"
  static let code = "'SF Mono', SFMono-Regular, ui-monospace, Menlo, Consolas, monospace"
  static let library = "system-ui, -apple-system, 'Helvetica Neue', Helvetica, sans-serif"
}

/// Generates the attributed strings of the documentation. The text does not depend on the width of
/// the view: Mermaid diagrams are laid out on a page of a fixed width, and the diagrams, formulas
/// and images scale themselves to the width of their line when the text is laid out.
///
/// A generator that `prepares` renders all diagrams and formulas of a document before it
/// generates the text (this takes time), and shows all of them. One that does not generate the
/// text at once, and shows the diagrams and formulas that are in the caches of the renderers.
private final class DocumentationStringGenerator: MathAttributedStringGenerator,
                                                  @unchecked Sendable {
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

  /// The width in points of the page which Mermaid lays diagrams out on. It is part of the key of
  /// the cache of the renderer, so it must not depend on the size of the view. The size of a
  /// diagram in the text is limited by `MermaidConfig.maxWidth` and by the width of the text.
  static let diagramPageWidth: CGFloat = 800

  /// What the first pass loads: everything but the images from the web, which can take long.
  static let quickOptions = RenderingOptions(baseUrl: nil,
                                             timeout: RenderingOptions.defaultTimeout,
                                             localImages: .any,
                                             remoteImages: .none,
                                             imageExtensions: RenderingOptions.defaultImageExtensions,
                                             safeMode: false,
                                             textSizeMultiplier: nil)

  /// What the final text loads.
  static let fullOptions = RenderingOptions(baseUrl: nil,
                                            timeout: RenderingOptions.defaultTimeout,
                                            localImages: .any,
                                            remoteImages: .any,
                                            imageExtensions: RenderingOptions.defaultImageExtensions,
                                            safeMode: false,
                                            textSizeMultiplier: nil)

  let rightPadding: Int
  let libraryFontSize: Float
  let prepares: Bool

  init(dark: Bool, rightPadding: Int, fonts: DocumentationFonts, prepares: Bool) {
    self.rightPadding = rightPadding
    self.libraryFontSize = fonts.library
    self.prepares = prepares
    super.init(version: .OS26,
               fontSize: fonts.text,
               fontFamily: DocumentationFont.text,
               fontColor: dark ? "#fff" : "#000",
               codeFontSize: fonts.code,
               codeFontFamily: DocumentationFont.code,
               codeFontColor: dark ? "#ccddff" : "#0000aa",
               codeBlockFontSize: fonts.code,
               codeBlockFontColor: dark ? "#aaddff" : "#000099",
               codeBlockBackground: dark ? "#333" : "#eee",
               syntaxHighlighting: dark ? .defaultDark : .default,
               syntaxHighlighter: DocumentationStringGenerator.highlighter,
               mermaid: MermaidConfig(theme: dark ? .dark : .default,
                                      themeVariables: [:],
                                      fontFamily: nil,
                                      scale: 2,
                                      width: DocumentationStringGenerator.diagramPageWidth,
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
               borderColor: dark ? "#333" : "#eee",
               blockquoteColor: dark ? "#fff" : "#000",
               h1Color: "#aa1111",
               h2Color: "#007aff",
               h3Color: "#007aff",
               h4Color: "#007aff",
               imageBaseUrl: Self.localBaseUrl,
               alignListMarkers: true,
               renderingOptions: Self.fullOptions)
  }

  override var needsPreparation: Bool {
    return self.prepares && super.needsPreparation
  }

  private class DocumentationHtmlGenerator: MathOS26HtmlGenerator, @unchecked Sendable {
    let rightPadding: Int
    let libraryFontSize: Float

    override init(outer: AttributedStringGenerator, renderingOptions: RenderingOptions) {
      let generator = outer as! DocumentationStringGenerator
      self.rightPadding = generator.rightPadding
      self.libraryFontSize = generator.libraryFontSize
      super.init(outer: outer, renderingOptions: renderingOptions)
    }

    override func generate(block: Block, parent: Parent, tight: Bool = false) -> String {
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
                 "<tr style=\"height: 15px; font-family: " + DocumentationFont.library +
                 "; font-size: \(self.libraryFontSize); " +
                 "font-style: italic;\">" +
                 "<td style=\"text-align: left;\">" + lib + "</td>" +
                 "<td style=\"text-align: right;padding-right: \(self.rightPadding)px;\">" +
                 type + "</td></tr></tbody></table><br/>\n"
        default:
          return super.generate(block: block, parent: parent, tight: tight)
      }
    }
  }

  override func htmlGenerator(options: RenderingOptions? = nil) -> InternalHtmlGenerator {
    return DocumentationHtmlGenerator(outer: self,
                                      renderingOptions: options ?? self.renderingOptions)
  }

  override var codeBoxStyle: String {
    return "background: \(self.codeBlockBackground);" +
           "width: 100%;" +
           "border: 1px solid \(self.borderColor);" +
           "padding: 0.3em;"
  }
}

/// Creates the generators and passes for the documentation. The generators are reused: creating
/// one configures the syntax highlighter, which is not free.
@MainActor
enum DocumentationPasses {
  private struct Key: Hashable {
    let dark: Bool
    let rightPadding: Int
    let text: Float
    let code: Float
    let library: Float
  }

  private static var generators: [Key: (quick: DocumentationStringGenerator,
                                         full: DocumentationStringGenerator)] = [:]

  static func passes(for request: MarkdownTextRequest) -> MarkdownTextRenderer.Passes {
    let key = Key(dark: request.colorScheme == .dark,
                  rightPadding: request.rightPadding,
                  text: request.fonts.text,
                  code: request.fonts.code,
                  library: request.fonts.library)
    let generators: (quick: DocumentationStringGenerator, full: DocumentationStringGenerator)
    if let existing = self.generators[key] {
      generators = existing
    } else {
      generators = (DocumentationStringGenerator(dark: key.dark,
                                                 rightPadding: key.rightPadding,
                                                 fonts: request.fonts,
                                                 prepares: false),
                    DocumentationStringGenerator(dark: key.dark,
                                                 rightPadding: key.rightPadding,
                                                 fonts: request.fonts,
                                                 prepares: true))
      self.generators[key] = generators
    }
    let (quick, full) = generators
    return MarkdownTextRenderer.Passes(
      quick: { block in
        try await quick.generateAsync(doc: block,
                                      options: DocumentationStringGenerator.quickOptions,
                                      scaleImages: true)
      },
      prepare: { block in
        async let diagrams = full.prepareDiagrams(in: block)
        async let formulas = full.prepareMath(in: block)
        let renderedDiagrams = await diagrams
        let renderedFormulas = await formulas
        return renderedDiagrams || renderedFormulas
      },
      full: { block in
        try await full.generateAsync(doc: block, scaleImages: true)
      })
  }
}
