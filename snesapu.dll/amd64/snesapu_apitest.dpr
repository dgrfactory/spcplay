{===================================================================================================
 Program:    snesapu_apitest, headless x86/x64 SNESAPU.DLL full-API comparison tool
 Platform:   Win32 or Win64 (same source, built once per architecture)

 snesapu_pcmdump.dpr exercises only 5 of the DLL's 29 exported functions plus InitAPU (fired
 implicitly by LoadLibrary).  This tool is a superset.  It calls every function in SNESAPU.def in a
 single deterministic run, interleaving the state-mutating ones into the normal EmuAPU playback loop
 at fixed sample-count checkpoints.  Any divergence between the x86 and x64 build then shows up as a
 byte difference in the final PCM file, the same methodology snesapu_pcmdump.dpr uses: SPC emulation
 is fully deterministic given the same call sequence, so two builds fed the identical calls at the
 identical sample offsets must produce byte-for-byte identical PCM, or something diverges.

 What this tool additionally checks, beyond a plain PCM diff:
   - GetSNESAPUContext/SetSNESAPUContext: the context blob's layout depends on pointer width, so an
     x86 blob and an x64 blob are not expected to match byte-for-byte even when both are correct.
     Instead this does a within-build round-trip: snapshot context, play N samples (segment X, goes
     into the main PCM stream), restore the snapshot, play N samples again into a scratch buffer
     (segment Y), and compare X to Y in-process.  If both functions are correct, X and Y must be
     identical.  This check runs, and must pass, on each build independently.
   - FixAPU: intended for a caller that has restored SPC700 registers and RAM some other way, such
     as from a save state, and needs the DLL to resync its derived internal state.  Tested the same
     way as the context round-trip, but restoring raw state via GetAPUData's ppRAM pointer, a direct
     64KB memcpy (the realistic way a save-state loader would do it, since SetAPURAM one byte at a
     time would be impractically slow), plus GetSPCRegs/FixAPU for the register side.
   - SetDSPDbg (pTrace) and SetSPCDbg (pDebug): unlike SNESAPUCallback, these two callbacks do not
     go through x64.inc's ExtCall.  They are invoked via a raw push-args-then-call sequence with a
     hand-rolled, non-ABI-standard stack protocol (see DSP.asm's DSPIn and SPC700.asm's SPCBreak/
     SPCTrace).  A normal Pascal stdcall/cdecl function does not receive these correctly on x64: the
     Windows x64 ABI always expects the first 4 int/pointer args in RCX/RDX/R8/R9 regardless of the
     source-level calling-convention keyword, with no mode to read the first args from the stack.
     So the callbacks below are written as raw assembler/nostackframe stubs that touch nothing but
     a call counter and ret, a minimal no-op passthrough.  This is a real test even doing nothing:
     if the amd64 port's hand-rolled push sequence violates the Windows x64 ABI's mandatory 16-byte
     stack alignment at each CALL, or miscounts the pushed slot width or count, the callback round-
     trip is exactly where that would surface as a crash or corrupted emulation state.  See
     DspTraceStub/SpcTraceStub below for the exact stack-slot layout this was reverse-engineered
     from.
   - GetAPUData's plain-data outputs (RAM, extra RAM, DSP register array, output ports) are hashed
     and logged, not just checked for non-NULL, see HashMem's comment.  SetDSPReg is swept across
     all 256 addresses, folded into one hash.  SetAPUOpt is exercised with several bit depth,
     channel, rate, and interpolation combinations, not just the one format used for the rest of
     the run.  SeekAPU is exercised with both fast=0 and fast=1.  GetSPCRegs' output values are
     logged directly.  The context round-trip snapshots, plays an unrelated further stretch, then
     restores, so it proves a genuine rewind rather than an immediate undo of the step right before
     the restore.

 Build (once per architecture):
   fpc -Pi386   -Twin32 snesapu_apitest.dpr
   fpc -Px86_64 -Twin64 snesapu_apitest.dpr

 Usage:
   snesapu_apitest.exe <dll path> <spc file path> <out pcm path> <sample count> [script700 file]

 Compare two runs (one per architecture, same .spc, same sample count):
   snesapu_apitest_x86.exe snesapu.dll       song.spc out_x86.pcm 2000000
   snesapu_apitest_x64.exe snesapu_amd64.dll song.spc out_x64.pcm 2000000
   fc /b out_x86.pcm out_x64.pcm
   fc /b out_x86.log out_x64.log

 Then compare the two runs' log files (see LogPath below) for the text-comparable values:
 SNESAPUInfo, GetScript700Data's version string, SetAPULength's returned total, the context/FixAPU
 round-trip hashes, the callback fire counts.  GetSNESAPUContextSize's byte count is expected to
 differ between x86/x64 (see above); the log marks that line accordingly, it is not a failure.
===================================================================================================}

program snesapu_apitest;

{$MODE DELPHI}
{$APPTYPE CONSOLE}
{$ASMMODE INTEL}

uses
  Windows, SysUtils;

type
  // Function pointer types, one per SNESAPU.def export.  SetScript700Data isn't wired into a
  // meaningful Script700 program here, only exercised for pointer/return-code sanity.
  TSNESAPUInfo            = procedure(pVer, pMin, pOpt: Pointer); stdcall;
  TSNESAPUCallback        = function(pCbFunc: Pointer; cbMask: Cardinal): Pointer; stdcall;
  TGetAPUData             = procedure(ppRAM, ppXRAM, ppOutPort, ppT64Cnt, ppDSP, ppVoice, ppVMMaxL, ppVMMaxR: Pointer); stdcall;
  TGetScript700Data       = procedure(pDLLVer, ppSPCReg, ppScript700: Pointer); stdcall;
  TResetAPU               = procedure(amp: Cardinal); stdcall;
  TFixAPU                 = procedure(pc: Word; a, y, x, psw, s: Byte); stdcall;
  TLoadSPCFile            = procedure(pSPC: Pointer); stdcall;
  TSetAPUOpt              = procedure(mixType, numChn, bits, rate, inter, opts: Cardinal); stdcall;
  TSetAPUSmpClk           = procedure(speed: Cardinal); stdcall;
  TSetAPULength           = function(song, fade: Cardinal): Cardinal; stdcall;
  TEmuAPU                 = function(pBuf: Pointer; len: Cardinal; ltype: Byte): Pointer; stdcall;
  TSeekAPU                = procedure(time: Cardinal; fast: Byte); stdcall;
  TSetTimerTrick          = procedure(port, wait: Cardinal); stdcall;
  TSetScript700           = function(pSource: Pointer): Cardinal; stdcall;
  TSetScript700Data       = function(addr: Cardinal; pData: Pointer; size: Cardinal): Cardinal; stdcall;
  TGetSNESAPUContextSize  = function: Cardinal; stdcall;
  TGetSNESAPUContext      = procedure(pCtxOut: Pointer); stdcall;
  TSetSNESAPUContext      = procedure(pCtxIn: Pointer); stdcall;
  TSetDSPAmp              = procedure(amp: Cardinal); stdcall;
  TSetDSPDbg              = function(pTrace: Pointer): Pointer; stdcall;
  TSetDSPEFBCT            = procedure(leak: Cardinal); stdcall;
  TSetDSPPitch            = procedure(base: Cardinal); stdcall;
  TSetDSPReg              = function(reg, val: Byte): Byte; stdcall;
  TSetDSPStereo           = procedure(sep: Cardinal); stdcall;
  TSetDSPVol              = procedure(vol: Cardinal); stdcall;
  TSetSPCDbg              = function(pTrace: Pointer; opts: Cardinal): Pointer; stdcall;
  TGetSPCRegs             = procedure(pPC, pA, pY, pX, pPSW, pSP: Pointer); stdcall;
  TSetAPURAM              = procedure(addr: Cardinal; val: Byte); stdcall;
  TInPort                 = procedure(addr, val: Byte); stdcall;

  TAPUCallback = function(effect, addr, value: Cardinal; lpData: Pointer): Cardinal; stdcall;

const
  SPC_FILE_SIZE   = 66048;
  CHUNK_SAMPLES   = 4096;
  // 4 bytes/channel (bits=-32, IEEE-754 float, matches the SetAPUOpt call below) times 2 channels.
  BYTES_PER_FRAME = 8;
  CBE_DSPREG      = $01;
  CBE_S700FCH     = $02;
  SPC_TRACE       = $10;
  // Interpolation types and a DSP option flag, for the SetAPUOpt variation sweep (see DSP.inc).
  INT_NONE        = 0;
  INT_LINEAR      = 1;
  INT_CUBIC       = 2;
  INT_SINC        = 4;
  INT_GAUSS4      = 7;
  DSP_ANALOG      = $01;

var
  hDLL: THandle;
  pSNESAPUInfo: TSNESAPUInfo;
  pSNESAPUCallback: TSNESAPUCallback;
  pGetAPUData: TGetAPUData;
  pGetScript700Data: TGetScript700Data;
  pResetAPU: TResetAPU;
  pFixAPU: TFixAPU;
  pLoadSPCFile: TLoadSPCFile;
  pSetAPUOpt: TSetAPUOpt;
  pSetAPUSmpClk: TSetAPUSmpClk;
  pSetAPULength: TSetAPULength;
  pEmuAPU: TEmuAPU;
  pSeekAPU: TSeekAPU;
  pSetTimerTrick: TSetTimerTrick;
  pSetScript700: TSetScript700;
  pSetScript700Data: TSetScript700Data;
  pGetSNESAPUContextSize: TGetSNESAPUContextSize;
  pGetSNESAPUContext: TGetSNESAPUContext;
  pSetSNESAPUContext: TSetSNESAPUContext;
  pSetDSPAmp: TSetDSPAmp;
  pSetDSPDbg: TSetDSPDbg;
  pSetDSPEFBCT: TSetDSPEFBCT;
  pSetDSPPitch: TSetDSPPitch;
  pSetDSPReg: TSetDSPReg;
  pSetDSPStereo: TSetDSPStereo;
  pSetDSPVol: TSetDSPVol;
  pSetSPCDbg: TSetSPCDbg;
  pGetSPCRegs: TGetSPCRegs;
  pSetAPURAM: TSetAPURAM;
  pInPort: TInPort;

  DllPath, SpcPath, OutPath, Script700Path: String;
  TotalSamples: Cardinal;
  SpcData: array[0..SPC_FILE_SIZE-1] of Byte;
  Buf: array[0..CHUNK_SAMPLES*BYTES_PER_FRAME-1] of Byte;
  fSpc, fOut: File;
  BytesRead, BytesWritten: LongInt;
  TotalWritten: Int64;
  SamplesDone: Int64;
  DspCallbackCount, SpcFetchCallbackCount: Int64;
  DspTraceCount, SpcTraceCount: Cardinal;
  FailCount: Integer;

  // GetAPUData results.  Every "pp"-prefixed param is pointer-to-pointer, the DLL writes back an
  // internal address, so each of these captures a Pointer, not a value.
  gRAM, gXRAM, gOutPort, gT64Cnt, gDSP, gVoice, gVMMaxL, gVMMaxR: Pointer;

  // Log file.  A console transcript is easy to skim past a mismatch in.  A line-oriented KEY=VALUE
  // log lets 'fc'/'diff' catch a divergence between the x86 and x64 run automatically, the same way
  // byte-diffing the PCM output already does for the audio itself.
  fLog: TextFile;
  LogPath: String;
  PcmHash: Cardinal;

  // Scratch used by several phases below.
  CtxSize: Cardinal;
  CtxBuf: array of Byte;
  SegX, SegY: array of Byte;
  SegLen: Cardinal;
  SavedRAM: array of Byte;
  RegPC: Word;
  RegA, RegY, RegX, RegPSW, RegSP: Byte;

// =====================================================================================================
// Utility

function YN(b: Boolean): String;
begin
  if b then Result := 'yes' else Result := 'no';
end;

// FNV-1a 32-bit.  Not cryptographic, just a cheap, deterministic change-detector so a value too
// large to print, such as a PCM segment or the whole output stream, still reduces to one comparable
// log line.  Seed is threaded through explicitly so a long stream can be hashed incrementally,
// chunk by chunk, and get the same result as hashing it all at once.  Pass FNV32_SEED for a fresh,
// standalone hash such as one isolated segment, or the previous call's Result to continue an
// ongoing stream hash such as PcmHash across every chunk written to the output file.
const
  FNV32_SEED = Cardinal($811C9DC5);

function Hash32(Seed: Cardinal; const Buf; Len: NativeUInt): Cardinal;
var
  P: PByte;
  i: NativeUInt;
begin
  P := PByte(@Buf);
  Result := Seed;
  for i := 0 to Len - 1 do
  begin
    Result := Result xor P[i];
    Result := Result * 16777619;
  end;
end;

// Hashes Len bytes starting at P.  Used for GetAPUData's plain-data outputs (RAM, extra RAM, DSP
// register array, output ports): none of these embed pointers, so their raw content is directly
// comparable between x86 and x64, unlike the Voice array, which is deliberately not hashed this
// way (its sIdx/bCur fields are real pointers on x86 but u32 offsets on x64, by design).
function HashMem(P: Pointer; Len: NativeUInt): Cardinal;
begin
  Result := Hash32(FNV32_SEED, PByte(P)^, Len);
end;

// Renders Len bytes starting at P as a plain hex string, for the rare case a hash mismatch needs
// eyeballing byte-by-byte instead of just knowing it exists.  Only meant for small regions.
function HexDump(P: Pointer; Len: NativeUInt): String;
var
  i: NativeUInt;
begin
  Result := '';
  for i := 0 to Len - 1 do
    Result := Result + IntToHex(PByte(P)[i], 2);
end;

// Writes to both the console, for a human watching it run, and the log file, for 'fc'/'diff'
// against the other architecture's run afterward.  Every line that should be identical between
// the x86 and x64 runs goes through this, in a fixed order, so the two log files line up 1:1.
procedure LogLine(const Line: String);
begin
  WriteLn(Line);
  WriteLn(fLog, Line);
end;

procedure LogKV(const Key, Value: String);
begin
  LogLine(Key + '=' + Value);
end;

procedure Info(const Msg: String);
begin
  LogLine('  ' + Msg);
end;

procedure Ok(const Msg: String);
begin
  LogLine('OK:   ' + Msg);
end;

procedure Warn(const Msg: String);
begin
  LogLine('WARN: ' + Msg);
end;

procedure Fail(const Msg: String);
begin
  LogLine('FAIL: ' + Msg);
  Inc(FailCount);
end;

procedure FatalFail(const Msg: String);
begin
  WriteLn('ERROR: ', Msg);
  Halt(1);
end;

function LoadTextFile(const Path: String): AnsiString;
var
  f: File;
  Size, Got: LongInt;
begin
  AssignFile(f, Path);
  {$I-}
  Reset(f, 1);
  {$I+}
  if IOResult <> 0 then
    FatalFail(Format('Could not open Script700 file "%s"', [Path]));

  Size := FileSize(f);
  SetLength(Result, Size);
  if Size > 0 then
  begin
    BlockRead(f, Result[1], Size, Got);
    if Got <> Size then
      FatalFail(Format('Short read on Script700 file "%s" (got %d of %d bytes)', [Path, Got, Size]));
  end;
  CloseFile(f);
  Result := Result + #0;
end;

// =====================================================================================================
// Callbacks

// SNESAPUCallback: standard ExtCall path, same protocol snesapu_pcmdump.dpr already exercises.
// Registered here for both CBE_DSPREG and CBE_S700FCH so this run also covers the fetch-event mask
// that pcmdump never set.
function APUCallback(effect, addr, value: Cardinal; lpData: Pointer): Cardinal; stdcall;
begin
  if effect = CBE_S700FCH then
    Inc(SpcFetchCallbackCount)
  else
    Inc(DspCallbackCount);
  Result := value;
end;

// SetDSPDbg's pTrace, not ExtCall.  Reverse-engineered from DSP.asm's DSPIn, the only call site:
//    Push PAX  (value byte, zero-extended into a pointer-width slot)
//    Push PBX  (pointer into the 'dsp' register array, itself becomes the pointer)
//    Call PDX
//    Pop PBX
//    Pop PAX
// So at entry: [ESP/RSP + PTRSIZE] = dsp-register pointer, [ESP/RSP + 2*PTRSIZE] = value.  The
// caller pops both back itself, no 'ret N', and never inspects a return value, so this is a pure
// read-only notification hook: a correct passthrough does not need to touch the stack at all.
// Kept as a true no-op, just a counter, rather than reading the args, to minimize the risk of
// getting the raw-asm offset math wrong in a way that would corrupt state instead of just failing
// to log a value.  On Win64 the address is loaded through an explicit 'lea rax, [rip+Symbol]'
// rather than referencing DspTraceCount directly as a memory operand: FPC's inline assembler does
// not default to RIP-relative addressing just because the reference sits inside a lea, the 'rip'
// keyword has to be written out, or it silently falls back to a 32-bit absolute displacement (this
// is not hypothetical: two earlier versions, one without the lea at all and one with a bare 'lea
// rax, [Symbol]', both crashed with STATUS_ACCESS_VIOLATION on the very first EmuAPU call, because
// Windows x64 commonly loads a module far above the 4GB an absolute 32-bit displacement can reach).
// EAX/RAX is safe to clobber here: DSP.asm's DSPIn explicitly saves and restores PAX/PBX around
// this call, so whatever this stub leaves in RAX is discarded regardless.
procedure DspTraceStub; assembler; nostackframe;
asm
  {$IFDEF CPU64}
  lea rax, [rip+DspTraceCount]
  inc dword ptr [rax]
  {$ELSE}
  lea eax, [DspTraceCount]
  inc dword ptr [eax]
  {$ENDIF}
  ret
end;

// SetSPCDbg's pDebug, not ExtCall either.  Reverse-engineered from SPC700.asm's SPCBreak, the only
// call site, pushed in this order (first Push = deepest on the stack):
//    Push PBX  (t0Step, zero-extended.  Byte index 3 of this slot is overwritten afterward with
//               an extra informational cycle-count byte.  This 6th slot is discarded by the
//               caller, never popped back into a real register, so it is not part of the
//               writable state)
//    Push [regSP]  (SP)
//    Push PDX  (PSW, in DL)
//    Push PCX  (X, in CL)
//    Push PAX  (YA)
//    Push PSI  (PC)
//    Call [pDebug]
//    Pop PAX (PC) / Pop PAX (YA) / Pop PCX (X) / Pop PDX (PSW) / Pop PDX (SP) / Pop PDX (discard)
// So at entry: [PTRSIZE]=PC, [2*PTRSIZE]=YA, [3*PTRSIZE]=X, [4*PTRSIZE]=PSW, [5*PTRSIZE]=SP,
// [6*PTRSIZE]=informational counter byte.  The caller pops all 6 back itself, no 'ret N'.  Per the
// doc comment in SPC700.asm, a real debugger is expected to read and overwrite these to steer
// execution.  This stub intentionally leaves them untouched, a no-op is well-defined, valid
// behavior for a debug hook, so this is again a minimal passthrough exercising only the raw
// call/return round-trip, not the register-mutation semantics.  The address is loaded through an
// explicit 'lea rax, [rip+Symbol]' on Win64, same reasoning as DspTraceStub above: the 'rip'
// keyword must be written out or FPC's inline assembler falls back to a 32-bit absolute
// displacement that breaks once the module loads above 4GB, which Windows x64 commonly does.
// RAX/RCX/RDX are safe to clobber here: SPC700.asm's SPCBreak reloads all three from the stack via
// Pop immediately after this call regardless of what this stub leaves in them.
procedure SpcTraceStub; assembler; nostackframe;
asm
  {$IFDEF CPU64}
  lea rax, [rip+SpcTraceCount]
  inc dword ptr [rax]
  {$ELSE}
  lea eax, [SpcTraceCount]
  inc dword ptr [eax]
  {$ENDIF}
  ret
end;

// =====================================================================================================
// Playback helpers

// Plays SamplesToPlay samples through EmuAPU, CHUNK_SAMPLES at a time, reusing the single-chunk-
// sized global Buf, writing each piece straight to fOut as it comes back.  Safe to call with any
// sample count, never accumulates more than one chunk in Buf at a time.
procedure WriteChunkToFile(SamplesToPlay: Cardinal);
var
  Left, This: Cardinal;
  E: Pointer;
  Written: NativeUInt;
begin
  Left := SamplesToPlay;
  while Left > 0 do
  begin
    if Left > CHUNK_SAMPLES then This := CHUNK_SAMPLES else This := Left;
    try
      E := pEmuAPU(@Buf[0], This, 1);
    except
      on Ex: Exception do
        FatalFail(Format('EmuAPU raised %s ("%s")', [Ex.ClassName, Ex.Message]));
    end;
    Written := NativeUInt(E) - NativeUInt(@Buf[0]);
    if Written > SizeOf(Buf) then
      FatalFail(Format('EmuAPU reported %d bytes, exceeding the %d-byte scratch buffer', [Written, SizeOf(Buf)]));
    BlockWrite(fOut, Buf[0], Written, BytesWritten);
    if Cardinal(BytesWritten) <> Cardinal(Written) then
      FatalFail('Write to output file failed');
    PcmHash := Hash32(PcmHash, Buf, Written);
    Inc(TotalWritten, Written);
    Inc(SamplesDone, This);
    Dec(Left, This);
  end;
end;

// Plays exactly SamplesToPlay samples into DestBuf, which must be sized to hold exactly
// SamplesToPlay*BYTES_PER_FRAME bytes.  Used only by the round-trip segments below, where the
// destination is pre-sized to match.  Unlike WriteChunkToFile, does not touch fOut.
procedure EmulateChunk(SamplesToPlay: Cardinal; DestBuf: Pointer);
var
  Left, This: Cardinal;
  P: PByte;
  E: Pointer;
begin
  P := PByte(DestBuf);
  Left := SamplesToPlay;
  while Left > 0 do
  begin
    if Left > CHUNK_SAMPLES then This := CHUNK_SAMPLES else This := Left;
    try
      E := pEmuAPU(P, This, 1);
    except
      on Ex: Exception do
        FatalFail(Format('EmuAPU raised %s ("%s")', [Ex.ClassName, Ex.Message]));
    end;
    P := PByte(E);
    Dec(Left, This);
    Inc(SamplesDone, This);
  end;
end;

// =====================================================================================================
// Main

var
  Ver, Min, Opt: Cardinal;
  DLLVer: array[0..31] of AnsiChar;
  pSPCReg, pScript700: Pointer;
  TotalLen: Cardinal;
  TestScript: AnsiString;
  ScriptResult: Cardinal;
  Blob: array[0..15] of Byte;
  BlobIdx: Integer;
  DataRes: Cardinal;
  DSPRegResult: Byte;
  RegIdx: Integer;
  DSPSweepHash: Cardinal;
  RemainingSamples: Int64;

begin
  FailCount := 0;
  DspCallbackCount := 0;
  SpcFetchCallbackCount := 0;
  DspTraceCount := 0;
  SpcTraceCount := 0;
  SamplesDone := 0;
  TotalWritten := 0;

  if ParamCount < 4 then
  begin
    WriteLn('Usage: snesapu_apitest <dll path> <spc file path> <out pcm path> <sample count> ',
            '[script700 file path]');
    Halt(1);
  end;

  DllPath  := ParamStr(1);
  SpcPath  := ParamStr(2);
  OutPath  := ParamStr(3);
  TotalSamples := StrToInt(ParamStr(4));
  if ParamCount >= 5 then
    Script700Path := ParamStr(5)
  else
    Script700Path := '';

  // Open the log file first.  Every Info/Ok/Warn/Fail/LogKV call from here on goes to it, so a
  // line-by-line 'fc'/'diff' of this run's log against the other architecture's run is the primary
  // way to catch a behavioral difference that the PCM byte-diff alone would not surface.
  LogPath := ChangeFileExt(OutPath, '.log');
  AssignFile(fLog, LogPath);
  {$I-}
  Rewrite(fLog);
  {$I+}
  if IOResult <> 0 then
    FatalFail(Format('Could not create log file "%s"', [LogPath]));
  PcmHash := FNV32_SEED;

  // Load the DLL and resolve every export.
  hDLL := LoadLibrary(PChar(DllPath));
  if hDLL = 0 then
    FatalFail(Format('LoadLibrary failed for "%s" (GetLastError=%d)', [DllPath, GetLastError]));
  Ok('LoadLibrary succeeded (InitAPU fired implicitly via DllMain)');

  pSNESAPUInfo            := TSNESAPUInfo(GetProcAddress(hDLL, 'SNESAPUInfo'));
  pSNESAPUCallback        := TSNESAPUCallback(GetProcAddress(hDLL, 'SNESAPUCallback'));
  pGetAPUData             := TGetAPUData(GetProcAddress(hDLL, 'GetAPUData'));
  pGetScript700Data       := TGetScript700Data(GetProcAddress(hDLL, 'GetScript700Data'));
  pResetAPU               := TResetAPU(GetProcAddress(hDLL, 'ResetAPU'));
  pFixAPU                 := TFixAPU(GetProcAddress(hDLL, 'FixAPU'));
  pLoadSPCFile            := TLoadSPCFile(GetProcAddress(hDLL, 'LoadSPCFile'));
  pSetAPUOpt              := TSetAPUOpt(GetProcAddress(hDLL, 'SetAPUOpt'));
  pSetAPUSmpClk           := TSetAPUSmpClk(GetProcAddress(hDLL, 'SetAPUSmpClk'));
  pSetAPULength           := TSetAPULength(GetProcAddress(hDLL, 'SetAPULength'));
  pEmuAPU                 := TEmuAPU(GetProcAddress(hDLL, 'EmuAPU'));
  pSeekAPU                := TSeekAPU(GetProcAddress(hDLL, 'SeekAPU'));
  pSetTimerTrick          := TSetTimerTrick(GetProcAddress(hDLL, 'SetTimerTrick'));
  pSetScript700           := TSetScript700(GetProcAddress(hDLL, 'SetScript700'));
  pSetScript700Data       := TSetScript700Data(GetProcAddress(hDLL, 'SetScript700Data'));
  pGetSNESAPUContextSize  := TGetSNESAPUContextSize(GetProcAddress(hDLL, 'GetSNESAPUContextSize'));
  pGetSNESAPUContext      := TGetSNESAPUContext(GetProcAddress(hDLL, 'GetSNESAPUContext'));
  pSetSNESAPUContext      := TSetSNESAPUContext(GetProcAddress(hDLL, 'SetSNESAPUContext'));
  pSetDSPAmp              := TSetDSPAmp(GetProcAddress(hDLL, 'SetDSPAmp'));
  pSetDSPDbg              := TSetDSPDbg(GetProcAddress(hDLL, 'SetDSPDbg'));
  pSetDSPEFBCT            := TSetDSPEFBCT(GetProcAddress(hDLL, 'SetDSPEFBCT'));
  pSetDSPPitch            := TSetDSPPitch(GetProcAddress(hDLL, 'SetDSPPitch'));
  pSetDSPReg              := TSetDSPReg(GetProcAddress(hDLL, 'SetDSPReg'));
  pSetDSPStereo           := TSetDSPStereo(GetProcAddress(hDLL, 'SetDSPStereo'));
  pSetDSPVol              := TSetDSPVol(GetProcAddress(hDLL, 'SetDSPVol'));
  pSetSPCDbg              := TSetSPCDbg(GetProcAddress(hDLL, 'SetSPCDbg'));
  pGetSPCRegs             := TGetSPCRegs(GetProcAddress(hDLL, 'GetSPCRegs'));
  pSetAPURAM              := TSetAPURAM(GetProcAddress(hDLL, 'SetAPURAM'));
  pInPort                 := TInPort(GetProcAddress(hDLL, 'InPort'));

  if not (Assigned(pSNESAPUInfo) and Assigned(pSNESAPUCallback) and Assigned(pGetAPUData) and
    Assigned(pGetScript700Data) and Assigned(pResetAPU) and Assigned(pFixAPU) and
    Assigned(pLoadSPCFile) and Assigned(pSetAPUOpt) and Assigned(pSetAPUSmpClk) and
    Assigned(pSetAPULength) and Assigned(pEmuAPU) and Assigned(pSeekAPU) and
    Assigned(pSetTimerTrick) and Assigned(pSetScript700) and Assigned(pSetScript700Data) and
    Assigned(pGetSNESAPUContextSize) and Assigned(pGetSNESAPUContext) and
    Assigned(pSetSNESAPUContext) and Assigned(pSetDSPAmp) and Assigned(pSetDSPDbg) and
    Assigned(pSetDSPEFBCT) and Assigned(pSetDSPPitch) and Assigned(pSetDSPReg) and
    Assigned(pSetDSPStereo) and Assigned(pSetDSPVol) and Assigned(pSetSPCDbg) and
    Assigned(pGetSPCRegs) and Assigned(pSetAPURAM) and Assigned(pInPort)) then
    FatalFail('GetProcAddress failed for one or more exports -- see SNESAPU.def');
  Ok('All 29 exports resolved');

  // SNESAPUInfo: compile-time-constant values, must match between builds.
  pSNESAPUInfo(@Ver, @Min, @Opt);
  LogKV('SNESAPUInfo_Ver', Format('0x%x', [Ver]));
  LogKV('SNESAPUInfo_Min', Format('0x%x', [Min]));
  LogKV('SNESAPUInfo_Opt', Format('0x%x', [Opt]));

  // GetScript700Data: pDLLVer is a 32-byte ASCII string, directly comparable across builds.
  FillChar(DLLVer, SizeOf(DLLVer), 0);
  pGetScript700Data(@DLLVer[0], @pSPCReg, @pScript700);
  LogKV('GetScript700Data_DLLVer', string(PAnsiChar(@DLLVer[0])));
  LogKV('GetScript700Data_pSPCReg_NonNull', YN(pSPCReg <> nil));
  LogKV('GetScript700Data_pScript700_NonNull', YN(pScript700 <> nil));

  // GetAPUData: capture pointers now, used later for the FixAPU round-trip.  The pointer values
  // themselves are addresses, never expected to match between architectures or even between two
  // runs of the same build thanks to ASLR, so only non-NULL-ness is logged here.
  pGetAPUData(@gRAM, @gXRAM, @gOutPort, @gT64Cnt, @gDSP, @gVoice, @gVMMaxL, @gVMMaxR);
  if (gRAM = nil) or (gDSP = nil) or (gVoice = nil) then
    Fail('GetAPUData returned a NULL pointer for RAM/DSP/Voice')
  else
    Ok('GetAPUData: all pointers non-NULL');

  // Register callbacks.  SNESAPUCallback is standard ExtCall.  SetDSPDbg/SetSPCDbg are the raw-
  // stack passthrough stubs, see their comments above.
  pSNESAPUCallback(@APUCallback, CBE_DSPREG or CBE_S700FCH);
  pSetDSPDbg(@DspTraceStub);
  pSetSPCDbg(@SpcTraceStub, SPC_TRACE);
  Ok('SNESAPUCallback / SetDSPDbg / SetSPCDbg registered');

  // ResetAPU: exercises the actual EXPROC entry point (InitAPU only calls the internal ResetAPUI
  // directly, never this wrapper).  Safe to call here: LoadSPCFile right below fully re-establishes
  // playback state on its own, so this reset has no lasting effect on the rest of the run.
  pResetAPU($10000);
  Ok('ResetAPU');

  // Load the .spc file.
  AssignFile(fSpc, SpcPath);
  {$I-}
  Reset(fSpc, 1);
  {$I+}
  if IOResult <> 0 then
    FatalFail(Format('Could not open "%s"', [SpcPath]));
  BlockRead(fSpc, SpcData, SPC_FILE_SIZE, BytesRead);
  CloseFile(fSpc);
  if BytesRead <> SPC_FILE_SIZE then
    FatalFail(Format('"%s" is %d bytes, expected exactly %d', [SpcPath, BytesRead, SPC_FILE_SIZE]));
  pLoadSPCFile(@SpcData[0]);
  Ok('LoadSPCFile');

  // SetAPULength: log the returned total, must match between builds.
  TotalLen := pSetAPULength(60 * 64000, 5 * 64000);
  LogKV('SetAPULength_Total', IntToStr(TotalLen));

  // Fixed, deterministic playback settings.
  pSetAPUOpt(1, 2, Cardinal(-32), 96000, 4, 0);
  pSetAPUSmpClk($10000);        // 1.0x, exercises the call, keeps timing unchanged from default

  // Open the main output file.
  AssignFile(fOut, OutPath);
  {$I-}
  Rewrite(fOut, 1);
  {$I+}
  if IOResult <> 0 then
    FatalFail(Format('Could not create "%s"', [OutPath]));

  // === Phase 1: a stretch of plain playback ===
  WriteChunkToFile(CHUNK_SAMPLES * 4);

  // Signal-derived scalars and GetAPUData content at a fixed, deterministic point in the stream.
  // If the audio output is bit-identical between builds up to here, which the PCM hash/diff
  // already checks, all of these must also match.  ppRAM/ppXRAM/ppDSP/ppOutPort/ppT64Cnt point at
  // plain data with no embedded pointers, so hashing their content directly is meaningful across
  // architectures (ppVoice is deliberately skipped, see HashMem's comment above).
  LogKV('Phase1_vMMaxL', IntToStr(PLongInt(gVMMaxL)^));
  LogKV('Phase1_vMMaxR', IntToStr(PLongInt(gVMMaxR)^));
  LogKV('Phase1_RAM_Hash', Format('%.8x', [HashMem(gRAM, $10000)]));
  LogKV('Phase1_XRAM_Hash', Format('%.8x', [HashMem(gXRAM, 64)]));
  LogKV('Phase1_XRAM_Hex', HexDump(gXRAM, 64));
  LogKV('Phase1_DSP_Hash', Format('%.8x', [HashMem(gDSP, 128)]));
  LogKV('Phase1_OutPort_Hash', Format('%.8x', [HashMem(gOutPort, 4)]));
  LogKV('Phase1_T64Cnt', IntToStr(PCardinal(gT64Cnt)^));

  // === Phase 2: SetAPUOpt variations ===
  // A handful of representative format/rate/interpolation combinations, each followed by a short
  // stretch of playback so the resulting bytes flow into the main PCM stream like everything else.
  // WriteChunkToFile sizes each write from EmuAPU's own returned span, not a fixed bytes/frame
  // assumption, so switching formats mid-stream is safe.  Buf is sized for the worst case, bits=-32
  // with 2 channels, 8 bytes/frame, which already covers every combination below.
  pSetAPUOpt(1, 1, 8, 8000, INT_NONE, 0);
  WriteChunkToFile(CHUNK_SAMPLES);
  pSetAPUOpt(1, 2, 16, 44100, INT_LINEAR, 0);
  WriteChunkToFile(CHUNK_SAMPLES);
  pSetAPUOpt(1, 2, 24, 48000, INT_CUBIC, 0);
  WriteChunkToFile(CHUNK_SAMPLES);
  pSetAPUOpt(1, 2, 32, 192000, INT_GAUSS4, DSP_ANALOG);
  WriteChunkToFile(CHUNK_SAMPLES);
  pSetAPUOpt(1, 2, Cardinal(-32), 96000, INT_SINC, 0);   // restore the format the rest of the run uses
  Ok('SetAPUOpt variation sweep called');

  // === Phase 3: DSP setter sweep ===
  // SetDSPStereo/SetDSPEFBCT/SetDSPPitch/SetDSPVol/SetDSPAmp, fixed test values, then a full sweep
  // of all 256 SetDSPReg addresses, then continue playback.  Any divergence these introduce shows
  // up in the PCM stream from here on.  DSPSweepHash folds in every result byte so the whole sweep
  // reduces to one comparable line instead of 256.
  pSetDSPStereo($8000);          // 0.5, normal separation, ~unchanged
  pSetDSPEFBCT($10000);          // 1.0, no crosstalk, SNES default
  pSetDSPPitch(32000);           // normal pitch
  pSetDSPVol($10000);            // no attenuation
  pSetDSPAmp($10000);            // 1.0x

  DSPSweepHash := FNV32_SEED;
  for RegIdx := 0 to 255 do
  begin
    DSPRegResult := pSetDSPReg(Byte(RegIdx), Byte(RegIdx));
    DSPSweepHash := Hash32(DSPSweepHash, DSPRegResult, SizeOf(DSPRegResult));
    if RegIdx = $26 then
      LogKV('SetDSPReg_MVOLL_Result', IntToStr(DSPRegResult));    // one concrete value alongside the hash
  end;
  LogKV('SetDSPReg_SweepHash', Format('%.8x', [DSPSweepHash]));
  Ok('DSP setter sweep called, including all 256 SetDSPReg addresses');
  WriteChunkToFile(CHUNK_SAMPLES * 4);

  // === Phase 4: SetAPURAM / InPort ===
  // Fixed, deterministic writes.  The values only need to match between builds, not to preserve
  // musical correctness, see the design note in the header.
  pSetAPURAM($0010, $00);
  pInPort($00, $00);
  Ok('SetAPURAM / InPort called');
  WriteChunkToFile(CHUNK_SAMPLES * 4);

  // === Phase 5: SetScript700 ===
  // Either a user-supplied file or a built-in comment-only smoke test.
  if Script700Path <> '' then
    TestScript := LoadTextFile(Script700Path)
  else
    TestScript := ';snesapu_apitest SetScript700 smoke test' + #0;
  ScriptResult := pSetScript700(PAnsiChar(TestScript));
  // Only comparable across builds when the same real Script700 file was supplied on the command
  // line.  The fallback built-in string's binary-conversion result depends on nothing arch-specific
  // either way, so it is still logged, just noted as such.
  LogKV('SetScript700_Result', IntToStr(ScriptResult));
  WriteChunkToFile(CHUNK_SAMPLES * 4);
  pSetScript700(nil);          // disable again so it doesn't affect the rest of the run

  // === Phase 6: SetScript700Data ===
  // Pointer/return-code sanity only, see header note.
  for BlobIdx := 0 to High(Blob) do Blob[BlobIdx] := BlobIdx;
  DataRes := pSetScript700Data(0, @Blob[0], SizeOf(Blob));
  LogKV('SetScript700Data_Result', IntToStr(DataRes));

  // === Phase 7: SetTimerTrick, enable briefly, then disable ===
  pSetTimerTrick(0, 1000);
  WriteChunkToFile(CHUNK_SAMPLES * 2);
  pSetTimerTrick(0, 0);          // wait=0 disables
  Ok('SetTimerTrick enabled/disabled');

  // === Phase 8: SeekAPU, both seek methods ===
  pSeekAPU(10 * 64000, 0);       // seek 10s forward, non-fast method
  Ok('SeekAPU (fast=0)');
  WriteChunkToFile(CHUNK_SAMPLES * 2);
  pSeekAPU(10 * 64000, 1);       // seek 10s forward again, fast method
  Ok('SeekAPU (fast=1)');
  WriteChunkToFile(CHUNK_SAMPLES * 2);

  // === Phase 9: GetSNESAPUContext / SetSNESAPUContext round-trip, distant snapshot ===
  // Snapshots at point P, plays segment X right after P, then plays a further, unrelated stretch,
  // simulating time passing after a save, before restoring to P and replaying the same length into
  // Y.  This shows the restore genuinely rewinds past the intervening stretch, not just undoing the
  // single step right above it.  X's hash is redundant with the main PCM diff, since X is also
  // written to the output file below, but Y is otherwise never persisted anywhere, so logging its
  // hash is what makes Y itself cross-architecture comparable.  A self-consistent-but-wrong restore
  // on one build alone would show up as a log diff here even though the X==Y check passed locally.
  CtxSize := pGetSNESAPUContextSize();
  LogLine(Format('GetSNESAPUContextSize=%d (IGNORE_ARCH_DIFF -- layout depends on pointer width)',
    [CtxSize]));
  SetLength(CtxBuf, CtxSize);
  pGetSNESAPUContext(@CtxBuf[0]);

  SegLen := CHUNK_SAMPLES * 2 * BYTES_PER_FRAME;
  SetLength(SegX, SegLen);
  SetLength(SegY, SegLen);

  EmulateChunk(CHUNK_SAMPLES * 2, @SegX[0]);
  // Segment X also becomes part of the main recorded stream, so the run stays one continuous story.
  BlockWrite(fOut, SegX[0], SegLen, BytesWritten);
  PcmHash := Hash32(PcmHash, SegX[0], SegLen);
  Inc(TotalWritten, SegLen);
  LogKV('Ctx_SegX_Hash', Format('%.8x', [Hash32(FNV32_SEED, SegX[0], SegLen)]));

  // Time passes before the restore below, so it proves a genuine rewind, not an immediate undo.
  WriteChunkToFile(CHUNK_SAMPLES * 4);

  pSetSNESAPUContext(@CtxBuf[0]);
  EmulateChunk(CHUNK_SAMPLES * 2, @SegY[0]);
  LogKV('Ctx_SegY_Hash', Format('%.8x', [Hash32(FNV32_SEED, SegY[0], SegLen)]));

  if CompareMem(@SegX[0], @SegY[0], SegLen) then
    Ok('GetSNESAPUContext/SetSNESAPUContext round-trip: X == Y (past the intervening playback)')
  else
    Fail('GetSNESAPUContext/SetSNESAPUContext round-trip: X != Y -- restore did not reproduce the original continuation');
  // State after Y is identical to state after X, by the check above, or if it failed, this
  // diverges from the main stream from here on regardless, itself informative.  Continue the
  // main stream.

  // === Phase 10: FixAPU round-trip ===
  // ppRAM direct copy + GetSPCRegs, same X/Y-hash reasoning as Phase 9 above.  The register values
  // are also logged directly: genuine emulated-CPU state, so they must match between x86 and x64
  // at this exact point in a byte-identical run.
  pGetSPCRegs(@RegPC, @RegA, @RegY, @RegX, @RegPSW, @RegSP);
  LogKV('FixAPU_RegPC', Format('0x%.4x', [RegPC]));
  LogKV('FixAPU_RegA', Format('0x%.2x', [RegA]));
  LogKV('FixAPU_RegY', Format('0x%.2x', [RegY]));
  LogKV('FixAPU_RegX', Format('0x%.2x', [RegX]));
  LogKV('FixAPU_RegPSW', Format('0x%.2x', [RegPSW]));
  LogKV('FixAPU_RegSP', Format('0x%.2x', [RegSP]));
  SetLength(SavedRAM, $10000);
  Move(PByte(gRAM)^, SavedRAM[0], $10000);

  EmulateChunk(CHUNK_SAMPLES * 2, @SegX[0]);
  BlockWrite(fOut, SegX[0], SegLen, BytesWritten);
  PcmHash := Hash32(PcmHash, SegX[0], SegLen);
  Inc(TotalWritten, SegLen);
  LogKV('Fix_SegX_Hash', Format('%.8x', [Hash32(FNV32_SEED, SegX[0], SegLen)]));

  Move(SavedRAM[0], PByte(gRAM)^, $10000);
  pFixAPU(RegPC, RegA, RegY, RegX, RegPSW, RegSP);
  EmulateChunk(CHUNK_SAMPLES * 2, @SegY[0]);
  LogKV('Fix_SegY_Hash', Format('%.8x', [Hash32(FNV32_SEED, SegY[0], SegLen)]));

  if CompareMem(@SegX[0], @SegY[0], SegLen) then
    Ok('FixAPU round-trip (raw RAM restore): X == Y')
  else
    Fail('FixAPU round-trip (raw RAM restore): X != Y -- FixAPU did not resync state to reproduce the original continuation');

  // === Phase 11: finish out the requested total sample count with plain playback ===
  RemainingSamples := Int64(TotalSamples) - SamplesDone;
  if RemainingSamples > 0 then
    WriteChunkToFile(Cardinal(RemainingSamples));

  CloseFile(fOut);

  // Disable the debug callbacks before unload, symmetrical with how they were enabled.
  pSetDSPDbg(nil);
  pSetSPCDbg(nil, 0);

  FreeLibrary(hDLL);

  LogLine('');
  LogKV('TotalSamplesWritten', IntToStr(SamplesDone));
  LogKV('TotalBytesWritten', IntToStr(TotalWritten));
  // Redundant with 'fc /b' on the .pcm files, but convenient as one comparable line here.
  LogKV('PcmHash', Format('%.8x', [PcmHash]));
  // Deterministic emulation given an identical call sequence means these fire counts should also
  // be identical between the x86 and x64 runs, not just greater than zero.
  LogKV('DspRegCallbackCount', IntToStr(DspCallbackCount));
  LogKV('SpcFetchCallbackCount', IntToStr(SpcFetchCallbackCount));
  LogKV('DspTraceStubCount', IntToStr(DspTraceCount));
  LogKV('SpcTraceStubCount', IntToStr(SpcTraceCount));
  if DspCallbackCount = 0 then Warn('SNESAPUCallback (CBE_DSPREG) never fired');
  if DspTraceCount = 0 then Warn('SetDSPDbg (pTrace) never fired');
  if SpcTraceCount = 0 then Warn('SetSPCDbg (pDebug) never fired');

  LogLine('');
  if FailCount = 0 then
    LogLine('=== ALL IN-PROCESS CHECKS PASSED (0 failures) ===')
  else
    LogLine(Format('=== %d IN-PROCESS CHECK(S) FAILED -- see FAIL lines above ===', [FailCount]));

  CloseFile(fLog);
end.
