; common.pbi -- a collection of things I expect to be available

EnableExplicit

; work in progress

; ----- Overview --------------------------------------------------------------
;
; This is a "catch all" include file for common definitions and procedures.
; Some of these may be redundant with PureBasic built in procedures, but
; I haven't found any so far.
;
; * Structure names are usually tMEANINGFUL_NAME_UPPER_CASED
;
; * Procedure names tend to be lower cased.
;
; * Procedures that return to the caller are usually declared as returning an
;   integer even if they do not have a meaningful return value.
;
; * Return values are almost always #true or #false.
;
; There are no thread safety checks.

; ----- Include system library interfaces -------------------------------------

; XIncludeFile "errno.pbi"
; XIncludeFile "unistd.pbi"
; XIncludeFile "stdio.h"
; XIncludeFile "stdlib.h"

DeclareModule COMMON

  ; ----- Key press and response mapping ----------------------------------------
  ;
  ; I couldn't come up with a better way to generate the control character
  ; constants so enumeration it is. I'm adding the VT100/ANSI interpretation of
  ; these as keys for reference.

  Enumeration ASCII_CONTROL_CHARACTERS 1
    #CTRL_A
    #CTRL_B
    #CTRL_C
    #CTRL_D
    #CTRL_E
    #CTRL_F
    #CTRL_G               ; BEL Terminal bell       \b  7
    #CTRL_H               ; BS  Backspace            ?  8
    #CTRL_I               ; HT  Horizontal tab      \t  9
    #CTRL_J               ; LF  Linefeed (newline)  \n 10
    #CTRL_K               ; VT  Vertical tab        \v 11
    #CTRL_L               ; FF  Formfeed            \f 12
    #CTRL_M               ; CR  Carriage return     \r 13
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

  ; ----- Various coordinate structures -----------------------------------------
  ;
  ; VT100 and (N/PD)CURSES both use row,col (y,x) coordinates from the upper left
  ; cornder. Use this for display coordinates to avoid x,y <-> y,x muscle memory
  ; bugs.

  Structure tROWCOL
    row.i
    col.i
  EndStructure

  ; Two and three axis coordinates.
  Structure tXY
    x.i
    y.i
  EndStructure

  Structure tXYZ
    x.i
    y.i
    z.i
  EndStructure

  ; ----- API -------------------------------------------------------------------

  Declare   abexit(s.s, extra.s="", rc.i=-1)

  Declare.i oplog(fn.s="common.log")
  Declare.i cllog()
  Declare.i wtlog(sev.s, msg.s)

  Declare.i string_to_buffer(s.s, *buf)
  Declare.i buffer_to_string(*buf, s.s)

  Declare.i c_is_num(c.s)
  Declare.i c_is_alpha(c.s)
  Declare.i c_is_punctuation(c.s)
  Declare.i c_is_alphanum(c.s)
  Declare.i c_is_keyword(c.s)
  Declare.i c_is_whitespace(c.s)

  Declare.i a_is_num(c.a)
  Declare.i a_is_alpha(c.a)
  Declare.i a_is_punctuation(c.a)
  Declare.i a_is_alphanum(c.a)
  Declare.i a_is_keyword(c.a)
  Declare.i a_is_whitespace(c.a)

EndDeclareModule

Module COMMON
  ; ----- Abnormal program termination ------------------------------------------
  ;
  ; This really should write to stderr. And also the log if one is opened.

  Procedure abexit(s.s, extra.s="", rc.i=-1)
    PrintN("")
    PrintN("")
    PrintN(s.s)
    PrintN(extra)
    End rc
  Endprocedure

  ; ----- Logging ---------------------------------------------------------------
  ;
  ; Open, write to, and close procedures for a simple text log file.

  Procedure.i oplog(fn.s="common.log")
    ; not implemented yet
    ProcedureReturn #false
  EndProcedure

  Procedure.i cllog()
    ; not implemented yet
    ProcedureReturn #false
  EndProcedure

  Procedure.i wtlog(sev.s, msg.s)
    ; not implemented yet
    ProcedureReturn #false
  EndProcedure

  ; ----- Copy a native string into a C string and back -------------------------
  ;
  ; These are very trusting routines. They make no overflow checks. As the caller
  ; provides the buffer, length verification is its responsibility.
  ;
  ; They always return #true.

  Procedure.i string_to_buffer(s.s, *buf)
    Define *ptr = *buf
    Define.i i
    For i = 1 To Len(s)
      PokeA(*ptr, Asc(Mid(s, i, 1)))
      *ptr = *ptr + 1
    Next i
    PokeA(*ptr, 0) ; this is not strictly needed
    ProcedureReturn #true
  EndProcedure

  ; TODO: Any way to speed up the string build?
  Procedure.i buffer_to_string(*buf, s.s)
    Define *ptr = *buf
    Define.i i
    While *ptr
      s = s + Chr(PeekA(*ptr))
      *ptr = *ptr + 1
    Wend
    ProcedureReturn #true
  EndProcedure

  ; ----- Utility predicates ----------------------------------------------------
  ;
  ; Just a bunch of predicates. There are two versions of the various character
  ; classification predicates: a single character string or an ASCII byte value.

  Procedure.i c_is_num(c.s)
    If Len(c) = 1 And c >= "0" And c <= "9"
      ProcedureReturn #true
    Else
      ProcedureReturn #false
    EndIf
  EndProcedure

  Procedure.i c_is_alpha(c.s)
    If Len(c) <> 1
      ProcedureReturn #false
    EndIf
    If (c >= "a" And c <= "z") Or (c >= "A" And c <= "Z")
      ProcedureReturn #true
    EndIf
    ProcedureReturn #false
  EndProcedure

  Procedure.i c_is_punctuation(c.s)
    If Len(c) = 1 And FindString(".,?!;:", c) > 0
      ProcedureReturn #true
    EndIf
    ProcedureReturn #false
  EndProcedure

  Procedure.i c_is_alphanum(c.s)
    If c_is_alpha(c) Or c_is_num(c)
      ProcedureReturn #true
    EndIf
    ProcedureReturn #false
  EndProcedure

  Procedure.i c_is_keyword(c.s)
    If c_is_alpha(c) Or c_is_num(c) Or c = "_"
      ProcedureReturn #true
    EndIf
    ProcedureReturn #false
  EndProcedure

  Procedure.i c_is_whitespace(c.s)
    If Len(c) = 1 and c <= " "
      If c = " "
        ProcedureReturn #true
      ElseIf c = ~"\t"
        ProcedureReturn #true
      ElseIf c = ~"\n"
        ProcedureReturn #true
      ElseIf c = ~"\r"
        ProcedureReturn #true
      ElseIf c = ~"\f"
        ProcedureReturn #true
      ElseIf c = ~"\v"
        ProcedureReturn #true
      EndIf
    EndIf
    ProcedureReturn #false
  EndProcedure

  Procedure.i a_is_num(c.a)
    If c >= '0' And c <= '9'
      ProcedureReturn #true
    Else
      ProcedureReturn #false
    EndIf
  EndProcedure

  Procedure.i a_is_alpha(c.a)
    If (c >= 'a' And c <= 'z') Or (c >= 'A' And c <= 'Z')
      ProcedureReturn #true
    EndIf
    ProcedureReturn #false
  EndProcedure

  Procedure.i a_is_punctuation(c.a)
    If FindString(".,?!;:", Chr(c)) > 0
      ProcedureReturn #true
    EndIf
    ProcedureReturn #false
  EndProcedure

  Procedure.i a_is_alphanum(c.a)
    If a_is_alpha(c) Or a_is_num(c)
      ProcedureReturn #true
    EndIf
    ProcedureReturn #false
  EndProcedure

  Procedure.i a_is_keyword(c.a)
    If a_is_alpha(c) Or a_is_num(c) Or c = '_'
      ProcedureReturn #true
    EndIf
    ProcedureReturn #false
  EndProcedure

  Procedure.i a_is_whitespace(c.a)
    If c = ' ' Or (c >= 9 and c <=13) ; tab through carriage return
      ProcedureReturn #true
    EndIf
    ProcedureReturn #false
  EndProcedure

  ; ----- Doubtless there will be more ------------------------------------------
EndModule
; common.pbi ends here --------------------------------------------------------
