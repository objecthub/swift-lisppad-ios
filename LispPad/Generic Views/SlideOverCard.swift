//
//  SlideOverCard.swift
//  LispPad
//  
//  Heavily modified version of João Gabriel Pozzobon's SlideOverCard package.
//  
//  Created by João Gabriel Pozzobon dos Santos on 30/10/20.
//  Copyright (c) 2020 João Gabriel Pozzobon dos Santos
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of
//  this software and associated documentation files (the "Software"), to deal in
//  the Software without restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the
//  Software, and to permit persons to whom the Software is furnished to do so,
//  subject to the following conditions:
//  
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//  
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
//  DEALINGS IN THE SOFTWARE.
// 

import SwiftUI

public struct SlideOverCard<Content: View>: View {
  var isPresented: Binding<Bool>
  let onDismiss: (() -> Void)?
  let content: Content
  
  @GestureState private var viewOffset: CGFloat = 0.0
  
  public init(isPresented: Binding<Bool>,
              onDismiss: (() -> Void)? = nil,
              content: @escaping () -> Content) {
    self.isPresented = isPresented
    self.onDismiss = onDismiss
    self.content = content()
  }
  
  public var body: some View {
    ZStack {
      if self.isPresented.wrappedValue {
        Color.black
          .opacity(0.4)
          .ignoresSafeArea()
          .transition(.opacity)
          .zIndex(1)
        VStack {
          Spacer()
          card
            .padding(.horizontal, 8)
            .padding(.top, 40)
            .padding(.bottom, 8)
            .ignoresSafeArea(.container, edges: [])
        }
        .transition(.move(edge: .bottom))
        .zIndex(2)
      }
    }
    .animation(.spring(response: 0.35, dampingFraction: 1), value: self.isPresented.wrappedValue)
  }
  
  private var card: some View {
    ZStack(alignment: Alignment(horizontal: .trailing, vertical: .top)) {
      content
      Button(action: self.dismiss) {
        ExitButton(size: 24)
      }
      .keyboardShortcut(KeyEquivalent.escape, modifiers: [])
      // .keyCommand(UIKeyCommand.inputEscape, modifiers: [], title: "Close card")
      .padding(.trailing, 7)
      .padding(.top, 8)
    }
    .background(Color(.systemBackground))
    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    .background(RoundedRectangle(cornerRadius: 16, style: .continuous)
                  .stroke(Color(.gray), lineWidth: 1.5))
    .offset(x: 0, y: viewOffset/pow(2, abs(viewOffset) / 500 + 1))
    .gesture(
      DragGesture()
        .updating($viewOffset) { value, state, transaction in
          state = value.translation.height
        }
        .onEnded() { value in
          if value.predictedEndTranslation.height > 175 {
            self.dismiss()
          }
        }
    )
  }
  
  func dismiss() {
    self.isPresented.wrappedValue = false
    if let onDismiss = self.onDismiss {
      onDismiss()
    }
  }
  
  public static func present(isPresented: Binding<Bool>,
                             onDismiss: (() -> Void)? = nil,
                             style: UIUserInterfaceStyle = .unspecified,
                             @ViewBuilder content: @escaping () -> Content) {
    let rootCard = SlideOverCard(isPresented: isPresented,
                                 onDismiss: { SlideOverCard.dismiss(isPresented: isPresented) },
                                 content: content)
    let controller = UIHostingController(rootView: rootCard)
    controller.view.backgroundColor = .clear
    controller.modalPresentationStyle = .overFullScreen
    controller.overrideUserInterfaceStyle = style
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
      UIApplication.shared.currentUIWindow()?.rootViewController?.present(controller, animated: false)
      isPresented.wrappedValue = true
    }
  }
  
  public static func dismiss(isPresented: Binding<Bool>) {
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
      isPresented.wrappedValue = false
      UIApplication.shared.currentUIWindow()?.rootViewController?.dismiss(animated: false)
    }
  }
}

extension View {
  public func slideOverCard<Content: View>
                           (isPresented: Binding<Bool>,
                            onDismiss: (() -> Void)? = nil,
                            @ViewBuilder content: @escaping () -> Content) -> some View {
    return ZStack {
      self
      SlideOverCard(isPresented: isPresented, onDismiss: onDismiss) {
        content()
      }
    }
  }
  
  public func slideOverCard<Item: Identifiable, Content: View>
                           (item: Binding<Item?>,
                            onDismiss: (() -> Void)? = nil,
                            @ViewBuilder content: @escaping (Item) -> Content) -> some View {
    let binding = Binding(get: { item.wrappedValue != nil },
                          set: { if !$0 { item.wrappedValue = nil } })
    return self.slideOverCard(isPresented: binding,
                              onDismiss: onDismiss,
                              content: {
                                if let item = item.wrappedValue {
                                  content(item)
                                }
                              })
  }
}
