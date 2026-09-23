//
//  PDFViewer.swift
//  LispPad
//
//  Created by Matthias Zenger on 10/04/2021.
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
import PDFKit

struct PDFViewer: UIViewRepresentable {
  private static let thumbnailSize = CGSize(width: 40, height: 54)
  
  /// Gives SwiftUI views outside of the viewer access to the underlying `PDFView`, e.g.
  /// for navigating via the outline or for searching the document.
  final class Controller: NSObject, ObservableObject, PDFDocumentDelegate {
    private static let highlightColor = UIColor.systemYellow.withAlphaComponent(0.4)
    private static let currentHighlightColor = UIColor.systemOrange.withAlphaComponent(0.6)
    
    fileprivate weak var pdfView: PDFView? {
      didSet {
        // The view is set from within SwiftUI view updates (`makeUIView`/`updateUIView`)
        // where publishing changes is not allowed, so resetting the search state of a
        // previous view gets deferred. The initial assignment has nothing to reset.
        if oldValue != nil && self.pdfView !== oldValue {
          oldValue?.document?.cancelFindString()
          DispatchQueue.main.async {
            self.clearSearch()
          }
        }
      }
    }
    
    /// All text segments matching the last search term, in document order.
    @Published private(set) var matches: [PDFSelection] = []
    
    /// The index of the currently selected match in `matches`, if any.
    @Published private(set) var currentMatch: Int? = nil
    
    /// Is a search currently in progress?
    @Published private(set) var searching: Bool = false
    
    /// The search term for which `matches` were found; nil if there was no search yet.
    @Published private(set) var searchTerm: String? = nil
    
    /// The index of the page on which the last search started. The first match on or
    /// after this page is selected first.
    private var startPageIndex: Int = 0
    
    override init() {
      super.init()
      NotificationCenter.default.addObserver(
        self,
        selector: #selector(self.handleFindEnded(notification:)),
        name: Notification.Name.PDFDocumentDidEndFind,
        object: nil)
    }
    
    deinit {
      NotificationCenter.default.removeObserver(self)
      self.pdfView?.document?.cancelFindString()
    }
    
    /// Returns the destination an outline entry is linked to, if any.
    static func destination(of outline: PDFOutline) -> PDFDestination? {
      return outline.destination ?? (outline.action as? PDFActionGoTo)?.destination
    }
    
    /// Jumps to the destination the given outline entry is linked to.
    func go(to outline: PDFOutline) {
      guard let pdfView = self.pdfView,
            let destination = Controller.destination(of: outline) else {
        return
      }
      if let page = destination.page {
        pdfView.go(to: page)
      } else {
        pdfView.go(to: destination)
      }
    }
    
    /// Starts an asynchronous, case-insensitive search for `term`. Matches are
    /// collected as they are found; the first match on or after the current page
    /// gets selected.
    func search(_ term: String) {
      self.clearSearch()
      guard !term.isEmpty,
            let pdfView = self.pdfView,
            let document = pdfView.document else {
        return
      }
      self.searchTerm = term
      self.searching = true
      if let page = pdfView.currentPage {
        self.startPageIndex = document.index(for: page)
      } else {
        self.startPageIndex = 0
      }
      document.delegate = self
      document.beginFindString(term, withOptions: [.caseInsensitive])
    }
    
    /// Cancels an ongoing search and removes all search highlights.
    func clearSearch() {
      if let document = self.pdfView?.document {
        document.cancelFindString()
        document.delegate = nil
      }
      self.pdfView?.highlightedSelections = nil
      // Reset synchronously: `search` relies on this state being cleared before it
      // sets up a new search
      self.matches = []
      self.currentMatch = nil
      self.searching = false
      self.searchTerm = nil
    }
    
    /// Selects the next match, wrapping around at the end of the document.
    func nextMatch() {
      guard !self.matches.isEmpty else {
        return
      }
      self.select(match: ((self.currentMatch ?? -1) + 1) % self.matches.count)
    }
    
    /// Selects the previous match, wrapping around at the beginning of the document.
    func previousMatch() {
      guard !self.matches.isEmpty else {
        return
      }
      let current = self.currentMatch ?? 0
      self.select(match: (current + self.matches.count - 1) % self.matches.count)
    }
    
    private func select(match index: Int) {
      guard index >= 0 && index < self.matches.count, let pdfView = self.pdfView else {
        return
      }
      self.currentMatch = index
      self.updateHighlights()
      pdfView.go(to: self.matches[index])
    }
    
    /// Highlights all matches, using a different color for the current match. `PDFView`
    /// doesn't redraw if `highlightedSelections` is set to the same selection objects
    /// again (even if their colors changed), so fresh copies are passed in every time.
    private func updateHighlights() {
      guard let pdfView = self.pdfView else {
        return
      }
      var highlights: [PDFSelection] = []
      highlights.reserveCapacity(self.matches.count)
      for (i, match) in self.matches.enumerated() {
        let highlight = match.copy() as? PDFSelection ?? match
        highlight.color = i == self.currentMatch ? Controller.currentHighlightColor
                                                 : Controller.highlightColor
        highlights.append(highlight)
      }
      pdfView.highlightedSelections = nil
      pdfView.highlightedSelections = highlights
    }
    
    private func pageIndex(of selection: PDFSelection) -> Int? {
      guard let document = self.pdfView?.document,
            let page = selection.pages.first else {
        return nil
      }
      return document.index(for: page)
    }
    
    // PDFDocumentDelegate
    
    func didMatchString(_ instance: PDFSelection) {
      DispatchQueue.main.async {
        guard self.searchTerm != nil else {
          return
        }
        self.matches.append(instance)
        if self.currentMatch == nil,
           let index = self.pageIndex(of: instance),
           index >= self.startPageIndex {
          self.select(match: self.matches.count - 1)
        }
      }
    }
    
    @objc private func handleFindEnded(notification: Notification) {
      DispatchQueue.main.async {
        guard self.searching,
              let document = notification.object as? PDFDocument,
              document === self.pdfView?.document,
              !document.isFinding else {
          return
        }
        self.searching = false
        self.updateHighlights()
        if self.currentMatch == nil && !self.matches.isEmpty {
          self.select(match: 0)
        }
      }
    }
  }
  
  let document: PDFDocument?
  let viewSize: CGSize
  var controller: Controller? = nil
  var showsPageLabel: Bool = true
  
  func makeUIView(context: Context) -> MyPDFView {
    let pdfView = MyPDFView()
    self.controller?.pdfView = pdfView
    pdfView.viewSize = self.viewSize
    pdfView.pageBreakMargins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    pdfView.autoresizesSubviews = true
    pdfView.autoresizingMask = [.flexibleWidth,
                                .flexibleHeight,
                                .flexibleTopMargin,
                                .flexibleLeftMargin]
    pdfView.displayDirection = .horizontal
    pdfView.autoScales = true
    pdfView.displayMode = .singlePageContinuous
    pdfView.displaysPageBreaks = true
    pdfView.pageShadowsEnabled = false
    pdfView.document = self.document
    pdfView.usePageViewController(true)
    let thumbnailView = PDFThumbnailView(
      frame: CGRect(x: 0,
                    y: self.viewSize.height - PDFViewer.thumbnailSize.height - 8,
                    width: viewSize.width,
                    height: PDFViewer.thumbnailSize.height))
    thumbnailView.backgroundColor = UIColor.clear
    thumbnailView.thumbnailSize = PDFViewer.thumbnailSize
    thumbnailView.layoutMode = .horizontal
    thumbnailView.pdfView = pdfView
    pdfView.addSubview(thumbnailView)
    pdfView.setPageLabel()
    NotificationCenter.default.addObserver(
      pdfView,
      selector: #selector(pdfView.handlePageChange(notification:)),
      name: Notification.Name.PDFViewPageChanged,
      object: nil)
    return pdfView
  }

  func updateUIView(_ pdfView: MyPDFView, context: Context) {
    pdfView.viewSize = self.viewSize
    pdfView.showsPageLabel = self.showsPageLabel
    self.controller?.pdfView = pdfView
  }
  
  class MyPDFView: PDFView {
    var viewSize: CGSize = CGSize(width: 0, height: 0)
    
    var showsPageLabel: Bool = true {
      didSet {
        if self.showsPageLabel != oldValue {
          self.setPageLabel()
        }
      }
    }
    
    func setPageLabel() {
      // Remove old label
      for view in self.subviews {
        if view.isKind(of: UILabel.self) {
          view.removeFromSuperview()
        }
      }
      // Add new label
      let pageLabel = UILabel(frame: CGRect(x: 0, y: 4, width: self.viewSize.width, height: 20))
      pageLabel.font = UIFont.systemFont(ofSize: 14.0)
      pageLabel.textAlignment = .center
      pageLabel.isHidden = !self.showsPageLabel
      pageLabel.text = String(format: "%@ of %d",
                                    self.currentPage?.label ?? "0",
                                    self.document?.pageCount ?? 0)
      self.addSubview(pageLabel)
    }
    
    @objc func handlePageChange(notification: Notification) {
      self.setPageLabel()
    }
  }
}
