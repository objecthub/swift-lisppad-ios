//
//  SchemePreviewSettingsTests.swift
//  LispPadTests
//
//  Created by Matthias Zenger on 30/10/2026.
//

import Testing
import Combine
import UIKit
@testable import LispPad

@MainActor
struct SchemePreviewSettingsTests {

  /// User defaults that exist for the duration of a test only.
  static func temporaryDefaults() -> UserDefaults {
    return UserDefaults(suiteName: "net.objecthub.LispPad.tests.\(UUID().uuidString)")!
  }

  static func components(of color: UIColor, in style: UIUserInterfaceStyle) -> [Double] {
    let resolved = color.resolvedColor(with: UITraitCollection(userInterfaceStyle: style))
    var red: CGFloat = 0.0
    var green: CGFloat = 0.0
    var blue: CGFloat = 0.0
    var alpha: CGFloat = 0.0
    resolved.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
    return [red, green, blue, alpha].map { Double($0) }
  }

  @Test func loadWithoutPublishedSettingsGivesDefaults() {
    #expect(SchemePreviewSettings.load(from: Self.temporaryDefaults()) == .default)
    #expect(SchemePreviewSettings.load(from: nil) == .default)
  }

  @Test func storedSettingsAreLoadedAgain() {
    let defaults = Self.temporaryDefaults()
    var settings = SchemePreviewSettings.default
    settings.highlightSyntax = false
    settings.markupIdent = false
    settings.fontName = "Menlo-Regular"
    settings.fontSize = 16.0
    settings.comments = .init(light: .init(0.1, 0.2, 0.3, 0.4), dark: .init(0.5, 0.6, 0.7, 0.8))
    settings.store(in: defaults)
    #expect(SchemePreviewSettings.load(from: defaults) == settings)
    settings.store(in: defaults)
    #expect(SchemePreviewSettings.load(from: defaults) == settings)
  }

  @Test func defaultsMatchEditorDefaults() {
    let settings = SchemePreviewSettings.default
    #expect(settings.highlightSyntax)
    #expect(settings.markupIdent)
    #expect(settings.fontName == nil)
    #expect(settings.fontSize == Double(FontMap.FontSize.compact.size))
    #expect(settings.text.light == .init(0.0, 0.0, 0.0))
    #expect(settings.docuIdent.light == .init(0.2, 0.2, 1.0))
    #expect(settings.parens.light == .init(0.6, 0.35, 0.2))
    #expect(settings.literals.light == .init(0.0, 0.6, 0.0))
    #expect(settings.comments.light == .init(1.0, 0.1, 0.1))
    #expect(settings.text.dark == .init(1.0, 1.0, 1.0))
    #expect(settings.docuIdent.dark == .init(0.5, 0.8, 1.0))
    #expect(settings.parens.dark == .init(0.85, 0.75, 0.45))
    #expect(settings.literals.dark == .init(0.7, 0.8, 0.3))
    #expect(settings.comments.dark == .init(1.0, 0.55, 0.45))
  }

  @Test func paletteFollowsAppearance() {
    let palette = SchemePreviewSettings.default.palette
    #expect(Self.components(of: palette.text, in: .light) == [0.0, 0.0, 0.0, 1.0])
    #expect(Self.components(of: palette.text, in: .dark) == [1.0, 1.0, 1.0, 1.0])
    #expect(Self.components(of: palette.literals, in: .light) == [0.0, 0.6, 0.0, 1.0])
    #expect(Self.components(of: palette.literals, in: .dark) == [0.7, 0.8, 0.3, 1.0])
  }

  @Test func colorsConvertToRGBA() {
    #expect(SchemePreviewSettings.RGBA(UIColor.white) == .init(1.0, 1.0, 1.0, 1.0))
    #expect(SchemePreviewSettings.RGBA(UIColor(red: 0.25, green: 0.5, blue: 0.75, alpha: 0.5))
              == .init(0.25, 0.5, 0.75, 0.5))
  }

  /// Polls `condition` until it holds, or until `timeout` is over. Changes are published
  /// after a debounce on the main queue, and every other test that changes a setting restarts
  /// the debounce. Hence, there is no fixed time after which a change is known to have arrived.
  static func eventually(timeout: Duration = .seconds(30),
                         _ condition: () -> Bool) async throws -> Bool {
    let clock = ContinuousClock()
    let deadline = clock.now + timeout
    while !condition() {
      guard clock.now < deadline else {
        return false
      }
      try await Task.sleep(for: .milliseconds(50))
    }
    return true
  }

  @Test func changedUserSettingsArePublished() async throws {
    let settings = UserSettings.standard
    let original = settings.commentsLightColor
    let changed = SchemePreviewSettings.RGBA(0.125, 0.25, 0.375, 1.0)
    settings.commentsLightColor = UIColor(red: 0.125, green: 0.25, blue: 0.375, alpha: 1.0)
    _ = try await Self.eventually { SchemePreviewSettings.load().comments.light == changed }
    let published = SchemePreviewSettings.load().comments.light
    // The published settings are shared with the previews of the installed app. Put the
    // setting back and wait until that is published as well, so no test color is left behind.
    settings.commentsLightColor = original
    let restored = try await Self.eventually {
      SchemePreviewSettings.load() == settings.schemePreviewSettings
    }
    #expect(published == changed)
    #expect(restored)
  }

  @Test func onlySettingsOfTheSnapshotAreReported() {
    let settings = UserSettings.standard
    let execOnReturn = settings.consoleExecOnReturn
    let markdownHighlighting = settings.markdownHighlightSyntax
    let markupIdent = settings.schemeMarkupIdent
    let codingFont = settings.codingFont
    var reported = 0
    let observer = settings.schemePreviewSettingsChanges.sink { reported += 1 }
    defer {
      observer.cancel()
      settings.consoleExecOnReturn = execOnReturn
      settings.markdownHighlightSyntax = markdownHighlighting
      settings.schemeMarkupIdent = markupIdent
      settings.codingFont = codingFont
    }
    settings.consoleExecOnReturn.toggle()
    settings.markdownHighlightSyntax.toggle()
    #expect(reported == 0)
    settings.schemeMarkupIdent.toggle()
    #expect(reported == 1)
    settings.codingFont = codingFont == "Menlo" ? "System" : "Menlo"
    #expect(reported == 2)
  }

  @Test func userSettingsAreMappedToSnapshot() {
    let settings = UserSettings.standard
    let codingFont = settings.codingFont
    let fontSize = settings.editorFontSize
    let comments = settings.commentsDarkColor
    defer {
      settings.codingFont = codingFont
      settings.editorFontSize = fontSize
      settings.commentsDarkColor = comments
    }
    settings.codingFont = "System"
    settings.editorFontSize = .large
    settings.commentsDarkColor = UIColor(red: 0.25, green: 0.5, blue: 0.75, alpha: 1.0)
    var snapshot = settings.schemePreviewSettings
    #expect(snapshot.fontName == nil)
    #expect(snapshot.fontSize == 16.0)
    #expect(snapshot.comments.dark == .init(0.25, 0.5, 0.75, 1.0))
    settings.codingFont = "Menlo"
    snapshot = settings.schemePreviewSettings
    #expect(snapshot.fontName == UserSettings.monospacedFontMap.fonts["Menlo"])
    #expect(snapshot.highlightSyntax == settings.schemeHighlightSyntax)
    #expect(snapshot.markupIdent == settings.schemeMarkupIdent)
  }
}
