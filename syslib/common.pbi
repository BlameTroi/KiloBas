; common.pbi -- a collection of things I expect to be available

EnableExplicit

XIncludeFile "errno.pbi"
XIncludeFile "unistd.pbi"
; XIncludeFile "stdio.h"
; XIncludeFile "stdlib.h"

; ----- Key press and response mapping ----------------------------------------
;
; I couldn't come up with a better way to generate the control character
; constants so enumeration it is. I'm adding the VT100/ANSI interpretation of
; these as keys for reference.
;
; TODO: Move to a separate include file.

Enumeration ANSI_CONTROL_CHARACTERS 1
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

; ----- Various coordinate structures -----------------------------------------

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

; ----- Forward references ----------------------------------------------------

Declare   abexit(s.s, extra.s="", rc.i=-1)
Declare.i oplog(fn.s="wtlog.txt")
Declare.i cllog()
Declare.i wtlog(sev.s, msg.s)

Declare.i string_to_buffer(s.s, *buf)
Declare.i buffer_to_string(*buf, s.s)

Declare.i c_is_num(c.s)
Declare.i c_is_alpha(c.s)
Declare.i c_is_punctuation(c.s)
Declare.i c_is_keyword(c.s)
Declare.i c_is_whitespace(c.s)

Declare.i a_is_num(c.a)
Declare.i a_is_alpha(c.a)
Declare.i a_is_punctuation(c.a)
Declare.i a_is_keyword(c.a)
Declare.i a_is_whitespace(c.a)

Procedure abexit(s.s, extra.s="", rc.i=-1)
  PrintN("")
  PrintN("")
  PrintN(s.s)
  PrintN(extra)
  End rc
Endprocedure

Procedure.i oplog(fn.s="wtlog.txt")
  ; not implemented yet
EndProcedure

Procedure.i cllog()
  ; not implemented yet
EndProcedure

Procedure.i wtlog(sev.s, msg.s)
  ; not implemented yet
EndProcedure

; ----- Copy a native string into a C string and back -------------------------
;
; These are very trusting routines. They make no overflow checks. As the caller
; provides the buffer, length verification is its responsibility.
;
; Always returns #true.

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

Procedure.i buffer_to_string(*buf, s.s)
  Define *ptr = *buf
  Define.i i
  While *ptr
    s = s + Chr(PeekA(*ptr))
    *ptr = *ptr + 1
  Wend
  ProcedureReturn #true
EndProcedure

; ----- utility predicates ----------------------------------------------------

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
  If c >= "a" And c <= "z"
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
