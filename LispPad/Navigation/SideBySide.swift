//
//  SideBySide.swift
//  LispPad
//
//  Created by Matthias Zenger on 27/10/2023.
//  Copyright © 2023 Matthias Zenger. All rights reserved.
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
import SwiftUI

enum SideBySideMode: Int {
  case normal = 0
  case swapped = 1
  case leftOnLeft = 2
  case rightOnRight = 3
  case leftOnRight = 4
  case rightOnLeft = 5
  
  mutating func toggle() {
    switch self {
      case .leftOnLeft:
        self = .rightOnRight
      case .leftOnRight:
        self = .rightOnLeft
      case .rightOnRight:
        self = .leftOnLeft
      case .rightOnLeft:
        self = .leftOnRight
      default:
        break
    }
  }
  
  mutating func swap() {
    switch self {
      case .normal:
        self = .swapped
      case .swapped:
        self = .normal
      default:
        break
    }
  }
  
  mutating func makeSideBySide() {
    switch self {
      case .leftOnLeft, .rightOnRight:
        self = .normal
      case .leftOnRight, .rightOnLeft:
        self = .swapped
      default:
        break
    }
  }
  
  mutating func close(left: Bool) {
    switch self {
      case .normal:
        self = left ? .rightOnRight : .leftOnLeft
      case .swapped:
        self = left ? .rightOnLeft : .leftOnRight
      default:
        break
    }
  }
  
  mutating func expand(left: Bool) {
    self.close(left: !left)
  }
  
  var isSideBySide: Bool {
    switch self {
      case .normal, .swapped:
        return true
      default:
        return false
    }
  }
  
  var isSwapped: Bool {
    switch self {
      case .swapped, .leftOnRight, .rightOnLeft:
        return true
      default:
        return false
    }
  }
  
  var sideToHide: SplitSide? {
    switch self {
      case .leftOnLeft, .rightOnLeft:
        return .secondary
      case .leftOnRight, .rightOnRight:
        return .primary
      default:
        return nil
    }
  }
}

struct SideBySideNavigator: View {
  static let lightColor: Color = Color(UIColor(named: "KeyColor") ?? UIColor.lightText)
  
  let leftSide: Bool
  let allowSplit: Bool
  @Binding var mode: SideBySideMode
  @Binding var fraction: CGFloat
  
  var body: some View {
    if self.mode.isSideBySide {
      Menu {
        ControlGroup {
          Button(action: {
            withAnimation {
              self.fraction = self.mode.isSwapped ? (self.leftSide ? 0.65 : 0.35)
                                                  : (self.leftSide ? 0.35 : 0.65)
            }
          }) {
            Label("Small", systemImage: "s.circle")
          }
          Button(action: {
            withAnimation {
              self.fraction = 0.5
            }
          }) {
            Label("Medium", systemImage: "m.circle")
          }
          Button(action: {
            withAnimation {
              self.fraction = self.mode.isSwapped ? (self.leftSide ? 0.35 : 0.65)
                                                  : (self.leftSide ? 0.65 : 0.35)
            }
          }) {
            Label("Large", systemImage: "l.circle")
          }
        }
        Button(action: {
          withAnimation {
            self.mode.swap()
          }
        }) {
          Label("Flip", systemImage: "arrow.triangle.2.circlepath")
        }
        Button(action: {
          withAnimation {
            self.mode.close(left: self.leftSide)
          }
        }) {
          Label("Close", systemImage: "square.slash")
        }
      } label: {
        Image(systemName: "arrow.left.and.right.square")
          .foregroundColor(.primary)
          .font(LispPadUI.toolbarSwitchFont)          
      } primaryAction: {
        self.mode.expand(left: self.leftSide)
      }
    } else {
      HStack(alignment: .center, spacing: 2) {
        Button(action: {
          withAnimation {
            self.mode.toggle()
          }
        }) {
          if self.leftSide {
            ZStack {
              Image(systemName: "rectangle.fill.on.rectangle.fill")
                .foregroundColor(.primary)
                .font(LispPadUI.toolbarSwitchFont)
              Image(systemName: "pencil")
                .foregroundColor(SideBySideNavigator.lightColor)
                .font(.system(size: 10, weight: .bold))
                .offset(x: 3, y: 1.6)
            }
          } else {
            ZStack {
              Image(systemName: "rectangle.fill.on.rectangle.fill")
                .foregroundColor(.primary)
                .font(LispPadUI.toolbarSwitchFont)
              Image(systemName: "terminal")
                .foregroundColor(SideBySideNavigator.lightColor)
                .font(.system(size: 15.5, weight: .regular))
                .offset(x: 2.2, y: 1.5)
            }
          }
        }
        if self.allowSplit {
          Button(action: {
            withAnimation {
              self.mode.makeSideBySide()
            }
          }) {
            Image(systemName: "rectangle.split.2x1")
              .foregroundColor(.primary)
              .font(LispPadUI.toolbarSwitchFont)
          }
        }
      }
    }
  }
}

struct SideBySide<Left: View, Right: View>: View {
  @State var hidden: SplitSide?
  @State var delayedMode: SideBySideMode
  @Binding var mode: SideBySideMode
  @Binding var fraction: CGFloat
  let leftMinFraction: CGFloat
  let rightMinFraction: CGFloat
  let dragToHide: Bool
  let visibleThickness: CGFloat
  let invisibleThickness: CGFloat
  let left: Left
  let right: Right
  
  init(mode: Binding<SideBySideMode>,
       fraction: Binding<CGFloat>,
       leftMinFraction: CGFloat = 0.2,
       rightMinFraction: CGFloat = 0.2,
       dragToHide: Bool = true,
       visibleThickness: CGFloat = 1.0,
       invisibleThickness: CGFloat = 20.0,
       @ViewBuilder left: () -> Left,
       @ViewBuilder right: () -> Right) {
    let hidden: SplitSide?
    switch mode.wrappedValue {
      case .normal, .swapped:
        hidden = nil
      case .leftOnLeft, .leftOnRight:
        hidden = .secondary
      case .rightOnRight, .rightOnLeft:
        hidden = .primary
    }
    self._hidden = State(initialValue: hidden)
    self._delayedMode = State(initialValue: mode.wrappedValue)
    self._mode = mode
    self._fraction = fraction
    self.leftMinFraction = leftMinFraction
    self.rightMinFraction = rightMinFraction
    self.dragToHide = dragToHide
    self.visibleThickness = visibleThickness
    self.invisibleThickness = invisibleThickness
    self.left = left()
    self.right = right()
  }
  
  var body: some View {
    Split(
      orientation: .constant(.horizontal),
      fraction: self.$fraction,
      hidden: self.$hidden,
      splitterWidth: self.visibleThickness,
      hideOnSide: true,
      constraints: SplitConstraints(minPFraction: self.leftMinFraction,
                                    minSFraction: self.rightMinFraction,
                                    priority: nil,
                                    dragToHideP: self.dragToHide,
                                    dragToHideS: self.dragToHide),
      primary: {
        if self.mode.isSwapped {
          right.transition(.move(edge: .leading))
        } else {
          left.transition(.move(edge: .leading))
        }
      }, secondary: {
        if self.mode.isSwapped {
          left.transition(.move(edge: .trailing))
        } else {
          right.transition(.move(edge: .trailing))
        }
      }, splitter: {
        Splitter(orientation: .constant(.horizontal),
                 color: .gray,
                 inset: self.visibleThickness / 2.0,
                 width: self.visibleThickness,
                 invisibleWidth: self.invisibleThickness)
        .transition(.move(edge: self.delayedMode.sideToHide == .primary ? .leading : .trailing))
      }
    )
    .constraints(minPFraction: self.leftMinFraction,
                 minSFraction: self.rightMinFraction,
                 dragToHideP: self.dragToHide,
                 dragToHideS: self.dragToHide)
    .onChange(of: self.mode, perform: { value in
      withAnimation {
        self.hidden = value.sideToHide
      }
      if self.delayedMode.isSideBySide {
        self.delayedMode = value
      } else {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
          self.delayedMode = value
        }
      }
    })
    .onChange(of: self.hidden, perform: { value in
      if value == .primary {
        let newValue: SideBySideMode = self.mode.isSwapped ? .leftOnRight : .rightOnRight
        if self.mode != newValue {
          self.mode = newValue
        }
      } else if value == .secondary {
        let newValue: SideBySideMode = self.mode.isSwapped ? .rightOnLeft : .leftOnLeft
        if self.mode != newValue {
          self.mode = newValue
        }
      }
    })
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}
