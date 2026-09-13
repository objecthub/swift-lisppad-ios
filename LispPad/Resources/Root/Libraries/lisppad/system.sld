;;; LISPPAD SYSTEM
;;;
;;; This library re-exports the subset of procedures provided by library
;;; `(lisppad system macos)` that is also available in the corresponding
;;; `(lisppad system ios)` library of LispPad Go. It is meant to be used by
;;; programs that need to run on both LispPad (macOS) and LispPad Go (iOS)
;;; without having to depend on platform-specific functionality.
;;;
;;; Author: Matthias Zenger
;;; Copyright © 2026 Matthias Zenger. All rights reserved.
;;;
;;; Licensed under the Apache License, Version 2.0 (the "License"); you may not
;;; use this file except in compliance with the License. You may obtain a copy
;;; of the License at
;;;
;;;   http://www.apache.org/licenses/LICENSE-2.0
;;;
;;; Unless required by applicable law or agreed to in writing, software distributed
;;; under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
;;; CONDITIONS OF ANY KIND, either express or implied. See the License for the
;;; specific language governing permissions and limitations under the License.

(define-library (lisppad system)

  (export show-message-panel
          show-choice-panel
          show-load-panel
          show-save-panel
          show-preview-panel
          show-help
          load-bitmaps-from-library
          load-bytevectors-from-library
          save-bitmap-in-library
          session-id
          session-name
          session-log
          project-directory
          icloud-directory
          screen-size
          dark-mode?)

  (import (lisppad system macos))
)
