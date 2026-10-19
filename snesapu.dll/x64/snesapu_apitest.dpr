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
   - GetSNESAPUContext/SetSNESAPUContext (Phase 14): its state layout depends on pointer width, so
     x86/x64 output is NOT expected to match byte-for-byte, unlike everywhere else.  Instead does an
     in-process round-trip (snapshot, replay a stretch, restore, replay the same length again,
     compare the two results byte-for-byte), which must pass independently on each build.  FixAPU
     (Phase 15) used to be checked the same way, but that assertion does not hold in general (see
     that phase's own comment), so it now only checks that FixAPU writes its given register values
     back correctly, via GetSPCRegs readback, an ordinary check like everywhere else.
   - SetDSPDbg/SetSPCDbg's callbacks (Phase 12/13) bypass x64.inc's ExCall entirely, using a
     hand-rolled, non-ABI-standard stack protocol instead (see DspTraceStub/SpcTraceStub below),
     since the Windows x64 ABI has no calling-convention mode for it.  A real regression target for
     this port's hand-rolled stack alignment, even with an otherwise-inert stub.
   - GetSNESAPUContextSize's byte count is expected to differ between x86/x64 (same pointer-width
     reason as above), and the log marks that line accordingly, not as a failure.

 Build (once per architecture):
   fpc -Pi386   -Twin32 snesapu_apitest.dpr
   fpc -Px86_64 -Twin64 snesapu_apitest.dpr

 Usage:
   snesapu_apitest.exe <dll path> <spc file path> <out pcm path> [script700 file] [-wav]

 <out pcm path> names the PCM output file directly (e.g. 'out_x86.pcm').  All log output (every
 Info/Ok/Warn/Fail/LogKV line) goes to stdout only, not to a file; redirect it yourself if you want
 to keep or diff it (see 'Compare two runs' below).

 Exit code: 0 if every in-process check passed (0 FAIL lines), 1 if any check failed or a fatal
 setup error (ERROR: line) aborted the run early, so a caller can tell success from failure without
 parsing the log.

 '-wav', if given (in any position among the arguments), additionally renders 5 fixed seconds of
 playback to a WAV file named after <out pcm path> with a '.wav' extension (e.g. 'out_x86.pcm' ->
 'out_x86.wav'): stereo, 16-bit, 32000Hz, INT_GAUSS interpolation, opts=0, SetScript700 paired the
 same way Phase 9 is, SetAPULength song=3s/fade=2s.  A quick-listening convenience, separate from
 and not part of the x86/x64 comparison stream above.

 The phases below already generate a fixed, deterministic amount of PCM output on their own
 (currently around 8 seconds), so there is no separate sample-count argument to grow or shrink the
 run: every run of the same .spc file produces the same length of output.

 Compare two runs (one per architecture, same .spc file):
   snesapu_apitest_x86.exe snesapu.dll     song.spc out_x86.pcm > out_x86.log
   snesapu_apitest_x64.exe snesapu_x64.dll song.spc out_x64.pcm > out_x64.log
   fc /b out_x86.log out_x64.log
   fc /b out_x86.pcm out_x64.pcm

 Then compare the two runs' redirected log output for the text-comparable values: SNESAPUInfo,
 GetScript700Data's version string, SetAPULength's fade-out/revival returned totals, the context
 round-trip hashes, the callback fire counts.
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
  // Phase 20's closing padding.  Small on purpose: it exercises nothing new, just flows a little
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
  // Caps how many of SNESAPUCallback/SetDSPDbg/SetSPCDbg's many firings actually perform the real
  // Win32 API call (see TestWin32APIFromCallback): enough to exercise the path repeatedly without
  // making every single DSP register write or SPC700 trace step pay for a real CreateFileW round
  // trip, which would needlessly slow down the whole run.
  WIN32_API_TEST_LIMIT = 3;
  // Win32APITestCount/FailCount indices (see TestWin32APIFromCallback): one budget of
  // WIN32_API_TEST_LIMIT attempts per distinct raw-callback entry point, not one shared budget,
  // so a source that fires rarely cannot be starved out by one that fires often.
  WTS_EXCALL      = 0;   // SNESAPUCallback, via ExCall
  WTS_DSPTRACE    = 1;   // SetDSPDbg's pTrace, via DspTraceStub
  WTS_SPCTRACE    = 2;   // SetSPCDbg's pDebug, via SpcTraceStub
  WTS_COUNT       = 3;
  WTS_NAMES: array[0..WTS_COUNT-1] of String = ('ExCall', 'DspTrace', 'SpcTrace');
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
  VOICE_MFLG_OFS  = 13;                                  // mFlg: resb, at byte offset 13 (see MixF)
  VOICE_MTGT_OFS  = 96;                                  // mTgtL, mTgtR: 2 resd, at byte offset 96
  // Phase 22: the x87 control word a misbehaving host callback leaves behind, round toward zero
  // with 24-bit precision and every exception still masked.  Any DLL FPU code that runs under it
  // instead of 037Fh rounds differently.
  CW_TAMPER       = $0C7F;
  // Phase 25: one sample is exactly 128 APU clock cycles at this rate, and 0.1 second of calls.
  SMPLOSS_RATE    = 192000;
  SMPLOSS_CALLS   = 19200;
  // Request sizes in APU clock cycles for the type 0 check.  With the 'DIV YA,X' loop, 64 and 96
  // make many requests end exactly at the time the SPC700 already reached, 1, 95, 97, 127 and 287
  // make some end one cycle after it, and every size but 287 makes others end before it.
  SMPLOSS_REQ: array[0..7] of Cardinal = (1, 64, 95, 96, 97, 127, 128, 287);
  // Phase 26: 0.1 second of APU clock cycles, which the DSP runs as 3200 samples at 32kHz and
  // resamples to 4800 at this rate.
  HALT_RATE       = 48000;
  HALT_CYCLES     = 2457600;
  HALT_SAMPLES    = 4800;
  // Phase 27: a type 1 request at this rate is not a whole number of APU clock cycles, so part of
  // it is made ahead into 'outBuf'.
  KEEPBUF_RATE    = 44100;
  KEEPBUF_SAMPLES = 100;
  // Phase 28: one long type 1 request per case, each at or past the limit that a
  // single EmuAPUBySmp call used to break at.  Speed, channels, bits, rate, opts, samples.
  LONGREQ_COUNT   = 3;
  LONGREQ_CANARY  = 16;                                  // bytes checked after the expected end
  LONGREQ_NAMES: array[0..LONGREQ_COUNT-1] of String = (
    'outBuf overflow (x15.99, 192kHz, DSP_ECHOFIR, 3 s)',
    'Div overflow (8000Hz, 175 s)',
    'speed overflow (x16, 48000Hz, 12.5 s)');
  LONGREQ_SPEED: array[0..LONGREQ_COUNT-1] of Cardinal = (1048052, $10000, $100000);
  LONGREQ_CHN:   array[0..LONGREQ_COUNT-1] of Cardinal = (2, 1, 1);
  LONGREQ_BITS:  array[0..LONGREQ_COUNT-1] of Cardinal = (32, 8, 8);
  LONGREQ_RATE:  array[0..LONGREQ_COUNT-1] of Cardinal = (192000, 8000, 48000);
  LONGREQ_OPTS:  array[0..LONGREQ_COUNT-1] of Cardinal = (DSP_ECHOFIR, 0, 0);
  LONGREQ_LEN:   array[0..LONGREQ_COUNT-1] of Cardinal = (576000, 1400000, 600000);
  // Phase 29: a type 0 request at x16 whose speed-adjusted cycles come to exactly 2^32, which used
  // to wrap to 0 cycles.  Mono 8-bit at 8000Hz keeps the buffer small.
  LONG0_SPEED     = $100000;
  LONG0_RATE      = 8000;
  LONG0_LEN       = $10000000;                           // about 10.9 s, 2^32 cycles at x16
  LONG0_CLK       = 24576000;                            // APU_CLK
  LONG0_T64       = 11184810;                            // 2^32 cycles in 64kHz ticks (384 each)
  // MixF's user-facing bits (DSP.h), both in Voice.mFlg.
  MFLG_MUTE       = $01;
  MFLG_NOISE      = $02;
  MFLG_OFF        = $08;                                 // voice inactive (DSP.inc), set by the DLL

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
  HostCW: Word;                                          // x87 control word before loading the DLL
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
  // See TestWin32APIFromCallback's own comment: a real Win32 API call made from inside
  // SNESAPUCallback/SetDSPDbg/SetSPCDbg's callbacks, regression-testing the stack-alignment fix
  // those raw callback paths needed.  Attempts is bounded per source (see WIN32_API_TEST_LIMIT/
  // WTS_*), so this stays a handful of real calls per callback source, not one for every DSP
  // register write.
  Win32APITestCount, Win32APITestFailCount: array[0..WTS_COUNT-1] of Int64;
  // Two more direct checks of the same DspTraceStub/SpcTraceStub entry point Win32APITestCount
  // already exercises, both cheap enough to run on every single firing, not just a bounded few:
  //   - AlignedSSEProbeCount: a 'movaps' executed against an address computed to be 16-byte
  //     aligned only if the entry RSP genuinely was 8 mod 16.  Faults immediately and
  //     deterministically if not, independent of whatever any external DLL like kernelbase does
  //     (unlike the CreateFileW test above, which depends on kernelbase using aligned SSE somewhere
  //     in its own call graph, an implementation detail that could change in a future Windows
  //     version without this branch's own fix regressing).
  //   - CallbackEntryAlignmentOKCount/BadCount: the same entry RSP's parity (mod 16), reported as a
  //     plain number via CheckCallbackEntryAlignment, so a regression is visible in the log even if
  //     the 'movaps' probe above is ever removed or does not fire first for some reason.
  AlignedSSEProbeCount: Int64;
  CallbackEntryAlignmentOKCount, CallbackEntryAlignmentBadCount: Int64;
  FailCount: Integer;

  // GetAPUData results.  Every "pp"-prefixed param is pointer-to-pointer, the DLL writes back an
  // internal address, so each of these captures a Pointer, not a value.
  gRAM, gXRAM, gOutPort, gT64Cnt, gDSP, gVoice, gVMMaxL, gVMMaxR: Pointer;

  // Log output.  A line-oriented KEY=VALUE log lets 'fc'/'diff' catch a divergence between the x86
  // and x64 run automatically, the same way byte-diffing the PCM output already does for the audio
  // itself, as long as it is redirected to a file (see this file's own header comment); this tool
  // itself only ever writes it to stdout.
  PcmHash: Cardinal;

  // Scratch used by several phases below.
  CtxSize: Cardinal;
  CtxBuf: array of Byte;
  SegX, SegY: array of Byte;
  SegLen: Cardinal;
  RegPC, NewRegPC, TestRegPC: Word;
  RegA, RegY, RegX, RegPSW, RegSP: Byte;
  NewRegA, NewRegY, NewRegX, NewRegPSW, NewRegSP: Byte;
  TestRegA, TestRegY, TestRegX, TestRegPSW, TestRegSP: Byte;
  DecOp, DecIdx, DecFailCount: Integer;                  // Phase 21 (DAA/DAS sweep)
  DecInA, DecInPSW, DecExpA, DecExpPSW: Byte;
  // Phase 22: while CWTamper is set, APUCallback's CBE_S700FCH case loads CW_TAMPER, counted in
  // CWTamperCount, so a scenario can confirm the callback really fired during it.
  CWTamper: Boolean;
  CWTamperCount: Int64;

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

// Hashes the Voice array (Count voices, Stride bytes each).  sIdx is a real pointer into the
// voice's own sample buffer on x86, but a small offset relative to that same buffer on x64 (see
// DSP.asm's StartSrc note), and bCur is a real pointer into decoded sample RAM on x86, but a
// pAPURAM-relative offset on x64, so neither is directly comparable as raw bytes.  Both are
// normalized, in a scratch copy before hashing, to what x64 already stores natively: the low 16
// bits of the offset from the pointer they are relative to (RAMBase for bCur, this voice's own
// address for sIdx).  Normalizing rather than masking to zero means a real mismatch in either
// still shows up instead of being hidden.  Low 16 bits only, since bCur's offset lives within
// pAPURAM's 64KB SPC address space and sIdx's within this 128-byte voice's own sBuf, so nothing
// meaningful lives above bit 15 on either architecture.
//
// A voice that has never been keyed on yet still has its raw field at 0 (StartSrc is the only
// place that ever assigns it, see DSP.asm).  On x64 that 0 is already the correct, comparable
// offset, but on x86 it is a NULL pointer rather than a real one, so subtracting the base from it
// would produce (0 minus this voice's own address), an ASLR-dependent value that varies from run
// to run and bears no relation to the other build's 0.  Both sides are left at 0 in that case
// instead of going through the subtraction.
function HashVoiceArray(P: Pointer; Count, Stride: NativeUInt; RAMBase: Pointer): Cardinal;
var
  i: NativeUInt;
  Scratch: array[0..VOICE_STRIDE-1] of Byte;
  RawBCur, RawSIdx: Cardinal;
  NormBCur, NormSIdx: Word;
begin
  Result := FNV32_SEED;
  for i := 0 to Count - 1 do
  begin
    Move(PByte(P)[i * Stride], Scratch[0], Stride);
    RawBCur := PCardinal(@Scratch[VOICE_BCUR_OFS])^;
    RawSIdx := PCardinal(@Scratch[VOICE_SIDX_OFS])^;
    {$IFDEF CPU64}
    NormBCur := RawBCur and $FFFF;
    NormSIdx := RawSIdx and $FFFF;
    {$ELSE}
    if RawBCur = 0 then
      NormBCur := 0
    else
      NormBCur := Word(RawBCur - Cardinal(NativeUInt(RAMBase)));
    if RawSIdx = 0 then
      NormSIdx := 0
    else
      NormSIdx := Word(RawSIdx - Cardinal(NativeUInt(P) + i * Stride));
    {$ENDIF}
    PCardinal(@Scratch[VOICE_BCUR_OFS])^ := NormBCur;
    PCardinal(@Scratch[VOICE_SIDX_OFS])^ := NormSIdx;
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

// Writes to stdout, for a human watching it run, or for 'fc'/'diff' against the other
// architecture's run afterward if redirected to a file.  Every line that should be identical
// between the x86 and x64 runs goes through this, in a fixed order, so two redirected log files
// line up 1:1.
procedure LogLine(const Line: String);
begin
  WriteLn(Line);
end;

procedure LogKV(const Key, Value: String);
begin
  LogLine(Key + '=' + Value);
end;

// Logs Prefix_DSP_Hash/Prefix_Voice_Hash, the two GetAPUData outputs directly comparable across
// x86/x64 (gDSP has no embedded pointers at all; HashVoiceArray normalizes bCur/sIdx into the same
// offset both architectures use).  Called once at the end of every PCM phase below, one pair of log
// lines per phase rather than a single running hash, so a divergence's log line pinpoints the
// phase it first appeared in instead of just proving one exists somewhere in the whole run.
procedure CheckFpuCW(const Prefix: String); forward;

procedure LogStateHash(const Prefix: String);
begin
  LogKV(Prefix + '_DSP_Hash', Format('%.8x', [HashMem(gDSP, 128)]));
  LogKV(Prefix + '_Voice_Hash', Format('%.8x', [HashVoiceArray(gVoice, VOICE_COUNT, VOICE_STRIDE, gRAM)]));
  CheckFpuCW(Prefix);
end;

// Reads the x87 FPU control word.  Every snesapu export saves the caller's control word on entry
// and restores it on return (the EXPROC/ENDP guard in x86.inc/x64.inc), so it must still match
// HostCW after any sequence of calls.
function GetX87CW: Word; assembler; nostackframe;
asm
  {$IFDEF CPU64}
  push    rax
  fnstcw  [rsp]
  pop     rax
  {$ELSE}
  push    eax
  fnstcw  [esp]
  pop     eax
  {$ENDIF}
  movzx   eax, ax
end;

// Loads CW into the x87 control word.  Only Phase 22's tampering callback uses it, to change the
// control word the way a host callback might, so the DLL's own resets can be checked.
procedure SetX87CW(CW: Word); assembler; nostackframe;
asm
  {$IFDEF CPU64}
  push    rcx
  fldcw   [rsp]
  pop     rcx
  {$ELSE}
  push    eax
  fldcw   [esp]
  pop     eax
  {$ENDIF}
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

// Called at the end of every phase.  Logs nothing when the control word is intact, so the x86 and
// x64 logs stay identical, and only a real change shows up as a FAIL line.
procedure CheckFpuCW(const Prefix: String);
var
  CW: Word;
begin
  CW := GetX87CW;
  if CW <> HostCW then
    Fail(Format('%s: x87 control word changed across snesapu calls (%.4x, expected %.4x)',
      [Prefix, CW, HostCW]));
end;

const
  PSW_C = $01;
  PSW_Z = $02;
  PSW_H = $08;
  PSW_N = $80;

// The hardware's DAA/DAS (bsnes SMP::instructionDecimalAdjustAdd/Sub), the reference for Phase 21.
// Only A, N, Z, and C change.  For DAS, a borrow from the low nibble adjustment does not touch C.
procedure RefDecimalAdjust(IsSub: Boolean; InA, InPSW: Byte; out OutA, OutPSW: Byte);
var
  R: Integer;
  C, H: Boolean;
begin
  R := InA;
  C := (InPSW and PSW_C) <> 0;
  H := (InPSW and PSW_H) <> 0;
  if not IsSub then
  begin
    if C or (R > $99) then
    begin
      R := (R + $60) and $FF;
      C := True;
    end;
    if H or ((R and $0F) > 9) then
      R := (R + 6) and $FF;
  end
  else
  begin
    if (not C) or (R > $99) then
    begin
      R := (R - $60) and $FF;
      C := False;
    end;
    if (not H) or ((R and $0F) > 9) then
      R := (R - 6) and $FF;
  end;

  OutA := R;
  OutPSW := InPSW and not (PSW_N or PSW_Z or PSW_C);
  if R >= $80 then
    OutPSW := OutPSW or PSW_N;
  if R = 0 then
    OutPSW := OutPSW or PSW_Z;
  if C then
    OutPSW := OutPSW or PSW_C;
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

// Calls a real Win32 API function (CreateFileW, read mode) from inside whichever callback invoked
// it, regression-testing the stack-alignment fix SNESAPUCallback (via ExCall) and SetDSPDbg/
// SetSPCDbg (via their own raw stack protocol; see x64.inc's AlignRawCallBegin/AlignRawCallEnd)
// needed: the original bug surfaced exactly this way, a host callback calling CreateFileW several
// frames into ntdll/kernelbase, which use aligned SSE instructions that fault on a misaligned
// stack, not from anything this simple round trip does by itself.  'Source' is one of the WTS_*
// constants, identifying which of the three raw-callback entry points made this particular call;
// each gets its own WIN32_API_TEST_LIMIT budget (see Win32APITestCount's own comment), so whichever
// source happens to fire most often during a run cannot silently consume the only shared budget and
// leave another source completely untested.  Opens SpcPath itself, since it is already guaranteed
// to exist for the whole run, rather than creating a separate temp file.
procedure TestWin32APIFromCallback(Source: Integer);
var
  hFile: THandle;
begin
  if Win32APITestCount[Source] >= WIN32_API_TEST_LIMIT then Exit;
  Inc(Win32APITestCount[Source]);
  hFile := CreateFileW(PWideChar(WideString(SpcPath)), GENERIC_READ, FILE_SHARE_READ, nil,
    OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
  if hFile = INVALID_HANDLE_VALUE then
  begin
    Inc(Win32APITestFailCount[Source]);
    Fail(Format('Win32 API call (CreateFileW) from inside a callback (source=%d) failed: ' +
      'GetLastError=%d', [Source, GetLastError]));
  end
  else
  begin
    CloseHandle(hFile);
    Ok(Format('Win32 API call (CreateFileW) from inside a callback (source=%d) succeeded',
      [Source]));
  end;
end;

// Reports the raw entry RSP's alignment (mod 16), captured by DspTraceStub/SpcTraceStub's own raw
// asm before either of them does anything else.  Per the Win64 ABI, this must be 8 at any genuine
// function entry point reached via a real 'call' (which always leaves RSP 8 mod 16 at the callee's
// very first instruction); DSP.asm's DSPIn/SPC700.asm's SPCBreak reaching 0 here instead is exactly
// the AlignRawCallBegin bug this branch already found and fixed once.  Every call updates the OK/
// Bad counters unconditionally, so the final summary always reflects the true count, but 'Ok' is
// only logged the first few times (see WIN32_API_TEST_LIMIT), to avoid flooding the log once a
// genuine regression is confirmed working; 'Fail' is never suppressed, since that should not
// happen at all.
procedure CheckCallbackEntryAlignment(EntryRSPParity: NativeUInt);
begin
  if EntryRSPParity = 8 then
  begin
    Inc(CallbackEntryAlignmentOKCount);
    if CallbackEntryAlignmentOKCount <= WIN32_API_TEST_LIMIT then
      Ok('Callback entry RSP alignment (mod 16 = 8, per Win64 ABI): correct');
  end
  else
  begin
    Inc(CallbackEntryAlignmentBadCount);
    Fail(Format('Callback entry RSP alignment: mod 16 = %d, expected 8 per Win64 ABI',
      [EntryRSPParity]));
  end;
end;

// x86 has no equivalent alignment requirement for this hand-rolled callback protocol (x86.inc's own
// AlignRawCallBegin is already a no-op, see its own comment), so DspTraceStub/SpcTraceStub's x86
// branch below runs no real 'movaps' probe and always reports alignment 8 (trivially true, not a
// faked pass: nothing here needs 16-byte alignment on x86 in the first place).  This keeps
// AlignedSSEProbeCount/CallbackEntryAlignmentOKCount nonzero and the final-summary log lines
// identical in shape on both builds, for the cross-architecture log diff this tool's own header
// comment describes.
procedure NoteAlignedSSEProbeSkippedOnX86;
begin
  Inc(AlignedSSEProbeCount);
end;

// SNESAPUCallback: standard ExCall path, same protocol snesapu_pcmdump.dpr already exercises.
// Registered for CBE_DSPREG, CBE_S700FCH, CBE_INCS700, CBE_INCDATA, and CBE_REQBP, covering every
// mask bit this tool exercises.  For CBE_INCS700/CBE_INCDATA, lpData points at exactly Value bytes
// of the filename text from a Script700 '#i'/'#ib' directive, not null-terminated.  The DLL never
// touches the filesystem itself for these, it only hands over the filename, so no real 'text.700'/
// 'bin.700' file needs to exist for this to run.  What a real host is expected to do with that
// filename is call back into SetScript700/SetScript700Data with the referenced file's content (see
// thirdparty/SNESAPU.cpp's IncludeScript700File), reentering the DLL's Script700 compiler from
// inside the very callback that its own outer SetScript700 call invoked, so this callback performs
// that same reentrant round-trip below, with canned content standing in for the file's real bytes,
// to exercise that path rather than only verify the filename.  CBE_REQBP fires from a Script700
// 'bp' command while RunScript700 executes the already-compiled bytecode during playback, not
// synchronously when SetScript700 compiles the script the way CBE_INCS700/CBE_INCDATA do, so the
// phase that exercises it plays some samples between setting the script and checking the count.
function APUCallback(effect, addr, value: Cardinal; lpData: Pointer): Cardinal; stdcall;
var
  Name: AnsiString;
  NestedResult: Cardinal;
  NestedBuf: array[0..15] of Byte;
  NestedIdx: Integer;
begin
  TestWin32APIFromCallback(WTS_EXCALL);  // see its own comment; exercises the ExCall path this fires on
  case effect of
    CBE_S700FCH:
      begin
        Inc(SpcFetchCallbackCount);
        if CWTamper then
        begin
          SetX87CW(CW_TAMPER);
          Inc(CWTamperCount);
        end;
      end;
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
          // Reentrant round-trip: SetScript700 called again, from inside the callback the outer
          // SetScript700 call is still executing under, matching IncludeScript700File's own
          // 'SetScript700(lpBuffer)' branch (addr=-1).  'm 0 0' is the exact prefix Phase 8's own
          // outer script already begins with, so it is already proven to compile on its own,
          // isolating this check to the reentrancy itself rather than to script content.
          NestedResult := pSetScript700(PAnsiChar(AnsiString('m 0 0' + #0)));
          LogKV('IncludeCallback_NestedSetScript700_Result', IntToStr(NestedResult));
        end
        else
        begin
          Inc(IncDataCallbackCount);
          if Name = 'bin.700' then
            Ok('CBE_INCDATA filename matches "bin.700"')
          else
            Fail(Format('CBE_INCDATA filename mismatch: got "%s"', [Name]));
          // Same reentrant round-trip as CBE_INCS700 above, but via SetScript700Data, matching
          // IncludeScript700File's 'SetScript700Data(addr, lpBuffer, dwSize)' branch.  The bytes
          // only need to survive the pointer/memcpy path, not decode as valid bytecode, the same
          // tolerance Phase 10's own SetScript700Data sanity check already relies on.
          for NestedIdx := 0 to High(NestedBuf) do NestedBuf[NestedIdx] := NestedIdx;
          NestedResult := pSetScript700Data(addr, @NestedBuf[0], SizeOf(NestedBuf));
          LogKV('IncludeCallback_NestedSetScript700Data_Result', IntToStr(NestedResult));
        end;
      end;
  else
    Inc(DspCallbackCount);
  end;
  Result := value;
end;

// SetDSPDbg's pTrace, not ExCall.  Reverse-engineered from DSP.asm's DSPIn, the only call site:
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
//
// Also calls TestWin32APIFromCallback (see its own comment), the reason this stub is no longer a
// pure counter.  On Win64, this requires its own dynamic 16-byte-alignment dance before the call,
// exactly like x64.inc's AlignRawCallBegin/AlignRawCallEnd, since this stub's own entry RSP is only
// guaranteed correctly aligned by DSP.asm's DSPIn doing the same thing on its side (see that
// macro's own doc), not assumed here and re-derived dynamically instead, so this test does not
// depend on that other fix already being correct.  R12 (callee-saved) is saved and restored around
// it for the same reason AlignRawCallBegin uses it: safe to repurpose as long as it is put back
// before this stub's own 'ret'.
//
// Also runs a direct 'movaps' alignment probe and reports the entry RSP's raw parity (see
// AlignedSSEProbeCount/CheckCallbackEntryAlignment's own comments), both measuring this stub's true
// entry RSP.  It is captured into RAX as the very first instruction, before anything else here,
// including the Win32 API call's own alignment dance, has a chance to change it.
//
// FNSAVE/FRSTOR bracket the two Pascal calls (CheckCallbackEntryAlignment/TestWin32APIFromCallback)
// unlike RAX/RBX above, since DSPIn's mixing caller can have live values on the x87 FPU stack when
// this callback fires, and DSP.asm's mixing/echo/filter chain shares that stack depth across many
// macros.  The Win64 ABI says nothing about FPU stack contents, only about clobberable registers,
// so a Pascal call touching x87 internally (CreateFileW/Format/WideString) can desync that shared
// depth, exactly the failure a real .spc file traced here: RAM/DSP/Voice/vMMax state diverging from
// x86 from Phase 1 onward, on a build that plays fine standalone with no debug callback registered.
// FNSAVE/FRSTOR save and restore the full x87 environment around the two calls, so whatever they do
// to the FPU stays invisible to DSPIn's caller.
procedure DspTraceStub; assembler; nostackframe;
asm
  {$IFDEF CPU64}
  mov     rax, rsp

  // NOTE: the probe address is derived from RSP after the Sub below, not from RAX (the entry RSP)
  // directly.  An address like '[rax-8]' would land ON TOP OF the return address slot at
  // [rax,rax+8), which 'movaps' would then overwrite, corrupting this very stub's own 'ret' target.
  // '[rsp+8]' stays entirely inside the 32 bytes just reserved, strictly below the entry RSP, and
  // is 16-byte aligned exactly when the entry RSP was genuinely 8 mod 16, the condition being
  // probed, since Sub by a multiple of 16 does not change that parity.
  sub     rsp, 32
  lea     rcx, [rsp+8]
  movaps  [rcx], xmm0
  add     rsp, 32
  lea     rdx, [rip+AlignedSSEProbeCount]
  inc     dword ptr [rdx]

  and     rax, 15
  push    r12
  mov     r12, rsp
  and     rsp, -16
  // 144 = 32 (shadow space for the two calls below) + 112 (x87 state image, 108 bytes per FNSAVE/
  // FRSTOR's fixed format, rounded up to keep the total itself a multiple of 16).  See the FNSAVE/
  // FRSTOR comment below for why this bracket exists at all.
  sub     rsp, 144
  fnsave  [rsp+32]
  mov     rcx, rax
  call    CheckCallbackEntryAlignment
  mov     rcx, WTS_DSPTRACE
  call    TestWin32APIFromCallback
  frstor  [rsp+32]
  mov     rsp, r12
  pop     r12

  lea     rax, [rip+DspTraceCount]
  inc     dword ptr [rax]
  {$ELSE}
  sub     esp, 108
  fnsave  [esp]
  call    NoteAlignedSSEProbeSkippedOnX86
  mov     eax, 8
  call    CheckCallbackEntryAlignment
  mov     eax, WTS_DSPTRACE
  call    TestWin32APIFromCallback
  frstor  [esp]
  add     esp, 108
  lea     eax, [DspTraceCount]
  inc     dword ptr [eax]
  {$ENDIF}
  ret
end;

// SetSPCDbg's pDebug, not ExCall either.  Reverse-engineered from SPC700.asm's SPCBreak, the only
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
//
// Also calls TestWin32APIFromCallback (see DspTraceStub's own comment for why, and for the dynamic
// 16-byte-alignment dance this requires on Win64, independent of SPC700.asm's SPCBreak doing the
// same thing on its side), plus the same direct 'movaps' alignment probe and raw entry-RSP-parity
// report DspTraceStub runs (see AlignedSSEProbeCount/CheckCallbackEntryAlignment's own comments).
//
// Also FNSAVE/FRSTOR-brackets the same two Pascal calls, for the same reason as DspTraceStub (see
// its own comment for the full story): SPC700 emulation itself is pure integer, but EmuAPU's outer
// loop interleaves EmuSPC and EmuDSP, so a live x87 computation from DSP.asm's side can still be in
// progress on the shared FPU stack at the exact moment this callback fires here too.
procedure SpcTraceStub; assembler; nostackframe;
asm
  {$IFDEF CPU64}
  mov     rax, rsp

  // See DspTraceStub's own comment on this exact sequence: the probe address must stay below the
  // entry RSP, never at '[rax-8]', or 'movaps' corrupts this stub's own return address.
  sub     rsp, 32
  lea     rcx, [rsp+8]
  movaps  [rcx], xmm0
  add     rsp, 32
  lea     rdx, [rip+AlignedSSEProbeCount]
  inc     dword ptr [rdx]

  and     rax, 15
  push    r12
  mov     r12, rsp
  and     rsp, -16
  sub     rsp, 144
  fnsave  [rsp+32]
  mov     rcx, rax
  call    CheckCallbackEntryAlignment
  mov     rcx, WTS_SPCTRACE
  call    TestWin32APIFromCallback
  frstor  [rsp+32]
  mov     rsp, r12
  pop     r12

  lea     rax, [rip+SpcTraceCount]
  inc     dword ptr [rax]
  {$ELSE}
  sub     esp, 108
  fnsave  [esp]
  call    NoteAlignedSSEProbeSkippedOnX86
  mov     eax, 8
  call    CheckCallbackEntryAlignment
  mov     eax, WTS_SPCTRACE
  call    TestWin32APIFromCallback
  frstor  [esp]
  add     esp, 108
  lea     eax, [SpcTraceCount]
  inc     dword ptr [eax]
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

// Plays exactly 1 sample through WriteChunkToFile and returns how many bytes it produced, i.e. the
// DLL's actual current bytes-per-frame (APU.asm's 'rawByte' = numChn * abs(bits) / 8, see
// SetAPUOptI).  No exported function reads rawChn/rawBits/rawByte back directly, so this is the
// only way to confirm what SetAPUOpt's numChn/bits validation actually resolved a given input to,
// rather than just checking that the call did not crash.  Routed through WriteChunkToFile itself
// (not a raw EmuAPU call) so the 1 measured sample still flows into the PCM file/hash/SamplesDone
// bookkeeping like every other sample in this run, keeping the whole stream deterministic and
// comparable between builds.
function MeasureFrameBytes: Int64;
var
  Before: Int64;
begin
  Before := TotalWritten;
  WriteChunkToFile(1);
  Result := TotalWritten - Before;
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
// SPC700 code helpers for Phases 22 and 23

// Writes one byte of SPC700 code at Addr through SetAPURAM and advances Addr.
procedure EmitSPC(var Addr: Word; B: Byte);
begin
  pSetAPURAM(Addr, B);
  Inc(Addr);
end;

// Emits 'MOV dp,#imm' (8F imm dp).
procedure EmitMovDpImm(var Addr: Word; Dp, Imm: Byte);
begin
  EmitSPC(Addr, $8F);
  EmitSPC(Addr, Imm);
  EmitSPC(Addr, Dp);
end;

// Emits the two writes that store Value in DSP register Reg ('MOV $F2,#Reg' then 'MOV $F3,#Value').
procedure EmitDSPWrite(var Addr: Word; Reg, Value: Byte);
begin
  EmitMovDpImm(Addr, $F2, Reg);
  EmitMovDpImm(Addr, $F3, Value);
end;

// Hash of every voice's mTgtL/mTgtR, the volumes ChnSep computes with FSqrt and FDiv when stereo
// separation is on, so any difference in x87 rounding shows up here.
function HashVoiceTargets: Cardinal;
var
  V: Integer;
begin
  Result := FNV32_SEED;
  for V := 0 to VOICE_COUNT - 1 do
    Result := Hash32(Result, PByte(gVoice)[V * VOICE_STRIDE + VOICE_MTGT_OFS], 8);
end;

// Runs one Phase 22 scenario from the current state and returns HashVoiceTargets afterwards.
//   0: the SPC700 writes VOL L/R of voice 0, which Phase 22 keys on first (DSPIn, then ChnSep).
//   1: the SPC700 clears KOF, then sets VOL L/R and keys on each voice in turn, so ChnSep also
//      runs from CatchUp's deferred KON processing.  At the 8kHz output Phase 22 sets, most ticks
//      reach it without calling EmuDSP.
//   2: a fast seek during a fade.  FixSeek keys every voice off, so ChnSep does not run, but
//      SetFade and the main volume handlers do.
function RunCWScenario(Scenario: Integer): Cardinal;
var
  A: Word;
  V: Integer;
begin
  case Scenario of
    0:
      begin
        A := $0200;
        EmitDSPWrite(A, $00, $71);
        EmitDSPWrite(A, $01, $13);
        EmitSPC(A, $2F);                                  // BRA $
        EmitSPC(A, $FE);
        pFixAPU($0200, 0, 0, 0, 0, $EF);
        pEmuAPU(@Buf[0], 256 * 24, 0);
      end;
    1:
      begin
        A := $0200;
        EmitDSPWrite(A, $5C, $00);                        // KOF = 0, so no KON below is cancelled
        for V := 0 to VOICE_COUNT - 1 do
        begin
          EmitDSPWrite(A, V * 16, $70 + V);
          EmitDSPWrite(A, V * 16 + 1, $20 + V * 3);
          EmitDSPWrite(A, $4C, 1 shl V);                  // KON this voice only
          EmitSPC(A, $8D);                                // MOV Y,#$40
          EmitSPC(A, $40);
          EmitSPC(A, $FE);                                // DBNZ Y,$ (spins 64 times)
          EmitSPC(A, $FE);
        end;
        EmitSPC(A, $2F);                                  // BRA $
        EmitSPC(A, $FE);
        pFixAPU($0200, 0, 0, 0, 0, $EF);
        pEmuAPU(@Buf[0], 256, 1);
      end;
    2:
      pSeekAPU(16000, 1);
  end;
  Result := HashVoiceTargets;
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
  CWIdx: Integer;                                        // Phase 22
  CWHashA, CWHashB: Cardinal;
  CWCountA: Int64;
  CtxA, CtxB: array of Byte;
  NoDspAddr: Word;                                       // Phase 23
  NoDspOld, NoDspNew: Byte;
  SmpCallIdx, SmpReqIdx: Integer;                        // Phase 25
  SmpReq: Cardinal;
  SmpTotal, SmpZeroCalls: Int64;
  SmpT64Start, SmpT64Delta: Cardinal;
  SmpExcess, SmpCount: Int64;
  SmpRet: Pointer;
  HaltSilent: Boolean;                                   // Phase 26
  KeepT64A, KeepT64B: Cardinal;                          // Phase 27
  LongIdx, LongByteIdx: Integer;                         // Phase 28
  LongBytes: NativeUInt;
  LongBuf: array of Byte;
  LongRet: Pointer;
  LongOK: Boolean;
  Long0T64Start, Long0T64Delta: Cardinal;                // Phase 29
  Long0Bytes, Long0Expect: Int64;
  DSPRegResult: Byte;
  FrameBytes: Int64;
  RegIdx: Integer;
  DSPSweepHash: Cardinal;
  TimerPortIdx: Integer;
  Win32TestSourceIdx: Integer;
  ArgIdx: Integer;
  VoiceIdx: Integer;
  VoiceMFlg: PByte;

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
    WriteLn('Usage: snesapu_apitest <dll path> <spc file path> <out pcm path> ',
            '[script700 file path] [-wav]');
    Halt(1);
  end;

  DllPath  := Args[0];
  SpcPath  := Args[1];
  OutPath  := Args[2];
  if Length(Args) >= 4 then
    Script700Path := Args[3]
  else
    Script700Path := '';

  PcmHash := FNV32_SEED;
  HostCW := GetX87CW;

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

  // GetAPUData: capture pointers now, used by every LogStateHash call and the Phase 1 state dump
  // below.  The pointer values themselves are addresses, never expected to match between
  // architectures or even between two runs of the same build thanks to ASLR, so only non-NULL-ness
  // is logged here.
  pGetAPUData(@gRAM, @gXRAM, @gOutPort, @gT64Cnt, @gDSP, @gVoice, @gVMMaxL, @gVMMaxR);
  if (gRAM = nil) or (gDSP = nil) or (gVoice = nil) then
    Fail('GetAPUData returned a NULL pointer for RAM/DSP/Voice')
  else
    Ok('GetAPUData: all pointers non-NULL');

  // Register callbacks.  SNESAPUCallback is standard ExCall.  SetDSPDbg/SetSPCDbg are the raw-
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
  LogKV('Phase1_Voice_Hash', Format('%.8x', [HashVoiceArray(gVoice, VOICE_COUNT, VOICE_STRIDE, gRAM)]));
  LogKV('Phase1_T64Cnt', IntToStr(PCardinal(gT64Cnt)^));
  CheckFpuCW('Phase1');

  // SNESAPUCallback's apuCbMask accumulation: CBE_DSPREG alone (registered above) should normally
  // have already fired from the ordinary playback just above, proving the narrow mask alone works,
  // before the remaining bits (needed starting Phase 8) are added by a second call.  A second chunk
  // after that would then confirm CBE_DSPREG did not stop firing, i.e. the second call's mask
  // genuinely OR-accumulates onto the first rather than replacing it.  Not asserted here as a Fail,
  // though: some .spc files write nothing to the DSP at all until their own paired Script700 program
  // (loaded starting Phase 9) has run, so DspCallbackCount can still legitimately be 0 at this point.
  // Only logged here, so an x86/x64 divergence still shows up as a log diff; the real 'did this ever
  // fire' assertion is deferred to the very end of the run, by which point every .spc file's own
  // Script700 program, if it has one, has had a chance to run.
  LogKV('Phase1_DspCallbackCount', IntToStr(DspCallbackCount));

  pSNESAPUCallback(@APUCallback, CBE_S700FCH or CBE_INCS700 or CBE_INCDATA or CBE_REQBP);
  WriteChunkToFile(CHUNK_SAMPLES);
  LogKV('Phase1_DspCallbackCount2', IntToStr(DspCallbackCount));

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
  // CallArg/ExCallArg marshaling this port fixed.  Calling it here, right after the mixType=0
  // test above, checks mixType really stays 0 (silent), not reset to some other value.
  pSetAPUOpt(Cardinal(-1), Cardinal(-1), Cardinal(-1), Cardinal(-1), Cardinal(-1), Cardinal(-1));
  if WriteChunkCheckSilent(CHUNK_SAMPLES) then
    Ok('SetAPUOpt (-1 sentinel, all params): mixType=0 preserved, output still silent')
  else
    Fail('SetAPUOpt (-1 sentinel, all params): output no longer silent, a setting was lost');

  // Out-of-range 'rate': below the 8000 minimum and above the 192000 maximum, a boundary neither
  // bound's own out-of-range handling was ever forced to trigger before, since every rate value
  // used elsewhere in this run already falls inside [8000,192000].  SetAPUOptI used to clamp its
  // own internal smpRate/rawRate to the nearest bound while SetDSPOpt independently reset an
  // out-of-range value to 32000, a genuine divergence, now closed: SetAPUOptI matches SetDSPOpt's
  // own reset-to-32000 check exactly (APU.asm), so this exercises only that shared path on both
  // sides.  Not asserted against a specific PCM byte pattern here, unlike numChn/bits below, since
  // rate feeds DSP.asm's own resampling state rather than a simple externally-observable byte count
  // like rawByte, and a byte-exact assertion would need careful state resets to avoid false
  // failures from residual filter/phase state.
  pSetAPUOpt(1, 2, 16, 4000, INT_GAUSS, 0);              // below the 8000 minimum
  WriteChunkToFile(CHUNK_SAMPLES);
  Ok('SetAPUOpt (rate=4000, below the 8000 minimum) played without crashing');
  pSetAPUOpt(1, 2, 16, 300000, INT_GAUSS, 0);            // above the 192000 maximum
  WriteChunkToFile(CHUNK_SAMPLES);
  Ok('SetAPUOpt (rate=300000, above the 192000 maximum) played without crashing');

  // Out-of-range 'inter': DSP.asm's SetDSPOpt resets any value outside [0,7] to 3 (INT_CUBIC)
  // rather than rejecting it or clamping to a bound ('Cmp EDX,7 / JBE .DefInter ... Mov EAX,3',
  // DSP.asm).  Every INT_* constant used anywhere else in this run is already inside [0,7], so this
  // reset-to-default path has never been exercised before.
  pSetAPUOpt(1, 2, 16, 44100, 99, 0);                    // 'inter'=99, well outside [0,7]
  WriteChunkToFile(CHUNK_SAMPLES);
  Ok('SetAPUOpt (inter=99, out of the [0,7] range) played without crashing');

  // Invalid 'numChn'/'bits': DSP.asm's SetDSPOpt only accepts numChn in {1,2} and bits in
  // {8,16,24,32,-32} (DSP.asm ~line 1032/1051), silently resetting anything else to its own default
  // (numChn=2, bits=16).  Unlike rate/inter above, APU.asm's SetAPUOptI never validates numChn/bits
  // at all: it computes 'rawByte' (bytes per sample, used both to size the span EmuAPU reports back
  // to the caller AND to drive the actual byte-copy loop into the caller's own buffer, 'Rep MovSB'
  // in EmuAPUI, APU.asm) directly from the RAW, unvalidated numChn/bits, while DSP.asm mixes using
  // its own silently-defaulted values instead.  So an invalid combination can make APU.asm's own
  // idea of the frame size diverge from what DSP.asm actually produces, corrupting how a caller
  // interprets the returned PCM span, not just an internal inconsistency the way the rate case was.
  //
  // APU.asm's SetAPUOptI now validates numChn/bits itself, matching SetDSPOpt's own check exactly
  // (numChn defaults to 2 unless 1 or 2, bits defaults to 16 unless 8/16/24/32/-32), fixed after
  // the EAccessViolation this exact test first exposed.  Checked here via MeasureFrameBytes rather
  // than just 'played without crashing', with bits held at 8 while numChn varies and numChn held at
  // 1 while bits varies, so each parameter's own clamp is isolated and confirmed to resolve to the
  // RIGHT value, not only a safe one.  Every valid value is covered (both for numChn, all five for
  // bits), plus a couple of representative invalid ones, including a wildly out-of-range numChn
  // (255): APU.asm's '-1' sentinel check now compares the full dword too, so 255 is no longer
  // mistaken for -1 the way it was before that fix, and genuinely exercises this validation.
  pSetAPUOpt(1, 1, 8, 44100, INT_GAUSS, 0);              // numChn=1, valid, must pass through
  FrameBytes := MeasureFrameBytes;
  if FrameBytes = 1 then
    Ok('SetAPUOpt (numChn=1, valid): resolved to 1 byte/frame, as expected')
  else
    Fail(Format('SetAPUOpt (numChn=1, valid): expected 1 byte/frame, got %d', [FrameBytes]));
  pSetAPUOpt(1, 2, 8, 44100, INT_GAUSS, 0);              // numChn=2, valid, must pass through
  FrameBytes := MeasureFrameBytes;
  if FrameBytes = 2 then
    Ok('SetAPUOpt (numChn=2, valid): resolved to 2 bytes/frame, as expected')
  else
    Fail(Format('SetAPUOpt (numChn=2, valid): expected 2 bytes/frame, got %d', [FrameBytes]));
  pSetAPUOpt(1, 0, 8, 44100, INT_GAUSS, 0);              // numChn=0, invalid, must default to 2
  FrameBytes := MeasureFrameBytes;
  if FrameBytes = 2 then
    Ok('SetAPUOpt (numChn=0, invalid): defaulted to 2 bytes/frame, as expected')
  else
    Fail(Format('SetAPUOpt (numChn=0, invalid): expected 2 bytes/frame, got %d', [FrameBytes]));
  pSetAPUOpt(1, 3, 8, 44100, INT_GAUSS, 0);              // numChn=3, invalid, must default to 2
  FrameBytes := MeasureFrameBytes;
  if FrameBytes = 2 then
    Ok('SetAPUOpt (numChn=3, invalid): defaulted to 2 bytes/frame, as expected')
  else
    Fail(Format('SetAPUOpt (numChn=3, invalid): expected 2 bytes/frame, got %d', [FrameBytes]));
  pSetAPUOpt(1, 255, 8, 44100, INT_GAUSS, 0);            // numChn=255, wildly invalid, must default to 2
  FrameBytes := MeasureFrameBytes;
  if FrameBytes = 2 then
    Ok('SetAPUOpt (numChn=255, invalid): defaulted to 2 bytes/frame, as expected')
  else
    Fail(Format('SetAPUOpt (numChn=255, invalid): expected 2 bytes/frame, got %d', [FrameBytes]));

  pSetAPUOpt(1, 1, 8, 44100, INT_GAUSS, 0);              // bits=8, valid, must pass through
  FrameBytes := MeasureFrameBytes;
  if FrameBytes = 1 then
    Ok('SetAPUOpt (bits=8, valid): resolved to 1 byte/frame, as expected')
  else
    Fail(Format('SetAPUOpt (bits=8, valid): expected 1 byte/frame, got %d', [FrameBytes]));
  pSetAPUOpt(1, 1, 16, 44100, INT_GAUSS, 0);             // bits=16, valid, must pass through
  FrameBytes := MeasureFrameBytes;
  if FrameBytes = 2 then
    Ok('SetAPUOpt (bits=16, valid): resolved to 2 bytes/frame, as expected')
  else
    Fail(Format('SetAPUOpt (bits=16, valid): expected 2 bytes/frame, got %d', [FrameBytes]));
  pSetAPUOpt(1, 1, 24, 44100, INT_GAUSS, 0);             // bits=24, valid, must pass through
  FrameBytes := MeasureFrameBytes;
  if FrameBytes = 3 then
    Ok('SetAPUOpt (bits=24, valid): resolved to 3 bytes/frame, as expected')
  else
    Fail(Format('SetAPUOpt (bits=24, valid): expected 3 bytes/frame, got %d', [FrameBytes]));
  pSetAPUOpt(1, 1, 32, 44100, INT_GAUSS, 0);             // bits=32, valid, must pass through
  FrameBytes := MeasureFrameBytes;
  if FrameBytes = 4 then
    Ok('SetAPUOpt (bits=32, valid): resolved to 4 bytes/frame, as expected')
  else
    Fail(Format('SetAPUOpt (bits=32, valid): expected 4 bytes/frame, got %d', [FrameBytes]));
  pSetAPUOpt(1, 1, Cardinal(-32), 44100, INT_GAUSS, 0);  // bits=-32, valid (float marker), must pass through
  FrameBytes := MeasureFrameBytes;
  if FrameBytes = 4 then
    Ok('SetAPUOpt (bits=-32, valid): resolved to 4 bytes/frame, as expected')
  else
    Fail(Format('SetAPUOpt (bits=-32, valid): expected 4 bytes/frame, got %d', [FrameBytes]));
  pSetAPUOpt(1, 1, 12, 44100, INT_GAUSS, 0);             // bits=12, invalid, must default to 16
  FrameBytes := MeasureFrameBytes;
  if FrameBytes = 2 then
    Ok('SetAPUOpt (bits=12, invalid): defaulted to 2 bytes/frame (16-bit), as expected')
  else
    Fail(Format('SetAPUOpt (bits=12, invalid): expected 2 bytes/frame, got %d', [FrameBytes]));
  pSetAPUOpt(1, 1, 127, 44100, INT_GAUSS, 0);            // bits=127, wildly invalid, must default to 16
  FrameBytes := MeasureFrameBytes;
  if FrameBytes = 2 then
    Ok('SetAPUOpt (bits=127, invalid): defaulted to 2 bytes/frame (16-bit), as expected')
  else
    Fail(Format('SetAPUOpt (bits=127, invalid): expected 2 bytes/frame, got %d', [FrameBytes]));

  pSetAPUOpt(1, 2, Cardinal(-32), 96000, INT_SINC, 0);   // restore the format the rest of the run uses
  LogStateHash('Phase2');

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
  LogStateHash('Phase3');

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
  LogStateHash('Phase4');

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
  LogStateHash('Phase5');

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
  LogStateHash('Phase6');

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
  LogStateHash('Phase7');

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
  LogStateHash('Phase8');

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
  LogStateHash('Phase9');

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
  LogStateHash('Phase10');

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
  LogStateHash('Phase11');

  // === Phase 12: SetSPCDbg 'opts' flag sweep (SPC_RETURN, SPC_HALT, DSP_HALT, SPC_NODSP,
  //     SPC_TRACE, DSP_PAUSE) ===
  // Each flag is registered alone, exercised with a short burst of playback, and restored to plain
  // SPC_TRACE afterward, matching the standing state Phases 8-11 above already relied on for
  // SpcTraceStub to keep firing, and that later phases (including Phase 13's own regression check
  // right below) continue to assume.

  // DSP_HALT sends RunDSP to its '.Mute' path ('Test byte [dbgOpt],DSP_HALT / JNZ .Mute', see
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
  LogStateHash('Phase12');

  // === Phase 13: SeekAPU, both seek methods ===
  // time=0 is SeekAPU's very first check ('Test EAX,EAX / RetZ'), returning immediately without
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
  // fixed (see x64.inc's CallArg/ExCallArg, and SPC700.asm's SetSPCDbgI): SeekAPU's fast path
  // internally calls 'SetSPCDbgI,-1,...' twice, '-1' meaning 'leave pDebug unchanged'.  Calling
  // SetSPCDbg/SetDSPDbg again now and checking the returned previous pointer, which both
  // functions always report before touching anything, proves those internal -1 calls really did
  // leave pDebug/pTrace as the addresses registered at startup, instead of the bogus
  // 0x00000000FFFFFFFF value the pre-fix bug corrupted them to.  SeekAPU's fast path now restores
  // dbgOpt itself, so the SPC_TRACE passed here only re-registers the state already in place.
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
  LogStateHash('Phase13');

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
  LogStateHash('Phase14');

  // === Phase 15: FixAPU register readback ===
  // Originally a full round-trip (snapshot RAM/dsp/extraRAM/Voice, play 2 chunks, restore, call
  // FixAPU, play the same 2 chunks again, assert byte-identical output), mirroring Phase 14's
  // GetSNESAPUContext/SetSNESAPUContext check.  Dropped after a real .spc file exposed that this
  // assertion does not hold in general: FixAPU (FixSPC+FixDSP) is a "reasonable resync" from a
  // register/RAM snapshot, not a guaranteed bit-perfect continuation, the same limitation a real
  // .spc save file has (it cannot capture a voice's exact envelope phase, pitch counter fraction,
  // sample buffer position, or interpolation history).  APU.asm's own resampling buffer bookkeeping
  // (outCur/outLen) has no external exposure at all, so even restoring every state block GetAPUData
  // exposes could not make two playback passes agree, an expectation the DLL was never designed to
  // satisfy.
  //
  // Simplified to what FixAPU actually documents: that it writes the given register values into the
  // emulated CPU state, verified directly via GetSPCRegs reading back what was just passed in.  The
  // values passed to FixAPU are deliberately XORed away from the current values first, not reused
  // as-is: a FixAPU that silently no-ops, leaving the old values untouched, would otherwise pass
  // this check by coincidence, since the old and given values would already match.  FixAPU is
  // called a second time afterward with the real, unmodified values, restoring genuine continuity
  // before playback resumes, so the deliberately-wrong test values do not leak into the PCM stream.
  pGetSPCRegs(@RegPC, @RegA, @RegY, @RegX, @RegPSW, @RegSP);
  LogKV('FixAPU_RegPC', Format('0x%.4x', [RegPC]));
  LogKV('FixAPU_RegA', Format('0x%.2x', [RegA]));
  LogKV('FixAPU_RegY', Format('0x%.2x', [RegY]));
  LogKV('FixAPU_RegX', Format('0x%.2x', [RegX]));
  LogKV('FixAPU_RegPSW', Format('0x%.2x', [RegPSW]));
  LogKV('FixAPU_RegSP', Format('0x%.2x', [RegSP]));

  TestRegPC := RegPC xor $FFFF;
  TestRegA := RegA xor $FF;
  TestRegY := RegY xor $FF;
  TestRegX := RegX xor $FF;
  TestRegPSW := RegPSW xor $FF;
  TestRegSP := RegSP xor $FF;
  pFixAPU(TestRegPC, TestRegA, TestRegY, TestRegX, TestRegPSW, TestRegSP);
  pGetSPCRegs(@NewRegPC, @NewRegA, @NewRegY, @NewRegX, @NewRegPSW, @NewRegSP);

  if (NewRegPC = TestRegPC) and (NewRegA = TestRegA) and (NewRegY = TestRegY) and
     (NewRegX = TestRegX) and (NewRegPSW = TestRegPSW) and (NewRegSP = TestRegSP) then
    Ok('FixAPU: register values correctly written back (verified via GetSPCRegs readback)')
  else
    Fail(Format('FixAPU: register readback mismatch (PC=0x%.4x/0x%.4x A=0x%.2x/0x%.2x Y=0x%.2x/0x%.2x ' +
      'X=0x%.2x/0x%.2x PSW=0x%.2x/0x%.2x SP=0x%.2x/0x%.2x)', [TestRegPC, NewRegPC, TestRegA, NewRegA,
      TestRegY, NewRegY, TestRegX, NewRegX, TestRegPSW, NewRegPSW, TestRegSP, NewRegSP]));

  pFixAPU(RegPC, RegA, RegY, RegX, RegPSW, RegSP);   // restore real continuity before playback resumes
  WriteChunkToFile(CHUNK_SAMPLES * 2);
  LogStateHash('Phase15');

  // === Phase 16: SetAPULength fade-out and revival ===
  // song=1s, fade=2s puts t64Cnt past songLen almost immediately, so SetFade drives DSP volume
  // toward silence over the following 2 seconds.  4 seconds of playback captures that fade curve
  // completing.  song=-1 (Cardinal 0xFFFFFFFF) means 'never ends', per SetDSPLength's unsigned
  // comparison against t64Cnt, forcing volume back to full immediately, so the song should be
  // audible again over the next 2 seconds.  ResetAPU, then a fresh LoadSPCFile, restores playback
  // position and SetAPULength's own state (songLen/fadeLen), so this excursion does not affect
  // Phase 20 below.  Neither call touches the SetAPUOpt format settings (rawRate/rawChn/rawBits/
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

  // song=-1 with a nonzero fade: the fade never starts, so the total must be -1 too, not the
  // wrapped -1 + fade.  Volume stays full, so the output stream is unchanged.
  TotalLen := pSetAPULength(Cardinal(-1), 64000);
  LogKV('FadeTest_SetAPULength_NoLengthFade_Result', IntToStr(TotalLen));
  if TotalLen = Cardinal(-1) then
    Ok('SetAPULength (song=-1, fade=64000): returned -1 (no length)')
  else
    Fail(Format('SetAPULength (song=-1, fade=64000): returned %d, expected -1 (no length)',
      [TotalLen]));

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
  LogStateHash('Phase16');

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
  LogStateHash('Phase17');

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
  LogStateHash('Phase18');

  // === Phase 19: Voice mute/noise flags (mFlg) ===
  // Voice.mFlg's low two bits (MixF's 'mute'/'noise', DSP.h) are the only part of the array
  // GetAPUData's ppVoice exposes that the DLL documents as 'set by user', so this is the one place
  // in this run that pokes the voice array directly instead of going through an exported setter.
  // One voice at a time, on then off, exercises both bits across all 8 voices; any x86/x64
  // mismatch in how DSP.asm reads mFlg (e.g. DSPIn's 'IdxSt Test,mix,PBX+mFlg,AH', or EmuDSP's
  // '.UsrFlg' loop, which gathers MFLG_MUTE/MFLG_NOISE into usrMute/dspNoiseF once per call)
  // surfaces through the ordinary PCM-hash comparison like everywhere else in this tool, so
  // nothing special is asserted for these two loops.
  for VoiceIdx := 0 to VOICE_COUNT - 1 do
  begin
    VoiceMFlg := @PByte(gVoice)[VoiceIdx * VOICE_STRIDE + VOICE_MFLG_OFS];
    VoiceMFlg^ := VoiceMFlg^ or MFLG_MUTE;
    WriteChunkToFile(CHUNK_SAMPLES);
    VoiceMFlg^ := VoiceMFlg^ and not MFLG_MUTE;
    WriteChunkToFile(CHUNK_SAMPLES);
  end;
  Ok('Voice mFlg mute bit: exercised on all 8 voices individually');

  for VoiceIdx := 0 to VOICE_COUNT - 1 do
  begin
    VoiceMFlg := @PByte(gVoice)[VoiceIdx * VOICE_STRIDE + VOICE_MFLG_OFS];
    VoiceMFlg^ := VoiceMFlg^ or MFLG_NOISE;
    WriteChunkToFile(CHUNK_SAMPLES);
    VoiceMFlg^ := VoiceMFlg^ and not MFLG_NOISE;
    WriteChunkToFile(CHUNK_SAMPLES);
  end;
  Ok('Voice mFlg noise bit: exercised on all 8 voices individually');

  // Muting every voice is the one property here worth asserting outright, not just relying on
  // cross-build comparison.  A direct 'SetDSPReg' poke to EVOLL/EVOLR is not enough: it only sets
  // the echo ramp's target, and the actually-mixed 'now' value (DSP.asm's nowEchoL/R) only snaps
  // to it via ResetVol, which no exported call reaches by itself, so a residual echo tail could
  // still leak through.  DSP_NOECHO via SetAPUOpt instead triggers SetDSPOpt's synchronous
  // ResetEcho, clearing the echo/FIR buffers directly, so the echo bus contributes zero regardless
  // of the ramp.  mixType/numChn/bits/rate/inter repeat Phase 3's restore (line ~1009) unchanged,
  // only 'opts' varies, and everything is restored right after.
  pSetAPUOpt(1, 2, Cardinal(-32), 96000, INT_SINC, DSP_NOECHO);
  for VoiceIdx := 0 to VOICE_COUNT - 1 do
  begin
    VoiceMFlg := @PByte(gVoice)[VoiceIdx * VOICE_STRIDE + VOICE_MFLG_OFS];
    VoiceMFlg^ := VoiceMFlg^ or MFLG_MUTE;
  end;
  if WriteChunkCheckSilent(CHUNK_SAMPLES) then
    Ok('Voice mFlg mute bit: all 8 voices muted, output buffer is silent, as expected')
  else
    Fail('Voice mFlg mute bit: all 8 voices muted, but output buffer is NOT silent');
  for VoiceIdx := 0 to VOICE_COUNT - 1 do
  begin
    VoiceMFlg := @PByte(gVoice)[VoiceIdx * VOICE_STRIDE + VOICE_MFLG_OFS];
    VoiceMFlg^ := VoiceMFlg^ and not MFLG_MUTE;
  end;
  pSetAPUOpt(1, 2, Cardinal(-32), 96000, INT_SINC, 0);
  LogStateHash('Phase19');

  // === Phase 20: closing stretch of plain playback ===
  // A fixed length, not a caller-supplied total, see FINAL_PADDING_SAMPLES and the header comment.
  WriteChunkToFile(FINAL_PADDING_SAMPLES);
  LogStateHash('Phase20');

  CloseFile(fOut);

  // === Phase 21: DAA/DAS against the hardware algorithm ===
  // Runs 'DAA A' and 'DAS A' for every A with each C/H combination (1024 cases each) and compares A
  // and PSW, read back through GetSPCRegs, with RefDecimalAdjust.  The opcode is written at $0200,
  // followed by 'BRA $' so the CPU spins in place afterward.  Runs after the output file is closed,
  // so the PCM stream is unaffected, and the -wav render below reloads the song anyway.
  DecFailCount := 0;
  for DecOp := 0 to 1 do
  begin
    if DecOp = 0 then
      pSetAPURAM($0200, $DF)                              // DAA A
    else
      pSetAPURAM($0200, $BE);                             // DAS A
    pSetAPURAM($0201, $2F);                               // BRA $
    pSetAPURAM($0202, $FE);

    for DecIdx := 0 to 1023 do
    begin
      DecInA := DecIdx and $FF;
      DecInPSW := 0;
      if (DecIdx and $100) <> 0 then
        DecInPSW := DecInPSW or PSW_C;
      if (DecIdx and $200) <> 0 then
        DecInPSW := DecInPSW or PSW_H;

      // 64 SPC cycles (24 APU clocks each) leave room for any overshoot carried over from the
      // previous call, so the opcode at $0200 always runs before the CPU starts spinning.
      pFixAPU($0200, DecInA, 0, 0, DecInPSW, $EF);
      pEmuAPU(@Buf[0], 64 * 24, 0);
      pGetSPCRegs(@RegPC, @RegA, @RegY, @RegX, @RegPSW, @RegSP);

      RefDecimalAdjust(DecOp = 1, DecInA, DecInPSW, DecExpA, DecExpPSW);
      if (RegA <> DecExpA) or (RegPSW <> DecExpPSW) then
      begin
        Inc(DecFailCount);
        if DecFailCount <= 8 then
          Fail(Format('%s: A=0x%.2x PSW=0x%.2x gave A=0x%.2x PSW=0x%.2x, ' +
            'expected A=0x%.2x PSW=0x%.2x', [Copy('DAADAS', DecOp * 3 + 1, 3), DecInA, DecInPSW,
            RegA, RegPSW, DecExpA, DecExpPSW]));
      end;
    end;
  end;
  if DecFailCount = 0 then
    Ok('DAA/DAS: all 2048 cases match the hardware algorithm')
  else
    Fail(Format('DAA/DAS: %d of 2048 case(s) mismatched (first 8 shown above)', [DecFailCount]));
  CheckFpuCW('Phase21');

  // === Phase 22: FPU work after a host callback that changes the x87 control word ===
  // Each scenario runs twice from the same snapshot, once with APUCallback loading CW_TAMPER on
  // every SPC700 fetch and once without, and the whole DLL state (the context) must match byte for
  // byte.  A missing control word reset on the way from SPC700 emulation into FPU code would round
  // differently, so each scenario guards one reset: DSPIn's '.NoCallback' (0), CatchUp's '.Skip'
  // (1) and FixSeek's entry (2).  Stereo separation is set off its neutral value so ChnSep takes
  // its FSqrt/FDiv path, every voice gets different left and right volumes, the output rate drops
  // to 8kHz so CatchUp skips EmuDSP on most ticks, and voice 0 is keyed on for scenario 0.
  pSetDSPStereo(49152);
  pSetAPUOpt(1, 2, 16, 8000, INT_GAUSS, 0);
  for VoiceIdx := 0 to VOICE_COUNT - 1 do
  begin
    pSetDSPReg(VoiceIdx * 16, $60 + VoiceIdx);
    pSetDSPReg(VoiceIdx * 16 + 1, $10 + VoiceIdx * 3);
  end;
  pSetDSPReg($5C, $00);
  pSetDSPReg($4C, $01);
  pEmuAPU(@Buf[0], 64, 1);                                // let the KON of voice 0 take effect
  CtxSize := pGetSNESAPUContextSize();
  SetLength(CtxBuf, CtxSize);
  SetLength(CtxA, CtxSize);
  SetLength(CtxB, CtxSize);
  for CWIdx := 0 to 2 do
  begin
    if CWIdx = 2 then                                     // fade from now on, so the seek lands in it
      pSetAPULength(PCardinal(gT64Cnt)^, 4 * 64000);
    if (CWIdx = 0) and ((PByte(gVoice)[VOICE_MFLG_OFS] and MFLG_OFF) <> 0) then
      Warn('x87 control word scenario 0: voice 0 is not playing, so ChnSep may not run');
    pGetSNESAPUContext(@CtxBuf[0]);
    CWTamperCount := 0;
    CWTamper := True;
    CWHashA := RunCWScenario(CWIdx);
    CWTamper := False;
    CWCountA := CWTamperCount;
    pGetSNESAPUContext(@CtxA[0]);
    pSetSNESAPUContext(@CtxBuf[0]);
    CWHashB := RunCWScenario(CWIdx);
    pGetSNESAPUContext(@CtxB[0]);
    LogKV(Format('CWTamper%d_Hash', [CWIdx]), Format('%.8x', [CWHashB]));
    if CWCountA = 0 then
      Fail(Format('x87 control word scenario %d: the tampering callback never fired', [CWIdx]))
    else if CompareMem(@CtxA[0], @CtxB[0], CtxSize) then
      Ok(Format('x87 control word scenario %d: same DLL state with a tampering callback ' +
        '(%d tampered fetches)', [CWIdx, CWCountA]))
    else
      Fail(Format('x87 control word scenario %d: DLL state differs with a tampering callback ' +
        '(voice volume hash %.8x vs %.8x)', [CWIdx, CWHashA, CWHashB]));
  end;
  pSetAPULength(Cardinal(-1), 0);                         // end the fade again
  pSetDSPStereo(32768);                                   // normal separation, as Phase 4 left it
  CheckFpuCW('Phase22');

  // === Phase 23: SPC_NODSP ignores DSPDATA writes to the $80-$FF mirror ===
  // With DSPADDR bit 7 set, $80-$FF are read-only mirrors of $00-$7F, so writing MVOLL through
  // $8C must leave it alone, while a write through $0C itself still lands.  SPC_NODSP routes
  // these writes through Func3's '%%NoDSP' path, which a fast seek also takes.
  pSetSPCDbg(@SpcTraceStub, SPC_NODSP);
  NoDspOld := PByte(gDSP)[$0C];
  NoDspNew := NoDspOld xor $55;
  NoDspAddr := $0200;
  EmitDSPWrite(NoDspAddr, $8C, NoDspNew);
  EmitSPC(NoDspAddr, $2F);                                // BRA $
  EmitSPC(NoDspAddr, $FE);
  pFixAPU($0200, 0, 0, 0, 0, $EF);
  pEmuAPU(@Buf[0], 64 * 24, 0);
  if PByte(gDSP)[$0C] = NoDspOld then
    Ok('SPC_NODSP: a DSPDATA write through $8C left MVOLL unchanged')
  else
    Fail(Format('SPC_NODSP: a DSPDATA write through $8C changed MVOLL from 0x%.2x to 0x%.2x',
      [NoDspOld, PByte(gDSP)[$0C]]));
  NoDspAddr := $0200;
  EmitDSPWrite(NoDspAddr, $0C, NoDspNew);
  pFixAPU($0200, 0, 0, 0, 0, $EF);
  pEmuAPU(@Buf[0], 64 * 24, 0);
  if PByte(gDSP)[$0C] = NoDspNew then
    Ok('SPC_NODSP: a DSPDATA write through $0C still updated MVOLL')
  else
    Fail(Format('SPC_NODSP: a DSPDATA write through $0C left MVOLL at 0x%.2x, expected 0x%.2x',
      [PByte(gDSP)[$0C], NoDspNew]));
  pSetSPCDbg(@SpcTraceStub, SPC_TRACE);                   // restore the standing state
  pSetDSPReg($0C, NoDspOld);
  CheckFpuCW('Phase23');

  // === Phase 24: SetScript700Data rejects an out-of-range addr or size ===
  // Both are unsigned, so an addr at or above 80000000h, or a size that runs past the end of the
  // Script700 area, must return -1 without writing anything.  A signed check let these through
  // and wrote outside the buffer.
  DataRes := pSetScript700Data($FFFFFF00, @Blob[0], SizeOf(Blob));
  if DataRes = Cardinal(-1) then
    Ok('SetScript700Data (addr=0xFFFFFF00): returned -1')
  else
    Fail(Format('SetScript700Data (addr=0xFFFFFF00): expected -1, got %d', [DataRes]));
  DataRes := pSetScript700Data($80000000, @Blob[0], SizeOf(Blob));
  if DataRes = Cardinal(-1) then
    Ok('SetScript700Data (addr=0x80000000): returned -1')
  else
    Fail(Format('SetScript700Data (addr=0x80000000): expected -1, got %d', [DataRes]));
  DataRes := pSetScript700Data(0, @Blob[0], $FFFFFFF0);
  if DataRes = Cardinal(-1) then
    Ok('SetScript700Data (size=0xFFFFFFF0): returned -1')
  else
    Fail(Format('SetScript700Data (size=0xFFFFFFF0): expected -1, got %d', [DataRes]));
  CheckFpuCW('Phase24');

  // === Phase 25: small EmuAPU requests produce the samples for all of their time ===
  // At 192000Hz and 1.0x speed one sample is exactly 128 APU clock cycles.  The SPC700 runs a
  // 'DIV YA,X' loop, whose 288-cycle instruction ends up to 287 cycles past the requested time, so
  // the next request is often already covered, sometimes exactly.  Such a request must still create
  // its samples.  For type 0, 19200 requests of R cycles are exactly 150*R samples whatever the
  // fraction left from before, and 50*R 64kHz ticks give or take the last instruction.  For type 1,
  // the SPC700 must not run ahead of the samples returned by more than the 192 samples EmuAPUBySmp
  // may keep in 'outBuf'.
  pSetAPUOpt(1, 2, 16, SMPLOSS_RATE, INT_GAUSS, 0);       // 4 bytes per sample, clears 'outBuf'
  pSetAPUSmpClk($10000);
  NoDspAddr := $0200;
  EmitSPC(NoDspAddr, $9E);                                // DIV YA,X
  EmitSPC(NoDspAddr, $2F);                                // BRA $0200
  EmitSPC(NoDspAddr, $FD);
  pFixAPU($0200, 0, 0, 1, 0, $EF);
  pEmuAPU(@Buf[0], 24576, 0);                             // settle into the loop

  for SmpReqIdx := 0 to High(SMPLOSS_REQ) do
  begin
    SmpReq := SMPLOSS_REQ[SmpReqIdx];
    SmpTotal := 0;
    SmpZeroCalls := 0;
    SmpT64Start := PCardinal(gT64Cnt)^;
    for SmpCallIdx := 1 to SMPLOSS_CALLS do
    begin
      SmpRet := pEmuAPU(@Buf[0], SmpReq, 0);
      SmpCount := (NativeUInt(SmpRet) - NativeUInt(@Buf[0])) div 4;
      Inc(SmpTotal, SmpCount);
      if SmpCount = 0 then
        Inc(SmpZeroCalls);
    end;
    SmpT64Delta := PCardinal(gT64Cnt)^ - SmpT64Start;
    LogKV(Format('SmallReq_Type0_%d_Samples', [SmpReq]), IntToStr(SmpTotal));
    LogKV(Format('SmallReq_Type0_%d_T64', [SmpReq]), IntToStr(SmpT64Delta));
    if SmpTotal <> Int64(SMPLOSS_CALLS div 128) * SmpReq then
      Fail(Format('EmuAPU type 0, %d calls of %d cycles: %d samples, expected %d ' +
        '(%d calls returned none)', [SMPLOSS_CALLS, SmpReq, SmpTotal,
        Int64(SMPLOSS_CALLS div 128) * SmpReq, SmpZeroCalls]))
    else if Abs(Int64(SmpT64Delta) - Int64(SMPLOSS_CALLS div 384) * SmpReq) > 1 then
      Fail(Format('EmuAPU type 0, %d calls of %d cycles: the SPC700 ran %d 64kHz ticks, ' +
        'expected %d', [SMPLOSS_CALLS, SmpReq, SmpT64Delta,
        Int64(SMPLOSS_CALLS div 384) * SmpReq]))
    else
      Ok(Format('EmuAPU type 0, %d calls of %d cycles: %d samples and %d 64kHz ticks ' +
        '(%d calls returned none)', [SMPLOSS_CALLS, SmpReq, SmpTotal, SmpT64Delta,
        SmpZeroCalls]));
  end;

  pSetAPUOpt(1, 2, 16, SMPLOSS_RATE, INT_GAUSS, 0);       // start type 1 with an empty 'outBuf'
  SmpT64Start := PCardinal(gT64Cnt)^;
  for SmpCallIdx := 1 to SMPLOSS_CALLS do
    pEmuAPU(@Buf[0], 1, 1);
  SmpT64Delta := PCardinal(gT64Cnt)^ - SmpT64Start;
  // One 64kHz tick is 3 samples at 192000Hz, so this is how many samples the SPC700 ran ahead of
  // the ones returned.  Up to 192 can sit in 'outBuf', plus a tick of rounding on either side.
  SmpExcess := Int64(SmpT64Delta) * 3 - SMPLOSS_CALLS;
  LogKV('SmallReq_Type1_T64', IntToStr(SmpT64Delta));
  if (SmpExcess >= -3) and (SmpExcess <= 192 + 3) then
    Ok(Format('EmuAPU type 1, %d calls of 1 sample: the SPC700 ran %d samples ahead',
      [SMPLOSS_CALLS, SmpExcess]))
  else
    Fail(Format('EmuAPU type 1, %d calls of 1 sample: the SPC700 ran %d samples ahead, ' +
      'expected 0 to 192', [SMPLOSS_CALLS, SmpExcess]));
  CheckFpuCW('Phase25');

  // === Phase 26: a suspended DSP outputs the resampled length, and seeks without a buffer ===
  // With DSP_ECHOFIR above 32kHz the DSP runs at 32kHz and resamples its output.  DSP_HALT must
  // still return silence of the resampled length, 4800 samples for 0.1 second at 48000Hz rather
  // than the 3200 samples the DSP runs, give or take one for the resampler phase.  A slow seek
  // emulates with no output buffer, which DSP_HALT used to fill with silence through NULL.
  pSetAPUOpt(1, 2, 16, HALT_RATE, INT_GAUSS, DSP_ECHOFIR);  // 4 bytes per sample
  pSetSPCDbg(@SpcTraceStub, DSP_HALT);
  FillChar(Buf, SizeOf(Buf), $55);
  SmpRet := pEmuAPU(@Buf[0], HALT_CYCLES, 0);
  SmpCount := (NativeUInt(SmpRet) - NativeUInt(@Buf[0])) div 4;
  HaltSilent := True;
  if SmpCount * 4 <= SizeOf(Buf) then
    for SmpCallIdx := 0 to Integer(SmpCount * 4) - 1 do
      if Buf[SmpCallIdx] <> 0 then
        HaltSilent := False;
  LogKV('HaltResampled_Samples', IntToStr(SmpCount));
  if Abs(SmpCount - HALT_SAMPLES) > 1 then
    Fail(Format('DSP_HALT with DSP_ECHOFIR at %dHz: %d samples for 0.1 second, expected %d',
      [HALT_RATE, SmpCount, HALT_SAMPLES]))
  else if not HaltSilent then
    Fail(Format('DSP_HALT with DSP_ECHOFIR at %dHz: %d samples, but not all silent',
      [HALT_RATE, SmpCount]))
  else
    Ok(Format('DSP_HALT with DSP_ECHOFIR at %dHz: %d silent samples for 0.1 second',
      [HALT_RATE, SmpCount]));
  pSeekAPU(64000, 0);                                     // an access violation ends the run here
  Ok('DSP_HALT: a slow seek of one second ran without writing through NULL');
  pSetSPCDbg(@SpcTraceStub, SPC_TRACE);                   // restore the standing state
  CheckFpuCW('Phase26');

  // === Phase 27: SetAPUOpt with the same format keeps the samples in 'outBuf' ===
  // EmuAPUBySmp makes the end of a 44100Hz type 1 request ahead into 'outBuf' and returns the rest
  // on the next call.  A SetAPUOpt call with the same format in between must keep them, so from
  // the same context the next request returns the same samples and leaves the SPC700 at the same
  // time as with no SetAPUOpt call.  Discarding them makes EmuAPUBySmp emulate further instead.
  pSetAPUOpt(1, 2, 16, KEEPBUF_RATE, INT_GAUSS, 0);       // 4 bytes per sample
  pEmuAPU(@Buf[0], KEEPBUF_SAMPLES, 1);
  CtxSize := pGetSNESAPUContextSize();
  SetLength(CtxBuf, CtxSize);
  SetLength(SegX, KEEPBUF_SAMPLES * 4);
  SetLength(SegY, KEEPBUF_SAMPLES * 4);
  pGetSNESAPUContext(@CtxBuf[0]);
  pEmuAPU(@Buf[0], KEEPBUF_SAMPLES, 1);
  pSetAPUOpt(1, 2, 16, KEEPBUF_RATE, INT_GAUSS, 0);       // the same format again
  pEmuAPU(@SegX[0], KEEPBUF_SAMPLES, 1);
  KeepT64A := PCardinal(gT64Cnt)^;
  pSetSNESAPUContext(@CtxBuf[0]);
  pEmuAPU(@Buf[0], KEEPBUF_SAMPLES, 1);
  pEmuAPU(@SegY[0], KEEPBUF_SAMPLES, 1);
  KeepT64B := PCardinal(gT64Cnt)^;
  LogKV('KeepOutBuf_T64', Format('%d %d', [KeepT64A, KeepT64B]));
  if KeepT64A <> KeepT64B then
    Fail(Format('SetAPUOpt with the same format: the SPC700 ran to 64kHz tick %d, ' +
      'expected %d as with no call (buffered samples were discarded)', [KeepT64A, KeepT64B]))
  else if not CompareMem(@SegX[0], @SegY[0], KEEPBUF_SAMPLES * 4) then
    Fail('SetAPUOpt with the same format: the next request returned different samples')
  else
    Ok('SetAPUOpt with the same format: the buffered samples were kept');
  CheckFpuCW('Phase27');

  // === Phase 28: long type 1 requests ===
  // EmuAPUBySmp works out the clock cycles of its whole request at once, so EmuAPUI hands it one
  // second at a time.  Each case makes one request well past a limit a single call used to break
  // at: the samples lost to rounding smpREmu overflowing outBuf into apuCbMask/apuCbFunc, the
  // samples-to-cycles Div raising #DE, and the speed-adjusted cycles wrapping into an endless
  // loop.  Each must return exactly the samples asked for and leave the bytes after them alone.
  // SPC_TRACE is off meanwhile, since its stub would run on every one of these instructions.
  pSetSPCDbg(@SpcTraceStub, 0);
  for LongIdx := 0 to LONGREQ_COUNT - 1 do
  begin
    pSetAPUSmpClk(LONGREQ_SPEED[LongIdx]);
    pSetAPUOpt(1, LONGREQ_CHN[LongIdx], LONGREQ_BITS[LongIdx], LONGREQ_RATE[LongIdx], INT_GAUSS,
      LONGREQ_OPTS[LongIdx]);
    LongBytes := NativeUInt(LONGREQ_LEN[LongIdx]) * LONGREQ_CHN[LongIdx] *
      (LONGREQ_BITS[LongIdx] div 8);
    SetLength(LongBuf, LongBytes + LONGREQ_CANARY);
    FillChar(LongBuf[0], Length(LongBuf), $A5);
    LongRet := pEmuAPU(@LongBuf[0], LONGREQ_LEN[LongIdx], 1);
    LongOK := True;
    for LongByteIdx := 0 to LONGREQ_CANARY - 1 do
      if LongBuf[LongBytes + NativeUInt(LongByteIdx)] <> $A5 then
        LongOK := False;
    if NativeUInt(LongRet) - NativeUInt(@LongBuf[0]) <> LongBytes then
      Fail(Format('Long type 1 request, %s: returned %d bytes, expected %d',
        [LONGREQ_NAMES[LongIdx], Int64(NativeUInt(LongRet) - NativeUInt(@LongBuf[0])),
        Int64(LongBytes)]))
    else if not LongOK then
      Fail(Format('Long type 1 request, %s: wrote past the end of the buffer',
        [LONGREQ_NAMES[LongIdx]]))
    else
      Ok(Format('Long type 1 request, %s: %d samples, nothing written past them',
        [LONGREQ_NAMES[LongIdx], LONGREQ_LEN[LongIdx]]));
  end;
  SetLength(LongBuf, 0);
  if pSNESAPUCallback(@APUCallback, 0) = @APUCallback then
    Ok('Long type 1 requests: SNESAPUCallback still reports the installed callback')
  else
    Fail('Long type 1 requests: the installed callback pointer was overwritten');
  pSetAPUSmpClk($10000);
  pSetSPCDbg(@SpcTraceStub, SPC_TRACE);                 // restore the standing state
  CheckFpuCW('Phase28');

  // === Phase 29: a long type 0 request above 1.0x speed ===
  // EmuAPUI converts len to speed-adjusted cycles, which at x16 reach 2^32 from about 10.9 s of
  // len.  They used to be cut to 32 bits, so this request emulated 0 cycles and returned no
  // samples.  It must return len * rate / APU_CLK samples and run the SPC700 for 2^32 cycles.
  pSetSPCDbg(@SpcTraceStub, 0);
  pSetAPUSmpClk(LONG0_SPEED);
  pSetAPUOpt(1, 1, 8, LONG0_RATE, INT_GAUSS, 0);         // 1 byte per sample
  Long0Expect := Int64(LONG0_LEN) * LONG0_RATE div LONG0_CLK;
  SetLength(LongBuf, Long0Expect + 1 + LONGREQ_CANARY);
  FillChar(LongBuf[0], Length(LongBuf), $A5);
  Long0T64Start := PCardinal(gT64Cnt)^;
  LongRet := pEmuAPU(@LongBuf[0], LONG0_LEN, 0);
  Long0T64Delta := PCardinal(gT64Cnt)^ - Long0T64Start;
  Long0Bytes := Int64(NativeUInt(LongRet) - NativeUInt(@LongBuf[0]));
  LogKV('LongType0_Bytes_T64', Format('%d %d', [Long0Bytes, Long0T64Delta]));
  if (Long0Bytes < Long0Expect) or (Long0Bytes > Long0Expect + 1) then
    Fail(Format('Long type 0 request at x16: returned %d samples, expected %d',
      [Long0Bytes, Long0Expect]))
  else if Abs(Int64(Long0T64Delta) - LONG0_T64) > 2 then
    Fail(Format('Long type 0 request at x16: the SPC700 ran %d ticks of 64kHz, expected %d',
      [Long0T64Delta, LONG0_T64]))
  else
    Ok(Format('Long type 0 request at x16: %d samples, %d ticks of 64kHz',
      [Long0Bytes, Long0T64Delta]));
  SetLength(LongBuf, 0);
  pSetAPUSmpClk($10000);
  pSetSPCDbg(@SpcTraceStub, SPC_TRACE);                 // restore the standing state
  CheckFpuCW('Phase29');

  // === Optional: '-wav' 5-second render ===
  // A separate, fixed-format excursion for quick listening/spot-checking, not part of the x86/x64
  // comparison stream above.  Deliberately placed here, after every phase's excursions, so it
  // doubles as a human-audible confirmation that ResetAPU/LoadSPCFile leave the DLL in a normal
  // state even after everything above, not just that the in-process FAIL checks passed.
  if WantWav then
  begin
    WavPath := ChangeFileExt(OutPath, '.wav');

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

  // Promoted from Warn to Fail: by this point every .spc file's own Script700 program, if it has
  // one, has already run (see Phase 1's own deferred-check comment above), so there is no longer a
  // legitimate reason for this to still be 0.
  if DspCallbackCount = 0 then
    Fail('SNESAPUCallback (CBE_DSPREG): callback never fired in the entire run')
  else
    Ok('SNESAPUCallback (CBE_DSPREG): callback fired at least once over the full run');
  if SpcFetchCallbackCount = 0 then Warn('SNESAPUCallback (CBE_S700FCH) never fired');
  if IncS700CallbackCount = 0 then Warn('SNESAPUCallback (CBE_INCS700) never fired');
  if IncDataCallbackCount = 0 then Warn('SNESAPUCallback (CBE_INCDATA) never fired');
  if ReqBPCallbackCount = 0 then Warn('SNESAPUCallback (CBE_REQBP) never fired');
  if DspTraceCount = 0 then Warn('SetDSPDbg (pTrace) never fired');
  if SpcTraceCount = 0 then Warn('SetSPCDbg (pDebug) never fired');

  // A genuine Fail, not a Warn: unlike the callback-fired-at-all checks above, this is expected to
  // always run at least once from each of the three callback sources (see TestWin32APIFromCallback)
  // and a failed CreateFileW here is exactly the symptom the stack-alignment fix it targets, not a
  // benign "this .spc file just does not exercise that" case.  Checked per-source
  // (WTS_EXCALL/WTS_DSPTRACE/WTS_SPCTRACE each has its own WIN32_API_TEST_LIMIT budget, see
  // Win32APITestCount's own comment), so one source firing often cannot mask another source never
  // having been exercised at all.
  for Win32TestSourceIdx := 0 to WTS_COUNT - 1 do
  begin
    LogKV(Format('Win32APITestCount_%s', [WTS_NAMES[Win32TestSourceIdx]]),
      IntToStr(Win32APITestCount[Win32TestSourceIdx]));
    LogKV(Format('Win32APITestFailCount_%s', [WTS_NAMES[Win32TestSourceIdx]]),
      IntToStr(Win32APITestFailCount[Win32TestSourceIdx]));
    if Win32APITestCount[Win32TestSourceIdx] = 0 then
      Fail(Format('Win32 API call test (CreateFileW from inside a callback, source=%s): never attempted',
        [WTS_NAMES[Win32TestSourceIdx]]))
    else if Win32APITestFailCount[Win32TestSourceIdx] <> 0 then
      Fail(Format('Win32 API call test (CreateFileW from inside a callback, source=%s): ' +
        '%d of %d attempt(s) failed', [WTS_NAMES[Win32TestSourceIdx],
        Win32APITestFailCount[Win32TestSourceIdx], Win32APITestCount[Win32TestSourceIdx]]))
    else
      Ok(Format('Win32 API call test (CreateFileW from inside a callback, source=%s): ' +
        'all %d attempt(s) succeeded',
        [WTS_NAMES[Win32TestSourceIdx], Win32APITestCount[Win32TestSourceIdx]]));
  end;

  // Unlike Win32APITestCount above (bounded by WIN32_API_TEST_LIMIT), these two run on every single
  // DspTraceStub/SpcTraceStub firing, so a nonzero count here confirms the checks genuinely ran
  // across the whole playback, not just a handful of times near the start.  On x86 the probe itself
  // is a no-op (see NoteAlignedSSEProbeSkippedOnX86's own comment: no such alignment requirement
  // exists there), so 'succeeded' below means 'the x64 movaps probe passed, or x86 has no such
  // requirement to fail', not literally the same instruction executing on both builds.
  LogKV('AlignedSSEProbeCount', IntToStr(AlignedSSEProbeCount));
  if AlignedSSEProbeCount = 0 then
    Fail('Aligned SSE (movaps) callback-entry probe: never attempted')
  else
    Ok(Format('Aligned SSE (movaps) callback-entry probe: %d attempt(s) succeeded (a failure on x64 ' +
      'would have crashed the process instead of reaching this line; x86 has no such requirement)',
      [AlignedSSEProbeCount]));

  LogKV('CallbackEntryAlignmentOKCount', IntToStr(CallbackEntryAlignmentOKCount));
  LogKV('CallbackEntryAlignmentBadCount', IntToStr(CallbackEntryAlignmentBadCount));
  if CallbackEntryAlignmentOKCount = 0 then
    Fail('Callback entry RSP alignment check: never attempted')
  else if CallbackEntryAlignmentBadCount <> 0 then
    Fail(Format('Callback entry RSP alignment check: %d of %d attempt(s) had the wrong parity',
      [CallbackEntryAlignmentBadCount, CallbackEntryAlignmentOKCount + CallbackEntryAlignmentBadCount]))
  else
    Ok(Format('Callback entry RSP alignment check: all %d attempt(s) correct',
      [CallbackEntryAlignmentOKCount]));

  LogLine('');
  if FailCount = 0 then
    LogLine('=== ALL IN-PROCESS CHECKS PASSED (0 failures) ===')
  else
    LogLine(Format('=== %d IN-PROCESS CHECK(S) FAILED, see FAIL lines above ===', [FailCount]));

  // Non-zero exit code on any FAIL, so a caller (batch file, CI step) can detect a failed run from
  // '%errorlevel%'/its own exit-code check alone, without having to parse the log.
  if FailCount <> 0 then
    ExitCode := 1;
end.
