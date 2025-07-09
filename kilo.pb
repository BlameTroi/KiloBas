; kilo.pb -- a PureBasic walkthrough of the kilo.c "editor in 1k lines" tutorial

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

EnableExplicit

; ----- Include system library interfaces -------------------------------------
;
; I'm unclear on how to best set the include path. Here I'm assuming that the
; libraries are in a sub directory of this project. When these reference each
; other they do not specify a directory. This works as I want it to so I'm not
; planning to use `IncludePath`.

XIncludeFile "syslib/errno.pbi"   ; the errors and how to decode them
XIncludeFile "syslib/termios.pbi" ; the termios structure, defines
XIncludeFile "syslib/unistd.pbi" ; The parts I need.

XIncludeFile "syslib/common.pbi" ; common macros, constants, and procedures

XIncludeFile "syslib/vt100.pbi"  ; VT100/ANSI terminal control API - no UseModule

UseModule errno
UseModule termios
UseModule unistd
UseModule common

; ----- Common or global data -------------------------------------------------
;
; This could be collected into a `context` structure that is dynamically
; allocated, but at this stage of development global variables suffice.

Global.tROWCOL   cursor_position    ; current position
Global.tROWCOL   screen_size        ; dimensions of physical screen
Global.tROWCOL   message_area       ; start of message output area
Global.tROWCOL   top_left           ; bounds of the editable region
Global.tROWCOL   bottom_right       ; NW corner, SE corner
Global.tTERMIOS original_termios   ; saved to restore at exit
Global.tTERMIOS raw_termios        ; not really used after set, kept for reference


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
    vt100::erase_screen
    vt100::cursor_home
    vt100::restore_mode(@original_termios)
  ElseIf reset
    vt100::HARD_RESET
  EndIf
  vt100::cursor_show
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
    ; Keep the cursor in bounds.
    \row = max(\row, top_left\row)
    \row = min(\row, bottom_right\row)
    \col = max(\col, top_left\col)
    \col = min(\col, bottom_right\col)
  EndWith
EndProcedure

Procedure.i cursor_home()
  vt100::cursor_position(top_left\row, top_left\col)
EndProcedure

Procedure.i draw_rows()
  vt100::save_cursor
  Define.i row
  For row = top_left\row To bottom_right\row
    vt100::erase_line
    vt100::write_string(~"~")
    vt100::write_string(~"\r\n")
  Next row
  vt100::restore_cursor
EndProcedure

Procedure.i refresh_screen()
  vt100::cursor_hide
  cursor_home()
  draw_rows()
  vt100::cursor_position(cursor_position\row, cursor_position\col)
  vt100::cursor_show
EndProcedure

; ----- Read a key press and return it one byte at a time ---------------------
;
; On macOS read doesn't mark no input as a hard error so check for nothing read
; and handle as if we got an error return flagged #EAGAIN. Proper handling
; of things such as PF keys is still to do.

Procedure.a read_key()
  Define.i n
  Define.a c
  Repeat
    n = vt100::read_key(c)
    If n = -1
      Define.i e = fERRNO()
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
  Define.a c = read_key()
  Select c
    Case #CTRL_D ; display screen size.
      Define.tROWCOL p
      vt100::report_screen_dimensions(@p)
      vt100::display_message("I", "Screen size: " + Str(p\row) + " x " + Str(p\col), @message_area)
    Case #CTRL_P ; display current cursor position
      Define.tROWCOL p
      vt100::report_cursor_position(@p)
      vt100::display_message("I", "Cursor position: " + Str(p\row) + " x " + Str(p\col), @message_area)
    Case #CTRL_Q ; quit program
      vt100::cursor_position(10, 1)
      ProcedureReturn #true
    Case #CTRL_A ; force an run through the abort path
      vt100::save_cursor
      vt100::cursor_position(5, 8)
      vt100::write_string("Game Over Man!!!")
      vt100::restore_cursor
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
  vt100::get_termios(@original_termios)
  vt100::set_raw_mode(@raw_termios)
  vt100::report_screen_dimensions(@screen_size)
  message_area = screen_size
  message_area\col = 1
  message_area\row = message_area\row - 1
  top_left\row = 3
  top_left\col = 1
  bottom_right = screen_size
  bottom_right\row = bottom_right\row - 3
  ; Greet the user.
  vt100::erase_screen
  cursor_home()
  vt100::report_cursor_position(@cursor_position)
  vt100::display_message("I", "Welcome to kilo in PureBasic!", @message_area)
  ; The top level mainline is really small.
  Repeat
    refresh_screen()
  Until process_key()
  ; Restore the terminal to its original settings.
  ; TODO: Can I save and restore the complete screen state?
  vt100::restore_mode(@original_termios)
EndProcedure

Mainline()

End

; kilo.pb ends here -----------------------------------------------------------
