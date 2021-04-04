//
//  AudioLibrary.swift
//  LispPad
//
//  Created by Matthias Zenger on 21/03/2021.
//  Copyright © 2021 Matthias Zenger. All rights reserved.
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
/// This class implements the LispPad-specific library `(lisppad audio)`.
///
public final class AudioLibrary: NativeLibrary {
  
  /// Name of the library.
  public override class var name: [String] {
    return ["lisppad", "audio"]
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
    self.define(Procedure("make-audio-player", self.makeAudioPlayer))
    self.define(Procedure("audio-player?", self.isAudioPlayer))
    self.define(Procedure("audio-player-playing?", self.isAudioPlayerPlaying))
    self.define(Procedure("audio-player-success?", self.isAudioPlayerSuccess))
    self.define(Procedure("audio-player-decode-error", self.isAudioPlayerDecodeError))
    self.define(Procedure("audio-player-duration", self.audioPlayerDuration))
    self.define(Procedure("audio-player-elapsed", self.audioPlayerElapsed))
    self.define(Procedure("set-audio-player-elapsed!", self.setAudioPlayerElapsed))
    self.define(Procedure("audio-player-volume", self.audioPlayerVolume))
    self.define(Procedure("set-audio-player-volume!", self.setAudioPlayerVolume))
    self.define(Procedure("audio-player-pan", self.audioPlayerPan))
    self.define(Procedure("set-audio-player-pan!", self.setAudioPlayerPan))
    self.define(Procedure("audio-player-rate", self.audioPlayerRate))
    self.define(Procedure("set-audio-player-rate!", self.setAudioPlayerRate))
    self.define(Procedure("audio-player-loops", self.audioPlayerLoops))
    self.define(Procedure("set-audio-player-loops!", self.setAudioPlayerLoops))
    self.define(Procedure("play-audio", self.playAudio))
    self.define(Procedure("pause-audio", self.pauseAudio))
    self.define(Procedure("stop-audio", self.stopAudio))
  }
  
  public override func initializations() {
  }
  
  private func audioPlayer(_ expr: Expr) throws -> AudioPlayer {
    guard case .object(let obj) = expr, let player = obj as? AudioPlayer else {
      throw RuntimeError.type(expr, expected: [AudioPlayer.type])
    }
    return player
  }
  
  private func makeAudioPlayer(_ source: Expr, _ fileType: Expr?, _ rate: Expr?) throws -> Expr {
    let player: AVAudioPlayer
    let ftype = (fileType?.isFalse ?? true) ? nil : fileType!
    switch source {
      case .string(_):
        let path = try source.asPath()
        player = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path, isDirectory: false),
                                   fileTypeHint: ftype?.asString())
      case .bytes(let bvec):
        player = try AVAudioPlayer(data: Data(bvec.value), fileTypeHint: ftype?.asString())
      default:
        throw RuntimeError.type(source, expected: [.strType, .byteVectorType])
    }
    if rate?.isTrue ?? false {
      player.enableRate = true
    }
    _ = player.prepareToPlay()
    return .object(AudioPlayer(player))
  }
  
  private func isAudioPlayer(_ expr: Expr) -> Expr {
    guard case .object(let obj) = expr, obj is AudioPlayer else {
      return .false
    }
    return .true
  }
  
  private func isAudioPlayerPlaying(_ expr: Expr) throws -> Expr {
    return .makeBoolean(try self.audioPlayer(expr).player.isPlaying)
  }
  
  private func isAudioPlayerSuccess(_ expr: Expr) throws -> Expr {
    if let success = try self.audioPlayer(expr).tracker.success {
      return .makeBoolean(success)
    }
    return .null
  }
  
  private func isAudioPlayerDecodeError(_ expr: Expr) throws -> Expr {
    if let error = try self.audioPlayer(expr).tracker.error {
      return .error(.os(error))
    }
    return .false
  }
  
  private func audioPlayerDuration(_ expr: Expr) throws -> Expr {
    return .makeNumber(try self.audioPlayer(expr).player.duration)
  }
  
  private func audioPlayerElapsed(_ expr: Expr) throws -> Expr {
    return .makeNumber(try self.audioPlayer(expr).player.currentTime)
  }
  
  private func setAudioPlayerElapsed(_ expr: Expr, _ time: Expr) throws -> Expr {
    let player = try self.audioPlayer(expr)
    var time = try time.asDouble(coerce: true)
    if time > player.player.duration {
      time = player.player.duration
    } else if time < 0.0 {
      time = 0.0
    }
    player.player.currentTime = time
    return .void
  }
  
  private func audioPlayerVolume(_ expr: Expr) throws -> Expr {
    return .makeNumber(Double(try self.audioPlayer(expr).player.volume))
  }
  
  private func setAudioPlayerVolume(_ expr: Expr, _ vol: Expr, _ fade: Expr?) throws -> Expr {
    var volume = try vol.asDouble(coerce: true)
    if volume > 1.0 {
      volume = 1.0
    } else if volume < 0.0 {
      volume = 0.0
    }
    var duration = try fade?.asDouble(coerce: true) ?? 0.0
    if duration < 0.0 {
      duration = 0.0
    }
    try self.audioPlayer(expr).player.setVolume(Float(volume), fadeDuration: TimeInterval(duration))
    return .void
  }
  
  private func audioPlayerPan(_ expr: Expr) throws -> Expr {
    return .makeNumber(Double(try self.audioPlayer(expr).player.pan))
  }
  
  private func setAudioPlayerPan(_ expr: Expr, _ pan: Expr) throws -> Expr {
    var pan = try pan.asDouble(coerce: true)
    if pan > 1.0 {
      pan = 1.0
    } else if pan < -1.0 {
      pan = -1.0
    }
    try self.audioPlayer(expr).player.pan = Float(pan)
    return .void
  }
  
  private func audioPlayerRate(_ expr: Expr) throws -> Expr {
    return .makeNumber(Double(try self.audioPlayer(expr).player.rate))
  }
  
  private func setAudioPlayerRate(_ expr: Expr, _ rate: Expr) throws -> Expr {
    var rate = try rate.asDouble(coerce: true)
    if rate > 2.0 {
      rate = 2.0
    } else if rate < 0.5 {
      rate = 0.5
    }
    try self.audioPlayer(expr).player.rate = Float(rate)
    return .void
  }
  
  private func audioPlayerLoops(_ expr: Expr) throws -> Expr {
    return .makeNumber(try self.audioPlayer(expr).player.numberOfLoops)
  }
  
  private func setAudioPlayerLoops(_ expr: Expr, _ num: Expr) throws -> Expr {
    try self.audioPlayer(expr).player.numberOfLoops = num.asInt()
    return .void
  }
  
  private func playAudio(_ expr: Expr, _ time: Expr?) throws -> Expr {
    let player = try self.audioPlayer(expr)
    player.tracker.success = nil
    player.tracker.error = nil
    if let playTime = time {
      player.player.play(atTime: TimeInterval(try playTime.asDouble(coerce: true)))
    } else {
      player.player.play()
    }
    return .void
  }
  
  private func pauseAudio(_ expr: Expr, _ time: Expr?) throws -> Expr {
    try self.audioPlayer(expr).player.pause()
    return .void
  }
  
  private func stopAudio(_ expr: Expr, _ time: Expr?) throws -> Expr {
    try self.audioPlayer(expr).player.stop()
    return .void
  }
}

/// Implementation of audio player objects
class AudioPlayer: NativeObject {
  
  /// Type representing fonts
  public static let type = Type.objectType(Symbol(uninterned: "audio-player"))

  class Tracker: NSObject, AVAudioPlayerDelegate {
    var success: Bool? = nil
    var error: Error? = nil
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
      self.success = flag
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
      self.error = error
    }
  }
  
  let player: AVAudioPlayer
  let tracker: Tracker
  
  init(_ player: AVAudioPlayer) {
    self.player = player
    self.tracker = Tracker()
    self.player.delegate = self.tracker
  }
  
  public override var type: Type {
    return AudioPlayer.type
  }
}
