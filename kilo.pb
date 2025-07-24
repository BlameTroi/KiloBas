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
;
; I wouldn't advise anyone ot trust my code without having reviewed and tested
; it themselves. :)

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
;   defined as returning a value as well.

EnableExplicit

; ----- Using a module just because I prefer to -------------------------------
;
; This top level program doesn't strictly need to be in a module, but I like the
; consistency. The only thing in the declaration is the mainline.

DeclareModule kilo
  EnableExplicit

  Declare Mainline()
EndDeclareModule

; ----- Include system library interfaces -------------------------------------

XIncludeFile "syslib/errno.pbi"   ; The errors and how to decode them.
XIncludeFile "syslib/unistd.pbi"  ; The parts I need.
XIncludeFile "syslib/common.pbi"  ; Common macros, constants, and procedures.
XIncludeFile "syslib/vt100.pbi"   ; VT100/ANSI terminal control API - no UseModule.

; ----- The actual module definition ------------------------------------------

Module kilo
  UseModule errno
  UseModule unistd
  UseModule common

  ; ----- Common or global data -------------------------------------------------
  ;
  ; Originally these were just lone global variables but I've moved them into
  ; a structure the tutorial calls "editorconfig" (not THAT editorconfig) to be
  ; more in synch with its code.
  ;
  ; This is a purely cosmetic change that is probably more trouble than it's
  ; worth.

  Structure erow
    size.i
    *char                      ; is there a better way to deal with a C string?
  EndStructure

  Structure econfig
    ; screen geometry
    cursor_position.tROWCOL    ; current position
    screen_size.tROWCOL        ; dimensions of physical screen
    message_area.tROWCOL       ; start of message output area
    top_left.tROWCOL           ; bounds of the editable region
    bottom_right.tROWCOL       ; NW corner, SE corner
    ; display data
    row.erow                   ; initially just one row
  EndStructure

  Global.econfig E             ; to address

  ; ----- Common error exit -----------------------------------------------------
  ;
  ; ANSI key sequences are mapped into meaningful integer values.

  Enumeration Kilo_Keys 1000
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

  ; The Read_Key routine can return an error code if needed, but for now that is
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

  Procedure Abort(s.s, extra.s="", erase.i=#true, reset.i=#false, rc.i=-1)
    If erase
      vt100::erase_screen
      vt100::cursor_home
      vt100::terminate()
    ElseIf reset
      vt100::HARD_RESET
    EndIf
    vt100::cursor_show
    abexit(s, extra, rc)
  EndProcedure

  ; ----- UI move the cursor based on keyboard input ----------------------------
  ;
  ; The screen display is superficially vi like. The top and bottom two rows
  ; are reserved. As in vi, empty lines are flagged with a tilde (~).
  ;
  ; Keep the within the edit area's bounds.
  ;
  ; Any key sequence that can move the cursor is mapped to one of these four
  ; possibiities.
  ;
  ; I might try to switch to a format more like that of XEdit in CMS.

  Procedure.i Move_Cursor(c.i)
    With E\cursor_position
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
      \row = max(\row, E\top_left\row)
      \row = min(\row, E\bottom_right\row)
      \col = max(\col, E\top_left\col)
      \col = min(\col, E\bottom_right\col)
    EndWith
  EndProcedure

  ; ----- UI home the cursor ----------------------------------------------------
  ;
  ; The physical screen homes to 1,1 but in the editor home means top left of
  ; the editable area. That may be changed to command entry area a la XEdit,
  ; but I haven't decided yet.

  Procedure.i Editor_Cursor_Home()
    With E\top_left
      vt100::cursor_position(\row, \col)
    EndWith
  EndProcedure

  ; ----- UI display rows of text in the editable area --------------------------
  ;
  ; Refresh the editable area while preserving the user's cursor position.
  ; Empty rows will have the conventional Vi tilde (~) on the left margin. 

  Procedure.i Draw_Rows()
    vt100::save_cursor
    Editor_Cursor_Home()
    Define.i row
    For row = E\top_left\row To E\bottom_right\row
      vt100::cursor_position(row, E\top_left\col)
      vt100::erase_line
      ; TODO: should this clip to the region?
      vt100::write_string(~"~")
    Next row
    vt100::restore_cursor
  EndProcedure

  ; Procedure.i Draw_Frame() <- to be provided

  ; ----- UI refresh the entire display -----------------------------------------
  ;
  ; The screen consists of a frame holding information about the current edit
  ; session and state. Inside this there is the edit 'window' or view of the
  ; current file.

  Procedure.i Refresh_Screen()
    vt100::cursor_hide
    ; I don't think I need this here Editor_Cursor_Home()
    ; Draw_Frame() <- to be written
    Draw_Rows()
    vt100::cursor_position(E\cursor_position\row, E\cursor_position\col)
    vt100::cursor_show
  EndProcedure

  ; ----- Read a key press and return it one byte at a time ---------------------
  ;
  ; Translate bytes read from the terminal into a usable format. Normal
  ; characters are received as a single byte. Special purpose keys are received
  ; as a multi-byte sequence starting with an ESC.
  ;
  ; This is the main "event" that can be recieved by this program. Most of the
  ; time spent in this program will be in the repeat lt the head of this
  ; procedure.
  ;
  ; If a character is read and it is not ESC pass it on.
  ;
  ; If an ESC is read, it could be either a real ESC keyed by the user or the
  ; start of a sequence to read and decode.
  ;
  ; The terminal should provide the full sequence at once so subsequent reads
  ; will quickly get the rest of the sequence. If the sequence is recognized as
  ; having an end marker, read until that is received. Otherwise read until no
  ; key is returned. While it is possible that a user keypress follows the
  ; sequence with no time gap, the odds are astronomically small (really). The
  ; read timeout is set to 1/10 of a second by default.
  ;
  ; Once we have read the full sequence, translate it into a single numeric
  ; value. See the enumeration Kilo_Keys for the supported sequence
  ; translations. These are assigned a value well above the highest possible
  ; ASCII character code. Unicode/UTF-8 is not supported in multibyte formats.
  ;
  ; The full sequence read is stored in a global 32 byte buffer. This is
  ; displayed elsewhere for information and debugging.
  ;
  ; A note on the read/spin error handling: On macOS read doesn't mark no input
  ; as a hard error so check for nothing read and handle as if we got an error
  ; return flagged #EAGAIN.

  Global Dim Keypress_Buffer.a(32)

  Procedure.i Read_Key()
    Define.i n, err
    ; Spin until we get some sort of key. It might be a plain textual key or
    ; the start of an ANSI sequence.
    FillMemory(@Keypress_Buffer(0), 32)
    Repeat
      n = vt100::read_key(Keypress_Buffer(0))
      If n = -1
        err = fERRNO()
        If err <> #EAGAIN
          Abort("Editor_Read_Key", Str(err))
        Else
          n = 0
        EndIf
      EndIf
    Until n<>0
    ; If the key is not ESC, it can be returned straight away.
    If Keypress_Buffer(0) <> #ESCAPE
      ; There's the Delete key and FN Delete. FN Delete comes through as ESC 3 ~.
      If Keypress_Buffer(0) = #DELETE
        ProcedureReturn #DEL_KEY
      EndIf
      ProcedureReturn Keypress_Buffer(0)
    EndIf
    ; Collect the rest of the sequence. If the next read times out then the user
    ; actually pressed ESC. No error checking is done. If one occurs it will be
    ; processed as a time out. So, any error or timeout on the next two
    ; characters read will return a lone ESC to the caller.
    ;
    ; We need to read at least three bytes to identify a sequence, and more may
    ; be needed. Read the next two bytes and if there is an error/time out, just
    ; return an ESC.
    n = vt100::read_key(Keypress_Buffer(1))
    If n <> 1
      ProcedureReturn #ESCAPE
    EndIf
    n = vt100::read_key(Keypress_Buffer(2))
    If n <> 1
      ProcedureReturn #BAD_SEQUENCE_READ
    EndIf
    ; If first byte is ESC, further filter on second byte. So far sequences
    ; prefixed by ESC [ and ESC O are supported.
    If Keypress_Buffer(1) = '['
      ; Numererics are followed by a tilde (~) requiring a fourth byte to complete
      ; the sequence.
      If Keypress_Buffer(2) >= '0' and keypress_buffer(2) <= '9'
        n = vt100::read_key(Keypress_Buffer(3))
        If n <> 1 Or Keypress_Buffer(3) <> '~'
          ProcedureReturn #BAD_SEQUENCE_READ
        EndIf
        Select Keypress_Buffer(2)
          Case '1'
            ProcedureReturn #HOME_KEY       ; also 7
          Case '3'
            ProcedureReturn #DEL_KEY
          Case '4'
            ProcedureReturn #END_KEY        ; also 8
          Case '5'
            ProcedureReturn #PAGE_UP
          Case '6'
            ProcedureReturn #PAGE_DOWN
          Case '7'
            ProcedureReturn #HOME_KEY      ; also 1
          Case '8'
            ProcedureReturn #END_KEY       ; also 4
          Default
            ProcedureReturn #BAD_SEQUENCE_READ
        EndSelect
      Else
        Select Keypress_Buffer(2)
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
    ElseIf Keypress_Buffer(1) = 'O' ; upper case 'o'
      Select Keypress_Buffer(2)
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

  ; ----- Display the keypress buffer as built in Read_Key ----------------------
  ;
  ; The Keypress_Buffer is a 32 byte nil terminated ASCII byte array. `Read_Key`
  ; stores the current keypress there. Many keys result in only one byte stored,
  ; say for an alphabetic letter, but longer sequences are possible when using
  ; special keys such as up or down error.
  ;
  ; Build a human readable representation of the buffer and display it. This was
  ; initally for debugging but it may become a permanent feature.

  Procedure Display_Keypress_Buffer()
    vt100::save_cursor
    Define.s s = "key: "
    Define.i i
    While Keypress_Buffer(i)
      If Keypress_Buffer(i) = #ESCAPE
        s = s + "ESC "
      ElseIf Keypress_Buffer(i) = ' '
        s = s + "SPC "
      ElseIf Keypress_Buffer(i) < ' '
        s = s + "^" + Chr('A' + Keypress_Buffer(i) - 1) + " "
      ElseIf Keypress_Buffer(i) = #DELETE
        s = s + "DEL "
      Else
        s = s + Chr(Keypress_Buffer(i)) + " "
      EndIf
      i = i + 1
    Wend
    Define.tROWCOL p
    vt100::cursor_position(E\top_left\row - 1, E\top_left\col + 20)
    vt100::write_string(s + "              ")
    vt100::restore_cursor
  EndProcedure

  ; ----- Handle key press ------------------------------------------------------
  ;
  ; Route control based on mode and key. Try to keep any one Case clause
  ; short--use Procedures when appropriate.
  ;
  ; A "key" returned from Read_Key might represent a multi-byte ANSI sequence. If
  ; so, it is mapped to some value from the kilo_keys enumeration. That
  ; enumeration starts from 1000.
  ;
  ; This procedure returns #true when the user requests that the session end.

  Procedure.i Process_Key()
    Define.i c = Read_Key()
    Display_Keypress_Buffer()
    Select c
      Case #CTRL_D ; display screen size.
        Define.tROWCOL p
        vt100::report_screen_dimensions(@p)
        vt100::display_message("I", "Screen size: " + Str(p\row) + " x " + Str(p\col), @E\message_area)
      Case #CTRL_P ; display current cursor position
        Define.tROWCOL p
        vt100::report_cursor_position(@p)
        vt100::display_message("I", "Cursor position: " + Str(p\row) + " x " + Str(p\col), @E\message_area)
      Case #CTRL_Q ; quit program
        vt100::cursor_position(10, 1)
        ProcedureReturn #true
      Case #CTRL_A ; force an run through the Abort path
        vt100::save_cursor
        vt100::cursor_position(5, 8)
        vt100::write_string("Game Over Man!!!")
        vt100::restore_cursor
        Delay(2500)
        Abort("You forced an abort", "", #false, #true, -1)
      Case #ARROW_UP, #ARROW_RIGHT, #ARROW_DOWN, #ARROW_LEFT
        Display_Keypress_Buffer()
        Move_Cursor(c)
      Case #PAGE_UP
        Define.i i
        For i = E\top_left\row To E\bottom_right\row
          Move_Cursor(#ARROW_UP)
        Next i
      Case #PAGE_DOWN
        Define.i i
        For i = E\top_left\row To E\bottom_right\row
          Move_Cursor(#ARROW_DOWN)
        Next i
      Case #HOME_KEY
        E\cursor_position = E\top_left
      Case #END_KEY
        E\cursor_position = E\bottom_right
        E\cursor_position\col = E\top_left\col
      Default
        ; To be provided
    EndSelect
    ProcedureReturn #false
  EndProcedure

  ; ----- Kilo top level --------------------------------------------------------

  ; Put terminal in raw mode and set up buffering.

  Procedure Terminal_Initialization()
    vt100::initialize(4096, #true)
  EndProcedure

  ; Get the screen dimensions and define the corners of the various regions or
  ; areas.

  Procedure Analyze_Geometry()
    vt100::report_screen_dimensions(@E\screen_size)
    E\message_area = E\screen_size
    E\message_area\col = 1
    E\message_area\row = E\message_area\row - 1
    E\top_left\row = 3
    E\top_left\col = 1
    E\bottom_right = E\screen_size
    E\bottom_right\row = E\bottom_right\row - 3
  EndProcedure

  ; Either greet the user with an empty editor or load in a single file named
  ; on the command line.

  Procedure Greet_or_Load_File()
    vt100::erase_screen
    Editor_Cursor_Home()
    vt100::report_cursor_position(@E\cursor_position)
    vt100::display_message("I", "Welcome to kilo in PureBasic!", @E\message_area)
    ; vt100::flush()
  EndProcedure

  ; Loop until the user requests we quit.

  Procedure Editor_Loop()
    Repeat
      Refresh_Screen()
    Until Process_Key()
    ; vt100::immediate()
  EndProcedure

  ; If the buffer is dirty ask if it should be written out. Do so if yes.

  Procedure Write_if_Dirty()
    ; to be provided
  EndProcedure

  ; Restore the terminal to its original state and spin down buffering.

  Procedure Terminal_Termination()
    vt100::terminate()
  EndProcedure

  ; Just a top level mainline as a road map.

  Procedure Mainline()
    ; If we had logging, commom subsystem initialization
    Terminal_Initialization()
    Analyze_Geometry()
    Greet_or_Load_File()
    Editor_Loop()
    Write_if_Dirty()
    Terminal_Termination()
    ; If we had logging, commom subsystem termination
  EndProcedure

EndModule

kilo::Mainline()

End

; kilo.pb ends here -----------------------------------------------------------
