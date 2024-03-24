;===================================================================================================
;Program:    SNESAPU Global Object
;Platform:   Intel 80386
;Programmer: sunburst (degrade-factory)
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
;                                                   Copyright (C) 2003-2024 degrade-factory
;===================================================================================================

%define SNESAPU_INC

;===================================================================================================
;Equates

;Align Adjustment ----------------------
;   Note: Please refer to the map file output during build and adjust the numbers,
;     so that the lower 8-bits of the start address of '_mix' are '00'.
;    If it is not, the output audio will be noisy because occurred memory-leak.
;    The value specified here is 0, 64, 128, or 192.
DSP_ALIGN   EQU 192                                             ;DSP Object Locate Alignment
