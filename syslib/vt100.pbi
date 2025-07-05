; vt100.pbi - a bunch of VT100 escape sequences from the Dec VT100 manual.

; ;;;;;;;;; trashing this, need to redo better once I get done with kilo.pb.
; ;;;;;;;;; it may or may not compile, it certainly won't run correctly.
;
; DO NOT INCLUDE
;
; ;;;;;;;;; obsolete
; ;;;;;;;;; obsolete
; ;;;;;;;;; obsolete
; ;;;;;;;;; obsolete
; ;;;;;;;;; obsolete
; ;;;;;;;;; obsolete
; ;;;;;;;;; obsolete
; ;;;;;;;;; obsolete
; ;;;;;;;;; obsolete
; ;;;;;;;;; obsolete
; ;;;;;;;;; obsolete

; work in progress

EnableExplicit

; I'm borrowing the idea of prefixing "system" or "internal" names with an
; underscore. Items named thusly should not be accessed outside their include
; file.

XIncludeFile "unistd.pbi"

; ----- VT100 Support Structures ----------------------------------------------

; Cached command sequence layout. I've moved the length from its natural (to me)
; position at the front to the back of the structure in hopes that addressing this
; via pointers for library routines will be easier.
;
; That worked. There is probably a better way to do this but I'll save it for
; another time.

#_VT100_CMD_SEQUENCE_MAX = 20
Structure _tVT100_CMD_SEQUENCE
  c.a[#_VT100_CMD_SEQUENCE_MAX]
  len.i
EndStructure

; A response from query position, query size; or a arguments to set position.

Structure tVT100_COORD_PAIR
  row.i
  col.i
EndStructure

; Preserve ERRNO for error handling.

Global VT100_ERRNO.i

; ----- VT100 Command Sequences -----------------------------------------------
;
; Here are the terminal commands I use (or expect to use).
;
; These values are almost all from the Dec VT100 Manual, currently found at
; https://vt100.net/.
;
; The _tVT100_CMD_SEQUENCE is an array of ASCII bytes and a length. All of the
; commands are prefixed with $1B (ESC). A low level call to `write` is used to
; sent the command to the terminal.

; Erasing

Global _VT100_CMD_ERASE_CURSOR_EOL._tVT100_CMD_SEQUENCE
Global _VT100_CMD_ERASE_BOL_CURSOR._tVT100_CMD_SEQUENCE
Global _VT100_CMD_ERASE_CURSOR_LINE._tVT100_CMD_SEQUENCE
Global _VT100_CMD_ERASE_CURSOR_EOS._tVT100_CMD_SEQUENCE
Global _VT100_CMD_ERASE_BOS_CURSOR._tVT100_CMD_SEQUENCE
Global _VT100_CMD_ERASE_ENTIRE_SCREEN._tVT100_CMD_SEQUENCE

; Querying

Global _VT100_CMD_GET_CURSOR._tVT100_CMD_SEQUENCE

; Positioning

Global _VT100_CMD_CURSOR_HOME._tVT100_CMD_SEQUENCE
Global _VT100_CMD_CURSOR_UP._tVT100_CMD_SEQUENCE
Global _VT100_CMD_CURSOR_DOWN._tVT100_CMD_SEQUENCE
Global _VT100_CMD_CURSOR_FORWARD._tVT100_CMD_SEQUENCE
Global _VT100_CMD_CURSOR_BACKWARD._tVT100_CMD_SEQUENCE
Global _VT100_CMD_CURSOR_DOWN_MAX._tVT100_CMD_SEQUENCE
Global _VT100_CMD_CURSOR_FORWARD_MAX._tVT100_CMD_SEQUENCE
Global _VT100_CMD_CURSOR_SAVE._tVT100_CMD_SEQUENCE
Global _VT100_CMD_CURSOR_RESTORE._tVT100_CMD_SEQUENCE

; Build the complete command sequence.

Procedure _VT100_LOAD_COMMAND(cmd.s, *seq._tVT100_CMD_SEQUENCE)
  if len(cmd) + 1 >= #_VT100_CMD_SEQUENCE_MAX
    PrintN("Overflow of VT100 sequence for " + cmd.s)
    End -1
  EndIf
  *seq\len = len(cmd) + 1
  *seq\c[0] = 27
  Define i.i
  For i = 1 to len(cmd)
    *seq\c[i] = Asc(Mid(cmd, i, 1))
  Next i
EndProcedure

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

Procedure _VT100_INITIALIZE()

  ; Erasing

  _VT100_LOAD_COMMAND("[0K", _VT100_CMD_ERASE_CURSOR_EOL)
  _VT100_LOAD_COMMAND("[1K", _VT100_CMD_ERASE_BOL_CURSOR)
  _VT100_LOAD_COMMAND("[2K", _VT100_CMD_ERASE_CURSOR_LINE)
  _VT100_LOAD_COMMAND("[0J", _VT100_CMD_ERASE_CURSOR_EOS)
  _VT100_LOAD_COMMAND("[1J", _VT100_CMD_ERASE_BOS_CURSOR)
  _VT100_LOAD_COMMAND("[2J", _VT100_CMD_ERASE_ENTIRE_SCREEN)

  ; Positioning

  ; These all take optional numeric arguments. The defaults (no arguments) are
  ; as named. Since all I've seen a need for so far is upper left (home) and
  ; lower right, I'm going with hard coding for those sequences as well.

  _VT100_LOAD_COMMAND("[H", _VT100_CMD_CURSOR_HOME)
  _VT100_LOAD_COMMAND("[A", _VT100_CMD_CURSOR_UP)
  _VT100_LOAD_COMMAND("[B", _VT100_CMD_CURSOR_DOWN)
  _VT100_LOAD_COMMAND("[C", _VT100_CMD_CURSOR_FORWARD)
  _VT100_LOAD_COMMAND("[D", _VT100_CMD_CURSOR_BACKWARD)
  _VT100_LOAD_COMMAND("7", _VT100_CMD_CURSOR_SAVE)
  _VT100_LOAD_COMMAND("8", _VT100_CMD_CURSOR_RESTORE)

  ; The following two could be combined in a [row;colH command but the behavior
  ; is not defined when one does a position way off the screen to determine its
  ; size. The behavior for the [rowsB and [colsC is defined.

  _VT100_LOAD_COMMAND("[999B", _VT100_CMD_CURSOR_DOWN_MAX)
  _VT100_LOAD_COMMAND("[999C", _VT100_CMD_CURSOR_FORWARD_MAX)

  ; Querying

  _VT100_LOAD_COMMAND("[6n", _VT100_CMD_GET_CURSOR)

EndProcedure

; ----- Primitives ------------------------------------------------------------
;
; These functions return #true for success or #false for failure. See the
; global error information at the top of this module for more details if they
; are available.

; Issue a command sequence to the terminal that is not expecing a response.

Procedure.i _VT100_WRITE_CMD(*cmd._tVT100_CMD_SEQUENCE)
  Define sent.i = fWRITE(1, *cmd, *cmd\len)
  If sent = *cmd\len
    ProcedureReturn #true
  Endif
  ; could add error code here
  ProcedureReturn #false
EndProcedure

; Like WRITE_NO_RESPONSE but a response is expected from the terminal. One
; example would be CMD_GET_CURSOR. The caller must provide a buffer area
; (an array of ascii bytes) and the maximum allowed response length.
;
; The assumption is that the whole response is available after the write
; completes and that there will be timing gap after the response which we
; can use to recognize its end.
;
; If that assumption is wrong, I'll need to determine a way to recognize
; the end. So far the only response expected if from a query of the cursor
; position. The format of the response is ESC [ row ; col R. The rest of
; the status requests are things we won't be using.

Procedure.s HEX_DUMP(*ptr, n.i)
  Define hexes.s = ""
  Define chars.s = ""
  Define c.a = 0
  While n
    c = PeekA(*ptr)
    If fISCNTRL(c)
      chars = chars + "."
    Else
      chars = chars + Chr(c)
    EndIf
    chars = chars + Right("00" + Hex(c), 2)
    *ptr = *ptr + 1
    n = n - 1
  Wend
  ProcedureReturn hexes + "*" + chars + "*"
EndProcedure

; ----- API -------------------------------------------------------------------
;
; These are the external API functions for terminal control. They all return
; #true on success or #false on failure.
;
; There are no lower level primitives for write and read operations, the
; functions are called directly.

; Write a single character to the terminal.

Procedure.i VT100_WRITE_CHARACTER(c.a)
  Define t.a = c
  Define sent.i = fWRITE(1, @t, 1)
  If sent = 1
    ProcedureReturn #true
  EndIf
  ; Could do error handling here
  ProcedureReturn #false
EndProcedure

; Write a PureBasic string to the terminal.
;
; I'm am not clear on the behavior of `write` when a utf-8 string with
; multi-byte characters is sent. I'm going to assume that in my use of
; this code I'm always using US ASCII characters.
;
; I marshall the string into a separate buffer because I couldn't get
; writing @s to work consistently.

Procedure.i VT100_WRITE_STRING(s.s)
  Define *buf = AllocateMemory(Len(s) + 8) 
  If *buf
    FillMemory(*buf, 64, 0, #PB_ASCII) 
    Define i.i 
    Define *ptr = *buf 
    For i = 1 To Len(s) 
      PokeA(*ptr, Asc(Mid(s, i, 1))) 
      *ptr = *ptr + 1 
    Next i 
    Define sent.i = fWRITE(1, *buf, Len(s)) 
    Define err.i = fERRNO() 
    FreeMemory(*buf) 
    If sent = Len(s)
      ProcedureReturn #true
    EndIf
    ; What error checking could be done here?
    ProcedureReturn #false
  EndIf
  ; This is a different error
  ; we should report and exits program as the memory alloc failed
  ProcedureReturn #false
EndProcedure

; Retired 'build a byte buffer' call.
;   Define *buf = AllocateMemory(Len(s) + 8) 
;   If *buf 
;   FillMemory(*resp, 64, 0, #PB_ASCII) 
;   Define i.i 
;   Define *ptr = *buf 
;   For i = 1 To Len(s) 
;     PokeA(*ptr, Asc(Mid(s, i, 1))) 
;     *ptr = *ptr + 1 
;   Next i 
;   Define sent.i = fWRITE(1, *buf, Len(s)) 
;   Define err.i = fERRNO() 
;   FreeMemory(*buf) 
;   If sent = Len(s) 
;     ProcedureReturn #true 
;   EndIf 
;   ; Could do error handling here 
;     PrintN("FATAL: VT100_GET_CURSOR_POSITION could not allocate response buffer.") IN
;     End -1 
;   EndIf 
;   ProcedureReturn #false 
; EndProcedure 

; Home the cursor.
;
; There is an explicit terminal command so no coordinates are needed.

Procedure.i VT100_HOME_CURSOR()
  ProcedureReturn _VT100_WRITE_CMD(@_VT100_CMD_CURSOR_HOME)
EndProcedure

; Erases the entire screen without moving the curssor.

Procedure.i VT100_ERASE_SCREEN()
  ProcedureReturn _VT100_WRITE_CMD(@_VT100_CMD_ERASE_ENTIRE_SCREEN)
EndProcedure

; CRLF needed instead of just LF when in raw mode.

Procedure.i VT100_CRLF()
  ProcedureReturn VT100_WRITE_STRING(~"\r\n")
EndProcedure

; Save and restore (I believe on a stack managed by the terminal) the cursor location.

Procedure VT100_SAVE_CURSOR()
  ProcedureReturn _VT100_WRITE_CMD(_VT100_CMD_CURSOR_SAVE)
EndProcedure

Procedure VT100_RESTORE_CURSOR()
  ProcedureReturn _VT100_WRITE_CMD(_VT100_CMD_CURSOR_RESTORE)
EndProcedure

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
; WORKS
Procedure.i VT100_SET_CURSOR(*coord.tVT100_COORD_PAIR)
  Define cmd.s = Chr($1b) + "["
  cmd = cmd + Str(*coord\row)
  cmd = cmd + ";"
  cmd = cmd + Str(*coord\col)
  cmd = cmd + "H"
  ProcedureReturn VT100_WRITE_STRING(cmd)
EndProcedure

; Get the current cursor position.
;
; If the cursor position can't be retrieved, a -1 is returned in *coord.
;
; The format of the response is ESC [ row ; col R.

Procedure.a VT100_READ_CHARACTER()
  Define.a buf
  fREAD(0, @buf, 1)
  ProcedureReturn buf
EndProcedure

Procedure.i VT100_READ_RESPONSE(*buf, n.i, m.a)
  Define.i i
  FillMemory(*buf, n, 0)
  Define *ptr = *buf
  While i < n-1 And *ptr <> m And fREAD(0, *ptr, 1) = 1
    i = i + 1
    *ptr = *ptr + 1
  Wend
  ProcedureReturn i
EndProcedure

Procedure.i VT100_GET_CURSOR(*cur.tVT100_COORD_PAIR)
  Define.a Dim buf(64) ; must address as buf(0)
  Define.i i
  If _VT100_WRITE_CMD(_VT100_CMD_GET_CURSOR)
    Define *ptr = @buf(0)
    Define bc.i = VT100_READ_RESPONSE(*ptr, 63, 'R')
    Print(~"\r\nRead = " + Str(bc))
    For i = 0 to bc
      Print(~"\r\n $" + Hex(buf(i)))
      If fISCNTRL(buf(i))
        Print(" ?")
      Else
        Print(" " + Chr(buf(i)))
      EndIf
    Next i
    Print(~"\r\n\r\nCheckpoint")
    End -1
  Else
    ; Error on write get cursor
    Print(~"\r\nError on write get cursor\r\n")
    ProcedureReturn #false
  EndIf
  ProcedureReturn #true
EndProcedure

; Procedure.i VT100_GET_CURSOR(*coord.tVT100_COORD_PAIR) 
;   *coord\row = -1 
;   *coord\col = -1 
;   If _VT100_WRITE_CMD(_VT100_CMD_GET_CURSOR) 
;     Define *buf = AllocateMemory(64) 
;     If *buf 
;       FillMemory(*buf, 63, 0, #PB_ASCII) 
;       Define c.a ; current character 
;       Define i.i ; character count 
;       ; Read a byte at a time checking for buffer overflow. 
;       Define *ptr = *buf 
;       While fREAD(0, *ptr, 1) = 1 
;         fWRITE(2, *ptr, 1) 
;         If i >= 63 OR *ptr = 'R' 
;           Break 
;         EndIf 
;         i = i + 1 
;         *ptr = *ptr + 1 
;         *ptr = 0 
;         if i >= 63 - 1 
;           Print(HEX_DUMP(*buf, i) + ~"\r\n") 
;           Print(HEX_DUMP(*buf, i) + ~"\r\n") 
;           Print(HEX_DUMP(*buf, i) + ~"\r\n") 
;           PrintN("Buffer overflow on write and response -- read") 
;           ProcedureReturn #false 
;         EndIf 
;       Wend 
;       WriteString(2, HEX_DUMP(*buf, i)) 
;       WriteAsciiCharacter(2, 16) 
;       Print(HEX_DUMP(*buf, i) + ~"\r\n") 
;       Print(HEX_DUMP(*buf, i) + ~"\r\n") 
;       Print(HEX_DUMP(*buf, i) + ~"\r\n") 
;       *coord\row = 0 
;       *coord\col = 0 
;       ; advance to first digit 
;       *ptr = *buf 
;       If *ptr <> $1b 
;         PrintN("Invalid response! 1 " + Hex(PeekA(*ptr))) 
;         End -1 
;       EndIf 
;       *ptr = *ptr + 1 
;       if *ptr <> '[' 
;         PrintN("Invalid response! 2") 
;         End -1 
;       EndIf 
;       *ptr = *ptr + 1 
;       While *ptr <= '9' AND *ptr >= '0' 
;         *coord\row = *coord\row * 10 + (*ptr - '0') 
;         *ptr = *ptr + 1 
;       Wend 
;       if *ptr <> ';' 
;         PrintN("Invalid response! 3") 
;         End -1 
;       EndIf 
;       *ptr = *ptr + 1 
;       While *ptr <= '9' AND *ptr >= '0' 
;         *coord\col = *coord\col * 10 + (*ptr - '0') 
;         *ptr = *ptr + 1 
;       Wend 
;       If *ptr <> 'R' 
;         PrintN("Invalid response! 4") 
;         End -1 
;       EndIf 
;       VT100_RESTORE_CURSOR() ; drop? 
;       FreeMemory(*buf) 
;       ProcedureReturn #true 
;     EndIf 
;     ; Do error reporting for failed write and response 
;     FreeMemory(*buf) 
;     ProcedureReturn #false 
;   EndIf 
;   ; Do error reporting for allocate failure 
;   ProcedureReturn #false 
; EndProcedure 

; Report screen size.
;
; Procedure VT100_GET_SCREEN_SIZE(*coord.tVT100_COORD_PAIR) 
;   *coord\x = -1 
;   *coord\y = -1 
;
;   VT100_SAVE_CURSOR() 
;
;   _VT100_WRITE_CMD(_VT100_CMD_CURSOR_DOWN_MAX) 
;   _VT100_WRITE_CMD(_VT100_CMD_CURSOR_FORWARD_MAX) 
;
;   Define *resp = AllocateMemory(64) 
;   If NOT *resp 
;     PrintN("FATAL: VT100_GET_CURSOR_POSITION could not allocate response buffer.") 
;     End -1 
;   EndIf 
;   FillMemory(*resp, 64, 0, #PB_ASCII) 
;
;   Define len.i = _VT100_WRITE_AND_RESPONSE(_VT100_CMD_GET_CURSOR_POS, *resp, 63) 
;   If len < 1 
;     PrintN("Error in get cursor position") 
;     ProcedureReturn 0 
;   EndIf 
;
;   VT100_RESTORE_CURSOR() 
;
;   ; Response is ESC [ 999;999 R 
;
;   ; Rehome to not hork the display 
;   VT100_HOME_CURSOR() 
;   Print(~"\n\r") 
;   Define i.i = 0 
;   Define *p = *resp 
;   While PeekA(*p) 
;     Define c.a = PeekA(*p) 
;     Print(Str(i) + ":" + Hex(c) + ":") 
;     If fISCNTRL(c) 
;       Print(".") 
;     Else 
;       Print(Chr(c)) 
;     EndIf 
;     Print(~"\n\r") 
;     *p = *p + 1 
;   Wend 
;
;   ProcedureReturn 0 
; EndProcedure 

; Determine screen size without updating the screen. Preserves the cursor
; location.

Procedure.i VT100_GET_SCREEN_SIZE(*coord.tVT100_COORD_PAIR)
  VT100_SAVE_CURSOR()
  VT100_ERASE_SCREEN()
  VT100_GET_CURSOR(*coord)
  VT100_RESTORE_CURSOR()
  ProcedureReturn #true
EndProcedure

; ESC [ Pn ; Pn R 	default value: 1 
;
; The CPR sequence reports the active position by means of the parameters. This sequence has two parameter values, the first specifying the line and the second specifying the column. The default condition with no parameters present, or parameters of 0, is equivalent to a cursor at home position. 
;
; The numbering of lines depends on the state of the Origin Mode (DECOM). 
;_
; This control sequence is solicited by a device status report (DSR) sent from the host. 
; From cursor to end of line 	ESC [ K or ESC [ 0 K 
; From beginning of line to cursor 	ESC [ 1 K 
; Entire line containing cursor 	ESC [ 2 K 
; From cursor to end of screen 	ESC [ J or ESC [ 0 J 
; From beginning of screen to cursor 	ESC [ 1 J 
; Entire screen 	ESC [ 2 J 
; ; clear 
; buf\c[0] = #ESC 
; buf\c[1] = Asc("[") 
; buf\c[2] = Asc("2") 
; buf\c[3] = Asc("J") 
; buf\c[4] = 0 
; fWRITE(1, buf, 4) 
; ; home 
; buf\c[2] = Asc("H") 
; buf\c[3] = 0 
; fWrite(1, buf, 3) 
; CUD – Cursor Down – Host to VT100 and VT100 to Host 
; ESC [ Pn B 	default value: 1 
;
; The CUD sequence moves the active position downward without altering the column position. The number of lines moved is determined by the parameter. If the parameter value is zero or one, the active position is moved one line downward. If the parameter value is n, the active position is moved n lines downward. In an attempt is made to move the cursor below the bottom margin, the cursor stops at the bottom margin. Editor Function 
; CUF – Cursor Forward – Host to VT100 and VT100 to Host 
; ESC [ Pn C 	default value: 1 
;
; The CUF sequence moves the active position to the right. The distance moved is determined by the parameter. A parameter value of zero or one moves the active position one position to the right. A parameter value of n moves the active position n positions to the right. If an attempt is made to move the cursor to the right of the right margin, the cursor stops at the right margin. Editor Function 
; CUP – Cursor Position 
; ESC [ Pn ; Pn H 	default value: 1 
;
; The CUP sequence moves 
; int getCursorPosition(int *rows, int *cols) { 
;   if (write(STDOUT_FILENO, "\x1b[6n", 4) != 4) return -1; 
;   printf("\r\n"); 
;   char c; 
;   while (read(STDIN_FILENO, &c, 1) == 1) { 
;     if (iscntrl(c)) { 
;       printf("%d\r\n", c); 
;     } else { 
;       printf("%d ('%c')\r\n", c, c); 
;     } 
;   } 
;   editorReadKey(); 
;   return -1; 
; } 
; int getWindowSize(int *rows, int *cols) { 
;   struct winsize ws; 
;   if (1 || ioctl(STDOUT_FILENO, TIOCGWINSZ, &ws) == -1 || ws.ws_col == 0) { 
;     if (write(STDOUT_FILENO, "\x1b[999C\x1b[999B", 12) != 12) return -1; 
;     return getCursorPosition(rows, cols); 
;   } else { 
;     *cols = ws.ws_col; 
;     *rows = ws.ws_row; 
;     return 0; 
;   } 
; } 
; Procedure.i VtQuerySize(*res.tVT100_COORD_PAIR) 
; EndProcedure 

; ------ Any initialization for this support library --------------------------

_VT100_INITIALIZE()

; vt100.pbi ends here ---------------------------------------------------------
