; kilo.pb -- a PureBasic walkthrough of the kilo.c "editor in 1k lines" tutorial

EnableExplicit

; work in progress.

; ----- Motivation and overview -----------------------------------------------
;
; * Project description:
;
; The kilo.c editor is a minimal vi like editor written in roughly 1,000 lines
; of code. There is also a walk through of a possible development path using C.
; This is an exercise to use kilo as a springboard into PureBasic programming
; at a non-GUI level.
;
; Having a stable reference code base provides structure as I learn to make
; system calls and write larger programs in PureBasic.
;
; * System calls:
;
; PureBasic has functions that can replace many raw system library functions.
; Examples include `AllocateMemory` for `malloc` and `CopyMemory` for `memcpy`.
;
; For functions that don't have PureBasic analogs--or those I haven't found
; yet--PureBasic provides an excellent interface to C code.
;
; So far everything I have needed is found in `libc`, which is `libc.dylib`
; on MacOS.
;
; I'm creating PureBasic Includes (*.pbi) for system functions that I need now
; or might want in the future. These parallel the standard C include files. The
; PureBasic `XIncludeFile` directive includes a file only once, so there is no
; need for pragmas or header guard checks.
;
; There are redundancies and inefficiencies in these includes, but they are
; confined to program initialization. If this becomes an issue, it will be
; fixed later.
;
; * Assumptions and limitations:
;
; This code is by me and for my use only. There are no OS or Compiler version
; checks in either the main project or in the common library includes.
;
; This is running on a MacOS desktop in 2025.

; ----- Bugs, notes, and quirks -----------------------------------------------
;
; * The tutorial suggested piping data on stdin as a way to force an error
;   return from get and set attr. On MacOS this results in a segmentation
;   fault. I could check on the device using `istty` but that isn't really
;   needed.
;
; * PureBasic has limited unsigned integer support. This shouldn't be a problem
;   as I don't do any arithmetic beyond pointer increment or decrement, and I
;   expect user memory to be well under the dividing line for positive and
;   negative numbers.

; ----- Include system library interfaces -------------------------------------
;
; I'm unclear on how to best set the include path. Here I'm assuming that
; the libraries are in a subdirectory of this project. When these reference each
; other they do not specify a directory. This works as I want it to so I'm
; not planning to use `IncludePath`.
; files do not mentioned the subdirectory.

; XIncludeFile "syslib/ctype.pbi" ; not yet implemented
XIncludeFile "syslib/errno.pbi"
XIncludeFile "syslib/termios.pbi"
; XIncludeFile "syslib/stdio.h" ; not yet implemented
; XIncludeFile "syslib/stdlib.h" ; not yet implemented
XIncludeFile "syslib/unistd.pbi"
XIncludeFile "syslib/vt100.pbi"

; ----- Keypress and response mapping -----------------------------------------
;
; I couldn't come up with a better way to generate the control keys so
; enumeration it is.
;
; TODO: Move to a separate include file.

Enumeration CONTROL_KEYS 1 Step 1
  #CTRL_A
  #CTRL_B
  #CTRL_C
  #CTRL_D
  #CTRL_E
  #CTRL_F
  #CTRL_G
  #CTRL_H
  #CTRL_I
  #CTRL_J
  #CTRL_K
  #CTRL_L
  #CTRL_M
  #CTRL_N
  #CTRL_O
  #CTRL_P
  #CTRL_Q
  #CTRL_R
  #CTRL_S
  #CTRL_T
  #CTRL_U
  #CTRL_V
  #CTRL_W
  #CTRL_X
  #CTRL_Y
  #CTRL_Z
EndEnumeration

; ----- Common or global data -------------------------------------------------
;
; This needs to land in a `context` structure that is dynamically allocated, but
; at this stage of development globals suffice.

Global retval.i
Global orig.tTERMIOS
Global raw.tTERMIOS

; ----- Forward declaration of procedures -------------------------------------

; Nothing as of yet.

; ----- Utility functions -----------------------------------------------------

; The original code has a `die` procedure. I've created something that allows
; for a little more information if desired.

Procedure abort(s.s, erase.i=#true, extra.s="", rc.i=-1)
  If erase
    VT100_ERASE_SCREEN()
    VT100_HOME_CURSOR()
  EndIf
  PrintN("")
  PrintN("!Abort! " + s)
  If extra <> ""
    PrintN(extra)
  EndIf
  End rc
EndProcedure

Procedure die(s.s)
  abort(s.s)
EndProcedure

; ----- Disable raw mode/restore prior saved terminal configuration -----------
;
; The code in the C `main` uses `atexit` to ensure that disable_raw_mode is
; called. I believe I can do this in PureBasic by decorating the Procedure
; declaration with either `C` or `Dll` to force the correct ABI but I haven't
; yet.

Procedure disable_raw_mode()
  if -1 = fTCSETATTR(0, #TCSAFLUSH, orig)
    die("disable_raw_mode-tcsetattr")
  endif
EndProcedure

; ----- Enable raw mode for direct terminal access ----------------------------
;
; Save the original terminal configuration and then put the terminal in a raw
; or uncooked configuation.

Procedure enable_raw_mode()
  If -1 = fTCGETATTR(0, orig)
    die("enable_raw_mode-tcgetattr")
  EndIf
  raw = orig
  raw\c_iflag = raw\c_iflag & ~(#BRKINT | #ICRNL | #INPCK | #ISTRIP | #IXON)
  raw\c_oflag = raw\c_oflag & ~(#OPOST)
  raw\c_cflag = raw\c_cflag | (#CS8)
  raw\c_lflag = raw\c_lflag & ~(#ECHO | #ICANON | #IEXTEN | #ISIG)
  raw\c_cc[#VMIN] = 0       ; min number of bytes to return from read
  raw\c_cc[#VTIME] = 1      ; timeout in read (1/10 second)
  If -1 = fTCSETATTR(0, #TCSAFLUSH, raw)
    die("enable_raw_mode-tcsetattr")
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

; ----- Display rows on the screen --------------------------------------------

Procedure editor_draw_rows()
  Define y.i, x.i
  For y = 0 To 23
    ; The following header and trailer writes could be combined but as we
    ; will be adding file text between the writes, separation makes
    ; sense.
    VT100_WRITE_STRING("~")       ; I should probably collapse these calls
    VT100_CRLF()
  Next y
EndProcedure

; ----- Read a keypress and return it one byte at a time ----------------------

Procedure.a editor_read_key()
  Define n.i
  Define c.a
  ; On MacOS read doesn't mark no input as a hard error so check for nothing
  ; read and handle as if we got an error return flagged #EAGAIN
  Repeat
    n = fREAD(0, @c, 1)
    If n = -1
      Define e.i = fERRNO()
      If e <> #EAGAIN
        die("Mainline-read-" + Str(e))
      Else
        n = 0
      Endif
    Endif
  Until n <> 0
  ProcedureReturn c
EndProcedure

; ----- Handle keypress -------------------------------------------------------

Procedure editor_process_key()
  Define c.a = editor_read_key()
  Select c
    Case #CTRL_Q:
      ProcedureReturn 1
  EndSelect
  ProcedureReturn 0
EndProcedure

; ----- Clear and repaint the screen ------------------------------------------

Procedure editor_refresh_screen()
  VT100_ERASE_SCREEN()
  VT100_HOME_CURSOR()
  editor_draw_rows()
  VT100_HOME_CURSOR()
  Define coord.tVT100_COORD_PAIR
  VT100_GET_CURSOR_POSITION(@coord)
EndProcedure

; ----- Mainline driver -------------------------------------------------------

enable_raw_mode()

Repeat
  editor_refresh_screen()
  Define done.i = editor_process_key()
Until done

disable_raw_mode()

; PrintN("")

End
