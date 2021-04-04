Library `(lispkit enum)` provides an implementation of enumerated values and sets of enumerated values based on the API defined by R6RS.

Enumerated values are represented by ordinary symbols, while finite sets of enumerated values form a separate type, known as _enumeration set_. The enumeration sets are further partitioned into sets that share the same universe and enumeration type. These universes and enumeration types are created by the `make-enumeration` procedure. Each call to that procedure creates a new enumeration type.

In the descriptions of the following procedures, _enum-set_ ranges over the enumeration sets, which are defined as the subsets of the universes that can be defined using `make-enumeration`.

***

**(make-enumeration _symbol-list_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Argument _symbol-list_ must be a list of symbols. The `make-enumeration` procedure creates a new enumeration type whose universe consists of those symbols (in canonical order of their first appearance in the list) and returns that universe as an enumeration set whose universe is itself and whose enumeration type is the newly created enumeration type.

**(enum-set-universe _enum-set_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Returns the set of all symbols that comprise the universe of its argument _enum-set_, as an enumeration set.

**(enum-set-indexer _enum-set_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Returns a unary procedure that, given a symbol that is in the universe of _enum-set_, returns its 0-origin index within the canonical ordering of the symbols in the universe; given a value not in the universe, the unary procedure returns `#f`.

```
(let* ((e (make-enumeration '(red green blue)))
       (i (enum-set-indexer e)))
  (list (i 'red) (i 'green) (i 'blue) (i 'yellow)))
 ⇒ (0 1 2 #f)
```

The `enum-set-indexer` procedure could be defined as follows using the `memq` procedure:

```
(define (enum-set-indexer set)
  (let* ((symbols (enum-set->list (enum-set-universe set)))
         (cardinality (length symbols)))
    (lambda (x)
      (cond ((memq x symbols) =>
              (lambda (probe) (- cardinality (length probe))))
            (else #f)))))
```

**(enum-set-constructor _enum-set_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Returns a unary procedure that, given a list of symbols that belong to the universe of _enum-set_, returns a subset of that universe that contains exactly the symbols in the list. The values in the list must all belong to the universe.

**(enum-set->list _enum-set_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Returns a list of the symbols that belong to its argument, in the canonical order of the universe of _enum-set_.

```
(let* ((e (make-enumeration '(red green blue)))
       (c (enum-set-constructor e)))
  (enum-set->list (c '(blue red))))
⇒ (red blue)
```

**(enum-set-member? _symbol enum-set_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  
**(enum-set-subset? _enum-set1 enum-set2_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  
**(enum-set=? _enum-set1 enum-set2_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

The `enum-set-member?` procedure returns `#t` if its first argument is an element of its second argument, `#f` otherwise.

The `enum-set-subset?` procedure returns `#t` if the universe of _enum-set1_ is a subset of the universe of _enum-set2_ (considered as sets of symbols) and every element of _enum-set1_ is a member of _enum-set2_. It returns `#f` otherwise.

The `enum-set=?` procedure returns `#t` if _enum-set1_ is a subset of _enum-set2_ and vice versa, as determined by the `enum-set-subset?` procedure. This implies that the universes of the two sets are equal as sets of symbols, but does not imply that they are equal as enumeration types. Otherwise, `#f` is returned.

```
(let* ((e (make-enumeration '(red green blue)))
       (c (enum-set-constructor e)))
  (list (enum-set-member? 'blue (c '(red blue)))
        (enum-set-member? 'green (c '(red blue)))
        (enum-set-subset? (c '(red blue)) e)
        (enum-set-subset? (c '(red blue)) (c '(blue red)))
        (enum-set-subset? (c '(red blue)) (c '(red)))
        (enum-set=? (c '(red blue)) (c '(blue red)))))
⇒ (#t #f #t #t #f #t)
```

**(enum-set-union _enum-set1 enum-set2_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  
**(enum-set-intersection _enum-set1 enum-set2_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  
**(enum-set-difference _enum-set1 enum-set2_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Arguments _enum-set1_ and _enum-set2_ must be enumeration sets that have the same enumeration type.

The `enum-set-union` procedure returns the union of _enum-set1_ and _enum-set2_. The `enum-set-intersection` procedure returns the intersection of _enum-set1_ and _enum-set2_. The `enum-set-difference` procedure returns the difference of _enum-set1_ and _enum-set2_.

```
(let* ((e (make-enumeration '(red green blue)))
       (c (enum-set-constructor e)))
  (list (enum-set->list (enum-set-union (c '(blue)) (c '(red))))
        (enum-set->list
          (enum-set-intersection (c '(red green)) (c '(red blue))))
        (enum-set->list
         (enum-set-difference (c '(red green)) (c '(red blue))))))
⇒ ((red blue) (red) (green))
```

**(enum-set-complement _enum-set_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Returns _enum-set_'s complement with respect to its universe.

```
(let* ((e (make-enumeration '(red green blue)))
       (c (enum-set-constructor e)))
  (enum-set->list (enum-set-complement (c '(red)))))
⇒ (green blue)
```

**(enum-set-projection _enum-set1 enum-set2_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Projects _enum-set1_ into the universe of _enum-set2_, dropping any elements of _enum-set1_ that do not belong to the universe of _enum-set2_. If _enum-set1_ is a subset of the universe of its second, no elements are dropped, and the injection is returned.

```
(let ((e1 (make-enumeration '(red green blue black)))
      (e2 (make-enumeration '(red black white))))
  (enum-set->list (enum-set-projection e1 e2))))
⇒ (red black)
```

**(define-enumeration _type-name (symbol ...) constructor_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[syntax]</span>  

The `define-enumeration` form defines an enumeration type and provides two macros for constructing its members and sets of its members. A `define-enumeration` form is a definition and can appear anywhere any other definition can appear.

_type-name_ is an identifier that is bound as a syntactic keyword; _symbol ..._ are the symbols that comprise the universe of the enumeration (in order).

`(`_type-name_ _symbol_`)` checks whether the name of _symbol_ is in the universe associated with _type-name_. If it is, `(`_type-name_ _symbol_`)` is equivalent to _symbol_. It is a syntax violation if it is not.

_constructor_ is an identifier that is bound to a syntactic form that, given any finite sequence of the symbols in the universe, possibly with duplicates, expands into an expression that evaluates to the enumeration set of those symbols.

`(`_constructor_ _symbol ..._`)` checks whether every <symbol> ... is in the universe associated with _type-name_. It is a syntax violation if one or more is not. Otherwise `(`_constructor_ _symbol> ..._`)` is equivalent to `((enum-set-constructor (`_constructor-syntax_`)) '(`_symbol ..._`))`.

Here is a complete example:

```
(define-enumeration color (black white purple maroon) color-set)
(color black)                   ⇒ black
(color purpel)                  ⇒ error: symbol not in enumeration universe
(enum-set->list (color-set))    ⇒ ()
(enum-set->list
  (color-set maroon white))     ⇒ (white maroon)
```

***

Some of this documentation is derived from the [R6RS specification of enumerations](http://www.r6rs.org/final/html/r6rs-lib/r6rs-lib-Z-H-14.html#node_chap_13) by Michael Sperber, Kent Dybvig, Matthew Flatt, Anton van Straaten, Richard Kelsey, William Clinger, and Jonathan Rees.
