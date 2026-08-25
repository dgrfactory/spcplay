{===================================================================================================
 Program:    snesapu_pcmdump, headless x86/x64 SNESAPU.DLL output comparison tool
 Platform:   Win32 or Win64 (same source, built once per architecture)

 Loads a SNESAPU-compatible DLL, the real x86 snesapu.dll or the amd64 port, by path, feeds it one
 .spc file, and dumps a fixed number of raw PCM samples to a file, nothing else.  No GUI, no audio
 device, no dependency on spcplay.exe's Delphi, x86-only frontend.

 The point: SPC emulation is fully deterministic given the same input file and the same exact call
 pattern, same SetAPUOpt settings, same chunk size per EmuAPU call, same total sample count.  Run
 this once against snesapu.dll (x86 build) and once against snesapu_amd64.dll (x64 build) with
 identical arguments, and the two output files should be byte-for-byte identical.  Any difference is
 a real behavioral divergence between the two builds, not a rendering/rounding artifact.  There is
 no audio device, resampling, or floating-point display step in between to blur a comparison.

 Build (once per architecture; a 32-bit process cannot load a 64-bit DLL or vice versa, so the DLL
 path argument at runtime must match whichever this EXE was built for):
   fpc -Pi386   -Twin32 snesapu_pcmdump.dpr      (x86 tester, run against snesapu.dll)
   fpc -Px86_64 -Twin64 snesapu_pcmdump.dpr      (x64 tester, run against snesapu_amd64.dll)

 Usage:
   snesapu_pcmdump.exe <dll path> <spc file path> <out pcm path> <sample count> [script700 file]

 The optional 5th argument, if given, is fed to SetScript700 as a smoke test of the EXPROC-wrapper-
 plus-'I'-suffixed-internal-implementation split (see x64.inc's EXPROC doc).  Without it, a trivial
 built-in comment-only string is used instead, just to confirm SetScript700 doesn't crash.

 Example (from cmd, comparing the two builds against the same .spc):
   snesapu_pcmdump_x86.exe snesapu.dll       song.spc out_x86.pcm 1000000
   snesapu_pcmdump_x64.exe snesapu_amd64.dll song.spc out_x64.pcm 1000000
   fc /b out_x86.pcm out_x64.pcm

 SetAPUOpt is called with fixed values below, mixType=1, 2 channels, 16-bit, 32000Hz, INT_GAUSS,
 opts=0.  These must not change between the two compared runs, since the output format and mixing
 depend on them.  EmuAPU is called in fixed CHUNK_SAMPLES-sized chunks rather than one huge request,
 both because that is how a real frontend calls it and to keep memory use bounded.  The chunk size
 itself does not need to match spcplay.exe's, only between the two runs being compared to each other:
 SPC700/DSP.asm state advances the same way per sample regardless of how the caller batches its
 EmuAPU calls, so any fixed chunk size is fine as long as it is the same on both sides.
===================================================================================================}

program snesapu_pcmdump;

{$MODE DELPHI}
{$APPTYPE CONSOLE}

uses
  Windows, SysUtils;

type
  TEmuAPU           = function(pBuf: Pointer; len: Cardinal; ltype: Byte): Pointer; stdcall;
  TLoadSPCFile      = procedure(pSPC: Pointer); stdcall;
  TSetAPUOpt        = procedure(mixType, numChn, bits, rate, inter, opts: Cardinal); stdcall;
  TSNESAPUCallback  = function(pCbFunc: Pointer; cbMask: Cardinal): Pointer; stdcall;
  TSetScript700     = function(pSource: Pointer): Cardinal; stdcall;

  // See APU.inc's SNESAPUCallback doc: 'function: u32 Callback(u32 effect, u32 addr, u32 value,
  // void *lpData)'.  This is invoked from the DLL via x64.inc's ExtCall, real Microsoft x64 ABI,
  // all 4 args, so a correctly-firing, correctly-valued callback here is a direct test of
  // ExtCall/ExtCallArg's argument marshalling and its R11-staged indirect call target.
  TAPUCallback = function(effect, addr, value: Cardinal; lpData: Pointer): Cardinal; stdcall;

const
  SPC_FILE_SIZE   = 66048;              // Fixed .spc file size, see APU.h's LoadSPCFile doc
  CHUNK_SAMPLES   = 4096;               // Samples requested per EmuAPU call, must match between
                                        //  the x86 and x64 runs being compared, see file header
  SAMPLING_RATE   = 32000;
  CHANNELS        = 2;
  BITS            = 16;
  BYTES_PER_FRAME = 4;                  // 16-bit, 2 channels = 4 bytes/sample-frame, matches
                                        //  SetAPUOpt below.  Only sizes the scratch buffer generously
  INTERPOLATION   = 3;
  CBE_DSPREG      = $01;                // Write DSP value event, see APU.inc.  Fires on every DSP
                                        //  register write, so a normal playback should trigger it

var
  hDLL: THandle;
  pEmuAPU: TEmuAPU;
  pLoadSPCFile: TLoadSPCFile;
  pSetAPUOpt: TSetAPUOpt;
  pSNESAPUCallback: TSNESAPUCallback;
  pSetScript700: TSetScript700;
  DllPath, SpcPath, OutPath, Script700Path: String;
  TotalSamples, SamplesLeft, ChunkLen: Cardinal;
  SpcData: array[0..SPC_FILE_SIZE-1] of Byte;
  Buf: array[0..CHUNK_SAMPLES*BYTES_PER_FRAME-1] of Byte;
  fSpc, fOut: File;
  BytesRead, BytesWritten: LongInt;
  EndPtr: Pointer;
  ChunkBytes: NativeUInt;
  TotalWritten: Int64;
  CallbackCount: Int64;
  ScriptResult: Cardinal;
  TestScript: AnsiString;

procedure Fail(const Msg: String);
begin
  WriteLn('ERROR: ', Msg);
  Halt(1);
end;

// Reads a whole file into a null-terminated AnsiString, suitable for passing straight to
// SetScript700's PAnsiChar(pSource) parameter, see the Script700 test below.
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
    Fail(Format('Could not open Script700 file "%s"', [Path]));

  Size := FileSize(f);
  SetLength(Result, Size);
  if Size > 0 then
  begin
    BlockRead(f, Result[1], Size, Got);
    if Got <> Size then
      Fail(Format('Short read on Script700 file "%s" (got %d of %d bytes)', [Path, Got, Size]));
  end;
  CloseFile(f);
  Result := Result + #0;
end;

function APUCallback(effect, addr, value: Cardinal; lpData: Pointer): Cardinal; stdcall;
begin
  Inc(CallbackCount);
  if CallbackCount <= 5 then
    WriteLn(Format('  callback #%d: effect=0x%x addr=0x%x value=0x%x lpData=%p',
      [CallbackCount, effect, addr, value, lpData]));
  Result := value;     // Doc: "Usually, will return value of 'value' parameter."
end;

begin
  if ParamCount < 4 then
  begin
    WriteLn('Usage: snesapu_pcmdump <dll path> <spc file path> <out pcm path> <sample count> ',
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

  // Load the DLL and resolve the 3 exports this tool needs.
  hDLL := LoadLibrary(PChar(DllPath));
  if hDLL = 0 then
    Fail(Format('LoadLibrary failed for "%s" (GetLastError=%d)', [DllPath, GetLastError]));

  pEmuAPU          := TEmuAPU(GetProcAddress(hDLL, 'EmuAPU'));
  pLoadSPCFile     := TLoadSPCFile(GetProcAddress(hDLL, 'LoadSPCFile'));
  pSetAPUOpt       := TSetAPUOpt(GetProcAddress(hDLL, 'SetAPUOpt'));
  pSNESAPUCallback := TSNESAPUCallback(GetProcAddress(hDLL, 'SNESAPUCallback'));
  pSetScript700    := TSetScript700(GetProcAddress(hDLL, 'SetScript700'));

  if not Assigned(pEmuAPU) then          Fail('GetProcAddress failed for EmuAPU');
  if not Assigned(pLoadSPCFile) then     Fail('GetProcAddress failed for LoadSPCFile');
  if not Assigned(pSetAPUOpt) then       Fail('GetProcAddress failed for SetAPUOpt');
  if not Assigned(pSNESAPUCallback) then Fail('GetProcAddress failed for SNESAPUCallback');
  if not Assigned(pSetScript700) then    Fail('GetProcAddress failed for SetScript700');

  // Load the .spc file.
  AssignFile(fSpc, SpcPath);
  {$I-}
  Reset(fSpc, 1);
  {$I+}
  if IOResult <> 0 then
    Fail(Format('Could not open "%s"', [SpcPath]));

  BlockRead(fSpc, SpcData, SPC_FILE_SIZE, BytesRead);
  CloseFile(fSpc);
  if BytesRead <> SPC_FILE_SIZE then
    Fail(Format('"%s" is %d bytes, expected exactly %d', [SpcPath, BytesRead, SPC_FILE_SIZE]));

  pLoadSPCFile(@SpcData[0]);

  // Register a callback to exercise ExtCall's real Microsoft x64 ABI marshalling, see APUCallback
  // above.  Registered after LoadSPCFile so a fresh LoadSPCFile call would not need to re-arm it.
  CallbackCount := 0;
  pSNESAPUCallback(@APUCallback, CBE_DSPREG);

  // Exercise SetScript700, one of the EXPROC-wrapper-plus-'I'-suffixed-internal-implementation
  // split functions, see x64.inc's EXPROC doc, so this is a direct test of that split's pointer
  // argument forwarding: EXPROC SetScript700 -> Call SetScript700I,PAX.
  //
  // Test 1: pSource = NULL is documented in APU.inc to disable Script700 and return 0, a safe,
  // deterministic smoke test that does not depend on knowing Script700's actual command grammar.
  ScriptResult := pSetScript700(nil);
  WriteLn(Format('OK: SetScript700(NULL) returned %d (expected 0)', [ScriptResult]));
  if ScriptResult <> 0 then
    WriteLn('WARNING: expected 0 for a NULL pSource');

  // Test 2: a real, non-NULL buffer, just to exercise the pointer marshalling through a live
  // compile pass without crashing.  If a script700 file path was given on the command line, load
  // and use its actual content, letting you test a real Script700 program.  Otherwise fall back to
  // a trivial comment-only string.  Either way, no specific return value is asserted here unless a
  // real file was supplied: a hand-fed string is not necessarily valid Script700 syntax, and the
  // point of the fallback case is only that EXPROC correctly forwards the pointer without crashing.
  if Script700Path <> '' then
    TestScript := LoadTextFile(Script700Path)
  else
    TestScript := ';SetScript700 EXPROC smoke test' + #0;

  ScriptResult := pSetScript700(PAnsiChar(TestScript));
  if Script700Path <> '' then
    WriteLn(Format('OK: SetScript700("%s") returned %d (no crash)', [Script700Path, ScriptResult]))
  else
    WriteLn(Format('OK: SetScript700(<built-in test string>) returned %d (no crash)', [ScriptResult]));
  if (Script700Path <> '') and (ScriptResult = Cardinal(-1)) then
    WriteLn('WARNING: SetScript700 reported a binary-conversion error for this file');

  // If no real Script700 file was given, the built-in test string was only a smoke test of the
  // pointer forwarding.  Reset back to disabled so it does not affect the EmuAPU run below.  If a
  // real file was given, leave it active so that file's Script700 program drives the EmuAPU run.
  if Script700Path = '' then
    pSetScript700(nil);

  // Fixed, deterministic playback settings, do not change between compared runs.
  pSetAPUOpt(1, CHANNELS, BITS, SAMPLING_RATE, INTERPOLATION, 0);

  // Pull PCM in fixed-size chunks, dumping raw bytes as-is.
  AssignFile(fOut, OutPath);
  {$I-}
  Rewrite(fOut, 1);
  {$I+}
  if IOResult <> 0 then
    Fail(Format('Could not create "%s"', [OutPath]));

  TotalWritten := 0;
  SamplesLeft := TotalSamples;
  while SamplesLeft > 0 do
  begin
    if SamplesLeft > CHUNK_SAMPLES then
      ChunkLen := CHUNK_SAMPLES
    else
      ChunkLen := SamplesLeft;

    try
      EndPtr := pEmuAPU(@Buf[0], ChunkLen, 1);
    except
      on E: Exception do
        Fail(Format('EmuAPU raised %s ("%s") at DLL+0x%x (ExceptAddr=%p, DLL base=%p)',
          [E.ClassName, E.Message, NativeUInt(ExceptAddr) - NativeUInt(hDLL), ExceptAddr, Pointer(hDLL)]));
    end;
    ChunkBytes := NativeUInt(EndPtr) - NativeUInt(@Buf[0]);

    if ChunkBytes > SizeOf(Buf) then
      Fail(Format('EmuAPU reported %d bytes written, exceeding the %d-byte scratch buffer', [ChunkBytes, SizeOf(Buf)]));

    BlockWrite(fOut, Buf[0], ChunkBytes, BytesWritten);
    if Cardinal(BytesWritten) <> ChunkBytes then
      Fail('Write to output file failed');

    Inc(TotalWritten, ChunkBytes);
    Dec(SamplesLeft, ChunkLen);
  end;

  CloseFile(fOut);
  FreeLibrary(hDLL);

  WriteLn(Format('OK: %d samples (%d bytes) written to "%s"', [TotalSamples, TotalWritten, OutPath]));
  WriteLn(Format('OK: SNESAPUCallback (ExtCall) fired %d times', [CallbackCount]));
  if CallbackCount = 0 then
    WriteLn('WARNING: callback never fired -- CBE_DSPREG may not have triggered for this .spc file, or ExtCall is broken');
end.
