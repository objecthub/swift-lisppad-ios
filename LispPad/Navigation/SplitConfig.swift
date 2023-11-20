//
//  SplitConfig.swift
//  SplitView
//
//  Created by Steven Harris on 1/31/23.
//
//  MIT License
//
//  Copyright (c) 2023 Steven G. Harris
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

import Foundation

/// The orientation of the `primary` and `secondary` views
public enum SplitOrientation: Hashable {
  case horizontal
  case vertical
}

/// The two sides of a SplitView.
/// For `SplitLayout.horizontal`, `primary` is left, `secondary` is right.
/// For `SplitLayout.vertical`, `primary` is top, `secondary` is bottom.
public enum SplitSide: Hashable {
  case primary
  case secondary
}

public struct SplitConstraints {

  /// The minimum fraction that the primary view will be constrained within.
  /// A value of `nil` means unconstrained.
  var minPFraction: CGFloat?

  /// The minimum fraction that the secondary view will be constrained within.
  /// A value of `nil` means unconstrained.
  var minSFraction: CGFloat?

  /// The side that should have sizing priority (i.e., stay fixed) as the containing view
  /// is resized. A value of `nil` means the fraction remains unchanged.
  var priority: SplitSide?

  /// Whether to hide the primary side when dragging stops past minPFraction
  var dragToHideP: Bool

  /// Whether to hide the secondary side when dragging stops past minSFraction
  var dragToHideS: Bool
  
  public init(minPFraction: CGFloat? = nil,
              minSFraction: CGFloat? = nil,
              priority: SplitSide? = nil,
              dragToHideP: Bool = false,
              dragToHideS: Bool = false) {
    self.minPFraction = minPFraction
    self.minSFraction = minSFraction
    self.priority = priority
    self.dragToHideP = dragToHideP && minPFraction != nil
    self.dragToHideS = dragToHideS && minSFraction != nil
  }
}
