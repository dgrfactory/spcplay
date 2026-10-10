;===================================================================================================
;Program:    x64 (Win64) Backend Macros for NASM
;Platform:   x86_64 / Microsoft x64 calling convention
;
;x64 counterpart to x86.inc, selected by macro.inc when WIN64 is defined.  Implements the same
; macro interface (PROC/ENDP/USES/PUBLIC/Call/RetN/LOCALS, plus the pointer aliases PAX/PBX/.../
; PTRSIZE/resPTR) so shared code in APU.asm/DSP.asm/SPC700.asm does not need to know which
; architecture it is built for.
;
;Calling convention notes:
;   - Two conventions live in this file, and which one to use depends on who is calling:
;       * EXPROC/ExCall/ExCallArg: the real Microsoft x64 convention (RCX/RDX/R8/R9, 32-byte
;         shadow space, caller-cleans-stack, 16-byte alignment at each CALL).  Use it only for the
;         DEF-exported entry points something outside this DLL calls, and for calling a genuinely
;         external function pointer (a frontend-registered callback).
;       * PROC/Call/CallArg: an internal-only convention that passes every argument on the stack,
;         the same way the x86 backend does.  Use it for everything else.  The reason a second
;         convention exists: marshalling arguments into RCX/RDX/R8/R9 clobbers them in the
;         CALLER's context before the callee's USES-protected prologue runs, silently breaking
;         code that assumes the x86 stdcall property that PCX/PDX/etc. survive a call unless the
;         callee's own body touches them.
;   - EXPROC homes its incoming register arguments (RCX/RDX/R8/R9) into the caller-provided shadow
;     space at [RBP+16]/[RBP+24]/[RBP+32]/[RBP+40], while PROC's arguments are already at those same
;     offsets since Call pushed them there directly.  Either way, arguments 5 and up are read
;     straight from the stack slots the caller placed them in ([RBP+48], [RBP+56], ...).  So body
;     code that reads a parameter as '[pc]', '[a]', etc. is unchanged from the x86 version, since
;     only the offsets differ, and that difference is hidden behind the %define generated here.
;   - Per the Windows x64 ABI, small (byte/word) typed arguments still occupy a full register or
;     stack slot with the upper bits unspecified.  Body code must keep reading parameters at their
;     true width (byte/word/dword), and never widen a byte/word parameter read to a qword.
;   - Both Call and ExCall stage every argument into memory before touching any register the
;     marshalling itself needs, so an argument expression may safely reference any register,
;     including one another argument also writes to.
;
;                                                   Copyright (C) 2026 degrade-factory
;
;List of users and dates who/when modified this file:
;   - degrade-factory in 2026-10-09
;===================================================================================================

%define ARCH_BITS   64

DEFAULT REL                                                                     ;RIP-relative [mem] addressing (position-independent,
                                                                                ; matches normal Windows x64 DLL builds)

;===================================================================================================
;Pointer-width register aliases
;
;Use these only where a register genuinely holds a pointer.  Registers used for plain 32-bit
; arithmetic (sample counts, offsets, loop counters, etc.) should keep using EAX/EBX/... directly.
; Writing a 32-bit sub-register zero-extends the full 64-bit register, so mixing PAX and EAX on the
; same physical register across a routine is safe.

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
;A bare 'Mov reg,label' assembles as a 10-byte absolute 64-bit immediate load, which needs a base
; relocation and defeats ASLR-friendly position-independent code.  Use RIP-relative LEA instead.
;
;Params:
;   Destination register, label (or label expression)

%macro LoadPtr 2
    LEA     %1,[%2]
%endmacro


;===================================================================================================
;Push/Pop All General-Purpose Registers
;
;PUSHAD/POPAD (opcodes 60h/61h) are not encodable in 64-bit mode, so this pushes/pops the seven
; pointer-width aliases individually instead.  PUSHAD also saves the pre-push ESP, but nothing in
; this codebase reads that slot back, so it is dropped here rather than emulated.  R8-R15 are left
; out, since nothing in this port's calling convention needs them preserved across a PushAD/PopAD
; span.

%macro PushAD 0
    Push    PAX,PCX,PDX,PBX,PBP,PSI,PDI
%endmacro

%macro PopAD 0
    Pop     PDI,PSI,PBP,PBX,PDX,PCX,PAX
%endmacro


;===================================================================================================
;Store/Load a Value at a Compile-Time-Constant Label, Indexed
;
;x64's RIP-relative addressing cannot take an SIB index register, so combining a compile-time
; label's address with a runtime index needs a real base register, unlike x86, which folds the
; label straight into the instruction's displacement (see x86.inc).  Earlier in this port, call
; sites picked whichever register looked "free" for this and were wrong more than once: the
; register turned out to already hold something a caller elsewhere in the call graph needed
; (SPC700.asm's PC, its RAM pointer, its X register, ...).  These macros push/pop the scratch
; register around the single instruction that needs it, so nothing at the call site has to reason
; about whether it is free, and it always survives, at the cost of a push/pop pair per use.
;
;Params:
;   op    - instruction mnemonic, optionally with a size specifier (e.g. "Mov" or "Mov byte")
;   label - compile-time-constant symbol being indexed
;   index - index expression (a register, "reg*scale", or 0 for no index)
;   val   - the other operand
;   reg   - (optional) scratch register to use.  Must not also be used as the index or val operand
;           in the same call.  If omitted, defaults to R10 with no Push/Pop, since R8-R15 never
;           hold a live value across this port's internal call boundaries (see PushAD), and R10
;           joins R11, already ExCall's own indirect-call-target scratch, as the pair these macros
;           own, leaving R8 and R9 free for a future hand-written scratch use.  When val is
;           AH/BH/CH/DH, or reg is explicitly passed as something other than R10, this falls back
;           to PDI with Push/Pop instead, since a REX prefix (forced by R8-R15) cannot encode a
;           high-byte register.

;IdxSt: op [label+index],val   (memory is the destination: a "store")
%macro IdxSt 4-5 0
    %push   IdxSt
    %ifidni %5,0
        %ifidni %4,AH
            %define %$R PDI
        %elifidni %4,BH
            %define %$R PDI
        %elifidni %4,CH
            %define %$R PDI
        %elifidni %4,DH
            %define %$R PDI
        %else
            %define %$R R10
        %endif
    %else
        %define %$R %5
    %endif
    %ifidni %$R,R10
        LoadPtr %$R,%2
        %1      [%$R+%3],%4
    %else
        Push    %$R
        LoadPtr %$R,%2
        %1      [%$R+%3],%4
        Pop     %$R
    %endif
    %pop
%endmacro

;IdxLd: op val,[label+index]   (memory is the source, a "load", val is usually a register)
;If val IS the scratch register, the pushed copy is discarded (stack pointer adjusted) instead of
; popped, since popping would overwrite the value just loaded.  Not needed on the R10 path, since
; nothing was pushed.
%macro IdxLd 4-5 0
    %push   IdxLd
    %ifidni %5,0
        %ifidni %2,AH
            %define %$R PDI
        %elifidni %2,BH
            %define %$R PDI
        %elifidni %2,CH
            %define %$R PDI
        %elifidni %2,DH
            %define %$R PDI
        %else
            %define %$R R10
        %endif
    %else
        %define %$R %5
    %endif
    %ifidni %$R,R10
        LoadPtr %$R,%3
        %1      %2,[%$R+%4]
    %else
        Push    %$R
        LoadPtr %$R,%3
        %1      %2,[%$R+%4]
        %ifnidni %2,%$R
            Pop     %$R
        %else
            Add     PSP,PTRSIZE
        %endif
    %endif
    %pop
%endmacro

;IdxLdX: op val,size [label+index]  memory is the source, a "load", for ops like MovZX/MovSX where
; val and the memory operand's size differ, e.g. a byte in memory zero-extended into a 32-bit
; register.  IdxLd's plain "%1 %2,[...]" template has nowhere to put the size keyword, so this is a
; separate macro for that shape, otherwise identical to IdxLd.  Pass val as a P-alias (e.g. PDI,
; not EDI) if it might collide with the scratch register; a bare 32-bit name would go undetected by
; %ifnidni below, since it is spelled differently from the pointer-width alias for the same register.
%macro IdxLdX 5-6 0
    %push   IdxLdX
    %ifidni %6,0
        %ifidni %2,AH
            %define %$R PDI
        %elifidni %2,BH
            %define %$R PDI
        %elifidni %2,CH
            %define %$R PDI
        %elifidni %2,DH
            %define %$R PDI
        %else
            %define %$R R10
        %endif
    %else
        %define %$R %6
    %endif
    %ifidni %$R,R10
        LoadPtr %$R,%4
        %1      %2,%3 [%$R+%5]
    %else
        Push    %$R
        LoadPtr %$R,%4
        %1      %2,%3 [%$R+%5]
        %ifnidni %2,%$R
            Pop     %$R
        %else
            Add     PSP,PTRSIZE
        %endif
    %endif
    %pop
%endmacro


;===================================================================================================
;Combine a Register With a Compile-Time-Constant Label's Address (no memory operand)
;
;This port does not always need a label's address as a memory operand in IdxSt/IdxLd's
; '[reg+index]' shape.  Some places just add, subtract, or compare it against a register's own
; value instead (e.g. turning a pointer into an index and back).  x86 can embed a label's address
; as a plain 32-bit immediate operand for this, but x64 cannot, since ADD/SUB/etc. to a 64-bit
; register only take a sign-extended imm32, so a register has to carry it, using the same reasoning
; and the same push/pop-scratch-register solution as IdxSt/IdxLd above.
;
;Params:
;   op    - instruction mnemonic (Add/Sub/And/Or/Cmp/...)
;   reg   - the register being combined with label's address
;   label - compile-time-constant symbol
;   reg2  - (optional) scratch register to use.  Must not be the same register as reg.  reg and
;           reg2 are two direct register operands to the same op, so op's encoding requires them
;           to already be the same width, which rules out reg ever being AH/BH/CH/DH (an 8-bit
;           register can never match reg2's pointer width).  There is therefore no REX conflict to
;           guard against, unlike IdxSt: an omitted reg2 always defaults to R10 with no Push/Pop
;           (see IdxSt's note above on why R10, not R8/R9).
;
;LblOp: op reg,label
%macro LblOp 3-4 0
    %push   LblOp
    %ifidni %4,0
        %define %$R R10
    %else
        %define %$R %4
    %endif
    %ifidni %$R,R10
        LoadPtr %$R,%3
        %1      %2,%$R
    %else
        Push    %$R
        LoadPtr %$R,%3
        %1      %2,%$R
        Pop     %$R
    %endif
    %pop
%endmacro


;===================================================================================================
;Store a Compile-Time-Constant Label's Address Into a Plain Memory Location
;
;x86 can 'Mov dword [mem],label' directly (a label's address is a 32-bit immediate).  x64 has no
; MOV m64,imm64 form, only reg64,imm64, so storing a full 64-bit address to memory always needs a
; register in between.  This is the same reasoning as IdxSt/IdxLd/LblOp above, applied here to the
; simplest case: no index, with dest and source each just one plain location.
;
;Params:
;   dest  - the (non-indexed) memory location to store into, a resPTR-sized variable
;   label - compile-time-constant symbol whose address is stored
;   reg   - (optional) scratch register to use.  Unlike IdxSt/LblOp, reg never sits alongside
;           another register operand in the generated instruction, so there is no AH/BH/CH/DH
;           conflict to guard against: an omitted reg always defaults to R10 with no Push/Pop
;           (see IdxSt's note above on why R10, not R8/R9).
;
;LblSt: Mov [dest],label
%macro LblSt 2-3 0
    %push   LblSt
    %ifidni %3,0
        %define %$R R10
    %else
        %define %$R %3
    %endif
    %ifidni %$R,R10
        LoadPtr %$R,%2
        Mov     [%1],%$R
    %else
        Push    %$R
        LoadPtr %$R,%2
        Mov     [%1],%$R
        Pop     %$R
    %endif
    %pop
%endmacro


;===================================================================================================
;A Unary Instruction on a Compile-Time-Constant Label, Indexed
;
;This follows the same reasoning as IdxSt/IdxLd, for instructions with only one explicit operand
; (FStP/FILd/FIMul/Div/Inc/...) that do not fit either macro's two-operand shape.
;
;Params:
;   op    - instruction mnemonic, optionally with a size specifier (e.g. "FILd dword")
;   label - compile-time-constant symbol being indexed
;   index - index expression (a register, "reg*scale", or 0 for no index)
;   reg   - (optional) scratch register to use.  Must not also be used as the index.  Like LblSt,
;           reg never sits alongside another register operand here, so an omitted reg always
;           defaults to R10 with no Push/Pop (see IdxSt's note above on why R10, not R8/R9).
;
;IdxUn: op [label+index]   (a single memory operand)
%macro IdxUn 3-4 0
    %push   IdxUn
    %ifidni %4,0
        %define %$R R10
    %else
        %define %$R %4
    %endif
    %ifidni %$R,R10
        LoadPtr %$R,%2
        %1      [%$R+%3]
    %else
        Push    %$R
        LoadPtr %$R,%2
        %1      [%$R+%3]
        Pop     %$R
    %endif
    %pop
%endmacro


;===================================================================================================
;Declare a Table of Pointers/Code Addresses (see x86.inc PTRTAB for full doc)
;
;Unlike a code-embedded 'Mov reg,label' (see LoadPtr above), a DQ table entry is exactly how x64
; pointer/vtable-style tables are normally built: the loader's base relocation table patches each
; 8-byte slot at load time, so this stays correct under ASLR without RIP-relative tricks.
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
;Align RSP Around A Raw, Non-ExCall Call Into Genuinely External Code (begin/end pair)
;
;For the rare hand-rolled callback invocation that passes arguments via its own private,
; pushed-on-the-stack protocol instead of the real Win64 ABI's RCX/RDX/R8/R9 (pTrace/pDebug; see
; DSP.asm's DSPIn and SPC700.asm's SPCBreak), not through ExCall.  Such a callback can only be a
; hand-written external stub to begin with, since MSVC has no x64 equivalent of a 'naked' function
; that could read arguments straight off the stack this way, so, unlike ExCall's genuine Win64 ABI
; call below, no 32-byte shadow space is reserved here: the whole point of this private protocol is
; that the callee does not expect a compiler-generated prologue to begin with.  RSP's 16-byte
; alignment is still not optional, though, for the same reason as ExCall: whatever this callback
; goes on to call itself, even indirectly, several frames deep, can still be genuine ABI-compliant
; code that assumes it.
;
;Bracket the existing Push/Call/Pop sequence with this pair, unchanged in between: AlignRawCallBegin
; at the very start, before the first Push, AlignRawCallEnd right after the last matching Pop.  The
; padding this inserts sits below (pushed before) every existing Push, so it never shifts any offset
; the callee's documented protocol, or this code's own matching Pops, already rely on.
;
;RSP's 16-byte alignment cannot be assumed on entry to either macro below.  This may be reached
; through one or more internal Call frames (see that macro's own doc), which push arguments and a
; return address with no alignment padding of their own, since nothing else in this codebase needs
; 16-byte alignment.  R12 is saved and repurposed to remember the exact pre-call RSP (it is
; otherwise unused anywhere in this codebase, so nothing this brackets can alias it), so restoring
; RSP from R12 in AlignRawCallEnd always undoes everything done in between in a single move,
; regardless of what that turns out to be.
;
;'And RSP,-16' alone only lands on a 16-byte boundary right here, not necessarily at the actual Call
; a few instructions later: every Push in between (the bracketed protocol's own arguments) moves RSP
; by another 8 bytes each, so an ODD number of them (DSP.asm's DSPIn: 5) flips the alignment this
; macro just fixed right back to misaligned by the time Call runs, while an EVEN number (SPC700.asm's
; SPCBreak: 6) happens to leave it correct by coincidence, not by design.  The optional parameter is
; the exact byte count of every Push between this macro and the Call (e.g. 5*PTRSIZE for DSPIn's
; five one-register Pushes), so this macro can pre-compensate: only when that count is not itself a
; multiple of 16 does an extra 8-byte pad get added here, so that subtracting it back out during the
; bracketed Pushes always lands exactly on a 16-byte boundary at the real Call, not just at this
; macro's own call site.  Defaults to 0 (already a multiple of 16, so no pad), matching ExCall's own
; use of this macro below, which pushes nothing of its own before its Call: its shadow-space/stack-
; args Sub is always a compile-time multiple of 16 by construction, so it needs no compensation
; either.

%macro AlignRawCallBegin 0-1 0
    Push    R12
    Mov     R12,RSP
    And     RSP,-16
    %if (%1 % 16) != 0
        Sub     RSP,8
    %endif
%endmacro

%macro AlignRawCallEnd 0
    Mov     RSP,R12
    Pop     R12
%endmacro


;===================================================================================================
;Move One ExCall Argument Into Its Destination Register
;
;A plain value (32-bit register or memory) is moved 32-bit-wide, which zero-extends the full 64-bit
; register, matching what most call sites pass and the x86 backend's behavior.  A pointer already
; sitting in a PAX/PBX/... alias register must instead be moved 64-bit wide: 'Mov ECX,RDI'
; (destination narrower than a 64-bit source register) is not encodable, and would silently truncate
; the pointer's upper half anyway.  So, to pass a pointer to ExCall, load it into a PAX/PBX/...
; register at the call site first, since a bare '[label]' is not enough: ExCall has no way to know
; whether that memory holds a 4-byte or 8-byte value.
;
;A negative immediate (e.g. '-1', this codebase's usual pointer-typed 'leave unchanged' sentinel)
; moves 64-bit wide instead, sign-extending it, so a callee reading it back through a P-alias and
; comparing against the same '-1' sees a match, exactly as it would on x86, where PAX is EAX.  A
; non-negative immediate still moves 32-bit wide: zero-extension and sign-extension agree for every
; value up to 07FFFFFFFh, so this changes nothing for the common case of a plain unsigned constant.
;
;Params:
;   64-bit destination register, 32-bit destination register, source token

%macro ExCallArg 3
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
        %ifnum %3
            %if %3 < 0
                Mov     %1,%3
            %else
                Mov     %2,%3
            %endif
        %else
            Mov     %2,%3
        %endif
    %endif
%endmacro


;===================================================================================================
;ExCall Procedure (Microsoft x64 calling convention)
;
;Use this only to call something that must honor the real Windows x64 ABI: a genuinely external
; function pointer (e.g. the frontend's registered apuCbFunc/pDebug/pTraceFunc callbacks).  For
; every other call within this codebase, use the plain (internal) Call below instead.  See its doc
; for why a second convention exists at all.
;
;Params:
;   Function name followed by up to 8 arguments.  The first 4 are passed in RCX/RDX/R8/R9.  Any
;   further arguments go on the stack, above a 32-byte shadow space, 16-byte aligned, and are
;   cleaned up by the caller after the call returns (Win64 is caller-cleanup, so unlike the x86
;   backend this needs no STDCALL/CDECL distinction).  See ExCallArg above for how pointer
;   arguments are handled.  See AlignRawCallBegin above for why RSP cannot be assumed 16-byte
;   aligned on entry, and for R12's role in fixing that up around the call below.

%macro ExCall 2-*
    %if %0 > 9
        %error  "ExCall :: Procedures cannot have more than 8 arguments"
    %endif

    ;Own context for %$n/%$stackn/%$framesz below.
    ; ExCall can be invoked from bare (non-PROC) code, e.g. SPC700.asm's jump-table opcode handlers,
    ; so it cannot rely on an enclosing PROC's %push context existing.
    %push ExCallCtx

    %assign %$n %0-1                                                            ;Number of real arguments
    %assign %$stackn 0
    %if %$n > 4
        %assign %$stackn %$n-4
    %endif

    %assign %$framesz 32+(%$stackn*8)                                           ;Shadow space + stack args
    %if (%$framesz % 16) != 0                                                   ;Keep RSP 16-byte aligned at CALL
        %assign %$framesz %$framesz+8
    %endif

    ;NOTE: See AlignRawCallBegin above: RSP cannot be assumed 16-byte aligned here, since ExCall may
    ; be reached through one or more internal Call frames.  Restoring RSP via AlignRawCallEnd later
    ; undoes both this alignment pad and the shadow-space/stack-args frame allocated below in a
    ; single move, rather than reversing each separately.
    AlignRawCallBegin

    Sub     RSP,%$framesz

    ;NOTE: An indirect call target (e.g. 'ExCall PCX,...', calling through a register) can itself
    ; alias one of the argument destination registers: 'ExCall PCX,dword CBE_REQBP,...' calls
    ; through RCX while also passing arg 1 destined for RCX, so the target must be read out of RCX
    ; into a register nothing below ever writes (R11, since R10 is already the argument-staging
    ; scratch), before any argument setup begins, or the call would jump through its own clobbered
    ; first argument instead of the real target.  A label target (the common case) needs no such
    ; staging.
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

    ;NOTE: Stage every argument's source value into memory before touching RAX/RCX/RDX/R8/R9.
    ; Otherwise an earlier-assigned register (e.g. RDX for arg 2, or RAX used as scratch to stage
    ; another arg) could also be the literal source token of a later-staged argument (e.g. "PDX" for
    ; arg 1, or "EAX" for some other arg): assigning straight into the final registers in a fixed
    ; order would let one argument's write clobber another's source before it is read, and using RAX
    ; itself as staging scratch has the same problem if some argument's source is literally EAX/PAX.
    ; R10 has no x86 counterpart, so it is never a P-alias/index/val operand anywhere in the shared
    ; codebase (see IdxSt/IdxLd's note on R8-R15), making it a scratch register no source token can
    ; ever alias.
    %if %$n >= 8
        ExCallArg R10,R10D,%9
        Mov     [RSP+32+24],R10
    %endif
    %if %$n >= 7
        ExCallArg R10,R10D,%8
        Mov     [RSP+32+16],R10
    %endif
    %if %$n >= 6
        ExCallArg R10,R10D,%7
        Mov     [RSP+32+8],R10
    %endif
    %if %$n >= 5
        ExCallArg R10,R10D,%6
        Mov     [RSP+32+0],R10
    %endif
    %if %$n >= 4
        ExCallArg R10,R10D,%5
        Mov     [RSP+24],R10
    %endif
    %if %$n >= 3
        ExCallArg R10,R10D,%4
        Mov     [RSP+16],R10
    %endif
    %if %$n >= 2
        ExCallArg R10,R10D,%3
        Mov     [RSP+8],R10
    %endif
    %if %$n >= 1
        ExCallArg R10,R10D,%2
        Mov     [RSP+0],R10
    %endif

    %if %$n >= 1
        Mov     RCX,[RSP+0]
    %endif
    %if %$n >= 2
        Mov     RDX,[RSP+8]
    %endif
    %if %$n >= 3
        Mov     R8,[RSP+16]
    %endif
    %if %$n >= 4
        Mov     R9,[RSP+24]
    %endif

    Call    %$target

    AlignRawCallEnd
    %pop
%endmacro


;===================================================================================================
;Move One (Internal) Call Argument Onto the Stack
;
;Unlike ExCallArg, which loads into a fixed register, this pushes straight onto the
; stack, for reasons the internal Call macro below explains.  A pointer sitting in a
; PAX/PBX/... alias register is pushed verbatim, already 8 bytes wide.  A plain register
; or memory source is first zero-extended into the scratch register pair, so a 4-byte
; source (e.g. a plain dword variable) is never over-read as 8 bytes by a bare 'Push
; qword'.
;
;A negative immediate (e.g. '-1', this codebase's usual pointer-typed 'leave unchanged'
; sentinel) is sign-extended into the scratch register instead, for the same reason
; ExCallArg above sign-extends one: a callee reading the parameter back through a P-alias
; and comparing against the same '-1' must see a match, as it would on x86.  A
; non-negative immediate still zero-extends, unchanged from before, since zero-extension
; and sign-extension agree for every value up to 07FFFFFFFh.
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
        %ifnum %3
            %if %3 < 0
                Mov     %1,%3
            %else
                Mov     %2,%3
            %endif
        %else
            Mov     %2,%3
        %endif
        Push    %1
    %endif
%endmacro


;===================================================================================================
;Call Procedure (internal convention)
;
;Microsoft x64's calling convention passes the first 4 arguments in RCX/RDX/R8/R9, registers this
; codebase's P-aliases treat as callee-saved-unless-documented, since PCX/PDX survive a call on x86,
; where stdcall arguments go on the stack, unless the callee's own USES-protected body touches them.
; On x64, just setting up a register-passed argument list clobbers RCX/RDX/R8/R9 in the caller's own
; context before the callee's prologue and its USES ever run, so USES can only protect what has
; already been overwritten with argument values, not the caller's original contents.  A real bug
; from exactly this: SPCTimers keeps its EDX live across 'Call CatchUp', a bare 0-arg call with no
; marshalling issue by itself, expecting it to survive as it would on x86, but CatchUp's own body
; calls 'Call EmuDSP,PDX,EAX', silently clobbering RDX out from under the caller three frames up.
;
;So, every PROC-to-PROC call within this codebase, i.e. everything except a genuinely external
; function pointer (see ExCall above), goes through this Call instead, which passes arguments on
; the stack the same way the x86 backend does (see x86.inc's Call), not through RCX/RDX/R8/R9.
; PCX/PDX/PBX/PSI/PDI/PBP then behave exactly as on x86: untouched by a call's argument setup,
; destroyed only if the callee's own body, and its USES if any, says so.
;
;Params:
;   Function name followed by up to 8 arguments, pushed right-to-left onto the stack (caller
;   cleans up afterward, since there is no external ABI to match here, so no STDCALL/CDECL
;   distinction is needed).  See CallArg above for how pointer arguments are handled (pushed
;   as-is, anything else is zero-extended into a scratch register first, since a 4-byte source,
;   e.g. a plain dword variable, must never be over-read as 8 bytes by a bare 'Push qword').

%macro Call 2-*
    %if %0 > 9
        %error  "Call :: Procedures cannot have more than 8 arguments"
    %endif

    %rep %0-1
        %rotate -1
        CallArg R10,R10D,%1
    %endrep
    %rotate -1

    Call    %1

    %assign %%argsize (%0*PTRSIZE)-PTRSIZE
    %if %%argsize > 0
        Add     RSP,%%argsize
    %endif
%endmacro


;===================================================================================================
;Set EAX to a Return Value, Preferring 'XOr EAX,EAX' for a Literal 0
;
;'XOr EAX,EAX' is 2 bytes versus 5 for 'Mov EAX,0', and breaks the register's dependency chain on
; some microarchitectures, so RetN/RetZ/RetNZ below use this instead of a plain 'Mov EAX,%1'.  Only
; a literal 0 known at assemble time qualifies: an EQU name or expression that merely evaluates to 0
; still falls through to 'Mov', since NASM's preprocessor cannot tell its value applies here.

%macro SetEAX 1
    %ifnum %1
        %if %1 == 0
            XOr     EAX,EAX
        %else
            Mov     EAX,%1
        %endif
    %else
        Mov     EAX,%1
    %endif
%endmacro


;===================================================================================================
;Conditional Move (architecture-neutral wrapper)
;
;This build's x64 CPU target (see this file's own 'CPU X64') supports CMOVcc natively, so this is
; just a thin passthrough.  CMOVcc needs at least a Pentium Pro, which predates the x86 build's
; 'CPU 386' target, so x86.inc emulates the same effect with a short branch instead.  Kept as a
; single architecture-neutral spelling so shared code (APU.asm/DSP.asm/SPC700.asm) never needs its
; own %ifdef WIN64 just to pick a branch or a real CMOVcc.
;
;Params:
;   condition suffix (e.g. 'B', 'A', 'NE', 'NZ', matching a real CMOVcc mnemonic), destination
;   register, source register or memory operand

%macro CMovX 3
    CMov%1  %2,%3
%endmacro


;===================================================================================================
;Return from Procedure (see x86.inc RetN for full doc)
;
;NOTE: this sets EAX (zero-extending RAX), matching the vast majority of call sites that return a
; plain integer.  A proc that must return a pointer should set PAX (RAX) explicitly in the body
; and fall through to ENDP/RetN with no argument, rather than passing a 64-bit value through here.

%macro RetN 0-1
    %if %0
        SetEAX  %1
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
;
;The optional value is only moved into EAX when the condition is actually taken, unlike a naive
; 'Mov EAX,value' placed before the jump, which would clobber EAX on the not-taken path too.

%macro RetZ 0-1
    %if %0
        JNZ     %%Skip
        SetEAX  %1
        Jmp     %$Done
        %%Skip:
    %else
        JZ      %$Done
    %endif
%endmacro


%macro RetNZ 0-1
    %if %0
        JZ      %%Skip
        SetEAX  %1
        Jmp     %$Done
        %%Skip:
    %else
        JNZ     %$Done
    %endif
%endmacro


;===================================================================================================
;Publicly Declare a Label
;
;The Microsoft x64 ABI has a single calling convention: no leading underscore, no '@N' stack-size
; suffix (those are x86-only stdcall/cdecl artifacts).  STDCALL/CDECL are intentionally ignored
; here.

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
;Use this only for the small set of functions something outside this DLL actually calls directly:
; the ~29 names in SNESAPU.def, and nothing else.  Everything else, including a DEF-exported
; function's own internal recursion/helpers (e.g. EmuAPU calling itself, or CatchUp calling EmuDSP),
; should be a plain (internal) PROC instead, per PROC's own doc below.  A DEF-exported name that is
; also called from elsewhere in this codebase should be split in two: a thin EXPROC of that exact
; name that only re-homes its arguments and forwards via the internal Call to a plain PROC of the
; same name plus an 'I' suffix (e.g. EXPROC EmuAPU forwards to PROC EmuAPUI), so every internal
; caller can Call the fast/internal-convention 'EmuAPUI' directly, instead of paying for (and
; risking) the ABI bridge on every recursive call.
;
;Params:
;   Procedure name followed by a list of arguments (up to 8).  Arguments 1-4 arrive in
;   RCX/RDX/R8/R9 and are homed into the shadow space the caller reserved.  Arguments 5-8 are read
;   directly from the stack slots the caller placed them in.

%macro EXPROC 1-*
    ALIGN   16                                                                  ;Align entry point on a cache line boundary
    %1:                                                                         ;Define procedure label

    %push PROC                                                                  ;Save context

    %if %0 > 9
        %error  "EXPROC :: Procedures cannot have more than 8 arguments"
    %endif

    ;NOTE: The x64 ABI treats the x87 control word as nonvolatile, so it is saved below the frame
    ; pointer and restored by ENDP, with 037Fh loaded in between (see x86.inc EXPROC for why not
    ; 'FInit').  The slot is 16 bytes to keep RSP aligned, and the frame is always created.
    Push    RBP                                                                 ;Create a frame pointer
    Mov     RBP,RSP
    Sub     RSP,16                                                              ;[RBP-8] = Frontend's FPU control word
    FNStCW  [RBP-8]                                                             ;[RBP-6] = Control word to run with
    Mov     word [RBP-6],037Fh
    FLdCW   [RBP-6]
    %assign %$fpuslot 16
    %assign %$paramsize 0

    %if %0 > 1                                                                  ;Does this procedure have any arguments?
        %assign %$paramsize (%0*8)-8                                            ;Save the size of the frame

        %if %0 >= 2                                                             ;Home register args / point at stack args
            %define %2  RBP+16
            Mov     [RBP+16],RCX

        %if %0 >= 3
            %define %3  RBP+24
            Mov     [RBP+24],RDX

        %if %0 >= 4
            %define %4  RBP+32
            Mov     [RBP+32],R8

        %if %0 >= 5
            %define %5  RBP+40
            Mov     [RBP+40],R9

        %if %0 >= 6
            %define %6  RBP+48                                                  ;Already on the stack, caller-provided

        %if %0 >= 7
            %define %7  RBP+56

        %if %0 >= 8
            %define %8  RBP+64

        %if %0 >= 9
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
;Define Procedure (internal convention, see the internal Call macro above for the full rationale)
;
;Params:
;   Procedure name followed by a list of arguments (up to 8), all read directly from the stack
;   slots the internal Call macro pushed them into, with no RCX/RDX/R8/R9 homing, so nothing here
;   overwrites those registers on entry.

%macro PROC 1-*
    ALIGN   16                                                                  ;Align entry point on a cache line boundary
    %1:                                                                         ;Define procedure label

    %push PROC                                                                  ;Save context

    %if %0 > 9
        %error  "PROC :: Procedures cannot have more than 8 arguments"
    %endif

    %if %0 > 1                                                                  ;Does this procedure have any arguments?
        Push    RBP                                                             ;Create a frame pointer
        Mov     RBP,RSP

        %assign %$paramsize (%0*8)-8                                            ;Save the size of the frame

        %if %0 >= 2                                                             ;Point at the stack slots Call already pushed
            %define %2  RBP+16

        %if %0 >= 3
            %define %3  RBP+24

        %if %0 >= 4
            %define %4  RBP+32

        %if %0 >= 5
            %define %5  RBP+40

        %if %0 >= 6
            %define %6  RBP+48

        %if %0 >= 7
            %define %7  RBP+56

        %if %0 >= 8
            %define %8  RBP+64

        %if %0 >= 9
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
;Each local is a native pointer-sized (8-byte) slot.  The total is padded to a multiple of 16
; bytes so RSP stays 16-byte aligned across any Call made later in the procedure.

%macro LOCALS 1-8
    %assign %$localsize %0*8

    %ifndef %$paramsize
        %assign %$paramsize 0
        Push    RBP
        Mov     RBP,RSP
    %endif

    %if %0 > 8
        %error  "LOCALS :: Procedures cannot have more than 8 local variables"
    %endif

    %ifdef %$fpuslot                                                            ;Place the locals below EXPROC's FPU slot
        %assign %$lbase %$fpuslot
    %else
        %assign %$lbase 0
    %endif

    %if %0 >= 1
        %xdefine %1 RBP-(%$lbase+8)

    %if %0 >= 2
        %xdefine %2 RBP-(%$lbase+16)

    %if %0 >= 3
        %xdefine %3 RBP-(%$lbase+24)

    %if %0 >= 4
        %xdefine %4 RBP-(%$lbase+32)

    %if %0 >= 5
        %xdefine %5 RBP-(%$lbase+40)

    %if %0 >= 6
        %xdefine %6 RBP-(%$lbase+48)

    %if %0 >= 7
        %xdefine %7 RBP-(%$lbase+56)

    %if %0 >= 8
        %xdefine %8 RBP-(%$lbase+64)

    %endif
    %endif
    %endif
    %endif
    %endif
    %endif
    %endif
    %endif

    %if (%$localsize % 16) != 0
        %assign %$localsize %$localsize+8
    %endif

    Sub     RSP,%$localsize
%endmacro


;===================================================================================================
;Registers Used by Procedure (see x86.inc USES for full doc)
;
;Params:
;   Same token names as the x86 backend (EBX/ECX/EDX/ESI/EDI, or ALL).  Shared code does not need
;   to change.  This backend pushes/pops the full 64-bit register underneath each name.

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

    %ifdef %$fpuslot                                                            ;Restore the frontend's FPU control word saved by
        FNClEx                                                                  ; EXPROC, clearing the masked exception flags
        FLdCW   [RBP-8]                                                         ; first so the frontend does not see them
    %endif

    %assign %$i 4
    %rep 5
        %ifdef %$ECX
            %if %$ECX == %$i
                Pop     RCX
            %endif
        %endif

        %ifdef %$EDX
            %if %$EDX == %$i
                Pop     RDX
            %endif
        %endif

        %ifdef %$EBX
            %if %$EBX == %$i
                Pop     RBX
            %endif
        %endif

        %ifdef %$ESI
            %if %$ESI == %$i
                Pop     RSI
            %endif
        %endif

        %ifdef %$EDI
            %if %$EDI == %$i
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
