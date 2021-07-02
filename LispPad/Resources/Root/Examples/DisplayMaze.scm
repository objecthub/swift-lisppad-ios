;;; Display mazes in a graphics window
;;;
;;; This is an extension of the `LispKit` sample code "Examples/Maze.scm". It loads the
;;; `LispKit` sample code and implements a simple procedure for rendering mazes in a
;;; drawing.
;;;
;;; Usage:
;;;   (maze-drawing (make-maze/randomized-dfs 25 25) 15 15)
;;;   (maze-drawing (make-maze/bintree 25 25) 15 15)
;;;
;;; Author: Matthias Zenger
;;; Copyright © 2019 Matthias Zenger. All rights reserved.
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

;; Load the example code from LispKit
(load "Examples/Maze")

;; `maze-drawing` returns a drawing of the given maze.`dx` and `dy` refer to the size of
;; a single cell.
(define (maze-drawing maze dx dy)
  (drawing
    (set-color red)
    (set-line-width 3)
    (draw (transform-shape (maze->shape maze dx dy) (translate 10 10)))))

;; Example usage
(maze-drawing (make-maze/randomized-dfs 25 20) 15 15)
