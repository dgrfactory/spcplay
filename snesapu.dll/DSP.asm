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
;                                                   Copyright (C) 2003-2026 degrade-factory
;
;List of users and dates who/when modified this file:
;   - degrade-factory in 2026-08-21
;   - Zenith in 2024-06-19
;===================================================================================================

%ifdef WIN64
    CPU     X64
    BITS    64
%else
    CPU     386
    BITS    32
%endif

;===================================================================================================
;Header files

%include "macro.inc"
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
    LOWBUF2     EQU 1152
    LOWLEN1     EQU LOWBUF1*2+LOWBUF2*2                                         ;Total size of BASS-BOOST buffer (without lowSize, lowLv)
    LOWLEN2     EQU 10


;===================================================================================================
;Structures



;===================================================================================================
;Data

%ifndef WINDOWS
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
    dspRegs     PTRTAB  RVolL,  RVolR,  RPitch, RPitch, RNull,  RADSR,  RADSR,  RGain
                PTRTAB  RNull,  RNull,  RNull,  RNull,  RMVolL, REFB,   RNull,  RFCf
                PTRTAB  RVolL,  RVolR,  RPitch, RPitch, RNull,  RADSR,  RADSR,  RGain
                PTRTAB  RNull,  RNull,  RNull,  RNull,  RMVolR, RNull,  RNull,  RFCf
                PTRTAB  RVolL,  RVolR,  RPitch, RPitch, RNull,  RADSR,  RADSR,  RGain
                PTRTAB  RNull,  RNull,  RNull,  RNull,  REVolL, RPMOn,  RNull,  RFCf
                PTRTAB  RVolL,  RVolR,  RPitch, RPitch, RNull,  RADSR,  RADSR,  RGain
                PTRTAB  RNull,  RNull,  RNull,  RNull,  REVolR, RNull,  RNull,  RFCf
                PTRTAB  RVolL,  RVolR,  RPitch, RPitch, RNull,  RADSR,  RADSR,  RGain
                PTRTAB  RNull,  RNull,  RNull,  RNull,  RKOn,   RNull,  RNull,  RFCf
                PTRTAB  RVolL,  RVolR,  RPitch, RPitch, RNull,  RADSR,  RADSR,  RGain
                PTRTAB  RNull,  RNull,  RNull,  RNull,  RKOff,  RNull,  RNull,  RFCf
                PTRTAB  RVolL,  RVolR,  RPitch, RPitch, RNull,  RADSR,  RADSR,  RGain
                PTRTAB  RNull,  RNull,  RNull,  RNull,  RFlg,   REDl,   RNull,  RFCf
                PTRTAB  RVolL,  RVolR,  RPitch, RPitch, RNull,  RADSR,  RADSR,  RGain
                PTRTAB  RNull,  RNull,  RNull,  RNull,  RNull,  REDl,   RNull,  RFCf

                ;Pointers to interpolation functions for each mixing routine
    intRout     PTRTAB  NoneInt,    LinearInt,  Point4Int,  Point4Int,  Point8Int,  Point4Int,  Point4Int,  Point4Int

                ;Pointers to interpolation table for each interpolation type
    tabRout     PTRTAB  0,          0,          cubicTab,   gaussTab,   sincTab,    gauss4Tab,  gauss4Tab,  gauss4Tab

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
    fpLowLv1    DD  0.003                                                       ;BASS-BOOST level (base 192kHz)
    fpLowLv2    DD  0.003
    fpLowBs1    DD  0.002                                                       ;BASS-BOOST buffer size (base 192kHz) (=LOWBUF1/192000)
    fpLowBs2    DD  0.006                                                       ;                                     (=LOWBUF2/192000)
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

%ifndef WINDOWS
SECTION .bss ALIGN=256
%else
SECTION .bss ALIGN=64

;This BSS must be aligned on at least a 256-byte boundary, if it is not, you will know as soon as
; you play a song.  Since neither the WIN32 or WIN64 build allows a maximum value greater than 64,
; the value is forcibly padded with zeros until it aligns with the 256-byte boundary.

    ALIGN  256, DB  0                                                           ;Force page alignment

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
    pTrace      resPTR  1                                                       ;-> Debugging vector
    pOutBuf     resPTR  1                                                       ;-> output buffer
    outLeft     resd    1                                                       ;Number of samples left to fill output buffer
    outCnt      resd    1                                                       ;t64 count at last call to EmuDSP
    outDec      resd    1                                                       ;Fractional number of samples to be generated
                resd    3-(PTRSIZE/4-1)*2

    ;DSP Options ---------------------- [4520]
    dspMix      resb    1                                                       ;Mixing routine
    dspChn      resb    1                                                       ;Number of channels being output
    dspSize     resb    1                                                       ;Size of samples in bytes
                resb    1

    dspRate     resd    1                                                       ;Sample rate (max 32kHz in actual emulation mode)
    dspOpts     resd    1                                                       ;Option flags passed to SetDSPOpt
    pitchBas    resd    1                                                       ;Base sample rate
    pitchAdj    resd    1                                                       ;Amount to adjust pitch rates [16.16]
    pInter      resPTR  1                                                       ;-> interpolation function
    pDecomp     resPTR  1                                                       ;-> sample decompression routine
                resd    4-(PTRSIZE/4-1)*2

    dspInter    resb    1                                                       ;Interpolation method
    voiceMix    resb    1                                                       ;Voices that are currently being mixed
    surround    resb    1                                                       ;Turn on surround sound  (OFF:0x00 / ON:0xFF)
    surroff     resb    1                                                       ;Turn off surround sound (OFF:0x00 / ON:0x80)

    ;Volume --------------------------- [4550]
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

    ;Noise ---------------------------- [4590]
    nRate       resd    1                                                       ;Noise sample rate reciprocal [.32]
    nfRate      resd    1
    nAcc        resd    1                                                       ;Noise accumulator [.32] (>= 1 generate a new sample)
    nfAcc       resd    1
    nSmp        resd    1                                                       ;Current Noise sample
    nfSmp       resd    1
    nSeed       resd    1                                                       ;Noise random seed
                resd    1

    ;Echo filtering ------------------- [45B0]
    firCur      resd    1                                                       ;Index of the first sample to feed into the filter
    firRate     resd    1                                                       ;Rate to feed samples into filter
                resd    2
    firTaps     resd    8                                                       ;Filter coefficents

    ;Echo ----------------------------- [45E0]
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

    ;Single source playback ----------- [4610]
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

    ;Emulation work ------------------- [4660]
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

    ;BASS BOOST ----------------------- [4690]
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

    ;Anti-Alies filter ---------------- [46D0]
    aaf1A1      resd    1                                                       ;Anti-Alies 1st filter coefficients
    aaf1B0      resd    1
    aaf1B1      resd    1
    aaf2A1      resd    1                                                       ;Anti-Alies 2nd filter coefficients
    aaf2B0      resd    1
    aaf2B1      resd    1
    aafBufL     resd    3                                                       ;Anti-Alies filter buffer (Left)
    aafBufR     resd    3                                                       ;Anti-Alies filter buffer (Right)

    ;ADSR/Gain ------------------------ [4700]
    adsrAdj     resd    1                                                       ;Update envelope rate adjustment (16.16)
    adsrClk     resw    1                                                       ;Update envelope rate clock
    adsrCnt     resw    1                                                       ;Number of times to update envelope
    adsrUpd     resb    1                                                       ;Number of updates executed by UpdateEnv
                resb    3
                resd    1

    ;Sampling rate converter ---------- [4710]
    smpBuf      resd    8                                                       ;Sample history buffer
    smpRate     resd    1                                                       ;Sample rate (max 192kHz)
    smpAdj      resd    1                                                       ;Sample rate adjustment
    smpDec      resd    1                                                       ;Sample rate (decimal)
    smpCur      resd    1                                                       ;Ratio between samples
    smpCnt      resd    1                                                       ;Ratio adjustment rate counter
    smpDen      resd    1                                                       ;Ratio adjustment reset timing
    smpRst      resd    1                                                       ;Ratio adjustment reset counter
                resd    1

    ;Storage buffers ------------------ [4750]
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

%ifndef WINDOWS
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

    ;NOTE (amd64 port): this used to write scratch FPU control words to [PSP-4]/[PSP-8], i.e. below
    ; the stack pointer without reserving that space.  x86's stdcall/cdecl ABI has no formal
    ; guarantee about that memory either, and Win64 in particular defines no red zone at all
    ; (unlike SysV) -- so this is reserved for real with Sub/Add PSP instead of assumed safe.

    Sub     PSP,8
    FStCW   [PSP+4]                                                             ;Save control state
    FStCW   [PSP+0]                                                             ;Set FPU to truncate when rounding
    Or      byte [PSP+1],1100b
    FLdCW   [PSP+0]

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

    FLdCW   [PSP+4]                                                             ;Restore control state
    Add     PSP,8

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

    LoadPtr PDI,mix                                                             ;Erase all mixer settings
    XOr     EAX,EAX
    Mov     ECX,256
    Rep     StoSD

    ;Build a look-up table for all possible expanded values in a BRR block.
    LoadPtr PDI,brrTab
    XOr     EBX,EBX                                                             ;EBX = Nybble to shift right by range
    Mov     CL,28                                                               ;ECX = Max range (+16 for 32-bit numbers)

    .Range:
        .Nybble:
            Mov     EAX,EBX                                                     ;EAX = Nybble >> Range
            SAR     EAX,CL
            And     EAX,~1                                                      ;All numbers used by DSP are even
            Mov     [PDI],EAX
            Add     PDI,4

        Add     EBX,10000000h                                                   ;Add 1 to uppermost nybble
        JNZ     .Nybble

        Add     PDI,0C0h

    Dec     CL
    Cmp     CL,15
    JA      .Range

    Mov     BL,3
    XOr     ECX,ECX

    .Invalid:
        XOr     EAX,EAX                                                         ;Positive nybbles turn into 0 when range > 12
        Mov     CL,8
        Rep     StoSD

        Mov     EAX,-4096                                                       ;Negative nybbles turn into -4096 when range > 12
        Mov     CL,8
        Rep     StoSD

        Add     PDI,0C0h

    Dec     BL
    JNZ     .Invalid

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

    LoadPtr PDI,cubicTab                                                        ;PDI -> Cubic array                 |FPU Stack after execution
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
        FIStP   word [PDI]                                                      ;Store value in cubicTab            |X1 X2 X3

        ;s[0] *= 1.5(x^3) - 2.5(x^2) + 1 ------
        FLd     dword [fn2_5]                                                   ;                                   |X1 X2 X3 -2.5
        FMul    ST,ST2                                                          ;                                   |X1 X2 X3 -2.5*X2=T1
        FLd     dword [fp1_5]                                                   ;                                   |X1 X2 X3 T1 1.5
        FMul    ST,ST2                                                          ;                                   |X1 X2 X3 T1 1.5*X3=T2
        FLd1                                                                    ;                                   |X1 X2 X3 T1 T2 1.0
        FAddP   ST1,ST                                                          ;                                   |X1 X2 X3 T1 T2+1
        FAddP   ST1,ST                                                          ;                                   |X1 X2 X3 T1+T2
        FMul    dword [fp32km1]                                                 ;                                   |X1 X2 X3 (T1+T2)*32767
        FIStP   word [PDI+2]                                                    ;                                   |X1 X2 X3

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
        FIStP   word [PDI+4]                                                    ;                                   |X1 X2 X3

        ;s[2] *= .5(x^3) - .5(x^2) ------------
        FLd     dword [fn0_5]                                                   ;                                   |X1 X2 X3 -0.5
        FMul    ST,ST2                                                          ;                                   |X1 X2 X3 -0.5*X2=T1
        FLd     dword [fp0_5]                                                   ;                                   |X1 X2 X3 T1 0.5
        FMul    ST,ST2                                                          ;                                   |X1 X2 X3 T1 0.5*X3=T2
        FAddP   ST1,ST                                                          ;                                   |X1 X2 X3 T1+T2
        FMul    dword [fp32km1]                                                 ;                                   |X1 X2 X3 (T1+T2)*32767
        FIStP   word [PDI+6]                                                    ;                                   |X1 X2 X3
        Add     PDI,8

        FStP    ST                                                              ;Pop X's off stack                  |X1 X2
        FStP    ST                                                              ;                                   |X1
        FStP    ST                                                              ;                                   |(empty)

    Inc     byte [ipD]
    JNZ     .NextC

    ;Interleave Gaussian table ---------------
    LoadPtr PSI,gaussTab
    LoadPtr PDI,mixBuf
    Mov     ECX,512
    Rep     MovSD
    LoadPtr PSI,mixBuf
    LoadPtr PDI,gaussTab

    XOr     CL,CL
    .NextG:
        Mov     AX,[PSI]
        Mov     [PDI+6],AX
        Mov     AX,[PSI+512]
        Mov     [PDI+4],AX
        Mov     AX,[PSI+1024]
        Mov     [PDI+2],AX
        Mov     AX,[PSI+1536]
        Mov     [PDI+0],AX
        Add     PDI,8
        Add     PSI,2

    Dec     CL
    JNZ     .NextG

    ;Build a look-up table for 8-point sinc interpolation with a Hanning window.
    ;
    ;  sin(4pi x)
    ;  ---------- * (0.5 + 0.5cos(pi x))
    ;    4pi x
    ;

    ;If ipD were initialized to -768 (-3.0), a divide by zero error would occur when building the table.
    ;So we manually initialize the first row, which is easy to do.

    LoadPtr PDI,sincTab
    XOr     EAX,EAX
    Mov     [PDI],EAX
    Mov     [PDI+4],EAX
    Mov     [PDI+8],EAX
    Mov     [PDI+12],EAX
    Mov     word [PDI+6],32767                                                  ;Set first row to 0 0 0 1 0 0 0 0
    Add     PDI,16
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
            FIStP   word [PDI]                                                  ;Store                              |(empty)
            Add     PDI,2

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
    LoadPtr PDI,gauss4Tab                                                       ;PDI -> Gauss array                 |FPU Stack after execution
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
        FIStP   word [PDI+6]                                                    ;                                   |A pi 256 x

        FAdd    ST,ST1                                                          ;                                   |A pi 256 x+256
        FLd     ST                                                              ;                                   |A pi 256 x x
        FDiv    ST,ST3                                                          ;                                   |A pi 256 x x/pi
        FMul    ST,ST                                                           ;                                   |A pi 256 x p^2
        FMul    dword [fpShR1]                                                  ;                                   |A pi 256 x p/2
        FChS                                                                    ;                                   |A pi 256 x -p
        Call    Exp                                                             ;                                   |A pi 256 x e^p
        FMul    ST,ST4                                                          ;                                   |A pi 256 x e*A
        FIStP   word [PDI+4]                                                    ;                                   |A pi 256 x

        FAdd    ST,ST1                                                          ;                                   |A pi 256 x+256
        FLd     ST                                                              ;                                   |A pi 256 x x
        FDiv    ST,ST3                                                          ;                                   |A pi 256 x x/pi
        FMul    ST,ST                                                           ;                                   |A pi 256 x p^2
        FMul    dword [fpShR1]                                                  ;                                   |A pi 256 x p/2
        FChS                                                                    ;                                   |A pi 256 x -p
        Call    Exp                                                             ;                                   |A pi 256 x e^p
        FMul    ST,ST4                                                          ;                                   |A pi 256 x e*A
        FIStP   word [PDI+2]                                                    ;                                   |A pi 256 x

        FAdd    ST,ST1                                                          ;                                   |A pi 256 x+256
        FDiv    ST,ST2                                                          ;                                   |A pi 256 x/pi
        FMul    ST,ST                                                           ;                                   |A pi 256 p^2
        FMul    dword [fpShR1]                                                  ;                                   |A pi 256 p/2
        FChS                                                                    ;                                   |A pi 256 -p
        Call    Exp                                                             ;                                   |A pi 256 e^p
        FMul    ST,ST3                                                          ;                                   |A pi 256 e*A
        FIStP   word [PDI]                                                      ;                                   |A pi 256

        Add     PDI,8

    Inc     byte [ipD]
    JNZ     .NextG4

    FStP    ST                                                                  ;                                   |A pi
    FStP    ST                                                                  ;                                   |A
    FStP    ST                                                                  ;                                   |(empty)

    Call    SetDSPOpt,1,2,16,32000,INT_GAUSS,0
    Call    SetDSPDbgI,0

ENDP


;===================================================================================================
;Erase echo filter memory

PROC ResetEcho

    XOr     EAX,EAX

    LoadPtr PDI,echoBuf
    Mov     ECX,ECHOBUF
    Rep     StoSD

    LoadPtr PDI,firBuf
    Mov     ECX,FIRBUF
    Add     ECX,FIRBUF/2
    Rep     StoSD

ENDP


;===================================================================================================
;Erase BASS-BOOST memory

PROC ResetLow

    XOr     EAX,EAX

    LoadPtr PDI,lowBufL1
    Mov     ECX,LOWLEN1
    Rep     StoSD
    LoadPtr PDI,lowRstL1
    Mov     ECX,LOWLEN2
    Rep     StoSD
    Inc     dword [lowRstL1]
    Inc     dword [lowRstL2]
    Inc     dword [lowRstR1]
    Inc     dword [lowRstR2]

    LoadPtr PDI,aafBufL
    Mov     ECX,6
    Rep     StoSD

ENDP


;===================================================================================================
;Erase sampling rate converter memory

PROC ResetResamp

    Mov     EAX,[smpDen]
    Mov     [smpRst],EAX

    XOr     EAX,EAX
    Mov     [smpCur],EAX
    Mov     [smpCnt],EAX

    LoadPtr PDI,smpBuf
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
    LoadPtr PDI,dsp
    Mov     ECX,32
    Rep     StoSD
    Mov     byte [dsp+flg],0E0h                                                 ;Place DSP in power up mode

    ;Erase internal mixing settings ----------
    Mov     BH,8
    LoadPtr PDI,mix

    .ClrMix:
        Mov     BL,[PDI+mFlg]
        And     BL,MFLG_USER                                                    ;Leave user voice flags (mute and noise)
        Or      BL,MFLG_OFF                                                     ;Set voice to inactive

        Mov     CL,32
        Rep     StoSD
        Mov     [PDI-80h+mFlg],BL

    Dec     BH
    JNZ     .ClrMix

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

    LoadPtr PDI,firTaps                                                         ;Reset filter coefficients
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
    Call    SetDSPVolI,10000h

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
    JE      .DefMix
        XOr     EAX,EAX
        Test    EDX,EDX
        SetNZ   AL

    .DefMix:
    Mov     [mixType],EAX

    ;numChn ----------------------------------
    MovZX   EAX,byte [dspChn]
    Mov     EDX,[numChn]
    Cmp     EDX,-1
    JE      .DefChn
        Mov     EAX,EDX

        Cmp     EDX,1
        JE      .DefChn
        Cmp     EDX,2
        JE      .DefChn
;       Cmp     EDX,4
;       JE      short .DefChn

        Mov     EAX,2

    .DefChn:
    Mov     [numChn],EAX

    ;bits ------------------------------------
    MovZX   EAX,byte [dspSize]
    Mov     EDX,[bits]
    Cmp     EDX,-1
    JE      .DefBits
        Mov     EAX,EDX
        SAR     EAX,3

        Cmp     EDX,8
        JE      .DefBits
        Cmp     EDX,16
        JE      .DefBits
        Cmp     EDX,24
        JE      .DefBits
        Cmp     EDX,32
        JE      .DefBits
        Cmp     EDX,-32
        JE      .DefBits

        Mov     EAX,2

    .DefBits:
    Mov     [bits],EAX

    ;rate ------------------------------------
    Mov     EAX,[smpRate]
    Mov     EDX,[rate]
    Cmp     EDX,-1
    JE      .DefRate
        Mov     EAX,EDX
        XOr     ECX,ECX

        Cmp     EDX,8000
        SetB    CL
        Cmp     EDX,192000
        SetA    CH
        Test    ECX,ECX
        JZ      .DefRate

        Mov     EAX,32000

    .DefRate:
    Mov     [rate],EAX

    ;inter -----------------------------------
    MovZX   EAX,byte [dspInter]
    Mov     EDX,[inter]
    Cmp     EDX,-1
    JE      .DefInter
        Mov     EAX,EDX
        Cmp     EDX,7
        JBE     .DefInter

        Mov     EAX,3

    .DefInter:
    Mov     [inter],EAX

    IdxLd   Mov,PSI,tabRout,PAX*PTRSIZE
    Test    PSI,PSI
    JZ      .NoCopyTable
        LoadPtr PDI,interTab
        Mov     ECX,1024
        Rep     MovSD

    .NoCopyTable:

    ;opts ------------------------------------
    Mov     EDX,[dspOpts]
    Mov     EAX,[opts]
    Cmp     EAX,-1
    JE      .DefOpts
        Mov     EDX,EAX

    .DefOpts:
    Mov     [opts],EDX

    ;=========================================
    ;Options

    ;Select ADPCM routine --------------------
    LblSt   pDecomp,UnpckSrc
    Test    EDX,DSP_OLDSMP
    JZ      .NewSmp
        LblSt   pDecomp,UnpckSrcOld

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
    JZ      .NoMix
        IdxLd   Mov,PAX,intRout,PAX*PTRSIZE
        Mov     [pInter],PAX

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
        JZ      .SMPROK                                                         ;   No

        Cmp     EAX,32000                                                       ;Is the sampling rate less than 32kHz?
        JBE     .SMPROK                                                         ;   Yes
            Mov     EAX,32000                                                   ;EAX = Least common multiple of 32000 and smpRate
            Mov     ECX,[smpRate]

            .LoopGCM:
            XOr     EDX,EDX
            Div     ECX
            Mov     EAX,ECX
            Test    EDX,EDX
            JZ      .ExitGCM
                Mov     ECX,EDX
                Jmp     .LoopGCM

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
        LoadPtr PSI,freqTab
        LoadPtr PDI,rateTab
        Mov     EBX,32000
        Mov     ECX,31

        .CalcRT:
            Mov     EAX,[PSI+PCX*4]
            ShL     EAX,16
            Mul     dword [dspRate]
            Div     EBX

            Cmp     EAX,10000h
            JAE     .RTOK
                Mov     EAX,10000h

            .RTOK:
            Mov     [PDI+PCX*4],EAX

        Dec     ECX
        JNZ     .CalcRT
        Mov     [PDI],ECX

        ;Volume ramping rate ------------------
        Mov     dword [PSP-4],32000
        FILd    dword [PSP-4]
        FIDiv   dword [dspRate]
        FMul    dword [fpShR8]
        FSt     dword [volRamp1]
        FIMul   dword [volAmp]
        FStP    dword [volRamp2]

        ;Reset FIR info -----------------------
        XOr     EAX,EAX
        Mov     [firCur],EAX

        Mov     EAX,[dspRate]
        MovZX   EDX,word [dspRate+2]
        ShL     EAX,16
        Mov     ECX,32000
        Div     ECX
        Mov     [firRate],EAX                                                   ;firRate = (dspRate<<16) / 32kHz

        ;Adjust voice rates -------------------
        Mov     EBX,7*80h                                                       ;Adjust the current rates in each voice incase the
                                                                                ; sample rate is being changed during emulation
        .Voice:
            IdxLd   Mov,EAX,mix,PBX+mOrgP                                       ;Set pitch
            IdxLdX  MovZX,PDX,byte,mix,PBX+mSrc                                 ;EDX = Source
            IdxLd   Add,EAX,scr700det,PDX*4                                     ;EAX += Detune[EDX]

            Mul     dword [pitchAdj]
            ShRD    EAX,EDX,16
            AdC     EAX,0
            IdxSt   Mov,mix,PBX+mRate,EAX

            IdxLdX  MovZX,PDI,byte,mix,PBX+eRIdx                                ;Set envelope adjustment
            IdxLd   Mov,EAX,rateTab,PDI*4,PDX
            IdxSt   Mov,mix,PBX+eRate,EAX
            IdxSt   Mov,mix,PBX+eCnt,EAX

        Add     EBX,-80h
        JNS     .Voice

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
        Mov     dword [PSP-4],2
        FISub   dword [PSP-4]                                                   ;                                   |wdt -2+wdt
        FILd    dword [PSP-4]                                                   ;                                   |wdt -2+wdt 2
        FAdd    ST,ST2                                                          ;                                   |wdt -2+wdt 2+wdt
        FDivP   ST1,ST                                                          ;                                   |wdt -2+wdt/2+wdt
        FStP    dword [aaf1A1]                                                  ;                                   |wdt

        ;B0 = B1 = wdt / (2 + wdt)
        Mov     dword [PSP-4],2
        FILd    dword [PSP-4]                                                   ;                                   |wdt 2
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
        Mov     dword [PSP-4],2
        FISub   dword [PSP-4]                                                   ;                                   |wdt -2+wdt
        FILd    dword [PSP-4]                                                   ;                                   |wdt -2+wdt 2
        FAdd    ST,ST2                                                          ;                                   |wdt -2+wdt 2+wdt
        FDivP   ST1,ST                                                          ;                                   |wdt -2+wdt/2+wdt
        FStP    dword [aaf2A1]                                                  ;                                   |wdt

        ;B0 = B1 = wdt / (2 + wdt)
        Mov     dword [PSP-4],2
        FILd    dword [PSP-4]                                                   ;                                   |wdt 2
        FAdd    ST,ST1                                                          ;                                   |wdt 2+wdt
        FDivP   ST1,ST                                                          ;                                   |wdt/2+wdt
        FSt     dword [aaf2B0]                                                  ;                                   |wdt/2+wdt
        FStP    dword [aaf2B1]                                                  ;                                   |(empty)

    .SameRate:

    ;=========================================
    ;Set sample size

    Mov     AL,[bits]
    Cmp     AL,[dspSize]                                                        ;If the sample size has changed, CL = 1
    JE      .SameBits
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
    JE      .SameMix
        Mov     [dspMix],AL
        Or      dword [fixVol],-1                                               ;Force volumes to be recalculated

    .SameMix:

    ;=========================================
    ;Erase sample buffers

    Test    byte [fixVol+1],-1
    JZ      .NoEraseBuf
        Call    ResetEcho

    .NoEraseBuf:
    Test    byte [fixVol+2],-1
    JZ      .NoEraseLow
        Call    ResetLow

    .NoEraseLow:
    Test    byte [fixVol+3],-1
    JZ      .NoEraseResamp
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
            IdxLd   Mov,AL,dsp,PCX+volL
            Call    InitReg
            IdxLd   Mov,EAX,mix,PCX*8+mTgtL
            IdxSt   Mov,mix,PCX*8+mChnL,EAX

            LEA     EBX,[ECX+volR]
            IdxLd   Mov,AL,dsp,PCX+volR
            Call    InitReg
            IdxLd   Mov,EAX,mix,PCX*8+mTgtR
            IdxSt   Mov,mix,PCX*8+mChnR,EAX

            LEA     EBX,[ECX+fc]
            IdxLd   Mov,AL,dsp,PCX+fc
            Call    InitReg

        Sub     CL,10h
        JNC     .NextVoice

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

;Called internally by InitDSP (see x64.inc's EXPROC for why a DEF-exported name also called
; internally needs this split).

EXPROC SetDSPDbg, pTraceFunc

    Mov     PAX,[pTraceFunc]
    Call    SetDSPDbgI,PAX

ENDP

PROC SetDSPDbgI, pTraceFuncI
USES EDX

    Mov     PDX,[pTrace]

    Mov     PAX,[pTraceFuncI]
    Cmp     PAX,-1
    JE      .NoFunc
        Mov     [pTrace],PAX

    .NoFunc:
    Mov     PAX,PDX

ENDP


;===================================================================================================
;Fix DSP After Loading Saved State

PROC FixDSP
USES ALL

    ;NOTE (amd64 port): EBX/ECX/AL here are DSP register numbers/values (per InitReg/DSPInC's own
    ; documented 'EBX = DSP register number' interface), not pointers -- no width change needed for
    ; those.  The dsp/mix accesses below use IdxLd/IdxSt (RIP-relative cannot include an index
    ; register).

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
        IdxLd   Mov,AL,dsp,PCX+volL
        Call    InitReg
        IdxLd   Mov,EAX,mix,PCX*8+mTgtL
        IdxSt   Mov,mix,PCX*8+mChnL,EAX

        LEA     EBX,[ECX+volR]
        IdxLd   Mov,AL,dsp,PCX+volR
        Call    InitReg
        IdxLd   Mov,EAX,mix,PCX*8+mTgtR
        IdxSt   Mov,mix,PCX*8+mChnR,EAX

        LEA     EBX,[ECX+fc]
        IdxLd   Mov,AL,dsp,PCX+fc
        Call    InitReg

    Sub     CL,10h
    JNC     .NextTap

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
        LoadPtr PDI,mix

        .ResetMix:
            Mov     [PDI+eVal],EAX
            Mov     [PDI+mOut],EAX
            And     byte [PDI+mFlg],MFLG_USER                                   ;Leave user voice flags (mute and noise)
            Or      byte [PDI+mFlg],MFLG_OFF                                    ;Set voice to inactive
            Sub     PDI,-80h

        Dec     CL
        JNZ     .ResetMix

        Mov     CL,8
        LoadPtr PDI,dsp

        .ResetDSP:
            Mov     [PDI+envx],AL
            Mov     [PDI+outx],AL
            Add     PDI,10h

        Dec     CL
        JNZ     .ResetDSP

        Call    FixDSP

    .NoReset:
    Call    ResetEcho
    Call    ResetLow
;   Call    ResetResamp                                                         ;Do not reset because noise occurs by seek
    Call    SetFade

ENDP


;===================================================================================================
;DSP Pitch Adjustment

EXPROC SetDSPPitch, base
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
        IdxLd   Mov,EAX,mix,PBX+mOrgP                                           ;Set pitch
        IdxLdX  MovZX,PDX,byte,mix,PBX+mSrc                                     ;EDX = Source
        IdxLd   Add,EAX,scr700det,PDX*4                                         ;EAX += Detune[EDX]

        Mul     dword [pitchAdj]
        ShRD    EAX,EDX,16
        AdC     EAX,0
        IdxSt   Mov,mix,PBX+mRate,EAX

    Add     EBX,-80h
    JNS     .Voice

ENDP


;===================================================================================================
;DSP Amplification

;Called internally by ResetAPUI (see x64.inc's EXPROC for why a DEF-exported name also called
; internally needs this split).

EXPROC SetDSPAmp, amp

    Call    SetDSPAmpI,[amp]

ENDP

PROC SetDSPAmpI, ampI
USES ECX,EDX,EBX

    Mov     EAX,[ampI]                                                          ;If amp < 0, amp = 0
    CDQ
    Not     EDX
    And     EAX,EDX

    Cmp     EAX,256
    JA      .NewScale
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

;Called internally by ResetDSP/SetFade (see x64.inc's EXPROC for why a DEF-exported name also called
; internally needs this split).

EXPROC SetDSPVol, vol

    Call    SetDSPVolI,[vol]

ENDP

PROC SetDSPVolI, volI
USES ECX,EDX,EBX

    Mov     EAX,[volI]                                                          ;If EAX < 0, EAX = 0
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

    ;Call   ResetVol                                                            ;Do not call ResetVol to smooth fade-out

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
    JB      .SetFade
        Call    SetDSPVolI,10000h
        RetN    EDX

    .SetFade:
        Push    PDX
        Call    SetFade                                                         ;If song is in fade mode, set fade volume
        Pop     PAX

ENDP


;===================================================================================================
;Set Fade Volume
;
;Calls SetDSPVol to fade the song out based on t64Cnt, songLen, and fadeLen.

PROC SetFade
LOCALS fadeTmp

    Mov     EAX,[t64Cnt]                                                        ;EAX = T64Cnt - songLen;
    Sub     EAX,[songLen]                                                       ;If T64Cnt <= songLen, do nothing
    JBE     .Done

    XOr     EDX,EDX                                                             ;If EAX >= fadeLen, call SetDSPVol(0)
    Cmp     EAX,[fadeLen]
    JAE     .SetVol

    Mov     [fadeTmp],EAX                                                       ;EDX = 65536 - 65536 * sin(EAX / fadeLen * pi / 2)
    FILd    dword [fadeTmp]                                                     ;                                   |EAX
    FIDiv   dword [fadeLen]                                                     ;                                   |EAX/fadeLen
    FLdPi                                                                       ;                                   |EAX/fadeLen pi
    FMulP   ST1,ST                                                              ;                                   |EAX/fadeLen*pi
    FMul    dword [fp0_5]                                                       ;                                   |EAX/fadeLen*pi/2=x
    FSin                                                                        ;                                   |sin(x)
    Mov     EDX,65536
    Mov     [fadeTmp],EDX
    FILd    dword [fadeTmp]                                                     ;                                   |sin(x) 65536
    FMul                                                                        ;                                   |sin(x)*65536
    FIStP   dword [fadeTmp]                                                     ;                                   |(empty)
    Mov     EAX,[fadeTmp]                                                       ;EAX = 65536 * sin(x)
    Sub     EDX,EAX                                                             ;EDX = 65536 - EAX

    .SetVol:
    Call    SetDSPVolI,EDX                                                      ;SetDSPVol(EDX);

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
LOCALS panTmp1,panTmp2                                                          ;panTmp2 alone is used as an 8-byte scratch
USES ECX,EBX                                                                    ; (see the .Center: block below)

    ShR     PBX,3
    IdxLd   Mov,AL,dsp,PBX+volL
    IdxLd   Mov,DL,dsp,PBX+volR

    Test    dword [dspOpts],DSP_REVERSE                                         ;Swap left, right?
    JZ      .NoReverse                                                          ;   No
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

    IdxLd   LEA,PBX,mix,PBX*8
    Mov     [PBX+mTgtL],EAX
    Mov     [PBX+mTgtR],EDX

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
    FILd    dword [PBX+mTgtR]
    FMul    dword [fpShR7]
    FLd     ST
    FMul    ST,ST
    FILd    dword [PBX+mTgtL]
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
    Test    byte [volSepar+3],80h
    JNZ     .Center
        FSt     qword [panTmp2]
        FLd     dword [fp0_5]
        Test    byte [panTmp2+7],80h
        JZ      .Right
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
    FStP    dword [PBX+mTgtR]
    Or      [PBX+mTgtR],EDX

    FSubR   dword [fp0_5]
    FSqrt
    FMulP   ST1,ST
    FStP    dword [PBX+mTgtL]
    Or      [PBX+mTgtL],EAX

    XOr     EAX,EAX
    RetN

.NoSep:
    FILd    dword [PBX+mTgtL]
    FMul    dword [fpShR7]
    FStP    dword [PBX+mTgtL]

    FILd    dword [PBX+mTgtR]
    FMul    dword [fpShR7]
    FStP    dword [PBX+mTgtR]

    XOr     EAX,EAX

ENDP
%endif


;===================================================================================================
;Set Stereo Separation

EXPROC SetDSPStereo, sep
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
        IdxLd   Mov,EAX,mix,PBX+mTgtL
        IdxLd   Mov,EDX,mix,PBX+mTgtR
        IdxSt   Mov,mix,PBX+mChnL,EAX
        IdxSt   Mov,mix,PBX+mChnR,EDX

    Add     EBX,-80h
    JNS     .Float
%endif

ENDP


;===================================================================================================
;Set Echo Stereo Separation

EXPROC SetDSPEFBCT, leak
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
; first block.
;
;In:
;   PBX-> mix[voice]
;   PSI-> dsp.voice[voice]
;
;Out:
;   nothing
;
;Destroys:
;   EAX,EDX

PROC StartSrc

    ;NOTE (amd64 port): bCur/sIdx (DSP.inc VoiceMix struct) stay 'resd 1' on both architectures --
    ; the struct's total size is relied on throughout DSP.asm as a fixed 128-byte voice stride, so
    ; it cannot grow.  On x86 a real pointer already fits in 4 bytes and this code is unchanged.
    ; On amd64 they instead hold a small OFFSET: bCur is pAPURAM-relative (SPC RAM is a 64KB space,
    ; so this always fits in 32 bits), sIdx is relative to the voice's own struct base (PBX).
    ; Both are reconstructed into a real pointer immediately after loading.

    Push    PSI,PDI,PBP
    MovZX   EAX,byte [PBX+mSrc]                                                 ;EAX = Source
    IdxLd   Mov,AL,scr700chg,PAX                                                ;AL = NoteChange[EAX]

    Mov     PSI,[pAPURAM]
    ShL     EAX,2
    Add     AH,[dsp+dir]                                                        ;EAX = Source directory
    Mov     SI,[PAX+PSI]                                                        ;PSI -> First block of waveform
    LEA     PDI,[PBX+sBuf]                                                      ;PDI -> Uncompressed sample buffer
%ifdef WIN64
    Mov     EAX,ESI
    Sub     PAX,[pAPURAM]
    Mov     [PBX+bCur],EAX                                                      ;Save as a pAPURAM-relative offset
    Mov     EAX,EDI
    Sub     PAX,PBX
    Mov     [PBX+sIdx],EAX                                                      ;Save as a voice-struct-relative offset
%else
    Mov     [EBX+bCur],ESI                                                      ;Save physical pointers to wave data
    Mov     [EBX+sIdx],EDI
%endif

    ;Decompress first block ------------------
    Mov     AL,[PSI]
    Push    PBX
    Mov     [PBX+bHdr],AL                                                       ;Save block header
    MovSX   EDX,word [PBX+sP1]
    MovSX   EBX,word [PBX+sP2]
    Call    [pDecomp]
    Mov     EAX,EBX
    Pop     PBX
    Mov     [PBX+sP1],DX
    Mov     [PBX+sP2],AX

    ;Initialize interpolation ----------------
    XOr     EAX,EAX
    Mov     [PBX+sBuf-4],EAX
    Mov     [PBX+sBuf-8],EAX
    Mov     [PBX+sBuf-12],EAX
    Mov     [PBX+sBuf-16],EAX

    Cmp     byte [dspInter],2                                                   ;Is interpolation enabled?
    JB      .NoInter
        Add     byte [PBX+sIdx],6                                               ;Update sample index (byte-sized delta --
                                                                                ; representation-agnostic, see note in StartSrc)
    .NoInter:
    Pop     PBP,PDI,PSI

ENDP


;===================================================================================================
;Start Envelope
;
;Called when a voice is keyed on to set up the internal data to begin envelope modification based on
; the values in ADSR/Gain.
;
;In:
;   PBX-> mix[voice]
;   PSI-> dsp.voice[voice]
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
    Mov     [PBX+eVal],EAX                                                      ;Envelope starts at 0
    Mov     [PBX+mOut],EAX
    Mov     [PBX+eRIdx],AL                                                      ;Reset envelope counter
    Mov     EDX,[rateTab]
    Mov     [PBX+eRate],EDX                                                     ;Reset rate of adjustment
    Mov     [PBX+eCnt],EDX
    Mov     [PSI+envx],AL                                                       ;Reset envelope height
    Mov     [PSI+outx],AL
    Mov     byte [PBX+eMode],E_ATT << 4                                         ;If envelope gets switched out of gain mode, start ADSR

    Test    byte [PSI+adsr],80h                                                 ;Is the envelope in ADSR mode?
    JZ      ChgGain                                                             ;   No, It is in gain mode

ChgAtt:
        Cmp     dword [PBX+eVal],D_MAX                                          ;Did envelope reach destination value?
        JGE     .ChgDec                                                         ;   Yes, change decay mode

        Mov     byte [PBX+eMode],E_ATT                                          ;Set envelope mode to attack
        Mov     dword [PBX+eDest],D_MAX                                         ;Set destination to 1.0

        Mov     AL,byte [PSI+adsr]
        And     AL,0Fh
        Add     AL,AL                                                           ;Adjust AL to index rateTab
        Inc     AL
        Cmp     AL,1Fh                                                          ;Is there an attack?
        JE      .NoAtt                                                          ;   Yes

        Mov     dword [PBX+eAdj],A_LIN                                          ;Set adjustment rate to linear
        Cmp     [PBX+eRIdx],AL
        JE      .AttNext

        Mov     [PBX+eRIdx],AL
        IdxLd   Mov,EDX,rateTab,PAX*4                                           ;Set rate of adjustment
        Mov     [PBX+eRate],EDX
        Mov     [PBX+eCnt],EDX

    .AttNext:
        RetN                                                                    ;Exit

    .NoAtt:
        Mov     dword [PBX+eAdj],A_NOATT                                        ;Set adjustment rate to 1.0
        Cmp     [PBX+eRIdx],AL
        JE      .AttNext

        Mov     [PBX+eRIdx],AL
        IdxLd   Mov,EDX,rateTab,PAX*4                                           ;Set rate of adjustment
        Mov     [PBX+eRate],EDX
        Mov     [PBX+eCnt],EDX

        RetN                                                                    ;Exit

    .ChgDec:
        MovZX   EAX,byte [PBX+eRIdx]
        IdxLd   Mov,EDX,rateTab,PAX*4                                           ;Set rate of adjustment
        Mov     [PBX+eRate],EDX
        Mov     [PBX+eCnt],EDX

ChgDec:
        Mov     AL,[PSI+adsr+1]                                                 ;Set destination to AL/8
        ShR     AL,5
        Inc     AL
;       Test    AL,8                                                            ;Is destination of envelope D_MAX?
;       JNZ     .ChgSus                                                         ;   Yes, change sustain mode

        IMul    EAX,D_EXP
        XOr     EDX,EDX                                                         ;Adjust value for internal precision
        Dec     EAX
        SetS    DL
        Add     EAX,EDX

        Cmp     byte [PBX+eMode],E_DECAY                                        ;If DR changes in the middle of DECAY,
        JNE     .DecSkip                                                        ;   and DR is higher than current envelope value,
        Cmp     [PBX+eVal],EAX                                                  ;   does not change to sustain mode
        JGE     .DecSkip

        Mov     dword [PBX+eDest],D_MIN                                         ;Destination to 0 instead of changing to sustain mode,
        Jmp     .DecReset                                                       ;   prevents changing to sustain mode by UpdateEnv

    .DecSkip:
        Cmp     [PBX+eVal],EAX                                                  ;Did envelope reach destination value?
        JLE     .ChgSus                                                         ;   Yes, change sustain mode

        Mov     dword [PBX+eAdj],A_EXP                                          ;Set adjustment rate to exponential
        Mov     byte [PBX+eMode],E_DECAY                                        ;Set envelope mode to decay
        Mov     [PBX+eDest],EAX

    .DecReset:
        MovZX   EAX,byte [PSI+adsr]
        And     AL,70h
        ShR     AL,3
        Add     AL,10h                                                          ;Adjust AL to index rateTab
        Cmp     [PBX+eRIdx],AL
        JE      .DecNext

        Mov     [PBX+eRIdx],AL
        IdxLd   Mov,EDX,rateTab,PAX*4                                           ;Set rate of adjustment
        Mov     [PBX+eRate],EDX
        Mov     [PBX+eCnt],EDX

    .DecNext:
        RetN                                                                    ;Exit

    .ChgSus:
        MovZX   EAX,byte [PBX+eRIdx]
        IdxLd   Mov,EDX,rateTab,PAX*4                                           ;Set rate of adjustment
        Mov     [PBX+eRate],EDX
        Mov     [PBX+eCnt],EDX

ChgSus:
        Mov     dword [PBX+eAdj],A_EXP                                          ;Set adjustment rate to exponential
        Mov     dword [PBX+eDest],D_MIN                                         ;Set destination to 0

        Mov     AL,[PSI+adsr+1]
        Mov     AH,E_IDLE
        And     AL,1Fh                                                          ;Is index zero?
        JZ      .SusNext                                                        ;   Yes, change idle mode

        Cmp     dword [PBX+eVal],D_MIN                                          ;Did envelope reach destination value?
        JLE     .SusNext                                                        ;   Yes, change idle mode

        XOr     AH,AH
        Cmp     [PBX+eRIdx],AL
        JE      .SusNext

        Mov     [PBX+eRIdx],AL
        IdxLd   Mov,EDX,rateTab,PAX*4
        Mov     [PBX+eRate],EDX                                                 ;Set rate of change
        Mov     [PBX+eCnt],EDX

    .SusNext:
        Or      AH,E_SUST
        Mov     [PBX+eMode],AH                                                  ;Set envelope mode to sustain
        RetN                                                                    ;Exit

ChgGain:
    Mov     AL,[PSI+gain]
    Test    AL,80h                                                              ;Is gain direct?
    JNZ     .GainMode                                                           ;   No, program envelope
        Mov     dword [PBX+eAdj],A_DIRECT                                       ;Set adjustment rate to 1.0

        And     AL,7Fh                                                          ;Isolate direct value
        Mov     EDX,EAX                                                         ;Adjust value for internal precision
        ShR     DL,7-E_SHIFT                                                    ;EAX = LEVEL * A_GAIN + LEVEL / 128 * A_GAIN
        ShL     EAX,E_SHIFT                                                     ; If LEVEL = 0x00, EAX = 0
        Add     EAX,EDX                                                         ; If LEVEL = 0x7F, EAX = D_MAX (128 * A_GAIN - 1)
        Mov     [PBX+eDest],EAX                                                 ;  EAX = 127 * A_GAIN + 127 / 128 * A_GAIN

        Mov     byte [PBX+eRIdx],31                                             ;Envelope is set
        IdxLd   Mov,ESI,rateTab,31*4                                            ;rateTab holds plain dwords, not pointers -- a
        Mov     [PBX+eRate],ESI                                                 ; 64-bit PSI store here would overrun eRate/eCnt
        Mov     [PBX+eCnt],ESI                                                  ; into eCnt/eVal

        Mov     DL,[PBX+eMode]
        And     DL,70h
        Or      DL,E_DIRECT                                                     ;Set mode to direct
        Mov     [PBX+eMode],DL
        RetN

    .GainMode:
        Mov     DL,AL
        Mov     AH,E_IDLE
        And     AL,1Fh                                                          ;Is index zero?
        JZ      .GainNext

        XOr     AH,AH
        Cmp     [PBX+eRIdx],AL
        JE      .GainNext

        Mov     [PBX+eRIdx],AL

        ;NOTE (amd64 port): ESI, not PSI/RSI -- eRate/eCnt are plain dwords (see the identical concern
        ; at ChgGain's other rateTab load above); a pointer-width store here would overrun into eCnt/eVal.

        IdxLd   Mov,ESI,rateTab,PAX*4
        Mov     [PBX+eRate],ESI                                                 ;Set rate of change
        Mov     [PBX+eCnt],ESI

    .GainNext:
        Mov     AL,[PBX+eMode]                                                  ;Preserve ADSR mode
        And     AL,70h
        Or      AL,AH

        Test    DL,60h                                                          ;Jump to the right mode
        JZ      .GainDec
        Test    DL,40h
        JZ      .GainExp
        Test    DL,20h
        JZ      .GainInc

    .GainBent:
        Mov     dword [PBX+eAdj],A_LIN
        Mov     dword [PBX+eDest],D_BENT
        Or      AL,E_BENT                                                       ;Set mode to bent line increase
        Mov     [PBX+eMode],AL
        RetN

    .GainInc:
        Mov     dword [PBX+eAdj],A_LIN
        Mov     dword [PBX+eDest],D_MAX
        Or      AL,E_INC                                                        ;Set mode to linear increase
        Mov     [PBX+eMode],AL
        RetN

    .GainExp:
        Mov     dword [PBX+eAdj],A_EXP
        Mov     dword [PBX+eDest],D_MIN
        Or      AL,E_EXP                                                        ;Set mode to exponential decrease
        Mov     [PBX+eMode],AL
        RetN

    .GainDec:
        Mov     dword [PBX+eAdj],A_LIN
        Mov     dword [PBX+eDest],D_MIN
        Or      AL,E_DEC                                                        ;Set mode to linear decrease
        Mov     [PBX+eMode],AL
        RetN
ENDP


;===================================================================================================
;Change Envelope
;
;Called when the ADSR registers are written to while an envelope is in progress.  Control is
; transfered to StartEnv where the envelope is updated.
;
;In:
;   PBX = Voice << 4
;
;Destroys:
;   EAX,EDX,PBX

PROC ChgADSR

    ;NOTE (amd64 port): PSI is pushed here (not through StartEnv's own PROC/USES ESI prologue, which
    ; this jumps past) purely so StartEnv's shared exit points -- which still expect to pop it --
    ; stay balanced; the pushed value is whatever ChgADSR's own caller had in PSI, restored
    ; transparently on return.  PSI itself is then immediately given a real value below (the dsp
    ; pointer), same as it would have on a normal call into StartEnv.

    Push    PSI                                                                 ;PSI will get popped on return from StartEnv
    IdxLd   LEA,PSI,dsp,PBX
    IdxLd   LEA,PBX,mix,PBX*8

    XOr     EAX,EAX
    Mov     DL,[PBX+eMode]
    And     DL,0Fh

    Cmp     DL,E_ATT                                                            ;If the envelope is not in attack, decay, or sustain
    JE      ChgAtt                                                              ; mode, changes to the ADSR registers have no effect
    Cmp     DL,E_DECAY
    JE      ChgDec
    Cmp     DL,E_SUST
    JE      ChgSus

    Pop     PSI                                                                 ;No changes were made, pop PSI and return

ENDP


;===================================================================================================
;DSP Data Port

;--------------------------------------------
;External procedure for users of SNESAPU.DLL
;
;Out:
;   EAX = not 0: success, 0: failure

EXPROC SetDSPReg, dReg, dVal
USES ECX,EDX,EBX

    MovZX   EBX,byte [dReg]
    MovZX   EAX,byte [dVal]

    XOr     CL,CL                                                               ;CL = Do not emulate DSP
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

    XOr     CL,CL                                                               ;CL = Do not emulate DSP
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
    Mov     PDX,[pTrace]
    Test    PDX,PDX
    JZ      .NoDbg
        MovZX   EAX,AL
        LblOp   Add,PBX,dsp                                                     ;PBX itself becomes the pointer

        Push    PCX,PSI,PDI                                                     ;Save these registers
        Push    PAX                                                             ;Pass these as parameters
        Push    PBX
        Call    PDX
        Pop     PBX
        Pop     PAX
        Pop     PDI,PSI,PCX

        MovZX   EBX,BL                                                          ;EBX = original dsp index

    .NoDbg:
%endif

    Test    dword [apuCbMask],CBE_DSPREG
    JZ      .NoCallback

    Mov     PDX,[apuCbFunc]
    Test    PDX,PDX
    JZ      .NoCallback
    Test    BL,80h                                                              ;Writes to 80-FFh have no effect (reads are mirrored
    JNZ     .NoCallback                                                         ; from lower mem)
        Push    PCX,PBX,PAX                                                     ;STDCALL is destroy PAX,PCX,PDX
        MovZX   EBX,BL
        MovZX   EAX,AL
        ExtCall PDX,dword CBE_DSPREG,EBX,EAX,dword 0

        Mov     BL,AL                                                           ;Copy overwrote value
        Pop     PAX
        Mov     AL,BL
        Pop     PBX,PCX

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

    IdxLd   Cmp,AL,dsp,PBX                                                      ;Is the new data the same as the current data?
    JZ      DSPDone                                                             ;   Yes, do not bother updating

    IdxSt   Mov,dsp,PBX,AL                                                      ;Update DSP RAM

DSPInC:
    IdxLd   Mov,PDX,dspRegs,PBX*PTRSIZE                                         ;Get the pointer to the register handler

    Mov     AH,BL
    And     EBX,70h
    Not     AH
    ShL     EBX,3                                                               ;EBX indexes mix (needed by some handlers)
    And     AH,MFLG_OFF                                                         ;AH = 08h if the register is in dsp.voice

    IdxSt   Test,mix,PBX+mFlg,AH                                                ;Is the voice inactive?
    JNZ     DSPDone                                                             ;   Yes, do not bother updating

%if DSPBK && DSPINTEG
    Test    CL,CL                                                               ;If write was from SPC700, emulate DSP before
    JZ      .NoOutput                                                           ; processing new register data
        Call    CatchUp

    .NoOutput:
%endif

    Jmp     PDX

DSPDone:
    XOr     EAX,EAX                                                             ;DSP state did not change

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
    JZ      %%Done

    Push    PSI

    Mov     CH,1
    LoadPtr PBX,mix
    LoadPtr PSI,dsp
    Mov     EDX,[31*4+rateTab]
    XOr     EAX,EAX

    %%Next:
        Test    CL,CH
        JZ      %%Skip

        Test    [voiceMix],CH                                                   ;Is voice currently playing?
        JZ      %%Skip                                                          ;   No, do nothing

        Test    byte [PBX+mFlg],MFLG_KOFF                                       ;Is already voice in key off mode?
        JNZ     %%Skip                                                          ;   Yes, do nothing
            Mov     byte [PBX+eRIdx],31                                         ;Place envelope in release mode
            Mov     [PBX+eRate],EDX
            Mov     [PBX+eCnt],EDX
            Mov     dword [PBX+eAdj],A_KOFF
            Mov     dword [PBX+eDest],D_MIN
            Mov     byte [PBX+eMode],E_REL
            Or      byte [PBX+mFlg],MFLG_KOFF                                   ;Flag voice as keying off
            Mov     [PBX+vRsv],AL                                               ;Reset ADSR/Gain changed flag
            Mov     [PBX+mKOn],AL                                               ;Reset delay time

        %%Skip:
        Add     PSI,10h
        Sub     PBX,-80h

    Add     CH,CH
    JNZ     %%Next

    Pop     PSI

    %%Done:
    Mov     [koffRsv],CH                                                        ;CH = 0
%endmacro

%macro CatchKOn 0
    ;KOn process -----------------------
    Mov     CL,[konRsv]
    Or      CL,[konRun]
    JZ      %%Done

    Push    PSI

    Mov     CL,[konRsv]
    Mov     CH,1
    LoadPtr PBX,mix
    LoadPtr PSI,dsp

    %%Next:
%if INTBK
        Test    byte [PBX+mKOn],-1                                              ;Is already voice in key on mode?
        JNZ     %%CheckKOff                                                     ;   Yes
            Test    CL,CH
            JZ      %%Skip

            XOr     EDX,EDX
            And     byte [PBX+mFlg],MFLG_USER                                   ;Leave user voice flags (mute and noise)
            Mov     byte [PBX+mKOn],KON_DELAY                                   ;Set delay time from writing KON to output
            Mov     [PBX+eVal],EDX                                              ;Reset envelope and wave height, because noise may be
            Mov     [PBX+mOut],EDX                                              ; mixed in when the channel volume is changed immediately
            Mov     [PSI+envx],DL                                               ; after KON.
            Mov     [PSI+outx],DL

            Or      [konRun],CH                                                 ;Start KON working
            Not     CH
            And     [dsp+endx],CH                                               ;Clear ENDX register if started KON
            Not     CH
            Jmp     %%Skip

        %%CheckKOff:
        Cmp     byte [PBX+mKOn],KON_CHKKOFF                                     ;Did time for checked KOFF after KON had been written?
        JA      %%CheckEnv                                                      ;   No

        Test    [dsp+kof],CH                                                    ;Is KOFF still written?
        JZ      %%CheckEnv                                                      ;   No
            Or      byte [PBX+mFlg],MFLG_KOFF                                   ;Flag voice as keying off
            Mov     byte [PBX+mKOn],0                                           ;Reset delay time

            Not     CH
            And     [konRun],CH                                                 ;Cancel KON working
            Not     CH
            Jmp     %%Skip

        %%CheckEnv:
        Cmp     byte [PBX+mKOn],KON_SAVEENV                                     ;Did time for saved envelope pass after KON had been
        JNE     %%StartKON                                                      ; written?  No
            Mov     DX,[PSI+adsr]                                               ;Save ADSR parameters
            Mov     [PBX+vAdsr],DX
            MovZX   DX,byte [PSI+gain]                                          ;Save Gain parameters
            Mov     [PBX+vGain],DL
            Mov     [PBX+vRsv],DH                                               ;Reset ADSR/Gain changed flag

        %%StartKON:
        Dec     byte [PBX+mKOn]                                                 ;Did time for enabled voice pass after KON had been
        JNZ     %%Skip                                                          ; written?  No, do nothing
            And     byte [PBX+mFlg],MFLG_USER                                   ;Leave user voice flags (mute and noise)
%else
        Test    CL,CH
        JZ      %%Skip
            XOr     EDX,EDX
            And     byte [PBX+mFlg],MFLG_USER                                   ;Leave user voice flags (mute and noise)
            Or      byte [PBX+mFlg],MFLG_KOFF                                   ;Flag voice as keying off
            Mov     [PBX+mKOn],DL                                               ;Start playing immediately

        Test    [dsp+kof],CH                                                    ;Is KOFF still written?
        JNZ     %%Skip                                                          ;   No
            And     byte [PBX+mFlg],~MFLG_KOFF                                  ;Cancel keying off flag

            Or      [konRun],CH                                                 ;Start KON working
            Not     CH
            And     [dsp+endx],CH                                               ;Clear ENDX register if started KON
            Not     CH

            Mov     DX,[PSI+adsr]                                               ;Save ADSR parameters
            Mov     [PBX+vAdsr],DX
            MovZX   DX,byte [PSI+gain]                                          ;Save Gain parameters
            Mov     [PBX+vGain],DL
            Mov     [PBX+vRsv],DH                                               ;Reset ADSR/Gain changed flag
%endif

            ;Set voice volume ------------------
            ;NOTE: each LblOp below loads its own scratch copy of mix's address fresh -- deliberately
            ; not shared across the Call RVolL in between, since RVolL (ChnSep) uses PDX as its own
            ; scratch and does not restore it.
%if STEREO
            LblOp   Sub,PBX,mix
            Call    RVolL
            LblOp   Add,PBX,mix
            Mov     EAX,[PBX+mTgtL]
            Mov     [PBX+mChnL],EAX
            Mov     EAX,[PBX+mTgtR]
            Mov     [PBX+mChnR],EAX
%else
            LblOp   Sub,PBX,mix
            Mov     AL,[PSI+volL]
            Call    RVolL
            Mov     AL,[PSI+volR]
            Call    RVolR
            LblOp   Add,PBX,mix
%endif

            ;Set pitch -------------------------
            MovZX   EAX,word [PSI+pitch]
            Test    dword [dspOpts],DSP_NOPLMT                                  ;If do not remove the pitch limit, the highest
            SetZ    DL                                                          ; pitch value is 3FFF
            Dec     DL
            Or      DL,3Fh
            And     AH,DL
            Mov     [PBX+mOrgP],EAX
            MovZX   EDX,byte [PSI+srcn]                                         ;EDX = Source
            Mov     [PBX+mSrc],DL                                               ;Save source number
            IdxLd   Add,EAX,scr700det,PDX*4                                     ;EAX += Detune[EDX]

            Mul     dword [pitchAdj]
            ShRD    EAX,EDX,16
            AdC     EAX,0
            Mov     [PBX+mRate],EAX
            Mov     word [PBX+mDec],0

            ;Key ON ----------------------------
            Mov     AX,[PSI+adsr]                                               ;Save now ADSR/Gain parameters
            Mov     DL,[PSI+gain]
            Push    PAX,PDX
            Mov     AX,[PBX+vAdsr]                                              ;Restore ADSR/Gain parameters
            Mov     [PSI+adsr],AX
            Mov     DL,[PBX+vGain]
            Mov     [PSI+gain],DL

            Call    StartSrc                                                    ;Start waveform decompression
            Call    StartEnv                                                    ;Start envelope

            Pop     PDX,PAX                                                     ;Restore ADSR/Gain parameters
            Mov     [PSI+adsr],AX
            Mov     [PSI+gain],DL

            Or      [voiceMix],CH                                               ;Mark voice as being on internally
            Not     CH
            And     [konRun],CH                                                 ;KON working was finished
            Not     CH

        %%Skip:
        Add     PSI,10h
        Sub     PBX,-80h

    Add     CH,CH
    JNZ     %%Next

    Pop     PSI                                                                 ;Now, CH = 0

    %%Done:
    Mov     [konRsv],CH
%endmacro


;===================================================================================================
;Set the Denormalized Numbers to 0
;
;Calculating denormalized numbers requires a many number of CPU clocks.  If the CPU does not support
; denormalized numbers, will take more processing time more because using software emulation.
;
;However, when it comes to audio data, denormalized numbers have very small outputs that are
; inaudible, so they can be treated as 0.
;
;Destroys:
;   EAX
%macro ZeroDN 1
    Mov     EAX,[%1]
    And     EAX,7F800000h                                                       ;Is the exponent part zero (denormalized)?
    JNZ     %%Normal                                                            ;   No
        Mov     [%1],EAX                                                        ;EAX = 0

    %%Normal:
%endmacro

%macro ZeroDNEFB 1
    FLd     dword [%1]
    FMul    dword [fpShR19]
    FStP    dword [PSP-4]
    ZeroDN  PSP-4
%endmacro


;===================================================================================================
;DSP Register Handlers

;============================================
;End block decoded

REndX:
%if DSPBK && DSPINTEG
    Test    CL,CL                                                               ;If write was from SPC700, emulate DSP before
    JZ      .NoOutput                                                           ; processing new register data
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
    JZ      .NoOutput                                                           ; processing new register data
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
    JZ      .NoOutput                                                           ; processing new register data
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

    Mov     [PSP-4],EAX
    FILd    dword [PSP-4]
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

    Mov     [PSP-4],EAX
    FILd    dword [PSP-4]
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
    JNZ     .NoRead                                                             ;   No
        ShR     PBX,3
        IdxLdX  MovZX,PAX,word,dsp,PBX+pitch                                    ;EAX = Pitch
        Test    dword [dspOpts],DSP_NOPLMT                                      ;If do not remove the pitch limit, the highest
        SetZ    DL                                                              ; pitch value is 3FFF
        Dec     DL
        Or      DL,3Fh
        And     AH,DL
        ShL     PBX,3
        IdxSt   Mov,mix,PBX+mOrgP,EAX

        IdxLdX  MovZX,PDX,byte,mix,PBX+mSrc                                     ;EDX = Source
        IdxLd   Add,EAX,scr700det,PDX*4                                         ;EAX += Detune[EDX]

        Mul     dword [pitchAdj]                                                ;Convert the pitch into a more meaningful value
        ShRD    EAX,EDX,16                                                      ;Remove 16-bit fraction from pitchAdj
        AdC     EAX,0
        IdxSt   Mov,mix,PBX+mRate,EAX

        XOr     EAX,EAX
        Inc     EAX

    .NoRead:
    Ret

;============================================
;Envelope

RADSR:
    ;NOTE: RGain (below) pushes ESI/PSI verbatim for StartEnv to pop -- it must still hold whatever
    ; DSPIn's own caller had, all the way through both RADSR's body and a possible fall-through
    ; into RGain via .SetGain: below.  So neither of these two handlers may use PSI as scratch for
    ; the dsp/mix base pointers -- IdxSt/IdxLd (default scratch PDI) are used instead, each
    ; self-contained so nothing needs to survive across the Call ChgADSR/Jmp ChgGain either.
    XOr     EAX,EAX
    IdxSt   Test byte,mix,PBX+mFlg,MFLG_KOFF                                    ;Is voice in key off mode?
    JNZ     .NoChg                                                              ;   Yes, envelope setting cannot be changed now

    IdxSt   Test byte,mix,PBX+mKOn,-1
    SetNZ   AL
    IdxSt   Or,mix,PBX+vRsv,AL
    Test    AL,AL                                                               ;Has time passed since KON was written?
    JNZ     .NoChg                                                              ;   No, update ADSR parameters later
        IdxLd   Mov,AL,mix,PBX+eMode                                            ;AL = ADSR or Gain mode
        ShR     PBX,3
        And     AL,E_ADSR
        IdxLd   Mov,AH,dsp,PBX+adsr
        And     AH,80h
        Or      AL,AH

        Test    AL,80h + E_ADSR
        JZ      .NoChg                                                          ;Envelope is already in gain mode, do nothing
        Test    AL,80h
        JZ      .SetGain                                                        ;Switched from ADSR to Gain
        Test    AL,E_ADSR
        JNZ     .Change                                                         ;Envelope is in ADSR mode, update settings

        IdxLd   Mov,AL,mix,PBX*8+eMode                                          ;Switched from Gain to ADSR, restore previous ADSR
        ShR     AL,4                                                            ; state then update settings
        Or      AL,E_ADSR
        IdxSt   Mov,mix,PBX*8+eMode,AL

        .Change:
        Call    ChgADSR
        XOr     EAX,EAX
        Inc     EAX

    .NoChg:
    Ret

    .SetGain:
        ShL     PBX,3
        IdxSt   ShL byte,mix,PBX+eMode,4                                        ;Save ADSR state, ChgGain will set bits 7 and 3-0

RGain:
    XOr     EAX,EAX
    IdxSt   Test byte,mix,PBX+mFlg,MFLG_KOFF                                    ;Is voice in key off mode?
    JNZ     .NoChg                                                              ;   Yes, envelope setting cannot be changed now

    IdxSt   Test byte,mix,PBX+mKOn,-1
    SetNZ   AL
    Add     AL,AL
    IdxSt   Or,mix,PBX+vRsv,AL
    Test    AL,AL                                                               ;Has time passed since KON was written?
    JNZ     .NoChg                                                              ;   No, update GAIN parameters later

    ShR     PBX,3
    IdxSt   Test byte,dsp,PBX+adsr,80h                                          ;Is envelope in gain mode?
    JNZ     .NoChg                                                              ;   No, setting gain register has no effect
        LoadPtr PDX,.Return
        Push    PDX,PSI                                                         ;PSI will get popped on return from StartEnv
        IdxLd   LEA,PSI,dsp,PBX
        IdxLd   LEA,PBX,mix,PBX*8
        Jmp     ChgGain                                                         ;See StartEnv

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

    Mov     [PSP-4],EAX
    FILd    dword [PSP-4]
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

    Mov     [PSP-4],EAX
    FILd    dword [PSP-4]
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

    Mov     [PSP-4],EAX
    FILd    dword [PSP-4]
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

    Mov     [PSP-4],EAX
    FILd    dword [PSP-4]
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
    Mov     [PSP-4],EAX
    FILd    dword [PSP-4]

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
    Push    PCX
    Mov     AL,byte [dsp+edl]
    And     EAX,0Fh
    ShL     EAX,9                                                               ;EAX = Number of samples to delay
    Push    PAX

    Test    EAX,EAX                                                             ;If EAX = 0, EAX = 1
    SetZ    CL
    Or      AL,CL
    ShL     EAX,2                                                               ;Multiply by 4, since original echo is stored in
    Mov     [echoLenM],EAX                                                      ; 16-bit stereo

%if ECHOMEM=0
    ;Normally, the current pointer is NOT initialized by changing the EDL, but when the playing speed
    ; is set other than 100%, the current pointer is initialized to rewrite memory in unexpected places.
    Mov     [echoMaxM],EAX
    Mov     [echoCurM],EAX
%endif

    Pop     PAX
    Mul     dword [dspRate]                                                     ;EAX *= Rate / 32kHz
    Mov     ECX,32000
    Div     ECX

    Test    EAX,EAX                                                             ;If EAX = 0, EAX = 1
    SetZ    CL
    Or      AL,CL
    ShL     EAX,3                                                               ;Multiply by 8, since SNESAPU echo is stored in
    Mov     [echoLenD],EAX                                                      ; 32-bit stereo
    Pop     PCX

    XOr     EAX,EAX
    Inc     EAX
    Ret

RFCf:
    ShR     PBX,5
    MovSX   EAX,AL
    Mov     [PSP-4],EAX

    FILd    dword [PSP-4]
    FMul    dword [fpShR7]
    IdxUn   FStP dword,firTaps,PBX

    XOr     EAX,EAX                                                             ;DSP state changed if echo was enabled
    Inc     EAX
    Ret

;============================================
;Other

RPMOn:
    ;Reset all pitch on all voices -----------
    Push    PCX
    LoadPtr PBX,mix
    Mov     CL,8

    .Next:
        Mov     EAX,[PBX+mOrgP]
        MovZX   EDX,byte [PBX+mSrc]                                             ;EDX = Source
        IdxLd   Add,EAX,scr700det,PDX*4                                         ;EAX += Detune[EDX]

        Mul     dword [pitchAdj]
        ShRD    EAX,EDX,16
        AdC     EAX,0
        Mov     [PBX+mRate],EAX

        Sub     PBX,-80h

    Dec     CL
    JNZ     .Next
    Pop     PCX

    XOr     EAX,EAX
    Inc     EAX
    Ret

RFlg:
    Test    AL,80h                                                              ;Has a soft reset been initialized?
    JZ      .NoSRst                                                             ;   No
        LoadPtr PBX,dsp
        And     AL,~80h
        Or      AL,60h                                                          ;Turn on mute and disable echo
        Mov     [PBX+flg],AL
        Mov     [PBX+endx],BL                                                   ;Clear end block flags
        Mov     [PBX+kon],BL
        Mov     [PBX+kof],BL
        Mov     [voiceMix],BL

        ;Reset internal voice settings --------
        LoadPtr PBX,mix+mFlg
        Mov     AL,8

        .MFlg:
            And     byte [PBX],MFLG_USER                                        ;Leave user voice flags (mute and noise)
            Or      byte [PBX],MFLG_OFF                                         ;Set voice to inactive
            Sub     PBX,-80h

        Dec     AL
        JNZ     .MFlg
    .NoSRst:

    ;Update noise clock ----------------------
    Mov     dword [nRate],0
    And     EAX,1Fh
    JZ      .NoNoise
        Mov     EBX,EAX
        Mov     EAX,-1
        Mov     EDX,65535
        IdxUn   Div dword,rateTab,PBX*4
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

    FILd    word [PSI]

ENDP


;===================================================================================================
;Linear Interpolation

PROC LinearInt

    FILd    word [PSI-2]
    FILd    word [PSI]
    Mov     [PSP-4],EAX
    FSub    ST,ST1                                                              ;Difference between samples
    FIMul   dword [PSP-4]                                                       ;Multiply by delta x from last sample
    FMul    dword [fpShR16]
    FAddP   ST1,ST

ENDP


;===================================================================================================
;Cubic/Gauss (Use 4-point) Interpolation

PROC Point4Int

    ShR     EAX,8                                                               ;EAX indexes interpolation table value
    IdxLd   LEA,PAX,interTab,PAX*8
    FILd    word [PSI-6]                                                        ;Get first sample
    FIMul   word [PAX+0]
    FILd    word [PSI-4]
    FIMul   word [PAX+2]
    FILd    word [PSI-2]
    FIMul   word [PAX+4]
    FILd    word [PSI]
    FIMul   word [PAX+6]
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
    IdxLd   LEA,PAX,interTab,PAX
    FILd    word [PSI-14]
    FIMul   word [PAX+0]
    FILd    word [PSI-12]
    FIMul   word [PAX+2]
    FILd    word [PSI-10]
    FIMul   word [PAX+4]
    FILd    word [PSI-8]
    FIMul   word [PAX+6]
    FILd    word [PSI-6]
    FIMul   word [PAX+8]
    FILd    word [PSI-4]
    FIMul   word [PAX+10]
    FILd    word [PSI-2]
    FIMul   word [PAX+12]
    FILd    word [PSI-0]
    FIMul   word [PAX+14]
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
    JNC     %%NoNInc
        Mov     EAX,[nSeed]
        Add     EAX,EAX
        JNS     %%NoiseOK
            XOr     EAX,40001h

        %%NoiseOK:
        Mov     [nSeed],EAX

        SAR     EAX,16
        Mov     [nSmp],EAX

    %%NoNInc:
    Test    dword [dspNoiseF],-1
    JZ      %%NoNIncF
    Mov     EAX,[nfRate]
    Add     [nfAcc],EAX
    JNC     %%NoNIncF
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
; previously believed.
;
;In:
;   CH  = Bitmask for current voice
;   PBX-> Current voice in 'mix'
;
;Destroys:
;   EAX,EDX

%macro PitchMod 0
    ;Adjust pitch by sample value ---------
    Mov     EAX,[PBX+mOut-80h]                                                  ;EAX = Wave height of last voice (-16.15)
    Add     EAX,32768                                                           ;Unsign sample
    IMul    EAX,dword [PBX+mOrgP]                                               ;Apply sample height to pitch
    SAR     EAX,15

    Push    PCX
    Test    dword [dspOpts],DSP_NOPLMT
    SetNZ   CL
    Add     CL,CL
    Add     CL,14

    ;Clamp pitch to 14-bits ---------------
    Mov     EDX,EAX
    SAR     EDX,CL
    JZ      %%PitchOK
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
    Pop     PCX

    ;Convert pitch to sample rate ---------
    MovZX   EDX,byte [PBX+mSrc]                                                 ;EDX = Source
    IdxLd   Add,EAX,scr700det,PDX*4                                             ;EAX += Detune[EDX]

    Mul     dword [pitchAdj]
    ShRD    EAX,EDX,16
    AdC     EAX,0
    Mov     [PBX+mRate],EAX
%endmacro


;===================================================================================================
;Process Sound Source
;
;Updates the current sample position and decompresses the next block if necessary
;
;In:
;   CH  = Bitmask for current voice
;   PBX-> Current voice in 'mix'
;
;Destroys:
;   EAX,EDX,CL,ESI

%macro UpdateSrc 0
    ;Update sample index ---------------------
    Mov     CL,[PBX+mRate+2]                                                    ;CL = Number of whole samples to increase index by
    Mov     EAX,[PBX+mRate]                                                     ;AX = Fraction of sample to increase index by
    Add     [PBX+mDec],AX                                                       ;Add AX to the decimal counter
    AdC     CL,0                                                                ;Add carry, if any, to increase amount
    JZ      %%NoSInc                                                            ;If the amount is zero, index didn't increase

    ;Check for end of block ------------------
    Add     CL,CL                                                               ;CL <<= 1  (for 16-bit samples)
    Add     [PBX+sIdx],CL                                                       ;Increase sample index
    Test    byte [PBX+sIdx],20h                                                 ;Have we reached the end of the block?
    JZ      %%NoSInc                                                            ;   No
        And     byte [PBX+sIdx],~20h                                            ;Adjust sample index for wrap around
        Mov     EAX,[PBX+sBuf+16]                                               ;Copy last four samples of buffer
        Mov     EDX,[PBX+sBuf+20]                                               ; (needed for interpolation)
        Mov     [PBX+sBuf-16],EAX
        Mov     [PBX+sBuf-12],EDX
        Mov     EAX,[PBX+sBuf+24]
        Mov     EDX,[PBX+sBuf+28]
        Mov     [PBX+sBuf-8],EAX
        Mov     [PBX+sBuf-4],EDX
        Add     word [PBX+bCur],9                                               ;Move to next sample block (word-sized delta --
                                                                                ; representation-agnostic, see note in StartSrc)
        Test    byte [PBX+bHdr],1                                               ;Was this the end block?
        JZ      %%NotEndB                                                       ;   No, decompress next block
        Or      [dsp+endx],CH                                                   ;Set flag in ENDX
        Test    byte [PBX+bHdr],2                                               ;Is this source looped?
        JNZ     %%LoopB                                                         ;   Yes, start over at loop point

        ;End voice playback -------------------
        %%EndPlay:
            Not     CH
            And     [voiceMix],CH                                               ;Don't include voice in mixing process
            Not     CH

            Mov     dword [PBX+eVal],0                                          ;Reset envelope and wave height
            Mov     dword [PBX+mOut],0
            Or      byte [PBX+mFlg],MFLG_OFF                                    ;Set voice to inactive
            And     byte [PBX+mFlg],~MFLG_KOFF
            Jmp     .VoiceDone

        ;Restart loop -------------------------
        %%LoopB:
            MovZX   EDX,byte [PBX+mSrc]                                         ;EDX = Source
            Test    byte [PBX+mFlg],MFLG_KOFF                                   ;Is voice in key off mode?
            JNZ     %%NoSrc                                                     ;   Yes
                Mov     PAX,PBX
                LblOp   Sub,PAX,mix
                ShR     EAX,3
                LblOp   Add,PAX,dsp
                Mov     DL,[PAX+srcn]                                           ;DL = Source
                Mov     [PBX+mSrc],DL                                           ;Save source number

            %%NoSrc:
            IdxLd   Mov,DL,scr700chg,PDX                                        ;DL = NoteChange[EDX]
            Mov     PAX,[pAPURAM]
            Mov     AH,[dsp+dir]                                                ;EAX = Source directory
            Mov     AX,[PDX*4+PAX+2]
%ifdef WIN64
            IdxLd   Sub,PAX,pAPURAM,0                                           ;Store as a pAPURAM-relative offset (see note in
%endif                                                                          ; StartSrc)
            Mov     [PBX+bCur],EAX                                              ;(x86: stores physical loop pointer directly)

        ;Decompress next block ----------------
        %%NotEndB:
%ifdef WIN64
            Mov     PSI,[pAPURAM]                                               ;Reconstruct the real pointer (see StartSrc --
            Mov     EAX,[PBX+bCur]                                              ; bCur is pAPURAM-relative, not PBX-relative)
            Add     PSI,PAX                                                     ;PSI -> Current sample block
%else
            Mov     ESI,[EBX+bCur]                                              ;PSI -> Current sample block
%endif
            Push    PDI,PBX
            Mov     AL,[PSI]                                                    ;Get block header
            LEA     PDI,[PBX+sBuf]                                              ;PDI -> location to store samples
            Mov     [PBX+bHdr],AL                                               ;Save header byte
            MovSX   EDX,word [PBX+sP1]                                          ;Load previous two samples
            MovSX   EBX,word [PBX+sP2]
            Call    [pDecomp]                                                   ;Call user selected decompression routine

            Mov     EAX,EBX
            Pop     PBX,PDI
            Mov     [PBX+sP1],DX                                                ;Save last two samples in 16-bit form
            Mov     [PBX+sP2],AX

            Mov     AL,[PBX+bHdr]
            And     AL,3
            Cmp     AL,1
            JNE     %%NoSInc

            XOr     EAX,EAX
            Mov     [PBX+sBuf+16],EAX
            Mov     [PBX+sBuf+20],EAX
            Mov     [PBX+sBuf+24],EAX
            Mov     [PBX+sBuf+28],EAX

    %%NoSInc:
%endmacro


;===================================================================================================
;Calculate Envelope Modification
;
;Changes the current height of the volume envelope based on its programming.
;
;In:
;   PBX-> Current voice in mix
;   CH  = Current voice bit mask
;
;Destroys:
;   EAX,CL,EDX,ESI

%macro UpdateEnv 0
    Test    byte [PBX+mKOn],-1                                                  ;Did time pass after KON had been written?
    JNZ     %%Done                                                              ;   No, quit

    Mov     AL,[adsrCnt]
    Test    AL,AL                                                               ;Should update envelope?
    JZ      %%Done                                                              ;   No, quit
    Mov     [adsrUpd],AL

    %%Loop:
    Mov     CL,[PBX+eMode]
    Test    CL,E_IDLE                                                           ;Is the envelope constant?
    JNZ     %%EnvDone                                                           ;   Yes, go to ADSR/Gain check

    Dec     word [PBX+eCnt+2]                                                   ;Decrease sample counter, is it zero?
    JNZ     %%LoopDone                                                          ;   No, go to next loop

    Mov     EAX,[PBX+eRate]                                                     ;Restore sample counter
    Add     [PBX+eCnt],EAX

    Mov     AL,CL
    And     AL,E_ADSR|E_DIRECT
    Cmp     AL,E_DIRECT                                                         ;Is the envelope direct mode?
    JE      %%EnvDirect                                                         ;   Yes

    ;Adjust Envelope -------------------------
    %%AdjExp:
    Test    CL,E_TYPE                                                           ;Is the adjustment an exponential decrease?
    JZ      %%AdjLin                                                            ;   No, go to linear
        Mov     EAX,[PBX+eVal]                                                  ;Get now envelope height
        Neg     EAX
        SAR     EAX,8
        Add     [PBX+eVal],EAX                                                  ;Subtract 1/256th of envelope height
        Mov     EDX,[PBX+eDest]                                                 ;Get destination
        Cmp     EDX,[PBX+eVal]                                                  ;Has height reached destination?
        JL      %%EnvDone                                                       ;   No
        Jmp     %%AdjOff

    %%AdjLin:
    Test    CL,E_DIR                                                            ;Is the adjustment up or down?
    JZ      %%AdjDec
        Mov     EAX,[PBX+eVal]                                                  ;Get now envelope height
        Add     EAX,[PBX+eAdj]
        Mov     [PBX+eVal],EAX                                                  ;Add adjustment to height
        Mov     EDX,[PBX+eDest]                                                 ;Get destination
        Cmp     EDX,EAX                                                         ;Has height reached destination?
        JG      %%EnvDone                                                       ;   No

        Mov     [PBX+eVal],EDX                                                  ;Set destination
        Jmp     %%AdjDone                                                       ;Change to decay mode

    %%AdjDec:
        Mov     EAX,[PBX+eVal]                                                  ;Get now envelope height
        Sub     EAX,[PBX+eAdj]
        Mov     [PBX+eVal],EAX                                                  ;Subtract adjustment to height
        Mov     EDX,[PBX+eDest]                                                 ;Get destination
        Cmp     EDX,EAX                                                         ;Has height reached destination?
        JL      %%EnvDone                                                       ;   No

    %%AdjOff:
        Mov     [PBX+eVal],EDX                                                  ;Set destination
        Test    EDX,EDX                                                         ;If destination is not 0, change to sustain mode
        JNZ     %%AdjDone

        Mov     AL,[PBX+eMode]                                                  ;If the envelope started out in ADSR mode, but was
        And     AL,~70h                                                         ; switched to Gain w/ linear decrease, the ADSR state
        Or      AL,E_SUST << 4                                                  ; will become sustain if ADSR is re-enabled.
        Mov     [PBX+eMode],AL

        Mov     AL,[PBX+mFlg]                                                   ;If the voice was getting keyed off, set MFLG_OFF to
        And     AL,MFLG_KOFF                                                    ; mark the voice as now being inactive
        Add     AL,AL
        SetZ    AH
        Or      [PBX+mFlg],AL
        And     byte [PBX+mFlg],~MFLG_KOFF

        Dec     AH
        And     AH,CH
        Not     AH
        And     [voiceMix],AH                                                   ;Disable voice mixing if keyed off

        Or      byte [PBX+eMode],E_IDLE                                         ;Envelope is no longer changing
        Jmp     %%EnvDone

    %%AdjDone:

    ;Change adjustment mode ------------------
    ;(see StartEnv)
    Test    CL,E_ADSR                                                           ;Is envelope in ADSR mode?
    JZ      %%EnvGain                                                           ;   No, jump to Gain

    Mov     PSI,PBX
    LblOp   Sub,PSI,mix
    XOr     EAX,EAX
    ShR     PSI,3                                                               ;PSI indexes current voice in dsp
    LblOp   Add,PSI,dsp

    Test    byte [PSI+adsr],80h                                                 ;Is envelope flag in ADSR?
    JZ      %%EnvDone                                                           ;   No

    Mov     [PBX+vRsv],AL                                                       ;Reset ADSR/Gain changed flag
    Test    CL,E_DEST                                                           ;Switch to next mode
    JNZ     %%EnvSust

    %%EnvDecay:
        LoadPtr PDX,%%EnvDone
        Push    PDX,PSI                                                         ;PSI will get popped on return from StartEnv
        Jmp     ChgDec                                                          ;See StartEnv

    %%EnvSust:
        LoadPtr PDX,%%EnvDone
        Push    PDX,PSI                                                         ;PSI will get popped on return from StartEnv
        Jmp     ChgSus                                                          ;See StartEnv

    %%EnvGain:
        Or      byte [PBX+eMode],E_IDLE                                         ;Envelope is now constant

        Test    CL,E_DEST                                                       ;If gain is in "bent line" mode and line has reached
        JZ      %%EnvDone                                                       ; bend point, adjust envelope settings, otherwise
                                                                                ; envelope is done.
        Cmp     dword [PBX+eDest],D_MAX
        JE      %%EnvDone

        And     byte [PBX+eMode],~E_IDLE                                        ;Undo idle flag
        Mov     dword [PBX+eAdj],A_BENT                                         ;Slow down increase rate
        Mov     dword [PBX+eDest],D_MAX                                         ;Set destination to max
        Jmp     %%EnvDone

    %%EnvDirect:
        Mov     EAX,[PBX+eVal]
        Mov     EDX,[PBX+eDest]
        Cmp     EDX,EAX
        JE      %%EnvDirectE
        JG      %%EnvDirectH

        Sub     EAX,[PBX+eAdj]                                                  ;Sub adjustment to height
        Mov     [PBX+eVal],EAX
        Cmp     EDX,EAX                                                         ;Has height reached destination?
        JL      %%EnvDone                                                       ;   No

        Mov     [PBX+eVal],EDX                                                  ;Set destination
        Jmp     %%EnvDirectE

    %%EnvDirectH:
        Add     EAX,[PBX+eAdj]                                                  ;Add adjustment to height
        Mov     [PBX+eVal],EAX
        Cmp     EDX,EAX                                                         ;Has height reached destination?
        JG      %%EnvDone                                                       ;   No

        Mov     [PBX+eVal],EDX                                                  ;Set destination

    %%EnvDirectE:
        Or      byte [PBX+eMode],E_IDLE                                         ;Envelope is now constant

    %%EnvDone:
    Mov     AL,[PBX+vRsv]
    Test    AL,1
    JZ      %%ChkGain
        Mov     byte [PBX+vRsv],0
        Push    PBX                                                             ;Update new ADSR parameters
        LblOp   Sub,PBX,mix
        Call    RADSR
        Pop     PBX
        Jmp     %%LoopDone

    %%ChkGain:
    Test    AL,2
    JZ      %%LoopDone
        Mov     byte [PBX+vRsv],0
        Push    PBX                                                             ;Update new Gain parameters
        LblOp   Sub,PBX,mix
        Call    RGain
        Pop     PBX

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
; always 32kHz, but in the case of an emulator the sample rate can change.  So measures have to be
; taken to ensure the filter will have the same effect, regardless of the output sample rate.
;
;To overcome this problem, I figured each tap of the filter is applied every 31250ns.  So the
; solution is to calculate when 31250ns have gone by, and use the sample at that point.  Of course
; this method really only works if the output rate is a multiple of 32k.  In order to get accurate
; results, some sort of interpolation method needs to be introduced.  I went the cheap route and
; used linear interpolation.
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
    FISt    dword [PSP-4]
    Mov     EAX,[PSP-4]
    Add     EAX,32768
    SAR     EAX,16                                                              ;Did a sample overflow signed-16bit?
    JZ      %%OK                                                                ;   No, do nothing
        Mov     EAX,[PSP-4]                                                     ;There is no overflow because FIR is handled with
        MovSX   EAX,AX                                                          ; 32bit-float, emulates signed-16bit overflow here.
        And     EAX,~1                                                          ;All numbers used by DSP are even

        Mov     [PSP-4],EAX
        FSubP   %1,ST
        FILd    dword [PSP-4]
        FAdd    %1,ST

    %%OK:
%endmacro

%macro FIRClampL 1
    FISt    dword [PSP-4]
    Mov     EAX,[PSP-4]
    Add     EAX,32768
    SAR     EAX,16                                                              ;Did a sample overflow signed-16bit?
    JZ      %%OK                                                                ;   No, do nothing
        Mov     EAX,[PSP-4]                                                     ;If s < -32768, s = -32768
        SAR     EAX,31                                                          ;If s > 32767, s = 32767
        Not     EAX
        XOr     EAX,-32768
        And     EAX,~1                                                          ;All numbers used by DSP are even

        Mov     [PSP-4],EAX
        FSubP   %1,ST
        FILd    dword [PSP-4]
        FAdd    %1,ST

    %%OK:
%endmacro

%macro FIRClampH 1
    FISt    dword [PSP-4]
    Mov     EAX,[PSP-4]
    Add     EAX,65536
    SAR     EAX,17                                                              ;Did a sample overflow signed-16bit?
    JZ      %%OK                                                                ;   No, do nothing
        Mov     EAX,[PSP-4]                                                     ;If s < -65536, s = -65536
        SAR     EAX,31                                                          ;If s > 65535, s = 65535
        Not     EAX
        XOr     EAX,-65536

        Mov     [PSP-4],EAX
        FSubP   %1,ST
        FILd    dword [PSP-4]
        FAdd    %1,ST

    %%OK:
%endmacro

%macro FIRFilter 0
    Test    dword [dspOpts],DSP_ECHOFIR
    JZ      %%NoZero

    LoadPtr PBX,mix
    XOr     DX,DX
    Inc     DH
    Mov     CL,8

    %%ChMute:
        Test    byte [PBX+mFlg],MFLG_MUTE                                       ;Is voice muted by user?
        SetZ    AL
        Dec     AL
        And     AL,DH
        Or      DL,AL

        Sub     PBX,-80h
        Add     DH,DH

    Dec     CL
    JNZ     %%ChMute

    Test    DL,DL                                                               ;DL = Muted channels, are any channels muted?
    JZ      %%NoZero                                                            ;   No

    Not     DL                                                                  ;DL = Not muted channels
    Mov     DH,[dsp+eon]                                                        ;DH = Using echo channels
    And     DH,DL                                                               ;Are all channels using echoes muted?
    JNZ     %%NoZero                                                            ;   No
        FLd     dword [fpShR1]                                                  ;Force feedback in half, without echo. (If there is
        FMul    ST1,ST                                                          ; a loud feedback that causes clipping, mute the
        FMul    ST2,ST                                                          ; channel toprevent the sound from playing forever.)
        FStP    ST

    %%NoZero:
    Sub     byte [firCur],4                                                     ;Move index back one sample. (Index will wrap around
    Mov     EBX,[firCur]                                                        ; after 64 samples, enough for up to 256kHz output.)
    IdxLd   LEA,PBX,firBuf,PBX*2                                                ;PBX -> Current sample in filter buffer
                                                                                ;                                   |FBR FBL
    Test    dword [dspOpts],DSP_ECHOFIR
    JZ      %%Skip
        FLd     ST                                                              ;Clamp 16-bit sample                |FBR FBL FBL
        FIRClampL   ST1
        FStP    ST                                                              ;                                   |FBR FBL

        FLd     ST1                                                             ;                                   |FBR FBL FBR
        FIRClampL   ST2
        FStP    ST                                                              ;                                   |FBR FBL

    %%Skip:
    FSt     dword [PBX]                                                         ;Store new samples in buffer
    FSt     dword [FIRBUF*2+PBX]
    FStP    dword [FIRBUF*4+PBX]                                                ;                                   |FBR
    FSt     dword [PBX+4]
    FSt     dword [FIRBUF*2+4+PBX]
    FStP    dword [FIRBUF*4+4+PBX]                                              ;                                   |(empty)

    FLdZ                                                                        ;                                   |0
    FLdZ                                                                        ;                                   |0 0
    Test    dword [dspOpts],DSP_ECHOFIR
    SetNZ   CH

    MovZX   EDX,CH                                                              ;PBX -> Unfiltered sample
    Dec     EDX
    Not     EDX
    And     EDX,FIRBUF*2+56
    Add     PBX,PDX

    MovZX   EDX,CH                                                              ;PDX -> Filter taps
    Dec     EDX
    And     EDX,28
    IdxLd   LEA,PDX,firTaps,PDX

    Mov     dword [PSP-8],0                                                     ;Reset decimal overflow, so filtering is consistant
    Mov     CL,8                                                                ;8-tap FIR filter

    %%Tap:
        FILd    dword [PSP-8]                                                   ;                                   |0 0 firDec
        FMul    dword [fpShR16]                                                 ;                                   |0 0 firDec>>16=FD

        FLd     dword [PBX+8]                                                   ;Interpolate left sample            |0 0 FD S1
        FSub    dword [PBX]                                                     ;                                   |0 0 FD S1-S2
        FMul    ST1                                                             ;                                   |0 0 FD (S1-S2)*FD
        FAdd    dword [PBX]                                                     ;                                   |0 0 FD (S1-S2)*FD+S2
        FMul    dword [PDX]                                                     ;                                   |0 0 FD ((S1-S2)*FD+S2)*FT
        FAddP   ST2,ST                                                          ;                                   |0 ((S1-S2)*FD+S2)*FT FD

        FLd     dword [PBX+12]                                                  ;Interpolate right sample           |0 FBL FD S1
        FSub    dword [PBX+4]                                                   ;                                   |0 FBL FD S1-S2
        FMulP   ST1,ST                                                          ;                                   |0 FBL (S1-S2)*FD
        FAdd    dword [PBX+4]                                                   ;                                   |0 FBL (S1-S2)*FD+S2
        FMul    dword [PDX]                                                     ;                                   |0 FBL ((S1-S2)*FD+S2)*FT
        FAddP   ST2,ST                                                          ;                                   |FBR FBL

        Test    dword [dspOpts],DSP_ECHOFIR
        JZ      %%ClampH
        Dec     CL                                                              ;Is calculate the oldest sample (n=0)?
        JZ      %%ClampL                                                        ;   Yes
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
            Jmp     %%Next

        %%ClampH:
            FLd     ST                                                          ;Clamp 17-bit sample                |FBR FBL FBL
            FIRClampH   ST1
            FStP    ST                                                          ;                                   |FBR FBL

            FLd     ST1                                                         ;                                   |FBR FBL FBR
            FIRClampH   ST2
            FStP    ST                                                          ;                                   |FBR FBL

        %%Next:
        Mov     EAX,[PSP-8]                                                     ;Determine next sample to use in filter
        Add     EAX,[firRate]
        Mov     [PSP-8],AX
        ShR     EAX,16

        Test    CH,CH
        JNZ     %%NewFIR
            LEA     PBX,[PAX*8+PBX]                                             ;PBX -> Sample to use in filter
            Sub     PDX,4                                                       ;PDX -> Next filter tap

        Dec     CL
        JNZ     %%Tap
        Jmp     %%Done

        %%NewFIR:
            ShL     EAX,3                                                       ;Multiply upper 16-bit by 8, not use 'ShR EAX,13'
            Sub     PBX,PAX                                                     ;PBX -> Sample to use in filter
            Add     PDX,4                                                       ;PDX -> Next filter tap

        Dec     CL
        JNZ     %%Tap

    %%Done:
%endmacro


;===================================================================================================
;DSP Catch Up with the Processing of SPC700

PROC CatchUp

    Push    PAX

    Mov     EAX,[t64Cnt]
    ShR     EAX,1
    Sub     EAX,[outCnt]
    JZ      .Done

    Add     [outCnt],EAX

    Push    PDX
    Mul     dword [outRate]
    Add     EAX,[outDec]
    AdC     EDX,0
    Mov     [outDec],AX
    ShRD    EAX,EDX,16

    Sub     [outLeft],EAX
    JNC     .Okay
        Add     EAX,[outLeft]
        Mov     dword [outLeft],0

    .Okay:
    Test    EAX,EAX
    JZ      .Skip
        Mov     PDX,[pOutBuf]                                                   ;Call cannot infer that a memory operand
        Call    EmuDSP,PDX,EAX                                                  ; holds a pointer -- load it into a
        Mov     [pOutBuf],PAX                                                   ; register first (PDX is free here)

    .Skip:
%if INTBK
    Push    PCX                                                                 ;Run KON/KOFF processing after emulate DSP
    CatchKOff
    CatchKOn
    Pop     PCX,PDX
%else
    Push    PBX,PCX                                                             ;Run KON processing after emulate DSP
    XOr     CH,CH                                                               ;Set CH = 0 for use with CatchKOn
    CatchKOn
    Pop     PCX,PBX,PDX
%endif

    .Done:
    Pop     PAX

ENDP


;===================================================================================================
;Set Automatic EmuDSP Parameters
;
;Destroys:
;   ECX,EDX

PROC SetEmuDSP, pBufD, numD, rateD

    Mov     EAX,[rateD]
    Test    EAX,EAX
    JZ      .Final
        XOr     EDX,EDX
        Mov     [outDec],EDX

        ShLD    EDX,EAX,16
        ShL     EAX,16
        Mov     ECX,32000
        Div     ECX
        Mov     [outRate],EAX

        Mov     EAX,[numD]
        Mov     [outLeft],EAX
        Mov     PAX,[pBufD]
        Mov     [pOutBuf],PAX
        Mov     EAX,[t64Cnt]
        ShR     EAX,1
        Mov     [outCnt],EAX
        RetN

    .Final:
        Mov     PAX,[pOutBuf]                                                   ;See the CatchUp note on preloading a
        Call    EmuDSP,PAX,[outLeft]                                            ; pointer-holding memory operand first
        Mov     [pOutBuf],PAX
        Mov     dword [outLeft],0

ENDP


;===================================================================================================
;Emulate SPC700

PROC EmuDSP, pBuf, num
USES ALL

    Mov     PAX,[pBuf]
    Mov     EDX,[num]
    Test    EDX,EDX
    JZ      .Done

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

    Push    PBX
    Mov     BH,8
    Mov     BL,1
    XOr     DH,DH
    LoadPtr PSI,mix+mFlg

    .Noise:
        Test    byte [PSI],MFLG_NOISE                                           ;Is noise enabled?
        SetZ    DL
        Dec     DL
        And     DL,BL
        Or      DH,DL

        Add     BL,BL
        Sub     PSI,-80h

    Dec     BH
    JNZ     .Noise
    Pop     PBX

    And     DH,BH
    Mov     [dspNoiseF],DH
    Or      [dspNoise],DH

    Test    dword [dspOpts],DSP_FLOAT                                           ;Is volume output floating-point?
    JNZ     .Next                                                               ;   Yes
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
        JBE     .NSmpOK
            Mov     EDX,MIX_SIZE

        .NSmpOK:
        Sub     [num],EDX

%ifdef SPC700_INC
        Test    byte [dbgOpt],DSP_HALT                                          ;Do nothing if APU is suspended
        JNZ     .Mute
%endif

        ;Call emulation routine ---------------
        Call    RunDSP                                                          ;Run DSP emulation
        JC      .Next                                                           ;Quit, if emulation produced output

    .Mute:
        ;Output silence -----------------------
        Mov     PDI,PAX                                                         ;PDI -> Buffer to store output

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
        Mov     PAX,PDI                                                         ;PAX -> End of buffer

        Jmp     .Next

    .Quit:
    Test    dword [dspOpts],DSP_FLOAT                                           ;Is volume output floating-point?
    JNZ     .OutFloat                                                           ;   Yes
        FLd     dword [vMMaxL]
        FMul    dword [fpShR16]
        FIStP   dword [vMMaxL]
        FLd     dword [vMMaxR]
        FMul    dword [fpShR16]
        FIStP   dword [vMMaxR]

    .OutFloat:
    Push    PAX
    Call    SetFade

    ;Update ENVX and OUTX registers ----------
    LoadPtr PBX,mix
    LoadPtr PSI,dsp
    Mov     DH,1

    .XRegs:
        Mov     EAX,[PBX+eVal]
        ShR     EAX,E_SHIFT
        Mov     [PSI+envx],AL

        Mov     AL,[PBX+mOut+1]
        Mov     [PSI+outx],AL

        Add     PSI,10h
        Sub     PBX,-80h

    Add     DH,DH
    JNZ     .XRegs

    ;Update DSP data register on SPC700 side -
    Mov     PBX,[pAPURAM]
    MovZX   EDX,byte [0F2h+PBX]
    IdxLd   Mov,DL,dsp,PDX
    Mov     [0F3h+PBX],DL
    Pop     PAX

    .Done:

ENDP


%macro CalRamp1 0-1
    Mov     EAX,[PCX]
    Cmp     EAX,[PCX-8]
    JE      %%OK

    FLd     dword [PCX]                                                         ;Current                            |Current
    FCom    dword [PCX-8]                                                       ;Target                             |Current
    FNSTSW  AX
    Test    AH,1                                                                ;Is C0 = 0 (Current > Target)?,
    JZ      %%Sub                                                               ;   Yes, subtraction

    %if %0                                                                      ;Current += volRamp
        FAdd    dword [%1]
    %else
        FAdd    dword [volRamp1]
    %endif

        FCom    dword [PCX-8]                                                   ;Target                             |Current
        FNSTSW  AX
        FStP    dword [PCX]                                                     ;Update current                     |(empty)
        Test    AH,1                                                            ;Is C0 = 0 (Current > Target)?,
        JNZ     %%OK                                                            ;   No, re-change with next tick
        Jmp     %%Force

    %%Sub:
    %if %0                                                                      ;Current -= volRamp
        FSub    dword [%1]
    %else
        FSub    dword [volRamp1]
    %endif

        FCom    dword [PCX-8]                                                   ;Target                             |Current
        FNSTSW  AX
        FStP    dword [PCX]                                                     ;Update current                     |(empty)
        Test    AH,1                                                            ;Is C0 = 0 (Current > Target)?,
        JZ      %%OK                                                            ;   Yes, re-change with next tick

    %%Force:
        Mov     EAX,[PCX-8]
        Mov     [PCX],EAX

    %%OK:
%endmacro

%macro CalRamp2 0-1
    Mov     AL,[voiceMix]
    Test    AL,AL
    JZ      %%Force

    %if %0
        Mov     EAX,[PCX]
        Test    EAX,EAX
        JZ      %%Force
    %endif

        CalRamp1    volRamp2
        Jmp     %%OK

    %%Force:
        Mov     EAX,[PCX-8]
        Mov     [PCX],EAX

    %%OK:
%endmacro

%macro MixSample 0
    ;Get sample ========================
%ifdef WIN64
    Mov     PSI,PBX                                                             ;Reconstruct the real pointer (see note in
    Mov     EAX,[PBX+sIdx]                                                      ; StartSrc on bCur/sIdx)
    Add     PSI,PAX                                                             ;PSI -> Current sample index
%else
    Mov     ESI,[EBX+sIdx]                                                      ;PSI -> Current sample index
%endif
    MovZX   EAX,word [PBX+mDec]
    Call    [pInter]                                                            ;                                   |smp

    Test    [dspNoise],CH                                                       ;Is noise enabled?
    JZ      %%NoNoise                                                           ;   No
        FStP    ST                                                              ;                                   |(empty)
        XOr     EAX,EAX
        Test    [dspNoiseF],CH
        SetNZ   AL
        IdxUn   FILd dword,nSmp,PAX*4                                           ;                                   |noise

    %%NoNoise:

    ;Mixing ============================
    Mov     EAX,[PBX+eVal]
    Mov     [envCrt],EAX
    XOr     EAX,EAX
    Test    dword [dspOpts],DSP_NOENV                                           ;Is envelope disabled?
    SetNZ   AL
    IdxUn   FIMul dword,envCrt,PAX*4
    FMul    dword [fpEShR]
    FISt    dword [PBX+mOut]

    Test    byte [PBX+mFlg],MFLG_MUTE                                           ;Is voice muted by user?
    JNZ     .VoiceOff                                                           ;   Yes

    MovZX   EAX,byte [PBX+mSrc]                                                 ;EAX = Source
    IdxLd   Mov,AH,scr700dsp,PAX                                                ;AH = DSPFlag[EAX]
    Test    AH,S700_MUTE                                                        ;AH and S700_MUTE = S700_MUTE?
    JNZ     .VoiceOff                                                           ;   Yes
%endmacro

%macro MixVoice 0
%if STEREO
    Test    byte [PBX+mFlg],MFLG_KOFF
    JNZ     %%NoChVol
        Push    PAX,PCX,PDX
        LEA     PCX,[PBX+mChnL]
        CalRamp1
        LEA     PCX,[PBX+mChnR]
        CalRamp1
        Pop     PDX,PCX,PAX

    %%NoChVol:
%endif

%if VMETERV
    Sub     PSP,16                                                              ;Create a temporary stack space for samples
%endif
    FLd     ST
    Test    [dsp+eon],CH
    JNZ     %%VoiceEcho
        FMul    dword [PBX+mChnL]
        Test    AH,S700_VOLUME                                                  ;AH and S700_VOLUME = S700_VOLUME?
        JZ      %%NoEchoL                                                       ;   No
            MovZX   ESI,AL                                                      ;ESI = AL
            IdxUn   FIMul dword,scr700vol,PSI*4
            FMul    dword [fpShR16]

        %%NoEchoL:

%if VMETERV
        FISt    dword [PSP]                                                     ;Store sample as an integer
        FSt     dword [PSP+4]                                                   ;Store sample as an floating-point
%endif
        FAdd    dword [PDI]
        FStP    dword [PDI]

        FMul    dword [PBX+mChnR]
        Test    AH,S700_VOLUME                                                  ;AH and S700_VOLUME = S700_VOLUME?
        JZ      %%NoEchoR                                                       ;   No
            MovZX   ESI,AL                                                      ;ESI = AL
            IdxUn   FIMul dword,scr700vol,PSI*4
            FMul    dword [fpShR16]

        %%NoEchoR:

%if VMETERV
        FISt    dword [PSP+8]
        FSt     dword [PSP+12]
%endif
        FAdd    dword [PDI+4]
        FSt     dword [PDI+4]
        Jmp     %%NoVoiceEcho

    %%VoiceEcho:
        FMul    dword [PBX+mChnL]
        Test    AH,S700_VOLUME                                                  ;AH and S700_VOLUME = S700_VOLUME?
        JZ      %%EchoL                                                         ;   No
            MovZX   ESI,AL                                                      ;ESI = AL
            IdxUn   FIMul dword,scr700vol,PSI*4
            FMul    dword [fpShR16]

        %%EchoL:

%if VMETERV
        FISt    dword [PSP]
        FSt     dword [PSP+4]
%endif
        FLd     ST
        FAdd    dword [PDI]
        FStP    dword [PDI]
        FAdd    dword [PDI+8]
        FStP    dword [PDI+8]

        FMul    dword [PBX+mChnR]
        Test    AH,S700_VOLUME                                                  ;AH and S700_VOLUME = S700_VOLUME?
        JZ      %%EchoR                                                         ;   No
            MovZX   ESI,AL                                                      ;ESI = AL
            IdxUn   FIMul dword,scr700vol,PSI*4
            FMul    dword [fpShR16]

        %%EchoR:

%if VMETERV
        FISt    dword [PSP+8]
        FSt     dword [PSP+12]
%endif
        FLd     ST
        FAdd    dword [PDI+4]
        FStP    dword [PDI+4]
        FAdd    dword [PDI+12]
        FSt     dword [PDI+12]

    %%NoVoiceEcho:

%if VMETERV
    ;Save greatest sample output ----
    ;NOTE (amd64 port): was Push/Pop-based (each Pop consuming 4 bytes to match the Sub ESP,16
    ; reservation above) -- POP only exists at 8-byte granularity on amd64, so this now reads the
    ; reserved slots directly by address and deallocates them with one Add PSP,16 instead.

    Test    dword [dspOpts],DSP_FLOAT                                           ;Is volume output floating-point?
    JNZ     %%ChFloat                                                           ;   Yes
        Mov     EAX,[PSP]                                                       ;Left sample (integer)
        CDQ                                                                     ;EDX:EAX = EAX
        XOr     EAX,EDX
        Sub     EAX,EDX

        Sub     EAX,[PBX+vMaxL]
        CDQ
        Not     EDX
        And     EAX,EDX
        Add     [PBX+vMaxL],EAX

        Mov     EAX,[PSP+8]                                                     ;Right sample (integer)
        CDQ
        XOr     EAX,EDX
        Sub     EAX,EDX

        Sub     EAX,[PBX+vMaxR]
        CDQ
        Not     EDX
        And     EAX,EDX
        Add     [PBX+vMaxR],EAX

        Add     PSP,16
        Jmp     %%Done

    %%ChFloat:
        Mov     EAX,[PSP+4]                                                     ;Left sample (float)
        And     EAX,7FFFFFFFh

        Sub     EAX,[PBX+vMaxL]
        CDQ
        Not     EDX
        And     EAX,EDX
        Add     [PBX+vMaxL],EAX

        Mov     EAX,[PSP+12]                                                    ;Right sample (float)
        And     EAX,7FFFFFFFh

        Sub     EAX,[PBX+vMaxR]
        CDQ
        Not     EDX
        And     EAX,EDX
        Add     [PBX+vMaxR],EAX

        Add     PSP,16

    %%Done:
%endif
%endmacro

%macro MixMaster 0
    ;Multiply samples by main volume ------
    LoadPtr PCX,nowMainL
    CalRamp2    1
    LoadPtr PCX,nowMainR
    CalRamp2    1

    FLd     dword [PSI]
    FMul    dword [nowMainL]
    Mov     AH,[scr700mds+S700_MVOL_L]
    Test    AH,S700_VOLUME                                                      ;AH and S700_VOLUME = S700_VOLUME?
    JZ      %%NoMainL                                                           ;   No
        FIMul   dword [scr700mvl+S700_MVOL_L*4]
        FMul    dword [fpShR16]

    %%NoMainL:
    FStP    dword [PSI]

    FLd     dword [PSI+4]
    FMul    dword [nowMainR]
    Mov     AH,[scr700mds+S700_MVOL_R]
    Test    AH,S700_VOLUME                                                      ;AH and S700_VOLUME = S700_VOLUME?
    JZ      %%NoMainR                                                           ;   No
        FIMul   dword [scr700mvl+S700_MVOL_R*4]
        FMul    dword [fpShR16]

    %%NoMainR:
    FStP    dword [PSI+4]
%endmacro

%macro MixEchoDSP 0
    ;NOTE (amd64 port): PSI already holds this macro's mixBuf-pointer parameter (used throughout the
    ; rest of the macro below) -- PCX is used as scratch here instead so PSI stays untouched.

    Mov     EDI,[echoMaxD]
    Sub     EDI,[echoCurD]
    IdxLd   LEA,PDI,echoBuf,PDI,PCX

    ZeroDN  PDI+4
    ZeroDN  PDI

    FLd     dword [PDI+4]                                                       ;                                   |FBR
    FLd     dword [PDI]                                                         ;                                   |FBR FBL

    ;Filter echo -----------------------
    Test    dword [dspOpts],DSP_NOFIR                                           ;Is FIR filter disabled?
    JNZ     %%NoFilter                                                          ;   Yes
        FIRFilter
    %%NoFilter:

    FLd     ST1                                                                 ;                                   |FBR FBL FBR
    FLd     ST1                                                                 ;                                   |FBR FBL FBR FBL

    ;Advance echo sample pointer -------
    Sub     dword [echoCurD],8
    JNZ     %%NoReset
        Mov     EAX,[echoLenD]
        Mov     [echoMaxD],EAX
        Mov     [echoCurD],EAX

    %%NoReset:

    ;Add echo to main output -----------
    LoadPtr PCX,nowEchoL
    CalRamp2
    LoadPtr PCX,nowEchoR
    CalRamp2

    FMul    dword [nowEchoL]                                                    ;                                   |FBR FBL FBR FBL*EchoL
    Mov     AH,[scr700mds+S700_ECHO_L]
    Test    AH,S700_VOLUME                                                      ;AH and S700_VOLUME = S700_VOLUME?
    JZ      %%NoEchoL                                                           ;   No
        FIMul   dword [scr700mvl+S700_ECHO_L*4]
        FMul    dword [fpShR16]

    %%NoEchoL:
    FAdd    dword [PSI]                                                         ;                                   |FBR FBL FBR EchoL+ML
    FStP    dword [PSI]                                                         ;                                   |FBR FBL FBR

    FMul    dword [nowEchoR]                                                    ;                                   |FBR FBL FBR*EchoR
    Mov     AH,[scr700mds+S700_ECHO_R]
    Test    AH,S700_VOLUME                                                      ;AH and S700_VOLUME = S700_VOLUME?
    JZ      %%NoEchoR                                                           ;   No
        FIMul   dword [scr700mvl+S700_ECHO_R*4]
        FMul    dword [fpShR16]

    %%NoEchoR:
    FAdd    dword [PSI+4]                                                       ;                                   |FBR FBL FBR+MR
    FStP    dword [PSI+4]                                                       ;                                   |FBR FBL

    ;Calculate echo feedback -----------
%if STEREO
    FLd     ST                                                                  ;                                   |FBR FBL FBL
    FMul    dword [echoFB]                                                      ;                                   |FBR FBL FBL*EchoFB
    FLd     ST2                                                                 ;                                   |FBR FBL EFBL FBR
    FMul    dword [echoFBCT]                                                    ;                                   |FBR FBL EFBL FBR*EchoFBCT
    FAddP   ST1,ST                                                              ;                                   |FBR FBL EFBL+EFBCR
    FAdd    dword [PSI+8]                                                       ;                                   |FBR FBL EFBL+EL
    FStP    dword [PDI]                                                         ;                                   |FBR FBL
    ZeroDNEFB   PDI

    FMul    dword [echoFBCT]                                                    ;                                   |FBR FBL*EchoFBCT
    FXCh    ST1                                                                 ;                                   |EFBCL FBR
    FMul    dword [echoFB]                                                      ;                                   |EFBCL FBR*EchoFB
    FAddP   ST1,ST                                                              ;                                   |EFBCL+EFBR
    FAdd    dword [PSI+12]                                                      ;                                   |EFBR+ER
    FStP    dword [PDI+4]                                                       ;                                   |(empty)
    ZeroDNEFB   PDI+4
%else
    FMul    dword [echoFB]                                                      ;                                   |FBR FBL*EchoFB
    FAdd    dword [PSI+8]                                                       ;                                   |FBR EFBL+EL
    FStP    dword [PDI]                                                         ;                                   |FBR
    ZeroDNEFB   PDI

    FMul    dword [echoFB]                                                      ;                                   |FBR*EchoFB
    FAdd    dword [PSI+12]                                                      ;                                   |EFBR+ER
    FStP    dword [PDI+4]                                                       ;                                   |(empty)
    ZeroDNEFB   PDI+4
%endif
%endmacro

%macro MixEchoMem 0
    Push    PBX,PCX
    Mov     EDX,[echoDecM]
    Sub     EDX,32000
    JNS     %%Skip

    Push    PCX                                                                 ;Dummy stack
    FLd     dword [PDI]
    FIStP   word [PSP]
    FLd     dword [PDI+4]
    FIStP   word [PSP+2]
    Pop     PCX                                                                 ;PCX = [PSP] (dword)
    And     ECX,~1 & ~10000h                                                    ;All numbers used by DSP are even

    %%Loop:
    Mov     PBX,[pAPURAM]
    Mov     BH,[dsp+esa]
    Mov     EAX,[echoMaxM]
    Sub     EAX,[echoCurM]
    Add     BX,AX
    Mov     [PBX],ECX

    Sub     dword [echoCurM],4
    JNZ     %%NoReset
        Mov     EAX,[echoLenM]
        Mov     [echoMaxM],EAX
        Mov     [echoCurM],EAX

    %%NoReset:
    Add     EDX,[dspRate]
    JS      %%Loop

    %%Skip:
    Mov     [echoDecM],EDX
    Pop     PCX,PBX
%endmacro

%macro NopEchoMem 0
    Mov     EDX,[echoDecM]
    Sub     EDX,32000
    JNS     %%Skip

    %%Loop:
    Sub     dword [echoCurM],4
    JNZ     %%NoReset
        Mov     EAX,[echoLenM]
        Mov     [echoMaxM],EAX
        Mov     [echoCurM],EAX

    %%NoReset:
    Add     EDX,[dspRate]
    JS      %%Loop

    %%Skip:
    Mov     [echoDecM],EDX
%endmacro

%macro MixBASS 0
    ;Save Current Sample --------------
    Mov     ECX,[lowCnt1]                                                       ;ECX = Cnt1
    Mov     EDX,[lowCnt2]                                                       ;EDX = Cnt2

    Mov     EAX,[PSI]                                                           ;EAX = Current Sample (Left)
    IdxSt   Mov,lowBufL1,PCX,EAX                                                ;BufL1[ECX] = EAX
    IdxSt   Mov,lowBufL2,PDX,EAX                                                ;BufL2[EDX] = EAX
    Push    PAX                                                                 ;Push PAX (Save Current Sample)

    Mov     EAX,[PSI+4]                                                         ;EAX = Current Sample (Right)
    IdxSt   Mov,lowBufR1,PCX,EAX                                                ;BufR1[ECX] = EAX
    IdxSt   Mov,lowBufR2,PDX,EAX                                                ;BufR2[EDX] = EAX
    Push    PAX                                                                 ;Push PAX (Save Current Sample)

    Test    ECX,ECX                                                             ;ECX = 0x00?
    JNZ     %%CountL                                                            ;   No
        Mov     ECX,[lowSize1]                                                  ;ECX = Size1

    %%CountL:
    Sub     ECX,4                                                               ;ECX -= 4
    Mov     [lowCnt1],ECX                                                       ;Cnt1 = ECX

    Test    EDX,EDX                                                             ;EDX = 0x00?
    JNZ     %%CountR                                                            ;   No
        Mov     EDX,[lowSize2]                                                  ;EDX = Size2

    %%CountR:
    Sub     EDX,4                                                               ;EDX -= 4
    Mov     [lowCnt2],EDX                                                       ;Cnt2 = EDX

    ;Calculate BASS BOOST -------------
    FLd     dword [lowSumL1]                                                    ;Left                               |SumL1
    IdxUn   FSub dword,lowBufL1,PCX                                             ;                                   |SumL1-BufL1[ECX]
    FAdd    dword [PSI]                                                         ;                                   |SumL1-BufL1[ECX]+SampleL
    FSt     dword [lowSumL1]                                                    ;                                   |   "
    FMul    dword [lowLv1]                                                      ;                                   |BASS1=(SumL1-BufL1[EDX]+SampleL)*Lv1
    FLd     dword [lowSumL2]                                                    ;                                   |BASS1 SumL2
    IdxUn   FSub dword,lowBufL2,PDX                                             ;                                   |BASS1 SumL2-BufL2[EDX]
    FAdd    dword [PSI]                                                         ;                                   |BASS1 SumL2-BufL2[EDX]+SampleL
    FSt     dword [lowSumL2]                                                    ;                                   |   "
    FMul    dword [lowLv2]                                                      ;                                   |BASS1 BASS2=(SumL2-BufL2[EDX]+SampleL)*Lv2
    FSubP   ST1,ST                                                              ;                                   |BASS1-BASS2
    FAdd    dword [PSI]                                                         ;                                   |BASS1-BASS2+SampleL
    FStP    dword [PSI]                                                         ;                                   |(empty)
    ZeroDN  PSI

    FLd     dword [lowSumR1]                                                    ;Right                              |SumR1
    IdxUn   FSub dword,lowBufR1,PCX                                             ;                                   |SumR1-BufR1[ECX]
    FAdd    dword [PSI+4]                                                       ;                                   |SumR1-BufR1[ECX]+SampleR
    FSt     dword [lowSumR1]                                                    ;                                   |   "
    FMul    dword [lowLv1]                                                      ;                                   |BASS1=(SumR1-BufR1[EDX]+SampleR)*Lv1
    FLd     dword [lowSumR2]                                                    ;                                   |BASS1 SumR2
    IdxUn   FSub dword,lowBufR2,PDX                                             ;                                   |BASS1 SumR2-BufR2[EDX]
    FAdd    dword [PSI+4]                                                       ;                                   |BASS1 SumR2-BufR2[EDX]+SampleR
    FSt     dword [lowSumR2]                                                    ;                                   |   "
    FMul    dword [lowLv2]                                                      ;                                   |BASS1 BASS2=(SumR2-BufR2[EDX]+SampleR)*Lv2
    FSubP   ST1,ST                                                              ;                                   |BASS1-BASS2
    FAdd    dword [PSI+4]                                                       ;                                   |BASS1-BASS2+SampleR
    FStP    dword [PSI+4]                                                       ;                                   |(empty)
    ZeroDN  PSI+4

    ;Reset Buffer ---------------------
    Pop     PDX,PCX                                                             ;PCX = Current Sample (Left), PDX = (Right)

    Mov     EAX,[lowSize1]                                                      ;EAX = Size1
    Test    ECX,ECX                                                             ;ECX = 0x00?
    JNZ     %%RstL1                                                             ;   No
        Mov     EAX,[lowRstL1]                                                  ;EAX = RstL1
        Dec     EAX                                                             ;EAX--, EAX = 0x00?
        JNZ     %%RstL1                                                         ;   No
            Mov     [lowSumL1],EAX                                              ;SumL1 = EAX (0x00)
            Inc     EAX                                                         ;EAX++ (0x01)

    %%RstL1:
    Mov     [lowRstL1],EAX                                                      ;RstL1 = EAX

    Mov     EAX,[lowSize2]                                                      ;EAX = Size2
    Test    ECX,ECX                                                             ;ECX = 0x00?
    JNZ     %%RstL2                                                             ;   No
        Mov     EAX,[lowRstL2]                                                  ;EAX = RstL2
        Dec     EAX                                                             ;EAX--, EAX = 0x00?
        JNZ     %%RstL2                                                         ;   No
            Mov     [lowSumL2],EAX                                              ;SumL2 = EAX (0x00)
            Inc     EAX                                                         ;EAX++ (0x01)

    %%RstL2:
    Mov     [lowRstL2],EAX                                                      ;RstL2 = EAX

    Mov     EAX,[lowSize1]                                                      ;EAX = Size1
    Test    EDX,EDX                                                             ;EDX = 0x00?
    JNZ     %%RstR1                                                             ;   No
        Mov     EAX,[lowRstR1]                                                  ;EAX = RstR1
        Dec     EAX                                                             ;EAX--, EAX = 0x00?
        JNZ     %%RstR1                                                         ;   No
            Mov     [lowSumR1],EAX                                              ;SumR1 = EAX (0x00)
            Inc     EAX                                                         ;EAX++ (0x01)

    %%RstR1:
    Mov     [lowRstR1],EAX                                                      ;RstR1 = EAX

    Mov     EAX,[lowSize2]                                                      ;EAX = Size2
    Test    EDX,EDX                                                             ;EDX = 0x00?
    JNZ     %%RstR2                                                             ;   No
        Mov     EAX,[lowRstR2]                                                  ;EAX = RstR2
        Dec     EAX                                                             ;EAX--, EAX = 0x00?
        JNZ     %%RstR2                                                         ;   No
            Mov     [lowSumR2],EAX                                              ;SumR2 = EAX (0x00)
            Inc     EAX                                                         ;EAX++ (0x01)

    %%RstR2:
    Mov     [lowRstR2],EAX                                                      ;RstR2 = EAX
%endmacro

%macro ApplyLevel 0
%if VMETERM
    Mov     EAX,[PSI]                                                           ;EAX = |Left|
    And     EAX,7FFFFFFFh

    Test    dword [dspOpts],DSP_NOSAFE                                          ;Is volume safe disabled?
    JNZ     %%NoMaxL                                                            ;   Yes
    Cmp     EAX,[fpMaxLv]
    JBE     %%NoMaxL
        Mov     byte [dspMute],80h
        Or      byte [disFlag],80h

    %%NoMaxL:
    Sub     EAX,[vMMaxL]                                                        ;*** Positive floats can be operated on as integers ***
    CDQ
    Not     EDX
    And     EAX,EDX
    Add     [vMMaxL],EAX

    Mov     EAX,[PSI+4]                                                         ;EAX = |Right|
    And     EAX,7FFFFFFFh

    Test    dword [dspOpts],DSP_NOSAFE                                          ;Is volume safe disabled?
    JNZ     %%NoMaxR                                                            ;   Yes
    Cmp     EAX,[fpMaxLv]
    JBE     %%NoMaxR
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
    Push    PSI,PBP

    %%Next:
        FLd     dword [aafBufL]                                                 ;Left:Filter1                       |z1
        FLd     dword [PSI]                                                     ;                                   |z1 in
        FLd     ST1                                                             ;                                   |z1 in z1
        FMul    dword [aaf1A1]                                                  ;                                   |z1 in z1*a1
        FSubP   ST1,ST                                                          ;                                   |z1 in-z1*a1
        FSt     dword [aafBufL]                                                 ;                                   |z1 in-z1*a1
        FMul    dword [aaf1B0]                                                  ;                                   |z1 (in-z1*a1)*b0
        FLd     ST1                                                             ;                                   |z1 (in-z1*a1)*b0 z1
        FMul    dword [aaf1B1]                                                  ;                                   |z1 (in-z1*a1)*b0 z1*b1
        FAddP   ST1,ST                                                          ;                                   |z1 (in-z1*a1)*b0+z1*b1=out
        FStP    dword [PSI]                                                     ;                                   |z1
        FStP    ST                                                              ;                                   |(empty)
        ZeroDN  PSI

        FLd     dword [aafBufL]                                                 ;Left:Filter2                       |z1
        FLd     dword [PSI]                                                     ;                                   |z1 in
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
        FStP    dword [PSI]                                                     ;                                   |z1
        FStP    ST                                                              ;                                   |(empty)
        ZeroDN  PSI

        FLd     dword [aafBufR]                                                 ;Right:Filter1                      |z1
        FLd     dword [PSI+4]                                                   ;                                   |z1 in
        FLd     ST1                                                             ;                                   |z1 in z1
        FMul    dword [aaf1A1]                                                  ;                                   |z1 in z1*a1
        FSubP   ST1,ST                                                          ;                                   |z1 in-z1*a1
        FSt     dword [aafBufR]                                                 ;                                   |z1 in-z1*a1
        FMul    dword [aaf1B0]                                                  ;                                   |z1 (in-z1*a1)*b0
        FLd     ST1                                                             ;                                   |z1 (in-z1*a1)*b0 z1
        FMul    dword [aaf1B1]                                                  ;                                   |z1 (in-z1*a1)*b0 z1*b1
        FAddP   ST1,ST                                                          ;                                   |z1 (in-z1*a1)*b0+z1*b1=out
        FStP    dword [PSI+4]                                                   ;                                   |z1
        FStP    ST                                                              ;                                   |(empty)
        ZeroDN  PSI+4

        FLd     dword [aafBufR]                                                 ;Right:Filter2                      |z1
        FLd     dword [PSI+4]                                                   ;                                   |z1 in
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
        FStP    dword [PSI+4]                                                   ;                                   |z1
        FStP    ST                                                              ;                                   |(empty)
        ZeroDN  PSI+4

        Add     PSI,16

    Dec     PBP
    JNZ     %%Next

    Pop     PBP,PSI
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
    SetNC   DL                                                                  ;If do not have enough samples, DL = 1
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

    Add     EBP,EDX
%endmacro

%macro Resampling 0
    Test    dword [smpAdj],-1                                                   ;Convert sample rate?
    JZ      %%Direct                                                            ;   No

    InitSampling

    LoadPtr PBX,smpBuf
    Dec     DL                                                                  ;Has the sample reference point moved?
    JZ      %%Filter                                                            ;   No, do not move sample history
        Mov     DL,3

        %%Tap:
            Mov     EAX,[PBX+8]
            Mov     [PBX],EAX
            Mov     EAX,[PBX+12]
            Mov     [PBX+4],EAX

            Add     PBX,8

        Dec     DL
        JNZ     %%Tap

        Mov     EAX,[PSI]                                                       ;Store the latest sample to history
        Mov     [PBX],EAX
        Mov     EAX,[PSI+4]
        Mov     [PBX+4],EAX

        Add     PBX,-24
        Add     PSI,16

    %%Filter:
        Mov     EAX,[smpCur]
        ShR     EAX,2                                                           ;Shift right by 2 bits to prevent the sign from
        Mov     [PSP-12],EAX                                                    ; entering (max = 40000000h)
        FILd    dword [PSP-12]
        Mov     dword [PSP-12],40000000h
        FILd    dword [PSP-12]
        FDivP   ST1,ST
        FStP    dword [PSP-12]

        FLd     dword [PBX+24]                                                  ;A                                  |s3
        FSub    dword [PBX+16]                                                  ;                                   |s3-s2
        FSub    dword [PBX]                                                     ;                                   |s3-s2-s0
        FAdd    dword [PBX+8]                                                   ;                                   |s3-s2-s0+s1=A'
        FMul    dword [PSP-12]                                                  ;                                   |A'*Frac
        FMul    dword [PSP-12]                                                  ;                                   |A'*Frac^2
        FMul    dword [PSP-12]                                                  ;                                   |A'*Frac^3=A
        FLd     dword [PBX]                                                     ;B                                  |A s0
        FSub    dword [PBX+8]                                                   ;                                   |A s0-s1
        FSub    ST,ST1                                                          ;                                   |A s0-s1-A=B'
        FMul    dword [PSP-12]                                                  ;                                   |A B'*Frac
        FMul    dword [PSP-12]                                                  ;                                   |A B'*Frac^2=B
        FLd     dword [PBX+16]                                                  ;C                                  |A B s2
        FSub    dword [PBX]                                                     ;                                   |A B s2-s0=C'
        FMul    dword [PSP-12]                                                  ;                                   |A B C'*Frac=C
        FLd     dword [PBX+8]                                                   ;D                                  |A B C s1=D
        FAddP   ST1,ST                                                          ;                                   |A B C+D
        FAddP   ST1,ST                                                          ;                                   |A B+C+D
        FAddP   ST1,ST                                                          ;                                   |A+B+C+D
        FStP    dword [PSP-8]                                                   ;                                   |(empty)
        ZeroDN  PSP-8

        FLd     dword [PBX+28]                                                  ;A                                  |s3
        FSub    dword [PBX+20]                                                  ;                                   |s3-s2
        FSub    dword [PBX+4]                                                   ;                                   |s3-s2-s0
        FAdd    dword [PBX+12]                                                  ;                                   |s3-s2-s0+s1=A'
        FMul    dword [PSP-12]                                                  ;                                   |A'*Frac
        FMul    dword [PSP-12]                                                  ;                                   |A'*Frac^2
        FMul    dword [PSP-12]                                                  ;                                   |A'*Frac^3=A
        FLd     dword [PBX+4]                                                   ;B                                  |A s0
        FSub    dword [PBX+12]                                                  ;                                   |A s0-s1
        FSub    ST,ST1                                                          ;                                   |A s0-s1-A=B'
        FMul    dword [PSP-12]                                                  ;                                   |A B'*Frac
        FMul    dword [PSP-12]                                                  ;                                   |A B'*Frac^2=B
        FLd     dword [PBX+20]                                                  ;C                                  |A B s2
        FSub    dword [PBX+4]                                                   ;                                   |A B s2-s0=C'
        FMul    dword [PSP-12]                                                  ;                                   |A B C'*Frac=C
        FLd     dword [PBX+12]                                                  ;D                                  |A B C s1=D
        FAddP   ST1,ST                                                          ;                                   |A B C+D
        FAddP   ST1,ST                                                          ;                                   |A B+C+D
        FAddP   ST1,ST                                                          ;                                   |A+B+C+D
        FStP    dword [PSP-4]                                                   ;                                   |(empty)
        ZeroDN  PSP-4

        Jmp     %%Exit

    %%Direct:
        Mov     EAX,[PSI]
        Mov     [PSP-8],EAX
        Mov     EAX,[PSI+4]
        Mov     [PSP-4],EAX

        Add     PSI,16

    %%Exit:
%endmacro

%macro MuteSampling 0
    Test    dword [smpAdj],-1                                                   ;Convert sample rate?
    JZ      %%Exit                                                              ;   No

    InitSampling

    LoadPtr PBX,smpBuf
    Dec     DL                                                                  ;Has the sample reference point moved?
    JZ      %%Exit                                                              ;   No, do not move sample history
        Mov     DL,3

        %%Tap:
            Mov     EAX,[PBX+8]
            Mov     [PBX],EAX
            Mov     EAX,[PBX+12]
            Mov     [PBX+4],EAX

            Add     PBX,8

        Dec     DL
        JNZ     %%Tap

        FSt     dword [PBX]                                                     ;Store the latest sample to history
        FSt     dword [PBX+4]

    %%Exit:
%endmacro

%macro DoneRunDSP 0
    Pop     PDX,PAX,PBX,PBP
    StC                                                                         ;Set carry
    Mov     PAX,PDI
    RetN
%endmacro

;===================================================================================================
;Run DSP emulation
;
;Emulates the DSP of the SNES using floating-point instructions.
;If no mixing flag is set on, except for pitch modulation, noise generator, and mixing.
;
;In:
;   PAX-> Buffer to store output
;   EDX = Number of samples to create (1 - MIX_SIZE)
;
;Out:
;   CF  = Set, samples were created
;   PAX-> End of buffer
;   EDX = Number of samples to create
;
;   CF  = Clear, DSP is muted
;   PDI-> Buffer to store output
;   EDX = Number of samples to create
;
;Destroys:
;   ECX,ESI,EDI,ST0-ST7

PROC RunDSP

    Push    PBP,PBX,PAX,PDX                                                     ;Last register must be PAX,PDX
    FInit

    Test    byte [disFlag],80h                                                  ;Is DSP reset or volume safe mode? (disFlag = [7])
    JNZ     .Mute                                                               ;   Yes

    ;=========================================
    ; Mix voices

    Mov     EBP,[PSP]
    LoadPtr PDI,mixBuf

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
        LoadPtr PBX,mix
        Mov     [PDI],EAX
        Mov     [PDI+4],EAX
        Mov     [PDI+8],EAX
        Mov     [PDI+12],EAX
        Mov     CH,1

        .VoiceMix:
            Test    [voiceMix],CH
            JZ      .VoiceDone

            Test    [dspPMod],CH                                                ;Is pitch modulation enabled?
            JZ      .NoPMod                                                     ;   No, pitch doesn't need to be adjusted
                PitchMod                                                        ;Apply pitch modulation
            .NoPMod:

            Test    byte [envFlag],-1                                           ;Do nothing if envelope is suspended
            JNZ     .NoEnv
                UpdateEnv                                                       ;Update envelope
            .NoEnv:

            MixSample                                                           ;                                   |smp
            MixVoice

            .VoiceOff:
            FStP    ST                                                          ;                                   |(empty)
            UpdateSrc                                                           ;Update sample position

            .VoiceDone:
            Sub     PBX,-80h

        Add     CH,CH
        JNZ     .VoiceMix

        Mov     [adsrCnt],CH                                                    ;Clear number of times to update envelope
        Add     PDI,16

    Dec     EBP
    JNZ     .NextEmu

    Test    byte [disFlag],8h                                                   ;Is pBuf NULL? (disFlag = [3])
    JNZ     .Mute                                                               ;   Yes

    ;=========================================
    ; Apply main volumes and mix in echo

    Mov     EBP,[PSP]
    LoadPtr PSI,mixBuf

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
        JNZ     .NoEchoMem                                                      ;   Yes
            MixEchoMem
%if ECHOMEM
            Jmp     .ExitEchoMem
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
        Add     PSI,16

    Dec     EBP
    JNZ     .NextSmp

    Test    byte [disFlag],40h                                                  ;Is DSP emulation disabled? (disFlag = [6])
    JNZ     .Mute                                                               ;   Yes

    ;=========================================
    ; Store output

    LoadPtr PSI,mixBuf
    Mov     PDI,[PSP+PTRSIZE]
    Mov     EBP,[PSP]

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
        Mov     EAX,[PSP-8]                                                     ;EAX = Sample
        XOr     EDX,EDX
        XOr     PBX,PBX
        BTR     EAX,31                                                          ;EAX = Absolute value
        RCR     EDX,1                                                           ;EDX = Sign of sample
        Sub     EAX,ECX
        SetA    BL                                                              ;PBX = -1 if EAX < ECX
        Dec     PBX
        And     EAX,EBX                                                         ;Clamp EAX
        Add     EAX,ECX
        Or      EAX,EDX                                                         ;Restore sign
        Mov     [PSP-8],EAX
        FLd     dword [PSP-8]

        Mov     EAX,[PSP-4]
        XOr     EDX,EDX
        XOr     PBX,PBX
        BTR     EAX,31
        RCR     EDX,1
        Sub     EAX,ECX
        SetA    BL
        Dec     PBX
        And     EAX,EBX
        Add     EAX,ECX
        Or      EAX,EDX
        Mov     [PSP-4],EAX
        FAdd    dword [PSP-4]

        FMul    dword [fp0_5]

        ;Reduce to integer form ---------------
        Mov     AL,[dspSize]
        Dec     AL
        JZ      .OutMono8
        Dec     AL
        JZ      .OutMono16
        Dec     AL
        JZ      .OutMono24

        .OutMono32:
            FIStP   dword [PDI]
            Add     PDI,4

            Dec     EBP
            JNZ     .NextMonoInt
            DoneRunDSP

        .OutMono8:
            FIStP   dword [PSP-4]
            Mov     DL,[PSP-1]
            Add     DL,80h
            Mov     [PDI],DL
            Inc     PDI

            Dec     EBP
            JNZ     .NextMonoInt
            DoneRunDSP

        .OutMono16:
            FIStP   dword [PSP-4]
            Mov     DX,[PSP-2]
            Mov     [PDI],DX
            Add     PDI,2

            Dec     EBP
            JNZ     .NextMonoInt
            DoneRunDSP

        .OutMono24:
            FIStP   dword [PSP-4]
            Mov     DX,[PSP-3]
            Mov     AL,[PSP-1]
            Mov     [PDI+0],DX
            Mov     [PDI+2],AL
            Add     PDI,3

            Dec     EBP
            JNZ     .NextMonoInt
            DoneRunDSP

    ;32-bit floating-point -------------------
    .OutMonoFloat:
        Resampling

        FLd     dword [PSP-8]
        FAdd    dword [PSP-4]
        FMul    dword [fp0_5]
        FMul    dword [fpShR31]
        FStP    dword [PDI]
        ZeroDN  PDI
        Add     PDI,4

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
        Mov     EAX,[PSP-8]                                                     ;EAX = Sample
        XOr     EDX,EDX
        XOr     PBX,PBX
        BTR     EAX,31                                                          ;EAX = Absolute value
        RCR     EDX,1                                                           ;EDX = Sign of sample
        Sub     EAX,ECX
        SetA    BL                                                              ;PBX = -1 if EAX < ECX
        Dec     PBX
        And     EAX,EBX                                                         ;Clamp EAX
        Add     EAX,ECX
        Or      EAX,EDX                                                         ;Restore sign
        Mov     [PSP-8],EAX
        FLd     dword [PSP-8]

        Mov     EAX,[PSP-4]
        XOr     EDX,EDX
        XOr     PBX,PBX
        BTR     EAX,31
        RCR     EDX,1
        Sub     EAX,ECX
        SetA    BL
        Dec     PBX
        And     EAX,EBX
        Add     EAX,ECX
        Or      EAX,EDX
        Mov     [PSP-4],EAX
        FLd     dword [PSP-4]

        ;Reduce to integer form ---------------
        Mov     AL,[dspSize]
        Dec     AL
        JZ      .OutStereo8
        Dec     AL
        JZ      .OutStereo16
        Dec     AL
        JZ      .OutStereo24

        .OutStereo32:
            FIStP   dword [PDI+4]
            FIStP   dword [PDI]
            Add     PDI,8

            Dec     EBP
            JNZ     .NextStereoInt
            DoneRunDSP

        .OutStereo8:
            FIStP   dword [PSP-4]
            FIStP   dword [PSP-5]
            Mov     DX,[PSP-2]
            Add     DH,80h
            Add     DL,80h
            Mov     [PDI],DX
            Add     PDI,2

            Dec     EBP
            JNZ     .NextStereoInt
            DoneRunDSP

        .OutStereo16:
            FIStP   dword [PSP-4]
            FIStP   dword [PSP-6]
            Mov     EDX,[PSP-4]
            Mov     [PDI],EDX
            Add     PDI,4

            Dec     EBP
            JNZ     .NextStereoInt
            DoneRunDSP

        .OutStereo24:
            FIStP   dword [PSP-4]
            FIStP   dword [PSP-7]
            Mov     DX,[PSP-6]
            Mov     EAX,[PSP-4]
            Mov     [PDI+0],DX
            Mov     [PDI+2],EAX
            Add     PDI,6

            Dec     EBP
            JNZ     .NextStereoInt
            DoneRunDSP

    ;32-bit floating-point -------------------
    .OutStereoFloat:
        Resampling

        FLd     dword [PSP-8]
        FMul    dword [fpShR31]
        FStP    dword [PDI]
        FLd     dword [PSP-4]
        FMul    dword [fpShR31]
        FStP    dword [PDI+4]
        ZeroDN  PDI
        ZeroDN  PDI+4
        Add     PDI,8

        Dec     EBP
        JNZ     .OutStereoFloat
        DoneRunDSP

    .Mute:
    Mov     EBP,[PSP]
    XOr     PDI,PDI

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
        Inc     PDI

    Dec     EBP
    JNZ     .MuteNext

    .MuteDone:
    Pop     PDX,PAX,PBX,PBP
    Mov     EDX,EDI                                                             ;EDI here is a plain sample count (from the Mute
    Mov     PDI,PAX                                                             ; loop above), unlike PAX which is the real pointer
    Cmp     EAX,1                                                               ;Set carry if pBuf is null, so EmuDSP doesn't crash

ENDP


;===================================================================================================
;Decompress Sound Source
;
;Decompresses a 9-byte bit-rate reduced block into 16 16-bit samples
;
;In:
;   AL  = Block header
;   PSI-> Sample Block
;   PDI-> Output buffer
;   EDX = Last sample of previous block
;   EBX = Next to last sample
;
;Out:
;   PSI-> Next Block
;   PDI-> After last sample
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
    Add     EAX,[PCX]                                                           ;s += delta
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
    Add     EAX,[PCX]                                                           ;s += delta
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
    Add     EAX,[PCX]                                                           ;s += delta
    MovSX   EDX,AX                                                              ;EDX = Last sample
%endmacro

%macro UnpckClamp 0
    Add     EAX,65536                                                           ;Clamp 16-bit sample to a 17-bit value,
    SAR     EAX,17                                                              ; because restored value by BRR is used in doubles.
    JZ      %%OK
        SetS    DL                                                              ;If s < -65536 (FFFF0000h), s = 0000h = 0
        MovZX   EDX,DL                                                          ;If s >  65534 (0000FFFEh), s = FFFEh = -2
        Dec     EDX
        Add     EDX,EDX

    %%OK:
%endmacro

UnpckSrc:

    Push    PCX,PBP

    Inc     SI                                                                  ;Inc SI so pointer will wrap around a 16-bit value
    XOr     PCX,PCX
    Mov     CH,AL
    ShR     CH,4
    IdxLd   LEA,PCX,brrTab,PCX                                                  ;PCX -> Row in brrTab
    Mov     PBP,8                                                               ;Decompress 8 bytes (16 nybbles)

    Test    AL,0Ch                                                              ;Does block use ADPCM compression?
    JZ      .Filter0                                                            ;   No
    Test    AL,08h                                                              ;Does block use filter 1?
    JZ      .Filter1                                                            ;   Yes
    Test    AL,04h                                                              ;Does block use filter 2?
    JZ      .Filter2                                                            ;   Yes
    Jmp     .Filter3                                                            ;Then it must use filter 3

    ;[Delta] ----------------------------------
    .Filter0:
        Mov     CL,[PSI]                                                        ;CL indexes delta value
        And     CL,0F0h                                                         ;PCX -> value
        ShR     CL,2

        Mov     EAX,[PCX]                                                       ;EAX = delta
        MovSX   EBX,AX                                                          ;EBX = Next to last sample
        Mov     [PDI],EBX

        Mov     CL,[PSI]
        Inc     SI
        And     CL,0Fh
        ShL     CL,2

        Mov     EAX,[PCX]
        MovSX   EDX,AX                                                          ;EDX = Last sample
        Mov     [PDI+2],DX
        Add     PDI,4

    Dec     PBP
    JNZ     .Filter0
    Pop     PBP,PCX
    Ret

    ;[Delta]+[Smp-1](15/16) ------------------
    .Filter1:
        Mov     CL,[PSI]                                                        ;CL indexes delta value
        And     CL,0F0h                                                         ;PCX -> value
        ShR     CL,2

        UnpckFilter1
        UnpckClamp

        Mov     [PDI],EDX

        Mov     CL,[PSI]
        Inc     SI
        And     CL,0Fh
        ShL     CL,2

        UnpckFilter1
        UnpckClamp

        Mov     [PDI+2],DX
        Add     PDI,4

    Dec     PBP
    JNZ     .Filter1
    Pop     PBP,PCX
    Ret

    ;[Delta]+[Smp-1](61/32)-[Smp-2](15/16) ---
    .Filter2:
        Mov     CL,[PSI]
        And     CL,0F0h
        ShR     CL,2

        UnpckFilter2
        UnpckClamp

        Mov     [PDI],EDX

        Mov     CL,[PSI]
        Inc     SI
        And     CL,0Fh
        ShL     CL,2

        UnpckFilter2
        UnpckClamp

        Mov     [PDI+2],DX
        Add     PDI,4

    Dec     PBP
    JNZ     .Filter2
    Pop     PBP,PCX
    Ret

    ;[Delta]+[Smp-1](115/64)-[Smp-2](13/16) --
    .Filter3:
        Mov     CL,[PSI]
        And     CL,0F0h
        ShR     CL,2

        UnpckFilter3
        UnpckClamp

        Mov     [PDI],EDX

        Mov     CL,[PSI]
        Inc     SI
        And     CL,0Fh
        ShL     CL,2

        UnpckFilter3
        UnpckClamp

        Mov     [PDI+2],DX
        Add     PDI,4

    Dec     PBP
    JNZ     .Filter3
    Pop     PBP,PCX
    Ret


;===================================================================================================
;Decompress Sound Source (Old school method)

UnpckSrcOld:

    Push    PCX

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
    JZ      .Filter0

    Add     CL,10                                                               ;Values will be shifted right from 32-bit values
    Test    AL,08h
    JZ      .Filter1

    Test    AL,04h
    JZ      .Filter2

    Jmp     .Filter3

    ;[Delta] ---------------------------------
    .Filter0:
        XOr     EAX,EAX
        XOr     EDX,EDX
        Mov     AH,[PSI]
        Mov     DH,AH
        And     AH,0F0h
        ShL     DH,4

        SAR     AX,CL
        SAR     DX,CL
        Mov     [PDI],AX
        Mov     [PDI+2],DX
        Add     PDI,4

        Inc     SI

    Dec     CH
    JNZ     .Filter0
    MovSX   EDX,DX
    MovSX   EBX,AX
    Pop     PCX
    Ret

    ;[Delta]+[Smp-1](15/16) ------------------
    .Filter1:
        Mov     EBX,[PSI]
        And     BL,0F0h
        ShL     EBX,24
        SAR     EBX,CL

        Mov     EAX,EDX
        IMul    EAX,60
        Add     EBX,EAX
        SAR     EBX,6

        Mov     [PDI],EBX

        Mov     EDX,[PSI]
        ShL     EDX,28
        SAR     EDX,CL

        Mov     EAX,EBX
        IMul    EAX,60
        Add     EDX,EAX
        SAR     EDX,6

        Mov     [PDI+2],DX
        Add     PDI,4

        Inc     SI

    Dec     CH
    JNZ     .Filter1
    Pop     PCX
    Ret

    ;[Delta]+[Smp-1](61/32)-[Smp-2](30/32) ---
    .Filter2:
        Mov     EAX,[PSI]
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

        Mov     [PDI],EAX

        Mov     EDX,[PSI]
        ShL     EDX,28
        SAR     EDX,CL

        IMul    EBX,60
        Sub     EDX,EBX
        Mov     EBX,EAX

        IMul    EAX,122
        Add     EDX,EAX
        SAR     EDX,6

        Mov     [PDI+2],DX
        Add     PDI,4

        Inc     SI

    Dec     CH
    JNZ     .Filter2
    Pop     PCX
    Ret

    ;[Delta]+[Smp-1](115/64)-[Smp-2](52/64) --
    .Filter3:
        Mov     EAX,[PSI]
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

        Mov     [PDI],EAX

        Mov     EDX,[PSI]
        ShL     EDX,28
        SAR     EDX,CL

        IMul    EBX,52
        Sub     EDX,EBX
        Mov     EBX,EAX

        IMul    EAX,115
        Add     EDX,EAX
        SAR     EDX,6

        Mov     [PDI+2],DX
        Add     PDI,4

        Inc     SI

    Dec     CH
    JNZ     .Filter3
    Pop     PCX
    Ret
