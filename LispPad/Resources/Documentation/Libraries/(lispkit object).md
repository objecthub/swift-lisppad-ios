# LispKit Object

Library `(lispkit object)` implements a simple, delegation-based object system for LispKit. It provides procedural and declarative interfaces for objects and classes. The class system is optional. It mostly provides means to define and manage new object types and construct objects using object constructors.


## Introduction

Similar to other Scheme and Lisp-based object systems, methods of objects are defined in terms of object/class-specific specializations of generic procedures. A generic procedure consists of methods for the various objects/classes it supports. A generic procedure performs a dynamic dispatch on the first parameter (the `self` parameter) to determine the applicable method.

### Generic procedures

Generic procedures can be defined using the `define-generic` form. Here is an example which defines three generic methods, one with only a `self` parameter, and two with three parameters `self`, `x` and `y`. The last generic procedure definition includes a `default` method which is applicable to all objects for which there is no specific method. When a generic procedure without default is applied to an object that does not define its own method implementation, an error gets signaled.

```scheme
(define-generic (point-coordinates self))
(define-generic (set-point-coordinates! self x y))
(define-generic (point-move! self x y)
  (let ((c (point-coordinate self)))
    (set-point-coordinate! self (+ (car c) x) (+ (cdr c) y))))
```

### Objects

An object encapsulates a list of methods each implementing a generic procedure. These methods are regular closures which can share mutable state. Objects do not have an explicit notion of a field or slot as in other Scheme or Lisp-based object systems. Fields/slots need to be implemented via generic procedures and method implementations sharing state. Here is an example explaining this approach:

```scheme
(define (make-point x y)
  (object ()
    ((point-coordinates self)
      (cons x y))
    ((set-point-coordinates! self nx ny)
      (set! x nx) (set! y ny))
    ((object-description self)
      (string-append (object-description x)
                     "/"
                     (object-description y)))))
```

This is a function creating new point objects. The `x` and `y` parameters of the constructor function are used for representing the state of the point object. The created point objects implement three generic procedures: `point-coordinates`, `set-point-coordinates`, and `object-description`. The latter procedure is defined directly by the library and, in general, used for creating a string representation of any object. By implementing the `object-description` method, the behavior gets customized for the object.

The following lines of code illustrate how point objects can be used:

```scheme
(define pt (make-point 25 37))
pt                               ⇒  #<object #<box (...)>>
(object-description pt)          ⇒  "25/37"
(point-coordinates pt)           ⇒  (25 . 37)
(set-point-coordinates! pt 5 6)
(object-description pt)          ⇒  "5/6"
(point-coordinates pt)           ⇒  (5 . 6)
```

### Inheritance

The LispKit object system supports inheritance via delegation. The following code shows how colored points can be implemented by delegating all point functionality to the previous implementation and by simply adding only color-related logic.

```scheme
(define-generic (point-color self) #f)
(define (make-colored-point x y color)
  (object ((super (make-point x y)))
    ((point-color self) color)
    ((object-description self)
       (string-append (object-description color)
                      ":"
                      (invoke (super object-description) self)))))
```

The object created in function `make-colored-point` inherits all methods from object `super` which gets set to a new point object. It adds a new method to generic procedure `point-color` and redefines the `object-description` method. The redefinition is implemented in terms of the inherited `object-description` method for points. The form `invoke` can be used to refer to overridden methods in delegatee objects. Thus, `(invoke (super object-description) self)` calls the `object-description` method of the `super` object but with the identity (`self`) of the colored point.

The following interaction illustrates the behavior:

```scheme
(define cpt (make-colored-point 100 50 'red))
(point-color cpt)                    ⇒  red
(point-coordinates cpt)              ⇒  (100 . 50)
(set-point-coordinates! cpt 101 51)
(object-description cpt)             ⇒  "red:101/51"
```

Objects can delegate functionality to multiple delegatees. The order in which they are listed determines the methods which are being inherited in case there are conflicts, i.e. multiple delegatees implement a method for the same generic procedure.


### Classes

Classes add syntactic sugar, simplifying the creation and management of objects. They play the following role in the object-system of LispKit:

  1. A class defines a constructor for objects represented by this class.
  2. Each class defines an object type, which can be used to distinguish objects created by the same constructor and supporting the same methods.
  3. A class can inherit functionality from several other classes, making it easy to reuse functionality.
  4. Classes are first-class objects supporting a number of class-related procedures.

The following code defines a `point` class with similar functionality as above:

```scheme
(define-class (point x y) ()
  (object ()
    ((point-coordinates self)
      (cons x y))
    ((set-point-coordinates! self nx ny)
      (set! x nx) (set! y ny))
    ((object-description self)
      (string-append (object-description x)
                     "/"
                     (object-description y)))))
```

Instances of this class are created by using the generic procedure `make-instance` which is implemented by all class objects:

```scheme
(define pt2 (make-instance point 82 10))
pt2                       ⇒  #<point #<box (...)>>
(object-description pt2)  ⇒  "82/10"
```

Each object created by a class implements a generic procedure `object-class` referring to the class of the object. Since classes are objects themselves we can obtain their name with generic procedure `class-name`:

```scheme
(object-class pt2)               ⇒  #<class #<box (...)>>
(class-name (object-class pt2))  ⇒  point
(instance-of? point pt2)         ⇒  #t
(instance-of? point pt)          ⇒  #f
```

Generic procedure `instance-of?` can be used to determine whether an object is a direct or indirect instance of a given class. The last two lines above show that `pt2` is an instance of `point`, but `pt` is not, even though it is functionally equivalent.

The following definition re-implements the colored point example from above using a class:

```scheme
(define-class (colored-point x y color) (point)
  (if (or (< x 0) (< y 0))
      (error "coordinates are negative: ($0; $1)" x y))
  (object ((super (make-instance point x y)))
    ((point-color self) color)
    ((object-description self)
       (string-append (object-description color)
                      ":"
                      (invoke (super object-description) self)))))
```

The following lines illustrate the behavior of `colored-point` objects vs `point` objects:

```scheme
(define cpt2 (make-instance colored-point 128 256 'blue))
(point-color cpt2)                  ⇒  blue
(point-coordinates cpt2)            ⇒  (128 . 256)
(set-point-coordinates! cpt2 64 32)
(object-description cpt2)           ⇒  "blue:64/32"
(instance-of? point cpt2)           ⇒  #t
(instance-of? colored-point cpt2)   ⇒  #t
(instance-of? colored-point cpt)    ⇒  #f
(class-name (object-class cpt2))    ⇒  colored-point
```


## Procedural object interface

**object-type-tag** <span style="float:right;text-align:rigth;">[constant]</span>  

Symbol representing the `object` type. The `type-for` procedure of library `(lispkit type)` returns this symbol for all objects created via `object` or `make-object`.

Every class created via `make-class` (or `define-class`) implicitly defines its own, more specific type tag for its instances, distinct from `object-type-tag` and `class-type-tag`, but not directly exposed to user code. `type-of` (see library `(lispkit type)`) returns a list of such tags for an object, ordered from most specific to least specific, e.g. `(type-of pt2) ⇒ (point object)` for an instance of a `point` class, `(type-of point) ⇒ (class object)` for the `point` class object itself, and `(type-of (make-object)) ⇒ (object)` for a plain object without a class.

**(object? _obj_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Returns `#t` if _obj_ is an object as defined by this library. Objects are either created procedurally via `make-object` or declaratively via `object`.

**(make-object)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  
**(make-object _delegate ..._)**  

Creates and returns a new object without any methods of its own. If one or more _delegate_ objects are provided, the new object inherits all of their methods (see `object-methods`); if several delegates implement a method for the same generic procedure, the method of the delegate listed first takes precedence. `make-object` is the procedural counterpart of the `object` syntax, which additionally allows methods to be attached right away.

**(method _obj generic_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Returns the method implementing generic procedure _generic_ for object _obj_, or `#f` if _obj_ does not implement _generic_. The result is a plain procedure still expecting the "self" object as its first argument, e.g. `((method obj generic) obj arg ...)`. This is the procedure used internally to perform dynamic dispatch, both by generic procedures created with `make-generic-procedure` and by the `invoke` syntax.

**(object-methods _obj_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Returns an association list of all methods implemented by object _obj_, i.e. a list of pairs `(generic . method)`. If `add-method!` was used to add more than one method for the same generic procedure, all of them show up in the list, with the most recently added one listed first (see `add-method!`).

**(add-method! _obj generic method_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Adds _method_ as a new implementation of generic procedure _generic_ to object _obj_, mutating _obj_ in place. _method_ is a procedure expecting the "self" object as its first argument. If _obj_ already implements _generic_, the previous method is not discarded but merely shadowed: it becomes visible again once _method_ is removed via `delete-method!`.

**(delete-method! _obj generic_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Removes the most recently added implementation of generic procedure _generic_ from object _obj_, mutating _obj_ in place, and exposing a previously shadowed implementation of _generic_ added earlier via `add-method!`, if there is one. If _obj_ does not implement _generic_, `delete-method!` has no effect.

**(make-generic-procedure)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  
**(make-generic-procedure _default_)**  

Returns a new generic procedure `(lambda (obj arg ...) ...)` implementing dynamic dispatch on its first argument _obj_: if _obj_ is an object (as defined by `object?`) implementing a method for this generic procedure, that method is applied to _obj_ and the remaining arguments. Otherwise, _default_ is applied instead, both for objects lacking an implementation of this generic procedure and for arguments that are not objects at all. If _default_ is not provided, invoking the generic procedure in such a case signals an error. `define-generic` provides a more convenient, declarative way to define generic procedures.


## Declarative object interface

**(object ((_delegatevar delegate_) ...) ((_generic self arg ... . rest_) _e1 e2 ..._) ...)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[syntax]</span>  

Creates and returns a new object, combining `make-object` and `add-method!` into a single declarative expression. Each `(_delegatevar delegate_)` clause binds _delegatevar_ to the value of expression _delegate_ and includes it as a delegate of the new object, exactly as with `make-object`; _delegatevar_ is visible in the method bodies below (and in later delegate expressions), which is how objects created with `object` implement inheritance (see the `colored-point` example in the introduction above). Each `((_generic self arg ... . rest_) _e1 e2 ..._)` clause adds a method for generic procedure _generic_ to the new object, equivalent to `(add-method! obj generic (lambda (self arg ... . rest) e1 e2 ...))`. Both the delegate expressions and the method bodies may refer to variables of the surrounding lexical scope, which is how objects created with `object` encapsulate mutable state.

**(define-generic (_name self arg ... . rest_))** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[syntax]</span>  
**(define-generic (_name self arg ... . rest_) _e1 e2 ..._)**  

Defines _name_ as a new generic procedure via `make-generic-procedure`. In the first form, _name_ has no default implementation, and applying it to an object (or value) without a matching method signals an error. In the second form, `(lambda (self arg ... . rest) e1 e2 ...)` is used as the default implementation, applied whenever the first argument is not an object, or is an object without its own method for _name_.

**(invoke (_obj generic_) _self arg ..._)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[syntax]</span>  

Invokes the method that object _obj_ implements for generic procedure _generic_, passing it _self_ and _arg ..._ as arguments, instead of _obj_ and _arg ..._. This is used to call an overridden method of a delegatee object while keeping the identity of the overriding object, as illustrated by the `colored-point` example in the introduction above: `(invoke (super object-description) self)` calls the `object-description` method implemented by the `super` delegate, but passes the colored point itself, rather than `super`, as `self`. Unlike applying _generic_ directly to _obj_, `invoke` signals an error if _obj_ does not implement _generic_, since it does not fall back to a default implementation.


## Procedural class interface

**class-type-tag** <span style="float:right;text-align:rigth;">[constant]</span>  

Symbol representing the `class` type. The `type-for` procedure of library `(lispkit type)` returns this symbol for all class objects.

**(class? _obj_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Returns `#t` if _obj_ is a class object, `#f` otherwise.

**root** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[object]</span>  

The root class object. All class objects have `root` as its direct or indirect superclass object.

**(make-class _name superclasses constructor_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Returns a new class whose name is _name_, which needs to be a symbol, or an error is signaled. _superclasses_ is a list of superclass objects, each of which needs to satisfy `class?`, or an error is signaled. _constructor_ is a procedure, or an error is signaled; it is called whenever an instance of this new class is being created via `make-instance`, with the arguments passed to `make-instance`, and it needs to return two values:

  1. A list of _delegate_ objects, one for each class listed in _superclasses_, in the same order; `make-instance` checks that the _n_-th delegate satisfies `(instance-of? (list-ref superclasses n) delegate)`, and signals an error otherwise. This is how instances of the new class inherit the methods of their superclasses (see `object` for how delegate objects contribute methods).
  2. An initializer procedure `(lambda (instance) ...)`, called by `make-instance` with the newly created _instance_ once its delegates have been combined and its `object-class` method has been set up (so that `object-class` and, transitively, `class-name` are already available within the initializer). The initializer is typically used to `add-method!` further methods to _instance_ that are specific to the new class, rather than inherited from a delegate.

The `define-class` syntax provides a more convenient, declarative way to create classes, expanding into a call to `make-class` with a suitably constructed _constructor_ procedure.

The following example defines a simple `counter` class directly via `make-class`, without any superclasses. Its constructor takes an initial count and returns the two required values: an empty list of delegates (since `counter` has no superclasses) and an initializer procedure that adds `counter-value` and `counter-increment!` methods to the new instance, closing over a private, mutable `count` variable:

```scheme
(define-generic (counter-value self))
(define-generic (counter-increment! self))
(define counter
  (make-class
    'counter
    '()
    (lambda (initial)
      (values
        '()
        (lambda (instance)
          (let ((count initial))
            (add-method! instance counter-value (lambda (self) count))
            (add-method! instance counter-increment!
              (lambda (self) (set! count (+ count 1)) count))))))))
```

Since the constructor's `let` is re-evaluated for every call to `make-instance`, each instance of `counter` gets its own, independent `count`:

```scheme
(define c1 (make-instance counter 10))
(define c2 (make-instance counter 100))
(counter-increment! c1)         ⇒  11
(counter-increment! c1)         ⇒  12
(counter-value c1)              ⇒  12
(counter-value c2)              ⇒  100
(class-name (object-class c1))  ⇒  counter
(instance-of? counter c1)       ⇒  #t
```

This is exactly the underlying mechanism that `define-class` builds on: it expands into a call to `make-class` whose constructor validates and processes _args_, evaluates the `object` expression's delegate clauses into a list of delegates, and wraps the `object` expression's method clauses into an initializer procedure, closely resembling the `counter` example above.

### Instance methods

**(object-class _obj_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[generic procedure]</span>  

Returns the class of object _obj_.

**(object-equal? _obj other_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[generic procedure]</span>  

Returns `#t` if _obj_ and _other_ are considered equal objects. The default implementation (used by objects and classes that do not provide their own `object-equal?` method) compares _obj_ and _other_ with `equal?`. Since objects internally wrap a list of methods (closures), and closures are only `equal?` to themselves, this default effectively behaves like an identity comparison for most objects: two separately constructed objects with equivalent state, but without a custom `object-equal?` method, are generally not considered equal, e.g. `(object-equal? (make-instance point 1 2) (make-instance point 1 2)) ⇒ #f`, even though both instances represent the same coordinates. Classes that need value-based equality should implement their own `object-equal?` method.

**(object-description _obj_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[generic procedure]</span>  

Returns a string representation of object _obj_. The default implementation (used by objects and classes that do not provide their own `object-description` method) converts _obj_ to a string via `write`, e.g. `(object-description (make-object)) ⇒ "#<object #<box ()>>"`.

### Class methods

**(class-name _class_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[generic procedure]</span>  

Returns the class name of _class_.

**(class-direct-superclasses _class_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[generic procedure]</span>  

Returns a list of superclass objects of _class_.

**(subclass? _class other_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[generic procedure]</span>  

Returns `#t` if _class_ is a subclass of class _other_, `#f` otherwise.

**(make-instance _class arg ..._)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[generic procedure]</span>  

Creates and returns a new object of _class_. _arg ..._ are the constructor arguments passed to the constructor of _class_.

**(instance-of? _class obj_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[generic procedure]</span>  

Returns `#t` if _obj_ is an instance of _class_.


## Declarative class interface

**(define-class (_name . args_)**  &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[syntax]</span>  
&nbsp;&nbsp;&nbsp;&nbsp; **(_super ..._)**  
&nbsp;&nbsp;&nbsp;&nbsp; **_init ..._**  
&nbsp;&nbsp;&nbsp;&nbsp; **(object ((_delegatevar delegate_) ...)**  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; **((_generic self arg ... . rest_) _e1 e2 ..._) ...))**  
**(define-class (_name . args_)**  
 &nbsp;&nbsp;&nbsp;&nbsp; **_pred?_**  
&nbsp;&nbsp;&nbsp;&nbsp; **(_super ..._)**  
&nbsp;&nbsp;&nbsp;&nbsp; **_init ..._**  
&nbsp;&nbsp;&nbsp;&nbsp; **(object ((_delegatevar delegate_) ...)**  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; **((_generic self arg ... . rest_) _e1 e2 ..._) ...))**  

Defines _name_ as a new class via `make-class`. The constructor of the class takes _args_ and is expressed in terms of an `object` expression: each _(delegatevar delegate)_ clause becomes a delegate of instances created by this class, and each _((generic self arg ... . rest) e1 e2 ...)_ clause becomes a method implementation of instances of _name_, exactly as with the `object` syntax. The optional _init ..._ expressions are evaluated first, in terms of _args_, before the delegates and methods are set up; they are typically used for validating constructor arguments, as illustrated by the `colored-point` example in the introduction above, which signals an error if the given coordinates are negative.

The second form additionally names a type predicate _pred?_ for instances of _name_, meant to be equivalent to `(lambda (obj) (instance-of? name obj))`.

While the `point`/`colored-point` example in the introduction above shows single inheritance combined with method overriding via `invoke`, a class may also list several superclasses at once. In that case, the `object` expression needs to provide one delegate per superclass, listed in the same order as the superclasses; `make-instance` checks that each delegate is indeed an instance of the corresponding superclass. This is how independently defined classes can be combined via multiple inheritance, without any of the combined classes having to know about each other. The following example defines two small, independent classes, `movable` and `colored`, and then combines both into a `sprite` class that inherits all of their methods purely through delegation, without needing to override or re-implement anything itself:

```scheme
(define-generic (position self))
(define-generic (move! self dx dy))
(define-generic (color self))

(define-class (movable x y) ()
  (object ()
    ((position self) (cons x y))
    ((move! self dx dy) (set! x (+ x dx)) (set! y (+ y dy)))))

(define-class (colored color-name) colored? ()
  (object ()
    ((color self) color-name)))
```

Class `sprite` lists both `movable` and `colored` as superclasses, and provides one delegate for each, created via `make-instance`. Since `sprite` does not need to customize any inherited behavior, its `object` expression has no method clauses of its own; all of its methods are contributed entirely by its two delegates:

```scheme
(define-class (sprite x y color-name) (movable colored)
  (object ((pos (make-instance movable x y))
           (col (make-instance colored color-name)))))
```

Instances of `sprite` behave exactly like instances of `movable` and `colored` for the generic procedures `position`, `move!`, and `color`, while `object-class` and `class-name` still correctly identify them as `sprite` objects, and each instance keeps its own, independent state:

```scheme
(define s1 (make-instance sprite 0 0 'red))
(define s2 (make-instance sprite 10 10 'blue))
(color s1)                      ⇒  red
(position s1)                   ⇒  (0 . 0)
(move! s1 3 4)
(position s1)                   ⇒  (3 . 4)
(position s2)                   ⇒  (10 . 10)
(instance-of? movable s1)       ⇒  #t
(colored? s1)                   ⇒  #t
(class-name (object-class s1))  ⇒  sprite
```
