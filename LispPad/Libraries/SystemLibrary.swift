//
//  SystemLibrary.swift
//  LispPad
//
//  Created by Matthias Zenger on 22/03/2021.
//  Copyright © 2021-2023 Matthias Zenger. All rights reserved.
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
import UIKit
import LispKit
import PhotosUI
import SwiftUI
import MobileCoreServices // Remove again

///
/// This class implements the LispPad-specific library `(lisppad system ios)`.
///
public final class SystemLibrary: NativeLibrary {
  internal weak var interpreter: Interpreter? = nil
  
  private let bursts: Symbol            // Assets with multiple high-speed photos
  private let cinematicVideos: Symbol   // Videos with a shallow depth of field and focus transitions
  private let depthEffectPhotos: Symbol // Photos with depth information
  private let images: Symbol            // Images including Live Photos
  private let livePhotos: Symbol        // Live Photos
  private let panoramas: Symbol         // Panorama photos
  private let screenRecordings: Symbol  // Screen recordings
  private let screenshots: Symbol       // Screenshots
  private let slomoVideos: Symbol       // Slow-motion videos
  private let timelapseVideos: Symbol   // Time-lapse videos
  private let videos: Symbol            // Videos
  private let or: Symbol                // Or operator
  private let and: Symbol               // And operator
  private let not: Symbol               // Not operator
  private let tempDir: URL
  
  /// Name of the library.
  public override class var name: [String] {
    return ["lisppad", "system", "ios"]
  }
  
  /// Initialization
  public required init(in context: Context) throws {
    self.bursts = context.symbols.intern("bursts")
    self.cinematicVideos = context.symbols.intern("cinematic-videos")
    self.depthEffectPhotos = context.symbols.intern("depth-effect-photos")
    self.images = context.symbols.intern("images")
    self.livePhotos = context.symbols.intern("live-photos")
    self.panoramas = context.symbols.intern("panoramas")
    self.screenRecordings = context.symbols.intern("screen-recordings")
    self.screenshots = context.symbols.intern("screenshots")
    self.slomoVideos = context.symbols.intern("slomo-videos")
    self.timelapseVideos = context.symbols.intern("timelapse-videos")
    self.videos = context.symbols.intern("videos")
    self.and = context.symbols.intern("and")
    self.or = context.symbols.intern("or")
    self.not = context.symbols.intern("not")
    self.tempDir = URL(fileURLWithPath: NSTemporaryDirectory())
                     .appendingPathComponent(UUID().uuidString)
    try super.init(in: context)
  }
  
  /// Declarations of the library.
  public override func declarations() {
    // Use files in iOS
    self.define(Procedure("open-in-files-app", self.openInFilesApp))
    self.define(Procedure("preview-file", self.previewFile))
    self.define(Procedure("share-file", self.shareFile))
    // Show interactive panels
    self.define(Procedure("show-message-panel", self.showMessagePanel))
    self.define(Procedure("show-confirmation-panel", self.showConfirmationPanel))
    self.define(Procedure("show-choice-panel", self.showChoicePanel))
    self.define(Procedure("show-input-panel", self.showInputPanel))
    self.define(Procedure("show-date-panel", self.showDatePanel))
    self.define(Procedure("show-preview-panel", self.showPreviewPanel))
    self.define(Procedure("show-share-panel", self.showSharePanel))
    self.define(Procedure("show-load-panel", self.showLoadPanel))
    self.define(Procedure("show-save-panel", self.showSavePanel))
    self.define(Procedure("show-interpreter-tab", self.showInterpreterTab))
    self.define(Procedure("show-help", self.showHelp))
    // Manage canvases
    self.define(Procedure("make-canvas", self.makeCanvas))
    self.define(Procedure("use-canvas", self.useCanvas))
    self.define(Procedure("close-canvas", self.closeCanvas))
    self.define(Procedure("canvas-name", self.canvasName))
    self.define(Procedure("set-canvas-name!", self.setCanvasName))
    self.define(Procedure("canvas-size", self.canvasSize))
    self.define(Procedure("set-canvas-size!", self.setCanvasSize))
    self.define(Procedure("canvas-scale", self.canvasScale))
    self.define(Procedure("set-canvas-scale!", self.setCanvasScale))
    self.define(Procedure("canvas-background", self.canvasBackground))
    self.define(Procedure("set-canvas-background!", self.setCanvasBackground))
    self.define(Procedure("canvas-drawing", self.canvasDrawing))
    self.define(Procedure("set-canvas-drawing!", self.setCanvasDrawing))
    // Load and save bitmaps into the library
    self.define(Procedure("save-bitmap-in-library", self.saveBitmapInLibrary))
    self.define(Procedure("load-bitmaps-from-library", self.loadBitmapsFromLibrary))
    self.define(Procedure("load-bytevectors-from-library", self.loadBytevectorsFromLibrary))
    // Sessions
    self.define(Procedure("session-id",  self.sessionId))
    self.define(Procedure("session-name",  self.sessionName))
    self.define(Procedure("session-log", self.sessionLog))
    // Local directories
    self.define(Procedure("project-directory", self.projectDirectory))
    self.define(Procedure("icloud-directory", self.icloudDirectory))
    // Information about the environment
    self.define(Procedure("screen-size", self.screenSize))
    self.define(Procedure("dark-mode?", self.isDarkMode))
    self.define(Procedure("icloud-list", self.iCloudList))
  }
  
  private func openInFilesApp(expr: Expr) throws -> Expr {
    let path = self.context.fileHandler.path(
                 try expr.asPath(),
                 relativeTo: self.context.evaluator.currentDirectoryPath)
    if let url = URL(string: "shareddocuments://\(path)") {
      DispatchQueue.main.async {
        UIApplication.shared.open(url)
      }
    }
    return .void
  }
  
  private func previewFile(expr: Expr) throws -> Expr {
    let path = self.context.fileHandler.path(
                 try expr.asPath(),
                 relativeTo: self.context.evaluator.currentDirectoryPath)
    DispatchQueue.main.async {
      self.interpreter?.previewUrl = URL(filePath: path)
    }
    return .void
  }
  
  private func shareFile(expr: Expr) throws -> Expr {
    let path = self.context.fileHandler.path(
                 try expr.asPath(),
                 relativeTo: self.context.evaluator.currentDirectoryPath)
    DispatchQueue.main.async {
      self.interpreter?.sheetAction = .share(url: URL(filePath: path), onDisappear: { })
    }
    return .void
  }
  
  private func showMessagePanel(_ title: Expr,
                                _ message: Expr?,
                                _ button: Expr?) throws -> Expr {
    if let interpreter {
      let title = title.isTrue ? try title.asString() : "Alert"
      let message = try message?.asString() ?? ""
      let yes = (button?.isTrue ?? false) ? try button!.asString() : "OK"
      let responseSemaphore = DispatchSemaphore(value: 0)
      var confirmed: Bool = false
      var done: Bool = false
      DispatchQueue.main.async {
        if interpreter.choiceAlert == nil {
          interpreter.choiceAlert = .init(
            title: title,
            message: message,
            options: [],
            cancel: nil,
            confirm: yes,
            onCancel: {
              done = true
              confirmed = true
              responseSemaphore.signal()
            },
            onConfirm: { str in
              done = true
              confirmed = true
              responseSemaphore.signal()
            })
        } else {
          done = true
          responseSemaphore.signal()
        }
      }
      while !done && !self.context.evaluator.isAbortionRequested() {
        _ = responseSemaphore.wait(timeout: .now() + 0.5)
      }
      return confirmed ? .void : .false
    }
    return .void
  }
  
  private func showConfirmationPanel(_ title: Expr,
                                     _ message: Expr,
                                     _ yes: Expr?,
                                     _ no: Expr?) throws -> Expr {
    if let interpreter {
      let title = title.isTrue ? try title.asString() : "Confirm"
      let message = message.isTrue ? try message.asString() : ""
      let yes = (yes?.isTrue ?? false) ? try yes!.asString() : "Yes"
      let no = (no?.isTrue ?? false) ? try no!.asString() : "No"
      let responseSemaphore = DispatchSemaphore(value: 0)
      var res: Bool = false
      var done: Bool = false
      DispatchQueue.main.async {
        if interpreter.choiceAlert == nil {
          interpreter.choiceAlert = .init(
            title: title,
            message: message,
            options: [],
            cancel: no,
            confirm: yes,
            onCancel: {
              res = false
              done = true
              responseSemaphore.signal()
            },
            onConfirm: { str in
              res = true
              done = true
              responseSemaphore.signal()
            })
        } else {
          done = true
          responseSemaphore.signal()
        }
      }
      while !done && !self.context.evaluator.isAbortionRequested() {
        _ = responseSemaphore.wait(timeout: .now() + 0.5)
      }
      return .makeBoolean(res)
    } else {
      return .false
    }
  }
  
  private func showChoicePanel(_ title: Expr,
                               _ message: Expr,
                               _ options: Expr,
                               _ selected: Expr?,
                               _ confirm: Expr?) throws -> Expr {
    if let interpreter {
      let title = title.isTrue ? try title.asString() : "Choose"
      let message = message.isTrue ? try message.asString() : ""
      var lst = options
      let responseSemaphore = DispatchSemaphore(value: 0)
      var res: Int? = nil
      var done = false
      var alternatives: [String] = []
      while case .pair(let opt, let rest) = lst {
        if case .pair(let str, _) = opt {
          alternatives.append(try str.asString())
        } else {
          alternatives.append(try opt.asString())
        }
        lst = rest
      }
      let selected = (selected?.isTrue ?? false) ? try selected!.asString() : nil
      let yes = (confirm?.isTrue ?? false) ? try confirm!.asString() : "Select"
      var choice: String? = nil
      DispatchQueue.main.async {
        if interpreter.choiceAlert == nil {
          interpreter.choiceAlert = .init(
            title: title,
            message: message,
            options: alternatives,
            selected: selected,
            cancel: "Cancel",
            confirm: yes,
            onCancel: {
              choice = nil
              done = true
              responseSemaphore.signal()
            },
            onConfirm: {
              choice = $0
              done = true
              responseSemaphore.signal()
            })
        } else {
          done = true
          responseSemaphore.signal()
        }
      }
      while !done && !self.context.evaluator.isAbortionRequested() {
        _ = responseSemaphore.wait(timeout: .now() + 0.5)
      }
      if let choice {
        for i in alternatives.indices {
          if alternatives[i] == choice {
            res = i
            break
          }
        }
      }
      return res == nil ? .false : .makeNumber(res!)
    } else {
      return .false
    }
  }
  
  private func showInputPanel(_ title: Expr,
                              _ message: Expr,
                              _ args: Arguments) throws -> Expr {
    guard let (intl, pholder, confirm) = args.optional(.false, .false, .false) else {
      throw RuntimeError.argumentCount(of: "show-input-panel",
                                       min: 2,
                                       max: 5,
                                       args: .pair(title, .pair(message, .makeList(args))))
    }
    if let interpreter {
      let title = title.isTrue ? try title.asString() : "Input"
      let message = message.isTrue ? try message.asString() : ""
      let initial = intl.isTrue ? try intl.asString() : ""
      let placeholder = pholder.isTrue ? try pholder.asString() : ""
      let yes = confirm.isTrue ? try confirm.asString() : "OK"
      let responseSemaphore = DispatchSemaphore(value: 0)
      var res: String? = nil
      var done: Bool = false
      DispatchQueue.main.async {
        if interpreter.textInputAlert == nil {
          interpreter.textInputAlert = .init(
            title: title,
            message: message,
            placeholder: placeholder,
            initial: initial,
            confirm: yes,
            onCancel: {
              res = nil
              done = true
              responseSemaphore.signal()
            },
            onConfirm: {
              res = $0
              done = true
              responseSemaphore.signal()
            })
        } else {
          done = true
          responseSemaphore.signal()
        }
      }
      while !done && !self.context.evaluator.isAbortionRequested() {
        _ = responseSemaphore.wait(timeout: .now() + 0.5)
      }
      return res == nil ? .false : .makeString(res!)
    } else {
      return .false
    }
  }
  
  static let calendar = Calendar(identifier: Calendar.Identifier.gregorian)
  
  private func asDate(_ expr: Expr) throws -> Date {
    guard case .object(let obj) = expr,
          let box = obj as? NativeDateTime else {
      throw RuntimeError.type(expr, expected: [NativeDateTime.type])
    }
    if let res = Self.calendar.date(from: box.value) {
      return res
    } else {
      throw RuntimeError.type(expr, expected: [NativeDateTime.type])
    }
  }
  
  private func asDateComponents(_ expr: Expr) throws -> DateComponents {
    guard case .object(let obj) = expr,
          let box = obj as? NativeDateTime else {
      throw RuntimeError.type(expr, expected: [NativeDateTime.type])
    }
    return box.value
  }
  
  private func toDateTime(_ date: Date, in timeZone: TimeZone) -> Expr {
    return .object(NativeDateTime(Self.calendar.dateComponents(in: timeZone, from: date)))
  }
  
  private func showDatePanel(_ title: Expr,
                             _ message: Expr,
                             _ type: Expr,
                             _ args: Arguments) throws -> Expr {
    guard let (intl, rng, tzone, confirm, cancel) = args.optional(.false, .false, .false,
                                                                  .false, .false) else {
      throw RuntimeError.argumentCount(of: "show-date-panel",
                                       min: 3,
                                       max: 8,
                                       args: .pair(title, .pair(message, .makeList(args))))
    }
    if let interpreter {
      let title = title.isTrue ? try title.asString() : nil
      let message = message.isTrue ? try message.asString() : nil
      // Determine timezone
      let timezone: TimeZone?
      switch tzone {
        case .false:
          timezone = .current
        case .fixnum(let delta):
          if delta > Int64(Int.min) && delta < Int64(Int.max) {
            timezone = TimeZone(secondsFromGMT: Int(delta))
          } else {
            timezone = nil
          }
        case .flonum(let delta):
          if delta > Double(Int.min) && delta < Double(Int.max) {
            timezone = TimeZone(secondsFromGMT: Int(delta)) ?? .current
          } else {
            timezone = nil
          }
        case .symbol(let sym):
          timezone = TimeZone(abbreviation: sym.identifier)
        case .string(let str):
          timezone = TimeZone(identifier: str as String) ?? TimeZone(abbreviation: str as String)
        default:
          timezone = nil
      }
      guard let timezone else {
        throw RuntimeError.eval(.invalidTimeZone, tzone)
      }
      // Determine date panel type and initial selection
      let initial: FlexDatePicker.Value
      switch try type.asSymbol().identifier {
        case "single":
          initial = .single(intl.isTrue ? try self.asDate(intl) : nil)
        case "range":
          switch intl {
            case .false, .null:
              initial = .range(nil)
            case .pair(let lower, let upper):
              initial = .range(ClosedRange(uncheckedBounds: (try self.asDate(lower),
                                                             try self.asDate(upper))))
            default:
              throw RuntimeError.type(intl, expected: [.pairType])
          }
        case "multiple":
          switch intl {
            case .false, .null:
              initial = .multi([])
            case .pair(_, _):
              var lst = intl
              var dates = Set<DateComponents>()
              while case .pair(let d, let rest) = lst {
                dates.insert(try self.asDateComponents(d))
                lst = rest
              }
              initial = .multi(dates)
            default:
              throw RuntimeError.type(intl, expected: [.pairType])
          }
        default:
          throw RuntimeError.type(type, expected: [NativeDateTime.type, .pairType])
      }
      // Determine allowed date range
      let bounds: Range<Date>?
      switch rng {
        case .false, .null:
          bounds = nil
        case .pair(let lower, let upper):
          bounds = Range(uncheckedBounds: (try self.asDate(lower), try self.asDate(upper)))
        default:
          throw RuntimeError.type(rng, expected: [.pairType])
      }
      // Extract the rest of the arguments
      let no = cancel.isTrue ? try cancel.asString() : "Cancel"
      let yes = confirm.isTrue ? try confirm.asString() : "Select"
      let responseSemaphore = DispatchSemaphore(value: 0)
      var res: FlexDatePicker.Value? = nil
      var done: Bool = false
      DispatchQueue.main.async {
        if interpreter.dateInputAlert == nil {
          interpreter.dateInputAlert = .init(
            title: title,
            message: message,
            initial: initial,
            bounds: bounds,
            cancel: no,
            confirm: yes,
            onCancel: {
              res = nil
              done = true
              responseSemaphore.signal()
            },
            onConfirm: {
              res = $0
              done = true
              responseSemaphore.signal()
            })
        } else {
          done = true
          responseSemaphore.signal()
        }
      }
      while !done && !self.context.evaluator.isAbortionRequested() {
        _ = responseSemaphore.wait(timeout: .now() + 0.5)
      }
      guard let res else {
        return .false
      }
      switch res {
        case .single(let date):
          if let date {
            return self.toDateTime(date, in: timezone)
          } else {
            return .false
          }
        case .range(let range):
          if let range {
            return .pair(self.toDateTime(range.lowerBound, in: timezone),
                         self.toDateTime(range.upperBound, in: timezone))
          } else {
            return .false
          }
        case .multi(let dates):
          var res = Expr.null
          for date in dates {
            res = .pair(.object(NativeDateTime(date)), res)
          }
          return res
      }
    } else {
      return .false
    }
  }
  
  private func writeTempFile(expr: Expr, ext: Expr?) throws -> URL? {
    var extens = try ext?.asString()
    var fileType: BitmapImageFileType? = nil
    if let ext = extens?.lowercased() {
      switch ext {
        case "png":
          fileType = .png
        case "jpg", "jpeg":
          fileType = .jpeg
        case "gif":
          fileType = .gif
        case "bmp":
          fileType = .bmp
        case "tiff", "tif":
          fileType = .tiff
        case "text", "txt":
          extens = "txt"
        case "markdown", "md":
          extens = "md"
        case "html", "htm":
          extens = "html"
        case "rtf":
          extens = "rtf"
        case "rtfd":
          extens = "rtfd"
        default:
          break
      }
    }
    guard (try? Foundation.FileManager.default.createDirectory(
             at: self.tempDir, withIntermediateDirectories: true)) != nil else {
      return nil
    }
    var data: Data? = nil
    switch expr {
      case .string(let str):
        extens = extens ?? "txt"
        data = (str as String).data(using: .utf8)
      case .bytes(let bv):
        data = NSData(bytesNoCopy: &bv.value, length: bv.value.count, freeWhenDone: false) as Data
      case .object(let obj):
        if let image = (obj as? NativeImage)?.value {
          extens = extens ?? "png"
          data = (fileType ?? .png).data(for: image, qualityFactor: 0.9)
        } else if let drawing = obj as? Drawing {
          if let image = iconImage(for: drawing,
                                   width: 1500,
                                   height: 1500,
                                   scale: 4.0,
                                   renderingWidth: 1500,
                                   renderingHeight: 1500) {
            extens = extens ?? "png"
            data = (fileType ?? .png).data(for: image, qualityFactor: 0.9)
          }
        } else if let astr = (obj as? StyledText)?.value {
          let type: NSAttributedString.DocumentType = extens == "rtf" ? .rtf : .rtfd 
          let fileWrapper = try? astr.fileWrapper(from: NSMakeRange(0, astr.length),
                                                  documentAttributes: [.documentType : type])
          let url = self.tempDir.appendingPathComponent("Preview")
                                .appendingPathExtension(extens ?? "rtfd")
          guard (try? fileWrapper?.write(to: url, originalContentsURL: nil)) != nil else {
            return nil
          }
          return url
        }
      default:
        extens = extens ?? "txt"
        data = expr.description.data(using: .utf8)
    }
    guard let data = data else {
      return nil
    }
    let url: URL
    if let extens {
      url = self.tempDir.appendingPathComponent("Preview").appendingPathExtension(extens)
    } else {
      url = self.tempDir.appendingPathComponent("Preview")
    }
    guard (try? data.write(to: url)) != nil else {
      return nil
    }
    return url
  }
  
  private func showPreviewPanel(expr: Expr, ext: Expr?) throws -> Expr {
    if let url = try self.writeTempFile(expr: expr, ext: ext) {
      DispatchQueue.main.async {
        self.interpreter?.previewUrl = url
        self.interpreter?.toDeleteUrl = url
      }
      return .true
    } else {
      return .false
    }
  }
  
  private func showSharePanel(expr: Expr, ext: Expr?) throws -> Expr {
    if let url = try self.writeTempFile(expr: expr, ext: ext) {
      DispatchQueue.main.async {
        self.interpreter?.sheetAction = .share(url: url) {
          
        }
        self.interpreter?.toDeleteUrl = url
      }
      return .true
    } else {
      return .false
    }
  }
  
  private func showLoadPanel(prompt: Expr, folders: Expr?, filetypes: Expr?) throws -> Expr {
    let title = try prompt.asString()
    let folders = folders?.isTrue ?? false
    var suffixes: Set<String>? = nil
    if var ftypes = filetypes {
      suffixes = []
      while case .pair(.string(let str), let rest) = ftypes {
        suffixes?.insert(str as String)
        ftypes = rest
      }
    }
    let result = AsyncResult<URL?>()
    DispatchQueue.main.async {
      self.interpreter?.sheetAction = .open(title: title,
                                            directories: folders,
                                            onOpen: { url in
                                              if suffixes != nil && !url.pathExtension.isEmpty {
                                                return suffixes!.contains(url.pathExtension)
                                              } else {
                                                result.set(value: url)
                                                return true
                                              }
                                            },
                                            onDisappear: result.abort)
    }
    if let url = try result.value(aborted: nil) {
      return .makeString(url.path)
    } else {
      return .false
    }
  }
  
  private func showSavePanel(prompt: Expr, expr: Expr?, lock: Expr?) throws -> Expr {
    let title = try prompt.asString()
    let path = expr == nil
                 ? nil
                 : self.context.fileHandler.path(
                     try expr!.asPath(), relativeTo: self.context.evaluator.currentDirectoryPath)
    let lockFolder = lock?.isTrue ?? false
    let result = AsyncResult<URL?>()
    DispatchQueue.main.async {
      self.interpreter?.sheetAction = .save(title: title,
                                            url: path == nil ? nil : URL(filePath: path!),
                                            lockFolder: lockFolder,
                                            onSave: { url in 
                                              result.set(value: url)
                                              return true
                                            },
                                            onDisappear: result.abort)
    }
    if let url = try result.value(aborted: nil) {
      return .makeString(url.path)
    } else {
      return .false
    }
  }
  
  private func showInterpreterTab(expr: Expr, arg: Expr?) throws -> Expr {
    let tab = try expr.asSymbol()
    switch tab.identifier {
      case "log":
        DispatchQueue.main.async {
          withAnimation {
            self.interpreter?.consoleTab = 0
          }
        }
      case "console":
        DispatchQueue.main.async {
          withAnimation {
            self.interpreter?.consoleTab = 1
          }
        }
      case "canvas":
        if let arg {
          let canvas = try self.canvas(from: arg)
          DispatchQueue.main.async {
            withAnimation {
              self.interpreter?.consoleTab = 2
              self.interpreter?.canvas = canvas
            }
          }
        } else {
          DispatchQueue.main.async {
            withAnimation {
              self.interpreter?.consoleTab = 2
            }
          }
        }
      default:
        throw RuntimeError.custom("error", "unknown tab", [expr])
    }
    return .void
  }
  
  private func showHelp(expr: Expr) throws -> Expr {
    let definition: String
    switch expr {
      case .symbol(let sym):
         definition = sym.identifier
      default:
        definition = try expr.asString()
    }
    DispatchQueue.main.async {
      self.interpreter?.helpDefinition = definition
    }
    return .void
  }
  
  private func drawing(from expr: Expr) throws -> Drawing {
    guard case .object(let obj) = expr, let drawing = obj as? Drawing else {
      throw RuntimeError.type(expr, expected: [Drawing.type])
    }
    return drawing
  }
  
  private func size(from size: Expr) throws -> CGSize {
    guard case .pair(.flonum(let w), .flonum(let h)) = size,
          w >= 10 && w <= 100000,
          h >= 10 && h <= 100000 else {
      throw RuntimeError.eval(.invalidSize, size)
    }
    return CGSize(width: w, height: h)
  }
  
  private func makeCanvas(expr: Expr, sze: Expr, name: Expr?, background: Expr?) throws -> Expr {
    let drawing = try self.drawing(from: expr)
    let size = try self.size(from: sze)
    let title = try name?.asString()
    let color: UIColor?
    if let background {
      guard case .object(let obj) = background, let col = obj as? LispKit.Color else {
        throw RuntimeError.type(expr, expected: [Color.type])
      }
      color = col.nsColor
    } else {
      color = nil
    }
    if let title {
      guard title.count > 0 && title.count <= 100 else {
        throw RuntimeError.custom("error", "illegal length of canvas name", [name!])
      }
    }
    guard size.width >= 10 && size.width <= 50000 &&
          size.height >= 10 && size.height <= 50000 else {
      throw RuntimeError.custom("error", "illegal size of canvas", [sze])
    }
    let canvasConfig = CanvasConfig(name: title,
                                    size: size,
                                    scale: 1.0,
                                    background: color,
                                    drawing: drawing)
    DispatchQueue.main.sync {
      withAnimation {
        self.interpreter?.setActiveCanvas(to: canvasConfig)
      }
    }
    return .makeNumber(canvasConfig.id)
  }
  
  private func useCanvas(expr: Expr, sze: Expr, name: Expr?, background: Expr?) throws -> Expr {
    let drawing = try self.drawing(from: expr)
    let size = try self.size(from: sze)
    let title = try name?.asString()
    let color: UIColor?
    if let background {
      guard case .object(let obj) = background, let col = obj as? LispKit.Color else {
        throw RuntimeError.type(expr, expected: [Color.type])
      }
      color = col.nsColor
    } else {
      color = nil
    }
    if let title {
      guard title.count > 0 && title.count <= 100 else {
        throw RuntimeError.custom("error", "illegal length of canvas name", [name!])
      }
    }
    guard size.width >= 10 && size.width <= 50000 &&
          size.height >= 10 && size.height <= 50000 else {
      throw RuntimeError.custom("error", "illegal size of canvas", [sze])
    }
    var canvasConfig: CanvasConfig? = nil
    if let canvases = self.interpreter?.canvases {
      for canvas in canvases {
        if canvas.name == title {
          canvasConfig = canvas
          break
        }
      }
    }
    if let canvasConfig {
      DispatchQueue.main.sync {
        canvasConfig.drawing = drawing
        canvasConfig.size = size
        canvasConfig.background = color
        canvasConfig.scale = 1.0
        canvasConfig.zoom = 1.0
      }
    } else {
      canvasConfig = CanvasConfig(name: title,
                                  size: size,
                                  scale: 1.0,
                                  background: color,
                                  drawing: drawing)
      DispatchQueue.main.sync {
        withAnimation {
          self.interpreter?.setActiveCanvas(to: canvasConfig!)
        }
      }
    }
    return .makeNumber(canvasConfig!.id)
  }
  
  private func closeCanvas(expr: Expr) throws -> Expr {
    if let canvases = self.interpreter?.canvases {
      switch expr {
        case .fixnum(let num):
          for canvas in canvases {
            if canvas.id == num {
              DispatchQueue.main.async {
                self.interpreter?.removeCanvas(canvas)
              }
              return .true
            }
          }
        case .string(let mstr):
          let str = mstr as String
          for canvas in canvases {
            if canvas.name == str {
              DispatchQueue.main.async {
                self.interpreter?.removeCanvas(canvas)
              }
              return .true
            }
          }
        default:
          break
      }
    }
    return .false
  }
  
  private func canvas(from expr: Expr) throws -> CanvasConfig {
    if let canvases = self.interpreter?.canvases {
      switch expr {
        case .fixnum(let num):
          for canvas in canvases {
            if canvas.id == num {
              return canvas
            }
          }
        case .string(let mstr):
          let str = mstr as String
          for canvas in canvases {
            if canvas.name == str {
              return canvas
            }
          }
        default:
          throw RuntimeError.type(expr, expected: [.fixnumType, .strType])
      }
    }
    throw RuntimeError.custom("error", "unknown canvas", [expr])
  }
  
  private func canvasName(expr: Expr) throws -> Expr {
    let canvas = try self.canvas(from: expr)
    return .makeString(canvas.name)
  }
  
  private func setCanvasName(expr: Expr, name: Expr) throws -> Expr {
    let canvas = try self.canvas(from: expr)
    let str = try name.asString()
    if str.count > 0 && str.count <= 100 {
      DispatchQueue.main.async {
        canvas.name = str
      }
      return .void
    } else {
      throw RuntimeError.custom("error", "illegal length of canvas name", [name])
    }
  }
  
  private func canvasSize(expr: Expr) throws -> Expr {
    let canvas = try self.canvas(from: expr)
    return .pair(.flonum(Double(canvas.size.width)), .flonum(Double(canvas.size.height)))
  }
  
  private func setCanvasSize(expr: Expr, sze: Expr) throws -> Expr {
    let canvas = try self.canvas(from: expr)
    let size = try self.size(from: sze)
    if size.width >= 10 && size.width <= 50000 && size.height >= 10 && size.height <= 50000 {
      DispatchQueue.main.sync {
        canvas.size = size
      }
      return .void
    } else {
      throw RuntimeError.custom("error", "illegal size of canvas", [sze])
    }
  }
  
  private func canvasScale(expr: Expr) throws -> Expr {
    let canvas = try self.canvas(from: expr)
    return .makeNumber(canvas.scale)
  }
  
  private func setCanvasScale(expr: Expr, scle: Expr) throws -> Expr {
    let canvas = try self.canvas(from: expr)
    let scale = try scle.asDouble(coerce: true)
    if scale > 0.0 && scale <= 1000.0 {
      DispatchQueue.main.sync {
        canvas.scale = scale
      }
      return .void
    } else {
      throw RuntimeError.custom("error", "illegal canvas scale", [scle])
    }
  }
  
  private func canvasBackground(expr: Expr) throws -> Expr {
    let canvas = try self.canvas(from: expr)
    if let background = canvas.background {
      return .object(Color(background))
    } else {
      return .false
    }
  }
  
  private func setCanvasBackground(expr: Expr, background: Expr) throws -> Expr {
    let canvas = try self.canvas(from: expr)
    if background.isFalse {
      DispatchQueue.main.sync {
        canvas.background = nil
      }
    } else if case .object(let obj) = background, let color = obj as? LispKit.Color {
      DispatchQueue.main.sync {
        canvas.background = color.nsColor
      }
    } else {
      throw RuntimeError.type(expr, expected: [Color.type])
    }
    return .void
  }
  
  private func canvasDrawing(expr: Expr) throws -> Expr {
    let canvas = try self.canvas(from: expr)
    return .object(canvas.drawing)
  }
  
  private func setCanvasDrawing(expr: Expr, dr: Expr) throws -> Expr {
    let canvas = try self.canvas(from: expr)
    let drawing = try self.drawing(from: expr)
    DispatchQueue.main.sync {
      canvas.drawing = drawing
    }
    return .void
  }
  
  private func saveBitmapInLibrary(expr: Expr) throws -> Expr {
    guard case .object(let obj) = expr,
          let imageBox = obj as? NativeImage else {
      throw RuntimeError.type(expr, expected: [NativeImage.type])
    }
    let imageManager = ImageManager()
    try imageManager.writeImageToLibrary(imageBox.value)
    return .true
  }
  
  private func photoFilter(_ expr: Expr) throws -> PHPickerFilter {
    switch expr {
      case .symbol(let sym):
        switch sym {
          case self.bursts:
            return .bursts
          case self.cinematicVideos:
            return .cinematicVideos
          case self.depthEffectPhotos:
            return .depthEffectPhotos
          case self.images:
            return .images
          case self.livePhotos:
            return .livePhotos
          case self.panoramas:
            return .panoramas
          case self.screenRecordings:
            return .screenRecordings
          case self.screenshots:
            return .screenshots
          case self.slomoVideos:
            return .slomoVideos
          case self.timelapseVideos:
            return .timelapseVideos
          case self.videos:
            return .videos
          default:
            throw RuntimeError.custom("error", "not a valid photos filter", [expr])
        }
      case .pair(.symbol(self.not), .pair(let operand, .null)):
        return PHPickerFilter.not(try self.photoFilter(operand))
      case .pair(.symbol(self.and), var list):
        var filters: [PHPickerFilter] = []
        while case .pair(let head, let tail) = list {
          filters.append(try self.photoFilter(head))
          list = tail
        }
        guard case .null = list else {
          throw RuntimeError.custom("error", "not a valid 'and' photos filter", [expr])
        }
        return PHPickerFilter.all(of: filters)
      case .pair(.symbol(self.or), var list):
        var filters: [PHPickerFilter] = []
        while case .pair(let head, let tail) = list {
          filters.append(try self.photoFilter(head))
          list = tail
        }
        guard case .null = list else {
          throw RuntimeError.custom("error", "not a valid 'or' photos filter", [expr])
        }
        return PHPickerFilter.any(of: filters)
      default:
        throw RuntimeError.custom("error", "not a valid photos filter expression", [expr])
    }
  }
  
  private func loadFromLibrary(_ maxImages: Expr?,
                               _ filter: Expr?,
                               _ dataOnly: Bool) throws -> ImageManager {
    let n: Int = try maxImages?.asInt(above: 1, below: 1000) ?? 1
    let f: PHPickerFilter = filter == nil ? .images : try self.photoFilter(filter!)
    let imageManager = ImageManager()
    DispatchQueue.main.sync {
      self.interpreter?.showPhotosPicker = Interpreter.PhotosPickerConfig(
        maxSelectionCount: n,
        matching: f,
        dataOnly: dataOnly,
        imageManager: imageManager)
    }
    return imageManager
  }
  
  private func loadBitmapsFromLibrary(_ maxImages: Expr?, _ filter: Expr?) throws -> Expr {
    let imageManager = try self.loadFromLibrary(maxImages, filter, false)
    let images = try imageManager.loadImagesFromLibrary()
    var res: [Expr] = []
    for image in images {
      if let image {
        res.append(.object(NativeImage(image)))
      } else {
        res.append(.false)
      }
    }
    return .makeList(Arguments(res))
  }
  
  private func loadBytevectorsFromLibrary(_ maxImages: Expr?, _ filter: Expr?) throws -> Expr {
    let imageManager = try self.loadFromLibrary(maxImages, filter, true)
    let data = try imageManager.loadDataFromLibrary()
    var res: [Expr] = []
    for d in data {
      if let d {
        var a = [UInt8](repeating: 0, count: d.count)
        (d as NSData).getBytes(&a, length: data.count)
        res.append(.bytes(MutableBox(a)))
      } else {
        res.append(.false)
      }
    }
    return .makeList(Arguments(res))
  }
  
  private func projectDirectory() -> Expr {
    if let path = PortableURL.Base.documents.url?.absoluteURL.path {
      return .makeString(path)
    } else {
      return .false
    }
  }
  
  private func icloudDirectory() -> Expr {
    if let path = PortableURL.Base.icloud.url?.absoluteURL.path {
      return .makeString(path)
    } else {
      return .false
    }
  }
  
  private func screenSize(docid: Expr?) throws -> Expr {
    let screen = UIScreen.main.bounds
    return .pair(.flonum(Double(screen.width)), .flonum(Double(screen.height)))
  }
  
  private func isDarkMode() -> Expr {
    return .makeBoolean(UITraitCollection.current.userInterfaceStyle == .dark)
  }
  
  private func iCloudList(_ expr: Expr?) throws -> Expr {
    if let urls = FileObserver.default?.observedFiles(expr?.isTrue) {
      var res = Expr.null
      for url in urls {
        if let portableUrl = PortableURL(url) {
          res = .pair(.makeString(portableUrl.relativePath), res)
        }
      }
      return res
    } else {
      return .false
    }
  }
  
  private func sessionId() -> Expr {
    return .fixnum(Int64(bitPattern: UInt64(UInt(bitPattern: ObjectIdentifier(self.context)))))
  }
  
  private func sessionName() -> Expr {
    return .makeString(UIDevice.current.localizedModel + " " +
                      String(format: "%02x", UInt64(UInt(bitPattern: ObjectIdentifier(self.context)))))
  }
  
  private func sessionLog(tme: Expr, sev: Expr, message: Expr, tag: Expr?) throws -> Expr {
    let time: Double? = tme.isFalse ? nil : try tme.asDouble()
    let sym = try sev.asSymbol()
    let severity: Severity
    switch sym.identifier {
      case "debug":
        severity = .debug
      case "info":
        severity = .info
      case "warn":
        severity = .warning
      case "error":
        severity = .error
      case "fatal":
        severity = .fatal
      default:
        throw RuntimeError.custom("error", "invalid severity", [sev])
    }
    SessionLog.standard.addLogEntry(time: time,
                                    severity: severity,
                                    tag: try tag?.asString() ?? "",
                                    message: try message.asString())
    return .void
  }
}
