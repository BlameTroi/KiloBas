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
; PureBasic has procedures that can replace many raw system library functions.
; Examples include `AllocateMemory` for `malloc` and `CopyMemory` for `memcpy`.
;
; For procedures that don't have PureBasic analogs--or those I haven't found
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
;
; * Error handling:
;
; I started out trying to use robust error handling but that is slowing me down
; and obscuring my view of the things I want to concentrate on. I'm going to
; yank most of the error handling out but leave return values in place so that
; I can add error handling back in once the editor is complete.

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
;   my personal coding standards. I'm started out using this style but I
;   find it to be unnatural. While there may be some dangling code in the
;   PureBasic style, I'm using the Troy style from now on and will retrofit
;   it into existing code when I see the other style.
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
; * Procedures that can fail return #true on success and #false on failure.
;   Procedures that really don't need to report success or failure are still
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
Global.tTERMIOS  original_termios   ; saved to restore at exit
Global.tTERMIOS  raw_termios        ; not really used after set, kept for reference

; ----- Common error exit -----------------------------------------------------
;
; ANSI key sequences are mapped into meaningful integer values.

Enumeration kilo_keys 1000
  #ARROW_UP
  #ARROW_DOWN
  #ARROW_RIGHT
  #ARROW_LEFT
  #DEL_KEY
  #PAGE_UP
  #PAGE_DOWN
  #HOME_KEY
  #END_KEY
EndEnumeration
; The read_key routine can return an error code if needed, but for now that is
; just treated as if the user pressed ESC.
#BAD_SEQUENCE_READ = #ESCAPE

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

Procedure.i move_cursor(c.i)
  With cursor_position
    Select c
      Case #ARROW_UP               ; N
        \row = \row - 1
      Case #ARROW_RIGHT            ; E
        \col = \col + 1
      Case #ARROW_DOWN             ; S
        \row = \row + 1
      Case #ARROW_LEFT             ; W
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

Global Dim keypress_buffer.a(32)

Procedure.i read_key()
  Define.i n, e
  For n = 0 To 31
    keypress_buffer(n) = 0
  Next n
  ; Spin until we get some sort of key. It might be a plain textual key or
  ; the start of an ANSI sequence.
  Repeat
    n = vt100::read_key(keypress_buffer(0))
    If n = -1
      e = fERRNO()
      If e <> #EAGAIN
        Abort("Editor_Read_key", Str(e))
      Else
        n = 0
      EndIf
    EndIf
  Until n<>0
  ; If the key is not ESC, it can be returned straight away.
  If keypress_buffer(0) <> #ESCAPE
    ; There's the Delete key and FN Delete. FN Delete comes through as ESC 3 ~.
    If keypress_buffer(0) = #DELETE
      ProcedureReturn #DEL_KEY
    EndIf
    ProcedureReturn keypress_buffer(0)
  EndIf
  ; Collect the rest of the sequence. If the next read times out then the user
  ; actually pressed ESC. No error checking is done. If one occurs it will be
  ; processed as a time out. So, any error or timeout on the next two
  ; characters read will return a lone ESC to the caller.
  ;
  ; We need to read at least three bytes to identify a sequence, and more may
  ; be needed. Read the next two bytes and if there is an error/time out, just
  ; return an ESC.
  n = vt100::read_key(keypress_buffer(1))
  If n <> 1
    ProcedureReturn #ESCAPE
  EndIf
  n = vt100::read_key(keypress_buffer(2))
  If n <> 1
    ProcedureReturn #BAD_SEQUENCE_READ
  EndIf
  ; If first byte is ESC, further filter on second byte. So far sequences
  ; prefixed by ESC [ and ESC O are supported.
  If keypress_buffer(1) = '['
    ; Numererics are followed by a tilde (~) requiring a fourth byte to complete
    ; the sequence.
    If keypress_buffer(2) >= '0' and keypress_buffer(2) <= '9'
      n = vt100::read_key(keypress_buffer(3))
      If n <> 1 Or keypress_buffer(3) <> '~'
        ProcedureReturn #BAD_SEQUENCE_READ
      EndIf
      Select keypress_buffer(2)
        Case '1', '7'
          ProcedureReturn #HOME_KEY
        Case '3'
          ProcedureReturn #DEL_KEY
        Case '4', '8'
          ProcedureReturn #END_KEY
        Case '5'
          ProcedureReturn #PAGE_UP
        Case '6'
          ProcedureReturn #PAGE_DOWN
        Default
          ProcedureReturn #BAD_SEQUENCE_READ
      EndSelect
    Else
      Select keypress_buffer(2)
        Case 'A'
          ProcedureReturn #ARROW_UP
        Case 'B'
          ProcedureReturn #ARROW_DOWN
        Case 'C'
          ProcedureReturn #ARROW_RIGHT
        Case 'D'
          ProcedureReturn #ARROW_LEFT
        Case 'H'
          ProcedureReturn #HOME_KEY
        Case 'F'
          ProcedureReturn #END_KEY
        Default
          ProcedureReturn #BAD_SEQUENCE_READ
      EndSelect
    EndIf
    ProcedureReturn #BAD_SEQUENCE_READ ; should never get here
  ElseIf keypress_buffer(1) = 'O' ; upper case 'o'
    Select keypress_buffer(2)
      Case 'H'
        ProcedureReturn #HOME_KEY
      Case 'F'
        ProcedureReturn #END_KEY
      Default
        ProcedureReturn #BAD_SEQUENCE_READ
    EndSelect
    ProcedureReturn #BAD_SEQUENCE_READ ; should never get here
  Else
    ProcedureReturn #BAD_SEQUENCE_READ ; but we can get here
  EndIf
  ProcedureReturn #BAD_SEQUENCE_READ ; should never get here
EndProcedure

; ----- Display the keypress buffer as built in read_key ----------------------
;
; The keypress_buffer is a 32 byte nil terminated ASCII byte array. `read_key`
; stores the current keypress there. Many keys result in only one byte stored,
; say for an alphabetic letter, but longer sequences are possible when using
; special keys such as up or down error.
;
; Build a human readable representation of the buffer and display it. This was
; initally for debugging but it may become a permanent feature.

Procedure display_keypress_buffer()
  vt100::save_cursor
  Define.s s = "key: "
  Define.i i
  While keypress_buffer(i)
    If keypress_buffer(i) = #ESCAPE
      s = s + "ESC "
    ElseIf keypress_buffer(i) = ' '
      s = s + "SPC "
    ElseIf keypress_buffer(i) < ' '
      s = s + "^" + Chr('A' + keypress_buffer(i) - 1) + " "
    ElseIf keypress_buffer(i) = #DELETE
      s = s + "DEL "
    Else
      s = s + Chr(keypress_buffer(i)) + " "
    EndIf
    i = i + 1
  Wend
  Define.tROWCOL p
  vt100::cursor_position(top_left\row - 1, top_left\col + 20)
  vt100::write_string(s + "              ")
  vt100::restore_cursor
EndProcedure

; ----- Handle key press ------------------------------------------------------
;
; Route control based on mode and key. Try to keep any one Case clause
; short--use Procedures when appropriate.
;
; A "key" returned from read_key might represent a multi-byte ANSI sequence. If
; so, it is mapped to some value from the kilo_keys enumeration. That
; enumeration starts from 1000.
;
; This procedure returns #true when the user requests that the session end.

Procedure.i process_key()
  Define.i c = read_key()
  display_keypress_buffer()
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
    Case #ARROW_UP, #ARROW_RIGHT, #ARROW_DOWN, #ARROW_LEFT
      display_keypress_buffer()
      move_cursor(c)
    Case #PAGE_UP
      Define.i i
      For i = top_left\row To bottom_right\row
        move_cursor(#ARROW_UP)
      Next i
    Case #PAGE_DOWN
      Define.i i
      For i = top_left\row To bottom_right\row
        move_cursor(#ARROW_DOWN)
      Next i
    Case #HOME_KEY
      cursor_position = top_left
    Case #END_KEY
      cursor_position = bottom_right
      cursor_position\col = top_left\col
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
