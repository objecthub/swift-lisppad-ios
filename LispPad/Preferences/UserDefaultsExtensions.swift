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

///
/// Extensions for managing user defaults.
/// 
extension UserDefaults {
  
  func str(forKey key: String, _ value: String) -> String {
    return self.string(forKey: key) ?? value
  }
  
  func boolean(forKey key: String, _ value: Bool = true) -> Bool {
    return (self.value(forKey: key) as? Bool) ?? value
  }
  
  func int(forKey key: String, _ value: Int) -> Int {
    return (self.value(forKey: key) as? Int) ?? value
  }
  
  func set(_ color: UIColor, forKey key: String) {
    if let obj = try? NSKeyedArchiver.archivedData(withRootObject: color,
                                                   requiringSecureCoding: false) {
      self.set(obj, forKey: key)
    }
  }
  
  func color(forKey key: String, alternateKey: String? = nil, _ value: UIColor) -> UIColor {
    guard let data = self.data(forKey: key),
          let color = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self,
                                                              from: data) else {
      guard let alternateKey,
            let data = self.data(forKey: alternateKey),
            let color = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self,
                                                                from: data) else {
        return value
      }
      self.set(color, forKey: key)
      return color
    }
    return color
  }
  
  func color(forKey key: String,
             alternateKey: String? = nil,
             red: CGFloat,
             green: CGFloat,
             blue: CGFloat) -> UIColor {
    guard let data = self.data(forKey: key),
          let color = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self,
                                                              from: data) else {
      guard let alternateKey,
            let data = self.data(forKey: alternateKey),
            let color = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self,
                                                                from: data) else {
        return UIColor(red: red, green: green, blue: blue, alpha: 1.0)
      }
      self.set(color, forKey: key)
      return color
    }
    return color
  }
}
