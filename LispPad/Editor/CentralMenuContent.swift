//
//  CentralMenuContent.swift
//  LispPad
//
//  Created by Matthias Zenger on 16/04/2026.
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

import SwiftUI
import UIKit

/// A transparent, invisible button overlaying the principal toolbar's title/chevron label
/// (see `CodeEditorView`) that provides the "central menu" via a native `UIMenu`.
///
/// A SwiftUI `Menu`'s content is only re-evaluated when something it observes (a `@State`/
/// `@Published` change) invalidates it -- there is no hook for "about to be presented" on
/// this platform. That made it impossible to compute the file size and, in particular, the
/// "Install Library/Applet" detection (which requires a full re-parse of the document) only
/// when the menu is actually opened: any reactive approach ends up recomputing on every
/// keystroke instead. `UIDeferredMenuElement.uncached`, by contrast, is invoked by UIKit at
/// the exact moment the menu is about to display, every single time, never cached -- exactly
/// the semantics needed here. `buildMenuElements()` below therefore reads live state directly
/// (current document, settings, favorites) rather than anything precomputed or debounced.
struct CentralMenuButton: UIViewRepresentable {
  @EnvironmentObject var fileManager: FileManager
  @EnvironmentObject var histManager: HistoryManager
  @EnvironmentObject var interpreter: Interpreter
  @EnvironmentObject var settings: UserSettings

  @Binding var showModal: CodeEditorView.SheetAction?
  @Binding var notSavedAlertAction: CodeEditorView.NotSavedAlertAction?
  @Binding var editorType: FileExtensions.EditorType

  let dismissCard: () -> Void

  func makeCoordinator() -> Coordinator {
    Coordinator(parent: self)
  }

  func makeUIView(context: Context) -> UIButton {
    let button = UIButton(type: .custom)
    button.backgroundColor = .clear
    button.showsMenuAsPrimaryAction = true
    button.menu = UIMenu(children: [
      UIDeferredMenuElement.uncached { [weak coordinator = context.coordinator] completion in
        completion(coordinator?.buildMenuElements() ?? [])
      }
    ])
    context.coordinator.button = button
    return button
  }

  func updateUIView(_ uiView: UIButton, context: Context) {
    context.coordinator.parent = self
    // The accessibility label is read directly by VoiceOver (not lazily, unlike the menu
    // content above), so it does need to be kept current here; the underlying SwiftUI label
    // is marked `.accessibilityHidden(true)` so VoiceOver only ever sees this one element.
    uiView.accessibilityLabel = self.fileManager.editorDocumentInfo.title
    uiView.accessibilityHint = "Opens the file menu"
  }

  final class Coordinator {
    var parent: CentralMenuButton
    weak var button: UIButton?

    init(parent: CentralMenuButton) {
      self.parent = parent
    }

    // MARK: - Menu construction (invoked fresh by UIKit each time the menu opens)

    func buildMenuElements() -> [UIMenuElement] {
      var sections: [UIMenuElement] = [
        self.fileInfoSection(),
        self.controlGroupSection(),
        self.rowActionsSection()
      ]
      if let shareAndInstall = self.shareAndInstallSection() {
        sections.append(shareAndInstall)
      }
      sections.append(self.settingsSection())
      return sections
    }

    private func fileInfoSection() -> UIMenuElement {
      let doc = self.parent.fileManager.editorDocument
      let isNew = self.parent.fileManager.editorDocumentInfo.new
      let action = UIAction(title: doc?.fileURL.lastPathComponent ?? "Unknown",
                            image: UIImage(systemName: PortableURL(doc?.fileURL)?.base?.imageName ?? "link"),
                            attributes: isNew ? [.disabled] : []) { [weak self] _ in
        self?.parent.dismissCard()
        if let path = PortableURL(doc?.fileURL)?.relativePath {
          UIPasteboard.general.string = path
        }
      }
      action.subtitle = (doc?.pathString ?? "/") + " • " + (doc?.sizeString ?? "? B")
      return UIMenu(options: .displayInline, children: [action])
    }

    private func controlGroupSection() -> UIMenuElement {
      let fm = self.parent.fileManager
      let isNew = fm.editorDocumentInfo.new
      let saveAction = UIAction(title: isNew ? "Save…" : "Move To…",
                                image: UIImage(systemName: isNew ? "tray.and.arrow.down" : "folder")) { [weak self] _ in
        self?.parent.dismissCard()
        fm.editorDocument?.saveFile { _ in
          self?.parent.showModal = .moveFile
        }
      }
      let duplicateAction = UIAction(title: "Duplicate",
                                     image: UIImage(systemName: "plus.rectangle.on.rectangle"),
                                     attributes: isNew ? [.disabled] : []) { [weak self] _ in
        guard let self else {
          return
        }
        self.parent.dismissCard()
        if let doc = fm.editorDocument, !doc.info.new {
          doc.saveFile { success in
            if success {
              fm.loadEditorDocument(source: doc.fileURL, makeUntitled: true) { success in
                if !success {
                  self.parent.notSavedAlertAction = .couldNotDuplicate
                }
              }
            } else {
              self.parent.notSavedAlertAction = .couldNotDuplicate
            }
          }
        }
      }
      let deleteAction = UIAction(title: "Delete",
                                  image: UIImage(systemName: "trash"),
                                  attributes: isNew ? [.destructive, .disabled] : [.destructive]) { [weak self] _ in
        self?.parent.dismissCard()
        self?.parent.notSavedAlertAction = .deleteFile
      }
      return UIMenu(options: .displayInline,
                    preferredElementSize: .medium,
                    children: [saveAction, duplicateAction, deleteAction])
    }

    private func rowActionsSection() -> UIMenuElement {
      let fm = self.parent.fileManager
      let hm = self.parent.histManager
      let isNew = fm.editorDocumentInfo.new
      let url = fm.editorDocument?.fileURL
      let renameAction = UIAction(title: "Rename…",
                                  image: UIImage(systemName: "pencil"),
                                  attributes: isNew ? [.disabled] : []) { [weak self] _ in
        self?.parent.dismissCard()
        self?.parent.showModal = .renameFile
      }
      let isFavorite = hm.isFavorite(url)
      let starAction = UIAction(title: isFavorite ? "Unstar" : "Star",
                                image: UIImage(systemName: isFavorite ? "star.fill" : "star"),
                                attributes: hm.canBeFavorite(url) ? [] : [.disabled]) { [weak self] _ in
        self?.parent.dismissCard()
        hm.toggleFavorite(url)
      }
      let copyPathAction = UIAction(title: "Copy Path",
                                    image: UIImage(systemName: "doc.on.clipboard"),
                                    attributes: isNew ? [.disabled] : []) { _ in
        if let url {
          UIPasteboard.general.string = url.path
        }
      }
      return UIMenu(options: .displayInline, children: [renameAction, starAction, copyPathAction])
    }

    private func shareAndInstallSection() -> UIMenuElement? {
      guard let doc = self.parent.fileManager.editorDocument else {
        return nil
      }
      var children: [UIMenuElement] = [self.shareAction(doc: doc)]
      if let installElement = self.installElement(doc: doc) {
        children.append(installElement)
      }
      return UIMenu(options: .displayInline, children: children)
    }

    private func shareAction(doc: TextDocument) -> UIMenuElement {
      let isNew = self.parent.fileManager.editorDocumentInfo.new
      return UIAction(title: "Share…",
                      image: UIImage(systemName: "square.and.arrow.up"),
                      attributes: isNew ? [.disabled] : []) { [weak self] _ in
        self?.presentShareSheet(for: doc.fileURL)
      }
    }

    private func presentShareSheet(for url: URL) {
      guard let button = self.button,
            let presenter = Self.topViewController(from: button) else {
        return
      }
      let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
      activityVC.popoverPresentationController?.sourceView = button
      activityVC.popoverPresentationController?.sourceRect = button.bounds
      presenter.present(activityVC, animated: true)
    }

    private static func topViewController(from view: UIView) -> UIViewController? {
      var responder: UIResponder? = view
      while let current = responder {
        if let controller = current as? UIViewController {
          var top = controller
          while let presented = top.presentedViewController {
            top = presented
          }
          return top
        }
        responder = current.next
      }
      return nil
    }

    // MARK: - Install Library/Applet

    private func installElement(doc: TextDocument) -> UIMenuElement? {
      let settings = self.parent.settings
      guard settings.foldersOnICloud || settings.foldersOnDevice,
            let type = CodeAnalyzer.codeType(doc: doc, context: self.parent.interpreter.context) else {
        return nil
      }
      let icon = UIImage(systemName: type.icon)
      if settings.foldersOnICloud && settings.foldersOnDevice {
        let icloudAction = UIAction(title: "On iCloud Drive",
                                    image: UIImage(systemName: "icloud")) { [weak self] _ in
          self?.performInstall(type: type, doc: doc, base: .icloud, locationName: "on iCloud Drive")
        }
        let localAction = UIAction(title: Self.localInstallTitle(),
                                   image: UIImage(systemName: Self.localInstallIcon())) { [weak self] _ in
          self?.performInstall(type: type, doc: doc, base: .documents, locationName: Self.localInstallName())
        }
        return UIMenu(title: "Install \(type.description)", image: icon, children: [icloudAction, localAction])
      } else {
        return UIAction(title: "Install \(type.description)", image: icon) { [weak self] _ in
          if settings.foldersOnICloud {
            self?.performInstall(type: type, doc: doc, base: .icloud, locationName: "on iCloud Drive")
          } else if settings.foldersOnDevice {
            self?.performInstall(type: type, doc: doc, base: .documents, locationName: Self.localInstallName())
          }
        }
      }
    }

    private func performInstall(type: CodeAnalyzer.CodeType,
                                doc: TextDocument,
                                base: PortableURL.Base,
                                locationName: String) {
      let descr = "\(type.itemType) \(type.description) \(locationName)"
      guard let url = base.url?.appendingPathComponent(type.folderName) else {
        self.parent.notSavedAlertAction = .installFailed(descr, nil)
        return
      }
      switch type {
        case .library(let lib):
          self.installLibrary(lib: lib, base: url, doc: doc, description: descr)
        case .applet(let name):
          self.installApplet(name: name, base: url, doc: doc, description: descr)
      }
    }

    private func installApplet(name: String, base: URL, doc: TextDocument, description: String) {
      var url = base
      url.appendPathComponent(name)
      url.appendPathExtension("scm")
      let fm = self.parent.fileManager
      doc.saveFile { [weak self] success in
        guard let self else {
          return
        }
        if success {
          if Foundation.FileManager.default.fileExists(atPath: url.absoluteURL.path) {
            self.parent.notSavedAlertAction = .installOverwrites(description, url)
          } else {
            do {
              try fm.sysFileManager.createDirectory(at: base, withIntermediateDirectories: true)
              try fm.sysFileManager.copyItem(at: doc.fileURL, to: url)
            } catch let err {
              self.parent.notSavedAlertAction = .installFailed(description, err)
            }
          }
        } else {
          self.parent.notSavedAlertAction = .installFailed(description, nil)
        }
      }
    }

    private func installLibrary(lib: [String], base: URL, doc: TextDocument, description: String) {
      var url = base
      for component in lib {
        url.appendPathComponent(component)
      }
      url.appendPathExtension("sld")
      let installBase = url.deletingLastPathComponent()
      let fm = self.parent.fileManager
      doc.saveFile { [weak self] success in
        guard let self else {
          return
        }
        if success {
          if Foundation.FileManager.default.fileExists(atPath: url.absoluteURL.path) {
            self.parent.notSavedAlertAction = .installOverwrites(description, url)
          } else {
            do {
              try fm.sysFileManager.createDirectory(at: installBase, withIntermediateDirectories: true)
              try fm.sysFileManager.copyItem(at: doc.fileURL, to: url)
            } catch let err {
              self.parent.notSavedAlertAction = .installFailed(description, err)
            }
          }
        } else {
          self.parent.notSavedAlertAction = .installFailed(description, nil)
        }
      }
    }

    private static func localInstallTitle() -> String {
      switch UIDevice.current.userInterfaceIdiom {
        case .phone:
          return "On My iPhone"
        case .pad:
          return "On My iPad"
        default:
          return "On My Device"
      }
    }

    private static func localInstallIcon() -> String {
      switch UIDevice.current.userInterfaceIdiom {
        case .phone:
          return "iphone"
        case .pad:
          return "ipad"
        default:
          return "desktopcomputer"
      }
    }

    private static func localInstallName() -> String {
      switch UIDevice.current.userInterfaceIdiom {
        case .phone:
          return "on your iPhone"
        case .pad:
          return "on your iPad"
        default:
          return "on your device"
      }
    }

    // MARK: - Settings

    private func settingsSection() -> UIMenuElement {
      UIMenu(title: "Settings", image: UIImage(systemName: "switch.2"), children: self.settingsGroups())
    }

    // A `UIAction`'s checkmark (`.state`) is fixed at the point it was built. `.keepsMenuPresented`
    // would keep the Settings submenu open across taps, but neither `UIDeferredMenuElement`
    // (its provider only re-runs when the menu is freshly (re-)presented, not merely kept open
    // -- confirmed empirically) nor rebuilding and reassigning `button.menu` in place (which,
    // also confirmed empirically, pops the user back out to the root menu instead of refreshing
    // in place) manage to keep the checkmark in sync while staying open. So each toggle instead
    // dismisses the menu like any other action: the setting is applied immediately either way,
    // and the next time the menu opens it is guaranteed to show the correct, current checkmarks.
    private func settingsGroups() -> [UIMenuElement] {
      let settings = self.parent.settings
      func toggle(_ title: String, isOn: Bool, flip: @escaping () -> Void) -> UIAction {
        UIAction(title: title, state: isOn ? .on : .off) { _ in
          flip()
        }
      }
      var groups: [UIMenuElement] = [
        UIMenu(options: .displayInline, children: [
          toggle("Show line numbers", isOn: settings.showLineNumbers) { settings.showLineNumbers.toggle() },
          toggle("Highlight current line", isOn: settings.highlightCurrentLine) { settings.highlightCurrentLine.toggle() },
          toggle("Highlight parenthesis", isOn: settings.highlightMatchingParen) { settings.highlightMatchingParen.toggle() }
        ])
      ]
      switch self.parent.editorType {
        case .scheme:
          groups.append(UIMenu(options: .displayInline, children: [
            toggle("Indent automatically", isOn: settings.schemeAutoIndent) { settings.schemeAutoIndent.toggle() },
            toggle("Highlight syntax", isOn: settings.schemeHighlightSyntax) { settings.schemeHighlightSyntax.toggle() },
            toggle("Markup identifiers", isOn: settings.schemeMarkupIdent) { settings.schemeMarkupIdent.toggle() }
          ]))
        case .markdown:
          groups.append(UIMenu(options: .displayInline, children: [
            toggle("Indent automatically", isOn: settings.markdownAutoIndent) { settings.markdownAutoIndent.toggle() },
            toggle("Highlight syntax", isOn: settings.markdownHighlightSyntax) { settings.markdownHighlightSyntax.toggle() }
          ]))
        default:
          break
      }
      return groups
    }
  }
}
