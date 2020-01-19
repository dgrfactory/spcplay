# SNES SPC700 Player + 改良版 SNESAPU.DLL

## 概要

SNES SPC700 Player と改良版 SNESAPU.DLL 一式のソースコードです。  
アプリの詳細については、[デグレファクトリーのサイト (日本語)](https://dgrfactory.jp/spcplay/index.html) をご覧ください。

## Overview

Source codes of SNES SPC700 Player and improved SNESAPU.DLL.  
If you want to see details of this software, please visit [release page (in English)](https://github.com/dgrfactory/spcplay/releases).

## How to build

### spcplay.exe

Frontend for using SNESAPU.DLL.  
Required software: dcc32 (Delphi6 UP2 RTL3)

```
rc.exe /l 0x411 /fo spcplay.res /d "NDEBUG" spcplay.rc
dcc32.exe spcplay.dpr
```

### snesapu.dll

SNES SPC700 emulator. (forks from [Alpha-II Productions](https://www.alpha-ii.com/))  
Required softwares: VC++ (VC++6 SP6), nasm (Netwide Assembler)

```
nasm.exe -D WIN32 -D STDCALL -O2 -w-macro-params -f win32 -o .\Release\SPC700.obj SPC700.asm
nasm.exe -D WIN32 -D STDCALL -O2 -w-macro-params -f win32 -o .\Release\DSP.obj DSP.asm
nasm.exe -D WIN32 -D STDCALL -O2 -w-macro-params -f win32 -o .\Release\APU.obj APU.asm
rc.exe /l 0x411 /fo .\Release\version.res /d "NDEBUG" version.rc
cl.exe @option\snesapu-cl.txt
link.exe @option\snesapu-link.txt
```

for 3rd-party players:
```
copy /y thirdparty\* .
  : (nasm, rc, cl)
link.exe @option\snesapu-3rd-link.txt
```

### spccmd.exe

Software that operates spcplay.exe on the command line.  
Required software: dcc32 (Delphi6 UP2 RTL3)

```
rc.exe /l 0x411 /fo spccmd.res /d "NDEBUG" spccmd.rc
dcc32.exe spccmd.dpr
```
