/***************************************************************************************************
* Program:    SNES Audio Processing Unit (APU) Emulator                                            *
* Platform:   Intel 80386                                                                          *
* Programmer: Anti Resonance (Alpha-II Productions), sunburst (degrade-factory)                    *
*                                                                                                  *
* "SNES" and "Super Nintendo Entertainment System" are trademarks of Nintendo Co., Limited and its *
* subsidiary companies.                                                                            *
*                                                                                                  *
* This program is free software; you can redistribute it and/or modify it under the terms of the   *
* GNU General Public License as published by the Free Software Foundation; either version 2 of     *
* the License, or (at your option) any later version.                                              *
*                                                                                                  *
* This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;        *
* without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.        *
* See the GNU General Public License for more details.                                             *
*                                                                                                  *
* You should have received a copy of the GNU General Public License along with this program;       *
* if not, write to the Free Software Foundation, Inc.                                              *
* 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.                                        *
*                                                                                                  *
*                                                 Copyright (C) 2003-2006 Alpha-II Productions     *
*                                                 Copyright (C) 2003-2016 degrade-factory          *
***************************************************************************************************/

#ifndef	__INC_APU
#define	__INC_APU

//**************************************************************************************************
// Defines

//The build options correspond to the equates at the top of APU.Inc

//SPC700 build options bits 7-0 ----------------
#define	SA_HALFC	0x02						//Half-carry enabled
#define	SA_CNTBK	0x04						//Counter Break
#define	SA_SPEED	0x08						//Speed hack
#define	SA_IPLW		0x10						//IPL ROM region writeable
#define	SA_DSPBK	0x20						//Break SPC700/Update DSP if 0F3h is read from

//DSP build options bits 15-8 ------------------
#define	SA_VMETERM	0x100						//Volume metering on main output (for APR)
#define	SA_VMETERC	0x200						//Volume metering on voices (for visualization)
#define	SA_SNESINT	0x400						//Use pregenerated gaussian curve from SNES
#define	SA_STEREO	0x800						//Stereo controls (seperation and EFBCT)

//APU build options bits 23-16 -----------------
#define	SA_DEBUG	0x10000						//Debugging ability
#define	SA_DSPINTEG	0x20000						//DSP emulation is integrated with the SPC700

// ----- degrade-factory code [2006/10/20] -----
#define	APURAMSIZE	0x10000						//APU RAM Memory Size
#define	SCR700SIZE	0x100000					//Script700 Program Area Size
#define	SCR700MASK	SCR700SIZE - 1				//Script700 Program Area Mask
// ----- degrade-factory code [END] -----

// ----- degrade-factory code [2015/11/23] -----
//SNESAPU callback effect
#define	CBE_DSPREG	0x01						//Write DSP value event
#define	CBE_S700FCH	0x02						//Write SPC700 fetch event
#define	CBE_INCS700	0x40000000					//Include Script700 text file
#define CBE_INCDATA	0x20000000					//Include Script700 binary file
// ----- degrade-factory code [END] -----

// ----- degrade-factory code [2016/05/09] -----
//**************************************************************************************************
// Pointer of SNESAPU callback function
//
// A prototype for a function that gets called for adding external methods.
//
// The role of parameters depends on the effect code.
// This callback function will be used in support of Script700, and SPC700/DSP debugging
// purposes.
//
// In:
//    effect = Effect code (see CBE_???)
//    addr   = Any address information
//    value  = Any value
//    pData -> Any pointer of values
//
// Out:
//    EAX = Usually, same value as 'value' argument

typedef u32 (__stdcall *CBFUNC)(u32 effect, u32 addr, u32 value, void *pData);
// ----- degrade-factory code [END] -----


////////////////////////////////////////////////////////////////////////////////////////////////////
// Private Declarations

#ifndef	SNESAPU_DLL

#ifdef	__cplusplus
extern	"C"	u32	apuOpt;							//Build options
// ----- degrade-factory code [2006/10/20] -----
extern	"C"	u8	scr700dsp[256];					//Script700 DSP Enable Flag (Channel)
extern	"C"	u8	scr700mds[32];					//Script700 DSP Enable Flag (Master)
extern	"C"	u8	scr700chg[256];					//Script700 DSP Note Change
extern	"C"	u32	scr700det[256];					//Script700 DSP Rate Detune
extern	"C"	u32	scr700vol[256];					//Script700 DSP Volume Change (Source)
extern	"C"	u32	scr700mvl[32];					//Script700 DSP Volume Change (Master)
extern	"C"	u32	scr700wrk[8];					//Script700 User Work Area
extern	"C"	u32	scr700cmp[2];					//Script700 Cmp Param
extern	"C"	u32	scr700cnt;						//Script700 Wait Count
extern	"C"	u32	scr700ptr;						//Script700 Program Pointer
extern	"C"	u32	scr700dat;						//Script700 Data Area Offset
extern	"C"	u32	pAPURAM;						//Pointer to SNESAPU 64KB RAM
extern	"C"	u32	pSCRRAM;						//Pointer to Script700 RAM
// ----- degrade-factory code [END] -----
#else
extern	u32	apuOpt;
// ----- degrade-factory code [2006/10/20] -----
extern	u8	scr700dsp[256];
extern	u8	scr700mds[32];
extern	u8	scr700chg[256];
extern	u32	scr700det[256];
extern	u32	scr700vol[256];
extern	u32	scr700mvl[32];
extern	u32	scr700wrk[8];
extern	u32	scr700cmp[2];
extern	u32	scr700cnt;
extern	u32	scr700ptr;
extern	u32	scr700dat;
extern	u32	pAPURAM;
extern	u32	pSCRRAM;
// ----- degrade-factory code [END] -----
#endif


////////////////////////////////////////////////////////////////////////////////////////////////////
// External Functions

#ifdef	__cplusplus
extern	"C" {
#endif

// ----- degrade-factory code [2013/10/12] -----
//**************************************************************************************************
// Initialize Audio Processing Unit
//
// This function is called by Windows operation system when called LoadLibrary/FreeLibrary
// API by frontend application.
//
// In:
//    reason = DLL call reason flag
//
// Out:
//    EAX = always TRUE

u32 InitAPU(u32 reason);


//**************************************************************************************************
// Get SNESAPU.DLL Version Information
//
// In:
//    pVer -> SNESAPU.DLL version (32bit)
//    pMin -> SNESAPU.DLL compatible version (32bit)
//    pOpt -> SNESAPU.DLL option flags

void SNESAPUInfo(u32 *pVer, u32 *pMin, u32 *pOpt);


//**************************************************************************************************
// Set SNESAPU.DLL Callback Function
//
// In:
//    pCbFunc -> Pointer of SNESAPU callback function
//               Callback function definition:
//                   u32 Callback(u32 effect, u32 addr, u32 value, void *lpData)
//               Usually, will return value of 'value' parameter.
//    cbMask   = SNESAPU callback mask

CBFUNC SNESAPUCallback(CBFUNC pCbFunc, u32 cbMask);


//**************************************************************************************************
// Get SNESAPU Data Pointers
//
// In:
//    ppRAM     -> 64KB Sound RAM
//    ppXRAM    -> 128byte extra RAM
//    ppOutPort -> APU 4 ports of output
//    ppT64Cnt  -> 64kHz timer counter
//    ppDSP     -> 128byte DSPRAM structure (see DSP.inc)
//    ppVoice   -> VoiceMix structures of 8 voices (see DSP.inc)
//    ppVMMaxL  -> Max master volume (left)
//    ppVMMaxR  -> Max master volume (right)

void GetAPUData(u8 **ppRAM, u8 **ppXRAM, u8 **ppOutPort, u32 **ppT64Cnt, DSPReg **ppDSP, Voice **ppVoice, u32 **ppVMMaxL, u32 **ppVMMaxR);


//**************************************************************************************************
// Get Script700 Data Pointers
//
// In:
//    pDLLVer     -> SNESAPU version (32byte string)
//    ppSPCReg    -> Pointer of SPC700 register
//    ppScript700 -> Pointer of Script700 work memory

void GetScript700Data(char *pDLLVer, u32 **ppSPCReg, u8 **ppScript700);
// ----- degrade-factory code [END] -----


//**************************************************************************************************
// Reset Audio Processor
//
// Clears all memory, sets registers to default values, and sets the amplification level.
//
// In:
//    amp = Amplification (-1 = keep current amp level, see SetDSPAmp for more information)

void ResetAPU(u32 amp);


//**************************************************************************************************
// Fix Audio Processor After Load
//
// Prepares the sound processor for emulation after an .SPC/.ZST is loaded.
//
// In:
//    SPC700 internal registers

void FixAPU(u16 pc, u8 a, u8 y, u8 x, u8 psw, u8 sp);


//**************************************************************************************************
// Load SPC File
//
// Restores the APU state from an SPC file.  This eliminates the need to call ResetAPU, copy memory,
// and call FixAPU.
//
// In:
//    pFile -> 66048 byte SPC file

void LoadSPCFile(void *pFile);


//**************************************************************************************************
// Set Audio Processor Options
//
// Configures the sound processor emulator.  Range checking is performed on all parameters.
//
// Notes:  -1 can be passed for any parameter you want to remain unchanged
//         see SetDSPOpt() in DSP.h for a more detailed explantion of the options
//
// In:
//    mixType = Mixing routine (default 1)
//    numChn  = Number of channels (1 or 2, default 2)
//    bits    = Sample size (8, 16, 24, 32, or -32 [IEEE 754], default 16)
//    rate    = Sample rate (8000-192000, default 32000)
//    inter   = Interpolation type (default INT_GAUSS)
//    opts    = See 'DSP options' in the Defines section of DSP.h

void SetAPUOpt(u32 mixType, u32 numChn, u32 bits, u32 rate, u32 inter, u32 opts);


//**************************************************************************************************
// Set Audio Processor Sample Clock
//
// Calculates the ratio of emulated clock cycles to sample output.  Used to speed up or slow down a
// song without affecting the pitch.
//
// In:
//    speed = Multiplier [16.16] (1/2x to 16x)

void SetAPUSmpClk(u32 speed);


//**************************************************************************************************
// Set Audio Processor Song Length
//
// Sets the length of the song and fade.
//
// Notes:  If a song is not playing, you must call ResetAPU or set T64Cnt to 0 before calling this.
//         To set a song with no length, pass -1 and 0 for the song and fade.
//
// In:
//    song = Length of song (in 1/64000ths second)
//    fade = Length of fade (in 1/64000ths second)
//
// Out:
//    Total length

u32 SetAPULength(u32 song, u32 fade);


//**************************************************************************************************
// Emulate Audio Processing Unit
//
// Emulates the APU for a specified amount of time.  DSP output is placed in a buffer to be handled
// by the main program.
//
// In:
//    pBuf-> Buffer to store output samples
//    len  = Length of time to emulate (must be > 0)
//    type = Type of parameter passed in len
//           0 - len is the number of APU clock cycles to emulate (APU_CLK = 1 second)
//           1 - len is the number of samples to generate
// Out:
//    -> End of buffer

void* EmuAPU(void *pBuf, u32 len, u8 type);


//**************************************************************************************************
// Seek to Position
//
// Seeks forward in the song from the current position.
//
// In:
//    time = 1/64000ths of a second to seek forward (must be >= 0)
//    fast = Use faster seeking method (may break some songs)

void SeekAPU(u32 time, b8 fast);


// ----- degrade-factory code [2013/10/12] -----
//**************************************************************************************************
// Set/Reset TimerTrick Compatible Function
//
// The setting of TimerTrick is converted into Script700, and it functions as Script700.
//
// In:
//    port = SPC700 port number (0 - 3 / 0xF4 - 0xF7).
//    wait = Wait time (1 - 0xFFFFFFFF).  If this parameter is 0, TimerTrick and Script700 is
//           disabled.

void SetTimerTrick(u32 port, u32 wait);


//**************************************************************************************************
// Set/Reset Script700 Compatible Function
//
// Script700 is a function to emulate the signal exchanged between 65C816 and SPC700 of SNES.
//
// In:
//    pSource -> Pointer to a null-terminated string buffer in which the Script700 command data was
//               stored.  If this parameter is NULL, Script700 is disabled.
//
// Out:
//    = Return value is a binary-converting result of the Script700 command.
//      >=1 : Last index of array of the program memory used.  Script700 is enabled.
//      0   : NULL was set in the pSource parameter.  Script700 is disabled.
//      -1  : Error occurred by binary-converting Script700.  Script700 is disabled.

u32 SetScript700(void *pSource);


//**************************************************************************************************
// Set Script700 Binary Data Function
//
// In:
//    addr   = Data area address of the destination to copy
//    pData -> Pointer to binary data buffer.  If this parameter is NULL, no operation.
//    size   = Size of buffer
//
// Out:
//    = Return value is a binary-converting result of the Script700 command.
//      >=1 : Last index of array of the program memory used.  Script700 is enabled.
//      0   : NULL was set in the pData parameter.  Script700 status will be not changed.
//      -1  : Error occurred by binary-converting Script700.  Script700 is disabled.

u32 SetScript700Data(u32 addr, void *pData, u32 size);
// ----- degrade-factory code [END] -----


// ----- degrade-factory code [2015/07/11] -----
//**************************************************************************************************
// Get SNESAPU Context Buffer Size Function
//
// SNESAPU Context is snapshot of global variables.
// This function returns buffer size required for snapshot.
//
// Out:
//    = Buffer size for copy of context data

u32 GetSNESAPUContextSize();


//**************************************************************************************************
// Get SNESAPU Context Data Function
//
// Copy the contents of SNESAPU Context for buffer.
// This means that to take a snapshot of SNESAPU.
//
// In:
//    pCtxOut -> Pointer of context buffer
//
// Out:
//    = Reserved

u32 GetSNESAPUContext(void *pCtxOut);


//**************************************************************************************************
// Set SNESAPU Context Data Function
//
// Copy the contents of SNESAPU Context from buffer.
// This means that to revert a snapshot of SNESAPU.
//
// In:
//    pCtxIn -> Pointer of context buffer
//
// Out:
//    = Reserved

u32 SetSNESAPUContext(void *pCtxIn);
// ----- degrade-factory code [END] -----

#ifdef	__cplusplus
}
#endif

#endif	//SNESAPU_DLL
#endif	//__INC_APU
