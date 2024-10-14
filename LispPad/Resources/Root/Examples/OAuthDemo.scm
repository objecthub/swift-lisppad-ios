;;; Demonstrate usage of OAuth 2.0 authorization
;;;
;;; This example showcases how to use LispKit's networking libraries to
;;; access web APIs from Google and GitHub. It relies on the system
;;; keychain to store secrets, including authorization credentials.
;;;
;;; This program defines three demo API calls: `google-people-api-demo`,
;;; `github-api-demo`, and `github-api-device-demo`. Each demo is
;;; represented by a procedure which is setting up everything so that
;;; an API call can eventually be made. The result of that call is
;;; returned by the demo procedures.
;;;
;;; Each demo requires a client id and a client secret which first need
;;; to be defined/registered either at Google's Cloud Platform Console or
;;; GitHub's developer settings. The demo procedures access client id and
;;; secret via the keychain. With procedure `provide-credentials` you
;;; first need to write the credentials into the keychain (only once).
;;;
;;; For Google, the process for how to set up OAuth 2.0 is described here:
;;; https://support.google.com/cloud/answer/6158849?hl=en
;;; It is recommended to pick "web application" as application type and
;;; include http://localhost:3000 as one of the supported redirect URIs.
;;; The Cloud Platform Console will provide both client id and secret,
;;; which need to be written to the keychain via procedure
;;; `provide-credentials`. When creating an OAuth 2.0 session via
;;; `make-oauth2-session`, it is important to enable the argument
;;; `intercept403?`.
;;;
;;; For GitHub, OAuth 2.0 credentials can be defined with a redirect URI
;;; to lisppad://oauth/callback. LispPad intercepts such requests
;;; forwarding the relevant parameters to library `(lispkit http oauth)`.
;;; This is why the GitHub flow implemented by procedure `github-api-demo`
;;; does not have to start its own web server to receive the authorization
;;; redirect. But it's important to set setting `secret_in_body` to true.
;;; For using the device grant flow implemented by `github-api-device-demo`
;;; it is important that the corresponding checkbox is ticked in the
;;; GitHub developer settings for the OAuth 2.0 client.
;;;
;;; Once the clients are registered and credentials are know, they can be
;;; stored in the keychain, e.g. like this:
;;;   (provide-credentials google-code "<client id>" "<secret>")
;;;   (provide-credentials github-code "<client id>" "<secret>")
;;;   (provide-credentials github-device "<client id>" "<secret>")
;;;
;;; Finally, the demo calls can be made via:
;;;   (google-people-api-demo)
;;;   (github-api-demo)
;;;   (github-api-device-demo)
;;;
;;;
;;; Author: Matthias Zenger
;;; Copyright © 2024 Matthias Zenger. All rights reserved.
;;;
;;; Licensed under the Apache License, Version 2.0 (the "License"); you may
;;; not use this file except in compliance with the License. You may obtain
;;; a copy of the License at
;;;
;;;   http://www.apache.org/licenses/LICENSE-2.0
;;;
;;; Unless required by applicable law or agreed to in writing, software
;;; distributed under the License is distributed on an "AS IS" BASIS,
;;; WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
;;; See the License for the specific language governing permissions and
;;; limitations under the License.

(import (lispkit base)
        (lispkit http)
        (lispkit http oauth)
        (lispkit http server)
        (lispkit thread)
        (lispkit thread future)
        (lispkit system keychain)
        (lispkit json))

;; Global configuration of demos

(define min-log-level 1)         ; leave out debug messages (0 = all; 5 = none)
(define remember-auth-tokens #f) ; forget auth tokens after each demo
(define embedded-auth-flow #t)   ; use an embedded auth flow

;;; Identify of authorization credentials in system keychain

(define google-code "google code")
(define github-code "github code")
(define github-device "github device")

;;; Manage authorization credentials via the system keychain

(define keychain (make-keychain "net.objecthub.LispPad.WebAPIs"))

(define (provide-credentials name id secret)
  (keychain-set! keychain name (values id secret)))

(define (credentials-exist? name)
  (keychain-exists? keychain name))

(define (retrieve-credentials name)
  (keychain-ref keychain name))

(define (delete-credentials name)
  (keychain-remove! keychain name))

;;; Use a small custom webserver to receive OAuth 2.0 redirects

(define (start-authorization-server)
  (let ((server (make-http-server)))
    ; Reject unknown paths
    (http-server-register-default! server
      (lambda (request) (srv-response-not-found)))
    ; Handle redirects at "/"
    (http-server-register! server "/"
      (lambda (request)
        (let ((url (string-append "http://localhost:3000" (srv-request-query request))))
          (http-server-log server 2 "handler/redirect" url)
          (if (oauth2-redirect! url)
              (make-srv-response 200 #f "redirect registered")
              (make-srv-response 200 #f "redirect failed")))))
    ; Start the server in a new thread
    (spawn (thunk (http-server-start! server 3000)))
    (thread-yield!)
    ; Return server object
    server))

(define (stop-authorization-server server)
  (http-server-stop! server))

;;; Access Google's People API via code grant flow-based authorization

(define (google-people-api-demo)
  (if (credentials-exist? google-code)
      ; authorization credentials found in the keychain
      (let-values (((client-id client-secret) (retrieve-credentials google-code))
                   ((server) (start-authorization-server)))
        ; Define authorization client for Google using a code grant flow
        (define google
          (make-oauth2 'code-grant
                       `((client_id . ,client-id)
                         (client_secret . ,client-secret)
                         (authorize_uri . "https://accounts.google.com/o/oauth2/auth")
                         (token_uri . "https://www.googleapis.com/oauth2/v3/token")
                         (redirect_uris . #("http://localhost:3000"))
                         (scope . "profile")
                         (auth_embedded . ,embedded-auth-flow)
                         (keychain . ,remember-auth-tokens)
                         (verbose . #t)
                         (log . ,min-log-level))))
        ; Set up an OAuth 2.0 HTTP session that uses the client to authorize requests
        (define session (make-oauth2-session google #f #f #t))
        ; Define a GET request for retrieving user data
        (define request
          (make-http-request
            "https://people.googleapis.com/v1/people/me?personFields=names" "GET"))
        ; Send the request via a OAuth 2.0 session; this returns a future containing
        ; the response of the request (or an error if the request failed)
        (define result (oauth2-session-send request session))
        ; Retrieve the body of the HTTP response from the `result` future; this will
        ; block until the response has been received.
        (define response (http-response-content (future-get result)))
        ; Stop the authorization server
        (stop-authorization-server server)
        ; Return response as a JSON object
        (bytevector->json response))
      ; client id and secret are unknown
      (begin
        (display "credentials unknown; use provide-credentials to set client id and secret")
        (newline))))

;;; Access GitHub API via code grant flow-based authorization

(define (github-api-demo)
  (if (credentials-exist? github-code)
      ; authorization credentials found in the keychain
      (let-values (((client-id client-secret) (retrieve-credentials github-code)))
        ; Define authorization client for GitHub using a code grant flow.
        ; As opposed to the Google API example, no server is needed to receive the
        ; auth tokens via a redirect. We use the ability for LispPad to receive such
        ; redirects natively via URI: lisppad://oauth/callback
        (define github
          (make-oauth2 'code-grant
                       `((client_id . ,client-id)
                         (client_secret . ,client-secret)
                         (authorize_uri . "https://github.com/login/oauth/authorize")
                         (token_uri . "https://github.com/login/oauth/access_token")
                         (redirect_uris . #("lisppad://oauth/callback"))
                         (scope . "user repo:status")
                         (secret_in_body . #t)
                         (auth_embedded . ,embedded-auth-flow)
                         (keychain . ,remember-auth-tokens)
                         (verbose . #t)
                         (log . ,min-log-level))))
        ; Set up an OAuth 2.0 HTTP session that uses the client to authorize requests
        (define session (make-oauth2-session github))
        ; Define a GET request for retrieving data about this user
        (define request (make-http-request "https://api.github.com/user" "GET"))
        ; Send the request via a OAuth 2.0 session; this returns a future containing
        ; the response of the request (or an error if the request failed)
        (define result (oauth2-session-send request session))
        ; Retrieve the body of the HTTP response from the `result` future; this will
        ; block until the response has been received.
        (define response (http-response-content (future-get result)))
        ; Return response as a JSON object
        (bytevector->json response))
      ; client id and secret are unknown
      (begin
        (display "credentials unknown; use provide-credentials to set client id and secret")
        (newline))))

;;; Access GitHub API via device grant flow-based authorization

(define (github-api-device-demo)
  (if (credentials-exist? github-device)
      ; authorization credentials found in the keychain
      (let-values (((client-id client-secret) (retrieve-credentials github-device)))
        ; Define authorization client for GitHub using a device grant flow.
        ; Here, no redirects happen and the authorization flow needs to poll for the
        ; availability of auth tokens.
        (define github
          (make-oauth2 'device-grant
                       `((client_id . ,client-id)
                         (client_secret . ,client-secret)
                         (device_authorize_uri . "https://github.com/login/device/code")
                         (authorize_uri . "https://github.com/login/oauth/authorize")
                         (token_uri . "https://github.com/login/oauth/access_token")
                         (scope . "user repo:status")
                         (secret_in_body . #t)
                         (keychain . ,remember-auth-tokens)
                         (verbose . #t)
                         (log . ,min-log-level))))
        ;; Determine information about how to authenticate via a web browser
        (define codes (future-get (oauth2-request-codes github)))
        (let ((url (cdr (assoc 'verification-url codes)))
              (code (cdr (assoc 'user-code codes))))
          ; Display authentication code
          (display* "Enter code '" code "' at URL " url "\n")
          ; Open authentication flow in external browser
          (open-url url)
          ; Poll authorization server to determine that the user authentication succeeded
          (future-get (oauth2-authorize! github))
          (display "Authorization succeeded\n")
          (let ()
            ; Set up an OAuth 2.0 HTTP session that uses the client to authorize requests
            (define session (make-oauth2-session github))
            ; Define a GET request for retrieving data about this user
            (define request (make-http-request "https://api.github.com/user" "GET"))
            ; Send the request via a OAuth 2.0 session; this returns a future containing
            ; the response of the request (or an error if the request failed)
            (define result (oauth2-session-send request session))
            ; Retrieve the body of the HTTP response from the `result` future; this will
            ; block until the response has been received.
            (define response (http-response-content (future-get result)))
            ; Return response as a JSON object
            (bytevector->json response))))
      ; client id and secret are unknown
      (begin
        (display "credentials unknown; use provide-credentials to set client id and secret")
        (newline))))
