# ===================================================================================================
# Program:    snesapu_validator.ps1
# Purpose:    static lint for leftover x86-only pointer-width notation
# Platform:   any (PowerShell 5.1+, no external dependencies)
#
# Catches the bug class this amd64 port has already hit more than once (apuCbFunc's EAX-width
# clear, InitAPU's original pointer-size mismatches, etc). Code that accesses a pointer variable
# (one declared 'resPTR' in APU.asm/DSP.asm/SPC700.asm) through a bare 32-bit E-register or an
# explicit dword/word/byte-sized memory operand, instead of the P-alias registers (PAX/PBX/PCX/PDX/
# PSI/PDI/PBP/PSP) or the PTRKW size keyword this port's macro layer defines. On x86 these two forms
# compile to the same bytes and behave identically, so a stray 'Mov EAX,[pDebug]' or 'Push dword
# [pDebug]' looks harmless there. On amd64 it silently truncates a 64-bit address to 32 bits, which
# shows up only as a crash or corrupted state far from the actual mistake.
#
# This script does not understand assembly semantics. It does not track which register currently
# holds a pointer value the way a human reviewer, or the P-alias audit done earlier in this port,
# does. It only catches the syntactically-detectable, high-confidence patterns below, covering every
# real bug of this shape found during the port so far:
#
#   1. 'LoadPtr <reg>,<label>' where <reg> is not a P-alias. LoadPtr's job is to produce a genuine
#      address in a register (LEA on amd64, MOV on x86), so its destination must always be
#      pointer-width, regardless of which label the address is for.
#   2. Any reference to '[<label>]' (with or without a +offset) where <label> is one of the
#      'resPTR'-declared pointer variables collected from the three .asm files, if the line also
#      contains a bare E-register (EAX/EBX/ECX/EDX/ESI/EDI/EBP/ESP) or an explicit dword/word/byte
#      size override immediately before the bracket. The correct forms are a plain P-alias register,
#      or the PTRKW macro constant for an explicit size (see x86.inc/x64.inc).
#   3. A raw '[label+register]'-style bracket expression written directly instead of going through
#      IdxSt/IdxLd/IdxLdX/IdxUn/LblOp/LblSt. Those macros exist because amd64's RIP-relative
#      addressing mode has no SIB byte, so it cannot combine a compile-time label with an index
#      register in one instruction the way x86's 32-bit-displacement-plus-SIB addressing can.
#      Confirmed empirically, not just from the NASM manual, that NASM does not reject this at build
#      time: 'mov al,[someLabel+ecx]' under 'DEFAULT REL'/win64 assembles cleanly and silently falls
#      back to a 32-bit address-size override (the 0x67 prefix) plus an IMAGE_REL_AMD64_ADDR32
#      relocation, the same "truncates to 32 bits, breaks above a 4GB load address" failure this
#      port has already hit and fixed more than once. This check flags any bracket expression in
#      APU.asm/DSP.asm/SPC700.asm that combines a real memory label (a colon-terminated label, or
#      one declared via resb/resw/resd/resq/resPTR/db/dw/dd/dq/times) with a register or SPC700.asm
#      register alias (PC/A/Y/YA/X/PS/S/OP1/OP2/DPI/ABSL/RAM/...). Those call sites should go
#      through the Idx**/Lbl** macro layer instead. A label combined only with a compile-time
#      constant, EQU-defined or a plain number, is not flagged: EQU constants and literals fold
#      into the instruction as an immediate displacement, which plain RIP-relative addressing
#      already handles fine. The danger is specifically a register riding along as an index, the
#      one thing RIP-relative addressing cannot do at all.
#   4. An IdxSt/IdxLd/IdxLdX/IdxUn/LblOp call that omits its optional trailing scratch-register
#      argument (all default to PDI) while also passing PDI, or one of its aliases (RAM/S from
#      SPC700.asm, or the bare EDI/RDI spelling of the same physical register), as one of that
#      call's other arguments. Those macros push the scratch register, overwrite it with the
#      label's address, then use it, so if that same register is also the index (or, for LblOp, the
#      combined register), its real value is already gone by the time the instruction runs. IdxLd/
#      IdxLdX exempt their 'val' argument from this: loading straight into PDI is the macro's
#      documented, intentionally-handled case (see their %ifnidni branch in x64.inc), not a
#      collision.
#
# False positives this script cannot distinguish from real bugs, rare in practice but possible:
#   - A line that legitimately needs the low 32 bits of a pointer for an unrelated reason. None of
#     this codebase's current pointer variables are used this way, but nothing stops a future one.
#   - A comment mentioning a pointer label and an E-register together. Comments are stripped before
#     matching, so this should not occur, but a NASM ';' inside a string literal on the same line
#     could confuse the comment-stripping. This codebase has no string literal containing ';' on the
#     same line as a resPTR reference today.
#   - Check 3 treats every colon-terminated label, including local '.loop:'-style jump targets, and
#     every res*/db/dw/dd/dq/times declaration as a real memory label. It cannot tell an EQU alias
#     used as a symbolic register name (SPC700.asm's PC/A/Y/YA/X/PS/S/OP1/OP2/DPI/ABSL/RAM, already
#     hardcoded into the known-register set below) apart from a future such alias not yet added to
#     that set. A new register-alias '%define' needs adding to $RegisterAliases below, or it will be
#     misread as a real label and can produce a false hit.
# Any real hit should still be reviewed by eye, not blindly fixed by mechanically swapping in a
# P-alias. See this port's own history of EXPROC/PROC calling-convention bugs for why blind register
# renaming without understanding the surrounding calling convention can make things worse.
#
# Usage: with no arguments, checks APU.asm/DSP.asm/SPC700.asm in the sibling snesapu.dll directory.
# Pass any number of paths, positionally or via -Files, to check a different set instead.
#   powershell -ExecutionPolicy Bypass -File snesapu_validator.ps1
#   powershell -ExecutionPolicy Bypass -File snesapu_validator.ps1 path\to\some.asm path\to\other.asm
#
# Exit code: 0 if no violations found, 1 if any were found, also 1 on a usage error such as a
# missing input file. Intended to run as a build-pipeline gate: call this before invoking nasm and
# abort the build if it returns non-zero, e.g. from a .bat file:
#   powershell -ExecutionPolicy Bypass -File snesapu_amd64.dll\snesapu_validator.ps1
#   if errorlevel 1 goto :BUILD_FAILED
#
#                                                   Copyright (C) 2026 degrade-factory
# ===================================================================================================

param(
    # Files to check, in any number, either positionally or via -Files. $null (the default) means
    # "use APU.asm/DSP.asm/SPC700.asm in the sibling snesapu.dll directory", this script's usual
    # target even though it now lives under snesapu_amd64.dll itself -- resolved below, once
    # $ScriptDir is known, since a parameter default cannot rely on $PSScriptRoot with
    # ValueFromRemainingArguments in Windows PowerShell 5.1.
    [Parameter(Position = 0, ValueFromRemainingArguments = $true)]
    [string[]]$Files = $null,
    # 'resPTR'-declared globals that are deliberately not plain pointers. Each packs a real address
    # in its high bytes with an unrelated small data value in its low byte(s), and the low-byte
    # accesses are the correct, intended way to read/write that packed value, not a leftover x86
    # mistake. regPC/regSP are documented this way in SPC700.asm: regPC is "RAM base with PC in the
    # low word", regSP is "RAM base with SP in the low byte" (see PopB). Add a name here only after
    # confirming a similar packed-value doc comment, not just because a hit looks intentional.
    [string[]]$ExcludeLabels = @('regPC', 'regSP')
)

$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $Files) {
    $Files = @(
        (Join-Path $ScriptDir '..\snesapu.dll\APU.asm'),
        (Join-Path $ScriptDir '..\snesapu.dll\DSP.asm'),
        (Join-Path $ScriptDir '..\snesapu.dll\SPC700.asm')
    )
}

# A relative path here is always a caller-supplied one, since the built-in defaults above are
# already absolute (they're joined against $ScriptDir before this point). Resolve it against the
# current directory, like any ordinary command-line tool, not against $ScriptDir.
$ResolvedFiles = @()
foreach ($f in $Files) {
    if (-not (Test-Path $f)) {
        Write-Host "ERROR: input file not found: $f"
        exit 1
    }
    $ResolvedFiles += (Resolve-Path $f).Path
}

$PAliases = 'PAX|PBX|PCX|PDX|PSI|PDI|PBP|PSP'
$BareRegs = 'EAX|EBX|ECX|EDX|ESI|EDI|EBP|ESP'

# Every register-shaped token Check 3 should treat as "an index register rode along", spelled
# exactly as it appears in source: the P-aliases, the bare 32-bit/16-bit/8-bit x86 register names,
# the raw 64-bit names (in case amd64-only code ever names one directly instead of via a P-alias),
# and SPC700.asm's own '%define'-based CPU-register aliases (see its "Registers"/"Pointers" equates
# block). Those resolve to a real register, not a memory label, even though they read like ordinary
# identifiers.
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

# --- Pass 1: collect every 'resPTR'-declared pointer variable name, plus every real memory-label --
# name (any colon-terminated label, or one declared via resb/resw/resd/resq/resPTR/db/dw/dd/dq/
# times), across all three files. EQU-defined names are deliberately not collected here. An EQU is
# a compile-time constant that assembles as a plain immediate, not a memory address, so combining
# one with a register inside brackets needs no RIP-relative addressing trick and is not a Check-3
# hit.
#
# A res*/d*-style declaration inside a 'STRUC ... ENDSTRUC' block (see SPC700.asm's MemMap,
# DSP.inc's VoiceMix) is not a real memory address either, it's a struct-member offset, which NASM
# resolves to a compile-time constant exactly like an EQU. That is the whole point of a
# base-register-plus-struct-offset idiom, e.g. 'RAM+t0' meaning "the t0 field of the struct RAM
# points at". Those names must be tracked and excluded here the same way EQU names are never
# collected at all.
$PtrLabels = New-Object System.Collections.Generic.HashSet[string]
$MemLabels = New-Object System.Collections.Generic.HashSet[string]
foreach ($path in $ResolvedFiles) {
    $strucDepth = 0
    foreach ($line in Get-Content -LiteralPath $path) {
        $code = ($line -split ';', 2)[0]
        if ($code -match '(?i)^\s*STRUC\b') { $strucDepth++; continue }
        if ($code -match '(?i)^\s*ENDSTRUC\b') { if ($strucDepth -gt 0) { $strucDepth-- }; continue }
        if ($code -match '^\s*([A-Za-z_][A-Za-z0-9_]*)\s+resPTR\b') {
            [void]$PtrLabels.Add($Matches[1])
        }
        if ($strucDepth -gt 0) { continue }
        if ($code -match '^\s*([A-Za-z_][A-Za-z0-9_.]*)\s*:') {
            [void]$MemLabels.Add($Matches[1])
        }
        if ($code -match '^\s*([A-Za-z_][A-Za-z0-9_]*)\s+(res[bwdq]|resPTR|d[bwdq]|times)\b') {
            [void]$MemLabels.Add($Matches[1])
        }
    }
}
# A name that is really a register alias (SPC700.asm's PC/A/Y/... equates block) is never a memory
# label even if it also matches one of the declaration patterns above. None currently do, since
# those are '%define', not ':' or 'res*/d*'. This is just belt-and-suspenders.
foreach ($r in $RegisterAliases) { [void]$MemLabels.Remove($r) }

if ($PtrLabels.Count -eq 0) {
    Write-Host "WARNING: found zero 'resPTR' declarations across $($ResolvedFiles.Count) file(s)."
    Write-Host "         Either the input file list is wrong, or this check needs updating --"
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
# SPC700.asm's own aliases for it (RAM, S). Used by Check 4 to catch an omitted scratch argument
# (which defaults to PDI) colliding with PDI used elsewhere in the same IdxSt/IdxLd/IdxLdX/IdxUn/
# LblOp call.
$PdiAliasSet = New-Object System.Collections.Generic.HashSet[string] ([StringComparer]::OrdinalIgnoreCase)
foreach ($r in @('PDI', 'RDI', 'EDI', 'RAM', 'S')) { [void]$PdiAliasSet.Add($r) }

# Argument counts and 1-indexed danger-argument positions (counting the op mnemonic as argument 1)
# for each macro whose optional trailing scratch-register argument defaults to PDI. Min is the
# argument count when that scratch argument is omitted -- Check 4 only looks at calls of exactly
# this length, since an explicit scratch argument (Min+1) already sidesteps the whole problem.
# IdxLd/IdxLdX omit their 'val' argument from DangerPositions: loading straight into PDI is the
# macro's documented, intentionally-handled case, not a collision.
$PdiScratchMacros = @{
    'IdxSt'  = @{ Min = 4; DangerPositions = @(3, 4) }  # op,label,index,val
    'IdxLd'  = @{ Min = 4; DangerPositions = @(4) }     # op,val,label,index
    'IdxLdX' = @{ Min = 5; DangerPositions = @(5) }     # op,val,size,label,index
    'IdxUn'  = @{ Min = 3; DangerPositions = @(3) }     # op,label,index
    'LblOp'  = @{ Min = 3; DangerPositions = @(2) }     # op,reg,label
}

# --- Pass 2: scan every line of every file for the four violation patterns -----------------------
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
            $Violations.Add("${fileName}:${lineNum}: LoadPtr targets bare register $($Matches[1]), should be a P-alias -- $($code.Trim())")
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
                    $Violations.Add("${fileName}:${lineNum}: ${reason} -- $($code.Trim())")
                }
            }
        }

        # Check 3: any '[...]' bracket on this line that combines a real memory label with a
        # register or SPC700.asm register alias token, i.e. label+index written directly instead
        # of via IdxSt/IdxLd/IdxLdX/IdxUn/LblOp/LblSt. Tokenize each bracket's contents on +/-/*
        # (sign is discarded, only token identity matters for classification) and classify each
        # token as a number, a known register/alias, or a plain symbol by elimination. Flag the
        # bracket only if it contains a real memory label and a register. A bracket combining a
        # label with only numbers or EQU constants is fine as-is: those fold into the instruction
        # as an immediate displacement, which plain RIP-relative addressing already handles fine.
        # Runs independently of Check 1/2, and of whether any resPTR label exists at all, since it
        # works off $MemLabels, not $PtrLabels.
        foreach ($bm in [regex]::Matches($code, '\[([^\[\]]+)\]')) {
            $tokens = $bm.Groups[1].Value -split '[+\-*]' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
            $foundLabel = $null
            $foundReg = $null
            foreach ($tok in $tokens) {
                if ($tok -match '^(0x[0-9A-Fa-f]+|[0-9][0-9A-Fa-f]*h|[01]+b|[0-7]+o|[0-9]+)$') { continue }
                if ($RegisterSet.Contains($tok)) { $foundReg = $tok; continue }
                if ($MemLabels.Contains($tok)) { $foundLabel = $tok; continue }
                # Neither a number, a known register/alias, nor a collected memory label. Most
                # likely an EQU constant or an unrelated identifier. Not something this check can
                # classify with confidence, so it is silently ignored rather than guessed at.
            }
            if ($foundLabel -and $foundReg) {
                # Pick the one macro that actually fits this bracket's position in the instruction,
                # instead of just listing all four. The bracket's role (destination, source, or the
                # only operand) is read from where it sits relative to the operand-separating comma:
                # nothing before the bracket but something after it is 'op [mem],val' (a store); a
                # comma before it is 'op val,[mem]' (a load); neither is 'op [mem]' alone (unary). A
                # size keyword (dword/word/byte/qword) directly in front of the bracket becomes part
                # of the recommended macro's 'op' argument, and additionally picks IdxLdX over IdxLd
                # for the load case, since IdxLd's template has no room for that keyword.
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
                $Violations.Add("${fileName}:${lineNum}: raw '[$($bm.Groups[1].Value)]' combines memory label '$foundLabel' with register '$foundReg' directly, use $recommended -- $($code.Trim())")
            }
        }

        # Check 4: an IdxSt/IdxLd/IdxLdX/IdxUn/LblOp call whose omitted scratch-register argument
        # defaults to PDI, on a line where one of that same call's other arguments is also PDI (or
        # an alias of it: RAM/S from SPC700.asm's register-alias block, or the bare EDI/RDI spelling
        # of the same physical register). The macro's Push/LoadPtr sequence overwrites the scratch
        # register with the label's address before the rest of the instruction runs, so if that
        # register is also the index (or, for LblOp, the combined register), its real value is gone
        # by the time it is used. IdxLd/IdxLdX exempt their 'val' argument from this: loading straight
        # into PDI is the macro's documented, intentionally-handled case (see their %ifnidni branch),
        # so only 'index' is checked there. LblOp has no such exception: 'reg' as PDI is always wrong
        # with a PDI scratch, since the combine happens after the scratch overwrite either way.
        foreach ($spec in $PdiScratchMacros.GetEnumerator()) {
            if ($code -notmatch "(?i)\b$($spec.Key)\s+(.*)$") { continue }
            $argsText = $Matches[1]
            $args = $argsText -split ',' | ForEach-Object { $_.Trim() }
            if ($args.Count -ne $spec.Value.Min) { continue } # scratch arg was passed explicitly, or this isn't a real call
            foreach ($pos in $spec.Value.DangerPositions) {
                if ($pos -gt $args.Count) { continue }
                $argTokens = $args[$pos - 1] -split '[+\-*]' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
                if ($argTokens | Where-Object { $PdiAliasSet.Contains($_) }) {
                    $Violations.Add("${fileName}:${lineNum}: $($spec.Key) omits its scratch-register argument (defaults to PDI) while also using PDI in argument $pos -- pass an explicit different scratch register -- $($code.Trim())")
                    break
                }
            }
        }
    }
}

Write-Host ''
if ($Violations.Count -eq 0) {
    Write-Host 'OK: no leftover x86-only pointer-width notation found.'
    exit 0
}
else {
    foreach ($v in $Violations) { Write-Host "VIOLATION: $v" }
    Write-Host ''
    Write-Host "$($Violations.Count) potential pointer-width violation(s) found -- review each by hand before fixing."
    exit 1
}
