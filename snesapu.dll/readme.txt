Super Nintendo Entertainment System(tm) Audio Processor Unit Emulator
Dynamically Linking Library version 2.0
==============================================================================

This is the source code to SNESAPU.DLL, a SNES APU emulator written for IA32
platforms.

The C++ code is used to create the DLL interface for 32-bit Windows platforms
and is only necessary if you're building SNESAPU.DLL.  The SNESAPU project was
created for Visual C++ v6.0 with the output set to compile into the
C:\Windows\system32 directory.

All of the emulation code was written in assembly for NASM v0.98.34 and
has been successfully compiled and executed under both Linux and Windows.

All assembly source was written with tab stops set to three characters.

Note:  Because of alignment issues with Win32 object files, extra padding may
       need to be inserted into the DSP emulator.  See line 247 in DSP.Asm


Files
-----

SNESAPU - Main program
SPC700  - Executes programs written for the SPC700
DSP     - Performs all mixing and output
APU     - Groups the SPC700 and DSP together and adds extra functionality



Implementation
--------------

I wanted to create an emulator that had versitilty and was easy to use.
Since those two objectives fall on opposite ends of the spectrum, it was hard
to find a middle ground.  I made the interface as easy as I could while still
retaining the functionality I wanted.

I'll explain how to create a basic SPC player.  If you want to add additional
features, you'll have to look at the header files for descriptions of the
functions.

First, you need to link the DLL.  If you include SNESAPU.h and SNESAPU.lib in
your project, your program should automatically load the DLL at run-time.
Otherwise, you'll need to use the LoadLibrary and GetProcAddress functions.

Upon linking the DLL, the emulator will be initialized.  The SPC700 is in a
a state identical to powerup in the SNES, and the DSP is set to return 16-bit
stereo output at 32kHz.  You can begin emulation at this point, though all
you will hear is silence as the SPC700 waits in a loop to receive data.

Allocate a buffer of 66048 bytes.  Read an SPC file into this buffer, then
pass a pointer to the buffer to LoadSPCFile().  This function will reset the
APU state and copy the necessary data from the file.

To emulate the APU, call EmuAPU().  Emulation can be based on clock cycles
or samples.

Keep track of how much time has gone by by checking t64Cnt.  One second is
equal to 64,000 counter increases.  t64Cnt is set to 0 by ResetAPU.

Summary:

1) Link the DLL to initialize the emulator
2) Call LoadSPCFile() to copy the SPC into the APU
3) Call EmuAPU() to generate audio output
4) Go to step 3 until you wish to stop
5) To load another song, goto step 2
6) Unlink the DLL to release memory allocated by SNESAPU.DLL



DSP Registers
-------------

The DSPRAM structure may look a bit intimidating, but it actually correctly
maps to the DSP registers and is quite easy to use.  Here are some examples
of how to access the registers:

Find out the instrument playing on voice 3 -

i = dsp.voice[3].srcn;


Find out the delay of the echo in milliseconds -

i = dsp.edl << 4;


Find out if a song uses echo filtering -

i = dsp.fir[0].c;
if (i == 0x7F) i = 0;

for (j=1; j<8; j++)
    i |= dsp.fir[j].c;

if (i) filter = true;



Thanks
------

The SNESAPU.DLL would not exist without these people:

Marius Fodor-
 Testing the DLL interface and emulation code, giving suggestions, answering
 my questions about C++, and telling me how to fix my errors, even when I
 didn't want to. :)
Datschge-
 Testing the DLL and giving constant suggestions
Gary Henderson-
 Getting me to write the 32-bit emulation core and helping with bugs

Thanks to these people also:

Sycraft-
 Suggesting the 32-bit sample routine and testing it
Cait Sith 2-
 Finding bugs in the SPC700 emulation and providing suggestions
nZero-
 Finding bugs in the DSP
Nitro-
 Testing the emulation core in its early, and broken, stages



Using the source in your own programs
-------------------------------------

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License,
or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the
Free Software Foundation, Inc.
59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.


SNESAPU is copyright (C)2001-2004 Alpha-II Productions (www.alpha-ii.com)

"SNES" and "Super Nintendo Entertainment System" are registered trademarks of
Nintendo (www.nintendo.com)