; kilo.pb -- a PureBasic walkthrough of the kilo.c "editor in 1k lines" tutorial

; work in progress.

EnableExplicit

; ----- System libraries ------------------------------------------------------
;
; While I think everything used comes out of libc, I'm thinking the best
; approach is to have separate include files for each section. There will be
; redundancy, but i'll manage. Things to consider include lazy initialization
; and better error reporting.
;
; Use `XIncludeFile` to include each file only once. I don't know where I'm
; going to put common library code yet, but once I figure that out the
; directory is indicated by an in source `IncludePath "path"` and not a
; compiler command line option.
;
; For now, functions are resolved from top to bottom in this file with no
; concern for startup time. 

; IncludePath ""
; XIncludeFile ctype.pbi
XIncludeFile "syslib/errno.pbi"
XIncludeFile "syslib/termios.pbi"
; XIncludeFile "stdio.h"
; XIncludeFile "stdlib.h"
; XIncludeFile "unistd.h"

; ----- I don't want to keep it, but for now globa data -----------------------

Global retval.i
Global orig.sTERMIOS
Global raw.sTERMIOS

; OpenConsole()
; ----- Forward declaration of procedures -------------------------------------

; Terminal control and management:

Procedure die(s.s)
  PrintN("Abort! " + s)
  End
EndProcedure

Procedure DisableRawMode()
  fTCSETATTR(0, #TCSAFLUSH, orig)
EndProcedure

Procedure EnableRawMode()
  fTCGETATTR(0, orig)
  raw = orig
  raw\c_iflag = raw\c_iflag & ~(#BRKINT | #ICRNL | #INPCK | #ISTRIP | #IXON)
  raw\c_oflag = raw\c_oflag & ~(#OPOST)
  raw\c_cflag = raw\c_cflag | (#CS8)
  raw\c_lflag = raw\c_lflag & ~(#ECHO | #ICANON | #IEXTEN | #ISIG)
  raw\c_cc[#VMIN] = 0       ; min number of bytes to return from read
  raw\c_cc[#VTIME] = 1      ; timeout in read (1/10 second)
  retval = fTCSETATTR(0, #TCSAFLUSH, raw)
  retval = fTCGETATTR(0, raw)
EndProcedure

; ----- System libraries ------------------------------------------------------
; ----- System libraries ------------------------------------------------------
; ----- System libraries ------------------------------------------------------
; ----- System libraries ------------------------------------------------------
; ----- System libraries ------------------------------------------------------
; ----- System libraries ------------------------------------------------------
; ----- System libraries ------------------------------------------------------
; ----- System libraries ------------------------------------------------------
; ----- System libraries ------------------------------------------------------
; ----- System libraries ------------------------------------------------------
; ----- System libraries ------------------------------------------------------

EnableRawMode()

define buf.PB_BUFFER

Define c.a = 0
retval = fREAD(0, buf, 1)
c = buf\c[0]
repeat
  if retval = 1
    if fISCNTRL(c) = 1
      printn(hex(c))
    else
      printn(hex(c) + " " + chr(c))
    endif
  endif
  retval = fREAD(0, buf, 1)
  c = buf\c[0]
until c = asc("q")

DisableRawMode()

; CloseConsole()

End
