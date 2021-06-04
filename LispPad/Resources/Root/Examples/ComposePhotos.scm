;;; Load, compose, display and save photos
;;;
;;; This is a demo showing how to load photos, create photos, display them in the console
;;; and save them in the iOS photo library. When executed, this demo will load a photo
;;; of a landscape and a logo image. It will create a new photo in which the logo is used
;;; as a watermark. In addition, a copyright message is added.
;;;
;;; The following statement saves the composed image on disk in JPEG format:
;;;   (save-bitmap "composed-image.jpeg" new-photo 'jpg)
;;; 
;;; This statement saves the composed image in the iOS photo library
;;;   (save-bitmap-in-library new-photo)
;;; 
;;; Author: Matthias Zenger
;;; Copyright © 2020-2021 Matthias Zenger. All rights reserved.
;;;
;;; Licensed under the Apache License, Version 2.0 (the "License"); you may not use this
;;; file except in compliance with the License. You may obtain a copy of the License at
;;;
;;;   http://www.apache.org/licenses/LICENSE-2.0
;;;
;;; Unless required by applicable law or agreed to in writing, software distributed under the
;;; License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
;;; either express or implied. See the License for the specific language governing permissions
;;; and limitations under the License.

(import (lispkit base)
        (lispkit draw)
        (lisppad system))

;; Fits size `s` into `max`
(define (scale-to-fit s max)
  (cond ((> (size-width s) (size-width max))
          (scale-to-fit
            (size (size-width max) (* (size-height s) (/ (size-width max) (size-width s)))) max))
        ((> (size-height s) (size-height max))
          (scale-to-fit
            (size (* (size-width s) (/ (size-height max) (size-height s))) (size-height max)) max))
        (else s)))

;; Scale an image `image` to fit the given boundaries `max` and place it in the middle of
;; rectangle `frame`, drawn in color `col`.
(define (scale-image image max frame col)
  (let* ((bounds (scale-to-fit (image-size image) max))
         (center (move-point (opt rect-point frame zero-point)
                             (/ (opt rect-width frame (size-width bounds)) 2)
                             (/ (opt rect-height frame (size-height bounds)) 2)))
         (image-point (move-point center
                                  (- (/ (size-width bounds) 2))
                                  (- (/ (size-height bounds) 2)))))
    (drawing (if col (set-color col))
             (if frame (draw-rect frame))
             (draw-image image (rect image-point bounds)))))

;; Load the photo and the logo from image files provided by LispPad
(define photo (load-image (asset-file-path "Regensberg" "jpeg" "Images")))
(define logo (load-image (asset-file-path "LispPadLogo" "png" "Images")))

;; Create a new drawing combining the photo and the logo and including a copyright message
;; at the bottom right corner.
(define composed-drawing
  (let* ((photo-size      (image-size photo))
         (copyright-text  "Photo © 2019 Matthias Zenger")
         (copyright-font  (font "Georgia" 108 normal italic))
         (copyright-size  (text-size copyright-text copyright-font))
         (copyright-point (point (- (size-width photo-size) (size-width copyright-size) 120)
                                 (- (size-height photo-size) 200))))
    (drawing
      (draw-image photo (rect zero-point photo-size))
      (draw-image logo (rect (point 120 120) (scale-size (image-size logo) 0.75)) 1.0 'source-over)
      (draw-text copyright-text copyright-point copyright-font white)
      (draw-text copyright-text (move-point copyright-point -6 -6) copyright-font black))))

;; Define a new image based on the composed drawing
(define new-photo (make-bitmap composed-drawing (image-size photo)))

;; Scale down the image and logo and return both drawings from the program
(define scaled-photo (scale-image new-photo (size 1000 1000) #f #f))
(define scaled-logo (scale-image logo (size 280 260) (rect 0 0 900 280) white))
(values scaled-logo scaled-photo)
