// *************************************************************************************************************************************************************
//   SNES SPC700 Player with Customized SNESAPU.DLL Version 2.XX Kernel Source Code
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
//  Copyright (C) 2003-2023 degrade-factory. All rights reserved.
//
// =================================================================================================
program spcplay;

//{$DEFINE TIMERTRICK}                                      // TimerTrick DEBUG
//{$DEFINE TRY700A}                                         // Try700 (Ansi) DEBUG
//{$DEFINE TRY700W}                                         // Try700 (Wide) DEBUG
//{$DEFINE TRANSMITSPC}                                     // TransmitSPC DEBUG
//{$DEFINE CONTEXT}                                         // SNESAPU Context DEBUG
//{$DEFINE SPCDEBUG}                                        // SNESAPU SPCDbg DEBUG
//{$DEFINE SPCCYCLE}                                        // SNESAPU Cycles DEBUG
//{$DEFINE DEBUGLOG}                                        // デバッグログ出力
//{$DEFINE UACDROP}                                         // UAC を超えたドロップ操作
//{$DEFINE ITASKBARLIST3}                                   // ITaskbarList3 対応
//{$DEFINE PERFORMANCETEST}                                 // パフォーマンステスト
//{$DEFINE SPCBPMTEST}                                      // SPC_BPM.DLL テスト

{$APPTYPE GUI}                                              // アプリケーションタイプ       : GUI モード
{$ASSERTIONS OFF}                                           // ソースコードのアサート       : 無効
{$BOOLEVAL OFF}                                             // 完全論理式評価               : 無効
{$DEBUGINFO OFF}                                            // デバッグ情報                 : 無効
{$DENYPACKAGEUNIT ON}                                       // UNIT 不使用                  : 有効
{$EXTENDEDSYNTAX ON}                                        // 関数の戻り値を無視可能       : 有効
{$EXTENSION 'exe'}                                          // 拡張子設定                   : EXE
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
{$R 'spcplay.res' 'spcplay.rc'}                             // リソース                     : spcplay.res <- spcplay.rc
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
    TSPCREG = record                                        // SPC700 レジスタ
        pc: word;                                               // PC レジスタ
        a: byte;                                                // A レジスタ
        x: byte;                                                // X レジスタ
        y: byte;                                                // Y レジスタ
        psw: byte;                                              // PSW レジスタ
        sp: byte;                                               // SP レジスタ
    end;

    // SPCHDR 構造体
    TSPCHDR = record
        FileHdr: array[0..32] of char;                      // ファイルヘッダ
        TagTarm: array[0..1] of byte;                       // ヘッダとタグの分離領域 (0x00, 0x1A)
        TagType: byte;                                      // タグの種類 (0x00 = 未定義, 0x1A = ID666, 0x1B = ID666 以外)
        Version: byte;                                      // SPC バージョン
        Reg: TSPCREG;                                       // SPC700 レジスタの初期値
        __r1: word;                                         // (未使用) = 0x00
        Title: array[0..31] of char;                        // 曲名
        Game: array[0..31] of char;                         // ゲーム名
        Dumper: array[0..15] of char;                       // SPC 製作者
        Comment: array[0..31] of char;                      // コメント
        Date: array[0..10] of char;                         // SPC 製作日
        SongLen: array[0..2] of char;                       // 演奏時間
        FadeLen: array[0..4] of char;                       // フェードアウト時間
        Artist: array[0..31] of char;                       // 作曲者
        ChDis: byte;                                        // チャンネルマスク初期状態
        Emulator: byte;                                     // 出力元エミュレータ
        __r2: array[0..35] of byte;                         // (未使用) = 0x00
        dwSongLen: longword;                                // (未使用) - 演奏時間
        dwFadeLen: longword;                                // (未使用) - フェードアウト時間
        TagFormat: byte;                                    // (未使用) - タグフォーマット
    end;

    // SPCHDRBIN 構造体
    TSPCHDRBIN = record
        __r1: array[0..157] of byte;                        // (予約) - SPCHDR
        DateDay: byte;                                      // SPC 製作日 (日)
        DateMonth: byte;                                    // SPC 製作日 (月)
        DateYear: word;                                     // SPC 製作日 (年)
        __r2: array[0..6] of byte;                          // (未使用) = 0x00
        SongLen: word;                                      // 演奏時間
        __r3: byte;                                         // (未使用) = 0x00
        FadeLen: longword;                                  // フェードアウト時間
        Artist: array[0..31] of char;                       // 作曲者
        ChDis: byte;                                        // チャンネルマスク初期状態
        Emulator: byte;                                     // 出力元エミュレータ
        __r4: byte;                                         // (未使用) = 0x00
        __r5: array[0..44] of byte;                         // (予約) - SPCHDR
    end;

    // SPC 構造体
    TSPC = record
        Hdr: TSPCHDR;                                       // SPC ファイルヘッダ
        Ram: array[0..65535] of byte;                       // SPC700 64KB RAM
        Dsp: array[0..127] of byte;                         // DSP レジスタ
        __r: array[0..63] of byte;                          // (未使用) = 0x00 or 拡張 RAM
        XRam: array[0..63] of byte;                         // SPC700 拡張 RAM
    end;

    // RAM 構造体
    TRAM = record case byte of
        1: (Ram: array[0..65535] of byte);                  // RAM
        2: (__r1: array[0..$F3] of byte;                    // (予約)
            dwPort: longword;                               // APU ポート (32 ビット)
            __r2: array[$F8..$FFFF] of byte);               // (予約)
    end;

    // XRAM 構造体
    TXRAM = record
        XRam: array[0..63] of byte;                         // XRAM
    end;

    // SPCPORT 構造体
    TSPCPORT = record case byte of
        1: (Port: array[0..3] of byte);                     // 各ポート
        2: (dwPort: longword);                              // ポート (32 ビット)
    end;

    // SPCSRCADDRS 構造体
    TSPCSRCADDRS = record
        Src: array[0..255] of record
            wStart: word;                                   // 開始アドレス
            wLoop: word;                                    // ループアドレス
        end;
    end;

    // SPC700REG 構造体
    TSPC700REG = record case byte of
        1: (psw: array[0..7] of longword;                   // PSW レジスタ (0x100 でマスク)
            pc: longword;                                   // PC レジスタ (下位 16 ビット)
            ya: longword;                                   // Y, A レジスタ (Y : 上位 8 ビット、 A : 下位 8 ビット)
            sp: longword;                                   // SP レジスタ (下位 8 ビット)
            x: longword);                                   // X レジスタ (下位 8 ビット)
        2: (Word: array[0..23] of word);
        3: (Byte: array[0..47] of byte);
    end;

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

    // VOICE 構造体
    TVOICE = record
        KOnADSR: word;                                      // KON 時の ADSR パラメータ
        KOnGain: byte;                                      // KON 時の Gain パラメータ
        ResetEnv: byte;                                     // KON 後の ADSR/Gain 変更フラグ
        CurrentSample: ^word;                               // カレントサンプルのポインタ
        CurrentBlock: pointer;                              // カレントブロックのポインタ
        BlockHdr: byte;                                     // カレントブロックのヘッダ
        MixFlag: byte;                                      // ミキシングオプション (下位 2 ビットでミュート・強制ノイズ設定、上位 6 ビットは予約)
        EnvelopeCurrentMode: byte;                          // エンベロープの動作モード
        EnvelopeRateTab: byte;                              // エンベロープレートタブのインデックス
        EnvelopeRate: longword;                             // エンベロープレートの調整
        SampleCounter: longword;                            // サンプルカウンタ
        EnvelopeRateValue: longword;                        // 現在のエンベロープ値
        EnvelopeAdjust: longword;                           // エンベロープの高さ
        EnvelopeDestination: longword;                      // エンベロープの最終値
        VolumeMaxLeft: single;                              // 最大出力レベル (左)
        VolumeMaxRight: single;                             // 最大出力レベル (右)
        LastSample1: word;                                  // 最後のサンプル 1
        LastSample2: word;                                  // 最後のサンプル 2
        LastSampleBlock: array[0..7] of word;               // 最後のサンプル x8 (補間処理で使用)
        Buffer: array[0..15] of word;                       // 32 バイトデータ (サンプルブロック解凍で使用)
        TargetVolumeLeft: single;                           // 最終的なチャンネル音量 (左)
        TargetVolumeRight: single;                          // 最終的なチャンネル音量 (右)
        ChannelVolumeLeft: longword;                        // 現在のチャンネル音量 (左) (クリックノイズ防止機能で使用)
        ChannelVolumeRight: longword;                       // 現在のチャンネル音量 (右) (クリックノイズ防止機能で使用)
        PitchRate: longword;                                // モジュレーション後のピッチレート
        PitchRateDecimal: word;                             // モジュレーション後のピッチレート (小数)
        CurrentSource: byte;                                // カレント音色番号
        StartDelay: byte;                                   // KON から発音までの遅延時間 (64kHz)
        PitchRateDSP: longword;                             // DSP でコンバートされたオリジナルピッチレート
        SampleOutput: longword;                             // チャンネル音量に依存しない最後のサンプル (ピッチモジュレーションで使用)
    end;

    // VOICES 構造体
    TVOICES = record
        Voice: array[0..7] of TVOICE;                       // DSP ボイスレジスタ
    end;
{$ALIGN ON}  // 構造体の自動サイズ調整なし --- ここまで

    // APU 構造体
    TAPU = record
        hSNESAPU: longword;                                 // SNESAPU.DLL ハンドル
        Ram: ^TRAM;                                         // SPC700 RAM のポインタ (65536 バイト)
        XRam: ^TXRAM;                                       // SPC700 拡張 RAM のポインタ (64 バイト)
        SPCOutPort: ^TSPCPORT;                              // SPC700 出力ポートのポインタ
        T64Count: ^longword;                                // 64kHz タイマカウンタのポインタ (64000 count/sec)
        DspReg: ^TDSPREG;                                   // DSP レジスタのポインタ (128 バイト)
        Voices: ^TVOICES;                                   // DSP ミキシングデータのポインタ (TVOICE x8)
        VolumeMaxLeft: ^single;                             // ミキシング最大出力レベル (左) のポインタ
        VolumeMaxRight: ^single;                            // ミキシング最大出力レベル (右) のポインタ
        SPC700Reg: ^TSPC700REG;                             // SPC700 レジスタのポインタ
        EmuAPU: function(buffer: pointer; length: longword; ltype: byte): pointer; stdcall;
        GetAPUData: procedure(ppRam: pointer; ppXRam: pointer; ppSPCOutput: pointer; ppT64Count: pointer; ppDsp: pointer; ppVoices: pointer;
            ppVolumeMaxLeft: pointer; ppVolumeMaxRight: pointer); stdcall;
        GetScript700Data: procedure(pVer: pointer; ppSPCReg: pointer; ppScript700: pointer); stdcall;
        GetSPCRegs: procedure(pPC: pointer; pA: pointer; pY: pointer; pX: pointer; pPSW: pointer; pSP: pointer); stdcall;
        InPort: procedure(port: byte; val: byte); stdcall;
        LoadSPCFile: procedure(pSPCFile: pointer); stdcall;
        ResetAPU: procedure(amp: longword); stdcall;
        SeekAPU: procedure(time: longword; fast: byte); stdcall;
        SetAPULength: function(time: longword; fade: longword): longword; stdcall;
        SetAPUOption: procedure(mix: longword; ch: longword; bit: longword; rate: longword; inter: longword; opt: longword); stdcall;
        SetAPURAM: procedure(addr: longword; val: byte); stdcall;
        SetAPUSpeed: procedure(speed: longword); stdcall;
        SetDSPAmp: procedure(amp: longword); stdcall;
        SetDSPFeedback: procedure(leak: longint); stdcall;
        SetDSPPitch: procedure(base: longword); stdcall;
        SetDSPReg: function(addr: byte; val: byte): byte; stdcall;
        SetDSPStereo: procedure(sep: longword); stdcall;
        SetScript700: function(pSource: pointer): longword; stdcall;
        SetScript700Data: function(addr: longword; pData: pointer; size: longword): longword; stdcall;
        SetSPCDbg: function(pTrace: pointer; opts: longword): pointer; stdcall;
        SNESAPUCallback: function(pCbFunc: pointer; cbMask: longword): pointer; stdcall;
        SNESAPUInfo: procedure(pVer: pointer; pMin: pointer; pOpt: pointer); stdcall;
{$IFDEF TIMERTRICK}
        SetTimerTrick: procedure(Port: longword; Wait: longword); stdcall;
{$ENDIF}
{$IFDEF TRY700A}
        Try700: function(lpFile: pointer): longint; stdcall;
{$ENDIF}
{$IFDEF TRY700W}
        Try700: function(lpFile: pointer): longint; stdcall;
{$ENDIF}
{$IFDEF TRANSMITSPC}
        TransmitSPC: function(addr: longword): longword; stdcall;
        TransmitSPCEx: function(table: pointer): longword; stdcall;
        StopTransmitSPC: function(): longword; stdcall;
        WriteIO: function(addr: longword; data: longword): longword; stdcall;
{$ENDIF}
{$IFDEF CONTEXT}
        GetSNESAPUContextSize: function(): longword; stdcall;
        GetSNESAPUContext: function(lpContext: pointer): longword; stdcall;
        SetSNESAPUContext: function(lpContext: pointer): longword; stdcall;
{$ENDIF}
{$IFDEF SPCDEBUG}
        SetDSPDbg: function(pTrace: pointer): pointer; stdcall;
{$ENDIF}
{$IFDEF SPCBPMTEST}
        hSPCBPM: longword;                                  // SPC_BPM.DLL ハンドル
        BPMInitialize: function(hSNESAPU: longword): longint; stdcall;
        BPMStart: function(lpReserved: pointer): longint; stdcall;
        BPMStop: function(): longint; stdcall;
        BPMGetBPM: function(): longint; stdcall;
{$ENDIF}
    end;

    // SCRIPT700 構造体
    TSCRIPT700 = record
        dwWork: array[0..7] of longword;                    // ユーザワークエリア
        dwCmpParam: array[0..1] of longword;                // 比較用パラメータエリア
        dwWaitCnt: longword;                                // ウェイトカウント
        dwPointer: longword;                                // プログラムポインタ
        cStatusFlag: byte;                                  // ステータスフラグ
        __reserved: byte;                                   // (予約)
        dwIntInPort: byte;                                  // 入力ポート監視ウェイト
        dwIntOutPort: byte;                                 // 出力ポート監視ウェイト
        dwData: longword;                                   // データエリアのオフセットアドレス
        dwStack: longword;                                  // スタックポインタ
    end;

    // SCRIPT700DATA 構造体
    TSCRIPT700DATA = record
        Data: ^TSCRIPT700;                                  // データ
        dwProgSize: longword;                               // プログラムサイズ
    end;

    // SCRIPT700EX 構造体
    TSCRIPT700EX = record
        Base: TSCRIPT700;                                   // 基本データ
        dwJump: longword;                                   // ジャンプ先アドレス
        dwTemp: longword;                                   // 一時格納用
        Stack: array[0..127] of longword;                   // スタックメモリ
    end;

    // APUDATA 構造体
    TAPUDATA = record
        SPCApuPort: TSPCPORT;                               // SPC700 入力ポート
        SPCOutPort: TSPCPORT;                               // SPC700 出力ポート
        SPCSrcAddrs: TSPCSRCADDRS;                          // SPC700 音色アドレス
        SPC700Reg: TSPC700REG;                              // SPC700 レジスタ
        T64Count: longword;                                 // 64kHz タイマカウンタ
        DspReg: TDSPREG;                                    // DSP レジスタ
        Voices: TVOICES;                                    // DSP ミキシングデータ
        VolumeMaxLeft: single;                              // ミキシング最大出力レベル (左)
        VolumeMaxRight: single;                             // ミキシング最大出力レベル (右)
        Script700: TSCRIPT700;                              // Script700 データ
    end;

    // SPCCACHE 構造体
    TSPCCACHE = record
        Spc: TSPC;                                          // SPC ファイルバッファ
        Script700: TSCRIPT700EX;                            // Script700 完全バッファ
        SPCOutPort: TSPCPORT;                               // SPC700 出力ポート
    end;

    // LEVEL 構造体
    TLEVEL = record
        cMasterVolumeLeft: byte;                            // マスター音量 (左)
        cMasterVolumeRight: byte;                           // マスター音量 (右)
        cMasterEchoLeft: byte;                              // マスターエコー (左)
        cMasterEchoRight: byte;                             // マスターエコー (右)
        cMasterDelay: byte;                                 // マスターディレイ
        cMasterFeedback: byte;                              // マスターフィードバック
        cMasterLevelLeft: byte;                             // マスター出力レベル (左)
        cMasterLevelRight: byte;                            // マスター出力レベル (右)
        Channel: array[0..7] of record                      // チャンネル
            bChannelShow: bytebool;                             // チャンネル表示
            cChannelVolumeLeft: byte;                           // チャンネル音量 (左)
            cChannelVolumeRight: byte;                          // チャンネル音量 (右)
            cChannelPitch: byte;                                // チャンネルピッチ
            cChannelEnvelope: byte;                             // チャンネルエンベロープ
            cChannelLevelLeft: byte;                            // チャンネル出力レベル (左)
            cChannelLevelRight: byte;                           // チャンネル出力レベル (右)
            __r: byte;                                          // (未使用)
            dwChannelEffect: record case byte of                // チャンネルエフェクト
                1: (EchoOn: bytebool;                               // エコーフラグ
                    PitchModOn: bytebool;                           // ピッチモジュレーションフラグ
                    NoiseOn: bytebool;                              // ノイズフラグ
                    Update: bytebool);                              // 更新フラグ
                2: (dwValue: longword);                             // フラグ (32 ビット)
            end;
        end;
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

    // STRDATA 構造体
    TSTRDATA = record case byte of
        1: (cData: array[0..7] of char);                    // 1 文字 x8
        2: (bData: array[0..7] of byte);                    // 8 ビット x8
        3: (wData: array[0..3] of word);                    // 16 ビット x4
        4: (dwData: array[0..1] of longword);               // 32 ビット x2
        5: (qwData: int64);                                 // 64 ビット
    end;

    // CRITICALSECTION 構造体
    TCRITICALSECTION = record
        lpDebugInfo: pointer;                               // デバッグ情報のポインタ
        dwLockCount: longword;                              // ロック回数
        dwRecursionCount: longword;                         // 再帰回数
        hOwningThread: longword;                            // スレッドハンドル
        hLockSemaphore: longword;                           // ロック信号ハンドル
        dwSpinCount: longword;                              // 待機回数
    end;

    // DBLPOINTER 構造体
    TDBLPOINTER = record
        p: pointer;                                         // ポインタ
    end;

    // GUID 構造体
    TGUID = record case byte of
        1: (Data1: longword;                                // 1
            Data2: word;                                    // 2
            Data3: word;                                    // 3
            Data4: array[0..7] of byte);                    // 4
        2: (DataX: array[0..3] of longword);                // 値 (128 ビット)
    end;

    // LONGLONG 構造体
    TLONGLONG = record
        l: longword;                                        // 下位 32 ビット
        h: longword;                                        // 上位 32 ビット
    end;

    // POINT 構造体
    TPOINT = record
        x: longint;                                         // X 座標
        y: longint;                                         // Y 座標
    end;

    // RECT 構造体
    TRECT = record
        left: longint;                                      // 左
        top: longint;                                       // 上
        right: longint;                                     // 右
        bottom: longint;                                    // 下
    end;

    // BOX 構造体
    TBOX = record
        left: longint;                                      // 左
        top: longint;                                       // 上
        width: longint;                                     // 幅
        height: longint;                                    // 高さ
    end;

    // KEYSTATE 構造体
    TKEYSTATE = record
        k: array[0..255] of byte;                           // キーの状態
    end;

    // MONITORINFO 構造体
    TMONITORINFO = record
        cdSize: longword;                                   // 構造体のサイズ
        rcMonitor: TRECT;                                   // モニタ全体のサイズ
        rcWork: TRECT;                                      // 作業領域のサイズ
        dwFlags: longword;                                  // フラグ
    end;

    // MSG 構造体
    TMSG = record
        hWnd: longword;                                     // ウィンドウハンドル
        msg: longword;                                      // メッセージ
        wParam: longword;                                   // メッセージ追加情報 1
        lParam: longword;                                   // メッセージ追加情報 2
        dwTime: longword;                                   // メッセージ送信時間
        pt: TPOINT;                                         // メッセージ発生座標 (POINT 構造体)
    end;

    // OPENFILENAME 構造体
    TOPENFILENAME = record
        lStructSize: longword;                              // 構造体のサイズ
        hwndOwner: longword;                                // ウィンドウハンドル
        hThisInstance: longword;                            // インスタンスハンドル
        lpstrFilter: pointer;                               // フィルタ
        lpstrCustomFilter: pointer;                         // カスタムフィルタ
        nMaxCustFilter: longword;                           // フィルタの最大値
        nFilterIndex: longword;                             // フィルタの選択値
        lpstrFile: pointer;                                 // ファイル名
        nMaxFile: longword;                                 // 最大ファイル
        lpstrFileTitle: pointer;                            // ファイルタイトル
        nMaxFileTitle: longword;                            // 最大ファイルタイトル
        lpstrInitialDir: pointer;                           // 初期フォルダ
        lpstrTitle: pointer;                                // タイトル
        Flags: longword;                                    // フラグ
        nFileOffset: word;                                  // ファイルオフセット
        nFileExtension: word;                               // ファイル拡張
        lpstrDefExt: pointer;                               // デフォルト拡張
        lCustData: longword;                                // カスタムデータ
        lpfnHook: pointer;                                  // フック
        lpTemplateName: pointer;                            // テンプレート名
    end;

    // OSVERSIONINFO 構造体
    TOSVERSIONINFO = record
        dwOSVersionInfoSize: longword;                      // 構造体のサイズ
        dwMajorVersion: longword;                           // メジャーバージョン
        dwMinorVersion: longword;                           // マイナーバージョン
        dwBuildNumber: longword;                            // ビルドナンバー
        dwPlatformId: longword;                             // プラットフォーム ID
        szCSDVersion: array[0..127] of char;                // 追加情報
    end;

    // REFCOLOR 構造体
    TREFCOLOR = record case byte of
        1: (r: byte;                                        // 赤
            g: byte;                                        // 緑
            b: byte;                                        // 青
            a: byte);                                       // アルファ
        2: (dwColor: longword);                             // 色番号
    end;

    // WAVEFORMATEXTENSIBLE 構造体
    TWAVEFORMATEXTENSIBLE = record
        wFormatTag: word;                                   // フォーマットタグ
        nChannels: word;                                    // チャンネル
        nSamplesPerSec: longword;                           // サンプリングレート
        nAvgBytesPerSec: longword;                          // 1 秒あたりのバイト数
        nBlockAlign: word;                                  // ブロック単位のバイト数
        wBitsPerSample: word;                               // 1 サンプルあたりのビット数
        cbSize: word;                                       // 追加情報のサイズ
        wValidBitsPerSample: word;                          // 1 サンプルあたりのビット数
        dwChannelMask: longword;                            // チャンネルマスク
        SubFormat: TGUID;                                   // サブフォーマット
    end;

    // WAVEHDR 構造体
    TWAVEHDR = record
        lpData: pointer;                                    // バッファのポインタ
        dwBufferLength: longword;                           // バッファのサイズ
        dwBytesRecorded: longword;                          // 録音済みのサイズ
        dwUser: longword;                                   // ユーザデータ
        dwFlags: longword;                                  // フラグ
        dwLoops: longword;                                  // ループ回数
        __lpNext: pointer;                                  // (予約)
        __reserved: longword;                               // (予約)
    end;

    // WAVEOUTCAPS 構造体
    TWAVEOUTCAPS = record
        wMid: word;                                         // 製造元番号
        wPid: word;                                         // 製品番号
        vDriverVersion: record                              // バージョン
            wMinor: byte;                                       // マイナーバージョン
            wMajor: byte;                                       // メジャーバージョン
            __r: word;                                          // (予約)
        end;
        szPname: array[0..31] of char;                      // デバイス名
        dwFormats: longword;                                // サポートされているフォーマット
        wChannels: word;                                    // サポートされているチャンネル
        __wReserved1: word;                                 // (予約)
        dwSupport: longword;                                // サポートされているコントロール
    end;

    // WIN32FINDDATA 構造体
    TWIN32FINDDATA = record
        dwFileAttributes: longword;                         // 属性
        ftCreateTime: TLONGLONG;                            // 作成日時
        ftLastAccessTime: TLONGLONG;                        // 最終アクセス日時
        ftLastWriteTime: TLONGLONG;                         // 最終更新日時
        dwFileSizeHigh: longword;                           // ファイルサイズ (上位)
        dwFileSizeLow: longword;                            // ファイルサイズ (下位)
        dwReserved0: longword;                              // (予約)
        dwReserved1: longword;                              // (予約)
        cFileName: array[0..259] of char;                   // 長いファイル名
        cAlternateFileName: array[0..13] of char;           // 短いファイル名
    end;

    // WINDOWPLACEMENT 構造体
    TWINDOWPLACEMENT = record
        length: longword;                                   // 構造体サイズ
        flags: longword;                                    // フラグ
        showCmd: longword;                                  // 表示スタイル
        ptMinPosition: TPOINT;                              // 最小化座標
        ptMaxPosition: TPOINT;                              // 最大化座標
        rcNormalPosition: TRECT;                            // 通常座標
    end;

    // WNDCLASSEX 構造体
    TWNDCLASSEX = record
        cdSize: longword;                                   // 構造体サイズ
        style: longword;                                    // クラススタイル
        lpfnwndproc: pointer;                               // WindowProc 関数のポインタ
        cbClsextra: longint;                                // ウィンドウクラス初期化
        cbWndExtra: longint;                                // ウィンドウインスタンス初期化
        hThisInstance: longword;                            // インスタンスハンドル
        hIcon: longword;                                    // 32x32 アイコンハンドル
        hCursor: longword;                                  // カーソルハンドル
        hbrBackground: longword;                            // 背景色ハンドル (+1)
        lpszMenuName: pointer;                              // デフォルトメニューのポインタ
        lpszClassName: pointer;                             // クラス名のポインタ
        hIconSm: longword;                                  // 16x16 アイコンハンドル
    end;

    // DROPFILES 構造体
    TDROPFILES = record
        pFiles: longword;                                   // ファイル一覧の開始インデックス
        pt: TPOINT;                                         // マウス座標
        fNC: longbool;                                      // 非クライアント領域フラグ
        fWide: longbool;                                    // UNICODE (Win9x: false, WinNT: true 必須)
    end;

    // FORMATETC 構造体
    TFORMATETC = record
        cfFormat: word;                                     // クリップボードフォーマット形式
        ptd: pointer;                                       // 対象デバイス情報
        dwAspect: longword;                                 // 表示に含まれる必要がある詳細情報
        lindex: longint;                                    // データがページ境界を越えて分割される必要がある場合の特性
        tymed: longword;                                    // データ転送に使用するストレージの種類
    end;

    // STGMEDIUM 構造体
    TSTGMEDIUM = record
        tymed: longword;                                    // データ転送に使用するストレージの種類
        handle: longword;                                   // データのハンドル
        pUnkForRelease: pointer;                            // ストレージ解放時にコールするインターフェイスのポインタ
    end;

    // DROPOBJECT 構造体
    TDROPOBJECT = record
        FormatEtc: ^TFORMATETC;                             // FORMATETC 構造体
        StgMedium: ^TSTGMEDIUM;                             // STGMEDIUM 構造体
        fRelease: longbool;                                 // データ複製フラグ
    end;

    // IDROPSOURCEVTBL 構造体
    TIDROPSOURCEVTBL = record
        OLEIDropSourceQueryInterface: pointer;              // IDropSource::QueryInterface 関数のポインタ
        OLEIDropSourceAddRef: pointer;                      // IDropSource::AddRef 関数のポインタ
        OLEIDropSourceRelease: pointer;                     // IDropSource::Release 関数のポインタ
        OLEIDropSourceQueryContinueDrag: pointer;           // IDropSource::QueryContinueDrag 関数のポインタ
        OLEIDropSourceGiveFeedback: pointer;                // IDropSource::GiveFeedback 関数のポインタ
    end;

    // IDROPSOURCE 構造体
    TIDROPSOURCE = record
        lpVtbl: pointer;                                    // インターフェイスのポインタ
        dwRefCnt: longword;                                 // 参照カウント
    end;

    // IDATAOBJECTVTBL 構造体
    TIDATAOBJECTVTBL = record
        OLEIDataObjectQueryInterface: pointer;              // IDataObject::QueryInterface 関数のポインタ
        OLEIDataObjectAddRef: pointer;                      // IDataObject::AddRef 関数のポインタ
        OLEIDataObjectRelease: pointer;                     // IDataObject::Release 関数のポインタ
        OLEIDataObjectGetData: pointer;                     // IDataObject::GetData 関数のポインタ
        OLEIDataObjectGetDataHere: pointer;                 // IDataObject::GetDataHere 関数のポインタ
        OLEIDataObjectQueryGetData: pointer;                // IDataObject::QueryGetData 関数のポインタ
        OLEIDataObjectGetCanonicalFormatEtc: pointer;       // IDataObject::GetCanonicalFormatEtc 関数のポインタ
        OLEIDataObjectSetData: pointer;                     // IDataObject::SetData 関数のポインタ
        OLEIDataObjectEnumFormatEtc: pointer;               // IDataObject::EnumFormatEtc 関数のポインタ
        OLEIDataObjectDAdvise: pointer;                     // IDataObject::DAdvise 関数のポインタ
        OLEIDataObjectDUnadvise: pointer;                   // IDataObject::DUnadvise 関数のポインタ
        OLEIDataObjectEnumDAdvise: pointer;                 // IDataObject::EnumDAdvise 関数のポインタ
    end;

    // IDATAOBJECT 構造体
    TIDATAOBJECT = record
        lpVtbl: pointer;                                    // インターフェイスのポインタ
        dwRefCnt: longword;                                 // 参照カウント
        dwObjectCnt: longword;                              // データオブジェクト数
        Objects: array[0..15] of TDROPOBJECT;               // データオブジェクト情報
    end;

    // POWERBROADCAST_SETTING 構造体
    TPOWERBROADCAST_SETTING = record
        PowerSetting: TGUID;                                // 電源設定
        dwDataLength: longword;                             // データの長さ
        Data: array of byte;                                // データ
    end;

    // DRAWITEMSTRUCT 構造体
    TDRAWITEMSTRUCT = record
        ctlType: longword;                                  // コントロールの型
        ctlID: longword;                                    // コントロールの識別子
        itemID: longword;                                   // メニュー項目の識別子
        itemAction: longword;                               // 描画アクション
        itemState: longword;                                // 描画アクションが実行された後の表示状態
        hwndItem: longword;                                 // ウィンドウハンドル、メニューハンドル
        hDC: longword;                                      // デバイスコンテキストのハンドル
        rcItem: TRECT;                                      // コントロールの境界
        itemData: pointer;                                  // アプリケーション定義の値
    end;

    // MENUBARINFO 構造体
    TMENUBARINFO = record
        cbSize: longword;                                   // 構造体のサイズ
        rcBar: TRECT;                                       // メニューバーのサイズ
        hMenu: longword;                                    // メニューハンドル
        hwndMenu: longword;                                 // ウィンドウハンドル
        dwFlags: longword;                                  // フラグ
    end;

    // MENUITEMINFO 構造体
    TMENUITEMINFO = record
        cbSize: longword;                                   // 構造体のサイズ
        fMask: longword;                                    // メンバーフラグ
        fType: longword;                                    // メニュー項目の種類
        fState: longword;                                   // メニュー項目の状態
        wID: longword;                                      // メニュー項目の識別ID
        hSubMenu: longword;                                 // サブメニューハンドル
        hbmpChecked: longword;                              // 選択時のビットマップハンドル
        hbmpUnchecked: longword;                            // 非選択時のビットマップハンドル
        dwItemData: pointer;                                // アプリケーション定義の値
        dwTypeData: pointer;                                // メニュー項目の内容
        cch: longword;                                      // メニュー項目のテキストの長さ (文字単位)
        hbmpItem: longword;                                 // ビットマップハンドル
    end;

    // UAHMENU 構造体
    TUAHMENU = record
        hMenu: longword;                                    // メニューハンドル
        hDC: longword;                                      // デバイスコンテキストのハンドル
        dwFlags: longword;                                  // フラグ
    end;

    // UAHMENUITEMMETRICS 構造体
    TUAHMENUITEMMETRICS = record
        Rect1: TRECT;
        Rect2: TRECT;
        Rect3: TRECT;
    end;

    // UAHMENUPOPUPMETRICS 構造体
    TUAHMENUPOPUPMETRICS = record
        rgcx: array[0..3] of longword;
        fUpdateMaxWidths: longword;
    end;

    // UAHMENUITEM 構造体
    TUAHMENUITEM = record
        nPosition: longint;                                 // メニュー位置
        Item: TUAHMENUITEMMETRICS;                          // メニュー情報
        Popup: TUAHMENUPOPUPMETRICS;                        // ポップアップメニュー情報
    end;

    // UAHDRAWMENUITEM 構造体
    TUAHDRAWMENUITEM = record
        Struct: TDRAWITEMSTRUCT;                            // 描画情報
        Menu: TUAHMENU;                                     // メニュー情報
        MenuItem: TUAHMENUITEM;                             // メニューアイテム情報
    end;

    // DTTOPTS 構造体
    TDTTOPTS = record
        cbSize: longword;                                   // 構造体のサイズ
        dwFlags: longword;                                  // フラグ
        crText: longword;                                   // テキストの色
        crBorder: longword;                                 // 枠線の色
        crShadow: longword;                                 // 影の色
        iTextShadowType: longint;                           // 影の種類
        ptShadowOffset: TPOINT;                             // 影とテキストのオフセット
        iBorderSize: longint;                               // アウトラインの半径
        iFontPropId: longint;                               // 代替フォント
        iColorPropId: longint;                              // 代替色
        iStateId: longint;                                  // 代替状態
        fApplyOverlay: longbool;                            // 影とアウトライン効果の上にテキストを描画
        iGlowSize: longint;                                 // 光彩のサイズ
        pfnDrawTextCallback: pointer;                       // コールバック関数のポインタ
        lParam: longword;                                   // コールバック関数のパラメータ
    end;

{$IFDEF TRANSMITSPC}
    // TRANSFERSPCEX 構造体
    TTRANSFERSPCEX = record
        cbSize: longword;                                   // 構造体のサイズ
        transmitType: longword;                             // 送信種別
        bScript700: longbool;                               // Script700 使用フラグ
        lptPort: longword;                                  // LPT ポートアドレス
    end;
{$ENDIF}

{$IFDEF ITASKBARLIST3}
    // ITASKBARLIST3VTBL 構造体
    TITASKBARLIST3VTBL = record
        COMITaskbarListQueryInterface: function(lpTaskbarList: pointer; priid: pointer; lplpDropSource: pointer): longword; stdcall;
        COMITaskbarListAddRef: function(lpTaskbarList: pointer): longword; stdcall;
        COMITaskbarListRelease: function(lpTaskbarList: pointer): longword; stdcall;
        COMITaskbarListHrInit: procedure(lpTaskbarList: pointer); stdcall;
        COMITaskbarListAddTab: procedure(lpTaskbarList: pointer; hWnd: longword); stdcall;
        COMITaskbarListDeleteTab: procedure(lpTaskbarList: pointer; hWnd: longword); stdcall;
        COMITaskbarListActiveTab: procedure(lpTaskbarList: pointer; hWnd: longword); stdcall;
        COMITaskbarListSetActiveAlt: procedure(lpTaskbarList: pointer; hWnd: longword); stdcall;
        COMITaskbarList2MarkFullscreenWindow: procedure(lpTaskbarList: pointer; hWnd: longword; fFullscreen: longbool); stdcall;
        COMITaskbarList3SetProgressValue: procedure(lpTaskbarList: pointer; hWnd: longword; ullCompleted: int64; ullTotal: int64); stdcall;
        COMITaskbarList3SetProgressState: procedure(lpTaskbarList: pointer; hWnd: longword; tbpFlags: longword); stdcall;
        COMITaskbarList3RegisterTab: procedure(lpTaskbarList: pointer; hWndTab: longword; hWndMDI: longword); stdcall;
        COMITaskbarList3UnregisterTab: procedure(lpTaskbarList: pointer; hWndTab: longword); stdcall;
        COMITaskbarList3SetTabOrder: procedure(lpTaskbarList: pointer; hWndTab: longword; hWndInsertBefore: longword); stdcall;
        COMITaskbarList3SetTabActive: procedure(lpTaskbarList: pointer; hWndTab: longword; hWndMDI: longword; tbatFlags: longword); stdcall;
        COMITaskbarList3ThumbBarAddButtons: procedure(lpTaskbarList: pointer; hWnd: longword; cButtons: longword; pButton: pointer); stdcall;
        COMITaskbarList3ThumbBarUpdateButtons: procedure(lpTaskbarList: pointer; hWnd: longword; cButtons: longword; pButton: pointer); stdcall;
        COMITaskbarList3ThumbBarSetImageList: procedure(lpTaskbarList: pointer; hWnd: longword; himl: longword); stdcall;
        COMITaskbarList3SetOverlayIcon: procedure(lpTaskbarList: pointer; hWnd: longword; hIcon: longword; pszDescription: pointer); stdcall;
        COMITaskbarList3SetThumbnailTooltip: procedure(lpTaskbarList: pointer; hWnd: longword; pszTip: pointer); stdcall;
        COMITaskbarList3SetThumbnailClip: procedure(lpTaskbarList: pointer; hWnd: longword; prcClip: longword); stdcall;
    end;

    // ITASKBARLIST3 構造体
    TITASKBARLIST3 = record
        lpVtbl: pointer;                                    // インターフェイスのポインタ
    end;
{$ENDIF}

    // CLASS クラス
    CCLASS = class
    private
    public
        procedure CreateClass(lpWindowProc: pointer; hThisInstance: longword; lpClassName: pointer; dwStyle: longword; lpIcon: pointer;
            lpSmallIcon: pointer; hCursor: longword; hbrBackground: longword);
        procedure DeleteClass(hThisInstance: longword; lpClassName: pointer);
    end;

    // FONT クラス
    CFONT = class
    private
    public
        hFont: longword;                                    // フォントハンドル
        procedure CreateFont(lpFontName: pointer; nHeight: longint; nWidth: longint; bBold: longbool; bItalic: longbool; bUnderLine: longbool;
            bStrike: longbool);
        procedure DeleteFont();
    end;

    // MENU クラス
    CMENU = class
    private
    public
        hMenu: longword;                                    // メニューハンドル
        procedure AppendMenu(dwID: longword; lpString: pointer); overload;
        procedure AppendMenu(dwID: longword; lpString: pointer; bRadio: longbool); overload;
        procedure AppendMenu(dwID: longword; lpString: pointer; hSubMenuID: longword); overload;
        procedure AppendSeparator();
        procedure CreateMenu();
        procedure CreatePopupMenu();
        procedure DeleteMenu();
        procedure InsertMenu(dwID: longword; dwAfterId: longword; lpString: pointer); overload;
        procedure InsertMenu(dwID: longword; dwAfterId: longword; lpString: pointer; bRadio: longbool); overload;
        procedure InsertMenu(dwID: longword; dwAfterId: longword; lpString: pointer; hSubMenuID: longword); overload;
        procedure InsertSeparator(dwId: longword);
        procedure RemoveItem(dwId: longword);
        procedure SetMenuCheck(dwID: longword; bCheck: longbool);
        procedure SetMenuEnable(dwID: longword; bEnable: longbool);
    end;

    // MENUBAR クラス
    CMENUBAR = class(CMENU)
    private
    public
        function  DrawMenuBar(hWnd: longword; lParam: longword): longword;
        procedure DrawMenuBorder(hWnd: longword);
        function  DrawMenuItem(hWnd: longword; lParam: longword): longword;
    end;

    // WINDOW クラス
    CWINDOW = class
    private
    public
        hWnd: longword;                                     // ウィンドウハンドル
        bMessageBox: longbool;                              // メッセージボックスフラグ
        procedure CreateItem(hThisInstance: longword; hMainWnd: longword; hFont: longword; lpItemName: pointer; lpCaption: pointer; dwItemID: longword;
            dwStylePlus: longword; dwStyleExPlus: longword; Box: TBOX);
        procedure CreateWindow(hThisInstance: longword; lpClassName: pointer; lpWndName: pointer; dwStylePlus: longword; dwStyleExPlus: longword; Box: TBOX);
        procedure DeleteWindow();
        function  GetCaption(lpCaption: pointer; nMaxCount: longint): longint;
        function  GetSystemMenu(): CMENU;
        function  GetWindowRect(lpRect: pointer): longbool;
        function  GetWindowStyle(): longword;
        function  GetWindowStyleEx(): longword;
        function  Invalidate(): longbool;
        function  MessageBox(lpText: pointer; lpCaption: pointer; uType: longword): longint;
        function  PostMessage(msg: longword; wParam: longword; lParam: longword): longbool;
        function  SendMessage(msg: longword; wParam: longword; lParam: longword): longword;
        procedure SetCaption(lpCaption: pointer);
        procedure SetWindowEnable(bEnable: longbool);
        procedure SetWindowPosition(nLeft: longint; nTop: longint; nWidth: longint; nHeight: longint);
        procedure SetWindowShowStyle(nCmdShow: longint);
        procedure SetWindowTopMost(bTopMost: longbool);
        procedure UpdateWindow(bVisible: longbool);
    end;

    // BUTTON クラス
    CBUTTON = class(CWINDOW)
    private
    public
        procedure CreateItem(hThisInstance: longword; hMainWnd: longword; hFont: longword; lpItemName: pointer; lpCaption: pointer; dwItemID: longword;
            dwStylePlus: longword; Box: TBOX);
        function  DrawItem(lParam: longword; bHighlight: longbool): longword;
    end;

    // WINDOWMAIN クラス
    CWINDOWMAIN = class
    private
        cfMain: CFONT;                                      // フォントクラス
        cwWindowMain: CWINDOW;                              // ウィンドウクラス (メインウィンドウ)
        cmSystem: CMENU;                                    // メニュークラス (システムメニュー)
        cmMain: CMENUBAR;                                   // メニュークラス (メニューバー)
        cmFile: CMENU;                                      // メニュークラス (ファイル)
        cmSetup: CMENU;                                     // メニュークラス (設定)
        cmSetupDevice: CMENU;                               // メニュークラス (設定 - サウンドデバイス)
        cmSetupChannel: CMENU;                              // メニュークラス (設定 - チャンネル)
        cmSetupBit: CMENU;                                  // メニュークラス (設定 - ビット)
        cmSetupRate: CMENU;                                 // メニュークラス (設定 - サンプリングレート)
        cmSetupInter: CMENU;                                // メニュークラス (設定 - 補間処理)
        cmSetupPitch: CMENU;                                // メニュークラス (設定 - ピッチ)
        cmSetupPitchKey: CMENU;                             // メニュークラス (設定 - ピッチ - キー)
        cmSetupSeparate: CMENU;                             // メニュークラス (設定 - 左右拡散度)
        cmSetupFeedback: CMENU;                             // メニュークラス (設定 - フィードバック反転度)
        cmSetupSpeed: CMENU;                                // メニュークラス (設定 - 演奏速度)
        cmSetupAmp: CMENU;                                  // メニュークラス (設定 - 音量)
        cmSetupMute: CMENU;                                 // メニュークラス (設定 - チャンネルマスク)
        cmSetupNoise: CMENU;                                // メニュークラス (設定 - チャンネルノイズ)
        cmSetupOption: CMENU;                               // メニュークラス (設定 - 拡張設定)
        cmSetupTime: CMENU;                                 // メニュークラス (設定 - 演奏時間)
        cmSetupOrder: CMENU;                                // メニュークラス (設定 - 演奏順序)
        cmSetupSeek: CMENU;                                 // メニュークラス (設定 - シーク時間)
        cmSetupInfo: CMENU;                                 // メニュークラス (設定 - 情報表示)
        cmSetupPriority: CMENU;                             // メニュークラス (設定 - 基本優先度)
        cmSetupOthers: CMENU;                               // メニュークラス (設定 - その他設定)
        cmList: CMENU;                                      // メニュークラス (プレイリスト)
        cmListPlay: CMENU;                                  // メニュークラス (プレイリスト - 演奏開始)
        cwStaticFile: CWINDOW;                              // ウィンドウクラス (ファイル名転送用ラベル)
        cwStaticMain: CWINDOW;                              // ウィンドウクラス (情報表示用ラベル)
        cwButtonOpen: CBUTTON;                              // ウィンドウクラス (OPEN ボタン)
        cwButtonSave: CBUTTON;                              // ウィンドウクラス (SAVE ボタン)
        cwButtonPlay: CBUTTON;                              // ウィンドウクラス (PLAY ボタン)
        cwButtonRestart: CBUTTON;                           // ウィンドウクラス (RESTART ボタン)
        cwButtonStop: CBUTTON;                              // ウィンドウクラス (STOP ボタン)
        cwCheckTrack: array[0..7] of CBUTTON;               // ウィンドウクラス (1 ～ 8 ボタン)
        cwButtonVolM: CBUTTON;                              // ウィンドウクラス (VL- ボタン)
        cwButtonVolP: CBUTTON;                              // ウィンドウクラス (VL+ ボタン)
        cwButtonSlow: CBUTTON;                              // ウィンドウクラス (SP- ボタン)
        cwButtonFast: CBUTTON;                              // ウィンドウクラス (SP+ ボタン)
        cwButtonBack: CBUTTON;                              // ウィンドウクラス (REW ボタン)
        cwButtonNext: CBUTTON;                              // ウィンドウクラス (FF ボタン)
        cwFileList: CWINDOW;                                // ウィンドウクラス (ファイル記録用)
        cwSortList: CWINDOW;                                // ウィンドウクラス (ソート用)
        cwTempList: CWINDOW;                                // ウィンドウクラス (テンポラリ用)
        cwPlayList: CWINDOW;                                // ウィンドウクラス (プレイリスト)
        cwButtonListAdd: CBUTTON;                           // ウィンドウクラス (ADD / INSERT ボタン)
        cwButtonListRemove: CBUTTON;                        // ウィンドウクラス (REMOVE ボタン)
        cwButtonListClear: CBUTTON;                         // ウィンドウクラス (CLEAR ボタン)
        cwButtonListUp: CBUTTON;                            // ウィンドウクラス (上へボタン)
        cwButtonListDown: CBUTTON;                          // ウィンドウクラス (下へボタン)
    public
        procedure AppendList();
        function  CreateWindow(hThisInstance: longword; lpClassName: pointer; lpArgs: pointer): longword;
        procedure DeleteWindow();
        procedure DragFile(msg: longword; wParam: longword; lParam: longword);
        procedure DrawInfo(pApuData: pointer; bWave: longbool);
        function  DropFile(dwParam: longword): longword;
        function  GetFileType(lpFile: pointer; bShowMsg: longbool; bScript700: longbool): longword;
        procedure GetID666Format(var Hdr: TSPCHDR);
        function  IsExt(lpFile: pointer; const sExt: string): longbool;
        function  IsSafePath(lpFile: pointer): longbool;
        procedure ListAdd(dwAuto: longword);
        procedure ListClear(bQuiet: longbool);
        procedure ListDelete();
        procedure ListDown();
        function  ListLoad(lpFile: pointer; dwType: longword; bShift: longbool): longbool;
        procedure ListNextPlay(dwOrder: longword; dwFlag: longword);
        function  ListPlay(dwOrder: longword; dwIndex: longint; dwFlag: longword): longint;
        function  ListSave(lpFile: pointer; bShift: longbool): longbool;
        procedure ListUp();
        function  LoadScript700(lpFile: pointer; dwAddr: longword): longbool;
        procedure MoveWindowScreenSide();
        procedure OpenFile();
        function  ReloadScript700(lpFile: pointer): longbool;
        procedure ResetInfo(bRedraw: longbool);
        procedure ResizeWindow();
        procedure SaveFile();
        procedure SaveSeekCache(dwIndex: longword);
        procedure SetChangeFunction(bFlag: longbool);
        procedure SetChangeInfo(bForce: longbool; dwValue: longint);
        procedure SetFunction(dwFlag: longint; dwType: longword);
        procedure SetGraphic();
        procedure SetTabFocus(hWnd: longword; bNext: longbool);
        procedure ShowErrMsg(dwCode: longword);
        function  SPCLoad(lpFile: pointer; bAutoPlay: longbool): longbool;
        procedure SPCOption();
        procedure SPCPlay(dwType: longword);
        procedure SPCReset(bWave: longbool);
        function  SPCSave(lpFile: pointer; bShift: longbool): longbool;
        procedure SPCSeek(dwTime: longword; bCache: longbool);
        procedure SPCStop(bRestart: longbool);
        procedure SPCTime(bCal: longbool; bDefault: longbool; bSet: longbool);
        procedure UpdateDevice(dwDeviceID: longint; dwFlag: longword);
        procedure UpdateInfo(bRedraw: longbool);
        procedure UpdateMenu();
        procedure UpdateTitle(dwFlag: longword);
        procedure UpdateWindow();
        procedure WaveClose(bForce: longbool);
        procedure WaveFormat(dwIndex: longword);
        procedure WaveInit();
        function  WaveOpen(): longword;
        function  WavePause(): longbool;
        procedure WaveProc(dwFlag: longword);
        procedure WaveQuit();
        procedure WaveReset(bForce: longbool);
        function  WaveResume(): longbool;
        function  WaveSave(lpFile: pointer; bShift: longbool; bQuiet: longbool): longbool;
        procedure WaveStart();
        function  WindowProc(hWnd: longword; msg: longword; wParam: longword; lParam: longword; var dwDef: longword): longword;
    end;


// *************************************************************************************************************************************************************
// 定数の宣言
// *************************************************************************************************************************************************************

const
    // Delphi 標準定数
    NULL = 0;                                               // ヌル
    NULLCHAR = #0;                                          // ヌル文字
    NULLPOINTER = nil;                                      // ヌルポインタ
    CRLF = #13#10;                                          // 改行

    // CLASS クラス
    COLOR_3DDKSHADOW = $15;
    COLOR_3DLIGHT = $16;
    COLOR_ACTIVEBORDER = $A;
    COLOR_ACTIVECAPTION = $2;
    COLOR_APPWORKSPACE = $C;
    COLOR_BACKGROUND = $1;
    COLOR_BTNFACE = $F;
    COLOR_BTNHIGHLIGHT = $14;
    COLOR_BTNSHADOW = $10;
    COLOR_BTNTEXT = $12;
    COLOR_CAPTIONTEXT = $9;
    COLOR_GRADIENTACTIVECAPTION = $1B;
    COLOR_GRADIENTINACTIVECAPTION = $1C;
    COLOR_GRAYTEXT = $11;
    COLOR_HIGHLIGHT = $D;
    COLOR_HIGHLIGHTTEXT = $E;
    COLOR_HOTLIGHT = $1A;
    COLOR_INACTIVEBORDER = $B;
    COLOR_INACTIVECAPTION = $3;
    COLOR_INACTIVECAPTIONTEXT = $13;
    COLOR_INFOBK = $18;
    COLOR_INFOTEXT = $17;
    COLOR_MENU = $4;
    COLOR_MENUBAR = $1E;
    COLOR_MENUHILIGHT = $1D;
    COLOR_MENUTEXT = $7;
    COLOR_SCROLLBAR = $0;
    COLOR_WINDOW = $5;
    COLOR_WINDOWFRAME = $6;
    COLOR_WINDOWTEXT = $8;
    CS_BYTEALIGNCLIENT = $1000;
    CS_BYTEALIGNWINDOW = $2000;
    CS_CLASSDC = $40;
    CS_DBLCLKS = $8;
    CS_GLOBALCLASS = $4000;
    CS_HREDRAW = $2;
    CS_INSERTCHAR = $2000;
    CS_KEYCVTWINDOW = $4;
    CS_NOCLOSE = $200;
    CS_NOKEYCVT = $100;
    CS_NOMOVECARET = $4000;
    CS_OWNDC = $20;
    CS_PARENTDC = $80;
    CS_PUBLICCLASS = $4000;
    CS_SAVEBITS = $800;
    CS_VREDRAW = $1;
    IDC_APPSTARTING = $7F8A;
    IDC_ARROW = $7F00;
    IDC_CROSS = $7F03;
    IDC_IBEAM = $7F01;
    IDC_ICON = $7F81;
    IDC_NO = $7F88;
    IDC_SIZE = $7F80;
    IDC_SIZEALL = $7F86;
    IDC_SIZENESW = $7F83;
    IDC_SIZENS = $7F85;
    IDC_SIZENWSE = $7F82;
    IDC_SIZEWE = $7F84;
    IDC_UPARROW = $7F04;
    IDC_WAIT = $7F02;

    // MENU クラス
    MF_BYCOMMAND = $0;
    MF_BYPOSITION = $400;
    MF_CHECKED = $8;
    MF_DISABLED = $2;
    MF_ENABLED = $0;
    MF_GRAYED = $1;
    MF_HILITE = $80;
    MF_MENUBREAK = $20;
    MF_OWNERDRAW = $100;
    MF_POPUP = $10;
    MF_RADIOCHECK = $200;
    MF_RIGHTJUSTIFY = $2000;
    MF_RIGHTORDER = $1000;
    MF_SEPARATOR = $800;
    MF_STRING = $0;
    MF_UNCHECKED = $0;
    MF_UNHILITE = $0;

    // MENUBAR クラス
    MIIM_BITMAP = $80;
    MIIM_CHECKMARKS = $8;
    MIIM_DATA = $20;
    MIIM_FTYPE = $100;
    MIIM_ID = $2;
    MIIM_STATE = $1;
    MIIM_STRING = $40;
    MIIM_SUBMENU = $4;
    MIIM_TYPE = $10;
    MIM_APPLYTOSUBMENUS = $80000000;
    MIM_BACKGROUND = $2;
    MIM_HELPID = $4;
    MIM_MAXHEIGHT = $1;
    MIM_MENUDATA = $8;
    MIM_STYLE = $10;
    MNS_AUTODISMISS = $10000000;
    MNS_CHECKORBMP = $4000000;
    MNS_DRAGDROP = $20000000;
    MNS_MODELESS = $40000000;
    MNS_NOCHECK = $80000000;
    MNS_NOTIFYBYPOS = $8000000;
    OBJID_CLIENT = $FFFFFFFC;
    OBJID_MENU = $FFFFFFFD;
    OBJID_SYSMENU = $FFFFFFFF;

    // WINDOW クラス
    BM_CLICK = $F5;
    BM_GETCHECK = $F0;
    BM_GETIMAGE = $F6;
    BM_GETSTATE = $F2;
    BM_SETCHECK = $F1;
    BM_SETIMAGE = $F7;
    BM_SETSTATE = $F3;
    BM_SETSTYLE = $F4;
    BN_CLICKED = $0;
    BN_DBLCLK = $5;
    BN_HILITE = $2;
    BN_KILLFOCUS = $7;
    BN_PAINT = $1;
    BN_SETFOCUS = $6;
    BN_UNHILITE = $3;
    BS_3STATE = $5;
    BS_AUTO3STATE = $6;
    BS_AUTOCHECKBOX = $3;
    BS_AUTORADIOBUTTON = $9;
    BS_BITMAP = $80;
    BS_BOTTOM = $800;
    BS_CENTER = $300;
    BS_CHECKBOX = $2;
    BS_DEFPUSHBUTTON = $1;
    BS_GROUPBOX = $7;
    BS_ICON = $40;
    BS_LEFT = $100;
    BS_LEFTTEXT = $20;
    BS_MULTILINE = $2000;
    BS_NOTIFY = $4000;
    BS_OWNERDRAW = $B;
    BS_PUSHBUTTON = $0;
    BS_PUSHLIKE = $1000;
    BS_RADIOBUTTON = $4;
    BS_RIGHT = $200;
    BS_TEXT = $0;
    BS_TOP = $400;
    BS_VCENTER = $C00;
    CB_ADDSTRING = $143;
    CB_DELETESTRING = $144;
    CB_DIR = $145;
    CB_ERR = -1;
    CB_ERRSPACE = -2;
    CB_FINDSTRING = $14C;
    CB_FINDSTRINGEXACT = $158;
    CB_GETCOUNT = $146;
    CB_GETCURSEL = $147;
    CB_GETDROPPEDCONTROLRECT = $152;
    CB_GETDROPPEDSTATE = $157;
    CB_GETDROPPEDWIDTH = $15F;
    CB_GETEDITSEL = $140;
    CB_GETEXTENDEDUI = $156;
    CB_GETHORIZONTALEXTENT = $15D;
    CB_GETITEMDATA = $150;
    CB_GETITEMHEIGHT = $154;
    CB_GETLBTEXT = $148;
    CB_GETLBTEXTLEN = $149;
    CB_GETLOCALE = $15A;
    CB_GETTOPINDEX = $15B;
    CB_INITSTORAGE = $161;
    CB_INSERTSTRING = $14A;
    CB_LIMITTEXT = $141;
    CB_MSGMAX = $15B;
    CB_OKAY = $0;
    CB_RESETCONTENT = $14B;
    CB_SELECTSTRING = $14D;
    CB_SETCURSEL = $14E;
    CB_SETDROPPEDWIDTH = $160;
    CB_SETEDITSEL = $142;
    CB_SETEXTENDEDUI = $155;
    CB_SETHORIZONTALEXTENT = $15E;
    CB_SETITEMDATA = $151;
    CB_SETITEMHEIGHT = $153;
    CB_SETLOCALE = $159;
    CB_SETTOPINDEX = $15C;
    CB_SHOWDROPDOWN = $14F;
    CBM_CREATEDIB = $2;
    CBM_INIT = $4;
    CBN_CLOSEUP = $8;
    CBN_DBLCLK = $2;
    CBN_DROPDOWN = $7;
    CBN_EDITCHANGE = $5;
    CBN_EDITUPDATE = $6;
    CBN_ERRSPACE = -1;
    CBN_KILLFOCUS = $4;
    CBN_SELCHANGE = $1;
    CBN_SELENDCANCEL = $A;
    CBN_SELENDOK = $9;
    CBN_SETFOCUS = $3;
    CBS_AUTOHSCROLL = $40;
    CBS_DISABLENOSCROLL = $800;
    CBS_DROPDOWN = $2;
    CBS_DROPDOWNLIST = $3;
    CBS_HASSTRINGS = $200;
    CBS_LOWERCASE = $4000;
    CBS_NOINTEGRALHEIGHT = $400;
    CBS_OEMCONVERT = $80;
    CBS_OWNERDRAWFIXED = $10;
    CBS_OWNERDRAWVARIABLE = $20;
    CBS_SIMPLE = $1;
    CBS_SORT = $100;
    CBS_UPPERCASE = $2000;
    CW_USEDEFAULT = -2147483648;
    DEVICE_NOTIFY_CALLBACK = $2;
    DEVICE_NOTIFY_SERVICE_HANDLE = $1;
    DEVICE_NOTIFY_WINDOW_HANDLE = $0;
    DS_3DLOOK = $4;
    DS_ABSALIGN = $1;
    DS_CENTER = $800;
    DS_CENTERMOUSE = $1000;
    DS_CONTEXTHELP = $2000;
    DS_CONTROL = $400;
    DS_FIXEDSYS = $8;
    DS_MODALFRAME = $80;
    DS_NOFAILCREATE = $10;
    DS_NOIDLEMSG = $100;
    DS_SETFONT = $40;
    DS_SYSMODAL = $2;
    EM_CANUNDO = $C6;
    EM_EMPTYUNDOBUFFER = $CD;
    EM_FMTLINES = $C8;
    EM_GETFIRSTVISIBLELINE = $CE;
    EM_GETHANDLE = $BD;
    EM_GETLINE = $C4;
    EM_GETLINECOUNT = $BA;
    EM_GETMODIFY = $B8;
    EM_GETPASSWORDCHAR = $D2;
    EM_GETRECT = $B2;
    EM_GETSEL = $B0;
    EM_GETTHUMB = $BE;
    EM_GETWORDBREAKPROC = $D1;
    EM_LIMITTEXT = $C5;
    EM_LINEFROMCHAR = $C9;
    EM_LINEINDEX = $BB;
    EM_LINELENGTH = $C1;
    EM_LINESCROLL = $B6;
    EM_REPLACESEL = $C2;
    EM_SCROLL = $B5;
    EM_SCROLLCARET = $B7;
    EM_SETHANDLE = $BC;
    EM_SETMODIFY = $B9;
    EM_SETPASSWORDCHAR = $CC;
    EM_SETREADONLY = $CF;
    EM_SETRECT = $B3;
    EM_SETRECTNP = $B4;
    EM_SETSEL = $B1;
    EM_SETTABSTOPS = $CB;
    EM_SETWORDBREAKPROC = $D0;
    EM_UNDO = $C7;
    EN_CHANGE = $300;
    EN_ERRSPACE = $500;
    EN_HSCROLL = $601;
    EN_KILLFOCUS = $200;
    EN_MAXTEXT = $501;
    EN_SETFOCUS = $100;
    EN_UPDATE = $400;
    EN_VSCROLL = $602;
    ES_AUTOHSCROLL = $80;
    ES_AUTOVSCROLL = $40;
    ES_CENTER = $1;
    ES_LEFT = $0;
    ES_LOWERCASE = $10;
    ES_MULTILINE = $4;
    ES_NOHIDESEL = $100;
    ES_NUMBER = $2000;
    ES_OEMCONVERT = $400;
    ES_PASSWORD = $20;
    ES_READONLY = $800;
    ES_RIGHT = $2;
    ES_UPPERCASE = $8;
    ES_WANTRETURN = $1000;
    GCL_CBCLSEXTRA = -20;
    GCL_CBWNDEXTRA = -18;
    GCL_HBRBACKGROUND = -10;
    GCL_HCURSOR = -12;
    GCL_HICON = -14;
    GCL_HICONSM = -34;
    GCL_HMODULE = -16;
    GCL_MENUNAME = -8;
    GCL_STYLE = -26;
    GCL_WNDPROC = -24;
    GWL_EXSTYLE = -20;
    GWL_HINSTANCE = -6;
    GWL_HWNDPARENT = -8;
    GWL_ID = -12;
    GWL_STYLE = -16;
    GWL_USERDATA = -21;
    GWL_WNDPROC = -4;
    HWND_BOTTOM = $1;
    HWND_NOTOPMOST = $FFFFFFFE;
    HWND_TOP = $0;
    HWND_TOPMOST = $FFFFFFFF;
    IDABORT = $3;
    IDCANCEL = $2;
    IDIGNORE = $5;
    IDNO = $7;
    IDOK = $1;
    IDRETRY = $4;
    IDYES = $6;
    ITEM_BUTTON = 'Button';
    ITEM_COMBOBOX = 'ComboBox';
    ITEM_EDIT = 'Edit';
    ITEM_LISTBOX = 'ListBox';
    ITEM_SCROLLBAR = 'ScrollBar';
    ITEM_STATIC = 'Static';
    LB_ADDFILE = $196;
    LB_ADDSTRING = $180;
    LB_CTLCODE = $0;
    LB_DELETESTRING = $182;
    LB_DIR = $18D;
    LB_ERR = -1;
    LB_ERRSPACE = -2;
    LB_FINDSTRING = $18F;
    LB_FINDSTRINGEXACT = $1A2;
    LB_GETANCHORINDEX = $19D;
    LB_GETCARETINDEX = $19F;
    LB_GETCOUNT = $18B;
    LB_GETCURSEL = $188;
    LB_GETHORIZONTALEXTENT = $193;
    LB_GETITEMDATA = $199;
    LB_GETITEMHEIGHT = $1A1;
    LB_GETITEMRECT = $198;
    LB_GETLOCALE = $1A6;
    LB_GETSEL = $187;
    LB_GETSELCOUNT = $190;
    LB_GETSELITEMS = $191;
    LB_GETTEXT = $189;
    LB_GETTEXTLEN = $18A;
    LB_GETTOPINDEX = $18E;
    LB_INSERTSTRING = $181;
    LB_MSGMAX = $1A8;
    LB_OKAY = $0;
    LB_RESETCONTENT = $184;
    LB_SELECTSTRING = $18C;
    LB_SELITEMRANGE = $19B;
    LB_SELITEMRANGEEX = $183;
    LB_SETANCHORINDEX = $19C;
    LB_SETCARETINDEX = $19E;
    LB_SETCOLUMNWIDTH = $195;
    LB_SETCOUNT = $1A7;
    LB_SETCURSEL = $186;
    LB_SETHORIZONTALEXTENT = $194;
    LB_SETITEMDATA = $19A;
    LB_SETITEMHEIGHT = $1A0;
    LB_SETLOCALE = $1A5;
    LB_SETSEL = $185;
    LB_SETTABSTOPS = $192;
    LB_SETTOPINDEX = $197;
    LBN_DBLCLK = $2;
    LBN_ERRSPACE = -2;
    LBN_KILLFOCUS = $5;
    LBN_SELCANCEL = $3;
    LBN_SELCHANGE = $1;
    LBN_SETFOCUS = $4;
    LBS_DISABLENOSCROLL = $1000;
    LBS_EXTENDEDSEL = $800;
    LBS_HASSTRINGS = $40;
    LBS_MULTICOLUMN = $200;
    LBS_MULTIPLESEL = $8;
    LBS_NODATA = $2000;
    LBS_NOINTEGRALHEIGHT = $100;
    LBS_NOREDRAW = $4;
    LBS_NOSEL = $4000;
    LBS_NOTIFY = $1;
    LBS_OWNERDRAWFIXED = $10;
    LBS_OWNERDRAWVARIABLE = $20;
    LBS_SORT = $2;
    LBS_USETABSTOPS = $80;
    LBS_WANTKEYBOARDINPUT = $400;
    MB_APPLMODAL = $0;
    MB_DEFBUTTON1 = $0;
    MB_DEFBUTTON2 = $100;
    MB_DEFBUTTON3 = $200;
    MB_ICONASTERISK = $40;
    MB_ICONEXCLAMATION = $30;
    MB_ICONHAND = $10;
    MB_ICONINFORMATION = $40;
    MB_ICONMASK = $F0;
    MB_ICONQUESTION = $20;
    MB_ICONSTOP = $10;
    MB_NOFOCUS = $8000;
    MB_OK = $0;
    MB_OKCANCEL = $1;
    MB_RETRYCANCEL = $5;
    MB_SETFOREGROUND = $10000;
    MB_SYSTEMMODAL = $1000;
    MB_TASKMODAL = $2000;
    MB_YESNO = $4;
    MB_YESNOCANCEL = $3;
    MK_ALT = $20;
    MK_LBUTTON = $1;
    MK_RBUTTON = $2;
    MK_SHIFT = $4;
    MK_CONTROL = $8;
    MK_MBUTTON = $10;
    MONITOR_DEFAULTTONULL = $0;
    MONITOR_DEFAULTTOPRIMARY = $1;
    MONITOR_DEFAULTTONEAREST = $2;
    MONITORINFOF_PRIMARY = $1;
    MSGFLT_ADD = $1;
    MSGFLT_REMOVE = $2;
    PBT_APMBATTERYLOW = $9;
    PBT_APMPOWERSTATUSCHANGE = $A;
    PBT_APMOEMEVENT = $B;
    PBT_APMQUERYSUSPEND = $0;
    PBT_APMQUERYSUSPENDFAILED = $2;
    PBT_APMQUERYSTANDBY = $1;
    PBT_APMQUERYSTANDBYFAILED = $3;
    PBT_APMRESUMEAUTOMATIC = $12;
    PBT_APMRESUMECRITICAL = $6;
    PBT_APMRESUMESTANDBY = $8;
    PBT_APMRESUMESUSPEND = $7;
    PBT_APMSTANDBY = $5;
    PBT_APMSUSPEND = $4;
    PBT_POWERSETTINGCHANGE = $8013;
    PM_NOREMOVE = $0;
    PM_REMOVE = $1;
    RDW_ALLCHILDREN = $80;
    RDW_ERASE = $4;
    RDW_ERASENOW = $200;
    RDW_FRAME = $400;
    RDW_INTERNALPAINT = $2;
    RDW_INVALIDATE = $1;
    RDW_NOCHILDREN = $40;
    RDW_NOERASE = $20;
    RDW_NOFRAME = $800;
    RDW_NOINTERNALPAINT = $10;
    RDW_UPDATENOW = $100;
    RDW_VALIDATE = $8;
    SB_BOTH = $3;
    SB_BOTTOM = $7;
    SB_CTL = $2;
    SB_ENDSCROLL = $8;
    SB_HORZ = $0;
    SB_LEFT = $6;
    SB_LINEDOWN = $1;
    SB_LINELEFT = $0;
    SB_LINERIGHT = $1;
    SB_LINEUP = $0;
    SB_PAGEDOWN = $3;
    SB_PAGELEFT = $2;
    SB_PAGERIGHT = $3;
    SB_PAGEUP = $2;
    SB_RIGHT = $7;
    SB_THUMBPOSITION = $4;
    SB_THUMBTRACK = $5;
    SB_TOP = $6;
    SB_VERT = $1;
    SBM_ENABLE_ARROWS = $E4;
    SBM_GETPOS = $E1;
    SBM_GETRANGE = $E3;
    SBM_SETPOS = $E0;
    SBM_SETRANGE = $E2;
    SBM_SETRANGEREDRAW = $E6;
    SBS_BOTTOMALIGN = $4;
    SBS_HORZ = $0;
    SBS_LEFTALIGN = $2;
    SBS_RIGHTALIGN = $4;
    SBS_SIZEBOX = $8;
    SBS_SIZEBOXBOTTOMRIGHTALIGN = $4;
    SBS_SIZEBOXTOPLEFTALIGN = $2;
    SBS_SIZEGRIP = $10;
    SBS_TOPALIGN = $2;
    SBS_VERT = $1;
    SC_ARRANGE = $F110;
    SC_CLOSE = $F060;
    SC_CONTEXTHELP = $F180;
    SC_DEFAULT = $F160;
    SC_HOTKEY = $F150;
    SC_HSCROLL = $F080;
    SC_KEYMENU = $F100;
    SC_MAXIMIZE = $F030;
    SC_MINIMIZE = $F020;
    SC_MONITORPOWER = $F170;
    SC_MOUSEMENU = $F090;
    SC_MOVE = $F010;
    SC_NEXTWINDOW = $F040;
    SC_PREVWINDOW = $F050;
    SC_RESTORE = $F120;
    SC_SCREENSAVE = $F140;
    SC_SEPARATOR = $F00F;
    SC_SIZE = $F000;
    SC_TASKLIST = $F130;
    SC_VSCROLL = $F070;
    SS_BITMAP = $E;
    SS_BLACKFRAME = $7;
    SS_BLACKRECT = $4;
    SS_CENTER = $1;
    SS_CENTERIMAGE = $200;
    SS_GRAYFRAME = $8;
    SS_GRAYRECT = $5;
    SS_ICON = $3;
    SS_LEFT = $0;
    SS_LEFTNOWORDWRAP = $C;
    SS_NOPREFIX = $80;
    SS_NOTIFY = $100;
    SS_RIGHT = $2;
    SS_RIGHTJUST = $400;
    SS_SIMPLE = $B;
    SS_WHITEFRAME = $9;
    SS_WHITERECT = $6;
    STM_GETICON = $171;
    STM_MSGMAX = $172;
    STM_SETICON = $170;
    STN_CLICKED = $0;
    STN_DBLCLK = $1;
    STN_DISABLE = $3;
    STN_ENABLE = $2;
    SM_AEROFRAME = 85;                                      // ウィンドウの枠線 (px) for Windows Vista, 7
    SM_ARRANGE = 56;
    SM_CLEANBOOT = 67;
    SM_CMETRICS16 = 76;                                     // for Win9x
    SM_CMETRICS32 = 83;                                     // for WinNT4
    SM_CMONITORS = 80;
    SM_CMOUSEBUTTONS = 43;
    SM_CXBORDER = 5;
    SM_CXCURSOR = 13;
    SM_CXDLGFRAME = 7;
    SM_CXDOUBLECLK = 36;
    SM_CXDRAG = 68;
    SM_CXEDGE = 45;
    SM_CXFRAME = 32;
    SM_CXFULLSCREEN = 16;
    SM_CXHSCROLL = 21;
    SM_CXHTHUMB = 10;
    SM_CXICON = 11;
    SM_CXICONSPACING = 38;
    SM_CXMAXIMIZED = 61;
    SM_CXMAXTRACK = 59;
    SM_CXMENUCHECK = 71;
    SM_CXMENUSIZE = 54;
    SM_CXMIN = 28;
    SM_CXMINIMIZED = 57;
    SM_CXMINSPACING = 47;
    SM_CXMINTRACK = 34;
    SM_CXSCREEN = 0;
    SM_CXSIZE = 30;
    SM_CXSMICON = 49;
    SM_CXSMSIZE = 52;
    SM_CXVIRTUALSCREEN = 78;
    SM_CXVSCROLL = 2;
    SM_CYBORDER = 6;
    SM_CYCAPTION = 4;
    SM_CYCURSOR = 14;
    SM_CYDLGFRAME = 8;
    SM_CYDOUBLECLK = 37;
    SM_CYDRAG = 69;
    SM_CYEDGE = 46;
    SM_CYFRAME = 33;
    SM_CYFULLSCREEN = 17;
    SM_CYHSCROLL = 3;
    SM_CYICON = 12;
    SM_CYICONSPACING = 39;
    SM_CYKANJIWINDOW = 18;
    SM_CYMAXIMIZED = 62;
    SM_CYMAXTRACK = 60;
    SM_CYMENU = 15;
    SM_CYMENUCHECK = 72;
    SM_CYMENUSIZE = 55;
    SM_CYMIN = 29;
    SM_CYMINIMIZED = 58;
    SM_CYMINSPACING = 48;
    SM_CYMINTRACK = 35;
    SM_CYSCREEN = 1;
    SM_CYSIZE = 31;
    SM_CYSMCAPTION = 51;
    SM_CYSMICON = 50;
    SM_CYSMSIZE = 53;
    SM_CYVIRTUALSCREEN = 79;
    SM_CYVSCROLL = 20;
    SM_CYVTHUMB = 9;
    SM_DBCSENABLED = 42;
    SM_DEBUG = 22;
    SM_MENUDROPALIGNMENT = 40;
    SM_MIDEASTENABLED = 74;
    SM_MOUSEPRESENT = 19;
    SM_MOUSEWHEELPRESENT = 75;
    SM_NETWORK = 63;
    SM_PENWINDOWS = 41;
    SM_RESERVED1 = 24;
    SM_RESERVED2 = 25;
    SM_RESERVED3 = 26;
    SM_RESERVED4 = 27;
    SM_SAMEDISPLAYFORMAT = 81;
    SM_SECURE = 44;
    SM_SHOWSOUNDS = 70;
    SM_SLOWMACHINE = 73;
    SM_SWAPBUTTON = 23;
    SM_XVIRTUALSCREEN = 76;
    SM_YVIRTUALSCREEN = 77;
    SPI_GETACCESSTIMEOUT = 60;
    SPI_GETACTIVEWINDOWTRACKING = $1000;
    SPI_GETACTIVEWNDTRKTIMEOUT = $2002;
    SPI_GETACTIVEWNDTRKZORDER = $100C;
    SPI_GETANIMATION = 72;
    SPI_GETBEEP = 1;
    SPI_GETBORDER = 5;
    SPI_GETCOMBOBOXANIMATION = $1004;
    SPI_GETDEFAULTINPUTLANG = 89;
    SPI_GETDRAGFULLWINDOWS = 38;
    SPI_GETFASTTASKSWITCH = 35;
    SPI_GETFILTERKEYS = 50;
    SPI_GETFONTSMOOTHING = 74;
    SPI_GETFOREGROUNDFLASHCOUNT = $2004;
    SPI_GETFOREGROUNDLOCKTIMEOUT = $2000;
    SPI_GETGRADIENTCAPTIONS = $1008;
    SPI_GETGRIDGRANULARITY = 18;
    SPI_GETHIGHCONTRAST = 66;
    SPI_GETHOTTRACKING = $100E;
    SPI_GETICONMETRICS = 45;
    SPI_GETICONTITLELOGFONT = 31;
    SPI_GETICONTITLEWRAP = 25;
    SPI_GETKEYBOARDDELAY = 22;
    SPI_GETKEYBOARDPREF = 68;
    SPI_GETKEYBOARDSPEED = 10;
    SPI_GETLISTBOXSMOOTHSCROLLING = $1006;
    SPI_GETLOWPOWERACTIVE = 83;
    SPI_GETLOWPOWERTIMEOUT = 79;
    SPI_GETMENUANIMATION = $1002;
    SPI_GETMENUDROPALIGNMENT = 27;
    SPI_GETMENUUNDERLINES = $100A;
    SPI_GETMINIMIZEDMETRICS = 43;
    SPI_GETMOUSE = 3;
    SPI_GETMOUSEHOVERHEIGHT = 100;
    SPI_GETMOUSEHOVERTIME = 102;
    SPI_GETMOUSEHOVERWIDTH = 98;
    SPI_GETMOUSEKEYS = 54;
    SPI_GETMOUSESPEED = 112;
    SPI_GETMOUSETRAILS = 94;
    SPI_GETNONCLIENTMETRICS = 41;
    SPI_GETPOWEROFFACTIVE = 84;
    SPI_GETPOWEROFFTIMEOUT = 80;
    SPI_GETSCREENREADER = 70;
    SPI_GETSCREENSAVEACTIVE = 16;
    SPI_GETSCREENSAVERRUNNING = 114;
    SPI_GETSCREENSAVETIMEOUT = 14;
    SPI_GETSERIALKEYS = 62;
    SPI_GETSHOWIMEUI = 110;
    SPI_GETSHOWSOUNDS = 56;
    SPI_GETSOUNDSENTRY = 64;
    SPI_GETSTICKYKEYS = 58;
    SPI_GETTOGGLEKEYS = 52;
    SPI_GETWHEELSCROLLLINES = 104;
    SPI_GETWINDOWSEXTENSION = 92;
    SPI_GETWORKAREA = 48;
    SPI_ICONHORIZONTALSPACING = 13;
    SPI_ICONVERTICALSPACING = 24;
    SPI_LANGDRIVER = 12;
    SPI_SETACCESSTIMEOUT = 61;
    SPI_SETACTIVEWINDOWTRACKING = $1001;
    SPI_SETACTIVEWNDTRKTIMEOUT = $2003;
    SPI_SETACTIVEWNDTRKZORDER = $100D;
    SPI_SETANIMATION = 73;
    SPI_SETBEEP = 2;
    SPI_SETBORDER = 6;
    SPI_SETCOMBOBOXANIMATION = $1005;
    SPI_SETCURSORS = 87;
    SPI_SETDEFAULTINPUTLANG = 90;
    SPI_SETDESKPATTERN = 21;
    SPI_SETDESKWALLPAPER = 20;
    SPI_SETDOUBLECLICKTIME = 32;
    SPI_SETDOUBLECLKHEIGHT = 30;
    SPI_SETDOUBLECLKWIDTH = 29;
    SPI_SETDRAGFULLWINDOWS = 37;
    SPI_SETDRAGHEIGHT = 77;
    SPI_SETDRAGWIDTH = 76;
    SPI_SETFASTTASKSWITCH = 36;
    SPI_SETFILTERKEYS = 51;
    SPI_SETFONTSMOOTHING = 75;
    SPI_SETFOREGROUNDFLASHCOUNT = $2005;
    SPI_SETFOREGROUNDLOCKTIMEOUT = $2001;
    SPI_SETGRADIENTCAPTIONS = $1009;
    SPI_SETGRIDGRANULARITY = 19;
    SPI_SETHANDHELD = 78;
    SPI_SETHIGHCONTRAST = 67;
    SPI_SETHOTTRACKING = $100F;
    SPI_SETICONMETRICS = 46;
    SPI_SETICONS = 88;
    SPI_SETICONTITLELOGFONT = 34;
    SPI_SETICONTITLEWRAP = 26;
    SPI_SETKEYBOARDDELAY = 23;
    SPI_SETKEYBOARDPREF = 69;
    SPI_SETKEYBOARDSPEED = 11;
    SPI_SETLANGTOGGLE = 91;
    SPI_SETLISTBOXSMOOTHSCROLLING = $1007;
    SPI_SETLOWPOWERACTIVE = 85;
    SPI_SETLOWPOWERTIMEOUT = 81;
    SPI_SETMENUANIMATION = $1003;
    SPI_SETMENUDROPALIGNMENT = 28;
    SPI_SETMENUUNDERLINES = $100B;
    SPI_SETMINIMIZEDMETRICS = 44;
    SPI_SETMOUSE = 4;
    SPI_SETMOUSEBUTTONSWAP = 33;
    SPI_SETMOUSEHOVERHEIGHT = 101;
    SPI_SETMOUSEHOVERTIME = 103;
    SPI_SETMOUSEHOVERWIDTH = 99;
    SPI_SETMOUSEKEYS = 55;
    SPI_SETMOUSESPEED = 113;
    SPI_SETMOUSETRAILS = 93;
    SPI_SETNONCLIENTMETRICS = 42;
    SPI_SETPENWINDOWS = 49;
    SPI_SETPOWEROFFACTIVE = 86;
    SPI_SETPOWEROFFTIMEOUT = 82;
    SPI_SETSCREENREADER = 71;
    SPI_SETSCREENSAVEACTIVE = 17;
    SPI_SETSCREENSAVERRUNNING = 97;
    SPI_SETSCREENSAVETIMEOUT = 15;
    SPI_SETSERIALKEYS = 63;
    SPI_SETSHOWIMEUI = 111;
    SPI_SETSHOWSOUNDS = 57;
    SPI_SETSOUNDSENTRY = 65;
    SPI_SETSTICKYKEYS = 59;
    SPI_SETTOGGLEKEYS = 53;
    SPI_SETWHEELSCROLLLINES = 105;
    SPI_SETWORKAREA = 47;
    SPI_SCREENSAVERRUNNING = SPI_SETSCREENSAVERRUNNING;
    SW_HIDE = $0;
    SW_MAXIMIZE = $3;
    SW_MINIMIZE = $6;
    SW_RESTORE = $9;
    SW_SHOW = $5;
    SW_SHOWDEFAULT = $A;
    SW_SHOWMAXIMIZED = $3;
    SW_SHOWMINIMIZED = $2;
    SW_SHOWMINNOACTIVE = $7;
    SW_SHOWNA = $8;
    SW_SHOWNOACTIVATE = $4;
    SW_SHOWNORMAL = $1;
    SWP_ASYNCWINDOWPOS = $4000;
    SWP_DEFERERASE = $2000;
    SWP_DRAWFRAME = $20;
    SWP_FRAMECHANGED = $20;
    SWP_HIDEWINDOW = $80;
    SWP_NOACTIVATE = $10;
    SWP_NOCOPYBITS = $100;
    SWP_NOMOVE = $2;
    SWP_NOOWNERZORDER = $200;
    SWP_NOREDRAW = $8;
    SWP_NOREPOSITION = $200;
    SWP_NOSENDCHANGING = $400;
    SWP_NOSIZE = $1;
    SWP_NOZODER = $4;
    SWP_SHOWWINDOW = $40;
    VK_0 = $30;
    VK_1 = $31;
    VK_2 = $32;
    VK_3 = $33;
    VK_4 = $34;
    VK_5 = $35;
    VK_6 = $36;
    VK_7 = $37;
    VK_8 = $38;
    VK_9 = $39;
    VK_A = $41;
    VK_ACCEPT = $1E;
    VK_ADD = $6B;
    VK_APPS = $5D;
    VK_ATTN = $F6;
    VK_B = $42;
    VK_BACK = $8;
    VK_BROWSER_BACK = $A6;
    VK_BROWSER_FAVORITES = $AB;
    VK_BROWSER_FORWARD = $A7;
    VK_BROWSER_HOME = $AC;
    VK_BROWSER_REFRESH = $A8;
    VK_BROWSER_SEARCH = $AA;
    VK_BROWSER_STOP = $A9;
    VK_C = $43;
    VK_CANCEL = $3;
    VK_CAPITAL = $14;
    VK_CLEAR = $C;
    VK_CONTROL = $11;
    VK_CONVERT = $1C;
    VK_CRSEL = $F7;
    VK_D = $44;
    VK_DECIMAL = $6E;
    VK_DELETE = $2E;
    VK_DIVIDE = $6F;
    VK_DOWN = $28;
    VK_E = $45;
    VK_ESCAPE = $1B;
    VK_END = $23;
    VK_EREOF = $F9;
    VK_EXECUTE = $2B;
    VK_EXSEL = $F8;
    VK_F = $46;
    VK_F1 = $70;
    VK_F2 = $71;
    VK_F3 = $72;
    VK_F4 = $73;
    VK_F5 = $74;
    VK_F6 = $75;
    VK_F7 = $76;
    VK_F8 = $77;
    VK_F9 = $78;
    VK_F10 = $79;
    VK_F11 = $7A;
    VK_F12 = $7B;
    VK_F13 = $7C;
    VK_F14 = $7D;
    VK_F15 = $7E;
    VK_F16 = $7F;
    VK_F17 = $80;
    VK_F18 = $81;
    VK_F19 = $82;
    VK_F20 = $83;
    VK_F21 = $84;
    VK_F22 = $85;
    VK_F23 = $86;
    VK_F24 = $87;
    VK_FINAL = $18;
    VK_G = $47;
    VK_H = $48;
    VK_HELP = $2F;
    VK_HOME = $24;
    VK_I = $49;
    VK_ICO_00 = $E4;
    VK_ICO_CLEAR = $E6;
    VK_ICO_HELP = $E3;
    VK_INSERT = $2D;
    VK_J = $4A;
    VK_JUNJA = $17;
    VK_K = $4B;
    VK_KANA = $15;
    VK_KANJI = $19;
    VK_L = $4C;
    VK_LAUNCH_APP1 = $B6;
    VK_LAUNCH_APP2 = $B7;
    VK_LAUNCH_MAIL = $B4;
    VK_LAUNCH_MEDIA_SELECT = $B5;
    VK_LBUTTON = $1;
    VK_LCONTROL = $A2;
    VK_LEFT = $25;
    VK_LMENU = $A4;
    VK_LSHIFT = $A0;
    VK_LWIN = $5B;
    VK_M = $4D;
    VK_MBUTTON = $4;
    VK_MEDIA_NEXT_TRACK = $B0;
    VK_MEDIA_PLAY_PAUSE = $B3;
    VK_MEDIA_PREV_TRACK = $B1;
    VK_MEDIA_STOP = $B2;
    VK_MENU = $12;
    VK_MODECHANGE = $1F;
    VK_MULTIPLY = $6A;
    VK_N = $4E;
    VK_NEXT = $22;
    VK_NONAME = $FC;
    VK_NUMLOCK = $90;
    VK_NUMPAD0 = $60;
    VK_NUMPAD1 = $61;
    VK_NUMPAD2 = $62;
    VK_NUMPAD3 = $63;
    VK_NUMPAD4 = $64;
    VK_NUMPAD5 = $65;
    VK_NUMPAD6 = $66;
    VK_NUMPAD7 = $67;
    VK_NUMPAD8 = $68;
    VK_NUMPAD9 = $69;
    VK_NONCONVERT = $1D;
    VK_O = $4F;
    VK_OEM_1 = $BA;
    VK_OEM_2 = $BF;
    VK_OEM_3 = $C0;
    VK_OEM_4 = $DB;
    VK_OEM_5 = $DC;
    VK_OEM_6 = $DD;
    VK_OEM_7 = $DE;
    VK_OEM_8 = $DF;
    VK_OEM_102 = $E2;
    VK_OEM_ATTN = $F0;
    VK_OEM_AUTO = $F3;
    VK_OEM_AX = $E1;
    VK_OEM_BACKTAB = $F5;
    VK_OEM_CLEAR = $FE;
    VK_OEM_COMMA = $BC;
    VK_OEM_COPY = $F2;
    VK_OEM_CUSEL = $EF;
    VK_OEM_ENLW = $F4;
    VK_OEM_FINISH = $F1;
    VK_OEM_JUMP = $EA;
    VK_OEM_MINUS = $BD;
    VK_OEM_PA1 = $EB;
    VK_OEM_PA2 = $EC;
    VK_OEM_PA3 = $ED;
    VK_OEM_PERIOD = $BE;
    VK_OEM_PLUS = $BB;
    VK_OEM_RESET = $E9;
    VK_OEM_WSCTRL = $EE;
    VK_P = $50;
    VK_PA1 = $FD;
    VK_PACKET = $E7;
    VK_PAINT = $2A;
    VK_PAUSE = $13;
    VK_PLAY = $FA;
    VK_PRIOR = $21;
    VK_PROCESSKEY = $E5;
    VK_Q = $51;
    VK_R = $52;
    VK_RBUTTON = $2;
    VK_RCONTROL = $A3;
    VK_RETURN = $D;
    VK_RIGHT = $27;
    VK_RMENU = $A5;
    VK_RSHIFT = $A1;
    VK_RWIN = $5C;
    VK_S = $53;
    VK_SELECT = $29;
    VK_SEPARATOR = $6C;
    VK_SCROLL = $91;
    VK_SHIFT = $10;
    VK_SLEEP = $5F;
    VK_SNAPSHOT = $2C;
    VK_SPACE = $20;
    VK_SUBTRACT = $6D;
    VK_T = $54;
    VK_TAB = $9;
    VK_U = $55;
    VK_UP = $26;
    VK_V = $56;
    VK_VOLUME_DOWN = $AE;
    VK_VOLUME_MUTE = $AD;
    VK_VOLUME_UP = $AF;
    VK_W = $57;
    VK_X = $58;
    VK_XBUTTON1 = $5;
    VK_XBUTTON2 = $6;
    VK_Y = $59;
    VK_Z = $5A;
    VK_ZOOM = $FB;
    WA_ACTIVATE = $1;
    WA_CLICKACTIVATE = $2;
    WA_INACTIVATE = $0;
    WM_ACTIVATE = $6;
    WM_ACTIVATEAPP = $1C;
    WM_APP = $8000;                                         // ～ $BFFF
    WM_ASKCBFORMATNAME = $30C;
    WM_CANCELJOURNAL = $4B;
    WM_CANCELMODE = $1F;
    WM_CAPTURECHANGED = $215;
    WM_CHANGECBCHAIN = $30D;
    WM_CHAR = $102;
    WM_CHARTOITEM = $2F;
    WM_CHILDACTIVATE = $22;
    WM_CLEAR = $303;
    WM_CLIPBOARDUPDATE = $31D;                              // Windows Vista
    WM_CLOSE = $10;
    WM_COMMAND = $111;
    WM_COMMNOTIFY = $44;
    WM_COMPACTING = $41;
    WM_COMPAREITEM = $39;
    WM_CONVERTREQUESTEX = $108;
    WM_COPY = $301;
    WM_COPYDATA = $4A;
    WM_COPYGLOBALDATA = $49;
    WM_CREATE = $1;
    WM_CTLCOLORBTN = $135;
    WM_CTLCOLORDLG = $136;
    WM_CTLCOLOREDIT = $133;
    WM_CTLCOLORLISTBOX = $134;
    WM_CTLCOLORMSGBOX = $132;
    WM_CTLCOLORSCROLLBAR = $137;
    WM_CTLCOLORSTATIC = $138;
    WM_CUT = $300;
    WM_DDE_FIRST = $3E0;
    WM_DEADCHAR = $103;
    WM_DELETEITEM = $2D;
    WM_DESTROY = $2;
    WM_DESTROYCLIPBOARD = $307;
    WM_DEVMODECHANGE = $1B;
    WM_DISPLAYCHANGE = $7E;
    WM_DRAWCLIPBOARD = $308;
    WM_DRAWITEM = $2B;
    WM_DROPFILES = $233;
    WM_DWMCOLORIZATIONCOLORCHANGED = $320;
    WM_DWMCOMPOSITIONCHANGED = $31E;                        // Windows Vista
    WM_DWMNCRENDERINGCHANGED = $31F;                        // Windows Vista
    WM_DWMSENDICONICLIVEPREVIEWBITMAP = $326;               // Windows 7
    WM_DWMSENDICONICTHUMBNAIL = $323;                       // Windows 7
    WM_DWMWINDOWMAXIMIZEDCHANGE = $321;                     // Windows Vista
    WM_ENABLE = $A;
    WM_ENDSESSION = $16;
    WM_ENTERIDLE = $121;
    WM_ENTERMENULOOP = $211;
    WM_ERASEBKGND = $14;
    WM_EXITHELPMODE = $367;
    WM_EXITMENULOOP = $212;
    WM_EXITSIZEMOVE = $232;
    WM_FLOATSTATUS = $36D;
    WM_FONTCHANGE = $1D;
    WM_GESTURE = $119;                                      // Windows 7
    WM_GESTURENOTIFY = $11A;                                // Windows 7
    WM_GETDLGCODE = $87;
    WM_GETFONT = $31;
    WM_GETHOTKEY = $33;
    WM_GETMINMAXINFO = $24;
    WM_GETTEXT = $D;
    WM_GETTEXTLENGTH = $E;
    WM_GETTITLEBARINFOEX = $33F;                            // Windows Vista
    WM_HELP = $53;                                          // Windows XP
    WM_HOTKEY = $312;
    WM_HSCROLL = $114;
    WM_HSCROLLCLIPBOARD = $30E;
    WM_ICONERASEBKGND = $27;
    WM_IME_CHAR = $286;
    WM_IME_COMPOSITION = $10F;
    WM_IME_COMPOSITIONFULL = $284;
    WM_IME_CONTROL = $283;
    WM_IME_ENDCOMPOSITION = $10E;
    WM_IME_KEYDOWN = $290;
    WM_IME_KEYLAST = $10F;
    WM_IME_KEYUP = $291;
    WM_IME_NOTIFY = $282;
    WM_IME_SELECT = $285;
    WM_IME_SETCONTEXT = $281;
    WM_IME_STARTCOMPOSITION = $10D;
    WM_INITDIALOG = $110;
    WM_INITMENU = $116;
    WM_INITMENUPOPUP = $117;
    WM_INPUT = $FF;                                         // Windows XP
    WM_INPUT_DEVICE_CHANGE = $FE;                           // Windows Vista
    WM_KEYDOWN = $100;
    WM_KEYFIRST = $100;
    WM_KEYLAST = $109;
    WM_KEYUP = $101;
    WM_KILLFOCUS = $8;
    WM_LBUTTONDBLCLK = $203;
    WM_LBUTTONDOWN = $201;
    WM_LBUTTONUP = $202;
    WM_MBUTTONDBLCLK = $209;
    WM_MBUTTONDOWN = $207;
    WM_MBUTTONUP = $208;
    WM_MDIACTIVATE = $222;
    WM_MDICASCADE = $227;
    WM_MDICREATE = $220;
    WM_MDIDESTROY = $221;
    WM_MDIGETACTIVE = $229;
    WM_MDIICONARRANGE = $228;
    WM_MDIMAXIMIZE = $225;
    WM_MDINEXT = $224;
    WM_MDIREFRESHMENU = $234;
    WM_MDIRESTORE = $223;
    WM_MDISETMENU = $230;
    WM_MDITILE = $226;
    WM_MEASUREITEM = $2C;
    WM_MENUCHAR = $120;
    WM_MENUCOMMAND = $126;
    WM_MENUDRAG = $123;
    WM_MENUGETOBJECT = $124;
    WM_MENURBUTTONUP = $122;
    WM_MENUSELECT = $11F;
    WM_MOUSEACTIVATE = $21;
    WM_MOUSEFIRST = $200;
    WM_MOUSEHOVER = $2A1;
    WM_MOUSELAST = $20E;
    WM_MOUSELEAVE = $2A3;
    WM_MOUSEMOVE = $200;
    WM_MOUSEWHEEL = $20A;
    WM_MOVE = $3;
    WM_NCACTIVATE = $86;
    WM_NCCALCSIZE = $83;
    WM_NCCREATE = $81;
    WM_NCDESTROY = $82;
    WM_NCHITTEST = $84;
    WM_NCLBUTTONDBLCLK = $A3;
    WM_NCLBUTTONDOWN = $A1;
    WM_NCLBUTTONUP = $A2;
    WM_NCMBUTTONDBLCLK = $A9;
    WM_NCMBUTTONDOWN = $A7;
    WM_NCMBUTTONUP = $A8;
    WM_NCMOUSEHOVER = $2A0;
    WM_NCMOUSELEAVE = $2A2;
    WM_NCMOUSEMOVE = $A0;
    WM_NCPAINT = $85;
    WM_NCRBUTTONDBLCLK = $A6;
    WM_NCRBUTTONDOWN = $A4;
    WM_NCRBUTTONUP = $A5;
    WM_NCXBUTTONDBLCLK = $AD;
    WM_NCXBUTTONDOWN = $AB;
    WM_NCXBUTTONUP = $AC;
    WM_NEXTDLGCTL = $28;
    WM_NULL = $0;
    WM_OTHERWINDOWCREATED = $42;
    WM_OTHERWINDOWDESTROYED = $43;
    WM_PAINT = $F;
    WM_PAINTCLIPBOARD = $309;
    WM_PAINTICON = $26;
    WM_PALETTECHANGED = $311;
    WM_PALETTEISCHANGING = $310;
    WM_PARENTNOTIFY = $210;
    WM_PASTE = $302;
    WM_PENWINFIRST = $380;
    WM_PENWINLAST = $38F;
    WM_POWER = $48;
    WM_POWERBROADCAST = $218;
    WM_QUERYDRAGICON = $37;
    WM_QUERYENDSESSION = $11;
    WM_QUERYNEWPALETTE = $30F;
    WM_QUERYOPEN = $13;
    WM_QUEUESYNC = $23;
    WM_QUIT = $12;
    WM_RBUTTONDBLCLK = $206;
    WM_RBUTTONDOWN = $204;
    WM_RBUTTONUP = $205;
    WM_RENDERALLFORMATS = $306;
    WM_RENDERFORMAT = $305;
    WM_SETCURSOR = $20;
    WM_SETFOCUS = $7;
    WM_SETFONT = $30;
    WM_SETHOTKEY = $32;
    WM_SETREDRAW = $B;
    WM_SETTEXT = $C;
    WM_SETTINGCHANGE = $1A;
    WM_SHOWWINDOW = $18;
    WM_SIZE = $5;
    WM_SIZECLIPBOARD = $30B;
    WM_SPOOLERSTATUS = $2A;
    WM_SYNCPAINT = $88;
    WM_SYSCHAR = $106;
    WM_SYSCOLORCHANGE = $15;
    WM_SYSCOMMAND = $112;
    WM_SYSDEADCHAR = $107;
    WM_SYSKEYDOWN = $104;
    WM_SYSKEYUP = $105;
    WM_TABLET_DEFBASE = $2C0;                               // Windows XP
    WM_TABLET_ADDED = WM_TABLET_DEFBASE + 8;                // Windows XP
    WM_TABLET_DELETED = WM_TABLET_DEFBASE + 9;              // Windows XP
    WM_TABLET_FLICK = WM_TABLET_DEFBASE + 11;               // Windows Vista
    WM_TABLET_QUERYSYSTEMGESTURESTATUS = WM_TABLET_DEFBASE + 12; // Windows Vista
    WM_TCARD = $52;                                         // Windows XP
    WM_THEMECHANGED = $31A;                                 // Windows XP
    WM_TIMECHANGE = $1E;
    WM_TIMER = $113;
    WM_TOUCH = $240;                                        // Windows 7
    WM_UAHDRAWMENU = $91;
    WM_UAHDRAWMENUITEM = $92;
    WM_UAHDESTROYWINDOW = $90;
    WM_UAHINITMENU = $93;
    WM_UAHMEASUREMENUITEM = $94;
    WM_UAHNCPAINTMENUPOPUP = $95;
    WM_UNICHAR = $109;                                      // Windows XP
    WM_UNINITMENUPOPUP = $125;
    WM_UNDO = $304;
    WM_USER = $400;                                         // ～ $7FFF
    WM_USERCHANGED = $54;                                   // Windows XP
    WM_VKEYTOITEM = $2E;
    WM_VSCROLL = $115;
    WM_VSCROLLCLIPBOARD = $30A;
    WM_WINDOWPOSCHANGED = $47;
    WM_WINDOWPOSCHANGING = $46;
    WM_WININICHANGE = $1A;
    WM_XBUTTONDBLCLK = $20D;
    WM_XBUTTONDOWN = $20B;
    WM_XBUTTONUP = $20C;
    WM_WTSSESSION_CHANGE = $2B1;                            // Windows XP
    WM_CHOOSEFONT_GETLOGFONT = WM_USER + 1;
    WM_CHOOSEFONT_SETFLAGS = WM_USER + 102;
    WM_CHOOSEFONT_SETLOGFONT = WM_USER + 101;
    WM_DDE_ACK = WM_DDE_FIRST + 4;
    WM_DDE_ADVISE = WM_DDE_FIRST + 2;
    WM_DDE_DATA = WM_DDE_FIRST + 5;
    WM_DDE_EXECUTE = WM_DDE_FIRST + 8;
    WM_DDE_INITIATE = WM_DDE_FIRST;
    WM_DDE_LAST = WM_DDE_FIRST + 8;
    WM_DDE_POKE = WM_DDE_FIRST + 7;
    WM_DDE_REQUEST = WM_DDE_FIRST + 6;
    WM_DDE_TERMINATE = WM_DDE_FIRST + 1;
    WM_DDE_UNADVISE = WM_DDE_FIRST + 3;
    WM_PSD_ENVSTAMPRECT = WM_USER + 5;
    WM_PSD_FULLPAGERECT = WM_USER + 1;
    WM_PSD_GREEKTEXTRECT = WM_USER + 4;
    WM_PSD_MARGINRECT = WM_USER + 3;
    WM_PSD_MINMARGINRECT = WM_USER + 2;
    WM_PSD_PAGESETUPDLG = WM_USER;
    WM_PSD_YAFULLPAGERECT = WM_USER + 6;
    WS_BORDER = $800000;
    WS_CAPTION = $C00000;
    WS_CHILD = $40000000;
    WS_CHILDWINDOW = $40000000;
    WS_CLIPCHILDREN = $2000000;
    WS_CLIPSIBLINGS = $4000000;
    WS_DISABLED = $8000000;
    WS_DLGFRAME = $400000;
    WS_EX_ACCEPTFILES = $10;
    WS_EX_APPWINDOW = $40000;
    WS_EX_CLIENTEDGE = $200;
    WS_EX_CONTEXTHELP = $400;
    WS_EX_CONTROLPARENT = $10000;
    WS_EX_DLGMODALFRAME = $1;
    WS_EX_LEFT = $0;
    WS_EX_LEFTSCROLLBAR = $4000;
    WS_EX_LTRREADING = $0;
    WS_EX_MDICHILD = $40;
    WS_EX_NOPARENTNOTIFY = $4;
    WS_EX_RIGHT = $1000;
    WS_EX_RIGHTSCROLLBAR = $0;
    WS_EX_RTLREADING = $2000;
    WS_EX_STATICEDGE = $20000;
    WS_EX_TOOLWINDOW = $80;
    WS_EX_TOPMOST = $8;
    WS_EX_TRANSPARENT = $20;
    WS_EX_WINDOWEDGE = $100;
    WS_GROUP = $20000;
    WS_HSCROLL = $100000;
    WS_ICONIC = $20000000;
    WS_MAXIMIZE = $1000000;
    WS_MAXIMIZEBOX = $10000;
    WS_MINIMIZE = $20000000;
    WS_MINIMIZEBOX = $20000;
    WS_OVERLAPPED = $0;
    WS_POPUP = $80000000;
    WS_SIZEBOX = $40000;
    WS_SYSMENU = $80000;
    WS_TABSTOP = $10000;
    WS_THICKFRAME = $40000;
    WS_TILED = $0;
    WS_VISIBLE = $10000000;
    WS_VSCROLL = $200000;

    // BUTTON クラス
    DT_BUTTOM = $8;
    DT_CALCRECT = $400;
    DT_CENTER = $1;
    DT_EDITCONTROL = $2000;
    DT_END_ELLIPSIS = $8000;
    DT_EXPANDTABS = $40;
    DT_EXTERNALLEADING = $200;
    DT_LEFT = $0;
    DT_HIDEPREFIX = $100000;
    DT_INTERNAL = $1000;
    DT_MODIFYSTRING = $10000;
    DT_NOCLIP = $100;
    DT_NOFULLWIDTHCHARBREAK = $80000;
    DT_NOPREFIX = $800;
    DT_PATH_ELLIPSIS = $4000;
    DT_PREFIXONLY = $200000;
    DT_RIGHT = $2;
    DT_RTLREADING = $20000;
    DT_SINGLELINE = $20;
    DT_TABSTOP = $80;
    DT_TOP = $0;
    DT_VCENTER = $4;
    DT_WORDBREAK = $10;
    DT_WORD_ELLIPSIS = $40000;
    ODA_DRAWENTIRE = $1;
    ODA_FOCUS = $4;
    ODA_SELECT = $2;
    ODT_BUTTON = 4;
    ODT_COMBOBOX = 3;
    ODT_HEADER = 100;
    ODT_LISTBOX = 2;
    ODT_LISTVIEW = 102;
    ODT_MENU = 1;
    ODT_STATIC = 5;
    ODT_TAB = 101;
    ODS_CHECKED = $8;
    ODS_COMBOBOXEDIT = $1000;
    ODS_DEFAULT = $20;
    ODS_DISABLED = $4;
    ODS_FOCUS = $10;
    ODS_GRAYED = $2;
    ODS_HOTLIGHT = $40;
    ODS_INACTIVE = $80;
    ODS_NOACCEL = $100;
    ODS_NOFOCUSRECT = $200;
    ODS_SELECTED = $1;

    // MAINWINDOW クラス
    ABOVE_NORMAL_PRIORITY_CLASS = $8000;
    BELOW_NORMAL_PRIORITY_CLASS = $4000;
    HIGH_PRIORITY_CLASS = $80;
    IDLE_PRIORITY_CLASS = $40;
    NORMAL_PRIORITY_CLASS = $20;
    REALTIME_PRIORITY_CLASS = $100;

    BLACKNESS = $00000042;
    DSTINVERT = $00550009;
    MERGECOPY = $00C000CA;
    MERGEPAINT = $00BB0226;
    NOTSRCCOPY = $00330008;
    NOTSRCERASE = $001100A6;
    PATCOPY = $00F00021;
    PATINVERT = $005A0049;
    PATPAINT = $00FB0A09;
    SRCAND = $008800C6;
    SRCCOPY = $00CC0020;
    SRCERASE = $00440328;
    SRCINVERT = $00660046;
    SRCPAINT = $00EE0086;
    WHITENESS = $00FF0062;

    CALLBACK_EVENT = $00050000;
    CALLBACK_FUNCTION = $00030000;
    CALLBACK_NULL = $00000000;
    CALLBACK_TASK = $00020000;
    CALLBACK_THREAD = CALLBACK_TASK;
    CALLBACK_TYPEMASK = $00070000;
    CALLBACK_WINDOW = $00010000;

    CF_BITMAP = 2;
    CF_DIB = 8;
    CF_DIF = 5;
    CF_ENHMETAFILE = 14;
    CF_HDROP = 15;
    CF_LOCALE = 16;
    CF_MAX = 17;
    CF_METAFILEPICT = 3;
    CF_OEMTEXT = 7;
    CF_PALETTE = 9;
    CF_PENDATA = 10;
    CF_RIFF = 11;
    CF_SYLK = 4;
    CF_TEXT = 1;
    CF_TIFF = 6;
    CF_UNICODETEXT = 13;
    CF_WAVE = 12;

    CHECKSUM_MAP_FAILURE = 2;
    CHECKSUM_MAPVIEW_FAILURE = 3;
    CHECKSUM_OPEN_FAILURE = 1;
    CHECKSUM_SUCCESS = 0;
    CHECKSUM_UNICODE_FAILURE = 4;

    CP_ACP = 0;
    CP_MACCP = 2;
    CP_OEMCP = 1;
    CP_SYMBOL = 42;
    CP_THREAD_ACP = 3;
    CP_UTF7 = 65000;
    CP_UTF8 = 65001;

    DATA_S_SAMEFORMATETC = $00040130;
    DRAGDROP_S_DROP = $00040100;
    DRAGDROP_S_CANCEL = $00040101;
    DRAGDROP_S_USEDEFAULTCURSORS = $00040102;
    DRAGDROP_E_NOTREGISTERED = $80040100;
    DRAGDROP_E_ALREADYREGISTERED = $80040101;
    DRAGDROP_E_INVALIDHWND = $80040102;
    DROPEFFECT_COPY = $1;
    DROPEFFECT_LINK = $4;
    DROPEFFECT_MOVE = $2;
    DROPEFFECT_NONE = $0;
    DROPEFFECT_SCROLL = $80000000;

    DV_E_CLIPFORMAT = $8004006A;
    DV_E_DVASPECT = $8004006B;
    DV_E_DVTARGETDEVICE = $80040065;
    DV_E_DVTARGETDEVICE_SIZE = $8004006C;
    DV_E_FORMATETC = $80040064;
    DV_E_LINDEX = $80040068;
    DV_E_STATDATA = $80040067;
    DV_E_STGMEDIUM = $80040066;
    DV_E_TYMED = $80040069;
    DVASPECT_CONTENT = $1;
    DVASPECT_DOCPRINT = $8;
    DVASPECT_ICON = $4;
    DVASPECT_THUMBNAIL = $2;

    E_ABORT = $80004004;
    E_ACCESSDENIED = $80070005;
    E_FAIL = $80004005;
    E_HANDLE = $80070006;
    E_INVALIDARG = $80070057;
    E_NOINTERFACE = $80004002;
    E_NOTIMPL = $80004001;
    E_OUTOFMEMORY = $8007000E;
    E_POINTER = $80004003;
    E_UNEXPECTED = $8000FFFF;

    ES_AWAYMODE_REQUIRED = $40;
    ES_CONTINUOUS = $80000000;
    ES_DISPLAY_REQUIRED = $2;
    ES_SYSTEM_REQUIRED = $1;
    ES_USER_PRESENT = $4;

    FILE_ATTRIBUTE_ARCHIVE = $00000020;
    FILE_ATTRIBUTE_COMPRESSED = $00000800;
    FILE_ATTRIBUTE_DIRECTORY = $00000010;
    FILE_ATTRIBUTE_ENCRYPTED = $00000040;
    FILE_ATTRIBUTE_HIDDEN = $00000002;
    FILE_ATTRIBUTE_NORMAL = $00000080;
    FILE_ATTRIBUTE_NOT_CONTENT_INDEXED = $00002000;
    FILE_ATTRIBUTE_OFFLINE = $00001000;
    FILE_ATTRIBUTE_READONLY = $00000001;
    FILE_ATTRIBUTE_REPARSE_POINT = $00000400;
    FILE_ATTRIBUTE_SPARSE_FILE = $00000200;
    FILE_ATTRIBUTE_SYSTEM = $00000004;
    FILE_ATTRIBUTE_TEMPORARY = $00000100;
    FILE_BEGIN = $0;
    FILE_CURRENT = $1;
    FILE_END = $2;
    FILE_FLAG_SEQUENTIAL_SCAN = $8000000;
    FILE_SHARE_DELETE = $4;
    FILE_SHARE_READ = $1;
    FILE_SHARE_WRITE = $2;

    GENERIC_READ = $80000000;
    GENERIC_WRITE = $40000000;

    GMEM_FIXED = $0;
    GMEM_MOVEABLE = $2;
    GMEM_ZEROINIT = $40;
    GHND = GMEM_MOVEABLE or GMEM_ZEROINIT;
    GPTR = GMEM_FIXED or GMEM_ZEROINIT;
    INVALID_HANDLE_VALUE = $FFFFFFFF;

    DONT_RESOLVE_DLL_REFERENCES = $1;
    LOAD_IGNORE_CODE_AUTHZ_LEVEL = $10;
    LOAD_LIBRARY_AS_DATAFILE = $2;
    LOAD_LIBRARY_AS_DATAFILE_EXCLUSIVE = $40;
    LOAD_LIBRARY_AS_IMAGE_RESOURCE = $20;
    LOAD_LIBRARY_REQUIRE_SIGNED_TARGET = $80;
    LOAD_LIBRARY_SAFE_CURRENT_DIRS = $2000;
    LOAD_LIBRARY_SEARCH_APPLICATION_DIR = $200;
    LOAD_LIBRARY_SEARCH_DEFAULT_DIRS = $1000;
    LOAD_LIBRARY_SEARCH_DLL_LOAD_DIR = $100;
    LOAD_LIBRARY_SEARCH_SYSTEM32 = $800;
    LOAD_LIBRARY_SEARCH_USER_DIRS = $400;
    LOAD_WITH_ALTERED_SEARCH_PATH = $8;

    CREATE_NEW = $1;
    CREATE_ALWAYS = $2;
    OPEN_EXISTING = $3;
    OPEN_ALWAYS = $4;
    TRUNCATE_EXISTING = $5;

    NOSLEEP_AUTO = $0;
    NOSLEEP_SLEEP = $1;
    NOSLEEP_DISPLAY = $2;

    OLE_E_ADVF = $80040001;
    OLE_E_ADVISENOTSUPPORTED = $80040003;
    OLE_E_BLANK = $80040007;
    OLE_E_CANT_BINDTOSOURCE = $8004000A;
    OLE_E_CANT_GETMONIKER = $80040009;
    OLE_E_CANTCONVERT = $80040011;
    OLE_E_CLASSDIFF = $80040008;
    OLE_E_ENUM_NOMORE = $80040002;
    OLE_E_INVALIDHWND = $8004000F;
    OLE_E_INVALIDRECT = $8004000D;
    OLE_E_NOT_INPLACEACTIVE = $80040010;
    OLE_E_NOCACHE = $80040006;
    OLE_E_NOCONNECTION = $80040004;
    OLE_E_NOSTORAGE = $80040012;
    OLE_E_NOTRUNNING = $80040005;
    OLE_E_OLEVERB = $80040000;
    OLE_E_PROMPTSAVECANCELLED = $8004000C;
    OLE_E_STATIC = $8004000B;
    OLE_E_WRONGCOMPOBJ = $8004000E;

    PROCESS_DUP_HANDLE = $0040;
    PROCESS_CREATE_PROCESS = $0080;
    PROCESS_CREATE_THREAD = $0002;
    PROCESS_SET_QUOTA = $0100;
    PROCESS_SET_INFORMATION = $0200;
    PROCESS_SET_SESSIONID = $0004;
    PROCESS_QUERY_INFORMATION = $0400;
    PROCESS_TERMINATE = $0001;
    PROCESS_VM_OPERATION = $0008;
    PROCESS_VM_READ = $0010;
    PROCESS_VM_WRITE = $0020;

    TYMED_ENHMF = $40;
    TYMED_FILE = $2;
    TYMED_HGLOBAL = $1;
    TYMED_GDI = $10;
    TYMED_ISTORAGE = $8;
    TYMED_ISTREAM = $4;
    TYMED_MFPICT = $20;
    TYMED_NULL = $0;

    VER_PLATFORM_WIN32s = 0;
    VER_PLATFORM_WIN32_WINDOWS = 1;
    VER_PLATFORM_WIN32_NT = 2;

    WAVE_FORMAT_DIRECT = $8;
    WAVE_FORMAT_EXTENSIBLE = $FFFE;
    WAVE_FORMAT_IEEE_FLOAT = $3;
    WAVE_FORMAT_PCM = $1;
    WAVE_FORMAT_QUERY = $1;
    MM_WOM_CLOSE = $3BC;
    MM_WOM_DONE = $3BD;
    MM_WOM_OPEN = $3BB;

{$IFDEF ITASKBARLIST3}
    CLSCTX_INPROC_SERVER = $1;
    CLSCTX_INPROC_HANDLER = $2;
    CLSCTX_LOCAL_SERVER = $4;
    CLSCTX_INPROC_SERVER16 = $8;
    CLSCTX_REMOTE_SERVER = $10;
    CLSCTX_INPROC_HANDLER16 = $20;
    CLSCTX_RESERVED1 = $40;
    CLSCTX_RESERVED2 = $80;
    CLSCTX_RESERVED3 = $100;
    CLSCTX_RESERVED4 = $200;
    CLSCTX_NO_CODE_DOWNLOAD = $400;
    CLSCTX_RESERVED5 = $800;
    CLSCTX_NO_CUSTOM_MARSHAL = $1000;
    CLSCTX_ENABLE_CODE_DOWNLOAD = $2000;
    CLSCTX_NO_FAILURE_LOG = $4000;
    CLSCTX_DISABLE_AAA = $8000;
    CLSCTX_ENABLE_AAA = $10000;
    CLSCTX_FROM_DEFAULT_CONTEXT = $20000;
    CLSCTX_ACTIVATE_32_BIT_SERVER = $40000;
    CLSCTX_ACTIVATE_64_BIT_SERVER = $80000;
    CLSCTX_ENABLE_CLOAKING = $100000;
    CLSCTX_APPCONTAINER = $400000;
    CLSCTX_ACTIVATE_AAA_AS_IU = $800000;
    CLSCTX_PS_DLL = $80000000;
{$ENDIF}

    // SNES SPC700 Player 本体の設定
    DEFAULT_TITLE: string = 'SNES SPC700 Player';
    SPCPLAY_TITLE = '[ SNES SPC700 Player   ]' + CRLF + ' SPCPLAY.EXE v';
    SNESAPU_TITLE = '[ SNES SPC700 Emulator ]' + CRLF + ' SNESAPU.DLL v';
    SPCPLAY_VERSION = '$CAP_FILE_VER';
    SNESAPU_VERSION = $20000; // SNESAPU_VER
    APPLINK_VERSION = $02190400;

    CBE_DSPREG = $1;
    CBE_S700FCH = $2;
    CBE_INCS700 = $40000000;
    CBE_INCDATA = $20000000;
    CBE_REQBP = $10000000;
    SCRIPT700_TEXT = $FFFFFFFF;

    BRKP_NEXT_STOP = $10000000;
    BRKP_STOPPED = $20000000;
    BRKP_RELEASE = $80000000;

{$IFDEF TRANSMITSPC}
    CLASS_NAME: string = 'SSDLabo_SPCPLAY_DEBUG';
{$ELSE}
    CLASS_NAME: string = 'SSDLabo_SPCPLAY';
{$ENDIF}
    SNESAPU_FILE = 'snesapu.dll';
    SPC_FILE_HEADER = 'SNES-SPC700 Sound File Data ';
    SPC_FILE_HEADER_LEN = 28;
    INI_FILE: string = 'spcplay.ini';
    SECTION_USER_POLICY = '[USER POLICY]';
    SECTION_APP_SETTING = '[APP SETTING]';
    BUFFER_LENGTH = 13;
    BUFFER_START = BUFFER_LENGTH + 1;
    BUFFER_AMP_____: string = 'AMP      0 : ';
    BUFFER_BIT_____: string = 'BIT      0 : ';
    BUFFER_BMPFONT_: string = 'BMPFONT  0 : ';
    BUFFER_BPM_____: string = 'BPM      0 : ';
    BUFFER_BUFNUM__: string = 'BUFNUM   2 : ';
    BUFFER_BUFTIME_: string = 'BUFTIME  2 : ';
    BUFFER_CACHEDIF: string = 'CACHEDIF 0 : ';
    BUFFER_CACHEINT: string = 'CACHEINT 0 : ';
    BUFFER_CACHEKON: string = 'CACHEKON 0 : ';
    BUFFER_CACHENUM: string = 'CACHENUM 0 : ';
    BUFFER_CHANNEL_: string = 'CHANNEL  0 : ';
    BUFFER_DEVICE__: string = 'DEVICE   0 : ';
    BUFFER_DEVNAME_: string = 'DEVNAME  0 : ';
    BUFFER_DRAWINFO: string = 'DRAWINFO 0 : ';
    BUFFER_EARSAFE_: string = 'EARSAFE  0 : ';
    BUFFER_FADELENG: string = 'FADELENG 0 : ';
    BUFFER_FEEDBACK: string = 'FEEDBACK 1 : ';
    BUFFER_FONTNAME: string = 'FONTNAME 3 : ';
    BUFFER_HIDELENG: string = 'HIDELENG 0 : ';
    BUFFER_INFO____: string = 'INFO     0 : ';
    BUFFER_INTER___: string = 'INTER    0 : ';
    BUFFER_LANGUAGE: string = 'LANGUAGE 1 : ';
    BUFFER_LEFT____: string = 'LEFT     0 : ';
    BUFFER_LISTHGT_: string = 'LISTHGT  0 : ';
    BUFFER_LISTMAX_: string = 'LISTMAX  0 : ';
    BUFFER_MUTE____: string = 'MUTE     0 : ';
    BUFFER_NEXTLENG: string = 'NEXTLENG 0 : ';
    BUFFER_NOISE___: string = 'NOISE    0 : ';
    BUFFER_NOSLEEP_: string = 'NOSLEEP  0 : ';
    BUFFER_OPTION__: string = 'OPTION   0 : ';
    BUFFER_PITCH___: string = 'PITCH    0 : ';
    BUFFER_PITCHSNC: string = 'PITCHSNC 0 : ';
    BUFFER_PLAYDEF_: string = 'PLAYDEF  0 : ';
    BUFFER_PLAYLENG: string = 'PLAYLENG 0 : ';
    BUFFER_PLAYTIME: string = 'PLAYTIME 0 : ';
    BUFFER_PLAYTYPE: string = 'PLAYTYPE 0 : ';
    BUFFER_PRIORITY: string = 'PRIORITY 0 : ';
    BUFFER_RATE____: string = 'RATE     0 : ';
    BUFFER_SCALE___: string = 'SCALE    0 : ';
    BUFFER_SEEKBAR_: string = 'SEEKBAR  0 : ';
    BUFFER_SEEKFAST: string = 'SEEKFAST 2 : ';
    BUFFER_SEEKMAX_: string = 'SEEKMAX  1 : ';
    BUFFER_SEEKSNC_: string = 'SEEKSNC  0 : ';
    BUFFER_SEEKTIME: string = 'SEEKTIME 1 : ';
    BUFFER_SEPARATE: string = 'SEPARATE 0 : ';
    BUFFER_SHIFTKEY: string = 'SHIFTKEY 0 : ';
    BUFFER_SPEED___: string = 'SPEED    0 : ';
    BUFFER_SPEEDTUN: string = 'SPEEDTUN 0 : ';
    BUFFER_THEME___: string = 'THEME    0 : ';
    BUFFER_TOP_____: string = 'TOP      0 : ';
    BUFFER_TOPMOST_: string = 'TOPMOST  0 : ';
    BUFFER_TOPTDISP: string = 'TOPTDISP 0 : ';
    BUFFER_TOPTLOCK: string = 'TOPTLOCK 0 : ';
    BUFFER_TREDRAW_: string = 'TREDRAW  0 : ';
    BUFFER_VERSION_: string = 'VERSION  0 : ';
    BUFFER_VOLCOLOR: string = 'VOLCOLOR 0 : ';
    BUFFER_VOLRESET: string = 'VOLRESET 0 : ';
    BUFFER_VOLSPEED: string = 'VOLSPEED 2 : ';
    BUFFER_WAITLENG: string = 'WAITLENG 0 : ';
    BUFFER_WAVBLANK: string = 'WAVBLANK 0 : ';
    BUFFER_WAVEFMT_: string = 'WAVEFMT  0 : ';
    FONT_NAME: array[0..1] of string = ('Microsoft Applocale', 'Lucida Console');
    LIST_FILE: string = 'spcplay.stk';
    LIST_FILE_HEADER_A: string = 'SSDLabo Spcplay ListFile v1.0';
    LIST_FILE_HEADER_A_LEN = 29;
    LIST_FILE_HEADER_B: string = 'SPCPLAY PLAYLIST';
    LIST_FILE_HEADER_B_LEN = 16;
    LIST_FILETYPE = 'lst';
    SCRIPT700_FILENAME = '65816.700';
    SCRIPT7SE_FILENAME = '65816.7SE';
    SCRIPT700_FILETYPE = '700';
    SCRIPT7SE_FILETYPE = '7SE';
    SCRIPT700TXT_FILENAME = '65816.700.TXT';
    SCRIPT7SETXT_FILENAME = '65816.7SE.TXT';
    SCRIPT700TXT_FILETYPE = '700.TXT';
    SCRIPT7SETXT_FILETYPE = '7SE.TXT';

{$IFDEF SPCBPMTEST}
    SPC_BPM_FILE = 'spc_bpm.dll';
{$ENDIF}

    BITMAP_NAME = 'MAINBMP';
    ICON_NAME = 'MAINICON';
    FILE_DEFAULT: string = 'FILE TRANSMIT WINDOW';
    DRAG_START_THRESHOLD = 5;
    DRAG_LIMIT_THRESHOLD = 2;
    LIST_ADD_THRESHOLD = 297;
    MIN_WAVE_LEVEL = 65535;
    NO_SLEEP_INTERVAL = 30000;
    WINDOW_MOVE_THRESHOLD = 10;
    WINDOW_WIDTH = 521;
    WINDOW_HEIGHT = 152;

    WM_APP_MESSAGE = $8000;                                 // 通知メッセージ
    WM_APP_COMMAND = $8001;                                 // ユーザコマンド

    WM_APP_TRANSMIT = $00000000;                            // ファイル名転送     ($0000???X, X:AutoPlay, lParam:hWnd)
    WM_APP_ACTIVATE = $00010000;                            // アクティブ         ($0001????)
    WM_APP_REDRAW = $00020000;                              // 再描画             ($0002????)
    WM_APP_SEEK = $00030000;                                // シーク             ($0003????)
    WM_APP_NEXT_PLAY = $00040000;                           // 次の曲を演奏       ($0004????)
    WM_APP_MINIMIZE = $00050000;                            // 最小化要求         ($0005????)
    WM_APP_REPEAT_TIME = $00060000;                         // リピート位置       ($0006????)
    WM_APP_START_TIME = $00061000;                          // リピート開始位置   ($00061???)
    WM_APP_LIMIT_TIME = $00062000;                          // リピート終了位置   ($00062???)
    WM_APP_RESET_TIME = $00063000;                          // リピート位置初期化 ($00063???)
    WM_APP_DRAG_DONE = $00070000;                           // ドラッグ終了       ($0007????)
    WM_APP_UPDATE_INFO = $00080000;                         // 情報更新           ($0008???X, X:Redraw)
    WM_APP_UPDATE_MENU = $00090000;                         // メニュー更新       ($0009????)
    WM_APP_WAVE_OUTPUT = $000A0000;                         // WAVE 書き込み      ($000A??YX, X:Shift, Y:Quiet, lParam:hWnd)
    WM_APP_TRY_RESUME = $000B0000;                          // 演奏再開試行       ($000B????)

    WM_APP_WAVE_PROC = $10000000;                           // WAVE 割り込み      ($1000????)
    WM_APP_SPC_PLAY = $10010000;                            // SPC 演奏開始       ($1001????)
    WM_APP_SPC_PAUSE = $10020000;                           // SPC 一時停止       ($1002????)
    WM_APP_SPC_RESUME = $10030000;                          // SPC 演奏再開       ($1003????)
    WM_APP_SPC_RESET = $10040000;                           // SPC 演奏設定       ($1004????)
    WM_APP_SPC_TIME = $10050000;                            // SPC 時間設定       ($1005????)
    WM_APP_SPC_SEEK = $10060000;                            // SPC シーク         ($1006???X, X:Cache)

    WM_APP_FUNCTION = $F0000000;                            // 機能設定           ($F000???X, X:Type 0 or 2)
    WM_APP_GET_DSP = $F1000000;                             // DSP 読み取り       ($F100??XX, XX:DSP Address)
    WM_APP_SET_DSP = $F1010000;                             // DSP 書き込み       ($F101??XX, XX:DSP Address, lParam:Value)
    WM_APP_GET_PORT = $F1100000;                            // ポート読み取り     ($F110???X, X:PORT Address)
    WM_APP_SET_PORT = $F1110000;                            // ポート書き込み     ($F111???X, X:PORT Address, lParam:Value)
    WM_APP_GET_RAM = $F1200000;                             // RAM 読み取り       ($F120XXXX, XXXX:RAM Address)
    WM_APP_SET_RAM = $F1210000;                             // RAM 書き込み       ($F121XXXX, XXXX:RAM Address, lParam:Value)
    WM_APP_GET_WORK = $F1300000;                            // ワーク読み取り     ($F130???X, X:WORK Address)
    WM_APP_SET_WORK = $F1310000;                            // ワーク書き込み     ($F131???X, X:WORK Address, lParam:Value)
    WM_APP_GET_CMP = $F1400000;                             // 比較値読み取り     ($F140???X, X:CMP Address)
    WM_APP_SET_CMP = $F1410000;                             // 比較値書き込み     ($F141???X, X:CMP Address, lParam:Value)
    WM_APP_GET_SPC = $F1500000;                             // SPC 読み取り       ($F150???X, X:0=PC,1=Y+A,2=SP+X,3=PSW)
    WM_APP_SET_SPC = $F1510000;                             // SPC 書き込み       ($F151???X, X:0=PC,1=Y+A,2=SP+X,3=PSW, lParam:Value)
    WM_APP_HALT = $F1600000;                                // HALT スイッチ      ($F160????, lParam:1=SPC_RETURN, 2=SPC_HALT, 4=DSP_HALT, 8=SPC_NODSP)
    WM_APP_BP_SET = $F4000000;                              // BreakPoint 設定    ($F400XXXX, X=RAM Address, lParam:CBE Flags (0:UNSET))
    WM_APP_BP_CLEAR = $F4010000;                            // BreakPoint 全解除  ($F401????)
    WM_APP_NEXT_TICK = $F4100000;                           // 次の命令で止める   ($F410????, lParam:0=CBE Flags)
    WM_APP_DSP_CHEAT = $F5000000;                           // DSP チート設定     ($F500??XX, XX:DSP Address, lParam:Value (-1:UNSET))
    WM_APP_DSP_THRU = $F5010000;                            // DSP チート全解除   ($F501????)
    WM_APP_GET_MUTE = $F6000000;                            // ミュート取得       ($F60000??)
    WM_APP_SET_MUTE = $F6010000;                            // ミュート設定       ($F60100??)
    WM_APP_STATUS = $FF000000;                              // ステータス取得     ($FF00????)
    WM_APP_APPVER = $FF010000;                              // バージョン取得     ($FF01????)
    WM_APP_EMU_APU = $FFFE0000;                             // 強制エミュレート   ($FFFE????)
    WM_APP_EMU_DEBUG = $FFFF0000;                           // SPC700 転送テスト  ($FFFF???X, X:Flag)

    DRAW_INFO_ALWAYS = $1;                                  // 常に描画

    FILE_TYPE_NOTEXIST = $1;                                // 存在しない
    FILE_TYPE_NOTREAD = $2;                                 // 読み込み不可
    FILE_TYPE_UNKNOWN = $3;                                 // 不明な形式
    FILE_TYPE_SPC = $10;                                    // SPC ファイル
    FILE_TYPE_LIST_A = $11;                                 // プレイリストファイル TYPE-A
    FILE_TYPE_LIST_B = $12;                                 // プレイリストファイル TYPE-B
    FILE_TYPE_FOLDER = $13;                                 // フォルダ
    FILE_TYPE_SCRIPT700 = $14;                              // Script700

    FUNCTION_TYPE_SEPARATE = $1;                            // 左右拡散度
    FUNCTION_TYPE_FEEDBACK = $2;                            // フィードバック反転度
    FUNCTION_TYPE_SPEED = $3;                               // 演奏速度
    FUNCTION_TYPE_AMP = $4;                                 // 音量
    FUNCTION_TYPE_SEEK = $5;                                // シーク
    FUNCTION_TYPE_NO_TIMER = $80000000;                     // タイマー設定なし

    ID666_UNKNOWN = $0;                                     // 不明
    ID666_TEXT = $1;                                        // ID666 テキストフォーマット
    ID666_BINARY = $2;                                      // ID666 バイナリフォーマット

    INFO_INDICATOR = $0;                                    // グラフィックインジケータ
    INFO_MIXER = $1;                                        // ミキサー情報
    INFO_CHANNEL_1 = $2;                                    // チャンネル情報 1
    INFO_CHANNEL_2 = $3;                                    // チャンネル情報 2
    INFO_CHANNEL_3 = $4;                                    // チャンネル情報 3
    INFO_CHANNEL_4 = $5;                                    // チャンネル情報 4
    INFO_SPC_1 = $6;                                        // SPC 情報 1
    INFO_SPC_2 = $7;                                        // SPC 情報 2
    INFO_SCRIPT700 = $8;                                    // Script700 デバッグ

    LIST_PLAY_INDEX_SELECTED = -1;                          // プレイリスト選択済みアイテム
    LIST_PLAY_INDEX_RANDOM = -2;                            // プレイリストからランダム選択
    LIST_NEXT_PLAY_SELECT = $10000;                         // プレイリストからアイテム選択
    LIST_NEXT_PLAY_CENTER = $20000;                         // プレイリスト中央選択

    PLAY_TYPE_AUTO = $0;                                    // 演奏自動選択
    PLAY_TYPE_PLAY = $1;                                    // 演奏開始
    PLAY_TYPE_PAUSE = $2;                                   // 一時停止
    PLAY_TYPE_LIST = $3;                                    // プレイリストからアイテム選択
    PLAY_TYPE_RANDOM = $4;                                  // プレイリストからランダム選択

    PLAY_MAX_ENDLESS = $0;                                  // エンドレス
    PLAY_MAX_ID666 = $1;                                    // ID666 設定時間を優先
    PLAY_MAX_DEFAULT = $2;                                  // デフォルト演奏時間を優先

    PLAY_ORDER_STOP = $0;                                   // 停止
    PLAY_ORDER_NEXT = $1;                                   // 次へ
    PLAY_ORDER_PREVIOUS = $2;                               // 前へ
    PLAY_ORDER_RANDOM = $3;                                 // ランダム
    PLAY_ORDER_SHUFFLE = $4;                                // シャッフル
    PLAY_ORDER_REPEAT = $5;                                 // リピート
    PLAY_ORDER_FIRST = $6;                                  // 最初から
    PLAY_ORDER_LAST = $7;                                   // 最後から

    READY_INITIALIZE = $0;                                  // 初期化中
    READY_ACTIVE = $1;                                      // 実行中
    READY_INACTIVE = $2;                                    // 表示停止中

    REDRAW_OFF = $0;                                        // 再描画なし
    REDRAW_LOCK_CRITICAL = $1;                              // 描画ロック (強制)
    REDRAW_LOCK_READY = $2;                                 // 描画ロック (次回描画許可)
    REDRAW_ON = $4;                                         // 再描画あり

    STATIC_SEEKBAR_TOP = 24;                                // シークバー検出位置 (上)
    STATIC_SEEKBAR_BOTTOM = 35;                             // シークバー検出位置 (下)

    STATUS_OPEN = $1;                                       // Open フラグ
    STATUS_PLAY = $2;                                       // Play フラグ
    STATUS_PAUSE = $4;                                      // Pause フラグ

    TIMER_ID_READY = $1;                                    // 準備完了
    TIMER_ID_OPTION_DISPLAY = $2;                           // オプション情報表示
    TIMER_ID_OPTION_LOCK = $3;                              // オプション変更ロック
    TIMER_ID_REDRAW_RESUME = $4;                            // サスペンド復帰後のウィンドウ再描画
    TIMER_INTERVAL_READY = 0;                               // 準備完了までの遅延時間
    TIMER_INTERVAL_OPTION_DISPLAY = 1000;                   // オプション情報表示の時間
    TIMER_INTERVAL_OPTION_LOCK = 300;                       // オプション変更ロックの時間
    TIMER_INTERVAL_REDRAW_RESUME = 1000;                    // サスペンド復帰後のウィンドウ再描画の時間

    TITLE_HIDE = $0;                                        // 非表示
    TITLE_NORMAL = $100;                                    // 標準
    TITLE_MINIMIZE = $200;                                  // 最小化
    TITLE_ALWAYS_FLAG = $FF00;                              // 標準 + 最小化
    TITLE_INFO_SEPARATE = $1;                               // 左右拡散度
    TITLE_INFO_FEEDBACK = $2;                               // フィードバック反転度
    TITLE_INFO_SPEED = $3;                                  // 演奏速度
    TITLE_INFO_AMP = $4;                                    // 音量
    TITLE_INFO_SEEK = $5;                                   // シーク

    THEME_DEFAULT = $0;                                     // デフォルト
    THEME_DARK = $1;                                        // ダークモード

    WAVE_DEVICE_SET_ONLY = $0;                              // デバイス ID 選択のみ
    WAVE_DEVICE_UPDATE_LIST = $1;                           // デバイス一覧を更新
    WAVE_DEVICE_UPDATE_SELECT = $2;                         // 選択デバイスを更新
    WAVE_DEVICE_INITIALIZE = $3;                            // 初期化

    WAVE_FORMAT_TYPE_SIZE = 2;
    WAVE_FORMAT_TYPE_ARRAY: array[0..WAVE_FORMAT_TYPE_SIZE - 1] of longword = (WAVE_FORMAT_DIRECT, NULL);
    WAVE_FORMAT_TAG_SIZE = 2;
    WAVE_FORMAT_TAG_ARRAY: array[0..WAVE_FORMAT_TAG_SIZE - 1] of word = (WAVE_FORMAT_EXTENSIBLE, WAVE_FORMAT_PCM);
    WAVE_FORMAT_INDEX_EXTENSIBLE = 0;
    WAVE_FORMAT_INDEX_PCM = 1;

    WAVE_PROC_GRAPH_ONLY = $0;                              // インジケータのみ描画
    WAVE_PROC_NO_GRAPH = $FFFF;                             // インジケータを描画しない
    WAVE_PROC_WRITE_WAVE = $10000;                          // サウンドバッファ書き込み
    WAVE_PROC_WRITE_INIT = $20000;                          // 再生時の初期化

    WAVE_MESSAGE_MAX_COUNT = 1;                             // WAVE メッセージ最大送信数

    WAVE_THREAD_SUSPEND = $0;                               // 停止状態
    WAVE_THREAD_RUNNING = $1;                               // 実行状態
    WAVE_THREAD_DEVICE_OPENED = $2;                         // デバイスのオープン完了
    WAVE_THREAD_DEVICE_CLOSED = $4;                         // デバイスのクローズ完了

    COLOR_BAR_NUM = 6;                                      // インジケータバーの数
    COLOR_BAR_NUM_X3 = 18;
    COLOR_BAR_NUM_X7 = 42;
    COLOR_BAR_WIDTH = 7;                                    // インジケータバーの最大幅
    COLOR_BAR_TOP = 48;                                     // インジケータバーの描画位置
    COLOR_BAR_TOP_FRAME = 45;                               // フレームの描画位置
    COLOR_BAR_HEIGHT = 48;                                  // インジケータバーの高さ
    COLOR_BAR_HEIGHT_M1 = 47;
    COLOR_BAR_HEIGHT_X2 = 96;
    COLOR_START_R: array[0..COLOR_BAR_NUM_X3 - 1] of byte = (  0, 172,   0, 172,   0, 102,   0, 224,   0, 212,   0, 120, 132, 255, 128, 255, 172, 224);
    COLOR_START_G: array[0..COLOR_BAR_NUM_X3 - 1] of byte = (128,  80,  96,   0,   0,   0, 164, 112, 112,   0,   0,   0, 255, 192, 208, 136, 168, 144);
    COLOR_START_B: array[0..COLOR_BAR_NUM_X3 - 1] of byte = (  0,   0, 212,   0, 240, 240,   0,   0, 224,   0, 240, 240, 128, 128, 255, 140, 255, 255);
    COLOR_END_R:   array[0..COLOR_BAR_NUM_X3 - 1] of byte = (  0, 128,   0,  96,   0,  58,   0, 160,   0, 112,   0,  64,  52, 172,  48, 192,  68, 104);
    COLOR_END_G:   array[0..COLOR_BAR_NUM_X3 - 1] of byte = ( 64,  48,  64,   0,   0,   0,  96,  80,  80,   0,   0,   0, 106, 106, 128,  36,  64,  48);
    COLOR_END_B:   array[0..COLOR_BAR_NUM_X3 - 1] of byte = (  0,   0, 160,   0, 128, 128,   0,   0, 160,   0, 128, 128,  48,  52, 164,  40, 192, 154);

    COLOR_BRIGHT_FORE = 127500;                             // 文字色の明るさの閾値
    COLOR_BRIGHT_BACK = 180000;                             // 背景色の明るさの閾値

    COLOR_BAR_GREEN = 0;                                    // 緑
    COLOR_BAR_ORANGE = 7;                                   // オレンジ
    COLOR_BAR_WATER = 14;                                   // 水色
    COLOR_BAR_RED = 21;                                     // 赤
    COLOR_BAR_BLUE = 28;                                    // 青
    COLOR_BAR_PURPLE = 35;                                  // 紫

    COLOR_DARK_BACK = $1C1C1C;                              // ダークモードの背景色
    COLOR_DARK_DISABLED = $6D6D6D;                          // ダークモードの文字色 (無効)
    COLOR_DARK_INACTIVE = $949494;                          // ダークモードの文字色 (非アクティブ)
    COLOR_DARK_LIGHT = $FFFFFF;                             // ダークモードの文字色 (ハイライト)
    COLOR_DARK_MENU = $2C2C2C;                              // ダークモードのメニュー背景色
    COLOR_DARK_TEXT = $ECECEC;                              // ダークモードの文字色

    ORG_COLOR_BAR_GREEN = $10000 or COLOR_BAR_GREEN;        // 緑
    ORG_COLOR_BAR_ORANGE = $10000 or COLOR_BAR_ORANGE;      // オレンジ
    ORG_COLOR_BAR_WATER = $10000 or COLOR_BAR_WATER;        // 水色
    ORG_COLOR_BAR_RED = $10000 or COLOR_BAR_RED;            // 赤
    ORG_COLOR_BAR_BLUE = $10000 or COLOR_BAR_BLUE;          // 青
    ORG_COLOR_BAR_PURPLE = $10000 or COLOR_BAR_PURPLE;      // 紫

    ORG_COLOR_BTNFACE = COLOR_BTNFACE + 1;                  // ボタンの背景色
    ORG_COLOR_BTNSHADOW = COLOR_BTNSHADOW + 1;              // ボタンの枠線色
    ORG_COLOR_BTNTEXT = COLOR_BTNTEXT + 1;                  // ボタンの文字色
    ORG_COLOR_GRAYTEXT = COLOR_GRAYTEXT + 1;                // 無効時の文字色
    ORG_COLOR_HIGHLIGHT = COLOR_HIGHLIGHT + 1;              // 項目の選択色
    ORG_COLOR_WINDOWTEXT = COLOR_WINDOWTEXT + 1;            // 有効時の文字色

    BITMAP_NUM = 53;                                        // ビットマップ文字の数
    BITMAP_NUM_WIDTH = 6;                                   // ビットマップ文字の幅
    BITMAP_NUM_HEIGHT = 9;                                  // ビットマップ文字の高さ
    BITMAP_NUM_FONT = 2;                                    // 数値フォントのパターン数
    BITMAP_NUM_X6 = BITMAP_NUM * BITMAP_NUM_WIDTH;
    BITMAP_NUM_X6P6 = BITMAP_NUM_X6 + BITMAP_NUM_WIDTH;
    BITMAP_NUM_HEX_X6 = 16 * BITMAP_NUM_WIDTH;
    BITMAP_MARK_HEIGHT = 3;                                 // 位置マークの高さ
    BITMAP_STRING_COLOR_LIGHT: array[0..BITMAP_NUM - 1] of longword =
        (ORG_COLOR_WINDOWTEXT, ORG_COLOR_WINDOWTEXT, ORG_COLOR_WINDOWTEXT, ORG_COLOR_WINDOWTEXT, ORG_COLOR_WINDOWTEXT, ORG_COLOR_WINDOWTEXT,
         ORG_COLOR_WINDOWTEXT, ORG_COLOR_WINDOWTEXT, ORG_COLOR_WINDOWTEXT, ORG_COLOR_WINDOWTEXT, ORG_COLOR_WINDOWTEXT, ORG_COLOR_WINDOWTEXT,
         ORG_COLOR_WINDOWTEXT, ORG_COLOR_WINDOWTEXT, ORG_COLOR_WINDOWTEXT, ORG_COLOR_WINDOWTEXT, ORG_COLOR_WINDOWTEXT, ORG_COLOR_WINDOWTEXT,
         ORG_COLOR_BAR_GREEN , ORG_COLOR_BAR_WATER , ORG_COLOR_BAR_ORANGE, ORG_COLOR_BAR_RED   , ORG_COLOR_BAR_BLUE  , ORG_COLOR_BAR_PURPLE,
         ORG_COLOR_BAR_BLUE  , ORG_COLOR_BAR_BLUE  , ORG_COLOR_BAR_BLUE  , ORG_COLOR_BAR_BLUE  , ORG_COLOR_BAR_BLUE  , ORG_COLOR_BAR_BLUE  ,
         ORG_COLOR_BAR_RED   , ORG_COLOR_GRAYTEXT  , ORG_COLOR_BAR_RED   , ORG_COLOR_BAR_RED   , ORG_COLOR_BAR_BLUE  , ORG_COLOR_BAR_BLUE  ,
         ORG_COLOR_BAR_ORANGE, ORG_COLOR_BAR_GREEN , ORG_COLOR_BAR_RED   , ORG_COLOR_BAR_BLUE  , ORG_COLOR_BAR_ORANGE, ORG_COLOR_BAR_GREEN ,
         ORG_COLOR_BAR_WATER , ORG_COLOR_BAR_RED   , ORG_COLOR_BAR_BLUE  , ORG_COLOR_BAR_ORANGE, ORG_COLOR_BAR_RED   , ORG_COLOR_BAR_WATER ,
         ORG_COLOR_BAR_RED   , ORG_COLOR_BAR_PURPLE, ORG_COLOR_BAR_RED   , ORG_COLOR_BAR_GREEN , ORG_COLOR_BAR_ORANGE);
    BITMAP_STRING_COLOR_DARK: array[0..BITMAP_NUM - 1] of longword =
        (ORG_COLOR_BTNFACE   , ORG_COLOR_BTNFACE   , ORG_COLOR_BTNFACE   , ORG_COLOR_BTNFACE   , ORG_COLOR_BTNFACE   , ORG_COLOR_BTNFACE   ,
         ORG_COLOR_BTNFACE   , ORG_COLOR_BTNFACE   , ORG_COLOR_BTNFACE   , ORG_COLOR_BTNFACE   , ORG_COLOR_BTNFACE   , ORG_COLOR_BTNFACE   ,
         ORG_COLOR_BTNFACE   , ORG_COLOR_BTNFACE   , ORG_COLOR_BTNFACE   , ORG_COLOR_BTNFACE   , ORG_COLOR_BTNFACE   , ORG_COLOR_BTNFACE   ,
         ORG_COLOR_BAR_GREEN , ORG_COLOR_BAR_WATER , ORG_COLOR_BAR_ORANGE, ORG_COLOR_BAR_RED   , ORG_COLOR_BAR_BLUE  , ORG_COLOR_BAR_PURPLE,
         ORG_COLOR_BAR_BLUE  , ORG_COLOR_BAR_BLUE  , ORG_COLOR_BAR_BLUE  , ORG_COLOR_BAR_BLUE  , ORG_COLOR_BAR_BLUE  , ORG_COLOR_BAR_BLUE  ,
         ORG_COLOR_BAR_RED   , ORG_COLOR_GRAYTEXT  , ORG_COLOR_BAR_RED   , ORG_COLOR_BAR_RED   , ORG_COLOR_BAR_BLUE  , ORG_COLOR_BAR_BLUE  ,
         ORG_COLOR_BAR_ORANGE, ORG_COLOR_BAR_GREEN , ORG_COLOR_BAR_RED   , ORG_COLOR_BAR_BLUE  , ORG_COLOR_BAR_ORANGE, ORG_COLOR_BAR_GREEN ,
         ORG_COLOR_BAR_WATER , ORG_COLOR_BAR_RED   , ORG_COLOR_BAR_BLUE  , ORG_COLOR_BAR_ORANGE, ORG_COLOR_BAR_RED   , ORG_COLOR_BAR_WATER ,
         ORG_COLOR_BAR_RED   , ORG_COLOR_BAR_PURPLE, ORG_COLOR_BAR_RED   , ORG_COLOR_BAR_GREEN , ORG_COLOR_BAR_ORANGE);

    NOISE_RATE: array[0..$1F] of int64 =
        ($3030303030,                                       // 0
         $3631303030,                                       // 16
         $3132303030,                                       // 21
         $3532303030,                                       // 25
         $3133303030,                                       // 31
         $3234303030,                                       // 42
         $3035303030,                                       // 50
         $3336303030,                                       // 63
         $3338303030,                                       // 83
         $3030313030,                                       // 100
         $3532313030,                                       // 125
         $3736313030,                                       // 167
         $3030323030,                                       // 200
         $3035323030,                                       // 250
         $3333333030,                                       // 333
         $3030343030,                                       // 400
         $3030353030,                                       // 500
         $3736363030,                                       // 667
         $3030383030,                                       // 800
         $3030303130,                                       // 1000
         $3333333130,                                       // 1333
         $3030363130,                                       // 1600
         $3030303230,                                       // 2000
         $3736363230,                                       // 2667
         $3030323330,                                       // 3200
         $3030303430,                                       // 4000
         $3333333530,                                       // 5333
         $3030343630,                                       // 6400
         $3030303830,                                       // 8000
         $3736363031,                                       // 10667
         $3030303631,                                       // 16000
         $3030303233);                                      // 32000

    HexTable: array[0..15] of char = ('0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F');
    BoolTable: array[0..1] of char = ('V', 'U');

    CHANNEL_MONO = 1;                                       // モノラル
    CHANNEL_STEREO = 2;                                     // ステレオ

    BIT_8 = 1;                                              // 8 ビット
    BIT_16 = 2;                                             // 16 ビット
    BIT_24 = 3;                                             // 24 ビット
    BIT_32 = 4;                                             // 32 ビット (int)
    BIT_IEEE = -4;                                          // 32 ビット (float)

    INTER_NONE = 0;                                         // 補間処理無効
    INTER_LINEAR = 1;                                       // 線形補間処理
    INTER_CUBIC = 2;                                        // 三次曲線補間処理
    INTER_GAUSS = 3;                                        // 実機ガウス分布補間処理
    INTER_SINC = 4;                                         // シンク関数補間処理
    INTER_GAUSS4 = 7;                                       // ガウス関数補間処理

    PITCH_NORMAL = 32000;                                   // 標準
    PITCH_OLDSBC = 32458;                                   // OLD Sound Blaster Card
    PITCH_OLDSNES = 32768;                                  // OLD ZSNES, Snes9x

    SEPARATE_100 = 65536;                                   // 100 ％
    SEPARATE_000 = 0;                                       // 0 ％
    SEPARATE_010 = SEPARATE_100 * 10 div 100;               // 10 ％
    SEPARATE_020 = SEPARATE_100 * 20 div 100;               // 20 ％
    SEPARATE_025 = SEPARATE_100 * 25 div 100;               // 25 ％
    SEPARATE_030 = SEPARATE_100 * 30 div 100;               // 30 ％
    SEPARATE_033 = SEPARATE_100 * 33 div 100;               // 33 ％
    SEPARATE_040 = SEPARATE_100 * 40 div 100;               // 40 ％
    SEPARATE_050 = SEPARATE_100 * 50 div 100;               // 50 ％
    SEPARATE_060 = SEPARATE_100 * 60 div 100;               // 60 ％
    SEPARATE_067 = SEPARATE_100 * 67 div 100;               // 67 ％
    SEPARATE_070 = SEPARATE_100 * 70 div 100;               // 70 ％
    SEPARATE_075 = SEPARATE_100 * 75 div 100;               // 75 ％
    SEPARATE_080 = SEPARATE_100 * 80 div 100;               // 80 ％
    SEPARATE_090 = SEPARATE_100 * 90 div 100;               // 90 ％

    FEEDBACK_100 = SEPARATE_100;                            // 100 ％
    FEEDBACK_000 = SEPARATE_000;                            // 0 ％
    FEEDBACK_010 = SEPARATE_010;                            // 10 ％
    FEEDBACK_020 = SEPARATE_020;                            // 20 ％
    FEEDBACK_025 = SEPARATE_025;                            // 25 ％
    FEEDBACK_030 = SEPARATE_030;                            // 30 ％
    FEEDBACK_033 = SEPARATE_033;                            // 33 ％
    FEEDBACK_040 = SEPARATE_040;                            // 40 ％
    FEEDBACK_050 = SEPARATE_050;                            // 50 ％
    FEEDBACK_060 = SEPARATE_060;                            // 60 ％
    FEEDBACK_067 = SEPARATE_067;                            // 67 ％
    FEEDBACK_070 = SEPARATE_070;                            // 70 ％
    FEEDBACK_075 = SEPARATE_075;                            // 75 ％
    FEEDBACK_080 = SEPARATE_080;                            // 80 ％
    FEEDBACK_090 = SEPARATE_090;                            // 90 ％

    SPEED_100 = 65536;                                      // 100 ％
    SPEED_001 = SPEED_100 *  100 div 10000;                 // 1 ％
    SPEED_005 = SPEED_100 *  500 div 10000;                 // 5 ％
    SPEED_010 = SPEED_100 * 1000 div 10000;                 // 10 ％
    SPEED_020 = SPEED_100 * 2000 div 10000;                 // 20 ％
    SPEED_025 = SPEED_100 * 2500 div 10000;                 // 25 ％
    SPEED_033 = SPEED_100 * 3333 div 10000;                 // 33 ％
    SPEED_040 = SPEED_100 * 4000 div 10000;                 // 40 ％
    SPEED_050 = SPEED_100 * 5000 div 10000;                 // 50 ％
    SPEED_067 = SPEED_100 * 6667 div 10000;                 // 67 ％
    SPEED_075 = SPEED_100 * 7500 div 10000;                 // 75 ％
    SPEED_080 = SPEED_100 * 8000 div 10000;                 // 80 ％
    SPEED_090 = SPEED_100 * 9000 div 10000;                 // 90 ％
    SPEED_110 = SPEED_100 *  110 div   100;                 // 110 ％
    SPEED_125 = SPEED_100 *  125 div   100;                 // 125 ％
    SPEED_133 = SPEED_100 *  133 div   100;                 // 133 ％
    SPEED_150 = SPEED_100 *  150 div   100;                 // 150 ％
    SPEED_200 = SPEED_100 *  200 div   100;                 // 200 ％
    SPEED_250 = SPEED_100 *  250 div   100;                 // 250 ％
    SPEED_300 = SPEED_100 *  300 div   100;                 // 300 ％
    SPEED_400 = SPEED_100 *  400 div   100;                 // 400 ％
    SPEED_500 = SPEED_100 *  500 div   100;                 // 500 ％
    SPEED_600 = SPEED_100 *  600 div   100;                 // 600 ％
    SPEED_700 = SPEED_100 *  700 div   100;                 // 700 ％
    SPEED_800 = SPEED_100 *  800 div   100;                 // 800 ％

    AMP_100 = 65536;                                        // 100 ％
    AMP_005 = AMP_100 *  500 div 10000;                     // 5 ％
    AMP_010 = AMP_100 * 1000 div 10000;                     // 10 ％
    AMP_015 = AMP_100 * 1500 div 10000;                     // 15 ％
    AMP_020 = AMP_100 * 2000 div 10000;                     // 20 ％
    AMP_025 = AMP_100 * 2500 div 10000;                     // 25 ％
    AMP_033 = AMP_100 * 3333 div 10000;                     // 33 ％
    AMP_040 = AMP_100 * 4000 div 10000;                     // 40 ％
    AMP_050 = AMP_100 * 5000 div 10000;                     // 50 ％
    AMP_067 = AMP_100 * 6667 div 10000;                     // 67 ％
    AMP_075 = AMP_100 * 7500 div 10000;                     // 75 ％
    AMP_080 = AMP_100 * 8000 div 10000;                     // 80 ％
    AMP_090 = AMP_100 * 9000 div 10000;                     // 90 ％
    AMP_110 = AMP_100 *  110 div   100;                     // 110 ％
    AMP_125 = AMP_100 *  125 div   100;                     // 125 ％
    AMP_133 = AMP_100 *  133 div   100;                     // 133 ％
    AMP_150 = AMP_100 *  150 div   100;                     // 150 ％
    AMP_200 = AMP_100 *  200 div   100;                     // 200 ％
    AMP_250 = AMP_100 *  250 div   100;                     // 250 ％
    AMP_300 = AMP_100 *  300 div   100;                     // 300 ％
    AMP_400 = AMP_100 *  400 div   100;                     // 400 ％

    OPTION_LOWPASS = $1;                                    // 実機と同じローパスフィルタ
    OPTION_OLDSMP = $2;                                     // 古い ADPCM デコーダを使用
    OPTION_SURROUND = $4;                                   // 逆位相サラウンド強制
    OPTION_REVERSE = $8;                                    // 左右反転
    OPTION_NOECHO = $10;                                    // エコー無効
    OPTION_NOPMOD = $20;                                    // ピッチモジュレーション無効
    OPTION_NOPREAD = $40;                                   // ピッチベンド無効
    OPTION_NOFIR = $80;                                     // FIR フィルタ無効
    OPTION_BASSBOOST = $100;                                // BASS BOOST (低音強調)
    OPTION_NOENV = $200;                                    // エンベロープ無効
    OPTION_NONOISE = $400;                                  // ノイズ発音指定無効
    OPTION_ECHOFIR = $800;                                  // 実機に近いエコー/FIR 処理
    OPTION_NOSURROUND = $1000;                              // サラウンド無効
    OPTION_ENVSPEED = $2000;                                // エンベロープ速度比を同期
    OPTION_NOPLIMIT = $4000;                                // ピッチ制限無効
    OPTION_FLOATOUT = $40000000;                            // 32 ビット (float) で出力レベルを設定
    OPTION_NOEARSAFE = $80000000;                           // イヤーセーフ無効

    LOCALE_AUTO = $0;                                       // 自動
    LOCALE_JA = $1;                                         // 日本語
    LOCALE_EN = $2;                                         // 英語

    SHIFT_KEY_SEEK = $1;                                    // シークと演奏速度変更のキーボードショートカットを反転

    MENU_FILE = 1;
    MENU_SETUP = 2;
    MENU_LIST = 3;
    MENU_FILE_OPEN_SIZE = 2;
    MENU_FILE_OPEN_BASE = 100;
    MENU_FILE_OPEN = MENU_FILE_OPEN_BASE;
    MENU_FILE_SAVE = MENU_FILE_OPEN_BASE + 1;
    MENU_FILE_PLAY_SIZE = 4;
    MENU_FILE_PLAY_BASE = 110;
    MENU_FILE_PLAY = MENU_FILE_PLAY_BASE;
    MENU_FILE_PAUSE = MENU_FILE_PLAY_BASE + 1;
    MENU_FILE_RESTART = MENU_FILE_PLAY_BASE + 2;
    MENU_FILE_STOP = MENU_FILE_PLAY_BASE + 3;
    MENU_FILE_EXIT = 190;
    MENU_SETUP_DEVICE = 10;
    MENU_SETUP_DEVICE_BASE = 1000; // +90 (ID は 1099 まで予約済み)
    MENU_SETUP_CHANNEL = 20;
    MENU_SETUP_CHANNEL_SIZE = 2;
    MENU_SETUP_CHANNEL_BASE = 200;
    MENU_SETUP_CHANNEL_VALUE: array[0..MENU_SETUP_CHANNEL_SIZE - 1] of longword = (CHANNEL_MONO, CHANNEL_STEREO);
    MENU_SETUP_BIT = 21;
    MENU_SETUP_BIT_SIZE = 5;
    MENU_SETUP_BIT_BASE = 210;
    MENU_SETUP_BIT_VALUE: array[0..MENU_SETUP_BIT_SIZE - 1] of longint = (BIT_8, BIT_16, BIT_24, BIT_32, BIT_IEEE);
    MENU_SETUP_RATE = 22;
    MENU_SETUP_RATE_SIZE = 16;
    MENU_SETUP_RATE_BASE = 220; // +10
    MENU_SETUP_RATE_VALUE: array[0..MENU_SETUP_RATE_SIZE - 1] of longword =
        (8000, 10000, 11025, 12000, 16000, 20000, 22050, 24000, 32000, 40000, 44100, 48000, 64000, 80000, 88200, 96000);
    MENU_SETUP_INTER = 30;
    MENU_SETUP_INTER_SIZE = 6;
    MENU_SETUP_INTER_BASE = 300;
    MENU_SETUP_INTER_VALUE: array[0..MENU_SETUP_INTER_SIZE - 1] of longword =
        (INTER_NONE, INTER_LINEAR, INTER_CUBIC, INTER_GAUSS, INTER_SINC, INTER_GAUSS4);
    MENU_SETUP_PITCH = 31;
    MENU_SETUP_PITCH_SIZE = 3;
    MENU_SETUP_PITCH_BASE = 310; // +20
    MENU_SETUP_PITCH_KEY = 338;
    MENU_SETUP_PITCH_KEY_SIZE = 6;
    MENU_SETUP_PITCH_KEY_BASE = MENU_SETUP_PITCH_BASE + MENU_SETUP_PITCH_SIZE;
    MENU_SETUP_PITCH_VALUE: array[0..MENU_SETUP_PITCH_SIZE + MENU_SETUP_PITCH_KEY_SIZE + MENU_SETUP_PITCH_KEY_SIZE] of longword =
        (PITCH_NORMAL, PITCH_OLDSBC, PITCH_OLDSNES, 45255, 42715, 40317, 38055, 35919, 33903, PITCH_NORMAL, 30204, 28509, 26909, 25398, 23973, 22627);
    MENU_SETUP_PITCH_ASYNC = 339;
    MENU_SETUP_SEPARATE = 34;
    MENU_SETUP_SEPARATE_SIZE = 15;
    MENU_SETUP_SEPARATE_BASE = 340; // +10
    MENU_SETUP_SEPARATE_VALUE: array[0..MENU_SETUP_SEPARATE_SIZE - 1] of longword =
        (SEPARATE_000, SEPARATE_010, SEPARATE_020, SEPARATE_025, SEPARATE_030, SEPARATE_033, SEPARATE_040, SEPARATE_050,
         SEPARATE_060, SEPARATE_067, SEPARATE_070, SEPARATE_075, SEPARATE_080, SEPARATE_090, SEPARATE_100);
    MENU_SETUP_FEEDBACK = 36;
    MENU_SETUP_FEEDBACK_SIZE = 15;
    MENU_SETUP_FEEDBACK_BASE = 360; // +10
    MENU_SETUP_FEEDBACK_VALUE: array[0..MENU_SETUP_FEEDBACK_SIZE - 1] of longword =
        (FEEDBACK_000, FEEDBACK_010, FEEDBACK_020, FEEDBACK_025, FEEDBACK_030, FEEDBACK_033, FEEDBACK_040, FEEDBACK_050,
         FEEDBACK_060, FEEDBACK_067, FEEDBACK_070, FEEDBACK_075, FEEDBACK_080, FEEDBACK_090, FEEDBACK_100);
    MENU_SETUP_SPEED = 38;
    MENU_SETUP_SPEED_SIZE = 27;
    MENU_SETUP_SPEED_BASE = 380; // +20
    MENU_SETUP_SPEED_VALUE: array[0..MENU_SETUP_SPEED_SIZE - 1] of longword =
        (SPEED_001, SPEED_005, SPEED_010, SPEED_020, $FFFFFFFF,
         SPEED_025, SPEED_033, SPEED_040, SPEED_050, SPEED_067, SPEED_075, SPEED_080, SPEED_090, SPEED_100,
         SPEED_110, SPEED_125, SPEED_133, SPEED_150, SPEED_200, SPEED_250, SPEED_300, SPEED_400,
         $FFFFFFFF, SPEED_500, SPEED_600, SPEED_700, SPEED_800);
    MENU_SETUP_AMP = 42;
    MENU_SETUP_AMP_SIZE = 22;
    MENU_SETUP_AMP_BASE = 410; // +10
    MENU_SETUP_AMP_VALUE: array[0..MENU_SETUP_AMP_SIZE - 1] of longword =
        (AMP_005, AMP_010, AMP_015, AMP_020, $FFFFFFFF,
         AMP_025, AMP_033, AMP_040, AMP_050, AMP_067, AMP_075, AMP_080, AMP_090, AMP_100,
         AMP_110, AMP_125, AMP_133, AMP_150, AMP_200, AMP_250, AMP_300, AMP_400);
    MENU_SETUP_MUTE = 46;
    MENU_SETUP_MUTE_ALL_BASE = 470;
    MENU_SETUP_MUTE_ALL_ENABLE = MENU_SETUP_MUTE_ALL_BASE;
    MENU_SETUP_MUTE_ALL_DISABLE = MENU_SETUP_MUTE_ALL_BASE + 1;
    MENU_SETUP_MUTE_ALL_XOR = MENU_SETUP_MUTE_ALL_BASE + 2;
    MENU_SETUP_MUTE_BASE = 460; // +10
    MENU_SETUP_NOISE = 48;
    MENU_SETUP_NOISE_ALL_BASE = 490;
    MENU_SETUP_NOISE_ALL_ENABLE = MENU_SETUP_NOISE_ALL_BASE;
    MENU_SETUP_NOISE_ALL_DISABLE = MENU_SETUP_NOISE_ALL_BASE + 1;
    MENU_SETUP_NOISE_ALL_XOR = MENU_SETUP_NOISE_ALL_BASE + 2;
    MENU_SETUP_NOISE_BASE = 480; // +10
    MENU_SETUP_MUTE_NOISE_SIZE = 8;
    MENU_SETUP_MUTE_NOISE_ALL_SIZE = 3;
    MENU_SETUP_OPTION = 50;
    MENU_SETUP_OPTION_SIZE = 17;
    MENU_SETUP_OPTION_BASE = 500; // +10
    MENU_SETUP_OPTION_VALUE: array[0..MENU_SETUP_OPTION_SIZE - 1] of longword =
        (OPTION_LOWPASS, OPTION_ECHOFIR, NULL, OPTION_BASSBOOST, OPTION_OLDSMP, OPTION_SURROUND, OPTION_REVERSE, OPTION_ENVSPEED,
         NULL, OPTION_NOSURROUND, OPTION_NOECHO, OPTION_NOFIR, OPTION_NOPMOD, OPTION_NOPREAD, OPTION_NOPLIMIT, OPTION_NOENV,
         OPTION_NONOISE);
    MENU_SETUP_TIME = 60;
    MENU_SETUP_TIME_DISABLE = 600;
    MENU_SETUP_TIME_ID666 = 601;
    MENU_SETUP_TIME_DEFAULT = 602;
    MENU_SETUP_TIME_START = 605;
    MENU_SETUP_TIME_LIMIT = 606;
    MENU_SETUP_TIME_RESET = 607;
    MENU_SETUP_ORDER = 61;
    MENU_SETUP_ORDER_SIZE = 6;
    MENU_SETUP_ORDER_BASE = 610;
    MENU_SETUP_SEEK = 62;
    MENU_SETUP_SEEK_SIZE = 6;
    MENU_SETUP_SEEK_BASE = 620; // +10
    MENU_SETUP_SEEK_VALUE: array[0..MENU_SETUP_SEEK_SIZE - 1] of longword = (1000, 2000, 3000, 4000, 5000, 10000);
    MENU_SETUP_SEEK_FAST = 657;
    MENU_SETUP_SEEK_ASYNC = 658;
    MENU_SETUP_INFO = 63;
    MENU_SETUP_INFO_SIZE = 9;
    MENU_SETUP_INFO_BASE = 630;
    MENU_SETUP_INFO_RESET = 659;
    MENU_SETUP_PRIORITY = 64;
    MENU_SETUP_PRIORITY_SIZE = 6;
    MENU_SETUP_PRIORITY_BASE = 640;
    MENU_SETUP_PRIORITY_VALUE: array[0..MENU_SETUP_PRIORITY_SIZE - 1] of longword =
        (REALTIME_PRIORITY_CLASS, HIGH_PRIORITY_CLASS, ABOVE_NORMAL_PRIORITY_CLASS, NORMAL_PRIORITY_CLASS, BELOW_NORMAL_PRIORITY_CLASS,
         IDLE_PRIORITY_CLASS);
    MENU_SETUP_OTHERS = 65;
    MENU_SETUP_TOPMOST = 650;
    MENU_SETUP_NOSLEEP = 651;
    MENU_LIST_PLAY = 700;
    MENU_LIST_PLAY_SELECT = 701;
    MENU_LIST_PLAY_SIZE = 6;
    MENU_LIST_PLAY_BASE = 702;
    MENU_LIST_PLAY_MAX = MENU_LIST_PLAY_BASE + MENU_LIST_PLAY_SIZE - 1;
    MENU_LIST_PLAY_VALUE: array[0..MENU_LIST_PLAY_SIZE - 1] of longword =
        (PLAY_ORDER_NEXT, PLAY_ORDER_PREVIOUS, PLAY_ORDER_RANDOM, PLAY_ORDER_SHUFFLE, PLAY_ORDER_FIRST, PLAY_ORDER_LAST);
    MENU_LIST_EDIT_SIZE = 4;
    MENU_LIST_EDIT_BASE = 710;
    MENU_LIST_ADD = MENU_LIST_EDIT_BASE;
    MENU_LIST_INSERT = MENU_LIST_EDIT_BASE + 1;
    MENU_LIST_REMOVE = MENU_LIST_EDIT_BASE + 2;
    MENU_LIST_CLEAR = MENU_LIST_EDIT_BASE + 3;
    MENU_LIST_MOVE_SIZE = 2;
    MENU_LIST_MOVE_BASE = 720;
    MENU_LIST_UP = MENU_LIST_MOVE_BASE;
    MENU_LIST_DOWN = MENU_LIST_MOVE_BASE + 1;

    ID_BASE = 1000;
    ID_BUTTON = 0;
    ID_COMBOBOX = 1;
    ID_EDIT = 2;
    ID_LISTBOX = 3;
    ID_SCROLLBAR = 4;
    ID_STATIC = 5;
    ID_OTHER = 6;
    ID_BUTTON_OPEN = ID_BASE * ID_BUTTON + 0;
    ID_BUTTON_SAVE = ID_BASE * ID_BUTTON + 1;
    ID_BUTTON_PLAY = ID_BASE * ID_BUTTON + 2;
    ID_BUTTON_RESTART = ID_BASE * ID_BUTTON + 3;
    ID_BUTTON_STOP = ID_BASE * ID_BUTTON + 4;
    ID_BUTTON_TRACK_BASE = ID_BASE * ID_BUTTON + 10;
    ID_BUTTON_TRACK: array[0..7] of longword =
        (ID_BUTTON_TRACK_BASE + 0, ID_BUTTON_TRACK_BASE + 1, ID_BUTTON_TRACK_BASE + 2, ID_BUTTON_TRACK_BASE + 3, ID_BUTTON_TRACK_BASE + 4,
         ID_BUTTON_TRACK_BASE + 5, ID_BUTTON_TRACK_BASE + 6, ID_BUTTON_TRACK_BASE + 7);
    ID_BUTTON_SLOW = ID_BASE * ID_BUTTON + 20;
    ID_BUTTON_FAST = ID_BASE * ID_BUTTON + 21;
    ID_BUTTON_AMPD = ID_BASE * ID_BUTTON + 22;
    ID_BUTTON_AMPU = ID_BASE * ID_BUTTON + 23;
    ID_BUTTON_BACK = ID_BASE * ID_BUTTON + 24;
    ID_BUTTON_NEXT = ID_BASE * ID_BUTTON + 25;
    ID_BUTTON_ADD = ID_BASE * ID_BUTTON + 30;
    ID_BUTTON_REMOVE = ID_BASE * ID_BUTTON + 31;
    ID_BUTTON_CLEAR = ID_BASE * ID_BUTTON + 32;
    ID_BUTTON_UP = ID_BASE * ID_BUTTON + 33;
    ID_BUTTON_DOWN = ID_BASE * ID_BUTTON + 34;
    ID_LIST_PLAY = ID_BASE * ID_LISTBOX + 0;
    ID_LIST_FILE = ID_BASE * ID_LISTBOX + 1;
    ID_LIST_SORT = ID_BASE * ID_LISTBOX + 2;
    ID_LIST_TEMP = ID_BASE * ID_LISTBOX + 3;
    ID_STATIC_MAIN = ID_BASE * ID_STATIC + 0;
    ID_STATIC_FILE = ID_BASE * ID_STATIC + 1;

    STR_MENU_SETUP_SEPARATE_PER_INDEX: array[0..MENU_SETUP_SEPARATE_SIZE - 1] of longword =
        (1, 4, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18);
    STR_MENU_SETUP_SEPARATE_TIP_INDEX: array[0..MENU_SETUP_SEPARATE_SIZE - 1] of longword =
        (2, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 3);
    STR_MENU_SETUP_FEEDBACK_PER_INDEX: array[0..MENU_SETUP_FEEDBACK_SIZE - 1] of longword =
        (1, 4, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18);
    STR_MENU_SETUP_FEEDBACK_TIP_INDEX: array[0..MENU_SETUP_FEEDBACK_SIZE - 1] of longword =
        (1, NULL, NULL, NULL, NULL, NULL, NULL, 2, NULL, NULL, NULL, NULL, NULL, NULL, 4);
    STR_MENU_SETUP_SPEED_PER_INDEX:    array[0..MENU_SETUP_SPEED_SIZE - 1]    of longword =
        (2, 3, 4, 6, NULL, 7, 9, 10, 11, 13, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, NULL, 27, 28, 29, 30);
    STR_MENU_SETUP_SPEED_TIP_INDEX:    array[0..MENU_SETUP_SPEED_SIZE - 1]    of longword =
        (9, NULL, NULL, NULL, NULL, 5, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1,
         NULL, NULL, NULL, NULL, NULL, NULL, NULL, 6, NULL, NULL, NULL, NULL, 10);
    STR_MENU_SETUP_AMP_PER_INDEX:      array[0..MENU_SETUP_AMP_SIZE - 1]      of longword =
        (3, 4, 5, 6, NULL, 7, 9, 10, 11, 13, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26);
    STR_MENU_SETUP_AMP_TIP_INDEX:      array[0..MENU_SETUP_AMP_SIZE - 1]      of longword =
        (11, NULL, NULL, NULL, NULL, 7, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 8);
    STR_MENU_SETUP_PER_INTEGER: array[0..30] of longword =
        (0, 0, 1, 5, 10, 15, 20, 25, 30, 33, 40, 50, 60, 67, 70, 75, 80, 90, 100, 110, 125, 133, 150, 200, 250, 300, 400, 500, 600, 700, 800);

    LANGUAGE_NUM = 2;                                       // ロケール数
    ERROR_SNESAPU: array[0..1] of string = ('SNESAPU.DLL の初期化に失敗しました。', 'Initializing SNESAPU.DLL is failed.');
    ERROR_CHECKSUM: array[0..1] of string = ('アプリケーションの起動に失敗しました。', 'Initializing application is failed.');
    ERROR_FILE_READ: array[0..1] of string = ('ファイルの読み込みに失敗しました。', 'Reading selected file is failed.');
    ERROR_FILE_WRITE: array[0..1] of string = ('ファイルの書き込みに失敗しました。', 'Writing selected file is failed.');
    ERROR_DEVICE: array[0..1] of string = ('サウンド デバイスの初期化に失敗しました。', 'Initializing selected sound device is failed.');
    ERROR_CODE_1: array[0..1] of string = (CRLF + '(エラー ', CRLF + '(ERROR ');
    ERROR_CODE_2: array[0..1] of string = (')', ')');
    WARN_CLEAR_PLAYLIST: array[0..1] of string = (
        'プレイリストをクリアしますか?' + CRLF + '※ この操作を行うと、元には戻せません。',
        'Are you sure you want to clear your playlist?' + CRLF + '* This action cannot be reversed.');
    WARN_WAVE_SIZE_1: array[0..1] of string = (
        'WAVE サウンド ファイルを作成しますか?' + CRLF + '※ ファイル サイズは最大約 ',
        'Are you sure you want to create a WAVE file?' + CRLF + '* Maximum size of created file will be about ');
    WARN_WAVE_SIZE_2: array[0..1] of string = (
        'MB です。' + CRLF + '※ 作成が完了するまで時間がかかる場合があります。 作成中は操作できません。',
        'MB.' + CRLF + '* Processing might take time until completed, and you cannot cancel processing.');
    INFO_WAVE_FINISH_1: array[0..1] of string = (
        'WAVE サウンド ファイルを作成しました。' + CRLF + '※ ファイル サイズは約 ',
        'WAVE file was created successfully.' + CRLF + '* Size of file is about ');
    INFO_WAVE_FINISH_2: array[0..1] of string = (
        'MB です。',
        'MB.');
    DIALOG_OPEN_FILTER: array[0..1] of string = (
        'SNES SPC700 サウンド (*.spc)' + NULLCHAR + '*.spc;*.sp0;*.sp1;*.sp2;*.sp3;*.sp4;*.sp5;*.sp6;*.sp7;*.sp8;*.sp9' + NULLCHAR +
        'プレイリスト (*.lst)' + NULLCHAR + '*.lst' + NULLCHAR +
        'SPC, プレイリスト (*.spc; *.lst)' + NULLCHAR + '*.spc;*.sp0;*.sp1;*.sp2;*.sp3;*.sp4;*.sp5;*.sp6;*.sp7;*.sp8;*.sp9;*.lst' + NULLCHAR,
        'SNES SPC700 sound (*.spc)' + NULLCHAR + '*.spc;*.sp0;*.sp1;*.sp2;*.sp3;*.sp4;*.sp5;*.sp6;*.sp7;*.sp8;*.sp9' + NULLCHAR +
        'Playlist (*.lst)' + NULLCHAR + '*.lst' + NULLCHAR +
        'SPC, Playlist (*.spc; *.lst)' + NULLCHAR + '*.spc;*.sp0;*.sp1;*.sp2;*.sp3;*.sp4;*.sp5;*.sp6;*.sp7;*.sp8;*.sp9;*.lst' + NULLCHAR);
    DIALOG_SCRIPT700_FILTER: array[0..1] of string = (
        'Script700 (*.700; *.7se)' + NULLCHAR + '*.700;*.7se;*.700.txt;*.7se.txt' + NULLCHAR,
        'Script700 (*.700; *.7se)' + NULLCHAR + '*.700;*.7se;*.700.txt;*.7se.txt' + NULLCHAR);
    DIALOG_ALL_FILTER: array[0..1] of string = (
        'すべてのファイル (*.*)' + NULLCHAR + '*.*' + NULLCHAR,
        'All Files (*.*)' + NULLCHAR + '*.*' + NULLCHAR);
    DIALOG_OPEN_DEFAULT = 3;
    DIALOG_LIST_FILTER: array[0..1] of string = (
        'プレイリスト (*.lst)' + NULLCHAR + '*.lst' + NULLCHAR,
        'Playlist (*.lst)' + NULLCHAR + '*.lst' + NULLCHAR);
    DIALOG_WAVE_FILTER: array[0..1] of string = (
        'WAVE サウンド (*.wav)' + NULLCHAR + '*.wav' + NULLCHAR,
        'WAVE Sound (*.wav)' + NULLCHAR + '*.wav' + NULLCHAR);
    DIALOG_SNAP_FILTER: array[0..1] of string = (
        'スナップショット (*.spc)' + NULLCHAR + '*.spc' + NULLCHAR,
        'SPC Snapshot (*.spc)' + NULLCHAR + '*.spc' + NULLCHAR);
    DIALOG_SAVE_DEFAULT = 1;
    STR_MENU_FILE: array[0..1] of pchar = ('ファイル(&F)', '&File');
    STR_MENU_SETUP: array[0..1] of pchar = ('設定(&S)', '&Settings');
    STR_MENU_LIST: array[0..1] of pchar = ('プレイリスト(&P)', '&Playlist');
    STR_MENU_FILE_EXIT: array[0..1] of pchar = ('終了(&X)', 'E&xit');
    STR_MENU_SETUP_DEVICE: array[0..1] of pchar = ('サウンド デバイス(&D)', 'Sound &Devices');
    STR_MENU_SETUP_DEVICE_MAPPER: array[0..1] of pchar = ('システム設定を使用(&D)', 'System &Default');
    STR_MENU_SETUP_CHANNEL: array[0..1] of pchar = ('チャンネル(&C)', '&Channels');
    STR_MENU_SETUP_BIT: array[0..1] of pchar = ('ビット(&B)', '&Bit');
    STR_MENU_SETUP_RATE: array[0..1] of pchar = ('サンプリング レート(&R)', 'Sampling &Rate');
    STR_MENU_SETUP_INTER: array[0..1] of pchar = ('補間処理(&I)', '&Interpolation');
    STR_MENU_SETUP_PITCH: array[0..1] of pchar = ('ピッチ(&P)', '&Pitch');
    STR_MENU_SETUP_PITCH_KEY: array[0..1] of pchar = ('音程キー(&K)', '&Key Shift');
    STR_MENU_SETUP_PITCH_PLUS: array[0..1] of string = ('＋&', '+ &');
    STR_MENU_SETUP_PITCH_MINUS: array[0..1] of string = ('－&', '- &');
    STR_MENU_SETUP_PITCH_ZERO: pchar = ' &0 ';
    STR_MENU_SETUP_PITCH_ASYNC: array[0..1] of pchar = ('演奏速度比と同期(&M)', '&Multiply by &Speed');
    STR_MENU_SETUP_SEPARATE: array[0..1] of pchar = ('左右拡散度(&E)', 'Stereo S&eparator');
    STR_MENU_SETUP_FEEDBACK: array[0..1] of pchar = ('フィードバック反転度(&F)', 'Echo &Feedback');
    STR_MENU_SETUP_SPEED: array[0..1] of pchar = ('演奏速度(&S)', '&Speed');
    STR_MENU_SETUP_AMP: array[0..1] of pchar = ('音量(&V)', '&Volume');
    STR_MENU_SETUP_MUTE: array[0..1] of pchar = ('チャンネル ミュート(&M)', 'Channel &Mute');
    STR_MENU_SETUP_NOISE: array[0..1] of pchar = ('チャンネル ノイズ(&N)', 'Channel &Noise');
    STR_MENU_SETUP_SWITCH_CHANNEL: array[0..1] of pchar = ('チャンネル ', 'Channel ');
    STR_MENU_SETUP_OPTION: array[0..1] of pchar = ('拡張設定(&X)', 'E&xpansion Flags');
    STR_MENU_SETUP_TIME: array[0..1] of pchar = ('演奏時間(&T)', 'Play &Time');
    STR_MENU_SETUP_TIME_DISABLE: array[0..1] of pchar = ('無効/エンドレス(&D)', '&Disable/Endless');
    STR_MENU_SETUP_TIME_ID666: array[0..1] of pchar = ('&ID666 時間設定を優先', 'Enable &ID666 Time');
    STR_MENU_SETUP_TIME_DEFAULT: array[0..1] of pchar = ('常に既定時間を使用(&E)', 'Always D&efault Time');
    STR_MENU_SETUP_TIME_START: array[0..1] of pchar = ('開始位置を設定(&S)', 'Set &Start Position Mark');
    STR_MENU_SETUP_TIME_LIMIT: array[0..1] of pchar = ('終了位置を設定(&L)', 'Set &Limit Position Mark');
    STR_MENU_SETUP_TIME_RESET: array[0..1] of pchar = ('位置をリセット(&R)', '&Reset Position Marks');
    STR_MENU_SETUP_ORDER: array[0..1] of pchar = ('演奏順序(&O)', 'Play &Order');
    STR_MENU_SETUP_INFO: array[0..1] of pchar = ('情報表示(&A)', 'I&nformation Viewer');
    STR_MENU_SETUP_INFO_RESET: array[0..1] of pchar = ('無音チャンネル非表示(&H)', '&Hide Muted Channels');
    STR_MENU_SETUP_SEEK: array[0..1] of pchar = ('シーク時間(&K)', 'See&k Time');
    STR_MENU_SETUP_SEEK_FAST: array[0..1] of pchar = ('高速シーク(&F)', '&Fast Seek');
    STR_MENU_SETUP_SEEK_ASYNC: array[0..1] of pchar = ('演奏速度比と同期(&M)', '&Multiply by Speed');
    STR_MENU_SETUP_PRIORITY: array[0..1] of pchar = ('処理優先度(&U)', 'CP&U Priority');
    STR_MENU_SETUP_OTHERS: array[0..1] of pchar = ('その他設定(&H)', 'Ot&her Flags');
    STR_MENU_SETUP_TOPMOST: array[0..1] of pchar = ('常に手前に表示(&W)', 'Al&ways on Top');
    STR_MENU_SETUP_NOSLEEP: array[0..1] of pchar = ('演奏中に画面オフを抑制(&D)', 'Not Turn Off &Display');
    STR_MENU_LIST_PLAY: array[0..1] of pchar = ('演奏開始(&P)', '&Play');
    STR_MENU_LIST_PLAY_SELECT: array[0..1] of pchar = ('選択項目(&S)', '&Selected Item');
    STR_MENU_FILE_OPEN_SUB: array[0..1] of array[0..MENU_FILE_OPEN_SIZE - 1] of pchar = (
        ('開く(&O)...', '保存(&S)...'),
        ('&Open...', '&Save...'));
    STR_MENU_FILE_PLAY_SUB: array[0..1] of array[0..MENU_FILE_PLAY_SIZE - 1] of pchar = (
        ('演奏開始(&P)', '一時停止(&P)', '最初から演奏(&R)', '演奏停止(&T)'),
        ('&Play', '&Pause', '&Restart', 'S&top'));
    STR_MENU_SETUP_MUTE_NOISE_ALL_SUB: array[0..1] of array[0..MENU_SETUP_MUTE_NOISE_ALL_SIZE - 1] of pchar = (
        ('すべてオン(&E)', 'すべてオフ(&D)', 'すべて反転(&R)'),
        ('&Enable All', '&Disable All', '&Reverse All'));
    STR_MENU_LIST_EDIT_SUB: array[0..1] of array[0..MENU_LIST_EDIT_SIZE - 1] of pchar = (
        ('追加(&A)', '挿入(&I)', '削除(&R)', 'クリア(&C)'),
        ('&Append', '&Insert', '&Remove', '&Clear'));
    STR_MENU_LIST_MOVE_SUB: array[0..1] of array[0..MENU_LIST_MOVE_SIZE - 1] of pchar = (
        ('上へ(&U)', '下へ(&D)'),
        ('Move &Up', 'Move &Down'));
    STR_MENU_SETUP_TIP: array[0..1] of array[0..11] of pchar = (
        ('', '[標準]', '[混合]', '[拡散]', '[反転]', '[遅]', '[速]', '[小]', '[大]', '[極遅]', '[極速]', '[極小]'),
        ('', '[Normal]', '[Mix]', '[Separate]', '[Reverse]', '[Slow]', '[Fast]', '[Low]', '[High]', '[Very Slow]', '[Very Fast]', '[Very Low]'));
    STR_MENU_SETUP_CHANNEL_SUB: array[0..1] of array[0..MENU_SETUP_CHANNEL_SIZE - 1] of pchar = (
        ('&1 チャンネル  (モノラル)', '&2 チャンネル  (ステレオ)'),
        ('&1 Channel  (Monaural)', '&2 Channels  (Stereo)'));
    STR_MENU_SETUP_BIT_SUB: array[0..1] of array[0..MENU_SETUP_BIT_SIZE - 1] of pchar = (
        ('&8 ビット', Concat('&16 ビット', #9, '[標準]'), '&24 ビット', '&32 ビット  (int)', Concat('&32 ビット  (float)', #9, '[高音質]')),
        ('&8-Bit', Concat('&16-Bit', #9, '[Normal]'), '&24-Bit', '&32-Bit  (int)', Concat('&32-Bit  (float)', #9, '[HQ]')));
    STR_MENU_SETUP_RATE_SUB: array[0..1] of array[0..MENU_SETUP_RATE_SIZE - 1] of pchar = (
        ('&8,000 Hz', '&10,000 Hz', '&11,025 Hz', '&12,000 Hz', '&16,000 Hz', '&20,000 Hz', '&22,050 Hz', '&24,000 Hz',
         Concat('&32,000 Hz', #9, '[標準]'), '&40,000 Hz', Concat('&44,100 Hz', #9, '[CD]'), Concat('&48,000 Hz', #9, '[DVD]'),
         '&64,000 Hz', '&80,000 Hz', '&88,200 Hz', '&96,000 Hz'),
        ('&8,000 Hz', '&10,000 Hz', '&11,025 Hz', '&12,000 Hz', '&16,000 Hz', '&20,000 Hz', '&22,050 Hz', '&24,000 Hz',
         Concat('&32,000 Hz', #9, '[Normal]'), '&40,000 Hz', Concat('&44,100 Hz', #9, '[CD]'), Concat('&48,000 Hz', #9, '[DVD]'),
         '&64,000 Hz', '&80,000 Hz', '&88,200 Hz', '&96,000 Hz'));
    STR_MENU_SETUP_INTER_SUB: array[0..1] of array[0..MENU_SETUP_INTER_SIZE - 1] of pchar = (
        ('無効(&D)', '線形補間(&L)', '三次スプライン補間(&C)', Concat('実機ガウス分布補間(&G)', #9, '[標準]'),
         Concat('シンク関数補間(&S)', #9, '[高音質]'), 'ガウス関数補間(&A)'),
        ('&Disable', '&Liner', '&Cubic Spline', Concat('SNES &Gaussian Table', #9, '[Normal]'),
         Concat('&Sinc Function', #9, '[HQ]'), 'G&aussian Function'));
    STR_MENU_SETUP_PITCH_SUB: array[0..1] of array[0..MENU_SETUP_PITCH_SIZE - 1] of pchar = (
        ('標準(&N)', '過去の &Sound Blaster 互換', '過去の &ZSNES, Snes9x 互換'),
        ('&Normal', 'OLD &Sound Blaster Card', 'OLD &ZSNES, Snes9x'));
    STR_MENU_SETUP_OPTION_SUB: array[0..1] of array[0..MENU_SETUP_OPTION_SIZE - 1] of pchar = (
        ('実機ローパス フィルタ(&L)', '実機エコー/FIR 処理(&M)', NULLPOINTER, '&BASS BOOST', '過去の &ADPCM デコーダ', '逆位相サラウンド強制(&S)',
         '左右反転(&R)', 'エンベロープ速度比を同期(&Y)', NULLPOINTER, 'サラウンド無効(&U)', 'エコー無効(&E)', '&FIR フィルタ無効',
         'ピッチ モジュレーション無効(&P)', 'ピッチ ベンド無効(&I)', 'ピッチ リミット無効(&T)', 'エンベロープ無効(&V)', 'ノイズ発音指定無効(&N)'),
        ('SNES &Low-Pass Filter', 'SNES Echo/FIR &Method', NULLPOINTER, '&BASS BOOST', 'Old &ADPCM Decoder', 'Opposite-Phase &Surround',
         '&Reverse Stereo', 'S&ynchronize Envelope with Speed', NULLPOINTER, 'Disable S&urround', 'Disable &Echo', 'Disable &FIR Filter',
         'Disable &Pitch Modulation', 'Disable P&itch Bend', 'Disable Pi&tch Limit', 'Disable En&velope', 'Disable &Noise Flags'));
    STR_MENU_SETUP_ORDER_SUB: array[0..1] of array[0..MENU_SETUP_ORDER_SIZE - 1] of pchar = (
        ('演奏停止(&S)', '次へ(&N)', '前へ(&P)', 'ランダム(&M)', 'シャッフル(&H)', 'リピート(&R)'),
        ('&Stop', '&Next Item', '&Previous Item', 'Rando&m', 'S&huffle', '&Repeat'));
    STR_MENU_SETUP_INFO_SUB: array[0..1] of array[0..MENU_SETUP_INFO_SIZE - 1] of pchar = (
        ('グラフィック インジケータ(&G)', '&DSP/BPM 情報', 'チャンネル情報 1 (&C)', 'チャンネル情報 2 (&A)', 'チャンネル情報 3 (&N)',
         'チャンネル情報 4 (&E)', '&SPC 情報 1', 'S&PC 情報 2', 'Script&700 デバッグ'),
        ('&Graphic Indicator', '&DSP/BPM', '&Channel 1', 'Ch&annel 2', 'Cha&nnel 3',
         'Chann&el 4', '&SPC Tags 1', 'S&PC Tags 2', 'Script&700 Debug'));
    STR_MENU_SETUP_SEEK_SUB: array[0..1] of array[0..MENU_SETUP_SEEK_SIZE - 1] of pchar = (
        ('&1 秒', '&2 秒', '&3 秒', '&4 秒', '&5 秒', '1&0 秒'),
        ('&1 s', '&2 s', '&3 s', '&4 s', '&5 s', '&10 s'));
    STR_MENU_SETUP_PRIORITY_SUB: array[0..1] of array[0..MENU_SETUP_PRIORITY_SIZE - 1] of pchar = (
        ('リアルタイム(&R)', '高(&H)', '標準以上(&A)', '標準(&N)', '標準以下(&B)', '低(&L)'),
        ('&Realtime', '&High', '&Above Normal', '&Normal', '&Below Normal', '&Low'));
    STR_MENU_LIST_PLAY_SUB: array[0..1] of array[0..MENU_LIST_PLAY_SIZE - 1] of pchar = (
        ('次へ(&N)', '前へ(&P)', 'ランダム(&M)', 'シャッフル(&H)', '最初から(&F)', '最後から(&L)'),
        ('&Next Item', '&Previous Item', 'Rando&m', 'S&huffle', '&First Item', '&Last Item'));
    STR_MENU_SETUP_PERCENT: array[0..1] of string = (' ％', ' %');
    STR_MENU_SETUP_SEC1: array[0..1] of string = (' 秒', ' s');
    STR_MENU_SETUP_SEC2: array[0..1] of string = (' sec', ' s  ');
    STR_MENU_SETUP_MSEC: array[0..1] of string = (' ms', ' ms');
    STR_BUTTON_OPEN = 'OPEN';
    STR_BUTTON_SAVE = 'SAVE';
    STR_BUTTON_PLAY = 'PLAY';
    STR_BUTTON_RESTART = 'RESTART';
    STR_BUTTON_PAUSE = 'PAUSE';
    STR_BUTTON_STOP = 'STOP';
    STR_BUTTON_SLOW = 'SP-';
    STR_BUTTON_FAST = 'SP+';
    STR_BUTTON_AMPD = 'VL-';
    STR_BUTTON_AMPU = 'VL+';
    STR_BUTTON_BACK = 'REW';
    STR_BUTTON_NEXT = 'FF';
    STR_BUTTON_APPEND = 'APPEND';
    STR_BUTTON_INSERT = 'INSERT';
    STR_BUTTON_REMOVE = 'REMOVE';
    STR_BUTTON_CLEAR = 'CLEAR';
    STR_BUTTON_UP: array[0..1] of pchar = ('▲', 'UP');
    STR_BUTTON_DOWN: array[0..1] of pchar = ('▼', 'DN');
    TITLE_NAME_UNKNOWN = 'Unknown';
    TITLE_NAME_SEPARATOR: array[0..1] of string = (' / ', ' / ');
    TITLE_NAME_HEADER: array[0..1] of string = (' [', ' [');
    TITLE_NAME_FOOTER: array[0..1] of string = (']', ']');
    TITLE_MAIN_HEADER: array[0..1] of string = (' - ', ' - ');
    TITLE_INFO_HEADER: array[0..1] of string = ('《 ', '< ');
    TITLE_INFO_FOOTER: array[0..1] of string = (' 》', ' >');
    TITLE_INFO_SEPARATE_HEADER: array[0..1] of string = ('左右拡散度 ', 'Separate ');
    TITLE_INFO_FEEDBACK_HEADER: array[0..1] of string = ('フィードバック反転度 ', 'Echo Feedback ');
    TITLE_INFO_SPEED_HEADER: array[0..1] of string = ('演奏速度 ', 'Speed ');
    TITLE_INFO_AMP_HEADER: array[0..1] of string = ('音量 ', 'Volume ');
    TITLE_INFO_SEEK_HEADER: array[0..1] of string = ('シーク ', 'Seek ');
    TITLE_INFO_PLUS: array[0..1] of string = ('＋', '+');
    TITLE_INFO_MINUS: array[0..1] of string = ('－', '-');
    TITLE_INFO_MULTIPLE: array[0..1] of string = (' × ', '  x');
    TITLE_INFO_PERCENT: array[0..1] of string = (' ％', ' %');
    TITLE_INFO_FILE_APPEND: array[0..1] of string = ('ファイル読込中... ', 'Loading... ');
    TITLE_INFO_FILE_HEADER: array[0..1] of string = ('ファイル作成中... ', 'Storing... ');
    TITLE_INFO_FILE_PROC: array[0..1] of string = (' ％完了', ' % completed');


// *************************************************************************************************************************************************************
// グローバル変数の宣言
// *************************************************************************************************************************************************************

var
    Apu: TAPU;                                              // APU
    Spc: TSPC;                                              // SPC
    Wave: record                                            // 音声データ
        dwEmuSize: longword;                                    // エミュレートサイズ
        dwBufSize: longword;                                    // バッファサイズ
        lpData: array of pointer;                               // バッファのポインタ
        dwHandle: longword;                                     // デバイスハンドル
        Format: TWAVEFORMATEXTENSIBLE;                          // フォーマット
        Header: array of TWAVEHDR;                              // ヘッダ
        Apu: array of TAPUDATA;                                 // APU データ
        dwTimeout: array[0..7] of longword;                     // インジケータリセットのタイムアウトバッファ
        dwIndex: longword;                                      // APU データインデックス
        dwLastIndex: longword;                                  // APU データ最後のインデックス
    end;
    Status: record                                          // ステータス
        ccClass: CCLASS;                                        // ウィンドウクラスのクラス
        cfMain: CWINDOWMAIN;                                    // メインウィンドウクラス
        hInstance: longword;                                    // インスタンスハンドル
        OsVersionInfo: TOSVERSIONINFO;                          // システムバージョン情報
        dwChannel: longword;                                    // チャンネル
        dwBit: longint;                                         // ビット
        dwRate: longword;                                       // サンプリングレート
        dwLanguage: longword;                                   // 言語
        hDCWindow: longword;                                    // ウィンドウ全体のデバイスコンテキストのハンドル
        hDCStatic: longword;                                    // 情報表示ウィンドウのデバイスコンテキストのハンドル
        hDCVolumeBuffer: longword;                              // インジケータのデバイスコンテキストのハンドル
        hBitmapVolume: longword;                                // インジケータのビットマップのハンドル
        hDCStringBuffer: longword;                              // 文字画像のデバイスコンテキストのハンドル
        hBitmapString: longword;                                // 文字画像のビットマップのハンドル
        hPowerNotify: longword;                                 // 電源設定通知イベントのハンドル
        hSuspendNotify: longword;                               // サスペンド通知イベントのハンドル
        lpStaticProc: pointer;                                  // 情報表示のウィンドウプロシージャのポインタ
        dwThreadHandle: longword;                               // スレッドハンドル
        dwThreadID: longword;                                   // スレッド ID
        dwThreadStatus: longword;                               // スレッド状態
        dwThreadIdle: longword;                                 // スレッドアイドルカウント
        dwWaveMessage: longword;                                // メッセージ送信済みカウント
        bOpen: longbool;                                        // Open フラグ
        bPlay: longbool;                                        // Play フラグ
        bPause: longbool;                                       // Pause フラグ
        lpCurrentPath: pointer;                                 // カレントパス
        lpCurrentSize: longword;                                // カレントパスのサイズ
        lpSPCFile: pointer;                                     // SPC ファイルパス
        lpSPCDir: pointer;                                      // SPC ディレクトリパス
        lpSPCName: pointer;                                     // SPC ファイル名
        lpOpenPath: pointer;                                    // ファイル読込フォルダバッファ
        lpSavePath: pointer;                                    // ファイル保存フォルダバッファ
        dwFocusHandle: longword;                                // フォーカスハンドル
        dwDeviceNum: longword;                                  // デバイス数
        sDeviceName: array of string;                           // デバイス名
        dwAPUPlayTime: longword;                                // 再生時間
        dwAPUFadeTime: longword;                                // フェードアウト時間
        dwDefaultTimeout: longword;                             // 次の曲に移る時間
        dwNextTimeout: longword;                                // 次の曲に移る時間 (設定)
        dwMuteTimeout: longword;                                // 次の曲に移る時間 (強制)
        dwMuteCounter: longword;                                // 次の曲に移る動作を禁止するカウンタ
        dwNextCache: longword;                                  // 次のキャッシュ時間
        bNextDefault: longbool;                                 // デフォルトの時間を使用
        bSPCRestart: longbool;                                  // 最初から演奏
        bSPCRefresh: longbool;                                  // 演奏状態を初期化
        bShiftButton: longbool;                                 // Shift
        bCtrlButton: longbool;                                  // Ctrl
        bBreakButton: longbool;                                 // Break
        bChangePlay: longbool;                                  // 演奏変更フラグ
        bChangeShift: longbool;                                 // Shift キー変更フラグ
        bOptionLock: longbool;                                  // オプションロック
        bWaveWrite: longbool;                                   // WAVE 書き込みフラグ
        dwReady: longword;                                      // 準備完了フラグ
        dwTitle: longword;                                      // タイトルフラグ
        dwInfo: longint;                                        // 情報フラグ
        dwRedrawInfo: longword;                                 // 再描画フラグ
        dwMenuFlags: longword;                                  // 選択されたメニュー情報
        dwLastTime: longword;                                   // 最後の演奏時間
        bTimeRepeat: longbool;                                  // 区間リピートフラグ
        dwPlayOrder: longword;                                  // 区間リピートする前の演奏順序
        dwStartTime: longword;                                  // リピート開始位置
        dwLastStartTime: longword;                              // 最後のリピート開始位置
        dwLimitTime: longword;                                  // リピート終了位置
        dwLastLimitTime: longword;                              // 最後のリピート終了位置
        dwTuningAddress: longword;                              // TUNING パラメータの開始アドレス
        dwTuningSize: longword;                                 // TUNING パラメータのサイズ
        dwOpenFilterIndex: longint;                             // ファイルタイプのインデックス (Open)
        dwSaveFilterIndex: longint;                             // ファイルタイプのインデックス (Save)
        DblClickPoint: TPOINT;                                  // ダブルクリック位置
        DragPoint: TPOINT;                                      // ドラッグ開始位置
        bDropCancel: longbool;                                  // ドロップ禁止フラグ
        dwScale: longint;                                       // 表示倍率
        BreakPoint: array[0..65535] of byte;                    // ブレイクポイントスイッチ
        dwNextTick: longword;                                   // 次の命令実行スイッチ
        DSPCheat: array[0..127] of word;                        // DSP チート
        bEmuDebug: longbool;                                    // 転送テストモード
        dwNoSleepTime: longword;                                // スリープ解除時間
        NowLevel: TLEVEL;                                       // 現在のレベル
        LastLevel: TLEVEL;                                      // 最後のレベル
        NumCache: array[0..287] of byte;                        // デジタル文字キャッシュ (48x6)
        SPCCache: array of TSPCCACHE;                           // シークキャッシュ
        Script700: TSCRIPT700DATA;                              // Script700 データ
        Tempo: TTEMPO;                                          // テンポ
        hBackBrush: longword;                                   // 背景色ブラシのハンドル
        hTextBrush: longword;                                   // 文字色ブラシのハンドル
        hMenuBrush: longword;                                   // メニュー背景色ブラシのハンドル
{$IFDEF CONTEXT}
        dwContextSize: longword;                                // SNESAPU コンテキストサイズ
        lpContext: pointer;                                     // SNESAPU コンテキストデータのポインタ
{$ENDIF}
{$IFDEF ITASKBARLIST3}
        ITaskbarList3: TITASKBARLIST3;                          // ITaskbarList3 インターフェイス
{$ENDIF}
    end;
    Option: record                                          // オプション
        dwAmp: longword;                                        // 音量
        dwBit: longint;                                         // ビット
        dwBmpFont: longword;                                    // 数値フォント
        bBPM: longbool;                                         // テンポ解析
        dwBufferNum: longword;                                  // バッファ数
        dwBufferTime: longword;                                 // バッファ時間
        dwCacheDiff: longword;                                  // シークキャッシュ適用差分
        dwCacheInt: longword;                                   // シークキャッシュ保存間隔
        dwCacheKOn: longword;                                   // シークキャッシュ KON 閾値
        dwCacheNum: longword;                                   // シークキャッシュ数
        dwChannel: longword;                                    // チャンネル
        dwDeviceID: longint;                                    // デバイス ID
        sDeviceName: string;                                    // デバイス名
        dwDrawInfo: longword;                                   // 情報描画フラグ
        bEarSafe: longbool;                                     // イヤーセーフ
        dwFadeTime: longword;                                   // デフォルトフェードアウト時間
        dwFeedback: longword;                                   // フィードバック反転度
        sFontName: string;                                      // フォント名
        dwHideTime: longword;                                   // デフォルトリセット時間
        dwInfo: longword;                                       // 情報表示
        dwInter: longword;                                      // 補間処理
        dwLanguage: longword;                                   // 言語
        dwListHeight: longword;                                 // プレイリストの高さ
        dwListMax: longint;                                     // プレイリスト登録最大件数
        dwMute: longword;                                       // チャンネルマスク
        dwNextTime: longword;                                   // デフォルト切り替え時間
        dwNoise: longword;                                      // チャンネルノイズ
        dwNoSleep: longword;                                    // スリープ解除
        dwOption: longword;                                     // 拡張設定
        dwPitch: longword;                                      // ピッチ
        bPitchAsync: longbool;                                  // ピッチ：演奏速度と同期
        dwPlayTime: longword;                                   // デフォルト演奏時間
        dwPlayMax: longint;                                     // 最大演奏時間
        dwPlayOrder: longword;                                  // 演奏順序
        dwPriority: longword;                                   // 基本優先度
        dwRate: longword;                                       // サンプリングレート
        dwScale: longint;                                       // 表示倍率
        dwSeekBar: longword;                                    // エンドレス時シークバー時間
        bSeekFast: longbool;                                    // 高速シーク
        dwSeekMax: longword;                                    // シーク可能時間
        bSeekAsync: longbool;                                   // シーク時間：演奏速度と同期
        dwSeekTime: longword;                                   // シーク時間
        dwSeparate: longword;                                   // 左右拡散度
        dwShiftKey: longword;                                   // シフトキー動作
        dwSpeedBas: longword;                                   // 演奏速度
        dwSpeedTun: longint;                                    // 演奏速度微調整
        dwTheme: longword;                                      // テーマ
        bTopMost: longbool;                                     // 常に手前に表示
        dwTimerOptionDisplay: longword;                         // オプション情報表示の時間
        dwTimerOptionLock: longword;                            // オプション変更ロックの時間
        dwTimerRedrawResume: longword;                          // サスペンド復帰後のウィンドウ再描画の時間
        dwVolumeColor: longword;                                // インジケータの色
        bVolumeReset: longbool;                                 // 無音チャンネル非表示
        dwVolumeSpeed: longword;                                // インジケータの減衰速度
        dwWaitTime: longword;                                   // デフォルトウェイト時間
        dwWaveBlank: longint;                                   // WAVE の最初の空白時間
        dwWaveFormat: longword;                                 // WAVE フォーマット
    end;
    CriticalSectionThread: TCRITICALSECTION;                // スレッドのクリティカルセクション
    CriticalSectionStatic: TCRITICALSECTION;                // 情報表示ウィンドウのクリティカルセクション
    KSDATAFORMAT_SUBTYPE_IEEE_FLOAT: TGUID;                 // KSDATAFORMAT_SUBTYPE_IEEE_FLOAT
    KSDATAFORMAT_SUBTYPE_PCM: TGUID;                        // KSDATAFORMAT_SUBTYPE_PCM
    IID_IDropSource: TGUID;                                 // IID_IDropSource
    IID_IDataObject: TGUID;                                 // IID_IDataObject
    IID_IUnknown: TGUID;                                    // IID_IUnknown
    GUID_CONSOLE_DISPLAY_STATE: TGUID;                      // GUID_CONSOLE_DISPLAY_STATE
{$IFDEF ITASKBARLIST3}
    CLSID_TaskbarList: TGUID;                               // CLSID_TaskbarList
    IID_ITaskbarList3: TGUID;                               // IID_ITaskbarList3
{$ENDIF}


// *************************************************************************************************************************************************************
// Win32 API の宣言
// *************************************************************************************************************************************************************

function  API_AppendMenu(hMenu: longword; uFlags: longword; uIDNewItem: longword; lpNewItem: pointer): longbool; stdcall; external 'user32.dll' name 'AppendMenuA';
function  API_BitBlt(hdcDest: longword; nXDest: longint; nYDest: longint; nWidthDest: longint; nHeightDest: longint; hdcSrc: longword; nXSrc: longint; nYSrc: longint; dwRop: longword): longbool; stdcall; external 'gdi32.dll' name 'BitBlt';
function  API_CallWindowProc(lpPrevWndFunc: pointer; hWnd: longword; msg: longword; wParam: longword; lParam: longword): longword; stdcall; external 'user32.dll' name 'CallWindowProcA';
function  API_CheckMenuItem(hMenu: longword; uID: longword; uCheck: longword): longword; stdcall; external 'user32.dll' name 'CheckMenuItem';
function  API_CloseHandle(hObject: longword): longbool; stdcall; external 'kernel32.dll' name 'CloseHandle';
function  API_CreateBitmap(nWidth: longint; nHeight: longint; nPlanes: longint; nBitCount: longint; lpBits: pointer): longword; stdcall; external 'gdi32.dll' name 'CreateBitmap';
function  API_CreateCompatibleBitmap(hDC: longword; nWidth: longint; nHeight: longint): longword; stdcall; external 'gdi32.dll' name 'CreateCompatibleBitmap';
function  API_CreateCompatibleDC(hDC: longword): longword; stdcall; external 'gdi32.dll' name 'CreateCompatibleDC';
function  API_CreateFile(lpFileName: pointer; dwDesiredAccess: longword; dwShareMode: longword; lpSecurityAttributes: pointer; dwCreationDisposition: longword; dwFlagsAndAttributes: longword; hTemplateFile: longword): longword; stdcall; external 'kernel32.dll' name 'CreateFileA';
function  API_CreateFont(nHeight: longint; nWidth: longint; nEscapement: longint; nOrientation: longint; fnWeight: longint; fdwItalic: longword; fdwUnderline: longword; fdwStrikeOut: longword; fdwCharSet: longword; fdwOutputPrecision: longword; fdwClipPrecision: longword; fdwQuality: longword; fdwPitchAndFamily: longword; lpszFace: pointer): longword; stdcall; external 'gdi32.dll' name 'CreateFontA';
function  API_CreateMenu(): longword; stdcall; external 'user32.dll' name 'CreateMenu';
function  API_CreatePopupMenu(): longword; stdcall; external 'user32.dll' name 'CreatePopupMenu';
function  API_CreateSolidBrush(color: longword): longword; stdcall; external 'gdi32.dll' name 'CreateSolidBrush';
function  API_CreateThread(lpThreadAttributes: pointer; dwStackSize: longword; lpStartAddress: pointer; lpParameter: pointer; dwCreationFlags: longword; lpThreadId: pointer): longword; stdcall; external 'kernel32.dll' name 'CreateThread';
function  API_CreateWindowEx(dwExStyle: longword; lpClassName: pointer; lpWindowName: pointer; dwStyle: longword; x: longint; y: longint; nWidth: longint; nHeight: longint; hWndParent: longword; hMenu: longword; hThisInstance: longword; lpParam: pointer): longword; stdcall; external 'user32.dll' name 'CreateWindowExA';
function  API_DefWindowProc(hWnd: longword; msg: longword; wParam: longword; lParam: longword): longword; stdcall; external 'user32.dll' name 'DefWindowProcA';
procedure API_DeleteCriticalSection(lpCriticalSection: pointer); stdcall; external 'kernel32.dll' name 'DeleteCriticalSection';
function  API_DeleteDC(hDC: longword): longbool; stdcall; external 'gdi32.dll' name 'DeleteDC';
function  API_DeleteMenu(hMenu: longword; uPosition: longword; uFlags: longword): longbool; stdcall; external 'user32.dll' name 'DeleteMenu';
function  API_DeleteObject(hObject: longword): longbool; stdcall; external 'gdi32.dll' name 'DeleteObject';
function  API_DestroyMenu(hMenu: longword): longbool; stdcall; external 'user32.dll' name 'DestroyMenu';
function  API_DestroyWindow(hWnd: longword): longbool; stdcall; external 'user32.dll' name 'DestroyWindow';
function  API_DispatchMessage(lpMsg: pointer): longword; stdcall; external 'user32.dll' name 'DispatchMessageA';
function  API_DoDragDrop(pDataObject: pointer; pDropSource: pointer; dwOKEffects: longword; pdwEffect: pointer): longword; stdcall; external 'ole32.dll' name 'DoDragDrop';
procedure API_DragFinish(hDrop: longword); stdcall; external 'shell32.dll' name 'DragFinish';
function  API_DragQueryFile(hDrop: longword; iFile: longword; lpszFile: pointer; cch: longword): longword; stdcall; external 'shell32.dll' name 'DragQueryFileA';
function  API_DragQueryPoint(hDrop: longword; ppt: pointer): longword; stdcall; external 'shell32.dll' name 'DragQueryPoint';
function  API_DrawMenuBar(hWnd: longword): longbool; stdcall; external 'user32.dll' name 'DrawMenuBar';
function  API_DrawText(hDC: longword; lpchText: pointer; cchText: longint; lprc: pointer; format: longword): longint; stdcall; external 'user32.dll' name 'DrawTextA';
function  API_EnableMenuItem(hMenu: longword; uID: longword; uEnable: longword): longbool; stdcall; external 'user32.dll' name 'EnableMenuItem';
function  API_EnableWindow(hWnd: longword; bEnable: longbool): longbool; stdcall; external 'user32.dll' name 'EnableWindow';
procedure API_EnterCriticalSection(lpCriticalSection: pointer); stdcall; external 'kernel32.dll' name 'EnterCriticalSection';
procedure API_FillMemory(Destination: pointer; Length: longword; Fill: byte); stdcall; external 'kernel32.dll' name 'RtlFillMemory';
function  API_FillRect(hDC: longword; lprc: pointer; hbr: longword): longint; stdcall; external 'user32.dll' name 'FillRect';
function  API_FindClose(hFindFile: longword): longbool; stdcall; external 'kernel32.dll' name 'FindClose';
function  API_FindFirstFile(lpFileName: pointer; lpFindFileData: pointer): longword; stdcall; external 'kernel32.dll' name 'FindFirstFileA';
function  API_FindNextFile(hFindFile: longword; lpFindFileData: pointer): longbool; stdcall; external 'kernel32.dll' name 'FindNextFileA';
function  API_FindWindowEx(hwndParent: longword; hwndChildAfter: longword; lpClassName: pointer; lpWindowName: pointer): longword; stdcall; external 'user32.dll' name 'FindWindowExA';
function  API_FreeLibrary(hModule: longword): longbool; stdcall; external 'kernel32.dll' name 'FreeLibrary';
function  API_GetClientRect(hWnd: longword; lpRect: pointer): longbool; stdcall; external 'user32.dll' name 'GetClientRect';
function  API_GetCommandLine(): pointer; stdcall; external 'kernel32.dll' name 'GetCommandLineA';
function  API_GetCurrentProcess(): longword; stdcall; external 'kernel32.dll' name 'GetCurrentProcess';
function  API_GetDC(hWnd: longword): longword; stdcall; external 'user32.dll' name 'GetDC';
function  API_GetFileAttributes(lpFileName: pointer): longword; stdcall; external 'kernel32.dll' name 'GetFileAttributesA';
function  API_GetFileSize(hFile: longword; pFileSizeHigh: pointer): longword; stdcall; external 'kernel32.dll' name 'GetFileSize';
function  API_GetFileTitle(lpszFile: pointer; lpszTitle: pointer; cbBuf: word): shortint; stdcall; external 'comdlg32.dll' name 'GetFileTitleA';
function  API_GetFocus(): longword; stdcall; external 'user32.dll' name 'GetFocus';
function  API_GetForegroundWindow(): longword; stdcall; external 'user32.dll' name 'GetForegroundWindow';
function  API_GetKeyboardState(lpKeyState: pointer): longbool; stdcall; external 'user32.dll' name 'GetKeyboardState';
function  API_GetLastError(): longword; stdcall; external 'kernel32.dll' name 'GetLastError';
function  API_GetMenuBarInfo(hWnd: longword; idObject: longword; idItem: longword; pmbi: pointer): longbool; stdcall; external 'user32.dll' name 'GetMenuBarInfo';
function  API_GetMenuItemInfo(hMenu: longword; item: longword; fByPosition: longbool; lpmii: pointer): longbool; stdcall; external 'user32.dll' name 'GetMenuItemInfoW';
function  API_GetMenuState(hMenu: longword; uID: longword; uFlags: longword): longword; stdcall; external 'user32.dll' name 'GetMenuState';
function  API_GetMessage(lpMsg: pointer; hWnd: longword; wMessageFilterMin: longword; wMessageFilterMax: longword): longbool; stdcall; external 'user32.dll' name 'GetMessageA';
function  API_GetModuleFileName(hModule: longword; lpFileName: pointer; nSize: longword): longword; stdcall; external 'kernel32.dll' name 'GetModuleFileNameA';
function  API_GetMonitorInfo(hMonitor: longword; lpmi: pointer): longbool; stdcall; external 'user32.dll' name 'GetMonitorInfoA';
function  API_GetNextDlgTabItem(hDlg: longword; hCtl: longword; bPrevious: longbool): longword; stdcall; external 'user32.dll' name 'GetNextDlgTabItem';
function  API_GetOpenFileName(lpofn: pointer): longbool; stdcall; external 'comdlg32.dll' name 'GetOpenFileNameA';
function  API_GetPixel(hDC: longword; x: longint; y: longint): longword; stdcall; external 'gdi32.dll' name 'GetPixel';
function  API_GetPriorityClass(hProcess: longword): longword; stdcall; external 'kernel32.dll' name 'GetPriorityClass';
function  API_GetProcAddress(hModule: longword; lpProcName: pointer): pointer; stdcall; external 'kernel32.dll' name 'GetProcAddress';
function  API_GetSaveFileName(lpofn: pointer): longbool; stdcall; external 'comdlg32.dll' name 'GetSaveFileNameA';
function  API_GetUserDefaultLCID(): longword; stdcall; external 'kernel32.dll' name 'GetUserDefaultLCID';
function  API_GetSysColor(nIndex: longint): longword; stdcall; external 'user32.dll' name 'GetSysColor';
function  API_GetSysColorBrush(nIndex: longint): longword; stdcall; external 'user32.dll' name 'GetSysColorBrush';
function  API_GetSystemMenu(hWnd: longword; bRevert: longbool): longword; stdcall; external 'user32.dll' name 'GetSystemMenu';
function  API_GetSystemMetrics(nIndex: longint): longint; stdcall; external 'user32.dll' name 'GetSystemMetrics';
function  API_GetVersionEx(lpVersionInfo: pointer): longbool; stdcall; external 'kernel32.dll' name 'GetVersionExA';
function  API_GetWindowDC(hWnd: longword): longword; stdcall; external 'user32.dll' name 'GetWindowDC';
function  API_GetWindowLong(hWnd: longword; nIndex: longint): longword; stdcall; external 'user32.dll' name 'GetWindowLongA';
function  API_GetWindowPlacement(hWnd: longword; lpwndpl: pointer): longbool; stdcall; external 'user32.dll' name 'GetWindowPlacement';
function  API_GetWindowRect(hWnd: longword; lpRect: pointer): longbool; stdcall; external 'user32.dll' name 'GetWindowRect';
function  API_GetWindowText(hWnd: longword; lpString: pointer; nMaxCount: longint): longint; stdcall; external 'user32.dll' name 'GetWindowTextA';
function  API_GdiFlush(): longbool; stdcall; external 'gdi32.dll' name 'GdiFlush';
function  API_GlobalAlloc(uFlags: longword; dwBytes: longword): longword; stdcall; external 'kernel32.dll' name 'GlobalAlloc';
function  API_GlobalFree(hMem: longword): longword; stdcall; external 'kernel32.dll' name 'GlobalFree';
procedure API_InitializeCriticalSection(lpCriticalSection: pointer); stdcall; external 'kernel32.dll' name 'InitializeCriticalSection';
function  API_InsertMenu(hMenu: longword; uPosition: longword; uFlags: longword; uIDNewItem: longword; lpNewItem: pointer): longbool; stdcall; external 'user32.dll' name 'InsertMenuA';
function  API_InterlockedDecrement(lpAddend: pointer): longword; stdcall; external 'kernel32.dll' name 'InterlockedDecrement';
function  API_InterlockedIncrement(lpAddend: pointer): longword; stdcall; external 'kernel32.dll' name 'InterlockedIncrement';
function  API_InvalidateRect(hWnd: longword; lpRect: pointer; bErase: longbool): longbool; stdcall; external 'user32.dll' name 'InvalidateRect';
function  API_IsWindowEnabled(hWnd: longword): longbool; stdcall; external 'user32.dll' name 'IsWindowEnabled';
function  API_KillTimer(hWnd: longword; uIDEvent: longword): longbool; stdcall; external 'user32.dll' name 'KillTimer';
procedure API_LeaveCriticalSection(lpCriticalSection: pointer); stdcall; external 'kernel32.dll' name 'LeaveCriticalSection';
function  API_LoadBitmap(hThisInstance: longword; lpBitmapName: pointer): longword; stdcall; external 'user32.dll' name 'LoadBitmapA';
function  API_LoadCursor(hThisInstance: longword; lpCursorName: pointer): longword; stdcall; external 'user32.dll' name 'LoadCursorA';
function  API_LoadIcon(hThisInstance: longword; lpIconName: pointer): longword; stdcall; external 'user32.dll' name 'LoadIconA';
function  API_LoadLibraryEx(lpLibFileName: pointer; hFile: longword; dwFlags: longword): longword; stdcall; external 'kernel32.dll' name 'LoadLibraryExA';
function  API_MakeSureDirectoryPathExists(lpPath: pointer): longbool; stdcall; external 'imagehlp.dll' name 'MakeSureDirectoryPathExists';
function  API_MapFileAndCheckSum(Filename: pointer; HeaderSum: pointer; CheckSum: pointer): longword; stdcall; external 'imagehlp.dll' name 'MapFileAndCheckSumA';
function  API_MessageBox(hWnd: longword; lpText: pointer; lpCaption: pointer; uType: longword): longint; stdcall; external 'user32.dll' name 'MessageBoxA';
function  API_MonitorFromRect(lprc: pointer; dwFlags: longword): longword; stdcall; external 'user32.dll' name 'MonitorFromRect';
procedure API_MoveMemory(Destination: pointer; Source: pointer; Length: longword); stdcall; external 'kernel32.dll' name 'RtlMoveMemory';
function  API_MoveWindow(hWnd: longword; x: longint; y: longint; nWidth: longint; nHeight: longint; bRepaint: longbool): longbool; stdcall; external 'user32.dll' name 'MoveWindow';
function  API_MultiByteToWideChar(dwCodePage: longword; dwFlags: longword; lpMultiByteStr: pointer; cchMultiByte: longint; lpWideCharStr: pointer; cchWideChar: longint): longint; stdcall; external 'kernel32.dll' name 'MultiByteToWideChar';
function  API_OleDuplicateData(hSrc: longword; cfFormat: word; uiFlags: longword): longword; stdcall; external 'ole32.dll' name 'OleDuplicateData';
function  API_OleInitialize(pvReserved: pointer): longword; stdcall; external 'ole32.dll' name 'OleInitialize';
procedure API_OleUninitialize(); stdcall; external 'ole32.dll' name 'OleUninitialize';
function  API_PeekMessage(lpMsg: pointer; hWnd: longword; wMessageFilterMin: longword; wMessageFilterMax: longword; wRemoveMsg: longword): longbool; stdcall; external 'user32.dll' name 'PeekMessageA';
function  API_PostMessage(hWnd: longword; msg: longword; wParam: longword; lParam: longword): longbool; stdcall; external 'user32.dll' name 'PostMessageA';
function  API_PostThreadMessage(idThread: longword; msg: longword; wParam: longword; lParam: longword): longbool; stdcall; external 'user32.dll' name 'PostThreadMessageA';
function  API_ReadFile(hFile: longword; lpBuffer: pointer; nNumberOfBytesToRead: longword; lpNumberOfBytesRead: pointer; lpOverlapped: pointer): longbool; stdcall; external 'kernel32.dll' name 'ReadFile';
function  API_RedrawWindow(hWnd: longword; lprcUpdate: pointer; hrgnUpdate: longword; flags: longword): longint; stdcall; external 'user32.dll' name 'RedrawWindow';
function  API_RegisterClassEx(lpwcx: pointer): smallint; stdcall; external 'user32.dll' name 'RegisterClassExA';
function  API_ReleaseDC(hWnd: longword; hDC: longword): longint; stdcall; external 'user32.dll' name 'ReleaseDC';
procedure API_ReleaseStgMedium(lpStgMedium: pointer); stdcall; external 'ole32.dll' name 'ReleaseStgMedium';
function  API_SelectObject(hDC: longword; hGdiObj: longword): longword; stdcall; external 'gdi32.dll' name 'SelectObject';
function  API_SendMessage(hWnd: longword; msg: longword; wParam: longword; lParam: longword): longword; stdcall; external 'user32.dll' name 'SendMessageA';
function  API_SetBkColor(hDC: longword; crColor: longword): longword; stdcall; external 'gdi32.dll' name 'SetBkColor';
function  API_SetClassLong(hWnd: longword; nIndex: longint; dwNewLong: longword): longword; stdcall; external 'user32.dll' name 'SetClassLongA';
function  API_SetEndOfFile(hFile: longword): longbool; stdcall; external 'kernel32.dll' name 'SetEndOfFile';
function  API_SetFilePointer(hFile: longword; lDistanceToMove: longword; lpDistanceToMoveHigh: pointer; dwMoveMethod: longword): longword; stdcall; external 'kernel32.dll' name 'SetFilePointer';
function  API_SetFocus(hWnd: longword): longword; stdcall; external 'user32.dll' name 'SetFocus';
function  API_SetForegroundWindow(hWnd: longword): longbool; stdcall; external 'user32.dll' name 'SetForegroundWindow';
function  API_SetMenu(hWnd: longword; hMenu: longword): longbool; stdcall; external 'user32.dll' name 'SetMenu';
function  API_SetPixel(hDC: longword; x: longint; y: longint; crColor: longword): longword; stdcall; external 'gdi32.dll' name 'SetPixel';
function  API_SetPriorityClass(hProcess: longword; dwPriorityClass: longword): longbool; stdcall; external 'kernel32.dll' name 'SetPriorityClass';
function  API_SetTextColor(hDC: longword; crColor: longword): longword; stdcall; external 'gdi32.dll' name 'SetTextColor';
function  API_SetThreadExecutionState(esFlags: longword): longword; stdcall; external 'kernel32.dll' name 'SetThreadExecutionState';
function  API_SetTimer(hWnd: longword; uIDEvent: longword; uElapse: longword; lpTimerFunc: pointer): longword; stdcall; external 'user32.dll' name 'SetTimer';
function  API_SetWindowLong(hWnd: longword; nIndex: longint; dwNewLong: longword): longword; stdcall; external 'user32.dll' name 'SetWindowLongA';
function  API_SetWindowPlacement(hWnd: longword; lpwndpl: pointer): longbool; stdcall; external 'user32.dll' name 'SetWindowPlacement';
function  API_SetWindowPos(hWnd: longword; hWndInsertAfter: longword; x: longint; y: longint; cx: longint; cy: longint; uFlags: longword): longbool; stdcall; external 'user32.dll' name 'SetWindowPos';
function  API_SetWindowText(hWnd: longword; lpString: pointer): longbool; stdcall; external 'user32.dll' name 'SetWindowTextA';
procedure API_Sleep(dwMilliseconds: longword); stdcall; external 'kernel32.dll' name 'Sleep';
function  API_StretchBlt(hdcDest: longword; nXDest: longint; nYDest: longint; nWidthDest: longint; nHeightDest: longint; hdcSrc: longword; nXSrc: longint; nYSrc: longint; nWidthSrc: longint; nHeightSrc: longint; dwRop: longword): longbool; stdcall; external 'gdi32.dll' name 'StretchBlt';
function  API_SystemParametersInfo(uAction: longword; uParam: longword; pParam: pointer; fWinIni: longword): longbool; stdcall; external 'user32.dll' name 'SystemParametersInfoA';
function  API_TranslateMessage(lpMsg: pointer): longbool; stdcall; external 'user32.dll' name 'TranslateMessage';
function  API_UnregisterClass(lpClassName: pointer; hThisInstance: longword): longbool; stdcall; external 'user32.dll' name 'UnregisterClassA';
function  API_UpdateWindow(hWnd: longword): longbool; stdcall; external 'user32.dll' name 'UpdateWindow';
function  API_waveOutClose(hwo: longword): longword; stdcall; external 'winmm.dll' name 'waveOutClose';
function  API_waveOutGetDevCaps(uDeviceID: longword; pwoc: pointer; cbwoc: longword): longword; stdcall; external 'winmm.dll' name 'waveOutGetDevCapsA';
function  API_waveOutGetNumDevs(): longword; stdcall; external 'winmm.dll' name 'waveOutGetNumDevs';
function  API_waveOutOpen(phwo: pointer; uDeviceID: longword; pwfx: pointer; dwCallback: longword; dwCallbackInstance: longword; fdwOpen: longword): longword; stdcall; external 'winmm.dll' name 'waveOutOpen';
function  API_waveOutPause(hwo: longword): longword stdcall; external 'winmm.dll' name 'waveOutPause';
function  API_waveOutPrepareHeader(hwo: longword; pwh: pointer; cbwh: longword): longword; stdcall; external 'winmm.dll' name 'waveOutPrepareHeader';
function  API_waveOutReset(hwo: longword): longword; stdcall; external 'winmm.dll' name 'waveOutReset';
function  API_waveOutRestart(hwo: longword): longword; stdcall; external 'winmm.dll' name 'waveOutRestart';
function  API_waveOutUnprepareHeader(hwo: longword; pwh: pointer; cbwh: longword): longword; stdcall; external 'winmm.dll' name 'waveOutUnprepareHeader';
function  API_waveOutWrite(hwo: longword; pwh: pointer; cbwh: longword): longword; stdcall; external 'winmm.dll' name 'waveOutWrite';
function  API_WriteFile(hFile: longword; lpBuffer: pointer; nNumberOfBytesToRead: longword; lpNumberOfBytesRead: pointer; lpOverlapped: pointer): longbool; stdcall; external 'kernel32.dll' name 'WriteFile';
procedure API_ZeroMemory(Destination: pointer; Length: longword); stdcall; external 'kernel32.dll' name 'RtlZeroMemory';
{$IFDEF ITASKBARLIST3}
function  API_CoCreateInstance(rclsid: pointer; pUnkOuter: pointer; dwClsContext: longword; riid: pointer; ppv: pointer): longword; stdcall; external 'ole32.dll' name 'CoCreateInstance';
function  API_CoInitialize(pvReserved: pointer): longword; stdcall; external 'ole32.dll' name 'CoInitialize';
function  API_CoUninitialize(): longword; stdcall; external 'ole32.dll' name 'CoUninitialize';
{$ENDIF}
{$IFDEF PERFORMANCETEST}
function  API_timeGetTime(): longword; stdcall; external 'winmm.dll' name 'timeGetTime';
{$ENDIF}


// *************************************************************************************************************************************************************
// 外部拡張コード
// *************************************************************************************************************************************************************

// ================================================================================
// API_TransparentBlt - TransparentBlt の 32bit カラー対応版
// ================================================================================
procedure API_TransparentBlt(hdcDest: longword; nXDest: longint; nYDest: longint; nWidthDest: longint; nHeightDest: longint; hdcSrc: longword; nXSrc: longint;
    nYSrc: longint; nWidthSrc: longint; nHeightSrc: longint; crTransparent: longword);
var
    hDCMaskBase: longword;
    hBitmapMaskBase: longword;
    hDCMaskDest: longword;
    hBitmapMaskDest: longword;
    dwOriginalColor: longword;
begin
    // デバイスコンテキストを作成
    hDCMaskBase := API_CreateCompatibleDC(hdcDest);
    hBitmapMaskBase := API_SelectObject(hDCMaskBase, API_CreateBitmap(nWidthDest, nHeightDest, 1, 1, NULLPOINTER));
    hDCMaskDest := API_CreateCompatibleDC(hdcDest);
    hBitmapMaskDest := API_SelectObject(hDCMaskDest, API_CreateCompatibleBitmap(hdcDest, nWidthDest, nHeightDest));
    // 透過色部分を除いて画像をコピー
    API_StretchBlt(hDCMaskDest, 0, 0, nWidthDest, nHeightDest, hdcSrc, 0, 0, nWidthSrc, nHeightSrc, SRCCOPY);
    dwOriginalColor := API_SetBkColor(hDCMaskDest, crTransparent);
    API_BitBlt(hDCMaskBase, 0, 0, nWidthDest, nHeightDest, hDCMaskDest, 0, 0, SRCCOPY);
    API_SetBkColor(hDCMaskDest, dwOriginalColor);
    API_BitBlt(hdcDest, 0, 0, nWidthDest, nHeightDest, hDCMaskBase, 0, 0, SRCAND);
    API_BitBlt(hDCMaskBase, 0, 0, nWidthDest, nHeightDest, hDCMaskBase, 0, 0, NOTSRCCOPY);
    API_BitBlt(hDCMaskDest, 0, 0, nWidthDest, nHeightDest, hDCMaskBase, 0, 0, SRCAND);
    API_BitBlt(hdcDest, nXDest, nYDest, nWidthDest, nHeightDest, hDCMaskDest, 0, 0, SRCPAINT);
    // デバイスコンテキストを削除
    API_DeleteObject(API_SelectObject(hDCMaskBase, hBitmapMaskBase));
    API_DeleteDC(hDCMaskBase);
    API_DeleteObject(API_SelectObject(hDCMaskDest, hBitmapMaskDest));
    API_DeleteDC(hDCMaskDest);
    // GDI 描画をフラッシュ
    API_GdiFlush();
end;

// ================================================================================
// Exists - フォルダ・ファイル存在チェック
// ================================================================================
function Exists(lpPath: pointer; dwFileMode: longword): longbool;
var
    dwResult: longword;
begin
    result := false;
    dwResult := API_GetFileAttributes(lpPath);
    if dwResult = INVALID_HANDLE_VALUE then exit;
    result := longbool((dwResult xor dwFileMode) and FILE_ATTRIBUTE_DIRECTORY);
end;

// ================================================================================
// GetSize - 文字列バッファの使用バイト数取得
// ================================================================================
function GetSize(lpBuffer: pointer; dwMax: longword): longword;
var
    dwOffset: longword;
begin
    // 初期化
    result := 0;
    dwOffset := longword(lpBuffer);
    while bytebool(pointer(dwOffset + result)^) and (result < dwMax) do Inc(result);
end;

// ================================================================================
// IntToHex - 数値を文字列に変換
// ================================================================================
function IntToHex(var StrData: TSTRDATA; X: longword; Len: longword): longword;
var
    I: longword;
begin
    result := Len;
    I := Len;
    StrData.qwData := $3030303030303030; // '00000000'
{$IFDEF FREEPASCAL}
    while not (not longbool(I) or not longbool(X)) do begin
{$ELSE}
    while longbool(I) and longbool(X) do begin
{$ENDIF}
        Dec(I);
        StrData.cData[I] := HexTable[X and $F];
        X := X shr 4;
    end;
end;

// ================================================================================
// IntToStr - 数値を文字列に変換
// ================================================================================
function IntToStr(var StrData: TSTRDATA; X: longword; Len: longword): longword; overload;
var
    I: longword;
begin
    result := Len;
    I := Len;
    StrData.qwData := $3030303030303030; // '00000000'
{$IFDEF FREEPASCAL}
    while not (not longbool(I) or not longbool(X)) do begin
{$ELSE}
    while longbool(I) and longbool(X) do begin
{$ENDIF}
        Dec(I);
        StrData.cData[I] := HexTable[X mod 10];
        X := X div 10;
    end;
end;

// ================================================================================
// IntToStr - 数値を文字列に変換
// ================================================================================
function IntToStr(X: longword): string; overload;
var
    I: longword;
begin
    if not longbool(X) then begin
        result := '0';
        exit;
    end;
    I := 12;
    result := '00000000000';
    while longbool(X) do begin
        Dec(I);
        result[I] := HexTable[X mod 10];
        X := X div 10;
    end;
    result := Copy(result, I, 11);
end;

// ================================================================================
// IntToStr - 数値を文字列に変換
// ================================================================================
function IntToStr(X: longint): string; overload;
var
    I: longword;
begin
    if X >= 0 then begin
        result := IntToStr(longword(X));
        exit;
    end;
    X := -X;
    I := 11;
    result := '00000000000';
    while longbool(X) do begin
        result[I] := HexTable[X mod 10];
        X := X div 10;
        Dec(I);
    end;
    result[I] := '-';
    result := Copy(result, I, 11);
end;

// ================================================================================
// IsEqualsGUID - GUID 比較
// ================================================================================
function IsEqualsGUID(S: TGUID; D: TGUID): longbool;
var
    I: longint;
begin
    result := true;
    for I := 0 to 3 do if S.DataX[I] <> D.DataX[I] then result := false;
end;

// ================================================================================
// IsSingleByte - 1 バイト文字比較
// ================================================================================
function IsSingleByte(const S: string; X: longword; const Match: char): longbool;
var
    X1: longword;
    X2: longword;
    B1: byte;
    B2: byte;
begin
    result := false;
    if char(S[X]) <> Match then exit;
    X1 := X - 1;
    X2 := X - 2;
    if X >= 2 then B1 := byte(S[X1]) else B1 := 0;
    if X >= 3 then B2 := byte(S[X2]) else B2 := 0;
    result := X = 1;
    if not result and (X >= 2) and not (((B1 >= $81) and (B1 <= $9F)) or ((B1 >= $E0) and (B1 <= $FC))) then result := true;
    if not result and (X >= 3) and     (((B2 >= $81) and (B2 <= $9F)) or ((B2 >= $E0) and (B2 <= $FC)))
    and (((B1 >= $40) and (B1 <= $7E)) or ((B1 >= $80) and (B1 <= $FC))) then result := true;
end;

// ================================================================================
// IsPathSeparator - ファイルパスの区切り文字を比較
// ================================================================================
function IsPathSeparator(const S: string; X: longword): longbool;
begin
    result := IsSingleByte(S, X, '\') or IsSingleByte(S, X, '/');
end;

// ================================================================================
// GetPosSeparator - 最後が区切り文字の位置を取得
// ================================================================================
function GetPosSeparator(const S: string): longint;
var
    I: longword;
    J: longword;
begin
    result := 0;
    J := Length(S);
    for I := 1 to J do if IsPathSeparator(S, I) then result := I;
end;

// ================================================================================
// Log10 - Log を計算
// ================================================================================
function Log10(X: double): double;
begin
    result := Ln(X) * 0.43429448190325182765112891891661; // Ln(X) / Ln(10)
end;

// ================================================================================
// Max - A, B のうち大きい値を取得
// ================================================================================
function Max(A: longint; B: longint): longint;
begin
    if A > B then result := A else result := B;
end;

// ================================================================================
// Min - A, B のうち小さい値を取得
// ================================================================================
function Min(A: longint; B: longint): longint;
begin
    if A < B then result := A else result := B;
end;

// ================================================================================
// ChrToStr - キャラクタの動的配列を文字列に変換
// ================================================================================
function ChrToStr(var C: array of char): string;
var
    S: string;
begin
    // NOTE: Free Pascal の場合、char 型の動的配列を string にキャストするためには、
    // SetString を使用しないと、文字列が正しく結合されないなどの不具合が発生する
    SetString(S, pchar(@C[0]), GetSize(@C[0], SizeOf(C)));
    result := S;
end;

// ================================================================================
// PtrToStr - キャラクタ配列のポインタを文字列に変換
// ================================================================================
function PtrToStr(P: pointer): string;
var
    S: string;
begin
    // NOTE: Free Pascal の場合、ポインタから string にキャストするためには、
    // SetString を使用しないと、文字列が正しく結合されないなどの不具合が発生する
    SetString(S, pchar(P), GetSize(P, 4096));
    result := S;
end;

// ================================================================================
// StrToInt - 文字列を数値に変換
// ================================================================================
function StrToInt(const S: string; Def: longint): longint; overload;
var
    I: longword;
    Sign: longbool;
    Size: longword;
    Start: longword;
    C: char;
begin
    result := 0;
    Size := Length(S);
    if Size > 0 then Sign := S[1] = '-' else Sign := false;
    if Sign then Start := 2 else Start := 1;
    for I := Start to Size do begin
        C := S[I];
        if (byte(C) >= $30) and (byte(C) <= $39) then begin
            result := result * 10 + byte(C) - $30;
        end else begin
            result := Def;
            exit;
        end;
    end;
    if Sign then result := -result;
end;

// ================================================================================
// StrToInt - 文字列を数値に変換
// ================================================================================
function StrToInt(const S: string; Def: longword): longword; overload;
var
    I: longword;
    Size: longword;
    C: char;
begin
    result := 0;
    Size := Length(S);
    for I := 1 to Size do begin
        C := S[I];
        if (byte(C) >= $30) and (byte(C) <= $39) then begin
            result := result * 10 + byte(C) - $30;
        end else begin
            result := Def;
            exit;
        end;
    end;
end;

// ================================================================================
// Trim - 空白除去
// ================================================================================
function Trim(const S: string): string;
var
    I: longint;
    J: longint;
    Size: longint;
begin
    Size := Length(S);
    I := 1;
    J := Size;
    while (I <= Size) and (S[I] = ' ') do Inc(I);
    while (J >= 1   ) and (S[J] = ' ') do Dec(J);
    Size := J - I + 1;
    if Size <= 0 then result := '' else result := Copy(S, I, Size);
end;


// *************************************************************************************************************************************************************
// メインプロシージャ
// *************************************************************************************************************************************************************

// ================================================================================
// WriteLog - デバッグログ出力
// ================================================================================
{$IFDEF DEBUGLOG}
procedure _WriteLog(const S: string);
var
    tf: textfile;
begin
    AssignFile(tf, 'spcplay.log');
    Append(tf);
    Writeln(tf, S);
    CloseFile(tf);
end;
{$ENDIF}

// ================================================================================
// SNESAPUCallback - SNESAPU コールバック
// ================================================================================
function _SNESAPUCallback(dwEffect: longword; dwAddr: longword; dwValue: longword; lpData: pointer): longword; stdcall;
var
    dwTemp: longword;

procedure IncludeScript700File(dwAddr: longword);
var
    I: longword;
    J: longword;
    lpBuffer: pointer;
begin
    // バッファのサイズを取得
    I := GetSize(Status.lpSPCDir, 1024);
    J := GetSize(lpData, 1024);
    if I + J > 1024 then exit;
    // バッファを確保
    GetMem(lpBuffer, 1024);
    // カレントディレクトリをコピー
    API_ZeroMemory(lpBuffer, 1024);
    API_MoveMemory(lpBuffer, Status.lpSPCDir, I);
    API_MoveMemory(pointer(longword(lpBuffer) + I), lpData, J);
    // Script700 をロード
    Status.cfMain.LoadScript700(lpBuffer, dwAddr);
    // バッファを解放
    FreeMem(lpBuffer, 1024);
end;

procedure RequestBreakPoint();
begin
    // クリティカルセクションを開始
    API_EnterCriticalSection(@CriticalSectionThread);
    // コールバックを追加設定
    Apu.SNESAPUCallback(@_SNESAPUCallback, CBE_S700FCH);
    // BreakPoint 設定
    if longbool(dwAddr and $10000) then API_ZeroMemory(@Status.BreakPoint, 65536)
    else Status.BreakPoint[dwAddr and $FFFF] := dwValue and $FF or $80;
    // クリティカルセクションを終了
    API_LeaveCriticalSection(@CriticalSectionThread);
end;

procedure AnalyzeTempo();
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

begin
    result := dwValue;
    case dwEffect of
        CBE_INCS700: IncludeScript700File(SCRIPT700_TEXT); // #include Script700 text
        CBE_INCDATA: IncludeScript700File(dwAddr); // #include Script700 binary
        CBE_REQBP: RequestBreakPoint();
        CBE_DSPREG: begin
            dwTemp := dwAddr and $7F;
            if longbool(Status.DSPCheat[dwTemp]) then result := Status.DSPCheat[dwTemp] and $FF;
            if Status.bWaveWrite and Option.bBPM then case dwTemp of
                $4C: AnalyzeTempo();
                $5C: Status.Tempo.cKOn := Status.Tempo.cKOn and (dwValue xor $FF and $FF);
            end;
{$IFDEF DEBUGLOG}
            _WriteLog(Concat('DSP   : ', IntToStr(dwAddr), ' ', IntToStr(dwValue), ' ', IntToStr(longword(lpData))));
{$ENDIF}
        end;
        CBE_S700FCH: begin
            if not Status.bWaveWrite then exit
            else if longbool(Status.dwNextTick and BRKP_NEXT_STOP) then Status.dwNextTick := (Status.dwNextTick and $FF) or BRKP_STOPPED
            else if longbool(Status.dwNextTick and BRKP_STOPPED) then result := dwValue or (Status.dwNextTick and $FF)
            else if longbool(Status.dwNextTick and BRKP_RELEASE) then Status.dwNextTick := 0
            else result := dwValue or Status.BreakPoint[longword(lpData) and $FFFF];
{$IFDEF DEBUGLOG}
            _WriteLog(Concat('SPC700: ', IntToStr(dwAddr), ' ', IntToStr(dwValue), ' ', IntToStr(longword(lpData))));
{$ENDIF}
        end;
    end;
end;

// ================================================================================
// WindowProc - ウィンドウプロシージャ
// ================================================================================
function _WindowProc(hWnd: longword; msg: longword; wParam: longword; lParam: longword): longword; stdcall;
var
    dwDef: longword;
begin
    // メッセージ処理
    dwDef := 0;
    result := Status.cfMain.WindowProc(hWnd, msg, wParam, lParam, dwDef);
    if not longbool(dwDef) then result := API_DefWindowProc(hWnd, msg, wParam, lParam);
end;

// ================================================================================
// WinMain - ウィンドウメイン関数
// ================================================================================
function _WinMain(hThisInstance: longword; hPrevInstance: longword; lpArgs: pointer; nCmdShow: longint): longword; stdcall;
var
    cfMain: CWINDOWMAIN;
    cwWindowMain: CWINDOW;
    dwBuffer: longword;
    bTransmitMsg: longbool;
    Msg: TMSG;
    dwKeyCode: longword;
    API_SetDllDirectory: function(lpPathName: pointer): longbool; stdcall;
begin
    // KERNEL32.DLL をロード
    dwBuffer := API_LoadLibraryEx(pchar('kernel32.dll'), NULL, LOAD_LIBRARY_SEARCH_SYSTEM32);
    if longbool(dwBuffer) then begin
        // 検索パスからカレントパスを削除 (for Windows XP SP1)
        @API_SetDllDirectory := API_GetProcAddress(dwBuffer, pchar('SetDllDirectoryA'));
        if longbool(@API_SetDllDirectory) then API_SetDllDirectory(pchar(''));
        // DLL を解放
        API_FreeLibrary(dwBuffer);
    end;
    // wParam を初期化
    Msg.wParam := 0;
    // クリティカルセクションを作成
    API_InitializeCriticalSection(@CriticalSectionThread);
    API_InitializeCriticalSection(@CriticalSectionStatic);
    // ウィンドウクラスを作成
    Status.ccClass := CCLASS.Create();
    Status.ccClass.CreateClass(@_WindowProc, hThisInstance, pchar(CLASS_NAME), CS_HREDRAW or CS_VREDRAW or CS_OWNDC, pchar(ICON_NAME),
        NULLPOINTER, IDC_ARROW, ORG_COLOR_BTNFACE);
    // ウィンドウを作成
    cfMain := CWINDOWMAIN.Create();
    Status.cfMain := cfMain;
    dwBuffer := cfMain.CreateWindow(hThisInstance, pchar(CLASS_NAME), lpArgs);
    // 起動に成功した場合
    if not longbool(dwBuffer) then begin
        // ウィンドウを取得
        cwWindowMain := cfMain.cwWindowMain;
        // メッセージを受け取るまで待機する。 WM_QUIT の場合はループを抜ける
        while API_GetMessage(@Msg, NULL, NULL, NULL) do begin
            // 初期化
            bTransmitMsg := true;
            // メッセージ処理
            case Msg.msg of
                WM_SYSKEYDOWN: begin // Alt キー + 任意のキー
                    dwKeyCode := Msg.wParam and $FF;
                    case dwKeyCode of
                        VK_UP: cfMain.ListUp(); // Alt + ↑ キー
                        VK_DOWN: cfMain.ListDown(); // Alt + ↓ キー
                        VK_LEFT: cfMain.SetFunction(-1, FUNCTION_TYPE_AMP); // Alt + ← キー
                        VK_RIGHT: cfMain.SetFunction(1, FUNCTION_TYPE_AMP); // Alt + → キー
                    end;
                end;
                WM_KEYDOWN: begin // 任意のキー
                    // メッセージを転送しない
                    bTransmitMsg := false;
                    // Ctrl キーが押されている場合
                    dwKeyCode := Msg.wParam and $FF;
                    if Status.bCtrlButton then case dwKeyCode of
                        VK_B: cfMain.ListNextPlay(PLAY_ORDER_NEXT, LIST_NEXT_PLAY_SELECT); // Ctrl + B キー
                        VK_C: cfMain.SPCPlay(PLAY_TYPE_PAUSE); // Ctrl + C キー
                        VK_O: cwWindowMain.PostMessage(WM_APP_COMMAND, MENU_FILE_OPEN, Msg.lParam); // Ctrl + O キー
                        VK_P: cfMain.SPCPlay(PLAY_TYPE_AUTO); // Ctrl + P キー
                        VK_Q: cwWindowMain.PostMessage(WM_QUIT, NULL, NULL); // Ctrl + Q キー
                        VK_R: cfMain.SPCStop(true); // Ctrl + R キー
                        VK_S: cwWindowMain.PostMessage(WM_APP_COMMAND, MENU_FILE_SAVE, Msg.lParam); // Ctrl + S キー
                        VK_T, VK_V: cfMain.SPCStop(false); // Ctrl + T, V キー
                        VK_X: cfMain.SPCPlay(PLAY_TYPE_PLAY); // Ctrl + X キー
                        VK_Z: cfMain.ListNextPlay(PLAY_ORDER_PREVIOUS, LIST_NEXT_PLAY_SELECT); // Ctrl + Z キー
                        VK_OEM_COMMA: cwWindowMain.PostMessage(WM_APP_COMMAND, MENU_SETUP_TIME_START, Msg.lParam); // Ctrl + , キー
                        VK_OEM_PERIOD: cwWindowMain.PostMessage(WM_APP_COMMAND, MENU_SETUP_TIME_LIMIT, Msg.lParam); // Ctrl + . キー
                        VK_OEM_2: cwWindowMain.PostMessage(WM_APP_COMMAND, MENU_SETUP_TIME_RESET, Msg.lParam); // Ctrl + / キー
                        VK_DELETE: cfMain.ListClear(true); // Ctrl + Del キー
                        VK_UP: cfMain.ListUp(); // Ctrl + ↑ キー
                        VK_DOWN: cfMain.ListDown(); // Ctrl + ↓ キー
                        VK_LEFT: if Status.bShiftButton or (Option.dwShiftKey = SHIFT_KEY_SEEK) then cfMain.SetFunction(-1, FUNCTION_TYPE_SEEK)
                            else cfMain.SetFunction(-1, FUNCTION_TYPE_SPEED); // Ctrl + ← キー
                        VK_RIGHT: if Status.bShiftButton or (Option.dwShiftKey = SHIFT_KEY_SEEK) then cfMain.SetFunction(1, FUNCTION_TYPE_SEEK)
                            else cfMain.SetFunction(1, FUNCTION_TYPE_SPEED); // Ctrl + → キー
                        VK_RETURN: cfMain.SPCPlay(PLAY_TYPE_RANDOM); // Ctrl + Enter キー
{$IFDEF CONTEXT}
                        VK_OEM_PLUS: begin // Ctrl + ; キー
                            // クリティカルセクションを開始
                            API_EnterCriticalSection(@CriticalSectionStatic);
                            // SNESAPU コンテキストを解放
                            if longbool(Status.lpContext) then FreeMem(Status.lpContext, Status.dwContextSize);
                            // SNESAPU コンテキストを取得
                            Status.dwContextSize := Apu.GetSNESAPUContextSize();
                            cwWindowMain.SetCaption(pchar(IntToStr(Status.dwContextSize)));
                            GetMem(Status.lpContext, Status.dwContextSize);
                            cwWindowMain.SetCaption(pchar(IntToStr(longword(Status.lpContext))));
                            Apu.GetSNESAPUContext(Status.lpContext);
                            // クリティカルセクションを終了
                            API_LeaveCriticalSection(@CriticalSectionStatic);
                        end;
                        VK_OEM_1: begin // Ctrl + : キー
                            // クリティカルセクションを開始
                            API_EnterCriticalSection(@CriticalSectionStatic);
                            // SNESAPU コンテキストを設定
                            if longbool(Status.lpContext) then Apu.SetSNESAPUContext(Status.lpContext);
                            // クリティカルセクションを終了
                            API_LeaveCriticalSection(@CriticalSectionStatic);
                        end;
{$ENDIF}
                        else Msg.wParam := Msg.wParam or $100;
                    end;
                    // キーマップを書き換え
                    if not Status.bCtrlButton and Status.bShiftButton then case dwKeyCode of
                        VK_UP: dwKeyCode := VK_NUMPAD8; // ↑ キー
                        VK_DOWN: dwKeyCode := VK_NUMPAD2; // ↓ キー
                    end;
                    // キーが処理されていない場合
                    if not Status.bCtrlButton or longbool(Msg.wParam and $100) then case dwKeyCode of
                        VK_ESCAPE: cwWindowMain.PostMessage(WM_APP_MESSAGE, WM_APP_MINIMIZE, NULL); // ESC キー
                        VK_TAB: cfMain.SetTabFocus(Msg.hWnd, not Status.bShiftButton); // Tab キー
                        VK_SHIFT: cfMain.SetChangeFunction(true); // Shift キー
                        VK_CONTROL: Status.bCtrlButton := true; // Ctrl キー
                        VK_F1..VK_F9: begin // F1 ～ F9 キー
                            // チャンネルマスクを設定
                            if dwKeyCode = VK_F9 then begin
                                if Status.bCtrlButton then Option.dwMute := $0
                                else Option.dwMute := Option.dwMute xor $FF;
                            end else begin
                                if Status.bCtrlButton then Option.dwMute := (1 shl (dwKeyCode - VK_F1)) xor $FF
                                else Option.dwMute := Option.dwMute xor (1 shl (dwKeyCode - VK_F1));
                            end;
                            // 設定をリセット
                            cfMain.SPCReset(false);
                        end;
                        VK_F12, VK_PAUSE: begin // F12, Break/Pause キー
                            // フラグを設定
                            Status.bBreakButton := not Status.bBreakButton;
                            // 情報を更新
                            cfMain.UpdateInfo(false);
                            // インジケータを再描画
                            cwWindowMain.PostMessage(WM_APP_MESSAGE, WM_APP_REDRAW, NULL);
                        end;
                        VK_INSERT: cfMain.ListAdd(0); // Insert キー
                        VK_DELETE: cfMain.ListDelete(); // Delete キー
                        VK_LEFT: if Status.bShiftButton then if Option.dwShiftKey = SHIFT_KEY_SEEK then cfMain.SetFunction(-1, FUNCTION_TYPE_SPEED)
                            else cfMain.SetFunction(-1, FUNCTION_TYPE_SEEK) else cfMain.SetChangeInfo(false, -1); // ← キー
                        VK_RIGHT: if Status.bShiftButton then if Option.dwShiftKey = SHIFT_KEY_SEEK then cfMain.SetFunction(1, FUNCTION_TYPE_SPEED)
                            else cfMain.SetFunction(1, FUNCTION_TYPE_SEEK) else cfMain.SetChangeInfo(false, 1); // → キー
                        VK_RETURN: if Status.bShiftButton then cfMain.SPCPlay(PLAY_TYPE_RANDOM)
                            else cfMain.SPCPlay(PLAY_TYPE_LIST); // Enter キー
                        VK_NUMPAD1, VK_NUMPAD3: cfMain.SetFunction(dwKeyCode - VK_NUMPAD2, FUNCTION_TYPE_SPEED); // テンキー 1, 3
                        VK_NUMPAD2: cfMain.ListNextPlay(PLAY_ORDER_NEXT, LIST_NEXT_PLAY_SELECT); // テンキー 2
                        VK_NUMPAD4, VK_NUMPAD6: cfMain.SetFunction(dwKeyCode - VK_NUMPAD5, FUNCTION_TYPE_SEEK); // テンキー 4, 6
                        VK_NUMPAD5: cfMain.SPCPlay(PLAY_TYPE_AUTO); // テンキー 5
                        VK_NUMPAD7, VK_NUMPAD9: cfMain.SetFunction(dwKeyCode - VK_NUMPAD8, FUNCTION_TYPE_SEPARATE); // テンキー 7, 9
                        VK_NUMPAD8: cfMain.ListNextPlay(PLAY_ORDER_PREVIOUS, LIST_NEXT_PLAY_SELECT); // テンキー 8
                        VK_NUMPAD0: cfMain.SPCStop(false); // テンキー 0
                        VK_ADD, VK_SUBTRACT: cfMain.SetFunction($6C - dwKeyCode, FUNCTION_TYPE_AMP); // テンキー +, -
                        VK_DIVIDE, VK_MULTIPLY: cfMain.SetFunction(1 - ((dwKeyCode and $1) shl 1), FUNCTION_TYPE_FEEDBACK); // テンキー /, *
                        VK_DECIMAL: cfMain.SPCStop(true); // テンキー .
                        VK_SPACE: bTransmitMsg := true; // Space キー
                        else if not Status.bCtrlButton then begin // その他のキー (プレイリスト上で操作したときと同じ処理を行う)
                            Msg.hWnd := cfMain.cwPlayList.hWnd;
                            bTransmitMsg := true;
                        end;
                    end;
                    // wParam を復元
                    Msg.wParam := dwKeyCode;
                end;
                WM_KEYUP: begin // 任意のキー
                    // タイマーを解除
                    if Status.bOptionLock then API_KillTimer(cwWindowMain.hWnd, TIMER_ID_OPTION_LOCK);
                    // オプション設定ロックを解除
                    Status.bOptionLock := false;
                    // キーを判別
                    dwKeyCode := Msg.wParam and $FF;
                    case dwKeyCode of
                        VK_SHIFT: cfMain.SetChangeFunction(true); // Shift キー
                        VK_CONTROL: Status.bCtrlButton := false; // Ctrl キー
                    end;
                end;
                WM_LBUTTONDOWN, WM_LBUTTONDBLCLK: begin // 左ボタン
                    if Msg.hWnd = cfMain.cwStaticMain.hWnd then begin
                        Status.DblClickPoint.x := Msg.lParam and $FFFF;
                        Status.DblClickPoint.y := Msg.lParam shr 16;
                        if not Status.bCtrlButton and Status.bShiftButton then cwWindowMain.PostMessage(WM_APP_MESSAGE, WM_APP_START_TIME, Msg.lParam)
                        else cwWindowMain.PostMessage(WM_APP_MESSAGE, WM_APP_SEEK, Msg.lParam);
                    end else if Msg.hWnd = cfMain.cwPlayList.hWnd then begin
                        cfMain.DragFile(Msg.msg, Msg.wParam, Msg.lParam);
                    end else if (Msg.msg = WM_LBUTTONDBLCLK) and longbool(API_GetWindowLong(Msg.hWnd, GWL_STYLE) and BS_OWNERDRAW) then begin
                        // NOTE: BS_OWNERDRAW の場合、BS_NOTIFY が自動的にセットされ、ボタンのダブルクリックが
                        // 機能してしまうため、WM_LBUTTONDBLCLK を WM_LBUTTONDOWN に強制的に変更する
                        Msg.msg := WM_LBUTTONDOWN;
                    end;
                end;
                WM_RBUTTONDOWN, WM_RBUTTONDBLCLK: begin // 右ボタン
                    if Msg.hWnd = cfMain.cwStaticMain.hWnd then begin
                        Status.DblClickPoint.x := Msg.lParam and $FFFF;
                        Status.DblClickPoint.y := Msg.lParam shr 16;
                        if not Status.bCtrlButton and Status.bShiftButton then cwWindowMain.PostMessage(WM_APP_MESSAGE, WM_APP_LIMIT_TIME, Msg.lParam)
                        else cwWindowMain.PostMessage(WM_APP_MESSAGE, WM_APP_SEEK, Msg.lParam);
                    end else if Msg.hWnd = cfMain.cwPlayList.hWnd then begin
                        cfMain.DragFile(Msg.msg, Msg.wParam, Msg.lParam);
                    end;
                    cfMain.SetChangeFunction(true);
                end;
                WM_MBUTTONDOWN, WM_MBUTTONDBLCLK: begin // 中央ボタン
                    if Msg.hWnd = cfMain.cwStaticMain.hWnd then begin
                        Status.DblClickPoint.x := Msg.lParam and $FFFF;
                        Status.DblClickPoint.y := Msg.lParam shr 16;
                        cwWindowMain.PostMessage(WM_APP_MESSAGE, WM_APP_RESET_TIME, Msg.lParam);
                    end;
                end;
                WM_RBUTTONUP: cfMain.SetChangeFunction(true); // 右ボタン
                WM_XBUTTONDOWN, WM_XBUTTONDBLCLK: if Status.bShiftButton xor longbool(Msg.wParam and $40) then cfMain.SetChangeInfo(false, -1)
                    else cfMain.SetChangeInfo(false, 1); // 拡張ボタン
                WM_MOUSEMOVE: if Msg.hWnd = cfMain.cwPlayList.hWnd then begin // マウス移動
                    cfMain.DragFile(Msg.msg, Msg.wParam, Msg.lParam);
                    Msg.msg := WM_LBUTTONUP; // 移動をキャンセル
                end;
                WM_MOUSEWHEEL: // ホイール：Ctrl キーが押されている場合は移動、 Ctrl キーが押されていない場合はスクロール
                    if Status.bCtrlButton then
                        if longbool(Msg.wParam and $80000000) then cfMain.ListDown()
                        else cfMain.ListUp()
                    else Msg.hWnd := cfMain.cwPlayList.hWnd;
            end;
            // メッセージを転送する場合
            if bTransmitMsg then begin
                // 仮想キーメッセージを文字メッセージに変換
                API_TranslateMessage(@Msg);
                // メッセージをウィンドウに送信
                API_DispatchMessage(@Msg);
            end;
        end;
        // ウィンドウを削除
        cfMain.DeleteWindow();
    end;
    // メインクラスを解放
    cfMain.Free();
    // ウィンドウクラスを削除
    Status.ccClass.DeleteClass(hThisInstance, pchar(CLASS_NAME));
    Status.ccClass.Free();
    // クリティカルセクションを削除
    API_DeleteCriticalSection(@CriticalSectionThread);
    API_DeleteCriticalSection(@CriticalSectionStatic);
    // wParam を返却
    result := Msg.wParam;
end;

// ================================================================================
// StaticProc - ラベルプロシージャ
// ================================================================================
function _StaticProc(hWnd: longword; msg: longword; wParam: longword; lParam: longword): longword; stdcall;
begin
    // システムが再描画を開始する場合
    if msg = WM_PAINT then begin
        // クリティカルセクションを開始
        API_EnterCriticalSection(@CriticalSectionStatic);
        // 再描画をロック (WM_PAINT 中に独自で描画するとデバイスコンテキストが破壊される)
        Status.dwRedrawInfo := Status.dwRedrawInfo or REDRAW_LOCK_CRITICAL or REDRAW_LOCK_READY;
        // デフォルトのウィンドウプロシージャを呼び出す
        result := API_CallWindowProc(Status.lpStaticProc, hWnd, msg, wParam, lParam);
        // インジケータの再描画を予約
        Status.cfMain.cwWindowMain.PostMessage(WM_APP_MESSAGE, WM_APP_REDRAW, NULL);
        // 再描画のロックを一部解除
        Status.dwRedrawInfo := Status.dwRedrawInfo xor REDRAW_LOCK_CRITICAL;
        // クリティカルセクションを終了
        API_LeaveCriticalSection(@CriticalSectionStatic);
    end else begin
        // デフォルトのウィンドウプロシージャを呼び出す
        result := API_CallWindowProc(Status.lpStaticProc, hWnd, msg, wParam, lParam);
    end;
end;

// ================================================================================
// WaveThread - スレッドプロシージャ
// ================================================================================
function _WaveThread(lpData: longword): longint; stdcall;
var
    cfMain: CWINDOWMAIN;
    cwWindowMain: CWINDOW;
    Msg: TMSG;
begin
    // ウィンドウハンドルを取得
    cfMain := Status.cfMain;
    cwWindowMain := cfMain.cwWindowMain;
    // メッセージキューを作成
    API_PeekMessage(@Msg, NULL, WM_USER, WM_USER, NULL);
    // 準備完了
    Status.dwThreadStatus := WAVE_THREAD_RUNNING;
    // メッセージを受け取るまで待機する。 WM_QUIT の場合はループを抜ける
    while API_GetMessage(@Msg, NULL, NULL, NULL) do case Msg.msg of
        MM_WOM_DONE: begin // デバイスの再生が終了した
            // クリティカルセクションを開始
            API_EnterCriticalSection(@CriticalSectionThread);
            // デバイスプロシージャを呼び出す
            if Status.bPlay then begin
                // 次の音声データを作成してデバイスに転送
                cfMain.WaveProc(WAVE_PROC_WRITE_WAVE);
                // リフレッシュ用の空メッセージを送信 (for wine)
                if longbool(Status.dwWaveMessage) then begin
                    cwWindowMain.PostMessage(WM_APP_MESSAGE, WM_APP_WAVE_PROC, NULL);
                    Dec(Status.dwWaveMessage);
                end;
                // スリープ抑制メッセージを送信
                if longbool(Option.dwNoSleep) then begin
                    Inc(Status.dwNoSleepTime, Option.dwBufferTime);
                    if Status.dwNoSleepTime >= NO_SLEEP_INTERVAL then API_SetThreadExecutionState(Option.dwNoSleep and $FFFF);
                    while Status.dwNoSleepTime >= NO_SLEEP_INTERVAL do Dec(Status.dwNoSleepTime, NO_SLEEP_INTERVAL);
                end;
            end else Dec(Status.dwThreadIdle);
            // クリティカルセクションを終了
            API_LeaveCriticalSection(@CriticalSectionThread);
        end;
        WM_APP_MESSAGE: case Msg.wParam of
            WM_APP_SPC_PLAY: begin // 演奏開始
                // クリティカルセクションを開始
                API_EnterCriticalSection(@CriticalSectionThread);
                // リピート開始位置が設定されている場合はシーク
                if Status.bWaveWrite and Status.bTimeRepeat and longbool(Status.dwStartTime) then cfMain.SPCSeek(Status.dwStartTime, true);
                // 演奏開始
                cfMain.WaveStart();
                // クリティカルセクションを終了
                API_LeaveCriticalSection(@CriticalSectionThread);
            end;
            WM_APP_SPC_PAUSE: if Status.bWaveWrite and cfMain.WavePause() then begin // 一時停止
                // メニューを更新
                cwWindowMain.PostMessage(WM_APP_MESSAGE, WM_APP_UPDATE_MENU, NULL);
                // インジケータをリセット
                cfMain.ResetInfo(true);
            end;
            WM_APP_SPC_RESUME: if Status.bWaveWrite and cfMain.WaveResume() then begin // 演奏再開
                // メニューを更新
                cwWindowMain.PostMessage(WM_APP_MESSAGE, WM_APP_UPDATE_MENU, NULL);
                // インジケータをリセット
                cfMain.ResetInfo(true);
            end;
            WM_APP_SPC_RESET: if Status.bWaveWrite then begin // 演奏設定
                // クリティカルセクションを開始
                API_EnterCriticalSection(@CriticalSectionThread);
                // SPC 演奏設定
                cfMain.SPCOption();
                // クリティカルセクションを終了
                API_LeaveCriticalSection(@CriticalSectionThread);
            end;
            WM_APP_SPC_TIME: if Status.bWaveWrite then begin // 時間設定
                // クリティカルセクションを開始
                API_EnterCriticalSection(@CriticalSectionThread);
                // SPC 演奏設定
                cfMain.SPCTime(false, false, true);
                // クリティカルセクションを終了
                API_LeaveCriticalSection(@CriticalSectionThread);
            end;
            WM_APP_SPC_SEEK, WM_APP_SPC_SEEK + 1: if Status.bWaveWrite then begin // シーク
                // クリティカルセクションを開始
                API_EnterCriticalSection(@CriticalSectionThread);
                // SPC シーク
                cfMain.SPCSeek(Msg.lParam, longbool(Msg.wParam and $1));
                // クリティカルセクションを終了
                API_LeaveCriticalSection(@CriticalSectionThread);
            end;
        end;
        MM_WOM_OPEN: Status.dwThreadStatus := Status.dwThreadStatus or WAVE_THREAD_DEVICE_OPENED; // デバイスがオープンされた
        MM_WOM_CLOSE: Status.dwThreadStatus := Status.dwThreadStatus or WAVE_THREAD_DEVICE_CLOSED; // デバイスがクローズされた
    end;
    // 処理終了
    Status.dwThreadStatus := WAVE_THREAD_SUSPEND;
    // wParam を返却
    result := Msg.wParam;
end;

// ================================================================================
// OLEIDropSourceAddRef - IDropSource インターフェイス参照
// ================================================================================
function _OLEIDropSourceAddRef(lpDropSource: pointer): longword; stdcall;
var
    IDropSource: ^TIDROPSOURCE;
begin
    // 参照カウントをインクリメント
    IDropSource := lpDropSource;
    result := API_InterlockedIncrement(@IDropSource.dwRefCnt);
end;

// ================================================================================
// OLEIDropSourceRelease - IDropSource インターフェイス解放
// ================================================================================
function _OLEIDropSourceRelease(lpDropSource: pointer): longword; stdcall;
var
    IDropSource: ^TIDROPSOURCE;
begin
    // 参照カウントをデクリメント
    IDropSource := lpDropSource;
    result := API_InterlockedDecrement(@IDropSource.dwRefCnt);
    // 参照カウントが 0 でない場合は終了
    if longbool(result) then exit;
    // メモリを解放
    API_GlobalFree(longword(IDropSource.lpVtbl));
    API_GlobalFree(longword(IDropSource));
end;

// ================================================================================
// OLEIDropSourceQueryInterface - IDropSource インターフェイス初期化
// ================================================================================
function _OLEIDropSourceQueryInterface(lpDropSource: pointer; priid: pointer; lplpDropSource: pointer): longword; stdcall;
var
    Guid: ^TGUID;
    DblPointer: ^TDBLPOINTER;
begin
    // 初期化
    Guid := priid;
    DblPointer := lplpDropSource;
    // 要求された GUID を確認
    if IsEqualsGUID(Guid^, IID_IDropSource) or IsEqualsGUID(Guid^, IID_IUnknown) then begin
        // IDropSource の GUID を要求された場合はクラスのポインタを設定
        DblPointer.p := lpDropSource;
        _OLEIDropSourceAddRef(lpDropSource);
        result := S_OK;
    end else begin
        // その他の GUID を要求された場合は存在しない情報を設定
        DblPointer.p := NULLPOINTER;
        result := E_NOINTERFACE;
    end;
end;

// ================================================================================
// OLEIDropSourceQueryContinueDrag - ドラッグ中の操作を取得
// ================================================================================
function _OLEIDropSourceQueryContinueDrag(lpDropSource: pointer; fEscapePressed: longbool; dwKeyState: longword): longword; stdcall;
var
    dwKey: longword;
begin
    // 初期化
    dwKey := dwKeyState and (MK_LBUTTON or MK_RBUTTON);
    if fEscapePressed or (dwKey = (MK_LBUTTON or MK_RBUTTON)) then begin
        // ドラッグ中に ESC キーが押された場合はドラッグをキャンセル
        result := DRAGDROP_S_CANCEL;
    end else if not longbool(dwKey) then begin
        // マウスのボタンが離れた場合はドロップ実行
        result := DRAGDROP_S_DROP;
    end else result := S_OK;
end;

// ================================================================================
// OLEIDropSourceGiveFeedback - ドラッグ中のマウスカーソル取得
// ================================================================================
function _OLEIDropSourceGiveFeedback(lpDropSource: pointer; dwEffect: longword): longword; stdcall;
begin
    // デフォルトのカーソルを設定
    result := DRAGDROP_S_USEDEFAULTCURSORS;
end;

// ================================================================================
// OLEIDataObjectAddRef - IDataObject インターフェイス参照
// ================================================================================
function _OLEIDataObjectAddRef(lpDataObject: pointer): longword; stdcall;
var
    IDataObject: ^TIDATAOBJECT;
begin
    // 参照カウントをインクリメント
    IDataObject := lpDataObject;
    result := API_InterlockedIncrement(@IDataObject.dwRefCnt);
end;

// ================================================================================
// OLEIDataObjectRelease - IDataObject インターフェイス解放
// ================================================================================
function _OLEIDataObjectRelease(lpDataObject: pointer): longword; stdcall;
var
    I: longint;
    IDataObject: ^TIDATAOBJECT;
    SelfObject: ^TDROPOBJECT;
begin
    // 参照カウントをデクリメント
    IDataObject := lpDataObject;
    result := API_InterlockedDecrement(@IDataObject.dwRefCnt);
    // 参照カウントが 0 でない場合は終了
    if longbool(result) then exit;
    // メモリを解放
    for I := 0 to IDataObject.dwObjectCnt - 1 do begin
        SelfObject := @IDataObject.Objects[I];
        if not SelfObject.fRelease then continue;
        if longbool(SelfObject.FormatEtc) then API_GlobalFree(longword(SelfObject.FormatEtc));
        if longbool(SelfObject.StgMedium) then begin
            // コピーされた追加のデータを解放
            API_ReleaseStgMedium(SelfObject.StgMedium);
            API_GlobalFree(longword(SelfObject.StgMedium));
        end;
        break;
    end;
    API_GlobalFree(longword(IDataObject.lpVtbl));
    API_GlobalFree(longword(IDataObject));
end;

// ================================================================================
// OLEIDataObjectQueryInterface - IDataObject インターフェイス初期化
// ================================================================================
function _OLEIDataObjectQueryInterface(lpDataObject: pointer; priid: pointer; lplpDataObject: pointer): longword; stdcall;
var
    Guid: ^TGUID;
    DblPointer: ^TDBLPOINTER;
begin
    // 初期化
    Guid := priid;
    DblPointer := lplpDataObject;
    // 要求された GUID を確認
    if IsEqualsGUID(Guid^, IID_IDataObject) or IsEqualsGUID(Guid^, IID_IUnknown) then begin
        // IDataObject の GUID を要求された場合はクラスのポインタを設定
        DblPointer.p := lpDataObject;
        _OLEIDataObjectAddRef(lpDataObject);
        result := S_OK;
    end else begin
        // その他の GUID を要求された場合は存在しない情報を設定
        DblPointer.p := NULLPOINTER;
        result := E_NOINTERFACE;
    end;
end;

// ================================================================================
// _OLEIDataObjectCopyData - ドラッグ対象データコピー
// ================================================================================
function _OLEIDataObjectCopyData(lpDataObject: pointer; lpDestMedium: pointer; lpFormatEtc: pointer; lpSrcMedium: pointer): longword;
var
    handle: longword;
    FormatEtc: ^TFORMATETC;
    SrcStgMedium: ^TSTGMEDIUM;
    DestStgMedium: ^TSTGMEDIUM;
    IDataObjectUnk: ^TIDATAOBJECTVTBL;
    AddRef: function(lpDataObject: pointer): longword;
begin
    // 初期化
    FormatEtc := lpFormatEtc;
    DestStgMedium := lpDestMedium;
    SrcStgMedium := lpSrcMedium;
    // フォーマットタイプが NULL の場合は終了
    if not longbool(SrcStgMedium.tymed) then begin
        result := E_INVALIDARG;
        exit;
    end;
    // データのインスタンスをコピー
    handle := API_OleDuplicateData(SrcStgMedium.handle, FormatEtc.cfFormat, GMEM_FIXED);
    // インスタンスのコピーに失敗した場合は終了
    if not longbool(handle) then begin
        result := E_OUTOFMEMORY;
        exit;
    end;
    // インスタンスのハンドルを設定
    DestStgMedium.handle := handle;
    // フォーマットデータをコピー
    DestStgMedium.tymed := SrcStgMedium.tymed;
    DestStgMedium.pUnkForRelease := SrcStgMedium.pUnkForRelease;
    if longbool(DestStgMedium.pUnkForRelease) then begin
        IDataObjectUnk := DestStgMedium.pUnkForRelease;
        AddRef := IDataObjectUnk.OLEIDataObjectAddRef;
        AddRef(IDataObjectUnk);
    end;
    // 終了
    result := S_OK;
end;

// ================================================================================
// OLEIDataObjectGetData - ドラッグ対象データ取得 (データ取得元側メモリ確保)
// ================================================================================
function _OLEIDataObjectGetData(lpDataObject: pointer; lpFormatEtc: pointer; lpStgMedium: pointer): longword; stdcall;
var
    I: longint;
    IDataObject: ^TIDATAOBJECT;
    FormatEtc: ^TFORMATETC;
    SelfObject: ^TDROPOBJECT;
begin
    // フォーマット定義が NULL の場合は終了
    if not longbool(lpFormatEtc) or not longbool(lpStgMedium) then begin
        result := E_INVALIDARG;
        exit;
    end;
    // 要求されたフォーマットが埋め込みオブジェクトでない場合は終了
    FormatEtc := lpFormatEtc;
    if not longbool(FormatEtc.dwAspect and DVASPECT_CONTENT) then begin
        result := DV_E_DVASPECT;
        exit;
    end;
    // 要求されたフォーマットが想定しているフォーマットを検索
    IDataObject := lpDataObject;
    SelfObject := NULLPOINTER;
    result := DV_E_FORMATETC;
    for I := 0 to IDataObject.dwObjectCnt - 1 do begin
        SelfObject := @IDataObject.Objects[I];
        if (FormatEtc.cfFormat = SelfObject.FormatEtc.cfFormat)
        and (FormatEtc.lindex = SelfObject.FormatEtc.lindex)
        and longbool(FormatEtc.dwAspect and SelfObject.FormatEtc.dwAspect)
        and longbool(FormatEtc.tymed and SelfObject.FormatEtc.tymed) then begin
            // 想定したフォーマット
            result := S_OK;
            break;
        end;
    end;
    // フォーマットが見つからなかった場合は終了
    if result <> S_OK then exit;
    // 要求されたデータのインスタンスをコピー
    result := _OLEIDataObjectCopyData(lpDataObject, lpStgMedium, SelfObject.FormatEtc, SelfObject.StgMedium);
end;

// ================================================================================
// OLEIDataObjectGetDataHere - ドラッグ対象データ取得 (データ提供元側メモリ確保)
// ================================================================================
function _OLEIDataObjectGetDataHere(lpDataObject: pointer; lpFormatEtc: pointer; lpStgMedium: pointer): longword; stdcall;
begin
    // 未実装
    result := E_NOTIMPL;
end;

// ================================================================================
// OLEIDataObjectQueryGetData - ドラッグ対象データフォーマットチェック
// ================================================================================
function _OLEIDataObjectQueryGetData(lpDataObject: pointer; lpFormatEtc: pointer): longword; stdcall;
var
    I: longint;
    IDataObject: ^TIDATAOBJECT;
    FormatEtc: ^TFORMATETC;
    SelfObject: ^TDROPOBJECT;
begin
    // フォーマット定義が NULL の場合は終了
    if not longbool(lpFormatEtc) then begin
        result := E_INVALIDARG;
        exit;
    end;
    // 要求されたフォーマットが埋め込みオブジェクトでない場合は終了
    FormatEtc := lpFormatEtc;
    if not longbool(FormatEtc.dwAspect and DVASPECT_CONTENT) then begin
        result := DV_E_DVASPECT;
        exit;
    end;
    // 要求されたフォーマットが想定しているフォーマットを検索
    IDataObject := lpDataObject;
    result := DV_E_FORMATETC;
    for I := 0 to IDataObject.dwObjectCnt - 1 do begin
        SelfObject := @IDataObject.Objects[I];
        if (FormatEtc.cfFormat = SelfObject.FormatEtc.cfFormat)
        and (FormatEtc.lindex = SelfObject.FormatEtc.lindex)
        and longbool(FormatEtc.dwAspect and SelfObject.FormatEtc.dwAspect)
        and longbool(FormatEtc.tymed and SelfObject.FormatEtc.tymed) then begin
            // 想定したフォーマット
            result := S_OK;
            break;
        end;
    end;
end;

// ================================================================================
// OLEIDataObjectGetCanonicalFormatEtc - 提供元と互換性のあるフォーマットの取得
// ================================================================================
function _OLEIDataObjectGetCanonicalFormatEtc(lpDataObject: pointer; lpFormatEtcIn: pointer; lpFormatEtcOut: pointer): longword; stdcall;
begin
    // 未実装
    result := E_NOTIMPL;
end;

// ================================================================================
// OLEIDataObjectSetData - ドラッグ対象データ設定
// ================================================================================
function _OLEIDataObjectSetData(lpDataObject: pointer; lpFormatEtc: pointer; lpStgMedium: pointer; fRelease: longbool): longword; stdcall;
var
    IDataObject: ^TIDATAOBJECT;
    SelfObject: ^TDROPOBJECT;
begin
    // フォーマット定義が NULL の場合は終了
    if not longbool(lpFormatEtc) or not longbool(lpStgMedium) then begin
        result := E_INVALIDARG;
        exit;
    end;
    // バッファサイズを確認
    IDataObject := lpDataObject;
    if IDataObject.dwObjectCnt >= longword(Length(IDataObject.Objects)) then begin
        result := E_OUTOFMEMORY;
        exit;
    end;
    // フォーマット定義を設定
    SelfObject := @IDataObject.Objects[IDataObject.dwObjectCnt];
    API_InterlockedIncrement(@IDataObject.dwObjectCnt);
    SelfObject.FormatEtc := lpFormatEtc;
    SelfObject.fRelease := fRelease;
    if fRelease then begin
        // データをコピーしない
        SelfObject.StgMedium := lpStgMedium;
        result := S_OK;
    end else begin
        // 要求されたデータのインスタンスをコピー
        result := _OLEIDataObjectCopyData(lpDataObject, SelfObject.StgMedium, lpFormatEtc, lpStgMedium);
    end;
end;

// ================================================================================
// OLEIDataObjectEnumFormatEtc - 提供元がサポートするフォーマットの列挙
// ================================================================================
function _OLEIDataObjectEnumFormatEtc(lpDataObject: pointer; dwDirection: longword; lplpEnumFormatEtc: pointer): longword; stdcall;
begin
    // 未実装
    result := E_NOTIMPL;
end;

// ================================================================================
// OLEIDataObjectDAdvise - 取得元と提供元の相互通知設定
// ================================================================================
function _OLEIDataObjectDAdvise(lpDataObject: pointer; lpFormatEtc: pointer; dwAdvf: longword; lpAdvSink: pointer; pdwConnection: pointer): longword; stdcall;
begin
    // 未サポート
    result := OLE_E_ADVISENOTSUPPORTED;
end;

// ================================================================================
// OLEIDataObjectDUnadvise - 取得元と提供元の相互通知解除
// ================================================================================
function _OLEIDataObjectDUnadvise(lpDataObject: pointer; dwConnection: longword): longword; stdcall;
begin
    // 未サポート
    result := OLE_E_ADVISENOTSUPPORTED;
end;

// ================================================================================
// OLEIDataObjectEnumDAdvise - 取得元と提供元の相互通知列挙
// ================================================================================
function _OLEIDataObjectEnumDAdvise(lpDataObject: pointer; lplpEnumAdvise: pointer): longword; stdcall;
begin
    // 未サポート
    result := OLE_E_ADVISENOTSUPPORTED;
end;

{$IFDEF SPCDEBUG}
procedure _SPCDebug(pc: longword; ya: word; x: byte; psw: byte; sp: longword; cnt: longword); cdecl;
begin

end;

procedure _DSPDebug(reg: pointer; val: byte); cdecl;
begin

end;
{$ENDIF}


// *************************************************************************************************************************************************************
// CLASS クラス
// *************************************************************************************************************************************************************

// ================================================================================
// CreateClass - クラス作成
// ================================================================================
procedure CCLASS.CreateClass(lpWindowProc: pointer; hThisInstance: longword; lpClassName: pointer; dwStyle: longword; lpIcon: pointer; lpSmallIcon: pointer;
    hCursor: longword; hbrBackground: longword);
var
    WndClassEx: TWNDCLASSEX;
begin
    API_ZeroMemory(@WndClassEx, SizeOf(TWNDCLASSEX));
    WndClassEx.cdSize := SizeOf(TWNDCLASSEX);
    WndClassEx.style := dwStyle;
    WndClassEx.lpfnWndProc := lpWindowProc;
    WndClassEx.hThisInstance := hThisInstance;
    WndClassEx.lpszMenuName := pchar(longword(word(1)));
    WndClassEx.lpszClassName := lpClassName;
    if longbool(lpIcon) then WndClassEx.hIcon := API_LoadIcon(hThisInstance, lpIcon);
    if longbool(hCursor) then WndClassEx.hCursor := API_LoadCursor(NULL, pointer(hCursor));
    if longbool(hbrBackground) then WndClassEx.hbrBackground := hbrBackground;
    if longbool(lpSmallIcon) then WndClassEx.hIconSm := API_LoadIcon(hThisInstance, lpSmallIcon);
    API_RegisterClassEx(@WndClassEx);
end;

// ================================================================================
// DeleteClass - クラス削除
// ================================================================================
procedure CCLASS.DeleteClass(hThisInstance: longword; lpClassName: pointer);
begin
    API_UnregisterClass(lpClassName, hThisInstance);
end;


// *************************************************************************************************************************************************************
// FONT クラス
// *************************************************************************************************************************************************************

// ================================================================================
// CreateFont - フォント作成
// ================================================================================
procedure CFONT.CreateFont(lpFontName: pointer; nHeight: longint; nWidth: longint; bBold: longbool; bItalic: longbool; bUnderLine: longbool; bStrike: longbool);
var
    Data: record
        nWeight: smallint;
        dwItalic: longword;
        dwUnderLine: longword;
        dwStrikeOut: longword;
    end;
begin
    API_ZeroMemory(@Data, SizeOf(Data));
    if bBold then Data.nWeight := 700;
    if bItalic then Data.dwItalic := 1;
    if bUnderLine then Data.dwUnderLine := 1;
    if bStrike then Data.dwStrikeOut := 1;
    hFont := API_CreateFont(nHeight, nWidth, NULL, NULL, Data.nWeight, Data.dwItalic, Data.dwUnderLine, Data.dwStrikeOut, 1, NULL, NULL, 2, 49, lpFontName);
end;

// ================================================================================
// DeleteFont - フォント削除
// ================================================================================
procedure CFONT.DeleteFont();
begin
    API_DeleteObject(hFont);
end;


// *************************************************************************************************************************************************************
// MENU クラス
// *************************************************************************************************************************************************************

// ================================================================================
// AppendMenu - メニュー項目追加
// ================================================================================
procedure CMENU.AppendMenu(dwID: longword; lpString: pointer);
begin
    API_AppendMenu(hMenu, MF_STRING, dwID, lpString);
end;

// ================================================================================
// AppendMenu - メニュー項目追加
// ================================================================================
procedure CMENU.AppendMenu(dwID: longword; lpString: pointer; bRadio: longbool);
begin
    if bRadio then API_AppendMenu(hMenu, MF_STRING or MF_RADIOCHECK, dwID, lpString)
    else AppendMenu(dwID, lpString);
end;

// ================================================================================
// AppendMenu - メニュー項目追加
// ================================================================================
procedure CMENU.AppendMenu(dwID: longword; lpString: pointer; hSubMenuID: longword);
begin
    API_AppendMenu(hMenu, MF_STRING or MF_POPUP, hSubMenuID, lpString);
end;

// ================================================================================
// AppendSeparator - メニューセパレータ追加
// ================================================================================
procedure CMENU.AppendSeparator();
begin
    API_AppendMenu(hMenu, MF_SEPARATOR, NULL, NULLPOINTER);
end;

// ================================================================================
// CreateMenu - メニュー作成
// ================================================================================
procedure CMENU.CreateMenu();
begin
    hMenu := API_CreateMenu();
end;

// ================================================================================
// CreatePopupMenu - サブメニュー作成
// ================================================================================
procedure CMENU.CreatePopupMenu();
begin
    hMenu := API_CreatePopupMenu();
end;

// ================================================================================
// DeleteMenu - メニュー削除
// ================================================================================
procedure CMENU.DeleteMenu();
begin
    API_DestroyMenu(hMenu);
end;

// ================================================================================
// InsertMenu - メニュー項目追加
// ================================================================================
procedure CMENU.InsertMenu(dwID: longword; dwAfterId: longword; lpString: pointer);
begin
    API_InsertMenu(hMenu, dwAfterId, MF_BYCOMMAND or MF_STRING, dwID, lpString);
end;

// ================================================================================
// InsertMenu - メニュー項目追加
// ================================================================================
procedure CMENU.InsertMenu(dwID: longword; dwAfterId: longword; lpString: pointer; bRadio: longbool);
begin
    if bRadio then API_InsertMenu(hMenu, dwAfterId, MF_BYCOMMAND or MF_STRING or MF_RADIOCHECK, dwID, lpString)
    else InsertMenu(dwID, dwAfterId, lpString);
end;

// ================================================================================
// InsertMenu - メニュー項目追加
// ================================================================================
procedure CMENU.InsertMenu(dwID: longword; dwAfterId: longword; lpString: pointer; hSubMenuID: longword);
begin
    API_InsertMenu(hMenu, dwAfterId, MF_BYCOMMAND or MF_STRING or MF_POPUP, hSubMenuID, lpString);
end;

// ================================================================================
// InsertSeparator - メニューセパレータ追加
// ================================================================================
procedure CMENU.InsertSeparator(dwId: longword);
begin
    API_InsertMenu(hMenu, dwId, MF_BYCOMMAND or MF_SEPARATOR, NULL, NULLPOINTER);
end;

// ================================================================================
// RemoveMenu - メニュー項目削除
// ================================================================================
procedure CMENU.RemoveItem(dwId: longword);
begin
    API_DeleteMenu(hMenu, dwId, MF_BYCOMMAND);
end;

// ================================================================================
// SetMenuCheck - メニューチェック設定
// ================================================================================
procedure CMENU.SetMenuCheck(dwID: longword; bCheck: longbool);
var
    dwFlags: longword;
begin
    dwFlags := API_GetMenuState(hMenu, dwId, MF_BYCOMMAND);
    if bCheck = longbool(dwFlags and MF_CHECKED) then exit;
    if bCheck then dwFlags := API_CheckMenuItem(hMenu, dwID, MF_CHECKED)
    else dwFlags := API_CheckMenuItem(hMenu, dwID, MF_UNCHECKED);
    if bCheck <> longbool(dwFlags and MF_CHECKED) then API_EnableMenuItem(hMenu, dwID, longword(API_EnableMenuItem(hMenu, dwID, MF_GRAYED)));
end;

// ================================================================================
// SetMenuEnable - メニュー有効設定
// ================================================================================
procedure CMENU.SetMenuEnable(dwID: longword; bEnable: longbool);
var
    dwFlags: longword;
begin
    dwFlags := API_GetMenuState(hMenu, dwId, MF_BYCOMMAND);
    if bEnable <> longbool(dwFlags and MF_GRAYED) then exit;
    if bEnable then API_EnableMenuItem(hMenu, dwID, MF_ENABLED)
    else API_EnableMenuItem(hMenu, dwID, MF_GRAYED);
end;


// *************************************************************************************************************************************************************
// MENUBAR クラス
// *************************************************************************************************************************************************************

// ================================================================================
// DrawMenuBar - メニューバー描画
// ================================================================================
function CMENUBAR.DrawMenuBar(hWnd: longword; lParam: longword): longword;
var
    UahMenu: ^TUAHMENU;
    MenuBarInfo: TMENUBARINFO;
    MenuRect: TRECT;
    WindowRect: TRECT;
begin
    // 初期化
    UahMenu := pointer(lParam);
    // メニューバーのサイズを取得
    MenuBarInfo.cbSize := SizeOf(TMENUBARINFO);
    API_GetMenuBarInfo(hWnd, OBJID_MENU, NULL, @MenuBarInfo);
    API_MoveMemory(@MenuRect, @MenuBarInfo.rcBar, SizeOf(TRECT));
    // ウィンドウの開始位置分、位置を変更
    API_GetWindowRect(hWnd, @WindowRect);
    Dec(MenuRect.left, WindowRect.left);
    Dec(MenuRect.right, WindowRect.left);
    Dec(MenuRect.top, WindowRect.top);
    Dec(MenuRect.bottom, WindowRect.top);
    // 描画
    API_FillRect(UahMenu.hDC, @MenuRect, Status.hMenuBrush);
    // メニュー境界を描画
    DrawMenuBorder(hWnd);
    // 成功
    result := 1;
end;

// ================================================================================
// DrawMenuBorder - メニュー境界描画
// ================================================================================
procedure CMENUBAR.DrawMenuBorder(hWnd: longword);
var
    MenuBarInfo: TMENUBARINFO;
    MenuRect: TRECT;
    WindowRect: TRECT;
begin
    // メニューバーのサイズを取得
    MenuBarInfo.cbSize := SizeOf(TMENUBARINFO);
    API_GetMenuBarInfo(hWnd, OBJID_MENU, NULL, @MenuBarInfo);
    API_MoveMemory(@MenuRect, @MenuBarInfo.rcBar, SizeOf(TRECT));
    // ウィンドウの開始位置分、位置を変更
    API_GetWindowRect(hWnd, @WindowRect);
    Dec(MenuRect.left, WindowRect.left);
    Dec(MenuRect.right, WindowRect.left);
    Dec(MenuRect.bottom, WindowRect.top);
    MenuRect.top := MenuRect.bottom;
    Inc(MenuRect.bottom);
    // 描画
    API_FillRect(Status.hDCWindow, @MenuRect, Status.hMenuBrush);
end;

// ================================================================================
// DrawMenuItem - メニューアイテム描画
// ================================================================================
function CMENUBAR.DrawMenuItem(hWnd: longword; lParam: longword): longword;
var
    UahMenuItem: ^TUAHDRAWMENUITEM;
    hDLL: longword;
    lpText: pointer;
    dwFlags: longword;
    wsData: widestring;
    hTheme: longword;
    MenuItemInfo: TMENUITEMINFO;
    Opts: TDTTOPTS;
    API_DrawThemeTextEx: function(hTheme: longword; hDC: longword; iPartId: longint; iStateId: longint; pszText: pointer; cchText: longint; dwTextFlags: longword; pRect: pointer; pOptions: pointer): longword; stdcall;
    API_OpenThemeData: function(hWnd: longword; pszClassList: pointer): longword; stdcall;
begin
    // 初期化
    result := 0;
    // Windows Vista 未満の場合は終了
    if (Status.OsVersionInfo.dwMajorVersion < 6) then exit;
    // UXTHEME.DLL のロードに失敗した場合は終了
    hDLL := API_LoadLibraryEx(pchar('uxtheme.dll'), NULL, LOAD_LIBRARY_SEARCH_SYSTEM32);
    if not longbool(hDLL) then exit;
    // メニューバーを描画
    @API_DrawThemeTextEx := API_GetProcAddress(hDLL, pchar('DrawThemeTextEx'));
    @API_OpenThemeData := API_GetProcAddress(hDLL, pchar('OpenThemeData'));
    if longbool(@API_DrawThemeTextEx) and longbool(@API_OpenThemeData) then begin
        // 初期化
        UahMenuItem := pointer(lParam);
        // バッファを確保
        GetMem(lpText, 256);
        // メニューのテキストを取得
        API_ZeroMemory(@MenuItemInfo, SizeOf(TMENUITEMINFO));
        MenuItemInfo.cbSize := SizeOf(TMENUITEMINFO);
        MenuItemInfo.fMask := MIIM_STRING;
        MenuItemInfo.dwTypeData := lpText;
        MenuItemInfo.cch := 128; // マルチバイト考慮
        API_GetMenuItemInfo(UahMenuItem.Menu.hMenu, UahMenuItem.MenuItem.nPosition, true, @MenuItemInfo);
        // 文字色設定を準備
        dwFlags := DT_SINGLELINE or DT_CENTER or DT_VCENTER;
        API_ZeroMemory(@Opts, SizeOf(TDTTOPTS));
        Opts.cbSize := SizeOf(TDTTOPTS);
        Opts.dwFlags := 1; // DTT_TEXTCOLOR
        // 文字色・背景色を設定
        if longbool(UahMenuItem.Struct.itemState and (ODS_DISABLED or ODS_GRAYED)) then begin
            Opts.crText := COLOR_DARK_DISABLED;
            API_FillRect(UahMenuItem.Menu.hDC, @UahMenuItem.Struct.rcItem, Status.hMenuBrush);
        end else if longbool(UahMenuItem.Struct.itemState and ODS_INACTIVE) then begin
            Opts.crText := COLOR_DARK_INACTIVE;
            API_FillRect(UahMenuItem.Menu.hDC, @UahMenuItem.Struct.rcItem, Status.hMenuBrush);
        end else if longbool(UahMenuItem.Struct.itemState and ODS_HOTLIGHT) then begin
            Opts.crText := COLOR_DARK_LIGHT;
            API_FillRect(UahMenuItem.Menu.hDC, @UahMenuItem.Struct.rcItem, ORG_COLOR_GRAYTEXT);
        end else if longbool(UahMenuItem.Struct.itemState and ODS_SELECTED) then begin
            Opts.crText := COLOR_DARK_LIGHT;
            API_FillRect(UahMenuItem.Menu.hDC, @UahMenuItem.Struct.rcItem, ORG_COLOR_HIGHLIGHT);
        end else begin
            Opts.crText := COLOR_DARK_LIGHT;
            API_FillRect(UahMenuItem.Menu.hDC, @UahMenuItem.Struct.rcItem, Status.hMenuBrush);
        end;
        if longbool(UahMenuItem.Struct.itemState and ODS_NOACCEL) then begin
            dwFlags := dwFlags or DT_HIDEPREFIX;
        end;
        // 文字色を適用
        wsData := 'Menu';
        hTheme := API_OpenThemeData(hWnd, pwidechar(wsData));
        API_DrawThemeTextEx(hTheme, UahMenuItem.Menu.hDC,
            $8, // MENU_BARITEM
            $1, // MBI_NORMAL
            lpText, MenuItemInfo.cch, dwFlags, @UahMenuItem.Struct.rcItem, @Opts);
        // バッファを解放
        FreeMem(lpText, 256);
        // 成功
        result := 1;
    end;
    // DLL を解放
    API_FreeLibrary(hDLL);
end;


// *************************************************************************************************************************************************************
// WINDOW クラス
// *************************************************************************************************************************************************************

// ================================================================================
// CreateItem - ウィンドウアイテム作成
// ================================================================================
procedure CWINDOW.CreateItem(hThisInstance: longword; hMainWnd: longword; hFont: longword; lpItemName: pointer; lpCaption: pointer; dwItemID: longword;
    dwStylePlus: longword; dwStyleExPlus: longword; Box: TBOX);
var
    dwStyle: longword;
    dwStyleEx: longword;
begin
    dwStyle := dwStylePlus or WS_CHILD;
    dwStyleEx := dwStyleExPlus;
    hWnd := API_CreateWindowEx(dwStyleEx, lpItemName, lpCaption, dwStyle, Box.left, Box.top, Box.width, Box.height, hMainWnd, dwItemID,
        hThisInstance, NULLPOINTER);
    SendMessage(WM_SETFONT, hFont, NULL);
end;

// ================================================================================
// CreateWindow - ウィンドウ作成
// ================================================================================
procedure CWINDOW.CreateWindow(hThisInstance: longword; lpClassName: pointer; lpWndName: pointer; dwStylePlus: longword; dwStyleExPlus: longword; Box: TBOX);
var
    dwStyle: longword;
    dwStyleEx: longword;
begin
    dwStyle := dwStylePlus or WS_OVERLAPPED;
    dwStyleEx := dwStyleExPlus;
    hWnd := API_CreateWindowEx(dwStyleEx, lpClassName, lpWndName, dwStyle, Box.left, Box.top, Box.width, Box.height, NULL, NULL,
        hThisInstance, NULLPOINTER);
    bMessageBox := false;
end;

// ================================================================================
// DeleteWindow - ウィンドウ削除
// ================================================================================
procedure CWINDOW.DeleteWindow();
begin
    API_DestroyWindow(hWnd);
end;

// ================================================================================
// GetCaption - キャプション取得
// ================================================================================
function CWINDOW.GetCaption(lpCaption: pointer; nMaxCount: longint): longint;
begin
    result := API_GetWindowText(hWnd, lpCaption, nMaxCount);
end;

// ================================================================================
// GetSystemMenu - システムメニュー取得
// ================================================================================
function CWINDOW.GetSystemMenu(): CMENU;
begin
    result := CMENU.Create();
    result.hMenu := API_GetSystemMenu(hWnd, false);
end;

// ================================================================================
// GetWindowRect - 通常状態のウィンドウサイズ取得
// ================================================================================
function CWINDOW.GetWindowRect(lpRect: pointer): longbool;
var
    WindowPlacement: TWINDOWPLACEMENT;
begin
    WindowPlacement.length := SizeOf(TWINDOWPLACEMENT);
    WindowPlacement.flags := NULL;
    result := API_GetWindowPlacement(hWnd, @WindowPlacement);
    API_MoveMemory(lpRect, @WindowPlacement.rcNormalPosition, SizeOf(TRECT));
end;

// ================================================================================
// GetWindowStyle - ウィンドウスタイル取得
// ================================================================================
function CWINDOW.GetWindowStyle(): longword;
begin
    result := API_GetWindowLong(hWnd, GWL_STYLE);
end;

// ================================================================================
// GetWindowStyleEx - 拡張ウィンドウスタイル取得
// ================================================================================
function CWINDOW.GetWindowStyleEx(): longword;
begin
    result := API_GetWindowLong(hWnd, GWL_EXSTYLE);
end;

// ================================================================================
// Invalidate - ウィンドウ描画予約
// ================================================================================
function CWINDOW.Invalidate(): longbool;
begin
    result := API_InvalidateRect(hWnd, NULLPOINTER, true);
end;

// ================================================================================
// MessageBox - メッセージボックス表示
// ================================================================================
function CWINDOW.MessageBox(lpText: pointer; lpCaption: pointer; uType: longword): longint;
begin
    bMessageBox := true;
    API_SetForegroundWindow(hWnd);
    result := API_MessageBox(hWnd, lpText, lpCaption, uType);
    bMessageBox := false;
end;

// ================================================================================
// PostMessage - 非同期メッセージ送信
// ================================================================================
function CWINDOW.PostMessage(msg: longword; wParam: longword; lParam: longword): longbool;
begin
    result := API_PostMessage(hWnd, msg, wParam, lParam);
end;

// ================================================================================
// SendMessage - 同期メッセージ送信
// ================================================================================
function CWINDOW.SendMessage(msg: longword; wParam: longword; lParam: longword): longword;
begin
    result := API_SendMessage(hWnd, msg, wParam, lParam);
end;

// ================================================================================
// SetCaption - キャプション設定
// ================================================================================
procedure CWINDOW.SetCaption(lpCaption: pointer);
begin
    API_SetWindowText(hWnd, lpCaption);
end;

// ================================================================================
// SetWindowEnable - ウィンドウ有効設定
// ================================================================================
procedure CWINDOW.SetWindowEnable(bEnable: longbool);
begin
    API_EnableWindow(hWnd, bEnable);
end;

// ================================================================================
// SetWindowPosition - ウィンドウ位置設定
// ================================================================================
procedure CWINDOW.SetWindowPosition(nLeft: longint; nTop: longint; nWidth: longint; nHeight: longint);
begin
    API_SetWindowPos(hWnd, NULL, nLeft, nTop, nWidth, nHeight, SWP_NOACTIVATE or SWP_NOZODER);
end;

// ================================================================================
// SetWindowShowStyle - ウィンドウ表示スタイル設定
// ================================================================================
procedure CWINDOW.SetWindowShowStyle(nCmdShow: longint);
var
    WindowPlacement: TWINDOWPLACEMENT;
begin
    WindowPlacement.length := SizeOf(TWINDOWPLACEMENT);
    WindowPlacement.flags := NULL;
    API_GetWindowPlacement(hWnd, @WindowPlacement);
    WindowPlacement.showCmd := nCmdShow;
    API_SetWindowPlacement(hWnd, @WindowPlacement);
end;

// ================================================================================
// SetWindowTopMost - ウィンドウ最前面表示設定
// ================================================================================
procedure CWINDOW.SetWindowTopMost(bTopMost: longbool);
var
    hWndInsertAfter: longword;
begin
    if bTopMost then hWndInsertAfter := HWND_TOPMOST else hWndInsertAfter := HWND_NOTOPMOST;
    API_SetWindowPos(hWnd, hWndInsertAfter, NULL, NULL, NULL, NULL, SWP_NOACTIVATE or SWP_NOMOVE or SWP_NOSIZE);
end;

// ================================================================================
// UpdateWindow - ウィンドウ更新
// ================================================================================
procedure CWINDOW.UpdateWindow(bVisible: longbool);
var
    dwStyle: longint;
begin
    if bVisible then dwStyle := SWP_SHOWWINDOW else dwStyle := SWP_HIDEWINDOW;
    API_SetWindowPos(hWnd, NULL, NULL, NULL, NULL, NULL, dwStyle or SWP_NOMOVE or SWP_NOSIZE or SWP_NOZODER);
    API_UpdateWindow(hWnd);
end;


// *************************************************************************************************************************************************************
// BUTTON クラス
// *************************************************************************************************************************************************************

// ================================================================================
// CreateItem - ボタン作成
// ================================================================================
procedure CBUTTON.CreateItem(hThisInstance: longword; hMainWnd: longword; hFont: longword; lpItemName: pointer; lpCaption: pointer; dwItemID: longword;
    dwStylePlus: longword; Box: TBOX);
var
    dwStyle: longword;
    dwStyleEx: longword;
begin
    if Option.dwTheme = THEME_DARK then begin
        dwStyle := dwStylePlus or WS_CHILD or BS_OWNERDRAW;
        dwStyleEx := WS_EX_NOPARENTNOTIFY;
    end else begin
        dwStyle := dwStylePlus or WS_CHILD;
        dwStyleEx := WS_EX_NOPARENTNOTIFY or WS_EX_STATICEDGE;
    end;
    hWnd := API_CreateWindowEx(dwStyleEx, lpItemName, lpCaption, dwStyle, Box.left, Box.top, Box.width, Box.height, hMainWnd, dwItemID,
        hThisInstance, NULLPOINTER);
    SendMessage(WM_SETFONT, hFont, NULL);
end;

// ================================================================================
// DrawItem - ボタン描画
// ================================================================================
function CBUTTON.DrawItem(lParam: longword; bHighlight: longbool): longword;
var
    Struct: ^TDRAWITEMSTRUCT;
    hWnd: longword;
    hDC: longword;
    hBitmap: longword;
    dwWidth: longword;
    dwHeight: longword;
    bPushed: longbool;
    bFocused: longbool;
    bDisabled: longbool;
    lpText: pointer;
    Rect: TRECT;
begin
    // 初期化
    Struct := pointer(lParam);
    hWnd := Struct.hwndItem;
    bPushed := longbool(Struct.itemState and ODS_SELECTED);
    bFocused := longbool(Struct.itemState and ODS_FOCUS);
    bDisabled := longbool(Struct.itemState and ODS_DISABLED);
    // サイズを取得
    API_MoveMemory(@Rect, @Struct.rcItem, SizeOf(TRECT));
    dwWidth := Rect.right - Rect.left;
    dwHeight := Rect.bottom - Rect.top;
    // デバイスコンテキストを作成
    hDC := API_CreateCompatibleDC(Struct.hDC);
    hBitmap := API_SelectObject(hDC, API_CreateCompatibleBitmap(Struct.hDC, dwWidth, dwHeight));
    // 背景色を描画
    Rect.left := 0;
    Rect.top := 0;
    Rect.right := dwWidth;
    Rect.bottom := dwHeight;
    API_FillRect(hDC, @Rect, Status.hBackBrush);
    // 外枠を描画
    Inc(Rect.left);   // 1
    Dec(Rect.right);  // width - 1
    API_FillRect(hDC, @Rect, ORG_COLOR_GRAYTEXT);
    Dec(Rect.left);   // 0
    Inc(Rect.right);  // width
    Inc(Rect.top);    // 1
    Dec(Rect.bottom); // height - 1
    API_FillRect(hDC, @Rect, ORG_COLOR_GRAYTEXT);
    // フォーカス枠線を描画
    Inc(Rect.left);   // 1
    Dec(Rect.right);  // width - 1
    if bPushed or bFocused then begin
        if bPushed then API_FillRect(hDC, @Rect, Status.hTextBrush)
        else API_FillRect(hDC, @Rect, ORG_COLOR_BTNSHADOW);
        Inc(Rect.left);   // 2
        Dec(Rect.right);  // width - 2
        Inc(Rect.top);    // 2
        Dec(Rect.bottom); // height - 2
    end;
    // 枠線内部の背景を描画
    if bPushed then begin
        API_FillRect(hDC, @Rect, ORG_COLOR_GRAYTEXT);
        API_SetBkColor(Struct.hDC, API_GetSysColor(COLOR_GRAYTEXT));
    end else if bHighlight then begin
        API_FillRect(hDC, @Rect, ORG_COLOR_HIGHLIGHT);
        API_SetBkColor(Struct.hDC, API_GetSysColor(COLOR_HIGHLIGHT));
    end else begin
        API_FillRect(hDC, @Rect, Status.hBackBrush);
        API_SetBkColor(Struct.hDC, COLOR_DARK_BACK);
    end;
    // ボタンに背景をコピー
    API_MoveMemory(@Rect, @Struct.rcItem, SizeOf(TRECT));
    API_BitBlt(Struct.hDC, Rect.left, Rect.top, dwWidth, dwHeight, hDC, 0, 0, SRCCOPY);
    // デバイスコンテキストを解放
    API_DeleteObject(API_SelectObject(hDC, hBitmap));
    API_DeleteDC(hDC);
    // バッファを確保
    GetMem(lpText, 16);
    // テキストを取得
    API_GetWindowText(hWnd, lpText, 16);
    if bPushed then begin
        Inc(Rect.left);
        Inc(Rect.top);
        Inc(Rect.right);
        Inc(Rect.bottom);
    end;
    // テキストを描画
    if bDisabled then API_SetTextColor(Struct.hDC, COLOR_DARK_DISABLED)
    else API_SetTextColor(Struct.hDC, COLOR_DARK_TEXT);
    API_DrawText(Struct.hDC, lpText, -1, @Rect, DT_SINGLELINE or DT_CENTER or DT_VCENTER);
    // バッファを解放
    FreeMem(lpText, 16);
    // 描画成功
    result := 1;
end;


// *************************************************************************************************************************************************************
// WINDOWMAIN クラス
// *************************************************************************************************************************************************************

// ================================================================================
// AppendList - プレイリスト登録
// ================================================================================
procedure CWINDOWMAIN.AppendList();
var
    I: longint;
    J: longint;
    dwFileCount: longint;
    dwIndex: longint;
    dwCount: longint;
    dwSelect1: longint;
    dwSelect2: longint;
    hFile: longword;
    dwReadSize: longword;
    bAdd: longbool;
    bSelect: longbool;
    lpFile: pointer;
    lpBuffer: pointer;
    lpTitle: pointer;
    pV: ^byte;
    SPCHdr: TSPCHDR;
    KeyState: TKEYSTATE;
begin
    // プレイリストのアイテム数を取得
    dwFileCount := cwSortList.SendMessage(LB_GETCOUNT, NULL, NULL);
    // プレイリストにアイテムが登録されていない場合は終了
    if not longbool(dwFileCount) then exit;
    // キーボードの状態を取得 (Status.bShiftButton 等では状態を取得不可)
    API_GetKeyboardState(@KeyState);
    // 再描画禁止
    cwPlayList.SendMessage(WM_SETREDRAW, 0, NULL);
    // Ctrl キーが押されている場合
    if bytebool(KeyState.k[VK_CONTROL] and $80) then begin
        // プレイリストをすべてクリア
        cwFileList.SendMessage(LB_RESETCONTENT, NULL, NULL);
        cwPlayList.SendMessage(LB_RESETCONTENT, NULL, NULL);
        // 選択されているアイテムを取得
        dwIndex := 0;
        dwCount := 0;
    end else begin
        // 選択されているアイテムを取得
        dwIndex := cwPlayList.SendMessage(LB_GETCURSEL, NULL, NULL);
        dwCount := cwPlayList.SendMessage(LB_GETCOUNT, NULL, NULL);
    end;
    // Shift キーが押されていない場合は追加、押されている場合は挿入
    bAdd := not bytebool(KeyState.k[VK_SHIFT] and $80) or not longbool(dwCount);
    if bAdd then dwSelect1 := dwCount else dwSelect1 := dwIndex;
    dwSelect2 := dwSelect1 - 1;
    bSelect := false;
    // バッファを確保
    GetMem(lpFile, 1024);
    GetMem(lpBuffer, 1024);
    GetMem(lpTitle, 33);
    // プレイリストに追加
    for I := 0 to dwFileCount - 1 do begin
        // プレイリストのアイテム数が最大値以上の場合はループを抜ける
        if dwCount >= Option.dwListMax then break;
        // ファイル名を取得
        cwSortList.SendMessage(LB_GETTEXT, I, longword(lpFile));
        // ファイルをオープン
        hFile := INVALID_HANDLE_VALUE;
        if IsSafePath(lpFile) then hFile := API_CreateFile(lpFile, GENERIC_READ, FILE_SHARE_READ, NULLPOINTER, OPEN_EXISTING,
            FILE_ATTRIBUTE_NORMAL or FILE_FLAG_SEQUENTIAL_SCAN, NULL);
        // ファイルのオープンに失敗した場合はループを再開
        if hFile = INVALID_HANDLE_VALUE then continue;
        // ファイルをロード
        API_ReadFile(hFile, @SPCHdr, SizeOf(TSPCHDR), @dwReadSize, NULLPOINTER);
        // ファイルのロードに失敗した場合はループを再開
        if not longbool(dwReadSize) then continue;
        // ファイルを追加
        if bAdd then cwFileList.SendMessage(LB_ADDSTRING, NULL, longword(lpFile))
        else cwFileList.SendMessage(LB_INSERTSTRING, dwIndex + I, longword(lpFile));
        // ID666 フォーマット形式を取得
        GetID666Format(SPCHdr);
        // タイトルを取得
        if not bytebool(SPCHdr.TagFormat) or not bytebool(SPCHdr.Title[0]) then begin
            API_ZeroMemory(lpBuffer, 1024);
            API_GetFileTitle(lpFile, lpBuffer, 1023);
            API_ZeroMemory(lpTitle, 33);
            API_MoveMemory(lpTitle, lpBuffer, 32);
        end else begin
            API_ZeroMemory(lpTitle, 33);
            API_MoveMemory(lpTitle, @SPCHdr.Title[0], 32);
        end;
        // テキストの制御コードをスペースに変換
        pV := lpTitle;
        for J := 0 to 31 do begin
            if ((pV^ > $0) and (pV^ < $20)) or (pV^ = $7F) then pV^ := $20;
            Inc(pV);
        end;
        // プレイリストに追加
        if bAdd then begin
            cwPlayList.SendMessage(LB_ADDSTRING, NULL, longword(lpTitle));
            cwPlayList.SendMessage(LB_SETITEMDATA, dwCount, NULL);
        end else begin
            cwPlayList.SendMessage(LB_INSERTSTRING, dwIndex + I, longword(lpTitle));
            cwPlayList.SendMessage(LB_SETITEMDATA, dwIndex + I, NULL);
        end;
        // カーソル選択
        bSelect := true;
        // プレイリストのアイテム数を追加
        Inc(dwCount);
        Inc(dwSelect2);
        // ファイルをクローズ
        API_CloseHandle(hFile);
    end;
    // バッファを解放
    FreeMem(lpFile, 1024);
    FreeMem(lpBuffer, 1024);
    FreeMem(lpTitle, 33);
    // ソート用リストをクリア
    cwSortList.SendMessage(LB_RESETCONTENT, NULL, NULL);
    // 再描画許可
    cwPlayList.SendMessage(WM_SETREDRAW, 1, NULL);
    cwPlayList.Invalidate();
    // プレイリストのアイテムを選択
    if bSelect then begin
        cwPlayList.SendMessage(LB_SETCURSEL, dwSelect2, NULL);
        cwPlayList.SendMessage(LB_SETCURSEL, dwSelect1, NULL);
    end;
    // メニューを更新
    UpdateMenu();
end;

// ================================================================================
// CreateWindow - ウィンドウ作成
// ================================================================================
function CWINDOWMAIN.CreateWindow(hThisInstance: longword; lpClassName: pointer; lpArgs: pointer): longword;
var
    I: longint;
    J: longint;
    K: longint;
    dwBuffer: longword;
    sInfo: string;
    fsFile: textfile;
    sData: string;
    sBuffer: string;
    cBuffer: array of char;
    lpBuffer: pointer;
    lpString: pointer;
    sEXEPath: string;
    sCmdLine: string;
    sChPath: string;
    sFontName: string;
    dwLeft: longint;
    dwPlayDefault: longint;
    dwTop: longint;
    hWndApp: longword;
    hFontApp: longword;
    wsData: widestring;
    Box: TBOX;
    API_DwmSetWindowAttribute: function(hWnd: longword; dwAttribute: longword; pvAttribute: pointer; cbAttribute: longword): longword; stdcall;
    API_FlushMenuThemes: function(): longword; stdcall;
    API_RegisterPowerSettingNotification: function(hRecipient: longword; powerSettingGuid: pointer; flags: longword): longword; stdcall;
    API_RegisterSuspendResumeNotification: function(hRecipient: longword; flags: longword): longword; stdcall;
    API_RtlGetVersion: function(lpVersionInfo: pointer): longbool; stdcall;
    API_SetPreferredAppMode: function(dwMode: longword): longword; stdcall;
    API_SetWindowTheme: function(hWnd: longword; pszSubAppName: pointer; pszSubIdList: pointer): longword; stdcall;
{$IFDEF UACDROP}
    API_ChangeWindowMessageFilter: function(msg: longword; dwFlag: longword): longword; stdcall;
{$ENDIF}

function GetParameter(var dwStart: longint; dwLength: longint; bLast: longbool): string;
var
    I: longint;
    J: longint;
    K: longint;
    cEnd: char;
begin
    // サイズがオーバーフローする場合
    if dwStart > dwLength then begin
        result := '';
        exit;
    end;
    // スペースをスキップ
    for I := dwStart to dwLength do if not IsSingleByte(sBuffer, I, ' ') then begin
        dwStart := I;
        break;
    end;
    // 最初の文字を取得
    if IsSingleByte(sBuffer, dwStart, '"') then begin
        cEnd := '"';
        Inc(dwStart);
        J := 1;
    end else if IsSingleByte(sBuffer, dwStart, '''') then begin
        cEnd := '''';
        Inc(dwStart);
        J := 1;
    end else begin
        if bLast then cEnd := NULLCHAR else cEnd := ' ';
        J := 0;
    end;
    // 最後の文字を取得
    K := dwLength + 1;
    for I := dwStart to dwLength do if IsSingleByte(sBuffer, I, cEnd) then begin
        K := I;
        break;
    end;
    // 文字を取得
    result := Trim(Copy(sBuffer, dwStart, K - dwStart));
    // オフセットを取得
    dwStart := K + J;
end;

function SimpleWindowBox(nLeft: longint; nTop: longint; nWidth: longint; nHeight: longint): TBOX;
begin
    Box.left := nLeft;
    Box.top := nTop;
    Box.width := nWidth;
    Box.height := nHeight;
    result := Box;
end;

function ScalableWindowBox(nLeft: longint; nTop: longint; nWidth: longint; nHeight: longint): TBOX;
begin
    if Status.dwScale = 2 then begin
        Box.left := nLeft;
        Box.top := nTop;
        Box.width := nWidth;
        Box.height := nHeight;
    end else begin
        Box.left := (nLeft * Status.dwScale) shr 1;
        Box.top := (nTop * Status.dwScale) shr 1;
        Box.width := (nWidth * Status.dwScale) shr 1;
        Box.height := (nHeight * Status.dwScale) shr 1;
    end;
    result := Box;
end;

{$IFNDEF TRY700A}{$IFNDEF TRY700W}{$IFDEF SIGNATURE}
function CheckImageHash(const sPath: string; dwBase: longword): longword;
var
    dwResult: longword;
    dwHeaderSum: longword;
    dwCheckSum: longword;
begin
    // チェックサムを取得
    sData := Concat(sChPath, sPath);
    dwResult := API_MapFileAndCheckSum(pchar(sData), @dwHeaderSum, @dwCheckSum);
    // ファイルのオープンに失敗した場合は終了
    result := dwBase + dwResult;
    if longbool(dwResult) then exit;
    // チェックサムが一致しない場合は終了
    result := dwBase + 9;
    if dwHeaderSum <> dwCheckSum then exit;
    // 終了
    result := 0;
end;
{$ENDIF}{$ENDIF}{$ENDIF}

procedure SetMenuTextAndTip(var cmMenu: CMENU; nSize: longint; dwBase: longint; MsgArray: array of pchar; bRadio: longbool); overload;
var
    I: longint;
begin
    // メニューを作成
    cmMenu := CMENU.Create();
    cmMenu.CreatePopupMenu();
    // メニューテキストを設定
    for I := 0 to nSize - 1 do begin
        if longbool(MsgArray[I]) then cmMenu.AppendMenu(dwBase + I, pchar(MsgArray[I]), bRadio)
        else cmMenu.AppendSeparator();
    end;
end;

procedure SetMenuTextAndTip(var cmMenu: CMENU; nSize: longint; dwBase: longint; PerIndex: array of longword; TipIndex: array of longword); overload;
var
    I: longint;
begin
    // メニューを作成
    cmMenu := CMENU.Create();
    cmMenu.CreatePopupMenu();
    // メニューテキストを設定
    for I := 0 to nSize - 1 do begin
        if longbool(PerIndex[I]) then begin
            sBuffer := Concat('&', IntToStr(STR_MENU_SETUP_PER_INTEGER[PerIndex[I]]), STR_MENU_SETUP_PERCENT[Status.dwLanguage]);
            if longbool(TipIndex[I]) then sBuffer := Concat(sBuffer, #9, STR_MENU_SETUP_TIP[Status.dwLanguage][TipIndex[I]]);
            cmMenu.AppendMenu(dwBase + I, pchar(sBuffer), true);
        end else begin
            cmMenu.AppendSeparator();
        end;
    end;
end;

function GetProcAddress(method: pchar): pointer;
begin
    result := API_GetProcAddress(dwBuffer, method);
    if not longbool(result) then I := 2;
end;

function GetINIValue(dwDef: longint): longint; overload;
begin
    result := StrToInt(Copy(sData, BUFFER_START, Length(sData) - BUFFER_LENGTH), dwDef);
end;

function GetINIValue(dwDef: longword): longword; overload;
begin
    result := StrToInt(Copy(sData, BUFFER_START, Length(sData) - BUFFER_LENGTH), dwDef);
end;

function ToBool(dwValue: longword): longbool;
begin
{$IFDEF FREEPASCAL}
    // NOTE: Free Pascal の場合、longword を longbool にキャストしても、
    // 内部的には -1 or 0 ではなく dwValue の値をそのまま使用するため、
    // dwValue = 1 のとき、longbool(dwValue) and longbool(2) が false 扱いになる
    // 確実に -1 or 0 に変換することで、上記判定が正しく true 扱いになる
    if longbool(dwValue) then result := true else result := false;
{$ELSE}
    // NOTE: Boland Delphi の場合、longbool にキャストすると、
    // 内部的には必ず -1 or 0 になる
    // ただし、ほとんどの場合無用な変換であるため、若干パフォーマンスが悪化する
    result := longbool(dwValue);
{$ENDIF}
end;

begin
    // 初期化
    result := 0;
    Randomize();
    Status.hBackBrush := NULL;
    Status.hTextBrush := NULL;
    Status.hMenuBrush := NULL;
{$IFDEF DEBUGLOG}
    _WriteLog('initialize ---------------------------------------------------------------------');
{$ENDIF}
    // コマンドラインを取得
    lpBuffer := API_GetCommandLine();
    J := GetSize(lpBuffer, 1023);
    SetLength(cBuffer, J);
    API_MoveMemory(@cBuffer[0], lpBuffer, J);
{$IFDEF FREEPASCAL}
    sBuffer := ChrToStr(cBuffer);
{$ELSE}
    // NOTE: Boland Delphi の場合、char の動的配列を string にキャストする場合は、
    // 直接 string() を使用する
    sBuffer := string(cBuffer);
{$ENDIF}
    // パラメータを取得
    I := 1;
    sEXEPath := GetParameter(I, J, false);
    sCmdLine := GetParameter(I, J, true);
    // ウィンドウを検索
    hWndApp := API_FindWindowEx(NULL, NULL, lpClassName, NULLPOINTER);
    // ウィンドウが見つかった場合
    if longbool(hWndApp) then begin
        // ウィンドウを登録
        cwWindowMain := CWINDOW.Create();
        cwWindowMain.hWnd := hWndApp;
        // コマンドラインを処理
        if not longbool(Length(sCmdLine)) then begin
            // 通常サイズに変更
            if longbool(cwWindowMain.GetWindowStyle() and WS_MINIMIZE) then cwWindowMain.SetWindowShowStyle(SW_SHOWNORMAL);
            // ウィンドウを前面に移動
            API_SetForegroundWindow(hWndApp);
        end else begin
            // ウィンドウを検索
            hWndApp := API_FindWindowEx(hWndApp, NULL, pchar(ITEM_STATIC), pchar(FILE_DEFAULT));
            // ウィンドウが見つかった場合
            if longbool(hWndApp) then begin
                // バッファを確保
                GetMem(lpBuffer, 1024);
                // バッファにコピー
                API_ZeroMemory(lpBuffer, 1024);
                lpString := pchar(sCmdLine);
                API_MoveMemory(lpBuffer, lpString, Length(sCmdLine));
                // ウィンドウを登録
                cwStaticFile := CWINDOW.Create();
                cwStaticFile.hWnd := hWndApp;
                // メッセージを送信
                cwStaticFile.SendMessage(WM_SETTEXT, NULL, longword(lpBuffer));
                cwWindowMain.PostMessage(WM_APP_MESSAGE, WM_APP_TRANSMIT or $1, hWndApp);
                // ウィンドウを解放
                cwStaticFile.Free();
                // バッファを解放
                FreeMem(lpBuffer, 1024);
            end;
        end;
        // ウィンドウを解放
        cwWindowMain.Free();
        // フラグを設定
        Apu.hSNESAPU := NULL;
        result := 99;
        // 終了
        exit;
    end;
    // ウィンドウを作成
    Status.dwFocusHandle := NULL;
    cwWindowMain := CWINDOW.Create();
    cwWindowMain.CreateWindow(hThisInstance, lpClassName, pchar(DEFAULT_TITLE), WS_CLIPSIBLINGS or WS_DLGFRAME or WS_MINIMIZEBOX or WS_OVERLAPPED
        or WS_SYSMENU, WS_EX_ACCEPTFILES or WS_EX_CONTROLPARENT or WS_EX_WINDOWEDGE, SimpleWindowBox(3000, 3000, 1024, 1024));
    hWndApp := cwWindowMain.hWnd;
    // バッファを確保
    GetMem(Status.lpCurrentPath, 1024);
    GetMem(Status.lpSPCFile, 1024);
    GetMem(Status.lpSPCDir, 1024);
    GetMem(Status.lpSPCName, 1024);
    GetMem(Status.lpOpenPath, 1024);
    GetMem(Status.lpSavePath, 1024);
    // バッファを確保
    lpBuffer := Status.lpCurrentPath;
    // EXE ファイル名を取得
    dwBuffer := GetPosSeparator(sEXEPath);
    if longbool(dwBuffer) then sEXEPath := Copy(sEXEPath, dwBuffer + 1, Length(sEXEPath));
    if (Length(sEXEPath) < 5) or (sEXEPath[Length(sEXEPath) - 3] <> '.') then sEXEPath := Concat(sEXEPath, '.exe');
    // カレントパスを取得
    API_GetModuleFileName(hThisInstance, lpBuffer, 1024);
    dwBuffer := GetPosSeparator(PtrToStr(lpBuffer));
    if dwBuffer > 1024 then dwBuffer := 1024;
    API_ZeroMemory(pointer(longword(lpBuffer) + dwBuffer), 1024 - dwBuffer);
    API_MoveMemory(Status.lpOpenPath, lpBuffer, 1024);
    API_MoveMemory(Status.lpSavePath, lpBuffer, 1024);
    Status.lpCurrentSize := GetSize(lpBuffer, 1023);
    sChPath := Copy(PtrToStr(lpBuffer), 1, Status.lpCurrentSize);
    // パラメータを初期化
    Wave.dwIndex := 0;
    Wave.dwLastIndex := 0;
    Status.hInstance := hThisInstance;
    Status.dwWaveMessage := WAVE_MESSAGE_MAX_COUNT;
    Status.bOpen := false;
    Status.bPlay := false;
    Status.bPause := false;
    Status.bSPCRestart := false;
    Status.bShiftButton := false;
    Status.bCtrlButton := false;
    Status.bBreakButton := false;
    Status.bChangePlay := false;
    Status.bChangeShift := false;
    Status.bOptionLock := false;
    Status.dwReady := READY_INITIALIZE;
    Status.dwTitle := TITLE_HIDE;
    Status.dwInfo := NULL;
    Status.dwRedrawInfo := REDRAW_OFF;
    Status.dwMenuFlags := 0;
    Status.dwOpenFilterIndex := DIALOG_OPEN_DEFAULT;
    Status.dwSaveFilterIndex := DIALOG_SAVE_DEFAULT;
    Status.DblClickPoint.x := 0;
    Status.DblClickPoint.y := 0;
    Status.DragPoint.x := -1;
    Status.DragPoint.y := -1;
    Status.bDropCancel := false;
    Status.dwScale := 2;
    API_ZeroMemory(@Status.BreakPoint, 65536);
    Status.dwNextTick := 0;
    API_ZeroMemory(@Status.DSPCheat, 256);
    Status.bEmuDebug := false;
    Status.dwNoSleepTime := 0;
{$IFDEF CONTEXT}
    Status.dwContextSize := 0;
    Status.lpContext := NULLPOINTER;
{$ENDIF}
    // 設定を初期化
    Option.dwAmp := AMP_100;
    Option.dwBit := BIT_16;
    Option.dwBmpFont := 0;
    Option.bBPM := true;
    Option.dwBufferNum := 22;
    Option.dwBufferTime := 23;
    Option.dwCacheDiff := 5000;
    Option.dwCacheInt := 10000;
    Option.dwCacheKOn := $40;
    Option.dwCacheNum := 60;
    Option.dwChannel := CHANNEL_STEREO;
    Option.dwDeviceID := -1;
    Option.sDeviceName := '';
    Option.dwDrawInfo := 0;
    Option.bEarSafe := true;
    Option.dwFadeTime := 10000;
    Option.dwFeedback := FEEDBACK_000;
    Option.sFontName := '';
    Option.dwHideTime := 1000;
    Option.dwInfo := INFO_INDICATOR;
    Option.dwInter := INTER_GAUSS;
    Option.dwLanguage := LOCALE_AUTO;
    dwLeft := 100;
    Option.dwListHeight := 127;
    Option.dwListMax := 5000;
    Option.dwMute := 0;
    Option.dwNextTime := 5000;
    Option.dwNoise := 0;
    Option.dwNoSleep := 0;
    Option.dwOption := OPTION_LOWPASS + OPTION_ECHOFIR;
    Option.dwPitch := PITCH_NORMAL;
    Option.bPitchAsync := false;
    dwPlayDefault := -1;
    Option.dwPlayTime := 120000;
    Option.dwPlayMax := 1;
    Option.dwPlayOrder := PLAY_ORDER_NEXT;
    Option.dwPriority := NORMAL_PRIORITY_CLASS;
    Option.dwRate := 32000;
    Option.dwScale := 100;
    Option.dwSeekBar := 180000;
    Option.bSeekFast := false;
    Option.dwSeekMax := 600000;
    Option.bSeekAsync := false;
    Option.dwSeekTime := 5000;
    Option.dwSeparate := SEPARATE_050;
    Option.dwShiftKey := 0;
    Option.dwSpeedBas := SPEED_100;
    Option.dwSpeedTun := 0;
    Option.dwTheme := THEME_DEFAULT;
    dwTop := 100;
    Option.bTopMost := false;
    Option.dwTimerOptionDisplay := TIMER_INTERVAL_OPTION_DISPLAY;
    Option.dwTimerOptionLock := TIMER_INTERVAL_OPTION_LOCK;
    Option.dwTimerRedrawResume := TIMER_INTERVAL_REDRAW_RESUME;
    Option.dwVolumeColor := 0;
    Option.bVolumeReset := true;
    Option.dwVolumeSpeed := 1;
    Option.dwWaitTime := 3000;
    Option.dwWaveBlank := 500;
    Option.dwWaveFormat := 0;
    // INI の存在をチェック
    sData := Concat(sChPath, INI_FILE);
    if IsSafePath(pchar(sData)) and Exists(pchar(sData), $FFFFFFFF) then begin
        // ファイルをオープン
        AssignFile(fsFile, sData);
        // ファイルを読み込む
        Reset(fsFile);
        while not Eof(fsFile) do begin
            Readln(fsFile, sData);
            sBuffer := Copy(sData, 1, BUFFER_LENGTH);
            if sBuffer = BUFFER_AMP_____ then Option.dwAmp := GetINIValue(Option.dwAmp);
            if sBuffer = BUFFER_BIT_____ then Option.dwBit := GetINIValue(Option.dwBit);
            if sBuffer = BUFFER_BMPFONT_ then Option.dwBmpFont := GetINIValue(Option.dwBmpFont);
            if sBuffer = BUFFER_BPM_____ then Option.bBPM := ToBool(GetINIValue(longint(Option.bBPM)));
            if sBuffer = BUFFER_BUFNUM__ then Option.dwBufferNum := GetINIValue(Option.dwBufferNum);
            if sBuffer = BUFFER_BUFTIME_ then Option.dwBufferTime := GetINIValue(Option.dwBufferTime);
            if sBuffer = BUFFER_CACHEDIF then Option.dwCacheDiff := GetINIValue(Option.dwCacheDiff);
            if sBuffer = BUFFER_CACHEINT then Option.dwCacheInt := GetINIValue(Option.dwCacheInt);
            if sBuffer = BUFFER_CACHEKON then Option.dwCacheKOn := GetINIValue(Option.dwCacheKOn);
            if sBuffer = BUFFER_CACHENUM then Option.dwCacheNum := GetINIValue(Option.dwCacheNum);
            if sBuffer = BUFFER_CHANNEL_ then Option.dwChannel := GetINIValue(Option.dwChannel);
            if sBuffer = BUFFER_DEVICE__ then Option.dwDeviceID := GetINIValue(Option.dwDeviceID);
            if sBuffer = BUFFER_DEVNAME_ then Option.sDeviceName := Copy(sData, BUFFER_START, Length(sData) - BUFFER_LENGTH);
            if sBuffer = BUFFER_DRAWINFO then Option.dwDrawInfo := GetINIValue(Option.dwDrawInfo);
            if sBuffer = BUFFER_EARSAFE_ then Option.bEarSafe := ToBool(GetINIValue(longint(Option.bEarSafe)));
            if sBuffer = BUFFER_FADELENG then Option.dwFadeTime := GetINIValue(Option.dwFadeTime);
            if sBuffer = BUFFER_FEEDBACK then Option.dwFeedback := GetINIValue(Option.dwFeedback);
            if sBuffer = BUFFER_FONTNAME then Option.sFontName := Copy(sData, BUFFER_START, Length(sData) - BUFFER_LENGTH);
            if sBuffer = BUFFER_HIDELENG then Option.dwHideTime := GetINIValue(Option.dwHideTime);
            if sBuffer = BUFFER_INFO____ then Option.dwInfo := GetINIValue(Option.dwInfo);
            if sBuffer = BUFFER_INTER___ then Option.dwInter := GetINIValue(Option.dwInter);
            if sBuffer = BUFFER_LANGUAGE then Option.dwLanguage := GetINIValue(Option.dwLanguage);
            if sBuffer = BUFFER_LEFT____ then dwLeft := GetINIValue(dwLeft);
            if sBuffer = BUFFER_LISTHGT_ then Option.dwListHeight := GetINIValue(Option.dwListHeight);
            if sBuffer = BUFFER_LISTMAX_ then Option.dwListMax := GetINIValue(Option.dwListMax);
            if sBuffer = BUFFER_MUTE____ then Option.dwMute := GetINIValue(Option.dwMute);
            if sBuffer = BUFFER_NEXTLENG then Option.dwNextTime := GetINIValue(Option.dwNextTime);
            if sBuffer = BUFFER_NOISE___ then Option.dwNoise := GetINIValue(Option.dwNoise);
            if sBuffer = BUFFER_NOSLEEP_ then Option.dwNoSleep := GetINIValue(Option.dwNoSleep) and $3;
            if sBuffer = BUFFER_OPTION__ then Option.dwOption := GetINIValue(Option.dwOption);
            if sBuffer = BUFFER_PITCH___ then Option.dwPitch := GetINIValue(Option.dwPitch);
            if sBuffer = BUFFER_PITCHSNC then Option.bPitchAsync := ToBool(GetINIValue(longint(Option.bPitchAsync)));
            if sBuffer = BUFFER_PLAYDEF_ then dwPlayDefault := GetINIValue(longint(0));
            if sBuffer = BUFFER_PLAYLENG then Option.dwPlayTime := GetINIValue(Option.dwPlayTime);
            if sBuffer = BUFFER_PLAYTIME then Option.dwPlayMax := GetINIValue(Option.dwPlayMax);
            if sBuffer = BUFFER_PLAYTYPE then Option.dwPlayOrder := GetINIValue(Option.dwPlayOrder);
            if sBuffer = BUFFER_PRIORITY then Option.dwPriority := GetINIValue(Option.dwPriority);
            if sBuffer = BUFFER_RATE____ then Option.dwRate := GetINIValue(Option.dwRate);
            if sBuffer = BUFFER_SCALE___ then Option.dwScale := GetINIValue(Option.dwScale);
            if sBuffer = BUFFER_SEEKBAR_ then Option.dwSeekBar := GetINIValue(Option.dwSeekBar);
            if sBuffer = BUFFER_SEEKFAST then Option.bSeekFast := ToBool(GetINIValue(longint(Option.bSeekFast)));
            if sBuffer = BUFFER_SEEKMAX_ then Option.dwSeekMax := GetINIValue(Option.dwSeekMax);
            if sBuffer = BUFFER_SEEKSNC_ then Option.bSeekAsync := ToBool(GetINIValue(longint(Option.bSeekAsync)));
            if sBuffer = BUFFER_SEEKTIME then Option.dwSeekTime := GetINIValue(Option.dwSeekTime);
            if sBuffer = BUFFER_SEPARATE then Option.dwSeparate := GetINIValue(Option.dwSeparate);
            if sBuffer = BUFFER_SHIFTKEY then Option.dwShiftKey := GetINIValue(Option.dwShiftKey);
            if sBuffer = BUFFER_SPEED___ then Option.dwSpeedBas := GetINIValue(Option.dwSpeedBas);
            if sBuffer = BUFFER_SPEEDTUN then Option.dwSpeedTun := GetINIValue(Option.dwSpeedTun);
            if sBuffer = BUFFER_THEME___ then Option.dwTheme := GetINIValue(Option.dwTheme);
            if sBuffer = BUFFER_TOP_____ then dwTop := GetINIValue(dwTop);
            if sBuffer = BUFFER_TOPMOST_ then Option.bTopMost := ToBool(GetINIValue(longint(Option.bTopMost)));
            if sBuffer = BUFFER_TOPTDISP then Option.dwTimerOptionDisplay := GetINIValue(Option.dwTimerOptionDisplay);
            if sBuffer = BUFFER_TOPTLOCK then Option.dwTimerOptionLock := GetINIValue(Option.dwTimerOptionLock);
            if sBuffer = BUFFER_TREDRAW_ then Option.dwTimerRedrawResume := GetINIValue(Option.dwTimerRedrawResume);
            if sBuffer = BUFFER_VOLCOLOR then Option.dwVolumeColor := GetINIValue(Option.dwVolumeColor);
            if sBuffer = BUFFER_VOLRESET then Option.bVolumeReset := ToBool(GetINIValue(longint(Option.bVolumeReset)));
            if sBuffer = BUFFER_VOLSPEED then Option.dwVolumeSpeed := GetINIValue(Option.dwVolumeSpeed);
            if sBuffer = BUFFER_WAITLENG then Option.dwWaitTime := GetINIValue(Option.dwWaitTime);
            if sBuffer = BUFFER_WAVBLANK then Option.dwWaveBlank := GetINIValue(Option.dwWaveBlank);
            if sBuffer = BUFFER_WAVEFMT_ then Option.dwWaveFormat := GetINIValue(Option.dwWaveFormat);
        end;
        // ファイルをクローズ
        CloseFile(fsFile);
    end;
    // 設定値を調整 (BUFNUM)
    if Option.dwBufferNum < 4 then Option.dwBufferNum := 4;
    if Option.dwBufferNum > 100 then Option.dwBufferNum := 100;
    // 設定値を調整 (BUFTIME)
    if Option.dwBufferTime < 10 then Option.dwBufferTime := 10;
    if Option.dwBufferTime > 5000 then Option.dwBufferTime := 5000;
    // 設定値を調整 (CACHENUM)
    if Option.dwCacheNum > 1000 then Option.dwCacheNum := 1000;
    // 設定値を調整 (EARSAFE, OPTION)
    if longbool(Option.dwOption and OPTION_NOEARSAFE) then Option.bEarSafe := false;
{$IFDEF FREEPASCAL}
    Option.dwOption := Option.dwOption and (OPTION_NOEARSAFE or OPTION_FLOATOUT xor -1);
{$ELSE}
    Option.dwOption := Option.dwOption and not (OPTION_NOEARSAFE or OPTION_FLOATOUT);
{$ENDIF}
    // 設定値を調整 (LANGUAGE)
    if longbool(Option.dwLanguage) and (Option.dwLanguage <= LANGUAGE_NUM) then Status.dwLanguage := Option.dwLanguage - 1
    else if API_GetUserDefaultLCID() and $FFFF = $0411 then Status.dwLanguage := 0
    else Status.dwLanguage := 1;
    if Status.dwLanguage > 1 then Status.dwLanguage := 0;
    // 設定値を調整 (PLAYTIME)
    if (Option.dwPlayMax >= 1) and (dwPlayDefault >= 0) then Option.dwPlayMax := (Option.dwPlayMax and 1) + (dwPlayDefault and 1);
    // 設定値を調整 (PLAYTYPE)
    Status.dwPlayOrder := Option.dwPlayOrder;
    // 設定値を調整 (SCALE)
    if Option.dwScale >= 200 then Status.dwScale := 4
    else if Option.dwScale >= 150 then Status.dwScale := 3;
{$IFNDEF TRY700A}{$IFNDEF TRY700W}{$IFDEF SIGNATURE}
    // SPCPLAY.EXE の破損を確認
    if not longbool(result) then result := CheckImageHash(sEXEPath, 10);
    // SNESAPU.DLL の破損を確認
    if not longbool(result) then result := CheckImageHash(SNESAPU_FILE, 20);
{$ENDIF}{$ENDIF}{$ENDIF}
    // ファイルが正常の場合
    K := 0;
    if not longbool(result) then begin
        // SNESAPU.DLL をロード
        sData := Concat(sChPath, SNESAPU_FILE);
        dwBuffer := API_LoadLibraryEx(pchar(sData), NULL, LOAD_LIBRARY_SEARCH_APPLICATION_DIR);
        if longbool(dwBuffer) then begin
            I := 0;
            @Apu.EmuAPU := GetProcAddress(pchar('EmuAPU'));
            @Apu.GetAPUData := GetProcAddress(pchar('GetAPUData'));
            @Apu.GetScript700Data := GetProcAddress(pchar('GetScript700Data'));
            @Apu.GetSPCRegs := GetProcAddress(pchar('GetSPCRegs'));
            @Apu.InPort := GetProcAddress(pchar('InPort'));
            @Apu.LoadSPCFile := GetProcAddress(pchar('LoadSPCFile'));
            @Apu.ResetAPU := GetProcAddress(pchar('ResetAPU'));
            @Apu.SeekAPU := GetProcAddress(pchar('SeekAPU'));
            @Apu.SetAPULength := GetProcAddress(pchar('SetAPULength'));
            @Apu.SetAPUOption := GetProcAddress(pchar('SetAPUOpt'));
            @Apu.SetAPURAM := GetProcAddress(pchar('SetAPURAM'));
            @Apu.SetAPUSpeed := GetProcAddress(pchar('SetAPUSmpClk'));
            @Apu.SetDSPAmp := GetProcAddress(pchar('SetDSPAmp'));
            @Apu.SetDSPFeedback := GetProcAddress(pchar('SetDSPEFBCT'));
            @Apu.SetDSPPitch := GetProcAddress(pchar('SetDSPPitch'));
            @Apu.SetDSPReg := GetProcAddress(pchar('SetDSPReg'));
            @Apu.SetDSPStereo := GetProcAddress(pchar('SetDSPStereo'));
            @Apu.SetScript700 := GetProcAddress(pchar('SetScript700'));
            @Apu.SetScript700Data := GetProcAddress(pchar('SetScript700Data'));
            @Apu.SetSPCDbg := GetProcAddress(pchar('SetSPCDbg'));
            @Apu.SNESAPUCallback := GetProcAddress(pchar('SNESAPUCallback'));
            @Apu.SNESAPUInfo := GetProcAddress(pchar('SNESAPUInfo'));
{$IFDEF TIMERTRICK}
            @Apu.SetTimerTrick := GetProcAddress(pchar('SetTimerTrick'));
{$ENDIF}
{$IFDEF TRY700A}
            @Apu.Try700 := GetProcAddress(pchar('try700'));
{$ENDIF}
{$IFDEF TRY700W}
            @Apu.Try700 := GetProcAddress(pchar('try700'));
{$ENDIF}
{$IFDEF TRANSMITSPC}
            @Apu.TransmitSPC := GetProcAddress(pchar('TransmitSPC'));
            @Apu.TransmitSPCEx := GetProcAddress(pchar('TransmitSPCEx'));
            @Apu.StopTransmitSPC := GetProcAddress(pchar('StopTransmitSPC'));
            @Apu.WriteIO := GetProcAddress(pchar('WriteIO'));
{$ENDIF}
{$IFDEF CONTEXT}
            @Apu.GetSNESAPUContextSize := GetProcAddress(pchar('GetSNESAPUContextSize'));
            @Apu.GetSNESAPUContext := GetProcAddress(pchar('GetSNESAPUContext'));
            @Apu.SetSNESAPUContext := GetProcAddress(pchar('SetSNESAPUContext'));
{$ENDIF}
{$IFDEF SPCDEBUG}
            @Apu.SetDSPDbg := GetProcAddress(pchar('SetDSPDbg'));
{$ENDIF}
            if longbool(I) then result := 2;
            Apu.SNESAPUCallback(@_SNESAPUCallback, CBE_INCS700 or CBE_INCDATA or CBE_REQBP);
            Apu.SNESAPUInfo(@K, NULLPOINTER, NULLPOINTER);
{$IFNDEF TRANSMITSPC}{$IFDEF SIGNATURE}
            if K <> SNESAPU_VERSION then result := 3;
{$ENDIF}{$ENDIF}
        end else result := 1;
        Apu.hSNESAPU := dwBuffer;
    end;
    // SNESAPU.DLL の情報を取得
    if not longbool(result) then begin
        Apu.GetAPUData(@Apu.Ram, @Apu.XRam, @Apu.SPCOutPort, @Apu.T64Count, @Apu.DspReg, @Apu.Voices, @Apu.VolumeMaxLeft, @Apu.VolumeMaxRight);
        if longbool((longword(Apu.Ram) and $FFFF) or ((longword(Apu.DspReg) or longword(Apu.Voices)) and $FF)) then result := 4;
    end;
    // SNESAPU.DLL の読み込みに失敗した場合
    if longbool(result) then begin
        // メッセージを表示
        ShowErrMsg(100 + result);
        // SNESAPU.DLL を解放
        if longbool(Apu.hSNESAPU) then API_FreeLibrary(Apu.hSNESAPU);
        // バッファを解放
        FreeMem(Status.lpCurrentPath, 1024);
        FreeMem(Status.lpSPCFile, 1024);
        FreeMem(Status.lpSPCDir, 1024);
        FreeMem(Status.lpSPCName, 1024);
        FreeMem(Status.lpOpenPath, 1024);
        FreeMem(Status.lpSavePath, 1024);
        // ウィンドウを削除
        cwWindowMain.DeleteWindow();
        cwWindowMain.Free();
        // 終了
        exit;
    end;
{$IFDEF SPCBPMTEST}
    // SPC_BPM.DLL をロード
    sData := Concat(sChPath, SPC_BPM_FILE);
    dwBuffer := API_LoadLibraryEx(pchar(sData), NULL, LOAD_LIBRARY_SEARCH_APPLICATION_DIR);
    Apu.hSPCBPM := dwBuffer;
    if longbool(dwBuffer) then begin
        @Apu.BPMInitialize := API_GetProcAddress(dwBuffer, pchar('Initialize'));
        @Apu.BPMStart := API_GetProcAddress(dwBuffer, pchar('Start'));
        @Apu.BPMStop := API_GetProcAddress(dwBuffer, pchar('Stop'));
        @Apu.BPMGetBPM := API_GetProcAddress(dwBuffer, pchar('GetBPM'));
    end;
    // SPC_BPM.DLL を初期化
    Apu.BPMInitialize(Apu.hSNESAPU);
{$ENDIF}
    // KSDATAFORMAT_SUBTYPE_IEEE_FLOAT : 00000003-0000-0010-8000-00AA00389B71
    KSDATAFORMAT_SUBTYPE_IEEE_FLOAT.DataX[0] := $00000003;
    KSDATAFORMAT_SUBTYPE_IEEE_FLOAT.DataX[1] := $00100000;
    KSDATAFORMAT_SUBTYPE_IEEE_FLOAT.DataX[2] := $AA000080;
    KSDATAFORMAT_SUBTYPE_IEEE_FLOAT.DataX[3] := $719B3800;
    // KSDATAFORMAT_SUBTYPE_PCM : 00000001-0000-0010-8000-00AA00389B71
    KSDATAFORMAT_SUBTYPE_PCM.DataX[0] := $00000001;
    KSDATAFORMAT_SUBTYPE_PCM.DataX[1] := $00100000;
    KSDATAFORMAT_SUBTYPE_PCM.DataX[2] := $AA000080;
    KSDATAFORMAT_SUBTYPE_PCM.DataX[3] := $719B3800;
    // IID_IDropSource : 00000121-0000-0000-C000-000000000046
    IID_IDropSource.DataX[0] := $00000121;
    IID_IDropSource.DataX[1] := $00000000;
    IID_IDropSource.DataX[2] := $000000C0;
    IID_IDropSource.DataX[3] := $46000000;
    // IID_IDataObject : 0000010E-0000-0000-C000-000000000046
    IID_IDataObject.DataX[0] := $0000010E;
    IID_IDataObject.DataX[1] := $00000000;
    IID_IDataObject.DataX[2] := $000000C0;
    IID_IDataObject.DataX[3] := $46000000;
    // IID_IUnknown : 00000000-0000-0000-C000-000000000046
    IID_IUnknown.DataX[0] := $00000000;
    IID_IUnknown.DataX[1] := $00000000;
    IID_IUnknown.DataX[2] := $000000C0;
    IID_IUnknown.DataX[3] := $46000000;
    // GUID_CONSOLE_DISPLAY_STATE : 6FE69556-704A-47A0-8F24-C28D936FDA47
    GUID_CONSOLE_DISPLAY_STATE.DataX[0] := $6FE69556;
    GUID_CONSOLE_DISPLAY_STATE.DataX[1] := $47A0704A;
    GUID_CONSOLE_DISPLAY_STATE.DataX[2] := $8DC2248F;
    GUID_CONSOLE_DISPLAY_STATE.DataX[3] := $47DA6F93;
{$IFDEF ITASKBARLIST3}
    // CLSID_TaskbarList : 56FDF344-FD6D-11D0-958A-006097C9A090
    CLSID_TaskbarList.DataX[0] := $56FDF344;
    CLSID_TaskbarList.DataX[1] := $11D0FD6D;
    CLSID_TaskbarList.DataX[2] := $60008A95;
    CLSID_TaskbarList.DataX[3] := $90A0C997;
    // IID_ITaskbarList3 : EA1AFB91-9A28-4B86-90E9-9E9F8A5EEFAF
    IID_ITaskbarList3.DataX[0] := $EA1AFB91;
    IID_ITaskbarList3.DataX[1] := $4B869A28;
    IID_ITaskbarList3.DataX[2] := $9F9EE990;
    IID_ITaskbarList3.DataX[3] := $AFEF5E8A;
{$ENDIF}
    Status.hPowerNotify := NULL;
    Status.hSuspendNotify := NULL;
    // USER32.DLL をロード
    dwBuffer := API_LoadLibraryEx(pchar('user32.dll'), NULL, LOAD_LIBRARY_SEARCH_SYSTEM32);
    if longbool(dwBuffer) then begin
        // ディスプレイの電源状態イベントを拾えるように設定 (for Windows 8, 8.1, 10, 11)
        @API_RegisterPowerSettingNotification := API_GetProcAddress(dwBuffer, pchar('RegisterPowerSettingNotification'));
        if longbool(@API_RegisterPowerSettingNotification) then begin
            Status.hPowerNotify := API_RegisterPowerSettingNotification(hWndApp, @GUID_CONSOLE_DISPLAY_STATE, DEVICE_NOTIFY_WINDOW_HANDLE);
        end;
        // S0 (省電力) スリープのイベントを拾えるように設定 (for Windows 8, 8.1, 10, 11)
        @API_RegisterSuspendResumeNotification := API_GetProcAddress(dwBuffer, pchar('RegisterSuspendResumeNotification'));
        if longbool(@API_RegisterSuspendResumeNotification) then begin
            Status.hSuspendNotify := API_RegisterSuspendResumeNotification(hWndApp, DEVICE_NOTIFY_WINDOW_HANDLE);
        end;
{$IFDEF UACDROP}
        // 権限が低いアプリケーションからのドロップを有効に設定 (for Windows Vista, 7)
        @API_ChangeWindowMessageFilter := API_GetProcAddress(dwBuffer, pchar('ChangeWindowMessageFilter'));
        if longbool(@API_ChangeWindowMessageFilter) then begin
            API_ChangeWindowMessageFilter(WM_DROPFILES, MSGFLT_ADD);
            API_ChangeWindowMessageFilter(WM_COPYDATA, MSGFLT_ADD);
            API_ChangeWindowMessageFilter(WM_COPYGLOBALDATA, MSGFLT_ADD);
        end;
{$ENDIF}
        // DLL を解放
        API_FreeLibrary(dwBuffer);
    end;
    // システムのバージョン情報を取得
    Status.OsVersionInfo.dwOSVersionInfoSize := SizeOf(TOSVERSIONINFO);
    API_GetVersionEx(@Status.OsVersionInfo);
    // NTDLL.DLL をロード
    dwBuffer := API_LoadLibraryEx(pchar('ntdll.dll'), NULL, LOAD_LIBRARY_SEARCH_SYSTEM32);
    if longbool(dwBuffer) then begin
        // システムのバージョン情報を取得
        @API_RtlGetVersion := API_GetProcAddress(dwBuffer, pchar('RtlGetVersion'));
        if longbool(@API_RtlGetVersion) then API_RtlGetVersion(@Status.OsVersionInfo);
        // DLL を解放
        API_FreeLibrary(dwBuffer);
    end;
{$IFDEF ITASKBARLIST3}
    // COM インターフェイスを初期化
    API_CoInitialize(NULLPOINTER);
    // タスクバーのボタンを制御するインターフェースを読み込み
    API_CoCreateInstance(@CLSID_TaskbarList, NULLPOINTER, CLSCTX_INPROC_SERVER, @IID_ITaskbarList3, @Status.ITaskbarList3);
{$ENDIF}
    // バッファを設定
    SetLength(cBuffer, 32);
    // データを格納するポインタを取得
    API_ZeroMemory(@cBuffer[0], 32);
    Apu.GetScript700Data(@cBuffer[0], @Apu.SPC700Reg, @Status.Script700.Data);
    // バージョン情報を作成
    sInfo := Concat(SPCPLAY_TITLE, SPCPLAY_VERSION,
{$IFNDEF SIGNATURE}
        #32#42, // 非公式マーク
{$ENDIF}
        CRLF, CRLF, SNESAPU_TITLE, Copy(
{$IFDEF FREEPASCAL}
        ChrToStr(cBuffer),
{$ELSE}
        // NOTE: Boland Delphi の場合、char の動的配列を string にキャストする場合は、
        // 直接 string() を使用する
        string(cBuffer),
{$ENDIF}
        1, GetSize(@cBuffer[0], 32)));
    if K <> SNESAPU_VERSION then sInfo := Concat(sInfo, #32#42); // バージョン不一致マーク
    // ブラシを作成
    if Option.dwTheme = THEME_DARK then begin
        Status.hBackBrush := API_CreateSolidBrush(COLOR_DARK_BACK);
        Status.hTextBrush := API_CreateSolidBrush(COLOR_DARK_TEXT);
        Status.hMenuBrush := API_CreateSolidBrush(COLOR_DARK_MENU);
        // 背景ブラシを変更
        API_SetClassLong(hWndApp, GCL_HBRBACKGROUND, Status.hBackBrush);
    end else begin
        Status.hBackBrush := ORG_COLOR_BTNFACE;
        Status.hTextBrush := ORG_COLOR_WINDOWTEXT;
    end;
    // 配列のサイズを初期化
    SetLength(Wave.lpData, Option.dwBufferNum);
    SetLength(Wave.Header, Option.dwBufferNum);
    SetLength(Wave.Apu, Option.dwBufferNum);
    SetLength(Status.SPCCache, Option.dwCacheNum);
    // ファイルメニューを作成
    cmFile := CMENU.Create();
    cmFile.CreatePopupMenu();
    for I := 0 to MENU_FILE_OPEN_SIZE - 1 do cmFile.AppendMenu(MENU_FILE_OPEN_BASE + I, STR_MENU_FILE_OPEN_SUB[Status.dwLanguage][I]);
    cmFile.AppendSeparator();
    for I := 0 to MENU_FILE_PLAY_SIZE - 1 do cmFile.AppendMenu(MENU_FILE_PLAY_BASE + I, STR_MENU_FILE_PLAY_SUB[Status.dwLanguage][I]);
    cmFile.AppendSeparator();
    cmFile.AppendMenu(MENU_FILE_EXIT, STR_MENU_FILE_EXIT[Status.dwLanguage]);
    // デバイスメニューを作成
    cmSetupDevice := CMENU.Create();
    cmSetupDevice.CreatePopupMenu();
    Status.dwDeviceNum := 0;
    UpdateDevice(Option.dwDeviceID, WAVE_DEVICE_INITIALIZE);
    // チャンネルメニューを作成
    SetMenuTextAndTip(cmSetupChannel, MENU_SETUP_CHANNEL_SIZE, MENU_SETUP_CHANNEL_BASE, STR_MENU_SETUP_CHANNEL_SUB[Status.dwLanguage], true);
    // ビットメニューを作成
    SetMenuTextAndTip(cmSetupBit, MENU_SETUP_BIT_SIZE, MENU_SETUP_BIT_BASE, STR_MENU_SETUP_BIT_SUB[Status.dwLanguage], true);
    // サンプリングレートメニューを作成
    SetMenuTextAndTip(cmSetupRate, MENU_SETUP_RATE_SIZE, MENU_SETUP_RATE_BASE, STR_MENU_SETUP_RATE_SUB[Status.dwLanguage], true);
    // 補間処理メニューを作成
    SetMenuTextAndTip(cmSetupInter, MENU_SETUP_INTER_SIZE, MENU_SETUP_INTER_BASE, STR_MENU_SETUP_INTER_SUB[Status.dwLanguage], true);
    // ピッチキーメニューを作成
    cmSetupPitchKey := CMENU.Create();
    cmSetupPitchKey.CreatePopupMenu();
    for I := 0 to MENU_SETUP_PITCH_KEY_SIZE - 1 do cmSetupPitchKey.AppendMenu(MENU_SETUP_PITCH_KEY_BASE + I,
        pchar(Concat(STR_MENU_SETUP_PITCH_PLUS[Status.dwLanguage], IntToStr(MENU_SETUP_PITCH_KEY_SIZE - I))), true);
    cmSetupPitchKey.AppendMenu(MENU_SETUP_PITCH_KEY_BASE + MENU_SETUP_PITCH_KEY_SIZE, STR_MENU_SETUP_PITCH_ZERO, true);
    for I := 0 to MENU_SETUP_PITCH_KEY_SIZE - 1 do cmSetupPitchKey.AppendMenu(MENU_SETUP_PITCH_KEY_BASE + MENU_SETUP_PITCH_KEY_SIZE + I + 1,
        pchar(Concat(STR_MENU_SETUP_PITCH_MINUS[Status.dwLanguage], char($31 + I))), true);
    // ピッチメニューを作成
    SetMenuTextAndTip(cmSetupPitch, MENU_SETUP_PITCH_SIZE, MENU_SETUP_PITCH_BASE, STR_MENU_SETUP_PITCH_SUB[Status.dwLanguage], true);
    cmSetupPitch.AppendSeparator();
    cmSetupPitch.AppendMenu(MENU_SETUP_PITCH_KEY, STR_MENU_SETUP_PITCH_KEY[Status.dwLanguage], cmSetupPitchKey.hMenu);
    cmSetupPitch.AppendMenu(MENU_SETUP_PITCH_ASYNC, STR_MENU_SETUP_PITCH_ASYNC[Status.dwLanguage]);
    // 左右拡散度メニューを作成
    SetMenuTextAndTip(cmSetupSeparate, MENU_SETUP_SEPARATE_SIZE, MENU_SETUP_SEPARATE_BASE, STR_MENU_SETUP_SEPARATE_PER_INDEX,
        STR_MENU_SETUP_SEPARATE_TIP_INDEX);
    // フィードバック反転度メニューを作成
    SetMenuTextAndTip(cmSetupFeedback, MENU_SETUP_FEEDBACK_SIZE, MENU_SETUP_FEEDBACK_BASE, STR_MENU_SETUP_FEEDBACK_PER_INDEX,
        STR_MENU_SETUP_FEEDBACK_TIP_INDEX);
    // 演奏速度メニューを作成
    SetMenuTextAndTip(cmSetupSpeed, MENU_SETUP_SPEED_SIZE, MENU_SETUP_SPEED_BASE, STR_MENU_SETUP_SPEED_PER_INDEX, STR_MENU_SETUP_SPEED_TIP_INDEX);
    // 音量メニューを作成
    SetMenuTextAndTip(cmSetupAmp, MENU_SETUP_AMP_SIZE, MENU_SETUP_AMP_BASE, STR_MENU_SETUP_AMP_PER_INDEX, STR_MENU_SETUP_AMP_TIP_INDEX);
    // チャンネルマスクメニューを作成
    cmSetupMute := CMENU.Create();
    cmSetupMute.CreatePopupMenu();
    for I := 0 to MENU_SETUP_MUTE_NOISE_ALL_SIZE - 1 do
        cmSetupMute.AppendMenu(MENU_SETUP_MUTE_ALL_BASE + I, STR_MENU_SETUP_MUTE_NOISE_ALL_SUB[Status.dwLanguage][I]);
    cmSetupMute.AppendSeparator();
    for I := 0 to MENU_SETUP_MUTE_NOISE_SIZE - 1 do
        cmSetupMute.AppendMenu(MENU_SETUP_MUTE_BASE + I, pchar(Concat(STR_MENU_SETUP_SWITCH_CHANNEL[Status.dwLanguage], '&', string(char($31 + I)))));
    // チャンネルノイズメニューを作成
    cmSetupNoise := CMENU.Create();
    cmSetupNoise.CreatePopupMenu();
    for I := 0 to MENU_SETUP_MUTE_NOISE_ALL_SIZE - 1 do
        cmSetupNoise.AppendMenu(MENU_SETUP_NOISE_ALL_BASE + I, STR_MENU_SETUP_MUTE_NOISE_ALL_SUB[Status.dwLanguage][I]);
    cmSetupNoise.AppendSeparator();
    for I := 0 to MENU_SETUP_MUTE_NOISE_SIZE - 1 do
        cmSetupNoise.AppendMenu(MENU_SETUP_NOISE_BASE + I, pchar(Concat(STR_MENU_SETUP_SWITCH_CHANNEL[Status.dwLanguage], '&', string(char($31 + I)))));
    // 拡張設定メニューを作成
    SetMenuTextAndTip(cmSetupOption, MENU_SETUP_OPTION_SIZE, MENU_SETUP_OPTION_BASE, STR_MENU_SETUP_OPTION_SUB[Status.dwLanguage], false);
    // 演奏時間メニューを作成
    cmSetupTime := CMENU.Create();
    cmSetupTime.CreatePopupMenu();
    cmSetupTime.AppendMenu(MENU_SETUP_TIME_DISABLE, STR_MENU_SETUP_TIME_DISABLE[Status.dwLanguage], true);
    cmSetupTime.AppendMenu(MENU_SETUP_TIME_ID666, STR_MENU_SETUP_TIME_ID666[Status.dwLanguage], true);
    cmSetupTime.AppendMenu(MENU_SETUP_TIME_DEFAULT, STR_MENU_SETUP_TIME_DEFAULT[Status.dwLanguage], true);
    cmSetupTime.AppendSeparator();
    cmSetupTime.AppendMenu(MENU_SETUP_TIME_START, STR_MENU_SETUP_TIME_START[Status.dwLanguage]);
    cmSetupTime.AppendMenu(MENU_SETUP_TIME_LIMIT, STR_MENU_SETUP_TIME_LIMIT[Status.dwLanguage]);
    cmSetupTime.AppendSeparator();
    cmSetupTime.AppendMenu(MENU_SETUP_TIME_RESET, STR_MENU_SETUP_TIME_RESET[Status.dwLanguage]);
    // 演奏順序メニューを作成
    SetMenuTextAndTip(cmSetupOrder, MENU_SETUP_ORDER_SIZE, MENU_SETUP_ORDER_BASE, STR_MENU_SETUP_ORDER_SUB[Status.dwLanguage], true);
    // シーク時間メニューを作成
    SetMenuTextAndTip(cmSetupSeek, MENU_SETUP_SEEK_SIZE, MENU_SETUP_SEEK_BASE, STR_MENU_SETUP_SEEK_SUB[Status.dwLanguage], true);
    cmSetupSeek.AppendSeparator();
    cmSetupSeek.AppendMenu(MENU_SETUP_SEEK_FAST, STR_MENU_SETUP_SEEK_FAST[Status.dwLanguage]);
    cmSetupSeek.AppendMenu(MENU_SETUP_SEEK_ASYNC, STR_MENU_SETUP_SEEK_ASYNC[Status.dwLanguage]);
    // 情報表示メニューを作成
    SetMenuTextAndTip(cmSetupInfo, MENU_SETUP_INFO_SIZE, MENU_SETUP_INFO_BASE, STR_MENU_SETUP_INFO_SUB[Status.dwLanguage], true);
    cmSetupInfo.AppendSeparator();
    cmSetupInfo.AppendMenu(MENU_SETUP_INFO_RESET, STR_MENU_SETUP_INFO_RESET[Status.dwLanguage]);
    // 基本優先度メニューを作成
    SetMenuTextAndTip(cmSetupPriority, MENU_SETUP_PRIORITY_SIZE, MENU_SETUP_PRIORITY_BASE, STR_MENU_SETUP_PRIORITY_SUB[Status.dwLanguage], true);
    // その他設定メニューを作成
    cmSetupOthers := CMENU.Create();
    cmSetupOthers.CreatePopupMenu();
    cmSetupOthers.AppendMenu(MENU_SETUP_TOPMOST, STR_MENU_SETUP_TOPMOST[Status.dwLanguage]);
    cmSetupOthers.AppendMenu(MENU_SETUP_NOSLEEP, STR_MENU_SETUP_NOSLEEP[Status.dwLanguage]);
    // 設定メニューを作成
    cmSetup := CMENU.Create();
    cmSetup.CreatePopupMenu();
    cmSetup.AppendMenu(MENU_SETUP_DEVICE, STR_MENU_SETUP_DEVICE[Status.dwLanguage], cmSetupDevice.hMenu);
    cmSetup.AppendMenu(MENU_SETUP_CHANNEL, STR_MENU_SETUP_CHANNEL[Status.dwLanguage], cmSetupChannel.hMenu);
    cmSetup.AppendMenu(MENU_SETUP_BIT, STR_MENU_SETUP_BIT[Status.dwLanguage], cmSetupBit.hMenu);
    cmSetup.AppendMenu(MENU_SETUP_RATE, STR_MENU_SETUP_RATE[Status.dwLanguage], cmSetupRate.hMenu);
    cmSetup.AppendSeparator();
    cmSetup.AppendMenu(MENU_SETUP_INTER, STR_MENU_SETUP_INTER[Status.dwLanguage], cmSetupInter.hMenu);
    cmSetup.AppendMenu(MENU_SETUP_PITCH, STR_MENU_SETUP_PITCH[Status.dwLanguage], cmSetupPitch.hMenu);
    cmSetup.AppendMenu(MENU_SETUP_SEPARATE, STR_MENU_SETUP_SEPARATE[Status.dwLanguage], cmSetupSeparate.hMenu);
    cmSetup.AppendMenu(MENU_SETUP_FEEDBACK, STR_MENU_SETUP_FEEDBACK[Status.dwLanguage], cmSetupFeedback.hMenu);
    cmSetup.AppendMenu(MENU_SETUP_SPEED, STR_MENU_SETUP_SPEED[Status.dwLanguage], cmSetupSpeed.hMenu);
    cmSetup.AppendMenu(MENU_SETUP_AMP, STR_MENU_SETUP_AMP[Status.dwLanguage], cmSetupAmp.hMenu);
    cmSetup.AppendMenu(MENU_SETUP_MUTE, STR_MENU_SETUP_MUTE[Status.dwLanguage], cmSetupMute.hMenu);
    cmSetup.AppendMenu(MENU_SETUP_NOISE, STR_MENU_SETUP_NOISE[Status.dwLanguage], cmSetupNoise.hMenu);
    cmSetup.AppendMenu(MENU_SETUP_OPTION, STR_MENU_SETUP_OPTION[Status.dwLanguage], cmSetupOption.hMenu);
    cmSetup.AppendSeparator();
    cmSetup.AppendMenu(MENU_SETUP_TIME, STR_MENU_SETUP_TIME[Status.dwLanguage], cmSetupTime.hMenu);
    cmSetup.AppendMenu(MENU_SETUP_ORDER, STR_MENU_SETUP_ORDER[Status.dwLanguage], cmSetupOrder.hMenu);
    cmSetup.AppendMenu(MENU_SETUP_SEEK, STR_MENU_SETUP_SEEK[Status.dwLanguage], cmSetupSeek.hMenu);
    cmSetup.AppendMenu(MENU_SETUP_INFO, STR_MENU_SETUP_INFO[Status.dwLanguage], cmSetupInfo.hMenu);
    cmSetup.AppendMenu(MENU_SETUP_PRIORITY, STR_MENU_SETUP_PRIORITY[Status.dwLanguage], cmSetupPriority.hMenu);
    cmSetup.AppendMenu(MENU_SETUP_OTHERS, STR_MENU_SETUP_OTHERS[Status.dwLanguage], cmSetupOthers.hMenu);
    // 演奏開始メニューを作成
    cmListPlay := CMENU.Create();
    cmListPlay.CreatePopupMenu();
    cmListPlay.AppendMenu(MENU_LIST_PLAY_SELECT, STR_MENU_LIST_PLAY_SELECT[Status.dwLanguage]);
    cmListPlay.AppendSeparator();
    for I := 0 to MENU_LIST_PLAY_SIZE - 1 do cmListPlay.AppendMenu(MENU_LIST_PLAY_BASE + I, STR_MENU_LIST_PLAY_SUB[Status.dwLanguage][I], true);
    // プレイリストメニューを作成
    cmList := CMENU.Create();
    cmList.CreatePopupMenu();
    cmList.AppendMenu(MENU_LIST_PLAY, STR_MENU_LIST_PLAY[Status.dwLanguage], cmListPlay.hMenu);
    cmList.AppendSeparator();
    for I := 0 to MENU_LIST_EDIT_SIZE - 1 do cmList.AppendMenu(MENU_LIST_EDIT_BASE + I, STR_MENU_LIST_EDIT_SUB[Status.dwLanguage][I]);
    cmList.AppendSeparator();
    for I := 0 to MENU_LIST_MOVE_SIZE - 1 do cmList.AppendMenu(MENU_LIST_MOVE_BASE + I, STR_MENU_LIST_MOVE_SUB[Status.dwLanguage][I]);
    // システムメニューを作成
    cmSystem := cwWindowMain.GetSystemMenu();
    cmSystem.RemoveItem(SC_MAXIMIZE);
    cmSystem.RemoveItem(SC_SIZE);
    cmSystem.InsertMenu(MENU_FILE, SC_CLOSE, STR_MENU_FILE[Status.dwLanguage], cmFile.hMenu);
    cmSystem.InsertMenu(MENU_SETUP, SC_CLOSE, STR_MENU_SETUP[Status.dwLanguage], cmSetup.hMenu);
    cmSystem.InsertMenu(MENU_LIST, SC_CLOSE, STR_MENU_LIST[Status.dwLanguage], cmList.hMenu);
    cmSystem.InsertSeparator(SC_CLOSE);
    // ウィンドウメニューを作成
    cmMain := CMENUBAR.Create();
    cmMain.CreateMenu();
    cmMain.AppendMenu(MENU_FILE, STR_MENU_FILE[Status.dwLanguage], cmFile.hMenu);
    cmMain.AppendMenu(MENU_SETUP, STR_MENU_SETUP[Status.dwLanguage], cmSetup.hMenu);
    cmMain.AppendMenu(MENU_LIST, STR_MENU_LIST[Status.dwLanguage], cmList.hMenu);
    API_SetMenu(hWndApp, cmMain.hMenu);
    // フォントを作成
    cfMain := CFONT.Create();
    Box := ScalableWindowBox(0, 0, 6, 12);
    if Length(Option.sFontName) > 0 then sFontName := Option.sFontName
    else sFontName := FONT_NAME[Status.dwLanguage];
    cfMain.CreateFont(pchar(sFontName), Box.height, Box.width, false, false, false, false);
    // プレイリスト、ボタンを作成
    hFontApp := cfMain.hFont;
    lpString := pchar(ITEM_BUTTON);
    lpBuffer := pchar(ITEM_LISTBOX);
    cwFileList := CWINDOW.Create();
    cwFileList.CreateItem(hThisInstance, hWndApp, hFontApp, lpBuffer, pchar(''),
        ID_LIST_FILE, LBS_NOREDRAW, NULL, ScalableWindowBox(0, 210, 220, 130));
    cwSortList := CWINDOW.Create();
    cwSortList.CreateItem(hThisInstance, hWndApp, hFontApp, lpBuffer, pchar(''),
        ID_LIST_SORT, LBS_NOREDRAW or LBS_SORT, NULL, ScalableWindowBox(0, 210, 220, 130));
    cwTempList := CWINDOW.Create();
    cwTempList.CreateItem(hThisInstance, hWndApp, hFontApp, lpBuffer, pchar(''),
        ID_LIST_TEMP, LBS_NOREDRAW, NULL, ScalableWindowBox(0, 210, 220, 130));
    cwButtonOpen := CBUTTON.Create();
    cwButtonOpen.CreateItem(hThisInstance, hWndApp, hFontApp, lpString, pchar(STR_BUTTON_OPEN),
        ID_BUTTON_OPEN, WS_TABSTOP or WS_VISIBLE, ScalableWindowBox(5, 103, 55, 21));
    cwButtonSave := CBUTTON.Create();
    cwButtonSave.CreateItem(hThisInstance, hWndApp, hFontApp, lpString, pchar(STR_BUTTON_SAVE),
        ID_BUTTON_SAVE, WS_TABSTOP or WS_VISIBLE, ScalableWindowBox(62, 103, 55, 21));
    cwButtonPlay := CBUTTON.Create();
    cwButtonPlay.CreateItem(hThisInstance, hWndApp, hFontApp, lpString, pchar(STR_BUTTON_PLAY),
        ID_BUTTON_PLAY, WS_TABSTOP or WS_VISIBLE, ScalableWindowBox(126, 103, 54, 21));
    cwButtonRestart := CBUTTON.Create();
    cwButtonRestart.CreateItem(hThisInstance, hWndApp, hFontApp, lpString, pchar(STR_BUTTON_RESTART),
        ID_BUTTON_RESTART, WS_TABSTOP or WS_VISIBLE, ScalableWindowBox(182, 103, 54, 21));
    cwButtonStop := CBUTTON.Create();
    cwButtonStop.CreateItem(hThisInstance, hWndApp, hFontApp, lpString, pchar(STR_BUTTON_STOP),
        ID_BUTTON_STOP, WS_TABSTOP or WS_VISIBLE, ScalableWindowBox(238, 103, 54, 21));
    sBuffer := ' ';
    K := 5;
    for I := 0 to 7 do begin
        sBuffer[1] := char($31 + I);
        cwCheckTrack[I] := CBUTTON.Create();
        cwCheckTrack[I].CreateItem(hThisInstance, hWndApp, hFontApp, lpString, pchar(sBuffer),
            ID_BUTTON_TRACK[I], BS_AUTOCHECKBOX or BS_PUSHLIKE or WS_TABSTOP or WS_VISIBLE, ScalableWindowBox(K, 127, 14, 21));
        Inc(K, 14);
    end;
    cwButtonVolM := CBUTTON.Create();
    cwButtonVolM.CreateItem(hThisInstance, hWndApp, hFontApp, lpString, pchar(STR_BUTTON_AMPD),
        ID_BUTTON_AMPD, WS_TABSTOP or WS_VISIBLE, ScalableWindowBox(126, 127, 26, 21));
    cwButtonVolP := CBUTTON.Create();
    cwButtonVolP.CreateItem(hThisInstance, hWndApp, hFontApp, lpString, pchar(STR_BUTTON_AMPU),
        ID_BUTTON_AMPU, WS_TABSTOP or WS_VISIBLE, ScalableWindowBox(154, 127, 26, 21));
    cwButtonSlow := CBUTTON.Create();
    cwButtonSlow.CreateItem(hThisInstance, hWndApp, hFontApp, lpString, pchar(STR_BUTTON_SLOW),
        ID_BUTTON_SLOW, WS_TABSTOP or WS_VISIBLE, ScalableWindowBox(182, 127, 26, 21));
    cwButtonFast := CBUTTON.Create();
    cwButtonFast.CreateItem(hThisInstance, hWndApp, hFontApp, lpString, pchar(STR_BUTTON_FAST),
        ID_BUTTON_FAST, WS_TABSTOP or WS_VISIBLE, ScalableWindowBox(210, 127, 26, 21));
    cwButtonBack := CBUTTON.Create();
    cwButtonBack.CreateItem(hThisInstance, hWndApp, hFontApp, lpString, pchar(STR_BUTTON_BACK),
        ID_BUTTON_BACK, WS_TABSTOP or WS_VISIBLE, ScalableWindowBox(238, 127, 26, 21));
    cwButtonNext := CBUTTON.Create();
    cwButtonNext.CreateItem(hThisInstance, hWndApp, hFontApp, lpString, pchar(STR_BUTTON_NEXT),
        ID_BUTTON_NEXT, WS_TABSTOP or WS_VISIBLE, ScalableWindowBox(266, 127, 26, 21));
    cwPlayList := CWINDOW.Create();
    if Option.dwTheme = THEME_DARK then begin
        cwPlayList.CreateItem(hThisInstance, hWndApp, hFontApp, lpBuffer, pchar(''),
            ID_LIST_PLAY, LBS_DISABLENOSCROLL or LBS_NOTIFY or WS_TABSTOP or WS_VISIBLE or WS_VSCROLL, WS_EX_STATICEDGE or WS_EX_NOPARENTNOTIFY,
            ScalableWindowBox(301, 0, 215, 124));
        ScalableWindowBox(301, 0, 215, Option.dwListHeight);
        Box.top := (Status.dwScale - 2) shl 1 + 2;
    end else begin
        cwPlayList.CreateItem(hThisInstance, hWndApp, hFontApp, lpBuffer, pchar(''),
            ID_LIST_PLAY, LBS_DISABLENOSCROLL or LBS_NOTIFY or WS_TABSTOP or WS_VISIBLE or WS_VSCROLL, WS_EX_CLIENTEDGE or WS_EX_NOPARENTNOTIFY,
            ScalableWindowBox(301, 0, 215, 124));
        ScalableWindowBox(301, 0, 215, Option.dwListHeight);
        Box.top := (Status.dwScale - 2) shl 1;
    end;
    API_MoveWindow(cwPlayList.hWnd, Box.left, Box.top, Box.width, Box.height, false); // プレイリストが小さくなるバグ回避
    cwButtonListAdd := CBUTTON.Create();
    cwButtonListAdd.CreateItem(hThisInstance, hWndApp, hFontApp, lpString, pchar(STR_BUTTON_APPEND),
        ID_BUTTON_ADD, WS_TABSTOP or WS_VISIBLE, ScalableWindowBox(301, 127, 54, 21));
    cwButtonListRemove := CBUTTON.Create();
    cwButtonListRemove.CreateItem(hThisInstance, hWndApp, hFontApp, lpString, pchar(STR_BUTTON_REMOVE),
        ID_BUTTON_REMOVE, WS_TABSTOP or WS_VISIBLE, ScalableWindowBox(357, 127, 54, 21));
    cwButtonListClear := CBUTTON.Create();
    cwButtonListClear.CreateItem(hThisInstance, hWndApp, hFontApp, lpString, pchar(STR_BUTTON_CLEAR),
        ID_BUTTON_CLEAR, WS_TABSTOP or WS_VISIBLE, ScalableWindowBox(413, 127, 54, 21));
    cwButtonListUp := CBUTTON.Create();
    cwButtonListUp.CreateItem(hThisInstance, hWndApp, hFontApp, lpString, pchar(STR_BUTTON_UP[Status.dwLanguage]),
        ID_BUTTON_UP, WS_TABSTOP or WS_VISIBLE, ScalableWindowBox(472, 127, 21, 21));
    cwButtonListDown := CBUTTON.Create();
    cwButtonListDown.CreateItem(hThisInstance, hWndApp, hFontApp, lpString, pchar(STR_BUTTON_DOWN[Status.dwLanguage]),
        ID_BUTTON_DOWN, WS_TABSTOP or WS_VISIBLE, ScalableWindowBox(495, 127, 21, 21));
    // Static を作成
    lpBuffer := pchar(ITEM_STATIC);
    cwStaticFile := CWINDOW.Create();
    cwStaticFile.CreateItem(hThisInstance, hWndApp, hFontApp, lpBuffer, pchar(FILE_DEFAULT),
        ID_STATIC_FILE, SS_NOPREFIX, WS_EX_NOPARENTNOTIFY, ScalableWindowBox(0, 0, 0, 0));
    cwStaticMain := CWINDOW.Create();
    cwStaticMain.CreateItem(hThisInstance, hWndApp, hFontApp, lpBuffer, pchar(sInfo),
        ID_STATIC_MAIN, SS_LEFTNOWORDWRAP or SS_NOPREFIX or SS_NOTIFY or WS_VISIBLE, WS_EX_NOPARENTNOTIFY, ScalableWindowBox(5, 2, 287, 96));
    // Static のウィンドウプロシージャを取得
    Status.lpStaticProc := pointer(API_SetWindowLong(cwStaticMain.hWnd, GWL_WNDPROC, longword(@_StaticProc)));
    // デバイスコンテキストを取得
    Status.hDCWindow := API_GetWindowDC(cwWindowMain.hWnd);
    Status.hDCStatic := API_GetDC(cwStaticMain.hWnd);
    // インジケータ表示用のデバイスコンテキストを作成
    Status.hDCVolumeBuffer := API_CreateCompatibleDC(Status.hDCStatic);
    Status.hBitmapVolume := API_SelectObject(Status.hDCVolumeBuffer, API_CreateCompatibleBitmap(Status.hDCStatic, COLOR_BAR_NUM_X7, COLOR_BAR_HEIGHT));
    // 文字表示用のデバイスコンテキストを作成
    Status.hDCStringBuffer := API_CreateCompatibleDC(Status.hDCStatic);
    Status.hBitmapString := API_SelectObject(Status.hDCStringBuffer, API_CreateCompatibleBitmap(Status.hDCStatic, BITMAP_NUM_X6P6, BITMAP_NUM_HEIGHT));
    // グラフィックリソースを設定
    SetGraphic();
    // デバイスを初期化
    WaveInit();
    // プレイリストファイルをロード
    lpBuffer := pchar(Concat(sChPath, LIST_FILE));
    dwBuffer := GetFileType(lpBuffer, false, false);
    case dwBuffer of
        FILE_TYPE_LIST_A, FILE_TYPE_LIST_B: ListLoad(lpBuffer, dwBuffer, true);
    end;
    // メニューを更新
    UpdateMenu();
    // プロセス優先度を設定
    API_SetPriorityClass(API_GetCurrentProcess(), Option.dwPriority);
    // スレッドを作成
    Status.dwThreadStatus := WAVE_THREAD_SUSPEND;
    Status.dwThreadHandle := API_CreateThread(NULLPOINTER, NULL, @_WaveThread, NULLPOINTER, NULL, @Status.dwThreadID);
    // ウィンドウ位置を設定
    cwWindowMain.SetWindowPosition(dwLeft, dwTop, 1024, 1024);
    // ウィンドウをリサイズ
    ResizeWindow();
    // フォーカスを設定
    SetTabFocus(hWndApp, true);
    // スレッドの準備が完了するまで待機
    while not longbool(Status.dwThreadStatus) do API_Sleep(16);
    // コマンドラインを処理
    if longbool(Length(sCmdLine)) then begin
        // バッファを確保
        GetMem(lpBuffer, 1024);
        // バッファにコピー
        API_ZeroMemory(lpBuffer, 1024);
        lpString := pchar(sCmdLine);
        API_MoveMemory(lpBuffer, lpString, Length(sCmdLine));
        // ファイルを開く
        dwBuffer := GetFileType(lpBuffer, true, false);
        case dwBuffer of
            FILE_TYPE_SPC: SPCLoad(lpBuffer, true);
            FILE_TYPE_LIST_A, FILE_TYPE_LIST_B: ListLoad(lpBuffer, dwBuffer, false);
        end;
        // バッファを解放
        FreeMem(lpBuffer, 1024);
    end;
    // フラグを設定
    Status.dwTitle := Status.dwTitle or TITLE_NORMAL;
    cwWindowMain.SendMessage(WM_SIZE, $FFFFFFFF, NULL);
{$IFDEF SPCDEBUG}
    Apu.SetSPCDbg(@_SPCDebug, $11); // SPC_TRACE | SPC_RETURN
    Apu.SetDSPDbg(@_DSPDebug);
{$ENDIF}
    // ダークモードの場合
    if Option.dwTheme = THEME_DARK then begin
        // DWMAPI.DLL をロード
        dwBuffer := API_LoadLibraryEx(pchar('dwmapi.dll'), NULL, LOAD_LIBRARY_SEARCH_SYSTEM32);
        if longbool(dwBuffer) then begin
            // タイトルバーのダークモードを有効化
            @API_DwmSetWindowAttribute := API_GetProcAddress(dwBuffer, pchar('DwmSetWindowAttribute'));
            I := -1; // TRUE: ダークモード
            if longbool(@API_DwmSetWindowAttribute) then API_DwmSetWindowAttribute(hWndApp, 20, @I, 4); // DWMWA_USE_IMMERSIVE_DARK_MODE
            // DLL を解放
            API_FreeLibrary(dwBuffer);
        end;
        // UXTHEME.DLL をロード
        dwBuffer := API_LoadLibraryEx(pchar('uxtheme.dll'), NULL, LOAD_LIBRARY_SEARCH_SYSTEM32);
        if longbool(dwBuffer) then begin
            // ウィンドウとメニューのダークモードを有効化
            @API_SetPreferredAppMode := API_GetProcAddress(dwBuffer, pointer(longword(135)));
            if longbool(@API_SetPreferredAppMode) then begin
                API_SetPreferredAppMode(0); // 一度デフォルトモードに戻す
                API_SetPreferredAppMode(2); // ダークモード
            end;
            // メニューテーマを更新
            @API_FlushMenuThemes := API_GetProcAddress(dwBuffer, pointer(longword(136)));
            if longbool(@API_FlushMenuThemes) then API_FlushMenuThemes();
            // プレイリストのダークモードを有効化
            @API_SetWindowTheme := API_GetProcAddress(dwBuffer, pchar('SetWindowTheme'));
            wsData := 'DarkMode_Explorer';
            if longbool(@API_SetWindowTheme) then API_SetWindowTheme(cwPlayList.hWnd, pwidechar(wsData), NULLPOINTER);
            // DLL を解放
            API_FreeLibrary(dwBuffer);
        end;
    end;
    // 準備完了
    API_SetTimer(hWndApp, TIMER_ID_READY, TIMER_INTERVAL_READY, NULLPOINTER);
end;

// ================================================================================
// DeleteWindow - ウィンドウ削除
// ================================================================================
procedure CWINDOWMAIN.DeleteWindow();
var
    I: longint;
    dwBuffer: longword;
    sChPath: string;
    fsFile: textfile;
    NormalRect: TRECT;
    ScreenRect: TRECT;
    API_UnregisterPowerSettingNotification: function(handle: longword): longbool; stdcall;
    API_UnregisterSuspendResumeNotification: function(handle: longword): longbool; stdcall;

function GetBoolToInt(bValue: longbool): string;
begin
    if bValue then result := '1' else result := '0';
end;

begin
    // プロセス優先度を標準に変更
    API_SetPriorityClass(API_GetCurrentProcess(), NORMAL_PRIORITY_CLASS);
    // デバイスを解放
    WaveQuit();
    // スレッドに終了を通知
    API_PostThreadMessage(Status.dwThreadID, WM_QUIT, NULL, NULL);
    // 通常状態のウィンドウサイズを取得
    cwWindowMain.GetWindowRect(@NormalRect);
    // スクリーンサイズを取得
    API_SystemParametersInfo(SPI_GETWORKAREA, NULL, @ScreenRect, NULL);
    // カレントパスを取得
    sChPath := Copy(PtrToStr(Status.lpCurrentPath), 1, Status.lpCurrentSize);
    // リピート開始位置、リピート終了位置が設定済みの場合は、本来の演奏順序に戻す
    if Status.bTimeRepeat then Option.dwPlayOrder := Status.dwPlayOrder;
    // INI ファイルを作成
    AssignFile(fsFile, Concat(sChPath, INI_FILE));
    Rewrite(fsFile);
    Writeln(fsFile, SECTION_USER_POLICY);
    Writeln(fsFile, Concat(BUFFER_BMPFONT_, IntToStr(Option.dwBmpFont)));
    Writeln(fsFile, Concat(BUFFER_BPM_____, GetBoolToInt(Option.bBPM)));
    Writeln(fsFile, Concat(BUFFER_BUFNUM__, IntToStr(Option.dwBufferNum)));
    Writeln(fsFile, Concat(BUFFER_BUFTIME_, IntToStr(Option.dwBufferTime)));
    Writeln(fsFile, Concat(BUFFER_CACHEDIF, IntToStr(Option.dwCacheDiff)));
    Writeln(fsFile, Concat(BUFFER_CACHEINT, IntToStr(Option.dwCacheInt)));
    Writeln(fsFile, Concat(BUFFER_CACHEKON, IntToStr(Option.dwCacheKOn)));
    Writeln(fsFile, Concat(BUFFER_CACHENUM, IntToStr(Option.dwCacheNum)));
    Writeln(fsFile, Concat(BUFFER_DRAWINFO, IntToStr(Option.dwDrawInfo)));
    Writeln(fsFile, Concat(BUFFER_EARSAFE_, GetBoolToInt(Option.bEarSafe)));
    Writeln(fsFile, Concat(BUFFER_FADELENG, IntToStr(Option.dwFadeTime)));
    Writeln(fsFile, Concat(BUFFER_FONTNAME, Option.sFontName));
    Writeln(fsFile, Concat(BUFFER_HIDELENG, IntToStr(Option.dwHideTime)));
    Writeln(fsFile, Concat(BUFFER_LANGUAGE, IntToStr(Option.dwLanguage)));
    Writeln(fsFile, Concat(BUFFER_LISTHGT_, IntToStr(Option.dwListHeight)));
    Writeln(fsFile, Concat(BUFFER_LISTMAX_, IntToStr(Option.dwListMax)));
    Writeln(fsFile, Concat(BUFFER_NEXTLENG, IntToStr(Option.dwNextTime)));
    Writeln(fsFile, Concat(BUFFER_PLAYLENG, IntToStr(Option.dwPlayTime)));
    Writeln(fsFile, Concat(BUFFER_SCALE___, IntToStr(Option.dwScale)));
    Writeln(fsFile, Concat(BUFFER_SEEKBAR_, IntToStr(Option.dwSeekBar)));
    Writeln(fsFile, Concat(BUFFER_SEEKMAX_, IntToStr(Option.dwSeekMax)));
    Writeln(fsFile, Concat(BUFFER_SHIFTKEY, IntToStr(Option.dwShiftKey)));
    Writeln(fsFile, Concat(BUFFER_SPEEDTUN, IntToStr(Option.dwSpeedTun)));
    Writeln(fsFile, Concat(BUFFER_THEME___, IntToStr(Option.dwTheme)));
    Writeln(fsFile, Concat(BUFFER_TOPTDISP, IntToStr(Option.dwTimerOptionDisplay)));
    Writeln(fsFile, Concat(BUFFER_TOPTLOCK, IntToStr(Option.dwTimerOptionLock)));
    Writeln(fsFile, Concat(BUFFER_TREDRAW_, IntToStr(Option.dwTimerRedrawResume)));
    Writeln(fsFile, Concat(BUFFER_VOLCOLOR, IntToStr(Option.dwVolumeColor)));
    Writeln(fsFile, Concat(BUFFER_VOLSPEED, IntToStr(Option.dwVolumeSpeed)));
    Writeln(fsFile, Concat(BUFFER_WAITLENG, IntToStr(Option.dwWaitTime)));
    Writeln(fsFile, Concat(BUFFER_WAVBLANK, IntToStr(Option.dwWaveBlank)));
    Writeln(fsFile, Concat(BUFFER_WAVEFMT_, IntToStr(Option.dwWaveFormat)));
    Writeln(fsFile, '');
    Writeln(fsFile, SECTION_APP_SETTING);
    Writeln(fsFile, Concat(BUFFER_AMP_____, IntToStr(Option.dwAmp)));
    Writeln(fsFile, Concat(BUFFER_BIT_____, IntToStr(Option.dwBit)));
    Writeln(fsFile, Concat(BUFFER_CHANNEL_, IntToStr(Option.dwChannel)));
    Writeln(fsFile, Concat(BUFFER_DEVICE__, IntToStr(Option.dwDeviceID)));
    Writeln(fsFile, Concat(BUFFER_DEVNAME_, Option.sDeviceName));
    Writeln(fsFile, Concat(BUFFER_FEEDBACK, IntToStr(Option.dwFeedback)));
    Writeln(fsFile, Concat(BUFFER_INFO____, IntToStr(Option.dwInfo)));
    Writeln(fsFile, Concat(BUFFER_INTER___, IntToStr(Option.dwInter)));
    Writeln(fsFile, Concat(BUFFER_LEFT____, IntToStr(NormalRect.left + ScreenRect.left)));
    Writeln(fsFile, Concat(BUFFER_MUTE____, IntToStr(Option.dwMute)));
    Writeln(fsFile, Concat(BUFFER_NOISE___, IntToStr(Option.dwNoise)));
    Writeln(fsFile, Concat(BUFFER_NOSLEEP_, IntToStr(Option.dwNoSleep)));
    Writeln(fsFile, Concat(BUFFER_OPTION__, IntToStr(Option.dwOption)));
    Writeln(fsFile, Concat(BUFFER_PITCH___, IntToStr(Option.dwPitch)));
    Writeln(fsFile, Concat(BUFFER_PITCHSNC, GetBoolToInt(Option.bPitchAsync)));
    Writeln(fsFile, Concat(BUFFER_PLAYTIME, IntToStr(Option.dwPlayMax)));
    Writeln(fsFile, Concat(BUFFER_PLAYTYPE, IntToStr(Option.dwPlayOrder)));
    Writeln(fsFile, Concat(BUFFER_PRIORITY, IntToStr(Option.dwPriority)));
    Writeln(fsFile, Concat(BUFFER_RATE____, IntToStr(Option.dwRate)));
    Writeln(fsFile, Concat(BUFFER_SEEKFAST, GetBoolToInt(Option.bSeekFast)));
    Writeln(fsFile, Concat(BUFFER_SEEKSNC_, GetBoolToInt(Option.bSeekAsync)));
    Writeln(fsFile, Concat(BUFFER_SEEKTIME, IntToStr(Option.dwSeekTime)));
    Writeln(fsFile, Concat(BUFFER_SEPARATE, IntToStr(Option.dwSeparate)));
    Writeln(fsFile, Concat(BUFFER_SPEED___, IntToStr(Option.dwSpeedBas)));
    Writeln(fsFile, Concat(BUFFER_TOP_____, IntToStr(NormalRect.top + ScreenRect.top)));
    Writeln(fsFile, Concat(BUFFER_TOPMOST_, GetBoolToInt(Option.bTopMost)));
    Writeln(fsFile, Concat(BUFFER_VERSION_, SPCPLAY_VERSION));
    Writeln(fsFile, Concat(BUFFER_VOLRESET, GetBoolToInt(Option.bVolumeReset)));
    CloseFile(fsFile);
    // プレイリストファイルを作成
    ListSave(pchar(Concat(sChPath, LIST_FILE)), true);
    // スレッドが完全に終了するまで待機
    while longbool(Status.dwThreadStatus) do API_Sleep(16);
    // スレッドを解放
    API_CloseHandle(Status.dwThreadHandle);
    // SNESAPU.DLL を解放
    if longbool(Apu.hSNESAPU) then API_FreeLibrary(Apu.hSNESAPU);
{$IFDEF SPCBPMTEST}
    // SPC_BPM.DLL を解放
    if longbool(Apu.hSPCBPM) then API_FreeLibrary(Apu.hSPCBPM);
{$ENDIF}
{$IFDEF CONTEXT}
    // SNESAPU コンテキストを解放
    if longbool(Status.lpContext) then FreeMem(Status.lpContext, Status.dwContextSize);
{$ENDIF}
    // デバイスコンテキストを解放
    API_DeleteObject(API_SelectObject(Status.hDCVolumeBuffer, Status.hBitmapVolume));
    API_DeleteDC(Status.hDCVolumeBuffer);
    API_DeleteObject(API_SelectObject(Status.hDCStringBuffer, Status.hBitmapString));
    API_DeleteDC(Status.hDCStringBuffer);
    API_ReleaseDC(cwStaticMain.hWnd, Status.hDCWindow);
    API_ReleaseDC(cwStaticMain.hWnd, Status.hDCStatic);
    // USER32.DLL をロード
    dwBuffer := API_LoadLibraryEx(pchar('user32.dll'), NULL, LOAD_LIBRARY_SEARCH_SYSTEM32);
    if longbool(dwBuffer) then begin
        // ディスプレイの電源状態イベントを解除 (for Windows 8, 8.1, 10, 11)
        @API_UnregisterPowerSettingNotification := API_GetProcAddress(dwBuffer, pchar('UnregisterPowerSettingNotification'));
        if longbool(@API_UnregisterPowerSettingNotification) then begin
            if longbool(Status.hPowerNotify) then API_UnregisterPowerSettingNotification(Status.hPowerNotify);
        end;
        // S0 (省電力) スリープのイベントを解除 (for Windows 8, 8.1, 10, 11)
        @API_UnregisterSuspendResumeNotification := API_GetProcAddress(dwBuffer, pchar('UnregisterSuspendResumeNotification'));
        if longbool(@API_UnregisterSuspendResumeNotification) then begin
            if longbool(Status.hSuspendNotify) then API_UnregisterSuspendResumeNotification(Status.hSuspendNotify);
        end;
        // DLL を解放
        API_FreeLibrary(dwBuffer);
    end;
    // バッファを解放
    FreeMem(Status.lpCurrentPath, 1024);
    FreeMem(Status.lpSPCFile, 1024);
    FreeMem(Status.lpSPCDir, 1024);
    FreeMem(Status.lpSPCName, 1024);
    FreeMem(Status.lpOpenPath, 1024);
    FreeMem(Status.lpSavePath, 1024);
    // ウィンドウを削除
    cmFile.DeleteMenu();
    cmFile.Free();
    cmSetupDevice.DeleteMenu();
    cmSetupDevice.Free();
    cmSetupChannel.DeleteMenu();
    cmSetupChannel.Free();
    cmSetupBit.DeleteMenu();
    cmSetupBit.Free();
    cmSetupRate.DeleteMenu();
    cmSetupRate.Free();
    cmSetupInter.DeleteMenu();
    cmSetupInter.Free();
    cmSetupPitchKey.DeleteMenu();
    cmSetupPitchKey.Free();
    cmSetupPitch.DeleteMenu();
    cmSetupPitch.Free();
    cmSetupSeparate.DeleteMenu();
    cmSetupSeparate.Free();
    cmSetupFeedback.DeleteMenu();
    cmSetupFeedback.Free();
    cmSetupSpeed.DeleteMenu();
    cmSetupSpeed.Free();
    cmSetupAmp.DeleteMenu();
    cmSetupAmp.Free();
    cmSetupMute.DeleteMenu();
    cmSetupMute.Free();
    cmSetupNoise.DeleteMenu();
    cmSetupNoise.Free();
    cmSetupOption.DeleteMenu();
    cmSetupOption.Free();
    cmSetupTime.DeleteMenu();
    cmSetupTime.Free();
    cmSetupOrder.DeleteMenu();
    cmSetupOrder.Free();
    cmSetupSeek.DeleteMenu();
    cmSetupSeek.Free();
    cmSetupInfo.DeleteMenu();
    cmSetupInfo.Free();
    cmSetupPriority.DeleteMenu();
    cmSetupPriority.Free();
    cmSetupOthers.DeleteMenu();
    cmSetupOthers.Free();
    cmSetup.DeleteMenu();
    cmSetup.Free();
    cmListPlay.DeleteMenu();
    cmListPlay.Free();
    cmList.DeleteMenu();
    cmList.Free();
    cmMain.DeleteMenu();
    cmMain.Free();
    cmSystem.DeleteMenu();
    cmSystem.Free();
    cwStaticFile.DeleteWindow();
    cwStaticFile.Free();
    cwStaticMain.DeleteWindow();
    cwStaticMain.Free();
    cwButtonOpen.DeleteWindow();
    cwButtonOpen.Free();
    cwButtonSave.DeleteWindow();
    cwButtonSave.Free();
    cwButtonPlay.DeleteWindow();
    cwButtonPlay.Free();
    cwButtonRestart.DeleteWindow();
    cwButtonRestart.Free();
    cwButtonStop.DeleteWindow();
    cwButtonStop.Free();
    for I := 0 to 7 do begin
        cwCheckTrack[I].DeleteWindow();
        cwCheckTrack[I].Free();
    end;
    cwButtonVolM.DeleteWindow();
    cwButtonVolM.Free();
    cwButtonVolP.DeleteWindow();
    cwButtonVolP.Free();
    cwButtonSlow.DeleteWindow();
    cwButtonSlow.Free();
    cwButtonFast.DeleteWindow();
    cwButtonFast.Free();
    cwButtonBack.DeleteWindow();
    cwButtonBack.Free();
    cwButtonNext.DeleteWindow();
    cwButtonNext.Free();
    cwFileList.DeleteWindow();
    cwFileList.Free();
    cwSortList.DeleteWindow();
    cwSortList.Free();
    cwTempList.DeleteWindow();
    cwTempList.Free();
    cwPlayList.DeleteWindow();
    cwPlayList.Free();
    cwButtonListAdd.DeleteWindow();
    cwButtonListAdd.Free();
    cwButtonListRemove.DeleteWindow();
    cwButtonListRemove.Free();
    cwButtonListClear.DeleteWindow();
    cwButtonListClear.Free();
    cwButtonListUp.DeleteWindow();
    cwButtonListUp.Free();
    cwButtonListDown.DeleteWindow();
    cwButtonListDown.Free();
    cfMain.DeleteFont();
    cfMain.Free();
    cwWindowMain.DeleteWindow();
    cwWindowMain.Free();
    // ブラシを削除
    if longbool(Status.hBackBrush) then API_DeleteObject(Status.hBackBrush);
    if longbool(Status.hTextBrush) then API_DeleteObject(Status.hTextBrush);
    if longbool(Status.hMenuBrush) then API_DeleteObject(Status.hMenuBrush);
{$IFDEF ITASKBARLIST3}
    // COM インターフェイスを解放
    API_CoUninitialize();
{$ENDIF}
end;

// ================================================================================
// DragFile - ファイルのドラッグ (受け渡し)
// ================================================================================
procedure CWINDOWMAIN.DragFile(msg: longword; wParam: longword; lParam: longword);
var
    x: longint;
    y: longint;
    dwIndex: longint;
    dwCount: longint;
    lpFile: pointer;
    lpBuffer: pointer;
    Rect: TRECT;
    KeyState: TKEYSTATE;
    IDropSourceVtbl: ^TIDROPSOURCEVTBL;
    IDropSource: ^TIDROPSOURCE;
    IDataObjectVtbl: ^TIDATAOBJECTVTBL;
    IDataObject: ^TIDATAOBJECT;
    DropFiles: ^TDROPFILES;
    FormatEtc: ^TFORMATETC;
    StgMedium: ^TSTGMEDIUM;
begin
    // マウス座標を取得
    x := lParam and $FFFF;
    y := (lParam shr 16) and $FFFF;
    // ドラッグを開始するか判定
    case msg of
        WM_LBUTTONDOWN: begin // 左ボタン
            Status.DragPoint.x := x;
            Status.DragPoint.y := y;
            // プレイリストを即時に反応させるためのメッセージを送信
            cwPlayList.PostMessage(WM_LBUTTONUP, wParam, lParam);
            exit;
        end;
        WM_RBUTTONDOWN: begin // 右ボタン
            Status.DragPoint.x := x;
            Status.DragPoint.y := y;
            exit;
        end;
        WM_MOUSEMOVE: begin // マウス移動
            if (Status.DragPoint.x < 0) or (Status.DragPoint.y < 0) then exit;
            API_GetClientRect(cwPlayList.hWnd, @Rect);
            if (x - Rect.left >= DRAG_LIMIT_THRESHOLD)
            and (Rect.right - x > DRAG_LIMIT_THRESHOLD)
            and (y - Rect.top >= DRAG_LIMIT_THRESHOLD)
            and (Rect.bottom - y > DRAG_LIMIT_THRESHOLD)
            and (Abs(x - Status.DragPoint.x) < DRAG_START_THRESHOLD)
            and (Abs(y - Status.DragPoint.y) < DRAG_START_THRESHOLD) then exit;
        end;
        else exit;
    end;
    // マウスカーソル位置を初期化
    Status.DragPoint.x := -1;
    Status.DragPoint.y := -1;
    // キーボードの状態を取得 (Status.bShiftButton 等では状態を取得不可)
    API_GetKeyboardState(@KeyState);
    // マウスのボタンが押されていない場合は終了
    if not bytebool((KeyState.k[VK_LBUTTON] or KeyState.k[VK_RBUTTON]) and $80) then exit;
    // マウスの右ボタンが押されている場合は Shift キーを解除
    if bytebool(KeyState.k[VK_RBUTTON] and $80) then SetChangeFunction(false);
    // プレイリストのアイテム数を取得
    dwCount := cwPlayList.SendMessage(LB_GETCOUNT, NULL, NULL);
    // プレイリストにアイテムが登録されていない場合は終了
    if not longbool(dwCount) then exit;
    // 選択されているアイテムを取得
    dwIndex := cwPlayList.SendMessage(LB_GETCURSEL, NULL, NULL);
    // バッファを確保
    GetMem(lpFile, 1024);
    // ファイルとタイトルを取得
    API_ZeroMemory(lpFile, 1024);
    cwFileList.SendMessage(LB_GETTEXT, dwIndex, longword(lpFile));
    // バッファをクリア
    IDropSourceVtbl := NULLPOINTER;
    IDropSource := NULLPOINTER;
    IDataObjectVtbl := NULLPOINTER;
    IDataObject := NULLPOINTER;
    DropFiles := NULLPOINTER;
    FormatEtc := NULLPOINTER;
    StgMedium := NULLPOINTER;
    // ファイルが存在する場合
    if IsSafePath(lpFile) and Exists(lpFile, $FFFFFFFF) then repeat
        // グローバルメモリを確保
        IDropSourceVtbl := pointer(API_GlobalAlloc(GMEM_FIXED, SizeOf(TIDROPSOURCEVTBL)));
        IDropSource := pointer(API_GlobalAlloc(GMEM_FIXED, SizeOf(TIDROPSOURCE)));
        IDataObjectVtbl := pointer(API_GlobalAlloc(GMEM_FIXED, SizeOf(TIDATAOBJECTVTBL)));
        IDataObject := pointer(API_GlobalAlloc(GMEM_FIXED, SizeOf(TIDATAOBJECT)));
        DropFiles := pointer(API_GlobalAlloc(GMEM_FIXED, SizeOf(TDROPFILES) + 2048));
        FormatEtc := pointer(API_GlobalAlloc(GMEM_FIXED, SizeOf(TFORMATETC)));
        StgMedium := pointer(API_GlobalAlloc(GMEM_FIXED, SizeOf(TSTGMEDIUM)));
        // メモリを確保できない場合はループを抜ける
        if not longbool(IDropSourceVtbl)
        or not longbool(IDropSource)
        or not longbool(IDataObjectVtbl)
        or not longbool(IDataObject)
        or not longbool(DropFiles)
        or not longbool(FormatEtc)
        or not longbool(StgMedium) then break;
        // クリップボード情報を取得
        DropFiles.pFiles := SizeOf(TDROPFILES);
        DropFiles.pt.x := x;
        DropFiles.pt.y := y;
        DropFiles.fNC := false;
        DropFiles.fWide := Status.OsVersionInfo.dwPlatformId = VER_PLATFORM_WIN32_NT;
        lpBuffer := pointer(longword(DropFiles) + SizeOf(TDROPFILES));
        if DropFiles.fWide then begin
            API_ZeroMemory(lpBuffer, 2048);
            API_MultiByteToWideChar(CP_ACP, NULL, lpFile, -1, lpBuffer, 2048);
        end else begin
            API_MoveMemory(lpBuffer, lpFile, 1024);
        end;
        // FORMATETC 構造体を初期化
        FormatEtc.cfFormat := CF_HDROP;
        FormatEtc.ptd := NULLPOINTER;
        FormatEtc.dwAspect := DVASPECT_CONTENT;
        FormatEtc.lindex := -1;
        FormatEtc.tymed := TYMED_HGLOBAL;
        // STGMEDIUM 構造体を初期化
        StgMedium.tymed := TYMED_HGLOBAL;
        StgMedium.handle := longword(DropFiles);
        StgMedium.pUnkForRelease := NULLPOINTER;
        // DROPSOURCE 構造体を初期化
        IDropSourceVtbl.OLEIDropSourceQueryInterface := @_OLEIDropSourceQueryInterface;
        IDropSourceVtbl.OLEIDropSourceAddRef := @_OLEIDropSourceAddRef;
        IDropSourceVtbl.OLEIDropSourceRelease := @_OLEIDropSourceRelease;
        IDropSourceVtbl.OLEIDropSourceQueryContinueDrag := @_OLEIDropSourceQueryContinueDrag;
        IDropSourceVtbl.OLEIDropSourceGiveFeedback := @_OLEIDropSourceGiveFeedback;
        IDropSource.lpVtbl := IDropSourceVtbl;
        IDropSource.dwRefCnt := 1;
        // DATAOBJECT 構造体を初期化
        IDataObjectVtbl.OLEIDataObjectQueryInterface := @_OLEIDataObjectQueryInterface;
        IDataObjectVtbl.OLEIDataObjectAddRef := @_OLEIDataObjectAddRef;
        IDataObjectVtbl.OLEIDataObjectRelease := @_OLEIDataObjectRelease;
        IDataObjectVtbl.OLEIDataObjectGetData := @_OLEIDataObjectGetData;
        IDataObjectVtbl.OLEIDataObjectGetDataHere := @_OLEIDataObjectGetDataHere;
        IDataObjectVtbl.OLEIDataObjectQueryGetData := @_OLEIDataObjectQueryGetData;
        IDataObjectVtbl.OLEIDataObjectGetCanonicalFormatEtc := @_OLEIDataObjectGetCanonicalFormatEtc;
        IDataObjectVtbl.OLEIDataObjectSetData := @_OLEIDataObjectSetData;
        IDataObjectVtbl.OLEIDataObjectEnumFormatEtc := @_OLEIDataObjectEnumFormatEtc;
        IDataObjectVtbl.OLEIDataObjectDAdvise := @_OLEIDataObjectDAdvise;
        IDataObjectVtbl.OLEIDataObjectDUnadvise := @_OLEIDataObjectDUnadvise;
        IDataObjectVtbl.OLEIDataObjectEnumDAdvise := @_OLEIDataObjectEnumDAdvise;
        IDataObject.lpVtbl := IDataObjectVtbl;
        IDataObject.dwRefCnt := 1;
        IDataObject.dwObjectCnt := 0;
        _OLEIDataObjectSetData(IDataObject, FormatEtc, StgMedium, true);
        // OLE を初期化
        if API_OleInitialize(NULLPOINTER) = S_OK then begin
            // プレイリストへのドロップを禁止
            Status.bDropCancel := true;
            // ドラッグアンドドロップイベントを開始
            dwIndex := NULL;
            dwIndex := API_DoDragDrop(IDataObject, IDropSource, DROPEFFECT_COPY or DROPEFFECT_SCROLL, @dwIndex);
            // OLE を解放
            API_OleUninitialize();
            // ドロップ禁止の解除を予約
            cwWindowMain.PostMessage(WM_APP_MESSAGE, WM_APP_DRAG_DONE, dwIndex);
        end;
        // バッファを解放
        _OLEIDropSourceRelease(IDropSource);
        _OLEIDataObjectRelease(IDataObject);
        // IDropSource と IDataObject の Release で参照カウントが 0 になったときにメモリ解放するため、
        // 後続では DropFiles, FormatEtc, StgMedium を含めて解放しない
        IDropSourceVtbl := NULLPOINTER;
        IDropSource := NULLPOINTER;
        IDataObjectVtbl := NULLPOINTER;
        IDataObject := NULLPOINTER;
        DropFiles := NULLPOINTER;
        FormatEtc := NULLPOINTER;
        StgMedium := NULLPOINTER;
    until true;
    // バッファを解放
    if longbool(IDropSourceVtbl) then API_GlobalFree(longword(IDropSourceVtbl));
    if longbool(IDropSource) then API_GlobalFree(longword(IDropSource));
    if longbool(IDataObjectVtbl) then API_GlobalFree(longword(IDataObjectVtbl));
    if longbool(IDataObject) then API_GlobalFree(longword(IDataObject));
    if longbool(DropFiles) then API_GlobalFree(longword(DropFiles));
    if longbool(FormatEtc) then API_GlobalFree(longword(FormatEtc));
    if longbool(StgMedium) then API_GlobalFree(longword(StgMedium));
    FreeMem(lpFile, 1024);
end;

// ================================================================================
// DrawInfo - インジケータの描画
// ================================================================================
procedure CWINDOWMAIN.DrawInfo(pApuData: pointer; bWave: longbool);
var
    I: longint;
    J: longword;
    K: longword;
    L: longword;
    V: longword;
    X: longint;
    Y: longint;
    Z: longint;
    bRedrawInfo: longbool;
    T64Count: longword;
    Rect: TRECT;
    CopiedRect: TRECT;
    StrData: TSTRDATA;
    ApuData: ^TAPUDATA;
    DspReg: ^TDSPREG;
    Voices: ^TVOICES;
    Voice: ^TVOICE;
    DspVoice: ^TDSPVOICE;
    SPC700Reg: ^TSPC700REG;
    Script700: ^TSCRIPT700;

function DrawInfoBitBlt(nXDest: longint; nYDest: longint; nWidthDest: longint; nHeightDest: longint; hdcSrc: longword; nXSrc: longint; nYSrc: longint): longbool;
begin
    if Status.dwScale = 2 then begin
        result := API_BitBlt(Status.hDCStatic, nXDest, nYDest, nWidthDest, nHeightDest, hdcSrc, nXSrc, nYSrc, SRCCOPY);
    end else begin
        result := API_StretchBlt(Status.hDCStatic, (nXDest * Status.dwScale) shr 1, (nYDest * Status.dwScale) shr 1,
            (nWidthDest * Status.dwScale) shr 1, (nHeightDest * Status.dwScale) shr 1 + (Status.dwScale and 1),
            hdcSrc, nXSrc, nYSrc, nWidthDest, nHeightDest, SRCCOPY);
    end;
end;

function DrawInfoFillRect(lprc: pointer; hbr: longword): longint;
begin
    if Status.dwScale = 2 then begin
        result := API_FillRect(Status.hDCStatic, lprc, hbr);
    end else begin
        API_MoveMemory(@CopiedRect, lprc, SizeOf(TRECT));
        CopiedRect.left := (CopiedRect.left * Status.dwScale) shr 1;
        CopiedRect.top := (CopiedRect.top * Status.dwScale) shr 1;
        CopiedRect.right := (CopiedRect.right * Status.dwScale) shr 1;
        CopiedRect.bottom := (CopiedRect.bottom * Status.dwScale) shr 1;
        result := API_FillRect(Status.hDCStatic, @CopiedRect, hbr);
    end;
end;

procedure UpdateVolumeWrite(cLastLevel: byte; cNowLevel: byte; dwColor: longword; dwLeft: longint; dwWidth: longint);
begin
    // 全体を再描画する場合
    if bRedrawInfo then begin
        // バーを描画
        if cNowLevel > 0 then begin
            DrawInfoBitBlt(dwLeft, COLOR_BAR_HEIGHT_X2 - longword(cNowLevel), dwWidth, longword(cNowLevel),
                Status.hDCVolumeBuffer, dwColor, COLOR_BAR_HEIGHT - longword(cNowLevel));
        end;
        // 空白部分を描画
        if cNowLevel < COLOR_BAR_HEIGHT then begin
            Rect.left := dwLeft;
            Rect.right := dwLeft + dwWidth;
            Rect.top := COLOR_BAR_HEIGHT;
            Rect.bottom := COLOR_BAR_HEIGHT_X2 - longword(cNowLevel);
            DrawInfoFillRect(@Rect, Status.hBackBrush);
        end;
    end else begin
        // レベル値が前回と同じ場合は終了
        if cLastLevel = cNowLevel then exit;
        // レベル値が前回より上がった場合はバーを描画
        if cLastLevel < cNowLevel then begin
            DrawInfoBitBlt(dwLeft, COLOR_BAR_HEIGHT_X2 - longword(cNowLevel), dwWidth, longword(cNowLevel - cLastLevel),
                Status.hDCVolumeBuffer, dwColor, COLOR_BAR_HEIGHT - longword(cNowLevel));
        // レベル値が前回より下がった場合は空白部分を描画
        end else begin
            Rect.left := dwLeft;
            Rect.right := dwLeft + dwWidth;
            Rect.top := COLOR_BAR_HEIGHT_X2 - longword(cLastLevel);
            Rect.bottom := COLOR_BAR_HEIGHT_X2 - longword(cNowLevel);
            DrawInfoFillRect(@Rect, Status.hBackBrush);
        end;
    end;
end;

procedure UpdateVolumeFrame(dwLeft: longint);
begin
    // フレームを描画
    Rect.left := dwLeft;
    Rect.right := dwLeft + 1;
    Rect.top := COLOR_BAR_TOP_FRAME;
    Rect.bottom := COLOR_BAR_HEIGHT_X2;
    DrawInfoFillRect(@Rect, ORG_COLOR_GRAYTEXT);
end;

procedure UpdateVolumeBlank(dwLeft: longint);
begin
    // 空白領域を描画
    Rect.left := dwLeft;
    Rect.right := dwLeft + 27;
    Rect.top := COLOR_BAR_TOP;
    Rect.bottom := COLOR_BAR_HEIGHT_X2;
    DrawInfoFillRect(@Rect, Status.hBackBrush);
end;

procedure UpdateNumWrite(dwX: longint; dwL: longword);
var
    dwI: longint;
    dwJ: longint;
    cV: byte;
begin
    // デジタル文字を描画
    dwJ := Y * COLOR_BAR_HEIGHT + dwX;
    dwX := dwX * BITMAP_NUM_WIDTH + Z;
    K := dwL - 1;
    L := Y * 12 + 25;
    for dwI := 0 to K do begin
        cV := StrData.bData[dwI];
        // 全体を描画する場合、または、前回描画値から変化した場合
        if bRedrawInfo or (Status.NumCache[dwJ] <> cV) then begin
            Status.NumCache[dwJ] := cV;
            J := longword(cV);
            case J of
                $20: J := BITMAP_NUM;  // SPACE
                $30..$39: Dec(J, $30); // 0 ～ 9
                $41..$5A: Dec(J, $37); // A ～ Z
                $61..$7A: Dec(J, $3D); // a ～ z
            end;
            DrawInfoBitBlt(dwX, L, BITMAP_NUM_WIDTH, BITMAP_NUM_HEIGHT, Status.hDCStringBuffer, J * BITMAP_NUM_WIDTH, 0);
        end;
        Inc(dwJ);
        Inc(dwX, BITMAP_NUM_WIDTH);
    end;
end;

procedure DeleteMarkWrite(dwY: longint);
begin
    // 位置マークを消去
    Rect.left := 137;
    Rect.right := 284 + (Status.dwScale and 1);
    Rect.top := dwY;
    Rect.bottom := dwY + (Status.dwScale and 1) + 3;
    DrawInfoFillRect(@Rect, Status.hBackBrush);
end;

procedure UpdateMarkWrite(dwI: longint; dwY: longint);
begin
    // 位置マークを描画
    DeleteMarkWrite(dwY);
    DrawInfoBitBlt(J - 2, dwY, BITMAP_NUM_WIDTH, BITMAP_MARK_HEIGHT, Status.hDCStringBuffer, (dwI + 38) * BITMAP_NUM_WIDTH, 0);
end;

function GetLevelAbs(cLevel: byte): byte;
begin
    result := byte(Min(COLOR_BAR_HEIGHT, (Abs(shortint(cLevel)) * 49) shr 7));
end;

function GetLevelDelay(cLevel: byte): byte;
begin
    result := byte(Min(COLOR_BAR_HEIGHT, longword((cLevel and $F) * 52) shr 4));
end;

function GetLevelByte(cLevel: byte): byte;
begin
    result := byte(Min(COLOR_BAR_HEIGHT, longword(cLevel * 49) shr 8));
end;

function GetVolumeLevel(dwLevel: single): byte;
begin
    result := byte(Max(0, Min(COLOR_BAR_HEIGHT, Round(18 * Log10(dwLevel * 0.005 + 1)))));
end;

function GetPitchLevel(dwLevel: longword): byte;
begin
    result := byte(Max(0, Min(COLOR_BAR_HEIGHT, Round(22 * Log10((dwLevel and $3FFF) + 1)) - 44)));
end;

procedure UpdateChannelSource(bDec: boolean);
begin
    // 音色番号を描画
    J := DspVoice.SoundSourcePlayBack;
    if bDec and Status.bBreakButton then begin
        Z := 0;
        UpdateNumWrite(X, IntToStr(StrData, J, 3));
    end else begin
        Z := 3;
        UpdateNumWrite(X, IntToHex(StrData, J, 2));
        Z := 0;
    end;
end;

function SearchTuneAddress(dwPhase: longword): bytebool;
var
    dwI: longint;
    dwJ: longint;
    dwK: longint;
    dwSource: longint;
    dwMatch: longword;
    TmpVoice: ^TVOICE;
    TmpDspVoice: ^TDSPVOICE;
begin
    // 探索済みの場合は終了
    if longbool(Status.dwTuningSize) then begin
        result := true;
        exit;
    end;
    // 初期化
    result := false;
    dwSource := -1;
    // 全チャンネルを探索
    for dwI := 0 to 7 do begin
        // 音が出力されていない場合はループを再開
        TmpVoice := @Voices.Voice[dwI];
        if not longbool(TmpVoice.VolumeMaxLeft) and not longbool(TmpVoice.VolumeMaxRight) then continue;
        // ADSR が指定されていない場合はループを再開
        TmpDspVoice := @DspReg.Voice[dwI];
        if not longbool(TmpDspVoice.EnvelopeADSR1) and not longbool(TmpDspVoice.EnvelopeADSR2) then continue;
        // ADSR パラメータを探索
        for dwJ := Status.dwTuningAddress + 1 to $FFBB do begin
            // ADSR パラメータが見つからない場合はループを再開
            if Apu.Ram.Ram[dwJ + 0] <> TmpDspVoice.EnvelopeADSR1 then continue;
            if Apu.Ram.Ram[dwJ + 1] <> TmpDspVoice.EnvelopeADSR2 then continue;
            if not longbool(dwPhase) then begin
                if Apu.Ram.Ram[dwJ + 2] <> TmpDspVoice.EnvelopeGain then continue;
            end else begin
                if Apu.Ram.Ram[dwJ - 1] <> TmpDspVoice.SoundSourcePlayBack then continue;
            end;
            // ADSR パラメータ位置を記録
            Status.dwTuningAddress := longword(dwJ);
            dwSource := longint(TmpDspVoice.SoundSourcePlayBack);
            // ループを抜ける
            break;
        end;
        // ADSR パラメータが見つからない場合は探索位置をリセット
        if dwSource < 0 then Status.dwTuningAddress := $1FF;
        // ループを抜ける
        break;
    end;
    // ADSR パラメータが見つからない場合は終了
    if dwSource < 0 then exit;
    // 次のチャンネルを探索
    for dwMatch := 0 to 1 do for dwI := 0 to 7 do begin
        // 音が出力されていない場合はループを再開
        if not longbool(dwMatch) then begin
            TmpVoice := @Voices.Voice[dwI];
            if not longbool(TmpVoice.VolumeMaxLeft) and not longbool(TmpVoice.VolumeMaxRight) then continue;
        end;
        // ADSR が指定されていない場合はループを再開
        TmpDspVoice := @DspReg.Voice[dwI];
        if not longbool(TmpDspVoice.EnvelopeADSR1) and not longbool(TmpDspVoice.EnvelopeADSR2) then continue;
        // 1回目のチャンネルと同じ波形番号の場合はループを再開
        if byte(dwSource) = TmpDspVoice.SoundSourcePlayBack then continue;
        // ADSR パラメータを探索
        for dwJ := 5 to 8 do begin
            // アドレスが範囲外になる場合はループを再開
            dwK := longint(TmpDspVoice.SoundSourcePlayBack) - dwSource;
            dwK := longint(Status.dwTuningAddress) + dwK * dwJ;
            if (dwK < $200) or (dwK > $FFBB) then continue;
            // ADSR パラメータが見つからない場合はループを再開
            if Apu.Ram.Ram[dwK + 0] <> TmpDspVoice.EnvelopeADSR1 then continue;
            if Apu.Ram.Ram[dwK + 1] <> TmpDspVoice.EnvelopeADSR2 then continue;
            if not longbool(dwPhase) then begin
                if Apu.Ram.Ram[dwK + 2] <> TmpDspVoice.EnvelopeGain then continue;
            end else begin
                if Apu.Ram.Ram[dwK - 1] <> TmpDspVoice.SoundSourcePlayBack then continue;
            end;
            // ADSR パラメータ位置から TUNING 開始アドレスを取得
            Dec(Status.dwTuningAddress, dwSource * dwJ - 3);
            // ADSR パラメータサイズを記録
            Status.dwTuningSize := dwJ;
            // 成功
            result := true;
            exit;
        end;
        // ループを抜ける
        break;
    end;
end;

begin
    // バッファを設定
    ApuData := pApuData;
    DspReg := @ApuData.DspReg;
    Voices := @ApuData.Voices;
    T64Count := ApuData.T64Count;
    // 再描画フラグを設定
    bRedrawInfo := longbool(Status.dwRedrawInfo and REDRAW_ON);
    // 次回は再描画しない
    Status.dwRedrawInfo := REDRAW_OFF;
    // 時間を描画
    Y := 0;
    Z := 0;
    UpdateNumWrite(11, IntToStr(StrData, T64Count div 230400000, 1));
    UpdateNumWrite(13, IntToStr(StrData, T64Count div 3840000 mod 60, 2));
    UpdateNumWrite(16, IntToStr(StrData, T64Count div 64000 mod 60, 2));
    UpdateNumWrite(19, IntToStr(StrData, T64Count div 64, 3));
    if Status.bTimeRepeat then begin
        // リピート開始位置を描画
        if Status.dwStartTime >= Status.dwDefaultTimeout then J := 280
        else J := (Status.dwStartTime * 141 div Status.dwDefaultTimeout) + 139;
        if bRedrawInfo or (J <> Status.dwLastStartTime) then UpdateMarkWrite(0, 24);
        Status.dwLastStartTime := J;
        // リピート終了位置を描画
        if Status.dwLimitTime >= Status.dwDefaultTimeout then J := 280
        else J := (Status.dwLimitTime * 141 div Status.dwDefaultTimeout) + 139;
        if bRedrawInfo or (J <> Status.dwLastLimitTime) then UpdateMarkWrite(1, 32);
        Status.dwLastLimitTime := J;
    end else begin
        J := 280;
        if longbool(Option.dwSeekBar) then begin
            // エンドレスマーク、または一時停止マークを描画
            if bRedrawInfo then if Option.dwPlayMax > PLAY_MAX_ENDLESS then UpdateMarkWrite(14, 24) else UpdateMarkWrite(13, 24);
        end else begin
            // リピート位置を消去
            if bRedrawInfo then DeleteMarkWrite(24);
        end;
        Status.dwLastStartTime := J;
        // リピート位置を消去
        if bRedrawInfo then DeleteMarkWrite(32);
        Status.dwLastLimitTime := $FFFFFFFF;
    end;
    if longbool(Option.dwSeekBar) or (Option.dwPlayMax > PLAY_MAX_ENDLESS) then begin
        // タイムゲージを描画
        if not Status.bPlay then J := 140
        else if T64Count >= Status.dwDefaultTimeout then J := 280
        else J := (T64Count * 141 div Status.dwDefaultTimeout) + 140;
        if bRedrawInfo or (J <> Status.dwLastTime) then begin
            if J > 140 then begin
                Rect.left := 140;
                Rect.right := J;
                Rect.top := 27;
                Rect.bottom := 32;
                DrawInfoFillRect(@Rect, Status.hTextBrush);
            end;
            if J < 280 then begin
                Rect.left := J;
                Rect.right := 280;
                Rect.top := 27;
                Rect.bottom := 28;
                DrawInfoFillRect(@Rect, Status.hBackBrush);
                Rect.top := 28;
                Rect.bottom := 31;
                DrawInfoFillRect(@Rect, ORG_COLOR_GRAYTEXT);
                Rect.top := 31;
                Rect.bottom := 32;
                DrawInfoFillRect(@Rect, Status.hBackBrush);
            end;
        end;
        // データをコピー
        Status.dwLastTime := J;
    end else begin
        // タイムゲージを消去
        if bRedrawInfo then begin
            Rect.left := 137;
            Rect.right := 284 + (Status.dwScale and 1);
            Rect.top := 24;
            Rect.bottom := 35 + (Status.dwScale and 1);
            DrawInfoFillRect(@Rect, Status.hBackBrush);
        end;
    end;
    // インジケータを描画
    case Option.dwInfo of
        INFO_INDICATOR: begin
            // 各レベル値を計算
            if bWave and not Status.bPause then begin
                Status.NowLevel.cMasterLevelLeft := Max(Status.NowLevel.cMasterLevelLeft - byte(Option.dwVolumeSpeed),
                    GetVolumeLevel(ApuData.VolumeMaxLeft));
                Status.NowLevel.cMasterLevelRight := Max(Status.NowLevel.cMasterLevelRight - byte(Option.dwVolumeSpeed),
                    GetVolumeLevel(ApuData.VolumeMaxRight));
                Status.NowLevel.cMasterVolumeLeft := GetLevelAbs(DspReg.MainVolumeLeft);
                Status.NowLevel.cMasterVolumeRight := GetLevelAbs(DspReg.MainVolumeRight);
                Status.NowLevel.cMasterEchoLeft := GetLevelAbs(DspReg.EchoVolumeLeft);
                Status.NowLevel.cMasterEchoRight := GetLevelAbs(DspReg.EchoVolumeRight);
                Status.NowLevel.cMasterDelay := GetLevelDelay(DspReg.EchoDelay);
                Status.NowLevel.cMasterFeedback := GetLevelAbs(DspReg.EchoFeedback);
                for I := 0 to 7 do begin
                    Voice := @Voices.Voice[I];
                    DspVoice := @DspReg.Voice[I];
                    Status.NowLevel.Channel[I].cChannelLevelLeft := Max(Status.NowLevel.Channel[I].cChannelLevelLeft - byte(Option.dwVolumeSpeed),
                        GetVolumeLevel(Voice.VolumeMaxLeft));
                    Status.NowLevel.Channel[I].cChannelLevelRight := Max(Status.NowLevel.Channel[I].cChannelLevelRight - byte(Option.dwVolumeSpeed),
                        GetVolumeLevel(Voice.VolumeMaxRight));
                    Status.NowLevel.Channel[I].cChannelVolumeLeft := GetLevelAbs(DspVoice.VolumeLeft);
                    Status.NowLevel.Channel[I].cChannelVolumeRight := GetLevelAbs(DspVoice.VolumeRight);
                    Status.NowLevel.Channel[I].cChannelPitch := GetPitchLevel(DspVoice.Pitch);
                    Status.NowLevel.Channel[I].cChannelEnvelope := GetLevelAbs(DspVoice.CurrentEnvelope);
                    if Option.bVolumeReset then begin
                        if not longbool(Voice.VolumeMaxLeft) and not longbool(Voice.VolumeMaxRight) then
                            Wave.dwTimeout[I] := Min(Option.dwHideTime, Wave.dwTimeout[I] + Option.dwBufferTime)
                        else Wave.dwTimeout[I] := 0;
                        V := Voice.MixFlag and $1;
                        if Wave.dwTimeout[I] = Option.dwHideTime then Inc(V);
                    end else begin
                        Wave.dwTimeout[I] := Option.dwHideTime;
                        V := Voice.MixFlag and $1;
                    end;
                    Status.NowLevel.Channel[I].bChannelShow := not longbool(V);
                end;
            end;
            // 全体を再描画する場合は MIXER とフレームを描画
            if bRedrawInfo then begin
                StrData.qwData := $535251504F; // 'OPQRS'
                Y := 1;
                Z := 4;
                UpdateNumWrite(1, 5);
                UpdateVolumeFrame(0);
                UpdateVolumeFrame(2);
                UpdateVolumeFrame(44);
                UpdateVolumeFrame(46);
            end;
            // マスターのインジケータを描画
            UpdateVolumeWrite(Status.LastLevel.cMasterVolumeLeft, Status.NowLevel.cMasterVolumeLeft, COLOR_BAR_GREEN, 4, 3);
            UpdateVolumeWrite(Status.LastLevel.cMasterVolumeRight, Status.NowLevel.cMasterVolumeRight, COLOR_BAR_GREEN, 8, 3);
            UpdateVolumeWrite(Status.LastLevel.cMasterEchoLeft, Status.NowLevel.cMasterEchoLeft, COLOR_BAR_ORANGE, 12, 3);
            UpdateVolumeWrite(Status.LastLevel.cMasterEchoRight, Status.NowLevel.cMasterEchoRight, COLOR_BAR_ORANGE, 16, 3);
            UpdateVolumeWrite(Status.LastLevel.cMasterDelay, Status.NowLevel.cMasterDelay, COLOR_BAR_WATER, 20, 3);
            UpdateVolumeWrite(Status.LastLevel.cMasterFeedback, Status.NowLevel.cMasterFeedback, COLOR_BAR_RED, 24, 3);
            UpdateVolumeWrite(Status.LastLevel.cMasterLevelLeft, Status.NowLevel.cMasterLevelLeft, COLOR_BAR_BLUE, 28, 7);
            UpdateVolumeWrite(Status.LastLevel.cMasterLevelRight, Status.NowLevel.cMasterLevelRight, COLOR_BAR_BLUE, 36, 7);
            X := 0;
            V := 0;
            Y := 1;
            for I := 0 to 7 do begin
                // 全体を再描画する場合はチャンネル番号とフレームを描画
                if bRedrawInfo then begin
                    Z := 0;
                    StrData.dwData[0] := I + $31;
                    UpdateNumWrite(X + 8, 1);
                    UpdateVolumeFrame(V + 76);
                    Status.LastLevel.Channel[I].dwChannelEffect.Update := true;
                end;
                // 各チャンネルのインジケータを描画
                if Status.NowLevel.Channel[I].bChannelShow then begin
                    Z := 3;
                    if not Status.LastLevel.Channel[I].bChannelShow then begin
                        API_ZeroMemory(@Status.LastLevel.Channel[I], 12);
                        Status.LastLevel.Channel[I].dwChannelEffect.Update := true;
                    end;
                    J := 1 shl I;
                    Status.NowLevel.Channel[I].dwChannelEffect.EchoOn := bytebool(DspReg.EchoOn and J);
                    Status.NowLevel.Channel[I].dwChannelEffect.PitchModOn := bytebool(DspReg.PitchModOn and J);
                    Status.NowLevel.Channel[I].dwChannelEffect.NoiseOn := bytebool(DspReg.NoiseOn and J);
                    Status.NowLevel.Channel[I].dwChannelEffect.Update := false;
                    if Status.LastLevel.Channel[I].dwChannelEffect.dwValue <> Status.NowLevel.Channel[I].dwChannelEffect.dwValue then begin
                        StrData.dwData[0] := $565656; // 'VVV'
                        if Status.NowLevel.Channel[I].dwChannelEffect.EchoOn then StrData.bData[0] := $49; // 'I'
                        if Status.NowLevel.Channel[I].dwChannelEffect.PitchModOn then StrData.bData[1] := $4A; // 'J'
                        if Status.NowLevel.Channel[I].dwChannelEffect.NoiseOn then StrData.bData[2] := $4B; // 'K'
                        UpdateNumWrite(X + 9, 3);
                    end;
                    UpdateVolumeWrite(Status.LastLevel.Channel[I].cChannelVolumeLeft, Status.NowLevel.Channel[I].cChannelVolumeLeft,
                        COLOR_BAR_GREEN, V + 48, 3);
                    UpdateVolumeWrite(Status.LastLevel.Channel[I].cChannelVolumeRight, Status.NowLevel.Channel[I].cChannelVolumeRight,
                        COLOR_BAR_GREEN, V + 52, 3);
                    UpdateVolumeWrite(Status.LastLevel.Channel[I].cChannelPitch, Status.NowLevel.Channel[I].cChannelPitch,
                        COLOR_BAR_ORANGE, V + 56, 3);
                    UpdateVolumeWrite(Status.LastLevel.Channel[I].cChannelEnvelope, Status.NowLevel.Channel[I].cChannelEnvelope,
                        COLOR_BAR_RED, V + 60, 3);
                    UpdateVolumeWrite(Status.LastLevel.Channel[I].cChannelLevelLeft, Status.NowLevel.Channel[I].cChannelLevelLeft,
                        COLOR_BAR_BLUE, V + 64, 5);
                    UpdateVolumeWrite(Status.LastLevel.Channel[I].cChannelLevelRight, Status.NowLevel.Channel[I].cChannelLevelRight,
                        COLOR_BAR_BLUE, V + 70, 5);
                end else if Status.LastLevel.Channel[I].bChannelShow then begin
                    Z := 3;
                    StrData.dwData[0] := $202020; // '   '
                    UpdateNumWrite(X + 9, 3);
                    UpdateVolumeBlank(V + 48);
                end;
                Inc(X, 5);
                Inc(V, 30);
            end;
            // データをコピー
            Status.LastLevel := Status.NowLevel;
        end;
        INFO_MIXER: begin
            // ミキサー情報を描画
            Y := 1;
            Z := 0;
            if Status.bBreakButton then begin
                UpdateNumWrite(13, IntToStr(StrData, Abs(shortint(DspReg.MainVolumeLeft)) and $7F, 3));
                UpdateNumWrite(19, IntToStr(StrData, Abs(shortint(DspReg.MainVolumeRight)) and $7F, 3));
                UpdateNumWrite(38, IntToStr(StrData, Abs(shortint(DspReg.EchoVolumeLeft)) and $7F, 3));
                UpdateNumWrite(44, IntToStr(StrData, Abs(shortint(DspReg.EchoVolumeRight)) and $7F, 3));
            end else begin
                UpdateNumWrite(13, IntToHex(StrData, DspReg.MainVolumeLeft, 2));
                UpdateNumWrite(19, IntToHex(StrData, DspReg.MainVolumeRight, 2));
                UpdateNumWrite(38, IntToHex(StrData, DspReg.EchoVolumeLeft, 2));
                UpdateNumWrite(44, IntToHex(StrData, DspReg.EchoVolumeRight, 2));
            end;
            Y := 2;
            if Status.bBreakButton then begin
                UpdateNumWrite(11, IntToStr(StrData, DspReg.EchoDelay, 3));
                UpdateNumWrite(36, IntToStr(StrData, Abs(shortint(DspReg.EchoFeedback)) and $7F, 3));
            end else begin
                UpdateNumWrite(11, IntToHex(StrData, DspReg.EchoDelay, 2));
                UpdateNumWrite(36, IntToHex(StrData, DspReg.EchoFeedback, 2));
            end;
            UpdateNumWrite(15, IntToStr(StrData, (DspReg.EchoDelay and $F) shl 4, 3));
            if bytebool(DspReg.EchoFeedback and $80) then V := Round(200 - DspReg.EchoFeedback * 0.78125) // 200 - FEEDBACK / 0x80 * 100
            else V := Round(DspReg.EchoFeedback * 0.7874015748031496062992125984252); // FEEDBACK / 0x7F * 100
            UpdateNumWrite(40, IntToStr(StrData, V, 3));
            Y := 3;
            V := DspReg.SourceDirectory shl 8;
            UpdateNumWrite(11, IntToHex(StrData, V, 4));
            if longbool(T64Count) then Inc(V, $3FF);
            UpdateNumWrite(16, IntToHex(StrData, V, 4));
            V := DspReg.EchoWaveform shl 8;
            UpdateNumWrite(36, IntToHex(StrData, V, 4));
            if longbool(T64Count) then
                if bytebool(DspReg.EchoDelay) then Inc(V, ((DspReg.EchoDelay and $F) shl 11) - 1)
                else Inc(V, 3);
            UpdateNumWrite(41, IntToHex(StrData, V, 4));
            V := DspReg.Flags;
            Y := 4;
            if not Status.bBreakButton then begin
                StrData.cData[0] := BoolTable[(V shr 7) and $1];
                UpdateNumWrite(13, 1);
                StrData.cData[0] := BoolTable[(V shr 6) and $1];
                UpdateNumWrite(17, 1);
                StrData.cData[0] := BoolTable[(V shr 5) and $1];
                UpdateNumWrite(21, 1);
                StrData.qwData := NOISE_RATE[V and $1F];
                UpdateNumWrite(36, 5);
            end;
            if Status.bBreakButton then for I := 0 to 7 do begin
                UpdateNumWrite(11 + I * 4, IntToStr(StrData, Abs(shortint(DspReg.Voice[I].Fir)) and $7F, 3));
            end else begin
                Y := 5;
                for I := 0 to 7 do UpdateNumWrite(11 + I * 3, IntToHex(StrData, DspReg.Voice[I].Fir, 2));
            end;
            if Option.bBPM then begin
                Y := 5;
                if Status.bBreakButton then begin
                    if Status.bPlay then begin
                        UpdateNumWrite(15, IntToStr(StrData, Status.Tempo.cKOnCount, 3));
                    end else begin
                        StrData.dwData[0] := $565656; // 'VVV'
                        UpdateNumWrite(15, 3);
                    end;
                    if bytebool(Status.Tempo.cKOnCountOld) then begin
                        UpdateNumWrite(19, IntToStr(StrData, Status.Tempo.cKOnCountOld, 3));
                    end else begin
                        StrData.dwData[0] := $565656; // 'VVV'
                        UpdateNumWrite(19, 3);
                    end;
                    if bytebool(Status.Tempo.cMinBPM) then begin
                        UpdateNumWrite(25, IntToStr(StrData, Status.Tempo.cMinBPM, 3));
                    end else begin
                        StrData.dwData[0] := $565656; // 'VVV'
                        UpdateNumWrite(25, 3);
                    end;
                    if bytebool(Status.Tempo.cMaxBPM) then begin
                        UpdateNumWrite(29, IntToStr(StrData, Status.Tempo.cMaxBPM, 3));
                    end else begin
                        StrData.dwData[0] := $565656; // 'VVV'
                        UpdateNumWrite(29, 3);
                    end;
                    if bytebool(Status.Tempo.cMode) then StrData.dwData[0] := Status.Tempo.cMode else StrData.dwData[0] := $56; // 'V'
                    UpdateNumWrite(35, 1);
                end;
{$IFDEF SPCBPMTEST}
                I := Apu.BPMGetBPM();
{$ELSE}
                I := Status.Tempo.cBPM;
{$ENDIF}
                if longbool(I) then begin
                    UpdateNumWrite(44, IntToStr(StrData, I, 3));
                end else begin
                    StrData.dwData[0] := $565656; // 'VVV'
                    UpdateNumWrite(44, 3);
                end;
            end;
        end;
        INFO_CHANNEL_1: for I := 0 to 7 do begin
            // 各チャンネル情報を描画
            X := I div 4 * 25 + 4;
            Y := I mod 4 + 2;
            DspVoice := @DspReg.Voice[I];
            UpdateChannelSource(true);
            if Status.bBreakButton then begin
                UpdateNumWrite(X +  4, IntToStr(StrData, Abs(shortint(DspVoice.VolumeLeft)) and $7F, 3));
                UpdateNumWrite(X +  8, IntToStr(StrData, Abs(shortint(DspVoice.VolumeRight)) and $7F, 3));
                UpdateNumWrite(X + 12, IntToStr(StrData, DspVoice.CurrentEnvelope, 3));
                UpdateNumWrite(X + 16, IntToHex(StrData, DspVoice.CurrentOutput, 2));
            end else begin
                UpdateNumWrite(X +  4, IntToHex(StrData, DspVoice.VolumeLeft, 2));
                UpdateNumWrite(X +  7, IntToHex(StrData, DspVoice.VolumeRight, 2));
                UpdateNumWrite(X + 16, IntToHex(StrData, DspVoice.CurrentEnvelope, 2));
                Z := 3;
                UpdateNumWrite(X + 10, IntToHex(StrData, DspVoice.Pitch, 4));
            end;
        end;
        INFO_CHANNEL_2: for I := 0 to 7 do begin
            // 各チャンネル情報を描画
            X := I div 4 * 25 + 4;
            Y := I mod 4 + 2;
            DspVoice := @DspReg.Voice[I];
            UpdateChannelSource(false);
            Voice := @Voices.Voice[I];
            if not longbool(T64Count) then begin
                // 演奏停止中
                if Status.bBreakButton then begin
                    StrData.dwData[0] := $3030; // '00'
                    UpdateNumWrite(X +  4, 2);
                    UpdateNumWrite(X +  7, 2);
                    UpdateNumWrite(X + 10, 2);
                    StrData.dwData[0] := $5656; // 'VV'
                    UpdateNumWrite(X + 16, 2);
                    Z := 3;
                    UpdateNumWrite(X + 13, 2);
                end else begin
                    StrData.dwData[0] := $5656; // 'VV'
                    UpdateNumWrite(X +  4, 2);
                    UpdateNumWrite(X +  7, 1);
                    UpdateNumWrite(X +  9, 1);
                    UpdateNumWrite(X + 11, 1);
                    StrData.dwData[0] := $54; // 'T'
                    UpdateNumWrite(X +  8, 1);
                    UpdateNumWrite(X + 10, 1);
                    UpdateNumWrite(X + 12, 1);
                    StrData.dwData[0] := $3030; // '00'
                    UpdateNumWrite(X + 13, 2);
                end;
            end else if Status.bBreakButton then begin
                // AddMusicK ADSR
                UpdateNumWrite(X +  4, IntToHex(StrData, DspVoice.EnvelopeADSR1, 2));
                UpdateNumWrite(X +  7, IntToHex(StrData, DspVoice.EnvelopeADSR2, 2));
                UpdateNumWrite(X + 10, IntToHex(StrData, DspVoice.EnvelopeGain, 2));
                StrData.dwData[0] := $54; // 'T'
                UpdateNumWrite(X +  6, 1);
                UpdateNumWrite(X +  9, 1);
                UpdateNumWrite(X + 12, 1);
                // TUNING
                if SearchTuneAddress(0) or SearchTuneAddress(1) then begin
                    V := longword(Apu.Ram) or ((Status.dwTuningAddress + Status.dwTuningSize * DspVoice.SoundSourcePlayBack) and $FFFF);
                    API_MoveMemory(@V, pointer(V), 4);
                    UpdateNumWrite(X + 16, IntToHex(StrData, V shr 8, 2));
                    Z := 3;
                    UpdateNumWrite(X + 13, IntToHex(StrData, V, 2));
                end else begin
                    StrData.dwData[0] := $5656; // 'VV'
                    UpdateNumWrite(X + 16, 2);
                    Z := 3;
                    UpdateNumWrite(X + 13, 2);
                end;
            end else if bytebool(DspVoice.EnvelopeADSR1 and $80) then begin
                // ADSR
                V := (DspVoice.EnvelopeADSR1 shl 8) or DspVoice.EnvelopeADSR2;
                StrData.dwData[0] := $5857; // 'WX'
                UpdateNumWrite(X +  4, 2);
                UpdateNumWrite(X +  7, IntToHex(StrData, (V shr  8) and $F, 1));
                UpdateNumWrite(X +  9, IntToHex(StrData, (V shr 12) and $7, 1));
                UpdateNumWrite(X + 11, IntToHex(StrData, (V shr  5) and $7, 1));
                UpdateNumWrite(X + 13, IntToHex(StrData, V and $1F, 2));
                V := Voice.EnvelopeCurrentMode and $F;
                if V = $A then StrData.dwData[0] := $65 else StrData.dwData[0] := $54; // 'e' or 'T'
                UpdateNumWrite(X +  8, 1);
                if V = $D then StrData.dwData[0] := $66 else StrData.dwData[0] := $54; // 'f' or 'T'
                UpdateNumWrite(X + 10, 1);
                if V = $9 then StrData.dwData[0] := $67 else StrData.dwData[0] := $54; // 'g' or 'T'
                UpdateNumWrite(X + 12, 1);
            end else begin
                // Gain
                V := DspVoice.EnvelopeGain;
                StrData.dwData[0] := $5A59; // 'YZ'
                UpdateNumWrite(X +  4, 2);
                StrData.dwData[0] := $61 + ((V shr 7) and $1); // 'a' or 'b'
                UpdateNumWrite(X +  7, 1);
                if bytebool(V and $80) then begin
                    // Auto
                    UpdateNumWrite(X +  9, IntToHex(StrData, (V shr 6) and $1, 1));
                    UpdateNumWrite(X + 11, IntToHex(StrData, (V shr 5) and $1, 1));
                    UpdateNumWrite(X + 13, IntToHex(StrData, V and $1F, 2));
                    StrData.dwData[0] := $54; // 'T'
                    UpdateNumWrite(X +  8, 1);
                    // MixFlag and $8 = MFLG_OFF は E_REL と等価とみなす
                    V := (Voice.EnvelopeCurrentMode and $F) or (Voice.MixFlag and $8);
                    if (V = $2) or (V = $6) then StrData.dwData[0] := $68 // 'h'
                    else if (V = $0) or (V = $1) then StrData.dwData[0] := $69 // 'i'
                    else StrData.dwData[0] := $54; // 'T'
                    UpdateNumWrite(X + 10, 1);
                    if (V = $2) or (V = $0) then StrData.dwData[0] := $6A // 'j'
                    else if V = $6 then StrData.dwData[0] := $6B // 'k'
                    else if V = $1 then StrData.dwData[0] := $6C // 'l'
                    else StrData.dwData[0] := $54; // 'T'
                    UpdateNumWrite(X + 12, 1);
                end else begin
                    // Direct
                    StrData.dwData[0] := $56; // 'V'
                    UpdateNumWrite(X +  9, 1);
                    UpdateNumWrite(X + 11, 1);
                    UpdateNumWrite(X + 13, IntToHex(StrData, V and $7F, 2));
                    StrData.dwData[0] := $54; // 'T'
                    UpdateNumWrite(X +  8, 1);
                    UpdateNumWrite(X + 10, 1);
                    // MixFlag and $8 = MFLG_OFF は E_REL と等価とみなす
                    V := (Voice.EnvelopeCurrentMode and $F) or (Voice.MixFlag and $8);
                    if V = $7 then StrData.dwData[0] := $6D // 'm'
                    else StrData.dwData[0] := $54; // 'T'
                    UpdateNumWrite(X + 12, 1);
                end;
            end;
            if Status.bBreakButton then begin
                // StrData.dwData[0] := $6E; // 'n'
                // UpdateNumWrite(X + 15, 1);
                // UpdateNumWrite(X + 16, IntToHex(StrData, DspVoice.CurrentOutput, 2));
            end else begin
                StrData.dwData[0] := $54; // 'T'
                UpdateNumWrite(X + 15, 1);
                UpdateNumWrite(X + 16, IntToHex(StrData, DspVoice.CurrentEnvelope, 2));
            end;
        end;
        INFO_CHANNEL_3: for I := 0 to 7 do begin
            // 各チャンネル情報を描画
            X := I div 4 * 25 + 4;
            Y := I mod 4 + 2;
            V := 1 shl I;
            DspVoice := @DspReg.Voice[I];
            UpdateChannelSource(true);
            Voice := @Voices.Voice[I];
            if not longbool(Voice.VolumeMaxLeft) and not longbool(Voice.VolumeMaxRight) then StrData.dwData[0] := $5656 // 'VV'
            else StrData.dwData[0] := $4847; // 'GH'
            UpdateNumWrite(X +  4, 2);
            if not bytebool(DspReg.EchoOn and V) then StrData.dwData[0] := $56 else StrData.dwData[0] := $49; // 'V' or 'I'
            UpdateNumWrite(X +  7, 1);
            if not bytebool(DspReg.PitchModOn and V) then StrData.dwData[0] := $56 else StrData.dwData[0] := $4A; // 'V' or 'J'
            Inc(Z);
            UpdateNumWrite(X +  8, 1);
            if not bytebool(DspReg.NoiseOn and V) then StrData.dwData[0] := $56 else StrData.dwData[0] := $4B; // 'V' or 'K'
            Inc(Z);
            UpdateNumWrite(X +  9, 1);
            if not bytebool(DspReg.KeyOn and V) then StrData.dwData[0] := $56 else StrData.dwData[0] := $4C; // 'V' or 'L'
            Inc(Z);
            UpdateNumWrite(X + 10, 1);
            if not bytebool(DspReg.KeyOff and V) then StrData.dwData[0] := $56 else StrData.dwData[0] := $4D; // 'V' or 'M'
            Inc(Z);
            UpdateNumWrite(X + 11, 1);
            if not bytebool(DspReg.EndWaveform and V) then StrData.dwData[0] := $56 else StrData.dwData[0] := $4E; // 'V' or 'N'
            Inc(Z);
            UpdateNumWrite(X + 12, 1);
            V := Voice.BlockHdr;
            if not longbool(V and $C) then StrData.dwData[0] := $30 else // '0'
            if not longbool(V and $8) then StrData.dwData[0] := $31 else // '1'
            if not longbool(V and $4) then StrData.dwData[0] := $32 else // '2'
            StrData.dwData[0] := $33;                                    // '3'
            Z := 0;
            UpdateNumWrite(X + 15, 1);
            UpdateNumWrite(X + 17, IntToHex(StrData, longword(Voice.BlockHdr) shr 4, 1));
        end;
        INFO_CHANNEL_4: for I := 0 to 7 do begin
            // 各チャンネル情報を描画
            X := I div 4 * 25 + 4;
            Y := I mod 4 + 2;
            DspVoice := @DspReg.Voice[I];
            UpdateChannelSource(true);
            Voice := @Voices.Voice[I];
            UpdateNumWrite(X +  4, IntToHex(StrData, ApuData.SPCSrcAddrs.Src[DspVoice.SoundSourcePlayBack].wStart, 4));
            UpdateNumWrite(X +  9, IntToHex(StrData, ApuData.SPCSrcAddrs.Src[DspVoice.SoundSourcePlayBack].wLoop, 4));
            UpdateNumWrite(X + 14, IntToHex(StrData, longword(Voice.CurrentBlock), 4));
        end;
        INFO_SPC_2: begin
            // SPC レジスタ情報を描画
            SPC700Reg := @ApuData.SPC700Reg;
            Y := 5;
            Z := 0;
            UpdateNumWrite(14, IntToHex(StrData, SPC700Reg.pc, 4));
            if Status.bBreakButton then begin
                UpdateNumWrite(21, IntToStr(StrData, SPC700Reg.ya and $FF, 3));
                UpdateNumWrite(27, IntToStr(StrData, (SPC700Reg.ya shr 8) and $FF, 3));
                UpdateNumWrite(33, IntToStr(StrData, SPC700Reg.x and $FF, 3));
                UpdateNumWrite(40, IntToStr(StrData, SPC700Reg.sp and $FF, 3));
            end else begin
                UpdateNumWrite(22, IntToHex(StrData, SPC700Reg.ya, 4));
                UpdateNumWrite(29, IntToHex(StrData, SPC700Reg.x, 2));
                UpdateNumWrite(35, IntToHex(StrData, SPC700Reg.sp, 2));
                for I := 0 to 7 do StrData.cData[I] := BoolTable[(SPC700Reg.psw[7 - I] and $100) shr 8];
                UpdateNumWrite(39, 8);
            end;
        end;
        INFO_SCRIPT700: begin
            // Script700 情報を描画
            Script700 := @ApuData.Script700;
            Y := 1;
            if Status.bBreakButton then begin
                for I := 0 to 3 do begin
                    Z := I * 3;
                    UpdateNumWrite(I * 3 + 11, IntToStr(StrData, ApuData.SPCApuPort.Port[I], 3));
                end;
                for I := 0 to 3 do begin
                    Z := I * 3;
                    UpdateNumWrite(I * 3 + 32, IntToStr(StrData, ApuData.SPCOutPort.Port[I], 3));
                end;
                Z := 0;
            end else begin
                Z := 0;
                for I := 0 to 3 do begin
                    UpdateNumWrite(I * 3 + 11, IntToHex(StrData, ApuData.SPCApuPort.Port[I], 2));
                    if not longbool(I) and longbool(Script700.cStatusFlag and $C) then StrData.bData[0] := $6F // 'o'
                    else if Script700.dwIntInPort = $80 + I then StrData.bData[0] := $6F // 'o'
                    else StrData.bData[0] := $20; // ' '
                    UpdateNumWrite(I * 3 + 13, 1);
                end;
                for I := 0 to 3 do begin
                    UpdateNumWrite(I * 3 + 32, IntToHex(StrData, ApuData.SPCOutPort.Port[I], 2));
                    if Script700.dwIntOutPort = $80 + I then StrData.bData[0] := $6F // 'o'
                    else StrData.bData[0] := $20; // ' '
                    UpdateNumWrite(I * 3 + 34, 1);
                end;
            end;
            Y := 2;
            for I := 0 to 3 do UpdateNumWrite(I * 9 + 11, IntToHex(StrData, Script700.dwWork[I], 8));
            Y := 3;
            for I := 0 to 3 do UpdateNumWrite(I * 9 + 11, IntToHex(StrData, Script700.dwWork[I + 4], 8));
            Y := 4;
            UpdateNumWrite(11, IntToHex(StrData, Script700.dwCmpParam[0], 8));
            UpdateNumWrite(20, IntToHex(StrData, Script700.dwCmpParam[1], 8));
            UpdateNumWrite(38, IntToHex(StrData, Script700.dwWaitCnt, 8));
            Y := 5;
            UpdateNumWrite(11, IntToHex(StrData, Status.Script700.dwProgSize, 6));
            UpdateNumWrite(23, IntToHex(StrData, Script700.dwPointer, 5));
            UpdateNumWrite(34, IntToHex(StrData, Script700.dwData, 5));
            IntToHex(StrData, Script700.dwStack, 2);
            StrData.cData[2] := BoolTable[Script700.cStatusFlag and $1];
            UpdateNumWrite(43, 3);
        end;
    end;
    // GDI 描画をフラッシュ
    API_GdiFlush();
end;

// ================================================================================
// DropFile - ファイルのドロップ (受け取り)
// ================================================================================
function CWINDOWMAIN.DropFile(dwParam: longword): longword;
var
    I: longint;
    dwCount: longint;
    bAdd: longbool;
    bList: longbool;
    lpFile: pointer;
    dwType: longword;
    dwPathSize: longint;
    dwFileSize: longint;
    hFile: longword;
    cFilePath: array[0..259] of char;
    Win32_Find_Data: TWIN32FINDDATA;
    Point: TPOINT;
begin
    // 初期化
    result := 1;
    // ソート用リストをクリア
    cwSortList.SendMessage(LB_RESETCONTENT, NULL, NULL);
    // ポインタの座標を取得
    API_DragQueryPoint(dwParam, @Point);
    // ドロップされた場所の検出
    if Status.dwScale = 2 then bAdd := Point.x >= LIST_ADD_THRESHOLD
    else bAdd := Point.x >= (LIST_ADD_THRESHOLD * Status.dwScale) shr 1;
    bList := false;
    // ドロップされたファイル数を取得
    dwCount := API_DragQueryFile(dwParam, $FFFFFFFF, NULLPOINTER, NULL);
    // ファイルがドロップされなかった場合、または、ファイル数が 1、かつドロップが禁止されている場合は終了
    if not longbool(dwCount) or (bAdd and (dwCount = 1) and Status.bDropCancel) then begin
        // ドラッグ終了
        API_DragFinish(dwParam);
        // 終了
        exit;
    end;
    // ファイル数が最大値以上の場合は最大値に設定
    if dwCount >= Option.dwListMax then dwCount := Option.dwListMax;
    // バッファを確保
    GetMem(lpFile, 1024);
    // すべてのファイルを確認
    for I := 0 to dwCount - 1 do begin
        // ファイルを取得
        API_ZeroMemory(lpFile, 1024);
        API_DragQueryFile(dwParam, I, lpFile, 260);
        // ファイルの種類を取得
        dwType := GetFileType(lpFile, dwCount = 1, dwCount = 1);
        case dwType of
            FILE_TYPE_SPC: if (dwCount = 1) and not bAdd then SPCLoad(lpFile, true)
                else cwSortList.SendMessage(LB_ADDSTRING, NULL, longword(lpFile));
            FILE_TYPE_LIST_A, FILE_TYPE_LIST_B: if not bList then bList := ListLoad(lpFile, dwType, false);
            FILE_TYPE_FOLDER: begin
                // タイトルを更新
                cwWindowMain.SetCaption(pchar(Concat(TITLE_INFO_HEADER[Status.dwLanguage], TITLE_INFO_FILE_APPEND[Status.dwLanguage],
                    TITLE_INFO_FOOTER[Status.dwLanguage], TITLE_MAIN_HEADER[Status.dwLanguage], DEFAULT_TITLE)));
                // ファイルパスを初期化
                dwPathSize := GetSize(lpFile, 260);
                API_ZeroMemory(@cFilePath[0], 260);
                API_MoveMemory(@cFilePath[0], lpFile, dwPathSize);
                if not IsPathSeparator(ChrToStr(cFilePath), dwPathSize) then begin
                    if longbool(Pos('/', ChrToStr(cFilePath))) then cFilePath[dwPathSize] := '/' else cFilePath[dwPathSize] := '\';
                    Inc(dwPathSize);
                end;
                cFilePath[dwPathSize] := '*';
                // SPC ファイルを検索
                hFile := INVALID_HANDLE_VALUE;
                if IsSafePath(@cFilePath) then hFile := API_FindFirstFile(@cFilePath, @Win32_Find_Data);
                if hFile < INVALID_HANDLE_VALUE then while true do begin
                    if not IsSingleByte(ChrToStr(Win32_Find_Data.cFileName), 1, '.') then begin
                        dwFileSize := GetSize(@Win32_Find_Data.cFileName[0], 260);
                        if dwPathSize + dwFileSize < 260 then begin
                            API_MoveMemory(@cFilePath[dwPathSize], @Win32_Find_Data.cFileName[0], dwFileSize);
                            API_ZeroMemory(@cFilePath[dwPathSize + dwFileSize], 260 - dwPathSize - dwFileSize);
                            if GetFileType(@cFilePath, false, false) = FILE_TYPE_SPC then
                                cwSortList.SendMessage(LB_ADDSTRING, NULL, longword(@cFilePath));
                        end;
                    end;
                    if not API_FindNextFile(hFile, @Win32_Find_Data) then begin
                        API_FindClose(hFile);
                        break;
                    end;
                end;
                // タイトルを更新
                UpdateTitle(NULL);
            end;
            FILE_TYPE_SCRIPT700: if dwCount = 1 then ReloadScript700(lpFile);
        end;
    end;
    // バッファを解放
    FreeMem(lpFile, 1024);
    // ドラッグ終了
    API_DragFinish(dwParam);
    // SPC ファイルをプレイリストに登録
    AppendList();
end;

// ================================================================================
// GetFileType - ファイルタイプ取得
// ================================================================================
function CWINDOWMAIN.GetFileType(lpFile: pointer; bShowMsg: longbool; bScript700: longbool): longword;
var
    bSafe: longbool;
    hFile: longword;
    dwReadSize: longword;
    cBuffer: array[0..63] of char;
    cSPCHeader: array[0..SPC_FILE_HEADER_LEN - 1] of char;
    cListHeaderA: array[0..LIST_FILE_HEADER_A_LEN - 1] of char;
    cListHeaderB: array[0..LIST_FILE_HEADER_B_LEN - 1] of char;
begin
    // 初期化
    result := FILE_TYPE_NOTEXIST;
    repeat
        // パスの安全性を確認
        bSafe := IsSafePath(lpFile);
        // フォルダが存在する場合はループを抜ける
        if bSafe and Exists(lpFile, 0) then begin
            result := FILE_TYPE_FOLDER;
            break;
        end;
        // ファイルが存在しない場合はループを抜ける
        if bSafe and not Exists(lpFile, $FFFFFFFF) then break;
        // 初期化
        result := FILE_TYPE_NOTREAD;
        // ファイルをオープン
        hFile := INVALID_HANDLE_VALUE;
        if bSafe then hFile := API_CreateFile(lpFile, GENERIC_READ, FILE_SHARE_READ, NULLPOINTER, OPEN_EXISTING,
            FILE_ATTRIBUTE_NORMAL or FILE_FLAG_SEQUENTIAL_SCAN, NULL);
        // ファイルのオープンに失敗した場合はループを抜ける
        if hFile = INVALID_HANDLE_VALUE then break;
        // 初期化
        result := FILE_TYPE_UNKNOWN;
        // ファイルの拡張子を取得
        if bScript700 and (
               IsExt(lpFile, Concat('.', SCRIPT700_FILETYPE))
            or IsExt(lpFile, Concat('.', SCRIPT7SE_FILETYPE))
            or IsExt(lpFile, Concat('.', SCRIPT700TXT_FILETYPE))
            or IsExt(lpFile, Concat('.', SCRIPT7SETXT_FILETYPE))
        ) then result := FILE_TYPE_SCRIPT700;
        // ファイルをロード
        API_ZeroMemory(@cBuffer[0], 64);
        API_ReadFile(hFile, @cBuffer[0], 64, @dwReadSize, NULLPOINTER);
        // バッファをコピー
        API_MoveMemory(@cSPCHeader[0], @cBuffer[0], SPC_FILE_HEADER_LEN);
        API_MoveMemory(@cListHeaderA[0], @cBuffer[0], LIST_FILE_HEADER_A_LEN);
        API_MoveMemory(@cListHeaderB[0], @cBuffer[0], LIST_FILE_HEADER_B_LEN);
        // ファイルの種類を取得
        if ChrToStr(cSPCHeader) = SPC_FILE_HEADER then result := FILE_TYPE_SPC;
        if ChrToStr(cListHeaderA) = LIST_FILE_HEADER_A then result := FILE_TYPE_LIST_A;
        if ChrToStr(cListHeaderB) = LIST_FILE_HEADER_B then result := FILE_TYPE_LIST_B;
        // ファイルをクローズ
        API_CloseHandle(hFile);
    until true;
    // ファイル形式が不明の場合はメッセージを表示
    if bShowMsg then case result of
        FILE_TYPE_NOTEXIST, FILE_TYPE_NOTREAD, FILE_TYPE_UNKNOWN: ShowErrMsg(200 + result);
    end;
end;

// ================================================================================
// GetID666Format - ID666 フォーマットタイプ取得
// ================================================================================
procedure CWINDOWMAIN.GetID666Format(var Hdr: TSPCHDR);
var
    Bin: array[0..255] of byte;
begin
    // 初期化
    API_MoveMemory(@Bin[0], @Hdr, 256);
    Hdr.TagFormat := ID666_UNKNOWN;
    // ID666 フォーマットの種類を取得
    if (Bin[$23] = $1A) or (
        // PHASE 1
        bytebool(((Bin[$2E] or Bin[$4E] or Bin[$6E] or Bin[$7E] or Bin[$B0] or Bin[$B1]) and $E0) or Bin[$24] or Bin[$9E] or Bin[$A9] or Bin[$AC]
            or Bin[$D1] or Bin[$D2])) then begin
        Hdr.TagFormat := ID666_TEXT;
        // PHASE 2
        if ((Bin[$A2] or Bin[$A3] or Bin[$A4] or Bin[$A5] or Bin[$A6] or Bin[$A7] or Bin[$A8] or Bin[$AB] or Bin[$AF]) < $20)
        // PHASE 3
        and ((Bin[$B0] >= $20) or (Bin[$B1] < $20))
        // PHASE 4
        and (Bin[$D2] < $30) then Hdr.TagFormat := ID666_BINARY;
    end;
end;

// ================================================================================
// IsExt - パスの拡張子を確認
// ================================================================================
function CWINDOWMAIN.IsExt(lpFile: pointer; const sExt: string): longbool;
var
    I: longint;
    dwSize: longword;
    dwExtSize: longword;
    cBuffer: array of char;
    V: byte;
begin
    // 初期化
    result := false;
    // バッファサイズが拡張子サイズ未満の場合は失敗
    dwSize := GetSize(lpFile, 1024);
    dwExtSize := Length(sExt);
    if dwSize < dwExtSize then exit;
    // 拡張子部分をコピー
    SetLength(cBuffer, dwExtSize);
{$IFDEF FREEPASCAL}
    API_MoveMemory(@cBuffer[0], lpFile + dwSize - dwExtSize, dwExtSize);
{$ELSE}
    API_MoveMemory(@cBuffer[0], pointer(longword(lpFile) + dwSize - dwExtSize), dwExtSize);
{$ENDIF}
    // 大文字に変換
    for I := 0 to dwExtSize - 1 do begin
        V := byte(cBuffer[I]);
        if (V >= $61) and (V <= $7A) then cBuffer[I] := char(V - $20);
    end;
    // 一致判定
{$IFDEF FREEPASCAL}
    result := ChrToStr(cBuffer) = sExt;
{$ELSE}
    // NOTE: Boland Delphi の場合、char の動的配列を string にキャストする場合は、
    // 直接 string() を使用する
    result := string(cBuffer) = sExt;
{$ENDIF}
end;

// ================================================================================
// IsSafePath - パスの安全性を確認
// ================================================================================
function CWINDOWMAIN.IsSafePath(lpFile: pointer): longbool;
var
    dwSize: longword;
    dwValue: ^longword;
begin
    // 初期化
    result := false;
    // バッファサイズが 4 バイト未満の場合は失敗
    dwSize := GetSize(lpFile, 4);
    if dwSize < 4 then exit;
    // \\.\ から始まる場合は失敗
    dwValue := lpFile;
    if dwValue^ = $5C2E5C5C then exit;
    // 成功
    result := true;
end;

// ================================================================================
// ListAdd - プレイリスト追加
// ================================================================================
procedure CWINDOWMAIN.ListAdd(dwAuto: longword);
var
    dwIndex: longint;
    dwCount: longint;
    dwSelect: longint;
    bAdd: longbool;
    lpTitle: pointer;
begin
    // SPC が開かれていない場合は終了
    if not Status.bOpen then exit;
    // プレイリストのアイテム数を取得
    dwCount := cwPlayList.SendMessage(LB_GETCOUNT, NULL, NULL);
    // プレイリストのアイテム数が最大値以上の場合は終了
    if dwCount >= Option.dwListMax then exit;
    // 選択されているアイテムを取得
    dwIndex := cwPlayList.SendMessage(LB_GETCURSEL, NULL, NULL);
    // 追加か挿入を取得
    case dwAuto of
        1: bAdd := true;
        2: bAdd := not longbool(dwCount);
        else bAdd := not Status.bShiftButton or not longbool(dwCount);
    end;
    if bAdd then dwSelect := dwCount else dwSelect := dwIndex;
    // ファイルを追加
    if bAdd then cwFileList.SendMessage(LB_ADDSTRING, NULL, longword(Status.lpSPCFile))
    else cwFileList.SendMessage(LB_INSERTSTRING, dwIndex, longword(Status.lpSPCFile));
    // タイトルを取得
    GetMem(lpTitle, 33);
    API_ZeroMemory(lpTitle, 33);
    API_MoveMemory(lpTitle, @Spc.Hdr.Title[0], 32);
    // プレイリストに追加
    if bAdd then begin
        cwPlayList.SendMessage(LB_ADDSTRING, NULL, longword(lpTitle));
        cwPlayList.SendMessage(LB_SETITEMDATA, dwCount, NULL);
    end else begin
        cwPlayList.SendMessage(LB_INSERTSTRING, dwIndex, longword(lpTitle));
        cwPlayList.SendMessage(LB_SETITEMDATA, dwIndex, NULL);
    end;
    FreeMem(lpTitle, 33);
    // プレイリストのアイテムを選択
    cwPlayList.SendMessage(LB_SETCURSEL, dwSelect, NULL);
    // メニューを更新
    UpdateMenu();
end;

// ================================================================================
// ListClear - プレイリストクリア
// ================================================================================
procedure CWINDOWMAIN.ListClear(bQuiet: longbool);
begin
    // 確認メッセージを表示
    if not bQuiet then if cwWindowMain.MessageBox(pchar(WARN_CLEAR_PLAYLIST[Status.dwLanguage]), pchar(DEFAULT_TITLE),
        MB_ICONQUESTION or MB_YESNO or MB_DEFBUTTON2) <> IDYES then exit;
    // プレイリストをすべてクリア
    cwFileList.SendMessage(LB_RESETCONTENT, NULL, NULL);
    cwPlayList.SendMessage(LB_RESETCONTENT, NULL, NULL);
    // メニューを更新
    UpdateMenu();
end;

// ================================================================================
// ListDelete - プレイリスト削除
// ================================================================================
procedure CWINDOWMAIN.ListDelete();
var
    dwIndex: longint;
    dwTopIndex: longint;
    dwCount: longint;
begin
    // プレイリストのアイテム数を取得
    dwCount := cwPlayList.SendMessage(LB_GETCOUNT, NULL, NULL);
    // プレイリストにアイテムが登録されていない場合は終了
    if not longbool(dwCount) then exit;
    // 選択されているアイテムを取得
    dwIndex := cwPlayList.SendMessage(LB_GETCURSEL, NULL, NULL);
    dwTopIndex := cwPlayList.SendMessage(LB_GETTOPINDEX, NULL, NULL);
    // ファイルとタイトルを削除
    cwFileList.SendMessage(LB_DELETESTRING, dwIndex, NULL);
    cwPlayList.SendMessage(LB_DELETESTRING, dwIndex, NULL);
    Dec(dwCount);
    // プレイリストのアイテムを選択
    if dwIndex >= dwCount then dwIndex := dwCount - 1;
    cwPlayList.SendMessage(LB_SETTOPINDEX, dwTopIndex, NULL);
    cwPlayList.SendMessage(LB_SETCURSEL, dwIndex, NULL);
    // メニューを更新
    UpdateMenu();
end;

// ================================================================================
// ListDown - プレイリストの項目を下へ移動
// ================================================================================
procedure CWINDOWMAIN.ListDown();
var
    lpFile: pointer;
    lpTitle: pointer;
    dwIndex: longint;
    dwCount: longint;
    dwItemData: longword;
begin
    // プレイリストのアイテム数を取得
    dwCount := cwPlayList.SendMessage(LB_GETCOUNT, NULL, NULL);
    // プレイリストにアイテムが登録されていない場合は終了
    if not longbool(dwCount) then exit;
    // 選択されているアイテムを取得
    dwIndex := cwPlayList.SendMessage(LB_GETCURSEL, NULL, NULL);
    // 一番下のアイテムが選択されている場合は終了
    if dwIndex >= dwCount - 1 then exit;
    // バッファを確保
    GetMem(lpFile, 1024);
    GetMem(lpTitle, 33);
    // ファイルとタイトルを取得
    API_ZeroMemory(lpFile, 1024);
    cwFileList.SendMessage(LB_GETTEXT, dwIndex, longword(lpFile));
    API_ZeroMemory(lpTitle, 33);
    cwPlayList.SendMessage(LB_GETTEXT, dwIndex, longword(lpTitle));
    dwItemData := cwPlayList.SendMessage(LB_GETITEMDATA, dwIndex, NULL);
    // カーソルを設定
    Inc(dwIndex);
    cwPlayList.SendMessage(LB_SETCURSEL, dwIndex, NULL);
    // 削除
    Dec(dwIndex);
    cwFileList.SendMessage(LB_DELETESTRING, dwIndex, NULL);
    cwPlayList.SendMessage(LB_DELETESTRING, dwIndex, NULL);
    // 挿入
    Inc(dwIndex);
    cwFileList.SendMessage(LB_INSERTSTRING, dwIndex, longword(lpFile));
    cwPlayList.SendMessage(LB_INSERTSTRING, dwIndex, longword(lpTitle));
    cwPlayList.SendMessage(LB_SETITEMDATA, dwIndex, dwItemData);
    // カーソルを設定
    cwPlayList.SendMessage(LB_SETCURSEL, dwIndex, NULL);
    // バッファを解放
    FreeMem(lpFile, 1024);
    FreeMem(lpTitle, 33);
    // メニューを更新
    UpdateMenu();
end;

// ================================================================================
// ListLoad - プレイリストを開く
// ================================================================================
function CWINDOWMAIN.ListLoad(lpFile: pointer; dwType: longword; bShift: longbool): longbool;
var
    I: longint;
    hFile: longword;
    dwListNum: longint;
    dwReadSize: longword;
    dwSize: longword;
    dwSizeFile: longword;
    dwSizeTitle: longword;
    dwTopIndex: longint;
    dwIndex: longint;
    lpListFile: pointer;
    lpTitle: pointer;
    cListHeader: array[0..63] of char;

procedure ConvertPath();
var
    C1: ^byte;
    C2: ^byte;
    wValue: ^word;
begin
    wValue := lpListFile;
    if wValue^ <> $5C2E then exit; // .\
    C1 := lpListFile;
    Inc(C1, Status.lpCurrentSize);
    C2 := lpListFile;
    Inc(C2, 2);
    API_MoveMemory(C1, C2, 1023 - Status.lpCurrentSize);
    API_MoveMemory(lpListFile, Status.lpCurrentPath, Status.lpCurrentSize);
end;

begin
    repeat
        // ファイルをオープン
        hFile := INVALID_HANDLE_VALUE;
        if IsSafePath(lpFile) then hFile := API_CreateFile(lpFile, GENERIC_READ, FILE_SHARE_READ, NULLPOINTER, OPEN_EXISTING,
            FILE_ATTRIBUTE_NORMAL or FILE_FLAG_SEQUENTIAL_SCAN, NULL);
        // ファイルのオープンに失敗した場合はループを抜ける
        if hFile = INVALID_HANDLE_VALUE then break;
        // プレイリストをクリア
        cwFileList.SendMessage(LB_RESETCONTENT, NULL, NULL);
        cwPlayList.SendMessage(LB_RESETCONTENT, NULL, NULL);
        // プレイリストのアイテム数と現在の場所を取得
        dwListNum := 0;
        dwTopIndex := 0;
        dwIndex := 0;
        dwReadSize := 0;
        case dwType of
            FILE_TYPE_LIST_A: begin
                // ヘッダを取得
                API_ReadFile(hFile, @cListHeader, LIST_FILE_HEADER_A_LEN, @dwReadSize, NULLPOINTER);
                // ファイルのロードに失敗した場合はループを抜ける
                if not longbool(dwReadSize) then break;
                // アイテム数を取得
                API_ReadFile(hFile, @dwListNum, 4, @dwReadSize, NULLPOINTER);
                // ファイルのロードに失敗した場合はループを抜ける
                if not longbool(dwReadSize) then break;
            end;
            FILE_TYPE_LIST_B: begin
                // ヘッダを取得
                API_ReadFile(hFile, @cListHeader, LIST_FILE_HEADER_B_LEN, @dwReadSize, NULLPOINTER);
                // ファイルのロードに失敗した場合はループを抜ける
                if not longbool(dwReadSize) then break;
                // アイテム数を取得
                API_ReadFile(hFile, @dwListNum, 2, @dwReadSize, NULLPOINTER);
                // ファイルのロードに失敗した場合はループを抜ける
                if not longbool(dwReadSize) then break;
                dwListNum := dwListNum and $FFFF;
                // プレイリストのトップ位置を取得
                API_ReadFile(hFile, @dwTopIndex, 2, @dwReadSize, NULLPOINTER);
                // ファイルのロードに失敗した場合はループを抜ける
                if not longbool(dwReadSize) then break;
                dwTopIndex := dwTopIndex and $FFFF;
                // プレイリストの選択位置を取得
                API_ReadFile(hFile, @dwIndex, 2, @dwReadSize, NULLPOINTER);
                // ファイルのロードに失敗した場合はループを抜ける
                if not longbool(dwReadSize) then break;
                dwIndex := dwIndex and $FFFF;
            end;
        end;
        // プレイリストにアイテムが登録されていない場合はループを抜ける
        if not longbool(dwListNum) then break;
        // アイテム数の最大値を設定
        if dwListNum > Option.dwListMax then dwListNum := Option.dwListMax;
        // 再描画禁止
        cwPlayList.SendMessage(WM_SETREDRAW, 0, NULL);
        // バッファを確保
        GetMem(lpListFile, 1024);
        GetMem(lpTitle, 33);
        // プレイリストを取得
        for I := 0 to dwListNum - 1 do begin
            dwSizeFile := 260;
            dwSizeTitle := 32;
            case dwType of
                FILE_TYPE_LIST_B: begin
                    // データサイズを取得
                    API_ReadFile(hFile, @dwSize, 2, @dwReadSize, NULLPOINTER);
                    // ファイルのロードに失敗した場合はループを抜ける
                    if not longbool(dwReadSize) then break;
                    dwSizeFile := dwSize and $3FF;
                    dwSizeTitle := (dwSize shr 10) and $3F;
                    if dwSizeTitle > 32 then dwSizeTitle := 32;
                end;
            end;
            // ファイルのロードに失敗した場合はループを抜ける
            if not longbool(dwReadSize) then break;
            // ファイルパスを取得
            API_ZeroMemory(lpListFile, 1024);
            API_ReadFile(hFile, lpListFile, dwSizeFile, @dwReadSize, NULLPOINTER);
            // ファイルのロードに失敗した場合はループを抜ける
            if not longbool(dwReadSize) then break;
            // タイトルを取得
            API_ZeroMemory(lpTitle, 33);
            API_ReadFile(hFile, lpTitle, dwSizeTitle, @dwReadSize, NULLPOINTER);
            // ファイルのロードに失敗した場合はループを抜ける
            if not longbool(dwReadSize) then break;
            // プレイリストに追加
            cwPlayList.SendMessage(LB_ADDSTRING, NULL, longword(lpTitle));
            cwPlayList.SendMessage(LB_SETITEMDATA, I, NULL);
            ConvertPath();
            cwFileList.SendMessage(LB_ADDSTRING, NULL, longword(lpListFile));
        end;
        // バッファを解放
        FreeMem(lpListFile, 1024);
        FreeMem(lpTitle, 33);
        // 再描画許可
        cwPlayList.SendMessage(WM_SETREDRAW, 1, NULL);
        cwPlayList.Invalidate();
        // ファイルのロードに成功した場合はプレイリストのアイテムを選択
        if longbool(dwReadSize) then begin
            if bShift then cwPlayList.SendMessage(LB_SETITEMDATA, dwIndex, 1);
            cwPlayList.SendMessage(LB_SETCURSEL, dwIndex, NULL);
            cwPlayList.SendMessage(LB_SETTOPINDEX, dwTopIndex, NULL);
        end;
    until true;
    // ファイルをクローズ
    if hFile <> INVALID_HANDLE_VALUE then API_CloseHandle(hFile);
    // メニューを更新
    UpdateMenu();
    // 成功
    result := true;
end;

// ================================================================================
// ListNextPlay - プレイリストの次を開く
// ================================================================================
procedure CWINDOWMAIN.ListNextPlay(dwOrder: longword; dwFlag: longword);
var
    I: longword;
    J: longword;
    K: longword;
    L: longword;
    X: longint;
    dwCount: longint;
    dwIndex: longint;
begin
    // 演奏順序を取得
    case dwOrder of
        PLAY_ORDER_STOP: begin
            // 演奏停止
            SPCStop(false);
            exit;
        end;
        PLAY_ORDER_REPEAT: begin
            // リピート
            SPCStop(true);
            exit;
        end;
    end;
    // プレイリストのアイテム数を取得
    dwCount := cwPlayList.SendMessage(LB_GETCOUNT, NULL, NULL);
    case dwCount of
        0: begin
            // 演奏停止
            SPCStop(false);
            exit;
        end;
        1: begin
            // 演奏開始
            ListPlay(dwOrder, 0, NULL);
            exit;
        end;
    end;
    // 次の曲を選択
    dwIndex := 0;
    J := 0;
    while true do begin
        I := 0;
        case dwOrder of
            PLAY_ORDER_FIRST: begin
                // 最初から
                dwIndex := 0;
                break;
            end;
            PLAY_ORDER_LAST: begin
                // 最後から
                dwIndex := dwCount - 1;
                break;
            end;
            PLAY_ORDER_RANDOM: begin
                // ランダム
                dwIndex := LIST_PLAY_INDEX_RANDOM;
                break;
            end;
            PLAY_ORDER_NEXT: begin
                // 最後に演奏されたインデックスを取得
                dwIndex := dwCount - 1;
                K := 0;
                for X := 0 to dwCount - 1 do begin
                    L := cwPlayList.SendMessage(LB_GETITEMDATA, X, NULL);
                    if L > K then begin
                        dwIndex := X;
                        K := L;
                    end;
                end;
                // 次のインデックスを選択
                if dwIndex = dwCount - 1 then dwIndex := 0 else Inc(dwIndex);
            end;
            PLAY_ORDER_PREVIOUS: begin
                // 最後に演奏されたインデックスを取得
                dwIndex := 0;
                K := 0;
                for X := 0 to dwCount - 1 do begin
                    L := cwPlayList.SendMessage(LB_GETITEMDATA, X, NULL);
                    if L > K then begin
                        dwIndex := X;
                        K := L;
                    end;
                end;
                // 前のインデックスを選択
                if dwIndex = 0 then dwIndex := dwCount - 1 else Dec(dwIndex);
            end;
            PLAY_ORDER_SHUFFLE: begin
                // テンポラリ用リストをクリア
                cwTempList.SendMessage(LB_RESETCONTENT, NULL, NULL);
                // 未演奏のインデックスとフラグの最小値、最大値を記録
                dwIndex := 0;
                K := 0;
                L := $FFFFFFFF;
                for X := 0 to dwCount - 1 do begin
                    J := cwPlayList.SendMessage(LB_GETITEMDATA, X, NULL);
                    if not longbool(J) then begin
                        cwTempList.SendMessage(LB_ADDSTRING, NULL, longword(pchar('TEMP')));
                        cwTempList.SendMessage(LB_SETITEMDATA, dwIndex, X);
                        Inc(dwIndex);
                    end;
                    if K < J then K := J;
                    if L > J then L := J;
                end;
                // 演奏ファイルを決定
                if longbool(dwIndex) then begin
                    dwIndex := cwTempList.SendMessage(LB_GETITEMDATA, Trunc(Random(dwIndex)), NULL);
                    J := K + 1;
                end else begin
                    for X := 0 to dwCount - 1 do begin
                        J := cwPlayList.SendMessage(LB_GETITEMDATA, X, NULL) - L;
                        if longbool(J) then cwPlayList.SendMessage(LB_SETITEMDATA, X, J)
                        else dwIndex := X;
                    end;
                    J := K - L + 1;
                end;
                // テンポラリ用リストをクリア
                cwTempList.SendMessage(LB_RESETCONTENT, NULL, NULL);
            end;
        end;
        // 処理が成功した場合はループを抜ける
        if not longbool(I) then break;
        // フラグを設定
        for X := 0 to dwCount - 1 do cwPlayList.SendMessage(LB_SETITEMDATA, X, NULL);
    end;
    // 演奏開始
    ListPlay(dwOrder, dwIndex, J or dwFlag);
end;

// ================================================================================
// ListPlay - プレイリストの読み込み
// ================================================================================
function CWINDOWMAIN.ListPlay(dwOrder: longword; dwIndex: longint; dwFlag: longword): longint;
var
    I: longint;
    dwTopIndex: longint;
    dwCount: longint;
    lpFile: pointer;
begin
    // 初期化
    result := -1;
    // プレイリストのアイテム数を取得
    dwCount := cwPlayList.SendMessage(LB_GETCOUNT, NULL, NULL);
    // プレイリストが選択されていない場合は終了
    if not longbool(dwCount) then exit;
    // バッファを確保
    GetMem(lpFile, 1024);
    // ファイルを取得
    API_ZeroMemory(lpFile, 1024);
    dwTopIndex := cwPlayList.SendMessage(LB_GETCURSEL, NULL, NULL);
    case dwIndex of
        LIST_PLAY_INDEX_SELECTED: result := dwTopIndex;
        LIST_PLAY_INDEX_RANDOM: result := Trunc(Random(dwCount));
        else result := dwIndex;
    end;
    cwFileList.SendMessage(LB_GETTEXT, result, longword(lpFile));
    // プレイリストのアイテムを選択する場合
    if longbool(dwFlag and LIST_NEXT_PLAY_SELECT) then begin
        // プレイリストのトップを設定
        if longbool(dwFlag and LIST_NEXT_PLAY_CENTER) then begin
            dwIndex := cwPlayList.SendMessage(LB_GETTOPINDEX, NULL, NULL);
            if result < dwTopIndex then begin
                dwTopIndex := result - 3;
                if dwTopIndex < 0 then dwTopIndex := 0;
                if dwTopIndex < dwIndex then cwPlayList.SendMessage(LB_SETTOPINDEX, dwTopIndex, NULL);
            end else if result > dwTopIndex then begin
                dwTopIndex := result - 6;
                if dwTopIndex < 0 then dwTopIndex := 0;
                if dwTopIndex > dwIndex then cwPlayList.SendMessage(LB_SETTOPINDEX, dwTopIndex, NULL);
            end;
        end;
        // プレイリストのアイテムを選択
        cwPlayList.SendMessage(LB_SETCURSEL, result, NULL);
        // メニューを更新
        UpdateMenu();
    end;
    // 演奏済みフラグを初期化
    dwFlag := dwFlag and $FFFF;
    if not longbool(dwFlag) then begin
        for I := 0 to dwCount - 1 do cwPlayList.SendMessage(LB_SETITEMDATA, I, NULL);
        Inc(dwFlag);
    end;
    // 演奏済みフラグを設定
    cwPlayList.SendMessage(LB_SETITEMDATA, result, dwFlag);
    // SPC をロード
    if GetFileType(lpFile, true, false) = FILE_TYPE_SPC then SPCLoad(lpFile, true);
    // バッファを解放
    FreeMem(lpFile, 1024);
end;

// ================================================================================
// ListSave - プレイリストの保存
// ================================================================================
function CWINDOWMAIN.ListSave(lpFile: pointer; bShift: longbool): longbool;
var
    I: longint;
    hFile: longword;
    dwListNum: longint;
    dwWriteSize: longword;
    dwSize: longword;
    dwSizeFile: longword;
    dwSizeTitle: longword;
    lpBuffer: pointer;
    lpListFile: pointer;
    lpTitle: pointer;

procedure ConvertPath();
var
    J: longword;
    C1: ^byte;
    C2: ^byte;
    wValue: word;
begin
    API_MoveMemory(lpBuffer, lpListFile, 1024);
    C1 := Status.lpCurrentPath;
    C2 := lpBuffer;
    for J := 0 to 1023 do begin
        if (C1^ >= $41) and (C1^ <= $5A) then C1^ := C1^ or $20;
        if (C2^ >= $41) and (C2^ <= $5A) then C2^ := C2^ or $20;
        if longbool(C1^) then begin
            if C1^ = C2^ then begin
                Inc(C1);
                Inc(C2);
                continue;
            end else begin
                exit;
            end;
        end;
        C1 := lpListFile;
        Inc(C1, 2);
        C2 := lpListFile;
        Inc(C2, J);
        API_MoveMemory(C1, C2, 1023 - J);
        wValue := $5C2E; // .\
        API_MoveMemory(lpListFile, @wValue, 2);
        exit;
    end;
end;

begin
    // 初期化
    result := false;
    // ファイルをオープン
    hFile := INVALID_HANDLE_VALUE;
    if IsSafePath(lpFile) then hFile := API_CreateFile(lpFile, GENERIC_WRITE, FILE_SHARE_READ, NULLPOINTER, CREATE_ALWAYS,
        FILE_ATTRIBUTE_NORMAL or FILE_FLAG_SEQUENTIAL_SCAN, NULL);
    // ファイルのオープンに失敗した場合は終了
    if hFile = INVALID_HANDLE_VALUE then exit;
    // ファイルのヘッダを保存
    lpTitle := pchar(LIST_FILE_HEADER_B);
    dwSize := LIST_FILE_HEADER_B_LEN;
    API_WriteFile(hFile, lpTitle, dwSize, @dwWriteSize, NULLPOINTER);
    // プレイリストのアイテム数を取得
    dwListNum := cwPlayList.SendMessage(LB_GETCOUNT, NULL, NULL);
    // プレイリストのアイテム数と現在の場所を保存
    dwSize := 0;
    API_WriteFile(hFile, @dwListNum, 2, @dwWriteSize, NULLPOINTER);
    if bShift then dwSize := cwPlayList.SendMessage(LB_GETTOPINDEX, NULL, NULL);
    API_WriteFile(hFile, @dwSize, 2, @dwWriteSize, NULLPOINTER);
    if bShift then dwSize := cwPlayList.SendMessage(LB_GETCURSEL, NULL, NULL);
    API_WriteFile(hFile, @dwSize, 2, @dwWriteSize, NULLPOINTER);
    // プレイリストにアイテムが登録されている場合
    if longbool(dwListNum) then begin
        // バッファを確保
        GetMem(lpBuffer, 1024);
        GetMem(lpListFile, 1024);
        GetMem(lpTitle, 33);
        // プレイリストを保存
        for I := 0 to dwListNum - 1 do begin
            API_ZeroMemory(lpListFile, 1024);
            cwFileList.SendMessage(LB_GETTEXT, I, longword(lpListFile));
            API_ZeroMemory(lpTitle, 33);
            cwPlayList.SendMessage(LB_GETTEXT, I, longword(lpTitle));
            ConvertPath();
            dwSizeFile := GetSize(lpListFile, 1023);
            dwSizeTitle := GetSize(lpTitle, 32);
            dwSize := dwSizeFile or (dwSizeTitle shl 10);
            API_WriteFile(hFile, @dwSize, 2, @dwWriteSize, NULLPOINTER);
            API_WriteFile(hFile, lpListFile, dwSizeFile, @dwWriteSize, NULLPOINTER);
            API_WriteFile(hFile, lpTitle, dwSizeTitle, @dwWriteSize, NULLPOINTER);
        end;
        // バッファを解放
        FreeMem(lpBuffer, 1024);
        FreeMem(lpListFile, 1024);
        FreeMem(lpTitle, 33);
    end;
    // ファイルをクローズ
    API_CloseHandle(hFile);
    // 成功
    result := true;
end;

// ================================================================================
// ListUp - プレイリストの項目を上へ移動
// ================================================================================
procedure CWINDOWMAIN.ListUp();
var
    lpFile: pointer;
    lpTitle: pointer;
    dwIndex: longint;
    dwCount: longint;
    dwItemData: longword;
begin
    // プレイリストのアイテム数を取得
    dwCount := cwPlayList.SendMessage(LB_GETCOUNT, NULL, NULL);
    // プレイリストにアイテムが登録されていない場合は終了
    if not longbool(dwCount) then exit;
    // 選択されているアイテムを取得
    dwIndex := cwPlayList.SendMessage(LB_GETCURSEL, NULL, NULL);
    // 一番上のアイテムが選択されている場合は終了
    if dwIndex <= 0 then exit;
    // バッファを確保
    GetMem(lpFile, 1024);
    GetMem(lpTitle, 33);
    // ファイルとタイトルを取得
    API_ZeroMemory(lpFile, 1024);
    cwFileList.SendMessage(LB_GETTEXT, dwIndex, longword(lpFile));
    API_ZeroMemory(lpTitle, 33);
    cwPlayList.SendMessage(LB_GETTEXT, dwIndex, longword(lpTitle));
    dwItemData := cwPlayList.SendMessage(LB_GETITEMDATA, dwIndex, NULL);
    // カーソルを設定
    Dec(dwIndex);
    cwPlayList.SendMessage(LB_SETCURSEL, dwIndex, NULL);
    // 削除
    Inc(dwIndex);
    cwFileList.SendMessage(LB_DELETESTRING, dwIndex, NULL);
    cwPlayList.SendMessage(LB_DELETESTRING, dwIndex, NULL);
    // 挿入
    Dec(dwIndex);
    cwFileList.SendMessage(LB_INSERTSTRING, dwIndex, longword(lpFile));
    cwPlayList.SendMessage(LB_INSERTSTRING, dwIndex, longword(lpTitle));
    cwPlayList.SendMessage(LB_SETITEMDATA, dwIndex, dwItemData);
    // カーソルを設定
    cwPlayList.SendMessage(LB_SETCURSEL, dwIndex, NULL);
    // バッファを解放
    FreeMem(lpFile, 1024);
    FreeMem(lpTitle, 33);
    // メニューを更新
    UpdateMenu();
end;

// ================================================================================
// LoadScript700 - Script700 ファイルの読み込み
// ================================================================================
function CWINDOWMAIN.LoadScript700(lpFile: pointer; dwAddr: longword): longbool;
var
    hFile: longword;
    dwSize: longword;
    dwHigh: longword;
    dwReadSize: longword;
    lpBuffer: pointer;
begin
    // 初期化
    result := false;
    // ファイルをオープン
    hFile := INVALID_HANDLE_VALUE;
    if IsSafePath(lpFile) then hFile := API_CreateFile(lpFile, GENERIC_READ, FILE_SHARE_READ, NULLPOINTER, OPEN_EXISTING,
        FILE_ATTRIBUTE_NORMAL or FILE_FLAG_SEQUENTIAL_SCAN, NULL);
    // ファイルのオープンに失敗した場合は終了
    if hFile = INVALID_HANDLE_VALUE then exit;
    // ファイルサイズを取得
    dwSize := API_GetFileSize(hFile, @dwHigh);
    // ファイルサイズが範囲内の場合
    if longbool(dwSize) and not longbool(dwSize and $FF000000) and not longbool(dwHigh) then begin
        // バッファを確保
        GetMem(lpBuffer, dwSize + 1);
        // バッファを初期化
        API_ZeroMemory(lpBuffer, dwSize + 1);
        // バッファに格納
        API_ReadFile(hFile, lpBuffer, dwSize, @dwReadSize, NULLPOINTER);
        // Script700 をコンパイル
        if dwAddr = SCRIPT700_TEXT then Status.Script700.dwProgSize := Apu.SetScript700(lpBuffer)
        else Status.Script700.dwProgSize := Apu.SetScript700Data(dwAddr, lpBuffer, dwSize);
        // バッファを解放
        FreeMem(lpBuffer, dwSize + 1);
        // 成功
        result := true;
    end;
    // ファイルをクローズ
    API_CloseHandle(hFile);
end;

// ================================================================================
// MoveWindowScreenSide - ウィンドウ位置の調整
// ================================================================================
procedure CWINDOWMAIN.MoveWindowScreenSide();
var
    bWin8: longbool;
    bWin10: longbool;
    hMonitor: longword;
    dwBorder: longint;
    dwWidth: longint;
    dwHeight: longint;
    MonitorInfo: TMONITORINFO;
    KeyState: TKEYSTATE;
    WindowRect: TRECT;
    ScreenRect: TRECT;

function isEnabledAero(): longbool;
var
    hDLL: longword;
    API_DwmIsCompositionEnabled: function(pfEnabled: pointer): longword; stdcall;
    fEnabled: longbool;
begin
    // 初期化
    result := false;
    // Windows 10 以上または XP 以下の場合は終了
    if bWin10 or (Status.OsVersionInfo.dwMajorVersion < 6) then exit;
    // DWMAPI.DLL のロードに失敗した場合は終了
    hDLL := API_LoadLibraryEx(pchar('dwmapi.dll'), NULL, LOAD_LIBRARY_SEARCH_SYSTEM32);
    if not longbool(hDLL) then exit;
    // Aero 有効を判定
    @API_DwmIsCompositionEnabled := API_GetProcAddress(hDLL, pchar('DwmIsCompositionEnabled'));
    if longbool(@API_DwmIsCompositionEnabled) then API_DwmIsCompositionEnabled(@fEnabled);
    // DLL を解放
    API_FreeLibrary(hDLL);
    // 成功
    result := fEnabled;
end;

begin
    // OS バージョンを取得
    bWin8 := (Status.OsVersionInfo.dwMajorVersion = 6) and (Status.OsVersionInfo.dwMinorVersion >= 2);
    bWin10 := Status.OsVersionInfo.dwMajorVersion >= 10;
    // キーボードの状態を取得 (Status.bShiftButton 等では状態を取得不可)
    API_GetKeyboardState(@KeyState);
    // Shift, Ctrl, Alt キーが押されている場合は終了
    if bytebool((KeyState.k[VK_SHIFT] or KeyState.k[VK_CONTROL] or KeyState.k[VK_MENU]) and $80) then exit;
    // ウィンドウの間隔を取得
    dwBorder := 0;
    if isEnabledAero() then dwBorder := API_GetSystemMetrics(SM_AEROFRAME);
    if longbool(dwBorder) then dwBorder := API_GetSystemMetrics(SM_CXFRAME) - dwBorder;
    // 現在のウィンドウ位置、サイズを取得
    API_GetWindowRect(cwWindowMain.hWnd, @WindowRect);
    // スクリーンハンドルを取得
    hMonitor := API_MonitorFromRect(@WindowRect, MONITOR_DEFAULTTOPRIMARY);
    // スクリーンサイズを取得
    MonitorInfo.cdSize := SizeOf(TMONITORINFO);
    if API_GetMonitorInfo(hMonitor, @MonitorInfo) then ScreenRect := MonitorInfo.rcWork
    else API_SystemParametersInfo(SPI_GETWORKAREA, NULL, @ScreenRect, NULL);
    // 新しいウィンドウ位置を取得
    dwWidth := WindowRect.right - WindowRect.left;
    dwHeight := WindowRect.bottom - WindowRect.top;
    if bWin8 then Dec(dwBorder, 1);     // ズレ補正 for Windows 8, 8.1
    Inc(ScreenRect.top, dwBorder);
    if bWin8 then Inc(dwBorder, 1);     // ズレ補正 for Windows 8, 8.1
    if bWin10 then Dec(dwBorder, 2);    // ズレ補正 for Windows 10
    Inc(ScreenRect.left, dwBorder);
    Dec(ScreenRect.right, dwBorder);
    Dec(ScreenRect.bottom, dwBorder);
    if Abs(WindowRect.left - ScreenRect.left) < WINDOW_MOVE_THRESHOLD then WindowRect.left := ScreenRect.left;
    if Abs(WindowRect.right - ScreenRect.right) < WINDOW_MOVE_THRESHOLD then WindowRect.left := ScreenRect.right - dwWidth;
    if Abs(WindowRect.top - ScreenRect.top) < WINDOW_MOVE_THRESHOLD then WindowRect.top := ScreenRect.top;
    if Abs(WindowRect.bottom - ScreenRect.bottom) < WINDOW_MOVE_THRESHOLD then WindowRect.top := ScreenRect.bottom - dwHeight;
    // ウィンドウを移動
    cwWindowMain.SetWindowPosition(WindowRect.left, WindowRect.top, dwWidth, dwHeight);
end;

// ================================================================================
// OpenFile - ファイルを開く
// ================================================================================
procedure CWINDOWMAIN.OpenFile();
var
    I: longint;
    sFilter: string;
    lpFiles: pointer;
    lpFile: pointer;
    dwSize: longword;
    lpPath: ^byte;
    bResult: longbool;
    bList: longbool;
    dwCount: longword;
    dwType: longword;
    OpenFileName: TOPENFILENAME;
begin
    // バッファを確保
    GetMem(lpFiles, 262144);
    // ファイル選択ダイアログを開く
    sFilter := DIALOG_OPEN_FILTER[Status.dwLanguage];
    if Status.bOpen then sFilter := Concat(sFilter, DIALOG_SCRIPT700_FILTER[Status.dwLanguage]);
    sFilter := Concat(sFilter, DIALOG_ALL_FILTER[Status.dwLanguage]);
    API_ZeroMemory(lpFiles, 262144);
    API_ZeroMemory(@OpenFileName, SizeOf(TOPENFILENAME));
    OpenFileName.hwndOwner := cwWindowMain.hWnd;
    OpenFileName.hThisInstance := Status.hInstance;
    OpenFileName.lpstrFilter := pchar(sFilter);
    OpenFileName.nFilterIndex := Status.dwOpenFilterIndex;
    OpenFileName.lpstrFile := lpFiles;
    OpenFileName.nMaxFile := 262143;
    OpenFileName.lpstrInitialDir := Status.lpOpenPath;
    OpenFileName.Flags := $81A04;
    OpenFileName.lStructSize := SizeOf(TOPENFILENAME);
    cwWindowMain.bMessageBox := true;
    bResult := API_GetOpenFileName(@OpenFileName);
    cwWindowMain.bMessageBox := false;
    // ファイルが選択された場合
    if bResult then begin
        // インデックスを記録
        Status.dwOpenFilterIndex := OpenFileName.nFilterIndex;
        // テンポラリ用リストをクリア
        cwTempList.SendMessage(LB_RESETCONTENT, NULL, NULL);
        // ポインタをリセット
        lpPath := lpFiles;
        // バッファを確保
        GetMem(lpFile, 1024);
        // ファイルパスのリストを作成
        while bytebool(lpPath^) do begin
            // ファイルパスを取得
            dwSize := GetSize(lpPath, 1023);
            API_ZeroMemory(lpFile, 1024);
            API_MoveMemory(lpFile, lpPath, dwSize);
            cwTempList.SendMessage(LB_ADDSTRING, NULL, longword(lpPath));
            // 次のファイルパスのポインタを取得
            Inc(lpPath, dwSize + 1);
        end;
        // テンポラリ用リストのアイテム数を取得
        dwCount := cwTempList.SendMessage(LB_GETCOUNT, NULL, NULL);
        // ポインタをリセット
        lpPath := lpFile;
        dwSize := 0;
        bList := false;
        // ファイルを抽出
        if longbool(dwCount) then for I := 0 to dwCount - 1 do begin
            // ファイルを取得
            API_ZeroMemory(lpPath, 1024 - dwSize);
            cwTempList.SendMessage(LB_GETTEXT, I, longword(lpPath));
            // カレントパスを記録
            if dwCount = 1 then begin
                API_ZeroMemory(Status.lpOpenPath, 1024);
                API_MoveMemory(Status.lpOpenPath, lpFile, GetPosSeparator(PtrToStr(lpFile)));
            end;
            // ファイルを開く
            if longbool(I) or (dwCount = 1) then begin
                // ファイルの種類を取得
                dwType := GetFileType(lpFile, dwCount = 1, dwCount = 1);
                case dwType of
                    FILE_TYPE_SPC: if dwCount = 1 then SPCLoad(lpFile, true)
                        else cwSortList.SendMessage(LB_ADDSTRING, NULL, longword(lpFile));
                    FILE_TYPE_LIST_A, FILE_TYPE_LIST_B: if not bList then bList := ListLoad(lpFile, dwType, false);
                    FILE_TYPE_SCRIPT700: if dwCount = 1 then ReloadScript700(lpFile);
                end;
            end else begin
                // ファイルパスのポインタを取得
                dwSize := GetSize(lpPath, 1023);
                if longbool(dwSize) then begin
{$IFDEF FREEPASCAL}
                    lpPath := pointer(lpPath) + dwSize - 1;
{$ELSE}
                    lpPath := pointer(longword(lpPath) + dwSize - 1);
{$ENDIF}
                    if lpPath^ <> $5C then begin // \
                        Inc(dwSize);
                        Inc(lpPath);
                        lpPath^ := $5C; // \
                    end;
                    Inc(lpPath);
                    // カレントパスを記録
                    API_ZeroMemory(Status.lpOpenPath, 1024);
                    API_MoveMemory(Status.lpOpenPath, lpFile, dwSize);
                end;
            end;
        end;
        // バッファを解放
        FreeMem(lpFile, 1024);
        // テンポラリ用リストをクリア
        cwTempList.SendMessage(LB_RESETCONTENT, NULL, NULL);
    end;
    // バッファを解放
    FreeMem(lpFiles, 262144);
    // SPC ファイルをプレイリストに登録
    AppendList();
end;

// ================================================================================
// ReloadScript700 - Script700 ファイルの再読み込み
// ================================================================================
function CWINDOWMAIN.ReloadScript700(lpFile: pointer): longbool;
var
    I: longint;
    J: longword;
    K: longword;
    lpBuffer: pointer;
begin
    // 初期化
    result := false;
    // SPC が開かれていない場合は終了
    if not Status.bOpen then exit;
    // バッファを確保
    GetMem(lpBuffer, 1024);
    // カレントディレクトリをバックアップ
    API_MoveMemory(lpBuffer, Status.lpSPCDir, 1024);
    // フォルダの位置を取得
    J := GetSize(lpFile, 1024);
    K := J;
    for I := 1 to K do begin
        if PtrToStr(lpFile)[I] = NULLCHAR then break;
        if IsPathSeparator(PtrToStr(lpFile), I) then J := I;
    end;
    // カレントディレクトリをコピー
    API_ZeroMemory(Status.lpSPCDir, 1024);
    API_MoveMemory(Status.lpSPCDir, lpFile, J);
    // クリティカルセクションを開始
    API_EnterCriticalSection(@CriticalSectionStatic);
    // Script700 をロード
    LoadScript700(lpFile, SCRIPT700_TEXT);
    // クリティカルセクションを終了
    API_LeaveCriticalSection(@CriticalSectionStatic);
    // カレントディレクトリを戻す
    API_MoveMemory(Status.lpSPCDir, lpBuffer, 1024);
    // バッファを解放
    FreeMem(lpBuffer, 1024);
    // 最初から演奏
    if Status.bPlay then SPCStop(true)
    else SPCPlay(PLAY_TYPE_PLAY);
    // 成功
    result := true;
end;

// ================================================================================
// ResetInfo - インジケータリセット (排他自動)
// ================================================================================
procedure CWINDOWMAIN.ResetInfo(bRedraw: longbool);
var
    I: longint;
begin
    // クリティカルセクションを開始
    API_EnterCriticalSection(@CriticalSectionStatic);
    // インジケータ関係のメモリを初期化
    API_ZeroMemory(@Status.NowLevel, SizeOf(TLEVEL));
    API_ZeroMemory(@Status.LastLevel, SizeOf(TLEVEL));
    for I := 0 to 7 do begin
        Status.LastLevel.Channel[I].bChannelShow := true;
        Wave.dwTimeout[I] := Option.dwHideTime;
    end;
    Status.dwLastTime := $FFFFFFFF;
    Status.dwLastStartTime := $FFFFFFFF;
    Status.dwLastLimitTime := $FFFFFFFF;
    Status.dwRedrawInfo := Status.dwRedrawInfo or REDRAW_ON;
    // クリティカルセクションを終了
    API_LeaveCriticalSection(@CriticalSectionStatic);
    // インジケータを再描画
    if bRedraw then WaveProc(WAVE_PROC_GRAPH_ONLY);
end;

// ================================================================================
// ResizeWindow - ウィンドウリサイズ
// ================================================================================
procedure CWINDOWMAIN.ResizeWindow();
var
    dwLeft: longint;
    dwTop: longint;
    dwWidth: longint;
    dwHeight: longint;
    WindowRect: TRECT;
    ClientRect: TRECT;
begin
    // ウィンドウのサイズ・位置を取得
    API_GetWindowRect(cwWindowMain.hWnd, @WindowRect);
    API_GetClientRect(cwWindowMain.hWnd, @ClientRect);
    // 初期化
    dwLeft := WindowRect.left;
    dwTop := WindowRect.top;
    if Status.dwScale = 2 then begin
        dwWidth := WINDOW_WIDTH;
        dwHeight := WINDOW_HEIGHT;
    end else begin
        dwWidth := (WINDOW_WIDTH * Status.dwScale) shr 1;
        dwHeight := (WINDOW_HEIGHT * Status.dwScale) shr 1;
    end;
    // 新しいサイズを取得
    dwWidth := (WindowRect.right - WindowRect.left) - (ClientRect.right - ClientRect.left) + dwWidth;
    dwHeight := (WindowRect.bottom - WindowRect.top) - (ClientRect.bottom - ClientRect.top) + dwHeight;
    // 新しいサイズを設定
    cwWindowMain.SetWindowPosition(dwLeft, dwTop, dwWidth, dwHeight);
    // ウィンドウを更新
    UpdateWindow();
end;

// ================================================================================
// SaveFile - ファイルの保存
// ================================================================================
procedure CWINDOWMAIN.SaveFile();
var
    I: longword;
    J: longword;
    sFilter: string;
    bShift: longbool;
    lpFile: pointer;
    bResult: longbool;
    dwIndex: longint;
    OpenFileName: TOPENFILENAME;
begin
    // バッファを確保
    GetMem(lpFile, 1024);
    // ファイル選択ダイアログを開く
    bShift := Status.bShiftButton;
    sFilter := DIALOG_LIST_FILTER[Status.dwLanguage];
    if Status.bOpen then sFilter := Concat(sFilter, DIALOG_WAVE_FILTER[Status.dwLanguage]);
    if Status.bPlay then sFilter := Concat(sFilter, DIALOG_SNAP_FILTER[Status.dwLanguage]);
    API_ZeroMemory(lpFile, 1024);
    API_ZeroMemory(@OpenFileName, SizeOf(TOPENFILENAME));
    if Status.bOpen then begin
        API_MoveMemory(lpFile, Status.lpSPCName, 1024);
        J := GetSize(lpFile, 1024);
        for I := 1 to 1024 do if IsSingleByte(PtrToStr(lpFile), I, '.') then J := I;
        I := longword(lpFile) + J - 1;
        if J < 1020 then case Status.dwSaveFilterIndex of
            1: API_MoveMemory(pointer(I), pchar('.lst'), 4);
            2: API_MoveMemory(pointer(I), pchar('.wav'), 4);
            3: API_MoveMemory(pointer(I), pchar('.spc'), 4);
        end;
    end;
    OpenFileName.hwndOwner := cwWindowMain.hWnd;
    OpenFileName.hThisInstance := Status.hInstance;
    OpenFileName.lpstrFilter := pchar(sFilter);
    OpenFileName.nFilterIndex := Status.dwSaveFilterIndex;
    OpenFileName.lpstrFile := lpFile;
    OpenFileName.nMaxFile := 1024;
    OpenFileName.lpstrInitialDir := Status.lpSavePath;
    OpenFileName.Flags := $80006;
    OpenFileName.lpstrDefExt := pchar(LIST_FILETYPE);
    OpenFileName.lStructSize := SizeOf(TOPENFILENAME);
    cwWindowMain.bMessageBox := true;
    bResult := API_GetSaveFileName(@OpenFileName);
    cwWindowMain.bMessageBox := false;
    // ファイルが選択された場合
    if bResult then begin
        // インデックスを記録
        dwIndex := OpenFileName.nFilterIndex;
        Status.dwSaveFilterIndex := dwIndex;
        // カレントパスを記録
        API_ZeroMemory(Status.lpSavePath, 1024);
        API_MoveMemory(Status.lpSavePath, lpFile, GetPosSeparator(PtrToStr(lpFile)));
        // ファイルを保存
        case dwIndex of
            1: ListSave(lpFile, bShift);
            2: WaveSave(lpFile, bShift, false);
            3: SPCSave(lpFile, bShift);
        end;
    end;
    // バッファを解放
    FreeMem(lpFile, 1024);
end;

// ================================================================================
// SaveSeekCache - シークキャッシュ保存 (排他必須)
// ================================================================================
procedure CWINDOWMAIN.SaveSeekCache(dwIndex: longword);
var
    I: longint;
    dwEnvelope: longword;
    SPCCache: ^TSPCCACHE;
    SPCBuf: ^TSPC;
    SPCReg: ^TSPCREG;
    DspVoice: ^TDSPVOICE;
begin
    // キャッシュを使用しない場合は終了
    if not longbool(Option.dwCacheNum) then exit;
    // 現在の状態をキャッシュ
    SPCCache := @Status.SPCCache[dwIndex];
    SPCBuf := @SPCCache.Spc;
    SPCReg := @SPCBuf.Hdr.Reg;
    Apu.GetSPCRegs(@SPCReg.pc, @SPCReg.a, @SPCReg.y, @SPCReg.x, @SPCReg.psw, @SPCReg.sp);
    API_MoveMemory(@SPCBuf.Ram, Apu.Ram, SizeOf(TRAM));
    API_MoveMemory(@SPCBuf.Dsp, Apu.DspReg, SizeOf(TDSPREG));
    API_MoveMemory(@SPCBuf.XRam, Apu.XRam, SizeOf(TXRAM));
    API_MoveMemory(@SPCCache.Script700, Status.Script700.Data, SizeOf(TSCRIPT700EX));
    SPCCache.SPCOutPort.dwPort := Apu.SPCOutPort.dwPort;
    SPCBuf.Hdr.dwSongLen := Apu.T64Count^;
    // KON を復元
    for I := 0 to 7 do begin
        DspVoice := @Apu.DspReg.Voice[I];
        dwEnvelope := $10;
        // ADSR または Gain (Direct を除く) の場合は、エンベロープの基準値を上げる
        if bytebool((DspVoice.EnvelopeADSR1 or DspVoice.EnvelopeGain) and $80) then dwEnvelope := Option.dwCacheKOn shl 4;
        if Apu.Voices.Voice[I].EnvelopeRateValue >= dwEnvelope then SPCBuf.Dsp[$4C] := SPCBuf.Dsp[$4C] or (1 shl I);
    end;
    // 次のキャッシュ時間を取得
    if dwIndex = Option.dwCacheNum - 1 then Status.dwNextCache := 0
    else Status.dwNextCache := Status.SPCCache[dwIndex + 1].Spc.Hdr.dwFadeLen;
end;

// ================================================================================
// SetChangeFunction - 機能切替
// ================================================================================
procedure CWINDOWMAIN.SetChangeFunction(bFlag: longbool);
var
    KeyState: TKEYSTATE;
    bShiftButton: longbool;
begin
    // キーボードの状態を取得
    API_GetKeyboardState(@KeyState);
    // マウスの右ボタンが押されている場合は Shift キーを解除
    bShiftButton := bFlag and bytebool((KeyState.k[VK_SHIFT] or KeyState.k[VK_RBUTTON]) and $80);
    // フラグが変更されていない場合は終了
    if Status.bShiftButton = bShiftButton then exit;
    // シフトフラグを切替
    Status.bShiftButton := bShiftButton;
    // メニューを更新
    UpdateMenu();
end;

// ================================================================================
// SetChangeInfo - インジケータ切替
// ================================================================================
procedure CWINDOWMAIN.SetChangeInfo(bForce: longbool; dwValue: longint);
begin
    // インジケータの種類を切替
    if bForce then begin
        // 前回と同じ場合は終了
        if Option.dwInfo = longword(dwValue) then exit;
        // インジケータの種類を設定
        Option.dwInfo := dwValue;
        // メニューを更新
        UpdateMenu();
        // SPC が開かれていない場合は終了
        if not Status.bOpen then exit;
    end else begin
        // SPC が開かれていない場合は終了
        if not Status.bOpen then exit;
        // インジケータの種類を設定
        Option.dwInfo := longword(longint(Option.dwInfo) + dwValue + MENU_SETUP_INFO_SIZE) mod MENU_SETUP_INFO_SIZE;
        // メニューを更新
        UpdateMenu();
    end;
    // 情報を更新
    UpdateInfo(true);
end;

// ================================================================================
// SetFunction - 設定切替
// ================================================================================
procedure CWINDOWMAIN.SetFunction(dwFlag: longint; dwType: longword);
var
    I: longword;
    J: longword;
    T64Count: longword;

function UpdateFunction(dwNow: longword; dwSize: longword; dwValues: array of longword; dwIdxs: array of longword; dwDef1: longword; dwIdx: longint;
    dwDef2: longword; dwDef3: longword): longword;
var
    dwI: longint;
begin
    // 現在の設定値を取得
    J := $FF;
    for dwI := 0 to dwSize - 1 do if dwNow = dwValues[dwI] then J := dwI;
    // 新しい設定値を取得
    I := (not dwFlag shr 1) and (dwSize - 1);
    if J = I then begin
        // 同じ値の場合
        result := $FFFFFFFF;
    end else if J = $FF then begin
        // 未定義の設定値の場合
        result := dwDef1;
        Status.dwInfo := dwIdx;
    end else begin
        // 次の設定値を設定
        Inc(J, dwFlag);
        if dwValues[J] = $FFFFFFFF then Inc(J, dwFlag);
        result := dwValues[J];
        Status.dwInfo := STR_MENU_SETUP_PER_INTEGER[dwIdxs[J]];
        // 設定が中央の場合はオプションの設定をロック
        if not longbool(dwType and FUNCTION_TYPE_NO_TIMER) and longbool(Option.dwTimerOptionLock)
                and ((result = dwDef1) or (result = dwDef2) or (result = dwDef3)) then begin
            Status.bOptionLock := true;
            API_SetTimer(cwWindowMain.hWnd, TIMER_ID_OPTION_LOCK, Option.dwTimerOptionLock, NULLPOINTER);
        end;
    end;
end;

begin
    // オプションの設定がロックされている場合は終了
    if Status.bOptionLock then exit;
    // 機能の種類を判別
    case dwType and $FFFF of
        FUNCTION_TYPE_SEPARATE: begin // 左右拡散度
            // 左右拡散度を設定
            I := UpdateFunction(Option.dwSeparate, MENU_SETUP_SEPARATE_SIZE, MENU_SETUP_SEPARATE_VALUE, STR_MENU_SETUP_SEPARATE_PER_INDEX,
                SEPARATE_050, 50, SEPARATE_000, SEPARATE_100);
            if I = $FFFFFFFF then exit;
            Option.dwSeparate := I;
            // タイトルを更新
            UpdateTitle(TITLE_INFO_SEPARATE);
            // 設定をリセット
            SPCReset(false);
        end;
        FUNCTION_TYPE_FEEDBACK: begin // フィードバック反転度
            // フィードバック反転度を設定
            I := UpdateFunction(Option.dwFeedback, MENU_SETUP_FEEDBACK_SIZE, MENU_SETUP_FEEDBACK_VALUE, STR_MENU_SETUP_FEEDBACK_PER_INDEX,
                FEEDBACK_000, 0, FEEDBACK_050, FEEDBACK_100);
            if I = $FFFFFFFF then exit;
            Option.dwFeedback := I;
            // タイトルを更新
            UpdateTitle(TITLE_INFO_FEEDBACK);
            // 設定をリセット
            SPCReset(false);
        end;
        FUNCTION_TYPE_SPEED: begin // 演奏速度
            // 演奏速度を設定
            I := UpdateFunction(Option.dwSpeedBas, MENU_SETUP_SPEED_SIZE, MENU_SETUP_SPEED_VALUE, STR_MENU_SETUP_SPEED_PER_INDEX,
                SPEED_100, 100, SPEED_025, SPEED_400);
            if I = $FFFFFFFF then exit;
            Option.dwSpeedBas := I;
            // タイトルを更新
            UpdateTitle(TITLE_INFO_SPEED);
            // 設定をリセット
            SPCReset(false);
        end;
        FUNCTION_TYPE_AMP: begin // 音量
            // 音量を設定
            I := UpdateFunction(Option.dwAmp, MENU_SETUP_AMP_SIZE, MENU_SETUP_AMP_VALUE, STR_MENU_SETUP_AMP_PER_INDEX,
                AMP_100, 100, AMP_025, AMP_400);
            if I = $FFFFFFFF then exit;
            Option.dwAmp := I;
            // タイトルを更新
            UpdateTitle(TITLE_INFO_AMP);
            // 設定をリセット
            SPCReset(false);
        end;
        FUNCTION_TYPE_SEEK: begin // シーク
            // SPC が開かれていない、演奏停止中、または一時停止中の場合は終了
            if not Status.bOpen or not Status.bPlay or Status.bPause then exit;
            // シーク位置を取得
            J := Option.dwSeekTime shl 6;
            if Option.bSeekAsync then J := longword(int64(J) * Option.dwSpeedBas div 65536);
            T64Count := Wave.Apu[Wave.dwLastIndex].T64Count;
            if dwFlag < 0 then begin
                I := T64Count;
                If I > (Option.dwSeekMax shl 6) then exit;
                if I > J then Dec(I, J) else I := 0;
                Status.dwInfo := -Option.dwSeekTime;
            end else begin
                I := T64Count + J;
                Status.dwInfo := Option.dwSeekTime;
            end;
            // タイトルを更新
            UpdateTitle(TITLE_INFO_SEEK);
            // スレッドにシークを通知
            API_PostThreadMessage(Status.dwThreadID, WM_APP_MESSAGE, WM_APP_SPC_SEEK + (longword(Status.bCtrlButton) and $1 xor $1), I);
        end;
    end;
end;

// ================================================================================
// SetGraphic - グラフィックリソース設定
// ================================================================================
procedure CWINDOWMAIN.SetGraphic();
var
    I: longint;
    J: longint;
    K: longint;
    L: longint;
    dwColDiffR: longint;
    dwColDiffG: longint;
    dwColDiffB: longint;
    hDCBitmapBuffer: longword;
    hBitmap: longword;
    Rect: TRECT;
    Color: TREFCOLOR;
begin
    // 背景色の明るさを取得
    Rect.left := 0;
    Rect.right := 2;
    Rect.top := 0;
    Rect.bottom := 1;
    API_FillRect(Status.hDCVolumeBuffer, @Rect, Status.hBackBrush);
    Color.dwColor := API_GetPixel(Status.hDCVolumeBuffer, 0, 0);
    J := 299 * Color.r + 587 * Color.g + 114 * Color.b;
    // 文字色の明るさを取得
    Inc(Rect.left);
    API_FillRect(Status.hDCVolumeBuffer, @Rect, Status.hTextBrush);
    Color.dwColor := API_GetPixel(Status.hDCVolumeBuffer, 1, 0);
    K := 299 * Color.r + 587 * Color.g + 114 * Color.b;
    if longbool(Option.dwVolumeColor) and (Option.dwVolumeColor <= 3) then L := (Option.dwVolumeColor - 1) * COLOR_BAR_NUM
    else if K >= COLOR_BRIGHT_FORE then L := COLOR_BAR_NUM + COLOR_BAR_NUM
    else if J >= COLOR_BRIGHT_BACK then L := COLOR_BAR_NUM
    else L := 0;
    // インジケータ用のグラフィックを描画
    K := 0;
    Color.dwColor := K;
    for I := L to COLOR_BAR_NUM + L - 1 do begin
        dwColDiffR := COLOR_END_R[I] - COLOR_START_R[I];
        dwColDiffG := COLOR_END_G[I] - COLOR_START_G[I];
        dwColDiffB := COLOR_END_B[I] - COLOR_START_B[I];
        for J := 0 to COLOR_BAR_HEIGHT_M1 do begin
            Color.r := Round(COLOR_START_R[I] + dwColDiffR * J / COLOR_BAR_HEIGHT_M1);
            Color.g := Round(COLOR_START_G[I] + dwColDiffG * J / COLOR_BAR_HEIGHT_M1);
            Color.b := Round(COLOR_START_B[I] + dwColDiffB * J / COLOR_BAR_HEIGHT_M1);
            API_SetPixel(Status.hDCVolumeBuffer, K, J, Color.dwColor);
        end;
        API_StretchBlt(Status.hDCVolumeBuffer, K, 0, COLOR_BAR_WIDTH, COLOR_BAR_HEIGHT, Status.hDCVolumeBuffer, K, 0, 1, COLOR_BAR_HEIGHT, SRCCOPY);
        Inc(K, 7);
    end;
    // 文字表示用の描画領域を紫色で描画
    API_SetPixel(Status.hDCStringBuffer, 0, 0, $FF00FF);
    API_StretchBlt(Status.hDCStringBuffer, 0, 0, BITMAP_NUM_X6, BITMAP_NUM_HEIGHT, Status.hDCStringBuffer, 0, 0, 1, 1, SRCCOPY);
    // ビットマップリソース用のデバイスコンテキストを作成
    hDCBitmapBuffer := API_CreateCompatibleDC(Status.hDCStatic);
    hBitmap := API_SelectObject(hDCBitmapBuffer, API_LoadBitmap(Status.hInstance, pchar(BITMAP_NAME)));
    // ビットマップリソースから文字表示用のデバイスコンテキストへ画像を転送 (AND 処理)
    if longbool(Option.dwBmpFont) and (Option.dwBmpFont < BITMAP_NUM_FONT) then begin
        API_BitBlt(Status.hDCStringBuffer, 0, 0, BITMAP_NUM_HEX_X6, BITMAP_NUM_HEIGHT, hDCBitmapBuffer, BITMAP_NUM_X6 * Option.dwBmpFont, 0, SRCAND);
        API_BitBlt(Status.hDCStringBuffer, BITMAP_NUM_HEX_X6, 0, BITMAP_NUM_X6 - BITMAP_NUM_HEX_X6, BITMAP_NUM_HEIGHT, hDCBitmapBuffer,
            BITMAP_NUM_HEX_X6, 0, SRCAND);
    end else begin
        API_BitBlt(Status.hDCStringBuffer, 0, 0, BITMAP_NUM_X6, BITMAP_NUM_HEIGHT, hDCBitmapBuffer, 0, 0, SRCAND);
    end;
    // ビットマップリソース用のデバイスコンテキストを作り直す
    API_DeleteObject(API_SelectObject(hDCBitmapBuffer, hBitmap));
    hBitmap := API_SelectObject(hDCBitmapBuffer, API_CreateCompatibleBitmap(Status.hDCStatic, BITMAP_NUM_X6, BITMAP_NUM_HEIGHT));
    // ビットマップリソース用の描画領域を文字色で描画
    K := 0;
    for I := 0 to BITMAP_NUM - 1 do begin
        if Option.dwTheme = THEME_DARK then J := BITMAP_STRING_COLOR_DARK[I]
        else J := BITMAP_STRING_COLOR_LIGHT[I];
        if longbool(J shr 16) then begin
            // インジケータの色で描画
            J := J and $FFFF;
            for L := 0 to 8 do API_BitBlt(hDCBitmapBuffer, K, L, BITMAP_NUM_WIDTH, 1, Status.hDCVolumeBuffer, J, Abs(4 - L) * 5 + 20, SRCCOPY);
        end else begin
            // システムカラーで描画
            Rect.left := K;
            Rect.right := K + BITMAP_NUM_WIDTH;
            Rect.top := 0;
            Rect.bottom := BITMAP_NUM_HEIGHT;
            API_FillRect(hDCBitmapBuffer, @Rect, J);
        end;
        Inc(K, BITMAP_NUM_WIDTH);
    end;
    // 文字表示用からビットマップリソース用のデバイスコンテキストへ画像を転送 (黒色でマスク)
    API_TransparentBlt(hDCBitmapBuffer, 0, 0, BITMAP_NUM_X6, BITMAP_NUM_HEIGHT, Status.hDCStringBuffer, 0, 0, BITMAP_NUM_X6, BITMAP_NUM_HEIGHT, $000000);
    // 文字表示用の描画領域をボタンの色で描画
    Rect.left := 0;
    Rect.right := BITMAP_NUM_X6P6;
    Rect.top := 0;
    Rect.bottom := 9;
    API_FillRect(Status.hDCStringBuffer, @Rect, Status.hBackBrush);
    // ビットマップリソース用から文字表示用のデバイスコンテキストへ画像を転送 (紫色でマスク)
    API_TransparentBlt(Status.hDCStringBuffer, 0, 0, BITMAP_NUM_X6, BITMAP_NUM_HEIGHT, hDCBitmapBuffer, 0, 0, BITMAP_NUM_X6, BITMAP_NUM_HEIGHT, $FF00FF);
    // ビットマップリソース用のデバイスコンテキストを解放
    API_DeleteObject(API_SelectObject(hDCBitmapBuffer, hBitmap));
    API_DeleteDC(hDCBitmapBuffer);
    // GDI 描画をフラッシュ
    API_GdiFlush();
    // メニューを描画
    API_DrawMenuBar(cwWindowMain.hWnd);
    // メニュー境界を描画
    if Option.dwTheme = THEME_DARK then cmMain.DrawMenuBorder(cwWindowMain.hWnd);
end;

// ================================================================================
// SetTabFocus - フォーカス移動
// ================================================================================
procedure CWINDOWMAIN.SetTabFocus(hWnd: longword; bNext: longbool);
var
    hWndApp: longword;
begin
    hWndApp := cwWindowMain.hWnd;
    if API_GetForegroundWindow() = hWndApp then API_SetFocus(API_GetNextDlgTabItem(hWndApp, hWnd, not bNext));
end;

// ================================================================================
// ShowErrMsg - エラーメッセージ表示
// ================================================================================
procedure CWINDOWMAIN.ShowErrMsg(dwCode: longword);
var
    sMsg: string;
begin
    // エラーの種類を判別
    case dwCode of
        100..109: sMsg := ERROR_SNESAPU[Status.dwLanguage];
        110..129: sMsg := ERROR_CHECKSUM[Status.dwLanguage];
        200..249: sMsg := ERROR_FILE_READ[Status.dwLanguage];
        250..299: sMsg := ERROR_FILE_WRITE[Status.dwLanguage];
        300..599: sMsg := ERROR_DEVICE[Status.dwLanguage];
        else sMsg := '';
    end;
    // メッセージを表示
    sMsg := Concat(sMsg, ERROR_CODE_1[Status.dwLanguage], IntToStr(dwCode), ERROR_CODE_2[Status.dwLanguage]);
    cwWindowMain.MessageBox(pchar(sMsg), pchar(DEFAULT_TITLE), MB_ICONEXCLAMATION or MB_OK);
end;

// ================================================================================
// SPCLoad - SPC ファイルの読み込み
// ================================================================================
function CWINDOWMAIN.SPCLoad(lpFile: pointer; bAutoPlay: longbool): longbool;
var
    I: longint;
    J: longword;
    K: longword;
    L: longword;
    pV: ^byte;
    bScript700Exist: longbool;
    hFile: longword;
    dwReadSize: longword;
    lpBuffer: pointer;
    lpTitle: pointer;
    sData: string;
    HdrBin: TSPCHDRBIN;
    StrData: TSTRDATA;

function CheckPath(dwEnd: longword; const sName: string): longbool;
begin
    sData := Concat(Copy(PtrToStr(lpFile), 1, dwEnd), sName);
    result := longbool(IsSafePath(pchar(sData)) and Exists(pchar(sData), $FFFFFFFF));
end;

begin
    // 初期化
    result := false;
    sData := '';
    // ファイルをオープン
    hFile := INVALID_HANDLE_VALUE;
    if IsSafePath(lpFile) then hFile := API_CreateFile(lpFile, GENERIC_READ, FILE_SHARE_READ, NULLPOINTER, OPEN_EXISTING,
        FILE_ATTRIBUTE_NORMAL or FILE_FLAG_SEQUENTIAL_SCAN, NULL);
    // ファイルのオープンに失敗した場合は終了
    if hFile = INVALID_HANDLE_VALUE then exit;
    // 演奏中の場合
    if Status.bPlay then begin
        // Script700 を強制終了
        Status.Script700.Data.cStatusFlag := Status.Script700.Data.cStatusFlag or $80;
        Status.bWaveWrite := false;
        // 演奏を一時停止
        WavePause();
    end;
    // インデックスのズレを補正
    if not Status.bOpen and (Status.dwOpenFilterIndex >= 4) then Inc(Status.dwOpenFilterIndex);
    // フラグを設定
    Status.bOpen := true;
    Status.bSPCRefresh := true;
    // ファイルをロード
    API_ReadFile(hFile, @Spc, $10200, @dwReadSize, NULLPOINTER);
    // バッファをコピー
    API_MoveMemory(Status.lpSPCFile, lpFile, 1024);
    API_MoveMemory(@HdrBin, @Spc.Hdr, 256);
    // ID666 フォーマット形式を取得
    GetID666Format(Spc.Hdr);
    // タイトルが存在しない場合
    if not bytebool(Spc.Hdr.TagFormat) or not bytebool(Spc.Hdr.Title[0]) then begin
        // タイトルにファイル名を設定
        GetMem(lpBuffer, 1024);
        GetMem(lpTitle, 33);
        API_ZeroMemory(lpBuffer, 1024);
        API_GetFileTitle(lpFile, lpBuffer, 1023);
        API_ZeroMemory(lpTitle, 33);
        API_MoveMemory(lpTitle, lpBuffer, 32);
        API_MoveMemory(@Spc.Hdr.Title[0], lpTitle, 32);
        FreeMem(lpBuffer, 1024);
        FreeMem(lpTitle, 33);
    end;
    // ID666 バイナリフォーマットの場合
    if Spc.Hdr.TagFormat = ID666_BINARY then begin
        // 日付を変換
        if (HdrBin.DateYear > 0) and (HdrBin.DateYear < 10000) and (HdrBin.DateMonth > 0) and (HdrBin.DateMonth < 13) and (HdrBin.DateDay > 0)
        and (HdrBin.DateDay < 32) then begin
            IntToStr(StrData, longword(HdrBin.DateYear), 4);
            API_MoveMemory(@Spc.Hdr.Date[0], @StrData, 4);
            Spc.Hdr.Date[4] := '/';
            IntToStr(StrData, longword(HdrBin.DateMonth), 2);
            API_MoveMemory(@Spc.Hdr.Date[5], @StrData, 2);
            Spc.Hdr.Date[7] := '/';
            IntToStr(StrData, longword(HdrBin.DateDay), 2);
            API_MoveMemory(@Spc.Hdr.Date[8], @StrData, 2);
        end else Spc.Hdr.Date[0] := NULLCHAR;
        // 演奏時間を変換
        I := HdrBin.SongLen;
        if I > 999 then I := 999;
        if longbool(I) then begin
            IntToStr(StrData, longword(I), 3);
            API_MoveMemory(@Spc.Hdr.SongLen[0], @StrData, 3);
        end;
        // フェードアウト時間を変換
        I := HdrBin.FadeLen and $FFFFFF;
        if I > 99999 then I := 99999;
        if longbool(I) then begin
            IntToStr(StrData, longword(I), 5);
            API_MoveMemory(@Spc.Hdr.FadeLen[0], @StrData, 5);
        end;
        // 作曲者、チャンネル無効、出力元エミュレータをコピー
        API_MoveMemory(@Spc.Hdr.Artist[0], @HdrBin.Artist[0], 34);
    end;
    // テキストの制御コードをスペースに変換
    pV := @Spc.Hdr.Title;
    for I := 0 to 162 do begin
        if ((pV^ > $0) and (pV^ < $20)) or (pV^ = $7F) then pV^ := $20;
        Inc(pV);
    end;
    // 演奏時間、フェードアウト時間を取得
    Spc.Hdr.dwSongLen := StrToInt(ChrToStr(Spc.Hdr.SongLen), longword(0));
    Spc.Hdr.dwFadeLen := StrToInt(ChrToStr(Spc.Hdr.FadeLen), longword(0));
    // フォルダの位置を取得
    J := GetSize(lpFile, 1024);
    K := J;
    L := J;
    for I := 1 to L do begin
        if PtrToStr(lpFile)[I] = NULLCHAR then break;
        if IsPathSeparator(PtrToStr(lpFile), I) then J := I;
        if IsSingleByte(PtrToStr(lpFile), I, '.') then K := I;
    end;
    // カレントディレクトリをコピー
    API_ZeroMemory(Status.lpSPCDir, 1024);
    API_MoveMemory(Status.lpSPCDir, lpFile, J);
    // ファイル名をコピー
    API_ZeroMemory(Status.lpSPCName, 1024);
    I := L - J;
    if I > 0 then API_MoveMemory(Status.lpSPCName, pointer(longword(lpFile) + J), I);
{$IFNDEF TRY700A}{$IFNDEF TRY700W}
    // ファイルを取得
    bScript700Exist := CheckPath(K, SCRIPT700_FILETYPE)
                    or CheckPath(K, SCRIPT7SE_FILETYPE)
                    or CheckPath(K, SCRIPT700TXT_FILETYPE)
                    or CheckPath(K, SCRIPT7SETXT_FILETYPE)
                    or CheckPath(J, SCRIPT700_FILENAME)
                    or CheckPath(J, SCRIPT7SE_FILENAME)
                    or CheckPath(J, SCRIPT700TXT_FILENAME)
                    or CheckPath(J, SCRIPT7SETXT_FILENAME);
    // Script700 をロード
    if not bScript700Exist or not LoadScript700(pchar(sData), SCRIPT700_TEXT) then Status.Script700.dwProgSize := Apu.SetScript700(NULLPOINTER);
{$ENDIF}{$ENDIF}
{$IFDEF TRY700A}
    cwWindowMain.MessageBox(pchar(IntToStr(Apu.Try700(lpFile))), NULLPOINTER, NULL);
{$ENDIF}
{$IFDEF TRY700W}
    GetMem(lpBuffer, 2048);
    API_MultiByteToWideChar(CP_ACP, NULL, lpFile, -1, lpBuffer, 2048);
    cwWindowMain.MessageBox(pchar(IntToStr(Apu.Try700(lpBuffer))), NULLPOINTER, NULL);
    FreeMem(lpBuffer, 2048);
{$ENDIF}
    // 情報を更新
    UpdateInfo(false);
    // タイトルを更新
    UpdateTitle(NULL);
    // 演奏を開始
    if Status.bPlay then SPCStop(bAutoPlay)
    else if bAutoPlay then SPCPlay(PLAY_TYPE_PLAY);
    // ファイルをクローズ
    API_CloseHandle(hFile);
    // 成功
    result := true;
end;

// ================================================================================
// SPCOption - SPC 演奏設定 (排他必須)
// ================================================================================
procedure CWINDOWMAIN.SPCOption();
var
    I: longint;
    V: byte;
    dwOption: longword;
    dwPitch: longword;
begin
    // 拡張設定を設定 (dwBit は負数になる場合があるため shl は使わない)
    dwOption := Option.dwOption or OPTION_FLOATOUT;
    if not longbool(Option.bEarSafe) then dwOption := dwOption or OPTION_NOEARSAFE;
    Apu.SetAPUOption(1, Status.dwChannel, Status.dwBit * 8, Status.dwRate, Option.dwInter, dwOption);
    // 演奏速度を設定
    Apu.SetAPUSpeed(Option.dwSpeedBas + longword(longint(Option.dwSpeedBas) * Option.dwSpeedTun div SPEED_100));
    // ピッチを設定
    if Option.dwPitch < 16384 then dwPitch := 16384
    else if Option.dwPitch > 262144 then dwPitch := 262144
    else dwPitch := Option.dwPitch;
    if Option.bPitchAsync then Apu.SetDSPPitch(Option.dwSpeedBas * dwPitch div SPEED_100)
    else Apu.SetDSPPitch(dwPitch);
    // 左右拡散度を設定
    Apu.SetDSPStereo(Option.dwSeparate);
    // フィードバック反転度を設定
    Apu.SetDSPFeedback(32768 - Option.dwFeedback);
    // 音量を設定
    Apu.SetDSPAmp(Option.dwAmp);
    // チャンネルマスクを設定
    for I := 0 to 7 do begin
        V := Apu.Voices.Voice[I].MixFlag and $FC;
        if bytebool(Option.dwMute and (1 shl I)) then V := V or $1;
        if bytebool(Option.dwNoise and (1 shl I)) then V := V or $2;
        Apu.Voices.Voice[I].MixFlag := V;
    end;
end;

// ================================================================================
// SPCPlay - SPC 演奏開始・一時停止
// ================================================================================
procedure CWINDOWMAIN.SPCPlay(dwType: longword);
var
    I: longint;
    J: longword;
    K: longword;
    SPCHdr: ^TSPCHDR;
{$IFDEF TRANSMITSPC}
    TSPCEx: TTRANSFERSPCEX;
{$ENDIF}
{$IFDEF PERFORMANCETEST}
    lpBuffer: pointer;
{$ENDIF}
begin
    // 演奏の種類を判別
    if not Status.bEmuDebug then case dwType of
        PLAY_TYPE_AUTO, PLAY_TYPE_PLAY: if not Status.bOpen then begin // 自動
            ListPlay(Option.dwPlayOrder, LIST_PLAY_INDEX_SELECTED, NULL);
            exit;
        end;
        PLAY_TYPE_LIST: begin // プレイリストの選択済みアイテム
            ListPlay(Option.dwPlayOrder, LIST_PLAY_INDEX_SELECTED, NULL);
            exit;
        end;
        PLAY_TYPE_RANDOM: begin // プレイリストからランダム選択
            ListNextPlay(PLAY_ORDER_RANDOM, LIST_NEXT_PLAY_SELECT);
            exit;
        end;
    end else begin
        // バッファをクリア
        API_ZeroMemory(@Spc.Hdr, SizeOf(TSPCHDR));
        // インデックスのズレを補正
        if not Status.bOpen and (Status.dwOpenFilterIndex >= 4) then Inc(Status.dwOpenFilterIndex);
        // フラグを設定
        Status.bOpen := true;
        // 情報を更新
        UpdateInfo(false);
        // タイトルを更新
        UpdateTitle(NULL);
    end;
    // SPC が開かれていない場合は終了
    if not Status.bOpen then exit;
    // スリープ解除タイマーを初期化
    Status.dwNoSleepTime := 0;
    // 一時停止中の場合
    if Status.bPause then begin
        // 一時停止指定の場合は終了
        if dwType = PLAY_TYPE_PAUSE then exit;
{$IFNDEF TRANSMITSPC}
        // スレッドに演奏再開を通知
        API_PostThreadMessage(Status.dwThreadID, WM_APP_MESSAGE, WM_APP_SPC_RESUME, NULL);
{$ENDIF}
    // 演奏中の場合
    end else if Status.bPlay then begin
        // 演奏開始指定の場合は終了
        if dwType = PLAY_TYPE_PLAY then exit;
{$IFNDEF TRANSMITSPC}
        // スレッドに一時停止を通知
        API_PostThreadMessage(Status.dwThreadID, WM_APP_MESSAGE, WM_APP_SPC_PAUSE, NULL);
{$ENDIF}
    // 演奏停止中の場合
    end else begin
        // 一時停止指定の場合は終了
        if dwType = PLAY_TYPE_PAUSE then exit;
        // クリティカルセクションを開始
        API_EnterCriticalSection(@CriticalSectionThread);
        // Script700 で設定されたブレイクポイントを解除
        for I := 0 to 65535 do if longbool(Status.BreakPoint[I] and $80) then Status.BreakPoint[I] := 0;
{$IFDEF TIMERTRICK}
        // TimerTrick を設定
        Apu.SetTimerTrick(0, 16661);
{$ENDIF}
        // SPC を APU に転送
        if Status.bEmuDebug then begin
            Apu.SetScript700(NULLPOINTER);
            Apu.ResetAPU($FFFFFFFF);
        end else Apu.LoadSPCFile(@Spc);
{$IFDEF TRANSMITSPC}
        //I := Apu.TransmitSPC($D050); // $EC00
        API_ZeroMemory(@TSPCEx, SizeOf(TSPCEx));
        TSPCEx.cbSize := SizeOf(TSPCEx);
        TSPCEx.transmitType := 1;
        TSPCEx.bScript700 := longbool(Status.Script700.dwProgSize);
        TSPCEx.lptPort := $D050;
        I := Apu.TransmitSPCEx(@TSPCEx);
        if longbool(I) then cwWindowMain.MessageBox(pchar(IntToStr(longint(I))), NULLPOINTER, 0);
{$ENDIF}
        // SPC 演奏設定
        SPCOption();
        // 演奏時間、フェードアウト時間を設定
        SPCTime(true, false, true);
        // クリティカルセクションを終了
        API_LeaveCriticalSection(@CriticalSectionThread);
{$IFDEF PERFORMANCETEST}
        // バッファを確保
        GetMem(lpBuffer, 96000 * 2 * 4);
        // 現在時刻を取得
        J := API_timeGetTime();
        // 299 秒分をエミュレート
        for I := 0 to 299 do Apu.EmuAPU(lpBuffer, 24576000, 0);
        // 現在時刻を取得
        J := API_timeGetTime() - J;
        // バッファを解放
        FreeMem(lpBuffer, 96000 * 2 * 4);
        // 時間を表示
        cwWindowMain.SetCaption(pchar(IntToStr(J)));
{$ENDIF}
        // 新しい SPC が読み込まれた場合
        if Status.bEmuDebug or Status.bSPCRefresh then begin
            // シークキャッシュを初期化
            if longbool(Option.dwCacheNum) then begin
                J := 0;
                K := Option.dwCacheInt shl 6;
                Status.dwNextCache := K;
                for I := 0 to Option.dwCacheNum - 1 do begin
                    Inc(J, K);
                    SPCHdr := @Status.SPCCache[I].Spc.Hdr;
                    SPCHdr.dwSongLen := $FFFFFFFF;
                    SPCHdr.dwFadeLen := J;
                end;
            end else begin
                Status.dwNextCache := 0;
            end;
            // リピート開始位置、リピート終了位置を初期化
            if Status.bTimeRepeat then Option.dwPlayOrder := Status.dwPlayOrder;
            Status.dwStartTime := 0;
            Status.dwLimitTime := Status.dwDefaultTimeout;
            Status.bTimeRepeat := false;
            // TUNING 開始アドレスを初期化
            Status.dwTuningAddress := $1FF;
            Status.dwTuningSize := 0;
        end;
        // テンポ解析が有効な場合
        if Option.bBPM then begin
            // バッファをクリア
            API_ZeroMemory(@Status.Tempo, SizeOf(TTEMPO));
{$IFDEF SPCBPMTEST}
            // BPM 解析を開始
            Apu.BPMStart(NULLPOINTER);
{$ELSE}
            // コールバックを追加設定
            Apu.SNESAPUCallback(@_SNESAPUCallback, CBE_DSPREG);
{$ENDIF}
        end;
        // デバイスをオープン
        Status.dwWaveMessage := WAVE_MESSAGE_MAX_COUNT;
{$IFDEF TRANSMITSPC}
        Status.bPlay := true;
        Status.bPause := false;
{$ELSE}
        Status.bPlay := Status.bSPCRestart;
        if Status.bSPCRestart then I := 0 else I := WaveOpen();
{$ENDIF}
        // フラグを設定
        Status.bSPCRestart := false;
        Status.bSPCRefresh := false;
        Status.bWaveWrite := true;
        // メニューを更新
        UpdateMenu();
        // インジケータをリセット
        if not Status.bTimeRepeat then ResetInfo(true);
{$IFNDEF TRANSMITSPC}
        // エラーがある場合
        if longbool(I) then begin
            // メッセージを表示
            ShowErrMsg(300 + (I and $FF));
        end else if Status.bPlay then begin
            // スレッドに演奏開始を通知
            API_PostThreadMessage(Status.dwThreadID, WM_APP_MESSAGE, WM_APP_SPC_PLAY, NULL);
        end;
{$ENDIF}
    end;
end;

// ================================================================================
// SPCReset - SPC リセット
// ================================================================================
procedure CWINDOWMAIN.SPCReset(bWave: longbool);
begin
    // デバイスの再オープンが不要な場合
    if not bWave and Status.bPlay then begin
        // スレッドに設定変更を通知
        API_PostThreadMessage(Status.dwThreadID, WM_APP_MESSAGE, WM_APP_SPC_RESET, NULL);
    end;
    // デバイスの再オープンが必要な場合
    if bWave and not Status.bPlay then begin
        // デバイスを解放
        WaveQuit();
        // デバイスを初期化
        WaveInit();
    end;
    // メニューを更新
    UpdateMenu();
end;

// ================================================================================
// SPCSave - SPC 保存
// ================================================================================
function CWINDOWMAIN.SPCSave(lpFile: pointer; bShift: longbool): longbool;
var
    hFile: longword;
    dwWriteSize: longword;
    SPCBuf: TSPC;
    SPCReg: ^TSPCREG;
begin
    // 初期化
    result := false;
    // SPC が開かれていない、または演奏停止中の場合は終了
    if not Status.bOpen or not Status.bPlay then exit;
    // クリティカルセクションを開始
    API_EnterCriticalSection(@CriticalSectionThread);
    // SPC を保存
    SPCReg := @SPCBuf.Hdr.Reg;
    API_MoveMemory(@SPCBuf, @Spc, SizeOf(TSPCHDR));
    Apu.GetSPCRegs(@SPCReg.pc, @SPCReg.a, @SPCReg.y, @SPCReg.x, @SPCReg.psw, @SPCReg.sp);
    API_MoveMemory(@SPCBuf.Ram, Apu.Ram, SizeOf(TRAM));
    API_MoveMemory(@SPCBuf.Dsp, Apu.DspReg, SizeOf(TDSPREG));
    API_MoveMemory(@SPCBuf.XRam, Apu.XRam, SizeOf(TXRAM));
    // クリティカルセクションを終了
    API_LeaveCriticalSection(@CriticalSectionThread);
    // ファイルをオープン
    hFile := INVALID_HANDLE_VALUE;
    if IsSafePath(lpFile) then begin
        API_MakeSureDirectoryPathExists(lpFile);
        hFile := API_CreateFile(lpFile, GENERIC_WRITE, FILE_SHARE_READ, NULLPOINTER, CREATE_ALWAYS,
            FILE_ATTRIBUTE_NORMAL or FILE_FLAG_SEQUENTIAL_SCAN, NULL);
    end;
    // ファイルのオープンに失敗した場合はメッセージを表示して終了
    if hFile = INVALID_HANDLE_VALUE then begin
        ShowErrMsg(251);
        exit;
    end;
    // SPC バッファを保存
    API_WriteFile(hFile, @SPCBuf, SizeOf(TSPC), @dwWriteSize, NULLPOINTER);
    // ファイルをクローズ
    API_CloseHandle(hFile);
    // 成功
    result := true;
end;

// ================================================================================
// SPCSeek - SPC シーク (排他必須)
// ================================================================================
procedure CWINDOWMAIN.SPCSeek(dwTime: longword; bCache: longbool);
var
    I: longint;
    J: longint;
    T64Count: longword;
    T64Cache: longword;
    dwCacheDiff: longword;
    dwTarget: longword;

procedure CacheSeek();
var
    SPCCache: ^TSPCCACHE;
    SPCOutPortCopy: ^TSPCPORT;
begin
    if not longbool(T64Cache) then begin
        // キャッシュがない場合は最初のバッファを読み込む
        Apu.LoadSPCFile(@Spc);
        T64Count := 0;
    end else begin
        // キャッシュがある場合はキャッシュを読み込む
        SPCCache := @Status.SPCCache[J];
        Apu.LoadSPCFile(@SPCCache.Spc);
        API_MoveMemory(Status.Script700.Data, @SPCCache.Script700, SizeOf(TSCRIPT700EX));
        Apu.SPCOutPort.dwPort := SPCCache.SPCOutPort.dwPort;
        SPCOutPortCopy := pointer(longword(Apu.SPCOutPort) + 8);
        SPCOutPortCopy.dwPort := Apu.SPCOutPort.dwPort;
        Apu.T64Count^ := T64Cache;
        T64Count := T64Cache;
    end;
    // 演奏時間、フェードアウト時間を設定
    Apu.SetAPULength(Status.dwAPUPlayTime, Status.dwAPUFadeTime);
end;

begin
    // SPC が開かれていない、演奏停止中、または一時停止中の場合は終了
    if not Status.bOpen or not Status.bPlay or Status.bPause then exit;
    // 最後にエミュレートした時間を取得
    T64Count := Wave.Apu[Wave.dwLastIndex].T64Count;
    // 現在の場所に変更がない場合は終了
    if dwTime = T64Count then exit;
{$IFDEF SPCBPMTEST}
    // テンポ解析が有効な場合、BPM 解析を停止
    if Option.bBPM then Apu.BPMStop();
{$ELSE}
    // テンポ解析が有効な場合、テンポ解析を無効化
    if Option.bBPM then Status.Tempo.bDisable := true;
{$ENDIF}
    // キャッシュの基準位置を取得
    dwCacheDiff := Option.dwCacheDiff shl 6;
    dwTarget := dwTime;
    if not Option.bSeekFast then if dwTarget > dwCacheDiff then Dec(dwTarget, dwCacheDiff) else dwTarget := 0;
    // シーク位置に最も近いキャッシュの場所を取得
    J := -1;
    for I := 0 to Option.dwCacheNum - 1 do if dwTarget >= Status.SPCCache[I].Spc.Hdr.dwSongLen then J := I;
    if not bCache or (J = -1) then T64Cache := 0
    else T64Cache := Status.SPCCache[J].Spc.Hdr.dwSongLen;
    // シーク位置が現在位置も後の場合は大まかな位置までシーク
    if dwTime > T64Count then begin
        // 現在位置よりキャッシュ位置の方が近い場合はキャッシュを読み込む
        if T64Cache > T64Count then CacheSeek();
        // キャッシュ位置が経過するまでループ
        while longbool(Status.dwNextCache) and (Status.dwNextCache < dwTime) do begin
            // キャッシュする位置までシーク
            if Status.dwNextCache > T64Count then Apu.SeekAPU(Status.dwNextCache - T64Count, byte(bCache and Option.bSeekFast));
            // キャッシュを更新
            Inc(J);
            SaveSeekCache(J);
            // 現在位置を記録
            T64Count := Apu.T64Count^;
        end;
    end else begin
        // シーク位置に最も近いキャッシュを読み込む
        CacheSeek();
    end;
    // 最終的な位置までシーク
    if dwTime > T64Count then Apu.SeekAPU(dwTime - T64Count, byte(bCache and Option.bSeekFast));
    // 無音検出フラグをリセット
    Status.dwMuteTimeout := 0;
    Status.dwMuteCounter := Option.dwBufferNum;
    // テンポ解析が有効な場合、テンポ解析を有効化
    if Option.bBPM then begin
        // 現在位置を取得
        T64Count := Apu.T64Count^;
        // バッファをクリア
        API_ZeroMemory(@Status.Tempo, SizeOf(TTEMPO));
        // シーク直後の時間で初期化
        Status.Tempo.dwStartTime := T64Count;
        Status.Tempo.dwKOnTime := T64Count;
        Status.Tempo.dwMinTime := T64Count;
        Status.Tempo.dwMaxTime := T64Count;
{$IFDEF SPCBPMTEST}
        // BPM 解析を開始
        Apu.BPMStart(NULLPOINTER);
{$ENDIF}
    end;
end;

// ================================================================================
// SPCStop - SPC 演奏停止
// ================================================================================
procedure CWINDOWMAIN.SPCStop(bRestart: longbool);
begin
    // SPC が開かれていない、または演奏停止中の場合は終了
    if not Status.bOpen or not Status.bPlay then exit;
    // フラグを設定
    Status.bSPCRestart := bRestart;
{$IFDEF TRANSMITSPC}
    Status.bPlay := false;
    Status.bPause := false;
    Apu.StopTransmitSPC();
{$ENDIF}
    // すぐに再演奏する場合
    if Status.bSPCRestart then begin
{$IFNDEF TRANSMITSPC}
        // 演奏を停止
        WaveReset(false);
{$ENDIF}
        // 再演奏
        SPCPlay(PLAY_TYPE_PLAY);
    end else begin
{$IFNDEF TRANSMITSPC}
        // 演奏を停止
        WaveClose(false);
{$ENDIF}
        // デバイスを更新
        UpdateDevice(Option.dwDeviceID, WAVE_DEVICE_UPDATE_LIST);
        // メニューを更新
        UpdateMenu();
        // インジケータをリセット
        ResetInfo(true);
    end;
end;

// ================================================================================
// SPCTime - SPC 時間設定 (bSet=true 時、排他必須)
// ================================================================================
procedure CWINDOWMAIN.SPCTime(bCal: longbool; bDefault: longbool; bSet: longbool);
begin
    // 演奏時間を計算する場合
    if bCal then begin
        // 無音検出フラグをリセット
        Status.dwMuteTimeout := 0;
        Status.dwMuteCounter := 0;
        // 演奏時間、フェードアウト時間を計算
        Status.bNextDefault := not bytebool(Spc.Hdr.TagFormat) or not longbool(Spc.Hdr.dwSongLen) or (Option.dwPlayMax = PLAY_MAX_DEFAULT);
        if Option.dwPlayMax = PLAY_MAX_ENDLESS then begin
            if not bDefault then begin
                Status.dwAPUPlayTime := $FFFFFFFF;
                Status.dwAPUFadeTime := 0;
            end else if Status.bNextDefault then begin
                Status.dwAPUPlayTime := Option.dwPlayTime shl 6;
                Status.dwAPUFadeTime := Option.dwFadeTime shl 6;
            end else begin
                Status.dwAPUPlayTime := Spc.Hdr.dwSongLen * 64000;
                Status.dwAPUFadeTime := Spc.Hdr.dwFadeLen shl 6;
            end;
            Status.dwDefaultTimeout := Option.dwSeekBar shl 6;
        end else if Status.bNextDefault then begin
            Status.dwAPUPlayTime := Option.dwPlayTime shl 6;
            Status.dwAPUFadeTime := Option.dwFadeTime shl 6;
            Status.dwDefaultTimeout := (Option.dwPlayTime + Option.dwFadeTime + Option.dwWaitTime) shl 6;
        end else begin
            Status.dwAPUPlayTime := Spc.Hdr.dwSongLen * 64000;
            Status.dwAPUFadeTime := Spc.Hdr.dwFadeLen shl 6;
            Status.dwDefaultTimeout := (Spc.Hdr.dwSongLen * 1000 + Spc.Hdr.dwFadeLen + Option.dwWaitTime) shl 6;
        end;
        if not longbool(Status.dwDefaultTimeout) then Inc(Status.dwDefaultTimeout);
    end;
    // 演奏時間を使用する場合
    if bDefault or (Option.dwPlayMax > PLAY_MAX_ENDLESS) then begin
        // タイムアウトを設定
        if bCal then Status.dwNextTimeout := Status.dwDefaultTimeout;
        // 演奏時間、フェードアウト時間を設定
        if bSet then Apu.SetAPULength(Status.dwAPUPlayTime, Status.dwAPUFadeTime);
    end else begin
        // タイムアウトを設定
        if bCal then Status.dwNextTimeout := 1;
        // 演奏中の場合は演奏時間、フェードアウト時間を設定
        if bSet and Status.bPlay then Apu.SetAPULength($FFFFFFFF, 0);
    end;
end;

// ================================================================================
// UpdateDevice - デバイス更新
// ================================================================================
procedure CWINDOWMAIN.UpdateDevice(dwDeviceID: longint; dwFlag: longword);
var
    I: longint;
    J: longint;
    sBuffer: string;
    WaveOutCaps: TWAVEOUTCAPS;
begin
    // デバイス一覧を更新する場合
    if longbool(dwFlag and WAVE_DEVICE_UPDATE_LIST) then begin
        // デバイスメニューを削除
        for I := 0 to Status.dwDeviceNum - 1 do cmSetupDevice.RemoveItem(MENU_SETUP_DEVICE_BASE + I + 1);
        // デバイス一覧を取得
        Status.dwDeviceNum := API_waveOutGetNumDevs();
        if Status.dwDeviceNum > 32 then Status.dwDeviceNum := 32;
        SetLength(Status.sDeviceName, Status.dwDeviceNum + 1);
        // デバイスを仮選択
        if dwDeviceID >= longint(Status.dwDeviceNum) then dwDeviceID := -1;
        if dwDeviceID < -1 then dwDeviceID := -1;
        Option.dwDeviceID := dwDeviceID;
        // デバイスメニューを作成
        if (dwFlag and WAVE_DEVICE_INITIALIZE) = WAVE_DEVICE_INITIALIZE then J := -1 else J := 0;
        for I := J to Status.dwDeviceNum - 1 do begin
            // デバイス名を取得
            if I < 0 then begin
                sBuffer := STR_MENU_SETUP_DEVICE_MAPPER[Status.dwLanguage];
            end else begin
                API_waveOutGetDevCaps(I, @WaveOutCaps, SizeOf(TWAVEOUTCAPS));
                sBuffer := ChrToStr(WaveOutCaps.szPname);
            end;
            Status.sDeviceName[I + 1] := sBuffer;
            // デバイス名を簡略化するため、' (' 以降を削除する
            if I < 0 then begin
                cmSetupDevice.AppendMenu(MENU_SETUP_DEVICE_BASE + I + 1, pchar(sBuffer), true);
                cmSetupDevice.AppendSeparator();
            end else begin
                J := Pos(' (', sBuffer);
                if longbool(J) then sBuffer := Copy(sBuffer, 1, J - 1);
                cmSetupDevice.AppendMenu(MENU_SETUP_DEVICE_BASE + I + 1, pchar(Concat('&', char($31 + I), ' : ', sBuffer)), true);
            end;
        end;
        // 前回終了時に選択していたデバイス名と一致するデバイスを優先する
        // 同名のデバイスが複数ある場合は、前回選択位置を優先する
        J := -1;
        for I := 0 to Status.dwDeviceNum do if Status.sDeviceName[I] = Option.sDeviceName then if J = -1 then J := I else J := -2;
        if J >= 0 then dwDeviceID := J - 1;
    end;
    // デバイスを再選択
    if dwDeviceID >= longint(Status.dwDeviceNum) then dwDeviceID := -1;
    Option.dwDeviceID := dwDeviceID;
    // デバイス名を記録
    if longbool(dwFlag and WAVE_DEVICE_UPDATE_SELECT) then
        if dwDeviceID < 0 then Option.sDeviceName := '' else Option.sDeviceName := Status.sDeviceName[dwDeviceID + 1];
end;

// ================================================================================
// UpdateInfo - 情報更新
// ================================================================================
procedure CWINDOWMAIN.UpdateInfo(bRedraw: longbool);
var
    sInfo: string;
    sBuffer: string;
begin
    // SPC が開かれていない場合は終了
    if not Status.bOpen then exit;
    // 情報を作成
    sInfo := 'Title    : ';
    if not bytebool(Spc.Hdr.Title[0]) then sInfo := Concat(sInfo, '(Unknown)')
    else sInfo := Concat(sInfo, ChrToStr(Spc.Hdr.Title));
    sInfo := Concat(sInfo, CRLF, 'Game     : ');
    if not bytebool(Spc.Hdr.TagFormat) or not bytebool(Spc.Hdr.Game[0]) then sInfo := Concat(sInfo, '(Unknown)')
    else sInfo := Concat(sInfo, ChrToStr(Spc.Hdr.Game));
    sInfo := Concat(sInfo, CRLF, 'Time     :  :  :  .');
    case Option.dwInfo of
        INFO_MIXER, INFO_CHANNEL_1, INFO_CHANNEL_2, INFO_CHANNEL_3, INFO_CHANNEL_4, INFO_SCRIPT700: begin
            case Option.dwInfo of
                INFO_CHANNEL_1:
                    if Status.bBreakButton then sInfo := Concat(sInfo, CRLF, '    Src VL  VR  EX  OX       Src VL  VR  EX  OX')
                    else sInfo := Concat(sInfo, CRLF, '    Src VL VR Pitch EX       Src VL VR Pitch EX');
                INFO_CHANNEL_2:
                    if Status.bBreakButton then sInfo := Concat(sInfo, CRLF, '    Src ADSR/Gain Tune       Src ADSR/Gain Tune')
                    else sInfo := Concat(sInfo, CRLF, '    Src ADSR/Gain   EX       Src ADSR/Gain   EX');
                INFO_CHANNEL_3: sInfo := Concat(sInfo, CRLF, '    Src On Flags   F R       Src On Flags   F R');
                INFO_CHANNEL_4: sInfo := Concat(sInfo, CRLF, '    Src Addr Loop Read       Src Addr Loop Read');
            end;
            case Option.dwInfo of
                INFO_MIXER: begin
                    sInfo := Concat(sInfo, CRLF, 'MasterLv : L=    R=      EchoLv   : L=    R=', CRLF,
                        'Delay    :    (    ms)   Feedback :    (   ', STR_MENU_SETUP_PERCENT[Status.dwLanguage], ')', CRLF);
                    if Status.bBreakButton then begin
                        sInfo := Concat(sInfo, 'SrcAddr  :     -         EchoAddr :     -', CRLF, 'FIR      :');
{$IFDEF SPCBPMTEST}
                        if Option.bBPM then sInfo := Concat(sInfo, CRLF, 'BPMWork  : KOn=   /    R=   -    E=   BPM*:')
{$ELSE}
                        if Option.bBPM then sInfo := Concat(sInfo, CRLF, 'BPMWork  : KOn=   /    R=   -    E=   BPM :')
{$ENDIF}
                        else sInfo := Concat(sInfo, CRLF, 'BPMWork  : (Disabled)');
                    end else begin
                        sInfo := Concat(sInfo, 'SrcAddr  :     -   _     EchoAddr :     -', CRLF,
                            'DSPFlags : R=  M=  E=    NoiseClk :       Hz', CRLF, 'FIR      :');
{$IFDEF SPCBPMTEST}
                        if Option.bBPM then sInfo := Concat(sInfo, '                            BPM*:');
{$ELSE}
                        if Option.bBPM then sInfo := Concat(sInfo, '                            BPM :');
{$ENDIF}
                    end;
                end;
                INFO_CHANNEL_1, INFO_CHANNEL_2, INFO_CHANNEL_3, INFO_CHANNEL_4: sInfo := Concat(sInfo, CRLF, '1 :                      5 :',
                    CRLF, '2 :                      6 :', CRLF, '3 :                      7 :', CRLF, '4 :                      8 :');
                INFO_SCRIPT700: sInfo := Concat(sInfo, CRLF, 'Port  In :                Out :', CRLF, 'Work 0-3 :', CRLF, '     4-7 :',
                    CRLF, 'CmpParam :                     Wait :', CRLF, 'UsedSize :        (Ptr=      Data=      SP=   )');
            end;
        end;
        INFO_SPC_1: begin
            sInfo := Concat(sInfo, CRLF, 'Artist   : ');
            if not bytebool(Spc.Hdr.TagFormat) or not bytebool(Spc.Hdr.Artist[0]) then sInfo := Concat(sInfo, '(Unknown)')
            else sInfo := Concat(sInfo, ChrToStr(Spc.Hdr.Artist));
            sInfo := Concat(sInfo, CRLF, 'Dumper   : ');
            if not bytebool(Spc.Hdr.TagFormat) or not bytebool(Spc.Hdr.Dumper[0]) then sInfo := Concat(sInfo, '(Unknown)')
            else sInfo := Concat(sInfo, ChrToStr(Spc.Hdr.Dumper));
            sInfo := Concat(sInfo, CRLF, 'Date     : ');
            if not bytebool(Spc.Hdr.TagFormat) or not bytebool(Spc.Hdr.Date[0]) then sInfo := Concat(sInfo, '(Unknown)')
            else sInfo := Concat(sInfo, ChrToStr(Spc.Hdr.Date));
            sInfo := Concat(sInfo, CRLF, 'Comment  : ');
            if not bytebool(Spc.Hdr.TagFormat) or not bytebool(Spc.Hdr.Comment[0]) then sInfo := Concat(sInfo, '(Unknown)')
            else sInfo := Concat(sInfo, ChrToStr(Spc.Hdr.Comment));
            sInfo := Concat(sInfo, CRLF, 'PlayTime : ');
            if not bytebool(Spc.Hdr.TagFormat) or not longbool(Spc.Hdr.dwSongLen) then sInfo := Concat(sInfo, '(Unknown)')
            else begin
                sBuffer := IntToStr(Spc.Hdr.dwSongLen);
                sInfo := Concat(sInfo, sBuffer, STR_MENU_SETUP_SEC2[Status.dwLanguage], StringOfChar(' ', 10 - Length(sBuffer)));
                if not longbool(Spc.Hdr.dwFadeLen) then sInfo := Concat(sInfo, '(No Fadeout)')
                else sInfo := Concat(sInfo, 'FadeTime : ', IntToStr(Spc.Hdr.dwFadeLen), STR_MENU_SETUP_MSEC[Status.dwLanguage]);
            end;
        end;
        INFO_SPC_2: begin
            sInfo := Concat(sInfo, CRLF, 'Header   : ', ChrToStr(Spc.Hdr.FileHdr));
            sInfo := Concat(sInfo, CRLF, 'Version  : ');
            case Spc.Hdr.Version of
                $0: sInfo := Concat(sInfo, '(Unknown)');
                else sInfo := Concat(sInfo, IntToStr(longword(Spc.Hdr.Version)));
            end;
            sInfo := Concat(sInfo, CRLF, 'TagType  : ');
            case Spc.Hdr.TagFormat of
                ID666_UNKNOWN: sInfo := Concat(sInfo, '(Unknown)');
                ID666_TEXT: sInfo := Concat(sInfo, 'ID666 Text Format');
                ID666_BINARY: sInfo := Concat(sInfo, 'ID666 Binary Format');
            end;
            if not bytebool(Spc.Hdr.TagFormat) then sBuffer := '(Unknown)'
            else case Spc.Hdr.Emulator and $F of
                $0: sBuffer := '(Unknown)';
                $1: sBuffer := 'ZSNES';
                $2: sBuffer := 'Snes9x';
                $3: sBuffer := 'ZST2SPC';
                $4: sBuffer := 'etc.';
                $5: sBuffer := 'SNEShout';
                $6: sBuffer := 'ZSNES/W';
                $7: sBuffer := 'Snes9xpp';
                $8: sBuffer := 'SNESGT';
                else sBuffer := '(Undefined)';
            end;
            if Status.bBreakButton then sInfo := Concat(sInfo, CRLF, 'Emulator : ', sBuffer, CRLF,
                'Register : PC=     A=    Y=    X=    SP=   ')
            else sInfo := Concat(sInfo, CRLF, 'Emulator : ', sBuffer, StringOfChar(' ', 28 - Length(sBuffer)), 'NVPBHIZC', CRLF,
                'Register : PC=     YA=     X=   SP=   ');
        end;
    end;
    // 情報を表示
    cwStaticMain.SetCaption(pchar(sInfo));
    // 再描画を行う場合はインジケータをリセット
    if bRedraw then ResetInfo(true);
end;

// ================================================================================
// UpdateMenu - メニュー更新
// ================================================================================
procedure CWINDOWMAIN.UpdateMenu();
var
    I: longint;
    bUp: longbool;
    bDown: longbool;
    bDelete: longbool;
    bMax: longbool;
    dwIndex: longint;
    dwCount: longint;
begin
    // プレイリストの位置とアイテム数を取得
    dwIndex := cwPlayList.SendMessage(LB_GETCURSEL, NULL, NULL);
    dwCount := cwPlayList.SendMessage(LB_GETCOUNT, NULL, NULL);
    // ファイルメニューを更新
    cmFile.SetMenuEnable(MENU_FILE_PLAY, (Status.bOpen or longbool(dwCount)) and (not Status.bPlay or Status.bPause));
    cmFile.SetMenuEnable(MENU_FILE_PAUSE, Status.bPlay and not Status.bPause);
    cmFile.SetMenuEnable(MENU_FILE_RESTART, Status.bPlay);
    cmFile.SetMenuEnable(MENU_FILE_STOP, Status.bPlay);
    // ボタンを更新
    cwButtonPlay.SetWindowEnable(Status.bOpen or longbool(dwCount));
    cwButtonRestart.SetWindowEnable(Status.bPlay);
    cwButtonStop.SetWindowEnable(Status.bPlay);
    bUp := Status.bPlay and not Status.bPause;
    bDown := Status.bShiftButton;
    if Status.bChangePlay <> bUp then if bUp then cwButtonPlay.SetCaption(pchar(STR_BUTTON_PAUSE))
    else cwButtonPlay.SetCaption(pchar(STR_BUTTON_PLAY));
    if Status.bChangeShift <> bDown then if bDown then begin
        cwButtonListAdd.SetCaption(pchar(STR_BUTTON_INSERT));
    end else begin
        cwButtonListAdd.SetCaption(pchar(STR_BUTTON_APPEND));
    end;
    Status.bChangePlay := bUp;
    Status.bChangeShift := bDown;
    // 設定メニューを更新
    for I := -1 to Status.dwDeviceNum - 1 do begin
        cmSetupDevice.SetMenuCheck(MENU_SETUP_DEVICE_BASE + I + 1, Option.dwDeviceID = I);
        cmSetupDevice.SetMenuEnable(MENU_SETUP_DEVICE_BASE + I + 1, not Status.bPlay);
    end;
    for I := 0 to MENU_SETUP_CHANNEL_SIZE - 1 do begin
        cmSetupChannel.SetMenuCheck(MENU_SETUP_CHANNEL_BASE + I, Option.dwChannel = MENU_SETUP_CHANNEL_VALUE[I]);
        cmSetupChannel.SetMenuEnable(MENU_SETUP_CHANNEL_BASE + I, not Status.bPlay);
    end;
    for I := 0 to MENU_SETUP_BIT_SIZE - 1 do begin
        cmSetupBit.SetMenuCheck(MENU_SETUP_BIT_BASE + I, Option.dwBit = MENU_SETUP_BIT_VALUE[I]);
        cmSetupBit.SetMenuEnable(MENU_SETUP_BIT_BASE + I, not Status.bPlay);
    end;
    for I := 0 to MENU_SETUP_RATE_SIZE - 1 do begin
        cmSetupRate.SetMenuCheck(MENU_SETUP_RATE_BASE + I, Option.dwRate = MENU_SETUP_RATE_VALUE[I]);
        cmSetupRate.SetMenuEnable(MENU_SETUP_RATE_BASE + I, not Status.bPlay);
    end;
    for I := 0 to MENU_SETUP_INTER_SIZE - 1 do
        cmSetupInter.SetMenuCheck(MENU_SETUP_INTER_BASE + I, Option.dwInter = MENU_SETUP_INTER_VALUE[I]);
    for I := 0 to MENU_SETUP_PITCH_SIZE - 1 do
        cmSetupPitch.SetMenuCheck(MENU_SETUP_PITCH_BASE + I, Option.dwPitch = MENU_SETUP_PITCH_VALUE[I]);
    for I := 0 to MENU_SETUP_PITCH_KEY_SIZE + MENU_SETUP_PITCH_KEY_SIZE do
        cmSetupPitchKey.SetMenuCheck(MENU_SETUP_PITCH_KEY_BASE + I, Option.dwPitch = MENU_SETUP_PITCH_VALUE[MENU_SETUP_PITCH_SIZE + I]);
    cmSetupPitch.SetMenuCheck(MENU_SETUP_PITCH_ASYNC, Option.bPitchAsync);
    for I := 0 to MENU_SETUP_SEPARATE_SIZE - 1 do
        cmSetupSeparate.SetMenuCheck(MENU_SETUP_SEPARATE_BASE + I, Option.dwSeparate = MENU_SETUP_SEPARATE_VALUE[I]);
    for I := 0 to MENU_SETUP_FEEDBACK_SIZE - 1 do
        cmSetupFeedback.SetMenuCheck(MENU_SETUP_FEEDBACK_BASE + I, Option.dwFeedback = MENU_SETUP_FEEDBACK_VALUE[I]);
    for I := 0 to MENU_SETUP_SPEED_SIZE - 1 do
        cmSetupSpeed.SetMenuCheck(MENU_SETUP_SPEED_BASE + I, Option.dwSpeedBas = MENU_SETUP_SPEED_VALUE[I]);
    for I := 0 to MENU_SETUP_AMP_SIZE - 1 do
        cmSetupAmp.SetMenuCheck(MENU_SETUP_AMP_BASE + I, Option.dwAmp = MENU_SETUP_AMP_VALUE[I]);
    for I := 0 to MENU_SETUP_MUTE_NOISE_SIZE - 1 do begin
        cmSetupMute.SetMenuCheck(MENU_SETUP_MUTE_BASE + I, longbool(Option.dwMute and (1 shl I)));
        cmSetupNoise.SetMenuCheck(MENU_SETUP_NOISE_BASE + I, longbool(Option.dwNoise and (1 shl I)));
    end;
    for I := 0 to MENU_SETUP_OPTION_SIZE - 1 do if longbool(MENU_SETUP_OPTION_VALUE[I]) then
        cmSetupOption.SetMenuCheck(MENU_SETUP_OPTION_BASE + I, longbool(Option.dwOption and MENU_SETUP_OPTION_VALUE[I]));
    cmSetupTime.SetMenuCheck(MENU_SETUP_TIME_DISABLE, Option.dwPlayMax = PLAY_MAX_ENDLESS);
    cmSetupTime.SetMenuCheck(MENU_SETUP_TIME_ID666, Option.dwPlayMax = PLAY_MAX_ID666);
    cmSetupTime.SetMenuCheck(MENU_SETUP_TIME_DEFAULT, Option.dwPlayMax = PLAY_MAX_DEFAULT);
    cmSetupTime.SetMenuEnable(MENU_SETUP_TIME_START, Status.bPlay);
    cmSetupTime.SetMenuEnable(MENU_SETUP_TIME_LIMIT, Status.bPlay);
    cmSetupTime.SetMenuEnable(MENU_SETUP_TIME_RESET, Status.bOpen and Status.bTimeRepeat);
    for I := 0 to MENU_SETUP_ORDER_SIZE - 1 do
        cmSetupOrder.SetMenuCheck(MENU_SETUP_ORDER_BASE + I, Option.dwPlayOrder = longword(I));
    for I := 0 to MENU_SETUP_SEEK_SIZE - 1 do
        cmSetupSeek.SetMenuCheck(MENU_SETUP_SEEK_BASE + I, Option.dwSeekTime = MENU_SETUP_SEEK_VALUE[I]);
    cmSetupSeek.SetMenuCheck(MENU_SETUP_SEEK_FAST, Option.bSeekFast);
    cmSetupSeek.SetMenuCheck(MENU_SETUP_SEEK_ASYNC, Option.bSeekAsync);
    for I := 0 to MENU_SETUP_INFO_SIZE - 1 do
        cmSetupInfo.SetMenuCheck(MENU_SETUP_INFO_BASE + I, Option.dwInfo = longword(I));
    cmSetupInfo.SetMenuCheck(MENU_SETUP_INFO_RESET, Option.bVolumeReset);
    for I := 0 to MENU_SETUP_PRIORITY_SIZE - 1 do begin
        cmSetupPriority.SetMenuCheck(MENU_SETUP_PRIORITY_BASE + I, Option.dwPriority = MENU_SETUP_PRIORITY_VALUE[I]);
        cmSetupPriority.SetMenuEnable(MENU_SETUP_PRIORITY_BASE + I, (Status.OsVersionInfo.dwMajorVersion >= 5)
            or (MENU_SETUP_PRIORITY_VALUE[I] <= REALTIME_PRIORITY_CLASS));
    end;
    cmSetupOthers.SetMenuCheck(MENU_SETUP_TOPMOST, Option.bTopMost);
    cmSetupOthers.SetMenuCheck(MENU_SETUP_NOSLEEP, Option.dwNoSleep = NOSLEEP_DISPLAY);
    // ボタンを更新
    for I := 0 to 7 do begin
        cwCheckTrack[I].SendMessage(BM_SETCHECK, 1 - (Option.dwMute and (1 shl I)) shr I, NULL);
        cwCheckTrack[I].Invalidate();
    end;
    cwButtonVolM.SetWindowEnable(Option.dwAmp > AMP_005);
    cwButtonVolP.SetWindowEnable(Option.dwAmp < AMP_400);
    cwButtonSlow.SetWindowEnable(Option.dwSpeedBas > SPEED_001);
    cwButtonFast.SetWindowEnable(Option.dwSpeedBas < SPEED_800);
    cwButtonBack.SetWindowEnable(bUp);
    cwButtonNext.SetWindowEnable(bUp);
    // プレイリストメニューを更新
    if not longbool(dwCount) then begin
        bUp := false;
        bDown := false;
        bDelete := false;
    end else if Status.bShiftButton then begin
        bUp := dwCount > 1;
        bDown := dwCount > 1;
        bDelete := true;
    end else begin
        bUp := dwIndex > 0;
        bDown := dwIndex < dwCount - 1;
        bDelete := true;
    end;
    bMax := dwCount > 1;
    cmListPlay.SetMenuEnable(MENU_LIST_PLAY_SELECT, bDelete);
    for I := 0 to MENU_LIST_PLAY_SIZE - 1 do cmListPlay.SetMenuEnable(MENU_LIST_PLAY_BASE + I, bMax);
    bMax := dwCount < Option.dwListMax;
    cmList.SetMenuEnable(MENU_LIST_ADD, Status.bOpen and bMax);
    cmList.SetMenuEnable(MENU_LIST_INSERT, Status.bOpen and bMax);
    cmList.SetMenuEnable(MENU_LIST_REMOVE, bDelete);
    cmList.SetMenuEnable(MENU_LIST_CLEAR, bDelete);
    cmList.SetMenuEnable(MENU_LIST_UP, bUp);
    cmList.SetMenuEnable(MENU_LIST_DOWN, bDown);
    // ボタンを更新
    cwPlayList.SetWindowEnable(bDelete);
    cwButtonListAdd.SetWindowEnable(Status.bOpen and bMax);
    cwButtonListRemove.SetWindowEnable(bDelete);
    cwButtonListClear.SetWindowEnable(bDelete);
    cwButtonListUp.SetWindowEnable(bUp);
    cwButtonListDown.SetWindowEnable(bDown);
    // フォーカスを設定
    if not API_IsWindowEnabled(API_GetFocus()) then SetTabFocus(API_GetFocus(), true);
end;

// ================================================================================
// UpdateTitle - タイトル表示
// ================================================================================
procedure CWINDOWMAIN.UpdateTitle(dwFlag: longword);

function GetPercentOfSpeed(): longword;
var
    dwBase: longword;
    dwDec: longword;
begin
    dwBase := Option.dwSpeedBas * 100;
    result := dwBase div 65536;
    dwDec := dwBase mod 65536;
    if dwDec >= 32768 then Inc(result);
end;

var
    dwInfo: longword;
    sInfo: string;
begin
    // タイトルを更新しない場合は終了
    // オプション操作のフラグを設定
    if not longbool(Status.dwTitle) then exit;
{$IFDEF FREEPASCAL}
    if not (not longbool(dwFlag) or not longbool(Option.dwTimerOptionDisplay)) then begin
{$ELSE}
    if longbool(dwFlag) and longbool(Option.dwTimerOptionDisplay) then begin
{$ENDIF}
        API_SetTimer(cwWindowMain.hWnd, TIMER_ID_OPTION_DISPLAY, Option.dwTimerOptionDisplay, NULLPOINTER);
        Status.dwTitle := (Status.dwTitle and TITLE_ALWAYS_FLAG) or dwFlag;
    end;
    // タイトルを設定
    sInfo := '';
    dwInfo := Status.dwTitle and not TITLE_ALWAYS_FLAG;
    // オプションが変更された場合
    if longbool(dwInfo) then begin
        sInfo := Concat(sInfo, TITLE_INFO_HEADER[Status.dwLanguage]);
        case dwInfo of
            TITLE_INFO_SEPARATE: sInfo := Concat(sInfo, TITLE_INFO_SEPARATE_HEADER[Status.dwLanguage], IntToStr(Status.dwInfo),
                STR_MENU_SETUP_PERCENT[Status.dwLanguage]);
            TITLE_INFO_FEEDBACK: sInfo := Concat(sInfo, TITLE_INFO_FEEDBACK_HEADER[Status.dwLanguage], IntToStr(Status.dwInfo),
                STR_MENU_SETUP_PERCENT[Status.dwLanguage]);
            TITLE_INFO_SPEED: sInfo := Concat(sInfo, TITLE_INFO_SPEED_HEADER[Status.dwLanguage], IntToStr(Status.dwInfo),
                STR_MENU_SETUP_PERCENT[Status.dwLanguage]);
            TITLE_INFO_AMP: sInfo := Concat(sInfo, TITLE_INFO_AMP_HEADER[Status.dwLanguage], IntToStr(Status.dwInfo),
                STR_MENU_SETUP_PERCENT[Status.dwLanguage]);
            TITLE_INFO_SEEK: begin
                sInfo := Concat(sInfo, TITLE_INFO_SEEK_HEADER[Status.dwLanguage]);
                if Status.dwInfo >= 0 then sInfo := Concat(sInfo, TITLE_INFO_PLUS[Status.dwLanguage])
                else sInfo := Concat(sInfo, TITLE_INFO_MINUS[Status.dwLanguage]);
                if longbool(Abs(Status.dwInfo) mod 1000) then sInfo := Concat(sInfo, IntToStr(Abs(Status.dwInfo)), STR_MENU_SETUP_MSEC[Status.dwLanguage])
                else sInfo := Concat(sInfo, IntToStr(Abs(Status.dwInfo) div 1000), STR_MENU_SETUP_SEC1[Status.dwLanguage]);
                if Option.bSeekAsync and (Option.dwSpeedBas <> 65536) then sInfo := Concat(sInfo, TITLE_INFO_MULTIPLE[Status.dwLanguage],
                    IntToStr(GetPercentOfSpeed()), TITLE_INFO_PERCENT[Status.dwLanguage]);
            end;
        end;
        sInfo := Concat(sInfo, TITLE_INFO_FOOTER[Status.dwLanguage], TITLE_MAIN_HEADER[Status.dwLanguage]);
    // SPC が開かれている場合
    end else if Status.bOpen then begin
        // 最小化している場合
        if longbool(Status.dwTitle and TITLE_MINIMIZE) then begin
            // SPC のタイトルを追加
            if not bytebool(Spc.Hdr.Title[0]) then sInfo := Concat(sInfo, TITLE_NAME_UNKNOWN)
            else sInfo := Concat(sInfo, ChrToStr(Spc.Hdr.Title));
{$IFDEF FREEPASCAL}
            if not (not bytebool(Spc.Hdr.TagFormat) or not bytebool(Spc.Hdr.Game[0])) then
{$ELSE}
            if bytebool(Spc.Hdr.TagFormat) and bytebool(Spc.Hdr.Game[0]) then
{$ENDIF}
                sInfo := Concat(sInfo, TITLE_NAME_SEPARATOR[Status.dwLanguage], ChrToStr(Spc.Hdr.Game));
            sInfo := Concat(sInfo, TITLE_NAME_HEADER[Status.dwLanguage], Copy(PtrToStr(Status.lpSPCName), 1, GetSize(Status.lpSPCName, 1023)),
                TITLE_NAME_FOOTER[Status.dwLanguage], TITLE_MAIN_HEADER[Status.dwLanguage]);
        end else begin
            // SPC のファイル名を追加
            sInfo := Concat(sInfo, Copy(PtrToStr(Status.lpSPCName), 1, GetSize(Status.lpSPCName, 1023)), TITLE_MAIN_HEADER[Status.dwLanguage]);
        end;
    end;
    // タイトルを更新
    sInfo := Concat(sInfo, DEFAULT_TITLE);
    cwWindowMain.SetCaption(pchar(sInfo));
end;

// ================================================================================
// UpdateWindow - ウィンドウ更新
// ================================================================================
procedure CWINDOWMAIN.UpdateWindow();
begin
    cwWindowMain.UpdateWindow(true);
    cwWindowMain.SetWindowTopMost(Option.bTopMost);
end;

// ================================================================================
// WaveClose - デバイスを閉じる
// ================================================================================
procedure CWINDOWMAIN.WaveClose(bForce: longbool);
var
    I: longint;
begin
    // デバイスをリセット
    WaveReset(bForce);
    // サウンドバッファを解放
    for I := 0 to Option.dwBufferNum - 1 do API_waveOutUnprepareHeader(Wave.dwHandle, @Wave.Header[I], SizeOf(TWAVEHDR));
    // デバイスをクローズ
    if longbool(API_waveOutClose(Wave.dwHandle)) then API_Sleep(50)
    // デバイスが完全にクローズされるまで待機
    else while not longbool(Status.dwThreadStatus and WAVE_THREAD_DEVICE_CLOSED) do API_Sleep(16);
    Status.dwThreadStatus := Status.dwThreadStatus xor WAVE_THREAD_DEVICE_CLOSED;
    // ハンドルを初期化
    Wave.dwHandle := 0;
end;

// ================================================================================
// WaveFormat - フォーマット初期化
// ================================================================================
procedure CWINDOWMAIN.WaveFormat(dwIndex: longword);
begin
    // タグの種類を判別
    case WAVE_FORMAT_TAG_ARRAY[dwIndex] of
        WAVE_FORMAT_EXTENSIBLE: begin // WAVEFORMATEXTENSIBLE 構造体
            Wave.Format.wFormatTag := WAVE_FORMAT_EXTENSIBLE;
            Wave.Format.cbSize := 22;
            case Status.dwBit of
                BIT_IEEE: Wave.Format.SubFormat := KSDATAFORMAT_SUBTYPE_IEEE_FLOAT;
                else Wave.Format.SubFormat := KSDATAFORMAT_SUBTYPE_PCM;
            end;
        end;
        WAVE_FORMAT_PCM: begin // WAVEFORMATEX 構造体
            case Status.dwBit of
                BIT_IEEE: Wave.Format.wFormatTag := WAVE_FORMAT_IEEE_FLOAT;
                else Wave.Format.wFormatTag := WAVE_FORMAT_PCM;
            end;
            Wave.Format.cbSize := 0;
        end;
    end;
end;

// ================================================================================
// WaveInit - デバイス初期化
// ================================================================================
procedure CWINDOWMAIN.WaveInit();
var
    I: longint;
    dwBit: longword;
begin
    // 設定値を調整 (チャンネル)
    if not ((Option.dwChannel = 1) or (Option.dwChannel = 2)) then Status.dwChannel := 2
    else Status.dwChannel := Option.dwChannel;
    // 設定値を調整 (ビット)
    if not (((Option.dwBit >= 1) and (Option.dwBit <= 4)) or (Option.dwBit = -4)) then Status.dwBit := 2
    else Status.dwBit := Option.dwBit;
    // 設定値を調整 (サンプリングレート)
    if Option.dwRate < 8000 then Status.dwRate := 8000
    else if Option.dwRate > 192000 then Status.dwRate := 192000
    else Status.dwRate := Option.dwRate;
    // フラグを設定
    Status.dwWaveMessage := WAVE_MESSAGE_MAX_COUNT;
    Status.bPlay := false;
    Status.bPause := false;
    // フォーマットを初期化
    dwBit := Abs(Status.dwBit);
    Wave.Format.wBitsPerSample := word(dwBit shl 3);
    Wave.Format.nSamplesPerSec := Status.dwRate;
    Wave.Format.nChannels := word(Status.dwChannel);
    Wave.Format.nBlockAlign := word(Status.dwChannel * dwBit);
    Wave.Format.nAvgBytesPerSec := Status.dwChannel * dwBit * Status.dwRate;
    Wave.Format.wValidBitsPerSample := Wave.Format.wBitsPerSample;
    Wave.Format.dwChannelMask := $3; // FL, FR
    // バッファサイズを計算
    Wave.dwEmuSize := Option.dwBufferTime * Wave.Format.nAvgBytesPerSec div 1000 div Wave.Format.nBlockAlign;
    Wave.dwBufSize := Wave.dwEmuSize * Wave.Format.nBlockAlign;
    // バッファを確保
    for I := 0 to Option.dwBufferNum - 1 do GetMem(Wave.lpData[I], Wave.dwBufSize);
end;

// ================================================================================
// WaveOpen - デバイスを開く
// ================================================================================
function CWINDOWMAIN.WaveOpen(): longword;
var
    I: longint;
    J: longint;
    WaveHdr: ^TWAVEHDR;
begin
    // デバイスをオープン
    for I := 0 to WAVE_FORMAT_TAG_SIZE - 1 do begin
        // フォーマットを初期化
        WaveFormat(I);
        // デバイスをオープン
        for J := 0 to WAVE_FORMAT_TYPE_SIZE - 1 do begin
            result := API_waveOutOpen(@Wave.dwHandle, Option.dwDeviceID, @Wave.Format, Status.dwThreadID, NULL,
                WAVE_FORMAT_TYPE_ARRAY[J] or CALLBACK_THREAD);
            if not longbool(result) then break;
        end;
        if not longbool(result) then break;
    end;
    // フラグを設定
    Status.dwWaveMessage := WAVE_MESSAGE_MAX_COUNT;
    Status.bPlay := not longbool(result);
    Status.bPause := false;
    // デバイスのオープンに失敗した場合は終了
    if not Status.bPlay then exit;
    // デバイスが完全にオープンされるまで待機
    while not longbool(Status.dwThreadStatus and WAVE_THREAD_DEVICE_OPENED) do API_Sleep(16);
    Status.dwThreadStatus := Status.dwThreadStatus xor WAVE_THREAD_DEVICE_OPENED;
    // サウンドバッファを準備
    for I := 0 to Option.dwBufferNum - 1 do begin
        WaveHdr := @Wave.Header[I];
        API_ZeroMemory(WaveHdr, SizeOf(TWAVEHDR));
        WaveHdr.lpData := Wave.lpData[I];
        WaveHdr.dwBufferLength := Wave.dwBufSize;
        API_waveOutPrepareHeader(Wave.dwHandle, WaveHdr, SizeOf(TWAVEHDR));
    end;
end;

// ================================================================================
// WavePause - デバイス一時停止 (排他自動)
// ================================================================================
function CWINDOWMAIN.WavePause(): longbool;
begin
    // 初期化
    result := false;
    // クリティカルセクションを開始
    API_EnterCriticalSection(@CriticalSectionThread);
    // 演奏中の場合
    if Status.bPlay and not Status.bPause then begin
        // フラグを設定
        Status.bPause := true;
        // 一時停止
        API_waveOutPause(Wave.dwHandle);
        // 成功
        result := true;
    end;
    // クリティカルセクションを終了
    API_LeaveCriticalSection(@CriticalSectionThread);
end;

// ================================================================================
// WaveProc - デバイスプロシージャ (dwFlag<>WAVE_PROC_GRAPH_ONLY 時、排他必須)
// ================================================================================
procedure CWINDOWMAIN.WaveProc(dwFlag: longword);
var
    I: longint;
    J: longint;
    K: longword;
    dwIndex: longword;
    bInit: longbool;
    bWave: longbool;
    T64Count: longword;
    T64Cache: longword;
    ApuData: ^TAPUDATA;
    DspReg: ^TDSPREG;
    Voice: ^TVOICE;
    DspVoice: ^TDSPVOICE;

begin
    // バッファを設定
    dwIndex := Wave.dwIndex;
    bInit := longbool(dwFlag and WAVE_PROC_WRITE_INIT);
    bWave := longbool(dwFlag and WAVE_PROC_WRITE_WAVE);
    // 音声データを転送する場合
    if bWave then begin
        // 出力レベル値を初期化
        Apu.VolumeMaxLeft^ := 0;
        Apu.VolumeMaxRight^ := 0;
        for I := 0 to 7 do begin
            Voice := @Apu.Voices.Voice[I];
            Voice.VolumeMaxLeft := 0;
            Voice.VolumeMaxRight := 0;
        end;
        // 新しいバッファを取得
{$IFDEF SPCCYCLE}
        if Status.Script700.Data.dwWork[0] = 0 then begin
          Apu.EmuAPU(Wave.lpData[dwIndex], 768, 0);
        end;
        Inc(Status.Script700.Data.dwWork[0]);
        API_ZeroMemory(Wave.lpData[dwIndex], Wave.dwBufSize);
{$ELSE}
        if Status.bWaveWrite then Apu.EmuAPU(Wave.lpData[dwIndex], Wave.dwEmuSize, 1);
        // if Status.bWaveWrite then Apu.EmuAPU(Wave.lpData[dwIndex], 24576 * 23, 0);
{$ENDIF}
        // バッファをデバイスに転送
        if longbool(API_waveOutWrite(Wave.dwHandle, @Wave.Header[dwIndex], SizeOf(TWAVEHDR))) then begin
            // すでに再試行済みの場合は終了
            if Status.bPause then exit;
            // フラグを設定
            Status.bPause := true;
            // デッドロックを防止するため、ウィンドウメッセージを送信
            cwWindowMain.PostMessage(WM_APP_MESSAGE, WM_APP_TRY_RESUME, NULL);
            // 終了
            exit;
        end;
        // APU データをコピー
        ApuData := @Wave.Apu[dwIndex];
        ApuData.SPCApuPort.dwPort := Apu.Ram.dwPort;
        ApuData.SPCOutPort.dwPort := Apu.SPCOutPort.dwPort;
        ApuData.SPCSrcAddrs := TSPCSRCADDRS(pointer(longword(Apu.Ram) or (Apu.DspReg.SourceDirectory shl 8))^);
        ApuData.SPC700Reg := Apu.SPC700Reg^;
        ApuData.T64Count := Apu.T64Count^;
        ApuData.DspReg := Apu.DspReg^;
        ApuData.Voices := Apu.Voices^;
        ApuData.VolumeMaxLeft := Apu.VolumeMaxLeft^ * 0.0000152587890625; // 1/65536
        ApuData.VolumeMaxRight := Apu.VolumeMaxRight^ * 0.0000152587890625;
        ApuData.Script700 := Status.Script700.Data^;
        Wave.dwLastIndex := dwIndex;
        Inc(dwIndex);
        if dwIndex = Option.dwBufferNum then dwIndex := 0;
        Wave.dwIndex := dwIndex;
    end;
    // インジケータを描画しない場合は終了
    if longbool(dwFlag and WAVE_PROC_NO_GRAPH) then exit;
    // バッファを設定
    ApuData := @Wave.Apu[dwIndex];
    DspReg := @ApuData.DspReg;
    T64Count := ApuData.T64Count;
    T64Cache := Apu.T64Count^;
    // 情報を更新
    if (longbool(Option.dwDrawInfo and DRAW_INFO_ALWAYS) or longbool(Status.dwTitle and TITLE_NORMAL)) then begin
        // クリティカルセクションを開始
        API_EnterCriticalSection(@CriticalSectionStatic);
        // インジケータを描画
        if (longbool(Option.dwDrawInfo and DRAW_INFO_ALWAYS) or longbool(Status.dwReady and READY_ACTIVE))
            and not longbool(Status.dwRedrawInfo and REDRAW_LOCK_READY) then DrawInfo(ApuData, bWave);
        // クリティカルセクションを終了
        API_LeaveCriticalSection(@CriticalSectionStatic);
    end;
    // キャッシュを保存する時間になった場合
    if longbool(Status.dwNextCache) and (T64Cache >= Status.dwNextCache) then begin
        // キャッシュするバッファの位置を取得
        J := 0;
        for I := 0 to Option.dwCacheNum - 1 do if T64Cache >= Status.SPCCache[I].Spc.Hdr.dwFadeLen then J := I;
        // キャッシュを保存
        SaveSeekCache(J);
    end;
    // タイムアウトが発生していない場合
    // 初期化中以外、かつ音声出力中、かつタイムアウト処理中以外、かつ（区間リピート設定済み、またはエンドレス以外）
    if not bInit and bWave and longbool(Status.dwNextTimeout) and (Status.bTimeRepeat or (Option.dwPlayMax > PLAY_MAX_ENDLESS)) then begin
        // パラメータ初期化
        J := 0;
        K := 0;
        // 演奏時間が終了位置を経過したか確認
        if Status.bTimeRepeat then begin
            if T64Count >= Status.dwLimitTime then J := 1;
        end else begin
            if T64Count >= Status.dwNextTimeout then J := 1;
        end;
        // 無音時間を確認
        if Status.bNextDefault then begin
            for I := 0 to 7 do begin
                DspVoice := @DspReg.Voice[I];
{$IFDEF FREEPASCAL}
                if not (not bytebool(DspVoice.VolumeLeft or DspVoice.VolumeRight) or not bytebool(DspVoice.CurrentEnvelope)) then begin
{$ELSE}
                if bytebool(DspVoice.VolumeLeft or DspVoice.VolumeRight) and bytebool(DspVoice.CurrentEnvelope) then begin
{$ENDIF}
                    K := 1;
                    break;
                end;
            end;
            if longbool(Status.dwMuteCounter or K) then begin
                Status.dwMuteTimeout := 0;
                if longbool(Status.dwMuteCounter) then Dec(Status.dwMuteCounter);
            end else begin
                if not longbool(Status.dwMuteTimeout) then Status.dwMuteTimeout := T64Count + (Option.dwNextTime shl 6);
                if T64Count >= Status.dwMuteTimeout then J := 1;
            end;
        end;
        // 次の曲を演奏する場合
        if longbool(J) then begin
            // 初期化 (タイムアウトを設定)
            Status.dwNextTimeout := 0;
            // デッドロックを防止するため、ウィンドウメッセージを送信
            cwWindowMain.PostMessage(WM_APP_MESSAGE, WM_APP_NEXT_PLAY, NULL);
        end;
    end;
end;

// ================================================================================
// WaveQuit - デバイス解放
// ================================================================================
procedure CWINDOWMAIN.WaveQuit();
var
    I: longint;
begin
{$IFNDEF TRANSMITSPC}
    // 演奏中の場合はデバイスをクローズ
    if Status.bPlay then WaveClose(false);
{$ENDIF}
    // バッファを解放
    for I := 0 to Option.dwBufferNum - 1 do FreeMem(Wave.lpData[I], Wave.dwBufSize);
end;

// ================================================================================
// WaveReset - デバイスリセット (排他自動)
// ================================================================================
procedure CWINDOWMAIN.WaveReset(bForce: longbool);
var
    I: longint;
    dwResult: longword;
begin
    // Script700 を強制終了
    Status.Script700.Data.cStatusFlag := Status.Script700.Data.cStatusFlag or $80;
    Status.bWaveWrite := false;
    // クリティカルセクションを開始
    API_EnterCriticalSection(@CriticalSectionThread);
    // フラグを設定
    Status.dwWaveMessage := WAVE_MESSAGE_MAX_COUNT;
    Status.bPlay := false;
    Status.bPause := false;
    // アイドルまでのカウントを設定
    Status.dwThreadIdle := Option.dwBufferNum;
    // デバイスをリセット
    dwResult := API_waveOutReset(Wave.dwHandle);
    // クリティカルセクションを終了
    API_LeaveCriticalSection(@CriticalSectionThread);
    // デバイスがアイドル状態になるまで待機
    if bForce or longbool(dwResult) then API_Sleep(50)
    else while longbool(Status.dwThreadIdle) do API_Sleep(16);
    // インジケータをクリア
    for I := 0 to Option.dwBufferNum - 1 do API_ZeroMemory(@Wave.Apu[I], SizeOf(TAPUDATA));
{$IFDEF SPCBPMTEST}
    // テンポ解析が有効な場合、BPM 解析を停止
    if Option.bBPM then Apu.BPMStop();
{$ELSE}
    // テンポ解析が有効な場合、テンポをクリア
    if Option.bBPM then API_ZeroMemory(@Status.Tempo, SizeOf(TTEMPO));
{$ENDIF}
end;

// ================================================================================
// WaveResume - デバイス再開 (排他自動)
// ================================================================================
function CWINDOWMAIN.WaveResume(): longbool;
begin
    // 初期化
    result := false;
    // クリティカルセクションを開始
    API_EnterCriticalSection(@CriticalSectionThread);
    // 一時停止中の場合
    if Status.bPlay and Status.bPause then begin
        // フラグを設定
        Status.bPause := false;
        // 一時停止を解除
        API_waveOutRestart(Wave.dwHandle);
        // 成功
        result := true;
    end;
    // クリティカルセクションを終了
    API_LeaveCriticalSection(@CriticalSectionThread);
end;

// ================================================================================
// WaveSave - WAVE ファイルの保存
// ================================================================================
function CWINDOWMAIN.WaveSave(lpFile: pointer; bShift: longbool; bQuiet: longbool): longbool;
var
    I: longint;
    hFile: longword;
    dwWaveL: longword;
    dwWaveB: longword;
    dwSizeB: longword;
    dwSizeH: longword;
    dwSizeP: longword;
    dwSizeL: longword;
    dwSizeT: longword;
    dwPCent: longword;
    dwBlank: longword;
    dwCount: longword;
    qwWaveL: int64;
    qwData: TLONGLONG;
    lpData: pointer;

function GetMBString(dwSize: longword): string;
var
    dwInt: longword;
    dwDec1: longword;
    dwDec2: longword;
begin
    dwInt := dwSize shr 20;
    dwDec1 := (dwSize and $FFFFF) * 100 shr 20;
    dwDec2 := dwDec1 mod 10;
    dwDec1 := (dwDec1 - dwDec2) div 10;
    result := Concat(IntToStr(dwInt), '.', IntToStr(dwDec1), IntToStr(dwDec2));
end;

begin
    // 初期化
    result := false;
    // 演奏停止
    SPCStop(false);
    // クリティカルセクションを開始
    API_EnterCriticalSection(@CriticalSectionThread);
    // SPC を APU に転送
    Apu.LoadSPCFile(@Spc);
    // SPC 演奏設定
    SPCOption();
    // 演奏時間、フェードアウト時間を設定
    SPCTime(true, true, true);
    // クリティカルセクションを終了
    API_LeaveCriticalSection(@CriticalSectionThread);
    // ヘッダサイズを計算
    case Option.dwWaveFormat of
        1: WaveFormat(WAVE_FORMAT_INDEX_PCM);
        2: WaveFormat(WAVE_FORMAT_INDEX_EXTENSIBLE);
        else case Status.dwBit of
            BIT_8, BIT_16: WaveFormat(WAVE_FORMAT_INDEX_PCM);
            else WaveFormat(WAVE_FORMAT_INDEX_EXTENSIBLE);
        end;
    end;
    dwSizeH := 16;
    if wordbool(Wave.Format.cbSize) then Inc(dwSizeH, Wave.Format.cbSize + 2);
    dwSizeP := dwSizeH + 28; // "RIFF" + 4 + "WAVE" + "fmt " + 4 + HEADER + "data" + 4
    // 無音のサイズを計算
    dwWaveL := Option.dwWaveBlank; // 最初の無音時間
    dwBlank := 0;
    if (dwWaveL < $80000000) and not longbool(Option.dwMute and $FF) then begin
        Inc(dwWaveL, dwWaveL mod 100); // 間隔調整
        dwBlank := dwWaveL div 100;
    end;
    // 音声のサイズを計算
    qwWaveL := int64((Status.dwAPUPlayTime + Status.dwAPUFadeTime) shr 6) * SPEED_100;
    dwWaveB := Option.dwSpeedBas + longword(longint(Option.dwSpeedBas) * Option.dwSpeedTun div SPEED_100);
    dwWaveL := qwWaveL div dwWaveB;
    Inc(dwWaveL, dwWaveL mod 100); // 間隔調整
    dwCount := dwWaveL div 100;
    // バッファサイズを計算
    dwWaveB := Wave.Format.nAvgBytesPerSec div 10 div longword(Wave.Format.nBlockAlign); // 100ms ごとのサンプル数
    dwSizeB := dwWaveB * longword(Wave.Format.nBlockAlign); // 100ms ごとのバイト数
    dwSizeT := dwSizeP + (dwBlank + dwCount + 10) * dwSizeB; // ヘッダ + 最初の無音 + 音声 + 最後の無音
    // 確認メッセージを表示
    if not bQuiet then if cwWindowMain.MessageBox(pchar(Concat(WARN_WAVE_SIZE_1[Status.dwLanguage], GetMBString(dwSizeT),
        WARN_WAVE_SIZE_2[Status.dwLanguage])), pchar(DEFAULT_TITLE), MB_ICONQUESTION or MB_YESNO or MB_DEFBUTTON2) <> IDYES then exit;
    // ファイルをオープン
    hFile := INVALID_HANDLE_VALUE;
    if IsSafePath(lpFile) then begin
        API_MakeSureDirectoryPathExists(lpFile);
        hFile := API_CreateFile(lpFile, GENERIC_WRITE, FILE_SHARE_READ, NULLPOINTER, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL
            or FILE_FLAG_SEQUENTIAL_SCAN, NULL);
    end;
    // ファイルのオープンに失敗した場合はメッセージを表示して終了
    if hFile = INVALID_HANDLE_VALUE then begin
        ShowErrMsg(252);
        exit;
    end;
    // 進行状況を表示
    cwWindowMain.SetCaption(pchar(Concat(TITLE_INFO_HEADER[Status.dwLanguage], TITLE_INFO_FILE_HEADER[Status.dwLanguage],
        TITLE_INFO_FOOTER[Status.dwLanguage], TITLE_MAIN_HEADER[Status.dwLanguage], DEFAULT_TITLE)));
    // クリティカルセクションを開始
    API_EnterCriticalSection(@CriticalSectionThread);
    // WAVE ヘッダを出力 (サイズ = WaveHeader + 28)
    dwSizeT := 0;
    qwData.l := $46464952; // "RIFF" + サイズ (後で計算)
    API_WriteFile(hFile, @qwData, 8, @dwSizeT, NULLPOINTER);
    qwData.l := $45564157; // "WAVE"
    API_WriteFile(hFile, @qwData, 4, @dwSizeT, NULLPOINTER);
    qwData.l := $20746D66; // "fmt " + サイズ
    qwData.h := dwSizeH;
    API_WriteFile(hFile, @qwData, 8, @dwSizeT, NULLPOINTER);
    API_WriteFile(hFile, @Wave.Format, dwSizeH, @dwSizeT, NULLPOINTER);
    qwData.l := $61746164; // "data" + サイズ (後で計算)
    API_WriteFile(hFile, @qwData, 8, @dwSizeT, NULLPOINTER);
    // バッファを確保
    GetMem(lpData, dwSizeB);
    // 最初の無音を出力
    if Status.dwBit = BIT_8 then API_FillMemory(lpData, dwSizeB, $80)
    else API_ZeroMemory(lpData, dwSizeB);
    if longbool(dwBlank) then for I := 0 to dwBlank - 1 do begin
        API_WriteFile(hFile, lpData, dwSizeB, @dwSizeT, NULLPOINTER);
        Inc(dwSizeP, dwSizeB);
    end;
    // WAVE データを出力
    dwPCent := $FFFFFFFF;
    dwSizeL := dwSizeP; // 最後のポインタ、現在のポインタ
    if (Option.dwWaveBlank >= 0) and not longbool(Option.dwMute and $FF) then dwSizeT := 0 else dwSizeT := 1;
    for I := 0 to dwCount - 1 do begin
        // 新しいバッファを取得
        Apu.VolumeMaxLeft^ := 0;
        Apu.VolumeMaxRight^ := 0;
        Apu.EmuAPU(lpData, dwWaveB, 1);
        // 無音を検出
        if not longbool(dwSizeT) then begin
            if (Apu.VolumeMaxLeft^ >= MIN_WAVE_LEVEL) or (Apu.VolumeMaxRight^ >= MIN_WAVE_LEVEL) then Inc(dwSizeT);
        end;
        // ファイルに出力
        if longbool(dwSizeT) then begin
            API_WriteFile(hFile, lpData, dwSizeB, @dwSizeT, NULLPOINTER);
            Inc(dwSizeP, dwSizeB);
            if (Apu.VolumeMaxLeft^ >= MIN_WAVE_LEVEL) or (Apu.VolumeMaxRight^ >= MIN_WAVE_LEVEL) then dwSizeL := dwSizeP;
        end;
        // 進行状況を表示
        dwWaveL := longword(I + 1) * 10 div dwCount * 10;
        if dwWaveL <> dwPCent then begin
            dwPCent := dwWaveL;
            cwWindowMain.SetCaption(pchar(Concat(TITLE_INFO_HEADER[Status.dwLanguage], TITLE_INFO_FILE_HEADER[Status.dwLanguage],
                IntToStr(dwPCent), TITLE_INFO_FILE_PROC[Status.dwLanguage], TITLE_INFO_FOOTER[Status.dwLanguage],
                TITLE_MAIN_HEADER[Status.dwLanguage], DEFAULT_TITLE)));
        end;
    end;
    // 最後の無音 (1000ms) を出力
    if Status.dwBit = BIT_8 then API_FillMemory(lpData, dwSizeB, $80)
    else API_ZeroMemory(lpData, dwSizeB);
    for I := 0 to 9 do begin
        API_WriteFile(hFile, lpData, dwSizeB, @dwSizeT, NULLPOINTER);
        Inc(dwSizeL, dwSizeB);
    end;
    // バッファを解放
    FreeMem(lpData, dwSizeB);
    // バッファサイズを出力
    dwSizeB := 0;
    API_SetFilePointer(hFile, 4, @dwSizeB, FILE_BEGIN);
    dwSizeP := dwSizeL - 8; // ファイルサイズ - ("RIFF" + 4)
    API_WriteFile(hFile, @dwSizeP, 4, @dwSizeT, NULLPOINTER);
    API_SetFilePointer(hFile, dwSizeH + 24, @dwSizeB, FILE_BEGIN);
    dwSizeP := dwSizeL - dwSizeH - 28; // データサイズ
    API_WriteFile(hFile, @dwSizeP, 4, @dwSizeT, NULLPOINTER);
    // ファイルの終端位置を設定
    API_SetFilePointer(hFile, dwSizeL, @dwSizeB, FILE_BEGIN);
    API_SetEndOfFile(hFile);
    // ファイルをクローズ
    API_CloseHandle(hFile);
    // クリティカルセクションを終了
    API_LeaveCriticalSection(@CriticalSectionThread);
    // タイトルを更新
    UpdateTitle(NULL);
    // メッセージを表示
    if not bQuiet then cwWindowMain.MessageBox(pchar(Concat(INFO_WAVE_FINISH_1[Status.dwLanguage], GetMBString(dwSizeL),
        INFO_WAVE_FINISH_2[Status.dwLanguage])), pchar(DEFAULT_TITLE), MB_ICONINFORMATION or MB_OK);
    // 成功
    result := true;
end;

// ================================================================================
// WaveStart - デバイス演奏開始 (排他必須)
// ================================================================================
procedure CWINDOWMAIN.WaveStart();
var
    I: longint;
    J: longint;
begin
    // 一時停止
    API_waveOutPause(Wave.dwHandle);
    // バッファ転送
    J := Option.dwBufferNum - 1;
    for I := 0 to J do WaveProc((J - I) or WAVE_PROC_WRITE_WAVE or WAVE_PROC_WRITE_INIT);
    // 演奏開始
    API_waveOutRestart(Wave.dwHandle);
end;

// ================================================================================
// WindowProc - メッセージ割込
// ================================================================================
function CWINDOWMAIN.WindowProc(hWnd: longword; msg: longword; wParam: longword; lParam: longword; var dwDef: longword): longword;

procedure SetSPCTime();
begin
    // 演奏時間、フェードアウト時間を設定
    SPCTime(true, false, false);
    // SPC が開かれていない、または演奏停止中の場合は終了
    if not Status.bOpen or not Status.bPlay then exit;
    // スレッドに設定変更を通知
    API_PostThreadMessage(Status.dwThreadID, WM_APP_MESSAGE, WM_APP_SPC_TIME, NULL);
end;

procedure ResetRepeatPosision();
begin
    // リピート開始位置、リピート終了位置を初期化
    Status.dwStartTime := 0;
    Status.dwLimitTime := Status.dwDefaultTimeout;
    Status.bTimeRepeat := false;
end;

procedure ResetTimeMark();
begin
    // SPC が開かれていない、または区間リピートが無効の場合は終了
    if not Status.bOpen or not Status.bTimeRepeat then exit;
    // リピート開始位置、リピート終了位置を初期化
    Option.dwPlayOrder := Status.dwPlayOrder;
    ResetRepeatPosision();
    // インジケータを再描画
    cwWindowMain.PostMessage(WM_APP_MESSAGE, WM_APP_REDRAW, NULL);
end;

procedure ChangeSPCTime();
var
    dwPlayMax: longint;
begin
    // 現在の設定値を記録
    dwPlayMax := Option.dwPlayMax;
    // フラグを設定
    if wParam = MENU_SETUP_TIME_DISABLE then Option.dwPlayMax := PLAY_MAX_ENDLESS
    else if wParam = MENU_SETUP_TIME_ID666 then Option.dwPlayMax := PLAY_MAX_ID666
    else if wParam = MENU_SETUP_TIME_DEFAULT then Option.dwPlayMax := PLAY_MAX_DEFAULT;
    // 演奏時間、フェードアウト時間を設定
    SetSPCTime();
    // 設定が変更された場合は、リピート開始位置、リピート終了位置を初期化
    if dwPlayMax <> Option.dwPlayMax then begin
        if Status.bTimeRepeat then Option.dwPlayOrder := Status.dwPlayOrder;
        ResetRepeatPosision();
    end;
    // インジケータを再描画
    cwWindowMain.PostMessage(WM_APP_MESSAGE, WM_APP_REDRAW, NULL);
end;

procedure ForceRepeatMode();
begin
    // 強制的にリピートモードに設定
    if not Status.bTimeRepeat then Status.dwPlayOrder := Option.dwPlayOrder;
    if Option.dwPlayOrder <> PLAY_ORDER_STOP then Option.dwPlayOrder := PLAY_ORDER_REPEAT;
    Status.bTimeRepeat := true;
    // インジケータを再描画
    cwWindowMain.PostMessage(WM_APP_MESSAGE, WM_APP_REDRAW, NULL);
end;

procedure SetStartTimeMark();
var
    dwTime: longword;
begin
    // SPC が開かれていない、演奏停止中、またはタイムアウトが発生した場合は終了
    if not Status.bOpen or not Status.bPlay or not longbool(Status.dwNextTimeout) then exit;
    // 現在の場所がシークバーを超える場合は終了
    dwTime := Wave.Apu[Wave.dwIndex].T64Count;
    if dwTime >= Status.dwDefaultTimeout then exit;
    // 現在の場所をリピート開始位置に設定
    Status.dwStartTime := dwTime;
    if Status.dwLimitTime < Status.dwStartTime then Status.dwLimitTime := Status.dwStartTime;
    // 強制的にリピートモードに設定
    ForceRepeatMode();
end;

procedure SetLimitTimeMark();
begin
    // SPC が開かれていない、演奏停止中、またはタイムアウトが発生した場合は終了
    if not Status.bOpen or not Status.bPlay or not longbool(Status.dwNextTimeout) then exit;
    // 現在の場所をリピート終了位置に設定
    Status.dwLimitTime := Wave.Apu[Wave.dwIndex].T64Count;
    if Status.dwStartTime > Status.dwLimitTime then Status.dwStartTime := Status.dwLimitTime;
    // 強制的にリピートモードに設定
    ForceRepeatMode();
end;

procedure ChangeStaticClick();
var
    X: longword;
    Y: longword;
begin
    // クリック位置を取得
    X := Status.DblClickPoint.x;
    Y := Status.DblClickPoint.y;
    if Status.dwScale <> 2 then begin
        X := Trunc(longint(X + X) / Status.dwScale);
        Y := Trunc(longint(Y + Y) / Status.dwScale);
    end;
    // シークバー上でダブルクリックされた場合は終了
    if not ((X < 140) or (X > 280) or (Y < STATIC_SEEKBAR_TOP) or (Y >= STATIC_SEEKBAR_BOTTOM)) then begin
        if longbool(Option.dwSeekBar) or (Option.dwPlayMax > PLAY_MAX_ENDLESS) then exit;
    end;
    // 情報表示切替
    if Status.bShiftButton then SetChangeInfo(false, -1)
    else SetChangeInfo(false, 1);
end;

function LostFocusWindow(): longword;
begin
    // 初期化
    result := 1;
    // フォーカスがあるウィンドウを記録
    if longbool(API_GetFocus()) and (API_GetFocus() <> cwWindowMain.hWnd) then Status.dwFocusHandle := API_GetFocus();
    // Shift キーを解除
    SetChangeFunction(false);
    // Ctrl キーを解除
    Status.bCtrlButton := false;
    // メニュー境界を描画
    if Option.dwTheme = THEME_DARK then cmMain.DrawMenuBorder(cwWindowMain.hWnd);
end;

function GetFocusWindow(): longword;
begin
    // 初期化
    result := 1;
    // Shift キーを設定
    SetChangeFunction(true);
    // メニュー境界を描画
    if Option.dwTheme = THEME_DARK then cmMain.DrawMenuBorder(cwWindowMain.hWnd);
    // ウィンドウにフォーカスを設定
    if (API_GetForegroundWindow() = cwWindowMain.hWnd) and longbool(Status.dwFocusHandle) then
        cwWindowMain.PostMessage(WM_APP_MESSAGE, WM_APP_ACTIVATE, NULL);
end;

function TransmitFile(bAutoPlay: longbool): longbool;
var
    lpFile: pointer;
    dwType: longword;
begin
    // 初期化
    result := false;
    // メッセージボックス表示中の場合
    if cwWindowMain.bMessageBox then begin
        // 元に戻す
        cwStaticFile.SetCaption(pchar(FILE_DEFAULT));
    end else begin
        // バッファを確保
        GetMem(lpFile, 1024);
        // バッファを初期化
        API_ZeroMemory(lpFile, 1024);
        // ファイル名を取得
        cwStaticFile.GetCaption(lpFile, 1024);
        // 元に戻す
        cwStaticFile.SetCaption(pchar(FILE_DEFAULT));
        // ファイルを開く
        dwType := GetFileType(lpFile, true, true);
        case dwType of
            FILE_TYPE_SPC: result := SPCLoad(lpFile, bAutoPlay);
            FILE_TYPE_LIST_A, FILE_TYPE_LIST_B: result := ListLoad(lpFile, dwType, false);
            FILE_TYPE_SCRIPT700: result := ReloadScript700(lpFile);
        end;
        // バッファを解放
        FreeMem(lpFile, 1024);
    end;
end;

procedure GetFocusWindowAfter();
begin
    // フォーカスを設定
    if API_GetFocus() = cwWindowMain.hWnd then begin
        API_SetFocus(Status.dwFocusHandle);
        Status.dwFocusHandle := NULL;
    end;
    // 基本優先度を取得
    Option.dwPriority := API_GetPriorityClass(API_GetCurrentProcess());
    // 常時手前を取得
    Option.bTopMost := longbool(cwWindowMain.GetWindowStyleEx() and WS_EX_TOPMOST);
    // フラグを設定
    Status.dwReady := READY_ACTIVE;
    // デバイスを更新
    UpdateDevice(Option.dwDeviceID, WAVE_DEVICE_UPDATE_LIST);
    // メニューを更新
    UpdateMenu();
end;

procedure RedrawInfo(bWindow: boolean);
begin
    // クリティカルセクションを開始
    API_EnterCriticalSection(@CriticalSectionStatic);
    // ウィンドウ全体を再描画する場合
    if (bWindow) then begin
        // ウィンドウを再描画
        API_RedrawWindow(cwWindowMain.hWnd, NULLPOINTER, NULL, RDW_INVALIDATE or RDW_ERASE or RDW_UPDATENOW or RDW_ALLCHILDREN);
        // メニュー境界を描画
        if Option.dwTheme = THEME_DARK then cmMain.DrawMenuBorder(cwWindowMain.hWnd);
    end;
    // 再描画がロックされていない場合
    if not longbool(Status.dwRedrawInfo and REDRAW_LOCK_CRITICAL) then begin
        // 再描画フラグを設定
        Status.dwRedrawInfo := REDRAW_ON;
        // インジケータを再描画
        if Status.bOpen then WaveProc(WAVE_PROC_GRAPH_ONLY);
    end;
    // クリティカルセクションを終了
    API_LeaveCriticalSection(@CriticalSectionStatic);
end;

procedure ClickSeekBar();
var
    X: longword;
    Y: longword;
begin
    // SPC が開かれていない、タイムアウトが発生した、またはシークバーが無効の場合は終了
    if not Status.bOpen or not longbool(Status.dwNextTimeout)
        or (not longbool(Option.dwSeekBar) and (Option.dwPlayMax = PLAY_MAX_ENDLESS)) then exit;
    // クリック位置を取得
    X := lParam and $FFFF;
    Y := lParam shr 16;
    if Status.dwScale <> 2 then begin
        X := Trunc(longint(X + X) / Status.dwScale);
        Y := Trunc(longint(Y + Y) / Status.dwScale);
    end;
    // クリック位置が範囲外の場合は終了
    if (X < 140) or (X > 280) or (Y < STATIC_SEEKBAR_TOP) or (Y >= STATIC_SEEKBAR_BOTTOM) then exit;
    // クリック位置の割合を取得
    Y := ((X - 139) * Status.dwDefaultTimeout div 141) + 1;
    if X = 140 then X := 0 else X := ((X - 140) * Status.dwDefaultTimeout div 141) + 1;
    if X > Status.dwDefaultTimeout then X := Status.dwDefaultTimeout;
    if Y > Status.dwDefaultTimeout then Y := Status.dwDefaultTimeout;
    // メッセージ処理
    case wParam and $FFFFF000 of
        WM_APP_SEEK: begin
            // スレッドにシークを通知
            API_PostThreadMessage(Status.dwThreadID, WM_APP_MESSAGE, WM_APP_SPC_SEEK + (longword(Status.bCtrlButton) and $1 xor $1), X);
        end;
        WM_APP_START_TIME: begin
            // リピート開始位置を設定
            if X < Status.dwLimitTime then Status.dwStartTime := X
            else Status.dwStartTime := Status.dwLimitTime;
            // 強制的にリピートモードに設定
            ForceRepeatMode();
        end;
        WM_APP_LIMIT_TIME: begin
            // リピート終了位置を設定
            if Y > Status.dwStartTime then Status.dwLimitTime := Y
            else Status.dwLimitTime := Status.dwStartTime;
            // 強制的にリピートモードに設定
            ForceRepeatMode();
        end;
        WM_APP_RESET_TIME: ResetTimeMark();
    end;
end;

procedure SetNextPlay();
var
    dwFlag: longword;
begin
    // SPC が開かれていない、または演奏停止中の場合は終了
    if not Status.bOpen or not Status.bPlay then exit;
    // ウィンドウにフォーカスがない場合はカーソルを選択
    if API_GetForegroundWindow() = cwWindowMain.hWnd then dwFlag := NULL
    else dwFlag := LIST_NEXT_PLAY_SELECT or LIST_NEXT_PLAY_CENTER;
    // 次の曲を再生
    ListNextPlay(Option.dwPlayOrder, dwFlag);
end;

procedure MinimizeWindow();
begin
    // 最小化されている場合は終了
    if longbool(cwWindowMain.GetWindowStyle() and WS_MINIMIZE) then exit;
    // フォーカスが設定されているウィンドウを記録
    LostFocusWindow();
    // 最小化
    cwWindowMain.SetWindowShowStyle(SW_MINIMIZE);
end;

function ReadAPURam(dwAddr: longword): longword;
var
    X: longword;
begin
    // RAM 値の読み取り
    API_MoveMemory(@X, pointer(longword(Apu.Ram) or dwAddr), 4);
    result := X;
end;

procedure WriteAPURam(dwAddr: longword; dwVal: longword);
var
    X: longword;
begin
    // RAM 値の書き込み
    for X := 0 to 3 do Apu.SetAPURAM(dwAddr + X, dwVal shr (X shl 3));
end;

function ReadSPCReg(dwAddr: longword): longword;
var
    X: longword;
begin
    // SPC レジスタを取得
    case dwAddr of
        0: result := Apu.SPC700Reg.pc and $FFFF;
        1: result := Apu.SPC700Reg.ya and $FFFF;
        2: result := ((Apu.SPC700Reg.sp and $FF) shl 8) or (Apu.SPC700Reg.x and $FF);
        3: begin
            result := 0;
            for X := 0 to 7 do result := result or ((Apu.SPC700Reg.psw[X] and $100) shr (8 - X));
        end;
        else result := 0;
    end;
end;

procedure WriteSPCReg(dwAddr: longword; dwVal: longword);
var
    X: longword;
begin
    // SPC レジスタを設定
    case dwAddr of
        0: Apu.SPC700Reg.Word[16] := dwVal and $FFFF;
        1: Apu.SPC700Reg.Word[18] := dwVal and $FFFF;
        2: begin
            Apu.SPC700Reg.Byte[40] := (dwVal and $FF00) shr 8;
            Apu.SPC700Reg.Byte[44] := dwVal and $FF;
        end;
        3: for X := 0 to 7 do Apu.SPC700Reg.Byte[(X shl 2) or $1] := (dwVal shr X) and $1;
    end;
end;

procedure ForceEmuAPU();
var
    lpData: pointer;
begin
    // 演奏停止中の場合は終了
    if not Status.bEmuDebug or not Status.bPlay then exit;
    // クリティカルセクションを開始
    API_EnterCriticalSection(@CriticalSectionThread);
    // バッファを確保
    GetMem(lpData, 16);
    // 強制エミュレート
    Apu.EmuAPU(lpData, 1, 1);
    // クリティカルセクションを終了
    API_LeaveCriticalSection(@CriticalSectionThread);
    // バッファを解放
    FreeMem(lpData, 16);
end;

function WaveOutput(bShift: longbool; bQuiet: longbool): longbool;
var
    lpFile: pointer;
begin
    // 初期化
    result := false;
    // メッセージボックス表示中の場合
    if cwWindowMain.bMessageBox then begin
        // 元に戻す
        cwStaticFile.SetCaption(pchar(FILE_DEFAULT));
    end else begin
        // バッファを確保
        GetMem(lpFile, 1024);
        // バッファを初期化
        API_ZeroMemory(lpFile, 1024);
        // ファイル名を取得
        cwStaticFile.GetCaption(lpFile, 1024);
        // 元に戻す
        cwStaticFile.SetCaption(pchar(FILE_DEFAULT));
        // WAVE ファイルを保存
        result := WaveSave(lpFile, bShift, bQuiet);
        // バッファを解放
        FreeMem(lpFile, 1024);
    end;
end;

procedure RedrawResume(lParam: longword);
var
    dwBuffer: longword;
    Setting: ^TPOWERBROADCAST_SETTING;
begin
    // 起動準備ができていない場合は終了
    if not longbool(Status.dwReady) or not longbool(Option.dwTimerRedrawResume) then exit;
    // ディスプレイの電源状態を確認
    if longbool(lParam) then begin
        // ディスプレイの電源状態イベントでない場合は終了
        Setting := pointer(lParam);
        if not IsEqualsGUID(Setting.PowerSetting, GUID_CONSOLE_DISPLAY_STATE) then exit;
        // ディスプレイの電源状態によって、準備完了フラグを設定
        API_MoveMemory(@dwBuffer, @Setting.Data, 4);
        if dwBuffer = $0 then Status.dwReady := READY_INACTIVE;
        if dwBuffer = $1 then Status.dwReady := READY_ACTIVE;
        // ディスプレイの電源がオンでない場合は終了
        if dwBuffer <> $1 then exit;
    end;
    // ウィンドウの再描画を予約
    API_KillTimer(cwWindowMain.hWnd, TIMER_ID_REDRAW_RESUME);
    API_SetTimer(cwWindowMain.hWnd, TIMER_ID_REDRAW_RESUME, Option.dwTimerRedrawResume, NULLPOINTER);
end;

begin
    // 初期化
    result := 0;
    // メニューを右クリックされた場合は、メッセージをメニュークリックイベントに変換
    if (msg = WM_MENURBUTTONUP) or ((msg = WM_MENUCHAR) and ((wParam and $FFFF) = $20)) then begin
        wParam := Status.dwMenuFlags and $FFFF;
        if not longbool(API_GetMenuState(lParam, wParam, MF_BYCOMMAND) and MF_GRAYED) then begin
            if msg = WM_MENUCHAR then result := $30000 or wParam else result := 0;
            msg := WM_COMMAND;
            lParam := 0;
            dwDef := 1;
        end;
    end;
    // メッセージ処理
    case msg of
        WM_SYSCOMMAND, WM_COMMAND, WM_APP_COMMAND: begin // システムコマンド処理
            if (msg = WM_SYSCOMMAND) or (msg = WM_APP_COMMAND) or ((msg = WM_COMMAND) and not longbool(lParam)) then begin // メニューが選択された
                case wParam of
                    MENU_FILE_OPEN: OpenFile();
                    MENU_FILE_SAVE: SaveFile();
                    MENU_FILE_PLAY, MENU_FILE_PAUSE: SPCPlay(PLAY_TYPE_AUTO);
                    MENU_FILE_RESTART: SPCStop(true);
                    MENU_FILE_STOP: SPCStop(false);
                    MENU_FILE_EXIT: cwWindowMain.PostMessage(WM_QUIT, NULL, NULL);
                    MENU_SETUP_PITCH_ASYNC: Option.bPitchAsync := not Option.bPitchAsync;
                    MENU_SETUP_SEEK_FAST: Option.bSeekFast := not Option.bSeekFast;
                    MENU_SETUP_SEEK_ASYNC: Option.bSeekAsync := not Option.bSeekAsync;
                    MENU_SETUP_MUTE_ALL_ENABLE: Option.dwMute := $FF;
                    MENU_SETUP_MUTE_ALL_DISABLE: Option.dwMute := $0;
                    MENU_SETUP_MUTE_ALL_XOR: Option.dwMute := Option.dwMute xor $FF;
                    MENU_SETUP_NOISE_ALL_ENABLE: Option.dwNoise := $FF;
                    MENU_SETUP_NOISE_ALL_DISABLE: Option.dwNoise := $0;
                    MENU_SETUP_NOISE_ALL_XOR: Option.dwNoise := Option.dwNoise xor $FF;
                    MENU_SETUP_TIME_DISABLE, MENU_SETUP_TIME_ID666, MENU_SETUP_TIME_DEFAULT: ChangeSPCTime();
                    MENU_SETUP_TIME_START: SetStartTimeMark();
                    MENU_SETUP_TIME_LIMIT: SetLimitTimeMark();
                    MENU_SETUP_TIME_RESET: ResetTimeMark();
                    MENU_SETUP_INFO_RESET: Option.bVolumeReset := not Option.bVolumeReset;
                    MENU_SETUP_TOPMOST: begin
                        // フラグを設定
                        Option.bTopMost := not Option.bTopMost;
                        // ウィンドウを更新
                        UpdateWindow();
                    end;
                    MENU_SETUP_NOSLEEP: Option.dwNoSleep := Option.dwNoSleep and NOSLEEP_DISPLAY xor NOSLEEP_DISPLAY;
                    MENU_LIST_ADD: ListAdd(1);
                    MENU_LIST_INSERT: ListAdd(2);
                    MENU_LIST_PLAY_SELECT: SPCPlay(PLAY_TYPE_LIST);
                    MENU_LIST_PLAY_BASE..MENU_LIST_PLAY_MAX:
                        ListNextPlay(MENU_LIST_PLAY_VALUE[wParam - MENU_LIST_PLAY_BASE], LIST_NEXT_PLAY_SELECT);
                    MENU_LIST_REMOVE: ListDelete();
                    MENU_LIST_CLEAR: ListClear(false);
                    MENU_LIST_UP: ListUp();
                    MENU_LIST_DOWN: ListDown();
                    else case wParam div 10 * 10 of
                        MENU_SETUP_DEVICE_BASE..MENU_SETUP_DEVICE_BASE + 90:
                            UpdateDevice(wParam - MENU_SETUP_DEVICE_BASE - 1, WAVE_DEVICE_UPDATE_SELECT);
                        MENU_SETUP_CHANNEL_BASE: Option.dwChannel := MENU_SETUP_CHANNEL_VALUE[wParam - MENU_SETUP_CHANNEL_BASE];
                        MENU_SETUP_BIT_BASE: Option.dwBit := MENU_SETUP_BIT_VALUE[wParam - MENU_SETUP_BIT_BASE];
                        MENU_SETUP_RATE_BASE..MENU_SETUP_RATE_BASE + 10:
                            Option.dwRate := MENU_SETUP_RATE_VALUE[wParam - MENU_SETUP_RATE_BASE];
                        MENU_SETUP_INTER_BASE: Option.dwInter := MENU_SETUP_INTER_VALUE[wParam - MENU_SETUP_INTER_BASE];
                        MENU_SETUP_PITCH_BASE..MENU_SETUP_PITCH_BASE + 20:
                            Option.dwPitch := MENU_SETUP_PITCH_VALUE[wParam - MENU_SETUP_PITCH_BASE];
                        MENU_SETUP_SEPARATE_BASE..MENU_SETUP_SEPARATE_BASE + 10:
                            Option.dwSeparate := MENU_SETUP_SEPARATE_VALUE[wParam - MENU_SETUP_SEPARATE_BASE];
                        MENU_SETUP_FEEDBACK_BASE..MENU_SETUP_FEEDBACK_BASE + 10:
                            Option.dwFeedback := MENU_SETUP_FEEDBACK_VALUE[wParam - MENU_SETUP_FEEDBACK_BASE];
                        MENU_SETUP_SPEED_BASE..MENU_SETUP_SPEED_BASE + 20:
                            Option.dwSpeedBas := MENU_SETUP_SPEED_VALUE[wParam - MENU_SETUP_SPEED_BASE];
                        MENU_SETUP_AMP_BASE..MENU_SETUP_AMP_BASE + 20: Option.dwAmp := MENU_SETUP_AMP_VALUE[wParam - MENU_SETUP_AMP_BASE];
                        MENU_SETUP_MUTE_BASE: Option.dwMute := Option.dwMute xor (1 shl (wParam - MENU_SETUP_MUTE_BASE));
                        MENU_SETUP_NOISE_BASE: Option.dwNoise := Option.dwNoise xor (1 shl (wParam - MENU_SETUP_NOISE_BASE));
                        MENU_SETUP_OPTION_BASE..MENU_SETUP_OPTION_BASE + 10:
                            Option.dwOption := Option.dwOption xor MENU_SETUP_OPTION_VALUE[wParam - MENU_SETUP_OPTION_BASE];
                        MENU_SETUP_ORDER_BASE: begin
                            // フラグを設定
                            Option.dwPlayOrder := wParam - MENU_SETUP_ORDER_BASE;
                            Status.dwPlayOrder := Option.dwPlayOrder;
                            // リピート開始位置、リピート終了位置を初期化
                            if (Option.dwPlayOrder <> PLAY_ORDER_STOP) and (Option.dwPlayOrder <> PLAY_ORDER_REPEAT) then ResetRepeatPosision();
                            // インジケータを再描画
                            cwWindowMain.PostMessage(WM_APP_MESSAGE, WM_APP_REDRAW, NULL);
                        end;
                        MENU_SETUP_SEEK_BASE: Option.dwSeekTime := MENU_SETUP_SEEK_VALUE[wParam - MENU_SETUP_SEEK_BASE];
                        MENU_SETUP_INFO_BASE: begin
                            SetChangeInfo(true, wParam - MENU_SETUP_INFO_BASE);
                            exit; // UpdateMenu を実行しない
                        end;
                        MENU_SETUP_PRIORITY_BASE: begin
                            // 設定する優先度を取得
                            Option.dwPriority := MENU_SETUP_PRIORITY_VALUE[wParam - MENU_SETUP_PRIORITY_BASE];
                            // プロセス優先度を設定
                            API_SetPriorityClass(API_GetCurrentProcess(), Option.dwPriority);
                        end;
                    end;
                end;
                case wParam div 100 of
                    2, 10: SPCReset(true); // 2: チャンネル～レート, 10: デバイス
                    3..5: SPCReset(false); // 3～5: 補間処理～拡張設定
                    6: UpdateMenu();       // 6: 演奏時間～常に手前に表示
                end;
            end else case (wParam and $FFFF) div ID_BASE of // 子ウィンドウが変化した
                ID_BUTTON: case wParam shr 16 of // ボタンの処理
                    BN_CLICKED: case wParam and $FFFF of // クリック、ダブルクリックされた
                        ID_BUTTON_OPEN: OpenFile();
                        ID_BUTTON_SAVE: SaveFile();
                        ID_BUTTON_PLAY: SPCPlay(PLAY_TYPE_AUTO);
                        ID_BUTTON_RESTART: SPCStop(true);
                        ID_BUTTON_STOP: SPCStop(false);
                        ID_BUTTON_TRACK_BASE..ID_BUTTON_TRACK_BASE + 7: begin
                            // チャンネルマスクを設定
                            Option.dwMute := Option.dwMute xor (1 shl ((wParam and $FFFF) - ID_BUTTON_TRACK_BASE));
                            // 設定をリセット
                            SPCReset(false);
                        end;
                        ID_BUTTON_SLOW: SetFunction(-1, FUNCTION_TYPE_SPEED or FUNCTION_TYPE_NO_TIMER);
                        ID_BUTTON_FAST: SetFunction(1, FUNCTION_TYPE_SPEED or FUNCTION_TYPE_NO_TIMER);
                        ID_BUTTON_AMPD: SetFunction(-1, FUNCTION_TYPE_AMP or FUNCTION_TYPE_NO_TIMER);
                        ID_BUTTON_AMPU: SetFunction(1, FUNCTION_TYPE_AMP or FUNCTION_TYPE_NO_TIMER);
                        ID_BUTTON_BACK: SetFunction(-1, FUNCTION_TYPE_SEEK or FUNCTION_TYPE_NO_TIMER);
                        ID_BUTTON_NEXT: SetFunction(1, FUNCTION_TYPE_SEEK or FUNCTION_TYPE_NO_TIMER);
                        ID_BUTTON_ADD: ListAdd(0);
                        ID_BUTTON_REMOVE: ListDelete();
                        ID_BUTTON_CLEAR: ListClear(false);
                        ID_BUTTON_UP: if Status.bShiftButton then ListNextPlay(PLAY_ORDER_PREVIOUS, LIST_NEXT_PLAY_SELECT)
                            else ListUp();
                        ID_BUTTON_DOWN: if Status.bShiftButton then ListNextPlay(PLAY_ORDER_NEXT, LIST_NEXT_PLAY_SELECT)
                            else ListDown();
                    end;
                end;
                ID_LISTBOX: case wParam shr 16 of // プレイリストの処理
                    LBN_SELCHANGE: case wParam and $FFFF of // 選択された
                        ID_LIST_PLAY: UpdateMenu();
                    end;
                    LBN_DBLCLK: case wParam and $FFFF of // ダブルクリックされた
                        ID_LIST_PLAY: SPCPlay(PLAY_TYPE_LIST);
                    end;
                end;
                ID_STATIC: case wParam shr 16 of // スタティックの処理
                    STN_DBLCLK: case wParam and $FFFF of // ダブルクリックされた
                        ID_STATIC_MAIN: ChangeStaticClick();
                    end;
                end;
            end;
        end;
        WM_DROPFILES: dwDef := DropFile(wParam); // ファイルがドロップされた
        WM_CAPTURECHANGED: dwDef := LostFocusWindow(); // マウスのキャプチャが変化した
        WM_ACTIVATE: case wParam and $FFFF of // ウィンドウのアクティブが変化した
            0: dwDef := LostFocusWindow(); // ウィンドウからフォーカスが離れた
            1, 2: dwDef := GetFocusWindow(); // ウィンドウにフォーカスが移った
        end;
        WM_SIZE: if longbool(Status.dwTitle) then begin // サイズが変更された
            if wParam = $FFFFFFFF then dwDef := 1;
            // フラグを設定
            Status.dwTitle := Status.dwTitle and not TITLE_ALWAYS_FLAG;
            if longbool(cwWindowMain.GetWindowStyle() and WS_MINIMIZE) then Status.dwTitle := Status.dwTitle or TITLE_MINIMIZE
            else Status.dwTitle := Status.dwTitle or TITLE_NORMAL;
            if longbool(cwWindowMain.GetWindowStyle() and WS_MAXIMIZE) then cwWindowMain.SetWindowShowStyle(SW_SHOWNORMAL);
            // 最小化された場合はインジケータをリセット
            if longbool(Status.dwTitle and TITLE_MINIMIZE) then ResetInfo(false);
            // タイトルを更新
            UpdateTitle(NULL);
        end;
        WM_MENUSELECT: Status.dwMenuFlags := wParam; // メニューが選択された
        WM_EXITSIZEMOVE: if longbool(Status.dwTitle) then MoveWindowScreenSide(); // ウィンドウが移動した
        WM_APP_MESSAGE: begin // ユーザー定義
            // 初期化
            dwDef := 1;
            // メッセージ処理
            case wParam and $FFFF0000 of
                WM_APP_TRANSMIT: result := longword(TransmitFile(longbool(wParam and $1))); // ファイル名が転送されてきた
                WM_APP_ACTIVATE: GetFocusWindowAfter(); // ウィンドウにフォーカスが移った
                WM_APP_REDRAW: RedrawInfo(longbool(wParam and $1)); // 再描画の必要が生じた
                WM_APP_SEEK, WM_APP_REPEAT_TIME: ClickSeekBar(); // シークの必要が生じた、リピート位置が変更された
                WM_APP_NEXT_PLAY: SetNextPlay(); // 次の曲を演奏
                WM_APP_MINIMIZE: MinimizeWindow(); // 最小化が要求された
                WM_APP_WAVE_PROC: Inc(Status.dwWaveMessage); // WAVE 割り込み
                WM_APP_FUNCTION: SetFunction((wParam and $2) - 1, lParam); // 機能設定
                WM_APP_GET_DSP, WM_APP_SET_DSP: begin // DSP 読み取り・書き込み
                    // クリティカルセクションを開始
                    API_EnterCriticalSection(@CriticalSectionThread);
                    // DSP レジスタ
                    result := Apu.DspReg.Reg[wParam and $7F];
                    if longbool(wParam and $10000) then Apu.SetDSPReg(byte(wParam), byte(lParam));
                    // クリティカルセクションを終了
                    API_LeaveCriticalSection(@CriticalSectionThread);
                end;
                WM_APP_GET_PORT, WM_APP_SET_PORT: begin // I/O ポート読み取り・書き込み
                    // クリティカルセクションを開始
                    API_EnterCriticalSection(@CriticalSectionThread);
                    // I/O ポート
                    result := Apu.SPCOutPort.Port[wParam and $3];
                    if longbool(wParam and $10000) then Apu.InPort(byte(wParam), byte(lParam));
                    // クリティカルセクションを終了
                    API_LeaveCriticalSection(@CriticalSectionThread);
                end;
                WM_APP_GET_RAM, WM_APP_SET_RAM: begin // RAM 読み取り・書き込み
                    // クリティカルセクションを開始
                    API_EnterCriticalSection(@CriticalSectionThread);
                    // APU RAM
                    result := ReadAPURam(wParam and $FFFF);
                    if longbool(wParam and $10000) then WriteAPURam(wParam and $FFFF, lParam);
                    // クリティカルセクションを終了
                    API_LeaveCriticalSection(@CriticalSectionThread);
                end;
                WM_APP_GET_WORK, WM_APP_SET_WORK: begin // ワーク読み取り・書き込み
                    // Script700 ユーザワークエリア
                    result := Status.Script700.Data.dwWork[wParam and $7];
                    if longbool(wParam and $10000) then Status.Script700.Data.dwWork[wParam and $7] := lParam;
                end;
                WM_APP_GET_CMP, WM_APP_SET_CMP: begin // 比較値読み取り・書き込み
                    // Script700 データエリア
                    result := Status.Script700.Data.dwCmpParam[wParam and $1];
                    if longbool(wParam and $10000) then Status.Script700.Data.dwCmpParam[wParam and $1] := lParam;
                end;
                WM_APP_GET_SPC, WM_APP_SET_SPC: begin // SPC 読み取り・書き込み
                    // クリティカルセクションを開始
                    API_EnterCriticalSection(@CriticalSectionThread);
                    // SPC レジスタ
                    result := ReadSPCReg(wParam and $FFFF);
                    if longbool(wParam and $10000) then WriteSPCReg(wParam and $FFFF, lParam);
                    // クリティカルセクションを終了
                    API_LeaveCriticalSection(@CriticalSectionThread);
                end;
                WM_APP_HALT: begin // HALT スイッチ
                    // クリティカルセクションを開始
                    API_EnterCriticalSection(@CriticalSectionThread);
                    // HALT スイッチ
                    Apu.SetSPCDbg(pointer(longword(-1)), lParam and $2F);
                    // クリティカルセクションを終了
                    API_LeaveCriticalSection(@CriticalSectionThread);
                end;
                WM_APP_BP_SET, WM_APP_BP_CLEAR: begin // BreakPoint 設定・全解除
                    // クリティカルセクションを開始
                    API_EnterCriticalSection(@CriticalSectionThread);
                    // コールバックを追加設定
                    Apu.SNESAPUCallback(@_SNESAPUCallback, CBE_S700FCH);
                    // BreakPoint 設定
                    if longbool(wParam and $10000) then API_ZeroMemory(@Status.BreakPoint, 65536)
                    else Status.BreakPoint[wParam and $FFFF] := lParam and $FF;
                    // クリティカルセクションを終了
                    API_LeaveCriticalSection(@CriticalSectionThread);
                end;
                WM_APP_NEXT_TICK: begin // 次の命令で止める
                    // クリティカルセクションを開始
                    API_EnterCriticalSection(@CriticalSectionThread);
                    // 次の命令実行スイッチ
                    if longbool(lParam) then Status.dwNextTick := (lParam and $FF) or BRKP_NEXT_STOP
                    else Status.dwNextTick := BRKP_RELEASE;
                    // クリティカルセクションを終了
                    API_LeaveCriticalSection(@CriticalSectionThread);
                end;
                WM_APP_DSP_CHEAT, WM_APP_DSP_THRU: begin // DSP チート設定・全解除
                    // クリティカルセクションを開始
                    API_EnterCriticalSection(@CriticalSectionThread);
                    // コールバックを追加設定
                    Apu.SNESAPUCallback(@_SNESAPUCallback, CBE_DSPREG);
                    // DSP チート設定
                    if longbool(wParam and $10000) then API_ZeroMemory(@Status.DSPCheat, 256)
                    else if lParam >= $100 then Status.DSPCheat[wParam and $7F] := 0
                    else Status.DSPCheat[wParam and $7F] := (lParam and $FF) or $100;
                    // クリティカルセクションを終了
                    API_LeaveCriticalSection(@CriticalSectionThread);
                end;
                WM_APP_GET_MUTE, WM_APP_SET_MUTE: begin // ミュート設定
                    // チャンネルマスク
                    result := Option.dwMute;
                    if longbool(wParam and $10000) then begin
                        // チャンネルマスクを設定
                        Option.dwMute := wParam and $FF;
                        // 設定をリセット
                        SPCReset(false);
                    end;
                end;
                WM_APP_STATUS: result := (longword(Status.bOpen) and STATUS_OPEN) or (longword(Status.bPlay) and STATUS_PLAY)
                    or (longword(Status.bPause) and STATUS_PAUSE); // ステータス取得
                WM_APP_APPVER: result := APPLINK_VERSION; // バージョン取得
                WM_APP_EMU_APU: ForceEmuAPU(); // 強制エミュレート
                WM_APP_EMU_DEBUG: Status.bEmuDebug := longbool(wParam and $1); // SPC700 転送テスト
                WM_APP_DRAG_DONE: Status.bDropCancel := false; // ドラッグ終了
                WM_APP_UPDATE_INFO: UpdateInfo(longbool(wParam and $1)); // 情報を更新
                WM_APP_UPDATE_MENU: UpdateMenu(); // メニューを更新
                WM_APP_WAVE_OUTPUT: result := longword(WaveOutput(longbool(wParam and $1), longbool(wParam and $2))); // WAVE 書き込み
                WM_APP_TRY_RESUME: begin // 演奏再開試行
                    // デバイスをクローズ
                    WaveClose(true);
                    // デバイスを更新
                    UpdateDevice(Option.dwDeviceID, WAVE_DEVICE_UPDATE_LIST);
                    // デバイスをオープン
                    if longbool(WaveOpen()) then begin
                        // メニューを更新
                        UpdateMenu();
                        // インジケータをリセット
                        ResetInfo(true);
                    end else begin
                        // フラグを設定
                        Status.bSPCRestart := false;
                        Status.bSPCRefresh := false;
                        Status.bWaveWrite := true;
                        // メニューを更新
                        UpdateMenu();
                        // インジケータをリセット
                        ResetInfo(true);
                        // スレッドに演奏開始を通知
                        API_PostThreadMessage(Status.dwThreadID, WM_APP_MESSAGE, WM_APP_SPC_PLAY, NULL);
                    end;
                end;
            end;
        end;
        WM_TIMER: case wParam of // タイマー
            TIMER_ID_READY: begin // 準備完了
                // フラグを設定
                Status.dwReady := READY_ACTIVE;
                // タイマーを解除
                API_KillTimer(cwWindowMain.hWnd, TIMER_ID_READY);
                // メニューを描画
                API_DrawMenuBar(cwWindowMain.hWnd);
                // メニュー境界を描画
                if Option.dwTheme = THEME_DARK then cmMain.DrawMenuBorder(cwWindowMain.hWnd);
            end;
            TIMER_ID_OPTION_DISPLAY: begin // 情報表示解除
                // フラグを設定
                Status.dwTitle := Status.dwTitle and TITLE_ALWAYS_FLAG;
                // タイマーを解除
                API_KillTimer(cwWindowMain.hWnd, TIMER_ID_OPTION_DISPLAY);
                // タイトルを更新
                UpdateTitle(NULL);
            end;
            TIMER_ID_OPTION_LOCK: begin // オプションロック解除
                // タイマーを解除
                if Status.bOptionLock then API_KillTimer(cwWindowMain.hWnd, TIMER_ID_OPTION_LOCK);
                // オプション設定ロックを解除
                Status.bOptionLock := false;
            end;
            TIMER_ID_REDRAW_RESUME: begin // サスペンド復帰後のウィンドウ再描画
                // タイマーを解除
                API_KillTimer(cwWindowMain.hWnd, TIMER_ID_REDRAW_RESUME);
                // ウィンドウ全体を再描画
                cwWindowMain.PostMessage(WM_APP_MESSAGE, WM_APP_REDRAW or $1, NULL);
            end;
        end;
        WM_ENDSESSION: if longbool(wParam) then DeleteWindow(); // セッションが終了 (Windows がログオフ、再起動、シャットダウン) した
        WM_POWERBROADCAST: case wParam of // Windows の電源管理状態が変化した
            PBT_APMSUSPEND, PBT_APMSTANDBY: SPCStop(false); // Windows がサスペンド、休止状態に入った
            PBT_APMRESUMESUSPEND, PBT_APMRESUMESTANDBY, PBT_APMRESUMEAUTOMATIC: RedrawResume(NULL); // Windows がサスペンドから復帰した
            PBT_POWERSETTINGCHANGE: RedrawResume(lParam); // ディスプレイの電源状態が変化した
        end;
        WM_DISPLAYCHANGE: RedrawResume(NULL); // ディスプレイの解像度が変化した
        WM_SYSCOLORCHANGE: begin // システムカラー設定が変化した
            // クリティカルセクションを開始
            API_EnterCriticalSection(@CriticalSectionStatic);
            // グラフィックリソースを設定
            SetGraphic();
            // クリティカルセクションを終了
            API_LeaveCriticalSection(@CriticalSectionStatic);
            // インジケータを再描画
            cwWindowMain.PostMessage(WM_APP_MESSAGE, WM_APP_REDRAW, NULL);
        end;
        WM_CLOSE: if hWnd = cwWindowMain.hWnd then begin // Windows がウィンドウを閉じた
            // 初期化
            dwDef := 1;
            // 終了メッセージを送信
            cwWindowMain.PostMessage(WM_QUIT, NULL, NULL);
        end;
        WM_CTLCOLORSTATIC, WM_CTLCOLORLISTBOX: if Option.dwTheme = THEME_DARK then begin
            API_SetTextColor(wParam, COLOR_DARK_TEXT);
            API_SetBkColor(wParam, COLOR_DARK_BACK);
            dwDef := 1;
            result := Status.hBackBrush;
        end;
        WM_DRAWITEM: if Option.dwTheme = THEME_DARK then begin
            result := 0;
            case wParam of
                ID_BUTTON_OPEN: result := cwButtonOpen.DrawItem(lParam, false);
                ID_BUTTON_SAVE: result := cwButtonSave.DrawItem(lParam, false);
                ID_BUTTON_PLAY: result := cwButtonPlay.DrawItem(lParam, false);
                ID_BUTTON_RESTART: result := cwButtonRestart.DrawItem(lParam, false);
                ID_BUTTON_STOP: result := cwButtonStop.DrawItem(lParam, false);
                ID_BUTTON_TRACK_BASE..ID_BUTTON_TRACK_BASE + 7: result := cwCheckTrack[wParam - ID_BUTTON_TRACK_BASE].DrawItem(
                    lParam, not longbool(Option.dwMute and (1 shl (wParam - ID_BUTTON_TRACK_BASE))));
                ID_BUTTON_AMPD: result := cwButtonVolM.DrawItem(lParam, false);
                ID_BUTTON_AMPU: result := cwButtonVolP.DrawItem(lParam, false);
                ID_BUTTON_SLOW: result := cwButtonSlow.DrawItem(lParam, false);
                ID_BUTTON_FAST: result := cwButtonFast.DrawItem(lParam, false);
                ID_BUTTON_BACK: result := cwButtonBack.DrawItem(lParam, false);
                ID_BUTTON_NEXT: result := cwButtonNext.DrawItem(lParam, false);
                ID_BUTTON_ADD: result := cwButtonListAdd.DrawItem(lParam, false);
                ID_BUTTON_REMOVE: result := cwButtonListRemove.DrawItem(lParam, false);
                ID_BUTTON_CLEAR: result := cwButtonListClear.DrawItem(lParam, false);
                ID_BUTTON_UP: result := cwButtonListUp.DrawItem(lParam, false);
                ID_BUTTON_DOWN: result := cwButtonListDown.DrawItem(lParam, false);
            end;
            dwDef := result;
        end;
        WM_UAHDRAWMENU: if Option.dwTheme = THEME_DARK then begin
            result := cmMain.DrawMenuBar(hWnd, lParam);
            dwDef := result;
        end;
        WM_UAHDRAWMENUITEM: if Option.dwTheme = THEME_DARK then begin
            result := cmMain.DrawMenuItem(hWnd, lParam);
            dwDef := result;
        end;
        WM_PAINT: if Option.dwTheme = THEME_DARK then begin
            if hWnd = cwWindowMain.hWnd then cmMain.DrawMenuBorder(hWnd);
        end;
    end;
end;


// *************************************************************************************************************************************************************
// エントリーポイント
// *************************************************************************************************************************************************************

begin
{$WARNINGS OFF} // コンパイラ警告メッセージなし --- ここから
    ExitCode := longint(_WinMain(hInstance, hPrevInst, cmdLine, cmdShow));
{$WARNINGS ON}  // コンパイラ警告メッセージなし --- ここまで
end.
