# LispPad System iOS

Library `(lisppad system ios)` implements a simple API for LispPad Go-specific system procedures. Procedures matching the same functionality on macOS are also available via library `(lisppad system)`.

## Files

**(project-directory)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Returns the path to the documents directory of LispPad Go, where local files are stored.

**(icloud-directory)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Returns the path to the iclouds directory of LispPad Go, where files are stored that are synchronized via iCloud. This procedure returns `#f` if iCloud synchronization is not enabled.

**(icloud-list)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Returns a list of file paths of all LispPad-related files that are synchronized via iCloud. The paths are relative to the iCloud directory which can be obtained via procedure `icloud-directory`.

**(preview-file _path_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Shows a preview of the content of the file at the given file path _path_. Supported are many different types of files, including text files, images, PDF files, spreadsheets, etc.

**(share-file _path_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Shows a file share panel for the file at file path _path_, allowing the user to share the file with another application.

**(open-in-files-app _path_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Opens the Files app at the given file path _path_.


## Images

**(save-bitmap-in-library _img_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Saves the given bitmap-based image _img_ in the photo library of the user. The first time this procedure gets invoked, it asks the user for permission to access the photo library.

**(load-bitmaps-from-library)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  
**(load-bitmaps-from-library _max_)**  
**(load-bitmaps-from-library _max filter_)**  

Opens an image selector showing the images of the user's photo library. The user can select up to _max_ images from the photo library. These are returned by procedure `load-bitmaps-from-library` as a list of images. _filter_ is an image filter for narrowing down the types of images that are shown. _filter_ has either the form of:

   - a symbol, indicating a type of images (e.g. `bursts`, `panoramas`, `videos`),
   - `(not ` _filter_ `)`, indicating the inverse of _filter_,
   - `(and ` _filter_ ... `)`, indicating the conjunction of the given filters, or
   - `(or ` _filter_ ... `)`, indicating the disjunction of the given filters.

The following image type tags, expressed as a symbol, are supported: `bursts`, `cinematic-videos`, `depth-effect-photos`, `images`, `live-photos`, `panoramas`, `screen-recordings`, `screenshots`, `slomo-videos`, `timelapse-videos`, and `videos`. The default is `images`.

**(load-bytevectors-from-library _obj_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Opens an image selector showing the images of the user's photo library. The user can select up to _max_ images from the photo library. These are returned by procedure `load-bitmaps-from-library` as a list of bytevectors. _filter_ is an image filter for narrowing down the types of images that are shown, as documented for procedure `load-bitmaps-from-library`. `load-bytevectors-from-library` is useful if one is dealing with videos or other types of data that are not supported natively.


## Interaction

**(show-message-panel _title_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  
**(show-message-panel _title message_)**  
**(show-message-panel _title message button_)**  

Shows a message panel (an alert) with the given _title_ and _message_, and a single button labeled _button_ for dismissing it. If _title_ is `#f`, the title `"Alert"` is used. If _message_ is not provided or `#f`, no message text is shown. If _button_ is not provided or `#f`, the button is labeled `"OK"`. `show-message-panel` returns an unspecified value once the panel was dismissed by the user, or `#f` if the panel could not be displayed.

**(show-confirmation-panel _title message_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  
**(show-confirmation-panel _title message yes_)**  
**(show-confirmation-panel _title message yes no_)**  

Shows a confirmation panel with the given _title_ and _message_, providing two buttons for confirming (labeled _yes_) or rejecting (labeled _no_) the request. If _title_ is `#f`, the title `"Confirm"` is used. If _yes_ is not provided or `#f`, the confirmation button is labeled `"Yes"`. If _no_ is not provided or `#f`, the rejection button is labeled `"No"`. Procedure `show-confirmation-panel` returns `#t` if the user confirms the request, and `#f` if the user rejects it or the panel could not be displayed.

**(show-choice-panel _title message options_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  
**(show-choice-panel _title message options selected_)**  
**(show-choice-panel _title message options selected confirm_)**  

Shows a choice panel with the given _title_ and _message_, letting the user pick one alternative from list _options_. Each element of _options_ is either a string, or a pair whose first component is a string used as the label of the alternative. _selected_ is a string identifying the label of the alternative that is selected initially; if _selected_ is not provided or `#f`, no alternative is pre-selected. _confirm_ is the label of the button used to confirm the selection; the default is `"Select"`. Procedure `show-choice-panel` returns the zero-based index of the alternative chosen by the user within _options_, or `#f` if the choice was cancelled or the panel could not be displayed.

**(show-input-panel _title message_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  
**(show-input-panel _title message initial_)**  
**(show-input-panel _title message initial placeholder_)**  
**(show-input-panel _title message initial placeholder confirm_)**  

Shows an input panel with the given _title_ and _message_, letting the user enter a line of text. _initial_ is the text shown initially in the input field; the default is the empty string. _placeholder_ is a placeholder text shown when the input field is empty; the default is the empty string. _confirm_ is the label of the button used to confirm the input; the default is `"OK"`. Procedure `show-input-panel` returns the string entered by the user, or `#f` if the input was cancelled or the panel could not be displayed.

**(show-date-panel _title message type_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  
**(show-date-panel _title message type initial_)**  
**(show-date-panel _title message type initial range_)**  
**(show-date-panel _title message type initial range tz_)**  
**(show-date-panel _title message type initial range tz confirm_)**  
**(show-date-panel _title message type initial range tz confirm cancel_)**  

Shows a date panel with the given _title_ and _message_, letting the user pick a date, a range of dates, or several dates, depending on _type_. _type_ is one of the symbols `single`, `range`, or `multiple`:

   - If _type_ is `single`, _initial_ is either `#f` (no date pre-selected) or a date-time object representing the initially selected date. `show-date-panel` returns a date-time object for the date picked by the user, or `#f` if the panel was cancelled.
   - If _type_ is `range`, _initial_ is either `#f` (no range pre-selected) or a pair of two date-time objects representing the lower and upper bound of the initially selected range. `show-date-panel` returns a pair of two date-time objects for the range picked by the user, or `#f` if the panel was cancelled.
   - If _type_ is `multiple`, _initial_ is either `#f` (no dates pre-selected) or a list of date-time objects representing the initially selected dates. `show-date-panel` returns a list of date-time objects for the dates picked by the user, or `#f` if the panel was cancelled.

_range_ restricts the dates that can be selected to a given interval. It is either `#f` (no restriction) or a pair of two date-time objects representing the lower and upper bound of the selectable interval. _tz_ specifies the time zone used for interpreting and returning date-time values. It is either `#f` (the current, operating-system defined time zone is used), a number representing an offset from GMT in seconds, a symbol referring to a time zone abbreviation (e.g. `PST`), or a string referring to a time zone identifier (e.g. `"America/Los_Angeles"`) or a time zone abbreviation. If _title_ or _message_ is `#f`, no title, respectively no message, is shown. _confirm_ and _cancel_ are the labels of the buttons used to confirm (default `"Select"`) and cancel (default `"Cancel"`) the panel. Procedure `show-date-panel` also returns `#f` if the panel could not be displayed.

**(show-preview-panel _obj_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  
**(show-preview-panel _obj type_)**  

Shows a preview of _obj_ when possible. Supported are the following types of data: strings (textual data), bytevectors (binary data), styled text, images, and drawings. For strings and bytevectors it is important that parameter _type_ is used to narrow down the type of content. _type_ is a string representing a "file extension". Supported are at least: `"png"`, `"jpg"`, `"jpeg"`, `"gif"`, `"bmp"`, `"tif"`, `"tiff"`, `"text"`, `"txt"`, `"markdown"`, `"md"`, `"html"`, `"rtf"`, and `"rtfd"`. Other _type_ extensions might work.

**(show-share-panel _obj_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  
**(show-share-panel _obj type_)**  

Shows a panel for sharing _obj_ with other applications when possible. Supported are the following types of data: strings (textual data), bytevectors (binary data), styled text, images, and drawings. For strings and bytevectors it is important that parameter _type_ is used to narrow down the type of content. _type_ is a string representing a "file extension". Supported are at least: `"png"`, `"jpg"`, `"jpeg"`, `"gif"`, `"bmp"`, `"tif"`, `"tiff"`, `"text"`, `"txt"`, `"markdown"`, `"md"`, `"html"`, `"rtf"`, and `"rtfd"`. Other _type_ extensions might work.

**(show-load-panel _prompt folders filetypes_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Displays a file load panel with the given _prompt_ message. _folders_ is a boolean argument; it should be set to `#t` if the user is required to select a folder. _filetypes_ is a list of suffixes of selectable file types.

**(show-save-panel _prompt_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  
**(show-save-panel _prompt path_)**  
**(show-save-panel _prompt path locked_)**  

Displays a file save panel with the given _prompt_ message. _path_ might refer to a pre-selected file. Boolean argument _locked_ determines if the folder (provided via _path_) may be changed or not.

**(show-interpreter-tab _tab_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  
**(show-interpreter-tab _tab canvas_)**  

LispPad Go has three interpreter views: the console view, the log view, and the canvas view. Procedure `show-interpreter-tab` enables programmatic navigation between these three views. _tab_ is one of the following three symbols: `console`, `log`, and `canvas`. If _tab_ is `canvas`, then a second argument _canvas_ can be provided referring to a canvas to select.

**(show-help _name_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Shows documentation for identifier _name_ (symbol or string), if available.


## Canvases

A canvas shows a drawing in the canvas view of the interpreter. The following parameters can be configured for every canvas: the drawing, the size of the canvas, a scale factor (default is 1.0), and an optional background color. Canvases are identified by a fixnum identifier.

**(make-canvas _drawing size_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  
**(make-canvas _drawing size name_)**  
**(make-canvas _drawing size name color_)**  

Creates a new canvas of _size_ showing _drawing_. String _name_ is used to identify the canvas in the user interface. If _name_ is not provided, a unqiue name is generated. _color_ is the background color of the new canvas. `make-canvas` returns a canvas identifier (fixnum), which is used to refer to canvases in the API.

**(use-canvas _drawing size_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  
**(use-canvas _drawing size name_)**  
**(use-canvas _drawing size name color_)**  

Creates or reuses a canvas of _size_ showing _drawing_. If there is already an existing canvas of the same _name_, it is reused and reconfigured. Otherwise, a new canvas is created. _color_ is the background color of the canvas. `use-canvas` returns a canvas identifier (fixnum), which is used to refer to canvases in the API.

**(close-canvas _canvas_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Closes _canvas_. _canvas_ is either a canvas identifier (fixnum) or it is a name of a canvas (string). `close-canvas` returns `#t` if a canvas was closed, otherwise `#f` is returned.

**(canvas-name _canvas_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Returns the name of _canvas_ as a string. _canvas_ is either a canvas identifier (fixnum) or it is a name of a canvas (string). It is an error if no matching canvas was found.

**(set-canvas-name! _canvas name_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Sets the name of _canvas_ to string _name_. _canvas_ is either a canvas identifier (fixnum) or it is a name of a canvas (string). It is an error if no matching canvas was found.

**(canvas-size _canvas_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Returns the size of _canvas_. _canvas_ is either a canvas identifier (fixnum) or it is a name of a canvas (string). It is an error if no matching canvas was found.

**(set-canvas-size! _canvas size_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Sets the size of _canvas_ to _size_. _canvas_ is either a canvas identifier (fixnum) or it is a name of a canvas (string). It is an error if no matching canvas was found.

**(canvas-scale _canvas_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Returns the scale factor used by _canvas_. The default is 1.0. _canvas_ is either a canvas identifier (fixnum) or it is a name of a canvas (string). It is an error if no matching canvas was found.

**(set-canvas-scale! _canvas scale_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Sets the scale factor used by _canvas_ to number _scale_. _canvas_ is either a canvas identifier (fixnum) or it is a name of a canvas (string). It is an error if no matching canvas was found.

**(canvas-background _canvas_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Returns the background color of _canvas_ if one was defined, or `#f` if no background color was set. _canvas_ is either a canvas identifier (fixnum) or it is a name of a canvas (string). It is an error if no matching canvas was found.

**(set-canvas-background! _canvas color_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Sets the background color of _canvas_ to _color_ (color or `#f`). _canvas_ is either a canvas identifier (fixnum) or it is a name of a canvas (string). It is an error if no matching canvas was found.

**(canvas-drawing _canvas_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Returns the drawing shown by _canvas_. _canvas_ is either a canvas identifier (fixnum) or it is a name of a canvas (string). It is an error if no matching canvas was found.

**(set-canvas-drawing! _canvas drawing_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Sets the background color of _canvas_ to _drawing_. _canvas_ is either a canvas identifier (fixnum) or it is a name of a canvas (string). It is an error if no matching canvas was found.


## Sessions

**(session-id)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Returns a unique fixnum (within LispPad Go) identifying the interpreter session. The number changes when the interpreter is reset or the application is restarted.

**(session-name)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Returns the name of the LispPad session which executes this function. This name is customizable on macOS. On iOS, the name is generated using the session id.

**(session-log _time sev str_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  
**(session-log _time sev str tag_)**  

Logs the message _str_ with severity _sev_ at the given timestamp _time_ (a double value) in the session log. _sev_ is one of the following symbols: `debug`, `info`, `warn`, `error`, or `fatal`.


## Environment

**(screen-size)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Returns the screen size of the screen of the device running LispPad Go.

**(dark-mode?)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Return `#t` if the device on which LispPad Go is running is using _dark mode_; returns `#f` otherwise.
