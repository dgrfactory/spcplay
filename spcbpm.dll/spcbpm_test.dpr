// *************************************************************************************************************************************************************
//   spcbpm_test - spcbpm.dll の動作確認 (x86 / x64)
// *************************************************************************************************************************************************************
//
//  SNESAPU.DLL と spcbpm.dll を読み込み、SPC ファイルを再生しながら BPM を解析して、次のことを確認する。
//    - Initialize が SNESAPU.DLL のハンドルを受け取れること (x64 でハンドルが 32 ビットに切り詰められないこと)
//    - Start が返す管理メモリのポインタが spcbpm.dll の中を指していること (x64 で 4 バイトだけ返さないこと)
//    - FORCEDSPDBG でビルドした spcbpm.dll の _DSPDebug が、前のベクタを DLL と同じ形で呼ぶこと
//        スタックの [+1] = DSP レジスタへのポインタ、[+2] = 値、EBX/RBX = ポインタ、EAX/RAX = 値
//        ポインタが 64 ビットのまま、GetAPUData の DSP レジスタ (128 バイト) の範囲に入っていること
//    - -cb を指定した場合、spcbpm より前に登録したテスト側の SNESAPUCallback に、spcbpm がイベントを呼び継ぐこと
//        CBE_DSPREG (spcbpm が登録したもの) と、Script700 の #i / #ib の CBE_INCS700 / CBE_INCDATA が届くこと
//        コールバックの中から呼んだ SetScript700 / SetScript700Data が、spcbpm を通しても使えること
//
//  ビルド (アーキテクチャごとに 1 回):
//    fpc -Pi386   -Twin32 spcbpm_test.dpr
//    fpc -Px86_64 -Twin64 spcbpm_test.dpr
//
//  使い方:
//    spcbpm_test.exe <SNESAPU.DLL> <spcbpm.dll> <SPC ファイル> [秒数 (既定 30)] [-cb]
//    -cb は、ほかの引数の前後どこに置いてもよい
//
//  _DSPDebug を確認するには、spcbpm.dll を FORCEDSPDBG を定義してビルドし、SNESAPU.DLL は DEBUG = 1 のものを使う。
//  FORCEDSPDBG なしの spcbpm.dll では SNESAPUCallback が使われ、テスト用のベクタは DLL から直接呼ばれる (モードとして表示する)。
//  BPM の値は、x86 版と x64 版で同じ SPC・同じ秒数を指定して、結果を比べる。
//  標準出力は x86 版と x64 版で同じ内容になるので、それぞれをファイルに保存して比べられる (アドレスは DSP やモジュールからの位置で表す)。
//  アーキテクチャ名と実際のアドレスは、調査用に標準エラー出力に出す。
//
//  終了コード: 0 = すべての確認に成功、1 = 失敗あり
//
// *************************************************************************************************************************************************************

program spcbpm_test;

{$MODE DELPHI}
{$APPTYPE CONSOLE}
{$ASMMODE INTEL}

uses
    Windows, SysUtils;

const
    SPC_FILE_SIZE = 66048;
    SAMPLE_RATE = 32000;
    CHUNK_SAMPLES = 3200;                                       // 0.1 秒
    DSP_REG_SIZE = 128;
    CBE_DSPREG = $01;                                           // SNESAPU コールバックのイベント
    CBE_INCS700 = $40000000;
    CBE_INCDATA = $20000000;
    // -cb の Script700。#i の中身は入力ポート 0 に 85 ($55) を書き、#ib の 1 バイト ($AA) は入力ポート 1 に書かれる
    SCRIPT_MAIN = '#i "inc.700"'#13#10'm d0 i1'#13#10'q'#13#10'e'#13#10'e'#13#10'#ib "data.bin"'#13#10;
    SCRIPT_INC = 'm #85 i0'#13#10;
    INC_TEXT_NAME = 'inc.700';
    INC_DATA_NAME = 'data.bin';
    INC_DATA_BYTE = $AA;

type
    TGetAPUData = procedure(ppRAM, ppXRAM, ppOutPort, ppT64Cnt, ppDSP, ppVoice, ppVMMaxL, ppVMMaxR: pointer); stdcall;
    TLoadSPCFile = procedure(pSPC: pointer); stdcall;
    TSetAPUOpt = procedure(mixType, numChn, bits, rate, inter, opts: longword); stdcall;
    TEmuAPU = function(pBuf: pointer; len: longword; ltype: byte): pointer; stdcall;
    TSetDSPDbg = function(pTrace: pointer): pointer; stdcall;
    TInitialize = function(hSNESAPU: THandle): longint; stdcall;
    TStart = function(lpReserved: pointer): longint; stdcall;
    TStop = function(): longint; stdcall;
    TGetBPM = function(lpReserved: pointer): longint; stdcall;
    TSNESAPUCallback = function(pCbFunc: pointer; cbMask: longword): pointer; stdcall;
    TSetScript700 = function(pSource: pointer): longint; stdcall;
    TSetScript700Data = function(addr: longword; pData: pointer; size: longword): longint; stdcall;

var
    // テスト用のベクタ (ChainStub) が記録する値
    ChainCount: longword;                                       // 呼ばれた回数
    ChainBadCount: longword;                                    // スタックとレジスタの不一致、または範囲外のポインタの回数
    ChainStackAddr: ptruint;                                    // 最後に受け取った値
    ChainStackValue: ptruint;
    ChainRegAddr: ptruint;
    ChainRegValue: ptruint;
    ChainRetAddr: ptruint;                                      // 最後の呼び出し元 (戻り先)
    DspBase: ptruint;                                           // DSP レジスタの先頭 (GetAPUData)

    // テスト側の SNESAPUCallback (TestCallback) が記録する値
    pSetScript700: TSetScript700;
    pSetScript700Data: TSetScript700Data;
    CbDspRegCount: longword;                                    // CBE_DSPREG の回数
    CbIncTextCount: longword;                                   // CBE_INCS700 の回数
    CbIncDataCount: longword;                                   // CBE_INCDATA の回数
    CbOtherCount: longword;                                     // そのほかのイベントの回数
    CbIncTextName: ansistring;                                  // 最後に受け取ったファイル名
    CbIncDataName: ansistring;
    CbIncTextAddr: longword;                                    // 最後に受け取った dwAddr (中身を置く位置)
    CbIncDataAddr: longword;
    CbIncTextValue: longword;                                   // 最後に受け取った dwValue (ファイル名の長さ)
    CbIncDataValue: longword;
    CbIncTextResult: longint;                                   // コールバックの中で呼んだ SetScript700 / SetScript700Data の戻り値
    CbIncDataResult: longint;
    IncDataByte: byte;

    FailCount: longint;

// ================================================================================
// ChainStub - テスト用の前のベクタ (SNESAPU.DLL と同じく、引数はスタック渡しで、呼び出し側が片付ける)
// ================================================================================
procedure ChainStub; assembler; nostackframe;
asm
{$IFDEF CPU64}
    // [RSP] = 戻り先、[RSP+8] = ポインタ、[RSP+16] = 値。RAX、RCX、RDX、R8-R11 は壊してよい
    lea     r10, [rip+ChainCount]
    inc     dword ptr [r10]
    mov     r11, [rsp+8]
    lea     r10, [rip+ChainStackAddr]
    mov     [r10], r11
    mov     r11, [rsp+16]
    lea     r10, [rip+ChainStackValue]
    mov     [r10], r11
    lea     r10, [rip+ChainRegAddr]
    mov     [r10], rbx
    lea     r10, [rip+ChainRegValue]
    mov     [r10], rax
    mov     r11, [rsp]
    lea     r10, [rip+ChainRetAddr]
    mov     [r10], r11
    // スタックとレジスタが一致し、ポインタが DSP レジスタの範囲に入っているか
    cmp     rbx, [rsp+8]
    jne     @Bad
    cmp     rax, [rsp+16]
    jne     @Bad
    mov     r11, [rsp+8]
    lea     r10, [rip+DspBase]
    sub     r11, [r10]
    cmp     r11, DSP_REG_SIZE
    jae     @Bad
    ret
@Bad:
    lea     r10, [rip+ChainBadCount]
    inc     dword ptr [r10]
{$ELSE}
    // [ESP] = 戻り先、[ESP+4] = ポインタ、[ESP+8] = 値。EAX、ECX、EDX は壊してよい
    inc     dword ptr [ChainCount]
    mov     ecx, [esp+4]
    mov     [ChainStackAddr], ecx
    mov     ecx, [esp+8]
    mov     [ChainStackValue], ecx
    mov     [ChainRegAddr], ebx
    mov     [ChainRegValue], eax
    mov     ecx, [esp]
    mov     [ChainRetAddr], ecx
    // スタックとレジスタが一致し、ポインタが DSP レジスタの範囲に入っているか
    cmp     ebx, [esp+4]
    jne     @Bad
    cmp     eax, [esp+8]
    jne     @Bad
    mov     ecx, [esp+4]
    sub     ecx, [DspBase]
    cmp     ecx, DSP_REG_SIZE
    jae     @Bad
    ret
@Bad:
    inc     dword ptr [ChainBadCount]
{$ENDIF}
end;

// ================================================================================
// TestCallback - テスト側の SNESAPUCallback (spcbpm より前に登録し、spcbpm から呼び継がれる)
// ================================================================================
function TestCallback(dwEffect: longword; dwAddr: longword; dwValue: longword; lpData: pointer): longword; stdcall;
var
    Name: ansistring;
begin
    // 扱わないイベントも含めて、値はそのまま返す
    result := dwValue;
    case dwEffect of
        CBE_DSPREG: Inc(CbDspRegCount);
        CBE_INCS700: begin
            // dwValue = ファイル名の長さ、lpData = ファイル名
            Inc(CbIncTextCount);
            CbIncTextAddr := dwAddr;
            CbIncTextValue := dwValue;
            SetString(Name, pansichar(lpData), dwValue);
            CbIncTextName := Name;
            CbIncTextResult := pSetScript700(pansichar(SCRIPT_INC));
        end;
        CBE_INCDATA: begin
            // dwAddr = データを置く位置
            Inc(CbIncDataCount);
            CbIncDataAddr := dwAddr;
            CbIncDataValue := dwValue;
            SetString(Name, pansichar(lpData), dwValue);
            CbIncDataName := Name;
            IncDataByte := INC_DATA_BYTE;
            CbIncDataResult := pSetScript700Data(dwAddr, @IncDataByte, 1);
        end;
        else Inc(CbOtherCount);
    end;
end;

// ================================================================================
// 補助関数
// ================================================================================
function Hex(Value: ptruint): string;
begin
    result := '$' + IntToHex(Value, SizeOf(pointer) * 2);
end;

// DSP レジスタへのポインタを、DSP の先頭からの位置で表す (x86 と x64 で同じになる)
function DspPos(Address: ptruint): string;
begin
    if Address - DspBase < DSP_REG_SIZE then result := 'DSP+$' + IntToHex(Address - DspBase, 2)
    else result := 'outside DSP';
end;

procedure Check(bOK: boolean; const Text: string);
begin
    if bOK then WriteLn('OK   ', Text)
    else begin
        WriteLn('FAIL ', Text);
        Inc(FailCount);
    end;
end;

procedure Fatal(const Text: string);
begin
    WriteLn('ERROR ', Text);
    Halt(1);
end;

function InModule(Address: pointer; hModule: THandle): boolean;
var
    Info: TMemoryBasicInformation;
begin
    result := (VirtualQuery(Address, Info, SizeOf(Info)) = SizeOf(Info)) and (THandle(Info.AllocationBase) = hModule);
end;

// アドレスがどのモジュールの中かを、モジュール名で表す (x86 と x64 で同じになる)
function ModuleName(Address: ptruint; hApu, hBpm: THandle): string;
begin
    if InModule(pointer(Address), hBpm) then result := 'spcbpm.dll'
    else if InModule(pointer(Address), hApu) then result := 'SNESAPU.DLL'
    else result := 'another module';
end;

function GetProc(hModule: THandle; const Name: string): pointer;
begin
    result := GetProcAddress(hModule, pchar(Name));
    if result = nil then Fatal('GetProcAddress failed: ' + Name);
end;

// ================================================================================
// メイン
// ================================================================================
var
    hApu, hBpm: THandle;
    pGetAPUData: TGetAPUData;
    pLoadSPCFile: TLoadSPCFile;
    pSetAPUOpt: TSetAPUOpt;
    pEmuAPU: TEmuAPU;
    pSetDSPDbg: TSetDSPDbg;
    pInitialize: TInitialize;
    pStart: TStart;
    pStop: TStop;
    pGetBPM: TGetBPM;
    pSNESAPUCallback: TSNESAPUCallback;
    pDsp, pCurrent, lpTempo, pRam, pPrevCb: pointer;
    Args: array of string;
    bCallback: boolean;
    SpcData: array[0..SPC_FILE_SIZE - 1] of byte;
    Buffer: array[0..CHUNK_SAMPLES * 4 - 1] of byte;            // ステレオ 16 ビット
    fSpc: file;
    BytesRead, Seconds, I, J, nResult: longint;
    bForced: boolean;
begin
    FailCount := 0;
    // 引数を読む (-cb はどこにあってもよく、それ以外を順に並べる)
    bCallback := false;
    SetLength(Args, 0);
    for I := 1 to ParamCount do begin
        if SameText(ParamStr(I), '-cb') then bCallback := true
        else begin
            SetLength(Args, Length(Args) + 1);
            Args[High(Args)] := ParamStr(I);
        end;
    end;
    if Length(Args) < 3 then begin
        WriteLn('usage: spcbpm_test.exe <SNESAPU.DLL> <spcbpm.dll> <SPC file> [seconds] [-cb]');
        Halt(1);
    end;
    Seconds := 30;
    if Length(Args) >= 4 then Seconds := StrToIntDef(Args[3], 30);
{$IFDEF CPU64}
    WriteLn(ErrOutput, 'spcbpm_test (x64)');
{$ELSE}
    WriteLn(ErrOutput, 'spcbpm_test (x86)');
{$ENDIF}

    // SNESAPU.DLL を読み込む
    hApu := LoadLibrary(pchar(Args[0]));
    if hApu = 0 then Fatal('LoadLibrary failed: ' + Args[0]);
    pGetAPUData := TGetAPUData(GetProc(hApu, 'GetAPUData'));
    pLoadSPCFile := TLoadSPCFile(GetProc(hApu, 'LoadSPCFile'));
    pSetAPUOpt := TSetAPUOpt(GetProc(hApu, 'SetAPUOpt'));
    pEmuAPU := TEmuAPU(GetProc(hApu, 'EmuAPU'));
    pSetDSPDbg := TSetDSPDbg(GetProc(hApu, 'SetDSPDbg'));
    pSNESAPUCallback := TSNESAPUCallback(GetProc(hApu, 'SNESAPUCallback'));
    pSetScript700 := TSetScript700(GetProc(hApu, 'SetScript700'));
    pSetScript700Data := TSetScript700Data(GetProc(hApu, 'SetScript700Data'));
    WriteLn(ErrOutput, 'SNESAPU.DLL  ', Hex(ptruint(hApu)));
    pDsp := nil;
    pRam := nil;
    pGetAPUData(@pRam, nil, nil, nil, @pDsp, nil, nil, nil);
    DspBase := ptruint(pDsp);
    WriteLn(ErrOutput, 'DSP          ', Hex(DspBase));

    // spcbpm より前に、テスト用の前のベクタを登録する
    pSetDSPDbg(@ChainStub);
    // -cb: spcbpm より前に、テスト側の SNESAPUCallback も登録する (spcbpm が後から登録して、呼び継ぐ形になる)
    if bCallback then begin
        CbDspRegCount := 0;
        CbIncTextCount := 0;
        CbIncDataCount := 0;
        CbOtherCount := 0;
        pPrevCb := pSNESAPUCallback(@TestCallback, CBE_INCS700 or CBE_INCDATA);
        Check(pPrevCb = nil, 'No SNESAPUCallback was installed before the test callback');
    end;

    // spcbpm.dll を読み込んで初期化する
    hBpm := LoadLibrary(pchar(Args[1]));
    if hBpm = 0 then Fatal('LoadLibrary failed: ' + Args[1]);
    pInitialize := TInitialize(GetProc(hBpm, 'Initialize'));
    pStart := TStart(GetProc(hBpm, 'Start'));
    pStop := TStop(GetProc(hBpm, 'Stop'));
    pGetBPM := TGetBPM(GetProc(hBpm, 'GetBPM'));
    WriteLn(ErrOutput, 'spcbpm.dll   ', Hex(ptruint(hBpm)));
    nResult := pInitialize(hApu);
    Check(nResult = 0, Format('Initialize returned %d', [nResult]));
    if nResult <> 0 then Halt(1);

    // spcbpm がどちらの方法で DSP の書き込みを受けているか (-1 は今のベクタを変えずに返す)
    pCurrent := pSetDSPDbg(pointer(-1));
    bForced := pCurrent <> @ChainStub;
    if bForced then WriteLn('Mode         SetDSPDbg (FORCEDSPDBG), _DSPDebug chains to the test vector')
    else WriteLn('Mode         SNESAPUCallback, the test vector is called by SNESAPU.DLL directly');

    // SPC ファイルを読み込む
    AssignFile(fSpc, Args[2]);
    {$I-}
    Reset(fSpc, 1);
    {$I+}
    if IOResult <> 0 then Fatal('Could not open ' + Args[2]);
    BlockRead(fSpc, SpcData, SPC_FILE_SIZE, BytesRead);
    CloseFile(fSpc);
    if BytesRead <> SPC_FILE_SIZE then Fatal(Format('%s is %d bytes, expected %d', [Args[2], BytesRead, SPC_FILE_SIZE]));
    pLoadSPCFile(@SpcData[0]);
    pSetAPUOpt(1, 2, 16, SAMPLE_RATE, longword(-1), longword(-1));

    // BPM 解析を開始する
    lpTempo := nil;
    nResult := pStart(@lpTempo);
    Check(nResult = 0, Format('Start returned %d', [nResult]));
    WriteLn(ErrOutput, 'Start        ', Hex(ptruint(lpTempo)));
    Check(InModule(lpTempo, hBpm), 'Start returned a pointer inside spcbpm.dll');

    // 再生する
    ChainCount := 0;
    ChainBadCount := 0;
    // 1 秒ごとに、その時点の BPM を表示する (x86 版と x64 版で、解析の進み方も比べられる)
    for I := 1 to Seconds do begin
        for J := 1 to SAMPLE_RATE div CHUNK_SAMPLES do pEmuAPU(@Buffer[0], CHUNK_SAMPLES, 1);
        WriteLn(Format('%4ds        BPM %d', [I, pGetBPM(nil)]));
    end;

    // 結果
    nResult := pGetBPM(nil);
    WriteLn(Format('BPM          %d (final, after %d seconds)', [nResult, Seconds]));
    Check(pStop() = 0, 'Stop');
    WriteLn(Format('Test vector  %d calls, last: stack %s $%s, registers %s $%s, called from %s',
        [ChainCount, DspPos(ChainStackAddr), IntToHex(ChainStackValue, 2), DspPos(ChainRegAddr), IntToHex(ChainRegValue, 2),
        ModuleName(ChainRetAddr, hApu, hBpm)]));
    WriteLn(ErrOutput, 'Test vector  last: stack ', Hex(ChainStackAddr), ' ', Hex(ChainStackValue), ', registers ', Hex(ChainRegAddr), ' ',
        Hex(ChainRegValue), ', return ', Hex(ChainRetAddr));
    Check(ChainCount > 0, 'The test vector was called (SNESAPU.DLL must be a DEBUG = 1 build)');
    Check(ChainBadCount = 0, Format('Every call passed the same pointer and value on the stack and in the registers, ' +
        'and the pointer was inside the DSP registers (%d bad)', [ChainBadCount]));
    if bForced then
        Check(InModule(pointer(ChainRetAddr), hBpm), 'The test vector was called from spcbpm.dll (_DSPDebug chained to it)')
    else
        Check(InModule(pointer(ChainRetAddr), hApu), 'The test vector was called from SNESAPU.DLL');

    // -cb: spcbpm を通した SNESAPUCallback の呼び継ぎを確認する
    if bCallback then begin
        // BPM 解析の再生中に、spcbpm が登録した CBE_DSPREG が呼び継がれたか (FORCEDSPDBG では spcbpm は登録しない)
        WriteLn(Format('Callback     CBE_DSPREG %d calls during playback', [CbDspRegCount]));
        if bForced then Check(CbDspRegCount = 0, 'The test callback got no CBE_DSPREG (spcbpm did not install a callback)')
        else Check(CbDspRegCount > 0, 'spcbpm passed CBE_DSPREG on to the test callback');
        // #i と #ib を含む Script700 を設定する (コールバックの中で SetScript700 / SetScript700Data を呼ぶ)
        nResult := pSetScript700(pansichar(SCRIPT_MAIN));
        WriteLn(Format('Callback     SetScript700 (main script) %d', [nResult]));
        WriteLn(Format('Callback     #i  "%s" %d call(s), addr %d, value %d, SetScript700 in the callback %d',
            [CbIncTextName, CbIncTextCount, CbIncTextAddr, CbIncTextValue, CbIncTextResult]));
        WriteLn(Format('Callback     #ib "%s" %d call(s), addr %d, value %d, SetScript700Data in the callback %d',
            [CbIncDataName, CbIncDataCount, CbIncDataAddr, CbIncDataValue, CbIncDataResult]));
        Check(nResult > 0, 'SetScript700 with #i and #ib succeeded');
        Check((CbIncTextCount = 1) and (CbIncTextName = INC_TEXT_NAME), 'CBE_INCS700 reached the test callback once with the file name');
        Check((CbIncDataCount = 1) and (CbIncDataName = INC_DATA_NAME), 'CBE_INCDATA reached the test callback once with the file name');
        Check(CbIncTextValue = Length(INC_TEXT_NAME), 'CBE_INCS700 passed the length of the file name as the value');
        Check(CbIncDataValue = Length(INC_DATA_NAME), 'CBE_INCDATA passed the length of the file name as the value');
        Check(CbIncTextResult > 0, 'SetScript700 inside the callback succeeded');
        Check(CbIncDataResult > 0, 'SetScript700Data inside the callback succeeded');
        Check(CbOtherCount = 0, 'No other event reached the test callback');
        // 少し再生して、読み込んだ中身が Script700 として動いたかを、入力ポート ($F4, $F5) で確かめる
        pEmuAPU(@Buffer[0], CHUNK_SAMPLES, 1);
        WriteLn(Format('Callback     ports $F4 $%s, $F5 $%s', [IntToHex(PByte(pRam)[$F4], 2), IntToHex(PByte(pRam)[$F5], 2)]));
        Check(PByte(pRam)[$F4] = 85, 'The included text ran (port 0 = $55)');
        Check(PByte(pRam)[$F5] = INC_DATA_BYTE, 'The included data was read (port 1 = $AA)');
        pSetScript700(nil);
    end;

    pSetDSPDbg(nil);
    FreeLibrary(hBpm);
    FreeLibrary(hApu);
    if FailCount = 0 then WriteLn('All checks passed') else WriteLn(Format('%d check(s) failed', [FailCount]));
    if FailCount <> 0 then Halt(1);
end.
