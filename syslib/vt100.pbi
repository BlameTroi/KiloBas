; vt100.pbi - a bunch of VT100 escape sequences from the Dec VT100 manual.

EnableExplicit

; work in progress

; ----- Overview --------------------------------------------------------------
;
; A wrapper for using VT100/ANSI terminal control sequences instead of
; (N/PD)CURSES.
;
; I couldn't come up with a way to create command sequence strings for
; the ESC prefix character so there's a little bit of extra work going
; on here.
;
; All of the API procedures are prefixed VT100. Any internal only procedures
; are prefixed _VT100.
;
; All command sequences mnemonic procedures or macros.

; ----- Include system library and local interfaces ---------------------------

XIncludeFile "unistd.pbi"
XIncludeFile "common.pbi"

; ----- Forward declarations --------------------------------------------------
;
; Better would be to put the external use procedure declarations in a
; DeclareModule block.

Declare.i VT100_GET_TERMIOS(*p.tTERMIOS)
Declare.i VT100_RAW_MODE(*p.tTERMIOS)
Declare.i VT100_RESTORE_MODE(*p.tTERMIOS)
Declare.i VT100_REPORT_CURSOR_POSITION(*coord.tROWCOL)
Declare.i VT100_REPORT_SCREEN_DIMENSIONS(*coord.tROWCOL)
Declare.i VT100_WRITE_CSI(s.s)
Declare.i VT100_WRITE_ESC(s.s)
Declare.i VT100_WRITE_STRING(s.s)

; ----- Globals ---------------------------------------------------------------
;
; I'm trying to keep this to a minimum and will probably convert this
; to a PureBasic Module to control scoping.

Global.i VT100_ERRNO

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

; ----- VT100 Command Sequences -----------------------------------------------
;
; These values are almost all from the Dec VT100 Manual, currently found at
; https://vt100.net/.
;
; The _tVT100_CMD_SEQUENCE is an array of ASCII bytes and a length. All of the
; commands are prefixed with $1B (ESC). A low level call to `write` is used to
; sent the command to the terminal.


; Load the command sequence values. I couldn't figure out a way to do this as
; a string literal (there's no escape for ESC) so these are built during
; program initialization.
;
; More proper naming would use the sequence introduction. These are:
;
; ESC - sequence starting with ESC (\x1B)
; CSI - Control Sequence Introducer: sequence starting with ESC [ or CSI (\x9B)
; DCS - Device Control String: sequence starting with ESC P or DCS (\x90)
; OSC - Operating System Command: sequence starting with ESC ] or OSC (\x9D)
;
; Everything I've needed so far is preceeded by CSI.


; Move cursor to row,col (ESC [ row; col H).
; Valid ANSI Mode Control Sequences 
;
;     CPR – Cursor Position Report – VT100 to Host 
;     CUB – Cursor Backward – Host to VT100 and VT100 to Host 
;     CUD – Cursor Down – Host to VT100 and VT100 to Host 
;     CUF – Cursor Forward – Host to VT100 and VT100 to Host 
;     CUP – Cursor Position 
;     CUU – Cursor Up – Host to VT100 and VT100 to Host 
;     DA – Device Attributes 
;     DECALN – Screen Alignment Display (DEC Private) 
;     DECANM – ANSI/VT52 Mode (DEC Private) 
;     DECARM – Auto Repeat Mode (DEC Private) 
;     DECAWM – Autowrap Mode (DEC Private) 
;     DECCKM – Cursor Keys Mode (DEC Private) 
;     DECCOLM – Column Mode (DEC Private) 
;     DECDHL – Double Height Line (DEC Private) 
;     DECDWL – Double-Width Line (DEC Private) 
;     DECID – Identify Terminal (DEC Private) 
;     DECINLM – Interlace Mode (DEC Private) 
;     DECKPAM – Keypad Application Mode (DEC Private) 
;     DECKPNM – Keypad Numeric Mode (DEC Private) 
;     DECLL – Load LEDS (DEC Private) 
;     DECOM – Origin Mode (DEC Private) 
;     DECRC – Restore Cursor (DEC Private) 
;     DECREPTPARM – Report Terminal Parameters 
;     DECREQTPARM – Request Terminal Parameters 
;     DECSC – Save Cursor (DEC Private) 
;     DECSCLM – Scrolling Mode (DEC Private) 
;     DECSCNM – Screen Mode (DEC Private) 
;     DECSTBM – Set Top and Bottom Margins (DEC Private) 
;     DECSWL – Single-width Line (DEC Private) 
;     DECTST – Invoke Confidence Test 
;     DSR – Device Status Report 
;     ED – Erase In Display 
;     EL – Erase In Line 
;     HTS – Horizontal Tabulation Set 
;     HVP – Horizontal and Vertical Position 
;     IND – Index 
;     LNM – Line Feed/New Line Mode 
;     NEL – Next Line 
;     RI – Reverse Index 
;     RIS – Reset To Initial State 
;     RM – Reset Mode 
;     SCS – Select Character Set 
;     SGR – Select Graphic Rendition 
;     SM – Set Mode 
;     TBC – Tabulation Clear 
; ------ Any initialization for this support library --------------------------


; ----- Disable raw mode/restore prior saved terminal configuration -----------
;
; If the client wants to restore the terminal to its configuration before
; it was placed in raw mode, VT100_GET_TERMIOS can be used to retrieve
; the current TERMIOS structure prior to VT100_SET_RAW_MODE.

Procedure.i VT100_GET_TERMIOS(*p.tTERMIOS)
  If -1 = fTCGETATTR(0, *p)
    abexit("Enable_Raw_Mode failed tcgetattr", Str(fERRNO()))
  EndIf
  ProcedureReturn #true
EndProcedure

Procedure.i VT100_RESTORE_MODE(*p.tTERMIOS)
  If -1 = fTCSETATTR(0, #TCSAFLUSH, *p)
    abexit("Disable_Raw_Mode failed tcsetattr", Str(fERRNO()))
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
    abexit("Enable_Raw_Mode failed tcsetattr", Str(fERRNO()))
  EndIf
  ProcedureReturn #true
EndProcedure

; vt100.pbi ends here ---------------------------------------------------------
