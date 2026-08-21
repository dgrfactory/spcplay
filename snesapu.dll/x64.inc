;===================================================================================================
;Program:    amd64 (Win64) Backend Macros for NASM
;Platform:   x86-64 / Microsoft x64 calling convention
;
;This file is the amd64 counterpart to x86.inc, selected by macro.inc when WIN64 is defined.  It
;implements the *same* macro interface (PROC/ENDP/USES/PUBLIC/Call/RetN/LOCALS, plus the pointer
;aliases PAX/PBX/.../PTRSIZE/resPTR) so that shared code in APU.asm/DSP.asm/SPC700.asm does not need
;to know which architecture it is being built for.
;
;Calling convention notes:
;   - There are TWO conventions in this file, and which one to use depends on who's calling:
;       * EXPROC/ExtCall/ExtCallArg -- the real Microsoft x64 calling convention (RCX/RDX/R8/R9,
;         32-byte shadow space, caller-cleans-stack, 16-byte alignment at each CALL). Use this ONLY
;         for the DEF-exported entry points something outside this DLL calls, and for calling a
;         genuinely external function pointer (a frontend-registered callback).
;       * PROC/Call/CallArg -- an internal-only convention that passes every argument on the stack,
;         exactly like the x86 backend does (see x86.inc). Use this for everything else. See PROC's
;         doc below for why a second convention exists at all: in short, marshalling arguments into
;         RCX/RDX/R8/R9 necessarily clobbers them in the CALLER's context before the callee's own
;         USES-protected prologue ever runs, which silently breaks code written assuming the x86
;         stdcall property that PCX/PDX/etc. survive a call unless the callee's own body says so.
;   - EXPROC 'homes' its incoming register arguments (RCX/RDX/R8/R9) into the caller-provided shadow
;     space at [RBP+16]/[RBP+24]/[RBP+32]/[RBP+40]; PROC's arguments are already at those same offsets
;     because Call pushed them there directly. Either way the 5th+ arguments are read directly from
;     the stack slots the caller placed them in ([RBP+48], [RBP+56], ...). This means body code that
;     reads a parameter as '[pc]', '[a]', etc. is UNCHANGED from the x86 version -- only the *offsets*
;     differ, and those are hidden behind the %define generated here.
;   - Per the Windows x64 ABI, small (byte/word) typed arguments still occupy a full register/stack
;     slot with the upper bits UNSPECIFIED.  Body code must keep reading parameters at their true
;     width (byte/word/dword) exactly as it already does -- never widen a read of a byte/word
;     parameter to a qword.
;   - Both Call and ExtCall stage every argument into memory before touching any register the
;     marshalling itself needs, so (unlike the ordering hazard this used to have) an argument
;     expression may safely reference any register, including one another argument also writes to.
;
;                                                   Copyright (C) 2026 degrade-factory
;
;List of users and dates who/when modified this file:
;   - degrade-factory in 2026-08-21
;===================================================================================================

%define ARCH_BITS   64

DEFAULT REL                                                                     ;RIP-relative [mem] addressing (position-independent,
                                                                                ; matches how Windows x64 DLLs are normally built)

;===================================================================================================
;Pointer-width register aliases
;
;Use these ONLY where a register genuinely holds a memory address (a pointer).  Registers used for
; plain 32-bit arithmetic (sample counts, offsets, loop counters, etc.) should keep using EAX/EBX/...
; directly -- writing to a 32-bit sub-register automatically zero-extends the full 64-bit register,
; so mixing PAX and EAX on the same physical register across a routine is safe.

%define PAX     RAX
%define PBX     RBX
%define PCX     RCX
%define PDX     RDX
%define PSI     RSI
%define PDI     RDI
%define PBP     RBP
%define PSP     RSP

PTRSIZE EQU     8                                                               ;Size (bytes) of a native pointer
%define PTRKW   qword                                                           ;Size keyword for a native pointer,
                                                                                ; e.g. 'Jmp PTRKW [mem]' for an indirect jump
                                                                                ; through a resPTR-sized memory operand

%macro resPTR 1                                                                 ;Reserve space for N native pointers
    resq    %1
%endmacro


;===================================================================================================
;Load the Address of a Label
;
;A bare 'Mov reg,label' would assemble as a 10-byte absolute 64-bit immediate load, which needs a
; base relocation and defeats ASLR-friendly position-independent code.  Use RIP-relative LEA
; instead.
;
;Params:
;   Destination register, label (or label expression)

%macro LoadPtr 2
    LEA     %1,[%2]
%endmacro


;===================================================================================================
;Push/Pop All General-Purpose Registers
;
;PUSHAD/POPAD (opcodes 60h/61h) aren't encodable in 64-bit mode at all, so this pushes/pops the
; seven pointer-width aliases individually instead.  PUSHAD also saves the pre-push ESP, but nothing
; in this codebase ever read that slot back out, so it's dropped here rather than emulated. R8-R15
; are intentionally left out -- nothing in this port's calling convention needs them preserved across
; a PushAD/PopAD span, and adding them would just be more state to save/restore for no benefit.

%macro PushAD 0
    Push    PAX,PCX,PDX,PBX,PBP,PSI,PDI
%endmacro

%macro PopAD 0
    Pop     PDI,PSI,PBP,PBX,PDX,PCX,PAX
%endmacro


;===================================================================================================
;Store/Load a Value at a Compile-Time-Constant Label, Indexed
;
;amd64's RIP-relative addressing cannot take an SIB index register, so combining a compile-time
; label's address with a runtime index needs a real base register -- unlike x86, which folds the
; label straight into the instruction's displacement (see x86.inc). Earlier in this port, individual
; call sites picked whichever register looked "free" for this and were wrong more than once: the
; register turned out to already hold something a caller elsewhere in the call graph needed
; (SPC700.asm's PC, its RAM pointer, its X register, ...). These macros push/pop the scratch
; register around the single instruction that needs it instead, so nothing at the call site has to
; reason about whether it is free -- it always survives, at the cost of a push/pop pair on every use.
;
;Params:
;   op    - instruction mnemonic, optionally with a size specifier (e.g. "Mov" or "Mov byte")
;   label - compile-time-constant symbol being indexed
;   index - index expression (a register, "reg*scale", or 0 for no index)
;   val   - the other operand
;   reg   - (optional) scratch register to use; default PDI. Must not also be used as the index or
;           val operand in the same call (its value going into that instruction would be the label's
;           address, not whatever the caller still needed it to hold).
;
;           R8-R15 (no x86 counterpart, so never a P-alias/index/val operand -- see the PAX/PBX/.../
;           PSP aliases below) look tempting as a default that could never collide, but DON'T default
;           to one: any of R8-R15 forces a REX prefix onto the final op instruction, and a REX prefix
;           makes AH/BH/CH/DH impossible to encode at all -- and val is routinely one of those here.
;           A high(R8-R15)-register default breaks the instant val is AH/BH/CH/DH, which is common
;           enough in this codebase (see e.g. DSPInC's mix-flag test) that it's not a safe default;
;           PDI/PSI/PBX/PCX/PDX never force a REX prefix by themselves, so they stay compatible with
;           AH/BH/CH/DH. An R8-R15 register is still fine to pass explicitly at a specific call site
;           where val/index are known not to be a high-byte register.

;IdxSt: op [label+index],val   (memory is the destination -- a "store")
%macro IdxSt 4-5 PDI
    Push    %5
    LoadPtr %5,%2
    %1      [%5+%3],%4
    Pop     %5
%endmacro

;IdxLd: op val,[label+index]   (memory is the source -- a "load"; val is usually a register)
;If val IS the scratch register (i.e. the load's whole point is to get the value into it), the
; pushed copy is discarded instead of restored -- popping it back would overwrite the very value
; just loaded.
%macro IdxLd 4-5 PDI
    Push    %5
    LoadPtr %5,%3
    %1      %2,[%5+%4]
    %ifnidni %2,%5
        Pop     %5
    %else
        Add     PSP,PTRSIZE
    %endif
%endmacro

;IdxLdX: op val,size [label+index]   (memory is the source -- a "load", for ops like MovZX/MovSX
; where val and the memory operand's size differ, e.g. a byte in memory zero-extended into a 32-bit
; register.  IdxLd's plain "%1 %2,[...]" template has nowhere to put the size keyword -- it needs to
; sit between the comma and the bracket, not before val -- so this is a separate macro for exactly
; that shape, otherwise identical to IdxLd (same val-is-the-scratch-register handling below).  Pass
; val as a P-alias (e.g. PDI, not EDI) if it might collide with the scratch register -- a bare
; 32-bit name would go undetected by %ifnidni below since it's spelled differently from the
; pointer-width alias even though they're the same physical register; writing PDI zero-extends the
; same way EDI would -- a 32-bit write always zero-extends the full 64-bit register in x64, and
; MovZX's own byte->32-bit extension already leaves the result non-negative, so targeting the
; 64-bit name changes nothing observable.
%macro IdxLdX 5-6 PDI
    Push    %6
    LoadPtr %6,%4
    %1      %2,%3 [%6+%5]
    %ifnidni %2,%6
        Pop     %6
    %else
        Add     PSP,PTRSIZE
    %endif
%endmacro


;===================================================================================================
;Combine a Register With a Compile-Time-Constant Label's Address (no memory operand)
;
;Not every place this port needed a label's address is a memory operand IdxSt/IdxLd's '[reg+index]'
; shape covers -- some just add/subtract/compare it against a register's own value (e.g. turning a
; pointer into an index and back). x86 can embed a label's address as a plain 32-bit immediate
; operand for this; amd64 cannot (ADD/SUB/etc. to a 64-bit register only take a sign-extended imm32),
; so a register has to carry it -- same reasoning, and same push/pop-a-scratch-register solution, as
; IdxSt/IdxLd (see above).
;
;Params:
;   op    - instruction mnemonic (Add/Sub/And/Or/Cmp/...)
;   reg   - the register being combined with label's address
;   label - compile-time-constant symbol
;   reg2  - (optional) scratch register to use; default PDI (see IdxSt/IdxLd's note above on why not
;           an R8-R15 register). Must not be the same register as reg.
;
;LblOp: op reg,label
%macro LblOp 3-4 PDI
    Push    %4
    LoadPtr %4,%3
    %1      %2,%4
    Pop     %4
%endmacro


;===================================================================================================
;Store a Compile-Time-Constant Label's Address Into a Plain Memory Location
;
;x86 can 'Mov dword [mem],label' directly (a label's address is a 32-bit immediate); amd64 has no
; MOV m64,imm64 form (only reg64,imm64), so storing a full 64-bit address to memory needs a register
; in between regardless of indexing -- same reasoning as IdxSt/IdxLd/LblOp, just for the simplest
; case of all (no index, dest and source are each just one plain location).
;
;Params:
;   dest  - the (non-indexed) memory location to store into -- a resPTR-sized variable
;   label - compile-time-constant symbol whose address is stored
;   reg   - (optional) scratch register to use; default PDI (see IdxSt/IdxLd's note on why not an
;           R8-R15 register)
;
;LblSt: Mov [dest],label
%macro LblSt 2-3 PDI
    Push    %3
    LoadPtr %3,%2
    Mov     [%1],%3
    Pop     %3
%endmacro


;===================================================================================================
;A Unary Instruction on a Compile-Time-Constant Label, Indexed
;
;Same reasoning as IdxSt/IdxLd, for instructions with only one explicit operand (FStP/FILd/FIMul/
; Div/Inc/...) so they do not fit either macro's two-operand shape.
;
;Params:
;   op    - instruction mnemonic, optionally with a size specifier (e.g. "FILd dword")
;   label - compile-time-constant symbol being indexed
;   index - index expression (a register, "reg*scale", or 0 for no index)
;   reg   - (optional) scratch register to use; default PDI (see IdxSt/IdxLd's note above on why not
;           an R8-R15 register). Must not also be used as the index.
;
;IdxUn: op [label+index]   (a single memory operand)
%macro IdxUn 3-4 PDI
    Push    %4
    LoadPtr %4,%2
    %1      [%4+%3]
    Pop     %4
%endmacro


;===================================================================================================
;Declare a Table of Pointers/Code Addresses (see x86.inc PTRTAB for full doc)
;
;Unlike a code-embedded 'Mov reg,label' (see LoadPtr above), a DQ table entry is exactly how x64
; pointer/vtable-style tables are normally built: the loader's base relocation table patches each
; 8-byte slot at load time, so this stays correct under ASLR without needing RIP-relative tricks.
;
;Params:
;   List of labels (or 0, for a null table entry)

%macro PTRTAB 1-*
    %rep %0
        DQ      %1
        %rotate 1
    %endrep
%endmacro


;===================================================================================================
;Move One ExtCall Argument Into Its Destination Register
;
;A plain value (immediate, 32-bit register, or memory) is moved 32-bit-wide, which zero-extends the
; full 64-bit register -- this is what most call sites pass and matches the x86 backend's behaviour.
; A pointer already sitting in one of the PAX/PBX/... alias registers must instead be moved 64-bit
; wide: 'Mov ECX,RDI' (destination narrower than a 64-bit source register) is not an encodable
; instruction, and even if it were, it would silently truncate the pointer's upper half.  So: to
; pass a pointer to ExtCall, load it into a PAX/PBX/... register at the call site first (a bare
; '[label]' is not enough -- ExtCall has no way to know whether that memory holds a 4-byte or 8-byte
; value).
;
;Params:
;   64-bit destination register, 32-bit destination register, source token

%macro ExtCallArg 3
    %ifidni %3,PAX
        Mov     %1,%3
    %elifidni %3,PBX
        Mov     %1,%3
    %elifidni %3,PCX
        Mov     %1,%3
    %elifidni %3,PDX
        Mov     %1,%3
    %elifidni %3,PSI
        Mov     %1,%3
    %elifidni %3,PDI
        Mov     %1,%3
    %elifidni %3,PBP
        Mov     %1,%3
    %elifidni %3,PSP
        Mov     %1,%3
    %else
        Mov     %2,%3
    %endif
%endmacro


;===================================================================================================
;Move One (Internal) Call Argument Onto the Stack
;
;Unlike ExtCallArg (which loads into a fixed register), this pushes straight onto the stack -- see
; the internal Call macro below for why. A pointer sitting in a PAX/PBX/... alias register is
; pushed verbatim (already 8 bytes wide); anything else (immediate, 32-bit register, or memory) is
; first zero-extended into the scratch register pair so a 4-byte source (e.g. a plain dword variable)
; never gets over-read as 8 bytes by a bare 'Push qword'.
;
;Params:
;   64-bit scratch register, 32-bit scratch register, source token

%macro CallArg 3
    %ifidni %3,PAX
        Push    %3
    %elifidni %3,PBX
        Push    %3
    %elifidni %3,PCX
        Push    %3
    %elifidni %3,PDX
        Push    %3
    %elifidni %3,PSI
        Push    %3
    %elifidni %3,PDI
        Push    %3
    %elifidni %3,PBP
        Push    %3
    %elifidni %3,PSP
        Push    %3
    %else
        Mov     %2,%3
        Push    %1
    %endif
%endmacro


;===================================================================================================
;ExtCall Procedure (Microsoft x64 calling convention)
;
;Use this ONLY to call something that must honor the real Windows x64 ABI: a genuinely external
; function pointer (e.g. the frontend's registered apuCbFunc/pDebug/pTraceFunc callbacks). For
; every other call within this codebase, use the plain (internal) Call below instead -- see its doc
; for why a second convention exists at all.
;
;Params:
;   Function name followed by up to 8 arguments.  The first 4 are passed in RCX/RDX/R8/R9; any
;   further arguments are placed on the stack, above a 32-byte shadow space, 16-byte aligned, and are
;   cleaned up by the caller after the call returns (Win64 is caller-cleanup, so unlike the x86
;   backend this needs no STDCALL/CDECL distinction). See ExtCallArg above for how pointer arguments
;   are handled.

%macro ExtCall 2-*
    %if %0>9
        %error  "ExtCall :: Procedures cannot have more than 8 arguments"
    %endif

    %push ExtCallCtx                                                            ;Own context for %$n/%$stackn/%$framesz below --
                                                                                ; ExtCall can be invoked from bare (non-PROC) code, e.g.
                                                                                ; SPC700.asm's jump-table opcode handlers, so it cannot
                                                                                ; rely on an enclosing PROC's %push context existing.
    %assign %$n %0-1                                                            ;Number of real arguments
    %assign %$stackn 0
    %if %$n>4
        %assign %$stackn %$n-4
    %endif

    %assign %$framesz 32+(%$stackn*8)                                           ;Shadow space + stack args
    %if (%$framesz % 16)!=0                                                     ;Keep RSP 16-byte aligned at CALL
        %assign %$framesz %$framesz+8
    %endif

    Sub     RSP,%$framesz

    ;An indirect call target (e.g. 'ExtCall PCX,...', calling through a register) can itself alias
    ; one of the argument destination registers -- 'ExtCall PCX,dword CBE_REQBP,...' calls through RCX
    ; while also passing an arg 1 that's destined for RCX, so the target must be read out of RCX and
    ; into a register nothing below ever writes (R11; R10 is already the argument-staging scratch)
    ; before any argument setup begins, or the call would jump through its own clobbered first
    ; argument instead of the real target. A label target (the common case) needs no such staging.
    %ifidni %1,PAX
        Mov     R11,%1
        %define %$target R11
    %elifidni %1,PBX
        Mov     R11,%1
        %define %$target R11
    %elifidni %1,PCX
        Mov     R11,%1
        %define %$target R11
    %elifidni %1,PDX
        Mov     R11,%1
        %define %$target R11
    %elifidni %1,PSI
        Mov     R11,%1
        %define %$target R11
    %elifidni %1,PDI
        Mov     R11,%1
        %define %$target R11
    %elifidni %1,PBP
        Mov     R11,%1
        %define %$target R11
    %elifidni %1,PSP
        Mov     R11,%1
        %define %$target R11
    %else
        %define %$target %1
    %endif

    ;Stage every argument's source value into memory before touching any of RAX/RCX/RDX/R8/R9 --
    ; this avoids a hazard where an earlier-assigned register (e.g. RDX for arg 2, or RAX used as a
    ; scratch to stage some other arg) is also the literal source token of a later-staged argument
    ; (e.g. "PDX" for arg 1, or "EAX" for some other arg): assigning straight into the final
    ; registers in a fixed order (whichever direction) would let one argument's write clobber
    ; another argument's source before it's ever read, and using RAX itself as the scratch to stage
    ; into memory has the exact same problem if some argument's source is literally EAX/PAX.  R10 has
    ; no x86 counterpart and so is never a P-alias/index/val operand anywhere in the shared codebase
    ; (see IdxSt/IdxLd's note on R8-R15), making it a scratch register no source token can ever alias.
    %if %$n>=8
        ExtCallArg R10,R10D,%9
        Mov     [RSP+32+24],R10
    %endif
    %if %$n>=7
        ExtCallArg R10,R10D,%8
        Mov     [RSP+32+16],R10
    %endif
    %if %$n>=6
        ExtCallArg R10,R10D,%7
        Mov     [RSP+32+8],R10
    %endif
    %if %$n>=5
        ExtCallArg R10,R10D,%6
        Mov     [RSP+32+0],R10
    %endif
    %if %$n>=4
        ExtCallArg R10,R10D,%5
        Mov     [RSP+24],R10
    %endif
    %if %$n>=3
        ExtCallArg R10,R10D,%4
        Mov     [RSP+16],R10
    %endif
    %if %$n>=2
        ExtCallArg R10,R10D,%3
        Mov     [RSP+8],R10
    %endif
    %if %$n>=1
        ExtCallArg R10,R10D,%2
        Mov     [RSP+0],R10
    %endif

    %if %$n>=1
        Mov     RCX,[RSP+0]
    %endif
    %if %$n>=2
        Mov     RDX,[RSP+8]
    %endif
    %if %$n>=3
        Mov     R8,[RSP+16]
    %endif
    %if %$n>=4
        Mov     R9,[RSP+24]
    %endif

    Call    %$target

    Add     RSP,%$framesz
    %pop
%endmacro


;===================================================================================================
;Call Procedure (internal convention)
;
;THE ROOT PROBLEM THIS SOLVES: Microsoft x64's calling convention passes the first 4 arguments in
; RCX/RDX/R8/R9 -- registers this codebase's P-aliases treat as callee-saved-unless-documented
; (PCX/PDX survive a call on x86, where stdcall arguments go on the stack, unless the callee's own
; body -- protected by its own USES -- touches them). On x64, just SETTING UP a register-passed
; argument list necessarily clobbers RCX/RDX/R8/R9 in the CALLER's own context, before the callee's
; prologue (and its USES) ever runs -- so a callee's USES can only protect what's *already been
; overwritten* with argument values, not the caller's original contents. A real bug from exactly
; this: SPCTimers keeps its EDX live across 'Call CatchUp' (a bare 0-arg call, so no marshalling
; issue by itself) expecting it to survive like it would on x86 -- but CatchUp's own body calls
; 'Call EmuDSP,PDX,EAX', and that marshalling silently clobbers RDX out from under the caller three
; frames up.
;
;So: every PROC-to-PROC call *within this codebase* (i.e. everything except a genuinely external
; function pointer -- see ExtCall above) goes through this Call instead, which passes arguments
; on the stack exactly like the x86 backend does (see x86.inc's Call) instead of through RCX/RDX/R8/R9.
; PCX/PDX/PBX/PSI/PDI/PBP then behave exactly as they do on x86: untouched by a call's argument
; setup, destroyed only if the callee's own body (and its USES, if any) says so.
;
;Params:
;   Function name followed by up to 8 arguments, pushed right-to-left onto the stack (caller cleans
;   up afterward -- there's no external ABI to match here, so no STDCALL/CDECL distinction is needed).
;   See CallArg above for how pointer arguments are handled (pushed as-is; anything else is
;   zero-extended into a scratch register first, since a 4-byte source, e.g. a plain dword variable,
;   must never be over-read as 8 bytes by a bare 'Push qword').

%macro Call 2-*
    %if %0>9
        %error  "Call :: Procedures cannot have more than 8 arguments"
    %endif

    %rep %0-1
        %rotate -1
        CallArg R10,R10D,%1
    %endrep
    %rotate -1

    Call    %1

    %assign %%argsize (%0*PTRSIZE)-PTRSIZE
    %if %%argsize>0
        Add     RSP,%%argsize
    %endif
%endmacro


;===================================================================================================
;Return from Procedure (see x86.inc RetN for full doc)
;
;Note: this sets EAX (zero-extending RAX), matching the vast majority of call sites which return a
; plain integer.  A proc that must return a pointer should set PAX (RAX) explicitly in the body and
; fall through to ENDP/RetN with no argument, rather than passing a 64-bit value through here.

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
;The Microsoft x64 ABI has a single calling convention -- no leading underscore, no '@N' stack-size
; suffix (those are x86-only stdcall/cdecl artifacts).  STDCALL/CDECL are intentionally ignored here.

%macro PUBLIC 1-*
    %ifdef INTERNAL
        GLOBAL  %1
    %else
        EXTERN  %1
    %endif
%endmacro


;===================================================================================================
;Define Externally-Callable Procedure (real Microsoft x64 calling convention)
;
;Use this ONLY for the small set of functions something outside this DLL actually calls directly:
; the ~29 names in SNESAPU.def, and nothing else. Everything else -- including a DEF-exported
; function's OWN internal recursion/helpers (e.g. EmuAPU calling itself, or CatchUp calling EmuDSP)
; -- should be a plain (internal) PROC instead; see PROC's doc below for why. A DEF-exported name
; that is ALSO called from elsewhere in this codebase should be split in two: a thin EXPROC of that
; exact name that only re-homes its arguments and forwards via the internal Call to a plain PROC of
; the same name plus an 'I' suffix (e.g. EXPROC EmuAPU forwards to PROC EmuAPUI), so every internal
; caller can Call the fast/internal-convention 'EmuAPUI' directly instead of paying for (and risking)
; the ABI bridge on every recursive call.
;
;Params:
;   Procedure name followed by a list of arguments (up to 8).  Arguments 1-4 arrive in
;   RCX/RDX/R8/R9 and are homed into the shadow space the caller reserved; arguments 5-8 are read
;   directly from the stack slots the caller placed them in.

%macro EXPROC 1-*
    ALIGN   16                                                                  ;Align entry point on a cache line boundary
    %1:                                                                         ;Define procedure label

    %push PROC                                                                  ;Save context

    %if %0>9
        %error  "EXPROC :: Procedures cannot have more than 8 arguments"
    %endif

    %if %0>1                                                                    ;Does this procedure have any arguments?
        Push    RBP                                                             ;Create a frame pointer
        Mov     RBP,RSP

        %assign %$paramsize (%0*8)-8                                            ;Save the size of the frame

        %if %0>=2                                                               ;Home register args / point at stack args
            %define %2  RBP+16
            Mov     [RBP+16],RCX

        %if %0>=3
            %define %3  RBP+24
            Mov     [RBP+24],RDX

        %if %0>=4
            %define %4  RBP+32
            Mov     [RBP+32],R8

        %if %0>=5
            %define %5  RBP+40
            Mov     [RBP+40],R9

        %if %0>=6
            %define %6  RBP+48                                                  ;Already on the stack, caller-provided

        %if %0>=7
            %define %7  RBP+56

        %if %0>=8
            %define %8  RBP+64

        %if %0>=9
            %define %9  RBP+72

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
;Define Procedure (internal convention -- see the internal Call macro above for the full rationale)
;
;Params:
;   Procedure name followed by a list of arguments (up to 8), all read directly from the stack slots
;   the internal Call macro pushed them into -- no RCX/RDX/R8/R9 homing, so nothing here ever
;   overwrites those registers on entry.

%macro PROC 1-*
    ALIGN   16                                                                  ;Align entry point on a cache line boundary
    %1:                                                                         ;Define procedure label

    %push PROC                                                                  ;Save context

    %if %0>9
        %error  "PROC :: Procedures cannot have more than 8 arguments"
    %endif

    %if %0>1                                                                    ;Does this procedure have any arguments?
        Push    RBP                                                             ;Create a frame pointer
        Mov     RBP,RSP

        %assign %$paramsize (%0*8)-8                                            ;Save the size of the frame

        %if %0>=2                                                               ;Point at the stack slots Call already pushed
            %define %2  RBP+16

        %if %0>=3
            %define %3  RBP+24

        %if %0>=4
            %define %4  RBP+32

        %if %0>=5
            %define %5  RBP+40

        %if %0>=6
            %define %6  RBP+48

        %if %0>=7
            %define %7  RBP+56

        %if %0>=8
            %define %8  RBP+64

        %if %0>=9
            %define %9  RBP+72

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
;Define Local Variables (see x86.inc LOCALS for full doc)
;
;Each local is a native pointer-sized (8-byte) slot.  The total is padded to a multiple of 16 bytes
; so RSP stays 16-byte aligned across any Call made later in the procedure.

%macro LOCALS 1-8
    %assign %$localsize %0*8

    %ifndef %$paramsize
        %assign %$paramsize 0
        Push    RBP
        Mov     RBP,RSP
    %endif

    %if %0>8
        %error  "LOCALS :: Procedures cannot have more than 8 local variables"
    %endif

    %if %0>=1
        %define %1  RBP-8

    %if %0>=2
        %define %2  RBP-16

    %if %0>=3
        %define %3  RBP-24

    %if %0>=4
        %define %4  RBP-32

    %if %0>=5
        %define %5  RBP-40

    %if %0>=6
        %define %6  RBP-48

    %if %0>=7
        %define %7  RBP-56

    %if %0>=8
        %define %8  RBP-64

    %endif
    %endif
    %endif
    %endif
    %endif
    %endif
    %endif
    %endif

    %if (%$localsize % 16)!=0
        %assign %$localsize %$localsize+8
    %endif

    Sub     RSP,%$localsize
%endmacro


;===================================================================================================
;Registers Used by Procedure (see x86.inc USES for full doc)
;
;Params:
;   Same token names as the x86 backend (EBX/ECX/EDX/ESI/EDI, or ALL) -- shared code does not need to
;   change.  This backend pushes/pops the full 64-bit register underneath each name.

%macro USES 1-5
    %ifidni %1,ALL
        Push    RCX,RDX,RBX,RSI,RDI
        %assign %$uses 5
        %assign %$ECX 0
        %assign %$EDX 1
        %assign %$EBX 2
        %assign %$ESI 3
        %assign %$EDI 4
    %else
        %assign %$uses  0
        %rep    %0
            %ifidni %1,ECX
                %assign %$ECX %$uses
                Push    RCX
            %elifidni %1,EDX
                %assign %$EDX %$uses
                Push    RDX
            %elifidni %1,EBX
                %assign %$EBX %$uses
                Push    RBX
            %elifidni %1,ESI
                %assign %$ESI %$uses
                Push    RSI
            %elifidni %1,EDI
                %assign %$EDI %$uses
                Push    RDI
            %else
                %error  "USES only accepts EBX, ECX, EDX, ESI, EDI, or ALL"
            %endif

            %rotate 1
            %assign %$uses %$uses+1
        %endrep
    %endif

%endmacro


;===================================================================================================
;End Procedure Definition (see x86.inc ENDP for full doc)
;
;Win64 is caller-cleanup, so unlike x86/STDCALL, Ret never takes a stack-size operand here.

%macro ENDP 0
    %$Done:

    %assign %$i 4
    %rep 5
        %ifdef %$ECX
            %if %$ECX==%$i
                Pop     RCX
            %endif
        %endif

        %ifdef %$EDX
            %if %$EDX==%$i
                Pop     RDX
            %endif
        %endif

        %ifdef %$EBX
            %if %$EBX==%$i
                Pop     RBX
            %endif
        %endif

        %ifdef %$ESI
            %if %$ESI==%$i
                Pop     RSI
            %endif
        %endif

        %ifdef %$EDI
            %if %$EDI==%$i
                Pop     RDI
            %endif
        %endif

        %assign %$i %$i-1
    %endrep

    %ifdef %$paramsize
        Leave
    %endif
    Ret

    %pop
%endmacro
