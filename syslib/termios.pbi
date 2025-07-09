; termios.pbi -- sys/termios.h for PureBasic.

; work in progress

EnableExplicit

XIncludeFile "unistd.pbi"
XIncludeFile "errno.pbi"

DeclareModule termios
  ; ----- Definitions from <sys/termios.h> --------------------------------------

  ; There are some preprocessor checks that appear to remove some of these. I am
  ; not trying to preserve them. They check for !_POSIX_C_SOURCE || _DARWIN_C_SOURCE.
  ; I'm creating this for my MacOS work and they seem to only remove definitions
  ; that aren't relevant. If I spot anything that needs tweaking I'll note it as
  ; it happens.
  ;
  ; Some coding notes:
  ;
  ; - Private entities are prefixed with "_".
  ; - Remember that hex notation for PureBasic is $xxxxxx.
  ; - I'm not trying to be portable. This is for 64 bit MacOS code. It will
  ;   probably run on Linux but I don't expect do so.
  ; - As this is 64 6it, an integer (.i) is the correct value. In C the fields
  ;   below such as c_?flags resolve their type to unsigned int. As I'm not doing
  ;   arithmetic the lack of an unsigned datatype should not be a problem.

  ; ----- Special Control Characters --------------------------------------------

  ; Special Control Characters, as indices into the c_cc[] array.
  ;
  ;Name	     Subscript	Enabled by

  #VEOF =        0       ; ICANON
  #VEOL =        1       ; ICANON
  #VEOL2 =       2       ; ICANON together with IEXTEN
  #VERASE =      3       ; ICANON
  #VWERASE =     4       ; ICANON together with IEXTEN
  #VKILL =       5       ; ICANON
  #VREPRINT =    6       ; ICANON together with IEXTEN
  ; =            7       ; spare 1
  #VINTR =       8       ; ISIG
  #VQUIT =       9       ; ISIG
  #VSUSP =       10      ; ISIG
  #VDSUSP =      11      ; ISIG together with IEXTEN
  #VSTART =      12      ; IXON, IXOFF
  #VSTOP =       13      ; IXON, IXOFF
  #VLNEXT =      14      ; IEXTEN
  #VDISCARD =    15      ; IEXTEN
  #VMIN =        16      ; !ICANON
  #VTIME =       17      ; !ICANON
  #VSTATUS =     18      ; ICANON together with IEXTEN
  ; =            19      ; spare 2
  #NCCS =        20

  ; #include <sys/_types/_posix_vdisable.h>
  ;
  ; #if !defined(_POSIX_C_SOURCE) || defined(_DARWIN_C_SOURCE)
  ; #CCEQ(val, c)    ((c) == (val) ? (val) != _POSIX_VDISABLE : 0)
  ; #endif

  ; ----- Input flags - software input processing -------------------------------

  #IGNBRK          = $0000001      ; ignore BREAK condition
  #BRKINT          = $0000002      ; map BREAK to SIGINTR
  #IGNPAR          = $0000004      ; ignore (discard) parity errors
  #PARMRK          = $0000008      ; mark parity and framing errors
  #INPCK           = $0000010      ; enable checking of parity errors
  #ISTRIP          = $0000020      ; strip 8th bit off chars
  #INLCR           = $0000040      ; map NL into CR
  #IGNCR           = $0000080      ; ignore CR
  #ICRNL           = $0000100      ; map CR to NL (ala CRMOD)
  #IXON            = $0000200      ; enable output flow control
  #IXOFF           = $0000400      ; enable input flow control
  #IXANY           = $0000800      ; any char will restart after stop
  #IMAXBEL         = $0002000      ; ring bell on input queue full
  #IUTF8           = $0004000      ; maintain state for UTF-8 VERASE

  ; ----- Output flags - software output processing -------------------------------

  #OPOST           = $0000001      ; enable following output processing
  #ONLCR           = $0000002      ; map NL to CR-NL (ala CRMOD)
  #OXTABS          = $0000004      ; expand tabs to spaces
  #ONOEOT          = $0000008      ; discard EOT's (^D) on output)

  ; ----- Unimplemented features --------------------------------------------------

  ; Here there was a block of code marked as "unimplemented features." I am not
  ; pulling those in. If they were used, the "programs will currently result in
  ; unexpected behaviour.

  ; ----- Control flags - hardware control of terminal ----------------------------

  #CIGNORE         = $0000001      ; ignore control flags
  #CSIZE           = $0000300      ; character size mask
  #CS5             = $0000000      ; 5 bits (pseudo)
  #CS6             = $0000100      ; 6 bits
  #CS7             = $0000200      ; 7 bits
  #CS8             = $0000300      ; 8 bits
  #CSTOPB          = $0000400      ; send 2 stop bits
  #CREAD           = $0000800      ; enable receiver
  #PARENB          = $0001000      ; parity enable
  #PARODD          = $0002000      ; odd parity, else even
  #HUPCL           = $0004000      ; hang up on last close
  #CLOCAL          = $0008000      ; ignore modem status lines
  #CCTS_OFLOW      = $0010000      ; CTS flow control of output
  #CRTS_IFLOW      = $0020000      ; RTS flow control of input
  #CDTR_IFLOW      = $0040000      ; DTR flow control of input
  #CDSR_OFLOW      = $0080000      ; DSR flow control of output
  #CCAR_OFLOW      = $0100000      ; DCD flow control of output
  #MDMBUF          = $0100000      ; old name for CCAR_OFLOW

  ; ----- "Local" flags - dumping groud for other state ---------------------------

  ;  * Warning: some flags in this structure begin with
  ;  * the letter "I" and look like they belong in the
  ;  * input flag.

  #ECHOKE          = $0000001      ; visual erase for line kill
  #ECHOE           = $0000002      ; visually erase chars
  #ECHOK           = $0000004      ; echo NL after line kill
  #ECHO            = $0000008      ; enable echoing
  #ECHONL          = $0000010      ; echo NL even if ECHO is off
  #ECHOPRT         = $0000020      ; visual erase mode for hardcopy
  #ECHOCTL         = $0000040      ; echo control chars as ^(Char)
  #ISIG            = $0000080      ; enable signals INTR, QUIT, [D]SUSP
  #ICANON          = $0000100      ; canonicalize input lines
  #ALTWERASE       = $0000200      ; use alternate WERASE algorithm
  #IEXTEN          = $0000400      ; enable DISCARD and LNEXT
  #EXTPROC         = $0000800      ; external processing
  #TOSTOP          = $0400000      ; stop background jobs from output
  #FLUSHO          = $0800000      ; output being flushed (state)
  #NOKERNINFO      = $2000000      ; no kernel output from VSTATUS
  ;                                ; yes, there's an extra hexmal place.on these
  #PENDIN          = $20000000     ; XXX retype pending input (state)
  #NOFLSH          = $80000000     ; don't flush after interrupt
  ; ----- Commands passed to tcsetattr() for setting the termios structure --------

  #TCSANOW       = 0               ; make change immediate
  #TCSADRAIN     = 1               ; drain output, then change
  #TCSAFLUSH     = 2               ; drain output, flush input
  #TCSASOFT      = $10             ; flag - don't alter h.w. state

  ; ----- Standard speeds (baud) --------------------------------------------------

  #B0 =      0
  #B50 =     50
  #B75 =     75
  #B110 =    110
  #B134 =    134
  #B150 =    150
  #B200 =    200
  #B300 =    300
  #B600 =    600
  #B1200 =   1200
  #B1800 =   1800
  #B2400 =   2400
  #B4800 =   4800
  #B9600 =   9600
  #B19200 =  19200
  #B38400 =  38400
  #B7200 =   7200
  #B14400 =  14400
  #B28800 =  28800
  #B57600 =  57600
  #B76800 =  76800
  #B115200 = 115200
  #B230400 = 230400
  #EXTA =    19200
  #EXTB =    38400

  #TCIFLUSH      = 1
  #TCOFLUSH      = 2
  #TCIOFLUSH     = 3
  #TCOOFF        = 1
  #TCOON         = 2
  #TCIOFF        = 3
  #TCION         = 4

  ; ----- System library function definitions -----------------------------------

  ; These are not exposed yet, I'm not sure they will ever be needed.
  ;
  ; speed_t cfgetispeed(const struct termios *);
  ; speed_t cfgetospeed(const struct termios *);
  ; int     cfsetispeed(struct termios *, speed_t);
  ; int     cfsetospeed(struct termios *, speed_t);
  ; int     tcgetattr(int, struct termios *);
  ; int     tcsetattr(int, int, const struct termios *);
  ; int     tcdrain(int) __DARWIN_ALIAS_C(tcdrain);
  ; int     tcflow(int, int);
  ; int     tcflush(int, int);
  ; int     tcsendbreak(int, int);
  ; void    cfmakeraw(struct termios *);
  ; int     cfsetspeed(struct termios *, speed_t);
  ; pid_t tcgetsid(int);


  ; ----- The termios structure ---------------------------------------------------

  ; the c typedef mappings:
  ;
  ; tcflag_t unsigned long -> .i (signed but we aren't doing arithmetic)
  ; cc_t unsigned char     -> .a
  ; speed_t unsigned long  -> .i as above
  ;
  ; The c definition ends after c_ospeed. I originally had some pad bytes after
  ; but the nature of the structure is such that they should not be needed.
  ; NOTE: for some reason I had c_i/ospeed as pointers to tTERMIOS. I am not
  ; sure why I did that.

  Structure tTERMIOS
    c_iflag.i                      ; input flags
    c_oflag.i                      ; output flags
    c_cflag.i                      ; control flags
    c_lflag.i                      ; local flags
    c_cc.a[20]                     ; control characters
    c_ispeed.i                     ; input speed
    c_ospeed.i                     ; output speed
  EndStructure

  Prototype.i _pTCGETATTR(filedes.i, *termios.tTERMIOS)
  Prototype.i _pTCSETATTR(filedes.i, optional_actions.i, *termios.tTERMIOS)
  Prototype.i _pISCNTRL(c.i)

  Global fTCGETATTR._pTCGETATTR
  Global fTCSETATTR._pTCSETATTR
  Global fISCNTRL._pISCNTRL

  Declare TERMIOS_dump(*t.tTERMIOS, tag.s="")
EndDeclareModule

Module termios

  ; ----- Utility functions -----------------------------------------------------

  ; Display TERMIOS for analysis. Note: Today I learned that structures are
  ; passed by reference.

  Procedure TERMIOS_dump(*t.tTERMIOS, tag.s="")
    PrintN("TERMIOS: " + tag)
    PrintN("  c_iflag = " + hex(*t\c_iflag))
    PrintN("  c_oflag = " + hex(*t\c_oflag))
    PrintN("  c_cflag = " + hex(*t\c_cflag))
    PrintN("  c_lflag = " + hex(*t\c_lflag))
    Print("  c_cc = ")
    Define i.i
    for i = 0 to 19
      Print(" " + hex(*t\c_cc[i]))
    next i
    PrintN("")
    PrintN("  c_ispeed = " + hex(*t\c_ispeed))
    PrintN("  c_ospeed = " + hex(*t\c_ospeed))
  EndProcedure

EndModule

; ------- Resolve function addresses ------------------------------------------

If OpenLibrary(0, "libc.dylib")
  termios::fTCGETATTR = GetFunction(0, "tcgetattr")
  termios::fTCSETATTR = GetFunction(0, "tcsetattr")
  termios::fISCNTRL = GetFunction(0, "iscntrl")
Else
  PrintN("Error on open library libc!")
  End
Endif
If termios::fTCGETATTR = 0 OR termios::fTCSETATTR = 0 OR termios::fISCNTRL = 0
  PrintN("Error retrieving one or more functions")
  PrintN("fTCGETATTR = " + hex(termios::fTCGETATTR))
  PrintN("fTCSETATTR = " + hex(termios::fTCSETATTR))
  PrintN("fISCNTRL = " + hex(termios::fISCNTRL))
  End
Endif
CloseLibrary(0)


; termios.pbi ends here ------------------------------------------------------
