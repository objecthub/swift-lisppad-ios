# LispPad Audio

Library `(lisppad audio)` implements an API for playing audio files in LispPad. Audio playback is managed through _audio player_ objects. A player is created from an audio file path or a bytevector containing audio data, and exposes controls for playback, volume, stereo panning, playback rate, and looping.

## Audio Players

**(make-audio-player _source_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  
**(make-audio-player _source file-type_)**  
**(make-audio-player _source file-type rate?_)**  

Creates and returns a new _audio-player_ object. _source_ is either a string specifying the path of an audio file, or a bytevector containing raw audio data. _file-type_ is an optional string providing a file-type hint for the audio decoder (e.g. `"mp3"`, `"aac"`, `"wav"`). If _file-type_ is `#f` or omitted, the type is inferred automatically. If _rate?_ is `#t`, variable-rate playback is enabled, allowing `set-audio-player-rate!` to change the playback speed. Variable-rate support must be enabled at creation time; it cannot be enabled after the player is created.

**(audio-player? _obj_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Returns `#t` if _obj_ is an _audio-player_ object, `#f` otherwise.

## Playback Control

**(play-audio _player_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  
**(play-audio _player time_)**  

Starts or resumes playback on _player_. If _time_ is provided, it specifies a delay in seconds at which playback should begin, allowing multiple players to be synchronized. Resets any previously recorded playback completion status.

**(pause-audio _player_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Pauses playback of _player_. The current playback position is preserved; playback can be resumed with `play-audio`.

**(stop-audio _player_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Stops playback of _player_ and rewinds to the beginning.

## Playback State

**(audio-player-playing? _player_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Returns `#t` if _player_ is currently playing audio, `#f` otherwise.

**(audio-player-success? _player_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Returns the completion status of the most recent playback. Returns `#t` if playback finished successfully, `#f` if it was interrupted or failed, and `()` (the empty list) if no playback has finished yet or playback is still in progress.

**(audio-player-decode-error _player_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Returns the decode error that occurred during the most recent playback, or `#f` if no decode error was recorded.

**(audio-player-duration _player_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Returns the total duration of the audio loaded into _player_, in seconds, as a flonum.

**(audio-player-elapsed _player_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Returns the current playback position of _player_ in seconds, as a flonum.

**(set-audio-player-elapsed! _player time_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Seeks _player_ to position _time_ (in seconds). _time_ is clamped to the range `[0.0, duration]`.

## Playback Properties

**(audio-player-volume _player_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Returns the current volume of _player_ as a flonum in the range `[0.0, 1.0]`, where `0.0` is silent and `1.0` is full volume.

**(set-audio-player-volume! _player vol_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  
**(set-audio-player-volume! _player vol fade_)**  

Sets the volume of _player_ to _vol_, a number clamped to `[0.0, 1.0]`. If _fade_ is provided, it specifies a fade duration in seconds over which the volume change is applied. Negative fade values are treated as zero.

**(audio-player-pan _player_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Returns the stereo pan position of _player_ as a flonum in the range `[-1.0, 1.0]`, where `-1.0` is fully left, `0.0` is center, and `1.0` is fully right.

**(set-audio-player-pan! _player pan_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Sets the stereo pan position of _player_ to _pan_, a number clamped to `[-1.0, 1.0]`.

**(audio-player-rate _player_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Returns the current playback rate of _player_ as a flonum. A rate of `1.0` is normal speed; `0.5` is half speed; `2.0` is double speed. Rate control is only meaningful if the player was created with _rate?_ set to `#t`.

**(set-audio-player-rate! _player rate_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Sets the playback rate of _player_ to _rate_, a number clamped to `[0.5, 2.0]`. The player must have been created with variable-rate support enabled (see `make-audio-player`).

**(audio-player-loops _player_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Returns the loop count of _player_ as an integer. A value of `0` means the audio plays once without looping. A positive value _n_ means the audio plays _n + 1_ times in total. A negative value means the audio loops indefinitely until stopped.

**(set-audio-player-loops! _player n_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>   

Sets the loop count of _player_ to the integer _n_. A value of `0` means the audio plays once without looping. A positive value _n_ means the audio plays _n + 1_ times in total. A negative value means the audio loops indefinitely until stopped.
