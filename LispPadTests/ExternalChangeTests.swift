//
//  ExternalChangeTests.swift
//  LispPadTests
//
//  Created by Matthias Zenger on 31/10/2026.
//

import Testing
import UIKit
@testable import LispPad

@MainActor
struct ExternalChangeTests {

  /// Opens a document for a new temporary file ("(display 1)\n"), steps aside as file
  /// presenter like the app does in the background, and returns both.
  static func openedDocument() async throws -> (document: TextDocument, url: URL) {
    let url = try TextDocumentPresenterTests.temporaryFile()
    let document = TextDocument(fileURL: url)
    #expect(await TextDocumentPresenterTests.open(document))
    document.suspendFilePresenter()
    return (document, url)
  }

  static func fingerprint(_ text: String) -> TextDocument.Fingerprint {
    return TextDocument.fingerprint(of: text)
  }

  static func reload(_ document: TextDocument) async {
    await withCheckedContinuation { continuation in
      document.reloadIfChangedOnDisk { continuation.resume() }
    }
  }

  static func save(_ document: TextDocument) async {
    await withCheckedContinuation { continuation in
      document.saveFile { _ in continuation.resume() }
    }
  }

  static func resolve(_ document: TextDocument, keepLocal: Bool) async {
    await withCheckedContinuation { continuation in
      document.resolveConflict(keepLocal: keepLocal) { continuation.resume() }
    }
  }

  /// Replaces the file the way another app does: with file coordination, from another thread.
  static func writeExternally(_ text: String, to url: URL) async {
    await withCheckedContinuation { continuation in
      DispatchQueue.global().async {
        var error: NSError?
        NSFileCoordinator(filePresenter: nil).coordinate(writingItemAt: url,
                                                         options: .forReplacing,
                                                         error: &error) { target in
          try? Data(text.utf8).write(to: target)
        }
        continuation.resume()
      }
    }
  }

  static func content(of url: URL) throws -> String {
    return try String(contentsOf: url, encoding: .utf8)
  }

  static func finish(_ document: TextDocument, _ url: URL) async {
    await TextDocumentPresenterTests.close(document)
    try? Foundation.FileManager.default.removeItem(at: url)
  }

  @Test func decisionDependsOnWhatChanged() {
    let saved = Self.fingerprint("(display 1)")
    let edited = Self.fingerprint("(display 1) ; mine")
    let other = Self.fingerprint("(display 2)")
    // The file is as before: edits stay unsaved
    #expect(TextDocument.resolve(local: saved, saved: saved, disk: saved) == .ignore)
    #expect(TextDocument.resolve(local: edited, saved: saved, disk: saved) == .ignore)
    // The file changed and there is nothing to lose
    #expect(TextDocument.resolve(local: saved, saved: saved, disk: other) == .adopt)
    // The file changed into what the document has anyway
    #expect(TextDocument.resolve(local: edited, saved: saved, disk: edited) == .adopt)
    // The file changed and so did the document
    #expect(TextDocument.resolve(local: edited, saved: saved, disk: other) == .conflict)
  }

  @Test func fingerprintsTellTextsApart() {
    #expect(Self.fingerprint("(display 1)") == Self.fingerprint("(display 1)"))
    #expect(Self.fingerprint("(display 1)") != Self.fingerprint("(display 2)"))
    #expect(Self.fingerprint("") != Self.fingerprint(" "))
    // Texts that are equal but not stored the same way are equal for the fingerprint
    let bridged = NSString(string: "(display ä)") as String
    #expect(Self.fingerprint(bridged) == Self.fingerprint("(display ä)"))
  }

  @Test func documentKeepsNoCopyOfTheSavedText() async throws {
    let (document, url) = try await Self.openedDocument()
    #expect(document.savedFingerprint == Self.fingerprint("(display 1)\n"))
    var edited = document.text
    edited.append("; mine\n")
    document.text = edited
    // Only the text itself changes; the baseline is a fixed-size fingerprint
    #expect(document.savedFingerprint == Self.fingerprint("(display 1)\n"))
    #expect(MemoryLayout<TextDocument.Fingerprint>.size == 32)
    await Self.finish(document, url)
  }

  @Test func unchangedFileLeavesDocumentAlone() async throws {
    let (document, url) = try await Self.openedDocument()
    await Self.reload(document)
    #expect(document.text == "(display 1)\n")
    #expect(document.savedFingerprint == Self.fingerprint("(display 1)\n"))
    #expect(!document.hasConflict)
    await Self.finish(document, url)
  }

  @Test func changedFileIsTakenOver() async throws {
    let (document, url) = try await Self.openedDocument()
    document.selectedRange = NSRange(location: 8, length: 0)
    try Data("(display 22222)\n".utf8).write(to: url)
    await Self.reload(document)
    #expect(document.text == "(display 22222)\n")
    #expect(document.savedFingerprint == Self.fingerprint("(display 22222)\n"))
    #expect(!document.hasConflict)
    #expect(document.selectedRange == NSRange(location: 8, length: 0))
    await Self.finish(document, url)
  }

  @Test func selectionStaysInsideAShorterText() async throws {
    let (document, url) = try await Self.openedDocument()
    document.selectedRange = NSRange(location: 10, length: 1)
    try Data("(a)".utf8).write(to: url)
    await Self.reload(document)
    #expect(document.text == "(a)")
    #expect(document.selectedRange == NSRange(location: 3, length: 0))
    await Self.finish(document, url)
  }

  @Test func presenterReturningFromBackgroundReloadsTheFile() async throws {
    let (document, url) = try await Self.openedDocument()
    try Data("(display 3)\n".utf8).write(to: url)
    document.resumeFilePresenter()
    let taken = try await SchemePreviewSettingsTests.eventually {
      document.text == "(display 3)\n"
    }
    #expect(taken)
    await Self.finish(document, url)
  }

  @Test func changesWhileInTheForegroundAreTakenOver() async throws {
    let url = try TextDocumentPresenterTests.temporaryFile()
    let document = TextDocument(fileURL: url)
    #expect(await TextDocumentPresenterTests.open(document))
    await Self.writeExternally("(display 8)\n", to: url)
    let taken = try await SchemePreviewSettingsTests.eventually {
      document.text == "(display 8)\n"
    }
    #expect(taken)
    await Self.finish(document, url)
  }

  @Test func changesInTheForegroundAreTakenOverAfterABackgroundStay() async throws {
    let (document, url) = try await Self.openedDocument()
    document.resumeFilePresenter()
    await Self.reload(document)
    await Self.writeExternally("(display 9)\n", to: url)
    let taken = try await SchemePreviewSettingsTests.eventually {
      document.text == "(display 9)\n"
    }
    #expect(taken)
    await Self.finish(document, url)
  }

  @Test func reloadsRequestedTogetherAllComplete() async throws {
    let (document, url) = try await Self.openedDocument()
    try Data("(display 7)\n".utf8).write(to: url)
    var completed = 0
    await withCheckedContinuation { continuation in
      for _ in 0..<3 {
        document.reloadIfChangedOnDisk {
          completed += 1
          if completed == 3 {
            continuation.resume()
          }
        }
      }
    }
    #expect(document.text == "(display 7)\n")
    await Self.finish(document, url)
  }

  @Test func unsavedEditsSurviveAnUnchangedFile() async throws {
    let (document, url) = try await Self.openedDocument()
    document.text = "(display 1) ; mine\n"
    await Self.reload(document)
    #expect(document.text == "(display 1) ; mine\n")
    #expect(document.savedFingerprint == Self.fingerprint("(display 1)\n"))
    #expect(!document.hasConflict)
    await Self.finish(document, url)
  }

  @Test func unsavedEditsAndChangedFileAreAConflict() async throws {
    let (document, url) = try await Self.openedDocument()
    document.text = "(display 1) ; mine\n"
    try Data("(display 4)\n".utf8).write(to: url)
    await Self.reload(document)
    #expect(document.text == "(display 1) ; mine\n")
    #expect(document.savedFingerprint == Self.fingerprint("(display 1)\n"))
    #expect(document.hasConflict)
    #expect(document.conflictFingerprint == Self.fingerprint("(display 4)\n"))
    await Self.finish(document, url)
  }

  @Test func keepingMineOverwritesTheFileOnTheNextSave() async throws {
    let (document, url) = try await Self.openedDocument()
    document.text = "(display 1) ; mine\n"
    try Data("(display 4)\n".utf8).write(to: url)
    await Self.reload(document)
    await Self.resolve(document, keepLocal: true)
    #expect(!document.hasConflict)
    #expect(document.text == "(display 1) ; mine\n")
    #expect(try Self.content(of: url) == "(display 4)\n")
    // The file counts as seen: looking at it again does not ask again
    await Self.reload(document)
    #expect(!document.hasConflict)
    await Self.save(document)
    #expect(try Self.content(of: url) == "(display 1) ; mine\n")
    await Self.finish(document, url)
  }

  @Test func reloadingDiscardsTheUnsavedEdits() async throws {
    let (document, url) = try await Self.openedDocument()
    document.text = "(display 1) ; mine\n"
    try Data("(display 4)\n".utf8).write(to: url)
    await Self.reload(document)
    await Self.resolve(document, keepLocal: false)
    #expect(!document.hasConflict)
    #expect(document.text == "(display 4)\n")
    #expect(document.savedFingerprint == Self.fingerprint("(display 4)\n"))
    await Self.finish(document, url)
  }

  @Test func reloadingTakesTheNewestVersionOfTheFile() async throws {
    let (document, url) = try await Self.openedDocument()
    document.text = "(display 1) ; mine\n"
    try Data("(display 4)\n".utf8).write(to: url)
    await Self.reload(document)
    #expect(document.conflictFingerprint == Self.fingerprint("(display 4)\n"))
    // The file changes again while the user is still deciding
    try Data("(display 5)\n".utf8).write(to: url)
    await Self.resolve(document, keepLocal: false)
    #expect(document.text == "(display 5)\n")
    #expect(!document.hasConflict)
    await Self.finish(document, url)
  }

  @Test func fileThatIsNotUTF8IsIgnored() async throws {
    let (document, url) = try await Self.openedDocument()
    try Data([0x28, 0xC3, 0x28, 0x29]).write(to: url)
    await Self.reload(document)
    #expect(document.text == "(display 1)\n")
    #expect(document.savedFingerprint == Self.fingerprint("(display 1)\n"))
    #expect(!document.hasConflict)
    await Self.finish(document, url)
  }

  @Test func saveMovesTheBaseline() async throws {
    let (document, url) = try await Self.openedDocument()
    document.text = "(display 5)\n"
    await Self.save(document)
    #expect(document.savedFingerprint == Self.fingerprint("(display 5)\n"))
    // Nothing is unsaved anymore, so another app's change is no conflict
    try Data("(display 6)\n".utf8).write(to: url)
    await Self.reload(document)
    #expect(document.text == "(display 6)\n")
    #expect(!document.hasConflict)
    await Self.finish(document, url)
  }

  @Test func backgroundSaveDoesNotOverwriteAnUnresolvedConflict() async throws {
    let (document, url) = try await Self.openedDocument()
    document.resumeFilePresenter()
    document.text = "(display 1) ; mine\n"
    try Data("(display 4)\n".utf8).write(to: url)
    await Self.reload(document)
    #expect(document.hasConflict)
    await withCheckedContinuation { continuation in
      document.saveAndSuspendFilePresenter { continuation.resume() }
    }
    #expect(try Self.content(of: url) == "(display 4)\n")
    #expect(TextDocumentPresenterTests.presenterCount(of: document) == 0)
    await Self.finish(document, url)
  }
}
