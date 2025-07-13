# PureBasic library includes

I'm creating enough code that looks reusable to warrant organization into a personal library. The PureBasic include mechanism is nice. No pragmas or guards needed. If you want a file to be included only once, use `XIncludeFile` instead of `IncludeFile`. Modules have a declaration section for anything meant to be visible outside the module definition. Exposed items can be referenced with a module prefix such as `mymod::` or they may be pulled into the current name space with the `UseModule` directive. There is a corresponding `UnuseModule` directive as well.

Included modules can be in separate directories from the including code. There is an `IncludePath` directive but I am unclear on how to set it. Here I'm assuming that the modules are in a sub directory of the project. When I include them from files in the main project directory I prefix them with the sub directory name. When I include these modules in other library modules, I do not add the sub directory prefix.

This does what I want. It looks as if includes are found relative to the file doing the include.

Based on this I don't see a need for an explicit include path in my work.

## Status

This is a work in progress. It may or may not work for anyone other than me. No guarantees!

## About libc

First, a reminder that the actual includes carry various licenses and copyrights. These are visible in your system's copy of said include files. Please see "Licensing" below.

I'm doing this on a Mac. The foreign function interface (FFI) in PureBasic is pretty good, but for some things it's best to redefine a system header in PureBasic. The `*.pbi` files in `syslib/` are pretty much transliterations of the C `#define`s into PureBasic constants. Data types and structures are redefined as needed.

I'm making no attempt to support Linux or Windows. Linux might work, I don't think these areas are too different between Darwin and Linux. Anytime a feature test conditional pops up, I assume the path for a MacOS desktop and ignore any other paths.

Generally, constants come over with their C name prefixed by `#`, which is PureBasic's constant flag.

Most functions are accessed using the Prototype feature of PureBasic, but some are called directly via inline C.

I uppercase the libc function names and prefix them with `p` for the prototype and `f` for the actual PureBasic function definition.

The function addresses are resolved at load time using `OpenLibrary()` and `GetFunction()`. This is done for each include's functions at the end of the include. I doubt the penalty at initialization will be noticeable.

## Licensing

There are modules that map C standard library includes to PureBasic. I have pulled no executable code from the libraries, only reworked the definitions and declarations that I need to see from PureBasic. The standard library has explicit licensing in each C include that I have not copied into my PureBasic modules.

I believe my PureBasic wrapping constitutes fair and reasonable use of the libraries. I distribute no Apple source or binary files directly.

I place no restrictions on "my" code beyond those in the parallel LICENSE file. Essentially my work is public domain/use at your own risk.

If I ever get "a round tuit" I will add more explicit verbiage in the includes.

## In conclusion

I'm not selling anything here, and I don't warrant my hacked code as being either safe or suitable for anyone besides me.

Happy hacking.

--
[BlameTroi](BlameTroi@Gmail.com)  
is Troy Brumley..

So let it be written...  
...so let it be done.

