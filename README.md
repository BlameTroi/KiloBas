# KiloBas

A PureBasic pass through the Kilo "editor in 1k lines of C" tutorial at [`Snaptoken`](https://viewsourcecode.org/snaptoken/kilo/), which is based on code by [`antirez`](https://antirez.com/news/108).

## Status

This is a work in progress. It is likely broken most of the time. I'm using it as a project to learn more about PureBasic. There's nothing new here other than some PureBasic modules as include files for both needed `libc` functions and my own ever growing personal standard library.

## About libc

First, a reminder that the actual includes carry various licenses and copyrights. These are visible in your system's copy of said include files. I plan to properly note the licenses in this code once I'm done with the tutorial, so please refer to the original sources if you care about such things.

I'm doing this on a Mac. The foreign function interface (FFI) in PureBasic is pretty good, but for some things it's best to redefine a system header in PureBasic. The `*.pbi` files in `syslib/` are pretty much transliterations of the C `#define`s into PureBasic constants. Data types and structures are redefined as needed.

I'm making no attempt to support Linux or Windows. Linux might work, I don't think these areas are too different between Darwin and Linux. Anytime a feature test conditional pops up, I assume the path for a MacOS desktop and ignore any other paths.

Generally, constants come over with their C name prefixed by `#`, which is PureBasic's constant flag.

Most functions are accessed using the Prototype feature of PureBasic, but some are called directly via inline C.

I uppercase the libc function names and prefix them with `p` for the prototype and `f` for the actual PureBasic function definition.

The function addresses are resolved at load time using `OpenLibrary()` and `GetFunction()`. This is done for each include's functions at the end of the include. I doubt the penalty at initialization will be noticeable.

## Licensing

I figure this is fair use and I place no restrictions on "my" code. I'll get around to copying in the appropriate licenses from Snaptoken and Apple/OpenBSD/Gnu when I'm finishing up.

## In conclusion

I'm not selling anything here, and I don't warrant my hacked code as being either safe or suitable for anyone besides me.

Happy hacking.

--
[BlameTroi](BlameTroi@Gmail.com)  
is Troy Brumley..

So let it be written...  
...so let it be done.

