{===================================================================================================
 Program:    SNESAPU_amd64.DLL (amd64/x64 Free Pascal driver)
 Platform:   x86-64

 Not a reimplementation of SNESAPU.DLL.  All emulation code lives in the NASM object files built
 from ../snesapu.dll/APU.asm, DSP.asm, SPC700.asm ('nasm -f win64 -D WIN64 -D WIN32').  The x86
 build links those objects with Visual C++ 6's linker, which cannot target x64.  Free Pascal's
 linker consumes the same Microsoft COFF .obj files directly, so it stands in for link.exe here.

 What this file does:
   - The $L directive pulls APU.obj/DSP.obj/SPC700.obj into the library.  The three object files
     reference each other's PUBLIC symbols directly (SPC700.asm calls DSP.asm's DSPIn/CatchUp,
     APU.asm calls DSP.asm's SetEmuDSP, all three share pAPURAM/pSCRRAM/mix/dsp/scr700*/etc), so
     linking them together resolves those cross-references the same way the x86 link step did.
   - 'external name' declarations expose the object files' exported procedures to Pascal code
     without duplicating their implementation.
   - 'exports' re-exports the same 29 functions SNESAPU.def exports for the x86 build (see that
     file under snesapu.dll/), under the same undecorated names.  x64.inc's PUBLIC macro emits no
     name decoration, so no 'name' aliasing is needed to match the x86 DLL's ABI.
   - InitAPU replaces the x86 build's hand-written _DllMainCRTStartup (see SNESAPU.cpp), which just
     forwards the DllMain reason code to InitAPU.  InitAPU only acts on DLL_PROCESS_ATTACH (1) and
     always returns TRUE, and already no-ops for every other reason code (see APU.asm).  So the
     single direct call below, for the attach that already happened by the time Pascal's
     initialization runs, covers everything.  No DllProc hook is needed for later notifications.

 Build (Free Pascal only, no Visual C++ for x64).  Run from this directory. Pass -D WIN32 with
 -D WIN64: WIN32 already selects the Windows-safe SECTION alignment values.
   nasm -f win64 -D WIN64 -D WIN32 -o APU.obj    ..\APU.asm
   nasm -f win64 -D WIN64 -D WIN32 -o DSP.obj    ..\DSP.asm
   nasm -f win64 -D WIN64 -D WIN32 -o SPC700.obj ..\SPC700.asm
   fpc -Px86_64 -Twin64 -osnesapu_amd64.dll SNESAPU.dpr
 The three .obj files must sit next to this source file, or adjust the $L paths below, for fpc to
 find them.  Verified as of this writing: all three assemble at 0 errors with the commands above,
 and their PUBLIC symbol names match the 'external name' declarations below exactly.

 Copyright (C) 2026 degrade-factory.  All rights reserved.
===================================================================================================}

library SNESAPU;

{$ASSERTIONS OFF}                                           // ソースコードのアサート       : 無効
{$BOOLEVAL OFF}                                             // 完全論理式評価               : 無効
{$DEBUGINFO OFF}                                            // デバッグ情報                 : 無効
{$DENYPACKAGEUNIT ON}                                       // UNIT 不使用                  : 有効
{$EXTENDEDSYNTAX ON}                                        // 関数の戻り値を無視可能       : 有効
{$EXTENSION 'dll'}                                          // 拡張子設定                   : DLL
{$IMPORTEDDATA OFF}                                         // 別パッケージのメモリ参照     : 無効
{$IOCHECKS OFF}                                             // I/O チェック                 : 無効
{$MINENUMSIZE 1}                                            // 列挙型の最大サイズ (x256)    : 1 (256)
{$OPENSTRINGS OFF}                                          // オープン文字列パラメータ     : 無効
{$OVERFLOWCHECKS OFF}                                       // オーバーフローチェック       : 無効
{$RANGECHECKS OFF}                                          // 範囲チェック                 : 無効
{$TYPEDADDRESS OFF}                                         // ポインタの型チェック         : 無効
{$TYPEINFO OFF}                                             // 実行時型情報                 : 無効
{$VARSTRINGCHECKS OFF}                                      // 文字列チェック               : 無効
{$WARNINGS ON}                                              // 警告生成                     : 有効
{$WRITEABLECONST OFF}                                       // 定数書き換え                 : 無効

{$CALLING STDCALL}                                          // CALL スタック方式 (x86)      : STDCALL
{$CHECKPOINTER OFF}                                         // ポインタチェック             : 無効
{$CODEPAGE UTF-8}                                           // 文字コード                   : UTF-8
{$HINTS OFF}                                                // ヒント生成                   : 無効
{$IEEEERRORS OFF}                                           // 浮動小数エラーチェック       : 無効
{$MODE DELPHI}                                              // 言語モード                   : DELPHI
{$LONGSTRINGS ON}                                           // AnsiString 使用              : 有効 ($MODE の後に定義)
{$OPTIMIZATION AUTOINLINE}                                  // 最適化オプション             : 短い関数を自動的にインライン展開
{$OPTIMIZATION CONSTPROP}                                   // 最適化オプション             : 確定した計算や変数をコンパイル時に定数に置き換え
{$OPTIMIZATION CSE}                                         // 最適化オプション             : 重複する共通の計算式をまとめて結果を使い回す
{$OPTIMIZATION DFA}                                         // 最適化オプション             : 変数の無駄な代入や理論上通らない分岐を削除
{$OPTIMIZATION LOOPUNROLL}                                  // 最適化オプション             : ループを連続したコードに置き換えて回数判定・ジャンプ命令を削除
{$OPTIMIZATION PEEPHOLE}                                    // 最適化オプション             : 局所的に冗長なアセンブリ命令の並びを単純な命令に置き換え
{$OPTIMIZATION REMOVEEMPTYPROCS}                            // 最適化オプション             : 中身が空の関数や呼び出されても何も実行しない処理を削除
{$OPTIMIZATION REGVAR}                                      // 最適化オプション             : ローカル変数をメモリではなく CPU レジスタに配置
{$OPTIMIZATION SIZE}                                        // 最適化オプション             : 実行ファイルサイズの削減を優先
{$OPTIMIZATION STACKFRAME}                                  // 最適化オプション             : 不要な関数呼び出し時のスタック構築処理（前処理・後処理）を省略
{$OPTIMIZATION TAILREC}                                     // 最適化オプション             : 関数の最後の再帰呼び出しをループ（ジャンプ命令）に変換して高速化
{$OPTIMIZATION USEEBP}                                      // 最適化オプション             : EBP レジスタを計算用の汎用レジスタとして流用
{$OPTIMIZATION USELOADMODIFYSTORE}                          // 最適化オプション             : 同一変数への再代入処理で直接変数を操作
{$POINTERMATH ON}                                           // ポインタ演算                 : 有効
{$SAFEFPUEXCEPTIONS OFF}                                    // FPU エラー即時報告           : 無効
{$SMARTLINK ON}                                             // スマートリンク               : 有効

{$L APU.obj}
{$L DSP.obj}
{$L SPC700.obj}
{$R 'version.res' 'version.rc'}


// ===================================================================================================
// External declarations, one per SNESAPU.def export.  Signatures follow snesapu.dll\SNESAPU.h:
// u8=Byte, u16=Word, u32=Cardinal, s32=LongInt, b8=Byte, any struct pointer=Pointer.  None of these
// 29 functions need the caller to know the pointed-to layout.  They hand back opaque pointers that
// calling code stores and passes back, exactly as GetAPUData's own callers do.

function  EmuAPU(pBuf: Pointer; len: Cardinal; ltype: Byte): Pointer; stdcall; external name 'EmuAPU';
procedure FixAPU(pc: Word; a, y, x, psw, sp: Byte); stdcall; external name 'FixAPU';
procedure GetAPUData(ppAPURAM, ppExtraRAM, ppSPCOut, ppT64Cnt, ppDSP, ppMix, ppVMMaxL, ppVMMaxR: Pointer); stdcall; external name 'GetAPUData';
procedure GetScript700Data(pVer: PAnsiChar; ppSPCReg, ppScript700: Pointer); stdcall; external name 'GetScript700Data';
function  GetSNESAPUContext(pCtxOut: Pointer): Cardinal; stdcall; external name 'GetSNESAPUContext';
function  GetSNESAPUContextSize: Cardinal; stdcall; external name 'GetSNESAPUContextSize';
procedure GetSPCRegs(pPC, pA, pY, pX, pPSW, pSP: Pointer); stdcall; external name 'GetSPCRegs';
procedure InPort(port: Cardinal; val: Byte); stdcall; external name 'InPort';
function  InitAPU(reason: Cardinal): Cardinal; stdcall; external name 'InitAPU';
procedure LoadSPCFile(pSPC: Pointer); stdcall; external name 'LoadSPCFile';
procedure ResetAPU(amp: Cardinal); stdcall; external name 'ResetAPU';
procedure SeekAPU(time: Cardinal; fast: Byte); stdcall; external name 'SeekAPU';
function  SetAPULength(song, fade: Cardinal): Cardinal; stdcall; external name 'SetAPULength';
procedure SetAPUOpt(mix, chn, bits, rate, inter, opts: Cardinal); stdcall; external name 'SetAPUOpt';
procedure SetAPURAM(addr: Cardinal; val: Byte); stdcall; external name 'SetAPURAM';
procedure SetAPUSmpClk(speed: Cardinal); stdcall; external name 'SetAPUSmpClk';
procedure SetDSPAmp(level: Cardinal); stdcall; external name 'SetDSPAmp';
function  SetDSPDbg(pTrace: Pointer): Pointer; stdcall; external name 'SetDSPDbg';
procedure SetDSPEFBCT(leak: LongInt); stdcall; external name 'SetDSPEFBCT';
procedure SetDSPPitch(base: Cardinal); stdcall; external name 'SetDSPPitch';
function  SetDSPReg(reg, val: Byte): Byte; stdcall; external name 'SetDSPReg';
procedure SetDSPStereo(sep: Cardinal); stdcall; external name 'SetDSPStereo';
procedure SetDSPVol(vol: Cardinal); stdcall; external name 'SetDSPVol';
function  SetScript700(pSource: Pointer): Cardinal; stdcall; external name 'SetScript700';
function  SetScript700Data(addr: Cardinal; pData: Pointer; size: Cardinal): Cardinal; stdcall; external name 'SetScript700Data';
function  SetSNESAPUContext(pCtxIn: Pointer): Cardinal; stdcall; external name 'SetSNESAPUContext';
function  SetSPCDbg(pTrace: Pointer; opts: Cardinal): Pointer; stdcall; external name 'SetSPCDbg';
procedure SetTimerTrick(port, wait: Cardinal); stdcall; external name 'SetTimerTrick';
function  SNESAPUCallback(pCbFunc: Pointer; cbMask: Cardinal): Pointer; stdcall; external name 'SNESAPUCallback';
procedure SNESAPUInfo(pVer, pMin, pOpt: Pointer); stdcall; external name 'SNESAPUInfo';

// ===================================================================================================
// Entry point, see the file header comment.  InitAPU only acts on DLL_PROCESS_ATTACH and always
// returns TRUE, so there is nothing worth checking here, matching _DllMainCRTStartup.

procedure SNESAPUDllProc(Reason: LongInt);
begin
  InitAPU(Reason);
end;

exports
  EmuAPU,
  FixAPU,
  GetAPUData,
  GetScript700Data,
  GetSNESAPUContext,
  GetSNESAPUContextSize,
  GetSPCRegs,
  InPort,
  LoadSPCFile,
  ResetAPU,
  SeekAPU,
  SetAPULength,
  SetAPUOpt,
  SetAPURAM,
  SetAPUSmpClk,
  SetDSPAmp,
  SetDSPDbg,
  SetDSPEFBCT,
  SetDSPPitch,
  SetDSPReg,
  SetDSPStereo,
  SetDSPVol,
  SetScript700,
  SetScript700Data,
  SetSNESAPUContext,
  SetSPCDbg,
  SetTimerTrick,
  SNESAPUCallback,
  SNESAPUInfo;

begin
  SNESAPUDllProc(1);   // 1 = DLL_PROCESS_ATTACH.  Avoids the Windows unit for one constant.
                       // No DllProc hook is needed for later notifications: InitAPU checks
                       // reason=DLL_PROCESS_ATTACH itself and no-ops for every other reason code
                       // (see APU.asm), so this one direct call for the initial attach covers
                       // everything InitAPU does.
end.
