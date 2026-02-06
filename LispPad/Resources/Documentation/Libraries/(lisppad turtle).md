# LispPad Turtle

Library `(lisppad turtle)` implements a simple graphics pane (a graphics window on macOS, a canvas on iOS) for displaying turtle graphics. The library supports one graphics pane per LispPad session which gets initialized by invoking `init-turtle`. `init-turtle` will create a new turtle and display its drawing on a graphics pane. If there is already an existing graphics pane with the given title, it will be reused. Turtle graphics can be reset via `reset-turtle`.

As opposed to library `(lispkit draw turtle)`, this library supports an _indicator_, i.e. a symbol that shows where the turtle is currently located and whether the pen is up or down. By default, an arrow is used as an indicator. A yellow arrow indicates that the pen is down, a white translucent arrow indicates that the pen is up.

Once `init-turtle` was called, the following functions can be used to move the turtle across the plane:

   - `(indicator-on)`: Show the turtle indicator
   - `(indicator-off)`: Hide the turtle indicator
   - `(pen-up)`: Lifts the turtle
   - `(pen-down)`: Drops the turtle
   - `(pen-color color)`: Sets the current color of the turtle
   - `(pen-size size)`: Sets the size of the turtle pen
   - `(home)`: Moves the turtle back to the origin
   - `(move x y)`: Moves the turtle to position `(x, y)`
   - `(heading angle)`: Sets the angle of the turtle (in radians)
   - `(turn angle)`: Turns the turtle by the given angle (in radians)
   - `(left angle)`: Turn left by the given angle (in radians)
   - `(right angle)`: Turn right by the given angle (in radians)
   - `(forward distance)`: Moves forward by `distance` units drawing a line if the pen is down
   - `(backward distance)`: Moves backward by `distance` units drawing a line if the pen is down
   - `(arc angle radius)`: Turns the turtle by the given angle (in radians) and draws an arc with `radius` around the current turtle position.

This library provides a simplified, interactive version of the API provided by library `(lispkit draw turtle)`.


## Setup

**(init-turtle)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  
**(init-turtle scale)**  
**(init-turtle scale title)**

Initializes a new turtle and displays its drawing in a graphics pane (a graphics window on macOS, a canvas on iOS). `init-turtle` gets two optional arguments: `scale` and `title`. `scale` is a scaling factor which determines the size of the turtle drawing. `title` is a string that defines the name of the graphics pane used by the turtle graphics. It also acts as the identify of the turtle graphics pane; i.e. it won't be possible to have two sessions with the same name but a different graphics pane.

**(reset-turtle)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Closes the graphics pane and resets the turtle library.

**(turtle-window)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Returns the window associated with the current turtle. Returns `#f` if there is no associated window.

**(turtle-drawing)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Returns the drawing associated with the current turtle.

**(turtle-indicator)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Returns the turtle indicator that is currently used.


## Indicators

Turtle indicators are defined and configured via record `<indicator>`. Instances are created using `make-indicator`. `empty-indicator` is a predefined indicator showing nothing. `arrow-indicator` is a constructor for creating arrow indicators of different sizes.

**indicator-type-tag** <span style="float:right;text-align:rigth;">[constant]</span>  

Symbol representing the `indicator` type. The `type-for` procedure of library `(lispkit type)` returns this symbol for all indicator objects.

**(indicator? _obj_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Returns `#t` if _obj_ is a turtle indicator object; returns `#f` otherwise.

**(make-indicator _shape width stroke-color up-color down-color_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Returns a new turtle indicator of given _shape_ and stroke _width_. _stroke-color_ is the color used to draw the shape, _up-color_ is the color used to fill the shape when the pen is up, and _down-color_ is the color used to fill the shape when the pen is down.

**empty-indicator** <span style="float:right;text-align:rigth;">[constant]</span>  

An indicator which is not drawing anything. This is used to disable indicators fully.

**(make-arrow-indicator)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  
**(make-arrow-indicator _size_)**  
**(make-arrow-indicator _size width_)**  
**(make-arrow-indicator _size width stroke-color_)**  
**(make-arrow-indicator _size width stroke-color up-color_)**  
**(make-arrow-indicator _size width stroke-color up-color down-color_)**  

Returns a new arrow indicator. _size_ is the size of the arrow shape (12 is the default), _width_ is the stroke width used to draw the shape, _stroke-color_ is the color used to draw the shape, _up-color_ is the color used to fill the shape when the pen is up, and _down-color_ is the color used to fill the shape when the pen is down.


## Drawing

**(indicator-on)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Show the turtle indicator.

**(indicator-off)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Hide the turtle indicator.

**(pen-up)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Lifts the turtle from the plane. Subsequent `forward` and `backward` operations don't lead to lines being drawn. Only the current coordinates are getting updated.

**(pen-down)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Drops the turtle onto the plane. Subsequent `forward` and `backward` operations will lead to lines being drawn.

**(pen-color _color_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Sets the drawing color of the turtle to _color_. _color_ is a color object as defined by library `(lispkit draw)`.

**(pen-size _size_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Sets the pen size of the turtle to _size_. The pen size corresponds to the width of lines drawn by `forward` and `backward`.

**(home)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Moves the turtle to its home position.

**(move _x y_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Moves the turtle to the position described by the coordinates _x_ and _y_.

**(heading _angle_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Sets the heading of the turtle to _angle_. _angle_ is expressed in terms of degrees.

**(turn _angle_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Adjusts the heading of the turtle by _angle_ degrees.

**(right _angle_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Adjusts the heading of the turtle by _angle_ degrees.

**(left _angle_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Adjusts the heading of the turtle by _-angle_ degrees.

**(forward _distance_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Moves the turtle forward by _distance_ units drawing a line if the pen is down.

**(backward _distance_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Moves the turtle backward by _distance_ units drawing a line if the pen is down.

**(arc _angle radius_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Turns the turtle by the given _angle_ (in radians) and draws an arc with _radius_ around the current turtle position if the pen is down.
