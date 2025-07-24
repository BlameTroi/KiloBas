; unistd.pbi -- most of the macOS unistd.h but without feature checks.

; ----- Overview --------------------------------------------------------------
;
; Those parts of <unistd.h> that I might need.
;
; I've tried to expose the basic file stream and file system functions (eg.,
; `chown`). There is some quesswork here. Obvious Darwin extensions have been
; dropped. There are a lot of process/thread/pipe controlling functions that
; really aren't appropriate for the sort of work I expect to do with PureBasic.
; If these functions are needed, write a separate module to access them.
;
; It is intended that this be both "IncludeFile"ed and "UseModule"ed.

EnableExplicit

DeclareModule unistd
  EnableExplicit

  ; ----- Standard file decriptors ---------------------------------------------

  #STDIN_FILENO  = 0              ; standard input file descriptor
  #STDIN         = 0              ; .. synonym
  #STDOUT_FILENO = 1              ; standard output file descriptor
  #STDOUT        = 1              ; .. synonym
  #STDERR_FILENO = 2              ; standard error file descriptor
  #STDERR        = 2              ; .. synonym

  ; ----- Type mapping C <-> PureBasic -----------------------------------------
  ;
  ; Type mapping:
  ;
  ; char * is a string, there are some decorations in the C headers for how
  ;        many bytes are expected, typically based on a following parameter.
  ;
  ; uid_t is a 32 bit unsigned integer.
  ;
  ; gid_t is as well.
  ;
  ; pid_t too.
  ;
  ; ints are 64 bit.
  ;
  ; size_t is an unsigned in, while ssize_t is signed int.
  ;
  ; Where an argument is flagged as const in the C header, I uppercase its
  ; placeholder variable name.
  ;
  ; I found the following on GitHub and it's a good use case for macros.
  ; I should probably redo these prototypes.
  ;
  ;{ from /usr/include/x86_64-linux-gnu/bits/types.h and /usr/include/x86_64-linux-gnu/bits/typesizes.h
  ;
  ; Macro dev_t : q : EndMacro 
  ; Macro ino_t : i : EndMacro 
  ; Macro mode_t : l : EndMacro 
  ; Macro nlink_t : q : EndMacro 
  ; Macro uid_t : l : EndMacro 
  ; Macro gid_t : l : EndMacro 
  ; Macro off_t : i : EndMacro 
  ; Macro blksize_t : i : EndMacro 
  ; Macro blkcnt_t : i : EndMacro 
  ; Macro time_t : i : EndMacro 
  ; Macro size_t : i : EndMacro 

  ; As strings in PureBasic use two bytes per character, I'm allocating a byte
  ; buffer of ascii (.a) which is basically an unsigned very short integer. I
  ; picked 2048 as the size as this is the value of LINE_MAX in syslimits.h on
  ; my system.

  #tT2KBUFFER = 2048
  Structure tTCBUFFER
    c.a[#tT2KBUFFER]
  endstructure

  ; ----- needed parts of fcntl.h -------------------------------------------------
  ;
  ; TODO: Pull in the needed parts from fcntl.h !!!!!!
  ; this may be better as a separate include.

  ; ----- System library prototype definitions ------------------------------------
  ;
  ; I've roughed in prototypes for all the functions I believe I might ever
  ; use. So far all I need is read() and write(). I've added a wrapper over
  ; write() to take a string, copy it to a byte buffer, and pass that buffer to
  ; write().
  :
  ; Prototype.i _pCHDIR(D.s)
  ; Prototype.i _pCHOWN(D.s, uid.i, gid.i)
  ; Prototype.i _pOPEN(PATH.s, oflag.i)
  ; Prototype.i _pCLOSE(filedes.i)
  ; Prototype.s pGETCWD(result_buf.s, size_of_buf.i)
  ; Prototype.s pGETLOGIN()
  ; Prototype.i _pGETPID()
  ; Prototype.i _pISATTY(filedes.i)
  ; Prototype.i _pRMDIR(D.s)
  ; Prototype.i _pSLEEP(secs.i)
  ; Prototype.s pTTYNAME(filedes.i)  ; *** legacy, prefer _r ***
  ; Prototype.i _pTTYNAME_R(filedes.i, namebuffer.s, len.i)
  ; Prototype.i _pFCHDIR(filedes.i)
  ; Prototype.i _pGETHOSTID()
  ; Prototype.i _pGETHOSTNAME(array_of_ascii_bytes.a, namelen.i)

  Prototype.i _pREAD(filedes.i, *c.tTCBUFFER, len.i)
  Prototype.i _pWRITE(filedes.i, *c.tTCBUFFER, len.i)

  Global fREAD._pREAD
  Global fWRITE._pWRITE
  Declare.i fWRITES(filedes.i, s.s)

EndDeclareModule

Module unistd

  ; ------ Wrapper over write() to pass a unicode but holding only ascii string -

  Procedure.i fWRITES(filedes.i, s.s)
    Static buf.tTCBUFFER

    If len(s) > #tT2KBUFFER
      ; TODO: support passing through the buffer.
      PrintN("***fWRITES buffer overflow***")
      PrintN("***fWRITES buffer overflow***")
      PrintN("***fWRITES buffer overflow***")
      End -1
    EndIf

    If len(s) < 1
      ProcedureReturn 0
    EndIf

    Define.i i = 1
    Define.i j = 0

    While i <= len(s)
      buf\c[j] = Asc(Mid(s, i, 1))
      i = i + 1
      j = j + 1
    Wend

    ProcedureReturn fWrite(filedes, buf, i)
  EndProcedure

EndModule

; ------- Expose read() and write() -------------------------------------------

If OpenLibrary(0, "libc.dylib")
  unistd::fREAD = GetFunction(0, "read")
  unistd::fWRITE = GetFunction(0, "write")
Else
  PrintN("Error on open library libc!")
  End
Endif
If unistd::fREAD = 0 OR unistd::fWRITE = 0
  PrintN("Error retrieving one or more functions")
  PrintN("fREAD = " + hex(unistd::fREAD))
  PrintN("fWRITE = " + hex(unistd::fWRITE))
  End
Endif

; unistd.pbi ends here -------------------------------------------------------
