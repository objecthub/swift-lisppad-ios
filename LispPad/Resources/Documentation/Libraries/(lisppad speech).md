# LispPad Speech

Library `(lisppad speech)` provides a speech synthesis API which parses text and converts it into audible speech. The conversion is based on factors like the language, the _voice_, and a range of parameters which are all aggregated by _speaker_ objects.


## Speech synthesis

**(speak _text_)** <span style="float:right;text-align:rigth;">[procedure]</span>   
**(speak _text speaker_)**   

Speaks the given string _text_ using with the _speaker_ object providing all speech synthesis parameters. If _speaker_ is not provided, the value of parameter object `current-speaker` is used.

**(phonemes _text_)** <span style="float:right;text-align:rigth;">[procedure]</span>   
**(phonemes _text speaker_)**   

Converts the given natural language string _text_ into a string of phonemes using the given _speaker_. If _speaker_ is not provided, the value of parameter object `current-speaker` is used.

Speakers can be configured to speak phonemes instead of natural language via procedure `speaker-interpret-phonemes!`.


## Speakers

A _speaker_ is an object defining speech synthesis parameters. There is a _current speaker_ which is used by default, unless a speaker is explicitly specified for the various procedures that require a speaker parameter.

A speaker object has the following components:

   - an immutable voice,
   - a mutable speaking rate,
   - a mutable speaking volume,
   - a flag determining whether the speaker interprets text or phonemes,
   - a flag determining how numbers are interpreted, as well as
   - a speaking pitch.

**current-speaker** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[parameter object]</span>  

Defines the _current speaker_, which is used as a default by all functions for which the speaker argument is optional. If there is no current speaker, this parameter is set to `#f`.

**(speaker? _obj_)** <span style="float:right;text-align:rigth;">[procedure]</span>   

Returns `#t` if _obj_ is a speaker object; otherwise `#f` is returned.

**(make-speaker)** <span style="float:right;text-align:rigth;">[procedure]</span>   
**(make-speaker _voice_)**   

Returns a new speaker for the given _voice_. If _voice_ is not provided, a default voice, specified at the operating system level, is being used. Speakers are stateful objects which can be configured with a number of procedures: `set-speaker-rate!`, `set-speaker-volume!`, `set-speaker-interpret-phonemes!`, `set-speaker-interpret-numbers!`, and `set-speaker-pitch!`.

**(speaker-voice)** <span style="float:right;text-align:rigth;">[procedure]</span>   
**(speaker-voice _speaker_)**   

Returns the voice of _speaker_. If _speaker_ is not provided, the parameter object `current-speaker` is used.

**(speaker-rate)** <span style="float:right;text-align:rigth;">[procedure]</span>   
**(speaker-rate _speaker_)**   

Returns the speaking rate of _speaker_. If _speaker_ is not provided, the parameter object `current-speaker` is used.

**(set-speaker-rate! _rate_)** <span style="float:right;text-align:rigth;">[procedure]</span>   
**(set-speaker-rate! _rate speaker_)**   

Sets the speaking rate of _speaker_ to number _rate_. If _speaker_ is not provided, the parameter object `current-speaker` is used.

**(speaker-volume)** <span style="float:right;text-align:rigth;">[procedure]</span>   
**(speaker-volume _speaker_)**   

Returns the volume of _speaker_ as a flonum ranging from 0.0 to 1.0.  If _speaker_ is not provided, the parameter object `current-speaker` is used.

**(set-speaker-volume! _volume_)** <span style="float:right;text-align:rigth;">[procedure]</span>   
**(set-speaker-volume! _volume speaker_)**   

Sets the volume of _speaker_ to number _volume_ which is a flonum between 0.0 and 1.0. If _speaker_ is not provided, the parameter object `current-speaker` is used.

**(speaker-interpret-phonemes)** <span style="float:right;text-align:rigth;">[procedure]</span>   
**(speaker-interpret-phonemes _speaker_)**   

Returns `#t` if _speaker_ interprets phonemes instead of natural language text.  If _speaker_ is not provided, the parameter object `current-speaker` is used.

**(set-speaker-interpret-phonemes! _phoneme?_)** <span style="float:right;text-align:rigth;">[procedure]</span>   
**(set-speaker-interpret-phonemes! _phoneme? speaker_)**   

If boolean argument _phoneme?_ is `#f`, _speaker_ is configured to interpret natural language. If _phoneme?_ is set to any other value, the _speaker_ is interpreting phonemes instead. If _speaker_ is not provided, the parameter object `current-speaker` is used.

**(speaker-interpret-numbers)** <span style="float:right;text-align:rigth;">[procedure]</span>   
**(speaker-interpret-numbers _speaker_)**   

Returns `#t` if _speaker_ interprets numbers as a natural language speaker would do ("100" is spoken as "hundred"). If it returns `#f`, _speaker_ decomposes numbers into a sequence of digits and speaks them individually ("100" is spoken as "one zero zero"). If _speaker_ is not provided, the parameter object `current-speaker` is used.

**(set-speaker-interpret-numbers! _natural?_)** <span style="float:right;text-align:rigth;">[procedure]</span>   
**(set-speaker-interpret-numbers! _natural? speaker_)**   

Sets the number interpretation of _speaker_ to boolean _natural?_. If _natural?_ is `#t` _speaker_ will interpret numbers as a natural language speaker would do ("100" is spoken as "hundred"). If _natural?_ is `#f`, _speaker_ decomposes numbers into a sequence of digits and speaks them individually ("100" is spoken as "one zero zero"). If _speaker_ is not provided, the parameter object `current-speaker` is used.

**(speaker-pitch)** <span style="float:right;text-align:rigth;">[procedure]</span>   
**(speaker-pitch _speaker_)**   

Returns the pitch of _speaker_ as a pair of two flonums: the car is the base of the pitch, and the cdr is the modulation of the pitch. If _speaker_ is not provided, the parameter object `current-speaker` is used.

**(set-speaker-pitch! _pitch_)** <span style="float:right;text-align:rigth;">[procedure]</span>   
**(set-speaker-pitch! _pitch speaker_)**   

Sets the pitch of _speaker_ to the pair of flonums _pitch_ whose car is the base of the pitch, and the cdr is the modulation of the pitch. If _speaker_ is not provided, the parameter object `current-speaker` is used.


## Voices

Voices are provided by the operating system and library `(lispkit speech)` does not have an explicit representation as objects. Symbols are used as identifiers for voices. For example, `com.apple.speech.synthesis.voice.Alex` refers to the default US voice.

A voice has the following characteristics:

   - Name (string)
   - Age (fixnum)
   - Gender (`male` or `female`)
   - Locale (symbol, e.g. `en_US`)

Library `(lispkit system)` provides means to handle _locales_, including language and country codes.

**(voice)** <span style="float:right;text-align:rigth;">[procedure]</span>   
**(voice _name_)**   
**(voice _id_)**   

Returns a symbol identifying the voice specified by the arguments of `voice`. If no argument is provided, an indentifier for the default voice is returned. If a _name_ string is provided, then an identifier for a voice whose name is _name_ is returned, or `#f` if no such voice exists. If an _id_ symbol is provided, then an identifier for a voice whose identifier matches _id_ is returned, or `#f` if no such voice exists. 

**(available-voices)** <span style="float:right;text-align:rigth;">[procedure]</span>   
**(available-voices _lang_)**   
**(available-voices _lang gender_)**   

Returns a list of symbols identifying voices matching the given language filter _lang_ and gender filter _gender_. Both _lang_ and _gender_ are symbols. _lang_ should either be a language or locale identifier. It can also be set to `#f` if only a gender filter is needed. _gender_ should either be symbol `male` or `female`.

```scheme
(available-voices 'en)
⇒ (com.apple.speech.synthesis.voice.Alex com.apple.speech.synthesis.voice.daniel com.apple.speech.synthesis.voice.fiona com.apple.speech.synthesis.voice.Fred com.apple.speech.synthesis.voice.karen com.apple.speech.synthesis.voice.moira com.apple.speech.synthesis.voice.rishi com.apple.speech.synthesis.voice.samantha com.apple.speech.synthesis.voice.tessa com.apple.speech.synthesis.voice.veena)
(available-voices (locale "en" "GB"))
⇒ (com.apple.speech.synthesis.voice.daniel)
```

**(available-voice? _obj_)** <span style="float:right;text-align:rigth;">[procedure]</span>   

Returns `#t` if _obj_ is a symbol identifying an available voice, otherwise `#f` is returned. This procedure fails if _obj_ is neither a symbol nor the value `#f`.

**(voice-name _voice_)** <span style="float:right;text-align:rigth;">[procedure]</span>   

Returns the name of the voice identified by symbol _voice_.

**(voice-age _voice_)** <span style="float:right;text-align:rigth;">[procedure]</span>   

Returns the age of the voice identified by symbol _voice_.

**(voice-gender _voice_)** <span style="float:right;text-align:rigth;">[procedure]</span>   

Returns the gender of the voice identified by symbol _voice_.

**(voice-locale _voice_)** <span style="float:right;text-align:rigth;">[procedure]</span>   

Returns the locale of the voice identified by symbol _voice_.
