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

; ----- Include system library interfaces -------------------------------------
;
; I'm unclear on how to best set the include path. Here I'm assuming that
; the libraries are in a sub directory of this project. When these reference each
; other they do not specify a directory. This works as I want it to so I'm
; not planning to use `IncludePath`.
; files do not mentioned the sub directory.

; System include libraries (libc):

; XIncludeFile "syslib/ctype.pbi" ; not yet implemented
XIncludeFile "syslib/errno.pbi"
XIncludeFile "syslib/termios.pbi"
; XIncludeFile "syslib/stdio.h" ; not yet implemented
; XIncludeFile "syslib/stdlib.h" ; not yet implemented
XIncludeFile "syslib/unistd.pbi"

; My utility libraries:

; XIncludeFile "syslib/vt100.pbi" ; removing for a bit


; ----- Keypress and response mapping -----------------------------------------
;
; I couldn't come up with a better way to generate the control character
; constants so enumeration it is. I'm adding the VT100/ANSI interpretation of
; these as keys for reference.
;
; TODO: Move to a separate include file.
; Name 	decimal 	octal 	hex 	C-escape 	Ctrl-Key 	Description 
; BEL 	7 	007 	0x07 	\a 	^G 	Terminal bell 
; BS 	8 	010 	0x08 	\b 	^H 	Backspace 
; HT 	9 	011 	0x09 	\t 	^I 	Horizontal TAB 
; LF 	10 	012 	0x0A 	\n 	^J 	Linefeed (newline) 
; VT 	11 	013 	0x0B 	\v 	^K 	Vertical TAB 
; FF 	12 	014 	0x0C 	\f 	^L 	Formfeed (also: New page NP) 
; CR 	13 	015 	0x0D 	\r 	^M 	Carriage return 
; ESC 	27 	033 	0x1B 	\e* 	^[ 	Escape character 
; DEL 	127 	177 	0x7F 	<none> 	<none> 	Delete character 

Enumeration ANSI_CHARACTERS 1
  #CTRL_A
  #CTRL_B
  #CTRL_C
  #CTRL_D
  #CTRL_E
  #CTRL_F
  #CTRL_G               ; BEL Terminal bell       \b
  #CTRL_H               ; BS  Basckspace          \b
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
; But these are y,x instead of x,y. To avoid the muscle memory confusion
; always use row and column naming.

Structure tCOORD
  row.i
  col.i
EndStructure

; ----- Common or global data -------------------------------------------------
;
; This needs to land in a `context` structure that is dynamically allocated, but
; at this stage of development global variables suffice.

Global.i        retval
Global.tTERMIOS orig
Global.tTERMIOS raw
Global.tCOORD   cursor
Global.tCOORD   dimensions

; ----- Forward declarations --------------------------------------------------
;
; Rather than try to manage just the ones I need, I'm going to declare all
; functions here.

Declare   Abort(s.s, extra.s="", erase.i=#true, reset.i=#false, rc.i=-1)
Declare.i Erase_Screen()
Declare.i Cursor_Home()
Declare.i Reset_Terminal()
Declare.i Cursor_Position(row.i, col.i)
Declare.i Report_Cursor_Position(*coord.tCOORD)
Declare.i Report_Screen_Size(*coord.tCOORD)
Declare   Disable_Raw_Mode()
Declare   Enable_Raw_Mode()
Declare.i Write_String(s.s)
Declare.i String_to_Buffer(*buf, s.s)
Declare.i Write_CSI_Command(s.s)
Declare.i Write_ESC_Command(s.s)

; ----- Common error exit -----------------------------------------------------
;
; The original code has a `die` procedure. I've created something that allows
; for a little more information if desired.
;
; Unfortunately we can't use the names of the parameters with defaults on
; procedure calls. This parameter ordering puts the values that might be
; overridden at the front of the list.

Procedure Abort(s.s, extra.s="", erase.i=#true, reset.i=#false, rc.i=-1)
  If erase
    Erase_Screen()
    Cursor_Home()
    Disable_Raw_Mode()
  ElseIf reset
    Reset_Terminal()
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
; declaration with either `C` or `Dll` to force the correct ABI but I haven't
; yooet.

Procedure Disable_Raw_Mode()
  If -1 = fTCSETATTR(0, #TCSAFLUSH, orig)
    Abort("Disable_Raw_Mode failed tcsetattr", Str(fERRNO()))
  Endif
EndProcedure

; ----- Enable raw mode for direct terminal access ----------------------------
;
; Save the original terminal configuration and then put the terminal in a raw
; or uncooked configuation.

Procedure enable_raw_mode()
  If -1 = fTCGETATTR(0, orig)
    Abort("Enable_Raw_Mode failed tcgetattr", Str(fERRNO()))
  EndIf
  raw = orig
  raw\c_iflag = raw\c_iflag & ~(#BRKINT | #ICRNL | #INPCK | #ISTRIP | #IXON)
  raw\c_oflag = raw\c_oflag & ~(#OPOST)
  raw\c_cflag = raw\c_cflag | (#CS8)
  raw\c_lflag = raw\c_lflag & ~(#ECHO | #ICANON | #IEXTEN | #ISIG)
  raw\c_cc[#VMIN] = 0       ; min number of bytes to return from read
  raw\c_cc[#VTIME] = 1      ; timeout in read (1/10 second)
  If -1 = fTCSETATTR(0, #TCSAFLUSH, raw)
    Abort("Enable_Raw_Mode failed tcsetattr", Str(fERRNO()))
  EndIf
EndProcedure

; Cursor up 	ESC [ Pn A 
; Cursor down 	ESC [ Pn B 
; Cursor forward (right) 	ESC [ Pn C 
; Cursor backward (left) 	ESC [ Pn D 
; Send data to the terminal.
;
; Raw text can be sent after marshaling out of the string and into
; an Ascii byte buffer.
;
; Commands are text with some prefix as defined
; in the VT100 terminal specification. 
;

; ----- Write a string to the terminal ----------------------------------------
;
; To avoid any unicode/utf issues I'm build a string of ascii bytes.
;
; Returns #true if the message was sent correctly, #false if the
; send failed (bytes sent = length to send), and aborts if buffer
; memory could not be allocated.

Procedure.i Write_String(s.s)
  Define *buf = AllocateMemory(Len(s) + 8) 
  If *buf
    FillMemory(*buf, Len(s) + 8, 0, #PB_ASCII) 
    Define i.i 
    String_to_Buffer(*buf, s)
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
; This is a very trusting routine. It makes no overflow checks. As the
; caller provides the buffer, the length verification is its responsibility.
;
; Always returns #true.

Procedure.i String_to_Buffer(*buf, s.s)
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

Procedure.i Write_CSI_Command(s.s)
  Define *buf = AllocateMemory(Len(s) + 8) ; padding for prefix
  If *buf
    FillMemory(*buf, Len(s) + 8, #PB_ASCII)
    PokeA(*buf, $1b)
    PokeA(*buf + 1, '[')
    String_to_Buffer(*buf + 2, s)
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

Procedure.i Write_ESC_Command(s.s)
  Define *buf = AllocateMemory(Len(s) + 8) ; padding for prefix
  If *buf
    FillMemory(*buf, Len(s) + 8, #PB_ASCII)
    PokeA(*buf, $1b)
    String_to_Buffer(*buf + 1, s)
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

; Neither DCS nor OSC have been needed yet so there is no support
; for them.

; ----- Mnemonic helper functions for various commands ------------------------

; This is an ED Erase in Display (J). It takes the following parameters:
;
; <NULL> Same as 0.
;      0 Erase from the active position to end of display.
;      1 Erase from start of the display to the active position.
;      2 Erase the entire screen.
; 
; The cursor position is not updated.

Procedure.i Erase_Screen()
  ProcedureReturn Write_CSI_COMMAND("2J") ; ED Erase in display
EndProcedure

; This is a CUP CUrsor Position (H). It takes the following parameters:
;
;  <NULL> Move cursor to home
;     1;1 Move cursor to home
; ROW;COL Move cursor to that ROW and COLUMN.
;
; ROW and COLUMN appear to be consistently one based. This can be changed
; but I'm comfortable assuming the default.
;
; Homing the cursor is a frequent enough operation to warrant its own
; helper.

Procedure.i Cursor_Home()
  ProcedureReturn Write_CSI_Command("H") ; CUP Cursor position to home
EndProcedure 

Procedure.i Cursor_Position(row.i, col.i)
  ProcedureReturn Write_CSI_Command(Str(row) + ";" + Str(col) + "H")
EndProcedure

; These are DECSC and DECRC Save/Restore Cursor (7/8).
;
; Save or Restore the Cursor's position along with the graphic rendition (SGR) and character
; set (SGS).
;
; These are paired: a DECRC should have been preceeded by a DECSC.

Procedure.i Save_Cursor()
  ProcedureReturn Write_ESC_Command("7")
EndProcedure

Procedure.i Restore_Cursor()
  ProcedureReturn Write_ESC_Command("8")
EndProcedure

; This is RIS Reset to Initial State (c).
;
; The terminal is returned to its "just powered on" state.

Procedure.i Reset_Terminal()
  ProcedureReturn Write_ESC_Command("c")
EndProcedure

; This is DSR Device Status Report active position (6n).
;
; There are multiple possible DSR requests. I believe the only one I need is
; the current cursor position. The response is a CPR Cursor Position Report.
; Its format is ESC [ row;col R.
;
; This may be the only place I need to parse a response so the parse code
; has not been factored out.
;
; The response values are returned via inout parameters.

Procedure.i Is_Digit(c.s)
  If Len(c) = 1 And c >= "0" And c <= "9"
    ProcedureReturn #true
  Else
    ProcedureReturn #false
  EndIf
EndProcedure

Procedure.i Report_Cursor_Position(*p.TCOORD)
  ; -1,-1 indicates a failure in the DSR
  *p\row = -1
  *p\col = -1
  If Write_CSI_Command("6n") ; DSR for CPR cursor position report 6n -> r;cR
    Define.a char
    Define.i i
    Define.s s
    ; Read a character at a time until we do not get a character (a time out
    ; on the wait) or the character received is the end makr for the CPR.
    While fREAD(0, @char, 1)
      s = s + Chr(char)
      If char = 'R'
        Break
      EndIf
    Wend
    ; Does this appear to be a valid CPR? \e[#;#R?
    ; No real error checking in here once we decide the response looks valid.
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

Procedure.i Report_Screen_Size(*p.tCOORD)
  ProcedureReturn #false
EndProcedure

; ----- System libraries ------------------------------------------------------
; ----- System libraries ------------------------------------------------------
; ----- System libraries ------------------------------------------------------
; ----- System libraries ------------------------------------------------------
; ----- System libraries ------------------------------------------------------
; ----- System libraries ------------------------------------------------------
; ----- System libraries ------------------------------------------------------

; ----- Display rows on the screen --------------------------------------------

Procedure editor_draw_rows()
  Write_ESC_Command("7") ; DECSC save cursor
  Define row.i, col.i
  For row = 1 To 23
    Write_String(~"~\r\n")
  Next row
  Write_string("~")
  Write_ESC_Command("8") ; DECRC restore cursor
EndProcedure

; ----- Read a keypress and return it one byte at a time ----------------------
;
; On MacOS read doesn't mark no input as a hard error so check for nothing
; read and handle as if we got an error return flagged #EAGAIN

Procedure.a editor_read_key()
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

; ----- Handle keypress -------------------------------------------------------

Procedure.i editor_process_key()
  Define c.a = editor_read_key()
  Select c
    Case #CTRL_D ; display screen size.
      Write_ESC_Command("7") ; DECSC save cursor
      ; The behavior for CUP 999;999H is not defined, so CUD/CUF instead
      Write_CSI_Command("999B") ; CUD cursor down this many
      Write_CSI_Command("999C") ; CUF cursor forward this many
      Define.tCOORD p
      p\row = -2 : p\col = -2
      Report_Cursor_Position(@p)
      Cursor_Home()
      Write_String("   " + Str(p\row) + " x " + Str(p\col) + "   ")
      Write_ESC_Command("8") ; DECRC restore cursor
    Case #CTRL_P
      Write_ESC_Command("7") ; DECSC save cursor
      Define.tCOORD p
      p\row = -2 : p\col = -2
      Report_Cursor_Position(@p)
      Cursor_Home()
      Write_String("   " + Str(p\row) + " x " + Str(p\col) + "   ")
      Write_ESC_Command("8") ; DECRC restore cursor
    Case #CTRL_Q
      Write_CSI_Command("10;1H") ; CUP cursor position 10 col 1
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
      ; to be determined
    EndSelect
    ProcedureReturn #false
  EndProcedure

; ----- Clear and repaint the screen ------------------------------------------

Procedure editor_refresh_screen()
  Cursor_Home()
  editor_draw_rows()
EndProcedure

; ----- Mainline driver -------------------------------------------------------
;
; This is youre basic repeat until done loop. Properly restoring the terminal
; settings needs better plumbing.

enable_raw_mode()
Erase_Screen()
Repeat
  editor_refresh_screen()
Until editor_process_key()

disable_raw_mode()

End

; kilo.pb ends here -----------------------------------------------------------
