;===================================================================================================
;Program:    TASM Like Macros for NASM
;Platform:   Intel 80386
;Programmer: Anti Resonance (Alpha-II Productions)
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
;                                                   Copyright (C) 2003 Alpha-II Productions
;                                                   Copyright (C) 2012-2026 degrade-factory
;
;List of users and dates who/when modified this file:
;   - degrade-factory in 2026-08-21
;===================================================================================================

;The following defines affect the way some macros work:
;   INTERNAL effects the way PUBLIC works (see macro header for comments)
;   STDCALL mangles labels and cleans up the stack on returns (x86 only)
;   CDECL mangles labels (x86 only)
;   WIN64 selects the amd64/Win64 backend (x64.inc) instead of the x86 backend (x86.inc)
;
;PROC/ENDP/USES/PUBLIC/Call/RetN/LOCALS, and the pointer-width aliases PAX/PBX/PCX/PDX/PSI/PDI/PBP/
; PSP/PTRSIZE/resPTR, come from whichever backend is selected below.  Architecture-neutral code
; (APU.asm/DSP.asm/SPC700.asm) should use only those names and never %ifdef on WIN64 itself -- see
; x86.inc/x64.inc for the rationale.

%ifdef WIN64
    %include "x64.inc"
%else
    %include "x86.inc"
%endif

;WINDOWS is defined whenever either Windows backend (WIN32 or WIN64) is targeted -- used by the
; handful of SECTION ALIGN= declarations in APU.asm/DSP.asm/SPC700.asm that must pick between the
; small, nasm-win32/win64-format-compatible alignment values (<=64) and a larger one for some other,
; non-Windows-COFF target.  This is a narrow exception to the "never %ifdef on WIN64 itself" rule
; above -- SECTION directives aren't code the PAX/PBX-style aliases can cover.
%ifdef WIN32
    %define WINDOWS
%elifdef WIN64
    %define WINDOWS
%endif

%define ST      ST0


;===================================================================================================
;Overloaded Instructions

;===================================================================================================
;Push
;
;Params:
;   List of values to be pushed onto the stack.  Values are pushed left to right.

%macro Push 2-*
    %rep %0
        Push    %1
        %rotate 1
    %endrep
%endmacro


;===================================================================================================
;Pop
;
;Params:
;   List of values to be popped off the stack.  Values are popped left to right.

%macro Pop 2-*
    %rep %0
        Pop     %1
        %rotate 1
    %endrep
%endmacro


;===================================================================================================
;Procedure Macros
;
;PROC/ENDP/USES/PUBLIC/Call/RetN/RetZ/RetZF/RetNZ/RetNZF/LOCALS are defined by the backend included
; above (x86.inc or x64.inc) -- see that file for documentation.  They share one interface across
; both architectures so code below this point in APU.asm/DSP.asm/SPC700.asm never needs to know
; which one is active.


;===================================================================================================
;Creating Floating Point Powers of 2

%macro Scale32 2                                                                ;Single
    %1  DD  (127+(%2)) << 23
%endmacro

%macro Scale64 2                                                                ;Double
    %1  DD  0,(1023+(%2)) << 20
%endmacro

%macro Scale80 2                                                                ;Extended
    %1  DD  0,80000000h
        DW  16383+(%2)
%endmacro
