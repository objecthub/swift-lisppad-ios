//
//  PlainFullScreenCover.swift
//  LispPad
//
//  Created by Matthias Zenger on 04/04/2026.
//

import SwiftUI

struct PlainFullScreenCover<CoverContent: View>: ViewModifier {
  @Binding var isPresented: Bool
  @ViewBuilder let coverContent: () -> CoverContent
  
  func body(content: Content) -> some View {
    content.background(
      FullScreenCoverHost(isPresented: $isPresented, coverContent: coverContent)
    )
  }
}

private struct FullScreenCoverHost<CoverContent: View>: UIViewControllerRepresentable {
  @Binding var isPresented: Bool
  @ViewBuilder let coverContent: () -> CoverContent
  
  func makeCoordinator() -> Coordinator {
    return Coordinator()
  }
  
  func makeUIViewController(context: Context) -> UIViewController {
    return UIViewController()
  }
  
  func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
    let coordinator = context.coordinator
    if isPresented, !coordinator.isPresenting {
      tryPresent(deadline: .now(), uiViewController: uiViewController, coordinator: coordinator)
    } else if !isPresented, coordinator.isPresenting {
      DispatchQueue.main.async {
        guard coordinator.isPresenting,
              let root = uiViewController.view.window?.rootViewController else {
          return
        }
        coordinator.isPresenting = false
        root.dismiss(animated: false)
      }
    }
  }
  
  private func tryPresent(deadline: DispatchTime,
                          uiViewController: UIViewController,
                          coordinator: Coordinator) {
    DispatchQueue.main.asyncAfter(deadline: deadline) {
      guard !coordinator.isPresenting, isPresented else {
        return
      }
      guard let root = uiViewController.view.window?.rootViewController,
            root.presentedViewController == nil else {
        tryPresent(deadline: .now() + 0.1,
                   uiViewController: uiViewController,
                   coordinator: coordinator)
        return
      }
      coordinator.isPresenting = true
      let hostingController = UIHostingController(rootView: self.coverContent())
      hostingController.modalPresentationStyle = .overFullScreen
      hostingController.view.backgroundColor = .clear
      root.present(hostingController, animated: false)
    }
  }
  
  private static func topViewController(from root: UIViewController) -> UIViewController {
    // Presented view controller takes priority over everything else
    if let presented = root.presentedViewController {
      return topViewController(from: presented)
    }
    // UINavigationController
    if let nav = root as? UINavigationController,
       let visible = nav.visibleViewController {
      return topViewController(from: visible)
    }
    // UITabBarController
    if let tab = root as? UITabBarController,
       let selected = tab.selectedViewController {
      return topViewController(from: selected)
    }
    // UISplitViewController
    if let split = root as? UISplitViewController {
      if split.isCollapsed {
        if let primary = split.viewController(for: .primary) {
          return topViewController(from: primary)
        }
      } else {
        if let supplementary = split.viewController(for: .supplementary) {
          return topViewController(from: supplementary)
        }
        if let secondary = split.viewController(for: .secondary) {
          return topViewController(from: secondary)
        }
        if let primary = split.viewController(for: .primary) {
          return topViewController(from: primary)
        }
      }
    }
    // UIPageViewController: viewControllers contains exactly the currently
    // visible pages; last is the most prominent (right/front page).
    if let page = root as? UIPageViewController,
       let viewControllers = page.viewControllers,
       !viewControllers.isEmpty,
       let last = viewControllers.last {
      return topViewController(from: last)
    }
    // Generic fallback: match children to their view's z-order
    // since children array order is not guaranteed to reflect visual stacking.
    if !root.children.isEmpty {
      let topChild = root.children
        .filter { $0.viewIfLoaded != nil }
        .sorted {
          let i0 = root.view.subviews.lastIndex(of: $0.view) ?? -1
          let i1 = root.view.subviews.lastIndex(of: $1.view) ?? -1
          return i0 < i1
        }
        .last
      if let topChild {
        return topViewController(from: topChild)
      }
    }
    return root
  }
  
  class Coordinator {
    var isPresenting = false
  }
}

extension View {
  func plainFullScreenCover<Content: View>(
      isPresented: Binding<Bool>,
      @ViewBuilder content: @escaping () -> Content) -> some View {
    modifier(PlainFullScreenCover(isPresented: isPresented, coverContent: content))
  }
}
