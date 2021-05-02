//
//  UserDefaultsExtensions.swift
//  LispPad
//
//  Created by Matthias Zenger on 02/05/2021.
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

import Foundation
import UIKit

extension UserDefaults {
  
  func str(forKey key: String, _ value: String) -> String {
    return self.string(forKey: key) ?? value
  }
  
  func bool(forKey key: String, _ value: Bool = true) -> Bool {
    if let obj = self.object(forKey: key) {
      return (obj as? Bool) ?? value
    } else {
      return value
    }
  }
  
  func int(forKey key: String, _ value: Int) -> Int {
    return (self.object(forKey: key) as? Int) ?? value
  }
  
  func set(_ color: CGColor, forKey key: String) {
    if let obj = try? NSKeyedArchiver.archivedData(withRootObject: UIColor(cgColor: color),
                                                   requiringSecureCoding: false) {
      self.set(obj, forKey: key)
    }
  }
  
  func color(forKey key: String, _ value: UIColor) -> CGColor {
    guard let data = self.data(forKey: key),
          let color = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self,
                                                              from: data) else {
      return value.cgColor
    }
    return color.cgColor
  }
  
  func color(forKey key: String, red: CGFloat, green: CGFloat, blue: CGFloat) -> CGColor {
    guard let data = self.data(forKey: key),
          let color = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self,
                                                              from: data) else {
      return CGColor(red: red, green: green, blue: blue, alpha: 1.0)
    }
    return color.cgColor
  }
}
