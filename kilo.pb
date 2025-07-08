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
; on macOS.
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
; This is running on a macOS desktop in 2025.

; ----- Bugs, notes, and quirks -----------------------------------------------
;
; * The tutorial suggested piping data on stdin as a way to force an error
;   return from get and set attr. On macOS this results in a segmentation
;   fault. I could check on the device using `istty` but that isn't really
;   needed.
;
; * PureBasic has limited unsigned integer support. This shouldn't be a problem
;   as I don't do any arithmetic beyond pointer increment or decrement, and I
;   expect user memory to be well under the dividing line for positive and
;   negative numbers.
;
; * Most of the example PureBasic code I've seen guards code backwards from
;   my personal coding standards. I'm going to try to use their style.
;
;   I would code:
;
;   If NOT somethingthatreturnsfalseonerror()
;     do error things and exit
;   EndIf
;   guarded code
;
;   But the PureBasic style is:
;
;   If somethingthatreturnsfalseonerror()
;     guarded code
;   Else
;     do error things and exit
;   EndIf
;
; This gets a bit odd feeling when there are multiple error paths to deal
; with.
;
; * Functions that can fail return #true on success and #false on failure.
;   Functions that really don't need to report success or failure are still
;   declared as returning a value as well.

; ----- Include system library interfaces -------------------------------------
;
; I'm unclear on how to best set the include path. Here I'm assuming that the
; libraries are in a sub directory of this project. When these reference each
; other they do not specify a directory. This works as I want it to so I'm not
; planning to use `IncludePath`.

; System include libraries (libc):
;
; These are the parts of the C system includes <.h> that I use.

; XIncludeFile "syslib/ctype.pbi" ; not yet implemented
XIncludeFile "syslib/errno.pbi"
XIncludeFile "syslib/termios.pbi"
; XIncludeFile "syslib/stdio.h" ; not yet implemented
; XIncludeFile "syslib/stdlib.h" ; not yet implemented
XIncludeFile "syslib/unistd.pbi" ; The parts of 

; My utility libraries:

XIncludeFile "syslib/common.pbi" ; common macros, constants, and procedures
XIncludeFile "syslib/vt100.pbi"  ; VT100/ANSI terminal control API

; ----- Forward declarations --------------------------------------------------
;
; None at present.

; ----- Common or global data -------------------------------------------------
;
; This could be collected into a `context` structure that is dynamically
; allocated, but at this stage of development global variables suffice.

Global.tROWCOL   cursor_position    ; current position
Global.tROWCOL   screen_size        ; dimensions of physical screen
Global.tROWCOL   message_area       ; start of message output area
Global.tROWCOL   top_left           ; bounds of the editable region
Global.tROWCOL   bottom_right       ; NW corner, SE corner
Global.tTERMIOS original_termios    ; saved to restore at exit
Global.tTERMIOS raw_termios         ; not really used after set, kept for reference

; ----- Common error exit -----------------------------------------------------
;
; The original code has a `die` procedure. I've created something that allows
; for a little more information if desired.
;
; Unfortunately we can't use the names of the parameters with defaults on
; procedure calls. This parameter ordering puts the values that might be
; overridden at the front of the list.

Procedure abort(s.s, extra.s="", erase.i=#true, reset.i=#false, rc.i=-1)
  If erase
    VT100_ERASE_SCREEN
    VT100_CURSOR_HOME
    VT100_RESTORE_MODE(@original_termios)
  ElseIf reset
    VT100_HARD_RESET
  EndIf
  VT100_CURSOR_SHOW
  abexit(s, extra, rc)
EndProcedure

; ----- Controlling the presentation ------------------------------------------
;
; The screen display is superficially vi like. The top and bottom two rows
; are reserved. As in vi, empty lines are flagged with a tilde (~).
;
; I might try to switch to a format more like that of XEdit in CMS.

Procedure.i move_cursor(c.a)
  With cursor_position
    Select c
      Case 'w', 'W'               ; N
        \row = \row - 1
      Case 'd', 'D'               ; E
        \col = \col + 1
      Case 's', 'S'               ; S
        \row = \row + 1
      Case 'a', 'A'               ; W
        \col = \col - 1
    EndSelect
    ; Keep the cursor in bounds. I check all four possible violations
    ; since the cursor could have been horked up by a bug in other
    ; parts of the editor.
    If \row < 1                   ; N
      \row = 1
    EndIf
    If \col > screen_size\col     ; E
      \col = screen_size\col
    EndIf
    If \row > screen_size\row     ; S
      \row = screen_size\row
    EndIf
    If \col < 1                   ; W
      \col = 1
    EndIf
  EndWith
EndProcedure

Procedure.i cursor_home()
  VT100_CURSOR_POSITION(3, 1)
EndProcedure

Procedure.i draw_rows()
  VT100_SAVE_CURSOR
  Define.i row
  For row = 3 To screen_size\row - 3
    VT100_ERASE_LINE
    VT100_WRITE_STRING(~"~")
    VT100_WRITE_STRING(~"\r\n")
  Next row
  VT100_RESTORE_CURSOR
EndProcedure

Procedure.i refresh_screen()
  VT100_CURSOR_HIDE
  ;VT100_ERASE_SCREEN
  ;VT100_CURSOR_HOME
  cursor_home()
  draw_rows()
  VT100_CURSOR_POSITION(cursor_position\row, cursor_position\col)
  ;VT100_CURSOR_HOME
  ;cursor_home()
  VT100_CURSOR_SHOW
EndProcedure

; ----- Read a key press and return it one byte at a time ---------------------
;
; On macOS read doesn't mark no input as a hard error so check for nothing read
; and handle as if we got an error return flagged #EAGAIN. Proper handling
; of things such as PF keys is still to do.

Procedure.a read_key()
  Define n.i
  Define c.a
  Repeat
    n = VT100_READ_KEY(c)
    If n = -1
      Define e.i = fERRNO()
      If e <> #EAGAIN
        Abort("Editor_Read_Key", Str(e))
      Else
        n = 0
      Endif
    Endif
  Until n <> 0
  ProcedureReturn c
EndProcedure

; ----- Handle key press ------------------------------------------------------
;
; Route control based on mode and key. Try to keep any one Case clause
; short--use Procedures when appropriate.
;
; This procedure returns #true when the user requests that the session end.

Procedure.i process_key()
  Define c.a = read_key()
  Select c
    Case #CTRL_D ; display screen size.
      Define.tROWCOL p
      VT100_REPORT_SCREEN_DIMENSIONS(@p)
      VT100_DISPLAY_MESSAGE("I", "Screen size: " + Str(p\row) + " x " + Str(p\col), @message_area)
    Case #CTRL_P ; display current cursor position
      Define.tROWCOL p
      VT100_REPORT_CURSOR_POSITION(@p)
      VT100_DISPLAY_MESSAGE("I", "Cursor position: " + Str(p\row) + " x " + Str(p\col), @message_area)
    Case #CTRL_Q ; quit program
      VT100_CURSOR_POSITION(10, 1)
      ProcedureReturn #true
    Case #CTRL_A ; force an run through the abort path
      VT100_SAVE_CURSOR
      VT100_CURSOR_POSITION(5, 8)
      VT100_WRITE_STRING("Game Over Man!!!")
      VT100_RESTORE_CURSOR
      Delay(2500)
      abort("You forced an abort", "", #false, #true, -1)
    Case 'w', 'W', 'a', 'A', 's', 'S', 'd', 'D' ; nesw
      move_cursor(c)
    Default
      ; To be provided
  EndSelect
  ProcedureReturn #false
EndProcedure

; ----- Kilo top level --------------------------------------------------------
;
; Set up the screen and do whatever is requested.

Procedure Mainline()
  ; Set up the terminal and identify screen areas.
  VT100_GET_TERMIOS(@original_termios)
  VT100_SET_RAW_MODE(@raw_termios)
  VT100_REPORT_SCREEN_DIMENSIONS(@screen_size)
  message_area = screen_size
  message_area\col = 1
  message_area\row = message_area\row - 1
  ; Greet the user.
  VT100_ERASE_SCREEN
  cursor_home()
  VT100_REPORT_CURSOR_POSITION(@cursor_position)
  VT100_DISPLAY_MESSAGE("I", "Welcome to kilo in PureBasic!", @message_area)
  ; The top level mainline is really small.
  Repeat
    refresh_screen()
  Until process_key()
  ; Restore the terminal to its original settings.
  ; TODO: Can I save and restore the complete screen state?
  VT100_RESTORE_MODE(@original_termios)
EndProcedure

Mainline()

End

; kilo.pb ends here -----------------------------------------------------------
