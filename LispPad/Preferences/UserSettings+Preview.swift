//
//  UserSettings+Preview.swift
//  LispPad
//
//  Copyright © 2026 Matthias Zenger. All rights reserved.
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

import Foundation
import Combine

/// Hands the editor settings that matter for Scheme code to the Quick Look extension.
extension UserSettings {

  /// The settings the Quick Look extension uses for previewing Scheme code.
  var schemePreviewSettings: SchemePreviewSettings {
    let fontName = Self.monospacedFontMap.fonts[self.codingFont] ?? ""
    return SchemePreviewSettings(
      highlightSyntax: self.schemeHighlightSyntax,
      markupIdent: self.schemeMarkupIdent,
      fontName: fontName.isEmpty ? nil : fontName,
      fontSize: Double(self.editorFontSize.size),
      text: .init(light: self.textLightColor, dark: self.textDarkColor),
      parens: .init(light: self.parensLightColor, dark: self.parensDarkColor),
      literals: .init(light: self.literalsLightColor, dark: self.literalsDarkColor),
      comments: .init(light: self.commentsLightColor, dark: self.commentsDarkColor),
      docuIdent: .init(light: self.docuIdentLightColor, dark: self.docuIdentDarkColor))
  }

  /// Emits whenever one of the settings changes that make up `schemePreviewSettings`. Changes
  /// of any other setting are not reported.
  var schemePreviewSettingsChanges: AnyPublisher<Void, Never> {
    func changes<T>(of publisher: Published<T>.Publisher) -> AnyPublisher<Void, Never> {
      return publisher.dropFirst().map { _ in () }.eraseToAnyPublisher()
    }
    return Publishers.MergeMany([
      changes(of: self.$schemeHighlightSyntax),
      changes(of: self.$schemeMarkupIdent),
      changes(of: self.$codingFont),
      changes(of: self.$editorFontSize),
      changes(of: self.$textLightColor),
      changes(of: self.$textDarkColor),
      changes(of: self.$parensLightColor),
      changes(of: self.$parensDarkColor),
      changes(of: self.$literalsLightColor),
      changes(of: self.$literalsDarkColor),
      changes(of: self.$commentsLightColor),
      changes(of: self.$commentsDarkColor),
      changes(of: self.$docuIdentLightColor),
      changes(of: self.$docuIdentDarkColor)
    ]).eraseToAnyPublisher()
  }

  /// Publishes the settings now, and again whenever one of them has changed.
  func startPublishingPreviewSettings() {
    self.publishPreviewSettings()
    self.previewSettingsObserver = self.schemePreviewSettingsChanges
      .debounce(for: .milliseconds(250), scheduler: DispatchQueue.main)
      .sink { [weak self] in
        self?.publishPreviewSettings()
      }
  }

  /// The settings are collected on the calling thread and written on a queue of their own, so
  /// that neither encoding them nor reaching the shared user defaults holds up the main thread.
  private func publishPreviewSettings() {
    let settings = self.schemePreviewSettings
    Self.previewQueue.async {
      settings.store()
    }
  }

  private static let previewQueue = DispatchQueue(label: "net.objecthub.LispPad.preview-settings",
                                                  qos: .utility)
}
