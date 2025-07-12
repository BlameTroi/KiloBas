; vt100.pbi - a bunch of VT100 escape sequences from the Dec VT100 manual.

; ----- Overview --------------------------------------------------------------
;
; A wrapper for using VT100/ANSI terminal control sequences instead of the
; ubiquitus (N/PD)CURSES.
;
; All of the API procedures should be referenced using the module name prefix
; of `vt100::`. Any procedure name prefixed with an underscore (_) is meant to
; be internal use only. I have to expose them in the module declaration as the
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
XIncludeFile "bufwriter.pbi"    ; buffer to stdout for terminal writes

DeclareModule vt100

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
  ; There are four prefixes. I don't know why there are so many options, but it
  ; is what is is.
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
  ; Save or Restore the Cursor's position along with the graphic rendition
  ; (SGR) and character set (SGS).
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
  ; The terminal is returned to its "just powered on" state. On a hardware
  ; VT100 this would also fire POST.

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

  ; ----- Expose the API --------------------------------------------------------

  ; Set up and tear down.

  Declare.i initialize()            ; basic setup, mostly for buffering
  Declare.i terminate()             ; teardown

  ; TODO: These need to be wrapped in the module and should not be called
  ; directly.

  Declare.i get_termios(*p.tTERMIOS)
  Declare.i restore_mode(*p.tTERMIOS)
  Declare.i set_raw_mode(*raw.tTERMIOS)

  ; Input procedures:

  Macro read_key(c)
    fREAD(0, @c, 1)
  EndMacro

  ; Output procedures and buffering management:

  Declare.i immediate()             ; turn off buffering (default = on)
  Declare.i deferred()              ; turn on buffering
  Declare.i flush()                 ; flush anything in buffer to terminal
  Declare.i write_string(s.s)
  Declare.i display_message(sev.s, msg.s, *pos.tROWCOL, log.i=#false)

  ; Terminal queries. Report screen dimensions is a special case of report
  ; cursor position and does a bit of work before calling report cursor
  ; position.

  Declare.i report_cursor_position(*p.tROWCOL)
  Declare.i report_screen_dimensions(*p.tROWCOL)

  ; These should never be directly called by client code. They are only exposed
  ; for use by macros. All client writes to the terminal should use write_string!

  Declare.i _write_csi(s.s)
  Declare.i _write_esc(s.s)

EndDeclareModule

Module vt100

  UseModule unistd
  UseModule errno
  UseModule termios
  UseModule common
  UseModule bufwriter

  ; ----- Globals ---------------------------------------------------------------
  ;
  ; So far all I keep is the *bcb.

  Global *bcb.bcb

  ; ----- Command sequence prefix helpers. ------------------------------------
  ;
  ; Since embedding an escape input a literal string seems to require a string
  ; concatenation, I decided to provide helpers that put the proper prefix into
  ; a buffer followed by the terminal command.

  ; Apply the CSI prefix to a parameter and command string and send it to the
  ; terminal.

  Procedure.i _write_csi(s.s)
    ProcedureReturn write_s(*bcb, Chr($1b) + "[" + s)
  EndProcedure

  ; Apply the ESC prefix to a parameter and command string and send it to the
  ; terminal.

  Procedure.i _write_esc(s.s)
    ProcedureReturn write_s(*bcb, Chr($1b) + s)
  EndProcedure

  ; ----- Write a string to the terminal ----------------------------------------
  ;
  ; To avoid any Unicode/UTF-8 issues I build a sequence of ASCII bytes.
  ;
  ; Returns whatever write_s returns

  Procedure.i write_string(s.s)
    ProcedureReturn write_s(*bcb, s)
  EndProcedure

  ; ----- Terminal queries. ---------------------------------------------------
  ;
  ; So far the only query done is to find the cursor position. Getting the
  ; screen dimensions is a special case of finding the cursor position.
  ;
  ; At present these are the only two queries.

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
    ; todo: -- preserve and restore
    *p\row = -1
    *p\col = -1
    ; Define.i x = _write_csi("6n") 
    ; If x                      ; DSR for CPR cursor position report 6n -> r;cR 
    If Not _write_csi("6n")     ; DSR for CPR cursor position report 6n -> r;cR
      ProcedureReturn #false
    EndIf
    Define.a char
    Define.i i
    Define.s s
    ; Read a character at a time until we do not get a character (a time out
    ; on the wait) or the character received is the end marker for the CPR.
    While read_key(char)
      s = s + Chr(char)
      If char = 'R'
        Break
      EndIf
    Wend
    ; Does this appear to be a valid CPR? \e[#;#R? There is no error checking
    ; beyond this.
    If Len(s) < 6 Or Left(s, 1) <> Chr($1b) Or Right(s, 1) <> "R"
      ProcedureReturn #false
    EndIf
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
  EndProcedure

  ; Report screen size using CUD/CUF and then a CPR. The cursor position is
  ; saved and restored across this operation. The behavior for CUP 999;999H is
  ; not defined, so I use CUD/CUF instead
  ;
  ; Report_Cursor_Position might report an error, but otherwise I don't check
  ; for errors.
  ;
  ; Due to the nature of this command its output is in immediate mode.

  Procedure.i report_screen_dimensions(*p.tROWCOL)
    immediate()
    save_cursor
    _write_csi("999B") ; CUD cursor down this many
    _write_csi("999C") ; CUF cursor forward this many
    report_cursor_position(*p)
    restore_cursor
    deferred()
    ProcedureReturn #true
  EndProcedure

  ; ----- Standard error/info message output ------------------------------------
  ;
  ; Display the severity and text of a message at a row/col. Optionally the
  ; message could be written to a log (from common.pbi).
  ;
  ; Always returns #true.
  ;
  ; Always flushes any buffered output.

  Procedure.i display_message(sev.s, msg.s, *pos.tROWCOL, log.i=#false)
    save_cursor
    cursor_position(*pos\row, *pos\col)
    erase_line
    write_string(sev + ":" + msg)
    restore_cursor
    buffer_flush(*bcb)
    ; todo: handle logging
    ProcedureReturn #true
  EndProcedure

  ; ----- Disable raw mode/restore prior saved terminal configuration -----------
  ;
  ; If the client wants to restore the terminal to its configuration before it
  ; was placed in raw mode, get_termios can be used to retrieve the current
  ; TERMIOS structure prior to set_raw_mode.
  ;
  ; These are the only places where an error will end the program. If I can't
  ; get or set the termios, there's no point in doing anything else.

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

  ; cfmakeraw does the following, review differences.
  ;
  ; termios_p->c_iflag &= ~(IGNBRK | BRKINT | PARMRK | ISTRIP
  ;         not in kilo---v---^--v------------v--^
  ;                 | INLCR | IGNCR | ICRNL | IXON);
  ;         missing ISTRIP --^
  ; termios_p->c_oflag &= ~OPOST;
  ; termios_p->c_lflag &= ~(ECHO | ECHONL | ICANON | ISIG | IEXTEN);
  ;                                ^--------- not in kilo
  ; termios_p->c_cflag &= ~(CSIZE | PARENB); <-------- this is not in kilo
  ; termios_p->c_cflag |= CS8;

  Procedure.i set_raw_mode(*raw.tTERMIOS)
    get_termios(*raw)
    With *raw
      \c_iflag = \c_iflag & ~(#BRKINT | #ICRNL | #INPCK | #ISTRIP | #IXON)
      \c_oflag = \c_oflag & ~(#OPOST)
      \c_lflag = \c_lflag & ~(#ECHO | #ICANON | #IEXTEN | #ISIG)
      \c_cflag = \c_cflag | (#CS8)
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
  ; All screen writes run through a buffered writer. This requires separate
  ; initialization and termination code so I've added the appropriate
  ; procedures to the vt100 interface. These are pass through procedures to
  ; isolate the client program from the guts of bufwriter.
  ;
  ; There are already too many entry points exposed (procedures or macro
  ; wrappers) in vt100.
  ;
  ; Actual terminal writes (buffered or not) are issued directly above in the
  ; vt100 code. Reads are done via read() in unistd.

  Procedure.i initialize()
    *bcb = buffer_initialize()
    *bcb\buffering = #false
  EndProcedure

  Procedure.i immediate()
    ; ProcedureReturn buffer_off(*bcb)
  EndProcedure

  Procedure.i deferred()
    ; ProcedureReturn buffer_on(*bcb)
  EndProcedure

  Procedure.i flush()
    ProcedureReturn buffer_flush(*bcb)
  EndProcedure

  Procedure.i terminate()
    ProcedureReturn buffer_terminate(*bcb)
  EndProcedure

EndModule

; vt100.pbi ends here ---------------------------------------------------------
