/***************************************************************************************************
* Program:    SNES Digital Signal Processor (DSP) Emulator                                         *
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
*                                                 Copyright (C) 1999-2006 Alpha-II Productions     *
*                                                 Copyright (C) 2003-2016 degrade-factory          *
***************************************************************************************************/

#ifndef __INC_DSP
#define __INC_DSP

//**************************************************************************************************
// Defines

//Interpolation routines -----------------------
#define INT_NONE    0                           //None
#define INT_LINEAR  1                           //Linear
#define INT_CUBIC   2                           //Cubic Spline
#define INT_GAUSS   3                           //SNES Gaussian
// ----- degrade-factory code [2004/08/16] -----
#define INT_SINC    4                           //8-point Sinc
#define INT_GAUSS4  7                           //4-point Gaussian
// ----- degrade-factory code [END] -----

//DSP options ----------------------------------
#define DSP_ANALOG  0x01                        //Simulate analog anomalies (low-pass filter)
#define DSP_OLDSMP  0x02                        //Old ADPCM sample decompression routine
#define DSP_SURND   0x04                        //Surround sound
#define DSP_REVERSE 0x08                        //Reverse stereo samples
#define DSP_NOECHO  0x10                        //Disable echo
// ----- degrade-factory code [2021/11/08] -----
#define DSP_NOPMOD  0x20                        //Disable pitch modulation
#define DSP_NOPREAD 0x40                        //Disable pitch read
#define DSP_NOFIR   0x80                        //Disable FIR filter
#define DSP_BASS    0x100                       //BASS BOOST (low-pass filter)
#define DSP_NOENV   0x200                       //Disable envelope
#define DSP_NONOISE 0x400                       //Disable noise
#define DSP_ECHOFIR 0x800                       //Simulate SNES echo/FIR method
#define DSP_NOSURND 0x1000                      //Disable surround sound
#define DSP_FLOAT   0x40000000                  //32bit floating-point volume output
#define DSP_NOSAFE  0x80000000                  //Disable volume safe
// ----- degrade-factory code [END] #37 -----

//PackWave options -----------------------------
#define BRR_LINEAR  0x01                        //Use linear compression for all blocks
#define BRR_LOOP    0x02                        //Set loop flag in block header
#define BRR_NOINIT  0x04                        //Don't create an initial block of silence
#define BRR_8BIT    0x10                        //Input samples are 8-bit

//Mixing flags ---------------------------------
#define MFLG_MUTE   0x01                        //Voice is muted (set by user)
#define MFLG_NOISE  0x02                        //Voice is noise (set by user)
#define MFLG_USER   0x03                        //Flags by user
#define MFLG_KOFF   0x04                        //Voice is in the process of keying off
#define MFLG_OFF    0x08                        //Voice is currently inactive
#define MFLG_END    0x10                        //End block was just played

// ----- degrade-factory code [2013/10/06] -----
//Script700 DSP flags
#define S700_MUTE   0x01                        //Mute voice
#define S700_CHANGE 0x02                        //Change sound source (note change)
#define S700_DETUNE 0x04                        //Detune sound pitch rate
#define S700_VOLUME 0x08                        //Change sound volume

//Script700 DSP master parameters
#define S700_MVOL_L 0x00                        //Master volume (left)
#define S700_MVOL_R 0x01                        //Master volume (right)
#define S700_ECHO_L 0x02                        //Echo volume (left)
#define S700_ECHO_R 0x03                        //Echo volume (right)
// ----- degrade-factory code [END] -----


//**************************************************************************************************
// Public Variables

//DSP registers --------------------------------
typedef struct DSPVoice
{
    s8  volL;                                   //Volume Left
    s8  volR;                                   //Volume Right
    u16 pitch;                                  //Pitch (rate/32000) (3.11)
    u8  srcn;                                   //Sound source being played back
    u8  adsr[2];                                //Envelope rates for attack, decay, and sustain
    u8  gain;                                   //Envelope gain (if not using ADSR)
    s8  envx;                                   //Current envelope height (.7)
    s8  outx;                                   //Current sample being output (-.7)
    s8  __r[6];
} DSPVoice;

typedef struct DSPFIR
{
    s8  __r[15];
    s8  c;                                      //Filter coefficient
} DSPFIR;

typedef union DSPReg
{
    DSPVoice    voice[8];                       //Voice registers

    struct                                      //Global registers
    {
        s8  __r00[12];
        s8  mvolL;                              //Main Volume Left (-.7)
        s8  efb;                                //Echo Feedback (-.7)
        s8  __r0E;
        s8  c0;                                 //FIR filter coefficent (-.7)

        s8  __r10[12];
        s8  mvolR;                              //Main Volume Right (-.7)
        s8  __r1D;
        s8  __r1E;
        s8  c1;

        s8  __r20[12];
        s8  evolL;                              //Echo Volume Left (-.7)
        u8  pmon;                               //Pitch Modulation on/off for each voice
        s8  __r2E;
        s8  c2;

        s8  __r30[12];
        s8  evolR;                              //Echo Volume Right (-.7)
        u8  non;                                //Noise output on/off for each voice
        s8  __r3E;
        s8  c3;

        s8  __r40[12];
        u8  kon;                                //Key On for each voice
        u8  eon;                                //Echo on/off for each voice
        s8  __r4E;
        s8  c4;

        s8  __r50[12];
        u8  kof;                                //Key Off for each voice (instantiates release mode)
        u8  dir;                                //Page containing source directory (wave table offsets)
        s8  __r5E;
        s8  c5;

        s8  __r60[12];
        u8  flg;                                //DSP flags and noise frequency
        u8  esa;                                //Starting page used to store echo waveform
        s8  __r6E;
        s8  c6;

        s8  __r70[12];
        u8  endx;                               //Waveform has ended
        u8  edl;                                //Echo Delay in ms >> 4
        s8  __r7E;
        s8  c7;
    };

    DSPFIR  fir[8];                             //FIR filter

    u8      reg[128];
} DSPReg;

//Internal mixing data -------------------------
// ----- degrade-factory code [2009/07/11] -----
typedef struct MixF
{
    b8  mute:1;                                 //Voice is muted (set by user)
    u8  noise:1;                                //Voice is noise (set by user)
    b8  keyOff:1;                               //Voice is in key off mode
    b8  inactive:1;                             //Voice is inactive, no samples are being played
    b8  keyEnd:1;                               //End block was just played
    u8  __r2:3;
} MixF;
// ----- degrade-factory code [END] -----

typedef enum EnvM
{
    ENV_DEC,                                    //Linear decrease
    ENV_EXP,                                    //Exponential decrease
    ENV_INC,                                    //Linear increase
    ENV_BENT = 6,                               //Bent line increase
    ENV_DIR,                                    //Direct setting
    ENV_REL,                                    //Release mode (key off)
    ENV_SUST,                                   //Sustain mode
    ENV_ATTACK,                                 //Attack mode
    ENV_DECAY = 13,                             //Decay mode
} EnvM;

#define ENVM_IDLE   0x80                        //Envelope is marked as idle, or not changing
#define ENVM_MODE   0xF                         //Envelope mode is stored in lower four bits

// ----- degrade-factory code [2009/03/11] -----
typedef struct Voice
{
    //Voice -----------08
    u16     vAdsr;                              //ADSR parameters when KON was written
    u8      vGain;                              //Gain parameters when KON was written
    u8      vRsv;                               //Changed ADSR/Gain parameters flag
    s16     *sIdx;                              //-> current sample in sBuf
    //Waveform --------06
    void    *bCur;                              //-> current block
    u8      bHdr;                               //Block Header for current block
    u8      mFlg;                               //Mixing flags (see MixF)
    //Envelope --------22
    u8      eMode;                              //[3-0] Current mode (see EnvM)
                                                //[6-4] ADSR mode to switch into from Gain
                                                //[7]   Envelope is idle
    u8      eRIdx;                              //Index in RateTab (0-31)
    u32     eRate;                              //Rate of envelope adjustment (16.16)
    u32     eCnt;                               //Sample counter (16.16)
    u32     eVal;                               //Current envelope value
    s32     eAdj;                               //Amount to adjust envelope height
    u32     eDest;                              //Envelope Destination
    //Visualization ---08
    s32     vMaxL;                              //Maximum absolute sample output
    s32     vMaxR;
    //Samples ---------52
    s16     sP1;                                //Last sample decompressed (prev1)
    s16     sP2;                                //Second to last sample (prev2)
    s16     sBufP[8];                           //Last 8 samples from previous block (needed for inter.)
    s16     sBuf[16];                           //32 bytes for decompressed sample blocks
    //Mixing ----------32
    f32     mTgtL;                              //Target volume (floating-point routine only)
    f32     mTgtR;                              // "  "
    s32     mChnL;                              //Channel Volume (-24.7)
    s32     mChnR;                              // "  "
    u32     mRate;                              //Pitch Rate after modulation (16.16)
    u16     mDec;                               //Pitch Decimal (.16) (used as delta for interpolation)
    u8      mSrc;                               //Current source number
    u8      mKOn;                               //Delay time from writing KON to output
    u32     mOrgP;                              //Original pitch rate converted from the DSP (16.16)
    s32     mOut;                               //Last sample output before chn vol (used for pitch mod)
} Voice;
// ----- degrade-factory code [END] -----


//**************************************************************************************************
// DSP Debugging Routine
//
// A prototype for a function that gets called for debugging purposes.
//
// The parameters passed in can be modified, and on return will be used to update the internal
// registers.  Set bit-7 of 'reg' to prevent the DSP from handling the write.
//
// For calling a pointer to another debugging routine, use the following macro.
//
// In:
//    reg -> Current register (LOBYTE = register index)
//    val  = Value being written to register

typedef void DSPDebug(volatile u8 *reg, volatile u8 val);

#ifdef  __GNUC__
#define _CallDSPDebug(proc, reg, val) \
            asm(" \
                pushl   %2 \
                pushl   %1 \
                calll   %0 \
                popl    %1 \
                popl    %2 \
            " : : "m" (proc), "m" (reg), "m" (val));
#else
#define _CallDSPDebug(proc, reg, val) \
            _asm \
            { \
                push    dword ptr [val]; \
                push    dword ptr [reg]; \
                call    dword ptr [proc]; \
                pop     dword ptr [reg]; \
                pop     dword ptr [val]; \
            }
#endif


////////////////////////////////////////////////////////////////////////////////////////////////////
// Private Declarations

#ifndef SNESAPU_DLL

#ifdef  __cplusplus
extern  "C" DSPReg  dsp;                        //DSP registers
extern  "C" Voice   mix[8];                     //Mixing structures for each voice
extern  "C" u32     vMMaxL,vMMaxR;              //Maximum absolute sample output
#else
extern  DSPReg  dsp;
extern  Voice   mix[8];
extern  u32     vMMaxL,vMMaxR;
#endif


////////////////////////////////////////////////////////////////////////////////////////////////////
// External Functions
//
// NOTE:  Unless otherwise stated, no range checking is performed.  It is the caller's
//        responsibilty to ensure parameters passed are within a valid range.

#ifdef  __cplusplus
extern  "C" {
#endif

// ----- degrade-factory code [2006/10/20] -----
//**************************************************************************************************
// Initialize DSP
//
// Creates the lookup tables for interpolation, and sets the default mixing settings:
//
//    mixType = 1
//    numChn  = 2
//    bits    = 16
//    rate    = 32000
//    inter   = INT_GAUSS
//    opts    = 0
//
// Note:
//    Callers should use InitAPU instead
//
// Destroys:
//    ST0-7

void InitDSP();
// ----- degrade-factory code [END] -----


//**************************************************************************************************
// Reset DSP
//
// Resets the DSP registers, erases internal variables, and resets the volume.
//
// Note:
//    Callers should use ResetAPU instead
//
// Destroys:
//    EAX

void ResetDSP();


//**************************************************************************************************
// Set DSP Options
//
// Recalculates tables, changes the output sample rate, and sets up the mixing routine.
//
// Notes:
//    Range checking is performed on all parameters.  If a parameter does not match the required
//     range of values, the default value will be assumed.
//
//    -1 can be used for any paramater that should remain unchanged.
//
//    Callers should use SetAPUOpt instead
//
// In:
//    mix   = Mixing routine (default 1)
//    chn   = Number of channels (1 or 2, default 2)
//    bits  = Sample size (8, 16, 24, 32, or -32 [IEEE 754], default 16)
//    rate  = Sample rate (8000-192000, default 32000)
//    inter = Interpolation type (default INT_GAUSS)
//    opts  = See 'DSP options' in the Defines section
//
// Destroys:
//    EAX

void SetDSPOpt(u32 mix, u32 chn, u32 bits, u32 rate, u32 inter, u32 opts);


//**************************************************************************************************
// Debug DSP
//
// Installs a vector that gets called each time a value is written to the DSP data register.
//
// Note:
//    The build option SA_DEBUG must be enabled
//
// In:
//    pTrace-> debug function (a null pointer turns off the debug call)
//
// Out:
//    Previously installed vector

DSPDebug* SetDSPDbg(DSPDebug *pTrace);


//**************************************************************************************************
// Fix DSP After Loading SPC File
//
// Initializes the internal mixer variables.
//
// Note:
//    Callers should use FixAPU instead
//
// Destroys:
//    EAX

void FixDSP();


//**************************************************************************************************
// Fix DSP After Seeking
//
// Puts all DSP voices in a key off state and erases echo region.
//
// In:
//    True  = Reset all voices
//    False = Only erase memory
//
// Destroys:
//    EAX

void FixSeek(u8 reset);


//**************************************************************************************************
// Set DSP Base Pitch
//
// Adjusts the pitch of the DSP.
//
// In:
//    base = Base sample rate (32000 = Normal pitch, 32458 = Old SB cards, 32768 = Old ZSNES)
//
// Destroys:
//    EAX

void SetDSPPitch(u32 base);


//**************************************************************************************************
// Set DSP Amplification
//
// This value is applied to the output with the main volumes.
//
// In:
//    amp = Amplification level [-15.16] (1.0 = SNES, negative values act as 0)
//
// Destroys:
//    EAX

void SetDSPAmp(u32 amp);


//**************************************************************************************************
// Set DSP Volume
//
// This value attenuates the output and was implemented to allow songs to be faded out.
//
// Notes:
//    ResetDSP sets this value to 65536 (no attenuation).
//    This function is called internally by EmuAPU and SetAPULength, and should not be called by
//     the user.
//
// In:
//    vol = Volume [-1.16] (0.0 to 1.0, negative values act as 0)
//
// Destroys:
//    EAX

void SetDSPVol(u32 vol);


//**************************************************************************************************
// Set Voice Stereo Separation
//
// Sets the amount to adjust the panning position of each voice.
//
// In:
//   sep = Separation [1.16]
//         1.0 - full separation (output is either left, center, or right)
//         0.5 - normal separation (output is unchanged)
//           0 - no separation (output is completely monaural)
//
// Destroys:
//    EAX,ST(0-7)

void SetDSPStereo(u32 sep);


//**************************************************************************************************
// Set Echo Feedback Crosstalk
//
// Sets the amount of crosstalk between the left and right channel during echo feedback.
//
// In:
//   leak = Crosstalk amount [-1.15]
//           1.0 - no crosstalk (SNES)
//             0 - full crosstalk (mono/center)
//          -1.0 - inverse crosstalk (L/R swapped)
//
// Destroys:
//    EAX

void SetDSPEFBCT(s32 leak);


//**************************************************************************************************
// DSP Data Port
//
// Writes a value to a specified DSP register and alters the DSP accordingly.  If the register write
// affects the output generated by the DSP, this function returns true.
//
// Note:
//    SetDSPReg does not call the debugging vector
//
// In:
//    reg = DSP Address
//    val = DSP Data
//
// Out:
//    true, if the DSP state was affected

b8 SetDSPReg(u8 reg, u8 val);


//**************************************************************************************************
// Emulate DSP
//
// Emulates the DSP of the SNES.
//
// Notes:
//    If 'pBuf' is NULL, the routine MIX_NONE will be used
//    Range checking is performed on 'size'
//
//    Callers should use EmuAPU instead
//
// In:
//    pBuf-> Buffer to store output
//    size = Length of buffer (in samples, can be 0)
//
// Out:
//    -> End of buffer
//
// Destroys:
//    ST(0-7)

void* EmuDSP(void *pBuf, s32 size);

#ifdef  __cplusplus
}
#endif

#endif  //SNESAPU_DLL
#endif  //__INC_DSP
