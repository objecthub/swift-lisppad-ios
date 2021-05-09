//
//  NavigationControl.swift
//  LispPad
//
//  Created by Matthias Zenger on 09/05/2021.
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

struct NavigationControl: View {
  let splitView: Bool
  let masterView: Bool
  @Binding var splitViewMode: SplitViewMode
  @Binding var masterWidthFraction: Double
  let action: () -> Void
  let splitViewAction: () -> Void

  var body: some View {
    if self.splitView && self.splitViewMode == (self.masterView ? .normal : .swapped) {
      Button(action: { self.splitViewMode = self.masterView ? .swapped : .normal }) {
        Image(systemName: "arrow.triangle.2.circlepath")
          .foregroundColor(.primary)
          .font(InterpreterView.toolbarSwitchFont)
      }
    } else if self.splitView && self.splitViewMode == (self.masterView ? .swapped : .normal) {
      Menu {
        Button(action: {
          withAnimation(.linear) {
            self.masterWidthFraction = 0.65
          }
        }) {
          Label("Small", systemImage: "s.circle")
        }
        .disabled(self.masterWidthFraction > 0.64)
        Button(action: {
          withAnimation(.linear) {
            self.masterWidthFraction = 0.5
          }
        }) {
          Label("Medium", systemImage: "m.circle")
        }
        .disabled(self.masterWidthFraction > 0.49 && self.masterWidthFraction < 0.51)
        Button(action: {
          withAnimation(.linear) {
            self.masterWidthFraction = 0.35
          }
        }) {
          Label("Large", systemImage: "l.circle")
        }
        .disabled(self.masterWidthFraction < 0.36)
        Divider()
        Button(action: {
          withAnimation(.linear) {
            self.splitViewMode = self.masterView ? .secondaryOnly : .primaryOnly
          }
        }) {
          Label("Close", systemImage: "square.slash")
        }
      } label: {
        Image(systemName: "arrow.left.and.right")
          .foregroundColor(.primary)
          .font(InterpreterView.toolbarFont)
      }
    } else {
      HStack {
        Button(action: {
          if self.splitView {
            splitViewAction()
            withAnimation(.linear) {
              self.splitViewMode = self.masterView ? .secondaryOnly : .primaryOnly
            }
          } else {
            action()
          }
        }) {
          Image(systemName: self.masterView ? "pencil.circle.fill" : "terminal.fill")
            .foregroundColor(.primary)
            .font(InterpreterView.toolbarSwitchFont)
        }
        if self.splitView {
          Button(action: {
            self.splitViewMode = self.masterView ? .normal : .swapped
          }) {
            Image(systemName: "rectangle.split.2x1")
              .foregroundColor(.primary)
              .font(InterpreterView.toolbarFont)
          }
          Spacer(minLength: 12)
        }
      }
    }
  }
}

struct NavigationControl_Previews: PreviewProvider {
  @State static var splitViewMode: SplitViewMode = .normal
  @State static var masterWidthFraction: Double = 0.5

  static var previews: some View {
    NavigationControl(splitView: true,
                      masterView: true,
                      splitViewMode: $splitViewMode,
                      masterWidthFraction: $masterWidthFraction,
                      action: { },
                      splitViewAction: { })
  }
}
