//
//  LispPadOAuthConfig.swift
//  LispPad
//
//  Created by Matthias Zenger on 13/10/2024.
//  Copyright © 2024 ObjectHub. All rights reserved.
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

import OAuth2
import LispKit
import UIKit

public final class LispPadOAuthConfig: HTTPOAuthConfig {
  
  final class Logger: OAuth2Logger {
    public var level: OAuth2LogLevel
    
    init(level: OAuth2LogLevel = OAuth2LogLevel.debug) {
      self.level = level
    }
    
    public func log(_ atLevel: OAuth2LogLevel,
                    module: String?,
                    filename: String?,
                    line: Int?,
                    function: String?,
                    msg: @autoclosure() -> String) {
      if level != .off && atLevel.rawValue >= level.rawValue {
        let severity: Severity
        switch atLevel {
          case .trace:
            severity = .debug
          case .debug:
            severity = .info
          case .warn:
            severity = .warning
          case .off:
            severity = .error
        }
        var message = msg()
        var tag = module == nil ? "oauth" : module!.lowercased()
        if message.starts(with: "REQUEST\n") {
          message.removeSubrange(message.startIndex..<message.index(message.startIndex, offsetBy: 8))
          tag = tag + "/req"
        } else if message.starts(with: "RESPONSE\n") {
          message.removeSubrange(message.startIndex..<message.index(message.startIndex, offsetBy: 9))
          tag = tag + "/res"
        }
        SessionLog.standard.addLogEntry(severity: severity, tag: tag, message: message)
      }
    }
  }
  
  
  public init(context: Context) {
  }
  
  public func configureEmbeddedAuth(oauth2: OAuth2) {
    if Thread.isMainThread {
      if let context = UIApplication.shared.keyWindowPresentedController {
        oauth2.authConfig.authorizeContext = context
        oauth2.authConfig.authorizeEmbedded = true
        oauth2.authConfig.ui.useSafariView = false
        oauth2.authConfig.ui.useAuthenticationSession = true
      }
    } else {
      DispatchQueue.main.sync {
        if let context = UIApplication.shared.keyWindowPresentedController {
          oauth2.authConfig.authorizeContext = context
          oauth2.authConfig.authorizeEmbedded = true
          oauth2.authConfig.ui.useSafariView = false
          oauth2.authConfig.ui.useAuthenticationSession = true
        }
      }
    }
  }
  
  public func createLogger(level: OAuth2LogLevel) -> OAuth2Logger {
    return Logger(level: level)
  }
}

extension UIApplication {
  public var keyWindowPresentedController: UIViewController? {
    // Find the key window
    let window = UIApplication.shared
                              .connectedScenes
                              .flatMap { ($0 as? UIWindowScene)?.windows ?? [] }
                              .last { $0.isKeyWindow }
    var viewController = window?.rootViewController
    // If root `UIViewController` is a `UITabBarController`
    if let presentedController = viewController as? UITabBarController {
      // Move to selected `UIViewController`
      viewController = presentedController.selectedViewController
    }
    // Go deeper to find the last presented `UIViewController`
    while let presentedController = viewController?.presentedViewController {
      // If root `UIViewController` is a `UITabBarController`
      if let presentedController = presentedController as? UITabBarController {
        // Move to selected `UIViewController`
        viewController = presentedController.selectedViewController
      } else {
        // Otherwise, go deeper
        viewController = presentedController
      }
    }
    return viewController
  }
}
