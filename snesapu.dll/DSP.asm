;===================================================================================================
;Program:    SNES Digital Signal Processor (DSP) Emulator
;Platform:   Intel 80386
;Programmer: Anti Resonance (Alpha-II Productions), sunburst (degrade-factory)
;
;"SNES" and "Super Nintendo Entertainment System" are trademarks of Nintendo Co., Limited and its
;subsidiary companies.
;
;This program is free software; you can redistribute it and/or modify it under the terms of the
;GNU General Public License as published by the Free Software Foundation; either version 2 of
;the License, or (at your option) any later version.
;
;This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
;without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
;See the GNU General Public License for more details.
;
;You should have received a copy of the GNU General Public License along with this program;
;if not, write to the Free Software Foundation, Inc.
;59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
;
;                                                   Copyright (C) 1999-2006 Alpha-II Productions
;                                                   Copyright (C) 2003-2025 degrade-factory
;
;List of users and dates who/when modified this file:
;   - degrade-factory in 2025-04-02
;   - Zenith in 2024-06-19
;===================================================================================================

CPU     386
BITS    32

;===================================================================================================
;Header files

%include "macro.inc"
%include "SNESAPU.inc"
%include "SPC700.inc"
%include "APU.inc"
%define INTERNAL
%include "DSP.inc"


;===================================================================================================
;Equates

    ;Envelope mode masks ------------------------
    E_TYPE      EQU 00001b                                                      ;Type of adj: Constant(1/64 or 1/256) / Exp.(255/256)
    E_DIR       EQU 00010b                                                      ;Direction: Decrease / Increase
    E_DEST      EQU 00100b                                                      ;Destination: Default(0 or 1) / Other(x/8 or .75)
    E_ADSR      EQU 01000b                                                      ;Envelope mode: Gain/ADSR
    E_IDLE      EQU 80h                                                         ;Envelope speed is set to 0
    E_DEC       EQU 00000b                                                      ;Linear decrease
    E_EXP       EQU 00001b                                                      ;Exponential decrease
    E_INC       EQU 00010b                                                      ;Linear increase
    E_BENT      EQU 00110b                                                      ;Bent line increase
    E_DIRECT    EQU 00111b                                                      ;Direct gain
    E_ATT       EQU 01010b                                                      ;Attack mode
    E_DECAY     EQU 01101b                                                      ;Decay mode
    E_SUST      EQU 01001b                                                      ;Sustain mode
    E_REL       EQU 01000b                                                      ;Release mode

    ;Envelope precision -------------------------
    E_SHIFT     EQU 4                                                           ;Amount to shift envelope to get 8-bit signed value

    ;Envelope adjustment rates ------------------
    A_GAIN      EQU (1 << E_SHIFT)                                              ;Amount to adjust envelope values
    A_LIN       EQU (128*A_GAIN)/64                                             ;Linear rate to increase/decrease envelope
    A_KOFF      EQU (128*A_GAIN)/256                                            ;Rate to decrease envelope during release
    A_BENT      EQU (128*A_GAIN)/256                                            ;Rate to increase envelope after bend
    A_NOATT     EQU (128*A_GAIN)-1                                              ;Rate to increase if attack rate is set to 0ms
    A_DIRECT    EQU (128*A_GAIN)-1                                              ;Rate to increase/decrease if envelope is set directly
    A_EXP       EQU 0                                                           ;Rate to decrease envelope exponentially (Not used)

    ;Envelope destination values ----------------
    D_MAX       EQU (128*A_GAIN)-1                                              ;Maximum envelope value
    D_BENT      EQU (128*A_GAIN*3)/4                                            ;First destination of bent line
    D_EXP       EQU (128*A_GAIN)/8                                              ;Minimum decay destination value
    D_MIN       EQU 0                                                           ;Minimum envelope value

    ;Array sizes --------------------------------
    MIX_SIZE    EQU 1024                                                        ;Size of mixing buffer in samples
    FIRBUF      EQU 2*2*64                                                      ;Stereo * Ring loop * 256kHz / 32kHz
    ECHOBUF     EQU 2*((192000*240)/1000)                                       ;Size of echo buffer (stereo * 192kHz * 240ms)
    LOWBUF1     EQU 384                                                         ;Size of BASS-BOOST buffer (base 192kHz)
    LOWBUF2     EQU 6144
    LOWLEN1     EQU LOWBUF1*2+LOWBUF2*2                                         ;Total size of BASS-BOOST buffer (without lowSize, lowLv)
    LOWLEN2     EQU 10


;===================================================================================================
;Structures



;===================================================================================================
;Data

%ifndef WIN32
SECTION .data ALIGN=256
%else
SECTION .data ALIGN=32
%endif

                ;12-bit Gaussian curve generated by SNES DSP
    gaussTab    DW      0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0 ;s0
                DW     16,   16,   16,   16,   16,   16,   16,   16,   16,   16,   16,   32,   32,   32,   32,   32
                DW     32,   32,   48,   48,   48,   48,   48,   64,   64,   64,   64,   64,   80,   80,   80,   80
                DW     96,   96,   96,   96,  112,  112,  112,  128,  128,  128,  144,  144,  144,  160,  160,  160
                DW    176,  176,  176,  192,  192,  208,  208,  224,  224,  240,  240,  240,  256,  256,  272,  272
                DW    288,  304,  304,  320,  320,  336,  336,  352,  368,  368,  384,  384,  400,  416,  432,  432
                DW    448,  464,  464,  480,  496,  512,  512,  528,  544,  560,  576,  576,  592,  608,  624,  640
                DW    656,  672,  688,  704,  720,  736,  752,  768,  784,  800,  816,  832,  848,  864,  880,  896
                DW    928,  944,  960,  976,  992, 1024, 1040, 1056, 1072, 1104, 1120, 1136, 1168, 1184, 1216, 1232
                DW   1248, 1280, 1296, 1328, 1344, 1376, 1392, 1424, 1440, 1472, 1504, 1520, 1552, 1584, 1600, 1632
                DW   1664, 1696, 1712, 1744, 1776, 1808, 1840, 1872, 1888, 1920, 1952, 1984, 2016, 2048, 2080, 2112
                DW   2144, 2192, 2224, 2256, 2288, 2320, 2352, 2400, 2432, 2464, 2496, 2544, 2576, 2608, 2656, 2688
                DW   2736, 2768, 2800, 2848, 2880, 2928, 2976, 3008, 3056, 3088, 3136, 3184, 3216, 3264, 3312, 3360
                DW   3392, 3440, 3488, 3536, 3584, 3632, 3680, 3728, 3776, 3824, 3872, 3920, 3968, 4016, 4064, 4112
                DW   4160, 4208, 4272, 4320, 4368, 4416, 4480, 4528, 4576, 4640, 4688, 4752, 4800, 4864, 4912, 4976
                DW   5024, 5088, 5136, 5200, 5248, 5312, 5376, 5424, 5488, 5552, 5616, 5664, 5728, 5792, 5856, 5920 ;e0
                DW   5984, 6048, 6096, 6160, 6224, 6288, 6352, 6416, 6480, 6560, 6624, 6688, 6752, 6816, 6880, 6944 ;s1
                DW   7024, 7088, 7152, 7216, 7296, 7360, 7424, 7504, 7568, 7632, 7712, 7776, 7856, 7920, 7984, 8064
                DW   8128, 8208, 8272, 8352, 8432, 8496, 8576, 8640, 8720, 8800, 8864, 8944, 9008, 9088, 9168, 9232
                DW   9312, 9392, 9472, 9536, 9616, 9696, 9776, 9840, 9920,10000,10080,10160,10240,10304,10384,10464
                DW  10544,10624,10704,10784,10848,10928,11008,11088,11168,11248,11328,11408,11488,11568,11648,11712
                DW  11792,11872,11952,12032,12112,12192,12272,12352,12432,12512,12592,12672,12752,12832,12896,12976
                DW  13056,13136,13216,13296,13376,13456,13536,13616,13680,13760,13840,13920,14000,14080,14144,14224
                DW  14304,14384,14464,14528,14608,14688,14768,14832,14912,14992,15056,15136,15216,15280,15360,15440
                DW  15504,15584,15648,15728,15808,15872,15952,16016,16080,16160,16224,16304,16368,16432,16512,16576
                DW  16640,16720,16784,16848,16912,16976,17056,17120,17184,17248,17312,17376,17440,17504,17568,17632
                DW  17696,17744,17808,17872,17936,18000,18048,18112,18176,18224,18288,18336,18400,18448,18512,18560
                DW  18624,18672,18720,18784,18832,18880,18928,18976,19040,19088,19136,19184,19232,19280,19312,19360
                DW  19408,19456,19504,19536,19584,19632,19664,19712,19744,19792,19824,19856,19904,19936,19968,20016
                DW  20048,20080,20112,20144,20176,20208,20240,20272,20304,20320,20352,20384,20400,20432,20464,20480
                DW  20512,20528,20544,20576,20592,20608,20640,20656,20672,20688,20704,20720,20736,20752,20752,20768
                DW  20784,20800,20800,20816,20832,20832,20848,20848,20848,20864,20864,20864,20864,20864,20880,20880 ;e1
                DW  20880,20880,20864,20864,20864,20864,20864,20848,20848,20848,20832,20832,20816,20800,20800,20784 ;s2
                DW  20768,20752,20752,20736,20720,20704,20688,20672,20656,20640,20608,20592,20576,20544,20528,20512
                DW  20480,20464,20432,20400,20384,20352,20320,20304,20272,20240,20208,20176,20144,20112,20080,20048
                DW  20016,19968,19936,19904,19856,19824,19792,19744,19712,19664,19632,19584,19536,19504,19456,19408
                DW  19360,19312,19280,19232,19184,19136,19088,19040,18976,18928,18880,18832,18784,18720,18672,18624
                DW  18560,18512,18448,18400,18336,18288,18224,18176,18112,18048,18000,17936,17872,17808,17744,17696
                DW  17632,17568,17504,17440,17376,17312,17248,17184,17120,17056,16976,16912,16848,16784,16720,16640
                DW  16576,16512,16432,16368,16304,16224,16160,16080,16016,15952,15872,15808,15728,15648,15584,15504
                DW  15440,15360,15280,15216,15136,15056,14992,14912,14832,14768,14688,14608,14528,14464,14384,14304
                DW  14224,14144,14080,14000,13920,13840,13760,13680,13616,13536,13456,13376,13296,13216,13136,13056
                DW  12976,12896,12832,12752,12672,12592,12512,12432,12352,12272,12192,12112,12032,11952,11872,11792
                DW  11712,11648,11568,11488,11408,11328,11248,11168,11088,11008,10928,10848,10784,10704,10624,10544
                DW  10464,10384,10304,10240,10160,10080,10000, 9920, 9840, 9776, 9696, 9616, 9536, 9472, 9392, 9312
                DW   9232, 9168, 9088, 9008, 8944, 8864, 8800, 8720, 8640, 8576, 8496, 8432, 8352, 8272, 8208, 8128
                DW   8064, 7984, 7920, 7856, 7776, 7712, 7632, 7568, 7504, 7424, 7360, 7296, 7216, 7152, 7088, 7024
                DW   6944, 6880, 6816, 6752, 6688, 6624, 6560, 6480, 6416, 6352, 6288, 6224, 6160, 6096, 6048, 5984 ;e2
                DW   5920, 5856, 5792, 5728, 5664, 5616, 5552, 5488, 5424, 5376, 5312, 5248, 5200, 5136, 5088, 5024 ;s3
                DW   4976, 4912, 4864, 4800, 4752, 4688, 4640, 4576, 4528, 4480, 4416, 4368, 4320, 4272, 4208, 4160
                DW   4112, 4064, 4016, 3968, 3920, 3872, 3824, 3776, 3728, 3680, 3632, 3584, 3536, 3488, 3440, 3392
                DW   3360, 3312, 3264, 3216, 3184, 3136, 3088, 3056, 3008, 2976, 2928, 2880, 2848, 2800, 2768, 2736
                DW   2688, 2656, 2608, 2576, 2544, 2496, 2464, 2432, 2400, 2352, 2320, 2288, 2256, 2224, 2192, 2144
                DW   2112, 2080, 2048, 2016, 1984, 1952, 1920, 1888, 1872, 1840, 1808, 1776, 1744, 1712, 1696, 1664
                DW   1632, 1600, 1584, 1552, 1520, 1504, 1472, 1440, 1424, 1392, 1376, 1344, 1328, 1296, 1280, 1248
                DW   1232, 1216, 1184, 1168, 1136, 1120, 1104, 1072, 1056, 1040, 1024,  992,  976,  960,  944,  928
                DW    896,  880,  864,  848,  832,  816,  800,  784,  768,  752,  736,  720,  704,  688,  672,  656
                DW    640,  624,  608,  592,  576,  576,  560,  544,  528,  512,  512,  496,  480,  464,  464,  448
                DW    432,  432,  416,  400,  384,  384,  368,  368,  352,  336,  336,  320,  320,  304,  304,  288
                DW    272,  272,  256,  256,  240,  240,  240,  224,  224,  208,  208,  192,  192,  176,  176,  176
                DW    160,  160,  160,  144,  144,  144,  128,  128,  128,  112,  112,  112,   96,   96,   96,   96
                DW     80,   80,   80,   80,   64,   64,   64,   64,   64,   48,   48,   48,   48,   48,   32,   32
                DW     32,   32,   32,   32,   32,   16,   16,   16,   16,   16,   16,   16,   16,   16,   16,   16
                DW      0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,    0 ;e3

                ;Jump table for DSP register writes (see DSPIn)
    dspRegs     DD  RVolL,  RVolR,  RPitch, RPitch, RNull,  RADSR,  RADSR,  RGain
                DD  RNull,  RNull,  RNull,  RNull,  RMVolL, REFB,   RNull,  RFCf
                DD  RVolL,  RVolR,  RPitch, RPitch, RNull,  RADSR,  RADSR,  RGain
                DD  RNull,  RNull,  RNull,  RNull,  RMVolR, RNull,  RNull,  RFCf
                DD  RVolL,  RVolR,  RPitch, RPitch, RNull,  RADSR,  RADSR,  RGain
                DD  RNull,  RNull,  RNull,  RNull,  REVolL, RPMOn,  RNull,  RFCf
                DD  RVolL,  RVolR,  RPitch, RPitch, RNull,  RADSR,  RADSR,  RGain
                DD  RNull,  RNull,  RNull,  RNull,  REVolR, RNull,  RNull,  RFCf
                DD  RVolL,  RVolR,  RPitch, RPitch, RNull,  RADSR,  RADSR,  RGain
                DD  RNull,  RNull,  RNull,  RNull,  RKOn,   RNull,  RNull,  RFCf
                DD  RVolL,  RVolR,  RPitch, RPitch, RNull,  RADSR,  RADSR,  RGain
                DD  RNull,  RNull,  RNull,  RNull,  RKOff,  RNull,  RNull,  RFCf
                DD  RVolL,  RVolR,  RPitch, RPitch, RNull,  RADSR,  RADSR,  RGain
                DD  RNull,  RNull,  RNull,  RNull,  RFlg,   REDl,   RNull,  RFCf
                DD  RVolL,  RVolR,  RPitch, RPitch, RNull,  RADSR,  RADSR,  RGain
                DD  RNull,  RNull,  RNull,  RNull,  RNull,  REDl,   RNull,  RFCf

                ;Pointers to interpolation functions for each mixing routine
    intRout     DD  NoneInt,    LinearInt,  Point4Int,  Point4Int,  Point8Int,  Point4Int,  Point4Int,  Point4Int

                ;Pointers to interpolation table for each interpolation type
    tabRout     DD  0,          0,          cubicTab,   gaussTab,   sincTab,    gauss4Tab,  gauss4Tab,  gauss4Tab

    ;Frequency table -------------------------
    freqTab     DD     0
                DD  2048, 1536, 1280                                            ;Number of samples between updates.  Used to determine
                DD  1024,  768,  640                                            ; envelope rates and noise frequencies
                DD   512,  384,  320
                DD   256,  192,  160
                DD   128,   96,   80
                DD    64,   48,   40
                DD    32,   24,   20
                DD    16,   12,   10
                DD     8,    6,    5
                DD     4,    3
                DD     2
                DD     1

    ;Floating point constants ----------------
    fn2_5       DD  -2.5                                                        ;Cubic interpolation
    fn1_5       DD  -1.5
    fn0_5       DD  -0.5
    fp0_5       DD  0.5
    fp1_5       DD  1.5

    fpA         DD  20534.298825777156115789949213172                           ;(sqrt(2 * pi) * 32768) / 4
    fp32km1     DD  32767.0                                                     ;Cubic interpolation
    fpMaxLv     DD  8589934592.0                                                ;(2 ^ 31) * 4
    fpLowRt     DD  192000.0                                                    ;BASS-BOOST base sampling rate
    fpLowLv1    DD  0.005                                                       ;BASS-BOOST level (base 192kHz)
    fpLowLv2    DD  0.0003125
    fpLowBs1    DD  0.002                                                       ;BASS-BOOST buffer size (base 192kHz) (=LOWBUF1/192000)
    fpLowBs2    DD  0.032                                                       ;                                     (=LOWBUF2/192000)
    fpAafCF1    DD  8038.1284389846                                             ;Anti-Alies 1st filter cut-off frequency
    fpAafCF2    DD  16176.421441299                                             ;Anti-Alies 2nd filter cut-off frequency

    Scale32 fp64k,16                                                            ;Various
    Scale32 fp32k,15                                                            ;Sinc interpolation
    Scale32 fp512,9                                                             ;Gaussian interpolation
    Scale32 fp256,8                                                             ;Number of points of interpolation between samples
    Scale32 fp128,7                                                             ;Stereo separation
    Scale32 fpShR1,-1                                                           ;Cubic interpolation
    Scale32 fpShR7,-7                                                           ;Voice volume
    Scale32 fpShR8,-8                                                           ;Main/Echo volume(7), 8 voices(3), Echo + Main(1)
    Scale32 fpShR10,-10                                                         ;Gaussian interpolation
    Scale32 fpShR15,-15                                                         ;Cubic interpolation
    Scale32 fpShR16,-16
    Scale32 fpShR19,-19                                                         ;Denormalized number check for echo feedback
    Scale32 fpShR23,-23                                                         ;EFBCT(16), EFB(7)
    Scale32 fpShR31,-31                                                         ;32bit-float (IEEE754) output
    Scale32 fpEShR,-(E_SHIFT+7)


;===================================================================================================
;Variables

%ifndef WIN32
SECTION .bss ALIGN=256
%else
SECTION .bss ALIGN=64

;The BSS must be aligned on at least a 256-byte boundary.  (If it's not, you'll know as soon as you
; play a song.)  This is tricky in Windows because the win32 object files can only specify 64-byte
; alignment.  Try padding with multiples of 64 until it works.

    resb    DSP_ALIGN                                                           ;Force page alignment

%endif

;Be careful when touching!  All arrays are carefully aligned on large boundaries to facillitate easier
; indexing and better cache utilization.

    ;DSP Core ---------------------------- [0]
    mix         resb    1024                                                    ;<VoiceMix> Mixing settings for each voice
    dsp         resb    128                                                     ;<DSPRAM> DSP registers

    ;Look-up Tables -------------------- [480]
    rateTab     resd    32                                                      ;Update Rate Table
    brrTab      resd    1024                                                    ;All possible range/nybble values for BRR
    cubicTab    resq    256                                                     ;Cubic interpolation
    sincTab     resq    512                                                     ;8-point Sinc interpolation with Hanning window
    gauss4Tab   resq    256                                                     ;4-point Gauss interpolation
    interTab    resq    512                                                     ;Interpolation Table

    ;Globals -------------------------- [4500]
    pTrace      resd    1                                                       ;-> Debugging vector
    pOutBuf     resd    1                                                       ;-> output buffer
    outLeft     resd    1                                                       ;Number of samples left to fill output buffer
    outCnt      resd    1                                                       ;t64 count at last call to EmuDSP
    outDec      resd    1                                                       ;Fractional number of samples to be generated
                resd    3

    ;DSP Options ---------------------- [4520]
    dspMix      resb    1                                                       ;Mixing routine
    dspChn      resb    1                                                       ;Number of channels being output
    dspSize     resb    1                                                       ;Size of samples in bytes
                resb    1

    dspRate     resd    1                                                       ;Sample rate (max 32kHz in actual emulation mode)
    dspOpts     resd    1                                                       ;Option flags passed to SetDSPOpt
    pitchBas    resd    1                                                       ;Base sample rate
    pitchAdj    resd    1                                                       ;Amount to adjust pitch rates [16.16]
    pInter      resd    1                                                       ;-> interpolation function
    pDecomp     resd    1                                                       ;-> sample decompression routine

    dspInter    resb    1                                                       ;Interpolation method
    voiceMix    resb    1                                                       ;Voices that are currently being mixed
    surround    resb    1                                                       ;Turn on surround sound  (OFF:0x00 / ON:0xFF)
    surroff     resb    1                                                       ;Turn off surround sound (OFF:0x00 / ON:0x80)

    ;Volume --------------------------- [4540]
    volSepar    resd    1                                                       ;Stereo separation
    volRamp1    resd    1                                                       ;Amount to ramp volume per sample
    volRamp2    resd    1                                                       ;Amount to ramp volume per sample
    volAmp      resd    1                                                       ;Amplification [16.16]
    volAtten    resd    1                                                       ;Global volume attenuation [1.16]
    volAdj      resd    1                                                       ;Amount to adjust main volumes [-15.16]
    volMainL    resd    1                                                       ;Main volumes
    volMainR    resd    1
    nowMainL    resd    1
    nowMainR    resd    1
    volEchoL    resd    1                                                       ;Echo volumes
    volEchoR    resd    1
    nowEchoL    resd    1
    nowEchoR    resd    1
    vMMaxL      resd    1                                                       ;Maximum absolute sample output
    vMMaxR      resd    1

    ;Noise ---------------------------- [4580]
    nRate       resd    1                                                       ;Noise sample rate reciprocal [.32]
    nfRate      resd    1
    nAcc        resd    1                                                       ;Noise accumulator [.32] (>= 1 generate a new sample)
    nfAcc       resd    1
    nSmp        resd    1                                                       ;Current Noise sample
    nfSmp       resd    1
    nSeed       resd    1                                                       ;Noise random seed
                resd    1

    ;Echo filtering ------------------- [45A0]
    firCur      resd    1                                                       ;Index of the first sample to feed into the filter
    firRate     resd    1                                                       ;Rate to feed samples into filter
                resd    2
    firTaps     resd    8                                                       ;Filter coefficents

    ;Echo ----------------------------- [45D0]
    echoLenD    resd    1                                                       ;Size of delay in echo area (in bytes)
    echoMaxD    resd    1                                                       ;Maximum position in echo area (in bytes)
    echoCurD    resd    1                                                       ;Writing position counter (in bytes)
                resd    1
    echoLenM    resd    1                                                       ;Size of delay in echo memory (in bytes)
    echoMaxM    resd    1                                                       ;Maximum position in echo memory (in bytes)
    echoCurM    resd    1                                                       ;Writing position counter (in bytes)
    echoDecM    resd    1                                                       ;Decimal counter

    efbct       resd    1                                                       ;User specified echo feedback crosstalk
    echoFB      resd    1                                                       ;Echo feedback
    echoFBCT    resd    1                                                       ;Echo feedback crosstalk
                resd    1

    ;Single source playback ----------- [4600]
    tBRR        resb    8                                                       ;Temporary buffer for storing BRR block
                resw    4                                                       ;Temporary buffer for single sound playback
    tBuf        resw    16
    tRate       resd    1
    tDec        resd    1
    tLoop       resd    1
    tBlk        resd    1
    tIdx        resd    1
    tP1         resd    1
    tP2         resd    1
                resd    1

    ;Emulation work ------------------- [4650]
    songLen     resd    1                                                       ;Length of song (in ticks)
    fadeLen     resd    1                                                       ;Length of fade (in ticks)
    outRate     resd    1                                                       ;Out sampling rate
    envCrt      resd    1                                                       ;Current envelope level
    envVal      resd    1                                                       ;MAX envelope level
    dspPMod     resb    1                                                       ;DSP pitch modulation flags
    dspNoise    resb    1                                                       ;DSP noise flags
    dspNoiseF   resb    1                                                       ;DSP noise flags (force)
    dspMute     resb    1                                                       ;DSP mute flags
    disFlag     resb    1                                                       ;DSP disabled channel flags (see EmuDSP)
    konRsv      resb    1                                                       ;Reserved KON flags
    koffRsv     resb    1                                                       ;Reserved KOFF flags
    konRun      resb    1                                                       ;Running KON process flags
    envFlag     resb    1                                                       ;DSP envelope flags
                                                                                ;   [1] - Suspended envelope by frontend
                                                                                ;   [5] - Suspended envelope by SetSPCDbg
                resb    3
                resd    4

    ;BASS BOOST ----------------------- [4680]
    lowRstL1    resd    1                                                       ;BASS-BOOST reset counter (Left)
    lowRstL2    resd    1
    lowRstR1    resd    1                                                       ;BASS-BOOST reset counter (Right)
    lowRstR2    resd    1
    lowSumL1    resd    1                                                       ;BASS-BOOST sum (Left)
    lowSumL2    resd    1
    lowSumR1    resd    1                                                       ;BASS-BOOST sum (Right)
    lowSumR2    resd    1
    lowCnt1     resd    1                                                       ;BASS-BOOST index counter
    lowCnt2     resd    1
    lowSize1    resd    1                                                       ;BASS-BOOST buffer size
    lowSize2    resd    1
    lowLv1      resd    1                                                       ;BASS-BOOST level
    lowLv2      resd    1
                resd    2

    ;Anti-Alies filter ---------------- [46C0]
    aaf1A1      resd    1                                                       ;Anti-Alies 1st filter coefficients
    aaf1B0      resd    1
    aaf1B1      resd    1
    aaf2A1      resd    1                                                       ;Anti-Alies 2nd filter coefficients
    aaf2B0      resd    1
    aaf2B1      resd    1
    aafBufL     resd    3                                                       ;Anti-Alies filter buffer (Left)
    aafBufR     resd    3                                                       ;Anti-Alies filter buffer (Right)

    ;ADSR/Gain ------------------------ [46F0]
    adsrAdj     resd    1                                                       ;Update envelope rate adjustment (16.16)
    adsrClk     resw    1                                                       ;Update envelope rate clock
    adsrCnt     resw    1                                                       ;Number of times to update envelope
    adsrUpd     resb    1                                                       ;Number of updates executed by UpdateEnv
                resb    3
                resd    1

    ;Sampling rate converter ---------- [4700]
    smpBuf      resd    8                                                       ;Sample history buffer
    smpRate     resd    1                                                       ;Sample rate (max 192kHz)
    smpAdj      resd    1                                                       ;Sample rate adjustment
    smpDec      resd    1                                                       ;Sample rate (decimal)
    smpSize     resd    1                                                       ;Emulate sample size
    smpCur      resd    1                                                       ;Ratio between samples
    smpCnt      resd    1                                                       ;Ratio adjustment rate counter
    smpDen      resd    1                                                       ;Ratio adjustment reset timing
    smpRst      resd    1                                                       ;Ratio adjustment reset counter

    ;Storage buffers ------------------ [4740]
    mixBuf      resd    MIX_SIZE*4                                              ;Temporary mixing buffer (linear buffer)
    echoBuf     resd    ECHOBUF                                                 ;External echo memory, 240ms @ 192kHz (ring buffer)
    firBuf      resd    FIRBUF                                                  ;Unaltered echo samples fed into FIR filter (ring buffer)
                resw    FIRBUF                                                  ;   Triple buffer
    lowBufL1    resd    LOWBUF1                                                 ;BASS-BOOST buffer (Left)
    lowBufL2    resd    LOWBUF2
    lowBufR1    resd    LOWBUF1                                                 ;BASS-BOOST buffer (Right)
    lowBufR2    resd    LOWBUF2

    dspVarEP    resd    1                                                       ;Endpoint of DSP.asm variables


;===================================================================================================
;Code

%ifndef WIN32
SECTION .text ALIGN=256
%else
SECTION .text ALIGN=16
%endif


;===================================================================================================
;Calculate Power of e
;
;Desc:
;   Calculates e to the power of x by using the formula:
;
;    2^(x * log2(e))
;
;   Where 2^x is calculated by:
;
;    2^int(x) * 2^frac(x)
;
;In:
;   ST = x
;
;Out:
;   ST = e^x

PROC Exp

    FStCW   [ESP-4]                                                             ;Save control state
    FStCW   [ESP-8]                                                             ;Set FPU to truncate when rounding
    Or      byte [ESP-7],1100b
    FLdCW   [ESP-8]

    FLdL2e                                                                      ;                                   |x Log2(e)
    FMulP   ST1,ST                                                              ;                                   |x*Log2(e)

    FLd     ST                                                                  ;                                   |ex ex
    FRndInt                                                                     ;Get the integer portion            |ex floor(ex)

    FXch    ST1                                                                 ;                                   |iex ex
    FSub    ST,ST1                                                              ;Get the fractional portion         |iex ex-iex

    F2XM1                                                                       ;Compute 2^frac                     |iex pow(2,fex)-1
    FLd1                                                                        ;                                   |iex p 1
    FAddP   ST1,ST                                                              ;                                   |iex p+1

    FXch                                                                        ;Compute 2^int                      |f iex
    FLd1                                                                        ;                                   |f iex 1
    FScale                                                                      ;                                   |f iex 1<<iex
    FStp    ST1                                                                 ;                                   |f i

    FMulP   ST1,ST                                                              ;                                   |f*i

    FLdCW   [ESP-4]                                                             ;Restore control state

ENDP


;===================================================================================================
;Initialize DSP

PROC InitDSP
LOCALS ipD                                                                      ;Integer, positive, delta
USES ECX,EDX,EBX,ESI,EDI

    XOr     EAX,EAX                                                             ;Reset values so SetDSPOpt will create new ones
    Mov     [dspOpts],EAX
    Mov     [volSepar],EAX

    Dec     EAX
    Mov     [dspMix],AL
    Mov     [dspChn],AL
    Mov     [dspSize],AL
    Mov     [dspInter],AL
    Mov     [dspRate],EAX
    Mov     [smpRate],EAX

    Mov     EAX,10000h
    Mov     [efbct],EAX
    Mov     [volAmp],EAX
    Mov     [volAtten],EAX
    Mov     [volAdj],EAX

    Mov     dword [pitchBas],32000
    Mov     EAX,5Fh                                                             ;Always envelope is 75% when DSP_NOENV is enabled
    ShL     EAX,E_SHIFT
    Mov     [envVal],EAX

    Mov     EDI,mix                                                             ;Erase all mixer settings
    XOr     EAX,EAX
    Mov     ECX,256
    Rep     StoSD

    ;Build a look-up table for all possible expanded values in a BRR block.
    Mov     EDI,brrTab
    XOr     EBX,EBX                                                             ;EBX = Nybble to shift right by range
    Mov     CL,28                                                               ;ECX = Max range (+16 for 32-bit numbers)

    .Range:
        .Nybble:
            Mov     EAX,EBX                                                     ;EAX = Nybble >> Range
            SAR     EAX,CL
            And     EAX,~1                                                      ;All numbers used by DSP are even
            Mov     [EDI],EAX
            Add     EDI,4

        Add     EBX,10000000h                                                   ;Add 1 to uppermost nybble
        JNZ     short .Nybble

        Add     EDI,0C0h

    Dec     CL
    Cmp     CL,15
    JA      short .Range

    Mov     BL,3
    XOr     ECX,ECX

    .Invalid:
        XOr     EAX,EAX                                                         ;Positive nybbles turn into 0 when range > 12
        Mov     CL,8
        Rep     StoSD

        Mov     EAX,-4096                                                       ;Negative nybbles turn into -4096 when range > 12
        Mov     CL,8
        Rep     StoSD

        Add     EDI,0C0h

    Dec     BL
    JNZ     short .Invalid

    ;Build a look-up table to calculate a cubic spline with only four integer multiplies.
    ;The table is built from the following equation, simplified for s:
    ;
    ; y = ax^3 + bx^2 + cx + d
    ;
    ;     3 (s[0] - s[1]) - s[-1] + s[2]
    ; a = ------------------------------
    ;                   2
    ;
    ;                      5 s[0] + s[2]
    ; b = 2 s[1] + s[-1] - -------------
    ;                            2
    ;
    ;     s[1] - s[-1]
    ; c = ------------
    ;          2
    ;
    ; d = s[0]
    ;
    ;y is the return sample
    ;x is the delta from current sample
    ;s is a four sample array with [0] being the current sample

    FInit                                                                       ;Reset FPU, otherwise there'll be problems
    Mov     dword [ipD],0                                                       ;Start with a delta of 0 (calculate 256 points)

    Mov     EDI,cubicTab                                                        ;EDI->Cubic array                   |FPU Stack after execution
    .NextC:
        ;x1=(n/256)  x2=(n/256)^2  x3=(n/256)^3
        FILd    dword [ipD]                                                     ;Load (int) delta                   |D
        FMul    dword [fpShR8]                                                  ;Divide delta by 256                |D/256=X1
        FLd     ST                                                              ;Copy top of stack                  |X1 X1
        FMul    ST,ST1                                                          ;Square point                       |X1 X1*X1=X2
        FLd     ST                                                              ;                                   |X1 X2 X2
        FMul    ST,ST2                                                          ;Cube point                         |X1 X2 X2*X1=X3

        ;s[-1] *= -.5(x^3) + (x^2) - .5x ------
        FLd     dword [fn0_5]                                                   ;                                   |X1 X2 X3 -0.5
        FMul    ST,ST3                                                          ;                                   |X1 X2 X3 -0.5*X1=T1
        FAdd    ST,ST2                                                          ;                                   |X1 X2 X3 T1+X2
        FLd     dword [fn0_5]                                                   ;                                   |X1 X2 X3 T1 -0.5
        FMul    ST,ST2                                                          ;                                   |X1 X2 X3 T1 -0.5*X3=T2
        FAddP   ST1,ST                                                          ;                                   |X1 X2 X3 T1+T2
        FMul    dword [fp32km1]                                                 ;Convert to fixed point (-.15)      |X1 X2 X3 (T1+T2)*32767
        FIStP   word [EDI]                                                      ;Store value in cubicTab            |X1 X2 X3

        ;s[0] *= 1.5(x^3) - 2.5(x^2) + 1 ------
        FLd     dword [fn2_5]                                                   ;                                   |X1 X2 X3 -2.5
        FMul    ST,ST2                                                          ;                                   |X1 X2 X3 -2.5*X2=T1
        FLd     dword [fp1_5]                                                   ;                                   |X1 X2 X3 T1 1.5
        FMul    ST,ST2                                                          ;                                   |X1 X2 X3 T1 1.5*X3=T2
        FLd1                                                                    ;                                   |X1 X2 X3 T1 T2 1.0
        FAddP   ST1,ST                                                          ;                                   |X1 X2 X3 T1 T2+1
        FAddP   ST1,ST                                                          ;                                   |X1 X2 X3 T1+T2
        FMul    dword [fp32km1]                                                 ;                                   |X1 X2 X3 (T1+T2)*32767
        FIStP   word [2+EDI]                                                    ;                                   |X1 X2 X3

        ;s[1] *= -1.5(x^3) + 2(x^2) + .5x -----
        FLd     dword [fp0_5]                                                   ;                                   |X1 X2 X3 0.5
        FMul    ST,ST3                                                          ;                                   |X1 X2 X3 0.5*X1=T1
        FLd     ST2                                                             ;                                   |X1 X2 X3 T1 X2
        FAdd    ST,ST3                                                          ;                                   |X1 X2 X3 T1 X2+X2=T2
        FLd     dword [fn1_5]                                                   ;                                   |X1 X2 X3 T1 T2 -1.5
        FMul    ST,ST3                                                          ;                                   |X1 X2 X3 T1 T2 -1.5*X3=T3
        FAddP   ST1,ST                                                          ;                                   |X1 X2 X3 T1 T2+T3
        FAddP   ST1,ST                                                          ;                                   |X1 X2 X3 T1+T2
        FMul    dword [fp32km1]                                                 ;                                   |X1 X2 X3 (T1+T2)*32767
        FIStP   word [4+EDI]                                                    ;                                   |X1 X2 X3

        ;s[2] *= .5(x^3) - .5(x^2) ------------
        FLd     dword [fn0_5]                                                   ;                                   |X1 X2 X3 -0.5
        FMul    ST,ST2                                                          ;                                   |X1 X2 X3 -0.5*X2=T1
        FLd     dword [fp0_5]                                                   ;                                   |X1 X2 X3 T1 0.5
        FMul    ST,ST2                                                          ;                                   |X1 X2 X3 T1 0.5*X3=T2
        FAddP   ST1,ST                                                          ;                                   |X1 X2 X3 T1+T2
        FMul    dword [fp32km1]                                                 ;                                   |X1 X2 X3 (T1+T2)*32767
        FIStP   word [6+EDI]                                                    ;                                   |X1 X2 X3
        Add     EDI,8

        FStP    ST                                                              ;Pop X's off stack                  |X1 X2
        FStP    ST                                                              ;                                   |X1
        FStP    ST                                                              ;                                   |(empty)

    Inc     byte [ipD]
    JNZ     .NextC

    ;Interleave Gaussian table ---------------
    Mov     ESI,gaussTab
    Mov     EDI,mixBuf
    Mov     ECX,512
    Rep     MovSD
    Mov     ESI,mixBuf
    Mov     EDI,gaussTab

    XOr     CL,CL
    .NextG:
        Mov     AX,[ESI]
        Mov     [6+EDI],AX
        Mov     AX,[512+ESI]
        Mov     [4+EDI],AX
        Mov     AX,[1024+ESI]
        Mov     [2+EDI],AX
        Mov     AX,[1536+ESI]
        Mov     [0+EDI],AX
        Add     EDI,8
        Add     ESI,2

    Dec     CL
    JNZ     short .NextG

    ;Build a look-up table for 8-point sinc interpolation with a Hanning window.
    ;
    ;  sin(4pi x)
    ;  ---------- * (0.5 + 0.5cos(pi x))
    ;    4pi x

    Mov     EDI,sincTab
    XOr     EAX,EAX                                                             ;If ipD were initialized to -768 (-3.0), a divide by
    Mov     [EDI],EAX                                                           ; zero error would occur when building the table.
    Mov     [4+EDI],EAX                                                         ; So we manually initialize the first row, which is
    Mov     [8+EDI],EAX                                                         ; easy to do.
    Mov     [12+EDI],EAX
    Mov     word [6+EDI],32767                                                  ;Set first row to 0 0 0 1 0 0 0 0
    Add     EDI,16
    Mov     dword [ipD],-769                                                    ;Fill remaining rows -769 to -1023 (-3.004 to -3.996)

    Mov     CH,255
    .NextS:
        Mov     CL,8
        .NextSS:
            FILd    dword [ipD]                                                 ;                                   |x
            FMul    dword [fpShR8]                                              ;(x >> 10) * 4pi                    |x>>8
            FLdPi                                                               ;                                   |x pi
            FMulP   ST1,ST                                                      ;                                   |x*pi
            FLd     ST                                                          ;                                   |x x

            FSin                                                                ;Sinc function                      |x sin(x)
            FDivRP  ST1,ST                                                      ;sin(x) / x                         |x/sin(x)

            FILd    dword [ipD]                                                 ;Hanning window                     |sinc x
            FMul    dword [fpShR10]                                             ;cos((x >> 10) * pi)                |sinc x>>10
            FLdPi                                                               ;                                   |sinc x pi
            FMulP   ST1,ST                                                      ;                                   |sinc x*pi
            FCos                                                                ;                                   |sinc cos(x*pi)
            FLd1                                                                ;(1.0 + cos) * 0.5                  |sinc cos 1.0
            FAddP   ST1,ST                                                      ;                                   |sinc cos+1.0
            FMul    dword [fp0_5]                                               ;                                   |sinc cos*0.5

            FMulP   ST1,ST                                                      ;Multiply by window                 |sinc*window
            FMul    dword [fp32k]                                               ;Convert to integer                 |sinc<<15
            FIStP   word [EDI]                                                  ;Store                              |(empty)
            Add     EDI,2

        Add     dword [ipD],256                                                 ;Move to next point of interpolation (x += 256)
        Dec     CL
        JNZ     .NextSS

    Sub     dword [ipD],801h
    Dec     CH
    JNZ     .NextS

    ;Build a look-up table for 4-point Gaussian interpolation.
    ;
    ;                                2
    ;       ____               (x/pi)
    ;     \| 2pi * (2^15)    - -------
    ; y = --------------- * e     2
    ;            4

    Mov     dword [ipD],-512
    Mov     EDI,gauss4Tab                                                       ;EDI->Gauss array                   |FPU Stack after execution
    FLd     dword [fpA]                                                         ;(sqrt(2 * pi) * 32768) / 4         |A = 20534.29882577715611578994921317
    FLd     dword [fp512]                                                       ;                                   |A 512
    FLdPi                                                                       ;                                   |A 512 3.14
    FDivP   ST1,ST                                                              ;                                   |A 512/3.14
    FLd     dword [fp256]                                                       ;Load 256 into FPU                  |A pi 256.0

    .NextG4:
        FILd    dword [ipD]                                                     ;Load (int) delta                   |A pi 256 x

        FLd     ST                                                              ;                                   |A pi 256 x x
        FDiv    ST,ST3                                                          ;                                   |A pi 256 x x/pi
        FMul    ST,ST                                                           ;                                   |A pi 256 x p^2
        FMul    dword [fpShR1]                                                  ;                                   |A pi 256 x p/2
        FChS                                                                    ;                                   |A pi 256 x -p
        Call    Exp                                                             ;                                   |A pi 256 x e^p
        FMul    ST,ST4                                                          ;                                   |A pi 256 x e*A
        FIStP   word [6+EDI]                                                    ;                                   |A pi 256 x

        FAdd    ST,ST1                                                          ;                                   |A pi 256 x+256
        FLd     ST                                                              ;                                   |A pi 256 x x
        FDiv    ST,ST3                                                          ;                                   |A pi 256 x x/pi
        FMul    ST,ST                                                           ;                                   |A pi 256 x p^2
        FMul    dword [fpShR1]                                                  ;                                   |A pi 256 x p/2
        FChS                                                                    ;                                   |A pi 256 x -p
        Call    Exp                                                             ;                                   |A pi 256 x e^p
        FMul    ST,ST4                                                          ;                                   |A pi 256 x e*A
        FIStP   word [4+EDI]                                                    ;                                   |A pi 256 x

        FAdd    ST,ST1                                                          ;                                   |A pi 256 x+256
        FLd     ST                                                              ;                                   |A pi 256 x x
        FDiv    ST,ST3                                                          ;                                   |A pi 256 x x/pi
        FMul    ST,ST                                                           ;                                   |A pi 256 x p^2
        FMul    dword [fpShR1]                                                  ;                                   |A pi 256 x p/2
        FChS                                                                    ;                                   |A pi 256 x -p
        Call    Exp                                                             ;                                   |A pi 256 x e^p
        FMul    ST,ST4                                                          ;                                   |A pi 256 x e*A
        FIStP   word [2+EDI]                                                    ;                                   |A pi 256 x

        FAdd    ST,ST1                                                          ;                                   |A pi 256 x+256
        FDiv    ST,ST2                                                          ;                                   |A pi 256 x/pi
        FMul    ST,ST                                                           ;                                   |A pi 256 p^2
        FMul    dword [fpShR1]                                                  ;                                   |A pi 256 p/2
        FChS                                                                    ;                                   |A pi 256 -p
        Call    Exp                                                             ;                                   |A pi 256 e^p
        FMul    ST,ST3                                                          ;                                   |A pi 256 e*A
        FIStP   word [EDI]                                                      ;                                   |A pi 256

        Add     EDI,8

    Inc     byte [ipD]
    JNZ     .NextG4

    FStP    ST                                                                  ;                                   |A pi
    FStP    ST                                                                  ;                                   |A
    FStP    ST                                                                  ;                                   |(empty)

    Call    SetDSPOpt,1,2,16,32000,INT_GAUSS,0
    Call    SetDSPDbg,0

ENDP


;===================================================================================================
;Erase echo filter memory

PROC ResetEcho

    XOr     EAX,EAX

    Mov     EDI,echoBuf
    Mov     ECX,ECHOBUF
    Rep     StoSD

    Mov     EDI,firBuf
    Mov     ECX,FIRBUF
    Add     ECX,FIRBUF/2
    Rep     StoSD

ENDP


;===================================================================================================
;Erase BASS-BOOST memory

PROC ResetLow

    XOr     EAX,EAX

    Mov     EDI,lowBufL1
    Mov     ECX,LOWLEN1
    Rep     StoSD
    Mov     EDI,lowRstL1
    Mov     ECX,LOWLEN2
    Rep     StoSD
    Inc     dword [lowRstL1]
    Inc     dword [lowRstL2]
    Inc     dword [lowRstR1]
    Inc     dword [lowRstR2]

    Mov     EDI,aafBufL
    Mov     ECX,6
    Rep     StoSD

ENDP


;===================================================================================================
;Erase sampling rate converter memory

PROC ResetResamp

    Mov     EAX,[smpDen]
    Mov     [smpRst],EAX

    XOr     EAX,EAX

    Mov     [smpSize],EAX
    Mov     [smpCur],EAX
    Mov     [smpCnt],EAX

    Mov     EDI,smpBuf
    Mov     ECX,8
    Rep     StoSD

ENDP


;===================================================================================================
;Reset master and echo volume

PROC ResetVol

    Mov     EAX,[volMainL]
    Mov     [nowMainL],EAX
    Mov     EAX,[volMainR]
    Mov     [nowMainR],EAX
    Mov     EAX,[volEchoL]
    Mov     [nowEchoL],EAX
    Mov     EAX,[volEchoR]
    Mov     [nowEchoR],EAX

ENDP


;===================================================================================================
;Reset DSP Settings

PROC ResetDSP
USES ECX,EBX,EDI

    XOr     EAX,EAX

    ;Erase DSP Registers ---------------------
    Mov     EDI,dsp
    Mov     ECX,32
    Rep     StoSD
    Mov     byte [dsp+flg],0E0h                                                 ;Place DSP in power up mode

    ;Erase internal mixing settings ----------
    Mov     BH,8
    Mov     EDI,mix

    .ClrMix:
        Mov     BL,[EDI+mFlg]
        And     BL,MFLG_USER                                                    ;Leave user voice flags (mute and noise)
        Or      BL,MFLG_OFF                                                     ;Set voice to inactive

        Mov     CL,32
        Rep     StoSD
        Mov     [EDI-80h+mFlg],BL

    Dec     BH
    JNZ     short .ClrMix

    ;Erase global volume settings ------------
    Mov     [volMainL],EAX
    Mov     [volMainR],EAX
    Mov     [volEchoL],EAX
    Mov     [volEchoR],EAX

    ;Erase noise settings --------------------
    Mov     [nRate],EAX
    Mov     [nAcc],EAX
    Mov     [nSmp],EAX
    Mov     dword [nSeed],1

    ;Erase echo settings --------------------
    Mov     [echoDecM],EAX                                                      ;Reset echo variables
    Mov     [echoFB],EAX
    Mov     [echoFBCT],EAX
    Mov     EAX,4
    Mov     [echoLenM],EAX                                                      ;Minimum value of echoLenM is 4byte (16-bit, stereo)
    Mov     [echoMaxM],EAX
    Mov     [echoCurM],EAX
    Add     EAX,EAX
    Mov     [echoLenD],EAX                                                      ;Minimum value of echoLenD is 8byte (32-bit, stereo)
    Mov     [echoMaxD],EAX
    Mov     [echoCurD],EAX

    Call    ResetVol
    Call    ResetEcho
    Call    ResetLow
    Call    ResetResamp

    Mov     EDI,firTaps                                                         ;Reset filter coefficients
    Mov     CL,8
    Rep     StoSD
    Mov     [firCur],EAX                                                        ;Reset filter variables

    ;Disable voices --------------------------
    Mov     [voiceMix],AL
    Mov     [vMMaxL],EAX
    Mov     [vMMaxR],EAX

    ;Reset times -----------------------------
    Mov     [outLeft],EAX
    Mov     [outCnt],EAX
    Mov     [outDec],EAX
    Mov     [dspPMod],EAX                                                       ;Clear dspPMod, dspNoise, dspNoiseF, dspMute
    Mov     [disFlag],EAX                                                       ;Clear disFlag, konRsv, koffRsv, konRun
    Mov     [envFlag],EAX                                                       ;Clear envFlag
    Mov     [adsrClk],EAX                                                       ;Clear adsrClk, adsrCnt
    Mov     dword [songLen],-1
    Mov     dword [fadeLen],1

    ;Reset noise settings (user) ------
    Mov     [nfAcc],EAX
    Mov     [nfSmp],EAX
    Mov     EAX,-1
    Mov     EDX,65535
    Div     dword [31*4+rateTab]
    Mov     [nfRate],EAX

    ;Reset fade volume -----------------------
    Call    SetDSPVol,10000h

ENDP


;===================================================================================================
;Set DSP Options

PROC SetDSPOpt, mixType, numChn, bits, rate, inter, opts
LOCALS fixVol
USES ALL

    XOr     EAX,EAX
    Mov     [fixVol],EAX

    ;=========================================
    ;Verify parameters

    ;mixType ---------------------------------
    MovZX   EAX,byte [dspMix]
    Mov     EDX,[mixType]
    Cmp     EDX,-1
    JE      short .DefMix
        XOr     EAX,EAX
        Test    EDX,EDX
        SetNZ   AL

    .DefMix:
    Mov     [mixType],EAX

    ;numChn ----------------------------------
    MovZX   EAX,byte [dspChn]
    Mov     EDX,[numChn]
    Cmp     EDX,-1
    JE      short .DefChn
        Mov     EAX,EDX

        Cmp     EDX,1
        JE      short .DefChn
        Cmp     EDX,2
        JE      short .DefChn
;       Cmp     EDX,4
;       JE      short .DefChn

        Mov     EAX,2

    .DefChn:
    Mov     [numChn],EAX

    ;bits ------------------------------------
    MovZX   EAX,byte [dspSize]
    Mov     EDX,[bits]
    Cmp     EDX,-1
    JE      short .DefBits
        Mov     EAX,EDX
        SAR     EAX,3

        Cmp     EDX,8
        JE      short .DefBits
        Cmp     EDX,16
        JE      short .DefBits
        Cmp     EDX,24
        JE      short .DefBits
        Cmp     EDX,32
        JE      short .DefBits
        Cmp     EDX,-32
        JE      short .DefBits

        Mov     EAX,2

    .DefBits:
    Mov     [bits],EAX

    ;rate ------------------------------------
    Mov     EAX,[smpRate]
    Mov     EDX,[rate]
    Cmp     EDX,-1
    JE      short .DefRate
        Mov     EAX,EDX
        XOr     ECX,ECX

        Cmp     EDX,8000
        SetB    CL
        Cmp     EDX,192000
        SetA    CH
        Test    ECX,ECX
        JZ      short .DefRate

        Mov     EAX,32000

    .DefRate:
    Mov     [rate],EAX

    ;inter -----------------------------------
    MovZX   EAX,byte [dspInter]
    Mov     EDX,[inter]
    Cmp     EDX,-1
    JE      short .DefInter
        Mov     EAX,EDX
        Cmp     EDX,7
        JBE     short .DefInter

        Mov     EAX,3

    .DefInter:
    Mov     [inter],EAX

    ShL     EAX,2
    Mov     ESI,[tabRout+EAX]
    Test    ESI,ESI
    JZ      short .NoCopyTable
        Mov     EDI,interTab
        Mov     ECX,1024
        Rep     MovSD

    .NoCopyTable:

    ;opts ------------------------------------
    Mov     EDX,[dspOpts]
    Mov     EAX,[opts]
    Cmp     EAX,-1
    JE      short .DefOpts
        Mov     EDX,EAX

    .DefOpts:
    Mov     [opts],EDX

    ;=========================================
    ;Options

    ;Select ADPCM routine --------------------
    Mov     dword [pDecomp],UnpckSrc
    Test    EDX,DSP_OLDSMP
    JZ      short .NewSmp
        Mov     dword [pDecomp],UnpckSrcOld

    .NewSmp:

    ;DSP option adjustment -------------------
    Mov     ECX,[dspOpts]
    XOr     ECX,EDX                                                             ;ECX = Changed DSP flags
    Mov     [dspOpts],EDX                                                       ;Save option flags

    Test    ECX,DSP_ECHOFIR                                                     ;If the DSP_ECHOFIR flag changes, force sampling rate
    SetZ    AL                                                                  ; processing (smpRate = -1)
    MovZX   EAX,AL
    Dec     EAX
    Or      [smpRate],EAX

    And     ECX,DSP_SURND+DSP_NOSURND+DSP_REVERSE                               ;If surround/reverse flag changes, reset volume settings
    SetNZ   AL
    Or      [fixVol+0],AL

    Cmp     byte [numChn],1
    SetE    AH

    Test    EDX,DSP_SURND                                                       ;If channel is 1, or surround is disabled,
    SetZ    AL                                                                  ; then surround equals 0x00, else 0xFF
    Or      AL,AH
    Dec     AL
    Mov     [surround],AL

    Test    EDX,DSP_NOSURND                                                     ;If channel is 1, or surround is disabled,
    SetNZ   AL                                                                  ; then surroff equals 0x80, else 0x00
    Or      AL,AH
    ShL     AL,7
    Mov     [surroff],AL

    Test    EDX,DSP_NOECHO                                                      ;If echo is disable, clear echo buffer
    SetNZ   AL
    Or      [fixVol+1],AL

    Test    EDX,DSP_BASS                                                        ;If BASS BOOST is disable, clear BASS-BOOST buffer
    SetZ    AL
    Or      [fixVol+2],AL

    ;=========================================
    ;Interpolation method

    MovZX   EAX,byte [inter]                                                    ;Save interpolation type
    Mov     [dspInter],AL

    MovZX   EDX,byte [mixType]                                                  ;If mixType != MIX_NONE
    Test    EDX,EDX
    JZ      short .NoMix
        Mov     EAX,[EAX*4+intRout]
        Mov     [pInter],EAX

    .NoMix:

    ;=========================================
    ;Calculate sample rate change

    Mov     EAX,[rate]
    Cmp     EAX,[smpRate]                                                       ;Has sample rate changed?
    JE      .SameRate                                                           ;   No
        Mov     [smpRate],EAX                                                   ;smpRate,dspRate = rate
        XOr     EDX,EDX                                                         ;smpAdj = 0

%if INTBK
        Test    dword [dspOpts],DSP_ECHOFIR                                     ;Is actual emulation mode?
        JZ      short .SMPROK                                                   ;   No

        Cmp     EAX,32000                                                       ;Is the sampling rate less than 32kHz?
        JBE     short .SMPROK                                                   ;   Yes
            Mov     EAX,32000                                                   ;EAX = Least common multiple of 32000 and smpRate
            Mov     ECX,[smpRate]

            .LoopGCM:
            XOr     EDX,EDX
            Div     ECX
            Mov     EAX,ECX
            Test    EDX,EDX
            JZ      short .ExitGCM
                Mov     ECX,EDX
                Jmp     short .LoopGCM

            .ExitGCM:
            Mov     ECX,EAX                                                     ;smpDen = Reduced denominator of 32000 / smpRate
            Mov     EAX,[smpRate]
            Div     ECX
            Mov     [smpDen],EAX

            Mov     EDX,32000                                                   ;smpAdj = 32000 * (2^32) / smpRate
            Mov     ECX,[smpRate]
            XOr     EAX,EAX
            Div     ECX
            Mov     EDX,EAX

            Mov     EAX,32000                                                   ;dspRate = 32000
            Mov     ECX,[smpRate]
            Sub     ECX,EAX                                                     ;smpDec = smpRate - 32000
            Mov     [smpDec],ECX

        .SMPROK:
%endif

        Mov     [dspRate],EAX
        Mov     [smpAdj],EDX

        ;Calculate amount to adjust SPC pitch values
        XOr     EDX,EDX                                                         ;EDX:EAX = Base pitch << 20
        Mov     EAX,[pitchBas]
        ShLD    EDX,EAX,20
        ShL     EAX,20

        Div     dword [dspRate]
        Mov     [pitchAdj],EAX

        ;Calculate update rate for envelopes and noise
        Mov     ESI,freqTab
        Mov     EDI,rateTab
        Mov     EBX,32000
        Mov     ECX,31

        .CalcRT:
            Mov     EAX,[ECX*4+ESI]
            ShL     EAX,16
            Mul     dword [dspRate]
            Div     EBX

            Cmp     EAX,10000h
            JAE     short .RTOK
                Mov     EAX,10000h

            .RTOK:
            Mov     [ECX*4+EDI],EAX

        Dec     ECX
        JNZ     short .CalcRT
        Mov     [EDI],ECX

        ;Volume ramping rate ------------------
        Mov     dword [ESP-4],32000
        FILd    dword [ESP-4]
        FIDiv   dword [dspRate]
        FMul    dword [fpShR8]
        FSt     dword [volRamp1]
        FIMul   dword [volAmp]
        FStP    dword [volRamp2]

        ;Reset FIR info -----------------------
        XOr     EAX,EAX
        Mov     [firCur],EAX

        Mov     EAX,[dspRate]
        MovZX   EDX,word [2+dspRate]
        ShL     EAX,16
        Mov     ECX,32000
        Div     ECX
        Mov     [firRate],EAX                                                   ;firRate = (dspRate<<16) / 32kHz

        ;Adjust voice rates -------------------
        Mov     EBX,7*80h                                                       ;Adjust the current rates in each voice incase the
                                                                                ; sample rate is being changed during emulation
        .Voice:
            Mov     EAX,[EBX+mix+mOrgP]                                         ;Set pitch
            MovZX   EDX,byte [EBX+mix+mSrc]                                     ;EDX = Source
            Add     EAX,[scr700det+EDX*4]                                       ;EAX += Detune[EDX]

            Mul     dword [pitchAdj]
            ShRD    EAX,EDX,16
            AdC     EAX,0
            Mov     [EBX+mix+mRate],EAX

            MovZX   EDI,byte [EBX+mix+eRIdx]                                    ;Set envelope adjustment
            Mov     EAX,[EDI*4+rateTab]
            Mov     [EBX+mix+eRate],EAX
            Mov     [EBX+mix+eCnt],EAX

        Add     EBX,-80h
        JNS     short .Voice

        ;Adjust echo delay --------------------
        Call    REDl

        ;BASS-BOOST buffer level ---------
        FLd     dword [fpLowRt]                                                 ;Level = (fpLowRt / dspRate) * fpLowLv
        FIDiv   dword [dspRate]
        FMul    dword [fpLowLv1]
        FStP    dword [lowLv1]

        FLd     dword [fpLowRt]
        FIDiv   dword [dspRate]
        FMul    dword [fpLowLv2]
        FStP    dword [lowLv2]

        ;BASS-BOOST buffer size ----------
        FILd    dword [dspRate]                                                 ;Size = dspRate * fpLowBs * 4
        FMul    dword [fpLowBs1]
        FIStP   dword [lowSize1]
        ShL     dword [lowSize1],2

        FILd    dword [dspRate]
        FMul    dword [fpLowBs2]
        FIStP   dword [lowSize2]
        ShL     dword [lowSize2],2

        Or      dword [fixVol],-1                                               ;Force volumes to be recalculated

        ;Anti-Alies 1st filter ---------
        ;Omega * Delta-T (wdt) = (2 * PI * cut-off frequency) * (1 / dspRate)
        FLdPi                                                                   ;                                   |pi
        FAdd    ST,ST                                                           ;                                   |pi*2
        FMul    dword [fpAafCF1]                                                ;                                   |pi*2*cf=Omega
        FLd1                                                                    ;                                   |Omega 1
        FIDiv   dword [dspRate]                                                 ;                                   |Omega 1/dspRate=Delta-T
        FMulP   ST1,ST                                                          ;                                   |Omega*Delta-T=wdt

        ;A0 = 1 (omit), A1 = (-2 + wdt) / (2 + wdt)
        FLd     ST                                                              ;                                   |wdt wdt
        Mov     dword [ESP-4],2
        FISub   dword [ESP-4]                                                   ;                                   |wdt -2+wdt
        FILd    dword [ESP-4]                                                   ;                                   |wdt -2+wdt 2
        FAdd    ST,ST2                                                          ;                                   |wdt -2+wdt 2+wdt
        FDivP   ST1,ST                                                          ;                                   |wdt -2+wdt/2+wdt
        FStP    dword [aaf1A1]                                                  ;                                   |wdt

        ;B0 = B1 = wdt / (2 + wdt)
        Mov     dword [ESP-4],2
        FILd    dword [ESP-4]                                                   ;                                   |wdt 2
        FAdd    ST,ST1                                                          ;                                   |wdt 2+wdt
        FDivP   ST1,ST                                                          ;                                   |wdt/2+wdt
        FSt     dword [aaf1B0]                                                  ;                                   |wdt/2+wdt
        FStP    dword [aaf1B1]                                                  ;                                   |(empty)

        ;Anti-Alies 2nd filter ---------
        ;Omega * Delta-T (wdt) = (2 * PI * cut-off frequency) * (1 / dspRate)
        FLdPi                                                                   ;                                   |pi
        FAdd    ST,ST                                                           ;                                   |pi*2
        FMul    dword [fpAafCF2]                                                ;                                   |pi*2*cf=Omega
        FLd1                                                                    ;                                   |Omega 1
        FIDiv   dword [dspRate]                                                 ;                                   |Omega 1/dspRate=Delta-T
        FMulP   ST1,ST                                                          ;                                   |Omega*Delta-T=wdt

        ;A0 = 1 (omit), A1 = (-2 + wdt) / (2 + wdt)
        FLd     ST                                                              ;                                   |wdt wdt
        Mov     dword [ESP-4],2
        FISub   dword [ESP-4]                                                   ;                                   |wdt -2+wdt
        FILd    dword [ESP-4]                                                   ;                                   |wdt -2+wdt 2
        FAdd    ST,ST2                                                          ;                                   |wdt -2+wdt 2+wdt
        FDivP   ST1,ST                                                          ;                                   |wdt -2+wdt/2+wdt
        FStP    dword [aaf2A1]                                                  ;                                   |wdt

        ;B0 = B1 = wdt / (2 + wdt)
        Mov     dword [ESP-4],2
        FILd    dword [ESP-4]                                                   ;                                   |wdt 2
        FAdd    ST,ST1                                                          ;                                   |wdt 2+wdt
        FDivP   ST1,ST                                                          ;                                   |wdt/2+wdt
        FSt     dword [aaf2B0]                                                  ;                                   |wdt/2+wdt
        FStP    dword [aaf2B1]                                                  ;                                   |(empty)

    .SameRate:

    ;=========================================
    ;Set sample size

    Mov     AL,[bits]
    Cmp     AL,[dspSize]                                                        ;If the sample size has changed, CL = 1
    JE      short .SameBits
        Mov     [dspSize],AL

    .SameBits:

    ;=========================================
    ;Set number of channels

    Mov     AL,[numChn]
    Cmp     AL,[dspChn]                                                         ;If the number of channels has changed, CL = 1
    SetNE   CL
    Or      [fixVol+0],CL
    Mov     [dspChn],AL

    ;=========================================
    ;Update areas affected by the mix type

    Mov     AL,[mixType]
    Cmp     AL,[dspMix]
    JE      short .SameMix
        Mov     [dspMix],AL
        Or      dword [fixVol],-1                                               ;Force volumes to be recalculated

    .SameMix:

    ;=========================================
    ;Erase sample buffers

    Test    byte [fixVol+1],-1
    JZ      short .NoEraseBuf
        Call    ResetEcho

    .NoEraseBuf:
    Test    byte [fixVol+2],-1
    JZ      short .NoEraseLow
        Call    ResetLow

    .NoEraseLow:
    Test    byte [fixVol+3],-1
    JZ      short .NoEraseResamp
        Call    ResetResamp

    .NoEraseResamp:

    ;=========================================
    ;Fixup volume handlers

    Test    byte [fixVol+0],-1
    JZ      .Done
        ;Reinitialize registers ---------------
        XOr     EDX,EDX
        Mov     ECX,70h
        .NextVoice:
            LEA     EBX,[ECX+volL]
            Mov     AL,[ECX+dsp+volL]
            Call    InitReg
            Mov     EAX,[ECX*8+mix+mTgtL]
            Mov     [ECX*8+mix+mChnL],EAX

            LEA     EBX,[ECX+volR]
            Mov     AL,[ECX+dsp+volR]
            Call    InitReg
            Mov     EAX,[ECX*8+mix+mTgtR]
            Mov     [ECX*8+mix+mChnR],EAX

            LEA     EBX,[ECX+fc]
            Mov     AL,[ECX+dsp+fc]
            Call    InitReg

        Sub     CL,10h
        JNC     short .NextVoice

        Mov     EBX,mvolL
        Mov     AL,[dsp+mvolL]
        Call    InitReg

        Mov     EBX,mvolR
        Mov     AL,[dsp+mvolR]
        Call    InitReg

        Mov     EBX,evolL
        Mov     AL,[dsp+evolL]
        Call    InitReg

        Mov     EBX,evolR
        Mov     AL,[dsp+evolR]
        Call    InitReg

        Mov     EBX,efb
        Mov     AL,[dsp+efb]
        Call    InitReg

        Call    ResetVol

    .Done:

ENDP


;===================================================================================================
;Debug DSP

PROC SetDSPDbg, pTraceFunc
USES EDX

    Mov     EDX,[pTrace]

    Mov     EAX,[pTraceFunc]
    Cmp     EAX,-1
    JE      short .NoFunc
        Mov     [pTrace],EAX

    .NoFunc:
    Mov     EAX,EDX

ENDP


;===================================================================================================
;Fix DSP After Loading Saved State

PROC FixDSP
USES ALL

    ;Enable voices currently keyed on --------
    Mov     byte [voiceMix],0

    Mov     EBX,kon
    Mov     AL,[dsp+kon]
    Call    InitReg

    ;Setup global paramaters -----------------
    Mov     EBX,mvolL
    Mov     AL,[dsp+mvolL]
    Call    InitReg

    Mov     EBX,mvolR
    Mov     AL,[dsp+mvolR]
    Call    InitReg

    Mov     EBX,evolL
    Mov     AL,[dsp+evolL]
    Call    InitReg

    Mov     EBX,evolR
    Mov     AL,[dsp+evolR]
    Call    InitReg

    Mov     EBX,flg
    Mov     AL,[dsp+flg]
    Call    InitReg

    Mov     EBX,efb
    Mov     AL,[dsp+efb]
    Call    InitReg

    Mov     EBX,edl
    Mov     AL,[dsp+edl]
    Call    InitReg

    Mov     ECX,70h
    .NextTap:
        LEA     EBX,[ECX+volL]
        Mov     AL,[ECX+dsp+volL]
        Call    InitReg
        Mov     EAX,[ECX*8+mix+mTgtL]
        Mov     [ECX*8+mix+mChnL],EAX

        LEA     EBX,[ECX+volR]
        Mov     AL,[ECX+dsp+volR]
        Call    InitReg
        Mov     EAX,[ECX*8+mix+mTgtR]
        Mov     [ECX*8+mix+mChnR],EAX

        LEA     EBX,[ECX+fc]
        Mov     AL,[ECX+dsp+fc]
        Call    InitReg

    Sub     CL,10h
    JNC     short .NextTap

    Call    ResetVol

%if INTBK && DSPINTEG
    Call    ResetKON
%endif

ENDP


;===================================================================================================
;Fix DSP After Seeking

PROC FixSeek, reset
USES ECX,EDI

    Mov     AL,[reset]
    Test    AL,AL
    JZ      .NoReset
        ;Turn off all voices ------------------
        Mov     AL,[dsp+kon]                                                    ;Mark all playing voices as ended
        Mov     [dsp+endx],AL

        XOr     EAX,EAX
        Mov     [dsp+kon],AL                                                    ;Reset key registers
        Mov     [dsp+kof],AL
        Mov     [voiceMix],AL
        Mov     [konRsv],AX                                                     ;Reset konRsv, koffRsv

        Mov     CL,8
        Mov     EDI,mix

        .ResetMix:
            Mov     [EDI+eVal],EAX
            Mov     [EDI+mOut],EAX
            And     byte [EDI+mFlg],MFLG_USER                                   ;Leave user voice flags (mute and noise)
            Or      byte [EDI+mFlg],MFLG_OFF                                    ;Set voice to inactive
            Sub     EDI,-80h

        Dec     CL
        JNZ     short .ResetMix

        Mov     CL,8
        Mov     EDI,dsp

        .ResetDSP:
            Mov     [EDI+envx],AL
            Mov     [EDI+outx],AL
            Add     EDI,10h

        Dec     CL
        JNZ     short .ResetDSP

        Call    FixDSP

    .NoReset:
    Call    ResetEcho
    Call    ResetLow
;   Call    ResetResamp                                                         ;Do not reset because noise occurs by seek
    Call    SetFade

ENDP


;===================================================================================================
;DSP Pitch Adjustment

PROC SetDSPPitch, base
USES EDX,EBX

    ;Calculate amount to adjust SPC pitch values
    XOr     EDX,EDX
    Mov     EAX,[base]
    Mov     [pitchBas],EAX
    ShLD    EDX,EAX,20
    ShL     EAX,20

    Div     dword [dspRate]
    Mov     [pitchAdj],EAX

    ;Adjust voice rates to new pitch ---------
    Mov     EBX,7*80h                                                           ;Adjust the current rates in each voice incase the
    .Voice:                                                                     ; sample rate is being changed during emulation
        Mov     EAX,[EBX+mix+mOrgP]                                             ;Set pitch
        MovZX   EDX,byte [EBX+mix+mSrc]                                         ;EDX = Source
        Add     EAX,[scr700det+EDX*4]                                           ;EAX += Detune[EDX]

        Mul     dword [pitchAdj]
        ShRD    EAX,EDX,16
        AdC     EAX,0
        Mov     [EBX+mix+mRate],EAX

    Add     EBX,-80h
    JNS     short .Voice

ENDP


;===================================================================================================
;DSP Amplification

PROC SetDSPAmp, amp
USES ECX,EDX,EBX

    Mov     EAX,[amp]                                                           ;If amp < 0, amp = 0
    CDQ
    Not     EDX
    And     EAX,EDX

    Cmp     EAX,256
    JA      short .NewScale
        ShL     EAX,12

    .NewScale:
    Mov     [volAmp],EAX

    ;Multiply by volume ----------------------
    Mul     dword [volAtten]
    ShRD    EAX,EDX,16
    Mov     [volAdj],EAX

    ;Update global volumes -------------------
    Mov     EBX,mvolL
    Mov     AL,[dsp+mvolL]
    Call    InitReg

    Mov     EBX,mvolR
    Mov     AL,[dsp+mvolR]
    Call    InitReg

    Mov     EBX,evolL
    Mov     AL,[dsp+evolL]
    Call    InitReg

    Mov     EBX,evolR
    Mov     AL,[dsp+evolR]
    Call    InitReg

    FLd     dword [volRamp1]
    FIMul   dword [volAmp]
    FStP    dword [volRamp2]

    Call    ResetVol

ENDP


;===================================================================================================
;DSP Fade Volume

PROC SetDSPVol, vol
USES ECX,EDX,EBX

    Mov     EAX,[vol]                                                           ;If EAX < 0, EAX = 0
    CDQ
    Not     EDX
    And     EAX,EDX
    Mov     [volAtten],EAX
    Mul     dword [volAmp]
    ShRD    EAX,EDX,16
    Mov     [volAdj],EAX

    ;Update global volumes -------------------
    Mov     EBX,mvolL
    Mov     AL,[dsp+mvolL]
    Call    InitReg

    Mov     EBX,mvolR
    Mov     AL,[dsp+mvolR]
    Call    InitReg

    Mov     EBX,evolL
    Mov     AL,[dsp+evolL]
    Call    InitReg

    Mov     EBX,evolR
    Mov     AL,[dsp+evolR]
    Call    InitReg

    ;Call   ResetVol                                                            ;Don't call ResetVol to smooth fade-out

ENDP


;===================================================================================================
;Set Song Length

PROC SetDSPLength, song, fade
USES EDX

    Mov     EDX,[fade]
    XOr     EAX,EAX                                                             ;If fadeLen = 0, fadeLen = 1
    Test    EDX,EDX                                                             ;0 will cause a division error
    SetZ    AL
    Or      EDX,EAX
    Mov     [fadeLen],EDX

    Mov     EAX,[song]
    Add     EDX,EAX
    Mov     [songLen],EAX

    Cmp     EAX,[t64Cnt]                                                        ;If t64Cnt > songLen
    JB      short .SetFade
        Call    SetDSPVol,10000h
        RetN    EDX

    .SetFade:
        Push    EDX
        Call    SetFade                                                         ;If song is in fade mode, set fade volume
        Pop     EAX
;       Mov     EAX,EDX

ENDP


;===================================================================================================
;Set Fade Volume
;
;Calls SetDSPVol to fade the song out based on t64Cnt, songLen, and fadeLen.

PROC SetFade

    Mov     EAX,[t64Cnt]                                                        ;EAX = T64Cnt - songLen;
    Sub     EAX,[songLen]                                                       ;If T64Cnt <= songLen, do nothing
    JBE     .Done

    XOr     EDX,EDX                                                             ;If EAX >= fadeLen, call SetDSPVol(0)
    Cmp     EAX,[fadeLen]
    JAE     .SetVol

    Mov     [ESP-4],EAX                                                         ;EDX = 65536 - 65536 * sin(EAX / fadeLen * pi / 2)
    FILd    dword [ESP-4]                                                       ;                                   |EAX
    FIDiv   dword [fadeLen]                                                     ;                                   |EAX/fadeLen
    FLdPi                                                                       ;                                   |EAX/fadeLen pi
    FMulP   ST1,ST                                                              ;                                   |EAX/fadeLen*pi
    FMul    dword [fp0_5]                                                       ;                                   |EAX/fadeLen*pi/2=x
    FSin                                                                        ;                                   |sin(x)
    Mov     EDX,65536
    Mov     [ESP-4],EDX
    FILd    dword [ESP-4]                                                       ;                                   |sin(x) 65536
    FMul                                                                        ;                                   |sin(x)*65536
    FIStP   dword [ESP-4]                                                       ;                                   |(empty)
    Mov     EAX,[ESP-4]                                                         ;EAX = 65536 * sin(x)
    Sub     EDX,EAX                                                             ;EDX = 65536 - EAX

    .SetVol:
    Call    SetDSPVol,EDX                                                       ;SetDSPVol(EDX);

    .Done:

ENDP


;===================================================================================================
;Adjust Voice Volume for Stereo Separation
;
;A big nasty function to adjust the left and right channel volumes for stereo separation control
;
;In:
;   EBX = Indexes current voice

%if STEREO
;Channel separator for floating-point routines
PROC ChnSep
RVolL:
RVolR:
USES ECX,EBX

    ShR     EBX,3
    Mov     AL,[EBX+dsp+volL]
    Mov     DL,[EBX+dsp+volR]

    Test    dword [dspOpts],DSP_REVERSE                                         ;Swap left, right?
    JZ      short .NoReverse                                                    ;   No
        XChg    AL,DL
    .NoReverse:

    Test    AL,[surroff]
    SetZ    AH
    Dec     AH
    XOr     AL,AH
    Sub     AL,AH
    Mov     AH,[surroff]
    Cmp     AX,8080h
    SetE    AH
    Sub     AL,AH
    MovSX   EAX,AL

    Test    DL,[surroff]
    SetZ    DH
    Dec     DH
    XOr     DL,DH
    Sub     DL,DH
    Mov     DH,[surroff]
    Cmp     DX,8080h
    SetE    DH
    Sub     DL,DH
    MovSX   EDX,DL

    LEA     EBX,[EBX*8+mix]
    Mov     [EBX+mTgtL],EAX
    Mov     [EBX+mTgtR],EDX

    Cmp     EAX,EDX
    JE      .NoSep

    Mov     ECX,[volSepar]
    Test    ECX,ECX
    JZ      .NoSep

    FInit

    And     AL,80h                                                              ;Save sign bit of each volume
    And     DL,80h
    ShL     EAX,24
    ShL     EDX,24

    ;Convert left/right into vol/pan ---------
    FILd    dword [EBX+mTgtR]
    FMul    dword [fpShR7]
    FLd     ST
    FMul    ST,ST
    FILd    dword [EBX+mTgtL]
    FMul    dword [fpShR7]
    FMul    ST,ST
    FAddP   ST1,ST
    FSqrt
    FXch
    FAbs
    FDiv    ST,ST1
    FMul    ST,ST
    FSub    dword [fp0_5]

    ;Adjust panning --------------------------
    FLd     ST
    Test    byte [3+volSepar],80h
    JNZ     short .Center
        FSt     qword [ESP-8]
        FLd     dword [fp0_5]
        Test    byte [ESP-1],80h
        JZ      short .Right
            FChS
        .Right:
        FSubRP  ST1,ST

    .Center:
    FMul    dword [volSepar]
    FAddP   ST1,ST
    FLd     ST

    ;Convert vol/pan back into left/right ----
    FAdd    dword [fp0_5]
    FSqrt
    FMul    ST,ST2
    FStP    dword [EBX+mTgtR]
    Or      [EBX+mTgtR],EDX

    FSubR   dword [fp0_5]
    FSqrt
    FMulP   ST1,ST
    FStP    dword [EBX+mTgtL]
    Or      [EBX+mTgtL],EAX

    XOr     EAX,EAX
    RetN

.NoSep:
    FILd    dword [EBX+mTgtL]
    FMul    dword [fpShR7]
    FStP    dword [EBX+mTgtL]

    FILd    dword [EBX+mTgtR]
    FMul    dword [fpShR7]
    FStP    dword [EBX+mTgtR]

    XOr     EAX,EAX

ENDP
%endif


;===================================================================================================
;Set Stereo Separation

PROC SetDSPStereo, sep
USES EDX,EBX

%if STEREO
    Sub     dword [sep],32768                                                   ;Convert fixed point unsigned value to signed float
    FILd    dword [sep]
    FMul    dword [fpShR15]
    FStP    dword [volSepar]

    ;Update each voice with new separation ---
    Mov     EBX,7*80h

    .Float:
        Call    ChnSep
        Mov     EAX,[EBX+mix+mTgtL]
        Mov     EDX,[EBX+mix+mTgtR]
        Mov     [EBX+mix+mChnL],EAX
        Mov     [EBX+mix+mChnR],EDX

    Add     EBX,-80h
    JNS     short .Float
%endif

ENDP


;===================================================================================================
;Set Echo Stereo Separation

PROC SetDSPEFBCT, leak
USES EDX,EBX

    Mov     EAX,[leak]
    Add     EAX,32768                                                           ;Unsign crosstalk
    Mov     [efbct],EAX

    ;Update echo feedback --------------------
    Mov     EBX,efb
    Mov     AL,[dsp+efb]
    Call    InitReg

ENDP


;===================================================================================================
;Start Sound Source Decompression
;
;Called when a voice is keyed on to set up the internal data for waveform mixing and decompress the
;first block.
;
;In:
;   EBX-> mix[voice]
;   ESI-> dsp.voice[voice]
;
;Out:
;   nothing
;
;Destroys:
;   EAX,EDX

PROC StartSrc

    Push    ESI,EDI,EBP
    MovZX   EAX,byte [EBX+mSrc]                                                 ;EAX = Source
    Mov     AL,[scr700chg+EAX]                                                  ;AL = NoteChange[EAX]

    Mov     ESI,[pAPURAM]
    ShL     EAX,2
    Add     AH,[dsp+dir]                                                        ;EAX -> Source directory
    Mov     SI,[EAX+ESI]                                                        ;ESI -> First block of waveform
    LEA     EDI,[EBX+sBuf]                                                      ;EDI -> Uncompressed sample buffer
    Mov     [EBX+bCur],ESI                                                      ;Save physical pointers to wave data
    Mov     [EBX+sIdx],EDI

    ;Decompress first block ------------------
    Mov     AL,[ESI]
    Push    EBX
    Mov     [EBX+bHdr],AL                                                       ;Save block header
    MovSX   EDX,word [EBX+sP1]
    MovSX   EBX,word [EBX+sP2]
    Call    [pDecomp]
    Mov     EAX,EBX
    Pop     EBX
    Mov     [EBX+sP1],DX
    Mov     [EBX+sP2],AX

    ;Initialize interpolation ----------------
    XOr     EAX,EAX
    Mov     [EBX+sBuf-4],EAX
    Mov     [EBX+sBuf-8],EAX
    Mov     [EBX+sBuf-12],EAX
    Mov     [EBX+sBuf-16],EAX

    Cmp     byte [dspInter],2                                                   ;Is interpolation enabled?
    JB      short .NoInter
        Add     byte [EBX+sIdx],6                                               ;Update sample index

    .NoInter:
    Pop     EBP,EDI,ESI

ENDP


;===================================================================================================
;Start Envelope
;
;Called when a voice is keyed on to set up the internal data to begin envelope modification based on
;the values in ADSR/Gain.
;
;In:
;   EBX-> mix[voice]
;   ESI-> dsp.voice[voice]
;
;Out:
;   mix.e???       = correct values for envelope routine in mixer
;   dsp.voice.envx = 0
;
;Destroys:
;   EAX,EDX

PROC StartEnv
USES ESI

    XOr     EAX,EAX
    Mov     [EBX+eVal],EAX                                                      ;Envelope starts at 0
    Mov     [EBX+mOut],EAX
    Mov     [EBX+eRIdx],AL                                                      ;Reset envelope counter
    Mov     EDX,[rateTab]
    Mov     [EBX+eRate],EDX                                                     ;Reset rate of adjustment
    Mov     [EBX+eCnt],EDX
    Mov     [ESI+envx],AL                                                       ;Reset envelope height
    Mov     [ESI+outx],AL
    Mov     byte [EBX+eMode],E_ATT << 4                                         ;If envelope gets switched out of gain mode, start ADSR

    Test    byte [ESI+adsr],80h                                                 ;Is the envelope in ADSR mode?
    JZ      ChgGain                                                             ;   No, It's in gain mode

ChgAtt:
        Cmp     dword [EBX+eVal],D_MAX                                          ;Did envelope reach destination value?
        JGE     short .ChgDec                                                   ;   Yes, change decay mode

        Mov     byte [EBX+eMode],E_ATT                                          ;Set envelope mode to attack
        Mov     dword [EBX+eDest],D_MAX                                         ;Set destination to 1.0

        Mov     AL,byte [ESI+adsr]
        And     AL,0Fh
        Add     AL,AL                                                           ;Adjust AL to index rateTab
        Inc     AL
        Cmp     AL,1Fh                                                          ;Is there an attack?
        JE      short .NoAtt                                                    ;   Yes

        Mov     dword [EBX+eAdj],A_LIN                                          ;Set adjustment rate to linear
        Cmp     [EBX+eRIdx],AL
        JE      short .AttNext

        Mov     [EBX+eRIdx],AL
        Mov     EDX,[EAX*4+rateTab]                                             ;Set rate of adjustment
        Mov     [EBX+eRate],EDX
        Mov     [EBX+eCnt],EDX

    .AttNext:
        RetN                                                                    ;Exit

    .NoAtt:
        Mov     dword [EBX+eAdj],A_NOATT                                        ;Set adjustment rate to 1.0
        Cmp     [EBX+eRIdx],AL
        JE      short .AttNext

        Mov     [EBX+eRIdx],AL
        Mov     EDX,[EAX*4+rateTab]                                             ;Set rate of adjustment
        Mov     [EBX+eRate],EDX
        Mov     [EBX+eCnt],EDX

        RetN                                                                    ;Exit

    .ChgDec:
        MovZX   EAX,byte [EBX+eRIdx]
        Mov     EDX,[EAX*4+rateTab]                                             ;Set rate of adjustment
        Mov     [EBX+eRate],EDX
        Mov     [EBX+eCnt],EDX

ChgDec:
        Mov     AL,[ESI+adsr+1]                                                 ;Set destination to AL/8
        ShR     AL,5
        Inc     AL
;       Test    AL,8                                                            ;Is destination of envelope D_MAX?
;       JNZ     .ChgSus                                                         ;   Yes, change sustain mode

        IMul    EAX,D_EXP
        XOr     EDX,EDX                                                         ;Adjust value for internal precision
        Dec     EAX
        SetS    DL
        Add     EAX,EDX

        Cmp     byte [EBX+eMode],E_DECAY                                        ;If DR changes in the middle of DECAY,
        JNE     short .DecSkip                                                  ;   and DR is higher than current envelope value,
        Cmp     [EBX+eVal],EAX                                                  ;   does not change to sustain mode
        JGE     short .DecSkip

        Mov     dword [EBX+eDest],D_MIN                                         ;Destination to 0 instead of changing to sustain mode,
        Jmp     short .DecReset                                                 ;   prevents changing to sustain mode by UpdateEnv

    .DecSkip:
        Cmp     [EBX+eVal],EAX                                                  ;Did envelope reach destination value?
        JLE     short .ChgSus                                                   ;   Yes, change sustain mode

        Mov     dword [EBX+eAdj],A_EXP                                          ;Set adjustment rate to exponential
        Mov     byte [EBX+eMode],E_DECAY                                        ;Set envelope mode to decay
        Mov     [EBX+eDest],EAX

    .DecReset:
        MovZX   EAX,byte [ESI+adsr]
        And     AL,70h
        ShR     AL,3
        Add     AL,10h                                                          ;Adjust AL to index rateTab
        Cmp     [EBX+eRIdx],AL
        JE      short .DecNext

        Mov     [EBX+eRIdx],AL
        Mov     EDX,[EAX*4+rateTab]                                             ;Set rate of adjustment
        Mov     [EBX+eRate],EDX
        Mov     [EBX+eCnt],EDX

    .DecNext:
        RetN                                                                    ;Exit

    .ChgSus:
        MovZX   EAX,byte [EBX+eRIdx]
        Mov     EDX,[EAX*4+rateTab]                                             ;Set rate of adjustment
        Mov     [EBX+eRate],EDX
        Mov     [EBX+eCnt],EDX

ChgSus:
        Mov     dword [EBX+eAdj],A_EXP                                          ;Set adjustment rate to exponential
        Mov     dword [EBX+eDest],D_MIN                                         ;Set destination to 0

        Mov     AL,[ESI+adsr+1]
        Mov     AH,E_IDLE
        And     AL,1Fh                                                          ;Is index zero?
        JZ      short .SusNext                                                  ;   Yes, change idle mode

        Cmp     dword [EBX+eVal],D_MIN                                          ;Did envelope reach destination value?
        JLE     short .SusNext                                                  ;   Yes, change idle mode

        XOr     AH,AH
        Cmp     [EBX+eRIdx],AL
        JE      short .SusNext

        Mov     [EBX+eRIdx],AL
        Mov     EDX,[EAX*4+rateTab]
        Mov     [EBX+eRate],EDX                                                 ;Set rate of change
        Mov     [EBX+eCnt],EDX

    .SusNext:
        Or      AH,E_SUST
        Mov     [EBX+eMode],AH                                                  ;Set envelope mode to sustain
        RetN                                                                    ;Exit

ChgGain:
    Mov     AL,[ESI+gain]
    Test    AL,80h                                                              ;Is gain direct?
    JNZ     short .GainMode                                                     ;   No, Program envelope
        Mov     dword [EBX+eAdj],A_DIRECT                                       ;Set adjustment rate to 1.0

        And     AL,7Fh                                                          ;Isolate direct value
        Mov     EDX,EAX                                                         ;Adjust value for internal precision
        ShR     DL,7-E_SHIFT                                                    ;EAX = LEVEL * A_GAIN + LEVEL / 128 * A_GAIN
        ShL     EAX,E_SHIFT                                                     ; If LEVEL = 0x00, EAX = 0
        Add     EAX,EDX                                                         ; If LEVEL = 0x7F, EAX = D_MAX (128 * A_GAIN - 1)
        Mov     [EBX+eDest],EAX                                                 ;  EAX = 127 * A_GAIN + 127 / 128 * A_GAIN

        Mov     byte [EBX+eRIdx],31                                             ;Envelope is set
        Mov     ESI,[31*4+rateTab]
        Mov     [EBX+eRate],ESI
        Mov     [EBX+eCnt],ESI

        Mov     DL,[EBX+eMode]
        And     DL,70h
        Or      DL,E_DIRECT                                                     ;Set mode to direct
        Mov     [EBX+eMode],DL
        RetN

    .GainMode:
        Mov     DL,AL
        Mov     AH,E_IDLE
        And     AL,1Fh                                                          ;Is index zero?
        JZ      short .GainNext

        XOr     AH,AH
        Cmp     [EBX+eRIdx],AL
        JE      short .GainNext

        Mov     [EBX+eRIdx],AL
        Mov     ESI,[EAX*4+rateTab]
        Mov     [EBX+eRate],ESI                                                 ;Set rate of change
        Mov     [EBX+eCnt],ESI

    .GainNext:
        Mov     AL,[EBX+eMode]                                                  ;Preserve ADSR mode
        And     AL,70h
        Or      AL,AH

        Test    DL,60h                                                          ;Jump to the right mode
        JZ      short .GainDec
        Test    DL,40h
        JZ      short .GainExp
        Test    DL,20h
        JZ      short .GainInc

    .GainBent:
        Mov     dword [EBX+eAdj],A_LIN
        Mov     dword [EBX+eDest],D_BENT
        Or      AL,E_BENT                                                       ;Set mode to bent line increase
        Mov     [EBX+eMode],AL
        RetN

    .GainInc:
        Mov     dword [EBX+eAdj],A_LIN
        Mov     dword [EBX+eDest],D_MAX
        Or      AL,E_INC                                                        ;Set mode to linear increase
        Mov     [EBX+eMode],AL
        RetN

    .GainExp:
        Mov     dword [EBX+eAdj],A_EXP
        Mov     dword [EBX+eDest],D_MIN
        Or      AL,E_EXP                                                        ;Set mode to exponential decrease
        Mov     [EBX+eMode],AL
        RetN

    .GainDec:
        Mov     dword [EBX+eAdj],A_LIN
        Mov     dword [EBX+eDest],D_MIN
        Or      AL,E_DEC                                                        ;Set mode to linear decrease
        Mov     [EBX+eMode],AL
        RetN
ENDP


;===================================================================================================
;Change Envelope
;
;Called when the ADSR registers are written to while an envelope is in progress.  Control is
;transfered to StartEnv where the envelope is updated.
;
;In:
;   EBX = Voice << 4
;
;Destroys:
;   EAX,EDX,EBX

PROC ChgADSR

    Push    ESI                                                                 ;ESI will get popped on return from StartEnv
    LEA     ESI,[EBX+dsp]
    LEA     EBX,[EBX*8+mix]

    XOr     EAX,EAX
    Mov     DL,[EBX+eMode]
    And     DL,0Fh

    Cmp     DL,E_ATT                                                            ;If the envelope isn't in attack, decay, or sustain
    JE      ChgAtt                                                              ; mode, changes to the ADSR registers have no effect
    Cmp     DL,E_DECAY
    JE      ChgDec
    Cmp     DL,E_SUST
    JE      ChgSus

    Pop     ESI                                                                 ;No changes were made, pop ESI and return

ENDP


;===================================================================================================
;DSP Data Port

;--------------------------------------------
;External procedure for users of SNESAPU.DLL
;
;Out:
;   EAX = not 0: success, 0: failure

PROC SetDSPReg, dReg, dVal
USES ECX,EDX,EBX

    MovZX   EBX,byte [dReg]
    MovZX   EAX,byte [dVal]

    XOr     CL,CL                                                               ;CL = Don't emulate DSP
    Call    DSPInB                                                              ;Process register write without calling debug function

ENDP


;--------------------------------------------
;Internal procedure for initialzing DSP registers
;
;In:
;   EBX = DSP register number
;   AL  = Write value
;
;Out:
;   EAX = DSP register is enabled
;
;Destroys:
;   EBX,EDX

PROC InitReg
USES ECX

    XOr     CL,CL                                                               ;CL = Don't emulate DSP
    Call    DSPInC                                                              ;Process register regardless of current register value

ENDP


;--------------------------------------------
;Procedure for writing to the DSP from the SPC700
;
;In:
;   EBX = DSP register number
;   AL  = Write value
;
;Out:
;   EAX = DSP register is enabled
;
;Destroys:
;   EBX,EDX

PROC DSPIn

%if DEBUG
    Mov     EDX,[pTrace]
    Test    EDX,EDX
    JZ      short .NoDbg
        MovZX   EAX,AL
        Add     EBX,dsp

        Push    ECX,ESI,EDI                                                     ;Save these registers
        Push    EAX                                                             ;Pass these as parameters
        Push    EBX

        Call    EDX

        Pop     EBX
        Pop     EAX
        Pop     EDI,ESI,ECX

        MovZX   EBX,BL

    .NoDbg:
%endif

    Test    dword [apuCbMask],CBE_DSPREG
    JZ      short .NoCallback

    Mov     EDX,[apuCbFunc]
    Test    EDX,EDX
    JZ      short .NoCallback
    Test    BL,80h                                                              ;Writes to 80-FFh have no effect (reads are mirrored
    JNZ     short .NoCallback                                                   ; from lower mem)
        Push    ECX,EBX,EAX                                                     ;STDCALL is destroy EAX,ECX,EDX
        MovZX   EBX,BL
        MovZX   EAX,AL
        Call    EDX,dword CBE_DSPREG,EBX,EAX,dword 0
        Mov     BL,AL                                                           ;Copy overwrote value
        Pop     EAX
        Mov     AL,BL
        Pop     EBX,ECX

    .NoCallback:
    Mov     CL,1                                                                ;CL = Emulate DSP to catch up to current state

DSPInB:
    Test    BL,80h                                                              ;Writes to 80-FFh have no effect (reads are mirrored
    JNZ     DSPDone                                                             ; from lower mem)

    Cmp     BL,kon
    JE      RKOn
    Cmp     BL,kof                                                              ;Check for registers that can have duplicate data
    JE      RKOff                                                               ; written
    Cmp     BL,endx
    JE      REndX

    Cmp     AL,[EBX+dsp]                                                        ;Is the new data the same as the current data?
    JZ      short DSPDone                                                       ;   Yes, Don't bother updating

    Mov     [EBX+dsp],AL                                                        ;Update DSP RAM

DSPInC:
    Mov     EDX,[EBX*4+dspRegs]                                                 ;Get the pointer to the register handler

    Mov     AH,BL
    And     EBX,70h
    Not     AH
    ShL     EBX,3                                                               ;EBX indexes mix (needed by some handlers)
    And     AH,MFLG_OFF                                                         ;AH = 08h if the register is in dsp.voice

    Test    [EBX+mix+mFlg],AH                                                   ;Is the voice inactive?
    JNZ     short DSPDone                                                       ;   Yes, Don't bother updating

%if DSPBK && DSPINTEG
    Test    CL,CL                                                               ;If write was from SPC700, emulate DSP before
    JZ      short .NoOutput                                                     ; processing new register data
        Call    CatchUp

    .NoOutput:
%endif

    Jmp     EDX

DSPDone:
    XOr     EAX,EAX                                                             ;DSP state didn't change

ENDP


;===================================================================================================
;Emulate the KON/KOFF delay processing of DSP
;
;Destroys:
;   EAX,EBX,ECX,EDX

%macro CatchKOff 0
    ;KOff process ----------------------
    MovZX   ECX,byte [koffRsv]                                                  ;Set CH = 0 for use with CatchKOn
    Test    CL,CL
    JZ      short %%Done

    Push    ESI

    Mov     CH,1
    Mov     EBX,mix
    Mov     ESI,dsp
    Mov     EDX,[31*4+rateTab]
    XOr     EAX,EAX

    %%Next:
        Test    CL,CH
        JZ      short %%Skip

        Test    [voiceMix],CH                                                   ;Is voice currently playing?
        JZ      short %%Skip                                                    ;   No, do nothing

        Test    byte [EBX+mFlg],MFLG_KOFF                                       ;Is already voice in key off mode?
        JNZ     short %%Skip                                                    ;   Yes, do nothing
            Mov     byte [EBX+eRIdx],31                                         ;Place envelope in release mode
            Mov     [EBX+eRate],EDX
            Mov     [EBX+eCnt],EDX
            Mov     dword [EBX+eAdj],A_KOFF
            Mov     dword [EBX+eDest],D_MIN
            Mov     byte [EBX+eMode],E_REL
            Or      byte [EBX+mFlg],MFLG_KOFF                                   ;Flag voice as keying off
            Mov     [EBX+vRsv],AL                                               ;Reset ADSR/Gain changed flag
            Mov     [EBX+mKOn],AL                                               ;Reset delay time

        %%Skip:
        Add     ESI,10h
        Sub     EBX,-80h

    Add     CH,CH
    JNZ     %%Next

    Pop     ESI

    %%Done:
    Mov     [koffRsv],CH                                                        ;CH = 0
%endmacro

%macro CatchKOn 0
    ;KOn process -----------------------
    Mov     CL,[konRsv]
    Or      CL,[konRun]
    JZ      %%Done

    Push    ESI

    Mov     CL,[konRsv]
    Mov     CH,1
    Mov     EBX,mix
    Mov     ESI,dsp

    %%Next:
%if INTBK
        Test    byte [EBX+mKOn],-1                                              ;Is already voice in key on mode?
        JNZ     short %%CheckKOff                                               ;   Yes
            Test    CL,CH
            JZ      %%Skip

            XOr     EDX,EDX
            And     byte [EBX+mFlg],MFLG_USER                                   ;Leave user voice flags (mute and noise)
            Mov     byte [EBX+mKOn],KON_DELAY                                   ;Set delay time from writing KON to output
            Mov     [EBX+eVal],EDX                                              ;Reset envelope and wave height, because noise may be
            Mov     [EBX+mOut],EDX                                              ; mixed in when the channel volume is changed immediately
            Mov     [ESI+envx],DL                                               ; after KON.
            Mov     [ESI+outx],DL

            Or      [konRun],CH                                                 ;Start KON working
            Not     CH
            And     [dsp+endx],CH                                               ;Clear ENDX register if started KON
            Not     CH
            Jmp     %%Skip

        %%CheckKOff:
        Cmp     byte [EBX+mKOn],KON_CHKKOFF                                     ;Did time for checked KOFF after KON had been written?
        JA      short %%CheckEnv                                                ;   No

        Test    [dsp+kof],CH                                                    ;Is KOFF still written?
        JZ      short %%CheckEnv                                                ;   No
            Or      byte [EBX+mFlg],MFLG_KOFF                                   ;Flag voice as keying off
            Mov     byte [EBX+mKOn],0                                           ;Reset delay time

            Not     CH
            And     [konRun],CH                                                 ;Cancel KON working
            Not     CH
            Jmp     %%Skip

        %%CheckEnv:
        Cmp     byte [EBX+mKOn],KON_SAVEENV                                     ;Did time for saved envelope pass after KON had been
        JNE     short %%StartKON                                                ; written?  No
            Mov     DX,[ESI+adsr]                                               ;Save ADSR parameters
            Mov     [EBX+vAdsr],DX
            MovZX   DX,byte [ESI+gain]                                          ;Save Gain parameters
            Mov     [EBX+vGain],DL
            Mov     [EBX+vRsv],DH                                               ;Reset ADSR/Gain changed flag

        %%StartKON:
        Dec     byte [EBX+mKOn]                                                 ;Did time for enabled voice pass after KON had been
        JNZ     %%Skip                                                          ; written?  No, do nothing
            And     byte [EBX+mFlg],MFLG_USER                                   ;Leave user voice flags (mute and noise)
%else
        Test    CL,CH
        JZ      %%Skip
            XOr     EDX,EDX
            And     byte [EBX+mFlg],MFLG_USER                                   ;Leave user voice flags (mute and noise)
            Or      byte [EBX+mFlg],MFLG_KOFF                                   ;Flag voice as keying off
            Mov     [EBX+mKOn],DL                                               ;Start playing immediately

        Test    [dsp+kof],CH                                                    ;Is KOFF still written?
        JNZ     %%Skip                                                          ;   No
            And     byte [EBX+mFlg],~MFLG_KOFF                                  ;Cancel keying off flag

            Or      [konRun],CH                                                 ;Start KON working
            Not     CH
            And     [dsp+endx],CH                                               ;Clear ENDX register if started KON
            Not     CH

            Mov     DX,[ESI+adsr]                                               ;Save ADSR parameters
            Mov     [EBX+vAdsr],DX
            MovZX   DX,byte [ESI+gain]                                          ;Save Gain parameters
            Mov     [EBX+vGain],DL
            Mov     [EBX+vRsv],DH                                               ;Reset ADSR/Gain changed flag
%endif

            ;Set voice volume ------------------
%if STEREO
            Sub     EBX,mix
            Call    RVolL
            Add     EBX,mix
            Mov     EAX,[EBX+mTgtL]
            Mov     [EBX+mChnL],EAX
            Mov     EAX,[EBX+mTgtR]
            Mov     [EBX+mChnR],EAX
%else
            Sub     EBX,mix
            Mov     AL,[ESI+volL]
            Call    RVolL
            Mov     AL,[ESI+volR]
            Call    RVolR
            Add     EBX,mix
%endif

            ;Set pitch -------------------------
            MovZX   EAX,word [ESI+pitch]
            Test    dword [dspOpts],DSP_NOPLMT                                  ;If do not remove the pitch limit, the highest
            SetZ    DL                                                          ; pitch value is 3FFF
            Dec     DL
            Or      DL,3Fh
            And     AH,DL
            Mov     [EBX+mOrgP],EAX
            MovZX   EDX,byte [ESI+srcn]                                         ;EDX = Source
            Mov     [EBX+mSrc],DL                                               ;Save source number
            Add     EAX,[scr700det+EDX*4]                                       ;EAX += Detune[EDX]

            Mul     dword [pitchAdj]
            ShRD    EAX,EDX,16
            AdC     EAX,0
            Mov     [EBX+mRate],EAX
            Mov     word [EBX+mDec],0

            ;Key ON ----------------------------
            Mov     AX,[ESI+adsr]                                               ;Save now ADSR/Gain parameters
            Mov     DL,[ESI+gain]
            Push    EAX,EDX
            Mov     AX,[EBX+vAdsr]                                              ;Restore ADSR/Gain parameters
            Mov     [ESI+adsr],AX
            Mov     DL,[EBX+vGain]
            Mov     [ESI+gain],DL

            Call    StartSrc                                                    ;Start waveform decompression
            Call    StartEnv                                                    ;Start envelope

            Pop     EDX,EAX                                                     ;Restore ADSR/Gain parameters
            Mov     [ESI+adsr],AX
            Mov     [ESI+gain],DL

            Or      [voiceMix],CH                                               ;Mark voice as being on internally
            Not     CH
            And     [konRun],CH                                                 ;KON working was finished
            Not     CH

        %%Skip:
        Add     ESI,10h
        Sub     EBX,-80h

    Add     CH,CH
    JNZ     %%Next

    Pop     ESI                                                                 ;Now, CH = 0

    %%Done:
    Mov     [konRsv],CH
%endmacro


;===================================================================================================
;Set the Denormalized Numbers to 0
;
;Calculating denormalized numbers requires a many number of CPU clocks.  If the CPU does not support
;denormalized numbers, will take more processing time more because using software emulation.
;
;However, when it comes to audio data, denormalized numbers have very small outputs that are
;inaudible, so they can be treated as 0.
;
;Destroys:
;   EAX
%macro ZeroDN 1
    Mov     EAX,[%1]
    And     EAX,7F800000h                                                       ;Is the exponent part zero (denormalized)?
    JNZ     short %%Normal                                                      ;   No
        Mov     [%1],EAX                                                        ;EAX = 0

    %%Normal:
%endmacro

%macro ZeroDNEFB 1
    FLd     dword [%1]
    FMul    dword [fpShR19]
    FStP    dword [ESP-4]
    ZeroDN  ESP-4
%endmacro


;===================================================================================================
;DSP Register Handlers

;============================================
;End block decoded

REndX:
%if DSPBK && DSPINTEG
    Test    CL,CL                                                               ;If write was from SPC700, emulate DSP before
    JZ      short .NoOutput                                                     ; processing new register data
        Call    CatchUp
    .NoOutput:
%endif

    XOr     EAX,EAX
    Or      AL,[dsp+endx]
    Mov     [dsp+endx],AH                                                       ;Reset the ENDX register
    SetNZ   AL
    Ret

;============================================
;Key Off

RKOff:
%if DSPBK && DSPINTEG
    Test    CL,CL                                                               ;If write was from SPC700, emulate DSP before
    JZ      short .NoOutput                                                     ; processing new register data
        Call    CatchUp
    .NoOutput:
%endif

    MovZX   EAX,AL
    Mov     [dsp+kof],AL
    Mov     [koffRsv],AL

%if DSPBK && DSPINTEG
    Push    EAX,EBX,ECX,EDX
    CatchKOff
    Pop     EDX,ECX,EBX,EAX
%endif

    Ret

;============================================
;Key On

RKOn:
%if DSPBK && DSPINTEG
    Test    CL,CL                                                               ;If write was from SPC700, emulate DSP before
    JZ      short .NoOutput                                                     ; processing new register data
        Call    CatchUp
    .NoOutput:
%endif

    MovZX   EAX,AL
    Mov     [dsp+kon],AL
    Mov     [konRsv],AL

%if DSPBK && DSPINTEG
    Push    EAX,EBX,ECX,EDX
    Mov     CH,AH                                                               ;Set CH = 0 for use with CatchKOn
    CatchKOn
    Pop     EDX,ECX,EBX,EAX
%endif

    Ret

%if INTBK && DSPINTEG
ResetKON:
    XOr     CH,CH                                                               ;Set CH = 0 for use with CatchKOn
    CatchKOn
    Ret
%endif

;============================================
;Voice volume

%if STEREO=0
RVolL:
    Test    AL,[surroff]
    SetZ    AH
    Dec     AH
    XOr     AL,AH
    Sub     AL,AH
    Mov     AH,[surroff]
    Cmp     AX,8080h
    SetE    AH
    Sub     AL,AH
    MovSX   EAX,AL

    Mov     [ESP-4],EAX
    FILd    dword [ESP-4]
    FMul    dword [fpShR7]                                                      ;Convert volume from fixed to floating-point
    FSt     dword [EBX+mix+mTgtL]
    FStP    dword [EBX+mix+mChnL]

    XOr     EAX,EAX
    Inc     EAX
    Ret

RVolR:
    Test    AL,[surroff]
    SetZ    AH
    Dec     AH
    XOr     AL,AH
    Sub     AL,AH
    Mov     AH,[surroff]
    Cmp     AX,8080h
    SetE    AH
    Sub     AL,AH
    MovSX   EAX,AL

    Mov     [ESP-4],EAX
    FILd    dword [ESP-4]
    FMul    dword [fpShR7]
    FSt     dword [EBX+mix+mTgtR]
    FStP    dword [EBX+mix+mChnR]

    XOr     EAX,EAX
    Inc     EAX
    Ret
%endif

;============================================
;Pitch

RPitch:
    XOr     EAX,EAX
    Test    dword [dspOpts],DSP_NOPREAD                                         ;Is pitch read enabled?
    JNZ     short .NoRead                                                       ;   No
        ShR     EBX,3
        MovZX   EAX,word [EBX+dsp+pitch]
        Test    dword [dspOpts],DSP_NOPLMT                                      ;If do not remove the pitch limit, the highest
        SetZ    DL                                                              ; pitch value is 3FFF
        Dec     DL
        Or      DL,3Fh
        And     AH,DL
        ShL     EBX,3
        Mov     [EBX+mix+mOrgP],EAX

        MovZX   EDX,byte [EBX+mix+mSrc]                                         ;EDX = Source
        Add     EAX,[scr700det+EDX*4]                                           ;EAX += Detune[EDX]

        Mul     dword [pitchAdj]                                                ;Convert the pitch into a more meaningful value
        ShRD    EAX,EDX,16                                                      ;Remove 16-bit fraction from pitchAdj
        AdC     EAX,0
        Mov     [EBX+mix+mRate],EAX

        XOr     EAX,EAX
        Inc     EAX

    .NoRead:
    Ret

;============================================
;Envelope

RADSR:
    XOr     EAX,EAX
    Test    byte [EBX+mix+mFlg],MFLG_KOFF                                       ;Is voice in key off mode?
    JNZ     short .NoChg                                                        ;   Yes, Envelope setting can't be changed now

    Test    byte [EBX+mix+mKOn],-1
    SetNZ   AL
    Or      [EBX+mix+vRsv],AL
    Test    AL,AL                                                               ;Has time passed since KON was written?
    JNZ     short .NoChg                                                        ;   No, update ADSR parameters later
        Mov     AL,[EBX+mix+eMode]                                              ;AL = ADSR or Gain mode
        ShR     EBX,3
        And     AL,E_ADSR
        Mov     AH,[EBX+dsp+adsr]
        And     AH,80h
        Or      AL,AH

        Test    AL,80h + E_ADSR
        JZ      short .NoChg                                                    ;Envelope is already in gain mode, do nothing
        Test    AL,80h
        JZ      short .SetGain                                                  ;Switched from ADSR to Gain
        Test    AL,E_ADSR
        JNZ     short .Change                                                   ;Envelope is in ADSR mode, update settings

        Mov     AL,[EBX*8+mix+eMode]                                            ;Switched from Gain to ADSR, restore previous ADSR
        ShR     AL,4                                                            ; state then update settings
        Or      AL,E_ADSR
        Mov     [EBX*8+mix+eMode],AL

        .Change:
        Call    ChgADSR
        XOr     EAX,EAX
        Inc     EAX

    .NoChg:
    Ret

    .SetGain:
        ShL     EBX,3
        ShL     byte [EBX+mix+eMode],4                                          ;Save ADSR state, ChgGain will set bits 7 and 3-0

RGain:
    XOr     EAX,EAX
    Test    byte [EBX+mix+mFlg],MFLG_KOFF                                       ;Is voice in key off mode?
    JNZ     short .NoChg                                                        ;   Yes, Envelope setting can't be changed now

    Test    byte [EBX+mix+mKOn],-1
    SetNZ   AL
    Add     AL,AL
    Or      [EBX+mix+vRsv],AL
    Test    AL,AL                                                               ;Has time passed since KON was written?
    JNZ     short .NoChg                                                        ;   No, update GAIN parameters later

    ShR     EBX,3
    Test    byte [EBX+dsp+adsr],80h                                             ;Is envelope in gain mode?
    JNZ     short .NoChg                                                        ;   No, Setting gain register has no effect
        Push    .Return
        Push    ESI                                                             ;StartEnv will pop ESI on return
        LEA     ESI,[EBX+dsp]
        LEA     EBX,[EBX*8+mix]
        Jmp     ChgGain                                                         ;Begin ADSR envelope

        .Return:
        XOr     EAX,EAX
        Inc     EAX

    .NoChg:
    Ret

;============================================
;Main volumes

RMVolL:
    Test    AL,[surroff]
    SetZ    AH
    Dec     AH
    XOr     AL,AH
    Sub     AL,AH
    Mov     AH,[surroff]
    Cmp     AX,8080h
    SetE    AH
    Sub     AL,AH
    MovSX   EAX,AL

    Mov     [ESP-4],EAX
    FILd    dword [ESP-4]
    FIMul   dword [volAdj]
    FMul    dword [fpShR7]                                                      ;>> 7 to turn MVOL into a float
    FStP    dword [volMainL]                                                    ;Leave the 16-bits added by volAdj so the final

    XOr     EAX,EAX                                                             ; output will be 32-bit instead of 16-bit
    Inc     EAX
    Ret

RMVolR:
    Test    AL,[surroff]
    SetZ    AH
    Dec     AH
    XOr     AL,AH
    Sub     AL,AH
    Mov     AH,[surroff]
    Cmp     AX,8080h
    SetE    AH
    Sub     AL,AH

    XOr     AL,[surround]
    Sub     AL,[surround]
    Cmp     AL,80h
    SetE    AH
    And     AH,[surround]
    Sub     AL,AH
    MovSX   EAX,AL

    Mov     [ESP-4],EAX
    FILd    dword [ESP-4]
    FIMul   dword [volAdj]
    FMul    dword [fpShR7]
    FStP    dword [volMainR]

    XOr     EAX,EAX
    Inc     EAX
    Ret

REVolL:
    Test    AL,[surroff]
    SetZ    AH
    Dec     AH
    XOr     AL,AH
    Sub     AL,AH
    Mov     AH,[surroff]
    Cmp     AX,8080h
    SetE    AH
    Sub     AL,AH
    MovSX   EAX,AL

    Mov     [ESP-4],EAX
    FILd    dword [ESP-4]
    FIMul   dword [volAdj]
    FMul    dword [fpShR7]
    FStP    dword [volEchoL]

    XOr     EAX,EAX
    Inc     EAX
    Ret

REVolR:
    Test    AL,[surroff]
    SetZ    AH
    Dec     AH
    XOr     AL,AH
    Sub     AL,AH
    Mov     AH,[surroff]
    Cmp     AX,8080h
    SetE    AH
    Sub     AL,AH

    XOr     AL,[surround]
    Sub     AL,[surround]
    Cmp     AL,80h
    SetE    AH
    And     AH,[surround]
    Sub     AL,AH
    MovSX   EAX,AL

    Mov     [ESP-4],EAX
    FILd    dword [ESP-4]
    FIMul   dword [volAdj]
    FMul    dword [fpShR7]
    FStP    dword [volEchoR]

    XOr     EAX,EAX
    Inc     EAX
    Ret

;============================================
;Echo settings

REFB:
    MovSX   EAX,AL
    Mov     [ESP-4],EAX
    FILd    dword [ESP-4]

%if STEREO
    FLd     ST
    FIMul   dword [efbct]
    FMul    dword [fpShR23]                                                     ;Convert from fixed to floating-point
    FStP    dword [echoFB]                                                      ;7-bits (efb) + 16-bits (efbct) = 23-bits

    FLd     dword [fp64k]
    FISub   dword [efbct]
    FMulP   ST1,ST
    FMul    dword [fpShR23]
    FStP    dword [echoFBCT]
%else
    FMul    dword [fpShR7]
    FStP    dword [echoFB]
%endif

    XOr     EAX,EAX
    Inc     EAX
    Ret

REDl:
    Push    ECX
    Mov     AL,byte [dsp+edl]
    And     EAX,0Fh
    ShL     EAX,9                                                               ;EAX = Number of samples to delay
    Push    EAX

    Test    EAX,EAX                                                             ;If EAX = 0, EAX = 1
    SetZ    CL
    Or      AL,CL
    ShL     EAX,2                                                               ;Multiply by 4, since original echo is stored in
    Mov     [echoLenM],EAX                                                      ; 16-bit stereo

%if ECHOMEM=0
    ;Normally, the current pointer is NOT initialized by changing the EDL, but when the playing speed
    ;is set other than 100%, the current pointer is initialized to rewrite memory in unexpected places.
    Mov     [echoMaxM],EAX
    Mov     [echoCurM],EAX
%endif

    Pop     EAX
    Mul     dword [dspRate]                                                     ;EAX *= Rate / 32kHz
    Mov     ECX,32000
    Div     ECX

    Test    EAX,EAX                                                             ;If EAX = 0, EAX = 1
    SetZ    CL
    Or      AL,CL
    ShL     EAX,3                                                               ;Multiply by 8, since SNESAPU echo is stored in
    Mov     [echoLenD],EAX                                                      ; 32-bit stereo
    Pop     ECX

    XOr     EAX,EAX
    Inc     EAX
    Ret

RFCf:
    ShR     EBX,5
    MovSX   EAX,AL
    Mov     [ESP-4],EAX

    FILd    dword [ESP-4]
    FMul    dword [fpShR7]
    FStP    dword [EBX+firTaps]

    XOr     EAX,EAX                                                             ;DSP state changed if echo was enabled
    Inc     EAX
    Ret

;============================================
;Other

RPMOn:
    ;Reset all pitch on all voices -----------
    Push    ECX
    Mov     EBX,mix
    Mov     CL,8

    .Next:
        Mov     EAX,[EBX+mOrgP]
        MovZX   EDX,byte [EBX+mSrc]                                             ;EDX = Source
        Add     EAX,[scr700det+EDX*4]                                           ;EAX += Detune[EDX]

        Mul     dword [pitchAdj]
        ShRD    EAX,EDX,16
        AdC     EAX,0
        Mov     [EBX+mRate],EAX

        Sub     EBX,-80h

    Dec     CL
    JNZ     short .Next
    Pop     ECX

    XOr     EAX,EAX
    Inc     EAX
    Ret

RFlg:
    Test    AL,80h                                                              ;Has a soft reset been initialized?
    JZ      short .NoSRst                                                       ;   No
        Mov     EBX,dsp
        And     AL,~80h
        Or      AL,60h                                                          ;Turn on mute and disable echo
        Mov     [EBX+flg],AL
        Mov     [EBX+endx],BL                                                   ;Clear end block flags
        Mov     [EBX+kon],BL
        Mov     [EBX+kof],BL
        Mov     [voiceMix],BL

        ;Reset internal voice settings --------
        Mov     EBX,mix+mFlg
        Mov     AL,8

        .MFlg:
            And     byte [EBX],MFLG_USER                                        ;Leave user voice flags (mute and noise)
            Or      byte [EBX],MFLG_OFF                                         ;Set voice to inactive
            Sub     EBX,-80h

        Dec     AL
        JNZ     .MFlg
    .NoSRst:

    ;Update noise clock ----------------------
    Mov     dword [nRate],0
    And     EAX,1Fh
    JZ      short .NoNoise
        Mov     EBX,EAX
        Mov     EAX,-1
        Mov     EDX,65535
        Div     dword [EBX*4+rateTab]
        Mov     [nRate],EAX

    .NoNoise:
    XOr     EAX,EAX
    Inc     EAX
    Ret

;============================================
;Null register

RNull:
    XOr     EAX,EAX
    Ret


;===================================================================================================
;No Interpolation

PROC NoneInt

    FILd    word [ESI]

ENDP


;===================================================================================================
;Linear Interpolation

PROC LinearInt

    FILd    word [ESI-2]
    FILd    word [ESI]
    Mov     [ESP-4],EAX
    FSub    ST,ST1                                                              ;Difference between samples
    FIMul   dword [ESP-4]                                                       ;Multiply by delta x from last sample
    FMul    dword [fpShR16]
    FAddP   ST1,ST

ENDP


;===================================================================================================
;Cubic/Gauss (Use 4-point) Interpolation

PROC Point4Int

    ShR     EAX,8                                                               ;EAX indexes interpolation table value
    LEA     EAX,[EAX*8+interTab]
    FILd    word [ESI-6]                                                        ;Get first sample
    FIMul   word [EAX+0]
    FILd    word [ESI-4]
    FIMul   word [EAX+2]
    FILd    word [ESI-2]
    FIMul   word [EAX+4]
    FILd    word [ESI]
    FIMul   word [EAX+6]
    FAddP   ST1,ST
    FAddP   ST1,ST
    FAddP   ST1,ST
    FMul    dword [fpShR15]

ENDP


;===================================================================================================
;Sinc (Use 8-point) Interpolation

PROC Point8Int

    ShR     EAX,4                                                               ;EAX indexes interpolation table value
    And     EAX,-16
    Add     EAX,interTab
    FILd    word [ESI-14]
    FIMul   word [EAX+0]
    FILd    word [ESI-12]
    FIMul   word [EAX+2]
    FILd    word [ESI-10]
    FIMul   word [EAX+4]
    FILd    word [ESI-8]
    FIMul   word [EAX+6]
    FILd    word [ESI-6]
    FIMul   word [EAX+8]
    FILd    word [ESI-4]
    FIMul   word [EAX+10]
    FILd    word [ESI-2]
    FIMul   word [EAX+12]
    FILd    word [ESI-0]
    FIMul   word [EAX+14]
    FAddP   ST1,ST
    FAddP   ST1,ST
    FAddP   ST1,ST
    FAddP   ST1,ST
    FAddP   ST1,ST
    FAddP   ST1,ST
    FAddP   ST1,ST
    FMul    dword [fpShR15]

ENDP


;===================================================================================================
;Noise Generator
;
;Generates white noise samples
;
;Out:
;   nSmp = Random 16-bit sample
;
;Destroys:
;   EAX,EDX

%macro NoiseGen 0
    Mov     EAX,[nRate]
    Add     [nAcc],EAX
    JNC     short %%NoNInc
        Mov     EAX,[nSeed]
        Add     EAX,EAX
        JNS     short %%NoiseOK
            XOr     EAX,40001h

        %%NoiseOK:
        Mov     [nSeed],EAX

        SAR     EAX,16
        Mov     [nSmp],EAX

    %%NoNInc:
    Test    dword [dspNoiseF],-1
    JZ      short %%NoNIncF
    Mov     EAX,[nfRate]
    Add     [nfAcc],EAX
    JNC     short %%NoNIncF
        IMul    EAX,[nfSmp],27865                                               ;X=(AX+C)%M  Where: X<M and 2<=A<M and 0<C<M
        Add     EAX,7263                                                        ;Add C
        CWDE                                                                    ;Modulus M (32768)
        Mov     [nfSmp],EAX

    %%NoNIncF:
%endmacro


;===================================================================================================
;Pitch Modulation
;
;Changes the pitch based on the output of the previous voice:
;
; P' = (P * (OUTX + 32768)) >> 15
;
;Pitch modulation in the SNES uses the full 16-bit sample value, not the 8-bit value in OUTX as
;previously believed.
;
;In:
;   CH  = Bitmask for current voice
;   EBX-> Current voice in 'mix'
;
;Destroys:
;   EAX,EDX

%macro PitchMod 0
    ;Adjust pitch by sample value ---------
    Mov     EAX,[EBX+mOut-80h]                                                  ;EAX = Wave height of last voice (-16.15)
    Add     EAX,32768                                                           ;Unsign sample
    IMul    EAX,dword [EBX+mOrgP]                                               ;Apply sample height to pitch
    SAR     EAX,15

    Push    ECX
    Test    dword [dspOpts],DSP_NOPLMT
    SetNZ   CL
    Add     CL,CL
    Add     CL,14

    ;Clamp pitch to 14-bits ---------------
    Mov     EDX,EAX
    SAR     EDX,CL
    JZ      short %%PitchOK
        SetS    AL
        MovZX   EAX,AL
        Dec     EAX
        Test    dword [dspOpts],DSP_NOPLMT                                      ;If do not remove the pitch limit, the highest
        SetZ    DL                                                              ; pitch value is 3FFF
        Dec     DL
        Or      DL,3Fh
        And     AH,DL
        MovZX   EAX,AX

    %%PitchOK:
    Pop     ECX

    ;Convert pitch to sample rate ---------
    MovZX   EDX,byte [EBX+mSrc]                                                 ;EDX = Source
    Add     EAX,[scr700det+EDX*4]                                               ;EAX += Detune[EDX]

    Mul     dword [pitchAdj]
    ShRD    EAX,EDX,16
    AdC     EAX,0
    Mov     [EBX+mRate],EAX
%endmacro


;===================================================================================================
;Process Sound Source
;
;Updates the current sample position and decompresses the next block if necessary
;
;In:
;   CH  = Bitmask for current voice
;   EBX-> Current voice in 'mix'
;
;Destroys:
;   EAX,EDX,CL,ESI

%macro UpdateSrc 0
    ;Update sample index ---------------------
    Mov     CL,[EBX+mRate+2]                                                    ;CL = Number of whole samples to increase index by
    Mov     EAX,[EBX+mRate]                                                     ;AX = Fraction of sample to increase index by
    Add     [EBX+mDec],AX                                                       ;Add AX to the decimal counter
    AdC     CL,0                                                                ;Add carry, if any, to increase amount
    JZ      %%NoSInc                                                            ;If the amount is zero, index didn't increase

    ;Check for end of block ------------------
    Add     CL,CL                                                               ;CL <<= 1  (for 16-bit samples)
    Add     [EBX+sIdx],CL                                                       ;Increase sample index
    Test    byte [EBX+sIdx],20h                                                 ;Have we reached the end of the block?
    JZ      %%NoSInc                                                            ;   No
        And     byte [EBX+sIdx],~20h                                            ;Adjust sample index for wrap around
        Mov     EAX,[EBX+sBuf+16]                                               ;Copy last four samples of buffer
        Mov     EDX,[EBX+sBuf+20]                                               ; (needed for interpolation)
        Mov     [EBX+sBuf-16],EAX
        Mov     [EBX+sBuf-12],EDX
        Mov     EAX,[EBX+sBuf+24]
        Mov     EDX,[EBX+sBuf+28]
        Mov     [EBX+sBuf-8],EAX
        Mov     [EBX+sBuf-4],EDX
        Add     word [EBX+bCur],9                                               ;Move to next sample block

        Test    byte [EBX+bHdr],1                                               ;Was this the end block?
        JZ      short %%NotEndB                                                 ;   No, Decompress next block
        Or      [dsp+endx],CH                                                   ;Set flag in ENDX
        Test    byte [EBX+bHdr],2                                               ;Is this source looped?
        JNZ     short %%LoopB                                                   ;   Yes, Start over at loop point

        ;End voice playback -------------------
        %%EndPlay:
            Not     CH
            And     [voiceMix],CH                                               ;Don't include voice in mixing process
            Not     CH

            Mov     dword [EBX+eVal],0                                          ;Reset envelope and wave height
            Mov     dword [EBX+mOut],0
            Or      byte [EBX+mFlg],MFLG_OFF                                    ;Set voice to inactive
            And     byte [EBX+mFlg],~MFLG_KOFF
            Jmp     .VoiceDone

        ;Restart loop -------------------------
        %%LoopB:
            MovZX   EDX,byte [EBX+mSrc]                                         ;EDX = Source
            Test    byte [EBX+mFlg],MFLG_KOFF                                   ;Is voice in key off mode?
            JNZ     short %%NoSrc                                               ;   Yes
                Mov     EAX,EBX
                Sub     EAX,mix
                ShR     EAX,3
                Add     EAX,dsp
                Mov     DL,[EAX+srcn]                                           ;DL = Source
                Mov     [EBX+mSrc],DL                                           ;Save source number

            %%NoSrc:
            Mov     DL,[scr700chg+EDX]                                          ;DL = NoteChange[EDX]
            Mov     EAX,[pAPURAM]
            Mov     AH,[dsp+dir]                                                ;EAX -> Source directory
            Mov     AX,[EDX*4+EAX+2]
            Mov     [EBX+bCur],EAX                                              ;Store loop point in current block pointer

        ;Decompress next block ----------------
        %%NotEndB:
            Mov     ESI,[EBX+bCur]                                              ;ESI -> Current sample block
            Push    EDI,EBX
            Mov     AL,[ESI]                                                    ;Get block header
            LEA     EDI,[EBX+sBuf]                                              ;EDI -> location to store samples
            Mov     [EBX+bHdr],AL                                               ;Save header byte
            MovSX   EDX,word [EBX+sP1]                                          ;Load previous two samples
            MovSX   EBX,word [EBX+sP2]
            Call    [pDecomp]                                                   ;Call user selected decompression routine

            Mov     EAX,EBX
            Pop     EBX,EDI
            Mov     [EBX+sP1],DX                                                ;Save last two samples in 16-bit form
            Mov     [EBX+sP2],AX

            Mov     AL,[EBX+bHdr]
            And     AL,3
            Cmp     AL,1
            JNE     short %%NoSInc

            XOr     EAX,EAX
            Mov     [EBX+sBuf+16],EAX
            Mov     [EBX+sBuf+20],EAX
            Mov     [EBX+sBuf+24],EAX
            Mov     [EBX+sBuf+28],EAX

    %%NoSInc:
%endmacro


;===================================================================================================
;Calculate Envelope Modification
;
;Changes the current height of the volume envelope based on its programming.
;
;In:
;   EBX-> Current voice in mix
;   CH  = Current voice bit mask
;
;Destroys:
;   EAX,CL,EDX,ESI

%macro UpdateEnv 0
    Test    byte [EBX+mKOn],-1                                                  ;Did time pass after KON had been written?
    JNZ     %%Done                                                              ;   No, quit

    Mov     AL,[adsrCnt]
    Test    AL,AL                                                               ;Should update envelope?
    JZ      %%Done                                                              ;   No, quit
    Mov     [adsrUpd],AL

    %%Loop:
    Mov     CL,[EBX+eMode]
    Test    CL,E_IDLE                                                           ;Is the envelope constant?
    JNZ     %%EnvDone                                                           ;   Yes, go to ADSR/Gain check

    Dec     word [2+EBX+eCnt]                                                   ;Decrease sample counter, is it zero?
    JNZ     %%LoopDone                                                          ;   No, go to next loop

    Mov     EAX,[EBX+eRate]                                                     ;Restore sample counter
    Add     [EBX+eCnt],EAX

    Mov     AL,CL
    And     AL,E_ADSR|E_DIRECT
    Cmp     AL,E_DIRECT                                                         ;Is the envelope direct mode?
    JE      %%EnvDirect                                                         ;   Yes

    ;Adjust Envelope -------------------------
    %%AdjExp:
    Test    CL,E_TYPE                                                           ;Is the adjustment an exponential decrease?
    JZ      short %%AdjLin                                                      ;   No, Go to linear
        Mov     EAX,[EBX+eVal]                                                  ;Get now envelope height
        Neg     EAX
        SAR     EAX,8
        Add     [EBX+eVal],EAX                                                  ;Subtract 1/256th of envelope height
        Mov     EDX,[EBX+eDest]                                                 ;Get destination
        Cmp     EDX,[EBX+eVal]                                                  ;Has height reached destination?
        JL      %%EnvDone                                                       ;   No
        Jmp     short %%AdjOff

    %%AdjLin:
    Test    CL,E_DIR                                                            ;Is the adjustment up or down?
    JZ      short %%AdjDec
        Mov     EAX,[EBX+eVal]                                                  ;Get now envelope height
        Add     EAX,[EBX+eAdj]
        Mov     [EBX+eVal],EAX                                                  ;Add adjustment to height
        Mov     EDX,[EBX+eDest]                                                 ;Get destination
        Cmp     EDX,EAX                                                         ;Has height reached destination?
        JG      %%EnvDone                                                       ;   No

        Mov     [EBX+eVal],EDX                                                  ;Set destination
        Jmp     short %%AdjDone                                                 ;Change to decay mode

    %%AdjDec:
        Mov     EAX,[EBX+eVal]                                                  ;Get now envelope height
        Sub     EAX,[EBX+eAdj]
        Mov     [EBX+eVal],EAX                                                  ;Subtract adjustment to height
        Mov     EDX,[EBX+eDest]                                                 ;Get destination
        Cmp     EDX,EAX                                                         ;Has height reached destination?
        JL      %%EnvDone                                                       ;   No

    %%AdjOff:
        Mov     [EBX+eVal],EDX                                                  ;Set destination
        Test    EDX,EDX                                                         ;If destination isn't 0, change to sustain mode
        JNZ     short %%AdjDone

        Mov     AL,[EBX+eMode]                                                  ;If the envelope started out in ADSR mode, but was
        And     AL,~70h                                                         ; switched to Gain w/ linear decrease, the ADSR state
        Or      AL,E_SUST << 4                                                  ; will become sustain if ADSR is re-enabled.
        Mov     [EBX+eMode],AL

        Mov     AL,[EBX+mFlg]                                                   ;If the voice was getting keyed off, set MFLG_OFF to
        And     AL,MFLG_KOFF                                                    ; mark the voice as now being inactive
        Add     AL,AL
        SetZ    AH
        Or      [EBX+mFlg],AL
        And     byte [EBX+mFlg],~MFLG_KOFF

        Dec     AH
        And     AH,CH
        Not     AH
        And     [voiceMix],AH                                                   ;Disable voice mixing if keyed off

        Or      byte [EBX+eMode],E_IDLE                                         ;Envelope is no longer changing
        Jmp     %%EnvDone

    %%AdjDone:

    ;Change adjustment mode ------------------
    ;(see StartEnv)
    Test    CL,E_ADSR                                                           ;Is envelope in ADSR mode?
    JZ      %%EnvGain                                                           ;   No, jump to Gain

    Mov     ESI,EBX
    Sub     ESI,mix
    XOr     EAX,EAX
    ShR     ESI,3                                                               ;ESI indexes current voice in dsp
    Add     ESI,dsp

    Test    byte [ESI+adsr],80h                                                 ;Is envelope flag in ADSR?
    JZ      %%EnvDone                                                           ;   No

    Mov     [EBX+vRsv],AL                                                       ;Reset ADSR/Gain changed flag
    Test    CL,E_DEST                                                           ;Switch to next mode
    JNZ     short %%EnvSust

    %%EnvDecay:
        Push    %%EnvDone
        Push    ESI                                                             ;ESI will get popped on return from StartEnv
        Jmp     ChgDec                                                          ;see StartEnv

    %%EnvSust:
        Push    %%EnvDone
        Push    ESI                                                             ;ESI will get popped on return from StartEnv
        Jmp     ChgSus                                                          ;see StartEnv

    %%EnvGain:
        Or      byte [EBX+eMode],E_IDLE                                         ;Envelope is now constant

        Test    CL,E_DEST                                                       ;If gain is in "bent line" mode and line has reached
        JZ      short %%EnvDone                                                 ; bend point, adjust envelope settings, otherwise
                                                                                ; envelope is done.
        Cmp     dword [EBX+eDest],D_MAX
        JE      short %%EnvDone

        And     byte [EBX+eMode],~E_IDLE                                        ;Undo idle flag
        Mov     dword [EBX+eAdj],A_BENT                                         ;Slow down increase rate
        Mov     dword [EBX+eDest],D_MAX                                         ;Set destination to max
        Jmp     short %%EnvDone

    %%EnvDirect:
        Mov     EAX,[EBX+eVal]
        Mov     EDX,[EBX+eDest]
        Cmp     EDX,EAX
        JE      short %%EnvDirectE
        JG      short %%EnvDirectH

        Sub     EAX,[EBX+eAdj]                                                  ;Sub adjustment to height
        Mov     [EBX+eVal],EAX
        Cmp     EDX,EAX                                                         ;Has height reached destination?
        JL      short %%EnvDone                                                 ;   No

        Mov     [EBX+eVal],EDX                                                  ;Set destination
        Jmp     short %%EnvDirectE

    %%EnvDirectH:
        Add     EAX,[EBX+eAdj]                                                  ;Add adjustment to height
        Mov     [EBX+eVal],EAX
        Cmp     EDX,EAX                                                         ;Has height reached destination?
        JG      short %%EnvDone                                                 ;   No

        Mov     [EBX+eVal],EDX                                                  ;Set destination

    %%EnvDirectE:
        Or      byte [EBX+eMode],E_IDLE                                         ;Envelope is now constant

    %%EnvDone:
    Mov     AL,[EBX+vRsv]
    Test    AL,1
    JZ      short %%ChkGain
        Mov     byte [EBX+vRsv],0
        Push    EBX                                                             ;Update new ADSR parameters
        Sub     EBX,mix
        Call    RADSR
        Pop     EBX
        Jmp     short %%LoopDone

    %%ChkGain:
    Test    AL,2
    JZ      short %%LoopDone
        Mov     byte [EBX+vRsv],0
        Push    EBX                                                             ;Update new Gain parameters
        Sub     EBX,mix
        Call    RGain
        Pop     EBX

    %%LoopDone:
    Dec     byte [adsrUpd]
    JNZ     %%Loop

    %%Done:
%endmacro


;===================================================================================================
;Finite Impulse Response Echo Filter
;
;Filters the echo using an eight tap FIR filter:
;
;        7
;       ---
;   x = \   c  * s
;       /    n    n
;       ---
;       n=0
;
;   x = output sample
;   c = filter coefficient (-.7)
;   s = unfiltered sample
;   n = 0 is the oldest sample and 7 is the most recent
;
;FIR filters are based on the sample rate.  This was fine in the SNES, because the sample rate was
;always 32kHz, but in the case of an emulator the sample rate can change.  So measures have to be
;taken to ensure the filter will have the same effect, regardless of the output sample rate.
;
;To overcome this problem, I figured each tap of the filter is applied every 31250ns.  So the
;solution is to calculate when 31250ns have gone by, and use the sample at that point.  Of course
;this method really only works if the output rate is a multiple of 32k.  In order to get accurate
;results, some sort of interpolation method needs to be introduced.  I went the cheap route and used
;linear interpolation.
;
;In:
;   ST0,1 = Input samples
;
;Out:
;   ST0,1 = Filtered samples
;
;Destroys:
;   EAX,EDX,EBX,CL

%macro FIRCut16 1
    FISt    dword [ESP-4]
    Mov     EAX,[ESP-4]
    Add     EAX,32768
    SAR     EAX,16                                                              ;Did a sample overflow signed-16bit?
    JZ      short %%OK                                                          ;   No, do nothing
        Mov     EAX,[ESP-4]                                                     ;There is no overflow because FIR is handled with
        MovSX   EAX,AX                                                          ; 32bit-float, emulates signed-16bit overflow here.
        And     EAX,~1                                                          ;All numbers used by DSP are even

        Mov     [ESP-4],EAX
        FSubP   %1,ST
        FILd    dword [ESP-4]
        FAdd    %1,ST

    %%OK:
%endmacro

%macro FIRClampL 1
    FISt    dword [ESP-4]
    Mov     EAX,[ESP-4]
    Add     EAX,32768
    SAR     EAX,16                                                              ;Did a sample overflow signed-16bit?
    JZ      short %%OK                                                          ;   No, do nothing
        Mov     EAX,[ESP-4]                                                     ;If s < -32768, s = -32768
        SAR     EAX,31                                                          ;If s > 32767, s = 32767
        Not     EAX
        XOr     EAX,-32768
        And     EAX,~1                                                          ;All numbers used by DSP are even

        Mov     [ESP-4],EAX
        FSubP   %1,ST
        FILd    dword [ESP-4]
        FAdd    %1,ST

    %%OK:
%endmacro

%macro FIRClampH 1
    FISt    dword [ESP-4]
    Mov     EAX,[ESP-4]
    Add     EAX,65536
    SAR     EAX,17                                                              ;Did a sample overflow signed-16bit?
    JZ      short %%OK                                                          ;   No, do nothing
        Mov     EAX,[ESP-4]                                                     ;If s < -65536, s = -65536
        SAR     EAX,31                                                          ;If s > 65535, s = 65535
        Not     EAX
        XOr     EAX,-65536

        Mov     [ESP-4],EAX
        FSubP   %1,ST
        FILd    dword [ESP-4]
        FAdd    %1,ST

    %%OK:
%endmacro

%macro FIRFilter 0
    Test    dword [dspOpts],DSP_ECHOFIR
    JZ      short %%NoZero

    Mov     EBX,mix
    XOr     DX,DX
    Inc     DH
    Mov     CL,8

    %%ChMute:
        Test    byte [EBX+mFlg],MFLG_MUTE                                       ;Is voice muted by user?
        SetZ    AL
        Dec     AL
        And     AL,DH
        Or      DL,AL

        Sub     EBX,-80h
        Add     DH,DH

    Dec     CL
    JNZ     short %%ChMute

    Test    DL,DL                                                               ;DL = Muted channels, are any channels muted?
    JZ      short %%NoZero                                                      ;   No

    Not     DL                                                                  ;DL = Not muted channels
    Mov     DH,[dsp+eon]                                                        ;DH = Using echo channels
    And     DH,DL                                                               ;Are all channels using echoes muted?
    JNZ     short %%NoZero                                                      ;   No
        FLd     dword [fpShR1]                                                  ;Force feedback in half, without echo. (If there is
        FMul    ST1,ST                                                          ; a loud feedback that causes clipping, mute the
        FMul    ST2,ST                                                          ; channel toprevent the sound from playing forever.)
        FStP    ST

    %%NoZero:
    Sub     byte [firCur],4                                                     ;Move index back one sample. (Index will wrap around
    Mov     EBX,[firCur]                                                        ; after 64 samples, enough for up to 256kHz output.)
    LEA     EBX,[EBX*2+firBuf]                                                  ;EBX -> Current sample in filter buffer
                                                                                ;                                   |FBR FBL
    Test    dword [dspOpts],DSP_ECHOFIR
    JZ      short %%Skip
        FLd     ST                                                              ;Clamp 16-bit sample                |FBR FBL FBL
        FIRClampL   ST1
        FStP    ST                                                              ;                                   |FBR FBL

        FLd     ST1                                                             ;                                   |FBR FBL FBR
        FIRClampL   ST2
        FStP    ST                                                              ;                                   |FBR FBL

    %%Skip:
    FSt     dword [EBX]                                                         ;Store new samples in buffer
    FSt     dword [FIRBUF*2+EBX]
    FStP    dword [FIRBUF*4+EBX]                                                ;                                   |FBR
    FSt     dword [4+EBX]
    FSt     dword [FIRBUF*2+4+EBX]
    FStP    dword [FIRBUF*4+4+EBX]                                              ;                                   |(empty)

    FLdZ                                                                        ;                                   |0
    FLdZ                                                                        ;                                   |0 0
    Test    dword [dspOpts],DSP_ECHOFIR
    SetNZ   CH

    MovZX   EDX,CH                                                              ;EBX -> Unfiltered sample
    Dec     EDX
    Not     EDX
    And     EDX,FIRBUF*2+56
    Add     EBX,EDX

    MovZX   EDX,CH                                                              ;EDX -> Filter taps
    Dec     EDX
    And     EDX,28
    Add     EDX,firTaps

    Mov     dword [ESP-8],0                                                     ;Reset decimal overflow, so filtering is consistant
    Mov     CL,8                                                                ;8-tap FIR filter

    %%Tap:
        FILd    dword [ESP-8]                                                   ;                                   |0 0 firDec
        FMul    dword [fpShR16]                                                 ;                                   |0 0 firDec>>16=FD

        FLd     dword [8+EBX]                                                   ;Interpolate left sample            |0 0 FD S1
        FSub    dword [EBX]                                                     ;                                   |0 0 FD S1-S2
        FMul    ST1                                                             ;                                   |0 0 FD (S1-S2)*FD
        FAdd    dword [EBX]                                                     ;                                   |0 0 FD (S1-S2)*FD+S2
        FMul    dword [EDX]                                                     ;                                   |0 0 FD ((S1-S2)*FD+S2)*FT
        FAddP   ST2,ST                                                          ;                                   |0 ((S1-S2)*FD+S2)*FT FD

        FLd     dword [12+EBX]                                                  ;Interpolate right sample           |0 FBL FD S1
        FSub    dword [4+EBX]                                                   ;                                   |0 FBL FD S1-S2
        FMulP   ST1,ST                                                          ;                                   |0 FBL (S1-S2)*FD
        FAdd    dword [4+EBX]                                                   ;                                   |0 FBL (S1-S2)*FD+S2
        FMul    dword [EDX]                                                     ;                                   |0 FBL ((S1-S2)*FD+S2)*FT
        FAddP   ST2,ST                                                          ;                                   |FBR FBL

        Test    dword [dspOpts],DSP_ECHOFIR
        JZ      %%ClampH
        Dec     CL                                                              ;Is calculate the oldest sample (n=0)?
        JZ      short %%ClampL                                                  ;   Yes
            FLd     ST                                                          ;Cut high-order bits                |FBR FBL FBL
            FIRCut16    ST1
            FStP    ST                                                          ;                                   |FBR FBL

            FLd     ST1                                                         ;                                   |FBR FBL FBR
            FIRCut16    ST2
            FStP    ST                                                          ;                                   |FBR FBL

            Inc     CL                                                          ;Restore CL
            Jmp     %%Next

        %%ClampL:
            FLd     ST                                                          ;Clamp 16-bit sample                |FBR FBL FBL
            FIRClampL   ST1
            FStP    ST                                                          ;                                   |FBR FBL

            FLd     ST1                                                         ;                                   |FBR FBL FBR
            FIRClampL   ST2
            FStP    ST                                                          ;                                   |FBR FBL

            Inc     CL                                                          ;Restore CL
            Jmp     short %%Next

        %%ClampH:
            FLd     ST                                                          ;Clamp 17-bit sample                |FBR FBL FBL
            FIRClampH   ST1
            FStP    ST                                                          ;                                   |FBR FBL

            FLd     ST1                                                         ;                                   |FBR FBL FBR
            FIRClampH   ST2
            FStP    ST                                                          ;                                   |FBR FBL

        %%Next:
        Mov     EAX,[ESP-8]                                                     ;Determine next sample to use in filter
        Add     EAX,[firRate]
        Mov     [ESP-8],AX
        ShR     EAX,16

        Test    CH,CH
        JNZ     short %%NewFIR
            LEA     EBX,[EAX*8+EBX]                                             ;EBX -> Sample to use in filter
            Sub     EDX,4                                                       ;EDX -> Next filter tap

        Dec     CL
        JNZ     %%Tap
        Jmp     short %%Done

        %%NewFIR:
            ShL     EAX,3                                                       ;Multiply upper 16-bit by 8, not use 'ShR EAX,13'
            Sub     EBX,EAX                                                     ;EBX -> Sample to use in filter
            Add     EDX,4                                                       ;EDX -> Next filter tap

        Dec     CL
        JNZ     %%Tap

    %%Done:
%endmacro


;===================================================================================================
;DSP Catch Up with the Processing of SPC700

PROC CatchUp

    Push    EAX

    Mov     EAX,[t64Cnt]
    ShR     EAX,1
    Sub     EAX,[outCnt]
    JZ      .Done

    Add     [outCnt],EAX

    Push    EDX
    Mul     dword [outRate]
    Add     EAX,[outDec]
    AdC     EDX,0
    Mov     [outDec],AX
    ShRD    EAX,EDX,16

    Sub     [outLeft],EAX
    JNC     short .Okay
        Add     EAX,[outLeft]
        Mov     dword [outLeft],0

    .Okay:
    Test    EAX,EAX
    JZ      short .Skip
        Call    EmuDSP,[pOutBuf],EAX
        Mov     [pOutBuf],EAX

    .Skip:
%if INTBK
    Push    ECX                                                                 ;Run KON/KOFF processing after emulate DSP
    CatchKOff
    CatchKOn
    Pop     ECX,EDX
%else
    Push    EBX,ECX                                                             ;Run KON processing after emulate DSP
    XOr     CH,CH                                                               ;Set CH = 0 for use with CatchKOn
    CatchKOn
    Pop     ECX,EBX,EDX
%endif

    .Done:
    Pop     EAX

ENDP


;===================================================================================================
;Set Automatic EmuDSP Parameters

PROC SetEmuDSP, pBufD, numD, rateD

    Mov     EAX,[rateD]
    Test    EAX,EAX
    JZ      short .Final
        Push    ECX,EDX
        XOr     EDX,EDX
        Mov     [outDec],EDX

        ShLD    EDX,EAX,16
        ShL     EAX,16
        Mov     ECX,32000
        Div     ECX
        Mov     [outRate],EAX
        Pop     EDX,ECX

        Mov     EAX,[numD]
        Mov     [outLeft],EAX
        Mov     EAX,[pBufD]
        Mov     [pOutBuf],EAX
        Mov     EAX,[t64Cnt]
        ShR     EAX,1
        Mov     [outCnt],EAX
        RetN

    .Final:
        Call    EmuDSP,[pOutBuf],[outLeft]
        Mov     [pOutBuf],EAX
        Mov     dword [outLeft],0

ENDP


;===================================================================================================
;Emulate SPC700

PROC EmuDSP, pBuf, num
USES ALL

    Mov     EAX,[pBuf]
    Mov     EDX,[num]
    Test    EDX,EDX
    JZ      .Done

    Test    EAX,EAX                                                             ;If pBuf is null by called SeekAPU
    JZ      short .SkipSize                                                     ;   Yes, force emulation

    Test    dword [smpAdj],-1                                                   ;Buffer overflow check
    JZ      short .SkipSize                                                     ;If half-hearted sampling rate (ex. 44100Hz),
        Test    dword [smpSize],-1                                              ; it will be write a few over samples due to
        JZ      .Done                                                           ; calculate errors

    .SkipSize:
    Test    EAX,EAX
    SetZ    BL                                                                  ;BL = 0 if output pointer is null, otherwise it indexes
    Dec     BL                                                                  ; the emulation routine
    And     BL,[dspMix]                                                         ;BL = 0 (mute) or 1 (output)
    Dec     BL
    Mov     BH,BL
    And     BL,8                                                                ;BL = 8 or 0
    Not     BH                                                                  ;BH = 0 or 0xFF

    Mov     DH,[dsp+flg]                                                        ;DH = disFlag
    And     DH,0E0h                                                             ;   [0] - Disabled write echo memory
    Or      DH,[dspMute]                                                        ;   [1] - (not used)
                                                                                ;   [2] - (not used)
    Mov     DL,[dspOpts]                                                        ;   [3] - Disabled DSP emulation (pBuf is NULL)
    And     DL,DSP_NOECHO                                                       ;   [4] - Disabled echo (user setting)
    Or      DH,DL                                                               ;   [5] - Disabled echo (DSP no echo flag)
                                                                                ;   [6] - Disabled DSP emulation (DSP mute flag)
    Or      DH,BL                                                               ;   [7] - Disabled DSP emulation (DSP reset flag)

    Test    dword [dspOpts],DSP_ECHOFIR                                         ;Is echo disabled?
    SetZ    DL
    Or      DH,DL
    Mov     [disFlag],DH

    Mov     DH,[dsp+pmon]                                                       ;Set DSP pitch modulation flags
    And     DH,0FEh
    Test    dword [dspOpts],DSP_NOPMOD                                          ;Is pitch modulation enabled?
    SetNZ   DL
    Dec     DL
    And     DH,DL
    And     DH,BH
    Mov     [dspPMod],DH

    Mov     DH,[dsp+non]                                                        ;Set DSP noise flags
    Test    dword [dspOpts],DSP_NONOISE                                         ;Is noise enabled?
    SetNZ   DL
    Dec     DL
    And     DH,DL
    Mov     BL,DH
    And     DH,BH
    Mov     [dspNoise],DH

    Push    EBX
    Mov     BH,8
    Mov     BL,1
    XOr     DH,DH
    Mov     ESI,mix+mFlg

    .Noise:
        Test    byte [ESI],MFLG_NOISE                                           ;Is noise enabled?
        SetZ    DL
        Dec     DL
        And     DL,BL
        Or      DH,DL

        Add     BL,BL
        Sub     ESI,-80h

    Dec     BH
    JNZ     short .Noise
    Pop     EBX

    And     DH,BH
    Mov     [dspNoiseF],DH
    Or      [dspNoise],DH

    Test    dword [dspOpts],DSP_FLOAT                                           ;Is volume output floating-point?
    JNZ     short .Next                                                         ;   Yes
        FILd    dword [vMMaxL]
        FMul    dword [fp64k]                                                   ;Convert to a 32-bit sample (<< 16)
        FStP    dword [vMMaxL]                                                  ;Save as a float
        FILd    dword [vMMaxR]
        FMul    dword [fp64k]
        FStP    dword [vMMaxR]

    .Next:
        ;Verify output buffer length ----------
        Mov     EDX,[num]
        Test    EDX,EDX                                                         ;Is num > 0?
        JLE     .Quit                                                           ;   No

        Cmp     EDX,MIX_SIZE                                                    ;Is num <= size of internal buffer?
        JBE     short .NSmpOK
            Mov     EDX,MIX_SIZE

        .NSmpOK:
        Sub     [num],EDX

%ifdef SPC700_INC
        Test    byte [dbgOpt],DSP_HALT                                          ;Do nothing if APU is suspended
        JNZ     short .Mute
%endif

        ;Call emulation routine ---------------
        Call    RunDSP                                                          ;Run DSP emulation
        JC      short .Next                                                     ;Quit, if emulation produced output

    .Mute:
        ;Output silence -----------------------
        Mov     EDI,EAX                                                         ;EDI-> Buffer to store output

        Mov     ECX,EDX                                                         ;ECX = Size of output buffer in samples
        XOr     EAX,EAX
        MovSX   AX,byte [dspSize]
        XOr     AL,AH
        Sub     AL,AH
        XOr     AH,AH
        Mul     byte [dspChn]
        Mul     ECX
        Mov     EDX,EAX                                                         ;EDX = Size of output buffer in bytes

        XOr     EAX,EAX                                                         ;EAX = 80h if samples are unsigned, 0 otherwise
        Cmp     byte [dspSize],1
        SetNE   AL
        Dec     EAX
        And     EAX,80808080h

        Mov     ECX,EDX                                                         ;Fill output buffer with baseline samples
        And     EDX,3
        ShR     ECX,2
        Rep     StoSD
        Mov     ECX,EDX
        Rep     StoSB
        Mov     EAX,EDI                                                         ;EAX-> End of buffer

        Jmp     .Next

    .Quit:
    Test    dword [dspOpts],DSP_FLOAT                                           ;Is volume output floating-point?
    JNZ     short .OutFloat                                                     ;   Yes
        FLd     dword [vMMaxL]
        FMul    dword [fpShR16]
        FIStP   dword [vMMaxL]
        FLd     dword [vMMaxR]
        FMul    dword [fpShR16]
        FIStP   dword [vMMaxR]

    .OutFloat:
    Push    EAX
    Call    SetFade

    ;Update ENVX and OUTX registers ----------
    Mov     EBX,mix
    Mov     ESI,dsp
    Mov     DH,1

    .XRegs:
        Mov     EAX,[EBX+eVal]
        ShR     EAX,E_SHIFT
        Mov     [ESI+envx],AL

        Mov     AL,[EBX+mOut+1]
        Mov     [ESI+outx],AL

        Add     ESI,10h
        Sub     EBX,-80h

    Add     DH,DH
    JNZ     short .XRegs

    ;Update DSP data register on SPC700 side -
    Mov     EBX,[pAPURAM]
    MovZX   EDX,byte [0F2h+EBX]
    Mov     DL,[EDX+dsp]
    Mov     [0F3h+EBX],DL
    Pop     EAX

    .Done:

ENDP


%macro CalRamp1 0-1
    Mov     EAX,[ECX]
    Cmp     EAX,[ECX-8]
    JE      short %%OK

    FLd     dword [ECX]                                                         ;Current                            |Current
    FCom    dword [ECX-8]                                                       ;Target                             |Current
    FNSTSW  AX
    Test    AH,1                                                                ;Is C0 = 0 (Current > Target)?,
    JZ      short %%Sub                                                         ;   Yes, subtraction

    %if %0                                                                      ;Current += volRamp
        FAdd    dword [%1]
    %else
        FAdd    dword [volRamp1]
    %endif

        FCom    dword [ECX-8]                                                   ;Target                             |Current
        FNSTSW  AX
        FStP    dword [ECX]                                                     ;Update current                     |(empty)
        Test    AH,1                                                            ;Is C0 = 0 (Current > Target)?,
        JNZ     short %%OK                                                      ;   No, re-change with next tick
        Jmp     short %%Force

    %%Sub:
    %if %0                                                                      ;Current -= volRamp
        FSub    dword [%1]
    %else
        FSub    dword [volRamp1]
    %endif

        FCom    dword [ECX-8]                                                   ;Target                             |Current
        FNSTSW  AX
        FStP    dword [ECX]                                                     ;Update current                     |(empty)
        Test    AH,1                                                            ;Is C0 = 0 (Current > Target)?,
        JZ      short %%OK                                                      ;   Yes, re-change with next tick

    %%Force:
        Mov     EAX,[ECX-8]
        Mov     [ECX],EAX

    %%OK:
%endmacro

%macro CalRamp2 0-1
    Mov     AL,[voiceMix]
    Test    AL,AL
    JZ      short %%Force

    %if %0
        Mov     EAX,[ECX]
        Test    EAX,EAX
        JZ      short %%Force
    %endif

        CalRamp1    volRamp2
        Jmp     short %%OK

    %%Force:
        Mov     EAX,[ECX-8]
        Mov     [ECX],EAX

    %%OK:
%endmacro

%macro MixSample 0
    ;Get sample ========================
    Mov     ESI,[EBX+sIdx]
    MovZX   EAX,word [EBX+mDec]
    Call    [pInter]                                                            ;                                   |smp

    Test    [dspNoise],CH                                                       ;Is noise enabled?
    JZ      short %%NoNoise                                                     ;   No
        FStP    ST                                                              ;                                   |(empty)
        XOr     EAX,EAX
        Test    [dspNoiseF],CH
        SetNZ   AL
        FILd    dword [nSmp+EAX*4]                                              ;                                   |noise

    %%NoNoise:

    ;Mixing ============================
    Mov     EAX,[EBX+eVal]
    Mov     [envCrt],EAX
    XOr     EAX,EAX
    Test    dword [dspOpts],DSP_NOENV                                           ;Is envelope disabled?
    SetNZ   AL
    FIMul   dword [envCrt+EAX*4]
    FMul    dword [fpEShR]
    FISt    dword [EBX+mOut]

    Test    byte [EBX+mFlg],MFLG_MUTE                                           ;Is voice muted by user?
    JNZ     .VoiceOff                                                           ;   Yes

    MovZX   EAX,byte [EBX+mSrc]                                                 ;EAX = Source
    Mov     AH,[scr700dsp+EAX]                                                  ;AH = DSPFlag[EAX]
    Test    AH,S700_MUTE                                                        ;AH and S700_MUTE = S700_MUTE?
    JNZ     .VoiceOff                                                           ;   Yes
%endmacro

%macro MixVoice 0
%if STEREO
    Test    byte [EBX+mFlg],MFLG_KOFF
    JNZ     %%NoChVol
        Push    EAX,ECX,EDX
        LEA     ECX,[EBX+mChnL]
        CalRamp1
        LEA     ECX,[EBX+mChnR]
        CalRamp1
        Pop     EDX,ECX,EAX

    %%NoChVol:
%endif

%if VMETERV
    Sub     ESP,16                                                              ;Create a temporary stack space for samples
%endif
    FLd     ST
    Test    [dsp+eon],CH
    JNZ     short %%VoiceEcho
        FMul    dword [EBX+mChnL]
        Test    AH,S700_VOLUME                                                  ;AH and S700_VOLUME = S700_VOLUME?
        JZ      short %%NoEchoL                                                 ;   No
            MovZX   ESI,AL                                                      ;ESI = AL
            FIMul   dword [scr700vol+ESI*4]
            FMul    dword [fpShR16]

        %%NoEchoL:

%if VMETERV
        FISt    dword [ESP]                                                     ;Store sample as an integer
        FSt     dword [4+ESP]                                                   ;Store sample as an floating-point
%endif
        FAdd    dword [EDI]
        FStP    dword [EDI]

        FMul    dword [EBX+mChnR]
        Test    AH,S700_VOLUME                                                  ;AH and S700_VOLUME = S700_VOLUME?
        JZ      short %%NoEchoR                                                 ;   No
            MovZX   ESI,AL                                                      ;ESI = AL
            FIMul   dword [scr700vol+ESI*4]
            FMul    dword [fpShR16]

        %%NoEchoR:

%if VMETERV
        FISt    dword [8+ESP]
        FSt     dword [12+ESP]
%endif
        FAdd    dword [4+EDI]
        FSt     dword [4+EDI]
        Jmp     short %%NoVoiceEcho

    %%VoiceEcho:
        FMul    dword [EBX+mChnL]
        Test    AH,S700_VOLUME                                                  ;AH and S700_VOLUME = S700_VOLUME?
        JZ      short %%EchoL                                                   ;   No
            MovZX   ESI,AL                                                      ;ESI = AL
            FIMul   dword [scr700vol+ESI*4]
            FMul    dword [fpShR16]

        %%EchoL:

%if VMETERV
        FISt    dword [ESP]
        FSt     dword [4+ESP]
%endif
        FLd     ST
        FAdd    dword [EDI]
        FStP    dword [EDI]
        FAdd    dword [8+EDI]
        FStP    dword [8+EDI]

        FMul    dword [EBX+mChnR]
        Test    AH,S700_VOLUME                                                  ;AH and S700_VOLUME = S700_VOLUME?
        JZ      short %%EchoR                                                   ;   No
            MovZX   ESI,AL                                                      ;ESI = AL
            FIMul   dword [scr700vol+ESI*4]
            FMul    dword [fpShR16]

        %%EchoR:

%if VMETERV
        FISt    dword [8+ESP]
        FSt     dword [12+ESP]
%endif
        FLd     ST
        FAdd    dword [4+EDI]
        FStP    dword [4+EDI]
        FAdd    dword [12+EDI]
        FSt     dword [12+EDI]

    %%NoVoiceEcho:

%if VMETERV
    ;Save greatest sample output ----
    Test    dword [dspOpts],DSP_FLOAT                                           ;Is volume output floating-point?
    JNZ     short %%ChFloat                                                     ;   Yes
        Pop     EAX                                                             ;Pop left sample off stack
        Pop     EDX                                                             ;Unused
        CDQ                                                                     ;EDX:EAX = EAX
        XOr     EAX,EDX
        Sub     EAX,EDX

        Sub     EAX,[EBX+vMaxL]
        CDQ
        Not     EDX
        And     EAX,EDX
        Add     [EBX+vMaxL],EAX

        Pop     EAX                                                             ;Pop right sample off stack
        Pop     EDX                                                             ;Unused
        CDQ
        XOr     EAX,EDX
        Sub     EAX,EDX

        Sub     EAX,[EBX+vMaxR]
        CDQ
        Not     EDX
        And     EAX,EDX
        Add     [EBX+vMaxR],EAX

        Jmp     short %%Done

    %%ChFloat:
        Pop     EDX                                                             ;Unused
        Pop     EAX
        And     EAX,7FFFFFFFh

        Sub     EAX,[EBX+vMaxL]
        CDQ
        Not     EDX
        And     EAX,EDX
        Add     [EBX+vMaxL],EAX

        Pop     EDX                                                             ;Unused
        Pop     EAX
        And     EAX,7FFFFFFFh

        Sub     EAX,[EBX+vMaxR]
        CDQ
        Not     EDX
        And     EAX,EDX
        Add     [EBX+vMaxR],EAX

    %%Done:
%endif
%endmacro

%macro MixMaster 0
    ;Multiply samples by main volume ------
    Mov     ECX,nowMainL
    CalRamp2    1
    Mov     ECX,nowMainR
    CalRamp2    1

    FLd     dword [ESI]
    FMul    dword [nowMainL]
    Mov     AH,[scr700mds+S700_MVOL_L]
    Test    AH,S700_VOLUME                                                      ;AH and S700_VOLUME = S700_VOLUME?
    JZ      short %%NoMainL                                                     ;   No
        FIMul   dword [scr700mvl+S700_MVOL_L*4]
        FMul    dword [fpShR16]

    %%NoMainL:
    FStP    dword [ESI]

    FLd     dword [4+ESI]
    FMul    dword [nowMainR]
    Mov     AH,[scr700mds+S700_MVOL_R]
    Test    AH,S700_VOLUME                                                      ;AH and S700_VOLUME = S700_VOLUME?
    JZ      short %%NoMainR                                                     ;   No
        FIMul   dword [scr700mvl+S700_MVOL_R*4]
        FMul    dword [fpShR16]

    %%NoMainR:
    FStP    dword [4+ESI]
%endmacro

%macro MixEchoDSP 0
    Mov     EDI,[echoMaxD]
    Sub     EDI,[echoCurD]
    Add     EDI,echoBuf

    ZeroDN  4+EDI
    ZeroDN  EDI

    FLd     dword [4+EDI]                                                       ;                                   |FBR
    FLd     dword [EDI]                                                         ;                                   |FBR FBL

    ;Filter echo -----------------------
    Test    dword [dspOpts],DSP_NOFIR                                           ;Is FIR filter disabled?
    JNZ     %%NoFilter                                                          ;   Yes
        FIRFilter
    %%NoFilter:

    FLd     ST1                                                                 ;                                   |FBR FBL FBR
    FLd     ST1                                                                 ;                                   |FBR FBL FBR FBL

    ;Advance echo sample pointer -------
    Sub     dword [echoCurD],8
    JNZ     short %%NoReset
        Mov     EAX,[echoLenD]
        Mov     [echoMaxD],EAX
        Mov     [echoCurD],EAX

    %%NoReset:

    ;Add echo to main output -----------
    Mov     ECX,nowEchoL
    CalRamp2
    Mov     ECX,nowEchoR
    CalRamp2

    FMul    dword [nowEchoL]                                                    ;                                   |FBR FBL FBR FBL*EchoL
    Mov     AH,[scr700mds+S700_ECHO_L]
    Test    AH,S700_VOLUME                                                      ;AH and S700_VOLUME = S700_VOLUME?
    JZ      short %%NoEchoL                                                     ;   No
        FIMul   dword [scr700mvl+S700_ECHO_L*4]
        FMul    dword [fpShR16]

    %%NoEchoL:
    FAdd    dword [ESI]                                                         ;                                   |FBR FBL FBR EchoL+ML
    FStP    dword [ESI]                                                         ;                                   |FBR FBL FBR

    FMul    dword [nowEchoR]                                                    ;                                   |FBR FBL FBR*EchoR
    Mov     AH,[scr700mds+S700_ECHO_R]
    Test    AH,S700_VOLUME                                                      ;AH and S700_VOLUME = S700_VOLUME?
    JZ      short %%NoEchoR                                                     ;   No
        FIMul   dword [scr700mvl+S700_ECHO_R*4]
        FMul    dword [fpShR16]

    %%NoEchoR:
    FAdd    dword [4+ESI]                                                       ;                                   |FBR FBL FBR+MR
    FStP    dword [4+ESI]                                                       ;                                   |FBR FBL

    ;Calculate echo feedback -----------
%if STEREO
    FLd     ST                                                                  ;                                   |FBR FBL FBL
    FMul    dword [echoFB]                                                      ;                                   |FBR FBL FBL*EchoFB
    FLd     ST2                                                                 ;                                   |FBR FBL EFBL FBR
    FMul    dword [echoFBCT]                                                    ;                                   |FBR FBL EFBL FBR*EchoFBCT
    FAddP   ST1,ST                                                              ;                                   |FBR FBL EFBL+EFBCR
    FAdd    dword [8+ESI]                                                       ;                                   |FBR FBL EFBL+EL
    FStP    dword [EDI]                                                         ;                                   |FBR FBL
    ZeroDNEFB   EDI

    FMul    dword [echoFBCT]                                                    ;                                   |FBR FBL*EchoFBCT
    FXCh    ST1                                                                 ;                                   |EFBCL FBR
    FMul    dword [echoFB]                                                      ;                                   |EFBCL FBR*EchoFB
    FAddP   ST1,ST                                                              ;                                   |EFBCL+EFBR
    FAdd    dword [12+ESI]                                                      ;                                   |EFBR+ER
    FStP    dword [4+EDI]                                                       ;                                   |(empty)
    ZeroDNEFB   4+EDI
%else
    FMul    dword [echoFB]                                                      ;                                   |FBR FBL*EchoFB
    FAdd    dword [8+ESI]                                                       ;                                   |FBR EFBL+EL
    FStP    dword [EDI]                                                         ;                                   |FBR
    ZeroDNEFB   EDI

    FMul    dword [echoFB]                                                      ;                                   |FBR*EchoFB
    FAdd    dword [12+ESI]                                                      ;                                   |EFBR+ER
    FStP    dword [4+EDI]                                                       ;                                   |(empty)
    ZeroDNEFB   4+EDI
%endif
%endmacro

%macro MixEchoMem 0
    Push    EBX,ECX
    Mov     EDX,[echoDecM]
    Sub     EDX,32000
    JNS     short %%Skip

    Push    ECX                                                                 ;Dummy stack
    FLd     dword [EDI]
    FIStP   word [ESP]
    FLd     dword [4+EDI]
    FIStP   word [2+ESP]
    Pop     ECX                                                                 ;ECX = [ESP] (dword)
    And     ECX,~1 & ~10000h                                                    ;All numbers used by DSP are even

    %%Loop:
    Mov     EBX,[pAPURAM]
    Mov     BH,[dsp+esa]
    Mov     EAX,[echoMaxM]
    Sub     EAX,[echoCurM]
    Add     BX,AX
    Mov     [EBX],ECX

    Sub     dword [echoCurM],4
    JNZ     short %%NoReset
        Mov     EAX,[echoLenM]
        Mov     [echoMaxM],EAX
        Mov     [echoCurM],EAX

    %%NoReset:
    Add     EDX,[dspRate]
    JS      short %%Loop

    %%Skip:
    Mov     [echoDecM],EDX
    Pop     ECX,EBX
%endmacro

%macro NopEchoMem 0
    Mov     EDX,[echoDecM]
    Sub     EDX,32000
    JNS     short %%Skip

    %%Loop:
    Sub     dword [echoCurM],4
    JNZ     short %%NoReset
        Mov     EAX,[echoLenM]
        Mov     [echoMaxM],EAX
        Mov     [echoCurM],EAX

    %%NoReset:
    Add     EDX,[dspRate]
    JS      short %%Loop

    %%Skip:
    Mov     [echoDecM],EDX
%endmacro

%macro MixBASS 0
    ;Save Current Sample --------------
    Mov     ECX,[lowCnt1]                                                       ;ECX = Cnt1
    Mov     EDX,[lowCnt2]                                                       ;EDX = Cnt2

    Mov     EAX,[ESI]                                                           ;EAX = Current Sample (Left)
    Mov     [lowBufL1+ECX],EAX                                                  ;BufL1[ECX] = EAX
    Mov     [lowBufL2+EDX],EAX                                                  ;BufL2[EDX] = EAX
    Push    EAX                                                                 ;Push EAX (Save Current Sample)

    Mov     EAX,[ESI+4]                                                         ;EAX = Current Sample (Right)
    Mov     [lowBufR1+ECX],EAX                                                  ;BufR1[ECX] = EAX
    Mov     [lowBufR2+EDX],EAX                                                  ;BufR2[EDX] = EAX
    Push    EAX                                                                 ;Push EAX (Save Current Sample)

    Test    ECX,ECX                                                             ;ECX = 0x00?
    JNZ     short %%CountL                                                      ;   No
        Mov     ECX,[lowSize1]                                                  ;ECX = Size1

    %%CountL:
    Sub     ECX,4                                                               ;ECX -= 4
    Mov     [lowCnt1],ECX                                                       ;Cnt1 = ECX

    Test    EDX,EDX                                                             ;EDX = 0x00?
    JNZ     short %%CountR                                                      ;   No
        Mov     EDX,[lowSize2]                                                  ;EDX = Size2

    %%CountR:
    Sub     EDX,4                                                               ;EDX -= 4
    Mov     [lowCnt2],EDX                                                       ;Cnt2 = EDX

    ;Calculate BASS BOOST -------------
    FLd     dword [lowSumL1]                                                    ;Left                               |SumL1
    FSub    dword [lowBufL1+ECX]                                                ;                                   |SumL1-BufL1[ECX]
    FAdd    dword [ESI]                                                         ;                                   |SumL1-BufL1[ECX]+SampleL
    FSt     dword [lowSumL1]                                                    ;                                   |   "
    FMul    dword [lowLv1]                                                      ;                                   |BASS1=(SumL1-BufL1[EDX]+SampleL)*Lv1
    FLd     dword [lowSumL2]                                                    ;                                   |BASS1 SumL2
    FSub    dword [lowBufL2+EDX]                                                ;                                   |BASS1 SumL2-BufL2[EDX]
    FAdd    dword [ESI]                                                         ;                                   |BASS1 SumL2-BufL2[EDX]+SampleL
    FSt     dword [lowSumL2]                                                    ;                                   |   "
    FMul    dword [lowLv2]                                                      ;                                   |BASS1 BASS2=(SumL2-BufL2[EDX]+SampleL)*Lv2
    FSubP   ST1,ST                                                              ;                                   |BASS1-BASS2
    FAdd    dword [ESI]                                                         ;                                   |BASS1-BASS2+SampleL
    FStP    dword [ESI]                                                         ;                                   |(empty)
    ZeroDN  ESI

    FLd     dword [lowSumR1]                                                    ;Right                              |SumR1
    FSub    dword [lowBufR1+ECX]                                                ;                                   |SumR1-BufR1[ECX]
    FAdd    dword [ESI+4]                                                       ;                                   |SumR1-BufR1[ECX]+SampleR
    FSt     dword [lowSumR1]                                                    ;                                   |   "
    FMul    dword [lowLv1]                                                      ;                                   |BASS1=(SumR1-BufR1[EDX]+SampleR)*Lv1
    FLd     dword [lowSumR2]                                                    ;                                   |BASS1 SumR2
    FSub    dword [lowBufR2+EDX]                                                ;                                   |BASS1 SumR2-BufR2[EDX]
    FAdd    dword [ESI+4]                                                       ;                                   |BASS1 SumR2-BufR2[EDX]+SampleR
    FSt     dword [lowSumR2]                                                    ;                                   |   "
    FMul    dword [lowLv2]                                                      ;                                   |BASS1 BASS2=(SumR2-BufR2[EDX]+SampleR)*Lv2
    FSubP   ST1,ST                                                              ;                                   |BASS1-BASS2
    FAdd    dword [ESI+4]                                                       ;                                   |BASS1-BASS2+SampleR
    FStP    dword [ESI+4]                                                       ;                                   |(empty)
    ZeroDN  ESI+4

    ;Reset Buffer ---------------------
    Pop     EDX,ECX                                                             ;ECX = Current Sample (Left), EDX = (Right)

    Mov     EAX,[lowSize1]                                                      ;EAX = Size1
    Test    ECX,ECX                                                             ;ECX = 0x00?
    JNZ     short %%RstL1                                                       ;   No
        Mov     EAX,[lowRstL1]                                                  ;EAX = RstL1
        Dec     EAX                                                             ;EAX--, EAX = 0x00?
        JNZ     short %%RstL1                                                   ;   No
            Mov     [lowSumL1],EAX                                              ;SumL1 = EAX (0x00)
            Inc     EAX                                                         ;EAX++ (0x01)

    %%RstL1:
    Mov     [lowRstL1],EAX                                                      ;RstL1 = EAX

    Mov     EAX,[lowSize2]                                                      ;EAX = Size2
    Test    ECX,ECX                                                             ;ECX = 0x00?
    JNZ     short %%RstL2                                                       ;   No
        Mov     EAX,[lowRstL2]                                                  ;EAX = RstL2
        Dec     EAX                                                             ;EAX--, EAX = 0x00?
        JNZ     short %%RstL2                                                   ;   No
            Mov     [lowSumL2],EAX                                              ;SumL2 = EAX (0x00)
            Inc     EAX                                                         ;EAX++ (0x01)

    %%RstL2:
    Mov     [lowRstL2],EAX                                                      ;RstL2 = EAX

    Mov     EAX,[lowSize1]                                                      ;EAX = Size1
    Test    EDX,EDX                                                             ;EDX = 0x00?
    JNZ     short %%RstR1                                                       ;   No
        Mov     EAX,[lowRstR1]                                                  ;EAX = RstR1
        Dec     EAX                                                             ;EAX--, EAX = 0x00?
        JNZ     short %%RstR1                                                   ;   No
            Mov     [lowSumR1],EAX                                              ;SumR1 = EAX (0x00)
            Inc     EAX                                                         ;EAX++ (0x01)

    %%RstR1:
    Mov     [lowRstR1],EAX                                                      ;RstR1 = EAX

    Mov     EAX,[lowSize2]                                                      ;EAX = Size2
    Test    EDX,EDX                                                             ;EDX = 0x00?
    JNZ     short %%RstR2                                                       ;   No
        Mov     EAX,[lowRstR2]                                                  ;EAX = RstR2
        Dec     EAX                                                             ;EAX--, EAX = 0x00?
        JNZ     short %%RstR2                                                   ;   No
            Mov     [lowSumR2],EAX                                              ;SumR2 = EAX (0x00)
            Inc     EAX                                                         ;EAX++ (0x01)

    %%RstR2:
    Mov     [lowRstR2],EAX                                                      ;RstR2 = EAX
%endmacro

%macro ApplyLevel 0
%if VMETERM
    Mov     EAX,[ESI]                                                           ;EAX = |Left|
    And     EAX,7FFFFFFFh

    Test    dword [dspOpts],DSP_NOSAFE                                          ;Is volume safe disabled?
    JNZ     short %%NoMaxL                                                      ;   Yes
    Cmp     EAX,[fpMaxLv]
    JBE     short %%NoMaxL
        Mov     byte [dspMute],80h
        Or      byte [disFlag],80h

    %%NoMaxL:
    Sub     EAX,[vMMaxL]                                                        ;*** Positive floats can be operated on as integers ***
    CDQ
    Not     EDX
    And     EAX,EDX
    Add     [vMMaxL],EAX

    Mov     EAX,[4+ESI]                                                         ;EAX = |Right|
    And     EAX,7FFFFFFFh

    Test    dword [dspOpts],DSP_NOSAFE                                          ;Is volume safe disabled?
    JNZ     short %%NoMaxR                                                      ;   Yes
    Cmp     EAX,[fpMaxLv]
    JBE     short %%NoMaxR
        Mov     byte [dspMute],80h
        Or      byte [disFlag],80h

    %%NoMaxR:
    Sub     EAX,[vMMaxR]                                                        ;*** Positive floats can be operated on as integers ***
    CDQ
    Not     EDX
    And     EAX,EDX
    Add     [vMMaxR],EAX
%endif
%endmacro

%macro MixAAF 0
    Push    ESI,EBP

    %%Next:
        FLd     dword [aafBufL]                                                 ;Left:Filter1                       |z1
        FLd     dword [ESI]                                                     ;                                   |z1 in
        FLd     ST1                                                             ;                                   |z1 in z1
        FMul    dword [aaf1A1]                                                  ;                                   |z1 in z1*a1
        FSubP   ST1,ST                                                          ;                                   |z1 in-z1*a1
        FSt     dword [aafBufL]                                                 ;                                   |z1 in-z1*a1
        FMul    dword [aaf1B0]                                                  ;                                   |z1 (in-z1*a1)*b0
        FLd     ST1                                                             ;                                   |z1 (in-z1*a1)*b0 z1
        FMul    dword [aaf1B1]                                                  ;                                   |z1 (in-z1*a1)*b0 z1*b1
        FAddP   ST1,ST                                                          ;                                   |z1 (in-z1*a1)*b0+z1*b1=out
        FStP    dword [ESI]                                                     ;                                   |z1
        FStP    ST                                                              ;                                   |(empty)
        ZeroDN  ESI

        FLd     dword [aafBufL]                                                 ;Left:Filter2                       |z1
        FLd     dword [ESI]                                                     ;                                   |z1 in
        FLd     ST1                                                             ;                                   |z1 in z1
        FMul    dword [aaf2A1]                                                  ;                                   |z1 in z1*a1
        FSubP   ST1,ST                                                          ;                                   |z1 in-z1*a1
        FMul    dword [aaf2B0]                                                  ;                                   |z1 (in-z1*a1)*b0
        FLd     ST1                                                             ;                                   |z1 (in-z1*a1)*b0 z1
        FMul    dword [aaf2B1]                                                  ;                                   |z1 (in-z1*a1)*b0 z1*b1
        FAddP   ST1,ST                                                          ;                                   |z1 (in-z1*a1)*b0+z1*b1=in
        FLd     ST1                                                             ;                                   |z1 in z1
        FMul    dword [aaf2A1]                                                  ;                                   |z1 in z1*a1
        FSubP   ST1,ST                                                          ;                                   |z1 in-z1*a1
        FSt     dword [aafBufL]                                                 ;                                   |z1 in-z1*a1
        FMul    dword [aaf2B0]                                                  ;                                   |z1 (in-z1*a1)*b0
        FLd     ST1                                                             ;                                   |z1 (in-z1*a1)*b0 z1
        FMul    dword [aaf2B1]                                                  ;                                   |z1 (in-z1*a1)*b0 z1*b1
        FAddP   ST1,ST                                                          ;                                   |z1 (in-z1*a1)*b0+z1*b1=out
        FStP    dword [ESI]                                                     ;                                   |z1
        FStP    ST                                                              ;                                   |(empty)
        ZeroDN  ESI

        FLd     dword [aafBufR]                                                 ;Right:Filter1                      |z1
        FLd     dword [ESI+4]                                                   ;                                   |z1 in
        FLd     ST1                                                             ;                                   |z1 in z1
        FMul    dword [aaf1A1]                                                  ;                                   |z1 in z1*a1
        FSubP   ST1,ST                                                          ;                                   |z1 in-z1*a1
        FSt     dword [aafBufR]                                                 ;                                   |z1 in-z1*a1
        FMul    dword [aaf1B0]                                                  ;                                   |z1 (in-z1*a1)*b0
        FLd     ST1                                                             ;                                   |z1 (in-z1*a1)*b0 z1
        FMul    dword [aaf1B1]                                                  ;                                   |z1 (in-z1*a1)*b0 z1*b1
        FAddP   ST1,ST                                                          ;                                   |z1 (in-z1*a1)*b0+z1*b1=out
        FStP    dword [ESI+4]                                                   ;                                   |z1
        FStP    ST                                                              ;                                   |(empty)
        ZeroDN  ESI+4

        FLd     dword [aafBufR]                                                 ;Right:Filter2                      |z1
        FLd     dword [ESI+4]                                                   ;                                   |z1 in
        FLd     ST1                                                             ;                                   |z1 in z1
        FMul    dword [aaf2A1]                                                  ;                                   |z1 in z1*a1
        FSubP   ST1,ST                                                          ;                                   |z1 in-z1*a1
        FMul    dword [aaf2B0]                                                  ;                                   |z1 (in-z1*a1)*b0
        FLd     ST1                                                             ;                                   |z1 (in-z1*a1)*b0 z1
        FMul    dword [aaf2B1]                                                  ;                                   |z1 (in-z1*a1)*b0 z1*b1
        FAddP   ST1,ST                                                          ;                                   |z1 (in-z1*a1)*b0+z1*b1=in
        FLd     ST1                                                             ;                                   |z1 in z1
        FMul    dword [aaf2A1]                                                  ;                                   |z1 in z1*a1
        FSubP   ST1,ST                                                          ;                                   |z1 in-z1*a1
        FSt     dword [aafBufR]                                                 ;                                   |z1 in-z1*a1
        FMul    dword [aaf2B0]                                                  ;                                   |z1 (in-z1*a1)*b0
        FLd     ST1                                                             ;                                   |z1 (in-z1*a1)*b0 z1
        FMul    dword [aaf2B1]                                                  ;                                   |z1 (in-z1*a1)*b0 z1*b1
        FAddP   ST1,ST                                                          ;                                   |z1 (in-z1*a1)*b0+z1*b1=out
        FStP    dword [ESI+4]                                                   ;                                   |z1
        FStP    ST                                                              ;                                   |(empty)
        ZeroDN  ESI+4

        Add     ESI,16

    Dec     EBP
    JNZ     %%Next

    Pop     EBP,ESI
%endmacro

%macro InitSampling 0
    XOr     EBX,EBX
    XOr     EDX,EDX

    Mov     EAX,[smpCnt]                                                        ;smpCnt = (smpCnt + smpDec) % smpRate
    Add     EAX,[smpDec]
    Cmp     EAX,[smpRate]
    SetB    BL
    Dec     EBX
    And     EBX,[smpRate]
    Sub     EAX,EBX                                                             ;If the number of times is the least common multiple of
    SetZ    DL                                                                  ; smpRate and dspRate, DL = 1
    Mov     [smpCnt],EAX

    Mov     EAX,[smpCur]                                                        ;smpCur += smpAdj
    Add     EAX,[smpAdj]
    SetC    BL                                                                  ;If the next sample is reached, BL = 1
    XOr     DL,BL                                                               ;If smpCur completes one cycle without error, DL = 0
    Mov     EBX,[smpAdj]
    Sub     EAX,EBX
    Add     EBX,EDX
    Add     EAX,EBX                                                             ;Add at once including error
    SetNC   DL                                                                  ;If don't have enough samples, DL = 1
    Mov     [smpCur],EAX

    XOr     EBX,EBX                                                             ;If smpRst completes one cycle,
    Dec     dword [smpRst]                                                      ;   reset smpCur, smpCnt, smpRst, and DL = 0
    SetZ    BL                                                                  ;   (probably DL is already 0, just to be sure)
    Dec     EBX
    And     [smpCur],EBX
    And     [smpCnt],EBX
    And     DL,BL
    Not     EBX
    And     EBX,[smpDen]
    Or      [smpRst],EBX

    Cmp     dword [smpSize],-1                                                  ;Adjustment samples mode?
    JE      short %%SkipSize                                                    ;   Yes

    Add     EBP,EDX
    Dec     dword [smpSize]                                                     ;Buffer overflow check
    JNZ     short %%SkipSize                                                    ;If half-hearted sampling rate (ex. 44100Hz),
        XOr     EBP,EBP                                                         ; it will be write a few over samples due to
        Inc     EBP                                                             ; calculate errors

    %%SkipSize:                                                                 ;If the sample reference point has moved, DL = 0
%endmacro

%macro Resampling 0
    Test    dword [smpAdj],-1                                                   ;Convert sample rate?
    JZ      %%Direct                                                            ;   No

    InitSampling

    Mov     EBX,smpBuf
    Dec     DL                                                                  ;Has the sample reference point moved?
    JZ      short %%Filter                                                      ;   No, don't move sample history
        Mov     DL,3

        %%Tap:
            Mov     EAX,[8+EBX]
            Mov     [EBX],EAX
            Mov     EAX,[12+EBX]
            Mov     [4+EBX],EAX

            Add     EBX,8

        Dec     DL
        JNZ     short %%Tap

        Mov     EAX,[ESI]                                                       ;Store the latest sample to history
        Mov     [EBX],EAX
        Mov     EAX,[4+ESI]
        Mov     [4+EBX],EAX

        Add     EBX,-24
        Add     ESI,16

    %%Filter:
        Mov     EAX,[smpCur]
        ShR     EAX,2                                                           ;Shift right by 2 bits to prevent the sign from
        Mov     [ESP-12],EAX                                                    ; entering (max = 40000000h)
        FILd    dword [ESP-12]
        Mov     dword [ESP-12],40000000h
        FILd    dword [ESP-12]
        FDivP   ST1,ST
        FStP    dword [ESP-12]

        FLd     dword [24+EBX]                                                  ;A                                  |s3
        FSub    dword [16+EBX]                                                  ;                                   |s3-s2
        FSub    dword [EBX]                                                     ;                                   |s3-s2-s0
        FAdd    dword [8+EBX]                                                   ;                                   |s3-s2-s0+s1=A'
        FMul    dword [ESP-12]                                                  ;                                   |A'*Frac
        FMul    dword [ESP-12]                                                  ;                                   |A'*Frac^2
        FMul    dword [ESP-12]                                                  ;                                   |A'*Frac^3=A
        FLd     dword [EBX]                                                     ;B                                  |A s0
        FSub    dword [8+EBX]                                                   ;                                   |A s0-s1
        FSub    ST,ST1                                                          ;                                   |A s0-s1-A=B'
        FMul    dword [ESP-12]                                                  ;                                   |A B'*Frac
        FMul    dword [ESP-12]                                                  ;                                   |A B'*Frac^2=B
        FLd     dword [16+EBX]                                                  ;C                                  |A B s2
        FSub    dword [EBX]                                                     ;                                   |A B s2-s0=C'
        FMul    dword [ESP-12]                                                  ;                                   |A B C'*Frac=C
        FLd     dword [8+EBX]                                                   ;D                                  |A B C s1=D
        FAddP   ST1,ST                                                          ;                                   |A B C+D
        FAddP   ST1,ST                                                          ;                                   |A B+C+D
        FAddP   ST1,ST                                                          ;                                   |A+B+C+D
        FStP    dword [ESP-8]                                                   ;                                   |(empty)
        ZeroDN  ESP-8

        FLd     dword [28+EBX]                                                  ;A                                  |s3
        FSub    dword [20+EBX]                                                  ;                                   |s3-s2
        FSub    dword [4+EBX]                                                   ;                                   |s3-s2-s0
        FAdd    dword [12+EBX]                                                  ;                                   |s3-s2-s0+s1=A'
        FMul    dword [ESP-12]                                                  ;                                   |A'*Frac
        FMul    dword [ESP-12]                                                  ;                                   |A'*Frac^2
        FMul    dword [ESP-12]                                                  ;                                   |A'*Frac^3=A
        FLd     dword [4+EBX]                                                   ;B                                  |A s0
        FSub    dword [12+EBX]                                                  ;                                   |A s0-s1
        FSub    ST,ST1                                                          ;                                   |A s0-s1-A=B'
        FMul    dword [ESP-12]                                                  ;                                   |A B'*Frac
        FMul    dword [ESP-12]                                                  ;                                   |A B'*Frac^2=B
        FLd     dword [20+EBX]                                                  ;C                                  |A B s2
        FSub    dword [4+EBX]                                                   ;                                   |A B s2-s0=C'
        FMul    dword [ESP-12]                                                  ;                                   |A B C'*Frac=C
        FLd     dword [12+EBX]                                                  ;D                                  |A B C s1=D
        FAddP   ST1,ST                                                          ;                                   |A B C+D
        FAddP   ST1,ST                                                          ;                                   |A B+C+D
        FAddP   ST1,ST                                                          ;                                   |A+B+C+D
        FStP    dword [ESP-4]                                                   ;                                   |(empty)
        ZeroDN  ESP-4

        Jmp     short %%Exit

    %%Direct:
        Mov     EAX,[ESI]
        Mov     [ESP-8],EAX
        Mov     EAX,[4+ESI]
        Mov     [ESP-4],EAX

        Add     ESI,16

    %%Exit:
%endmacro

%macro MuteSampling 0
    Test    dword [smpAdj],-1                                                   ;Convert sample rate?
    JZ      %%Exit                                                              ;   No

    InitSampling

    Mov     EBX,smpBuf
    Dec     DL                                                                  ;Has the sample reference point moved?
    JZ      short %%Exit                                                        ;   No, don't move sample history
        Mov     DL,3

        %%Tap:
            Mov     EAX,[8+EBX]
            Mov     [EBX],EAX
            Mov     EAX,[12+EBX]
            Mov     [4+EBX],EAX

            Add     EBX,8

        Dec     DL
        JNZ     short %%Tap

        FSt     dword [EBX]                                                     ;Store the latest sample to history
        FSt     dword [4+EBX]

    %%Exit:
%endmacro

%macro DoneRunDSP 0
    Pop     EDX,EAX,EBX,EBP
    StC                                                                         ;Set carry
    RetN    EDI
%endmacro

;===================================================================================================
;Run DSP emulation
;
;Emulates the DSP of the SNES using floating-point instructions.
;If no mixing flag is set on, except for pitch modulation, noise generator, and mixing.
;
;In:
;   EAX-> Buffer to store output
;   EDX = Number of samples to create (1 - MIX_SIZE)
;
;Out:
;   CF  = Set, samples were created
;   EAX-> End of buffer
;   EDX = Number of samples to create
;
;   CF  = Clear, DSP is muted
;   EDI-> Buffer to store output
;   EDX = Number of samples to create
;
;Destroys:
;   ECX,ESI,EDI,ST0-ST7

PROC RunDSP

    Push    EBP,EBX,EAX,EDX                                                     ;Last register must be EAX,EDX
    FInit

    Test    byte [disFlag],80h                                                  ;Is DSP reset or volume safe mode? (disFlag = [7])
    JNZ     .Mute                                                               ;   Yes

    ;=========================================
    ; Mix voices

    Mov     EBP,[ESP]
    Mov     EDI,mixBuf

    .NextEmu:
        ;Generate Noise -----------------------
        NoiseGen

        Mov     EAX,[adsrAdj]                                                   ;Calculate number of times to update envelope
        Add     [adsrClk],EAX

        Test    dword [dspOpts],DSP_ENVSPD                                      ;Is synchronize envelope updates enabled?
        SetZ    CL                                                              ;   When yes, adsrCnt is not cleared
        Dec     CL                                                              ;   When no, always adsrCnt is set 1
        And     [adsrCnt],CL
        Inc     CL
        Or      [adsrCnt],CL

        ;Voice Loop ---------------------------
        XOr     ECX,ECX
        XOr     EAX,EAX
        Mov     EBX,mix
        Mov     [EDI],EAX
        Mov     [4+EDI],EAX
        Mov     [8+EDI],EAX
        Mov     [12+EDI],EAX
        Mov     CH,1

        .VoiceMix:
            Test    [voiceMix],CH
            JZ      .VoiceDone

            Test    [dspPMod],CH                                                ;Is pitch modulation enabled?
            JZ      short .NoPMod                                               ;   No, Pitch doesn't need to be adjusted
                PitchMod                                                        ;Apply pitch modulation
            .NoPMod:

%ifdef SPC700_INC
            Test    byte [envFlag],-1                                           ;Do nothing if envelope is suspended
            JNZ     .NoEnv
%endif

            Cmp     dword [smpSize],-1                                          ;Adjustment samples mode?
            JE      .NoEnv                                                      ;   Yes
                UpdateEnv                                                       ;Update envelope

            .NoEnv:
            MixSample                                                           ;                                   |smp
            MixVoice

            .VoiceOff:
            FStP    ST                                                          ;                                   |(empty)

            Cmp     dword [smpSize],-1                                          ;Adjustment samples mode?
            JE      .VoiceDone                                                  ;   Yes
                UpdateSrc                                                       ;Update sample position

            .VoiceDone:
            Sub     EBX,-80h

        Add     CH,CH
        JNZ     .VoiceMix

        Mov     [adsrCnt],CH                                                    ;Clear number of times to update envelope
        Add     EDI,16

    Dec     EBP
    JNZ     .NextEmu

    Test    byte [disFlag],8h                                                   ;Is pBuf NULL? (disFlag = [3])
    JNZ     .Mute                                                               ;   Yes

    ;=========================================
    ; Apply main volumes and mix in echo

    Mov     EBP,[ESP]
    Mov     ESI,mixBuf

    .NextSmp:
        Test    dword [dspOpts],DSP_NOMAIN                                      ;Is main output disabled?
        JNZ     .NoMain                                                         ;   Yes
            MixMaster
        .NoMain:

        Test    byte [disFlag],30h                                              ;Is echo disabled by DSP? (disFlag = [4][5])
        JNZ     .NoEchoDSP                                                      ;   Yes
            MixEchoDSP
        .NoEchoDSP:

        Test    byte [disFlag],31h                                              ;Is echo delay disabled? (disFlag = [0][4][5])
        JNZ     short .NoEchoMem                                                ;   Yes
            MixEchoMem
%if ECHOMEM
            Jmp     short .ExitEchoMem
%endif
        .NoEchoMem:
%if ECHOMEM
            NopEchoMem                                                          ;Increment cursor only
        .ExitEchoMem:
%endif

        Test    dword [dspOpts],DSP_BASS                                        ;Is BASS BOOST enabled?
        JZ      .NoBASS                                                         ;   No
            MixBASS
        .NoBASS:

        ApplyLevel
        Add     ESI,16

    Dec     EBP
    JNZ     .NextSmp

    Test    byte [disFlag],40h                                                  ;Is DSP emulation disabled? (disFlag = [6])
    JNZ     .Mute                                                               ;   Yes

    ;=========================================
    ; Store output

    Mov     ESI,mixBuf
    Mov     EDI,[ESP+4]
    Mov     EBP,[ESP]

    Test    dword [dspOpts],DSP_ANALOG                                          ;Is Anti-Alies filter enabled?
    JZ      .NoAAF                                                              ;   No
        MixAAF
    .NoAAF:

    Cmp     byte [dspChn],2
    JE      .OutStereo
    Cmp     byte [dspSize],-4
    JE      .OutMonoFloat

    Mov     ECX,4EFFFE00h                                                       ;ECX = 2147418112.0 (32767 << 16)

    .NextMonoInt:
        Resampling

        ;Clamp samples ------------------------
        Mov     EAX,[ESP-8]                                                     ;EAX = Sample
        XOr     EDX,EDX
        XOr     EBX,EBX
        BTR     EAX,31                                                          ;EAX = Absolute value
        RCR     EDX,1                                                           ;EDX = Sign of sample
        Sub     EAX,ECX
        SetA    BL                                                              ;EBX = -1 if EAX < ECX
        Dec     EBX
        And     EAX,EBX                                                         ;Clamp EAX
        Add     EAX,ECX
        Or      EAX,EDX                                                         ;Restore sign
        Mov     [ESP-8],EAX
        FLd     dword [ESP-8]

        Mov     EAX,[ESP-4]
        XOr     EDX,EDX
        XOr     EBX,EBX
        BTR     EAX,31
        RCR     EDX,1
        Sub     EAX,ECX
        SetA    BL
        Dec     EBX
        And     EAX,EBX
        Add     EAX,ECX
        Or      EAX,EDX
        Mov     [ESP-4],EAX
        FAdd    dword [ESP-4]

        FMul    dword [fp0_5]

        ;Reduce to integer form ---------------
        Mov     AL,[dspSize]
        Dec     AL
        JZ      short .OutMono8
        Dec     AL
        JZ      short .OutMono16
        Dec     AL
        JZ      short .OutMono24

        .OutMono32:
            FIStP   dword [EDI]
            Add     EDI,4

            Dec     EBP
            JNZ     .NextMonoInt
            DoneRunDSP

        .OutMono8:
            FIStP   dword [ESP-4]
            Mov     DL,[ESP-1]
            Add     DL,80h
            Mov     [EDI],DL
            Inc     EDI

            Dec     EBP
            JNZ     .NextMonoInt
            DoneRunDSP

        .OutMono16:
            FIStP   dword [ESP-4]
            Mov     DX,[ESP-2]
            Mov     [EDI],DX
            Add     EDI,2

            Dec     EBP
            JNZ     .NextMonoInt
            DoneRunDSP

        .OutMono24:
            FIStP   dword [ESP-4]
            Mov     DX,[ESP-3]
            Mov     AL,[ESP-1]
            Mov     [0+EDI],DX
            Mov     [2+EDI],AL
            Add     EDI,3

            Dec     EBP
            JNZ     .NextMonoInt
            DoneRunDSP

    ;32-bit floating-point -------------------
    .OutMonoFloat:
        Resampling

        FLd     dword [ESP-8]
        FAdd    dword [ESP-4]
        FMul    dword [fp0_5]
        FMul    dword [fpShR31]
        FStP    dword [EDI]
        ZeroDN  EDI
        Add     EDI,4

        Dec     EBP
        JNZ     .OutMonoFloat
        DoneRunDSP

    .OutStereo:
    Cmp     byte [dspSize],-4
    JE      .OutStereoFloat

    Mov     ECX,4EFFFE00h                                                       ;ECX = 2147418112.0 (32767 << 16)

    .NextStereoInt:
        Resampling

        ;Clamp samples ------------------------
        Mov     EAX,[ESP-8]                                                     ;EAX = Sample
        XOr     EDX,EDX
        XOr     EBX,EBX
        BTR     EAX,31                                                          ;EAX = Absolute value
        RCR     EDX,1                                                           ;EDX = Sign of sample
        Sub     EAX,ECX
        SetA    BL                                                              ;EBX = -1 if EAX < ECX
        Dec     EBX
        And     EAX,EBX                                                         ;Clamp EAX
        Add     EAX,ECX
        Or      EAX,EDX                                                         ;Restore sign
        Mov     [ESP-8],EAX
        FLd     dword [ESP-8]

        Mov     EAX,[ESP-4]
        XOr     EDX,EDX
        XOr     EBX,EBX
        BTR     EAX,31
        RCR     EDX,1
        Sub     EAX,ECX
        SetA    BL
        Dec     EBX
        And     EAX,EBX
        Add     EAX,ECX
        Or      EAX,EDX
        Mov     [ESP-4],EAX
        FLd     dword [ESP-4]

        ;Reduce to integer form ---------------
        Mov     AL,[dspSize]
        Dec     AL
        JZ      short .OutStereo8
        Dec     AL
        JZ      short .OutStereo16
        Dec     AL
        JZ      short .OutStereo24

        .OutStereo32:
            FIStP   dword [4+EDI]
            FIStP   dword [EDI]
            Add     EDI,8

            Dec     EBP
            JNZ     .NextStereoInt
            DoneRunDSP

        .OutStereo8:
            FIStP   dword [ESP-4]
            FIStP   dword [ESP-5]
            Mov     DX,[ESP-2]
            Add     DH,80h
            Add     DL,80h
            Mov     [EDI],DX
            Add     EDI,2

            Dec     EBP
            JNZ     .NextStereoInt
            DoneRunDSP

        .OutStereo16:
            FIStP   dword [ESP-4]
            FIStP   dword [ESP-6]
            Mov     EDX,[ESP-4]
            Mov     [EDI],EDX
            Add     EDI,4

            Dec     EBP
            JNZ     .NextStereoInt
            DoneRunDSP

        .OutStereo24:
            FIStP   dword [ESP-4]
            FIStP   dword [ESP-7]
            Mov     DX,[ESP-6]
            Mov     EAX,[ESP-4]
            Mov     [0+EDI],DX
            Mov     [2+EDI],EAX
            Add     EDI,6

            Dec     EBP
            JNZ     .NextStereoInt
            DoneRunDSP

    ;32-bit floating-point -------------------
    .OutStereoFloat:
        Resampling

        FLd     dword [ESP-8]
        FMul    dword [fpShR31]
        FStP    dword [EDI]
        FLd     dword [ESP-4]
        FMul    dword [fpShR31]
        FStP    dword [4+EDI]
        ZeroDN  EDI
        ZeroDN  4+EDI
        Add     EDI,8

        Dec     EBP
        JNZ     .OutStereoFloat
        DoneRunDSP

    .Mute:
    Mov     EBP,[ESP]
    XOr     EDI,EDI

    Test    byte [disFlag],8h                                                   ;Is pBuf NULL? (disFlag = [3])
    JZ      .MuteNext                                                           ;   No
    Test    dword [smpAdj],-1                                                   ;Convert sample rate?
    JZ      .MuteDone                                                           ;   No, done

    .SampleNext:
        InitSampling

    Dec     EBP
    JNZ     .SampleNext
    Jmp     .MuteDone

    .MuteNext:
        FLdZ
        MuteSampling
        FStP    ST
        Inc     EDI

    Dec     EBP
    JNZ     .MuteNext

    .MuteDone:
    Pop     EDX,EAX,EBX,EBP
    Mov     EDX,EDI
    Mov     EDI,EAX
    Cmp     EAX,1                                                               ;Set carry if pBuf is null, so EmuDSP doesn't crash

ENDP


;===================================================================================================
;Decompress Sound Source
;
;Decompresses a 9-byte bit-rate reduced block into 16 16-bit samples
;
;In:
;   AL  = Block header
;   ESI-> Sample Block
;   EDI-> Output buffer
;   EDX = Last sample of previous block
;   EBX = Next to last sample
;
;Out:
;   ESI-> Next Block
;   EDI-> After last sample
;   EDX = Last sample
;   EBX = Next to last sample
;
;Destroys:
;   EAX

%macro UnpckFilter1 0
    ;Add 15/16 of second sample -----------
    Mov     EBX,EDX                                                             ;EBX = Next to last sample
    Neg     EDX
    SAR     EDX,5
    LEA     EAX,[EDX*2+EBX]                                                     ;s = ((-p1 >> 4) & ~1) + p1

    ;Add delta ----------------------------
    Add     EAX,[ECX]                                                           ;s += delta
    MovSX   EDX,AX                                                              ;EDX = Last sample
%endmacro

%macro UnpckFilter2 0
    ;Subtract 15/16 of second sample ------
    Mov     EAX,EBX
    Neg     EBX
    SAR     EAX,5
    LEA     EAX,[EAX*2+EBX]                                                     ;s = ((p2 >> 4) & ~1) + -p2
    Mov     EBX,EDX                                                             ;EBX = Next to last sample

    ;Add 61/32 of last sample -------------
    LEA     EAX,[EDX*2+EAX]                                                     ;s += 2 * p1
    LEA     EDX,[EDX*2+EDX]
    Neg     EDX
    SAR     EDX,6
    LEA     EAX,[EDX*2+EAX]                                                     ;s += ((-3 * p1) >> 5) & ~1

    ;Add delta ----------------------------
    Add     EAX,[ECX]                                                           ;s += delta
    MovSX   EDX,AX                                                              ;EDX = Last sample
%endmacro

%macro UnpckFilter3 0
    ;Subtract 52/64 of second sample ------
    Mov     EAX,EBX
    LEA     EBX,[EBX*2+EBX]
    SAR     EBX,5
    Neg     EAX
    LEA     EAX,[EBX*2+EAX]                                                     ;s = (((p2 * 3) >> 4) & ~1) + -p2
    Mov     EBX,EDX                                                             ;EBX = Next to last sample

    ;Add 115/64 of last sample ------------
    LEA     EAX,[EDX*2+EAX]                                                     ;s += 2 * p1
    LEA     EDX,[EBX*4+EBX]
    LEA     EDX,[EBX*8+EDX]
    Neg     EDX
    SAR     EDX,7
    LEA     EAX,[EDX*2+EAX]                                                     ;s += ((-13 * p1) >> 6) & ~1

    ;Add delta ----------------------------
    Add     EAX,[ECX]                                                           ;s += delta
    MovSX   EDX,AX                                                              ;EDX = Last sample
%endmacro

%macro UnpckClamp 0
    Add     EAX,65536                                                           ;Clamp 16-bit sample to a 17-bit value,
    SAR     EAX,17                                                              ; because restored value by BRR is used in doubles.
    JZ      short %%OK
        SetS    DL                                                              ;If s < -65536 (FFFF0000h), s = 0000h = 0
        MovZX   EDX,DL                                                          ;If s >  65534 (0000FFFEh), s = FFFEh = -2
        Dec     EDX
        Add     EDX,EDX

    %%OK:
%endmacro

UnpckSrc:

    Push    ECX,EBP

    Inc     SI                                                                  ;Inc SI so pointer will wrap around a 16-bit value
    XOr     ECX,ECX
    Mov     CH,AL
    ShR     CH,4
    Add     ECX,brrTab                                                          ;ECX -> Row in brrTab
    Mov     EBP,8                                                               ;Decompress 8 bytes (16 nybbles)

    Test    AL,0Ch                                                              ;Does block use ADPCM compression?
    JZ      short .Filter0                                                      ;   No
    Test    AL,08h                                                              ;Does block use filter 1?
    JZ      short .Filter1                                                      ;   Yes
    Test    AL,04h                                                              ;Does block use filter 2?
    JZ      .Filter2                                                            ;   Yes
    Jmp     .Filter3                                                            ;Then it must use filter 3

    ;[Delta] ----------------------------------
    .Filter0:
        Mov     CL,[ESI]                                                        ;CL indexes delta value
        And     CL,0F0h                                                         ;ECX -> value
        ShR     CL,2

        Mov     EAX,[ECX]                                                       ;EAX = delta
        MovSX   EBX,AX                                                          ;EBX = Next to last sample
        Mov     [EDI],EBX

        Mov     CL,[ESI]
        Inc     SI
        And     CL,0Fh
        ShL     CL,2

        Mov     EAX,[ECX]
        MovSX   EDX,AX                                                          ;EDX = Last sample
        Mov     [2+EDI],DX
        Add     EDI,4

    Dec     EBP
    JNZ     short .Filter0
    Pop     EBP,ECX
    Ret

    ;[Delta]+[Smp-1](15/16) ------------------
    .Filter1:
        Mov     CL,[ESI]                                                        ;CL indexes delta value
        And     CL,0F0h                                                         ;ECX -> value
        ShR     CL,2

        UnpckFilter1
        UnpckClamp

        Mov     [EDI],EDX

        Mov     CL,[ESI]
        Inc     SI
        And     CL,0Fh
        ShL     CL,2

        UnpckFilter1
        UnpckClamp

        Mov     [2+EDI],DX
        Add     EDI,4

    Dec     EBP
    JNZ     short .Filter1
    Pop     EBP,ECX
    Ret

    ;[Delta]+[Smp-1](61/32)-[Smp-2](15/16) ---
    .Filter2:
        Mov     CL,[ESI]
        And     CL,0F0h
        ShR     CL,2

        UnpckFilter2
        UnpckClamp

        Mov     [EDI],EDX

        Mov     CL,[ESI]
        Inc     SI
        And     CL,0Fh
        ShL     CL,2

        UnpckFilter2
        UnpckClamp

        Mov     [2+EDI],DX
        Add     EDI,4

    Dec     EBP
    JNZ     .Filter2
    Pop     EBP,ECX
    Ret

    ;[Delta]+[Smp-1](115/64)-[Smp-2](13/16) --
    .Filter3:
        Mov     CL,[ESI]
        And     CL,0F0h
        ShR     CL,2

        UnpckFilter3
        UnpckClamp

        Mov     [EDI],EDX

        Mov     CL,[ESI]
        Inc     SI
        And     CL,0Fh
        ShL     CL,2

        UnpckFilter3
        UnpckClamp

        Mov     [2+EDI],DX
        Add     EDI,4

    Dec     EBP
    JNZ     .Filter3
    Pop     EBP,ECX
    Ret


;===================================================================================================
;Decompress Sound Source (Old school method)

UnpckSrcOld:

    Push    ECX

    ;Get range -------------------------------
    Mov     CL,0CFh
    Inc     SI
    Sub     CL,AL                                                               ;CL = 12 - Range (change range from << to >>)
    SetNC   AH                                                                  ;If result is negative (invalid range) add 3
    Dec     AH
    And     AH,30h
    Add     CL,AH
    ShR     CL,4

    Mov     CH,8
    Test    AL,0Ch
    JZ      short .Filter0

    Add     CL,10                                                               ;Values will be shifted right from 32-bit values
    Test    AL,08h
    JZ      short .Filter1

    Test    AL,04h
    JZ      .Filter2

    Jmp     .Filter3

    ;[Delta] ---------------------------------
    .Filter0:
        XOr     EAX,EAX
        XOr     EDX,EDX
        Mov     AH,[ESI]
        Mov     DH,AH
        And     AH,0F0h
        ShL     DH,4

        SAR     AX,CL
        SAR     DX,CL
        Mov     [EDI],AX
        Mov     [2+EDI],DX
        Add     EDI,4

        Inc     SI

    Dec     CH
    JNZ     short .Filter0
    MovSX   EDX,DX
    MovSX   EBX,AX
    Pop     ECX
    Ret

    ;[Delta]+[Smp-1](15/16) ------------------
    .Filter1:
        Mov     EBX,[ESI]
        And     BL,0F0h
        ShL     EBX,24
        SAR     EBX,CL

        Mov     EAX,EDX
        IMul    EAX,60
        Add     EBX,EAX
        SAR     EBX,6

        Mov     [EDI],EBX

        Mov     EDX,[ESI]
        ShL     EDX,28
        SAR     EDX,CL

        Mov     EAX,EBX
        IMul    EAX,60
        Add     EDX,EAX
        SAR     EDX,6

        Mov     [2+EDI],DX
        Add     EDI,4

        Inc     SI

    Dec     CH
    JNZ     short .Filter1
    Pop     ECX
    Ret

    ;[Delta]+[Smp-1](61/32)-[Smp-2](30/32) ---
    .Filter2:
        Mov     EAX,[ESI]
        And     AL,0F0h
        ShL     EAX,24
        SAR     EAX,CL

        ;Subtract 15/16 of second sample ------
        IMul    EBX,60
        Sub     EAX,EBX
        Mov     EBX,EDX

        ;Add 61/32 of last sample -------------
        IMul    EDX,122
        Add     EAX,EDX
        SAR     EAX,6

        Mov     [EDI],EAX

        Mov     EDX,[ESI]
        ShL     EDX,28
        SAR     EDX,CL

        IMul    EBX,60
        Sub     EDX,EBX
        Mov     EBX,EAX

        IMul    EAX,122
        Add     EDX,EAX
        SAR     EDX,6

        Mov     [2+EDI],DX
        Add     EDI,4

        Inc     SI

    Dec     CH
    JNZ     .Filter2
    Pop     ECX
    Ret

    ;[Delta]+[Smp-1](115/64)-[Smp-2](52/64) --
    .Filter3:
        Mov     EAX,[ESI]
        And     AL,0F0h
        ShL     EAX,24
        SAR     EAX,CL

        ;Subtract 13/16 of second sample ------
        IMul    EBX,52
        Sub     EAX,EBX
        Mov     EBX,EDX

        ;Add 115/64 of last sample ------------
        IMul    EDX,115
        Add     EAX,EDX
        SAR     EAX,6

        Mov     [EDI],EAX

        Mov     EDX,[ESI]
        ShL     EDX,28
        SAR     EDX,CL

        IMul    EBX,52
        Sub     EDX,EBX
        Mov     EBX,EAX

        IMul    EAX,115
        Add     EDX,EAX
        SAR     EDX,6

        Mov     [2+EDI],DX
        Add     EDI,4

        Inc     SI

    Dec     CH
    JNZ     .Filter3
    Pop     ECX
    Ret
