; bufwriter.pbi -- an output buffer for write() for vt100 support

; ----- Overview --------------------------------------------------------------
;
; There are times when deferred writes to a terminal make sense. This is an
; attempt at an small abstraction layer to add buffering without forcing 
; significant changes in my vt100 module.
;
; It does very little in the way of error checking or handling. I know how to
; do those things, but this project doesn't warrant them.
;
; It is intended that this be both "IncludeFile"ed and "UseModule"ed.

EnableExplicit

DeclareModule bufwriter
  XIncludeFile "unistd.pbi"
  XIncludeFile "errno.pbi"
  XIncludeFile "common.pbi"

  UseModule unistd
  UseModule errno
  UseModule common

  ; ----- Our control block -----------------------------------------------------

  Structure bcb
    size.i                ; bytes allocated
    used.i                ; bytes used
    buffering.i           ; are we?
    *buf                  ; the buffer
    *nxt                  ; next available in buffer
  EndStructure

  ; ----- API -------------------------------------------------------------------

  Declare.i buffer_initialize(size.i=8192)               ; create the buffer
  Declare.i buffer_off(*bcb)                   ; turn buffering off
  Declare.i buffer_on(*bcb)                    ; turn buffering on
  Declare.i write_s(*bcb, s.s)                    ; write a string to the buffer
  Declare.i write_s_immediate(*bcb, s.s)          ; do it now
  Declare.i write_m(*bcb, *m, length.i)           ; write a byte array to the buffer
  Declare.i write_m_immediate(*bcb, *m, length.i) ; do it now
  Declare.i buffer_flush(*bcb)                           ; write the buffer
  Declare.i buffer_clear(*bcb)                           ; write the buffer
  Declare.i buffer_terminate(*bcb)                       ; flush and release the buffer

EndDeclareModule

Module bufwriter

  UseModule unistd
  UseModule errno
  UseModule common

  ; ----- Acquire and initialize the buffer -------------------------------------
  ;
  ; The actual buffer is hung off the bcb.

  Procedure.i buffer_initialize(size.i=8192)               ; create the buffer
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
  EndProcedure

  ; ----- Turn buffering on -----------------------------------------------------
  ;
  ; Defaults to write to buffer.

  Procedure.i buffer_on(*bcb.bcb)                    ; turn buffering on
    *bcb\buffering = #true
  EndProcedure

  ; ----- A possibly deferred string write --------------------------------------
  ;
  ; Write a string. If buffering is off, do a write immediate. If the buffer would
  ; overflow, this is an error and returns a -1.

  Procedure.i write_s(*bcb.bcb, s.s)                    ; write a string to the buffer
    If *bcb\buffering
      With *bcb
        If Len(s) + 1 + \used >= \size
          ProcedureReturn -1
        EndIf
        string_to_buffer(s, \nxt)
        \nxt = \nxt + Len(s)
        \used = \used + Len(s)
      EndWith
      ProcedureReturn Len(s)
    Else
      ProcedureReturn write_s_immediate(*bcb, s)
    EndIf
  EndProcedure

  ; ----- An immediate string write ---------------------------------------------
  ;
  ; Write the string to stdout as a byte sequence.

  Procedure.i write_s_immediate(*bcb.bcb, s.s)          ; do it now
    Define *m = AllocateMemory(Len(s) + 8) ; padding for prefix
    string_to_buffer(s, *m)
    Define.i sent = fWRITE(1, *m, Len(s) + 2)
    FreeMemory(*m)
    ProcedureReturn sent
  EndProcedure

  ; ----- A possibly deferred byte sequence write -------------------------------
  ;
  ; Write a sequence of bytes. If buffering is off, do a write immediate. If the
  ; buffer would overflow, this is an error and returns a -1.

  Procedure.i write_m(*bcb.bcb, *m, length.i)           ; write a byte array to the buffer
    if *bcb\buffering
      With *bcb
        If length + 1 + \used >= \size
          ProcedureReturn -1
        EndIf
        CopyMemory(\nxt, *m, length)
        \nxt = \nxt + length
        \used = \used + length
      EndWith
      ProcedureReturn length
    Else
      ProcedureReturn write_m_immediate(*bcb, *m, length)
    EndIf
  EndProcedure

  ; ----- An immediate byte sequence write --------------------------------------
  ;
  ; Write the byte sequence to stdout.

  Procedure.i write_m_immediate(*bcb.bcb, *m, length.i) ; do it now
    Define.i sent = fWRITE(1, *m, length)
    ProcedureReturn sent
  EndProcedure

  ; ----- Flush the buffer ------------------------------------------------------
  ;
  ; If the buffer holds data, write it and return the byte count written. Otherwise
  ; return #false.

  Procedure.i buffer_flush(*bcb.bcb)                           ; write the buffer
    If *bcb\buf = *bcb\nxt
      ProcedureReturn #false
    EndIf
    Define.i sent = fWRITE(1, *bcb\buf, *bcb\used)
    *bcb\nxt = *bcb\buf
    *bcb\used = 0
    ProcedureReturn sent
  EndProcedure

  ; ----- Clear the buffer ------------------------------------------------------
  ;
  ; Discard everything in the buffer. Returns #false if the buffer was already
  ; empty.

  Procedure.i buffer_clear(*bcb.bcb)                           ; write the buffer
    If *bcb\buf = *bcb\nxt
      ProcedureReturn #false
    EndIf
    *bcb\nxt = *bcb\buf
    *bcb\used = 0
    ProcedureReturn #true
  EndProcedure

  ; ----- Done with the buffer --------------------------------------------------
  ;
  ; If there is any data in the buffer, flush it. Then release the buffer and bcb.

  Procedure.i buffer_terminate(*bcb.bcb)                       ; flush and release the buffer
    If *bcb\buf <> *bcb\nxt
      buffer_flush(*bcb)
    EndIf
    FreeMemory(*bcb\buf)
    FreeMemory(*bcb)
    ProcedureReturn #true
  EndProcedure

EndModule

; There is no need for module initialization--yet.

; common.pbi ends here --------------------------------------------------------
