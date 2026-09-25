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
import UniformTypeIdentifiers

struct ConsoleView: View {
  static let logButtonColor = Color(UIColor(named: "LogSwitchColor") ??
                                      UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0))
  static let resultColor = Color(UIColor(named: "ResultColor") ??
                                   UIColor(red: 0.0, green: 0.1, blue: 0.7, alpha: 1.0))
  
  @EnvironmentObject var globals: LispPadGlobals
  @EnvironmentObject var docManager: DocumentationManager
  @EnvironmentObject var interpreter: Interpreter
  @EnvironmentObject var settings: UserSettings
  @State var dynamicHeight: CGFloat = 100
  @State var buttonDiameter: CGFloat? = nil
  @State var executeMenuPresented: Bool = false
  @State var inputBuffer: String? = nil
  @State var inputHistoryIndex: Int = -1
  @State var minSeverityFilter = Severity.debug
  @State var logMessageFilter = ""
  @State var filterMessage = true
  @State var filterTag = true
  @State var redraw = false
  @StateObject var keyboardObserver = KeyboardObserver()
  
  let font: Font
  let action: () -> Void
  
  @Binding var splitViewMode: SideBySideMode
  @ObservedObject var console: Console
  @Binding var contentBatch: Int
  @Binding var history: [String]
  @ObservedObject var state: InterpreterState
  @Binding var readingStatus: Interpreter.ReadingStatus
  @Binding var ready: Bool
  @Binding var showSheet: InterpreterView.SheetAction?
  @Binding var showModal: InterpreterView.SheetAction?
  @Binding var showCard: Bool
  @ObservedObject var cardContent: MutableBlock
  @Binding var updateConsole: ((CodeEditorTextView) -> Void)?
  @Binding var updateEditor: ((CodeEditorTextView) -> Void)?
  
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
      Button {
        UIPasteboard.general.string = text
      } label: {
        Label("Copy Error", systemImage: "doc.on.clipboard")
      }
      Divider()
      ShareLink("Share Error…", item: text)
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
        case .empty:
          Divider().frame(width: 10, height: 1)
        case .drawingResult(let drawing, let image):
          VStack(alignment: .leading, spacing: 2) {
            Text(entry.text)
              .font(self.font)
              .fontWeight(.regular)
              .foregroundColor(ConsoleView.resultColor)
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
                Button {
                  UIPasteboard.general.image = image
                } label: {
                  Label("Copy Image", systemImage: "doc.on.clipboard")
                }
                Divider()
                Button {
                  self.state.showProgressView = "Saving Image…"
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
                    DispatchQueue.main.async {
                      self.state.showProgressView = nil
                    }
                  }
                } label: {
                  Label("Save Image", systemImage: "square.and.arrow.down")
                }
                Button {
                  self.state.showProgressView = "Printing Image…"
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
                      self.state.showProgressView = nil
                      let printController = UIPrintInteractionController.shared
                      printController.printInfo = printInfo
                      printController.printingItem = res
                      printController.present(animated: true) { _, isPrinted, error in }
                    }
                  }
                } label: {
                  Label("Print Image", systemImage: "printer")
                }
                Button {
                  self.state.showProgressView = "Sharing Image…"
                  DispatchQueue.global(qos: .userInitiated).async {
                    if let betterImage = iconImage(for: drawing,
                                                   width: 1500,
                                                   height: 1500,
                                                   scale: 4.0,
                                                   renderingWidth: 1500,
                                                   renderingHeight: 1500) {
                      self.presentSheet(.shareImage(betterImage))
                    } else {
                      self.presentSheet(.shareImage(image))
                    }
                    DispatchQueue.main.async {
                      self.state.showProgressView = nil
                    }
                  }
                } label: {
                  Label("Share Image…", systemImage: "square.and.arrow.up")
                }
              }
          }
          .padding(.horizontal, 4)
        case .error(let context):
          self.errorRow(entry.text, context)
        default:
          Text(entry.text)
            .font(self.font)
            .fontWeight(entry.kind == .info ? .bold : .regular)
            .foregroundColor(entry.kind == .result ? ConsoleView.resultColor :
                              (entry.kind == .output ? .secondary : .primary))
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 4)
            .padding(.vertical, entry.kind == .command ? 4 : (entry.kind == .output ? 1 : 0))
            .contextMenu {
              Button(action: {
                UIPasteboard.general.setValue(entry.text,
                                              forPasteboardType: UTType.utf8PlainText.identifier)
              }) {
                Label("Copy Text", systemImage: "doc.on.clipboard")
              }
              if entry.text.count <= 800 {
                Button(action: {
                  self.state.consoleInput = entry.text
                  self.state.consoleInputRange = NSRange(location: (entry.text as NSString).length,
                                                         length: 0)
                }) {
                  Label("Copy to Input", systemImage: "dock.arrow.down.rectangle")
                }
              }
              Divider()
              ShareLink("Share Text…", item: entry.text)
            }
      }
    }
  }
  
  var control: some View {
    Group {
      if #available(iOS 26.0, *) {
        GlassEffectContainer(spacing: 8) {
          self.controlContent
        }
      } else {
        self.controlContent
      }
    }
    .padding(6)
  }

  private var controlContent: some View {
    HStack(alignment: .bottom, spacing: 8) {
      ConsoleEditor(text: self.$state.consoleInput,
                    selectedRange: self.$state.consoleInputRange,
                    focused: self.$state.focused,
                    calculatedHeight: self.$dynamicHeight,
                    update: self.$updateConsole,
                    keyboardObserver: self.keyboardObserver,
                    // While the submit button's long-press menu is open, its bottom-most
                    // item sits right above this field. Without this, a tap there can be
                    // stolen by the console text view (which grabs touches to place the
                    // cursor/become first responder) instead of registering as a menu
                    // selection.
                    allowsHitTesting: !self.executeMenuPresented,
                    defineAction: { block in
                      self.showCard = true
                      self.cardContent.block = block
                    },
                    returnAction: {
                      guard !self.state.consoleInput.isEmpty, self.ready ||
                              self.readingStatus == .accept else {
                        return
                      }
                      self.inputBuffer = nil
                      self.inputHistoryIndex = -1
                      self.action()
                    },
                    customReturn: {
                      return self.settings.consoleExecOnReturn
                    })
        .multilineTextAlignment(.leading)
        .frame(minHeight: self.dynamicHeight, maxHeight: self.dynamicHeight)
        .onAppear {
          // THIS IS A HUGE HACK (to work around a SwiftUI navigation bug)
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let shouldFocus = self.state.shouldFocus
            self.state.shouldFocus = false
            if !self.state.focused && shouldFocus {
              self.updateConsole = { textView in
                textView.becomeFirstResponder()
              }
            }
          }
        }
        .modifier(ConsoleInputBarChrome())
        .onChange(of: self.dynamicHeight) { oldValue, newValue in
          // Captured once, from the field's first genuine (single-line) layout pass, and
          // never touched again, so the button's size stays fixed even as the field grows
          // for multi-line input. The very first reported height can transiently be 0
          // before layout settles, so that spurious value is ignored.
          if self.buttonDiameter == nil && newValue > 1 {
            self.buttonDiameter = newValue
          }
        }
      // A plain Menu's presentation lifecycle (onAppear/onDisappear on its content) is not
      // reliably reported on iOS 26, which made `executeMenuPresented` -- and therefore the
      // console field's `allowsHitTesting` -- flicker or stick. Driving a `.popover` off an
      // explicit @State we set/clear ourselves (on long-press, on each row's own action, and
      // implicitly on outside-tap dismissal via the isPresented binding) is fully
      // deterministic instead.
      Image(systemName: self.executeButtonIcon)
        .font(.system(size: 18, weight: .semibold))
        .foregroundStyle(.white)
        .blendMode(.overlay)
        .frame(width: self.buttonDiameter ?? 44, height: self.buttonDiameter ?? 44)
        .modifier(ConsoleButtonChrome(tint: self.executeButtonTint))
        .contentShape(Circle())
        .onTapGesture {
          guard !self.state.consoleInput.isEmpty, self.ready || self.readingStatus == .accept else {
            return
          }
          self.inputBuffer = nil
          self.inputHistoryIndex = -1
          self.action()
        }
        .onLongPressGesture(minimumDuration: 0.3) {
          self.executeMenuPresented = true
        }
        .popover(isPresented: self.$executeMenuPresented) {
          self.executeMenuContents
            .presentationCompactAdaptation(.popover)
        }
    }
  }

  // Content of the submit button's long-press popover: recent command history followed
  // by a destructive "Clear Input" row, matching the layout the system Menu used to
  // produce. Each row clears `executeMenuPresented` itself after acting.
  private var executeMenuContents: some View {
    VStack(alignment: .leading, spacing: 0) {
      if self.ready && self.history.count > 0 {
        Text("COMMAND HISTORY")
          .font(.caption)
          .foregroundColor(.secondary)
          .padding(.horizontal, 24)
          .padding(.top, 12)
          .padding(.bottom, 6)
        Divider()
        ScrollView {
          LazyVStack(alignment: .leading, spacing: 0) {
            ForEach(Array(self.history.enumerated()), id: \.offset) { index, entry in
              Button {
                self.state.consoleInput = entry
                self.state.consoleInputRange = NSRange(location: (entry as NSString).length,
                                                       length: 0)
                self.executeMenuPresented = false
              } label: {
                Text(entry)
                  .font(.system(.footnote, design: .monospaced))
                  .lineLimit(2)
                  .frame(maxWidth: .infinity, alignment: .leading)
                  .padding(.horizontal, 12)
                  .padding(.vertical, 6)
                  .contentShape(Rectangle())
              }
              .buttonStyle(.plain)
              if index < self.history.count - 1 {
                Divider()
                  .foregroundStyle(Color.primary.opacity(0.1))
                  .padding(.leading, 8)
              }
            }
          }
        }
        .frame(maxWidth: 320, maxHeight: 320)
        Divider()
          .padding(.vertical, 4)
      }
      Button(role: .destructive) {
        self.state.consoleInput = ""
        self.executeMenuPresented = false
      } label: {
        HStack {
          Text("CLEAR INPUT")
            .font(.caption)
          Spacer()
          Image(systemName: "xmark")
            .font(.caption)
        }
      }
      .padding(.horizontal, 24)
      .padding(.top, 6)
      .padding(.bottom, 12)
    }
    .frame(width: 280)
  }

  // Which icon the execute button shows, based on interpreter/reading state.
  private var executeButtonIcon: String {
    if !self.ready && self.readingStatus == .accept {
      return self.state.consoleInput.isEmpty ? "questionmark" : "arrow.forward"
    } else if self.state.consoleInput.isEmpty {
      return "pencil"
    } else {
      return "arrow.up"
    }
  }

  // The execute button's tint, matching the same state distinctions the icon used to convey
  // via color alone (red for input requests, muted while there is nothing to submit).
  private var executeButtonTint: Color {
    if !self.ready && self.readingStatus == .accept {
      return .red
    } else if self.state.consoleInput.isEmpty {
      return Color(.systemGray3)
    } else {
      return .accentColor
    }
  }

  // Styles the console input field. On iOS 26+ it gets a Liquid Glass rounded rectangle,
  // matching the look of a system search field; on earlier versions it falls back to a
  // plain rounded box.
  private struct ConsoleInputBarChrome: ViewModifier {
    func body(content: Content) -> some View {
      if #available(iOS 26.0, *) {
        content
          .padding(.horizontal, 6)
          .glassEffect(.regular.interactive(),
                       in: RoundedRectangle(cornerRadius: 14, style: .continuous))
          .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
              .strokeBorder(Color.primary.opacity(0.6), lineWidth: 0.75)
          )
      } else {
        content
          .background(RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.gray, lineWidth: 0.7)
                        .background(RoundedRectangle(cornerRadius: 14, style: .continuous)
                                      .fill(Color(.systemBackground))))
      }
    }
  }

  // Styles the submit/menu button as a standalone, fully tinted Liquid Glass button on
  // iOS 26+, matching other round system glass buttons; falls back to a plain filled
  // circular button.
  private struct ConsoleButtonChrome: ViewModifier {
    let tint: Color

    func body(content: Content) -> some View {
      if #available(iOS 26.0, *) {
        content
          .glassEffect(.regular.tint(self.tint).interactive(), in: Circle())
      } else {
        content
          .background(Circle().fill(self.tint))
      }
    }
  }

  // Invisible buttons that only exist to register keyboard shortcuts. They have no
  // visual presence, so they don't need to live inside the bottom bar.
  var keyCommandButtons: some View {
    Group {
      ZStack {
        if !self.splitViewMode.isSideBySide || self.state.focused {
          Button(action: {
            guard !self.state.consoleInput.isEmpty,
                  self.ready || self.readingStatus == .accept else {
              return
            }
            self.inputBuffer = nil
            self.inputHistoryIndex = -1
            self.action()
          }) {
            EmptyView()
          }
          .keyCommand("\r", modifiers: .command, title: "Execute command")
        }
        Button(action: {
          guard !self.state.consoleInput.isEmpty, self.ready || self.readingStatus == .accept else {
            return
          }
          self.inputBuffer = nil
          self.inputHistoryIndex = -1
          self.action()
        }) {
          EmptyView()
        }
        .keyCommand("\r", modifiers: [.command, .alternate], title: "Execute command")
        Button(action: {
          if self.inputHistoryIndex >= 0 &&
              self.inputHistoryIndex < self.history.count &&
              self.history[self.inputHistoryIndex] != self.state.consoleInput {
            self.inputHistoryIndex = -1
            self.inputBuffer = nil
          }
          if self.inputHistoryIndex + 1 < self.history.count {
            if self.inputBuffer == nil {
              self.inputBuffer = self.state.consoleInput
            }
            self.inputHistoryIndex += 1
            let input = self.history[self.inputHistoryIndex]
            self.state.consoleInput = input
            self.state.consoleInputRange = NSRange(location: (input as NSString).length, length: 0)
          }
        }) {
          EmptyView()
        }
        .keyCommand(UIKeyCommand.inputUpArrow, modifiers: [.command, .alternate], title: "Previous command")
        Button(action: {
          if self.inputHistoryIndex >= 0 &&
              self.inputHistoryIndex < self.history.count &&
              self.history[self.inputHistoryIndex] != self.state.consoleInput {
            self.inputHistoryIndex = -1
            self.inputBuffer = nil
          } else if self.inputHistoryIndex > 0 {
            self.inputHistoryIndex -= 1
            let input = self.history[self.inputHistoryIndex]
            self.state.consoleInput = input
            self.state.consoleInputRange = NSRange(location: (input as NSString).length, length: 0)
          } else if self.inputHistoryIndex == 0 {
            self.state.consoleInput = self.inputBuffer ?? ""
            self.state.consoleInputRange =
            NSRange(location: (self.state.consoleInput as NSString).length, length: 0)
            self.inputHistoryIndex = -1
            self.inputBuffer = nil
          }
        }) {
          EmptyView()
        }
        .keyCommand(UIKeyCommand.inputDownArrow, modifiers: [.command, .alternate], title: "Next command")
        Button(action: {
          if self.state.consoleTab > 0 {
            self.state.consoleTab = (self.state.consoleTab + 2) % 3
          }
        }) {
          EmptyView()
        }
        .keyCommand(UIKeyCommand.inputLeftArrow, modifiers: [.command, .alternate], title: "Previous view")
        Button(action: {
          if self.state.consoleTab < 2 {
            self.state.consoleTab = (self.state.consoleTab + 1) % 3
          }
        }) {
          EmptyView()
        }
        .keyCommand(UIKeyCommand.inputRightArrow, modifiers: [.command, .alternate], title: "Next view")
        Button(action: { self.state.consoleTab = 0 }) {
          EmptyView()
        }
        .keyCommand("l", modifiers: [.command, .alternate], title: "Show log")
        Button(action: { self.state.consoleTab = 1 }) {
          EmptyView()
        }
        .keyCommand("i", modifiers: [.command, .alternate], title: "Show interpreter")
        Button(action: { self.state.consoleTab = 2 }) {
          EmptyView()
        }
        .keyCommand("c", modifiers: [.command, .alternate], title: "Show canvas")
      }
      ZStack {
        if self.state.focused {
          Button(action: self.selectExpression) {
            EmptyView()
          }
          .keyCommand("e", modifiers: .command, title: "Select expression")
        }
        if self.state.focused {
          Button(action: self.defineIdentifier) {
            EmptyView()
          }
          .keyCommand("d", modifiers: .command, title: "Define identifier")
        }
        Button(action: self.switchAcross) {
          EmptyView()
        }
        .keyCommand("s", modifiers: .command, title: "Switch to editor")
      }
    }
    .frame(width: 0, height: 0)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      TabView(selection: self.$state.consoleTab) {
        LogView(font: self.font,
                input: self.$state.consoleInput,
                showSheet: self.$showSheet,
                showModal: self.$showModal)
        .tag(0)
        GeometryReader { geo in
          ZStack(alignment: .bottomTrailing) {
            ScrollView(.vertical, showsIndicators: true) {
              ScrollViewReader { scrollViewProxy in
                LazyVStack(alignment: .leading, spacing: 0) {
                  ForEach(self.console.content, id: \.id) { entry in
                    self.consoleRow(entry, width: geo.size.width)
                  }
                }
                .onChange(of: self.console.content) { oldValue, newValue in
                  if let id = self.console.lastOutputId {
                    withAnimation {
                      scrollViewProxy.scrollTo(id, anchor: .bottomTrailing)
                    }
                  }
                }
                .onChange(of: self.contentBatch) { oldValue, newValue in
                  if let id = self.console.lastOutputId {
                    withAnimation {
                      scrollViewProxy.scrollTo(id, anchor: .bottomTrailing)
                    }
                  }
                }
                .onChange(of: self.state.consoleInput) { oldValue, newValue in
                  if let id = self.console.lastOutputId {
                    withAnimation {
                      scrollViewProxy.scrollTo(id, anchor: .bottomTrailing)
                    }
                  }
                }
              }
            }
            .scrollDismissesKeyboard(.interactively)
          }
        }
        .tag(1)
        CanvasPanel(state: self.state, showModal: self.$showModal)
        .tag(2)
      }
      .tabViewStyle(.page(indexDisplayMode: .never))
      .indexViewStyle(.page(backgroundDisplayMode: .interactive))
      .slideOverCard(isPresented: self.$showCard, onDismiss: {
        self.cardContent.block = nil
       }) {
        OptionalScrollView {
          MutableMarkdownText(self.cardContent, rightPadding: 26)
            .modifier(self.globals.services)
            .padding(.horizontal, 10)
            .padding(.top, 10)
            .padding(.bottom, -10)
        }
      }
      //.resignKeyboardOnDragGesture(enable: UIDevice.current.userInterfaceIdiom != .pad)
      self.keyCommandButtons
    }
    .safeAreaInset(edge: .bottom, spacing: 0) {
      self.control
    }
  }
  
  private func selectExpression() {
    if let range = TextFormatter.selectEnclosingExpr(string: self.state.consoleInput as NSString,
                                                     selectedRange: self.state.consoleInputRange,
                                                     smart: true) {
      self.state.consoleInputRange = range
    }
  }
  
  private func defineIdentifier() {
    if let name = TextFormatter.selectedName(in: self.state.consoleInput,
                                             for: self.state.consoleInputRange),
       let documentation = self.docManager.documentation(for: name) {
      self.showCard = true
      self.cardContent.block = documentation
    }
  }
  
  private func switchAcross() {
    if self.splitViewMode.isSideBySide {
      if self.state.focused {
        self.updateEditor = { textView in
          textView.becomeFirstResponder()
        }
      } else {
        self.updateConsole = { textView in
          textView.becomeFirstResponder()
        }
      }
    } else {
      self.splitViewMode.toggle()
    }
  }
  
  private func presentSheet(_ action: InterpreterView.SheetAction) {
    // if UIDevice.current.userInterfaceIdiom == .pad {
      self.showModal = action
    // } else {
    //  self.showSheet = action
    // }
  }
}
