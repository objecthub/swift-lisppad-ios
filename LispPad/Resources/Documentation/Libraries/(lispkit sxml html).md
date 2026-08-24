# LispKit SXML HTML

Library `(lispkit sxml html)` implements a permissive, streaming HTML parser. Unlike the strict XML parser of library `(lispkit sxml xml)`, this parser is designed to cope with the malformed and inconsistent markup that is commonplace in real-world HTML documents: it inserts "virtual" start and end tags as needed to keep the parsed document a properly nested tree, aiming for behavior comparable to how common web browsers parse HTML.

The parser is implemented as a tree-folding parser (in the style of `foldts`) with an interface modeled after the SSAX parser of library `(lispkit sxml xml)`: a low-level, callback-based procedure `make-html-parser` for building custom parsers, plus two ready-to-use convenience procedures, `html->sxml` and `html-strip`, built on top of it.


**(make-html-parser _key val ..._)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Returns a new HTML parser, a procedure `(seed [port])`, that parses the HTML document from input port _port_ (or, if _port_ is a string, an input port opened on that string), invoking the given callbacks while folding over the document tree. If _port_ is not provided, the parser reads from the current input port (as defined by `current-input-port` of library `(lispkit port)`). _seed_ is the initial seed value, threaded through the callbacks and returned as the final result once the whole document (or fragment) has been parsed.

`make-html-parser` accepts the following keyword arguments; all of them are optional:

   - `start:` A procedure `(tag attrs seed virtual?)`, invoked when a start-tag is encountered. _tag_ is the (lower-cased) tag name symbol, _attrs_ is the list of `(name value)` attribute pairs, _seed_ is the current seed, and _virtual?_ is `#t` if this start-tag was inserted by the parser to fix up the document tree (rather than being present literally in the source). The procedure returns a new seed to be used while parsing the children of the element. The default handler returns _seed_ unchanged.
   - `end:` A procedure `(tag attrs parent-seed seed virtual?)`, invoked when an end-tag is encountered (including virtual ones inserted for unclosed elements). _attrs_ are the attributes of the corresponding start-tag, _parent-seed_ is the seed that was passed to the `start:` handler, _seed_ is the seed resulting from parsing the element's children, and _virtual?_ is `#t` if the end-tag was inserted by the parser. The procedure returns the seed to be used for further sibling elements. The default handler returns _seed_ unchanged.
   - `text:` A procedure `(text seed)`, invoked with a chunk of entity-decoded character content. May be called multiple times between a start-tag and its end-tag; results need to be accumulated by the handler itself. The default handler returns _seed_ unchanged.
   - `comment:` A procedure `(text seed)`, invoked with the content of an HTML comment. The default handler returns _seed_ unchanged.
   - `decl:` A procedure `(name attrs seed)`, invoked for a declaration such as `<!DOCTYPE ...>`. The default handler returns _seed_ unchanged.
   - `process:` A procedure `(list seed)`, invoked for a processing instruction, where _list_ is a two-element list of the (lower-cased) PI target symbol (or `#f`) and the PI body string. The default handler returns _seed_ unchanged.
   - `entity:` A procedure `(name-or-num seed)` that converts a named or numeric character entity (given either as a string name or an integer code point) into a string. The default handler looks _name-or-num_ up in _entities_ and falls back to re-emitting the original `&name;` notation if the entity is unknown.
   - `entities:` An association list of `(name . string)` pairs used to resolve named entity references (in addition to the numeric `&#NNNN;` / `&#xHHHH;` forms, which are always understood). Defaults to a small built-in table covering `amp`, `quot`, `lt`, `gt`, `apos`, and `nbsp`.
   - `tag-levels:`, `unnestables:`, `bodyless:`, `literals:`, `terminators:` Advanced parameters controlling the error-recovery heuristics used to cope with malformed markup, namely the relative nesting levels of tags (used to decide when to force-close an open tag), tags that may not be nested within themselves (such as `p`, `li`, `td`, `tr`), tags that never have a body or a closing tag (such as `img`, `hr`, `br`), tags whose content is read verbatim up to a matching closing tag rather than being parsed as markup (such as `script`, `xmp`), and tags whose content extends to the end of the document (such as `plaintext`). These rarely need to be customized.

```scheme
(define (html-strip . o)
  (call-with-output-string
    (lambda (out)
      (let ((parse
              (make-html-parser
                'start: (lambda (tag attrs seed virtual?) seed)
                'end:   (lambda (tag attrs parent-seed seed virtual?) seed)
                'text:  (lambda (text seed) (display text out)))))
        (apply parse (cons #f #f) o)))))
```

**(html-\>sxml)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  
**(html-\>sxml _port_)**  

Parses the HTML document available from input port _port_ (or a string, in which case an input port is opened on it) and returns its content as an SXML tree, wrapped in a `*TOP*` element (see library `(lispkit sxml)` for details on the SXML representation). If _port_ is not provided, `html->sxml` reads from the current input port. Declarations, processing instructions, and comments are represented, respectively, as `(*DECL* name attr ...)`, `(*PI* target body)`, and `(*COMMENT* text)` nodes.

```scheme
(import (lispkit sxml html) (lispkit port))

(call-with-port (open-input-string "<ul><li>one</li><li>two</li></ul>")
  (lambda (port) (html->sxml port)))
  ⇒ (*TOP* (ul (li "one") (li "two")))

;; A missing closing tag for <b> is automatically fixed up:
(call-with-port (open-input-string "<p>Hello, <b>World</p>")
  (lambda (port) (html->sxml port)))
⇒ (*TOP* (p "Hello, " (b "World")))
```

**(html-strip)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  
**(html-strip _port_)**  

Parses the HTML document available from input port _port_ (or a string) and returns a string containing all of its text content, with every tag removed. No whitespace reduction or other post-processing of the extracted text is performed. If _port_ is not provided, `html-strip` reads from the current input port.

```scheme
(html-strip "<p>5 &lt; 7 &amp; 7 &gt; 5</p>")
⇒ "5 < 7 & 7 > 5"
```
