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
;   - degrade-factory in 2026-10-15
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

EXPROC InitAPU, reason
USES ECX,EDX,EDI

    ;NOTE (x64 port): InitAPU is not listed in SNESAPU.def, but Pascal calls it directly, crossing
    ; the DLL boundary like an export, so it needs EXPROC.  Without EXPROC, RCX is not homed and
    ; [reason] reads stack garbage.  This was found when reason came out non-1, skipping InitAPU's
    ; body, leaving pAPURAM zeroed, and crashing ResetSPC's 'Rep StoSD' on a NULL PDI.
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
        Mov     ECX,[PBX]                                                       ;ECX = Size of the caller's structure, including this field
        Sub     ECX,2*PTRSIZE                                                   ;Does it reach past the work memory pointer?
        JL      .ppScript700Next                                                ;   No

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

    Add     PSI,100h                                                            ;memcpy(&apuRAM, &spc[100h], 10000h)
    Mov     PDI,[pAPURAM]
    Mov     ECX,4000h
    Rep     MovSD

    LoadPtr PDI,dsp                                                             ;memcpy(&dsp, &spc[10100h], 128)
    Mov     ECX,32
    Rep     MovSD

    Add     PSI,40h                                                             ;memcpy(&xram, &spc[101C0h], 64)
    LoadPtr PDI,extraRAM
    Mov     ECX,16
    Rep     MovSD

    ;NOTE: Extract each SPC register from the file and zero-extend it to a dword-sized local before
    ; handing them to 'Call FixAPUI'.  Call's argument marshaling always reads and writes a full 32
    ; bits per slot, so passing a raw byte or word memory reference directly, e.g. '[27h+PSI]',
    ; would read 2 to 3 extra bytes of meaningful file data past the field.  These locals are
    ; dedicated 4-byte scratch, so a full-width read back out of them is safe.

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
    Mov     ECX,[numChnI]
    Cmp     ECX,-1
    JE      .DefChn
        Mov     AL,CL

        Cmp     ECX,1
        JE      .OKChn
        Cmp     ECX,2
        JE      .OKChn

        Mov     AL,2

        .OKChn:
        Cmp     AL,[rawChn]                                                     ;Discard the samples kept in outBuf only when the
        JE      .DefChn                                                         ; output format changes
        Mov     [outCur],EDX
        Mov     [outLen],EDX

    .DefChn:
    Mov     [rawChn],AL

    ;bits ------------------------------------
    Mov     CL,[rawBits]
    Mov     EAX,[bitsI]
    Cmp     EAX,-1
    JE      .DefBits
        Mov     CL,AL

        Cmp     EAX,8
        JE      .OKBits
        Cmp     EAX,16
        JE      .OKBits
        Cmp     EAX,24
        JE      .OKBits
        Cmp     EAX,32
        JE      .OKBits
        Cmp     EAX,-32
        JE      .OKBits

        Mov     CL,16

        .OKBits:
        Cmp     CL,[rawBits]                                                    ;Discard the samples kept in outBuf only when the
        JE      .DefBits                                                        ; output format changes
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

    MovZX   EAX,byte [rawChn]                                                   ;Not AL, the bits block above reused it
    MovZX   ECX,CL
    Mul     ECX
    ShR     AL,3
    Mov     [rawByte],AL

    ;rate ------------------------------------
    Mov     EAX,[rawRate]
    Mov     EDX,[rateI]
    Cmp     EDX,-1
    CMovX   NE,EAX,EDX                                                          ;If EDX = -1, use the current rate

    XOr     ECX,ECX                                                             ;Range check before the comparison with rawRate below,
    Cmp     EAX,8000                                                            ; so an invalid rate is not seen as a change every time
    SetB    CL
    Cmp     EAX,192000
    SetA    CH
    Test    ECX,ECX
    Mov     EDX,32000
    CMovX   NZ,EAX,EDX
    Mov     [rateI],EAX

    ;opts ------------------------------------
    Mov     EAX,[dspOpts]
    Mov     EDX,[optsI]
    Cmp     EDX,-1
    CMovX   NE,EAX,EDX                                                          ;If EDX = -1, use the current opts
    Mov     [optsI],EAX

    ;DSP option adjustment -------------------
    Mov     EDX,[dspOpts]
    XOr     EDX,EAX
    Mov     [dspOpts],EAX

    Test    DX,DSP_ECHOFIR                                                      ;If the DSP_ECHOFIR flag changes,
    SetZ    AL                                                                  ; force sampling rate processing (rawRate = -1)
    MovZX   EAX,AL
    Dec     EAX
    Or      [rawRate],EAX

    Mov     EAX,[rateI]
    Cmp     EAX,[rawRate]                                                       ;Has sample rate changed?
    JE      .KeepRate                                                           ;   No
        Mov     [rawRate],EAX
        XOr     EDX,EDX
        Mov     [outCur],EDX                                                    ;Discard the samples made at the old rate
        Mov     [outLen],EDX

%if INTBK
        Test    word [dspOpts],DSP_ECHOFIR                                      ;If actual emulation mode and
        SetNZ   CL                                                              ; rate > 32000, rate = 32000
        Mov     EDX,32000
        Cmp     EAX,EDX
        SetA    CH
        And     CL,CH
        CMovX   NZ,EAX,EDX
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

    Mov     EDX,1024                                                            ;If speed < 1024, speed = 1024 (~1.5%)
    Cmp     EAX,EDX                                                             ;NOTE: If lower any more, will crash or noisy.
    CMovX   B,EAX,EDX

    Mov     EDX,1048576                                                         ;If speed > 1048576, speed = 1048576 (x16)
    Cmp     EAX,EDX
    CMovX   A,EAX,EDX

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

EXPROC SetAPULength, song, fade

    ;NOTE (x64 port): This used to be 'Jmp SetDSPLength', a tail-jump that only works when caller
    ; and callee share a calling convention, which holds on x86 but not on x64.  EXPROC left song
    ; and fade unhomed in RCX and RDX, while SetDSPLength expected them pushed to the stack by Call,
    ; so jumping straight in read stack garbage.  Declaring the parameters and forwarding via Call,
    ; not Jmp, fixes this on both architectures.
    Call    SetDSPLength,[song],[fade]

ENDP


;===================================================================================================
;Emulate Audio Processing Unit

;EmuAPU recurses into itself internally (see EmuAPUBySmp's/.NextSec's own 'Call EmuAPUI' below), so
; the DEF-exported entry point is just a thin ABI bridge into the real (internal-convention) body --
; see x64.inc's EXPROC for why a DEF-exported name that is also called internally needs this split.

EXPROC EmuAPU, pBuf, len, type
USES ECX

    Mov     PCX,[pBuf]
    Mov     PAX,PCX
    Test    PCX,PCX                                                             ;NULL pBuf does nothing and returns NULL.  Internal callers
    RetZ                                                                        ; such as SeekAPU call EmuAPUI with no buffer on purpose.

    MovZX   EAX,byte [type]
    Call    EmuAPUI,PCX,[len],EAX

ENDP

PROC EmuAPUI, pBufI, lenI, typeI
USES ECX,EDX,EBX,ESI,EDI

    Mov     PDI,[pBufI]
    Mov     EAX,[lenI]
    XOr     ESI,ESI                                                             ;ESI = High bits of the clock cycles left
    Test    EAX,EAX
    JZ      .Done

    Test    byte [typeI],-1                                                     ;Is the unit of len samples?
    JS      .NextSec                                                            ;   No, not adjust clock cycles (for seek)
    JZ      .AdjCycles                                                          ;   No, adjust clock cycles to APU speed
        Call    EmuAPUBySmp                                                     ;   Yes
        Jmp     .Done

    .AdjCycles:
    ;NOTE: Above 1.0x speed, the adjusted cycles of a long request do not fit in 32 bits (from about
    ; 10.9 seconds at x16), so they are kept in ESI:EAX, up to 36 bits.
    Mov     ECX,[smpRAdj]                                                       ;ESI:EAX = EAX * smpRAdj / 65536
    Mul     ECX
    ShRD    EAX,EDX,16
    ShR     EDX,16
    Mov     ESI,EDX

    .NextSec:
    Mov     ECX,APU_CLK
    Mov     EBX,EAX

    ;Fixup cycles ----------------------------
    Cmp     EAX,ECX                                                             ;If ESI:EAX > APU_CLK, EAX = APU_CLK (unsigned, as len is)
    CMovX   A,EAX,ECX
    Test    ESI,ESI
    CMovX   NZ,EAX,ECX
    Sub     EBX,EAX                                                             ;len -= clock cycles, borrowing from the high bits
    SbB     ESI,0

    ;Initialize DSP --------------------------
    ;NOTE: The samples are created on every pass, even when the SPC700 already ran past this time in
    ; the previous call, so that every clock cycle of SPC700 time has its output.
    Push    PAX
    Mul     dword [smpREmu]                                                     ;samples = ((smpREmu * cycles) + smpDec) / APU_CLK
    Add     EAX,[smpDec]
    AdC     EDX,0
    Div     ECX
    Mov     [smpDec],EDX

    Call    SetEmuDSP,PDI,EAX,[smpREmu]
    Pop     PAX

    ;Emulate APU -----------------------------
    ;NOTE: For more accurate emulation, instead of waiting for cycles after doing 1 opcode
    ; processing, running opcode should be processed internally every cycle.  However, this
    ; requires complex logic and sophisticated analysis.
    Add     EAX,[cycLeft]                                                       ;Did the previous call already emulate past this time?
    JLE     .NoCycles                                                           ;   Yes, only create the samples
    Call    EmuSPC,EAX

    .NoCycles:
    Mov     ECX,EAX                                                             ;ECX = len - emulated clock cycles

    Call    SetEmuDSP,0,0,0                                                     ;Create any remaining samples
    Mov     PDI,PAX                                                             ;PDI = End of buffer
    Mov     [cycLeft],ECX
    Mov     EAX,EBX
    Or      EBX,ESI                                                             ;Is emulation completed?
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
    Mov     EDX,[outCur]                                                        ;outCur is a plain dword.  'Add r64,r/m32' is not
    Add     PSI,PDX                                                             ; encodable, so load 32-bit then add at full width
    MovZX   EDX,byte [rawByte]

    .BefLoop:
        Mov     ECX,EDX                                                         ;Copy from outBuf to pBuf
        Rep     MovSB
        Add     [outCur],EDX
        Sub     [outLen],EDX

        Dec     EBX                                                             ;Is emulation completed?
        RetZ                                                                    ;   Yes, done

        Sub     EAX,EDX                                                         ;Is outBuf empty?
        JNZ     .BefLoop                                                        ;   No, continue

    .BefEnd:
    Mov     [outCur],EAX                                                        ;EAX = 0

    ;Emulate whole seconds -------------------
    ;NOTE: The code below works out the clock cycles of the request in one go, so more than one
    ; second is first emulated a second at a time, rawRate samples being exactly APU_CLK cycles.
    ; This keeps its 32-bit math in range, and leaves at most one second of rounding loss for
    ; outBuf.
    .NextSec:
    Cmp     EBX,[rawRate]                                                       ;Is more than one second left?
    JBE     .Fixup                                                              ;   No
        Call    EmuAPUI,PDI,APU_CLK,0
        Mov     PDX,PAX                                                         ;Save return value of EmuAPU
        Sub     PAX,PDI                                                         ;EAX = Emulated buffer size (bytes)
        Mov     PDI,PDX                                                         ;PDI = End of buffer

        XOr     EDX,EDX                                                         ;EAX = Bytes to samples
        MovZX   ECX,byte [rawByte]
        Div     ECX
        Sub     EBX,EAX                                                         ;No more than rawRate samples come out, so EBX stays
        Jmp     .NextSec                                                        ; above 0

    ;Fixup samples ---------------------------
    .Fixup:
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
    RetZ                                                                        ;   Yes, done

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
    Mov     EDX,24576                                                           ;NOTE: If clock cycles is less than 24576 and playback
    Cmp     ECX,EDX                                                             ; speed is below 25%, will crash or noisy.
    CMovX   B,ECX,EDX

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
        RetZ                                                                    ;   Yes, done

        Sub     EAX,EDX                                                         ;Is outBuf empty?
        JNZ     .AftLoop                                                        ;   No, continue

        Mov     [outCur],EAX                                                    ;EAX = 0, since outBuf is refilled from its start when
        Jmp     .AftEmu                                                         ; emulation is re-run

ENDP


;===================================================================================================
;Seek to Position

EXPROC SeekAPU, time, fast
USES ECX,EDX

    Mov     EAX,[time]                                                          ;numSeconds = time / 64000
    Test    EAX,EAX                                                             ;time = 00h?
    RetZ                                                                        ;   Yes, done

    XOr     EDX,EDX
    Mov     ECX,64000
    Div     ECX
    Mov     ECX,EAX                                                             ;ECX = time / 64000
    IMul    EDX,APU_CLK/64000                                                   ;EDX = (time % 64000) * (APU_CLK / 64000)

    Test    byte [fast],-1                                                      ;Fast mode completely bypasses the DSP emulation
    JZ      .Slow
        Mov     EAX,[dbgOpt]                                                    ;Save the frontend's debugging options (width fix only,
        Push    PAX                                                             ; not a pointer), restored after the seek
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
        Pop     PAX
        Call    SetSPCDbgI,-1,EAX                                               ;Restore the frontend's options, which re-enables DSP writes
        Jmp     .Done

    .Slow:
        Mov     EAX,[dspOpts]
        Push    PAX                                                             ;Save APU options (width fix only, not a pointer)
        Or      EAX,DSP_ENVSPD+DSP_NOSAFE
        Call    SetAPUOptI,-1,-1,-1,-1,-1,EAX
        Mov     EAX,[smpRAdj]
        Push    PAX,PDI                                                         ;Save APU speed (width fix only, not a pointer)

        Mov     EDI,EAX
        ShR     EAX,16                                                          ;When APU speed is less than 100%, temporarily increase
        Mov     EAX,10000h                                                      ; it to 100% to speed up processing
        CMovX   Z,EDI,EAX

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
    XOr     EAX,EAX
    Mov     [outCur],EAX                                                        ;Discard samples EmuAPUBySmp kept from before the seek
    Mov     [outLen],EAX
    Call    FixSeek,[fast]                                                      ;Fixup DSP after seeking

ENDP


;===================================================================================================
;Set/Reset TimerTrick Compatible Function

EXPROC SetTimerTrick, port, wait
USES ECX,ESI

    Mov     CL,[scr700inc+02h]
    Test    CL,CL                                                               ;Is a script being compiled for an include?
    RetNZ                                                                       ;   Yes, leave it alone

    Call    SetScript700I,0                                                     ;Clear the current script first
    Mov     ECX,[wait]
    Test    ECX,ECX                                                             ;Is TimerTrick being turned off?
    RetZ                                                                        ;   Yes, the script is already cleared

    ;NOTE: The 'w' command adds the wait to a signed count, so a wait of 80000000h or more wraps it.
    ; The wait then comes out wrong, or the loop spins forever.  The wait is capped at about 17
    ; minutes.
    Cmp     ECX,7FFFFF00h                                                       ;Is the wait too long?
    JBE     .WaitOK                                                             ;   No
        Mov     ECX,7FFFFF00h                                                   ;   Yes, cap it

    .WaitOK:

    ;NOTE: Convert from TimerTrick to Script700.  TimerTrick increments the value of a specific port
    ; by 1 at regular intervals.  This process generates the Script700 binary code to achieve this
    ; functionality.  The conversion rules are as follows.
    ;-------------------------------------------------------------------------------
    ; [Script700 Command]       [Binary]
    ; :0    w   (WAIT)      ->  00h : 01h 00h ??? ??? ??? ???
    ;       a   #1  i(PORT) ->  06h : 04h 00h 00h 01h 00h 00h 00h 02h ???
    ;       bra 0           ->  0Fh : 05h 00h 00h
    ;       (EXIT)          ->  12h : 00h
    ;-------------------------------------------------------------------------------

    Mov     PSI,[pSCRRAM]
    Mov     [PSI+02h],ECX                                                       ;Operand of 'w': the wait
    Mov     CL,[port]
    Mov     [PSI+0Eh],CL                                                        ;Destination of 'a': the port number

    Mov     word  [PSI+00h],0001h
    Mov     dword [PSI+06h],01000004h
    Mov     dword [PSI+0Ah],02000000h
    Mov     dword [PSI+0Fh],00000005h
    Mov     dword [scr700lbl],0

ENDP


;===================================================================================================
;Seek First Command
;   Uses: DH, AL
;   Z flag: OFF=Success, ON=Failure

PROC GetScript700First

    XOr     DH,DH                                                               ;Failure until a command is found

    .RETURN:
    Mov     AL,[PCX]
    Cmp     AL,00h                                                              ;End of the text?
    JE      .ERROR                                                              ;   Yes, no command
    Cmp     AL,09h                                                              ;TAB?
    JE      .NEXT                                                               ;   Yes, skip it
    Cmp     AL,0Ah                                                              ;End of the line?
    JE      .ERROR                                                              ;   Yes, no command on this line
    Cmp     AL,0Dh                                                              ;End of the line?
    JE      .ERROR                                                              ;   Yes, no command on this line
    Cmp     AL,20h                                                              ;SPACE?
    JE      .NEXT                                                               ;   Yes, skip it
    Or      DH,01h                                                              ;Success, PCX is on the command
    Jmp     .EXIT

    .NEXT:
    Inc     PCX
    Jmp     .RETURN

    .ERROR:
    XOr     DH,DH

    .EXIT:
    Test    DH,DH                                                               ;ZF = 1 on failure, for the caller

ENDP


;===================================================================================================
;Seek Next Command/Parameter
;   Uses: DH, AL
;   Z flag: OFF=Success, ON=Failure

PROC GetScript700Next

    XOr     DH,DH                                                               ;Failure until a separator is passed

    .RETURN:
    Mov     AL,[PCX]
    Cmp     AL,00h                                                              ;End of the text?
    JE      .ERROR                                                              ;   Yes, no next token
    Cmp     AL,09h                                                              ;TAB?
    JE      .NEXT                                                               ;   Yes, skip it
    Cmp     AL,0Ah                                                              ;End of the line?
    JE      .ERROR                                                              ;   Yes, no next token on this line
    Cmp     AL,0Dh                                                              ;End of the line?
    JE      .ERROR                                                              ;   Yes, no next token on this line
    Cmp     AL,20h                                                              ;SPACE?
    JNE     .EXIT                                                               ;   No, PCX is on the next token, if a separator came first

    .NEXT:
    Inc     PCX
    Or      DH,01h                                                              ;A separator was passed
    Jmp     .RETURN

    .ERROR:
    XOr     DH,DH

    .EXIT:
    Test    DH,DH                                                               ;ZF = 1 on failure, for the caller

ENDP


;===================================================================================================
;Skip Next Command/Parameter
;   Uses: AL

PROC GetScript700Skip

    .RETURN:
    Mov     AL,[PCX]
    Cmp     AL,00h                                                              ;End of the text?
    RetZ                                                                        ;   Yes, the token ends here
    Cmp     AL,09h                                                              ;TAB?
    RetZ                                                                        ;   Yes, the token ends here
    Cmp     AL,0Ah                                                              ;End of the line?
    RetZ                                                                        ;   Yes, the token ends here
    Cmp     AL,0Dh                                                              ;End of the line?
    RetZ                                                                        ;   Yes, the token ends here
    Cmp     AL,20h                                                              ;SPACE?
    RetZ                                                                        ;   Yes, the token ends here

    Inc     PCX
    Jmp     .RETURN

ENDP


;===================================================================================================
;Seek Next Line
;   Uses: DH, AL

PROC GetScript700NextLine

    .RETURN:
    Mov     AL,[PCX]
    Cmp     AL,00h                                                              ;End of the text?
    RetZ                                                                        ;   Yes, there is no next line
    Cmp     AL,0Ah                                                              ;End of the line?
    JE      .NEXT2                                                              ;   Yes, pass the line break
    Cmp     AL,0Dh                                                              ;End of the line?
    JE      .NEXT2                                                              ;   Yes, pass the line break
    Inc     PCX                                                                 ;Skip the rest of the line
    Jmp     .RETURN

    .NEXT1:
    Mov     AL,[PCX]
    Cmp     AL,00h                                                              ;End of the text?
    RetZ                                                                        ;   Yes, there is no next line
    Cmp     AL,0Ah                                                              ;Another line break?
    JE      .NEXT2                                                              ;   Yes, pass it too, which also skips empty lines
    Cmp     AL,0Dh                                                              ;Another line break?
    JE      .NEXT2                                                              ;   Yes, pass it too, which also skips empty lines
    RetN                                                                        ;PCX is at the start of the next line

    .NEXT2:
    Inc     PCX
    Jmp     .NEXT1

ENDP


;===================================================================================================
;Parse Number (Supported DEC or HEX, and Minus)
;   EAX = Number of Result
;   Uses: DH
;   Z flag: OFF=Success, ON=Failure

PROC GetScript700Number

    Push    PBX
    XOr     EAX,EAX                                                             ;Value so far
    XOr     EBX,EBX                                                             ;Each digit goes in BL, with the rest of EBX kept 0
    XOr     DH,DH                                                               ;Flags: 01h digits read, 02h minus, 04h hexadecimal

    Mov     BL,[PCX]
    Cmp     BL,2Bh                                                              ;'+'?
    JE      .NOP                                                                ;   Yes, skip it
    Cmp     BL,2Dh                                                              ;'-'?
    JE      .MINUS                                                              ;   Yes, negate at the end

    .RETURNFIRST:
    Cmp     BL,30h                                                              ;'0', which may start '0x'?
    JE      .HEXZ                                                               ;   Yes, look for the 'x'
    Cmp     BL,24h                                                              ;'$'?
    JE      .HEXOK                                                              ;   Yes, hexadecimal

    .RETURN:
    Mov     BL,[PCX]
    Sub     BL,30h                                                              ;Digit value, if '0' to '9'
    Cmp     BL,10                                                               ;A decimal digit?
    JB      .RETURNNEXT                                                         ;   Yes

    Test    DH,04h                                                              ;Hexadecimal?
    JZ      .NEXT                                                               ;   No, the number ends here
    Sub     BL,11h                                                              ;'A' to 'F' become 0 to 5
    Cmp     BL,6                                                                ;'A' to 'F'?
    JB      .HEXCHECKNEXT                                                       ;   Yes
    Sub     BL,20h                                                              ;'a' to 'f' become 0 to 5
    Cmp     BL,6                                                                ;'a' to 'f'?
    JAE     .NEXT                                                               ;   No, the number ends here

    .HEXCHECKNEXT:
    Add     BL,10                                                               ;Value of the hex digit A to F

    .RETURNNEXT:
    Test    DH,04h                                                              ;Hexadecimal?
    JNZ     .SETHEX                                                             ;   Yes
        LEA     EAX,[EAX+EAX*4]                                                 ;Value * 10, as * 5 and then * 2
        Add     EAX,EAX
        Jmp     .SETOK

    .SETHEX:
        ShL     EAX,4                                                           ;Value * 16

    .SETOK:
    Add     EAX,EBX                                                             ;Add the digit
    Inc     PCX
    Or      DH,01h                                                              ;At least one digit has been read
    Jmp     .RETURN

    .MINUS:
    Or      DH,02h                                                              ;Negate at the end

    .NOP:
    Inc     PCX
    Mov     BL,[PCX]
    Jmp     .RETURNFIRST

    .HEXZ:
    Inc     PCX
    Mov     BL,[PCX]
    And     BL,0DFh                                                             ;To upper case
    Cmp     BL,58h                                                              ;'x' after the '0'?
    JE      .HEXOK                                                              ;   Yes, hexadecimal
    Dec     PCX                                                                 ;   No, read the '0' as a decimal digit
    Jmp     .RETURN

    .HEXOK:
    Or      DH,04h                                                              ;Hexadecimal
    Inc     PCX                                                                 ;Skip the 'x' or '$'
    Jmp     .RETURN

    .NEXT:
    Mov     BL,[PCX]
    Cmp     BL,00h                                                              ;End of the text?
    JE      .EXIT                                                               ;   Yes, the number ends here
    Cmp     BL,09h                                                              ;TAB?
    JE      .EXIT                                                               ;   Yes, the number ends here
    Cmp     BL,0Ah                                                              ;End of the line?
    JE      .EXIT                                                               ;   Yes, the number ends here
    Cmp     BL,0Dh                                                              ;End of the line?
    JE      .EXIT                                                               ;   Yes, the number ends here
    Cmp     BL,20h                                                              ;SPACE?
    JE      .EXIT                                                               ;   Yes, the number ends here
    XOr     DH,DH                                                               ;Failure, another character follows the number

    .EXIT:
    Test    DH,02h                                                              ;Minus?
    JZ      .PLUS                                                               ;   No
        Neg     EAX

    .PLUS:
    Pop     PBX
    And     DH,01h                                                              ;ZF = 1 on failure (no digit, or a bad end), for the caller

ENDP


;===================================================================================================
;Check Last of Command/Parameter
;   Uses: DH, AL
;   Z flag: OFF=Success, ON=Failure

PROC GetScript700Last

    Mov     DH,01h                                                              ;Success unless another character follows
    Inc     PCX                                                                 ;Look at the character after the token's last one

    Mov     AL,[PCX]
    Cmp     AL,00h                                                              ;End of the text?
    JE      .OK                                                                 ;   Yes, the token ends cleanly
    Cmp     AL,09h                                                              ;TAB?
    JE      .OK                                                                 ;   Yes, the token ends cleanly
    Cmp     AL,0Ah                                                              ;End of the line?
    JE      .OK                                                                 ;   Yes, the token ends cleanly
    Cmp     AL,0Dh                                                              ;End of the line?
    JE      .OK                                                                 ;   Yes, the token ends cleanly
    Cmp     AL,20h                                                              ;SPACE?
    JE      .OK                                                                 ;   Yes, the token ends cleanly
    XOr     DH,DH                                                               ;Failure, the token runs on into other characters

    .OK:
    Test    DH,DH                                                               ;ZF = 1 on failure, for the caller

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

    Mov     PSI,[pSCRRAM]

    Mov     AX,[scr700inc+02h]
    Test    AL,AL                                                               ;Called back to compile an included text?
    JZ      .INIT                                                               ;   No, start a new script
        Mov     PCX,[pSourceI]
        Test    PCX,PCX                                                         ;No text?
        JZ      .CRITICALERROR                                                  ;   Yes

        IdxLd   Mov,EBX,scr700inc,04h                                           ;Continue at the program cursor of the including script
        Mov     EDI,EBX                                                         ;Rollback point for an error
        Dec     AH                                                              ;Was the include in the EXT zone?
        JZ      .EXTRETURN                                                      ;   Yes
        Dec     AH                                                              ;In the data zone?
        JZ      .DATARETURN2                                                    ;   Yes
        Jmp     .NORMALRETURN                                                   ;   No, in the script command zone

    .INIT:
    XOr     EAX,EAX
    Mov     [PSI],AL                                                            ;Start with an empty program ('q')
    Mov     [scr700ptr],EAX                                                     ;Run from the start of the program
    Mov     [scr700dat],EAX                                                     ;No data area yet
    Mov     [scr700inc],EAX                                                     ;Not in include mode
    Mov     dword [scr700cnt],32                                                ;Same start count as ResetSPC

    LoadPtr PDI,scr700dsp
    Mov     PCX,328                                                             ;Clear the DSP flags (256/4 + 32/4 dwords) and detune (256)
    Rep     StoSD

    LoadPtr PDI,scr700chg
    Mov     ECX,EAX                                                             ;Note change table as identity, entry n = n

    .CLEARCHG:
        Dec     CL
        Mov     [PDI+PCX],CL
    Dec     AL                                                                  ;All 256 entries
    JNZ     .CLEARCHG

    LoadPtr PDI,scr700lbl
    Dec     EAX                                                                 ;-1 marks a label as undefined
    Mov     PCX,1024                                                            ;All 1024 labels
    Rep     StoSD

    Mov     PCX,[pSourceI]
    Test    PCX,PCX                                                             ;No text?
    JZ      .CRITICALERROR                                                      ;   Yes, Script700 is disabled
    XOr     EBX,EBX                                                             ;Reset the program cursor
    XOr     EDI,EDI                                                             ;Reset the rollback point for an error

    ;---------- Script Command Zone ----------

    .NORMALRETURN:
    And     PBX,SCR700MASK                                                      ;Keep the program cursor inside the Script700 area
    Cmp     PBX,PDI                                                             ;Did the cursor wrap back before this line?
    JB      .CRITICALERROR                                                      ;   Yes, the program is too large

    Mov     PDI,PBX                                                             ;Rollback point: the start of this line's code
    Call    GetScript700First                                                   ;Find the command on this line
    JZ      .NORMALERROR                                                        ;   None, so the line is skipped
    XOr     DL,DL

    Mov     AL,[PCX]
    Cmp     AL,3Ah                                                              ;':', a label?
    JE      .LABEL                                                              ;   Yes
    Cmp     AL,23h                                                              ;'#', a directive such as an include?
    JE      .Shp                                                                ;   Yes
    And     AL,0DFh                                                             ;To upper case
    Cmp     AL,45h                                                              ;'e', the start of the EXT zone?
    JE      .E                                                                  ;   Yes
    Cmp     AL,51h                                                              ;'q'?
    JE      .Q                                                                  ;   Yes
    Cmp     AL,57h                                                              ;'w'?
    JE      .W                                                                  ;   Yes
    Cmp     AL,4Dh                                                              ;'m'?
    JE      .M                                                                  ;   Yes
    Cmp     AL,43h                                                              ;'c'?
    JE      .C                                                                  ;   Yes
    Cmp     AL,41h                                                              ;'a'?
    JE      .A                                                                  ;   Yes
    Cmp     AL,53h                                                              ;'s'?
    JE      .S                                                                  ;   Yes
    Cmp     AL,55h                                                              ;'u'?
    JE      .U                                                                  ;   Yes
    Cmp     AL,44h                                                              ;'d'?
    JE      .D                                                                  ;   Yes
    Cmp     AL,4Eh                                                              ;'n'?
    JE      .N                                                                  ;   Yes
    Cmp     AL,42h                                                              ;'b', a branch?
    JE      .B                                                                  ;   Yes
    Cmp     AL,52h                                                              ;'r'?
    JE      .R                                                                  ;   Yes
    Cmp     AL,46h                                                              ;'f'?
    JE      .F                                                                  ;   Yes
    Jmp     .NORMALERROR                                                        ;   No, an unknown command

    .E:                                                                                                             ; e
    Call    GetScript700Last                                                    ;Is 'e' alone?
    JZ      .NORMALERROR                                                        ;   No, an error

    Mov     byte [scr700inc+03h],01h                                            ;Now in the EXT zone
    Jmp     .EXTRETURN

    .Q:                                                                                                             ; q
    Call    GetScript700Last                                                    ;Is 'q' alone?
    JZ      .NORMALERROR                                                        ;   No, an error

    Mov     byte [PSI+PBX],00h                                                  ;Emit 'q' (opcode 00h)
    Inc     PBX
    Jmp     .NORMALRETURN

    .LABEL:
    Inc     PCX                                                                 ;Past the ':'
    Mov     AL,[PCX]
    Cmp     AL,3Ah                                                              ;'::', the start of the EXT zone?
    JE      .LABEL2                                                             ;   Yes
    Call    GetScript700Number                                                  ;Label number                       ; :[LABEL]
    JZ      .NORMALERROR                                                        ;   Not a number, an error

    And     EAX,1023                                                            ;Labels wrap at 1024
    IdxSt   Mov,scr700lbl,PAX*4,EBX                                             ;The label points at the next command's code
    Jmp     .NORMALRETURN

    .LABEL2:                                                                                                        ; ::
    Call    GetScript700Last                                                    ;Is '::' alone?
    JZ      .NORMALERROR                                                        ;   No, an error

    Mov     byte [scr700inc+03h],01h                                            ;Now in the EXT zone
    Jmp     .EXTRETURN

    .NOP:                                                                                                           ; nop
    Inc     PCX
    Mov     AL,[PCX]
    Test    AL,AL                                                               ;End of the text?
    JZ      .NORMALERROR                                                        ;   Yes, an error

    And     AL,0DFh                                                             ;To upper case
    Cmp     AL,50h                                                              ;'nop'?
    JNE     .NORMALERROR                                                        ;   No, an error

    Call    GetScript700Last                                                    ;Is 'nop' alone?
    JZ      .NORMALERROR                                                        ;   No, an error
    Jmp     .NORMALRETURN                                                       ;'nop' emits no code

    .N:                                                                                                             ; n
    Inc     PCX
    Mov     AL,[PCX]
    And     AL,0DFh                                                             ;To upper case
    Cmp     AL,4Fh                                                              ;'no', so maybe 'nop'?
    JE      .NOP                                                                ;   Yes
    Mov     DL,04h                                                              ;Opcode of 'n'
    Call    GetScript700Next                                                    ;Find the 1st operand
    JZ      .NORMALERROR                                                        ;   None, an error

    Mov     [scr700tmp],PCX                                                     ;Remember the 1st operand, encoded after the operator
    Call    GetScript700Skip                                                    ;Over the 1st operand
    Call    GetScript700Next                                                    ;Find the operator
    JZ      .NORMALERROR                                                        ;   None, an error

    Mov     AL,[PCX]
    XOr     DH,DH                                                               ;Operator code, counted up as each one is tried
    Cmp     AL,2Bh                                                              ;'+', operator 00h?
    JE      .NORMALNEXT                                                         ;   Yes
    Inc     DH
    Cmp     AL,2Dh                                                              ;'-', operator 01h?
    JE      .NORMALNEXT                                                         ;   Yes
    Inc     DH
    Cmp     AL,2Ah                                                              ;'*', operator 02h?
    JE      .NORMALNEXT                                                         ;   Yes
    Inc     DH
    Cmp     AL,2Fh                                                              ;'/', operator 03h?
    JE      .NORMALNEXT                                                         ;   Yes
    Inc     DH
    Cmp     AL,5Ch                                                              ;'\', operator 04h?
    JE      .NORMALNEXT                                                         ;   Yes
    Inc     DH
    Cmp     AL,25h                                                              ;'%', operator 05h?
    JE      .NORMALNEXT                                                         ;   Yes
    Inc     DH
    Cmp     AL,24h                                                              ;'$', operator 06h?
    JE      .NORMALNEXT                                                         ;   Yes
    Inc     DH
    Cmp     AL,26h                                                              ;'&', operator 07h?
    JE      .NORMALNEXT                                                         ;   Yes
    Inc     DH
    Cmp     AL,7Ch                                                              ;'|', operator 08h?
    JE      .NORMALNEXT                                                         ;   Yes
    Inc     DH
    Cmp     AL,5Eh                                                              ;'^', operator 09h?
    JE      .NORMALNEXT                                                         ;   Yes
    Inc     DH
    Cmp     AL,3Ch                                                              ;'<', operator 0Ah?
    JE      .NORMALNEXT                                                         ;   Yes
    Inc     DH
    Cmp     AL,3Eh                                                              ;'>', operator 0Bh?
    JE      .NORMALNEXT                                                         ;   Yes
    Inc     DH
    Cmp     AL,5Fh                                                              ;'_', operator 0Ch?
    JE      .NORMALNEXT                                                         ;   Yes
    Inc     DH
    Cmp     AL,21h                                                              ;'!', operator 0Dh?
    JE      .NORMALNEXT                                                         ;   Yes
    Mov     DH,0FFh                                                             ;Unknown operator, rejected below
    Jmp     .NORMALNEXT

    .M:                                                                                                             ; m
    Mov     DL,02h                                                              ;Opcode of 'm'
    Jmp     .NORMALNEXT

    .C:                                                                                                             ; c
    Mov     DL,03h                                                              ;Opcode of 'c'
    Jmp     .NORMALNEXT

    .A:                                                                                                             ; a
    Mov     DX,0005h                                                            ;'a' is 'n' with '+' (DL = 05h marks a, s, u and d)
    Jmp     .NORMALNEXT

    .S:                                                                                                             ; s
    Mov     DX,0105h                                                            ;'s' is 'n' with '-'
    Jmp     .NORMALNEXT

    .U:                                                                                                             ; u
    Mov     DX,0205h                                                            ;'u' is 'n' with '*'
    Jmp     .NORMALNEXT

    .D:                                                                                                             ; d
    Mov     DX,0305h                                                            ;'d' is 'n' with '/'

    .NORMALNEXT:
    Cmp     DL,04h                                                              ;'n'?
    JE      .SETN                                                               ;   Yes
    Cmp     DL,05h                                                              ;'a', 's', 'u' or 'd'?
    JE      .SETASUD                                                            ;   Yes
        Mov     [PSI+PBX],DL                                                    ;Emit the opcode
        Jmp     .SETNE

    .SETN:
        Inc     DH                                                              ;Unknown operator (0FFh)?
        JZ      .NORMALERROR                                                    ;   Yes, an error

        Dec     DH
        Mov     [PSI+PBX],DL                                                    ;Emit the opcode of 'n'
        Inc     PBX
        Mov     [PSI+PBX],DH                                                    ;Emit the operator
        Jmp     .SETNE

    .SETASUD:
        Inc     DH                                                              ;Unknown operator (0FFh)?
        JZ      .NORMALERROR                                                    ;   Yes, an error

        Dec     DH
        Mov     byte [PSI+PBX],04h                                              ;Emit them as 'n'
        Inc     PBX
        Mov     [PSI+PBX],DH                                                    ;Emit the operator

    .SETNE:
    Inc     PBX
    Cmp     DL,04h                                                              ;'n'?
    JNE     .NNEXT                                                              ;   No
        Call    GetScript700Last                                                ;Is the operator a single character?
        JZ      .NORMALERROR                                                    ;   No, an error

        Mov     PCX,[scr700tmp]                                                 ;Back to the 1st operand
        Jmp     .N1E

    .NNEXT:
        Inc     PCX                                                             ;Past the command letter
        Call    GetScript700Next                                                ;Find the 1st operand
        JZ      .NORMALERROR                                                    ;   None, an error

    .N1E:
    ShL     EDX,16                                                              ;Keep the opcode (DL) and operator (DH) in the upper half
    LoadPtr PAX,.N2                                                             ;After the 1st operand, go on to the 2nd
    Mov     [scr700jmp],PAX
    Inc     DH                                                                  ;Not 'w', so a bare number is a port
    Jmp     .SETVAL                                                             ;Encode the 1st operand

    .W:                                                                                                             ; w
    Inc     PCX
    Mov     AL,[PCX]
    And     AL,0DFh                                                             ;To upper case
    Cmp     AL,49h                                                              ;'wi'?
    JE      .WI                                                                 ;   Yes
    Cmp     AL,4Fh                                                              ;'wo'?
    JE      .WO                                                                 ;   Yes
    Dec     PCX                                                                 ;   No, a plain 'w'

    Mov     byte [PSI+PBX],01h                                                  ;Emit 'w' (01h)
    Jmp     .WNEXT

    .WI:                                                                                                            ; wi
    Mov     byte [PSI+PBX],16h                                                  ;Emit 'wi' (16h)
    Jmp     .WNEXT

    .WO:                                                                                                            ; wo
    Mov     byte [PSI+PBX],17h                                                  ;Emit 'wo' (17h)

    .WNEXT:
    Inc     PBX
    Inc     PCX                                                                 ;Past the command
    Call    GetScript700Next                                                    ;Find the operand
    JZ      .NORMALERROR                                                        ;   None, an error

    LoadPtr PAX,.NORMALRETURN                                                   ;After the operand, the command is done
    Mov     [scr700jmp],PAX
    XOr     DH,DH                                                               ;'w', 'wi' or 'wo', so a bare number is an immediate
    Jmp     .SETVAL                                                             ;Encode the operand

    .N2:
    ShR     EDX,16                                                              ;Get the opcode back into DL
    Cmp     DL,04h                                                              ;'n'?
    JNE     .N2E                                                                ;   No
        Call    GetScript700Next                                                ;Find the operator
        JZ      .NORMALERROR                                                    ;   None, an error
        Call    GetScript700Skip                                                ;Over the operator

    .N2E:
    Call    GetScript700Next                                                    ;Find the 2nd operand
    JZ      .NORMALERROR                                                        ;   None, an error

    LoadPtr PAX,.NORMALRETURN                                                   ;After the 2nd operand, the command is done
    Mov     [scr700jmp],PAX
    Mov     DH,01h                                                              ;Not 'w', so a bare number is a port

    .SETVAL:
    Mov     AL,[PCX]
    XOr     DL,DL                                                               ;Operand type, counted up as each prefix is tried
    Cmp     AL,23h                                                              ;'#', an immediate (00h)?           ; #[NUM]
    JE      .SETVAL4B                                                           ;   Yes, 4 bytes
    And     AL,0DFh                                                             ;To upper case
    Add     DL,2
    Cmp     AL,49h                                                              ;'i', an input port (02h)?          ; i[PORT]
    JE      .SETVAL1B                                                           ;   Yes, 1 byte
    Inc     DL
    Cmp     AL,4Fh                                                              ;'o', an output port (03h)?         ; o[PORT]
    JE      .SETVAL1B                                                           ;   Yes, 1 byte
    Inc     DL
    Cmp     AL,57h                                                              ;'w', a work register (04h)?        ; w[WORK]
    JE      .SETVAL1B                                                           ;   Yes, 1 byte
    Inc     DL
    Cmp     AL,58h                                                              ;'x', extra RAM (05h)?              ; x[XRAM]
    JE      .SETVAL1B                                                           ;   Yes, 1 byte
    XOr     AH,AH                                                               ;AH = 0 for RAM, 1 for the data area
    Inc     DL
    Cmp     AL,52h                                                              ;'r', SPC700 RAM (06h-08h)?         ; r(x)[RAM]
    JE      .SETVALRD                                                           ;   Yes, look for its size
    Inc     AH
    Add     DL,3
    Cmp     AL,44h                                                              ;'d', data area (09h-0Bh)?          ; d(x)[DATA]
    JE      .SETVALRD                                                           ;   Yes, look for its size
    Add     DL,3
    Cmp     AL,4Ch                                                              ;'l', a label (0Ch)?                ; l[LABEL]
    JE      .SETVAL2B                                                           ;   Yes, 2 bytes

    Dec     PCX                                                                 ;No prefix, back one character      ; (#)[NUM]/[PORT]
    Mov     DL,DH                                                               ;Type 00h (immediate) for 'w' and 'bp', 01h (port) otherwise
    Dec     DH                                                                  ;'w' or 'bp'?
    JNZ     .SETVAL4B                                                           ;   Yes, a 4-byte immediate
    Jmp     .SETVAL1B                                                           ;   No, a 1-byte port

    .SETVALRD:
    Inc     PCX
    Mov     AL,[PCX]
    And     AL,0DFh                                                             ;To upper case
    Cmp     AL,42h                                                              ;'b', byte size?                    ; rb[RAM], db[DATA]
    JE      .SETVALRD2                                                          ;   Yes
    Inc     DL
    Cmp     AL,57h                                                              ;'w', word size?                    ; rw[RAM], dw[DATA]
    JE      .SETVALRD2                                                          ;   Yes
    Inc     DL
    Cmp     AL,44h                                                              ;'d', dword size?                   ; rd[RAM], dd[DATA]
    JE      .SETVALRD2                                                          ;   Yes
    Dec     PCX                                                                 ;   No size, so byte size           ; r[RAM], d[DATA]
    Sub     DL,2                                                                ;Back to the byte type

    .SETVALRD2:
    Dec     AH                                                                  ;RAM?
    JNZ     .SETVAL2B                                                           ;   Yes, a 2-byte address

    .SETVAL4B:                                                                                                      ; 4 byte method
    Inc     PCX
    Mov     AL,[PCX]
    Cmp     AL,3Fh                                                              ;'?', the compare value?
    JE      .SETVALCMP                                                          ;   Yes
    Call    GetScript700Number                                                  ;The operand value
    JZ      .NORMALERROR                                                        ;   Not a number, an error

    Mov     [PSI+PBX],DL                                                        ;Emit the operand type and its 4-byte value
    Inc     PBX
    Mov     [PSI+PBX],EAX
    Add     PBX,4
    Jmp     [scr700jmp]                                                         ;Back to the command

    .SETVAL1B:                                                                                                      ; 1 byte method
    Inc     PCX
    Mov     AL,[PCX]
    Cmp     AL,3Fh                                                              ;'?', the compare value?
    JE      .SETVALCMP                                                          ;   Yes
    Call    GetScript700Number
    JZ      .NORMALERROR                                                        ;   Not a number, an error

    Mov     [PSI+PBX],DL                                                        ;Emit the operand type and its 1-byte value
    Inc     PBX
    Mov     [PSI+PBX],AL
    Inc     PBX
    Jmp     [scr700jmp]

    .SETVAL2B:                                                                                                      ; 2 byte method
    Inc     PCX
    Mov     AL,[PCX]
    Cmp     AL,3Fh                                                              ;'?', the compare value?
    JE      .SETVALCMP                                                          ;   Yes
    Call    GetScript700Number
    JZ      .NORMALERROR                                                        ;   Not a number, an error

    Mov     [PSI+PBX],DL                                                        ;Emit the operand type and its 2-byte value
    Inc     PBX
    Mov     [PSI+PBX],AX
    Add     PBX,2
    Jmp     [scr700jmp]

    .SETVALCMP:                                                                                                     ; cmp method
    Call    GetScript700Last                                                    ;Is '?' alone?
    JZ      .NORMALERROR                                                        ;   No, an error

    Add     DL,10h                                                              ;Types 10h and up read the compare value instead
    Mov     [PSI+PBX],DL                                                        ;Emit the operand type, no value follows
    Inc     PBX
    Jmp     [scr700jmp]

    .B:                                                                                                             ; bxx
    Inc     PCX
    Mov     AH,[PCX]                                                            ;2nd letter
    And     AH,0DFh                                                             ;To upper case.  End of the text or a SPACE (both now 0)?
    JZ      .NORMALERROR                                                        ;   Yes, an error

    Cmp     AH,50h                                                              ;'bp'?
    JE      .BP                                                                 ;   Yes
    Inc     PCX
    Mov     AL,[PCX]                                                            ;3rd letter
    And     AL,0DFh                                                             ;To upper case.  End of the text or a SPACE (both now 0)?
    JZ      .NORMALERROR                                                        ;   Yes, an error

    Mov     DL,05h                                                              ;Opcode, counted up as each branch is tried
    Cmp     AX,5241h                                                            ;'bra' (05h)?                       ; bra
    JE      .BXXNEXT                                                            ;   Yes
    Inc     DL
    Cmp     AX,4551h                                                            ;'beq' (06h)?                       ; beq
    JE      .BXXNEXT                                                            ;   Yes
    Inc     DL
    Cmp     AX,4E45h                                                            ;'bne' (07h)?                       ; bne
    JE      .BXXNEXT                                                            ;   Yes
    Inc     DL
    Cmp     AX,4745h                                                            ;'bge' (08h)?                       ; bge
    JE      .BXXNEXT                                                            ;   Yes
    Inc     DL
    Cmp     AX,4C45h                                                            ;'ble' (09h)?                       ; ble
    JE      .BXXNEXT                                                            ;   Yes
    Inc     DL
    Cmp     AX,4754h                                                            ;'bgt' (0Ah)?                       ; bgt
    JE      .BXXNEXT                                                            ;   Yes
    Inc     DL
    Cmp     AX,4C54h                                                            ;'blt' (0Bh)?                       ; blt
    JE      .BXXNEXT                                                            ;   Yes
    Inc     DL
    Cmp     AX,4343h                                                            ;'bcc' (0Ch)?                       ; bcc
    JE      .BXXNEXT                                                            ;   Yes
    Inc     DL
    Cmp     AX,4C4Fh                                                            ;'blo' (0Dh)?                       ; blo
    JE      .BXXNEXT                                                            ;   Yes
    Inc     DL
    Cmp     AX,4849h                                                            ;'bhi' (0Eh)?                       ; bhi
    JE      .BXXNEXT                                                            ;   Yes
    Inc     DL
    Cmp     AX,4353h                                                            ;'bcs' (0Fh)?                       ; bcs
    JE      .BXXNEXT                                                            ;   Yes
    Jmp     .NORMALERROR                                                        ;   No, an unknown branch

    .BXXNEXT:
    Inc     PCX                                                                 ;Past the command
    Call    GetScript700Next                                                    ;Find the target
    JZ      .NORMALERROR                                                        ;   None, an error

    Mov     AL,[PCX]
    Cmp     AL,23h                                                              ;'#', a label number?
    JE      .BXXVALN                                                            ;   Yes
    And     AL,0DFh                                                             ;To upper case
    Cmp     AL,57h                                                              ;'w', a label number in a work register?
    JE      .BXXVALW                                                            ;   Yes
    Dec     PCX                                                                 ;   No, a bare label number

    .BXXVALN:
    Inc     PCX
    Call    GetScript700Number                                                  ;Label number
    JZ      .NORMALERROR                                                        ;   Not a number, an error

    And     EAX,1023                                                            ;Labels wrap at 1024
    Mov     [PSI+PBX],DL                                                        ;Emit the opcode and the label number
    Inc     PBX
    Mov     [PSI+PBX],AX
    Add     PBX,2
    Jmp     .NORMALRETURN

    .BXXVALW:
    Inc     PCX                                                                 ;Past the 'w'
    Call    GetScript700Number                                                  ;Work register number
    JZ      .NORMALERROR                                                        ;   Not a number, an error

    Mov     AH,80h                                                              ;8000h + n reads the label number from wn
    Mov     [PSI+PBX],DL                                                        ;Emit the opcode and the work register
    Inc     PBX
    Mov     [PSI+PBX],AX
    Add     PBX,2
    Jmp     .NORMALRETURN

    .BP:                                                                                                            ; bp
    Test    dword [apuCbMask],CBE_REQBP                                         ;Does the frontend take breakpoint requests?
    JZ      .NORMALERROR                                                        ;   No, 'bp' is an error
    Test    PTRKW [apuCbFunc],-1                                                ;Is a callback installed?
    JZ      .NORMALERROR                                                        ;   No, 'bp' is an error

    Mov     byte [PSI+PBX],18h                                                  ;Emit 'bp' (18h)
    Inc     PBX
    Inc     PCX                                                                 ;Past the command
    Call    GetScript700Next                                                    ;Find the operand
    JZ      .NORMALERROR                                                        ;   None, an error

    LoadPtr PAX,.NORMALRETURN                                                   ;After the operand, the command is done
    Mov     [scr700jmp],PAX
    XOr     DH,DH                                                               ;A bare number is an immediate, as for 'w'
    Jmp     .SETVAL                                                             ;Encode the operand

    .R:                                                                                                             ; r
    Inc     PCX
    Mov     AL,[PCX]
    Cmp     AL,30h                                                              ;'r0'?
    JE      .R0                                                                 ;   Yes
    Cmp     AL,31h                                                              ;'r1'?
    JE      .R1                                                                 ;   Yes
    Dec     PCX                                                                 ;   No, a plain 'r'
    Call    GetScript700Last                                                    ;Is 'r' alone?
    JZ      .NORMALERROR                                                        ;   No, an error

    Mov     byte [PSI+PBX],10h                                                  ;Emit 'r' (10h)
    Inc     PBX
    Jmp     .NORMALRETURN

    .R0:                                                                                                            ; r0
    Call    GetScript700Last                                                    ;Is 'r0' alone?
    JZ      .NORMALERROR                                                        ;   No, an error
    Mov     byte [PSI+PBX],11h                                                  ;Emit 'r0' (11h)
    Inc     PBX
    Jmp     .NORMALRETURN

    .R1:                                                                                                            ; r1
    Call    GetScript700Last                                                    ;Is 'r1' alone?
    JZ      .NORMALERROR                                                        ;   No, an error

    Mov     byte [PSI+PBX],12h                                                  ;Emit 'r1' (12h)
    Inc     PBX
    Jmp     .NORMALRETURN

    .F:                                                                                                             ; f
    Inc     PCX
    Mov     AL,[PCX]
    Cmp     AL,30h                                                              ;'f0'?
    JE      .F0                                                                 ;   Yes
    Cmp     AL,31h                                                              ;'f1'?
    JE      .F1                                                                 ;   Yes
    Dec     PCX                                                                 ;   No, a plain 'f'
    Call    GetScript700Last                                                    ;Is 'f' alone?
    JZ      .NORMALERROR                                                        ;   No, an error

    Mov     byte [PSI+PBX],13h                                                  ;Emit 'f' (13h)
    Inc     PBX
    Jmp     .NORMALRETURN

    .F0:                                                                                                            ; f0
    Call    GetScript700Last                                                    ;Is 'f0' alone?
    JZ      .NORMALERROR                                                        ;   No, an error

    Mov     byte [PSI+PBX],14h                                                  ;Emit 'f0' (14h)
    Inc     PBX
    Jmp     .NORMALRETURN

    .F1:                                                                                                            ; f1
    Call    GetScript700Last                                                    ;Is 'f1' alone?
    JZ      .NORMALERROR                                                        ;   No, an error

    Mov     byte [PSI+PBX],15h                                                  ;Emit 'f1' (15h)
    Inc     PBX
    Jmp     .NORMALRETURN

    .Shp:                                                                                                           ; #
    Test    dword [apuCbMask],CBE_INCS700 | CBE_INCDATA                         ;Does the frontend take include requests?
    JZ      .ShpERROR                                                           ;   No, '#' is an error
    Test    PTRKW [apuCbFunc],-1                                                ;Is a callback installed?
    JZ      .ShpERROR                                                           ;   No, '#' is an error

    Inc     PCX
    Mov     AL,[PCX]
    And     AL,0DFh                                                             ;To upper case
    Cmp     AL,49h                                                              ;'#i'?                              ; #i
    JNE     .ShpERROR                                                           ;   No, an unknown directive

    .ShpI:
    Inc     PCX
    Mov     DL,40h                                                              ;A text include, unless 'b' follows
    Mov     AL,[PCX]
    Cmp     AL,09h                                                              ;TAB after '#i'?
    JE      .ShpI1                                                              ;   Yes, a text include
    Cmp     AL,20h                                                              ;SPACE after '#i'?
    JE      .ShpI1                                                              ;   Yes, a text include

    And     AL,0DFh                                                             ;To upper case
    Cmp     AL,54h                                                              ;'#it'?                             ; #it
    JE      .ShpIT                                                              ;   Yes

    Test    byte [scr700inc+03h],02h                                            ;In the data zone?
    JZ      .ShpERROR                                                           ;   No, '#ib' is only allowed there
    Mov     DL,20h                                                              ;A binary include
    Cmp     AL,42h                                                              ;'#ib'?                             ; #ib
    JE      .ShpIB                                                              ;   Yes
    Jmp     .ShpERROR                                                           ;   No, an unknown directive

    .ShpIT:
    Inc     PCX                                                                 ;Past the 't'

    .ShpI1:
    Test    byte [scr700inc+02h],-1                                             ;Already compiling an included text?
    JNZ     .ShpERROR                                                           ;   Yes, text includes do not nest
    Jmp     .ShpI2

    .ShpIB:
    Inc     PCX                                                                 ;Past the 'b'

    .ShpI2:
    Call    GetScript700Next                                                    ;Find the file name
    JZ      .ShpERROR                                                           ;   None, an error
    Mov     AL,[PCX]
    Cmp     AL,22h                                                              ;Opening quote?
    JNE     .ShpERROR                                                           ;   No, an error

    Mov     [scr700inc],DL                                                      ;Kind of this include (40h text, 20h binary)
    Inc     PCX                                                                 ;Past the quote

    Push    PDI,PCX
    LoadPtr PDI,scr700pth
    XOr     EAX,EAX
    Mov     PCX,64                                                              ;Clear the first 256 bytes of the file name buffer
    Rep     StoSD
    Pop     PCX,PDI

    LoadPtr PDX,scr700pth

    .ShpI3:
    Mov     AL,[PCX]
    Cmp     AL,00h                                                              ;End of the text?
    JE      .ShpERROR                                                           ;   Yes, the name is not closed
    Cmp     AL,0Ah                                                              ;End of the line?
    JE      .ShpERROR                                                           ;   Yes, the name is not closed
    Cmp     AL,0Dh                                                              ;End of the line?
    JE      .ShpERROR                                                           ;   Yes, the name is not closed
    Cmp     AL,22h                                                              ;Closing quote?
    JE      .ShpI4                                                              ;   Yes, the name is complete

    Inc     AH                                                                  ;Name length, at most 255
    JZ      .ShpERROR                                                           ;   Longer, an error
    Mov     [PDX],AL                                                            ;Copy the name
    Inc     PDX
    Inc     PCX
    Jmp     .ShpI3

    .ShpI4:
    Call    GetScript700Last                                                    ;Is the closing quote followed by a separator? (AH is kept)
    JZ      .ShpERROR                                                           ;   No, an error

    IdxSt   Mov,scr700inc,04h,EBX                                               ;Where the included code goes
    Inc     EBX                                                                 ;Default result if the frontend sets none
    IdxSt   Mov,scr700inc,08h,EBX

    MovZX   EDX,byte [scr700inc]                                                ;Event: CBE_INCS700 (40000000h) or CBE_INCDATA (20000000h)
    ShL     EDX,24
    Test    dword [apuCbMask],EDX                                               ;Does the frontend take this kind of include?
    JZ      .ShpERROR                                                           ;   No, an error, before entering include mode

    Mov     AL,[scr700inc]                                                      ;Enter include mode, saving the outer mode in byte 01h
    ShR     word [scr700inc+01h],8
    Mov     [scr700inc+02h],AL

    Push    PDI,PBX,PCX                                                         ;The callback may destroy PAX, PCX and PDX
    Mov     PDI,[apuCbFunc]
    Mov     ECX,[scr700dat]
    Sub     PBX,PCX                                                             ;addr: one past the cursor, relative to the data area
    MovZX   EAX,AH                                                              ;size: length of the file name
    LoadPtr PCX,scr700pth                                                       ;The file name
    ExCall  PDI,EDX,PBX,EAX,PCX                                                 ;Callback(event, addr, size, name)
    Pop     PCX,PBX,PDI

    ShL     word [scr700inc+01h],8                                              ;Back to the outer include mode

    IdxLd   Mov,EDX,scr700inc,08h                                               ;Result of SetScript700 or SetScript700Data, or the default
    Test    EDX,EDX                                                             ;Did it fail?
    JS      .CRITICALERROR                                                      ;   Yes, the whole script fails
    CMovX   NZ,EBX,EDX                                                          ;Continue after the included code

    Dec     PBX                                                                 ;The result is one past the last byte used
    Mov     AH,[scr700inc+03h]
    Dec     AH                                                                  ;Was the include in the EXT zone?
    JZ      .EXTRETURN                                                          ;   Yes
    Dec     AH                                                                  ;In the data zone?
    JZ      .DATARETURN2                                                        ;   Yes
    Jmp     .NORMALRETURN                                                       ;   No, in the script command zone

    .ShpERROR:
    Mov     AH,[scr700inc+03h]
    Dec     AH                                                                  ;Was the error in the EXT zone?
    JZ      .EXTERROR                                                           ;   Yes
    Dec     AH                                                                  ;In the data zone?
    JZ      .DATAERROR                                                          ;   Yes

    .NORMALERROR:
    Mov     PBX,PDI                                                             ;Roll back the code of this line
    Test    byte [PCX],-1                                                       ;End of the text?
    JZ      .EXIT                                                               ;   Yes, finish
    Call    GetScript700NextLine                                                ;Skip the rest of the line
    Jmp     .NORMALRETURN

    ;---------- Extension Command Zone ----------

    .EXTRETURN:

    ;NOTE (x64 port): Array accesses below use IdxSt and IdxLd, which load their own scratch base
    ; pointer per access.  So PSI and PDI keep their usual meaning here, unlike elsewhere in this
    ; proc.
    Call    GetScript700First                                                   ;Find the command on this line
    JZ      .EXTERROR                                                           ;   None, so the line is skipped
    Mov     AL,[PCX]
    Cmp     AL,3Ah                                                              ;'::', the start of the EXT zone?
    JE      .EXLABEL                                                            ;   Yes
    Cmp     AL,23h                                                              ;'#', a directive?
    JE      .Shp                                                                ;   Yes
    And     AL,0DFh                                                             ;To upper case
    Cmp     AL,45h                                                              ;'e', the end of the EXT zone?
    JE      .EXE                                                                ;   Yes
    Cmp     AL,4Dh                                                              ;'m', mute?
    JE      .EXM                                                                ;   Yes
    Cmp     AL,43h                                                              ;'c', change the source?
    JE      .EXC                                                                ;   Yes
    Cmp     AL,44h                                                              ;'d', detune?
    JE      .EXD                                                                ;   Yes
    Cmp     AL,56h                                                              ;'v', volume?
    JE      .EXV                                                                ;   Yes
    Jmp     .EXTERROR                                                           ;   No, an unknown command

    .EXLABEL:                                                                                                       ; ::
    Inc     PCX
    Mov     AL,[PCX]
    Cmp     AL,3Ah                                                              ;Second ':'?
    JNE     .EXTERROR                                                           ;   No, an error

    Call    GetScript700Last                                                    ;Is '::' alone?
    JZ      .EXTERROR                                                           ;   No, an error
    Jmp     .EXTRETURN                                                          ;Already in the EXT zone, so nothing to do

    .EXE:                                                                                                           ; e
    Call    GetScript700Last                                                    ;Is 'e' alone?
    JZ      .EXTERROR                                                           ;   No, an error

    Mov     byte [scr700inc+03h],02h                                            ;Now in the data zone
    Jmp     .DATARETURN

    .EXM:                                                                                                           ; m
    Inc     PCX                                                                 ;Past the 'm'
    Call    GetScript700Next                                                    ;Find the source number
    JZ      .EXTERROR                                                           ;   None, an error

    Mov     AL,[PCX]
    Cmp     AL,21h                                                              ;'!', all sources?
    JE      .EXMALL                                                             ;   Yes
    Call    GetScript700Number
    JZ      .EXTERROR                                                           ;   Not a number, an error

    MovZX   EAX,AL
    IdxSt   XOr byte,scr700dsp,PAX,01h                                          ;Toggle S700_MUTE of the source
    Jmp     .EXTRETURN

    .EXMALL:                                                                                                        ; !
    Call    GetScript700Last                                                    ;Is '!' alone?
    JZ      .EXTERROR                                                           ;   No, an error
    XOr     EDX,EDX

    .EXMALLRETURN:
    IdxSt   XOr dword,scr700dsp,PDX,01010101h                                   ;Toggle S700_MUTE of 4 sources at a time
    Add     EDX,4
    Cmp     EDX,256                                                             ;All 256 sources done?
    JNE     .EXMALLRETURN                                                       ;   No
    Jmp     .EXTRETURN

    .EXC:                                                                                                           ; c
    Inc     PCX                                                                 ;Past the 'c'
    Call    GetScript700Next                                                    ;Find the source number
    JZ      .EXTERROR                                                           ;   None, an error

    Mov     AL,[PCX]
    Cmp     AL,21h                                                              ;'!', all sources?
    JE      .EXCALL                                                             ;   Yes
    Call    GetScript700Number
    JZ      .EXTERROR                                                           ;   Not a number, an error

    Mov     DL,AL                                                               ;Source to change
    Call    GetScript700Next                                                    ;Find the new source number
    JZ      .EXTERROR                                                           ;   None, an error
    Call    GetScript700Number
    JZ      .EXTERROR                                                           ;   Not a number, an error

    MovZX   EDX,DL
    IdxSt   Or byte,scr700dsp,PDX,02h                                           ;Set S700_CHANGE of the source
    IdxSt   Mov,scr700chg,PDX,AL                                                ;The source played instead
    Jmp     .EXTRETURN

    .EXCALL:                                                                                                        ; !
    Inc     PCX                                                                 ;Past the '!'
    Call    GetScript700Next                                                    ;Find the new source number
    JZ      .EXTERROR                                                           ;   None, an error
    Call    GetScript700Number
    JZ      .EXTERROR                                                           ;   Not a number, an error
    XOr     EDX,EDX

    .EXCALLRETURN:
    IdxSt   Or dword,scr700dsp,PDX,02020202h                                    ;Set S700_CHANGE of 4 sources at a time
    IdxSt   Mov,scr700chg,PDX+0,AL                                              ;The source played instead
    IdxSt   Mov,scr700chg,PDX+1,AL
    IdxSt   Mov,scr700chg,PDX+2,AL
    IdxSt   Mov,scr700chg,PDX+3,AL
    Add     EDX,4
    Cmp     EDX,256                                                             ;All 256 sources done?
    JNE     .EXCALLRETURN                                                       ;   No
    Jmp     .EXTRETURN

    .EXD:                                                                                                           ; d
    Inc     PCX                                                                 ;Past the 'd'
    Call    GetScript700Next                                                    ;Find the source number
    JZ      .EXTERROR                                                           ;   None, an error

    Mov     AL,[PCX]
    Cmp     AL,21h                                                              ;'!', all sources?
    JE      .EXDALL                                                             ;   Yes
    Call    GetScript700Number
    JZ      .EXTERROR                                                           ;   Not a number, an error

    Mov     DL,AL                                                               ;Source to detune
    Call    GetScript700Next                                                    ;Find the detune value
    JZ      .EXTERROR                                                           ;   None, an error
    Call    GetScript700Number
    JZ      .EXTERROR                                                           ;   Not a number, an error

    MovZX   EDX,DL
    IdxSt   Or byte,scr700dsp,PDX,04h                                           ;Set S700_DETUNE of the source
    IdxSt   Mov,scr700det,PDX*4,EAX                                             ;Added to the pitch rate
    Jmp     .EXTRETURN

    .EXDALL:                                                                                                        ; !
    Inc     PCX                                                                 ;Past the '!'
    Call    GetScript700Next                                                    ;Find the detune value
    JZ      .EXTERROR                                                           ;   None, an error
    Call    GetScript700Number
    JZ      .EXTERROR                                                           ;   Not a number, an error
    XOr     EDX,EDX

    .EXDALLRETURN:
    IdxSt   Or dword,scr700dsp,PDX,04040404h                                    ;Set S700_DETUNE of 4 sources at a time
    IdxSt   Mov,scr700det,PDX*4+0,EAX                                           ;Added to the pitch rate
    IdxSt   Mov,scr700det,PDX*4+4,EAX
    IdxSt   Mov,scr700det,PDX*4+8,EAX
    IdxSt   Mov,scr700det,PDX*4+12,EAX
    Add     EDX,4
    Cmp     EDX,256                                                             ;All 256 sources done?
    JNE     .EXDALLRETURN                                                       ;   No
    Jmp     .EXTRETURN

    .EXV:                                                                                                           ; v
    Inc     PCX                                                                 ;Past the 'v'
    Call    GetScript700Next                                                    ;Find the target
    JZ      .EXTERROR                                                           ;   None, an error

    XOr     DH,DH                                                               ;DH = 0 for a source, 1 for a master entry
    Mov     AL,[PCX]
    Inc     PCX
    Cmp     AL,21h                                                              ;'!', all sources?
    JE      .EXVALL                                                             ;   Yes
    And     AL,0DFh                                                             ;To upper case
    Cmp     AL,56h                                                              ;'vv', master volume only?
    JE      .EXVV                                                               ;   Yes
    Cmp     AL,45h                                                              ;'ve', echo volume only?
    JE      .EXVE                                                               ;   Yes
    Mov     DL,S700_MVOL_L
    Cmp     AL,4Ch                                                              ;'vl', left master and echo?
    JE      .EXVL                                                               ;   Yes
    Mov     DL,S700_MVOL_R
    Cmp     AL,52h                                                              ;'vr', right master and echo?
    JE      .EXVR                                                               ;   Yes
    Dec     PCX                                                                 ;No letter, so back to the source number
    Call    GetScript700Number
    JZ      .EXTERROR                                                           ;   Not a number, an error

    MovZX   DX,AL                                                               ;Source number, DH = 0
    LoadPtr PAX,.EXTRETURN                                                      ;Where .ENVSET returns to
    Mov     [scr700jmp],PAX

    .ENVSET:
    ShL     EDX,16                                                              ;Keep DX in the upper half while EDX is used below
    Call    GetScript700Next                                                    ;Find the volume
    JZ      .EXTERROR                                                           ;   None, an error
    Call    GetScript700Number
    JZ      .EXTERROR                                                           ;   Not a number, an error

    Push    PDX                                                                 ;(width fix only, not a pointer)
    XOr     EDX,EDX
    Test    EAX,EAX                                                             ;A negative volume becomes 0
    SetS    DL
    Dec     EDX
    And     EAX,EDX
    Pop     PDX                                                                 ;(width fix only, not a pointer)
    ShR     EDX,16                                                              ;DH = 1 reaches the master arrays after the source ones
    IdxSt   Or byte,scr700dsp,PDX,08h                                           ;Set S700_VOLUME of the entry
    IdxSt   Mov,scr700vol,PDX*4,EAX                                             ;The volume
    Jmp     [scr700jmp]

    .EXVL:
    Mov     AL,[PCX]
    And     AL,0DFh                                                             ;To upper case
    Cmp     AL,52h                                                              ;'vlr', all four?
    JE      .EXVLR                                                              ;   Yes

    .EXVR:
    Inc     DH
    LoadPtr PAX,.EXVLR3                                                         ;Then set the echo volume too
    Mov     [scr700jmp],PAX
    Jmp     .ENVSET

    .EXVLR:
    Inc     PCX                                                                 ;Past the 'r'
    Inc     DH
    LoadPtr PAX,.EXVLR2                                                         ;Then set the other three too
    Mov     [scr700jmp],PAX
    Jmp     .ENVSET

    .EXVLR2:
    IdxSt   Or dword,scr700dsp,PDX,08080808h                                    ;Set S700_VOLUME of all four master entries
    IdxSt   Mov,scr700vol,PDX*4+4,EAX                                           ;S700_MVOL_R
    IdxSt   Mov,scr700vol,PDX*4+12,EAX                                          ;S700_ECHO_R

    .EXVLR3:
    IdxSt   Or byte,scr700dsp,PDX+2,08h                                         ;The echo volume on the same side
    IdxSt   Mov,scr700vol,PDX*4+8,EAX
    Jmp     .EXTRETURN

    .EXVALL:
    Call    GetScript700Next                                                    ;Find the volume
    JZ      .EXTERROR                                                           ;   None, an error
    Call    GetScript700Number
    JZ      .EXTERROR                                                           ;   Not a number, an error

    XOr     EDX,EDX
    Test    EAX,EAX                                                             ;A negative volume becomes 0
    SetS    DL
    Dec     EDX
    And     EAX,EDX
    XOr     EDX,EDX

    .EXVALLRETURN:
    IdxSt   Or dword,scr700dsp,PDX,08080808h                                    ;Set S700_VOLUME of 4 sources at a time
    IdxSt   Mov,scr700vol,PDX*4+0,EAX                                           ;The volume
    IdxSt   Mov,scr700vol,PDX*4+4,EAX
    IdxSt   Mov,scr700vol,PDX*4+8,EAX
    IdxSt   Mov,scr700vol,PDX*4+12,EAX
    Add     EDX,4
    Cmp     EDX,256                                                             ;All 256 sources done?
    JNE     .EXVALLRETURN                                                       ;   No
    Jmp     .EXTRETURN

    .EXVV:
    Mov     AL,[PCX]
    And     AL,0DFh                                                             ;To upper case
    Mov     DL,S700_MVOL_L
    Cmp     AL,4Ch                                                              ;'vvl'?
    JE      .EXVCMD                                                             ;   Yes
    Mov     DL,S700_MVOL_R
    Cmp     AL,52h                                                              ;'vvr'?
    JE      .EXVCMD                                                             ;   Yes
    Jmp     .EXTERROR                                                           ;   No, an error

    .EXVE:
    Mov     AL,[PCX]
    And     AL,0DFh                                                             ;To upper case
    Mov     DL,S700_ECHO_L
    Cmp     AL,4Ch                                                              ;'vel'?
    JE      .EXVCMD                                                             ;   Yes
    Mov     DL,S700_ECHO_R
    Cmp     AL,52h                                                              ;'ver'?
    JE      .EXVCMD                                                             ;   Yes
    Jmp     .EXTERROR                                                           ;   No, an error

    .EXVCMD:
    Inc     PCX                                                                 ;Past the 'l' or 'r'
    Inc     DH
    LoadPtr PAX,.EXTRETURN                                                      ;Where .ENVSET returns to
    Mov     [scr700jmp],PAX
    Jmp     .ENVSET

    .EXTERROR:
    Test    byte [PCX],-1                                                       ;End of the text?
    JZ      .EXIT                                                               ;   Yes, finish
    Call    GetScript700NextLine                                                ;Skip the rest of the line
    Jmp     .EXTRETURN

    ;---------- Data Command Zone ----------

    .DATARETURN:
    XOr     AH,AH
    Mov     PDI,PBX                                                             ;The data must not wrap back below this
    Mov     [PSI+PBX],AH                                                        ;End the program with 'q'
    Mov     [scr700dat],EBX                                                     ;The data area starts after it
    Inc     dword [scr700dat]
    Call    GetScript700First                                                   ;Skip the blanks after 'e'

    .DATARETURN2:
    Mov     DL,AH                                                               ;Expect the high digit of a byte

    .DATARETURNLINE:
    Mov     AL,[PCX]
    Cmp     AL,00h                                                              ;End of the text?
    JE      .EXIT                                                               ;   Yes, finish
    Cmp     AL,3Ah                                                              ;':', a label?
    JE      .DATALABEL                                                          ;   Yes
    Cmp     AL,23h                                                              ;'#', a directive?
    JE      .Shp                                                                ;   Yes
    Inc     PCX
    Cmp     AL,0Ah                                                              ;End of the line?
    JE      .DATANEWLINE                                                        ;   Yes
    Cmp     AL,0Dh                                                              ;End of the line?
    JE      .DATANEWLINE                                                        ;   Yes
    Cmp     AL,09h                                                              ;TAB?
    JE      .DATARETURNLINE                                                     ;   Yes, skip it
    Cmp     AL,20h                                                              ;SPACE?
    JE      .DATARETURNLINE                                                     ;   Yes, skip it
    Sub     AL,30h
    Cmp     AL,10                                                               ;'0' to '9'?
    JB      .DATANUM                                                            ;   Yes
    Sub     AL,11h
    Cmp     AL,6                                                                ;'A' to 'F'?
    JB      .DATAHEX                                                            ;   Yes
    Sub     AL,20h
    Cmp     AL,6                                                                ;'a' to 'f'?
    JB      .DATAHEX                                                            ;   Yes
    Dec     PCX
    Call    GetScript700NextLine                                                ;Anything else ends the line, as a comment
    Jmp     .DATARETURNLINE

    .DATALABEL:
    Inc     PCX                                                                 ;Past the ':'
    Call    GetScript700Number                                                  ;Label number                       ; :[LABEL]
    JZ      .DATAERROR                                                          ;   Not a number, an error

    And     EAX,1023                                                            ;Labels wrap at 1024
    Mov     EDX,EBX                                                             ;Offset of the next byte in the data area
    Sub     EDX,[scr700dat]
    Inc     EDX
    Or      EDX,80000000h                                                       ;Bit 31 keeps branches from jumping to it
    IdxSt   Mov,scr700lbl,PAX*4,EDX

    .DATANEWLINE:
    XOr     AH,AH                                                               ;A digit left alone before a line break is dropped
    Jmp     .DATARETURN2

    .DATAHEX:
    Add     AL,10                                                               ;Value of the hex digit A to F

    .DATANUM:
    Dec     DL                                                                  ;The low digit?
    JZ      .DATANUM2                                                           ;   Yes

    ShL     AX,12                                                               ;The high digit into AH, as 'Mov AH,AL' and 'ShL AH,4'
    Add     DL,2                                                                ;Expect the low digit
    Jmp     .DATARETURNLINE

    .DATANUM2:
    Or      AH,AL                                                               ;The byte is complete
    Inc     PBX
    And     PBX,SCR700MASK
    Cmp     PBX,PDI                                                             ;Wrapped around the Script700 area?
    JB      .CRITICALERROR                                                      ;   Yes, the data does not fit

    Mov     [PSI+PBX],AH
    Mov     PDI,PBX
    Jmp     .DATARETURNLINE

    .DATAERROR:
    Test    byte [PCX],-1                                                       ;End of the text?
    JZ      .EXIT                                                               ;   Yes, finish
    Call    GetScript700NextLine                                                ;Skip the rest of the line
    XOr     AH,AH                                                               ;Drop a digit left alone
    Jmp     .DATARETURN2

    ;---------- Error ----------

    .CRITICALERROR:
    XOr     EAX,EAX
    Test    byte [scr700inc+02h],-1                                             ;Compiling an included text?
    JNZ     .NORESET                                                            ;   Yes, the including script disables it
        Mov     [PSI],AL                                                        ;Disable the program with 'q' at the start
        Mov     [scr700dat],EAX                                                 ;No data area, so SetScript700Data writes nothing

    .NORESET:
    Test    PCX,PCX                                                             ;No text, so only disabling Script700?
    SetZ    AL
    Dec     EAX                                                                 ;0 if so, -1 for an error
    Jmp     .FINALIZE

    ;---------- Finalize ----------

    .EXIT:
    Mov     EAX,EBX                                                             ;Result: the end of the program memory used
    Inc     EAX
    Test    byte [scr700inc+02h],-1                                             ;Compiling an included text?
    JNZ     .FINALIZE                                                           ;   Yes, the including script ends the program

    Mov     ECX,[scr700dat]
    Test    ECX,ECX                                                             ;Is there a data area?
    JNZ     .FINALIZE                                                           ;   Yes, the program already ends with 'q'

    Mov     [PSI+PBX],CL                                                        ;End the program with 'q'
    Mov     [scr700dat],EAX                                                     ;An empty data area after it

    .FINALIZE:
    IdxSt   Mov,scr700inc,08h,EAX                                               ;Also the result for an including script

ENDP


;===================================================================================================
;Set Script700 Binary Data Function

EXPROC SetScript700Data, addr, pData, size

    Mov     PAX,[pData]
    Test    PAX,PAX                                                             ;No data?
    JZ      .FINALIZE                                                           ;   Yes, return 0 and change nothing

    Mov     EAX,[scr700dat]
    Test    EAX,EAX                                                             ;No data area (no script, a failure, or TimerTrick)?
    JZ      .CRITICALERROR                                                      ;   Yes, writing would reach the program
    Add     EAX,[addr]                                                          ;End of the range, with addr and size unsigned
    JC      .CRITICALERROR                                                      ;   Past 4 GB, an error
    Add     EAX,[size]
    JC      .CRITICALERROR                                                      ;   Past 4 GB, an error
    Cmp     EAX,SCR700SIZE                                                      ;Past the Script700 area?
    JA      .CRITICALERROR                                                      ;   Yes, an error

    Push    PDI,PSI,PCX

    Mov     PDI,[pSCRRAM]                                                       ;Destination: the data area + addr
    Mov     EAX,[scr700dat]
    Add     PDI,PAX
    Mov     EAX,[addr]
    Add     PDI,PAX
    Mov     PSI,[pData]

    Mov     ECX,[size]                                                          ;Copy by dwords, then the rest by bytes
    ShR     ECX,2
    Rep     MovSD

    Mov     ECX,[size]
    And     ECX,3
    Rep     MovSB

    Mov     PAX,PDI                                                             ;Result: the end of the data written
    Sub     PAX,[pSCRRAM]

    Pop     PCX,PSI,PDI
    Jmp     .FINALIZE

    .CRITICALERROR:
    Mov     EAX,-1                                                              ;-1 for an error

    .FINALIZE:
    IdxSt   Mov,scr700inc,08h,EAX                                               ;Also the result for an including script

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

    Add     EAX,ECX

    LoadPtr PCX,dspVarEP                                                        ;PCX = Variable size of DSP.asm
    LblOp   Sub,PCX,mix
    And     ECX,0FFFFFFFCh
    Add     ECX,4

    Add     EAX,ECX

    LoadPtr PCX,spcVarEP                                                        ;PCX = Variable size of SPC700.asm
    LblOp   Sub,PCX,extraRAM
    And     ECX,0FFFFFFFCh
    Add     ECX,4

    Add     EAX,ECX

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
