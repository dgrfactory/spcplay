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
;                                                   Copyright (C) 2003-2020 degrade-factory
;===================================================================================================

CPU		386
BITS	32

;===================================================================================================
;Header files

%include "macro.inc"
%include "SNESAPU.inc"
%include "SPC700.inc"
%include "DSP.inc"
%define	INTERNAL
%include "APU.inc"


;===================================================================================================
; Data

%ifndef WIN32
SECTION .data ALIGN=256
%else
SECTION .data ALIGN=32
%endif

; ----- degrade-factory code [2019/07/15] -----
	apuOpt		DD	(CPU_CYC << 24) | (DEBUG << 16) | (DSPINTEG << 17) | (VMETERM << 8) | (VMETERV << 9) | (1 << 10) | (STEREO << 11) \
					| (HALFC << 1) | (CNTBK << 2) | (SPEED << 3) | (IPLW << 4) | (DSPBK << 5) | (INTBK << 6)
	apuDllVer	DD	21861h														;SNESAPU.DLL Current Version
	apuCmpVer	DD	11000h														;SNESAPU.DLL Backwards Compatible Version
	apuVerStr	DD	"2.18.1 (build 6862)"										;SNESAPU.DLL Current Version (32byte String)
				DD	8
; ----- degrade-factory code [END] -----


;===================================================================================================
; Variables

%ifndef WIN32
SECTION .bss ALIGN=256
%else
SECTION .bss ALIGN=64
%endif

;Don't touch!  All arrays are carefully aligned on large boundaries to facillitate easier indexing
;and better cache utilization.

; ----- degrade-factory code [2013/10/06] -----
	apuRAMBuf	resb	APURAMSIZE*2+16											;SNESAPU 64KB APU RAM Buffer
	scrRAMBuf	resb	SCR700SIZE+16											;Script700 RAM Buffer

	scr700lbl	resd	1024													;Script700 Label Work Area
	scr700dsp	resb	256														;Script700 DSP Enable Flag (Source)
	scr700mds	resb	32														;Script700 DSP Enable Flag (Master)
	scr700det	resd	256														;Script700 DSP Rate Detune
	scr700chg	resb	256														;Script700 DSP Note Change
	scr700vol	resd	256														;Script700 DSP Volume Change (Source)
	scr700mvl	resd	32														;Script700 DSP Volume Change (Master)

	scr700wrk	resd	8														;Script700 User Work Area
	scr700cmp	resd	2														;Script700 Cmp Param
	scr700cnt	resd	1														;Script700 Wait Count
	scr700ptr	resd	1														;Script700 Program Pointer
	scr700stf	resd	1														;Script700 Stack Flag

	scr700dat	resd	1														;Script700 Data Area Offset
	scr700stp	resd	1														;Script700 Stack Pointer
	scr700jmp	resd	1														;Script700 Jump Address
	scr700tmp	resd	1														;Script700 Temporary
	scr700stk	resd	128														;Script700 Stack Area
	scr700inc	resd	3														;Script700 Include Depth
	scr700pth	resd	256														;Script700 Include Path

	pAPURAM		resd	1														;Pointer to SNESAPU 64KB RAM
	pSCRRAM		resd	1														;Pointer to Script700 RAM
	cycLeft		resd	1														;Clock cycles left to emulate in EmuAPU loop
	smpDec		resd	1														;Unused clocks from cycle to sample conversion
	smpRate		resd	1														;Sample rate
	smpRAdj		resd	1														;Sample rate adjustment (16.16)
	smpREmu		resd	1														;Number of emulated samples per second

	apuCbMask	resd	1														;SNESAPU callback mask
	apuCbFunc	resd	1														;SNESAPU callback function
; ----- degrade-factory code [END] -----

; ----- degrade-factory code [2015/07/11] -----
	apuVarEP	resd	1														;Endpoint of APU.asm variable
; ----- degrade-factory code [END] -----


;===================================================================================================
; Code

%ifndef WIN32
SECTION .text ALIGN=256
%else
SECTION .text ALIGN=16
%endif


; ----- degrade-factory code [2013/10/12] -----
;===================================================================================================
;Initialize Audio Processing Unit

PROC InitAPU, reason

	Mov		EAX,[reason]
	Dec		EAX																	;reason = DLL_PROCESS_ATTACH (1)?
	JNZ		short .Quit															;	No

	Mov		EAX,apuRAMBuf
	Add		EAX,0FFFFh
	XOr		AX,AX
	Mov		[pAPURAM],EAX

	Add		EAX,10000h
	Mov		EDI,EAX
	XOr		EAX,EAX
	Mov		ECX,12
	Rep		StoSD

	Mov		[scr700inc],EAX
	Mov		[apuCbMask],EAX
	Mov		[apuCbFunc],EAX

	Mov		EAX,scrRAMBuf
	Mov		[pSCRRAM],EAX

	Call	InitSPC
	Call	InitDSP

	Mov		dword [smpRate],32000
	Mov		dword [smpRAdj],10000h

	Call	SetAPUSmpClk,[smpRAdj]

	Call	ResetAPU,10000h														;Reset APU
	Call	SetScript700,0														;Reset Script700

	.Quit:
	Mov		EAX,1																;Return TRUE

ENDP


;===================================================================================================
;Get SNESAPU.DLL Version Information

PROC SNESAPUInfo, pVer, pMin, pOpt
USES EBX

	Mov		EBX,[pVer]
	Test	EBX,EBX
	JZ		short .pVerNext
		Mov		EAX,[apuDllVer]
		Mov		[EBX],EAX
	.pVerNext:

	Mov		EBX,[pMin]
	Test	EBX,EBX
	JZ		short .pMinNext
		Mov		EAX,[apuCmpVer]
		Mov		[EBX],EAX
	.pMinNext:

	Mov		EBX,[pOpt]
	Test	EBX,EBX
	JZ		short .pOptNext
		Mov		EAX,[apuOpt]
		Mov		[EBX],EAX
	.pOptNext:

ENDP


;===================================================================================================
;Set/Reset SNESAPU Callback Function

PROC SNESAPUCallback, pCbFunc, cbMask
USES EBX

	Mov		EAX,[apuCbFunc]

	Mov		EBX,[pCbFunc]
	Mov		[apuCbFunc],EBX

	Mov		EBX,[cbMask]
	Or		[apuCbMask],EBX														;OR method for chain call

ENDP


;===================================================================================================
;Get SNESAPU Data Pointers

PROC GetAPUData, ppRAM, ppXRAM, ppOutPort, ppT64Cnt, ppDSP, ppVoice, ppVMMaxL, ppVMMaxR
USES EBX

	Mov		EBX,[ppRAM]
	Test	EBX,EBX
	JZ		short .ppRAMNext
		Mov		EAX,[pAPURAM]
		Mov		[EBX],EAX
	.ppRAMNext:

	Mov		EBX,[ppXRAM]
	Test	EBX,EBX
	JZ		short .ppXRAMNext
		Mov		EAX,extraRAM
		Mov		[EBX],EAX
	.ppXRAMNext:

	Mov		EBX,[ppOutPort]
	Test	EBX,EBX
	JZ		short .ppOutPortNext
		Mov		EAX,outPort
		Mov		[EBX],EAX
	.ppOutPortNext:

	Mov		EBX,[ppT64Cnt]
	Test	EBX,EBX
	JZ		short .ppT64CntNext
		Mov		EAX,t64Cnt
		Mov		[EBX],EAX
	.ppT64CntNext:

	Mov		EBX,[ppDSP]
	Test	EBX,EBX
	JZ		short .ppDSPNext
		Mov		EAX,dsp
		Mov		[EBX],EAX
	.ppDSPNext:

	Mov		EBX,[ppVoice]
	Test	EBX,EBX
	JZ		short .ppVoiceNext
		Mov		EAX,mix
		Mov		[EBX],EAX
	.ppVoiceNext:

	Mov		EBX,[ppVMMaxL]
	Test	EBX,EBX
	JZ		short .ppVMMaxLNext
		Mov		EAX,vMMaxL
		Mov		[EBX],EAX
	.ppVMMaxLNext:

	Mov		EBX,[ppVMMaxR]
	Test	EBX,EBX
	JZ		short .ppVMMaxRNext
		Mov		EAX,vMMaxR
		Mov		[EBX],EAX
	.ppVMMaxRNext:

ENDP


;===================================================================================================
;Get Script700 Data Pointers

PROC GetScript700Data, pDLLVer, ppSPCReg, ppScript700
USES EBX

	Mov		EBX,[pDLLVer]
	Test	EBX,EBX
	JZ		short .pDLLVerNext
		Mov		EAX,[apuVerStr+00h]
		Mov		[EBX+00h],EAX
		Mov		EAX,[apuVerStr+04h]
		Mov		[EBX+04h],EAX
		Mov		EAX,[apuVerStr+08h]
		Mov		[EBX+08h],EAX
		Mov		EAX,[apuVerStr+0Ch]
		Mov		[EBX+0Ch],EAX
		Mov		EAX,[apuVerStr+10h]
		Mov		[EBX+10h],EAX
		Mov		EAX,[apuVerStr+14h]
		Mov		[EBX+14h],EAX
		Mov		EAX,[apuVerStr+18h]
		Mov		[EBX+18h],EAX
		Mov		EAX,[apuVerStr+1Ch]
		Mov		[EBX+1Ch],EAX
	.pDLLVerNext:

	Mov		EBX,[ppSPCReg]
	Test	EBX,EBX
	JZ		short .ppSPCRegNext
		Mov		EAX,[pSPCReg]
		Mov		[EBX],EAX
	.ppSPCRegNext:

	Mov		EBX,[ppScript700]
	Test	EBX,EBX
	JZ		short .ppScript700Next
		Mov		EAX,scr700wrk
		Mov		[EBX],EAX
	.ppScript700Next:

ENDP
; ----- degrade-factory code [END] -----


;===================================================================================================
;Reset Audio Processor

PROC ResetAPU, amp

	Call	ResetSPC
	Call	ResetDSP

	Cmp		dword [amp],-1
	JE		short .NoAmp
		Call	SetDSPAmp,[amp]
	.NoAmp:

	Mov		dword [cycLeft],0
	Mov		dword [smpDec],0

ENDP


;===================================================================================================
;Fix Audio Processor After Load

PROC FixAPU, pc, a, y, x, psw, s

	Call	FixSPC,[pc],[a],[y],[x],[psw],[s]
	Call	FixDSP

ENDP


;===================================================================================================
;Load SPC File

PROC LoadSPCFile, pFile
USES ECX,ESI,EDI

	Call	ResetAPU,-1

	Mov		ESI,[pFile]

	Add		ESI,100h															;memcpy(&apuRAM, &spc[0x100], 0x10000)
	Mov		EDI,[pAPURAM]
	Mov		ECX,4000h
	Rep		MovSD

	Mov		EDI,dsp																;memcpy(&dsp, &spc[0x10100], 128)
	Mov		ECX,32
	Rep		MovSD

	Add		ESI,40h																;memcpy(&xram, &spc[0x101C0], 64)
	Mov		EDI,extraRAM
	Mov		ECX,16
	Rep		MovSD

	Mov		ESI,[pFile]
	XOr		EAX,EAX
	Mov		AL,[2Bh+ESI]														;SP
	Push	EAX
	Mov		AL,[2Ah+ESI]														;PSW
	Push	EAX
	Mov		AL,[28h+ESI]														;X
	Push	EAX
	Mov		AL,[29h+ESI]														;Y
	Push	EAX
	Mov		AL,[27h+ESI]														;A
	Push	EAX
	Mov		AX,[25h+ESI]														;PC
	Push	EAX
	Call	FixAPU

ENDP


;===================================================================================================
;Set Audio Processor Options

PROC SetAPUOpt, mixType, numChn, bits, rate, inter, opts

	Mov		EAX,[rate]															;Is a rate specified?
	Cmp		EAX,-1																;If rate != -1
	JE		short .KeepRate

		Cmp		EAX,8000														;If rate < 8000, rate = 8000
		JAE		short .OKL
			Mov		EAX,8000
		.OKL:

		Cmp		EAX,192000														;If rate > 192000, rate = 192000
		JBE		short .OKH
			Mov		EAX,192000
		.OKH:

		Mov		[smpRate],EAX
		Call	SetAPUSmpClk,[smpRAdj]											;Calculate the number of clock cycles per sample

	.KeepRate:
	Call	SetDSPOpt,[mixType],[numChn],[bits],[rate],[inter],[opts]			;Set options in DSP emulator

ENDP


;===================================================================================================
;Set Audio Processor Sample Clock

PROC SetAPUSmpClk, speed
USES EDX

; ----- degrade-factory code [2004/08/16] -----
	Mov		EAX,[speed]
	Cmp		EAX,4096															;If speed < 4096, speed = 4096
	JAE		short .OKL
		Mov		EAX,4096
	.OKL:
; ----- degrade-factory code [END] -----

	Cmp		EAX,1048576															;If speed > 1048576, speed = 1048576
	JBE		short .OKH
		Mov		EAX,1048576
	.OKH:
	Mov		[smpRAdj],EAX

	Mov		EAX,[smpRate]														;smpREmu = (smpRate << 16) / smpRAdj;
	MovZX	EDX,word [2+smpRate]
	ShL		EAX,16
	Div		dword [smpRAdj]
	Mov		[smpREmu],EAX

ENDP


;===================================================================================================
;Set Audio Processor Song Length

PROC SetAPULength

	Jmp		SetDSPLength

ENDP


;===================================================================================================
;Emulate Audio Processing Unit

PROC EmuAPU, pBuf, len, type
USES ECX,EDX,EBX,EDI

	Mov		ECX,APU_CLK

%if DSPINTEG
	;Fixup samples/cycles --------------------
	Test	byte [type],-1
	JZ		short .Cycles
		Call	SetEmuDSP,[pBuf],[len],[smpREmu]

		Mov		EAX,[len]
		Mul		ECX																;cycles = (APU_CLK * len) / smpREmu
		Div		dword [smpREmu]
		Add		EAX,[cycLeft]
		JLE		short .NoCycles
		Jmp		short .Samples

	.Cycles:
		Mov		EAX,[len]
		Add		EAX,[cycLeft]
		JLE		short .NoCycles

		Push	EAX
		Mul		dword [smpREmu]													;samples = (smpREmu * len) / APU_CLK
		Div		ECX
		Call	SetEmuDSP,[pBuf],EAX,[smpREmu]
		Pop		EAX

	.Samples:

	;Emulate APU -----------------------------
	Call	EmuSPC,EAX

	.NoCycles:
	Mov		[cycLeft],EAX
	Call	SetEmuDSP,0,0,0														;Create any remaining samples

%else

	;If samples were passed, convert to clock cycles
	Mov		EAX,[len]
	Cmp		byte [type],0
	JZ		short .Cycles
		Mul		ECX																;cycles = (APU_CLK * len) / smpREmu
		Div		dword [smpREmu]
	.Cycles:
	Add		[cycLeft],EAX

	;Emulate APU -----------------------------
	XOr		EBX,EBX																;Number of samples generated
	Mov		EDI,[pBuf]

	.Next:
		Mov		EAX,[cycLeft]
		Test	EAX,EAX
		JLE		short .Done

		;SPC700 -------------------------------
		Mov		EDX,EAX
		Call	EmuSPC,EAX
		Mov		[cycLeft],EAX

		;DSP ----------------------------------
		Sub		EDX,EAX															;Calculate number of samples to create
		Mov		EAX,EDX															;EAX = number of cycles emulated
		Mul		dword [smpREmu]
		Add		EAX,[smpDec]
		AdC		EDX,0
		Div		ECX																;samples = (((cycles - cycLeft) * smpREmu) + smpDec) / APU_CLK
		Mov		[smpDec],EDX

		Add		EBX,EAX															;size += samples
		Cmp		EBX,[len]														;Sometimes sample count will go over by one
		JBE		short .LenOK
			Add		EAX,[len]
			Sub		EAX,EBX
			Mov		EBX,[len]
		.LenOK:

		Call	EmuDSP,EDI,EAX													;pBuf = EmuDSP(pBuf,samples)
		Mov		EDI,EAX
		Jmp		short .Next

	.Done:

	;Make sure enough samples were created to fill buffer
	Cmp		byte [type],0														;If (type && size<len), EmuDSP(pBuf, len-size)
	Mov		EDX,[len]
	SetNZ	AL
	Sub		EDX,EBX
	SetG	AH
	Test	AL,AH
	RetZ	EDI

	Call	EmuDSP,EAX,EDX
%endif

ENDP


;===================================================================================================
;Seek to Position

PROC SeekAPU, time, fast
USES ECX,EDX

	XOr		EDX,EDX
	Mov		EAX,[time]															;numSeconds = time / 64000
	Test	EAX,EAX
	RetZF
	Mov		ECX,64000
	Div		ECX
	Mov		ECX,EAX
	IMul	EDX,APU_CLK/64000													;EDX = (time % 64000) * (APU_CLK / 64000)

	Test	byte [fast],-1														;Fast mode completely bypasses the DSP emulation
	JZ		short .Slow
; ----- degrade-factory code [2006/03/21] -----
		Call	SetSPCDbg,-1,SPC_NODSP											;Disable writes to the DSP registers

		Test	EDX,EDX
		JZ		short .EmuSPC

		Call	EmuSPC,EDX
		Test	ECX,ECX
		JZ		short .DoneSeek

		.EmuSPC:
			Call	EmuSPC,APU_CLK
		Dec		ECX
		JNZ		short .EmuSPC

		.DoneSeek:
		Call	SetSPCDbg,-1,0													;Re-enable writes to the DSP registers
		Jmp		short .Done
; ----- degrade-factory code [END] -----

	.Slow:
		Test	EDX,EDX
		JZ		short .EmuAPU

		Call	EmuAPU,0,EDX,0
		Test	ECX,ECX
		JZ		short .Done

		.EmuAPU:
			Call	EmuAPU,0,APU_CLK,0
		Dec		ECX
		JNZ		short .EmuAPU

	.Done:
	Call	FixSeek,[fast]														;Fixup DSP after seeking

ENDP


; ----- degrade-factory code [2015/12/12] -----
;===================================================================================================
;Set/Reset TimerTrick Compatible Function

PROC SetTimerTrick, port, wait
USES ECX,ESI

	Mov		CL,[scr700inc+02h]
	Test	CL,CL																;Include mode?
	JNZ		short .EXIT															;	Yes

	Call	SetScript700,0														;Reset Script700
	Mov		ECX,[wait]															;ECX = wait
	Test	ECX,ECX																;ECX = 0x00?
	JZ		short .EXIT															;	Yes
		;---------- TimerTrick -> Script700 binary converter ----------

		Mov		ESI,[pSCRRAM]													;ESI = Script RAM Pointer
		Mov		[ESI+02h],ECX													;Program[0x02] = ECX
		Mov		CL,[port]														;CL = port
		Mov		[ESI+0Eh],CL													;Program[0x0E] = CL

		;-------------------------------------------------------------------------------
		; [Script700 Command]       [Binary]
		; :0	w	(WAIT)		->	0x00 : 0x01 0x00 ???? ???? ???? ????
		;		a	#1	i(PORT)	->  0x06 : 0x04 0x00 0x00 0x01 0x00 0x00 0x00 0x02 ????
		;		bra	0			->  0x0F : 0x05 0x00 0x00
		;		(EXIT)			->  0x14 : 0x00
		;-------------------------------------------------------------------------------

		Mov		word  [ESI+00h],0001h
		Mov		dword [ESI+06h],01000004h
		Mov		dword [ESI+0Ah],02000000h
		Mov		dword [ESI+0Fh],00000005h
		Mov		dword [scr700lbl],0
	.EXIT:

ENDP


;===================================================================================================
;Seek First Command
;   Uses: DH, AL
;   Z flag: OFF=Success, ON=Failure

PROC GetScript700First

	XOr		DH,DH																;DH = 0x00

	.RETURN:
	Mov		AL,[ECX]															;AL = [ECX]
	Cmp		AL,00h																;Is char NULL?
	JE		short .ERROR														;	Yes
	Cmp		AL,09h																;Is char TAB?
	JE		short .NEXT															;	Yes
	Cmp		AL,0Ah																;Is char RETURN?
	JE		short .ERROR														;	Yes
	Cmp		AL,0Dh																;Is char RETURN?
	JE		short .ERROR														;	Yes
	Cmp		AL,20h																;Is char SPACE?
	JE		short .NEXT															;	Yes
	Or		DH,01h																;DH = 0x01 (Success)
	Jmp		short .EXIT

	.NEXT:
	Inc		ECX																	;ECX++
	Jmp		short .RETURN

	.ERROR:
	XOr		DH,DH																;DH = 0x00 (Failure)

	.EXIT:
	Test	DH,DH																;DH = 0x00 (Failure)?

ENDP


;===================================================================================================
;Seek Next Command/Parameter
;   Uses: DH, AL
;   Z flag: OFF=Success, ON=Failure

PROC GetScript700Next

	XOr		DH,DH																;DH = 0x00

	.RETURN:
	Mov		AL,[ECX]															;AL = [ECX]
	Cmp		AL,00h																;Is char NULL?
	JE		short .ERROR														;	Yes
	Cmp		AL,09h																;Is char TAB?
	JE		short .NEXT															;	Yes
	Cmp		AL,0Ah																;Is char RETURN?
	JE		short .ERROR														;	Yes
	Cmp		AL,0Dh																;Is char RETURN?
	JE		short .ERROR														;	Yes
	Cmp		AL,20h																;Is char SPACE?
	JE		short .NEXT															;	Yes
	Jmp		short .EXIT

	.NEXT:
	Inc		ECX																	;ECX++
	Or		DH,01h																;DH = 0x01 (Success)
	Jmp		short .RETURN

	.ERROR:
	XOr		DH,DH																;DH = 0x00 (Failure)

	.EXIT:
	Test	DH,DH																;DH = 0x00 (Failure)?

ENDP


;===================================================================================================
;Skip Next Command/Parameter
;   Uses: AL

PROC GetScript700Skip

	.RETURN:
	Mov		AL,[ECX]															;AL = [ECX]
	Cmp		AL,00h																;Is char NULL?
	JE		short .EXIT															;	Yes
	Cmp		AL,09h																;Is char TAB?
	JE		short .EXIT															;	Yes
	Cmp		AL,20h																;Is char SPACE?
	JE		short .EXIT															;	Yes
	Inc		ECX																	;ECX++
	Jmp		short .RETURN

	.EXIT:

ENDP


;===================================================================================================
;Seek Next Line
;   Uses: DH, AL

PROC GetScript700NextLine

	.RETURN:
	Mov		AL,[ECX]															;AL = [ECX]
	Cmp		AL,00h																;Is char NULL?
	JE		short .EXIT															;	Yes
	Cmp		AL,0Ah																;Is char RETURN?
	JE		short .NEXT2														;	Yes
	Cmp		AL,0Dh																;Is char RETURN?
	JE		short .NEXT2														;	Yes
	Inc		ECX																	;ECX++
	Jmp		short .RETURN

	.NEXT:
	Mov		AL,[ECX]															;AL = [ECX]
	Cmp		AL,00h																;Is char NULL?
	JE		short .EXIT															;	Yes
	Cmp		AL,0Ah																;Is char RETURN?
	JE		short .NEXT2														;	Yes
	Cmp		AL,0Dh																;Is char RETURN?
	JE		short .NEXT2														;	Yes
	Jmp		short .EXIT

	.NEXT2:
	Inc		ECX																	;ECX++
	Jmp		short .NEXT

	.EXIT:

ENDP


;===================================================================================================
;Parse Number (Supported DEC or HEX, and Minus)
;   EAX = Number of Result
;   Uses: DH
;   Z flag: OFF=Success, ON=Failure

PROC GetScript700Number

	Push	EBX
	XOr		EAX,EAX																;EAX = 0x00
	XOr		EBX,EBX																;EBX = 0x00
	XOr		DH,DH																;DH = 0x00

	Mov		BL,[ECX]															;BL = [ECX]
	Cmp		BL,2Bh																;Is char "+"?
	JE		short .NOP															;	Yes
	Cmp		BL,2Dh																;Is char "-"?
	JE		short .MINUS														;	Yes

	.RETURNFIRST:
	Cmp		BL,30h																;Is char "0"?
	JE		short .HEXZ															;	Yes
	Cmp		BL,24h																;Is char "$"?
	JE		short .HEXOK														;	Yes

	.RETURN:
	Mov		BL,[ECX]															;BL = Char
	Sub		BL,30h																;BL -= 0x30
	Cmp		BL,10																;BL >= 10? (Is not char "0" to "9"?)
	JAE		short .HEXCHECK														;	Yes
	Jmp		short .RETURNNEXT

	.HEXCHECKNEXT:
	Add		BL,10																;BL += 10

	.RETURNNEXT:
	Test	DH,04h																;DH &= 0x04? (HEX mode?)
	JNZ		short .SETHEX														;	Yes
		LEA		EAX,[EAX+EAX*4]													;EAX *= 5
		Add		EAX,EAX															;EAX += EAX							;(EAX *= 10)
		Jmp		short .SETOK

	.SETHEX:
		ShL		EAX,4															;EAX << 4

	.SETOK:
	Add		EAX,EBX																;EAX += EBX
	Inc		ECX																	;ECX++
	Or		DH,01h																;DH |= 0x01 (Success)
	Jmp		short .RETURN

	.MINUS:
	Or		DH,02h																;DH |= 0x02 (MINUS mode)

	.NOP:
	Inc		ECX																	;ECX++
	Mov		BL,[ECX]															;BL = Char
	Jmp		short .RETURNFIRST

	.HEXZ:
	Inc		ECX																	;ECX++
	Mov		BL,[ECX]															;BL = Char
	And		BL,0DFh																;BL &= 0xDF
	Cmp		BL,58h																;Is char "X"?
	JE		short .HEXOK														;	Yes
	Dec		ECX																	;ECX--
	Jmp		short .RETURN

	.HEXOK:
	Or		DH,04h																;DH |= 0x04 (HEX mode)
	Inc		ECX																	;ECX++
	Jmp		short .RETURN

	.HEXCHECK:
	Test	DH,04h																;DH &= 0x04? (HEX mode?)
	JZ		short .NEXT															;	No
	Sub		BL,11h																;BL -= 0x11 (0x41)
	Cmp		BL,6																;BL < 6? (Is char "A" to "F"?)
	JB		short .HEXCHECKNEXT													;	Yes
	Sub		BL,20h																;BL -= 0x20 (0x61)
	Cmp		BL,6																;BL < 6? (Is char "a" to "f"?)
	JB		short .HEXCHECKNEXT													;	Yes

	.NEXT:
	Mov		BL,[ECX]															;BL = Char
	Cmp		BL,00h																;Is char NULL?
	JE		short .EXIT															;	Yes
	Cmp		BL,09h																;Is char TAB?
	JE		short .EXIT															;	Yes
	Cmp		BL,0Ah																;Is char RETURN?
	JE		short .EXIT															;	Yes
	Cmp		BL,0Dh																;Is char RETURN?
	JE		short .EXIT															;	Yes
	Cmp		BL,20h																;Is char SPACE?
	JE		short .EXIT															;	Yes
	XOr		DH,DH																;DH = 0x00 (Failure)

	.EXIT:
	Test	DH,02h																;DH &= 0x02? (MINUS mode?)
	JZ		short .PLUS															;	No
		Neg		EAX																;EAX = -EAX
	.PLUS:
	Pop		EBX
	And		DH,01h																;DH &= 0x01

ENDP


;===================================================================================================
;Check Last of Command/Parameter
;   Uses: DH, AL
;   Z flag: OFF=Success, ON=Failure

PROC GetScript700Last

	XOr		DH,DH																;DH = 0x00
	Or		DH,01h																;DH = 0x01 (Success)
	Inc		ECX																	;ECX++
	Mov		AL,[ECX]															;AL = Char
	Cmp		AL,00h																;Is char NULL?
	JE		short .OK															;	Yes
	Cmp		AL,09h																;Is char TAB?
	JE		short .OK															;	Yes
	Cmp		AL,0Ah																;Is char RETURN?
	JE		short .OK															;	Yes
	Cmp		AL,0Dh																;Is char RETURN?
	JE		short .OK															;	Yes
	Cmp		AL,20h																;Is char SPACE?
	JE		short .OK															;	Yes
	XOr		DH,DH																;DH = 0x00 (Failure)

	.OK:
	Test	DH,DH																;DH = 0x00 (Failure)?

ENDP


;===================================================================================================
;Set/Reset Script700 Compatible Function
;   EAX = Free / Result of GetScript700Number / (AL) Use GetScript700xxx function
;   EBX = Index of Script700 binary area
;   ECX = Pointer of Script700 buffer
;   EDX = Free / (DH) Use GetScript700xxx function
;   ESI = Pointer base of Script700 binary area
;   EDI = Index of Script700 program area for rollback

PROC SetScript700, pSource
USES ECX,EDX,EBX,ESI,EDI

	;---------- Initialize ----------

	Mov		ESI,[pSCRRAM]														;ESI = Script RAM Pointer

	Mov		AX,[scr700inc+02h]
	Test	AL,AL																;Include mode?
	JZ		short .INIT															;	No
		Mov		ECX,[pSource]													;ECX = Source Pointer
		Test	ECX,ECX															;ECX = NULL?
		JZ		.CRITICALERROR													;	Yes

		Mov		EBX,[scr700inc+04h]
		Mov		EDI,EBX
		Dec		AH
		JZ		.EXTRETURN
		Dec		AH
		JZ		.DATARETURN2
		Jmp		short .NORMALRETURN

	.INIT:
	XOr		EAX,EAX																;EAX = 0x00
	Mov		[ESI],AL															;Program[0] = AL
	Mov		[scr700ptr],EAX														;Reset Pointer
	Mov		[scr700dat],EAX
	Mov		[scr700inc],EAX

	XOr		EBX,EBX																;EBX = 0x00
	Inc		EBX																	;EBX++ (0x01)
	Mov		[scr700cnt],EBX

	Mov		EDI,scr700dsp
	Mov		ECX,328																;Channel(256/4) + Master(32/4) + Detune(256)
	Rep		StoSD

	Mov		EDI,scr700chg
	Mov		ECX,EAX																;ECX = EAX (0x00)

	.CLEARCHG:
		Dec		CL																;CL--
		Mov		[EDI+ECX],CL
	Dec		AL																	;AL--
	JNZ		short .CLEARCHG

	Mov		EDI,scr700lbl
	Dec		EAX																	;EAX-- (0xFFFFFFFF)
	Mov		ECX,1024															;4096byte
	Rep		StoSD

	Mov		ECX,[pSource]														;ECX = Source Pointer
	Test	ECX,ECX																;ECX = NULL?
	JZ		.CRITICALERROR														;	Yes
	XOr		EBX,EBX																;EBX = 0x00
	XOr		EDI,EDI																;EDI = 0x00

	;---------- Script Command Zone ----------

	.NORMALRETURN:
	And		EBX,SCR700MASK														;EBX &= Program Mask
	Cmp		EBX,EDI																;EBX < EDI?
	JB		.CRITICALERROR														;	Yes

	Mov		EDI,EBX																;EDI = EBX
	Call	GetScript700First													;Seek First
	JZ		.NORMALERROR														;	Failure
	XOr		DL,DL																;DL = 0x00
	Mov		AL,[ECX]															;AL = [ECX]
	Cmp		AL,3Ah																;Is char ":"?
	JE		.LABEL																;	Yes
	Cmp		AL,23h																;Is char "#"?
	JE		.Shp																;	Yes
	And		AL,0DFh																;AL &= 0xDF
	Cmp		AL,45h																;Is char "E"?
	JE		short .E															;	Yes
	Cmp		AL,51h																;Is char "Q"?
	JE		short .Q															;	Yes
	Cmp		AL,57h																;Is char "W"?
	JE		.W																	;	Yes
	Cmp		AL,4Dh																;Is char "M"?
	JE		.M																	;	Yes
	Cmp		AL,43h																;Is char "C"?
	JE		.C																	;	Yes
	Cmp		AL,41h																;Is char "A"?
	JE		.A																	;	Yes
	Cmp		AL,53h																;Is char "S"?
	JE		.S																	;	Yes
	Cmp		AL,55h																;Is char "U"?
	JE		.U																	;	Yes
	Cmp		AL,44h																;Is char "D"?
	JE		.D																	;	Yes
	Cmp		AL,4Eh																;Is char "N"?
	JE		.N																	;	Yes
	Cmp		AL,42h																;Is char "B"?
	JE		.B																	;	Yes
	Cmp		AL,52h																;Is char "R"?
	JE		.R																	;	Yes
	Cmp		AL,46h																;Is char "F"?
	JE		.F																	;	Yes
	Jmp		.NORMALERROR														;	No

	.E:																												; e
	Call	GetScript700Last													;Check Last
	JZ		.NORMALERROR														;	Failure
	Mov		byte [scr700inc+03h],01h											;Extension Command Zone
	Jmp		.EXTRETURN

	.Q:																												; q
	Call	GetScript700Last													;Check Last
	JZ		.NORMALERROR														;	Failure
	Mov		byte [ESI+EBX],00h													;Program[EBX] = 0x00
	Inc		EBX																	;EBX++
	Jmp		.NORMALRETURN

	.LABEL:
	Inc		ECX																	;ECX++
	Mov		AL,[ECX]															;AL = [ECX]
	Cmp		AL,3Ah																;Is char ":"?
	JE		short .LABEL2														;	Yes
	Call	GetScript700Number													;Parse Number (EAX = result)		; :[LABEL]
	JZ		.NORMALERROR														;	Failure
	And		EAX,1023															;EAX &= 1023
	Mov		[scr700lbl+EAX*4],EBX												;Label[EAX] = EBX
	Jmp		.NORMALRETURN

	.LABEL2:																										; ::
	Call	GetScript700Last													;Check Last
	JZ		.NORMALERROR														;	Failure
	Mov		byte [scr700inc+03h],01h											;Extension Command Zone
	Jmp		.EXTRETURN

	.NOP:																											; nop
	Inc		ECX																	;ECX++
	Mov		AL,[ECX]															;AL = [ECX]
	Test	AL,AL																;AL = 0x00?
	JZ		.NORMALERROR														;	Yes
	And		AL,0DFh																;AL &= 0xDF
	Cmp		AL,50h																;Is char "P"?
	JNE		.NORMALERROR														;	No
	Call	GetScript700Last													;Check Last
	JZ		.NORMALERROR														;	Failure
	Jmp		.NORMALRETURN

	.N:																												; n
	Inc		ECX																	;ECX++
	Mov		AL,[ECX]															;AL = [ECX]
	And		AL,0DFh																;AL &= 0xDF
	Cmp		AL,4Fh																;Is char "O"?
	JE		short .NOP															;	Yes
	Mov		DL,04h																;DL = 0x04
	Call	GetScript700Next													;Seek Next
	JZ		.NORMALERROR														;	Failure
	Mov		[scr700tmp],ECX														;Temp = ECX (Save Param1 Pointer)
	Call	GetScript700Skip													;Skip
	Call	GetScript700Next													;Seek Next
	JZ		.NORMALERROR														;	Failure
	Mov		AL,[ECX]															;AL = [ECX]
	XOr		DH,DH																;DH = 0x00
	Cmp		AL,2Bh																;Is char "+"?
	JE		short .NORMALNEXT													;	Yes
	Inc		DH																	;DH++ (0x01)
	Cmp		AL,2Dh																;Is char "-"?
	JE		short .NORMALNEXT													;	Yes
	Inc		DH																	;DH++ (0x02)
	Cmp		AL,2Ah																;Is char "*"?
	JE		short .NORMALNEXT													;	Yes
	Inc		DH																	;DH++ (0x03)
	Cmp		AL,2Fh																;Is char "/"?
	JE		short .NORMALNEXT													;	Yes
	Inc		DH																	;DH++ (0x04)
	Cmp		AL,5Ch																;Is char "\"?
	JE		short .NORMALNEXT													;	Yes
	Inc		DH																	;DH++ (0x05)
	Cmp		AL,25h																;Is char "%"?
	JE		short .NORMALNEXT													;	Yes
	Inc		DH																	;DH++ (0x06)
	Cmp		AL,24h																;Is char "$"?
	JE		short .NORMALNEXT													;	Yes
	Inc		DH																	;DH++ (0x07)
	Cmp		AL,26h																;Is char "&"?
	JE		short .NORMALNEXT													;	Yes
	Inc		DH																	;DH++ (0x08)
	Cmp		AL,7Ch																;Is char "|"?
	JE		short .NORMALNEXT													;	Yes
	Inc		DH																	;DH++ (0x09)
	Cmp		AL,5Eh																;Is char "^"?
	JE		short .NORMALNEXT													;	Yes
	Inc		DH																	;DH++ (0x0A)
	Cmp		AL,3Ch																;Is char "<"?
	JE		short .NORMALNEXT													;	Yes
	Inc		DH																	;DH++ (0x0B)
	Cmp		AL,3Eh																;Is char ">"?
	JE		short .NORMALNEXT													;	Yes
	Inc		DH																	;DH++ (0x0C)
	Cmp		AL,5Fh																;Is char "_"?
	JE		short .NORMALNEXT													;	Yes
	Inc		DH																	;DH++ (0x0D)
	Cmp		AL,21h																;Is char "!"?
	JE		short .NORMALNEXT													;	Yes
	Mov		DH,0FFh																;DH = 0xFF
	Jmp		short .NORMALNEXT

	.M:																												; m
	Mov		DL,02h																;DL = 0x02
	Jmp		short .NORMALNEXT

	.C:																												; c
	Mov		DL,03h																;DL = 0x03
	Jmp		short .NORMALNEXT

	.A:																												; a
	Mov		DX,0005h															;DL = 0x05, DH = 0x00
	Jmp		short .NORMALNEXT

	.S:																												; s
	Mov		DX,0105h															;DL = 0x05, DH = 0x01
	Jmp		short .NORMALNEXT

	.U:																												; u
	Mov		DX,0205h															;DL = 0x05, DH = 0x02
	Jmp		short .NORMALNEXT

	.D:																												; d
	Mov		DX,0305h															;DL = 0x05, DH = 0x03

	.NORMALNEXT:
	Cmp		DL,04h																;DL = 0x04? (Is command N?)
	JE		short .SETN															;	Yes
	Cmp		DL,05h																;DL = 0x05? (Is command A,S,U,D?)
	JE		short .SETASUD														;	Yes
		Mov		[ESI+EBX],DL													;Program[EBX] = DL
		Jmp		short .SETNE

	.SETN:
		Inc		DH																;DH++ (DH = 0xFF?)
		JZ		.NORMALERROR													;	Yes
		Dec		DH																;DH--
		Mov		[ESI+EBX],DL													;Program[EBX] = DL
		Inc		EBX																;EBX++
		Mov		[ESI+EBX],DH													;Program[EBX] = DH
		Jmp		short .SETNE

	.SETASUD:
		Inc		DH																;DH++ (DH = 0xFF?)
		JZ		.NORMALERROR													;	Yes
		Dec		DH																;DH--
		Mov		byte [ESI+EBX],04h												;Program[EBX] = 0x04
		Inc		EBX																;EBX++
		Mov		[ESI+EBX],DH													;Program[EBX] = DH

	.SETNE:
	Inc		EBX																	;EBX++
	Cmp		DL,04h																;DL = 0x04? (Is command N?)
	JNE		short .NNEXT														;	No
		Call	GetScript700Last												;Check Last
		JZ		.NORMALERROR													;	Failure
		Mov		ECX,[scr700tmp]													;ECX = Temp (Restore Param1 Pointer)
		Jmp		short .N1E

	.NNEXT:
		Inc		ECX																;ECX++
		Call	GetScript700Next												;Seek Next
		JZ		.NORMALERROR													;	Failure

	.N1E:
	ShL		EDX,16																;EDX << 16
	Mov		dword [scr700jmp],.N2												;Set Return Address
	Inc		DH																	;DH++ (DH = 0x01)
	Jmp		short .SETVAL

	.W:																												; w
	Mov		byte [ESI+EBX],01h													;Program[EBX] = 0x01
	Inc		EBX																	;EBX++
	Inc		ECX																	;ECX++
	Call	GetScript700Next													;Seek Next
	JZ		.NORMALERROR														;	Failure
	Mov		dword [scr700jmp],.NORMALRETURN										;Set Return Address
	XOr		DH,DH																;DH = 0x00
	Jmp		short .SETVAL

	.N2:
	ShR		EDX,16																;EDX >> 16
	Cmp		DL,04h																;DL = 0x04? (Is command N?)
	JNE		short .N2E															;	No
		Call	GetScript700Next												;Seek Next
		JZ		.NORMALERROR													;	Failure
		Call	GetScript700Skip												;Skip

	.N2E:
	Call	GetScript700Next													;Seek Next
	JZ		.NORMALERROR														;	Failure
	Mov		dword [scr700jmp],.NORMALRETURN										;Set Return Address
	Mov		DH,01h																;DH = 0x01

	.SETVAL:
	Mov		AL,[ECX]															;AL = [ECX]
	XOr		DL,DL																;DL = 0x00
	Cmp		AL,23h																;Is char "#"?						; #[NUM]
	JE		short .SETVAL4B														;	Yes
	And		AL,0DFh																;AL &= 0xDF
	Add		DL,2																;DL += 2 (0x02)
	Cmp		AL,49h																;Is char "I"?						; i[PORT]
	JE		short .SETVAL1B														;	Yes
	Inc		DL																	;DL++ (0x03)
	Cmp		AL,4Fh																;Is char "O"?						; o[PORT]
	JE		short .SETVAL1B														;	Yes
	Inc		DL																	;DL++ (0x04)
	Cmp		AL,57h																;Is char "W"?						; w[WORK]
	JE		short .SETVAL1B														;	Yes
	Inc		DL																	;DL++ (0x05)
	Cmp		AL,58h																;Is char "X"?						; x[XRAM]
	JE		short .SETVAL1B														;	Yes
	XOr		AH,AH																;AH = 0x00
	Inc		DL																	;DL++ (0x06)
	Cmp		AL,52h																;Is char "R"?						; r(x)[RAM]
	JE		short .SETVALRD														;	Yes
	Inc		AH																	;AH++ (0x01)
	Add		DL,3																;DL += 3 (0x09)
	Cmp		AL,44h																;Is char "D"?						; d(x)[DATA]
	JE		short .SETVALRD														;	Yes
	Add		DL,3																;DL += 3 (0x0C)
	Cmp		AL,4Ch																;Is char "L"?						; l[LABEL]
	JE		short .SETVAL2B														;	Yes

	Dec		ECX																	;ECX--								; (#)[NUM]/[PORT]
	Mov		DL,DH																;DL = DH
	Dec		DH																	;DH-- (DH = 0x01?)
	JNZ		short .SETVAL4B														;	No (w command)
	Jmp		short .SETVAL1B														;	Yes (others command)

	.SETVALRD:
	Inc		ECX																	;ECX++
	Mov		AL,[ECX]															;AL = [ECX]
	And		AL,0DFh																;AL &= 0xDF
	Cmp		AL,42h																;Is char "B"?						; rb[RAM], db[DATA]
	JE		short .SETVALRD2													;	Yes
	Inc		DL																	;DL++ (0x07 or 0x0A)
	Cmp		AL,57h																;Is char "W"?						; rw[RAM], dw[DATA]
	JE		short .SETVALRD2													;	Yes
	Inc		DL																	;DL++ (0x08 or 0x0B)
	Cmp		AL,44h																;Is char "D"?						; rd[RAM], dd[DATA]
	JE		short .SETVALRD2													;	Yes
	Dec		ECX																	;ECX--								; r[RAM], d[DATA]
	Sub		DL,2																;DL -= 2 (0x06 or 0x09)

	.SETVALRD2:
	Dec		AH																	;AH-- (AH = 0x01?)
	JNZ		short .SETVAL2B														;	No

	.SETVAL4B:																										; 4 byte method
	Inc		ECX																	;ECX++
	Mov		AL,[ECX]															;AL = [ECX]
	Cmp		AL,3Fh																;Is char "?"?
	JE		short .SETVALCMP													;	Yes
	Call	GetScript700Number													;Parse Number (EAX = result)
	JZ		.NORMALERROR														;	Failure
	Mov		[ESI+EBX],DL														;Program[EBX] = DL
	Inc		EBX																	;EBX++
	Mov		[ESI+EBX],EAX														;Program[EBX] = EAX
	Add		EBX,4																;EBX += 4
	Jmp		[scr700jmp]

	.SETVAL1B:																										; 1 byte method
	Inc		ECX																	;ECX++
	Mov		AL,[ECX]															;AL = [ECX]
	Cmp		AL,3Fh																;Is char "?"?
	JE		short .SETVALCMP													;	Yes
	Call	GetScript700Number													;Parse Number (EAX = result)
	JZ		.NORMALERROR														;	Failure
	Mov		[ESI+EBX],DL														;Program[EBX] = DL
	Inc		EBX																	;EBX++
	Mov		[ESI+EBX],AL														;Program[EBX] = AL
	Inc		EBX																	;EBX++
	Jmp		[scr700jmp]

	.SETVAL2B:																										; 2 byte method
	Inc		ECX																	;ECX++
	Mov		AL,[ECX]															;AL = [ECX]
	Cmp		AL,3Fh																;Is char "?"?
	JE		short .SETVALCMP													;	Yes
	Call	GetScript700Number													;Parse Number (EAX = result)
	JZ		.NORMALERROR														;	Failure
	Mov		[ESI+EBX],DL														;Program[EBX] = DL
	Inc		EBX																	;EBX++
	Mov		[ESI+EBX],AX														;Program[EBX] = AX
	Add		EBX,2																;EBX += 2
	Jmp		[scr700jmp]

	.SETVALCMP:																										; cmp method
	Call	GetScript700Last													;Check Last
	JZ		.NORMALERROR														;	Failure
	Add		DL,10h																;DL += 0x10
	Mov		[ESI+EBX],DL														;Program[EBX] = DL
	Inc		EBX																	;EBX++
	Jmp		[scr700jmp]

	.B:																												; bxx
	Inc		ECX																	;ECX++
	Mov		AH,[ECX]															;AH = [ECX]
	And		AH,0DFh																;AH &= 0xDF
	Test	AH,AH																;AH = 0x00?
	JZ		.NORMALERROR														;	Yes
	Inc		ECX																	;ECX++
	Mov		AL,[ECX]															;AL = [ECX]
	And		AL,0DFh																;AL &= 0xDF
	Test	AL,AL																;AL = 0x00?
	JZ		.NORMALERROR														;	Yes
	Mov		DL,05h																;DL = 0x05
	Cmp		AX,5241h															;Is string "BRA"?					; bra
	JE		short .BXXNEXT														;	Yes
	Inc		DL																	;DL++ (0x06)
	Cmp		AX,4551h															;Is string "BEQ"?					; beq
	JE		short .BXXNEXT														;	Yes
	Inc		DL																	;DL++ (0x07)
	Cmp		AX,4E45h															;Is string "BNE"?					; bne
	JE		short .BXXNEXT														;	Yes
	Inc		DL																	;DL++ (0x08)
	Cmp		AX,4745h															;Is string "BGE"?					; bge
	JE		short .BXXNEXT														;	Yes
	Inc		DL																	;DL++ (0x09)
	Cmp		AX,4C45h															;Is string "BLE"?					; ble
	JE		short .BXXNEXT														;	Yes
	Inc		DL																	;DL++ (0x0A)
	Cmp		AX,4754h															;Is string "BGT"?					; bgt
	JE		short .BXXNEXT														;	Yes
	Inc		DL																	;DL++ (0x0B)
	Cmp		AX,4C54h															;Is string "BLT"?					; blt
	JE		short .BXXNEXT														;	Yes
	Inc		DL																	;DL++ (0x0C)
	Cmp		AX,4343h															;Is string "BCC"?					; bcc
	JE		short .BXXNEXT														;	Yes
	Inc		DL																	;DL++ (0x0D)
	Cmp		AX,4C4Fh															;Is string "BLO"?					; blo
	JE		short .BXXNEXT														;	Yes
	Inc		DL																	;DL++ (0x0E)
	Cmp		AX,4849h															;Is string "BHI"?					; bhi
	JE		short .BXXNEXT														;	Yes
	Inc		DL																	;DL++ (0x0F)
	Cmp		AX,4353h															;Is string "BCS"?					; bcs
	JE		short .BXXNEXT														;	Yes
	Jmp		.NORMALERROR														;	No

	.BXXNEXT:
	Inc		ECX																	;ECX++
	Call	GetScript700Next													;Seek Next
	JZ		.NORMALERROR														;	Failure
	Mov		AL,[ECX]															;AL = [ECX]
	Cmp		AL,23h																;Is char "#"?
	JE		short .BXXVALN														;	Yes
	And		AL,0DFh																;AL &= 0xDF
	Cmp		AL,57h																;Is char "W"?
	JE		short .BXXVALW														;	Yes
	Dec		ECX																	;ECX--

	.BXXVALN:
	Inc		ECX																	;ECX++
	Call	GetScript700Number													;Parse Number (EAX = result)
	JZ		.NORMALERROR														;	Failure
	And		EAX,1023															;EAX &= 1023
	Mov		[ESI+EBX],DL														;Program[EBX] = DL
	Inc		EBX																	;EBX++
	Mov		[ESI+EBX],AX														;Program[EBX] = AX
	Add		EBX,2																;EBX += 2
	Jmp		.NORMALRETURN

	.BXXVALW:
	Inc		ECX																	;ECX++
	Call	GetScript700Number													;Parse Number (EAX = result)
	JZ		.NORMALERROR														;	Failure
	Mov		AH,80h																;AH = 0x80
	Mov		[ESI+EBX],DL														;Program[EBX] = DL
	Inc		EBX																	;EBX++
	Mov		[ESI+EBX],AX														;Program[EBX] = AX
	Add		EBX,2																;EBX += 2
	Jmp		.NORMALRETURN

	.R:																												; r
	Inc		ECX																	;ECX++
	Mov		AL,[ECX]															;AL = [ECX]
	Cmp		AL,30h																;Is char "0"?
	JE		short .R0															;	Yes
	Cmp		AL,31h																;Is char "1"?
	JE		short .R1															;	Yes
	Dec		ECX																	;ECX--
	Call	GetScript700Last													;Check Last
	JZ		.NORMALERROR														;	Failure
	Mov		byte [ESI+EBX],10h													;Program[EBX] = 0x10
	Inc		EBX																	;EBX++
	Jmp		.NORMALRETURN

	.R0:																											; r0
	Call	GetScript700Last													;Check Last
	JZ		.NORMALERROR														;	Failure
	Mov		byte [ESI+EBX],11h													;Program[EBX] = 0x11
	Inc		EBX																	;EBX++
	Jmp		.NORMALRETURN

	.R1:																											; r1
	Call	GetScript700Last													;Check Last
	JZ		.NORMALERROR														;	Failure
	Mov		byte [ESI+EBX],12h													;Program[EBX] = 0x12
	Inc		EBX																	;EBX++
	Jmp		.NORMALRETURN

	.F:																												; f
	Inc		ECX																	;ECX++
	Mov		AL,[ECX]															;AL = [ECX]
	Cmp		AL,30h																;Is char "0"?
	JE		short .F0															;	Yes
	Cmp		AL,31h																;Is char "1"?
	JE		short .F1															;	Yes
	Dec		ECX																	;ECX--
	Call	GetScript700Last													;Check Last
	JZ		.NORMALERROR														;	Failure
	Mov		byte [ESI+EBX],13h													;Program[EBX] = 0x13
	Inc		EBX																	;EBX++
	Jmp		.NORMALRETURN

	.F0:																											; f0
	Call	GetScript700Last													;Check Last
	JZ		.NORMALERROR														;	Failure
	Mov		byte [ESI+EBX],14h													;Program[EBX] = 0x14
	Inc		EBX																	;EBX++
	Jmp		.NORMALRETURN

	.F1:																											; f1
	Call	GetScript700Last													;Check Last
	JZ		.NORMALERROR														;	Failure
	Mov		byte [ESI+EBX],15h													;Program[EBX] = 0x15
	Inc		EBX																	;EBX++
	Jmp		.NORMALRETURN

	.Shp:																											; #
	Test	dword [apuCbMask],CBE_INCS700 | CBE_INCDATA
	JZ		.ShpERROR

	Mov		EDX,[apuCbFunc]
	Test	EDX,EDX
	JZ		.ShpERROR

	Inc		ECX																	;ECX++
	Mov		AL,[ECX]															;AL = [ECX]
	And		AL,0DFh																;AL &= 0xDF
	Cmp		AL,49h																;Is char "I"?						; #i
	JE		short .ShpI															;	Yes
	Jmp		.ShpERROR															;	No

	.ShpI:
	Inc		ECX																	;ECX++
	Mov		DL,40h																;DL = 0x40 (TEXT mode)
	Mov		AL,[ECX]															;AL = [ECX]
	Cmp		AL,09h																;AL = 0x09? (TAB)
	JE		short .ShpI1														;	Yes
	Cmp		AL,20h																;AL = 0x20? (SPACE)
	JE		short .ShpI1														;	Yes

	And		AL,0DFh																;AL &= 0xDF
	Cmp		AL,54h																;Is char "T"?						; #it
	JE		short .ShpIT														;	Yes

	Test	byte [scr700inc+03h],02h											;Data Command Zone?
	JZ		.ShpERROR															;	No
	Mov		DL,20h																;DL = 0x20 (DATA mode)
	Cmp		AL,42h																;Is char "B"?						; #ib
	JE		short .ShpIB														;	Yes
	Jmp		.ShpERROR															;	No

	.ShpIT:
	Inc		ECX																	;ECX++

	.ShpI1:
	Test	byte [scr700inc+02h],-1												;Include mode?
	JNZ		.ShpERROR															;	Yes
	Jmp		short .ShpI2

	.ShpIB:
	Inc		ECX																	;ECX++

	.ShpI2:
	Call	GetScript700Next													;Seek Next
	JZ		.ShpERROR															;	Failure
	Mov		AL,[ECX]															;AL = [ECX]
	Cmp		AL,22h																;Is char "\""?
	JNE		.ShpERROR															;	No

	Mov		[scr700inc],DL														;Include = 00h:NEW
	Inc		ECX																	;ECX++

	Push	EDI,ECX
	Mov		EDI,scr700pth
	XOr		EAX,EAX
	Mov		ECX,64
	Rep		StoSD
	Pop		ECX,EDI

	Mov		EDX,scr700pth

	.ShpI3:
	Mov		AL,[ECX]															;AL = [ECX]
	Cmp		AL,00h																;Is char NULL?
	JE		.ShpERROR															;	Yes
	Cmp		AL,0Ah																;Is char RETURN?
	JE		.ShpERROR															;	Yes
	Cmp		AL,0Dh																;Is char RETURN?
	JE		.ShpERROR															;	Yes
	Cmp		AL,22h																;Is char "\""?
	JE		short .ShpI4														;	Yes

	Inc		AH
	JZ		.ShpERROR
	Mov		[EDX],AL															;Path[EDX] = AL
	Inc		EDX																	;EDX++
	Inc		ECX																	;ECX++
	Jmp		short .ShpI3

	.ShpI4:
	Mov		[scr700inc+04h],EBX
	Inc		EBX																	;EBX++
	Mov		[scr700inc+08h],EBX													;Store pointer of successful for not call SetScript700

	MovZX	EDX,byte [scr700inc]												;Include = 02h:OLD 01h:00h 00h:NEW
	ShR		word [scr700inc+01h],8												;          02h:00h 01h:OLD 00h:NEW
	Mov		[scr700inc+02h],DL													;          02h:NEW 01h:OLD 00h:NEW
																				;EDX = 0x40 (TEXT) or 0x20 (DATA)
	ShL		EDX,24																;EDX << 24 (0x40000000 or 0x20000000)
	Test	dword [apuCbMask],EDX
	JZ		short .ShpERROR

	Push	EDI,EBX,ECX															;STDCALL is destroy EAX,ECX,EDX
	Mov		EDI,[apuCbFunc]
	Sub		EBX,[scr700dat]														;EBX -= Data Offset
	MovZX	EAX,AH																;EAX = Size of file name
	Mov		ECX,scr700pth														;ECX = Pointer of file name
	Call	EDI,EDX,EBX,EAX,ECX
	Pop		ECX,EBX,EDI

	ShL		word [scr700inc+01h],8												;Include = 02h:OLD 01h:00h 00h:NEW

	Mov		EDX,[scr700inc+08h]													;EDX = Return value of SetScript700
	Test	EDX,EDX																;EDX = ?
	JS		.CRITICALERROR														;	< 0
	JZ		short .ShpEXIT														;	= 0
		Mov		EBX,EDX															;EBX = EDX

	.ShpEXIT:
	Dec		EBX																	;EBX--
	Call	GetScript700Last													;Check Last
	JZ		short .ShpERROR														;	Failure
	Mov		AH,[scr700inc+03h]
	Dec		AH
	JZ		.EXTRETURN
	Dec		AH
	JZ		.DATARETURN2
	Jmp		.NORMALRETURN

	.ShpERROR:
	Mov		AH,[scr700inc+03h]
	Dec		AH
	JZ		.EXTERROR
	Dec		AH
	JZ		.DATAERROR

	.NORMALERROR:
	Mov		EBX,EDI																;EBX = EDI
	Test	byte [ECX],-1														;Is char NULL?
	JZ		.EXIT																;	Yes
	Call	GetScript700NextLine												;Next Line
	Jmp		.NORMALRETURN

	;---------- Extension Command Zone ----------

	.EXTRETURN:
	Call	GetScript700First													;Seek First
	JZ		.EXTERROR															;	Failure
	Mov		AL,[ECX]															;AL = [ECX]
	Cmp		AL,3Ah																;Is char ":"?
	JE		short .EXLABEL														;	Yes
	Cmp		AL,23h																;Is char "#"?
	JE		.Shp																;	Yes
	And		AL,0DFh																;AL &= 0xDF
	Cmp		AL,45h																;Is char "E"?
	JE		short .EXE															;	Yes
	Cmp		AL,4Dh																;Is char "M"?
	JE		short .EXM															;	Yes
	Cmp		AL,43h																;Is char "C"?
	JE		.EXC																;	Yes
	Cmp		AL,44h																;Is char "D"?
	JE		.EXD																;	Yes
	Cmp		AL,56h																;Is char "V"?
	JE		.EXV																;	Yes
	Jmp		.EXTERROR															;	No

	.EXLABEL:																										; ::
	Inc		ECX																	;ECX++
	Mov		AL,[ECX]															;AL = [ECX]
	Cmp		AL,3Ah																;Is char ":"?
	JNE		.EXTERROR															;	No
	Call	GetScript700Last													;Check Last
	JZ		.EXTERROR															;	Failure
	Jmp		short .EXTRETURN

	.EXE:																											; e
	Call	GetScript700Last													;Check Last
	JZ		.EXTERROR															;	Failure
	Mov		byte [scr700inc+03h],02h											;Data Command Zone
	Jmp		.DATARETURN

	.EXM:																											; m
	Inc		ECX																	;ECX++
	Call	GetScript700Next													;Seek Next
	JZ		.EXTERROR															;	Failure
	Mov		AL,[ECX]															;AL = [ECX]
	Cmp		AL,21h																;Is char "!"?
	JE		short .EXMALL														;	Yes
	Call	GetScript700Number													;Parse Number (EAX = result)
	JZ		.EXTERROR															;	Failure
	MovZX	EAX,AL																;EAX = AL
	XOr		byte [scr700dsp+EAX],01h											;pDSPFlag[EAX] ^= 0x01
	Jmp		.EXTRETURN

	.EXMALL:																										; !
	Call	GetScript700Last													;Check Last
	JZ		.EXTERROR															;	Failure
	XOr		EDX,EDX																;EDX = 0x00

	.EXMALLRETURN:
	XOr		dword [scr700dsp+EDX],01010101h										;pDSPFlag[EDX] ^= 0x01010101
	Add		EDX,4																;EDX += 4
	Cmp		EDX,256																;EDX = 256?
	JNE		short .EXMALLRETURN													;	No
	Jmp		.EXTRETURN

	.EXC:																											; c
	Inc		ECX																	;ECX++
	Call	GetScript700Next													;Seek Next
	JZ		.EXTERROR															;	Failure
	Mov		AL,[ECX]															;AL = [ECX]
	Cmp		AL,21h																;Is char "!"?
	JE		short .EXCALL														;	Yes
	Call	GetScript700Number													;Parse Number (EAX = result)
	JZ		.EXTERROR															;	Failure
	Mov		DL,AL																;DL = AL
	Call	GetScript700Next													;Seek Next
	JZ		.EXTERROR															;	Failure
	Call	GetScript700Number													;Parse Number (EAX = result)
	JZ		.EXTERROR															;	Failure
	MovZX	EDX,DL																;EDX = DL
	Or		byte [scr700dsp+EDX],02h											;pDSPFlag[EDX] |= 0x02
	Mov		[scr700chg+EDX],AL													;pDSPChange[EDX] = AL
	Jmp		.EXTRETURN

	.EXCALL:																										; !
	Inc		ECX																	;ECX++
	Call	GetScript700Next													;Seek Next
	JZ		.EXTERROR															;	Failure
	Call	GetScript700Number													;Parse Number (EAX = result)
	JZ		.EXTERROR															;	Failure
	XOr		EDX,EDX																;EDX = 0x00

	.EXCALLRETURN:
	Or		dword [scr700dsp+EDX],02020202h										;pDSPFlag[EDX] |= 0x02020202
	Mov		[scr700chg+EDX+0],AL												;pDSPChange[EDX+0] = AL
	Mov		[scr700chg+EDX+1],AL												;pDSPChange[EDX+1] = AL
	Mov		[scr700chg+EDX+2],AL												;pDSPChange[EDX+2] = AL
	Mov		[scr700chg+EDX+3],AL												;pDSPChange[EDX+3] = AL
	Add		EDX,4																;EDX += 4
	Cmp		EDX,256																;EDX = 256?
	JNE		short .EXCALLRETURN													;	No
	Jmp		.EXTRETURN

	.EXD:																											; d
	Inc		ECX																	;ECX++
	Call	GetScript700Next													;Seek Next
	JZ		.EXTERROR															;	Failure
	Mov		AL,[ECX]															;AL = [ECX]
	Cmp		AL,21h																;Is char "!"?
	JE		short .EXDALL														;	Yes
	Call	GetScript700Number													;Parse Number (EAX = result)
	JZ		.EXTERROR															;	Failure
	Mov		DL,AL																;DL = AL
	Call	GetScript700Next													;Seek Next
	JZ		.EXTERROR															;	Failure
	Call	GetScript700Number													;Parse Number (EAX = result)
	JZ		.EXTERROR															;	Failure
	MovZX	EDX,DL																;EDX = DL
	Or		byte [scr700dsp+EDX],04h											;pDSPFlag[EDX] |= 0x04
	Mov		[scr700det+EDX*4],EAX												;pDSPDetune[EDX] = EAX
	Jmp		.EXTRETURN

	.EXDALL:																										; !
	Inc		ECX																	;ECX++
	Call	GetScript700Next													;Seek Next
	JZ		.EXTERROR															;	Failure
	Call	GetScript700Number													;Parse Number (EAX = result)
	JZ		.EXTERROR															;	Failure
	XOr		EDX,EDX																;EDX = 0x00

	.EXDALLRETURN:
	Or		dword [scr700dsp+EDX],04040404h										;pDSPFlag[EDX] |= 0x04040404
	Mov		[scr700det+EDX*4+0],EAX												;pDSPDetune[EDX+0] = EAX
	Mov		[scr700det+EDX*4+4],EAX												;pDSPDetune[EDX+1] = EAX
	Mov		[scr700det+EDX*4+8],EAX												;pDSPDetune[EDX+2] = EAX
	Mov		[scr700det+EDX*4+12],EAX											;pDSPDetune[EDX+3] = EAX
	Add		EDX,4																;EDX += 4
	Cmp		EDX,256																;EDX = 256?
	JNE		short .EXDALLRETURN													;	No
	Jmp		.EXTRETURN

	.EXV:																											; v
	Inc		ECX																	;ECX++
	Call	GetScript700Next													;Seek Next
	JZ		.EXTERROR															;	Failure
	XOr		DH,DH																;DH = 0x00
	Mov		AL,[ECX]															;AL = [ECX]
	Inc		ECX																	;ECX++
	Cmp		AL,21h																;Is char "!"?
	JE		.EXVALL																;	Yes
	And		AL,0DFh																;AL &= 0xDF
	Cmp		AL,56h																;Is char "V"?
	JE		.EXVV																;	Yes
	Cmp		AL,45h																;Is char "E"?
	JE		.EXVE																;	Yes
	Mov		DL,S700_MVOL_L														;DL = MasterVolumeLeft
	Cmp		AL,4Ch																;Is char "L"?
	JE		short .EXVL															;	Yes
	Mov		DL,S700_MVOL_R														;DL = MasterVolumeRight
	Cmp		AL,52h																;Is char "R"?
	JE		short .EXVR															;	Yes
	Dec		ECX																	;ECX--
	Call	GetScript700Number													;Parse Number (EAX = result)
	JZ		.EXTERROR															;	Failure
	MovZX	DX,AL																;DL = AL, DH = 0x00
	Mov		dword [scr700jmp],.EXTRETURN										;Set Return Address

	.ENVSET:
	ShL		EDX,16																;EDX << 16
	Call	GetScript700Next													;Seek Next
	JZ		.EXTERROR															;	Failure
	Call	GetScript700Number													;Parse Number (EAX = result)
	JZ		.EXTERROR															;	Failure
	Push	EDX																	;Push EDX
	Test	EAX,EAX																;If EAX < 0
	SetS	DL																	;	Yes, DL = 1
	MovZX	EDX,DL																;EDX = DL
	Dec		EDX																	;EDX--
	And		EAX,EDX																;EAX &= EDX
	Pop		EDX																	;Pop EDX
	ShR		EDX,16																;EDX >> 16
	Or		byte [scr700dsp+EDX],08h											;pDSPFlag[EDX] |= 0x08
	Mov		[scr700vol+EDX*4],EAX												;pDSPVolume[EDX] = EAX
	Jmp		[scr700jmp]

	.EXVL:
	Mov		AL,[ECX]															;AL = [ECX]
	And		AL,0DFh																;AL &= 0xDF
	Cmp		AL,52h																;Is char "R"?
	JE		short .EXVLR														;	Yes

	.EXVR:
	Inc		DH																	;DH++
	Mov		dword [scr700jmp],.EXVLR3											;Set Return Address
	Jmp		short .ENVSET

	.EXVLR:
	Inc		ECX																	;ECX++
	Inc		DH																	;DH++
	Mov		dword [scr700jmp],.EXVLR2											;Set Return Address
	Jmp		short .ENVSET

	.EXVLR2:
	Or		dword [scr700dsp+EDX],08080808h										;pDSPFlag[EDX] |= 0x08080808
	Mov		[scr700vol+EDX*4+4],EAX												;pDSPVolume[EDX+1] = EAX
	Mov		[scr700vol+EDX*4+12],EAX											;pDSPVolume[EDX+3] = EAX

	.EXVLR3:
	Or		byte [scr700dsp+EDX+2],08h											;pDSPFlag[EDX+2] |= 0x08
	Mov		[scr700vol+EDX*4+8],EAX												;pDSPVolume[EDX+2] = EAX
	Jmp		.EXTRETURN

	.EXVALL:
	Call	GetScript700Next													;Seek Next
	JZ		.EXTERROR															;	Failure
	Call	GetScript700Number													;Parse Number (EAX = result)
	JZ		.EXTERROR															;	Failure
	Test	EAX,EAX																;If EAX < 0
	SetS	DL																	;	Yes, DL = 1
	MovZX	EDX,DL																;EDX = DL
	Dec		EDX																	;EDX--
	And		EAX,EDX																;EAX &= EDX
	XOr		EDX,EDX

	.EXVALLRETURN:
	Or		dword [scr700dsp+EDX],08080808h										;pDSPFlag[EDX] |= 0x08080808
	Mov		[scr700vol+EDX*4+0],EAX												;pDSPVolume[EDX+0] = EAX
	Mov		[scr700vol+EDX*4+4],EAX												;pDSPVolume[EDX+1] = EAX
	Mov		[scr700vol+EDX*4+8],EAX												;pDSPVolume[EDX+2] = EAX
	Mov		[scr700vol+EDX*4+12],EAX											;pDSPVolume[EDX+3] = EAX
	Add		EDX,4																;EDX += 4
	Cmp		EDX,256																;EDX = 256?
	JNE		short .EXVALLRETURN													;	No
	Jmp		.EXTRETURN

	.EXVV:
	Mov		AL,[ECX]															;AL = [ECX]
	And		AL,0DFh																;AL &= 0xDF
	Mov		DL,S700_MVOL_L														;DL = MasterVolumeLeft
	Cmp		AL,4Ch																;Is char "L"?
	JE		short .EXVCMD														;	Yes
	Mov		DL,S700_MVOL_R														;DL = MasterVolumeRight
	Cmp		AL,52h																;Is char "R"?
	JE		short .EXVCMD														;	Yes
	Jmp		short .EXTERROR

	.EXVE:
	Mov		AL,[ECX]															;AL = [ECX]
	And		AL,0DFh																;AL &= 0xDF
	Mov		DL,S700_ECHO_L														;DL = EchoVolumeLeft
	Cmp		AL,4Ch																;Is char "L"?
	JE		short .EXVCMD														;	Yes
	Mov		DL,S700_ECHO_R														;DL = EchoVolumeRight
	Cmp		AL,52h																;Is char "R"?
	JE		short .EXVCMD														;	Yes
	Jmp		short .EXTERROR

	.EXVCMD:
	Inc		ECX																	;ECX++
	Inc		DH																	;DH++
	Mov		dword [scr700jmp],.EXTRETURN										;Set Return Address
	Jmp		.ENVSET

	.EXTERROR:
	Test	byte [ECX],-1														;Is char NULL?
	JZ		.EXIT																;	Yes
	Call	GetScript700NextLine												;Next Line
	Jmp		.EXTRETURN

	;---------- Data Command Zone ----------

	.DATARETURN:
	XOr		AH,AH																;AH = 0x00
	Mov		EDI,EBX																;EDI = EBX
	Mov		[ESI+EBX],AH														;Program[EBX] = AH
	Mov		[scr700dat],EBX														;Data Offset = EBX
	Inc		dword [scr700dat]													;Data Offset++
	Call	GetScript700First													;Seek First

	.DATARETURN2:
	Mov		DL,AH																;DL = AH (0x00)

	.DATARETURNLINE:
	Mov		AL,[ECX]															;AL = [ECX]
	Cmp		AL,00h																;AL = 0x00?
	JE		.EXIT																;	Yes
	Cmp		AL,3Ah																;Is char ":"?
	JE		short .DATALABEL													;	Yes
	Cmp		AL,23h																;Is char "#"?
	JE		.Shp																;	Yes
	Inc		ECX																	;ECX++
	Cmp		AL,0Ah																;Is char RETURN?
	JE		short .DATANEWLINE													;	Yes
	Cmp		AL,0Dh																;Is char RETURN?
	JE		short .DATANEWLINE													;	Yes
	Cmp		AL,09h																;AL = 0x09? (TAB)
	JE		short .DATARETURNLINE												;	Yes
	Cmp		AL,20h																;AL = 0x20? (SPACE)
	JE		short .DATARETURNLINE												;	Yes
	Sub		AL,30h																;AL -= 0x30
	Cmp		AL,10																;AL < 10? (Is char "0" to "9"?)
	JB		short .DATANUM														;	Yes
	Sub		AL,11h																;AL -= 0x11 (0x41)
	Cmp		AL,6																;AL < 6? (Is char "A" to "F"?)
	JB		short .DATAHEX														;	Yes
	Sub		AL,20h																;AL -= 0x20 (0x61)
	Cmp		AL,6																;AL < 6? (Is not char "a" to "f"?)
	JB		short .DATAHEX														;	Yes
	Dec		ECX																	;ECX--
	Call	GetScript700NextLine												;Next Line
	Jmp		short .DATARETURNLINE

	.DATALABEL:
	Inc		ECX																	;ECX++
	Mov		AL,[ECX]															;AL = [ECX]
	Call	GetScript700Number													;Parse Number (EAX = result)		; :[LABEL]
	JZ		.DATAERROR															;	Failure
	And		EAX,1023															;EAX &= 1023
	Mov		EDX,EBX																;EDX = EBX
	Sub		EDX,[scr700dat]														;EDX -= Data Offset
	Inc		EDX																	;EDX++
	Mov		[scr700lbl+EAX*4],EDX												;Label[EAX] = EDX

	.DATANEWLINE:
	XOr		AH,AH																;AH = 0x00
	Jmp		.DATARETURN2

	.DATAHEX:
	Add		AL,10																;AL += 10

	.DATANUM:
	Dec		DL																	;DL-- (DL = 0x00?)
	JZ		short .DATANUM2														;	Yes
	ShL		AX,12																;AX << 12 (Mov AH,AL; ShL AH,4)
	Add		DL,2																;DL += 2
	Jmp		short .DATARETURNLINE

	.DATANUM2:
	Or		AH,AL																;AH |= AL
	Inc		EBX																	;EBX++
	And		EBX,SCR700MASK														;EBX &= Program Mask
	Cmp		EBX,EDI																;EBX < EDI?
	JB		short .CRITICALERROR												;	Yes
	Mov		[ESI+EBX],AH														;Program[EBX] = AH
	Mov		EDI,EBX																;EDI = EBX
	Jmp		.DATARETURNLINE

	.DATAERROR:
	Test	byte [ECX],-1														;Is char NULL?
	JZ		short .EXIT															;	Yes
	Call	GetScript700NextLine												;Next Line
	XOr		AH,AH																;AH = 0x00
	Jmp		.DATARETURN2

	;---------- Error ----------

	.CRITICALERROR:
	XOr		EAX,EAX																;EAX = 0x00
	Test	byte [scr700inc+02h],-1												;Include mode?
	JNZ		short .NORESET														;	Yes
		Mov		[ESI],AL														;Program[0] = AL

	.NORESET:
	Test	ECX,ECX																;ECX = NULL?
	SetZ	AL																	;AL = Zero?
	Dec		EAX																	;EAX--
	Jmp		short .FINALIZE

	;---------- Finalize ----------

	.EXIT:
	Mov		EAX,EBX																;EAX = EBX
	Inc		EAX																	;EAX++
	Test	byte [scr700inc+02h],-1												;Include mode?
	JNZ		short .FINALIZE														;	Yes
	Mov		ECX,[scr700dat]														;ECX = Data Offset
	Test	ECX,ECX																;ECX = 0x00?
	JNZ		short .FINALIZE														;	No
	Mov		[ESI+EBX],CL														;Program[EBX] = CL
	Mov		[scr700dat],EAX														;Data Offset = EAX

	.FINALIZE:
	Mov		[scr700inc+08h],EAX

ENDP


;===================================================================================================
;Set Script700 Binary Data Function

PROC SetScript700Data, addr, pData, size

	Mov		EAX,[pData]															;EAX = Data Pointer
	Test	EAX,EAX																;EAX = NULL?
	JZ		short .FINALIZE														;	Yes

	Mov		EAX,[scr700dat]														;EAX = Data Offset
	Add		EAX,[addr]															;EAX += addr, is overflow?
	JO		short .CRITICALERROR												;	Yes
	Add		EAX,[size]															;EAX += size, is overflow?
	JO		short .CRITICALERROR												;	Yes
	Cmp		EAX,SCR700SIZE														;EAX > Buffer Size?
	JG		short .CRITICALERROR												;	Yes

	Push	EDI,ESI,ECX

	Mov		EDI,[pSCRRAM]														;EDI = Script RAM Pointer
	Add		EDI,[scr700dat]														;EDI += Data Offset
	Add		EDI,[addr]															;EDI += addr
	Mov		ESI,[pData]															;ESI = Data Pointer

	Mov		ECX,[size]															;ECX = size
	ShR		ECX,2																;ECX >> 2
	Rep		MovSD																;memcpy(EDI, ESI, ECX*4)

	Mov		ECX,[size]															;ECX = size
	And		ECX,3																;ECX &= 3
	Rep		MovSB																;memcpy(EDI, ESI, ECX)

	Mov		EAX,EDI																;EAX = EDI (EAX = Script RAM Pointer + DataOffset + addr + size)
	Sub		EAX,[pSCRRAM]														;EAX -= Script RAM Pointer (EAX = DataOffset + addr + size)

	Pop		ECX,ESI,EDI
	Jmp		short .FINALIZE

	.CRITICALERROR:
	XOr		EAX,EAX																;EAX = 0x00
	Dec		EAX																	;EAX--

	.FINALIZE:
	Mov		[scr700inc+08h],EAX

ENDP
; ----- degrade-factory code [END] -----


; ----- degrade-factory code [2015/07/11] -----
;===================================================================================================
;Get SNESAPU Context Buffer Size Function

PROC GetSNESAPUContextSize
USES ECX

	XOr		EAX,EAX

	Mov		ECX,apuVarEP														;ECX = Variable size of APU.asm
	Sub		ECX,apuRAMBuf
	And		ECX,0FFFFFFFCh
	Add		ECX,4

	Add		EAX,ECX																;EAX += ECX

	Mov		ECX,dspVarEP														;ECX = Variable size of DSP.asm
	Sub		ECX,mix
	And		ECX,0FFFFFFFCh
	Add		ECX,4

	Add		EAX,ECX																;EAX += ECX

	Mov		ECX,spcVarEP														;ECX = Variable size of SPC700.asm
	Sub		ECX,extraRAM
	And		ECX,0FFFFFFFCh
	Add		ECX,4

	Add		EAX,ECX																;EAX += ECX

ENDP


;===================================================================================================
;Get SNESAPU Context Data Function

PROC GetSNESAPUContext, pCtxOut
USES ECX,ESI,EDI

	Mov		EDI,[pCtxOut]

	Mov		ECX,apuVarEP														;ECX = Variable size of APU.asm
	Sub		ECX,apuRAMBuf
	ShR		ECX,2
	Inc		ECX

	Mov		ESI,apuRAMBuf														;memcpy(&EDI, &apuRAMBuf, ECX*4)
	Rep		MovSD

	Mov		ECX,dspVarEP														;ECX = Variable size of DSP.asm
	Sub		ECX,mix
	ShR		ECX,2
	Inc		ECX

	Mov		ESI,mix																;memcpy(&EDI, &mix, ECX*4)
	Rep		MovSD

	Mov		ECX,spcVarEP														;ECX = Variable size of SPC700.asm
	Sub		ECX,extraRAM
	ShR		ECX,2
	Inc		ECX

	Mov		ESI,extraRAM														;memcpy(&EDI, &extraRAM, ECX*4)
	Rep		MovSD

	XOr		EAX,EAX

ENDP


;===================================================================================================
;Set SNESAPU Context Data Function

PROC SetSNESAPUContext, pCtxIn
USES ECX,ESI,EDI

	Mov		ESI,[pCtxIn]

	Mov		ECX,apuVarEP														;ECX = Variable size of APU.asm
	Sub		ECX,apuRAMBuf
	ShR		ECX,2
	Inc		ECX

	Mov		EDI,apuRAMBuf														;memcpy(&apuRAMBuf, &ESI, ECX*4)
	Rep		MovSD

	Mov		ECX,dspVarEP														;ECX = Variable size of DSP.asm
	Sub		ECX,mix
	ShR		ECX,2
	Inc		ECX

	Mov		EDI,mix																;memcpy(&mix, &ESI, ECX*4)
	Rep		MovSD

	Mov		ECX,spcVarEP														;ECX = Variable size of SPC700.asm
	Sub		ECX,extraRAM
	ShR		ECX,2
	Inc		ECX

	Mov		EDI,extraRAM														;memcpy(&extraRAM, &ESI, ECX*4)
	Rep		MovSD

	XOr		EAX,EAX

ENDP
; ----- degrade-factory code [END] -----
