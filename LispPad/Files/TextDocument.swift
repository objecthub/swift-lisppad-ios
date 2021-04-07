//
//  TextDocument.swift
//  LispPad
//
//  Created by Matthias Zenger on 06/04/2021.
//

import UIKit

final class TextDocument: UIDocument, ObservableObject, Identifiable {
  @Published var text: String = ""
  
  var id: URL {
    return self.fileURL
  }
  
  func loadFile() {
    if Foundation.FileManager.default.fileExists(atPath: self.fileURL.path) {
      self.open(completionHandler: { success in
        if success {
          print("File open OK")
        } else {
          print("Failed to open file")
        }
      })
    } else {
      self.save(to: self.fileURL,
                for: .forCreating,
                completionHandler: { success in
                  if success {
                    print("File created OK")
                  } else {
                    print("Failed to create file ")
                  }
                })
    }
  }
  
  func saveFile() {
    self.save(to: self.fileURL,
              for: .forOverwriting,
              completionHandler: { success in
                if success {
                  print("File overwrite OK")
                } else {
                  print("File overwrite failed")
                }})
  }
  
  override func load(fromContents contents: Any, ofType typeName: String?) throws {
    if let data = contents as? Data {
      self.text = String(data: data, encoding: .utf8) ?? ""
    }
  }
  
  override func contents(forType typeName: String) throws -> Any {
    return self.text.data(using: .utf8) ?? Data()
  }
}
