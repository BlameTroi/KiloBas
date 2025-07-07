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
;
; I expect to break this as I start making a set of my own libraries independent
; from the system libraries. I want to have a txblib separate from syslib. When
; I start on that I'll have some untangling to do.

; System include libraries (libc):

; XIncludeFile "syslib/ctype.pbi" ; not yet implemented
XIncludeFile "syslib/errno.pbi"
XIncludeFile "syslib/termios.pbi"
; XIncludeFile "syslib/stdio.h" ; not yet implemented
; XIncludeFile "syslib/stdlib.h" ; not yet implemented
XIncludeFile "syslib/unistd.pbi"

; My utility libraries:

; XIncludeFile "syslib/vt100.pbi" ; removing for a bit


; ----- Key press and response mapping ----------------------------------------
;
; I couldn't come up with a better way to generate the control character
; constants so enumeration it is. I'm adding the VT100/ANSI interpretation of
; these as keys for reference.
;
; TODO: Move to a separate include file.

Enumeration ANSI_CHARACTERS 1
  #CTRL_A
  #CTRL_B
  #CTRL_C
  #CTRL_D
  #CTRL_E
  #CTRL_F
  #CTRL_G               ; BEL Terminal bell       \b
  #CTRL_H               ; BS  Backspace           \b
  #CTRL_I               ; HT  Horizontal tab      \t
  #CTRL_J               ; LF  Linefeed (newline)  \n
  #CTRL_K               ; VT  Vertical tab        \v
  #CTRL_L               ; FF  Formfeed            \f
  #CTRL_M               ; CR  Carriage return     \r
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
  #ESCAPE               ; ESC Escape (PB #ESC)   \e
  #DELETE = 127         ; DEL Delete character
EndEnumeration

; ----- The usual x,y coordinates ---------------------------------------------
;
; But these are y,x instead of x,y. To avoid the muscle memory confusion always
; use row and column naming.

Structure tCOORD
  row.i
  col.i
EndStructure

; ----- Common or global data -------------------------------------------------
;
; This needs to land in a `context` structure that is dynamically allocated,
; but at this stage of development global variables suffice.

Global.tCOORD   cursor_position     ; current position
Global.tCOORD   screen_size         ; dimensions of physical screen
Global.tCOORD   message_area        ; start of message output area

Global.tTERMIOS original_termios    ; saved to restore at exit
Global.tTERMIOS raw_termios         ; not really used after set, kept for reference

; ----- Macros for some of the simple VT100 commands --------------------------
;
; This is an ED Erase in Display (J). It takes the following parameters:
;
; <NULL> Same as 0.
;      0 Erase from the active position to end of display.
;      1 Erase from start of the display to the active position.
;      2 Erase the entire screen.
;
; The cursor position is not updated.

Macro VT100_ERASE_SCREEN
  VT100_WRITE_CSI("2J")
EndMacro

; This is a CUP CUrsor Position (H). It takes the following parameters:
;
;  <NULL> Move cursor to home
;     1;1 Move cursor to home
; ROW;COL Move cursor to that ROW and COLUMN.
;
; ROW and COLUMN appear to be consistently one based. This can be changed but
; I'm comfortable assuming the default.
;
; Homing the cursor is a frequent enough operation to warrant its own helper.

Macro VT100_CURSOR_HOME
  VT100_WRITE_CSI("H")
EndMacro

; Row and column should be integers.

Macro VT100_CURSOR_POSITION(row, col)
  VT100_WRITE_CSI(Str(row) + ";" + Str(col) + "H")
EndMacro

; These are DECSC and DECRC Save/Restore Cursor (7/8).
;
; Save or Restore the Cursor's position along with the graphic rendition (SGR)
; and character set (SGS).
;
; These are paired: a DECRC should have been preceded by a DECSC.

Macro VT100_SAVE_CURSOR
  VT100_WRITE_ESC("7")
EndMacro

Macro VT100_RESTORE_CURSOR
  VT100_WRITE_ESC("8")
EndMacro

Macro VT100_ERASE_LINE
  VT100_WRITE_CSI("K") ; EL Erase in line from cursor to eol
EndMacro

; This is RIS Reset to Initial State (c).
;
; The terminal is returned to its "just powered on" state.

Macro VT100_HARD_RESET
  VT100_WRITE_ESC("c")
EndMacro




; ----- Forward declarations --------------------------------------------------
;
; Rather than try to manage just the ones I need, I'm going to declare all
; functions here.

Declare.i VT100_GET_TERMIOS(*p.tTERMIOS)
Declare.i VT100_RAW_MODE(*p.tTERMIOS)
Declare.i VT100_RESTORE_MODE(*p.tTERMIOS)
Declare.i VT100_REPORT_CURSOR_POSITION(*coord.tCOORD)
Declare.i VT100_REPORT_SCREEN_DIMENSIONS(*coord.tCOORD)
Declare.i VT100_WRITE_CSI(s.s)
Declare.i VT100_WRITE_ESC(s.s)
Declare.i VT100_WRITE_STRING(s.s)
Declare.i VT100_STRING_TO_BUFFER(*buf, s.s)

Declare   Abort(s.s, extra.s="", erase.i=#true, reset.i=#false, rc.i=-1)
Declare.i display_message(sev.s, msg.s)
Declare.i Log_Message(sev.s, msg.s)

; ----- Common error exit -----------------------------------------------------
;
; The original code has a `die` procedure. I've created something that allows
; for a little more information if desired.
;
; Unfortunately we can't use the names of the parameters with defaults on
; procedure calls. This parameter ordering puts the values that might be
; overridden at the front of the list.

Procedure.i Abort(s.s, extra.s="", erase.i=#true, reset.i=#false, rc.i=-1)
  If erase
    VT100_ERASE_SCREEN
    VT100_CURSOR_HOME
    VT100_RESTORE_MODE(@original_termios)
  ElseIf reset
    VT100_HARD_RESET
  EndIf
  PrintN("")
  PrintN("kilo.pb fatal error!")
  PrintN(" Message: " + s)
  If extra <> ""
    PrintN(" Extra  : " + extra)
  EndIf
  End rc
EndProcedure

; ----- Disable raw mode/restore prior saved terminal configuration -----------
;
; The code in the C `main` uses `atexit` to ensure that disable_raw_mode is
; called. I believe I can do this in PureBasic by decorating the Procedure
; declaration with either `C` or `Dll` to force the correct ABI.

Procedure.i VT100_GET_TERMIOS(*p.tTERMIOS)
  If -1 = fTCGETATTR(0, *p)
    Abort("Enable_Raw_Mode failed tcgetattr", Str(fERRNO()))
  EndIf
  ProcedureReturn #true
EndProcedure

Procedure.i VT100_RESTORE_MODE(*p.tTERMIOS)
  If -1 = fTCSETATTR(0, #TCSAFLUSH, *p)
    Abort("Disable_Raw_Mode failed tcsetattr", Str(fERRNO()))
  Endif
  ProcedureReturn #true
EndProcedure

Procedure.i VT100_SET_RAW_MODE(*raw.tTERMIOS)
  VT100_GET_TERMIOS(*raw)
  With *raw
    \c_iflag = \c_iflag & ~(#BRKINT | #ICRNL | #INPCK | #ISTRIP | #IXON)
    \c_oflag = \c_oflag & ~(#OPOST)
    \c_cflag = \c_cflag | (#CS8)
    \c_lflag = \c_lflag & ~(#ECHO | #ICANON | #IEXTEN | #ISIG)
    \c_cc[#VMIN] = 0       ; min number of bytes to return from read
    \c_cc[#VTIME] = 1      ; timeout in read (1/10 second)
  EndWith
  If -1 = fTCSETATTR(0, #TCSAFLUSH, *raw)
    Abort("Enable_Raw_Mode failed tcsetattr", Str(fERRNO()))
  EndIf
  ProcedureReturn #true
EndProcedure

; Cursor up 	ESC [ Pn A
; Cursor down 	ESC [ Pn B
; Cursor forward (right) 	ESC [ Pn C
; Cursor backward (left) 	ESC [ Pn D
; Send data to the terminal.
;
; Raw text can be sent after marshaling out of the string and into an ASCII
; byte buffer.
;
; Commands are text with some prefix as defined in the VT100 terminal
; specification.

; ----- Write a string to the terminal ----------------------------------------
;
; To avoid any Unicode/UTF-8 issues I'm build a string of ASCII bytes.
;
; Returns #true if the message was sent correctly, #false if the send failed
; (bytes sent = length to send), and aborts if buffer memory could not be
; allocated.

Procedure.i VT100_WRITE_STRING(s.s)
  Define *buf = AllocateMemory(Len(s) + 8)
  If *buf
    FillMemory(*buf, Len(s) + 8, 0, #PB_ASCII)
    VT100_STRING_TO_BUFFER(*buf, s)
    Define.i sent = fWRITE(1, *buf, Len(s))
    Define.i err = fERRNO()
    FreeMemory(*buf)
    If sent = Len(s)
      ProcedureReturn #true
    EndIf
    ; What error checking could be done here?
    ProcedureReturn #false
  Else
    ; A fatal error.
    Abort("Write_String AllocateMemory failed", Str(fERRNO()))
    ProcedureReturn #false ; never executed
  EndIf
EndProcedure

; ----- Copy a native string into a C string ----------------------------------
;
; This is a very trusting routine. It makes no overflow checks. As the caller
; provides the buffer, the length verification is its responsibility.
;
; Always returns #true.

Procedure.i VT100_STRING_TO_BUFFER(*buf, s.s)
  Define *ptr = *buf
  Define.i i
  For i = 1 To Len(s)
    PokeA(*ptr, Asc(Mid(s, i, 1)))
    *ptr = *ptr + 1
  Next i
  PokeA(*ptr, 0) ; this is not strictly needed
  ProcedureReturn #true
EndProcedure

; ----- Issue terminal commands with any required prefix ---------------------
;
; Terminal commands have a very consistent format.
;
; PREFIX PARAMETERS COMMAND
;
; PREFIX is one of the four options listed below.
;
; PARAMETERS are optional ASCII numeric strings separated by semicolons.
;
; COMMAND is usually a single alphabetic character (case sensitive).
;
; There are four prefixes. I don't know why there are so many options, but
; it is what is is.
;
; ESC - sequence starting with ESC (\x1B)
; CSI - Control Sequence Introducer: sequence starting with ESC [ or CSI (\x9B)
; DCS - Device Control String: sequence starting with ESC P or DCS (\x90)
; OSC - Operating System Command: sequence starting with ESC ] or OSC (\x9D)
;
; Where there are multiple prefix options I will use the ESC [ P ] variants.

; CSI prefixed command:

Procedure.i VT100_WRITE_CSI(s.s)
  Define *buf = AllocateMemory(Len(s) + 8) ; padding for prefix
  If *buf
    FillMemory(*buf, Len(s) + 8, #PB_ASCII)
    PokeA(*buf, $1b)
    PokeA(*buf + 1, '[')
    VT100_STRING_TO_BUFFER(*buf + 2, s)
    Define.i sent = fWRITE(1, *buf, Len(s) + 2)
    FreeMemory(*buf)
    If sent = Len(s) + 2
      ProcedureReturn #true
    Else
      ; error on send
      ProcedureReturn #false
    EndIf
  Else
    ; A fatal error.
    Abort("Write_CSI_Command AllocateMemory failed", Str(fERRNO()))
    ProcedureReturn #false ; never executed
  EndIf
EndProcedure

; ESC prefixed command:

Procedure.i VT100_WRITE_ESC(s.s)
  Define *buf = AllocateMemory(Len(s) + 8) ; padding for prefix
  If *buf
    FillMemory(*buf, Len(s) + 8, #PB_ASCII)
    PokeA(*buf, $1b)
    VT100_STRING_TO_BUFFER(*buf + 1, s)
    Define.i sent = fWRITE(1, *buf, Len(s) + 1)
    If sent = Len(s) + 1
      ProcedureReturn #true
    Else
      ; error on send
      ProcedureReturn #false
    EndIf
  Else
    ; A fatal error.
    Abort("Write_ESC_Command AllocateMemory failed", Str(fERRNO()))
    ProcedureReturn #false ; never executed
  EndIf
EndProcedure

; DCS and OSC are not implemented.




; This is DSR Device Status Report active position (6n).
;
; There are multiple possible DSR requests. I believe the only one I need is
; the current cursor position. The response is a CPR Cursor Position Report.
; Its format is ESC [ row;col R.
;
; This may be the only place I need to parse a response so the parse code
; has not been factored out.
;
; The response values are returned via in/out parameters.

Procedure.i Is_Digit(c.s)
  If Len(c) = 1 And c >= "0" And c <= "9"
    ProcedureReturn #true
  Else
    ProcedureReturn #false
  EndIf
EndProcedure

Procedure.i VT100_REPORT_CURSOR_POSITION(*p.TCOORD)
  ; -1,-1 indicates a failure in the DSR
  *p\row = -1
  *p\col = -1
  If VT100_WRITE_CSI("6n") ; DSR for CPR cursor position report 6n -> r;cR
    Define.a char
    Define.i i
    Define.s s
    ; Read a character at a time until we do not get a character (a time out
    ; on the wait) or the character received is the end marker for the CPR.
    While fREAD(0, @char, 1)
      s = s + Chr(char)
      If char = 'R'
        Break
      EndIf
    Wend
    ; Does this appear to be a valid CPR? \e[#;#R? There is no error checking
    ; beyond this.
    If Len(s) >= 6 And Left(s, 1) = Chr($1b) And Right(s, 1) = "R"
      ; Collect row (digits up to the ;).
      *p\row = 0
      i = 3
      While Is_Digit(Mid(s, i, 1))
        *p\row = *p\row * 10 + Val(Mid(s, i, 1))
        i = i + 1
      Wend
      ; Skip past the assumed ; and collect the column (digits up to the R).
      *p\col = 0
      i = i + 1
      While Is_Digit(Mid(s, i, 1))
        *p\col = *p\col * 10 + Val(Mid(s, i, 1))
        i = i + 1
      Wend
      ProcedureReturn #true
    Else
      ; Invalid CPR format.
      ProcedureReturn #false
    EndIf
  Else
    ; Error in DSR.
    ProcedureReturn #false
  EndIf
EndProcedure

; Report screen size using CUD/CUF and then a CPR. The cursor position is saved
; and restored across this operation. The behavior for CUP 999;999H is not
; defined, so I use CUD/CUF instead
;
; Report_Cursor_Position might report an error, but otherwise I don't check for
; one here.


Procedure.i VT100_REPORT_SCREEN_DIMENSIONS(*p.tCOORD)
  VT100_SAVE_CURSOR
  VT100_WRITE_CSI("999B") ; CUD cursor down this many
  VT100_WRITE_CSI("999C") ; CUF cursor forward this many
  VT100_REPORT_CURSOR_POSITION(*p)
  VT100_RESTORE_CURSOR
  ProcedureReturn #true
EndProcedure

; Display the severity and text of a message. A "message area" will be defined
; later, for now it's the last line of the display.

Procedure.i display_message(sev.s, msg.s)
  VT100_SAVE_CURSOR
  VT100_CURSOR_POSITION(message_area\row, message_area\col)
  VT100_ERASE_LINE
  VT100_WRITE_STRING(sev + ":" + msg)
  VT100_RESTORE_CURSOR
  ProcedureReturn #true
EndProcedure

; ----- System libraries ------------------------------------------------------
; ----- System libraries ------------------------------------------------------
; ----- System libraries ------------------------------------------------------
; ----- System libraries ------------------------------------------------------
; ----- System libraries ------------------------------------------------------
; ----- System libraries ------------------------------------------------------
; ----- System libraries ------------------------------------------------------

; ----- Display rows on the screen --------------------------------------------
;
; The top and bottom two rows are reserved.

Procedure.i cursor_home()
  VT100_CURSOR_POSITION(3, 1)
EndProcedure

Procedure.i draw_rows()
  VT100_SAVE_CURSOR
  cursor_home()
  Define.i row
  For row = 3 To screen_size\row - 3
    VT100_WRITE_STRING(~"~\r\n")
  Next row
  ; Write_string("~")
  VT100_RESTORE_CURSOR
EndProcedure

; ----- Read a key press and return it one byte at a time ---------------------
;
; On macOS read doesn't mark no input as a hard error so check for nothing read
; and handle as if we got an error return flagged #EAGAIN

Procedure.a read_key()
  Define n.i
  Define c.a
  Repeat
    n = fREAD(0, @c, 1)
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

Procedure.i process_key()
  Define c.a = read_key()
  Select c
    Case #CTRL_D ; display screen size.
      Define.tCOORD p
      VT100_REPORT_SCREEN_DIMENSIONS(@p)
      display_message("I", "Screen size: " + Str(p\row) + " x " + Str(p\col))
    Case #CTRL_P
      Define.tCOORD p
      VT100_REPORT_CURSOR_POSITION(@p)
      display_message("I", "Cursor position: " + Str(p\row) + " x " + Str(p\col))
    Case #CTRL_Q
      VT100_CURSOR_POSITION(10, 1)
      ProcedureReturn #true
    Case 'w', 'W'
      ; Define coord.tCOORD
      ; VT100_GET_CURSOR(@coord)
      ; coord\row = coord\row - 1
      ; If coord\row < 1
      ;   coord\row = 23
      ; EndIf
      ; VT100_SET_CURSOR(@coord)
    Case 'a', 'A'
      ; Define coord.tCOORD
      ; VT100_GET_CURSOR(@coord)
      ; coord\col = coord\col - 1
      ; If coord\col < 1
      ;   coord\col = 79
      ; EndIf
      ; VT100_SET_CURSOR(@coord)
    Case 's', 'S'
      ; Define coord.tCOORD
      ; VT100_GET_CURSOR(@coord)
      ; coord\row = coord\row + 1
      ; If coord\row > 23
      ;   coord\row = 1
      ; EndIf
      ; VT100_SET_CURSOR(@coord)
    Case 'd', 'D'
      ; Define coord.tCOORD
      ; VT100_GET_CURSOR(@coord)
      ; coord\row = coord\col - 1
      ; If coord\col < 1
      ;   coord\col = 23
      ; EndIf
      ; VT100_SET_CURSOR(@coord)
    Default
      ; To be provided
  EndSelect
  ProcedureReturn #false
EndProcedure

; ----- Clear and repaint the screen ------------------------------------------

Procedure.i refresh_screen()
  draw_rows()
EndProcedure

; ----- Mainline driver -------------------------------------------------------
;
; This is your basic repeat until done loop. Properly restoring the terminal
; settings needs better plumbing.

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
display_message("I", "Welcome to kilo in PureBasic!")

; The top level mainline is really small.
Repeat
  refresh_screen()
Until process_key()

; Restore the terminal to its original settings.
; TODO: Can I save and restore the complete screen state?
VT100_RESTORE_MODE(@original_termios)

End

; kilo.pb ends here -----------------------------------------------------------
