//
//  ConsoleView.swift
//  LispPad
//
//  Created by Matthias Zenger on 14/03/2021.
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
import MobileCoreServices

struct ConsoleView: View {
  @EnvironmentObject var settings: UserSettings
  
  let font: Font
  let infoFont: Font
  let inputFont: Font
  let action: () -> Void
  
  @Binding var content: [ConsoleOutput]
  @Binding var history: [String]
  @Binding var input: String
  @Binding var readingStatus: Interpreter.ReadingStatus
  @Binding var ready: Bool
  @Binding var showSheet: InterpreterView.SheetAction?
  @Binding var showProgressView: String?
  
  init(font: Font = .system(size: 12, design: .monospaced),
       infoFont: Font = .system(size: 13, weight: .bold, design: .default),
       inputFont: Font = .system(size: 12, design: .monospaced),
       action: @escaping () -> Void = {},
       content: Binding<[ConsoleOutput]>,
       history: Binding<[String]>,
       input: Binding<String>,
       readingStatus: Binding<Interpreter.ReadingStatus>,
       ready: Binding<Bool>,
       showSheet: Binding<InterpreterView.SheetAction?>,
       showProgressView: Binding<String?>) {
    self.font = font
    self.infoFont = infoFont
    self.inputFont = inputFont
    self.action = action
    self._content = content
    self._history = history
    self._input = input
    self._readingStatus = readingStatus
    self._ready = ready
    self._showSheet = showSheet
    self._showProgressView = showProgressView
  }
  
  func consoleRow(_ entry: ConsoleOutput, width: CGFloat) -> some View {
    HStack(alignment: .top, spacing: 0) {
      if entry.kind == .command {
        Text("▶︎")
          .font(self.font)
          .frame(alignment: .topLeading)
          .padding(.init(top: 3, leading: 4, bottom: 5, trailing: 3))
      } else if entry.isError {
        Text("⚠️")
          .font(self.font)
          .frame(alignment: .topLeading)
          .padding(.leading, 2)
      }
      if case .drawingResult(let drawing, let image) = entry.kind {
        Image(uiImage: image)
          .resizable()
          .frame(maxWidth: min(image.size.width, width * 0.97),
                 maxHeight: min(image.size.width, width * 0.97) /
                            image.size.width * image.size.height)
          .padding(.leading, 4)
          .padding(.vertical, 8)
          .background(self.settings.consoleGraphicsBackgroundColor)
          .contextMenu {
            Button(action: {
              UIPasteboard.general.image = image
            }) {
              Label("Copy Image", systemImage: "doc.on.clipboard")
            }
            Divider()
            Button(action: {
              self.showProgressView = "Saving image…"
              DispatchQueue.global(qos: .userInitiated).async {
                var res = image
                if let betterImage = iconImage(for: drawing,
                                               width: 1500,
                                               height: 1500,
                                               scale: 4.0,
                                               renderingWidth: 1500,
                                               renderingHeight: 1500) {
                  res = betterImage
                }
                let imageManager = ImageManager()
                _ = try? imageManager.writeImageToLibrary(res, async: true)
                self.showProgressView = nil
              }
            }) {
              Label("Save Image", systemImage: "photo.on.rectangle.angled")
            }
            Button(action: {
              self.showProgressView = "Printing image…"
              DispatchQueue.global(qos: .userInitiated).async {
                var res = image
                if let betterImage = iconImage(for: drawing,
                                               width: 1500,
                                               height: 1500,
                                               scale: 2.0,
                                               renderingWidth: 1500,
                                               renderingHeight: 1500) {
                  res = betterImage
                }
                let printInfo = UIPrintInfo(dictionary: nil)
                printInfo.jobName = "Printing LispPad image…"
                printInfo.outputType = .general
                DispatchQueue.main.async {
                  self.showProgressView = nil
                  let printController = UIPrintInteractionController.shared
                  printController.printInfo = printInfo
                  printController.printingItem = res
                  printController.present(animated: true) { _, isPrinted, error in }
                }
              }
            }) {
              Label("Print Image", systemImage: "printer")
            }
            Button(action: {
              self.showProgressView = "Sharing image…"
              DispatchQueue.global(qos: .userInitiated).async {
                if let betterImage = iconImage(for: drawing,
                                               width: 1500,
                                               height: 1500,
                                               scale: 4.0,
                                               renderingWidth: 1500,
                                               renderingHeight: 1500) {
                  self.showSheet = .shareImage(betterImage)
                } else {
                  self.showSheet = .shareImage(image)
                }
                self.showProgressView = nil
              }
            }) {
              Label("Share Image", systemImage: "square.and.arrow.up")
            }
          }
      } else {
        Text(entry.text) // append location for errors
          .font(entry.kind == .info ? self.infoFont : self.font)
          .fontWeight(entry.kind == .info ? .bold : .regular)
          .foregroundColor(entry.isError ? .red : 
                            (entry.kind == .result ? .blue :
                              (entry.kind == .output ? .secondary : .primary)))
          .frame(maxWidth: .infinity, alignment: .topLeading)
          .fixedSize(horizontal: false, vertical: true)
          .padding(.horizontal, 4)
          .padding(.vertical, entry.kind == .command ? 4 : (entry.kind == .output ? 1 : 0))
          .contextMenu {
            Button(action: {
              UIPasteboard.general.setValue(entry.text,
                                            forPasteboardType: kUTTypePlainText as String)
            }) {
              Label("Copy Text", systemImage: "doc.on.clipboard")
            }
            if entry.text.count <= 800 {
              Button(action: {
                self.input = entry.text
              }) {
                Label("Copy to Input", systemImage: "dock.arrow.down.rectangle")
              }
            }
            Divider()
            Button(action: {
              self.showSheet = .shareText(entry.text)
            }) {
              Label("Share Text", systemImage: "square.and.arrow.up")
            }
          }
      }
    }
  }
  
  var control: some View {
    HStack(alignment: .bottom, spacing: 0) {
      Text(self.input.isEmpty ? " " : self.input)
        .font(self.inputFont)
        .foregroundColor(.clear)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding(EdgeInsets(top: 9, leading: 7, bottom: 9, trailing: 7))
        .overlay(
          TextEditor(text: $input)
            .font(self.inputFont)
            .allowsTightening(false)
            .autocapitalization(.none)
            .disableAutocorrection(true)
            .offset(y: 1))
        .padding(.leading, 3)
      Button(action: action) {
        if !self.ready && self.readingStatus == .accept {
          if self.input.isEmpty {
            Image(systemName: "questionmark.circle.fill")
              .resizable()
              .scaledToFit()
              .frame(height: 26)
              .foregroundColor(.init(.sRGB, red: 0.8, green: 0.5, blue: 0.5, opacity: 1.0))
          } else {
            Image(systemName: "arrow.forward.circle.fill")
              .resizable()
              .scaledToFit()
              .frame(height: 26)
              .foregroundColor(.red)
          }
        } else if self.input.isEmpty {
          Image(systemName: "pencil.circle.fill")
            .resizable()
            .scaledToFit()
            .frame(height: 26)
        } else {
          Image(systemName: "arrow.up.circle.fill")
            .resizable()
            .scaledToFit()
            .frame(height: 26)
        }
      }
      .disabled(self.input.isEmpty || (!self.ready && self.readingStatus != .accept))
      .contextMenu {
        if self.ready {
          ForEach(self.history, id: \.self) { entry in
            Button(entry) {
              self.input = entry
            }
          }
        }
        Button(action: { self.input = "" }) {
          Label("Clear input", systemImage: "xmark.circle.fill")
        }
      }
      .padding(.trailing, 3)
      .offset(y: -4)
      .gesture(DragGesture().onEnded { _ in
        UIApplication.shared.sendAction(
          #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
      })
    }.overlay(
      RoundedRectangle(cornerRadius: 14).stroke(Color.gray, lineWidth: 1)
    )
    .padding(.horizontal, 6)
    .padding(.bottom, -4)
  }
  
  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      GeometryReader { geo in
        ScrollViewReader { scrollViewProxy in
          ConsoleScrollView(.vertical, offsetChanged: { coord in 
            // Swift.print("coord = \(coord)")
          }) {
            LazyVStack(alignment: .leading, spacing: 0) {
              ForEach(self.content, id: \.id) { entry in
                self.consoleRow(entry, width: geo.size.width)
              }
            }.frame(minWidth: 0,
                    maxWidth: .infinity,
                    minHeight: 0,
                    maxHeight: .infinity,
                    alignment: .topLeading
            )
            .onChange(of: self.content.count) { _ in
              if self.content.count > 0 {
                withAnimation {
                  scrollViewProxy.scrollTo(self.content[self.content.endIndex - 1].id,
                                           anchor: .bottomLeading)
                }
              }
            }
            .onChange(of: self.input.count) { _ in
              if self.content.count > 0 {
                scrollViewProxy.scrollTo(self.content[self.content.endIndex - 1].id,
                                         anchor: .bottomLeading)
              }
            }
          }
        }
      }
      // Divider()
      Spacer(minLength: 6)
      self.control
    }
  }
}
