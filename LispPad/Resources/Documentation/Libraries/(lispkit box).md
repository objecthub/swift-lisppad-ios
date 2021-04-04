# LispKit Box

LispKit is a R7RS-compliant implementation with one exception: pairs are immutable. This library provides implementations of basic mutable data structures with reference semantics: mutable multi-place buffers, also called _boxes_, and mutable pairs. The difference between a two-place box and a mutable pair is that a mutable pair allows mutations of the two elements independent of each other.

## Boxes

**(box? _obj_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Returns `#t` if _obj_ is a box; `#f` otherwise.

**(box _obj ..._)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Returns a new box object that contains the objects _obj ..._.

**(unbox _box_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Returns the current contents of _box_. If multiple values have been stored in the box, `unbox` will return multiple values. This procedure fails if _box_ is not referring to a box.

**(set-box! _box obj ..._)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Sets the content of _box_ to objects _obj ..._. This procedure fails if _box_ is not referring to a box.

**(update-box! _box proc_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Invokes _proc_ with the content of _box_ and stores the result of this function invocation in _box_. `update-box!` is implemented like this:

```scheme
(define (update-box! box proc)
  (set-box! box (apply-with-values proc (unbox box))))
```

## Mutable pairs

**(mpair? _obj_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Returns `#t` if v is a mutable pair (mpair); `#f` otherwise.

**(mcons _car cdr_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Returns a new mutable pair whose first element is set to _car_ and whose second element is set to _cdr_.

**(mcar _mpair_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Returns the first element of the mutable pair _mpair_.

**(mcdr _mpair_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Returns the second element of the mutable pair _mpair_.

**(set-mcar! _mpair obj_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Sets the first element of the mutable pair _mpair_ to _obj_.

**(set-mcdr! _mpair obj_)** &nbsp;&nbsp;&nbsp; <span style="float:right;text-align:rigth;">[procedure]</span>  

Sets the second element of the mutable pair _mpair_ to _obj_.
