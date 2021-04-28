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
  let font: Font
  let infoFont: Font
  let action: () -> Void
  
  @Binding var content: [ConsoleOutput]
  @Binding var history: [String]
  @Binding var input: String
  @Binding var readingStatus: Interpreter.ReadingStatus
  @Binding var ready: Bool
  
  init(font: Font = .system(size: 12, design: .monospaced),
       infoFont: Font = .system(size: 13, weight: .bold, design: .default),
       action: @escaping () -> Void = {},
       content: Binding<[ConsoleOutput]>,
       history: Binding<[String]>,
       input: Binding<String>,
       readingStatus: Binding<Interpreter.ReadingStatus>,
       ready: Binding<Bool>) {
    self.font = font
    self.infoFont = infoFont
    self.action = action
    self._content = content
    self._history = history
    self._input = input
    self._readingStatus = readingStatus
    self._ready = ready
  }
  
  func consoleRow(_ entry: ConsoleOutput) -> some View {
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
            UIPasteboard.general.setValue(entry.text, forPasteboardType: kUTTypePlainText as String)
          }) {
            Label("Copy to clipboard", systemImage: "doc.on.clipboard")
          }
          if entry.text.count <= 500 {
            Button(action: {
              self.input = entry.text
            }) {
              Label("Copy to input field", systemImage: "dock.arrow.down.rectangle")
            }
          }
        }
    }
  }
  
  var control: some View {
    HStack(alignment: .bottom, spacing: 0) {
      Text(self.input.isEmpty ? " " : self.input)
        .font(self.font)
        .foregroundColor(.clear)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding(EdgeInsets(top: 9, leading: 7, bottom: 9, trailing: 7))
        .overlay(
          TextEditor(text: $input)
            .font(self.font)
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
              .frame(height: 25)
              .foregroundColor(.init(.sRGB, red: 0.8, green: 0.5, blue: 0.5, opacity: 1.0))
          } else {
            Image(systemName: "arrow.forward.circle.fill")
              .resizable()
              .scaledToFit()
              .frame(height: 25)
              .foregroundColor(.red)
          }
        } else if self.input.isEmpty {
          Image(systemName: "pencil.circle.fill")
            .resizable()
            .scaledToFit()
            .frame(height: 25)
        } else {
          Image(systemName: "arrow.up.circle.fill")
            .resizable()
            .scaledToFit()
            .frame(height: 25)
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
      ScrollViewReader { scrollViewProxy in
        ConsoleScrollView(.vertical, offsetChanged: { coord in 
          // Swift.print("coord = \(coord)")
        }) {
          LazyVStack(alignment: .leading, spacing: 0) {
            ForEach(self.content, id: \.id) { entry in
              self.consoleRow(entry)
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
      // Divider()
      Spacer(minLength: 6)
      self.control
    }
  }
}
