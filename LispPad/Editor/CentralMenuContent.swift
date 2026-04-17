//
//  CentralEditorMenuContent.swift
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


struct CentralMenuContent: View {
  @EnvironmentObject var fileManager: FileManager
  @EnvironmentObject var histManager: HistoryManager
  @EnvironmentObject var interpreter: Interpreter
  @EnvironmentObject var settings: UserSettings
  
  @Binding var showModal: CodeEditorView.SheetAction?
  @Binding var notSavedAlertAction: CodeEditorView.NotSavedAlertAction?
  @Binding var editorType: FileExtensions.EditorType
  @Binding var codeType: CodeAnalyzer.CodeType?
  
  let dismissCard: () -> Void
  
  var body: some View {
    Button {
      self.dismissCard()
      if let path = PortableURL(self.fileManager.editorDocument?.fileURL)?.relativePath {
        UIPasteboard.general.string = path
      }
    } label: {
      Label(self.fileManager.editorDocument?.fileURL.lastPathComponent ?? "Unknown",
            systemImage: PortableURL(self.fileManager.editorDocument?.fileURL)?.base?.imageName ?? "link")
      Text((self.fileManager.editorDocument?.pathString ?? "/") + 
           " • " + (self.fileManager.editorDocument?.sizeString ?? "? B"))
    }
    .disabled(self.fileManager.editorDocumentInfo.new)
    ControlGroup {
      Button {
        self.dismissCard()
        self.fileManager.editorDocument?.saveFile { success in
          self.showModal = .moveFile
        }
      } label: {
        Label(self.fileManager.editorDocumentInfo.new ? "Save…" : "Move To…",
              systemImage: self.fileManager.editorDocumentInfo.new
              ? "tray.and.arrow.down" : "folder")
      }
      Button {
        self.dismissCard()
        if let doc = self.fileManager.editorDocument, !doc.info.new {
          doc.saveFile { success in
            if success {
              self.fileManager.loadEditorDocument(
                source: doc.fileURL,
                makeUntitled: true,
                action: { success in
                  if !success {
                    self.notSavedAlertAction = .couldNotDuplicate
                  }
                })
            } else {
              self.notSavedAlertAction = .couldNotDuplicate
            }
          }
        }
      } label: {
        Label("Duplicate", systemImage: "plus.rectangle.on.rectangle")
      }
      .disabled(self.fileManager.editorDocumentInfo.new)
      Button(role: .destructive) {
        self.dismissCard()
        self.notSavedAlertAction = .deleteFile
      } label: {
        Label("Delete", systemImage: "trash")
      }
      .disabled(self.fileManager.editorDocumentInfo.new)
    }
    Button {
      self.dismissCard()
      self.showModal = .renameFile
    } label: {
      Label("Rename…", systemImage: "pencil")
    }
    .disabled(self.fileManager.editorDocumentInfo.new)
    Button {
      self.dismissCard()
      self.histManager.toggleFavorite(self.fileManager.editorDocument?.fileURL)
    } label: {
      if self.histManager.isFavorite(self.fileManager.editorDocument?.fileURL) {
        Label("Unstar", systemImage: "star.fill")
      } else {
        Label("Star", systemImage: "star")
      }
    }
    .disabled(!self.histManager.canBeFavorite(self.fileManager.editorDocument?.fileURL))
    Button {
      if let url = self.fileManager.editorDocument?.fileURL {
        UIPasteboard.general.string = url.path
      }
    } label: {
      Label("Copy Path", systemImage: "doc.on.clipboard")
    }
    .disabled(self.fileManager.editorDocumentInfo.new)
    if let url = self.fileManager.editorDocument?.fileURL {
      Divider()
      ShareLink(item: url)
        .disabled(self.fileManager.editorDocumentInfo.new)
      if let type = self.codeType {
        self.installMenuItems(type: type, divider: false)
      }
    } else {
      if let type = self.codeType {
        self.installMenuItems(type: type, divider: true)
      }
    }
    Divider()
    Menu {
      Toggle("Show line numbers", isOn: $settings.showLineNumbers)
      Toggle("Highlight current line", isOn: $settings.highlightCurrentLine)
      Toggle("Highlight parenthesis", isOn: $settings.highlightMatchingParen)
      if self.editorType == .scheme {
        Divider()
        Toggle("Indent automatically", isOn: $settings.schemeAutoIndent)
        Toggle("Highlight syntax", isOn: $settings.schemeHighlightSyntax)
        Toggle("Markup identifiers", isOn: $settings.schemeMarkupIdent)
      } else if self.editorType == .markdown {
        Divider()
        Toggle("Indent automatically", isOn: $settings.markdownAutoIndent)
        Toggle("Highlight syntax", isOn: $settings.markdownHighlightSyntax)
      }
    } label: {
      Label("Settings", systemImage: "switch.2")
    }
  }
  
  @ViewBuilder
  private func installMenuItems(type: CodeAnalyzer.CodeType, divider: Bool) -> some View {
    switch type {
      case .library(let lib):
        if divider {
          Divider()
        }
        if self.settings.foldersOnICloud && self.settings.foldersOnDevice {
          Menu {
            Button {
              let descr = "library \(type.description) on iCloud Drive"
              if let doc = self.fileManager.editorDocument,
                 let url = PortableURL.Base.icloud.url?.appendingPathComponent("Libraries") {
                self.installLibrary(lib: lib, base: url, doc: doc, description: descr)
              } else {
                self.notSavedAlertAction = .installFailed(descr, nil)
              }
            } label: {
              Label("On iCloud Drive", systemImage: "icloud")
            }
            Button {
              let descr = "library \(type.description) \(self.localInstallName())"
              if let doc = self.fileManager.editorDocument,
                 let url = PortableURL.Base.documents.url?.appendingPathComponent("Libraries") {
                self.installLibrary(lib: lib, base: url, doc: doc, description: descr)
              } else {
                self.notSavedAlertAction = .installFailed(descr, nil)
              }
            } label: {
              self.localInstallLabel()
            }
          } label: {
            Label("Install \(type.description)", systemImage: "shippingbox")
          }
        } else {
          Button {
            if self.settings.foldersOnICloud {
              let descr = "library \(type.description) on iCloud Drive"
              if let doc = self.fileManager.editorDocument,
                 let url = PortableURL.Base.icloud.url?.appendingPathComponent("Libraries") {
                self.installLibrary(lib: lib, base: url, doc: doc, description: descr)
              } else {
                self.notSavedAlertAction = .installFailed(descr, nil)
              }
            } else if self.settings.foldersOnDevice {
              let descr = "library \(type.description) \(self.localInstallName())"
              if let doc = self.fileManager.editorDocument,
                 let url = PortableURL.Base.documents.url?.appendingPathComponent("Libraries") {
                self.installLibrary(lib: lib, base: url, doc: doc, description: descr)
              } else {
                self.notSavedAlertAction = .installFailed(descr, nil)
              }
            }
          } label: {
            Label("Install \(type.description)", systemImage: "shippingbox")
          }
        }
      case .applet(let name):
        if divider {
          Divider()
        }
        if self.settings.foldersOnICloud && self.settings.foldersOnDevice {
          Menu {
            Button {
              let descr = "applet \(type.description) on iCloud Drive"
              if let doc = self.fileManager.editorDocument,
                 let url = PortableURL.Base.icloud.url?.appendingPathComponent("Applets") {
                self.installApplet(name: name, base: url, doc: doc, description: descr)
              } else {
                self.notSavedAlertAction = .installFailed(descr, nil)
              }
            } label: {
              Label("On iCloud Drive", systemImage: "icloud")
            }
            Button {
              let descr = "applet \(type.description) \(self.localInstallName())"
              if let doc = self.fileManager.editorDocument,
                 let url = PortableURL.Base.documents.url?.appendingPathComponent("Applets") {
                self.installApplet(name: name, base: url, doc: doc, description: descr)
              } else {
                self.notSavedAlertAction = .installFailed(descr, nil)
              }
            } label: {
              self.localInstallLabel()
            }
          } label: {
            Label("Install \(type.description)", systemImage: "scroll")
          }
        } else {
          Button {
            if self.settings.foldersOnICloud {
              let descr = "applet \(type.description) on iCloud Drive"
              if let doc = self.fileManager.editorDocument,
                 let url = PortableURL.Base.icloud.url?.appendingPathComponent("Applets") {
                self.installApplet(name: name, base: url, doc: doc, description: descr)
              } else {
                self.notSavedAlertAction = .installFailed(descr, nil)
              }
            } else if self.settings.foldersOnDevice {
              let descr = "applet \(type.description) \(self.localInstallName())"
              if let doc = self.fileManager.editorDocument,
                 let url = PortableURL.Base.documents.url?.appendingPathComponent("Applets") {
                self.installApplet(name: name, base: url, doc: doc, description: descr)
              } else {
                self.notSavedAlertAction = .installFailed(descr, nil)
              }
            }
          } label: {
            Label("Install \(type.description)", systemImage: "scroll")
          }
        }
    }
  }
  
  private func installApplet(name: String, base: URL, doc: TextDocument, description: String) {
    var url = base
    url.appendPathComponent(name)
    url.appendPathExtension("scm")
    doc.saveFile { success in
      if success {
        if Foundation.FileManager.default.fileExists(atPath: url.absoluteURL.path) {
          self.notSavedAlertAction = .installOverwrites(description, url)
        } else {
          do {
            try self.fileManager.sysFileManager
                  .createDirectory(at: base, withIntermediateDirectories: true)
            try self.fileManager.sysFileManager.copyItem(at: doc.fileURL, to: url)
          } catch let err {
            self.notSavedAlertAction = .installFailed(description, err)
          }
        }
      } else {
        self.notSavedAlertAction = .installFailed(description, nil)
      }
    }
  }
  
  private func installLibrary(lib: [String], base: URL, doc: TextDocument, description: String) {
    var url = base
    for component in lib {
      url.appendPathComponent(component)
    }
    url.appendPathExtension("sld")
    let base = url.deletingLastPathComponent()
    doc.saveFile { success in
      if success {
        if Foundation.FileManager.default.fileExists(atPath: url.absoluteURL.path) {
          self.notSavedAlertAction = .installOverwrites(description, url)
        } else {
          do {
            try self.fileManager.sysFileManager
                  .createDirectory(at: base, withIntermediateDirectories: true)
            try self.fileManager.sysFileManager.copyItem(at: doc.fileURL, to: url)
          } catch let err {
            self.notSavedAlertAction = .installFailed(description, err)
          }
        }
      } else {
        self.notSavedAlertAction = .installFailed(description, nil)
      }
    }
  }
  
  private func localInstallLabel() -> some View {
    switch UIDevice.current.userInterfaceIdiom {
      case .phone:
        Label("On My iPhone", systemImage: "iphone")
      case .pad:
        Label("On My iPad", systemImage: "ipad")
      default:
        Label("On My Device", systemImage: "desktopcomputer")
    }
  }
  
  private func localInstallName() -> String {
    switch UIDevice.current.userInterfaceIdiom {
      case .phone:
        return "on your iPhone"
      case .pad:
        return "on your iPad"
      default:
        return "on your device"
    }
  }
}
