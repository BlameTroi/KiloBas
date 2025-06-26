// 
// PureBasic 6.21 - C Backend (MacOS X - arm64) generated code
// 
// (c) 2025 Fantaisie Software
// 
// The header must remain intact for Re-Assembly
// 
// Console
// String
// Memory
// Map
// Library
// Object
// SimpleList
// :System
// 
#pragma warning(disable: 4024)
// 
typedef long long quad;
typedef quad integer;
#define PB_INFINITY (1.0 / 0.0)
#define PB_NEG_INFINITY (-1.0 / 0.0)
typedef struct pb_array { void *a; } pb_array;
typedef struct pb_array2 { void *a; integer b[2]; } pb_array2;
typedef struct pb_array3 { void *a; integer b[3]; } pb_array3;
typedef struct pb_array4 { void *a; integer b[4]; } pb_array4;
typedef struct pb_array5 { void *a; integer b[5]; } pb_array5;
typedef struct pb_array6 { void *a; integer b[6]; } pb_array6;
typedef struct pb_array7 { void *a; integer b[7]; } pb_array7;
typedef struct pb_array8 { void *a; integer b[8]; } pb_array8;
typedef struct pb_array9 { void *a; integer b[9]; } pb_array9;
typedef struct pb_listitem { void *a; void *b; void *c;} pb_listitem;
typedef struct pb_list { void *a; pb_listitem *b; } pb_list;
typedef struct pb_mapitem { void *a; void *b; void *c;} pb_mapitem;
typedef struct pb_pbmap { pb_mapitem *a; } pb_pbmap;
typedef struct pb_map { pb_pbmap *a; } pb_map;
static integer s_s[]={0, -1};
#define M_SYSFUNCTION(a) a
#define M_PBFUNCTION(a) a
#define M_CDECL
typedef void TCHAR;
#include <math.h>
#define SYS_BankerRound(x) llrint(x)
#define SYS_BankerRoundQuad(x) llrint(x)
integer f_exit_(integer) asm("_exit");
// 
integer PB_Asc(void*);
void* PB_Chr(integer,integer);
integer PB_CloseLibrary(integer);
integer PB_FreeConsole();
integer PB_FreeLibraries();
integer PB_FreeMemorys();
integer PB_FreeObjects();
integer PB_GetFunction(integer,void*);
void* PB_Hex(quad,integer);
integer PB_InitConsole();
integer PB_InitLibrary();
integer PB_InitMap();
integer PB_InitMemory();
integer PB_OpenLibrary(integer,void*);
integer PB_Print(void*);
integer PB_PrintN(void*);
static char *tls;
int PB_ExitCode=0;
integer PB_MemoryBase=0;
integer PB_Instance=0;
int PB_ArgC;
char **PB_ArgV;
static unsigned char *pb_datapointer;
// 
// 
// 
// 
void SYS_Quit();
M_SYSFUNCTION(void) SYS_InitPureBasic();
void exit(int status);
M_PBFUNCTION(void) PB_InitCocoa();
M_SYSFUNCTION(void) SYS_CopyStructure(void *Destination, integer Length, integer *StructureMap, const void *Source);
M_SYSFUNCTION(void) SYS_CopyString(const void *String);
M_SYSFUNCTION(void) SYS_FastAllocateString4(TCHAR **Address, const TCHAR *String);
M_SYSFUNCTION(void) SYS_FreeString(TCHAR *String);
extern void *PB_StringBase;
extern integer PB_StringBasePosition;
M_SYSFUNCTION(void) SYS_InitString(void);
M_SYSFUNCTION(void) SYS_FreeStrings(void);
// 
M_SYSFUNCTION(void) SYS_PushStringBasePosition(void);
M_SYSFUNCTION(integer) SYS_PopStringBasePosition(void);
M_SYSFUNCTION(integer) SYS_PopStringBasePositionUpdate(void);
M_SYSFUNCTION(void *) SYS_PopStringBasePositionValue(void);
M_SYSFUNCTION(void *) SYS_PopStringBasePositionValueNoUpdate(void);
M_SYSFUNCTION(integer) SYS_GetStringBasePosition(void);
M_SYSFUNCTION(void) SYS_SetStringBasePosition(integer Position);
M_SYSFUNCTION(integer) SYS_StringBasePositionNoPop(void);
M_SYSFUNCTION(char *) SYS_GetStringBase(void);
volatile int PB_DEBUGGER_LineNumber=0;
volatile int PB_DEBUGGER_NbIncludedFiles=2;
const char PB_DEBUGGER_FileName[]="kilo.pb";
char *PB_DEBUGGER_IncludedFiles[]={
"errno.pbi",
"termios.pbi",
0};
typedef struct s_stermios s_stermios;
typedef struct s_pb_buffer s_pb_buffer;
// 
typedef integer (*pf_pperror)(void* v_s);
static integer f_ferrno();
static integer f_getlibcerrno();
typedef integer (*pf_ptcgetattr)(integer v_filedes,s_stermios* p_termios);
typedef integer (*pf_ptcsetattr)(integer v_filedes,integer v_optional_actions,s_stermios* p_termios);
typedef integer (*pf_piscntrl)(integer v_c);
typedef integer (*pf_pread)(integer v_filedes,s_pb_buffer* p_c,integer v_len);
static integer f_dumptermios(s_stermios* p_t,void* v_tag);
static integer f_getlibctermios();
static integer f_die(void* v_s);
static integer f_disablerawmode();
static integer f_enablerawmode();

#pragma pack(1)
typedef struct s_stermios {
integer f_c_iflag;
integer f_c_oflag;
integer f_c_cflag;
integer f_c_lflag;
unsigned char f_c_cc[20];
integer f_c_ispeed;
integer f_c_ospeed;
} s_stermios;
#pragma pack()

#pragma pack(1)
typedef struct s_pb_buffer {
unsigned char f_c[256];
} s_pb_buffer;
#pragma pack()
static unsigned short _S12[]={0};
static unsigned short _S7[]={32,32,99,95,111,102,108,97,103,32,61,32,0};
static unsigned short _S11[]={32,0};
static unsigned short _S26[]={113,0};
static unsigned short _S17[]={105,115,99,110,116,114,108,0};
static unsigned short _S1[]={108,105,98,99,46,100,121,108,105,98,0};
static unsigned short _S10[]={32,32,99,95,99,99,32,61,32,0};
static unsigned short _S13[]={32,32,99,95,105,115,112,101,101,100,32,61,32,0};
static unsigned short _S14[]={32,32,99,95,111,115,112,101,101,100,32,61,32,0};
static unsigned short _S3[]={69,114,114,111,114,32,111,110,32,111,112,101,110,32,108,105,98,114,97,114,121,32,108,105,98,99,33,32,102,111,114,32,112,101,114,114,111,114,0};
static unsigned short _S22[]={102,84,67,83,69,84,65,84,84,82,32,61,32,0};
static unsigned short _S15[]={116,99,103,101,116,97,116,116,114,0};
static unsigned short _S6[]={32,32,99,95,105,102,108,97,103,32,61,32,0};
static unsigned short _S5[]={84,69,82,77,73,79,83,58,32,0};
static unsigned short _S25[]={65,98,111,114,116,33,32,0};
static unsigned short _S21[]={102,84,67,71,69,84,65,84,84,82,32,61,32,0};
static unsigned short _S20[]={69,114,114,111,114,32,114,101,116,114,105,101,118,105,110,103,32,111,110,101,32,111,114,32,109,111,114,101,32,102,117,110,99,116,105,111,110,115,0};
static unsigned short _S24[]={102,82,69,65,68,32,61,32,0};
static unsigned short _S9[]={32,32,99,95,108,102,108,97,103,32,61,32,0};
static unsigned short _S23[]={102,73,83,67,78,84,82,76,32,61,32,0};
static unsigned short _S8[]={32,32,99,95,99,102,108,97,103,32,61,32,0};
static unsigned short _S18[]={114,101,97,100,0};
static unsigned short _S2[]={112,101,114,114,111,114,0};
static unsigned short _S16[]={116,99,115,101,116,97,116,116,114,0};
static unsigned short _S19[]={69,114,114,111,114,32,111,110,32,111,112,101,110,32,108,105,98,114,97,114,121,32,108,105,98,99,33,0};
static unsigned short _S4[]={69,114,114,111,114,32,114,101,116,114,105,101,118,105,110,103,32,102,117,110,99,116,105,111,110,32,112,101,114,114,111,114,32,102,114,111,109,32,108,105,98,99,0};

static integer ms_s[]={0,-1};
static s_stermios g_orig;
static pf_pperror g_fperror=0;
static s_stermios g_raw;
static unsigned char v_c=0;
static pf_ptcgetattr g_ftcgetattr=0;
static integer g_retval=0;
static s_pb_buffer v_buf;
static pf_piscntrl g_fiscntrl=0;
static pf_ptcsetattr g_ftcsetattr=0;
static pf_pread g_fread=0;
// 
// 
// Procedure EnableRawMode()
static integer f_enablerawmode() {
integer r=0;
PB_DEBUGGER_LineNumber=50;
// fTCGETATTR(0, orig)
PB_DEBUGGER_LineNumber=51;
integer p0=(integer)((integer)(&g_orig));
integer r0=g_ftcgetattr(0LL,p0);
// raw = orig
PB_DEBUGGER_LineNumber=52;
SYS_CopyStructure((void*)((integer)(&g_raw)),68,0,(void*)((integer)(&g_orig)));
// raw\c_iflag = raw\c_iflag & ~(#BRKINT | #ICRNL | #INPCK | #ISTRIP | #IXON)
PB_DEBUGGER_LineNumber=53;
g_raw.f_c_iflag=(g_raw.f_c_iflag&-819);
// raw\c_oflag = raw\c_oflag & ~(#OPOST)
PB_DEBUGGER_LineNumber=54;
g_raw.f_c_oflag=(g_raw.f_c_oflag&-2);
// raw\c_cflag = raw\c_cflag | (#CS8)
PB_DEBUGGER_LineNumber=55;
g_raw.f_c_cflag=(g_raw.f_c_cflag|768);
// raw\c_lflag = raw\c_lflag & ~(#ECHO | #ICANON | #IEXTEN | #ISIG)
PB_DEBUGGER_LineNumber=56;
g_raw.f_c_lflag=(g_raw.f_c_lflag&-1417);
// raw\c_cc[#VMIN] = 0       
PB_DEBUGGER_LineNumber=57;
g_raw.f_c_cc[16LL]=0;
// raw\c_cc[#VTIME] = 1      
PB_DEBUGGER_LineNumber=58;
g_raw.f_c_cc[17LL]=1;
// retval = fTCSETATTR(0, #TCSAFLUSH, raw)
PB_DEBUGGER_LineNumber=59;
integer p1=(integer)((integer)(&g_raw));
integer r1=g_ftcsetattr(0LL,2LL,p1);
g_retval=r1;
// retval = fTCGETATTR(0, raw)
PB_DEBUGGER_LineNumber=60;
integer p2=(integer)((integer)(&g_raw));
integer r2=g_ftcgetattr(0LL,p2);
g_retval=r2;
// EndProcedure
PB_DEBUGGER_LineNumber=61;
r=0;
end:
return r;
}
// Procedure GetLibcTermios()
static integer f_getlibctermios() {
integer r=0;
PB_DEBUGGER_LineNumber=2097494;
// If OpenLibrary(0, "libc.dylib")
PB_DEBUGGER_LineNumber=2097495;
integer r0=PB_OpenLibrary(0LL,_S1);
if (!(r0)) { goto no2; }
// fTCGETATTR.pTCGETATTR = GetFunction(0, "tcgetattr")
PB_DEBUGGER_LineNumber=2097496;
integer r1=PB_GetFunction(0LL,_S15);
g_ftcgetattr=r1;
// fTCSETATTR = GetFunction(0, "tcsetattr")
PB_DEBUGGER_LineNumber=2097497;
integer r2=PB_GetFunction(0LL,_S16);
g_ftcsetattr=r2;
// fISCNTRL = GetFunction(0, "iscntrl")
PB_DEBUGGER_LineNumber=2097498;
integer r3=PB_GetFunction(0LL,_S17);
g_fiscntrl=r3;
// fREAD = GetFunction(0, "read")
PB_DEBUGGER_LineNumber=2097499;
integer r4=PB_GetFunction(0LL,_S18);
g_fread=r4;
// Else
PB_DEBUGGER_LineNumber=2097500;
goto endif1;
no2:;
PB_DEBUGGER_LineNumber=2097500;
// PrintN("Error on open library libc!")
PB_DEBUGGER_LineNumber=2097501;
integer r5=PB_PrintN(_S19);
// End
PB_DEBUGGER_LineNumber=2097502;
SYS_Quit();
// Endif
endif1:;
PB_DEBUGGER_LineNumber=2097503;
// If fTCGETATTR = 0 OR fTCSETATTR = 0 OR fISCNTRL = 0 OR fREAD = 0 OR fPERROR = 0
PB_DEBUGGER_LineNumber=2097504;
integer c6=0;
if ((g_ftcgetattr==0LL)) { goto ok6; }
if ((g_ftcsetattr==0LL)) { goto ok6; }
goto no6;
ok6:
c6=1;
no6:;
integer c7=0;
if (c6) { goto ok7; }
if ((g_fiscntrl==0LL)) { goto ok7; }
goto no7;
ok7:
c7=1;
no7:;
integer c8=0;
if (c7) { goto ok8; }
if ((g_fread==0LL)) { goto ok8; }
goto no8;
ok8:
c8=1;
no8:;
integer c9=0;
if (c8) { goto ok9; }
if ((g_fperror==0LL)) { goto ok9; }
goto no9;
ok9:
c9=1;
no9:;
if (!(c9)) { goto no5; }
// PrintN("Error retrieving one or more functions")
PB_DEBUGGER_LineNumber=2097505;
integer r6=PB_PrintN(_S20);
// PrintN("fTCGETATTR = " + hex(fTCGETATTR))
PB_DEBUGGER_LineNumber=2097506;
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
SYS_CopyString(_S21);
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
quad p0=(quad)g_ftcgetattr;
PB_Hex(p0,SYS_PopStringBasePosition());
SYS_PopStringBasePosition();
void* p1=(void*)SYS_PopStringBasePositionValueNoUpdate();
integer r7=PB_PrintN(p1);
SYS_PopStringBasePositionUpdate();
// PrintN("fTCSETATTR = " + hex(fTCSETATTR))
PB_DEBUGGER_LineNumber=2097507;
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
SYS_CopyString(_S22);
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
quad p2=(quad)g_ftcsetattr;
PB_Hex(p2,SYS_PopStringBasePosition());
SYS_PopStringBasePosition();
void* p3=(void*)SYS_PopStringBasePositionValueNoUpdate();
integer r8=PB_PrintN(p3);
SYS_PopStringBasePositionUpdate();
// PrintN("fISCNTRL = " + hex(fISCNTRL))
PB_DEBUGGER_LineNumber=2097508;
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
SYS_CopyString(_S23);
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
quad p4=(quad)g_fiscntrl;
PB_Hex(p4,SYS_PopStringBasePosition());
SYS_PopStringBasePosition();
void* p5=(void*)SYS_PopStringBasePositionValueNoUpdate();
integer r9=PB_PrintN(p5);
SYS_PopStringBasePositionUpdate();
// PrintN("fREAD = " + hex(fREAD))
PB_DEBUGGER_LineNumber=2097509;
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
SYS_CopyString(_S24);
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
quad p6=(quad)g_fread;
PB_Hex(p6,SYS_PopStringBasePosition());
SYS_PopStringBasePosition();
void* p7=(void*)SYS_PopStringBasePositionValueNoUpdate();
integer r10=PB_PrintN(p7);
SYS_PopStringBasePositionUpdate();
// End
PB_DEBUGGER_LineNumber=2097510;
SYS_Quit();
// Endif
no5:;
PB_DEBUGGER_LineNumber=2097511;
// CloseLibrary(0)
PB_DEBUGGER_LineNumber=2097512;
integer r11=PB_CloseLibrary(0LL);
// EndProcedure
PB_DEBUGGER_LineNumber=2097513;
r=0;
end:
return r;
}
// Procedure GetLibcErrno()
static integer f_getlibcerrno() {
integer r=0;
PB_DEBUGGER_LineNumber=1048754;
// If OpenLibrary(0, "libc.dylib")  
PB_DEBUGGER_LineNumber=1048755;
integer r0=PB_OpenLibrary(0LL,_S1);
if (!(r0)) { goto no2; }
// fPERROR = GetFunction(0, "perror")
PB_DEBUGGER_LineNumber=1048756;
integer r1=PB_GetFunction(0LL,_S2);
g_fperror=r1;
// Else 
PB_DEBUGGER_LineNumber=1048757;
goto endif1;
no2:;
PB_DEBUGGER_LineNumber=1048757;
// PrintN("Error on open library libc! for perror") 
PB_DEBUGGER_LineNumber=1048758;
integer r2=PB_PrintN(_S3);
// End 
PB_DEBUGGER_LineNumber=1048759;
SYS_Quit();
// Endif 
endif1:;
PB_DEBUGGER_LineNumber=1048760;
// 
// If fPERROR = 0
PB_DEBUGGER_LineNumber=1048762;
if (!((g_fperror==0LL))) { goto no5; }
// PrintN("Error retrieving function perror from libc")
PB_DEBUGGER_LineNumber=1048763;
integer r3=PB_PrintN(_S4);
// End
PB_DEBUGGER_LineNumber=1048764;
SYS_Quit();
// Endif
no5:;
PB_DEBUGGER_LineNumber=1048765;
// 
// CloseLibrary(0)
PB_DEBUGGER_LineNumber=1048767;
integer r4=PB_CloseLibrary(0LL);
// EndProcedure
PB_DEBUGGER_LineNumber=1048768;
r=0;
end:
return r;
}
// Procedure DisableRawMode()
static integer f_disablerawmode() {
integer r=0;
PB_DEBUGGER_LineNumber=46;
// fTCSETATTR(0, #TCSAFLUSH, orig)
PB_DEBUGGER_LineNumber=47;
integer p0=(integer)((integer)(&g_orig));
integer r0=g_ftcsetattr(0LL,2LL,p0);
// EndProcedure
PB_DEBUGGER_LineNumber=48;
r=0;
end:
return r;
}
// 
char PB_OpenGLSubsystem=1;
int PB_Compiler_Unicode=1;
int PB_Compiler_Thread=0;
int PB_Compiler_Purifier=0;
int PB_Compiler_Debugger=0;
int PB_Compiler_DPIAware=0;
int PB_ExecutableType=1;
// 
void PB_EndFunctions() {
PB_FreeConsole();
PB_FreeLibraries();
PB_FreeObjects();
PB_FreeMemorys();
}
// 
int main(int argc, char* argv[]) {
PB_ArgC = argc;
PB_ArgV = argv;
SYS_InitPureBasic();
SYS_InitString();
PB_InitLibrary();
PB_InitMap();
PB_InitMemory();
PB_InitConsole();
// 
// 
// 
// 
// EnableExplicit
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// XIncludeFile "syslib/errno.pbi"
// 
// 
// 
// 
// EnableExplicit
// 
// 
// 
// 
// 
// 
// #EPERM           = 1               
// #ENOENT          = 2               
// #ESRCH           = 3               
// #EINTR           = 4               
// #EIO             = 5               
// #ENXIO           = 6               
// #E2BIG           = 7               
// #ENOEXEC         = 8               
// #EBADF           = 9               
// #ECHILD          = 10              
// #EDEADLK         = 11              
// 
// #ENOMEM          = 12              
// #EACCES          = 13              
// #EFAULT          = 14              
// #ENOTBLK         = 15              
// #EBUSY           = 16              
// #EEXIST          = 17              
// #EXDEV           = 18              
// #ENODEV          = 19              
// #ENOTDIR         = 20              
// #EISDIR          = 21              
// #EINVAL          = 22              
// #ENFILE          = 23              
// #EMFILE          = 24              
// #ENOTTY          = 25              
// #ETXTBSY         = 26              
// #EFBIG           = 27              
// #ENOSPC          = 28              
// #ESPIPE          = 29              
// #EROFS           = 30              
// #EMLINK          = 31              
// #EPIPE           = 32              
// 
// 
// #EDOM            = 33              
// #ERANGE          = 34              
// 
// 
// #EAGAIN          = 35              
// #EWOULDBLOCK     = #EAGAIN         
// #EINPROGRESS     = 36              
// #EALREADY        = 37              
// 
// 
// #ENOTSOCK        = 38              
// #EDESTADDRREQ    = 39              
// #EMSGSIZE        = 40              
// #EPROTOTYPE      = 41              
// #ENOPROTOOPT     = 42              
// #EPROTONOSUPPORT = 43           
// #ESOCKTNOSUPPORT = 44           
// #ENOTSUP         = 45              
// #EOPNOTSUPP      = #ENOTSUP        
// #EPFNOSUPPORT    = 46              
// #EAFNOSUPPORT    = 47              
// #EADDRINUSE      = 48              
// #EADDRNOTAVAIL   = 49             
// 
// 
// #ENETDOWN        = 50              
// #ENETUNREACH     = 51              
// #ENETRESET       = 52              
// #ECONNABORTED    = 53              
// #ECONNRESET      = 54              
// #ENOBUFS         = 55              
// #EISCONN         = 56              
// #ENOTCONN        = 57              
// #ESHUTDOWN       = 58              
// #ETOOMANYREFS    = 59              
// #ETIMEDOUT       = 60              
// #ECONNREFUSED    = 61              
// 
// 
// #ELOOP           = 62              
// #ENAMETOOLONG    = 63              
// 
// 
// #EHOSTDOWN       = 64              
// #EHOSTUNREACH    = 65              
// #ENOTEMPTY       = 66              
// 
// 
// #EPROCLIM        = 67              
// #EUSERS          = 68              
// #EDQUOT          = 69              
// 
// 
// #ESTALE          = 70              
// #EREMOTE         = 71              
// #EBADRPC         = 72              
// #ERPCMISMATCH    = 73              
// #EPROGUNAVAIL    = 74              
// #EPROGMISMATCH   = 75              
// #EPROCUNAVAIL    = 76              
// #ENOLCK          = 77              
// #ENOSYS          = 78              
// #EFTYPE          = 79              
// #EAUTH           = 80              
// #ENEEDAUTH       = 81              
// 
// 
// #EPWROFF         = 82              
// #EDEVERR         = 83              
// 
// #EOVERFLOW       = 84              
// 
// 
// #EBADEXEC        = 85              
// #EBADARCH        = 86              
// #ESHLIBVERS      = 87              
// #EBADMACHO       = 88              
// 
// #ECANCELED       = 89              
// 
// #EIDRM           = 90              
// #ENOMSG          = 91              
// #EILSEQ          = 92              
// #ENOATTR         = 93              
// 
// #EBADMSG         = 94              
// #EMULTIHOP       = 95              
// #ENODATA         = 96              
// #ENOLINK         = 97              
// #ENOSR           = 98              
// #ENOSTR          = 99              
// #EPROTO          = 100             
// #ETIME           = 101             
// 
// 
// 
// 
// #ENOPOLICY       = 103             
// 
// #ENOTRECOVERABLE = 104             
// #EOWNERDEAD      = 105             
// 
// #EQFULL          = 106             
// #ELAST           = 106             
// 
// 
// 
// Prototype.i pPERROR(s.s)
// Global fPERROR.pPERROR;
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// GetLibcErrno()
PB_DEBUGGER_LineNumber=1048770;
integer r0=f_getlibcerrno();
// 
// 
// 
// 
// XIncludeFile "syslib/termios.pbi"
// 
// 
// 
// 
// EnableExplicit
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// #VEOF =        0       
// #VEOL =        1       
// #VEOL2 =       2       
// #VERASE =      3       
// #VWERASE =     4       
// #VKILL =       5       
// #VREPRINT =    6       
// 
// #VINTR =       8       
// #VQUIT =       9       
// #VSUSP =       10      
// #VDSUSP =      11      
// #VSTART =      12      
// #VSTOP =       13      
// #VLNEXT =      14      
// #VDISCARD =    15      
// #VMIN =        16      
// #VTIME =       17      
// #VSTATUS =     18      
// 
// #NCCS =        20
// 
// 
// 
// 
// 
// 
// 
// 
// 
// #IGNBRK          = $0000001      
// #BRKINT          = $0000002      
// #IGNPAR          = $0000004      
// #PARMRK          = $0000008      
// #INPCK           = $0000010      
// #ISTRIP          = $0000020      
// #INLCR           = $0000040      
// #IGNCR           = $0000080      
// #ICRNL           = $0000100      
// #IXON            = $0000200      
// #IXOFF           = $0000400      
// #IXANY           = $0000800      
// #IMAXBEL         = $0002000      
// #IUTF8           = $0004000      
// 
// 
// 
// #OPOST           = $0000001      
// #ONLCR           = $0000002      
// #OXTABS          = $0000004      
// #ONOEOT          = $0000008      
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// #CIGNORE         = $0000001      
// #CSIZE           = $0000300      
// #CS5             = $0000000      
// #CS6             = $0000100      
// #CS7             = $0000200      
// #CS8             = $0000300      
// #CSTOPB          = $0000400      
// #CREAD           = $0000800      
// #PARENB          = $0001000      
// #PARODD          = $0002000      
// #HUPCL           = $0004000      
// #CLOCAL          = $0008000      
// #CCTS_OFLOW      = $0010000      
// #CRTS_IFLOW      = $0020000      
// #CDTR_IFLOW      = $0040000      
// #CDSR_OFLOW      = $0080000      
// #CCAR_OFLOW      = $0100000      
// #MDMBUF          = $0100000      
// 
// 
// 
// 
// 
// 
// 
// #ECHOKE          = $0000001      
// #ECHOE           = $0000002      
// #ECHOK           = $0000004      
// #ECHO            = $0000008      
// #ECHONL          = $0000010      
// #ECHOPRT         = $0000020      
// #ECHOCTL         = $0000040      
// #ISIG            = $0000080      
// #ICANON          = $0000100      
// #ALTWERASE       = $0000200      
// #IEXTEN          = $0000400      
// #EXTPROC         = $0000800      
// #TOSTOP          = $0400000      
// #FLUSHO          = $0800000      
// #NOKERNINFO      = $2000000      
// 
// #PENDIN          = $20000000     
// #NOFLSH          = $80000000     
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// Structure sTERMIOS
// c_iflag.i                      
// c_oflag.i                      
// c_cflag.i                      
// c_lflag.i                      
// c_cc.a[20]                     
// c_ispeed.i                     
// c_ospeed.i                     
// EndStructure
// 
// 
// 
// 
// #TCSANOW       = 0               
// #TCSADRAIN     = 1               
// #TCSAFLUSH     = 2               
// #TCSASOFT      = $10             
// 
// 
// 
// #B0 =      0
// #B50 =     50
// #B75 =     75
// #B110 =    110
// #B134 =    134
// #B150 =    150
// #B200 =    200
// #B300 =    300
// #B600 =    600
// #B1200 =   1200
// #B1800 =   1800
// #B2400 =   2400
// #B4800 =   4800
// #B9600 =   9600
// #B19200 =  19200
// #B38400 =  38400
// #B7200 =   7200
// #B14400 =  14400
// #B28800 =  28800
// #B57600 =  57600
// #B76800 =  76800
// #B115200 = 115200
// #B230400 = 230400
// #EXTA =    19200
// #EXTB =    38400
// 
// #TCIFLUSH      = 1
// #TCOFLUSH      = 2
// #TCIOFLUSH     = 3
// #TCOOFF        = 1
// #TCOON         = 2
// #TCIOFF        = 3
// #TCION         = 4
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// XIncludeFile "errno.pbi"
// 
// 
// 
// 
// Structure PB_BUFFER
// c.a[256]
// endstructure
// 
// 
// 
// 
// Prototype.i pTCGETATTR(filedes.i, *termios.sTERMIOS)
// Prototype.i pTCSETATTR(filedes.i, optional_actions.i, *termios.sTERMIOS)
// Prototype.i pISCNTRL(c.i)
// Prototype.i pREAD(filedes.i, *c.PB_BUFFER, len.i)
// 
// Global fTCGETATTR.pTCGETATTR;
// Global fTCSETATTR.pTCSETATTR;
// Global fISCNTRL.pISCNTRL;
// Global fREAD.pREAD;
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// GetLibcTermios()
PB_DEBUGGER_LineNumber=2097515;
integer r1=f_getlibctermios();
// 
// 
// 
// 
// 
// 
// 
// 
// 
// Global retval.i;
// Global orig.sTERMIOS;
// Global raw.sTERMIOS;
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// 
// EnableRawMode()
PB_DEBUGGER_LineNumber=75;
integer r2=f_enablerawmode();
// 
// define buf.PB_BUFFER
PB_DEBUGGER_LineNumber=77;;
// 
// Define c.a = 0
PB_DEBUGGER_LineNumber=79;
v_c=0;
// retval = fREAD(0, buf, 1)
PB_DEBUGGER_LineNumber=80;
integer p0=(integer)((integer)(&v_buf));
integer r3=g_fread(0LL,p0,1LL);
g_retval=r3;
// c = buf\c[0]
PB_DEBUGGER_LineNumber=81;
v_c=v_buf.f_c[0LL];
// repeat
do {
PB_DEBUGGER_LineNumber=82;
// if retval = 1
PB_DEBUGGER_LineNumber=83;
if (!((g_retval==1LL))) { goto no3; }
// if fISCNTRL(c) = 1
PB_DEBUGGER_LineNumber=84;
integer r4=g_fiscntrl(v_c);
if (!((r4==1))) { goto no5; }
// printn(hex(c))
PB_DEBUGGER_LineNumber=85;
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
PB_Hex(v_c,SYS_PopStringBasePosition());
void* p1=(void*)SYS_PopStringBasePositionValueNoUpdate();
integer r5=PB_PrintN(p1);
SYS_PopStringBasePositionUpdate();
// else
PB_DEBUGGER_LineNumber=86;
goto endif4;
no5:;
PB_DEBUGGER_LineNumber=86;
// printn(hex(c) + " " + chr(c))
PB_DEBUGGER_LineNumber=87;
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
PB_Hex(v_c,SYS_PopStringBasePosition());
SYS_CopyString(_S11);
SYS_PushStringBasePosition();
SYS_PushStringBasePosition();
PB_Chr(v_c,SYS_PopStringBasePosition());
SYS_PopStringBasePosition();
void* p2=(void*)SYS_PopStringBasePositionValueNoUpdate();
integer r6=PB_PrintN(p2);
SYS_PopStringBasePositionUpdate();
// endif
endif4:;
PB_DEBUGGER_LineNumber=88;
// endif
no3:;
PB_DEBUGGER_LineNumber=89;
// retval = fREAD(0, buf, 1)
PB_DEBUGGER_LineNumber=90;
integer p3=(integer)((integer)(&v_buf));
integer r7=g_fread(0LL,p3,1LL);
g_retval=r7;
// c = buf\c[0]
PB_DEBUGGER_LineNumber=91;
v_c=v_buf.f_c[0LL];
// until c = asc("q")
PB_DEBUGGER_LineNumber=92;
until1:;
integer r8=PB_Asc(_S26);
if ((v_c==r8)) { goto ok1; }
no1:;
} while (1);
ok1:;
il_until1:;
// 
// DisableRawMode()
PB_DEBUGGER_LineNumber=94;
integer r9=f_disablerawmode();
// 
// 
// 
// End
PB_DEBUGGER_LineNumber=98;
SYS_Quit();
// 
SYS_Quit();
}

void SYS_Quit() {
PB_EndFunctions();
exit(PB_ExitCode);
}
