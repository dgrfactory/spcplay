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
;                                                   Copyright (C) 2003-2016 degrade-factory
;===================================================================================================

%define SPC700_INC

;===================================================================================================
;Equates

APU_CLK		EQU	24576000

;SPC700 debugging options -------------------
SPC_RETURN	EQU	01h												;Return from EmuSPC
SPC_HALT	EQU	02h												;Halt emulation
DSP_HALT	EQU	04h												;Internal flag used for syncing SPC_HALT with EmuDSP
SPC_NODSP	EQU	08h												;Disable calls to the DSP emu from the SPC700
SPC_TRACE	EQU	10h												;Trace next instruction
; ----- degrade-factory code [2016/08/20] -----
DSP_PAUSE	EQU	20h												;Disable update envelope
; ----- degrade-factory code [END] -----

; ----- degrade-factory code [2016/08/20] -----
;SPC700 fetch options -----------------------
FCH_HALT	EQU	01h
FCH_NOP		EQU	02h
FCH_PAUSE	EQU	03h
; ----- degrade-factory code [END] -----

; ----- degrade-factory code [2010/04/03] -----
%ifdef	SHVC_SOUND_SUPPORT
;Extend function pointer address ------------
EXT_WRPORT	EQU	10014h											;Callback function to write port
EXT_RDPORT	EQU	10018h											;Callback function to read port
EXT_RESET	EQU	10022h											;Callback function to reset
%endif
; ----- degrade-factory code [END] -----


;===================================================================================================
;Structures


;===================================================================================================
;Public Variables

PUBLIC	extraRAM												;RAM used for storage if ROM reading is enabled
PUBLIC	outPort													;Four out ports
PUBLIC	t64Cnt													;Counter increased every 64kHz
PUBLIC	dbgOpt													;SPC700 debugging options
; ----- degrade-factory code [2006/08/01] -----
PUBLIC	pSPCReg													;Pointer to SPC700 Register Buffer
; ----- degrade-factory code [END] -----
; ----- degrade-factory code [2015/07/11] -----
PUBLIC	spcVarEP												;Endpoint of SPC700.asm variables
; ----- degrade-factory code [END] -----


;===================================================================================================
;Exported Functions

; ----- degrade-factory code [2006/10/20] -----
;===================================================================================================
;Initialize SPC700
;
;This function is a remnant from the 16-bit assembly when dynamic code reallocation was used.
;Now it just initializes internal pointers.
;
;Destroys:
;   EAX

PUBLIC InitSPC, NULL
; ----- degrade-factory code [END] -----


;===================================================================================================
;Reset SPC700
;
;Clears all memory, resets the function registers, T64Cnt, and halt flag, and copies ROM into the
;IPL region.
;
;Destroys:
;   EAX=0

PUBLIC ResetSPC, NULL


;===================================================================================================
;Debug SPC700
;
;Installs a vector that gets called between each opcode for debugging purposes.  The function is
;called with the C calling convention.
;
;Upon entrance to the function:
;   [ESP+4] -> Current opcode (low word = PC)
;   [ESP+8]  = YA
;   [ESP+12] = X
;   [ESP+16] = PSW
;   [ESP+20]-> Current stack (low word = SP)
;   [ESP+24] = Clock cycle down count
;              [0-1] 8kHz cycles left until counters 0 and 1 increase
;              [2]   64kHz cycles left until counter 2 increases
;              [3]   CPU cycles left until 64kHz clock pulse
;
;Note:
;   pTrace is always called when a STOP instruction is encountered, regardless of the options.
;   DEBUG must be set to 1 in APU.Inc for pTrace to be called under other circumstances
;
;In:
;   pTrace-> debug function (NULL turns off the debug call, -1 leaves the current vector)
;   opts   = SPC700 debugging options (-1 leaves the current options)
;
;Out:
;   Previously installed vector

PUBLIC SetSPCDbg, pTrace:ptr, opts:dword


;===================================================================================================
;Fix SPC700 After Load
;
;Loads timer steps with the values in the timer registers, resets the counters, sets up the in/out
;ports, and stores the registers.
;
;In:
;   SPC internal registers
;
;Destroys:
;   EAX

PUBLIC FixSPC, pc:word, a:byte, y:byte, x:byte, psw:byte, sp:byte


;===================================================================================================
;Get SPC700 Registers
;
;Returns the internal registers of the SPC700.
;
;In:
;   Pointers to variables to store registers
;
;Destroys:
;   EAX

PUBLIC GetSPCRegs, pPC:ptr, pA:ptr, pY:ptr, pX:ptr, pPSW:ptr, pSP:ptr


;===================================================================================================
;Write to APU RAM
;
;Writes a value to APU RAM.  Use this instead of writing to RAM directly so any necessary internal
;changes can be made.
;
;In:
;   addr = Address to write to (only the lower 16-bits are used)
;   val  = Value to write
;
;Destroys:
;   EAX

PUBLIC SetAPURAM, addr:dword, val:byte


;===================================================================================================
;Write to SPC700 Port
;
;Writes a value to the SPC700 via the in ports.  This is provided as an alternative to APUIn.
;
;In:
;   port = Port on which to write (only the lower 2-bits are used)
;   val  = Value to write
;
;Destroys:
;   EAX

PUBLIC InPort, addr:byte, val:byte


;===================================================================================================
;Emulate SPC700
;
;Emulates the SPC700 for the number of clock cycles specified, or if the counter break option is
;enabled, until a counter is increased, whichever happens first.
;
;In:
;   cyc = Number of 24.576MHz clock cycles to execute (signed, must be > 0)
;
;Out:
;   EAX = Clock cycles left to execute (negative if more cycles than specified were emulated)
;
;Destroys:
;   nothing

PUBLIC EmuSPC, cyc:dword
