; bufwriter.pbi -- an output buffer for write() for vt100 support

; ----- Overview --------------------------------------------------------------
;
; There are times when deferred writes to a terminal make sense. This is an
; attempt at an small abstraction layer to add buffering without forcing
; significant changes in my vt100 module.
;
; It does very little in the way of error checking or handling. I know how to
; do those things, but this project doesn't warrant them. Procedures tend to
; return #true if they work (or should have worked), and #false if not.
;
; It is intended that this be both "IncludeFile"ed and "UseModule"ed by vt100.
; It is split out in case I want to reuse it elsewhere.

EnableExplicit

XIncludeFile "unistd.pbi"

DeclareModule bufwriter

  ; ----- Our control block -----------------------------------------------------
  ;
  ; I keep track of both the count of bytes used in the buffer and the location
  ; of the next available byte. It is redundant but I prefer way the code
  ; flows.

  #BCB_DEFAULT = 4096     ; buffer size
  Structure bcb
    size.i                ; bytes allocated
    used.i                ; bytes used
    *buf                  ; the buffer
    *nxt                  ; next available in buffer
    buffering.i           ; are we?
  EndStructure

  ; ----- API -------------------------------------------------------------------

  Declare.i buffer_initialize(bufsz.i=#BCB_DEFAULT) ; create the buffer
  Declare.i buffer_off(*bcb)                        ; turn buffering off
  Declare.i buffer_on(*bcb)                         ; turn buffering on
  Declare.i write_s(*bcb, s.s)                      ; write a string to the buffer
  Declare.i write_s_immediate(*bcb, s.s)            ; do it now
  Declare.i write_m(*bcb, *m, length.i)             ; write a byte array to the buffer
  Declare.i write_m_immediate(*bcb, *m, length.i)   ; do it now
  Declare.i buffer_flush(*bcb)                      ; write the buffer
  Declare.i buffer_clear(*bcb)                      ; clear the buffer
  Declare.i buffer_terminate(*bcb)                  ; flush and release the buffer

EndDeclareModule

Module bufwriter

  UseModule unistd

  ; ----- Utility copy a PureBasic string to a memory buffer --------------------
  ;
  ; The actual buffer is hung off the bcb. Returns *bcb or nil on error.

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

  ; ----- Acquire and initialize the buffer -------------------------------------
  ;
  ; The actual buffer is hung off the bcb. Returns *bcb or nil on error. As
  ; this is not threaded we could use a static global for the bcb but I prefer
  ; to allocate such things.

  Procedure.i buffer_initialize(bufsz.i=#BCB_DEFAULT)       ; create the buffer
    Define.bcb *bcb = AllocateMemory(sizeof(bcb))
    With *bcb
      \size = size
      \used = 0
      \buf = AllocateMemory(size)
      \nxt = \buf
      \buffering = #true
    EndWith
    ProcedureReturn *bcb
  EndProcedure

  ; ----- Turn buffering off ----------------------------------------------------
  ;
  ; Any writes will be immediate, even if they don't request it. Any existing
  ; data in the buffer is untouched.

  Procedure.i buffer_off(*bcb.bcb)                   ; turn buffering off
    *bcb\buffering = #false
    ProcedureReturn #true
  EndProcedure

  ; ----- Turn buffering on -----------------------------------------------------
  ;
  ; Defaults to write to buffer.

  Procedure.i buffer_on(*bcb.bcb)                    ; turn buffering on
    *bcb\buffering = #true
    ProcedureReturn #true
  EndProcedure

  ; ----- A possibly deferred string write --------------------------------------
  ;
  ; Write a string. If buffering is off, do a write immediate. If the buffer
  ; would overflow, this is an error and returns a #false. Otherwise return
  ; #true.

  Procedure.i write_s(*bcb.bcb, s.s)              ; write a string to the buffer
    If *bcb\buffering
      With *bcb
        If Len(s) + 1 + \used >= \size
          ProcedureReturn #false
        EndIf
        string_to_buffer(s, \nxt)
        \nxt = \nxt + Len(s)
        \used = \used + Len(s)
      EndWith
      ProcedureReturn #true
    Else
      ProcedureReturn write_s_immediate(*bcb, s)
    EndIf
  EndProcedure

  ; ----- An immediate string write ---------------------------------------------
  ;
  ; Write the string to stdout as a byte sequence. Always returns #true.

  Procedure.i write_s_immediate(*bcb.bcb, s.s)  ; write the string immediately
    Define *m = AllocateMemory(Len(s) + 8)      ; meh, I always pad
    string_to_buffer(s, *m)
    fWRITE(1, *m, Len(s) + 2)
    FreeMemory(*m)
    ProcedureReturn #true
  EndProcedure

  ; ----- A possibly deferred byte sequence write -------------------------------
  ;
  ; Write a sequence of bytes. If buffering is off, do a write immediate. If
  ; the buffer would overflow, this is an error and returns #false, otherwise
  ; #true.

  Procedure.i write_m(*bcb.bcb, *m, length.i)    ; write a byte array to the buffer
    if *bcb\buffering
      With *bcb
        If length + 1 + \used >= \size
          ProcedureReturn #false
        EndIf
        CopyMemory(\nxt, *m, length)
        \nxt = \nxt + length
        \used = \used + length
      EndWith
      ProcedureReturn #true
    Else
      ProcedureReturn write_m_immediate(*bcb, *m, length)
    EndIf
  EndProcedure

  ; ----- An immediate byte sequence write --------------------------------------
  ;
  ; Write the byte sequence to stdout. Always returns #true.

  Procedure.i write_m_immediate(*bcb.bcb, *m, length.i) ; write now
    fWRITE(1, *m, length)
    ProcedureReturn #true
  EndProcedure

  ; ----- Flush the buffer ------------------------------------------------------
  ;
  ; If the buffer holds data, write it and return #true, otherwise return
  ; #false.

  Procedure.i buffer_flush(*bcb.bcb)              ; write the buffer
    With *bcb
      If \buf = \nxt
        ProcedureReturn #false
      EndIf
      fWRITE(1, \buf, \used)
      \nxt = \buf
      \used = 0
    EndWith
    ProcedureReturn #true
  EndProcedure

  ; ----- Clear the buffer ------------------------------------------------------
  ;
  ; Discard everything in the buffer. Returns #false if the buffer was already
  ; empty.

  Procedure.i buffer_clear(*bcb.bcb)               ; write the buffer
    With *bcb
      If \buf = \nxt
        ProcedureReturn #false
      EndIf
      \nxt = \buf
      \used = 0
    EndWith
    ProcedureReturn #true
  EndProcedure

  ; ----- Done with the buffer --------------------------------------------------
  ;
  ; If there is any data in the buffer, flush it. Then release the buffer and
  ; bcb.

  Procedure.i buffer_terminate(*bcb.bcb)       ; flush and release the buffer
    With *bcb
      If \buf <> \nxt
        buffer_flush(*bcb)
      EndIf
      FreeMemory(\buf)
      FreeMemory(*bcb)
    EndWith
    ProcedureReturn #true
  EndProcedure

EndModule

; bufwriter.pbi ends here --------------------------------------------------------
