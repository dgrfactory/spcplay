/***************************************************************************************************
* Program:    SNES SPC700 Sound Processing Unit (SPU) Emulator                                     *
* Platform:   Intel 80386                                                                          *
* Programmer: Anti Resonance (Alpha-II Productions), sunburst (degrade-factory)                    *
*                                                                                                  *
* Thanks to Michael Abrash.  It was reading the Graphics Programming Black Book that gave me the   *
* idea and inspiration to write this in the first place.                                           *
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
*                                                 Copyright (C) 1999-2008 Alpha-II Productions     *
*                                                 Copyright (C) 2003-2016 degrade-factory          *
***************************************************************************************************/

#ifndef __INC_SPC700
#define __INC_SPC700

//**************************************************************************************************
// Defines

#define APU_CLK     24576000                    //Number of clock cycles in one second

//SPC700 debugging options ---------------------

//Disable DSP data register:
//
//Writes to the DSP data register (0F3h) will have no effect

#define SPC_NODSP   0x8

//Trace execution:
//
//To step through each instruction.  This flag will cause the debug vector to be called before
// executing the current instruction.
//
//This flag only works if SPC700.Asm is compiled with the SA_DEBUG option enabled (see APU.h).

#define SPC_TRACE   0x10

//Return immediately from EmuSPC:
//
//This flag only works when used with SPC_TRACE.  Once the debug vector returns, the CPU registers
// are updated then EmuSPC is terminated before the next instruction is executed.
//
//This only returns from EmuSPC, not from EmuAPU.  If you need to terminate DSP emulation as well,
// specify SPC_HALT in addition to SPC_RETURN.

#define SPC_RETURN  0x1

//Halt APU:
//
//Subsequent calls to EmuSPC will return that cycles were emulated, but nothing will have happened.
//
//Once this flag has been set, the next call to EmuSPC will also disable the DSP emulator.
// Subsequent calls to EmuDSP will generate silence.  This way emulation can be halted in the
// middle of EmuAPU without affecting the size of the output buffer.

#define SPC_HALT    0x2

// ----- degrade-factory code [2016/08/20] -----
//Pause DSP Emulation:
//
//Writes to the DSP envelope will have no update.
//
//When debugging a program of SPC700 which influences a DSP, it's necessary to stop both of SPC700
// and DSP.  Therefore it's appropriate to use this flag with SPC_HALT.

#define DSP_PAUSE   0x20
// ----- degrade-factory code [END] -----


//**************************************************************************************************
// Public Variables

typedef struct SPCFlags
{
    u8      c:1;                                //Carry
    u8      z:1;                                //Zero
    u8      i:1;                                //Interrupts Enabled (not used in the SNES)
    u8      h:1;                                //Half-Carry (auxiliary)
    u8      b:1;                                //Software Break
    u8      p:1;                                //Direct Page Selector
    u8      v:1;                                //Overflow
    u8      n:1;                                //Negative (sign)
} SPCFlags;


//**************************************************************************************************
// SPC700 Debugging Routine
//
// A prototype for a function that gets called for debugging purposes.
//
// The parameters passed in can be modified, and on return will be used to update the internal
// registers (except 'cnt').
//
// Note:
//    When modifying PC or SP, only the lower word needs to be modified; the upper word will be
//     ignored.
//
// In:
//    pc -> Current opcode (LOWORD = PC)
//    ya  = YA
//    x   = X
//    psw = PSW
//    sp -> Current stack byte (LOWORD = SP)
//    cnt = Clock cycle counters (four counters, one in each byte)
//          [0-1] 8kHz cycles left until counters 0 and 1 increase
//          [2]   64kHz cycles left until counter 2 increases
//          [3]   CPU cycles left until next 64kHz clock pulse

typedef void SPCDebug(volatile u8 *pc, volatile u16 ya, volatile u8 x, volatile SPCFlags psw, volatile u8 *sp, volatile u32 cnt);

////////////////////////////////////////////////////////////////////////////////////////////////////
// Private Declarations

#ifndef SNESAPU_DLL

#ifdef  __cplusplus
extern  "C" u8  extraRAM[64];                   //RAM used for storage if ROM reading is enabled
extern  "C" u8  outPort[4];                     //Four out ports
extern  "C" u32 t64Cnt;                         //Counter increased every 64kHz
// ----- degrade-factory code [2006/08/01] -----
extern  "C" u32 pSPCReg;                        //Pointer to SPC700 Register Buffer
// ----- degrade-factory code [END] -----
#else
extern  u8  extraRAM[64];
extern  u8  outPort[4];
extern  u32 t64Cnt;
// ----- degrade-factory code [2006/08/01] -----
extern  u32 pSPCReg;
// ----- degrade-factory code [END] -----
#endif


////////////////////////////////////////////////////////////////////////////////////////////////////
// External Functions

#ifdef  __cplusplus
extern  "C" {
#endif

// ----- degrade-factory code [2008/01/08] -----
//**************************************************************************************************
// Initialize SPC700
//
// This function is a remnant from the 16-bit assembly when dynamic code reallocation was used.
// Now it just initializes internal pointers.
//
// Note:
//    Callers should use InitAPU instead
//
// Destroys:
//    EAX

void InitSPC();
// ----- degrade-factory code [END] -----


// ----- degrade-factory code [2008/01/08] -----
//**************************************************************************************************
// Reset SPC700
//
// Clears all memory, resets the function registers, T64Cnt, and halt flag, and copies ROM into the
// IPL region.
//
// Note:
//    Callers should use ResetAPU instead
//
// Destroys:
//    EAX

void ResetSPC();
// ----- degrade-factory code [END] -----


//**************************************************************************************************
// Set SPC700 Debugging Routine
//
// Installs a vector that gets called before instruction execution for debugging purposes.
//
// Note:
//    pTrace is always called when a STOP instruction is encountered, regardless of the options.
//    The build option SA_DEBUG must be enabled for pTrace to be called under other circumstances
//
// In:
//    pTrace-> Debugging vector (NULL can be passed to disable the debug vector, -1 leaves the
//             vector currently in place)
//    opts   = SPC700 debugging flags (see SPC_??? defines, -1 leaves the current flags)
//
// Out:
//    Previously installed vector

SPCDebug* SetSPCDbg(SPCDebug *pTrace, u32 opts);


// ----- degrade-factory code [2008/01/08] -----
//**************************************************************************************************
// Fix SPC700 After Loading SPC File
//
// Loads timer steps with the values in the timer registers, resets the counters, sets up the in/out
// ports, and stores the registers.
//
// Note:
//    Callers should use FixAPU instead
//
// In:
//    SPC internal registers
//
// Destroys:
//    EAX

void FixSPC(u16 pc, u8 a, u8 y, u8 x, u8 psw, u8 sp);
// ----- degrade-factory code [END] -----


//**************************************************************************************************
// Get SPC700 Registers
//
// Returns the registers stored in the CPU.
//
// In:
//    -> Vars to store SPC internal registers
//
// Destroys:
//    EAX

void GetSPCRegs(u16 *pPC, u8 *pA, u8 *pY, u8 *pX, u8 *pPSW, u8 *pSP);


//**************************************************************************************************
// Write to APU RAM
//
// Writes a value to APU RAM.  Use this instead of writing to RAM directly so any necessary internal
// changes can be made.
//
// In:
//    addr = Address to write to (only the lower 16-bits are used)
//    val  = Value to write
//
// Destroys:
//    EAX

void SetAPURAM(u32 addr, u8 val);


//**************************************************************************************************
// Write to SPC700 Port
//
// Writes a value to the SPC700 via the in ports.  Use this instead of writing to RAM directly.
//
// In:
//    port = Port on which to write (0-3)
//    val  = Value to write
//
// Destroys:
//    EAX

void InPort(u8 port, u8 val);


// ----- degrade-factory code [2008/01/08] -----
//**************************************************************************************************
// Emulate SPC700
//
// Emulates the SPC700 for the number of clock cycles specified, or if the counter break option is
// enabled, until a counter is increased, whichever happens first.
//
// Note:
//    Callers should use EmuAPU instead
//    Passing values <= 0 will cause undeterminable results
//
// In:
//    cyc = Number of 24.576MHz clock cycles to execute (must be > 0)
//
// Out:
//    Clock cycles left to execute (negative if more cycles than specified were emulated)
//
// Destroys:
//    nothing

s32 EmuSPC(s32 cyc);
// ----- degrade-factory code [END] -----


#ifdef  __cplusplus
}
#endif

#endif  //SNESAPU_DLL
#endif  //__INC_SPC700
