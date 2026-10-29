//
//  WebView.swift
//  LispPad
//
//  Created by Matthias Zenger on 30/10/2021.
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
import Combine
@preconcurrency import WebKit

class WebViewController: ObservableObject {
  @Published var pageTitle: String = "Loading…"
  @Published var load: WebResource? = nil
  @Published var reload: Bool = false
  @Published var goHome: Bool = false
  @Published var isLoading: Bool = false
  @Published var goBack: Bool = false
  @Published var canGoBack: Bool = false
  @Published var goForward: Bool = false
  @Published var canGoForward: Bool = false
  @Published var zoom: CGFloat = 1.0

  /// Bounds for the zoom level, whether it is chosen explicitly or via a pinch gesture.
  static let minZoom: CGFloat = 0.5
  static let maxZoom: CGFloat = 2.0
}

enum WebResource {
  case request(URL, URLRequest.CachePolicy?, TimeInterval?)
  case file(URL, URL?)
  case html(String, URL?)
  
  func load(into view: WKWebView) {
    switch self {
      case .request(let url, let policy, let timeout):
        view.load(URLRequest(url: url,
                             cachePolicy: policy ?? .useProtocolCachePolicy,
                             timeoutInterval: timeout ?? 30))
      case .file(let url, let root):
        view.loadFileURL(url, allowingReadAccessTo: root ?? url.deletingLastPathComponent())
      case .html(let content, let base):
        view.loadHTMLString(content, baseURL: base)
    }
  }
}

struct LinkingPolicy {
  
  static let all = LinkingPolicy(allowLocal: true,
                                 forbiddenHosts: nil,
                                 allowedHosts: nil,
                                 linkExternally: nil,
                                 linkInternally: nil).evaluate
  
  static let allExternal = LinkingPolicy(allowLocal: true,
                                         forbiddenHosts: nil,
                                         allowedHosts: nil,
                                         linkExternally: nil,
                                         linkInternally: []).evaluate
  
  static let none = LinkingPolicy(allowLocal: false,
                                  forbiddenHosts: nil,
                                  allowedHosts: [],
                                  linkExternally: nil,
                                  linkInternally: nil).evaluate
  
  static let localOnly = LinkingPolicy(allowLocal: true,
                                       forbiddenHosts: nil,
                                       allowedHosts: [],
                                       linkExternally: nil,
                                       linkInternally: nil).evaluate
  
  enum Decision: Int {
    case cancel = 0
    case allow = 1
    case download = 2
    case allowExternal = 3
  }
  
  typealias Evaluator = (WKNavigationAction) -> Decision
  
  let allowLocal: Bool
  let forbiddenHosts: [String]?
  let allowedHosts: [String]?
  let linkExternally: [String]?
  let linkInternally: [String]?
  
  func evaluate(_ navigationAction: WKNavigationAction) -> Decision {
    guard let host = navigationAction.request.url?.host else {
      return self.allowLocal ? .allow : .cancel
    }
    if let forbiddenHosts = self.forbiddenHosts {
      for forbiddenHost in forbiddenHosts {
        if host.hasSuffix(forbiddenHost) {
          return .cancel
        }
      }
    }
    return self.evalAllowedHosts(host)
  }
  
  private func evalAllowedHosts(_ host: String) -> Decision {
    if let allowedHosts = allowedHosts {
      for allowedHost in allowedHosts {
        if host.hasSuffix(allowedHost) {
          return self.evalInternalExternal(host)
        }
      }
      return .cancel
    } else {
      return self.evalInternalExternal(host)
    }
  }
  
  private func evalInternalExternal(_ host: String) -> Decision {
    if let linkExternally = self.linkExternally {
      for external in linkExternally {
        if host.hasSuffix(external) {
          return .allowExternal
        }
      }
      return .allow
    }
    if let linkInternally = self.linkInternally {
      for internl in linkInternally {
        if host.hasSuffix(internl) {
          return .allow
        }
      }
      return .allowExternal
    }
    return .allow
  }
}

enum CredentialProvider {
  case none
  case predefined(URLCredential)
  case handler((URLAuthenticationChallenge) -> (URLSession.AuthChallengeDisposition,
                                                URLCredential?))
}

enum NavigationNotification {
  case decidedPolicyFor(WKWebView,
                        WKNavigationAction,
                        WKNavigationActionPolicy)
  case didReceiveAuthChallenge(WKWebView,
                               URLAuthenticationChallenge,
                               URLSession.AuthChallengeDisposition,
                               URLCredential?)
  case didStartProvisionalNavigation(WKWebView, WKNavigation)
  case didReceiveServerRedirectForProvisionalNavigation(WKWebView, WKNavigation)
  case didCommit(WKWebView, WKNavigation)
  case didFinish(WKWebView, WKNavigation)
  case didFailProvisionalNavigation(WKWebView, WKNavigation, Error)
  case didFail(WKWebView, WKNavigation, Error)
}

struct WebView: UIViewRepresentable {
  @ObservedObject var controller: WebViewController
  let resource: WebResource
  let title: String?
  let policyEvaluator: LinkingPolicy.Evaluator
  let credentialProvider: CredentialProvider
  let action: (NavigationNotification) -> Void
  
  init(controller: WebViewController,
       resource: WebResource,
       title: String? = nil,
       policyEvaluator: @escaping LinkingPolicy.Evaluator = LinkingPolicy.allExternal,
       credentialProvider: CredentialProvider = .none,
       action: ((NavigationNotification) -> Void)? = nil) {
    self.controller = controller
    self.resource = resource
    self.title = title
    self.policyEvaluator = policyEvaluator
    self.credentialProvider = credentialProvider
    self.action = action ?? { notification in }
  }
  
  public func makeCoordinator() -> Coordinator {
    return Coordinator(controller: self.controller,
                       title: self.title,
                       policyEvaluator: self.policyEvaluator,
                       credential: self.credentialProvider,
                       action: self.action)
  }
  
  public func makeUIView(context: Context) -> WKWebView  {
    let view = WKWebView()
    view.navigationDelegate = context.coordinator
    view.scrollView.delegate = context.coordinator
    context.coordinator.openURLProc = context.environment.openURL
    let pinch = UIPinchGestureRecognizer(target: context.coordinator,
                                         action: #selector(Coordinator.pinched(_:)))
    pinch.delegate = context.coordinator
    view.addGestureRecognizer(pinch)
    context.coordinator.disableNativePinch(of: view)
    context.coordinator.apply(zoom: self.controller.zoom, to: view)
    DispatchQueue.main.async {
      view.publisher(for: \.canGoBack).assign(to: &controller.$canGoBack)
      view.publisher(for: \.canGoForward).assign(to: &controller.$canGoForward)
      view.publisher(for: \.isLoading).assign(to: &controller.$isLoading)
      self.resource.load(into: view)
    }
    return view
  }
  
  public func updateUIView(_ view: WKWebView, context: Context) {
    DispatchQueue.main.async {
      // Update zoom level if changed
      if context.coordinator.appliedZoom != self.controller.zoom {
        context.coordinator.apply(zoom: self.controller.zoom, to: view)
      }
      // Load content/resources, navigate
      if let resource = controller.load {
        resource.load(into: view)
        controller.load = nil
      } else if controller.reload {
        view.reload()
        controller.reload = false
      } else if controller.goHome {
        self.resource.load(into: view)
        controller.goHome = false
      } else if view.canGoBack, controller.goBack {
        view.goBack()
        controller.goBack = false
      } else if view.canGoForward, controller.goForward {
        view.goForward()
        controller.goForward = false
      }
    }
  }
  
  final class Coordinator: NSObject, WKNavigationDelegate, UIScrollViewDelegate,
                           UIGestureRecognizerDelegate {
    @ObservedObject var controller: WebViewController
    var openURLProc: OpenURLAction? = nil
    let title: String?
    let policyEvaluator: LinkingPolicy.Evaluator
    let credentialProvider: CredentialProvider
    let action: (NavigationNotification) -> Void
    var isUpdatingZoomProgrammatically = false
    private(set) var appliedZoom: CGFloat = 1.0
    private var pinchStartZoom: CGFloat = 1.0

    init(controller: WebViewController,
         title: String?,
         policyEvaluator: @escaping LinkingPolicy.Evaluator,
         credential: CredentialProvider,
         action: @escaping (NavigationNotification) -> Void) {
      DispatchQueue.main.async {
        controller.pageTitle = title ?? "Loading…"
      }
      self.controller = controller
      self.title = title
      self.policyEvaluator = policyEvaluator
      self.credentialProvider = credential
      self.action = action
    }
    
    /// Sets the zoom level of the web view's content. In contrast to magnifying the scroll view
    /// or setting `pageZoom`, which scale the rendered page, this zooms the document itself. As a
    /// consequence, the text reflows to the available width.
    func apply(zoom: CGFloat, to view: WKWebView) {
      self.appliedZoom = zoom
      let setZoom = "document.documentElement.style.zoom = '\(zoom)';"
      // Documents loaded later on (e.g. by following a link) are zoomed upon creation
      let userContent = view.configuration.userContentController
      userContent.removeAllUserScripts()
      userContent.addUserScript(WKUserScript(source: setZoom,
                                             injectionTime: .atDocumentStart,
                                             forMainFrameOnly: true))
      // Zoom the current document, staying at the same relative vertical position within it. The
      // horizontal position is reset, since a pinch gesture leaves the page scrolled sideways.
      view.evaluateJavaScript("""
          (function() {
            var page = document.scrollingElement || document.documentElement;
            var position = page.scrollHeight > 0 ? page.scrollTop / page.scrollHeight : 0;
            \(setZoom)
            page.scrollTop = position * page.scrollHeight;
            page.scrollLeft = 0;
          })();
        """)
      // Drop the magnification of a preceding double tap, which is now part of the zoom level
      self.resetMagnification(of: view.scrollView, animated: false)
    }

    private func resetMagnification(of scrollView: UIScrollView, animated: Bool) {
      self.isUpdatingZoomProgrammatically = true
      scrollView.setZoomScale(1.0, animated: animated)
      self.isUpdatingZoomProgrammatically = false
    }

    /// WebKit limits the magnification of a pinch gesture to the range in which the whole width of
    /// the content is visible. That is incompatible with the zoom levels offered otherwise. So,
    /// pinch gestures are handled by `pinched(_:)`. WebKit enables its own pinch gesture again
    /// whenever it sets up a new page, so this needs to be repeated for every navigation.
    func disableNativePinch(of view: WKWebView) {
      view.scrollView.pinchGestureRecognizer?.isEnabled = false
    }

    /// Turns a pinch gesture directly into a zoom level within bounds.
    @objc func pinched(_ recognizer: UIPinchGestureRecognizer) {
      guard let view = recognizer.view as? WKWebView else {
        return
      }
      switch recognizer.state {
        case .began:
          self.disableNativePinch(of: view)
          self.pinchStartZoom = self.appliedZoom
        case .changed:
          let zoom = min(max(self.pinchStartZoom * recognizer.scale, WebViewController.minZoom),
                         WebViewController.maxZoom)
          if abs(zoom - self.appliedZoom) >= 0.01 {
            self.apply(zoom: zoom, to: view)
            self.controller.zoom = zoom
          }
        default:
          break
      }
    }

    // MARK: - UIGestureRecognizerDelegate

    /// Without this, WebKit's own pinch gesture, which is already in progress when `pinched(_:)`
    /// begins, takes precedence and the latter never gets to see the gesture.
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
      return true
    }

    // MARK: - UIScrollViewDelegate

    /// Once a zoom gesture other than a pinch (i.e. a double tap) ends, the magnification it
    /// produced is turned into a new zoom level of the page content, such that the content is
    /// laid out again.
    public func scrollViewDidEndZooming(_ scrollView: UIScrollView,
                                        with view: UIView?,
                                        atScale scale: CGFloat) {
      if !isUpdatingZoomProgrammatically && abs(scale - 1.0) > 0.01 {
        let zoom = min(max(self.appliedZoom * scale, WebViewController.minZoom),
                       WebViewController.maxZoom)
        if abs(zoom - self.appliedZoom) > 0.001 {
          DispatchQueue.main.async {
            self.controller.zoom = zoom
          }
        } else {
          // The gesture ended up beyond a bound; just undo its magnification
          self.resetMagnification(of: scrollView, animated: true)
        }
      }
    }
    
    // MARK: - WKNavigationDelegate
    
    public func webView(_ view: WKWebView,
                        decidePolicyFor navigationAction: WKNavigationAction,
                        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
      switch self.policyEvaluator(navigationAction) {
        case .cancel:
          decisionHandler(.cancel)
          self.action(.decidedPolicyFor(view, navigationAction, .cancel))
        case .allow:
          decisionHandler(.allow)
          self.action(.decidedPolicyFor(view, navigationAction, .allow))
        case .download:
          decisionHandler(.download)
          self.action(.decidedPolicyFor(view, navigationAction, .download))
        case .allowExternal:
          if let url = navigationAction.request.url {
            self.openURLProc?(url)
            decisionHandler(.cancel)
            self.action(.decidedPolicyFor(view, navigationAction, .cancel))
          } else {
            decisionHandler(.allow)
            self.action(.decidedPolicyFor(view, navigationAction, .allow))
          }
      }
    }
    
    public func webView(_ view: WKWebView,
                        didReceive chall: URLAuthenticationChallenge,
                        completionHandler: @escaping (URLSession.AuthChallengeDisposition,
                                                      URLCredential?) -> Void) {
      switch self.credentialProvider {
        case .none:
          completionHandler(.performDefaultHandling, nil)
          self.action(.didReceiveAuthChallenge(view, chall, .performDefaultHandling, nil))
        case .predefined(let credential):
          let authenticationMethod = chall.protectionSpace.authenticationMethod
          if authenticationMethod == NSURLAuthenticationMethodDefault ||
             authenticationMethod == NSURLAuthenticationMethodHTTPBasic ||
             authenticationMethod == NSURLAuthenticationMethodHTTPDigest {
            completionHandler(.useCredential, credential)
            self.action(.didReceiveAuthChallenge(view, chall, .useCredential, credential))
          } else if authenticationMethod == NSURLAuthenticationMethodServerTrust {
            completionHandler(.performDefaultHandling, nil)
            self.action(.didReceiveAuthChallenge(view, chall, .performDefaultHandling, nil))
          } else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            self.action(.didReceiveAuthChallenge(view, chall, .cancelAuthenticationChallenge, nil))
          }
        case .handler(let handler):
          let (disposition, credential) = handler(chall)
          completionHandler(disposition, credential)
          self.action(.didReceiveAuthChallenge(view, chall, disposition, credential))
      }
    }
    
    public func webView(_ view: WKWebView,
                        didStartProvisionalNavigation navigation: WKNavigation!) {
      self.action(.didStartProvisionalNavigation(view, navigation))
    }
    
    public func webView(_ view: WKWebView,
                        didReceiveServerRedirectForProvisionalNavigation nav: WKNavigation!) {
      self.action(.didReceiveServerRedirectForProvisionalNavigation(view, nav))
    }
    
    public func webView(_ view: WKWebView, didCommit navigation: WKNavigation!) {
      self.disableNativePinch(of: view)
      self.action(.didCommit(view, navigation))
    }

    public func webView(_ view: WKWebView, didFinish navigation: WKNavigation!) {
      self.disableNativePinch(of: view)
      // Set the page title
      if let title = self.title ?? view.title {
        self.controller.pageTitle = title
      }
      // Set the default font
      view.evaluateJavaScript(
        "document.getElementsByTagName('body')[0].style.fontFamily =\"-apple-system\"")
      // Propagate event
      self.action(.didFinish(view, navigation))
    }
    
    public func webView(_ view: WKWebView,
                        didFail navigation: WKNavigation!,
                        withError error: Error) {
      self.action(.didFail(view, navigation, error))
    }
    
    public func webView(_ view: WKWebView,
                        didFailProvisionalNavigation navigation: WKNavigation!,
                        withError error: Error) {
      self.action(.didFailProvisionalNavigation(view, navigation, error))
    }
  }
}
