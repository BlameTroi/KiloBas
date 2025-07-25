; errno.pbi -- everything from the macOS errno.h without the level checks.

; ----- Overview --------------------------------------------------------------
;
; Those parts of <errno.h> that I might need. Some of these may be redundant
; with PureBasic built in procedures but I'm not too worried about that.
;
; This may work with a little modification on something other than macOS.
;
; It is intended that this be both "IncludeFile"ed and "UseModule"ed.

EnableExplicit

DeclareModule errno
  EnableExplicit

  ; ----- Errors from <errno.h> as PureBasic constants --------------------------

  ; There are some preprocessor checks that appear to remove some of these.
  ; I am not bothering with them. The numbers are constants.

  #EPERM           = 1               ; Operation not permitted
  #ENOENT          = 2               ; No such file or directory
  #ESRCH           = 3               ; No such process
  #EINTR           = 4               ; Interrupted system call
  #EIO             = 5               ; Input/output error
  #ENXIO           = 6               ; Device not configured
  #E2BIG           = 7               ; Argument list too long
  #ENOEXEC         = 8               ; Exec format error
  #EBADF           = 9               ; Bad file descriptor
  #ECHILD          = 10              ; No child processes
  #EDEADLK         = 11              ; Resource deadlock avoided
  ; 11 was #EAGAIN
  #ENOMEM          = 12              ; Cannot allocate memory
  #EACCES          = 13              ; Permission denied
  #EFAULT          = 14              ; Bad address
  #ENOTBLK         = 15              ; Block device required
  #EBUSY           = 16              ; Device / Resource busy
  #EEXIST          = 17              ; File exists
  #EXDEV           = 18              ; Cross-device link
  #ENODEV          = 19              ; Operation not supported by device
  #ENOTDIR         = 20              ; Not a directory
  #EISDIR          = 21              ; Is a directory
  #EINVAL          = 22              ; Invalid argument
  #ENFILE          = 23              ; Too many open files in system
  #EMFILE          = 24              ; Too many open files
  #ENOTTY          = 25              ; Inappropriate ioctl for device
  #ETXTBSY         = 26              ; Text file busy
  #EFBIG           = 27              ; File too large
  #ENOSPC          = 28              ; No space left on device
  #ESPIPE          = 29              ; Illegal seek
  #EROFS           = 30              ; Read-only file system
  #EMLINK          = 31              ; Too many links
  #EPIPE           = 32              ; Broken pipe

  ; math software
  #EDOM            = 33              ; Numerical argument out of domain
  #ERANGE          = 34              ; Result too large

  ; non-blocking and interrupt i/o
  #EAGAIN          = 35              ; Resource temporarily unavailable
  #EWOULDBLOCK     = #EAGAIN         ; Operation would block
  #EINPROGRESS     = 36              ; Operation now in progress
  #EALREADY        = 37              ; Operation already in progress

  ; ipc/network software -- argument errors
  #ENOTSOCK        = 38              ; Socket operation on non-socket
  #EDESTADDRREQ    = 39              ; Destination address required
  #EMSGSIZE        = 40              ; Message too long
  #EPROTOTYPE      = 41              ; Protocol wrong type for socket
  #ENOPROTOOPT     = 42              ; Protocol not available
  #EPROTONOSUPPORT = 43           ; Protocol not supported
  #ESOCKTNOSUPPORT = 44           ; Socket type not supported
  #ENOTSUP         = 45              ; Operation not supported
  #EOPNOTSUPP      = #ENOTSUP        ; Operation not supported on socket
  #EPFNOSUPPORT    = 46              ; Protocol family not supported
  #EAFNOSUPPORT    = 47              ; Address family not supported by protocol family
  #EADDRINUSE      = 48              ; Address already in use
  #EADDRNOTAVAIL   = 49             ; Can't assign requested address

  ; ipc/network software -- operational errors
  #ENETDOWN        = 50              ; Network is down
  #ENETUNREACH     = 51              ; Network is unreachable
  #ENETRESET       = 52              ; Network dropped connection on reset
  #ECONNABORTED    = 53              ; Software caused connection abort
  #ECONNRESET      = 54              ; Connection reset by peer
  #ENOBUFS         = 55              ; No buffer space available
  #EISCONN         = 56              ; Socket is already connected
  #ENOTCONN        = 57              ; Socket is not connected
  #ESHUTDOWN       = 58              ; Can't send after socket shutdown
  #ETOOMANYREFS    = 59              ; Too many references: can't splice
  #ETIMEDOUT       = 60              ; Operation timed out
  #ECONNREFUSED    = 61              ; Connection refused

  ; file system.
  #ELOOP           = 62              ; Too many levels of symbolic links
  #ENAMETOOLONG    = 63              ; File name too long

  ; should be rearranged
  #EHOSTDOWN       = 64              ; Host is down
  #EHOSTUNREACH    = 65              ; No route to host
  #ENOTEMPTY       = 66              ; Directory not empty

  ; quotas & mush
  #EPROCLIM        = 67              ; Too many processes
  #EUSERS          = 68              ; Too many users
  #EDQUOT          = 69              ; Disc quota exceeded

  ; Network File System
  #ESTALE          = 70              ; Stale NFS file handle
  #EREMOTE         = 71              ; Too many levels of remote in path
  #EBADRPC         = 72              ; RPC struct is bad
  #ERPCMISMATCH    = 73              ; RPC version wrong
  #EPROGUNAVAIL    = 74              ; RPC prog. not avail
  #EPROGMISMATCH   = 75              ; Program version wrong
  #EPROCUNAVAIL    = 76              ; Bad procedure for program
  #ENOLCK          = 77              ; No locks available
  #ENOSYS          = 78              ; Function not implemented
  #EFTYPE          = 79              ; Inappropriate file type or format
  #EAUTH           = 80              ; Authentication error
  #ENEEDAUTH       = 81              ; Need authenticator

  ; Intelligent device errors
  #EPWROFF         = 82              ; Device power is off
  #EDEVERR         = 83              ; Device error, e.g. paper out

  #EOVERFLOW       = 84              ; Value too large to be stored in data type

  ; Program loading errors
  #EBADEXEC        = 85              ; Bad executable
  #EBADARCH        = 86              ; Bad CPU type in executable
  #ESHLIBVERS      = 87              ; Shared library version mismatch
  #EBADMACHO       = 88              ; Malformed Macho file

  #ECANCELED       = 89              ; Operation canceled

  #EIDRM           = 90              ; Identifier removed
  #ENOMSG          = 91              ; No message of desired type
  #EILSEQ          = 92              ; Illegal byte sequence
  #ENOATTR         = 93              ; Attribute not found

  #EBADMSG         = 94              ; Bad message
  #EMULTIHOP       = 95              ; Reserved
  #ENODATA         = 96              ; No message available on STREAM
  #ENOLINK         = 97              ; Reserved
  #ENOSR           = 98              ; No STREAM resources
  #ENOSTR          = 99              ; Not a STREAM
  #EPROTO          = 100             ; Protocol error
  #ETIME           = 101             ; STREAM ioctl timeout

  ; This value is only discrete when compiling __DARWIN_UNIX03, or KERNEL
  ; #EOPNOTSUPP      = 102             ; Operation not supported on socket

  #ENOPOLICY       = 103             ; No such policy registered

  #ENOTRECOVERABLE = 104             ; State not recoverable
  #EOWNERDEAD      = 105             ; Previous owner died

  #EQFULL          = 106             ; Interface output queue is full
  #ELAST           = 106             ; Must be equal largest errno

  ; ----- Expose errno() and perror() -------------------------------------------

  Prototype _pPERROR(*ptr=0)
  Global fPERROR._pPERROR
  Global LAST_ERRNO.i = 0
  Declare.i fERRNO()

EndDeclareModule

; ----- System library function wrappers --------------------------------------

Module errno
  ; If I am understanding this correctly, the ! lines are passed through to the
  ; C backend during compilation and so what they do there is available
  ; afterward in the code. The v_<blah> is a procedure variable named <blah>.

  ; Get `errno` using C. Note that `errno` is not reset to zero by the library
  ; code between function calls. It is only set when an error occurs, so
  ; I clear it here after I retrieve it.

  Procedure.i fERRNO()
    Define.i error
    !#include <errno.h>
    !extern int errno;
    !v_error=errno;
    !errno=0;
    LAST_ERRNO = error
    ProcedureReturn error
  EndProcedure

EndModule

; ----- Expose perror ---------------------------------------------------------
;
; I wonder if fERRNO() will work if I can't find perror?

If OpenLibrary(0, "libc.dylib")  
  errno::fPERROR = GetFunction(0, "perror")
Else 
  PrintN("Error on open library libc! for perror") 
  End errno::fERRNO()
Endif 

If errno::fPERROR = 0
  PrintN("Error retrieving function perror from libc")
  End errno::fERRNO()
Endif
CloseLibrary(0)

; errno.pbi ends here ---------------------------------------------------------
