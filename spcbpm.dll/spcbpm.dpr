// *************************************************************************************************************************************************************
//   BPM Analyzer for SNESAPU.DLL
// *************************************************************************************************************************************************************

// =================================================================================================
//
//  +++ THIS SOURCE CODE IS GPL +++
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation; either version 2 of the License,
//  or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
//  See the GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the
//  Free Software Foundation, Inc.
//  59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
//
//  * GNU GPL v2.0 document is in LICENSE file.
//
//
//  +++ このソースコードは GPL です +++
//
//  このプログラムはフリーソフトウェアです。 あなたはフリーソフトウェア団体によって発行
//  されている GNU 一般公衆利用許諾契約書のバージョン 2、もしくは希望であればそれ以上の
//  バージョンのうち、いずれかで定められた条件の下でこのプログラムを再配布、もしくは改変
//  することができます。
//
//  このプログラムは役に立つことを期待して配布されていますが、『 何の保証もありません 』。
//  つまり、『 商品性 (機能性、安全性、耐久性に優れているか) 』や『 適合性 (ある特定の目的に
//  うまく使用できるか) 』の黙示的な保証さえありません。
//  詳しくは GNU 一般公衆利用許諾契約書 (GNU General Public License) をご覧ください。
//
//  あなたはこのプログラムと一緒に GNU 一般公衆利用許諾契約書のコピーを受け取ったはずです。
//  受け取っていない場合は、フリーソフトウェア団体から取り寄せてください。
//  宛先 : Free Software Foundation, Inc.
//         59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
//
//  ※ GNU 一般公衆利用許諾契約書バージョン 2 のドキュメントは、付属の LICENSE にあります。
//
//
//  Copyright (C) 2024 degrade-factory. All rights reserved.
//
// =================================================================================================
library spcbpm;

//{$DEFINE FORCEDSPDBG}                                     // DSPDbg API を強制使用

{$APPTYPE GUI}                                              // アプリケーションタイプ       : GUI モード
{$ASSERTIONS OFF}                                           // ソースコードのアサート       : 無効
{$BOOLEVAL OFF}                                             // 完全論理式評価               : 無効
{$DEBUGINFO OFF}                                            // デバッグ情報                 : 無効
{$DENYPACKAGEUNIT ON}                                       // UNIT 不使用                  : 有効
{$EXTENDEDSYNTAX ON}                                        // 関数の戻り値を無視可能       : 有効
{$EXTENSION 'dll'}                                          // 拡張子設定                   : DLL
{$IMAGEBASE $00400000}                                      // イメージベースアドレス       : 0x00400000
{$IMPORTEDDATA OFF}                                         // 別パッケージのメモリ参照     : 無効
{$IOCHECKS OFF}                                             // I/O チェック                 : 無効
{$LONGSTRINGS ON}                                           // AnsiString 使用              : 有効
{$MAXSTACKSIZE $00100000}                                   // 最大スタック設定             : 0x00100000
{$MINENUMSIZE 1}                                            // 列挙型の最大サイズ (x256)    : 1 (256)
{$MINSTACKSIZE $00004000}                                   // 最小スタック設定             : 0x00004000
{$OPENSTRINGS OFF}                                          // オープン文字列パラメータ     : 無効
{$OVERFLOWCHECKS OFF}                                       // オーバーフローチェック       : 無効
{$RANGECHECKS OFF}                                          // 範囲チェック                 : 無効
{$R 'spcbpm.res' 'spcbpm.rc'}                               // リソース                     : spcbpm.res <- spcbpm.rc
{$STACKFRAMES OFF}                                          // 完全スタックフレーム生成     : 無効
{$TYPEDADDRESS OFF}                                         // ポインタの型チェック         : 無効
{$TYPEINFO OFF}                                             // 実行時型情報                 : 無効
{$VARSTRINGCHECKS OFF}                                      // 文字列チェック               : 無効
{$WARNINGS ON}                                              // 警告生成                     : 有効
{$WEAKPACKAGEUNIT OFF}                                      // 弱いパッケージ化             : 無効
{$WRITEABLECONST OFF}                                       // 定数書き換え                 : 無効

{$IFDEF FREEPASCAL}     // for Free Pascal 3.2+
{$CALLING STDCALL}                                          // CALL スタック方式            : STDCALL
{$CHECKPOINTER OFF}                                         // ポインタチェック             : 無効
{$FPUTYPE x87}                                              // 浮動小数演算命令             : x87
{$HINTS OFF}                                                // ヒント生成                   : 無効
{$IEEEERRORS OFF}                                           // 浮動小数エラーチェック       : 無効
{$MODE delphi}                                              // 言語モード                   : delphi
{$OPTIMIZATION LEVEL3,USEEBP}                               // 最適化コンパイル             : Lv3, EBP レジスタ使用
{$POINTERMATH ON}                                           // ポインタ演算                 : 有効
{$SAFEFPUEXCEPTIONS OFF}                                    // FPU エラー即時報告           : 無効
{$ELSE}                 // for Boland Delphi 6+
{$DEFINITIONINFO OFF}                                       // シンボル宣言と参照情報       : 無効
{$DESIGNONLY OFF}                                           // IDE 使用                     : 無効
{$HINTS ON}                                                 // ヒント生成                   : 有効
{$IMPLICITBUILD ON}                                         // ビルドのたびに再コンパイル   : 有効
{$LOCALSYMBOLS OFF}                                         // ローカルシンボル情報         : 無効
{$OBJEXPORTALL OFF}                                         // シンボルのエクスポート       : 無効
{$OPTIMIZATION ON}                                          // 最適化コンパイル             : 有効
{$REALCOMPATIBILITY OFF}                                    // Real48 互換                  : 無効
{$REFERENCEINFO OFF}                                        // 完全な参照情報の生成         : 無効
{$RUNONLY OFF}                                              // 実行時のみコンパイル         : 無効
{$SAFEDIVIDE OFF}                                           // 初期 Pentium FDIV バグ回避   : 無効
{$ENDIF}


// *************************************************************************************************************************************************************
// 外部クラスの宣言
// *************************************************************************************************************************************************************

//uses MemCheck in '..\..\memcheck\MemCheck.pas';


// *************************************************************************************************************************************************************
// 構造体、およびクラスの宣言
// *************************************************************************************************************************************************************

type
{$ALIGN OFF} // 構造体の自動サイズ調整なし --- ここから
    // DSPVOICE 構造体
    TDSPVOICE = record
        VolumeLeft: byte;                                   // 出力レベル (左)
        VolumeRight: byte;                                  // 出力レベル (右)
        Pitch: word;                                        // ピッチ (下位 14 ビット)
        SoundSourcePlayBack: byte;                          // 波形番号
        EnvelopeADSR1: byte;                                // エンベロープの種類 (上位 1 ビット) と ADSR エンベロープの設定 (DR : 3 ビット、AR : 4 ビット)
        EnvelopeADSR2: byte;                                // エンベロープの設定 (SL : 3 ビット、SR : 5 ビット)
        EnvelopeGain: byte;                                 // Gain エンベロープの設定 (上位 3 ビット)
        CurrentEnvelope: byte;                              // 現在のエンベロープ値
        CurrentOutput: byte;                                // 現在の波形出力値
        __r: array[0..4] of byte;                           // (予約) = DSPREG 構造体
        Fir: byte;                                          // FIR フィルタ係数
    end;

    // DSPREG 構造体
    TDSPREG = record case byte of
        1: (Voice: array[0..7] of TDSPVOICE);               // ボイスレジスタ (DSPVOICE x8)
        2: (__r00: array[0..11] of byte;                    // (予約) = DSPVOICE
            MainVolumeLeft: byte;                           // マスター音量 (左)
            EchoFeedback: byte;                             // エコーフィードバックの強さ
            __r0E: byte;                                    // (未使用)
            __r0F: byte;                                    // (予約) = DSPVOICE
            __r10: array[0..11] of byte;                    // (予約) = DSPVOICE
            MainVolumeRight: byte;                          // マスター音量 (右)
            __r1D: byte;                                    // (未使用)
            __r1E: byte;                                    // (未使用)
            __r1F: byte;                                    // (予約) = DSPVOICE
            __r20: array[0..11] of byte;                    // (予約) = DSPVOICE
            EchoVolumeLeft: byte;                           // エコー音量 (左)
            PitchModOn: byte;                               // 各チャンネルのピッチモジュレーションのオンフラグ (8 ビット)
            __r2E: byte;                                    // (未使用)
            __r2F: byte;                                    // (予約) = DSPVOICE
            __r30: array[0..11] of byte;                    // (予約) = DSPVOICE
            EchoVolumeRight: byte;                          // エコー音量 (右)
            NoiseOn: byte;                                  // 各チャンネルのノイズのオンフラグ (8 ビット)
            __r3E: byte;                                    // (未使用)
            __r3F: byte;                                    // (予約) = DSPVOICE
            __r40: array[0..11] of byte;                    // (予約) = DSPVOICE
            KeyOn: byte;                                    // 各チャンネルのキーのオンフラグ (8 ビット)
            EchoOn: byte;                                   // 各チャンネルのエコーのオンフラグ (8 ビット)
            __r4E: byte;                                    // (未使用)
            __r4F: byte;                                    // (予約) = DSPVOICE
            __r50: array[0..11] of byte;                    // (予約) = DSPVOICE
            KeyOff: byte;                                   // 各チャンネルのキーのオフフラグ (8 ビット)
            SourceDirectory: byte;                          // ソースディレクトリ (波形情報が格納されているメモリのオフセットアドレス x0x100)
            __r5E: byte;                                    // (未使用)
            __r5F: byte;                                    // (予約) = DSPVOICE
            __r60: array[0..11] of byte;                    // (予約) = DSPVOICE
            Flags: byte;                                    // DSP リセット、出力無効、エコー無効フラグ (上位 3 ビット) とノイズ周波数 (下位 5 ビット)
            EchoWaveform: byte;                             // エコー記憶領域 (エコー処理に使用するメモリのオフセットアドレス x0x100)
            __r6E: byte;                                    // (未使用)
            __r6F: byte;                                    // (予約) = DSPVOICE
            __r70: array[0..11] of byte;                    // (予約) = DSPVOICE
            EndWaveform: byte;                              // 各チャンネルの波形フォームの終了点通過フラグ (8 ビット)
            EchoDelay: byte;                                // エコーディレイ時間 (x16 [ms])
            __r7E: byte;                                    // (未使用)
            __r7F: byte);                                   // (予約) = DSPVOICE
        3: (Reg: array[0..127] of byte);                    // DSP レジスタ
    end;
{$ALIGN ON}  // 構造体の自動サイズ調整なし --- ここまで

    // APU 構造体
    TAPU = record
        T64Count: ^longword;                                // 64kHz タイマカウンタのポインタ (64000 count/sec)
        DspReg: ^TDSPREG;                                   // DSP レジスタのポインタ (128 バイト)
        GetAPUData: procedure(ppRam: pointer; ppXRam: pointer; ppSPCOutput: pointer; ppT64Count: pointer; ppDsp: pointer; ppVoices: pointer;
            ppVolumeMaxLeft: pointer; ppVolumeMaxRight: pointer); stdcall;
        SNESAPUCallback: function(pCbFunc: pointer; cbMask: longword): pointer; stdcall;
        SNESAPUCallbackProc: function(dwEffect: longword; dwAddr: longword; dwValue: longword; lpData: pointer): longword; stdcall;
        SetDSPDbg: function(pDSPDbg: pointer): pointer; stdcall;
        DSPDebug: procedure(); stdcall;
    end;

    // TEMPOHISTORY 構造体
    TTEMPOHISTORY = record case byte of
        1: (cChannel: byte;                                 // チャンネル番号
            cSource: byte;                                  // 音色番号
            cVolume: byte;                                  // 音量
            __r1: byte;                                     // (未使用)
            wPitch: word;                                   // ピッチ
            __r2: byte;                                     // (未使用)
            __r3: byte);                                    // (未使用)
        2: (qwHash: int64);                                 // 疑似ハッシュ値
    end;

    // TEMPO 構造体
    TTEMPO = record
        bDisable: bytebool;                                 // 無効フラグ
        cBPM: byte;                                         // 確定テンポ
        cMinBPM: byte;                                      // テンポ解析範囲 (最小)
        cMaxBPM: byte;                                      // テンポ解析範囲 (最大)
        cMode: byte;                                        // テンポ解決モード (信頼度)
        cKOn: byte;                                         // KON フラグ
        cKOnCount: byte;                                    // KON カウンタ
        cKOnCountOld: byte;                                 // KON カウンタ (前回の値)
        dwStartTime: longword;                              // 解析開始時間 (64kHz)
        dwKOnTime: longword;                                // KON 間隔解析用時間 (64kHz)
        dwMinTime: longword;                                // 最小テンポ解析用時間 (64kHz)
        dwMaxTime: longword;                                // 最大テンポ解析用時間 (64kHz)
        dwTripleTime: longword;                             // 三拍子・三連符考慮時間 (64kHz)
        Count: array[60..200] of longword;                  // テンポごとのカウンタ
        T64Count: array[0..7] of longword;                  // チャンネルごとの前回発音時間 (64kHz)
        Volume: array[0..7] of byte;                        // チャンネルごとの音量
        dwHistory: longword;                                // 履歴番号
        History: array[0..15] of TTEMPOHISTORY              // 履歴
    end;


// *************************************************************************************************************************************************************
// 定数の宣言
// *************************************************************************************************************************************************************

const
    // Delphi 標準定数
    NULL = 0;                                               // ヌル
    NULLCHAR = #0;                                          // ヌル文字
    NULLPOINTER = nil;                                      // ヌルポインタ

    CBE_DSPREG = $1;


// *************************************************************************************************************************************************************
// グローバル変数の宣言
// *************************************************************************************************************************************************************

var
    Apu: TAPU;                                              // APU
    Status: record                                          // ステータス
        bInitialized: longbool;                                 // 初期化済み
        Tempo: TTEMPO;                                          // テンポ
    end;
    Option: record                                          // オプション
        bBPM: longbool;                                         // テンポ解析
    end;


// *************************************************************************************************************************************************************
// Win32 API の宣言
// *************************************************************************************************************************************************************

function  API_GetProcAddress(hModule: longword; lpProcName: pointer): pointer; stdcall; external 'kernel32.dll' name 'GetProcAddress';
procedure API_MoveMemory(Destination: pointer; Source: pointer; Length: longword); stdcall; external 'kernel32.dll' name 'RtlMoveMemory';
procedure API_ZeroMemory(Destination: pointer; Length: longword); stdcall; external 'kernel32.dll' name 'RtlZeroMemory';


// *************************************************************************************************************************************************************
// メインプロシージャ
// *************************************************************************************************************************************************************

// ================================================================================
// AnalyzeTempo - テンポの推測
// ================================================================================
procedure AnalyzeTempo(dwValue: longword);
var
    I: longint;
    cKOn: byte;
    cEnable: byte;
    cValue: byte;
    cBPM1: byte;
    cBPM2: byte;
    dwBPM: longword;
    dwScan1: longint;
    dwScan2: longword;
    dwCount1: longword;
    dwCount2: longword;
    dwCount3: longword;
    T64Count: longword;
    Tempo: ^TTEMPO;
    DspVoice: ^TDSPVOICE;
    History: TTEMPOHISTORY;
begin
    // テンポ解析が無効な場合は終了
    Tempo := @Status.Tempo;
    if Tempo.bDisable then exit;
    // 新しく KON されたチャンネルを取得
    cKOn := dwValue;
    cEnable := (cKOn xor Tempo.cKOn) and cKOn;
    Tempo.cKOn := cKOn;
    // 新しく KON されたチャンネルがない場合は終了
    if not bytebool(cEnable) then exit;
    // 各チャンネルの最大音量を取得
    T64Count := Apu.T64Count^;
    cKOn := 1;
    for I := 0 to 7 do begin
        if bytebool(cEnable and cKOn) then begin
            // 平均音量を取得
            DspVoice := @Apu.DspReg.Voice[I];
            dwScan2 := Abs(shortint(DspVoice.VolumeLeft)) + Abs(shortint(DspVoice.VolumeRight));
            cValue := (dwScan2 shr 1) + (dwScan2 and 1);
            Tempo.Volume[I] := cValue;
            // 発音履歴を記録
            if bytebool(cValue) then begin
                History.cChannel := I;
                History.cSource := DspVoice.SoundSourcePlayBack;
                History.cVolume := cValue;
                History.wPitch := DspVoice.Pitch;
                Tempo.History[Tempo.dwHistory].qwHash := History.qwHash;
                Tempo.dwHistory := (Tempo.dwHistory + 1) and 15;
            // 無音を除外
            end else cEnable := cEnable xor cKOn;
        end;
        Inc(cKOn, cKOn);
    end;
    // 解析対象のチャンネルがない場合は終了
    if not bytebool(cEnable) then exit;
    // 各チャンネルの時間成分を取得
    cKOn := 1;
    for I := 0 to 7 do begin
        if bytebool(cEnable and cKOn) then begin
            // 前回 KON の時間差分からテンポを計算
            dwCount1 := Tempo.T64Count[I];
            if longbool(dwCount1) then begin
                dwBPM := T64Count - dwCount1;
                if longbool(dwBPM) then dwBPM := 7680000 div dwBPM; // 60(bpm) * 64000(1sec) * 2
                // 重みづけ
                if (dwBPM >= 521) and (dwBPM <= 800) then Inc(Tempo.Count[(dwBPM shr 2) + ((dwBPM shr 1) and 1)]);
                if (dwBPM >= 240) and (dwBPM <= 520) then Inc(Tempo.Count[(dwBPM shr 2) + ((dwBPM shr 1) and 1)], 2);
                if (dwBPM >= 261) and (dwBPM <= 400) then Inc(Tempo.Count[(dwBPM shr 1) + (dwBPM and 1)], 2);
                if (dwBPM >= 120) and (dwBPM <= 260) then Inc(Tempo.Count[(dwBPM shr 1) + (dwBPM and 1)], 3);
                if (dwBPM >= 131) and (dwBPM <= 200) then Inc(Tempo.Count[dwBPM], 3);
                if (dwBPM >=  60) and (dwBPM <= 130) then Inc(Tempo.Count[dwBPM], 4);
                if (dwBPM >=  66) and (dwBPM <= 100) then Inc(Tempo.Count[dwBPM + dwBPM], 4);
                if (dwBPM >=  30) and (dwBPM <=  65) then Inc(Tempo.Count[dwBPM + dwBPM], 5);
            end;
            Tempo.T64Count[I] := T64Count;
            // 疑似エコーを除外
            DspVoice := @Apu.DspReg.Voice[I];
            for dwCount1 := 0 to 15 do begin
                History.qwHash := Tempo.History[dwCount1].qwHash;
                if History.cChannel = I then continue;
                if History.cSource <> DspVoice.SoundSourcePlayBack then continue;
                if History.cVolume <= Tempo.Volume[I] then continue;
                if Abs(smallint(History.wPitch - DspVoice.Pitch)) >= 80 then continue;
                cEnable := cEnable xor cKOn;
                break;
            end;
        end;
        Inc(cKOn, cKOn);
    end;
    // 解析対象のチャンネルがない場合は終了
    if not bytebool(cEnable) then exit;
    // 解析基準となるテンポの範囲を計算
    dwCount3 := T64Count - Tempo.dwKOnTime;
    if dwCount3 >= 4800 then begin // 75ms (max 800bpm)
        // KON 数をカウント
        Tempo.dwKOnTime := T64Count;
        Inc(Tempo.cKOnCount);
        // 曲全体のテンポを計算
        dwBPM := 7680000 div dwCount3; // 60(bpm) * 64000(1sec) * 2
        dwBPM := (dwBPM shr 1) + (dwBPM and 1);
        while longbool(dwBPM) and (dwBPM <= 56) do Inc(dwBPM, dwBPM);
        while longbool(dwBPM) and (dwBPM >= 204) do dwBPM := dwBPM shr 1;
        if dwBPM < 60 then dwBPM := 60;
        if dwBPM > 200 then dwBPM := 200;
        // 最小テンポを計算
        if dwBPM <= 70 then dwCount1 := 64 else dwCount1 := dwBPM - 6;
        if bytebool(Tempo.cMinBPM) then begin
            dwScan2 := Tempo.cMinBPM;
            if (dwCount1 <= dwScan2) or ((T64Count - Tempo.dwMinTime) >= 480000) then Tempo.dwMinTime := T64Count // 7.5sec
            else dwCount1 := dwScan2 + 1;
        end;
        // 最大テンポを計算
        if dwCount1 >= 184 then if dwBPM >= 194 then dwCount2 := 200 else dwCount2 := dwBPM + 6
        else if dwBPM >= 190 then dwCount2 := 196 else dwCount2 := dwBPM + 6;
        if bytebool(Tempo.cMaxBPM) then begin
            dwScan2 := Tempo.cMaxBPM;
            if (dwCount2 >= dwScan2) or ((T64Count - Tempo.dwMaxTime) >= 320000) then Tempo.dwMaxTime := T64Count // 5sec
            else dwCount2 := dwScan2 - (Tempo.cKOnCount and 1);
        end;
        if dwCount2 <= 76 then dwCount1 := 60;
        // 解析基準範囲を確定
        Tempo.cMinBPM := dwCount1;
        Tempo.cMaxBPM := dwCount2;
    end else begin
        // 解析基準範囲が未決定の場合は、仮設定
        if not bytebool(Tempo.cMinBPM) then Tempo.cMinBPM := 120;
        if not bytebool(Tempo.cMaxBPM) then Tempo.cMaxBPM := 140;
        dwCount1 := Tempo.cMinBPM;
        dwCount2 := Tempo.cMaxBPM;
    end;
    // 解析開始から規定時間が経過していない場合は終了
    dwScan2 := T64Count - Tempo.dwStartTime;
    if dwScan2 < 64000 then exit; // 1sec
    // 解析基準範囲を補正
    cEnable := $31; // 1-4
    if dwCount2 >= 140 then begin
        cValue := ((dwCount2 * 6553) shr 16) - (longword(dwCount2 >= 170) and 1) - 4; // max * 0.1 - (4 or 5)
        if not bytebool(Tempo.cKOnCountOld) and (Tempo.cKOnCount <= cValue) then begin
            // 初回解析時に発音回数が少ない場合、最小テンポの基準範囲を 1/2 に設定
            dwCount1 := dwCount1 shr 1;
            if dwCount1 < 64 then dwCount1 := 64;
            cEnable := $41; // A-D
        end else if bytebool(Tempo.cKOnCountOld) and (Tempo.cKOnCountOld <= cValue) then begin
            // 前回解析時に発音回数が少ない場合、最小・最大テンポの基準範囲を 1/2 に設定
            dwCount1 := dwCount1 shr 1;
            dwCount2 := (dwCount2 shr 1) + 3; // min 73
            if dwCount1 < 64 then dwCount1 := 64;
            if dwCount2 < 127 then dwCount2 := 127;
            cEnable := $41; // A-D
        end else if dwCount1 <= (Tempo.cBPM + 12) then begin
            // 最小テンポの基準範囲の最大値を、現在値の少し手前に設定
            dwBPM := Tempo.cBPM - 2;
            if dwCount1 > dwBPM then begin
                dwCount1 := dwBPM;
                if dwCount1 < 64 then dwCount1 := 64;
                cEnable := $35; // 5-8
            end;
        end;
    end;
    // 解析基準範囲内で出現回数が最も多いテンポを取得
    dwScan1 := 0;
    dwScan2 := 0;
    cBPM1 := dwCount1;
    cBPM2 := dwCount2;
    for I := dwCount1 to dwCount2 do begin
        dwCount3 := Tempo.Count[I];
        if dwScan2 < dwCount3 then begin
            dwScan1 := I;
            dwScan2 := dwCount3;
            Tempo.cMode := cEnable;
        end;
    end;
    // テンポの平均値を計算して中央値を補正
    dwScan2 := dwScan1;
    Dec(dwScan1, 5);
    Inc(dwScan2, 5);
    if dwScan1 < 60 then dwScan1 := 60;
    if dwScan2 > 200 then dwScan2 := 200;
    dwBPM := 0;
    dwCount1 := 0;
    for I := dwScan1 to dwScan2 do begin
        dwCount3 := Tempo.Count[I];
        Inc(dwBPM, longword(I + I) * dwCount3);
        Inc(dwCount1, dwCount3);
    end;
    if longbool(dwCount1) then begin
        dwBPM := dwBPM div dwCount1;
        dwBPM := (dwBPM shr 1) + (dwBPM and 1);
    end;
    // 三拍子・三連符を考慮して中央値を補正
    if (dwBPM >= 96) and ((dwBPM <= 128) or (dwBPM >= 176)) and (dwCount1 >= 16) then begin
        dwScan1 := ((dwBPM shl (1 + (longword(dwBPM <= 150) and 1))) * 21845) shr 16; // x2/3 or x4/3
        if longbool(Tempo.dwTripleTime) or ((dwScan1 >= Tempo.cMinBPM) and (dwScan1 <= Tempo.cMaxBPM)) then begin
            // 新しい中央値を計算
            dwScan2 := dwScan1;
            Dec(dwScan1, 5);
            Inc(dwScan2, 5);
            if dwScan1 < 60 then dwScan1 := 60;
            if dwScan2 > 200 then dwScan2 := 200;
            cValue := dwBPM; // バックアップ
            dwBPM := 0;
            dwCount2 := 0;
            for I := dwScan1 to dwScan2 do begin
                dwCount3 := Tempo.Count[I];
                Inc(dwBPM, longword(I + I) * dwCount3);
                Inc(dwCount2, dwCount3);
            end;
            // 三連符検出の重み基準値
            dwCount3 := 30;
            if longbool(Tempo.dwTripleTime) then dwCount3 := 10;
            if (dwCount2 >= dwCount3) and (dwCount2 >= (dwCount1 shr 3)) then begin
                dwBPM := dwBPM div dwCount2;
                dwBPM := (dwBPM shr 1) + (dwBPM and 1);
                dwCount1 := dwCount2 shl 2;
                Tempo.cMode := cEnable + 1;
                Tempo.dwTripleTime := 640000; // 10sec
            end else begin
                dwBPM := cValue; // 復元
            end;
        end;
    end;
    // テンポが推測できなかった場合 (初回のみ)
    if not bytebool(Tempo.cBPM) and not longbool(dwBPM) then begin
        if (cBPM2 - cBPM1) <= 20 then begin
            // テンポ解析範囲の誤差から推測
            dwBPM := (cBPM1 + cBPM2) shr 1;
            Tempo.cMode := cEnable + 2;
        end else begin
            // テンポ解析範囲の誤差が大きい場合、全範囲から推測
            dwScan2 := 0;
            for I := 60 to 200 do begin
                dwCount3 := Tempo.Count[I];
                if dwScan2 < dwCount3 then begin
                    dwScan2 := dwCount3;
                    dwBPM := I;
                    Tempo.cMode := cEnable + 3;
                end;
            end;
            if longbool(dwBPM) then begin
                if dwBPM <= 70 then cBPM1 := 60 else cBPM1 := dwBPM - 10;
                if dwBPM >= 190 then cBPM2 := 200 else cBPM2 := dwBPM + 10;
                Tempo.cMinBPM := cBPM1;
                Tempo.cMaxBPM := cBPM2;
            end;
        end;
    end;
    // テンポを推測済みで、解析開始から規定時間が経過した場合、解析結果をクリア
    dwCount2 := T64Count - Tempo.dwStartTime;
    if bytebool(Tempo.cBPM) and ((dwCount1 >= 600) or (dwCount2 >= 240000) // 3.75sec
            or (Tempo.cBPM < cBPM1) or (Tempo.cBPM > cBPM2)) then begin
        // KON カウントを学習
        if (Tempo.cBPM < cBPM1) or (Tempo.cBPM > cBPM2) then begin
            if longbool(dwBPM) and ((dwCount1 >= 30) or (dwCount2 >= 120000)) then Tempo.cBPM := dwBPM // 1.875sec
            else if not bytebool(Tempo.cKOnCountOld) then Tempo.cBPM := dwBPM;
            Tempo.cKOnCountOld := 0; // 学習リセット
        end else begin
            if longbool(dwBPM) and (dwCount1 >= 30) then Tempo.cBPM := dwBPM;
            Tempo.cKOnCountOld := Tempo.cKOnCount;
            if cEnable = $41 then Dec(Tempo.cKOnCountOld) else Inc(Tempo.cKOnCountOld);
        end;
        // 初期化
        Tempo.cKOnCount := 0;
        Tempo.dwStartTime := T64Count;
        if Tempo.dwTripleTime > dwCount2 then Dec(Tempo.dwTripleTime, dwCount2) else Tempo.dwTripleTime := 0;
        API_ZeroMemory(@Tempo.Count, SizeOf(Tempo.Count));
        // テンポの揺れを防止
        if (dwBPM >= Tempo.cMinBPM) and (dwBPM <= Tempo.cMaxBPM) then begin
            dwCount3 := Tempo.Count[dwBPM] shr 2;
            if T64Count < 720000 then dwCount3 := dwCount3 shr 1; // 11.25sec
            if not ((dwCount1 >= 60) or (dwCount2 >= 240000)) then dwCount3 := dwCount3 shr 1; // 3.75sec
            Tempo.Count[dwBPM] := dwCount3;
        end;
        exit;
    end;
    // 件数が基準値以上、または、規定時間経過後のテンポを推測値として記録
    if longbool(dwBPM) and ((dwCount1 >= 60) or (dwCount2 >= 240000)) then begin // 3.75sec
        Tempo.cBPM := dwBPM;
        // テンポの揺れを防止
        if (dwBPM >= Tempo.cMinBPM) and (dwBPM <= Tempo.cMaxBPM) then Inc(Tempo.Count[dwBPM], 2);
        exit;
    end;
end;

// ================================================================================
// SNESAPUCallback - SNESAPU コールバック
// ================================================================================
function _SNESAPUCallback(dwEffect: longword; dwAddr: longword; dwValue: longword; lpData: pointer): longword; stdcall;
begin
    result := dwValue;
    case dwEffect of
        CBE_DSPREG: begin
            if Option.bBPM then case dwAddr and $7F of
                $4C: AnalyzeTempo(dwValue);
                $5C: Status.Tempo.cKOn := Status.Tempo.cKOn and (dwValue xor $FF and $FF);
            end;
        end;
    end;
    if longbool(@Apu.SNESAPUCallbackProc) then begin
        result := Apu.SNESAPUCallbackProc(dwEffect, dwAddr, dwValue, lpData);
    end;
end;

// ================================================================================
// DSPDebug - DSP デバッグ
// ================================================================================
procedure _DSPDebug(); stdcall;
var
    dwAddr: longword;
    dwValue: longword;
begin
    asm
        Mov dwAddr,EBX
        Mov dwValue,EAX
    end;
    if Option.bBPM then case dwAddr and $7F of
        $4C: AnalyzeTempo(dwValue);
        $5C: Status.Tempo.cKOn := Status.Tempo.cKOn and (dwValue xor $FF and $FF);
    end;
    if longbool(@Apu.DSPDebug) then asm
        Mov EDX,Apu.DSPDebug;
        Mov EBX,dwAddr
        Mov EAX,dwValue
        Call EDX
    end;
end;

// ================================================================================
// Initialize - 初期化
// ================================================================================
function Initialize(hSNESAPU: longword): longint; stdcall;
begin
    // 初期化済みの場合は、終了
    if Status.bInitialized then begin
        result := 1;
        exit;
    end;
    // フラグ初期化
    Option.bBPM := false;
    // SNESAPU.DLL の API を取得
    result := -1;
    @Apu.GetAPUData := API_GetProcAddress(hSNESAPU, pchar('GetAPUData'));
    if not longbool(@Apu.GetAPUData) then exit;
    @Apu.SNESAPUCallback := API_GetProcAddress(hSNESAPU, pchar('SNESAPUCallback'));
    @Apu.SetDSPDbg := API_GetProcAddress(hSNESAPU, pchar('SetDSPDbg'));
    if not longbool(@Apu.SNESAPUCallback) and not longbool(@Apu.SetDSPDbg) then exit;
    // SNESAPU.DLL の情報を取得
    Apu.GetAPUData(NULLPOINTER, NULLPOINTER, NULLPOINTER, @Apu.T64Count, @Apu.DspReg, NULLPOINTER, NULLPOINTER, NULLPOINTER);
    // コールバックを追加設定
{$IFNDEF FORCEDSPDBG}
    if longbool(@Apu.SNESAPUCallback) then @Apu.SNESAPUCallbackProc := Apu.SNESAPUCallback(@_SNESAPUCallback, CBE_DSPREG)
    else
{$ENDIF}
    @Apu.DSPDebug := Apu.SetDSPDbg(@_DSPDebug);
    // 成功
    Status.bInitialized := true;
    result := 0;
end;

// ================================================================================
// Start - BPM 解析開始
// ================================================================================
function Start(lpReserved: pointer): longint; stdcall;
var
    dwAddress: pointer;
    T64Count: longword;
begin
    // 初期化されていない場合は、終了
    if not Status.bInitialized then begin
        result := -1;
        exit;
    end;
    // バッファをクリア
    API_ZeroMemory(@Status.Tempo, SizeOf(TTEMPO));
    // フラグを設定
    Option.bBPM := true;
    // 現在位置を取得
    T64Count := Apu.T64Count^;
    // 時間を初期化
    Status.Tempo.dwStartTime := T64Count;
    Status.Tempo.dwKOnTime := T64Count;
    Status.Tempo.dwMinTime := T64Count;
    Status.Tempo.dwMaxTime := T64Count;
    // 管理メモリを返却
    if longbool(lpReserved) then begin
        dwAddress := @Status.Tempo;
        API_MoveMemory(lpReserved, @dwAddress, 4);
    end;
    // 成功
    result := 0;
end;

// ================================================================================
// Stop - BPM 解析停止
// ================================================================================
function Stop(): longint; stdcall;
begin
    // 初期化されていない場合は、終了
    if not Status.bInitialized then begin
        result := -1;
        exit;
    end;
    // BPM 解析が開始されていない場合は、終了
    if not Option.bBPM then begin
        result := -2;
        exit;
    end;
    // フラグを設定
    Option.bBPM := false;
    // 成功
    result := 0;
end;

// ================================================================================
// GetBPM - BPM 取得
// ================================================================================
function GetBPM(lpReserved: pointer): longint; stdcall;
begin
    // 初期化されていない場合は、終了
    if not Status.bInitialized then begin
        result := -1;
        exit;
    end;
    // BPM 解析が開始されていない場合は、終了
    if not Option.bBPM then begin
        result := -2;
        exit;
    end;
    // BPM を返却
    result := Status.Tempo.cBPM;
end;


// *************************************************************************************************************************************************************
// エクスポート関数
// *************************************************************************************************************************************************************

exports
    Initialize,
    Start,
    Stop,
    GetBPM;

begin
    Status.bInitialized := false;
end.
