pyForOcaml
==========

Why?
----

I've been writing Python code for almost two decades.  I therefore know the
standard Python library really well.  Unfortunately, as helpful as [integrated
pylint checking](http://www.pylint.org/) in my editor can be, it doesn't even come
close to the power of type systems like that inside OCaml.

In plain words: the more code you write in your Python program, the more you miss 
the compile-time checking that is done by languages like OCaml.
There are many errors that manifest as runtime errors under Python,
untraceable by *pylint* or *pychecker* - and which would be caught at compile-time
by any adequately-strong type system of a statically-typed language.

I don't miss the verbosity of C++ or Java, of course - Python's syntax rocks!
It was the reason I left C++ behind and only use it
[when execution speed is paramount](http://users.softlab.ece.ntua.gr/~ttsiod/straylight.html).
But syntax isn't everything - and with the type inference of OCaml, brevity
levels are very similar.

OK, so what did you do?
-----------------------

This is a repository where I will add "ports" of Python's standard library
functions, offering a type-safe OCaml interface.

**TL;DR: Python's stdlib is burned into my brain - so this mini-library will
allow me to code in OCaml using forms of "the Python standard library
functions".**

How to use it?
--------------

Functions returning results, will appear in two forms: the type-safe form, and
the exception-throwing, python-esque, unsafe form. For members of the 'Os'
module (which corresponds to Python's 'os' module), the return value for the
type-safe versions of the functions, is...

    type 'a osResult = Result of 'a | Error of string

For example:

    let abspath x = ...
    let abspath_unsafe = ...

The first one, returns `string osResult`, which means EITHER a string,
or an error string describing the error that happened. The seasoned
python developer can then pattern match on the result...

    let myFolder = match Os.abspath foo
    | Result s - > s
    | Error _ -> ...

...and sleep soundly, knowing that all potential errors of this invocation
to `os.abspath` are called and handled. If he desires the python-styled (i.e.
unsafe) version, he can do so:

    let myFolder = Os.abspath_unsafe foo
    
...but his program will get an exception at runtime if something
goes wrong - as is the case with Python.

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

I have used large parts of Thomas Leonard's code in this. He did a
migration from Python to OCaml, but didn't build a library like this.
I think it would have helped - it sure helps me (my mind is full of Python,
and I have no wish to mind-cache "Yet Another Standard Library (TM)").

So far, all the code is Thomas's, except for my 'py.ml'.

You are missing function foo.bar from Python's stdlib
-----------------------------------------------------

No kiddin. Please send patch providing the missing functionality, and I will
merge it in.

License
-------

GPL2

Contact point
-------------

Thanassis Tsiodras, Dr.-Ing.
e-mail: ttsiodras@gmail.com
web: http://users.softlab.ece.ntua.gr/~ttsiod/
