;;; LISPPAD TURTLE
;;;
;;; This is a library implementing a simple canvas for displaying turtle
;;; graphics. The library supports one graphics canvas per LispPad session
;;; which gets initialized by invoking `init-turtle`.
;;; 
;;; The following set of "turtle functions" are provided:
;;; 
;;;   - `(indicator-on)`: Shows the turtle icon
;;;   - `(indicator-off)`: Hides the turtle icon
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

  (export indicator?
          make-indicator
          empty-indicator
          make-arrow-indicator
          init-turtle
          reset-turtle
          turtle-drawing
          turtle-indicator
          indicator-on
          indicator-off
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

    (define-record-type indicator
                        (make-indicator shape width stroke-color up-color down-color)
                        indicator?
                        (shape indicator-shape set-indicator-shape!)
                        (width indicator-width set-indicator-width!)
                        (stroke-color indicator-stroke-color set-indicator-stroke-color!)
                        (up-color indicator-up-color set-indicator-up-color!)
                        (down-color indicator-down-color set-indicator-down-color!))
    
    (define empty-indicator
      (make-indicator (shape) 0 white white white))
    
    (define (make-arrow-indicator . args)
      (let-optionals args ((size 12)
                           (width 0.7)
                           (stroke-color (color 0.3 0.3 1.0))
                           (up-color (color 1.0 1.0 1.0 0.65))
                           (down-color (color 0.95 0.85 0.25 0.65)))
        (make-indicator (arrow-shape size) width stroke-color up-color down-color)))
    
    (define (arrow-shape size)
      (shape
        (move-to (point (* size 0.5) 0))
        (line-to (point (* size -0.5) (* size 0.5)))
        (line-to (point (* size -0.25) 0))
        (line-to (point (* size -0.5) (* size -0.5)))
        (line-to (point (* size 0.5) 0))))

    ;; The turtle for this session
    (define turtle #f)

    ;; The turtle drawing
    (define indicator-drawing #f)
    
    ;; The indicator for showing the current position and orientation of the turtle
    (define indicator #f)
    
    ;; Show the indicator?
    (define indicator-enabled? #t)

    ;; The canvas for this session
    (define canvas #t)

    ;; Initializes a new turtle and displays its drawing in a new window. `init-turtle` gets
    ;; two optional arguments: `scale` and `title`. `scale` is a scaling factor which determines
    ;; the size of the turtle drawing. `title` is a string that defines the window name of the
    ;; turtle graphics. It also acts as the identify of the turtle graphics window; i.e. it won't
    ;; be possible to have two sessions with the same name but a different graphics window.
    (define (init-turtle . args)
      (let-optionals args ((scale 1.0)
                           (ind (make-arrow-indicator 12))
                           (title (string-append
                                    "Turtle "
                                    (number->string (fxand (session-id) (fx1- (expt 2 32))) 16))))
        (let* ((len (min (size-width (screen-size)) (size-height (screen-size))))
               (plane-size (size len len))
               (dx (/ (size-width plane-size) 2.0))
               (dy (/ (size-height plane-size) 2.0)))
          (set! indicator ind)
          (set! turtle (lispkit:make-turtle dx dy scale))
          (set! indicator-drawing (drawing))
          (set! indicator-enabled? #t)
          (update-indicator)
          (set! canvas (use-canvas (drawing
                                     (inline-drawing (lispkit:turtle-drawing turtle))
                                     (inline-drawing indicator-drawing))
                                    plane-size
                                    title))
          (show-interpreter-tab 'canvas canvas))))
    
    (define (update-indicator)
      (if (and indicator-enabled? (indicator-shape indicator))
          (let ((arrow-shape (transform-shape
                               (indicator-shape indicator)
                               (transformation
                                 (rotate (lispkit:turtle-angle turtle))
                                 (translate (lispkit:turtle-x turtle) (lispkit:turtle-y turtle))))))
            (clear-drawing indicator-drawing)
            (set-color (indicator-stroke-color indicator) indicator-drawing)
            (if (lispkit:turtle-pen-down? turtle)
                (set-fill-color (indicator-down-color indicator) indicator-drawing)
                (set-fill-color (indicator-up-color indicator) indicator-drawing))
            (fill arrow-shape indicator-drawing)
            (draw arrow-shape (indicator-width indicator) indicator-drawing))
          (clear-drawing indicator-drawing)))

    ;; Closes the turtle window and resets the turtle library.
    (define (reset-turtle)
      (close-canvas canvas)
      (set! turtle #f)
      (set! indicator-drawing #f)
      (set! indicator #f)
      (set! indicator-enabled? #t)
      (set! canvas #f)
      (show-interpreter-tab 'console))

    ;; Returns the current turtle drawing
    (define (turtle-drawing)
      (lispkit:turtle-drawing turtle))
    
    ;; Returns the current turtle indicator
    (define (turtle-indicator)
      indicator)
      
    (define (indicator-on)
      (set! indicator-enabled? #t)
      (update-indicator))
      
    (define (indicator-off)
      (set! indicator-enabled? #f)
      (update-indicator))
    
    (define (pen-up)
      (lispkit:pen-up turtle)
      (update-indicator))
    
    (define (pen-down)
      (lispkit:pen-down turtle)
      (update-indicator))
    
    (define (pen-color color)
      (lispkit:pen-color color turtle))
    
    (define (pen-size size)
      (lispkit:pen-size size turtle))
    
    (define (home)
      (lispkit:home turtle)
      (update-indicator))
    
    (define (move x y)
      (lispkit:move x y turtle)
      (update-indicator))

    (define (heading angle)
      (lispkit:heading angle turtle)
      (update-indicator))

    (define (turn angle)
      (lispkit:turn angle turtle)
      (update-indicator))

    (define (left angle)
      (lispkit:left angle turtle)
      (update-indicator))

    (define (right angle)
      (lispkit:right angle turtle)
      (update-indicator))

    (define (forward len)
      (lispkit:forward len turtle)
      (update-indicator))

    (define (backward len)
      (lispkit:backward len turtle)
      (update-indicator))
  )
)
