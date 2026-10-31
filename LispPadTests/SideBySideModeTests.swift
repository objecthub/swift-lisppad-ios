//
//  SideBySideModeTests.swift
//  LispPadTests
//
//  Created by Matthias Zenger on 31/10/2026.
//

import Testing
@testable import LispPad

struct SideBySideModeTests {

  private func showingEditor(_ mode: SideBySideMode) -> SideBySideMode {
    var mode = mode
    mode.showEditor()
    return mode
  }

  @Test("The editor replaces the interpreter if only the interpreter is shown")
  func editorReplacesInterpreter() {
    #expect(self.showingEditor(.leftOnLeft) == .rightOnRight)
    #expect(self.showingEditor(.leftOnRight) == .rightOnLeft)
  }

  @Test("Modes that show the editor stay as they are")
  func editorIsShownAlready() {
    #expect(self.showingEditor(.normal) == .normal)
    #expect(self.showingEditor(.swapped) == .swapped)
    #expect(self.showingEditor(.rightOnRight) == .rightOnRight)
    #expect(self.showingEditor(.rightOnLeft) == .rightOnLeft)
  }

  @Test("The side of the editor is kept")
  func sideIsKept() {
    #expect(!self.showingEditor(.leftOnLeft).isSwapped)
    #expect(self.showingEditor(.leftOnRight).isSwapped)
  }
}
