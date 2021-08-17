# LispPad System

Library `(lisppad system)` implements a simple API for LispPad system functions.

**(open-in-files-app _path_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Opens the Files app at the given file path _path_.

**(save-bitmap-in-library _img_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Saves the given bitmap-based image _img_ in the photo library of the user. The first time this procedure gets invoked, it asks the user for permission to access the photo library.

**(screen-size)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Returns the screen size of the screen of the device running LispPad Go.

**(project-directory)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Returns the path to the documents directory of LispPad Go.

**(dark-mode?)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Return `#t` if the device on which LispPad Go is running is using _dark mode_; returns `#f` otherwise.

**(sleep _sec_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Sleeps for _sec_ seconds.
