# Changelog

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
