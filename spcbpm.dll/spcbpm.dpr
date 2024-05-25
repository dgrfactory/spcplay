// *************************************************************************************************************************************************************
//   BPM Analyzer for SNESAPU.DLL
// *************************************************************************************************************************************************************

library spcbpm;

//{$DEFINE FORCEDSPDBG}                                     // DSPDbg API �������g�p

{$APPTYPE GUI}                                              // �A�v���P�[�V�����^�C�v       : GUI ���[�h
{$ASSERTIONS OFF}                                           // �\�[�X�R�[�h�̃A�T�[�g       : ����
{$BOOLEVAL OFF}                                             // ���S�_�����]��               : ����
{$DEBUGINFO OFF}                                            // �f�o�b�O���                 : ����
{$DENYPACKAGEUNIT ON}                                       // UNIT �s�g�p                  : �L��
{$EXTENDEDSYNTAX ON}                                        // �֐��̖߂�l�𖳎��\       : �L��
{$EXTENSION 'dll'}                                          // �g���q�ݒ�                   : DLL
{$IMAGEBASE $00400000}                                      // �C���[�W�x�[�X�A�h���X       : 0x00400000
{$IMPORTEDDATA OFF}                                         // �ʃp�b�P�[�W�̃������Q��     : ����
{$IOCHECKS OFF}                                             // I/O �`�F�b�N                 : ����
{$LONGSTRINGS ON}                                           // AnsiString �g�p              : �L��
{$MAXSTACKSIZE $00100000}                                   // �ő�X�^�b�N�ݒ�             : 0x00100000
{$MINENUMSIZE 1}                                            // �񋓌^�̍ő�T�C�Y (x256)    : 1 (256)
{$MINSTACKSIZE $00004000}                                   // �ŏ��X�^�b�N�ݒ�             : 0x00004000
{$OPENSTRINGS OFF}                                          // �I�[�v��������p�����[�^     : ����
{$OVERFLOWCHECKS OFF}                                       // �I�[�o�[�t���[�`�F�b�N       : ����
{$RANGECHECKS OFF}                                          // �͈̓`�F�b�N                 : ����
{$R 'spcbpm.res' 'spcbpm.rc'}                               // ���\�[�X                     : spcbpm.res <- spcbpm.rc
{$STACKFRAMES OFF}                                          // ���S�X�^�b�N�t���[������     : ����
{$TYPEDADDRESS OFF}                                         // �|�C���^�̌^�`�F�b�N         : ����
{$TYPEINFO OFF}                                             // ���s���^���                 : ����
{$VARSTRINGCHECKS OFF}                                      // ������`�F�b�N               : ����
{$WARNINGS ON}                                              // �x������                     : �L��
{$WEAKPACKAGEUNIT OFF}                                      // �ア�p�b�P�[�W��             : ����
{$WRITEABLECONST OFF}                                       // �萔��������                 : ����

{$IFDEF FREEPASCAL}     // for Free Pascal 3.2+
{$CALLING STDCALL}                                          // CALL �X�^�b�N����            : STDCALL
{$CHECKPOINTER OFF}                                         // �|�C���^�`�F�b�N             : ����
{$FPUTYPE x87}                                              // �����������Z����             : x87
{$HINTS OFF}                                                // �q���g����                   : ����
{$IEEEERRORS OFF}                                           // ���������G���[�`�F�b�N       : ����
{$MODE delphi}                                              // ���ꃂ�[�h                   : delphi
{$OPTIMIZATION LEVEL3,USEEBP}                               // �œK���R���p�C��             : Lv3, EBP ���W�X�^�g�p
{$POINTERMATH ON}                                           // �|�C���^���Z                 : �L��
{$SAFEFPUEXCEPTIONS OFF}                                    // FPU �G���[������           : ����
{$ELSE}                 // for Boland Delphi 6+
{$DEFINITIONINFO OFF}                                       // �V���{���錾�ƎQ�Ə��       : ����
{$DESIGNONLY OFF}                                           // IDE �g�p                     : ����
{$HINTS ON}                                                 // �q���g����                   : �L��
{$IMPLICITBUILD ON}                                         // �r���h�̂��тɍăR���p�C��   : �L��
{$LOCALSYMBOLS OFF}                                         // ���[�J���V���{�����         : ����
{$OBJEXPORTALL OFF}                                         // �V���{���̃G�N�X�|�[�g       : ����
{$OPTIMIZATION ON}                                          // �œK���R���p�C��             : �L��
{$REALCOMPATIBILITY OFF}                                    // Real48 �݊�                  : ����
{$REFERENCEINFO OFF}                                        // ���S�ȎQ�Ə��̐���         : ����
{$RUNONLY OFF}                                              // ���s���̂݃R���p�C��         : ����
{$SAFEDIVIDE OFF}                                           // ���� Pentium FDIV �o�O���   : ����
{$ENDIF}


// *************************************************************************************************************************************************************
// �O���N���X�̐錾
// *************************************************************************************************************************************************************

//uses MemCheck in '..\..\memcheck\MemCheck.pas';


// *************************************************************************************************************************************************************
// �\���́A����уN���X�̐錾
// *************************************************************************************************************************************************************

type
{$ALIGN OFF} // �\���̂̎����T�C�Y�����Ȃ� --- ��������
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
        1: (Voice: array[0..7] of TDSPVOICE);               // �{�C�X���W�X�^ (DSPVOICE x8)
        2: (__r00: array[0..11] of byte;                    // (�\��) = DSPVOICE
            MainVolumeLeft: byte;                           // �}�X�^�[���� (��)
            EchoFeedback: byte;                             // �G�R�[�t�B�[�h�o�b�N�̋���
            __r0E: byte;                                    // (���g�p)
            __r0F: byte;                                    // (�\��) = DSPVOICE
            __r10: array[0..11] of byte;                    // (�\��) = DSPVOICE
            MainVolumeRight: byte;                          // �}�X�^�[���� (�E)
            __r1D: byte;                                    // (���g�p)
            __r1E: byte;                                    // (���g�p)
            __r1F: byte;                                    // (�\��) = DSPVOICE
            __r20: array[0..11] of byte;                    // (�\��) = DSPVOICE
            EchoVolumeLeft: byte;                           // �G�R�[���� (��)
            PitchModOn: byte;                               // �e�`�����l���̃s�b�`���W�����[�V�����̃I���t���O (8 �r�b�g)
            __r2E: byte;                                    // (���g�p)
            __r2F: byte;                                    // (�\��) = DSPVOICE
            __r30: array[0..11] of byte;                    // (�\��) = DSPVOICE
            EchoVolumeRight: byte;                          // �G�R�[���� (�E)
            NoiseOn: byte;                                  // �e�`�����l���̃m�C�Y�̃I���t���O (8 �r�b�g)
            __r3E: byte;                                    // (���g�p)
            __r3F: byte;                                    // (�\��) = DSPVOICE
            __r40: array[0..11] of byte;                    // (�\��) = DSPVOICE
            KeyOn: byte;                                    // �e�`�����l���̃L�[�̃I���t���O (8 �r�b�g)
            EchoOn: byte;                                   // �e�`�����l���̃G�R�[�̃I���t���O (8 �r�b�g)
            __r4E: byte;                                    // (���g�p)
            __r4F: byte;                                    // (�\��) = DSPVOICE
            __r50: array[0..11] of byte;                    // (�\��) = DSPVOICE
            KeyOff: byte;                                   // �e�`�����l���̃L�[�̃I�t�t���O (8 �r�b�g)
            SourceDirectory: byte;                          // �\�[�X�f�B���N�g�� (�g�`��񂪊i�[����Ă��郁�����̃I�t�Z�b�g�A�h���X x0x100)
            __r5E: byte;                                    // (���g�p)
            __r5F: byte;                                    // (�\��) = DSPVOICE
            __r60: array[0..11] of byte;                    // (�\��) = DSPVOICE
            Flags: byte;                                    // DSP ���Z�b�g�A�o�͖����A�G�R�[�����t���O (��� 3 �r�b�g) �ƃm�C�Y���g�� (���� 5 �r�b�g)
            EchoWaveform: byte;                             // �G�R�[�L���̈� (�G�R�[�����Ɏg�p���郁�����̃I�t�Z�b�g�A�h���X x0x100)
            __r6E: byte;                                    // (���g�p)
            __r6F: byte;                                    // (�\��) = DSPVOICE
            __r70: array[0..11] of byte;                    // (�\��) = DSPVOICE
            EndWaveform: byte;                              // �e�`�����l���̔g�`�t�H�[���̏I���_�ʉ߃t���O (8 �r�b�g)
            EchoDelay: byte;                                // �G�R�[�f�B���C���� (x16 [ms])
            __r7E: byte;                                    // (���g�p)
            __r7F: byte);                                   // (�\��) = DSPVOICE
        3: (Reg: array[0..127] of byte);                    // DSP ���W�X�^
    end;
{$ALIGN ON}  // �\���̂̎����T�C�Y�����Ȃ� --- �����܂�

    // APU �\����
    TAPU = record
        T64Count: ^longword;                                // 64kHz �^�C�}�J�E���^�̃|�C���^ (64000 count/sec)
        DspReg: ^TDSPREG;                                   // DSP ���W�X�^�̃|�C���^ (128 �o�C�g)
        GetAPUData: procedure(ppRam: pointer; ppXRam: pointer; ppSPCOutput: pointer; ppT64Count: pointer; ppDsp: pointer; ppVoices: pointer;
            ppVolumeMaxLeft: pointer; ppVolumeMaxRight: pointer); stdcall;
        SNESAPUCallback: function(pCbFunc: pointer; cbMask: longword): pointer; stdcall;
        SNESAPUCallbackProc: function(dwEffect: longword; dwAddr: longword; dwValue: longword; lpData: pointer): longword; stdcall;
        SetDSPDbg: function(pDSPDbg: pointer): pointer; stdcall;
        DSPDebug: procedure(); stdcall;
    end;

    // TEMPOHISTORY �\����
    TTEMPOHISTORY = record case byte of
        1: (cChannel: byte;                                 // �`�����l���ԍ�
            cSource: byte;                                  // ���F�ԍ�
            cVolume: byte;                                  // ����
            __r1: byte;                                     // (���g�p)
            wPitch: word;                                   // �s�b�`
            __r2: byte;                                     // (���g�p)
            __r3: byte);                                    // (���g�p)
        2: (qwHash: int64);                                 // �^���n�b�V���l
    end;

    // TEMPO �\����
    TTEMPO = record
        bDisable: bytebool;                                 // �����t���O
        cBPM: byte;                                         // �m��e���|
        cMinBPM: byte;                                      // �e���|��͔͈� (�ŏ�)
        cMaxBPM: byte;                                      // �e���|��͔͈� (�ő�)
        cMode: byte;                                        // �e���|�������[�h (�M���x)
        cKOn: byte;                                         // KON �t���O
        cKOnCount: byte;                                    // KON �J�E���^
        cKOnCountOld: byte;                                 // KON �J�E���^ (�O��̒l)
        dwStartTime: longword;                              // ��͊J�n���� (64kHz)
        dwKOnTime: longword;                                // KON �Ԋu��͗p���� (64kHz)
        dwMinTime: longword;                                // �ŏ��e���|��͗p���� (64kHz)
        dwMaxTime: longword;                                // �ő�e���|��͗p���� (64kHz)
        dwTripleTime: longword;                             // �O���q�E�O�A���l������ (64kHz)
        Count: array[60..200] of longword;                  // �e���|���Ƃ̃J�E���^
        T64Count: array[0..7] of longword;                  // �`�����l�����Ƃ̑O�񔭉����� (64kHz)
        Volume: array[0..7] of byte;                        // �`�����l�����Ƃ̉���
        dwHistory: longword;                                // ����ԍ�
        History: array[0..15] of TTEMPOHISTORY              // ����
    end;


// *************************************************************************************************************************************************************
// �萔�̐錾
// *************************************************************************************************************************************************************

const
    // Delphi �W���萔
    NULL = 0;                                               // �k��
    NULLCHAR = #0;                                          // �k������
    NULLPOINTER = nil;                                      // �k���|�C���^

    CBE_DSPREG = $1;


// *************************************************************************************************************************************************************
// �O���[�o���ϐ��̐錾
// *************************************************************************************************************************************************************

var
    Apu: TAPU;                                              // APU
    Status: record                                          // �X�e�[�^�X
        bInitialized: longbool;                                 // �������ς�
        Tempo: TTEMPO;                                          // �e���|
    end;
    Option: record                                          // �I�v�V����
        bBPM: longbool;                                         // �e���|���
    end;


// *************************************************************************************************************************************************************
// Win32 API �̐錾
// *************************************************************************************************************************************************************

function  API_GetProcAddress(hModule: longword; lpProcName: pointer): pointer; stdcall; external 'kernel32.dll' name 'GetProcAddress';
procedure API_MoveMemory(Destination: pointer; Source: pointer; Length: longword); stdcall; external 'kernel32.dll' name 'RtlMoveMemory';
procedure API_ZeroMemory(Destination: pointer; Length: longword); stdcall; external 'kernel32.dll' name 'RtlZeroMemory';


// *************************************************************************************************************************************************************
// ���C���v���V�[�W��
// *************************************************************************************************************************************************************

// ================================================================================
// AnalyzeTempo - �e���|�̐���
// ================================================================================
procedure AnalyzeTempo(dwValue: longword);
var
    I: longint;
    cKOn: byte;
    cEnable: byte;
    cValue: byte;
    cBPM1: byte;
    cBPM2: byte;
    dwBPM: longword;
    dwScan1: longint;
    dwScan2: longword;
    dwCount1: longword;
    dwCount2: longword;
    dwCount3: longword;
    T64Count: longword;
    Tempo: ^TTEMPO;
    DspVoice: ^TDSPVOICE;
    History: TTEMPOHISTORY;
begin
    // �e���|��͂������ȏꍇ�͏I��
    Tempo := @Status.Tempo;
    if Tempo.bDisable then exit;
    // �V���� KON ���ꂽ�`�����l�����擾
    cKOn := dwValue;
    cEnable := (cKOn xor Tempo.cKOn) and cKOn;
    Tempo.cKOn := cKOn;
    // �V���� KON ���ꂽ�`�����l�����Ȃ��ꍇ�͏I��
    if not bytebool(cEnable) then exit;
    // �e�`�����l���̍ő剹�ʂ��擾
    T64Count := Apu.T64Count^;
    cKOn := 1;
    for I := 0 to 7 do begin
        if bytebool(cEnable and cKOn) then begin
            // ���ω��ʂ��擾
            DspVoice := @Apu.DspReg.Voice[I];
            dwScan2 := Abs(shortint(DspVoice.VolumeLeft)) + Abs(shortint(DspVoice.VolumeRight));
            cValue := (dwScan2 shr 1) + (dwScan2 and 1);
            Tempo.Volume[I] := cValue;
            // �����������L�^
            if bytebool(cValue) then begin
                History.cChannel := I;
                History.cSource := DspVoice.SoundSourcePlayBack;
                History.cVolume := cValue;
                History.wPitch := DspVoice.Pitch;
                Tempo.History[Tempo.dwHistory].qwHash := History.qwHash;
                Tempo.dwHistory := (Tempo.dwHistory + 1) and 15;
            // ���������O
            end else cEnable := cEnable xor cKOn;
        end;
        Inc(cKOn, cKOn);
    end;
    // ��͑Ώۂ̃`�����l�����Ȃ��ꍇ�͏I��
    if not bytebool(cEnable) then exit;
    // �e�`�����l���̎��Ԑ������擾
    cKOn := 1;
    for I := 0 to 7 do begin
        if bytebool(cEnable and cKOn) then begin
            // �O�� KON �̎��ԍ�������e���|���v�Z
            dwCount1 := Tempo.T64Count[I];
            if longbool(dwCount1) then begin
                dwBPM := T64Count - dwCount1;
                if longbool(dwBPM) then dwBPM := 7680000 div dwBPM; // 60(bpm) * 64000(1sec) * 2
                // �d�݂Â�
                if (dwBPM >= 521) and (dwBPM <= 800) then Inc(Tempo.Count[(dwBPM shr 2) + ((dwBPM shr 1) and 1)]);
                if (dwBPM >= 240) and (dwBPM <= 520) then Inc(Tempo.Count[(dwBPM shr 2) + ((dwBPM shr 1) and 1)], 2);
                if (dwBPM >= 261) and (dwBPM <= 400) then Inc(Tempo.Count[(dwBPM shr 1) + (dwBPM and 1)], 2);
                if (dwBPM >= 120) and (dwBPM <= 260) then Inc(Tempo.Count[(dwBPM shr 1) + (dwBPM and 1)], 3);
                if (dwBPM >= 131) and (dwBPM <= 200) then Inc(Tempo.Count[dwBPM], 3);
                if (dwBPM >=  60) and (dwBPM <= 130) then Inc(Tempo.Count[dwBPM], 4);
                if (dwBPM >=  66) and (dwBPM <= 100) then Inc(Tempo.Count[dwBPM + dwBPM], 4);
                if (dwBPM >=  30) and (dwBPM <=  65) then Inc(Tempo.Count[dwBPM + dwBPM], 5);
            end;
            Tempo.T64Count[I] := T64Count;
            // �^���G�R�[�����O
            DspVoice := @Apu.DspReg.Voice[I];
            for dwCount1 := 0 to 15 do begin
                History.qwHash := Tempo.History[dwCount1].qwHash;
                if History.cChannel = I then continue;
                if History.cSource <> DspVoice.SoundSourcePlayBack then continue;
                if History.cVolume <= Tempo.Volume[I] then continue;
                if Abs(smallint(History.wPitch - DspVoice.Pitch)) >= 80 then continue;
                cEnable := cEnable xor cKOn;
                break;
            end;
        end;
        Inc(cKOn, cKOn);
    end;
    // ��͑Ώۂ̃`�����l�����Ȃ��ꍇ�͏I��
    if not bytebool(cEnable) then exit;
    // ��͊�ƂȂ�e���|�͈̔͂��v�Z
    dwCount3 := T64Count - Tempo.dwKOnTime;
    if dwCount3 >= 4800 then begin // 75ms (max 800bpm)
        // KON �����J�E���g
        Tempo.dwKOnTime := T64Count;
        Inc(Tempo.cKOnCount);
        // �ȑS�̂̃e���|���v�Z
        dwBPM := 7680000 div dwCount3; // 60(bpm) * 64000(1sec) * 2
        dwBPM := (dwBPM shr 1) + (dwBPM and 1);
        while longbool(dwBPM) and (dwBPM <= 56) do Inc(dwBPM, dwBPM);
        while longbool(dwBPM) and (dwBPM >= 204) do dwBPM := dwBPM shr 1;
        if dwBPM < 60 then dwBPM := 60;
        if dwBPM > 200 then dwBPM := 200;
        // �ŏ��e���|���v�Z
        if dwBPM <= 70 then dwCount1 := 64 else dwCount1 := dwBPM - 6;
        if bytebool(Tempo.cMinBPM) then begin
            dwScan2 := Tempo.cMinBPM;
            if (dwCount1 <= dwScan2) or ((T64Count - Tempo.dwMinTime) >= 480000) then Tempo.dwMinTime := T64Count // 7.5sec
            else dwCount1 := dwScan2 + 1;
        end;
        // �ő�e���|���v�Z
        if dwCount1 >= 184 then if dwBPM >= 194 then dwCount2 := 200 else dwCount2 := dwBPM + 6
        else if dwBPM >= 190 then dwCount2 := 196 else dwCount2 := dwBPM + 6;
        if bytebool(Tempo.cMaxBPM) then begin
            dwScan2 := Tempo.cMaxBPM;
            if (dwCount2 >= dwScan2) or ((T64Count - Tempo.dwMaxTime) >= 320000) then Tempo.dwMaxTime := T64Count // 5sec
            else dwCount2 := dwScan2 - (Tempo.cKOnCount and 1);
        end;
        if dwCount2 <= 76 then dwCount1 := 60;
        // ��͊�͈͂��m��
        Tempo.cMinBPM := dwCount1;
        Tempo.cMaxBPM := dwCount2;
    end else begin
        // ��͊�͈͂�������̏ꍇ�́A���ݒ�
        if not bytebool(Tempo.cMinBPM) then Tempo.cMinBPM := 120;
        if not bytebool(Tempo.cMaxBPM) then Tempo.cMaxBPM := 140;
        dwCount1 := Tempo.cMinBPM;
        dwCount2 := Tempo.cMaxBPM;
    end;
    // ��͊J�n����K�莞�Ԃ��o�߂��Ă��Ȃ��ꍇ�͏I��
    dwScan2 := T64Count - Tempo.dwStartTime;
    if dwScan2 < 64000 then exit; // 1sec
    // ��͊�͈͂�␳
    cEnable := $31; // 1-4
    if dwCount2 >= 140 then begin
        cValue := ((dwCount2 * 6553) shr 16) - (longword(dwCount2 >= 170) and 1) - 4; // max * 0.1 - (4 or 5)
        if not bytebool(Tempo.cKOnCountOld) and (Tempo.cKOnCount <= cValue) then begin
            // �����͎��ɔ����񐔂����Ȃ��ꍇ�A�ŏ��e���|�̊�͈͂� 1/2 �ɐݒ�
            dwCount1 := dwCount1 shr 1;
            if dwCount1 < 64 then dwCount1 := 64;
            cEnable := $41; // A-D
        end else if bytebool(Tempo.cKOnCountOld) and (Tempo.cKOnCountOld <= cValue) then begin
            // �O���͎��ɔ����񐔂����Ȃ��ꍇ�A�ŏ��E�ő�e���|�̊�͈͂� 1/2 �ɐݒ�
            dwCount1 := dwCount1 shr 1;
            dwCount2 := (dwCount2 shr 1) + 3; // min 73
            if dwCount1 < 64 then dwCount1 := 64;
            if dwCount2 < 127 then dwCount2 := 127;
            cEnable := $41; // A-D
        end else if dwCount1 <= (Tempo.cBPM + 12) then begin
            // �ŏ��e���|�̊�͈͂̍ő�l���A���ݒl�̏�����O�ɐݒ�
            dwBPM := Tempo.cBPM - 2;
            if dwCount1 > dwBPM then begin
                dwCount1 := dwBPM;
                if dwCount1 < 64 then dwCount1 := 64;
                cEnable := $35; // 5-8
            end;
        end;
    end;
    // ��͊�͈͓��ŏo���񐔂��ł������e���|���擾
    dwScan1 := 0;
    dwScan2 := 0;
    cBPM1 := dwCount1;
    cBPM2 := dwCount2;
    for I := dwCount1 to dwCount2 do begin
        dwCount3 := Tempo.Count[I];
        if dwScan2 < dwCount3 then begin
            dwScan1 := I;
            dwScan2 := dwCount3;
            Tempo.cMode := cEnable;
        end;
    end;
    // �e���|�̕��ϒl���v�Z���Ē����l��␳
    dwScan2 := dwScan1;
    Dec(dwScan1, 5);
    Inc(dwScan2, 5);
    if dwScan1 < 60 then dwScan1 := 60;
    if dwScan2 > 200 then dwScan2 := 200;
    dwBPM := 0;
    dwCount1 := 0;
    for I := dwScan1 to dwScan2 do begin
        dwCount3 := Tempo.Count[I];
        Inc(dwBPM, longword(I + I) * dwCount3);
        Inc(dwCount1, dwCount3);
    end;
    if longbool(dwCount1) then begin
        dwBPM := dwBPM div dwCount1;
        dwBPM := (dwBPM shr 1) + (dwBPM and 1);
    end;
    // �O���q�E�O�A�����l�����Ē����l��␳
    if (dwBPM >= 96) and ((dwBPM <= 128) or (dwBPM >= 176)) and (dwCount1 >= 16) then begin
        dwScan1 := ((dwBPM shl (1 + (longword(dwBPM <= 150) and 1))) * 21845) shr 16; // x2/3 or x4/3
        if longbool(Tempo.dwTripleTime) or ((dwScan1 >= Tempo.cMinBPM) and (dwScan1 <= Tempo.cMaxBPM)) then begin
            // �V���������l���v�Z
            dwScan2 := dwScan1;
            Dec(dwScan1, 5);
            Inc(dwScan2, 5);
            if dwScan1 < 60 then dwScan1 := 60;
            if dwScan2 > 200 then dwScan2 := 200;
            cValue := dwBPM; // �o�b�N�A�b�v
            dwBPM := 0;
            dwCount2 := 0;
            for I := dwScan1 to dwScan2 do begin
                dwCount3 := Tempo.Count[I];
                Inc(dwBPM, longword(I + I) * dwCount3);
                Inc(dwCount2, dwCount3);
            end;
            // �O�A�����o�̏d�݊�l
            dwCount3 := 30;
            if longbool(Tempo.dwTripleTime) then dwCount3 := 10;
            if (dwCount2 >= dwCount3) and (dwCount2 >= (dwCount1 shr 3)) then begin
                dwBPM := dwBPM div dwCount2;
                dwBPM := (dwBPM shr 1) + (dwBPM and 1);
                dwCount1 := dwCount2 shl 2;
                Tempo.cMode := cEnable + 1;
                Tempo.dwTripleTime := 640000; // 10sec
            end else begin
                dwBPM := cValue; // ����
            end;
        end;
    end;
    // �e���|�������ł��Ȃ������ꍇ (����̂�)
    if not bytebool(Tempo.cBPM) and not longbool(dwBPM) then begin
        if (cBPM2 - cBPM1) <= 20 then begin
            // �e���|��͔͈͂̌덷���琄��
            dwBPM := (cBPM1 + cBPM2) shr 1;
            Tempo.cMode := cEnable + 2;
        end else begin
            // �e���|��͔͈͂̌덷���傫���ꍇ�A�S�͈͂��琄��
            dwScan2 := 0;
            for I := 60 to 200 do begin
                dwCount3 := Tempo.Count[I];
                if dwScan2 < dwCount3 then begin
                    dwScan2 := dwCount3;
                    dwBPM := I;
                    Tempo.cMode := cEnable + 3;
                end;
            end;
            if longbool(dwBPM) then begin
                if dwBPM <= 70 then cBPM1 := 60 else cBPM1 := dwBPM - 10;
                if dwBPM >= 190 then cBPM2 := 200 else cBPM2 := dwBPM + 10;
                Tempo.cMinBPM := cBPM1;
                Tempo.cMaxBPM := cBPM2;
            end;
        end;
    end;
    // �e���|�𐄑��ς݂ŁA��͊J�n����K�莞�Ԃ��o�߂����ꍇ�A��͌��ʂ��N���A
    dwCount2 := T64Count - Tempo.dwStartTime;
    if bytebool(Tempo.cBPM) and ((dwCount1 >= 600) or (dwCount2 >= 240000) // 3.75sec
            or (Tempo.cBPM < cBPM1) or (Tempo.cBPM > cBPM2)) then begin
        // KON �J�E���g���w�K
        if (Tempo.cBPM < cBPM1) or (Tempo.cBPM > cBPM2) then begin
            if longbool(dwBPM) and ((dwCount1 >= 30) or (dwCount2 >= 120000)) then Tempo.cBPM := dwBPM // 1.875sec
            else if not bytebool(Tempo.cKOnCountOld) then Tempo.cBPM := dwBPM;
            Tempo.cKOnCountOld := 0; // �w�K���Z�b�g
        end else begin
            if longbool(dwBPM) and (dwCount1 >= 30) then Tempo.cBPM := dwBPM;
            Tempo.cKOnCountOld := Tempo.cKOnCount;
            if cEnable = $41 then Dec(Tempo.cKOnCountOld) else Inc(Tempo.cKOnCountOld);
        end;
        // ������
        Tempo.cKOnCount := 0;
        Tempo.dwStartTime := T64Count;
        if Tempo.dwTripleTime > dwCount2 then Dec(Tempo.dwTripleTime, dwCount2) else Tempo.dwTripleTime := 0;
        API_ZeroMemory(@Tempo.Count, SizeOf(Tempo.Count));
        // �e���|�̗h���h�~
        if (dwBPM >= Tempo.cMinBPM) and (dwBPM <= Tempo.cMaxBPM) then begin
            dwCount3 := Tempo.Count[dwBPM] shr 2;
            if T64Count < 720000 then dwCount3 := dwCount3 shr 1; // 11.25sec
            if not ((dwCount1 >= 60) or (dwCount2 >= 240000)) then dwCount3 := dwCount3 shr 1; // 3.75sec
            Tempo.Count[dwBPM] := dwCount3;
        end;
        exit;
    end;
    // ��������l�ȏ�A�܂��́A�K�莞�Ԍo�ߌ�̃e���|�𐄑��l�Ƃ��ċL�^
    if longbool(dwBPM) and ((dwCount1 >= 60) or (dwCount2 >= 240000)) then begin // 3.75sec
        Tempo.cBPM := dwBPM;
        // �e���|�̗h���h�~
        if (dwBPM >= Tempo.cMinBPM) and (dwBPM <= Tempo.cMaxBPM) then Inc(Tempo.Count[dwBPM], 2);
        exit;
    end;
end;

// ================================================================================
// SNESAPUCallback - SNESAPU �R�[���o�b�N
// ================================================================================
function _SNESAPUCallback(dwEffect: longword; dwAddr: longword; dwValue: longword; lpData: pointer): longword; stdcall;
begin
    result := dwValue;
    case dwEffect of
        CBE_DSPREG: begin
            if Option.bBPM then case dwAddr and $7F of
                $4C: AnalyzeTempo(dwValue);
                $5C: Status.Tempo.cKOn := Status.Tempo.cKOn and (dwValue xor $FF and $FF);
            end;
        end;
    end;
    if longbool(@Apu.SNESAPUCallbackProc) then begin
        result := Apu.SNESAPUCallbackProc(dwEffect, dwAddr, dwValue, lpData);
    end;
end;

// ================================================================================
// DSPDebug - DSP �f�o�b�O
// ================================================================================
procedure _DSPDebug(); stdcall;
var
    dwAddr: longword;
    dwValue: longword;
begin
    asm
        Mov dwAddr,EBX
        Mov dwValue,EAX
    end;
    if Option.bBPM then case dwAddr and $7F of
        $4C: AnalyzeTempo(dwValue);
        $5C: Status.Tempo.cKOn := Status.Tempo.cKOn and (dwValue xor $FF and $FF);
    end;
    if longbool(@Apu.DSPDebug) then asm
        Mov EDX,Apu.DSPDebug;
        Mov EBX,dwAddr
        Mov EAX,dwValue
        Call EDX
    end;
end;

// ================================================================================
// Initialize - ������
// ================================================================================
function Initialize(hSNESAPU: longword): longint; stdcall;
begin
    // �������ς݂̏ꍇ�́A�I��
    if Status.bInitialized then begin
        result := 1;
        exit;
    end;
    // �t���O������
    Option.bBPM := false;
    // SNESAPU.DLL �� API ���擾
    result := -1;
    @Apu.GetAPUData := API_GetProcAddress(hSNESAPU, pchar('GetAPUData'));
    if not longbool(@Apu.GetAPUData) then exit;
    @Apu.SNESAPUCallback := API_GetProcAddress(hSNESAPU, pchar('SNESAPUCallback'));
    @Apu.SetDSPDbg := API_GetProcAddress(hSNESAPU, pchar('SetDSPDbg'));
    if not longbool(@Apu.SNESAPUCallback) and not longbool(@Apu.SetDSPDbg) then exit;
    // SNESAPU.DLL �̏����擾
    Apu.GetAPUData(NULLPOINTER, NULLPOINTER, NULLPOINTER, @Apu.T64Count, @Apu.DspReg, NULLPOINTER, NULLPOINTER, NULLPOINTER);
    // �R�[���o�b�N��ǉ��ݒ�
{$IFNDEF FORCEDSPDBG}
    if longbool(@Apu.SNESAPUCallback) then @Apu.SNESAPUCallbackProc := Apu.SNESAPUCallback(@_SNESAPUCallback, CBE_DSPREG)
    else
{$ENDIF}
    @Apu.DSPDebug := Apu.SetDSPDbg(@_DSPDebug);
    // ����
    Status.bInitialized := true;
    result := 0;
end;

// ================================================================================
// Start - BPM ��͊J�n
// ================================================================================
function Start(lpReserved: pointer): longint; stdcall;
var
    dwAddress: pointer;
    T64Count: longword;
begin
    // ����������Ă��Ȃ��ꍇ�́A�I��
    if not Status.bInitialized then begin
        result := -1;
        exit;
    end;
    // �o�b�t�@���N���A
    API_ZeroMemory(@Status.Tempo, SizeOf(TTEMPO));
    // �t���O��ݒ�
    Option.bBPM := true;
    // ���݈ʒu���擾
    T64Count := Apu.T64Count^;
    // ���Ԃ�������
    Status.Tempo.dwStartTime := T64Count;
    Status.Tempo.dwKOnTime := T64Count;
    Status.Tempo.dwMinTime := T64Count;
    Status.Tempo.dwMaxTime := T64Count;
    // �Ǘ���������ԋp
    if longbool(lpReserved) then begin
        dwAddress := @Status.Tempo;
        API_MoveMemory(lpReserved, @dwAddress, 4);
    end;
    // ����
    result := 0;
end;

// ================================================================================
// Stop - BPM ��͒�~
// ================================================================================
function Stop(): longint; stdcall;
begin
    // ����������Ă��Ȃ��ꍇ�́A�I��
    if not Status.bInitialized then begin
        result := -1;
        exit;
    end;
    // BPM ��͂��J�n����Ă��Ȃ��ꍇ�́A�I��
    if not Option.bBPM then begin
        result := -2;
        exit;
    end;
    // �t���O��ݒ�
    Option.bBPM := false;
    // ����
    result := 0;
end;

// ================================================================================
// GetBPM - BPM �擾
// ================================================================================
function GetBPM(lpReserved: pointer): longint; stdcall;
begin
    // ����������Ă��Ȃ��ꍇ�́A�I��
    if not Status.bInitialized then begin
        result := -1;
        exit;
    end;
    // BPM ��͂��J�n����Ă��Ȃ��ꍇ�́A�I��
    if not Option.bBPM then begin
        result := -2;
        exit;
    end;
    // BPM ��ԋp
    result := Status.Tempo.cBPM;
end;


// *************************************************************************************************************************************************************
// �G�N�X�|�[�g�֐�
// *************************************************************************************************************************************************************

exports
    Initialize,
    Start,
    Stop,
    GetBPM;

begin
    Status.bInitialized := false;
end.
