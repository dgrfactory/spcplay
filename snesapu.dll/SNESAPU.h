/***************************************************************************************************
* Program:    Super Nintendo Entertainment System(tm) Audio Processing Unit Emulator               *
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
*                                                 Copyright (C) 2001-2004 Alpha-II Productions     *
*                                                 Copyright (C) 2003-2015 degrade-factory          *
***************************************************************************************************/

#ifndef __INC_SNESAPU
#define __INC_SNESAPU

#define SNESAPU_DLL                             //Don't include local function/variable definitions
#include    "Types.h"
#include    "SPC700.h"
#include    "APU.h"
#include    "DSP.h"

// ----- degrade-factory code [2015/07/11] -----
//**************************************************************************************************
// Function pointers to SNESAPU

typedef struct
{
    u8      *ram;                               //Base pointer to APU RAM
    u8      *xram;                              //Pointer to writeable IPL region
    u8      *outPort;                           //SPC700 output ports
    u32     *t64Cnt;                            //64kHz timer counter
    DSPReg  *dsp;                               //DSP registers
    Voice   *voice;                             //Internal DSP mixing data
    u32     *vMMaxL,*vMMaxR;                    //Max main sample output

    void*       (__stdcall *EmuAPU)(void *pBuf, u32 len, b8 type);
    void*       (__stdcall *EmuDSP)(void *pBuf, s32 size);
    s32         (__stdcall *EmuSPC)(u32 cyc);
    void        (__stdcall *FixAPU)(u16 pc, u8 a, u8 y, u8 x, u8 psw, u8 sp);
    void        (__stdcall *FixDSP)();
    void        (__stdcall *FixSPC)(u16 pc, u8 a, u8 y, u8 x, u8 psw, u8 sp);
    void        (__stdcall *FixSeek)(u8 reset);
    void        (__stdcall *GetAPUData)(u8 **ppAPURAM, u8 **ppExtraRAM, u8 **ppSPCOut, u32 **ppT64Cnt, DSPReg **ppDSP, Voice **ppMix, u32 **ppVMMaxL, u32 **ppVMMaxR);
    void        (__stdcall *GetScript700Data)(char *pVer, u32 **ppSPCReg, u8 **ppScript700);
    u32         (__stdcall *GetSNESAPUContext)(void *pCtxOut);
    u32         (__stdcall *GetSNESAPUContextSize)();
    void        (__stdcall *GetSPCRegs)(u16 *pPC, u8 *pA, u8 *pY, u8 *pX, u8 *pPSW, u8 *pSP);
    void        (__stdcall *InPort)(u32 port, u32 val);
    u32         (__stdcall *InitAPU)(u32 reason);
    void        (__stdcall *InitDSP)();
    void        (__stdcall *InitSPC)();
    void        (__stdcall *LoadSPCFile)(void *pSPC);
    void        (__stdcall *ResetAPU)(u32 amp);
    void        (__stdcall *ResetDSP)();
    void        (__stdcall *ResetSPC)();
    void        (__stdcall *SeekAPU)(u32 time, b8 fast);
    u32         (__stdcall *SetAPULength)(u32 song, u32 fade);
    void        (__stdcall *SetAPUOpt)(u32 mix, u32 chn, u32 bits, u32 rate, u32 inter, u32 opts);
    void        (__stdcall *SetAPURAM)(u32 addr, u8 val);
    void        (__stdcall *SetAPUSmpClk)(u32 speed);
    void        (__stdcall *SetDSPAmp)(u32 level);
    DSPDebug*   (__stdcall *SetDSPDbg)(DSPDebug *pTrace);
    void        (__stdcall *SetDSPEFBCT)(s32 leak);
    void        (__stdcall *SetDSPOpt)(u32 mix, u32 chn, u32 bits, u32 rate, u32 inter, u32 opts);
    void        (__stdcall *SetDSPPitch)(u32 base);
    b8          (__stdcall *SetDSPReg)(u8 reg, u8 val);
    void        (__stdcall *SetDSPStereo)(u32 sep);
    void        (__stdcall *SetDSPVol)(u32 vol);
    u32         (__stdcall *SetScript700)(void *pSource);
    u32         (__stdcall *SetScript700Data)(u32 addr, void *pData, u32 size);
    u32         (__stdcall *SetSNESAPUContext)(void *pCtxIn);
    SPCDebug*   (__stdcall *SetSPCDbg)(SPCDebug *pTrace, u32 opts);
    void        (__stdcall *SetTimerTrick)(u32 port, u32 wait);
    CBFUNC      (__stdcall *SNESAPUCallback)(CBFUNC pCbFunc, u32 cbMask);
    void        (__stdcall *SNESAPUInfo)(u32 *pVer, u32 *pMin, u32 *pOpt);
} SAPUFunc;


//**************************************************************************************************
// External Functions - See other header files for exported function descriptions

#define import  __declspec(dllimport)

#ifdef  __cplusplus
extern  "C" {
#endif

import  void*       __stdcall EmuAPU(void *pBuf, u32 len, b8 type);
import  void*       __stdcall EmuDSP(void *pBuf, s32 size);
import  s32         __stdcall EmuSPC(u32 cyc);
import  void        __stdcall FixAPU(u16 pc, u8 a, u8 y, u8 x, u8 psw, u8 sp);
import  void        __stdcall FixDSP();
import  void        __stdcall FixSPC(u16 pc, u8 a, u8 y, u8 x, u8 psw, u8 sp);
import  void        __stdcall FixSeek(u8 reset);
import  void        __stdcall GetAPUData(u8 **ppAPURAM, u8 **ppExtraRAM, u8 **ppSPCOut, u32 **ppT64Cnt, DSPReg **ppDSP, Voice **ppMix, u32 **ppVMMaxL, u32 **ppVMMaxR);
import  void        __stdcall GetScript700Data(char *pVer, u32 **ppSPCReg, u8 **ppScript700);
import  u32         __stdcall GetSNESAPUContext(void *pCtxOut);
import  u32         __stdcall GetSNESAPUContextSize();
import  void        __stdcall GetSPCRegs(u16 *pPC, u8 *pA, u8 *pY, u8 *pX, u8 *pPSW, u8 *pSP);
import  u32         __stdcall InitAPU(u32 reason);
import  void        __stdcall InitDSP();
import  void        __stdcall InitSPC();
import  void        __stdcall InPort(u32 port, u8 val);
import  void        __stdcall LoadSPCFile(void *pSPC);
import  void        __stdcall ResetAPU(u32 amp);
import  void        __stdcall ResetDSP();
import  void        __stdcall ResetSPC();
import  void        __stdcall SeekAPU(u32 time, b8 fast);
import  u32         __stdcall SetAPULength(u32 song, u32 fade);
import  void        __stdcall SetAPUOpt(u32 mix, u32 chn, u32 bits, u32 rate, u32 inter, u32 opts);
import  void        __stdcall SetAPURAM(u32 addr, u8 val);
import  void        __stdcall SetAPUSmpClk(u32 speed);
import  void        __stdcall SetDSPAmp(u32 level);
import  DSPDebug*   __stdcall SetDSPDbg(DSPDebug *pTrace);
import  void        __stdcall SetDSPEFBCT(s32 leak);
import  void        __stdcall SetDSPOpt(u32 mix, u32 chn, u32 bits, u32 rate, u32 inter, u32 opts);
import  void        __stdcall SetDSPPitch(u32 base);
import  b8          __stdcall SetDSPReg(u8 reg, u8 val);
import  void        __stdcall SetDSPStereo(u32 sep);
import  void        __stdcall SetDSPVol(u32 vol);
import  u32         __stdcall SetScript700(void *pSource);
import  u32         __stdcall SetScript700Data(u32 addr, void *pData, u32 size);
import  u32         __stdcall SetSNESAPUContext(void *pCtxIn);
import  SPCDebug*   __stdcall SetSPCDbg(SPCDebug *pTrace, u32 opts);
import  void        __stdcall SetTimerTrick(u32 port, u32 wait);
import  CBFUNC      __stdcall SNESAPUCallback(CBFUNC pCbFunc, u32 cbMask);
import  void        __stdcall SNESAPUInfo(u32 *pVer, u32 *pMin, u32 *pOpt);

#ifdef  __cplusplus
}
#endif
// ----- degrade-factory code [END] -----

#endif  //__INC_SNESAPU
