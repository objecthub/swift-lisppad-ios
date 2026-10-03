//
//  ContainerGeometry.swift
//  LispPad
//
//  Created by Matthias Zenger on 03/10/2026.
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

/// 
/// Represents the geometric properties of a container view, including size, safe area insets,
/// and reserved screen areas (such as notches, Dynamic Island, etc.).
///
/// This structure is used to calculate available space for navigation bars and other UI elements
/// while accounting for system-reserved areas and safe area insets.
/// 
struct ContainerGeometry: Equatable {
  
  /// Defines the display mode for navigation bars based on available width.
  enum NavigationBarMode {
    case full     // Full-featured navigation bar with all controls visible
    case compact  // Compact navigation bar with some controls hidden
    case minimal  // Minimal navigation bar with only essential controls
  }
  
  /// The size of the usable area within safe area insets.
  let size: CGSize
  
  /// The safe area insets that define padding from screen edges.
  let safeAreaInsets: EdgeInsets
  
  /// An array of reserved rectangles representing system UI elements like notches or Dynamic Island.
  let reserved: [CGRect]
  
  /// Returns the total container size including safe area insets.
  ///
  /// This computed property adds the safe area insets to the base size to get the full
  /// container dimensions including areas under system UI elements.
  var containerSize: CGSize {
    return CGSize(width: self.size.width + self.safeAreaInsets.leading + self.safeAreaInsets.trailing,
                  height: self.size.height + self.safeAreaInsets.top + self.safeAreaInsets.bottom)
  }
  
  /// Calculates the available width for a navigation bar on either the left or right side.
  ///
  /// This method accounts for reserved screen areas (like notches or Dynamic Island) that may
  /// overlap with the navigation bar position. It reduces the available width by the amount
  /// occupied by any reserved areas.
  ///
  /// - Parameters:
  ///   - left: If `true`, calculates width for the left side; otherwise for the right side.
  ///   - masterWidthFraction: The fraction of the total width allocated to the master (left) pane.
  /// - Returns: The available width for the navigation bar after accounting for reserved areas.
  func navigationBarWidth(left: Bool, masterWidthFraction: CGFloat) -> CGFloat {
    if left {
      // Calculate initial width based on master fraction
      var width = self.size.width * masterWidthFraction
      let right = self.safeAreaInsets.leading + width
      let top = 10.0 - self.safeAreaInsets.top  // Y-position to check for overlaps
      
      // Check each reserved area for overlap with the navigation bar region
      for frame in self.reserved {
        if frame.minY < top && frame.maxY > top &&
           frame.minX < right && frame.maxX > self.safeAreaInsets.leading {
          // Reserved area overlaps with our navigation bar - reduce width accordingly
          if frame.maxX <= right {
            if frame.minX < self.safeAreaInsets.leading {
              width -= frame.maxX - self.safeAreaInsets.leading
            } else {
              width -= frame.width
            }
          } else {
            width -= right - frame.minX
          }
        }
      }
      return width
    } else {
      // Calculate width for right side
      var width = self.size.width * (1.0 - masterWidthFraction)
      let left = self.safeAreaInsets.leading + self.size.width * masterWidthFraction
      let top = 10.0 - self.safeAreaInsets.top
      
      // Check each reserved area for overlap with the right navigation bar region
      for frame in self.reserved {
        if frame.minY < top && frame.maxY > top &&
            frame.maxX > left && frame.minX < self.safeAreaInsets.leading + self.size.width {
          // Reserved area overlaps with right navigation bar - reduce width accordingly
          if frame.minX >= left  {
            if frame.maxX > self.safeAreaInsets.leading + self.size.width {
              width -= self.safeAreaInsets.leading + self.size.width - frame.minX
            } else {
              width -= frame.width
            }
          } else {
            width -= frame.maxX - left
          }
        }
      }
      return width
    }
  }
  
  /// Calculates the navigation bar width for a specific pane in a split view layout.
  ///
  /// This method determines which side of the screen the navigation bar should appear on
  /// based on the split view mode and whether it's for the interpreter or editor pane.
  ///
  /// - Parameters:
  ///   - interpreter: If `true`, calculates for the interpreter pane; otherwise for the editor.
  ///   - splitViewMode: The current split view layout mode.
  ///   - masterWidthFraction: The fraction of total width allocated to the master pane.
  /// - Returns: The available width for the navigation bar.
  func navigationBarWidth(interpreter: Bool,
                          splitViewMode: SideBySideMode,
                          masterWidthFraction: CGFloat) -> CGFloat {
    switch splitViewMode {
      case .normal:
        return self.navigationBarWidth(left: interpreter, masterWidthFraction: masterWidthFraction)
      case .swapped:
        return self.navigationBarWidth(left: !interpreter, masterWidthFraction: masterWidthFraction)
      case .leftOnLeft, .rightOnRight, .leftOnRight, .rightOnLeft:
        // For stacked/overlapping modes, use full width
        return self.navigationBarWidth(left: true, masterWidthFraction: 1.0)
    }
  }
  
  /// Determines the appropriate navigation bar display mode based on available width.
  ///
  /// This method calculates the available width and returns an appropriate display mode.
  /// Narrower widths result in more compact navigation bar modes with fewer visible controls.
  ///
  /// - Parameters:
  ///   - interpreter: If `true`, determines mode for the interpreter pane; otherwise for the editor.
  ///   - splitViewMode: The current split view layout mode.
  ///   - masterWidthFraction: The fraction of total width allocated to the master pane.
  /// - Returns: The navigation bar mode (full, compact, or minimal) appropriate for the available width.
  func navigationBarMode(interpreter: Bool,
                         splitViewMode: SideBySideMode,
                         masterWidthFraction: CGFloat) -> NavigationBarMode {
    let width = self.navigationBarWidth(interpreter: interpreter,
                                        splitViewMode: splitViewMode,
                                        masterWidthFraction: masterWidthFraction)
    // Determine mode based on available width
    // TODO: Currently uses same thresholds for both panes; could be customized per pane
    if interpreter {
      if width < 300 {
        return .minimal
      } else {
        return .full
      }
    } else {
      if width < 300 {
        return .minimal
      } else {
        return .full
      }
    }
  }
  
  /// Returns `true` if the container has zero size (both width and height are 0).
  var isEmpty: Bool {
    return self.size.width == 0.0 && self.size.height == 0.0
  }
  
  /// A container geometry instance with zero size and no safe area insets.
  /// Used as a default or placeholder value.
  static let zero: ContainerGeometry =
      ContainerGeometry(size: .zero,
                        safeAreaInsets: .init(top: 0, leading: 0, bottom: 0, trailing: 0),
                        reserved: [])
}

/// Extension to make `ContainerGeometry` available as an environment value in SwiftUI views.
extension EnvironmentValues {
  /// Environment value for accessing container geometry information.
  ///
  /// Use this in your SwiftUI views to access container size, safe area insets,
  /// and reserved screen areas:
  ///
  /// ```swift
  /// @Environment(\.containerGeometry) var containerGeometry
  /// ```
  @Entry var containerGeometry: ContainerGeometry = .zero
}
