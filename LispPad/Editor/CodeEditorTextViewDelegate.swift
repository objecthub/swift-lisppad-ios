//
//  CodeEditorTextViewDelegate.swift
//  LispPad
//
//  Created by Matthias Zenger on 04/04/2021.
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

import UIKit
import SwiftUI

class CodeEditorTextViewDelegate: EditorTextViewDelegate {
  let fileManager: FileManager
  
  init(text: Binding<String>, selectedRange: Binding<NSRange>, fileManager: FileManager) {
    self.fileManager = fileManager
    super.init(text: text, selectedRange: selectedRange)
  }
  
  public func scrollViewDidScroll(_ scrollView: UIScrollView) {
    self.fileManager.editorDocument?.lastContentOffset = scrollView.contentOffset
  }
  
  public override func textView(_ textView: UITextView,
                                shouldChangeTextIn range: NSRange,
                                replacementText text: String) -> Bool {
    if text == "\n" {
      let indent: String
      switch self.fileManager.editorDocumentInfo.editorType {
        case .scheme:
          guard UserSettings.standard.schemeAutoIndent else {
            return true
          }
          indent = self.schemeIndent(textView.textStorage.string as NSString, range)
        case .markdown:
          guard UserSettings.standard.markdownAutoIndent else {
            return true
          }
          indent = self.markdownIndent(textView.textStorage.string as NSString, range)
        case .other:
          return true
      }
      if let replaceStart = textView.position(from: textView.beginningOfDocument,
                                              offset: range.location),
          let replaceEnd = textView.position(from: replaceStart, offset: range.length),
          let textRange = textView.textRange(from: replaceStart, to: replaceEnd) {
        // textView.undoManager?.beginUndoGrouping()
        textView.replace(textRange, withText: "\n" + indent)
        // textView.undoManager?.endUndoGrouping()
        return false
      }
      return true
    } else {
      return super.textView(textView, shouldChangeTextIn: range, replacementText: text)
    }
  }
}
