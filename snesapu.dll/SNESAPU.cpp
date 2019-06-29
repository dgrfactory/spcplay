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
*                                                 Copyright (C) 2003-2008 degrade-factory          *
***************************************************************************************************/

// ----- degrade-factory code [2008/01/13] -----
#define WIN32_LEAN_AND_MEAN                                     //Leave out unnecessary grunt in windows.h
#include    "types.h"
#include    "SPC700.h"
#include    "DSP.h"
#include    "APU.h"
#pragma comment(linker, "/opt:nowin98")
#pragma comment(linker, "/merge:.rdata=.text")
#pragma comment(linker, "/section:.text,erw")
#pragma comment(linker, "/ignore:4078")
#pragma comment(linker, "/nodefaultlib")

#ifdef  __cplusplus
extern  "C" {
#endif

u32 _DllMainCRTStartup(u32 hinst, u32 fwdReason, u32 lpReserved) {
    return InitAPU(fwdReason);
}

#ifdef  __cplusplus
}
#endif
// ----- degrade-factory code [END] -----
