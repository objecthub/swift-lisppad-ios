//
//  CodeEditorTextView.swift
//  LispPad
//
//  Created by Matthias Zenger on 28/03/2021.
//

import UIKit

class CodeEditorTextView: UITextView {
  private static let gutterWidth: CGFloat = 40.0
  
  let textStorageDelegate: CodeEditorTextStorageDelegate
  
  var codingFont: UIFont {
    get {
      let lm = self.layoutManager as! CodeEditorLayoutManager
      return lm.codingFont
    }
    set(newFont) {
      let lm = self.layoutManager as! CodeEditorLayoutManager
      if !lm.codingFont.isEqual(newFont) {
        lm.codingFont = newFont
        self.setNeedsDisplay()
      }
    }
  }
  
  var codingTextColor: UIColor {
    get {
      let lm = self.layoutManager as! CodeEditorLayoutManager
      return lm.codingTextColor
    }
    set(newColor) {
      let lm = self.layoutManager as! CodeEditorLayoutManager
      if !lm.codingTextColor.isEqual(newColor) {
        lm.codingTextColor = newColor
        self.setNeedsDisplay()
      }
    }
  }
  
  var codingBorderColor: UIColor = .lightGray {
    didSet {
      self.setNeedsDisplay()
    }
  }
  
  var codingBackgroundColor: UIColor = .secondarySystemBackground {
    didSet {
      self.setNeedsDisplay()
    }
  }
  
  init(frame: CGRect, docManager: DocumentationManager) {
    let ts = NSTextStorage()
    let td = CodeEditorTextStorageDelegate(enableSyntaxHighlighting: true,
                                           enableIdentifierMarkup: true,
                                           lispSyntax: true,
                                           docManager: docManager)
    let lm = CodeEditorLayoutManager()
    let tc = NSTextContainer(size: CGSize(width: CGFloat.greatestFiniteMagnitude,
                                          height: CGFloat.greatestFiniteMagnitude))
    tc.widthTracksTextView = true
    tc.exclusionPaths = [UIBezierPath(rect: CGRect(x: 0.0, y: 0.0,
                                                   width: CodeEditorTextView.gutterWidth,
                                                   height: CGFloat.greatestFiniteMagnitude))]
    lm.addTextContainer(tc)
    ts.addLayoutManager(lm)
    ts.delegate = td
    self.textStorageDelegate = td
    super.init(frame: frame, textContainer: tc)
    self.backgroundColor = .clear
    self.contentMode = .redraw
  }
  
  required init(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func draw(_ rect: CGRect) {
    if let context: CGContext = UIGraphicsGetCurrentContext() {
      let bounds = self.bounds
      context.setFillColor(self.codingBackgroundColor.cgColor)
      context.fill(CGRect(x: bounds.origin.x,
                          y: bounds.origin.y,
                          width: CodeEditorTextView.gutterWidth,
                          height: bounds.size.height))
      context.setStrokeColor(self.codingBorderColor.cgColor);
      context.setLineWidth(0.2);
      context.stroke(CGRect(x: bounds.origin.x + 39.2,
                            y: bounds.origin.y,
                            width: 0.2,
                            height: bounds.height))
      self.layoutManager.drawBackground(forGlyphRange: NSRange(location: 0, length: 0), at: CGPoint(x: 0, y: 8))
    }
    super.draw(rect)
  }
}
