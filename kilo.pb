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

; ----- Macros (I wish) -------------------------------------------------------

; Macros in PureBasic don't appear to be as flexible as C preprocessor macros. I
; will just define the constants that I would normally define with a macro. This
; may become an include.
;
; I can't use a function so the readability of this approach is poor. I'll switch
; to global variables. The convention of uppercase names means that while it isn't
; a PureBasic constant, I regard it as constant.

Global CTRL_Q.a = Asc("q") & $1f

; ----- I don't want to keep it, but for now globa data -----------------------

Global retval.i
Global orig.sTERMIOS
Global raw.sTERMIOS

; ----- Forward declaration of procedures -------------------------------------

; I'm not sure if `OpenConsole` and `CloseConsole` are needed for this. When I
; run it from a command line prompt without them everything seems fine.

; ----- Forward declaration of procedures -------------------------------------

; ----- Utility functions -----------------------------------------------------

; Common failure exit

Procedure die(s.s)
  PrintN("!Abort! " + s)
  End -1
EndProcedure

; Note: The tutorial suggested piping data on stdin as a way to force an
; error return from get and set attr. On MacOS this gets a results in a
; segmentation fault. It's not worth the effort to try to handle such an
; oddball situation in code so I have not tested a real error through
; these routines.

; Restore the original terminal configuration.

Procedure DisableRawMode()
  if -1 = fTCSETATTR(0, #TCSAFLUSH, orig)
    Die("DisableRawMode-tcsetattr")
  endif
EndProcedure

; Save the original terminal configuration and then put the terminal in a raw
; uncooked configuation.

Procedure EnableRawMode()
  ; Better would be to add DisableRawMode to the atexit chain here, but for 
  ; now it's left hard coded in the mainline.
  If -1 = fTCGETATTR(0, orig)
    Die("EnableRawMode-tcgetattr")
  EndIf
  raw = orig
  raw\c_iflag = raw\c_iflag & ~(#BRKINT | #ICRNL | #INPCK | #ISTRIP | #IXON)
  raw\c_oflag = raw\c_oflag & ~(#OPOST)
  raw\c_cflag = raw\c_cflag | (#CS8)
  raw\c_lflag = raw\c_lflag & ~(#ECHO | #ICANON | #IEXTEN | #ISIG)
  raw\c_cc[#VMIN] = 0       ; min number of bytes to return from read
  raw\c_cc[#VTIME] = 1      ; timeout in read (1/10 second)
  If -1 = fTCSETATTR(0, #TCSAFLUSH, raw)
    Die("EnableRawMode-tcsetattr")
  EndIf
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

; ----- Read a keypress and return it one byte at a time ----------------------

Procedure.a EditorReadKey()
  Define n.i
  Define buf.PB_BUFFER
  ; On MacOS read doesn't mark no input as a hard error so check for nothing
  ; read and handle as if we got an error return flagged #EAGAIN
  Repeat
    n = fREAD(0, buf, 1)
    If n = -1
      Define e.i = fERRNO()
      If e <> #EAGAIN
        die("Mainline-read-" + Str(e))
      Else
        n = 0
      Endif
    Endif
  Until n <> 0
  ProcedureReturn buf\c[0]
EndProcedure

; ----- Handle keypress -------------------------------------------------------

Procedure EditorProcessKey()
  Define c.a = EditorReadKey()
  Select c
    Case CTRL_Q:
      ProcedureReturn 1
  EndSelect
  ProcedureReturn 0
EndProcedure

; ----- Clear and repaint the screen ------------------------------------------

Procedure EditorRefreshScreen()
  Define buf.PB_BUFFER
  buf\c[0] = 27
  buf\c[1] = Asc("[")
  buf\c[2] = Asc("2")
  buf\c[3] = Asc("J")
  fWRITE(1, buf, 4)
EndProcedure

; ----- Mainline driver -------------------------------------------------------

EnableRawMode()

Repeat
  EditorRefreshScreen()
  Define done.i = EditorProcessKey()
Until done

DisableRawMode()

; PrintN("")

End
