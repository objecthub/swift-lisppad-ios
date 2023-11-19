//
//  CanvasView.swift
//  LispPad
//
//  Created by Matthias Zenger on 11/11/2023.
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

import SwiftUI

struct CanvasView: View {
  private let minZoom: CGFloat = 0.5
  private let maxZoom: CGFloat = 3.0
  @EnvironmentObject var settings: UserSettings
  @EnvironmentObject var interpreter: Interpreter
  @ObservedObject var canvas: CanvasConfig
  
  var body: some View {
    ScrollView([.horizontal, .vertical]) {
      ZStack(alignment: .center) {
        if let background = self.canvas.background {
          Color(background)
        } else {
          self.settings.consoleGraphicsBackgroundColor
        }
        Canvas(opaque: false,
               colorMode: .nonLinear,
               rendersAsynchronously: false) { context, size in
          context.withCGContext { cgcontext in
            UIGraphicsPushContext(cgcontext)
            defer {
              UIGraphicsPopContext()
            }
            cgcontext.scaleBy(x: self.canvas.drawScale, y: self.canvas.drawScale)
            self.canvas.drawing.draw()
            cgcontext.scaleBy(x: 1.0, y: 1.0)
          }
        }
        .onTapGesture(count: 2) {
          withAnimation {
            if self.canvas.zoom == 1.0 {
              self.canvas.zoom = self.maxZoom
            } else {
              self.canvas.zoom = 1.0
            }
            self.interpreter.objectWillChange.send()
          }
        }
      }
      .frame(width: self.canvas.width, height: self.canvas.height, alignment: .center)
    }
  }
}
