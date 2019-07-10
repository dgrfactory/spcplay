/***************************************************************************************************
* Program:    Super Nintendo Entertainment System(tm) Audio Processing Unit Emulator               *
* Platform:   Intel 80386                                                                          *
* Programmer: Anti Resonance (Alpha-II Productions), sunburst (degrade-factory)                    *
*                                                                                                  *
* "SNES" and "Super Nintendo Entertainment System" are trademarks of Nintendo Co., Limited and its *
* subsidiary companies.                                                                            *
*                                                                                                  *
* This program is free software; you can redistribute it and/or modify it under the terms of the   *
* GNU General Public License as published by the Free Software Foundation; either version 2 of     *
* the License, or (at your option) any later version.                                              *
*                                                                                                  *
* This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;        *
* without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.        *
* See the GNU General Public License for more details.                                             *
*                                                                                                  *
* You should have received a copy of the GNU General Public License along with this program;       *
* if not, write to the Free Software Foundation, Inc.                                              *
* 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.                                        *
*                                                                                                  *
*                                                 Copyright (C) 2001-2004 Alpha-II Productions     *
*                                                 Copyright (C) 2003-2015 degrade-factory          *
***************************************************************************************************/

// ----- degrade-factory code [2015/02/28] -----
#define WIN32_LEAN_AND_MEAN                                     //Leave out unnecessary grunt in windows.h
#include    <conio.h>
#include    <stdlib.h>
#include    <windows.h>
#include    <mmsystem.h>
#include    "Types.h"
#include    "SPC700.h"
#include    "DSP.h"
#include    "APU.h"
#pragma comment(linker, "/opt:nowin98")
#pragma comment(linker, "/merge:.rdata=.text")
#pragma comment(linker, "/section:.text,erw")
#pragma comment(linker, "/ignore:4078")
#pragma comment(linker, "/ignore:4089")

/* Some SPC registers */
#define SPC_PORT0           0xF4
#define SPC_PORT1           0xF5
#define SPC_PORT2           0xF6
#define SPC_PORT3           0xF7
#define SPC_TIMER0          0xFA
#define SPC_TIMER1          0xFB
#define SPC_TIMER2          0xFC
#define SPC_CONTROL         0xF1
#define SPC_REGADD          0xF2

/* some Dsp registers address and bits */
#define DSP_FLG             0x6C
#define DSP_FLG_RES         0x80
#define DSP_FLG_MUTE        0x40
#define DSP_FLG_ECEN        0x20
#define DSP_ESA             0x6D
#define DSP_EDL             0x7D
#define DSP_KON             0x4C

#define MLDR_SPC_TIMER0     0x01
#define MLDR_SPC_TIMER1     0x04
#define MLDR_SPC_TIMER2     0x07
#define MLDR_BOOTPTR        0x02

#define BOOT_OFFSET         0x1F
#define BOOT_SPC_CONTROL    BOOT_OFFSET + 0x01
#define BOOT_SPC_PORT0      BOOT_OFFSET + 0x04
#define BOOT_SPC_PORT1      BOOT_OFFSET + 0x09
#define BOOT_SPC_PORT2      BOOT_OFFSET + 0x0E
#define BOOT_SPC_PORT3      BOOT_OFFSET + 0x13
#define BOOT_DSP_FLG        BOOT_OFFSET + 0x1B
#define BOOT_DSP_KON        BOOT_OFFSET + 0x21
#define BOOT_SPC_REGADD     BOOT_OFFSET + 0x24
#define BOOT_SP             BOOT_OFFSET + 0x27
#define BOOT_A              BOOT_OFFSET + 0x2A
#define BOOT_Y              BOOT_OFFSET + 0x2C
#define BOOT_X              BOOT_OFFSET + 0x2E

#define OUTPUT_PIN          0x01
#define SCK_PIN             0x02
#define CART_PIN            0x40
#define RESET_PIN           0x80

#define _RD_PIN             0x08
#define WR_PIN              0x04
#define _ADDR1              0x02
#define _ADDR0              0x01

#define INPUT_PIN           0x10
#define RDY_PIN             0x20

#define OUTPUT_MODE         0x00
#define INPUT_MODE          0x20
#define ECR_OFFSET          0x402
#define CONTROL_PORT        0x002

static int BASE = 0;
static int port0 = 0;
static int control_pins = 0;
static int boot = 0;
static int transmit_type = 0;

static u8 _700Asc = 0;
static u8 _700Dir[2048];
static u32 _700DirSize = 0;

#define DATA        (int)(BASE + 0x000)
#define STATUS      (int)(BASE + 0x001)
#define CONTROL     (int)(BASE + 0x002)
#define ECR         (int)(BASE + 0x402)

#define SetPins(x, p)       x = (x | p)
#define ClrPins(x, p)       x = (x & (~p))
#define TogglePins(x, p)    x = (x ^ p)

typedef HANDLE (__stdcall *CreateFileP)(void*, DWORD, DWORD, LPSECURITY_ATTRIBUTES, DWORD, DWORD, HANDLE);
typedef BOOL (__stdcall *IsInpOutDriverOpenP)(void);
typedef u8 (__stdcall *DlPortReadPortUcharP)(u16);
typedef void (__stdcall *DlPortWritePortUcharP)(u16, u8);
typedef int (__stdcall *CallbackPortReadP)(int);
typedef void (__stdcall *CallbackPortWriteP)(int, int);

static HINSTANCE hInpOut32;
static IsInpOutDriverOpenP pIsInpOutDriverOpen;
static DlPortReadPortUcharP pDlPortReadPortUchar;
static DlPortWritePortUcharP pDlPortWritePortUchar;
static CallbackPortReadP pCallbackRead;
static CallbackPortWriteP pCallbackWrite;
static unsigned long dwS700ThreadID;
static HANDLE hS700ThreadHandle;
static u32 fActiveS700Thread = 0;

#define TRANSMIT_TYPE_LPT           0x01
#define TRANSMIT_TYPE_GIMIC         0x02
#define TRANSMIT_TYPE_CALLBACK      0x03

typedef struct TRANSMITSPCEX
{
    u32     cbSize;
    u32     transmitType;
    u32     bScript700;
} TRANSFERSPCEX;

typedef struct TRANSMITSPCEXLPT
{
    u32     cbSize;
    u32     transmitType;
    u32     bScript700;
    u32     dataPort;
} TRANSFERSPCEXLPT;

typedef struct TRANSMITSPCEXCALLBACK
{
    u32     cbSize;
    u32     transmitType;
    u32     bScript700;
    CallbackPortReadP   pCallbackRead;
    CallbackPortWriteP  pCallbackWrite;
} TRANSFERSPCEXCALLBACK;
// ----- degrade-factory code [END] -----


//**************************************************************************************************
// Variables

////////////////////////////////////////////////////////////////////////////////////////////////////
// Functions

// ----- degrade-factory code [2016/08/20] -----
#ifdef  __cplusplus
extern  "C" {
#endif


//**************************************************************************************************
DWORD MakeScript700FileNameA(void *lp700File, DWORD dwType, DWORD posYen, DWORD posDot) {
    switch (dwType) {
    case 0: // (FILENAME).700
        if (posDot > 256) return -1;
        MoveMemory((void*)((u32)lp700File + posDot + 1), (LPCTSTR)"700\0", 4);
        break;

    case 1: // (FILENAME).7SE
        if (posDot > 256) return -1;
        MoveMemory((void*)((u32)lp700File + posDot + 1), (LPCTSTR)"7se\0", 4);
        break;

    case 2: // 65816.700
        if (posYen > 250) return -1;
        MoveMemory((void*)((u32)lp700File + posYen + 1), (LPCTSTR)"65816.700\0", 10);
        break;

    case 3: // 65816.7SE
        if (posYen > 250) return -1;
        MoveMemory((void*)((u32)lp700File + posYen + 1), (LPCTSTR)"65816.7se\0", 10);
        break;

    default: // Exit Loop
        return 0;
    }

    // try load file
    return 1;
}

DWORD MakeScript700FileNameW(void *lp700File, DWORD dwType, DWORD posYen, DWORD posDot) {
    switch (dwType) {
    case 0: // (FILENAME).700
        if (posDot > 2000) return -1;
        MoveMemory((void*)((u32)lp700File + posDot + 2), (LPCWSTR)L"700\0", 8);
        break;

    case 1: // (FILENAME).7SE
        if (posDot > 2000) return -1;
        MoveMemory((void*)((u32)lp700File + posDot + 2), (LPCWSTR)L"7se\0", 8);
        break;

    case 2: // 65816.700
        if (posYen > 2000) return -1;
        MoveMemory((void*)((u32)lp700File + posYen + 2), (LPCWSTR)L"65816.700\0", 20);
        break;

    case 3: // 65816.7SE
        if (posYen > 2000) return -1;
        MoveMemory((void*)((u32)lp700File + posYen + 2), (LPCWSTR)L"65816.7se\0", 20);
        break;

    default: // Exit Loop
        return 0;
    }

    // try load file
    return 1;
}


//**************************************************************************************************
BOOL LoadScript700(CreateFileP func, void *lp700File, u32 addr) {
    // open Script700 file
    HANDLE hFile = func(lp700File, GENERIC_READ, FILE_SHARE_READ, 0, OPEN_EXISTING, 0, 0);
    if (hFile == INVALID_HANDLE_VALUE) return FALSE;

    // get file size
    DWORD dwSize = GetFileSize(hFile, NULL);
    if (dwSize == 0 || dwSize > 16777216) {
        CloseHandle(hFile);
        return FALSE;
    }

    // alloc memory
    void *lpBuffer = malloc(dwSize + 1);
    if (!lpBuffer) {
        CloseHandle(hFile);
        return FALSE;
    }

    // read Script700 file
    DWORD dwLoad;
    ZeroMemory(lpBuffer, dwSize + 1);
    ReadFile(hFile, lpBuffer, dwSize, &dwLoad, NULL);
    CloseHandle(hFile);

    // set Script700
    if (addr == -1) SetScript700(lpBuffer);
    else SetScript700Data(addr, lpBuffer, dwSize);

    // free memory
    free(lpBuffer);

    // exit
    return TRUE;
}


//**************************************************************************************************
void IncludeScript700File(u32 addr, u32 value, void *lpData) {
    // get pointer of CreateFile function
    HINSTANCE hModule = LoadLibrary("kernel32.dll");
    if (!hModule) return;

    CreateFileP func = (CreateFileP)GetProcAddress(hModule, _700Asc ? "CreateFileA" : "CreateFileW");
    if (!func) {
        FreeLibrary(hModule);
        return;
    }

    // copy buffer
    void *lp700File = malloc(2048);
    MoveMemory(lp700File, &_700Dir, 2048);

    if (_700Asc) {
        // get buffer size
        if (_700DirSize + value > 2048) {
            FreeLibrary(hModule);
            free(lp700File);
            return;
        }

        // load Script700 file
        void *lpFile = (void*)((u32)lp700File + _700DirSize);
        MoveMemory(lpFile, lpData, value);
        LoadScript700(func, lp700File, addr);
    } else {
        // get buffer size
        void *lpFile = (void*)((u32)lp700File + _700DirSize);
        u32 result = MultiByteToWideChar(CP_ACP, NULL, (LPCSTR)lpData, -1, (LPWSTR)lpFile, 2048 - _700DirSize);
        if (!result) {
            FreeLibrary(hModule);
            free(lp700File);
            return;
        }

        // load Script700 file
        LoadScript700(func, lp700File, addr);
    }

    FreeLibrary(hModule);
    free(lp700File);
}

u32 CustomSNESAPUCallback(u32 effect, u32 addr, u32 value, void *lpData) {
    switch (effect) {
    case CBE_INCS700:
        IncludeScript700File(-1, value, lpData);
        break;
    case CBE_INCDATA:
        IncludeScript700File(addr, value, lpData);
        break;
    }

    return value;
}

//**************************************************************************************************
int try700(void *lpFile) {
    if (lpFile == NULL) {
        // reset Script700
        SetScript700(NULL);
        return 0;
    }

    // get pointer of CreateFile function
    HINSTANCE hModule = LoadLibrary("kernel32.dll");
    if (!hModule) return -1;

    u8 c = 0, c1 = 0, c2 = 0, asc = 0;
    c = *(u8*)((u32)lpFile);
    if (!c) return -2;
    asc = *(u8*)((u32)lpFile + 1);
    _700Asc = asc;

    CreateFileP func = (CreateFileP)GetProcAddress(hModule, asc ? "CreateFileA" : "CreateFileW");
    if (!func) {
        FreeLibrary(hModule);
        return -3;
    }

    // crear memory
    void *lp700File = malloc(2048);
    if (!lp700File) {
        FreeLibrary(hModule);
        return -4;
    }

    DWORD i, posYen = 0, posDot = 0;
    ZeroMemory(lp700File, 2048);

    // search backslash and dot char
    if (asc) {
        for (i = 0; i < 1024; i++) {
            c2 = c1;
            c1 = c;
            c = *(u8*)((u32)lpFile + i);
            if (c == 0x5C) {
                if ( ((c2 >= 0x81 && c2 <= 0x9F) || (c2 >= 0xE0 && c2 <= 0xFC)) && ((c1 >= 0x40 && c1 <= 0x7E) || (c1 >= 0x80 && c1 <= 0xFC))) posYen = i;
                if (!((c1 >= 0x81 && c1 <= 0x9F) || (c1 >= 0xE0 && c1 <= 0xFC))) posYen = i;
            }
            if (c == 0x2E) posDot = i;
            if (!c) break;
        }
    } else {
        for (i = 0; i < 2048; i += 2) {
            c = *(u8*)((u32)lpFile + i);
            if (!c) break;
            c1 = *(u8*)((u32)lpFile + i + 1);
            if (c1) continue;
            if (c == 0x5C) posYen = i;
            if (c == 0x2E) posDot = i;
        }
    }

    // copy SPC file path
    if (asc || i < 8) {
        MoveMemory(lp700File, lpFile, i);
    } else {
        DWORD d1 = *(u32*)((u32)lpFile);
        DWORD d2 = *(u32*)((u32)lpFile + 4);
        if (d1 == 0x005C005C && d2 == 0x005C003F) {
            MoveMemory(lp700File, lpFile, i);
        } else {
            d1 = 0x005C005C;
            d2 = 0x005C003F;
            MoveMemory(lp700File, &d1, 4);
            MoveMemory((void*)((u32)lp700File + 4), &d2, 4);
            MoveMemory((void*)((u32)lp700File + 8), lpFile, i);
            posYen += 8;
            posDot += 8;
        }
    }

    // copy current directory
    _700DirSize = posYen + (asc ? 1 : 2);
    ZeroMemory(&_700Dir, 2048);
    MoveMemory(&_700Dir, lp700File, _700DirSize);

    // set original callback
    CBFUNC backup = SNESAPUCallback(&CustomSNESAPUCallback, CBE_INCS700 | CBE_INCDATA);

    // load Script700 file loop
    for (i = 0; i < 255; i++) {
        // get Script700 file path
        u32 ret = asc
            ? MakeScript700FileNameA(lp700File, i, posYen, posDot)
            : MakeScript700FileNameW(lp700File, i, posYen, posDot);
        if (!ret)   break;      // ret == 0
        if (!ret++) continue;   // ret == -1

        // load Script700 file
        if (LoadScript700(func, lp700File, -1)) break;
    }

    // restore callback
    SNESAPUCallback(backup, NULL);

    // free memory
    free(lp700File);
    FreeLibrary(hModule);
    return (posYen << 16) | (asc << 8) | i;
}


//**************************************************************************************************
void InitWork_700() {
    // reset Script700
    SetScript700(NULL);
}


//**************************************************************************************************
void io_outp(int port, int data) {
    if (pDlPortWritePortUchar) {
        pDlPortWritePortUchar(port, data);
    } else {
        _outp(port, data);
    }
}

int io_inp(int port) {
    if (pDlPortReadPortUchar) {
        return pDlPortReadPortUchar(port);
    } else {
        return _inp(port);
    }
}

void apu_write(int address, int data) {
    if (pCallbackWrite) {
        pCallbackWrite(address, data);
    } else {
        ClrPins(control_pins, INPUT_MODE);
        io_outp(CONTROL, control_pins);

        SetPins(control_pins, _ADDR0 + _ADDR1);
        ClrPins(control_pins, address);
        ClrPins(control_pins, WR_PIN);
        ClrPins(control_pins, _RD_PIN);
        io_outp(CONTROL, control_pins);

        io_outp(DATA, data);

        SetPins(control_pins, WR_PIN);
        io_outp(CONTROL, control_pins);
    }
}

int apu_read(int address) {
    if (pCallbackRead) {
        return pCallbackRead(address);
    } else {
        int data;

        SetPins(control_pins, INPUT_MODE);

        SetPins(control_pins, _ADDR0 + _ADDR1);
        ClrPins(control_pins, address);
        SetPins(control_pins, WR_PIN);
        SetPins(control_pins, _RD_PIN);
        io_outp(CONTROL, control_pins);

        data = io_inp(DATA);

        ClrPins(control_pins, _RD_PIN);
        io_outp(CONTROL, control_pins);

        return data;
    }
}

void apu_reset(void) {
    ClrPins(control_pins,WR_PIN);       // once the OR gate is in place
    SetPins(control_pins,_RD_PIN);      // pulling both /RD and /WR low
    io_outp(CONTROL, control_pins);     // will reset the APU, since
    Sleep(50);                          // /RESET will be tied to the

    SetPins(control_pins,WR_PIN);       // output of the OR gate.
    ClrPins(control_pins,_RD_PIN);
    io_outp(CONTROL, control_pins);
    Sleep(50);
}

int apu_waitInport(int port, int data, int timeout_ms) {
    unsigned int ms = timeGetTime() + timeout_ms;
    while(apu_read(port) != data) if (timeGetTime() >= ms) return 0;
    return 1;
}

int apu_initTransfer(int address) {
    if (!apu_waitInport(0, 0xaa, 500)) return 0;
    if (!apu_waitInport(1, 0xbb, 500)) return 0;

    // write any value other than 0 to 2141
    apu_write(1, 1);

    // write the destination address to poirt $2142 and $2143, with the
    // low byte written at $2142
    apu_write(2, address & 0xff); // low
    apu_write(3, (address & 0xff00) >> 8); // high So our code will go at $0002

    // write $CC to port $2140
    apu_write(0, 0xcc);
    if (!apu_waitInport(0, 0xcc, 500)) return 0;
    port0 = 0;

    return 1;
}

int apu_newTransfer(int address) {
    int i;
    apu_write(1, 1);
    apu_write(3, (address & 0xff00) >> 8);
    apu_write(2, (address & 0xff));

    i = apu_read(0);
    i += 2; i &= 0xff;
    if (!i) i += 2; // if it's 0, increase it again

    apu_write(0, i);
    if (!apu_waitInport(0, i, 500)) return 0;
    port0 = 0;

    return 1;
}

int apu_endTransfer(int start_address) {
    int i;
    apu_write(1, 0);
    apu_write(3, (start_address & 0xff00) >> 8);
    apu_write(2, (start_address & 0xff));

    i = apu_read(0);
    i += 2; i &= 0xff;
    if (!i) i += 2; // if it's 0, increase it again

    apu_write(0, i);

    return 1;
}

int BidirAvailable(void) {
    int bidir = 0;

    // try to change to input mode
    io_outp(CONTROL, INPUT_MODE);

    // see if it worked
    io_outp(DATA, 0x55);
    if (io_inp(DATA) != 0x55) bidir = 1;

    // make sure we didn't accidentally choose the state the port was in
    io_outp(DATA, 0xaa);
    if (io_inp(DATA) != 0xaa) bidir = 1;

    // return port to output mode and data = $00
    io_outp(CONTROL, OUTPUT_MODE);
    control_pins = OUTPUT_MODE;
    io_outp(DATA, 0);

    return bidir;
}

void begin_config_mode(int chip) {
    unsigned char init_code;

    switch(chip) {
        case 666:  init_code = 0x44; break;
        case 665:  init_code = 0x55; break;
        default:   return;
    }

    io_outp(0x3f0, init_code);
    io_outp(0x3f0, init_code);
}

void end_config_mode(void) {
    // Note that there is a typo in Parallel Port Complete, page 214
    // it says write to 0x3f1 instead of 0x3f0
    io_outp(0x3f0, 0xaa);
}

void begin_EPP(int port_addr, int chip) {
    // port_addr = 0x278 or 0x378, chip = '666' or '665'
    begin_config_mode(chip);

    // control word for configuring
    // CR   Bits 1,  Port address   00 -> disabled
    //                              01 -> 0x3bc
    //                              10 -> 0x378
    //                              11 -> 0x278 (default)
    //       Bit 2   Port power     1  -> power supplied (default)
    //                              0  -> low power mode
    //       Bit 3   Mode           1  -> SPP (default)
    //                              0  -> Extended modes allowed (CR4-bits 0,1)
    //       Bit 4   IRQ polarity   1  -> active high, inactive low (default)
    //                              0  -> active low, inactive high-Z
    //                                      (always true in ECP,EPP)

    // set CR1
    io_outp(0x3f0, 1);
    if (port_addr == 0x378) io_outp(0x3f1, 0x96); else io_outp(0x3f1, 0x97);

    // CR4  Bits 0,1  Ext modes     10 -> SPP, PS/2 (default)
    //                              01 -> SPP and EPP
    //                              10 -> ECP
    //                              11 -> ECP and EPP
    //         Bit 6  EPP type      0  -> EPP 1.9 (default)
    //                              1  -> EPP 1.7

    io_outp(0x3f0, 4);   // use CR4
    io_outp(0x3f1, 3);   // use EPP

    // CRA  Bits 0-3  ECP FIFO thres -> threshold for ECP service requests
    //                                  default 0

    /*      Use if you need
      io_outp( 0x3f0, 0xa );  // use CRA
      io_outp( 0x3f1, 8 );    // threshold for ECP requests
    */

    // 0x34 == <0011 0100>
    // PS/2 (byte, bidirectional) type (bits 7-5) == 001,
    //      no interrupts at nError (bit 4) == 1,
    //      disable DMA (bit 3) == 0,
    // disable DMA and service interrupts (bit 2) == 1
    // bits 1,0 read only, so don't care
    io_outp((int)(port_addr + ECR_OFFSET), 0x34);

    /* pulse - nInit (bit 2) low */

    io_outp((int)(port_addr + CONTROL_PORT), 0x00);
    end_config_mode();

    // ECP emulating EPP 0x80 == <1000 0000>
    //      For EPP mode, set ECR of ECP to mode (bits 7-5) == 100
    //      Falling edge of nError generates interrupt (bit 4) == 0,
    //      disable DMA (bit 3) == 0,
    // enable service interrupts (bit 2) == 0
    // bits 1,0 read only, so don't care

    // set ECR to EPP mode
    io_outp((int)(port_addr + ECR_OFFSET), 0x80);

    // pulse - nInit (bit 2) high; reset the peripheral,
    // min pulse width 50 micro-sec
    io_outp((int)(port_addr + CONTROL_PORT), 0x04);
}

int EnableBidir(void) {
    // Some computers/ParallelPorts need to have something enabled
    // before they can switch to and from input/output mode.
    // This will try a bunch of ways to enable bidir.

    if (BidirAvailable()) return 1;

    // try using ECP first
    //
    // 0x34 =
    //   bit 7:5 = 001, PS2/ParallelPort mode
    //   bit 4 = 1, Disables the interrupt generated on
    //              the asserting edge of nFault.
    //   bit 3 = 0, Disables DMA unconditionally.
    //   bit 2 = 1, Disables DMA and all of the service interrupts.
    //   bit 1,0 are ReadOnly

    // trying to get computer to allow bidir via ECP...
    io_outp(ECR, 0x34);
    if (BidirAvailable()) return 1;

    // trying to get computer to allow bidir via EPP... chipset 666
    begin_EPP(DATA, 666);
    if (BidirAvailable()) return 1;

    // trying to get computer to allow bidir via EPP... chipset 665
    begin_EPP(DATA, 665);
    if (BidirAvailable()) return 1;

    return 0;
}

void __stdcall WritePort(int address, int data) {
    if (boot) {
        MoveMemory((void *)(pAPURAM + (address & 3) + 0xF4), &data, 1);
    } else if (address == -1) {
        // GIMIC: block transfer start
        if (transmit_type == TRANSMIT_TYPE_GIMIC) apu_write(0xff, 0xfe);

        // write ports
        apu_write(1, (data >> 8) & 0xff);
        apu_write(2, (data >> 16) & 0xff);
        apu_write(3, (data >> 24) & 0xff);
        apu_write(0, data & 0xff);

        // GIMIC: block transfer end
        if (transmit_type == TRANSMIT_TYPE_GIMIC) apu_write(0xff, 0xff);
    } else {
        apu_write(address & 3, data);
    }
}

int __stdcall ReadPort(int address) {
    if (boot) {
        return outPort[address & 3];
    } else if (address == -1) {
        if (transmit_type == TRANSMIT_TYPE_GIMIC) return outPort[0]; return apu_read(0) & 0xff;
    } else {
        return apu_read(address & 3) & 0xff;
    }
}

void __stdcall ResetTransmit() {
    apu_reset();
    int i = NULL;
    MoveMemory((void *)(pAPURAM + 0x10022), &i, 4);
}

void CloseIOPort() {
    // finalize InpOut32
    if (hInpOut32) {
        FreeLibrary(hInpOut32);
        hInpOut32 = NULL;
    }
}

int OpenIOPort() {
    // initialize
    hInpOut32 = NULL;
    pDlPortReadPortUchar = NULL;
    pDlPortWritePortUchar = NULL;

    // initialize GiveIO
    HANDLE hGiveIo = CreateFile("\\\\.\\giveio", GENERIC_READ + GENERIC_WRITE, 0, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);
    if (hGiveIo != INVALID_HANDLE_VALUE) {
        CloseHandle(hGiveIo);
        return 0;
    }

    // initialize InpOut32
    if (!hInpOut32) {
        hInpOut32 = LoadLibrary("inpout32.dll");
    }
    if (hInpOut32) {
        pIsInpOutDriverOpen = (IsInpOutDriverOpenP)GetProcAddress(hInpOut32, "IsInpOutDriverOpen");
        if (pIsInpOutDriverOpen()) {
            pDlPortReadPortUchar = (DlPortReadPortUcharP)GetProcAddress(hInpOut32, "DlPortReadPortUchar");
            pDlPortWritePortUchar = (DlPortWritePortUcharP)GetProcAddress(hInpOut32, "DlPortWritePortUchar");
            return 0;
        }
    }

    // failure
    return -1;
}

int WriteIO(int address, int data) {
    int result = OpenIOPort();
    if (result) return result;

    io_outp(address, data);

    return 0;
}

int StopTransmitSPC() {
    if (fActiveS700Thread) {
        fActiveS700Thread = 2;
        while (fActiveS700Thread) Sleep(1);
        CloseHandle(hS700ThreadHandle);
    }

    return 0;
}

int LocalTransmitSPC(int type) {
    transmit_type = type;
    if (type == TRANSMIT_TYPE_LPT) {
        // initialize paralell port
        if (!EnableBidir()) return -2; // port is not ECP,EPP
    }

    StopTransmitSPC();

    unsigned char memloader[] = {

        // ---- RESET ----

        0x8f, 0x00, 0xfa,   // MOV $fa, #$00    ; $0001: Timer0
        0x8f, 0x00, 0xfb,   // MOV $fb, #$00    ; $0004: Timer1
        0x8f, 0x00, 0xfc,   // MOV $fc, #$00    ; $0007: Timer2

        0xe4, 0xfd,         // MOV A, $fd       ; clear timer counters
        0xe4, 0xfe,         // MOV A, $fe       ;
        0xe4, 0xff,         // MOV A, $ff       ;

        // ---- DSP LOADER ----

        0xcd, 0x00,         // MOV X, #$0       ; reset
        0x8d, 0x00,         // MOV Y, #$0       ;

        0xd8, 0xf4,         // MOV $f4, X       ; LDSP_A: Port0 = written flag
        0x3d,               // INC X            ; X++
        0x3e, 0xf4,         // CMP X, $f4       ; LDSP_B: Port0 = X?
        0xd0, 0xfc,         // BNE LDSP_B:      ;

        0xcb, 0xf2,         // MOV $f2, Y       ; byte 1
        0xfa, 0xf5, 0xf3,   // MOV $f3, $f5     ; TODO: NOT use MOVW, dsp register will be broken
        0xfc,               // INC Y            ;

        0xcb, 0xf2,         // MOV $f2, Y       ; byte 2
        0xfa, 0xf6, 0xf3,   // MOV $f3, $f6     ;
        0xfc,               // INC Y            ;

        0x30, 0x08,         // BMI EXIT:        ; Y = $80?

        0xcb, 0xf2,         // MOV $f2, Y       ; byte 3
        0xfa, 0xf7, 0xf3,   // MOV $f3, $f7     ;
        0xfc,               // INC Y            ;

        0x2f, 0xe3,         // BRA LDSP_A:      ;

        // ---- RAM LOADER ($100-$ffff) ----

        0xab, 0x05,         // INC db+5         ; reset
        0x8d, 0x00,         // MOV Y, #$0       ;

        0xd8, 0xf4,         // MOV $f4, X       ; LRAM_A: Port0 = written flag
        0x3d,               // INC X            ; X++
        0x3e, 0xf4,         // CMP X, $f4       ; LRAM_B: Port0 = X?
        0xd0, 0xfc,         // BNE LRAM_B:      ;

        0xe4, 0xf5,         // MOV A, $f5       ; byte 1
        0xd7, 0x04,         // MOV [dp+4]+Y, A  ;
        0x3a, 0x04,         // INCW dp+4        ;

        0xe4, 0xf6,         // MOV A, $f6       ; byte 2
        0xd7, 0x04,         // MOV [dp+4]+Y, A  ;
        0x3a, 0x04,         // INCW dp+4        ;

        0xe4, 0xf7,         // MOV A, $f7       ; byte 3
        0xd7, 0x04,         // MOV [dp+4]+Y, A  ;
        0x3a, 0x04,         // INCW dp+4        ;

        0xd0, 0xe5,         // BNE LRAM_A:      ;

        // ---- EXIT ----

        0x8d, 0x00,         // MOV Y, #$0       ;
        0x5f, 0x00, 0x00    // JMP [bootcode]   ; -$0002
    };

    unsigned char bootcode[] = {

        // ---- RAM LOADER ($00-$ef) ----

        0xd8, 0xf4,         // MOV $f4, X       ; LRAM_A: Port0 = written flag
        0x3d,               // INC X            ; X++
        0x3e, 0xf4,         // CMP X, $f4       ; LRAM_B: Port0 = X?
        0xd0, 0xfc,         // BNE LRAM_B:      ;

        0xe4, 0xf5,         // MOV A, $f5       ; byte 1
        0xd6, 0x00, 0x00,   // MOV [Y], A       ;
        0xfc,               // INC Y            ;

        0xe4, 0xf6,         // MOV A, $f6       ; byte 2
        0xd6, 0x00, 0x00,   // MOV [Y], A       ;
        0xfc,               // INC Y            ;

        0xe4, 0xf7,         // MOV A, $f7       ; byte 3
        0xd6, 0x00, 0x00,   // MOV [Y], A       ;
        0xfc,               // INC Y            ;

        0xad, 0xf0,         // CMP Y, #$f0      ; Y = $f0?
        0xd0, 0xe3,         // BNE LRAM_A:      ;

        0xd8, 0xf4,         // MOV $f4, X       ; Port0 = written flag

        // ---- COPY REGISTERS ----

        0x8f, 0x00, 0xf1,   // MOV $f1, #$00    ; $0001: SPC Control register

        0x78, 0x00, 0xf4,   // CMP $f4, #$0     ; LPORT0: $0004: Port0
        0xd0, 0xfb,         // BNE LPORT0:      ;
        0x78, 0x00, 0xf5,   // CMP $f5, #$0     ; LPORT1: $0009: Port1
        0xd0, 0xfb,         // BNE LPORT1:      ;
        0x78, 0x00, 0xf6,   // CMP $f6, #$0     ; LPORT2: $000e: Port2
        0xd0, 0xfb,         // BNE LPORT2:      ;
        0x78, 0x00, 0xf7,   // CMP $f7, #$0     ; LPORT3: $0013: Port3
        0xd0, 0xfb,         // BNE LPORT3:      ;

        0x8f, 0x6c, 0xf2,   // MOV $f2, #$6c    ; point to flg register
        0x8f, 0x00, 0xf3,   // MOV $f3, #$0     ; $001b: DSP FLG register
        0x8f, 0x4c, 0xf2,   // MOV $f2, #$4c    ; point to kon register
        0x8f, 0x00, 0xf3,   // MOV $f3, #$0     ; $0021: DSP KON register
        0x8f, 0x00, 0xf2,   // MOV $f2, #$0     ; $0024: SPC dsp reg addr.
        0xcd, 0x00,         // MOV X, #$0       ; $0027: SPC stack pointer
        0xbd,               // MOV SP, X        ;
        0xe8, 0x00,         // MOV A, #$0       ; $002a: SPC A register
        0x8d, 0x00,         // MOV Y, #$0       ; $002c: SPC Y register
        0xcd, 0x00,         // MOV X, #$0       ; $002e: SPC X register

        0x7f                // RETI             ;
    };

    int i = 0, j = 0, count = 0;
    int echosize1, echoregion1, echomax1, echosize2, echoregion2, echomax2, bootptr;
    unsigned short spc_pc;
    unsigned char spc_pcl, spc_pch, spc_a, spc_x, spc_y, spc_sw, spc_sp;
    unsigned char spcdata[65536], spcdata2[65536], spcxram[64], dspdata[128], dspdata1[128], dspdata2[128], buf[65536];
    boot = 0;

    // ************************************************************************************
    //   Initialize Section
    // ************************************************************************************

    // copy pointers of callback function
    i = (int)&WritePort;
    MoveMemory((void *)(pAPURAM + 0x10014), &i, 4);
    i = (int)&ReadPort;
    MoveMemory((void *)(pAPURAM + 0x10018), &i, 4);
    i = (int)&ResetTransmit;
    MoveMemory((void *)(pAPURAM + 0x10022), &i, 4);

    // copy spc data from SNESAPU library
    MoveMemory(&spcdata, (void *)pAPURAM, 65536);
    MoveMemory(&spcdata2, &spcdata, 65536);
    MoveMemory(&spcxram, &extraRAM, 64);
    MoveMemory(&dspdata, &dsp, 128);
    MoveMemory(&dspdata1, &dspdata, 128);
    GetSPCRegs(&spc_pc, &spc_a, &spc_y, &spc_x, &spc_sw, &spc_sp);
    spc_pcl = spc_pc & 0xff;
    spc_pch = (spc_pc >> 8) & 0xff;

    // save a bunch of registers to be restored later by bootcode
    bootcode[BOOT_SPC_PORT0] = spcdata[SPC_PORT0];
    bootcode[BOOT_SPC_PORT1] = spcdata[SPC_PORT1];
    bootcode[BOOT_SPC_PORT2] = spcdata[SPC_PORT2];
    bootcode[BOOT_SPC_PORT3] = spcdata[SPC_PORT3];
    bootcode[BOOT_DSP_FLG] = dspdata[DSP_FLG];
    bootcode[BOOT_DSP_KON] = dspdata[DSP_KON];
    bootcode[BOOT_SPC_REGADD] = spcdata[SPC_REGADD];
    bootcode[BOOT_A] = spc_a;
    bootcode[BOOT_Y] = spc_y;
    bootcode[BOOT_X] = spc_x;
    bootcode[BOOT_SPC_CONTROL] = spcdata[SPC_CONTROL] & 0x0f; // timer register only

    // save timer registers by memloader
    memloader[MLDR_SPC_TIMER0] = spcdata[SPC_TIMER0];
    memloader[MLDR_SPC_TIMER1] = spcdata[SPC_TIMER1];
    memloader[MLDR_SPC_TIMER2] = spcdata[SPC_TIMER2];

    // push program counter and status ward on stack
    spcdata[0x100 + ((spc_sp - 0) & 0xff)] = spc_pch;
    spcdata[0x100 + ((spc_sp - 1) & 0xff)] = spc_pcl;
    spcdata[0x100 + ((spc_sp - 2) & 0xff)] = spc_sw;
    bootcode[BOOT_SP] = (spc_sp - 3) & 0xff; // save new stack pointer

    // mute all voices
    dspdata[DSP_FLG] = DSP_FLG_MUTE | DSP_FLG_ECEN;
    dspdata[DSP_KON] = 0x00; // voice 0-7 off

    // echo memory
    if (dspdata1[DSP_FLG] & DSP_FLG_ECEN) {
        echoregion1 = 0;
        echosize1 = 0;
        echomax1 = 0;
    } else {
        echoregion1 = dspdata1[DSP_ESA] * 256;
        echosize1 = dspdata1[DSP_EDL] * 2048;
        if (echosize1 == 0) echosize1 = 4;
        echomax1 = echoregion1 + echosize1;
        for (i = echoregion1; i < echomax1; i++) spcdata[i & 0xffff] = 0x01;
    }

    // emulate 1sec
    boot = 1;
    for (i = 0; i < 64000; i++) EmuAPU(&buf[0], 384, 0);
    boot = 0;
    MoveMemory(&dspdata2, &dsp, 128);

    // echo memory
    if (dspdata2[DSP_FLG] & DSP_FLG_ECEN) {
        echoregion2 = 0;
        echosize2 = 0;
        echomax2 = 0;
    } else {
        echoregion2 = dspdata2[DSP_ESA] * 256;
        echosize2 = dspdata2[DSP_EDL] * 2048;
        if (echosize2 == 0) echosize2 = 4;
        echomax2 = echoregion2 + echosize2;
        for (i = echoregion2; i < echomax2; i++) spcdata[i & 0xffff] = 0x01;
    }

    // redo emulation
    ResetAPU(-1);
    MoveMemory((void *)pAPURAM, &spcdata2, 65536);
    MoveMemory(&extraRAM, &spcxram, 64);
    MoveMemory(&dsp, &dspdata1, 128);
    FixAPU(spc_pc, spc_a, spc_y, spc_x, spc_sw, spc_sp);

    // try find a place to install bootcode (step 1)
    for (bootptr = 0xffbf; bootptr >= 0x100; bootptr--) {
        if (spcdata[bootptr] == 0x00) count++; else count = 0;
        if (count == sizeof(bootcode)) break;
    }

    // try find a place to install bootcode (step 2)
    if (count != sizeof(bootcode)) {
        count = 0;
        for (bootptr = 0xffbf; bootptr >= 0x100; bootptr--) {
            if (spcdata[bootptr] == 0x00 || spcdata[bootptr] == 0xff) count++; else count = 0;
            if (count == sizeof(bootcode)) break;
        }
    }

    // try find a place to install bootcode (step 3)
    for (i = echoregion1; i < echomax1; i++) spcdata[i & 0xffff] = 0x00;
    for (i = echoregion2; i < echomax2; i++) spcdata[i & 0xffff] = 0x00;
    if (count != sizeof(bootcode)) {
        count = 0;
        for (bootptr = 0xffbf; bootptr >= 0x100; bootptr--) {
            if (spcdata[bootptr] == 0x00 || spcdata[bootptr] == 0xff) count++; else count = 0;
            if (count == sizeof(bootcode)) break;
        }
    }
    if (count != sizeof(bootcode)) return -3; // cannot find empty memory for install bootcode

    // copy bootcode
    for (i = bootptr; i <= bootptr + count - 1; i++) {
        spcdata[i & 0xffff] = bootcode[i - bootptr];
    }

    // set pointer of bootcode
    MoveMemory(&memloader[sizeof(memloader) - MLDR_BOOTPTR], &bootptr, 2);

    // ************************************************************************************
    //   SHVC-SOUND transmit section
    // ************************************************************************************

    // reset SHVC-SOUND unit
    if (type == TRANSMIT_TYPE_LPT) {
        apu_reset();
    }

    // initialize IPL
    if (!apu_initTransfer(0x0006)) return 10; // timeout 10

    // for GIMIC
    if (type == TRANSMIT_TYPE_GIMIC) {
        apu_write(0xff, 0x01); // double speed transfer start (GMC-SPC2)
        apu_write(0xff, 0xfe); // block transfer start
    }

    // upload memloader
    for (i = 0; i < sizeof(memloader); i++) {
        apu_write(1, memloader[i]);
        if (type == TRANSMIT_TYPE_GIMIC) {
            apu_write(2, 0x00);
            apu_write(3, 0x00);
        }
        apu_write(0, port0);
        if (type != TRANSMIT_TYPE_GIMIC && !apu_waitInport(0, port0, 500)) return 10; // timeout 10
        if (++port0 >= 256) port0 = 0;
    }

    // for GIMIC
    if (type == TRANSMIT_TYPE_GIMIC) {
        apu_write(0xff, 0xff); // block transfer end
    }

    // finalize IPL
    if (!apu_endTransfer(0x0006)) return 11; // timeout 11
    if (!apu_waitInport(0, 0x00, 500)) return 12; // timeout 12
    j = 0x01;

    // for GIMIC
    if (type == TRANSMIT_TYPE_GIMIC) {
        apu_write(0xff, 0xfe); // block transfer start
    }

    // upload DSP registers
    for (i = 0x00; i < 0x81; i += 3, j = (j + 1) & 0xFF) {
        apu_write(1, dspdata[i]);
        apu_write(2, dspdata[i + 1]);
        if (i < 0x7e) apu_write(3, dspdata[i + 2]);
        else if (type == TRANSMIT_TYPE_GIMIC) apu_write(3, 0x00);
        apu_write(0, j);
        if (type != TRANSMIT_TYPE_GIMIC && !apu_waitInport(0, j, 500)) return 20; // timeout 20
    }

    // upload RAM memory (0x0100 to 0xffff) for memloader
    for (i = 0x100; i < 0x10000; i += 3, j = (j + 1) & 0xFF) {
        apu_write(1, spcdata[i]);
        apu_write(2, spcdata[i + 1]);
        apu_write(3, spcdata[i + 2]);
        apu_write(0, j);
        if (type != TRANSMIT_TYPE_GIMIC && !apu_waitInport(0, j, 500)) return 21; // timeout 21
    }

    // upload RAM memory (0x00-0xef) for bootcode
    // after 0xef comes spc700 registers (0xf0 to 0xff), those are taken care of by the bootcode
    for (i = 0x00; i < 0xf0; i += 3, j = (j + 1) & 0xFF) {
        apu_write(1, spcdata[i]);
        apu_write(2, spcdata[i + 1]);
        apu_write(3, spcdata[i + 2]);
        apu_write(0, j);
        if (type != TRANSMIT_TYPE_GIMIC && !apu_waitInport(0, j, 500)) return 22; // timeout 22
    }

    // for GIMIC
    if (type == TRANSMIT_TYPE_GIMIC) {
        apu_write(0xff, 0xff); // block transfer end
        apu_write(0xff, 0x00); // double speed transfer end (GMC-SPC2)
    }

    // restore SPC ports
    apu_write(0, spcdata[SPC_PORT0]);
    apu_write(1, spcdata[SPC_PORT1]);
    apu_write(2, spcdata[SPC_PORT2]);
    apu_write(3, spcdata[SPC_PORT3]);

    // wait a little
    Sleep(50);

    // emulate SPC700 a little for initialize script700
/*
    boot = 1;
    MoveMemory(&outPort, &spcdata[SPC_PORT0], 4);
    EmuAPU(&buf[0], 384, 0);
    boot = 0;
*/

    // success, now playing
    return 0;
}

DWORD Script700ThreadProc(void* lpData) {
    unsigned char buf[65536];
    unsigned int ms = timeGetTime();

    while (fActiveS700Thread == 1) {
        unsigned int nms = timeGetTime();
        int diff = nms - ms;
        if (diff) {
            diff = diff << 6;
            for (int i = 0; i < diff && i < 64000; i++) EmuAPU(&buf[0], 384, 0);
            ms = nms;
        }

        Sleep(1);
    }

    fActiveS700Thread = 0;
    return 0;
}

int TransmitSPC(int paddr) {
    BASE = paddr;
    pCallbackRead = NULL;
    pCallbackWrite = NULL;

    int result = OpenIOPort();
    if (result) return result;

    result = LocalTransmitSPC(TRANSMIT_TYPE_LPT);
    return result;
}

int TransmitSPCEx(TRANSMITSPCEX *table) {
    TRANSMITSPCEX ctb;
    ZeroMemory(&ctb, sizeof(ctb));
    MoveMemory(&ctb, table, sizeof(ctb));
    int result = -1;

    // LPT
    if (ctb.transmitType == TRANSMIT_TYPE_LPT) {
        TRANSMITSPCEXLPT tb;
        ZeroMemory(&tb, sizeof(tb));
        if (ctb.cbSize > sizeof(tb)) return 1;

        MoveMemory(&tb, table, ctb.cbSize);
        BASE = tb.dataPort;
        pCallbackRead = NULL;
        pCallbackWrite = NULL;

        result = OpenIOPort();
        if (result) return result;

        result = LocalTransmitSPC(ctb.transmitType);

    // GIMIC or CALLBACK
    } else if (ctb.transmitType == TRANSMIT_TYPE_GIMIC || ctb.transmitType == TRANSMIT_TYPE_CALLBACK) {
        TRANSMITSPCEXCALLBACK tb;
        ZeroMemory(&tb, sizeof(tb));
        if (ctb.cbSize > sizeof(tb)) return 1;

        MoveMemory(&tb, table, ctb.cbSize);
        pCallbackRead = tb.pCallbackRead;
        pCallbackWrite = tb.pCallbackWrite;

        result = LocalTransmitSPC(ctb.transmitType);
    }

    // script700
    if (ctb.bScript700) {
        fActiveS700Thread = 1;
        hS700ThreadHandle = CreateThread(NULL, NULL, &Script700ThreadProc, NULL, NULL, &dwS700ThreadID);
    }

    return result;
}


//**************************************************************************************************
u32 DllMain(u32 hinst, u32 fwdReason, u32 lpReserved) {
    u32 result = InitAPU(fwdReason);

    if (fwdReason == DLL_PROCESS_ATTACH) {
//      SNESAPUCallback(&CustomSNESAPUCallback, CBE_INCS700 | CBE_INCDATA);
    } else if (fwdReason == DLL_PROCESS_DETACH) {
        StopTransmitSPC();
        CloseIOPort();
    }

    return result;
}

#ifdef  __cplusplus
}
#endif
// ----- degrade-factory code [END] -----
