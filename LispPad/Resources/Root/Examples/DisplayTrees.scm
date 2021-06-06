;;; Draw binary trees
;;;
;;; This is a minimal extension of the `LispKit` sample code "Examples/DrawTrees.scm".
;;; It loads the `LispKit` sample code and implements a simple function which draws
;;; binary trees in a new drawing, which can be easily displayed in the LispPad Go
;;; console.
;;; 
;;; Binary trees are represented as s-expressions. An inner node of a binary tree is
;;; represented by a list with tree elements: `(<label> <left tree> <right tree>)`. A
;;; leaf node is just a label. For example: `(1 (2 3 (4 5 #f)) (6 #f 7))` represents
;;; this binary tree:
;;; 
;;;              1
;;;            /   \
;;;           2     6
;;;          / \     \
;;;         3   4     7
;;;            /
;;;           5
;;; 
;;; `test-tree-1`, `test-tree-2`, `test-tree-3`, `test-tree-4`, and ``test-tree-5` are
;;; example trees. They can be displayed in a graphics window via procedure `show-tree`.
;;;
;;; Usage:
;;;   (tree-drawing test-tree-1)
;;;   (tree-drawing test-tree-2)
;;;   (tree-drawing test-tree-3)
;;;   (tree-drawing test-tree-4)
;;;   (tree-drawing test-tree-5)
;;;   (tree-drawing test-tree-6)
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

;; Load the example code
(load "Examples/DrawTrees")

;; Define a test tree
(define test-tree-6
  '(A (B (C #f D) (E F (G H (I J K))))
      (L M (N O (P Q (R (S (T U #f) V) #f))))))

;; `tree-drawing` returns a drawing of the given binary tree `xs`. `fx` and `fy` are
;; scaling factors for x and y coordinates. `pad` is the padding around the tree in
;; pixels.
(define (tree-drawing xs . args)
  (let-optionals args ((fx 25)
                       (fy 33)
                       (pad 33))
    (let ((node (layout-tree xs 2)))
      (let-values (((xmin xmax ymax) (tree-dimensions node)))
        (draw-tree node fx fy (- pad (* xmin fx)) pad)))))
