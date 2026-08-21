;===================================================================================================
;Program:    x86 (32-bit) Backend Macros for NASM
;Platform:   Intel 80386
;
;This file implements the architecture-specific half of the macro layer used by APU.asm, DSP.asm,
;and SPC700.asm.  It is selected automatically by macro.inc when WIN64 is NOT defined.
;
;Everything in this file defines the *mechanism* (stack layout, calling convention, register width)
;for a 32-bit x86 (stdcall/cdecl) target.  Shared, architecture-neutral code must never %ifdef on
;WIN64 directly; it should only use the names defined here (PROC/ENDP/USES/PUBLIC/Call/RetN, and
;the pointer-width aliases PAX/PBX/PCX/PDX/PSI/PDI/PBP/PSP/PTRSIZE/resPTR).
;
;                                                   Copyright (C) 2026 degrade-factory
;
;List of users and dates who/when modified this file:
;   - degrade-factory in 2026-08-21
;===================================================================================================

%define ARCH_BITS   32

;===================================================================================================
;Pointer-width register aliases
;
;Use these ONLY where a register genuinely holds a memory address (a pointer).  Registers used for
; plain 32-bit arithmetic (sample counts, offsets, loop counters, etc.) should keep using EAX/EBX/...
; directly -- they do not need to grow on amd64, and rewriting them would only add risk.

%define PAX     EAX
%define PBX     EBX
%define PCX     ECX
%define PDX     EDX
%define PSI     ESI
%define PDI     EDI
%define PBP     EBP
%define PSP     ESP

PTRSIZE EQU     4                                                               ;Size (bytes) of a native pointer
%define PTRKW   dword                                                           ;Size keyword for a native pointer,
                                                                                ; e.g. 'Jmp PTRKW [mem]' for an indirect jump
                                                                                ; through a resPTR-sized memory operand

%macro resPTR 1                                                                 ;Reserve space for N native pointers
    resd    %1
%endmacro


;===================================================================================================
;Load the Address of a Label
;
;Params:
;   Destination register, label (or label expression)

%macro LoadPtr 2
    Mov     %1,%2
%endmacro


;===================================================================================================
;Push/Pop All General-Purpose Registers
;
;PUSHAD/POPAD (opcodes 60h/61h) aren't encodable in 64-bit mode at all -- see x64.inc for the
; replacement there. Written as a raw DB here rather than the mnemonic itself, since a %macro
; sharing a name with a real instruction shadows it; writing the mnemonic in the macro body would
; just expand the macro again (recursively) instead of reaching the real PUSHAD/POPAD.

%macro PushAD 0
    DB      60h
%endmacro

%macro PopAD 0
    DB      61h
%endmacro


;===================================================================================================
;Store/Load a Value at a Compile-Time-Constant Label, Indexed
;
;See x64.inc for the full rationale. On x86 a label's address folds directly into an instruction's
; displacement, so both macros collapse to the single instruction the pre-port baseline always used
; -- no scratch register is touched, and %5 (the amd64-only scratch register) is accepted but
; ignored.
;
;Params:
;   op    - instruction mnemonic, optionally with a size specifier (e.g. "Mov" or "Mov byte")
;   label - compile-time-constant symbol being indexed
;   index - index expression (a register, "reg*scale", or 0 for no index)
;   val   - the other operand
;   reg   - (amd64 only; ignored here) scratch register to use, default PDI

;IdxSt: op [label+index],val   (memory is the destination -- a "store")
%macro IdxSt 4-5
    %1      [%2+%3],%4
%endmacro

;IdxLd: op val,[label+index]   (memory is the source -- a "load"; val is usually a register)
%macro IdxLd 4-5
    %1      %2,[%3+%4]
%endmacro

;IdxLdX: op val,size [label+index]   (memory is the source -- a "load"; for ops like MovZX/MovSX
; where val and the memory operand's size differ -- IdxLd's "%1 %2,[...]" template has nowhere to
; put the size keyword, which needs to sit between the comma and the bracket, so this variant
; exists for that shape. Collapses to the single instruction the pre-port baseline always used,
; same as IdxLd -- see x64.inc for the full rationale. %6 (the amd64-only scratch register) is
; accepted but ignored.
%macro IdxLdX 5-6
    %1      %2,%3 [%4+%5]
%endmacro


;===================================================================================================
;Combine a Register With a Compile-Time-Constant Label's Address (no memory operand)
;
;See x64.inc for the full rationale. On x86 a label's address is just a 32-bit immediate, so this
; collapses to the single instruction the pre-port baseline always used -- no scratch register is
; touched, and %4 (the amd64-only scratch register) is accepted but ignored.
;
;Params:
;   op    - instruction mnemonic (Add/Sub/And/Or/Cmp/...)
;   reg   - the register being combined with label's address
;   label - compile-time-constant symbol
;   reg2  - (amd64 only; ignored here) scratch register to use, default PDI
;
;LblOp: op reg,label

%macro LblOp 3-4
    %1      %2,%3
%endmacro


;===================================================================================================
;Store a Compile-Time-Constant Label's Address Into a Plain Memory Location
;
;See x64.inc for the full rationale. On x86 a label's address is a 32-bit immediate that can be
; stored directly, so this collapses to the single instruction the pre-port baseline always used
; -- no scratch register is touched, and %3 (the amd64-only scratch register) is accepted but
; ignored.
;
;Params:
;   dest  - the (non-indexed) memory location to store into -- a resPTR-sized variable
;   label - compile-time-constant symbol whose address is stored
;   reg   - (amd64 only; ignored here) scratch register to use, default PDI
;
;LblSt: Mov dword [dest],label

%macro LblSt 2-3
    Mov     dword [%1],%2
%endmacro


;===================================================================================================
;A Unary Instruction on a Compile-Time-Constant Label, Indexed
;
;See x64.inc for the full rationale. On x86 a label's address folds directly into an instruction's
; displacement, so this collapses to the single instruction the pre-port baseline always used
; -- no scratch register is touched, and %4 (the amd64-only scratch register) is accepted but
; ignored.
;
;Params:
;   op    - instruction mnemonic, optionally with a size specifier (e.g. "FILd dword")
;   label - compile-time-constant symbol being indexed
;   index - index expression (a register, "reg*scale", or 0 for no index)
;   reg   - (amd64 only; ignored here) scratch register to use, default PDI
;
;IdxUn: op [label+index]   (a single memory operand -- FStP/FILd/FIMul/Div/Inc/...)

%macro IdxUn 3-4
    %1      [%2+%3]
%endmacro


;===================================================================================================
;Declare a Table of Pointers/Code Addresses
;
;A plain 'DD label1,label2,...' jump/pointer table stores each address as a 32-bit value -- fine on
; x86, but on amd64 a real address needs the full 8 bytes (see x64.inc). Use PTRTAB so the same table
; source works on both, and PTRSIZE (not a literal 4) to scale any index into it.
;
;Params:
;   List of labels (or 0, for a null table entry)

%macro PTRTAB 1-*
    %rep %0
        DD      %1
        %rotate 1
    %endrep
%endmacro


;===================================================================================================
;Call Procedure
;
;If STDCALL is defined, the procedure is assumed to clean up the stack.
;
;Params:
;   Function name followed by stack parameters.  All arguments are assumed to be dwords.
;
;amd64 needs two distinct calling conventions -- a real Microsoft x64 ABI one (ExtCall) for
; anything crossing the DLL boundary, and a stack-based internal one (Call) for everything else,
; since just marshalling arguments into RCX/RDX/R8/R9 there clobbers them in the caller's own
; context (see x64.inc's Call for the full story). x86's stdcall/cdecl convention already passes
; every argument on the stack, so that split doesn't exist here -- ExtCall is simply Call under
; another name, so shared code can write EXPROC/ExtCall (for the ~29 DEF-exported entry points and
; genuinely external callback pointers) without an amd64-only %ifdef.

%macro Call 2-*
    %rep %0-1
        %rotate -1
        Push    dword %1
    %endrep
    %rotate -1

    Call    %1

    %ifndef STDCALL
        Add     ESP,(%0*4)-4
    %endif
%endmacro

;ExtCall duplicates Call's body rather than forwarding to it (e.g. 'Call %{1:-1}') -- nasm 2.10.09's
; %{n:m} parameter-range forwarding re-splits a multi-token argument like 'dword CBE_DSPREG' on its
; internal space, so the forwarded Call sees "dword" and "CBE_DSPREG" as two separate arguments
; instead of one, corrupting the argument count.

%macro ExtCall 2-*
    %rep %0-1
        %rotate -1
        Push    dword %1
    %endrep
    %rotate -1

    Call    %1

    %ifndef STDCALL
        Add     ESP,(%0*4)-4
    %endif
%endmacro


;===================================================================================================
;Return from Procedure
;
;Ensures the stack frame will be cleaned up and any used registers restored
;
;Params (optional):
;   Value to return in EAX

%macro RetN 0-1
    %if %0
        Mov     EAX,%1
    %endif

    %ifdef %$paramsize
        Jmp     %$Done
    %elifdef %$uses
        Jmp     %$Done
    %else
        Ret
    %endif
%endmacro


;===================================================================================================
;Conditional Return from Procedure (see RetN)

%macro RetZ 0-1
    %if %0
        Mov     EAX,%1
    %endif

    JZ      short %$Done
%endmacro


%macro RetZF 0-1
    %if %0
        Mov     EAX,%1
    %endif

    JZ      %$Done
%endmacro


%macro RetNZ 0-1
    %if %0
        Mov     EAX,%1
    %endif

    JNZ     short %$Done
%endmacro


%macro RetNZF 0-1
    %if %0
        Mov     EAX,%1
    %endif

    JNZ     %$Done
%endmacro


;===================================================================================================
;Publicly Declare a Label
;
;If INTERNAL is defined, the label is declared as GLOBAL, otherwise EXTERN.
;If STDCALL is defined, the label has an underscore prepended and an 'at' with the size of the
; argument stack appended.
;If CDECL is defined, the label has an underscore prepended.
;
;Params:
;   The variable or procedure name.  Procedures must be followed by a list of arguments.  If a
;   procedure has no arguments, specify 'NULL'.

%macro PUBLIC 1-*
    %ifdef STDCALL
        %if %0==1
            %xdefine    PUBNAME _%1
        %elif %0==2
            %ifidni %2,NULL
                %xdefine    PUBNAME _%1@0
            %else
                %xdefine    PUBNAME _%1@4
            %endif
        %elif %0==3
            %xdefine    PUBNAME _%1@8
        %elif %0==4
            %xdefine    PUBNAME _%1@12
        %elif %0==5
            %xdefine    PUBNAME _%1@16
        %elif %0==6
            %xdefine    PUBNAME _%1@20
        %elif %0==7
            %xdefine    PUBNAME _%1@24
        %elif %0==8
            %xdefine    PUBNAME _%1@28
        %elif %0==9
            %xdefine    PUBNAME _%1@32
        %elif
            %error  "PUBLIC :: Procedures cannot have more than 8 arguments"
        %endif
        %ifdef INTERNAL
            GLOBAL  PUBNAME
        %else
            EXTERN  PUBNAME
        %endif
        %xdefine    %1  PUBNAME
    %elifdef CDECL
        %ifdef INTERNAL
            GLOBAL  _%1
        %else
            EXTERN  _%1
        %endif
        %xdefine    %1  _%1
    %else
        %ifdef INTERNAL
            GLOBAL  %1
        %else
            EXTERN  %1
        %endif
    %endif
%endmacro


;===================================================================================================
;Define Externally-Callable Procedure
;
;See x64.inc's EXPROC for the full rationale (amd64 needs a distinct, real-ABI entry macro for
; anything crossing the DLL boundary; x86 doesn't, since stdcall/cdecl already applies uniformly).
; EXPROC is simply PROC under another name here, so shared code can write EXPROC without an
; amd64-only %ifdef. A DEF-exported name that's also called from elsewhere in this codebase still
; doesn't need the EXPROC-plus-'I'-suffix split x64.inc describes -- on x86 there's nothing to
; bridge, so calling the DEF-exported name directly is already the fast path.
;
;EXPROC duplicates PROC's body rather than forwarding to it (e.g. 'PROC %{1:-1}') -- see ExtCall's
; note above on why nasm 2.10.09's %{n:m} forwarding isn't used here either. EXPROC's own arguments
; are plain identifiers (no multi-token values), so the bug that note describes cannot actually
; trigger here today, but staying consistent with ExtCall avoids relying on that forwarding at all.

%macro EXPROC 1-*
    ALIGN   16                                                                  ;Align entry point on a cache line boundary
    %1:                                                                         ;Define procedure label

    %push PROC                                                                  ;Save context

    %if %0>9
        %error  "EXPROC :: Procedures cannot have more than 8 arguments"
    %endif

    %if %0>1                                                                    ;Does this procedure have any arguments?
        Push    EBP                                                             ;Create a frame pointer
        Mov     EBP,ESP

        %assign %$paramsize (%0*4)-4                                            ;Save the size of the frame

        %if %0>=2                                                               ;Create pointers to each argument
            %define %2  EBP+8

        %if %0>=3
            %define %3  EBP+12

        %if %0>=4
            %define %4  EBP+16

        %if %0>=5
            %define %5  EBP+20

        %if %0>=6
            %define %6  EBP+24

        %if %0>=7
            %define %7  EBP+28

        %if %0>=8
            %define %8  EBP+32

        %if %0>=9
            %define %9  EBP+36

        %endif
        %endif
        %endif
        %endif
        %endif
        %endif
        %endif
        %endif
    %endif
%endmacro


;===================================================================================================
;Define Procedure
;
;Used to begin a procedure definition (body).  Defines a label, creates the initial stack frame,
; and generates offsets for any arguments.  Arguments are assumed to be 32-bit and passed right to
; left on the stack (stdcall/cdecl).
;
;Params:
;   Procedure name followed by a list of arguments passed on the stack

%macro PROC 1-*
    ALIGN   16                                                                  ;Align entry point on a cache line boundary
    %1:                                                                         ;Define procedure label

    %push PROC                                                                  ;Save context

    %if %0>9
        %error  "PROC :: Procedures cannot have more than 8 arguments"
    %endif

    %if %0>1                                                                    ;Does this procedure have any arguments?
        Push    EBP                                                             ;Create a frame pointer
        Mov     EBP,ESP

        %assign %$paramsize (%0*4)-4                                            ;Save the size of the frame

        %if %0>=2                                                               ;Create pointers to each argument
            %define %2  EBP+8

        %if %0>=3
            %define %3  EBP+12

        %if %0>=4
            %define %4  EBP+16

        %if %0>=5
            %define %5  EBP+20

        %if %0>=6
            %define %6  EBP+24

        %if %0>=7
            %define %7  EBP+28

        %if %0>=8
            %define %8  EBP+32

        %if %0>=9
            %define %9  EBP+36

        %endif
        %endif
        %endif
        %endif
        %endif
        %endif
        %endif
        %endif
    %endif
%endmacro


;===================================================================================================
;Define Local Variables
;
;Defines a list of local variables to be temporarily allocated on the stack
;
;Params:
;   Variable names (each var is allocated 32-bits)

%macro LOCALS 1-8
    %assign %$localsize %0*4                                                    ;Save the size of the local variables

    %ifndef %$paramsize                                                         ;If a stack frame hasn't been created, create one
        %assign %$paramsize 0                                                   ;No arguments
        Push    EBP
        Mov     EBP,ESP
    %endif

    %if %0>8
        %error  "LOCALS :: Procedures cannot have more than 8 local variables"
    %endif

    %if %0>=1                                                                   ;Create pointers to each of the locals
        %define %1  EBP-4

    %if %0>=2
        %define %2  EBP-8

    %if %0>=3
        %define %3  EBP-12

    %if %0>=4
        %define %4  EBP-16

    %if %0>=5
        %define %5  EBP-20

    %if %0>=6
        %define %6  EBP-24

    %if %0>=7
        %define %7  EBP-28

    %if %0>=8
        %define %8  EBP-32

    %endif
    %endif
    %endif
    %endif
    %endif
    %endif
    %endif
    %endif

    Sub     ESP,%$localsize                                                     ;Allocate space on the stack
%endmacro


;===================================================================================================
;Registers Used by Procedure
;
;Pushes registers onto the stack, then restores them at the end of the procedure.  EAX is assumed
; to contain the return value.  EBP and ESP must be saved manually, if no stack frame is used.
;
;Params:
;   Registers used by the procedure (EBX, ECX, EDX, ESI, and EDI, or ALL to save all five)

%macro USES 1-5
    %ifidni %1,ALL
        Push    ECX,EDX,EBX,ESI,EDI
        %assign %$uses 5
        %assign %$ECX 0
        %assign %$EDX 1
        %assign %$EBX 2
        %assign %$ESI 3
        %assign %$EDI 4
    %else
        %assign %$uses  0
        %rep    %0
            %ifidni %1,ECX                                                      ;Does parameter == "ECX"?
                %assign %$ECX %$uses                                            ;Define "$ECX" as the current push position
                Push    ECX                                                     ;Push ECX
            %elifidni %1,EDX
                %assign %$EDX %$uses
                Push    EDX
            %elifidni %1,EBX
                %assign %$EBX %$uses
                Push    EBX
            %elifidni %1,ESI
                %assign %$ESI %$uses
                Push    ESI
            %elifidni %1,EDI
                %assign %$EDI %$uses
                Push    EDI
            %else
                %error  "USES only accepts EBX, ECX, EDX, ESI, EDI, or ALL"
            %endif

            %rotate 1
            %assign %$uses %$uses+1
        %endrep
    %endif

%endmacro


;===================================================================================================
;End Procedure Definition
;
;Ends a procedure definition.  Restores any used registers, cleans up the stack frame, and pops the
; context stack.  Also pops any arguments off the stack if STDCALL is defined.

%macro ENDP 0
    %$Done:

    %assign %$i 4
    %rep 5
        %ifdef %$ECX                                                            ;Is "$ECX" defined?
            %if %$ECX==%$i                                                      ;Does it equal the current pop position?
                Pop     ECX
            %endif
        %endif

        %ifdef %$EDX
            %if %$EDX==%$i
                Pop     EDX
            %endif
        %endif

        %ifdef %$EBX
            %if %$EBX==%$i
                Pop     EBX
            %endif
        %endif

        %ifdef %$ESI
            %if %$ESI==%$i
                Pop     ESI
            %endif
        %endif

        %ifdef %$EDI
            %if %$EDI==%$i
                Pop     EDI
            %endif
        %endif

        %assign %$i %$i-1
    %endrep

    %ifdef %$paramsize
        Leave

        %if %$paramsize>0
            %ifdef STDCALL
                Ret     %$paramsize
            %else
                Ret
            %endif
        %else
            Ret
        %endif
    %else
        Ret
    %endif

    %pop
%endmacro
