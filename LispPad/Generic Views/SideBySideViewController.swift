//
//  SideBySideViewController.swift
//  LispPad
//
//  This component has been originally written by Dmytro Anokhin as part of his
//  SplitOrFlipViewController project at https://github.com/dmytro-anokhin/split-or-flip .
//  The version included with LispPad Go has been modified to compile under Swift 5.4
//  so that it behaves like the original implementation which was using UISplitViewController
//  (but never really worked well, especially not with the multi-tasking features of iPadOS).
//  
//  Created by Dmytro Anokhin on 08/10/2017.
//  Copyright © 2017 Dmytro Anokhin. All rights reserved.
//
//  MIT License
// 
//  Copyright (c) 2017 Dmytro Anokhin
//  
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//  
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//  
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//  

import UIKit

class SideBySideViewController: UIViewController {
  
  /// View controller visible on the left side in side-by-side display state
  var leftViewController: UIViewController? {
    willSet {
      /*
         Before changing view controller we need to remove previous one. For this we must
         break child-parent relationship. Order of steps is important:
             - notify the child about intention to remove it from the parent;
             - remove the child view from the superview;
             - remove the child from the parent.

         Before removing the child view we need not to forget to remove layout constraints.
         I skip this step because I use manual layout.
         Same routine is for the right view controller.
      */
      guard let child = leftViewController else {
        return
      }
      child.willMove(toParent: nil)
      child.view.removeFromSuperview()
      child.removeFromParent()
    }

    didSet {
      /*
         When adding view controller to the container we must establish child-parent relationship.
         Order of steps is important:
             - add the child view controller;
             - provide size for the child view;
             - add it to the container view;
             - notify the child that it moved to the parent.

         After adding the child view to the container we can optionally setup layout constraints.
         I'm using manual layout so this step is not necessary.
         Same routine is for the right view controller.
      */
      guard let child = leftViewController else {
        return
      }
      loadViewIfNeeded() // I load view to simplify the example
      addChild(child)
      child.view.frame = leftContainerView.bounds
      leftContainerView.contentView = child.view
      child.didMove(toParent: self)
    }
  }

  /// View controller visible on the right side in side-by-side display state
  var rightViewController: UIViewController? {
    willSet {
      guard let child = rightViewController else {
        return
      }
      child.willMove(toParent: nil)
      child.view.removeFromSuperview()
      child.removeFromParent()
    }

    didSet {
      guard let child = rightViewController else {
        return
      }
      if !isViewLoaded {
        loadView()
      }
      addChild(child)
      child.view.frame = rightContainerView.bounds
      rightContainerView.contentView = child.view
      child.didMove(toParent: self)
    }
  }

  /// View controller visible in one display state
  var primaryViewController: UIViewController? {
    switch displayFocus {
      case .left:
        return leftViewController
      case .right:
        return rightViewController
    }
  }

  /// Changes view controller visible in one display state. This must be either left
  /// or right view controller
  func setPrimaryViewController(_ primaryViewController: UIViewController, animated: Bool) {
    assert(primaryViewController == leftViewController ||
           primaryViewController == rightViewController)
    if primaryViewController == leftViewController {
      showLeftView(animated)
    } else if primaryViewController == rightViewController {
      showRightView(animated)
    }
  }

  /// Defines visibility of child view controllers
  enum DisplayMode {
    // Both view controllers are displayed at the same time, side-by-side
    case sideBySide
    // One view controller at a time is displayed
    case one
  }

  /// Current display mode
  private(set) var displayMode: DisplayMode = .sideBySide

  public var preferredDisplayMode: DisplayMode = .sideBySide
  
  func flipAction() {
    switch displayFocus {
      case .left:
        showRightView(true)
      case .right:
        showLeftView(true)
    }
  }
  
  override func loadView() {
    super.loadView()
    // Set background color
    self.view.backgroundColor = .systemFill
    // Prepare container views
    self.leftContainerView = ContainerView()
    self.leftContainerView.clipsToBounds = true
    self.rightContainerView = ContainerView()
    self.rightContainerView.clipsToBounds = true
  }
  
  override func viewWillLayoutSubviews() {
    super.viewWillLayoutSubviews()
    guard !isAnimating else {
      return
    } // Skip routine if animation running
    // Update display state for current size
    displayMode = suggestDisplayMode(for: traitCollection)
    let size = view.bounds.size
    switch displayMode {
      case .sideBySide:
        // Add subviews. Order is not important
        view.addSubview(leftContainerView)
        view.addSubview(rightContainerView)
        // Update left column width
        leftColumnWidth = suggestLeftColumnWidth(for: size)
        // Position container views
        switch displayFocus {
          case .left:
            leftContainerView.frame = leftColumnFrame(for: size)
            rightContainerView.frame = rightColumnFrame(for: size)
          case .right:
            leftContainerView.frame = rightColumnFrame(for: size)
            rightContainerView.frame = leftColumnFrame(for: size)
        }
      case .one:
        // Add/remove subviews based on display focus
        switch displayFocus {
          case .left:
            view.addSubview(leftContainerView)
            leftContainerView.frame = fullFrame(for: size)
            rightContainerView.removeFromSuperview()
          case .right:
            view.addSubview(rightContainerView)
            rightContainerView.frame = fullFrame(for: size)
            leftContainerView.removeFromSuperview()
        }
    }
  }
  
  override func viewWillTransition(to size: CGSize,
                                   with coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransition(to: size, with: coordinator)
    coordinator.animate(alongsideTransition: nil) { _ in
      // Transition completed. Update UI elements.
    }
  }

  override func willTransition(to newCollection: UITraitCollection,
                               with coordinator: UIViewControllerTransitionCoordinator) {
    super.willTransition(to: newCollection, with: coordinator)
    coordinator.animate(alongsideTransition: nil) { _ in
      // Transition completed. Update UI elements.
    }
  }
  
  /// The ContainerView manages layout of the content view.
  private class ContainerView: UIView {
    var contentView: UIView? {
      willSet {
        contentView?.removeFromSuperview()
      }
      didSet {
        guard let contentView = contentView else { return }
        addSubview(contentView)
      }
    }

    override func layoutSubviews() {
      super.layoutSubviews()
      contentView?.frame = bounds
    }
  }

  /// In the one display mode performs transition from right to left view controller.
  /// In the side-by-side display mode brings left view to the front.
  public func showLeftView(_ animated: Bool) {
    guard displayFocus != .left else {
      return
    }
    displayFocus = .left
    switch displayMode {
      case .sideBySide:
        view.bringSubviewToFront(leftContainerView)
      case .one:
        if animated {
          isAnimating = true
          view.insertSubview(leftContainerView, at: 0)
          leftContainerView.frame = fullLeftFrame(for: view.bounds.size)
          UIView.animate(withDuration: 0.3, animations: {
            self.leftContainerView.frame = self.fullFrame(for: self.view.bounds.size)
            self.rightContainerView.frame = self.fullRightFrame(for: self.view.bounds.size)
          },
          completion: { _ in
            self.rightContainerView.removeFromSuperview()
            self.isAnimating = false
          })
        } else {
          view.addSubview(leftContainerView)
          leftContainerView.frame = fullFrame(for: view.bounds.size)
          rightContainerView.removeFromSuperview()
        }
    }
  }

  /// In the one display mode performs transition from left to right view controller.
  /// In the side-by-side display mode brings right view to the front.
  public func showRightView(_ animated: Bool) {
    guard displayFocus != .right else {
      return
    }
    displayFocus = .right
    switch displayMode {
      case .sideBySide:
        view.bringSubviewToFront(rightContainerView)
      case .one:
        if animated {
          isAnimating = true
          view.insertSubview(rightContainerView, at: 0)
          rightContainerView.frame = fullRightFrame(for: view.bounds.size)
          UIView.animate(withDuration: 0.3, animations: {
            self.leftContainerView.frame = self.fullLeftFrame(for: self.view.bounds.size)
            self.rightContainerView.frame = self.fullFrame(for: self.view.bounds.size)
          },
          completion: { _ in
            self.leftContainerView.removeFromSuperview()
            self.isAnimating = false
          })
        } else {
          view.addSubview(rightContainerView)
          rightContainerView.frame = fullFrame(for: view.bounds.size)
          leftContainerView.removeFromSuperview()
        }
    }
  }

  /// Defines visible view controller when one at a time displayed
  public enum DisplayFocus {
    /// When .displayMode set to .one, left view is visible
    case left
    /// When .displayMode set to .one, right view is visible
    case right
  }

  public var displayFocus: DisplayFocus = .left

  /// Flag to mark that animation for flip is in progress
  private var isAnimating = false

  private var leftContainerView: ContainerView!
  private var rightContainerView: ContainerView!
  
  /// Suggests display mode based on trait collection
  private func suggestDisplayMode(for traitCollection: UITraitCollection) -> DisplayMode {
    if preferredDisplayMode == .one {
      return .one
    } else {
      return traitCollection.horizontalSizeClass == .regular ? .sideBySide : .one
    }
  }
  
  /// Width of the left view in side-by-side display mode
  private var leftColumnWidth: CGFloat!
  
  public var preferredLeftColumnFraction: CGFloat = 0.5
  
  /// Suggests width of the left column in side-by-side display mode
  private func suggestLeftColumnWidth(for availableSize: CGSize) -> CGFloat {
    return availableSize.width * preferredLeftColumnFraction
    // return availableSize.width > availableSize.height && availableSize.width > 440.0 * 2.0 ? 440.0 : 320.0
  }
  
  /// Calculates frame that takes all available size
  private func fullFrame(for availableSize: CGSize) -> CGRect {
      return CGRect(origin: .zero, size: availableSize)
  }

  /// Calculates frame that takes all available size on the left of the view
  private func fullLeftFrame(for availableSize: CGSize) -> CGRect {
    switch traitCollection.layoutDirection {
      case .unspecified, .leftToRight:
        return CGRect(x: -availableSize.width, y: 0.0, width: availableSize.width, height: availableSize.height)
      case .rightToLeft:
        return CGRect(x: availableSize.width, y: 0.0, width: availableSize.width, height: availableSize.height)
      @unknown default:
        return CGRect(x: -availableSize.width, y: 0.0, width: availableSize.width, height: availableSize.height)
    }
  }

  /// Calculates frame that takes all available size on the right of the view
  private func fullRightFrame(for availableSize: CGSize) -> CGRect {
    switch traitCollection.layoutDirection {
        case .unspecified, .leftToRight:
            return CGRect(x: availableSize.width, y: 0.0, width: availableSize.width, height: availableSize.height)
        case .rightToLeft:
            return CGRect(x: -availableSize.width, y: 0.0, width: availableSize.width, height: availableSize.height)
      @unknown default:
        return CGRect(x: availableSize.width, y: 0.0, width: availableSize.width, height: availableSize.height)
    }
  }

  /// Frame of the left column for available size. In right to left layout direction positioned on the right.
  private func leftColumnFrame(for availableSize: CGSize) -> CGRect {
    switch traitCollection.layoutDirection {
      case .unspecified, .leftToRight:
        return CGRect(x: 0.0, y: 0.0, width: leftColumnWidth - 1, height: availableSize.height)
      case .rightToLeft:
        return CGRect(x: availableSize.width - leftColumnWidth + 1, y: 0.0, width: leftColumnWidth - 1, height: availableSize.height)
      @unknown default:
        return CGRect(x: 0.0, y: 0.0, width: leftColumnWidth - 1, height: availableSize.height)
    }
  }

  /// Frame of the right column for available size. In right to left layout direction positioned on the left.
  private func rightColumnFrame(for availableSize: CGSize) -> CGRect {
    switch traitCollection.layoutDirection {
      case .unspecified, .leftToRight:
        return CGRect(x: leftColumnWidth, y: 0.0, width: availableSize.width - leftColumnWidth, height: availableSize.height)
      case .rightToLeft:
        return CGRect(x: 0.0, y: 0.0, width: availableSize.width - leftColumnWidth, height: availableSize.height)
      @unknown default:
        return CGRect(x: leftColumnWidth, y: 0.0, width: availableSize.width - leftColumnWidth, height: availableSize.height)
    }
  }
}
