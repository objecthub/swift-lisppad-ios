# LispKit SXML XML

Library `(lispkit sxml xml)` implements a validating, namespace-aware XML parser following the [XML 1.0 Recommendation](http://www.w3.org/TR/1998/REC-xml-19980210.html) as well as the [XML Namespaces Recommendation](http://www.w3.org/TR/REC-xml-names). The implementation is an adaptation of Oleg Kiselyov's _SSAX_ parsing framework (Simple SAX, or "Static SAX"), a purely functional variant of a SAX-style, streaming parser.

Most clients only need the high-level conversion procedure `xml->sxml`, which reads XML from a port and returns the corresponding SXML tree (see library `(lispkit sxml)` for details on the SXML representation). The remaining procedures exported by this library expose the lower-level building blocks of the SSAX framework and are intended for programmers who want to implement a custom XML parser, e.g. one that produces a different in-memory representation than SXML, that performs validation against a DTD/schema, or that only processes a subset of a (potentially large) XML document while streaming through it.


## Parsing XML into SXML

**(xml-\>sxml)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  
**(xml-\>sxml _port_)**  
**(xml-\>sxml _port namespace-prefixes_)**  

Parses the XML document available from input port _port_ and returns its content as an SXML tree, wrapped in a `*TOP*` element. If _port_ is not provided, `xml->sxml` reads from the current input port (as defined by `current-input-port` of library `(lispkit port)`). After `xml->sxml` returns, the read position of _port_ is right after the root element of the document.

_namespace-prefixes_ is a list of `(user-prefix . uri-string)` pairs, where _user-prefix_ is a symbol chosen by the caller and _uri-string_ is a string identifying an XML namespace. For every element or attribute name that is qualified by a namespace listed in _namespace-prefixes_, the corresponding _user-prefix_ is used to build a prefixed symbol `user-prefix:localname` in the resulting SXML tree, irrespective of the actual namespace prefix used in the source document. If _namespace-prefixes_ is provided and not empty, the top-level `*TOP*` element carries a `*NAMESPACES*` attribute listing the requested namespace mappings. The default for _namespace-prefixes_ is the empty list.

A `<!DOCTYPE ...>` declaration, if present, is skipped (together with an internal DTD subset, if any) and a warning is printed via `ssax-warn`; the DTD itself is not used for validation. Processing instructions are collected into `(*PROCESSING-INSTRUCTIONS* target body)` nodes; comments are discarded.

```scheme
(import (lispkit sxml xml) (lispkit port))

(call-with-port (open-input-string "<book id=\"1\"><title>SXML in a Nutshell</title></book>")
  (lambda (port) (xml->sxml port)))
  ⇒ (*TOP* (book (@ (id "1")) (title "SXML in a Nutshell")))

(call-with-port (open-input-string
                  "<root xmlns:h=\"http://www.w3.org/HTML\"><h:p>Hi</h:p></root>")
  (lambda (port) (xml->sxml port '((html . "http://www.w3.org/HTML")))))
⇒ (*TOP* (@ (*NAMESPACES* (html "http://www.w3.org/HTML")))
         (root (html:p "Hi")))
```


## SSAX parsing framework

The remaining procedures of this library implement the low-level, extensible SSAX parsing framework. They share the following terminology and data representations:

   - **UNRES-NAME**: an unresolved element, attribute, or processing-instruction name as it appears literally in an XML document. A simple name (an `NCName`) is represented as a Scheme symbol; a qualified name (a `QName`, e.g. `ns:local`) is represented as a pair `(prefix . localpart)` of symbols.
   - **RES-NAME**: a namespace-resolved version of an UNRES-NAME. A name qualified by a non-empty namespace URI is represented as a pair `(uri-symbol . localpart)`; an unqualified name remains a plain symbol.
   - **NAMESPACES**: a list describing the namespace declarations currently in effect. Each element has one of the forms `(prefix uri-symbol . uri-symbol)`, `(prefix user-prefix . uri-symbol)`, `(*DEFAULT* user-prefix . uri-symbol)`, or `(*DEFAULT* #f . #f)` (the latter un-declaring the default namespace). If several elements describe the same prefix, the one closest to the beginning of the list is in effect.
   - **ATTLIST**: an ordered collection of `(name . value)` pairs (where `name` is a RES-NAME or UNRES-NAME, and `value` is a string), sorted by name.
   - **STR-HANDLER**: a procedure of three arguments, _string1_, _string2_, and _seed_, returning a new seed. It handles a chunk of character data _string1_, immediately followed by another (typically short) chunk _string2_.
   - **ENTITIES**: an association list of `(name . body)` pairs describing declared general entities, where _name_ is the symbol under which the entity was declared and _body_ is either a string, or (for an external entity) a thunk returning an input port from which the entity's replacement text can be read.
   - **xml-token**: a record describing a markup token (a start-tag, end-tag, processing instruction, declaration, or named entity reference), consisting of a _kind_ and a _head_. See `xml-token-kind` and `xml-token-head` below.

**(xml-token-kind _token_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Returns the kind of markup token _token_, one of the symbols `START`, `END`, `PI`, `DECL`, `COMMENT`, `CDSECT`, or `ENTITY-REF`.

**(xml-token-head _token_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Returns the head of markup token _token_. For a `START` or `END` token, this is the (UNRES-NAME) tag name; for a `PI` token, the PI target; for a `DECL` token, the declaration keyword (e.g. `DOCTYPE`); for an `ENTITY-REF` token, the entity name. For `COMMENT` and `CDSECT` tokens, the head is `#f`.

For example, `<p>` is tokenized as kind `START` and head `p`; `</p>` as kind `END` and head `p`; `<!DOCTYPE ...>` as kind `DECL` and head `DOCTYPE`; `<?xml version="1.0"?>` as kind `PI` and head `xml`; `&my-ent;` as kind `ENTITY-REF` and head `my-ent`.

**(ssax-warn _port msg other-msg ..._)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Writes a warning to the current error port (as defined by `current-error-port` of library `(lispkit port)`), concatenating _msg_ and all _other-msg_ arguments. _port_ is currently unused by the default implementation but is passed for consistency with other SSAX procedures that may report errors relative to the position within an input port.

**(ssax-scan-misc _port_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Scans past a sequence of comments and whitespace in the prolog or epilog of an XML document (the `Misc*` production of the XML grammar), reading from input port _port_. Returns either the eof object, or the xml-token describing the next processing instruction, declaration, or start tag that was encountered (comments are silently skipped and not reported).

**(ssax-read-char-data _port expect-eof? str-handler seed_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Reads the character content of an XML element (the `content` production of the XML grammar) from _port_, invoking STR-HANDLER _str-handler_ for every chunk of character data encountered, threading the seed value _seed_ through successive invocations. CDATA sections and character references are expanded and passed to _str-handler_ inline; comments are silently disregarded. If _expect-eof?_ is `#t`, encountering the end of _port_ is not treated as an error (this is used while reading a parsed entity).

`ssax-read-char-data` stops reading as soon as it encounters a start tag, an end tag, the beginning of a processing instruction, a named entity reference, or (if _expect-eof?_ is `#t`) the end of the input. It returns two values: the final seed (the result of the last invocation of _str-handler_, or the original _seed_ if _str-handler_ was never invoked), and either the eof object, or an xml-token describing what interrupted the character data (which the caller is responsible for handling further).

**(ssax-read-attributes _port entities_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Reads a sequence of `name="value"` attribute declarations from _port_, using ENTITIES _entities_ to resolve named entity references occurring within attribute values, and returns the corresponding ATTLIST of `(UNRES-NAME . value)` pairs. The current position of _port_ must be at the first character of the first attribute name (or at the character immediately following the last attribute, e.g. `>` or `/`, if there are no more attributes).

**(ssax-read-external-id _port_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Reads an `ExternalID` production (`SYSTEM SystemLiteral` or `PUBLIC PubidLiteral SystemLiteral`) from _port_ and returns the `SystemLiteral` part as a string; a `PubidLiteral`, if present, is skipped. The current position of _port_ must be at the `S` or `P` character starting the `SYSTEM` or `PUBLIC` keyword.

**(ssax-resolve-name _port unres-name namespaces apply-default-ns?_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Converts UNRES-NAME _unres-name_ into a RES-NAME using the NAMESPACES declarations _namespaces_ currently in effect. If _apply-default-ns?_ is `#t`, an unqualified name is resolved against the default namespace (if any is declared in _namespaces_); this should be `#f` for attribute names, since the default namespace does not apply to attributes. The `xml` prefix is always resolved to the pre-declared `http://www.w3.org/XML/1998/namespace` namespace. _port_ is used only for error reporting when a used namespace prefix has not been declared.

**(make-ssax-pi-parser _handlers_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Creates and returns a procedure `(port target seed)` that parses and processes a single processing instruction (PI). _handlers_ is an association list of `(pi-tag . pi-handler)` pairs, where _pi-tag_ is a symbol denoting a PI target and _pi-handler_ is a procedure `(port pi-tag seed)`. When invoked, _pi-handler_ is expected to read the remainder of the PI, up to and including the terminating `?>`, and to return a new seed. The special _pi-tag_ `*DEFAULT*` may be used to handle PIs for which no specific handler is registered; if no `*DEFAULT*` handler is given, unhandled PIs are skipped (with a warning printed via `ssax-warn`).

**(make-ssax-elem-parser _new-level-seed finish-element char-data-handler pi-handlers_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Creates and returns a procedure `(start-tag-head port elems entities namespaces preserve-ws? seed)` that parses and processes a single element, including all of its attributes, character data, and child elements. The returned procedure must be invoked right after the start-tag head has been read; it is typically used to parse the root element of a document.

   - _new-level-seed_ is a procedure `(elem-gi attributes namespaces expected-content seed)` that computes the seed passed to the handlers processing the content of the element about to be parsed (RES-NAME _elem-gi_).
   - _finish-element_ is a procedure `(elem-gi attributes namespaces parent-seed seed)`, invoked once parsing of the element is finished; _seed_ is the result of the last content handler invocation (or of _new-level-seed_, if the element was empty), and _parent-seed_ is the seed that was passed to _new-level-seed_. The procedure computes the seed that becomes the overall result of the element parser.
   - _char-data-handler_ is a STR-HANDLER used to process character content of the element.
   - _pi-handlers_ has the same shape as the _handlers_ argument of `make-ssax-pi-parser`.

**(make-ssax-parser _tag val ..._)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Creates and returns a full XML document parser, a procedure `(port seed)` that parses the document prolog and then delegates to an element parser (as created by `make-ssax-elem-parser`) to process the root element and the remainder of the document. The generated parser can act as a SAX parser, a DOM parser (such as `xml->sxml`), or as a specialized parser, depending on the supplied handlers.

`make-ssax-parser` takes a property list of _tag_/_val_ pairs. The following tags are recognized (all other tags are rejected):

   - `NEW-LEVEL-SEED` (required) — see `my-new-level-seed` of `make-ssax-elem-parser`.
   - `FINISH-ELEMENT` (required) — see `my-finish-element` of `make-ssax-elem-parser`.
   - `CHAR-DATA-HANDLER` (required) — a STR-HANDLER, see `my-char-data-handler` of `make-ssax-elem-parser`.
   - `PROCESSING-INSTRUCTIONS` — an association list as expected by `make-ssax-pi-parser`. Defaults to `'()`.
   - `DOCTYPE` — a procedure `(port docname systemid internal-subset? seed)`, invoked when a `<!DOCTYPE ...>` declaration is encountered. If _internal-subset?_ is `#t`, the current position of _port_ is right after the `[` that begins the internal DTD subset; the handler is responsible for reading past the internal subset before returning. The handler must return four values: `elems entities namespaces seed`, where _elems_ describes the declared elements (or `#f` to disable validation). The default handler skips the internal subset, if any, prints a warning via `ssax-warn`, and returns `(values #f '() '() seed)`.
   - `UNDECL-ROOT` — a procedure `(elem-gi seed)`, invoked with the UNRES-NAME of the root element when the document does not contain a `DOCTYPE` declaration. Like the `DOCTYPE` handler, it must return four values: `elems entities namespaces seed`. The default handler returns `(values #f '() '() seed)`.
   - `DECL-ROOT` — a procedure `(elem-gi seed)`, invoked with the UNRES-NAME of the root element when the document does contain a `DOCTYPE` declaration. It returns a new seed. The default handler is the identity function.

```scheme
(import (lispkit sxml xml) (lispkit port))

(define count-elements
  (make-ssax-parser
    'NEW-LEVEL-SEED
    (lambda (elem-gi attributes namespaces expected-content seed) (+ seed 1))
    'FINISH-ELEMENT
    (lambda (elem-gi attributes namespaces parent-seed seed) seed)
    'CHAR-DATA-HANDLER
    (lambda (string1 string2 seed) seed)))

(call-with-port (open-input-string "<a><b/><c><d/></c></a>")
  (lambda (port) (count-elements port 0)))
⇒ 4
```

