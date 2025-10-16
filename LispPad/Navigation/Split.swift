//
//  Split.swift
//  SplitView
//
//  Created by Steven Harris on 8/9/21.
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

import SwiftUI

/// A View with a draggable `splitter` between `primary` and `secondary`.
/// Views are layed out either horizontally or vertically as defined by `orientation`
/// and separated by `spacing()`,  and the `splitter` is  centered within it.
/// The same Split view is used regardless of `orientation`, since the math is all the same
/// but applied to width or height depending on whether `orientation` is `.horizontal` or not.
public struct Split<P: View, D: View, S: View>: View {
  
  /// The `primary` View, left when `orientation == .horizontal`, top when
  /// `orientation == .vertical`.
  @ViewBuilder private let primary: () -> P
  
  /// The `secondary` View, right when `orientation == .horizontal`, bottom when
  /// `orientation == .vertical`.
  @ViewBuilder private let secondary: () -> S
  
  /// The `splitter` view that sits between `primary` and `secondary` views.
  @ViewBuilder private let splitter: () -> D
  
  /// Reserved, visible width of the splitter view. Default is 2.
  private let splitterWidth: CGFloat
  
  /// Hide the splitter view when one side is hidden? Default is true.
  private let hideOnSide: Bool
  
  /// The constraints within which the splitter can travel and which side if any has priority
  private let constraints: SplitConstraints
  
  /// Function to execute with `constrainedFraction` as argument during drag
  private let onDrag: ((CGFloat)->Void)?
  
  /// Used to change the orientation of a split view
  @Binding private var orientation: SplitOrientation
  
  /// Only affects the initial orientation, but updated to `constrainedFraction`
  /// after dragging ends. In this way, Split users can save the `FractionHolder`
  /// state to reflect slider position for restarts.
  @Binding private var fraction: CGFloat
  
  /// Use to hide/show `secondary` independent of dragging. When value is `false`,
  /// will restore to `constrainedFraction`.
  @Binding private var hiddenSide: SplitSide?
  
  /// Set to 
  @State private var splitterHidden: Bool = false
  
  /// Fraction that tracks the `splitter` position across full width/height,
  /// where minPFraction <= constrainedFraction <= (1-minSFraction)
  @State private var constrainedFraction: CGFloat
  
  /// Fraction that tracks the cursor across full width/height during drag, where
  /// 0  <= fullFraction <= 1
  @State private var fullFraction: CGFloat
  
  /// The previous size, used to determine how to change `constrainedFraction`
  /// as size changes
  @State private var oldSize: CGSize? = nil
  
  /// The previous position as we drag the `splitter`
  @State private var previousPosition: CGFloat? = nil
  
  public var body: some View {
    GeometryReader { geometry in
      let horizontal = self.orientation == .horizontal
      let size = geometry.size
      let length = horizontal ? size.width : size.height
      let breadth = horizontal ? size.height : size.width
      let hidePrimary = sideToHide() == .primary || self.hiddenSide == .primary
      let hideSecondary = sideToHide() == .secondary || self.hiddenSide == .secondary
      let minPLength = length * ((hidePrimary ? 0 : self.constraints.minPFraction) ?? 0)
      let minSLength = length * ((hideSecondary ? 0 : self.constraints.minSFraction) ?? 0)
      let pLength = max(minPLength, pLength(in: size))
      let sLength = max(minSLength, sLength(in: size))
      let spacing = self.spacing()
      let pWidth = horizontal ? max(minPLength, min(size.width - spacing, pLength - spacing / 2))
                              : breadth
      let pHeight = horizontal ? breadth
                               : max(minPLength, min(size.height - spacing, pLength - spacing / 2))
      let sWidth = horizontal ? max(minSLength, min(size.width - pLength, sLength - spacing / 2))
                              : breadth
      let sHeight = horizontal ? breadth
                               : max(minSLength, min(size.height - pLength, sLength - spacing / 2))
      let sOffset = horizontal ? CGSize(width: pWidth + spacing, height: 0)
                               : CGSize(width: 0, height: pHeight + spacing)
      let dCenter = horizontal ? CGPoint(x: pWidth + spacing / 2, y: size.height / 2)
                               : CGPoint(x: size.width / 2, y: pHeight + spacing / 2)
      ZStack(alignment: .topLeading) {
        if !hidePrimary {
          primary()
            .frame(width: pWidth, height: pHeight)
        }
        if !hideSecondary {
          secondary()
            .frame(width: sWidth, height: sHeight)
            .offset(sOffset)
        }
        if isDraggable() {
          splitter()
            .position(dCenter)
            .gesture(drag(in: size))
        }
      }
      // Monitor changes to the fraction binding as this is the mechanism for clients
      // to programmatically update split fraction
      .onChange(of: self.fraction) { oldValue, newValue in
        // Enforce fraction constraints
        let constrainedValue = min(1 - (self.constraints.minSFraction ?? 0),
                                   max((self.constraints.minPFraction ?? 0), newValue))
        // Update internal fractions if there is a change
        if constrainedValue != self.constrainedFraction {
          withAnimation {
            self.constrainedFraction = constrainedValue
            self.fullFraction = constrainedValue
          }
        }
      }
      // Our size changes when the window size changes or the containing window's size changes.
      // Note our size doesn't change when dragging the splitter, but when we have nested split
      // views, dragging our splitter can cause the size of another split view to change.
      // Use task instead of both onChange and onAppear because task will only executed when
      // geometry.size changes. Sometimes onAppear starts with CGSize.zero, which causes issues.
      .task(id: geometry.size) {
        self.setConstrainedFraction(in: geometry.size)
      }
      // Can cause problems in some List styles if not clipped
      .clipped()
    }
  }
  
  /// Public initializer allowing `orientation`, `fraction`, `hidden`, `primary` and `secondary`
  /// to be specified. The styling constraints and any custom `splitter` must be specified
  /// using the modifiers if they are not defaults
  public init(orientation: Binding<SplitOrientation> = .constant(.horizontal),
              fraction: Binding<CGFloat> = .constant(0.5),
              hidden: Binding<SplitSide?> = .constant(nil),
              @ViewBuilder primary: @escaping () -> P,
              @ViewBuilder secondary: @escaping () -> S) where D == Splitter {
    self.init(orientation: orientation,
              fraction: fraction,
              hidden: hidden,
              primary: primary,
              secondary: secondary,
              splitter: { Splitter(orientation: orientation) })
  }
  
  /// Public initializer allowing `orientation`, `fraction`, `hidden`, `primary` and `secondary`
  /// to be specified. The styling constraints and any custom `splitter` must be specified
  /// using the modifiers if they are not defaults
  public init(orientation: Binding<SplitOrientation> = .constant(.horizontal),
              fraction: Binding<CGFloat> = .constant(0.5),
              hidden: Binding<SplitSide?> = .constant(nil),
              splitterWidth: CGFloat = 2,
              hideOnSide: Bool = true,
              constraints: SplitConstraints = SplitConstraints(),
              onDrag: ((CGFloat)->Void)? = nil,
              @ViewBuilder primary: @escaping () -> P,
              @ViewBuilder secondary: @escaping () -> S,
              @ViewBuilder splitter: @escaping () -> D) {
    self._orientation = orientation
    self._fraction = fraction
    self._hiddenSide = hidden
    self.splitterWidth = splitterWidth
    self.hideOnSide = constraints.dragToHideP || constraints.dragToHideS || hideOnSide
    self.constraints = constraints
    self.onDrag = onDrag
    self.primary = primary
    self.secondary = secondary
    self.splitter = splitter
    self._constrainedFraction = State(initialValue: fraction.wrappedValue)
    self._fullFraction = State(initialValue: fraction.wrappedValue)
  }
  
  /// Return the spacing between `primary` and `secondary`, which is occupied by the
  /// splitter's `width`. If we are previewing the hide (i.e., drag-to-hide) or we are
  /// using the `hideSplitter` styling and a side is hidden, then return 0, because the
  /// splitter is not visible.
  internal func spacing() -> CGFloat {
    if self.splitterHidden || (self.hiddenSide != nil && self.hideOnSide) {
      return 0
    } else {
      return self.splitterWidth
    }
  }
  
  /// Set the constrainedFraction to maintain the size of the priority side when
  /// size changes, as called from task(id:) modifier.
  private func setConstrainedFraction(in size: CGSize) {
    guard let side = constraints.priority else {
      return
    }
    guard let oldSize else {
      // We need to know the oldSize to be able to adjust constrainedFraction in a way
      // that maintains a fixed width/height for the priority side.
      oldSize = size
      return
    }
    let horizontal = self.orientation == .horizontal
    let oldLength = horizontal ? oldSize.width : oldSize.height
    let newLength = horizontal ? size.width : size.height
    let delta = newLength - oldLength
    self.oldSize = size     // Retain even if delta might be zero because orientation might change
    if delta == 0 { return }
    let oldPLength = constrainedFraction * oldLength
      // If holding the primary side constant, the pLength doesn't change
    let newPLength = side == .primary ? oldPLength : oldPLength + delta
    let newFraction = newPLength / newLength
      // Always keep the constrainedFraction within bounds of minimums if specified
    constrainedFraction = min(1 - (self.constraints.minSFraction ?? 0),
                              max((self.constraints.minPFraction ?? 0), newFraction))
    fraction = constrainedFraction
  }
  
  /// The Gesture recognized by the `splitter`.
  ///
  /// The main function of dragging is to modify the `constrainedFraction` and to track
  /// `fullFraction`.
  ///
  /// Whenever we drag, we also set `hide.value` to `nil`. This is because the `pLength` and
  /// `sLength` key off of `hide` to return the full width/height when its value is non-nil.
  ///
  /// When we are done dragging, we the value of `fraction`, which does nothing unless someone
  /// is holding onto it. If, for example, a FractionHolder was passed-in using the `fraction()`
  /// modifier here or in HSplit/VSplit, then we keep its value in sync so that next time the
  /// Split view is opened, it maintains its state.
  ///
  /// If `dragToHideP`/`dragToHideS` is set in constraints, automatically hide the side when
  /// done dragging if `sideToHide` returns a side that should be hidden. The `splitter` is
  /// always hidden in this case since `splitter.styling.hideSplitter` is forced to true in
  /// the `init` method.
  /// 
  /// Note that during drag, we "preview" that a side will be hidden. While previewing, the
  /// `splitter` color is `.clear`, and the size of `primary` and `secondary` are adjusted.
  /// This is different than when a side is actually hidden (i.e., when `hide.side` is
  /// non-nil). In the latter case, the `splitter` is not part of `body` - it doesn't exist
  /// to be dragged.
  private func drag(in size: CGSize) -> some Gesture {
    return DragGesture()
      .onChanged { gesture in
        // Unhide if the splitter is hidden, but resetting constrainedFraction first
        self.unhide(in: size)
        let fraction = fraction(for: gesture, in: size)
        self.constrainedFraction = fraction.constrained
        self.fullFraction = fraction.full
        self.splitterHidden = !isDraggable() || sideToHide() != nil
        self.onDrag?(constrainedFraction)
        self.previousPosition = self.orientation == .horizontal
                              ? self.constrainedFraction * size.width
                              : self.constrainedFraction * size.height
      }
      .onEnded { gesture in
        previousPosition = nil
        // We are never previewing the hidden state when drag ends.
        self.splitterHidden = false
        self.hiddenSide = sideToHide()
        // The fullFraction is used to determine the sideToHide, so we need to reset when
        // done dragging, but after setting the hidden side.
        self.fullFraction = constrainedFraction
        self.fraction = constrainedFraction
      }
  }
  
  /// Return the side to hide for previewing in the drag-to-hide operation.
  /// Note a side is not necessarily hidden when `sideToHide` is called.
  /// Use a rounded-to-3-decimal-places constrainedFraction because... floating point.
  private func sideToHide() -> SplitSide? {
    guard self.constraints.dragToHideP || self.constraints.dragToHideS else {
      return nil
    }
    if self.constraints.dragToHideP &&
        (round(fullFraction * 1000) / 1000.0) <= (self.constraints.minPFraction! / 2) {
      return .primary
    } else if self.constraints.dragToHideS &&
                (round((1 - fullFraction) * 1000) / 1000.0) <=
                (self.constraints.minSFraction! / 2) {
      return .secondary
    } else {
      return nil
    }
  }
  
  /// Return a new value for `constrained` and `full` fractions based on the DragGesture.
  ///
  /// The `constrained` value is always between `minSFraction` and `minPFraction`
  /// (if specified). The `full` value is always between 0 and 1.
  ///
  /// We use a delta based on `previousPosition` so the `splitter` follows the location
  /// where drag begins, not the center of the splitter. This way the drag is smooth from
  /// the beginning, rather than jumping the splitter location to the starting drag point.
  func fraction(for gesture: DragGesture.Value, in size: CGSize)
                  -> (constrained: CGFloat, full: CGFloat) {
    let horizontal = self.orientation == .horizontal
    // Size in direction of dragging
    let length = horizontal ? size.width : size.height
    // Splitter position prior to drag
    let splitterLocation = length * constrainedFraction
    // Gesture location in direction of dragging
    let gestureLocation = horizontal ? gesture.location.x : gesture.location.y
    // Gesture movement since beginning of drag
    let gestureTranslation = horizontal ? gesture.translation.width : gesture.translation.height
    // Amount moved since last change
    let delta = previousPosition == nil ? gestureTranslation : gestureLocation - previousPosition!
    // New location kept in proper bounds
    let constrainedLocation = max(0, min(length, splitterLocation + delta))
    // Fraction of full size without regard to constraints
    let fullFraction = constrainedLocation / length
    // Fraction of full size kept within constraints
    let constrainedFraction = min(1 - (self.constraints.minSFraction ?? 0),
                                  max((self.constraints.minPFraction ?? 0), fullFraction))
    return (constrained: constrainedFraction, full: fullFraction)
  }
  
  /// Return whether the splitter is draggable. 
  ///
  /// The splitter becomes non-draggable if `splitter.styling.hideSplitter` is `true`
  /// and either side is hidden. It will also be non-draggable when the `primary` side
  /// is hidden and `minPFraction` is specified, or when the `secondary` side is hidden and
  /// `minSFraction` is specified. When the splitter is non-draggable, it is not part of the
  /// `body` of Split. It is not just hidden -- it doesn't even exist to respond to drag events.
  /// 
  /// When using drag-to-split by specifying `constraints.dragToHideP` and/or
  /// `constraints.dragToHideS`, `splitter.styling.hideSplitter` is  forced to `true`.
  /// Why? It's easier to see than explain. Try removing the last line in the private `init`
  /// and see for yourself.
  /// 
  /// **Important**: You must provide a means to unhide the side (e.g., a hide/show
  /// button) if your splitter can become non-draggable.
  /// 
  /// On a related note, when you use an invisible splitter, you will typically specify min 
  /// fractions it has to stay within. If you don't, then it can be dragged to the edge, and
  /// your user will have no visual indication that the other side can be re-exposed by
  /// dragging the invisible splitter out again.
  private func isDraggable() -> Bool {
    if self.hiddenSide == nil {
      return true
    } else if self.hideOnSide {
      return false
    } else if self.constraints.minPFraction == nil && self.constraints.minSFraction == nil {
      return true
    } else if self.hiddenSide! == .primary {
      return self.constraints.minPFraction == nil
    } else {
      return self.constraints.minSFraction == nil
    }
  }
  
  /// Unhide before dragging if a side is hidden.
  ///
  /// When we set `hide.size` to nil, the `body` is recomputed based on `constrainedFraction`.
  /// However, `constrainedFraction` is set to what it was before hiding (so it can be
  /// restored properly). Here we reset `constrainedFraction` to the "hidden" position
  /// so that drag behaves smoothly from that position.
  private func unhide(in size: CGSize) {
    if self.hiddenSide != nil {
      let length = self.orientation == .horizontal ? size.width : size.height
      let pLength = pLength(in: size)
      constrainedFraction = pLength/length
      self.hiddenSide = nil
    }
  }
  
  /// The length of `primary` in the `orientation` direction, without regard to any inset for
  /// the Splitter
  private func pLength(in size: CGSize) -> CGFloat {
    let length = self.orientation == .horizontal ? size.width : size.height
    if let side = self.hiddenSide {
      return side == .secondary ? length : 0
    } else {
      if let sideToHide = sideToHide() {
        return sideToHide == .secondary ? length : 0
      } else {
        return length * constrainedFraction
      }
    }
  }
  
  /// The length of `secondary` in the `orientation` direction, without regard to any inset
  /// for the Splitter
  private func sLength(in size: CGSize) -> CGFloat {
    let length = self.orientation == .horizontal ? size.width : size.height
    if let side = self.hiddenSide {
      return side == .primary ? length : 0
    } else {
      if let sideToHide = sideToHide() {
        return sideToHide == .primary ? length : 0
      } else {
        return length - pLength(in: size)
      }
    }
  }
  
  //MARK: Modifiers
  
  /// Return a new Split with the `splitter` set to the `splitter` passed-in.
  public func splitter<T>(@ViewBuilder _ splitter: @escaping () -> T)
                           -> Split<P, T, S> where T: View {
    return Split<P, T, S>(orientation: self._orientation,
                          fraction: self._fraction,
                          hidden: self._hiddenSide,
                          splitterWidth: self.splitterWidth,
                          hideOnSide: self.hideOnSide,
                          constraints: self.constraints,
                          onDrag: self.onDrag,
                          primary: self.primary,
                          secondary: self.secondary,
                          splitter: splitter)
  }
  
  /// Return a new instance of Split with `constraints` set to a `SplitConstraints` object
  /// holding these values.
  public func constraints(minPFraction: CGFloat? = nil,
                          minSFraction: CGFloat? = nil,
                          priority: SplitSide? = nil,
                          dragToHideP: Bool = false,
                          dragToHideS: Bool = false) -> Split<P, D, S> {
    return self.constraints(SplitConstraints(minPFraction: minPFraction,
                                             minSFraction: minSFraction,
                                             priority: priority,
                                             dragToHideP: dragToHideP,
                                             dragToHideS: dragToHideS))
  }
  
  /// Return a new instance of Split with `constraints` set to the given `SplitConstraints`
  /// object.
  public func constraints(_ constraints: SplitConstraints) -> Split<P, D, S> {
    return Split(orientation: self._orientation,
                 fraction: self._fraction,
                 hidden: self._hiddenSide,
                 splitterWidth: self.splitterWidth,
                 hideOnSide: self.hideOnSide,
                 constraints: constraints,
                 onDrag: self.onDrag,
                 primary: self.primary,
                 secondary: self.secondary,
                 splitter: self.splitter)
  }
  
  /// Return a new instance of Split with `onDrag` set to `callback`.
  ///
  /// The `callback` will be executed as `splitter` is dragged, with the current value
  /// of `constrainedFraction`. Note that `fraction` is different. It is only set when
  /// drag ends, and it is used to determine the initial fraction at open.
  public func onDrag(_ callback: ((CGFloat)->Void)?) -> Split<P, D, S> {
    return Split(orientation: self._orientation,
                 fraction: self._fraction,
                 hidden: self._hiddenSide,
                 splitterWidth: self.splitterWidth,
                 hideOnSide: self.hideOnSide,
                 constraints: self.constraints,
                 onDrag: callback,
                 primary: self.primary,
                 secondary: self.secondary,
                 splitter: self.splitter)
  }
}

/*
struct Split_Previews: PreviewProvider {
  static var previews: some View {
    Split(
      orientation: .constant(.horizontal),
      primary: { Color.green },
      secondary: {
        Split(
          orientation: .constant(.vertical),
          primary: { Color.red },
          secondary: {
            Split(
              orientation: .constant(.horizontal),
              primary: { Color.blue },
              secondary: { Color.yellow }
            )
            .styling(color: Color.purple, visibleThickness: 8)
          }
        ).styling(color: Color.brown, visibleThickness: 8)
      }
    ).styling(color: Color.yellow, visibleThickness: 8)
    Split(
      orientation: .constant(.horizontal),
      primary: {
        Split(
          orientation: .constant(.vertical),
          primary: { Color.red },
          secondary: { Color.green })
      },
      secondary: {
        Split(
          orientation: .constant(.vertical),
          primary: { Color.yellow },
          secondary: { Color.blue })
      }
    )
  }
}
*/
