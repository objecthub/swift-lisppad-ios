;;; Applet that superimposes a logo onto an image
;;;
;;; This is a demo showcasing applets, the `(lispkit image)`
;;; library, as well as how to use an applet also as a regular
;;; Scheme program.
;;; 
;;; This applet takes 4 optional string arguments and 2 file
;;; arguments. The 4 string arguments are used to provide the
;;; following parameters: logo fraction, padding fraction,
;;; intensity, and radius. The 2 file arguments refer to the
;;; base and the logo image. The logo image is optional.
;;;
;;; It is recommended to install applets in the Applets folder
;;; either on the local directory tree or in iCloud. Load this
;;; program into the LispPad editor and select the menu item:
;;; Install "LogoImposition" from the central editor menu
;;; (just tap the file name) for installing the applet.
;;; 
;;; Author: Matthias Zenger
;;; Copyright © 2026 Matthias Zenger. All rights reserved.
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
        (lispkit image)
        (lispkit draw)
        (lisppad applet))

(define (vignette input intensity radius)
  (image-filter-output
    (make-image-filter
      'vignette
      input 
      `((input-intensity . ,intensity) (input-radius . ,radius)))))

(define (crop input extent)
  (image-filter-output
    (make-image-filter
      'crop
      input
      `((input-rectangle . ,extent)))))

(define (shrink input factor)
  (if (> (abs (- factor 1)) 0.0001)
      (image-filter-output
        (make-image-filter
          'affine-transform
          input
          `((input-transform . ,(scale factor factor)))))
      input))

(define (shift input dx dy)
  (image-filter-output
    (make-image-filter
      'affine-transform
      input
      `((input-transform . ,(translate dx dy))))))

(define (overlay front back)
  (image-filter-output
    (make-image-filter
      'source-over-compositing
      front
      `((input-background-image . ,back)))))

(define (scale-logo input base-extent max-fraction)
  (let* ((input-extent (abstract-image-bounds input))
         (scaled-size (scale-size (rect-size base-extent) max-fraction))
         (scale-factor (min 1.0
                            (/ (size-width scaled-size) (rect-width input-extent))
                            (/ (size-height scaled-size) (rect-height input-extent)))))
    (shrink input scale-factor)))

(define (place-logo input logo pad-fraction)
  (let* ((input-extent (abstract-image-bounds input))
         (logo-extent (abstract-image-bounds logo))
         (padding (- (min (* (rect-width input-extent) pad-fraction)
                          (* (rect-height input-extent) pad-fraction))))
         (dx (- (rect-x input-extent) padding (rect-x logo-extent)))
         (dy (- (rect-y input-extent) padding (rect-y logo-extent))))
    (crop (overlay (shift logo dx dy) input) input-extent)))

(define (compose-image base-image logo-image max-fraction
                       pad-fraction intensity radius)
  (let ((base-extent (abstract-image-bounds base-image)))
    (place-logo
      (if (and intensity radius)
          (crop (vignette base-image intensity radius)
                base-extent)
          base-image)
      (scale-logo logo-image base-extent max-fraction)
      pad-fraction)))

(define (get-abstract-image x)
  (if (applet-file? x)
      (make-abstract-image (applet-file-data x))
      (make-abstract-image x)))

(define default-logo-path
  (asset-file-path "LispPadLogo" "png" "Images"))

;; If this is running as a regular program, ask
;; the user to select a photo from the photo
;; library.
(unless (running-as-applet?)
  (applet-arguments-override!
    (make-applet-result
      "0.2"   ; Override the logo fraction
      "0.05"  ; Override the padding fraction
      (car (load-bitmaps-from-library)))))

(define image
  (let-values
    (((logo-frac pad-frac intensity radius)
      (apply values
             (map string->number
                  (applet-string-arguments
                    '("0.15" "0.04" "1.2" "1.8")))))
     ((base-image logo-image)
      (apply values
             (map get-abstract-image
                  (applet-file-arguments
                    (list #f default-logo-path))))))
    (abstract-image->image
      (compose-image base-image
                     logo-image
                     logo-frac
                     pad-frac
                     intensity
                     radius))))

(if (running-as-applet?)
  ; If this program runs as an applet,
  ; return the image
  (make-applet-result image)
  ; If this runs as a regular program,...
  (let ((path
         (append-path-extension
           (file-path
             (make-uuid-string)
             (car (system-directory 'temporary)))
           "jpg")))
    ; Write the image into the photos library
    (save-bitmap-in-library image)
    ; Save the image in the temp directory
    (save-image path image 'jpg)
    ; Preview the result
    (show-preview-panel image)
    path))
