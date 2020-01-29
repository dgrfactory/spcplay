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
//  +++ このソース コードは GPL です +++
//
//  このプログラムはフリー ソフトウェアです。 あなたはフリー ソフトウェア団体によって発行
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
//  受け取っていない場合は、フリー ソフトウェア団体から取り寄せてください。
//  宛先 : Free Software Foundation, Inc.
//         59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
//
//  ※ GNU 一般公衆利用許諾契約書バージョン 2 のドキュメントは、付属の LICENSE にあります。
//
//
//  Copyright (C) 2003-2020 degrade-factory. All rights reserved.
//
// =================================================================================================
program spccmd;

{$APPTYPE CONSOLE}                                          // アプリケーション タイプ    : CONSOLE モード
{$ASSERTIONS OFF}                                           // ソース コードのアサート    : 無効
{$BOOLEVAL OFF}                                             // 完全論理式評価             : 無効
{$DEBUGINFO OFF}                                            // デバッグ情報               : 無効
{$DEFINITIONINFO OFF}                                       // シンボル宣言と参照情報     : 無効
{$DENYPACKAGEUNIT OFF}                                      // UNIT 使用                  : 無効
{$DESIGNONLY OFF}                                           // IDE 使用                   : 無効
{$EXTENDEDSYNTAX ON}                                        // 関数の戻り値を無視可能     : 有効
{$EXTENSION exe}                                            // 拡張子設定                 : EXE
{$HINTS ON}                                                 // ヒント生成                 : 有効
{$IMAGEBASE $00400000}                                      // イメージ ベース アドレス   : 0x00400000
{$IMPLICITBUILD ON}                                         // ビルドのたびに再コンパイル : 有効
{$IMPORTEDDATA OFF}                                         // 別パッケージのメモリ参照   : 無効
{$IOCHECKS OFF}                                             // I/O チェック               : 無効
{$LOCALSYMBOLS OFF}                                         // ローカル シンボル情報      : 無効
{$LONGSTRINGS ON}                                           // AnsiString 使用            : 有効
{$MAXSTACKSIZE $00100000}                                   // 最大スタック設定           : 0x00100000
{$MINENUMSIZE 1}                                            // 列挙型の最大サイズ (x256)  : 1 (256)
{$MINSTACKSIZE $00004000}                                   // 最小スタック設定           : 0x00004000
{$OBJEXPORTALL OFF}                                         // シンボルのエクスポート     : 無効
{$OPENSTRINGS OFF}                                          // オープン文字列パラメータ   : 無効
{$OPTIMIZATION ON}                                          // 最適化コンパイル           : 有効
{$OVERFLOWCHECKS OFF}                                       // オーバーフロー チェック    : 無効
{$RANGECHECKS OFF}                                          // 範囲チェック               : 無効
{$REALCOMPATIBILITY OFF}                                    // Real48 互換                : 無効
{$REFERENCEINFO OFF}                                        // 完全な参照情報の生成       : 無効
{$R 'spccmd.res' 'spccmd.rc'}                               // リソース                   : spccmd.res <- spccmd.rc
{$RUNONLY OFF}                                              // 実行時のみコンパイル       : 無効
{$SAFEDIVIDE OFF}                                           // 初期 Pentium FDIV バグ回避 : 無効
{$STACKFRAMES OFF}                                          // 完全スタック フレーム生成  : 無効
{$TYPEDADDRESS OFF}                                         // ポインタの型チェック       : 無効
{$TYPEINFO OFF}                                             // 実行時型情報               : 無効
{$VARSTRINGCHECKS OFF}                                      // 文字列チェック             : 無効
{$WARNINGS ON}                                              // 警告生成                   : 有効
{$WEAKPACKAGEUNIT OFF}                                      // 弱いパッケージ化           : 無効
{$WRITEABLECONST OFF}                                       // 定数書き換え               : 無効


// *************************************************************************************************************************************************************
// 外部クラスの宣言
// *************************************************************************************************************************************************************

//uses MemCheck in '..\..\MemCheck.pas';


// *************************************************************************************************************************************************************
// 構造体、およびクラスの宣言
// *************************************************************************************************************************************************************

type
    // DSP 構造体
    TDSP = record
        Dsp: array[0..127] of byte;                         // DSP レジスタ
    end;

    // RAM 構造体
    TRAM = record
        Ram: array[0..65535] of byte;                       // SPC700 64KB RAM
    end;

    // SPC 構造体
    TSPC = record
        Hdr: array[0..255] of byte;                         // SPC ファイル ヘッダ
        Ram: array[0..65535] of byte;                       // SPC700 64KB RAM
        Dsp: array[0..127] of byte;                         // DSP レジスタ
        __r: array[0..63] of byte;                          // (未使用) = 0x00 or 拡張 RAM
        XRam: array[0..63] of byte;                         // SPC700 拡張 RAM
    end;

    // STRDATA 構造体
    TSTRDATA = record case byte of
        1: (cData: array[0..7] of char);                    // 1 文字 x8
        2: (bData: array[0..7] of byte);                    // 8 ビット x8
        3: (wData: array[0..3] of word);                    // 16 ビット x4
        4: (dwData: array[0..1] of longword);               // 32 ビット x2
        5: (qwData: int64);                                 // 64 ビット
    end;

    // TRANSFERSPCEX 構造体
    TTRANSFERSPCEX = record
        cbSize: longword;
        transmitType: longword;
        bScript700: longbool;
        pCallbackRead: pointer;
        pCallbackWrite: pointer;
    end;


// *************************************************************************************************************************************************************
// 定数の宣言
// *************************************************************************************************************************************************************

const
    // Delphi 標準定数
    NULL = 0;                                               // ヌル
    NULLCHAR = #0;                                          // ヌル文字
    NULLPOINTER = nil;                                      // ヌル ポインタ
    CRLF = #13#10;                                          // 改行

    CLASS_NAME: string = 'SSDLabo_SPCPLAY';
    SPC_FILE_HEADER = 'SNES-SPC700 Sound File Data ';
    SPC_FILE_HEADER_LEN = 28;
    SPCCMD_VERSION = '1.5.1 (build 4212)';
    APPLINK_VERSION = $02170500;
    HexTable: array[0..15] of char = ('0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F');
    INI_FILE: string = 'spcplay.ini';
    BUFFER_LENGTH = 13;
    BUFFER_START = BUFFER_LENGTH + 1;
    BUFFER_LANGUAGE: string = 'LANGUAGE 1 : ';
    LIST_FILE: string = 'spcplay.stk';
    LIST_FILE_HEADER_A: string = 'SSDLabo Spcplay ListFile v1.0';
    LIST_FILE_HEADER_A_LEN = 29;
    LIST_FILE_HEADER_B: string = 'SPCPLAY PLAYLIST';
    LIST_FILE_HEADER_B_LEN = 16;

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
    INVALID_HANDLE_VALUE = $FFFFFFFF;
    ITEM_STATIC = 'Static';
    WM_SETTEXT = $C;

    CREATE_NEW = $1;
    CREATE_ALWAYS = $2;
    OPEN_EXISTING = $3;
    OPEN_ALWAYS = $4;
    TRUNCATE_EXISTING = $5;

    LOCALE_AUTO = 0;                                        // 自動
    LOCALE_JA = 1;                                          // 日本語
    LOCALE_EN = 2;                                          // 英語

    WM_COMMAND = $111;
    MENU_FILE_PLAY_BASE = 110;
    MENU_FILE_PLAY = MENU_FILE_PLAY_BASE;
    MENU_FILE_PAUSE = MENU_FILE_PLAY_BASE + 1;
    MENU_FILE_RESTART = MENU_FILE_PLAY_BASE + 2;
    MENU_FILE_STOP = MENU_FILE_PLAY_BASE + 3;

    FILE_DEFAULT: string = 'FILE TRANSMIT WINDOW';

    WM_APP_TRANSMIT = $00000000;                            // ファイル名転送     ($0000???X, X:AutoPlay, l:hWnd)
    WM_APP_WAVE_OUTPUT = $000A0000;                         // WAVE 書き込み      ($000A??YX, X:Shift, Y:Quiet, l:hWnd)

    WM_APP_MESSAGE = $8000;

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
    WM_APP_STATUS = $FF000000;                              // ステータス取得     ($FF00????)
    WM_APP_APPVER = $FF010000;                              // バージョン取得     ($FF01????)
    WM_APP_EMU_APU = $FFFE0000;                             // 強制エミュレート   ($FFFE????)
    WM_APP_EMU_DEBUG = $FFFF0000;                           // SPC700 転送テスト  ($FFFF???X, X:Flag)

    FILE_TYPE_NOTEXIST = $1;                                // 存在しない
    FILE_TYPE_NOTREAD = $2;                                 // 読み込み不可
    FILE_TYPE_UNKNOWN = $3;                                 // 不明な形式
    FILE_TYPE_SPC = $10;                                    // SPC ファイル
    FILE_TYPE_LIST_A = $11;                                 // プレイリスト ファイル TYPE-A
    FILE_TYPE_LIST_B = $12;                                 // プレイリスト ファイル TYPE-B
    FILE_TYPE_FOLDER = $13;                                 // フォルダ
    FILE_TYPE_WAVE = $20;                                   // WAVE ファイル

    STATUS_OPEN = $1;                                       // Open フラグ
    STATUS_PLAY = $2;                                       // Play フラグ
    STATUS_PAUSE = $4;                                      // Pause フラグ

    STR_VERSION_1: array[0..1] of string = ('SNES SPC700 Player 外部拡張コマンド ツール', 'SNES SPC700 Player external command tool');
    STR_VERSION_2: array[0..1] of string = ('サポートしている SPCPLAY.EXE のバージョン： v2.18.0 以降', 'Supported SPCPLAY.EXE version: v2.18.0 or later');

    STR_USAGE_TITLE: array[0..1] of string = ('<< 構文 >>', '<< USAGE >>');
    STR_USAGE_NEXT: array[0..1] of string = ('Enter キーで続きを表示します...', 'Press Enter key to continue...');
    STR_USAGE_COMMAND: array[0..1] of string = ('  spccmd.exe [オプション]', '  spccmd.exe [option]');
    STR_USAGE_OPTION: array[0..1] of string = ('[オプション]', '[option]');
    STR_USAGE_OPTION_BASE: array[0..1] of string = ('基本オプション', 'Base options');
    STR_USAGE_OPTION_BASE_H: array[0..1] of string = ('構文ヘルプを表示', 'Show usage');
    STR_USAGE_OPTION_BASE_V: array[0..1] of string = ('バージョン情報を表示', 'Show version');
    STR_USAGE_OPTION_BASE_P: array[0..1] of string = ('演奏開始・一時停止', 'Play/Pause');
    STR_USAGE_OPTION_BASE_R: array[0..1] of string = ('最初から演奏', 'Restart');
    STR_USAGE_OPTION_BASE_S: array[0..1] of string = ('演奏停止', 'Stop');
    STR_USAGE_OPTION_DSP: array[0..1] of string = ('DSP レジスタ値の読取・書込', 'Read/Write DSP registers');
    STR_USAGE_OPTION_DSP_G: array[0..1] of string = ('読取   <XX>(アドレス) = $00～$7F', 'Read    <XX>(Address) = $00-$7F');
    STR_USAGE_OPTION_DSP_S: array[0..1] of string = ('書込   <YY>(値) = $00～$FF (8bit)', 'Write   <YY>(Value) = $00-$FF (8bit)');
    STR_USAGE_OPTION_DSP_M: array[0..1] of string = ('DSP レジスタ メモリマップ表示', 'Show DSP Register Memory Map');
    STR_USAGE_OPTION_PORT: array[0..1] of string = ('SPC700 I/O ポート値の読取・書込', 'Read/Write I/O ports');
    STR_USAGE_OPTION_PORT_G: array[0..1] of string = ('読取   <XX>(アドレス) = 0～3', 'Read    <XX>(Address) = 0-3');
    STR_USAGE_OPTION_PORT_S: array[0..1] of string = ('書込   <YY>(値) = $00～$FF (8bit)', 'Write   <YY>(Value) = $00-$FF (8bit)');
    STR_USAGE_OPTION_PORT_T: array[0..1] of string = ('値を書込後すぐに元の値に戻す', 'Test write mode');
    STR_USAGE_OPTION_RAM: array[0..1] of string = ('64KB APU RAM の読取・書込', 'Read/Write 64KB APU RAM');
    STR_USAGE_OPTION_RAM_G: array[0..1] of string = ('読取   <XX>(アドレス) = $0000～$FFFF', 'Read    <XX>(Address) = $0000-$FFFF');
    STR_USAGE_OPTION_RAM_S: array[0..1] of string = ('書込   <YY>(値) = $00000000～$FFFFFFFF (32bit)', 'Write   <YY>(Value) = $00000000-$FFFFFFFF (32bit)');
    STR_USAGE_OPTION_RAM_M: array[0..1] of string = ('APU RAM メモリマップ表示 <ZZ>(表示量)', 'Show Memory Map <ZZ>(Table size)');
    STR_USAGE_OPTION_WORK: array[0..1] of string = ('Script700 Work の読取・書込', 'Read/Write Script700 working memories');
    STR_USAGE_OPTION_WORK_G: array[0..1] of string = ('読取   <XX>(アドレス) = 0～7', 'Read    <XX>(Address) = 0-7');
    STR_USAGE_OPTION_WORK_S: array[0..1] of string = ('書込   <YY>(値) = $00000000～$FFFFFFFF (32bit)', 'Write   <YY>(Value) = $00000000-$FFFFFFFF (32bit)');
    STR_USAGE_OPTION_CMP: array[0..1] of string = ('Script700 CmpParam の読取・書込', 'Read/Write Script700 CMP parameters');
    STR_USAGE_OPTION_CMP_G: array[0..1] of string = ('読取   <XX>(アドレス) = 0／1', 'Read    <XX>(Address) = 0/1');
    STR_USAGE_OPTION_CMP_S: array[0..1] of string = ('書込   <YY>(値) = $00000000～$FFFFFFFF (32bit)', 'Write   <YY>(Value) = $00000000-$FFFFFFFF (32bit)');
    STR_USAGE_OPTION_SPC: array[0..1] of string = ('SPC700 レジスタ値の読取・書込', 'Read/Write SPC700 registers');
    STR_USAGE_OPTION_SPC_G: array[0..1] of string = ('読取   <XX>(0=PC, 1=Y+A, 2=SP+X, 3:PSW)', 'Read    <XX>(0=PC, 1=Y+A, 2=SP+X, 3:PSW)');
    STR_USAGE_OPTION_SPC_S: array[0..1] of string = ('書込   <YY>(値) = $0000～$FFFF (16bit)', 'Write   <YY>(Value) = $0000-$FFFF (16bit)');
    STR_USAGE_OPTION_HALT: array[0..1] of string = ('エミュレーション動作', 'Set emulation flags');
    STR_USAGE_OPTION_HALT_S1: array[0..1] of string = ('<XX>(1=SPC_RETURN, 2=SPC_HALT, 4=DSP_HALT, 8=SPC_NODSP,', '<XX>(1=SPC_RETURN, 2=SPC_HALT, 4=DSP_HALT, 8=SPC_NODSP,');
    STR_USAGE_OPTION_HALT_S2: array[0..1] of string = ('     32=DSP_PAUSE, 34=SPC_HALT+DSP_PAUSE)', '     32=DSP_PAUSE, 34=SPC_HALT+DSP_PAUSE)');
    STR_USAGE_OPTION_BP: array[0..1] of string = ('SPC700 ブレイクポイント', 'SPC700 break points');
    STR_USAGE_OPTION_BP_X: array[0..1] of string = ('<XX>(アドレス) = $0000～$FFFF', '<XX>(Address) = $0000-$FFFF');
    STR_USAGE_OPTION_BP_Y: array[0..1] of string = ('<YY>(0=解除, 1>=設定※)', '<YY>(0=UNSET, 1>=SET *)');
    STR_USAGE_OPTION_BPAC: array[0..1] of string = ('ブレイクポイント全解除', 'All clear break points');
    STR_USAGE_OPTION_NEXT: array[0..1] of string = ('次へ進む', 'Next tick');
    STR_USAGE_OPTION_NEXT_Z: array[0..1] of string = ('<ZZ>(0=次のBPまで, 1>=次の命令まで※)', '<XX>(0=Next BP, 1>=Next Operate *)');
    STR_USAGE_OPTION_STOP_FLAGS: array[0..1] of string = ('  ※停止方法：1=SPC_HALT, 2=NOP, 3=SPC_HALT+DSP_PAUSE', '    * How to stop: 1=SPC_HALT, 2=NOP, 3=SPC_HALT+DSP_PAUSE');
    STR_USAGE_OPTION_DSPC: array[0..1] of string = ('DSP チート', 'DSP cheats');
    STR_USAGE_OPTION_DSPC_X: array[0..1] of string = ('<XX>(アドレス) = $00～$7F', '<XX>(Address) = $00-$7F');
    STR_USAGE_OPTION_DSPC_Y: array[0..1] of string = ('<YY>(値) = $00～$FF (8bit), $100>=解除', '<YY>(Value) = $00-$FF (8bit), $100>=UNSET');
    STR_USAGE_OPTION_DSPCAC: array[0..1] of string = ('DSP チート全解除', 'All clear DSP cheats');
    STR_USAGE_OPTION_OW: array[0..1] of string = ('SPC 書換', 'Rewriting SPC');
    STR_USAGE_OPTION_OW_ZC_1: array[0..1] of string = ('エコー作業領域をゼロクリア', 'Clear echo work area to $00');
    STR_USAGE_OPTION_OW_ZC_2: array[0..1] of string = ('<IF> = 読込ファイル  <OF> = 書込ファイル', '<IF> = Read path  <OF> = Write path');
    STR_USAGE_OPTION_EMU: array[0..1] of string = ('SPC 転送シミュレーション', 'SPC transfer simulation');
    STR_USAGE_OPTION_EMU_PD_1: array[0..1] of string = ('SHVC-SOUND への転送をシミュレート', 'Simulate transfer to SHVC-SOUND');
    STR_USAGE_OPTION_EMU_PD_2: array[0..1] of string = ('<IF> = 読込ファイル', '<IF> = Read path');
    STR_USAGE_OPTION_EMU_PD_3: array[0..1] of string = ('<SF> = Script700 ファイル', '<SF> = Script700 path');
    STR_USAGE_OPTION_CNV: array[0..1] of string = ('SPC 変換', 'SPC converter');
    STR_USAGE_OPTION_CNV_CW_1: array[0..1] of string = ('SPC -> WAVE (.wav) 変換', 'SPC -> WAVE (.wav)');
    STR_USAGE_OPTION_CNV_CW_2: array[0..1] of string = ('<IF> = 読込ファイル  <OF> = 書込ファイル', '<IF> = Read path  <OF> = Write path');
    STR_ERROR_008: array[0..1] of string = ('SPCCMD.EXE が起動できません。', 'SPCCMD.EXE cannot open.');
    STR_ERROR_009: array[0..1] of string = ('SPCCMD.EXE が起動できません。', 'SPCCMD.EXE cannot open.');
    STR_ERROR_101: array[0..1] of string = ('SNES SPC700 Player が起動していません。', 'SNES SPC700 Player is not running.');
    STR_ERROR_102: array[0..1] of string = ('起動している SNES SPC700 Player のバージョンには対応していません。', 'Does not support version of this SNES SPC700 Player.');
    STR_ERROR_109: array[0..1] of string = ('スイッチは使用できません。', 'switch cannot be used.');
    STR_ERROR_201: array[0..1] of string = ('書き込み先のファイル名が指定されていません。', 'Write path is undefined.');
    STR_ERROR_202: array[0..1] of string = ('読み込み先のファイル名と書き込み先のファイル名が同じです。', 'Read path is same Write path.');
    STR_ERROR_203: array[0..1] of string = ('ファイルが書き込めません。', 'Cannot write file.');
    STR_ERROR_204: array[0..1] of string = ('ファイルが読み込めません。', 'Cannot read file.');
    STR_ERROR_205: array[0..1] of string = ('SNESAPU.DLL が読み込めません。', 'Cannot read SNESAPU.DLL.');
    STR_ERROR_206: array[0..1] of string = ('対応していない SNESAPU.DLL です。', 'Does not support version of this SNESAPU.DLL.');
    STR_ERROR_301: array[0..1] of string = ('ファイルが読み込めません。', 'Cannot read file.');
    STR_ERROR_302: array[0..1] of string = ('SNESAPU.DLL が読み込めません。', 'Cannot read SNESAPU.DLL.');
    STR_ERROR_303: array[0..1] of string = ('対応していない SNESAPU.DLL です。', 'Does not support version of this SNESAPU.DLL.');
    STR_ERROR_304: array[0..1] of string = ('ファイルが読み込めません。', 'Cannot read file.');
    STR_ERROR_401: array[0..1] of string = ('ファイルを読み込めません。', 'Cannot read file.');
    STR_ERROR_402: array[0..1] of string = ('ファイルを転送できません。', 'Cannot transfer file path.');
    STR_ERROR_403: array[0..1] of string = ('ファイルを読み込めません。', 'Cannot read file.');
    STR_ERROR_404: array[0..1] of string = ('ファイルを書き込めません。', 'Cannot write file.');
    STR_DONE: array[0..1] of string = ('正常終了しました。', 'Done.');
    STR_RESULT: array[0..1] of string = ('戻り値', 'Return Value');
    STR_CONVERT: array[0..1] of string = ('変換中...', 'Converting...');
    STR_DSP_MAP: array[0..1] of string = ('DSP レジスタ メモリマップ', 'DSP Register Memory Map');
    STR_RAM_MAP: array[0..1] of string = ('64KB APU RAM メモリマップ', '64KB APU RAM Memory Map');

    ASM_BOOTCODE: array[0..76] of byte = (
        $8f, $00, $00,      // MOV $0, #$0      ; $0001: ram $0000
        $8f, $00, $01,      // MOV $1, #$0      ; $0004: ram $0001
        $8f, $ff, $fc,      // MOV $fc, #$ff    ; $0007: Timer2
        $8f, $ff, $fb,      // MOV $fb, #$ff    ; $000a: Timer1
        $8f, $4f, $fa,      // MOV $fa, #$4f    ; $000d: Timer0
        $8f, $31, $f1,      // MOV $f1, #$31    ; $0010: SPC Control reg
        $cd, $53,           // MOV X, #$53      ;
        $d8, $f4,           // MOV $f4, X       ;
        $e4, $f4,           // MOV A, $f4       ;
        $68, $00,           // CMP A, #$0       ; $0019: Port0
        $d0, $fa,           // BNE p0016        ;
        $e4, $f5,           // MOV A, $f5       ;
        $68, $00,           // CMP A, #$0       ; $001f: Port1
        $d0, $fa,           // BNE p001c        ;
        $e4, $f6,           // MOV A, $f6       ;
        $68, $00,           // CMP A, #$0       ; $0024: Port2
        $d0, $fa,           // BNE p0022        ;
        $e4, $f7,           // MOV A, $f7       ;
        $68, $00,           // CMP A, #$0       ; $002b: Port3
        $d0, $fa,           // BNE p0028        ;
        $e4, $fd,           // MOV A, $fd       ;
        $e4, $fe,           // MOV A, $fe       ;
        $e4, $ff,           // MOV A, $ff       ;
        $8f, $6c, $f2,      // MOV $f2, #$6c    ; point to flg register
        $8f, $00, $f3,      // MOV $f3, #$0     ; $0038: DSP FLG register
        $8f, $4c, $f2,      // MOV $f2, #$4c    ; point to kon register
        $8f, $00, $f3,      // MOV $f3, #$0     ; $003e: DSP KON register
        $8f, $7f, $f2,      // MOV $f2, #$7f    ; $0041: SPC dsp reg addr.
        $cd, $f5,           // MOV X, #$f5      ; $0044: SPC stack pointer
        $bd,                // MOV SP, X        ;
        $e8, $ff,           // MOV A, #$ff      ; $0047: SPC A register
        $8d, $00,           // MOV Y, #$0       ; $0049: SPC Y register
        $cd, $00,           // MOV X, #$0       ; $004b: SPC X register
        $7f                 // RETI             ;
    );
    ASM_MEMLOADER: array[0..67] of byte = (
        // --- DSP LOADER ---
        $cd, $53,           // MOV X, #$53      ;
        $d8, $f6,           // MOV $f6, X       ;

        $c4, $f2,           // MOV $f2, A       ; START:
        $64, $f4,           // CMP A, $f4       ; LOOP:
        $d0, $fc,           // BNE LOOP:        ;

        $fa, $f5, $f3,      // MOV $f3, $f5     ;
        $c4, $f4,           // MOV $f4, A       ;
        $bc,                // INC A            ;
        $10, $f2,           // BPL START:       ;

        // --- RAM LOADER ---
        $e8, $00,           // MOV A, #$0       ;
        $8d, $01,           // MOV Y, #$1       ;
        $da, $00,           // MOVW dp, YA      ; dp = $100
        $8d, $00,           // MOV Y, #$0       ;

        $64, $f4,           // CMP A, $f4       ; LOOP:
        $d0, $fc,           // BNE LOOP:        ;
        $c4, $f6,           // MOV $f6, A       ;

        $64, $f4,           // CMP A, $f4       ; LOOP:
        $f0, $fc,           // BEQ LOOP:        ;
        $f8, $f4,           // MOV X, $f4       ;
        $30, $1a,           // BMI EXIT:        ;

        $48, $01,           // EOR A, #$1       ;
        $5d,                // MOV X, A         ;
        $e4, $f5,           // MOV A, $f5       ;
        $d7, $00,           // MOV [dp]+Y, A    ;
        $3a, $00,           // INCW dp          ;
        $e4, $f6,           // MOV A, $f6       ;
        $d7, $00,           // MOV [dp]+Y, A    ;
        $3a, $00,           // INCW dp          ;
        $e4, $f7,           // MOV A, $f7       ;
        $d7, $00,           // MOV [dp]+Y, A    ;
        $3a, $00,           // INCW dp          ;
        $7d,                // MOV A, X         ;
        $c4, $f4,           // MOV $f4, A       ;
        $2f, $de,           // BRA LOOP:        ;

        $2f, $00            // BRA $??          ; jump inside rom
    );


var
    _hWndApp: longword;


// *************************************************************************************************************************************************************
// Win32 API の宣言
// *************************************************************************************************************************************************************

function  API_CloseHandle(hObject: longword): longbool; stdcall; external 'kernel32.dll' name 'CloseHandle';
function  API_CreateFile(lpFileName: pointer; dwDesiredAccess: longword; dwShareMode: longword; lpSecurityAttributes: pointer; dwCreationDisposition: longword; dwFlagsAndAttributes: longword; hTemplateFile: longword): longword; stdcall; external 'kernel32.dll' name 'CreateFileA';
function  API_FindWindowEx(hwndParent: longword; hwndChildAfter: longword; lpClassName: pointer; lpWindowName: pointer): longword; stdcall; external 'user32.dll' name 'FindWindowExA';
function  API_FreeLibrary(hModule: longword): longbool; stdcall; external 'kernel32.dll' name 'FreeLibrary';
function  API_GetCommandLine(): pointer; stdcall; external 'kernel32.dll' name 'GetCommandLineA';
function  API_GetFileAttributes(lpFileName: pointer): longword; stdcall; external 'kernel32.dll' name 'GetFileAttributesA';
function  API_GetFileSize(hFile: longword; pFileSizeHigh: pointer): longword; stdcall; external 'kernel32.dll' name 'GetFileSize';
function  API_GetModuleFileName(hModule: longword; lpFileName: pointer; nSize: longword): longword; stdcall; external 'kernel32.dll' name 'GetModuleFileNameA';
function  API_GetProcAddress(hModule: longword; lpProcName: pointer): pointer; stdcall; external 'kernel32.dll' name 'GetProcAddress';
function  API_GetUserDefaultLCID(): longword; stdcall; external 'kernel32.dll' name 'GetUserDefaultLCID';
function  API_LoadLibrary(lpLibFileName: pointer): longword; stdcall; external 'kernel32.dll' name 'LoadLibraryA';
function  API_MapFileAndCheckSum(Filename: pointer; HeaderSum: pointer; CheckSum: pointer): longword; stdcall; external 'imagehlp.dll' name 'MapFileAndCheckSumA';
procedure API_MoveMemory(Destination: pointer; Source: pointer; Length: longword); stdcall; external 'kernel32.dll' name 'RtlMoveMemory';
function  API_ReadFile(hFile: longword; lpBuffer: pointer; nNumberOfBytesToRead: longword; lpNumberOfBytesRead: pointer; lpOverlapped: pointer): longbool; stdcall; external 'kernel32.dll' name 'ReadFile';
function  API_SendMessage(hWnd: longword; msg: longword; wParam: longword; lParam: longword): longword; stdcall; external 'user32.dll' name 'SendMessageA';
procedure API_Sleep(dwMilliseconds: longword); stdcall; external 'kernel32.dll' name 'Sleep';
function  API_timeGetTime(): longword; stdcall; external 'winmm.dll' name 'timeGetTime';
function  API_WriteFile(hFile: longword; lpBuffer: pointer; nNumberOfBytesToRead: longword; lpNumberOfBytesRead: pointer; lpOverlapped: pointer): longbool; stdcall; external 'kernel32.dll' name 'WriteFile';
procedure API_ZeroMemory(Destination: pointer; Length: longword); stdcall; external 'kernel32.dll' name 'RtlZeroMemory';


// *************************************************************************************************************************************************************
// 外部拡張コード
// *************************************************************************************************************************************************************

// ================================================================================
// GetSize - 文字列バッファの使用バイト数取得
// ================================================================================
function GetSize(lpBuffer: pointer; dwMax: longword): longword;
var
    dwOffset: longword;
begin
    result := 0;
    dwOffset := longword(lpBuffer);
    while bytebool(pointer(dwOffset + result)^) and (result < dwMax) do Inc(result);
end;

// ================================================================================
// IsSafePath - パスの安全性を確認
// ================================================================================
function IsSafePath(lpFile: pointer): longbool;
var
    dwValue: ^longword;
begin
    dwValue := lpFile;
    if dwValue^ = $5C2E5C5C then begin // \\.\
        result := false;
        exit;
    end;
    result := true;
end;

// ================================================================================
// Exists - フォルダ・ファイル存在チェック
// ================================================================================
function Exists(lpPath: pointer; dwFileMode: longword): longbool;
var
    dwResult: longword;
begin
    result := false;
    if not IsSafePath(lpPath) then exit;
    dwResult := API_GetFileAttributes(lpPath);
    if dwResult = INVALID_HANDLE_VALUE then exit;
    result := longbool((dwResult xor dwFileMode) and FILE_ATTRIBUTE_DIRECTORY);
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
    while longbool(X) do begin
        Dec(I);
        StrData.cData[I] := HexTable[X and $F];
        X := X shr 4;
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
    if not result and (X >= 3) and     (((B2 >= $81) and (B2 <= $9F)) or ((B2 >= $E0) and (B2 <= $FC))) and (((B1 >= $40) and (B1 <= $7E)) or ((B1 >= $80) and (B1 <= $FC))) then result := true;
end;

// ================================================================================
// IsPathSeparator - ファイル パスの区切り文字を比較
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
// StrToInt - 文字列を数値に変換
// ================================================================================
function StrToInt(const S: string; Default: longint): longint; overload;
var
    I: longword;
    Sign: longbool;
    Size: longword;
    Start: longword;
    C: char;
    X: longint;
begin
    result := 0;
    Size := Length(S);
    X := 10;
    if Size > 0 then Sign := S[1] = '-' else Sign := false;
    if Sign then Start := 2 else Start := 1;
    if (Start <= Size) and (S[Start] = '$') then begin X := 16; Inc(Start); end;
    for I := Start to Size do begin
        C := S[I];
        if (byte(C) >= $30) and (byte(C) <= $39) then begin
            result := result * X + byte(C) - $30;
        end else if (X > 10) and (byte(C) >= $41) and (byte(C) <= $46) then begin
            result := result * X + byte(C) - $37;
        end else if (X > 10) and (byte(C) >= $61) and (byte(C) <= $66) then begin
            result := result * X + byte(C) - $57;
        end else begin
            result := Default;
            exit;
        end;
    end;
    if Sign then result := -result;
end;

// ================================================================================
// StrToInt - 文字列を数値に変換
// ================================================================================
function StrToInt(const S: string; Default: longword): longword; overload;
var
    I: longword;
    Size: longword;
    Start: longword;
    C: char;
    X: longword;
begin
    result := 0;
    Size := Length(S);
    Start := 1;
    X := 10;
    if (Start <= Size) and (S[Start] = '$') then begin X := 16; Inc(Start); end;
    for I := Start to Size do begin
        C := S[I];
        if (byte(C) >= $30) and (byte(C) <= $39) then begin
            result := result * X + byte(C) - $30;
        end else if (X > 10) and (byte(C) >= $41) and (byte(C) <= $46) then begin
            result := result * X + byte(C) - $37;
        end else if (X > 10) and (byte(C) >= $61) and (byte(C) <= $66) then begin
            result := result * X + byte(C) - $57;
        end else begin
            result := Default;
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
// メイン プロシージャ
// *************************************************************************************************************************************************************

// ================================================================================
// WinMain - ウィンドウ メイン関数
// ================================================================================
function _WinMain(hThisInstance: longword): longword; stdcall;
var
    I: longint;
    J: longint;
    fsFile: textfile;
    sData: string;
    sLine: string;
    sBuffer: string;
    cBuffer: array of char;
    lpBuffer: pointer;
    dwBuffer: longword;
    sEXEPath: string;
    sCmdLine: string;
    sChPath: string;
    dwLanguage: longword;
    dwParam1: longword;
    dwParam2: longword;
    hWnd: longword;
    dwVersion: longword;
    StrData: TSTRDATA;

function CheckImageHash(sPath: string; dwBase: longword): longword;
var
    dwResult: longword;
    dwHeaderSum: longword;
    dwCheckSum: longword;
begin
    // チェックサムを取得
    sData := Concat(sChPath, sPath);
    writeln(sData);
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

procedure ShowVersion();
begin
    writeln(output, STR_VERSION_1[dwLanguage]);
    writeln(output, Concat('v', SPCCMD_VERSION));
    writeln(output, STR_VERSION_2[dwLanguage]);
end;

procedure ShowUsage();
begin
    writeln(output, '');
    writeln(output, STR_USAGE_TITLE[dwLanguage]);
    writeln(output, Concat('  ', STR_USAGE_COMMAND[dwLanguage]));
    writeln(output, '');
    writeln(output, STR_USAGE_OPTION[dwLanguage]);
    writeln(output, Concat(' == ', STR_USAGE_OPTION_BASE[dwLanguage]));
    writeln(output, Concat('  -? -h         : ', STR_USAGE_OPTION_BASE_H[dwLanguage]));
    writeln(output, Concat('  -v            : ', STR_USAGE_OPTION_BASE_V[dwLanguage]));
    writeln(output, Concat('  -p            : ', STR_USAGE_OPTION_BASE_P[dwLanguage]));
    writeln(output, Concat('  -r            : ', STR_USAGE_OPTION_BASE_R[dwLanguage]));
    writeln(output, Concat('  -s            : ', STR_USAGE_OPTION_BASE_S[dwLanguage]));
    writeln(output, '');
    writeln(output, STR_USAGE_NEXT[dwLanguage]);
    readln(input);

    writeln(output, Concat(' == ', STR_USAGE_OPTION_DSP[dwLanguage]));
    writeln(output, Concat('  -gd <XX>      : ', STR_USAGE_OPTION_DSP_G[dwLanguage]));
    writeln(output, Concat('  -sd <XX> <YY> : ', STR_USAGE_OPTION_DSP_S[dwLanguage]));
    writeln(output, Concat('  -md           : ', STR_USAGE_OPTION_DSP_M[dwLanguage]));
    writeln(output, '');
    writeln(output, Concat(' == ', STR_USAGE_OPTION_PORT[dwLanguage]));
    writeln(output, Concat('  -gp <XX>      : ', STR_USAGE_OPTION_PORT_G[dwLanguage]));
    writeln(output, Concat('  -sp <XX> <YY> : ', STR_USAGE_OPTION_PORT_S[dwLanguage]));
    writeln(output, Concat('  -tp <XX> <YY> : ', STR_USAGE_OPTION_PORT_T[dwLanguage]));
    writeln(output, '');
    writeln(output, Concat(' == ', STR_USAGE_OPTION_RAM[dwLanguage]));
    writeln(output, Concat('  -gr <XX>      : ', STR_USAGE_OPTION_RAM_G[dwLanguage]));
    writeln(output, Concat('  -sr <XX> <YY> : ', STR_USAGE_OPTION_RAM_S[dwLanguage]));
    writeln(output, Concat('  -mr <XX> <ZZ> : ', STR_USAGE_OPTION_RAM_M[dwLanguage]));
    writeln(output, '');
    writeln(output, Concat(' == ', STR_USAGE_OPTION_WORK[dwLanguage]));
    writeln(output, Concat('  -gw <XX>      : ', STR_USAGE_OPTION_WORK_G[dwLanguage]));
    writeln(output, Concat('  -sw <XX> <YY> : ', STR_USAGE_OPTION_WORK_S[dwLanguage]));
    writeln(output, '');
    writeln(output, Concat(' == ', STR_USAGE_OPTION_CMP[dwLanguage]));
    writeln(output, Concat('  -gc <XX>      : ', STR_USAGE_OPTION_CMP_G[dwLanguage]));
    writeln(output, Concat('  -sc <XX> <YY> : ', STR_USAGE_OPTION_CMP_S[dwLanguage]));
    writeln(output, '');
    writeln(output, STR_USAGE_NEXT[dwLanguage]);
    readln(input);

    writeln(output, Concat(' == ', STR_USAGE_OPTION_SPC[dwLanguage]));
    writeln(output, Concat('  -gs <XX>      : ', STR_USAGE_OPTION_SPC_G[dwLanguage]));
    writeln(output, Concat('  -ss <XX> <YY> : ', STR_USAGE_OPTION_SPC_S[dwLanguage]));
    writeln(output, '');
    writeln(output, Concat(' == ', STR_USAGE_OPTION_HALT[dwLanguage]));
    writeln(output, Concat('  -sh <XX>      : ', STR_USAGE_OPTION_HALT_S1[dwLanguage]));
    writeln(output, Concat('                  ', STR_USAGE_OPTION_HALT_S2[dwLanguage]));
    writeln(output, '');
    writeln(output, Concat(' == ', STR_USAGE_OPTION_BP[dwLanguage]));
    writeln(output, Concat('  -bp <XX> <YY> : ', STR_USAGE_OPTION_BP_X[dwLanguage]));
    writeln(output, Concat('                  ', STR_USAGE_OPTION_BP_Y[dwLanguage]));
    writeln(output, Concat('  -bpn <ZZ>     : ', STR_USAGE_OPTION_NEXT[dwLanguage]));
    writeln(output, Concat('                  ', STR_USAGE_OPTION_NEXT_Z[dwLanguage]));
    writeln(output, Concat('                  ', STR_USAGE_OPTION_STOP_FLAGS[dwLanguage]));
    writeln(output, Concat('  -bpc          : ', STR_USAGE_OPTION_BPAC[dwLanguage]));
    writeln(output, '');
    writeln(output, Concat(' == ', STR_USAGE_OPTION_DSPC[dwLanguage]));
    writeln(output, Concat('  -dc <XX> <YY> : ', STR_USAGE_OPTION_DSPC_X[dwLanguage]));
    writeln(output, Concat('                  ', STR_USAGE_OPTION_DSPC_Y[dwLanguage]));
    writeln(output, Concat('  -dcc          : ', STR_USAGE_OPTION_DSPCAC[dwLanguage]));
    writeln(output, '');
    writeln(output, STR_USAGE_NEXT[dwLanguage]);
    readln(input);

    writeln(output, Concat(' == ', STR_USAGE_OPTION_OW[dwLanguage]));
    writeln(output, Concat('  -zc <IF> <OF> : ', STR_USAGE_OPTION_OW_ZC_1[dwLanguage]));
    writeln(output, Concat('                  ', STR_USAGE_OPTION_OW_ZC_2[dwLanguage]));
    writeln(output, '');
    writeln(output, Concat(' == ', STR_USAGE_OPTION_EMU[dwLanguage]));
    writeln(output,        '  -pd <IF>        ');
    writeln(output, Concat('  -td <IF> <SF> : ', STR_USAGE_OPTION_EMU_PD_1[dwLanguage]));
    writeln(output, Concat('                  ', STR_USAGE_OPTION_EMU_PD_2[dwLanguage]));
    writeln(output, Concat('                  ', STR_USAGE_OPTION_EMU_PD_3[dwLanguage]));
    writeln(output, '');
    writeln(output, Concat(' == ', STR_USAGE_OPTION_CNV[dwLanguage]));
    writeln(output, Concat('  -cw <IF> <OF> : ', STR_USAGE_OPTION_CNV_CW_1[dwLanguage]));
    writeln(output, Concat('                  ', STR_USAGE_OPTION_CNV_CW_2[dwLanguage]));
    writeln(output, '');
end;

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

function GetINIValue(dwDef: longint): longint; overload;
begin
    result := StrToInt(Copy(sData, BUFFER_START, Length(sData) - BUFFER_LENGTH), dwDef);
end;

function GetINIValue(dwDef: longword): longword; overload;
begin
    result := StrToInt(Copy(sData, BUFFER_START, Length(sData) - BUFFER_LENGTH), dwDef);
end;

function ZeroClear(): longword;
var
    X: longword;
    Y: longword;
    sSPCFile: string;
    sOutFile: string;
    hSPCFile: longword;
    hOutFile: longword;
    dwSize: longword;
    hDLL: longword;
    GetAPUData: procedure(ppRam: pointer; ppXRam: pointer; ppSPCOutput: pointer; ppT64Count: pointer; ppDsp: pointer; ppVoices: pointer; ppVolumeMaxLeft: pointer; ppVolumeMaxRight: pointer); stdcall;
    LoadSPCFile: procedure(pSPCFile: pointer); stdcall;
    EmuAPU: function(buffer: pointer; length: longword; ltype: byte): pointer; stdcall;
    SPCBuffer: TSPC;
    RAMBuffer: ^TRAM;
    DSPBuffer: ^TDSP;
    EmuBuffer: array[0..$FFFF] of byte;

procedure ClearEcho();
var
    Z: longword;
    dwEchoRegion: longword;
    dwEchoSize: longword;
    dwEchoMax: longword;
begin
    if longbool(DSPBuffer.Dsp[$6C] and $20) then exit;
    dwEchoRegion := DSPBuffer.Dsp[$6D] shl 8;
    dwEchoSize := DSPBuffer.Dsp[$7D] shl 11;
    if not longbool(dwEchoSize) then dwEchoSize := 4;
    dwEchoMax := dwEchoRegion + dwEchoSize;
    for Z := dwEchoRegion to dwEchoMax - 1 do begin
        SPCBuffer.Ram[Z and $FFFF] := 0;
        RAMBuffer.Ram[Z and $FFFF] := 0;
    end;
end;

begin
    sSPCFile := GetParameter(I, J, false);
    sOutFile := GetParameter(I, J, false);
    hSPCFile := INVALID_HANDLE_VALUE;
    hOutFile := INVALID_HANDLE_VALUE;
    hDLL := NULL;
    try
        // パラメータ チェック
        if sOutFile = '' then begin
            result := 201;
            writeln(output, Concat(STR_ERROR_201[dwLanguage], ' (code 201)'));
            exit;
        end;
        if sOutFile = sSPCFile then begin
            result := 202;
            writeln(output, Concat(STR_ERROR_202[dwLanguage], ' (code 202)'));
            exit;
        end;
        // 出力先ファイルを用意
        hOutFile := API_CreateFile(pchar(sOutFile), GENERIC_WRITE, FILE_SHARE_READ, NULLPOINTER, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL or FILE_FLAG_SEQUENTIAL_SCAN, NULL);
        if hOutFile = INVALID_HANDLE_VALUE then begin
            result := 203;
            writeln(output, Concat(STR_ERROR_203[dwLanguage], ' (code 203)'));
            exit;
        end;
        // SPC バッファを読み込み
        hSPCFile := API_CreateFile(pchar(sSPCFile), GENERIC_READ, FILE_SHARE_READ, NULLPOINTER, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL or FILE_FLAG_SEQUENTIAL_SCAN, NULL);
        if hSPCFile = INVALID_HANDLE_VALUE then begin
            result := 204;
            writeln(output, Concat(STR_ERROR_204[dwLanguage], ' (code 204)'));
            exit;
        end;
        API_ReadFile(hSPCFile, @SPCBuffer, $10200, @dwSize, NULLPOINTER);
        // SNESAPU.DLL を読み込み
        hDLL := API_LoadLibrary(pchar('snesapu.dll'));
        if not longbool(hDLL) then begin
            result := 205;
            writeln(output, Concat(STR_ERROR_205[dwLanguage], ' (code 205)'));
            exit;
        end;
        // 関数を読み込み
        @GetAPUData := API_GetProcAddress(hDLL, pchar('GetAPUData'));
        @LoadSPCFile := API_GetProcAddress(hDLL, pchar('LoadSPCFile'));
        @EmuAPU := API_GetProcAddress(hDLL, pchar('EmuAPU'));
        if not longbool(@GetAPUData) or not longbool(@EmuAPU) or not longbool(@LoadSPCFile) then begin
            result := 206;
            writeln(output, Concat(STR_ERROR_206[dwLanguage], ' (code 206)'));
            exit;
        end;
        // エコー領域クリア
        GetAPUData(@RAMBuffer, NULLPOINTER, NULLPOINTER, NULLPOINTER, @DSPBuffer, NULLPOINTER, NULLPOINTER, NULLPOINTER);
        LoadSPCFile(@SPCBuffer);
        ClearEcho();
        for X := 0 to 4 do begin
            for Y := 1 to 12800 do EmuAPU(@EmuBuffer, 384, 0);
            ClearEcho();
        end;
        // SPC バッファを書き込み
        API_WriteFile(hOutFile, @SPCBuffer, $10200, @dwSize, NULLPOINTER);
        // 終了
        writeln(output, STR_DONE[dwLanguage]);
        result := 0;
    finally
        if hSPCFile <> INVALID_HANDLE_VALUE then API_CloseHandle(hSPCFile);
        if hOutFile <> INVALID_HANDLE_VALUE then API_CloseHandle(hOutFile);
        if longbool(hDLL) then API_FreeLibrary(hDLL);
    end;
end;

procedure _ApuWrite(port: longword; data: byte); stdcall;
begin
    API_SendMessage(_hWndApp, WM_APP_MESSAGE, WM_APP_SET_PORT + port, data);
end;

function _ApuRead(port: longword): byte; stdcall;
begin
    API_SendMessage(_hWndApp, WM_APP_MESSAGE, WM_APP_EMU_APU, NULL);
    result := byte(API_SendMessage(_hWndApp, WM_APP_MESSAGE, WM_APP_GET_PORT + port, NULL));
end;

function PortDebug(): longword;
var
    X: longword;
    Y: longword;
    step: longword;
    ms: longword;
    sSPCFile: string;
    hSPCFile: longword;
    dwSize: longword;
    hDLL: longword;
    GetAPUData: procedure(ppRam: pointer; ppXRam: pointer; ppSPCOutput: pointer; ppT64Count: pointer; ppDsp: pointer; ppVoices: pointer; ppVolumeMaxLeft: pointer; ppVolumeMaxRight: pointer); stdcall;
    LoadSPCFile: procedure(pSPCFile: pointer); stdcall;
    EmuAPU: function(buffer: pointer; length: longword; ltype: byte): pointer; stdcall;
    SPCBuffer: TSPC;
    RAMBuffer: ^TRAM;
    DSPBuffer: ^TDSP;
    EmuBuffer: array[0..$FFFF] of byte;
    dwEchoRegion: array[0..1] of longword;
    dwEchoSize: array[0..1] of longword;
    dwEchoMax: array[0..1] of longword;
    count: longword;
    bootptr: longword;
    bootcode: array[0..255] of byte;
    memloader: array[0..255] of byte;
    port0: byte;

procedure ClearEcho(idx: longword);
var
    Z: longword;
begin
    dwEchoRegion[idx] := $FFFF;
    dwEchoSize[idx] := 0;
    dwEchoMax[idx] := $FFFF;
    if longbool(DSPBuffer.Dsp[$6C] and $20) then exit;
    dwEchoRegion[idx] := DSPBuffer.Dsp[$6D] shl 8;
    dwEchoSize[idx] := DSPBuffer.Dsp[$7D] shl 11;
    if not longbool(dwEchoSize[idx]) then dwEchoSize[idx] := 4;
    dwEchoMax[idx] := dwEchoRegion[idx] + dwEchoSize[idx];
    for Z := dwEchoRegion[idx] to dwEchoMax[idx] - 1 do begin
        SPCBuffer.Ram[Z and $FFFF] := $01;
        RAMBuffer.Ram[Z and $FFFF] := $01;
    end;
end;

procedure ApuWrite(port: longword; data: byte);
begin
    _ApuWrite(port, data);
end;

function ApuRead(port: longword): byte;
begin
    result := _ApuRead(port);
end;

function ApuWaitInPort(port: longword; data: byte; timeout: longword): longbool;
var
    ms: longword;
begin
    result := false;
    ms := API_timeGetTime() + timeout;
    while ApuRead(port) <> data do if API_timeGetTime() >= ms then exit;
    result := true;
end;

function ApuWriteHandshake(port: longword; data: byte): longbool;
begin
    result := false;
    ApuWrite(port, data);
    ApuWrite(0, port0);
    if not ApuWaitInPort(0, port0, 500) then exit;
    Inc(port0);
    result := true;
end;

function ApuWriteBytes(data: array of byte; start: longword; len: longword): longbool;
var
    I: longword;
begin
    result := false;
    for I := 0 to len - 1 do if not ApuWriteHandShake(1, data[I + start]) then exit;
    result := true;
end;

function ApuInitTransfer(addr: longword): longbool;
begin
    result := false;
    if not ApuWaitInPort(0, $AA, 500) then exit;
    if not ApuWaitInPort(1, $BB, 500) then exit;
    ApuWrite(1, 1);
    ApuWrite(2, addr and $FF);
    ApuWrite(3, (addr and $FF00) shr 8);
    ApuWrite(0, $CC);
    if not ApuWaitInPort(0, $CC, 500) then exit;
    port0 := 0;
    result := true;
end;

function ApuNewTransfer(addr: longword): longbool;
var
    data: byte;
begin
    result := false;
    ApuWrite(1, 1);
    ApuWrite(3, (addr and $FF00) shr 8);
    ApuWrite(2, addr and $FF);
    data := ApuRead(0);
    Inc(data, 2);
    if data = 0 then Inc(data, 2);
    ApuWrite(0, data);
    if not ApuWaitInPort(0, data, 500) then exit;
    port0 := 0;
    result := true;
end;

function ApuEndTransfer(addr: longword): longbool;
var
    data: byte;
begin
    ApuWrite(1, 0);
    ApuWrite(3, (addr and $FF00) shr 8);
    ApuWrite(2, addr and $FF);
    data := ApuRead(0);
    Inc(data, 2);
    if data = 0 then Inc(data, 2);
    ApuWrite(0, data);
    result := true;
end;

begin
    sSPCFile := GetParameter(I, J, false);
    hSPCFile := INVALID_HANDLE_VALUE;
    hDLL := NULL;
    for X := 0 to Length(ASM_BOOTCODE) - 1 do bootcode[X] := ASM_BOOTCODE[X];
    for X := 0 to Length(ASM_MEMLOADER) - 1 do memloader[X] := ASM_MEMLOADER[X];
    memloader[Length(ASM_MEMLOADER) - 1] := 199 - Length(ASM_MEMLOADER);
    port0 := 0;
    result := 0;
    try
        // ウィンドウを検索
        hWnd := API_FindWindowEx(NULL, NULL, PChar(CLASS_NAME), NULLPOINTER);
        // ウィンドウが見つからなかった場合
        if not longbool(hWnd) then begin
            result := 101;
            writeln(output, Concat(STR_ERROR_101[dwLanguage], ' (code 101)'));
            exit;
        end;
        _hWndApp := hWnd;
        // バージョンを取得
        dwVersion := API_SendMessage(hWnd, WM_APP_MESSAGE, WM_APP_APPVER, NULL);
        // バージョンが対応していない場合
        if dwVersion <> APPLINK_VERSION then begin
            result := 102;
            writeln(output, Concat(STR_ERROR_102[dwLanguage], ' (code 102)'));
            exit;
        end;
        // SPC バッファを読み込み
        hSPCFile := API_CreateFile(pchar(sSPCFile), GENERIC_READ, FILE_SHARE_READ, NULLPOINTER, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL or FILE_FLAG_SEQUENTIAL_SCAN, NULL);
        if hSPCFile = INVALID_HANDLE_VALUE then begin
            result := 301;
            writeln(output, Concat(STR_ERROR_301[dwLanguage], ' (code 301)'));
            exit;
        end;
        API_ReadFile(hSPCFile, @SPCBuffer, $10200, @dwSize, NULLPOINTER);
        // SNESAPU.DLL を読み込み
        hDLL := API_LoadLibrary(pchar('snesapu.dll'));
        if not longbool(hDLL) then begin
            result := 302;
            writeln(output, Concat(STR_ERROR_302[dwLanguage], ' (code 302)'));
            exit;
        end;
        // 関数を読み込み
        @GetAPUData := API_GetProcAddress(hDLL, pchar('GetAPUData'));
        @LoadSPCFile := API_GetProcAddress(hDLL, pchar('LoadSPCFile'));
        @EmuAPU := API_GetProcAddress(hDLL, pchar('EmuAPU'));
        if not longbool(@GetAPUData) or not longbool(@EmuAPU) or not longbool(@LoadSPCFile) then begin
            result := 303;
            writeln(output, Concat(STR_ERROR_303[dwLanguage], ' (code 303)'));
            exit;
        end;
        // エコー領域クリア
        writeln(output, 'エコー領域をクリア中...');
        GetAPUData(@RAMBuffer, NULLPOINTER, NULLPOINTER, NULLPOINTER, @DSPBuffer, NULLPOINTER, NULLPOINTER, NULLPOINTER);
        LoadSPCFile(@SPCBuffer);
        ClearEcho(0);
        for X := 0 to 4 do begin
            for Y := 1 to 12800 do EmuAPU(@EmuBuffer, 384, 0);
            ClearEcho(1);
        end;
        // bootcode にパラメータをコピー
        bootcode[$01] := SPCBuffer.Ram[$00]; // RAM
        bootcode[$04] := SPCBuffer.Ram[$01]; // RAM
        bootcode[$10] := SPCBuffer.Ram[$F1]; // SPC700 control
        bootcode[$41] := SPCBuffer.Ram[$F2]; // SPC700 register add
        bootcode[$19] := SPCBuffer.Ram[$F4]; // SPC700 port0
        bootcode[$1F] := SPCBuffer.Ram[$F5]; // SPC700 port1
        bootcode[$25] := SPCBuffer.Ram[$F6]; // SPC700 port2
        bootcode[$2B] := SPCBuffer.Ram[$F7]; // SPC700 port3
        bootcode[$0D] := SPCBuffer.Ram[$FA]; // SPC700 timer0
        bootcode[$0A] := SPCBuffer.Ram[$FB]; // SPC700 timer1
        bootcode[$07] := SPCBuffer.Ram[$FC]; // SPC700 timer2
        bootcode[$38] := SPCBuffer.Dsp[$6C]; // DSP flags
        bootcode[$3E] := SPCBuffer.Dsp[$4C]; // DSP KON
        bootcode[$47] := SPCBuffer.Hdr[$27]; // SPC700 register A
        bootcode[$49] := SPCBuffer.Hdr[$29]; // SPC700 register Y
        bootcode[$4B] := SPCBuffer.Hdr[$28]; // SPC700 register X
        // スタック領域にパラメータをコピー
        SPCBuffer.Ram[$100 or ((SPCBuffer.Hdr[$2B] - 0) and $FF)] := SPCBuffer.Hdr[$26]; // SPC700 register PC(H)
        SPCBuffer.Ram[$100 or ((SPCBuffer.Hdr[$2B] - 1) and $FF)] := SPCBuffer.Hdr[$25]; // SPC700 register PC(L)
        SPCBuffer.Ram[$100 or ((SPCBuffer.Hdr[$2B] - 2) and $FF)] := SPCBuffer.Hdr[$2A]; // SPC700 register PSW
        bootcode[$44] := (SPCBuffer.Hdr[$2B] - 3) and $FF;
        // 転送中はミュート
        SPCBuffer.Dsp[$6C] := $60;
        SPCBuffer.Dsp[$4C] := $00;
        // bootcode を入れる場所を探索 (STEP 1)
        writeln(output, 'Boot Code の空き領域を探索中...');
        step := 1;
        count := 0;
        bootptr := 65471;
        while bootptr >= 256 do begin
            if SPCBuffer.Ram[bootptr] = $00 then Inc(count) else count := 0;
            if count = longword(Length(ASM_BOOTCODE)) then break;
            Dec(bootptr);
        end;
        // bootcode を入れる場所を探索 (STEP 2)
        if count <> longword(Length(ASM_BOOTCODE)) then begin
            step := 2;
            count := 0;
            bootptr := 65471;
            while bootptr >= 256 do begin
                if (SPCBuffer.Ram[bootptr] = $00) or (SPCBuffer.Ram[bootptr] = $FF) then Inc(count) else count := 0;
                if count = longword(Length(ASM_BOOTCODE)) then break;
                Dec(bootptr);
            end;
        end;
        // bootcode を入れる場所を探索 (STEP 3)
        for X := 0 to 1 do for Y := dwEchoRegion[X] to dwEchoMax[X] - 1 do SPCBuffer.Ram[Y and $FFFF] := $00;
        if count <> longword(Length(ASM_BOOTCODE)) then begin
            step := 3;
            count := 0;
            bootptr := 65471;
            while bootptr >= 256 do begin
                if (SPCBuffer.Ram[bootptr] = $00) or (SPCBuffer.Ram[bootptr] = $FF) then Inc(count) else count := 0;
                if count = longword(Length(ASM_BOOTCODE)) then break;
                Dec(bootptr);
            end;
        end;
        // bootcode の空き領域チェック
        if count <> longword(Length(ASM_BOOTCODE)) then begin
            result := 311;
            writeln(output, 'Boot Code を書き込むための空き領域がありません。 (code 311)');
            exit;
        end;
        // bootcode をコピー
        write(output, 'Boot Code のアドレス = ');
        IntToHex(StrData, bootptr, 4);
        write(output, Copy(String(StrData.cData), 1, 4));
        write(output, '～');
        IntToHex(StrData, bootptr + count - 1, 4);
        write(output, Copy(String(StrData.cData), 1, 4));
        write(output, ' (STEP ');
        IntToHex(StrData, step, 1);
        write(output, Copy(String(StrData.cData), 1, 1));
        writeln(output, ')');
        if step >= 3 then writeln(output, '※実機では冒頭でノイズが発生する場合があります。');
        for X := 0 to count - 1 do SPCBuffer.Ram[(bootptr + X) and $FFFF] := bootcode[X];
        // 初期化待ち
        writeln(output, '');
        writeln(output, '+------------------------------------------------------------+');
        writeln(output, '| (!) SPC 転送を開始します。                                 |');
        writeln(output, '|     転送中は SNES SPC700 Player を操作しないでください。   |');
        writeln(output, '+------------------------------------------------------------+');
        writeln(output, '');
        writeln(output, 'SPC700 のリセットを待機中...');
        ms := API_timeGetTime();
        API_SendMessage(hWnd, WM_APP_MESSAGE, WM_APP_EMU_DEBUG or $1, NULL);
        API_SendMessage(hWnd, WM_COMMAND, MENU_FILE_STOP, NULL); // stop
        API_SendMessage(hWnd, WM_COMMAND, MENU_FILE_PLAY, NULL); // play
        API_SendMessage(hWnd, WM_COMMAND, MENU_FILE_PLAY, NULL); // pause
        if not ApuInitTransfer(2) then begin
            result := 312;
            writeln(output, 'SPC700 がリセットされていません。 (code 312)');
            exit;
        end;
        // memloader を送信
        writeln(output, '転送プログラムを送信中...');
        if not ApuWriteBytes(memloader, 0, Length(ASM_MEMLOADER)) then begin
            result := 313;
            writeln(output, '転送プログラムを送信できません。 (code 313)');
            exit;
        end;
        if not ApuEndTransfer(2) then begin
            result := 314;
            writeln(output, '転送プログラムを送信できません。 (code 314)');
            exit;
        end;
        // memloader を実行開始
        if not ApuWaitInPort(2, $53, 500) then begin
            result := 315;
            writeln(output, '転送プログラムを開始しましたが、応答がありません (code 315)');
            exit;
        end;
        // DSP レジスタを送信
        writeln(output, 'DSP レジスタを送信中...');
        port0 := 0;
        if not ApuWriteBytes(SPCBuffer.Dsp, 0, 128) then begin
            result := 316;
            writeln(output, 'DSP レジスタを送信できません。 (code 316)');
            exit;
        end;
        // RAM 転送準備
        ApuWrite(0, $0);
        if not ApuWaitInPort(2, $0, 500) then begin
            result := 317;
            writeln(output, 'DSP レジスタを送信できません。 (code 317)');
            exit;
        end;
        // RAM 転送 (0x0100～0xFFBE)
        write(output, 'RAM を送信中...');
        X := $100;
        Y := 1;
        while X < $FFBE do begin
            ApuWrite(1, SPCBuffer.Ram[X]);
            ApuWrite(2, SPCBuffer.Ram[X + 1]);
            ApuWrite(3, SPCBuffer.Ram[X + 2]);
            ApuWrite(0, Y);
            if not ApuWaitInPort(0, Y, 500) then begin
                result := 318;
                writeln(output, '');
                writeln(output, 'RAM を送信できません。 (code 318)');
                exit;
            end;
            Inc(X, 3);
            Y := Y xor 1;
            if not longbool((X - $100) mod $600) then write(output, '.');
        end;
        writeln(output, '');
        ApuWrite(0, $80);
        // RAM 転送 (0x0002～0x00EF)
        if not ApuInitTransfer(2) then begin
            result := 319;
            writeln(output, 'RAM を送信できません。 (code 319)');
            exit;
        end;
        if not ApuWriteBytes(SPCBuffer.Ram, $2, $ED) then begin
            result := 320;
            writeln(output, 'RAM を送信できません。 (code 320)');
            exit;
        end;
        // RAM 転送 (0xFFBE～0xFFBF)
        if not ApuNewTransfer($FFBE) then begin
            result := 321;
            writeln(output, 'RAM を送信できません。 (code 321)');
            exit;
        end;
        if not ApuWriteBytes(SPCBuffer.Ram, $FFBE, 2) then begin
            result := 322;
            writeln(output, 'RAM を送信できません。 (code 322)');
            exit;
        end;
        // XRAM 転送 (0xFFC0～0xFFFF)
        writeln(output, 'XRAM を送信中...');
        if (SPCBuffer.Ram[$F1] and $80) > 0 then begin
            if not ApuWriteBytes(SPCBuffer.XRam, 0, 64) then begin
                result := 321;
                writeln(output, 'XRAM を送信できません。 (code 321)');
                exit;
            end;
        end else begin
            if not ApuWriteBytes(SPCBuffer.Ram, 65472, 64) then begin
                result := 322;
                writeln(output, 'RAM (0xFFC0～0xFFFF) を送信できません。 (code 322)');
                exit;
            end;
        end;
        // bootcode を実行開始
        writeln(output, '演奏開始準備中...');
        if not ApuEndTransfer(bootptr) then begin
            result := 323;
            writeln(output, 'Boot Code を開始できません (code 323)');
            exit;
        end;
        if not ApuWaitInPort(0, $53, 500) then begin
            result := 324;
            writeln(output, 'Boot Code を開始しましたが、応答がありません (code 324)');
            exit;
        end;
        // SPC ポートを転送
        ApuWrite(0, SPCBuffer.Ram[$F4]);
        ApuWrite(1, SPCBuffer.Ram[$F5]);
        ApuWrite(2, SPCBuffer.Ram[$F6]);
        ApuWrite(3, SPCBuffer.Ram[$F7]);
        // 終了
        writeln(output, STR_DONE[dwLanguage]);
        writeln(output, Concat('TIME = ', IntToStr(API_timeGetTime() - ms), ' [ms]'));
    finally
        if not longbool(result) then API_SendMessage(hWnd, WM_COMMAND, MENU_FILE_PLAY, NULL); // play
        if longbool(hWnd) then API_SendMessage(hWnd, WM_APP_MESSAGE, WM_APP_EMU_DEBUG, NULL);
        if hSPCFile <> INVALID_HANDLE_VALUE then API_CloseHandle(hSPCFile);
        if longbool(hDLL) then API_FreeLibrary(hDLL);
    end;
end;

function TransferDebug(): longword;
var
    sSPCFile: string;
    sScript700File: string;
    hSPCFile: longword;
    hScript700File: longword;
    dwSize: longword;
    dwHigh: longword;
    hDLL: longword;
    LoadSPCFile: procedure(pSPCFile: pointer); stdcall;
    SetScript700: procedure(pSource: pointer); stdcall;
    TransmitSPCEx: function(pType: pointer): longword; stdcall;
    StopTransmitSPC: function(): longword; stdcall;
    SPCBuffer: TSPC;
    lpBuffer: pointer;
    table: TTRANSFERSPCEX;
    ms: longword;

begin
    sSPCFile := GetParameter(I, J, false);
    sScript700File := GetParameter(I, J, false);
    hSPCFile := INVALID_HANDLE_VALUE;
    hScript700File := INVALID_HANDLE_VALUE;
    hDLL := NULL;
    result := 0;
    try
        // ウィンドウを検索
        hWnd := API_FindWindowEx(NULL, NULL, PChar(CLASS_NAME), NULLPOINTER);
        // ウィンドウが見つからなかった場合
        if not longbool(hWnd) then begin
            result := 101;
            writeln(output, Concat(STR_ERROR_101[dwLanguage], ' (code 101)'));
            exit;
        end;
        _hWndApp := hWnd;
        // バージョンを取得
        dwVersion := API_SendMessage(hWnd, WM_APP_MESSAGE, WM_APP_APPVER, NULL);
        // バージョンが対応していない場合
        if dwVersion <> APPLINK_VERSION then begin
            result := 102;
            writeln(output, Concat(STR_ERROR_102[dwLanguage], ' (code 102)'));
            exit;
        end;
        // SPC バッファを読み込み
        hSPCFile := API_CreateFile(pchar(sSPCFile), GENERIC_READ, FILE_SHARE_READ, NULLPOINTER, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL or FILE_FLAG_SEQUENTIAL_SCAN, NULL);
        if hSPCFile = INVALID_HANDLE_VALUE then begin
            result := 301;
            writeln(output, Concat(STR_ERROR_301[dwLanguage], ' (code 301)'));
            exit;
        end;
        API_ReadFile(hSPCFile, @SPCBuffer, $10200, @dwSize, NULLPOINTER);
        // SNESAPU.DLL を読み込み
        hDLL := API_LoadLibrary(pchar('snesapu.dll'));
        if not longbool(hDLL) then begin
            result := 302;
            writeln(output, Concat(STR_ERROR_302[dwLanguage], ' (code 302)'));
            exit;
        end;
        @LoadSPCFile := API_GetProcAddress(hDLL, pchar('LoadSPCFile'));
        @SetScript700 := API_GetProcAddress(hDLL, pchar('SetScript700'));
        @TransmitSPCEx := API_GetProcAddress(hDLL, pchar('TransmitSPCEx'));
        @StopTransmitSPC := API_GetProcAddress(hDLL, pchar('StopTransmitSPC'));
        if not longbool(@LoadSPCFile) or not longbool(@SetScript700) or not longbool(@TransmitSPCEx) or not longbool(@StopTransmitSPC) then begin
            result := 303;
            writeln(output, Concat(STR_ERROR_303[dwLanguage], ' (code 303)'));
            exit;
        end;
        // SPC バッファをセット
        LoadSPCFile(@SPCBuffer);
        // Script700 バッファを読み込み
        if sScript700File <> '' then begin
            hScript700File := API_CreateFile(pchar(sScript700File), GENERIC_READ, FILE_SHARE_READ, NULLPOINTER, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL or FILE_FLAG_SEQUENTIAL_SCAN, NULL);
            if hScript700File = INVALID_HANDLE_VALUE then begin
                result := 304;
                writeln(output, Concat(STR_ERROR_304[dwLanguage], ' (code 304)'));
                exit;
            end;
            dwSize := API_GetFileSize(hScript700File, @dwHigh);
            GetMem(lpBuffer, dwSize + 1);
            API_ZeroMemory(lpBuffer, dwSize + 1);
            API_ReadFile(hScript700File, lpBuffer, dwSize, @dwHigh, NULLPOINTER);
            SetScript700(lpBuffer);
            FreeMem(lpBuffer, dwSize + 1);
        end;
        // 初期化待ち
        writeln(output, 'SNESAPU.DLL の機能を使用して転送します。');
        writeln(output, '');
        writeln(output, '┏ ──────────────────────────────── ┓');
        writeln(output, '┫(!) SPC 転送を開始します。                                        ┃');
        writeln(output, '┫    転送中は SNES SPC700 Player を操作しないでください。          ┃');
        writeln(output, '┗ ──────────────────────────────── ┛');
        writeln(output, '');
        ms := API_timeGetTime();
        API_SendMessage(hWnd, WM_APP_MESSAGE, WM_APP_EMU_DEBUG or $1, NULL);
        API_SendMessage(hWnd, WM_COMMAND, MENU_FILE_STOP, NULL); // stop
        API_SendMessage(hWnd, WM_COMMAND, MENU_FILE_PLAY, NULL); // play
        API_SendMessage(hWnd, WM_COMMAND, MENU_FILE_PLAY, NULL); // pause
        // 転送開始
        writeln(output, 'SNESAPU.DLL でおまかせ転送中...');
        API_ZeroMemory(@table, SizeOf(table));
        table.cbSize := SizeOf(table);
        table.transmitType := 3; // TRANSMITSPC_TYPE_CALLBACK
        table.bScript700 := hScript700File <> INVALID_HANDLE_VALUE;
        table.pCallbackRead := @_ApuRead;
        table.pCallbackWrite := @_ApuWrite;
        dwHigh := TransmitSPCEx(@table);
        writeln(output, Concat('TransmitSPCEx = ', IntToStr(dwHigh)));
        if longbool(dwHigh) then begin
            result := 311;
            writeln(output, '転送に失敗しました。 (code 311)');
            exit;
        end;
        // Script700 を使用していない場合は終了
        if hScript700File = INVALID_HANDLE_VALUE then begin
            writeln(output, STR_DONE[dwLanguage]);
            writeln(output, Concat('TIME = ', IntToStr(API_timeGetTime() - ms), ' [ms]'));
            exit;
        end;
        // スリープ
        API_SendMessage(hWnd, WM_COMMAND, MENU_FILE_PLAY, NULL); // play
        API_Sleep(15000);
        // 終了
        dwHigh := StopTransmitSPC();
        writeln(output, Concat('StopTransmitSPC = ', IntToStr(dwHigh)));
        writeln(output, STR_DONE[dwLanguage]);
        writeln(output, Concat('TIME = ', IntToStr(API_timeGetTime() - ms), ' [ms]'));
    finally
        if not longbool(result) then API_SendMessage(hWnd, WM_COMMAND, MENU_FILE_PLAY, NULL); // play
        if longbool(hWnd) then API_SendMessage(hWnd, WM_APP_MESSAGE, WM_APP_EMU_DEBUG, NULL);
        if hSPCFile <> INVALID_HANDLE_VALUE then API_CloseHandle(hSPCFile);
        if hScript700File <> INVALID_HANDLE_VALUE then API_CloseHandle(hScript700File);
        if longbool(hDLL) then API_FreeLibrary(hDLL);
    end;
end;

function WaitOpenWindow(): longbool;
var
    dwCount: longword;
begin
    // 初期化
    dwCount := 50;
    // ウィンドウを検索
    while longbool(dwCount) and not longbool(hWnd) do begin
        hWnd := API_FindWindowEx(NULL, NULL, PChar(CLASS_NAME), NULLPOINTER);
        API_Sleep(100);
        Dec(dwCount);
    end;
    result := longbool(hWnd);
end;

function WaitRunning(): longbool;
var
    dwCount: longword;
    dwVer: longword;
begin
    // 初期化
    dwCount := 50;
    dwVer := NULL;
    // 起動状態を取得
    while longbool(dwCount) and not longbool(dwVer) do begin
        dwVer := API_SendMessage(hWnd, WM_APP_MESSAGE, WM_APP_APPVER, NULL);
        API_Sleep(100);
        Dec(dwCount);
    end;
    result := longbool(dwVer);
end;

procedure OutputValue(dwValue: longword);
begin
    IntToHex(StrData, dwValue, 8);
    write(output, STR_RESULT[dwLanguage]);
    write(output, ' = $');
    write(output, String(StrData.cData));
    write(output, ' (');
    write(output, IntToStr(dwValue));
    writeln(output, ')');
end;

procedure OutputMemoryMap(msg: longword; size: longint);
var
    X: longint;
    Y: longint;
begin
    SetLength(cBuffer, 12);
    cBuffer[$2] := ' ';
    cBuffer[$5] := ' ';
    cBuffer[$8] := ' ';
    cBuffer[$B] := ' ';
    writeln(output, '');
    write(output, 'Addr  :  +0 +1 +2 +3 +4 +5 +6 +7  +8 +9 +A +B +C +D +E +F');
    for X := dwParam1 to dwParam1 + (dwParam2 or $F) do begin
        if longbool(X and $FFFF0000) then break;
        if not longbool(X and $F) then begin
            writeln(output, '');
            IntToHex(StrData, X, 4);
            write(output, Copy(String(StrData.cData), 1, 4));
            write(output, '  : ');
        end;
        if not longbool(X and $7) then begin
            write(output, ' ');
        end;
        if not longbool(X and $3) then begin
            J := 0;
            for Y := 0 to size - 1 do J := J or longint(API_SendMessage(hWnd, WM_APP_MESSAGE, msg or longword((X + Y) and $FFFF), NULL) shl (Y shl 3));
            IntToHex(StrData, J, 8);
            cBuffer[$0] := StrData.cData[$6];
            cBuffer[$1] := StrData.cData[$7];
            cBuffer[$3] := StrData.cData[$4];
            cBuffer[$4] := StrData.cData[$5];
            cBuffer[$6] := StrData.cData[$2];
            cBuffer[$7] := StrData.cData[$3];
            cBuffer[$9] := StrData.cData[$0];
            cBuffer[$A] := StrData.cData[$1];
            write(output, String(cBuffer));
        end;
    end;
    writeln(output, '');
end;

function OutputWave(): longword;
var
    M: longint;
    N: longint;
    X: longword;
    Y: longword;
    dwType: longword;
    dwCount: longword;
    sInFile: string;
    sSPCFiles: array of string;
    sSPCFile: string;
    sOutFile: string;
    sWavFile: string;
    posYen: longint;
    posDot: longint;
    hWndStatic: longword;
    lpString: pointer;
    lpPath: pointer;

function GetFileType(lpFile: pointer): longword;
var
    hFile: longword;
    dwReadSize: longword;
    cBuffer: array[0..63] of char;
    cSPCHeader: array[0..SPC_FILE_HEADER_LEN - 1] of char;
    cListHeaderA: array[0..LIST_FILE_HEADER_A_LEN - 1] of char;
    cListHeaderB: array[0..LIST_FILE_HEADER_B_LEN - 1] of char;
begin
    // 初期化
    result := FILE_TYPE_NOTEXIST;
    // フォルダが存在する場合
    if Exists(lpFile, 0) then result := FILE_TYPE_FOLDER;
    // ファイルが存在する場合
    if Exists(lpFile, $FFFFFFFF) then repeat
        // 初期化
        result := FILE_TYPE_NOTREAD;
        // ファイルをオープン
        hFile := INVALID_HANDLE_VALUE;
        if IsSafePath(lpFile) then hFile := API_CreateFile(lpFile, GENERIC_READ, FILE_SHARE_READ, NULLPOINTER, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL or FILE_FLAG_SEQUENTIAL_SCAN, NULL);
        // ファイルのオープンに失敗した場合はループを抜ける
        if hFile = INVALID_HANDLE_VALUE then break;
        // 初期化
        result := FILE_TYPE_UNKNOWN;
        // ファイルをロード
        API_ZeroMemory(@cBuffer[0], 64);
        API_ReadFile(hFile, @cBuffer[0], 64, @dwReadSize, NULLPOINTER);
        // バッファをコピー
        API_MoveMemory(@cSPCHeader[0], @cBuffer[0], SPC_FILE_HEADER_LEN);
        API_MoveMemory(@cListHeaderA[0], @cBuffer[0], LIST_FILE_HEADER_A_LEN);
        API_MoveMemory(@cListHeaderB[0], @cBuffer[0], LIST_FILE_HEADER_B_LEN);
        // ファイルの種類を取得
        if string(cSPCHeader) = SPC_FILE_HEADER then result := FILE_TYPE_SPC;
        if string(cListHeaderA) = LIST_FILE_HEADER_A then result := FILE_TYPE_LIST_A;
        if string(cListHeaderB) = LIST_FILE_HEADER_B then result := FILE_TYPE_LIST_B;
        // ファイルをクローズ
        API_CloseHandle(hFile);
    until true;
end;

function GetList(lpFile: pointer): longbool;
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
begin
    repeat
        // ファイルをオープン
        hFile := INVALID_HANDLE_VALUE;
        if IsSafePath(lpFile) then hFile := API_CreateFile(lpFile, GENERIC_READ, FILE_SHARE_READ, NULLPOINTER, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL or FILE_FLAG_SEQUENTIAL_SCAN, NULL);
        // ファイルのオープンに失敗した場合はループを抜ける
        if hFile = INVALID_HANDLE_VALUE then break;
        // プレイリストのアイテム数と現在の場所を取得
        dwListNum := 0;
        dwTopIndex := 0;
        dwIndex := 0;
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
        if dwListNum > 32767 then dwListNum := 32767;
        // バッファを確保
        SetLength(sSPCFiles, dwListNum);
        GetMem(lpListFile, 1024);
        GetMem(lpTitle, 33);
        // プレイリストを取得
        for I := 0 to dwListNum - 1 do begin
            dwSizeFile := 260;
            dwSizeTitle := 32;
            case dwType of
                FILE_TYPE_LIST_B: begin
                    // データ サイズを取得
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
            // ファイル パスを取得
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
            SetLength(cBuffer, dwSizeFile);
            API_MoveMemory(@cBuffer[0], lpListFile, dwSizeFile);
            sSPCFiles[I] := string(cBuffer);
        end;
        // バッファを解放
        FreeMem(lpListFile, 1024);
        FreeMem(lpTitle, 33);
    until true;
    // ファイルをクローズ
    if hFile <> INVALID_HANDLE_VALUE then API_CloseHandle(hFile);
    // 成功
    result := true;
end;

begin
    // パスを取得
    sInFile := GetParameter(I, J, false);
    sOutFile := GetParameter(I, J, false);
    // ファイルタイプを取得
    dwType := GetFileType(pchar(sInFile));
    case dwType of
        FILE_TYPE_SPC: begin
            dwCount := 1;
            SetLength(sSPCFiles, dwCount);
            sSPCFiles[0] := sInFile;
        end;
        FILE_TYPE_LIST_A, FILE_TYPE_LIST_B: begin
            GetList(pchar(sInFile));
        end;
        else begin
            result := 401;
            writeln(output, Concat(STR_ERROR_401[dwLanguage], ' (code 401)'));
            exit;
        end;
    end;
    // バッファを確保
    GetMem(lpPath, 1024);
    N := Length(sSPCFiles);
    // ループ
    for M := 0 to N - 1 do begin
        sSPCFile := sSPCFiles[M];
        if not longbool(Length(sOutFile)) then begin
            // 出力先パスが指定されていない場合
            posDot := 0;
            Y := Length(sSPCFile);
            for X := 1 to Y do if IsSingleByte(sSPCFile, X, '.') then posDot := X;
            sWavFile := Concat(Copy(sSPCFile, 1, posDot), 'wav');
        end else if (N >= 2) or Exists(pchar(sOutFile), 0) then begin
            // 出力ファイルが複数、または、フォルダが指定された場合
            posYen := 0;
            posDot := 0;
            Y := Length(sSPCFile);
            for X := 1 to Y do begin
                if IsSingleByte(sSPCFile, X, '\') then posYen := X;
                if IsSingleByte(sSPCFile, X, '.') then posDot := X;
            end;
            sWavFile := Concat(sOutFile, '\', Concat(Copy(sSPCFile, posYen + 1, posDot - posYen), 'wav'));
        end else begin
            sWavFile := sOutFile;
        end;
        writeln(output, Concat(STR_CONVERT[dwLanguage], '  ', sSPCFile, ' -> ', sWavFile));
        // ウィンドウを検索
        hWndStatic := API_FindWindowEx(hWnd, NULL, pchar(ITEM_STATIC), pchar(FILE_DEFAULT));
        if not longbool(hWndStatic) then begin
            result := 402;
            writeln(output, Concat(STR_ERROR_402[dwLanguage], ' (code 402)'));
            exit;
        end;
        // バッファにコピー
        API_ZeroMemory(lpPath, 1024);
        lpString := pchar(sSPCFile);
        API_MoveMemory(lpPath, lpString, Length(sSPCFile));
        // メッセージを送信
        API_SendMessage(hWndStatic, WM_SETTEXT, NULL, longword(lpPath));
        X := API_SendMessage(hWnd, WM_APP_MESSAGE, WM_APP_TRANSMIT, hWndStatic);
        if not longbool(X) then begin
            result := 403;
            writeln(output, Concat(STR_ERROR_403[dwLanguage], ' (code 403)'));
            exit;
        end;
        // バッファにコピー
        API_ZeroMemory(lpPath, 1024);
        lpString := pchar(sWavFile);
        API_MoveMemory(lpPath, lpString, Length(sWavFile));
        // メッセージを送信
        API_SendMessage(hWndStatic, WM_SETTEXT, NULL, longword(lpPath));
        X := API_SendMessage(hWnd, WM_APP_MESSAGE, WM_APP_WAVE_OUTPUT or $2, hWndStatic);
        if not longbool(X) then begin
            result := 404;
            writeln(output, Concat(STR_ERROR_404[dwLanguage], ' (code 404)'));
            exit;
        end;
    end;
    // バッファを解放
    FreeMem(lpPath, 1024);
    // 終了
    writeln(output, STR_DONE[dwLanguage]);
    result := 0;
end;

begin
    // コマンドラインを取得
    lpBuffer := API_GetCommandLine();
    J := GetSize(lpBuffer, 1024);
    SetLength(cBuffer, J);
    API_MoveMemory(@cBuffer[0], lpBuffer, J);
    sBuffer := string(cBuffer);
    // パラメータを取得
    I := 1;
    sEXEPath := GetParameter(I, J, false);
    sCmdLine := GetParameter(I, J, false);
    dwParam1 := 0;
    dwParam2 := 0;
    // バッファを確保
    GetMem(lpBuffer, 1024);
    // カレント パスを取得
    API_GetModuleFileName(hThisInstance, lpBuffer, 1024);
    dwBuffer := GetPosSeparator(string(lpBuffer));
    if dwBuffer > 1024 then dwBuffer := 1024;
    API_ZeroMemory(pointer(longword(lpBuffer) + dwBuffer), 1024 - dwBuffer);
    dwBuffer := GetSize(lpBuffer, 1023);
    sChPath := Copy(string(lpBuffer), 1, dwBuffer);
    // バッファを解放
    FreeMem(lpBuffer, 1024);
    // 設定を初期化
    dwLanguage := LOCALE_AUTO;
    // INI の存在をチェック
    sData := Concat(sChPath, INI_FILE);
    if Exists(pchar(sData), $FFFFFFFF) then begin
        // ファイルをオープン
        AssignFile(fsFile, sData);
        // ファイルを読み込む
        Reset(fsFile);
        while not Eof(fsFile) do begin
            Readln(fsFile, sData);
            sLine := Copy(sData, 1, BUFFER_LENGTH);
            if sLine = BUFFER_LANGUAGE then dwLanguage := GetINIValue(dwLanguage);
        end;
        // ファイルをクローズ
        CloseFile(fsFile);
    end;
    // 設定値をチェック
    if longbool(dwLanguage) then dwLanguage := dwLanguage - 1
    else if API_GetUserDefaultLCID() and $FFFF = $0411 then dwLanguage := 0
    else dwLanguage := 1;
    if dwLanguage > 1 then dwLanguage := 0;
    // SPCCMD.EXE の破損を確認
    dwBuffer := GetPosSeparator(sEXEPath);
    if longbool(dwBuffer) then sEXEPath := Copy(sEXEPath, dwBuffer + 1, Length(sEXEPath));
    if (Length(sEXEPath) < 5) or (sEXEPath[Length(sEXEPath) - 3] <> '.') then sEXEPath := Concat(sEXEPath, '.exe');
    result := CheckImageHash(sEXEPath, 0);
    if longbool(result) then begin
        if result = 9 then writeln(output, Concat(STR_ERROR_009[dwLanguage], ' (code 009)'))
        else writeln(output, Concat(STR_ERROR_008[dwLanguage], ' (code 008)'));
        exit;
    end;
    // パラメータをチェック
    if (sCmdLine = '') or
       (sCmdLine = '/?') or (sCmdLine = '/h') or
       (sCmdLine = '-?') or (sCmdLine = '-h') then begin
        ShowVersion();
        ShowUsage();
        result := 1;
        exit;
    end else if (sCmdLine = '/v') or
                (sCmdLine = '-v') then begin
        ShowVersion();
        result := 1;
        exit;
    end else if (sCmdLine = '/gd') or (sCmdLine = '/gp') or (sCmdLine = '/gr') or (sCmdLine = '/gw') or (sCmdLine = '/gc') or (sCmdLine = '/gs') or (sCmdLine = '/sh') or (sCmdLine = '/bpn') or
                (sCmdLine = '-gd') or (sCmdLine = '-gp') or (sCmdLine = '-gr') or (sCmdLine = '-gw') or (sCmdLine = '-gc') or (sCmdLine = '-gs') or (sCmdLine = '-sh') or (sCmdLine = '-bpn') then begin
        dwParam1 := StrToInt(GetParameter(I, J, false), dwParam1);
    end else if (sCmdLine = '/sd') or (sCmdLine = '/sp') or (sCmdLine = '/sr') or (sCmdLine = '/sw') or (sCmdLine = '/sc') or (sCmdLine = '/ss') or (sCmdLine = '/tp') or (sCmdLine = '/mr') or (sCmdLine = '/bp') or (sCmdLine = '/dc') or
                (sCmdLine = '-sd') or (sCmdLine = '-sp') or (sCmdLine = '-sr') or (sCmdLine = '-sw') or (sCmdLine = '-sc') or (sCmdLine = '-ss') or (sCmdLine = '-tp') or (sCmdLine = '-mr') or (sCmdLine = '-bp') or (sCmdLine = '-dc') then begin
        dwParam1 := StrToInt(GetParameter(I, J, false), dwParam1);
        dwParam2 := StrToInt(GetParameter(I, J, false), dwParam2);
    end else if (sCmdLine = '/zc') or
                (sCmdLine = '-zc') then begin
        result := ZeroClear();
        exit;
    end else if (sCmdLine = '/pd') or
                (sCmdLine = '-pd') then begin
        result := PortDebug();
        exit;
    end else if (sCmdLine = '/td') or
                (sCmdLine = '-td') then begin
        result := TransferDebug();
        exit;
    end;
    // ウィンドウを検索
    hWnd := API_FindWindowEx(NULL, NULL, PChar(CLASS_NAME), NULLPOINTER);
    // ウィンドウが見つからなかった場合
    if not longbool(hWnd) then begin
        result := 101;
        writeln(output, Concat(STR_ERROR_101[dwLanguage], ' (code 101)'));
        exit;
    end;
    // バージョンを取得
    dwVersion := API_SendMessage(hWnd, WM_APP_MESSAGE, WM_APP_APPVER, NULL);
    // バージョンが対応していない場合
    if dwVersion <> APPLINK_VERSION then begin
        result := 102;
        writeln(output, Concat(STR_ERROR_102[dwLanguage], ' (code 102)'));
        exit;
    end;
    // スイッチによって処理を分ける
         if (sCmdLine = '/p')   or
            (sCmdLine = '-p')   then API_SendMessage(hWnd, WM_COMMAND, MENU_FILE_PLAY, NULL)
    else if (sCmdLine = '/r')   or
            (sCmdLine = '-r')   then API_SendMessage(hWnd, WM_COMMAND, MENU_FILE_RESTART, NULL)
    else if (sCmdLine = '/s')   or
            (sCmdLine = '-s')   then API_SendMessage(hWnd, WM_COMMAND, MENU_FILE_STOP, NULL)
    else if (sCmdLine = '/gd')  or
            (sCmdLine = '-gd')  then OutputValue(API_SendMessage(hWnd, WM_APP_MESSAGE, WM_APP_GET_DSP  or (dwParam1 and $FFFF), NULL))
    else if (sCmdLine = '/sd')  or
            (sCmdLine = '-sd')  then OutputValue(API_SendMessage(hWnd, WM_APP_MESSAGE, WM_APP_SET_DSP  or (dwParam1 and $FFFF), dwParam2))
    else if (sCmdLine = '/gp')  or
            (sCmdLine = '-gp')  then OutputValue(API_SendMessage(hWnd, WM_APP_MESSAGE, WM_APP_GET_PORT or (dwParam1 and $FFFF), NULL))
    else if (sCmdLine = '/sp')  or
            (sCmdLine = '-sp')  then OutputValue(API_SendMessage(hWnd, WM_APP_MESSAGE, WM_APP_SET_PORT or (dwParam1 and $FFFF), dwParam2))
    else if (sCmdLine = '/gr')  or
            (sCmdLine = '-gr')  then OutputValue(API_SendMessage(hWnd, WM_APP_MESSAGE, WM_APP_GET_RAM  or (dwParam1 and $FFFF), NULL))
    else if (sCmdLine = '/sr')  or
            (sCmdLine = '-sr')  then OutputValue(API_SendMessage(hWnd, WM_APP_MESSAGE, WM_APP_SET_RAM  or (dwParam1 and $FFFF), dwParam2))
    else if (sCmdLine = '/gw')  or
            (sCmdLine = '-gw')  then OutputValue(API_SendMessage(hWnd, WM_APP_MESSAGE, WM_APP_GET_WORK or (dwParam1 and $FFFF), NULL))
    else if (sCmdLine = '/sw')  or
            (sCmdLine = '-sw')  then OutputValue(API_SendMessage(hWnd, WM_APP_MESSAGE, WM_APP_SET_WORK or (dwParam1 and $FFFF), dwParam2))
    else if (sCmdLine = '/gc')  or
            (sCmdLine = '-gc')  then OutputValue(API_SendMessage(hWnd, WM_APP_MESSAGE, WM_APP_GET_CMP  or (dwParam1 and $FFFF), NULL))
    else if (sCmdLine = '/sc')  or
            (sCmdLine = '-sc')  then OutputValue(API_SendMessage(hWnd, WM_APP_MESSAGE, WM_APP_SET_CMP  or (dwParam1 and $FFFF), dwParam2))
    else if (sCmdLine = '/gs')  or
            (sCmdLine = '-gs')  then OutputValue(API_SendMessage(hWnd, WM_APP_MESSAGE, WM_APP_GET_SPC  or (dwParam1 and $FFFF), NULL))
    else if (sCmdLine = '/ss')  or
            (sCmdLine = '-ss')  then OutputValue(API_SendMessage(hWnd, WM_APP_MESSAGE, WM_APP_SET_SPC  or (dwParam1 and $FFFF), dwParam2))
    else if (sCmdLine = '/sh')  or
            (sCmdLine = '-sh')  then API_SendMessage(hWnd, WM_APP_MESSAGE, WM_APP_HALT, dwParam1)
    else if (sCmdLine = '/bp')  or
            (sCmdLine = '-bp')  then API_SendMessage(hWnd, WM_APP_MESSAGE, WM_APP_BP_SET or (dwParam1 and $FFFF), dwParam2)
    else if (sCmdLine = '/bpc') or
            (sCmdLine = '-bpc') then API_SendMessage(hWnd, WM_APP_MESSAGE, WM_APP_BP_CLEAR, NULL)
    else if (sCmdLine = '/bpn') or
            (sCmdLine = '-bpn') then API_SendMessage(hWnd, WM_APP_MESSAGE, WM_APP_NEXT_TICK, dwParam1)
    else if (sCmdLine = '/dc')  or
            (sCmdLine = '-dc')  then API_SendMessage(hWnd, WM_APP_MESSAGE, WM_APP_DSP_CHEAT or (dwParam1 and $FFFF), dwParam2)
    else if (sCmdLine = '/dcc') or
            (sCmdLine = '-dcc') then API_SendMessage(hWnd, WM_APP_MESSAGE, WM_APP_DSP_THRU, NULL)
    else if (sCmdLine = '/md')  or
            (sCmdLine = '-md')  then begin
        writeln(STR_DSP_MAP[dwLanguage]);
        dwParam1 := 0;
        dwParam2 := $7F;
        OutputMemoryMap(WM_APP_GET_DSP, 4);
    end else if (sCmdLine = '/mr') or
                (sCmdLine = '-mr') then begin
        writeln(STR_RAM_MAP[dwLanguage]);
        dwParam1 := dwParam1 and $FFF0;
        if not longbool(dwParam2) then dwParam2 := $100;
        Dec(dwParam2);
        OutputMemoryMap(WM_APP_GET_RAM, 1);
    end else if (sCmdLine = '/tp') or
                (sCmdLine = '-tp') then begin
        I := API_SendMessage(hWnd, WM_APP_MESSAGE, WM_APP_GET_PORT + (dwParam1 and $FF), NULL);
        API_SendMessage(hWnd, WM_APP_MESSAGE, WM_APP_SET_PORT + (dwParam1 and $FF), dwParam2);
        API_Sleep(100);
        API_SendMessage(hWnd, WM_APP_MESSAGE, WM_APP_SET_PORT + (dwParam1 and $FF), I);
    end else if (sCmdLine = '/cw') or
                (sCmdLine = '-cw') then begin
        result := OutputWave();
        exit;
    end else begin
        result := 109;
        if longbool(Length(sCmdLine)) then writeln(output, Concat(sCmdLine, ' ', STR_ERROR_109[dwLanguage], ' (code 109)'));
        ShowUsage();
        exit;
    end;
    // 正常終了
    result := 0;
end;


// *************************************************************************************************************************************************************
// エントリー ポイント
// *************************************************************************************************************************************************************

begin
{$WARNINGS OFF} // コンパイラ警告メッセージなし --- ここから
    ExitCode := longint(_WinMain(hInstance));
{$WARNINGS ON}  // コンパイラ警告メッセージなし --- ここまで
end.
