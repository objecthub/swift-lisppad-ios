//
//  PortableURL.swift
//  LispPad
//
//  Created by Matthias Zenger on 12/04/2021.
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
import LispKit

///
/// A `PortableURL` implements a URL bookmark that works even if the app is being updated.
/// It also works across devices assuming the devices have the same content in their local
/// folders. This struct is mostly useful for persisting URLs in the user defaults.
/// 
enum PortableURL: Hashable, Codable, Identifiable, CustomStringConvertible {
  
  enum Base: Int, Codable, CustomStringConvertible, CaseIterable {
    case application = 0
    case documents = 1
    case icloud = 2
    case lispkit = 3
    case lisppad = 4
    
    var url: URL? {
      switch self {
        case .application:
          return Base.applicationUrl
        case .documents:
          return Base.documentsUrl
        case .icloud:
          return Base.icloudUrl
        case .lispkit:
          return Base.lispkitUrl
        case .lisppad:
          return Base.lisppadUrl
      }
    }
    
    var path: String? {
      if let path = self.url?.absoluteURL.path {
        if path.last == "/" {
          return path
        } else {
          return path + "/"
        }
      }
      return nil
    }
    
    var imageName: String {
      switch self {
        case .application:
          return "internaldrive"
        case .documents:
          switch UIDevice.current.userInterfaceIdiom {
            case .phone:
              return "iphone"
            case .pad:
              return "ipad"
            default:
              return "desktopcomputer"
          }
        case .icloud:
          return "icloud"
        case .lispkit:
          return "building.columns"
        case .lisppad:
          return "building.columns.fill"
      }
    }
    
    var description: String {
      switch self {
        case .application:
          return "Internal"
        case .documents:
          return "Documents"
        case .icloud:
          return "iCloud"
        case .lispkit:
          return "LispKit"
        case .lisppad:
          return "LispPad"
      }
    }
    
    private static let applicationUrl = Self.appSupportDirectory()
    private static let documentsUrl = Self.documentsDirectory()
    private static let icloudUrl = Self.icloudDirectory()
    private static let lispkitUrl = { () -> URL? in
      guard let base = Context.bundle?.bundleURL.absoluteURL else {
        return nil
      }
      return URL(fileURLWithPath: Context.rootDirectory, relativeTo: base).resolvingSymlinksInPath()
    }()
    private static let lisppadUrl = URL(fileURLWithPath: "Root",
                                        relativeTo: Bundle.main.bundleURL.absoluteURL)
                                    .resolvingSymlinksInPath()
    
    /// Returns the "iCloud Drive" URL if available.
    static func icloudDirectory() -> URL? {
      return Foundation.FileManager.default.url(forUbiquityContainerIdentifier: nil)?
                                           .appendingPathComponent("Documents")
                                           .resolvingSymlinksInPath()
    }
    
    /// Returns the "On my iPhone" URL if available (creating it if it does not exist already).
    static func documentsDirectory() -> URL? {
      return try? Foundation.FileManager.default.url(for: .documentDirectory,
                                                     in: .userDomainMask,
                                                     appropriateFor: nil,
                                                     create: true).resolvingSymlinksInPath()
    }

    /// Returns the internal application support URL if available (creating it if it does not
    /// exist already).
    static func appSupportDirectory() -> URL? {
      return try? Foundation.FileManager.default.url(for: .applicationSupportDirectory,
                                                     in: .userDomainMask,
                                                     appropriateFor: nil,
                                                     create: true).resolvingSymlinksInPath()
    }
    
    /// Returns a cache URL if available.
    static func cacheDirectory() -> URL? {
      return Foundation.FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
    }
  }
  
  enum CodingKeys: CodingKey {
    case url
    case rel
    case base
    
    static let absolute: Set<CodingKeys> = [.url]
    static let relative: Set<CodingKeys> = [.rel, .base]
  }
  
  case absolute(URL)
  case relative(String, Base)
  
  init?(_ url: URL?) {
    guard let url = url else {
      return nil
    }
    self.init(url: url)
  }
  
  init(url: URL) {
    if let (rel, base) = PortableURL.normalizeURL(url) {
      self = .relative(rel, base)
    } else {
      self = .absolute(url)
    }
  }
  
  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let containerKeys = Set(container.allKeys)
    switch containerKeys {
      case CodingKeys.absolute:
        self = .absolute(try container.decode(URL.self, forKey: .url))
      case CodingKeys.relative:
        self = .relative(try container.decode(String.self, forKey: .rel),
                         try container.decode(Base.self, forKey: .base))
      default:
        throw DecodingError.dataCorrupted(.init(codingPath: [],
                                                debugDescription: "PortableURL coding broken",
                                                underlyingError: nil))
    }
  }
  
  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    switch self {
      case .absolute(let url):
        try container.encode(url, forKey: .url)
      case .relative(let rel, let base):
        try container.encode(rel, forKey: .rel)
        try container.encode(base, forKey: .base)
    }
  }
  
  var isRelative: Bool {
    switch self {
      case .absolute(_):
        return false
      case .relative(_, _):
        return true
    }
  }
  
  var url: URL? {
    switch self {
      case .absolute(let url):
        return url
      case .relative(let rel, let base):
        guard let baseUrl = base.url else {
          return nil
        }
        return URL(fileURLWithPath: rel, relativeTo: baseUrl)
    }
  }
  
  var id: String {
    switch self {
      case .absolute(let url):
        return url.absoluteString
      case .relative(let rel, let base):
        return "[\(base)] \(rel)"
    }
  }
  
  var relativePath: String {
    switch self {
      case .absolute(let url):
        return url.path
      case .relative(let rel, _):
        return rel
    }
  }
  
  var base: Base? {
    switch self {
      case .absolute(_):
        return nil
      case .relative(_, let base):
        return base
    }
  }
  
  var baseURL: URL? {
    switch self {
      case .absolute(let url):
        return url.baseURL
      case .relative(_, let base):
        return base.url
    }
  }
  
  var absoluteURL: URL? {
    self.url?.absoluteURL
  }
  
  var absolutePath: String? {
    self.url?.absoluteURL.path
  }
  
  var itemExists: Bool {
    guard let path = self.absolutePath else {
      return false
    }
    var dir: ObjCBool = false
    return Foundation.FileManager.default.fileExists(atPath: path, isDirectory: &dir)
  }
  
  var fileExists: Bool {
    guard let path = self.absolutePath else {
      return false
    }
    var dir: ObjCBool = false
    return Foundation.FileManager.default.fileExists(atPath: path, isDirectory: &dir)
             && !dir.boolValue
  }
  
  var directoryExists: Bool {
    guard let path = self.absolutePath else {
      return false
    }
    var dir: ObjCBool = false
    return Foundation.FileManager.default.fileExists(atPath: path, isDirectory: &dir)
             && dir.boolValue
  }
  
  var mutable: Bool {
    switch self {
      case .absolute(_),
           .relative(_, .application),
           .relative(_, .documents),
           .relative(_, .icloud):
        return true
      default:
        return false
    }
  }
  
  var description: String {
    self.id
  }
  
  private static func normalizeURL(_ url: URL) -> (String, Base)? {
    let aurl = url.absoluteURL.resolvingSymlinksInPath().path
    for base in Base.allCases {
      if let abaseUrl = base.path {
        if aurl.hasPrefix(abaseUrl) {
          return (String(aurl[aurl.index(aurl.startIndex, offsetBy: abaseUrl.count)...]), base)
        }
      }
    }
    return nil
  }
}
