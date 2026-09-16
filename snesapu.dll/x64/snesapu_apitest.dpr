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

 Beyond a plain PCM/log diff, three things need special handling, not just the ordinary FAIL/log
 mechanism every other check here uses.  Everything else this tool exercises (which format/edge-case
 combination, which boundary value, which sentinel) is documented at its own '=== Phase N: ... ==='
 marker in Main, in file order, not repeated here:
   - GetSNESAPUContext/SetSNESAPUContext (Phase 14) and FixAPU (Phase 15): their state layout
     depends on pointer width, so x86/x64 output is NOT expected to match byte-for-byte, unlike
     everywhere else.  Both instead do an in-process round-trip (snapshot, replay a stretch,
     restore, replay the same length again, compare the two results byte-for-byte), which must pass
     independently on each build, regardless of what the two builds' raw bytes look like to
     each other.
   - SetDSPDbg/SetSPCDbg's callbacks (Phase 12/13) bypass x64.inc's ExtCall entirely, using a
     hand-rolled, non-ABI-standard stack protocol instead (see DspTraceStub/SpcTraceStub below),
     since the Windows x64 ABI has no calling-convention mode for it.  A real regression target for
     this port's hand-rolled stack alignment, even with an otherwise-inert stub.
   - GetSNESAPUContextSize's byte count is expected to differ between x86/x64 (same pointer-width
     reason as above), and the log marks that line accordingly, not as a failure.

 Build (once per architecture):
   fpc -Pi386   -Twin32 snesapu_apitest.dpr
   fpc -Px86_64 -Twin64 snesapu_apitest.dpr

 Usage:
   snesapu_apitest.exe <dll path> <spc file path> <out log path> [script700 file] [-wav]

 <out log path> names the log file directly (e.g. 'out_x86.log'); the PCM file is derived from it
 by changing the extension to '.pcm' (e.g. 'out_x86.pcm'), since the log, not the PCM file, is what
 a run is actually judged by (see 'Then compare...' below) and so belongs in the primary argument.

 Exit code: 0 if every in-process check passed (0 FAIL lines), 1 if any check failed or a fatal
 setup error (ERROR: line) aborted the run early, so a caller can tell success from failure without
 parsing the log.

 '-wav', if given (in any position among the arguments), additionally renders 5 fixed seconds of
 playback to a WAV file named after <out log path> with a '.wav' extension (e.g. 'out_x86.log' ->
 'out_x86.wav'): stereo, 16-bit, 32000Hz, INT_GAUSS interpolation, opts=0, SetScript700 paired the
 same way Phase 9 is, SetAPULength song=3s/fade=2s.  A quick-listening convenience, separate from
 and not part of the x86/x64 comparison stream above.

 The 19 phases below already generate a fixed, deterministic amount of PCM output on their own
 (currently around 8 seconds), so there is no separate sample-count argument to grow or shrink the
 run: every run of the same .spc file produces the same length of output.

 Compare two runs (one per architecture, same .spc file):
   snesapu_apitest_x86.exe snesapu.dll     song.spc out_x86.log
   snesapu_apitest_x64.exe snesapu_x64.dll song.spc out_x64.log
   fc /b out_x86.log out_x64.log
   fc /b out_x86.pcm out_x64.pcm

 Then compare the two runs' log files (see LogPath below) for the text-comparable values:
 SNESAPUInfo, GetScript700Data's version string, SetAPULength's fade-out/revival returned totals,
 the context/FixAPU round-trip hashes, the callback fire counts.
===================================================================================================}

program snesapu_apitest;

{$MODE DELPHI}
{$APPTYPE CONSOLE}
{$ASMMODE INTEL}

uses
  Windows, SysUtils;

type
  // Function pointer types, one per SNESAPU.def export.  SetScript700Data is not wired into a
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

  // Canonical 44-byte PCM WAV header, for the optional '-wav' output.  DataSize is known upfront
  // (WAV_SAMPLES is fixed), so the whole header is written once before any sample data, no seek-
  // back-and-patch needed afterward.
  TWavHeader = packed record
    RiffId: array[0..3] of AnsiChar;                     // 'RIFF'
    RiffSize: Cardinal;                                  // 36 + DataSize
    WaveId: array[0..3] of AnsiChar;                     // 'WAVE'
    FmtId: array[0..3] of AnsiChar;                       // 'fmt '
    FmtSize: Cardinal;                                    // 16
    AudioFormat: Word;                                    // 1 = PCM
    NumChannels: Word;
    SampleRate: Cardinal;
    ByteRate: Cardinal;
    BlockAlign: Word;
    BitsPerSample: Word;
    DataId: array[0..3] of AnsiChar;                      // 'data'
    DataSize: Cardinal;
  end;

const
  SPC_FILE_SIZE   = 66048;
  CHUNK_SAMPLES   = 4096;
  // 4 bytes/channel (bits=-32, IEEE-754 float, matches the SetAPUOpt call below) times 2 channels.
  BYTES_PER_FRAME = 8;
  // Phase 19's closing padding.  Small on purpose: it exercises nothing new, just flows a little
  // more plain playback into the PCM stream after every other phase's excursions and resets, so a
  // few chunks are enough.  Fixed, not caller-supplied, see the header comment.
  FINAL_PADDING_SAMPLES = CHUNK_SAMPLES * 4;
  // '-wav' output format, all fixed, see the header comment.
  WAV_CHANNELS      = 2;
  WAV_BITS          = 16;
  WAV_RATE          = 32000;
  WAV_SECONDS       = 5;
  WAV_SAMPLES       = WAV_SECONDS * WAV_RATE;
  WAV_BYTES_PER_FRAME = (WAV_CHANNELS * WAV_BITS) div 8;
  CBE_DSPREG      = $01;
  CBE_S700FCH     = $02;
  CBE_INCDATA     = $20000000;
  CBE_INCS700     = $40000000;
  CBE_REQBP       = $10000000;
  FCH_PAUSE       = 3;
  // SetSPCDbg's 'opts' bitfield (SPC700.h).  SPC_TRACE is the only one used elsewhere in this run;
  // the rest are exercised together as a sweep, see that phase's own comment.
  SPC_RETURN      = $1;
  SPC_HALT        = $2;
  DSP_HALT        = $4;
  SPC_NODSP       = $8;
  SPC_TRACE       = $10;
  DSP_PAUSE       = $20;
  // Interpolation types and a DSP option flag, for the SetAPUOpt variation sweep (see DSP.inc).
  INT_NONE        = 0;
  INT_LINEAR      = 1;
  INT_CUBIC       = 2;
  INT_GAUSS       = 3;
  INT_SINC        = 4;
  INT_GAUSS4      = 7;
  DSP_ANALOG      = $01;
  DSP_OLDSMP      = $02;
  DSP_SURND       = $04;
  DSP_REVERSE     = $08;
  DSP_NOECHO      = $10;
  DSP_NOPMOD      = $20;
  DSP_NOPREAD     = $40;
  DSP_NOFIR       = $80;
  DSP_BASS        = $100;
  DSP_NOENV       = $200;
  DSP_NONOISE     = $400;
  DSP_ECHOFIR     = $800;
  DSP_NOSURND     = $1000;
  DSP_ENVSPD      = $2000;
  DSP_NOPLMT      = $4000;
  DSP_NOMAIN      = $8000;
  // VoiceMix struct layout (DSP.inc), for masking sIdx/bCur out of the Voice array hash below.
  // 128 bytes per voice, 8 voices, matches DSP.asm's 'mix resb 1024' declaration.
  VOICE_STRIDE    = 128;
  VOICE_COUNT     = 8;
  VOICE_SIDX_OFS  = 4;                                   // sIdx: resd, at byte offset 4
  VOICE_BCUR_OFS  = 8;                                   // bCur: resd, at byte offset 8

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
  Args: array of String;                                 // ParamStr(1..), with '-wav' pulled out
  WantWav: Boolean;
  WavPath: String;
  SpcData: array[0..SPC_FILE_SIZE-1] of Byte;
  Buf: array[0..CHUNK_SAMPLES*BYTES_PER_FRAME-1] of Byte;
  fSpc, fOut, fWav: File;
  BytesRead, BytesWritten: LongInt;
  TotalWritten: Int64;
  SamplesDone: Int64;
  DspCallbackCount, SpcFetchCallbackCount: Int64;
  IncS700CallbackCount, IncDataCallbackCount: Int64;
  ReqBPCallbackCount: Int64;
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

// =================================================================================================
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
// comparable between x86 and x64.  The Voice array needs HashVoiceArray below instead, since two
// of its fields are pointers on x86 but plain offsets on x64, by design.
function HashMem(P: Pointer; Len: NativeUInt): Cardinal;
begin
  Result := Hash32(FNV32_SEED, PByte(P)^, Len);
end;

// Hashes the Voice array (Count voices, Stride bytes each) with sIdx and bCur masked to zero in
// a scratch copy before hashing, so the rest of each voice's mixing state is still cross-checked.
// sIdx is a real pointer into the voice's own sample buffer on x86, but a small offset relative to
// that same buffer on x64 (see DSP.asm's StartSrc note), and bCur is a real pointer into decoded
// sample RAM on x86, but a pAPURAM-relative offset on x64, so neither is directly comparable.
function HashVoiceArray(P: Pointer; Count, Stride: NativeUInt): Cardinal;
var
  i: NativeUInt;
  Scratch: array[0..VOICE_STRIDE-1] of Byte;
begin
  Result := FNV32_SEED;
  for i := 0 to Count - 1 do
  begin
    Move(PByte(P)[i * Stride], Scratch[0], Stride);
    FillChar(Scratch[VOICE_SIDX_OFS], SizeOf(Cardinal), 0);
    FillChar(Scratch[VOICE_BCUR_OFS], SizeOf(Cardinal), 0);
    Result := Hash32(Result, Scratch[0], Stride);
  end;
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

// =================================================================================================
// Callbacks

// SNESAPUCallback: standard ExtCall path, same protocol snesapu_pcmdump.dpr already exercises.
// Registered for CBE_DSPREG, CBE_S700FCH, CBE_INCS700, CBE_INCDATA, and CBE_REQBP, covering every
// mask bit this tool exercises.  For CBE_INCS700/CBE_INCDATA, lpData points at exactly Value bytes
// of the filename text from a Script700 '#i'/'#ib' directive, not null-terminated.  The DLL never
// touches the filesystem itself for these, it only hands over the filename (see
// thirdparty/SNESAPU.cpp's IncludeScript700File for the reference frontend that would actually load
// the file), so this callback only verifies the bytes it receives.  CBE_REQBP fires from a
// Script700 'bp' command while RunScript700 executes the already-compiled bytecode during playback,
// not synchronously when SetScript700 compiles the script the way CBE_INCS700/CBE_INCDATA do, so
// the phase that exercises it plays some samples between setting the script and checking the count.
function APUCallback(effect, addr, value: Cardinal; lpData: Pointer): Cardinal; stdcall;
var
  Name: AnsiString;
begin
  case effect of
    CBE_S700FCH: Inc(SpcFetchCallbackCount);
    CBE_REQBP:
      begin
        Inc(ReqBPCallbackCount);
        LogKV('ReqBPCallback_Effect', Format('0x%x', [effect]));
        LogKV('ReqBPCallback_Addr', Format('0x%x', [addr]));
        LogKV('ReqBPCallback_Value', Format('0x%x', [value]));
      end;
    CBE_INCS700, CBE_INCDATA:
      begin
        SetString(Name, PAnsiChar(lpData), Integer(value));
        LogKV('IncludeCallback_Effect', Format('0x%x', [effect]));
        LogKV('IncludeCallback_Addr', Format('0x%x', [addr]));
        LogKV('IncludeCallback_Value', IntToStr(value));
        LogKV('IncludeCallback_Filename', Name);
        if effect = CBE_INCS700 then
        begin
          Inc(IncS700CallbackCount);
          if Name = 'text.700' then
            Ok('CBE_INCS700 filename matches "text.700"')
          else
            Fail(Format('CBE_INCS700 filename mismatch: got "%s"', [Name]));
        end
        else
        begin
          Inc(IncDataCallbackCount);
          if Name = 'bin.700' then
            Ok('CBE_INCDATA filename matches "bin.700"')
          else
            Fail(Format('CBE_INCDATA filename mismatch: got "%s"', [Name]));
        end;
      end;
  else
    Inc(DspCallbackCount);
  end;
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

// =================================================================================================
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

// Plays roughly ClockCycles worth of audio via one of EmuAPU's two clock-cycle modes, instead of
// the sample-count mode (type=1) WriteChunkToFile uses: LType=0 adjusts the cycle count for the
// current APU speed first (SetAPUSmpClk's smpRAdj), the same path EmuAPUI's own recursion uses.
// LType=255 (byte -1) skips that adjustment, treating ClockCycles as already-adjusted cycles,
// the path internal to SeekAPU alone (see APU.asm's '.NextSec'), never reached through the
// exported EmuAPU otherwise.  Unlike WriteChunkToFile, the output byte span is not known ahead of
// time, since 'len' here is a cycle count, not a sample count, so this makes one EmuAPU call and
// writes back whatever it returns, with no internal chunking loop.  Keep ClockCycles modest
// enough that the result cannot exceed Buf's capacity.
procedure WriteChunkByClock(ClockCycles: Cardinal; LType: Byte);
var
  E: Pointer;
  Written: NativeUInt;
begin
  try
    E := pEmuAPU(@Buf[0], ClockCycles, LType);
  except
    on Ex: Exception do
      FatalFail(Format('EmuAPU (type=%d) raised %s ("%s")', [LType, Ex.ClassName, Ex.Message]));
  end;
  Written := NativeUInt(E) - NativeUInt(@Buf[0]);
  if Written > SizeOf(Buf) then
    FatalFail(Format('EmuAPU (type=%d) reported %d bytes, exceeding the %d-byte scratch buffer',
      [LType, Written, SizeOf(Buf)]));
  BlockWrite(fOut, Buf[0], Written, BytesWritten);
  if Cardinal(BytesWritten) <> Cardinal(Written) then
    FatalFail('Write to output file failed');
  PcmHash := Hash32(PcmHash, Buf, Written);
  Inc(TotalWritten, Written);
  Inc(SamplesDone, Written div BYTES_PER_FRAME);
end;

// Plays exactly SamplesToPlay samples (type=1), like WriteChunkByClock's single-call shape, then
// reports whether every returned byte is zero.  SamplesToPlay must fit in one chunk.  Used only by
// the mixType=0 (MIX_NONE) check in Phase 2, where silence is itself the property under test.
function WriteChunkCheckSilent(SamplesToPlay: Cardinal): Boolean;
var
  E: Pointer;
  Written: NativeUInt;
  I: NativeUInt;
begin
  try
    E := pEmuAPU(@Buf[0], SamplesToPlay, 1);
  except
    on Ex: Exception do
      FatalFail(Format('EmuAPU (mixType=0) raised %s ("%s")', [Ex.ClassName, Ex.Message]));
  end;
  Written := NativeUInt(E) - NativeUInt(@Buf[0]);
  if Written > SizeOf(Buf) then
    FatalFail(Format('EmuAPU (mixType=0) reported %d bytes, exceeding the %d-byte scratch buffer',
      [Written, SizeOf(Buf)]));
  Result := True;
  for I := 0 to Written - 1 do
    if Buf[I] <> 0 then
    begin
      Result := False;
      Break;
    end;
  BlockWrite(fOut, Buf[0], Written, BytesWritten);
  if Cardinal(BytesWritten) <> Cardinal(Written) then
    FatalFail('Write to output file failed');
  PcmHash := Hash32(PcmHash, Buf, Written);
  Inc(TotalWritten, Written);
  Inc(SamplesDone, Written div BYTES_PER_FRAME);
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

// Writes a canonical 44-byte PCM WAV header to F, sized for exactly DataBytes of sample data to
// follow.  Only used by the optional '-wav' output, a fixed-format excursion separate from the
// main PCM stream, so it does not touch PcmHash/TotalWritten/SamplesDone.
procedure WriteWavHeader(var F: File; DataBytes, SampleRate, Channels, Bits: Cardinal);
var
  Hdr: TWavHeader;
  Written: LongInt;
begin
  Hdr.RiffId := 'RIFF';
  Hdr.WaveId := 'WAVE';
  Hdr.FmtId := 'fmt ';
  Hdr.FmtSize := 16;
  Hdr.AudioFormat := 1;
  Hdr.NumChannels := Channels;
  Hdr.SampleRate := SampleRate;
  Hdr.BlockAlign := (Channels * Bits) div 8;
  Hdr.ByteRate := SampleRate * Hdr.BlockAlign;
  Hdr.BitsPerSample := Bits;
  Hdr.DataId := 'data';
  Hdr.DataSize := DataBytes;
  Hdr.RiffSize := 36 + DataBytes;
  BlockWrite(F, Hdr, SizeOf(Hdr), Written);
  if Written <> SizeOf(Hdr) then
    FatalFail('Write to WAV file failed (header)');
end;

// Plays TotalSamples samples (type=1, CHUNK_SAMPLES at a time, reusing the shared Buf, same
// chunking shape as WriteChunkToFile) straight into F, the WAV file's already-open data section.
// Only used by the optional '-wav' output; see WriteWavHeader's comment for why it stays separate
// from WriteChunkToFile instead of reusing it directly.
procedure WriteWavSamples(var F: File; TotalSamples: Cardinal);
var
  Left, This: Cardinal;
  E: Pointer;
  Written: NativeUInt;
  BW: LongInt;
begin
  Left := TotalSamples;
  while Left > 0 do
  begin
    if Left > CHUNK_SAMPLES then This := CHUNK_SAMPLES else This := Left;
    try
      E := pEmuAPU(@Buf[0], This, 1);
    except
      on Ex: Exception do
        FatalFail(Format('EmuAPU (wav) raised %s ("%s")', [Ex.ClassName, Ex.Message]));
    end;
    Written := NativeUInt(E) - NativeUInt(@Buf[0]);
    if Written > SizeOf(Buf) then
      FatalFail(Format('EmuAPU (wav) reported %d bytes, exceeding the %d-byte scratch buffer',
        [Written, SizeOf(Buf)]));
    BlockWrite(F, Buf[0], Written, BW);
    if Cardinal(BW) <> Cardinal(Written) then
      FatalFail('Write to WAV file failed (data)');
    Dec(Left, This);
  end;
end;

// =================================================================================================
// Main

var
  Ver, Min, Opt: Cardinal;
  DLLVer: array[0..31] of AnsiChar;
  pSPCReg, pScript700: Pointer;
  OldPDebug, OldPTrace, OldPCallback: Pointer;
  ZeroLenResult: Pointer;
  TotalLen: Cardinal;
  TestScript: AnsiString;
  ScriptResult: Cardinal;
  SongScript700Path, FallbackScript700Path: String;
  Blob: array[0..15] of Byte;
  BlobIdx: Integer;
  DataRes: Cardinal;
  DSPRegResult: Byte;
  RegIdx: Integer;
  DSPSweepHash: Cardinal;
  TimerPortIdx: Integer;
  ArgIdx: Integer;

begin
  FailCount := 0;
  DspCallbackCount := 0;
  SpcFetchCallbackCount := 0;
  IncS700CallbackCount := 0;
  IncDataCallbackCount := 0;
  ReqBPCallbackCount := 0;
  DspTraceCount := 0;
  SpcTraceCount := 0;
  SamplesDone := 0;
  TotalWritten := 0;

  // '-wav' is pulled out first, wherever it appears among the arguments, so it does not shift the
  // positional ones (dll/spc/pcm/[script700]) that follow it.
  WantWav := False;
  SetLength(Args, 0);
  for ArgIdx := 1 to ParamCount do
    if SameText(ParamStr(ArgIdx), '-wav') then
      WantWav := True
    else
    begin
      SetLength(Args, Length(Args) + 1);
      Args[High(Args)] := ParamStr(ArgIdx);
    end;

  if Length(Args) < 3 then
  begin
    WriteLn('Usage: snesapu_apitest <dll path> <spc file path> <out log path> ',
            '[script700 file path] [-wav]');
    Halt(1);
  end;

  DllPath  := Args[0];
  SpcPath  := Args[1];
  LogPath  := Args[2];
  OutPath  := ChangeFileExt(LogPath, '.pcm');
  if Length(Args) >= 4 then
    Script700Path := Args[3]
  else
    Script700Path := '';

  // Open the log file first.  Every Info/Ok/Warn/Fail/LogKV call from here on goes to it, so a
  // line-by-line 'fc'/'diff' of this run's log against the other architecture's run is the primary
  // way to catch a behavioral difference that the PCM byte-diff alone would not surface.
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
    FatalFail('GetProcAddress failed for one or more exports, see SNESAPU.def');
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
  //
  // SNESAPUCallback's mask starts narrow (CBE_DSPREG only) rather than the full combined mask used
  // from here on, so Phase 1 below can prove apuCbMask genuinely accumulates via OR ('Or
  // [apuCbMask],EBX', APU.asm), not replaces: the remaining bits are added there, once fOut is
  // open and a first chunk can be played to confirm CBE_DSPREG already fired under the narrow mask
  // alone.
  pSNESAPUCallback(@APUCallback, CBE_DSPREG);
  pSetDSPDbg(@DspTraceStub);
  pSetSPCDbg(@SpcTraceStub, SPC_TRACE);
  Ok('SNESAPUCallback (CBE_DSPREG only) / SetDSPDbg / SetSPCDbg registered');

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
  // One chunk is enough: the hashes below just need some fixed, deterministic point in the
  // stream to compare, not a long stretch, since any divergence up to here already shows in the
  // PCM byte-diff regardless of how much or little was played first.
  WriteChunkToFile(CHUNK_SAMPLES);

  // Signal-derived scalars and GetAPUData content at a fixed, deterministic point in the stream.
  // If the audio output is bit-identical between builds up to here, which the PCM hash/diff
  // already checks, all of these must also match.  ppRAM/ppXRAM/ppDSP/ppOutPort/ppT64Cnt point at
  // plain data with no embedded pointers, so hashing their content directly is meaningful across
  // architectures.  ppVoice needs HashVoiceArray instead, see its comment.
  LogKV('Phase1_vMMaxL', IntToStr(PLongInt(gVMMaxL)^));
  LogKV('Phase1_vMMaxR', IntToStr(PLongInt(gVMMaxR)^));
  LogKV('Phase1_RAM_Hash', Format('%.8x', [HashMem(gRAM, $10000)]));
  LogKV('Phase1_XRAM_Hash', Format('%.8x', [HashMem(gXRAM, 64)]));
  LogKV('Phase1_XRAM_Hex', HexDump(gXRAM, 64));
  LogKV('Phase1_DSP_Hash', Format('%.8x', [HashMem(gDSP, 128)]));
  LogKV('Phase1_OutPort_Hash', Format('%.8x', [HashMem(gOutPort, 4)]));
  LogKV('Phase1_Voice_Hash', Format('%.8x', [HashVoiceArray(gVoice, VOICE_COUNT, VOICE_STRIDE)]));
  LogKV('Phase1_T64Cnt', IntToStr(PCardinal(gT64Cnt)^));

  // SNESAPUCallback's apuCbMask accumulation: CBE_DSPREG alone (registered above) must already have
  // fired from the ordinary playback just above, proving the narrow mask alone works, before the
  // remaining bits (needed starting Phase 8) are added by a second call.  A second chunk after that
  // confirms CBE_DSPREG did not stop firing, i.e. the second call's mask genuinely OR-accumulates
  // onto the first rather than replacing it.
  if DspCallbackCount = 0 then
    Fail('SNESAPUCallback (CBE_DSPREG alone): callback never fired during initial playback')
  else
    Ok('SNESAPUCallback (CBE_DSPREG alone): callback fired during initial playback');

  pSNESAPUCallback(@APUCallback, CBE_S700FCH or CBE_INCS700 or CBE_INCDATA or CBE_REQBP);
  WriteChunkToFile(CHUNK_SAMPLES);
  if DspCallbackCount = 0 then
    Fail('SNESAPUCallback (apuCbMask accumulation): CBE_DSPREG stopped firing, mask was replaced')
  else
    Ok('SNESAPUCallback (apuCbMask accumulation): CBE_DSPREG still fires after adding more bits');

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
  pSetAPUOpt(1, 2, 32, 192000, INT_GAUSS4, 0);
  WriteChunkToFile(CHUNK_SAMPLES);
  pSetAPUOpt(1, 2, 16, 32000, INT_GAUSS, $FFFF xor DSP_NOECHO xor DSP_NOMAIN);
  WriteChunkToFile(CHUNK_SAMPLES);
  pSetAPUOpt(1, 2, 16, 32000, INT_GAUSS, DSP_NOECHO);
  WriteChunkToFile(CHUNK_SAMPLES);
  pSetAPUOpt(1, 2, 16, 32000, INT_GAUSS, DSP_NOMAIN);
  WriteChunkToFile(CHUNK_SAMPLES);
  pSetAPUOpt(1, 2, 16, 44100, INT_GAUSS, DSP_ECHOFIR);
  WriteChunkToFile(CHUNK_SAMPLES);
  pSetAPUOpt(1, 2, 16, 48000, INT_GAUSS, DSP_ECHOFIR);
  WriteChunkToFile(CHUNK_SAMPLES);
  pSetAPUOpt(1, 2, 16, 64000, INT_GAUSS, DSP_ECHOFIR);
  WriteChunkToFile(CHUNK_SAMPLES);
  pSetAPUOpt(1, 2, 16, 96000, INT_GAUSS, DSP_ECHOFIR);
  WriteChunkToFile(CHUNK_SAMPLES);
  Ok('SetAPUOpt format/rate/interpolation sweep tested (11 patterns)');

  // mixType=0 (MIX_NONE) forces DSP output to silence directly inside EmuDSP, without ever calling
  // RunDSP (DSP.asm's EmuDSP: 'Test byte [dspMix],-1 / JZ .Mute').  Silence is its only externally
  // visible effect, so WriteChunkCheckSilent plays one chunk and checks every returned byte is 0.
  pSetAPUOpt(0, 2, 16, 64000, INT_GAUSS, DSP_ECHOFIR);
  if WriteChunkCheckSilent(CHUNK_SAMPLES) then
    Ok('SetAPUOpt (mixType=0, rate=64000, opts=DSP_ECHOFIR): output buffer is silent, as expected')
  else
    Fail('SetAPUOpt (mixType=0, rate=64000, opts=DSP_ECHOFIR): output buffer contains nonzero samples');
  pSetAPUOpt(0, 2, 16, 32000, INT_GAUSS, DSP_ECHOFIR);
  if WriteChunkCheckSilent(CHUNK_SAMPLES) then
    Ok('SetAPUOpt (mixType=0, rate=32000, opts=DSP_ECHOFIR): output buffer is silent, as expected')
  else
    Fail('SetAPUOpt (mixType=0, rate=32000, opts=DSP_ECHOFIR): output buffer contains nonzero samples');
  pSetAPUOpt(0, 2, 16, 64000, INT_GAUSS, 0);
  if WriteChunkCheckSilent(CHUNK_SAMPLES) then
    Ok('SetAPUOpt (mixType=0, rate=64000, opts=0): output buffer is silent, as expected')
  else
    Fail('SetAPUOpt (mixType=0, rate=64000, opts=0): output buffer contains nonzero samples');
  pSetAPUOpt(0, 2, 16, 32000, INT_GAUSS, 0);
  if WriteChunkCheckSilent(CHUNK_SAMPLES) then
    Ok('SetAPUOpt (mixType=0, rate=32000, opts=0): output buffer is silent, as expected')
  else
    Fail('SetAPUOpt (mixType=0, rate=32000, opts=0): output buffer contains nonzero samples');

  // -1 sentinel, all six parameters: SetDSPOpt (DSP.asm) treats -1 as 'keep the current setting'
  // for mixType/numChn/bits/rate/inter/opts alike ('Cmp EDX,-1 / JE .DefXxx', repeated per
  // parameter).  SeekAPU already exercises this internally, every time it runs ('Call
  // SetAPUOptI,-1,-1,-1,-1,-1,EAX', APU.asm), but only through the DLL's own recursive call, never
  // through this exported entry point directly, the shape most exposed to the x64.inc
  // CallArg/ExtCallArg marshaling this port fixed.  Calling it here, right after the mixType=0
  // test above, checks mixType really stays 0 (silent), not reset to some other value.
  pSetAPUOpt(Cardinal(-1), Cardinal(-1), Cardinal(-1), Cardinal(-1), Cardinal(-1), Cardinal(-1));
  if WriteChunkCheckSilent(CHUNK_SAMPLES) then
    Ok('SetAPUOpt (-1 sentinel, all params): mixType=0 preserved, output still silent')
  else
    Fail('SetAPUOpt (-1 sentinel, all params): output no longer silent, a setting was lost');

  pSetAPUOpt(1, 2, Cardinal(-32), 96000, INT_SINC, 0);   // restore the format the rest of the run uses

  // === Phase 3: EmuAPU edge cases ===
  // len=0 is EmuAPUI's very first check ('Test EAX,EAX / JZ .Done'), returning immediately with
  // nothing emulated and pBuf unchanged.  No other phase ever calls EmuAPU with len=0, so this
  // exercises that early-out path directly, instead of only ever passing a nonzero count.
  ZeroLenResult := pEmuAPU(@Buf[0], 0, 0);
  if ZeroLenResult = @Buf[0] then
    Ok('EmuAPU (len=0, type=0): returned pBuf unchanged, as documented')
  else
    Fail(Format('EmuAPU (len=0, type=0): expected %p, got %p', [@Buf[0], ZeroLenResult]));
  ZeroLenResult := pEmuAPU(@Buf[0], 0, 1);
  if ZeroLenResult = @Buf[0] then
    Ok('EmuAPU (len=0, type=1): returned pBuf unchanged, as documented')
  else
    Fail(Format('EmuAPU (len=0, type=1): expected %p, got %p', [@Buf[0], ZeroLenResult]));

  // Every other phase calls EmuAPU with type=1 (len is a sample count).  type=0 and type=255
  // instead treat len as raw APU clock cycles (APU_CLK=24576000 per second, see SPC700.inc), see
  // WriteChunkByClock's comment for how the two differ.  A modest cycle count, about 1ms, keeps
  // the returned span well under Buf's capacity.
  WriteChunkByClock(24576000 div 1000, 0);
  Ok('EmuAPU (type=0, clock-cycle mode) played without crashing');
  WriteChunkByClock(24576000 div 1000, 255);
  Ok('EmuAPU (type=255, SeekAPU-only clock-cycle mode) played without crashing');

  // === Phase 4: DSP setter sweep ===
  // SetDSPStereo/SetDSPEFBCT/SetDSPPitch/SetDSPVol/SetDSPAmp, fixed test values, then a full sweep
  // of all 256 SetDSPReg addresses, then continue playback.  Any divergence these introduce shows
  // up in the PCM stream from here on.  DSPSweepHash folds in every result byte so the whole sweep
  // reduces to one comparable line instead of 256.
  pSetDSPStereo(32768);           // 0.5, normal separation, ~unchanged
  WriteChunkToFile(CHUNK_SAMPLES);
  pSetDSPEFBCT(32768);           // 1.0, no crosstalk, SNES default (DSP.h: leak is signed [-1.15])
  WriteChunkToFile(CHUNK_SAMPLES);
  pSetDSPPitch(32000);           // normal pitch
  WriteChunkToFile(CHUNK_SAMPLES);
  pSetDSPVol($10000);            // no attenuation
  WriteChunkToFile(CHUNK_SAMPLES);
  pSetDSPAmp($10000);            // 1.0x
  WriteChunkToFile(CHUNK_SAMPLES);
  Ok('SetDSPStereo/EFBCT/Pitch/Vol/Amp set (fixed values)');

  DSPSweepHash := FNV32_SEED;
  for RegIdx := 0 to 255 do
  begin
    DSPRegResult := pSetDSPReg(Byte(RegIdx), Byte(RegIdx));
    DSPSweepHash := Hash32(DSPSweepHash, DSPRegResult, SizeOf(DSPRegResult));
    if RegIdx = $26 then
      LogKV('SetDSPReg_MVOLL_Result', IntToStr(DSPRegResult));    // one concrete value alongside the hash
  end;
  LogKV('SetDSPReg_SweepHash', Format('%.8x', [DSPSweepHash]));
  Ok('SetDSPReg swept across all 256 addresses');
  WriteChunkToFile(CHUNK_SAMPLES);      // one chunk to flow the sweep's effect into the PCM stream

  // SetDSPAmp/SetDSPVol/SetDSPStereo/SetDSPEFBCT/SetDSPPitch, extreme/boundary values.  Each was
  // only ever exercised above with one representative 'normal' value, unlike SetDSPReg's full
  // sweep or SetAPUSmpClk's own clamp-boundary test (Phase 6).  SetDSPAmp/SetDSPVol clamp a
  // negative-as-unsigned argument to 0 ('CDQ / Not EDX / And EAX,EDX', DSP.asm), and SetDSPAmp
  // additionally treats amp<=256 as an old-style 0-256 range, scaling it by 4096 ('Cmp EAX,256 /
  // JA .NewScale / ShL EAX,12'), exactly at that boundary.  SetDSPStereo's 'sep' is unsigned
  // [1.16] (0 = mono, 32768 = normal, 65536 = full separation, DSP.h), offset by 32768 with plain
  // unsigned arithmetic and no clamp.  SetDSPEFBCT's 'leak' is instead signed [-1.15] (DSP.h:
  // 32768 = no crosstalk, 0 = full crosstalk, -32768 = inverse crosstalk), so its own '+32768'
  // ('Unsign crosstalk', DSP.asm) expects a value already in that signed range, not the unsigned
  // 16.16 range SetDSPAmp/SetDSPVol/SetDSPPitch use elsewhere in this run.  A short burst of
  // playback follows each so a marshaling mismatch shows up in the PCM stream like everywhere
  // else, then every value is restored to its default above before Phase 5.
  pSetDSPAmp(0);
  WriteChunkToFile(CHUNK_SAMPLES);
  pSetDSPAmp(256);                       // exactly the old-style-range/16.16 scaling boundary
  WriteChunkToFile(CHUNK_SAMPLES);
  pSetDSPAmp(Cardinal(-1));              // negative as unsigned, clamped to 0
  WriteChunkToFile(CHUNK_SAMPLES);
  pSetDSPAmp($10000);                    // restore 1.0x

  pSetDSPVol(0);
  WriteChunkToFile(CHUNK_SAMPLES);
  pSetDSPVol($7FFFFFFF);                 // largest value still positive after the CDQ sign test
  WriteChunkToFile(CHUNK_SAMPLES);
  pSetDSPVol($10000);                    // restore no attenuation

  pSetDSPStereo(0);
  WriteChunkToFile(CHUNK_SAMPLES);
  pSetDSPStereo(65535);
  WriteChunkToFile(CHUNK_SAMPLES);
  pSetDSPStereo(32768);                  // restore 0.5, normal separation

  pSetDSPEFBCT(0);                       // full crosstalk (mono/center), one documented endpoint
  WriteChunkToFile(CHUNK_SAMPLES);
  pSetDSPEFBCT(Cardinal(-32768));        // -1.0, inverse crosstalk (L/R swapped), the other end
  WriteChunkToFile(CHUNK_SAMPLES);
  pSetDSPEFBCT(32768);                   // restore 1.0, no crosstalk

  pSetDSPPitch(0);
  WriteChunkToFile(CHUNK_SAMPLES);
  pSetDSPPitch(192000);                  // an already-used-elsewhere safe upper rate (Phase 2)
  WriteChunkToFile(CHUNK_SAMPLES);
  pSetDSPPitch(32000);                   // restore normal pitch
  Ok('DSP setter extreme/boundary values tested (SetDSPAmp/Vol/Stereo/EFBCT/Pitch)');

  // === Phase 5: SetAPURAM / InPort ===
  // Fixed, deterministic writes.  The values only need to match between builds, not to preserve
  // musical correctness, see the design note in the header.  SetAPURAM covers both ends of the
  // 64KB RAM (addr=$0000 and addr=$FFFF), not just one mid-range address, and InPort covers all
  // 4 SPC700 I/O ports (inPortCp is declared 'resb 4' in SPC700.asm), not just port 0.  One chunk
  // per step is enough to flow each write's effect into the PCM stream, the same reasoning as
  // Phase 1's own single chunk.
  pSetAPURAM($0000, $00);
  pSetAPURAM($0010, $00);
  pSetAPURAM($FFFF, $00);
  Ok('SetAPURAM called at both RAM boundaries and one mid-range address');
  pInPort($00, $00);
  WriteChunkToFile(CHUNK_SAMPLES);
  pInPort($00, $01);
  WriteChunkToFile(CHUNK_SAMPLES);
  pInPort($00, $02);
  WriteChunkToFile(CHUNK_SAMPLES);
  pInPort($01, $00);
  pInPort($02, $00);
  pInPort($03, $00);
  WriteChunkToFile(CHUNK_SAMPLES);
  Ok('InPort called on all 4 ports');

  // === Phase 6: SetAPUSmpClk clamp boundaries ===
  // SetAPUSmpClkI (APU.asm) clamps speed to [1024, 1048576], pulling an out-of-range value to
  // the nearest bound rather than rejecting it.  Exercises both bounds, plus one value just
  // outside each, instead of only the documented 1.0x default ($10000) every other phase uses.
  // A short burst of playback follows each, so a clamp-boundary mismatch would shift subsequent
  // PCM bytes.  Restored to $10000 (1.0x) before continuing.
  pSetAPUSmpClk(1024);                     // minimum
  WriteChunkToFile(CHUNK_SAMPLES);
  pSetAPUSmpClk(512);                      // below minimum, should clamp to 1024
  WriteChunkToFile(CHUNK_SAMPLES);
  pSetAPUSmpClk(1048576);                  // maximum
  WriteChunkToFile(CHUNK_SAMPLES);
  pSetAPUSmpClk(2097152);                  // above maximum, should clamp to 1048576
  WriteChunkToFile(CHUNK_SAMPLES);
  pSetAPUSmpClk($10000);                   // restore 1.0x
  Ok('SetAPUSmpClk clamp boundaries tested');

  // === Phase 7: SetScript700 ===
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
  pSetScript700(nil);          // disable again so it does not affect the rest of the run

  // === Phase 8: SetScript700 include/breakpoint callbacks (CBE_INCS700/CBE_INCDATA/CBE_REQBP) ===
  // 'm 0 0' just gets the interpreter past the header.  '#i "text.700"' and '#ib "bin.700"' fire
  // CBE_INCS700/CBE_INCDATA synchronously while SetScript700 compiles the script, with lpData/value
  // spanning exactly the filename text.  Both are verified inside APUCallback itself (see its
  // comment).  'bp $1234' is different: it compiles to a bytecode instruction that only fires
  // CBE_REQBP once RunScript700 actually executes it during playback, so a chunk of playback runs
  // below before checking it fired, unlike the include directives, which are already done by the
  // time pSetScript700 returns.  All three callbacks log effect/addr/value, so a diff between the
  // x86 and x64 logs would catch a mismatch the per-build checks here cannot.
  ScriptResult := pSetScript700(PAnsiChar(AnsiString('m 0 0 #i "text.700" bp $1234 e e FFFFFF #ib "bin.700"' + #0)));
  LogKV('IncludeTest_SetScript700_Result', IntToStr(ScriptResult));
  if IncS700CallbackCount = 0 then Fail('CBE_INCS700 callback never fired');
  if IncDataCallbackCount = 0 then Fail('CBE_INCDATA callback never fired');
  WriteChunkToFile(CHUNK_SAMPLES * 4);           // let RunScript700 reach and execute 'bp $1234'
  if ReqBPCallbackCount = 0 then Fail('CBE_REQBP callback never fired');
  pSetScript700(nil);          // disable again so it does not affect the rest of the run

  // === Phase 9: SetScript700, using the .spc file's own paired Script700 program ===
  // Looks for '<spc base name>.700' next to the .spc file first, e.g. 'song.spc' pairs with
  // 'song.700', falls back to '65816.700' in the same directory when that specific pairing does
  // not exist, and falls back again to passing nil, plain waveform generation with no Script700
  // program at all, when neither file exists. Whichever path is taken, a chunk of playback follows
  // so the resulting audio, correct or not, flows into the main PCM stream and log like every other
  // phase, then the script is disabled again so it does not affect what follows.
  SongScript700Path := ChangeFileExt(SpcPath, '.700');
  FallbackScript700Path := ExtractFilePath(SpcPath) + '65816.700';
  if FileExists(SongScript700Path) then
  begin
    LogKV('PairedScript700_Source', SongScript700Path);
    TestScript := LoadTextFile(SongScript700Path);
    ScriptResult := pSetScript700(PAnsiChar(TestScript));
  end
  else if FileExists(FallbackScript700Path) then
  begin
    LogKV('PairedScript700_Source', FallbackScript700Path);
    TestScript := LoadTextFile(FallbackScript700Path);
    ScriptResult := pSetScript700(PAnsiChar(TestScript));
  end
  else
  begin
    LogKV('PairedScript700_Source', '(none, nil)');
    ScriptResult := pSetScript700(nil);
  end;
  LogKV('PairedScript700_Result', IntToStr(ScriptResult));
  WriteChunkToFile(CHUNK_SAMPLES * 4);
  pSetScript700(nil);          // disable again so it does not affect the rest of the run

  // === Phase 10: SetScript700Data ===
  // Pointer/return-code sanity only, see header note.
  for BlobIdx := 0 to High(Blob) do Blob[BlobIdx] := BlobIdx;
  DataRes := pSetScript700Data(0, @Blob[0], SizeOf(Blob));
  LogKV('SetScript700Data_Result', IntToStr(DataRes));

  // pData=nil is 'Test PAX,PAX / JZ .FINALIZE', skipping the memcpy entirely, and, since EAX is
  // never set along that path, falls through to the function's own 'EAX' return with whatever
  // just made PAX zero, i.e. 0 itself.  No other phase ever calls SetScript700Data with pData=nil,
  // so this exercises that early-out path directly, checking the returned 0 as a concrete signal.
  DataRes := pSetScript700Data(0, nil, 0);
  if DataRes = 0 then
    Ok('SetScript700Data (pData=nil): returned 0, as documented')
  else
    Fail(Format('SetScript700Data (pData=nil): expected 0, got %d', [DataRes]));

  // === Phase 11: SetTimerTrick, enable briefly, then disable ===
  pSetTimerTrick(0, 1000);
  WriteChunkToFile(CHUNK_SAMPLES * 2);
  pSetTimerTrick(0, 0);          // wait=0 disables
  Ok('SetTimerTrick enabled/disabled (port=0)');

  // 'port' is encoded as a raw byte into the generated Script700 bytecode ('Mov CL,[port] / Mov
  // [PSI+0Eh],CL', APU.asm), with no range check, but only port=0 was exercised above.  InPort
  // (Phase 5) already covers all 4 SNES I/O ports for its own address parameter, so match that
  // coverage here too.
  for TimerPortIdx := 1 to 3 do
  begin
    pSetTimerTrick(Cardinal(TimerPortIdx), 1000);
    WriteChunkToFile(CHUNK_SAMPLES);
    pSetTimerTrick(Cardinal(TimerPortIdx), 0);
  end;
  Ok('SetTimerTrick enabled/disabled on all 4 SNES I/O ports');

  // === Phase 12: SetSPCDbg 'opts' flag sweep (SPC_RETURN, SPC_HALT, DSP_HALT, SPC_NODSP,
  //     SPC_TRACE, DSP_PAUSE) ===
  // Each flag is registered alone, exercised with a short burst of playback, and restored to plain
  // SPC_TRACE afterward, matching the standing state Phases 8-11 above already relied on for
  // SpcTraceStub to keep firing, and that later phases (including Phase 13's own regression check
  // right below) continue to assume.

  // DSP_HALT is checked directly inside EmuDSP ('Test byte [dbgOpt],DSP_HALT / JNZ .Mute', see
  // DSP.asm), so it reliably silences output, verified via WriteChunkCheckSilent, the same
  // technique the mixType=0 test (Phase 2) uses.
  pSetSPCDbg(@SpcTraceStub, DSP_HALT);
  if WriteChunkCheckSilent(CHUNK_SAMPLES) then
    Ok('SetSPCDbg opts=DSP_HALT: output buffer is silent, as expected')
  else
    Fail('SetSPCDbg opts=DSP_HALT: output buffer contains nonzero samples');

  // SPC_HALT only stops EmuSPC (SPC700 instruction execution); DSP mixing keeps running off the
  // last SPC700 register state via EmuAPUI's own unconditional EmuDSP call (APU.asm), which checks
  // nothing in dbgOpt except DSP_HALT above, so SPC_HALT alone is NOT guaranteed to produce
  // silence, unlike SPC700.h's own (stale) comment for it claims.  Checked here only for 'plays
  // without crashing', not for silence.
  pSetSPCDbg(@SpcTraceStub, SPC_HALT);
  WriteChunkToFile(CHUNK_SAMPLES);
  Ok('SetSPCDbg opts=SPC_HALT: played without crashing');

  // SPC_NODSP/DSP_PAUSE have narrower effects (skip the SPC700-triggered DSP catch-up call, and
  // skip envelope updates, respectively) that do not silence the whole stream, so only exercised
  // for 'plays without crashing', the same bar EmuAPU's type=0/255 modes (Phase 3) use.
  pSetSPCDbg(@SpcTraceStub, SPC_NODSP);
  WriteChunkToFile(CHUNK_SAMPLES);
  Ok('SetSPCDbg opts=SPC_NODSP: played without crashing');

  pSetSPCDbg(@SpcTraceStub, DSP_PAUSE);
  WriteChunkToFile(CHUNK_SAMPLES);
  Ok('SetSPCDbg opts=DSP_PAUSE: played without crashing');

  // SPC_TRACE alone: the standing state the rest of this run otherwise uses continuously, included
  // here only so the sweep is complete and explicit rather than relying on it being implicitly
  // exercised everywhere else.
  pSetSPCDbg(@SpcTraceStub, SPC_TRACE);
  WriteChunkToFile(CHUNK_SAMPLES);
  Ok('SetSPCDbg opts=SPC_TRACE: played without crashing');

  // SPC_RETURN (SPC700.h): 'This flag only works when used with SPC_TRACE.'  Registered alone
  // here, it should be a pure no-op (SetSPCDbgI resets pOpFetch to the non-tracing SPCFetch
  // whenever SPC_TRACE is not set, so SPCBreak's own SPC_RETURN check is never reached at all).
  // Checked only for 'plays without crashing', the same bar as SPC_NODSP/DSP_PAUSE/SPC_TRACE above:
  // asserting the output is NOT silent would be unreliable here, since RunDSP's envelope updates
  // keep running during the SPC_HALT test just above regardless of dbgOpt, and can decay a voice to
  // genuine silence within that one short burst, leaving no new note-on to revive it in time for
  // this equally short one.
  //
  // SPC_RETURN combined with SPC_TRACE is deliberately NOT tested.  Traced by hand through
  // SPC700.asm's SPCTrace/SPCBreak/SPCTimers: once SPC_RETURN (or SPC_HALT) is set while tracing,
  // 'Test byte [dbgOpt],SPC_HALT | SPC_RETURN / JNZ SPCTimers' skips the traced instruction's
  // dispatch entirely, so SPCTimers computes zero cycles consumed this lap ('clkExec - clkLeft',
  // unchanged since nothing was dispatched) and loops back to SPCTrace via 'Jmp PBP' without making
  // any progress.  SpcTraceStub is a deliberate no-op (see its own comment) that never clears the
  // flag the way a real debugger would, so this combination would retrace the same instruction
  // forever, an unbounded hang with the same shape as the mixType=0 bug this session already
  // root-caused, this time inside SPC700.asm's fetch loop rather than DSP.asm's RunDSP.
  pSetSPCDbg(@SpcTraceStub, SPC_RETURN);
  WriteChunkToFile(CHUNK_SAMPLES);
  Ok('SetSPCDbg opts=SPC_RETURN (alone, no SPC_TRACE): played without crashing');

  pSetSPCDbg(@SpcTraceStub, SPC_TRACE);      // restore the standing state the rest of this run uses
  Ok('SetSPCDbg opts sweep tested (SPC_RETURN, SPC_HALT, DSP_HALT, SPC_NODSP, DSP_PAUSE)');

  // === Phase 13: SeekAPU, both seek methods ===
  // time=0 is SeekAPU's very first check ('Test EAX,EAX / RetZF'), returning immediately without
  // touching anything.  No other phase ever calls SeekAPU with time=0, so this exercises that
  // early-out path directly, for both fast values, instead of only ever passing a nonzero time.
  pSeekAPU(0, 0);
  pSeekAPU(0, 1);
  Ok('SeekAPU (time=0, both fast values): returned immediately without crashing');
  pSeekAPU(10 * 64000, 0);       // seek 10s forward, non-fast method
  Ok('SeekAPU (fast=0)');
  WriteChunkToFile(CHUNK_SAMPLES * 2);
  pSeekAPU(10 * 64000, 1);       // seek 10s forward again, fast method
  Ok('SeekAPU (fast=1)');
  WriteChunkToFile(CHUNK_SAMPLES * 2);

  // Direct, non-destructive regression test for the x64-only crash this port already hit and
  // fixed (see x64.inc's CallArg/ExtCallArg, and SPC700.asm's SetSPCDbgI): SeekAPU's fast path
  // internally calls 'SetSPCDbgI,-1,...' twice, '-1' meaning 'leave pDebug unchanged'.  Calling
  // SetSPCDbg/SetDSPDbg again now and checking the returned previous pointer, which both
  // functions always report before touching anything, proves those internal -1 calls really did
  // leave pDebug/pTrace as the addresses registered at startup, instead of the bogus
  // 0x00000000FFFFFFFF value the pre-fix bug corrupted them to.  This also restores SPC_TRACE in
  // dbgOpt, which SeekAPU's fast path clears and nothing else re-enables, so SpcTraceStub keeps
  // firing for the rest of the run instead of going permanently silent after this phase.
  OldPDebug := pSetSPCDbg(@SpcTraceStub, SPC_TRACE);
  if OldPDebug = @SpcTraceStub then
    Ok('SetSPCDbg: pDebug unchanged by SeekAPU (fast=1)''s internal -1 sentinel calls')
  else
    Fail(Format('SetSPCDbg: pDebug corrupted, expected %p, got %p', [Pointer(@SpcTraceStub), OldPDebug]));

  OldPTrace := pSetDSPDbg(@DspTraceStub);
  if OldPTrace = @DspTraceStub then
    Ok('SetDSPDbg: pTrace unchanged (SetDSPDbgI''s own -1 path is not exercised internally yet)')
  else
    Fail(Format('SetDSPDbg: pTrace corrupted, expected %p, got %p', [Pointer(@DspTraceStub), OldPTrace]));

  // === Phase 14: GetSNESAPUContext / SetSNESAPUContext round-trip, distant snapshot ===
  // Snapshots at point P, plays segment X right after P, then plays a further, unrelated stretch,
  // simulating time passing after a save, before restoring to P and replaying the same length into
  // Y.  This shows the restore genuinely rewinds past the intervening stretch, not just undoing the
  // single step right above it.  X's hash is redundant with the main PCM diff, since X is also
  // written to the output file below, but Y is otherwise never persisted anywhere, so logging its
  // hash is what makes Y itself cross-architecture comparable.  A self-consistent-but-wrong restore
  // on one build alone would show up as a log diff here even though the X==Y check passed locally.
  CtxSize := pGetSNESAPUContextSize();
  LogLine(Format('GetSNESAPUContextSize=%d (IGNORE_ARCH_DIFF, layout depends on pointer width)',
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
    Fail('GetSNESAPUContext/SetSNESAPUContext round-trip: X != Y, restore did not reproduce the original continuation');
  // State after Y is identical to state after X, by the check above, or if it failed, this
  // diverges from the main stream from here on regardless, itself informative.  Continue the
  // main stream.

  // === Phase 15: FixAPU round-trip ===
  // ppRAM direct copy + GetSPCRegs, same X/Y-hash reasoning as Phase 14 above.  The register values
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
    Fail('FixAPU round-trip (raw RAM restore): X != Y, FixAPU did not resync state to reproduce the original continuation');

  // === Phase 16: SetAPULength fade-out and revival ===
  // song=1s, fade=2s puts t64Cnt past songLen almost immediately, so SetFade drives DSP volume
  // toward silence over the following 2 seconds.  4 seconds of playback captures that fade curve
  // completing.  song=-1 (Cardinal 0xFFFFFFFF) means 'never ends', per SetDSPLength's unsigned
  // comparison against t64Cnt, forcing volume back to full immediately, so the song should be
  // audible again over the next 2 seconds.  ResetAPU, then a fresh LoadSPCFile, restores playback
  // position and SetAPULength's own state (songLen/fadeLen), so this excursion does not affect
  // Phase 19 below.  Neither call touches the SetAPUOpt format settings (rawRate/rawChn/rawBits/
  // dspOpts), which only InitAPU, run once at DLL load, initializes, so no need to redo SetAPUOpt.
  TotalLen := pSetAPULength(1 * 64000, 2 * 64000);
  LogKV('FadeTest_SetAPULength_FadeOut_Result', IntToStr(TotalLen));
  WriteChunkToFile(4 * 96000);                     // 4 seconds at the 96000Hz rate active here
  Ok('SetAPULength fade-out: 4s captured');

  // Combines the fade with SeekAPU's fast path, a combination no earlier phase exercises: Phase 13
  // already seeks while the song is at full volume, this seeks while it is faded to silence, so
  // any interaction between SetFade's volume ramp and the fast path's DSP-write suppression
  // (SPC_NODSP) would surface here instead of staying hidden behind the two phases never
  // overlapping.
  pSeekAPU(5 * 64000, 1);
  WriteChunkToFile(CHUNK_SAMPLES);
  Ok('SeekAPU (fast=1) while faded: played without crashing');

  TotalLen := pSetAPULength(Cardinal(-1), 0);
  LogKV('FadeTest_SetAPULength_Revive_Result', IntToStr(TotalLen));
  WriteChunkToFile(2 * 96000);                     // 2 seconds, song should be audible again
  Ok('SetAPULength revival: 2s captured');

  // fade=0: SetDSPLength's own guard ('Test EDX,EDX / SetZ AL / Or EDX,EAX', DSP.asm) converts
  // fade=0 to an internal fadeLen=1, avoiding a division by zero in SetFade's sin() curve, rather
  // than skipping the fade entirely, so a short song plus fade=0 should still reach full silence,
  // just with no perceptible ramp (one tick's worth of fade curve).  The revival call just above
  // also passes fade=0, but with song=-1 (never ends), so SetFade's own division is never actually
  // reached there; a real, already-elapsed song length is needed to exercise it, as here.  Most of
  // the elapsed time plays through WriteChunkToFile as usual, leaving the last chunk to verify
  // silence.
  TotalLen := pSetAPULength(1 * 64000, 0);
  LogKV('FadeTest_SetAPULength_FadeZero_Result', IntToStr(TotalLen));
  WriteChunkToFile(2 * 96000 - CHUNK_SAMPLES);
  if WriteChunkCheckSilent(CHUNK_SAMPLES) then
    Ok('SetAPULength (fade=0): reached full silence, as expected')
  else
    Fail('SetAPULength (fade=0): output not silent after the song''s length elapsed');

  // song=0: a literal zero-length song is immediately past its own (empty) length from the very
  // first tick ('Cmp EAX,[t64Cnt] / JB .SetFade', DSP.asm's SetDSPLength), the same '.SetFade'
  // branch the main fade-out test above already exercises via a nonzero song length, so this only
  // adds the literal zero-boundary value, not a new code path.  Should reach full silence again
  // once the (now 2s) fade curve completes.
  TotalLen := pSetAPULength(0, 2 * 64000);
  LogKV('FadeTest_SetAPULength_SongZero_Result', IntToStr(TotalLen));
  WriteChunkToFile(2 * 96000 - CHUNK_SAMPLES);
  if WriteChunkCheckSilent(CHUNK_SAMPLES) then
    Ok('SetAPULength (song=0): reached full silence, as expected')
  else
    Fail('SetAPULength (song=0): output not silent after the fade completed');

  pResetAPU($10000);
  pLoadSPCFile(@SpcData[0]);
  Ok('ResetAPU / LoadSPCFile: SetAPULength state reset');

  // === Phase 17: FixAPU with extreme register values ===
  // Exercises FixAPU's byte/word parameter marshaling (see APU.asm's NOTE on zero-extending each
  // field to a dword-sized local before the internal Call) at both ends of every field's range,
  // not just the real, mid-range values the round-trip in Phase 15 used.  SPC700 has no undefined
  // opcode, so any PC/A/Y/X/PSW/SP combination decodes and runs, producing deterministic, if
  // musically meaningless, output.  ResetAPU plus a fresh LoadSPCFile afterward discards this
  // excursion, matching Phase 16's own cleanup pattern.
  pFixAPU($FFFF, $FF, $FF, $FF, $FF, $FF);
  WriteChunkToFile(CHUNK_SAMPLES);
  Ok('FixAPU (all-0xFF edge values): played without crashing');

  pFixAPU($0000, $00, $00, $00, $00, $00);
  WriteChunkToFile(CHUNK_SAMPLES);
  Ok('FixAPU (all-0x00 edge values): played without crashing');

  pResetAPU($10000);
  pLoadSPCFile(@SpcData[0]);
  Ok('ResetAPU / LoadSPCFile: FixAPU edge-value excursion reset');

  // === Phase 18: ResetAPU with amp=-1 (skip amp change) and amp=0 (full mute) ===
  // amp=-1 is ResetAPUI's 'Cmp dword [ampI],-1 / JE .NoAmp', skipping the SetDSPAmpI call that
  // would otherwise rescale the output volume, while ResetSPC/ResetDSP still run unconditionally
  // either way.  Every other ResetAPU call in this tool passes $10000 (1.0x), so this exercises
  // that skip directly.  A fresh LoadSPCFile follows, matching every other excursion's cleanup
  // pattern, since ResetAPU alone, without it, would leave playback reset but not reloaded.
  pResetAPU(Cardinal(-1));
  pLoadSPCFile(@SpcData[0]);
  Ok('ResetAPU (amp=-1): played through the amp-change skip without crashing');

  // amp=0 takes the opposite path from amp=-1 above: ResetAPUI's own 'Cmp dword [ampI],-1' does
  // NOT match, so SetDSPAmpI actually runs, the same clamp/scale logic exercised directly via
  // SetDSPAmp's own boundary block in Phase 4, but reached this time through ResetAPU's entry
  // point instead.
  pResetAPU(0);
  WriteChunkToFile(CHUNK_SAMPLES);
  Ok('ResetAPU (amp=0): played through full-mute reset without crashing');
  pResetAPU($10000);
  pLoadSPCFile(@SpcData[0]);
  Ok('ResetAPU (amp=$10000): normal playback restored');

  // === Phase 19: closing stretch of plain playback ===
  // A fixed length, not a caller-supplied total, see FINAL_PADDING_SAMPLES and the header comment.
  WriteChunkToFile(FINAL_PADDING_SAMPLES);

  CloseFile(fOut);

  // === Optional: '-wav' 5-second render ===
  // A separate, fixed-format excursion for quick listening/spot-checking, not part of the x86/x64
  // comparison stream above.  Deliberately placed here, after all 19 phases' excursions, so it
  // doubles as a human-audible confirmation that ResetAPU/LoadSPCFile leave the DLL in a normal
  // state even after everything above, not just that the in-process FAIL checks passed.
  if WantWav then
  begin
    WavPath := ChangeFileExt(LogPath, '.wav');

    pResetAPU($10000);
    pLoadSPCFile(@SpcData[0]);
    pSetAPUOpt(1, WAV_CHANNELS, WAV_BITS, WAV_RATE, INT_GAUSS, 0);

    if FileExists(SongScript700Path) then
      TestScript := LoadTextFile(SongScript700Path)
    else if FileExists(FallbackScript700Path) then
      TestScript := LoadTextFile(FallbackScript700Path)
    else
      TestScript := '';
    if TestScript <> '' then
      pSetScript700(PAnsiChar(TestScript))
    else
      pSetScript700(nil);

    pSetAPULength(3 * 64000, 2 * 64000);

    AssignFile(fWav, WavPath);
    {$I-}
    Rewrite(fWav, 1);
    {$I+}
    if IOResult <> 0 then
      FatalFail(Format('Could not create WAV file "%s"', [WavPath]));

    WriteWavHeader(fWav, WAV_SAMPLES * WAV_BYTES_PER_FRAME, WAV_RATE, WAV_CHANNELS, WAV_BITS);
    WriteWavSamples(fWav, WAV_SAMPLES);
    CloseFile(fWav);

    pSetScript700(nil);          // disable again, matching every other phase's own cleanup pattern
    Ok(Format('WAV file written: "%s" (%d seconds)', [WavPath, WAV_SECONDS]));
  end;

  // Disable every callback before unload, symmetrical with how they were enabled.  SNESAPUCallback
  // was never unregistered anywhere above, unlike SetDSPDbg/SetSPCDbg, and its own pCbFunc=nil
  // path (APU.asm: 'Mov [apuCbFunc],PBX', unconditionally, unlike cbMask's OR-together chain-call
  // method just below it) was never exercised either.  The returned previous pointer is checked
  // against APUCallback itself, the same non-destructive-regression shape Phase 13 already uses
  // for SetSPCDbg/SetDSPDbg.
  OldPCallback := pSNESAPUCallback(nil, 0);
  if OldPCallback = @APUCallback then
    Ok('SNESAPUCallback: unregistered (pCbFunc=nil), previous callback reported correctly')
  else
    Fail(Format('SNESAPUCallback: expected previous callback %p, got %p',
      [Pointer(@APUCallback), OldPCallback]));
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
  LogKV('IncS700CallbackCount', IntToStr(IncS700CallbackCount));
  LogKV('IncDataCallbackCount', IntToStr(IncDataCallbackCount));
  LogKV('ReqBPCallbackCount', IntToStr(ReqBPCallbackCount));
  LogKV('DspTraceStubCount', IntToStr(DspTraceCount));
  LogKV('SpcTraceStubCount', IntToStr(SpcTraceCount));
  if DspCallbackCount = 0 then Warn('SNESAPUCallback (CBE_DSPREG) never fired');
  if SpcFetchCallbackCount = 0 then Warn('SNESAPUCallback (CBE_S700FCH) never fired');
  if IncS700CallbackCount = 0 then Warn('SNESAPUCallback (CBE_INCS700) never fired');
  if IncDataCallbackCount = 0 then Warn('SNESAPUCallback (CBE_INCDATA) never fired');
  if ReqBPCallbackCount = 0 then Warn('SNESAPUCallback (CBE_REQBP) never fired');
  if DspTraceCount = 0 then Warn('SetDSPDbg (pTrace) never fired');
  if SpcTraceCount = 0 then Warn('SetSPCDbg (pDebug) never fired');

  LogLine('');
  if FailCount = 0 then
    LogLine('=== ALL IN-PROCESS CHECKS PASSED (0 failures) ===')
  else
    LogLine(Format('=== %d IN-PROCESS CHECK(S) FAILED, see FAIL lines above ===', [FailCount]));

  CloseFile(fLog);

  // Non-zero exit code on any FAIL, so a caller (batch file, CI step) can detect a failed run from
  // '%errorlevel%'/its own exit-code check alone, without having to parse the log.
  if FailCount <> 0 then
    ExitCode := 1;
end.
