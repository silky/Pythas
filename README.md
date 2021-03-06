# Pythas [![Build](https://img.shields.io/travis/pinselimo/Pythas.svg)](https://travis-ci.org/pinselimo/Pythas)

Import Haskell modules as if they were Python modules. If an imported name does not exist as Python module/package, Pythas will traverse the specified subdirectory below your ```cwd``` to look for a matching Haskell file. If one is found it is imported just as if it was a Python module.

If you have a file ```Example.hs``` like in the ```example``` directory, it will be imported and can be used like such:

~~~python
>>>import pythas
>>>import example.example as e
>>>e.hello()
Hello from Haskell!
~~~

You can also just ```from * import```. Try:

~~~python
>>>from example.example import multisin
>>>from math import pi
>>>multisin(2,pi)
2.4492935982947064e-16
~~~

and you'll see: It doesn't stop at invoking side-effects.

## Sequences

Python ```Sequences``` can be passed as linked lists or as arrays. Depending on which flavour of programming you want to embrace. Currently for speed and space reasons arrays are used by the backend, but it should be no problem to change that for those hardcore FP nerds stuck in ```Haskell```-land.
Try things like:

~~~python
>>>from example.example import mapQuarter
>>>mapQuarter(range(1000,5000,1000))
[250.0, 500.0, 750.0, 1000.0]
~~~

While in Haskell lists **have** to be used, in Python any kind of sequence can be handed over. Needless to say, varying types won't be supported.

## Tuples

Tuples are only supported as result types of functions. Tuples as input arguments fall under sequences in Python and are not supported more directly. Try to ```curry``` your functions appropriately. 

~~~python
>>>from example.example import tuple
>>>tuple()
(1,"a")
~~~

You can use tuples to pack results of different types into a single one. It is no problem to nest them and lists or vice versa. Checkout ```test.hs.Test.hs``` to see what Pythas is (successfully) tested for.

## Requirements

Only make sure that ```GHC``` is located in your ```$PATH```. ```Pythas``` is written with compatibility and ease of use in mind. All libraries used in the ```Haskell``` backend are contained in the standard installation of GHC. No requirements exist on the ```Python```ic side of life.

## Install

```Pythas``` can be installed using pip:

~~~sh
$ pip install .
~~~

## Constraints

Only Python versions 3.7 and up are supported. Unfortunately, only [PEP 562] introduced ```__getattr__``` for modules. This renders level of abstraction ```Pythas``` aims for impossible on lower Python versions.

Only functions having their type declared will be imported. You can handle the export of the function yourself by adding a ```foreign export ccall``` for the function, otherwise ```Pythas``` will do that for you. To exclude a function just omit the functions type. Functions of types that are not supported won't get exported either.

All Haskell constants in the IO monad are imported as functions. Due to lists being turned into ```CArray```s or ```CTuple{x}```s, also constant lists must be called like a function without arguments:

~~~python
>>>from example.example import someConstant, haskellList
>>>someConstant
63
>>>haskellList()
[63]
~~~

 ```Pythas``` enforces the file naming scheme of Haskell for  ```.hs``` files as does the ```GHC```! This is primarily due to  ```GHC``` failing to find the imported module at compile time. Thus, we fail early and raise a ```ModuleNotFoundError```.

## Testing

Currently only testing of the library as a whole is implemented. Run:

~~~bash
$ python test/testpythasffi.py
~~~

## License

The Software in this repository is licensed under the LGPLv3 License.
See COPYING.LESSER file for details.

    Pythas  Copyright (C) 2020  Simon Plakolb
    This program comes with ABSOLUTELY NO WARRANTY; for details type `show w'.
    This is free software, and you are welcome to redistribute it
    under certain conditions; see COPYING and COPYING.LESSER.

