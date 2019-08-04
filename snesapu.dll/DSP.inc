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
;                                                   Copyright (C) 2003-2019 degrade-factory
;===================================================================================================

%define DSP_INC

;===================================================================================================
;Equates

;Interpolation routines
INT_NON		EQU	0												;None
INT_LINEAR	EQU	1												;Linear
INT_CUBIC	EQU	2												;Cubic Spline
INT_GAUSS	EQU	3												;SNES Gaussian
; ----- degrade-factory code [2004/08/16] -----
INT_SINC	EQU	4												;8-point Sinc
INT_GAUSS4	EQU	7												;4-point Gaussian
; ----- degrade-factory code [END] -----

;DSP options
DSP_ANALOG	EQU	01h												;Simulate analog anomalies (low-pass filter)
DSP_OLDSMP	EQU	02h												;Traditional ADPCM routine
DSP_SURND	EQU	04h												;Surround sound
DSP_REVERSE	EQU	08h												;Reverse stereo samples
DSP_NOECHO	EQU	10h												;Disable echo (must not be bit 0 or 5, see disEcho)
; ----- degrade-factory code [2008/09/09] -----
DSP_NOPMOD	EQU	20h												;Disable pitch modulation
DSP_NOPREAD	EQU	40h												;Disable pitch read
DSP_NOFIR	EQU	80h												;Disable FIR Filter
DSP_BASS	EQU	100h											;BASS BOOST (low-pass filter)
DSP_NOENV	EQU	200h											;Disable envelope
DSP_NONOISE	EQU	400h											;Disable noise
DSP_ECHOMEM	EQU	800h											;Write DSP echo memory map
DSP_NOSURND	EQU	1000h											;Disable surround sound
DSP_FLOAT	EQU	40000000h										;32bit floating-point volume output
DSP_NOSAFE	EQU	80000000h										;Disable volume safe
; ----- degrade-factory code [END] -----

;PackWave options (unused)
BRR_LINEAR	EQU	01h												;Use linear compression for all blocks
BRR_LOO		EQU	02h												;Set loop flag in block header
BRR_NOINIT	EQU	04h												;Don't create an initial block of silence
BRR_8BIT	EQU 10h												;Input samples are 8-bit

;Mixing flags
MFLG_MUTE	EQU	01h												;Voice is muted (set by user)
MFLG_NOISE	EQU	02h												;Voice is noise (set by user)
MFLG_USER	EQU	03h												;Flags by user
MFLG_KOFF	EQU	04h												;Voice is in the process of keying off
MFLG_OFF	EQU	08h												;Voice is currently inactive
MFLG_END	EQU	10h												;End block was just played

; ----- degrade-factory code [2019/08/04] -----
;Script700 DSP flags
S700_MUTE	EQU	01h												;Mute voice
S700_CHANGE	EQU	02h												;Change sound source (note change)
S700_DETUNE	EQU	04h												;Detune sound pitch rate
S700_VOLUME	EQU	08h												;Change sound volume

;Script700 DSP master parameters
S700_MVOL_L	EQU	00h												;Master volume (left)
S700_MVOL_R	EQU	01h												;Master volume (right)
S700_ECHO_L	EQU	02h												;Echo volume (left)
S700_ECHO_R	EQU	03h												;Echo volume (right)

;DSP KON delay emulation time
KON_DELAY	EQU	19												;Delay time from writing KON to output (40Ts / 2 - 1)
KON_CHKKOFF	EQU	1												;Delay time from checking KOFF, if DSPBK is 1
KON_SAVEENV	EQU	KON_DELAY										;Delay time from writing save envelope to output
; ----- degrade-factory code [END] -----


;===================================================================================================
;Structures

;DSP registers ------------------------------
STRUC DSPVoice
	volL	resb	1											;Volume Left
	volR	resb	1											;Volume Right
	pitch	resw	1											;Pitch (Rate/32000) [3.11]
	srcn	resb	1											;Wave form being played back
	adsr	resw	1											;Envelope rates: attack, decay, and sustain
	gain	resb	1											;Envelope gain rate (if not using ADSR)
	envx	resb	1											;Current envelope height [.7]
	outx	resb	1											;Current sample being output [-.7]
			resb	2
ENDSTRUC

STRUC DSPRAM
	voice	resb	12											;Settings for voice 0
	mvolL	resb	1											;Main Volume Left [-.7]
	efb		resb	1											;Echo Feedback [-.7]
			resb	1
	fc		resb	1											;Filter Coefficient 0
	v2		resb	12
	mvolR	resb	1											;Main Volume Right [-.7]
			resb	3
	v3		resb	12
	evolL	resb	1											;Echo Volume Left [-.7]
	pmon	resb	1											;Pitch Modulation on/off for each voice
			resb	2
	v4		resb	12
	evolR	resb	1											;Echo Volume Right [-.7]
	non		resb	1											;Noise output on/off for each voice
			resb	2
	v5		resb	12
	kon		resb	1											;Key On for each voice
	eon		resb	1											;Echo on/off for each voice
			resb	2
	v6		resb	12
	kof		resb	1											;Key Off for each voice (instantiates release mode)
	dir		resb	1											;Page containing source directory (wave table offsets)
			resb	2
	v7		resb	12
	flg		resb	1											;DSP flags and noise frequency
	esa		resb	1											;Starting page used to store echo waveform
			resb	2
	v8		resb	12
	endx	resb	1											;Waveform has ended
	edl		resb	1											;Echo Delay in ms >> 4
			resb	2
ENDSTRUC

; ----- degrade-factory code [2009/03/11] -----
;Internal mixing settings -------------------
STRUC VoiceMix
	;Voice ------------08
	vAdsr	resw	1											;ADSR parameters when KON was written
	vGain	resb	1											;Gain parameters when KON was written
	vRsv	resb	1											;Changed ADSR/Gain parameters flag
	sIdx	resd	1											;-> current sample in sBuf
	;Waveform ---------06
	bCur	resd	1											;-> current block
	bHdr	resb	1											;Block Header for current block
	mFlg	resb	1											;Mixing flags
	;Envelope ---------22
	eMode	resb	1											;[3-0] Current envelope mode
																;[6-4] ADSR mode to switch into from Gain
																;[7]   Envelope is not changing
	eRIdx	resb	1											;Index in rateTab
	eRate	resd	1											;Rate of envelope adjustment [16.16]
	eCnt	resd	1											;Sample counter [16.16]
	eVal	resd	1											;Current envelope value
	eAdj	resd	1											;Amount to adjust envelope height
	eDest	resd	1											;Envelope Destination [16.16]
	;Visualization ----08
	vMaxL	resd	1											;Maximum absolute sample output
	vMaxR	resd	1
	;Samples ----------52
	sP1		resw	1											;Last sample decompressed (prev1)
	sP2		resw	1											;Second to last sample (prev2)
	sBufP	resw	8											;Last 8 samples from previous block
	sBuf	resw	16											;32 bytes for decompressed samples
	;Mixing -----------32
	mTgtL	resd	1											;Target volume
	mTgtR	resd	1											; "  "
	mChnL	resd	1											;Channel volume [-24.7]
	mChnR	resd	1											; "  "
	mRate	resd	1											;Pitch Rate after modulation [16.16]
	mDec	resw	1											;Pitch Decimal [.16] (used as delta for interpolation)
	mSrc	resb	1											;Current source number
	mKOn	resb	1											;Delay time from writing KON to output
	mOrgP	resd	1											;Original pitch rate converted from the DSP [16.16]
	mOut	resd	1											;Last sample output before chn vol (used for pitch mod)
ENDSTRUC
; ----- degrade-factory code [END] -----


;===================================================================================================
;Public Variables

PUBLIC	mix														;Mixing structures for each voice
PUBLIC	dsp														;1 page of DSP RAM
PUBLIC	vMMaxL													;Maximum absolute sample output
PUBLIC	vMMaxR
; ----- degrade-factory code [2016/08/20] -----
PUBLIC	envFlag													;Update envelope flags
PUBLIC	dspVarEP												;Endpoint of DSP.asm variables
; ----- degrade-factory code [END] -----


;===================================================================================================
;Exported Functions

; ----- degrade-factory code [2006/10/20] -----
;===================================================================================================
;Initialize DSP
;
;Creates the lookup tables for interpolation, and sets the default mixing settings:
;
;   mixType = 1
;   numChn  = 2
;   bits    = 16
;   rate    = 32000
;   inter   = INT_GAUSS
;   opts    = 0
;
;Destroys:
;   ST0-7

PUBLIC InitDSP, NULL
; ----- degrade-factory code [END] -----


;===================================================================================================
;Reset DSP
;
;Resets the DSP registers, erases internal variables, and resets the volume.
;
;Destroys:
;   EAX

PUBLIC ResetDSP, NULL


;===================================================================================================
;Set DSP Options
;
;Recalculates tables, changes the output sample rate, and sets up the mixing routine.
;
;Notes:
;   Range checking is performed on all parameters.  If a parameter does not match the required
;    range of values, the default value will be assumed.
;
;   -1 can be used for any paramater that should remain unchanged.
;
; In:
;   mixType = Mixing routine (default 1)
;   numChn  = Number of channels (1 or 2, default 2)
;   bits    = Sample size (8, 16, 24, 32, or -32 [IEEE 754], default 16)
;   rate    = Sample rate (8000-192000, default 32000)
;   inter   = Interpolation type (default INT_GAUSS)
;   opts    = See "DSP options" in the Equates section
;
;Destroys:
;   EAX

PUBLIC SetDSPOpt, mixType:dword, numChn:dword, bits:dword, rate:dword, inter:dword, opts:dword


;===================================================================================================
;Debug DSP
;
;Installs a vector that gets called each time a value is written to the DSP data register.
;The function is called with the C calling convention.
;
;Upon entrance to the function:
;   [ESP+4] = Current opcode (low word = PC)
;   [ESP+8] = YA
;
;Note:
;   DEBUG must be set to 1 in APU.Inc
;
;In:
;   pTrace-> debug function (a null pointer turns off the debug call)
;
;Out:
;   Previously installed vector

PUBLIC SetDSPDbg, pTrace:ptr


;===================================================================================================
;Fix DSP After Loading SPC file
;
;Initializes the internal mixer variables.
;
;Destroys:
;   EAX

PUBLIC FixDSP, NULL


;===================================================================================================
;Fix DSP After Seeking
;
;Puts all DSP voices in a key off state and erases echo region.
;
;In:
;   reset = True, Reset all voices
;           False, Only erase memory
;
;Destroys:
;   EAX

PUBLIC FixSeek, reset:byte


;===================================================================================================
;DSP Pitch Adjustment
;
;Adjusts the pitch of the DSP.
;
;In:
;   base = Base sample rate (32000 - Normal pitch, 32458 - Old SB cards, 32768 - Old ZSNES)
;
;Destroys:
;   EAX

PUBLIC SetDSPPitch, base:dword


;===================================================================================================
;Set DSP Amplification
;
;This value is applied to the output with the main volumes.
;
;In:
;   amp = Amplification level [-15.16] (1.0 = SNES, negative values act as 0)
;
;Destroys:
;   EAX

PUBLIC SetDSPAmp, amp:dword


;===================================================================================================
;Set DSP Volume
;
;This value attenuates the output and was implemented to allow songs to be faded out.  ResetDSP sets
;this value to 65536 (no attenuation).
;
;In:
;   vol = Volume [-1.16] (0.0 to 1.0, negative values act as 0)
;
;Destroys:
;   EAX

PUBLIC SetDSPVol, vol:dword
PUBLIC SetDSPLength, song:dword, fade:dword						;see SetAPULength in APU.Inc


;===================================================================================================
;Set Voice Stereo Separation
;
;Sets the amount to adjust the panning position of each voice.
;
;In:
;   sep = Separation [1.16]
;         1.0 - full separation (output is either left, center, or right)
;         0.5 - normal separation (output is unchanged)
;           0 - no separation (output is completely monaural)
;
;Destroys:
;   EAX

PUBLIC SetDSPStereo, sep:dword


;===================================================================================================
;Set Echo Feedback Crosstalk
;
;Sets the amount of crosstalk between the left and right channel during echo feedback.
;
;In:
;   leak = Crosstalk amount [-1.15]
;           1.0 - no crosstalk (SNES)
;             0 - full crosstalk (mono/center)
;          -1.0 - inverse crosstalk (L/R swapped)
;
;Destroys:
;   EAX

PUBLIC SetDSPEFBCT, leak:dword


;===================================================================================================
;DSP Data Port
;
;Writes a value to a specified DSP register and alters the DSP accordingly.  If the register write
;affects the output generated by the DSP, this function returns true.
;
;Note:
;   SetDSPReg does not call the debugging vector
;
;In:
;   reg = DSP Address
;   val = DSP Data
;
;Out:
;   EAX = True, if the DSP state was affected

PUBLIC SetDSPReg, reg:byte, val:byte
PUBLIC DSPIn, NULL												;Used internally by SPC700.Asm


;===================================================================================================
;Emulate DSP
;
;Emulates the DSP of the SNES.
;
;Notes:
;   If 'pBuf' is null, the routine MIX_NONE will be used
;   Range checking is performed on 'len'
;
;In:
;   pBuf-> Buffer to store output
;   len  = Length of buffer (in samples)
;
;Out:
;   EAX -> End of buffer
;
;Destroys:
;   ST0-ST7

PUBLIC EmuDSP, pBuf:ptr, len:dword
PUBLIC SetEmuDSP, pBuf:ptr, len:dword, rate:dword				;Used internally by APU.Asm
PUBLIC CatchUp													;Used internally by SPC700.Asm
