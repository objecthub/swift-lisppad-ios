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
  
  @State var dynamicHeight: CGFloat = 100
  
  let font: Font
  let infoFont: Font
  let action: () -> Void
  @State var inputBuffer: String? = nil
  @State var inputHistoryIndex: Int = -1
  @State var updateConsole: ((CodeEditorTextView) -> Void)? = nil
  @StateObject var keyboardObserver = KeyboardObserver()
  
  @Binding var content: [ConsoleOutput]
  @Binding var history: [String]
  @Binding var input: String
  @Binding var selectedInputRange: NSRange
  @Binding var readingStatus: Interpreter.ReadingStatus
  @Binding var ready: Bool
  @Binding var showSheet: InterpreterView.SheetAction?
  @Binding var showProgressView: String?
  
  init(font: Font = .system(size: 12, design: .monospaced),
       infoFont: Font = .system(size: 13, weight: .bold, design: .default),
       action: @escaping () -> Void = {},
       content: Binding<[ConsoleOutput]>,
       history: Binding<[String]>,
       input: Binding<String>,
       selectedInputRange: Binding<NSRange>,
       readingStatus: Binding<Interpreter.ReadingStatus>,
       ready: Binding<Bool>,
       showSheet: Binding<InterpreterView.SheetAction?>,
       showProgressView: Binding<String?>) {
    self.font = font
    self.infoFont = infoFont
    self.action = action
    self._content = content
    self._history = history
    self._input = input
    self._selectedInputRange = selectedInputRange
    self._readingStatus = readingStatus
    self._ready = ready
    self._showSheet = showSheet
    self._showProgressView = showProgressView
  }
  
  func errorText(image: String, text: String?) -> Text {
    return text == nil ? Text("") : Text("\n") +
                                    Text(Image(systemName: image)) +
                                    Text(" " + text!)
  }
  
  func errorRow(_ text: String, _ context: ErrorContext?) -> some View {
    (Text(text).foregroundColor(.red) +
      self.errorText(image: "mappin.and.ellipse", text: context?.position) +
      self.errorText(image: "building.columns", text: context?.library) +
      self.errorText(image: "location", text: context?.stackTrace))
    .font(self.font)
    .fontWeight(.regular)
    .foregroundColor(.secondary)
    .frame(maxWidth: .infinity, alignment: .topLeading)
    .fixedSize(horizontal: false, vertical: true)
    .padding(.leading, 4)
    .contextMenu {
      Button(action: {
        UIPasteboard.general.setValue(text, forPasteboardType: kUTTypePlainText as String)
      }) {
        Label("Copy Error", systemImage: "doc.on.clipboard")
      }
      Divider()
      Button(action: {
        self.showSheet = .shareText(text)
      }) {
        Label("Share Error", systemImage: "square.and.arrow.up")
      }
    }
  }
  
  func consoleRow(_ entry: ConsoleOutput, width: CGFloat) -> some View {
    HStack(alignment: .top, spacing: 0) {
      if entry.kind == .command {
        Text("▶︎")
          .font(self.font)
          .frame(alignment: .topLeading)
          .padding(EdgeInsets(top: 3, leading: 4, bottom: 5, trailing: 3))
      } else if entry.isError {
        Text("⚠️")
          .font(self.font)
          .frame(alignment: .topLeading)
          .padding(.leading, 2)
      }
      switch entry.kind {
        case .drawingResult(let drawing, let image):
          VStack(alignment: .leading, spacing: 2) {
            Text(entry.text)
              .font(self.font)
              .fontWeight(.regular)
              .foregroundColor(.blue)
              .frame(maxWidth: .infinity, alignment: .topLeading)
              .fixedSize(horizontal: false, vertical: true)
            Image(uiImage: image)
              .resizable()
              .frame(maxWidth: min(image.size.width, width * 0.98),
                     maxHeight: min(image.size.width, width * 0.98) /
                                image.size.width * image.size.height)
              .background(self.settings.consoleGraphicsBackgroundColor)
              .padding(.vertical, 4)
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
          }
          .padding(.horizontal, 4)
        case .error(let context):
          self.errorRow(entry.text, context)
        default:
          Text(entry.text)
            .font(entry.kind == .info ? self.infoFont : self.font)
            .fontWeight(entry.kind == .info ? .bold : .regular)
            .foregroundColor(entry.kind == .result ? .blue :
                              (entry.kind == .output ? .secondary : .primary))
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
      ConsoleEditor(text: $input,
                    selectedRange: $selectedInputRange,
                    calculatedHeight: $dynamicHeight,
                    update: $updateConsole,
                    keyboardObserver: self.keyboardObserver,
                    defineAction: { block in
                      self.showSheet = .showDocumentation(block)
                    })
        .multilineTextAlignment(.leading)
        .frame(minHeight: self.dynamicHeight, maxHeight: self.dynamicHeight)
        .padding(.leading, 3)
        .onAppear {
          if !input.isEmpty {
            self.updateConsole = { textView in
              textView.becomeFirstResponder()
            }
          }
        }
      Button(action: {
        self.inputBuffer = nil
        self.inputHistoryIndex = -1
        self.action()
      }) {
        if !self.ready && self.readingStatus == .accept {
          if self.input.isEmpty {
            Image(systemName: "questionmark.circle.fill")
              .resizable()
              .scaledToFit()
              .frame(height: 24.5)
              .foregroundColor(.init(.sRGB, red: 0.8, green: 0.5, blue: 0.5, opacity: 1.0))
          } else {
            Image(systemName: "arrow.forward.circle.fill")
              .resizable()
              .scaledToFit()
              .frame(height: 24.5)
              .foregroundColor(.red)
          }
        } else if self.input.isEmpty {
          Image(systemName: "pencil.circle.fill")
            .resizable()
            .scaledToFit()
            .frame(height: 24.5)
        } else {
          Image(systemName: "arrow.up.circle.fill")
            .resizable()
            .scaledToFit()
            .frame(height: 24.5)
        }
      }
      .keyCommand("\r", modifiers: .command, title: "Execute command")
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
      .offset(y: -3)
      .gesture(DragGesture().onEnded { _ in
        UIApplication.shared.endEditing(true)
      })
      Button(action: {
        if self.inputHistoryIndex >= 0 &&
           self.inputHistoryIndex < self.history.count &&
           self.history[self.inputHistoryIndex] != self.input {
          self.inputHistoryIndex = -1
          self.inputBuffer = nil
        }
        if self.inputHistoryIndex + 1 < self.history.count {
          if self.inputBuffer == nil {
            self.inputBuffer = self.input
          }
          self.inputHistoryIndex += 1
          self.input = self.history[self.inputHistoryIndex]
        }
      }) {
        EmptyView()
      }
      .keyCommand(UIKeyCommand.inputUpArrow, modifiers: .command, title: "Previous command")
      Button(action: {
        if self.inputHistoryIndex >= 0 &&
           self.inputHistoryIndex < self.history.count &&
           self.history[self.inputHistoryIndex] != self.input {
          self.inputHistoryIndex = -1
          self.inputBuffer = nil
        } else if self.inputHistoryIndex > 0 {
          self.inputHistoryIndex -= 1
          self.input = self.history[self.inputHistoryIndex]
        } else if self.inputHistoryIndex == 0 {
          self.input = self.inputBuffer ?? ""
          self.inputHistoryIndex = -1
          self.inputBuffer = nil
        }
      }) {
        EmptyView()
      }
      .keyCommand(UIKeyCommand.inputDownArrow, modifiers: .command, title: "Next command")
    }
    .background(RoundedRectangle(cornerRadius: 14, style: .continuous)
                  .stroke(Color.gray, lineWidth: 0.7)
                  .background(RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color(.systemBackground))))
    .padding(6)
    .background(Color("NavigationBarColor").ignoresSafeArea())
  }
  
  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      GeometryReader { geo in
        ScrollViewReader { scrollViewProxy in
          ScrollView(.vertical, showsIndicators: true) {
            LazyVStack(alignment: .leading, spacing: 0) {
              ForEach(self.content, id: \.id) { entry in
                self.consoleRow(entry, width: geo.size.width)
              }
            }
            /* .frame(minWidth: 0,               // Looks like we don't need that anymore
                    maxWidth: .infinity,
                    minHeight: 0,
                    maxHeight: .infinity,
                    alignment: .topLeading
            ) */
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
      .resignKeyboardOnDragGesture(enable: UIDevice.current.userInterfaceIdiom != .pad)
      Divider()
      self.control
    }
  }
}
