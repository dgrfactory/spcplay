# SNES SPC700 Player + 改良版 SNESAPU.DLL

## 概要

SNES SPC700 Player と改良版 SNESAPU.DLL 一式のソースコードです。  
アプリの詳細については、[デグレファクトリーのサイト](https://dgrfactory.jp/spcplay/index.html)をご覧ください。

## spcplay.exe

**SNES SPC700 Player:**  
スーパーファミコンの音楽ファイル (SPC) をパソコン上で再生するための SPC 専用プレイヤーです。  
Win32API を直接使用しているので、軽量・軽快に動作します。

コンパイルに必要なソフト： dcc32 (Delphi6 UP2 RTL3)

```
dcc32 spcplay.dpr
```

## snesapu.dll

**改良版SNESAPU.DLL:**  
再現性と音質に定評がある Alpha-II Productions 製の SNESAPU.DLL v2.0 をベースに、最新版 v3.0 の一部機能や独自拡張機能を取り込んでいます。

コンパイルに必要なソフト： VC++ (VC++6 SP6 で動作確認済), nasm (Netwide Assembler)

```
nasm.exe -D WIN32 -D STDCALL -O2 -w-macro-params -f win32 -o .\Release\SPC700.obj SPC700.asm
nasm.exe -D WIN32 -D STDCALL -O2 -w-macro-params -f win32 -o .\Release\DSP.obj DSP.asm
nasm.exe -D WIN32 -D STDCALL -O2 -w-macro-params -f win32 -o .\Release\APU.obj APU.asm
rc.exe /l 0x411 /fo"Release/version.res" /d "NDEBUG" version.rc
cl.exe @option\snesapu-cl.txt
link.exe @option\snesapu-link.txt
```

※他プレイヤー用をビルドする場合は、thirdparty ディレクトリの中身を本体にコピーして、snesapu-link.txt の代わりに snesapu-3rd-link.txt を使用。

## spccmd.exe

**SNES SPC700 Player 外部コマンド拡張ツール:**  
SNES SPC700 Player をコマンドラインで操作するアプリです。  
コマンドによる再生・停止操作、SPC700 や DSP のデバッグ、G.I.M.I.C 等の転送プログラムのシミュレーション等が行えます。

コンパイルに必要なソフト： dcc32 (Delphi6 UP2 RTL3)

```
dcc32 spccmd.dpr
```
