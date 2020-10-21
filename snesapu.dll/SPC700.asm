;===================================================================================================
;Program:    SNES SPC700 Sound Processing Unit (SPU) Emulator
;Platform:   Intel 80386
;Programmer: Anti Resonance (Alpha-II Productions), sunburst (degrade-factory)
;
;Thanks to Michael Abrash.  It was reading the Graphics Programming Black Book that gave me the
;idea and inspiration to write this in the first place.
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
;                                                   Copyright (C) 1999-2008 Alpha-II Productions
;                                                   Copyright (C) 2003-2020 degrade-factory
;===================================================================================================

CPU		386
BITS	32

;===================================================================================================
;Header files

%include "macro.inc"
%include "SNESAPU.inc"
%include "DSP.inc"
%include "APU.inc"
%define	INTERNAL
%include "SPC700.inc"


;===================================================================================================
;Equates

	;Clock cycles per operation -----------------
	T64_CYC		EQU	384															;64kHz timer clock divisor
	T8_CYC		EQU	(8*T64_CYC)													;8kHz timer clock divisor

	;Cleanup options ----------------------------
	na			EQU	 0															;Option is not applicable to this instruction
	WD			EQU	 001b														;Instruction writes to direct page
	RD			EQU	 010b														;Instruction reads from direct page
	WD16		EQU	 101b														;Instruction writes 16 bits to direct page
	RD16		EQU	 110b														;Instruction reads 16 bits from direct page
	WA			EQU	1001b														;Instruction writes to absolute address
	RA			EQU	1010b														;Instruction reads from absolute address

	;Registers ----------------------------------
	%define	PC		SI															;Intel equivilants to SPC registers
	%define	A		AL
	%define	Y		AH
	%define	YA		AX
	%define	X		CH
	%define	PS		DL
	%define	S		EDI

	;Pointers -----------------------------------
	%define	OP1		ESI															;First instruction operand
	%define	OP2		ESI+1														;Second instruction operand
	%define	DPI 	EBX															;Direct Page Index
	%define	ABSL	EBX															;Absolute Location
	%define	RAM		EDI															;64K RAM

;===================================================================================================
;Structures

;The flags are split up into eight dwords, with the flag being stored in the second byte.  The high
;word of P is loaded with the pointer to RAM, so the 32-bit value of [P-1] is a literal pointer to
;the current Direct Page.

STRUC SPCFlags
		resb	1
	CF	resb	4																;Carry (Called CF because MASM and TASM32 reserved C)
	Z	resb	4																;Zero
	I	resb	4																;Interrupts Enabled (unused in the SNES)
	H	resb	4																;Half-Carry
	B	resb	4																;Software Break
	P	resb	4																;Direct Page selector
	V	resb	4																;Integer Overflow
	N	resb	3																;Negative
ENDSTRUC

STRUC MemMap
	dp0				resb	0F0h												;Direct Page 0
		testReg		resb	1													;	Test register (no use)
		control		resb	1													;	Control register
		dspAddr		resb	1													;	DSP Address
		dspData		resb	1													;	DSP Data
		port0		resb	1													;	Port 0
		port1		resb	1													;	Port 1
		port2		resb	1													;	Port 2
		port3		resb	1													;	Port 3
					resb	1													;	unused
					resb	1													;	unused
		t0			resb	1													;	Timer 0
		t1			resb	1													;	Timer 1
		t2			resb	1													;	Timer 2
		c0			resb	1													;	Counter 0
		c1			resb	1													;	Counter 1
		c2			resb	1													;	Counter 2

	dp1				resb	100h												;Direct Page 1
	gp				resb	0FD00h												;General Pages 2-254
	up				resb	0C0h												;Uppermost Page 255
		ipl			resb	040h												;	Program used to transfer memory
ENDSTRUC

;===================================================================================================
; Data

%ifndef WIN32
SECTION .data ALIGN=256
%else
SECTION .data ALIGN=32
%endif

																				;The 64 bytes of ROM in the IPL region
	iplROM		DB 0CDh,0EFh,0BDh,0E8h,000h,0C6h,01Dh,0D0h,0FCh,08Fh,0AAh,0F4h,08Fh,0BBh,0F5h,078h
				DB 0CCh,0F4h,0D0h,0FBh,02Fh,019h,0EBh,0F4h,0D0h,0FCh,07Eh,0F4h,0D0h,00Bh,0E4h,0F5h
				DB 0CBh,0F4h,0D7h,000h,0FCh,0D0h,0F3h,0ABh,001h,010h,0EFh,07Eh,0F4h,010h,0EBh,0BAh
				DB 0F6h,0DAh,000h,0BAh,0F4h,0C4h,0F4h,0DDh,05Dh,0D0h,0DBh,01Fh,000h,000h,0C0h,0FFh

; ----- degrade-factory code [2007/10/07] -----
	opcOfs		DD Opc00,Opc01,Opc02,Opc03,Opc04,Opc05,Opc06,Opc07,Opc08,Opc09,Opc0A,Opc0B,Opc0C,Opc0D,Opc0E,Opc0F
				DD Opc10,Opc11,Opc12,Opc13,Opc14,Opc15,Opc16,Opc17,Opc18,Opc19,Opc1A,Opc1B,Opc1C,Opc1D,Opc1E,Opc1F
				DD Opc20,Opc21,Opc22,Opc23,Opc24,Opc25,Opc26,Opc27,Opc28,Opc29,Opc2A,Opc2B,Opc2C,Opc2D,Opc2E,Opc2F
				DD Opc30,Opc31,Opc32,Opc33,Opc34,Opc35,Opc36,Opc37,Opc38,Opc39,Opc3A,Opc3B,Opc3C,Opc3D,Opc3E,Opc3F
				DD Opc40,Opc41,Opc42,Opc43,Opc44,Opc45,Opc46,Opc47,Opc48,Opc49,Opc4A,Opc4B,Opc4C,Opc4D,Opc4E,Opc4F
				DD Opc50,Opc51,Opc52,Opc53,Opc54,Opc55,Opc56,Opc57,Opc58,Opc59,Opc5A,Opc5B,Opc5C,Opc5D,Opc5E,Opc5F
				DD Opc60,Opc61,Opc62,Opc63,Opc64,Opc65,Opc66,Opc67,Opc68,Opc69,Opc6A,Opc6B,Opc6C,Opc6D,Opc6E,Opc6F
				DD Opc70,Opc71,Opc72,Opc73,Opc74,Opc75,Opc76,Opc77,Opc78,Opc79,Opc7A,Opc7B,Opc7C,Opc7D,Opc7E,Opc7F
				DD Opc80,Opc81,Opc82,Opc83,Opc84,Opc85,Opc86,Opc87,Opc88,Opc89,Opc8A,Opc8B,Opc8C,Opc8D,Opc8E,Opc8F
				DD Opc90,Opc91,Opc92,Opc93,Opc94,Opc95,Opc96,Opc97,Opc98,Opc99,Opc9A,Opc9B,Opc9C,Opc9D,Opc9E,Opc9F
				DD OpcA0,OpcA1,OpcA2,OpcA3,OpcA4,OpcA5,OpcA6,OpcA7,OpcA8,OpcA9,OpcAA,OpcAB,OpcAC,OpcAD,OpcAE,OpcAF
				DD OpcB0,OpcB1,OpcB2,OpcB3,OpcB4,OpcB5,OpcB6,OpcB7,OpcB8,OpcB9,OpcBA,OpcBB,OpcBC,OpcBD,OpcBE,OpcBF
				DD OpcC0,OpcC1,OpcC2,OpcC3,OpcC4,OpcC5,OpcC6,OpcC7,OpcC8,OpcC9,OpcCA,OpcCB,OpcCC,OpcCD,OpcCE,OpcCF
				DD OpcD0,OpcD1,OpcD2,OpcD3,OpcD4,OpcD5,OpcD6,OpcD7,OpcD8,OpcD9,OpcDA,OpcDB,OpcDC,OpcDD,OpcDE,OpcDF
				DD OpcE0,OpcE1,OpcE2,OpcE3,OpcE4,OpcE5,OpcE6,OpcE7,OpcE8,OpcE9,OpcEA,OpcEB,OpcEC,OpcED,OpcEE,OpcEF
				DD OpcF0,OpcF1,OpcF2,OpcF3,OpcF4,OpcF5,OpcF6,OpcF7,OpcF8,OpcF9,OpcFA,OpcFB,OpcFC,OpcFD,OpcFE,OpcFF
	fncOfs		DD Func0,Func1,Func2,Func3,Func4,Func5,Func6,Func7,Func8,Func9,FuncA,FuncB,FuncC,FuncD,FuncE,FuncF
				DD FuncZ
; ----- degrade-factory code [END] -----

; ----- degrade-factory code [2013/10/06] -----
	scrAsmSkip	DD 4	; #[NUM]
				DD 1	; [PORT]
				DD 1	; i[PORT]
				DD 1	; o[PORT]
				DD 1	; w[WORK]
				DD 1	; x[XRAM]
				DD 2	; r(b)[RAM]
				DD 2	; rw[RAM]
				DD 2	; rd[RAM]
				DD 4	; d(b)[DATA]
				DD 4	; dw[DATA]
				DD 4	; dd[DATA]
				DD 2	; l[LABEL]
				DD 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
; ----- degrade-factory code [END] -----


;===================================================================================================
; Variables

%ifndef WIN32
SECTION .bss ALIGN=256
%else
SECTION .bss ALIGN=64
%endif

; ----- degrade-factory code [2016/08/20] -----
	extraRAM	resb	64														;Memory used for writes when ROM reading is enabled

	outPort		resb	4														;Out port values
	inPortCp	resb	4														;In port copies
	outPortCp	resb	4														;Out port copies
	flushPort	resb	4														;Port values for flush
	portMod		resb	1														;In port was modified (bits 3-0) SPC700 is sleeping (7)
	tControl	resb	1														;Copy of [F1h]
				resb	2

	t0Step		resb	1														;Timer pulses left until next counter increase,
	t1Step		resb	1														; aka up counters (even though I use them to count down)
	t2Step		resb	2

	clkTotal	resd	1														;Total number of clock cycles left to execute
	clkExec		resd	1														;Number of cycles needed for 64kHz timer to increase
	clkLeft		resd	1														;Number of cycles left to execute until timer increase
	t8kHz		resd	1														;Clock cycles left until 8kHz pulse
	t64kHz		resd	1														;Clock cycles left until 64kHz pulse
	t64Cnt		resd	1														;64kHz counter (increased every 64kHz pulse)
	pSPCReg		resd	1														;Pointer to SPC700 Register Buffer

	pOpFetch	resd	1														;Pointer to opcode fetcher
	pDebug		resd	1														;Pointer to tracing routine
	dbgOpt		resd	1														;Debugging options
				resd	1

	PSW			resd	8														;Flags in dword form
	regPC		resd	1														;Storage for registers between calls
	regYA		resd	1
	regSP		resd	1
	regX		resd	1

	tmpTotal	resd	1														;clkTotal which was set before EmuAPU was called
	tmpExec		resd	1														;clkExec which was set before EmuAPU was called
	tmpLeft		resd	1														;clkLeft which was set before EmuAPU was called

%ifdef SHVC_SOUND_SUPPORT
	cbWrPort	resd	1														;Callback function to write port
	cbRdPort	resd	1														;Callback function to read port
	cbReset		resd	1														;Callback function to reset
%endif

%if SPEED
	oldT64		resd	1														;Value of 't64Cnt' at the last counter read
%endif
; ----- degrade-factory code [END] -----

; ----- degrade-factory code [2019/07/07] -----
	t64DSP		resd	1														;Last cycles of DSP emulation
	spcVarEP	resd	1														;Endpoint of SPC700.asm variable
; ----- degrade-factory code [END] -----


;===================================================================================================
; Code

%ifndef WIN32
SECTION .text ALIGN=256
%else
SECTION .text ALIGN=16
%endif


;===================================================================================================
;Convert flags
;   Convert flags between internal 32-byte and external 8-bit format
;
;Expand PSW into 8 dwords (destroys bit flags)
%macro ExpPSW 0
	Mov		EBX,PSW+1
	Mov		DH,8
	%%Next:
		ShR		PS,1
		SetC	[EBX]
		LEA		EBX,[4+EBX]

	Dec		DH
	JNZ		%%Next
%endmacro

;Compress 8 dwords into PSW (byte flags are unaffected)
%macro CmpPSW 0
	Mov		EBX,PSW+1
	Mov		EDX,80h
	%%Next:
		Mov		DH,[EBX]
		LEA		EBX,[4+EBX]

	ShR		EDX,1
	JNC		%%Next
%endmacro


;===================================================================================================
;Initialize SPC700

; ----- degrade-factory code [2010/04/03] -----
PROC InitSPC

	Mov		EAX,[pAPURAM]
	Mov		[regPC],EAX
	Mov		AX,1FFh
	Mov		[regSP],EAX

	Mov		AX,0F0h
	Mov		byte [1+EAX],80h													;IPL ROM reading enabled
	Mov		dword [0Ch+EAX],0F0F0F00h											;Counters set to 0Fh
	Mov		dword [pSPCReg],PSW

	Mov		EAX,scr700stk
	Add		EAX,255
	XOr		AL,AL
	Mov		[scr700stp],EAX

%ifdef SHVC_SOUND_SUPPORT
	Mov		EAX,[pAPURAM]														;Reset event callback function
	Add		EAX,EXT_WRPORT
	Mov		[cbWrPort],EAX

	Mov		EAX,[pAPURAM]														;Reset event callback function
	Add		EAX,EXT_RDPORT
	Mov		[cbRdPort],EAX

	Mov		EAX,[pAPURAM]														;Reset event callback function
	Add		EAX,EXT_RESET
	Mov		[cbReset],EAX
%endif

	Call	SetSPCDbg,0,0														;Set fetch pointer to default if debugging is enabled

ENDP
; ----- degrade-factory code [END] -----


;===================================================================================================
;Reset SPC700

PROC ResetSPC
USES ECX,EDX,ESI,EDI

	;Erase 64K SPC RAM -----------------------
	Mov		EDI,[pAPURAM]
	Mov		EAX,-1																;Fill RAM with STOPs
	Mov		ECX,4000h
	Rep		StoSD

	;Reset Function Registers ----------------
; ----- degrade-factory code [2019/07/06] -----
	Mov		EAX,[pAPURAM]
	Mov		AX,0F0h
	Mov		byte [EAX+0],0Ah													;Test gets set to 0Ah
	And		byte [EAX+1],07h													;Timer status is preserved, other bits are reset
	Or		byte [EAX+1],80h
	Mov		dword [EAX+4],0														;Reset in-ports
	Mov		word [EAX+8],-1														;See above comment on erasing RAM
	Mov		dword [EAX+0Ah],0													;Timers set to 00h
	Mov		word [EAX+0Eh],0													;Counters set to 00h
	Mov		byte [EAX-0Fh],80h													;Enable ROM reading

	;Copy IPL ROM into extra RAM -------------
%if IPLW
	Mov		ESI,iplROM															;Copy to RAM
	Mov		EDI,[pAPURAM]
	Mov		DI,ipl
	Mov		ECX,10h
	Rep		MovSD

	Mov		ESI,iplROM															;If IPL region writing is enabled, fill extra RAM
	Mov		EDI,extraRAM														; with IPL ROM
	Mov		ECX,10h
	Rep		MovSD
%endif

	;Reset internal variables ----------------
	XOr		ECX,ECX
	Mov		dword [t8kHz],T8_CYC-1												;Reset timer clocks
	Mov		dword [t64kHz],T64_CYC-1
	Mov		[t64Cnt],ECX
	Mov		[portMod],CL
	Mov		dword [t64DSP],-1

	;Reset Script700 works -------------------
	Mov		[scr700stp],CL
	Mov		ECX,[scr700stp]
	XOr		EAX,EAX
	Dec		EAX
	Mov		[ECX],EAX

	Mov		EDI,scr700wrk
	Inc		EAX																	;Fill 0
	Mov		ECX,12																;scr700wrk(8) + scr700cmp(2) + scr700cnt(1) + scr700ptr(1)
	Rep		StoSD
	Mov		dword [scr700cnt],32
	Mov		dword [scr700stf],03h
; ----- degrade-factory code [END] -----

	Call	FixSPC,0FFC0h,0,0,0,0,0

; ----- degrade-factory code [2010/04/03] -----
%ifdef SHVC_SOUND_SUPPORT
	Mov		EAX,[pAPURAM]														;Reset event callback function
	Add		EAX,EXT_RESET
	Mov		[cbReset],EAX
%endif
; ----- degrade-factory code [END] -----

ENDP


;===================================================================================================
;Debug SPC700

PROC SetSPCDbg, pTrace, opts
USES EDX

	Mov		EDX,[pDebug]

	Mov		EAX,[pTrace]
	Cmp		EAX,-1
	JE		short .NoFunc
		Mov		[pDebug],EAX
	.NoFunc:

	Mov		dword [pOpFetch],SPCFetch											;Disable instruction tracing

	Cmp		byte [opts],-1
	JE		short .NoOpts														;Leave options as they are

	Test	byte [opts],SPC_TRACE												;If trace is enabled, set fetch pointer to watch
	JZ		short .TraceOff
	Test	EAX,EAX																;Make sure function pointer isn't null
	JZ		short .TraceOff
		Mov		dword [pOpFetch],SPCTrace
	.TraceOff:

; ----- degrade-factory code [2016/08/20] -----
	Mov		AL,[opts]															;Update disable envelope flags
	And		AL,DSP_PAUSE
	Mov		AH,[envFlag]
	And		AH,~DSP_PAUSE
	Or		AH,AL
	Mov		[envFlag],AH
; ----- degrade-factory code [END] -----

	Mov		EAX,[opts]															;Save options
	Mov		[dbgOpt],EAX

	.NoOpts:
	Mov		EAX,EDX

ENDP


;===================================================================================================
;Fix SPC700 After Load

PROC FixSPC, inPC, inA, inY, inX, inPSW, inSP
USES ECX,EDX,EBX,ESI,EDI

	;Load registers --------------------------
	XOr		EAX,EAX
; ----- degrade-factory code [2011/02/05] -----
	Mov		[outPort],EAX														;Initialize outPort
; ----- degrade-factory code [END] -----

	Mov		AX,[inPC]
	Mov		[regPC],AX
	Mov		AL,[inA]
	Mov		AH,[inY]
	Mov		[regYA],EAX
	Mov		AL,[inX]
	Mov		[regX],AL
	Mov		AL,[inSP]
	Mov		[regSP],AL

	Mov		DL,[inPSW]
	Mov		EBX,PSW
	Mov		AH,8
	.Flag:
		Mov		dword [EBX],0
		ShR		DL,1
		SetC	[1+EBX]
		Add		EBX,4

	Dec		AH
	JNZ		short .Flag

	Mov		RAM,[pAPURAM]
	Or		[PSW+P-1],RAM														;Load location of SPC RAM into PSW.P

	Mov		AL,[RAM+t0]															;Initialize timer counters
	Dec		AL
	Mov		[t0Step],AL
	Mov		AL,[RAM+t1]
	Dec		AL
	Mov		[t1Step],AL
	Mov		AL,[RAM+t2]
	Dec		AL
	Mov		[t2Step],AL
	Mov		byte [3+t0Step],0

; ----- degrade-factory code [2015/02/28] -----
	Mov		EAX,[RAM+port0]														;Copy port values to inPortCp, outPortCp, flushPort
	Mov		[inPortCp],EAX
	Mov		[outPortCp],EAX
	Mov		[flushPort],EAX
; ----- degrade-factory code [END] -----

	Mov		AL,[RAM+control]													;Copy control register for comparisons
	And		AL,87h
	Mov		[tControl],AL
	Mov		[RAM+control],AL

	;Copy the correct extra RAM --------------
	Test	byte [RAM+control],80h
	RetNZ

	LEA		ESI,[RAM+ipl]
	Mov		EDI,extraRAM
	Mov		ECX,10h
	Rep		MovSD

ENDP


;===================================================================================================
;Get CPU Registers

PROC GetSPCRegs, pPC, pA, pY, pX, pPSW, pSP
USES EBX

	Mov		EBX,PSW+1
	Mov		AL,80h
	.Flag:
		Mov		AH,[EBX]
		Add		EBX,4

	ShR		AX,1
	JNC		short .Flag

	Mov		EBX,[pPSW]
	Mov		[EBX],AL

	Mov		EBX,[pPC]
	Mov		AX,[regPC]
	Mov		[EBX],AX

	Mov		EBX,[pA]
	Mov		AX,[regYA]
	Mov		[EBX],AL

	Mov		EBX,[pY]
	Mov		[EBX],AH

	Mov		EBX,[pX]
	Mov		AL,[regX]
	Mov		[EBX],AL

	Mov		EBX,[pSP]
	Mov		AL,[regSP]
	Mov		[EBX],AL

ENDP


;===================================================================================================
;Write to APU RAM

PROC SetAPURAM, addr, val
USES EBX

	;Write value to memory -------------------
	Mov		EBX,[pAPURAM]
	Mov		BX,[addr]
	Mov		AL,[val]
	Mov		[EBX],AL

	;Check write -----------------------------
	Cmp		BX,ipl
	JAE		short .WROM

	Dec		BH
	Cmp		BX,0FFF0h
	JB		short .Done

	;Handle function register ----------------
	Push	ECX,EDI,EBP
	Mov		EDI,[pAPURAM]
	Mov		EBP,.Return

; ----- degrade-factory code [2007/10/07] -----
	And		BL,0Fh
	MovZX	EBX,BL
	Mov		EBX,[fncOfs+EBX*4]
	Jmp		EBX
; ----- degrade-factory code [END] -----

	.Return:
	Pop		EBP,EDI,ECX
	RetN

	;Handle IPL ROM --------------------------
	.WROM:
	XOr		BX,BX
%if IPLW
	Test	byte [tControl],80h
	RetZ
%endif

	Push	ECX
	MovZX	ECX,word [addr]
	Sub		ECX,ipl
%if IPLW
	Mov		AL,[EBX+ECX+ipl]
	Mov		[ECX+extraRAM],AL
	Mov		AL,[ECX+iplROM]
%else
	Mov		AL,[ECX+extraRAM]
%endif
	Mov		[EBX+ECX+ipl],AL
	Pop		ECX

	.Done:

ENDP


;===================================================================================================
;Write to SPC700 Port(s)

; ----- degrade-factory code [2011/02/11] -----
%ifdef SHVC_SOUND_SUPPORT
PROC ReadPort

	Push	EAX

	Mov		EAX,[cbRdPort]
	Mov		EAX,[EAX]
	Test	EAX,EAX
	JZ		short .NoCallback
		Push	ECX																;STDCALL is destroy EAX,ECX,EDX
		Call	EAX,ESI
		Pop		ECX
		Test	EAX,EAX
		JS		short .NoCallback
		MovZX	EDX,AL

	.NoCallback:
	Pop		EAX

ENDP


PROC WritePort

	Push	EAX

	Mov		EAX,[cbWrPort]
	Mov		EAX,[EAX]
	Test	EAX,EAX
	JZ		short .NoCallback
		Push	ECX,EDX															;STDCALL is destroy EAX,ECX,EDX
		Call	EAX,ESI,EDX
		Pop		EDX,ECX

	.NoCallback:
	Pop		EAX

ENDP
%endif
; ----- degrade-factory code [END] -----


PROC InPort, portb, valb
USES ECX

	;Set flag in portMod ---------------------
	MovZX	ECX,byte [portb]
	And		ECX,3
	Mov		AL,1
	ShL		AL,CL
	Or		[portMod],AL

	;Write value to port ---------------------
; ----- degrade-factory code [2015/02/28] -----
	Mov		AL,[valb]
	Mov		[inPortCp+ECX],AL
	Mov		[flushPort+ECX],AL
	Add		ECX,[pAPURAM]
	Mov		[ECX+0F4h],AL
; ----- degrade-factory code [END] -----

; ----- degrade-factory code [2011/02/11] -----
%ifdef SHVC_SOUND_SUPPORT
	Push	EDX,ESI
	Mov		ESI,ECX
	Mov		EDX,EAX
	Call	WritePort
	Pop		ESI,EDX
%endif
; ----- degrade-factory code [END] -----

ENDP


; ----- degrade-factory code [2015/02/28] -----
;===================================================================================================
;Run Script700 emulation
;   EAX = Free / (AL) Calculate option of N command
;   EBX = Index of Script700 binary area
;   ECX = Free / (CH) Move/Calc mode of .700P2
;   EDX = Free / Real value of Script700 parameter
;   ESI = Index value of Script700 parameter
;   EDI = Skip size of command
;   EBP = Pointer base of Script700 binary area

PROC RunScript700

	;---------- Initialize ----------

	PushAD																		;Push all registers
	Mov		EBX,[scr700ptr]														;EBX = Program Pointer
	Mov		EBP,[pSCRRAM]														;EBP = Script RAM Pointer

	;---------- Command Fetcher ----------

	.700RETURN:
	Test	dword [scr700stf],-1												;Is abort mode?
	JS		.700ERROR															;	Yes

	Mov		AH,[EBP+EBX]														;AH = Program[EBX]
	Test	AH,AH																;Is command E,Q?
	JZ		.700EXIT															;	Yes
	Inc		EBX																	;EBX++
	Dec		AH																	;Is command W?
	JZ		.700W																;	Yes
	Dec		AH																	;Is command M?
	JZ		.700M																;	Yes
	Dec		AH																	;Is command C?
	JZ		.700C																;	Yes
	Dec		AH																	;Is command A,S,U,D,N?
	JZ		.700N																;	Yes
	Dec		AH																	;Is command BRA?
	JZ		.700BRA																;	Yes
	Dec		AH																	;Is command BEQ?
	JZ		.700BEQ																;	Yes
	Dec		AH																	;Is command BNE?
	JZ		.700BNE																;	Yes
	Dec		AH																	;Is command BGE?
	JZ		.700BGE																;	Yes
	Dec		AH																	;Is command BLE?
	JZ		.700BLE																;	Yes
	Dec		AH																	;Is command BGT?
	JZ		.700BGT																;	Yes
	Dec		AH																	;Is command BLT?
	JZ		.700BLT																;	Yes
	Dec		AH																	;Is command BCC?
	JZ		.700BCC																;	Yes
	Dec		AH																	;Is command BLO?
	JZ		.700BLO																;	Yes
	Dec		AH																	;Is command BHI?
	JZ		.700BHI																;	Yes
	Dec		AH																	;Is command BCS?
	JZ		.700BCS																;	Yes
	Dec		AH																	;Is command R?
	JZ		.700R																;	Yes
	Dec		AH																	;Is command R0?
	JZ		.700R0																;	Yes
	Dec		AH																	;Is command R1?
	JZ		.700R1																;	Yes
	Dec		AH																	;Is command F?
	JZ		.700F																;	Yes
	Dec		AH																	;Is command F0?
	JZ		.700F0																;	Yes
	Dec		AH																	;Is command F1?
	JZ		.700F1																;	Yes
	Jmp		.700ERROR

	.700GETPVAL:
	MovZX	EDI,AH																;EDI = AH
	Mov		EDI,[scrAsmSkip+EDI*4]												;EDI = Skip[EDI]
	Test	AH,10h																;AH &= 0x10?
	JNZ		short .700GETPCMP													;	Yes
	Mov		ESI,[EBP+EBX]														;ESI = Program[EBX]
	Ret

	.700GETPCMP:
	MovZX	ESI,CL																;ESI = CL
	Mov		ESI,[scr700cmp+ESI]													;ESI = CmpParam[ESI]
	And		AH,0Fh																;AH &= 0x0F
	Ret

	;---------- No.1 Parameter Fetcher ----------

	.700P1:
	Call	.700GETPVAL															;Get Parameter Value
	Test	AH,AH																;Is parameter #[NUM]?
	JZ		short .700P1N														;	Yes
	Dec		AH																	;Is parameter [PORT]?
	JZ		short .700P1P														;	Yes
	Dec		AH																	;Is parameter i[PORT]?
	JZ		short .700P1I														;	Yes
	Dec		AH																	;Is parameter o[PORT]?
	JZ		short .700P1O														;	Yes
	Dec		AH																	;Is parameter w[WORK]?
	JZ		short .700P1W														;	Yes
	Dec		AH																	;Is parameter x[XRAM]?
	JZ		short .700P1X														;	Yes
	Dec		AH																	;Is parameter r[RAM],rb[RAM]?
	JZ		short .700P1RB														;	Yes
	Dec		AH																	;Is parameter rw[RAM]?
	JZ		short .700P1RW														;	Yes
	Dec		AH																	;Is parameter rd[RAM]?
	JZ		.700P1RD															;	Yes
	Dec		AH																	;Is parameter d[DATA],db[DATA]?
	JZ		.700P1DB															;	Yes
	Dec		AH																	;Is parameter dw[DATA]?
	JZ		.700P1DW															;	Yes
	Dec		AH																	;Is parameter dd[DATA]?
	JZ		.700P1DD															;	Yes
	Dec		AH																	;Is parameter l[LABEL]?
	JZ		.700P1L																;	Yes
	Pop		EAX																	;Cancel Return Address
	Jmp		.700ERROR

	.700P1N:																										; #[NUM]
	Mov		EDX,ESI																;EDX = ESI
	Ret

	.700P1I:																										; i[PORT]
	And		ESI,3																;ESI &= 3
	MovZX	EDX,byte [inPortCp+ESI]												;EDX = InPort[ESI]
	Ret

	.700P1P:																										; [PORT]
	And		ESI,3																;ESI &= 3
	MovZX	EDX,byte [outPortCp+ESI]											;EDX = OutPort[ESI]
%ifdef SHVC_SOUND_SUPPORT
	Call	ReadPort
%endif
	Ret

	.700P1O:																										; o[PORT]
	And		ESI,3																;ESI &= 3
	MovZX	EDX,byte [outPort+ESI]												;EDX = OutPort[ESI]
%ifdef SHVC_SOUND_SUPPORT
	Call	ReadPort
%endif
	Ret

	.700P1W:																										; w[WORK]
	And		ESI,7																;ESI &= 7
	Mov		EDX,[scr700wrk+ESI*4]												;EDX = Work[ESI]
	Ret

	.700P1X:																										; x[XRAM]
	And		ESI,63																;ESI &= 63
	MovZX	EDX,byte [extraRAM+ESI]												;EDX = XRAM[ESI]
	Ret

	.700P1RB:																										; r[RAM], rb[RAM]
	MovZX	ESI,SI																;ESI = SI
	Add		ESI,[pAPURAM]														;ESI += RAM Pointer
	MovZX	EDX,byte [ESI]														;EDX = RAM[ESI]
	Ret

	.700P1RW:																										; rw[RAM]
	MovZX	ESI,SI																;ESI = SI
	Add		ESI,[pAPURAM]														;ESI += RAM Pointer
	MovZX	EDX,word [ESI]														;EDX = RAM[ESI]
	Ret

	.700P1RD:																										; rd[RAM]
	MovZX	ESI,SI																;ESI = SI
	Add		ESI,[pAPURAM]														;ESI += RAM Pointer
	Mov		EDX,[ESI]															;EDX = RAM[ESI]
	Ret

	.700P1DB:																										; d[DATA], db[DATA]
	Add		ESI,[scr700dat]														;ESI += Data Area Offset
	And		ESI,SCR700MASK														;ESI &= Program Mask
	MovZX	EDX,byte [EBP+ESI]													;EDX = DATA[ESI]
	Ret

	.700P1DW:																										; dw[DATA]
	Add		ESI,[scr700dat]														;ESI += Data Area Offset
	And		ESI,SCR700MASK														;ESI &= Program Mask
	MovZX	EDX,word [EBP+ESI]													;EDX = DATA[ESI]
	Ret

	.700P1DD:																										; dd[DATA]
	Add		ESI,[scr700dat]														;ESI += Data Area Offset
	And		ESI,SCR700MASK														;ESI &= Program Mask
	Mov		EDX,[EBP+ESI]														;EDX = DATA[ESI]
	Ret

	.700P1L:																										; l[LABEL]
	MovZX	ESI,SI																;ESI = SI
	And		ESI,1023															;ESI &= 1023
	Mov		EDX,[scr700lbl+ESI*4]												;ESI = Label[ESI]
	Ret

	;---------- No.2 Parameter Fetcher ----------

	.700P2:
	Call	.700GETPVAL															;Get Parameter Value
	Test	AH,AH																;Is parameter #[NUM]?
	JZ		short .700P2N														;	Yes
	Dec		AH																	;Is parameter [PORT]?
	JZ		short .700P2P														;	Yes
	Dec		AH																	;Is parameter i[PORT]?
	JZ		short .700P2I														;	Yes
	Dec		AH																	;Is parameter o[PORT]?
	JZ		.700P2O																;	Yes
	Dec		AH																	;Is parameter w[WORK]?
	JZ		.700P2W																;	Yes
	Dec		AH																	;Is parameter x[XRAM]?
	JZ		.700P2X																;	Yes
	Dec		AH																	;Is parameter r[RAM],rb[RAM]?
	JZ		.700P2RB															;	Yes
	Dec		AH																	;Is parameter rw[RAM]?
	JZ		.700P2RW															;	Yes
	Dec		AH																	;Is parameter rd[RAM]?
	JZ		.700P2RD															;	Yes
	Dec		AH																	;Is parameter d[DATA],db[DATA]?
	JZ		.700P2DB															;	Yes
	Dec		AH																	;Is parameter dw[DATA]?
	JZ		.700P2DW															;	Yes
	Dec		AH																	;Is parameter dd[DATA]?
	JZ		.700P2DD															;	Yes
	Dec		AH																	;Is parameter l[LABEL]?
	JZ		.700P2L																;	Yes
	Pop		EAX																	;Cancel Return Address
	Jmp		.700ERROR

	.700P2N:																										; #[NUM] (NOP)
	Ret

	.700P2P:																										; [PORT]
	And		ESI,3																;ESI &= 3
	Test	CH,CH																;CH = 0x00? (Move?)
	JZ		short .700P2I2														;	Yes
		MovZX	ECX,byte [outPortCp+ESI]										;ECX = OutPort[ESI]
		Call	.700NCAL														;AL = Calc Option, EDX = Param1, ECX = Param2

	Jmp		short .700P2I2

	.700P2I:																										; i[PORT]
	And		ESI,3																;ESI &= 3
	Test	CH,CH																;CH = 0x00? (Move?)
	JZ		short .700P2I2														;	Yes
		MovZX	ECX,byte [inPortCp+ESI]											;ECX = InPort[ESI]
		Call	.700NCAL														;AL = Calc Option, EDX = Param1, ECX = Param2

	.700P2I2:																	;EDX = New Value
	Mov		[flushPort+ESI],DL													;FlushPort[ESI]
	Mov		CL,[scr700stf]														;CL = Stack Flag
	And		CL,02h																;CL = 0x02?
	JZ		short .700P2I3														;	No

	Mov		ECX,ESI																;ECX = ESI
	Mov		AL,1																;AL = 1
	ShL		AL,CL																;AL << CL
	Or		[portMod],AL														;PortMod |= AL
	Mov		[inPortCp+ESI],DL													;InPort[ESI] = DL
	Add		ESI,[pAPURAM]														;ESI += RAM Pointer
	Mov		[ESI+0F4h],DL														;RAM[ESI + F4h] = DL
%ifdef SHVC_SOUND_SUPPORT
	Call	WritePort
%endif

	.700P2I3:
	Ret

	.700P2O:																										; o[PORT]
	And		ESI,3																;ESI &= 3
	Test	CH,CH																;CH = 0x00? (Move?)
	JZ		short .700P2O2														;	Yes
		MovZX	ECX,byte [outPort+ESI]											;ECX = OutPort[ESI]
		Call	.700NCAL														;AL = Calc Option, EDX = Param1, ECX = Param2

	.700P2O2:																	;EDX = New Value
	Mov		[outPort+ESI],DL													;OutPort[ESI] = DL
	Mov		[outPortCp+ESI],DL													;Copy value
	Ret

	.700P2W:																										; w[WORK]
	And		ESI,7																;ESI &= 7
	Test	CH,CH																;CH = 0x00? (Move?)
	JZ		short .700P2W2														;	Yes
		Mov		ECX,[scr700wrk+ESI*4]											;ECX = Work[ESI]
		Call	.700NCAL														;AL = Calc Option, EDX = Param1, ECX = Param2

	.700P2W2:																	;EDX = New Value
	Mov		[scr700wrk+ESI*4],EDX												;Work[ESI] = EDX
	Ret

	.700P2X:																										; x[XRAM]
	And		ESI,63																;ESI &= 63
	Test	CH,CH																;CH = 0x00? (Move?)
	JZ		short .700P2X2														;	Yes
		MovZX	ECX,byte [extraRAM+ESI]											;ECX = XRAM[ESI]
		Call	.700NCAL														;AL = Calc Option, EDX = Param1, ECX = Param2

	.700P2X2:																	;EDX = New Value
	Mov		[extraRAM+ESI],DL													;XRAM[ESI] = DL
	Ret

	.700P2RB:																										; r[RAM], rb[RAM]
	MovZX	ESI,SI																;ESI = SI
	Add		ESI,[pAPURAM]														;ESI += RAM Pointer
	Test	CH,CH																;CH = 0x00? (Move?)
	JZ		short .700P2RB2														;	Yes
		MovZX	ECX,byte [ESI]													;ECX = RAM[ESI]
		Call	.700NCAL														;AL = Calc Option, EDX = Param1, ECX = Param2

	.700P2RB2:																	;EDX = New Value
	Mov		[ESI],DL															;RAM[ESI] = DL
	Ret

	.700P2RW:																										; rw[RAM]
	MovZX	ESI,SI																;ESI = SI
	Add		ESI,[pAPURAM]														;ESI += RAM Pointer
	Test	CH,CH																;CH = 0x00? (Move?)
	JZ		short .700P2RW2														;	Yes
		MovZX	ECX,word [ESI]													;ECX = RAM[ESI]
		Call	.700NCAL														;AL = Calc Option, EDX = Param1, ECX = Param2

	.700P2RW2:																	;EDX = New Value
	Mov		[ESI],DX															;RAM[ESI] = DX
	Ret

	.700P2RD:																										; rd[RAM]
	MovZX	ESI,SI																;ESI = SI
	Add		ESI,[pAPURAM]														;ESI += RAM Pointer
	Test	CH,CH																;CH = 0x00? (Move?)
	JZ		short .700P2RD2														;	Yes
		Mov		ECX,[ESI]														;ECX = RAM[ESI]
		Call	.700NCAL														;AL = Calc Option, EDX = Param1, ECX = Param2

	.700P2RD2:																	;EDX = New Value
	Mov		[ESI],EDX															;RAM[ESI] = EDX
	Ret

	.700P2DB:																										; d[DATA], db[DATA]
	Add		ESI,[scr700dat]														;ESI += Data Area Offset
	And		ESI,SCR700MASK														;ESI &= Program Mask
	Add		ESI,EBP																;ESI += EBP (Script RAM Pointer)
	Test	CH,CH																;CH = 0x00? (Move?)
	JZ		short .700P2DB2														;	Yes
		MovZX	ECX,byte [ESI]													;ECX = DATA[ESI]
		Call	.700NCAL														;AL = Calc Option, EDX = Param1, ECX = Param2

	.700P2DB2:																	;EDX = New Value
	Mov		[ESI],DL															;DATA[ESI] = DL
	Ret

	.700P2DW:																										; dw[DATA]
	Add		ESI,[scr700dat]														;ESI += Data Area Offset
	And		ESI,SCR700MASK														;ESI &= Program Mask
	Add		ESI,EBP																;ESI += EBP (Script RAM Pointer)
	Test	CH,CH																;CH = 0x00? (Move?)
	JZ		short .700P2DW2														;	Yes
		MovZX	ECX,word [ESI]													;ECX = DATA[ESI]
		Call	.700NCAL														;AL = Calc Option, EDX = Param1, ECX = Param2

	.700P2DW2:																	;EDX = New Value
	Mov		[ESI],DX															;DATA[ESI] = DX
	Ret

	.700P2DD:																										; dd[DATA]
	Add		ESI,[scr700dat]														;ESI += Data Area Offset
	And		ESI,SCR700MASK														;ESI &= Program Mask
	Add		ESI,EBP																;ESI += EBP (Script RAM Pointer)
	Test	CH,CH																;CH = 0x00? (Move?)
	JZ		short .700P2DD2														;	Yes
		Mov		ECX,[ESI]														;ECX = DATA[ESI]
		Call	.700NCAL														;AL = Calc Option, EDX = Param1, ECX = Param2

	.700P2DD2:																	;EDX = New Value
	Mov		[ESI],EDX															;DATA[ESI] = EDX
	Ret

	.700P2L:																										; l[LABEL]
	MovZX	ESI,SI																;ESI = SI
	And		ESI,1023															;ESI &= 1023
	Test	CH,CH																;CH = 0x00? (Move?)
	JZ		short .700P2L2														;	Yes
		Mov		ECX,[scr700lbl+ESI*4]											;ECX = Label[ESI]
		Call	.700NCAL														;AL = Calc Option, EDX = Param1, ECX = Param2

	.700P2L2:																	;EDX = New Value
	Mov		[scr700lbl+ESI*4],EDX												;Label[ESI] = EDX
	Ret

	;---------- Command Main Routine (CALC) ----------

	.700W:																											; w
	Mov		AH,[EBP+EBX]														;AH = Program[EBX]
	Inc		EBX																	;EBX++
	XOr		ECX,ECX																;ECX = 0x00
	Call	.700P1																;Get Value of Parameter
	Add		EBX,EDI																;EBX += EDI
	Add		[scr700cnt],EDX														;TimeCount += EDX
	Cmp		dword [scr700cnt],32												;TimeCount < 32?
	JL		.700RETURN															;	Yes
	Jmp		.700END

	.700M:																											; m
	Mov		AH,[EBP+EBX]														;AH = Program[EBX]
	Inc		EBX																	;EBX++
	XOr		ECX,ECX																;ECX = 0x00
	Call	.700P1																;Get Value of Parameter
	Add		EBX,EDI																;EBX += EDI
	Mov		AH,[EBP+EBX]														;AH = Program[EBX]
	Inc		EBX																	;EBX++
	Mov		ECX,0004h															;CH = 0x00, CL = 0x04
	Call	.700P2																;Set Value of Parameter
	Add		EBX,EDI																;EBX += EDI
	Jmp		.700RETURN

	.700C:																											; c
	Mov		AH,[EBP+EBX]														;AH = Program[EBX]
	Inc		EBX																	;EBX++
	XOr		ECX,ECX																;ECX = 0x00
	Call	.700P1																;Get Value of Parameter
	Mov		[scr700cmp],EDX														;CmpParam[0] = EDX
	Add		EBX,EDI																;EBX += EDI
	Mov		AH,[EBP+EBX]														;AH = Program[EBX]
	Inc		EBX																	;EBX++
	Mov		ECX,04h																;ECX = 0x04
	Call	.700P1																;Get Value of Parameter
	Mov		[scr700cmp+4],EDX													;CmpParam[1] = EDX
	Add		EBX,EDI																;EBX += EDI
	Jmp		.700RETURN

	.700N:																											; a, s, u, d, n
	Mov		AX,[EBP+EBX]														;AX = Program[EBX]
	Add		EBX,2																;EBX += 2
	XOr		ECX,ECX																;ECX = 0x00
	Call	.700P1																;Get Value of Parameter
	Add		EBX,EDI																;EBX += EDI
	Mov		AH,[EBP+EBX]														;AH = Program[EBX]
	Inc		EBX																	;EBX++
	Mov		ECX,0104h															;CH = 0x01, CL = 0x04
	Call	.700P2																;Set Value of Parameter
	Add		EBX,EDI																;EBX += EDI
	Jmp		.700RETURN

	.700NCAL:
	Test	AL,AL																;Is parameter +?
	JZ		short .700NCALADD													;	No
	Dec		AL																	;Is parameter -?
	JZ		short .700NCALSUB													;	Yes
	Dec		AL																	;Is parameter *?
	JZ		short .700NCALMUL													;	Yes
	Dec		AL																	;Is parameter /?
	JZ		short .700NCALIDIV													;	Yes
	Dec		AL																	;Is parameter \?
	JZ		short .700NCALDIV													;	Yes
	Dec		AL																	;Is parameter %?
	JZ		short .700NCALIMOD													;	Yes
	Dec		AL																	;Is parameter $?
	JZ		short .700NCALMOD													;	Yes
	Dec		AL																	;Is parameter &?
	JZ		short .700NCALAND													;	Yes
	Dec		AL																	;Is parameter |?
	JZ		short .700NCALOR													;	Yes
	Dec		AL																	;Is parameter ^?
	JZ		short .700NCALXOR													;	Yes
	Dec		AL																	;Is parameter <?
	JZ		short .700NCALSHL													;	Yes
	Dec		AL																	;Is parameter >?
	JZ		short .700NCALSHR													;	Yes
	Dec		AL																	;Is parameter _?
	JZ		short .700NCALSAR													;	Yes
	Dec		AL																	;Is parameter !?
	JZ		short .700NCALNOT													;	Yes
	Pop		EAX																	;Cancel Return Address
	Jmp		.700ERROR

	.700NCALADD:																									; + (ADD)
	Add		EDX,ECX																;EDX = EDX + ECX
	Ret

	.700NCALSUB:																									; - (SUB)
	Sub		ECX,EDX																;ECX = ECX - EDX
	Mov		EDX,ECX																;EDX = ECX
	Ret

	.700NCALMUL:																									; * (MUL)
	Mov		EAX,EDX																;EAX = EDX
	IMul	ECX																	;EDX:EAX = EAX * ECX
	Mov		EDX,EAX																;EDX = EAX
	Ret

	.700NCALIDIV:																									; / (IDIV)
	Test	EDX,EDX																;EDX = 0x00?
	JZ		short .700NCALERROR													;	Yes
	Mov		EAX,ECX																;EAX = ECX
	Mov		ECX,EDX																;ECX = EDX
	Cdq																			;(EAX < 0) EDX = 0xFFFFFFFF / (EAX >= 0) EDX = 0x00
	IDiv	ECX																	;EAX = EDX:EAX / ECX
	Mov		EDX,EAX																;EDX = EAX
	Ret

	.700NCALDIV:																									; \_(DIV)
	Test	EDX,EDX																;EDX = 0x00?
	JZ		short .700NCALERROR													;	Yes
	Mov		EAX,ECX																;EAX = ECX
	Mov		ECX,EDX																;ECX = EDX
	XOr		EDX,EDX																;EDX = 0x00
	Div		ECX																	;EAX = EDX:EAX / ECX
	Mov		EDX,EAX																;EDX = EAX
	Ret

	.700NCALIMOD:																									; % (IMOD)
	Test	EDX,EDX																;EDX = 0x00?
	JZ		short .700NCALERROR													;	Yes
	Mov		EAX,ECX																;EAX = ECX
	Mov		ECX,EDX																;ECX = EDX
	Cdq																			;(EAX < 0) EDX = 0xFFFFFFFF / (EAX >= 0) EDX = 0x00
	IDiv	ECX																	;EAX = EDX:EAX / ECX
	Ret

	.700NCALMOD:																									; $ (MOD)
	Test	EDX,EDX																;EDX = 0x00?
	JZ		short .700NCALERROR													;	Yes
	Mov		EAX,ECX																;EAX = ECX
	Mov		ECX,EDX																;ECX = EDX
	XOr		EDX,EDX																;EDX = 0x00
	Div		ECX																	;EAX = EDX:EAX / ECX
	Ret

	.700NCALERROR:
	Mov		EDX,ECX																;EDX = ECX
	Ret

	.700NCALAND:																									; & (AND)
	And		ECX,EDX																;ECX &= EDX
	Mov		EDX,ECX																;EDX = ECX
	Ret

	.700NCALOR:																										; | (OR)
	Or		ECX,EDX																;ECX |= EDX
	Mov		EDX,ECX																;EDX = ECX
	Ret

	.700NCALXOR:																									; ^ (XOR)
	XOr		ECX,EDX																;ECX ^= EDX
	Mov		EDX,ECX																;EDX = ECX
	Ret

	.700NCALSHL:																									; < (SHL)
	Mov		EAX,ECX																;EAX = ECX
	Mov		CL,DL																;CL = DL
	ShL		EAX,CL																;EAX << CL
	Mov		EDX,EAX																;EDX = EAX
	Ret

	.700NCALSHR:																									; > (SHR)
	Mov		EAX,ECX																;EAX = ECX
	Mov		CL,DL																;CL = DL
	ShR		EAX,CL																;EAX >> CL
	Mov		EDX,EAX																;EDX = EAX
	Ret

	.700NCALSAR:																									; _ (SAR)
	Mov		EAX,ECX																;EAX = ECX
	Mov		CL,DL																;CL = DL
	SaR		EAX,CL																;EAX >> CL
	Mov		EDX,EAX																;EDX = EAX
	Ret

	.700NCALNOT:																									; ! (NOT)
	Not		EDX																	;EDX = !EDX
	Ret

	;---------- Command Main Routine (JUMP) ----------

	.700BRA:																										; bra (TRUE)
	Mov		SI,[EBP+EBX]														;SI = Program[EBX]
	Add		EBX,2																;EBX += 2
	Test	SI,SI																;SI >= 0x8000?
	JNS		short .700BRAN														;	No
	And		ESI,7																;ESI &= 7
	Mov		ESI,[scr700wrk+ESI*4]												;ESI = Work[ESI]

	.700BRAN:
	And		ESI,1023															;ESI &= 1023
	Mov		ESI,[scr700lbl+ESI*4]												;ESI = Label[ESI]
	Inc		ESI																	;ESI++, ESI = 0x00?
	JZ		.700RETURN															;	Yes

	Dec		ESI																	;ESI--
	Mov		EDX,EBX																;EDX = EBX
	Mov		EBX,ESI																;EBX = ESI
	Mov		CL,[scr700stf]														;CL = Stack Flag
	And		CL,01h																;CL = 0x01?
	JZ		.700RETURN															;	Yes

	Mov		ECX,[scr700stp]														;ECX = Stack Pointer
	Sub		CL,4																;CL -= 4
	Mov		[scr700stp],ECX														;Stack Pointer = ECX
	Mov		[ECX],EDX															;Stack Value = EDX
	XOr		EDX,EDX																;EDX = 0x00
	Dec		EDX																	;EDX-- (EDX = 0xFFFFFFFF)
	Sub		CL,4																;CL -= 4
	Mov		[ECX],EDX															;Stack Value = EDX
	Jmp		.700RETURN

	.700BEQ:																										; beq (CmpParam2 == CmpParam1)
	Mov		ECX,[scr700cmp+4]													;ECX = CmpParam[1]
	Mov		EDX,[scr700cmp]														;EDX = CmpParam[0]
	Cmp		ECX,EDX																;ECX = EDX?
	JE		.700BRA																;	Yes
	Add		EBX,2																;EBX += 2
	Jmp		.700RETURN

	.700BNE:																										; bne (CmpParam2 != CmpParam1)
	Mov		ECX,[scr700cmp+4]													;ECX = CmpParam[1]
	Mov		EDX,[scr700cmp]														;EDX = CmpParam[0]
	Cmp		ECX,EDX																;ECX != EDX?
	JNE		.700BRA																;	Yes
	Add		EBX,2																;EBX += 2
	Jmp		.700RETURN

	.700BGE:																										; bge ((signed)CmpParam2 >= CmpParam1)
	Mov		ECX,[scr700cmp+4]													;ECX = CmpParam[1]
	Mov		EDX,[scr700cmp]														;EDX = CmpParam[0]
	Cmp		ECX,EDX																;ECX >= EDX?
	JGE		.700BRA																;	Yes
	Add		EBX,2																;EBX += 2
	Jmp		.700RETURN

	.700BLE:																										; ble ((signed)CmpParam2 <= CmpParam1)
	Mov		ECX,[scr700cmp+4]													;ECX = CmpParam[1]
	Mov		EDX,[scr700cmp]														;EDX = CmpParam[0]
	Cmp		ECX,EDX																;ECX <= EDX?
	JLE		.700BRA																;	Yes
	Add		EBX,2																;EBX += 2
	Jmp		.700RETURN

	.700BGT:																										; bgt ((signed)CmpParam2 > CmpParam1)
	Mov		ECX,[scr700cmp+4]													;ECX = CmpParam[1]
	Mov		EDX,[scr700cmp]														;EDX = CmpParam[0]
	Cmp		ECX,EDX																;ECX > EDX?
	JG		.700BRA																;	Yes
	Add		EBX,2																;EBX += 2
	Jmp		.700RETURN

	.700BLT:																										; blt ((signed)CmpParam2 < CmpParam1)
	Mov		ECX,[scr700cmp+4]													;ECX = CmpParam[1]
	Mov		EDX,[scr700cmp]														;EDX = CmpParam[0]
	Cmp		ECX,EDX																;ECX < EDX?
	JL		.700BRA																;	Yes
	Add		EBX,2																;EBX += 2
	Jmp		.700RETURN

	.700BCC:																										; bcc ((unsigned)CmpParam2 >= CmpParam1)
	Mov		ECX,[scr700cmp+4]													;ECX = CmpParam[1]
	Mov		EDX,[scr700cmp]														;EDX = CmpParam[0]
	Cmp		ECX,EDX																;ECX >= EDX?
	JAE		.700BRA																;	Yes
	Add		EBX,2																;EBX += 2
	Jmp		.700RETURN

	.700BLO:																										; blo ((unsigned)CmpParam2 <= CmpParam1)
	Mov		ECX,[scr700cmp+4]													;ECX = CmpParam[1]
	Mov		EDX,[scr700cmp]														;EDX = CmpParam[0]
	Cmp		ECX,EDX																;ECX <= EDX?
	JBE		.700BRA																;	Yes
	Add		EBX,2																;EBX += 2
	Jmp		.700RETURN

	.700BHI:																										; bhi ((unsigned)CmpParam2 > CmpParam1)
	Mov		ECX,[scr700cmp+4]													;ECX = CmpParam[1]
	Mov		EDX,[scr700cmp]														;EDX = CmpParam[0]
	Cmp		ECX,EDX																;ECX > EDX?
	JA		.700BRA																;	Yes
	Add		EBX,2																;EBX += 2
	Jmp		.700RETURN

	.700BCS:																										; bcs ((unsigned)CmpParam2 < CmpParam1)
	Mov		ECX,[scr700cmp+4]													;ECX = CmpParam[1]
	Mov		EDX,[scr700cmp]														;EDX = CmpParam[0]
	Cmp		ECX,EDX																;ECX < EDX?
	JB		.700BRA																;	Yes
	Add		EBX,2																;EBX += 2
	Jmp		.700RETURN

	.700R:																											; r
	Mov		ECX,[scr700stp]														;ECX = Stack Pointer
	Mov		EDX,[ECX]															;EDX = Stack Value
	Inc		EDX																	;EDX++, EDX = 0x00?
	JZ		.700RETURN															;	Yes
	Dec		EDX																	;EDX--
	Add		CL,4																;CL += 4
	Mov		[scr700stp],ECX														;Stack Pointer = ECX
	Mov		EBX,EDX																;EBX = EDX

	.700R1:																											; r1
	Or		byte [scr700stf],01h												;Stack Flag |= 0x01
	Jmp		.700RETURN

	.700R0:																											; r0
	And		byte [scr700stf],~01h												;Stack Flag &= ~0x01
	Jmp		.700RETURN

	.700F:																											; f
	Or		byte [portMod],0Fh													;PortMod |= 0x0F
	Mov		EDX,[flushPort]														;EDX = FlushPort
	Mov		[inPortCp],EDX														;InPort = EDX
	Mov		ESI,[pAPURAM]														;ESI = RAM Pointer
	Mov		[ESI+0F4h],EDX														;RAM[ESI + F4h] = EDX
%ifdef SHVC_SOUND_SUPPORT
	Mov		ESI,-1																;ESI = -1
	Call	WritePort
%endif
	Add		dword [scr700cnt],32												;TimeCount += 32
	Or		byte [scr700stf],06h												;Stack Flag |= 0x06
	XOr		EDX,EDX																;EDX = 0x00
	Mov		[scr700cmp],EDX														;CmpParam[0] = EDX
	Jmp		.700END

	.700F1:																											; f1
	Or		byte [scr700stf],02h												;Stack Flag |= 0x02
	Jmp		.700RETURN

	.700F0:																											; f0
	And		byte [scr700stf],~02h												;Stack Flag &= ~0x02
	Jmp		.700RETURN

	;---------- Error ----------

	.700ERROR:
	XOr		EBX,EBX																;EBX = 0x00
	Dec		EBX																	;EBX-- (EBX = 0xFFFFFFFF)

	;---------- Exit ----------

	.700EXIT:
	XOr		EDX,EDX																;EDX = 0x00
	Mov		[scr700cnt],EDX														;TimeCount = EDX

	;---------- Finalize ----------

	.700END:
	Mov		[scr700ptr],EBX														;Program Pointer = EBX
	PopAD																		;Pop all registers

ENDP
; ----- degrade-factory code [END] -----


;===================================================================================================
;Emulate SPC700

PROC EmuSPC, cyc

	Test	byte [dbgOpt],SPC_HALT
	JZ		short .NoHalt
; ----- degrade-factory code [2013/05/25] -----
		XOr		EAX,EAX
		RetN
; ----- degrade-factory code [END] -----
	.NoHalt:

	PushAD																		;Save all registers and load EAX with the number of
	Mov		EAX,[cyc]															; clock cycles to execute

%if DEBUG																		;EBP = Location to jump to after handling an opcode
	Mov		EBP,[pOpFetch]
%else
	Mov		EBP,SPCFetch
%endif

; ----- degrade-factory code [2020/10/21] -----
	Mov		EDX,[apuCbFunc]
	Test	EDX,EDX
	JZ		short .NoCallback
		Mov		EDX,[clkTotal]
		Mov		[tmpTotal],EDX
		Mov		EDX,[clkExec]
		Mov		[tmpExec],EDX
		Mov		EDX,[clkLeft]
		Mov		[tmpLeft],EDX

	.NoCallback:
; ----- degrade-factory code [END] #19 -----

	;Setup clock cycle execution -------------
	;clkLeft contains the number of clock cycles to emulate until timer 2 increases or it's time to quit

	XOr		EDX,EDX
	Mov		[clkTotal],EAX

	Sub		EAX,[t64kHz]														;If cyc > t64kHz, clkExec = t64kHz
	SetA	DL																	;else clkExec = cyc
	Dec		EDX
	And		EAX,EDX
	Add		EAX,[t64kHz]

	Mov		[clkExec],EAX														;Save the number we want to execute this lap
	Mov		[clkLeft],EAX

	;Load x86 registers ----------------------
	Mov		EDI,[pAPURAM]
	Mov		ESI,[regPC]
	Mov		EAX,[regYA]
	Mov		CH,[regX]
	XOr		EDX,EDX																;EDX = Number of emulated clock cycles, initialize to 0

	;Update DSP data register ----------------
	;(Incase it was modifed during DSP emulation)
	MovZX	EBX,byte [RAM+dspAddr]
	Mov		CL,[EBX+dsp]
	Mov		[RAM+dspData],CL

%if DEBUG
	Jmp		EBP																	;Jump into emulation routine
%else
	Jmp		SPCFetch
%endif

SPCExit:
	Mov		[regPC],ESI															;Save emulated registers
	Mov		[regYA],EAX
	Mov		[regX],CH
	PopAD																		;Restore x86 registers before call
	Mov		EAX,[clkTotal]														;Return clock cycles left to emulate

ENDP


;===================================================================================================
;Opcode Fetcher
;
;Fetches the next opcode and jumps to the appropriate handler.  Keeps track of clock cycles emulated
;and timers.
;In the debug build, before the fetcher handles the next opcode a user defined function is called.

SPCTrace:
; ----- degrade-factory code [2020/10/20] -----
	Cmp		dword [clkLeft],0													;Have we executed all clock cycles?
	JLE		SPCTimers															;	Yes, Update timers
; ----- degrade-factory code [END] #18 -----

SPCBreak:
	;Call SPCTrace ---------------------------
	Push	dword [t0Step]														;Pass down counters
	CmpPSW																		;DL = PSW
	ShR		ECX,8																;CL = X
	Push	dword [regSP]														;Pass SP
	Push	EDX																	; ""  PSW
	Push	ECX																	; ""  X
	Push	EAX																	; ""  YA
	Push	ESI																	; ""  PC

	Mov		EAX,[t64kHz]														;Pass number of cycles left until 64kHz increase
	Mov		CL,CPU_CYC
	Div		CL
	Mov		[23+ESP],AL

	Call	[pDebug]															;Call tracing routine

	;Update registers ------------------------
	Pop		EAX																	;Pop PC
	Mov		SI,AX
	Pop		EAX																	;Pop YA
	And		EAX,0FFFFh
	Pop		ECX																	;Pop X
	MovZX	ECX,CL
	ShL		ECX,8
	Pop		EDX																	;Pop PSW
	ExpPSW
	Pop		EDX																	;Pop SP
	Mov		[regSP],DX
	Pop		EDX

	Mov		EBP,SPCExit
	Mov		EDI,[pAPURAM]														;Restore EDI
	XOr		EDX,EDX																;Reset DH since timers have already been handled

	Test	byte [dbgOpt],SPC_HALT | SPC_RETURN
	JNZ		SPCTimers

	Test	byte [dbgOpt],SPC_TRACE
	JNZ		short .Trace
		Mov		dword [pOpFetch],SPCFetch
	.Trace:
	Mov		EBP,[pOpFetch]														;Restore EBP

	;Fetching begins by first subtracting the number of clock cycles emulated by the last
	;instruction (passed in EDX).  If more cycles need to be emulated before updating timer 2, then
	;get the next opcode and emulate it.  To emulate, each opcode handler is aligned on a page
	;boundary.  An instruction opcode acts as an index to this 64K table of functions, and is used
	;to jump directly to the handler without needing to use a jump table.

SPCFetch:																		;(All opcode handlers return to this point)
; ----- degrade-factory code [2020/10/20] -----
	Cmp		dword [clkLeft],0													;Have we executed all clock cycles?
	JLE		SPCTimers															;	Yes, Update timers
; ----- degrade-factory code [END] #18 -----

; ----- degrade-factory code [2020/10/21] -----
	Test	dword [apuCbMask],CBE_S700FCH
	JZ		short .NoCallback

	Mov		EDX,[apuCbFunc]
	Test	EDX,EDX
	JZ		short .NoCallback
		Push	EAX,ECX															;STDCALL is destroy EAX,ECX,EDX
		Mov		EAX,[ESI]
		Call	EDX,dword CBE_S700FCH,EAX,dword 0,ESI
		Mov		EDX,EAX
		Pop		ECX,EAX

		Test	DL,FCH_HALT														;Exit emulation?
		JZ		short .NextCallback												;	No

		And		DL,FCH_NOP														;Update disable envelope flags
		Mov		DH,[envFlag]
		And		DH,~FCH_PAUSE
		Or		DH,DL
		Mov		[envFlag],DH

		Mov		EDX,[tmpTotal]
		Mov		[clkTotal],EDX
		Mov		EDX,[tmpExec]
		Mov		[clkExec],EDX
		Mov		EDX,[tmpLeft]
		Mov		[clkLeft],EDX

		Jmp		SPCExit

	.NextCallback:
		And		byte [envFlag],~FCH_PAUSE

		Test	DL,FCH_NOP														;Skip opecode?
		JZ		short .NoCallback												;	No

		Mov		EDX,[opcOfs]													;NOP
		Jmp		EDX

	.NoCallback:
; ----- degrade-factory code [END] #19 -----

; ----- degrade-factory code [2007/10/07] -----
	MovZX	EDX,byte [ESI]														;Get next opcode
	Mov		EDX,[opcOfs+EDX*4]													;Add the base of the emulation table to the opcode
	Inc		PC																	;Move PC to first operand or next instruction
	Jmp		EDX																	;Jump to handler
; ----- degrade-factory code [END] -----

	;clkExec contains the number of clock cycles we wanted to emulate this round.  By subtracting
	;clkLeft (which will be a number <= 0) we get the actual number of cycles emulated, which will
	;be subtracted from the total number to be emulated (clkTotal) and used to update the timers.

SPCTimers:
; ----- degrade-factory code [2019/07/07] -----
	Mov		EDX,[clkExec]														;EDX = Actual number of clock cycles emulated
	Sub		EDX,[clkLeft]

	;Update timers ---------------------------
	Sub		[t64kHz],EDX														;Subtract cycles from timer clock.  Has it rolled over?
	JNS		.NoT64Inc															;	No, Don't update timers
		Add		dword [t64kHz],T64_CYC											;Restore timer 2 clock
		Inc		dword [t64Cnt]													;Increase 64kHz counter

		Mov		BL,[tControl]													;BL = Control register
		ShL		BL,6															;Copy timer enable bit into CF
		SbB		byte [t2Step],0													;Decrease timer step if timer is enabled
		JNC		short .NoC2Inc													;If carry, counter needs to be increased
			Mov		BH,[RAM+t2]													;Restore the number of steps until counter increase
			Dec		BH
			Mov		[t2Step],BH
			Inc		byte [RAM+c2]												;Increase counter 2
			And		byte [RAM+c2],0Fh											;Only lower 4-bits are operable
%if CNTBK
%if DSPINTEG
			Call	CatchUp														;Emulate DSP
%else
			Mov		EBP,SPCExit													;Signal the emu to exit so the DSP can catch up
%endif
%endif
		.NoC2Inc:
	.NoT64Inc:
	Sub		[t8kHz],EDX
	JNS		short .NoT8Inc
		Add		dword [t8kHz],T8_CYC											;Reset clock pulse counter

		Mov		BL,[tControl]													;BL = Control register
		ShL		BL,7															;Copy timer enable bit into CF
		SbB		byte [t1Step],0
		JNC		short .NoC1Inc
			Mov		BH,[RAM+t1]
			Dec		BH
			Mov		[t1Step],BH
			Inc		byte [RAM+c1]
			And		byte [RAM+c1],0Fh
%if CNTBK
%if DSPINTEG
			Call	CatchUp
%else
			Mov		EBP,SPCExit
%endif
%endif
		.NoC1Inc:
		Add		BL,BL
		SbB		byte [t0Step],0
		JNC		short .NoC0Inc
			Mov		BH,[RAM+t0]
			Dec		BH
			Mov		[t0Step],BH
			Inc		byte [RAM+c0]
			And		byte [RAM+c0],0Fh
%if CNTBK
%if DSPINTEG
			Call	CatchUp
%else
			Mov		EBP,SPCExit
%endif
%endif
		.NoC0Inc:
	.NoT8Inc:

	Mov		EBX,[t64Cnt]
	Cmp		[t64DSP],EBX														;Interrupt Script700/DSP every 1Ts
	JE		short .NoDSP
		Mov		[t64DSP],EBX

		Test	dword [scr700cnt],-1											;TimeCount = 0?
		JZ		short .No700													;	Yes
		Sub		dword [scr700cnt],32											;TimeCount -= 32, TimeCount > 0?
		JG		short .No700													;	Yes

		Mov		BL,[scr700stf]													;BL = Stack Flag
		And		BL,04h															;BL = 0x04?
		JZ		short .Run700													;	No

		Add		dword [scr700cnt],32											;TimeCount += 32
		Add		dword [scr700cmp],32											;CmpParam[0] += 32
		Mov		BL,[outPortCp]													;BL = OutPort[0]
%ifdef SHVC_SOUND_SUPPORT
		Push	ESI,EDX
		Mov		ESI,-1
		Mov		DL,BL
		Call	ReadPort
		Mov		BL,DL
		Pop		EDX,ESI
%endif
		Cmp		[flushPort],BL													;FlushPort[0] = BL?
		JNE		short .No700													;	No

		And		byte [scr700stf],~04h											;Stack Flag &= ~0x04
		Sub		dword [scr700cnt],32											;TimeCount -= 32

		.Run700:
		Call	RunScript700													;Run Script700 emulation

		.No700:
%if INTBK && DSPINTEG
		Call	CatchUp															;Emulate DSP
%endif

	.NoDSP:

	;After the timers are updated, subtract the number of cycles emulated from the total number
	;passed in.  If we've emulated all clock cycles requested by the caller, then quit.  Otherwise
	;add another 32 and return to the fetcher.

	Sub		[clkTotal],EDX														;Have we executed all clock cycles?
	JLE		SPCExit																;	Yes, Quit

	Mov		BX,AX																;Calculate number of cycles to emulate
	Mov		EAX,[t64kHz]														;clkExec = (t64kHz < clkTotal) ? t64kHz : clkTotal
	Sub		EAX,[clkTotal]
	CDQ
	And		EAX,EDX
	Add		EAX,[clkTotal]
	Mov		[clkLeft],EAX
	Mov		[clkExec],EAX
	Mov		AX,BX																;Restore SPC.A, SPC.Y
	Jmp		EBP																	;Return to fetcher
; ----- degrade-factory code [END] -----


;===================================================================================================
;Counter Speed Hack
;
;Modifies the up counters so the next counter to increase will increase on the next 64kHz pulse.
;This guarantees the program will never have to poll the counters more than four consecutive times,
;which greatly increases emulation speed.
;
;In:
;   EBX -> Counter just read (FD-FFh)
;
;Out:
;   Counter = 0
;
;Destroys:
;   nothing

%if SPEED
CntHack:

	Test	byte [EBX],-1														;Is counter >0?
	JNZ		.Reset																;	Yes, No need to speed up then

	Test	byte [tControl],7													;Are any timers enabled?
	JNZ		.Reset
		Push	EAX,ECX,EDX

		;This code was added because some games repeatedly check or keep a running total of the number
		;of counter increases.  If more than 64 machine cycles go by between counter reads, we'll
		;assume that the program is doing other things besides polling the counter, and essentially
		;disable the speed hack.

		Mov		EAX,[t64Cnt]
		Sub		EAX,[oldT64]
		Cmp		EAX,(64 * CPU_CYC) / T64_CYC									;Wait for no more than 64 machine cycles
		Mov		EAX,[t64Cnt]
		Mov		[oldT64],EAX
		JA		.NoHack

		;Since we don't know which timers the program is using, the emulator breaks on all counter
		;increases.  Because of this, the hack needs to advance the next closest counter, regardless
		;of which counter is actually being read.  So the first step is to figure out how many clock
		;cycles are needed for each counter to increase, then choose the smallest value.
		;
		;Basically the following statement is used to convert each counter to cycles.  If the timer
		;is turned off, 2^32-1 is returned to guarentee that it's not chosen as a valid value.
		;
		; if (APURAM.control & 1)
		;    EDX = t0Step * T8_CYC + t8kHz; //T64_CYC for timer 2
		; else
		;    EDX = 0xffffffff;

		MovZX	ECX,byte [t2Step]												;Get up counter 2
		XOr		EDX,EDX
		ShL		ECX,7															;ECX *= 128
		Test	byte [tControl],4												;Is the timer enabled?
		SetNZ	DL																;	Yes, EDX will = 0, -1 otherwise
		LEA		ECX,[ECX*2+ECX]													;ECX *= 3 (384 = T64_CYC)
		Dec		EDX
		Add		ECX,[t64kHz]													;ECX += t64kHz
		Or		EDX,ECX															;EDX = -1 or cycles needed to increase counter 2

		MovZX	ECX,byte [t1Step]												;Do the same for counter 1
		XOr		EAX,EAX
		ShL		ECX,10															;ECX *= 1024 (128*8)
		Test	byte [tControl],2
		SetNZ	AL
		LEA		ECX,[ECX*2+ECX]													;ECX *= 3 (3072 = T8_CYC)
		Dec		EAX
		Add		ECX,[t8kHz]
		Or		EAX,ECX

		Cmp		EAX,EDX															;Does counter 1 have less time than counter 2?
		JB		short .Cnt1														;	Yes, Leave EAX with counter 1
			Mov		EAX,EDX														;EAX = Clocks left until counter 2 increases
		.Cnt1:

		MovZX	ECX,byte [t0Step]												;And for counter 0
		XOr		EDX,EDX
		ShL		ECX,10
		Test	byte [tControl],1
		SetNZ	DL
		LEA		ECX,[ECX*2+ECX]
		Dec		EDX
		Add		ECX,[t8kHz]
		Or		EDX,ECX

		Cmp		EAX,EDX															;Does counter 1 or 2 have less time than counter 0?
		JB		short .Cnt2
			Mov		EAX,EDX
		.Cnt2:

		;Once we've figured out the least number of cycles needed for a counter increase, we need to
		;make sure we have enough total cycles left to emulate.  Then make sure we have enough cycles
		;to increase the 64kHz timer.

		Cmp		EAX,[clkTotal]													;Are there enough clocks left for shortest cnt to inc?
		JB		short .Clk
			Mov		EAX,[clkTotal]												;	No, Change EAX to the # of cycles left to emulate
		.Clk:

		Cmp		EAX,T64_CYC														;Are there enough cycles for a 64kHz pulse?
		JB		short .NoHack													;	No, Quit since nothing will be modified

		;Now's the time to actually skip emulating clock cycles.  All we care about are 64kHz timer
		;increases, so first we divide the number of cycles to skip by T64_CYC and throw away the
		;remainder.  The number of pulses are added to T64Cnt, as if they really were emulated.
		;The pulses are then subtracted from t2Step.  Next the number of pulses is divided by 8 to
		;give us the number of 8kHz pulses to skip.  Since up to 7 64kHz pulses could occur before
		;one 8kHz pulse, the remainder is converted back into clock cycles and subtracted from t8kHz.
		;Finally, the total number of cycles skipped is subtracted from clkTotal.
		;
		; T64Cnt += EAX / T64_CYC;
		; t2Step -= EAX / T64_CYC;                       //# of 64kHz pulses
		; t8kHz -= ((EAX % T8_CYC) / T64_CYC) * T64_CYC; //Fraction of 8kHz pulses
		; t0Step -= EAX / T8_CYC;                        //# of 8kHz pulses
		; clkTotal -= EAX - (EAX % T64_CYC);             //Actual cycles skipped

		XOr		EDX,EDX															;EAX = # of 64kHz pulses
		Mov		ECX,T64_CYC
		Div		ECX

		Add		[t64Cnt],EAX													;Add pulses to 64kHz counter
		Sub		[t2Step],AL														;Subtract pulses from up counter 2
; ----- degrade-factory code [2019/07/07] -----
		Mov		dword [t64DSP],-1
; ----- degrade-factory code [END] -----

		Mov		EDX,EAX
		Mov		ECX,EAX
		And		EAX,7															;EAX = # of cycles to be subtracted from 8kHz timer
		ShR		EDX,3															;EDX = # of 8kHz pulses to be subtracted from up 0 & 1
		ShL		EAX,7
		ShL		ECX,7
		LEA		EAX,[EAX*2+EAX]
		LEA		ECX,[ECX*2+ECX]													;ECX = Total number of emulated clock cycles skipped

		Sub		[t8kHz],EAX
		Sub		[t0Step],DL
		Sub		[t1Step],DL
		Sub		[clkTotal],ECX

		Pop		EDX,ECX,EAX
		Ret

		.NoHack:
		Pop		EDX,ECX,EAX
		Ret

	.Reset:
	Mov		byte [EBX],0
	Ret
%endif


;===================================================================================================
;Sleep Speed Hack
;
;Simulates executing the SLEEP instruction x times by reducing clkTotal to a value less than 3, and
;updating all timers and counters accordingly.
;
;In:
;   nothing
;
;Destroys:
;   EDX

%if SPEED
SleepHack:
	Push	EAX,ECX

	Mov		EAX,[clkExec]														;EAX = Cycles that have been emulated
	Sub		EAX,[clkLeft]
	Sub		[clkTotal],EAX

	Mov		EAX,[clkTotal]														;EAX = Total cycles left to emulate
	XOr		EDX,EDX
	Mov		ECX,3
	Div		ECX																	;EAX = # of SLEEP instructions that can be emulated
	Sub		[clkTotal],EDX														;Make clkTotal divisible by 3
	Mov		[clkExec],EDX
	Mov		[clkLeft],EDX

	;Timers 0 and 1 --------------------------
	Mov		EAX,[clkTotal]
	XOr		EDX,EDX
	Mov		ECX,T8_CYC
	Div		ECX																	;EAX = # of 8kHz cycles

	Sub		[t8kHz],EDX
	JNS		short .No8Inc
		Add		dword [t8kHz],T8_CYC
		Inc		EAX
	.No8Inc:

	Push	EAX
	MovZX	EDX,byte [t0Step]
	Inc		EDX
	Sub		EDX,EAX
	JG		short .NoC0Inc
		Neg		EAX
		XOr		EDX,EDX

		MovZX	ECX,byte [RAM+t0]
		Dec		CL

; ----- degrade-factory code [2015/11/23] -----
		JZ		short .SkipT0
			Div		ECX
		.SkipT0:
; ----- degrade-factory code [END] -----

		Add		[RAM+c0],AL
		And		byte [RAM+c0],0Fh

		Mov		CL,DL
		Mov		DL,[RAM+t0]
		Sub		DL,CL
	.NoC0Inc:
	Mov		[t0Step],DL

	Pop		EAX
	MovZX	EDX,byte [t1Step]
	Inc		EDX
	Sub		EDX,EAX
	JG		short .NoC1Inc
		Neg		EAX
		XOr		EDX,EDX

		MovZX	ECX,byte [RAM+t1]
		Dec		CL

; ----- degrade-factory code [2015/11/23] -----
		JZ		short .SkipT1
			Div		ECX
		.SkipT1:
; ----- degrade-factory code [END] -----

		Add		[RAM+c1],AL
		And		byte [RAM+c1],0Fh

		Mov		CL,DL
		Mov		DL,[RAM+t1]
		Sub		DL,CL
	.NoC1Inc:
	Mov		[t1Step],DL

	;Timer 2 ---------------------------------
	Mov		EAX,[clkTotal]
	XOr		EDX,EDX
	Mov		ECX,T64_CYC
	Div		ECX

	Sub		[t64kHz],EDX
	JNS		short .No64Inc
		Add		dword [t64kHz],T64_CYC
		Inc		EAX
	.No64Inc:

	MovZX	EDX,byte [t2Step]
	Inc		EDX
	Sub		EDX,EAX
	JG		short .NoC2Inc
		Neg		EAX
		XOr		EDX,EDX

		MovZX	ECX,byte [RAM+t2]
		Dec		CL

; ----- degrade-factory code [2015/11/23] -----
		JZ		short .SkipT2
			Div		ECX
		.SkipT2:
; ----- degrade-factory code [END] -----

		Add		[RAM+c2],AL
		And		byte [RAM+c2],0Fh

		Mov		CL,DL
		Mov		DL,[RAM+t2]
		Sub		DL,CL
	.NoC2Inc:
	Mov		[t2Step],DL

	Mov		EAX,[clkLeft]
	Mov		[clkTotal],EAX

	Pop		ECX,EAX

Ret
%endif

;===================================================================================================
;Macros

;===================================================================================================
;Load pointers
;   Load DPI or ABSL (aliases for EBX) with the value needed by the instruction.
;
;dp - Load DPI with the 8-bit immediate value
%macro Ldp 0
	Mov		EBX,dword [PSW+P-1]													;EBX-> Direct Page 0 or 1
	Mov		BL,[OP1]															;BL-> Location in DP
%endmacro

;dp - Load DPI with the 2nd 8-bit immediate value
%macro Ldp2 0
	Mov		EBX,dword [PSW+P-1]
	Mov		BL,[OP2]
%endmacro

;(X) - Load DPI with the value in X
%macro LX 0
	Mov		EBX,dword [PSW+P-1]
	Mov		BL,X
%endmacro

;(Y) - Load DPI with the value in Y
%macro LY 0
	Mov		EBX,dword [PSW+P-1]
	Mov		BL,Y
%endmacro

;dp+X - Load DPI with the 8-bit immediate value + X
%macro LdpX 0
	Ldp
	Add		BL,X
%endmacro

;dp+Y - Load DPI with the 8-bit immediate value + Y
%macro LdpY 0
	Ldp
	Add		BL,Y
%endmacro

;abs - Load ABSL with the 16-bit immediate value
%macro Labs 0
	Mov		EBX,[pAPURAM]
	Mov		BX,[OP1]
%endmacro

;abs+X - Load ABSL with the 16-bit immediate value + X
%macro LabsX 0
	Mov		EBX,[pAPURAM]
	Mov		BL,X
	Add		BX,[OP1]
%endmacro

;abs+Y - Load ABSL with the 16-bit immediate value + Y
%macro LabsY 0
	Mov		EBX,[pAPURAM]
	Mov		BL,Y
	Add		BX,[OP1]
%endmacro

;[dp+X] - Load ABSL with the 16-bit value at [dp+X]
%macro LadpX 0
	LdpX
	Mov		BX,[DPI]
%endmacro

;[dp]+Y - Load ABSL with the 16-bit value at [dp] + Y
%macro LadpY 0
	Ldp
	Mov		BX,[DPI]
	Add		BL,Y
	AdC		BH,0
%endmacro

;[abs+X] - Load ABSL with the 16-bit value at [abs+X]
%macro LaabsX 0
	Mov		EBX,[pAPURAM]
	Mov		BL,X
	Add		BX,[OP1]
%endmacro

;mem.bit - Load ABSL with the first 13-bits of the immediate value, and DL with the last 3
;   ABSL-> byte in mem 0-1FFFh
;   DL  -> bit in byte
%macro Lmbit 0
	Labs
	Mov		DL,BH
	ShR		DL,5
	And		BH,1Fh
%endmacro


;===================================================================================================
;Get flags from CPU
;   The x86 CPU updates its flags with the execution of each instruction.  So these macros update
;   the PSW with the x86 equivilants.
;
;Get Carry flag
%macro GetC 0
	SetC	[PSW+CF]
%endmacro

;Get Not Carry flag
%macro GetCs 0
	SetNC	[PSW+CF]
%endmacro

;Get Negative and Zero flags
%macro GetNZ 0
	SetS	[PSW+N]
	SetZ	[PSW+Z]
%endmacro

;Get Negative, Zero, and Carry flags
%macro GetNZC 0
	GetC
	GetNZ
%endmacro

;Get Negative, Zero, and Not Carry flags (for compare instructions)
%macro GetNZCs 0
	GetCs
	GetNZ
%endmacro

;Get Negative, Overflow, and Zero flags
%macro GetNVZ 0
	GetNZ
	SetO	[PSW+V]
%endmacro

;Get Negative, Overflow, Half-Carry, Zero, and Carry flags (for addition instructions)
%macro GetNVHZC 0
	GetC
	GetNVZ
%if HALFC
	Mov		DH,AH
	LAHF
	ShL		AH,4
	SetC	[PSW+H]
	Mov		AH,DH
%endif
%endmacro

;Get Negative, Overflow, Half-Carry, Zero, and Not Carry flags (for subtraction instructions)
%macro GetNVHZCs 0
	GetCs
	GetNVZ
%if HALFC
	Mov		DH,AH
	LAHF
	ShL		AH,4
	SetNC	[PSW+H]
	Mov		AH,DH
%endif
%endmacro


;===================================================================================================
;Memory checkers
;   Certain sections of memory can't be written to or read from, or trigger events when read or
;   modified.  This is the part that really slows emulation down, for every instruction involving
;   memory multiple checks have to be performed.
;
;Peform functions when specific memory locations have been modified.
;   Opt - bit-7 ROM checking needs to be performed
;         bit-0 Data written was 16-bit
%macro WrPost 1

%if %1 & 80h
	Cmp		BX,ipl																;Was memory in the IPL ROM region modified?
	JAE		short %%WROM														;	Yes
%endif

	Dec		BH
	Cmp		BX,0FFF0h															;Was a function register written to?
%if DEBUG
	JAE		short %%WReg														;	Yes, Jump to handler
		Jmp		EBP																;	No, Jump to next opcode
	%%WReg:
%else
	JB		SPCFetch
%endif
; ----- degrade-factory code [2007/10/07] -----
		Mov		CL,BL															;EBX->Function register handler
		And		CL,0Fh
		MovZX	EBX,CL
		Mov		EBX,[fncOfs+EBX*4]
; ----- degrade-factory code [END] -----
%if %1 & 1
; ----- degrade-factory code [2007/10/07] -----
		Push	EBX																;Save low function register handler
		Inc		CL																;Jump to next function register
		MovZX	EBX,CL
		Mov		EBX,[fncOfs+EBX*4]
		Mov		EBP,Func0+10h
; ----- degrade-factory code [END] -----
%endif
		Jmp		EBX

%if %1 & 80h
	%%WROM:
%if IPLW
		Test	byte [tControl],80h												;Is ROM reading enabled?
%if DEBUG
		JZ		short %%WNext													;	No, write was okay
%else
		JZ		SPCFetch
%endif
%endif
			Sub		BX,ipl														;Convert BX to index within IPL ROM region
			MovZX	EBX,BX
%if IPLW
			Mov		CL,[EBX+RAM+ipl]											;Get the byte written
			Mov		[EBX+extraRAM],CL
			Mov		CL,[EBX+iplROM]												;Replace ROM byte
%else
			Mov		CL,[EBX+extraRAM]
%endif
			Mov		[EBX+RAM+ipl],CL
%if DEBUG
		%%WNext:
		Jmp		EBP
%else
		Jmp		SPCFetch
%endif
%endif

%endmacro

;Perform functions when specific memory locations have been read
;   Opt - bit-1 Next instruction should be fetched after check
;         bit-0 Data read was 16-bit

%macro ResetCnt 0
	Inc		BH																	;EBX -> Counter
%if SPEED
	Call	CntHack																;Call speed hack
%else
	Mov		byte [EBX],0														;Reset counter
%endif
%endmacro

%macro CheckDSP 0
%if DSPBK && DSPINTEG
	Cmp		BX,0F3h
	JNE		short %%NotF3
		Call	CatchUp
	%%NotF3:
%endif
%endmacro

%macro BreakDSP 0
%if DSPBK && (DSPINTEG == 0)
	Cmp		BX,0FFF3h
	JNE		short %%NotF3
		Push	EAX
		Mov		EBP,SPCExit
		Mov		EAX,[clkLeft]
		Add		[clkExec],EAX
		Sub		[clkLeft],EAX
		Pop		EAX
	%%NotF3:
%endif
%endmacro

%macro RdPost 1
	Dec		BH
	BreakDSP
	Cmp		BX,0FFFDh															;Was a counter read from?

%if %1 & 2
%if DEBUG
	JAE		short %%RNext														;	Yes
		Jmp		EBP																;Jump back to fetch
	%%RNext:
	ResetCnt
	Jmp		EBP
%else
	JB		SPCFetch
	ResetCnt
	Jmp		SPCFetch
%endif
%else
	JB		short %%RNext														;	No, Continue with opcode
	ResetCnt
	%%RNext:
%endif

%endmacro


;===================================================================================================
;Clean up after executing an instruction
;   Updates flags to reflect instruction, checks memory read/writes, and decreases the clock counter
;   the number of cycles it takes for the instruction to execute on the SPC700.  If the opcode has
;   any operands, PC is moved past them.
;
;   %1 = Number of clock cycles instruction takes to execute
;   %2 = Number of bytes in expression
;   %3 = Check memory
;        01h - perform post write checking
;        02h - perform post read checking
;        04h - 16-bit operation
;        08h - check absolute address
;   %4 = Flags to be updated
;        NZ, NZC(s), NVZ, NVZC(s)
%macro CleanUp 2-*

	%if %0 >= 4																	;Is flag paramater not blank?
		Get%4																	;	Yes, Get modified flags
	%endif

; ----- degrade-factory code [2008/01/11] -----
	Sub		dword [clkLeft],%1*CPU_CYC											;Subtract cycles instruction takes to execute
; ----- degrade-factory code [END] -----

	%if %2 > 1																	;Is number of instruction bytes greater than 1?
		%rep %2-1																;	Yes, Increase PC for each operand byte
			Inc		PC
		%endrep
	%endif

	%if %0 >= 3																	;Is memory check parameter not blank?
		%ifidn %3,na															;Is parameter equal to nothing (0)?
%if DEBUG
			Jmp		EBP															;	Yes, Fetch next opcode
%else
			Jmp		SPCFetch
%endif
		%endif
		%if %3 & 1																;Is write check bit in parameter set?
			%if %3 & 8															;Is it possible to write to IPL ROM region?
				WrPost	80h														;	Yes, Check for ROM writes
			%else																;	No, Just check for function register writes
				%if %3 & 4														;Was a 16-bit value written?
					WrPost	1													;	Yes
				%else
					WrPost	0													;	No
				%endif
			%endif
		%endif

		%if %3 & 2																;Is read check bit in parameter set?
			%if %3 & 4
				RdPost	3
			%else
				RdPost	2
			%endif
		%endif
	%else
%if DEBUG
		Jmp		EBP																;	No, Grab next opcode
%else
		Jmp		SPCFetch
%endif
	%endif

%endmacro


;===================================================================================================
;Stack Operations

;Pop byte off stack
;   Val - r/m to pop
; ----- degrade-factory code [2011/04/10] -----
%macro PopB 1
	Inc		byte [regSP]														;Increase SP
	Mov		EBX,[regSP]															;EBX -> Current stack position
	Mov		%1,[EBX]															;Get value from stack
%endmacro
; ----- degrade-factory code [END] -----

;Pop word off stack
;   Val - r/m to pop
; ----- degrade-factory code [2007/09/01] -----
%macro PopW 1
	Mov		EBX,[regSP]															;EBX -> Current stack position
	Inc		BL																	;Increase SP
	Mov		DL,[EBX]															;Get value from stack (LOW)
	Inc		BL																	;Increase SP
	Mov		DH,[EBX]															;Get value from stack (HIGH)
	Mov		[regSP],EBX
	Mov		%1,DX
%endmacro
; ----- degrade-factory code [END] -----

;Push byte onto stack
;   Val - r/m to push
; ----- degrade-factory code [2011/04/10] -----
%macro PushB 1
	Mov		EBX,[regSP]															;EBX -> Current stack position
	Dec		byte [regSP]														;Decrease SP
	Mov		[EBX],%1															;Put value in stack
%endmacro
; ----- degrade-factory code [END] -----

;Push word onto stack
;   Val - r/m to push
; ----- degrade-factory code [2007/09/01] -----
%macro PushW 1
	Mov		DX,%1
	Mov		EBX,[regSP]															;EBX -> Current stack position
	Mov		[EBX],DH															;Put value in stack (HIGH)
	Dec		BL																	;Decrease SP
	Mov		[EBX],DL															;Put value in stack (LOW)
	Dec		BL																	;Decrease SP
	Mov		[regSP],EBX
%endmacro
; ----- degrade-factory code [END] -----


;===================================================================================================
;Opcode Handlers
;
;Ins - Desc
; Flags
;Form
;
;Ins:   Mnemonic for instruction
;
;Desc:  Long name for instruction
;
;Flags: Results of flag after execution
;       ? - Unknown
;       * - Reflects result of instruction
;       0 - Clear
;       1 - Set
;
;Form:  Format implemented
;
;===================================================================================================
;Once the table is built, entrance can be called indirectly at EmuSPC.
;
;Upon entrance to an opcode handler, the registers will be:
;   AL  = SPC.A
;   AH  = SPC.Y
;   EBX = ?
;   CL  = ?
;   CH  = SPC.X
;   EDX-> Entry point of current opcode handler
;   SI  = SPC.PC+1
;   ESI-> First byte after opcode
;   EDI-> Base of SPC RAM
;   EBP-> SPCFetch (SPCTrace if debugging is enabled)
;
;   CL, EDX, and EBX may be freely modified.  All other registers must reflect the results of the
;   operation or remain unchanged.
;
;===================================================================================================
;Opcodes:
;
;   00 NOP     10 BPL     20 CLRP    30 BMI     40 SETP    50 BVC     60 CLRC    70 BVS
;   01 TCALL   11 TCALL   21 TCALL   31 TCALL   41 TCALL   51 TCALL   61 TCALL   71 TCALL
;   02 SET1    12 CLR1    22 SET1    32 CLR1    42 SET1    52 CLR1    62 SET1    72 CLR1
;   03 BBS     13 BBC     23 BBS     33 BBC     43 BBS     53 BBC     63 BBS     73 BBC
;   04 OR      14 OR      24 AND     34 AND     44 EOR     54 EOR     64 CMP     74 CMP
;   05 OR      15 OR      25 AND     35 AND     45 EOR     55 EOR     65 CMP     75 CMP
;   06 OR      16 OR      26 AND     36 AND     46 EOR     56 EOR     66 CMP     76 CMP
;   07 OR      17 OR      27 AND     37 AND     47 EOR     57 EOR     67 CMP     77 CMP
;   08 OR      18 OR      28 AND     38 AND     48 EOR     58 EOR     68 CMP     78 CMP
;   09 OR      19 OR      29 AND     39 AND     49 EOR     59 EOR     69 CMP     79 CMP
;   0A OR1     1A DECW    2A OR1     3A INCW    4A AND1    5A CMPW    6A AND1    7A ADDW
;   0B ASL     1B ASL     2B ROL     3B ROL     4B LSR     5B LSR     6B ROR     7B ROR
;   0C ASL     1C ASL     2C ROL     3C ROL     4C LSR     5C LSR     6C ROR     7C ROR
;   0D PUSH    1D DEC     2D PUSH    3D INC     4D PUSH    5D MOV     6D PUSH    7D MOV
;   0E TSET1   1E CMP     2E CBNE    3E CMP     4E TCLR1   5E CMP     6E DBNZ    7E CMP
;   0F BRK     1F JMP     2F BRA     3F CALL    4F PCALL   5F JMP     6F RET     7F RETI
;
;   80 SETC    90 BCC     A0 EI      B0 BCS     C0 DI      D0 BNE     E0 CLRV    F0 BEQ
;   81 TCALL   91 TCALL   A1 TCALL   B1 TCALL   C1 TCALL   D1 TCALL   E1 TCALL   F1 TCALL
;   82 SET1    92 CLR1    A2 SET1    B2 CLR1    C2 SET1    D2 CLR1    E2 SET1    F2 CLR1
;   83 BBS     93 BBC     A3 BBS     B3 BBC     C3 BBS     D3 BBC     E3 BBS     F3 BBC
;   84 ADC     94 ADC     A4 SBC     B4 SBC     C4 MOV     D4 MOV     E4 MOV     F4 MOV
;   85 ADC     95 ADC     A5 SBC     B5 SBC     C5 MOV     D5 MOV     E5 MOV     F5 MOV
;   86 ADC     96 ADC     A6 SBC     B6 SBC     C6 MOV     D6 MOV     E6 MOV     F6 MOV
;   87 ADC     97 ADC     A7 SBC     B7 SBC     C7 MOV     D7 MOV     E7 MOV     F7 MOV
;   88 ADC     98 ADC     A8 SBC     B8 SBC     C8 CMP     D8 MOV     E8 MOV     F8 MOV
;   89 ADC     99 ADC     A9 SBC     B9 SBC     C9 MOV     D9 MOV     E9 MOV     F9 MOV
;   8A EOR1    9A SUBW    AA MOV1    BA MOVW    CA MOV1    DA MOVW    EA NOT1    FA MOV
;   8B DEC     9B DEC     AB INC     BB INC     CB MOV     DB MOV     EB MOV     FB MOV
;   8C DEC     9C DEC     AC INC     BC INC     CC MOV     DC DEC     EC MOV     FC INC
;   8D MOV     9D MOV     AD CMP     BD MOV     CD MOV     DD MOV     ED NOTC    FD MOV
;   8E POP     9E DIV     AE POP     BE DAA     CE POP     DE CBNE    EE POP     FE DBNZ
;   8F MOV     9F XCN     AF MOV     BF MOV     CF MUL     DF DAS     EF SLEEP   FF STOP


;===================================================================================================
;NOP - No Operation
; N V P B H I Z C
;
;NOp
%macro Opc00 0
	CleanUp	2,1																	;Do nothing
%endmacro


;===================================================================================================
;ADC - Add with Carry
; N V P B H I Z C
; * *     *   * *
;AdC A,#imm
%macro Opc88 0
	ShR		byte [PSW+CF],1
	AdC		A,[OP1]
	CleanUp	2,2,na,NVHZC
%endmacro

;AdC A,dp
%macro Opc84 0
	Ldp
	CheckDSP
	ShR		byte [PSW+CF],1
	AdC		A,[DPI]
	CleanUp	3,2,RD,NVHZC
%endmacro

;AdC A,dp+X
%macro Opc94 0
	LdpX
	CheckDSP
	ShR		byte [PSW+CF],1
	AdC		A,[DPI]
	CleanUp	4,2,RD,NVHZC
%endmacro

;AdC A,abs
%macro Opc85 0
	Labs
	CheckDSP
	ShR		byte [PSW+CF],1
	AdC		A,[ABSL]
	CleanUp	4,3,RA,NVHZC
%endmacro

;AdC A,abs+X
%macro Opc95 0
	LabsX
	CheckDSP
	ShR		byte [PSW+CF],1
	AdC		A,[ABSL]
	CleanUp	5,3,RA,NVHZC
%endmacro

;AdC A,abs+Y
%macro Opc96 0
	LabsY
	CheckDSP
	ShR		byte [PSW+CF],1
	AdC		A,[ABSL]
	CleanUp	5,3,RA,NVHZC
%endmacro

;AdC A,(X)
%macro Opc86 0
	LX
	CheckDSP
	ShR		byte [PSW+CF],1
	AdC		A,[DPI]
	CleanUp	3,1,RD,NVHZC
%endmacro

;AdC A,[dp+X]
%macro Opc87 0
	LadpX
	CheckDSP
	ShR		byte [PSW+CF],1
	AdC		A,[ABSL]
	CleanUp	6,2,RA,NVHZC
%endmacro

;AdC A,[dp]+Y
%macro Opc97 0
	LadpY
	CheckDSP
	ShR		byte [PSW+CF],1
	AdC		A,[ABSL]
	CleanUp	6,2,RA,NVHZC
%endmacro

;AdC dp,#imm
%macro Opc98 0
	Mov		DH,[OP1]
	Ldp2
	ShR		byte [PSW+CF],1
	AdC		[DPI],DH
	CleanUp	5,3,WD,NVHZC
%endmacro

;AdC dp,dp
%macro Opc89 0
	Ldp
	CheckDSP
	Mov		DH,[DPI]
	RdPost	0
	Ldp2
	ShR		byte [PSW+CF],1
	AdC		[DPI],DH
	CleanUp	6,3,WD,NVHZC
%endmacro

;AdC (X),(Y)
%macro Opc99 0
	LY
	CheckDSP
	Mov		DH,[DPI]
	RdPost	0
	LX
	ShR		byte [PSW+CF],1
	AdC		[DPI],DH
	CleanUp	5,1,WD,NVHZC
%endmacro


;===================================================================================================
;ADDW - Add Word
; N V P B H I Z C
; * *     *   * *
;AddW YA,dp
%macro Opc7A 0
	Ldp
	Add		YA,[DPI]
	CleanUp	5,2,RD16,NVHZC
%endmacro


;===================================================================================================
;AND - Bit-wise Logical And
; N V P B H I Z C
; *           *
;And A,#imm
%macro Opc28 0
	And		A,[OP1]
	CleanUp	2,2,na,NZ
%endmacro

;And A,dp
%macro Opc24 0
	Ldp
	CheckDSP
	And		A,[DPI]
	CleanUp	3,2,RD,NZ
%endmacro

;And A,dp+X
%macro Opc34 0
	LdpX
	CheckDSP
	And		A,[DPI]
	CleanUp	4,2,RD,NZ
%endmacro

;And A,abs
%macro Opc25 0
	Labs
	CheckDSP
	And		A,[ABSL]
	CleanUp	4,3,RA,NZ
%endmacro

;And A,abs+X
%macro Opc35 0
	LabsX
	CheckDSP
	And		A,[ABSL]
	CleanUp	5,3,RA,NZ
%endmacro

;And A,abs+Y
%macro Opc36 0
	LabsY
	CheckDSP
	And		A,[ABSL]
	CleanUp	5,3,RA,NZ
%endmacro

;And A,(X)
%macro Opc26 0
	LX
	CheckDSP
	And		A,[DPI]
	CleanUp	3,1,RD,NZ
%endmacro

;And A,[dp+X]
%macro Opc27 0
	LadpX
	CheckDSP
	And		A,[ABSL]
	CleanUp	6,2,RA,NZ
%endmacro

;And A,[dp]+Y
%macro Opc37 0
	LadpY
	CheckDSP
	And		A,[ABSL]
	CleanUp	6,2,RA,NZ
%endmacro

;And dp,#imm
%macro Opc38 0
	Ldp2
	Mov		DH,[OP1]
	And		[DPI],DH
	CleanUp	5,3,WD,NZ
%endmacro

;And dp,dp
%macro Opc29 0
	Ldp
	CheckDSP
	Mov		DH,[DPI]
	RdPost	0
	Ldp2
	And		[DPI],DH
	CleanUp	6,3,WD,NZ
%endmacro

;And (X),(Y)
%macro Opc39 0
	LY
	CheckDSP
	Mov		DH,[DPI]
	RdPost	0
	LX
	And		[DPI],DH
	CleanUp	5,1,WD,NZ
%endmacro


;===================================================================================================
;AND1 - And Carry with Absolute Bit
; N V P B H I Z C
;               *
;And1 C,mem.bit
%macro Opc4A 0
	Cmp		byte [PSW+CF],0														;Is carry zero?
	JZ		short %%Nc															;	Yes, Result will be zero anyway so quit
		Lmbit
		Mov		BL,[ABSL]
		BT		EBX,EDX															;(Bit Test only uses the first five bits of EDX)
		CleanUp	4,3,na,C
	%%Nc:
	CleanUp	4,3
%endmacro

;And1 C,/mem.bit
%macro Opc6A 0
	Cmp		byte [PSW+CF],0
	JZ		short %%Ncn
		Lmbit
		Mov		BL,[ABSL]
		BT		EBX,EDX
		CleanUp	4,3,na,Cs
	%%Ncn:
	CleanUp	4,3
%endmacro


;===================================================================================================
;ASL - Arithmetic Shift Left
; N V P B H I Z C
; *           * *
;ASL A
%macro Opc1C 0
	ShL		A,1
	CleanUp	2,1,na,NZC
%endmacro

;ASL dp
%macro Opc0B 0
	Ldp
	ShL		byte [DPI],1
	CleanUp	4,2,WD,NZC
%endmacro

;ASL dp+X
%macro Opc1B 0
	LdpX
	ShL		byte [DPI],1
	CleanUp	5,2,WD,NZC
%endmacro

;ASL abs
%macro Opc0C 0
	Labs
	ShL		byte [ABSL],1
	CleanUp	5,3,WA,NZC
%endmacro


;===================================================================================================
;BBC - Branch If Bit Clear
; N V P B H I Z C

	;-----------------------------------------
	;Branch if bit clear
	;   %1 - Bit to test (0-7)

	%macro BBC 1
		Ldp																		;Load DP pointer
		Test	byte [DPI],1 << %1												;Test requested bit, is it clear?
		JNZ		short %%BCDone													;	No, Clean up
			MovSX	EDX,byte [OP2]												;EDX = Relative adjustment
			Add		PC,DX														;Adjust PC
			CleanUp	7,3,RD
		%%BCDone:
		CleanUp	5,3,RD
	%endmacro

;BBC dp.0,rel
%macro Opc13 0
	BBC		0
%endmacro

;BBC dp.1,rel
%macro Opc33 0
	BBC		1
%endmacro

;BBC dp.2,rel
%macro Opc53 0
	BBC		2
%endmacro

;BBC dp.3,rel
%macro Opc73 0
	BBC		3
%endmacro

;BBC dp.4,rel
%macro Opc93 0
	BBC		4
%endmacro

;BBC dp.5,rel
%macro OpcB3 0
	BBC		5
%endmacro

;BBC dp.6,rel
%macro OpcD3 0
	BBC		6
%endmacro

;BBC dp.7,rel
%macro OpcF3 0
	BBC		7
%endmacro


;===================================================================================================
;BBS - Branch If Bit Set
; N V P B H I Z C

	;-----------------------------------------
	;Branch if bit set
	;   %1 - Bit to test (0-7)

	%macro BBS 1
		Ldp
		Test	byte [DPI],1 << %1												;Test the requested bit, is it set?
		JZ		short %%BSDone													;	No, Clean up
			MovSX	EDX,byte [OP2]												;DX = Relative adjustment
			Add		PC,DX														;Add relative displacement to PC
			CleanUp	7,3,RD
		%%BSDone:
		CleanUp	5,3,RD
	%endmacro

;BBS dp.0,rel
%macro Opc03 0
	BBS		0
%endmacro

;BBS dp.1,rel
%macro Opc23 0
	BBS		1
%endmacro

;BBS dp.2,rel
%macro Opc43 0
	BBS		2
%endmacro

;BBS dp.3,rel
%macro Opc63 0
	BBS		3
%endmacro

;BBS dp.4,rel
%macro Opc83 0
	BBS		4
%endmacro

;BBS dp.5,rel
%macro OpcA3 0
	BBS		5
%endmacro

;BBS dp.6,rel
%macro OpcC3 0
	BBS		6
%endmacro

;BBS dp.7,rel
%macro OpcE3 0
	BBS		7
%endmacro


;===================================================================================================
;Bxx - Conditional Branch
; N V P B H I Z C

	;-----------------------------------------
	;Branch on condition
	;   %1 - Flag to Test
	;   %2 - Condition of flag (0 or 1)

	%macro Bxx 2
		Test	byte [PSW+%1],1
		%if %2 == 1
			JZ		short %%BxDone
		%else
			JNZ		short %%BxDone
		%endif
			MovSX	EBX,byte [OP1]
			Add		PC,BX
			CleanUp	4,2
		%%BxDone:
		CleanUp	2,2
	%endmacro

;BCC rel - Branch if Carry Clear (JAE)
%macro Opc90 0
	Bxx		CF,0
%endmacro

;BCS rel - Branch if Carry Set (JB)
%macro OpcB0 0
	Bxx		CF,1
%endmacro

;BNE rel - Branch if Not Equal (JNE/JNZ)
%macro OpcD0 0
	Bxx		Z,0
%endmacro

;BEQ rel - Branch if Equal (JE/JZ)
%macro OpcF0 0
	Bxx		Z,1
%endmacro

;BVC rel - Branch if Overflow Clear (JNO)
%macro Opc50 0
	Bxx		V,0
%endmacro

;BVS rel - Branch if Overflow Set (JO)
%macro Opc70 0
	Bxx		V,1
%endmacro

;BPL rel - Branch if Plus (JNS)
%macro Opc10 0
	Bxx		N,0
%endmacro

;BMI rel - Branch if Minus (JS)
%macro Opc30 0
	Bxx		N,1
%endmacro


;===================================================================================================
;BRA - Branch (JMP Short)
; N V P B H I Z C
;
;BRA rel
%macro Opc2F 0
	MovSX	EBX,byte [OP1]
	Add		PC,BX
	CleanUp	4,2
%endmacro


;===================================================================================================
;BRK - Software Interrupt
; N V P B H I Z C
;       1   0
;Brk
%macro Opc0F 0
	PushW	PC
	CmpPSW
	PushB	PS
	Mov		PC,[0FFDEh+RAM]
; ----- degrade-factory code [2020/10/20] -----
	Mov		byte [PSW+B],1
	Mov		byte [PSW+I],0
; ----- degrade-factory code [END] #20 -----
	CleanUp	8,1
%endmacro


;===================================================================================================
;CALL - Call Procedure
; N V P B H I Z C
;
;Call abs
%macro Opc3F 0
	Add		PC,2
	PushW	PC
	Mov		PC,[ESI-2]
	CleanUp	8,na
%endmacro


;===================================================================================================
;CBNE - Compare with A, Branch if Not Equal
; N V P B H I Z C
;
;CBNE dp,rel
%macro Opc2E 0
	Ldp
	CheckDSP
	Cmp		A,[DPI]
	JE		short %%NCBdp
		MovSX	EDX,byte [OP2]
		Add		PC,DX
		CleanUp	7,3,RD
	%%NCBdp:
	CleanUp	5,3,RD
%endmacro

;CBNE dp+X,rel
%macro OpcDE 0
	LdpX
	CheckDSP
	Cmp		A,[DPI]
	JE		short %%NCBdpx
		MovSX	EDX,byte [OP2]
		Add		PC,DX
		CleanUp	8,3,RD
	%%NCBdpx:
	CleanUp	6,3,RD
%endmacro


;===================================================================================================
;CLR1 - Clear Bit
; N V P B H I Z C

	;-----------------------------------------
	;Clear bit
	;   %1 - Bit to clear (0-7)

	%macro Clr 1
		Ldp
		And		byte [DPI],~(1 << %1)
		CleanUp	4,2,WD
	%endmacro

;Clr1 dp.0
%macro Opc12 0
	Clr		0
%endmacro

;Clr1 dp.1
%macro Opc32 0
	Clr		1
%endmacro

;Clr1 dp.2
%macro Opc52 0
	Clr		2
%endmacro

;Clr1 dp.3
%macro Opc72 0
	Clr		3
%endmacro

;Clr1 dp.4
%macro Opc92 0
	Clr		4
%endmacro

;Clr1 dp.5
%macro OpcB2 0
	Clr		5
%endmacro

;Clr1 dp.6
%macro OpcD2 0
	Clr		6
%endmacro

;Clr1 dp.7
%macro OpcF2 0
	Clr		7
%endmacro


;===================================================================================================
;CLRC - Clear Carry Flag
; N V P B H I Z C
;               0
;ClrC
%macro Opc60 0
	Mov		byte [PSW+CF],0
	CleanUp	2,1
%endmacro


;===================================================================================================
;CLRP - Clear Direct Page Flag
; N V P B H I Z C
;     0
;ClrP
%macro Opc20 0
	Mov		byte [PSW+P],0
	CleanUp	2,1
%endmacro


;===================================================================================================
;CLRV - Clear Overflow and Half-carry Flags
; N V P B H I Z C
;   0     0
;ClrV
%macro OpcE0 0
	Mov		byte [PSW+V],0
	Mov		byte [PSW+H],0
	CleanUp	2,1
%endmacro


;===================================================================================================
;CMP - Compare Two Operands
; N V P B H I Z C
; *           * *
;Cmp A,#imm
%macro Opc68 0
	Cmp		A,[OP1]
	CleanUp	2,2,na,NZCs
%endmacro

;Cmp X,#imm
%macro OpcC8 0
	Cmp		X,[OP1]
	CleanUp	2,2,na,NZCs
%endmacro

;Cmp Y,#imm
%macro OpcAD 0
	Cmp		Y,[OP1]
	CleanUp	2,2,na,NZCs
%endmacro

;Cmp A,dp
%macro Opc64 0
	Ldp
	CheckDSP
	Cmp		A,[DPI]
	CleanUp	3,2,RD,NZCs
%endmacro

;Cmp X,dp
%macro Opc3E 0
	Ldp
	CheckDSP
	Cmp		X,[DPI]
	CleanUp	3,2,RD,NZCs
%endmacro

;Cmp Y,dp
%macro Opc7E 0
	Ldp
	CheckDSP
	Cmp		Y,[DPI]
	CleanUp	3,2,RD,NZCs
%endmacro

;Cmp A,dp+X
%macro Opc74 0
	LdpX
	CheckDSP
	Cmp		A,[DPI]
	CleanUp	4,2,RD,NZCs
%endmacro

;Cmp A,abs
%macro Opc65 0
	Labs
	CheckDSP
	Cmp		A,[ABSL]
	CleanUp	4,3,RA,NZCs
%endmacro

;Cmp X,abs
%macro Opc1E 0
	Labs
	CheckDSP
	Cmp		X,[ABSL]
	CleanUp	4,3,RA,NZCs
%endmacro

;Cmp Y,abs
%macro Opc5E 0
	Labs
	CheckDSP
	Cmp		Y,[ABSL]
	CleanUp	4,3,RA,NZCs
%endmacro

;Cmp A,abs+X
%macro Opc75 0
	LabsX
	CheckDSP
	Cmp		A,[ABSL]
	CleanUp	5,3,RA,NZCs
%endmacro

;Cmp A,abs+Y
%macro Opc76 0
	LabsY
	CheckDSP
	Cmp		A,[ABSL]
	CleanUp	5,3,RA,NZCs
%endmacro

;Cmp A,(X)
%macro Opc66 0
	LX
	CheckDSP
	Cmp		A,[DPI]
	CleanUp	3,1,RD,NZCs
%endmacro

;Cmp A,[dp+X]
%macro Opc67 0
	LadpX
	CheckDSP
	Cmp		A,[ABSL]
	CleanUp	6,2,RA,NZCs
%endmacro

;Cmp A,[dp]+Y
%macro Opc77 0
	LadpY
	CheckDSP
	Cmp		A,[ABSL]
	CleanUp	6,2,RA,NZCs
%endmacro

;Cmp dp,#imm
%macro Opc78 0
	Ldp2
	Mov		DH,[OP1]
	Cmp		[DPI],DH
	CleanUp	5,3,RD,NZCs
%endmacro

;Cmp dp,dp
%macro Opc69 0
	Ldp
	CheckDSP
	Mov		DH,[DPI]
	RdPost	0
	Ldp2
	Cmp		[DPI],DH
	CleanUp	6,3,RD,NZCs
%endmacro

;Cmp (X),(Y)
%macro Opc79 0
	LY
	CheckDSP
	Mov		DH,[DPI]
	RdPost	0
	LX
	Cmp		[DPI],DH
	CleanUp	5,1,RD,NZCs
%endmacro


;===================================================================================================
;CMPW - Compare Two Words
; N V P B H I Z C
; *           * *
;CmpW YA,dp
%macro Opc5A 0
	Ldp
	Cmp		YA,[DPI]
	CleanUp	4,2,RD16,NZCs
%endmacro


;===================================================================================================
;DAA - Decimal Adjust After Addition
; N V P B H I Z C
; *           * *
;DAA A
%macro OpcDF 0
	Mov		DH,AH																;Save AH (Y)
	Mov		AH,[PSW+H]															;Set AF and CF in AH
	ShL		AH,4
	Or		AH,[PSW+CF]
	SAHF																		;Store AH into flags register
	Mov		AH,DH																;Restore AH
	DAA																			;Execute DAA on AL (A)
	CleanUp	3,1,na,NZC
%endmacro


;===================================================================================================
;DAS - Decimal Adjust After Subtraction
; N V P B H I Z C
; *           * *
;DAS A
%macro OpcBE 0
	Mov		DH,AH
	Mov		AH,[PSW+H]
	ShL		AH,4
	Or		AH,[PSW+CF]
	XOr		AH,11h																;Reverse flags for x86
	SAHF
	Mov		AH,DH
	DAS
	CleanUp	3,1,na,NZCs
%endmacro


;===================================================================================================
;DBNZ - Decrease byte, Branch if not Zero
; N V P B H I Z C
;
;DBNZ Y,rel
%macro OpcFE 0
	Dec		Y
	JZ		short %%NDBy
		MovSX	EBX,byte [OP1]
		Add		PC,BX
		CleanUp	6,2
	%%NDBy:
	CleanUp	4,2
%endmacro

;DBNZ dp,rel
%macro Opc6E 0
	Ldp
	Dec		byte [DPI]
	JZ		short %%NDBdp
		MovSX	EDX,byte [OP2]
		Add		PC,DX
		CleanUp	7,3,WD
	%%NDBdp:
	CleanUp	5,3,WD
%endmacro


;===================================================================================================
;DEC - Decrease Byte by 1
; N V P B H I Z C
; *           *
;Dec A
%macro Opc9C 0
	Dec		A
	CleanUp	2,1,na,NZ
%endmacro

;Dec X
%macro Opc1D 0
	Dec		X
	CleanUp	2,1,na,NZ
%endmacro

;Dec Y
%macro OpcDC 0
	Dec		Y
	CleanUp	2,1,na,NZ
%endmacro

;Dec dp
%macro Opc8B 0
	Ldp
	Dec		byte [DPI]
	CleanUp	4,2,WD,NZ
%endmacro

;Dec dp+X
%macro Opc9B 0
	LdpX
	Dec		byte [DPI]
	CleanUp	5,2,WD,NZ
%endmacro

;Dec abs
%macro Opc8C 0
	Labs
	Dec		byte [ABSL]
	CleanUp	5,3,WA,NZ
%endmacro


;===================================================================================================
;DECW - Decrease Word by 1
; N V P B H I Z C
; *           *
;DecW dp
%macro Opc1A 0
	Ldp
	Dec		word [DPI]
	CleanUp	6,2,WD16,NZ
%endmacro


;===================================================================================================
;DI - Disable Interrupts
; N V P B H I Z C
;           0
;DI
%macro OpcC0 0
	Mov		byte [PSW+I],0
	CleanUp	3,1
%endmacro


;===================================================================================================
;DIV - Divide
; N V P B H I Z C
; * *     *   *
;Div YA,X
%macro Opc9E 0
; ----- degrade-factory code [2010/09/25] -----
	MovZX	EDX,Y																;EDX = Y
	MovZX	EBX,X																;EBX = X
	Cmp		DL,BL
	SetAE	[PSW+V]

%if HALFC
	And		DL,0Fh
	And		BL,0Fh
	Cmp		DL,BL
	SetAE	[PSW+H]

	Mov		DL,Y
	Mov		BL,X
%endif

	Test	BL,BL
	JZ		short %%Div0

	Add		BX,BX																;BX = X << 1
	Cmp		DX,BX
	JAE		short %%DivOF
		XOr		DX,DX															;DX:AX = YA
		MovZX	BX,X															;BX = X

		Div		BX																;A = AL
		Mov		Y,DL															;Y = DL
		Test	A,A
		CleanUp	12,1,na,NZ

	%%Div0:
		RoL		YA,8
		Not		A
		Mov		byte [PSW+V],1
		Test	A,A
		CleanUp	12,1,na,NZ

	%%DivOF:
		XOr		DX,DX															;DX:AX = YA - X << 9
		MovZX	BX,X
		ShL		BX,9
		Sub		AX,BX

		MovZX	BX,X															;BX = 256 - X
		Not		BL
		Inc		BX

		Div		BX
		Not		A																;A = 255 - AL
		Add		DL,X															;Y = X + DL
		Mov		Y,DL
		Test	A,A
		CleanUp	12,1,na,NZ
; ----- degrade-factory code [END] -----
%endmacro


;===================================================================================================
;EI - Enable Interrupts
; N V P B H I Z C
;           1
;EI
%macro OpcA0 0
	Mov		byte [PSW+I],1
	CleanUp	3,1
%endmacro


;===================================================================================================
;EOR - Bit-wise Logical Exclusive Or
; N V P B H I Z C
; *           *
;EOr A,#imm
%macro Opc48 0
	XOr		A,[OP1]
	CleanUp	2,2,na,NZ
%endmacro

;EOr A,dp
%macro Opc44 0
	Ldp
	CheckDSP
	XOr		A,[DPI]
	CleanUp	3,2,RD,NZ
%endmacro

;EOr A,dp+X
%macro Opc54 0
	LdpX
	CheckDSP
	XOr		A,[DPI]
	CleanUp	4,2,RD,NZ
%endmacro

;EOr A,abs
%macro Opc45 0
	Labs
	CheckDSP
	XOr		A,[ABSL]
	CleanUp	4,3,RA,NZ
%endmacro

;EOr A,abs+X
%macro Opc55 0
	LabsX
	CheckDSP
	XOr		A,[ABSL]
	CleanUp	5,3,RA,NZ
%endmacro

;EOr A,abs+Y
%macro Opc56 0
	LabsY
	CheckDSP
	XOr		A,[ABSL]
	CleanUp	5,3,RA,NZ
%endmacro

;EOr A,(X)
%macro Opc46 0
	LX
	CheckDSP
	XOr		A,[DPI]
	CleanUp	3,1,RD,NZ
%endmacro

;EOr A,[dp+X]
%macro Opc47 0
	LadpX
	CheckDSP
	XOr		A,[ABSL]
	CleanUp	6,2,RA,NZ
%endmacro

;EOr A,[dp]+Y
%macro Opc57 0
	LadpY
	CheckDSP
	XOr		A,[ABSL]
	CleanUp	6,2,RA,NZ
%endmacro

;EOr dp,#imm
%macro Opc58 0
	Ldp2
	Mov		DH,[OP1]
	XOr		[DPI],DH
	CleanUp	5,3,WD,NZ
%endmacro

;EOr dp,dp
%macro Opc49 0
	Ldp
	CheckDSP
	Mov		DH,[DPI]
	RdPost	0
	Ldp2
	XOr		[DPI],DH
	CleanUp	6,3,WD,NZ
%endmacro

;EOr (X),(Y)
%macro Opc59 0
	LY
	CheckDSP
	Mov		DH,[DPI]
	RdPost	0
	LX
	XOr		[DPI],DH
	CleanUp	5,1,WD,NZ
%endmacro


;===================================================================================================
;EOR1 - XOr Carry with Absolute Bit
; N V P B H I Z C
;               *
;EOr1 C,mem.bit
%macro Opc8A 0
	Lmbit
	Push	EBX
	Mov		BL,[ABSL]
	BT		EBX,EDX
	AdC		byte [PSW+CF],0
	And		byte [PSW+CF],1
	Pop		EBX
	CleanUp	5,3,RA
%endmacro


;===================================================================================================
;INC - Increase Byte by 1
; N V P B H I Z C
; *           *
;Inc A
%macro OpcBC 0
	Inc		A
	CleanUp	2,1,na,NZ
%endmacro

;Inc X
%macro Opc3D 0
	Inc		X
	CleanUp	2,1,na,NZ
%endmacro

;Inc Y
%macro OpcFC 0
	Inc		Y
	CleanUp	2,1,na,NZ
%endmacro

;Inc dp
%macro OpcAB 0
	Ldp
	Inc		byte [DPI]
	CleanUp	4,2,WD,NZ
%endmacro

;Inc dp+X
%macro OpcBB 0
	LdpX
	Inc		byte [DPI]
	CleanUp	5,2,WD,NZ
%endmacro

;Inc abs
%macro OpcAC 0
	Labs
	Inc		byte [ABSL]
	CleanUp	5,3,WA,NZ
%endmacro


;===================================================================================================
;INCW - Increase Word by 1
; N V P B H I Z C
; *           *
;INCW dp
%macro Opc3A 0
	Ldp
	Inc		word [DPI]
	CleanUp	6,2,WD16,NZ
%endmacro


;===================================================================================================
;JMP - Indirect Jump
; N V P B H I Z C
;
;Jmp abs
%macro Opc5F 0
	Mov		PC,[OP1]
	CleanUp	3,na
%endmacro

;Jmp [abs+X]
%macro Opc1F 0
	LaabsX
	Mov		PC,[ABSL]
	CleanUp	6,na
%endmacro


;===================================================================================================
;LSR - Logical Shift Right
; N V P B H I Z C
; *           * *
;LSR A
%macro Opc5C 0
	ShR		A,1
	CleanUp	2,1,na,NZC
%endmacro

;LSR dp
%macro Opc4B 0
	Ldp
	ShR		byte [DPI],1
	CleanUp	4,2,WD,NZC
%endmacro

;LSR dp+X
%macro Opc5B 0
	LdpX
	ShR		byte [DPI],1
	CleanUp	5,2,WD,NZC
%endmacro

;LSR abs
%macro Opc4C 0
	Labs
	ShR		byte [ABSL],1
	CleanUp	5,3,WA,NZC
%endmacro


;===================================================================================================
;MOV - Load Immediate
; N V P B H I Z C
; *           *
;Mov A,#imm
%macro OpcE8 0
	Mov		A,[OP1]
	Test	A,A
	CleanUp	2,2,na,NZ
%endmacro

;Mov X,#imm
%macro OpcCD 0
	Mov		X,[OP1]
	Test	X,X
	CleanUp	2,2,na,NZ
%endmacro

;Mov Y,#imm
%macro Opc8D 0
	Mov		Y,[OP1]
	Test	Y,Y
	CleanUp	2,2,na,NZ
%endmacro


;===================================================================================================
;MOV - Copy Register
; N V P B H I Z C
; *           *
;Mov A,X
%macro Opc7D 0
	Mov		A,X
	Test	A,A
	CleanUp	2,1,na,NZ
%endmacro

;Mov A,Y
%macro OpcDD 0
	Mov		A,Y
	Test	A,A
	CleanUp	2,1,na,NZ
%endmacro

;Mov X,A
%macro Opc5D 0
	Mov		X,A
	Test	X,X
	CleanUp	2,1,na,NZ
%endmacro

;Mov Y,A
%macro OpcFD 0
	Mov		Y,A
	Test	Y,Y
	CleanUp	2,1,na,NZ
%endmacro

;Mov X,SP
%macro Opc9D 0
	Mov		X,byte [regSP]
	Test	X,X
	CleanUp	2,1,na,NZ
%endmacro

;Mov SP,X (flags not affected)
%macro OpcBD 0
	Mov		byte [regSP],X
	CleanUp	2,1
%endmacro


;===================================================================================================
;MOV - Load Memory Into Register
; N V P B H I Z C
; *           *
;Mov A,dp
%macro OpcE4 0
	Ldp
	CheckDSP
	Mov		A,[DPI]
	Test	A,A
	CleanUp	3,2,RD,NZ
%endmacro

;Mov X,dp
%macro OpcF8 0
	Ldp
	CheckDSP
	Mov		X,[DPI]
	Test	X,X
	CleanUp	3,2,RD,NZ
%endmacro

;Mov Y,dp
%macro OpcEB 0
	Ldp
	CheckDSP
	Mov		Y,[DPI]
	Test	Y,Y
	CleanUp	3,2,RD,NZ
%endmacro

;Mov A,dp+X
%macro OpcF4 0
	LdpX
	CheckDSP
	Mov		A,[DPI]
	Test	A,A
	CleanUp	4,2,RD,NZ
%endmacro

;Mov X,dp+Y
%macro OpcF9 0
	LdpY
	CheckDSP
	Mov		X,[DPI]
	Test	X,X
	CleanUp	4,2,RD,NZ
%endmacro

;Mov Y,dp+X
%macro OpcFB 0
	LdpX
	CheckDSP
	Mov		Y,[DPI]
	Test	Y,Y
	CleanUp	4,2,RD,NZ
%endmacro

;Mov A,abs
%macro OpcE5 0
	Labs
	CheckDSP
	Mov		A,[ABSL]
	Test	A,A
	CleanUp	4,3,RA,NZ
%endmacro

;Mov X,abs
%macro OpcE9 0
	Labs
	CheckDSP
	Mov		X,[ABSL]
	Test	X,X
	CleanUp	4,3,RA,NZ
%endmacro

;Mov Y,abs
%macro OpcEC 0
	Labs
	CheckDSP
	Mov		Y,[ABSL]
	Test	Y,Y
	CleanUp	4,3,RA,NZ
%endmacro

;Mov A,abs+X
%macro OpcF5 0
	LabsX
	CheckDSP
	Mov		A,[ABSL]
	Test	A,A
	CleanUp	5,3,RA,NZ
%endmacro

;Mov A,abs+Y
%macro OpcF6 0
	LabsY
	CheckDSP
	Mov		A,[ABSL]
	Test	A,A
	CleanUp	5,3,RA,NZ
%endmacro

;Mov A,(X)
%macro OpcE6 0
	LX
	CheckDSP
	Mov		A,[DPI]
	Test	A,A
	CleanUp	3,1,RD,NZ
%endmacro

;Mov A,[dp+X]
%macro OpcE7 0
	LadpX
	CheckDSP
	Mov		A,[ABSL]
	Test	A,A
	CleanUp	6,2,RA,NZ
%endmacro

;Mov A,[dp]+Y
%macro OpcF7 0
	LadpY
	CheckDSP
	Mov		A,[ABSL]
	Test	A,A
	CleanUp	6,2,RA,NZ
%endmacro


;===================================================================================================
;MOV - Store Register in Memory
; N V P B H I Z C
;
;Mov dp,A
%macro OpcC4 0
	Ldp
	Mov		[DPI],A
	CleanUp	4,2,WD
%endmacro

;Mov dp,X
%macro OpcD8 0
	Ldp
	Mov		[DPI],X
	CleanUp	4,2,WD
%endmacro

;Mov dp,Y
%macro OpcCB 0
	Ldp
	Mov		[DPI],Y
	CleanUp	4,2,WD
%endmacro

;Mov dp+X,A
%macro OpcD4 0
	LdpX
	Mov		[DPI],A
	CleanUp	5,2,WD
%endmacro

;Mov dp+Y,X
%macro OpcD9 0
	LdpY
	Mov		[DPI],X
	CleanUp	5,2,WD
%endmacro

;Mov dp+X,Y
%macro OpcDB 0
	LdpX
	Mov		[DPI],Y
	CleanUp	5,2,WD
%endmacro

;Mov abs,A
%macro OpcC5 0
	Labs
	Mov		[ABSL],A
	CleanUp	5,3,WA
%endmacro

;Mov abs,X
%macro OpcC9 0
	Labs
	Mov		[ABSL],X
	CleanUp	5,3,WA
%endmacro

;Mov abs,Y
%macro OpcCC 0
	Labs
	Mov		[ABSL],Y
	CleanUp	5,3,WA
%endmacro

;Mov abs+X,A
%macro OpcD5 0
	LabsX
	Mov		[ABSL],A
	CleanUp	6,3,WA
%endmacro

;Mov abs+Y,A
%macro OpcD6 0
	LabsY
	Mov		[ABSL],A
	CleanUp	6,3,WA
%endmacro

;Mov [dp+X],A
%macro OpcC7 0
	LadpX
	Mov		[ABSL],A
	CleanUp	7,2,WA
%endmacro

;Mov [dp]+Y,A
%macro OpcD7 0
	LadpY
	Mov		[ABSL],A
	CleanUp	7,2,WA
%endmacro

;Mov (X),A
%macro OpcC6 0
	LX
	Mov		[DPI],A
	CleanUp	4,1,WD
%endmacro


;===================================================================================================
;MOV - Move Data to Memory
; N V P B H I Z C
;
;Mov dp,#imm
%macro Opc8F 0
	Ldp2
	Mov		DH,[OP1]
	Mov		[DPI],DH
	CleanUp	5,3,WD
%endmacro

;Mov dp,dp
%macro OpcFA 0
	Ldp
	Mov		DH,[DPI]
	RdPost	0
	Ldp2
	Mov		[DPI],DH
	CleanUp	5,3,WD
%endmacro


;===================================================================================================
;MOV - Load Byte with Auto Increase
; N V P B H I Z C
; *           *
;Mov A,(X)+
%macro OpcBF 0
	LX
	CheckDSP
	Inc		X
	Mov		A,[DPI]
	Test	A,A
	CleanUp	4,1,RD,NZ
%endmacro


;===================================================================================================
;MOV - Store Byte with Auto Increase
; N V P B H I Z C
;
;Mov (X)+,A
%macro OpcAF 0
	LX
	Inc		X
	Mov		[DPI],A
	CleanUp	4,1,WD
%endmacro


;===================================================================================================
;MOV1 - Load Absolute Bit Into Carry
; N V P B H I Z C
;               *
;Mov1 C,mem.bit
%macro OpcAA 0
	Lmbit
	Push	EBX
	Mov		BL,[ABSL]
	BT		EBX,EDX
	GetC
	Pop		EBX
	CleanUp	4,3,RA
%endmacro


;===================================================================================================
;MOV1 - Store Carry in Absolute Bit
; N V P B H I Z C
;
;Mov1 mem.bit,C
%macro OpcCA 0
	Lmbit
	Mov		CL,DL
	Mov		DL,[PSW+CF]
	ShL		DL,CL
	Or		[ABSL],DL
	Mov		DL,0FEh
	Or		DL,[PSW+CF]
	ROL		DL,CL
	And		[ABSL],DL
	CleanUp	6,3,WA
%endmacro


;===================================================================================================
;MOVW - Move Word
; N V P B H I Z C
; *           *
;MovW YA,dp
%macro OpcBA 0
	Ldp
	Mov		YA,[DPI]
	Test	YA,YA
	CleanUp	5,2,RD16,NZ
%endmacro

;MovW dp,YA (flags not affected)
%macro OpcDA 0
	Ldp
	Mov		[DPI],YA
; ----- degrade-factory code [2010/09/25] -----
	CleanUp	5,2,WD16
; ----- degrade-factory code [END] -----
%endmacro


;===================================================================================================
;MUL - Multiply
; N V P B H I Z C
; *           *
;Mul YA
%macro OpcCF 0
	Mul		Y
; ----- degrade-factory code [2012/12/15] -----
	Test	Y,Y																	;Result is set based on y (high-byte) only
; ----- degrade-factory code [END] -----
	CleanUp	9,1,na,NZ
%endmacro


;===================================================================================================
;NOT1 - Complement Absolute Bit
; N V P B H I Z C
;
;Not1 mem.bit
%macro OpcEA 0
	Lmbit
	Mov		CL,DL
	Mov		DH,1
	ShL		DH,CL
	XOr		[ABSL],DH
	CleanUp	5,3,WA
%endmacro


;===================================================================================================
;NOTC - Complement Carry Flag
; N V P B H I Z C
;               *
;NotC
%macro OpcED 0
	XOr		byte [PSW+CF],1
	CleanUp	3,1
%endmacro


;===================================================================================================
;OR - Bit-wise Logical Inclusive Or
; N V P B H I Z C
; *           *
;Or A,#imm
%macro Opc08 0
	Or		A,[OP1]
	CleanUp	2,2,na,NZ
%endmacro

;Or A,dp
%macro Opc04 0
	Ldp
	CheckDSP
	Or		A,[DPI]
	CleanUp	3,2,RD,NZ
%endmacro

;Or A,dp+X
%macro Opc14 0
	LdpX
	CheckDSP
	Or		A,[DPI]
	CleanUp	4,2,RD,NZ
%endmacro

;Or A,abs
%macro Opc05 0
	Labs
	CheckDSP
	Or		A,[ABSL]
	CleanUp	4,3,RA,NZ
%endmacro

;Or A,abs+X
%macro Opc15 0
	LabsX
	CheckDSP
	Or		A,[ABSL]
	CleanUp	5,3,RA,NZ
%endmacro

;Or A,abs+Y
%macro Opc16 0
	LabsY
	CheckDSP
	Or		A,[ABSL]
	CleanUp	5,3,RA,NZ
%endmacro

;Or A,(X)
%macro Opc06 0
	LX
	CheckDSP
	Or		A,[DPI]
	CleanUp	3,1,RD,NZ
%endmacro

;Or A,[dp+X]
%macro Opc07 0
	LadpX
	CheckDSP
	Or		A,[ABSL]
	CleanUp	6,2,RA,NZ
%endmacro

;Or A,[dp]+Y
%macro Opc17 0
	LadpY
	CheckDSP
	Or		A,[ABSL]
	CleanUp	6,2,RA,NZ
%endmacro

;Or dp,#imm
%macro Opc18 0
	Ldp2
	Mov		DH,[OP1]
	Or		[DPI],DH
	CleanUp	5,3,WD,NZ
%endmacro

;Or dp,dp
%macro Opc09 0
	Ldp
	CheckDSP
	Mov		DH,[DPI]
	RdPost	0
	Ldp2
	Or		[DPI],DH
	CleanUp	6,3,WD,NZ
%endmacro

;Or (X),(Y)
%macro Opc19 0
	LY
	CheckDSP
	Mov		DH,[DPI]
	RdPost	0
	LX
	Or		[DPI],DH
	CleanUp	5,1,WD,NZ
%endmacro


;===================================================================================================
;OR1 - Or Carry with Absolute Bit
; N V P B H I Z C
;               *
;Or1 C,mem.bit
%macro Opc0A 0
	Lmbit
	Mov		CL,[ABSL]
	BT		ECX,EDX
	SetC	DL
	Or		[PSW+CF],DL
	CleanUp	5,3,RA
%endmacro

;Or1 C,/mem.bit
%macro Opc2A 0
	Lmbit
	Mov		CL,[ABSL]
	BT		ECX,EDX
	SetNC	DL
	Or		[PSW+CF],DL
	CleanUp	5,3,RA
%endmacro


;===================================================================================================
;PCALL - Call Procedure in Uppermost Page
; N V P B H I Z C
;
;PCall up
; ----- degrade-factory code [2011/04/10] -----
%macro Opc4F 0
	LEA		EBX,[RAM+up]
	Mov		BL,[OP1]
	Push	EBX
	Inc		PC
	PushW	PC
	Pop		OP1
	CleanUp	6,na
%endmacro
; ----- degrade-factory code [END] -----


;===================================================================================================
;POP - Pop Register Off Stack
; N V P B H I Z C
;
;Pop A
%macro OpcAE 0
	PopB	A
	CleanUp	4,1
%endmacro

;Pop X
%macro OpcCE 0
	PopB	X
	CleanUp	4,1
%endmacro

;Pop Y
%macro OpcEE 0
	PopB	Y
	CleanUp	4,1
%endmacro


;===================================================================================================
;POP - Pop Flags Off Stack
; N V P B H I Z C
; ? ? ? ? ? ? ? ?
;Pop PSW
%macro Opc8E 0
	PopB	PS
	ExpPSW
	CleanUp	4,1
%endmacro


;===================================================================================================
;PUSH - Push Register Onto Stack
; N V P B H I Z C
;
;Push A
%macro Opc2D 0
	PushB	A
	CleanUp	4,1
%endmacro

;Push X
%macro Opc4D 0
	PushB	X
	CleanUp	4,1
%endmacro

;Push Y
%macro Opc6D 0
	PushB	Y
	CleanUp	4,1
%endmacro

;Push PSW
%macro Opc0D 0
	CmpPSW
	PushB	PS
	CleanUp	4,1
%endmacro


;===================================================================================================
;RET - Return From Call
; N V P B H I Z C
;
;Ret
%macro Opc6F 0
	PopW	PC
	CleanUp	5,1
%endmacro


;===================================================================================================
;RETI - Return From Interrupt
; N V P B H I Z C
; ? ? ? ? ? 1 ? ?
;RetI
%macro Opc7F 0
	PopB	PS
	ExpPSW
	PopW	PC
	CleanUp	6,1
%endmacro


;===================================================================================================
;ROL - Rotate 9-bits Left
; N V P B H I Z C
; *           * *
;RoL A
%macro Opc3C 0
	ShR		byte [PSW+CF],1
	RCL		A,1
	GetC
	Test	A,A
	CleanUp	2,1,na,NZ
%endmacro

;RoL dp
%macro Opc2B 0
	Ldp
	ShR		byte [PSW+CF],1
	RCL		byte [DPI],1
	GetC
	Cmp		byte [DPI],0
	CleanUp	4,2,WD,NZ
%endmacro

;RoL dp+X
%macro Opc3B 0
	LdpX
	ShR		byte [PSW+CF],1
	RCL		byte [DPI],1
	GetC
	Cmp		byte [DPI],0
	CleanUp	5,2,WD,NZ
%endmacro

;RoL abs
%macro Opc2C 0
	Labs
	ShR		byte [PSW+CF],1
	RCL		byte [ABSL],1
	GetC
	Cmp		byte [ABSL],0
	CleanUp	5,3,WA,NZ
%endmacro


;===================================================================================================
;ROR - Rotate 9-bits Right
; N V P B H I Z C
; *           * *
;RoR A
%macro Opc7C 0
	ShR		byte [PSW+CF],1
	RCR		A,1
	GetC
	Test	A,A
	CleanUp	2,1,na,NZ
%endmacro

;RoR dp
%macro Opc6B 0
	Ldp
	ShR		byte [PSW+CF],1
	RCR		byte [DPI],1
	GetC
	Cmp		byte [DPI],0
	CleanUp	4,2,WD,NZ
%endmacro

;RoR dp+X
%macro Opc7B 0
	LdpX
	ShR		byte [PSW+CF],1
	RCR		byte [DPI],1
	GetC
	Cmp		byte [DPI],0
	CleanUp	5,2,WD,NZ
%endmacro

;RoR abs
%macro Opc6C 0
	Labs
	ShR		byte [PSW+CF],1
	RCR		byte [ABSL],1
	GetC
	Cmp		byte [ABSL],0
	CleanUp	5,3,WA,NZ
%endmacro


;===================================================================================================
;SBC - Subtract with Carry
; N V P B H I Z C
; * *     *   * *
;SbC A,#imm
%macro OpcA8 0
	Cmp		byte [PSW+CF],1
	SbB		A,[OP1]
	CleanUp	2,2,na,NVHZCs
%endmacro

;SbC A,dp
%macro OpcA4 0
	Ldp
	CheckDSP
	Cmp		byte [PSW+CF],1
	SbB		A,[DPI]
	CleanUp	3,2,RD,NVHZCs
%endmacro

;SbC A,dp+X
%macro OpcB4 0
	LdpX
	CheckDSP
	Cmp		byte [PSW+CF],1
	SbB		A,[DPI]
	CleanUp	4,2,RD,NVHZCs
%endmacro

;SbC A,abs
%macro OpcA5 0
	Labs
	CheckDSP
	Cmp		byte [PSW+CF],1
	SbB		A,[ABSL]
	CleanUp	4,3,RA,NVHZCs
%endmacro

;SbC A,abs+X
%macro OpcB5 0
	LabsX
	CheckDSP
	Cmp		byte [PSW+CF],1
	SbB		A,[ABSL]
	CleanUp	5,3,RA,NVHZCs
%endmacro

;SbC A,abs+Y
%macro OpcB6 0
	LabsY
	CheckDSP
	Cmp		byte [PSW+CF],1
	SbB		A,[ABSL]
	CleanUp	5,3,RA,NVHZCs
%endmacro

;SbC A,(X)
%macro OpcA6 0
	LX
	CheckDSP
	Cmp		byte [PSW+CF],1
	SbB		A,[DPI]
	CleanUp	3,1,RD,NVHZCs
%endmacro

;SbC A,[dp+X]
%macro OpcA7 0
	LadpX
	CheckDSP
	Cmp		byte [PSW+CF],1
	SbB		A,[ABSL]
	CleanUp	6,2,RA,NVHZCs
%endmacro

;SbC A,[dp]+Y
%macro OpcB7 0
	LadpY
	CheckDSP
	Cmp		byte [PSW+CF],1
	SbB		A,[ABSL]
	CleanUp	6,2,RA,NVHZCs
%endmacro

;SbC dp,#imm
%macro OpcB8 0
	Ldp2
	Mov		DH,[OP1]
	Cmp		byte [PSW+CF],1
	SbB		[DPI],DH
	CleanUp	5,3,WD,NVHZCs
%endmacro

;SbC dp,dp
%macro OpcA9 0
	Ldp
	CheckDSP
	Mov		DH,[DPI]
	RdPost	0
	Ldp2
	Cmp		byte [PSW+CF],1
	SbB		[DPI],DH
	CleanUp	6,3,WD,NVHZCs
%endmacro

;SbC (X),(Y)
%macro OpcB9 0
	LY
	CheckDSP
	Mov		DH,[DPI]
	RdPost	0
	LX
	Cmp		byte [PSW+CF],1
	SbB		[DPI],DH
	CleanUp	5,1,WD,NVHZCs
%endmacro


;===================================================================================================
;SET1 - Set Bit
; N V P B H I Z C

	;-----------------------------------------
	;Set bit
	;   %1 - Bit to Set (0-7)

	%macro Set 1
		Ldp
		Or		byte [DPI],1 << %1
		CleanUp	4,2,WD
	%endmacro

;Set1 dp.0
%macro Opc02 0
	Set		0
%endmacro

;Set1 dp.1
%macro Opc22 0
	Set		1
%endmacro

;Set1 dp.2
%macro Opc42 0
	Set		2
%endmacro

;Set1 dp.3
%macro Opc62 0
	Set		3
%endmacro

;Set1 dp.4
%macro Opc82 0
	Set		4
%endmacro

;Set1 dp.5
%macro OpcA2 0
	Set		5
%endmacro

;Set1 dp.6
%macro OpcC2 0
	Set		6
%endmacro

;Set1 dp.7
%macro OpcE2 0
	Set		7
%endmacro


;===================================================================================================
;SETC - Set Carry Flag
; N V P B H I Z C
;               1
;SetC
%macro Opc80 0
	Mov		byte [PSW+CF],1
	CleanUp	2,1
%endmacro


;===================================================================================================
;SETP - Set Direct Page Flag
; N V P B H I Z C
;     1     0
;SetP
%macro Opc40 0
	Mov		byte [PSW+P],1
	Mov		byte [PSW+I],0
	CleanUp	2,1
%endmacro


;===================================================================================================
;SLEEP - Suspend the SPC700
; N V P B H I Z C
;
;Sleep
%macro OpcEF 0
	Test	byte [portMod],80h													;Is the SPC700 sleeping?
	SetZ	DL																	;	No, Erase port status
	Dec		DL
	And		[portMod],DL

	Test	byte [portMod],0Fh													;Has the 65816 written to the SPC700?
	JNZ		%%WakeUp															;	Yes, Wake up
		Or		byte [portMod],80h												;SPC700 is in sleep mode
		Dec		PC																;Sleep by repeating the instruction
%if SPEED
		Call	SleepHack
%endif
		CleanUp	3,1
	%%WakeUp:
	Mov		byte [portMod],0
	CleanUp	3,1
%endmacro


;===================================================================================================
;STOP - Stop the SPC700
; N V P B H I Z C
;
;Stop
%macro OpcFF 0
	Dec		PC																	;Stop execution by repeating the instruction
%if DEBUG
	Test	byte [dbgOpt],SPC_TRACE
	JNZ		short %%NoDbg
%endif
	Mov		EBX,[pDebug]
	Test	EBX,EBX
	JZ		short %%NoDbg
		Sub		dword [clkLeft],3*CPU_CYC
		Jmp		SPCBreak
	%%NoDbg:
	CleanUp	3,1
%endmacro


;===================================================================================================
;SUBW - Subtract Word
; N V P B H I Z C
; * *     *   * *
;SubW YA,dp
%macro Opc9A 0
	Ldp
	Sub		YA,[DPI]
	CleanUp	5,2,RD16,NVHZCs
%endmacro


;===================================================================================================
;TCALL - Call Pointer in Vector Table
; N V P B H I Z C

	;-----------------------------------------
	;Table Call
	;   %1 - Table Index

	%macro TCall 1
		PushW	PC
		Mov		PC,word [((15-%1)*2)+RAM+ipl]
		CleanUp	8,na
	%endmacro

;TCall 0
%macro Opc01 0
	TCall	0
%endmacro

;TCall 1
%macro Opc11 0
	TCall	1
%endmacro

;TCall 2
%macro Opc21 0
	TCall	2
%endmacro

;TCall 3
%macro Opc31 0
	TCall	3
%endmacro

;TCall 4
%macro Opc41 0
	TCall	4
%endmacro

;TCall 5
%macro Opc51 0
	TCall	5
%endmacro

;TCall 6
%macro Opc61 0
	TCall	6
%endmacro

;TCall 7
%macro Opc71 0
	TCall	7
%endmacro

;TCall 8
%macro Opc81 0
	TCall	8
%endmacro

;TCall 9
%macro Opc91 0
	TCall	9
%endmacro

;TCall 10
%macro OpcA1 0
	TCall	10
%endmacro

;TCall 11
%macro OpcB1 0
	TCall	11
%endmacro

;TCall 12
%macro OpcC1 0
	TCall	12
%endmacro

;TCall 13
%macro OpcD1 0
	TCall	13
%endmacro

;TCall 14
%macro OpcE1 0
	TCall	14
%endmacro

;TCall 15
%macro OpcF1 0
	TCall	15
%endmacro


;===================================================================================================
;TCLR1 - Test and Clear Bits with A
; N V P B H I Z C
; *           *
;TClr1 abs
%macro Opc4E 0
	Labs
	Mov		DH,[ABSL]
	Not		A
	And		[ABSL],A
	Not		A
; ----- degrade-factory code [2010/09/25] -----
;	Test	A,DH																;Perhaps, bug of SPC700's opecode
	Cmp		A,DH
; ----- degrade-factory code [END] -----
	CleanUp	6,3,WA,NZ
%endmacro


;===================================================================================================
;TSET1 - Test and Set Bits with A
; N V P B H I Z C
; *           *
;TSet1 abs
%macro Opc0E 0
	Labs
	Mov		DH,[ABSL]
	Or		[ABSL],A
; ----- degrade-factory code [2010/09/25] -----
;	Test	A,DH																;Perhaps, bug of SPC700's opecode
	Cmp		A,DH
; ----- degrade-factory code [END] -----
	CleanUp	6,3,WA,NZ
%endmacro


;===================================================================================================
;XCN - Exchange Nybbles
; N V P B H I Z C
; *           *
;XCN A
%macro Opc9F 0
	ROR		A,4
	Test	A,A
	CleanUp	5,1,na,NZ
%endmacro


;===================================================================================================
;Function Register Handlers
;
;These are specific functions to handle data written to the function registers (F0h to FFh)

;===================================================================================================
;Test (unused)

%macro Func0 0
%if DEBUG
	Jmp		EBP
%else
	Jmp		SPCFetch
%endif

;This is a bit of code to handle 16-bit writes to the F0h - FEh range.
;During a 16-bit write, EBP is loaded with the address here, and the address of the handler for the
;high byte is pushed onto the stack.  After handling the low byte, the emulator will jump here where
;EBP will be restored then control will be passed to the handler for the high byte.

ALIGN 16
%if DEBUG
	Mov		EBP,[pOpFetch]
%else
	Mov		EBP,SPCFetch
%endif
	Ret

%endmacro


;===================================================================================================
;Control
;   Checks control register for ROM reading enable, port reset, and timer enable.

%macro Func1 0
	Push	EAX
	Mov		BL,[RAM+control]

	;ROM access ------------------------------
; ----- degrade-factory code [2008/01/11] -----
	Mov		AL,[tControl]
	XOr		AL,BL																;Did ROM access change?
	JNS		short %%NoRA														;	No
		Push	ECX,ESI,EDI
		Mov		ESI,extraRAM													;Setup registers to move data from Extra RAM to
		Mov		DI,ipl															; IPL region

		Mov		ECX,10h
		Test	BL,BL															;Is ROM readable?
		JNS		short %%NoRR													;	No, Perform move as intended
			XChg	ESI,EDI														;Reverse original operation, move IPL to Extra RAM
			Rep		MovSD
			Mov		CL,10h														;Setup registers to move ROM program into IPL region
			LEA		EDI,[ESI-40h]
			Mov		ESI,iplROM
		%%NoRR:
		Rep		MovSD															;Move iplROM or extraRAM to IPL ROM region
		Pop		EDI,ESI,ECX
	%%NoRA:
; ----- degrade-factory code [END] -----

	;Clear ports -----------------------------
; ----- degrade-factory code [2015/02/28] -----
	Test	BL,30h																;Was a clear ports command written?
	JZ		short %%NoCP														;	No
		Mov		EAX,EBX
		Not		EAX																;Reverse command bits
		ShL		EAX,26															;Create a mask based on bits 5 & 4
		SAR		EAX,15
		SAR		AX,15
		And		dword [RAM+port0],EAX											;Reset in-ports
		And		dword [inPortCp],EAX
		And		dword [flushPort],EAX
	%%NoCP:
; ----- degrade-factory code [END] -----

	;Timer control ---------------------------
	Mov		AL,[tControl]														;AL = Timers currently enabled
	And		BL,87h
	Mov		[tControl],BL														;Store new timers enabled
	Mov		[RAM+control],BL

	Not		AL
	And		BL,AL																;BL=1 if new timer=1 and old timer=0
	And		BL,7
	JZ		short %%NoTR														;	Quit if no timers are reset
		;Branching method ---------------------
		ShR		BL,1															;Do we need to reset timer 0?
		JNC		short %%NoRT0													;	No
			Mov		AL,[RAM+t0]													;Get timer register
			Dec		AL
			Mov		[t0Step],AL													;Reset timer step
			Mov		byte [RAM+c0],0												;Reset counter
		%%NoRT0:

		ShR		BL,1
		JNC		short %%NoRT1
			Mov		AL,[RAM+t1]
			Dec		AL
			Mov		[t1Step],AL
			Mov		byte [RAM+c1],0
		%%NoRT1:

		ShR		BL,1
		JNC		short %%NoRT2
			Mov		AL,[RAM+t2]
			Dec		AL
			Mov		[t2Step],AL
			Mov		byte [RAM+c2],0
		%%NoRT2:
	%%NoTR:
	Pop		EAX
	Jmp		EBP

%endmacro


;===================================================================================================
;DSP Address
;   Loads 0F3h with value indexed in DSP RAM.  In the SNES, reads from registers 80-FF mirror
;   registers 00-7F.

%macro Func2 0
; ----- degrade-factory code [2008/01/11] -----
	Mov		BL,[RAM+dspAddr]													;BL = DSP register
	And		EBX,7Fh																;The MSB of the addr is ignored when getting data
	Mov		CL,[EBX+dsp]														;Get byte from DSP RAM
	Mov		[RAM+dspData],CL													;Store byte in DSP data reg
; ----- degrade-factory code [END] -----
	Jmp		EBP
%endmacro


;===================================================================================================
;DSP Data
;   Updates the DSP RAM with the value written to the data port, and calls the DSP emulator to
;   handle the new data.

%macro Func3 0
	Test	byte [dbgOpt],SPC_NODSP
	JNZ		short %%NoDSP

	Push	EDX,EAX
	MovZX	EBX,byte [RAM+dspAddr]
	Mov		AL,[RAM+dspData]
	Call	DSPIn
	Pop		EAX,EDX
	Jmp		EBP

	%%NoDSP:
; ----- degrade-factory code [2008/01/11] -----
	Mov		BL,[RAM+dspAddr]
	And		EBX,7Fh
	Mov		CL,[RAM+dspData]
	Mov		[EBX+dsp],CL
; ----- degrade-factory code [END] -----
	Jmp		EBP
%endmacro


;===================================================================================================
;Out Ports 0-3
;   Moves data to out port memory, and replaces register with in port value

; ----- degrade-factory code [2011/02/05] -----
%macro Func4 0
	Mov		CL,[RAM+port0]														;Get value written
	Mov		BL,[inPortCp+0]														;Get value to be read from in port memory (from console)
	Mov		[outPort+0],CL														;Place value written into out port memory (to console)
	Mov		[outPortCp+0],CL													;Copy value
	Mov		[RAM+port0],BL														;Reload register with in port value
	Jmp		EBP
%endmacro

%macro Func5 0
	Mov		CL,[RAM+port1]
	Mov		BL,[inPortCp+1]
	Mov		[outPort+1],CL
	Mov		[outPortCp+1],CL
	Mov		[RAM+port1],BL
	Jmp		EBP
%endmacro

%macro Func6 0
	Mov		CL,[RAM+port2]
	Mov		BL,[inPortCp+2]
	Mov		[outPort+2],CL
	Mov		[outPortCp+2],CL
	Mov		[RAM+port2],BL
	Jmp		EBP
%endmacro

%macro Func7 0
	Mov		CL,[RAM+port3]
	Mov		BL,[inPortCp+3]
	Mov		[outPort+3],CL
	Mov		[outPortCp+3],CL
	Mov		[RAM+port3],BL
	Jmp		EBP
%endmacro
; ----- degrade-factory code [END] -----


;===================================================================================================
;Unused
;   No special handling is associated with registers 0F8h and 0F9h

%macro Func8 0
	Jmp		EBP
%endmacro

%macro Func9 0
	Jmp		EBP
%endmacro


;===================================================================================================
;Timers 0-2
;   In reality, reading the timer registers always returns 00

%macro FuncA 0
	Jmp		EBP
%endmacro

%macro FuncB 0
	Jmp		EBP
%endmacro

%macro FuncC 0
	Jmp		EBP
%endmacro


;===================================================================================================
;Counters 0-2
;  The counter registers can't be written to.  In the unlikely event that they are, this hack will
;  reset them to keep things from going awry.

%macro FuncD 0
	Mov		byte [RAM+c0],0
	Jmp		EBP
%endmacro

%macro FuncE 0
	Mov		byte [RAM+c1],0
	Jmp		EBP
%endmacro

%macro FuncF 0
	Mov		byte [RAM+c2],0
	Jmp		EBP
%endmacro


;===================================================================================================
;Build Opcode Table
;
;Arrange all the opcoder emulators in order.  (This was a lot easier with MASM's FORC macro.)

; ----- degrade-factory code [2016/05/15] -----
ALIGN 16
Opc00:	Opc00
ALIGN 16
Opc01:	Opc01
ALIGN 16
Opc02:	Opc02
ALIGN 16
Opc03:	Opc03
ALIGN 16
Opc04:	Opc04
ALIGN 16
Opc05:	Opc05
ALIGN 16
Opc06:	Opc06
ALIGN 16
Opc07:	Opc07
ALIGN 16
Opc08:	Opc08
ALIGN 16
Opc09:	Opc09
ALIGN 16
Opc0A:	Opc0A
ALIGN 16
Opc0B:	Opc0B
ALIGN 16
Opc0C:	Opc0C
ALIGN 16
Opc0D:	Opc0D
ALIGN 16
Opc0E:	Opc0E
ALIGN 16
Opc0F:	Opc0F
ALIGN 16
Opc10:	Opc10
ALIGN 16
Opc11:	Opc11
ALIGN 16
Opc12:	Opc12
ALIGN 16
Opc13:	Opc13
ALIGN 16
Opc14:	Opc14
ALIGN 16
Opc15:	Opc15
ALIGN 16
Opc16:	Opc16
ALIGN 16
Opc17:	Opc17
ALIGN 16
Opc18:	Opc18
ALIGN 16
Opc19:	Opc19
ALIGN 16
Opc1A:	Opc1A
ALIGN 16
Opc1B:	Opc1B
ALIGN 16
Opc1C:	Opc1C
ALIGN 16
Opc1D:	Opc1D
ALIGN 16
Opc1E:	Opc1E
ALIGN 16
Opc1F:	Opc1F
ALIGN 16
Opc20:	Opc20
ALIGN 16
Opc21:	Opc21
ALIGN 16
Opc22:	Opc22
ALIGN 16
Opc23:	Opc23
ALIGN 16
Opc24:	Opc24
ALIGN 16
Opc25:	Opc25
ALIGN 16
Opc26:	Opc26
ALIGN 16
Opc27:	Opc27
ALIGN 16
Opc28:	Opc28
ALIGN 16
Opc29:	Opc29
ALIGN 16
Opc2A:	Opc2A
ALIGN 16
Opc2B:	Opc2B
ALIGN 16
Opc2C:	Opc2C
ALIGN 16
Opc2D:	Opc2D
ALIGN 16
Opc2E:	Opc2E
ALIGN 16
Opc2F:	Opc2F
ALIGN 16
Opc30:	Opc30
ALIGN 16
Opc31:	Opc31
ALIGN 16
Opc32:	Opc32
ALIGN 16
Opc33:	Opc33
ALIGN 16
Opc34:	Opc34
ALIGN 16
Opc35:	Opc35
ALIGN 16
Opc36:	Opc36
ALIGN 16
Opc37:	Opc37
ALIGN 16
Opc38:	Opc38
ALIGN 16
Opc39:	Opc39
ALIGN 16
Opc3A:	Opc3A
ALIGN 16
Opc3B:	Opc3B
ALIGN 16
Opc3C:	Opc3C
ALIGN 16
Opc3D:	Opc3D
ALIGN 16
Opc3E:	Opc3E
ALIGN 16
Opc3F:	Opc3F
ALIGN 16
Opc40:	Opc40
ALIGN 16
Opc41:	Opc41
ALIGN 16
Opc42:	Opc42
ALIGN 16
Opc43:	Opc43
ALIGN 16
Opc44:	Opc44
ALIGN 16
Opc45:	Opc45
ALIGN 16
Opc46:	Opc46
ALIGN 16
Opc47:	Opc47
ALIGN 16
Opc48:	Opc48
ALIGN 16
Opc49:	Opc49
ALIGN 16
Opc4A:	Opc4A
ALIGN 16
Opc4B:	Opc4B
ALIGN 16
Opc4C:	Opc4C
ALIGN 16
Opc4D:	Opc4D
ALIGN 16
Opc4E:	Opc4E
ALIGN 16
Opc4F:	Opc4F
ALIGN 16
Opc50:	Opc50
ALIGN 16
Opc51:	Opc51
ALIGN 16
Opc52:	Opc52
ALIGN 16
Opc53:	Opc53
ALIGN 16
Opc54:	Opc54
ALIGN 16
Opc55:	Opc55
ALIGN 16
Opc56:	Opc56
ALIGN 16
Opc57:	Opc57
ALIGN 16
Opc58:	Opc58
ALIGN 16
Opc59:	Opc59
ALIGN 16
Opc5A:	Opc5A
ALIGN 16
Opc5B:	Opc5B
ALIGN 16
Opc5C:	Opc5C
ALIGN 16
Opc5D:	Opc5D
ALIGN 16
Opc5E:	Opc5E
ALIGN 16
Opc5F:	Opc5F
ALIGN 16
Opc60:	Opc60
ALIGN 16
Opc61:	Opc61
ALIGN 16
Opc62:	Opc62
ALIGN 16
Opc63:	Opc63
ALIGN 16
Opc64:	Opc64
ALIGN 16
Opc65:	Opc65
ALIGN 16
Opc66:	Opc66
ALIGN 16
Opc67:	Opc67
ALIGN 16
Opc68:	Opc68
ALIGN 16
Opc69:	Opc69
ALIGN 16
Opc6A:	Opc6A
ALIGN 16
Opc6B:	Opc6B
ALIGN 16
Opc6C:	Opc6C
ALIGN 16
Opc6D:	Opc6D
ALIGN 16
Opc6E:	Opc6E
ALIGN 16
Opc6F:	Opc6F
ALIGN 16
Opc70:	Opc70
ALIGN 16
Opc71:	Opc71
ALIGN 16
Opc72:	Opc72
ALIGN 16
Opc73:	Opc73
ALIGN 16
Opc74:	Opc74
ALIGN 16
Opc75:	Opc75
ALIGN 16
Opc76:	Opc76
ALIGN 16
Opc77:	Opc77
ALIGN 16
Opc78:	Opc78
ALIGN 16
Opc79:	Opc79
ALIGN 16
Opc7A:	Opc7A
ALIGN 16
Opc7B:	Opc7B
ALIGN 16
Opc7C:	Opc7C
ALIGN 16
Opc7D:	Opc7D
ALIGN 16
Opc7E:	Opc7E
ALIGN 16
Opc7F:	Opc7F
ALIGN 16
Opc80:	Opc80
ALIGN 16
Opc81:	Opc81
ALIGN 16
Opc82:	Opc82
ALIGN 16
Opc83:	Opc83
ALIGN 16
Opc84:	Opc84
ALIGN 16
Opc85:	Opc85
ALIGN 16
Opc86:	Opc86
ALIGN 16
Opc87:	Opc87
ALIGN 16
Opc88:	Opc88
ALIGN 16
Opc89:	Opc89
ALIGN 16
Opc8A:	Opc8A
ALIGN 16
Opc8B:	Opc8B
ALIGN 16
Opc8C:	Opc8C
ALIGN 16
Opc8D:	Opc8D
ALIGN 16
Opc8E:	Opc8E
ALIGN 16
Opc8F:	Opc8F
ALIGN 16
Opc90:	Opc90
ALIGN 16
Opc91:	Opc91
ALIGN 16
Opc92:	Opc92
ALIGN 16
Opc93:	Opc93
ALIGN 16
Opc94:	Opc94
ALIGN 16
Opc95:	Opc95
ALIGN 16
Opc96:	Opc96
ALIGN 16
Opc97:	Opc97
ALIGN 16
Opc98:	Opc98
ALIGN 16
Opc99:	Opc99
ALIGN 16
Opc9A:	Opc9A
ALIGN 16
Opc9B:	Opc9B
ALIGN 16
Opc9C:	Opc9C
ALIGN 16
Opc9D:	Opc9D
ALIGN 16
Opc9E:	Opc9E
ALIGN 16
Opc9F:	Opc9F
ALIGN 16
OpcA0:	OpcA0
ALIGN 16
OpcA1:	OpcA1
ALIGN 16
OpcA2:	OpcA2
ALIGN 16
OpcA3:	OpcA3
ALIGN 16
OpcA4:	OpcA4
ALIGN 16
OpcA5:	OpcA5
ALIGN 16
OpcA6:	OpcA6
ALIGN 16
OpcA7:	OpcA7
ALIGN 16
OpcA8:	OpcA8
ALIGN 16
OpcA9:	OpcA9
ALIGN 16
OpcAA:	OpcAA
ALIGN 16
OpcAB:	OpcAB
ALIGN 16
OpcAC:	OpcAC
ALIGN 16
OpcAD:	OpcAD
ALIGN 16
OpcAE:	OpcAE
ALIGN 16
OpcAF:	OpcAF
ALIGN 16
OpcB0:	OpcB0
ALIGN 16
OpcB1:	OpcB1
ALIGN 16
OpcB2:	OpcB2
ALIGN 16
OpcB3:	OpcB3
ALIGN 16
OpcB4:	OpcB4
ALIGN 16
OpcB5:	OpcB5
ALIGN 16
OpcB6:	OpcB6
ALIGN 16
OpcB7:	OpcB7
ALIGN 16
OpcB8:	OpcB8
ALIGN 16
OpcB9:	OpcB9
ALIGN 16
OpcBA:	OpcBA
ALIGN 16
OpcBB:	OpcBB
ALIGN 16
OpcBC:	OpcBC
ALIGN 16
OpcBD:	OpcBD
ALIGN 16
OpcBE:	OpcBE
ALIGN 16
OpcBF:	OpcBF
ALIGN 16
OpcC0:	OpcC0
ALIGN 16
OpcC1:	OpcC1
ALIGN 16
OpcC2:	OpcC2
ALIGN 16
OpcC3:	OpcC3
ALIGN 16
OpcC4:	OpcC4
ALIGN 16
OpcC5:	OpcC5
ALIGN 16
OpcC6:	OpcC6
ALIGN 16
OpcC7:	OpcC7
ALIGN 16
OpcC8:	OpcC8
ALIGN 16
OpcC9:	OpcC9
ALIGN 16
OpcCA:	OpcCA
ALIGN 16
OpcCB:	OpcCB
ALIGN 16
OpcCC:	OpcCC
ALIGN 16
OpcCD:	OpcCD
ALIGN 16
OpcCE:	OpcCE
ALIGN 16
OpcCF:	OpcCF
ALIGN 16
OpcD0:	OpcD0
ALIGN 16
OpcD1:	OpcD1
ALIGN 16
OpcD2:	OpcD2
ALIGN 16
OpcD3:	OpcD3
ALIGN 16
OpcD4:	OpcD4
ALIGN 16
OpcD5:	OpcD5
ALIGN 16
OpcD6:	OpcD6
ALIGN 16
OpcD7:	OpcD7
ALIGN 16
OpcD8:	OpcD8
ALIGN 16
OpcD9:	OpcD9
ALIGN 16
OpcDA:	OpcDA
ALIGN 16
OpcDB:	OpcDB
ALIGN 16
OpcDC:	OpcDC
ALIGN 16
OpcDD:	OpcDD
ALIGN 16
OpcDE:	OpcDE
ALIGN 16
OpcDF:	OpcDF
ALIGN 16
OpcE0:	OpcE0
ALIGN 16
OpcE1:	OpcE1
ALIGN 16
OpcE2:	OpcE2
ALIGN 16
OpcE3:	OpcE3
ALIGN 16
OpcE4:	OpcE4
ALIGN 16
OpcE5:	OpcE5
ALIGN 16
OpcE6:	OpcE6
ALIGN 16
OpcE7:	OpcE7
ALIGN 16
OpcE8:	OpcE8
ALIGN 16
OpcE9:	OpcE9
ALIGN 16
OpcEA:	OpcEA
ALIGN 16
OpcEB:	OpcEB
ALIGN 16
OpcEC:	OpcEC
ALIGN 16
OpcED:	OpcED
ALIGN 16
OpcEE:	OpcEE
ALIGN 16
OpcEF:	OpcEF
ALIGN 16
OpcF0:	OpcF0
ALIGN 16
OpcF1:	OpcF1
ALIGN 16
OpcF2:	OpcF2
ALIGN 16
OpcF3:	OpcF3
ALIGN 16
OpcF4:	OpcF4
ALIGN 16
OpcF5:	OpcF5
ALIGN 16
OpcF6:	OpcF6
ALIGN 16
OpcF7:	OpcF7
ALIGN 16
OpcF8:	OpcF8
ALIGN 16
OpcF9:	OpcF9
ALIGN 16
OpcFA:	OpcFA
ALIGN 16
OpcFB:	OpcFB
ALIGN 16
OpcFC:	OpcFC
ALIGN 16
OpcFD:	OpcFD
ALIGN 16
OpcFE:	OpcFE
ALIGN 16
OpcFF:	OpcFF

ALIGN 16
Func0:	Func0
ALIGN 16
Func1:	Func1
ALIGN 16
Func2:	Func2
ALIGN 16
Func3:	Func3
ALIGN 16
Func4:	Func4
ALIGN 16
Func5:	Func5
ALIGN 16
Func6:	Func6
ALIGN 16
Func7:	Func7
ALIGN 16
Func8:	Func8
ALIGN 16
Func9:	Func9
ALIGN 16
FuncA:	FuncA
ALIGN 16
FuncB:	FuncB
ALIGN 16
FuncC:	FuncC
ALIGN 16
FuncD:	FuncD
ALIGN 16
FuncE:	FuncE
ALIGN 16
FuncF:	FuncF
ALIGN 16
FuncZ:	Jmp	EBP
; ----- degrade-factory code [END] -----
