; vt100.pbi - a bunch of VT100 escape sequences from the Dec VT100 manual.

; work in progress

EnableExplicit

XIncludeFile "unistd.pbi"
XIncludeFile "common.pbi"

; Preserve ERRNO for error handling.

Global VT100_ERRNO.i

; ----- VT100 Command Sequences -----------------------------------------------
;
; These values are almost all from the Dec VT100 Manual, currently found at
; https://vt100.net/.
;
; The _tVT100_CMD_SEQUENCE is an array of ASCII bytes and a length. All of the
; commands are prefixed with $1B (ESC). A low level call to `write` is used to
; sent the command to the terminal.


; Load the command sequence values. I couldn't figure out a way to do this as
; a string literal (there's no escape for ESC) so these are built during
; program initialization.
;
; More proper naming would use the sequence introduction. These are:
;
; ESC - sequence starting with ESC (\x1B)
; CSI - Control Sequence Introducer: sequence starting with ESC [ or CSI (\x9B)
; DCS - Device Control String: sequence starting with ESC P or DCS (\x90)
; OSC - Operating System Command: sequence starting with ESC ] or OSC (\x9D)
;
; Everything I've needed so far is preceeded by CSI.


; Move cursor to row,col (ESC [ row; col H).
; Valid ANSI Mode Control Sequences 
;
;     CPR – Cursor Position Report – VT100 to Host 
;     CUB – Cursor Backward – Host to VT100 and VT100 to Host 
;     CUD – Cursor Down – Host to VT100 and VT100 to Host 
;     CUF – Cursor Forward – Host to VT100 and VT100 to Host 
;     CUP – Cursor Position 
;     CUU – Cursor Up – Host to VT100 and VT100 to Host 
;     DA – Device Attributes 
;     DECALN – Screen Alignment Display (DEC Private) 
;     DECANM – ANSI/VT52 Mode (DEC Private) 
;     DECARM – Auto Repeat Mode (DEC Private) 
;     DECAWM – Autowrap Mode (DEC Private) 
;     DECCKM – Cursor Keys Mode (DEC Private) 
;     DECCOLM – Column Mode (DEC Private) 
;     DECDHL – Double Height Line (DEC Private) 
;     DECDWL – Double-Width Line (DEC Private) 
;     DECID – Identify Terminal (DEC Private) 
;     DECINLM – Interlace Mode (DEC Private) 
;     DECKPAM – Keypad Application Mode (DEC Private) 
;     DECKPNM – Keypad Numeric Mode (DEC Private) 
;     DECLL – Load LEDS (DEC Private) 
;     DECOM – Origin Mode (DEC Private) 
;     DECRC – Restore Cursor (DEC Private) 
;     DECREPTPARM – Report Terminal Parameters 
;     DECREQTPARM – Request Terminal Parameters 
;     DECSC – Save Cursor (DEC Private) 
;     DECSCLM – Scrolling Mode (DEC Private) 
;     DECSCNM – Screen Mode (DEC Private) 
;     DECSTBM – Set Top and Bottom Margins (DEC Private) 
;     DECSWL – Single-width Line (DEC Private) 
;     DECTST – Invoke Confidence Test 
;     DSR – Device Status Report 
;     ED – Erase In Display 
;     EL – Erase In Line 
;     HTS – Horizontal Tabulation Set 
;     HVP – Horizontal and Vertical Position 
;     IND – Index 
;     LNM – Line Feed/New Line Mode 
;     NEL – Next Line 
;     RI – Reverse Index 
;     RIS – Reset To Initial State 
;     RM – Reset Mode 
;     SCS – Select Character Set 
;     SGR – Select Graphic Rendition 
;     SM – Set Mode 
;     TBC – Tabulation Clear 
; ------ Any initialization for this support library --------------------------

_VT100_INITIALIZE()

; vt100.pbi ends here ---------------------------------------------------------
