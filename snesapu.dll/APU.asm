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
;                                                   Copyright (C) 2003-2026 degrade-factory
;
;List of users and dates who/when modified this file:
;   - degrade-factory in 2026-08-21
;===================================================================================================

%ifdef WIN64
    CPU     X64
    BITS    64
%else
    CPU     386
    BITS    32
%endif

;===================================================================================================
;Header files

%include "macro.inc"
%include "SPC700.inc"
%include "DSP.inc"
%define INTERNAL
%include "APU.inc"


;===================================================================================================
;Data

%ifndef WIN32
SECTION .data ALIGN=256
%else
SECTION .data ALIGN=32
%endif

    apuOpt      DD  (CPU_CYC << 24) | (DEBUG << 16) | (DSPINTEG << 17) | (VMETERM << 8) | (VMETERV << 9) | (1 << 10) | (STEREO << 11) \
                    | (HALFC << 1) | (CNTBK << 2) | (SPEED << 3) | (IPLW << 4) | (DSPBK << 5) | (INTBK << 6)
    apuDllVer   DD  20000h                                                      ;SNESAPU.DLL Current Version
    apuCmpVer   DD  11000h                                                      ;SNESAPU.DLL Backwards Compatible Version
    apuVerStr   DD  "$CAP_FILE_VER"                                             ;SNESAPU.DLL Current Version (32byte String)
                DD  8


;===================================================================================================
;Variables

%ifndef WIN32
SECTION .bss ALIGN=256
%else
SECTION .bss ALIGN=64
%endif

    apuRAMBuf   resw    APURAMSIZE                                              ;SNESAPU 64KB APU RAM buffer (double size)
                resd    2                                                       ;   Overflow reference area
                resd    6                                                       ;Extend function pointer address
    scrRAMBuf   resb    SCR700SIZE                                              ;Script700 RAM buffer
                resd    4                                                       ;   Overflow reference area

    scr700lbl   resd    1024                                                    ;Script700 Label work area
    scr700dsp   resb    256                                                     ;Script700 DSP enable flags (Source)
    scr700mds   resb    32                                                      ;Script700 DSP enable flags (Master)
    scr700det   resd    256                                                     ;Script700 DSP rate detune
    scr700chg   resb    256                                                     ;Script700 DSP note change
    scr700vol   resd    256                                                     ;Script700 DSP volume change (Source)
    scr700mvl   resd    32                                                      ;Script700 DSP volume change (Master)

    scr700wrk   resd    8                                                       ;Script700 User work area
    scr700cmp   resd    2                                                       ;Script700 Compare parameters
    scr700cnt   resd    1                                                       ;Script700 Waiting count
    scr700ptr   resd    1                                                       ;Script700 Program pointer
    scr700stf   resb    1                                                       ;Script700 Status flags
                                                                                ;   [0] - Enable writing return address in stack
                                                                                ;   [1] - Enable always writing ports
                                                                                ;   [2] - Waiting output port 0 without SHVC-SOUND
                                                                                ;   [3] - Waiting output port 0 with SHVC-SOUND
                                                                                ;   [5] - Call RunScript700 before fetch
                                                                                ;   [6] - SHVC-SOUND transfer mode
                                                                                ;   [7] - Force abort Script700 (from frontend)
                resb    1
    scr700int   resb    2                                                       ;Script700 Interrupt ports
    scr700dat   resd    1                                                       ;Script700 Data area offset
    scr700stp   resPTR  1                                                       ;Script700 Stack pointer

    scr700jmp   resPTR  1                                                       ;Script700 Jump address
    scr700stk   resd    128                                                     ;Script700 Stack area
    scr700pth   resd    256                                                     ;Script700 Include path
    scr700inc   resd    3                                                       ;Script700 Include depth
    scr700tmp   resPTR  1                                                       ;Script700 Temporary

    pAPURAM     resPTR  1                                                       ;Pointer to SNESAPU 64KB RAM
    pSCRRAM     resPTR  1                                                       ;Pointer to Script700 RAM
    cycLeft     resd    1                                                       ;Clock cycles left to emulate in EmuAPU loop
    smpDec      resd    1                                                       ;Unused clocks from cycle to sample conversion
    smpRate     resd    1                                                       ;Sample rate (max 32kHz in actual emulation mode)
    smpRAdj     resd    1                                                       ;Sample rate adjustment (16.16)
    smpREmu     resd    1                                                       ;Number of emulated samples per second

    rawChn      resb    1                                                       ;Number of channels being output
    rawBits     resb    1                                                       ;Size of samples in bits
    rawByte     resb    1                                                       ;Size of samples in bytes
                resb    1
    rawRate     resd    1                                                       ;Sample rate (max 192kHz)
    dspOpts     resd    1                                                       ;DSP option

    outCur      resd    1                                                       ;Temporary buffer cursor
    outLen      resd    1                                                       ;Temporary buffer used length
    outBuf      resq    192                                                     ;Temporary buffer (max 192 samples * 2ch * 32bit)

    apuCbMask   resd    1                                                       ;SNESAPU callback mask
    apuCbFunc   resPTR  1                                                       ;SNESAPU callback function

    apuVarEP    resd    1                                                       ;Endpoint of APU.asm variable


;===================================================================================================
;Code

%ifndef WIN32
SECTION .text ALIGN=256
%else
SECTION .text ALIGN=16
%endif


;===================================================================================================
;Initialize Audio Processing Unit

;NOTE (amd64 port): not in SNESAPU.def, but still called directly from Pascal via 'external name
; "InitAPU"' linkage (see snesapu_amd64.dpr) -- that is a real Windows x64 ABI call crossing the DLL
; boundary just as much as a DEF-exported function is, so this needs EXPROC too (a plain internal
; PROC never homes its incoming RCX, so [reason] would read stack garbage instead of the real
; argument -- this was found via reason ending up non-1, silently skipping InitAPU's whole body,
; which left pAPURAM at its zeroed .bss default and crashed ResetSPC's 'Rep StoSD' on a NULL PDI).

EXPROC InitAPU, reason

    Mov     EAX,[reason]
    Dec     EAX                                                                 ;reason = DLL_PROCESS_ATTACH (1)?
    JNZ     .Quit                                                               ;   No

    LoadPtr PAX,apuRAMBuf
    Add     PAX,0FFFFh
    XOr     AX,AX                                                               ;Round down to a 64KB boundary
    Mov     [pAPURAM],PAX

    Add     PAX,10000h
    Mov     PDI,PAX
    XOr     EAX,EAX
    Mov     ECX,12
    Rep     StoSD

    Mov     [scr700inc],EAX
    Mov     [apuCbMask],EAX
    Mov     [apuCbFunc],PAX
    Mov     [dspOpts],EAX

    LoadPtr PAX,scrRAMBuf
    Mov     [pSCRRAM],PAX

    Call    InitSPC
    Call    InitDSP

    Mov     dword [smpRate],32000
    Mov     dword [smpRAdj],10000h
    Mov     byte [rawChn],2
    Mov     byte [rawBits],16
    Mov     byte [rawByte],4
    Mov     dword [rawRate],32000

    Call    SetAPUSmpClkI,[smpRAdj]
    Call    ResetAPUI,10000h                                                    ;Reset APU
    Call    SetScript700I,0                                                     ;Reset Script700

    .Quit:
    Mov     EAX,1                                                               ;Return TRUE

ENDP


;===================================================================================================
;Get SNESAPU.DLL Version Information

EXPROC SNESAPUInfo, pVer, pMin, pOpt
USES EBX

    Mov     PBX,[pVer]
    Test    PBX,PBX
    JZ      .pVerNext
        Mov     EAX,[apuDllVer]
        Mov     [PBX],EAX
    .pVerNext:

    Mov     PBX,[pMin]
    Test    PBX,PBX
    JZ      .pMinNext
        Mov     EAX,[apuCmpVer]
        Mov     [PBX],EAX
    .pMinNext:

    Mov     PBX,[pOpt]
    Test    PBX,PBX
    JZ      .pOptNext
        Mov     EAX,[apuOpt]
        Mov     [PBX],EAX
    .pOptNext:

ENDP


;===================================================================================================
;Set/Reset SNESAPU Callback Function

EXPROC SNESAPUCallback, pCbFunc, cbMask
USES EBX

    Mov     PAX,[apuCbFunc]                                                     ;Return previous callback

    Mov     PBX,[pCbFunc]
    Mov     [apuCbFunc],PBX

    Mov     EBX,[cbMask]
    Or      [apuCbMask],EBX                                                     ;OR method for chain call

ENDP


;===================================================================================================
;Get SNESAPU Data Pointers

EXPROC GetAPUData, ppRAM, ppXRAM, ppOutPort, ppT64Cnt, ppDSP, ppVoice, ppVMMaxL, ppVMMaxR
USES EBX

    Mov     PBX,[ppRAM]
    Test    PBX,PBX
    JZ      .ppRAMNext
        Mov     PAX,[pAPURAM]
        Mov     [PBX],PAX
    .ppRAMNext:

%ifdef SPC700_INC
    Mov     PBX,[ppXRAM]
    Test    PBX,PBX
    JZ      .ppXRAMNext
        LoadPtr PAX,extraRAM
        Mov     [PBX],PAX
    .ppXRAMNext:

    Mov     PBX,[ppOutPort]
    Test    PBX,PBX
    JZ      .ppOutPortNext
        LoadPtr PAX,outPort
        Mov     [PBX],PAX
    .ppOutPortNext:

    Mov     PBX,[ppT64Cnt]
    Test    PBX,PBX
    JZ      .ppT64CntNext
        LoadPtr PAX,t64Cnt
        Mov     [PBX],PAX
    .ppT64CntNext:
%endif

    Mov     PBX,[ppDSP]
    Test    PBX,PBX
    JZ      .ppDSPNext
        LoadPtr PAX,dsp
        Mov     [PBX],PAX
    .ppDSPNext:

    Mov     PBX,[ppVoice]
    Test    PBX,PBX
    JZ      .ppVoiceNext
        LoadPtr PAX,mix
        Mov     [PBX],PAX
    .ppVoiceNext:

%ifdef DSP_INC
    Mov     PBX,[ppVMMaxL]
    Test    PBX,PBX
    JZ      .ppVMMaxLNext
        LoadPtr PAX,vMMaxL
        Mov     [PBX],PAX
    .ppVMMaxLNext:

    Mov     PBX,[ppVMMaxR]
    Test    PBX,PBX
    JZ      .ppVMMaxRNext
        LoadPtr PAX,vMMaxR
        Mov     [PBX],PAX
    .ppVMMaxRNext:
%endif

ENDP


;===================================================================================================
;Get Script700 Data Pointers

EXPROC GetScript700Data, pDLLVer, ppSPCReg, ppScript700
USES EBX,ECX

    Mov     PBX,[pDLLVer]
    Test    PBX,PBX
    JZ      .pDLLVerNext
        Mov     EAX,[apuVerStr+00h]
        Mov     [PBX+00h],EAX
        Mov     EAX,[apuVerStr+04h]
        Mov     [PBX+04h],EAX
        Mov     EAX,[apuVerStr+08h]
        Mov     [PBX+08h],EAX
        Mov     EAX,[apuVerStr+0Ch]
        Mov     [PBX+0Ch],EAX
        Mov     EAX,[apuVerStr+10h]
        Mov     [PBX+10h],EAX
        Mov     EAX,[apuVerStr+14h]
        Mov     [PBX+14h],EAX
        Mov     EAX,[apuVerStr+18h]
        Mov     [PBX+18h],EAX
        Mov     EAX,[apuVerStr+1Ch]
        Mov     [PBX+1Ch],EAX
    .pDLLVerNext:

%ifdef SPC700_INC
    Mov     PBX,[ppSPCReg]
    Test    PBX,PBX
    JZ      .ppSPCRegNext
        Mov     PAX,[pSPCReg]
        Mov     [PBX],PAX
    .ppSPCRegNext:
%endif

    Mov     PBX,[ppScript700]
    Test    PBX,PBX
    JZ      .ppScript700Next
        Mov     ECX,[PBX]
        Sub     ECX,PTRSIZE
        JL      .ppScript700Next

        LoadPtr PAX,scr700wrk
        Add     PBX,PTRSIZE
        Mov     [PBX],PAX
        Sub     ECX,PTRSIZE
        JL      .ppScript700Next

        LoadPtr PAX,scr700dsp
        Add     PBX,PTRSIZE
        Mov     [PBX],PAX
    .ppScript700Next:

ENDP


;===================================================================================================
;Reset Audio Processor

;Called internally by InitAPU and LoadSPCFile (see x64.inc's EXPROC for why a DEF-exported name also
; called internally needs this split).

EXPROC ResetAPU, amp

    Call    ResetAPUI,[amp]

ENDP

PROC ResetAPUI, ampI

    Call    ResetSPC
    Call    ResetDSP

    Cmp     dword [ampI],-1
    JE      .NoAmp
        Call    SetDSPAmpI,[ampI]
    .NoAmp:

    XOr     EAX,EAX
    Mov     [cycLeft],EAX
    Mov     [smpDec],EAX
    Mov     [outCur],EAX
    Mov     [outLen],EAX

ENDP


;===================================================================================================
;Fix Audio Processor After Load

;Called internally by LoadSPCFile (see x64.inc's EXPROC for why a DEF-exported name also called
; internally needs this split).

EXPROC FixAPU, pc, a, y, x, psw, s

    Call    FixAPUI,[pc],[a],[y],[x],[psw],[s]

ENDP

PROC FixAPUI, pcI, aI, yI, xI, pswI, sI

    Call    FixSPC,[pcI],[aI],[yI],[xI],[pswI],[sI]
    Call    FixDSP

ENDP


;===================================================================================================
;Load SPC File

EXPROC LoadSPCFile, pFile
LOCALS lPC,lA,lY,lX,lPSW,lS                                                     ;See the Call FixAPU note below
USES ECX,ESI,EDI

    Call    ResetAPUI,-1

    Mov     PSI,[pFile]

    Add     PSI,100h                                                            ;memcpy(&apuRAM, &spc[0x100], 0x10000)
    Mov     PDI,[pAPURAM]
    Mov     ECX,4000h
    Rep     MovSD

    LoadPtr PDI,dsp                                                             ;memcpy(&dsp, &spc[0x10100], 128)
    Mov     ECX,32
    Rep     MovSD

    Add     PSI,40h                                                             ;memcpy(&xram, &spc[0x101C0], 64)
    LoadPtr PDI,extraRAM
    Mov     ECX,16
    Rep     MovSD

    ;Extract each SPC register from the file and zero-extend it to a dword-sized local before handing
    ; them to Call FixAPU.  Call's argument marshaling always reads/writes a full 32 bits per slot, so
    ; passing a raw byte/word memory reference here directly (e.g. '[27h+PSI]') would read 3-2 extra,
    ; meaningful bytes of file data past the field -- these locals are dedicated 4-byte scratch, so a
    ; full-width read back out of them is safe.

    Mov     PSI,[pFile]
    XOr     EAX,EAX
    Mov     AL,[2Bh+PSI]                                                        ;SP
    Mov     [lS],EAX
    Mov     AL,[2Ah+PSI]                                                        ;PSW
    Mov     [lPSW],EAX
    Mov     AL,[28h+PSI]                                                        ;X
    Mov     [lX],EAX
    Mov     AL,[29h+PSI]                                                        ;Y
    Mov     [lY],EAX
    Mov     AL,[27h+PSI]                                                        ;A
    Mov     [lA],EAX
    Mov     AX,[25h+PSI]                                                        ;PC
    Mov     [lPC],EAX
    Call    FixAPUI,[lPC],[lA],[lY],[lX],[lPSW],[lS]

ENDP


;===================================================================================================
;Set Audio Processor Options

;Called internally by SeekAPU (see x64.inc's EXPROC for why a DEF-exported name also called
; internally needs this split).

EXPROC SetAPUOpt, mixType, numChn, bits, rate, inter, opts

    Call    SetAPUOptI,[mixType],[numChn],[bits],[rate],[inter],[opts]

ENDP

PROC SetAPUOptI, mixTypeI, numChnI, bitsI, rateI, interI, optsI
USES ECX,EDX

    XOr     EDX,EDX

    ;numChn ----------------------------------
    Mov     AL,[rawChn]
    Mov     AH,[numChnI]
    Cmp     AH,-1
    JE      .DefChn
        Mov     AL,AH
        Mov     [outCur],EDX
        Mov     [outLen],EDX

    .DefChn:
    Mov     [rawChn],AL

    ;bits ------------------------------------
    Mov     CL,[rawBits]
    Mov     CH,[bitsI]
    Cmp     CH,-1
    JE      .DefBits
        Mov     CL,CH
        Mov     [outCur],EDX
        Mov     [outLen],EDX

    .DefBits:
    Mov     [rawBits],CL

    ;bytes -----------------------------------
    Test    CL,CL                                                               ;rawByte = numChn * abs(bits) / 8
    SetNS   CH
    Dec     CH
    XOr     CL,CH
    Sub     CL,CH

    MovZX   EAX,AL
    MovZX   ECX,CL
    Mul     ECX
    ShR     AL,3
    Mov     [rawByte],AL

    ;rate ------------------------------------
    Mov     EAX,[rawRate]
    Mov     EDX,[rateI]
    Cmp     EDX,-1
    JE      .DefRate
        Mov     EAX,EDX

    .DefRate:
    Mov     [rateI],EAX

    ;opts ------------------------------------
    Mov     EAX,[dspOpts]
    Mov     EDX,[optsI]
    Cmp     EDX,-1
    JE      .DefOpts
        Mov     EAX,EDX

    .DefOpts:
    Mov     [optsI],EAX

    ;DSP option adjustment -------------------
    Mov     EDX,[dspOpts]
    XOr     EDX,EAX
    Mov     [dspOpts],EAX

    Test    EDX,DSP_ECHOFIR                                                     ;If the DSP_ECHOFIR flag changes,
    SetZ    AL                                                                  ; force sampling rate processing (rawRate = -1)
    MovZX   EAX,AL
    Dec     EAX
    Or      [rawRate],EAX

    Mov     EAX,[rateI]
    Cmp     EAX,[rawRate]                                                       ;Has sample rate changed?
    JE      .KeepRate                                                           ;   No
        Cmp     EAX,8000                                                        ;If rate < 8000, rate = 8000
        JAE     .OKL
            Mov     EAX,8000

        .OKL:
        Cmp     EAX,192000                                                      ;If rate > 192000, rate = 192000
        JBE     .OKH
            Mov     EAX,192000

        .OKH:
        Mov     [rawRate],EAX

%if INTBK
        Test    dword [dspOpts],DSP_ECHOFIR                                     ;Is actual emulation mode?
        JZ      .OKA                                                            ;   No, smpRate = rawRate

        Cmp     EAX,32000                                                       ;If rate > 32000, rate = 32000
        JBE     .OKA
            Mov     EAX,32000

        .OKA:
%endif

        Mov     [smpRate],EAX
        XOr     EAX,EAX
        Call    SetAPUSmpClkI,[smpRAdj]                                         ;Calculate the number of clock cycles per sample

    .KeepRate:
    Call    SetDSPOpt,[mixTypeI],[numChnI],[bitsI],[rateI],[interI],[optsI]     ;Set options in DSP emulator

ENDP


;===================================================================================================
;Set Audio Processor Sample Clock

;Called internally by InitAPU/EmuAPUI/SeekAPU (see x64.inc's EXPROC for why a DEF-exported name also
; called internally needs this split).

EXPROC SetAPUSmpClk, speed

    Call    SetAPUSmpClkI,[speed]

ENDP

PROC SetAPUSmpClkI, speedI
USES EDX

    Mov     EAX,[speedI]
    Cmp     EAX,1024                                                            ;If speed < 1024, speed = 1024 (~1.5%)
    JAE     .OKL                                                                ;Note: If lower any more, will crash or noisy.
        Mov     EAX,1024

    .OKL:
    Cmp     EAX,1048576                                                         ;If speed > 1048576, speed = 1048576 (x16)
    JBE     .OKH
        Mov     EAX,1048576

    .OKH:
    Mov     [smpRAdj],EAX
%ifdef DSP_INC
    Mov     [adsrAdj],EAX
%endif

    Mov     EAX,[smpRate]                                                       ;smpREmu = (smpRate << 16) / smpRAdj;
    MovZX   EDX,word [smpRate+2]
    ShL     EAX,16
    Div     dword [smpRAdj]
    Mov     [smpREmu],EAX

ENDP


;===================================================================================================
;Set Audio Processor Song Length
;
;NOTE (amd64 port): was 'Jmp SetDSPLength', a tail-jump alias that only works when the caller's
; and callee's calling conventions are identical.  That was true on x86, where EXPROC and PROC are
; both plain stdcall, but not on amd64: EXPROC received song/fade in RCX/RDX with no stack homing,
; since 0 declared params meant EXPROC's own homing code never ran, while SetDSPLength is a PROC
; that reads its arguments from the stack the internal Call macro would have pushed them to.
; Jumping straight into it left song/fade reading whatever garbage happened to be on the stack.
; Declaring the parameters here and forwarding via Call, not Jmp, marshals them correctly on both
; architectures, matching every other EXPROC-to-PROC forward in this codebase.

EXPROC SetAPULength, song, fade

    Call    SetDSPLength,[song],[fade]

ENDP


;===================================================================================================
;Emulate Audio Processing Unit

;EmuAPU recurses into itself internally (see EmuAPUBySmp's/.NextSec's own 'Call EmuAPUI' below), so
; the DEF-exported entry point is just a thin ABI bridge into the real (internal-convention) body --
; see x64.inc's EXPROC for why a DEF-exported name that is also called internally needs this split.

EXPROC EmuAPU, pBuf, len, type

    Mov     PCX,[pBuf]
    Mov     EDX,[len]
    MovZX   EAX,byte [type]
    Call    EmuAPUI,PCX,EDX,EAX

ENDP

PROC EmuAPUI, pBufI, lenI, typeI
USES ECX,EDX,EBX,EDI

    Mov     PDI,[pBufI]
    Mov     EAX,[lenI]
    Test    EAX,EAX
    JZ      .Done

    Test    byte [typeI],-1                                                     ;Is the unit of len samples?
    JS      .NextSec                                                            ;   No, not adjust clock cycles (for seek)
    JZ      .AdjCycles                                                          ;   No, adjust clock cycles to APU speed
        Call    EmuAPUBySmp                                                     ;   Yes
        Jmp     .Done

    .AdjCycles:
    XOr     EDX,EDX                                                             ;EAX = EAX * smpRAdj / 65536
    Mov     ECX,[smpRAdj]
    Mul     ECX
    ShRD    EAX,EDX,16

    .NextSec:
    Mov     ECX,APU_CLK
    XOr     EDX,EDX
    Mov     EBX,EAX

    ;Fixup cycles ----------------------------
    Sub     EAX,ECX                                                             ;If EAX > APU_CLK, EAX = APU_CLK
    CDQ
    And     EAX,EDX
    Add     EAX,ECX

    Sub     EBX,EAX                                                             ;len -= clock cycles
    Mov     EDX,EAX
    Add     EAX,[cycLeft]                                                       ;Is emulation completed?
    JLE     .NoCycles                                                           ;   Yes

    ;Initialize DSP --------------------------
    Push    PAX
    Mov     EAX,EDX                                                             ;samples = ((smpREmu * cycles) + smpDec) / APU_CLK
    Mul     dword [smpREmu]
    Add     EAX,[smpDec]
    AdC     EDX,0
    Div     ECX
    Mov     [smpDec],EDX

    Call    SetEmuDSP,PDI,EAX,[smpREmu]
    Pop     PAX

    ;Emulate APU -----------------------------
    ;Note: For more accurate emulation, instead of waiting for cycles after doing 1 opcode processing,
    ; running opcode should be processed internally every cycle.
    ; However, this requires complex logic and sophisticated analysis.

    Call    EmuSPC,EAX
    Mov     ECX,EAX                                                             ;ECX = len - emulated clock cycles

    Call    SetEmuDSP,0,0,0                                                     ;Create any remaining samples
    Mov     PDI,PAX                                                             ;PDI = End of buffer
    Mov     EAX,ECX

    .NoCycles:
    Mov     [cycLeft],EAX
    Mov     EAX,EBX
    Test    EBX,EBX                                                             ;Is emulation completed?
    JNZ     .NextSec                                                            ;   No, continue

    .Done:
    Mov     PAX,PDI                                                             ;PAX = End of buffer

ENDP


;===================================================================================================
;Emulate Audio Processing Unit (by sample units)
;
;If the sampling rate is not divisible by 1000 (ex. 44100, 88200Hz), the length of the generated
; waveform data will not be constant, and forcibly interpolating waveform will cause noise.
;
;This procedure returns only the specified size, with adjusting the beginning and end of the
; generated waveform data.
;
;In:
;   EAX = len (sample units)
;   PDI-> Buffer to store output
;
;Out:
;   EBX = Number of samples not output
;   PDI-> End of buffer
;
;Destroys:
;   ECX,EDX

PROC EmuAPUBySmp
USES ESI

    Mov     EBX,EAX                                                             ;EBX = len (samples)
    Mov     EAX,[outLen]
    Test    EAX,EAX                                                             ;Has already been emulated?
    JZ      .BefEnd                                                             ;   No, skip

    ;Copy before buffer ----------------------
    LoadPtr PSI,outBuf
    Mov     EDX,[outCur]                                                        ;outCur is a plain dword -- 'Add r64,r/m32' is not
    Add     PSI,PDX                                                             ; encodable, so load 32-bit then add at full width
    MovZX   EDX,byte [rawByte]

    .BefLoop:
        Mov     ECX,EDX                                                         ;Copy from outBuf to pBuf
        Rep     MovSB
        Add     [outCur],EDX
        Sub     [outLen],EDX

        Dec     EBX                                                             ;Is emulation completed?
        JZ      .Done                                                           ;   Yes, done

        Sub     EAX,EDX                                                         ;Is outBuf empty?
        JNZ     .BefLoop                                                        ;   No, continue

    .BefEnd:
    Mov     [outCur],EAX                                                        ;EAX = 0

    ;Fixup samples ---------------------------
    XOr     EDX,EDX                                                             ;EAX = samples * APU_CLK / rawRate
    Mov     EAX,EBX                                                             ;EDX = samples * APU_CLK % rawRate .. (1)
    Mov     ECX,APU_CLK
    Mul     ECX
    Mov     ECX,[rawRate]
    Div     ECX
    Push    PDX                                                                 ;(width fix only, not a pointer)

    XOr     EDX,EDX                                                             ;EAX = samples * smpRate / rawRate
    Mov     EAX,EBX                                                             ;EDX = samples * smpRate % rawRate .. (2)
    Mov     ECX,[smpRate]
    Mul     ECX
    Mov     ECX,[rawRate]
    Div     ECX

    Mov     EAX,EBX                                                             ;EAX = samples
    Pop     PCX
    Or      EDX,ECX                                                             ;Is (1) and (2) equal 0?
    JZ      .MainEmu                                                            ;   Yes, not need fixup
        Sub     EAX,8                                                           ;Need more than 8 samples?
        JLE     .AftEmu                                                         ;   No, skip

    ;Emulate to pBuf -------------------------
    .MainEmu:
    XOr     EDX,EDX                                                             ;EAX = samples to clock cycles
    Mov     ECX,APU_CLK
    Mul     ECX
    Mov     ECX,[rawRate]
    Div     ECX

    Call    EmuAPUI,PDI,EAX,0
    Mov     PDX,PAX                                                             ;Save return value of EmuAPU
    Sub     PAX,PDI                                                             ;EAX = Emulated buffer size (bytes)
    Mov     PDI,PDX                                                             ;PDI = End of buffer

    XOr     EDX,EDX                                                             ;EAX = Bytes to samples
    MovZX   ECX,byte [rawByte]
    Div     ECX
    Sub     EBX,EAX                                                             ;Is emulation completed?
    JZ      .Done                                                               ;   Yes, done

    ;Emulate to outBuf -----------------------
    .AftEmu:
    Mov     EAX,EBX                                                             ;EAX = samples

    XOr     EDX,EDX                                                             ;EAX = samples to clock cycles
    Mov     ECX,APU_CLK
    Mul     ECX
    Mov     ECX,[rawRate]
    Div     ECX

    LoadPtr PSI,outBuf
    Mov     ECX,EAX                                                             ;ECX = clock cycles (min. 24576 = 192 samples at 192000Hz)
    Cmp     ECX,24576                                                           ;Note: If clock cycles is less than 24576 and playback
    JAE     .EmuLoop                                                            ; speed is below 25%, will crash or noisy.
        Mov     ECX,24576

    .EmuLoop:
    Call    EmuAPUI,PSI,ECX,0
    Sub     PAX,PSI                                                             ;EAX = Emulated buffer size (bytes)
    JZ      .EmuLoop                                                            ;Continue until the waveform is output

    ;Copy after buffer -----------------------
    Mov     [outLen],EAX
    MovZX   EDX,byte [rawByte]

    .AftLoop:
        Mov     ECX,EDX                                                         ;Copy from outBuf to pBuf
        Rep     MovSB
        Add     [outCur],EDX
        Sub     [outLen],EDX

        Dec     EBX                                                             ;Is emulation completed?
        JZ      .Done                                                           ;   Yes, done

        Sub     EAX,EDX                                                         ;Is outBuf empty?
        JNZ     .AftLoop                                                        ;   No, continue
        Jmp     .AftEmu                                                         ;   Yes, re-run emulation

    .Done:

ENDP


;===================================================================================================
;Seek to Position

EXPROC SeekAPU, time, fast
USES ECX,EDX

    XOr     EDX,EDX
    Mov     EAX,[time]                                                          ;numSeconds = time / 64000
    Test    EAX,EAX
    RetZF

    Mov     ECX,64000
    Div     ECX
    Mov     ECX,EAX                                                             ;ECX = time / 64000
    IMul    EDX,APU_CLK/64000                                                   ;EDX = (time % 64000) * (APU_CLK / 64000)

    Test    byte [fast],-1                                                      ;Fast mode completely bypasses the DSP emulation
    JZ      .Slow
        Call    SetSPCDbgI,-1,SPC_NODSP                                         ;Disable writes to the DSP registers

        Test    EDX,EDX
        JZ      .EmuSPC

        Call    EmuSPC,EDX
        Test    ECX,ECX
        JZ      .DoneSeek

        .EmuSPC:
        Call    EmuSPC,APU_CLK
        Dec     ECX
        JNZ     .EmuSPC

        .DoneSeek:
        Call    SetSPCDbgI,-1,0                                                 ;Re-enable writes to the DSP registers
        Jmp     .Done

    .Slow:
        Mov     EAX,[dspOpts]
        Push    PAX                                                             ;Save APU options (width fix only, not a pointer)
        Or      EAX,DSP_ENVSPD+DSP_NOSAFE
        Call    SetAPUOptI,-1,-1,-1,-1,-1,EAX
        Mov     EAX,[smpRAdj]
        Push    PAX,PDI                                                         ;Save APU speed (width fix only, not a pointer)

        Mov     EDI,EAX
        ShR     EAX,16
        JNZ     .MinSpeed                                                       ;When APU speed is less than 100%, temporarily increase
            Mov     EDI,10000h                                                  ; it to 100% to speed up processing

        .MinSpeed:
        Test    EDX,EDX
        JZ      .EmuAPU

        Call    SetAPUSmpClkI,EDI
        Call    EmuAPUI,0,EDX,-1                                                ;Do not adjust clock cycles to APU speed
        Test    ECX,ECX
        JZ      .DoneSlow

        .EmuAPU:
        XOr     EAX,EAX                                                         ;If last second then emulate at current speed
        Dec     ECX                                                             ; else at maximum speed for faster
        SetZ    AL
        Inc     ECX
        Dec     EAX
        Or      EAX,EDI
        Call    SetAPUSmpClkI,EAX
        Call    EmuAPUI,0,APU_CLK,-1                                            ;Do not adjust clock cycles to APU speed
        Dec     ECX
        JNZ     .EmuAPU

        .DoneSlow:
        Pop     PDI,PAX
        Call    SetAPUSmpClkI,EAX                                               ;Restore APU speed
        Pop     PAX
        Call    SetAPUOptI,-1,-1,-1,-1,-1,EAX                                   ;Restore APU options

    .Done:
    Call    FixSeek,[fast]                                                      ;Fixup DSP after seeking

ENDP


;===================================================================================================
;Set/Reset TimerTrick Compatible Function

EXPROC SetTimerTrick, port, wait
USES ECX,ESI

    Mov     CL,[scr700inc+02h]
    Test    CL,CL                                                               ;Include mode?
    JNZ     .EXIT                                                               ;   Yes

    Call    SetScript700I,0                                                     ;Reset Script700
    Mov     ECX,[wait]                                                          ;ECX = wait
    Test    ECX,ECX                                                             ;ECX = 0x00?
    JZ      .EXIT                                                               ;   Yes
        ;---------- TimerTrick -> Script700 binary converter ----------

        Mov     PSI,[pSCRRAM]                                                   ;PSI = Script RAM Pointer
        Mov     [PSI+02h],ECX                                                   ;Program[0x02] = ECX
        Mov     CL,[port]                                                       ;CL = port
        Mov     [PSI+0Eh],CL                                                    ;Program[0x0E] = CL

        ;-------------------------------------------------------------------------------
        ; [Script700 Command]       [Binary]
        ; :0    w   (WAIT)      ->  0x00 : 0x01 0x00 ???? ???? ???? ????
        ;       a   #1  i(PORT) ->  0x06 : 0x04 0x00 0x00 0x01 0x00 0x00 0x00 0x02 ????
        ;       bra 0           ->  0x0F : 0x05 0x00 0x00
        ;       (EXIT)          ->  0x12 : 0x00
        ;-------------------------------------------------------------------------------

        Mov     word  [PSI+00h],0001h
        Mov     dword [PSI+06h],01000004h
        Mov     dword [PSI+0Ah],02000000h
        Mov     dword [PSI+0Fh],00000005h
        Mov     dword [scr700lbl],0

    .EXIT:

ENDP


;===================================================================================================
;Seek First Command
;   Uses: DH, AL
;   Z flag: OFF=Success, ON=Failure

PROC GetScript700First

    XOr     DH,DH                                                               ;DH = 0x00

    .RETURN:
    Mov     AL,[PCX]                                                            ;AL = [PCX]
    Cmp     AL,00h                                                              ;Is char NULL?
    JE      .ERROR                                                              ;   Yes
    Cmp     AL,09h                                                              ;Is char TAB?
    JE      .NEXT                                                               ;   Yes
    Cmp     AL,0Ah                                                              ;Is char RETURN?
    JE      .ERROR                                                              ;   Yes
    Cmp     AL,0Dh                                                              ;Is char RETURN?
    JE      .ERROR                                                              ;   Yes
    Cmp     AL,20h                                                              ;Is char SPACE?
    JE      .NEXT                                                               ;   Yes
    Or      DH,01h                                                              ;DH = 0x01 (Success)
    Jmp     .EXIT

    .NEXT:
    Inc     PCX                                                                 ;PCX++
    Jmp     .RETURN

    .ERROR:
    XOr     DH,DH                                                               ;DH = 0x00 (Failure)

    .EXIT:
    Test    DH,DH                                                               ;DH = 0x00 (Failure)?

ENDP


;===================================================================================================
;Seek Next Command/Parameter
;   Uses: DH, AL
;   Z flag: OFF=Success, ON=Failure

PROC GetScript700Next

    XOr     DH,DH                                                               ;DH = 0x00

    .RETURN:
    Mov     AL,[PCX]                                                            ;AL = [PCX]
    Cmp     AL,00h                                                              ;Is char NULL?
    JE      .ERROR                                                              ;   Yes
    Cmp     AL,09h                                                              ;Is char TAB?
    JE      .NEXT                                                               ;   Yes
    Cmp     AL,0Ah                                                              ;Is char RETURN?
    JE      .ERROR                                                              ;   Yes
    Cmp     AL,0Dh                                                              ;Is char RETURN?
    JE      .ERROR                                                              ;   Yes
    Cmp     AL,20h                                                              ;Is char SPACE?
    JE      .NEXT                                                               ;   Yes
    Jmp     .EXIT

    .NEXT:
    Inc     PCX                                                                 ;PCX++
    Or      DH,01h                                                              ;DH = 0x01 (Success)
    Jmp     .RETURN

    .ERROR:
    XOr     DH,DH                                                               ;DH = 0x00 (Failure)

    .EXIT:
    Test    DH,DH                                                               ;DH = 0x00 (Failure)?

ENDP


;===================================================================================================
;Skip Next Command/Parameter
;   Uses: AL

PROC GetScript700Skip

    .RETURN:
    Mov     AL,[PCX]                                                            ;AL = [PCX]
    Cmp     AL,00h                                                              ;Is char NULL?
    JE      .EXIT                                                               ;   Yes
    Cmp     AL,09h                                                              ;Is char TAB?
    JE      .EXIT                                                               ;   Yes
    Cmp     AL,20h                                                              ;Is char SPACE?
    JE      .EXIT                                                               ;   Yes
    Inc     PCX                                                                 ;PCX++
    Jmp     .RETURN

    .EXIT:

ENDP


;===================================================================================================
;Seek Next Line
;   Uses: DH, AL

PROC GetScript700NextLine

    .RETURN:
    Mov     AL,[PCX]                                                            ;AL = [PCX]
    Cmp     AL,00h                                                              ;Is char NULL?
    JE      .EXIT                                                               ;   Yes
    Cmp     AL,0Ah                                                              ;Is char RETURN?
    JE      .NEXT2                                                              ;   Yes
    Cmp     AL,0Dh                                                              ;Is char RETURN?
    JE      .NEXT2                                                              ;   Yes
    Inc     PCX                                                                 ;PCX++
    Jmp     .RETURN

    .NEXT:
    Mov     AL,[PCX]                                                            ;AL = [PCX]
    Cmp     AL,00h                                                              ;Is char NULL?
    JE      .EXIT                                                               ;   Yes
    Cmp     AL,0Ah                                                              ;Is char RETURN?
    JE      .NEXT2                                                              ;   Yes
    Cmp     AL,0Dh                                                              ;Is char RETURN?
    JE      .NEXT2                                                              ;   Yes
    Jmp     .EXIT

    .NEXT2:
    Inc     PCX                                                                 ;PCX++
    Jmp     .NEXT

    .EXIT:

ENDP


;===================================================================================================
;Parse Number (Supported DEC or HEX, and Minus)
;   EAX = Number of Result
;   Uses: DH
;   Z flag: OFF=Success, ON=Failure

PROC GetScript700Number

    Push    PBX
    XOr     EAX,EAX                                                             ;EAX = 0x00
    XOr     EBX,EBX                                                             ;EBX = 0x00
    XOr     DH,DH                                                               ;DH = 0x00

    Mov     BL,[PCX]                                                            ;BL = [PCX]
    Cmp     BL,2Bh                                                              ;Is char "+"?
    JE      .NOP                                                                ;   Yes
    Cmp     BL,2Dh                                                              ;Is char "-"?
    JE      .MINUS                                                              ;   Yes

    .RETURNFIRST:
    Cmp     BL,30h                                                              ;Is char "0"?
    JE      .HEXZ                                                               ;   Yes
    Cmp     BL,24h                                                              ;Is char "$"?
    JE      .HEXOK                                                              ;   Yes

    .RETURN:
    Mov     BL,[PCX]                                                            ;BL = Char
    Sub     BL,30h                                                              ;BL -= 0x30
    Cmp     BL,10                                                               ;BL >= 10? (Is not char "0" to "9"?)
    JAE     .HEXCHECK                                                           ;   Yes
    Jmp     .RETURNNEXT

    .HEXCHECKNEXT:
    Add     BL,10                                                               ;BL += 10

    .RETURNNEXT:
    Test    DH,04h                                                              ;DH &= 0x04? (HEX mode?)
    JNZ     .SETHEX                                                             ;   Yes
        LEA     EAX,[EAX+EAX*4]                                                 ;EAX *= 5
        Add     EAX,EAX                                                         ;EAX += EAX                         ;(EAX *= 10)
        Jmp     .SETOK

    .SETHEX:
        ShL     EAX,4                                                           ;EAX << 4

    .SETOK:
    Add     EAX,EBX                                                             ;EAX += EBX
    Inc     PCX                                                                 ;PCX++
    Or      DH,01h                                                              ;DH |= 0x01 (Success)
    Jmp     .RETURN

    .MINUS:
    Or      DH,02h                                                              ;DH |= 0x02 (MINUS mode)

    .NOP:
    Inc     PCX                                                                 ;PCX++
    Mov     BL,[PCX]                                                            ;BL = Char
    Jmp     .RETURNFIRST

    .HEXZ:
    Inc     PCX                                                                 ;PCX++
    Mov     BL,[PCX]                                                            ;BL = Char
    And     BL,0DFh                                                             ;BL &= 0xDF
    Cmp     BL,58h                                                              ;Is char "X"?
    JE      .HEXOK                                                              ;   Yes
    Dec     PCX                                                                 ;PCX--
    Jmp     .RETURN

    .HEXOK:
    Or      DH,04h                                                              ;DH |= 0x04 (HEX mode)
    Inc     PCX                                                                 ;PCX++
    Jmp     .RETURN

    .HEXCHECK:
    Test    DH,04h                                                              ;DH &= 0x04? (HEX mode?)
    JZ      .NEXT                                                               ;   No
    Sub     BL,11h                                                              ;BL -= 0x11 (0x41)
    Cmp     BL,6                                                                ;BL < 6? (Is char "A" to "F"?)
    JB      .HEXCHECKNEXT                                                       ;   Yes
    Sub     BL,20h                                                              ;BL -= 0x20 (0x61)
    Cmp     BL,6                                                                ;BL < 6? (Is char "a" to "f"?)
    JB      .HEXCHECKNEXT                                                       ;   Yes

    .NEXT:
    Mov     BL,[PCX]                                                            ;BL = Char
    Cmp     BL,00h                                                              ;Is char NULL?
    JE      .EXIT                                                               ;   Yes
    Cmp     BL,09h                                                              ;Is char TAB?
    JE      .EXIT                                                               ;   Yes
    Cmp     BL,0Ah                                                              ;Is char RETURN?
    JE      .EXIT                                                               ;   Yes
    Cmp     BL,0Dh                                                              ;Is char RETURN?
    JE      .EXIT                                                               ;   Yes
    Cmp     BL,20h                                                              ;Is char SPACE?
    JE      .EXIT                                                               ;   Yes
    XOr     DH,DH                                                               ;DH = 0x00 (Failure)

    .EXIT:
    Test    DH,02h                                                              ;DH &= 0x02? (MINUS mode?)
    JZ      .PLUS                                                               ;   No
        Neg     EAX                                                             ;EAX = -EAX
    .PLUS:
    Pop     PBX
    And     DH,01h                                                              ;DH &= 0x01

ENDP


;===================================================================================================
;Check Last of Command/Parameter
;   Uses: DH, AL
;   Z flag: OFF=Success, ON=Failure

PROC GetScript700Last

    XOr     DH,DH                                                               ;DH = 0x00
    Or      DH,01h                                                              ;DH = 0x01 (Success)
    Inc     PCX                                                                 ;PCX++
    Mov     AL,[PCX]                                                            ;AL = Char
    Cmp     AL,00h                                                              ;Is char NULL?
    JE      .OK                                                                 ;   Yes
    Cmp     AL,09h                                                              ;Is char TAB?
    JE      .OK                                                                 ;   Yes
    Cmp     AL,0Ah                                                              ;Is char RETURN?
    JE      .OK                                                                 ;   Yes
    Cmp     AL,0Dh                                                              ;Is char RETURN?
    JE      .OK                                                                 ;   Yes
    Cmp     AL,20h                                                              ;Is char SPACE?
    JE      .OK                                                                 ;   Yes
    XOr     DH,DH                                                               ;DH = 0x00 (Failure)

    .OK:
    Test    DH,DH                                                               ;DH = 0x00 (Failure)?

ENDP


;===================================================================================================
;Set/Reset Script700 Compatible Function
;   EAX = Free / Result of GetScript700Number / (AL) Use GetScript700xxx function
;   EBX = Index of Script700 binary area
;   ECX = Pointer of Script700 buffer
;   EDX = Free / (DH) Use GetScript700xxx function
;   ESI = Pointer base of Script700 binary area
;   EDI = Index of Script700 program area for rollback

;Called internally by InitAPU/EmuAPUI (see x64.inc's EXPROC for why a DEF-exported name also called
; internally needs this split).

EXPROC SetScript700, pSource

    Mov     PAX,[pSource]
    Call    SetScript700I,PAX

ENDP

PROC SetScript700I, pSourceI
USES ECX,EDX,EBX,ESI,EDI

    ;---------- Initialize ----------

    Mov     PSI,[pSCRRAM]                                                       ;PSI = Script RAM Pointer

    Mov     AX,[scr700inc+02h]
    Test    AL,AL                                                               ;Include mode?
    JZ      .INIT                                                               ;   No
        Mov     PCX,[pSourceI]                                                  ;PCX = Source Pointer
        Test    PCX,PCX                                                         ;PCX = NULL?
        JZ      .CRITICALERROR                                                  ;   Yes

        IdxLd   Mov,EBX,scr700inc,04h
        Mov     EDI,EBX
        Dec     AH
        JZ      .EXTRETURN
        Dec     AH
        JZ      .DATARETURN2
        Jmp     .NORMALRETURN

    .INIT:
    XOr     EAX,EAX                                                             ;EAX = 0x00
    Mov     [PSI],AL                                                            ;Program[0] = AL
    Mov     [scr700ptr],EAX                                                     ;Reset Pointer
    Mov     [scr700dat],EAX
    Mov     [scr700inc],EAX

    XOr     EBX,EBX                                                             ;EBX = 0x00
    Inc     EBX                                                                 ;EBX++ (0x01)
    Mov     [scr700cnt],EBX

    LoadPtr PDI,scr700dsp
    Mov     PCX,328                                                             ;Channel(256/4) + Master(32/4) + Detune(256)
    Rep     StoSD

    LoadPtr PDI,scr700chg
    Mov     ECX,EAX                                                             ;PCX = EAX (0x00)

    .CLEARCHG:
        Dec     CL                                                              ;CL--
        Mov     [PDI+PCX],CL
    Dec     AL                                                                  ;AL--
    JNZ     .CLEARCHG

    LoadPtr PDI,scr700lbl
    Dec     EAX                                                                 ;EAX-- (0xFFFFFFFF)
    Mov     PCX,1024                                                            ;4096byte
    Rep     StoSD

    Mov     PCX,[pSourceI]                                                      ;PCX = Source Pointer
    Test    PCX,PCX                                                             ;PCX = NULL?
    JZ      .CRITICALERROR                                                      ;   Yes
    XOr     PBX,PBX                                                             ;PBX = 0x00
    XOr     PDI,PDI                                                             ;PDI = 0x00

    ;---------- Script Command Zone ----------

    .NORMALRETURN:
    And     PBX,SCR700MASK                                                      ;PBX &= Program Mask
    Cmp     PBX,PDI                                                             ;PBX < PDI?
    JB      .CRITICALERROR                                                      ;   Yes

    Mov     PDI,PBX                                                             ;PDI = PBX
    Call    GetScript700First                                                   ;Seek First
    JZ      .NORMALERROR                                                        ;   Failure
    XOr     DL,DL                                                               ;DL = 0x00
    Mov     AL,[PCX]                                                            ;AL = [PCX]
    Cmp     AL,3Ah                                                              ;Is char ":"?
    JE      .LABEL                                                              ;   Yes
    Cmp     AL,23h                                                              ;Is char "#"?
    JE      .Shp                                                                ;   Yes
    And     AL,0DFh                                                             ;AL &= 0xDF
    Cmp     AL,45h                                                              ;Is char "E"?
    JE      .E                                                                  ;   Yes
    Cmp     AL,51h                                                              ;Is char "Q"?
    JE      .Q                                                                  ;   Yes
    Cmp     AL,57h                                                              ;Is char "W"?
    JE      .W                                                                  ;   Yes
    Cmp     AL,4Dh                                                              ;Is char "M"?
    JE      .M                                                                  ;   Yes
    Cmp     AL,43h                                                              ;Is char "C"?
    JE      .C                                                                  ;   Yes
    Cmp     AL,41h                                                              ;Is char "A"?
    JE      .A                                                                  ;   Yes
    Cmp     AL,53h                                                              ;Is char "S"?
    JE      .S                                                                  ;   Yes
    Cmp     AL,55h                                                              ;Is char "U"?
    JE      .U                                                                  ;   Yes
    Cmp     AL,44h                                                              ;Is char "D"?
    JE      .D                                                                  ;   Yes
    Cmp     AL,4Eh                                                              ;Is char "N"?
    JE      .N                                                                  ;   Yes
    Cmp     AL,42h                                                              ;Is char "B"?
    JE      .B                                                                  ;   Yes
    Cmp     AL,52h                                                              ;Is char "R"?
    JE      .R                                                                  ;   Yes
    Cmp     AL,46h                                                              ;Is char "F"?
    JE      .F                                                                  ;   Yes
    Jmp     .NORMALERROR                                                        ;   No

    .E:                                                                                                             ; e
    Call    GetScript700Last                                                    ;Check Last
    JZ      .NORMALERROR                                                        ;   Failure

    Mov     byte [scr700inc+03h],01h                                            ;Extension Command Zone
    Jmp     .EXTRETURN

    .Q:                                                                                                             ; q
    Call    GetScript700Last                                                    ;Check Last
    JZ      .NORMALERROR                                                        ;   Failure

    Mov     byte [PSI+PBX],00h                                                  ;Program[PBX] = 0x00
    Inc     PBX                                                                 ;PBX++
    Jmp     .NORMALRETURN

    .LABEL:
    Inc     PCX                                                                 ;PCX++
    Mov     AL,[PCX]                                                            ;AL = [PCX]
    Cmp     AL,3Ah                                                              ;Is char ":"?
    JE      .LABEL2                                                             ;   Yes
    Call    GetScript700Number                                                  ;Parse Number (EAX = result)        ; :[LABEL]
    JZ      .NORMALERROR                                                        ;   Failure

    And     EAX,1023                                                            ;EAX &= 1023
    IdxSt   Mov,scr700lbl,PAX*4,PBX                                             ;Label[EAX] = PBX
    Jmp     .NORMALRETURN

    .LABEL2:                                                                                                        ; ::
    Call    GetScript700Last                                                    ;Check Last
    JZ      .NORMALERROR                                                        ;   Failure

    Mov     byte [scr700inc+03h],01h                                            ;Extension Command Zone
    Jmp     .EXTRETURN

    .NOP:                                                                                                           ; nop
    Inc     PCX                                                                 ;PCX++
    Mov     AL,[PCX]                                                            ;AL = [PCX]
    Test    AL,AL                                                               ;AL = 0x00?
    JZ      .NORMALERROR                                                        ;   Yes

    And     AL,0DFh                                                             ;AL &= 0xDF
    Cmp     AL,50h                                                              ;Is char "P"?
    JNE     .NORMALERROR                                                        ;   No

    Call    GetScript700Last                                                    ;Check Last
    JZ      .NORMALERROR                                                        ;   Failure
    Jmp     .NORMALRETURN

    .N:                                                                                                             ; n
    Inc     PCX                                                                 ;PCX++
    Mov     AL,[PCX]                                                            ;AL = [PCX]
    And     AL,0DFh                                                             ;AL &= 0xDF
    Cmp     AL,4Fh                                                              ;Is char "O"?
    JE      .NOP                                                                ;   Yes
    Mov     DL,04h                                                              ;DL = 0x04
    Call    GetScript700Next                                                    ;Seek Next
    JZ      .NORMALERROR                                                        ;   Failure

    Mov     [scr700tmp],PCX                                                     ;Temp = PCX (Save Param1 Pointer)
    Call    GetScript700Skip                                                    ;Skip
    Call    GetScript700Next                                                    ;Seek Next
    JZ      .NORMALERROR                                                        ;   Failure

    Mov     AL,[PCX]                                                            ;AL = [PCX]
    XOr     DH,DH                                                               ;DH = 0x00
    Cmp     AL,2Bh                                                              ;Is char "+"?
    JE      .NORMALNEXT                                                         ;   Yes
    Inc     DH                                                                  ;DH++ (0x01)
    Cmp     AL,2Dh                                                              ;Is char "-"?
    JE      .NORMALNEXT                                                         ;   Yes
    Inc     DH                                                                  ;DH++ (0x02)
    Cmp     AL,2Ah                                                              ;Is char "*"?
    JE      .NORMALNEXT                                                         ;   Yes
    Inc     DH                                                                  ;DH++ (0x03)
    Cmp     AL,2Fh                                                              ;Is char "/"?
    JE      .NORMALNEXT                                                         ;   Yes
    Inc     DH                                                                  ;DH++ (0x04)
    Cmp     AL,5Ch                                                              ;Is char "\"?
    JE      .NORMALNEXT                                                         ;   Yes
    Inc     DH                                                                  ;DH++ (0x05)
    Cmp     AL,25h                                                              ;Is char "%"?
    JE      .NORMALNEXT                                                         ;   Yes
    Inc     DH                                                                  ;DH++ (0x06)
    Cmp     AL,24h                                                              ;Is char "$"?
    JE      .NORMALNEXT                                                         ;   Yes
    Inc     DH                                                                  ;DH++ (0x07)
    Cmp     AL,26h                                                              ;Is char "&"?
    JE      .NORMALNEXT                                                         ;   Yes
    Inc     DH                                                                  ;DH++ (0x08)
    Cmp     AL,7Ch                                                              ;Is char "|"?
    JE      .NORMALNEXT                                                         ;   Yes
    Inc     DH                                                                  ;DH++ (0x09)
    Cmp     AL,5Eh                                                              ;Is char "^"?
    JE      .NORMALNEXT                                                         ;   Yes
    Inc     DH                                                                  ;DH++ (0x0A)
    Cmp     AL,3Ch                                                              ;Is char "<"?
    JE      .NORMALNEXT                                                         ;   Yes
    Inc     DH                                                                  ;DH++ (0x0B)
    Cmp     AL,3Eh                                                              ;Is char ">"?
    JE      .NORMALNEXT                                                         ;   Yes
    Inc     DH                                                                  ;DH++ (0x0C)
    Cmp     AL,5Fh                                                              ;Is char "_"?
    JE      .NORMALNEXT                                                         ;   Yes
    Inc     DH                                                                  ;DH++ (0x0D)
    Cmp     AL,21h                                                              ;Is char "!"?
    JE      .NORMALNEXT                                                         ;   Yes
    Mov     DH,0FFh                                                             ;DH = 0xFF
    Jmp     .NORMALNEXT

    .M:                                                                                                             ; m
    Mov     DL,02h                                                              ;DL = 0x02
    Jmp     .NORMALNEXT

    .C:                                                                                                             ; c
    Mov     DL,03h                                                              ;DL = 0x03
    Jmp     .NORMALNEXT

    .A:                                                                                                             ; a
    Mov     DX,0005h                                                            ;DL = 0x05, DH = 0x00
    Jmp     .NORMALNEXT

    .S:                                                                                                             ; s
    Mov     DX,0105h                                                            ;DL = 0x05, DH = 0x01
    Jmp     .NORMALNEXT

    .U:                                                                                                             ; u
    Mov     DX,0205h                                                            ;DL = 0x05, DH = 0x02
    Jmp     .NORMALNEXT

    .D:                                                                                                             ; d
    Mov     DX,0305h                                                            ;DL = 0x05, DH = 0x03

    .NORMALNEXT:
    Cmp     DL,04h                                                              ;DL = 0x04? (Is command N?)
    JE      .SETN                                                               ;   Yes
    Cmp     DL,05h                                                              ;DL = 0x05? (Is command A,S,U,D?)
    JE      .SETASUD                                                            ;   Yes
        Mov     [PSI+PBX],DL                                                    ;Program[PBX] = DL
        Jmp     .SETNE

    .SETN:
        Inc     DH                                                              ;DH++ (DH = 0xFF?)
        JZ      .NORMALERROR                                                    ;   Yes

        Dec     DH                                                              ;DH--
        Mov     [PSI+PBX],DL                                                    ;Program[PBX] = DL
        Inc     PBX                                                             ;PBX++
        Mov     [PSI+PBX],DH                                                    ;Program[PBX] = DH
        Jmp     .SETNE

    .SETASUD:
        Inc     DH                                                              ;DH++ (DH = 0xFF?)
        JZ      .NORMALERROR                                                    ;   Yes

        Dec     DH                                                              ;DH--
        Mov     byte [PSI+PBX],04h                                              ;Program[PBX] = 0x04
        Inc     PBX                                                             ;PBX++
        Mov     [PSI+PBX],DH                                                    ;Program[PBX] = DH

    .SETNE:
    Inc     PBX                                                                 ;PBX++
    Cmp     DL,04h                                                              ;DL = 0x04? (Is command N?)
    JNE     .NNEXT                                                              ;   No
        Call    GetScript700Last                                                ;Check Last
        JZ      .NORMALERROR                                                    ;   Failure

        Mov     PCX,[scr700tmp]                                                 ;PCX = Temp (Restore Param1 Pointer)
        Jmp     .N1E

    .NNEXT:
        Inc     PCX                                                             ;PCX++
        Call    GetScript700Next                                                ;Seek Next
        JZ      .NORMALERROR                                                    ;   Failure

    .N1E:
    ShL     EDX,16                                                              ;EDX << 16
    LoadPtr PAX,.N2                                                             ;Set Return Address
    Mov     [scr700jmp],PAX
    Inc     DH                                                                  ;DH++ (DH = 0x01)
    Jmp     .SETVAL

    .W:                                                                                                             ; w
    Inc     PCX                                                                 ;PCX++
    Mov     AL,[PCX]                                                            ;AL = [PCX]
    And     AL,0DFh                                                             ;AL &= 0xDF
    Cmp     AL,49h                                                              ;Is char "I"?
    JE      .WI                                                                 ;   Yes
    Cmp     AL,4Fh                                                              ;Is char "O"?
    JE      .WO                                                                 ;   Yes
    Dec     PCX                                                                 ;PCX--

    Mov     byte [PSI+PBX],01h                                                  ;Program[PBX] = 0x01
    Jmp     .WNEXT

    .WI:                                                                                                            ; wi
    Mov     byte [PSI+PBX],16h                                                  ;Program[PBX] = 0x16
    Jmp     .WNEXT

    .WO:                                                                                                            ; wo
    Mov     byte [PSI+PBX],17h                                                  ;Program[PBX] = 0x17

    .WNEXT:
    Inc     PBX                                                                 ;PBX++
    Inc     PCX                                                                 ;PCX++
    Call    GetScript700Next                                                    ;Seek Next
    JZ      .NORMALERROR                                                        ;   Failure

    LoadPtr PAX,.NORMALRETURN                                                   ;Set Return Address
    Mov     [scr700jmp],PAX
    XOr     DH,DH                                                               ;DH = 0x00
    Jmp     .SETVAL

    .N2:
    ShR     EDX,16                                                              ;EDX >> 16
    Cmp     DL,04h                                                              ;DL = 0x04? (Is command N?)
    JNE     .N2E                                                                ;   No
        Call    GetScript700Next                                                ;Seek Next
        JZ      .NORMALERROR                                                    ;   Failure
        Call    GetScript700Skip                                                ;Skip

    .N2E:
    Call    GetScript700Next                                                    ;Seek Next
    JZ      .NORMALERROR                                                        ;   Failure

    LoadPtr PAX,.NORMALRETURN                                                   ;Set Return Address
    Mov     [scr700jmp],PAX
    Mov     DH,01h                                                              ;DH = 0x01

    .SETVAL:
    Mov     AL,[PCX]                                                            ;AL = [PCX]
    XOr     DL,DL                                                               ;DL = 0x00
    Cmp     AL,23h                                                              ;Is char "#"?                       ; #[NUM]
    JE      .SETVAL4B                                                           ;   Yes
    And     AL,0DFh                                                             ;AL &= 0xDF
    Add     DL,2                                                                ;DL += 2 (0x02)
    Cmp     AL,49h                                                              ;Is char "I"?                       ; i[PORT]
    JE      .SETVAL1B                                                           ;   Yes
    Inc     DL                                                                  ;DL++ (0x03)
    Cmp     AL,4Fh                                                              ;Is char "O"?                       ; o[PORT]
    JE      .SETVAL1B                                                           ;   Yes
    Inc     DL                                                                  ;DL++ (0x04)
    Cmp     AL,57h                                                              ;Is char "W"?                       ; w[WORK]
    JE      .SETVAL1B                                                           ;   Yes
    Inc     DL                                                                  ;DL++ (0x05)
    Cmp     AL,58h                                                              ;Is char "X"?                       ; x[XRAM]
    JE      .SETVAL1B                                                           ;   Yes
    XOr     AH,AH                                                               ;AH = 0x00
    Inc     DL                                                                  ;DL++ (0x06)
    Cmp     AL,52h                                                              ;Is char "R"?                       ; r(x)[RAM]
    JE      .SETVALRD                                                           ;   Yes
    Inc     AH                                                                  ;AH++ (0x01)
    Add     DL,3                                                                ;DL += 3 (0x09)
    Cmp     AL,44h                                                              ;Is char "D"?                       ; d(x)[DATA]
    JE      .SETVALRD                                                           ;   Yes
    Add     DL,3                                                                ;DL += 3 (0x0C)
    Cmp     AL,4Ch                                                              ;Is char "L"?                       ; l[LABEL]
    JE      .SETVAL2B                                                           ;   Yes

    Dec     PCX                                                                 ;PCX--                              ; (#)[NUM]/[PORT]
    Mov     DL,DH                                                               ;DL = DH
    Dec     DH                                                                  ;DH-- (DH = 0x01?)
    JNZ     .SETVAL4B                                                           ;   No (w command)
    Jmp     .SETVAL1B                                                           ;   Yes (others command)

    .SETVALRD:
    Inc     PCX                                                                 ;PCX++
    Mov     AL,[PCX]                                                            ;AL = [PCX]
    And     AL,0DFh                                                             ;AL &= 0xDF
    Cmp     AL,42h                                                              ;Is char "B"?                       ; rb[RAM], db[DATA]
    JE      .SETVALRD2                                                          ;   Yes
    Inc     DL                                                                  ;DL++ (0x07 or 0x0A)
    Cmp     AL,57h                                                              ;Is char "W"?                       ; rw[RAM], dw[DATA]
    JE      .SETVALRD2                                                          ;   Yes
    Inc     DL                                                                  ;DL++ (0x08 or 0x0B)
    Cmp     AL,44h                                                              ;Is char "D"?                       ; rd[RAM], dd[DATA]
    JE      .SETVALRD2                                                          ;   Yes
    Dec     PCX                                                                 ;PCX--                              ; r[RAM], d[DATA]
    Sub     DL,2                                                                ;DL -= 2 (0x06 or 0x09)

    .SETVALRD2:
    Dec     AH                                                                  ;AH-- (AH = 0x01?)
    JNZ     .SETVAL2B                                                           ;   No

    .SETVAL4B:                                                                                                      ; 4 byte method
    Inc     PCX                                                                 ;PCX++
    Mov     AL,[PCX]                                                            ;AL = [PCX]
    Cmp     AL,3Fh                                                              ;Is char "?"?
    JE      .SETVALCMP                                                          ;   Yes
    Call    GetScript700Number                                                  ;Parse Number (EAX = result)
    JZ      .NORMALERROR                                                        ;   Failure

    Mov     [PSI+PBX],DL                                                        ;Program[PBX] = DL
    Inc     PBX                                                                 ;PBX++
    Mov     [PSI+PBX],EAX                                                       ;Program[PBX] = EAX
    Add     PBX,4                                                               ;PBX += 4
    Jmp     [scr700jmp]

    .SETVAL1B:                                                                                                      ; 1 byte method
    Inc     PCX                                                                 ;PCX++
    Mov     AL,[PCX]                                                            ;AL = [PCX]
    Cmp     AL,3Fh                                                              ;Is char "?"?
    JE      .SETVALCMP                                                          ;   Yes
    Call    GetScript700Number                                                  ;Parse Number (EAX = result)
    JZ      .NORMALERROR                                                        ;   Failure

    Mov     [PSI+PBX],DL                                                        ;Program[PBX] = DL
    Inc     PBX                                                                 ;PBX++
    Mov     [PSI+PBX],AL                                                        ;Program[PBX] = AL
    Inc     PBX                                                                 ;PBX++
    Jmp     [scr700jmp]

    .SETVAL2B:                                                                                                      ; 2 byte method
    Inc     PCX                                                                 ;PCX++
    Mov     AL,[PCX]                                                            ;AL = [PCX]
    Cmp     AL,3Fh                                                              ;Is char "?"?
    JE      .SETVALCMP                                                          ;   Yes
    Call    GetScript700Number                                                  ;Parse Number (EAX = result)
    JZ      .NORMALERROR                                                        ;   Failure

    Mov     [PSI+PBX],DL                                                        ;Program[PBX] = DL
    Inc     PBX                                                                 ;PBX++
    Mov     [PSI+PBX],AX                                                        ;Program[PBX] = AX
    Add     PBX,2                                                               ;PBX += 2
    Jmp     [scr700jmp]

    .SETVALCMP:                                                                                                     ; cmp method
    Call    GetScript700Last                                                    ;Check Last
    JZ      .NORMALERROR                                                        ;   Failure

    Add     DL,10h                                                              ;DL += 0x10
    Mov     [PSI+PBX],DL                                                        ;Program[PBX] = DL
    Inc     PBX                                                                 ;PBX++
    Jmp     [scr700jmp]

    .B:                                                                                                             ; bxx
    Inc     PCX                                                                 ;PCX++
    Mov     AH,[PCX]                                                            ;AH = [PCX]
    And     AH,0DFh                                                             ;AH &= 0xDF
    Test    AH,AH                                                               ;AH = 0x00?
    JZ      .NORMALERROR                                                        ;   Yes

    Cmp     AH,50h                                                              ;Is char "P"?
    JE      .BP                                                                 ;   Yes
    Inc     PCX                                                                 ;PCX++
    Mov     AL,[PCX]                                                            ;AL = [PCX]
    And     AL,0DFh                                                             ;AL &= 0xDF
    Test    AL,AL                                                               ;AL = 0x00?
    JZ      .NORMALERROR                                                        ;   Yes

    Mov     DL,05h                                                              ;DL = 0x05
    Cmp     AX,5241h                                                            ;Is string "BRA"?                   ; bra
    JE      .BXXNEXT                                                            ;   Yes
    Inc     DL                                                                  ;DL++ (0x06)
    Cmp     AX,4551h                                                            ;Is string "BEQ"?                   ; beq
    JE      .BXXNEXT                                                            ;   Yes
    Inc     DL                                                                  ;DL++ (0x07)
    Cmp     AX,4E45h                                                            ;Is string "BNE"?                   ; bne
    JE      .BXXNEXT                                                            ;   Yes
    Inc     DL                                                                  ;DL++ (0x08)
    Cmp     AX,4745h                                                            ;Is string "BGE"?                   ; bge
    JE      .BXXNEXT                                                            ;   Yes
    Inc     DL                                                                  ;DL++ (0x09)
    Cmp     AX,4C45h                                                            ;Is string "BLE"?                   ; ble
    JE      .BXXNEXT                                                            ;   Yes
    Inc     DL                                                                  ;DL++ (0x0A)
    Cmp     AX,4754h                                                            ;Is string "BGT"?                   ; bgt
    JE      .BXXNEXT                                                            ;   Yes
    Inc     DL                                                                  ;DL++ (0x0B)
    Cmp     AX,4C54h                                                            ;Is string "BLT"?                   ; blt
    JE      .BXXNEXT                                                            ;   Yes
    Inc     DL                                                                  ;DL++ (0x0C)
    Cmp     AX,4343h                                                            ;Is string "BCC"?                   ; bcc
    JE      .BXXNEXT                                                            ;   Yes
    Inc     DL                                                                  ;DL++ (0x0D)
    Cmp     AX,4C4Fh                                                            ;Is string "BLO"?                   ; blo
    JE      .BXXNEXT                                                            ;   Yes
    Inc     DL                                                                  ;DL++ (0x0E)
    Cmp     AX,4849h                                                            ;Is string "BHI"?                   ; bhi
    JE      .BXXNEXT                                                            ;   Yes
    Inc     DL                                                                  ;DL++ (0x0F)
    Cmp     AX,4353h                                                            ;Is string "BCS"?                   ; bcs
    JE      .BXXNEXT                                                            ;   Yes
    Jmp     .NORMALERROR                                                        ;   No

    .BXXNEXT:
    Inc     PCX                                                                 ;PCX++
    Call    GetScript700Next                                                    ;Seek Next
    JZ      .NORMALERROR                                                        ;   Failure

    Mov     AL,[PCX]                                                            ;AL = [PCX]
    Cmp     AL,23h                                                              ;Is char "#"?
    JE      .BXXVALN                                                            ;   Yes
    And     AL,0DFh                                                             ;AL &= 0xDF
    Cmp     AL,57h                                                              ;Is char "W"?
    JE      .BXXVALW                                                            ;   Yes
    Dec     PCX                                                                 ;PCX--

    .BXXVALN:
    Inc     PCX                                                                 ;PCX++
    Call    GetScript700Number                                                  ;Parse Number (EAX = result)
    JZ      .NORMALERROR                                                        ;   Failure

    And     EAX,1023                                                            ;EAX &= 1023
    Mov     [PSI+PBX],DL                                                        ;Program[PBX] = DL
    Inc     PBX                                                                 ;PBX++
    Mov     [PSI+PBX],AX                                                        ;Program[PBX] = AX
    Add     PBX,2                                                               ;PBX += 2
    Jmp     .NORMALRETURN

    .BXXVALW:
    Inc     PCX                                                                 ;PCX++
    Call    GetScript700Number                                                  ;Parse Number (EAX = result)
    JZ      .NORMALERROR                                                        ;   Failure

    Mov     AH,80h                                                              ;AH = 0x80
    Mov     [PSI+PBX],DL                                                        ;Program[PBX] = DL
    Inc     PBX                                                                 ;PBX++
    Mov     [PSI+PBX],AX                                                        ;Program[PBX] = AX
    Add     PBX,2                                                               ;PBX += 2
    Jmp     .NORMALRETURN

    .BP:                                                                                                            ; bp
    Test    dword [apuCbMask],CBE_REQBP                                         ;Is supported callback?
    JZ      .NORMALERROR                                                        ;   No
    Test    PTRKW [apuCbFunc],-1                                                ;Is defined callback function?
    JZ      .NORMALERROR                                                        ;   No

    Mov     byte [PSI+PBX],18h                                                  ;Program[PBX] = 0x18
    Inc     PBX                                                                 ;PBX++
    Inc     PCX                                                                 ;PCX++
    Call    GetScript700Next                                                    ;Seek Next
    JZ      .NORMALERROR                                                        ;   Failure

    LoadPtr PAX,.NORMALRETURN                                                   ;Set Return Address
    Mov     [scr700jmp],PAX
    XOr     DH,DH                                                               ;DH = 0x00
    Jmp     .SETVAL

    .R:                                                                                                             ; r
    Inc     PCX                                                                 ;PCX++
    Mov     AL,[PCX]                                                            ;AL = [PCX]
    Cmp     AL,30h                                                              ;Is char "0"?
    JE      .R0                                                                 ;   Yes
    Cmp     AL,31h                                                              ;Is char "1"?
    JE      .R1                                                                 ;   Yes
    Dec     PCX                                                                 ;PCX--
    Call    GetScript700Last                                                    ;Check Last
    JZ      .NORMALERROR                                                        ;   Failure

    Mov     byte [PSI+PBX],10h                                                  ;Program[PBX] = 0x10
    Inc     PBX                                                                 ;PBX++
    Jmp     .NORMALRETURN

    .R0:                                                                                                            ; r0
    Call    GetScript700Last                                                    ;Check Last
    JZ      .NORMALERROR                                                        ;   Failure
    Mov     byte [PSI+PBX],11h                                                  ;Program[PBX] = 0x11
    Inc     PBX                                                                 ;PBX++
    Jmp     .NORMALRETURN

    .R1:                                                                                                            ; r1
    Call    GetScript700Last                                                    ;Check Last
    JZ      .NORMALERROR                                                        ;   Failure

    Mov     byte [PSI+PBX],12h                                                  ;Program[PBX] = 0x12
    Inc     PBX                                                                 ;PBX++
    Jmp     .NORMALRETURN

    .F:                                                                                                             ; f
    Inc     PCX                                                                 ;PCX++
    Mov     AL,[PCX]                                                            ;AL = [PCX]
    Cmp     AL,30h                                                              ;Is char "0"?
    JE      .F0                                                                 ;   Yes
    Cmp     AL,31h                                                              ;Is char "1"?
    JE      .F1                                                                 ;   Yes
    Dec     PCX                                                                 ;PCX--
    Call    GetScript700Last                                                    ;Check Last
    JZ      .NORMALERROR                                                        ;   Failure

    Mov     byte [PSI+PBX],13h                                                  ;Program[PBX] = 0x13
    Inc     PBX                                                                 ;PBX++
    Jmp     .NORMALRETURN

    .F0:                                                                                                            ; f0
    Call    GetScript700Last                                                    ;Check Last
    JZ      .NORMALERROR                                                        ;   Failure

    Mov     byte [PSI+PBX],14h                                                  ;Program[PBX] = 0x14
    Inc     PBX                                                                 ;PBX++
    Jmp     .NORMALRETURN

    .F1:                                                                                                            ; f1
    Call    GetScript700Last                                                    ;Check Last
    JZ      .NORMALERROR                                                        ;   Failure

    Mov     byte [PSI+PBX],15h                                                  ;Program[PBX] = 0x15
    Inc     PBX                                                                 ;PBX++
    Jmp     .NORMALRETURN

    .Shp:                                                                                                           ; #
    Test    dword [apuCbMask],CBE_INCS700 | CBE_INCDATA                         ;Is supported callback?
    JZ      .ShpERROR                                                           ;   No
    Test    PTRKW [apuCbFunc],-1                                                ;Is defined callback function?
    JZ      .ShpERROR                                                           ;   No

    Inc     PCX                                                                 ;PCX++
    Mov     AL,[PCX]                                                            ;AL = [PCX]
    And     AL,0DFh                                                             ;AL &= 0xDF
    Cmp     AL,49h                                                              ;Is char "I"?                       ; #i
    JE      .ShpI                                                               ;   Yes
    Jmp     .ShpERROR                                                           ;   No

    .ShpI:
    Inc     PCX                                                                 ;PCX++
    Mov     DL,40h                                                              ;DL = 0x40 (TEXT mode)
    Mov     AL,[PCX]                                                            ;AL = [PCX]
    Cmp     AL,09h                                                              ;AL = 0x09? (TAB)
    JE      .ShpI1                                                              ;   Yes
    Cmp     AL,20h                                                              ;AL = 0x20? (SPACE)
    JE      .ShpI1                                                              ;   Yes

    And     AL,0DFh                                                             ;AL &= 0xDF
    Cmp     AL,54h                                                              ;Is char "T"?                       ; #it
    JE      .ShpIT                                                              ;   Yes

    Test    byte [scr700inc+03h],02h                                            ;Data Command Zone?
    JZ      .ShpERROR                                                           ;   No
    Mov     DL,20h                                                              ;DL = 0x20 (DATA mode)
    Cmp     AL,42h                                                              ;Is char "B"?                       ; #ib
    JE      .ShpIB                                                              ;   Yes
    Jmp     .ShpERROR                                                           ;   No

    .ShpIT:
    Inc     PCX                                                                 ;PCX++

    .ShpI1:
    Test    byte [scr700inc+02h],-1                                             ;Include mode?
    JNZ     .ShpERROR                                                           ;   Yes
    Jmp     .ShpI2

    .ShpIB:
    Inc     PCX                                                                 ;PCX++

    .ShpI2:
    Call    GetScript700Next                                                    ;Seek Next
    JZ      .ShpERROR                                                           ;   Failure
    Mov     AL,[PCX]                                                            ;AL = [PCX]
    Cmp     AL,22h                                                              ;Is char "\""?
    JNE     .ShpERROR                                                           ;   No

    Mov     [scr700inc],DL                                                      ;Include = 00h:NEW
    Inc     PCX                                                                 ;PCX++

    Push    PDI,PCX
    LoadPtr PDI,scr700pth
    XOr     EAX,EAX
    Mov     PCX,64
    Rep     StoSD
    Pop     PCX,PDI

    LoadPtr PDX,scr700pth

    .ShpI3:
    Mov     AL,[PCX]                                                            ;AL = [PCX]
    Cmp     AL,00h                                                              ;Is char NULL?
    JE      .ShpERROR                                                           ;   Yes
    Cmp     AL,0Ah                                                              ;Is char RETURN?
    JE      .ShpERROR                                                           ;   Yes
    Cmp     AL,0Dh                                                              ;Is char RETURN?
    JE      .ShpERROR                                                           ;   Yes
    Cmp     AL,22h                                                              ;Is char "\""?
    JE      .ShpI4                                                              ;   Yes

    Inc     AH
    JZ      .ShpERROR
    Mov     [PDX],AL                                                            ;Path[PDX] = AL
    Inc     PDX                                                                 ;PDX++
    Inc     PCX                                                                 ;PCX++
    Jmp     .ShpI3

    .ShpI4:
    IdxSt   Mov,scr700inc,04h,EBX                                               ;Save program cursor
    Inc     EBX                                                                 ;PBX++
    IdxSt   Mov,scr700inc,08h,EBX                                               ;Store pointer of successful for not call SetScript700

    MovZX   EDX,byte [scr700inc]                                                ;Include = 02h:OLD 01h:00h 00h:NEW
    ShR     word [scr700inc+01h],8                                              ;          02h:00h 01h:OLD 00h:NEW
    Mov     [scr700inc+02h],DL                                                  ;          02h:NEW 01h:OLD 00h:NEW
                                                                                ;EDX = 0x40 (TEXT) or 0x20 (DATA)
    ShL     EDX,24                                                              ;EDX << 24 (0x40000000 or 0x20000000)
    Test    dword [apuCbMask],EDX                                               ;Is supported callback?
    JZ      .ShpERROR                                                           ;   No

    Push    PDI,PBX,PCX                                                         ;STDCALL is destroy PAX,PCX,PDX
    Mov     PDI,[apuCbFunc]
    Mov     ECX,[scr700dat]
    Sub     PBX,PCX
    MovZX   EAX,AH                                                              ;EAX = Size of file name
    LoadPtr PCX,scr700pth                                                       ;PCX = Pointer of file name
    ExtCall PDI,EDX,PBX,EAX,PCX
    Pop     PCX,PBX,PDI

    ShL     word [scr700inc+01h],8                                              ;Include = 02h:OLD 01h:00h 00h:NEW

    IdxLd   Mov,EDX,scr700inc,08h                                               ;EDX = Return value of SetScript700
    Test    EDX,EDX                                                             ;EDX = ?
    JS      .CRITICALERROR                                                      ;   < 0
    JZ      .ShpEXIT                                                            ;   = 0
        Mov     EBX,EDX                                                         ;PBX = EDX

    .ShpEXIT:
    Dec     PBX                                                                 ;PBX--
    Call    GetScript700Last                                                    ;Check Last
    JZ      .ShpERROR                                                           ;   Failure
    Mov     AH,[scr700inc+03h]
    Dec     AH
    JZ      .EXTRETURN
    Dec     AH
    JZ      .DATARETURN2
    Jmp     .NORMALRETURN

    .ShpERROR:
    Mov     AH,[scr700inc+03h]
    Dec     AH
    JZ      .EXTERROR
    Dec     AH
    JZ      .DATAERROR

    .NORMALERROR:
    Mov     PBX,PDI                                                             ;PBX = PDI
    Test    byte [PCX],-1                                                       ;Is char NULL?
    JZ      .EXIT                                                               ;   Yes
    Call    GetScript700NextLine                                                ;Next Line
    Jmp     .NORMALRETURN

    ;---------- Extension Command Zone ----------

    .EXTRETURN:

    ;NOTE (amd64 port): every '[array+reg]' access in the Extension Command Zone below (on the
    ; scr700dsp/scr700chg/scr700det/scr700vol arrays) uses IdxSt/IdxLd, which load their own scratch
    ; base pointer per access -- PSI/PDI keep their usual meaning (PSI = script RAM pointer) throughout,
    ; unlike the array accesses elsewhere in this proc that still address off PSI/PBX/PDI directly.

    Call    GetScript700First                                                   ;Seek First
    JZ      .EXTERROR                                                           ;   Failure
    Mov     AL,[PCX]                                                            ;AL = [PCX]
    Cmp     AL,3Ah                                                              ;Is char ":"?
    JE      .EXLABEL                                                            ;   Yes
    Cmp     AL,23h                                                              ;Is char "#"?
    JE      .Shp                                                                ;   Yes
    And     AL,0DFh                                                             ;AL &= 0xDF
    Cmp     AL,45h                                                              ;Is char "E"?
    JE      .EXE                                                                ;   Yes
    Cmp     AL,4Dh                                                              ;Is char "M"?
    JE      .EXM                                                                ;   Yes
    Cmp     AL,43h                                                              ;Is char "C"?
    JE      .EXC                                                                ;   Yes
    Cmp     AL,44h                                                              ;Is char "D"?
    JE      .EXD                                                                ;   Yes
    Cmp     AL,56h                                                              ;Is char "V"?
    JE      .EXV                                                                ;   Yes
    Jmp     .EXTERROR                                                           ;   No

    .EXLABEL:                                                                                                       ; ::
    Inc     PCX                                                                 ;PCX++
    Mov     AL,[PCX]                                                            ;AL = [PCX]
    Cmp     AL,3Ah                                                              ;Is char ":"?
    JNE     .EXTERROR                                                           ;   No

    Call    GetScript700Last                                                    ;Check Last
    JZ      .EXTERROR                                                           ;   Failure
    Jmp     .EXTRETURN

    .EXE:                                                                                                           ; e
    Call    GetScript700Last                                                    ;Check Last
    JZ      .EXTERROR                                                           ;   Failure

    Mov     byte [scr700inc+03h],02h                                            ;Data Command Zone
    Jmp     .DATARETURN

    .EXM:                                                                                                           ; m
    Inc     PCX                                                                 ;PCX++
    Call    GetScript700Next                                                    ;Seek Next
    JZ      .EXTERROR                                                           ;   Failure

    Mov     AL,[PCX]                                                            ;AL = [PCX]
    Cmp     AL,21h                                                              ;Is char "!"?
    JE      .EXMALL                                                             ;   Yes
    Call    GetScript700Number                                                  ;Parse Number (EAX = result)
    JZ      .EXTERROR                                                           ;   Failure

    MovZX   EAX,AL                                                              ;EAX = AL
    IdxSt   XOr byte,scr700dsp,PAX,01h                                          ;pDSPFlag[EAX] ^= 0x01
    Jmp     .EXTRETURN

    .EXMALL:                                                                                                        ; !
    Call    GetScript700Last                                                    ;Check Last
    JZ      .EXTERROR                                                           ;   Failure
    XOr     EDX,EDX                                                             ;EDX = 0x00

    .EXMALLRETURN:
    IdxSt   XOr dword,scr700dsp,PDX,01010101h                                   ;pDSPFlag[EDX] ^= 0x01010101
    Add     EDX,4                                                               ;EDX += 4
    Cmp     EDX,256                                                             ;EDX = 256?
    JNE     .EXMALLRETURN                                                       ;   No
    Jmp     .EXTRETURN

    .EXC:                                                                                                           ; c
    Inc     PCX                                                                 ;PCX++
    Call    GetScript700Next                                                    ;Seek Next
    JZ      .EXTERROR                                                           ;   Failure

    Mov     AL,[PCX]                                                            ;AL = [PCX]
    Cmp     AL,21h                                                              ;Is char "!"?
    JE      .EXCALL                                                             ;   Yes
    Call    GetScript700Number                                                  ;Parse Number (EAX = result)
    JZ      .EXTERROR                                                           ;   Failure

    Mov     DL,AL                                                               ;DL = AL
    Call    GetScript700Next                                                    ;Seek Next
    JZ      .EXTERROR                                                           ;   Failure
    Call    GetScript700Number                                                  ;Parse Number (EAX = result)
    JZ      .EXTERROR                                                           ;   Failure

    MovZX   EDX,DL                                                              ;EDX = DL
    IdxSt   Or byte,scr700dsp,PDX,02h                                           ;pDSPFlag[EDX] |= 0x02
    IdxSt   Mov,scr700chg,PDX,AL                                                ;pDSPChange[EDX] = AL
    Jmp     .EXTRETURN

    .EXCALL:                                                                                                        ; !
    Inc     PCX                                                                 ;PCX++
    Call    GetScript700Next                                                    ;Seek Next
    JZ      .EXTERROR                                                           ;   Failure
    Call    GetScript700Number                                                  ;Parse Number (EAX = result)
    JZ      .EXTERROR                                                           ;   Failure
    XOr     EDX,EDX                                                             ;EDX = 0x00

    .EXCALLRETURN:
    IdxSt   Or dword,scr700dsp,PDX,02020202h                                    ;pDSPFlag[EDX] |= 0x02020202
    IdxSt   Mov,scr700chg,PDX+0,AL                                              ;pDSPChange[EDX+0] = AL
    IdxSt   Mov,scr700chg,PDX+1,AL                                              ;pDSPChange[EDX+1] = AL
    IdxSt   Mov,scr700chg,PDX+2,AL                                              ;pDSPChange[EDX+2] = AL
    IdxSt   Mov,scr700chg,PDX+3,AL                                              ;pDSPChange[EDX+3] = AL
    Add     EDX,4                                                               ;EDX += 4
    Cmp     EDX,256                                                             ;EDX = 256?
    JNE     .EXCALLRETURN                                                       ;   No
    Jmp     .EXTRETURN

    .EXD:                                                                                                           ; d
    Inc     PCX                                                                 ;PCX++
    Call    GetScript700Next                                                    ;Seek Next
    JZ      .EXTERROR                                                           ;   Failure

    Mov     AL,[PCX]                                                            ;AL = [PCX]
    Cmp     AL,21h                                                              ;Is char "!"?
    JE      .EXDALL                                                             ;   Yes
    Call    GetScript700Number                                                  ;Parse Number (EAX = result)
    JZ      .EXTERROR                                                           ;   Failure

    Mov     DL,AL                                                               ;DL = AL
    Call    GetScript700Next                                                    ;Seek Next
    JZ      .EXTERROR                                                           ;   Failure
    Call    GetScript700Number                                                  ;Parse Number (EAX = result)
    JZ      .EXTERROR                                                           ;   Failure

    MovZX   EDX,DL                                                              ;EDX = DL
    IdxSt   Or byte,scr700dsp,PDX,04h                                           ;pDSPFlag[EDX] |= 0x04
    IdxSt   Mov,scr700det,PDX*4,EAX                                             ;pDSPDetune[EDX] = EAX
    Jmp     .EXTRETURN

    .EXDALL:                                                                                                        ; !
    Inc     PCX                                                                 ;PCX++
    Call    GetScript700Next                                                    ;Seek Next
    JZ      .EXTERROR                                                           ;   Failure
    Call    GetScript700Number                                                  ;Parse Number (EAX = result)
    JZ      .EXTERROR                                                           ;   Failure
    XOr     EDX,EDX                                                             ;EDX = 0x00

    .EXDALLRETURN:
    IdxSt   Or dword,scr700dsp,PDX,04040404h                                    ;pDSPFlag[EDX] |= 0x04040404
    IdxSt   Mov,scr700det,PDX*4+0,EAX                                           ;pDSPDetune[EDX+0] = EAX
    IdxSt   Mov,scr700det,PDX*4+4,EAX                                           ;pDSPDetune[EDX+1] = EAX
    IdxSt   Mov,scr700det,PDX*4+8,EAX                                           ;pDSPDetune[EDX+2] = EAX
    IdxSt   Mov,scr700det,PDX*4+12,EAX                                          ;pDSPDetune[EDX+3] = EAX
    Add     EDX,4                                                               ;EDX += 4
    Cmp     EDX,256                                                             ;EDX = 256?
    JNE     .EXDALLRETURN                                                       ;   No
    Jmp     .EXTRETURN

    .EXV:                                                                                                           ; v
    Inc     PCX                                                                 ;PCX++
    Call    GetScript700Next                                                    ;Seek Next
    JZ      .EXTERROR                                                           ;   Failure

    XOr     DH,DH                                                               ;DH = 0x00
    Mov     AL,[PCX]                                                            ;AL = [PCX]
    Inc     PCX                                                                 ;PCX++
    Cmp     AL,21h                                                              ;Is char "!"?
    JE      .EXVALL                                                             ;   Yes
    And     AL,0DFh                                                             ;AL &= 0xDF
    Cmp     AL,56h                                                              ;Is char "V"?
    JE      .EXVV                                                               ;   Yes
    Cmp     AL,45h                                                              ;Is char "E"?
    JE      .EXVE                                                               ;   Yes
    Mov     DL,S700_MVOL_L                                                      ;DL = MasterVolumeLeft
    Cmp     AL,4Ch                                                              ;Is char "L"?
    JE      .EXVL                                                               ;   Yes
    Mov     DL,S700_MVOL_R                                                      ;DL = MasterVolumeRight
    Cmp     AL,52h                                                              ;Is char "R"?
    JE      .EXVR                                                               ;   Yes
    Dec     PCX                                                                 ;PCX--
    Call    GetScript700Number                                                  ;Parse Number (EAX = result)
    JZ      .EXTERROR                                                           ;   Failure

    MovZX   DX,AL                                                               ;DL = AL, DH = 0x00
    LoadPtr PAX,.EXTRETURN                                                      ;Set Return Address
    Mov     [scr700jmp],PAX

    .ENVSET:
    ShL     EDX,16                                                              ;EDX << 16
    Call    GetScript700Next                                                    ;Seek Next
    JZ      .EXTERROR                                                           ;   Failure
    Call    GetScript700Number                                                  ;Parse Number (EAX = result)
    JZ      .EXTERROR                                                           ;   Failure

    Push    PDX                                                                 ;(width fix only, not a pointer)
    XOr     EDX,EDX                                                             ;EDX = 0
    Test    EAX,EAX                                                             ;If EAX < 0
    SetS    DL                                                                  ;   Yes, EDX = 1
    Dec     EDX                                                                 ;EDX--
    And     EAX,EDX                                                             ;EAX &= EDX
    Pop     PDX                                                                 ;(width fix only, not a pointer)
    ShR     EDX,16                                                              ;EDX >> 16
    IdxSt   Or byte,scr700dsp,PDX,08h                                           ;pDSPFlag[EDX] |= 0x08
    IdxSt   Mov,scr700vol,PDX*4,EAX                                             ;pDSPVolume[EDX] = EAX
    Jmp     [scr700jmp]

    .EXVL:
    Mov     AL,[PCX]                                                            ;AL = [PCX]
    And     AL,0DFh                                                             ;AL &= 0xDF
    Cmp     AL,52h                                                              ;Is char "R"?
    JE      .EXVLR                                                              ;   Yes

    .EXVR:
    Inc     DH                                                                  ;DH++
    LoadPtr PAX,.EXVLR3                                                         ;Set Return Address
    Mov     [scr700jmp],PAX
    Jmp     .ENVSET

    .EXVLR:
    Inc     PCX                                                                 ;PCX++
    Inc     DH                                                                  ;DH++
    LoadPtr PAX,.EXVLR2                                                         ;Set Return Address
    Mov     [scr700jmp],PAX
    Jmp     .ENVSET

    .EXVLR2:
    IdxSt   Or dword,scr700dsp,PDX,08080808h                                    ;pDSPFlag[EDX] |= 0x08080808
    IdxSt   Mov,scr700vol,PDX*4+4,EAX                                           ;pDSPVolume[EDX+1] = EAX
    IdxSt   Mov,scr700vol,PDX*4+12,EAX                                          ;pDSPVolume[EDX+3] = EAX

    .EXVLR3:
    IdxSt   Or byte,scr700dsp,PDX+2,08h                                         ;pDSPFlag[EDX+2] |= 0x08
    IdxSt   Mov,scr700vol,PDX*4+8,EAX                                           ;pDSPVolume[EDX+2] = EAX
    Jmp     .EXTRETURN

    .EXVALL:
    Call    GetScript700Next                                                    ;Seek Next
    JZ      .EXTERROR                                                           ;   Failure
    Call    GetScript700Number                                                  ;Parse Number (EAX = result)
    JZ      .EXTERROR                                                           ;   Failure

    XOr     EDX,EDX                                                             ;EDX = 0
    Test    EAX,EAX                                                             ;If EAX < 0
    SetS    DL                                                                  ;   Yes, EDX = 1
    Dec     EDX                                                                 ;EDX--
    And     EAX,EDX                                                             ;EAX &= EDX
    XOr     EDX,EDX

    .EXVALLRETURN:
    IdxSt   Or dword,scr700dsp,PDX,08080808h                                    ;pDSPFlag[EDX] |= 0x08080808
    IdxSt   Mov,scr700vol,PDX*4+0,EAX                                           ;pDSPVolume[EDX+0] = EAX
    IdxSt   Mov,scr700vol,PDX*4+4,EAX                                           ;pDSPVolume[EDX+1] = EAX
    IdxSt   Mov,scr700vol,PDX*4+8,EAX                                           ;pDSPVolume[EDX+2] = EAX
    IdxSt   Mov,scr700vol,PDX*4+12,EAX                                          ;pDSPVolume[EDX+3] = EAX
    Add     EDX,4                                                               ;EDX += 4
    Cmp     EDX,256                                                             ;EDX = 256?
    JNE     .EXVALLRETURN                                                       ;   No
    Jmp     .EXTRETURN

    .EXVV:
    Mov     AL,[PCX]                                                            ;AL = [PCX]
    And     AL,0DFh                                                             ;AL &= 0xDF
    Mov     DL,S700_MVOL_L                                                      ;DL = MasterVolumeLeft
    Cmp     AL,4Ch                                                              ;Is char "L"?
    JE      .EXVCMD                                                             ;   Yes
    Mov     DL,S700_MVOL_R                                                      ;DL = MasterVolumeRight
    Cmp     AL,52h                                                              ;Is char "R"?
    JE      .EXVCMD                                                             ;   Yes
    Jmp     .EXTERROR

    .EXVE:
    Mov     AL,[PCX]                                                            ;AL = [PCX]
    And     AL,0DFh                                                             ;AL &= 0xDF
    Mov     DL,S700_ECHO_L                                                      ;DL = EchoVolumeLeft
    Cmp     AL,4Ch                                                              ;Is char "L"?
    JE      .EXVCMD                                                             ;   Yes
    Mov     DL,S700_ECHO_R                                                      ;DL = EchoVolumeRight
    Cmp     AL,52h                                                              ;Is char "R"?
    JE      .EXVCMD                                                             ;   Yes
    Jmp     .EXTERROR

    .EXVCMD:
    Inc     PCX                                                                 ;PCX++
    Inc     DH                                                                  ;DH++
    LoadPtr PAX,.EXTRETURN                                                      ;Set Return Address
    Mov     [scr700jmp],PAX
    Jmp     .ENVSET

    .EXTERROR:
    Test    byte [PCX],-1                                                       ;Is char NULL?
    JZ      .EXIT                                                               ;   Yes
    Call    GetScript700NextLine                                                ;Next Line
    Jmp     .EXTRETURN

    ;---------- Data Command Zone ----------

    .DATARETURN:
    XOr     AH,AH                                                               ;AH = 0x00
    Mov     PDI,PBX                                                             ;PDI = PBX
    Mov     [PSI+PBX],AH                                                        ;Program[PBX] = AH
    Mov     [scr700dat],EBX                                                     ;Data Offset = PBX
    Inc     dword [scr700dat]                                                   ;Data Offset++
    Call    GetScript700First                                                   ;Seek First

    .DATARETURN2:
    Mov     DL,AH                                                               ;DL = AH (0x00)

    .DATARETURNLINE:
    Mov     AL,[PCX]                                                            ;AL = [PCX]
    Cmp     AL,00h                                                              ;AL = 0x00?
    JE      .EXIT                                                               ;   Yes
    Cmp     AL,3Ah                                                              ;Is char ":"?
    JE      .DATALABEL                                                          ;   Yes
    Cmp     AL,23h                                                              ;Is char "#"?
    JE      .Shp                                                                ;   Yes
    Inc     PCX                                                                 ;PCX++
    Cmp     AL,0Ah                                                              ;Is char RETURN?
    JE      .DATANEWLINE                                                        ;   Yes
    Cmp     AL,0Dh                                                              ;Is char RETURN?
    JE      .DATANEWLINE                                                        ;   Yes
    Cmp     AL,09h                                                              ;AL = 0x09? (TAB)
    JE      .DATARETURNLINE                                                     ;   Yes
    Cmp     AL,20h                                                              ;AL = 0x20? (SPACE)
    JE      .DATARETURNLINE                                                     ;   Yes
    Sub     AL,30h                                                              ;AL -= 0x30
    Cmp     AL,10                                                               ;AL < 10? (Is char "0" to "9"?)
    JB      .DATANUM                                                            ;   Yes
    Sub     AL,11h                                                              ;AL -= 0x11 (0x41)
    Cmp     AL,6                                                                ;AL < 6? (Is char "A" to "F"?)
    JB      .DATAHEX                                                            ;   Yes
    Sub     AL,20h                                                              ;AL -= 0x20 (0x61)
    Cmp     AL,6                                                                ;AL < 6? (Is not char "a" to "f"?)
    JB      .DATAHEX                                                            ;   Yes
    Dec     PCX                                                                 ;PCX--
    Call    GetScript700NextLine                                                ;Next Line
    Jmp     .DATARETURNLINE

    .DATALABEL:
    Inc     PCX                                                                 ;PCX++
    Mov     AL,[PCX]                                                            ;AL = [PCX]
    Call    GetScript700Number                                                  ;Parse Number (EAX = result)        ; :[LABEL]
    JZ      .DATAERROR                                                          ;   Failure

    And     EAX,1023                                                            ;EAX &= 1023
    Mov     EDX,EBX                                                             ;EDX = PBX
    Sub     EDX,[scr700dat]                                                     ;EDX -= Data Offset
    Inc     EDX                                                                 ;EDX++
    Or      EDX,80000000h                                                       ;EDX |= 0x80000000
    IdxSt   Mov,scr700lbl,PAX*4,EDX                                             ;Label[EAX] = EDX

    .DATANEWLINE:
    XOr     AH,AH                                                               ;AH = 0x00
    Jmp     .DATARETURN2

    .DATAHEX:
    Add     AL,10                                                               ;AL += 10

    .DATANUM:
    Dec     DL                                                                  ;DL-- (DL = 0x00?)
    JZ      .DATANUM2                                                           ;   Yes

    ShL     AX,12                                                               ;AX << 12 (Mov AH,AL; ShL AH,4)
    Add     DL,2                                                                ;DL += 2
    Jmp     .DATARETURNLINE

    .DATANUM2:
    Or      AH,AL                                                               ;AH |= AL
    Inc     PBX                                                                 ;PBX++
    And     PBX,SCR700MASK                                                      ;PBX &= Program Mask
    Cmp     PBX,PDI                                                             ;PBX < PDI?
    JB      .CRITICALERROR                                                      ;   Yes

    Mov     [PSI+PBX],AH                                                        ;Program[PBX] = AH
    Mov     PDI,PBX                                                             ;PDI = PBX
    Jmp     .DATARETURNLINE

    .DATAERROR:
    Test    byte [PCX],-1                                                       ;Is char NULL?
    JZ      .EXIT                                                               ;   Yes
    Call    GetScript700NextLine                                                ;Next Line
    XOr     AH,AH                                                               ;AH = 0x00
    Jmp     .DATARETURN2

    ;---------- Error ----------

    .CRITICALERROR:
    XOr     EAX,EAX                                                             ;EAX = 0x00
    Test    byte [scr700inc+02h],-1                                             ;Include mode?
    JNZ     .NORESET                                                            ;   Yes
        Mov     [PSI],AL                                                        ;Program[0] = AL

    .NORESET:
    Test    PCX,PCX                                                             ;PCX = NULL?
    SetZ    AL                                                                  ;AL = Zero?
    Dec     EAX                                                                 ;EAX--
    Jmp     .FINALIZE

    ;---------- Finalize ----------

    .EXIT:
    Mov     EAX,EBX                                                             ;EAX = PBX
    Inc     EAX                                                                 ;EAX++
    Test    byte [scr700inc+02h],-1                                             ;Include mode?
    JNZ     .FINALIZE                                                           ;   Yes

    Mov     ECX,[scr700dat]                                                     ;ECX = Data Offset
    Test    ECX,ECX                                                             ;ECX = 0x00?
    JNZ     .FINALIZE                                                           ;   No

    Mov     [PSI+PBX],CL                                                        ;Program[PBX] = CL
    Mov     [scr700dat],EAX                                                     ;Data Offset = EAX

    .FINALIZE:
    IdxSt   Mov,scr700inc,08h,EAX

ENDP


;===================================================================================================
;Set Script700 Binary Data Function

EXPROC SetScript700Data, addr, pData, size

    Mov     PAX,[pData]                                                         ;PAX = Data Pointer
    Test    PAX,PAX                                                             ;PAX = NULL?
    JZ      .FINALIZE                                                           ;   Yes

    Mov     EAX,[scr700dat]                                                     ;EAX = Data Offset
    Add     EAX,[addr]                                                          ;EAX += addr, is overflow?
    JO      .CRITICALERROR                                                      ;   Yes
    Add     EAX,[size]                                                          ;EAX += size, is overflow?
    JO      .CRITICALERROR                                                      ;   Yes
    Cmp     EAX,SCR700SIZE                                                      ;EAX > Buffer Size?
    JG      .CRITICALERROR                                                      ;   Yes

    Push    PDI,PSI,PCX

    Mov     PDI,[pSCRRAM]                                                       ;PDI = Script RAM Pointer
    Mov     EAX,[scr700dat]                                                     ;PDI += Data Offset
    Add     PDI,PAX
    Mov     EAX,[addr]                                                          ;PDI += addr
    Add     PDI,PAX
    Mov     PSI,[pData]                                                         ;PSI = Data Pointer

    Mov     ECX,[size]                                                          ;ECX = size
    ShR     ECX,2                                                               ;ECX >> 2
    Rep     MovSD                                                               ;memcpy(EDI, ESI, ECX*4)

    Mov     ECX,[size]                                                          ;ECX = size
    And     ECX,3                                                               ;ECX &= 3
    Rep     MovSB                                                               ;memcpy(EDI, ESI, ECX)

    Mov     PAX,PDI                                                             ;PAX = PDI (RAM Pointer + DataOffset + addr + size)
    Sub     PAX,[pSCRRAM]                                                       ;PAX -= Script RAM Pointer

    Pop     PCX,PSI,PDI
    Jmp     .FINALIZE

    .CRITICALERROR:
    XOr     EAX,EAX                                                             ;EAX = 0x00
    Dec     EAX                                                                 ;EAX--

    .FINALIZE:
    IdxSt   Mov,scr700inc,08h,EAX

ENDP


;===================================================================================================
;Get SNESAPU Context Buffer Size Function

EXPROC GetSNESAPUContextSize
USES ECX

    XOr     EAX,EAX

    LoadPtr PCX,apuVarEP                                                        ;PCX = Variable size of APU.asm
    LblOp   Sub,PCX,apuRAMBuf
    And     ECX,0FFFFFFFCh
    Add     ECX,4

    Add     EAX,ECX                                                             ;EAX += ECX

    LoadPtr PCX,dspVarEP                                                        ;PCX = Variable size of DSP.asm
    LblOp   Sub,PCX,mix
    And     ECX,0FFFFFFFCh
    Add     ECX,4

    Add     EAX,ECX                                                             ;EAX += ECX

    LoadPtr PCX,spcVarEP                                                        ;PCX = Variable size of SPC700.asm
    LblOp   Sub,PCX,extraRAM
    And     ECX,0FFFFFFFCh
    Add     ECX,4

    Add     EAX,ECX                                                             ;EAX += ECX

ENDP


;===================================================================================================
;Get SNESAPU Context Data Function

EXPROC GetSNESAPUContext, pCtxOut
USES ECX,ESI,EDI

    Mov     PDI,[pCtxOut]

    LoadPtr PCX,apuVarEP                                                        ;PCX = Variable size of APU.asm
    LblOp   Sub,PCX,apuRAMBuf
    ShR     ECX,2
    Inc     ECX

    LoadPtr PSI,apuRAMBuf                                                       ;memcpy(&EDI, &apuRAMBuf, ECX*4)
    Rep     MovSD

    LoadPtr PCX,dspVarEP                                                        ;PCX = Variable size of DSP.asm
    LblOp   Sub,PCX,mix
    ShR     ECX,2
    Inc     ECX

    LoadPtr PSI,mix                                                             ;memcpy(&EDI, &mix, ECX*4)
    Rep     MovSD

    LoadPtr PCX,spcVarEP                                                        ;PCX = Variable size of SPC700.asm
    LblOp   Sub,PCX,extraRAM
    ShR     ECX,2
    Inc     ECX

    LoadPtr PSI,extraRAM                                                        ;memcpy(&EDI, &extraRAM, ECX*4)
    Rep     MovSD

    XOr     EAX,EAX

ENDP


;===================================================================================================
;Set SNESAPU Context Data Function

EXPROC SetSNESAPUContext, pCtxIn
USES ECX,ESI,EDI

    Mov     PSI,[pCtxIn]

    LoadPtr PCX,apuVarEP                                                        ;PCX = Variable size of APU.asm
    LblOp   Sub,PCX,apuRAMBuf
    ShR     ECX,2
    Inc     ECX

    LoadPtr PDI,apuRAMBuf                                                       ;memcpy(&apuRAMBuf, &ESI, ECX*4)
    Rep     MovSD

    LoadPtr PCX,dspVarEP                                                        ;PCX = Variable size of DSP.asm
    LblOp   Sub,PCX,mix
    ShR     ECX,2
    Inc     ECX

    LoadPtr PDI,mix                                                             ;memcpy(&mix, &ESI, ECX*4)
    Rep     MovSD

    LoadPtr PCX,spcVarEP                                                        ;PCX = Variable size of SPC700.asm
    LblOp   Sub,PCX,extraRAM
    ShR     ECX,2
    Inc     ECX

    LoadPtr PDI,extraRAM                                                        ;memcpy(&extraRAM, &ESI, ECX*4)
    Rep     MovSD

    XOr     EAX,EAX

ENDP
