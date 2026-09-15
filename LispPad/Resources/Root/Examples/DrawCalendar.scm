;;; Draws a calendar for a given month and shows it on a canvas
;;;
;;; This is a demo combining libraries `(lispkit draw)`, `(lispkit date-time)`,
;;; and `(lisppad system ios)`. Procedure `draw-calendar` draws a calendar for
;;; a given month and year, consisting of a header showing the month name and
;;; year, a row of weekday abbreviations, and a grid of day numbers. Weekend
;;; columns are shaded, and, if the displayed month is the current month, the
;;; current day is highlighted. The month name and the weekday abbreviations
;;; are localized based on an optional locale argument. The first day of
;;; the week (i.e. the first column) can be configured via an optional
;;; `fdw` argument, either explicitly via symbols `monday`/`sunday`, or
;;; `#f` for the operating system's default. The dimensions, fonts, and
;;; colors used for drawing are each bundled into a record type (defined
;;; via library `(lispkit record)`), and can be overridden via optional
;;; `dims`, `fonts`, and `colors` arguments. An optional column showing
;;; ISO week numbers can be displayed in front of the 7 day columns; it
;;; is shown whenever the `week-width` field of `dims` is greater than
;;; zero (it defaults to zero, i.e. the week column is hidden by default).
;;; Procedure `show-calendar` draws the calendar and shows it on a canvas.
;;;
;;; Example invocations:
;;;   (show-calendar)                   ; current month
;;;   (show-calendar 2026 9)            ; September 2026
;;;   (show-calendar 2026 9 'de_DE)     ; ... with German month/weekday names
;;;   (show-calendar 2026 9 #f 'sunday) ; ... with Sunday as first column
;;;
;;; 
;;; Author: Matthias Zenger
;;; Copyright © 2026 Matthias Zenger. All rights reserved.
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
        (lispkit draw)
        (lispkit record)
        (lispkit date-time)
        (lisppad system ios))

;; Record type bundling the dimension constants used for drawing a calendar:
;; the width/height of a day cell, the height of the title header, the
;; height of the weekday header row, and the width of the (optional) week
;; number column shown in front of the 7 day columns. The week number
;; column is only drawn when `week-width` is greater than zero.
(define-record-type <calendar-dims>
  (make-calendar-dims cell-width cell-height header-height weekday-height week-width)
  calendar-dims?
  (cell-width calendar-dims-cell-width)
  (cell-height calendar-dims-cell-height)
  (header-height calendar-dims-header-height)
  (weekday-height calendar-dims-weekday-height)
  (week-width calendar-dims-week-width))

;; Default dimensions used by `draw-calendar` unless overridden. The week
;; number column is hidden by default (`week-width` is zero).
(define default-calendar-dims
  (make-calendar-dims 80.0 50.0 50.0 30.0 0.0))

;; Computes a `<calendar-dims>` record whose 7 day columns (plus, if
;; `weeks?` is true, the week number column) together take up `width`
;; points, preserving the proportions of `default-calendar-dims`.
(define (calendar-dims width . args)
  (let-optionals args ((weeks? #f))
    (let* ((base-width (if weeks? 600.0 560.0))
           (scale (/ width base-width)))
      (make-calendar-dims (* scale 80)
                          (* scale 50)
                          (* scale 50)
                          (* scale 30)
                          (if weeks? (* scale 40) 0.0)))))

;; Record type bundling the font constants used for drawing a calendar: the
;; font for the title, the weekday header row, the day numbers, and the
;; (optional) week number column.
(define-record-type <calendar-fonts>
  (make-calendar-fonts title-font weekday-font day-font week-font)
  calendar-fonts?
  (title-font calendar-fonts-title-font)
  (weekday-font calendar-fonts-weekday-font)
  (day-font calendar-fonts-day-font)
  (week-font calendar-fonts-week-font))

;; Default fonts used by `draw-calendar` unless overridden. `week-font` is
;; small since it only needs to fit a 1- or 2-digit week number.
(define default-calendar-fonts
  (make-calendar-fonts (font "Helvetica-Bold" 18)
                        (font "Helvetica-Bold" 11)
                        (font "Helvetica" 14)
                        (font "Helvetica-Oblique" 10)))

;; Record type bundling the color constants used for drawing a calendar,
;; including the text color and background color of the (optional) week
;; number column.
(define-record-type <calendar-colors>
  (make-calendar-colors border-color
                         grid-color
                         day-color
                         title-color
                         title-bg
                         weekend-color
                         weekend-bg
                         weekday-color
                         weekday-bg
                         today-bg
                         week-color
                         week-bg)
  calendar-colors?
  (border-color calendar-colors-border-color)
  (grid-color calendar-colors-grid-color)
  (day-color calendar-colors-day-color)
  (title-color calendar-colors-title-color)
  (title-bg calendar-colors-title-bg)
  (weekend-color calendar-colors-weekend-color)
  (weekend-bg calendar-colors-weekend-bg)
  (weekday-color calendar-colors-weekday-color)
  (weekday-bg calendar-colors-weekday-bg)
  (today-bg calendar-colors-today-bg)
  (week-color calendar-colors-week-color)
  (week-bg calendar-colors-week-bg))

;; Default colors used by `draw-calendar` unless overridden.
(define default-calendar-colors
  (make-calendar-colors black
                        (color 0.6 0.6 0.6)
                        black
                        (color 0 0 0.5)
                        (color 0.85 0.87 0.93)
                        (color 0.75 0.15 0.15)
                        (color 0.95 0.95 0.95)
                        (color 0.3 0.3 0.3)
                        (color 0.85 0.85 0.85)
                        (color 1.0 0.9 0.7)
                        (color 0.4 0.4 0.4)
                        (color 0.92 0.92 0.92)))


;; Number of days in `month` of `year` (1-indexed month), computed by taking
;; the day before the 1st of the following month.
(define (days-in-month year month)
  (let-values (((ny nm) (if (= month 12) (values (+ year 1) 1) (values year (+ month 1)))))
    (date-time-day (date-time-add (date-time ny nm 1) -1))))

;; Full month name for `locale`, e.g. "September". `locale` is a symbol,
;; e.g. `en_US` or `de_DE`, or `#f` to use the current, operating
;; system-defined locale.
(define (month-name year month locale)
  (date-time->string (date-time year month 1) locale "MMMM"))

;; Abbreviated weekday name for `locale` and column `col` (0-based), where
;; the first column corresponds to ISO weekday number `fdwn` (1 = Monday,
;; ..., 7 = Sunday), independent of the displayed month. `locale` is a
;; symbol, e.g. `en_US` or `de_DE`, or `#f` to use the current, operating
;; system-defined locale.
(define (weekday-name col locale fdwn)
  (date-time->string
    (week->date-time 2024 2 (+ 1 (modulo (+ fdwn col -1) 7))) locale "EEE"))

;; Maps the `fdw` argument (first day of the week) to the ISO weekday number
;; (1 = Monday, ..., 7 = Sunday) of the calendar's first column. The default
;; is defined by the locale.
(define (first-weekday-number fdw loc)
  (cond ((eq? fdw 'monday) 1)
        ((eq? fdw 'sunday) 7)
        (else (if (locale-sunday-first? (or loc (locale))) 7 1))))

;; Rect of the given `size`, centered on point `pt`.
(define (centered-rect pt sz)
  (rect (- (point-x pt) (/ (size-width sz) 2))
        (- (point-y pt) (/ (size-height sz) 2))
        (size-width sz)
        (size-height sz)))

;; Draw `str` centered within rect `rct`.
(define (draw-centered str fnt clr rct)
  (draw-text str (centered-rect (rect-mid-point rct) (text-size str fnt)) fnt clr))

;; Draw a calendar for `month`/`year` in `locale`, with first day of the
;; week `fdw`, dimensions `dims`, fonts `fonts`, and colors `colors` (all
;; optional, defaulting to the current month/year, the operating
;; system-defined locale, the operating system's default first day of the
;; week, and `default-calendar-dims`/`default-calendar-fonts`/
;; `default-calendar-colors` respectively). `locale` is a symbol, e.g.
;; `en_US` or `de_DE`, used for localizing the month name and the weekday
;; abbreviations. `fdw` is `#f` or one of the symbols `monday`/`sunday` —
;; see `first-weekday-number` for details. `dims` is a `<calendar-dims>`,
;; `fonts` a `<calendar-fonts>`, and `colors` a `<calendar-colors>` record,
;; allowing the layout, fonts, and colors of the calendar to be customized.
;; If `dims`' `week-width` field is greater than zero, an extra column is
;; drawn in front of the 7 day columns, showing the ISO week number of
;; each row, using `fonts`' `week-font` and `colors`' `week-color`/
;; `week-bg`. Returns two values: a `(lispkit draw)` drawing and the
;; `size` needed to display it (the latter depends on the number of
;; week-rows, so it cannot be a constant).
(define (draw-calendar . args)
  (let-optionals args ((year (date-time-year (date-time)))
                        (month (date-time-month (date-time)))
                        (locale #f)
                        (fdw #f)
                        (dims default-calendar-dims)
                        (fonts default-calendar-fonts)
                        (colors default-calendar-colors))
    (let* ((cell-width (calendar-dims-cell-width dims))
           (cell-height (calendar-dims-cell-height dims))
           (header-height (calendar-dims-header-height dims))
           (weekday-height (calendar-dims-weekday-height dims))
           (title-font (calendar-fonts-title-font fonts))
           (weekday-font (calendar-fonts-weekday-font fonts))
           (day-font (calendar-fonts-day-font fonts))
           (border-color (calendar-colors-border-color colors))
           (grid-color (calendar-colors-grid-color colors))
           (day-color (calendar-colors-day-color colors))
           (title-color (calendar-colors-title-color colors))
           (title-bg (calendar-colors-title-bg colors))
           (weekend-color (calendar-colors-weekend-color colors))
           (weekend-bg (calendar-colors-weekend-bg colors))
           (weekday-color (calendar-colors-weekday-color colors))
           (weekday-bg (calendar-colors-weekday-bg colors))
           (today-bg (calendar-colors-today-bg colors))
           (week-width (calendar-dims-week-width dims))
           (week-font (calendar-fonts-week-font fonts))
           (week-color (calendar-colors-week-color colors))
           (week-bg (calendar-colors-week-bg colors))
           (weeks? (> week-width 0))
           (fdwn (first-weekday-number fdw locale))
           (first-wd (modulo (- (date-time-weekday (date-time year month 1)) fdwn) 7))
           (sat-col (modulo (- 6 fdwn) 7))
           (sun-col (modulo (- 7 fdwn) 7))
           (ndays (days-in-month year month))
           (week-rows (quotient (+ first-wd ndays 6) 7))
           (grid-top (+ header-height weekday-height))
           (width (+ week-width (* 7 cell-width)))
           (height (+ grid-top (* week-rows cell-height)))
           (today (date-time))
           (this-month? (and (= year (date-time-year today)) (= month (date-time-month today)))))
      (values
        (drawing
          ; Draw title background
          (set-fill-color title-bg)
          (fill-rect (rect 0 0 width header-height))
          ; Draw weekday header background
          (set-fill-color weekday-bg)
          (fill-rect (rect 0 header-height width weekday-height))
          ; Draw week number column background
          (if weeks?
            (begin
              (set-fill-color week-bg)
              (fill-rect (rect 0 grid-top week-width (* week-rows cell-height)))))
          ; Draw weekend column backgrounds
          (set-fill-color weekend-bg)
          (fill-rect
            (rect (+ week-width (* sat-col cell-width))
                  grid-top
                  cell-width
                  (* week-rows cell-height)))
          (fill-rect
            (rect (+ week-width (* sun-col cell-width))
                  grid-top
                  cell-width
                  (* week-rows cell-height)))
          ; Highlight today, if the displayed month is the current month
          (if this-month?
            (let* ((d (date-time-day today))
                   (idx (+ first-wd (- d 1)))
                   (row (quotient idx 7))
                   (col (remainder idx 7))
                   (x (+ week-width (* col cell-width)))
                   (y (+ grid-top (* row cell-height))))
              (set-fill-color today-bg)
              (fill (rectangle (point (+ x 4) (+ y 4))
                                (size (- cell-width 8) (- cell-height 8)) 6 6))))
          ; Draw grid lines
          (set-color grid-color)
          (set-line-width 1.0)
          (do ((c 0 (+ c 1))) ((> c 7))
            (draw-line (point (+ week-width (* c cell-width)) header-height)
                       (point (+ week-width (* c cell-width)) height)))
          (do ((r 0 (+ r 1))) ((> r week-rows))
            (draw-line (point 0 (+ grid-top (* r cell-height)))
                       (point width (+ grid-top (* r cell-height)))))
          (draw-line (point 0 header-height) (point width header-height))
          ; Draw outer border
          (set-color border-color)
          (set-line-width 1.5)
          (draw-rect (rect 0 0 width height))
          ; Title: month name + year
          (draw-centered
            (string-append (month-name year month locale) " " (number->string year))
            title-font
            title-color
            (rect 0 0 width header-height))
          ; Print weekday header row
          (do ((c 0 (+ c 1))) ((= c 7))
            (draw-centered
              (weekday-name c locale fdwn)
              weekday-font
              weekday-color
              (rect (+ week-width (* c cell-width)) header-height cell-width weekday-height)))
          ; Print week numbers
          (if weeks?
            (do ((r 0 (+ r 1))) ((= r week-rows))
              (draw-centered
                (number->string
                  (date-time-week
                    (date-time-add (date-time year month 1) (max (- (* r 7) first-wd) 0))
                    (if fdw (if (eq? fdwn 1) 'de_DE 'en_US) locale)))
                week-font
                week-color
                (rect 0 (+ grid-top (* r cell-height)) week-width cell-height))))
          ; Print day numbers
          (do ((d 1 (+ d 1))) ((> d ndays))
            (let* ((idx (+ first-wd (- d 1)))
                   (row (quotient idx 7))
                   (col (remainder idx 7))
                   (x (+ week-width (* col cell-width)))
                   (y (+ grid-top (* row cell-height)))
                   (weekend? (or (= col sat-col) (= col sun-col))))
              (draw-centered (number->string d)
                             day-font
                             (if weekend? weekend-color day-color)
                             (rect x y cell-width cell-height)))))
        (size width height)))))

;; Show a calendar for `month`/`year`/`locale`/`fdw`/`dims`/`fonts`/`colors`
;; (all optional, see `draw-calendar`) on a LispPad Go canvas named "Calendar".
(define (show-calendar . args)
  (let-values (((d sz) (apply draw-calendar args)))
    (show-interpreter-tab 'canvas)
    (use-canvas d sz "Calendar")))

;; Show the calendar for the current month on a canvas, with a week number
;; column in front of the 7 day columns
(show-calendar (date-time-year (date-time))  ; current year
               (date-time-month (date-time)) ; current month
               #f                            ; default locale
               #f                            ; default first week day
               (calendar-dims (size-width (screen-size)) #t))
