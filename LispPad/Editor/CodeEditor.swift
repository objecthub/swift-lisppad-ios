//
//  CodeEditor.swift
//  LispPad
//
//  Created by Matthias Zenger on 28/03/2021.
//

import SwiftUI
import UIKit

public typealias SystemFontAlias = UIFont
public typealias SystemColorAlias = UIColor
public typealias SymbolicTraits = UIFontDescriptor.SymbolicTraits
public typealias OnSelectionChangeCallback = ([NSRange]) -> Void

let defaultEditorFont = UIFont.preferredFont(forTextStyle: .body)
let defaultEditorTextColor = UIColor.label

/*
open class LispTextView: UITextView {
  
  /// Find matching parenthesis between the indices `from` and `to`. If `from` < `to`,
  /// then search forward, if `to` < `from`, search backward.
  private func find(_ ch: UniChar,
                    matching with: UniChar,
                    from: Int,
                    to: Int,
                    in str: NSString) -> Int {
    var open = 0
    if to < from {
      var i = from - 1
      while i >= to {
        if str.character(at: i) == with {
          open += 1
        } else if str.character(at: i) == ch {
          if open == 0 {
            return i
          }
          open -= 1
        }
        i -= 1
      }
    } else if to > from {
      var i = from + 1
      while i < to {
        if str.character(at: i) == with {
          open += 1
        } else if str.character(at: i) == ch {
          if open == 0 {
            return i
          }
          open -= 1
        }
        i += 1
      }
    }
    return -1
  }
  
  /// Highlight the matching parenthesis between the indices `from` and `to`. If `from` is less
  /// than `to`, then search forward, if `to` is less than `from`, search backward.
  func highlight(in str: NSString, from: Int, to: Int, matching ch: UniChar) {
    let loc = self.find(ch, matching: str.character(at: from), from: from, to: to, in: str)
    if loc >= 0 {
      super.showFindIndicator(for: NSRange(location: loc, length: 1))
    }
  }
  
  
  
}
*/

struct CodeEditor: UIViewRepresentable {
  typealias Coordinator = CodeEditorTextViewDelegate
  
  @EnvironmentObject var docManager: DocumentationManager

  @Binding var text: String
  /* {
    didSet {
      self.onTextChange(text)
    }
  } */
  
  var onEditingChanged: () -> Void = {}
  var onCommit: () -> Void = {}
  var onTextChange: (String) -> Void = { _ in }
  
  var autocapitalizationType: UITextAutocapitalizationType = .sentences
  var autocorrectionType: UITextAutocorrectionType = .default
  private(set) var backgroundColor: UIColor? = nil
  private(set) var color: UIColor? = nil
  private(set) var font: UIFont? = nil
  private(set) var insertionPointColor: UIColor? = nil
  var keyboardType: UIKeyboardType = .default
  private(set) var onSelectionChange: OnSelectionChangeCallback? = nil
  
  public init(text: Binding<String>,
              onEditingChanged: @escaping () -> Void = {},
              onCommit: @escaping () -> Void = {},
              onTextChange: @escaping (String) -> Void = { _ in }) {
    self._text = text
    self.onEditingChanged = onEditingChanged
    self.onCommit = onCommit
    self.onTextChange = onTextChange
  }

  public func makeCoordinator() -> Coordinator {
    return CodeEditorTextViewDelegate(self)
  }
  
  public func makeUIView(context: Context) -> UITextView {
    let textView = CodeEditorTextView(frame: CGRect(x: 0,
                                                    y: 0,
                                                    width: CGFloat.greatestFiniteMagnitude,
                                                    height: CGFloat.greatestFiniteMagnitude),
                                      docManager: docManager)  // UITextView()
    textView.delegate = context.coordinator
    textView.isEditable = true
    textView.isScrollEnabled = true
    textView.isSelectable = true
    textView.isUserInteractionEnabled = true
    textView.smartQuotesType = .no
    textView.smartDashesType = .no
    textView.smartInsertDeleteType = .no
    textView.textAlignment = .natural // or .left ?
    updateTextViewModifiers(textView)
    return textView
  }

  public func updateUIView(_ uiView: UITextView, context: Context) {
    // uiView.text = self.text
  }
  
  private func updateTextViewModifiers(_ textView: UITextView) {
    textView.keyboardType = keyboardType
    textView.autocapitalizationType = autocapitalizationType
    textView.autocorrectionType = autocorrectionType
    if let color = self.backgroundColor {
      textView.backgroundColor = color
    }
    if let font = self.font {
      textView.font = font
    }
    textView.tintColor = insertionPointColor ?? textView.tintColor
    let textInputTraits = textView.value(forKey: "textInputTraits") as? NSObject
    textInputTraits?.setValue(textView.tintColor, forKey: "insertionPointColor")
  }
}

/// CodeEditor-specific modifiers
extension CodeEditor {
  public func autocapitalizationType(_ type: UITextAutocapitalizationType) -> Self {
    var new = self
    new.autocapitalizationType = type
    return new
  }
  
  public func autocorrectionType(_ type: UITextAutocorrectionType) -> Self {
    var new = self
    new.autocorrectionType = type
    return new
  }
  
  public func backgroundColor(_ color: UIColor) -> Self {
    var new = self
    new.backgroundColor = color
    return new
  }
  
  public func defaultColor(_ color: UIColor) -> Self {
    var new = self
    new.color = color
    return new
  }
  
  public func defaultFont(_ font: UIFont) -> Self {
    var new = self
    new.font = font
    return new
  }
  
  public func keyboardType(_ type: UIKeyboardType) -> Self {
    var new = self
    new.keyboardType = type
    return new
  }
  
  public func insertionPointColor(_ color: UIColor) -> Self {
    var new = self
    new.insertionPointColor = color
    return new
  }
  
  public func onSelectionChange(_ callback: @escaping ([NSRange]) -> Void) -> Self {
    var new = self
    new.onSelectionChange = callback
    return new
  }
  
  public func onSelectionChange(_ callback: @escaping (NSRange) -> Void) -> Self {
    var new = self
    new.onSelectionChange = { ranges in
      guard let range = ranges.first else {
        return
      }
      callback(range)
    }
    return new
  }
}
