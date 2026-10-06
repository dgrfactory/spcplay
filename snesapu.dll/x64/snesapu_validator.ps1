# ==================================================================================================
# Program:    snesapu_validator.ps1
# Purpose:    static lint for leftover x86-only pointer-width notation
# Platform:   any (PowerShell 5.1+, no external dependencies)
#
# Catches a bug class this x64 port has hit more than once: code touching a pointer
# variable (one declared 'resPTR' or 'PTRTAB' in APU.asm, DSP.asm, or SPC700.asm) through a
# bare 32-bit E-register or an explicit dword/word/byte memory operand, instead of a
# P-alias register (PAX, PBX, PCX, PDX, PSI, PDI, PBP, PSP) or the 'PTRKW' size keyword.  On
# x86 both forms compile identically, so a stray 'Mov EAX,[pDebug]' looks harmless there.
# On x64 it silently truncates a 64-bit address to 32 bits, surfacing only as a distant
# crash or corrupted state.
#
# This script does not understand assembly semantics, and does not track which register
# currently holds a pointer value the way a human reviewer, or the P-alias audit done
# earlier in this port, does.  It only catches the syntactically-detectable, high-confidence
# patterns below, covering every real bug of this shape found during the port so far:
#
#   1. 'LoadPtr <reg>,<label>' where <reg> is not a P-alias.  LoadPtr's job is to produce a genuine
#      address in a register (LEA on x64, MOV on x86), so its destination must always be
#      pointer-width, regardless of which label the address is for.
#   2. Any '[<label>]' reference, with or without a +offset, where <label> is a known 'resPTR' or
#      'PTRTAB' pointer variable, on a line that also uses a bare E-register (EAX, EBX, ECX, EDX,
#      ESI, EDI, EBP, ESP) or an explicit dword/word/byte size override right before the bracket.
#      The correct form is a P-alias register, or 'PTRKW' for an explicit size.
#   3. A raw '[label+register]' bracket written directly, instead of through IdxSt, IdxLd, IdxLdX,
#      or IdxUn, since x64's RIP-relative addressing has no SIB byte and cannot combine a
#      compile-time label with an index register the way x86's addressing can.  Confirmed
#      empirically that NASM does not reject this at build time: 'mov al,[someLabel+ecx]' assembles
#      cleanly under 'DEFAULT REL'/win64 but silently falls back to a 32-bit address-size override
#      plus an 'IMAGE_REL_AMD64_ADDR32' relocation, the same 4GB-load-address failure this port has
#      already hit and fixed more than once.  Flags any bracket combining a real memory label
#      (colon-terminated, or declared via resb/resw/resd/resq/resPTR/PTRTAB/db/dw/dd/dq/times) with
#      a register or SPC700.asm register alias, but not one combined only with a number or an EQU
#      constant, since those fold into the instruction as a plain immediate displacement.
#   4. Check 3's own low-confidence fallback: a '[...]' bracket pairing a known register with an
#      identifier this script cannot classify at all (not a number, register, memory label, known
#      EQU constant, or STRUC member).  $EquNames and $StrucMembers (above) are collected from
#      every scanned file's own %include'd .inc files too, e.g. DSP.inc's DSPRAM/VoiceMix, precisely
#      so the common base-register-plus-struct-offset idiom does not swamp this check.  What is left
#      after those exclusions is exactly Check 3's blind spot: since Pass 1 only scans declarations
#      this script knows how to recognize, a real memory label declared some other way would
#      otherwise be silently missed rather than flagged.  Reported separately from Check 3, and
#      clearly marked low-confidence, since most hits will still be an EQU or STRUC member this
#      script's own patterns did not recognize as one, rather than a genuinely missed label.
#   5. A raw 'Mov'/'Add'/'Sub'/'And'/'Or'/'Cmp' whose second operand is a known memory label used
#      bare (not inside '[...]'), written directly instead of through LoadPtr (a register
#      destination), LblOp (Add/Sub/And/Or/Cmp with a register destination), or LblSt (Mov into an
#      unindexed, bracketed destination).  See LoadPtr's own doc comment in x64.inc: embedding a
#      label this way assembles as a 10-byte absolute-address immediate load needing a base
#      relocation, defeating ASLR-friendly position-independent code, the same failure mode Check 3
#      targets for indexed memory operands.
#   6. An IdxSt/IdxLd/IdxLdX/IdxUn/LblOp call that omits its optional trailing scratch-register
#      argument while also passing that same physical register as one of the call's other
#      arguments.  The macro pushes the scratch register (or, on the no-Push/Pop R10 path below,
#      simply clobbers it), overwrites it with the label's address, then uses it, so that other
#      argument's real value is already gone (or was never saved) by the time the instruction runs.
#      IdxSt/IdxLd/IdxLdX pick their default per call: R10, with no Push/Pop, unless their 'val'
#      argument is AH/BH/CH/DH, which forces PDI with Push/Pop instead, since an R8-R15 base would
#      make a REX prefix mandatory and REX cannot encode a high-byte register.  IdxUn and LblOp
#      have no 'val' operand of their own to force that fallback, so they always default to R10.
#      R10, not R8/R9, so R10 joins R11 (already ExCall's own indirect-call-target scratch) as the
#      pair these macros own, leaving R8/R9 free for a future hand-written scratch use without
#      silently colliding with these macros.  IdxLd and IdxLdX exempt their own 'val' argument from
#      this check, since loading straight into the scratch register is their documented,
#      intentional case, correctly handled by the macro itself either way (discarding the pushed
#      copy on the PDI path, or, on the R10 path, never pushing one to begin with).
#   7. An IdxSt call whose stored value (argument 4: op, label, index, val, optional scratch) is a
#      P-alias register, or an LblSt call whose destination (argument 1: dest, label, optional
#      scratch) receives a label's address via a P-alias scratch register, where that label is a
#      memory symbol this script has seen declared but not via 'resPTR'/'PTRTAB'.  This is the
#      mirror of Check 2: a P-alias is pointer-width, so storing one into a narrower field, or into
#      a raw struct-array base like DSP.inc's 'mix'/'dsp', overwrites the memory that follows it.
#      Confirmed real bug found this way: APU.asm:1403, 'IdxSt Mov,scr700lbl,PAX*4,PBX', wrote 8
#      bytes into a 4-byte 'scr700lbl' slot, corrupting the next entry, on x64 only.
#   8. The read-side mirror of Check 7: an IdxLd call (argument 2: op, val, label, index, optional
#      scratch) whose 'val' is a P-alias and whose 'op' is anything other than LEA, where 'label' is
#      known but not 'resPTR'/'PTRTAB'.  LEA is exempt, since it only computes an address and never
#      reads memory, so its destination is correctly pointer-width regardless of 'label'.  Any other
#      op reads memory at 'val''s width, so 'IdxLd Mov,PAX,someDwordArray,index' would read 8 bytes
#      from a 4-byte-per-element array, pulling in the next element or reading past the array's end.
#   9. A 'Call'/'ExCall' argument, in any position after the target, that is a bare '[label]'
#      referencing a known 'resPTR'/'PTRTAB' variable directly.  CallArg/ExCallArg (x64.inc) move a
#      plain register or memory source 32-bit wide, since they cannot tell from the token alone
#      whether that memory holds 4 or 8 bytes, so a bare '[pDebug]' truncates a real pointer to its
#      low 4 bytes.  Load the pointer into a P-alias register first, e.g. 'Mov PAX,[pDebug]', then
#      pass PAX, the pattern every current call site in this codebase already follows.
#  10. 'Call' (the internal, stack-based convention) invoking a name declared via 'EXPROC' instead
#      of 'PROC'.  See the calling-convention notes near the top of x64.inc: Call marshals every
#      argument onto the stack, but an EXPROC's own prologue homes RCX/RDX/R8/R9 into that same
#      stack space, so Call-ing it directly passes whatever those registers already held, not the
#      caller's real arguments.  This is exactly why every EXPROC forwards to an internal,
#      conventionally 'I'-suffixed PROC for other code in this codebase to Call instead.
#  11. The mirror of Check 10: 'ExCall' (the real Microsoft x64 ABI convention) invoking a name
#      declared via 'PROC', not 'EXPROC'.  ExCall marshals arguments into RCX/RDX/R8/R9; a plain
#      PROC's body instead reads them straight off the stack, at the offsets Call would have pushed
#      them to, so ExCall corrupts them the same way, in reverse.
#  12. 'XOr <P-alias>,<same P-alias>' (e.g. 'XOr PBX,PBX'), a self-XOr zeroing idiom written at
#      64-bit width for no reason: on x86-64, a 32-bit write always zero-extends the full 64-bit
#      register, so 'XOr EBX,EBX' zeroes RBX just as completely as 'XOr PBX,PBX' (RBX,RBX) does, at
#      one byte less encoding (no REX.W prefix needed).  Purely a style/size nit, not a correctness
#      bug like Checks 1-11, so it is reported the same way but never changes behavior if left as is.
#
# False positives this script cannot distinguish from real bugs, rare in practice but possible:
#   - A line that legitimately needs the low 32 bits of a pointer for an unrelated reason.  None of
#     this codebase's current pointer variables are used this way, but nothing stops a future one.
#   - A comment mentioning a pointer label and an E-register together.  Comments are stripped before
#     matching, so this should not occur, unless a NASM ';' inside a string literal on the same line
#     confuses the comment-stripping.  No such string literal exists in this codebase today.
#   - Check 3 treats every colon-terminated label, and every res*/db/dw/dd/dq/times declaration, as
#     a real memory label, and cannot tell an EQU alias used as a symbolic register name (SPC700's
#     PC, A, Y, YA, X, PS, S, OP1, OP2, DPI, ABSL, RAM, already hardcoded below) apart from a future
#     one not yet added to $RegisterAliases, which would be misread as a real label.
#   - Checks 7 and 8 have no per-field width or pointer-ness inside a struct-array base like
#     DSP.inc's 'mix'/'dsp': they only know the base label is not 'resPTR'/'PTRTAB'.  A future field
#     there that genuinely needs a full pointer would need excluding by name.  No such field exists
#     today.
# Any real hit should still be reviewed by eye, not blindly fixed by mechanically swapping
# in a P-alias.  See this port's own history of EXPROC/PROC calling-convention bugs for why
# blind register renaming without understanding the surrounding calling convention can make
# things worse.
#
# Usage: with no arguments, checks APU.asm/DSP.asm/SPC700.asm in the sibling snesapu directory.
# Pass any number of paths, positionally or via -Files, to check a different set instead.
#   powershell -ExecutionPolicy Bypass -File snesapu_validator.ps1
#   powershell -ExecutionPolicy Bypass -File snesapu_validator.ps1 path\to\some.asm path\to\other.asm
#
# Exit code: 0 if no violations were found, 1 if any were, also 1 on a usage error such as a missing
# input file.  Intended to run as a build-pipeline gate: call this before invoking nasm, and abort
# the build if it returns non-zero, e.g. from a .bat file:
#   powershell -ExecutionPolicy Bypass -File snesapu_validator.ps1
#   if errorlevel 1 goto :BUILD_FAILED
#
#                                                   Copyright (C) 2026 degrade-factory
# ==================================================================================================

param(
    # Files to check, in any number, either positionally or via -Files. $null, the default, means
    # "use APU.asm/DSP.asm/SPC700.asm in the sibling snesapu directory", this script's usual
    # target even though it now lives under snesapu-x64 itself.  Resolved below, once $ScriptDir is
    # known, since a parameter default cannot rely on $PSScriptRoot with ValueFromRemainingArguments
    # in Windows PowerShell 5.1.
    [Parameter(Position = 0, ValueFromRemainingArguments = $true)]
    [string[]]$Files = $null,
    # 'resPTR'-declared globals that are deliberately not plain pointers, each packing a real
    # address in its high bytes with an unrelated small data value in its low byte, where the
    # low-byte access is intended, not a leftover x86 mistake. regPC and regSP are documented this
    # way in SPC700.asm (see PopB).  Add a name here only after confirming a similar doc comment on
    # the label itself, not just because a hit looks intentional.
    [string[]]$ExcludeLabels = @('regPC', 'regSP')
)

$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $Files) {
    $Files = @(
        (Join-Path $ScriptDir '..\snesapu\APU.asm'),
        (Join-Path $ScriptDir '..\snesapu\DSP.asm'),
        (Join-Path $ScriptDir '..\snesapu\SPC700.asm')
    )
}

# A relative path here is always a caller-supplied one, since the built-in defaults above are
# already absolute, joined against $ScriptDir before this point.  Resolve it against the current
# directory, like any ordinary command-line tool, not against $ScriptDir.
$ResolvedFiles = @()
foreach ($f in $Files) {
    if (-not (Test-Path $f)) {
        Write-Host "ERROR: input file not found: $f"
        # $host.SetShouldExit(), not just 'exit 1': older Windows PowerShell console hosts, v2 or
        # v3, the default on Windows 7 before a WMF update, do not reliably propagate a script's
        # plain 'exit N' as the process exit code back to the calling shell, so a caller batch
        # file's '%errorlevel%' can read 0 even though N was 1.  SetShouldExit is the long-standing,
        # version-safe fix, a harmless no-op on modern hosts.
        $host.SetShouldExit(1)
        exit 1
    }
    $ResolvedFiles += (Resolve-Path $f).Path
}

$PAliases = 'PAX|PBX|PCX|PDX|PSI|PDI|PBP|PSP'
$BareRegs = 'EAX|EBX|ECX|EDX|ESI|EDI|EBP|ESP'

# P-alias -> its equivalent 32-bit E-register, for Check 12's suggested replacement.
$EAliasOf = @{
    'PAX' = 'EAX'; 'PBX' = 'EBX'; 'PCX' = 'ECX'; 'PDX' = 'EDX'
    'PSI' = 'ESI'; 'PDI' = 'EDI'; 'PBP' = 'EBP'; 'PSP' = 'ESP'
}

# Every file a scanned .asm '%include's, transitively (e.g. APU.asm includes macro.inc, which
# itself includes x64.inc, the one that actually declares 'PTRSIZE'), resolved relative to each
# including file's own directory the way NASM itself resolves a bare include name.  Pass 1 below
# also reads these, purely to collect EQU/STRUC-member names (e.g. x64.inc's 'PTRSIZE', DSP.inc's
# DSPRAM/VoiceMix), so Check 4 can recognize the common base-register-plus-struct-offset or
# EQU-constant idiom and not mistake either for a missed memory label.  This script still never
# checks these files themselves for violations.
$IncludedFiles = New-Object System.Collections.Generic.List[string]
$SeenIncludes = New-Object System.Collections.Generic.HashSet[string] ([StringComparer]::OrdinalIgnoreCase)
$IncludeWorklist = New-Object System.Collections.Generic.Queue[string]
foreach ($path in $ResolvedFiles) { $IncludeWorklist.Enqueue($path) }
while ($IncludeWorklist.Count -gt 0) {
    $path = $IncludeWorklist.Dequeue()
    $dir = Split-Path -Parent $path
    foreach ($line in Get-Content -LiteralPath $path) {
        if ($line -match '(?i)^\s*%include\s+"([^"]+)"') {
            $incPath = Join-Path $dir $Matches[1]
            if (Test-Path $incPath) {
                $incResolved = (Resolve-Path $incPath).Path
                if ($SeenIncludes.Add($incResolved)) {
                    [void]$IncludedFiles.Add($incResolved)
                    $IncludeWorklist.Enqueue($incResolved)
                }
            }
        }
    }
}
$StrucScanFiles = @($ResolvedFiles) + @($IncludedFiles)

# Every register-shaped token Check 3 should treat as an index that rode along, spelled exactly as
# it appears in source: the P-aliases, the bare 32/16/8-bit x86 register names, the raw 64-bit
# names, and SPC700.asm's own '%define'-based CPU-register aliases.  Those resolve to a real
# register, not a memory label, even though they read like ordinary identifiers.
$RegisterAliases = @(
    'PAX', 'PBX', 'PCX', 'PDX', 'PSI', 'PDI', 'PBP', 'PSP',
    'RAX', 'RBX', 'RCX', 'RDX', 'RSI', 'RDI', 'RBP', 'RSP',
    'EAX', 'EBX', 'ECX', 'EDX', 'ESI', 'EDI', 'EBP', 'ESP',
    'AX', 'BX', 'CX', 'DX', 'SI', 'DI', 'BP', 'SP',
    'AL', 'AH', 'BL', 'BH', 'CL', 'CH', 'DL', 'DH',
    'PC', 'A', 'Y', 'YA', 'X', 'PS', 'S', 'OP1', 'OP2', 'DPI', 'ABSL', 'RAM'
)
$RegisterSet = New-Object System.Collections.Generic.HashSet[string] ([StringComparer]::OrdinalIgnoreCase)
foreach ($r in $RegisterAliases) { [void]$RegisterSet.Add($r) }

# ==================================================================================================
# Pass 1: collect every pointer variable name declared via 'resPTR' or 'PTRTAB', plus every real
# memory-label name (any colon-terminated label, or one declared via resb/resw/resd/resq/resPTR/
# PTRTAB/db/dw/dd/dq/times), across all three files.  An EQU-defined name is deliberately not
# added to $MemLabels, since it assembles as a plain immediate, not a memory address, so combining
# one with a register inside brackets is not a Check 3 hit, but it is collected into its own
# $EquNames set below, so Check 4 does not mistake a known EQU constant (e.g. 'PTRSIZE', 'FIRBUF')
# for a possibly-missed memory label.
#
# A res*/d*-style declaration inside a 'STRUC ... ENDSTRUC' block, such as SPC700.asm's
# MemMap or DSP.inc's VoiceMix, is not a real memory address either, but a struct-member
# offset that NASM resolves to a compile-time constant just like an EQU, the whole point of
# a base-register-plus-struct-offset idiom such as 'RAM+t0'.  Those names are excluded from
# $MemLabels here the same way EQU names are, and collected into their own $StrucMembers set
# instead, for the same Check 4 reason.
$PtrLabels = New-Object System.Collections.Generic.HashSet[string]
$MemLabels = New-Object System.Collections.Generic.HashSet[string]
$StrucMembers = New-Object System.Collections.Generic.HashSet[string]
$EquNames = New-Object System.Collections.Generic.HashSet[string]
$ProcNames = New-Object System.Collections.Generic.HashSet[string]
$ExProcNames = New-Object System.Collections.Generic.HashSet[string]
foreach ($path in $StrucScanFiles) {
    $strucDepth = 0
    foreach ($line in Get-Content -LiteralPath $path) {
        $code = ($line -split ';', 2)[0]
        if ($code -match '(?i)^\s*STRUC\b') { $strucDepth++; continue }
        if ($code -match '(?i)^\s*ENDSTRUC\b') { if ($strucDepth -gt 0) { $strucDepth-- }; continue }
        if ($code -match '^\s*([A-Za-z_][A-Za-z0-9_]*)\s+resPTR\b') {
            [void]$PtrLabels.Add($Matches[1])
        }
        # 'PTRTAB' declares a table of pointer-width code addresses, like 'resPTR' but for many
        # elements instead of one, e.g. SPC700.asm's 'opcOfs'/'fncOfs' or DSP.asm's 'dspRegs'.
        # Every element is genuinely pointer-width, so these join $PtrLabels alongside 'resPTR'
        # names for Checks 2, 5, and 6 to classify correctly.
        if ($code -match '^\s*([A-Za-z_][A-Za-z0-9_]*)\s+PTRTAB\b') {
            [void]$PtrLabels.Add($Matches[1])
        }
        if ($code -match '^\s*([A-Za-z_][A-Za-z0-9_]*)\s+EQU\b') {
            [void]$EquNames.Add($Matches[1])
        }
        # 'PROC'/'EXPROC' each declare a callable procedure name, in one of the two calling
        # conventions Call/ExCall below must not cross.  A name is always declared by exactly one
        # of these two macros, never both, so $ProcNames and $ExProcNames are disjoint by
        # construction.  See Checks 10 and 11 for why mixing them silently corrupts arguments.
        if ($code -match '(?i)^\s*PROC\s+([A-Za-z_][A-Za-z0-9_]*)') {
            [void]$ProcNames.Add($Matches[1])
        }
        if ($code -match '(?i)^\s*EXPROC\s+([A-Za-z_][A-Za-z0-9_]*)') {
            [void]$ExProcNames.Add($Matches[1])
        }
        if ($strucDepth -gt 0) {
            if ($code -match '^\s*([A-Za-z_][A-Za-z0-9_]*)\s+(res[bwdq]|d[bwdq]|times)\b') {
                [void]$StrucMembers.Add($Matches[1])
            }
            continue
        }
        if ($code -match '^\s*([A-Za-z_][A-Za-z0-9_.]*)\s*:') {
            [void]$MemLabels.Add($Matches[1])
        }
        if ($code -match '^\s*([A-Za-z_][A-Za-z0-9_]*)\s+(res[bwdq]|resPTR|PTRTAB|d[bwdq]|times)\b') {
            [void]$MemLabels.Add($Matches[1])
        }
    }
}
# A name that is really a register alias, from SPC700.asm's PC/A/Y/... equates block, is never a
# memory label even if it also matches one of the declaration patterns above.  None currently do,
# since those are '%define', not ':' or 'res*/d*', so this is just belt-and-suspenders.
foreach ($r in $RegisterAliases) { [void]$MemLabels.Remove($r) }

if ($PtrLabels.Count -eq 0) {
    Write-Host "WARNING: found zero 'resPTR' declarations across $($ResolvedFiles.Count) file(s)."
    Write-Host "         Either the input file list is wrong, or this check needs updating,"
    Write-Host "         either way, pointer-label-based checks below cannot run meaningfully."
}
else {
    Write-Host "Found $($PtrLabels.Count) pointer-typed global(s) (resPTR): $($PtrLabels -join ', ')"
}

foreach ($ex in $ExcludeLabels) {
    if ($PtrLabels.Remove($ex)) {
        Write-Host "  excluding '$ex' from the checks below (packed pointer+data value, see -ExcludeLabels doc)"
    }
}

$LabelAlt = ($PtrLabels | ForEach-Object { [regex]::Escape($_) }) -join '|'

# Every spelling of the PDI physical register: the P-alias itself, its bare 32/64-bit x86 names, and
# SPC700.asm's own aliases for it, RAM and S.  Used by Check 6 on the PDI-fallback path (val is
# AH/BH/CH/DH), to catch an omitted scratch argument colliding with PDI used elsewhere in the call.
$PdiAliasSet = New-Object System.Collections.Generic.HashSet[string] ([StringComparer]::OrdinalIgnoreCase)
foreach ($r in @('PDI', 'RDI', 'EDI', 'RAM', 'S')) { [void]$PdiAliasSet.Add($r) }

# Every spelling of the R10 physical register: its 64/32/16/8-bit names.  R10 has no P-alias or
# SPC700.asm equate, since this port never gives it a persistent meaning of its own outside ExCall's
# argument-staging scratch (see x64.inc's PushAD comment and ExCall's doc), which is exactly why
# it is safe as the default scratch register here too.  R10, not R8/R9, so that R10 joins R11
# (already ExCall's own indirect-call-target scratch) as the pair these macros own, leaving R8/R9
# free for a future hand-written scratch use without silently colliding with these macros.  Used by
# Check 6 on the (more common) R10-default path, to catch the same class of collision.
$R10AliasSet = New-Object System.Collections.Generic.HashSet[string] ([StringComparer]::OrdinalIgnoreCase)
foreach ($r in @('R10', 'R10D', 'R10W', 'R10B')) { [void]$R10AliasSet.Add($r) }

# Every spelling of a high-byte register.  IdxSt/IdxLd/IdxLdX's 'val' argument being one of these is
# what forces their scratch register to fall back to PDI instead of R10 (see x64.inc's IdxSt comment:
# an R8-R15 base would force a REX prefix, and REX cannot encode a high-byte register).
$HighByteRegSet = New-Object System.Collections.Generic.HashSet[string] ([StringComparer]::OrdinalIgnoreCase)
foreach ($r in @('AH', 'BH', 'CH', 'DH')) { [void]$HighByteRegSet.Add($r) }

# Argument counts and 1-indexed argument positions, counting the op mnemonic as argument 1, for each
# macro whose optional trailing scratch-register argument defaults to R10 or PDI (see Check 6 above).
# Min is the argument count with that scratch argument omitted, since an explicit one, at Min+1,
# already sidesteps the problem.  ValPos, where present, is the 'val' argument that decides which
# default applies.  Its absence means the macro has no 'val' of its own and always defaults to R10.
# DangerPositions are the other arguments to scan for a collision with whichever default applies.
# IdxLd and IdxLdX omit their own ValPos from DangerPositions, since loading straight into the
# scratch register is their documented, intentional case, not a collision, on either default.
$ScratchRegMacros = @{
    'IdxSt'  = @{ Min = 4; ValPos = 4; DangerPositions = @(3, 4) }      # op,label,index,val
    'IdxLd'  = @{ Min = 4; ValPos = 2; DangerPositions = @(4) }         # op,val,label,index
    'IdxLdX' = @{ Min = 5; ValPos = 2; DangerPositions = @(5) }         # op,val,size,label,index
    'IdxUn'  = @{ Min = 3; ValPos = $null; DangerPositions = @(3) }     # op,label,index
    'LblOp'  = @{ Min = 3; ValPos = $null; DangerPositions = @(2) }     # op,reg,label
}

# ==================================================================================================
# Pass 2: scan every line of every file for the twelve violation patterns above.
$Violations = New-Object System.Collections.Generic.List[string]

foreach ($path in $ResolvedFiles) {
    $fileName = Split-Path -Leaf $path
    $lineNum = 0
    foreach ($line in Get-Content -LiteralPath $path) {
        $lineNum++
        $code = ($line -split ';', 2)[0]
        if ($code.Trim() -eq '') { continue }

        # Check 1: LoadPtr into a bare E-register (destination is always the first operand).
        if ($code -match "(?i)\bLoadPtr\s+($BareRegs)\s*,") {
            $Violations.Add("${fileName}:${lineNum}: LoadPtr targets bare register $($Matches[1]), should be a P-alias: $($code.Trim())")
            continue
        }

        if ($LabelAlt -ne '') {
            # Check 2: a bracketed reference to a known pointer variable, on a line that also uses a
            # bare E-register or an explicit dword/word/byte size override right before the bracket.
            # $Matches gets overwritten by each subsequent -match below, so the label name is saved
            # to its own variable immediately, before any other regex evaluation can clobber it.
            if ($code -match "\[\s*($LabelAlt)\s*(\+[^\]]*)?\]") {
                $labelName = $Matches[1]
                $hasBareReg = $code -match "(?i)\b($BareRegs)\b"
                $bareRegName = if ($hasBareReg) { $Matches[1] } else { $null }
                $hasSizeOverride = $code -match "(?i)\b(dword|word|byte)\s+\[\s*($LabelAlt)\b"
                if ($hasBareReg -or $hasSizeOverride) {
                    $reason = if ($hasSizeOverride) { "explicit dword/word/byte size on pointer variable '$labelName' (use PTRKW instead)" }
                              else { "bare register '$bareRegName' alongside pointer variable '$labelName' (use a P-alias instead)" }
                    $Violations.Add("${fileName}:${lineNum}: ${reason}: $($code.Trim())")
                }
            }
        }

        # Check 3: any '[...]' bracket that combines a real memory label with a register or
        # SPC700.asm register alias, i.e. a label+index written directly instead of through
        # IdxSt/IdxLd/IdxLdX/IdxUn.  Tokenizes each bracket's contents on +/-/*, discards the sign,
        # and classifies each token as a number, a known register/alias, a collected memory label,
        # or a known STRUC member (see $StrucMembers above) by elimination, flagging only a bracket
        # that contains both a label and a register.  Runs independently of Checks 1 and 2, and of
        # whether any 'resPTR' label exists at all, since it works off $MemLabels, not $PtrLabels.
        #
        # Check 4: the low-confidence fallback for the same bracket, when a token pairs with a
        # known register but is neither a number, a known register/alias, a collected memory
        # label, nor a known STRUC member.  Most such tokens really are an EQU constant this script
        # cannot otherwise classify, but a few may be a real memory label Pass 1 failed to collect
        # (e.g. one declared in a file this script does not scan), so this reports them separately
        # and clearly marked low-confidence, rather than silently ignoring them as Check 3 alone
        # would.  See the header's false-positives section for why this is noisier than Check 3.
        foreach ($bm in [regex]::Matches($code, '\[([^\[\]]+)\]')) {
            $tokens = $bm.Groups[1].Value -split '[+\-*]' |
                ForEach-Object { $_.Trim().Trim('(', ')') } | Where-Object { $_ -ne '' }
            $foundLabel = $null
            $foundReg = $null
            $unknownToks = New-Object System.Collections.Generic.List[string]
            foreach ($tok in $tokens) {
                if ($tok -match '^(0x[0-9A-Fa-f]+|[0-9][0-9A-Fa-f]*h|[01]+b|[0-7]+o|[0-9]+)$') { continue }
                # A macro-parameter placeholder ('%1', '%2', ...): resolved only when the macro is
                # instantiated, never a literal label reference on this line as written.
                if ($tok -match '^%[0-9]+$') { continue }
                if ($RegisterSet.Contains($tok)) { $foundReg = $tok; continue }
                if ($MemLabels.Contains($tok)) { $foundLabel = $tok; continue }
                if ($StrucMembers.Contains($tok)) { continue }
                if ($EquNames.Contains($tok)) { continue }
                # Neither a number, a known register/alias, a collected memory label, a known STRUC
                # member, nor a known EQU constant.  Most likely an identifier this script has no
                # declaration for at all, so it is set aside for Check 4 below
                # instead of being silently ignored outright.
                [void]$unknownToks.Add($tok)
            }
            if ($foundLabel -and $foundReg) {
                # Picks the one macro that actually fits this bracket's position, instead of just
                # listing all four, reading the bracket's role, destination, source, or the only
                # operand, from where it sits relative to the operand-separating comma.  A size
                # keyword right before the bracket picks IdxLdX over IdxLd for a load, since IdxLd's
                # template has no room for that keyword.
                $beforeBracket = $code.Substring(0, $bm.Index)
                $afterBracket = $code.Substring($bm.Index + $bm.Length)
                $hasCommaBefore = $beforeBracket.Contains(',')
                $hasCommaAfter = $afterBracket.Contains(',')
                $hasSizePrefix = $beforeBracket -match '(?i)(dword|word|byte|qword)\s*$'
                $recommended = if ($hasCommaBefore) {
                    if ($hasSizePrefix) { 'IdxLdX (a load with a differently-sized memory operand, e.g. MovZX/MovSX)' }
                    else { 'IdxLd (a load: memory is the source operand)' }
                } elseif ($hasCommaAfter) {
                    'IdxSt (a store: memory is the destination operand)'
                } else {
                    'IdxUn (a single memory operand, e.g. FStP/FILd/Inc)'
                }
                $Violations.Add("${fileName}:${lineNum}: raw '[$($bm.Groups[1].Value)]' combines memory label '$foundLabel' with register '$foundReg' directly, use ${recommended}: $($code.Trim())")
            }
            elseif ($foundReg -and $unknownToks.Count -gt 0) {
                $unknownList = $unknownToks -join "', '"
                $Violations.Add("${fileName}:${lineNum}: (low-confidence) raw '[$($bm.Groups[1].Value)]' pairs register '$foundReg' with unrecognized identifier(s) '$unknownList', review by hand: if one of these is really a memory label this script missed, it needs IdxSt/IdxLd/IdxLdX/IdxUn instead of raw addressing, otherwise this is probably a struct-offset/EQU idiom and can be ignored: $($code.Trim())")
            }
        }

        # Check 5: 'Mov'/'Add'/'Sub'/'And'/'Or'/'Cmp' with a bare (non-bracketed) known memory
        # label as its second operand, written directly instead of through LoadPtr/LblOp/LblSt.
        # See the header comment above for why this silently assembles wrong.
        if ($code -match "(?i)^\s*(Mov|Add|Sub|And|Or|Cmp)\b\s*(.*)$") {
            $opName = $Matches[1]
            $operandsText = $Matches[2]
            $commaIdx = $operandsText.IndexOf(',')
            if ($commaIdx -ge 0) {
                $destTok = $operandsText.Substring(0, $commaIdx).Trim()
                $srcTok = $operandsText.Substring($commaIdx + 1).Trim()
                $destNoSize = $destTok -replace '(?i)^(dword|word|byte|qword)\s+', ''
                if (-not $srcTok.StartsWith('[') -and $MemLabels.Contains($srcTok)) {
                    if ($RegisterSet.Contains($destNoSize)) {
                        if ($opName -match '(?i)^Mov$') {
                            $Violations.Add("${fileName}:${lineNum}: raw 'Mov $destTok,$srcTok' loads a label's address directly, use LoadPtr instead: $($code.Trim())")
                        }
                        else {
                            $Violations.Add("${fileName}:${lineNum}: raw '$opName $destTok,$srcTok' combines a register with a label's address directly, use LblOp instead: $($code.Trim())")
                        }
                    }
                    elseif ($opName -match '(?i)^Mov$' -and $destNoSize -match '^\[\s*([A-Za-z_][A-Za-z0-9_.]*)\s*\]$' -and $MemLabels.Contains($Matches[1])) {
                        $Violations.Add("${fileName}:${lineNum}: raw 'Mov $destTok,$srcTok' stores a label's address directly, use LblSt instead: $($code.Trim())")
                    }
                }
            }
        }

        # Check 6: an IdxSt/IdxLd/IdxLdX/IdxUn/LblOp call whose omitted scratch-register argument
        # collides with that same physical register (R10, or PDI on the high-byte-val fallback)
        # used elsewhere in the same call.  See the header comment above for why this silently
        # corrupts that other argument's value.
        foreach ($spec in $ScratchRegMacros.GetEnumerator()) {
            if ($code -notmatch "(?i)\b$($spec.Key)\s+(.*)$") { continue }
            $argsText = $Matches[1]
            $args = $argsText -split ',' | ForEach-Object { $_.Trim() }
            if ($args.Count -ne $spec.Value.Min) { continue } # scratch arg was explicit, or this is not a real call
            $isHighByteVal = $spec.Value.ValPos -and $HighByteRegSet.Contains($args[$spec.Value.ValPos - 1])
            if ($isHighByteVal) { $defaultReg = 'PDI'; $aliasSet = $PdiAliasSet }
            else { $defaultReg = 'R10'; $aliasSet = $R10AliasSet }
            foreach ($pos in $spec.Value.DangerPositions) {
                if ($pos -gt $args.Count) { continue }
                $argTokens = $args[$pos - 1] -split '[+\-*]' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
                if ($argTokens | Where-Object { $aliasSet.Contains($_) }) {
                    $Violations.Add("${fileName}:${lineNum}: $($spec.Key) omits its scratch-register argument (defaults to $defaultReg here) while also using $defaultReg in argument ${pos}, pass an explicit different scratch register: $($code.Trim())")
                    break
                }
            }
        }

        # Check 7: IdxSt storing a P-alias value into a label declared but not via 'resPTR', or
        # LblSt storing a label's address into such a destination, the mirror image of Check 2.  See
        # the header comment above for the real bug this catches.
        if ($code -match "(?i)\bIdxSt\s+(.*)$") {
            $idxStArgs = $Matches[1] -split ',' | ForEach-Object { $_.Trim() }
            if ($idxStArgs.Count -eq 4 -or $idxStArgs.Count -eq 5) {
                $storeLabel = $idxStArgs[1]
                $storeVal = $idxStArgs[3]
                if ($MemLabels.Contains($storeLabel) -and -not $PtrLabels.Contains($storeLabel) -and ($storeVal -match "(?i)^($PAliases)$")) {
                    $Violations.Add("${fileName}:${lineNum}: IdxSt stores pointer-width '$storeVal' into '$storeLabel', which is not declared 'resPTR', use a bare register matching the field's real width instead: $($code.Trim())")
                }
            }
        }
        if ($code -match "(?i)\bLblSt\s+(.*)$") {
            $lblStArgs = $Matches[1] -split ',' | ForEach-Object { $_.Trim() }
            if ($lblStArgs.Count -eq 2 -or $lblStArgs.Count -eq 3) {
                $storeDest = $lblStArgs[0]
                if ($MemLabels.Contains($storeDest) -and -not $PtrLabels.Contains($storeDest)) {
                    $Violations.Add("${fileName}:${lineNum}: LblSt stores a label's address into '$storeDest', which is not declared 'resPTR': $($code.Trim())")
                }
            }
        }

        # Check 8: IdxLd loading through a non-LEA op into a P-alias 'val' from a label known but
        # not declared 'resPTR'/'PTRTAB', the read-side mirror of Check 7.  See the header comment
        # above for why 'op' must be checked and IdxLdX needs no equivalent.
        if ($code -match "(?i)\bIdxLd\s+(.*)$") {
            $idxLdArgs = $Matches[1] -split ',' | ForEach-Object { $_.Trim() }
            if ($idxLdArgs.Count -eq 4 -or $idxLdArgs.Count -eq 5) {
                $loadOp = $idxLdArgs[0]
                $loadVal = $idxLdArgs[1]
                $loadLabel = $idxLdArgs[2]
                if ($loadOp -notmatch '(?i)^LEA$' -and $MemLabels.Contains($loadLabel) -and -not $PtrLabels.Contains($loadLabel) -and ($loadVal -match "(?i)^($PAliases)$")) {
                    $Violations.Add("${fileName}:${lineNum}: IdxLd ($loadOp) loads pointer-width '$loadVal' from '$loadLabel', which is not declared 'resPTR'/'PTRTAB', use a bare register matching the field's real width instead: $($code.Trim())")
                }
            }
        }

        # Check 9: a 'Call'/'ExCall' argument (any position after the target in position 1) that is
        # a bare '[label]' referencing a known 'resPTR'/'PTRTAB' variable directly, instead of first
        # loading it into a P-alias register. See the header comment above for why this truncates.
        if ($code -match "(?i)\b(?:Ex)?Call\s+(.*)$") {
            $callArgs = $Matches[1] -split ',' | ForEach-Object { $_.Trim() }
            for ($i = 1; $i -lt $callArgs.Count; $i++) {
                if ($callArgs[$i] -match '^\[\s*([A-Za-z_][A-Za-z0-9_]*)\s*\]$' -and $PtrLabels.Contains($Matches[1])) {
                    $ptrArgName = $Matches[1]
                    $Violations.Add("${fileName}:${lineNum}: Call/ExCall argument '$($callArgs[$i])' reads pointer-typed '$ptrArgName' ('resPTR'/'PTRTAB') 32-bit wide, load it into a P-alias register first: $($code.Trim())")
                }
            }
        }

        # Check 10: 'Call' (the internal, stack-based convention) invoking a name declared via
        # EXPROC instead of PROC.  Call marshals every argument onto the stack for the internal
        # convention; an EXPROC's own prologue instead homes RCX/RDX/R8/R9 into that same stack
        # space, so calling it through Call passes whatever those registers happened to already
        # hold, not the caller's real arguments.  See the header comment above for the two
        # conventions and why EXPROC always forwards to an internal, conventionally 'I'-suffixed
        # PROC for exactly this reason.
        if ($code -match '(?i)^\s*Call\s+([A-Za-z_][A-Za-z0-9_]*)') {
            $callTarget = $Matches[1]
            if ($ExProcNames.Contains($callTarget)) {
                $Violations.Add("${fileName}:${lineNum}: Call invokes '$callTarget', declared via EXPROC (the real Microsoft x64 ABI convention), call its internal 'I'-suffixed counterpart instead, or use ExCall if it genuinely needs the ABI convention: $($code.Trim())")
            }
        }

        # Check 11: the mirror of Check 10: 'ExCall' (the real Microsoft x64 ABI convention)
        # invoking a name declared via PROC, not EXPROC.  ExCall marshals arguments into
        # RCX/RDX/R8/R9; a plain PROC's body instead reads them straight off the stack, at the
        # offsets Call would have pushed them to, so ExCall corrupts them the same way, in reverse.
        if ($code -match '(?i)^\s*ExCall\s+([A-Za-z_][A-Za-z0-9_]*)') {
            $exCallTarget = $Matches[1]
            if ($ProcNames.Contains($exCallTarget)) {
                $Violations.Add("${fileName}:${lineNum}: ExCall invokes '$exCallTarget', declared via PROC (the internal-only convention), use Call instead: $($code.Trim())")
            }
        }

        # Check 12: 'XOr <P-alias>,<same P-alias>', a self-XOr zeroing idiom written at 64-bit width
        # for no reason, since a 32-bit write already zero-extends the full 64-bit register.  See the
        # header comment above.
        if ($code -match "(?i)^\s*XOr\s+($PAliases)\s*,\s*($PAliases)\b") {
            $xorLhs = $Matches[1]
            $xorRhs = $Matches[2]
            if ($xorLhs.ToUpperInvariant() -eq $xorRhs.ToUpperInvariant()) {
                $eAlias = $EAliasOf[$xorLhs.ToUpperInvariant()]
                $Violations.Add("${fileName}:${lineNum}: 'XOr $xorLhs,$xorRhs' zeroes the full 64-bit register at 64-bit width for no reason, use 'XOr $eAlias,$eAlias' instead: $($code.Trim())")
            }
        }
    }
}

if ($Violations.Count -eq 0) {
    Write-Host 'OK: no leftover x86-only pointer-width notation found.'
    $host.SetShouldExit(0)  # see the file-not-found check above for why this accompanies 'exit'
    exit 0
}
else {
    foreach ($v in $Violations) { Write-Host "VIOLATION: $v" }
    Write-Host ''
    Write-Host "$($Violations.Count) potential pointer-width violation(s) found, review each by hand before fixing."
    $host.SetShouldExit(1)  # see the file-not-found check above for why this accompanies 'exit'
    exit 1
}
