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
  @State var background: Color? = nil
  @State var image: Image? = nil
  @State var renderTask: Task<Void, Never>? = nil
  @State var drawingId: UInt = .max
  @State var drawingInstr: Int = -1
  @ObservedObject var canvas: CanvasConfig
  private let processor = RenderProcessor()
  
  var body: some View {
    ScrollView([.horizontal, .vertical]) {
      ZStack(alignment: .center) {
        self.background ?? self.settings.consoleGraphicsBackgroundColor
        GeometryReader { proxy in
          ZStack {
            if let image {
              image
            }
          }
          .onChange(of: self.canvas.state) { state in
            if state.drawingId == self.drawingId && state.drawingInstr != self.drawingInstr {
              self.drawingInstr = state.drawingInstr
            } else {
              self.drawingId = state.drawingId
              self.drawingInstr = state.drawingInstr
              self.image = nil
            }
            self.render(size: proxy.size, state: state)
          }
          .onAppear {
            if self.image == nil {
              self.drawingId = self.canvas.state.drawingId
              self.drawingInstr = self.canvas.state.drawingInstr
              self.render(size: proxy.size, state: self.canvas.state)
            }
          }
        }
        .onTapGesture(count: 2) {
          if self.canvas.zoom == 1.0 {
            self.canvas.zoom = self.maxZoom
          } else {
            self.canvas.zoom = 1.0
          }
        }
      }
      .frame(width: self.canvas.width, height: self.canvas.height, alignment: .center)
    }
    .onChange(of: self.canvas.background) { col in
      if let background = col {
        self.background = Color(background)
      } else {
        self.background = nil
      }
    }
    .onAppear {
      if let background = self.canvas.background {
        self.background = Color(background)
      } else {
        self.background = nil
      }
    }
  }
  
  func render(size: CGSize, state: CanvasConfig.State) {
    self.renderTask?.cancel()
    self.renderTask = Task.detached {
      if let image = await processor.render(size: size, state: state), !Task.isCancelled {
        await MainActor.run {
          self.image = image
        }
      }
    }
  }
}

final actor RenderProcessor {
  func render(size: CGSize, state: CanvasConfig.State) async -> Image? {
    if Task.isCancelled {
      return nil
    }
    UIGraphicsBeginImageContextWithOptions(size, false, .zero)
    defer {
      UIGraphicsEndImageContext()
    }
    guard !Task.isCancelled, let context = UIGraphicsGetCurrentContext() else {
      return nil
    }
    context.scaleBy(x: state.drawScale, y: state.drawScale)
    state.drawing.draw()
    guard !Task.isCancelled, let uiImage = UIGraphicsGetImageFromCurrentImageContext() else {
      return nil
    }
    return Image(uiImage: uiImage)
  }
}
