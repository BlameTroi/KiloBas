; unistd.pbi -- everything from the MacOS unistd.h without the level checks.

; work in progress

; What's in here:
;
; I've tried to port the basic file stream and file system functions (eg.,
; `chown`). There is some quesswork here. Obvious Darwin extensions have been
; dropped. There are a lot of process/thread/pipe controlling functions that
; really aren't appropriate for the sort of work I expect to do with PureBasic.
; If these functions are needed, write a separate module to access them.

EnableExplicit

; ----- Standard file decriptors ---------------------------------------------

#STDIN_FILENO  = 0; standard input file descriptor
#STDIN         = 0
#STDOUT_FILENO = 1; standard output file descriptor
#STDOUT        = 1
#STDERR_FILENO = 2; standard error file descriptor
#STDERR        = 2


; ----- Standard file decriptors ---------------------------------------------

; Type mapping:
;
; char * is a string, there are some decorations in the C headers for how many
; bytes are expected, typically based on a following parameter.
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

; As strings in PureBasic use two bytes per character, I'm allocating a byte
; buffer of ascii (.a) which is basically an unsigned very short integer. I picked
; 2048 as the size as this is the value of LINE_MAX in syslimits.h on my system.

#tT2KBUFFER = 2048
Structure tTCBUFFER
  c.a[#tT2KBUFFER]
endstructure

; ----- needed parts of fcntl.h -------------------------------------------------

; TODO: Pull in the needed parts from fcntl.h !!!!!!
; this may be better as a separate include.

; ----- System library prototype definitions ------------------------------------

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

; ------- Resolve function addresses ------------------------------------------

Procedure _UNISTD_INITIALIZE()
  If OpenLibrary(0, "libc.dylib")
    fREAD = GetFunction(0, "read")
    fWRITE = GetFunction(0, "write")
  Else
    PrintN("Error on open library libc!")
    End
  Endif
  If fREAD = 0 OR fWRITE = 0
    PrintN("Error retrieving one or more functions")
    PrintN("fREAD = " + hex(fREAD))
    PrintN("fWRITE = " + hex(fWRITE))
    End
  Endif
  CloseLibrary(0)
EndProcedure

; ------ Wrapper over write() to pass a unicode but holding only ascii string -

Procedure.i fWRITES(filedes.i, s.s, len.i)
  Static buf.tTCBUFFER

  If len(s) > #tT2KBUFFER
    PrintN("***fWRITES buffer overflow***")
    PrintN("***fWRITES buffer overflow***")
    PrintN("***fWRITES buffer overflow***")
    End -1
  EndIf

  If len(s) < 1
    ProcedureReturn 0
  EndIf

  Define i.i = 1
  Define j.i = 0

  While i <= len(s)
    buf\c[j] = Asc(Mid(s, i, 1))
    i = i + 1
    j = j + 1
  Wend

  ProcedureReturn fWrite(filedes, buf, i)
EndProcedure

_UNISTD_INITIALIZE()

; unistd.pbi ends here -------------------------------------------------------
