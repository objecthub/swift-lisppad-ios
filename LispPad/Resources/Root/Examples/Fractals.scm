;;; Draws three fractals into three canvases
;;;
;;; This is a demo of the library `(lispkit draw turte)` and the
;;; canvas feature of LispPad Go. The procedures `fern-drawing`,
;;; `dragon-drawing`, and `ccurve-drawing` all return a drawing
;;; of a fractal which is then being shown on an individual
;;; canvas. Procedure `close-drawing` closes the drawings
;;; showing the fractals.
;;;
;;; Author: Matthias Zenger
;;; Copyright © 2024 Matthias Zenger. All rights reserved.
;;;
;;; Licensed under the Apache License, Version 2.0 (the "License");
;;; you may not use this file except in compliance with the
;;; License. You may obtain a copy of the License at
;;;
;;;   http://www.apache.org/licenses/LICENSE-2.0
;;;
;;; Unless required by applicable law or agreed to in writing,
;;; software distributed under the License is distributed on
;;; an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
;;; KIND, either express or implied. See the License for the
;;; specific language governing permissions and limitations
;;; under the License.

(import (lispkit base)
        (lispkit draw)
        (lispkit draw turtle)
        (lisppad system ios))

;; Draw a fractal fern

(define (fern size min)
   (if (>= size min)
       (begin
         (forward (* 0.18 size))
         (turn 4)
         (fern (* 0.82 size) min)
         (turn 58)
         (fern (* 0.40 size) min)
         (turn -122)
         (fern (* 0.40 size) min)
         (turn 60)
         (forward (* -0.18 size)))))

(define (fern-drawing)
  (parameterize
    ((current-turtle (make-turtle 200 200 2.0)))
      (pen-color (color 0.0 0.5 0.0))
      (pen-size 0.3)
      (move 35 180)
      (heading -120)
      (fern 280.0 2.0)
      (turtle-drawing (current-turtle))))

;; Draw a fractal dragon

(define (dragon len angle min)
  (define ang2 (- 90 angle))
  (define (sdragon size positive)
    (cond ((< size min)
            (forward size))
          (positive
            (turn angle)
            (sdragon (* size 0.7071) #t)
            (turn -90)
            (sdragon (* size 0.7071) #f)
            (turn ang2))
          (else
            (turn (- ang2))
            (sdragon (* size 0.7071) #t)
            (turn 90)
            (sdragon (* size 0.7071) #f)
            (turn (- angle)))))
  (heading angle)
  (sdragon len #t))

(define (dragon-drawing)
  (parameterize
    ((current-turtle (make-turtle 200 200 2.0)))
      (pen-color (color 0.7 0.0 0.0))
      (pen-size 0.3)
      (move 27 -19)
      (dragon 175.0 0 1.5)
      (turtle-drawing (current-turtle))))

;; Draw a ccurve

(define (ccurve len angle min)
  (cond
    ((< len min)
      (heading angle)
      (forward len))
    (else
      (ccurve (* len 0.7071) (+ angle 45) min)
      (ccurve (* len 0.7071) (- angle 45) min))))

(define (ccurve-drawing)
  (parameterize
    ((current-turtle (make-turtle 200 200 2.0)))
      (pen-color (color 0.0 0.0 0.5))
      (pen-size 0.3)
      (move 47 -16)
      (ccurve 135.0 90.0 1.0)
      (turtle-drawing (current-turtle))))

;; Create and initialize canvases

(define dsize (size 390 600))

(show-interpreter-tab 'canvas)

(define d1
  (use-canvas (fern-drawing) dsize "Fern"))
(define d2
  (use-canvas (dragon-drawing) dsize "Dragon"))
(define d3
  (use-canvas (ccurve-drawing) dsize "Curve"))

(define (close-drawings)
  (close-canvas d1)
  (close-canvas d2)
  (close-canvas d3)
  (void))

(void)
