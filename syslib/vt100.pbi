; vt100.pbi - a bunch of VT100 escape sequences from the Dec VT100 manual.

; ----- Overview --------------------------------------------------------------
;
; A wrapper for using VT100/ANSI terminal control sequences instead of the
; ubiquitus (N/PD)CURSES.
;
; All of the API procedures should be referenced using the module name prefix of
; `vt100::`. Any procedure name prefixed with an underscore (_) is meant to be
; internal use only. I have to expose them in the module declaration as the
; mnemonic command macros use them.
;
; All procedures are declared as returning an integer even if there is no
; meaningful status to return. This will be #true for success and #false for
; failure.
;
; Some of the "procedures" are macros around procedure calls. They can be used
; like procedures in your code--they all expand to a single statement procedure
; call. Anything more involved requires a "real" procedure.
;
; VT100/ANSI control sequences are documented in a few different places. There
; is an online copy of the actual DEC VT100 manuals at:
;
; https://vt100.net/
;
; and a well formatted quick reference summary at:
;
; https://gist.github.com/ConnerWill/d4b6c776b509add763e17f9f113fd25b#escape
;
; Some of the sequences are marked as "DEC private" but they are widely
; implemented. My reference terminal is kitty.
;
; It is intended that this module is only "IncldueFile"ed. The module name
; prefix 'vt100::' in client code identifies the calls as part of this API.

EnableExplicit

; ----- Include system library and local interfaces ---------------------------

XIncludeFile "unistd.pbi"       ; primarily for read() and write()
XIncludeFile "errno.pbi"        ; you never know
XincludeFile "termios.pbi"      ; terminal control
XIncludeFile "common.pbi"       ; my tool box

; ----- Exposed procedures, macros, and constants -----------------------------

DeclareModule vt100

  UseModule unistd
  UseModule errno
  UseModule termios
  UseModule common

  ; ----- Command sequences are identified by a prefix -------------------------
  ;
  ; Terminal commands have a very consistent format:
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
  ;
  ; Examples: "CSI H"        homes the cursor to 1,1.
  ;           "CSI 10,3 H"   moves the cursor to row 10 column 3.
  ;           "ESC c"        performs a hard reset of the terminal.
  ;
  ; So far DCS and OSC are not needed and no helpers for them exist.
  ;
  ; Thes various _WRITE_xxx procedures should never be called direclty by the
  ; client. Create a new wrapper macro if you need a new command.

  ; ----- API Macros and procedures to issue VT100 commands ---------------------
  ;
  ; While I don't have everything documented yet, I have added descriptions of
  ; most command sequences for these macros and the more complex procedures
  ; that follow.
  ;
  ; These procedures and macros are roughly ordered by increasing complexity.
  ;
  ; Where possible mnemonic macros are used to avoid chasing typos in command
  ; string literals. Note that these use the module prefix `vt100::` in the
  ; generated code. My APIs expect to be included but not "UseModule"ed.

  ; This is an ED Erase in Display (J). It takes the following parameters:
  ;
  ; <NULL> Same as 0.
  ;      0 Erase from the active position to end of display.
  ;      1 Erase from start of the display to the active position.
  ;      2 Erase the entire screen.
  ;
  ; The cursor position is not updated.

  Macro erase_screen
    vt100::_write_csi("2J")
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
  ; Homing the cursor is a frequent enough operation to warrant a separate
  ; macro.

  Macro cursor_home
    vt100::_write_csi("H")
  EndMacro

  ; Row and column should be integers.

  Macro cursor_position(row, col)
    vt100::_write_csi(Str(row) + ";" + Str(col) + "H")
  EndMacro

  ; These are DECSC and DECRC Save/Restore Cursor (7/8).
  ;
  ; Save or Restore the Cursor's position along with the graphic rendition (SGR)
  ; and character set (SGS).
  ;
  ; These are paired: a DECRC should have been preceded by a DECSC.

  Macro save_cursor
    vt100::_write_esc("7")
  EndMacro

  Macro restore_cursor
    vt100::_write_esc("8")
  EndMacro

  ; This is an EL Erase in Line (K).
  ;
  ; It takes no parameters and erases from the cursor position (inclusive) to
  ; the end of the cursor's line (row).

  Macro erase_line
    vt100::_write_csi("K") ; EL Erase in line from cursor to eol
  EndMacro

  ; This is RIS Reset to Initial State (c).
  ;
  ; The terminal is returned to its "just powered on" state. On a hardware VT100
  ; this would also fire POST.

  Macro hard_reset
    vt100::_write_esc("c")
  EndMacro

  ; These are SM Set Mode and RM Reset Mode (h, l).
  ;
  ; There are several settings available. I believe most of these are obsolete,
  ; but a few are still useful.
  ;
  ;                     To Set                   To Reset
  ; Mode Name           Mode          Sequence   Mode       Sequence
  ;
  ; Line feed/new line  New line      ESC [20h   Line feed  ESC [20l
  ; Cursor key mode     Application   ESC [?1h   Cursor     ESC [?1l
  ; ANSI/VT52 mode      ANSI          N/A        VT52       ESC [?2l
  ; Column mode         132 Col       ESC [?3h   80 Col     ESC [?3l
  ; Scrolling mode      Smooth        ESC [?4h   Jump       ESC [?4l
  ; Screen mode         Reverse       ESC [?5h   Normal     ESC [?5l
  ; Origin mode         Relative      ESC [?6h   Absolute   ESC [?6l
  ; Wraparound          On            ESC [?7h   Off        ESC [?7l
  ; Auto repeat         On            ESC [?8h   Off        ESC [?8l
  ; Interlace           On            ESC [?9h   Off        ESC [?9l
  ; Keypad mode         Application   ESC =      Numeric    ESC >
  ; Cursor Visibile     Show          ESC ?25h   Hide       ESC ?25l

  Macro cursor_hide
    vt100::_write_csi("?25l")
  EndMacro

  Macro cursor_show
    vt100::_write_csi("?25h")
  EndMacro

  ; ----- Read from the terminal ------------------------------------------------
  ;
  ; Wrap read() for terminal I/O. This isn't strictly needed and the function is
  ; actually in unistd, but I like the consistency.

  Macro read_key(c)
    fREAD(0, @c, 1)
  EndMacro

  ; ----- Expose API functions --------------------------------------------------

  ; Primary API procedures for vt100.

  Declare.i report_cursor_position(*p.tROWCOL)
  Declare.i write_string(s.s)
  Declare.i report_screen_dimensions(*p.tROWCOL)
  Declare.i display_message(sev.s, msg.s, *pos.tROWCOL, log.i=#false)

  ; These need to be wrapped in the module and should not be called directly.

  Declare.i get_termios(*p.tTERMIOS)
  Declare.i restore_mode(*p.tTERMIOS)
  Declare.i set_raw_mode(*raw.tTERMIOS)

  ; These should never be directly called by the client. They are included to
  ; support the macros that need them.

  Declare.i _write_csi(s.s)
  Declare.i _write_esc(s.s)

EndDeclareModule

Module vt100

  UseModule unistd
  UseModule errno
  UseModule termios
  UseModule common

  ; ----- Globals ---------------------------------------------------------------
  ;
  ; None as yet.

  ; ----- Command sequence prefix helpers. ------------------------------------
  ;
  ; Since embedding an escape input a literal string seems to require a string
  ; concatenation, I decided to provide helpers that put the proper prefix into
  ; a buffer followed by the terminal command.

  ; Apply the CSI prefix to a parameter and command string and send it to the
  ; terminal.

  Procedure.i _write_csi(s.s)
    Define *buf = AllocateMemory(Len(s) + 8) ; padding for prefix
    If *buf
      FillMemory(*buf, Len(s) + 8, #PB_ASCII)
      PokeA(*buf, $1b)
      PokeA(*buf + 1, '[')
      string_to_buffer(s, *buf + 2)
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
      abexit("Write_CSI_Command AllocateMemory failed", Str(fERRNO()))
      ProcedureReturn #false ; never executed
    EndIf
  EndProcedure

  ; Apply the ESC prefix to a parameter and command string and send it to the
  ; terminal.

  Procedure.i _write_esc(s.s)
    Define *buf = AllocateMemory(Len(s) + 8) ; padding for prefix
    If *buf
      FillMemory(*buf, Len(s) + 8, #PB_ASCII)
      PokeA(*buf, $1b)
      string_to_buffer(s, *buf + 1)
      Define.i sent = fWRITE(1, *buf, Len(s) + 1)
      If sent = Len(s) + 1
        ProcedureReturn #true
      Else
        ; error on send
        ProcedureReturn #false
      EndIf
    Else
      ; A fatal error.
      abexit("Write_ESC_Command AllocateMemory failed", Str(fERRNO()))
      ProcedureReturn #false ; never executed
    EndIf
  EndProcedure

  ; ----- Support code for commands as needed.
  ;
  ; Some comands require additional work.

  ; This is DSR Device Status Report active position (6n).
  ;
  ; There are multiple possible DSR requests. I believe the only one I need is
  ; the current cursor position. The response is a CPR Cursor Position Report.
  ; Its format is ESC [ row;col R.
  ;
  ; I think this is the only tie I need to parse a response so the parse code
  ; has not been factored out.
  ;
  ; The response values are returned via an reference to a row/col structure.

  Procedure.i report_cursor_position(*p.tROWCOL)
    ; -1,-1 indicates a failure in the DSR
    *p\row = -1
    *p\col = -1
    If _write_csi("6n") ; DSR for CPR cursor position report 6n -> r;cR
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
        While c_is_num(Mid(s, i, 1))
          *p\row = *p\row * 10 + Val(Mid(s, i, 1))
          i = i + 1
        Wend
        ; Skip past the assumed ; and collect the column (digits up to the R).
        *p\col = 0
        i = i + 1
        While c_is_num(Mid(s, i, 1))
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

  ; ----- Write a string to the terminal ----------------------------------------
  ;
  ; To avoid any Unicode/UTF-8 issues I build a string of ASCII bytes.
  ;
  ; Returns #true if the message was sent correctly, #false if the send failed
  ; (bytes sent = length to send), and aborts if buffer memory could not be
  ; allocated.

  Procedure.i write_string(s.s)
    Define *buf = AllocateMemory(Len(s) + 8)
    If *buf
      FillMemory(*buf, Len(s) + 8, 0, #PB_ASCII)
      string_to_buffer(s, *buf)
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
      abexit("Write_String AllocateMemory failed", Str(fERRNO()))
      ProcedureReturn #false ; never executed
    EndIf
  EndProcedure

  ; ----- Determine screen size -------------------------------------------------
  ;
  ; Report screen size using CUD/CUF and then a CPR. The cursor position is
  ; saved and restored across this operation. The behavior for CUP 999;999H is
  ; not defined, so I use CUD/CUF instead
  ;
  ; Report_Cursor_Position might report an error, but otherwise I don't check
  ; for errors.

  Procedure.i report_screen_dimensions(*p.tROWCOL)
    save_cursor
    _write_csi("999B") ; CUD cursor down this many
    _write_csi("999C") ; CUF cursor forward this many
    report_cursor_position(*p)
    restore_cursor
    ProcedureReturn #true
  EndProcedure

  ; ----- Standard error/info message output ------------------------------------
  ;
  ; Display the severity and text of a message at a row/col. Optionally the
  ; message could be written to a log (from common.pbi).

  Procedure.i display_message(sev.s, msg.s, *pos.tROWCOL, log.i=#false)
    save_cursor
    cursor_position(*pos\row, *pos\col)
    erase_line
    write_string(sev + ":" + msg)
    restore_cursor
    ; todo: handle log
    ProcedureReturn #true
  EndProcedure

  ; ----- Disable raw mode/restore prior saved terminal configuration -----------
  ;
  ; If the client wants to restore the terminal to its configuration before it
  ; was placed in raw mode, get_termios can be used to retrieve the current
  ; TERMIOS structure prior to set_raw_mode.

  Procedure.i get_termios(*p.tTERMIOS)
    If -1 = fTCGETATTR(0, *p)
      abexit("Enable_Raw_Mode failed tcgetattr", Str(fERRNO()))
    EndIf
    ProcedureReturn #true
  EndProcedure

  Procedure.i restore_mode(*p.tTERMIOS)
    If -1 = fTCSETATTR(0, #TCSAFLUSH, *p)
      abexit("Disable_Raw_Mode failed tcsetattr", Str(fERRNO()))
    Endif
    ProcedureReturn #true
  EndProcedure

  Procedure.i set_raw_mode(*raw.tTERMIOS)
    get_termios(*raw)
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

  ; ----- Buffered output -------------------------------------------------------
  ;
  ; This is mostly for screen repaints. As the buffer may need to grow the
  ; client will hold the current buffer pointer and any function that updates
  ; the buffer could return an updated pointer.

  ; To be provided: I think I want most everything to write to the buffer and
  ; require an explicit flush request. This would be a bit like building a BMS
  ; stream.

EndModule

; There is no need for module initialization--yet.

; vt100.pbi ends here ---------------------------------------------------------
