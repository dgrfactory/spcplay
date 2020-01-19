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
//  +++ ���̃\�[�X �R�[�h�� GPL �ł� +++
//
//  ���̃v���O�����̓t���[ �\�t�g�E�F�A�ł��B ���Ȃ��̓t���[ �\�t�g�E�F�A�c�̂ɂ���Ĕ��s
//  ����Ă��� GNU ��ʌ��O���p�����_�񏑂̃o�[�W���� 2�A�������͊�]�ł���΂���ȏ��
//  �o�[�W�����̂����A�����ꂩ�Œ�߂�ꂽ�����̉��ł��̃v���O�������Ĕz�z�A�������͉���
//  ���邱�Ƃ��ł��܂��B
//
//  ���̃v���O�����͖��ɗ����Ƃ����҂��Ĕz�z����Ă��܂����A�w ���̕ۏ؂�����܂��� �x�B
//  �܂�A�w ���i�� (�@�\���A���S���A�ϋv���ɗD��Ă��邩) �x��w �K���� (�������̖ړI��
//  ���܂��g�p�ł��邩) �x�َ̖��I�ȕۏ؂�������܂���B
//  �ڂ����� GNU ��ʌ��O���p�����_�� (GNU General Public License) ���������������B
//
//  ���Ȃ��͂��̃v���O�����ƈꏏ�� GNU ��ʌ��O���p�����_�񏑂̃R�s�[���󂯎�����͂��ł��B
//  �󂯎���Ă��Ȃ��ꍇ�́A�t���[ �\�t�g�E�F�A�c�̂�����񂹂Ă��������B
//  ���� : Free Software Foundation, Inc.
//         59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
//
//  �� GNU ��ʌ��O���p�����_�񏑃o�[�W���� 2 �̃h�L�������g�́A�t���� LICENSE �ɂ���܂��B
//
//
//  Copyright (C) 2003-2019 degrade-factory. All rights reserved.
//
// =================================================================================================
program spcplay;

//{$DEFINE TIMERTRICK}                                      // TimerTrick DEBUG             : OFF (���߂��O���� ON)
//{$DEFINE TRY700A}                                         // Try700 (Ansi) DEBUG          : OFF (���߂��O���� ON)
//{$DEFINE TRY700W}                                         // Try700 (Wide) DEBUG          : OFF (���߂��O���� ON)
//{$DEFINE TRANSMITSPC}                                     // TransmitSPC DEBUG            : OFF (���߂��O���� ON)
//{$DEFINE CONTEXT}                                         // SNESAPU Context DEBUG        : OFF (���߂��O���� ON)
//{$DEFINE SPCDEBUG}                                        // SNESAPU SPCDbug DEBUG        : OFF (���߂��O���� ON)
//{$DEFINE DEBUGLOG}                                        // �f�o�b�O ���O�o��            : OFF (���߂��O���� ON)
//{$DEFINE UACDROP}                                         // UAC �𒴂����h���b�v����     : OFF (���߂��O���� ON)
//{$DEFINE ITASKBARLIST3}                                   // ITaskbarList3 �Ή�           : OFF (���߂��O���� ON)

{$APPTYPE GUI}                                              // �A�v���P�[�V���� �^�C�v      : GUI ���[�h
{$ASSERTIONS OFF}                                           // �\�[�X �R�[�h�̃A�T�[�g      : ����
{$BOOLEVAL OFF}                                             // ���S�_�����]��               : ����
{$DEBUGINFO OFF}                                            // �f�o�b�O���                 : ����
{$DEFINITIONINFO OFF}                                       // �V���{���錾�ƎQ�Ə��       : ����
{$DENYPACKAGEUNIT OFF}                                      // UNIT �g�p                    : ����
{$DESIGNONLY OFF}                                           // IDE �g�p                     : ����
{$EXTENDEDSYNTAX ON}                                        // �֐��̖߂�l�𖳎��\       : �L��
{$EXTENSION exe}                                            // �g���q�ݒ�                   : EXE
{$HINTS ON}                                                 // �q���g����                   : �L��
{$IMAGEBASE $00400000}                                      // �C���[�W �x�[�X �A�h���X     : 0x00400000
{$IMPLICITBUILD ON}                                         // �r���h�̂��тɍăR���p�C��   : �L��
{$IMPORTEDDATA OFF}                                         // �ʃp�b�P�[�W�̃������Q��     : ����
{$IOCHECKS OFF}                                             // I/O �`�F�b�N                 : ����
{$LOCALSYMBOLS OFF}                                         // ���[�J�� �V���{�����        : ����
{$LONGSTRINGS ON}                                           // AnsiString �g�p              : �L��
{$MAXSTACKSIZE $00100000}                                   // �ő�X�^�b�N�ݒ�             : 0x00100000
{$MINENUMSIZE 1}                                            // �񋓌^�̍ő�T�C�Y (x256)    : 1 (256)
{$MINSTACKSIZE $00004000}                                   // �ŏ��X�^�b�N�ݒ�             : 0x00004000
{$OBJEXPORTALL OFF}                                         // �V���{���̃G�N�X�|�[�g       : ����
{$OPENSTRINGS OFF}                                          // �I�[�v��������p�����[�^     : ����
{$OPTIMIZATION ON}                                          // �œK���R���p�C��             : �L��
{$OVERFLOWCHECKS OFF}                                       // �I�[�o�[�t���[ �`�F�b�N      : ����
{$RANGECHECKS OFF}                                          // �͈̓`�F�b�N                 : ����
{$REALCOMPATIBILITY OFF}                                    // Real48 �݊�                  : ����
{$REFERENCEINFO OFF}                                        // ���S�ȎQ�Ə��̐���         : ����
{$R 'spcplay.res' 'spcplay.rc'}                             // ���\�[�X                     : spcplay.res <- spcplay.rc
{$RUNONLY OFF}                                              // ���s���̂݃R���p�C��         : ����
{$SAFEDIVIDE OFF}                                           // ���� Pentium FDIV �o�O���   : ����
{$STACKFRAMES OFF}                                          // ���S�X�^�b�N �t���[������    : ����
{$TYPEDADDRESS OFF}                                         // �|�C���^�̌^�`�F�b�N         : ����
{$TYPEINFO OFF}                                             // ���s���^���                 : ����
{$VARSTRINGCHECKS OFF}                                      // ������`�F�b�N               : ����
{$WARNINGS ON}                                              // �x������                     : �L��
{$WEAKPACKAGEUNIT OFF}                                      // �ア�p�b�P�[�W��             : ����
{$WRITEABLECONST OFF}                                       // �萔��������                 : ����


// *************************************************************************************************************************************************************
// �O���N���X�̐錾
// *************************************************************************************************************************************************************

//uses MemCheck in '..\..\memcheck\MemCheck.pas';


// *************************************************************************************************************************************************************
// �\���́A����уN���X�̐錾
// *************************************************************************************************************************************************************

type
{$ALIGN OFF} // �\���̂̎����T�C�Y�����Ȃ� --- ��������
    TSPCREG = record                                        // SPC700 ���W�X�^
        pc: word;                                               // PC ���W�X�^
        a: byte;                                                // A ���W�X�^
        x: byte;                                                // X ���W�X�^
        y: byte;                                                // Y ���W�X�^
        psw: byte;                                              // PSW ���W�X�^
        sp: byte;                                               // SP ���W�X�^
    end;

    // SPCHDR �\����
    TSPCHDR = record
        FileHdr: array[0..32] of char;                      // �t�@�C�� �w�b�_
        TagTarm: array[0..1] of byte;                       // �w�b�_�ƃ^�O�̕����̈� (0x00, 0x1A)
        TagType: byte;                                      // �^�O�̎�� (0x00 = ����`, 0x1A = ID666, 0x1B = ID666 �ȊO)
        Version: byte;                                      // SPC �o�[�W����
        Reg: TSPCREG;                                       // SPC700 ���W�X�^�̏����l
        __r1: word;                                         // (���g�p) = 0x00
        Title: array[0..31] of char;                        // �Ȗ�
        Game: array[0..31] of char;                         // �Q�[����
        Dumper: array[0..15] of char;                       // SPC �����
        Comment: array[0..31] of char;                      // �R�����g
        Date: array[0..10] of char;                         // SPC �����
        SongLen: array[0..2] of char;                       // ���t����
        FadeLen: array[0..4] of char;                       // �t�F�[�h�A�E�g����
        Artist: array[0..31] of char;                       // ��Ȏ�
        ChDis: byte;                                        // �`�����l�� �}�X�N�������
        Emulator: byte;                                     // �o�͌��G�~�����[�^
        __r2: array[0..35] of byte;                         // (���g�p) = 0x00
        dwSongLen: longword;                                // (���g�p) - ���t����
        dwFadeLen: longword;                                // (���g�p) - �t�F�[�h�A�E�g����
        TagFormat: byte;                                    // (���g�p) - �^�O �t�H�[�}�b�g
    end;

    // SPCHDRBIN �\����
    TSPCHDRBIN = record
        __r1: array[0..157] of byte;                        // (�\��) - SPCHDR
        DateDay: byte;                                      // SPC ����� (��)
        DateMonth: byte;                                    // SPC ����� (��)
        DateYear: word;                                     // SPC ����� (�N)
        __r2: array[0..6] of byte;                          // (���g�p) = 0x00
        SongLen: word;                                      // ���t����
        __r3: byte;                                         // (���g�p) = 0x00
        FadeLen: longword;                                  // �t�F�[�h�A�E�g����
        Artist: array[0..31] of char;                       // ��Ȏ�
        ChDis: byte;                                        // �`�����l�� �}�X�N�������
        Emulator: byte;                                     // �o�͌��G�~�����[�^
        __r4: byte;                                         // (���g�p) = 0x00
        __r5: array[0..44] of byte;                         // (�\��) - SPCHDR
    end;

    // SPC �\����
    TSPC = record
        Hdr: TSPCHDR;                                       // SPC �t�@�C�� �w�b�_
        Ram: array[0..65535] of byte;                       // SPC700 64KB RAM
        Dsp: array[0..127] of byte;                         // DSP ���W�X�^
        __r: array[0..63] of byte;                          // (���g�p) = 0x00 or �g�� RAM
        XRam: array[0..63] of byte;                         // SPC700 �g�� RAM
    end;
{$ALIGN ON}  // �\���̂̎����T�C�Y�����Ȃ� --- �����܂�

    // RAM �\����
    TRAM = record case byte of
        1: (Ram: array[0..65535] of byte);                  // RAM
        2: (__r1: array[0..$F3] of byte;                    // (�\��)
            dwPort: longword;                               // APU �|�[�g (32 �r�b�g)
            __r2: array[$F8..$FFFF] of byte);               // (�\��)
    end;

    // XRAM �\����
    TXRAM = record
        XRam: array[0..63] of byte;                         // XRAM
    end;

    // SPCPORT �\����
    TSPCPORT = record case byte of
        1: (Port: array[0..3] of byte);                     // �e�|�[�g
        2: (dwPort: longword);                              // �|�[�g (32 �r�b�g)
    end;

    // SPCSRCADDRS �\����
    TSPCSRCADDRS = record
        Src: array[0..255] of record
            wStart: word;                                   // �J�n�A�h���X
            wLoop: word;                                    // ���[�v �A�h���X
        end;
    end;

    // SPC700REG �\����
    TSPC700REG = record case byte of
        1: (psw: array[0..7] of longword;                   // PSW ���W�X�^ (0x100 �Ń}�X�N)
            pc: longword;                                   // PC ���W�X�^ (���� 16 �r�b�g)
            ya: longword;                                   // Y, A ���W�X�^ (Y : ��� 8 �r�b�g�A A : ���� 8 �r�b�g)
            sp: longword;                                   // SP ���W�X�^ (���� 8 �r�b�g)
            x: longword);                                   // X ���W�X�^ (���� 8 �r�b�g)
        2: (Word: array[0..23] of word);
        3: (Byte: array[0..47] of byte);
    end;

    // DSPVOICE �\����
    TDSPVOICE = record
        VolumeLeft: byte;                                   // �o�̓��x�� (��)
        VolumeRight: byte;                                  // �o�̓��x�� (�E)
        Pitch: word;                                        // �s�b�` (���� 14 �r�b�g)
        SoundSourcePlayBack: byte;                          // �g�`�ԍ�
        EnvelopeADSR1: byte;                                // �G���x���[�v�̎�� (��� 1 �r�b�g) �� ADSR �G���x���[�v�̐ݒ� (DR : 3 �r�b�g�AAR : 4 �r�b�g)
        EnvelopeADSR2: byte;                                // �G���x���[�v�̐ݒ� (SL : 3 �r�b�g�ASR : 5 �r�b�g)
        EnvelopeGain: byte;                                 // Gain �G���x���[�v�̐ݒ� (��� 3 �r�b�g)
        CurrentEnvelope: byte;                              // ���݂̃G���x���[�v�l
        CurrentOutput: byte;                                // ���݂̔g�`�o�͒l
        __r: array[0..4] of byte;                           // (�\��) = DSPREG �\����
        Fir: byte;                                          // FIR �t�B���^�W��
    end;

    // DSPREG �\����
    TDSPREG = record case byte of
        1: (Voice: array[0..7] of TDSPVOICE);               // �{�C�X ���W�X�^ (DSPVOICE x8)
        2: (__r00: array[0..11] of byte;                    // (�\��) = DSPVOICE
            MainVolumeLeft: byte;                           // �}�X�^�[���� (��)
            EchoFeedback: byte;                             // �G�R�[ �t�B�[�h�o�b�N�̋���
            __r0E: byte;                                    // (���g�p)
            __r0F: byte;                                    // (�\��) = DSPVOICE
            __r10: array[0..11] of byte;                    // (�\��) = DSPVOICE
            MainVolumeRight: byte;                          // �}�X�^�[���� (�E)
            __r1D: byte;                                    // (���g�p)
            __r1E: byte;                                    // (���g�p)
            __r1F: byte;                                    // (�\��) = DSPVOICE
            __r20: array[0..11] of byte;                    // (�\��) = DSPVOICE
            EchoVolumeLeft: byte;                           // �G�R�[���� (��)
            PitchModOn: byte;                               // �e�`�����l���̃s�b�` ���W�����[�V���� �I�� �t���O (8 �r�b�g)
            __r2E: byte;                                    // (���g�p)
            __r2F: byte;                                    // (�\��) = DSPVOICE
            __r30: array[0..11] of byte;                    // (�\��) = DSPVOICE
            EchoVolumeRight: byte;                          // �G�R�[���� (�E)
            NoiseOn: byte;                                  // �e�`�����l���̃m�C�Y �I�� �t���O (8 �r�b�g)
            __r3E: byte;                                    // (���g�p)
            __r3F: byte;                                    // (�\��) = DSPVOICE
            __r40: array[0..11] of byte;                    // (�\��) = DSPVOICE
            KeyOn: byte;                                    // �e�`�����l���̃L�[ �I�� �t���O (8 �r�b�g)
            EchoOn: byte;                                   // �e�`�����l���̃G�R�[ �I�� �t���O (8 �r�b�g)
            __r4E: byte;                                    // (���g�p)
            __r4F: byte;                                    // (�\��) = DSPVOICE
            __r50: array[0..11] of byte;                    // (�\��) = DSPVOICE
            KeyOff: byte;                                   // �e�`�����l���̃L�[ �I�t �t���O (8 �r�b�g)
            SourceDirectory: byte;                          // �\�[�X �f�B���N�g�� (�g�`��񂪊i�[����Ă��郁�����̃I�t�Z�b�g �A�h���X x0x100)
            __r5E: byte;                                    // (���g�p)
            __r5F: byte;                                    // (�\��) = DSPVOICE
            __r60: array[0..11] of byte;                    // (�\��) = DSPVOICE
            Flags: byte;                                    // DSP ���Z�b�g�A�o�͖����A�G�R�[�����t���O (��� 3 �r�b�g) �ƃm�C�Y���g�� (���� 5 �r�b�g)
            EchoWaveform: byte;                             // �G�R�[�L���̈� (�G�R�[�����Ɏg�p���郁�����̃I�t�Z�b�g �A�h���X x0x100)
            __r6E: byte;                                    // (���g�p)
            __r6F: byte;                                    // (�\��) = DSPVOICE
            __r70: array[0..11] of byte;                    // (�\��) = DSPVOICE
            EndWaveform: byte;                              // �e�`�����l���̔g�`�t�H�[���̏I���_�ʉ߃t���O (8 �r�b�g)
            EchoDelay: byte;                                // �G�R�[ �f�B���C���� (x16 [ms])
            __r7E: byte;                                    // (���g�p)
            __r7F: byte);                                   // (�\��) = DSPVOICE
        3: (Reg: array[0..127] of byte);                    // DSP ���W�X�^
    end;

    // VOICE �\����
    TVOICE = record
        KOnADSR: word;                                      // KON ���� ADSR �p�����[�^
        KOnGain: byte;                                      // KON ���� Gain �p�����[�^
        ResetEnv: byte;                                     // KON ��� ADSR/Gain �ύX�t���O
        CurrentSample: ^word;                               // �J�����g �T���v���̃|�C���^
        CurrentBlock: pointer;                              // �J�����g �u���b�N�̃|�C���^
        BlockHdr: byte;                                     // �J�����g �u���b�N�̃w�b�_
        MixFlag: byte;                                      // �~�L�V���O �I�v�V���� (���� 2 �r�b�g�Ń~���[�g�E�����m�C�Y�ݒ�A��� 6 �r�b�g�͗\��)
        EnvelopeCurrentMode: byte;                          // �G���x���[�v�̓��샂�[�h
        EnvelopeRateTab: byte;                              // �G���x���[�v ���[�g �^�u�̃C���f�b�N�X
        EnvelopeRate: longword;                             // �G���x���[�v ���[�g�̒���
        SampleCounter: longword;                            // �T���v�� �J�E���^
        EnvelopeRateValue: longword;                        // ���݂̃G���x���[�v�l
        EnvelopeAdjust: longword;                           // �G���x���[�v�̍���
        EnvelopeDestination: longword;                      // �G���x���[�v�̍ŏI�l
        VolumeMaxLeft: single;                              // �ő�o�̓��x�� (��)
        VolumeMaxRight: single;                             // �ő�o�̓��x�� (�E)
        LastSample1: word;                                  // �Ō�̃T���v�� 1
        LastSample2: word;                                  // �Ō�̃T���v�� 2
        LastSampleBlock: array[0..7] of word;               // �Ō�̃T���v�� x8 (��ԏ����Ŏg�p)
        Buffer: array[0..15] of word;                       // 32 �o�C�g �f�[�^ (�T���v�� �u���b�N�𓀂Ŏg�p)
        TargetVolumeLeft: single;                           // �ŏI�I�ȃ`�����l������ (��)
        TargetVolumeRight: single;                          // �ŏI�I�ȃ`�����l������ (�E)
        ChannelVolumeLeft: longword;                        // ���݂̃`�����l������ (��) (�N���b�N �m�C�Y�h�~�@�\�Ŏg�p)
        ChannelVolumeRight: longword;                       // ���݂̃`�����l������ (�E) (�N���b�N �m�C�Y�h�~�@�\�Ŏg�p)
        PitchRate: longword;                                // ���W�����[�V������̃s�b�` ���[�g
        PitchRateDecimal: word;                             // ���W�����[�V������̃s�b�` ���[�g (����)
        CurrentSource: byte;                                // �J�����g���F�ԍ�
        StartDelay: byte;                                   // KON ���甭���܂ł̒x������ (64kHz)
        PitchRateDSP: longword;                             // DSP �ŃR���o�[�g���ꂽ�I���W�i�� �s�b�` ���[�g
        SampleOutput: longword;                             // �`�����l�����ʂɈˑ����Ȃ��Ō�̃T���v�� (�s�b�` ���W�����[�V�����Ŏg�p)
    end;

    // VOICES �\����
    TVOICES = record
        Voice: array[0..7] of TVOICE;                       // DSP �{�C�X ���W�X�^
    end;

    // APU �\����
    TAPU = record
        hDLL: longword;                                     // SNESAPU.DLL �n���h��
        Ram: ^TRAM;                                         // SPC700 RAM �̃|�C���^ (65536 �o�C�g)
        XRam: ^TXRAM;                                       // SPC700 �g�� RAM �̃|�C���^ (64 �o�C�g)
        SPCOutPort: ^TSPCPORT;                              // SPC700 �o�̓|�[�g�̃|�C���^
        T64Count: ^longword;                                // 64kHz �^�C�} �J�E���^�̃|�C���^ (64000 count/sec)
        DspReg: ^TDSPREG;                                   // DSP ���W�X�^�̃|�C���^ (128 �o�C�g)
        Voices: ^TVOICES;                                   // DSP �~�L�V���O �f�[�^�̃|�C���^ (TVOICE x8)
        VolumeMaxLeft: ^single;                             // �~�L�V���O�ő�o�̓��x�� (��) �̃|�C���^
        VolumeMaxRight: ^single;                            // �~�L�V���O�ő�o�̓��x�� (�E) �̃|�C���^
        SPC700Reg: ^TSPC700REG;                             // SPC700 ���W�X�^�̃|�C���^
        EmuAPU: function(buffer: pointer; length: longword; ltype: byte): pointer; stdcall;
        GetAPUData: procedure(ppRam: pointer; ppXRam: pointer; ppSPCOutput: pointer; ppT64Count: pointer; ppDsp: pointer; ppVoices: pointer; ppVolumeMaxLeft: pointer; ppVolumeMaxRight: pointer); stdcall;
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
    end;

    // SCRIPT700 �\����
    TSCRIPT700 = record
        dwWork: array[0..7] of longword;                    // ���[�U ���[�N �G���A
        dwCmpParam: array[0..1] of longword;                // �R���y�A �p�����[�^ �G���A
        dwWaitCnt: longword;                                // �E�F�C�g �J�E���g
        dwPointer: longword;                                // �v���O���� �|�C���^
        dwStackFlag: longword;                              // �X�^�b�N �t���O
        dwData: longword;                                   // �f�[�^ �G���A �I�t�Z�b�g �A�h���X
        dwStack: longword;                                  // �X�^�b�N �|�C���^
    end;

    // SCRIPT700DATA �\����
    TSCRIPT700DATA = record
        Data: ^TSCRIPT700;                                  // �f�[�^
        dwProgSize: longword;                               // �v���O���� �T�C�Y
    end;

    // SCRIPT700EX �\����
    TSCRIPT700EX = record
        Base: TSCRIPT700;                                   // ��{�f�[�^
        dwJump: longword;                                   // �W�����v��A�h���X
        dwTemp: longword;                                   // �ꎞ�i�[�p
        Stack: array[0..127] of longword;                   // �X�^�b�N ������
    end;

    // APUDATA �\����
    TAPUDATA = record
        SPCApuPort: TSPCPORT;                               // SPC700 ���̓|�[�g
        SPCOutPort: TSPCPORT;                               // SPC700 �o�̓|�[�g
        SPCSrcAddrs: TSPCSRCADDRS;                          // SPC700 ���F�A�h���X
        SPC700Reg: TSPC700REG;                              // SPC700 ���W�X�^
        T64Count: longword;                                 // 64kHz �^�C�} �J�E���^
        DspReg: TDSPREG;                                    // DSP ���W�X�^
        Voices: TVOICES;                                    // DSP �~�L�V���O �f�[�^
        VolumeMaxLeft: single;                              // �~�L�V���O�ő�o�̓��x�� (��)
        VolumeMaxRight: single;                             // �~�L�V���O�ő�o�̓��x�� (�E)
        Script700: TSCRIPT700;                              // Script700 �f�[�^
    end;

    // SPCCACHE �\����
    TSPCCACHE = record
        Spc: TSPC;                                          // SPC �t�@�C�� �o�b�t�@
        Script700: TSCRIPT700EX;                            // Script700 ���S�o�b�t�@
        SPCOutPort: TSPCPORT;                               // SPC700 �o�̓|�[�g
    end;

    // LEVEL �\����
    TLEVEL = record
        cMasterVolumeLeft: byte;                            // �}�X�^�[���� (��)
        cMasterVolumeRight: byte;                           // �}�X�^�[���� (�E)
        cMasterEchoLeft: byte;                              // �}�X�^�[ �G�R�[ (��)
        cMasterEchoRight: byte;                             // �}�X�^�[ �G�R�[ (�E)
        cMasterDelay: byte;                                 // �}�X�^�[ �f�B���C
        cMasterFeedback: byte;                              // �}�X�^�[ �t�B�[�h�o�b�N
        cMasterLevelLeft: byte;                             // �}�X�^�[�o�̓��x�� (��)
        cMasterLevelRight: byte;                            // �}�X�^�[�o�̓��x�� (�E)
        Channel: array[0..7] of record                      // �`�����l��
            bChannelShow: bytebool;                             // �`�����l���\��
            cChannelVolumeLeft: byte;                           // �`�����l������ (��)
            cChannelVolumeRight: byte;                          // �`�����l������ (�E)
            cChannelPitch: byte;                                // �`�����l�� �s�b�`
            cChannelEnvelope: byte;                             // �`�����l�� �G���x���[�v
            cChannelLevelLeft: byte;                            // �`�����l���o�̓��x�� (��)
            cChannelLevelRight: byte;                           // �`�����l���o�̓��x�� (�E)
            __r: byte;                                          // (���g�p)
            dwChannelEffect: record case byte of                // �`�����l�� �G�t�F�N�g
                1: (EchoOn: bytebool;                               // �G�R�[ �t���O
                    PitchModOn: bytebool;                           // �s�b�` ���W�����[�V���� �t���O
                    NoiseOn: bytebool;                              // �m�C�Y �t���O
                    Update: bytebool);                              // �X�V�t���O
                2: (dwValue: longword);                             // �t���O (32 �r�b�g)
            end;
        end;
    end;

    // STRDATA �\����
    TSTRDATA = record case byte of
        1: (cData: array[0..7] of char);                    // 1 ���� x8
        2: (bData: array[0..7] of byte);                    // 8 �r�b�g x8
        3: (wData: array[0..3] of word);                    // 16 �r�b�g x4
        4: (dwData: array[0..1] of longword);               // 32 �r�b�g x2
        5: (qwData: int64);                                 // 64 �r�b�g
    end;

    // CRITICALSECTION �\����
    TCRITICALSECTION = record
        lpDebugInfo: pointer;                               // �f�o�b�O���̃|�C���^
        dwLockCount: longword;                              // ���b�N��
        dwRecursionCount: longword;                         // �ċA��
        hOwningThread: longword;                            // �X���b�h �n���h��
        hLockSemaphore: longword;                           // ���b�N�M���n���h��
        dwSpinCount: longword;                              // �ҋ@��
    end;

    // DBLPOINTER �\����
    TDBLPOINTER = record
        p: pointer;                                         // �|�C���^
    end;

    // GUID �\����
    TGUID = record case byte of
        1: (data1: longword;                                // 1
            data2: word;                                    // 2
            Data3: word;                                    // 3
            Data4: array[0..7] of byte);                    // 4
        2: (DataX: array[0..3] of longword);                // �l (128 �r�b�g)
    end;

    // LONGLONG �\����
    TLONGLONG = record
        l: longword;                                        // ���� 32 �r�b�g
        h: longword;                                        // ��� 32 �r�b�g
    end;

    // POINT �\����
    TPOINT = record
        x: longint;                                         // X ���W
        y: longint;                                         // Y ���W
    end;

    // RECT �\����
    TRECT = record
        left: longint;                                      // ��
        top: longint;                                       // ��
        right: longint;                                     // �E
        bottom: longint;                                    // ��
    end;

    // BOX �\����
    TBOX = record
        left: longint;                                      // ��
        top: longint;                                       // ��
        width: longint;                                     // ��
        height: longint;                                    // ����
    end;

    // KEYSTATE �\����
    TKEYSTATE = record
        k: array[0..255] of byte;                           // �L�[�̏��
    end;

    // MONITORINFO �\����
    TMONITORINFO = record
        cdSize: longword;                                   // �\���̂̃T�C�Y
        rcMonitor: TRECT;                                   // ���j�^�S�̂̃T�C�Y
        rcWork: TRECT;                                      // ��Ɨ̈�̃T�C�Y
        dwFlags: longword;                                  // �t���O
    end;

    // MSG �\����
    TMSG = record
        hWnd: longword;                                     // �E�B���h�E �n���h��
        msg: longword;                                      // ���b�Z�[�W
        wParam: longword;                                   // ���b�Z�[�W�ǉ���� 1
        lParam: longword;                                   // ���b�Z�[�W�ǉ���� 2
        dwTime: longword;                                   // ���b�Z�[�W���M����
        pt: TPOINT;                                         // ���b�Z�[�W�������W (POINT �\����)
    end;

    // OPENFILENAME �\����
    TOPENFILENAME = record
        lStructSize: longword;                              // �\���̂̃T�C�Y
        hwndOwner: longword;                                // �E�B���h�E �n���h��
        hThisInstance: longword;                            // �C���X�^���X �n���h��
        lpstrFilter: pointer;                               // �t�B���^
        lpstrCustomFilter: pointer;                         // �J�X�^�� �t�B���^
        nMaxCustFilter: longword;                           // �t�B���^�̍ő�l
        nFilterIndex: longword;                             // �t�B���^�̑I��l
        lpstrFile: pointer;                                 // �t�@�C����
        nMaxFile: longword;                                 // �ő�t�@�C��
        lpstrFileTitle: pointer;                            // �t�@�C�� �^�C�g��
        nMaxFileTitle: longword;                            // �ő�t�@�C�� �^�C�g��
        lpstrInitialDir: pointer;                           // �����t�H���_
        lpstrTitle: pointer;                                // �^�C�g��
        Flags: longword;                                    // �t���O
        nFileOffset: word;                                  // �t�@�C�� �I�t�Z�b�g
        nFileExtension: word;                               // �t�@�C���g��
        lpstrDefExt: pointer;                               // �f�t�H���g�g��
        lCustData: longword;                                // �J�X�^�� �f�[�^
        lpfnHook: pointer;                                  // �t�b�N
        lpTemplateName: pointer;                            // �e���v���[�g��
    end;

    // OSVERSIONINFO �\����
    TOSVERSIONINFO = record
        dwOSVersionInfoSize: longword;                      // �\���̂̃T�C�Y
        dwMajorVersion: longword;                           // ���W���[ �o�[�W����
        dwMinorVersion: longword;                           // �}�C�i�[ �o�[�W����
        dwBuildNumber: longword;                            // �r���h �i���o�[
        dwPlatformId: longword;                             // �v���b�g�t�H�[�� ID
        szCSDVersion: array[0..127] of char;                // �ǉ����
    end;

    // REFCOLOR �\����
    TREFCOLOR = record case byte of
        1: (r: byte;                                        // ��
            g: byte;                                        // ��
            b: byte;                                        // ��
            a: byte);                                       // �A���t�@
        2: (dwColor: longword);                             // �F�ԍ�
    end;

    // WAVEFORMATEXTENSIBLE �\����
    TWAVEFORMATEXTENSIBLE = record
        wFormatTag: word;                                   // �t�H�[�}�b�g �^�O
        nChannels: word;                                    // �`�����l��
        nSamplesPerSec: longword;                           // �T���v�����O ���[�g
        nAvgBytesPerSec: longword;                          // 1 �b������̃o�C�g��
        nBlockAlign: word;                                  // �u���b�N�P�ʂ̃o�C�g��
        wBitsPerSample: word;                               // 1 �T���v��������̃r�b�g��
        cbSize: word;                                       // �ǉ����̃T�C�Y
        wValidBitsPerSample: word;                          // 1 �T���v��������̃r�b�g��
        dwChannelMask: longword;                            // �`�����l�� �}�X�N
        SubFormat: TGUID;                                   // �T�u �t�H�[�}�b�g
    end;

    // WAVEHDR �\����
    TWAVEHDR = record
        lpData: pointer;                                    // �o�b�t�@�̃|�C���^
        dwBufferLength: longword;                           // �o�b�t�@�̃T�C�Y
        dwBytesRecorded: longword;                          // �^���ς݂̃T�C�Y
        dwUser: longword;                                   // ���[�U �f�[�^
        dwFlags: longword;                                  // �t���O
        dwLoops: longword;                                  // ���[�v��
        __lpNext: pointer;                                  // (�\��)
        __reserved: longword;                               // (�\��)
    end;

    // WAVEOUTCAPS �\����
    TWAVEOUTCAPS = record
        wMid: word;                                         // �������ԍ�
        wPid: word;                                         // ���i�ԍ�
        vDriverVersion: record                              // �o�[�W����
            wMinor: byte;                                       // �}�C�i�[ �o�[�W����
            wMajor: byte;                                       // ���W���[ �o�[�W����
            __r: word;                                          // (�\��)
        end;
        szPname: array[0..31] of char;                      // �f�o�C�X��
        dwFormats: longword;                                // �T�|�[�g����Ă���t�H�[�}�b�g
        wChannels: word;                                    // �T�|�[�g����Ă���`�����l��
        __wReserved1: word;                                 // (�\��)
        dwSupport: longword;                                // �T�|�[�g����Ă���R���g���[��
    end;

    // WIN32FINDDATA �\����
    TWIN32FINDDATA = record
        dwFileAttributes: longword;                         // ����
        ftCreateTime: TLONGLONG;                            // �쐬����
        ftLastAccessTime: TLONGLONG;                        // �ŏI�A�N�Z�X����
        ftLastWriteTime: TLONGLONG;                         // �ŏI�X�V����
        dwFileSizeHigh: longword;                           // �t�@�C�� �T�C�Y (���)
        dwFileSizeLow: longword;                            // �t�@�C�� �T�C�Y (����)
        dwReserved0: longword;                              // (�\��)
        dwReserved1: longword;                              // (�\��)
        cFileName: array[0..259] of char;                   // �����t�@�C����
        cAlternateFileName: array[0..13] of char;           // �Z���t�@�C����
    end;

    // WINDOWPLACEMENT �\����
    TWINDOWPLACEMENT = record
        length: longword;                                   // �\���̃T�C�Y
        flags: longword;                                    // �t���O
        showCmd: longword;                                  // �\���X�^�C��
        ptMinPosition: TPOINT;                              // �ŏ������W
        ptMaxPosition: TPOINT;                              // �ő剻���W
        rcNormalPosition: TRECT;                            // �ʏ���W
    end;

    // WNDCLASSEX �\����
    TWNDCLASSEX = record
        cdSize: longword;                                   // �\���̃T�C�Y
        style: longword;                                    // �N���X �X�^�C��
        lpfnwndproc: pointer;                               // WindowProc �֐��̃|�C���^
        cbClsextra: longint;                                // �E�B���h�E �N���X������
        cbWndExtra: longint;                                // �E�B���h�E �C���X�^���X������
        hThisInstance: longword;                            // �C���X�^���X �n���h��
        hIcon: longword;                                    // 32x32 �A�C�R�� �n���h��
        hCursor: longword;                                  // �J�[�\�� �n���h��
        hbrBackground: longword;                            // �w�i�F�n���h�� (+1)
        lpszMenuName: pointer;                              // �f�t�H���g ���j���[�̃|�C���^
        lpszClassName: pointer;                             // �N���X���̃|�C���^
        hIconSm: longword;                                  // 16x16 �A�C�R�� �n���h��
    end;

    // DROPFILES �\����
    TDROPFILES = record
        pFiles: longword;                                   // �t�@�C���ꗗ�̊J�n�C���f�b�N�X
        pt: TPOINT;                                         // �}�E�X���W
        fNC: longbool;                                      // ��N���C�A���g�̈�t���O
        fWide: longbool;                                    // UNICODE (Win9x: false, WinNT: true �K�{)
    end;

    // FORMATETC �\����
    TFORMATETC = record
        cfFormat: word;                                     // �N���b�v�{�[�h �t�H�[�}�b�g�`��
        ptd: pointer;                                       // �Ώۃf�o�C�X���
        dwAspect: longword;                                 // �\���Ɋ܂܂��K�v������ڍ׏��
        lindex: longint;                                    // �f�[�^���y�[�W���E���z���ĕ��������K�v������ꍇ�̓���
        tymed: longword;                                    // �f�[�^�]���Ɏg�p����X�g���[�W�̎��
    end;

    // STGMEDIUM �\����
    TSTGMEDIUM = record
        tymed: longword;                                    // �f�[�^�]���Ɏg�p����X�g���[�W�̎��
        handle: longword;                                   // �f�[�^�̃n���h��
        pUnkForRelease: pointer;                            // �X�g���[�W������ɃR�[������C���^�[�t�F�C�X�̃|�C���^
    end;

    // DROPOBJECT �\����
    TDROPOBJECT = record
        FormatEtc: ^TFORMATETC;                             // FORMATETC �\����
        StgMedium: ^TSTGMEDIUM;                             // STGMEDIUM �\����
        fRelease: longbool;                                 // �f�[�^�����t���O
    end;

    // IDROPSOURCEVTBL �\����
    TIDROPSOURCEVTBL = record
        OLEIDropSourceQueryInterface: pointer;              // IDropSource::QueryInterface �֐��̃|�C���^
        OLEIDropSourceAddRef: pointer;                      // IDropSource::AddRef �֐��̃|�C���^
        OLEIDropSourceRelease: pointer;                     // IDropSource::Release �֐��̃|�C���^
        OLEIDropSourceQueryContinueDrag: pointer;           // IDropSource::QueryContinueDrag �֐��̃|�C���^
        OLEIDropSourceGiveFeedback: pointer;                // IDropSource::GiveFeedback �֐��̃|�C���^
    end;

    // IDROPSOURCE �\����
    TIDROPSOURCE = record
        lpVtbl: pointer;                                    // �C���^�[�t�F�C�X�̃|�C���^
        dwRefCnt: longword;                                 // �Q�ƃJ�E���g
    end;

    // IDATAOBJECTVTBL �\����
    TIDATAOBJECTVTBL = record
        OLEIDataObjectQueryInterface: pointer;              // IDataObject::QueryInterface �֐��̃|�C���^
        OLEIDataObjectAddRef: pointer;                      // IDataObject::AddRef �֐��̃|�C���^
        OLEIDataObjectRelease: pointer;                     // IDataObject::Release �֐��̃|�C���^
        OLEIDataObjectGetData: pointer;                     // IDataObject::GetData �֐��̃|�C���^
        OLEIDataObjectGetDataHere: pointer;                 // IDataObject::GetDataHere �֐��̃|�C���^
        OLEIDataObjectQueryGetData: pointer;                // IDataObject::QueryGetData �֐��̃|�C���^
        OLEIDataObjectGetCanonicalFormatEtc: pointer;       // IDataObject::GetCanonicalFormatEtc �֐��̃|�C���^
        OLEIDataObjectSetData: pointer;                     // IDataObject::SetData �֐��̃|�C���^
        OLEIDataObjectEnumFormatEtc: pointer;               // IDataObject::EnumFormatEtc �֐��̃|�C���^
        OLEIDataObjectDAdvise: pointer;                     // IDataObject::DAdvise �֐��̃|�C���^
        OLEIDataObjectDUnadvise: pointer;                   // IDataObject::DUnadvise �֐��̃|�C���^
        OLEIDataObjectEnumDAdvise: pointer;                 // IDataObject::EnumDAdvise �֐��̃|�C���^
    end;

    // IDATAOBJECT �\����
    TIDATAOBJECT = record
        lpVtbl: pointer;                                    // �C���^�[�t�F�C�X�̃|�C���^
        dwRefCnt: longword;                                 // �Q�ƃJ�E���g
        dwObjectCnt: longword;                              // �f�[�^ �I�u�W�F�N�g��
        Objects: array[0..15] of TDROPOBJECT;               // �f�[�^ �I�u�W�F�N�g���
    end;

{$IFDEF ITASKBARLIST3}
    // ITASKBARLIST3VTBL �\����
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

    // ITASKBARLIST3 �\����
    TITASKBARLIST3 = record
        lpVtbl: pointer;                                    // �C���^�[�t�F�C�X�̃|�C���^
    end;
{$ENDIF}

{$IFDEF TRANSMITSPC}
    // TRANSFERSPCEX �\����
    TTRANSFERSPCEX = record
        cbSize: longword;
        transmitType: longword;
        bScript700: longbool;
        lptPort: longword;
    end;
{$ENDIF}

    // CLASS �N���X
    CCLASS = class
    private
    public
        procedure CreateClass(lpWindowProc: pointer; hThisInstance: longword; lpClassName: pointer; dwStyle: longword; lpIcon: pointer; lpSmallIcon: pointer; dwCursor: longword; dwBackColor: longword);
        procedure DeleteClass(hThisInstance: longword; lpClassName: pointer);
    end;

    // FONT �N���X
    CFONT = class
    private
    public
        hFont: longword;                                    // �t�H���g �n���h��
        procedure CreateFont(lpFontName: pointer; nHeight: longint; nWidth: longint; bBold: longbool; bItalic: longbool; bUnderLine: longbool; bStrike: longbool);
        procedure DeleteFont();
    end;

    // MENU �N���X
    CMENU = class
    private
    public
        hMenu: longword;                                    // ���j���[ �n���h��
        procedure AppendMenu(dwID: longword; lpString: pointer); overload;
        procedure AppendMenu(dwID: longword; lpString: pointer; bRadio: longbool); overload;
        procedure AppendMenu(dwID: longword; lpString: pointer; hSubMenuID: longword); overload;
        procedure AppendSeparator();
        procedure CreateMenu();
        procedure CreatePopupMenu();
        procedure DeleteMenu();
        procedure InsertMenu(dwID: longword; dwPosition: longword; lpString: pointer); overload;
        procedure InsertMenu(dwID: longword; dwPosition: longword; lpString: pointer; bRadio: longbool); overload;
        procedure InsertMenu(dwID: longword; dwPosition: longword; lpString: pointer; hSubMenuID: longword); overload;
        procedure InsertSeparator(dwPosition: longword);
        procedure RemoveItem(dwPosition: longword);
        procedure SetMenuCheck(dwID: longword; bCheck: longbool);
        procedure SetMenuEnable(dwID: longword; bEnable: longbool);
    end;

    // WINDOW �N���X
    CWINDOW = class
    private
    public
        hWnd: longword;                                     // �E�B���h�E �n���h��
        bMessageBox: longbool;                              // ���b�Z�[�W �{�b�N�X �t���O
        procedure CreateItem(hThisInstance: longword; hMainWnd: longword; hFont: longword; lpItemName: pointer; lpCaption: pointer; dwItemID: longword; dwStylePlus: longword; dwStyleExPlus: longword; Box: TBOX);
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

    // WINDOWMAIN �N���X
    CWINDOWMAIN = class
    private
        cfMain: CFONT;                                      // �t�H���g �N���X
        cwWindowMain: CWINDOW;                              // �E�B���h�E �N���X (���C�� �E�B���h�E)
        cmSystem: CMENU;                                    // ���j���[ �N���X (�V�X�e�� ���j���[)
        cmMain: CMENU;                                      // ���j���[ �N���X (���j���[ �o�[)
        cmFile: CMENU;                                      // ���j���[ �N���X (�t�@�C��)
        cmSetup: CMENU;                                     // ���j���[ �N���X (�ݒ�)
        cmSetupDevice: CMENU;                               // ���j���[ �N���X (�ݒ� - �T�E���h �f�o�C�X)
        cmSetupChannel: CMENU;                              // ���j���[ �N���X (�ݒ� - �`�����l��)
        cmSetupBit: CMENU;                                  // ���j���[ �N���X (�ݒ� - �r�b�g)
        cmSetupRate: CMENU;                                 // ���j���[ �N���X (�ݒ� - �T���v�����O ���[�g)
        cmSetupInter: CMENU;                                // ���j���[ �N���X (�ݒ� - ��ԏ���)
        cmSetupPitch: CMENU;                                // ���j���[ �N���X (�ݒ� - �s�b�`)
        cmSetupPitchKey: CMENU;                             // ���j���[ �N���X (�ݒ� - �s�b�` - �L�[)
        cmSetupSeparate: CMENU;                             // ���j���[ �N���X (�ݒ� - ���E�g�U�x)
        cmSetupFeedback: CMENU;                             // ���j���[ �N���X (�ݒ� - �t�B�[�h�o�b�N���]�x)
        cmSetupSpeed: CMENU;                                // ���j���[ �N���X (�ݒ� - ���t���x)
        cmSetupAmp: CMENU;                                  // ���j���[ �N���X (�ݒ� - ����)
        cmSetupMute: CMENU;                                 // ���j���[ �N���X (�ݒ� - �`�����l�� �}�X�N)
        cmSetupNoise: CMENU;                                // ���j���[ �N���X (�ݒ� - �`�����l�� �m�C�Y)
        cmSetupOption: CMENU;                               // ���j���[ �N���X (�ݒ� - �g���ݒ�)
        cmSetupTime: CMENU;                                 // ���j���[ �N���X (�ݒ� - ���t����)
        cmSetupOrder: CMENU;                                // ���j���[ �N���X (�ݒ� - ���t����)
        cmSetupSeek: CMENU;                                 // ���j���[ �N���X (�ݒ� - �V�[�N����)
        cmSetupInfo: CMENU;                                 // ���j���[ �N���X (�ݒ� - ���\��)
        cmSetupPriority: CMENU;                             // ���j���[ �N���X (�ݒ� - ��{�D��x)
        cmList: CMENU;                                      // ���j���[ �N���X (�v���C���X�g)
        cmListPlay: CMENU;                                  // ���j���[ �N���X (�v���C���X�g - ���t�J�n)
        cwStaticFile: CWINDOW;                              // �E�B���h�E �N���X (�t�@�C�����]���p���x��)
        cwStaticMain: CWINDOW;                              // �E�B���h�E �N���X (���\���p���x��)
        cwButtonOpen: CWINDOW;                              // �E�B���h�E �N���X (OPEN �{�^��)
        cwButtonSave: CWINDOW;                              // �E�B���h�E �N���X (SAVE �{�^��)
        cwButtonPlay: CWINDOW;                              // �E�B���h�E �N���X (PLAY �{�^��)
        cwButtonRestart: CWINDOW;                           // �E�B���h�E �N���X (RESTART �{�^��)
        cwButtonStop: CWINDOW;                              // �E�B���h�E �N���X (STOP �{�^��)
        cwCheckTrack: array[0..7] of CWINDOW;               // �E�B���h�E �N���X (1 �` 8 �{�^��)
        cwButtonVolM: CWINDOW;                              // �E�B���h�E �N���X (VL- �{�^��)
        cwButtonVolP: CWINDOW;                              // �E�B���h�E �N���X (VL+ �{�^��)
        cwButtonSlow: CWINDOW;                              // �E�B���h�E �N���X (SP- �{�^��)
        cwButtonFast: CWINDOW;                              // �E�B���h�E �N���X (SP+ �{�^��)
        cwButtonBack: CWINDOW;                              // �E�B���h�E �N���X (REW �{�^��)
        cwButtonNext: CWINDOW;                              // �E�B���h�E �N���X (FF �{�^��)
        cwFileList: CWINDOW;                                // �E�B���h�E �N���X (�t�@�C���L�^�p)
        cwSortList: CWINDOW;                                // �E�B���h�E �N���X (�\�[�g�p)
        cwTempList: CWINDOW;                                // �E�B���h�E �N���X (�e���|�����p)
        cwPlayList: CWINDOW;                                // �E�B���h�E �N���X (�v���C���X�g)
        cwButtonListAdd: CWINDOW;                           // �E�B���h�E �N���X (ADD / INSERT �{�^��)
        cwButtonListRemove: CWINDOW;                        // �E�B���h�E �N���X (REMOVE �{�^��)
        cwButtonListClear: CWINDOW;                         // �E�B���h�E �N���X (CLEAR �{�^��)
        cwButtonListUp: CWINDOW;                            // �E�B���h�E �N���X (��փ{�^��)
        cwButtonListDown: CWINDOW;                          // �E�B���h�E �N���X (���փ{�^��)
    public
        procedure AppendList();
        function  CreateWindow(hThisInstance: longword; lpClassName: pointer; lpArgs: pointer): longword;
        procedure DeleteWindow();
        procedure DragFile(msg: longword; wParam: longword; lParam: longword);
        procedure DrawInfo(pApuData: pointer; bWave: longbool);
        function  DropFile(dwParam: longword): longword;
        function  GetFileType(lpFile: pointer; bShowMsg: longbool; bScript700: longbool): longword;
        procedure GetID666Format(var Hdr: TSPCHDR);
        function  GetSize(lpBuffer: pointer; dwMax: longword): longword;
        function  IsExt(lpFile: pointer; sExt: string): longbool;
        function  IsSafePath(lpFile: pointer): longbool;
        procedure ListAdd(dwAuto: longword);
        procedure ListClear();
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
        procedure UpdateInfo(bRedraw: longbool);
        procedure UpdateMenu();
        procedure UpdateTitle(dwFlag: longword);
        procedure UpdateWindow();
        procedure WaveClose();
        procedure WaveFormat(dwIndex: longword);
        procedure WaveInit();
        function  WaveOpen(): longword;
        function  WavePause(): longbool;
        procedure WaveProc(dwFlag: longword);
        procedure WaveQuit();
        procedure WaveReset();
        function  WaveResume(): longbool;
        function  WaveSave(lpFile: pointer; bShift: longbool; bQuiet: longbool): longbool;
        procedure WaveStart();
        function  WindowProc(hWnd: longword; msg: longword; wParam: longword; lParam: longword; var dwDef: longword): longword;
    end;


// *************************************************************************************************************************************************************
// �萔�̐錾
// *************************************************************************************************************************************************************

const
    // Delphi �W���萔
    NULL = 0;                                               // �k��
    NULLCHAR = #0;                                          // �k������
    NULLPOINTER = nil;                                      // �k�� �|�C���^
    CRLF = #13#10;                                          // ���s

    // CLASS �N���X
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

    // MENU �N���X
    MF_BYCOMMAND = $0;
    MF_BYPOSITION = $400;
    MF_CHECKED = $8;
    MF_DISABLED = $2;
    MF_ENABLED = $0;
    MF_GRAYED = $1;
    MF_HILITE = $80;
    MF_MENUBREAK = $20;
    MF_OWNERDROW = $100;
    MF_POPUP = $10;
    MF_RADIOCHECK = $200;
    MF_RIGHTJUSTIFY = $2000;
    MF_RIGHTORDER = $1000;
    MF_SEPARATOR = $800;
    MF_STRING = $0;
    MF_UNCHECKED = $0;
    MF_UNHILITE = $0;

    // WINDOW �N���X
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
    PM_NOREMOVE = $0;
    PM_REMOVE = $1;
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
    SM_AEROFRAME = 85;                                      // �E�B���h�E�̘g�� (px) for Windows Vista, 7
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
    WM_APP = $8000;                                         // �` $BFFF
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
    WM_UNICHAR = $109;                                      // Windows XP
    WM_UNINITMENUPOPUP = $125;
    WM_UNDO = $304;
    WM_USER = $400;                                         // �` $7FFF
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

    // MAINWINDOW �N���X
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

    CREATE_NEW = $1;
    CREATE_ALWAYS = $2;
    OPEN_EXISTING = $3;
    OPEN_ALWAYS = $4;
    TRUNCATE_EXISTING = $5;

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

    GMEM_FIXED = $0;
    GMEM_MOVEABLE = $2;
    GMEM_ZEROINIT = $40;
    GHND = GMEM_MOVEABLE or GMEM_ZEROINIT;
    GPTR = GMEM_FIXED or GMEM_ZEROINIT;

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
    TYMED_ENHMF = $40;
    TYMED_FILE = $2;
    TYMED_HGLOBAL = $1;
    TYMED_GDI = $10;
    TYMED_ISTORAGE = $8;
    TYMED_ISTREAM = $4;
    TYMED_MFPICT = $20;
    TYMED_NULL = $0;

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

    // SNES SPC700 Player �{�̂̐ݒ�
    DEFAULT_TITLE: string = 'SNES SPC700 Player';
    SPCPLAY_TITLE = '[ SNES SPC700 Player   ]' + CRLF + ' SPCPLAY.EXE v';
    SNESAPU_TITLE = '[ SNES SPC700 Emulator ]' + CRLF + ' SNESAPU.DLL v';
    SPCPLAY_VERSION = '2.18.1 (build 6862)';
    SNESAPU_VERSION = $21861;
    APPLINK_VERSION = $02170500;

    CBE_DSPREG = $1;
    CBE_S700FCH = $2;
    CBE_INCS700 = $40000000;
    CBE_INCDATA = $20000000;
    SCRIPT700_TEXT = $FFFFFFFF;

    BRKP_NEXT_STOP = $10000000;
    BRKP_STOPPED = $20000000;
    BRKP_RELEASE = $80000000;

{$IFNDEF TRANSMITSPC}
    CLASS_NAME: string = 'SSDLabo_SPCPLAY';
{$ELSE}
    CLASS_NAME: string = 'SSDLabo_SPCPLAY_DEBUG';
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
    BUFFER_BUFNUM__: string = 'BUFNUM   2 : ';
    BUFFER_BUFTIME_: string = 'BUFTIME  2 : ';
    BUFFER_CHANNEL_: string = 'CHANNEL  0 : ';
    BUFFER_DEVICE__: string = 'DEVICE   0 : ';
    BUFFER_DRAWINFO: string = 'DRAWINFO 0 : ';
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
    BUFFER_SEEKFAST: string = 'SEEKFAST 1 : ';
    BUFFER_SEEKINT_: string = 'SEEKINT  1 : ';
    BUFFER_SEEKMAX_: string = 'SEEKMAX  1 : ';
    BUFFER_SEEKNUM_: string = 'SEEKNUM  2 : ';
    BUFFER_SEEKTIME: string = 'SEEKTIME 1 : ';
    BUFFER_SEPARATE: string = 'SEPARATE 0 : ';
    BUFFER_SPEED___: string = 'SPEED    0 : ';
    BUFFER_SPEEDTUN: string = 'SPEEDTUN 0 : ';
    BUFFER_TOP_____: string = 'TOP      0 : ';
    BUFFER_TOPMOST_: string = 'TOPMOST  0 : ';
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
    ICON_NAME = 'MAINICON';
    BITMAP_NAME = 'MAINBMP';
    FILE_DEFAULT: string = 'FILE TRANSMIT WINDOW';
    MIN_WAVE_LEVEL = 65535;
    LIST_ADD_THRESHOLD = 297;
    DRAG_START_THRESHOLD = 5;
    DRAG_LIMIT_THRESHOLD = 2;
    WINDOW_MOVE_THRESHOLD = 10;
    WINDOW_WIDTH = 520;
    WINDOW_HEIGHT = 152;

    WM_APP_MESSAGE = $8000;                                 // �ʒm���b�Z�[�W
    WM_APP_COMMAND = $8001;                                 // ���[�U �R�}���h

    WM_APP_TRANSMIT = $00000000;                            // �t�@�C�����]��     ($0000???X, X:AutoPlay, lParam:hWnd)
    WM_APP_ACTIVATE = $00010000;                            // �A�N�e�B�u         ($0001????)
    WM_APP_REDRAW = $00020000;                              // �ĕ`��             ($0002????)
    WM_APP_SEEK = $00030000;                                // �V�[�N             ($0003????)
    WM_APP_NEXT_PLAY = $00040000;                           // ���̋Ȃ����t       ($0004????)
    WM_APP_MINIMIZE = $00050000;                            // �ŏ����v��         ($0005????)
    WM_APP_REPEAT_TIME = $00060000;                         // ���s�[�g�ʒu       ($0006????)
    WM_APP_START_TIME = $00061000;                          // ���s�[�g�J�n�ʒu   ($00061???)
    WM_APP_LIMIT_TIME = $00062000;                          // ���s�[�g�I���ʒu   ($00062???)
    WM_APP_RESET_TIME = $00063000;                          // ���s�[�g�ʒu������ ($00063???)
    WM_APP_DRAG_DONE = $00070000;                           // �h���b�O�I��       ($0007????)
    WM_APP_UPDATE_INFO = $00080000;                         // ���X�V           ($0008???X, X:Redraw)
    WM_APP_UPDATE_MENU = $00090000;                         // ���j���[�X�V       ($0009????)
    WM_APP_WAVE_OUTPUT = $000A0000;                         // WAVE ��������      ($000A??YX, X:Shift, Y:Quiet, lParam:hWnd)

    WM_APP_WAVE_PROC = $10000000;                           // WAVE ���荞��      ($1000????)
    WM_APP_SPC_PLAY = $10010000;                            // SPC ���t�J�n       ($1001????)
    WM_APP_SPC_PAUSE = $10020000;                           // SPC �ꎞ��~       ($1002????)
    WM_APP_SPC_RESUME = $10030000;                          // SPC ���t�ĊJ       ($1003????)
    WM_APP_SPC_RESET = $10040000;                           // SPC ���t�ݒ�       ($1004????)
    WM_APP_SPC_TIME = $10050000;                            // SPC ���Ԑݒ�       ($1005????)
    WM_APP_SPC_SEEK = $10060000;                            // SPC �V�[�N         ($1006???X, X:Cache)

    WM_APP_FUNCTION = $F0000000;                            // �@�\�ݒ�           ($F000???X, X:Type 0 or 2)
    WM_APP_GET_DSP = $F1000000;                             // DSP �ǂݎ��       ($F100??XX, XX:DSP Address)
    WM_APP_SET_DSP = $F1010000;                             // DSP ��������       ($F101??XX, XX:DSP Address, lParam:Value)
    WM_APP_GET_PORT = $F1100000;                            // �|�[�g�ǂݎ��     ($F110???X, X:PORT Address)
    WM_APP_SET_PORT = $F1110000;                            // �|�[�g��������     ($F111???X, X:PORT Address, lParam:Value)
    WM_APP_GET_RAM = $F1200000;                             // RAM �ǂݎ��       ($F120XXXX, XXXX:RAM Address)
    WM_APP_SET_RAM = $F1210000;                             // RAM ��������       ($F121XXXX, XXXX:RAM Address, lParam:Value)
    WM_APP_GET_WORK = $F1300000;                            // ���[�N�ǂݎ��     ($F130???X, X:WORK Address)
    WM_APP_SET_WORK = $F1310000;                            // ���[�N��������     ($F131???X, X:WORK Address, lParam:Value)
    WM_APP_GET_CMP = $F1400000;                             // ��r�l�ǂݎ��     ($F140???X, X:CMP Address)
    WM_APP_SET_CMP = $F1410000;                             // ��r�l��������     ($F141???X, X:CMP Address, lParam:Value)
    WM_APP_GET_SPC = $F1500000;                             // SPC �ǂݎ��       ($F150???X, X:0=PC,1=Y+A,2=SP+X,3=PSW)
    WM_APP_SET_SPC = $F1510000;                             // SPC ��������       ($F151???X, X:0=PC,1=Y+A,2=SP+X,3=PSW, lParam:Value)
    WM_APP_HALT = $F1600000;                                // HALT �X�C�b�`      ($F160????, lParam:1=SPC_RETURN, 2=SPC_HALT, 4=DSP_HALT, 8=SPC_NODSP)
    WM_APP_BP_SET = $F4000000;                              // BreakPoint �ݒ�    ($F400XXXX, X=RAM Address, lParam:CBE Flags (0:UNSET))
    WM_APP_BP_CLEAR = $F4010000;                            // BreakPoint �S����  ($F401????)
    WM_APP_NEXT_TICK = $F4100000;                           // ���̖��߂Ŏ~�߂�   ($F410????, lParam:0=CBE Flags)
    WM_APP_DSP_CHEAT = $F5000000;                           // DSP �`�[�g�ݒ�     ($F500??XX, XX:DSP Address, lParam:Value (-1:UNSET))
    WM_APP_DSP_THRU = $F5010000;                            // DSP �`�[�g�S����   ($F501????)
    WM_APP_STATUS = $FF000000;                              // �X�e�[�^�X�擾     ($FF00????)
    WM_APP_APPVER = $FF010000;                              // �o�[�W�����擾     ($FF01????)
    WM_APP_EMU_APU = $FFFE0000;                             // �����G�~�����[�g   ($FFFE????)
    WM_APP_EMU_DEBUG = $FFFF0000;                           // SPC700 �]���e�X�g  ($FFFF???X, X:Flag)

    FILE_TYPE_NOTEXIST = $1;                                // ���݂��Ȃ�
    FILE_TYPE_NOTREAD = $2;                                 // �ǂݍ��ݕs��
    FILE_TYPE_UNKNOWN = $3;                                 // �s���Ȍ`��
    FILE_TYPE_SPC = $10;                                    // SPC �t�@�C��
    FILE_TYPE_LIST_A = $11;                                 // �v���C���X�g �t�@�C�� TYPE-A
    FILE_TYPE_LIST_B = $12;                                 // �v���C���X�g �t�@�C�� TYPE-B
    FILE_TYPE_FOLDER = $13;                                 // �t�H���_
    FILE_TYPE_SCRIPT700 = $14;                              // Script700

    STATUS_OPEN = $1;                                       // Open �t���O
    STATUS_PLAY = $2;                                       // Play �t���O
    STATUS_PAUSE = $4;                                      // Pause �t���O

    ID666_UNKNOWN = $0;                                     // �s��
    ID666_TEXT = $1;                                        // ID666 �e�L�X�g �t�H�[�}�b�g
    ID666_BINARY = $2;                                      // ID666 �o�C�i�� �t�H�[�}�b�g

    INFO_INDICATOR = $0;                                    // �O���t�B�b�N �C���W�P�[�^
    INFO_MIXER = $1;                                        // �~�L�T�[���
    INFO_CHANNEL_1 = $2;                                    // �`�����l����� 1
    INFO_CHANNEL_2 = $3;                                    // �`�����l����� 2
    INFO_CHANNEL_3 = $4;                                    // �`�����l����� 3
    INFO_CHANNEL_4 = $5;                                    // �`�����l����� 4
    INFO_SPC_1 = $6;                                        // SPC ��� 1
    INFO_SPC_2 = $7;                                        // SPC ��� 2
    INFO_SCRIPT700 = $8;                                    // Script700 �f�o�b�O

    PLAY_TYPE_AUTO = $0;                                    // ���t�����I��
    PLAY_TYPE_PLAY = $1;                                    // ���t�J�n
    PLAY_TYPE_PAUSE = $2;                                   // �ꎞ��~
    PLAY_TYPE_LIST = $3;                                    // �v���C���X�g �A�C�e���I��
    PLAY_TYPE_RANDOM = $4;                                  // �v���C���X�g �����_���I��

    PLAY_ORDER_STOP = $0;                                   // ��~
    PLAY_ORDER_NEXT = $1;                                   // ����
    PLAY_ORDER_PREVIOUS = $2;                               // �O��
    PLAY_ORDER_RANDOM = $3;                                 // �����_��
    PLAY_ORDER_SHUFFLE = $4;                                // �V���b�t��
    PLAY_ORDER_REPEAT = $5;                                 // ���s�[�g
    PLAY_ORDER_FIRST = $6;                                  // �ŏ�����
    PLAY_ORDER_LAST = $7;                                   // �Ōォ��

    FUNCTION_TYPE_SEPARATE = $1;                            // ���E�g�U�x
    FUNCTION_TYPE_FEEDBACK = $2;                            // �t�B�[�h�o�b�N���]�x
    FUNCTION_TYPE_SPEED = $3;                               // ���t���x
    FUNCTION_TYPE_AMP = $4;                                 // ����
    FUNCTION_TYPE_SEEK = $5;                                // �V�[�N
    FUNCTION_TYPE_NO_TIMER = $80000000;                     // �^�C�}�[�ݒ�Ȃ�

    LIST_PLAY_INDEX_SELECTED = -1;                          // �v���C���X�g�I���ς݃A�C�e��
    LIST_PLAY_INDEX_RANDOM = -2;                            // �v���C���X�g �����_���I��
    LIST_NEXT_PLAY_SELECT = $10000;                         // �v���C���X�g �A�C�e���I��
    LIST_NEXT_PLAY_CENTER = $20000;                         // �v���C���X�g�����I��

    TITLE_HIDE = $0;                                        // ��\��
    TITLE_NORMAL = $100;                                    // �W��
    TITLE_MINIMIZE = $200;                                  // �ŏ���
    TITLE_ALWAYS_FLAG = $FF00;                              // �W�� + �ŏ���
    TITLE_INFO_SEPARATE = $1;                               // ���E�g�U�x
    TITLE_INFO_FEEDBACK = $2;                               // �t�B�[�h�o�b�N���]�x
    TITLE_INFO_SPEED = $3;                                  // ���t���x
    TITLE_INFO_AMP = $4;                                    // ����
    TITLE_INFO_SEEK = $5;                                   // �V�[�N

    TIMER_ID_TITLE_INFO = $1;                               // �ꎞ�I�v�V�������\��
    TIMER_ID_OPTION_LOCK = $2;                              // �I�v�V�����ύX���b�N
    TIMER_INTERVAL_TITLE_INFO = 1000;                       // �ꎞ�I�v�V�������\���̎���
    TIMER_INTERVAL_OPTION_LOCK = 300;                       // �I�v�V�����ύX���b�N�̎���

    REDRAW_OFF = $0;                                        // �ĕ`��Ȃ�
    REDRAW_LOCK_CRITICAL = $1;                              // �`�惍�b�N (����)
    REDRAW_LOCK_READY = $2;                                 // �`�惍�b�N (����`�拖��)
    REDRAW_ON = $4;                                         // �ĕ`�悠��

    DRAW_INFO_ALWAYS = $1;                                  // ��ɕ`��

    WAVE_PROC_GRAPH_ONLY = $0;                              // �C���W�P�[�^�̂ݕ`��
    WAVE_PROC_NO_GRAPH = $FFFF;                             // �C���W�P�[�^��`�悵�Ȃ�
    WAVE_PROC_WRITE_WAVE = $10000;                          // �T�E���h �o�b�t�@��������
    WAVE_PROC_WRITE_INIT = $20000;                          // �Đ����̏�����

    WAVE_MESSAGE_MAX_COUNT = 1;                             // WAVE ���b�Z�[�W�ő呗�M��

    WAVE_THREAD_SUSPEND = $0;                               // ��~���
    WAVE_THREAD_RUNNING = $1;                               // ���s���
    WAVE_THREAD_DEVICE_OPENED = $2;                         // �f�o�C�X �I�[�v������
    WAVE_THREAD_DEVICE_CLOSED = $4;                         // �f�o�C�X �N���[�Y����

    WAVE_FORMAT_TYPE_SIZE = 2;
    WAVE_FORMAT_TYPE_ARRAY: array[0..WAVE_FORMAT_TYPE_SIZE - 1] of longword = (WAVE_FORMAT_DIRECT, NULL);
    WAVE_FORMAT_TAG_SIZE = 2;
    WAVE_FORMAT_TAG_ARRAY: array[0..WAVE_FORMAT_TAG_SIZE - 1] of word = (WAVE_FORMAT_EXTENSIBLE, WAVE_FORMAT_PCM);
    WAVE_FORMAT_INDEX_EXTENSIBLE = 0;
    WAVE_FORMAT_INDEX_PCM = 1;

    COLOR_BAR_NUM = 6;                                      // �C���W�P�[�^ �o�[�̐�
    COLOR_BAR_NUM_X3 = 18;
    COLOR_BAR_NUM_X7 = 42;
    COLOR_BAR_WIDTH = 7;                                    // �C���W�P�[�^ �o�[�̍ő啝
    COLOR_BAR_TOP = 48;                                     // �C���W�P�[�^ �o�[�̕`��ʒu
    COLOR_BAR_TOP_FRAME = 45;                               // �t���[���̕`��ʒu
    COLOR_BAR_HEIGHT = 48;                                  // �C���W�P�[�^ �o�[�̍���
    COLOR_BAR_HEIGHT_M1 = 47;
    COLOR_BAR_HEIGHT_X2 = 96;
    COLOR_START_R: array[0..COLOR_BAR_NUM_X3 - 1] of byte = (  0, 172,   0, 172,   0, 102,   0, 224,   0, 212,   0, 120, 132, 255, 128, 255, 172, 224);
    COLOR_START_G: array[0..COLOR_BAR_NUM_X3 - 1] of byte = (128,  80,  96,   0,   0,   0, 164, 112, 112,   0,   0,   0, 255, 192, 208, 136, 168, 144);
    COLOR_START_B: array[0..COLOR_BAR_NUM_X3 - 1] of byte = (  0,   0, 212,   0, 240, 240,   0,   0, 224,   0, 240, 240, 128, 128, 255, 140, 255, 255);
    COLOR_END_R:   array[0..COLOR_BAR_NUM_X3 - 1] of byte = (  0, 128,   0,  96,   0,  58,   0, 160,   0, 112,   0,  64,  52, 172,  48, 192,  68, 104);
    COLOR_END_G:   array[0..COLOR_BAR_NUM_X3 - 1] of byte = ( 64,  48,  64,   0,   0,   0,  96,  80,  80,   0,   0,   0, 106, 106, 128,  36,  64,  48);
    COLOR_END_B:   array[0..COLOR_BAR_NUM_X3 - 1] of byte = (  0,   0, 160,   0, 128, 128,   0,   0, 160,   0, 128, 128,  48,  52, 164,  40, 192, 154);

    COLOR_BRIGHT_FORE = 127500;                             // �����F�̖��邳��臒l
    COLOR_BRIGHT_BACK = 180000;                             // �w�i�F�̖��邳��臒l

    COLOR_BAR_GREEN = 0;                                    // ��
    COLOR_BAR_ORANGE = 7;                                   // �I�����W
    COLOR_BAR_WATER = 14;                                   // ���F
    COLOR_BAR_RED = 21;                                     // ��
    COLOR_BAR_BLUE = 28;                                    // ��
    COLOR_BAR_PURPLE = 35;                                  // ��

    ORG_COLOR_BAR_GREEN = $10000 or COLOR_BAR_GREEN;        // ��
    ORG_COLOR_BAR_ORANGE = $10000 or COLOR_BAR_ORANGE;      // �I�����W
    ORG_COLOR_BAR_WATER = $10000 or COLOR_BAR_WATER;        // ���F
    ORG_COLOR_BAR_RED = $10000 or COLOR_BAR_RED;            // ��
    ORG_COLOR_BAR_BLUE = $10000 or COLOR_BAR_BLUE;          // ��
    ORG_COLOR_BAR_PURPLE = $10000 or COLOR_BAR_PURPLE;      // ��

    ORG_COLOR_BTNFACE = COLOR_BTNFACE + 1;                  // �{�^���̐F
    ORG_COLOR_GRAYTEXT = COLOR_GRAYTEXT + 1;                // �������̕����F
    ORG_COLOR_WINDOWTEXT = COLOR_WINDOWTEXT + 1;            // �L�����̕����F

    BITMAP_NUM = 50;                                        // �r�b�g�}�b�v�����̐�
    BITMAP_NUM_X6 = BITMAP_NUM * 6;
    BITMAP_NUM_X6P6 = BITMAP_NUM_X6 + 6;
    BITMAP_NUM_WIDTH = 6;                                   // �r�b�g�}�b�v�����̕�
    BITMAP_NUM_HEIGHT = 9;                                  // �r�b�g�}�b�v�����̍���
    BITMAP_MARK_HEIGHT = 3;                                 // �ʒu�}�[�N�̍���
    BITMAP_STRING_COLOR: array[0..BITMAP_NUM - 1] of longword =
        (ORG_COLOR_WINDOWTEXT, ORG_COLOR_WINDOWTEXT, ORG_COLOR_WINDOWTEXT, ORG_COLOR_WINDOWTEXT, ORG_COLOR_WINDOWTEXT, ORG_COLOR_WINDOWTEXT, ORG_COLOR_WINDOWTEXT, ORG_COLOR_WINDOWTEXT,
         ORG_COLOR_WINDOWTEXT, ORG_COLOR_WINDOWTEXT, ORG_COLOR_WINDOWTEXT, ORG_COLOR_WINDOWTEXT, ORG_COLOR_WINDOWTEXT, ORG_COLOR_WINDOWTEXT, ORG_COLOR_WINDOWTEXT, ORG_COLOR_WINDOWTEXT,
         ORG_COLOR_WINDOWTEXT, ORG_COLOR_WINDOWTEXT, ORG_COLOR_BAR_GREEN , ORG_COLOR_BAR_WATER , ORG_COLOR_BAR_ORANGE, ORG_COLOR_BAR_RED   , ORG_COLOR_BAR_BLUE  , ORG_COLOR_BAR_PURPLE,
         ORG_COLOR_BAR_BLUE  , ORG_COLOR_BAR_BLUE  , ORG_COLOR_BAR_BLUE  , ORG_COLOR_BAR_BLUE  , ORG_COLOR_BAR_BLUE  , ORG_COLOR_BAR_BLUE  , ORG_COLOR_BAR_RED   , ORG_COLOR_GRAYTEXT  ,
         ORG_COLOR_BAR_RED   , ORG_COLOR_BAR_RED   , ORG_COLOR_BAR_BLUE  , ORG_COLOR_BAR_BLUE  , ORG_COLOR_BAR_ORANGE, ORG_COLOR_BAR_GREEN , ORG_COLOR_BAR_RED   , ORG_COLOR_BAR_BLUE  ,
         ORG_COLOR_BAR_ORANGE, ORG_COLOR_BAR_GREEN , ORG_COLOR_BAR_WATER , ORG_COLOR_BAR_RED   , ORG_COLOR_BAR_BLUE  , ORG_COLOR_BAR_ORANGE, ORG_COLOR_BAR_RED   , ORG_COLOR_BAR_WATER ,
         ORG_COLOR_BAR_RED   , ORG_COLOR_BAR_PURPLE);

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

    CHANNEL_MONO = 1;                                       // ���m����
    CHANNEL_STEREO = 2;                                     // �X�e���I

    BIT_8 = 1;                                              // 8 �r�b�g
    BIT_16 = 2;                                             // 16 �r�b�g
    BIT_24 = 3;                                             // 24 �r�b�g
    BIT_32 = 4;                                             // 32 �r�b�g (int)
    BIT_IEEE = -4;                                          // 32 �r�b�g (float)

    INTER_NONE = 0;                                         // ��ԏ�������
    INTER_LINEAR = 1;                                       // ���`��ԏ���
    INTER_CUBIC = 2;                                        // �O���Ȑ���ԏ���
    INTER_GAUSS = 3;                                        // ���@�K�E�X���z��ԏ���
    INTER_SINC = 4;                                         // �V���N�֐���ԏ���
    INTER_GAUSS4 = 7;                                       // �K�E�X�֐���ԏ���

    PITCH_NORMAL = 32000;                                   // �W��
    PITCH_OLDSBC = 32458;                                   // OLD Sound Blaster Card
    PITCH_OLDSNES = 32768;                                  // OLD ZSNES, Snes9x

    SEPARATE_100 = 65536;                                   // 100 ��
    SEPARATE_000 = 0;                                       // 0 ��
    SEPARATE_010 = SEPARATE_100 * 10 div 100;               // 10 ��
    SEPARATE_020 = SEPARATE_100 * 20 div 100;               // 20 ��
    SEPARATE_025 = SEPARATE_100 * 25 div 100;               // 25 ��
    SEPARATE_030 = SEPARATE_100 * 30 div 100;               // 30 ��
    SEPARATE_033 = SEPARATE_100 * 33 div 100;               // 33 ��
    SEPARATE_040 = SEPARATE_100 * 40 div 100;               // 40 ��
    SEPARATE_050 = SEPARATE_100 * 50 div 100;               // 50 ��
    SEPARATE_060 = SEPARATE_100 * 60 div 100;               // 60 ��
    SEPARATE_067 = SEPARATE_100 * 67 div 100;               // 67 ��
    SEPARATE_070 = SEPARATE_100 * 70 div 100;               // 70 ��
    SEPARATE_075 = SEPARATE_100 * 75 div 100;               // 75 ��
    SEPARATE_080 = SEPARATE_100 * 80 div 100;               // 80 ��
    SEPARATE_090 = SEPARATE_100 * 90 div 100;               // 90 ��

    FEEDBACK_100 = SEPARATE_100;                            // 100 ��
    FEEDBACK_000 = SEPARATE_000;                            // 0 ��
    FEEDBACK_010 = SEPARATE_010;                            // 10 ��
    FEEDBACK_020 = SEPARATE_020;                            // 20 ��
    FEEDBACK_025 = SEPARATE_025;                            // 25 ��
    FEEDBACK_030 = SEPARATE_030;                            // 30 ��
    FEEDBACK_033 = SEPARATE_033;                            // 33 ��
    FEEDBACK_040 = SEPARATE_040;                            // 40 ��
    FEEDBACK_050 = SEPARATE_050;                            // 50 ��
    FEEDBACK_060 = SEPARATE_060;                            // 60 ��
    FEEDBACK_067 = SEPARATE_067;                            // 67 ��
    FEEDBACK_070 = SEPARATE_070;                            // 70 ��
    FEEDBACK_075 = SEPARATE_075;                            // 75 ��
    FEEDBACK_080 = SEPARATE_080;                            // 80 ��
    FEEDBACK_090 = SEPARATE_090;                            // 90 ��

    SPEED_100 = 65536;                                      // 100 ��
    SPEED_025 = SPEED_100 * 2500 div 10000;                 // 25 ��
    SPEED_033 = SPEED_100 * 3333 div 10000;                 // 33 ��
    SPEED_040 = SPEED_100 * 4000 div 10000;                 // 40 ��
    SPEED_050 = SPEED_100 * 5000 div 10000;                 // 50 ��
    SPEED_067 = SPEED_100 * 6667 div 10000;                 // 67 ��
    SPEED_075 = SPEED_100 * 7500 div 10000;                 // 75 ��
    SPEED_080 = SPEED_100 * 8000 div 10000;                 // 80 ��
    SPEED_090 = SPEED_100 * 9000 div 10000;                 // 90 ��
    SPEED_110 = SPEED_100 *  110 div   100;                 // 110 ��
    SPEED_125 = SPEED_100 *  125 div   100;                 // 125 ��
    SPEED_133 = SPEED_100 *  133 div   100;                 // 133 ��
    SPEED_150 = SPEED_100 *  150 div   100;                 // 150 ��
    SPEED_200 = SPEED_100 *  200 div   100;                 // 200 ��
    SPEED_250 = SPEED_100 *  250 div   100;                 // 250 ��
    SPEED_300 = SPEED_100 *  300 div   100;                 // 300 ��
    SPEED_400 = SPEED_100 *  400 div   100;                 // 400 ��

    AMP_100 = 65536;                                        // 100 ��
    AMP_025 = AMP_100 * 2500 div 10000;                     // 25 ��
    AMP_033 = AMP_100 * 3333 div 10000;                     // 33 ��
    AMP_040 = AMP_100 * 4000 div 10000;                     // 40 ��
    AMP_050 = AMP_100 * 5000 div 10000;                     // 50 ��
    AMP_067 = AMP_100 * 6667 div 10000;                     // 67 ��
    AMP_075 = AMP_100 * 7500 div 10000;                     // 75 ��
    AMP_080 = AMP_100 * 8000 div 10000;                     // 80 ��
    AMP_090 = AMP_100 * 9000 div 10000;                     // 90 ��
    AMP_110 = AMP_100 *  110 div   100;                     // 110 ��
    AMP_125 = AMP_100 *  125 div   100;                     // 125 ��
    AMP_133 = AMP_100 *  133 div   100;                     // 133 ��
    AMP_150 = AMP_100 *  150 div   100;                     // 150 ��
    AMP_200 = AMP_100 *  200 div   100;                     // 200 ��
    AMP_250 = AMP_100 *  250 div   100;                     // 250 ��
    AMP_300 = AMP_100 *  300 div   100;                     // 300 ��
    AMP_400 = AMP_100 *  400 div   100;                     // 400 ��

    OPTION_ANALOG = $1;                                     // �A���`�G�C���A�X �t�B���^ (���g�p)
    OPTION_OLDSMP = $2;                                     // �Â��T���v�� �u���b�N�𓀃��\�b�h���g�p
    OPTION_SURROUND = $4;                                   // �t�ʑ��T���E���h����
    OPTION_REVERSE = $8;                                    // ���E���]
    OPTION_NOECHO = $10;                                    // �G�R�[����
    OPTION_NOPMOD = $20;                                    // �s�b�` ���W�����[�V��������
    OPTION_NOPREAD = $40;                                   // �s�b�` ���[�h����
    OPTION_NOFIR = $80;                                     // FIR �t�B���^����
    OPTION_BASSBOOST = $100;                                // BASS BOOST (�ቹ����)
    OPTION_NOENV = $200;                                    // �G���x���[�v����
    OPTION_NONOISE = $400;                                  // �m�C�Y����
    OPTION_ECHOMEMORY = $800;                               // DSP �̃G�R�[ ���������m��
    OPTION_NOSURROUND = $1000;                              // �T���E���h����
    OPTION_FLOATOUT = $40000000;                            // 32 �r�b�g (float) �ŏo�̓��x����ݒ�
    OPTION_NOEARSAFE = $80000000;                           // �C���[�Z�[�t����

    LOCALE_AUTO = 0;                                        // ����
    LOCALE_JA = 1;                                          // ���{��
    LOCALE_EN = 2;                                          // �p��

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
    MENU_SETUP_DEVICE_BASE = 1000; // +90 (ID �� 1099 �܂ŗ\��ς�)
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
    MENU_SETUP_RATE_VALUE: array[0..MENU_SETUP_RATE_SIZE - 1] of longword = (8000, 10000, 11025, 12000, 16000, 20000, 22050, 24000, 32000, 40000, 44100, 48000, 64000, 80000, 88200, 96000);
    MENU_SETUP_INTER = 30;
    MENU_SETUP_INTER_SIZE = 6;
    MENU_SETUP_INTER_BASE = 300;
    MENU_SETUP_INTER_VALUE: array[0..MENU_SETUP_INTER_SIZE - 1] of longword = (INTER_NONE, INTER_LINEAR, INTER_CUBIC, INTER_GAUSS, INTER_SINC, INTER_GAUSS4);
    MENU_SETUP_PITCH = 31;
    MENU_SETUP_PITCH_SIZE = 3;
    MENU_SETUP_PITCH_BASE = 310; // +20
    MENU_SETUP_PITCH_KEY = 338;
    MENU_SETUP_PITCH_KEY_SIZE = 6;
    MENU_SETUP_PITCH_KEY_BASE = MENU_SETUP_PITCH_BASE + MENU_SETUP_PITCH_SIZE;
    MENU_SETUP_PITCH_VALUE: array[0..MENU_SETUP_PITCH_SIZE + MENU_SETUP_PITCH_KEY_SIZE + MENU_SETUP_PITCH_KEY_SIZE] of longword = (PITCH_NORMAL, PITCH_OLDSBC, PITCH_OLDSNES, 45255, 42715, 40317, 38055, 35919, 33903, PITCH_NORMAL, 30204, 28509, 26909, 25398, 23973, 22627);
    MENU_SETUP_PITCH_ASYNC = 339;
    MENU_SETUP_SEPARATE = 34;
    MENU_SETUP_SEPARATE_SIZE = 15;
    MENU_SETUP_SEPARATE_BASE = 340; // +10
    MENU_SETUP_SEPARATE_VALUE: array[0..MENU_SETUP_SEPARATE_SIZE - 1] of longword = (SEPARATE_000, SEPARATE_010, SEPARATE_020, SEPARATE_025, SEPARATE_030, SEPARATE_033, SEPARATE_040, SEPARATE_050, SEPARATE_060, SEPARATE_067, SEPARATE_070, SEPARATE_075, SEPARATE_080, SEPARATE_090, SEPARATE_100);
    MENU_SETUP_FEEDBACK = 36;
    MENU_SETUP_FEEDBACK_SIZE = 15;
    MENU_SETUP_FEEDBACK_BASE = 360; // +10
    MENU_SETUP_FEEDBACK_VALUE: array[0..MENU_SETUP_FEEDBACK_SIZE - 1] of longword = (FEEDBACK_000, FEEDBACK_010, FEEDBACK_020, FEEDBACK_025, FEEDBACK_030, FEEDBACK_033, FEEDBACK_040, FEEDBACK_050, FEEDBACK_060, FEEDBACK_067, FEEDBACK_070, FEEDBACK_075, FEEDBACK_080, FEEDBACK_090, FEEDBACK_100);
    MENU_SETUP_SPEED = 38;
    MENU_SETUP_SPEED_SIZE = 17;
    MENU_SETUP_SPEED_BASE = 380; // +10
    MENU_SETUP_SPEED_VALUE: array[0..MENU_SETUP_SPEED_SIZE - 1] of longword = (SPEED_025, SPEED_033, SPEED_040, SPEED_050, SPEED_067, SPEED_075, SPEED_080, SPEED_090, SPEED_100, SPEED_110, SPEED_125, SPEED_133, SPEED_150, SPEED_200, SPEED_250, SPEED_300, SPEED_400);
    MENU_SETUP_AMP = 40;
    MENU_SETUP_AMP_SIZE = 17;
    MENU_SETUP_AMP_BASE = 400; // +10
    MENU_SETUP_AMP_VALUE: array[0..MENU_SETUP_AMP_SIZE - 1] of longword = (AMP_025, AMP_033, AMP_040, AMP_050, AMP_067, AMP_075, AMP_080, AMP_090, AMP_100, AMP_110, AMP_125, AMP_133, AMP_150, AMP_200, AMP_250, AMP_300, AMP_400);
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
    MENU_SETUP_OPTION_SIZE = 13;
    MENU_SETUP_OPTION_BASE = 500; // +10
    MENU_SETUP_OPTION_VALUE: array[0..MENU_SETUP_OPTION_SIZE - 1] of longword = (OPTION_ANALOG, OPTION_BASSBOOST, OPTION_OLDSMP, OPTION_REVERSE, OPTION_SURROUND, OPTION_NOSURROUND, OPTION_NOECHO, OPTION_NOPMOD, OPTION_NOPREAD, OPTION_NOFIR, OPTION_NOENV, OPTION_NONOISE, OPTION_ECHOMEMORY);
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
    MENU_SETUP_SEEK_SIZE = 5;
    MENU_SETUP_SEEK_BASE = 620; // +10
    MENU_SETUP_SEEK_VALUE: array[0..MENU_SETUP_SEEK_SIZE - 1] of longword = (1000, 2000, 3000, 4000, 5000);
    MENU_SETUP_INFO = 63;
    MENU_SETUP_INFO_SIZE = 9;
    MENU_SETUP_INFO_BASE = 630;
    MENU_SETUP_INFO_RESET = 629;
    MENU_SETUP_PRIORITY = 64;
    MENU_SETUP_PRIORITY_SIZE = 6;
    MENU_SETUP_PRIORITY_BASE = 640;
    MENU_SETUP_PRIORITY_VALUE: array[0..MENU_SETUP_PRIORITY_SIZE - 1] of longword = (REALTIME_PRIORITY_CLASS, HIGH_PRIORITY_CLASS, ABOVE_NORMAL_PRIORITY_CLASS, NORMAL_PRIORITY_CLASS, BELOW_NORMAL_PRIORITY_CLASS, IDLE_PRIORITY_CLASS);
    MENU_SETUP_TOPMOST = 650;
    MENU_LIST_PLAY = 700;
    MENU_LIST_PLAY_SELECT = 701;
    MENU_LIST_PLAY_SIZE = 6;
    MENU_LIST_PLAY_BASE = 702;
    MENU_LIST_PLAY_MAX = MENU_LIST_PLAY_BASE + MENU_LIST_PLAY_SIZE - 1;
    MENU_LIST_PLAY_VALUE: array[0..MENU_LIST_PLAY_SIZE - 1] of longword = (PLAY_ORDER_NEXT, PLAY_ORDER_PREVIOUS, PLAY_ORDER_RANDOM, PLAY_ORDER_SHUFFLE, PLAY_ORDER_FIRST, PLAY_ORDER_LAST);
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
    ID_BUTTON_TRACK: array[0..7] of longword = (ID_BUTTON_TRACK_BASE + 0, ID_BUTTON_TRACK_BASE + 1, ID_BUTTON_TRACK_BASE + 2, ID_BUTTON_TRACK_BASE + 3, ID_BUTTON_TRACK_BASE + 4, ID_BUTTON_TRACK_BASE + 5, ID_BUTTON_TRACK_BASE + 6, ID_BUTTON_TRACK_BASE + 7);
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

    STR_MENU_SETUP_SEPARATE_PER_INDEX: array[0..MENU_SETUP_SEPARATE_SIZE - 1] of longword = (0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14);
    STR_MENU_SETUP_SEPARATE_TIP_INDEX: array[0..MENU_SETUP_SEPARATE_SIZE - 1] of longword = (2, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 3);
    STR_MENU_SETUP_FEEDBACK_PER_INDEX: array[0..MENU_SETUP_FEEDBACK_SIZE - 1] of longword = (0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14);
    STR_MENU_SETUP_FEEDBACK_TIP_INDEX: array[0..MENU_SETUP_FEEDBACK_SIZE - 1] of longword = (1, NULL, NULL, NULL, NULL, NULL, NULL, 2, NULL, NULL, NULL, NULL, NULL, NULL, 4);
    STR_MENU_SETUP_SPEED_PER_INDEX:    array[0..MENU_SETUP_SPEED_SIZE - 1]    of longword = (3, 5, 6, 7, 9, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22);
    STR_MENU_SETUP_SPEED_TIP_INDEX:    array[0..MENU_SETUP_SPEED_SIZE - 1]    of longword = (5, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 6);
    STR_MENU_SETUP_AMP_PER_INDEX:      array[0..MENU_SETUP_AMP_SIZE - 1]      of longword = (3, 5, 6, 7, 9, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22);
    STR_MENU_SETUP_AMP_TIP_INDEX:      array[0..MENU_SETUP_AMP_SIZE - 1]      of longword = (7, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 8);
    STR_MENU_SETUP_PER_INTEGER: array[0..22] of longword = (0, 10, 20, 25, 30, 33, 40, 50, 60, 67, 70, 75, 80, 90, 100, 110, 125, 133, 150, 200, 250, 300, 400);

    ERROR_SNESAPU: array[0..1] of string = ('SNESAPU.DLL �̏������Ɏ��s���܂����B', 'Initializing SNESAPU.DLL is failed.');
    ERROR_CHECKSUM: array[0..1] of string = ('�A�v���P�[�V�����̋N���Ɏ��s���܂����B', 'Initializing application is failed.');
    ERROR_FILE_READ: array[0..1] of string = ('�t�@�C���̓ǂݍ��݂Ɏ��s���܂����B', 'Reading selected file is failed.');
    ERROR_FILE_WRITE: array[0..1] of string = ('�t�@�C���̏������݂Ɏ��s���܂����B', 'Writing selected file is failed.');
    ERROR_DEVICE: array[0..1] of string = ('�T�E���h �f�o�C�X�̏������Ɏ��s���܂����B', 'Initializing selected sound device is failed.');
    ERROR_CODE_1: array[0..1] of string = (CRLF + '(�G���[ ', CRLF + '(ERROR ');
    ERROR_CODE_2: array[0..1] of string = (')', ')');
    WARN_WAVE_SIZE_1: array[0..1] of string = (
        'WAVE �T�E���h �t�@�C�����쐬���܂���?' + CRLF + '�� �t�@�C�� �T�C�Y�͍ő�� ',
        'Do you want to create the WAVE file?' + CRLF + '* Maximum size of created file will be about ');
    WARN_WAVE_SIZE_2: array[0..1] of string = (
        'MB �ł��B' + CRLF + '�� �쐬����������܂Ŏ��Ԃ�������ꍇ������܂��B �쐬���͑���ł��܂���B',
        'MB.' + CRLF + '* Processing might take time until completed, and you cannot cancel processing.');
    INFO_WAVE_FINISH_1: array[0..1] of string = (
        'WAVE �T�E���h �t�@�C�����쐬���܂����B' + CRLF + '�� �t�@�C�� �T�C�Y�͖� ',
        'WAVE file was created successfully.' + CRLF + '* Size of file is about ');
    INFO_WAVE_FINISH_2: array[0..1] of string = (
        'MB �ł��B',
        'MB.');
    DIALOG_OPEN_FILTER: array[0..1] of string = (
        'SNES SPC700 �T�E���h (*.spc)' + NULLCHAR + '*.spc;*.sp0;*.sp1;*.sp2;*.sp3;*.sp4;*.sp5;*.sp6;*.sp7;*.sp8;*.sp9' + NULLCHAR +
        '�v���C���X�g (*.lst)' + NULLCHAR + '*.lst' + NULLCHAR +
        '���ׂĂ̑Ή��`���t�@�C��' + NULLCHAR + '*.spc;*.sp0;*.sp1;*.sp2;*.sp3;*.sp4;*.sp5;*.sp6;*.sp7;*.sp8;*.sp9;*.lst' + NULLCHAR +
        '���ׂẴt�@�C��' + NULLCHAR + '*.*' + NULLCHAR,
        'SNES SPC700 sound (*.spc)' + NULLCHAR + '*.spc;*.sp0;*.sp1;*.sp2;*.sp3;*.sp4;*.sp5;*.sp6;*.sp7;*.sp8;*.sp9' + NULLCHAR +
        'Playlist (*.lst)' + NULLCHAR + '*.lst' + NULLCHAR +
        'All Supported Files' + NULLCHAR + '*.spc;*.sp0;*.sp1;*.sp2;*.sp3;*.sp4;*.sp5;*.sp6;*.sp7;*.sp8;*.sp9;*.lst' + NULLCHAR +
        'All Files' + NULLCHAR + '*.*' + NULLCHAR);
    DIALOG_SCRIPT700_FILTER: array[0..1] of string = (
        'Script700 (*.700; *.7se)' + NULLCHAR + '*.700;*.7se;*.700.txt;*.7se.txt' + NULLCHAR,
        'Script700 (*.700; *.7se)' + NULLCHAR + '*.700;*.7se;*.700.txt;*.7se.txt' + NULLCHAR);
    DIALOG_OPEN_DEFAULT = 3;
    DIALOG_SAVE_FILTER: array[0..1] of string = (
        '�v���C���X�g (*.lst)' + NULLCHAR + '*.lst' + NULLCHAR,
        'Playlist (*.lst)' + NULLCHAR + '*.lst' + NULLCHAR);
    DIALOG_WAVE_FILTER: array[0..1] of string = (
        'WAVE �T�E���h (*.wav)' + NULLCHAR + '*.wav' + NULLCHAR,
        'WAVE Sound (*.wav)' + NULLCHAR + '*.wav' + NULLCHAR);
    DIALOG_SNAP_FILTER: array[0..1] of string = (
        '�X�i�b�v�V���b�g (*.spc)' + NULLCHAR + '*.spc' + NULLCHAR,
        'SPC Snapshot (*.spc)' + NULLCHAR + '*.spc' + NULLCHAR);
    DIALOG_SAVE_DEFAULT = 1;
    STR_MENU_FILE: array[0..1] of pchar = ('�t�@�C��(&F)', '&File');
    STR_MENU_SETUP: array[0..1] of pchar = ('�ݒ�(&S)', '&Settings');
    STR_MENU_LIST: array[0..1] of pchar = ('�v���C���X�g(&P)', '&Playlist');
    STR_MENU_FILE_EXIT: array[0..1] of pchar = ('�I��(&X)', 'E&xit');
    STR_MENU_SETUP_DEVICE: array[0..1] of pchar = ('�T�E���h �f�o�C�X(&D)', 'Sound &Devices');
    STR_MENU_SETUP_CHANNEL: array[0..1] of pchar = ('�`�����l��(&C)', '&Channels');
    STR_MENU_SETUP_BIT: array[0..1] of pchar = ('�r�b�g(&B)', '&Bit');
    STR_MENU_SETUP_RATE: array[0..1] of pchar = ('�T���v�����O ���[�g(&R)', 'Sampling &Rate');
    STR_MENU_SETUP_INTER: array[0..1] of pchar = ('��ԏ���(&I)', '&Interpolation');
    STR_MENU_SETUP_PITCH: array[0..1] of pchar = ('�s�b�`(&P)', '&Pitch');
    STR_MENU_SETUP_PITCH_KEY: array[0..1] of pchar = ('�����L�[(&K)', '&Key Shift');
    STR_MENU_SETUP_PITCH_PLUS: array[0..1] of string = ('�{&', '+ &');
    STR_MENU_SETUP_PITCH_MINUS: array[0..1] of string = ('�|&', '- &');
    STR_MENU_SETUP_PITCH_ZERO: pchar = ' &0 ';
    STR_MENU_SETUP_PITCH_ASYNC: array[0..1] of pchar = ('��ɉ��t���x�Ɠ���(&A)', '&Always Sync Speed');
    STR_MENU_SETUP_SEPARATE: array[0..1] of pchar = ('���E�g�U�x(&E)', 'Stereo S&eparator');
    STR_MENU_SETUP_FEEDBACK: array[0..1] of pchar = ('�t�B�[�h�o�b�N���]�x(&F)', 'Echo &Feedback');
    STR_MENU_SETUP_SPEED: array[0..1] of pchar = ('���t���x(&S)', '&Speed');
    STR_MENU_SETUP_AMP: array[0..1] of pchar = ('����(&V)', '&Volume');
    STR_MENU_SETUP_MUTE: array[0..1] of pchar = ('�`�����l�� �~���[�g(&M)', 'Channel &Mute');
    STR_MENU_SETUP_NOISE: array[0..1] of pchar = ('�`�����l�� �m�C�Y(&N)', 'Channel &Noise');
    STR_MENU_SETUP_SWITCH_CHANNEL: array[0..1] of pchar = ('�`�����l�� ', 'Channel ');
    STR_MENU_SETUP_OPTION: array[0..1] of pchar = ('�g���ݒ�(&X)', 'E&xpansion Flags');
    STR_MENU_SETUP_TIME: array[0..1] of pchar = ('���t����(&T)', 'Play &Time');
    STR_MENU_SETUP_TIME_DISABLE: array[0..1] of pchar = ('����(&D)', '&Disable');
    STR_MENU_SETUP_TIME_ID666: array[0..1] of pchar = ('&ID666 �ݒ�l���g�p', 'Enable &ID666 Time');
    STR_MENU_SETUP_TIME_DEFAULT: array[0..1] of pchar = ('�f�t�H���g�l���g�p(&E)', '&Enable Default Time');
    STR_MENU_SETUP_TIME_START: array[0..1] of pchar = ('�J�n�ʒu��ݒ�(&S)', 'Set &Start Position Mark');
    STR_MENU_SETUP_TIME_LIMIT: array[0..1] of pchar = ('�I���ʒu��ݒ�(&L)', 'Set &Limit Position Mark');
    STR_MENU_SETUP_TIME_RESET: array[0..1] of pchar = ('�ʒu�����Z�b�g(&R)', '&Reset Position Marks');
    STR_MENU_SETUP_ORDER: array[0..1] of pchar = ('���t����(&O)', 'Play &Order');
    STR_MENU_SETUP_INFO: array[0..1] of pchar = ('���\��(&A)', 'I&nformation Viewer');
    STR_MENU_SETUP_INFO_RESET: array[0..1] of pchar = ('�����`�����l����\��(&H)', '&Hide Muted Channels');
    STR_MENU_SETUP_SEEK: array[0..1] of pchar = ('�V�[�N����(&K)', 'See&k Time');
    STR_MENU_SETUP_PRIORITY: array[0..1] of pchar = ('�����D��x(&U)', 'CP&U Priority');
    STR_MENU_SETUP_TOPMOST: array[0..1] of pchar = ('��Ɏ�O�ɕ\��(&W)', 'Al&ways on Top');
    STR_MENU_LIST_PLAY: array[0..1] of pchar = ('���t�J�n(&P)', '&Play');
    STR_MENU_LIST_PLAY_SELECT: array[0..1] of pchar = ('�I������(&S)', '&Selected Item');
    STR_MENU_FILE_OPEN_SUB: array[0..1] of array[0..MENU_FILE_OPEN_SIZE - 1] of pchar = (
        ('�J��(&O)...', '�ۑ�(&S)...'),
        ('&Open...', '&Save...'));
    STR_MENU_FILE_PLAY_SUB: array[0..1] of array[0..MENU_FILE_PLAY_SIZE - 1] of pchar = (
        ('���t�J�n(&P)', '�ꎞ��~(&P)', '�ŏ����牉�t(&R)', '���t��~(&T)'),
        ('&Play', '&Pause', '&Restart', 'S&top'));
    STR_MENU_SETUP_MUTE_NOISE_ALL_SUB: array[0..1] of array[0..MENU_SETUP_MUTE_NOISE_ALL_SIZE - 1] of pchar = (
        ('���ׂăI��(&E)', '���ׂăI�t(&D)', '���ׂĔ��](&R)'),
        ('&Enable All', '&Disable All', '&Reverse All'));
    STR_MENU_LIST_EDIT_SUB: array[0..1] of array[0..MENU_LIST_EDIT_SIZE - 1] of pchar = (
        ('�ǉ�(&A)', '�}��(&I)', '�폜(&R)', '�N���A(&C)'),
        ('&Append', '&Insert', '&Remove', '&Clear'));
    STR_MENU_LIST_MOVE_SUB: array[0..1] of array[0..MENU_LIST_MOVE_SIZE - 1] of pchar = (
        ('���(&U)', '����(&D)'),
        ('Move &Up', 'Move &Down'));
    STR_MENU_SETUP_TIP: array[0..1] of array[0..8] of pchar = (
        ('', '�m�W���n', '�m�����n', '�m�g�U�n', '�m���]�n', '�m�x�n', '�m���n', '�m���n', '�m��n'),
        ('', '[Normal]', '[Mix]', '[Separate]', '[Reverse]', '[Slow]', '[Fast]', '[Down]', '[Up]'));
    STR_MENU_SETUP_CHANNEL_SUB: array[0..1] of array[0..MENU_SETUP_CHANNEL_SIZE - 1] of pchar = (
        ('&1 �`�����l��  (���m����)', '&2 �`�����l��  (�X�e���I)'),
        ('&1 Channel  (Monaural)', '&2 Channels  (Stereo)'));
    STR_MENU_SETUP_BIT_SUB: array[0..1] of array[0..MENU_SETUP_BIT_SIZE - 1] of pchar = (
        ('&8 �r�b�g', Concat('&16 �r�b�g', #9, '�m�W���n'), '&24 �r�b�g', '&32 �r�b�g  (int)', Concat('&32 �r�b�g  (float)', #9, '�m�������n')),
        ('&8-Bit', Concat('&16-Bit', #9, '[Normal]'), '&24-Bit', '&32-Bit  (int)', Concat('&32-Bit  (float)', #9, '[HQ]')));
    STR_MENU_SETUP_RATE_SUB: array[0..1] of array[0..MENU_SETUP_RATE_SIZE - 1] of pchar = (
        ('&8,000 Hz', '&10,000 Hz', '&11,025 Hz', '&12,000 Hz', '&16,000 Hz', '&20,000 Hz', '&22,050 Hz', '&24,000 Hz', Concat('&32,000 Hz', #9, '�m�����n'), '&40,000 Hz', '&44,100 Hz', '&48,000 Hz', '&64,000 Hz', '&80,000 Hz', '&88,200 Hz', '&96,000 Hz'),
        ('&8,000 Hz', '&10,000 Hz', '&11,025 Hz', '&12,000 Hz', '&16,000 Hz', '&20,000 Hz', '&22,050 Hz', '&24,000 Hz', Concat('&32,000 Hz', #9, '[Recommend]'), '&40,000 Hz', '&44,100 Hz', '&48,000 Hz', '&64,000 Hz', '&80,000 Hz', '&88,200 Hz', '&96,000 Hz'));
    STR_MENU_SETUP_INTER_SUB: array[0..1] of array[0..MENU_SETUP_INTER_SIZE - 1] of pchar = (
        ('����(&D)', '���`���(&L)', '�O���X�v���C�����(&C)', Concat('���@�K�E�X���z���(&G)', #9, '�m�W���n'), Concat('�V���N�֐����(&S)', #9, '�m�������n'), '�K�E�X�֐����(&A)'),
        ('&Disable', '&Liner', '&Cubic Spline', Concat('SNES &Gauss Table', #9, '[Normal]'), Concat('&Sinc Function', #9, '[HQ]'), 'G&auss Function'));
    STR_MENU_SETUP_PITCH_SUB: array[0..1] of array[0..MENU_SETUP_PITCH_SIZE - 1] of pchar = (
        ('�W��(&N)', '�ߋ��� &Sound Blaster �݊�', '�ߋ��� &ZSNES, Snes9x �݊�'),
        ('&Normal', 'OLD &Sound Blaster Card', 'OLD &ZSNES, Snes9x'));
    STR_MENU_SETUP_OPTION_SUB: array[0..1] of array[0..MENU_SETUP_OPTION_SIZE - 1] of pchar = (
        ('���@���[�p�X �t�B���^(&L)', '&BASS BOOST', '�ߋ��� &ADPCM ���g�p', '���E���](&R)', '�t�ʑ��T���E���h����(&S)', '�T���E���h����(&U)', '�G�R�[����(&E)', '�s�b�` ���W�����[�V��������(&P)', '�s�b�` �x���h����(&I)', '&FIR �t�B���^����', '�G���x���[�v����(&V)', '�m�C�Y�w�薳��(&N)', '�G�R�[��ƃ���������(&M)'),
        ('SNES &Low-Pass Filter', '&BASS BOOST', 'Old &ADPCM Emulation', '&Reverse Stereo', 'Opposite-Phase &Surround', 'Disable S&urround', 'Disable &Echo', 'Disable &Pitch Modulation', 'Disable P&itch Bend', 'Disable &FIR Filter', 'Disable En&velope', 'Disable &Noise Flags', 'Rewrite Echo Work &Memory'));
    STR_MENU_SETUP_ORDER_SUB: array[0..1] of array[0..MENU_SETUP_ORDER_SIZE - 1] of pchar = (
        ('���t��~(&S)', '����(&N)', '�O��(&P)', '�����_��(&M)', '�V���b�t��(&H)', '���s�[�g(&R)'),
        ('&Stop', '&Next Item', '&Previous Item', 'Rando&m', 'S&huffle', '&Repeat'));
    STR_MENU_SETUP_INFO_SUB: array[0..1] of array[0..MENU_SETUP_INFO_SIZE - 1] of pchar = (
        ('�O���t�B�b�N �C���W�P�[�^(&G)', '�~�L�T�[���(&M)', '�`�����l����� 1 (&C)', '�`�����l����� 2 (&A)', '�`�����l����� 3 (&N)', '�`�����l����� 4 (&E)', '&SPC ��� 1', 'S&PC ��� 2', 'Script&700 �f�o�b�O'),
        ('&Graphic Indicator', '&Mixer', '&Channel 1', 'Ch&annel 2', 'Cha&nnel 3', 'Chann&el 4', '&SPC Tags 1', 'S&PC Tags 2', 'Script&700 Debug'));
    STR_MENU_SETUP_SEEK_SUB: array[0..1] of array[0..MENU_SETUP_SEEK_SIZE - 1] of pchar = (
        ('&1 �b', '&2 �b', '&3 �b', '&4 �b', '&5 �b'),
        ('&1 s', '&2 s', '&3 s', '&4 s', '&5 s'));
    STR_MENU_SETUP_PRIORITY_SUB: array[0..1] of array[0..MENU_SETUP_PRIORITY_SIZE - 1] of pchar = (
        ('���A���^�C��(&R)', '��(&H)', '�W���ȏ�(&A)', '�W��(&N)', '�W���ȉ�(&B)', '��(&L)'),
        ('&Realtime', '&High', '&Above Normal', '&Normal', '&Below Normal', '&Low'));
    STR_MENU_LIST_PLAY_SUB: array[0..1] of array[0..MENU_LIST_PLAY_SIZE - 1] of pchar = (
        ('����(&N)', '�O��(&P)', '�����_��(&M)', '�V���b�t��(&H)', '�ŏ�����(&F)', '�Ōォ��(&L)'),
        ('&Next Item', '&Previous Item', 'Rando&m', 'S&huffle', '&First Item', '&Last Item'));
    STR_MENU_SETUP_PERCENT: array[0..1] of string = ('��', '%');
    STR_MENU_SETUP_SEC1: array[0..1] of string = ('�b', 's');
    STR_MENU_SETUP_SEC2: array[0..1] of string = ('sec', 's  ');
    STR_MENU_SETUP_MSEC: array[0..1] of string = ('ms', 'ms');
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
    STR_BUTTON_UP: array[0..1] of pchar = ('��', 'UP');
    STR_BUTTON_DOWN: array[0..1] of pchar = ('��', 'DN');
    TITLE_NAME_UNKNOWN = 'Unknown';
    TITLE_NAME_SEPARATOR: array[0..1] of string = (' �^ ', ' / ');
    TITLE_NAME_HEADER: array[0..1] of string = ('�m', ' [');
    TITLE_NAME_FOOTER: array[0..1] of string = ('�n', ']');
    TITLE_MAIN_HEADER: array[0..1] of string = (' - ', ' - ');
    TITLE_INFO_HEADER: array[0..1] of string = ('�s ', '< ');
    TITLE_INFO_FOOTER: array[0..1] of string = (' �t', ' >');
    TITLE_INFO_SEPARATE_HEADER: array[0..1] of string = ('���E�g�U�x ', 'Separate ');
    TITLE_INFO_FEEDBACK_HEADER: array[0..1] of string = ('�t�B�[�h�o�b�N���]�x ', 'Echo Feedback ');
    TITLE_INFO_SPEED_HEADER: array[0..1] of string = ('���t���x ', 'Speed ');
    TITLE_INFO_AMP_HEADER: array[0..1] of string = ('���� ', 'Volume ');
    TITLE_INFO_SEEK_HEADER: array[0..1] of string = ('�V�[�N ', 'Seek ');
    TITLE_INFO_PLUS: array[0..1] of string = ('�{', '+');
    TITLE_INFO_MINUS: array[0..1] of string = ('�|', '-');
    TITLE_INFO_FILE_APPEND: array[0..1] of string = ('�t�@�C���Ǎ���... ', 'Loading... ');
    TITLE_INFO_FILE_HEADER: array[0..1] of string = ('�t�@�C���쐬��... ', 'Storing... ');
    TITLE_INFO_FILE_PROC: array[0..1] of string = (' ������', '% completed');


// *************************************************************************************************************************************************************
// �O���[�o���ϐ��̐錾
// *************************************************************************************************************************************************************

var
    Apu: TAPU;                                              // APU
    Spc: TSPC;                                              // SPC
    Wave: record                                            // �����f�[�^
        dwEmuSize: longword;                                    // �G�~�����[�g �T�C�Y
        dwBufSize: longword;                                    // �o�b�t�@ �T�C�Y
        lpData: array of pointer;                               // �o�b�t�@�̃|�C���^
        dwHandle: longword;                                     // �f�o�C�X �n���h��
        Format: TWAVEFORMATEXTENSIBLE;                          // �t�H�[�}�b�g
        Header: array of TWAVEHDR;                              // �w�b�_
        Apu: array of TAPUDATA;                                 // APU �f�[�^
        dwTimeout: array[0..7] of longword;                     // �C���W�P�[�^ ���Z�b�g �^�C���A�E�g �o�b�t�@
        dwIndex: longword;                                      // APU �f�[�^ �C���f�b�N�X
        dwLastIndex: longword;                                  // APU �f�[�^�Ō�̃C���f�b�N�X
    end;
    Status: record                                          // �X�e�[�^�X
        ccClass: CCLASS;                                        // �E�B���h�E �N���X�̃N���X
        cfMain: CWINDOWMAIN;                                    // ���C�� �E�B���h�E �N���X
        hInstance: longword;                                    // �C���X�^���X �n���h��
        OsVersionInfo: TOSVERSIONINFO;                          // �V�X�e�� �o�[�W�������
        dwLanguage: longword;                                   // ����
        hDCStatic: longword;                                    // ���\���E�B���h�E �f�o�C�X �R���e�L�X�g �n���h��
        hDCVolumeBuffer: longword;                              // �C���W�P�[�^ �f�o�C�X �R���e�L�X�g �n���h��
        hBitmapVolume: longword;                                // �C���W�P�[�^ �r�b�g�}�b�v �n���h��
        hDCStringBuffer: longword;                              // �����摜�f�o�C�X �R���e�L�X�g �n���h��
        hBitmapString: longword;                                // �����摜�r�b�g�}�b�v �n���h��
        lpStaticProc: pointer;                                  // ���\���E�B���h�E �v���V�[�W���̃|�C���^
        dwThreadHandle: longword;                               // �X���b�h �n���h��
        dwThreadID: longword;                                   // �X���b�h ID
        dwThreadStatus: longword;                               // �X���b�h���
        dwThreadIdle: longword;                                 // �X���b�h �A�C�h�� �J�E���g
        dwWaveMessage: longword;                                // ���b�Z�[�W���M�ς݃J�E���g
        bOpen: longbool;                                        // Open �t���O
        bPlay: longbool;                                        // Play �t���O
        bPause: longbool;                                       // Pause �t���O
        lpCurrentPath: pointer;                                 // �J�����g �p�X
        lpCurrentSize: longword;                                // �J�����g �p�X�̃T�C�Y
        lpSPCFile: pointer;                                     // SPC �t�@�C�� �p�X
        lpSPCDir: pointer;                                      // SPC �f�B���N�g�� �p�X
        lpSPCName: pointer;                                     // SPC �t�@�C����
        lpOpenPath: pointer;                                    // �t�@�C���Ǎ��t�H���_ �o�b�t�@
        lpSavePath: pointer;                                    // �t�@�C���ۑ��t�H���_ �o�b�t�@
        dwFocusHandle: longword;                                // �t�H�[�J�X �n���h��
        dwDeviceNum: longword;                                  // �f�o�C�X��
        dwAPUPlayTime: longword;                                // �Đ�����
        dwAPUFadeTime: longword;                                // �t�F�[�h�A�E�g����
        dwDefaultTimeout: longword;                             // ���̋ȂɈڂ鎞��
        dwNextTimeout: longword;                                // ���̋ȂɈڂ鎞�� (�ݒ�)
        dwMuteTimeout: longword;                                // ���̋ȂɈڂ鎞�� (����)
        dwMuteCounter: longword;                                // ���̋ȂɈڂ铮����֎~����J�E���^
        dwNextCache: longword;                                  // ���̃L���b�V������
        bNextDefault: longbool;                                 // �f�t�H���g�̎��Ԃ��g�p
        bSPCRestart: longbool;                                  // �ŏ����牉�t
        bSPCRefresh: longbool;                                  // ���t��Ԃ�������
        bShiftButton: longbool;                                 // Shift
        bCtrlButton: longbool;                                  // Ctrl
        bBreakButton: longbool;                                 // Break
        bChangePlay: longbool;                                  // ���t�ύX�t���O
        bChangeShift: longbool;                                 // Shift �L�[�ύX�t���O
        bChangeBreak: longbool;                                 // Break �L�[�ύX�t���O
        bOptionLock: longbool;                                  // �I�v�V���� ���b�N
        bWaveWrite: longbool;                                   // WAVE �������݃t���O
        dwTitle: longword;                                      // �^�C�g�� �t���O
        dwInfo: longint;                                        // ���t���O
        dwRedrawInfo: longword;                                 // �ĕ`��t���O
        dwMenuFlags: longword;                                  // �I�����ꂽ���j���[���
        dwLastTime: longword;                                   // �Ō�̉��t����
        bTimeRepeat: longbool;                                  // ��ԃ��s�[�g�t���O
        dwPlayOrder: longword;                                  // ��ԃ��s�[�g����O�̉��t����
        dwStartTime: longword;                                  // ���s�[�g�J�n�ʒu
        dwLastStartTime: longword;                              // �Ō�̃��s�[�g�J�n�ʒu
        dwLimitTime: longword;                                  // ���s�[�g�I���ʒu
        dwLastLimitTime: longword;                              // �Ō�̃��s�[�g�I���ʒu
        dwOpenFilterIndex: longint;                             // �t�@�C�� �^�C�v�̃C���f�b�N�X (Open)
        dwSaveFilterIndex: longint;                             // �t�@�C�� �^�C�v�̃C���f�b�N�X (Save)
        DragPoint: TPOINT;                                      // �h���b�O�J�n�ʒu
        bDropCancel: longbool;                                  // �h���b�v�֎~�t���O
        dwScale: longint;                                       // �\���{��
        BreakPoint: array[0..65535] of byte;                    // �u���C�N �|�C���g �X�C�b�`
        dwNextTick: longword;                                   // ���̖��ߎ��s�X�C�b�`
        DSPCheat: array[0..127] of word;                        // DSP �`�[�g
        bEmuDebug: longbool;                                    // �]���e�X�g ���[�h
        NowLevel: TLEVEL;                                       // ���݂̃��x��
        LastLevel: TLEVEL;                                      // �Ō�̃��x��
        NumCache: array[0..287] of byte;                        // �f�W�^�������L���b�V�� (48x6)
        SPCCache: array of TSPCCACHE;                           // �V�[�N �L���b�V��
        Script700: TSCRIPT700DATA;                              // Script700 �f�[�^
{$IFDEF CONTEXT}
        dwContextSize: longword;                                // SNESAPU �R���e�L�X�g�T�C�Y
        lpContext: pointer;                                     // SNESAPU �R���e�L�X�g�f�[�^�̃|�C���^
{$ENDIF}
{$IFDEF ITASKBARLIST3}
        ITaskbarList3: TITASKBARLIST3;                          // ITaskbarList3 �C���^�[�t�F�C�X
{$ENDIF}
    end;
    Option: record                                          // �I�v�V����
        dwAmp: longword;                                        // ����
        dwBit: longint;                                         // �r�b�g
        dwBufferNum: longword;                                  // �o�b�t�@��
        dwBufferTime: longword;                                 // �o�b�t�@����
        dwChannel: longword;                                    // �`�����l��
        dwDeviceID: longint;                                    // �f�o�C�X ID
        dwDrawInfo: longword;                                   // ���`��t���O
        dwFadeTime: longword;                                   // �f�t�H���g �t�F�[�h�A�E�g����
        dwFeedback: longword;                                   // �t�B�[�h�o�b�N���]�x
        sFontName: string;                                      // �t�H���g��
        dwHideTime: longword;                                   // �f�t�H���g ���Z�b�g����
        dwInfo: longword;                                       // ���\��
        dwInter: longword;                                      // ��ԏ���
        dwLanguage: longword;                                   // ����
        dwListHeight: longword;                                 // �v���C���X�g�̍���
        dwListMax: longint;                                     // �v���C���X�g�o�^�ő匏��
        dwMute: longword;                                       // �`�����l�� �}�X�N
        dwNextTime: longword;                                   // �f�t�H���g�؂�ւ�����
        dwNoise: longword;                                      // �`�����l�� �m�C�Y
        dwOption: longword;                                     // �g���ݒ�
        dwPitch: longword;                                      // �s�b�`
        bPitchAsync: longbool;                                  // ��ɉ��t���x�Ɠ���
        bPlayDefault: longbool;                                 // ��Ƀf�t�H���g�l���g�p
        dwPlayTime: longword;                                   // �f�t�H���g���t����
        bPlayTime: longbool;                                    // ���t����
        dwPlayOrder: longword;                                  // ���t����
        dwPriority: longword;                                   // ��{�D��x
        dwRate: longword;                                       // �T���v�����O ���[�g
        dwScale: longint;                                       // �\���{��
        dwSeekFast: longword;                                   // �����V�[�N
        dwSeekInt: longword;                                    // �V�[�N �L���b�V���ۑ��Ԋu
        dwSeekMax: longword;                                    // �V�[�N�\����
        dwSeekNum: longword;                                    // �V�[�N �L���b�V����
        dwSeekTime: longword;                                   // �V�[�N����
        dwSeparate: longword;                                   // ���E�g�U�x
        dwSpeedBas: longword;                                   // ���t���x
        dwSpeedTun: longint;                                    // ���t���x������
        bTopMost: longbool;                                     // ��Ɏ�O�ɕ\��
        dwVolumeColor: longword;                                // �C���W�P�[�^�̐F
        bVolumeReset: longbool;                                 // �����`�����l����\��
        dwVolumeSpeed: longword;                                // �C���W�P�[�^�̌������x
        dwWaitTime: longword;                                   // �f�t�H���g �E�F�C�g����
        dwWaveBlank: longint;                                   // WAVE �̍ŏ��̋󔒎���
        dwWaveFormat: longword;                                 // WAVE �t�H�[�}�b�g
    end;
    CriticalSectionThread: TCRITICALSECTION;                // �X���b�h �N���e�B�J�� �Z�N�V����
    CriticalSectionStatic: TCRITICALSECTION;                // ���\���E�B���h�E �N���e�B�J�� �Z�N�V����
    KSDATAFORMAT_SUBTYPE_IEEE_FLOAT: TGUID;                 // KSDATAFORMAT_SUBTYPE_IEEE_FLOAT
    KSDATAFORMAT_SUBTYPE_PCM: TGUID;                        // KSDATAFORMAT_SUBTYPE_PCM
    IID_IDropSource: TGUID;                                 // IID_IDropSource
    IID_IDataObject: TGUID;                                 // IID_IDataObject
    IID_IUnknown: TGUID;                                    // IID_IUnknown
{$IFDEF ITASKBARLIST3}
    CLSID_TaskbarList: TGUID;                               // CLSID_TaskbarList
    IID_ITaskbarList3: TGUID;                               // IID_ITaskbarList3
{$ENDIF}


// *************************************************************************************************************************************************************
// Win32 API �̐錾
// *************************************************************************************************************************************************************

function  API_AppendMenu(hMenu: longword; uFlags: longword; uIDNewItem: longword; lpNewItem: pointer): longbool; stdcall; external 'user32.dll' name 'AppendMenuA';
function  API_BitBlt(hdcDest: longword; nXDest: longint; nYDest: longint; nWidthDest: longint; nHeightDest: longint; hdcSrc: longword; nXSrc: longint; nYSrc: longint; dwRop: longword): longbool; stdcall; external 'gdi32.dll' name 'BitBlt';
function  API_CallWindowProc(lpPrevWndFunc: pointer; hWnd: longword; msg: longword; wParam: longword; lParam: longword): longword; stdcall; external 'user32.dll' name 'CallWindowProcA';
function  API_CheckMenuItem(hMenu: longword; uID: longword; uCheck: longword): longword; stdcall; external 'user32.dll' name 'CheckMenuItem';
function  API_CloseHandle(hObject: longword): longbool; stdcall; external 'kernel32.dll' name 'CloseHandle';
{$IFDEF ITASKBARLIST3}
function  API_CoCreateInstance(rclsid: pointer; pUnkOuter: pointer; dwClsContext: longword; riid: pointer; ppv: pointer): longword; stdcall; external 'ole32.dll' name 'CoCreateInstance';
function  API_CoInitialize(pvReserved: pointer): longword; stdcall; external 'ole32.dll' name 'CoInitialize';
function  API_CoUninitialize(): longword; stdcall; external 'ole32.dll' name 'CoUninitialize';
{$ENDIF}
function  API_CreateBitmap(nWidth: longint; nHeight: longint; nPlanes: longint; nBitCount: longint; lpBits: pointer): longword; stdcall; external 'gdi32.dll' name 'CreateBitmap';
function  API_CreateCompatibleBitmap(hDC: longword; nWidth: longint; nHeight: longint): longword; stdcall; external 'gdi32.dll' name 'CreateCompatibleBitmap';
function  API_CreateCompatibleDC(hDC: longword): longword; stdcall; external 'gdi32.dll' name 'CreateCompatibleDC';
function  API_CreateFile(lpFileName: pointer; dwDesiredAccess: longword; dwShareMode: longword; lpSecurityAttributes: pointer; dwCreationDisposition: longword; dwFlagsAndAttributes: longword; hTemplateFile: longword): longword; stdcall; external 'kernel32.dll' name 'CreateFileA';
function  API_CreateFont(nHeight: longint; nWidth: longint; nEscapement: longint; nOrientation: longint; fnWeight: longint; fdwItalic: longword; fdwUnderline: longword; fdwStrikeOut: longword; fdwCharSet: longword; fdwOutputPrecision: longword; fdwClipPrecision: longword; fdwQuality: longword; fdwPitchAndFamily: longword; lpszFace: pointer): longword; stdcall; external 'gdi32.dll' name 'CreateFontA';
function  API_CreateMenu(): longword; stdcall; external 'user32.dll' name 'CreateMenu';
function  API_CreatePopupMenu(): longword; stdcall; external 'user32.dll' name 'CreatePopupMenu';
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
function  API_GetSystemMenu(hWnd: longword; bRevert: longbool): longword; stdcall; external 'user32.dll' name 'GetSystemMenu';
function  API_GetSystemMetrics(nIndex: longint): longint; stdcall; external 'user32.dll' name 'GetSystemMetrics';
function  API_GetVersionEx(lpVersionInfo: pointer): longbool; stdcall; external 'kernel32.dll' name 'GetVersionExA';
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
function  API_LoadLibrary(lpLibFileName: pointer): longword; stdcall; external 'kernel32.dll' name 'LoadLibraryA';
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
function  API_RegisterClassEx(lpwcx: pointer): smallint; stdcall; external 'user32.dll' name 'RegisterClassExA';
function  API_ReleaseDC(hWnd: longword; hDC: longword): longint; stdcall; external 'user32.dll' name 'ReleaseDC';
function  API_SelectObject(hDC: longword; hGdiObj: longword): longword; stdcall; external 'gdi32.dll' name 'SelectObject';
function  API_SendMessage(hWnd: longword; msg: longword; wParam: longword; lParam: longword): longword; stdcall; external 'user32.dll' name 'SendMessageA';
function  API_SetBkColor(hDC: longword; crColor: longword): longword; stdcall; external 'gdi32.dll' name 'SetBkColor';
function  API_SetEndOfFile(hFile: longword): longbool; stdcall; external 'kernel32.dll' name 'SetEndOfFile';
function  API_SetFilePointer(hFile: longword; lDistanceToMove: longword; lpDistanceToMoveHigh: pointer; dwMoveMethod: longword): longword; stdcall; external 'kernel32.dll' name 'SetFilePointer';
function  API_SetFocus(hWnd: longword): longword; stdcall; external 'user32.dll' name 'SetFocus';
function  API_SetForegroundWindow(hWnd: longword): longbool; stdcall; external 'user32.dll' name 'SetForegroundWindow';
function  API_SetMenu(hWnd: longword; hMenu: longword): longbool; stdcall; external 'user32.dll' name 'SetMenu';
function  API_SetPixel(hDC: longword; x: longint; y: longint; crColor: longword): longword; stdcall; external 'gdi32.dll' name 'SetPixel';
function  API_SetPriorityClass(hProcess: longword; dwPriorityClass: longword): longbool; stdcall; external 'kernel32.dll' name 'SetPriorityClass';
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


// *************************************************************************************************************************************************************
// �O���g���R�[�h
// *************************************************************************************************************************************************************

// ================================================================================
// API_TransparentBlt - TransparentBlt �� 32bit �J���[�Ή���
// ================================================================================
procedure API_TransparentBlt(hdcDest: longword; nXDest: longint; nYDest: longint; nWidthDest: longint; nHeightDest: longint; hdcSrc: longword; nXSrc: longint; nYSrc: longint; nWidthSrc: longint; nHeightSrc: longint; crTransparent: longword);
var
    hDCMaskBase: longword;
    hBitmapMaskBase: longword;
    hDCMaskDest: longword;
    hBitmapMaskDest: longword;
    dwOriginalColor: longword;
begin
    // �f�o�C�X �R���e�L�X�g���쐬
    hDCMaskBase := API_CreateCompatibleDC(hdcDest);
    hBitmapMaskBase := API_SelectObject(hDCMaskBase, API_CreateBitmap(nWidthDest, nHeightDest, 1, 1, NULLPOINTER));
    hDCMaskDest := API_CreateCompatibleDC(hdcDest);
    hBitmapMaskDest := API_SelectObject(hDCMaskDest, API_CreateCompatibleBitmap(hdcDest, nWidthDest, nHeightDest));
    // ���ߐF�����������ĉ摜���R�s�[
    API_StretchBlt(hDCMaskDest, 0, 0, nWidthDest, nHeightDest, hdcSrc, 0, 0, nWidthSrc, nHeightSrc, SRCCOPY);
    dwOriginalColor := API_SetBkColor(hDCMaskDest, crTransparent);
    API_BitBlt(hDCMaskBase, 0, 0, nWidthDest, nHeightDest, hDCMaskDest, 0, 0, SRCCOPY);
    API_SetBkColor(hDCMaskDest, dwOriginalColor);
    API_BitBlt(hdcDest, 0, 0, nWidthDest, nHeightDest, hDCMaskBase, 0, 0, SRCAND);
    API_BitBlt(hDCMaskBase, 0, 0, nWidthDest, nHeightDest, hDCMaskBase, 0, 0, NOTSRCCOPY);
    API_BitBlt(hDCMaskDest, 0, 0, nWidthDest, nHeightDest, hDCMaskBase, 0, 0, SRCAND);
    API_BitBlt(hdcDest, nXDest, nYDest, nWidthDest, nHeightDest, hDCMaskDest, 0, 0, SRCPAINT);
    // �f�o�C�X �R���e�L�X�g���폜
    API_DeleteObject(API_SelectObject(hDCMaskBase, hBitmapMaskBase));
    API_DeleteDC(hDCMaskBase);
    API_DeleteObject(API_SelectObject(hDCMaskDest, hBitmapMaskDest));
    API_DeleteDC(hDCMaskDest);
    // GDI �`����t���b�V��
    API_GdiFlush();
end;

// ================================================================================
// Exists - �t�H���_�E�t�@�C�����݃`�F�b�N
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
// IntToHex - ���l�𕶎���ɕϊ�
// ================================================================================
function IntToHex(var StrData: TSTRDATA; X: longword; Len: longword): longword;
var
    I: longword;
begin
    result := Len;
    I := Len;
    StrData.qwData := $3030303030303030; // '00000000'
    while longbool(I) and longbool(X) do begin
        Dec(I);
        StrData.cData[I] := HexTable[X and $F];
        X := X shr 4;
    end;
end;

// ================================================================================
// IntToStr - ���l�𕶎���ɕϊ�
// ================================================================================
function IntToStr(var StrData: TSTRDATA; X: longword; Len: longword): longword; overload;
var
    I: longword;
begin
    result := Len;
    I := Len;
    StrData.qwData := $3030303030303030; // '00000000'
    while longbool(I) and longbool(X) do begin
        Dec(I);
        StrData.cData[I] := HexTable[X mod 10];
        X := X div 10;
    end;
end;

// ================================================================================
// IntToStr - ���l�𕶎���ɕϊ�
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
// IntToStr - ���l�𕶎���ɕϊ�
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
// IsEqualsGUID - GUID ��r
// ================================================================================
function IsEqualsGUID(S: TGUID; D: TGUID): longbool;
var
    I: longint;
begin
    result := true;
    for I := 0 to 3 do if S.DataX[I] <> D.DataX[I] then result := false;
end;

// ================================================================================
// IsSingleByte - 1 �o�C�g������r
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
// IsPathSeparator - �t�@�C�� �p�X�̋�؂蕶�����r
// ================================================================================
function IsPathSeparator(const S: string; X: longword): longbool;
begin
    result := IsSingleByte(S, X, '\') or IsSingleByte(S, X, '/');
end;

// ================================================================================
// GetPosSeparator - �Ōオ��؂蕶���̈ʒu���擾
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
// Log10 - Log ���v�Z
// ================================================================================
function Log10(X: double): double;
begin
    result := Ln(X) * 0.43429448190325182765112891891661; // Ln(X) / Ln(10)
end;

// ================================================================================
// Max - A, B �̂����傫���l���擾
// ================================================================================
function Max(A: longint; B: longint): longint;
begin
    if A > B then result := A else result := B;
end;

// ================================================================================
// Min - A, B �̂����������l���擾
// ================================================================================
function Min(A: longint; B: longint): longint;
begin
    if A < B then result := A else result := B;
end;

// ================================================================================
// StrToInt - ������𐔒l�ɕϊ�
// ================================================================================
function StrToInt(const S: string; Default: longint): longint; overload;
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
            result := Default;
            exit;
        end;
    end;
    if Sign then result := -result;
end;

// ================================================================================
// StrToInt - ������𐔒l�ɕϊ�
// ================================================================================
function StrToInt(const S: string; Default: longword): longword; overload;
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
            result := Default;
            exit;
        end;
    end;
end;

// ================================================================================
// Trim - �󔒏���
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
// ���C�� �v���V�[�W��
// *************************************************************************************************************************************************************

// ================================================================================
// WriteLog - �f�o�b�O ���O�o��
// ================================================================================
{$IFDEF DEBUGLOG}
procedure _WriteLog(S: string);
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
// SNESAPUCallback - SNESAPU �R�[���o�b�N
// ================================================================================
function _SNESAPUCallback(dwEffect: longword; dwAddr: longword; dwValue: longword; lpData: pointer): longword; stdcall;

procedure IncludeScript700File(dwAddr: longword);
var
    I: longword;
    J: longword;
    cfMain: CWINDOWMAIN;
    lpBuffer: pointer;
begin
    cfMain := Status.cfMain;
    // �o�b�t�@�̃T�C�Y���擾
    I := cfMain.GetSize(Status.lpSPCDir, 1024);
    J := cfMain.GetSize(lpData, 1024);
    if I + J > 1024 then exit;
    // �o�b�t�@���m��
    GetMem(lpBuffer, 1024);
    // �J�����g �f�B���N�g�����R�s�[
    API_ZeroMemory(lpBuffer, 1024);
    API_MoveMemory(lpBuffer, Status.lpSPCDir, I);
    API_MoveMemory(pointer(longword(lpBuffer) + I), lpData, J);
    // Script700 �����[�h
    cfMain.LoadScript700(lpBuffer, dwAddr);
    // �o�b�t�@�����
    FreeMem(lpBuffer, 1024);
end;

begin
    result := dwValue;
    case dwEffect of
        CBE_INCS700: IncludeScript700File(SCRIPT700_TEXT); // #include Script700 text
        CBE_INCDATA: IncludeScript700File(dwAddr); // #include Script700 binary
        CBE_DSPREG: begin
            if longbool(Status.DSPCheat[dwAddr and $7F]) then result := Status.DSPCheat[dwAddr and $7F] and $FF;
{$IFDEF DEBUGLOG}
            _WriteLog(Concat('DSP   : ', IntToStr(dwAddr), ' ', IntToStr(dwValue), ' ', IntToStr(longword(lpData))));
{$ENDIF}
        end;
        CBE_S700FCH: begin
            if longbool(Status.dwNextTick and BRKP_NEXT_STOP) then Status.dwNextTick := (Status.dwNextTick and $FF) or BRKP_STOPPED
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
// WindowProc - �E�B���h�E �v���V�[�W��
// ================================================================================
function _WindowProc(hWnd: longword; msg: longword; wParam: longword; lParam: longword): longword; stdcall;
var
    dwDef: longword;
begin
    // ���b�Z�[�W����
    dwDef := 0;
    result := Status.cfMain.WindowProc(hWnd, msg, wParam, lParam, dwDef);
    if not longbool(dwDef) then result := API_DefWindowProc(hWnd, msg, wParam, lParam);
end;

// ================================================================================
// WinMain - �E�B���h�E ���C���֐�
// ================================================================================
function _WinMain(hThisInstance: longword; hPrevInstance: longword; lpArgs: pointer; nCmdShow: longint): longword; stdcall;
var
    cfMain: CWINDOWMAIN;
    cwWindowMain: CWINDOW;
    dwFlag: longword;
    bTransmitMsg: longbool;
    Msg: TMSG;
    dwKeyCode: longword;
begin
    // wParam ��������
    Msg.wParam := 0;
    // �N���e�B�J�� �Z�N�V�������쐬
    API_InitializeCriticalSection(@CriticalSectionThread);
    API_InitializeCriticalSection(@CriticalSectionStatic);
    // �E�B���h�E �N���X���쐬
    Status.ccClass := CCLASS.Create();
    Status.ccClass.CreateClass(@_WindowProc, hThisInstance, pchar(CLASS_NAME), CS_HREDRAW or CS_VREDRAW or CS_OWNDC, pchar(ICON_NAME), NULLPOINTER, IDC_ARROW, COLOR_BTNFACE);
    // �E�B���h�E���쐬
    cfMain := CWINDOWMAIN.Create();
    Status.cfMain := cfMain;
    dwFlag := cfMain.CreateWindow(hThisInstance, pchar(CLASS_NAME), lpArgs);
    // �N���ɐ��������ꍇ
    if not longbool(dwFlag) then begin
        // �E�B���h�E���擾
        cwWindowMain := cfMain.cwWindowMain;
        // ���b�Z�[�W���󂯎��܂őҋ@����B WM_QUIT �̏ꍇ�̓��[�v�𔲂���
        while API_GetMessage(@Msg, NULL, NULL, NULL) do begin
            // ������
            bTransmitMsg := true;
            // ���b�Z�[�W����
            case Msg.msg of
                WM_SYSKEYDOWN: begin // Alt �L�[ + �C�ӂ̃L�[
                    dwKeyCode := Msg.wParam and $FF;
                    case dwKeyCode of
                        VK_UP: cfMain.ListUp(); // Alt + �� �L�[
                        VK_DOWN: cfMain.ListDown(); // Alt + �� �L�[
                        VK_LEFT: cfMain.SetFunction(-1, FUNCTION_TYPE_AMP); // Alt + �� �L�[
                        VK_RIGHT: cfMain.SetFunction(1, FUNCTION_TYPE_AMP); // Alt + �� �L�[
                    end;
                end;
                WM_KEYDOWN: begin // �C�ӂ̃L�[
                    // ���b�Z�[�W��]�����Ȃ�
                    bTransmitMsg := false;
                    // Ctrl �L�[��������Ă���ꍇ
                    dwKeyCode := Msg.wParam and $FF;
                    if Status.bCtrlButton then case dwKeyCode of
                        VK_B: cfMain.ListNextPlay(PLAY_ORDER_NEXT, LIST_NEXT_PLAY_SELECT); // Ctrl + B �L�[
                        VK_C: cfMain.SPCPlay(PLAY_TYPE_PAUSE); // Ctrl + C �L�[
                        VK_O: cwWindowMain.PostMessage(WM_APP_COMMAND, MENU_FILE_OPEN, Msg.lParam); // Ctrl + O �L�[
                        VK_P: cfMain.SPCPlay(PLAY_TYPE_AUTO); // Ctrl + P �L�[
                        VK_Q: cwWindowMain.PostMessage(WM_QUIT, NULL, NULL); // Ctrl + Q �L�[
                        VK_R: cfMain.SPCStop(true); // Ctrl + R �L�[
                        VK_S: cwWindowMain.PostMessage(WM_APP_COMMAND, MENU_FILE_SAVE, Msg.lParam); // Ctrl + S �L�[
                        VK_T, VK_V: cfMain.SPCStop(false); // Ctrl + T, V �L�[
                        VK_X: cfMain.SPCPlay(PLAY_TYPE_PLAY); // Ctrl + X �L�[
                        VK_Z: cfMain.ListNextPlay(PLAY_ORDER_PREVIOUS, LIST_NEXT_PLAY_SELECT); // Ctrl + Z �L�[
                        VK_OEM_COMMA: cwWindowMain.PostMessage(WM_APP_COMMAND, MENU_SETUP_TIME_START, Msg.lParam); // Ctrl + , �L�[
                        VK_OEM_PERIOD: cwWindowMain.PostMessage(WM_APP_COMMAND, MENU_SETUP_TIME_LIMIT, Msg.lParam); // Ctrl + . �L�[
                        VK_OEM_2: cwWindowMain.PostMessage(WM_APP_COMMAND, MENU_SETUP_TIME_RESET, Msg.lParam); // Ctrl + / �L�[
                        VK_DELETE: cfMain.ListClear(); // Ctrl + Del �L�[
                        VK_UP: cfMain.ListUp(); // Ctrl + �� �L�[
                        VK_DOWN: cfMain.ListDown(); // Ctrl + �� �L�[
                        VK_LEFT: cfMain.SetFunction(-1, FUNCTION_TYPE_SPEED); // Ctrl + �� �L�[
                        VK_RIGHT: cfMain.SetFunction(1, FUNCTION_TYPE_SPEED); // Ctrl + �� �L�[
                        VK_RETURN: cfMain.SPCPlay(PLAY_TYPE_RANDOM); // Ctrl + Enter �L�[
{$IFDEF CONTEXT}
                        VK_OEM_PLUS: begin // Ctrl + ; �L�[
                            // �N���e�B�J�� �Z�N�V�������J�n
                            API_EnterCriticalSection(@CriticalSectionStatic);
                            // SNESAPU �R���e�L�X�g�����
                            if longbool(Status.lpContext) then FreeMem(Status.lpContext, Status.dwContextSize);
                            // SNESAPU �R���e�L�X�g���擾
                            Status.dwContextSize := Apu.GetSNESAPUContextSize();
                            cwWindowMain.SetCaption(pchar(IntToStr(Status.dwContextSize)));
                            GetMem(Status.lpContext, Status.dwContextSize);
                            cwWindowMain.SetCaption(pchar(IntToStr(longword(Status.lpContext))));
                            Apu.GetSNESAPUContext(Status.lpContext);
                            // �N���e�B�J�� �Z�N�V�������I��
                            API_LeaveCriticalSection(@CriticalSectionStatic);
                        end;
                        VK_OEM_1: begin // Ctrl + : �L�[
                            // �N���e�B�J�� �Z�N�V�������J�n
                            API_EnterCriticalSection(@CriticalSectionStatic);
                            // SNESAPU �R���e�L�X�g��ݒ�
                            if longbool(Status.lpContext) then Apu.SetSNESAPUContext(Status.lpContext);
                            // �N���e�B�J�� �Z�N�V�������I��
                            API_LeaveCriticalSection(@CriticalSectionStatic);
                        end;
{$ENDIF}
                        else Msg.wParam := Msg.wParam or $100;
                    end;
                    // �L�[ �}�b�v����������
                    if not Status.bCtrlButton and Status.bShiftButton then case dwKeyCode of
                        VK_UP: dwKeyCode := VK_NUMPAD8; // �� �L�[
                        VK_DOWN: dwKeyCode := VK_NUMPAD2; // �� �L�[
                    end;
                    // �L�[����������Ă��Ȃ��ꍇ
                    if not Status.bCtrlButton or longbool(Msg.wParam and $100) then case dwKeyCode of
                        VK_ESCAPE: cwWindowMain.PostMessage(WM_APP_MESSAGE, WM_APP_MINIMIZE, NULL); // ESC �L�[
                        VK_TAB: cfMain.SetTabFocus(Msg.hWnd, not Status.bShiftButton); // Tab �L�[
                        VK_SHIFT: cfMain.SetChangeFunction(true); // Shift �L�[
                        VK_CONTROL: Status.bCtrlButton := true; // Ctrl �L�[
                        VK_F1..VK_F9: begin // F1 �` F9 �L�[
                            // �`�����l�� �}�X�N��ݒ�
                            if dwKeyCode = VK_F9 then begin
                                if Status.bCtrlButton then Option.dwMute := $0
                                else Option.dwMute := Option.dwMute xor $FF;
                            end else begin
                                if Status.bCtrlButton then Option.dwMute := (1 shl (dwKeyCode - VK_F1)) xor $FF
                                else Option.dwMute := Option.dwMute xor (1 shl (dwKeyCode - VK_F1));
                            end;
                            // �ݒ�����Z�b�g
                            cfMain.SPCReset(false);
                        end;
                        VK_PAUSE: begin // Break/Pause �L�[
                            // �t���O��ݒ�
                            Status.bBreakButton := not Status.bBreakButton;
                            Status.bChangeBreak := true;
                            // �C���W�P�[�^���ĕ`��
                            cwWindowMain.PostMessage(WM_APP_MESSAGE, WM_APP_REDRAW, NULL);
                        end;
                        VK_INSERT: cfMain.ListAdd(0); // Insert �L�[
                        VK_DELETE: cfMain.ListDelete(); // Delete �L�[
                        VK_LEFT: if Status.bShiftButton then cfMain.SetFunction(-1, FUNCTION_TYPE_SEEK)
                            else cfMain.SetChangeInfo(false, -1); // �� �L�[
                        VK_RIGHT: if Status.bShiftButton then cfMain.SetFunction(1, FUNCTION_TYPE_SEEK)
                            else cfMain.SetChangeInfo(false, 1); // �� �L�[
                        VK_RETURN: if Status.bShiftButton then cfMain.SPCPlay(PLAY_TYPE_RANDOM)
                            else cfMain.SPCPlay(PLAY_TYPE_LIST); // Enter �L�[
                        VK_NUMPAD1, VK_NUMPAD3: cfMain.SetFunction(dwKeyCode - VK_NUMPAD2, FUNCTION_TYPE_SPEED); // �e���L�[ 1, 3
                        VK_NUMPAD2: cfMain.ListNextPlay(PLAY_ORDER_NEXT, LIST_NEXT_PLAY_SELECT); // �e���L�[ 2
                        VK_NUMPAD4, VK_NUMPAD6: cfMain.SetFunction(dwKeyCode - VK_NUMPAD5, FUNCTION_TYPE_SEEK); // �e���L�[ 4, 6
                        VK_NUMPAD5: cfMain.SPCPlay(PLAY_TYPE_AUTO); // �e���L�[ 5
                        VK_NUMPAD7, VK_NUMPAD9: cfMain.SetFunction(dwKeyCode - VK_NUMPAD8, FUNCTION_TYPE_SEPARATE); // �e���L�[ 7, 9
                        VK_NUMPAD8: cfMain.ListNextPlay(PLAY_ORDER_PREVIOUS, LIST_NEXT_PLAY_SELECT); // �e���L�[ 8
                        VK_NUMPAD0: cfMain.SPCStop(false); // �e���L�[ 0
                        VK_ADD, VK_SUBTRACT: cfMain.SetFunction($6C - dwKeyCode, FUNCTION_TYPE_AMP); // �e���L�[ +, -
                        VK_DIVIDE, VK_MULTIPLY: cfMain.SetFunction(1 - ((dwKeyCode and $1) shl 1), FUNCTION_TYPE_FEEDBACK); // �e���L�[ /, *
                        VK_DECIMAL: cfMain.SPCStop(true); // �e���L�[ .
                        VK_SPACE: bTransmitMsg := true; // Space �L�[
                        else if not Status.bCtrlButton then begin // ���̑��̃L�[ (�v���C���X�g��ő��삵���Ƃ��Ɠ����������s��)
                            Msg.hWnd := cfMain.cwPlayList.hWnd;
                            bTransmitMsg := true;
                        end;
                    end;
                    // wParam �𕜌�
                    Msg.wParam := dwKeyCode;
                end;
                WM_KEYUP: begin // �C�ӂ̃L�[
                    // �^�C�}�[������
                    if Status.bOptionLock then API_KillTimer(cwWindowMain.hWnd, TIMER_ID_OPTION_LOCK);
                    // �I�v�V�����ݒ胍�b�N������
                    Status.bOptionLock := false;
                    // �L�[�𔻕�
                    dwKeyCode := Msg.wParam and $FF;
                    case dwKeyCode of
                        VK_SHIFT: cfMain.SetChangeFunction(true); // Shift �L�[
                        VK_CONTROL: Status.bCtrlButton := false; // Ctrl �L�[
                    end;
                end;
                WM_LBUTTONDOWN, WM_LBUTTONDBLCLK: begin // ���{�^��
                    if Msg.hWnd = cfMain.cwStaticMain.hWnd then begin
                        if Status.bShiftButton then cwWindowMain.PostMessage(WM_APP_MESSAGE, WM_APP_START_TIME, Msg.lParam)
                        else cwWindowMain.PostMessage(WM_APP_MESSAGE, WM_APP_SEEK, Msg.lParam);
                    end else if Msg.hWnd = cfMain.cwPlayList.hWnd then begin
                        cfMain.DragFile(Msg.msg, Msg.wParam, Msg.lParam);
                    end;
                end;
                WM_RBUTTONDOWN, WM_RBUTTONDBLCLK: begin // �E�{�^��
                    if Msg.hWnd = cfMain.cwStaticMain.hWnd then begin
                        if Status.bShiftButton then cwWindowMain.PostMessage(WM_APP_MESSAGE, WM_APP_LIMIT_TIME, Msg.lParam)
                        else cwWindowMain.PostMessage(WM_APP_MESSAGE, WM_APP_SEEK, Msg.lParam);
                    end else if Msg.hWnd = cfMain.cwPlayList.hWnd then begin
                        cfMain.DragFile(Msg.msg, Msg.wParam, Msg.lParam);
                    end;
                    cfMain.SetChangeFunction(true);
                end;
                WM_RBUTTONUP: cfMain.SetChangeFunction(true); // �E�{�^��
                WM_XBUTTONDOWN, WM_XBUTTONDBLCLK: if Status.bShiftButton xor longbool(Msg.wParam and $40) then cfMain.SetChangeInfo(false, -1)
                    else cfMain.SetChangeInfo(false, 1); // �g���{�^��
                WM_MOUSEMOVE: if Msg.hWnd = cfMain.cwPlayList.hWnd then begin // �}�E�X�ړ�
                    cfMain.DragFile(Msg.msg, Msg.wParam, Msg.lParam);
                    Msg.msg := WM_LBUTTONUP; // �ړ����L�����Z��
                end;
                WM_MOUSEWHEEL: // �z�C�[���FCtrl �L�[��������Ă���ꍇ�͈ړ��A Ctrl �L�[��������Ă��Ȃ��ꍇ�̓X�N���[��
                    if Status.bCtrlButton then
                        if longbool(Msg.wParam and $80000000) then cfMain.ListDown()
                        else cfMain.ListUp()
                    else Msg.hWnd := cfMain.cwPlayList.hWnd;
            end;
            // ���b�Z�[�W��]������ꍇ
            if bTransmitMsg then begin
                // ���z�L�[ ���b�Z�[�W�𕶎����b�Z�[�W�ɕϊ�
                API_TranslateMessage(@Msg);
                // ���b�Z�[�W���E�B���h�E�ɑ��M
                API_DispatchMessage(@Msg);
            end;
        end;
        // �E�B���h�E���폜
        cfMain.DeleteWindow();
    end;
    // ���C�� �N���X�����
    cfMain.Free();
    // �E�B���h�E �N���X���폜
    Status.ccClass.DeleteClass(hThisInstance, pchar(CLASS_NAME));
    Status.ccClass.Free();
    // �N���e�B�J�� �Z�N�V�������폜
    API_DeleteCriticalSection(@CriticalSectionThread);
    API_DeleteCriticalSection(@CriticalSectionStatic);
    // wParam ��ԋp
    result := Msg.wParam;
end;

// ================================================================================
// StaticProc - ���x�� �v���V�[�W��
// ================================================================================
function _StaticProc(hWnd: longword; msg: longword; wParam: longword; lParam: longword): longword; stdcall;
begin
    // �V�X�e�����ĕ`����J�n����ꍇ
    if msg = WM_PAINT then begin
        // �N���e�B�J�� �Z�N�V�������J�n
        API_EnterCriticalSection(@CriticalSectionStatic);
        // �ĕ`������b�N (WM_PAINT ���ɓƎ��ŕ`�悷��ƃf�o�C�X �R���e�L�X�g���j�󂳂��)
        Status.dwRedrawInfo := Status.dwRedrawInfo or REDRAW_LOCK_CRITICAL or REDRAW_LOCK_READY;
        // �f�t�H���g�̃E�B���h�E �v���V�[�W�����Ăяo��
        result := API_CallWindowProc(Status.lpStaticProc, hWnd, msg, wParam, lParam);
        // �C���W�P�[�^�̍ĕ`���\��
        Status.cfMain.cwWindowMain.PostMessage(WM_APP_MESSAGE, WM_APP_REDRAW, NULL);
        // �ĕ`��̃��b�N���ꕔ����
        Status.dwRedrawInfo := Status.dwRedrawInfo xor REDRAW_LOCK_CRITICAL;
        // �N���e�B�J�� �Z�N�V�������I��
        API_LeaveCriticalSection(@CriticalSectionStatic);
    end else begin
        // �f�t�H���g�̃E�B���h�E �v���V�[�W�����Ăяo��
        result := API_CallWindowProc(Status.lpStaticProc, hWnd, msg, wParam, lParam);
    end;
end;

// ================================================================================
// WaveThread - �X���b�h �v���V�[�W��
// ================================================================================
function _WaveThread(lpData: longword): longint; stdcall;
var
    cfMain: CWINDOWMAIN;
    cwWindowMain: CWINDOW;
    Msg: TMSG;
begin
    // �E�B���h�E �n���h�����擾
    cfMain := Status.cfMain;
    cwWindowMain := cfMain.cwWindowMain;
    // ���b�Z�[�W �L���[���쐬
    API_PeekMessage(@Msg, NULL, WM_USER, WM_USER, NULL);
    // ��������
    Status.dwThreadStatus := WAVE_THREAD_RUNNING;
    // ���b�Z�[�W���󂯎��܂őҋ@����B WM_QUIT �̏ꍇ�̓��[�v�𔲂���
    while API_GetMessage(@Msg, NULL, NULL, NULL) do case Msg.msg of
        MM_WOM_DONE: begin // �f�o�C�X�̍Đ����I������
            // �N���e�B�J�� �Z�N�V�������J�n
            API_EnterCriticalSection(@CriticalSectionThread);
            // �f�o�C�X �v���V�[�W�����Ăяo��
            if Status.bPlay then begin
                cfMain.WaveProc(WAVE_PROC_WRITE_WAVE);
                if longbool(Status.dwWaveMessage) then begin
                    // ���t���b�V���p�̋󃁃b�Z�[�W�𑗐M (for wine)
                    cwWindowMain.PostMessage(WM_APP_MESSAGE, WM_APP_WAVE_PROC, NULL);
                    Dec(Status.dwWaveMessage);
                end;
            end else Dec(Status.dwThreadIdle);
            // �N���e�B�J�� �Z�N�V�������I��
            API_LeaveCriticalSection(@CriticalSectionThread);
        end;
        WM_APP_MESSAGE: case Msg.wParam of
            WM_APP_SPC_PLAY: begin // ���t�J�n
                // �N���e�B�J�� �Z�N�V�������J�n
                API_EnterCriticalSection(@CriticalSectionThread);
                // ���s�[�g�J�n�ʒu���ݒ肳��Ă���ꍇ�̓V�[�N
                if Status.bWaveWrite and Status.bTimeRepeat and longbool(Status.dwStartTime) then cfMain.SPCSeek(Status.dwStartTime, true);
                // ���t�J�n
                cfMain.WaveStart();
                // �N���e�B�J�� �Z�N�V�������I��
                API_LeaveCriticalSection(@CriticalSectionThread);
            end;
            WM_APP_SPC_PAUSE: if Status.bWaveWrite and cfMain.WavePause() then begin // �ꎞ��~
                // ���j���[���X�V
                cwWindowMain.PostMessage(WM_APP_MESSAGE, WM_APP_UPDATE_MENU, NULL);
                // �C���W�P�[�^�����Z�b�g
                cfMain.ResetInfo(true);
            end;
            WM_APP_SPC_RESUME: if Status.bWaveWrite and cfMain.WaveResume() then begin // ���t�ĊJ
                // ���j���[���X�V
                cwWindowMain.PostMessage(WM_APP_MESSAGE, WM_APP_UPDATE_MENU, NULL);
                // �C���W�P�[�^�����Z�b�g
                cfMain.ResetInfo(true);
            end;
            WM_APP_SPC_RESET: if Status.bWaveWrite then begin // ���t�ݒ�
                // �N���e�B�J�� �Z�N�V�������J�n
                API_EnterCriticalSection(@CriticalSectionThread);
                // SPC ���t�ݒ�
                cfMain.SPCOption();
                // �N���e�B�J�� �Z�N�V�������I��
                API_LeaveCriticalSection(@CriticalSectionThread);
            end;
            WM_APP_SPC_TIME: if Status.bWaveWrite then begin // ���Ԑݒ�
                // �N���e�B�J�� �Z�N�V�������J�n
                API_EnterCriticalSection(@CriticalSectionThread);
                // SPC ���t�ݒ�
                cfMain.SPCTime(false, false, true);
                // �N���e�B�J�� �Z�N�V�������I��
                API_LeaveCriticalSection(@CriticalSectionThread);
            end;
            WM_APP_SPC_SEEK, WM_APP_SPC_SEEK + 1: if Status.bWaveWrite then begin // �V�[�N
                // �N���e�B�J�� �Z�N�V�������J�n
                API_EnterCriticalSection(@CriticalSectionThread);
                // SPC �V�[�N
                cfMain.SPCSeek(Msg.lParam, longbool(Msg.wParam and $1));
                // �N���e�B�J�� �Z�N�V�������I��
                API_LeaveCriticalSection(@CriticalSectionThread);
            end;
        end;
        MM_WOM_OPEN: Status.dwThreadStatus := Status.dwThreadStatus or WAVE_THREAD_DEVICE_OPENED; // �f�o�C�X���I�[�v�����ꂽ
        MM_WOM_CLOSE: Status.dwThreadStatus := Status.dwThreadStatus or WAVE_THREAD_DEVICE_CLOSED; // �f�o�C�X���N���[�Y���ꂽ
    end;
    // �����I��
    Status.dwThreadStatus := WAVE_THREAD_SUSPEND;
    // wParam ��ԋp
    result := Msg.wParam;
end;

// ================================================================================
// OLEIDropSourceAddRef - IDropSource �C���^�[�t�F�C�X�Q��
// ================================================================================
function _OLEIDropSourceAddRef(lpDropSource: pointer): longword; stdcall;
var
    IDropSource: ^TIDROPSOURCE;
begin
    // �Q�ƃJ�E���g���C���N�������g
    IDropSource := lpDropSource;
    result := API_InterlockedIncrement(@IDropSource.dwRefCnt);
end;

// ================================================================================
// OLEIDropSourceRelease - IDropSource �C���^�[�t�F�C�X���
// ================================================================================
function _OLEIDropSourceRelease(lpDropSource: pointer): longword; stdcall;
var
    IDropSource: ^TIDROPSOURCE;
begin
    // �Q�ƃJ�E���g���f�N�������g
    IDropSource := lpDropSource;
    result := API_InterlockedDecrement(@IDropSource.dwRefCnt);
    // �Q�ƃJ�E���g�� 0 �łȂ��ꍇ�͏I��
    if longbool(result) then exit;
    // �����������
    API_GlobalFree(longword(IDropSource.lpVtbl));
    API_GlobalFree(longword(IDropSource));
end;

// ================================================================================
// OLEIDropSourceQueryInterface - IDropSource �C���^�[�t�F�C�X������
// ================================================================================
function _OLEIDropSourceQueryInterface(lpDropSource: pointer; priid: pointer; lplpDropSource: pointer): longword; stdcall;
var
    Guid: ^TGUID;
    DblPointer: ^TDBLPOINTER;
begin
    // ������
    Guid := priid;
    DblPointer := lplpDropSource;
    // �v�����ꂽ GUID ���m�F
    if IsEqualsGUID(Guid^, IID_IDropSource) or IsEqualsGUID(Guid^, IID_IUnknown) then begin
        // IDropSource �� GUID ��v�����ꂽ�ꍇ�̓N���X�̃|�C���^��ݒ�
        DblPointer.p := lpDropSource;
        _OLEIDropSourceAddRef(lpDropSource);
        result := S_OK;
    end else begin
        // ���̑��� GUID ��v�����ꂽ�ꍇ�͑��݂��Ȃ�����ݒ�
        DblPointer.p := NULLPOINTER;
        result := E_NOINTERFACE;
    end;
end;

// ================================================================================
// OLEIDropSourceQueryContinueDrag - �h���b�O���̑�����擾
// ================================================================================
function _OLEIDropSourceQueryContinueDrag(lpDropSource: pointer; fEscapePressed: longbool; dwKeyState: longword): longword; stdcall;
var
    dwKey: longword;
begin
    // ������
    dwKey := dwKeyState and (MK_LBUTTON or MK_RBUTTON);
    if fEscapePressed or (dwKey = (MK_LBUTTON or MK_RBUTTON)) then begin
        // �h���b�O���� ESC �L�[�������ꂽ�ꍇ�̓h���b�O���L�����Z��
        result := DRAGDROP_S_CANCEL;
    end else if not longbool(dwKey) then begin
        // �}�E�X�̃{�^�������ꂽ�ꍇ�̓h���b�v���s
        result := DRAGDROP_S_DROP;
    end else result := S_OK;
end;

// ================================================================================
// OLEIDropSourceGiveFeedback - �h���b�O���̃}�E�X �J�[�\���擾
// ================================================================================
function _OLEIDropSourceGiveFeedback(lpDropSource: pointer; dwEffect: longword): longword; stdcall;
begin
    // �f�t�H���g�̃J�[�\����ݒ�
    result := DRAGDROP_S_USEDEFAULTCURSORS;
end;

// ================================================================================
// OLEIDataObjectAddRef - IDataObject �C���^�[�t�F�C�X�Q��
// ================================================================================
function _OLEIDataObjectAddRef(lpDataObject: pointer): longword; stdcall;
var
    IDataObject: ^TIDATAOBJECT;
begin
    // �Q�ƃJ�E���g���C���N�������g
    IDataObject := lpDataObject;
    result := API_InterlockedIncrement(@IDataObject.dwRefCnt);
end;

// ================================================================================
// OLEIDataObjectRelease - IDataObject �C���^�[�t�F�C�X���
// ================================================================================
function _OLEIDataObjectRelease(lpDataObject: pointer): longword; stdcall;
var
    I: longint;
    J: longint;
    IDataObject: ^TIDATAOBJECT;
    SelfObject: ^TDROPOBJECT;
    ClearObject: ^TDROPOBJECT;
begin
    // �Q�ƃJ�E���g���f�N�������g
    IDataObject := lpDataObject;
    result := API_InterlockedDecrement(@IDataObject.dwRefCnt);
    // �Q�ƃJ�E���g�� 0 �łȂ��ꍇ�͏I��
    if longbool(result) then exit;
    // �����������
    for I := 0 to IDataObject.dwObjectCnt - 1 do begin
        SelfObject := @IDataObject.Objects[I];
        if SelfObject.fRelease then begin
            if longbool(SelfObject.FormatEtc) then API_GlobalFree(longword(SelfObject.FormatEtc));
            if longbool(SelfObject.StgMedium) then API_GlobalFree(longword(SelfObject.StgMedium));
        end;
        for J := I to IDataObject.dwObjectCnt - 1 do begin
            ClearObject := @IDataObject.Objects[J];
            if ClearObject.FormatEtc = SelfObject.FormatEtc then ClearObject.FormatEtc := NULLPOINTER;
            if ClearObject.StgMedium = SelfObject.StgMedium then ClearObject.StgMedium := NULLPOINTER;
        end;
    end;
    API_GlobalFree(longword(IDataObject.lpVtbl));
    API_GlobalFree(longword(IDataObject));
end;

// ================================================================================
// OLEIDataObjectQueryInterface - IDataObject �C���^�[�t�F�C�X������
// ================================================================================
function _OLEIDataObjectQueryInterface(lpDataObject: pointer; priid: pointer; lplpDataObject: pointer): longword; stdcall;
var
    Guid: ^TGUID;
    DblPointer: ^TDBLPOINTER;
begin
    // ������
    Guid := priid;
    DblPointer := lplpDataObject;
    // �v�����ꂽ GUID ���m�F
    if IsEqualsGUID(Guid^, IID_IDataObject) or IsEqualsGUID(Guid^, IID_IUnknown) then begin
        // IDataObject �� GUID ��v�����ꂽ�ꍇ�̓N���X�̃|�C���^��ݒ�
        DblPointer.p := lpDataObject;
        _OLEIDataObjectAddRef(lpDataObject);
        result := S_OK;
    end else begin
        // ���̑��� GUID ��v�����ꂽ�ꍇ�͑��݂��Ȃ�����ݒ�
        DblPointer.p := NULLPOINTER;
        result := E_NOINTERFACE;
    end;
end;

// ================================================================================
// _OLEIDataObjectCopyData - �h���b�O�Ώۃf�[�^ �R�s�[
// ================================================================================
function _OLEIDataObjectCopyData(lpDataObject: pointer; lpDestMedium: pointer; lpFormatEtc: pointer; lpSrcMedium: pointer): longword;
var
    FormatEtc: ^TFORMATETC;
    SrcStgMedium: ^TSTGMEDIUM;
    DestStgMedium: ^TSTGMEDIUM;
    handle: longword;
    IDataObjectUnk: ^TIDATAOBJECTVTBL;
    AddRef: function(lpDataObject: pointer): longword;
begin
    // ������
    FormatEtc := lpFormatEtc;
    DestStgMedium := lpDestMedium;
    SrcStgMedium := lpSrcMedium;
    // �t�H�[�}�b�g �^�C�v�� NULL �̏ꍇ�͏I��
    if not longbool(SrcStgMedium.tymed) then begin
        result := E_INVALIDARG;
        exit;
    end;
    // �f�[�^�̃C���X�^���X���R�s�[
    handle := API_OleDuplicateData(SrcStgMedium.handle, FormatEtc.cfFormat, GMEM_FIXED);
    // �C���X�^���X�̃R�s�[�Ɏ��s�����ꍇ�͏I��
    if not longbool(handle) then begin
        result := E_OUTOFMEMORY;
        exit;
    end;
    // �C���X�^���X�̃n���h����ݒ�
    DestStgMedium.handle := handle;
    // �t�H�[�}�b�g �f�[�^���R�s�[
    DestStgMedium.tymed := SrcStgMedium.tymed;
    DestStgMedium.pUnkForRelease := SrcStgMedium.pUnkForRelease;
    if longbool(DestStgMedium.pUnkForRelease) then begin
        IDataObjectUnk := DestStgMedium.pUnkForRelease;
        AddRef := IDataObjectUnk.OLEIDataObjectAddRef;
        AddRef(IDataObjectUnk);
    end;
    // �I��
    result := S_OK;
end;

// ================================================================================
// OLEIDataObjectGetData - �h���b�O�Ώۃf�[�^�擾 (�f�[�^�擾�����������m��)
// ================================================================================
function _OLEIDataObjectGetData(lpDataObject: pointer; lpFormatEtc: pointer; lpStgMedium: pointer): longword; stdcall;
var
    I: longint;
    IDataObject: ^TIDATAOBJECT;
    FormatEtc: ^TFORMATETC;
    SelfObject: ^TDROPOBJECT;
begin
    // �t�H�[�}�b�g��`�� NULL �̏ꍇ�͏I��
    if not longbool(lpFormatEtc) or not longbool(lpStgMedium) then begin
        result := E_INVALIDARG;
        exit;
    end;
    // �v�����ꂽ�t�H�[�}�b�g�����ߍ��݃I�u�W�F�N�g�łȂ��ꍇ�͏I��
    FormatEtc := lpFormatEtc;
    if not longbool(FormatEtc.dwAspect and DVASPECT_CONTENT) then begin
        result := DV_E_DVASPECT;
        exit;
    end;
    // �v�����ꂽ�t�H�[�}�b�g���z�肵�Ă���t�H�[�}�b�g������
    IDataObject := lpDataObject;
    SelfObject := NULLPOINTER;
    result := DV_E_FORMATETC;
    for I := 0 to IDataObject.dwObjectCnt - 1 do begin
        SelfObject := @IDataObject.Objects[I];
        if (FormatEtc.cfFormat = SelfObject.FormatEtc.cfFormat)
        and (FormatEtc.lindex = SelfObject.FormatEtc.lindex)
        and longbool(FormatEtc.dwAspect and SelfObject.FormatEtc.dwAspect)
        and longbool(FormatEtc.tymed and SelfObject.FormatEtc.tymed) then begin
            // �z�肵���t�H�[�}�b�g
            result := S_OK;
            break;
        end;
    end;
    // �t�H�[�}�b�g��������Ȃ������ꍇ�͏I��
    if result <> S_OK then exit;
    // �v�����ꂽ�f�[�^�̃C���X�^���X���R�s�[
    result := _OLEIDataObjectCopyData(lpDataObject, lpStgMedium, SelfObject.FormatEtc, SelfObject.StgMedium);
end;

// ================================================================================
// OLEIDataObjectGetDataHere - �h���b�O�Ώۃf�[�^�擾 (�f�[�^�񋟌����������m��)
// ================================================================================
function _OLEIDataObjectGetDataHere(lpDataObject: pointer; lpFormatEtc: pointer; lpStgMedium: pointer): longword; stdcall;
begin
    // ������
    result := E_NOTIMPL;
end;

// ================================================================================
// OLEIDataObjectQueryGetData - �h���b�O�Ώۃf�[�^ �t�H�[�}�b�g �`�F�b�N
// ================================================================================
function _OLEIDataObjectQueryGetData(lpDataObject: pointer; lpFormatEtc: pointer): longword; stdcall;
var
    I: longint;
    IDataObject: ^TIDATAOBJECT;
    FormatEtc: ^TFORMATETC;
    SelfObject: ^TDROPOBJECT;
begin
    // �t�H�[�}�b�g��`�� NULL �̏ꍇ�͏I��
    if not longbool(lpFormatEtc) then begin
        result := E_INVALIDARG;
        exit;
    end;
    // �v�����ꂽ�t�H�[�}�b�g�����ߍ��݃I�u�W�F�N�g�łȂ��ꍇ�͏I��
    FormatEtc := lpFormatEtc;
    if not longbool(FormatEtc.dwAspect and DVASPECT_CONTENT) then begin
        result := DV_E_DVASPECT;
        exit;
    end;
    // �v�����ꂽ�t�H�[�}�b�g���z�肵�Ă���t�H�[�}�b�g������
    IDataObject := lpDataObject;
    result := DV_E_FORMATETC;
    for I := 0 to IDataObject.dwObjectCnt - 1 do begin
        SelfObject := @IDataObject.Objects[I];
        if (FormatEtc.cfFormat = SelfObject.FormatEtc.cfFormat)
        and (FormatEtc.lindex = SelfObject.FormatEtc.lindex)
        and longbool(FormatEtc.dwAspect and SelfObject.FormatEtc.dwAspect)
        and longbool(FormatEtc.tymed and SelfObject.FormatEtc.tymed) then begin
            // �z�肵���t�H�[�}�b�g
            result := S_OK;
            break;
        end;
    end;
end;

// ================================================================================
// OLEIDataObjectGetCanonicalFormatEtc - �񋟌��ƌ݊����̂���t�H�[�}�b�g�̎擾
// ================================================================================
function _OLEIDataObjectGetCanonicalFormatEtc(lpDataObject: pointer; lpFormatEtcIn: pointer; lpFormatEtcOut: pointer): longword; stdcall;
begin
    // ������
    result := E_NOTIMPL;
end;

// ================================================================================
// OLEIDataObjectSetData - �h���b�O�Ώۃf�[�^�ݒ�
// ================================================================================
function _OLEIDataObjectSetData(lpDataObject: pointer; lpFormatEtc: pointer; lpStgMedium: pointer; fRelease: longbool): longword; stdcall;
var
    IDataObject: ^TIDATAOBJECT;
    SelfObject: ^TDROPOBJECT;
begin
    // �t�H�[�}�b�g��`�� NULL �̏ꍇ�͏I��
    if not longbool(lpFormatEtc) or not longbool(lpStgMedium) then begin
        result := E_INVALIDARG;
        exit;
    end;
    // �o�b�t�@ �T�C�Y���m�F
    IDataObject := lpDataObject;
    if IDataObject.dwObjectCnt >= longword(Length(IDataObject.Objects)) then begin
        result := E_OUTOFMEMORY;
        exit;
    end;
    // �t�H�[�}�b�g��`��ݒ�
    SelfObject := @IDataObject.Objects[IDataObject.dwObjectCnt];
    API_InterlockedIncrement(@IDataObject.dwObjectCnt);
    SelfObject.FormatEtc := lpFormatEtc;
    SelfObject.fRelease := fRelease;
    if fRelease then begin
        // �f�[�^���R�s�[���Ȃ�
        SelfObject.StgMedium := lpStgMedium;
        result := S_OK;
    end else begin
        // �v�����ꂽ�f�[�^�̃C���X�^���X���R�s�[
        result := _OLEIDataObjectCopyData(lpDataObject, SelfObject.StgMedium, lpFormatEtc, lpStgMedium);
    end;
end;

// ================================================================================
// OLEIDataObjectEnumFormatEtc - �񋟌����T�|�[�g����t�H�[�}�b�g�̗�
// ================================================================================
function _OLEIDataObjectEnumFormatEtc(lpDataObject: pointer; dwDirection: longword; lplpEnumFormatEtc: pointer): longword; stdcall;
begin
    // ������
    result := E_NOTIMPL;
end;

// ================================================================================
// OLEIDataObjectDAdvise - �擾���ƒ񋟌��̑��ݒʒm�ݒ�
// ================================================================================
function _OLEIDataObjectDAdvise(lpDataObject: pointer; lpFormatEtc: pointer; dwAdvf: longword; lpAdvSink: pointer; pdwConnection: pointer): longword; stdcall;
begin
    // ���T�|�[�g
    result := OLE_E_ADVISENOTSUPPORTED;
end;

// ================================================================================
// OLEIDataObjectDUnadvise - �擾���ƒ񋟌��̑��ݒʒm����
// ================================================================================
function _OLEIDataObjectDUnadvise(lpDataObject: pointer; dwConnection: longword): longword; stdcall;
begin
    // ���T�|�[�g
    result := OLE_E_ADVISENOTSUPPORTED;
end;

// ================================================================================
// OLEIDataObjectEnumDAdvise - �擾���ƒ񋟌��̑��ݒʒm��
// ================================================================================
function _OLEIDataObjectEnumDAdvise(lpDataObject: pointer; lplpEnumAdvise: pointer): longword; stdcall;
begin
    // ���T�|�[�g
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
// CLASS �N���X
// *************************************************************************************************************************************************************

// ================================================================================
// CreateClass - �N���X�쐬
// ================================================================================
procedure CCLASS.CreateClass(lpWindowProc: pointer; hThisInstance: longword; lpClassName: pointer; dwStyle: longword; lpIcon: pointer; lpSmallIcon: pointer; dwCursor: longword; dwBackColor: longword);
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
    if longbool(dwCursor) then WndClassEx.hCursor := API_LoadCursor(NULL, pointer(dwCursor));
    if longbool(dwBackColor) then WndClassEx.hbrBackground := dwBackColor + 1;
    if longbool(lpSmallIcon) then WndClassEx.hIconSm := API_LoadIcon(hThisInstance, lpSmallIcon);
    API_RegisterClassEx(@WndClassEx);
end;

// ================================================================================
// DeleteClass - �N���X�폜
// ================================================================================
procedure CCLASS.DeleteClass(hThisInstance: longword; lpClassName: pointer);
begin
    API_UnregisterClass(lpClassName, hThisInstance);
end;


// *************************************************************************************************************************************************************
// FONT �N���X
// *************************************************************************************************************************************************************

// ================================================================================
// CreateFont - �t�H���g�쐬
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
// DeleteFont - �t�H���g�폜
// ================================================================================
procedure CFONT.DeleteFont();
begin
    API_DeleteObject(hFont);
end;


// *************************************************************************************************************************************************************
// MENU �N���X
// *************************************************************************************************************************************************************

// ================================================================================
// AppendMenu - ���j���[���ڒǉ�
// ================================================================================
procedure CMENU.AppendMenu(dwID: longword; lpString: pointer);
begin
    API_AppendMenu(hMenu, MF_STRING, dwID, lpString);
end;

// ================================================================================
// AppendMenu - ���j���[���ڒǉ�
// ================================================================================
procedure CMENU.AppendMenu(dwID: longword; lpString: pointer; bRadio: longbool);
begin
    if bRadio then API_AppendMenu(hMenu, MF_STRING or MF_RADIOCHECK, dwID, lpString)
    else AppendMenu(dwID, lpString);
end;

// ================================================================================
// AppendMenu - ���j���[���ڒǉ�
// ================================================================================
procedure CMENU.AppendMenu(dwID: longword; lpString: pointer; hSubMenuID: longword);
begin
    API_AppendMenu(hMenu, MF_STRING or MF_POPUP, hSubMenuID, lpString);
end;

// ================================================================================
// AppendSeparator - ���j���[ �Z�p���[�^�ǉ�
// ================================================================================
procedure CMENU.AppendSeparator();
begin
    API_AppendMenu(hMenu, MF_SEPARATOR, NULL, NULLPOINTER);
end;

// ================================================================================
// CreateMenu - ���j���[�쐬
// ================================================================================
procedure CMENU.CreateMenu();
begin
    hMenu := API_CreateMenu();
end;

// ================================================================================
// CreatePopupMenu - �T�u ���j���[�쐬
// ================================================================================
procedure CMENU.CreatePopupMenu();
begin
    hMenu := API_CreatePopupMenu();
end;

// ================================================================================
// DeleteMenu - ���j���[�폜
// ================================================================================
procedure CMENU.DeleteMenu();
begin
    API_DestroyMenu(hMenu);
end;

// ================================================================================
// InsertMenu - ���j���[���ڒǉ�
// ================================================================================
procedure CMENU.InsertMenu(dwID: longword; dwPosition: longword; lpString: pointer);
begin
    API_InsertMenu(hMenu, dwPosition, MF_BYCOMMAND or MF_STRING, dwID, lpString);
end;

// ================================================================================
// InsertMenu - ���j���[���ڒǉ�
// ================================================================================
procedure CMENU.InsertMenu(dwID: longword; dwPosition: longword; lpString: pointer; bRadio: longbool);
begin
    if bRadio then API_InsertMenu(hMenu, dwPosition, MF_BYCOMMAND or MF_STRING or MF_RADIOCHECK, dwID, lpString)
    else InsertMenu(dwID, dwPosition, lpString);
end;

// ================================================================================
// InsertMenu - ���j���[���ڒǉ�
// ================================================================================
procedure CMENU.InsertMenu(dwID: longword; dwPosition: longword; lpString: pointer; hSubMenuID: longword);
begin
    API_InsertMenu(hMenu, dwPosition, MF_BYCOMMAND or MF_STRING or MF_POPUP, hSubMenuID, lpString);
end;

// ================================================================================
// InsertSeparator - ���j���[ �Z�p���[�^�ǉ�
// ================================================================================
procedure CMENU.InsertSeparator(dwPosition: longword);
begin
    API_InsertMenu(hMenu, dwPosition, MF_BYCOMMAND or MF_SEPARATOR, NULL, NULLPOINTER);
end;

// ================================================================================
// RemoveMenu - ���j���[���ڍ폜
// ================================================================================
procedure CMENU.RemoveItem(dwPosition: longword);
begin
    API_DeleteMenu(hMenu, dwPosition, MF_BYCOMMAND);
end;

// ================================================================================
// SetMenuCheck - ���j���[ �`�F�b�N�ݒ�
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
// SetMenuEnable - ���j���[�L���ݒ�
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
// WINDOW �N���X
// *************************************************************************************************************************************************************

// ================================================================================
// CreateItem - �E�B���h�E �A�C�e���쐬
// ================================================================================
procedure CWINDOW.CreateItem(hThisInstance: longword; hMainWnd: longword; hFont: longword; lpItemName: pointer; lpCaption: pointer; dwItemID: longword; dwStylePlus: longword; dwStyleExPlus: longword; Box: TBOX);
var
    dwStyle: longword;
    dwStyleEx: longword;
begin
    dwStyle := dwStylePlus or WS_CHILD;
    dwStyleEx := dwStyleExPlus;
    hWnd := API_CreateWindowEx(dwStyleEx, lpItemName, lpCaption, dwStyle, Box.left, Box.top, Box.width, Box.height, hMainWnd, dwItemID, hThisInstance, NULLPOINTER);
    SendMessage(WM_SETFONT, hFont, NULL);
end;

// ================================================================================
// CreateWindow - �E�B���h�E�쐬
// ================================================================================
procedure CWINDOW.CreateWindow(hThisInstance: longword; lpClassName: pointer; lpWndName: pointer; dwStylePlus: longword; dwStyleExPlus: longword; Box: TBOX);
var
    dwStyle: longword;
    dwStyleEx: longword;
begin
    dwStyle := dwStylePlus or WS_OVERLAPPED;
    dwStyleEx := dwStyleExPlus;
    hWnd := API_CreateWindowEx(dwStyleEx, lpClassName, lpWndName, dwStyle, Box.left, Box.top, Box.width, Box.height, NULL, NULL, hThisInstance, NULLPOINTER);
    bMessageBox := false;
end;

// ================================================================================
// DeleteWindow - �E�B���h�E�폜
// ================================================================================
procedure CWINDOW.DeleteWindow();
begin
    API_DestroyWindow(hWnd);
end;

// ================================================================================
// GetCaption - �L���v�V�����擾
// ================================================================================
function CWINDOW.GetCaption(lpCaption: pointer; nMaxCount: longint): longint;
begin
    result := API_GetWindowText(hWnd, lpCaption, nMaxCount);
end;

// ================================================================================
// GetSystemMenu - �V�X�e�� ���j���[�擾
// ================================================================================
function CWINDOW.GetSystemMenu(): CMENU;
begin
    result := CMENU.Create();
    result.hMenu := API_GetSystemMenu(hWnd, false);
end;

// ================================================================================
// GetWindowRect - �ʏ��Ԃ̃E�B���h�E �T�C�Y�擾
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
// GetWindowStyle - �E�B���h�E �X�^�C���擾
// ================================================================================
function CWINDOW.GetWindowStyle(): longword;
begin
    result := API_GetWindowLong(hWnd, GWL_STYLE);
end;

// ================================================================================
// GetWindowStyleEx - �g���E�B���h�E �X�^�C���擾
// ================================================================================
function CWINDOW.GetWindowStyleEx(): longword;
begin
    result := API_GetWindowLong(hWnd, GWL_EXSTYLE);
end;

// ================================================================================
// Invalidate - �E�B���h�E�`��\��
// ================================================================================
function CWINDOW.Invalidate(): longbool;
begin
    result := API_InvalidateRect(hWnd, NULLPOINTER, true);
end;

// ================================================================================
// MessageBox - ���b�Z�[�W �{�b�N�X�\��
// ================================================================================
function CWINDOW.MessageBox(lpText: pointer; lpCaption: pointer; uType: longword): longint;
begin
    bMessageBox := true;
    API_SetForegroundWindow(hWnd);
    result := API_MessageBox(hWnd, lpText, lpCaption, uType);
    bMessageBox := false;
end;

// ================================================================================
// PostMessage - �񓯊����b�Z�[�W���M
// ================================================================================
function CWINDOW.PostMessage(msg: longword; wParam: longword; lParam: longword): longbool;
begin
    result := API_PostMessage(hWnd, msg, wParam, lParam);
end;

// ================================================================================
// SendMessage - �������b�Z�[�W���M
// ================================================================================
function CWINDOW.SendMessage(msg: longword; wParam: longword; lParam: longword): longword;
begin
    result := API_SendMessage(hWnd, msg, wParam, lParam);
end;

// ================================================================================
// SetCaption - �L���v�V�����ݒ�
// ================================================================================
procedure CWINDOW.SetCaption(lpCaption: pointer);
begin
    API_SetWindowText(hWnd, lpCaption);
end;

// ================================================================================
// SetWindowEnable - �E�B���h�E�L���ݒ�
// ================================================================================
procedure CWINDOW.SetWindowEnable(bEnable: longbool);
begin
    API_EnableWindow(hWnd, bEnable);
end;

// ================================================================================
// SetWindowPosition - �E�B���h�E�ʒu�ݒ�
// ================================================================================
procedure CWINDOW.SetWindowPosition(nLeft: longint; nTop: longint; nWidth: longint; nHeight: longint);
begin
    API_SetWindowPos(hWnd, NULL, nLeft, nTop, nWidth, nHeight, SWP_NOACTIVATE or SWP_NOZODER);
end;

// ================================================================================
// SetWindowShowStyle - �E�B���h�E�\���X�^�C���ݒ�
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
// SetWindowTopMost - �E�B���h�E�őO�ʕ\���ݒ�
// ================================================================================
procedure CWINDOW.SetWindowTopMost(bTopMost: longbool);
var
    hWndInsertAfter: longword;
begin
    if bTopMost then hWndInsertAfter := HWND_TOPMOST else hWndInsertAfter := HWND_NOTOPMOST;
    API_SetWindowPos(hWnd, hWndInsertAfter, NULL, NULL, NULL, NULL, SWP_NOACTIVATE or SWP_NOMOVE or SWP_NOSIZE);
end;

// ================================================================================
// UpdateWindow - �E�B���h�E�X�V
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
// WINDOWMAIN �N���X
// *************************************************************************************************************************************************************

// ================================================================================
// AppendList - �v���C���X�g�o�^
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
    // �v���C���X�g�̃A�C�e�������擾
    dwFileCount := cwSortList.SendMessage(LB_GETCOUNT, NULL, NULL);
    // �v���C���X�g�ɃA�C�e�����o�^����Ă��Ȃ��ꍇ�͏I��
    if not longbool(dwFileCount) then exit;
    // �L�[�{�[�h�̏�Ԃ��擾 (Status.bShiftButton ���ł͏�Ԃ��擾�s��)
    API_GetKeyboardState(@KeyState);
    // �ĕ`��֎~
    cwPlayList.SendMessage(WM_SETREDRAW, 0, NULL);
    // Ctrl �L�[��������Ă���ꍇ
    if bytebool(KeyState.k[VK_CONTROL] and $80) then begin
        // �v���C���X�g�����ׂăN���A
        cwFileList.SendMessage(LB_RESETCONTENT, NULL, NULL);
        cwPlayList.SendMessage(LB_RESETCONTENT, NULL, NULL);
        // �I������Ă���A�C�e�����擾
        dwIndex := 0;
        dwCount := 0;
    end else begin
        // �I������Ă���A�C�e�����擾
        dwIndex := cwPlayList.SendMessage(LB_GETCURSEL, NULL, NULL);
        dwCount := cwPlayList.SendMessage(LB_GETCOUNT, NULL, NULL);
    end;
    // Shift �L�[��������Ă��Ȃ��ꍇ�͒ǉ��A������Ă���ꍇ�͑}��
    bAdd := not bytebool(KeyState.k[VK_SHIFT] and $80) or not longbool(dwCount);
    if bAdd then dwSelect1 := dwCount else dwSelect1 := dwIndex;
    dwSelect2 := dwSelect1 - 1;
    bSelect := false;
    // �o�b�t�@���m��
    GetMem(lpFile, 1024);
    GetMem(lpBuffer, 1024);
    GetMem(lpTitle, 33);
    // �v���C���X�g�ɒǉ�
    for I := 0 to dwFileCount - 1 do begin
        // �v���C���X�g�̃A�C�e�������ő�l�ȏ�̏ꍇ�̓��[�v�𔲂���
        if dwCount >= Option.dwListMax then break;
        // �t�@�C�������擾
        cwSortList.SendMessage(LB_GETTEXT, I, longword(lpFile));
        // �t�@�C�����I�[�v��
        hFile := INVALID_HANDLE_VALUE;
        if IsSafePath(lpFile) then hFile := API_CreateFile(lpFile, GENERIC_READ, FILE_SHARE_READ, NULLPOINTER, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL or FILE_FLAG_SEQUENTIAL_SCAN, NULL);
        // �t�@�C���̃I�[�v���Ɏ��s�����ꍇ�̓��[�v���ĊJ
        if hFile = INVALID_HANDLE_VALUE then continue;
        // �t�@�C�������[�h
        API_ReadFile(hFile, @SPCHdr, SizeOf(TSPCHDR), @dwReadSize, NULLPOINTER);
        // �t�@�C���̃��[�h�Ɏ��s�����ꍇ�̓��[�v���ĊJ
        if not longbool(dwReadSize) then continue;
        // �t�@�C����ǉ�
        if bAdd then cwFileList.SendMessage(LB_ADDSTRING, NULL, longword(lpFile))
        else cwFileList.SendMessage(LB_INSERTSTRING, dwIndex + I, longword(lpFile));
        // ID666 �t�H�[�}�b�g�`�����擾
        GetID666Format(SPCHdr);
        // �^�C�g�����擾
        if not bytebool(SPCHdr.TagFormat) or not bytebool(SPCHdr.Title[0]) then begin
            API_ZeroMemory(lpBuffer, 1024);
            API_GetFileTitle(lpFile, lpBuffer, 1023);
            API_ZeroMemory(lpTitle, 33);
            API_MoveMemory(lpTitle, lpBuffer, 32);
        end else begin
            API_ZeroMemory(lpTitle, 33);
            API_MoveMemory(lpTitle, @SPCHdr.Title[0], 32);
        end;
        // �e�L�X�g�̐���R�[�h���X�y�[�X�ɕϊ�
        pV := lpTitle;
        for J := 0 to 31 do begin
            if ((pV^ > $0) and (pV^ < $20)) or (pV^ = $7F) then pV^ := $20;
            Inc(pV);
        end;
        // �v���C���X�g�ɒǉ�
        if bAdd then begin
            cwPlayList.SendMessage(LB_ADDSTRING, NULL, longword(lpTitle));
            cwPlayList.SendMessage(LB_SETITEMDATA, dwCount, NULL);
        end else begin
            cwPlayList.SendMessage(LB_INSERTSTRING, dwIndex + I, longword(lpTitle));
            cwPlayList.SendMessage(LB_SETITEMDATA, dwIndex + I, NULL);
        end;
        // �J�[�\���I��
        bSelect := true;
        // �v���C���X�g�̃A�C�e������ǉ�
        Inc(dwCount);
        Inc(dwSelect2);
        // �t�@�C�����N���[�Y
        API_CloseHandle(hFile);
    end;
    // �o�b�t�@�����
    FreeMem(lpFile, 1024);
    FreeMem(lpBuffer, 1024);
    FreeMem(lpTitle, 33);
    // �\�[�g�p���X�g���N���A
    cwSortList.SendMessage(LB_RESETCONTENT, NULL, NULL);
    // �ĕ`�拖��
    cwPlayList.SendMessage(WM_SETREDRAW, 1, NULL);
    cwPlayList.Invalidate();
    // �v���C���X�g�̃A�C�e����I��
    if bSelect then begin
        cwPlayList.SendMessage(LB_SETCURSEL, dwSelect2, NULL);
        cwPlayList.SendMessage(LB_SETCURSEL, dwSelect1, NULL);
    end;
    // ���j���[���X�V
    UpdateMenu();
end;

// ================================================================================
// CreateWindow - �E�B���h�E�쐬
// ================================================================================
function CWINDOWMAIN.CreateWindow(hThisInstance: longword; lpClassName: pointer; lpArgs: pointer): longword;
var
    I: longint;
    J: longint;
    K: longint;
    L: longint;
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
    dwTop: longint;
    hWndApp: longword;
    hFontApp: longword;
    Box: TBOX;
    WaveOutCaps: TWAVEOUTCAPS;
    API_RtlGetVersion: function(lpVersionInfo: pointer): longbool; stdcall;
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
    // �T�C�Y���I�[�o�[�t���[����ꍇ
    if dwStart > dwLength then begin
        result := '';
        exit;
    end;
    // �X�y�[�X���X�L�b�v
    for I := dwStart to dwLength do if not IsSingleByte(sBuffer, I, ' ') then begin
        dwStart := I;
        break;
    end;
    // �ŏ��̕������擾
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
    // �Ō�̕������擾
    K := dwLength + 1;
    for I := dwStart to dwLength do if IsSingleByte(sBuffer, I, cEnd) then begin
        K := I;
        break;
    end;
    // �������擾
    result := Trim(Copy(sBuffer, dwStart, K - dwStart));
    // �I�t�Z�b�g���擾
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

function CheckImageHash(sPath: string; dwBase: longword): longword;
var
    dwResult: longword;
    dwHeaderSum: longword;
    dwCheckSum: longword;
begin
    // �`�F�b�N�T�����擾
    sData := Concat(sChPath, sPath);
    dwResult := API_MapFileAndCheckSum(pchar(sData), @dwHeaderSum, @dwCheckSum);
    // �t�@�C���̃I�[�v���Ɏ��s�����ꍇ�͏I��
    result := dwBase + dwResult;
    if longbool(dwResult) then exit;
    // �`�F�b�N�T������v���Ȃ��ꍇ�͏I��
    result := dwBase + 9;
    if dwHeaderSum <> dwCheckSum then exit;
    // �I��
    result := 0;
end;

procedure SetMenuTextAndTip(var cmMenu: CMENU; nSize: longint; dwBase: longint; MsgArray: array of pchar; bRadio: longbool); overload;
var
    I: longint;
begin
    // ���j���[���쐬
    cmMenu := CMENU.Create();
    cmMenu.CreatePopupMenu();
    // ���j���[ �e�L�X�g��ݒ�
    for I := 0 to nSize - 1 do cmMenu.AppendMenu(dwBase + I, pchar(MsgArray[I]), bRadio);
end;

procedure SetMenuTextAndTip(var cmMenu: CMENU; nSize: longint; dwBase: longint; PerIndex: array of longword; TipIndex: array of longword); overload;
var
    I: longint;
begin
    // ���j���[���쐬
    cmMenu := CMENU.Create();
    cmMenu.CreatePopupMenu();
    // ���j���[ �e�L�X�g��ݒ�
    for I := 0 to nSize - 1 do begin
        sBuffer := Concat('&', IntToStr(STR_MENU_SETUP_PER_INTEGER[PerIndex[I]]), ' ', STR_MENU_SETUP_PERCENT[Status.dwLanguage]);
        if longbool(TipIndex[I]) then sBuffer := Concat(sBuffer, #9, STR_MENU_SETUP_TIP[Status.dwLanguage][TipIndex[I]]);
        cmMenu.AppendMenu(dwBase + I, pchar(sBuffer), true);
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

begin
    // ������
    result := 0;
    Randomize();
{$IFDEF DEBUGLOG}
    _WriteLog('initialize ---------------------------------------------------------------------');
{$ENDIF}
    // �R�}���h���C�����擾
    lpBuffer := API_GetCommandLine();
    J := GetSize(lpBuffer, 1023);
    SetLength(cBuffer, J);
    API_MoveMemory(@cBuffer[0], lpBuffer, J);
    sBuffer := string(cBuffer);
    // �p�����[�^���擾
    I := 1;
    sEXEPath := GetParameter(I, J, false);
    sCmdLine := GetParameter(I, J, true);
    // �E�B���h�E������
    hWndApp := API_FindWindowEx(NULL, NULL, lpClassName, NULLPOINTER);
    // �E�B���h�E�����������ꍇ
    if longbool(hWndApp) then begin
        // �E�B���h�E��o�^
        cwWindowMain := CWINDOW.Create();
        cwWindowMain.hWnd := hWndApp;
        // �R�}���h���C��������
        if not longbool(Length(sCmdLine)) then begin
            // �ʏ�T�C�Y�ɕύX
            if longbool(cwWindowMain.GetWindowStyle() and WS_MINIMIZE) then cwWindowMain.SetWindowShowStyle(SW_SHOWNORMAL);
            // �E�B���h�E��O�ʂɈړ�
            API_SetForegroundWindow(hWndApp);
        end else begin
            // �E�B���h�E������
            hWndApp := API_FindWindowEx(hWndApp, NULL, pchar(ITEM_STATIC), pchar(FILE_DEFAULT));
            // �E�B���h�E�����������ꍇ
            if longbool(hWndApp) then begin
                // �o�b�t�@���m��
                GetMem(lpBuffer, 1024);
                // �o�b�t�@�ɃR�s�[
                API_ZeroMemory(lpBuffer, 1024);
                lpString := pchar(sCmdLine);
                API_MoveMemory(lpBuffer, lpString, Length(sCmdLine));
                // �E�B���h�E��o�^
                cwStaticFile := CWINDOW.Create();
                cwStaticFile.hWnd := hWndApp;
                // ���b�Z�[�W�𑗐M
                cwStaticFile.SendMessage(WM_SETTEXT, NULL, longword(lpBuffer));
                cwWindowMain.PostMessage(WM_APP_MESSAGE, WM_APP_TRANSMIT or $1, hWndApp);
                // �E�B���h�E�����
                cwStaticFile.Free();
                // �o�b�t�@�����
                FreeMem(lpBuffer, 1024);
            end;
        end;
        // �E�B���h�E�����
        cwWindowMain.Free();
        // �t���O��ݒ�
        Apu.hDLL := NULL;
        result := 99;
        // �I��
        exit;
    end;
    // �E�B���h�E���쐬
    Status.dwFocusHandle := NULL;
    cwWindowMain := CWINDOW.Create();
    cwWindowMain.CreateWindow(hThisInstance, lpClassName, pchar(DEFAULT_TITLE), WS_CLIPSIBLINGS or WS_DLGFRAME or WS_MINIMIZEBOX or WS_OVERLAPPED or WS_SYSMENU, WS_EX_ACCEPTFILES or WS_EX_CONTROLPARENT or WS_EX_WINDOWEDGE, SimpleWindowBox(3000, 3000, 1024, 1024));
    hWndApp := cwWindowMain.hWnd;
    // �o�b�t�@���m��
    GetMem(Status.lpCurrentPath, 1024);
    GetMem(Status.lpSPCFile, 1024);
    GetMem(Status.lpSPCDir, 1024);
    GetMem(Status.lpSPCName, 1024);
    GetMem(Status.lpOpenPath, 1024);
    GetMem(Status.lpSavePath, 1024);
    // �o�b�t�@���m��
    lpBuffer := Status.lpCurrentPath;
    // EXE �t�@�C�������擾
    dwBuffer := GetPosSeparator(sEXEPath);
    if longbool(dwBuffer) then sEXEPath := Copy(sEXEPath, dwBuffer + 1, Length(sEXEPath));
    if (Length(sEXEPath) < 5) or (sEXEPath[Length(sEXEPath) - 3] <> '.') then sEXEPath := Concat(sEXEPath, '.exe');
    // �J�����g �p�X���擾
    API_GetModuleFileName(hThisInstance, lpBuffer, 1024);
    dwBuffer := GetPosSeparator(string(lpBuffer));
    if dwBuffer > 1024 then dwBuffer := 1024;
    API_ZeroMemory(pointer(longword(lpBuffer) + dwBuffer), 1024 - dwBuffer);
    API_MoveMemory(Status.lpOpenPath, lpBuffer, 1024);
    API_MoveMemory(Status.lpSavePath, lpBuffer, 1024);
    Status.lpCurrentSize := GetSize(lpBuffer, 1023);
    sChPath := Copy(string(lpBuffer), 1, Status.lpCurrentSize);
    // �p�����[�^��������
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
    Status.bChangeBreak := false;
    Status.bOptionLock := false;
    Status.dwTitle := TITLE_HIDE;
    Status.dwInfo := NULL;
    Status.dwRedrawInfo := REDRAW_OFF;
    Status.dwMenuFlags := 0;
    Status.dwOpenFilterIndex := DIALOG_OPEN_DEFAULT;
    Status.dwSaveFilterIndex := DIALOG_SAVE_DEFAULT;
    Status.DragPoint.x := -1;
    Status.DragPoint.y := -1;
    Status.bDropCancel := false;
    Status.dwScale := 2;
    API_ZeroMemory(@Status.BreakPoint, 65536);
    Status.dwNextTick := 0;
    API_ZeroMemory(@Status.DSPCheat, 256);
    Status.bEmuDebug := false;
{$IFDEF CONTEXT}
    Status.dwContextSize := 0;
    Status.lpContext := NULLPOINTER;
{$ENDIF}
    // �ݒ��������
    Option.dwAmp := AMP_100;
    Option.dwBit := BIT_16;
    Option.dwBufferNum := 22;
    Option.dwBufferTime := 23;
    Option.dwChannel := CHANNEL_STEREO;
    Option.dwDeviceID := -1;
    Option.dwDrawInfo := 0;
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
    Option.dwOption := 0;
    Option.dwPitch := PITCH_NORMAL;
    Option.bPitchAsync := false;
    Option.bPlayDefault := false;
    Option.dwPlayTime := 120000;
    Option.bPlayTime := true;
    Option.dwPlayOrder := PLAY_ORDER_NEXT;
    Option.dwPriority := NORMAL_PRIORITY_CLASS;
    Option.dwRate := 32000;
    Option.dwScale := 100;
    Option.dwSeekFast := 1;
    Option.dwSeekInt := 15000;
    Option.dwSeekMax := 600000;
    Option.dwSeekNum := 40;
    Option.dwSeekTime := 5000;
    Option.dwSeparate := SEPARATE_050;
    Option.dwSpeedBas := SPEED_100;
    Option.dwSpeedTun := 0;
    dwTop := 100;
    Option.bTopMost := false;
    Option.dwVolumeColor := 0;
    Option.bVolumeReset := true;
    Option.dwVolumeSpeed := 1;
    Option.dwWaitTime := 3000;
    Option.dwWaveBlank := 500;
    Option.dwWaveFormat := 0;
    // INI �̑��݂��`�F�b�N
    sData := Concat(sChPath, INI_FILE);
    if IsSafePath(pchar(sData)) and Exists(pchar(sData), $FFFFFFFF) then begin
        // �t�@�C�����I�[�v��
        AssignFile(fsFile, sData);
        // �t�@�C����ǂݍ���
        Reset(fsFile);
        while not Eof(fsFile) do begin
            Readln(fsFile, sData);
            sBuffer := Copy(sData, 1, BUFFER_LENGTH);
            if sBuffer = BUFFER_AMP_____ then Option.dwAmp := GetINIValue(Option.dwAmp);
            if sBuffer = BUFFER_BIT_____ then Option.dwBit := GetINIValue(Option.dwBit);
            if sBuffer = BUFFER_BUFNUM__ then Option.dwBufferNum := GetINIValue(Option.dwBufferNum);
            if sBuffer = BUFFER_BUFTIME_ then Option.dwBufferTime := GetINIValue(Option.dwBufferTime);
            if sBuffer = BUFFER_CHANNEL_ then Option.dwChannel := GetINIValue(Option.dwChannel);
            if sBuffer = BUFFER_DEVICE__ then Option.dwDeviceID := GetINIValue(Option.dwDeviceID);
            if sBuffer = BUFFER_DRAWINFO then Option.dwDrawInfo := GetINIValue(Option.dwDrawInfo);
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
            if sBuffer = BUFFER_OPTION__ then Option.dwOption := GetINIValue(Option.dwOption);
            if sBuffer = BUFFER_PITCH___ then Option.dwPitch := GetINIValue(Option.dwPitch);
            if sBuffer = BUFFER_PITCHSNC then Option.bPitchAsync := longbool(GetINIValue(longint(Option.bPitchAsync)));
            if sBuffer = BUFFER_PLAYDEF_ then Option.bPlayDefault := longbool(GetINIValue(longint(Option.bPlayDefault)));
            if sBuffer = BUFFER_PLAYLENG then Option.dwPlayTime := GetINIValue(Option.dwPlayTime);
            if sBuffer = BUFFER_PLAYTIME then Option.bPlayTime := longbool(GetINIValue(longint(Option.bPlayTime)));
            if sBuffer = BUFFER_PLAYTYPE then Option.dwPlayOrder := GetINIValue(Option.dwPlayOrder);
            if sBuffer = BUFFER_PRIORITY then Option.dwPriority := GetINIValue(Option.dwPriority);
            if sBuffer = BUFFER_RATE____ then Option.dwRate := GetINIValue(Option.dwRate);
            if sBuffer = BUFFER_SCALE___ then Option.dwScale := GetINIValue(Option.dwScale);
            if sBuffer = BUFFER_SEEKFAST then Option.dwSeekFast := GetINIValue(Option.dwSeekFast);
            if sBuffer = BUFFER_SEEKINT_ then Option.dwSeekInt := GetINIValue(Option.dwSeekInt);
            if sBuffer = BUFFER_SEEKMAX_ then Option.dwSeekMax := GetINIValue(Option.dwSeekMax);
            if sBuffer = BUFFER_SEEKNUM_ then Option.dwSeekNum := GetINIValue(Option.dwSeekNum);
            if sBuffer = BUFFER_SEEKTIME then Option.dwSeekTime := GetINIValue(Option.dwSeekTime);
            if sBuffer = BUFFER_SEPARATE then Option.dwSeparate := GetINIValue(Option.dwSeparate);
            if sBuffer = BUFFER_SPEED___ then Option.dwSpeedBas := GetINIValue(Option.dwSpeedBas);
            if sBuffer = BUFFER_SPEEDTUN then Option.dwSpeedTun := GetINIValue(Option.dwSpeedTun);
            if sBuffer = BUFFER_TOP_____ then dwTop := GetINIValue(dwTop);
            if sBuffer = BUFFER_TOPMOST_ then Option.bTopMost := longbool(GetINIValue(longint(Option.bTopMost)));
            if sBuffer = BUFFER_VOLCOLOR then Option.dwVolumeColor := GetINIValue(Option.dwVolumeColor);
            if sBuffer = BUFFER_VOLRESET then Option.bVolumeReset := longbool(GetINIValue(longint(Option.bVolumeReset)));
            if sBuffer = BUFFER_VOLSPEED then Option.dwVolumeSpeed := GetINIValue(Option.dwVolumeSpeed);
            if sBuffer = BUFFER_WAITLENG then Option.dwWaitTime := GetINIValue(Option.dwWaitTime);
            if sBuffer = BUFFER_WAVBLANK then Option.dwWaveBlank := GetINIValue(Option.dwWaveBlank);
            if sBuffer = BUFFER_WAVEFMT_ then Option.dwWaveFormat := GetINIValue(Option.dwWaveFormat);
        end;
        // �t�@�C�����N���[�Y
        CloseFile(fsFile);
    end;
    // �ݒ�l���`�F�b�N
    if longbool(Option.dwLanguage) then Status.dwLanguage := Option.dwLanguage - 1
    else if API_GetUserDefaultLCID() and $FFFF = $0411 then Status.dwLanguage := 0
    else Status.dwLanguage := 1;
    if Status.dwLanguage > 1 then Status.dwLanguage := 0;
    if Option.dwVolumeColor > 3 then Option.dwVolumeColor := 0;
    if Option.dwScale >= 200 then Status.dwScale := 4
    else if Option.dwScale >= 150 then Status.dwScale := 3;
    Status.dwPlayOrder := Option.dwPlayOrder;
{$IFNDEF TRY700A}{$IFNDEF TRY700W}
    // SPCPLAY.EXE �̔j�����m�F
    if not longbool(result) then result := CheckImageHash(sEXEPath, 10);
    // SNESAPU.DLL �̔j�����m�F
    if not longbool(result) then result := CheckImageHash(SNESAPU_FILE, 20);
{$ENDIF}{$ENDIF}
    // �t�@�C��������̏ꍇ
    if not longbool(result) then begin
        // SNESAPU.DLL �����[�h
        sData := Concat(sChPath, SNESAPU_FILE);
        dwBuffer := API_LoadLibrary(pchar(sData));
        // SNESAPU.DLL �̃��[�h�ɐ��������ꍇ
        if longbool(dwBuffer) then begin
            // �֐���ǂݍ���
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
            Apu.SNESAPUCallback(@_SNESAPUCallback, CBE_INCS700 or CBE_INCDATA);
            Apu.SNESAPUInfo(@I, NULLPOINTER, NULLPOINTER);
{$IFNDEF TRANSMITSPC}
            if I <> SNESAPU_VERSION then result := 3;
{$ENDIF}
        end else result := 1;
        Apu.hDLL := dwBuffer;
    end;
    // SNESAPU.DLL �̏����擾
    if not longbool(result) then begin
        Apu.GetAPUData(@Apu.Ram, @Apu.XRam, @Apu.SPCOutPort, @Apu.T64Count, @Apu.DspReg, @Apu.Voices, @Apu.VolumeMaxLeft, @Apu.VolumeMaxRight);
        if longbool((longword(Apu.Ram) and $FFFF) or ((longword(Apu.DspReg) or longword(Apu.Voices)) and $FF)) then result := 4;
    end;
    // SNESAPU.DLL �̓ǂݍ��݂Ɏ��s�����ꍇ
    if longbool(result) then begin
        // ���b�Z�[�W��\��
        ShowErrMsg(100 + result);
        // SNESAPU.DLL �����
        if longbool(Apu.hDLL) then API_FreeLibrary(Apu.hDLL);
        // �o�b�t�@�����
        FreeMem(Status.lpCurrentPath, 1024);
        FreeMem(Status.lpSPCFile, 1024);
        FreeMem(Status.lpSPCDir, 1024);
        FreeMem(Status.lpSPCName, 1024);
        FreeMem(Status.lpOpenPath, 1024);
        FreeMem(Status.lpSavePath, 1024);
        // �E�B���h�E���폜
        cwWindowMain.DeleteWindow();
        cwWindowMain.Free();
        // �I��
        exit;
    end;
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
{$IFDEF UACDROP}
    // �������Ⴂ�A�v���P�[�V��������̃h���b�v��L���ɐݒ� (for Windows Vista, 7)
    dwBuffer := API_LoadLibrary(pchar('user32.dll'));
    if longbool(dwBuffer) then begin
        @API_ChangeWindowMessageFilter := API_GetProcAddress(dwBuffer, pchar('ChangeWindowMessageFilter'));
        if longbool(@API_ChangeWindowMessageFilter) then begin
            API_ChangeWindowMessageFilter(WM_DROPFILES, MSGFLT_ADD);
            API_ChangeWindowMessageFilter(WM_COPYDATA, MSGFLT_ADD);
            API_ChangeWindowMessageFilter(WM_COPYGLOBALDATA, MSGFLT_ADD);
        end;
        API_FreeLibrary(dwBuffer);
    end;
{$ENDIF}
    // �V�X�e���̃o�[�W���������擾
    Status.OsVersionInfo.dwOSVersionInfoSize := SizeOf(TOSVERSIONINFO);
    API_GetVersionEx(@Status.OsVersionInfo);
    dwBuffer := API_LoadLibrary(pchar('ntdll.dll'));
    if longbool(dwBuffer) then begin
        @API_RtlGetVersion := API_GetProcAddress(dwBuffer, pchar('RtlGetVersion'));
        if longbool(@API_RtlGetVersion) then API_RtlGetVersion(@Status.OsVersionInfo);
        API_FreeLibrary(dwBuffer);
    end;
{$IFDEF ITASKBARLIST3}
    // COM �C���^�[�t�F�C�X��������
    API_CoInitialize(NULLPOINTER);
    // �^�X�N�o�[�̃{�^���𐧌䂷��C���^�[�t�F�[�X��ǂݍ���
    API_CoCreateInstance(@CLSID_TaskbarList, NULLPOINTER, CLSCTX_INPROC_SERVER, @IID_ITaskbarList3, @Status.ITaskbarList3);
{$ENDIF}
    // �o�b�t�@��ݒ�
    SetLength(cBuffer, 32);
    // �f�[�^���i�[����|�C���^���擾
    API_ZeroMemory(@cBuffer[0], 32);
    Apu.GetScript700Data(@cBuffer[0], @Apu.SPC700Reg, @Status.Script700.Data);
    // �o�[�W���������쐬
    sInfo := Concat(SPCPLAY_TITLE, SPCPLAY_VERSION, CRLF, CRLF, SNESAPU_TITLE, Copy(string(cBuffer), 1, GetSize(@cBuffer[0], 32)));
    // �z��̃T�C�Y��������
    SetLength(Wave.lpData, Option.dwBufferNum);
    SetLength(Wave.Header, Option.dwBufferNum);
    SetLength(Wave.Apu, Option.dwBufferNum);
    SetLength(Status.SPCCache, Option.dwSeekNum);
    // �t�@�C�� ���j���[���쐬
    cmFile := CMENU.Create();
    cmFile.CreatePopupMenu();
    for I := 0 to MENU_FILE_OPEN_SIZE - 1 do cmFile.AppendMenu(MENU_FILE_OPEN_BASE + I, STR_MENU_FILE_OPEN_SUB[Status.dwLanguage][I]);
    cmFile.AppendSeparator();
    for I := 0 to MENU_FILE_PLAY_SIZE - 1 do cmFile.AppendMenu(MENU_FILE_PLAY_BASE + I, STR_MENU_FILE_PLAY_SUB[Status.dwLanguage][I]);
    cmFile.AppendSeparator();
    cmFile.AppendMenu(MENU_FILE_EXIT, STR_MENU_FILE_EXIT[Status.dwLanguage]);
    // �f�o�C�X ���j���[���쐬
    cmSetupDevice := CMENU.Create();
    cmSetupDevice.CreatePopupMenu();
    Status.dwDeviceNum := API_waveOutGetNumDevs();
    if Status.dwDeviceNum > 9 then Status.dwDeviceNum := 9;
    for I := -1 to Status.dwDeviceNum - 1 do begin
        API_waveOutGetDevCaps(I, @WaveOutCaps, SizeOf(TWAVEOUTCAPS));
        cmSetupDevice.AppendMenu(MENU_SETUP_DEVICE_BASE + I + 1, pchar(Concat('&', char($31 + I), '   ', string(WaveOutCaps.szPname))), true);
    end;
    // �`�����l�� ���j���[���쐬
    SetMenuTextAndTip(cmSetupChannel, MENU_SETUP_CHANNEL_SIZE, MENU_SETUP_CHANNEL_BASE, STR_MENU_SETUP_CHANNEL_SUB[Status.dwLanguage], true);
    // �r�b�g ���j���[���쐬
    SetMenuTextAndTip(cmSetupBit, MENU_SETUP_BIT_SIZE, MENU_SETUP_BIT_BASE, STR_MENU_SETUP_BIT_SUB[Status.dwLanguage], true);
    // �T���v�����O ���[�g ���j���[���쐬
    SetMenuTextAndTip(cmSetupRate, MENU_SETUP_RATE_SIZE, MENU_SETUP_RATE_BASE, STR_MENU_SETUP_RATE_SUB[Status.dwLanguage], true);
    // ��ԏ������j���[���쐬
    SetMenuTextAndTip(cmSetupInter, MENU_SETUP_INTER_SIZE, MENU_SETUP_INTER_BASE, STR_MENU_SETUP_INTER_SUB[Status.dwLanguage], true);
    // �s�b�` �L�[ ���j���[���쐬
    cmSetupPitchKey := CMENU.Create();
    cmSetupPitchKey.CreatePopupMenu();
    for I := 0 to MENU_SETUP_PITCH_KEY_SIZE - 1 do cmSetupPitchKey.AppendMenu(MENU_SETUP_PITCH_KEY_BASE + I, pchar(Concat(STR_MENU_SETUP_PITCH_PLUS[Status.dwLanguage], IntToStr(MENU_SETUP_PITCH_KEY_SIZE - I))), true);
    cmSetupPitchKey.AppendMenu(MENU_SETUP_PITCH_KEY_BASE + MENU_SETUP_PITCH_KEY_SIZE, STR_MENU_SETUP_PITCH_ZERO, true);
    for I := 0 to MENU_SETUP_PITCH_KEY_SIZE - 1 do cmSetupPitchKey.AppendMenu(MENU_SETUP_PITCH_KEY_BASE + MENU_SETUP_PITCH_KEY_SIZE + I + 1, pchar(Concat(STR_MENU_SETUP_PITCH_MINUS[Status.dwLanguage], char($31 + I))), true);
    // �s�b�` ���j���[���쐬
    SetMenuTextAndTip(cmSetupPitch, MENU_SETUP_PITCH_SIZE, MENU_SETUP_PITCH_BASE, STR_MENU_SETUP_PITCH_SUB[Status.dwLanguage], true);
    cmSetupPitch.AppendSeparator();
    cmSetupPitch.AppendMenu(MENU_SETUP_PITCH_KEY, STR_MENU_SETUP_PITCH_KEY[Status.dwLanguage], cmSetupPitchKey.hMenu);
    cmSetupPitch.AppendMenu(MENU_SETUP_PITCH_ASYNC, STR_MENU_SETUP_PITCH_ASYNC[Status.dwLanguage]);
    // ���E�g�U�x���j���[���쐬
    SetMenuTextAndTip(cmSetupSeparate, MENU_SETUP_SEPARATE_SIZE, MENU_SETUP_SEPARATE_BASE, STR_MENU_SETUP_SEPARATE_PER_INDEX, STR_MENU_SETUP_SEPARATE_TIP_INDEX);
    // �t�B�[�h�o�b�N���]�x���j���[���쐬
    SetMenuTextAndTip(cmSetupFeedback, MENU_SETUP_FEEDBACK_SIZE, MENU_SETUP_FEEDBACK_BASE, STR_MENU_SETUP_FEEDBACK_PER_INDEX, STR_MENU_SETUP_FEEDBACK_TIP_INDEX);
    // ���t���x���j���[���쐬
    SetMenuTextAndTip(cmSetupSpeed, MENU_SETUP_SPEED_SIZE, MENU_SETUP_SPEED_BASE, STR_MENU_SETUP_SPEED_PER_INDEX, STR_MENU_SETUP_SPEED_TIP_INDEX);
    // ���ʃ��j���[���쐬
    SetMenuTextAndTip(cmSetupAmp, MENU_SETUP_AMP_SIZE, MENU_SETUP_AMP_BASE, STR_MENU_SETUP_AMP_PER_INDEX, STR_MENU_SETUP_AMP_TIP_INDEX);
    // �`�����l�� �}�X�N ���j���[���쐬
    cmSetupMute := CMENU.Create();
    cmSetupMute.CreatePopupMenu();
    for I := 0 to MENU_SETUP_MUTE_NOISE_ALL_SIZE - 1 do cmSetupMute.AppendMenu(MENU_SETUP_MUTE_ALL_BASE + I, STR_MENU_SETUP_MUTE_NOISE_ALL_SUB[Status.dwLanguage][I]);
    cmSetupMute.AppendSeparator();
    for I := 0 to MENU_SETUP_MUTE_NOISE_SIZE - 1 do cmSetupMute.AppendMenu(MENU_SETUP_MUTE_BASE + I, pchar(Concat(STR_MENU_SETUP_SWITCH_CHANNEL[Status.dwLanguage], '&', char($31 + I))));
    // �`�����l�� �m�C�Y ���j���[���쐬
    cmSetupNoise := CMENU.Create();
    cmSetupNoise.CreatePopupMenu();
    for I := 0 to MENU_SETUP_MUTE_NOISE_ALL_SIZE - 1 do cmSetupNoise.AppendMenu(MENU_SETUP_NOISE_ALL_BASE + I, STR_MENU_SETUP_MUTE_NOISE_ALL_SUB[Status.dwLanguage][I]);
    cmSetupNoise.AppendSeparator();
    for I := 0 to MENU_SETUP_MUTE_NOISE_SIZE - 1 do cmSetupNoise.AppendMenu(MENU_SETUP_NOISE_BASE + I, pchar(Concat(STR_MENU_SETUP_SWITCH_CHANNEL[Status.dwLanguage], '&', char($31 + I))));
    // �g���ݒ胁�j���[���쐬
    SetMenuTextAndTip(cmSetupOption, MENU_SETUP_OPTION_SIZE, MENU_SETUP_OPTION_BASE, STR_MENU_SETUP_OPTION_SUB[Status.dwLanguage], false);
    // ���t���ԃ��j���[���쐬
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
    // ���t�������j���[���쐬
    SetMenuTextAndTip(cmSetupOrder, MENU_SETUP_ORDER_SIZE, MENU_SETUP_ORDER_BASE, STR_MENU_SETUP_ORDER_SUB[Status.dwLanguage], true);
    // �V�[�N���ԃ��j���[���쐬
    SetMenuTextAndTip(cmSetupSeek, MENU_SETUP_SEEK_SIZE, MENU_SETUP_SEEK_BASE, STR_MENU_SETUP_SEEK_SUB[Status.dwLanguage], true);
    // ���\�����j���[���쐬
    SetMenuTextAndTip(cmSetupInfo, MENU_SETUP_INFO_SIZE, MENU_SETUP_INFO_BASE, STR_MENU_SETUP_INFO_SUB[Status.dwLanguage], true);
    cmSetupInfo.AppendSeparator();
    cmSetupInfo.AppendMenu(MENU_SETUP_INFO_RESET, STR_MENU_SETUP_INFO_RESET[Status.dwLanguage]);
    // ��{�D��x���j���[���쐬
    SetMenuTextAndTip(cmSetupPriority, MENU_SETUP_PRIORITY_SIZE, MENU_SETUP_PRIORITY_BASE, STR_MENU_SETUP_PRIORITY_SUB[Status.dwLanguage], true);
    // �ݒ胁�j���[���쐬
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
    cmSetup.AppendSeparator();
    cmSetup.AppendMenu(MENU_SETUP_TOPMOST, STR_MENU_SETUP_TOPMOST[Status.dwLanguage]);
    // ���t�J�n���j���[���쐬
    cmListPlay := CMENU.Create();
    cmListPlay.CreatePopupMenu();
    cmListPlay.AppendMenu(MENU_LIST_PLAY_SELECT, STR_MENU_LIST_PLAY_SELECT[Status.dwLanguage]);
    cmListPlay.AppendSeparator();
    for I := 0 to MENU_LIST_PLAY_SIZE - 1 do cmListPlay.AppendMenu(MENU_LIST_PLAY_BASE + I, STR_MENU_LIST_PLAY_SUB[Status.dwLanguage][I], true);
    // �v���C���X�g ���j���[���쐬
    cmList := CMENU.Create();
    cmList.CreatePopupMenu();
    cmList.AppendMenu(MENU_LIST_PLAY, STR_MENU_LIST_PLAY[Status.dwLanguage], cmListPlay.hMenu);
    cmList.AppendSeparator();
    for I := 0 to MENU_LIST_EDIT_SIZE - 1 do cmList.AppendMenu(MENU_LIST_EDIT_BASE + I, STR_MENU_LIST_EDIT_SUB[Status.dwLanguage][I]);
    cmList.AppendSeparator();
    for I := 0 to MENU_LIST_MOVE_SIZE - 1 do cmList.AppendMenu(MENU_LIST_MOVE_BASE + I, STR_MENU_LIST_MOVE_SUB[Status.dwLanguage][I]);
    // �V�X�e�� ���j���[���쐬
    cmSystem := cwWindowMain.GetSystemMenu();
    cmSystem.RemoveItem(SC_MAXIMIZE);
    cmSystem.RemoveItem(SC_SIZE);
    cmSystem.InsertMenu(MENU_FILE, SC_CLOSE, STR_MENU_FILE[Status.dwLanguage], cmFile.hMenu);
    cmSystem.InsertMenu(MENU_SETUP, SC_CLOSE, STR_MENU_SETUP[Status.dwLanguage], cmSetup.hMenu);
    cmSystem.InsertMenu(MENU_LIST, SC_CLOSE, STR_MENU_LIST[Status.dwLanguage], cmList.hMenu);
    cmSystem.InsertSeparator(SC_CLOSE);
    // �E�B���h�E ���j���[���쐬
    cmMain := CMENU.Create();
    cmMain.CreateMenu();
    cmMain.AppendMenu(MENU_FILE, STR_MENU_FILE[Status.dwLanguage], cmFile.hMenu);
    cmMain.AppendMenu(MENU_SETUP, STR_MENU_SETUP[Status.dwLanguage], cmSetup.hMenu);
    cmMain.AppendMenu(MENU_LIST, STR_MENU_LIST[Status.dwLanguage], cmList.hMenu);
    API_SetMenu(hWndApp, cmMain.hMenu);
    // �t�H���g���쐬
    cfMain := CFONT.Create();
    ScalableWindowBox(0, 0, 6, 12);
    if Length(Option.sFontName) > 0 then sFontName := Option.sFontName
    else sFontName := FONT_NAME[Status.dwLanguage];
    cfMain.CreateFont(pchar(sFontName), Box.height, Box.width, false, false, false, false);
    // �v���C���X�g�A�{�^�����쐬
    hFontApp := cfMain.hFont;
    lpString := pchar(ITEM_BUTTON);
    lpBuffer := pchar(ITEM_LISTBOX);
    cwFileList := CWINDOW.Create();
    cwFileList.CreateItem(hThisInstance, hWndApp, hFontApp, lpBuffer, pchar(''), ID_LIST_FILE, LBS_NOREDRAW, NULL, ScalableWindowBox(0, 210, 220, 130));
    cwSortList := CWINDOW.Create();
    cwSortList.CreateItem(hThisInstance, hWndApp, hFontApp, lpBuffer, pchar(''), ID_LIST_SORT, LBS_NOREDRAW or LBS_SORT, NULL, ScalableWindowBox(0, 210, 220, 130));
    cwTempList := CWINDOW.Create();
    cwTempList.CreateItem(hThisInstance, hWndApp, hFontApp, lpBuffer, pchar(''), ID_LIST_TEMP, LBS_NOREDRAW, NULL, ScalableWindowBox(0, 210, 220, 130));
    cwButtonOpen := CWINDOW.Create();
    cwButtonOpen.CreateItem(hThisInstance, hWndApp, hFontApp, lpString, pchar(STR_BUTTON_OPEN), ID_BUTTON_OPEN, WS_TABSTOP or WS_VISIBLE, WS_EX_NOPARENTNOTIFY or WS_EX_STATICEDGE, ScalableWindowBox(5, 103, 55, 21));
    cwButtonSave := CWINDOW.Create();
    cwButtonSave.CreateItem(hThisInstance, hWndApp, hFontApp, lpString, pchar(STR_BUTTON_SAVE), ID_BUTTON_SAVE, WS_TABSTOP or WS_VISIBLE, WS_EX_NOPARENTNOTIFY or WS_EX_STATICEDGE, ScalableWindowBox(62, 103, 55, 21));
    cwButtonPlay := CWINDOW.Create();
    cwButtonPlay.CreateItem(hThisInstance, hWndApp, hFontApp, lpString, pchar(STR_BUTTON_PLAY), ID_BUTTON_PLAY, WS_TABSTOP or WS_VISIBLE, WS_EX_NOPARENTNOTIFY or WS_EX_STATICEDGE, ScalableWindowBox(126, 103, 54, 21));
    cwButtonRestart := CWINDOW.Create();
    cwButtonRestart.CreateItem(hThisInstance, hWndApp, hFontApp, lpString, pchar(STR_BUTTON_RESTART), ID_BUTTON_RESTART, WS_TABSTOP or WS_VISIBLE, WS_EX_NOPARENTNOTIFY or WS_EX_STATICEDGE, ScalableWindowBox(182, 103, 54, 21));
    cwButtonStop := CWINDOW.Create();
    cwButtonStop.CreateItem(hThisInstance, hWndApp, hFontApp, lpString, pchar(STR_BUTTON_STOP), ID_BUTTON_STOP, WS_TABSTOP or WS_VISIBLE, WS_EX_NOPARENTNOTIFY or WS_EX_STATICEDGE, ScalableWindowBox(238, 103, 54, 21));
    sBuffer := '   ';
    K := 5;
    for I := 0 to 7 do begin
        sBuffer[2] := char($31 + I);
        cwCheckTrack[I] := CWINDOW.Create();
        cwCheckTrack[I].CreateItem(hThisInstance, hWndApp, hFontApp, lpString, pchar(sBuffer), ID_BUTTON_TRACK[I], BS_AUTOCHECKBOX or BS_PUSHLIKE or WS_TABSTOP or WS_VISIBLE, WS_EX_NOPARENTNOTIFY or WS_EX_STATICEDGE, ScalableWindowBox(K, 127, 14, 21));
        Inc(K, 14);
    end;
    cwButtonVolM := CWINDOW.Create();
    cwButtonVolM.CreateItem(hThisInstance, hWndApp, hFontApp, lpString, pchar(STR_BUTTON_AMPD), ID_BUTTON_AMPD, WS_TABSTOP or WS_VISIBLE, WS_EX_NOPARENTNOTIFY or WS_EX_STATICEDGE, ScalableWindowBox(126, 127, 26, 21));
    cwButtonVolP := CWINDOW.Create();
    cwButtonVolP.CreateItem(hThisInstance, hWndApp, hFontApp, lpString, pchar(STR_BUTTON_AMPU), ID_BUTTON_AMPU, WS_TABSTOP or WS_VISIBLE, WS_EX_NOPARENTNOTIFY or WS_EX_STATICEDGE, ScalableWindowBox(154, 127, 26, 21));
    cwButtonSlow := CWINDOW.Create();
    cwButtonSlow.CreateItem(hThisInstance, hWndApp, hFontApp, lpString, pchar(STR_BUTTON_SLOW), ID_BUTTON_SLOW, WS_TABSTOP or WS_VISIBLE, WS_EX_NOPARENTNOTIFY or WS_EX_STATICEDGE, ScalableWindowBox(182, 127, 26, 21));
    cwButtonFast := CWINDOW.Create();
    cwButtonFast.CreateItem(hThisInstance, hWndApp, hFontApp, lpString, pchar(STR_BUTTON_FAST), ID_BUTTON_FAST, WS_TABSTOP or WS_VISIBLE, WS_EX_NOPARENTNOTIFY or WS_EX_STATICEDGE, ScalableWindowBox(210, 127, 26, 21));
    cwButtonBack := CWINDOW.Create();
    cwButtonBack.CreateItem(hThisInstance, hWndApp, hFontApp, lpString, pchar(STR_BUTTON_BACK), ID_BUTTON_BACK, WS_TABSTOP or WS_VISIBLE, WS_EX_NOPARENTNOTIFY or WS_EX_STATICEDGE, ScalableWindowBox(238, 127, 26, 21));
    cwButtonNext := CWINDOW.Create();
    cwButtonNext.CreateItem(hThisInstance, hWndApp, hFontApp, lpString, pchar(STR_BUTTON_NEXT), ID_BUTTON_NEXT, WS_TABSTOP or WS_VISIBLE, WS_EX_NOPARENTNOTIFY or WS_EX_STATICEDGE, ScalableWindowBox(266, 127, 26, 21));
    cwPlayList := CWINDOW.Create();
    cwPlayList.CreateItem(hThisInstance, hWndApp, hFontApp, lpBuffer, pchar(''), ID_LIST_PLAY, LBS_DISABLENOSCROLL or LBS_NOTIFY or WS_TABSTOP or WS_VISIBLE or WS_VSCROLL, WS_EX_CLIENTEDGE or WS_EX_NOPARENTNOTIFY, ScalableWindowBox(300, 0, 215, 124));
    ScalableWindowBox(300, 0, 215, Option.dwListHeight);
    Box.top := (Status.dwScale - 2) shl 1;
    API_MoveWindow(cwPlayList.hWnd, Box.left, Box.top, Box.width, Box.height, false); // �v���C���X�g���������Ȃ�o�O���
    cwButtonListAdd := CWINDOW.Create();
    cwButtonListAdd.CreateItem(hThisInstance, hWndApp, hFontApp, lpString, pchar(STR_BUTTON_APPEND), ID_BUTTON_ADD, WS_TABSTOP or WS_VISIBLE, WS_EX_NOPARENTNOTIFY or WS_EX_STATICEDGE, ScalableWindowBox(300, 127, 54, 21));
    cwButtonListRemove := CWINDOW.Create();
    cwButtonListRemove.CreateItem(hThisInstance, hWndApp, hFontApp, lpString, pchar(STR_BUTTON_REMOVE), ID_BUTTON_REMOVE, WS_TABSTOP or WS_VISIBLE, WS_EX_NOPARENTNOTIFY or WS_EX_STATICEDGE, ScalableWindowBox(356, 127, 54, 21));
    cwButtonListClear := CWINDOW.Create();
    cwButtonListClear.CreateItem(hThisInstance, hWndApp, hFontApp, lpString, pchar(STR_BUTTON_CLEAR), ID_BUTTON_CLEAR, WS_TABSTOP or WS_VISIBLE, WS_EX_NOPARENTNOTIFY or WS_EX_STATICEDGE, ScalableWindowBox(412, 127, 54, 21));
    cwButtonListUp := CWINDOW.Create();
    cwButtonListUp.CreateItem(hThisInstance, hWndApp, hFontApp, lpString, pchar(STR_BUTTON_UP[Status.dwLanguage]), ID_BUTTON_UP, WS_TABSTOP or WS_VISIBLE, WS_EX_NOPARENTNOTIFY or WS_EX_STATICEDGE, ScalableWindowBox(471, 127, 21, 21));
    cwButtonListDown := CWINDOW.Create();
    cwButtonListDown.CreateItem(hThisInstance, hWndApp, hFontApp, lpString, pchar(STR_BUTTON_DOWN[Status.dwLanguage]), ID_BUTTON_DOWN, WS_TABSTOP or WS_VISIBLE, WS_EX_NOPARENTNOTIFY or WS_EX_STATICEDGE, ScalableWindowBox(494, 127, 21, 21));
    // Static ���쐬
    lpBuffer := pchar(ITEM_STATIC);
    cwStaticFile := CWINDOW.Create();
    cwStaticFile.CreateItem(hThisInstance, hWndApp, hFontApp, lpBuffer, pchar(FILE_DEFAULT), ID_STATIC_FILE, SS_NOPREFIX, WS_EX_NOPARENTNOTIFY, ScalableWindowBox(0, 0, 0, 0));
    cwStaticMain := CWINDOW.Create();
    cwStaticMain.CreateItem(hThisInstance, hWndApp, hFontApp, lpBuffer, pchar(sInfo), ID_STATIC_MAIN, SS_LEFTNOWORDWRAP or SS_NOPREFIX or SS_NOTIFY or WS_VISIBLE, WS_EX_NOPARENTNOTIFY, ScalableWindowBox(5, 2, 287, 96));
    // Static �̃E�B���h�E �v���V�[�W�����擾
    Status.lpStaticProc := pointer(API_SetWindowLong(cwStaticMain.hWnd, GWL_WNDPROC, longword(@_StaticProc)));
    // Static �̃f�o�C�X �R���e�L�X�g���擾
    Status.hDCStatic := API_GetDC(cwStaticMain.hWnd);
    // �C���W�P�[�^�\���p�̃f�o�C�X �R���e�L�X�g���쐬
    Status.hDCVolumeBuffer := API_CreateCompatibleDC(Status.hDCStatic);
    Status.hBitmapVolume := API_SelectObject(Status.hDCVolumeBuffer, API_CreateCompatibleBitmap(Status.hDCStatic, COLOR_BAR_NUM_X7, COLOR_BAR_HEIGHT));
    // �����\���p�̃f�o�C�X �R���e�L�X�g���쐬
    Status.hDCStringBuffer := API_CreateCompatibleDC(Status.hDCStatic);
    Status.hBitmapString := API_SelectObject(Status.hDCStringBuffer, API_CreateCompatibleBitmap(Status.hDCStatic, BITMAP_NUM_X6P6, BITMAP_NUM_HEIGHT));
    // �O���t�B�b�N ���\�[�X��ݒ�
    SetGraphic();
    // �f�o�C�X��������
    WaveInit();
    // �v���C���X�g �t�@�C�������[�h
    lpBuffer := pchar(Concat(sChPath, LIST_FILE));
    dwBuffer := GetFileType(lpBuffer, false, false);
    case dwBuffer of
        FILE_TYPE_LIST_A, FILE_TYPE_LIST_B: ListLoad(lpBuffer, dwBuffer, true);
    end;
    // ���j���[���X�V
    UpdateMenu();
    // �v���Z�X�D��x��ݒ�
    API_SetPriorityClass(API_GetCurrentProcess(), Option.dwPriority);
    // �X���b�h���쐬
    Status.dwThreadStatus := WAVE_THREAD_SUSPEND;
    Status.dwThreadHandle := API_CreateThread(NULLPOINTER, NULL, @_WaveThread, NULLPOINTER, NULL, @Status.dwThreadID);
    // �E�B���h�E�ʒu��ݒ�
    cwWindowMain.SetWindowPosition(dwLeft, dwTop, 1024, 1024);
    // �E�B���h�E�����T�C�Y
    ResizeWindow();
    // �t�H�[�J�X��ݒ�
    SetTabFocus(hWndApp, true);
    // �X���b�h�̏�������������܂őҋ@
    while not longbool(Status.dwThreadStatus) do API_Sleep(1);
    // �R�}���h���C��������
    if longbool(Length(sCmdLine)) then begin
        // �o�b�t�@���m��
        GetMem(lpBuffer, 1024);
        // �o�b�t�@�ɃR�s�[
        API_ZeroMemory(lpBuffer, 1024);
        lpString := pchar(sCmdLine);
        API_MoveMemory(lpBuffer, lpString, Length(sCmdLine));
        // �t�@�C�����J��
        dwBuffer := GetFileType(lpBuffer, true, false);
        case dwBuffer of
            FILE_TYPE_SPC: SPCLoad(lpBuffer, true);
            FILE_TYPE_LIST_A, FILE_TYPE_LIST_B: ListLoad(lpBuffer, dwBuffer, false);
        end;
        // �o�b�t�@�����
        FreeMem(lpBuffer, 1024);
    end;
    // �t���O��ݒ�
    Status.dwTitle := Status.dwTitle or TITLE_NORMAL;
    cwWindowMain.SendMessage(WM_SIZE, $FFFFFFFF, NULL);
{$IFDEF SPCDEBUG}
    Apu.SetSPCDbg(@_SPCDebug, $10);
    Apu.SetDSPDbg(@_DSPDebug);
{$ENDIF}
end;

// ================================================================================
// DeleteWindow - �E�B���h�E�폜
// ================================================================================
procedure CWINDOWMAIN.DeleteWindow();
var
    I: longint;
    sChPath: string;
    NormalRect: TRECT;
    ScreenRect: TRECT;
    fsFile: textfile;

function GetBoolToInt(bValue: longbool): string;
begin
    if bValue then result := '1' else result := '0';
end;

begin
    // �v���Z�X�D��x��W���ɕύX
    API_SetPriorityClass(API_GetCurrentProcess(), NORMAL_PRIORITY_CLASS);
    // �f�o�C�X�����
    WaveQuit();
    // �X���b�h�ɏI����ʒm
    API_PostThreadMessage(Status.dwThreadID, WM_QUIT, NULL, NULL);
    // �ʏ��Ԃ̃E�B���h�E �T�C�Y���擾
    cwWindowMain.GetWindowRect(@NormalRect);
    // �X�N���[�� �T�C�Y���擾
    API_SystemParametersInfo(SPI_GETWORKAREA, NULL, @ScreenRect, NULL);
    // �J�����g �p�X���擾
    sChPath := Copy(string(Status.lpCurrentPath), 1, Status.lpCurrentSize);
    // ���s�[�g�J�n�ʒu�A���s�[�g�I���ʒu���ݒ�ς݂̏ꍇ�́A�{���̉��t�����ɖ߂�
    if Status.bTimeRepeat then Option.dwPlayOrder := Status.dwPlayOrder;
    // INI �t�@�C�����쐬
    AssignFile(fsFile, Concat(sChPath, INI_FILE));
    Rewrite(fsFile);
    Writeln(fsFile, SECTION_USER_POLICY);
    Writeln(fsFile, Concat(BUFFER_BUFNUM__, IntToStr(Option.dwBufferNum)));
    Writeln(fsFile, Concat(BUFFER_BUFTIME_, IntToStr(Option.dwBufferTime)));
    Writeln(fsFile, Concat(BUFFER_DRAWINFO, IntToStr(Option.dwDrawInfo)));
    Writeln(fsFile, Concat(BUFFER_FADELENG, IntToStr(Option.dwFadeTime)));
    Writeln(fsFile, Concat(BUFFER_FONTNAME, Option.sFontName));
    Writeln(fsFile, Concat(BUFFER_HIDELENG, IntToStr(Option.dwHideTime)));
    Writeln(fsFile, Concat(BUFFER_LANGUAGE, IntToStr(Option.dwLanguage)));
    Writeln(fsFile, Concat(BUFFER_LISTHGT_, IntToStr(Option.dwListHeight)));
    Writeln(fsFile, Concat(BUFFER_LISTMAX_, IntToStr(Option.dwListMax)));
    Writeln(fsFile, Concat(BUFFER_NEXTLENG, IntToStr(Option.dwNextTime)));
    Writeln(fsFile, Concat(BUFFER_PLAYLENG, IntToStr(Option.dwPlayTime)));
    Writeln(fsFile, Concat(BUFFER_SCALE___, IntToStr(Option.dwScale)));
    Writeln(fsFile, Concat(BUFFER_SEEKFAST, IntToStr(Option.dwSeekFast)));
    Writeln(fsFile, Concat(BUFFER_SEEKINT_, IntToStr(Option.dwSeekInt)));
    Writeln(fsFile, Concat(BUFFER_SEEKMAX_, IntToStr(Option.dwSeekMax)));
    Writeln(fsFile, Concat(BUFFER_SEEKNUM_, IntToStr(Option.dwSeekNum)));
    Writeln(fsFile, Concat(BUFFER_SPEEDTUN, IntToStr(Option.dwSpeedTun)));
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
    Writeln(fsFile, Concat(BUFFER_FEEDBACK, IntToStr(Option.dwFeedback)));
    Writeln(fsFile, Concat(BUFFER_INFO____, IntToStr(Option.dwInfo)));
    Writeln(fsFile, Concat(BUFFER_INTER___, IntToStr(Option.dwInter)));
    Writeln(fsFile, Concat(BUFFER_LEFT____, IntToStr(NormalRect.left + ScreenRect.left)));
    Writeln(fsFile, Concat(BUFFER_MUTE____, IntToStr(Option.dwMute)));
    Writeln(fsFile, Concat(BUFFER_NOISE___, IntToStr(Option.dwNoise)));
    Writeln(fsFile, Concat(BUFFER_OPTION__, IntToStr(Option.dwOption)));
    Writeln(fsFile, Concat(BUFFER_PITCH___, IntToStr(Option.dwPitch)));
    Writeln(fsFile, Concat(BUFFER_PITCHSNC, GetBoolToInt(Option.bPitchAsync)));
    Writeln(fsFile, Concat(BUFFER_PLAYDEF_, GetBoolToInt(Option.bPlayDefault)));
    Writeln(fsFile, Concat(BUFFER_PLAYTIME, GetBoolToInt(Option.bPlayTime)));
    Writeln(fsFile, Concat(BUFFER_PLAYTYPE, IntToStr(Option.dwPlayOrder)));
    Writeln(fsFile, Concat(BUFFER_PRIORITY, IntToStr(Option.dwPriority)));
    Writeln(fsFile, Concat(BUFFER_RATE____, IntToStr(Option.dwRate)));
    Writeln(fsFile, Concat(BUFFER_SEEKTIME, IntToStr(Option.dwSeekTime)));
    Writeln(fsFile, Concat(BUFFER_SEPARATE, IntToStr(Option.dwSeparate)));
    Writeln(fsFile, Concat(BUFFER_SPEED___, IntToStr(Option.dwSpeedBas)));
    Writeln(fsFile, Concat(BUFFER_TOP_____, IntToStr(NormalRect.top + ScreenRect.top)));
    Writeln(fsFile, Concat(BUFFER_TOPMOST_, GetBoolToInt(Option.bTopMost)));
    Writeln(fsFile, Concat(BUFFER_VERSION_, SPCPLAY_VERSION));
    Writeln(fsFile, Concat(BUFFER_VOLRESET, GetBoolToInt(Option.bVolumeReset)));
    CloseFile(fsFile);
    // �v���C���X�g �t�@�C�����쐬
    ListSave(pchar(Concat(sChPath, LIST_FILE)), true);
    // �X���b�h�����S�ɏI������܂őҋ@
    while longbool(Status.dwThreadStatus) do API_Sleep(1);
    // �X���b�h�����
    API_CloseHandle(Status.dwThreadHandle);
    // SNESAPU.DLL �����
    if longbool(Apu.hDLL) then API_FreeLibrary(Apu.hDLL);
{$IFDEF CONTEXT}
    // SNESAPU �R���e�L�X�g�����
    if longbool(Status.lpContext) then FreeMem(Status.lpContext, Status.dwContextSize);
{$ENDIF}
    // �f�o�C�X �R���e�L�X�g�����
    API_DeleteObject(API_SelectObject(Status.hDCVolumeBuffer, Status.hBitmapVolume));
    API_DeleteDC(Status.hDCVolumeBuffer);
    API_DeleteObject(API_SelectObject(Status.hDCStringBuffer, Status.hBitmapString));
    API_DeleteDC(Status.hDCStringBuffer);
    API_ReleaseDC(cwStaticMain.hWnd, Status.hDCStatic);
    // �o�b�t�@�����
    FreeMem(Status.lpCurrentPath, 1024);
    FreeMem(Status.lpSPCFile, 1024);
    FreeMem(Status.lpSPCDir, 1024);
    FreeMem(Status.lpSPCName, 1024);
    FreeMem(Status.lpOpenPath, 1024);
    FreeMem(Status.lpSavePath, 1024);
    // �E�B���h�E���폜
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
{$IFDEF ITASKBARLIST3}
    // COM �C���^�[�t�F�C�X�����
    API_CoUninitialize();
{$ENDIF}
end;

// ================================================================================
// DragFile - �t�@�C���̃h���b�O (�󂯓n��)
// ================================================================================
procedure CWINDOWMAIN.DragFile(msg: longword; wParam: longword; lParam: longword);
var
    x: longint;
    y: longint;
    dwIndex: longint;
    dwCount: longint;
    Rect: TRECT;
    lpFile: pointer;
    lpBuffer: pointer;
    IDropSourceVtbl: ^TIDROPSOURCEVTBL;
    IDropSource: ^TIDROPSOURCE;
    IDataObjectVtbl: ^TIDATAOBJECTVTBL;
    IDataObject: ^TIDATAOBJECT;
    DropFiles: ^TDROPFILES;
    FormatEtc: ^TFORMATETC;
    StgMedium: ^TSTGMEDIUM;
    KeyState: TKEYSTATE;
begin
    // �}�E�X���W���擾
    x := lParam and $FFFF;
    y := (lParam shr 16) and $FFFF;
    // �h���b�O���J�n���邩����
    case msg of
        WM_LBUTTONDOWN: begin // ���{�^��
            Status.DragPoint.x := x;
            Status.DragPoint.y := y;
            // �v���C���X�g�𑦎��ɔ��������邽�߂̃��b�Z�[�W�𑗐M
            cwPlayList.PostMessage(WM_LBUTTONUP, wParam, lParam);
            exit;
        end;
        WM_RBUTTONDOWN: begin // �E�{�^��
            Status.DragPoint.x := x;
            Status.DragPoint.y := y;
            exit;
        end;
        WM_MOUSEMOVE: begin // �}�E�X�ړ�
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
    // �}�E�X�J�[�\���ʒu��������
    Status.DragPoint.x := -1;
    Status.DragPoint.y := -1;
    // �L�[�{�[�h�̏�Ԃ��擾 (Status.bShiftButton ���ł͏�Ԃ��擾�s��)
    API_GetKeyboardState(@KeyState);
    // �}�E�X�̃{�^����������Ă��Ȃ��ꍇ�͏I��
    if not bytebool((KeyState.k[VK_LBUTTON] or KeyState.k[VK_RBUTTON]) and $80) then exit;
    // �}�E�X�̉E�{�^����������Ă���ꍇ�� Shift �L�[������
    if bytebool(KeyState.k[VK_RBUTTON] and $80) then SetChangeFunction(false);
    // �v���C���X�g�̃A�C�e�������擾
    dwCount := cwPlayList.SendMessage(LB_GETCOUNT, NULL, NULL);
    // �v���C���X�g�ɃA�C�e�����o�^����Ă��Ȃ��ꍇ�͏I��
    if not longbool(dwCount) then exit;
    // �I������Ă���A�C�e�����擾
    dwIndex := cwPlayList.SendMessage(LB_GETCURSEL, NULL, NULL);
    // �o�b�t�@���m��
    GetMem(lpFile, 1024);
    // �t�@�C���ƃ^�C�g�����擾
    API_ZeroMemory(lpFile, 1024);
    cwFileList.SendMessage(LB_GETTEXT, dwIndex, longword(lpFile));
    // �o�b�t�@���N���A
    IDropSourceVtbl := NULLPOINTER;
    IDropSource := NULLPOINTER;
    IDataObjectVtbl := NULLPOINTER;
    IDataObject := NULLPOINTER;
    DropFiles := NULLPOINTER;
    FormatEtc := NULLPOINTER;
    StgMedium := NULLPOINTER;
    // �t�@�C�������݂���ꍇ
    if IsSafePath(lpFile) and Exists(lpFile, $FFFFFFFF) then repeat
        // �O���[�o�� ���������m��
        IDropSourceVtbl := pointer(API_GlobalAlloc(GMEM_FIXED, SizeOf(TIDROPSOURCEVTBL)));
        IDropSource := pointer(API_GlobalAlloc(GMEM_FIXED, SizeOf(TIDROPSOURCE)));
        IDataObjectVtbl := pointer(API_GlobalAlloc(GMEM_FIXED, SizeOf(TIDATAOBJECTVTBL)));
        IDataObject := pointer(API_GlobalAlloc(GMEM_FIXED, SizeOf(TIDATAOBJECT)));
        DropFiles := pointer(API_GlobalAlloc(GMEM_FIXED, SizeOf(TDROPFILES) + 2048));
        FormatEtc := pointer(API_GlobalAlloc(GMEM_FIXED, SizeOf(TFORMATETC)));
        StgMedium := pointer(API_GlobalAlloc(GMEM_FIXED, SizeOf(TSTGMEDIUM)));
        // ���������m�ۂł��Ȃ��ꍇ�̓��[�v�𔲂���
        if not longbool(IDropSourceVtbl)
        or not longbool(IDropSource)
        or not longbool(IDataObjectVtbl)
        or not longbool(IDataObject)
        or not longbool(DropFiles)
        or not longbool(FormatEtc)
        or not longbool(StgMedium) then break;
        // �N���b�v�{�[�h�����擾
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
        // FORMATETC �\���̂�������
        FormatEtc.cfFormat := CF_HDROP;
        FormatEtc.ptd := NULLPOINTER;
        FormatEtc.dwAspect := DVASPECT_CONTENT;
        FormatEtc.lindex := -1;
        FormatEtc.tymed := TYMED_HGLOBAL;
        // STGMEDIUM �\���̂�������
        StgMedium.tymed := TYMED_HGLOBAL;
        StgMedium.handle := longword(DropFiles);
        StgMedium.pUnkForRelease := NULLPOINTER;
        // DROPSOURCE �\���̂�������
        IDropSourceVtbl.OLEIDropSourceQueryInterface := @_OLEIDropSourceQueryInterface;
        IDropSourceVtbl.OLEIDropSourceAddRef := @_OLEIDropSourceAddRef;
        IDropSourceVtbl.OLEIDropSourceRelease := @_OLEIDropSourceRelease;
        IDropSourceVtbl.OLEIDropSourceQueryContinueDrag := @_OLEIDropSourceQueryContinueDrag;
        IDropSourceVtbl.OLEIDropSourceGiveFeedback := @_OLEIDropSourceGiveFeedback;
        IDropSource.lpVtbl := IDropSourceVtbl;
        IDropSource.dwRefCnt := 1;
        // DATAOBJECT �\���̂�������
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
        // OLE ��������
        if API_OleInitialize(NULLPOINTER) = S_OK then begin
            // �v���C���X�g�ւ̃h���b�v���֎~
            Status.bDropCancel := true;
            // �h���b�O �A���h �h���b�v �C�x���g���J�n
            dwIndex := NULL;
            dwIndex := API_DoDragDrop(IDataObject, IDropSource, DROPEFFECT_COPY or DROPEFFECT_SCROLL, @dwIndex);
            // OLE �����
            API_OleUninitialize();
            // �h���b�v�֎~�̉�����\��
            cwWindowMain.PostMessage(WM_APP_MESSAGE, WM_APP_DRAG_DONE, dwIndex);
        end;
        // �o�b�t�@�����
        _OLEIDropSourceRelease(IDropSource);
        _OLEIDataObjectRelease(IDataObject);
        IDropSourceVtbl := NULLPOINTER;
        IDropSource := NULLPOINTER;
        IDataObjectVtbl := NULLPOINTER;
        IDataObject := NULLPOINTER;
        FormatEtc := NULLPOINTER;
        StgMedium := NULLPOINTER;
    until true;
    // �o�b�t�@�����
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
// DrawInfo - �C���W�P�[�^�̕`��
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
    // �S�̂��ĕ`�悷��ꍇ
    if bRedrawInfo then begin
        // �o�[��`��
        if cNowLevel > 0 then begin
            DrawInfoBitBlt(dwLeft, COLOR_BAR_HEIGHT_X2 - longword(cNowLevel), dwWidth, longword(cNowLevel),
                Status.hDCVolumeBuffer, dwColor, COLOR_BAR_HEIGHT - longword(cNowLevel));
        end;
        // �󔒕�����`��
        if cNowLevel < COLOR_BAR_HEIGHT then begin
            Rect.left := dwLeft;
            Rect.right := dwLeft + dwWidth;
            Rect.top := COLOR_BAR_HEIGHT;
            Rect.bottom := COLOR_BAR_HEIGHT_X2 - longword(cNowLevel);
            DrawInfoFillRect(@Rect, ORG_COLOR_BTNFACE);
        end;
    end else begin
        // ���x���l���O��Ɠ����ꍇ�͏I��
        if cLastLevel = cNowLevel then exit;
        // ���x���l���O����オ�����ꍇ�̓o�[��`��
        if cLastLevel < cNowLevel then begin
            DrawInfoBitBlt(dwLeft, COLOR_BAR_HEIGHT_X2 - longword(cNowLevel), dwWidth, longword(cNowLevel - cLastLevel),
                Status.hDCVolumeBuffer, dwColor, COLOR_BAR_HEIGHT - longword(cNowLevel));
        // ���x���l���O���艺�������ꍇ�͋󔒕�����`��
        end else begin
            Rect.left := dwLeft;
            Rect.right := dwLeft + dwWidth;
            Rect.top := COLOR_BAR_HEIGHT_X2 - longword(cLastLevel);
            Rect.bottom := COLOR_BAR_HEIGHT_X2 - longword(cNowLevel);
            DrawInfoFillRect(@Rect, ORG_COLOR_BTNFACE);
        end;
    end;
end;

procedure UpdateVolumeFrame(dwLeft: longint);
begin
    // �t���[����`��
    Rect.left := dwLeft;
    Rect.right := dwLeft + 1;
    Rect.top := COLOR_BAR_TOP_FRAME;
    Rect.bottom := COLOR_BAR_HEIGHT_X2;
    DrawInfoFillRect(@Rect, ORG_COLOR_GRAYTEXT);
end;

procedure UpdateVolumeBlank(dwLeft: longint);
begin
    // �󔒗̈��`��
    Rect.left := dwLeft;
    Rect.right := dwLeft + 27;
    Rect.top := COLOR_BAR_TOP;
    Rect.bottom := COLOR_BAR_HEIGHT_X2;
    DrawInfoFillRect(@Rect, ORG_COLOR_BTNFACE);
end;

procedure UpdateNumWrite(dwX: longint; dwL: longword);
var
    dwI: longint;
    dwJ: longint;
    cV: byte;
begin
    // �f�W�^��������`��
    dwJ := Y * COLOR_BAR_HEIGHT + dwX;
    dwX := dwX * BITMAP_NUM_WIDTH + Z;
    K := dwL - 1;
    L := Y * 12 + 25;
    for dwI := 0 to K do begin
        cV := StrData.bData[dwI];
        // �S�̂�`�悷��ꍇ�A�܂��́A�O��`��l����ω������ꍇ
        if bRedrawInfo or (Status.NumCache[dwJ] <> cV) then begin
            Status.NumCache[dwJ] := cV;
            J := longword(cV);
            case J of
                $20: J := BITMAP_NUM;  // SPACE
                $30..$39: Dec(J, $30); // 0 �` 9
                $41..$5A: Dec(J, $37); // A �` Z
                $61..$7A: Dec(J, $3D); // a �` z
            end;
            DrawInfoBitBlt(dwX, L, BITMAP_NUM_WIDTH, BITMAP_NUM_HEIGHT, Status.hDCStringBuffer, J * BITMAP_NUM_WIDTH, 0);
        end;
        Inc(dwJ);
        Inc(dwX, BITMAP_NUM_WIDTH);
    end;
end;

procedure DeleteMarkWrite(dwI: longint; dwY: longint);
begin
    // �ʒu�}�[�N������
    Rect.left := 137;
    Rect.right := 283 + (Status.dwScale and 1);
    Rect.top := dwY;
    Rect.bottom := dwY + (Status.dwScale and 1) + 3;
    DrawInfoFillRect(@Rect, ORG_COLOR_BTNFACE);
end;

procedure UpdateMarkWrite(dwI: longint; dwY: longint);
begin
    // �ʒu�}�[�N��`��
    DeleteMarkWrite(dwI, dwY);
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

procedure UpdateChannelSource();
begin
    // �S�̂��ĕ`�悷��ꍇ�͂�������`��̈���N���A
    if Status.bChangeBreak then begin
        StrData.dwData[0] := $202020; // '   '
        Z := 0;
        UpdateNumWrite(X, 3);
    end;
    // ���F�ԍ���`��
    J := DspVoice.SoundSourcePlayBack;
    if Status.bBreakButton then begin
        Z := 0;
        UpdateNumWrite(X, IntToStr(StrData, J, 3));
    end else begin
        Z := 3;
        UpdateNumWrite(X, IntToHex(StrData, J, 2));
    end;
end;

begin
    // �o�b�t�@��ݒ�
    ApuData := pApuData;
    DspReg := @ApuData.DspReg;
    Voices := @ApuData.Voices;
    T64Count := ApuData.T64Count;
    // �ĕ`��t���O��ݒ�
    bRedrawInfo := longbool(Status.dwRedrawInfo and REDRAW_ON);
    // ����͍ĕ`�悵�Ȃ�
    Status.dwRedrawInfo := REDRAW_OFF;
    // ���Ԃ�`��
    Y := 0;
    Z := 0;
    UpdateNumWrite(11, IntToStr(StrData, T64Count div 230400000, 1));
    UpdateNumWrite(13, IntToStr(StrData, T64Count div 3840000 mod 60, 2));
    UpdateNumWrite(16, IntToStr(StrData, T64Count div 64000 mod 60, 2));
    UpdateNumWrite(19, IntToStr(StrData, T64Count div 64, 3));
    if Status.bTimeRepeat then begin
        // ���s�[�g�J�n�ʒu��`��
        if Status.dwStartTime >= Status.dwDefaultTimeout then J := 280
        else J := Trunc(Status.dwStartTime / Status.dwDefaultTimeout * 141) + 139;
        if bRedrawInfo or (J <> Status.dwLastStartTime) then UpdateMarkWrite(0, 24);
        Status.dwLastStartTime := J;
        // ���s�[�g�I���ʒu��`��
        if Status.dwLimitTime >= Status.dwDefaultTimeout then J := 280
        else J := Trunc(Status.dwLimitTime / Status.dwDefaultTimeout * 141) + 139;
        if bRedrawInfo or (J <> Status.dwLastLimitTime) then UpdateMarkWrite(1, 32);
        Status.dwLastLimitTime := J;
    end else begin
        // ���s�[�g�ʒu������
        if bRedrawInfo then begin
            DeleteMarkWrite(0, 24);
            DeleteMarkWrite(1, 32);
        end;
    end;
    if Option.bPlayTime then begin
        // �^�C�� �Q�[�W��`��
        if not Status.bPlay then J := 140
        else if T64Count >= Status.dwDefaultTimeout then J := 280
        else J := Trunc(T64Count / Status.dwDefaultTimeout * 141) + 140;
        if bRedrawInfo or (J <> Status.dwLastTime) then begin
            if J > 140 then begin
                Rect.left := 140;
                Rect.right := J;
                Rect.top := 27;
                Rect.bottom := 32;
                DrawInfoFillRect(@Rect, ORG_COLOR_WINDOWTEXT);
            end;
            if J < 280 then begin
                Rect.left := J;
                Rect.right := 280;
                Rect.top := 27;
                Rect.bottom := 28;
                DrawInfoFillRect(@Rect, ORG_COLOR_BTNFACE);
                Rect.top := 28;
                Rect.bottom := 31;
                DrawInfoFillRect(@Rect, ORG_COLOR_GRAYTEXT);
                Rect.top := 31;
                Rect.bottom := 32;
                DrawInfoFillRect(@Rect, ORG_COLOR_BTNFACE);
            end;
        end;
        // �f�[�^���R�s�[
        Status.dwLastTime := J;
    end else begin
        // �^�C�� �Q�[�W������
        if bRedrawInfo then begin
            Rect.left := 137;
            Rect.right := 283 + (Status.dwScale and 1);
            Rect.top := 24;
            Rect.bottom := 35 + (Status.dwScale and 1);
            DrawInfoFillRect(@Rect, ORG_COLOR_BTNFACE);
        end;
    end;
    // �C���W�P�[�^��`��
    case Option.dwInfo of
        INFO_INDICATOR: begin
            // �e���x���l���v�Z
            if bWave and not Status.bPause then begin
                Status.NowLevel.cMasterLevelLeft := Max(Status.NowLevel.cMasterLevelLeft - byte(Option.dwVolumeSpeed), GetVolumeLevel(ApuData.VolumeMaxLeft));
                Status.NowLevel.cMasterLevelRight := Max(Status.NowLevel.cMasterLevelRight - byte(Option.dwVolumeSpeed), GetVolumeLevel(ApuData.VolumeMaxRight));
                Status.NowLevel.cMasterVolumeLeft := GetLevelAbs(DspReg.MainVolumeLeft);
                Status.NowLevel.cMasterVolumeRight := GetLevelAbs(DspReg.MainVolumeRight);
                Status.NowLevel.cMasterEchoLeft := GetLevelAbs(DspReg.EchoVolumeLeft);
                Status.NowLevel.cMasterEchoRight := GetLevelAbs(DspReg.EchoVolumeRight);
                Status.NowLevel.cMasterDelay := GetLevelDelay(DspReg.EchoDelay);
                Status.NowLevel.cMasterFeedback := GetLevelAbs(DspReg.EchoFeedback);
                for I := 0 to 7 do begin
                    Voice := @Voices.Voice[I];
                    DspVoice := @DspReg.Voice[I];
                    Status.NowLevel.Channel[I].cChannelLevelLeft := Max(Status.NowLevel.Channel[I].cChannelLevelLeft - byte(Option.dwVolumeSpeed), GetVolumeLevel(Voice.VolumeMaxLeft));
                    Status.NowLevel.Channel[I].cChannelLevelRight := Max(Status.NowLevel.Channel[I].cChannelLevelRight - byte(Option.dwVolumeSpeed), GetVolumeLevel(Voice.VolumeMaxRight));
                    Status.NowLevel.Channel[I].cChannelVolumeLeft := GetLevelAbs(DspVoice.VolumeLeft);
                    Status.NowLevel.Channel[I].cChannelVolumeRight := GetLevelAbs(DspVoice.VolumeRight);
                    Status.NowLevel.Channel[I].cChannelPitch := GetPitchLevel(DspVoice.Pitch);
                    Status.NowLevel.Channel[I].cChannelEnvelope := GetLevelAbs(DspVoice.CurrentEnvelope);
                    if Option.bVolumeReset then begin
                        if not longbool(Voice.VolumeMaxLeft) and not longbool(Voice.VolumeMaxRight) then Wave.dwTimeout[I] := Min(Option.dwHideTime, Wave.dwTimeout[I] + Option.dwBufferTime)
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
            // �S�̂��ĕ`�悷��ꍇ�� MIXER �ƃt���[����`��
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
            // �}�X�^�[�̃C���W�P�[�^��`��
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
                // �S�̂��ĕ`�悷��ꍇ�̓`�����l���ԍ��ƃt���[����`��
                if bRedrawInfo then begin
                    Z := 0;
                    StrData.dwData[0] := I + $31;
                    UpdateNumWrite(X + 8, 1);
                    UpdateVolumeFrame(V + 76);
                    Status.LastLevel.Channel[I].dwChannelEffect.Update := true;
                end;
                // �e�`�����l���̃C���W�P�[�^��`��
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
                    UpdateVolumeWrite(Status.LastLevel.Channel[I].cChannelVolumeLeft, Status.NowLevel.Channel[I].cChannelVolumeLeft, COLOR_BAR_GREEN, V + 48, 3);
                    UpdateVolumeWrite(Status.LastLevel.Channel[I].cChannelVolumeRight, Status.NowLevel.Channel[I].cChannelVolumeRight, COLOR_BAR_GREEN, V + 52, 3);
                    UpdateVolumeWrite(Status.LastLevel.Channel[I].cChannelPitch, Status.NowLevel.Channel[I].cChannelPitch, COLOR_BAR_ORANGE, V + 56, 3);
                    UpdateVolumeWrite(Status.LastLevel.Channel[I].cChannelEnvelope, Status.NowLevel.Channel[I].cChannelEnvelope, COLOR_BAR_RED, V + 60, 3);
                    UpdateVolumeWrite(Status.LastLevel.Channel[I].cChannelLevelLeft, Status.NowLevel.Channel[I].cChannelLevelLeft, COLOR_BAR_BLUE, V + 64, 5);
                    UpdateVolumeWrite(Status.LastLevel.Channel[I].cChannelLevelRight, Status.NowLevel.Channel[I].cChannelLevelRight, COLOR_BAR_BLUE, V + 70, 5);
                end else if Status.LastLevel.Channel[I].bChannelShow then begin
                    Z := 3;
                    StrData.dwData[0] := $202020; // '   '
                    UpdateNumWrite(X + 9, 3);
                    UpdateVolumeBlank(V + 48);
                end;
                Inc(X, 5);
                Inc(V, 30);
            end;
            // �f�[�^���R�s�[
            Status.LastLevel := Status.NowLevel;
        end;
        INFO_MIXER: begin
            // �~�L�T�[����`��
            Y := 1;
            Z := 0;
            UpdateNumWrite(13, IntToHex(StrData, DspReg.MainVolumeLeft, 2));
            UpdateNumWrite(19, IntToHex(StrData, DspReg.MainVolumeRight, 2));
            UpdateNumWrite(38, IntToHex(StrData, DspReg.EchoVolumeLeft, 2));
            UpdateNumWrite(44, IntToHex(StrData, DspReg.EchoVolumeRight, 2));
            Y := 2;
            UpdateNumWrite(11, IntToHex(StrData, DspReg.EchoDelay, 2));
            UpdateNumWrite(15, IntToStr(StrData, (DspReg.EchoDelay and $F) shl 4, 3));
            UpdateNumWrite(36, IntToHex(StrData, DspReg.EchoFeedback, 2));
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
            StrData.cData[0] := BoolTable[(V shr 7) and $1];
            UpdateNumWrite(13, 1);
            StrData.cData[0] := BoolTable[(V shr 6) and $1];
            UpdateNumWrite(17, 1);
            StrData.cData[0] := BoolTable[(V shr 5) and $1];
            UpdateNumWrite(21, 1);
            StrData.qwData := NOISE_RATE[V and $1F];
            UpdateNumWrite(36, 5);
            Y := 5;
            for I := 0 to 7 do UpdateNumWrite(11 + I * 3, IntToHex(StrData, DspReg.Voice[I].Fir, 2));
        end;
        INFO_CHANNEL_1: for I := 0 to 7 do begin
            // �e�`�����l������`��
            X := I div 4 * 25 + 4;
            Y := I mod 4 + 2;
            DspVoice := @DspReg.Voice[I];
            UpdateChannelSource();
            Z := 0;
            UpdateNumWrite(X +  4, IntToHex(StrData, DspVoice.VolumeLeft, 2));
            UpdateNumWrite(X +  7, IntToHex(StrData, DspVoice.VolumeRight, 2));
            UpdateNumWrite(X + 16, IntToHex(StrData, DspVoice.CurrentEnvelope, 2));
            Z := 3;
            UpdateNumWrite(X + 10, IntToHex(StrData, DspVoice.Pitch, 4));
        end;
        INFO_CHANNEL_2: for I := 0 to 7 do begin
            // �e�`�����l������`��
            X := I div 4 * 25 + 4;
            Y := I mod 4 + 2;
            DspVoice := @DspReg.Voice[I];
            UpdateChannelSource();
            Voice := @Voices.Voice[I];
            Z := 0;
            if not longbool(T64Count) then begin
                // ���t��~��
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
                    V := Voice.EnvelopeCurrentMode and $F;
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
                    V := Voice.EnvelopeCurrentMode and $F;
                    if V = $7 then StrData.dwData[0] := $6D // 'm'
                    else StrData.dwData[0] := $54; // 'T'
                    UpdateNumWrite(X + 12, 1);
                end;
            end;
            if Status.bBreakButton then begin
                StrData.dwData[0] := $6E; // 'n'
                UpdateNumWrite(X + 15, 1);
                UpdateNumWrite(X + 16, IntToHex(StrData, DspVoice.CurrentOutput, 2));
            end else begin
                StrData.dwData[0] := $54; // 'T'
                UpdateNumWrite(X + 15, 1);
                UpdateNumWrite(X + 16, IntToHex(StrData, DspVoice.CurrentEnvelope, 2));
            end;
        end;
        INFO_CHANNEL_3: for I := 0 to 7 do begin
            // �e�`�����l������`��
            X := I div 4 * 25 + 4;
            Y := I mod 4 + 2;
            V := 1 shl I;
            DspVoice := @DspReg.Voice[I];
            UpdateChannelSource();
            Voice := @Voices.Voice[I];
            if not longbool(Voice.VolumeMaxLeft) and not longbool(Voice.VolumeMaxRight) then StrData.dwData[0] := $5656 else StrData.dwData[0] := $4847; // 'VV' or 'GH'
            Z := 0;
            UpdateNumWrite(X +  4, 2);
            if not bytebool(DspReg.EchoOn and V) then StrData.dwData[0] := $56 else StrData.dwData[0] := $49; // 'V' or 'I'
            Z := 0;
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
            // �e�`�����l������`��
            X := I div 4 * 25 + 4;
            Y := I mod 4 + 2;
            DspVoice := @DspReg.Voice[I];
            UpdateChannelSource();
            Z := 0;
            Voice := @Voices.Voice[I];
            UpdateNumWrite(X +  4, IntToHex(StrData, ApuData.SPCSrcAddrs.Src[DspVoice.SoundSourcePlayBack].wStart, 4));
            UpdateNumWrite(X +  9, IntToHex(StrData, ApuData.SPCSrcAddrs.Src[DspVoice.SoundSourcePlayBack].wLoop, 4));
            UpdateNumWrite(X + 14, IntToHex(StrData, longword(Voice.CurrentBlock), 4));
        end;
        INFO_SPC_2: begin
            // SPC ���W�X�^����`��
            SPC700Reg := @ApuData.SPC700Reg;
            Y := 5;
            Z := 0;
            UpdateNumWrite(14, IntToHex(StrData, SPC700Reg.pc, 4));
            UpdateNumWrite(22, IntToHex(StrData, SPC700Reg.ya, 4));
            UpdateNumWrite(29, IntToHex(StrData, SPC700Reg.x, 2));
            UpdateNumWrite(35, IntToHex(StrData, SPC700Reg.sp, 2));
            for I := 0 to 7 do StrData.cData[I] := BoolTable[(SPC700Reg.psw[7 - I] and $100) shr 8];
            UpdateNumWrite(39, 8);
        end;
        INFO_SCRIPT700: begin
            // Script700 ����`��
            Script700 := @ApuData.Script700;
            Y := 1;
            Z := 0;
            for I := 0 to 3 do UpdateNumWrite(I * 3 + 11, IntToHex(StrData, ApuData.SPCApuPort.Port[I], 2));
            for I := 0 to 3 do UpdateNumWrite(I * 3 + 31, IntToHex(StrData, ApuData.SPCOutPort.Port[I], 2));
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
            StrData.cData[2] := BoolTable[Script700.dwStackFlag and $1];
            UpdateNumWrite(43, 3);
        end;
    end;
    // GDI �`����t���b�V��
    API_GdiFlush();
end;

// ================================================================================
// DropFile - �t�@�C���̃h���b�v (�󂯎��)
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
    // ������
    result := 1;
    // �\�[�g�p���X�g���N���A
    cwSortList.SendMessage(LB_RESETCONTENT, NULL, NULL);
    // �|�C���^�̍��W���擾
    API_DragQueryPoint(dwParam, @Point);
    // �h���b�v���ꂽ�ꏊ�̌��o
    if Status.dwScale = 2 then bAdd := Point.x >= LIST_ADD_THRESHOLD
    else bAdd := Point.x >= (LIST_ADD_THRESHOLD * Status.dwScale) shr 1;
    bList := false;
    // �h���b�v���ꂽ�t�@�C�������擾
    dwCount := API_DragQueryFile(dwParam, $FFFFFFFF, NULLPOINTER, NULL);
    // �t�@�C�����h���b�v����Ȃ������ꍇ�A�܂��́A�t�@�C������ 1�A���h���b�v���֎~����Ă���ꍇ�͏I��
    if not longbool(dwCount) or (bAdd and (dwCount = 1) and Status.bDropCancel) then begin
        // �h���b�O�I��
        API_DragFinish(dwParam);
        // �I��
        exit;
    end;
    // �t�@�C�������ő�l�ȏ�̏ꍇ�͍ő�l�ɐݒ�
    if dwCount >= Option.dwListMax then dwCount := Option.dwListMax;
    // �o�b�t�@���m��
    GetMem(lpFile, 1024);
    // ���ׂẴt�@�C�����m�F
    for I := 0 to dwCount - 1 do begin
        // �t�@�C�����擾
        API_ZeroMemory(lpFile, 1024);
        API_DragQueryFile(dwParam, I, lpFile, 260);
        // �t�@�C���̎�ނ��擾
        dwType := GetFileType(lpFile, dwCount = 1, dwCount = 1);
        case dwType of
            FILE_TYPE_SPC: if (dwCount = 1) and not bAdd then SPCLoad(lpFile, true)
                else cwSortList.SendMessage(LB_ADDSTRING, NULL, longword(lpFile));
            FILE_TYPE_LIST_A, FILE_TYPE_LIST_B: if not bList then bList := ListLoad(lpFile, dwType, false);
            FILE_TYPE_FOLDER: begin
                // �^�C�g�����X�V
                cwWindowMain.SetCaption(pchar(Concat(TITLE_INFO_HEADER[Status.dwLanguage], TITLE_INFO_FILE_APPEND[Status.dwLanguage], TITLE_INFO_FOOTER[Status.dwLanguage], TITLE_MAIN_HEADER[Status.dwLanguage], DEFAULT_TITLE)));
                // �t�@�C�� �p�X��������
                dwPathSize := GetSize(lpFile, 260);
                API_ZeroMemory(@cFilePath[0], 260);
                API_MoveMemory(@cFilePath[0], lpFile, dwPathSize);
                if not IsPathSeparator(string(cFilePath), dwPathSize) then begin
                    if longbool(Pos('/', string(cFilePath))) then cFilePath[dwPathSize] := '/'
                    else cFilePath[dwPathSize] := '\';
                    Inc(dwPathSize);
                end;
                cFilePath[dwPathSize] := '*';
                // SPC �t�@�C��������
                hFile := INVALID_HANDLE_VALUE;
                if IsSafePath(@cFilePath) then hFile := API_FindFirstFile(@cFilePath, @Win32_Find_Data);
                if hFile < INVALID_HANDLE_VALUE then while true do begin
                    if not IsSingleByte(string(Win32_Find_Data.cFileName), 1, '.') then begin
                        dwFileSize := GetSize(@Win32_Find_Data.cFileName[0], 260);
                        if dwPathSize + dwFileSize < 260 then begin
                            API_MoveMemory(@cFilePath[dwPathSize], @Win32_Find_Data.cFileName[0], dwFileSize);
                            API_ZeroMemory(@cFilePath[dwPathSize + dwFileSize], 260 - dwPathSize - dwFileSize);
                            if GetFileType(@cFilePath, false, false) = FILE_TYPE_SPC then cwSortList.SendMessage(LB_ADDSTRING, NULL, longword(@cFilePath));
                        end;
                    end;
                    if not API_FindNextFile(hFile, @Win32_Find_Data) then begin
                        API_FindClose(hFile);
                        break;
                    end;
                end;
                // �^�C�g�����X�V
                UpdateTitle(NULL);
            end;
            FILE_TYPE_SCRIPT700: if dwCount = 1 then ReloadScript700(lpFile);
        end;
    end;
    // �o�b�t�@�����
    FreeMem(lpFile, 1024);
    // �h���b�O�I��
    API_DragFinish(dwParam);
    // SPC �t�@�C�����v���C���X�g�ɓo�^
    AppendList();
end;

// ================================================================================
// GetFileType - �t�@�C�� �^�C�v�擾
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
    // ������
    result := FILE_TYPE_NOTEXIST;
    repeat
        // �p�X�̈��S�����m�F
        bSafe := IsSafePath(lpFile);
        // �t�H���_�����݂���ꍇ
        if bSafe and Exists(lpFile, 0) then begin
            result := FILE_TYPE_FOLDER;
            break;
        end;
        // �t�@�C�������݂��Ȃ��ꍇ
        if bSafe and not Exists(lpFile, $FFFFFFFF) then break;
        // ������
        result := FILE_TYPE_NOTREAD;
        // �t�@�C�����I�[�v��
        hFile := INVALID_HANDLE_VALUE;
        if bSafe then hFile := API_CreateFile(lpFile, GENERIC_READ, FILE_SHARE_READ, NULLPOINTER, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL or FILE_FLAG_SEQUENTIAL_SCAN, NULL);
        // �t�@�C���̃I�[�v���Ɏ��s�����ꍇ�̓��[�v�𔲂���
        if hFile = INVALID_HANDLE_VALUE then break;
        // ������
        result := FILE_TYPE_UNKNOWN;
        // �t�@�C���̊g���q���擾
        if bScript700 and (
               IsExt(lpFile, Concat('.', SCRIPT700_FILETYPE))
            or IsExt(lpFile, Concat('.', SCRIPT7SE_FILETYPE))
            or IsExt(lpFile, Concat('.', SCRIPT700TXT_FILETYPE))
            or IsExt(lpFile, Concat('.', SCRIPT7SETXT_FILETYPE))
        ) then result := FILE_TYPE_SCRIPT700;
        // �t�@�C�������[�h
        API_ZeroMemory(@cBuffer[0], 64);
        API_ReadFile(hFile, @cBuffer[0], 64, @dwReadSize, NULLPOINTER);
        // �o�b�t�@���R�s�[
        API_MoveMemory(@cSPCHeader[0], @cBuffer[0], SPC_FILE_HEADER_LEN);
        API_MoveMemory(@cListHeaderA[0], @cBuffer[0], LIST_FILE_HEADER_A_LEN);
        API_MoveMemory(@cListHeaderB[0], @cBuffer[0], LIST_FILE_HEADER_B_LEN);
        // �t�@�C���̎�ނ��擾
        if string(cSPCHeader) = SPC_FILE_HEADER then result := FILE_TYPE_SPC;
        if string(cListHeaderA) = LIST_FILE_HEADER_A then result := FILE_TYPE_LIST_A;
        if string(cListHeaderB) = LIST_FILE_HEADER_B then result := FILE_TYPE_LIST_B;
        // �t�@�C�����N���[�Y
        API_CloseHandle(hFile);
    until true;
    // �t�@�C���`�����s���̏ꍇ�̓��b�Z�[�W��\��
    if bShowMsg then case result of
        FILE_TYPE_NOTEXIST, FILE_TYPE_NOTREAD, FILE_TYPE_UNKNOWN: ShowErrMsg(200 + result);
    end;
end;

// ================================================================================
// GetID666Format - ID666 �t�H�[�}�b�g �^�C�v�擾
// ================================================================================
procedure CWINDOWMAIN.GetID666Format(var Hdr: TSPCHDR);
var
    Bin: array[0..255] of byte;
begin
    // ������
    API_MoveMemory(@Bin[0], @Hdr, 256);
    Hdr.TagFormat := ID666_UNKNOWN;
    // ID666 �t�H�[�}�b�g�̎�ނ��擾
    if (Bin[$23] = $1A) or (
        // PHASE 1
        bytebool(((Bin[$2E] or Bin[$4E] or Bin[$6E] or Bin[$7E] or Bin[$B0] or Bin[$B1]) and $E0) or Bin[$24] or Bin[$9E] or Bin[$A9] or Bin[$AC] or Bin[$D1] or Bin[$D2])) then begin
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
// GetSize - ������o�b�t�@�̎g�p�o�C�g���擾
// ================================================================================
function CWINDOWMAIN.GetSize(lpBuffer: pointer; dwMax: longword): longword;
var
    dwOffset: longword;
begin
    // ������
    result := 0;
    dwOffset := longword(lpBuffer);
    while bytebool(pointer(dwOffset + result)^) and (result < dwMax) do Inc(result);
end;

// ================================================================================
// IsExt - �p�X�̊g���q���m�F
// ================================================================================
function CWINDOWMAIN.IsExt(lpFile: pointer; sExt: string): longbool;
var
    I: longint;
    dwSize: longword;
    dwExtSize: longword;
    cBuffer: array of char;
    V: byte;
begin
    // ������
    result := false;
    // �o�b�t�@ �T�C�Y���g���q�T�C�Y�����̏ꍇ�͎��s
    dwSize := GetSize(lpFile, 1024);
    dwExtSize := Length(sExt);
    if dwSize < dwExtSize then exit;
    // �g���q�������R�s�[
    SetLength(cBuffer, dwExtSize);
    API_MoveMemory(@cBuffer[0], pointer(longword(lpFile) + dwSize - dwExtSize), dwExtSize);
    // �啶���ɕϊ�
    for I := 0 to dwExtSize - 1 do begin
        V := byte(cBuffer[I]);
        if (V >= $61) and (V <= $7A) then cBuffer[I] := char(V - $20);
    end;
    // ��v����
    result := string(cBuffer) = sExt;
end;

// ================================================================================
// IsSafePath - �p�X�̈��S�����m�F
// ================================================================================
function CWINDOWMAIN.IsSafePath(lpFile: pointer): longbool;
var
    dwSize: longword;
    dwValue: ^longword;
begin
    // ������
    result := false;
    // �o�b�t�@ �T�C�Y�� 4 �o�C�g�����̏ꍇ�͎��s
    dwSize := GetSize(lpFile, 4);
    if dwSize < 4 then exit;
    // \\.\ ����n�܂�ꍇ�͎��s
    dwValue := lpFile;
    if dwValue^ = $5C2E5C5C then exit;
    // ����
    result := true;
end;

// ================================================================================
// ListAdd - �v���C���X�g�ǉ�
// ================================================================================
procedure CWINDOWMAIN.ListAdd(dwAuto: longword);
var
    dwIndex: longint;
    dwCount: longint;
    dwSelect: longint;
    bAdd: longbool;
    lpTitle: pointer;
begin
    // SPC ���J����Ă��Ȃ��ꍇ�͏I��
    if not Status.bOpen then exit;
    // �v���C���X�g�̃A�C�e�������擾
    dwCount := cwPlayList.SendMessage(LB_GETCOUNT, NULL, NULL);
    // �v���C���X�g�̃A�C�e�������ő�l�ȏ�̏ꍇ�͏I��
    if dwCount >= Option.dwListMax then exit;
    // �I������Ă���A�C�e�����擾
    dwIndex := cwPlayList.SendMessage(LB_GETCURSEL, NULL, NULL);
    // �ǉ����}�����擾
    case dwAuto of
        1: bAdd := true;
        2: bAdd := not longbool(dwCount);
        else bAdd := not Status.bShiftButton or not longbool(dwCount);
    end;
    if bAdd then dwSelect := dwCount else dwSelect := dwIndex;
    // �t�@�C����ǉ�
    if bAdd then cwFileList.SendMessage(LB_ADDSTRING, NULL, longword(Status.lpSPCFile))
    else cwFileList.SendMessage(LB_INSERTSTRING, dwIndex, longword(Status.lpSPCFile));
    // �^�C�g�����擾
    GetMem(lpTitle, 33);
    API_ZeroMemory(lpTitle, 33);
    API_MoveMemory(lpTitle, @Spc.Hdr.Title[0], 32);
    // �v���C���X�g�ɒǉ�
    if bAdd then begin
        cwPlayList.SendMessage(LB_ADDSTRING, NULL, longword(lpTitle));
        cwPlayList.SendMessage(LB_SETITEMDATA, dwCount, NULL);
    end else begin
        cwPlayList.SendMessage(LB_INSERTSTRING, dwIndex, longword(lpTitle));
        cwPlayList.SendMessage(LB_SETITEMDATA, dwIndex, NULL);
    end;
    FreeMem(lpTitle, 33);
    // �v���C���X�g�̃A�C�e����I��
    cwPlayList.SendMessage(LB_SETCURSEL, dwSelect, NULL);
    // ���j���[���X�V
    UpdateMenu();
end;

// ================================================================================
// ListClear - �v���C���X�g �N���A
// ================================================================================
procedure CWINDOWMAIN.ListClear();
begin
    // �v���C���X�g�����ׂăN���A
    cwFileList.SendMessage(LB_RESETCONTENT, NULL, NULL);
    cwPlayList.SendMessage(LB_RESETCONTENT, NULL, NULL);
    // ���j���[���X�V
    UpdateMenu();
end;

// ================================================================================
// ListDelete - �v���C���X�g�폜
// ================================================================================
procedure CWINDOWMAIN.ListDelete();
var
    dwIndex: longint;
    dwTopIndex: longint;
    dwCount: longint;
begin
    // �v���C���X�g�̃A�C�e�������擾
    dwCount := cwPlayList.SendMessage(LB_GETCOUNT, NULL, NULL);
    // �v���C���X�g�ɃA�C�e�����o�^����Ă��Ȃ��ꍇ�͏I��
    if not longbool(dwCount) then exit;
    // �I������Ă���A�C�e�����擾
    dwIndex := cwPlayList.SendMessage(LB_GETCURSEL, NULL, NULL);
    dwTopIndex := cwPlayList.SendMessage(LB_GETTOPINDEX, NULL, NULL);
    // �t�@�C���ƃ^�C�g�����폜
    cwFileList.SendMessage(LB_DELETESTRING, dwIndex, NULL);
    cwPlayList.SendMessage(LB_DELETESTRING, dwIndex, NULL);
    Dec(dwCount);
    // �v���C���X�g�̃A�C�e����I��
    if dwIndex >= dwCount then dwIndex := dwCount - 1;
    cwPlayList.SendMessage(LB_SETTOPINDEX, dwTopIndex, NULL);
    cwPlayList.SendMessage(LB_SETCURSEL, dwIndex, NULL);
    // ���j���[���X�V
    UpdateMenu();
end;

// ================================================================================
// ListDown - �v���C���X�g�̍��ڂ����ֈړ�
// ================================================================================
procedure CWINDOWMAIN.ListDown();
var
    lpFile: pointer;
    lpTitle: pointer;
    dwIndex: longint;
    dwCount: longint;
    dwItemData: longword;
begin
    // �v���C���X�g�̃A�C�e�������擾
    dwCount := cwPlayList.SendMessage(LB_GETCOUNT, NULL, NULL);
    // �v���C���X�g�ɃA�C�e�����o�^����Ă��Ȃ��ꍇ�͏I��
    if not longbool(dwCount) then exit;
    // �I������Ă���A�C�e�����擾
    dwIndex := cwPlayList.SendMessage(LB_GETCURSEL, NULL, NULL);
    // ��ԉ��̃A�C�e�����I������Ă���ꍇ�͏I��
    if dwIndex >= dwCount - 1 then exit;
    // �o�b�t�@���m��
    GetMem(lpFile, 1024);
    GetMem(lpTitle, 33);
    // �t�@�C���ƃ^�C�g�����擾
    API_ZeroMemory(lpFile, 1024);
    cwFileList.SendMessage(LB_GETTEXT, dwIndex, longword(lpFile));
    API_ZeroMemory(lpTitle, 33);
    cwPlayList.SendMessage(LB_GETTEXT, dwIndex, longword(lpTitle));
    dwItemData := cwPlayList.SendMessage(LB_GETITEMDATA, dwIndex, NULL);
    // �J�[�\����ݒ�
    Inc(dwIndex);
    cwPlayList.SendMessage(LB_SETCURSEL, dwIndex, NULL);
    // �폜
    Dec(dwIndex);
    cwFileList.SendMessage(LB_DELETESTRING, dwIndex, NULL);
    cwPlayList.SendMessage(LB_DELETESTRING, dwIndex, NULL);
    // �}��
    Inc(dwIndex);
    cwFileList.SendMessage(LB_INSERTSTRING, dwIndex, longword(lpFile));
    cwPlayList.SendMessage(LB_INSERTSTRING, dwIndex, longword(lpTitle));
    cwPlayList.SendMessage(LB_SETITEMDATA, dwIndex, dwItemData);
    // �J�[�\����ݒ�
    cwPlayList.SendMessage(LB_SETCURSEL, dwIndex, NULL);
    // �o�b�t�@�����
    FreeMem(lpFile, 1024);
    FreeMem(lpTitle, 33);
    // ���j���[���X�V
    UpdateMenu();
end;

// ================================================================================
// ListLoad - �v���C���X�g���J��
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
        // �t�@�C�����I�[�v��
        hFile := INVALID_HANDLE_VALUE;
        if IsSafePath(lpFile) then hFile := API_CreateFile(lpFile, GENERIC_READ, FILE_SHARE_READ, NULLPOINTER, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL or FILE_FLAG_SEQUENTIAL_SCAN, NULL);
        // �t�@�C���̃I�[�v���Ɏ��s�����ꍇ�̓��[�v�𔲂���
        if hFile = INVALID_HANDLE_VALUE then break;
        // �v���C���X�g���N���A
        cwFileList.SendMessage(LB_RESETCONTENT, NULL, NULL);
        cwPlayList.SendMessage(LB_RESETCONTENT, NULL, NULL);
        // �v���C���X�g�̃A�C�e�����ƌ��݂̏ꏊ���擾
        dwListNum := 0;
        dwTopIndex := 0;
        dwIndex := 0;
        case dwType of
            FILE_TYPE_LIST_A: begin
                // �w�b�_���擾
                API_ReadFile(hFile, @cListHeader, LIST_FILE_HEADER_A_LEN, @dwReadSize, NULLPOINTER);
                // �t�@�C���̃��[�h�Ɏ��s�����ꍇ�̓��[�v�𔲂���
                if not longbool(dwReadSize) then break;
                // �A�C�e�������擾
                API_ReadFile(hFile, @dwListNum, 4, @dwReadSize, NULLPOINTER);
                // �t�@�C���̃��[�h�Ɏ��s�����ꍇ�̓��[�v�𔲂���
                if not longbool(dwReadSize) then break;
            end;
            FILE_TYPE_LIST_B: begin
                // �w�b�_���擾
                API_ReadFile(hFile, @cListHeader, LIST_FILE_HEADER_B_LEN, @dwReadSize, NULLPOINTER);
                // �t�@�C���̃��[�h�Ɏ��s�����ꍇ�̓��[�v�𔲂���
                if not longbool(dwReadSize) then break;
                // �A�C�e�������擾
                API_ReadFile(hFile, @dwListNum, 2, @dwReadSize, NULLPOINTER);
                // �t�@�C���̃��[�h�Ɏ��s�����ꍇ�̓��[�v�𔲂���
                if not longbool(dwReadSize) then break;
                dwListNum := dwListNum and $FFFF;
                // �v���C���X�g�̃g�b�v�ʒu���擾
                API_ReadFile(hFile, @dwTopIndex, 2, @dwReadSize, NULLPOINTER);
                // �t�@�C���̃��[�h�Ɏ��s�����ꍇ�̓��[�v�𔲂���
                if not longbool(dwReadSize) then break;
                dwTopIndex := dwTopIndex and $FFFF;
                // �v���C���X�g�̑I���ʒu���擾
                API_ReadFile(hFile, @dwIndex, 2, @dwReadSize, NULLPOINTER);
                // �t�@�C���̃��[�h�Ɏ��s�����ꍇ�̓��[�v�𔲂���
                if not longbool(dwReadSize) then break;
                dwIndex := dwIndex and $FFFF;
            end;
        end;
        // �v���C���X�g�ɃA�C�e�����o�^����Ă��Ȃ��ꍇ�̓��[�v�𔲂���
        if not longbool(dwListNum) then break;
        // �A�C�e�����̍ő�l��ݒ�
        if dwListNum > Option.dwListMax then dwListNum := Option.dwListMax;
        // �ĕ`��֎~
        cwPlayList.SendMessage(WM_SETREDRAW, 0, NULL);
        // �o�b�t�@���m��
        GetMem(lpListFile, 1024);
        GetMem(lpTitle, 33);
        // �v���C���X�g���擾
        for I := 0 to dwListNum - 1 do begin
            dwSizeFile := 260;
            dwSizeTitle := 32;
            case dwType of
                FILE_TYPE_LIST_B: begin
                    // �f�[�^ �T�C�Y���擾
                    API_ReadFile(hFile, @dwSize, 2, @dwReadSize, NULLPOINTER);
                    // �t�@�C���̃��[�h�Ɏ��s�����ꍇ�̓��[�v�𔲂���
                    if not longbool(dwReadSize) then break;
                    dwSizeFile := dwSize and $3FF;
                    dwSizeTitle := (dwSize shr 10) and $3F;
                    if dwSizeTitle > 32 then dwSizeTitle := 32;
                end;
            end;
            // �t�@�C���̃��[�h�Ɏ��s�����ꍇ�̓��[�v�𔲂���
            if not longbool(dwReadSize) then break;
            // �t�@�C�� �p�X���擾
            API_ZeroMemory(lpListFile, 1024);
            API_ReadFile(hFile, lpListFile, dwSizeFile, @dwReadSize, NULLPOINTER);
            // �t�@�C���̃��[�h�Ɏ��s�����ꍇ�̓��[�v�𔲂���
            if not longbool(dwReadSize) then break;
            // �^�C�g�����擾
            API_ZeroMemory(lpTitle, 33);
            API_ReadFile(hFile, lpTitle, dwSizeTitle, @dwReadSize, NULLPOINTER);
            // �t�@�C���̃��[�h�Ɏ��s�����ꍇ�̓��[�v�𔲂���
            if not longbool(dwReadSize) then break;
            // �v���C���X�g�ɒǉ�
            cwPlayList.SendMessage(LB_ADDSTRING, NULL, longword(lpTitle));
            cwPlayList.SendMessage(LB_SETITEMDATA, I, NULL);
            ConvertPath();
            cwFileList.SendMessage(LB_ADDSTRING, NULL, longword(lpListFile));
        end;
        // �o�b�t�@�����
        FreeMem(lpListFile, 1024);
        FreeMem(lpTitle, 33);
        // �ĕ`�拖��
        cwPlayList.SendMessage(WM_SETREDRAW, 1, NULL);
        cwPlayList.Invalidate();
        // �t�@�C���̃��[�h�ɐ��������ꍇ�̓v���C���X�g�̃A�C�e����I��
        if longbool(dwReadSize) then begin
            if bShift then cwPlayList.SendMessage(LB_SETITEMDATA, dwIndex, 1);
            cwPlayList.SendMessage(LB_SETCURSEL, dwIndex, NULL);
            cwPlayList.SendMessage(LB_SETTOPINDEX, dwTopIndex, NULL);
        end;
    until true;
    // �t�@�C�����N���[�Y
    if hFile <> INVALID_HANDLE_VALUE then API_CloseHandle(hFile);
    // ���j���[���X�V
    UpdateMenu();
    // ����
    result := true;
end;

// ================================================================================
// ListNextPlay - �v���C���X�g�̎����J��
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
    // ���t�������擾
    case dwOrder of
        PLAY_ORDER_STOP: begin
            // ���t��~
            SPCStop(false);
            exit;
        end;
        PLAY_ORDER_REPEAT: begin
            // ���s�[�g
            SPCStop(true);
            exit;
        end;
    end;
    // �v���C���X�g�̃A�C�e�������擾
    dwCount := cwPlayList.SendMessage(LB_GETCOUNT, NULL, NULL);
    case dwCount of
        0: begin
            // ���t��~
            SPCStop(false);
            exit;
        end;
        1: begin
            // ���t�J�n
            ListPlay(dwOrder, 0, NULL);
            exit;
        end;
    end;
    // ���̋Ȃ�I��
    dwIndex := 0;
    J := 0;
    while true do begin
        I := 0;
        case dwOrder of
            PLAY_ORDER_FIRST: begin
                // �ŏ�����
                dwIndex := 0;
                break;
            end;
            PLAY_ORDER_LAST: begin
                // �Ōォ��
                dwIndex := dwCount - 1;
                break;
            end;
            PLAY_ORDER_RANDOM: begin
                // �����_��
                dwIndex := LIST_PLAY_INDEX_RANDOM;
                break;
            end;
            PLAY_ORDER_NEXT: begin
                // �Ō�ɉ��t���ꂽ�C���f�b�N�X���擾
                dwIndex := dwCount - 1;
                K := 0;
                for X := 0 to dwCount - 1 do begin
                    L := cwPlayList.SendMessage(LB_GETITEMDATA, X, NULL);
                    if L > K then begin
                        dwIndex := X;
                        K := L;
                    end;
                end;
                // ���̃C���f�b�N�X��I��
                if dwIndex = dwCount - 1 then dwIndex := 0 else Inc(dwIndex);
            end;
            PLAY_ORDER_PREVIOUS: begin
                // �Ō�ɉ��t���ꂽ�C���f�b�N�X���擾
                dwIndex := 0;
                K := 0;
                for X := 0 to dwCount - 1 do begin
                    L := cwPlayList.SendMessage(LB_GETITEMDATA, X, NULL);
                    if L > K then begin
                        dwIndex := X;
                        K := L;
                    end;
                end;
                // �O�̃C���f�b�N�X��I��
                if dwIndex = 0 then dwIndex := dwCount - 1 else Dec(dwIndex);
            end;
            PLAY_ORDER_SHUFFLE: begin
                // �e���|�����p���X�g���N���A
                cwTempList.SendMessage(LB_RESETCONTENT, NULL, NULL);
                // �����t�̃C���f�b�N�X�ƃt���O�̍ŏ��l�A�ő�l���L�^
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
                // ���t�t�@�C��������
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
                // �e���|�����p���X�g���N���A
                cwTempList.SendMessage(LB_RESETCONTENT, NULL, NULL);
            end;
        end;
        // ���������������ꍇ�̓��[�v�𔲂���
        if not longbool(I) then break;
        // �t���O��ݒ�
        for X := 0 to dwCount - 1 do cwPlayList.SendMessage(LB_SETITEMDATA, X, NULL);
    end;
    // ���t�J�n
    ListPlay(dwOrder, dwIndex, J or dwFlag);
end;

// ================================================================================
// ListPlay - �v���C���X�g�̓ǂݍ���
// ================================================================================
function CWINDOWMAIN.ListPlay(dwOrder: longword; dwIndex: longint; dwFlag: longword): longint;
var
    I: longint;
    dwTopIndex: longint;
    dwCount: longint;
    lpFile: pointer;
begin
    // ������
    result := -1;
    // �v���C���X�g�̃A�C�e�������擾
    dwCount := cwPlayList.SendMessage(LB_GETCOUNT, NULL, NULL);
    // �v���C���X�g���I������Ă��Ȃ��ꍇ�͏I��
    if not longbool(dwCount) then exit;
    // �o�b�t�@���m��
    GetMem(lpFile, 1024);
    // �t�@�C�����擾
    API_ZeroMemory(lpFile, 1024);
    dwTopIndex := cwPlayList.SendMessage(LB_GETCURSEL, NULL, NULL);
    case dwIndex of
        LIST_PLAY_INDEX_SELECTED: result := dwTopIndex;
        LIST_PLAY_INDEX_RANDOM: result := Trunc(Random(dwCount));
        else result := dwIndex;
    end;
    cwFileList.SendMessage(LB_GETTEXT, result, longword(lpFile));
    // �v���C���X�g�̃A�C�e����I������ꍇ
    if longbool(dwFlag and LIST_NEXT_PLAY_SELECT) then begin
        // �v���C���X�g�̃g�b�v��ݒ�
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
        // �v���C���X�g�̃A�C�e����I��
        cwPlayList.SendMessage(LB_SETCURSEL, result, NULL);
        // ���j���[���X�V
        UpdateMenu();
    end;
    // ���t�ς݃t���O��������
    dwFlag := dwFlag and $FFFF;
    if not longbool(dwFlag) then begin
        for I := 0 to dwCount - 1 do cwPlayList.SendMessage(LB_SETITEMDATA, I, NULL);
        Inc(dwFlag);
    end;
    // ���t�ς݃t���O��ݒ�
    cwPlayList.SendMessage(LB_SETITEMDATA, result, dwFlag);
    // SPC �����[�h
    if GetFileType(lpFile, true, false) = FILE_TYPE_SPC then SPCLoad(lpFile, true);
    // �o�b�t�@�����
    FreeMem(lpFile, 1024);
end;

// ================================================================================
// ListSave - �v���C���X�g�̕ۑ�
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
    // ������
    result := false;
    // �t�@�C�����I�[�v��
    hFile := INVALID_HANDLE_VALUE;
    if IsSafePath(lpFile) then hFile := API_CreateFile(lpFile, GENERIC_WRITE, FILE_SHARE_READ, NULLPOINTER, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL or FILE_FLAG_SEQUENTIAL_SCAN, NULL);
    // �t�@�C���̃I�[�v���Ɏ��s�����ꍇ�͏I��
    if hFile = INVALID_HANDLE_VALUE then exit;
    // �t�@�C���̃w�b�_��ۑ�
    lpTitle := pchar(LIST_FILE_HEADER_B);
    dwSize := LIST_FILE_HEADER_B_LEN;
    API_WriteFile(hFile, lpTitle, dwSize, @dwWriteSize, NULLPOINTER);
    // �v���C���X�g�̃A�C�e�������擾
    dwListNum := cwPlayList.SendMessage(LB_GETCOUNT, NULL, NULL);
    // �v���C���X�g�̃A�C�e�����ƌ��݂̏ꏊ��ۑ�
    dwSize := 0;
    API_WriteFile(hFile, @dwListNum, 2, @dwWriteSize, NULLPOINTER);
    if bShift then dwSize := cwPlayList.SendMessage(LB_GETTOPINDEX, NULL, NULL);
    API_WriteFile(hFile, @dwSize, 2, @dwWriteSize, NULLPOINTER);
    if bShift then dwSize := cwPlayList.SendMessage(LB_GETCURSEL, NULL, NULL);
    API_WriteFile(hFile, @dwSize, 2, @dwWriteSize, NULLPOINTER);
    // �v���C���X�g�ɃA�C�e�����o�^����Ă���ꍇ
    if longbool(dwListNum) then begin
        // �o�b�t�@���m��
        GetMem(lpBuffer, 1024);
        GetMem(lpListFile, 1024);
        GetMem(lpTitle, 33);
        // �v���C���X�g��ۑ�
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
        // �o�b�t�@�����
        FreeMem(lpBuffer, 1024);
        FreeMem(lpListFile, 1024);
        FreeMem(lpTitle, 33);
    end;
    // �t�@�C�����N���[�Y
    API_CloseHandle(hFile);
    // ����
    result := true;
end;

// ================================================================================
// ListUp - �v���C���X�g�̍��ڂ���ֈړ�
// ================================================================================
procedure CWINDOWMAIN.ListUp();
var
    lpFile: pointer;
    lpTitle: pointer;
    dwIndex: longint;
    dwCount: longint;
    dwItemData: longword;
begin
    // �v���C���X�g�̃A�C�e�������擾
    dwCount := cwPlayList.SendMessage(LB_GETCOUNT, NULL, NULL);
    // �v���C���X�g�ɃA�C�e�����o�^����Ă��Ȃ��ꍇ�͏I��
    if not longbool(dwCount) then exit;
    // �I������Ă���A�C�e�����擾
    dwIndex := cwPlayList.SendMessage(LB_GETCURSEL, NULL, NULL);
    // ��ԏ�̃A�C�e�����I������Ă���ꍇ�͏I��
    if dwIndex <= 0 then exit;
    // �o�b�t�@���m��
    GetMem(lpFile, 1024);
    GetMem(lpTitle, 33);
    // �t�@�C���ƃ^�C�g�����擾
    API_ZeroMemory(lpFile, 1024);
    cwFileList.SendMessage(LB_GETTEXT, dwIndex, longword(lpFile));
    API_ZeroMemory(lpTitle, 33);
    cwPlayList.SendMessage(LB_GETTEXT, dwIndex, longword(lpTitle));
    dwItemData := cwPlayList.SendMessage(LB_GETITEMDATA, dwIndex, NULL);
    // �J�[�\����ݒ�
    Dec(dwIndex);
    cwPlayList.SendMessage(LB_SETCURSEL, dwIndex, NULL);
    // �폜
    Inc(dwIndex);
    cwFileList.SendMessage(LB_DELETESTRING, dwIndex, NULL);
    cwPlayList.SendMessage(LB_DELETESTRING, dwIndex, NULL);
    // �}��
    Dec(dwIndex);
    cwFileList.SendMessage(LB_INSERTSTRING, dwIndex, longword(lpFile));
    cwPlayList.SendMessage(LB_INSERTSTRING, dwIndex, longword(lpTitle));
    cwPlayList.SendMessage(LB_SETITEMDATA, dwIndex, dwItemData);
    // �J�[�\����ݒ�
    cwPlayList.SendMessage(LB_SETCURSEL, dwIndex, NULL);
    // �o�b�t�@�����
    FreeMem(lpFile, 1024);
    FreeMem(lpTitle, 33);
    // ���j���[���X�V
    UpdateMenu();
end;

// ================================================================================
// LoadScript700 - Script700 �t�@�C���̓ǂݍ���
// ================================================================================
function CWINDOWMAIN.LoadScript700(lpFile: pointer; dwAddr: longword): longbool;
var
    hFile: longword;
    dwSize: longword;
    dwHigh: longword;
    dwReadSize: longword;
    lpBuffer: pointer;
begin
    // ������
    result := false;
    // �t�@�C�����I�[�v��
    hFile := INVALID_HANDLE_VALUE;
    if IsSafePath(lpFile) then hFile := API_CreateFile(lpFile, GENERIC_READ, FILE_SHARE_READ, NULLPOINTER, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL or FILE_FLAG_SEQUENTIAL_SCAN, NULL);
    // �t�@�C���̃I�[�v���Ɏ��s�����ꍇ�͏I��
    if hFile = INVALID_HANDLE_VALUE then exit;
    // �t�@�C�� �T�C�Y���擾
    dwSize := API_GetFileSize(hFile, @dwHigh);
    // �t�@�C�� �T�C�Y���͈͓��̏ꍇ
    if longbool(dwSize) and not longbool(dwSize and $FF000000) and not longbool(dwHigh) then begin
        // �o�b�t�@���m��
        GetMem(lpBuffer, dwSize + 1);
        // �o�b�t�@��������
        API_ZeroMemory(lpBuffer, dwSize + 1);
        // �o�b�t�@�Ɋi�[
        API_ReadFile(hFile, lpBuffer, dwSize, @dwReadSize, NULLPOINTER);
        // Script700 ���R���p�C��
        if dwAddr = SCRIPT700_TEXT then Status.Script700.dwProgSize := Apu.SetScript700(lpBuffer)
        else Status.Script700.dwProgSize := Apu.SetScript700Data(dwAddr, lpBuffer, dwSize);
        // �o�b�t�@�����
        FreeMem(lpBuffer, dwSize + 1);
        // ����
        result := true;
    end;
    // �t�@�C�����N���[�Y
    API_CloseHandle(hFile);
end;

// ================================================================================
// MoveWindowScreenSide - �E�B���h�E�ʒu�̒���
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
begin
    // OS �o�[�W�������擾
    bWin8 := (Status.OsVersionInfo.dwMajorVersion = 6) and (Status.OsVersionInfo.dwMinorVersion >= 2);
    bWin10 := Status.OsVersionInfo.dwMajorVersion >= 10;
    // �L�[�{�[�h�̏�Ԃ��擾 (Status.bShiftButton ���ł͏�Ԃ��擾�s��)
    API_GetKeyboardState(@KeyState);
    // Shift, Ctrl, Alt �L�[��������Ă���ꍇ�͏I��
    if bytebool((KeyState.k[VK_SHIFT] or KeyState.k[VK_CONTROL] or KeyState.k[VK_MENU]) and $80) then exit;
    // �E�B���h�E�̊Ԋu���擾
    dwBorder := 0;
    if not bWin10 then dwBorder := API_GetSystemMetrics(SM_AEROFRAME);
    if longbool(dwBorder) then dwBorder := API_GetSystemMetrics(SM_CXFRAME) - dwBorder;
    // ���݂̃E�B���h�E�ʒu�A�T�C�Y���擾
    API_GetWindowRect(cwWindowMain.hWnd, @WindowRect);
    // �X�N���[�� �n���h�����擾
    hMonitor := API_MonitorFromRect(@WindowRect, MONITOR_DEFAULTTOPRIMARY);
    // �X�N���[�� �T�C�Y���擾
    MonitorInfo.cdSize := SizeOf(TMONITORINFO);
    if API_GetMonitorInfo(hMonitor, @MonitorInfo) then ScreenRect := MonitorInfo.rcWork
    else API_SystemParametersInfo(SPI_GETWORKAREA, NULL, @ScreenRect, NULL);
    // �V�����E�B���h�E�ʒu���擾
    dwWidth := WindowRect.right - WindowRect.left;
    dwHeight := WindowRect.bottom - WindowRect.top;
    if bWin8 then Dec(dwBorder, 1);
    Inc(ScreenRect.top, dwBorder);
    if bWin8 then Inc(dwBorder, 1);
    if bWin10 then Dec(dwBorder, 2);
    Inc(ScreenRect.left, dwBorder);
    Dec(ScreenRect.right, dwBorder);
    Dec(ScreenRect.bottom, dwBorder);
    if Abs(WindowRect.left - ScreenRect.left) < WINDOW_MOVE_THRESHOLD then WindowRect.left := ScreenRect.left;
    if Abs(WindowRect.right - ScreenRect.right) < WINDOW_MOVE_THRESHOLD then WindowRect.left := ScreenRect.right - dwWidth;
    if Abs(WindowRect.top - ScreenRect.top) < WINDOW_MOVE_THRESHOLD then WindowRect.top := ScreenRect.top;
    if Abs(WindowRect.bottom - ScreenRect.bottom) < WINDOW_MOVE_THRESHOLD then WindowRect.top := ScreenRect.bottom - dwHeight;
    // �E�B���h�E���ړ�
    cwWindowMain.SetWindowPosition(WindowRect.left, WindowRect.top, dwWidth, dwHeight);
end;

// ================================================================================
// OpenFile - �t�@�C�����J��
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
    // �o�b�t�@���m��
    GetMem(lpFiles, 262144);
    // �t�@�C���I���_�C�A���O���J��
    sFilter := DIALOG_OPEN_FILTER[Status.dwLanguage];
    if Status.bOpen then sFilter := Concat(sFilter, DIALOG_SCRIPT700_FILTER[Status.dwLanguage]);
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
    // �t�@�C�����I�����ꂽ�ꍇ
    if bResult then begin
        // �C���f�b�N�X���L�^
        Status.dwOpenFilterIndex := OpenFileName.nFilterIndex;
        // �e���|�����p���X�g���N���A
        cwTempList.SendMessage(LB_RESETCONTENT, NULL, NULL);
        // �|�C���^�����Z�b�g
        lpPath := lpFiles;
        // �o�b�t�@���m��
        GetMem(lpFile, 1024);
        // �t�@�C�� �p�X�̃��X�g���쐬
        while bytebool(lpPath^) do begin
            // �t�@�C�� �p�X���擾
            dwSize := GetSize(lpPath, 1023);
            API_ZeroMemory(lpFile, 1024);
            API_MoveMemory(lpFile, lpPath, dwSize);
            cwTempList.SendMessage(LB_ADDSTRING, NULL, longword(lpPath));
            // ���̃t�@�C�� �p�X�̃|�C���^���擾
            Inc(lpPath, dwSize + 1);
        end;
        // �e���|�����p���X�g�̃A�C�e�������擾
        dwCount := cwTempList.SendMessage(LB_GETCOUNT, NULL, NULL);
        // �|�C���^�����Z�b�g
        lpPath := lpFile;
        dwSize := 0;
        bList := false;
        // �t�@�C���𒊏o
        if longbool(dwCount) then for I := 0 to dwCount - 1 do begin
            // �t�@�C�����擾
            API_ZeroMemory(lpPath, 1024 - dwSize);
            cwTempList.SendMessage(LB_GETTEXT, I, longword(lpPath));
            // �J�����g �p�X���L�^
            if dwCount = 1 then begin
                API_ZeroMemory(Status.lpOpenPath, 1024);
                API_MoveMemory(Status.lpOpenPath, lpFile, GetPosSeparator(string(lpFile)));
            end;
            // �t�@�C�����J��
            if longbool(I) or (dwCount = 1) then begin
                // �t�@�C���̎�ނ��擾
                dwType := GetFileType(lpFile, dwCount = 1, dwCount = 1);
                case dwType of
                    FILE_TYPE_SPC: if dwCount = 1 then SPCLoad(lpFile, true)
                        else cwSortList.SendMessage(LB_ADDSTRING, NULL, longword(lpFile));
                    FILE_TYPE_LIST_A, FILE_TYPE_LIST_B: if not bList then bList := ListLoad(lpFile, dwType, false);
                    FILE_TYPE_SCRIPT700: if dwCount = 1 then ReloadScript700(lpFile);
                end;
            end else begin
                // �t�@�C�� �p�X�̃|�C���^���擾
                dwSize := GetSize(lpPath, 1023);
                if longbool(dwSize) then begin
                    lpPath := pointer(longword(lpPath) + dwSize - 1);
                    if lpPath^ <> $5C then begin // \
                        Inc(dwSize);
                        Inc(lpPath);
                        lpPath^ := $5C; // \
                    end;
                    Inc(lpPath);
                    // �J�����g �p�X���L�^
                    API_ZeroMemory(Status.lpOpenPath, 1024);
                    API_MoveMemory(Status.lpOpenPath, lpFile, dwSize);
                end;
            end;
        end;
        // �o�b�t�@�����
        FreeMem(lpFile, 1024);
        // �e���|�����p���X�g���N���A
        cwTempList.SendMessage(LB_RESETCONTENT, NULL, NULL);
    end;
    // �o�b�t�@�����
    FreeMem(lpFiles, 262144);
    // SPC �t�@�C�����v���C���X�g�ɓo�^
    AppendList();
end;

// ================================================================================
// ReloadScript700 - Script700 �t�@�C���̍ēǂݍ���
// ================================================================================
function CWINDOWMAIN.ReloadScript700(lpFile: pointer): longbool;
var
    I: longint;
    J: longword;
    K: longword;
    lpBuffer: pointer;
begin
    // ������
    result := false;
    // SPC ���J����Ă��Ȃ��ꍇ�͏I��
    if not Status.bOpen then exit;
    // �o�b�t�@���m��
    GetMem(lpBuffer, 1024);
    // �J�����g �f�B���N�g�����o�b�N�A�b�v
    API_MoveMemory(lpBuffer, Status.lpSPCDir, 1024);
    // �t�H���_�̈ʒu���擾
    J := GetSize(lpFile, 1024);
    K := J;
    for I := 1 to K do begin
        if string(lpFile)[I] = NULLCHAR then break;
        if IsPathSeparator(string(lpFile), I) then J := I;
    end;
    // �J�����g �f�B���N�g�����R�s�[
    API_ZeroMemory(Status.lpSPCDir, 1024);
    API_MoveMemory(Status.lpSPCDir, lpFile, J);
    // �N���e�B�J�� �Z�N�V�������J�n
    API_EnterCriticalSection(@CriticalSectionStatic);
    // Script700 �����[�h
    LoadScript700(lpFile, SCRIPT700_TEXT);
    // �N���e�B�J�� �Z�N�V�������I��
    API_LeaveCriticalSection(@CriticalSectionStatic);
    // �J�����g �f�B���N�g����߂�
    API_MoveMemory(Status.lpSPCDir, lpBuffer, 1024);
    // �o�b�t�@�����
    FreeMem(lpBuffer, 1024);
    // �ŏ����牉�t
    if Status.bPlay then SPCStop(true)
    else SPCPlay(PLAY_TYPE_PLAY);
    // ����
    result := true;
end;

// ================================================================================
// ResetInfo - �C���W�P�[�^ ���Z�b�g (�r������)
// ================================================================================
procedure CWINDOWMAIN.ResetInfo(bRedraw: longbool);
var
    I: longint;
begin
    // �N���e�B�J�� �Z�N�V�������J�n
    API_EnterCriticalSection(@CriticalSectionStatic);
    // �C���W�P�[�^�֌W�̃�������������
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
    // �N���e�B�J�� �Z�N�V�������I��
    API_LeaveCriticalSection(@CriticalSectionStatic);
    // �C���W�P�[�^���ĕ`��
    if bRedraw then WaveProc(WAVE_PROC_GRAPH_ONLY);
end;

// ================================================================================
// ResizeWindow - �E�B���h�E ���T�C�Y
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
    // �E�B���h�E�̃T�C�Y�E�ʒu���擾
    API_GetWindowRect(cwWindowMain.hWnd, @WindowRect);
    API_GetClientRect(cwWindowMain.hWnd, @ClientRect);
    // ������
    dwLeft := WindowRect.left;
    dwTop := WindowRect.top;
    if Status.dwScale = 2 then begin
        dwWidth := WINDOW_WIDTH;
        dwHeight := WINDOW_HEIGHT;
    end else begin
        dwWidth := (WINDOW_WIDTH * Status.dwScale) shr 1;
        dwHeight := (WINDOW_HEIGHT * Status.dwScale) shr 1;
    end;
    // �V�����T�C�Y���擾
    dwWidth := (WindowRect.right - WindowRect.left) - (ClientRect.right - ClientRect.left) + dwWidth;
    dwHeight := (WindowRect.bottom - WindowRect.top) - (ClientRect.bottom - ClientRect.top) + dwHeight;
    // �V�����T�C�Y��ݒ�
    cwWindowMain.SetWindowPosition(dwLeft, dwTop, dwWidth, dwHeight);
    // �E�B���h�E���X�V
    UpdateWindow();
end;

// ================================================================================
// SaveFile - �t�@�C���̕ۑ�
// ================================================================================
procedure CWINDOWMAIN.SaveFile();
var
    sFilter: string;
    bShift: longbool;
    lpFile: pointer;
    bResult: longbool;
    OpenFileName: TOPENFILENAME;
    dwIndex: longint;
begin
    // �o�b�t�@���m��
    GetMem(lpFile, 1024);
    // �t�@�C���I���_�C�A���O���J��
    bShift := Status.bShiftButton;
    sFilter := DIALOG_SAVE_FILTER[Status.dwLanguage];
    if Status.bOpen then sFilter := Concat(sFilter, DIALOG_WAVE_FILTER[Status.dwLanguage]);
    if Status.bPlay then sFilter := Concat(sFilter, DIALOG_SNAP_FILTER[Status.dwLanguage]);
    API_ZeroMemory(lpFile, 1024);
    API_ZeroMemory(@OpenFileName, SizeOf(TOPENFILENAME));
    if bytebool(Spc.Hdr.TagFormat) and bytebool(Spc.Hdr.Title[0]) then begin
        API_MoveMemory(lpFile, @Spc.Hdr.Title[0], 32);
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
    // �t�@�C�����I�����ꂽ�ꍇ
    if bResult then begin
        // �C���f�b�N�X���L�^
        dwIndex := OpenFileName.nFilterIndex;
        Status.dwSaveFilterIndex := dwIndex;
        // �J�����g �p�X���L�^
        API_ZeroMemory(Status.lpSavePath, 1024);
        API_MoveMemory(Status.lpSavePath, lpFile, GetPosSeparator(string(lpFile)));
        // �t�@�C����ۑ�
        case dwIndex of
            1: ListSave(lpFile, bShift);
            2: WaveSave(lpFile, bShift, false);
            3: SPCSave(lpFile, bShift);
        end;
    end;
    // �o�b�t�@�����
    FreeMem(lpFile, 1024);
end;

// ================================================================================
// SaveSeekCache - �V�[�N �L���b�V���ۑ� (�r���K�{)
// ================================================================================
procedure CWINDOWMAIN.SaveSeekCache(dwIndex: longword);
var
    SPCCache: ^TSPCCACHE;
    SPCBuf: ^TSPC;
    SPCReg: ^TSPCREG;
begin
    // �L���b�V�����g�p���Ȃ��ꍇ�͏I��
    if not longbool(Option.dwSeekNum) then exit;
    // ���݂̏�Ԃ��L���b�V��
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
    // ���̃L���b�V�����Ԃ��擾
    if dwIndex = Option.dwSeekNum - 1 then Status.dwNextCache := 0
    else Status.dwNextCache := Status.SPCCache[dwIndex + 1].Spc.Hdr.dwFadeLen;
end;

// ================================================================================
// SetChangeFunction - �@�\�ؑ�
// ================================================================================
procedure CWINDOWMAIN.SetChangeFunction(bFlag: longbool);
var
    KeyState: TKEYSTATE;
    bShiftButton: longbool;
begin
    // �L�[�{�[�h�̏�Ԃ��擾
    API_GetKeyboardState(@KeyState);
    // �}�E�X�̉E�{�^����������Ă���ꍇ�� Shift �L�[������
    bShiftButton := bFlag and bytebool((KeyState.k[VK_SHIFT] or KeyState.k[VK_RBUTTON]) and $80);
    // �t���O���ύX����Ă��Ȃ��ꍇ�͏I��
    if Status.bShiftButton = bShiftButton then exit;
    // �V�t�g�t���O��ؑ�
    Status.bShiftButton := bShiftButton;
    // ���j���[���X�V
    UpdateMenu();
end;

// ================================================================================
// SetChangeInfo - �C���W�P�[�^�ؑ�
// ================================================================================
procedure CWINDOWMAIN.SetChangeInfo(bForce: longbool; dwValue: longint);
begin
    // �C���W�P�[�^�̎�ނ�ؑ�
    if bForce then begin
        // �O��Ɠ����ꍇ�͏I��
        if Option.dwInfo = longword(dwValue) then exit;
        // �C���W�P�[�^�̎�ނ�ݒ�
        Option.dwInfo := dwValue;
        // ���j���[���X�V
        UpdateMenu();
        // SPC ���J����Ă��Ȃ��ꍇ�͏I��
        if not Status.bOpen then exit;
    end else begin
        // SPC ���J����Ă��Ȃ��ꍇ�͏I��
        if not Status.bOpen then exit;
        // �C���W�P�[�^�̎�ނ�ݒ�
        Option.dwInfo := longword(longint(Option.dwInfo) + dwValue + MENU_SETUP_INFO_SIZE) mod MENU_SETUP_INFO_SIZE;
        // ���j���[���X�V
        UpdateMenu();
    end;
    // �����X�V
    UpdateInfo(true);
end;

// ================================================================================
// SetFunction - �ݒ�ؑ�
// ================================================================================
procedure CWINDOWMAIN.SetFunction(dwFlag: longint; dwType: longword);
var
    I: longword;
    J: longword;
    T64Count: longword;

function UpdateFunction(dwNow: longword; dwSize: longword; dwValus: array of longword; dwIdxs: array of longword; dwDef1: longword; dwDef2: longint): longword;
var
    dwI: longint;
begin
    // ���݂̐ݒ�l���擾
    J := $FF;
    for dwI := 0 to dwSize - 1 do if dwNow = dwValus[dwI] then J := dwI;
    // �V�����ݒ�l���擾
    I := (not dwFlag shr 1) and (dwSize - 1);
    if J = I then begin
        // �����l�̏ꍇ
        result := $FFFFFFFF;
    end else if J = $FF then begin
        // ����`�̐ݒ�l�̏ꍇ
        result := dwDef1;
        Status.dwInfo := dwDef2;
    end else begin
        // ���̐ݒ�l��ݒ�
        Inc(J, dwFlag);
        result := dwValus[J];
        Status.dwInfo := STR_MENU_SETUP_PER_INTEGER[dwIdxs[J]];
        // �ݒ肪�����̏ꍇ�̓I�v�V�����̐ݒ�����b�N
        if not longbool(dwType and FUNCTION_TYPE_NO_TIMER) and (J = dwSize div 2) then begin
            Status.bOptionLock := true;
            API_SetTimer(cwWindowMain.hWnd, TIMER_ID_OPTION_LOCK, TIMER_INTERVAL_OPTION_LOCK, NULLPOINTER);
        end;
    end;
end;

begin
    // �I�v�V�����̐ݒ肪���b�N����Ă���ꍇ�͏I��
    if Status.bOptionLock then exit;
    // �@�\�̎�ނ𔻕�
    case dwType and $FFFF of
        FUNCTION_TYPE_SEPARATE: begin // ���E�g�U�x
            // ���E�g�U�x��ݒ�
            I := UpdateFunction(Option.dwSeparate, MENU_SETUP_SEPARATE_SIZE, MENU_SETUP_SEPARATE_VALUE, STR_MENU_SETUP_SEPARATE_PER_INDEX, SEPARATE_050, 50);
            if I = $FFFFFFFF then exit;
            Option.dwSeparate := I;
            // �^�C�g�����X�V
            UpdateTitle(TITLE_INFO_SEPARATE);
            // �ݒ�����Z�b�g
            SPCReset(false);
        end;
        FUNCTION_TYPE_FEEDBACK: begin // �t�B�[�h�o�b�N���]�x
            // �t�B�[�h�o�b�N���]�x��ݒ�
            I := UpdateFunction(Option.dwFeedback, MENU_SETUP_FEEDBACK_SIZE, MENU_SETUP_FEEDBACK_VALUE, STR_MENU_SETUP_FEEDBACK_PER_INDEX, FEEDBACK_000, 0);
            if I = $FFFFFFFF then exit;
            Option.dwFeedback := I;
            // �^�C�g�����X�V
            UpdateTitle(TITLE_INFO_FEEDBACK);
            // �ݒ�����Z�b�g
            SPCReset(false);
        end;
        FUNCTION_TYPE_SPEED: begin // ���t���x
            // ���t���x��ݒ�
            I := UpdateFunction(Option.dwSpeedBas, MENU_SETUP_SPEED_SIZE, MENU_SETUP_SPEED_VALUE, STR_MENU_SETUP_SPEED_PER_INDEX, SPEED_100, 100);
            if I = $FFFFFFFF then exit;
            Option.dwSpeedBas := I;
            // �^�C�g�����X�V
            UpdateTitle(TITLE_INFO_SPEED);
            // �ݒ�����Z�b�g
            SPCReset(false);
        end;
        FUNCTION_TYPE_AMP: begin // ����
            // ���ʂ�ݒ�
            I := UpdateFunction(Option.dwAmp, MENU_SETUP_AMP_SIZE, MENU_SETUP_AMP_VALUE, STR_MENU_SETUP_AMP_PER_INDEX, AMP_100, 100);
            if I = $FFFFFFFF then exit;
            Option.dwAmp := I;
            // �^�C�g�����X�V
            UpdateTitle(TITLE_INFO_AMP);
            // �ݒ�����Z�b�g
            SPCReset(false);
        end;
        FUNCTION_TYPE_SEEK: begin // �V�[�N
            // SPC ���J����Ă��Ȃ��A���t��~���A�܂��͈ꎞ��~���̏ꍇ�͏I��
            if not Status.bOpen or not Status.bPlay or Status.bPause then exit;
            // �V�[�N�ʒu���擾
            J := Option.dwSeekTime shl 6;
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
            // �^�C�g�����X�V
            UpdateTitle(TITLE_INFO_SEEK);
            // �X���b�h�ɃV�[�N��ʒm
            API_PostThreadMessage(Status.dwThreadID, WM_APP_MESSAGE, WM_APP_SPC_SEEK + (longword(not Status.bCtrlButton) and $1), I);
        end;
    end;
end;

// ================================================================================
// SetGraphic - �O���t�B�b�N ���\�[�X�ݒ�
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
    // �w�i�F�̖��邳���擾
    Rect.left := 0;
    Rect.right := 2;
    Rect.top := 0;
    Rect.bottom := 1;
    API_FillRect(Status.hDCVolumeBuffer, @Rect, ORG_COLOR_BTNFACE);
    Color.dwColor := API_GetPixel(Status.hDCVolumeBuffer, 0, 0);
    J := 299 * Color.r + 587 * Color.g + 114 * Color.b;
    // �����F�̖��邳���擾
    Inc(Rect.left);
    API_FillRect(Status.hDCVolumeBuffer, @Rect, ORG_COLOR_WINDOWTEXT);
    Color.dwColor := API_GetPixel(Status.hDCVolumeBuffer, 1, 0);
    K := 299 * Color.r + 587 * Color.g + 114 * Color.b;
    if longbool(Option.dwVolumeColor) then L := (Option.dwVolumeColor - 1) * COLOR_BAR_NUM
    else if K >= COLOR_BRIGHT_FORE then L := COLOR_BAR_NUM shl 1
    else if J >= COLOR_BRIGHT_BACK then L := COLOR_BAR_NUM
    else L := 0;
    // �C���W�P�[�^�p�̃O���t�B�b�N��`��
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
    // �����\���p�̕`��̈�����F�ŕ`��
    API_SetPixel(Status.hDCStringBuffer, 0, 0, $FF00FF);
    API_StretchBlt(Status.hDCStringBuffer, 0, 0, BITMAP_NUM_X6, BITMAP_NUM_HEIGHT, Status.hDCStringBuffer, 0, 0, 1, 1, SRCCOPY);
    // �r�b�g�}�b�v ���\�[�X�p�̃f�o�C�X �R���e�L�X�g���쐬
    hDCBitmapBuffer := API_CreateCompatibleDC(Status.hDCStatic);
    hBitmap := API_SelectObject(hDCBitmapBuffer, API_LoadBitmap(Status.hInstance, pchar(BITMAP_NAME)));
    // �r�b�g�}�b�v ���\�[�X���當���\���p�̃f�o�C�X �R���e�L�X�g�։摜��]�� (AND ����)
    API_BitBlt(Status.hDCStringBuffer, 0, 0, BITMAP_NUM_X6, BITMAP_NUM_HEIGHT, hDCBitmapBuffer, 0, 0, SRCAND);
    // �r�b�g�}�b�v ���\�[�X�p�̃f�o�C�X �R���e�L�X�g����蒼��
    API_DeleteObject(API_SelectObject(hDCBitmapBuffer, hBitmap));
    hBitmap := API_SelectObject(hDCBitmapBuffer, API_CreateCompatibleBitmap(Status.hDCStatic, BITMAP_NUM_X6, BITMAP_NUM_HEIGHT));
    // �r�b�g�}�b�v ���\�[�X�p�̕`��̈�𕶎��F�ŕ`��
    K := 0;
    for I := 0 to BITMAP_NUM - 1 do begin
        J := BITMAP_STRING_COLOR[I];
        if longbool(J shr 16) then begin
            // �C���W�P�[�^�̐F�ŕ`��
            J := J and $FFFF;
            for L := 0 to 8 do API_BitBlt(hDCBitmapBuffer, K, L, BITMAP_NUM_WIDTH, 1, Status.hDCVolumeBuffer, J, Abs(4 - L) * 5 + 20, SRCCOPY);
        end else begin
            // �V�X�e�� �J���[�ŕ`��
            Rect.left := K;
            Rect.right := K + BITMAP_NUM_WIDTH;
            Rect.top := 0;
            Rect.bottom := BITMAP_NUM_HEIGHT;
            API_FillRect(hDCBitmapBuffer, @Rect, J);
        end;
        Inc(K, BITMAP_NUM_WIDTH);
    end;
    // �����\���p����r�b�g�}�b�v ���\�[�X�p�̃f�o�C�X �R���e�L�X�g�։摜��]�� (���F�Ń}�X�N)
    API_TransparentBlt(hDCBitmapBuffer, 0, 0, BITMAP_NUM_X6, BITMAP_NUM_HEIGHT, Status.hDCStringBuffer, 0, 0, BITMAP_NUM_X6, BITMAP_NUM_HEIGHT, $000000);
    // �����\���p�̕`��̈���{�^���̐F�ŕ`��
    Rect.left := 0;
    Rect.right := BITMAP_NUM_X6P6;
    Rect.top := 0;
    Rect.bottom := 9;
    API_FillRect(Status.hDCStringBuffer, @Rect, ORG_COLOR_BTNFACE);
    // �r�b�g�}�b�v ���\�[�X�p���當���\���p�̃f�o�C�X �R���e�L�X�g�։摜��]�� (���F�Ń}�X�N)
    API_TransparentBlt(Status.hDCStringBuffer, 0, 0, BITMAP_NUM_X6, BITMAP_NUM_HEIGHT, hDCBitmapBuffer, 0, 0, BITMAP_NUM_X6, BITMAP_NUM_HEIGHT, $FF00FF);
    // �r�b�g�}�b�v ���\�[�X�p�̃f�o�C�X �R���e�L�X�g�����
    API_DeleteObject(API_SelectObject(hDCBitmapBuffer, hBitmap));
    API_DeleteDC(hDCBitmapBuffer);
    // GDI �`����t���b�V��
    API_GdiFlush();
    // ���j���[��`��
    API_DrawMenuBar(cwWindowMain.hWnd);
end;

// ================================================================================
// SetTabFocus - �t�H�[�J�X�ړ�
// ================================================================================
procedure CWINDOWMAIN.SetTabFocus(hWnd: longword; bNext: longbool);
var
    hWndApp: longword;
begin
    hWndApp := cwWindowMain.hWnd;
    if API_GetForegroundWindow() = hWndApp then API_SetFocus(API_GetNextDlgTabItem(hWndApp, hWnd, not bNext));
end;

// ================================================================================
// ShowErrMsg - �G���[ ���b�Z�[�W�\��
// ================================================================================
procedure CWINDOWMAIN.ShowErrMsg(dwCode: longword);
var
    sMsg: string;
begin
    // �G���[�̎�ނ𔻕�
    case dwCode of
        100..109: sMsg := ERROR_SNESAPU[Status.dwLanguage];
        110..129: sMsg := ERROR_CHECKSUM[Status.dwLanguage];
        200..249: sMsg := ERROR_FILE_READ[Status.dwLanguage];
        250..299: sMsg := ERROR_FILE_WRITE[Status.dwLanguage];
        300..599: sMsg := ERROR_DEVICE[Status.dwLanguage];
        else sMsg := '';
    end;
    // ���b�Z�[�W��\��
    sMsg := Concat(sMsg, ERROR_CODE_1[Status.dwLanguage], IntToStr(dwCode), ERROR_CODE_2[Status.dwLanguage]);
    cwWindowMain.MessageBox(pchar(sMsg), pchar(DEFAULT_TITLE), MB_ICONEXCLAMATION or MB_OK);
end;

// ================================================================================
// SPCLoad - SPC �t�@�C���̓ǂݍ���
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
    HdrBin: TSPCHDRBIN;
    StrData: TSTRDATA;
    sData: string;

function CheckPath(dwEnd: longword; sName: string): longbool;
begin
    sData := Concat(Copy(string(lpFile), 1, dwEnd), sName);
    result := longbool(IsSafePath(pchar(sData)) and Exists(pchar(sData), $FFFFFFFF));
end;

begin
    // ������
    result := false;
    // �t�@�C�����I�[�v��
    hFile := INVALID_HANDLE_VALUE;
    if IsSafePath(lpFile) then hFile := API_CreateFile(lpFile, GENERIC_READ, FILE_SHARE_READ, NULLPOINTER, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL or FILE_FLAG_SEQUENTIAL_SCAN, NULL);
    // �t�@�C���̃I�[�v���Ɏ��s�����ꍇ�͏I��
    if hFile = INVALID_HANDLE_VALUE then exit;
    // ���t���̏ꍇ
    if Status.bPlay then begin
        // Script700 �������I��
        Status.Script700.Data.dwStackFlag := Status.Script700.Data.dwStackFlag or $80000000;
        Status.bWaveWrite := false;
        // ���t���ꎞ��~
        WavePause();
    end;
    // �t���O��ݒ�
    Status.bOpen := true;
    Status.bSPCRefresh := true;
    // �t�@�C�������[�h
    API_ReadFile(hFile, @Spc, $10200, @dwReadSize, NULLPOINTER);
    // �o�b�t�@���R�s�[
    API_MoveMemory(Status.lpSPCFile, lpFile, 1024);
    API_MoveMemory(@HdrBin, @Spc.Hdr, 256);
    // ID666 �t�H�[�}�b�g�`�����擾
    GetID666Format(Spc.Hdr);
    // �^�C�g�������݂��Ȃ��ꍇ
    if not bytebool(Spc.Hdr.TagFormat) or not bytebool(Spc.Hdr.Title[0]) then begin
        // �^�C�g���Ƀt�@�C������ݒ�
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
    // ID666 �o�C�i�� �t�H�[�}�b�g�̏ꍇ
    if Spc.Hdr.TagFormat = ID666_BINARY then begin
        // ���t��ϊ�
        if (HdrBin.DateYear > 0) and (HdrBin.DateYear < 10000) and (HdrBin.DateMonth > 0) and (HdrBin.DateMonth < 13) and (HdrBin.DateDay > 0) and (HdrBin.DateDay < 32) then begin
            IntToStr(StrData, longword(HdrBin.DateYear), 4);
            API_MoveMemory(@Spc.Hdr.Date[0], @StrData, 4);
            Spc.Hdr.Date[4] := '/';
            IntToStr(StrData, longword(HdrBin.DateMonth), 2);
            API_MoveMemory(@Spc.Hdr.Date[5], @StrData, 2);
            Spc.Hdr.Date[7] := '/';
            IntToStr(StrData, longword(HdrBin.DateDay), 2);
            API_MoveMemory(@Spc.Hdr.Date[8], @StrData, 2);
        end else Spc.Hdr.Date[0] := NULLCHAR;
        // ���t���Ԃ�ϊ�
        I := HdrBin.SongLen;
        if I > 999 then I := 999;
        if longbool(I) then begin
            IntToStr(StrData, longword(I), 3);
            API_MoveMemory(@Spc.Hdr.SongLen[0], @StrData, 3);
        end;
        // �t�F�[�h�A�E�g���Ԃ�ϊ�
        I := HdrBin.FadeLen and $FFFFFF;
        if I > 99999 then I := 99999;
        if longbool(I) then begin
            IntToStr(StrData, longword(I), 5);
            API_MoveMemory(@Spc.Hdr.FadeLen[0], @StrData, 5);
        end;
        // ��ȎҁA�`�����l�������A�o�͌��G�~�����[�^���R�s�[
        API_MoveMemory(@Spc.Hdr.Artist[0], @HdrBin.Artist[0], 34);
    end;
    // �e�L�X�g�̐���R�[�h���X�y�[�X�ɕϊ�
    pV := @Spc.Hdr.Title;
    for I := 0 to 162 do begin
        if ((pV^ > $0) and (pV^ < $20)) or (pV^ = $7F) then pV^ := $20;
        Inc(pV);
    end;
    // ���t���ԁA�t�F�[�h�A�E�g���Ԃ��擾
    Spc.Hdr.dwSongLen := StrToInt(string(Spc.Hdr.SongLen), longword(0));
    Spc.Hdr.dwFadeLen := StrToInt(string(Spc.Hdr.FadeLen), longword(0));
    // �t�H���_�̈ʒu���擾
    J := GetSize(lpFile, 1024);
    K := J;
    L := J;
    for I := 1 to L do begin
        if string(lpFile)[I] = NULLCHAR then break;
        if IsPathSeparator(string(lpFile), I) then J := I;
        if IsSingleByte(string(lpFile), I, '.') then K := I;
    end;
    // �J�����g �f�B���N�g�����R�s�[
    API_ZeroMemory(Status.lpSPCDir, 1024);
    API_MoveMemory(Status.lpSPCDir, lpFile, J);
    // �t�@�C�������R�s�[
    API_ZeroMemory(Status.lpSPCName, 1024);
    I := L - J;
    if I > 0 then API_MoveMemory(Status.lpSPCName, pointer(longword(lpFile) + J), I);
{$IFNDEF TRY700A}{$IFNDEF TRY700W}
    // �t�@�C�����擾
    bScript700Exist := CheckPath(K, SCRIPT700_FILETYPE)
                    or CheckPath(K, SCRIPT7SE_FILETYPE)
                    or CheckPath(K, SCRIPT700TXT_FILETYPE)
                    or CheckPath(K, SCRIPT7SETXT_FILETYPE)
                    or CheckPath(J, SCRIPT700_FILENAME)
                    or CheckPath(J, SCRIPT7SE_FILENAME)
                    or CheckPath(J, SCRIPT700TXT_FILENAME)
                    or CheckPath(J, SCRIPT7SETXT_FILENAME);
    // Script700 �����[�h
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
    // �����X�V
    UpdateInfo(false);
    // �^�C�g�����X�V
    UpdateTitle(NULL);
    // ���t���J�n
    if Status.bPlay then SPCStop(bAutoPlay)
    else if bAutoPlay then SPCPlay(PLAY_TYPE_PLAY);
    // �t�@�C�����N���[�Y
    API_CloseHandle(hFile);
    // ����
    result := true;
end;

// ================================================================================
// SPCOption - SPC ���t�ݒ� (�r���K�{)
// ================================================================================
procedure CWINDOWMAIN.SPCOption();
var
    I: longint;
    V: byte;
begin
    // �g���ݒ��ݒ� (dwBit �͕����ɂȂ�ꍇ�����邽�� shl �͎g��Ȃ�)
    Apu.SetAPUOption(1, Option.dwChannel, Option.dwBit * 8, Option.dwRate, Option.dwInter, Option.dwOption or OPTION_FLOATOUT);
    // ���t���x��ݒ�
    Apu.SetAPUSpeed(Option.dwSpeedBas + Round(Option.dwSpeedBas / SPEED_100 * Option.dwSpeedTun));
    // �s�b�`��ݒ�
    if Option.bPitchAsync then Apu.SetDSPPitch(Round(Option.dwSpeedBas / SPEED_100 * Option.dwPitch))
    else Apu.SetDSPPitch(Option.dwPitch);
    // ���E�g�U�x��ݒ�
    Apu.SetDSPStereo(Option.dwSeparate);
    // �t�B�[�h�o�b�N���]�x��ݒ�
    Apu.SetDSPFeedback(32768 - Option.dwFeedback);
    // ���ʂ�ݒ�
    Apu.SetDSPAmp(Option.dwAmp);
    // �`�����l�� �}�X�N��ݒ�
    for I := 0 to 7 do begin
        V := Apu.Voices.Voice[I].MixFlag and $FC;
        if bytebool(Option.dwMute and (1 shl I)) then V := V or $1;
        if bytebool(Option.dwNoise and (1 shl I)) then V := V or $2;
        Apu.Voices.Voice[I].MixFlag := V;
    end;
end;

// ================================================================================
// SPCPlay - SPC ���t�J�n�E�ꎞ��~
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
begin
    // ���t�̎�ނ𔻕�
    if not Status.bEmuDebug then case dwType of
        PLAY_TYPE_AUTO, PLAY_TYPE_PLAY: if not Status.bOpen then begin // ����
            ListPlay(Option.dwPlayOrder, LIST_PLAY_INDEX_SELECTED, NULL);
            exit;
        end;
        PLAY_TYPE_LIST: begin // �v���C���X�g�̑I���ς݃A�C�e��
            ListPlay(Option.dwPlayOrder, LIST_PLAY_INDEX_SELECTED, NULL);
            exit;
        end;
        PLAY_TYPE_RANDOM: begin // �v���C���X�g���烉���_���I��
            ListNextPlay(PLAY_ORDER_RANDOM, LIST_NEXT_PLAY_SELECT);
            exit;
        end;
    end else begin
        // �o�b�t�@���N���A
        API_ZeroMemory(@Spc.Hdr, SizeOf(TSPCHDR));
        // �t���O��ݒ�
        Status.bOpen := true;
        // �����X�V
        UpdateInfo(false);
        // �^�C�g�����X�V
        UpdateTitle(NULL);
    end;
    // SPC ���J����Ă��Ȃ��ꍇ�͏I��
    if not Status.bOpen then exit;
    // �ꎞ��~���̏ꍇ
    if Status.bPause then begin
        // �ꎞ��~�w��̏ꍇ�͏I��
        if dwType = PLAY_TYPE_PAUSE then exit;
{$IFNDEF TRANSMITSPC}
        // �X���b�h�ɉ��t�ĊJ��ʒm
        API_PostThreadMessage(Status.dwThreadID, WM_APP_MESSAGE, WM_APP_SPC_RESUME, NULL);
{$ENDIF}
    // ���t���̏ꍇ
    end else if Status.bPlay then begin
        // ���t�J�n�w��̏ꍇ�͏I��
        if dwType = PLAY_TYPE_PLAY then exit;
{$IFNDEF TRANSMITSPC}
        // �X���b�h�Ɉꎞ��~��ʒm
        API_PostThreadMessage(Status.dwThreadID, WM_APP_MESSAGE, WM_APP_SPC_PAUSE, NULL);
{$ENDIF}
    // ���t��~���̏ꍇ
    end else begin
        // �ꎞ��~�w��̏ꍇ�͏I��
        if dwType = PLAY_TYPE_PAUSE then exit;
        // �N���e�B�J�� �Z�N�V�������J�n
        API_EnterCriticalSection(@CriticalSectionThread);
{$IFDEF TIMERTRICK}
        // TimerTrick ��ݒ�
        Apu.SetTimerTrick(0, 16661);
{$ENDIF}
        // SPC �� APU �ɓ]��
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
        // SPC ���t�ݒ�
        SPCOption();
        // ���t���ԁA�t�F�[�h�A�E�g���Ԃ�ݒ�
        SPCTime(true, false, true);
        // �N���e�B�J�� �Z�N�V�������I��
        API_LeaveCriticalSection(@CriticalSectionThread);
        // �V���� SPC ���ǂݍ��܂ꂽ�ꍇ
        if Status.bEmuDebug or Status.bSPCRefresh then begin
            // �V�[�N �L���b�V����������
            if longbool(Option.dwSeekNum) then begin
                J := 0;
                K := Option.dwSeekInt shl 6;
                Status.dwNextCache := K;
                for I := 0 to Option.dwSeekNum - 1 do begin
                    Inc(J, K);
                    SPCHdr := @Status.SPCCache[I].Spc.Hdr;
                    SPCHdr.dwSongLen := $FFFFFFFF;
                    SPCHdr.dwFadeLen := J;
                end;
            end else begin
                Status.dwNextCache := 0;
            end;
            // ���s�[�g�J�n�ʒu�ƃ��s�[�g�I���ʒu��ݒ�
            Status.dwStartTime := 0;
            Status.dwLimitTime := Status.dwDefaultTimeout;
        end;
        // �f�o�C�X���I�[�v��
        Status.dwWaveMessage := WAVE_MESSAGE_MAX_COUNT;
{$IFNDEF TRANSMITSPC}
        Status.bPlay := Status.bSPCRestart;
        if Status.bSPCRestart then I := 0 else I := WaveOpen();
{$ELSE}
        Status.bPlay := true;
        Status.bPause := false;
{$ENDIF}
        // �t���O��ݒ�
        Status.bSPCRestart := false;
        Status.bSPCRefresh := false;
        Status.bWaveWrite := true;
        // ���j���[���X�V
        UpdateMenu();
        // �C���W�P�[�^�����Z�b�g
        ResetInfo(true);
{$IFNDEF TRANSMITSPC}
        // �G���[������ꍇ
        if longbool(I) then begin
            // ���b�Z�[�W��\��
            ShowErrMsg(300 + (I and $FF));
        end else if Status.bPlay then begin
            // �X���b�h�ɉ��t�J�n��ʒm
            API_PostThreadMessage(Status.dwThreadID, WM_APP_MESSAGE, WM_APP_SPC_PLAY, NULL);
        end;
{$ENDIF}
    end;
end;

// ================================================================================
// SPCReset - SPC ���Z�b�g
// ================================================================================
procedure CWINDOWMAIN.SPCReset(bWave: longbool);
begin
    // �f�o�C�X�̍ăI�[�v�����s�v�ȏꍇ
    if not bWave and Status.bPlay then begin
        // �X���b�h�ɐݒ�ύX��ʒm
        API_PostThreadMessage(Status.dwThreadID, WM_APP_MESSAGE, WM_APP_SPC_RESET, NULL);
    end;
    // �f�o�C�X�̍ăI�[�v�����K�v�ȏꍇ
    if bWave and not Status.bPlay then begin
        // �f�o�C�X�����
        WaveQuit();
        // �f�o�C�X��������
        WaveInit();
    end;
    // ���j���[���X�V
    UpdateMenu();
end;

// ================================================================================
// SPCSave - SPC �ۑ�
// ================================================================================
function CWINDOWMAIN.SPCSave(lpFile: pointer; bShift: longbool): longbool;
var
    SPCBuf: TSPC;
    SPCReg: ^TSPCREG;
    hFile: longword;
    dwWriteSize: longword;
begin
    // ������
    result := false;
    // SPC ���J����Ă��Ȃ��A�܂��͉��t��~���̏ꍇ�͏I��
    if not Status.bOpen or not Status.bPlay then exit;
    // �N���e�B�J�� �Z�N�V�������J�n
    API_EnterCriticalSection(@CriticalSectionThread);
    // SPC ��ۑ�
    SPCReg := @SPCBuf.Hdr.Reg;
    API_MoveMemory(@SPCBuf, @Spc, SizeOf(TSPCHDR));
    Apu.GetSPCRegs(@SPCReg.pc, @SPCReg.a, @SPCReg.y, @SPCReg.x, @SPCReg.psw, @SPCReg.sp);
    API_MoveMemory(@SPCBuf.Ram, Apu.Ram, SizeOf(TRAM));
    API_MoveMemory(@SPCBuf.Dsp, Apu.DspReg, SizeOf(TDSPREG));
    API_MoveMemory(@SPCBuf.XRam, Apu.XRam, SizeOf(TXRAM));
    // �N���e�B�J�� �Z�N�V�������I��
    API_LeaveCriticalSection(@CriticalSectionThread);
    // �t�@�C�����I�[�v��
    hFile := INVALID_HANDLE_VALUE;
    if IsSafePath(lpFile) then begin
        API_MakeSureDirectoryPathExists(lpFile);
        hFile := API_CreateFile(lpFile, GENERIC_WRITE, FILE_SHARE_READ, NULLPOINTER, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL or FILE_FLAG_SEQUENTIAL_SCAN, NULL);
    end;
    // �t�@�C���̃I�[�v���Ɏ��s�����ꍇ�̓��b�Z�[�W��\�����ďI��
    if hFile = INVALID_HANDLE_VALUE then begin
        ShowErrMsg(251);
        exit;
    end;
    // SPC �o�b�t�@��ۑ�
    API_WriteFile(hFile, @SPCBuf, SizeOf(TSPC), @dwWriteSize, NULLPOINTER);
    // �t�@�C�����N���[�Y
    API_CloseHandle(hFile);
    // ����
    result := true;
end;

// ================================================================================
// SPCSeek - SPC �V�[�N (�r���K�{)
// ================================================================================
procedure CWINDOWMAIN.SPCSeek(dwTime: longword; bCache: longbool);
var
    I: longint;
    J: longint;
    T64Count: longword;
    T64Cache: longword;

procedure CacheSeek();
var
    SPCCache: ^TSPCCACHE;
begin
    if not longbool(T64Cache) then begin
        // �L���b�V�����Ȃ��ꍇ�͍ŏ��̃o�b�t�@��ǂݍ���
        Apu.LoadSPCFile(@Spc);
        T64Count := 0;
    end else begin
        // �L���b�V��������ꍇ�̓L���b�V����ǂݍ���
        SPCCache := @Status.SPCCache[J];
        Apu.LoadSPCFile(@SPCCache.Spc);
        API_MoveMemory(Status.Script700.Data, @SPCCache.Script700, SizeOf(TSCRIPT700EX));
        Apu.SPCOutPort.dwPort := SPCCache.SPCOutPort.dwPort;
        Apu.T64Count^ := T64Cache;
        T64Count := T64Cache;
    end;
    // ���t���ԁA�t�F�[�h�A�E�g���Ԃ�ݒ�
    if Option.bPlayTime then Apu.SetAPULength(Status.dwAPUPlayTime, Status.dwAPUFadeTime);
end;

begin
    // SPC ���J����Ă��Ȃ��A���t��~���A�܂��͈ꎞ��~���̏ꍇ�͏I��
    if not Status.bOpen or not Status.bPlay or Status.bPause then exit;
    // �Ō�ɃG�~�����[�g�������Ԃ��擾
    T64Count := Wave.Apu[Wave.dwLastIndex].T64Count;
    // ���݂̏ꏊ�ɕύX���Ȃ��ꍇ�͏I��
    if dwTime = T64Count then exit;
    // �V�[�N�ʒu�ɍł��߂��L���b�V���̏ꏊ���擾
    J := -1;
    for I := 0 to Option.dwSeekNum - 1 do if dwTime >= Status.SPCCache[I].Spc.Hdr.dwSongLen then J := I;
    if not bCache or (J = -1) then T64Cache := 0
    else T64Cache := Status.SPCCache[J].Spc.Hdr.dwSongLen;
    // ��܂��Ȉʒu�܂ŃV�[�N
    if dwTime > T64Count then begin
        // ���݈ʒu���L���b�V���ʒu�̕����߂��ꍇ�̓L���b�V����ǂݍ���
        if T64Cache > T64Count then CacheSeek();
        // �L���b�V���ʒu���o�߂���܂Ń��[�v
        while longbool(Status.dwNextCache) and (Status.dwNextCache < dwTime) do begin
            // �L���b�V������ʒu�܂ŃV�[�N
            if Status.dwNextCache > T64Count then Apu.SeekAPU(Status.dwNextCache - T64Count, byte(Option.dwSeekFast));
            // �L���b�V�����X�V
            Inc(J);
            SaveSeekCache(J);
            // ���݈ʒu���L�^
            T64Count := Apu.T64Count^;
        end;
    end else begin
        // �V�[�N�ʒu�ɍł��߂��L���b�V����ǂݍ���
        CacheSeek();
    end;
    // �ŏI�I�Ȉʒu�܂ŃV�[�N
    if dwTime > T64Count then Apu.SeekAPU(dwTime - T64Count, byte(Option.dwSeekFast));
    // �������o�t���O�����Z�b�g
    Status.dwMuteTimeout := 0;
    Status.dwMuteCounter := Option.dwBufferNum;
end;

// ================================================================================
// SPCStop - SPC ���t��~
// ================================================================================
procedure CWINDOWMAIN.SPCStop(bRestart: longbool);
begin
    // SPC ���J����Ă��Ȃ��A�܂��͉��t��~���̏ꍇ�͏I��
    if not Status.bOpen or not Status.bPlay then exit;
    // �t���O��ݒ�
    Status.bSPCRestart := bRestart;
{$IFDEF TRANSMITSPC}
    Status.bPlay := false;
    Status.bPause := false;
    Apu.StopTransmitSPC();
{$ENDIF}
    // �����ɍĉ��t����ꍇ
    if Status.bSPCRestart then begin
{$IFNDEF TRANSMITSPC}
        // ���t���~
        WaveReset();
{$ENDIF}
        // �ĉ��t
        SPCPlay(PLAY_TYPE_PLAY);
    end else begin
{$IFNDEF TRANSMITSPC}
        // ���t���~
        WaveClose();
{$ENDIF}
        // ���j���[���X�V
        UpdateMenu();
        // �C���W�P�[�^�����Z�b�g
        ResetInfo(true);
    end;
end;

// ================================================================================
// SPCTime - SPC ���Ԑݒ� (bSet=true ���A�r���K�{)
// ================================================================================
procedure CWINDOWMAIN.SPCTime(bCal: longbool; bDefault: longbool; bSet: longbool);
begin
    // ���t���Ԃ��v�Z����ꍇ
    if bCal then begin
        // �������o�t���O�����Z�b�g
        Status.dwMuteTimeout := 0;
        Status.dwMuteCounter := 0;
        // ���t���ԁA�t�F�[�h�A�E�g���Ԃ��v�Z
        Status.bNextDefault := Option.bPlayDefault or not bytebool(Spc.Hdr.TagFormat) or not longbool(Spc.Hdr.dwSongLen);
        if Status.bNextDefault then begin
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
    // ���t���Ԃ��g�p����ꍇ
    if bDefault or Option.bPlayTime then begin
        // �^�C���A�E�g��ݒ�
        if bCal then Status.dwNextTimeout := Status.dwDefaultTimeout;
        // ���t���ԁA�t�F�[�h�A�E�g���Ԃ�ݒ�
        if bSet then Apu.SetAPULength(Status.dwAPUPlayTime, Status.dwAPUFadeTime);
    end else begin
        // �^�C���A�E�g��ݒ�
        if bCal then Status.dwNextTimeout := 1;
        // ���t���̏ꍇ�͉��t���ԁA�t�F�[�h�A�E�g���Ԃ�ݒ�
        if bSet and Status.bPlay then Apu.SetAPULength($FFFFFFFF, 0);
    end;
end;

// ================================================================================
// UpdateInfo - ���X�V
// ================================================================================
procedure CWINDOWMAIN.UpdateInfo(bRedraw: longbool);
var
    sInfo: string;
    sBuffer: string;
begin
    // SPC ���J����Ă��Ȃ��ꍇ�͏I��
    if not Status.bOpen then exit;
    // �����쐬
    sInfo := 'Title    : ';
    if not bytebool(Spc.Hdr.Title[0]) then sInfo := Concat(sInfo, '(Unknown)')
    else sInfo := Concat(sInfo, string(Spc.Hdr.Title));
    sInfo := Concat(sInfo, CRLF, 'Game     : ');
    if not bytebool(Spc.Hdr.TagFormat) or not bytebool(Spc.Hdr.Game[0]) then sInfo := Concat(sInfo, '(Unknown)')
    else sInfo := Concat(sInfo, string(Spc.Hdr.Game));
    sInfo := Concat(sInfo, CRLF, 'Time     :  :  :  .');
    case Option.dwInfo of
        INFO_MIXER, INFO_CHANNEL_1, INFO_CHANNEL_2, INFO_CHANNEL_3, INFO_CHANNEL_4, INFO_SCRIPT700: begin
            case Option.dwInfo of
                INFO_CHANNEL_1: sInfo := Concat(sInfo, CRLF, '    Src Level Pitch EX       Src Level Pitch EX');
                INFO_CHANNEL_2: sInfo := Concat(sInfo, CRLF, '    Src ADSR/Gain   EX       Src ADSR/Gain   EX');
                INFO_CHANNEL_3: sInfo := Concat(sInfo, CRLF, '    Src On Flags   F R       Src On Flags   F R');
                INFO_CHANNEL_4: sInfo := Concat(sInfo, CRLF, '    Src Addr Loop Read       Src Addr Loop Read');
            end;
            case Option.dwInfo of
                INFO_MIXER: sInfo := Concat(sInfo, CRLF, 'MasterLv : L=    R=      EchoLv   : L=    R=', CRLF, 'Delay    :    (    ms)   Feedback :    (    ', STR_MENU_SETUP_PERCENT[Status.dwLanguage], ')', CRLF, 'SrcAddr  :     -   _     EchoAddr :     -', CRLF, 'DSPFlags : R=  M=  E=    NoiseClk :       Hz', CRLF, 'FIR      :');
                INFO_CHANNEL_1, INFO_CHANNEL_2, INFO_CHANNEL_3, INFO_CHANNEL_4: sInfo := Concat(sInfo, CRLF, '1 :                      5 :', CRLF, '2 :                      6 :', CRLF, '3 :                      7 :', CRLF, '4 :                      8 :');
                INFO_SCRIPT700: sInfo := Concat(sInfo, CRLF, 'Port  In :               Out :', CRLF, 'Work 0-3 :', CRLF, '     4-7 :', CRLF, 'CmpParam :                     Wait :', CRLF, 'UsedSize :        (Ptr=      Data=      SP=   )');
            end;
        end;
        INFO_SPC_1: begin
            sInfo := Concat(sInfo, CRLF, 'Artist   : ');
            if not bytebool(Spc.Hdr.TagFormat) or not bytebool(Spc.Hdr.Artist[0]) then sInfo := Concat(sInfo, '(Unknown)')
            else sInfo := Concat(sInfo, string(Spc.Hdr.Artist));
            sInfo := Concat(sInfo, CRLF, 'Dumper   : ');
            if not bytebool(Spc.Hdr.TagFormat) or not bytebool(Spc.Hdr.Dumper[0]) then sInfo := Concat(sInfo, '(Unknown)')
            else sInfo := Concat(sInfo, string(Spc.Hdr.Dumper));
            sInfo := Concat(sInfo, CRLF, 'Date     : ');
            if not bytebool(Spc.Hdr.TagFormat) or not bytebool(Spc.Hdr.Date[0]) then sInfo := Concat(sInfo, '(Unknown)')
            else sInfo := Concat(sInfo, string(Spc.Hdr.Date));
            sInfo := Concat(sInfo, CRLF, 'Comment  : ');
            if not bytebool(Spc.Hdr.TagFormat) or not bytebool(Spc.Hdr.Comment[0]) then sInfo := Concat(sInfo, '(Unknown)')
            else sInfo := Concat(sInfo, string(Spc.Hdr.Comment));
            sInfo := Concat(sInfo, CRLF, 'PlayTime : ');
            if not bytebool(Spc.Hdr.TagFormat) or not longbool(Spc.Hdr.dwSongLen) then sInfo := Concat(sInfo, '(Unknown)')
            else begin
                sBuffer := IntToStr(Spc.Hdr.dwSongLen);
                sInfo := Concat(sInfo, sBuffer, ' ', STR_MENU_SETUP_SEC2[Status.dwLanguage], StringOfChar(' ', 10 - Length(sBuffer)));
                if not longbool(Spc.Hdr.dwFadeLen) then sInfo := Concat(sInfo, '(No Fadeout)')
                else sInfo := Concat(sInfo, 'FadeTime : ', IntToStr(Spc.Hdr.dwFadeLen), ' ', STR_MENU_SETUP_MSEC[Status.dwLanguage]);
            end;
        end;
        INFO_SPC_2: begin
            sInfo := Concat(sInfo, CRLF, 'Header   : ', string(Spc.Hdr.FileHdr));
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
            sInfo := Concat(sInfo, CRLF, 'Emulator : ', sBuffer, StringOfChar(' ', 28 - Length(sBuffer)), 'NVPBHIZC', CRLF, 'Register : PC=     YA=     X=   SP=   ');
        end;
    end;
    // ����\��
    cwStaticMain.SetCaption(pchar(sInfo));
    // �ĕ`����s���ꍇ�A�C���W�P�[�^�����Z�b�g
    if bRedraw then ResetInfo(true);
end;

// ================================================================================
// UpdateMenu - ���j���[�X�V
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
    // �v���C���X�g�̈ʒu�ƃA�C�e�������擾
    dwIndex := cwPlayList.SendMessage(LB_GETCURSEL, NULL, NULL);
    dwCount := cwPlayList.SendMessage(LB_GETCOUNT, NULL, NULL);
    // �t�@�C�� ���j���[���X�V
    cmFile.SetMenuEnable(MENU_FILE_PLAY, (Status.bOpen or longbool(dwCount)) and (not Status.bPlay or Status.bPause));
    cmFile.SetMenuEnable(MENU_FILE_PAUSE, Status.bPlay and not Status.bPause);
    cmFile.SetMenuEnable(MENU_FILE_RESTART, Status.bPlay);
    cmFile.SetMenuEnable(MENU_FILE_STOP, Status.bPlay);
    // �{�^�����X�V
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
    Status.bTimeRepeat := Option.bPlayTime and ((Option.dwPlayOrder = PLAY_ORDER_STOP) or (Option.dwPlayOrder = PLAY_ORDER_REPEAT));
    // �ݒ胁�j���[���X�V
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
    for I := 0 to MENU_SETUP_INTER_SIZE - 1 do cmSetupInter.SetMenuCheck(MENU_SETUP_INTER_BASE + I, Option.dwInter = MENU_SETUP_INTER_VALUE[I]);
    for I := 0 to MENU_SETUP_PITCH_SIZE - 1 do cmSetupPitch.SetMenuCheck(MENU_SETUP_PITCH_BASE + I, Option.dwPitch = MENU_SETUP_PITCH_VALUE[I]);
    for I := 0 to MENU_SETUP_PITCH_KEY_SIZE + MENU_SETUP_PITCH_KEY_SIZE do cmSetupPitchKey.SetMenuCheck(MENU_SETUP_PITCH_KEY_BASE + I, Option.dwPitch = MENU_SETUP_PITCH_VALUE[MENU_SETUP_PITCH_SIZE + I]);
    cmSetupPitch.SetMenuCheck(MENU_SETUP_PITCH_ASYNC, Option.bPitchAsync);
    for I := 0 to MENU_SETUP_SEPARATE_SIZE - 1 do cmSetupSeparate.SetMenuCheck(MENU_SETUP_SEPARATE_BASE + I, Option.dwSeparate = MENU_SETUP_SEPARATE_VALUE[I]);
    for I := 0 to MENU_SETUP_FEEDBACK_SIZE - 1 do cmSetupFeedback.SetMenuCheck(MENU_SETUP_FEEDBACK_BASE + I, Option.dwFeedback = MENU_SETUP_FEEDBACK_VALUE[I]);
    for I := 0 to MENU_SETUP_SPEED_SIZE - 1 do cmSetupSpeed.SetMenuCheck(MENU_SETUP_SPEED_BASE + I, Option.dwSpeedBas = MENU_SETUP_SPEED_VALUE[I]);
    for I := 0 to MENU_SETUP_AMP_SIZE - 1 do cmSetupAmp.SetMenuCheck(MENU_SETUP_AMP_BASE + I, Option.dwAmp = MENU_SETUP_AMP_VALUE[I]);
    for I := 0 to MENU_SETUP_MUTE_NOISE_SIZE - 1 do begin
        cmSetupMute.SetMenuCheck(MENU_SETUP_MUTE_BASE + I, longbool(Option.dwMute and (1 shl I)));
        cmSetupNoise.SetMenuCheck(MENU_SETUP_NOISE_BASE + I, longbool(Option.dwNoise and (1 shl I)));
    end;
    for I := 0 to MENU_SETUP_OPTION_SIZE - 1 do cmSetupOption.SetMenuCheck(MENU_SETUP_OPTION_BASE + I, longbool(Option.dwOption and MENU_SETUP_OPTION_VALUE[I]));
    cmSetupTime.SetMenuCheck(MENU_SETUP_TIME_DISABLE, not Option.bPlayTime);
    cmSetupTime.SetMenuCheck(MENU_SETUP_TIME_ID666, Option.bPlayTime and not Option.bPlayDefault);
    cmSetupTime.SetMenuCheck(MENU_SETUP_TIME_DEFAULT, Option.bPlayTime and Option.bPlayDefault);
    cmSetupTime.SetMenuEnable(MENU_SETUP_TIME_START, Status.bPlay and Option.bPlayTime);
    cmSetupTime.SetMenuEnable(MENU_SETUP_TIME_LIMIT, Status.bPlay and Option.bPlayTime);
    cmSetupTime.SetMenuEnable(MENU_SETUP_TIME_RESET, Status.bOpen and Status.bTimeRepeat);
    for I := 0 to MENU_SETUP_ORDER_SIZE - 1 do cmSetupOrder.SetMenuCheck(MENU_SETUP_ORDER_BASE + I, Option.dwPlayOrder = longword(I));
    for I := 0 to MENU_SETUP_SEEK_SIZE - 1 do cmSetupSeek.SetMenuCheck(MENU_SETUP_SEEK_BASE + I, Option.dwSeekTime = MENU_SETUP_SEEK_VALUE[I]);
    for I := 0 to MENU_SETUP_INFO_SIZE - 1 do cmSetupInfo.SetMenuCheck(MENU_SETUP_INFO_BASE + I, Option.dwInfo = longword(I));
    cmSetupInfo.SetMenuCheck(MENU_SETUP_INFO_RESET, Option.bVolumeReset);
    for I := 0 to MENU_SETUP_PRIORITY_SIZE - 1 do begin
        cmSetupPriority.SetMenuCheck(MENU_SETUP_PRIORITY_BASE + I, Option.dwPriority = MENU_SETUP_PRIORITY_VALUE[I]);
        cmSetupPriority.SetMenuEnable(MENU_SETUP_PRIORITY_BASE + I, (Status.OsVersionInfo.dwMajorVersion >= 5) or (MENU_SETUP_PRIORITY_VALUE[I] <= REALTIME_PRIORITY_CLASS));
    end;
    cmSetup.SetMenuCheck(MENU_SETUP_TOPMOST, Option.bTopMost);
    // �{�^�����X�V
    for I := 0 to 7 do cwCheckTrack[I].SendMessage(BM_SETCHECK, 1 - (Option.dwMute and (1 shl I)) shr I, NULL);
    cwButtonVolM.SetWindowEnable(Option.dwAmp > AMP_025);
    cwButtonVolP.SetWindowEnable(Option.dwAmp < AMP_400);
    cwButtonSlow.SetWindowEnable(Option.dwSpeedBas > SPEED_025);
    cwButtonFast.SetWindowEnable(Option.dwSpeedBas < SPEED_400);
    cwButtonBack.SetWindowEnable(bUp);
    cwButtonNext.SetWindowEnable(bUp);
    // �v���C���X�g ���j���[���X�V
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
    // �{�^�����X�V
    cwPlayList.SetWindowEnable(bDelete);
    cwButtonListAdd.SetWindowEnable(Status.bOpen and bMax);
    cwButtonListRemove.SetWindowEnable(bDelete);
    cwButtonListClear.SetWindowEnable(bDelete);
    cwButtonListUp.SetWindowEnable(bUp);
    cwButtonListDown.SetWindowEnable(bDown);
    // �t�H�[�J�X��ݒ�
    if not API_IsWindowEnabled(API_GetFocus()) then SetTabFocus(API_GetFocus(), true);
end;

// ================================================================================
// UpdateTitle - �^�C�g���\��
// ================================================================================
procedure CWINDOWMAIN.UpdateTitle(dwFlag: longword);
var
    dwInfo: longword;
    sInfo: string;
begin
    // �^�C�g�����X�V���Ȃ��ꍇ�͏I��
    if not longbool(Status.dwTitle) then exit;
    // �I�v�V��������̃t���O��ݒ�
    if longbool(dwFlag) then begin
        API_SetTimer(cwWindowMain.hWnd, TIMER_ID_TITLE_INFO, TIMER_INTERVAL_TITLE_INFO, NULLPOINTER);
        Status.dwTitle := (Status.dwTitle and TITLE_ALWAYS_FLAG) or dwFlag;
    end;
    // �^�C�g����ݒ�
    sInfo := '';
    dwInfo := Status.dwTitle and not TITLE_ALWAYS_FLAG;
    // �I�v�V�������ύX���ꂽ�ꍇ
    if longbool(dwInfo) then begin
        sInfo := Concat(sInfo, TITLE_INFO_HEADER[Status.dwLanguage]);
        case dwInfo of
            TITLE_INFO_SEPARATE: sInfo := Concat(sInfo, TITLE_INFO_SEPARATE_HEADER[Status.dwLanguage], IntToStr(Status.dwInfo), ' ', STR_MENU_SETUP_PERCENT[Status.dwLanguage]);
            TITLE_INFO_FEEDBACK: sInfo := Concat(sInfo, TITLE_INFO_FEEDBACK_HEADER[Status.dwLanguage], IntToStr(Status.dwInfo), ' ', STR_MENU_SETUP_PERCENT[Status.dwLanguage]);
            TITLE_INFO_SPEED: sInfo := Concat(sInfo, TITLE_INFO_SPEED_HEADER[Status.dwLanguage], IntToStr(Status.dwInfo), ' ', STR_MENU_SETUP_PERCENT[Status.dwLanguage]);
            TITLE_INFO_AMP: sInfo := Concat(sInfo, TITLE_INFO_AMP_HEADER[Status.dwLanguage], IntToStr(Status.dwInfo), ' ', STR_MENU_SETUP_PERCENT[Status.dwLanguage]);
            TITLE_INFO_SEEK: begin
                sInfo := Concat(sInfo, TITLE_INFO_SEEK_HEADER[Status.dwLanguage]);
                if Status.dwInfo >= 0 then sInfo := Concat(sInfo, TITLE_INFO_PLUS[Status.dwLanguage])
                else sInfo := Concat(sInfo, TITLE_INFO_MINUS[Status.dwLanguage]);
                if longbool(Abs(Status.dwInfo) mod 1000) then sInfo := Concat(sInfo, IntToStr(Abs(Status.dwInfo)), STR_MENU_SETUP_MSEC[Status.dwLanguage])
                else sInfo := Concat(sInfo, IntToStr(longword(Trunc(Abs(Status.dwInfo) / 1000))), ' ', STR_MENU_SETUP_SEC1[Status.dwLanguage]);
            end;
        end;
        sInfo := Concat(sInfo, TITLE_INFO_FOOTER[Status.dwLanguage], TITLE_MAIN_HEADER[Status.dwLanguage]);
    // SPC ���J����Ă���ꍇ
    end else if Status.bOpen then begin
        // �ŏ������Ă���ꍇ
        if longbool(Status.dwTitle and TITLE_MINIMIZE) then begin
            // SPC �̃^�C�g����ǉ�
            if not bytebool(Spc.Hdr.Title[0]) then sInfo := Concat(sInfo, TITLE_NAME_UNKNOWN)
            else sInfo := Concat(sInfo, string(Spc.Hdr.Title));
            if bytebool(Spc.Hdr.TagFormat) and bytebool(Spc.Hdr.Game[0]) then sInfo := Concat(sInfo, TITLE_NAME_SEPARATOR[Status.dwLanguage], string(Spc.Hdr.Game));
            sInfo := Concat(sInfo, TITLE_NAME_HEADER[Status.dwLanguage], Copy(string(Status.lpSPCName), 1, GetSize(Status.lpSPCName, 1023)), TITLE_NAME_FOOTER[Status.dwLanguage], TITLE_MAIN_HEADER[Status.dwLanguage]);
        end else begin
            // SPC �̃t�@�C������ǉ�
            sInfo := Concat(sInfo, Copy(string(Status.lpSPCName), 1, GetSize(Status.lpSPCName, 1023)), TITLE_MAIN_HEADER[Status.dwLanguage]);
        end;
    end;
    // �^�C�g�����X�V
    sInfo := Concat(sInfo, DEFAULT_TITLE);
    cwWindowMain.SetCaption(pchar(sInfo));
end;

// ================================================================================
// UpdateWindow - �E�B���h�E�X�V
// ================================================================================
procedure CWINDOWMAIN.UpdateWindow();
begin
    cwWindowMain.UpdateWindow(true);
    cwWindowMain.SetWindowTopMost(Option.bTopMost);
end;

// ================================================================================
// WaveClose - �f�o�C�X�����
// ================================================================================
procedure CWINDOWMAIN.WaveClose();
var
    I: longint;
begin
    // �f�o�C�X�����Z�b�g
    WaveReset();
    // �T�E���h �o�b�t�@�����
    for I := 0 to Option.dwBufferNum - 1 do API_waveOutUnprepareHeader(Wave.dwHandle, @Wave.Header[I], SizeOf(TWAVEHDR));
    // �f�o�C�X���N���[�Y
    API_waveOutClose(Wave.dwHandle);
    // �f�o�C�X�����S�ɃN���[�Y�����܂őҋ@
    while not longbool(Status.dwThreadStatus and WAVE_THREAD_DEVICE_CLOSED) do API_Sleep(1);
    Status.dwThreadStatus := Status.dwThreadStatus xor WAVE_THREAD_DEVICE_CLOSED;
    // �n���h����������
    Wave.dwHandle := 0;
end;

// ================================================================================
// WaveFormat - �t�H�[�}�b�g������
// ================================================================================
procedure CWINDOWMAIN.WaveFormat(dwIndex: longword);
begin
    // �^�O�̎�ނ𔻕�
    case WAVE_FORMAT_TAG_ARRAY[dwIndex] of
        WAVE_FORMAT_EXTENSIBLE: begin // WAVEFORMATEXTENSIBLE �\����
            Wave.Format.wFormatTag := WAVE_FORMAT_EXTENSIBLE;
            Wave.Format.cbSize := 22;
            case Option.dwBit of
                BIT_IEEE: Wave.Format.SubFormat := KSDATAFORMAT_SUBTYPE_IEEE_FLOAT;
                else Wave.Format.SubFormat := KSDATAFORMAT_SUBTYPE_PCM;
            end;
        end;
        WAVE_FORMAT_PCM: begin // WAVEFORMATEX �\����
            case Option.dwBit of
                BIT_IEEE: Wave.Format.wFormatTag := WAVE_FORMAT_IEEE_FLOAT;
                else Wave.Format.wFormatTag := WAVE_FORMAT_PCM;
            end;
            Wave.Format.cbSize := 0;
        end;
    end;
end;

// ================================================================================
// WaveInit - �f�o�C�X������
// ================================================================================
procedure CWINDOWMAIN.WaveInit();
var
    I: longint;
    dwBit: longword;
begin
    // �t���O��ݒ�
    Status.dwWaveMessage := WAVE_MESSAGE_MAX_COUNT;
    Status.bPlay := false;
    Status.bPause := false;
    // �t�H�[�}�b�g��������
    dwBit := Abs(Option.dwBit);
    Wave.Format.wBitsPerSample := word(dwBit shl 3);
    Wave.Format.nSamplesPerSec := Option.dwRate;
    Wave.Format.nChannels := word(Option.dwChannel);
    Wave.Format.nBlockAlign := word(Option.dwChannel * dwBit);
    Wave.Format.nAvgBytesPerSec := Option.dwChannel * dwBit * Option.dwRate;
    Wave.Format.wValidBitsPerSample := Wave.Format.wBitsPerSample;
    Wave.Format.dwChannelMask := $3; // FL, FR
    // �o�b�t�@ �T�C�Y���v�Z
    Wave.dwEmuSize := Option.dwBufferTime * Wave.Format.nAvgBytesPerSec div 1000 div Wave.Format.nBlockAlign;
    Wave.dwBufSize := Wave.dwEmuSize * Wave.Format.nBlockAlign;
    // �o�b�t�@���m��
    for I := 0 to Option.dwBufferNum - 1 do GetMem(Wave.lpData[I], Wave.dwBufSize);
end;

// ================================================================================
// WaveOpen - �f�o�C�X���J��
// ================================================================================
function CWINDOWMAIN.WaveOpen(): longword;
var
    I: longint;
    J: longint;
    WaveHdr: ^TWAVEHDR;
begin
    // �f�o�C�X���I�[�v��
    for I := 0 to WAVE_FORMAT_TAG_SIZE - 1 do begin
        // �t�H�[�}�b�g��������
        WaveFormat(I);
        // �f�o�C�X���I�[�v��
        for J := 0 to WAVE_FORMAT_TYPE_SIZE - 1 do begin
            result := API_waveOutOpen(@Wave.dwHandle, Option.dwDeviceID, @Wave.Format, Status.dwThreadID, NULL, WAVE_FORMAT_TYPE_ARRAY[J] or CALLBACK_THREAD);
            if not longbool(result) then break;
        end;
        if not longbool(result) then break;
    end;
    // �t���O��ݒ�
    Status.dwWaveMessage := WAVE_MESSAGE_MAX_COUNT;
    Status.bPlay := not longbool(result);
    Status.bPause := false;
    // �f�o�C�X�̃I�[�v���Ɏ��s�����ꍇ�͏I��
    if not Status.bPlay then exit;
    // �f�o�C�X�����S�ɃI�[�v�������܂őҋ@
    while not longbool(Status.dwThreadStatus and WAVE_THREAD_DEVICE_OPENED) do API_Sleep(1);
    Status.dwThreadStatus := Status.dwThreadStatus xor WAVE_THREAD_DEVICE_OPENED;
    // �T�E���h �o�b�t�@������
    for I := 0 to Option.dwBufferNum - 1 do begin
        WaveHdr := @Wave.Header[I];
        API_ZeroMemory(WaveHdr, SizeOf(TWAVEHDR));
        WaveHdr.lpData := Wave.lpData[I];
        WaveHdr.dwBufferLength := Wave.dwBufSize;
        API_waveOutPrepareHeader(Wave.dwHandle, WaveHdr, SizeOf(TWAVEHDR));
    end;
end;

// ================================================================================
// WavePause - �f�o�C�X�ꎞ��~ (�r������)
// ================================================================================
function CWINDOWMAIN.WavePause(): longbool;
begin
    // ������
    result := false;
    // �N���e�B�J�� �Z�N�V�������J�n
    API_EnterCriticalSection(@CriticalSectionThread);
    // ���t���̏ꍇ
    if Status.bPlay and not Status.bPause then begin
        // �t���O��ݒ�
        Status.bPause := true;
        // �ꎞ��~
        API_waveOutPause(Wave.dwHandle);
        // ����
        result := true;
    end;
    // �N���e�B�J�� �Z�N�V�������I��
    API_LeaveCriticalSection(@CriticalSectionThread);
end;

// ================================================================================
// WaveProc - �f�o�C�X �v���V�[�W�� (dwFlag<>WAVE_PROC_GRAPH_ONLY ���A�r���K�{)
// ================================================================================
procedure CWINDOWMAIN.WaveProc(dwFlag: longword);
var
    I: longint;
    J: longint;
    K: longword;
    dwIndex: longword;
    bInit: longbool;
    bWave: longbool;
    ApuData: ^TAPUDATA;
    DspReg: ^TDSPREG;
    T64Count: longword;
    T64Cache: longword;
    Voice: ^TVOICE;
    DspVoice: ^TDSPVOICE;

begin
    // �o�b�t�@��ݒ�
    dwIndex := Wave.dwIndex;
    bInit := longbool(dwFlag and WAVE_PROC_WRITE_INIT);
    bWave := longbool(dwFlag and WAVE_PROC_WRITE_WAVE);
    // �����f�[�^��]������ꍇ
    if bWave then begin
        // �o�̓��x���l��������
        Apu.VolumeMaxLeft^ := 0;
        Apu.VolumeMaxRight^ := 0;
        for I := 0 to 7 do begin
            Voice := @Apu.Voices.Voice[I];
            Voice.VolumeMaxLeft := 0;
            Voice.VolumeMaxRight := 0;
        end;
        // �V�����o�b�t�@���擾
        if Status.bWaveWrite then Apu.EmuAPU(Wave.lpData[dwIndex], Wave.dwEmuSize, 1);
        // �o�b�t�@���f�o�C�X�ɓ]��
        API_waveOutWrite(Wave.dwHandle, @Wave.Header[dwIndex], SizeOf(TWAVEHDR));
        // APU �f�[�^���R�s�[
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
    // �C���W�P�[�^��`�悵�Ȃ��ꍇ�͏I��
    if longbool(dwFlag and WAVE_PROC_NO_GRAPH) then exit;
    // �o�b�t�@��ݒ�
    ApuData := @Wave.Apu[dwIndex];
    DspReg := @ApuData.DspReg;
    T64Count := ApuData.T64Count;
    T64Cache := Apu.T64Count^;
    // �����X�V
    if (longbool(Option.dwDrawInfo and DRAW_INFO_ALWAYS) or longbool(Status.dwTitle and TITLE_NORMAL)) then begin
        // �N���e�B�J�� �Z�N�V�������J�n
        API_EnterCriticalSection(@CriticalSectionStatic);
        // �C���W�P�[�^��`��
        if not longbool(Status.dwRedrawInfo and REDRAW_LOCK_READY) then DrawInfo(ApuData, bWave);
        // �N���e�B�J�� �Z�N�V�������I��
        API_LeaveCriticalSection(@CriticalSectionStatic);
    end;
    // �L���b�V����ۑ����鎞�ԂɂȂ����ꍇ
    if longbool(Status.dwNextCache) and (T64Cache >= Status.dwNextCache) then begin
        // �L���b�V������o�b�t�@�̈ʒu���擾
        J := 0;
        for I := 0 to Option.dwSeekNum - 1 do if T64Cache >= Status.SPCCache[I].Spc.Hdr.dwFadeLen then J := I;
        // �L���b�V����ۑ�
        SaveSeekCache(J);
    end;
    // �^�C���A�E�g���������Ă��Ȃ��ꍇ
    if not bInit and bWave and Option.bPlayTime and longbool(Status.dwNextTimeout) then begin
        // �p�����[�^������
        J := 0;
        K := 0;
        // ���t���Ԃ��m�F
        if T64Count >= Status.dwNextTimeout then J := 1;
        if Status.bTimeRepeat and (T64Count >= Status.dwLimitTime) then J := 1;
        if Status.bNextDefault then begin
            for I := 0 to 7 do begin
                DspVoice := @DspReg.Voice[I];
                if (bytebool(DspVoice.VolumeLeft) or bytebool(DspVoice.VolumeRight)) and bytebool(DspVoice.CurrentEnvelope) then begin
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
        // ���̋Ȃ����t����ꍇ
        if longbool(J) then begin
            // ������ (�^�C���A�E�g��ݒ�)
            Status.dwNextTimeout := 0;
            // �f�b�h���b�N��h�~���邽�߁A�E�B���h�E ���b�Z�[�W�𑗐M
            cwWindowMain.PostMessage(WM_APP_MESSAGE, WM_APP_NEXT_PLAY, NULL);
        end;
    end;
end;

// ================================================================================
// WaveQuit - �f�o�C�X���
// ================================================================================
procedure CWINDOWMAIN.WaveQuit();
var
    I: longint;
begin
{$IFNDEF TRANSMITSPC}
    // ���t���̏ꍇ�̓f�o�C�X���N���[�Y
    if Status.bPlay then WaveClose();
{$ENDIF}
    // �o�b�t�@�����
    for I := 0 to Option.dwBufferNum - 1 do FreeMem(Wave.lpData[I], Wave.dwBufSize);
end;

// ================================================================================
// WaveReset - �f�o�C�X ���Z�b�g (�r������)
// ================================================================================
procedure CWINDOWMAIN.WaveReset();
var
    I: longint;
begin
    // Script700 �������I��
    Status.Script700.Data.dwStackFlag := Status.Script700.Data.dwStackFlag or $80000000;
    Status.bWaveWrite := false;
    // �N���e�B�J�� �Z�N�V�������J�n
    API_EnterCriticalSection(@CriticalSectionThread);
    // �t���O��ݒ�
    Status.dwWaveMessage := WAVE_MESSAGE_MAX_COUNT;
    Status.bPlay := false;
    Status.bPause := false;
    // �f�o�C�X �A�C�h���܂ł̃J�E���g��ݒ�
    Status.dwThreadIdle := Option.dwBufferNum;
    // �f�o�C�X�����Z�b�g
    API_waveOutReset(Wave.dwHandle);
    // �N���e�B�J�� �Z�N�V�������I��
    API_LeaveCriticalSection(@CriticalSectionThread);
    // �f�o�C�X���A�C�h����ԂɂȂ�܂őҋ@
    while longbool(Status.dwThreadIdle) do API_Sleep(1);
    // �C���W�P�[�^���N���A
    for I := 0 to Option.dwBufferNum - 1 do API_ZeroMemory(@Wave.Apu[I], SizeOf(TAPUDATA));
end;

// ================================================================================
// WaveResume - �f�o�C�X�ĊJ (�r������)
// ================================================================================
function CWINDOWMAIN.WaveResume(): longbool;
begin
    // ������
    result := false;
    // �N���e�B�J�� �Z�N�V�������J�n
    API_EnterCriticalSection(@CriticalSectionThread);
    // �ꎞ��~���̏ꍇ
    if Status.bPlay and Status.bPause then begin
        // �t���O��ݒ�
        Status.bPause := false;
        // �ꎞ��~������
        API_waveOutRestart(Wave.dwHandle);
        // ����
        result := true;
    end;
    // �N���e�B�J�� �Z�N�V�������I��
    API_LeaveCriticalSection(@CriticalSectionThread);
end;

// ================================================================================
// WaveSave - WAVE �t�@�C���̕ۑ�
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
    dwDec1 := Trunc((dwSize and $FFFFF) / $100000 * 100);
    dwDec2 := dwDec1 mod 10;
    dwDec1 := (dwDec1 - dwDec2) div 10;
    result := Concat(IntToStr(dwInt), '.', IntToStr(dwDec1), IntToStr(dwDec2));
end;

begin
    // ������
    result := false;
    // ���t��~
    SPCStop(false);
    // �N���e�B�J�� �Z�N�V�������J�n
    API_EnterCriticalSection(@CriticalSectionThread);
    // SPC �� APU �ɓ]��
    Apu.LoadSPCFile(@Spc);
    // SPC ���t�ݒ�
    SPCOption();
    // ���t���ԁA�t�F�[�h�A�E�g���Ԃ�ݒ�
    SPCTime(true, true, true);
    // �N���e�B�J�� �Z�N�V�������I��
    API_LeaveCriticalSection(@CriticalSectionThread);
    // �w�b�_ �T�C�Y���v�Z
    case Option.dwWaveFormat of
        1: WaveFormat(WAVE_FORMAT_INDEX_PCM);
        2: WaveFormat(WAVE_FORMAT_INDEX_EXTENSIBLE);
        else case Option.dwBit of
            BIT_8, BIT_16: WaveFormat(WAVE_FORMAT_INDEX_PCM);
            else WaveFormat(WAVE_FORMAT_INDEX_EXTENSIBLE);
        end;
    end;
    dwSizeH := 16;
    if wordbool(Wave.Format.cbSize) then Inc(dwSizeH, Wave.Format.cbSize + 2);
    dwSizeP := dwSizeH + 28; // "RIFF" + 4 + "WAVE" + "fmt " + 4 + HEADER + "data" + 4
    // �����̃T�C�Y���v�Z
    dwWaveL := Option.dwWaveBlank; // �ŏ��̖�������
    dwBlank := 0;
    if dwWaveL < $80000000 then begin
        Inc(dwWaveL, dwWaveL mod 100); // �Ԋu����
        dwBlank := dwWaveL div 100;
    end;
    // �����̃T�C�Y���v�Z
    qwWaveL := int64((Status.dwAPUPlayTime + Status.dwAPUFadeTime) shr 6) * SPEED_100;
    dwWaveB := Option.dwSpeedBas + Round(Option.dwSpeedBas / SPEED_100 * Option.dwSpeedTun);
    dwWaveL := qwWaveL div dwWaveB;
    Inc(dwWaveL, dwWaveL mod 100); // �Ԋu����
    dwCount := dwWaveL div 100;
    // �o�b�t�@ �T�C�Y���v�Z
    dwWaveB := Wave.Format.nAvgBytesPerSec div 10 div longword(Wave.Format.nBlockAlign); // 100ms ���Ƃ̃T���v����
    dwSizeB := dwWaveB * longword(Wave.Format.nBlockAlign); // 100ms ���Ƃ̃o�C�g��
    dwSizeT := dwSizeP + (dwBlank + dwCount + 10) * dwSizeB; // �w�b�_ + �ŏ��̖��� + ���� + �Ō�̖���
    // �m�F���b�Z�[�W��\��
    if not bQuiet then if cwWindowMain.MessageBox(pchar(Concat(WARN_WAVE_SIZE_1[Status.dwLanguage], GetMBString(dwSizeT), WARN_WAVE_SIZE_2[Status.dwLanguage])), pchar(DEFAULT_TITLE), MB_ICONQUESTION or MB_YESNO or MB_DEFBUTTON2) <> IDYES then exit;
    // �t�@�C�����I�[�v��
    hFile := INVALID_HANDLE_VALUE;
    if IsSafePath(lpFile) then begin
        API_MakeSureDirectoryPathExists(lpFile);
        hFile := API_CreateFile(lpFile, GENERIC_WRITE, FILE_SHARE_READ, NULLPOINTER, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL or FILE_FLAG_SEQUENTIAL_SCAN, NULL);
    end;
    // �t�@�C���̃I�[�v���Ɏ��s�����ꍇ�̓��b�Z�[�W��\�����ďI��
    if hFile = INVALID_HANDLE_VALUE then begin
        ShowErrMsg(252);
        exit;
    end;
    // �i�s�󋵂�\��
    cwWindowMain.SetCaption(pchar(Concat(TITLE_INFO_HEADER[Status.dwLanguage], TITLE_INFO_FILE_HEADER[Status.dwLanguage], TITLE_INFO_FOOTER[Status.dwLanguage], TITLE_MAIN_HEADER[Status.dwLanguage], DEFAULT_TITLE)));
    // �N���e�B�J�� �Z�N�V�������J�n
    API_EnterCriticalSection(@CriticalSectionThread);
    // WAVE �w�b�_���o�� (�T�C�Y = WaveHeader + 28)
    dwSizeT := 0;
    qwData.l := $46464952; // "RIFF" + �T�C�Y (��Ōv�Z)
    API_WriteFile(hFile, @qwData, 8, @dwSizeT, NULLPOINTER);
    qwData.l := $45564157; // "WAVE"
    API_WriteFile(hFile, @qwData, 4, @dwSizeT, NULLPOINTER);
    qwData.l := $20746D66; // "fmt " + �T�C�Y
    qwData.h := dwSizeH;
    API_WriteFile(hFile, @qwData, 8, @dwSizeT, NULLPOINTER);
    API_WriteFile(hFile, @Wave.Format, dwSizeH, @dwSizeT, NULLPOINTER);
    qwData.l := $61746164; // "data" + �T�C�Y (��Ōv�Z)
    API_WriteFile(hFile, @qwData, 8, @dwSizeT, NULLPOINTER);
    // �o�b�t�@���m��
    GetMem(lpData, dwSizeB);
    // �ŏ��̖������o��
    if Option.dwBit = BIT_8 then API_FillMemory(lpData, dwSizeB, $80)
    else API_ZeroMemory(lpData, dwSizeB);
    if longbool(dwBlank) then for I := 0 to dwBlank - 1 do begin
        API_WriteFile(hFile, lpData, dwSizeB, @dwSizeT, NULLPOINTER);
        Inc(dwSizeP, dwSizeB);
    end;
    // WAVE �f�[�^���o��
    dwPCent := $FFFFFFFF;
    dwSizeL := dwSizeP; // �Ō�̃|�C���^�A���݂̃|�C���^
    if Option.dwWaveBlank >= 0 then dwSizeT := 0 else dwSizeT := 1;
    for I := 0 to dwCount - 1 do begin
        // �V�����o�b�t�@���擾
        Apu.VolumeMaxLeft^ := 0;
        Apu.VolumeMaxRight^ := 0;
        Apu.EmuAPU(lpData, dwWaveB, 1);
        // ���������o
        if not longbool(dwSizeT) then begin
            if (Apu.VolumeMaxLeft^ >= MIN_WAVE_LEVEL) or (Apu.VolumeMaxRight^ >= MIN_WAVE_LEVEL) then Inc(dwSizeT);
        end;
        // �t�@�C���ɏo��
        if longbool(dwSizeT) then begin
            API_WriteFile(hFile, lpData, dwSizeB, @dwSizeT, NULLPOINTER);
            Inc(dwSizeP, dwSizeB);
            if (Apu.VolumeMaxLeft^ >= MIN_WAVE_LEVEL) or (Apu.VolumeMaxRight^ >= MIN_WAVE_LEVEL) then dwSizeL := dwSizeP;
        end;
        // �i�s�󋵂�\��
        dwWaveL := Trunc((I + 1) / dwCount * 10) * 10;
        if dwWaveL <> dwPCent then begin
            dwPCent := dwWaveL;
            cwWindowMain.SetCaption(pchar(Concat(TITLE_INFO_HEADER[Status.dwLanguage], TITLE_INFO_FILE_HEADER[Status.dwLanguage], IntToStr(dwPCent), TITLE_INFO_FILE_PROC[Status.dwLanguage], TITLE_INFO_FOOTER[Status.dwLanguage], TITLE_MAIN_HEADER[Status.dwLanguage], DEFAULT_TITLE)));
        end;
    end;
    // �Ō�̖��� (1000ms) ���o��
    if Option.dwBit = BIT_8 then API_FillMemory(lpData, dwSizeB, $80)
    else API_ZeroMemory(lpData, dwSizeB);
    for I := 0 to 9 do begin
        API_WriteFile(hFile, lpData, dwSizeB, @dwSizeT, NULLPOINTER);
        Inc(dwSizeL, dwSizeB);
    end;
    // �o�b�t�@�����
    FreeMem(lpData, dwSizeB);
    // �o�b�t�@ �T�C�Y���o��
    dwSizeB := 0;
    API_SetFilePointer(hFile, 4, @dwSizeB, FILE_BEGIN);
    dwSizeP := dwSizeL - 8; // �t�@�C�� �T�C�Y - ("RIFF" + 4)
    API_WriteFile(hFile, @dwSizeP, 4, @dwSizeT, NULLPOINTER);
    API_SetFilePointer(hFile, dwSizeH + 24, @dwSizeB, FILE_BEGIN);
    dwSizeP := dwSizeL - dwSizeH - 28; // �f�[�^ �T�C�Y
    API_WriteFile(hFile, @dwSizeP, 4, @dwSizeT, NULLPOINTER);
    // �t�@�C���̏I�[�ʒu��ݒ�
    API_SetFilePointer(hFile, dwSizeL, @dwSizeB, FILE_BEGIN);
    API_SetEndOfFile(hFile);
    // �t�@�C�����N���[�Y
    API_CloseHandle(hFile);
    // �N���e�B�J�� �Z�N�V�������I��
    API_LeaveCriticalSection(@CriticalSectionThread);
    // �^�C�g�����X�V
    UpdateTitle(NULL);
    // ���b�Z�[�W��\��
    if not bQuiet then cwWindowMain.MessageBox(pchar(Concat(INFO_WAVE_FINISH_1[Status.dwLanguage], GetMBString(dwSizeL), INFO_WAVE_FINISH_2[Status.dwLanguage])), pchar(DEFAULT_TITLE), MB_ICONINFORMATION or MB_OK);
    // ����
    result := true;
end;

// ================================================================================
// WaveStart - �f�o�C�X���t�J�n (�r���K�{)
// ================================================================================
procedure CWINDOWMAIN.WaveStart();
var
    I: longint;
    J: longint;
begin
    // �ꎞ��~
    API_waveOutPause(Wave.dwHandle);
    // �o�b�t�@�]��
    J := Option.dwBufferNum - 1;
    for I := 0 to J do WaveProc((J - I) or WAVE_PROC_WRITE_WAVE or WAVE_PROC_WRITE_INIT);
    // ���t�J�n
    API_waveOutRestart(Wave.dwHandle);
end;

// ================================================================================
// WindowProc - ���b�Z�[�W����
// ================================================================================
function CWINDOWMAIN.WindowProc(hWnd: longword; msg: longword; wParam: longword; lParam: longword; var dwDef: longword): longword;

procedure SetSPCTime();
begin
    // ���t���ԁA�t�F�[�h�A�E�g���Ԃ�ݒ�
    SPCTime(true, false, false);
    // SPC ���J����Ă��Ȃ��A�܂��͉��t��~���̏ꍇ�͏I��
    if not Status.bOpen or not Status.bPlay then exit;
    // �X���b�h�ɐݒ�ύX��ʒm
    API_PostThreadMessage(Status.dwThreadID, WM_APP_MESSAGE, WM_APP_SPC_TIME, NULL);
end;

procedure ResetTimeMark();
begin
    // SPC ���J����Ă��Ȃ��A�܂��͉��t���Ԃ������̏ꍇ�͏I��
    if not Status.bOpen or not Option.bPlayTime then exit;
    // ���s�[�g�J�n�ʒu�A���s�[�g�I���ʒu��������
    Status.dwStartTime := 0;
    Status.dwLimitTime := Status.dwDefaultTimeout;
    Option.dwPlayOrder := Status.dwPlayOrder;
    // ��ԃ��s�[�g�������̏ꍇ�͏I��
    if not Status.bTimeRepeat then exit;
    // �C���W�P�[�^���ĕ`��
    cwWindowMain.PostMessage(WM_APP_MESSAGE, WM_APP_REDRAW, NULL);
end;

procedure ChangeSPCTime();
var
    bPlayTime: longbool;
    bPlayDefault: longbool;
begin
    // ���݂̐ݒ�l���L�^
    bPlayTime := Option.bPlayTime;
    bPlayDefault := Option.bPlayDefault;
    // �t���O��ݒ�
    Option.bPlayTime := wParam <> MENU_SETUP_TIME_DISABLE;
    if Option.bPlayTime then Option.bPlayDefault := wParam = MENU_SETUP_TIME_DEFAULT;
    // ���t���ԁA�t�F�[�h�A�E�g���Ԃ�ݒ�
    SetSPCTime();
    // �ݒ肪�ύX���ꂽ�ꍇ�́A���s�[�g�J�n�ʒu�A���s�[�g�I���ʒu��������
    if bPlayTime <> Option.bPlayTime or bPlayDefault <> Option.bPlayDefault then begin
        Status.dwStartTime := 0;
        Status.dwLimitTime := Status.dwDefaultTimeout;
        if bPlayTime <> Option.bPlayTime then Option.dwPlayOrder := Status.dwPlayOrder;
    end;
    // �C���W�P�[�^���ĕ`��
    cwWindowMain.PostMessage(WM_APP_MESSAGE, WM_APP_REDRAW, NULL);
end;

procedure SetStartTimeMark();
begin
    // SPC ���J����Ă��Ȃ��A���t��~���A���t���Ԃ������A�܂��̓^�C���A�E�g�����������ꍇ�͏I��
    if not Status.bOpen or not Status.bPlay or not Option.bPlayTime or not longbool(Status.dwNextTimeout) then exit;
    // ���݂̏ꏊ�����s�[�g�J�n�ʒu�ɐݒ�
    Status.dwStartTime := Wave.Apu[Wave.dwIndex].T64Count;
    if Status.dwLimitTime < Status.dwStartTime then Status.dwLimitTime := Status.dwStartTime;
    // �����I�Ƀ��s�[�g���[�h�ɐݒ�
    if not Status.bTimeRepeat then Status.dwPlayOrder := Option.dwPlayOrder;
    if Option.dwPlayOrder <> PLAY_ORDER_STOP then Option.dwPlayOrder := PLAY_ORDER_REPEAT;
    // �C���W�P�[�^���ĕ`��
    cwWindowMain.PostMessage(WM_APP_MESSAGE, WM_APP_REDRAW, NULL);
end;

procedure SetLimitTimeMark();
begin
    // SPC ���J����Ă��Ȃ��A���t��~���A���t���Ԃ������A�܂��̓^�C���A�E�g�����������ꍇ�͏I��
    if not Status.bOpen or not Status.bPlay or not Option.bPlayTime or not longbool(Status.dwNextTimeout) then exit;
    // ���݂̏ꏊ�����s�[�g�I���ʒu�ɐݒ�
    Status.dwLimitTime := Wave.Apu[Wave.dwIndex].T64Count;
    if Status.dwStartTime > Status.dwLimitTime then Status.dwStartTime := Status.dwLimitTime;
    // �����I�Ƀ��s�[�g���[�h�ɐݒ�
    if not Status.bTimeRepeat then Status.dwPlayOrder := Option.dwPlayOrder;
    if Option.dwPlayOrder <> PLAY_ORDER_STOP then Option.dwPlayOrder := PLAY_ORDER_REPEAT;
    // �C���W�P�[�^���ĕ`��
    cwWindowMain.PostMessage(WM_APP_MESSAGE, WM_APP_REDRAW, NULL);
end;

procedure ChangeStaticClick();
begin
    // ���\���ؑ�
    if Status.bShiftButton then SetChangeInfo(false, -1)
    else SetChangeInfo(false, 1);
end;

function LostFocusWindow(): longword;
begin
    // ������
    result := 1;
    // �t�H�[�J�X������E�B���h�E���L�^
    if longbool(API_GetFocus()) and (API_GetFocus() <> cwWindowMain.hWnd) then Status.dwFocusHandle := API_GetFocus();
    // Shift �L�[������
    SetChangeFunction(false);
    // Ctrl �L�[������
    Status.bCtrlButton := false;
end;

function GetFocusWindow(): longword;
begin
    // ������
    result := 1;
    // Shift �L�[��ݒ�
    SetChangeFunction(true);
    // �E�B���h�E�Ƀt�H�[�J�X��ݒ�
    if (API_GetForegroundWindow() = cwWindowMain.hWnd) and longbool(Status.dwFocusHandle) then cwWindowMain.PostMessage(WM_APP_MESSAGE, WM_APP_ACTIVATE, NULL);
end;

function TransmitFile(bAutoPlay: longbool): longbool;
var
    lpFile: pointer;
    dwType: longword;
begin
    // ������
    result := false;
    // ���b�Z�[�W �{�b�N�X�\�����̏ꍇ
    if cwWindowMain.bMessageBox then begin
        // ���ɖ߂�
        cwStaticFile.SetCaption(pchar(FILE_DEFAULT));
    end else begin
        // �o�b�t�@���m��
        GetMem(lpFile, 1024);
        // �o�b�t�@��������
        API_ZeroMemory(lpFile, 1024);
        // �t�@�C�������擾
        cwStaticFile.GetCaption(lpFile, 1024);
        // ���ɖ߂�
        cwStaticFile.SetCaption(pchar(FILE_DEFAULT));
        // �t�@�C�����J��
        dwType := GetFileType(lpFile, true, true);
        case dwType of
            FILE_TYPE_SPC: result := SPCLoad(lpFile, bAutoPlay);
            FILE_TYPE_LIST_A, FILE_TYPE_LIST_B: result := ListLoad(lpFile, dwType, false);
            FILE_TYPE_SCRIPT700: result := ReloadScript700(lpFile);
        end;
        // �o�b�t�@�����
        FreeMem(lpFile, 1024);
    end;
end;

procedure GetFocusWindowAfter();
begin
    // �t�H�[�J�X��ݒ�
    if API_GetFocus() = cwWindowMain.hWnd then begin
        API_SetFocus(Status.dwFocusHandle);
        Status.dwFocusHandle := NULL;
    end;
    // ��{�D��x���擾
    Option.dwPriority := API_GetPriorityClass(API_GetCurrentProcess());
    // �펞��O���擾
    Option.bTopMost := longbool(cwWindowMain.GetWindowStyleEx() and WS_EX_TOPMOST);
    // ���j���[���X�V
    UpdateMenu();
end;

procedure RedrawInfo();
begin
    // �N���e�B�J�� �Z�N�V�������J�n
    API_EnterCriticalSection(@CriticalSectionStatic);
    // �ĕ`�悪���b�N����Ă��Ȃ��ꍇ
    if not longbool(Status.dwRedrawInfo and REDRAW_LOCK_CRITICAL) then begin
        // �ĕ`��t���O��ݒ�
        Status.dwRedrawInfo := REDRAW_ON;
        // �C���W�P�[�^���ĕ`��
        if Status.bOpen then WaveProc(WAVE_PROC_GRAPH_ONLY);
        // Break �L�[ �t���O��ݒ�
        Status.bChangeBreak := false;
    end;
    // �N���e�B�J�� �Z�N�V�������I��
    API_LeaveCriticalSection(@CriticalSectionStatic);
end;

procedure ClickSeekBar();
var
    X: longword;
    Y: longword;
begin
    // SPC ���J����Ă��Ȃ��A���t���Ԃ������A�܂��̓^�C���A�E�g�����������ꍇ�͏I��
    if not Status.bOpen or not Option.bPlayTime or not longbool(Status.dwNextTimeout) then exit;
    // �N���b�N�ʒu���擾
    X := lParam and $FFFF;
    Y := lParam shr 16;
    if Status.dwScale <> 2 then begin
        X := Trunc(longint(X shl 1) / Status.dwScale);
        Y := Trunc(longint(Y shl 1) / Status.dwScale);
    end;
    // �N���b�N�ʒu���͈͊O�̏ꍇ�͏I��
    if (X < 140) or (X > 280) or (Y < 27) or (Y >= 32) then exit;
    // �N���b�N�ʒu�̊������擾
    Y := Trunc((X - 139) / 141 * Status.dwDefaultTimeout) + 1;
    if X = 140 then X := 0 else X := Trunc((X - 140) / 141 * Status.dwDefaultTimeout) + 1;
    if X > Status.dwDefaultTimeout then X := Status.dwDefaultTimeout;
    if Y > Status.dwDefaultTimeout then Y := Status.dwDefaultTimeout;
    // ���b�Z�[�W����
    case wParam and $FFFFF000 of
        WM_APP_SEEK: begin
            // �X���b�h�ɃV�[�N��ʒm
            API_PostThreadMessage(Status.dwThreadID, WM_APP_MESSAGE, WM_APP_SPC_SEEK + (longword(not Status.bCtrlButton) and $1), X);
        end;
        WM_APP_START_TIME: begin
            // ���s�[�g�J�n�ʒu��ݒ�
            if X < Status.dwLimitTime then Status.dwStartTime := X
            else Status.dwStartTime := Status.dwLimitTime;
            // �C���W�P�[�^���ĕ`��
            cwWindowMain.PostMessage(WM_APP_MESSAGE, WM_APP_REDRAW, NULL);
        end;
        WM_APP_LIMIT_TIME: begin
            // ���s�[�g�I���ʒu��ݒ�
            if Y > Status.dwStartTime then Status.dwLimitTime := Y
            else Status.dwLimitTime := Status.dwStartTime;
            // �C���W�P�[�^���ĕ`��
            cwWindowMain.PostMessage(WM_APP_MESSAGE, WM_APP_REDRAW, NULL);
        end;
        WM_APP_RESET_TIME: ResetTimeMark();
    end;
end;

procedure SetNextPlay();
var
    dwFlag: longword;
begin
    // SPC ���J����Ă��Ȃ��A�܂��͉��t��~���̏ꍇ�͏I��
    if not Status.bOpen or not Status.bPlay then exit;
    // �E�B���h�E�Ƀt�H�[�J�X���Ȃ��ꍇ�̓J�[�\����I��
    if API_GetForegroundWindow() = cwWindowMain.hWnd then dwFlag := NULL
    else dwFlag := LIST_NEXT_PLAY_SELECT or LIST_NEXT_PLAY_CENTER;
    // ���̋Ȃ��Đ�
    ListNextPlay(Option.dwPlayOrder, dwFlag);
end;

procedure MinimizeWindow();
begin
    // �ŏ�������Ă���ꍇ�͏I��
    if longbool(cwWindowMain.GetWindowStyle() and WS_MINIMIZE) then exit;
    // �t�H�[�J�X���ݒ肳��Ă���E�B���h�E���L�^
    LostFocusWindow();
    // �ŏ���
    cwWindowMain.SetWindowShowStyle(SW_MINIMIZE);
end;

function ReadAPURam(dwAddr: longword): longword;
var
    X: longword;
begin
    // RAM �l�̓ǂݎ��
    API_MoveMemory(@X, pointer(longword(Apu.Ram) or dwAddr), 4);
    result := X;
end;

procedure WriteAPURam(dwAddr: longword; dwVal: longword);
var
    X: longword;
begin
    // RAM �l�̏�������
    for X := 0 to 3 do Apu.SetAPURAM(dwAddr + X, dwVal shr (X shl 3));
end;

function ReadSPCReg(dwAddr: longword): longword;
var
    X: longword;
begin
    // SPC ���W�X�^���擾
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
    // SPC ���W�X�^��ݒ�
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
    // ���t��~���̏ꍇ�͏I��
    if not Status.bEmuDebug or not Status.bPlay then exit;
    // �N���e�B�J�� �Z�N�V�������J�n
    API_EnterCriticalSection(@CriticalSectionThread);
    // �o�b�t�@���m��
    GetMem(lpData, 16);
    // �����G�~�����[�g
    Apu.EmuAPU(lpData, 1, 1);
    // �N���e�B�J�� �Z�N�V�������I��
    API_LeaveCriticalSection(@CriticalSectionThread);
    // �o�b�t�@�����
    FreeMem(lpData, 16);
end;

function WaveOutput(bShift: longbool; bQuiet: longbool): longbool;
var
    lpFile: pointer;
begin
    // ������
    result := false;
    // ���b�Z�[�W �{�b�N�X�\�����̏ꍇ
    if cwWindowMain.bMessageBox then begin
        // ���ɖ߂�
        cwStaticFile.SetCaption(pchar(FILE_DEFAULT));
    end else begin
        // �o�b�t�@���m��
        GetMem(lpFile, 1024);
        // �o�b�t�@��������
        API_ZeroMemory(lpFile, 1024);
        // �t�@�C�������擾
        cwStaticFile.GetCaption(lpFile, 1024);
        // ���ɖ߂�
        cwStaticFile.SetCaption(pchar(FILE_DEFAULT));
        // WAVE �t�@�C����ۑ�
        result := WaveSave(lpFile, bShift, bQuiet);
        // �o�b�t�@�����
        FreeMem(lpFile, 1024);
    end;
end;

begin
    // ������
    result := 0;
    // ���j���[���E�N���b�N���ꂽ�ꍇ�A���b�Z�[�W�����j���[ �N���b�N �C�x���g�ɕϊ�
    if (msg = WM_MENURBUTTONUP) or ((msg = WM_MENUCHAR) and ((wParam and $FFFF) = $20)) then begin
        wParam := Status.dwMenuFlags and $FFFF;
        if not longbool(API_GetMenuState(lParam, wParam, MF_BYCOMMAND) and MF_GRAYED) then begin
            if msg = WM_MENUCHAR then result := $30000 or wParam else result := 0;
            msg := WM_COMMAND;
            lParam := 0;
            dwDef := 1;
        end;
    end;
    // ���b�Z�[�W����
    case msg of
        WM_SYSCOMMAND, WM_COMMAND, WM_APP_COMMAND: begin // �V�X�e�� �R�}���h����
            if (msg = WM_SYSCOMMAND) or (msg = WM_APP_COMMAND) or ((msg = WM_COMMAND) and not longbool(lParam)) then begin // ���j���[���I�����ꂽ
                case wParam of
                    MENU_FILE_OPEN: OpenFile();
                    MENU_FILE_SAVE: SaveFile();
                    MENU_FILE_PLAY, MENU_FILE_PAUSE: SPCPlay(PLAY_TYPE_AUTO);
                    MENU_FILE_RESTART: SPCStop(true);
                    MENU_FILE_STOP: SPCStop(false);
                    MENU_FILE_EXIT: cwWindowMain.PostMessage(WM_QUIT, NULL, NULL);
                    MENU_SETUP_PITCH_ASYNC: Option.bPitchAsync := not Option.bPitchAsync;
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
                        // �t���O��ݒ�
                        Option.bTopMost := not Option.bTopMost;
                        // �E�B���h�E���X�V
                        UpdateWindow();
                    end;
                    MENU_LIST_ADD: ListAdd(1);
                    MENU_LIST_INSERT: ListAdd(2);
                    MENU_LIST_PLAY_SELECT: SPCPlay(PLAY_TYPE_LIST);
                    MENU_LIST_PLAY_BASE..MENU_LIST_PLAY_MAX: ListNextPlay(MENU_LIST_PLAY_VALUE[wParam - MENU_LIST_PLAY_BASE], LIST_NEXT_PLAY_SELECT);
                    MENU_LIST_REMOVE: ListDelete();
                    MENU_LIST_CLEAR: ListClear();
                    MENU_LIST_UP: ListUp();
                    MENU_LIST_DOWN: ListDown();
                    else case wParam div 10 * 10 of
                        MENU_SETUP_DEVICE_BASE..MENU_SETUP_DEVICE_BASE + 90: Option.dwDeviceID := wParam - MENU_SETUP_DEVICE_BASE - 1;
                        MENU_SETUP_CHANNEL_BASE: Option.dwChannel := MENU_SETUP_CHANNEL_VALUE[wParam - MENU_SETUP_CHANNEL_BASE];
                        MENU_SETUP_BIT_BASE: Option.dwBit := MENU_SETUP_BIT_VALUE[wParam - MENU_SETUP_BIT_BASE];
                        MENU_SETUP_RATE_BASE..MENU_SETUP_RATE_BASE + 10: Option.dwRate := MENU_SETUP_RATE_VALUE[wParam - MENU_SETUP_RATE_BASE];
                        MENU_SETUP_INTER_BASE: Option.dwInter := MENU_SETUP_INTER_VALUE[wParam - MENU_SETUP_INTER_BASE];
                        MENU_SETUP_PITCH_BASE..MENU_SETUP_PITCH_BASE + 20: Option.dwPitch := MENU_SETUP_PITCH_VALUE[wParam - MENU_SETUP_PITCH_BASE];
                        MENU_SETUP_SEPARATE_BASE..MENU_SETUP_SEPARATE_BASE + 10: Option.dwSeparate := MENU_SETUP_SEPARATE_VALUE[wParam - MENU_SETUP_SEPARATE_BASE];
                        MENU_SETUP_FEEDBACK_BASE..MENU_SETUP_FEEDBACK_BASE + 10: Option.dwFeedback := MENU_SETUP_FEEDBACK_VALUE[wParam - MENU_SETUP_FEEDBACK_BASE];
                        MENU_SETUP_SPEED_BASE..MENU_SETUP_SPEED_BASE + 10: Option.dwSpeedBas := MENU_SETUP_SPEED_VALUE[wParam - MENU_SETUP_SPEED_BASE];
                        MENU_SETUP_AMP_BASE..MENU_SETUP_AMP_BASE + 10: Option.dwAmp := MENU_SETUP_AMP_VALUE[wParam - MENU_SETUP_AMP_BASE];
                        MENU_SETUP_MUTE_BASE: Option.dwMute := Option.dwMute xor (1 shl (wParam - MENU_SETUP_MUTE_BASE));
                        MENU_SETUP_NOISE_BASE: Option.dwNoise := Option.dwNoise xor (1 shl (wParam - MENU_SETUP_NOISE_BASE));
                        MENU_SETUP_OPTION_BASE..MENU_SETUP_OPTION_BASE + 10: Option.dwOption := Option.dwOption xor MENU_SETUP_OPTION_VALUE[wParam - MENU_SETUP_OPTION_BASE];
                        MENU_SETUP_ORDER_BASE: begin
                            // �t���O��ݒ�
                            Option.dwPlayOrder := wParam - MENU_SETUP_ORDER_BASE;
                            Status.dwPlayOrder := Option.dwPlayOrder;
                            // �C���W�P�[�^���ĕ`��
                            cwWindowMain.PostMessage(WM_APP_MESSAGE, WM_APP_REDRAW, NULL);
                        end;
                        MENU_SETUP_SEEK_BASE: Option.dwSeekTime := MENU_SETUP_SEEK_VALUE[wParam - MENU_SETUP_SEEK_BASE];
                        MENU_SETUP_INFO_BASE: begin
                            SetChangeInfo(true, wParam - MENU_SETUP_INFO_BASE);
                            exit; // UpdateMenu �����s���Ȃ�
                        end;
                        MENU_SETUP_PRIORITY_BASE: begin
                            // �ݒ肷��D��x���擾
                            Option.dwPriority := MENU_SETUP_PRIORITY_VALUE[wParam - MENU_SETUP_PRIORITY_BASE];
                            // �v���Z�X�D��x��ݒ�
                            API_SetPriorityClass(API_GetCurrentProcess(), Option.dwPriority);
                        end;
                    end;
                end;
                case wParam div 100 of
                    2, 10: SPCReset(true); // 2: �`�����l���`���[�g, 10: �f�o�C�X
                    3..5: SPCReset(false); // 3�`5: ��ԏ����`�g���ݒ�
                    6: UpdateMenu();       // 6: ���t���ԁ`��Ɏ�O�ɕ\��
                end;
            end else case (wParam and $FFFF) div ID_BASE of // �q�E�B���h�E���ω�����
                ID_BUTTON: case wParam shr 16 of // �{�^���̏���
                    BN_CLICKED, BN_DBLCLK: case wParam and $FFFF of // �N���b�N�A�_�u���N���b�N���ꂽ
                        ID_BUTTON_OPEN: OpenFile();
                        ID_BUTTON_SAVE: SaveFile();
                        ID_BUTTON_PLAY: SPCPlay(PLAY_TYPE_AUTO);
                        ID_BUTTON_RESTART: SPCStop(true);
                        ID_BUTTON_STOP: SPCStop(false);
                        ID_BUTTON_TRACK_BASE..ID_BUTTON_TRACK_BASE + 7: begin
                            // �`�����l�� �}�X�N��ݒ�
                            Option.dwMute := Option.dwMute xor (1 shl ((wParam and $FFFF) - ID_BUTTON_TRACK_BASE));
                            // �ݒ�����Z�b�g
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
                        ID_BUTTON_CLEAR: ListClear();
                        ID_BUTTON_UP: if Status.bShiftButton then ListNextPlay(PLAY_ORDER_PREVIOUS, LIST_NEXT_PLAY_SELECT)
                            else ListUp();
                        ID_BUTTON_DOWN: if Status.bShiftButton then ListNextPlay(PLAY_ORDER_NEXT, LIST_NEXT_PLAY_SELECT)
                            else ListDown();
                    end;
                end;
                ID_LISTBOX: case wParam shr 16 of // �v���C���X�g�̏���
                    LBN_SELCHANGE: case wParam and $FFFF of // �I�����ꂽ
                        ID_LIST_PLAY: UpdateMenu();
                    end;
                    LBN_DBLCLK: case wParam and $FFFF of // �_�u���N���b�N���ꂽ
                        ID_LIST_PLAY: SPCPlay(PLAY_TYPE_LIST);
                    end;
                end;
                ID_STATIC: case wParam shr 16 of // �X�^�e�B�b�N�̏���
                    STN_DBLCLK: case wParam and $FFFF of // �_�u���N���b�N���ꂽ
                        ID_STATIC_MAIN: ChangeStaticClick();
                    end;
                end;
            end;
        end;
        WM_DROPFILES: dwDef := DropFile(wParam); // �t�@�C�����h���b�v���ꂽ
        WM_CAPTURECHANGED: dwDef := LostFocusWindow(); // �}�E�X�̃L���v�`�����ω�����
        WM_ACTIVATE: case wParam and $FFFF of // �E�B���h�E�̃A�N�e�B�u���ω�����
            0: dwDef := LostFocusWindow(); // �E�B���h�E����t�H�[�J�X�����ꂽ
            1, 2: dwDef := GetFocusWindow(); // �E�B���h�E�Ƀt�H�[�J�X���ڂ���
        end;
        WM_SIZE: if longbool(Status.dwTitle) then begin // �T�C�Y���ύX���ꂽ
            if wParam = $FFFFFFFF then dwDef := 1;
            // �t���O��ݒ�
            Status.dwTitle := Status.dwTitle and not TITLE_ALWAYS_FLAG;
            if longbool(cwWindowMain.GetWindowStyle() and WS_MINIMIZE) then Status.dwTitle := Status.dwTitle or TITLE_MINIMIZE
            else Status.dwTitle := Status.dwTitle or TITLE_NORMAL;
            if longbool(cwWindowMain.GetWindowStyle() and WS_MAXIMIZE) then cwWindowMain.SetWindowShowStyle(SW_SHOWNORMAL);
            // �ŏ������ꂽ�ꍇ�̓C���W�P�[�^�����Z�b�g
            if longbool(Status.dwTitle and TITLE_MINIMIZE) then ResetInfo(false);
            // �^�C�g�����X�V
            UpdateTitle(NULL);
        end;
        WM_MENUSELECT: Status.dwMenuFlags := wParam; // ���j���[���I�����ꂽ
        WM_EXITSIZEMOVE: if longbool(Status.dwTitle) then MoveWindowScreenSide(); // �E�B���h�E���ړ�����
        WM_APP_MESSAGE: begin // ���[�U�[��`
            // ������
            dwDef := 1;
            // ���b�Z�[�W����
            case wParam and $FFFF0000 of
                WM_APP_TRANSMIT: result := longword(TransmitFile(longbool(wParam and $1))); // �t�@�C�������]������Ă���
                WM_APP_ACTIVATE: GetFocusWindowAfter(); // �E�B���h�E�Ƀt�H�[�J�X���ڂ���
                WM_APP_REDRAW: RedrawInfo(); // �ĕ`��̕K�v��������
                WM_APP_SEEK, WM_APP_REPEAT_TIME: ClickSeekBar(); // �V�[�N�̕K�v���������A���s�[�g�ʒu���ύX���ꂽ
                WM_APP_NEXT_PLAY: SetNextPlay(); // ���̋Ȃ����t
                WM_APP_MINIMIZE: MinimizeWindow(); // �ŏ������v�����ꂽ
                WM_APP_WAVE_PROC: Inc(Status.dwWaveMessage); // WAVE ���荞��
                WM_APP_FUNCTION: SetFunction((wParam and $2) - 1, lParam); // �@�\�ݒ�
                WM_APP_GET_DSP, WM_APP_SET_DSP: begin // DSP �ǂݎ��E��������
                    // �N���e�B�J�� �Z�N�V�������J�n
                    API_EnterCriticalSection(@CriticalSectionThread);
                    // DSP ���W�X�^
                    result := Apu.DspReg.Reg[wParam and $7F];
                    if longbool(wParam and $10000) then Apu.SetDSPReg(byte(wParam), byte(lParam));
                    // �N���e�B�J�� �Z�N�V�������I��
                    API_LeaveCriticalSection(@CriticalSectionThread);
                end;
                WM_APP_GET_PORT, WM_APP_SET_PORT: begin // I/O �|�[�g�ǂݎ��E��������
                    // �N���e�B�J�� �Z�N�V�������J�n
                    API_EnterCriticalSection(@CriticalSectionThread);
                    // I/O �|�[�g
                    result := Apu.SPCOutPort.Port[wParam and $3];
                    if longbool(wParam and $10000) then Apu.InPort(byte(wParam), byte(lParam));
                    // �N���e�B�J�� �Z�N�V�������I��
                    API_LeaveCriticalSection(@CriticalSectionThread);
                end;
                WM_APP_GET_RAM, WM_APP_SET_RAM: begin // RAM �ǂݎ��E��������
                    // �N���e�B�J�� �Z�N�V�������J�n
                    API_EnterCriticalSection(@CriticalSectionThread);
                    // APU RAM
                    result := ReadAPURam(wParam and $FFFF);
                    if longbool(wParam and $10000) then WriteAPURam(wParam and $FFFF, lParam);
                    // �N���e�B�J�� �Z�N�V�������I��
                    API_LeaveCriticalSection(@CriticalSectionThread);
                end;
                WM_APP_GET_WORK, WM_APP_SET_WORK: begin // ���[�N�ǂݎ��E��������
                    result := Status.Script700.Data.dwWork[wParam and $7];
                    if longbool(wParam and $10000) then Status.Script700.Data.dwWork[wParam and $7] := lParam;
                end;
                WM_APP_GET_CMP, WM_APP_SET_CMP: begin // ��r�l�ǂݎ��E��������
                    result := Status.Script700.Data.dwCmpParam[wParam and $1];
                    if longbool(wParam and $10000) then Status.Script700.Data.dwCmpParam[wParam and $1] := lParam;
                end;
                WM_APP_GET_SPC, WM_APP_SET_SPC: begin // SPC �ǂݎ��E��������
                    // �N���e�B�J�� �Z�N�V�������J�n
                    API_EnterCriticalSection(@CriticalSectionThread);
                    // SPC ���W�X�^
                    result := ReadSPCReg(wParam and $FFFF);
                    if longbool(wParam and $10000) then WriteSPCReg(wParam and $FFFF, lParam);
                    // �N���e�B�J�� �Z�N�V�������I��
                    API_LeaveCriticalSection(@CriticalSectionThread);
                end;
                WM_APP_HALT: begin // HALT �X�C�b�`
                    // �N���e�B�J�� �Z�N�V�������J�n
                    API_EnterCriticalSection(@CriticalSectionThread);
                    // HALT �X�C�b�`
                    Apu.SetSPCDbg(pointer(longword(-1)), lParam and $2F);
                    // �N���e�B�J�� �Z�N�V�������I��
                    API_LeaveCriticalSection(@CriticalSectionThread);
                end;
                WM_APP_BP_SET, WM_APP_BP_CLEAR: begin // BreakPoint �ݒ�E�S����
                    // �N���e�B�J�� �Z�N�V�������J�n
                    API_EnterCriticalSection(@CriticalSectionThread);
                    // �R�[���o�b�N��ǉ��ݒ�
                    Apu.SNESAPUCallback(@_SNESAPUCallback, CBE_S700FCH);
                    // BreakPoint �ݒ�
                    if longbool(wParam and $10000) then API_ZeroMemory(@Status.BreakPoint, 65536)
                    else Status.BreakPoint[wParam and $FFFF] := lParam and $FF;
                    // �N���e�B�J�� �Z�N�V�������I��
                    API_LeaveCriticalSection(@CriticalSectionThread);
                end;
                WM_APP_NEXT_TICK: begin // ���̖��߂Ŏ~�߂�
                    // �N���e�B�J�� �Z�N�V�������J�n
                    API_EnterCriticalSection(@CriticalSectionThread);
                    // ���̖��ߎ��s�X�C�b�`
                    if longbool(lParam) then Status.dwNextTick := (lParam and $FF) or BRKP_NEXT_STOP
                    else Status.dwNextTick := BRKP_RELEASE;
                    // �N���e�B�J�� �Z�N�V�������I��
                    API_LeaveCriticalSection(@CriticalSectionThread);
                end;
                WM_APP_DSP_CHEAT, WM_APP_DSP_THRU: begin // DSP �`�[�g�ݒ�E�S����
                    // �N���e�B�J�� �Z�N�V�������J�n
                    API_EnterCriticalSection(@CriticalSectionThread);
                    // �R�[���o�b�N��ǉ��ݒ�
                    Apu.SNESAPUCallback(@_SNESAPUCallback, CBE_DSPREG);
                    // DSP �`�[�g�ݒ�
                    if longbool(wParam and $10000) then API_ZeroMemory(@Status.DSPCheat, 256)
                    else if lParam >= $100 then Status.DSPCheat[wParam and $7F] := 0
                    else Status.DSPCheat[wParam and $7F] := (lParam and $FF) or $100;
                    // �N���e�B�J�� �Z�N�V�������I��
                    API_LeaveCriticalSection(@CriticalSectionThread);
                end;
                WM_APP_STATUS: result := (longword(Status.bOpen) and STATUS_OPEN) or (longword(Status.bPlay) and STATUS_PLAY) or (longword(Status.bPause) and STATUS_PAUSE); // �X�e�[�^�X�擾
                WM_APP_APPVER: result := APPLINK_VERSION; // �o�[�W�����擾
                WM_APP_EMU_APU: ForceEmuAPU(); // �����G�~�����[�g
                WM_APP_EMU_DEBUG: Status.bEmuDebug := longbool(wParam and $1); // SPC700 �]���e�X�g
                WM_APP_DRAG_DONE: Status.bDropCancel := false; // �h���b�O�I��
                WM_APP_UPDATE_INFO: UpdateInfo(longbool(wParam and $1)); // �����X�V
                WM_APP_UPDATE_MENU: UpdateMenu(); // ���j���[���X�V
                WM_APP_WAVE_OUTPUT: result := longword(WaveOutput(longbool(wParam and $1), longbool(wParam and $2))); // WAVE ��������
            end;
        end;
        WM_TIMER: case wParam of // �^�C�}�[
            TIMER_ID_TITLE_INFO: begin // ���\������
                // �t���O��ݒ�
                Status.dwTitle := Status.dwTitle and TITLE_ALWAYS_FLAG;
                // �^�C�}�[������
                API_KillTimer(cwWindowMain.hWnd, TIMER_ID_TITLE_INFO);
                // �^�C�g�����X�V
                UpdateTitle(NULL);
            end;
            TIMER_ID_OPTION_LOCK: begin // �I�v�V���� ���b�N����
                // �^�C�}�[������
                if Status.bOptionLock then API_KillTimer(cwWindowMain.hWnd, TIMER_ID_OPTION_LOCK);
                // �I�v�V�����ݒ胍�b�N������
                Status.bOptionLock := false;
            end;
        end;
        WM_ENDSESSION: if longbool(wParam) then DeleteWindow(); // �Z�b�V�������I�� (Windows �����O�I�t�A�ċN���A�V���b�g�_�E��) ����
        WM_POWERBROADCAST: case wParam of // Windows �̓d���Ǘ���Ԃ��ω�����
            $4, $5: SPCStop(false); // Windows ���T�X�y���h�A�x�~��Ԃɓ��낤�Ƃ���
        end;
        WM_SYSCOLORCHANGE: begin // �V�X�e�� �J���[�ݒ肪�ω�����
            // �N���e�B�J�� �Z�N�V�������J�n
            API_EnterCriticalSection(@CriticalSectionStatic);
            // �O���t�B�b�N ���\�[�X��ݒ�
            SetGraphic();
            // �N���e�B�J�� �Z�N�V�������I��
            API_LeaveCriticalSection(@CriticalSectionStatic);
            // �C���W�P�[�^���ĕ`��
            cwWindowMain.PostMessage(WM_APP_MESSAGE, WM_APP_REDRAW, NULL);
        end;
        WM_CLOSE: if hWnd = cwWindowMain.hWnd then begin // Windows ���E�B���h�E�����
            // ������
            dwDef := 1;
            // �I�����b�Z�[�W�𑗐M
            cwWindowMain.PostMessage(WM_QUIT, NULL, NULL);
        end;
    end;
end;


// *************************************************************************************************************************************************************
// �G���g���[ �|�C���g
// *************************************************************************************************************************************************************

begin
{$WARNINGS OFF} // �R���p�C���x�����b�Z�[�W�Ȃ� --- ��������
    ExitCode := longint(_WinMain(hInstance, hPrevInst, cmdLine, cmdShow));
{$WARNINGS ON}  // �R���p�C���x�����b�Z�[�W�Ȃ� --- �����܂�
end.
