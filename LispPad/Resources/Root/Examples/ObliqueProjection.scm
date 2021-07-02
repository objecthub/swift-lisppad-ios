;;; Oblique projection of points, lines and planes
;;; 
;;; This program visualizes points, lines and planes in a 3-dimensional cartesian coordinate
;;; system using an oblique projection as described in http://zenger.org/papers/fa.pdf (in
;;; German). All projection and transformation logic is contained in the LispKit example
;;; code `VisualizePointSets.scm`. The code in this program simply displays one or two
;;; visualizations in the LispPad Go console.
;;; 
;;; Example usage:
;;;   (projection-drawing point-set-1)
;;;   (projection-drawing point-set-2)
;;;   (dual-projection-drawing point-set-1 point-set-2)
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

;; This loads the domain logic and includes all the necessary imports from LispKit
(load "Examples/VisualizePointSets")

;; Procedures for displaying point set visualizations in LispPad graphics windows

(define (projection-drawing ps . args)
  (let-optionals args ((proj (current-projection)))
    (drawing (draw-projection proj ps))))

(define (dual-projection-drawing ps1 ps2 . args)
  (let-optionals args ((dsize (size 650 400))
                       (proj (current-projection)))
    (let* ((d1     (make-drawing))
           (d2     (make-drawing))
           (shift  (translate (fl/ (size-width dsize) 2.0) 0)))
      (draw-projection proj ps1 d1)
      (draw-projection proj ps2 d2)
      (set-color black d1)
      (enable-transformation shift d1)
      (draw-drawing d2 d1)
      (disable-transformation shift d1)
      d1)))

;; Demo point sets

(define point-set-1 (list (list (plane #(0 0 0) #(1.0 0.1 -0.5) #(0.0 0.8 0.8))
                                (color 0.6 0.6 0.6) (color 0 0 1 0.15))
                          (list (plane #(0 -7.5 0) #(1.0 0.0 0.0) #(0.0 0.0 1.0))
                                (color 0.6 0.6 0.6) (color 1 0 0 0.15))))

(define point-set-2 (list (plane #(0 0 0) #(0.0 0.0 1.0) #(1.0 0.0 0.0))
                          (plane #(0 0 0) #(0.0 0.0 1.0) #(1.7 1.0 0.0))
                          (plane #(0 0 0) #(0.0 0.0 1.0) #(1.0 1.7 0.0))
                          (plane #(0 0 0) #(0.0 0.0 1.0) #(0.0 1.0 0.0))
                          (plane #(0 0 0) #(0.0 0.0 1.0) #(-1.0 1.7 0.0))
                          (plane #(0 0 0) #(0.0 0.0 1.0) #(1.7 -1.0 0.0))))

(dual-projection-drawing point-set-1 point-set-2)
