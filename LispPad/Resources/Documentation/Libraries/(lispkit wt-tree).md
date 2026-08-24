# LispKit WT-Tree

Library `(lispkit wt-tree)` implements _weight-balanced binary trees_, a persistent, ordered key/value data structure. A `wt-tree` maps keys to values (like a hash table), but, unlike a hash table, keeps its entries ordered according to a user-supplied ordering predicate on the keys and provides efficient positional (rank-based) access, range splitting, and set-theoretic operations (union, intersection, difference, subset test) on the key sets of two trees. The implementation is an enhanced and bug-corrected variant of Stephen Adams' weight-balanced trees, following Yoichi Hirai and Kazuhiko Yamamoto, ["Balancing weight-balanced trees"](https://yoichihirai.com/bst.pdf), Journal of Functional Programming, 21(3):287-307, 2011.

WT-trees are persistent: operations such as `wt-tree/add` or `wt-tree/delete` return a new tree and leave the argument tree unchanged, sharing structure with it. For performance-sensitive code, destructive counterparts (`wt-tree/add!`, `wt-tree/delete!`, `wt-tree/delete-min!`) are also provided, mutating a tree in place.


## Tree types

Every `wt-tree` is created with respect to a _tree type_, an object that bundles the strict ordering predicate (`key<?`) used to compare keys together with the tree-type-specific implementations of all `wt-tree` operations. Two trees can only be combined with each other (e.g. via `wt-tree/union`) if they were created with the very same tree type object.

**(make-wt-tree-type _key<?_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Returns a new tree type whose keys are ordered by the strict ordering predicate _key<?_, i.e. a procedure of two arguments returning `#t` if and only if its first argument is strictly less than its second.

**(make-comparator-wt-tree-type _comp_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Returns a new tree type whose keys are ordered according to the ordering predicate of comparator _comp_ (see `comparator-ordering-predicate` of library `(lispkit comparator)`).

**(wt-tree-type? _obj_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Returns `#t` if _obj_ is a tree type (as created by `make-wt-tree-type`, `make-comparator-wt-tree-type`, or one of the predefined tree types below), `#f` otherwise.

**wt-tree-type-tag** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[constant]</span>  

Symbol representing the `wt-tree-type` type. The `type-of` procedure of library `(lispkit type)` returns a list starting with this symbol for tree type objects (not for `wt-tree` instances themselves; use `wt-tree-type?` respectively `wt-tree?` to distinguish the two).

**number-wt-type** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[constant]</span>  

Predefined tree type ordering keys via `<`, i.e. for using real numbers as keys.

**string-wt-type** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[constant]</span>  

Predefined tree type ordering keys via `string<?`, i.e. for using strings as keys.

**string-ci-wt-type** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[constant]</span>  

Predefined tree type ordering keys via `string-ci<?`, i.e. for using strings as keys, ignoring case.

**char-wt-type** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[constant]</span>  

Predefined tree type ordering keys via `char<?`, i.e. for using characters as keys.

**char-ci-wt-type** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[constant]</span>  

Predefined tree type ordering keys via `char-ci<?`, i.e. for using characters as keys, ignoring case.


## Constructing WT-Trees

**(make-wt-tree)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  
**(make-wt-tree _type_)**  

Returns a new, empty `wt-tree` of tree type _type_. The default for _type_ is `number-wt-type`.

**(singleton-wt-tree _key value_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  
**(singleton-wt-tree _type key value_)**  

Returns a new `wt-tree` of tree type _type_ containing a single entry mapping _key_ to _value_. The default for _type_ is `number-wt-type`.

**(alist-\>wt-tree _type alist_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Returns a new `wt-tree` of tree type _type_, populated with the `(key . value)` associations of association list _alist_. If _alist_ contains several entries for the same key, the entry that appears later in _alist_ takes precedence.

```scheme
(define t
  (alist->wt-tree
    number-wt-type
    '((3 . "c") (1 . "a") (2 . "b"))))
```

**(wt-tree? _obj_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Returns `#t` if _obj_ is a `wt-tree`, `#f` otherwise.

**(wt-tree/copy _tree_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Returns a new `wt-tree` with the same tree type, keys, and values as _tree_. Since wt-trees are persistent, `wt-tree/copy` is a cheap, O(1) operation; the copy initially shares its internal representation with _tree_, but the two trees evolve independently from each other, in particular with respect to the destructive operations `wt-tree/add!`, `wt-tree/delete!`, and `wt-tree/delete-min!`.

**(wt-tree/valid? _tree_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Returns `#t` if `wt-tree` _tree_ satisfies the weight-balance and ordering invariants of the underlying tree implementation, `#f` otherwise. Since these invariants are maintained automatically by all `wt-tree` operations, this predicate is primarily useful for testing and debugging purposes.


## Basic operations

**(wt-tree/empty? _tree_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Returns `#t` if `wt-tree` _tree_ contains no entries, `#f` otherwise.

**(wt-tree/size _tree_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Returns the number of entries in `wt-tree` _tree_.

**(wt-tree/add _tree key value_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Returns a new `wt-tree`, like _tree_ but with _key_ mapped to _value_. If _key_ is already present in _tree_, its associated value is replaced; _tree_ itself remains unchanged.

**(wt-tree/add! _tree key value_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Destructively adds an entry mapping _key_ to _value_ to `wt-tree` _tree_, replacing any value that _key_ was previously mapped to. Returns an unspecified result.

**(wt-tree/delete _tree key_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Returns a new `wt-tree`, like _tree_ but with any entry for _key_ removed. If _key_ is not present in _tree_, a copy of _tree_ is returned. _tree_ itself remains unchanged.

**(wt-tree/delete! _tree key_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Destructively removes the entry for _key_, if any, from `wt-tree` _tree_. Returns an unspecified result.

**(wt-tree/member? _key tree_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Returns `#t` if `wt-tree` _tree_ contains an entry for _key_, `#f` otherwise. Note that, unlike most other procedures of this library, `wt-tree/member?` expects _key_ as its first and _tree_ as its second argument.

**(wt-tree/lookup _tree key default_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Returns the value associated with _key_ in `wt-tree` _tree_, or _default_ if _tree_ does not contain an entry for _key_.

```scheme
(define t (singleton-wt-tree 2 "b"))
(wt-tree/lookup t 2 #f)     ⇒  "b"
(wt-tree/lookup t 9 #f)     ⇒  #f
(wt-tree/lookup t 1 'none)  ⇒  none
```


## Ordered and positional access

Since the entries of a `wt-tree` are kept in key order, they can also be accessed by their zero-based position (_rank_) in this order, from the smallest key (position `0`) to the largest key (position `(- (wt-tree/size tree) 1)`).

**(wt-tree/index _tree index_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Returns the key at position _index_ of `wt-tree` _tree_, in ascending key order. Signals an error if _index_ is not in the range `[0, (wt-tree/size tree))`.

**(wt-tree/index-datum _tree index_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Like `wt-tree/index`, but returns the value associated with the key at position _index_ instead of the key itself.

**(wt-tree/index-pair _tree index_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Like `wt-tree/index`, but returns a pair `(key . value)` for the entry at position _index_.

**(wt-tree/rank _tree key_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Returns the zero-based position of _key_ within `wt-tree` _tree_ in ascending key order, or `#f` if _tree_ does not contain an entry for _key_. `wt-tree/rank` is the inverse operation of `wt-tree/index`.

**(wt-tree/min _tree_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Returns the smallest key of `wt-tree` _tree_. Signals an error if _tree_ is empty.

**(wt-tree/min-datum _tree_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Returns the value associated with the smallest key of `wt-tree` _tree_. Signals an error if _tree_ is empty.

**(wt-tree/min-pair _tree_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Returns a pair `(key . value)` for the entry with the smallest key of `wt-tree` _tree_. Signals an error if _tree_ is empty.

**(wt-tree/delete-min _tree_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Returns a new `wt-tree`, like _tree_ but with the entry for the smallest key removed. _tree_ itself remains unchanged. Signals an error if _tree_ is empty.

**(wt-tree/delete-min! _tree_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Destructively removes the entry for the smallest key from `wt-tree` _tree_. Returns an unspecified result. Signals an error if _tree_ is empty.


## Splitting trees

**(wt-tree/split< _tree key_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Returns a new `wt-tree` containing all entries of _tree_ whose key is strictly less than _key_ (the entry for _key_ itself, if present, is excluded).

**(wt-tree/split> _tree key_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Returns a new `wt-tree` containing all entries of _tree_ whose key is strictly greater than _key_ (the entry for _key_ itself, if present, is excluded).


## Set-like operations

The following procedures combine two wt-trees based on their key sets. _tree1_ and _tree2_ must have been created with the same tree type object (e.g. both via `number-wt-type`, or both via the same tree type returned from `make-wt-tree-type`); otherwise, an error is signalled.

**(wt-tree/union _tree1 tree2_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Returns a new `wt-tree` containing all entries whose key is in _tree1_ or _tree2_ (or both). For a key present in both trees, the value from _tree2_ is used.

**(wt-tree/union-merge _tree1 tree2 merge_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Like `wt-tree/union`, but for a key present in both trees, the associated value is computed by calling _merge_ with three arguments: the key, the value associated with the key in _tree2_, and the value associated with the key in _tree1_.

```scheme
(define t1 (alist->wt-tree number-wt-type '((1 . "a1") (2 . "b1"))))
(define t2 (alist->wt-tree number-wt-type '((2 . "b2") (3 . "c2"))))
(wt-tree/fold
  (lambda (k v acc) (cons (cons k v) acc))
  '()
  (wt-tree/union-merge t1 t2
    (lambda (key v2 v1) (string-append v1 "+" v2))))
⇒ ((1 . "a1") (2 . "b1+b2") (3 . "c2"))
```

**(wt-tree/intersection _tree1 tree2_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Returns a new `wt-tree` containing all entries whose key is present in both _tree1_ and _tree2_. For each such key, the value from _tree2_ is used.

**(wt-tree/difference _tree1 tree2_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Returns a new `wt-tree` containing all entries of _tree1_ whose key is not present in _tree2_.

**(wt-tree/subset? _tree1 tree2_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Returns `#t` if the set of keys of _tree1_ is a subset of the set of keys of _tree2_, `#f` otherwise. Only key membership is compared; associated values are not taken into account.

**(wt-tree/set-equal? _tree1 tree2_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Returns `#t` if _tree1_ and _tree2_ have the same set of keys, `#f` otherwise. Just like `wt-tree/subset?`, only keys are compared, not values. `wt-tree/set-equal?` is implemented like this:

```scheme
(define (wt-tree/set-equal? tree1 tree2)
  (and (wt-tree/subset? tree1 tree2)
       (wt-tree/subset? tree2 tree1)))
```


## Traversal

**(wt-tree/fold _combiner init tree_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Combines all entries of `wt-tree` _tree_, in ascending key order, with combining function _combiner_, using _init_ as the value for the smallest entry not yet part of the combined result. _combiner_ is a procedure of three arguments, a key, its associated value, and the so-far accumulated result; it returns a new accumulated result. `wt-tree/fold` corresponds to a right fold over the ascending sequence of entries, i.e. it computes

```scheme
(combiner k₁ v₁ (combiner k₂ v₂ (... (combiner kₙ vₙ init) ...)))
```

for a tree with entries `k₁ < k₂ < ... < kₙ`. For instance, `wt-tree/fold` can be used to convert a `wt-tree` into a sorted association list:

```scheme
(wt-tree/fold (lambda (key value alist) (cons (cons key value) alist)) '() t)
```

**(wt-tree/for-each _proc tree_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Invokes _proc_ once for every entry of `wt-tree` _tree_, in ascending key order, passing the key and the associated value as two arguments. The result of `wt-tree/for-each` is unspecified.
