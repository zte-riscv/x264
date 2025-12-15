/*****************************************************************************
 * bitstream-a.S: riscv bitstream functions
 *****************************************************************************
 * Copyright (C) 2014-2024 x264 project
 *
 * Authors: Yin Tong <yintong.ustc@bytedance.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02111, USA.
 *
 * This program is also available under a commercial proprietary license.
 * For more information, contact us at licensing@x264.com.
 *****************************************************************************/

#include "asm.S"

// TODO: This function can be optimized by select a appropriate length of data to be processed each time, 
// a larger VLEN may not bring performance gains,
// because if we detect the whole seqence need to insert 0x03, we should to process them one by one
function nal_escape_rvv
    vsetivli       zero, 16, e8, m1, ta, ma
    vmv.v.i        v1, -1
    vmv.v.i        v8, 4
    li             a6, 3
    sub            a5, a1, a2
    beqz           a5, 99f

0:
    addi           t1, a5, 15
    bltz           t1, 16f
    mv             a1, a2
    j              100f

16:
    vle8.v         v2, (a1)
    addi           a1, a1, 16
    vslidedown.vi  v3, v1, 14
    vslideup.vi    v3, v2, 2
    vslidedown.vi  v4, v1, 15
    vslideup.vi    v4, v2, 1
    vmslt.vi       v21, v2, 4
    vmseq.vi       v0, v3, 0
    vmseq.vi       v20, v4, 0
    vmand.mm       v0, v0, v21
    vmand.mm       v0, v0, v20
    vcpop.m        a7, v0
    beqz           a7, 16f
    li             a5, -16
100:
    vslidedown.vi  v5, v1, 14
    vmv.x.s        t6, v5
    vslidedown.vi  v5, v1, 15
    vmv.x.s        a7, v5
    slliw          t6, t6, 8
    or             t6, t6, a7

101:
    add            a3, a5, a1
    lbu            t2, 0(a3)
    slliw          t3, t6, 16
    or             t4, t3, t2
    slli           t4, t4, 32
    srli           t4, t4, 32
    addi           t4, t4, -3
    bgtz           t4, 102f

    sb             a6, 0(a0)
    addi           a0, a0, 1
    slliw          t6, t6, 8
    or             t6, t6, a6

102:
    addi           a5, a5, 1
    sb             t2, 0(a0)
    addi           a0, a0, 1
    slliw          t6, t6, 8
    or             t6, t6, t2
    bltz           a5, 101b
    sub            a5, a1, a2
    srliw          t4, t6, 8
    andi           t4, t4, 0xff
    andi           t5, t6, 0xff
    vslideup.vi    v7, v1, 2
    vslide1down.vx v7, v7, t4
    vslide1down.vx v1, v7, t5

    bltz           a5, 0b
    j              99f

16:
    sub            a5, a1, a2
    vse8.v         v2, (a0)
    addi           a0, a0, 16
    vmv.v.v        v1, v2
    bltz           a5, 0b

99:
    ret
endfunc