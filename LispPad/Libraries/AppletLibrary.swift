//
//  ShortcutLibrary.swift
//  LispPad
//
//  Created by Matthias Zenger on 22/03/2026.
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
import AppIntents
import LispKit
import UniformTypeIdentifiers
import PDFKit

///
/// This class implements the LispPad-specific library `(lisppad applet)`.
///
public final class AppletLibrary: NativeLibrary {
  
  /// If this is set, it overrides the arguments from the context.
  private var argumentOverride: AppletResult? = nil
  
  /// Name of the library.
  public override class var name: [String] {
    return ["lisppad", "applet"]
  }
  
  /// Initialization
  public required init(in context: Context) throws {
    try super.init(in: context)
  }
  
  /// Dependencies of the library.
  public override func dependencies() {
  }
  
  /// Declarations of the library.
  public override func declarations() {
    self.define(Procedure("running-as-applet?", self.isRunningAsApplet))
    self.define(Procedure("applet-string-arguments", self.appletStringArguments))
    self.define(Procedure("applet-file-arguments", self.appletFileArguments))
    self.define(Procedure("applet-arguments-override!", self.appletArgumentsOverride))
    self.define(Procedure("make-applet-result", self.makeAppletResult))
    self.define(Procedure("applet-result?", self.isAppletResult))
    self.define(Procedure("applet-result-append!", self.appletResultAppend))
    self.define(Procedure("applet-result-strings", self.appletResultStrings))
    self.define(Procedure("applet-result-string-append!", self.appletResultStringAppend))
    self.define(Procedure("applet-result-files", self.appletResultFiles))
    self.define(Procedure("applet-result-file-append!", self.appletResultFileAppend))
    self.define(Procedure("make-applet-file", self.makeAppletFile))
    self.define(Procedure("applet-file?", self.isAppletFile))
    self.define(Procedure("applet-file-transiet?", self.appletFileTransient))
    self.define(Procedure("applet-file-name", self.appletFileName))
    self.define(Procedure("applet-file-path", self.appletFilePath))
    self.define(Procedure("applet-file-type", self.appletFileType))
    self.define(Procedure("applet-file-data", self.appletFileData))
    self.define(Procedure("applet-file-available-types", self.appletFileAvailableTypes))
    self.define(Procedure("applet-file->object", self.appletFileToObject))
    self.define(Procedure("applet-confirmation-dialog", self.appletConfirmationDialog))
    self.define(Procedure("applet-read-dialog", self.appletReadDialog))
    self.define(Procedure("applet-choice-dialog", self.appletChoiceDialog))
  }
  
  public override func initializations() {
  }
  
  private func appletContext() throws -> IntentInterpreter.Context {
    guard let context = self.context as? IntentInterpreter.Context else {
      throw RuntimeError.custom("error", "program not running as an applet", [])
    }
    return context
  }
  
  private func appletResult(_ expr: Expr) throws -> AppletResult {
    guard case .object(let obj) = expr, let res = obj as? AppletResult else {
      throw RuntimeError.type(expr, expected: [AppletResult.type])
    }
    return res
  }
  
  private func appletFile(_ expr: Expr) throws -> AppletFile {
    guard case .object(let obj) = expr, let res = obj as? AppletFile else {
      throw RuntimeError.type(expr, expected: [AppletFile.type])
    }
    return res
  }
  
  private func isRunningAsApplet() -> Expr {
    guard self.context is IntentInterpreter.Context else {
      return .false
    }
    return .true
  }
  
  private func appletStringArguments(_ forceOrig: Expr?) throws -> Expr {
    if forceOrig?.isFalse ?? true, let argumentOverride {
      var res = Expr.null
      for str in argumentOverride.strings.reversed() {
        res = .pair(str == nil ? .false : .makeString(str!), res)
      }
      return res
    } else {
      let context = try self.appletContext()
      var res = Expr.null
      for str in context.strings.reversed() {
        res = .pair(str == nil ? .false : .makeString(str!), res)
      }
      return res
    }
  }
  
  private func appletFileArguments(_ forceOrig: Expr?) throws -> Expr {
    if forceOrig?.isFalse ?? true, let argumentOverride {
      var res = Expr.null
      for file in argumentOverride.files.reversed() {
        res = .pair(file == nil ? .false : .object(AppletFile(file!)), res)
      }
      return res
    } else {
      let context = try self.appletContext()
      var res = Expr.null
      for file in context.files.reversed() {
        res = .pair(file == nil ? .false : .object(AppletFile(file!)), res)
      }
      return res
    }
  }
  
  private func appletArgumentsOverride(_ expr: Expr) throws -> Expr {
    let currentOverride = self.argumentOverride
    if expr.isFalse {
      self.argumentOverride = nil
    } else {
      self.argumentOverride = try self.appletResult(expr)
    }
    if let currentOverride {
      return .object(currentOverride)
    } else {
      return .false
    }
  }
  
  private func makeAppletResult(_ expr: Expr?) -> Expr {
    if let expr {
      let res = AppletResult()
      res.include(expr)
      return .object(res)
    } else {
      return .object(AppletResult())
    }
  }
  
  private func isAppletResult(_ expr: Expr) -> Expr {
    guard case .object(let obj) = expr, obj is AppletResult else {
      return .false
    }
    return .true
  }
  
  private func appletResultStrings(_ expr: Expr) throws -> Expr {
    let result = try self.appletResult(expr)
    var res = Expr.null
    for str in result.strings.reversed() {
      res = .pair(str == nil ? .false : .makeString(str!), res)
    }
    return res
  }
  
  private func appletResultAppend(_ expr: Expr, _ obj: Expr) throws -> Expr {
    let result = try self.appletResult(expr)
    result.include(obj)
    return .void
  }
  
  private func appletResultStringAppend(_ expr: Expr, _ str: Expr) throws -> Expr {
    let result = try self.appletResult(expr)
    if str.isTrue {
      result.strings.append(try str.asString())
    } else {
      result.strings.append(nil)
    }
    return .makeNumber(result.strings.count - 1)
  }
  
  private func appletResultFiles(_ expr: Expr) throws -> Expr {
    let result = try self.appletResult(expr)
    var res = Expr.null
    for file in result.files.reversed() {
      res = .pair(file == nil ? .false : .object(AppletFile(file!)), res)
    }
    return res
  }
  
  private func appletResultFileAppend(_ expr: Expr, _ f: Expr) throws -> Expr {
    let result = try self.appletResult(expr)
    if f.isTrue {
      result.files.append(try self.appletFile(f).file)
    } else {
      result.files.append(nil)
    }
    return .makeNumber(result.files.count - 1)
  }
  
  private func makeAppletFile(_ expr: Expr, _ name: Expr?, _ type: Expr?) throws -> Expr {
    if case .string(_) = expr {
      let url = URL(fileURLWithPath:
        self.context.fileHandler.path(try expr.asPath(),
                                      relativeTo: self.context.evaluator.currentDirectoryPath))
      if let name, name.isTrue {
        if let type, type.isTrue {
          if let tp = try UTType(type.asString()) {
            return .object(AppletFile(IntentFile(fileURL: url,
                                                 filename: try name.asString(),
                                                 type: tp)))
          } else {
            return .false
          }
        } else {
          return .object(AppletFile(IntentFile(fileURL: url, filename: try name.asString())))
        }
      } else {
        if let type, type.isTrue {
          if let tp = try UTType(type.asString()) {
            return .object(AppletFile(IntentFile(fileURL: url, filename: nil, type: tp)))
          } else {
            return .false
          }
        } else {
          return .object(AppletFile(IntentFile(fileURL: url)))
        }
      }
    } else if let name {
      if case .bytes(_) = expr {
        let data = Data(try expr.asByteVector().value)
        if let type, type.isTrue {
          if let tp = try UTType(type.asString()) {
            return .object(AppletFile(IntentFile(data: data, filename: try name.asString(), type: tp)))
          } else {
            return .false
          }
        } else {
          return .object(AppletFile(IntentFile(data: data, filename: try name.asString())))
        }
      } else if let ifile = AppletResult.toIntentFile(expr, filename: try name.asString()) {
        return .object(AppletFile(ifile))
      } else {
        return .false
      }
    } else {
      return .false
    }
  }
  
  private func isAppletFile(_ expr: Expr) throws -> Expr {
    guard case .object(let obj) = expr, obj is AppletFile else {
      return .false
    }
    return .true
  }
  
  private func appletFileTransient(_ expr: Expr) throws -> Expr {
    return .makeBoolean(try self.appletFile(expr).file.removedOnCompletion)
  }
  
  private func appletFileName(_ expr: Expr) throws -> Expr {
    return .makeString(try self.appletFile(expr).file.filename)
  }
  
  private func appletFilePath(_ expr: Expr, _ percentEncoded: Expr?) throws -> Expr {
    if let url = try self.appletFile(expr).file.fileURL {
      if let percentEncoded {
        return .makeString(url.path(percentEncoded: percentEncoded.isTrue))
      } else {
        return .makeString(url.path())
      }
    } else {
      return .false
    }
  }
  
  private func appletFileType(_ expr: Expr) throws -> Expr {
    let af = try self.appletFile(expr)
    if let type = af.file.type {
      return .makeString(type.identifier)
    } else {
      return .false
    }
  }
  
  private func getData(from ifile: IntentFile, type: UTType?) throws -> Data? {
    if let type {
      if #available(iOS 18.0, *) {
        let responseSemaphore = DispatchSemaphore(value: 0)
        var data: Data? = nil
        var done: Bool = false
        Task {
          do {
            data = try await ifile.data(contentType: type)
            done = true
          } catch {
            done = true
          }
          responseSemaphore.signal()
        }
        while !done && !self.context.evaluator.isAbortionRequested() {
          _ = responseSemaphore.wait(timeout: .now() + 0.5)
        }
        return data
      } else {
        return ifile.data
      }
    } else {
      return ifile.data
    }
  }
  
  private func appletFileData(_ expr: Expr, _ type: Expr?) throws -> Expr {
    let af = try self.appletFile(expr)
    let tp = type == nil ? nil : try UTType(type!.asString())    
    if let data = try self.getData(from: af.file, type: tp) {
      var res = [UInt8](repeating: 0, count: data.count)
      data.copyBytes(to: &res, count: data.count)
      return .bytes(MutableBox(res))
    } else {
      return .false
    }
  }
  
  private func appletFileAvailableTypes(_ expr: Expr) throws -> Expr {
    if #available(iOS 18.0, *) {
      let types = try self.appletFile(expr).file.availableContentTypes
      var res = Expr.null
      for tpe in types {
        res = .pair(.makeString(tpe.identifier), res)
      }
      return res
    } else {
      return .false
    }
  }
  
  private func appletFileToObject(_ expr: Expr, _ type: Expr?) throws -> Expr {
    let af = try self.appletFile(expr)
    let tp = try (type == nil ? nil : UTType(type!.asString())) ?? af.file.type
    if let data = try self.getData(from: af.file, type: tp) {
      switch tp {
        case .plainText, .utf8PlainText, .text, .delimitedText,
             .tabSeparatedText, .commaSeparatedText, .utf8TabSeparatedText:
          if let tr = String(data: data, encoding: .utf8) {
            return .makeString(tr)
          } else {
            return .false
          }
        case .utf16PlainText, .utf16ExternalPlainText:
          if let tr = String(data: data, encoding: .utf16) {
            return .makeString(tr)
          } else {
            return .false
          }
        case .gif, .bmp, .png, .jpeg, .tiff:
          if let image = UIImage(data: data) {
            return .object(NativeImage(image))
          } else {
            return .false
          }
        case .pdf:
          if let pdf = PDFDocument(data: data) {
            return .object(NativePDFDocument(document: pdf))
          } else {
            return .false
          }
        case .zip:
          if let archive = ZipArchive(data) {
            return .object(archive)
          } else {
            return .false
          }
        case .rtf:
          do {
            let text = try NSMutableAttributedString(
                              data: data,
                              options: [.documentType: NSAttributedString.DocumentType.rtf],
                              documentAttributes: nil)
            return .object(StyledText(text))
          } catch {
            return .false
          }
        case .rtfd, .flatRTFD:
          do {
            let text = try NSMutableAttributedString(
                              data: data,
                              options: [.documentType: NSAttributedString.DocumentType.rtfd],
                              documentAttributes: nil)
            return .object(StyledText(text))
          } catch {
            return .false
          }
        default:
          if #available(iOS 18.0, *), tp == .tarArchive {
            if let archive = TarArchive(url: af.file.fileURL, data: data) {
              return .object(archive)
            } else {
              return .false
            }
          } else if let tar = UTType("public.tar-archive"), tp == tar {
            if let archive = TarArchive(url: af.file.fileURL, data: data) {
              return .object(archive)
            } else {
              return .false
            }
          } else {
            return .false
          }
      }
    } else {
      return .false
    }
  }
  
  private func appletConfirmationDialog(_ prompt: Expr, _ modern: Expr?) throws -> Expr {
    let prompt = try prompt.asString()
    let classic = (modern ?? .true).isFalse
    let responseSemaphore = DispatchSemaphore(value: 0)
    var res: Bool = false
    var done: Bool = false
    if let context = self.context as? IntentInterpreter.Context {
      Task {
        res = await context.confirmationDialog(prompt, classic)
        done = true
        responseSemaphore.signal()
      }
      while !done && !self.context.evaluator.isAbortionRequested() {
        _ = responseSemaphore.wait(timeout: .now() + 0.5)
      }
    } else if let interpreter = self.context.delegate as? Interpreter {
      let title: String
      if case .string(let str) = modern {
        title = str as String
      } else {
        title = "Confirm"
      }
      DispatchQueue.main.async {
        if interpreter.alertConfig == nil {
          interpreter.alertConfig = .choice(.init(
            title: title,
            message: prompt,
            options: [],
            onCancel: {
              res = false
              done = true
              responseSemaphore.signal()
            },
            onConfirm: { str in
              res = true
              done = true
              responseSemaphore.signal()
            }))
        } else {
          done = true
          responseSemaphore.signal()
        }
      }
      while !done && !self.context.evaluator.isAbortionRequested() {
        _ = responseSemaphore.wait(timeout: .now() + 0.5)
      }
    } else {
      throw RuntimeError.custom("error", "program not running as an applet", [])
    }
    return .makeBoolean(res)
  }
  
  private func appletChoiceDialog(_ prompt: Expr, _ options: Expr, _ modern: Expr?) throws -> Expr {
    let prompt = try prompt.asString()
    let classic = (modern ?? .true).isFalse
    var lst = options
    let responseSemaphore = DispatchSemaphore(value: 0)
    var res: Int? = nil
    var done = false
    if let context = self.context as? IntentInterpreter.Context {
      var alternatives: [EvalIntent.ChoiceItem] = []
      while case .pair(let opt, let rest) = lst {
        if case .pair(let str, let style) = opt {
          if case .null = style {
            alternatives.append(.init(title: try str.asString(), style: .plain))
          } else if style.isTrue {
            alternatives.append(.init(title: try str.asString(), style: .destructive))
          } else {
            alternatives.append(.init(title: try str.asString(), style: .cancel))
          }
        } else {
          alternatives.append(.init(title: try opt.asString(), style: .plain))
        }
        lst = rest
      }
      Task {
        res = await context.choiceDialog(prompt, alternatives, classic)
        done = true
        responseSemaphore.signal()
      }
      while !done && !self.context.evaluator.isAbortionRequested() {
        _ = responseSemaphore.wait(timeout: .now() + 0.5)
      }
    } else if let interpreter = self.context.delegate as? Interpreter {
      let title: String
      if case .string(let str) = modern {
        title = str as String
      } else {
        title = "Choose"
      }
      var alternatives: [String] = []
      while case .pair(let opt, let rest) = lst {
        if case .pair(let str, _) = opt {
          alternatives.append(try str.asString())
        } else {
          alternatives.append(try opt.asString())
        }
        lst = rest
      }
      var choice: String? = nil
      DispatchQueue.main.async {
        if interpreter.alertConfig == nil {
          interpreter.alertConfig = .choice(.init(
            title: title,
            message: prompt,
            options: alternatives,
            onCancel: {
              choice = nil
              done = true
              responseSemaphore.signal()
            },
            onConfirm: {
              choice = $0
              done = true
              responseSemaphore.signal()
            }))
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
    } else {
      throw RuntimeError.custom("error", "program not running as an applet", [])
    }
    return res == nil ? .false : .makeNumber(res!)
  }
  
  private func appletReadDialog(_ prompt: Expr, _ title: Expr?) throws -> Expr {
    let prompt = try prompt.asString()
    let title = try title?.asString() ?? "Input"
    let responseSemaphore = DispatchSemaphore(value: 0)
    var res: String? = nil
    var done: Bool = false
    if let context = self.context as? IntentInterpreter.Context {
      Task {
        res = await context.readDialog(prompt)
        done = true
        responseSemaphore.signal()
      }
      while !done && !self.context.evaluator.isAbortionRequested() {
        _ = responseSemaphore.wait(timeout: .now() + 0.5)
      }
    } else if let interpreter = self.context.delegate as? Interpreter {
      DispatchQueue.main.async {
        if interpreter.alertConfig == nil {
          interpreter.alertConfig = .textInput(.init(
            title: title,
            message: prompt,
            initial: "",
            onCancel: {
              res = nil
              done = true
              responseSemaphore.signal()
            },
            onConfirm: {
              res = $0
              done = true
              responseSemaphore.signal()
            }))
        } else {
          done = true
          responseSemaphore.signal()
        }
      }
      while !done && !self.context.evaluator.isAbortionRequested() {
        _ = responseSemaphore.wait(timeout: .now() + 0.5)
      }
    } else {
      throw RuntimeError.custom("error", "program not running as an applet", [])
    }
    return res == nil ? .false : .makeString(res!)
  }
}

/// Implementation of applet result objects
class AppletResult: NativeObject {
  
  /// Type representing fonts
  public static let type = Type.objectType(Symbol(uninterned: "applet-result"))
  
  var strings: [String?] = []
  var files: [IntentFile?] = []
  
  public static func toIntentFile(_ expr: Expr, filename: String) -> IntentFile? {
    switch expr {
      case .string(let str):
        if let data = (str as String).data(using: .utf8) {
          return IntentFile(data: data, filename: filename, type: .utf8PlainText)
        } else {
          return nil
        }
      case .object(let obj):
        if let img = obj as? NativeImage,
           let data = BitmapImageFileType.png.data(for: img.value, qualityFactor: nil) {
          return IntentFile(data: data, filename: filename, type: .png)
        } else if let ndoc = obj as? NativePDFDocument,
                  let doc = ndoc.document as? LispKitPDFDocument,
                  let data = (doc.persistDrawings() ?? doc).dataRepresentation(options: [:]) {
          return IntentFile(data: data, filename: filename, type: .pdf)
        } else if let text = obj as? StyledText {
          do {
            let data = try text.value.data(from: NSRange(location: 0, length: text.value.length),
                                           documentAttributes: [
                                             .documentType: NSAttributedString.DocumentType.rtf
                                           ])
            return IntentFile(data: data, filename: filename, type: .rtf)
          } catch {
            return nil
          }
        } else if let archive = obj as? ZipArchive,
                  let data = archive.archive.data {
          return IntentFile(data: data, filename: filename, type: .zip)
        } else if let archive = obj as? TarArchive {
          if #available(iOS 18.0, *) {
            return IntentFile(data: archive.data, filename: filename, type: .tarArchive)
          } else if let tp = UTType("public.tar-archive") {
            return IntentFile(data: archive.data, filename: filename, type: tp)
          } else {
            return nil
          }
        } else {
          return nil
        }
      default:
        return nil
    }
  }
  
  public func include(_ expr: Expr, nested: Bool = false) {
    switch expr {
      case .void:
        break
      case .string(let str):
        if nested {
          self.strings.append(expr.description)
        } else {
          self.strings.append(str as String)
        }
      case .values(let expr):
        var next = expr
        while case .pair(let x, let rest) = next {
          self.include(x, nested: true)
          next = rest
        }
      case .bytes(let bvector):
        self.files.append(IntentFile(data: Data(bvector.value), filename: "Output"))
      case .object(let obj):
        if let result = obj as? AppletResult {
          self.strings.append(contentsOf: result.strings)
          self.files.append(contentsOf: result.files)
        } else if let img = obj as? NativeImage,
                  let data = BitmapImageFileType.png.data(for: img.value, qualityFactor: nil) {
          self.files.append(IntentFile(data: data, filename: "Output.png", type: .png))
        } else if let ndoc = obj as? NativePDFDocument,
                  let doc = ndoc.document as? LispKitPDFDocument,
                  let data = (doc.persistDrawings() ?? doc).dataRepresentation(options: [:]) {
          self.files.append(IntentFile(data: data, filename: "Output.pdf", type: .pdf))
        } else if let text = obj as? StyledText {
          do {
            let data = try text.value.data(from: NSRange(location: 0, length: text.value.length),
                                           documentAttributes: [
                                             .documentType: NSAttributedString.DocumentType.rtf
                                           ])
            self.files.append(IntentFile(data: data, filename: "Output.rtf", type: .rtf))
          } catch {
            fallthrough
          }
        } else if let archive = obj as? ZipArchive,
                  let data = archive.archive.data {
          self.files.append(IntentFile(data: data, filename: "Output.zip", type: .zip))
        } else if let archive = obj as? TarArchive {
          if #available(iOS 18.0, *) {
            self.files.append(IntentFile(data: archive.data,
                                         filename: "Output.tar",
                                         type: .tarArchive))
          } else if let tp = UTType("public.tar-archive") {
            self.files.append(IntentFile(data: archive.data,
                                         filename: "Output.tar",
                                         type: tp))
          } else {
            fallthrough
          }
        } else {
          fallthrough
        }
      default:
        self.strings.append(expr.description)
    }
  }
  
  public override var type: Type {
    return Self.type
  }
  
  public override var string: String {
    return "#<\(self.tagString)>"
  }
  
  public override var tagString: String {
    return "\(Self.type) \(self.identityString): \(self.strings.count) strings, " +
           "\(self.files.count) files"
  }
  
  public override func unpack(in context: Context) -> Exprs {
    return [.makeString(self.identityString),
            .makeNumber(self.strings.count),
            .makeNumber(self.files.count)]
  }
}

/// Implementation of applet files
class AppletFile: NativeObject {
  
  /// Type representing fonts
  public static let type = Type.objectType(Symbol(uninterned: "applet-file"))
  
  let file: IntentFile
  
  init(_ file: IntentFile) {
    self.file = file
  }
  
  public override var type: Type {
    return Self.type
  }
  
  public override var string: String {
    return "#<\(self.tagString)>"
  }
  
  public override var tagString: String {
    var res = "\(Self.type) \(self.identityString): \"\(self.file.filename)\""
    if let type = self.file.type {
      res += " \(type.identifier)"
    }
    return res
  }
  
  public override func unpack(in context: Context) -> Exprs {
    let tp: Expr
    if let type = self.file.type {
      tp = .makeString(type.identifier)
    } else {
      tp = .false
    }
    return [.makeString(self.identityString),
            .makeString(self.file.filename),
            tp]
  }
}
