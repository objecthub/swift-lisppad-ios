//
//  CanvasScrollView.swift
//  LispPad
//
//  Created by Matthias Zenger on 12/11/2023.
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
import LispKit

struct CanvasPanel: View {
  @EnvironmentObject var globals: LispPadGlobals
  @EnvironmentObject var interpreter: Interpreter
  @ObservedObject var state: InterpreterState
  @State var showSizeEditor: Bool = false
  
  private func round(_ x: CGFloat) -> CGFloat {
    let y = floor(x)
    let d = x - y
    if d < 0.1 {
      return y
    } else if d < 0.3 {
      return y + 0.2
    } else if d < 0.5 {
      return y + 0.4
    } else if d < 0.7 {
      return y + 0.6
    } else if d < 0.9 {
      return y + 0.8
    } else {
      return y + 1.0
    }
  }
  
  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      VStack(alignment: .leading, spacing: 0) {
        Divider()
          .offset(x: 0.0, y: -1.0)
          .ignoresSafeArea(.container, edges: [.leading, .trailing])
        HStack(alignment: .center, spacing: 0) {
          Text("Canvas:")
            .font(.footnote)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
          GeometryReader { geometry in
            Menu {
              Picker("", selection: self.$interpreter.canvas) {
                ForEach(self.interpreter.canvases) { canvas in
                  Text(canvas.name).tag(canvas)
                }
              }
            } label: {
              HStack(alignment: .center, spacing: 4) {
                Text(self.interpreter.canvas.name)
                  .lineLimit(1)
                  .allowsTightening(true)
                if self.interpreter.canvases.count > 1 {
                  Image(systemName: "chevron.up.chevron.down")
                }
              }
              .font(.footnote)
            }
            .fixedSize(horizontal: false, vertical: false)
            .frame(maxWidth: geometry.size.width, maxHeight: 25, alignment: .leading)
            .disabled(self.interpreter.canvases.isEmpty)
          }
          .frame(maxHeight: 25, alignment: .center)
          Spacer(minLength: 0)
          if self.interpreter.canvas != .empty {
            Button {
              self.showSizeEditor = true
            } label: {
              HStack(alignment: .center, spacing: 1) {
                Text("⨉")
                Text("\(Int(self.interpreter.canvas.size.width))\n" +
                     "\(Int(self.interpreter.canvas.size.height))")
              }
              .font(.caption2)
              .foregroundColor(.gray)
              .lineLimit(2)
              .allowsTightening(true)
              .fixedSize(horizontal: true, vertical: false)
            }
            .padding(4)
            .popover(isPresented: self.$showSizeEditor) {
              CanvasSizeEditor(width: self.interpreter.canvas.size.width,
                               height: self.interpreter.canvas.size.height,
                               scale: self.interpreter.canvas.scale) { size, scale in
                withAnimation {
                  self.interpreter.canvas.size.width = size.width
                  self.interpreter.canvas.size.height = size.height
                  self.interpreter.canvas.scale = scale
                  self.interpreter.objectWillChange.send()
                }
              }
              .frame(idealWidth: 240, idealHeight: 100)
              .presentationCompactAdaptation(horizontal: .popover, vertical: .popover)
            }
          }
          HStack(alignment: .center, spacing: 4) {
            Button {
              let x = self.interpreter.canvas.zoom
              withAnimation {
                self.interpreter.canvas.zoom = self.round(x - (x >= 0.6 ? 0.2 : 0.0))
                self.interpreter.objectWillChange.send()
              }
            } label: {
              Image(systemName: "minus.magnifyingglass")
                .font(LogView.iconFont)
            }
            Text("\(Int(self.interpreter.canvas.zoom * 100.0))%")
              .font(.caption)
              .foregroundColor(self.interpreter.canvas == .empty ? .gray : .primary)
              .lineLimit(1)
              .allowsTightening(true)
              .fixedSize(horizontal: true, vertical: false)
            Button {
              let x = self.interpreter.canvas.zoom
              withAnimation {
                self.interpreter.canvas.zoom = self.round(x + (x <= 2.8 ? 0.2 : 0.0))
                self.interpreter.objectWillChange.send()
              }
            } label: {
              Image(systemName: "plus.magnifyingglass")
                .font(LogView.iconFont)
            }
          }
          .padding(.leading, 6)
          .padding(.trailing, 4)
          .disabled(self.interpreter.canvas == .empty)
          Menu {
            Button {
              self.state.showProgressView = "Saving Image…"
              DispatchQueue.global(qos: .userInitiated).async {
                if let res = iconImage(for: self.interpreter.canvas.drawing,
                                       width: 1500,
                                       height: 1500,
                                       scale: 4.0,
                                       renderingWidth: 1500,
                                       renderingHeight: 1500) {
                  let imageManager = ImageManager()
                  _ = try? imageManager.writeImageToLibrary(res, async: true)
                }
                DispatchQueue.main.async {
                  self.state.showProgressView = nil
                }
              }
            } label: {
              Label("Save Image", systemImage: "photo.on.rectangle.angled")
            }
            .disabled(self.state.showProgressView != nil)
            Button {
              self.state.showProgressView = "Saving Canvas…"
              DispatchQueue.global(qos: .userInitiated).async {
                if let image = iconImage(for: self.interpreter.canvas.drawing,
                                         width: self.interpreter.canvas.size.width,
                                         height: self.interpreter.canvas.size.height,
                                         scale: 4.0,
                                         extra: self.interpreter.canvas.scale,
                                         renderingWidth: self.interpreter.canvas.size.width,
                                         renderingHeight: self.interpreter.canvas.size.height,
                                         contentOnly: false) {
                  let imageManager = ImageManager()
                  _ = try? imageManager.writeImageToLibrary(image, async: true)
                }
                DispatchQueue.main.async {
                  self.state.showProgressView = nil
                }
              }
            } label: {
              Label("Save Canvas", systemImage: "photo.on.rectangle")
            }
            .disabled(self.state.showProgressView != nil)
            Button {
              self.state.showProgressView = "Printing Canvas…"
              DispatchQueue.global(qos: .userInitiated).async {
                if let res = iconImage(for: self.interpreter.canvas.drawing,
                                       width: self.interpreter.canvas.size.width,
                                       height: self.interpreter.canvas.size.height,
                                       scale: 4.0,
                                       extra: self.interpreter.canvas.scale,
                                       renderingWidth: self.interpreter.canvas.size.width,
                                       renderingHeight: self.interpreter.canvas.size.height,
                                       contentOnly: false) {
                  let printInfo = UIPrintInfo(dictionary: nil)
                  printInfo.jobName = "Printing LispPad Canvas…"
                  printInfo.outputType = .general
                  DispatchQueue.main.async {
                    self.state.showProgressView = nil
                    let printController = UIPrintInteractionController.shared
                    printController.printInfo = printInfo
                    printController.printingItem = res
                    printController.present(animated: true) { _, isPrinted, error in }
                  }
                } else {
                  DispatchQueue.main.async {
                    self.state.showProgressView = nil
                  }
                }
              }
            } label: {
              Label("Print Canvas", systemImage: "printer")
            }
            .disabled(self.state.showProgressView != nil)
            Divider()
            Button(role: .destructive) {
              withAnimation {
                self.interpreter.removeCanvas()
              }
            } label: {
              Label("Close Canvas", systemImage: "xmark.rectangle")
            }
          } label: {
            Image(systemName: "ellipsis.circle")
              .font(LogView.iconFont)
              .padding(.horizontal, 8)
          }
          .disabled(self.interpreter.canvas == .empty || self.state.showProgressView != nil)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .background(Color(.tertiarySystemBackground).opacity(0.85)
          .ignoresSafeArea(.container, edges: [.leading, .trailing]))
        Divider()
          .ignoresSafeArea(.container, edges: [.leading, .trailing])
      }
      ZStack(alignment: .center) {
        Color(.secondarySystemBackground)
          .ignoresSafeArea(.container, edges: [.leading, .trailing])
        if self.interpreter.canvas != .empty {
          VStack(alignment: .leading, spacing: 0) {
            CanvasView(canvas: self.interpreter.canvas)
            if let label = self.interpreter.canvas.label {
              Divider()
              HStack(alignment: .center, spacing: 0) {
                Text(label)
                  .font(.footnote)
                  .foregroundColor(.primary)
                  .lineLimit(8)
                  .allowsTightening(true)
                  .padding(8)
                Spacer()
              }
              .background(Color(.tertiarySystemBackground).opacity(0.85))
            }
          }
        }
      }.frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .onChange(of: self.interpreter.canvases) { canvases in
      if let canvas = canvases.first {
        if !canvases.contains(self.interpreter.canvas) {
          self.interpreter.canvas = canvas
        }
      } else if self.interpreter.canvas != .empty {
        self.interpreter.canvas = .empty
      }
    }
  }
}
