//
//  KeyCommand.swift
//  LispPad
//  
//  Adds Keyboard Shortcuts to SwiftUI on iOS 13
//  See https://steipete.com/posts/fixing-keyboardshortcut-in-swiftui/
//  Author: Peter Steinberger
//  License: MIT
//
//  Usage: (wrap view in `KeyboardEnabledHostingController`)
//    Button(action: {
//      print("Button Tapped!!")
//    }) {
//      Text("Button")
//    }
//    .keyCommand("e", modifiers: [.control])

import SwiftUI
import Combine

/// Subclass for `UIHostingController` that enables using the `onKeyCommand` extension.
class KeyboardEnabledHostingController<Content>:
        UIHostingController<KeyboardEnabledHostingController.Wrapper> where Content: View {
  private let handler = KeyCommandHandler()

  init(rootView: Content) {
    super.init(rootView: Wrapper(content: rootView, handler: self.handler))
  }

  struct Wrapper: View {
    let content: Content
    fileprivate let handler: KeyCommandHandler

    var body: some View {
      content.environmentObject(self.handler)
    }
  }

  @objc required dynamic init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override var keyCommands: [UIKeyCommand]? {
    if let registrator = self.handler.registrator {
      return registrator.keyCommands + (super.keyCommands ?? [])
    } else {
      return super.keyCommands
    }
  }

  // This method must be inside a responder, else it is hidden
  @objc private func performKeyCommand(_ keyCommand: UIKeyCommand) {
    guard let input = keyCommand.input,
          let registrator = self.handler.registrator else {
      return
    }
    let keyPair = KeyCommandPair(input: input, modifiers: keyCommand.modifierFlags)
    registrator.keyPublisher.send(keyPair)
  }

  override var canBecomeFirstResponder: Bool { true }
}

private struct KeyCommandStyle: PrimitiveButtonStyle {
  var commandPair: KeyCommandPair

  // Purely additive style: https://developer.apple.com/documentation/swiftui/button/init(_:)
  func makeBody(configuration: Configuration) -> some View {
    Button(configuration).keyCommand(keyPair: commandPair, action: configuration.trigger)
  }
}

extension View {
  /// Register a key command for the current button, invoking the button action when triggered.
  func keyCommand(_ key: String,
                  modifiers: UIKeyModifierFlags = .command,
                  title: String = "") -> some View {
    buttonStyle(KeyCommandStyle(commandPair: KeyCommandPair(input: key, modifiers: modifiers)))
  }

  /// Register a key command for the current view
  func onKeyCommand(_ key: String,
                    modifiers: UIKeyModifierFlags = .command,
                    title: String = "",
                    action: @escaping () -> Void) -> some View {
    keyCommand(keyPair: KeyCommandPair(input: key, modifiers: modifiers, title: title),
               action: action)
  }

  fileprivate func keyCommand(keyPair: KeyCommandPair, action: @escaping () -> Void) -> some View {
    self.modifier(KeyCommandModifier(commandPair: keyPair, action: action))
  }
}

private struct KeyCommandModifier: ViewModifier {
  @EnvironmentObject var handler: KeyCommandHandler
  fileprivate var commandPair: KeyCommandPair
  var action: () -> Void

  func body(content: Content) -> some View {
    if let registrator = self.handler.registrator {
      content
        .padding(0) // without a modification, onReceive is not called
        .onReceive(registrator.keyPublisher.filter { $0 == self.commandPair }) { _ in
          action()
        }
        .onAppear {
          registrator.register(commandPair)
        }
    } else {
      // TODO: fix this
      content.keyboardShortcut(KeyEquivalent(self.commandPair.input.first!),
                               modifiers: .command)
    }
  }
}

class KeyCommandHandler: ObservableObject {
  static let empty = KeyCommandHandler(nil)
  
  fileprivate let registrator: KeyCommandRegistrator?
  
  convenience init() {
    self.init(KeyCommandRegistrator())
  }
  
  fileprivate init(_ registrator: KeyCommandRegistrator?) {
    self.registrator = registrator
  }
}

private class KeyCommandRegistrator {
  var keyCommands: [UIKeyCommand] = []
  let keyPublisher = PassthroughSubject<KeyCommandPair, Never>()

  func register(_ commandPair: KeyCommandPair) {
    self.keyCommands += [UIKeyCommand(title: commandPair.title ?? "",
                                      action: NSSelectorFromString("performKeyCommand:"),
                                      input: commandPair.input,
                                      modifierFlags: commandPair.modifiers)]
  }
}

private struct KeyCommandPair: Equatable {
  var input: String
  var modifiers: UIKeyModifierFlags
  var title: String?

  static func == (lhs: KeyCommandPair, rhs: KeyCommandPair) -> Bool {
    return lhs.input == rhs.input && lhs.modifiers == rhs.modifiers
  }
}
