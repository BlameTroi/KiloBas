; logger.pbi -- a simple write to file logger

; ----- Overview --------------------------------------------------------------
;
; I need some basic trace capabilities. Multiple parallel logs are possible. A
; log is created with logger::initialize(). A handle to the log is returned as
; *lcb and is used on subsequent calls.

EnableExplicit

XIncludeFile "errno.pbi"
XIncludeFile "common.pbi"

DeclareModule logger

  EnableExplicit
  UseModule errno
  UseModule common

  ; ----- logger control block --------------------------------------------------
  ;
  ; *lcb is the handle for a log instance. The full structure is visible but
  ; should not be directly used by client code.

  Structure lcb
    lname.s                    ; give the file a name
    lnum.i                     ; file number from open
    lopen.i                    ; are we open?
    lactive.i                  ; are we active?
  EndStructure

  ; ----- API -------------------------------------------------------------------

  Declare.i initialize(logname.s="logger.log", active.i=#true)  ; create the logger file with state
  Declare.i prt(*lcb.lcb, sev.s, msg.s)     ; a simple message
  Declare.i off(*lcb.lcb)                   ; turn loggering off
  Declare.i on(*lcb.lcb)                    ; turn loggering on
  Declare.i terminate(*lcb.lcb)             ; flush and release the logger

EndDeclareModule

Module logger

  ; ----- Initialize the logger -----------------------------------------------

  Procedure.i initialize(logname.s = "logger.log", active.i=#true)
    Define.lcb *lcb
    *lcb = AllocateMemory(sizeof(lcb))
    If Not *lcb
      abexit("logger -- could not allocate lcb!", Str(fERRNO()))
    EndIf
    *lcb\lnum = CreateFile(#PB_Any, logname, #PB_File_NoBuffering)
    If *lcb\lnum < 0
      abexit("logger -- could not open file '" + logname + "'!", Str(fERRNO()))
    EndIf
    *lcb\lname = logname
    *lcb\lactive = #true
    prt(*lcb, "I", "********** New Log Session on '" + logname + "' *********")
    If Not *lcb\lactive
      off(*lcb)
    EndIf
    ProcedureReturn *lcb
  EndProcedure

  ; ----- Log something ------------------------------------------------------

  Procedure.i prt(*lcb.lcb, sev.s, msg.s)
    If *lcb\lactive
      Define.s dte = FormatDate("%yyyy/%mm/%dd", Date())
      Define.s tme = FormatDate("%hh:%ii:%ss", Date())
      WriteStringN(*lcb\lnum, sev + " " + dte + " " + tme + " " + msg)
    EndIf
    ProcedureReturn #true
  EndProcedure

  ; ----- Turn logging off ------------------------------------------------------

  Procedure.i off(*lcb.lcb)
    If *lcb\lactive
      prt(*lcb, "I", "********** Log Off **********")
      *lcb\lactive = #false
    EndIf
    ProcedureReturn #true
  EndProcedure

  ; ----- Turn loggering on -----------------------------------------------------

  Procedure.i on(*lcb.lcb)
    If Not *lcb\lactive
      prt(*lcb, "I", "*********** Log On ***********")
      *lcb\lactive = #true
    EndIf
    ProcedureReturn #true
  EndProcedure

  ; ----- Done with the logger --------------------------------------------------

  Procedure.i terminate(*lcb.lcb)
    If Not *lcb\lactive
      on(*lcb)
    EndIf
    prt(*lcb, "I", "********** Log End Session **********")
    CloseFile(*lcb\lnum)
    FreeMemory(*lcb)
    ProcedureReturn #true
  EndProcedure

EndModule

; logger.pbi ends here --------------------------------------------------------
