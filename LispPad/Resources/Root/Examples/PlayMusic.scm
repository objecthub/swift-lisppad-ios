;;; Play music files
;;;
;;; This is a demo showcasing library `(lisppad audio)`. This library
;;; provides a simple asynchronous API to play back music (e.g. music in AAC,
;;; MP3, etc. format). The library allows for control over the volume, the
;;; pan, and playback rate. It also supports playing music in a loop.
;;; 
;;; Procedure `mix-music` plays two music tracks in a row using fade-in and
;;; fade-out effects as well as changing the playback rate. Here is an
;;; example invocation which plays back two tracks from Bensound.com:
;;; 
;;;   (mix-music endless-motion moose)
;;; 
;;; Author: Matthias Zenger
;;; Copyright © 2021 Matthias Zenger. All rights reserved.
;;;
;;; Licensed under the Apache License, Version 2.0 (the "License"); you may
;;; not use this file except in compliance with the License. You may obtain
;;; a copy of the License at
;;;
;;;   http://www.apache.org/licenses/LICENSE-2.0
;;;
;;; Unless required by applicable law or agreed to in writing, software
;;; distributed under the License is distributed on an "AS IS" BASIS,
;;; WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
;;; implied. See the License for the specific language governing
;;; permissions and limitations under the License.

(import (lispkit base)
        (lisppad system)
        (lisppad audio))

;; Reset the given audio player `pl` and set volume to `vol`.
(define (reset-audio-player! pl vol)
  ; stop playing
  (if (audio-player-playing? pl)
      (stop-audio pl))
  ; set volume
  (set-audio-player-volume! pl vol)
  ; set to normal rate
  (set-audio-player-rate! pl 1)
  ; make audio player play the music from the beginning
  (set-audio-player-elapsed! pl 0))

;; First play `pl1` and, after 20 seconds, fade in `pl2`; after 20 more
;; seconds, incease the play rate of `pl2` and fade out the music.
(define (mix-music pl1 pl2)
  (reset-audio-player! pl1 1)
  (reset-audio-player! pl2 0)
  (play-audio pl1)
  (sleep 20.4)
  (set-audio-player-volume! pl1 0 4)
  (play-audio pl2)
  (set-audio-player-volume! pl2 1 4)
  (sleep 20)
  (stop-audio pl1)
  (set-audio-player-rate! pl2 1.05)
  (sleep 1)
  (set-audio-player-rate! pl2 1.1)
  (sleep 1)
  (set-audio-player-rate! pl2 1.15)
  (sleep 1)
  (set-audio-player-rate! pl2 1.2)
  (sleep 1)
  (set-audio-player-volume! pl2 0 3)
  (sleep 3.3)
  (stop-audio pl2))

;; Create music player for track "Endless motion" from Bensound.com
(define endless-motion
  (make-audio-player
    (asset-file-path "bensound-endlessmotion" "mp3" "Audio") #f #t))

;; Create music player for track "Moose" from Bensound.com. Load track
;; "Moose" into a bytevector via `read-binary-file` and pass the bytevector
;; to `make-audio-player`.
(define moose
  (make-audio-player
    (read-binary-file (asset-file-path "bensound-moose" "mp3" "Audio")) #f #t))

;; Stop playing `endless-motion` and `moose`
(define (stop-demo-music)
  (reset-audio-player! endless-motion 1)
  (reset-audio-player! moose 1))
