;;; LISPPAD TURTLE
;;;
;;; This is a library implementing a simple canvas for displaying turtle
;;; graphics. The library supports one graphics canvas per LispPad session
;;; which gets initialized by invoking `init-turtle`.
;;; 
;;; The following set of "turtle functions" are provided:
;;; 
;;;   - `(pen-up)`: Lifts the turtle
;;;   - `(pen-down)`: Drops the turtle
;;;   - `(pen-color color)`: Sets the current color of the turtle
;;;   - `(pen-size size)`: Sets the size of the turtle pen
;;;   - `(home)`: Moves the turtle back to the origin
;;;   - `(move x y)`: Moves the turtle to position `(x, y)`
;;;   - `(heading angle)`: Sets the angle of the turtle (in radians)
;;;   - `(turn angle)`: Turns the turtle by the given angle (in radians)
;;;   - `(left angle)`: Turn left by the given angle (in radians)
;;;   - `(right angle)`: Turn right by the given angle (in radians)
;;;   - `(forward length)`: Moves forward by `length` units drawing a line
;;;     if the pen is down
;;;   - `(backward length)`: Moves backward by `length` units drawing a
;;;     line if the pen is down
;;;
;;; Author: Matthias Zenger
;;; Copyright © 2018-2023 Matthias Zenger. All rights reserved.
;;;
;;; Licensed under the Apache License, Version 2.0 (the "License"); you may
;;; not use this file except in compliance with the License. You may obtain
;;; a copy of the License at
;;;
;;;   http://www.apache.org/licenses/LICENSE-2.0
;;;
;;; Unless required by applicable law or agreed to in writing, software
;;; distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
;;; WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
;;; License for the specific language governing permissions and limitations
;;; under the License.

(define-library (lisppad turtle)

  (export init-turtle
          reset-turtle
          turtle-drawing
          pen-up
          pen-down
          pen-color
          pen-size
          home
          move
          heading
          turn
          left
          right
          forward
          backward)

  (import (lispkit base)
          (lispkit draw)
          (lisppad system)
          (prefix (lispkit draw turtle) lispkit:))

  (begin

    ;; The turtle for this session
    (define turtle #f)

    ;; The canvas for this session
    (define canvas #t)

    ;; Initializes a new turtle and displays its drawing in a new canvas.
    ;; `init-turtle` gets two optional arguments: `scale` and `title`. `scale`
    ;; is a scaling factor which determines the size of the turtle drawing.
    ;; `title` is a string that defines the canvas name of the turtle graphics.
    ;; It also acts as the identify of the turtle graphics canvas; i.e. it won't
    ;; be possible to have two sessions with the same name but a different canvas.
    (define (init-turtle . args)
      (let-optionals args ((scale 1.0)
                           (title (string-append
                                    "Turtle "
                                    (number->string (fxand (session-id) (fx1- (expt 2 32))) 16))))
        (let* ((len (min (size-width (screen-size)) (size-height (screen-size))))
               (plane-size (size len len))
               (dx (/ (size-width plane-size) 2.0))
               (dy (/ (size-height plane-size) 2.0))
               (new-turtle (lispkit:make-turtle dx dy scale)))
          (set! turtle new-turtle)
          (set! canvas (use-canvas (lispkit:turtle-drawing new-turtle)
                                    plane-size
                                    title))
          (void))))

    ;; Closes the turtle canvas and resets the turtle library.
    (define (reset-turtle)
      (close-canvas canvas)
      (set! turtle #f)
      (set! canvas #f))

    ;; Returns the current turtle drawing
    (define (turtle-drawing)
      (lispkit:turtle-drawing turtle))
    
    (define (pen-up)
      (lispkit:pen-up turtle))

    (define (pen-down)
      (lispkit:pen-down turtle))

    (define (pen-color color)
      (lispkit:pen-color color turtle))

    (define (pen-size size)
      (lispkit:pen-size size turtle))

    (define (home)
      (lispkit:home turtle))

    (define (move x y)
      (lispkit:move x y turtle))

    (define (heading angle)
      (lispkit:heading angle turtle))

    (define (turn angle)
      (lispkit:turn angle turtle))

    (define (left angle)
      (lispkit:left angle turtle))

    (define (right angle)
      (lispkit:right angle turtle))

    (define (forward len)
      (lispkit:forward len turtle))

    (define (backward len)
      (lispkit:backward len turtle))
  )
)
