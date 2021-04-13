//
//  CodeEditor.swift
//  LispPad
//
//  Created by Matthias Zenger on 28/03/2021.
//

import SwiftUI
import UIKit

struct CodeEditor: UIViewRepresentable {
  typealias Coordinator = CodeEditorTextViewDelegate
  
  @EnvironmentObject var docManager: DocumentationManager

  @Binding var text: String
  @Binding var forceUpdate: Bool
  @Binding var position: NSRange?
  
  var autocapitalizationType: UITextAutocapitalizationType = .sentences
  var autocorrectionType: UITextAutocorrectionType = .default
  private(set) var backgroundColor: UIColor? = nil
  private(set) var color: UIColor? = nil
  private(set) var font: UIFont? = nil
  private(set) var insertionPointColor: UIColor? = nil
  var keyboardType: UIKeyboardType = .default
  
  public init(text: Binding<String>,
              forceUpdate: Binding<Bool>,
              position: Binding<NSRange?>) {
    self._text = text
    self._forceUpdate = forceUpdate
    self._position = position
  }

  public func makeCoordinator() -> Coordinator {
    return CodeEditorTextViewDelegate(_text)
  }
  
  public func makeUIView(context: Context) -> UITextView {
    let textView = CodeEditorTextView(frame: CGRect(x: 0,
                                                    y: 0,
                                                    width: CGFloat.greatestFiniteMagnitude,
                                                    height: CGFloat.greatestFiniteMagnitude),
                                      docManager: docManager)
    textView.delegate = context.coordinator
    textView.isEditable = true
    textView.isScrollEnabled = true
    textView.isSelectable = true
    textView.isUserInteractionEnabled = true
    textView.smartQuotesType = .no
    textView.smartDashesType = .no
    textView.smartInsertDeleteType = .no
    textView.textAlignment = .left // or .natural ?
    textView.text = self.text
    updateTextViewModifiers(textView)
    return textView
  }

  public func updateUIView(_ uiView: UITextView, context: Context) {
    if let pos = self.position {
      if self.forceUpdate {
        uiView.text = self.text
      }
      uiView.selectedRange = pos
      uiView.scrollRangeToVisible(pos)
      DispatchQueue.main.async {
        uiView.becomeFirstResponder()
        self.position = nil
        self.forceUpdate = false
      }
    } else if self.forceUpdate {
      uiView.text = self.text
      DispatchQueue.main.async {
        self.forceUpdate = false
      }
    }
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
}
