;;; Draws a Sierpinski triangle using turtle graphics
;;;
;;; This is a demo of the library `(lispkit draw turte)`. The code will first initialize
;;; the turtle and then draw a Sierpinski triangle in the turtle drawing. More information
;;; about Sierpinski triangles can be found here:
;;; https://en.wikipedia.org/wiki/Sierpinski_triangle
;;;
;;; Author: Matthias Zenger
;;; Copyright © 2021 Matthias Zenger. All rights reserved.
;;;
;;; Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file
;;; except in compliance with the License. You may obtain a copy of the License at
;;;
;;;   http://www.apache.org/licenses/LICENSE-2.0
;;;
;;; Unless required by applicable law or agreed to in writing, software distributed under the
;;; License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
;;; either express or implied. See the License for the specific language governing permissions
;;; and limitations under the License.

(import (lispkit base)
        (lispkit draw)
        (lispkit draw turtle))

;; Draws a Sierpinski triangle at the current turtle position for the given edge
;; length `size`. `n` determines the number of iterations.
(define (sierpinski size n)
  (cond ((positive? n)
          (sierpinski (fx/ size 2) (- n 1))
          (forward (fx/ size 2))
          (sierpinski (fx/ size 2) (- n 1))
          (backward (fx/ size 2))
          (turn 60)
          (forward (fx/ size 2))
          (turn -60)
          (sierpinski (fx/ size 2) (- n 1))
          (turn 60)
          (backward (fx/ size 2))
          (turn -60))
        (else
          (forward size)
          (turn 120)
          (forward size)
          (turn 120)
          (forward size)
          (turn -240))))

;; Draws a Sierpinski triangle centered in the middle of the turtle plane for the given
;; edge length `size`. `n` determines the number of iterations.
(define (draw-sierpinski size n . args)
  (let-optionals args ((scale 1.0))
    (parameterize ((current-turtle (make-turtle (/ size 2.0) (/ size 2.0) scale)))
      (home)
      (heading 0)
      (pen-color blue)
      (pen-up)
      (backward (fx/ size 2))
      (turn 90)
      (backward (* size 0.5 (sqrt (/ 3 4))))
      (turn -90)
      (pen-down)
      (sierpinski size n)
      (turtle-drawing (current-turtle)))))

(draw-sierpinski 800 7)
