; vt100.pbi - a bunch of VT100 escape sequences from the Dec VT100 manual.

; work in progress

; I'm borrowing the idea of prefixing "system" or "internal" names with an
; underscore. Items named thusly should not be accessed outside their include
; file.

XIncludeFile "unistd.pbi"

EnableExplicit

; ----- VT100 Support Structures ----------------------------------------------

; Cached command sequence layout. I've moved the length from its natural (to me)
; position at the front to the back of the structure in hopes that addressing this
; via pointers for library routines will be easier.
;
; That worked. There is probably a better way to do this but I'll save it for
; another time.

#_VT100_SEQUENCE_MAX = 20
Structure _tVT100_SEQUENCE
  c.a[#_VT100_SEQUENCE_MAX]
  len.i
EndStructure

; A response from either query position or query size. This is meant to be 
; externally visible.

; todo: rotate xy.

Structure tVT100_COORD_PAIR
  x.i
  y.i
EndStructure

; ----- VT100 Command Sequences -----------------------------------------------

; There are more commands and queries than I need. As more are needed they can
; be added. The basic idea is a structure with an array of characters and
; a length. A function will call the write terminal function as needed.

; Erasing 

Global _VT100_ERASE_CURSOR_EOL._tVT100_SEQUENCE
Global _VT100_ERASE_BOL_CURSOR._tVT100_SEQUENCE
Global _VT100_ERASE_CURSOR_LINE._tVT100_SEQUENCE
Global _VT100_ERASE_CURSOR_EOS._tVT100_SEQUENCE
Global _VT100_ERASE_BOS_CURSOR._tVT100_SEQUENCE
Global _VT100_ERASE_ENTIRE_SCREEN._tVT100_SEQUENCE

; Querying

Global _VT100_GET_CURSOR_POS._tVT100_SEQUENCE

; Positioning

Global _VT100_CURSOR_HOME._tVT100_SEQUENCE
Global _VT100_CURSOR_DOWN._tVT100_SEQUENCE
Global _VT100_CURSOR_FORWARD._tVT100_SEQUENCE
Global _VT100_CURSOR_DOWN_MAX._tVT100_SEQUENCE
Global _VT100_CURSOR_FORWARD_MAX._tVT100_SEQUENCE

; ----- Helper to fill in the sequence template -------------------------------

; There is a rather simple overflow check. This should only ever be seen during
; development.

Procedure _VT100_LOAD_SEQUENCE(cmd.s, *seq._tVT100_SEQUENCE)
  if len(cmd) + 1 >= #_VT100_SEQUENCE_MAX
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

; ----- Build command sequences -----------------------------------------------

; These values are almost all from the Dec VT100 Manual, currently found at
; https://vt100.net/.

Procedure _VT100_INITIALIZE()

  ; Erasing

  _VT100_LOAD_SEQUENCE("[0K", _VT100_ERASE_CURSOR_EOL)
  _VT100_LOAD_SEQUENCE("[1K", _VT100_ERASE_BOL_CURSOR)
  _VT100_LOAD_SEQUENCE("[2K", _VT100_ERASE_CURSOR_LINE)
  _VT100_LOAD_SEQUENCE("[0J", _VT100_ERASE_CURSOR_EOS)
  _VT100_LOAD_SEQUENCE("[1J", _VT100_ERASE_BOS_CURSOR)
  _VT100_LOAD_SEQUENCE("[2J", _VT100_ERASE_ENTIRE_SCREEN)

  ; Positioning

  ; These all take optional numeric arguments. The defaults (no arguments) are as named.
  ; Since all I've seen a need for so far is upper left (home) and lower right, I'm
  ; going with hard coding for those sequences as well.

  _VT100_LOAD_SEQUENCE("[H", _VT100_CURSOR_HOME)
  _VT100_LOAD_SEQUENCE("[B", _VT100_CURSOR_DOWN)
  _VT100_LOAD_SEQUENCE("[C", _VT100_CURSOR_FORWARD)

  ; The following two could be combined in a [row;colH command but the behavior is not
  ; defined when one does a position way off the screen to determine its size. The
  ; behavior for the [rowsB and [colsC is defined.

  _VT100_LOAD_SEQUENCE("[999B", _VT100_CURSOR_DOWN_MAX)
  _VT100_LOAD_SEQUENCE("[999C", _VT100_CURSOR_FORWARD_MAX)

  ; Querying

  _VT100_LOAD_SEQUENCE("[6n", _VT100_GET_CURSOR_POS)

EndProcedure

; ----- Primitives ------------------------------------------------------------

; The procedure return for all of these is number of bytes written, which sould
; match the length stored in the sequence. If a response from the terminal is needed,
; the return is not yet defined.
;
; Returning < 1 indicates an error.

Procedure.i _VT100_WRITE_NO_RESPONSE(*cmd._tVT100_SEQUENCE)
  Define sent.i = fWRITE(1, *cmd, *cmd\len)
  ; could add error code here
  ProcedureReturn sent.i
EndProcedure

; Sends a request and reads the response into the supplied buffer. Return is -1 for
; an error, 0 is probably an error (no response), and a positive number is the number
; of bytes in the response.

Procedure.i _VT100_WRITE_AND_RESPONSE(*cmd._tVT100_SEQUENCE, *buf.tTCBUFFER, maxlen.i)
  Define sent.i = fWRITE(1, *cmd, *cmd\len)
  If *cmd\len <> sent
    PrintN("Error on write and response -- write")
    ProcedureReturn -1
  EndIf
  FillMemory(*buf, maxlen, 0, #PB_ASCII)
  ; The expectation here is the whole response is available and when we do not
  ; get a character on a read, we have reached the end of the response.

  Define c.a
  Define i.i
  While fREAD(0, @c, 1) = 1
    *buf\c[i] = c
    i = i + 1
    if i >= maxlen
      PrintN("Buffer overflow on write and response -- read")
      ProcedureReturn -1
    EndIf
  Wend
  ProcedureReturn i
EndProcedure

; ----- Higher level requests -------------------------------------------------

; The procedure return for all of these is 0 for success and anything else for
; an error. I know that's backwards from booleans but it makes sense to me.

Procedure.i VT100_HOME_CURSOR()
  ProcedureReturn _VT100_WRITE_NO_RESPONSE(@_VT100_CURSOR_HOME) - _VT100_CURSOR_HOME\len
EndProcedure

Procedure.i VT100_ERASE_SCREEN()
  ProcedureReturn _VT100_WRITE_NO_RESPONSE(@_VT100_ERASE_ENTIRE_SCREEN) - _VT100_ERASE_ENTIRE_SCREEN\len
EndProcedure

; DSR – Device Status Report 
; ESC [ Ps n 	default value: 0 
;
; Requests and reports the general status of the VT100 according to the following parameter(s). 
; Parameter 	Parameter Meaning 
; 0 	Response from VT100 – Ready, No malfunctions detected (default) 
; 3 	Response from VT100 – Malfunction – retry 
; 5 	Command from host – Please report status (using a DSR control sequence) 
; 6 	Command from host – Please report active position (using a CPR control sequence) 
; int getCursorPosition(int *rows, int *cols) { 
;   char buf[32]; 
;   unsigned int i = 0; 
;   if (write(STDOUT_FILENO, "\x1b[6n", 4) != 4) return -1; 
;   while (i < sizeof(buf) - 1) { 
;     if (read(STDIN_FILENO, &buf[i], 1) != 1) break; 
;     if (buf[i] == 'R') break; 
;     i++; 
;   } 
;   buf[i] = '\0'; 
;   printf("\r\n&buf[1]: '%s'\r\n", &buf[1]); 
;   editorReadKey(); 
;   return -1; 
; } 
; Not implemented.

Procedure.i VT100_GET_CURSOR_POSITION(*coord.tVT100_COORD_PAIR)
  _VT100_WRITE_NO_RESPONSE(_VT100_CURSOR_DOWN_MAX)
  _VT100_WRITE_NO_RESPONSE(_VT100_CURSOR_FORWARD_MAX)

  Define *resp = AllocateMemory(64)
  If NOT *resp
    PrintN("FATAL: VT100_GET_CURSOR_POSITION could not allocate response buffer.")
    End -1
  EndIf
  FillMemory(*resp, 64, 0, #PB_ASCII)

  Define len.i = _VT100_WRITE_AND_RESPONSE(_VT100_GET_CURSOR_POS, *resp, 63)
  If len < 1
    PrintN("Error in get cursor position")
    ProcedureReturn -1
  EndIf

  *coord\x = 0
  *coord\y = 0

  ; Rehome to not hork the display
  VT100_HOME_CURSOR()
  Print(~"\n\r")
  Define i.i = 0
  Define *p = *resp
  While PeekA(*p)
    Define c.a = PeekA(*p)
    Print(Str(i) + ":" + Hex(c) + ":")
    If fISCNTRL(c)
      Print(".")
    Else
      Print(Chr(c))
    EndIf
    Print(~"\n\r")
    *p = *p + 1
  Wend

  ProcedureReturn 0
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
