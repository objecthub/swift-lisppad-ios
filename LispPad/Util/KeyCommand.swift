//
//  KeyCommand.swift
//  LispPad
//  
//  Adds Keyboard Shortcuts to SwiftUI on iOS 13 if the UI is driven by a UIHostingController
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

/// Subclass for `UIHostingController` that enables using the `keyCommand` and
/// `onKeyCommand` view modifiers.
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

  override var canBecomeFirstResponder: Bool {
    return true
  }
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
                  title: String? = nil) -> some View {
    // Map event modifiers to the corresponding data type used by SwiftUI
    var eventModifiers: EventModifiers = []
    if modifiers.contains(.command) {
      eventModifiers.insert(.command)
    }
    if modifiers.contains(.shift) {
      eventModifiers.insert(.shift)
    }
    if modifiers.contains(.alternate) {
      eventModifiers.insert(.option)
    }
    if modifiers.contains(.control) {
      eventModifiers.insert(.control)
    }
    // Map keys to the corresponding data type used by SwiftUI
    let keyEquiv: KeyEquivalent
    switch key {
      case UIKeyCommand.inputUpArrow:
        keyEquiv = .upArrow
      case UIKeyCommand.inputDownArrow:
        keyEquiv = .downArrow
      case UIKeyCommand.inputRightArrow:
        keyEquiv = .rightArrow
      case UIKeyCommand.inputLeftArrow:
        keyEquiv = .leftArrow
      case UIKeyCommand.inputEscape:
        keyEquiv = .escape
      default:
        keyEquiv = KeyEquivalent(key.first!)
    }
    return self.buttonStyle(
                  KeyCommandStyle(commandPair: KeyCommandPair(input: key,
                                                              modifiers: modifiers,
                                                              title: title)))
               .keyboardShortcut(keyEquiv, modifiers: eventModifiers)
  }

  /// Register a key command for the current view
  func onKeyCommand(_ key: String,
                    modifiers: UIKeyModifierFlags = .command,
                    title: String? = nil,
                    action: @escaping () -> Void) -> some View {
    return keyCommand(keyPair: KeyCommandPair(input: key, modifiers: modifiers, title: title),
                      action: action)
  }

  fileprivate func keyCommand(keyPair: KeyCommandPair, action: @escaping () -> Void) -> some View {
    return self.modifier(KeyCommandModifier(commandPair: keyPair, action: action))
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
      content
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
