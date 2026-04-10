;;; Default Prelude for LispPad Go
;;; 
;;; Author: Matthias Zenger
;;; Copyright © 2021-2026 Matthias Zenger.
;;; All rights reserved.
;;;
;;; Licensed under the Apache License,
;;; Version 2.0 (the "License"); you may not
;;; use this file except in compliance with
;;; the License. You may obtain a copy of the
;;; License at
;;; 
;; http://www.apache.org/licenses/LICENSE-2.0
;;;
;;; Unless required by applicable law or
;;; agreed to in writing, software 
;;; distributed under the License is
;;; distributed on an "AS IS" BASIS, WITHOUT
;;; WARRANTIES OR CONDITIONS OF ANY KIND,
;;; either express or implied. See the 
;;; License for the specific language 
;;; governing permissions and limitations
;;; under the License.

;; Import (lispkit base) from the LispKit
;; release as well as (lisppad system ios)
;; for the initial environment.

(import (lispkit base)
        (lisppad system ios))

;; Define utilities that are useful primarily
;; for operational/development purposes.

(define (local-ip-address . args)
  (let ((intf (apply available-network-interfaces args)))
    (and (pair? intf) (cadar intf))))
