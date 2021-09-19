;===================================================================================================
;Program:    SNES Audio Processing Unit (APU) Emulator
;Platform:   Intel 80386
;Programmer: Anti Resonance (Alpha-II Productions), sunburst (degrade-factory)
;
;"SNES" and "Super Nintendo Entertainment System" are trademarks of Nintendo Co., Limited and its
;subsidiary companies.
;
;This program is free software; you can redistribute it and/or modify it under the terms of the
;GNU General Public License as published by the Free Software Foundation; either version 2 of
;the License, or (at your option) any later version.
;
;This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
;without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
;See the GNU General Public License for more details.
;
;You should have received a copy of the GNU General Public License along with this program;
;if not, write to the Free Software Foundation, Inc.
;59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
;
;                                                   Copyright (C) 2003-2006 Alpha-II Productions
;                                                   Copyright (C) 2003-2021 degrade-factory
;===================================================================================================

%define APU_INC

;===================================================================================================
;Options

; ----- degrade-factory code [2019/07/15] -----
CPU_CYC     EQU 24                                              ;CPU clock divisor
                                                                ;10 = 2.457MHz
                                                                ;12 = 2.048MHz
                                                                ;24 = 1.024MHz

DEBUG       EQU 1                                               ;Enable debugging ability
DSPINTEG    EQU 1                                               ;Integrate DSP emulation with SPC700

HALFC       EQU 1                                               ;Enable half-carry flag emulation for decimal adjusts
SPEED       EQU 0                                               ;Enable speed hacks for counter reads and SLEEP
                                                                ;   Notes:  If speed hacks enabled, will stop Script700 when sleeping SPC700.
                                                                ;           If unused Script700, set the flag to "1" in order to run faster emulation.
IPLW        EQU 1                                               ;Enables the IPL Writable flag in register F1

CNTBK       EQU 0                                               ;Break SPC700/Update DSP if a counter increases
DSPBK       EQU 0                                               ;Break SPC700/Update DSP if register F3 is read
INTBK       EQU 1                                               ;Break SPC700/Update DSP if emulated 1Ts with SPC700
                                                                ;   Notes:  If all of CNTBK, DSPBK and INTBK are set to 0, sound will be not output.
                                                                ;           If you want the behavior closest to the SNES, set only INTBK to "1".

VMETERM     EQU 1                                               ;Monitor main output level (for APR)
VMETERV     EQU 1                                               ;Monitor levels of each voice (for visualization)

STEREO      EQU 1                                               ;Enable stereo controls (separation and EFBCT)

APURAMSIZE  EQU 10000h                                          ;APU RAM Memory Size
SCR700SIZE  EQU 100000h                                         ;Script700 Program Area Size
SCR700MASK  EQU SCR700SIZE - 1                                  ;Script700 Program Area Mask
; ----- degrade-factory code [END] -----

; ----- degrade-factory code [2015/11/23] -----
;SNESAPU callback effect
CBE_DSPREG  EQU 01h                                             ;Write DSP value event
CBE_S700FCH EQU 02h                                             ;Write SPC700 fetch event
CBE_INCS700 EQU 40000000h                                       ;Include Script700 text file
CBE_INCDATA EQU 20000000h                                       ;Include Script700 binary file
; ----- degrade-factory code [END] -----


;===================================================================================================
;Public Variables

PUBLIC  apuOpt                                                  ;Build options
; ----- degrade-factory code [2021/09/18] -----
PUBLIC  scr700lbl                                               ;Script700 Label pointer
PUBLIC  scr700stk                                               ;Script700 Stack area
PUBLIC  scr700dsp                                               ;Script700 DSP enable flags (Channel)
PUBLIC  scr700mds                                               ;Script700 DSP enable flags (Master)
PUBLIC  scr700chg                                               ;Script700 DSP note change
PUBLIC  scr700det                                               ;Script700 DSP rate detune
PUBLIC  scr700vol                                               ;Script700 DSP volume change (Source)
PUBLIC  scr700mvl                                               ;Script700 DSP volume change (Master)
PUBLIC  scr700wrk                                               ;Script700 User work area
PUBLIC  scr700cmp                                               ;Script700 Compare parameters
PUBLIC  scr700cnt                                               ;Script700 Wait Time Count
PUBLIC  scr700ptr                                               ;Script700 Program pointer
PUBLIC  scr700int                                               ;Script700 Interrupt ports
PUBLIC  scr700stf                                               ;Script700 Status flags
PUBLIC  scr700dat                                               ;Script700 Data area offset
PUBLIC  scr700stp                                               ;Script700 Stack pointer
PUBLIC  pAPURAM                                                 ;Pointer to SNESAPU 64KB RAM
PUBLIC  pSCRRAM                                                 ;Pointer to Script700 RAM
PUBLIC  apuCbMask                                               ;SNESAPU callback mask
PUBLIC  apuCbFunc                                               ;SNESAPU callback function
; ----- degrade-factory code [END] #34 -----


;===================================================================================================
;Exported Functions

; ----- degrade-factory code [2013/10/12] -----
;===================================================================================================
;Initialize Audio Processing Unit
;
;This function is called by Windows operation system when called LoadLibrary/FreeLibrary
;API by frontend application.
;
;In:
;   reason = DLL call reason type
;
;Out:
;   EAX = always TRUE

PUBLIC InitAPU, reason:dword


;===================================================================================================
;Get SNESAPU.DLL Version Information
;
;In:
;   pVer -> SNESAPU.DLL version (32bit)
;   pMin -> SNESAPU.DLL compatible version (32bit)
;   pOpt -> SNESAPU.DLL option flags

PUBLIC SNESAPUInfo, pVer:ptr, pMin:ptr, pOpt:ptr


;===================================================================================================
;Set/Reset SNESAPU Callback Function
;
;In:
;   pCbFunc -> SNESAPU callback function
;              function: u32 Callback(u32 effect, u32 addr, u32 value, void *lpData)
;              Usually, will return value of 'value' parameter.
;   cbMask   = SNESAPU callback mask
;
;Out:
;   EAX -> before SNESAPU callback function

PUBLIC SNESAPUCallback, pCbFunc:ptr, cbMask:dword


;===================================================================================================
;Get SNESAPU Data Pointers
;
;In:
;   ppRAM     -> 64KB Sound RAM
;   ppXRAM    -> 128byte extra RAM
;   ppOutPort -> APU 4 ports of output
;   ppT64Cnt  -> 64kHz timer counter
;   ppDSP     -> 128byte DSPRAM structure (see DSP.inc)
;   ppVoice   -> VoiceMix structures of 8 voices (see DSP.inc)
;   ppVMMaxL  -> Max master volume (left)
;   ppVMMaxR  -> Max master volume (right)

PUBLIC GetAPUData, ppRAM:ptr, ppXRAM:ptr, ppOutPort:ptr, ppT64Cnt:ptr, ppDSP:ptr, ppVoice:ptr, ppVMMaxL:ptr, ppVMMaxR:ptr


;===================================================================================================
;Get Script700 Data Pointers
;
;In:
;   pDLLVer     -> SNESAPU version (32byte string)
;   ppSPCReg    -> Pointer of SPC700 register
;   ppScript700 -> Pointer of Script700 work memory

PUBLIC GetScript700Data, pDLLVer:ptr, ppSPCReg:ptr, ppScript700:ptr
; ----- degrade-factory code [END] -----


;===================================================================================================
;Reset Audio Processor
;
;Clears all memory, sets registers to default values, and sets the amplification level.
;
;In:
;   amp = Amplification (-1 = keep current amp level, see SetDSPAmp for more information)

PUBLIC ResetAPU, amp:dword


;===================================================================================================
;Fix Audio Processor After Load
;
;Prepares the sound processor for emulation after an .SPC/.ZST is loaded.
;
;In:
;   SPC700 internal registers

PUBLIC FixAPU, pc:word, a:byte, y:byte, x:byte, psw:byte, s:byte


;===================================================================================================
;Load SPC File
;
;Restores the APU state from an SPC file.  This eliminates the need to call ResetAPU, copy memory,
;and call FixAPU.
;
;In:
;   pFile -> 66048 byte SPC file

PUBLIC LoadSPCFile, pFile:ptr


;===================================================================================================
;Set Audio Processor Options
;
;Configures the sound processor emulator.  Range checking is performed on all parameters.
;
;Notes:  -1 can be passed for any parameter you want to remain unchanged
;        see SetDSPOpt() in DSP.Inc for a more detailed description
;
;In:
;   mixType = Mixing routine (default 1)
;   numChn  = Number of channels (1 or 2, default 2)
;   bits    = Sample size (8, 16, 24, 32, or -32 [IEEE 754], default 16)
;   rate    = Sample rate (8000-192000, default 32000)
;   inter   = Interpolation type (default INT_GAUSS)
;   opts    = See 'DSP options' in the Defines section of DSP.Inc

PUBLIC SetAPUOpt, mixType:dword, numChn:dword, bits:dword, rate:dword, inter:dword, opts:dword


;===================================================================================================
;Set Audio Processor Sample Clock
;
;Calculates the ratio of emulated clock cycles to sample output.  Used to speed up or slow down a
;song without affecting the pitch.
;
;In:
;   speed = Multiplier [16.16] (1/2x to 16x)

PUBLIC SetAPUSmpClk, speed:dword


;===================================================================================================
;Set Audio Processor Song Length
;
;Sets the length of the song and fade.
;
;Notes:  If a song is not yet playing, you must call ResetAPU or set T64Cnt to 0 before calling this
;        To set a song with no length, pass -1 and 0 for the song and fade
;
;In:
;   song = Length of song (in 1/64000ths second)
;   fade = Length of fade (in 1/64000ths second)
;
;Out:
;   EAX = Total length

PUBLIC SetAPULength, song:dword, fade:dword


;===================================================================================================
;Emulate Audio Processing Unit
;
;Emulates the APU for a specified amount of time.  DSP output is placed in a buffer to be handled
;by the main program.
;
;In:
;   pBuf -> Buffer to store output samples
;   len   = Length of time to emulate (must be > 0)
;   type  = Type of parameter passed in len
;           0 - len is the number of APU clock cycles to emulate (APU_CLK = 1 second)
;           1 - len is the number of samples to generate
;Out:
;   EAX -> End of buffer

PUBLIC EmuAPU, pBuf:ptr, len:dword, type:byte


;===================================================================================================
;Seek to Position
;
;Seeks forward in the song.
;
;In:
;   time = 1/64000ths second to seek forward
;   fast = Use faster seeking method (may break some songs)

PUBLIC SeekAPU, time:dword, fast:bool


; ----- degrade-factory code [2013/10/12] -----
;===================================================================================================
;Set/Reset TimerTrick Compatible Function
;
;The setting of TimerTrick is converted into Script700, and it functions as Script700.
;
;In:
;   port = SPC700 port number (0 - 3 / 0F4h - 0F7h).
;   wait = Wait time (1 - 0FFFFFFFFh).  If this parameter is 0, TimerTrick and Script700 is
;          disabled.

PUBLIC SetTimerTrick, port:dword, wait:dword


;===================================================================================================
;Set/Reset Script700 Compatible Function
;
;Script700 is a function to emulate the signal exchanged between 65C816 and SPC700 of SNES.
;
;In:
;   pSource -> Pointer to a null-terminated string buffer in which the Script700 command data was
;              stored.  If this parameter is 0, Script700 is disabled.
;
;Out:
;   EAX = Return value is a binary-converting result of the Script700 command.
;         >=1 : Last index of array of the program memory used.  Script700 is enabled.
;         0   : NULL was set in the pSource parameter.  Script700 is disabled.
;         -1  : Error occurred by binary-converting Script700.  Script700 is disabled.

PUBLIC SetScript700, pSource:ptr


;===================================================================================================
;Set Script700 Binary Data Function
;
;In:
;   addr   = Data area address of the destination to copy
;   pData -> Pointer to binary data buffer.  If this parameter is NULL, no operation.
;   size   = Size of buffer
;
;Out:
;   EAX = Return value is a binary-converting result of the Script700 command.
;         >=1 : Last index of array of the program memory used.  Script700 is enabled.
;         0   : NULL was set in the pData parameter.  Script700 status will be not changed.
;         -1  : Error occurred by binary-converting Script700.  Script700 is disabled.

PUBLIC SetScript700Data, addr:dword, pData:ptr, size:dword
; ----- degrade-factory code [END] -----


; ----- degrade-factory code [2015/07/11] -----
;===================================================================================================
;Get SNESAPU Context Buffer Size Function
;
;SNESAPU Context is snapshot of global variables.
;This function returns buffer size required for snapshot.
;
;Out:
;   EAX = Buffer size for copy of context data

PUBLIC GetSNESAPUContextSize


;===================================================================================================
;Get SNESAPU Context Data Function
;
;Copy the contents of SNESAPU Context for buffer.
;This means that to take a snapshot of SNESAPU.
;
;In:
;   pCtxOut -> Pointer of context buffer
;
;Out:
;   EAX = Reserved

PUBLIC GetSNESAPUContext, pCtxOut:ptr


;===================================================================================================
;Set SNESAPU Context Data Function
;
;Copy the contents of SNESAPU Context from buffer.
;This means that to revert a snapshot of SNESAPU.
;
;In:
;   pCtxIn -> Pointer of context buffer
;
;Out:
;   EAX = Reserved

PUBLIC SetSNESAPUContext, pCtxIn:ptr
; ----- degrade-factory code [END] -----
