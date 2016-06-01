pyForOcaml
==========

Why?
----

I've been writing Python code for almost two decades - and I know the
standard Python library really well.  Unfortunately, the correctness of my
programs has suffered in the transition to a dynamically typed language...
As helpful as [integrated pylint checking](http://www.pylint.org/) from
within my editor can be, it doesn't even come close to the power of type
systems like the one inside OCaml.

In plain words: the more code you write in your Python program, the more you miss 
the compile-time checking that is done by languages like OCaml.

Why?

Because there are many errors that manifest as runtime errors under Python,
untraceable by *pylint* or *pychecker* - and which would be caught at compile-time
by a statically-typed language equipped with a strong type system.

Don't misunderstand me - I don't miss the verbosity of C++ or Java, of course.
Python's syntax rocks!  It was the reason I left C++ behind and only use it
[when execution speed is paramount](https://www.thanassis.space/straylight.html).
But syntax isn't everything - and with the type inference of OCaml, brevity levels
are very similar.

OK, so...
---------

**TL;DR: Python's stdlib is burned into my brain - so this mini-library will
allow me to code in OCaml using forms of "the Python standard library
functions".**

This repository will host "ports" of Python's standard library functions to
OCaml - offering a type-safe OCaml interface to their functionality.

How to use it?
--------------

Functions returning results, will appear in two forms: the type-safe form, and
the exception-throwing, python-esque, unsafe form. For members of the 'Os'
module (which corresponds to Python's 'os' module), the return value for the
type-safe versions of the functions, is...

    type 'a osResult = Result of 'a | Error of string

For example, `os.abspath`...

    let abspath x = ...  (* string -> string osResult *)
    let abspath_unsafe = ...  (* string -> string *)

The first form, returns `string osResult`, which means EITHER a string,
or an error string describing the error that happened. The developer can then
pattern match on the result...

    let myFolder = match Os.abspath foo
    | Result s - > s
    | Error _ -> ...

...and sleep soundly, knowing that all potential errors of this invocation
to `os.abspath` are handled. If the python-styled (i.e.  unsafe) version 
is preferred, then that too can be used...

    let myFolder = Os.abspath_unsafe foo
    
...but the program will then get an exception at runtime if something
goes wrong (as is the case with Python).

*A more likely usage scenario*

As I port my Python code to OCaml, I will start with the unsafe form of the
APIs, and when the program works, I will gradually move parts of the code (as
time permits) to the much safer form of the interfaces, by searching for
`_unsafe` and removing it. In this way, I will force myself (via the OCaml
compiler) to handle errors, wherever they may occur.

*Fallbacks*

To assist with the simple case of providing a *fallback* value in case of
error, the library contains a `fallback` helper. For example, to find the
symbolic links under a folder and print them...

    open Py
    ...
    Os.popenAndReadLines "find . -type l"
    |> fallback ["(failed to use 'find' for symlinks!)"]
    |> String.concat "\n\t"
    |> print_endline

or e.g. to list the current folder's contents:

    open Py
    ...
    Os.listdir "."
    |> fallback ["(failed)"]
    |> String.concat ","
    |> print_endline ;

File `test1.ml` contains sample usages of some of the functions ported so far -
have a look.

Is this based on 0install?
--------------------------

I have used large parts of Thomas Leonard's 0install code in this. He did a
migration from Python to OCaml, but didn't build a library like this.
I think it would have helped - it sure helps me (my mind is full of Python,
and I have no wish to mind-cache "Yet Another Standard Library (TM)").

So far, most of the code comes from  Thomas - except for my `py.ml`,
providing the Python 'translations'.

You are missing Python's foo.bar function
-----------------------------------------

No kiddin - I've only ported a small part of `os` and `os.path` so far.
Still, it allows me to write scripts in OCaml that I would have written
in Python.

Please send patches providing the missing functionality, and I will
merge them in.

License
-------

GPL2

Contact point
-------------

Thanassis Tsiodras, Dr.-Ing.

e-mail: ttsiodras@gmail.com

web: https://www.thanassis.space
