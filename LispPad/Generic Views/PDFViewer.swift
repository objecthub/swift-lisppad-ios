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
  
  let url: URL
  let viewSize: CGSize
  
  func makeUIView(context: Context) -> MyPDFView {
    let pdfView = MyPDFView()
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
    pdfView.document = PDFDocument(url: self.url)
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
  }
  
  class MyPDFView: PDFView {
    var viewSize: CGSize = CGSize(width: 0, height: 0)
    
    func setPageLabel() {
      // Remove old label
      for view in self.subviews {
        if view.isKind(of: UILabel.self) {
          view.removeFromSuperview()
        }
      }
      // Add new label
      let pageLabel = UILabel(frame: CGRect(x: viewSize.width - 108, y: 4, width: 100, height: 20))
      pageLabel.font = UIFont.systemFont(ofSize: 14.0)
      pageLabel.textAlignment = .right
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
