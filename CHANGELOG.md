# Changelog

## 2.2.1 (2026-02-22)

- Allow executing commands by pressing return on hardware keyboards
- Revamped keyboard experience supporting a second extension focused on navigation
- Redesigned definition/document structure switchboard user experience
- Refreshed user experience for some panels
- Fixed inconsistent documentation font sizes
- Fixed bugs involving indentation and commenting features

## 2.2 (2026-02-15)

- Updated app icon
- New library and documentation browser
- New "center menu" in the editor
- Reimplemented canvas view to allow for more complex drawings
- Fixed bugs in the file organizer
- Allow overriding `Prelude.scm`
- Bug fixes involving `quasiquote` and `cond-expand`
- New library for handling locations: `(lispkit location)`
- New library for creating and editing PDF documents: `(lispkit pdf)`
- New library for solving computer vision problems: `(lispkit vision)`
- New libraries for processing/manipulating images: `(lispkit image)`, `(lispkit image process)`
- New library for drawing maps: `(lispkit draw map)`
- New library for making and drawing snapshots of web pages: `(lispkit draw web)`
- Extensions of libraries `(lispkit draw)`, `(lispkit core)`, `(lispkit enum)`, `(lispkit date-time)`, and `(lispkit object)`
- New sample code: `ImageComposition.scm`, `OCR.scm`, `MermaidDiagrams.scm`, `Pinterest.scm`
- Updated LispPad Library Reference
- Interpreter now based on LispKit 2.6.0

## 2.1 (2024-11-22)

- Fixed keyboard shortcuts
- Reimplemented edit menu
- Support separate sets of editor color schemes for light and dark mode
- Allow setting the appearance (light vs. dark) at the application level
- Extended available coding fonts
- Support for all major JSON standards via libraries `(lispkit json)` and `(lispkit json schema)`
- Support for HTTP-based networking via libraries `(lispkit http)`, `(lispkit http oauth)`, and `(lispkit http server)`
- Deeper integrations into macOS and iOS operating systems via libraries `(lispkit system keychain)` and `(lispkit system pasteboard)`
- Support for drawing a variety of different types of bar codes via library `(lispkit draw barcode)`
- New libraries: `(lispkit url)`, `(lispkit serialize)`, `(lispkit thread future)`, and `(lispkit thread shared-queue)`
- Extended libraries: `(lispkit box)`, `(lispkit thread)`, `(lispkit system)`, `(lispkit bytevector)`, `(lispkit markdown)`, `(lispkit dynamic)`, `(lispkit control)`
- New sample code: `Keychain.scm`, `WebAPIs.scm`, and `Webserver.scm`
- Updated LispPad Library Reference
- Interpreter now based on LispKit 2.5.0

## 2.0.1 (2024-03-03)

- Support sharing of canvases
- Support smarter parenthesis matching for Lisp code
- Reimplemented overflow menu of the editor, fixing bugs and providing new line-level features
- Reimplemented REPL command history (long-press on "Send" button)
- Reimplemented the "Load"/+ menu for reloading recent files and the editor buffer
- Log files being loaded into the interpreter
- Fixed cursor placement in the interpreter input
- Fixed bug preventing the editor buffer to be emptied when "New" was selected
- Fixed opening recent and starred files
- Improved consistency of icon usage with LispPad on macOS
- Updated LispPad Library Reference

## 2.0 (2024-01-15)

- Redesigned the navigation between interpreter and editor
- Redesigned the split screen mode for iPads, allowing free positioning of the splitter
- Redesigned file/directory browser fixing usability issues and supporting file previews
- Introduced drawing canvases (left-swipe in console) in addition to the log view (right-swipe in console)
- Libraries can be imported via a swipe in the Libraries view; support for library list refresh
- User experience bug fixes, especially involving modal sheets
- Ported universal formatting facility from Common Lisp and made it available via library `(lispkit format)`
- Library `(lispkit records)` now supports extensible records compatible to SRFI 131
- Made application scriptable via library `(lisppad system ios)`
- Extended libraries: `(lispkit system)`, `(lispkit port)`, `(lispkit bitset)`, `(lispkit system)`, `(lispkit draw)`, `(lispkit draw turtle)`, `(lispkit core)`, `(lispkit type)`, `(lispkit bytevector)`
- New libraries: `(lisppad system ios)`, `(lisppad turtle)`, `(lispkit format)`, `(lispkit crypto)`, `(lispkit archive tar)`, `(lispkit list set)`, `(srfi 239)`, `(srfi 235)`
- New sample code: `Fractals.scm`, `Blockchain.scm`
- Interpreter now based on LispKit 2.4.0

## 1.3.4 (2023-02-11)

- Improved management of recent files and favorites.
- Remember last edited file (can be switched off in the settings)
- Improved display of file names in the editor
- Fixed bug affecting bytevector copy procedures in library `(lispkit bytevector)`
- Extended library: `(lispkit graph)`
- New libraries: `(srfi 228)`, `(srfi 233)`, and `(srfi 236)`
- Interpreter now based on LispKit 2.3.2

## 1.3.3 (2022-12-27)

- User interface changes to optimize the look and feel for iOS 16, including revised key bindings
- Access to the log viewer in the console by swiping right
- New settings for defining the maximum stack size and the maximum number of active calls to trace upon errors
- New setting to prevent virtual keyboard extensions to be shown if there is a hardware keyboard
- Display call stack when errors are shown on the console
- Limit stack size to prevent application crashes
- Fixed bug leading to deadlocks when using text ports
- Fixed bug allowing to execute empty lists
- Fixed serious bug leading to an infinite loop when iterating through stack traces
- New procedure in library `(lispkit thread)`: `thread-max-stack`
- New library: `(lisppad draw map)`
- New sample code: `DisplayMap.scm`
- Interpreter now based on LispKit 2.3.1

## 1.3.2 (2022-09-21)

- iOS 16 bug fixes

## 1.3.1 (2022-08-15)

- Performance improvements: Optimized code generation for lambdas without captured expressions
- Fixed division by zero issues with truncate and floor procedures
- Made procedure open-file of library `(lispkit system)` work on iOS
- Extended libraries: `(lispkit core)`, `(lispkit string)`, `(lispkit math)`, `(lispkit type)`, `(lispkit enum)`, `(lispkit draw)`, and `(lispkit clos)`
- New libraries: `(lispkit math matrix)`, `(lispkit bitset)`, `(lispkit styled-text)`, `(lispkit draw chart bar)`, `(srfi 118)`, `(srfi 141)`, `(srfi 149)`, and `(srfi 232)`
- New sample code: `ObjectOrientation.scm`, `DrawBarCharts.scm`, and `StyledTextDoc.scm`
- Interpreter now based on LispKit 2.3.0

## 1.3.0 (2022-03-02)

- Allow setting font in preferences; allow for more granular choice of font sizes
- Multi-threaded evaluator, executing multiple virtual machines in parallel
- Go-inspired channels for synchronizing threads
- Revamp of math libraries, addressing incompatibilities and fixing numerous bugs
- New procedures in libraries `(lispkit math)`, `(lispkit math util)`, `(lispkit system)`, `(lispkit port)`, and `(lispkit debug)`
- New libraries: `(lispkit thread)`, `(lispkit thread channel)`, `(scheme flonum)`, `(srfi 18)`, `(srfi 144)`, `(srfi 208)`, and `(srfi 230)`
- Exceptions now include more information about the active call stack
- Interpreter now based on LispKit 2.2.0

## 1.2.2 (2021-12-17)

- Adjusted colors used in REPL to improve legibility
- Fixed bug leading to symbol definition views disappearing behind the keyboard

## 1.2.1 (2021-12-15)

- Integrated log viewer into console
- Increased stack size of interpreter
- Fixed file/editor loader
- Fixed scrolling within console
- Included new documentation for libraries `(lispkit prolog)`, `(lispkit math stats)`, `(lispkit math util)`, `(lispkit text-table)`, `(srfi 166)`, `(srfi 227)`, and `(srfi 229)`
- Interpreter now based on LispKit 2.1.0

## 1.2.0 (2021-10-02)

- Optimized user interface for iOS 15
- Improved synchronization with iCloud Drive
- New in-context documentation viewer
- Searchable Libraries view; include libraries that are not loaded
- Support for search/replace; save the search/replace history; enable case-insensitive search
- New procedures `icloud-directory` and `icloud-list` in library `(lisppad system)`
- Bug fixes in library `(lispkit location)`
- Interpreter now based on LispKit 2.0.3

## 1.1.2 (2021-08-19)

- Comprehensive support for keyboard shortcuts
- Keyboard shortcut documentation accessible via LispPad menu
- Fixed split view-related bugs (on iPadOS)
- New library `(lisppad location)` supporting geocoding and reverse geocoding
- New procedure `open-in-files-app` in library `(lisppad system)`
- New example code
- Interpreter now based on LispKit 2.0.2

## 1.1.1 (2021-07-03)

- Extended keyboard for editing Markdown and Scheme code
- Extended edit menu with support for looking up Scheme definitions in console and editor
- Syntax highlighting, parenthesis matching, automatic indentation in console
- Undo/redo support on iPhones
- Improved keyboard dismissal in console
- New example code
- Interpreter now based on LispKit 2.0.1

## 1.1.0 (2021-06-11)

- Console/editor split view on iPadOS
- Markdown document previewer
- Table of contents for markdown documents
- Display graphics directly in the console
- Support tighter line spacing in the console
- Display stack trace in console for errors
- Allow dismissing the keyboard in the editor view
- New library `(lispkit archive zip)` for creating, reading, and writing zip archives.
 
## 1.0.1 (2021-05-06)

- Support opening files in LispPad Go triggered by other apps
- Fixed various dark mode-related bugs
- File handling improvements and bug fixes
- Text editor display improvements

## 1.0.0 (2021-05-01)

- Initial version
