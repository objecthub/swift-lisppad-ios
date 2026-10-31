//
//  TextDocumentPresenterTests.swift
//  LispPadTests
//
//  Created by Matthias Zenger on 30/10/2026.
//

import Testing
import UIKit
@testable import LispPad

@MainActor
struct TextDocumentPresenterTests {

  static func temporaryFile() throws -> URL {
    let url = Foundation.FileManager.default.temporaryDirectory
      .appendingPathComponent("document-\(UUID().uuidString).scm")
    try Data("(display 1)\n".utf8).write(to: url)
    return url
  }

  static func presenterCount(of document: TextDocument) -> Int {
    return NSFileCoordinator.filePresenters.filter { $0 === document }.count
  }

  static func open(_ document: TextDocument) async -> Bool {
    return await withCheckedContinuation { continuation in
      document.open { continuation.resume(returning: $0) }
    }
  }

  static func close(_ document: TextDocument) async {
    await withCheckedContinuation { continuation in
      document.close { _ in continuation.resume() }
    }
  }

  @Test func openDocumentStepsAsideWhileSuspended() async throws {
    let url = try Self.temporaryFile()
    defer {
      try? Foundation.FileManager.default.removeItem(at: url)
    }
    let document = TextDocument(fileURL: url)
    #expect(await Self.open(document))
    #expect(Self.presenterCount(of: document) == 1)
    document.suspendFilePresenter()
    #expect(Self.presenterCount(of: document) == 0)
    document.resumeFilePresenter()
    #expect(Self.presenterCount(of: document) == 1)
    await Self.close(document)
  }

  @Test func documentStepsAsideOnceItsSaveIsDone() async throws {
    let url = try Self.temporaryFile()
    defer {
      try? Foundation.FileManager.default.removeItem(at: url)
    }
    let document = TextDocument(fileURL: url)
    #expect(await Self.open(document))
    await withCheckedContinuation { continuation in
      document.saveAndSuspendFilePresenter {
        continuation.resume()
      }
    }
    #expect(Self.presenterCount(of: document) == 0)
    document.resumeFilePresenter()
    #expect(Self.presenterCount(of: document) == 1)
    await Self.close(document)
  }

  @Test func documentStaysPresenterIfTheAppReturnsBeforeTheSaveIsDone() async throws {
    let url = try Self.temporaryFile()
    defer {
      try? Foundation.FileManager.default.removeItem(at: url)
    }
    let document = TextDocument(fileURL: url)
    #expect(await Self.open(document))
    await withCheckedContinuation { continuation in
      document.saveAndSuspendFilePresenter {
        continuation.resume()
      }
      document.resumeFilePresenter()
    }
    #expect(Self.presenterCount(of: document) == 1)
    await Self.close(document)
  }

  @Test func suspendingAndResumingTwiceChangesNothing() async throws {
    let url = try Self.temporaryFile()
    defer {
      try? Foundation.FileManager.default.removeItem(at: url)
    }
    let document = TextDocument(fileURL: url)
    #expect(await Self.open(document))
    document.suspendFilePresenter()
    document.suspendFilePresenter()
    #expect(Self.presenterCount(of: document) == 0)
    document.resumeFilePresenter()
    document.resumeFilePresenter()
    #expect(Self.presenterCount(of: document) == 1)
    await Self.close(document)
  }

  @Test func closedDocumentIsNotRegisteredAgain() async throws {
    let url = try Self.temporaryFile()
    defer {
      try? Foundation.FileManager.default.removeItem(at: url)
    }
    let document = TextDocument(fileURL: url)
    #expect(await Self.open(document))
    document.suspendFilePresenter()
    await Self.close(document)
    document.resumeFilePresenter()
    #expect(Self.presenterCount(of: document) == 0)
  }

  @Test func documentThatIsNotOpenIsLeftAlone() throws {
    let url = try Self.temporaryFile()
    defer {
      try? Foundation.FileManager.default.removeItem(at: url)
    }
    let document = TextDocument(fileURL: url)
    document.suspendFilePresenter()
    document.resumeFilePresenter()
    #expect(Self.presenterCount(of: document) == 0)
  }
}
