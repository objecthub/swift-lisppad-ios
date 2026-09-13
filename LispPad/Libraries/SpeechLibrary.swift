//
//  SpeechLibrary.swift
//  LispPad
//
//  Created by Matthias Zenger on 13/09/2026.
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
import AVFoundation
import LispKit

///
/// This class implements the LispPad-specific library `(lisppad speech)`.
///
public final class SpeechLibrary: NativeLibrary {
  
  /// Name of the library.
  public override class var name: [String] {
    return ["lisppad", "speech"]
  }
  
  private var currentSpeaker: Speaker?
  private let condition: NSCondition
  private let speakerParam: Procedure
  
  /// Initialization
  public required init(in context: Context) throws {
    self.currentSpeaker = nil
    self.condition = NSCondition()
    if let speaker = Speaker() {
      self.speakerParam = Procedure(.null, .object(speaker))
    } else {
      self.speakerParam = Procedure(.null, .false)
    }
    try super.init(in: context)
  }

  /// Dependencies of the library.
  public override func dependencies() {
  }
  
  /// Declarations of the library.
  public override func declarations() {
    self.define("current-speaker", as: self.speakerParam)
    self.define(Procedure("available-voices", availableVoices))
    self.define(Procedure("voice", voice))
    self.define(Procedure("available-voice?", availableVoice))
    self.define(Procedure("voice-name", voiceName))
    self.define(Procedure("voice-age", voiceAge))
    self.define(Procedure("voice-gender", voiceGender))
    self.define(Procedure("voice-locale", voiceLocale))
    self.define(Procedure("make-speaker", makeSpeaker))
    self.define(Procedure("speaker?", isSpeaker))
    self.define(Procedure("speaker-voice", speakerVoice))
    self.define(Procedure("speaker-rate", speakerRate))
    self.define(Procedure("speaker-volume", speakerVolume))
    self.define(Procedure("speaker-interpret-phonemes", speakerInterpretPhonemes))
    self.define(Procedure("speaker-interpret-numbers", speakerInterpretNumbers))
    self.define(Procedure("speaker-pitch", speakerPitch))
    self.define(Procedure("set-speaker-rate!", setSpeakerRate))
    self.define(Procedure("set-speaker-volume!", setSpeakerVolume))
    self.define(Procedure("set-speaker-interpret-phonemes!", setSpeakerInterpretPhonemes))
    self.define(Procedure("set-speaker-interpret-numbers!", setSpeakerInterpretNumbers))
    self.define(Procedure("set-speaker-pitch!", setSpeakerPitch))
    self.define(Procedure("speak", speak))
    self.define(Procedure("phonemes", phonemes))
  }
  
  public override func initializations() {
  }
  
  private func availableVoices(lang: Expr?, gender: Expr?) throws -> Expr {
    var res = Exprs()
    let allVoices = AVSpeechSynthesisVoice.speechVoices()
    
    guard let langFilter = lang else {
      for voice in allVoices {
        res.append(.symbol(self.context.symbols.intern(voice.identifier)))
      }
      return .makeList(res)
    }
    
    let localeFilter: Locale? = langFilter.isFalse
                                  ? nil : Locale(identifier: try langFilter.asSymbol().identifier)
    var genderFilter: AVSpeechSynthesisVoiceGender? = nil
    if let gender = gender {
      switch try gender.asSymbol().identifier {
        case "male":
          genderFilter = .male
        case "female":
          genderFilter = .female
        default:
          return .null
      }
    }
    
    for voice in allVoices {
      let locale = Locale(identifier: voice.language)
      let matchesLocale = localeFilter == nil ||
          ((localeFilter!.language.languageCode?.identifier == nil ||
            localeFilter!.language.languageCode?.identifier == locale.language.languageCode?.identifier) &&
           (localeFilter!.region?.identifier == nil ||
            localeFilter!.region?.identifier == locale.region?.identifier))
      let matchesGender = genderFilter == nil || voice.gender == genderFilter!
      
      if matchesLocale && matchesGender {
        res.append(.symbol(self.context.symbols.intern(voice.identifier)))
      }
    }
    return .makeList(res)
  }
  
  private func voice(expr: Expr?) -> Expr {
    if let voice = expr {
      switch voice {
        case .string(let str):
          let nameFilter = str.lowercased.trimmingCharacters(in: .whitespaces)
          for voice in AVSpeechSynthesisVoice.speechVoices() {
            if voice.name.lowercased() == nameFilter {
              return .symbol(self.context.symbols.intern(voice.identifier))
            }
          }
          return .false
        case .symbol(let sym):
          let idFilter = sym.identifier
          if let _ = AVSpeechSynthesisVoice(identifier: idFilter) {
            return .symbol(self.context.symbols.intern(idFilter))
          }
          return .false
        default:
          return .false
      }
    } else {
      // Return the default voice for the current locale
      if let defaultVoice = AVSpeechSynthesisVoice(language: Locale.current.identifier) {
        return .symbol(self.context.symbols.intern(defaultVoice.identifier))
      } else if let fallbackVoice = AVSpeechSynthesisVoice.speechVoices().first {
        return .symbol(self.context.symbols.intern(fallbackVoice.identifier))
      }
      return .false
    }
  }
  
  private func availableVoice(voice: Expr) throws -> Expr {
    if voice.isFalse {
      return .false
    }
    let idFilter = try voice.asSymbol().identifier
    return AVSpeechSynthesisVoice(identifier: idFilter) != nil ? .true : .false
  }
  
  private func voiceName(voice: Expr) throws -> Expr {
    if voice.isFalse {
      return .false
    }
    guard let avVoice = AVSpeechSynthesisVoice(identifier: try voice.asSymbol().identifier) else {
      return .false
    }
    return .makeString(avVoice.name)
  }
  
  private func voiceAge(voice: Expr) throws -> Expr {
    if voice.isFalse {
      return .false
    }
    // AVSpeechSynthesisVoice doesn't provide age information
    // Return a default or false to indicate unavailable
    return .false
  }
  
  private func voiceGender(voice: Expr) throws -> Expr {
    if voice.isFalse {
      return .false
    }
    guard let avVoice = AVSpeechSynthesisVoice(identifier: try voice.asSymbol().identifier) else {
      return .false
    }
    switch avVoice.gender {
      case .male:
        return .symbol(self.context.symbols.intern("male"))
      case .female:
        return .symbol(self.context.symbols.intern("female"))
      case .unspecified:
        return .false
      @unknown default:
        return .false
    }
  }
  
  private func voiceLocale(voice: Expr) throws -> Expr {
    if voice.isFalse {
      return .false
    }
    guard let avVoice = AVSpeechSynthesisVoice(identifier: try voice.asSymbol().identifier) else {
      return .false
    }
    return .symbol(self.context.symbols.intern(avVoice.language))
  }
  
  private func makeSpeaker(v: Expr?) throws -> Expr {
    let voice: AVSpeechSynthesisVoice?
    if let v = v, !v.isFalse {
      voice = AVSpeechSynthesisVoice(identifier: try v.asSymbol().identifier)
      guard voice != nil else {
        throw RuntimeError.custom("error", "cannot create speaker for voice \(v)", [])
      }
    } else {
      voice = nil
    }
    
    if let speaker = Speaker(voice: voice) {
      return .object(speaker)
    } else if let expr = v, !expr.isFalse {
      throw RuntimeError.custom("error", "cannot create speaker for voice \(expr)", [])
    } else {
      throw RuntimeError.custom("error", "cannot create speaker for default voice", [])
    }
  }
  
  private func isSpeaker(expr: Expr) throws -> Expr {
    guard case .object(let obj) = expr, obj is Speaker else {
      return .false
    }
    return .true
  }
  
  private func asSpeaker(_ expr: Expr?) throws -> Speaker {
    var expr = expr
    if expr == nil {
      guard let value = self.context.evaluator.getParam(self.speakerParam) else {
        throw RuntimeError.custom("error", "cannot access current speaker object", [])
      }
      expr = value
    }
    guard case .object(let obj) = expr!,
          let speaker = obj as? Speaker else {
      throw RuntimeError.type(expr!, expected: [Speaker.type])
    }
    return speaker
  }
  
  private func speakerVoice(speaker: Expr?) throws -> Expr {
    guard let voice = try self.asSpeaker(speaker).voice else {
      return .false
    }
    return .symbol(self.context.symbols.intern(voice.identifier))
  }
  
  private func speakerRate(speaker: Expr?) throws -> Expr {
    return .flonum(Double(try self.asSpeaker(speaker).rate))
  }
  
  private func speakerVolume(speaker: Expr?) throws -> Expr {
    return .flonum(Double(try self.asSpeaker(speaker).volume))
  }
  
  private func speakerInterpretPhonemes(speaker: Expr?) throws -> Expr {
    // AVSpeechSynthesizer handles phoneme interpretation differently via IPA notation in utterances
    // This functionality is not directly available as a mode setting
    return .false
  }
  
  private func speakerInterpretNumbers(speaker: Expr?) throws -> Expr {
    // AVSpeechSynthesizer doesn't have a direct equivalent to number mode
    return .true
  }
  
  private func speakerPitch(speaker: Expr?) throws -> Expr {
    let spkr = try self.asSpeaker(speaker)
    return .pair(.flonum(Double(spkr.pitchMultiplier)), .flonum(0.0))
  }
  
  private func setSpeakerRate(rate: Expr, speaker: Expr?) throws -> Expr {
    try self.asSpeaker(speaker).rate = Float(try rate.asDouble(coerce: true))
    return .void
  }
  
  private func setSpeakerVolume(volume: Expr, speaker: Expr?) throws -> Expr {
    try self.asSpeaker(speaker).volume = Float(try volume.asDouble(coerce: true))
    return .void
  }
  
  private func setSpeakerInterpretPhonemes(phoneme: Expr, speaker: Expr?) throws -> Expr {
    // AVSpeechSynthesizer doesn't have a direct mode for phoneme interpretation
    // Phonemes are handled via IPA notation in the utterance text itself
    return .void
  }
  
  private func setSpeakerInterpretNumbers(numbers: Expr, speaker: Expr?) throws -> Expr {
    // AVSpeechSynthesizer doesn't have a direct equivalent to number mode
    return .void
  }
  
  private func setSpeakerPitch(base: Expr, mod: Expr?, sp: Expr?) throws -> Expr {
    let speaker = try self.asSpeaker(sp)
    speaker.pitchMultiplier = Float(try base.asDouble(coerce: true))
    // AVSpeechSynthesizer doesn't support pitch modulation separately
    return .void
  }
  
  private func speak(text: Expr, sp: Expr?) throws -> Expr {
    let speaker = try self.asSpeaker(sp)
    self.condition.lock()
    while self.currentSpeaker != nil {
      self.condition.wait()
    }
    self.currentSpeaker = speaker
    self.condition.unlock()
    let res = speaker.speak(text: try text.asString())
    self.condition.lock()
    self.currentSpeaker = nil
    self.condition.unlock()
    return res ? .false : .true
  }
  
  private func phonemes(text: Expr, sp: Expr?) throws -> Expr {
    // AVSpeechSynthesizer doesn't provide a phonemes conversion method like NSSpeechSynthesizer
    // Return the original text as a fallback
    return .makeString(try text.asString())
  }
  
  public func abortSpeaking() {
    self.currentSpeaker?.abortSpeaking()
  }
}

/// Implementation of speaker objects
class Speaker: NativeObject {
  
  /// Type representing fonts
  public static let type = Type.objectType(Symbol(uninterned: "speaker"))

  let synth: AVSpeechSynthesizer
  let tracker: Tracker
  let voice: AVSpeechSynthesisVoice?
  var rate: Float = AVSpeechUtteranceDefaultSpeechRate
  var volume: Float = 1.0
  var pitchMultiplier: Float = 1.0
  
  class Tracker: NSObject, AVSpeechSynthesizerDelegate {
    var speaking: Bool
    var failure: Bool
    let condition: NSCondition

    override init() {
      self.speaking = false
      self.failure = false
      self.condition = NSCondition()
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, 
                           didCancel utterance: AVSpeechUtterance) {
      self.speakingCompleted(successful: false)
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, 
                           didFinish utterance: AVSpeechUtterance) {
      self.speakingCompleted(successful: true)
    }
    
    func speakingCompleted(successful: Bool) {
      self.condition.lock()
      self.speaking = false
      if !successful {
        self.failure = true
      }
      self.condition.signal()
      self.condition.unlock()
    }
  }

  init?(voice: AVSpeechSynthesisVoice? = nil) {
    self.synth = AVSpeechSynthesizer()
    self.tracker = Tracker()
    self.voice = voice
    super.init()
    self.synth.delegate = self.tracker
  }
  
  public override var type: Type {
    return Speaker.type
  }
  
  func speak(text: String) -> Bool {
    self.tracker.condition.lock()
    while self.tracker.speaking {
      self.tracker.condition.wait()
    }
    self.tracker.speaking = true
    self.tracker.failure = false
    
    let utterance = AVSpeechUtterance(string: text)
    if let voice = self.voice {
      utterance.voice = voice
    }
    utterance.rate = self.rate
    utterance.volume = self.volume
    utterance.pitchMultiplier = self.pitchMultiplier
    
    self.synth.speak(utterance)
    while self.tracker.speaking {
      self.tracker.condition.wait()
    }
    let failed = self.tracker.failure
    self.tracker.condition.unlock()
    return failed
  }

  func speakAsync(text: String) {
    self.tracker.condition.lock()
    while self.tracker.speaking {
      self.tracker.condition.wait()
    }
    self.tracker.speaking = true
    
    let utterance = AVSpeechUtterance(string: text)
    if let voice = self.voice {
      utterance.voice = voice
    }
    utterance.rate = self.rate
    utterance.volume = self.volume
    utterance.pitchMultiplier = self.pitchMultiplier
    
    self.synth.speak(utterance)
    self.tracker.condition.unlock()
  }
  
  func abortSpeaking() {
    self.tracker.condition.lock()
    self.synth.stopSpeaking(at: .immediate)
    self.tracker.speaking = false
    self.tracker.failure = true
    self.tracker.condition.signal()
    self.tracker.condition.unlock()
  }
  
  var isSpeaking: Bool {
    return self.tracker.speaking
  }
}
