/*****************************************************************************
 * pixel.S: riscv pixel metrics
 *****************************************************************************
 * Copyright (C) 2009-2024 x264 project
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

const mask
    .rept 16
    .byte 0xff
    .endr
    .rept 16
    .byte 0x00
    .endr
endconst

const mask_ac_4_8
    .short 0, -1, -1, -1,  0, -1, -1, -1
    .short 0, -1, -1, -1, -1, -1, -1, -1
endconst

.macro SUMSUBL_AB sum, sub, a, b
    vwaddu.vv       \sum, \a, \b
    vwsubu.vv       \sub, \a, \b
.endm

.macro vabs d0, s0, t0
    vrsub.vi        \t0, \s0, 0
    vmax.vv         \d0, \s0, \t0
.endm

.macro uabd d0, s0, s1, t0
    vmaxu.vv        \d0, \s0, \s1
    vminu.vv        \t0, \s0, \s1
    vsub.vv         \d0, \d0, \t0    
.endm

.macro uaba d0, s0, s1, t0, t1
    vmaxu.vv        \t1, \s0, \s1
    vminu.vv        \t0, \s0, \s1
    vsub.vv         \t0, \t1, \t0
    vadd.vv         \d0, \d0, \t0    
.endm

.macro uabal d0, s0, s1, t0, t1
    vmaxu.vv        \t1, \s0, \s1
    vminu.vv        \t0, \s0, \s1
    vsub.vv         \t0, \t1, \t0
    vwaddu.wv       \d0, \d0, \t0    
.endm

.macro uabdl d0, s0, s1, t0, t1
    vmaxu.vv        \t1, \s0, \s1
    vminu.vv        \t0, \s0, \s1
    vwsubu.vv       \d0, \t1, \t0    
.endm

.macro HADAMARD4_V r1, r2, r3, r4, t1, t2, t3, t4
    SUMSUB_ABCD \t1, \t2, \t3, \t4, \r1, \r2, \r3, \r4
    SUMSUB_ABCD \r1, \r3, \r2, \r4, \t1, \t3, \t2, \t4
.endm


#if BIT_DEPTH == 8

// SAD functions

function pixel_sad_4x4_rvv
    vsetivli    zero, 4, e8, mf4, ta, ma
    vle8.v      v0, (a0)
    add         a0, a0, a1
    vle8.v      v1, (a0)
    add         a0, a0, a1
    vle8.v      v2, (a2)
    add         a2, a2, a3
    vle8.v      v3, (a2)
    add         a2, a2, a3

    vsetivli    zero, 8, e8, mf2, ta, ma
    vslideup.vi v0, v1, 4
    vslideup.vi v2, v3, 4
    uabdl       v16, v0, v2, v8, v12

    vsetivli    zero, 4, e8, mf4, ta, ma
    vle8.v      v0, (a0)
    add         a0, a0, a1
    vle8.v      v1, (a0)
    vle8.v      v2, (a2)
    add         a2, a2, a3
    vle8.v      v3, (a2)

    vsetivli    zero, 8, e8, mf2, ta, ma
    vslideup.vi v0, v1, 4
    vslideup.vi v2, v3, 4
    uabal       v16, v0, v2, v8, v12

    vsetivli    zero, 8, e16, m1, ta, ma
    vmv.s.x     v31, zero
    vredsum.vs  v31, v16, v31
    vmv.x.s     a0, v31
    
    ret
endfunc

function pixel_sad_4x8_rvv
    vsetivli    zero, 4, e8, mf4, ta, ma
    vle8.v      v0, (a0)
    add         a0, a0, a1
    vle8.v      v1, (a0)
    add         a0, a0, a1
    vle8.v      v2, (a2)
    add         a2, a2, a3
    vle8.v      v3, (a2)
    add         a2, a2, a3

    vsetivli    zero, 8, e8, mf2, ta, ma
    vslideup.vi v0, v1, 4
    vslideup.vi v2, v3, 4
    uabdl       v16, v0, v2, v8, v12
.rept 3
    vsetivli    zero, 4, e8, mf4, ta, ma
    vle8.v      v0, (a0)
    add         a0, a0, a1
    vle8.v      v1, (a0)
    add         a0, a0, a1
    vle8.v      v2, (a2)
    add         a2, a2, a3
    vle8.v      v3, (a2)
    add         a2, a2, a3

    vsetivli    zero, 8, e8, mf2, ta, ma
    vslideup.vi v0, v1, 4
    vslideup.vi v2, v3, 4
    uabal       v16, v0, v2, v8, v12
.endr
    vsetivli    zero, 8, e16, m1, ta, ma
    vmv.s.x     v31, zero
    vredsum.vs  v31, v16, v31
    vmv.x.s     a0, v31
    
    ret
endfunc

function pixel_sad_4x16_rvv
    vsetivli    zero, 4, e8, mf4, ta, ma
    vle8.v      v0, (a0)
    add         a0, a0, a1
    vle8.v      v1, (a0)
    add         a0, a0, a1
    vle8.v      v2, (a2)
    add         a2, a2, a3
    vle8.v      v3, (a2)
    add         a2, a2, a3

    vsetivli    zero, 8, e8, mf2, ta, ma
    vslideup.vi v0, v1, 4
    vslideup.vi v2, v3, 4
    uabdl       v16, v0, v2, v8, v12
.rept 7
    vsetivli    zero, 4, e8, mf4, ta, ma
    vle8.v      v0, (a0)
    add         a0, a0, a1
    vle8.v      v1, (a0)
    add         a0, a0, a1
    vle8.v      v2, (a2)
    add         a2, a2, a3
    vle8.v      v3, (a2)
    add         a2, a2, a3

    vsetivli    zero, 8, e8, mf2, ta, ma
    vslideup.vi v0, v1, 4
    vslideup.vi v2, v3, 4
    uabal       v16, v0, v2, v8, v12
.endr
    vsetivli    zero, 8, e16, m1, ta, ma
    vmv.s.x     v31, zero
    vredsum.vs  v31, v16, v31
    vmv.x.s     a0, v31
    
    ret
endfunc

function pixel_sad_8x4_rvv
    vsetivli    zero, 8, e8, mf2, ta, ma
    vle8.v      v0, (a0)
    add         a0, a0, a1
    vle8.v      v1, (a0)
    add         a0, a0, a1
    vle8.v      v2, (a2)
    add         a2, a2, a3
    vle8.v      v3, (a2)
    add         a2, a2, a3

    vsetivli    zero, 16, e8, m1, ta, ma
    vslideup.vi v0, v1, 8
    vslideup.vi v2, v3, 8
    uabdl       v16, v0, v2, v8, v12

    vsetivli    zero, 8, e8, mf2, ta, ma
    vle8.v      v0, (a0)
    add         a0, a0, a1
    vle8.v      v1, (a0)
    vle8.v      v2, (a2)
    add         a2, a2, a3
    vle8.v      v3, (a2)

    vsetivli    zero, 16, e8, m1, ta, ma
    vslideup.vi v0, v1, 8
    vslideup.vi v2, v3, 8
    uabal       v16, v0, v2, v8, v12

    vsetivli    zero, 16, e16, m2, ta, ma
    vmv.s.x     v31, zero
    vredsum.vs  v31, v16, v31
    vmv.x.s     a0, v31
    
    ret
endfunc

function pixel_sad_8x8_rvv
    vsetivli    zero, 8, e8, mf2, ta, ma
    vle8.v      v0, (a0)
    add         a0, a0, a1
    vle8.v      v1, (a0)
    add         a0, a0, a1
    vle8.v      v2, (a2)
    add         a2, a2, a3
    vle8.v      v3, (a2)
    add         a2, a2, a3

    vsetivli    zero, 16, e8, m1, ta, ma
    vslideup.vi v0, v1, 8
    vslideup.vi v2, v3, 8
    uabdl       v16, v0, v2, v8, v12
.rept 3
    vsetivli    zero, 8, e8, mf2, ta, ma
    vle8.v      v0, (a0)
    add         a0, a0, a1
    vle8.v      v1, (a0)
    add         a0, a0, a1
    vle8.v      v2, (a2)
    add         a2, a2, a3
    vle8.v      v3, (a2)
    add         a2, a2, a3

    vsetivli    zero, 16, e8, m1, ta, ma
    vslideup.vi v0, v1, 8
    vslideup.vi v2, v3, 8
    uabal       v16, v0, v2, v8, v12
.endr
    vsetivli    zero, 16, e16, m2, ta, ma
    vmv.s.x     v31, zero
    vredsum.vs  v31, v16, v31
    vmv.x.s     a0, v31
    
    ret
endfunc

function pixel_sad_8x16_rvv
    vsetivli    zero, 8, e8, mf2, ta, ma
    vle8.v      v0, (a0)
    add         a0, a0, a1
    vle8.v      v1, (a0)
    add         a0, a0, a1
    vle8.v      v2, (a2)
    add         a2, a2, a3
    vle8.v      v3, (a2)
    add         a2, a2, a3

    vsetivli    zero, 16, e8, m1, ta, ma
    vslideup.vi v0, v1, 8
    vslideup.vi v2, v3, 8
    uabdl       v16, v0, v2, v8, v12
.rept 7
    vsetivli    zero, 8, e8, mf2, ta, ma
    vle8.v      v0, (a0)
    add         a0, a0, a1
    vle8.v      v1, (a0)
    add         a0, a0, a1
    vle8.v      v2, (a2)
    add         a2, a2, a3
    vle8.v      v3, (a2)
    add         a2, a2, a3

    vsetivli    zero, 16, e8, m1, ta, ma
    vslideup.vi v0, v1, 8
    vslideup.vi v2, v3, 8
    uabal       v16, v0, v2, v8, v12
.endr
    vsetivli    zero, 16, e16, m2, ta, ma
    vmv.s.x     v31, zero
    vredsum.vs  v31, v16, v31
    vmv.x.s     a0, v31
    
    ret
endfunc

function pixel_sad_16x8_rvv
    vsetivli    zero, 16, e8, m1, ta, ma
    vle8.v      v0, (a0)
    add         a0, a0, a1
    vle8.v      v1, (a0)
    add         a0, a0, a1
    vle8.v      v2, (a2)
    add         a2, a2, a3
    vle8.v      v3, (a2)
    add         a2, a2, a3
    uabdl       v16, v0, v2, v8, v12
    uabal       v16, v1, v3, v8, v12
.rept 3
    vle8.v      v0, (a0)
    add         a0, a0, a1
    vle8.v      v1, (a0)
    add         a0, a0, a1
    vle8.v      v2, (a2)
    add         a2, a2, a3
    vle8.v      v3, (a2)
    add         a2, a2, a3
    uabal       v16, v0, v2, v8, v12
    uabal       v16, v1, v3, v8, v12
.endr
    vsetivli    zero, 16, e16, m2, ta, ma
    vmv.s.x     v31, zero
    vredsum.vs  v31, v16, v31
    vmv.x.s     a0, v31

    ret
endfunc

function pixel_sad_16x16_rvv
    vsetivli    zero, 16, e8, m1, ta, ma
    vle8.v      v0, (a0)
    add         a0, a0, a1
    vle8.v      v1, (a0)
    add         a0, a0, a1
    vle8.v      v2, (a2)
    add         a2, a2, a3
    vle8.v      v3, (a2)
    add         a2, a2, a3
    uabdl       v16, v0, v2, v8, v12
    uabal       v16, v1, v3, v8, v12
.rept 7
    vle8.v      v0, (a0)
    add         a0, a0, a1
    vle8.v      v1, (a0)
    add         a0, a0, a1
    vle8.v      v2, (a2)
    add         a2, a2, a3
    vle8.v      v3, (a2)
    add         a2, a2, a3
    uabal       v16, v0, v2, v8, v12
    uabal       v16, v1, v3, v8, v12
.endr
    vmv.v.i     v31, 0
    vsetivli    zero, 16, e16, m2, ta, ma
    vwredsum.vs v31, v16, v31
    vsetivli     zero, 4, e32, m1, ta, ma
    vmv.x.s     a0, v31

    ret
endfunc

// SAD_ALIGNED functions

function pixel_sad_aligned_4x4_rvv
    vsetivli    zero, 4, e32, m1, ta, ma
    vlse32.v    v0, (a0), a1
    vlse32.v    v4, (a2), a3    
    vsetivli    zero, 1, e16, m1, ta, ma
    vmv.s.x     v31, zero
    vsetivli    zero, 16, e8, m1, ta, ma
    uabd        v16,v0,v4,v8
    vwredsumu.vs  v31, v16, v31
    vsetivli    zero, 1, e16, m1, ta, ma
    vmv.x.s     a0, v31

    ret
endfunc

function pixel_sad_aligned_4x8_rvv
    li          t0, 32
    vsetivli    zero, 8, e32, m2, ta, ma
    vlse32.v    v0, (a0), a1
    vlse32.v    v4, (a2), a3    
    vsetivli    zero, 1, e16, m1, ta, ma
    vmv.s.x     v31, zero
    vsetvli     zero, t0, e8, m2, ta, ma
    uabd        v16,v0,v4,v8
    vwredsumu.vs  v31, v16, v31
    vsetivli    zero, 1, e16, m1, ta, ma
    vmv.x.s     a0, v31

    ret
endfunc

function pixel_sad_aligned_4x16_rvv
    li          t0, 64
    vsetivli    zero, 16, e32, m4, ta, ma
    vlse32.v    v0, (a0), a1
    vlse32.v    v4, (a2), a3
    vsetivli    zero, 1, e16, m1, ta, ma
    vmv.s.x     v31, zero
    vsetvli     zero, t0, e8, m4, ta, ma
    uabd        v16,v0,v4,v8
    vwredsumu.vs  v31, v16, v31
    vsetivli    zero, 1, e16, m1, ta, ma
    vmv.x.s     a0, v31

    ret
endfunc

function pixel_sad_aligned_8x4_rvv
    li          t0, 32
    vsetivli    zero, 4, e64, m2, ta, ma
    vlse64.v    v0, (a0), a1
    vlse64.v    v4, (a2), a3
    vsetivli    zero, 1, e16, m1, ta, ma
    vmv.s.x     v31, zero
    vsetvli     zero, t0, e8, m2, ta, ma
    uabd        v16,v0,v4,v8
    vwredsumu.vs  v31, v16, v31
    vsetivli    zero, 1, e16, m1, ta, ma
    vmv.x.s     a0, v31

    ret
endfunc


function pixel_sad_aligned_8x8_rvv
    li          t0, 64
    vsetivli    zero, 8, e64, m4, ta, ma
    vlse64.v    v0, (a0), a1
    vlse64.v    v4, (a2), a3
    vsetivli    zero, 1, e16, m1, ta, ma
    vmv.s.x     v31, zero
    vsetvli    zero, t0, e8, m4, ta, ma

    uabd   v16, v0, v4, v20
    vwredsumu.vs  v31, v16, v31
    vsetivli    zero, 1, e16, m1, ta, ma
    vmv.x.s     a0, v31
    zext.h a0, a0

    ret
endfunc

// vredsum.vs is expensive when LMUL become bigger, 
// so this may can be optimized by reduce using of vredsum.vs, replaced by multiple vadd.vv followed by a final vredsum.vs
function pixel_sad_aligned_8x16_rvv
    li          t0, 64
    vsetivli    zero, 8, e64, m4, ta, ma
    vlse64.v    v0, (a0), a1
    vlse64.v    v8, (a2), a3
    slli        t1, a1, 3
    slli        t2, a3, 3
    add         a0, a0, t1
    add         a2, a2, t2
    vlse64.v    v4, (a0), a1
    vlse64.v    v12, (a2), a3

    vsetivli    zero, 1, e16, m1, ta, ma
    vmv.s.x     v31, zero
    vsetvli    zero, t0, e8, m4, ta, ma

    uabd   v16, v0, v8, v24
    uabd   v20, v4, v12, v24

    vwredsumu.vs  v31, v16, v31
    vwredsumu.vs  v31, v20, v31
    vsetivli    zero, 1, e16, m1, ta, ma
    vmv.x.s     a0, v31

    ret
endfunc

function pixel_sad_aligned_16x8_rvv
    li          t0, 64
    vsetivli    zero, 8, e64, m4, ta, ma
    vlse64.v    v0, (a0), a1
    vlse64.v    v8, (a2), a3
    addi        a0, a0, 8
    addi        a2, a2, 8
    vlse64.v    v4, (a0), a1
    vlse64.v    v12, (a2), a3

    vsetivli    zero, 1, e16, m1, ta, ma
    vmv.s.x     v31, zero
    vsetvli    zero, t0, e8, m4, ta, ma

    uabd   v16, v0, v8, v24
    uabd   v20, v4, v12, v24

    vwredsumu.vs  v31, v16, v31
    vwredsumu.vs  v31, v20, v31
    vsetivli    zero, 1, e16, m1, ta, ma
    vmv.x.s     a0, v31

    ret
endfunc

function pixel_sad_aligned_16x16_rvv
    li          t0, 64
    vsetivli    zero, 8, e64, m4, ta, ma
    vlse64.v    v0, (a0), a1
    vlse64.v    v8, (a2), a3
    slli        t1, a1, 3
    slli        t2, a3, 3
    add         t3, a0, t1
    add         t4, a2, t2
    vlse64.v    v4, (t3), a1
    vlse64.v    v12, (t4), a3

    vsetivli    zero, 1, e16, m1, ta, ma
    vmv.s.x     v30, zero
    vmv.s.x     v31, zero
    vsetvli    zero, t0, e8, m4, ta, ma
    uabd   v16, v0, v8, v24
    uabd   v20, v4, v12, v24
    vwredsumu.vs  v30, v16, v30
    vwredsumu.vs  v31, v20, v31

    addi        a0, a0, 8
    addi        a2, a2, 8

    vsetivli    zero, 8, e64, m4, ta, ma
    vlse64.v    v0, (a0), a1
    vlse64.v    v8, (a2), a3
    add         t3, a0, t1
    add         t4, a2, t2
    vlse64.v    v4, (t3), a1
    vlse64.v    v12, (t4), a3

    vsetvli    zero, t0, e8, m4, ta, ma
    uabd   v16, v0, v8, v24
    uabd   v20, v4, v12, v24
    vwredsumu.vs  v30, v16, v30
    vwredsumu.vs  v31, v20, v31
    vsetivli    zero, 1, e16, m1, ta, ma
    vmv.x.s     a0, v30
    vmv.x.s     a5, v31
    add         a0, a0, a5

    ret
endfunc

// SAD_X3 functions
// RISC-V RVV implementation of SAD for 4x4 blocks with 3 predictions
function pixel_sad_x3_4x4_rvv
    li          t0, FENC_STRIDE
    // --- Process first two rows ---
    vsetivli    zero, 4, e8, mf4, ta, ma

    // Load first row of source block
    vle8.v      v0, (a0)                 // src row0
    add         a0, a0, t0               // Move to next src row
    
    // Load second row of source block  
    vle8.v      v1, (a0)                 // src row1
    add         a0, a0, t0               // Move to next src row
    
    // Load first prediction block (2 rows)
    vle8.v      v2, (a1)                 // pred0 row0
    add         a1, a1, a4               // pred0 stride
    vle8.v      v3, (a1)                 // pred0 row1
    add         a1, a1, a4               // Move to next row
    
    // Load second prediction block (2 rows)
    vle8.v      v4, (a2)                 // pred1 row0
    add         a2, a2, a4               // pred1 stride
    vle8.v      v5, (a2)                 // pred1 row1
    add         a2, a2, a4               // Move to next row
    
    // Load third prediction block (2 rows)
    vle8.v      v6, (a3)                 // pred2 row0
    add         a3, a3, a4               // pred2 stride
    vle8.v      v7, (a3)                 // pred2 row1
    add         a3, a3, a4               // Move to next row

    // Combine rows into 8-element vectors
    vsetivli    zero, 8, e8, mf2, ta, ma
    vslideup.vi v0, v1, 4
    vslideup.vi v2, v3, 4
    vslideup.vi v4, v5, 4
    vslideup.vi v6, v7, 4

    // Calculate initial absolute differences (first 2 rows)
    uabdl       v16, v0, v2, v8, v12
    uabdl       v18, v0, v4, v8, v12
    uabdl       v20, v0, v6, v8, v12

    // --- Process last two rows ---
    vsetivli    zero, 4, e8, mf4, ta, ma
    vle8.v      v0, (a0)
    add         a0, a0, t0
    vle8.v      v1, (a0)
    add         a0, a0, t0
    vle8.v      v2, (a1)
    add         a1, a1, a4
    vle8.v      v3, (a1)
    add         a1, a1, a4
    vle8.v      v4, (a2)
    add         a2, a2, a4
    vle8.v      v5, (a2)
    add         a2, a2, a4
    vle8.v      v6, (a3)
    add         a3, a3, a4
    vle8.v      v7, (a3)
    add         a3, a3, a4

    vsetivli    zero, 8, e8, mf2, ta, ma
    vslideup.vi v0, v1, 4
    vslideup.vi v2, v3, 4
    vslideup.vi v4, v5, 4
    vslideup.vi v6, v7, 4
    uabal       v16, v0, v2, v8, v12
    uabal       v18, v0, v4, v8, v12
    uabal       v20, v0, v6, v8, v12

    // --- Sum results ---
    vsetivli    zero, 8, e16, m1, ta, ma
    vmv.s.x     v30, zero
    vredsum.vs  v31, v16, v30
    vmv.x.s     t2, v31
    vredsum.vs  v31, v18, v30
    vmv.x.s     t3, v31
    vredsum.vs  v31, v20, v30
    vmv.x.s     t4, v31

    sw          t2, 0(a5)
    sw          t3, 4(a5)
    sw          t4, 8(a5)
    ret
endfunc

function pixel_sad_x3_4x8_rvv
    li          t0, FENC_STRIDE
    vsetivli    zero, 4, e8, mf4, ta, ma
    vle8.v      v0, (a0)
    add         a0, a0, t0
    vle8.v      v1, (a0)
    add         a0, a0, t0
    vle8.v      v2, (a1)
    add         a1, a1, a4
    vle8.v      v3, (a1)
    add         a1, a1, a4
    vle8.v      v4, (a2)
    add         a2, a2, a4
    vle8.v      v5, (a2)
    add         a2, a2, a4
    vle8.v      v6, (a3)
    add         a3, a3, a4
    vle8.v      v7, (a3)
    add         a3, a3, a4

    vsetivli    zero, 8, e8, mf2, ta, ma
    vslideup.vi v0, v1, 4
    vslideup.vi v2, v3, 4
    vslideup.vi v4, v5, 4
    vslideup.vi v6, v7, 4
    uabdl       v16, v0, v2, v8, v12
    uabdl       v18, v0, v4, v8, v12
    uabdl       v20, v0, v6, v8, v12
.rept 3
    vsetivli    zero, 4, e8, mf4, ta, ma
    vle8.v      v0, (a0)
    add         a0, a0, t0
    vle8.v      v1, (a0)
    add         a0, a0, t0
    vle8.v      v2, (a1)
    add         a1, a1, a4
    vle8.v      v3, (a1)
    add         a1, a1, a4
    vle8.v      v4, (a2)
    add         a2, a2, a4
    vle8.v      v5, (a2)
    add         a2, a2, a4
    vle8.v      v6, (a3)
    add         a3, a3, a4
    vle8.v      v7, (a3)
    add         a3, a3, a4

    vsetivli    zero, 8, e8, mf2, ta, ma
    vslideup.vi v0, v1, 4
    vslideup.vi v2, v3, 4
    vslideup.vi v4, v5, 4
    vslideup.vi v6, v7, 4
    uabal       v16, v0, v2, v8, v12
    uabal       v18, v0, v4, v8, v12
    uabal       v20, v0, v6, v8, v12
.endr
    vsetivli    zero, 8, e16, m1, ta, ma
    vmv.s.x     v30, zero
    vredsum.vs  v31, v16, v30
    vmv.x.s     t2, v31
    vredsum.vs  v31, v18, v30
    vmv.x.s     t3, v31
    vredsum.vs  v31, v20, v30
    vmv.x.s     t4, v31

    sw          t2, 0(a5)
    sw          t3, 4(a5)
    sw          t4, 8(a5)
    ret
endfunc

function pixel_sad_x3_8x4_rvv
    li          t0, FENC_STRIDE
    vsetivli    zero, 8, e8, mf2, ta, ma
    vle8.v      v0, (a0)
    add         a0, a0, t0
    vle8.v      v1, (a0)
    add         a0, a0, t0
    vle8.v      v2, (a1)
    add         a1, a1, a4
    vle8.v      v3, (a1)
    add         a1, a1, a4
    vle8.v      v4, (a2)
    add         a2, a2, a4
    vle8.v      v5, (a2)
    add         a2, a2, a4
    vle8.v      v6, (a3)
    add         a3, a3, a4
    vle8.v      v7, (a3)
    add         a3, a3, a4

    vsetivli    zero, 16, e8, m1, ta, ma
    vslideup.vi v0, v1, 8
    vslideup.vi v2, v3, 8
    vslideup.vi v4, v5, 8
    vslideup.vi v6, v7, 8
    uabdl       v16, v0, v2, v8, v12
    uabdl       v18, v0, v4, v8, v12
    uabdl       v20, v0, v6, v8, v12

    vsetivli    zero, 8, e8, mf2, ta, ma
    vle8.v      v0, (a0)
    add         a0, a0, t0
    vle8.v      v1, (a0)
    add         a0, a0, t0
    vle8.v      v2, (a1)
    add         a1, a1, a4
    vle8.v      v3, (a1)
    add         a1, a1, a4
    vle8.v      v4, (a2)
    add         a2, a2, a4
    vle8.v      v5, (a2)
    add         a2, a2, a4
    vle8.v      v6, (a3)
    add         a3, a3, a4
    vle8.v      v7, (a3)
    add         a3, a3, a4

    vsetivli    zero, 16, e8, m1, ta, ma
    vslideup.vi v0, v1, 8
    vslideup.vi v2, v3, 8
    vslideup.vi v4, v5, 8
    vslideup.vi v6, v7, 8
    uabal       v16, v0, v2, v8, v12
    uabal       v18, v0, v4, v8, v12
    uabal       v20, v0, v6, v8, v12

    vsetivli    zero, 16, e16, m2, ta, ma
    vmv.s.x     v30, zero
    vredsum.vs  v31, v16, v30
    vmv.x.s     t2, v31
    vredsum.vs  v31, v18, v30
    vmv.x.s     t3, v31
    vredsum.vs  v31, v20, v30
    vmv.x.s     t4, v31

    sw          t2, 0(a5)
    sw          t3, 4(a5)
    sw          t4, 8(a5)
    ret
endfunc

function pixel_sad_x3_8x8_rvv
    li          t0, FENC_STRIDE

    vsetivli    zero, 8, e8, mf2, ta, ma
    vle8.v      v0, (a0)
    add         a0, a0, t0
    vle8.v      v1, (a0)
    add         a0, a0, t0

    vle8.v      v2, (a1)
    add         a1, a1, a4
    vle8.v      v3, (a1)
    add         a1, a1, a4

    vle8.v      v4, (a2)
    add         a2, a2, a4
    vle8.v      v5, (a2)
    add         a2, a2, a4

    vle8.v      v6, (a3)
    add         a3, a3, a4
    vle8.v      v7, (a3)
    add         a3, a3, a4

    vsetivli    zero, 16, e8, m1, ta, ma
    vslideup.vi v0, v1, 8
    vslideup.vi v2, v3, 8
    vslideup.vi v4, v5, 8
    vslideup.vi v6, v7, 8
    uabdl       v16, v0, v2, v8, v12
    uabdl       v18, v0, v4, v8, v12
    uabdl       v20, v0, v6, v8, v12
.rept 3
    vsetivli    zero, 8, e8, mf2, ta, ma
    vle8.v      v0, (a0)
    add         a0, a0, t0
    vle8.v      v1, (a0)
    add         a0, a0, t0

    vle8.v      v2, (a1)
    add         a1, a1, a4
    vle8.v      v3, (a1)
    add         a1, a1, a4

    vle8.v      v4, (a2)
    add         a2, a2, a4
    vle8.v      v5, (a2)
    add         a2, a2, a4

    vle8.v      v6, (a3)
    add         a3, a3, a4
    vle8.v      v7, (a3)
    add         a3, a3, a4

    vsetivli    zero, 16, e8, m1, ta, ma
    vslideup.vi v0, v1, 8
    vslideup.vi v2, v3, 8
    vslideup.vi v4, v5, 8
    vslideup.vi v6, v7, 8
    uabal       v16, v0, v2, v8, v12
    uabal       v18, v0, v4, v8, v12
    uabal       v20, v0, v6, v8, v12
.endr
    vsetivli    zero, 16, e16, m2, ta, ma
    vmv.s.x     v30, zero
    vredsum.vs  v31, v16, v30
    vmv.x.s     t2, v31
    vredsum.vs  v31, v18, v30
    vmv.x.s     t3, v31
    vredsum.vs  v31, v20, v30
    vmv.x.s     t4, v31

    sw          t2, 0(a5)
    sw          t3, 4(a5)
    sw          t4, 8(a5)
    ret
endfunc

function pixel_sad_x3_8x16_rvv
    li          t0, FENC_STRIDE
    vsetivli    zero, 8, e8, mf2, ta, ma
    vle8.v      v0, (a0)
    add         a0, a0, t0
    vle8.v      v1, (a0)
    add         a0, a0, t0
    vle8.v      v2, (a1)
    add         a1, a1, a4
    vle8.v      v3, (a1)
    add         a1, a1, a4
    vle8.v      v4, (a2)
    add         a2, a2, a4
    vle8.v      v5, (a2)
    add         a2, a2, a4
    vle8.v      v6, (a3)
    add         a3, a3, a4
    vle8.v      v7, (a3)
    add         a3, a3, a4

    vsetivli    zero, 16, e8, m1, ta, ma
    vslideup.vi v0, v1, 8
    vslideup.vi v2, v3, 8
    vslideup.vi v4, v5, 8
    vslideup.vi v6, v7, 8
    uabdl       v16, v0, v2, v8, v12
    uabdl       v18, v0, v4, v8, v12
    uabdl       v20, v0, v6, v8, v12
.rept 7
    vsetivli    zero, 8, e8, mf2, ta, ma
    vle8.v      v0, (a0)
    add         a0, a0, t0
    vle8.v      v1, (a0)
    add         a0, a0, t0
    vle8.v      v2, (a1)
    add         a1, a1, a4
    vle8.v      v3, (a1)
    add         a1, a1, a4
    vle8.v      v4, (a2)
    add         a2, a2, a4
    vle8.v      v5, (a2)
    add         a2, a2, a4
    vle8.v      v6, (a3)
    add         a3, a3, a4
    vle8.v      v7, (a3)
    add         a3, a3, a4

    vsetivli    zero, 16, e8, m1, ta, ma
    vslideup.vi v0, v1, 8
    vslideup.vi v2, v3, 8
    vslideup.vi v4, v5, 8
    vslideup.vi v6, v7, 8
    uabal       v16, v0, v2, v8, v12
    uabal       v18, v0, v4, v8, v12
    uabal       v20, v0, v6, v8, v12
.endr
    vsetivli    zero, 16, e16, m2, ta, ma
    vmv.s.x     v30, zero
    vredsum.vs  v31, v16, v30
    vmv.x.s     t2, v31
    vredsum.vs  v31, v18, v30
    vmv.x.s     t3, v31
    vredsum.vs  v31, v20, v30
    vmv.x.s     t4, v31

    sw          t2, 0(a5)
    sw          t3, 4(a5)
    sw          t4, 8(a5)
    ret
endfunc

function pixel_sad_x3_16x8_rvv
    li          t0, FENC_STRIDE
    vsetivli    zero, 16, e8, m1, ta, ma
    vle8.v      v0, (a0)
    add         a0, a0, t0
    vle8.v      v1, (a0)
    add         a0, a0, t0

    vle8.v      v2, (a1)
    add         a1, a1, a4
    vle8.v      v3, (a1)
    add         a1, a1, a4
    uabdl       v16, v0, v2, v8, v12
    uabal       v16, v1, v3, v10, v14
    vle8.v      v4, (a2)
    add         a2, a2, a4
    vle8.v      v5, (a2)
    add         a2, a2, a4
    uabdl       v18, v0, v4, v8, v12
    uabal       v18, v1, v5, v10, v14
    vle8.v      v6, (a3)
    add         a3, a3, a4
    vle8.v      v7, (a3)
    add         a3, a3, a4
    uabdl       v20, v0, v6, v8, v12
    uabal       v20, v1, v7, v10, v14

 .rept 3
    vle8.v      v0, (a0)
    add         a0, a0, t0
    vle8.v      v1, (a0)
    add         a0, a0, t0

    vle8.v      v2, (a1)
    add         a1, a1, a4
    vle8.v      v3, (a1)
    add         a1, a1, a4
    uabal       v16, v0, v2, v8, v12
    uabal       v16, v1, v3, v10, v14
    vle8.v      v4, (a2)
    add         a2, a2, a4
    vle8.v      v5, (a2)
    add         a2, a2, a4
    uabal       v18, v0, v4, v8, v12
    uabal       v18, v1, v5, v10, v14
    vle8.v      v6, (a3)
    add         a3, a3, a4
    vle8.v      v7, (a3)
    add         a3, a3, a4
    uabal       v20, v0, v6, v8, v12
    uabal       v20, v1, v7, v10, v14
.endr
vsetivli    zero, 16, e16, m2, ta, ma
    vmv.s.x     v30, zero
    vredsum.vs  v31, v16, v30
    vmv.x.s     t2, v31
    vredsum.vs  v31, v18, v30
    vmv.x.s     t3, v31
    vredsum.vs  v31, v20, v30
    vmv.x.s     t4, v31

    sw          t2, 0(a5)
    sw          t3, 4(a5)
    sw          t4, 8(a5)
    ret
endfunc

function pixel_sad_x3_16x16_rvv
    li          t0, FENC_STRIDE
    vsetivli    zero, 16, e8, m1, ta, ma
    vle8.v      v0, (a0)
    add         a0, a0, t0
    vle8.v      v1, (a0)
    add         a0, a0, t0

    vle8.v      v2, (a1)
    add         a1, a1, a4
    vle8.v      v3, (a1)
    add         a1, a1, a4
    uabdl       v16, v0, v2, v8, v12
    uabal       v16, v1, v3, v10, v14
    vle8.v      v4, (a2)
    add         a2, a2, a4
    vle8.v      v5, (a2)
    add         a2, a2, a4
    uabdl       v18, v0, v4, v8, v12
    uabal       v18, v1, v5, v10, v14
    vle8.v      v6, (a3)
    add         a3, a3, a4
    vle8.v      v7, (a3)
    add         a3, a3, a4
    uabdl       v20, v0, v6, v8, v12
    uabal       v20, v1, v7, v10, v14

 .rept 7
    vle8.v      v0, (a0)
    add         a0, a0, t0
    vle8.v      v1, (a0)
    add         a0, a0, t0

    vle8.v      v2, (a1)
    add         a1, a1, a4
    vle8.v      v3, (a1)
    add         a1, a1, a4
    uabal       v16, v0, v2, v8, v12
    uabal       v16, v1, v3, v10, v14
    vle8.v      v4, (a2)
    add         a2, a2, a4
    vle8.v      v5, (a2)
    add         a2, a2, a4
    uabal       v18, v0, v4, v8, v12
    uabal       v18, v1, v5, v10, v14
    vle8.v      v6, (a3)
    add         a3, a3, a4
    vle8.v      v7, (a3)
    add         a3, a3, a4
    uabal       v20, v0, v6, v8, v12
    uabal       v20, v1, v7, v10, v14
.endr
    vsetivli    zero, 16, e16, m2, ta, ma
    vmv.s.x     v30, zero
    vredsum.vs  v31, v16, v30
    vmv.x.s     t2, v31
    vredsum.vs  v31, v18, v30
    vmv.x.s     t3, v31
    vredsum.vs  v31, v20, v30
    vmv.x.s     t4, v31

    sw          t2, 0(a5)
    sw          t3, 4(a5)
    sw          t4, 8(a5)
    ret    
endfunc

// SAD_X4 functions

// RISC-V RVV implementation of SAD for 4x4 blocks with 4 predictions
function pixel_sad_x4_4x4_rvv
    li          t0, FENC_STRIDE
    
    // --- Process first two rows of all 4 predictions ---
    vsetivli    zero, 4, e8, mf4, ta, ma
    // Load source rows 0-1
    vle8.v      v0, (a0)                 // src row0
    add         a0, a0, t0
    vle8.v      v1, (a0)                 // src row1
    add         a0, a0, t0
    
    // Load prediction 0 rows 0-1
    vle8.v      v2, (a1)                 // pred0 row0
    add         a1, a1, a5               // pred0 stride
    vle8.v      v3, (a1)                 // pred0 row1
    add         a1, a1, a5
    
    // Load prediction 1 rows 0-1
    vle8.v      v4, (a2)                 // pred1 row0
    add         a2, a2, a5               // pred1 stride
    vle8.v      v5, (a2)                 // pred1 row1
    add         a2, a2, a5
    
    // Load prediction 2 rows 0-1
    vle8.v      v6, (a3)                 // pred2 row0
    add         a3, a3, a5               // pred2 stride
    vle8.v      v7, (a3)                 // pred2 row1
    add         a3, a3, a5
    
    // Load prediction 3 rows 0-1
    vle8.v      v8, (a4)                 // pred3 row0
    add         a4, a4, a5               // pred3 stride
    vle8.v      v9, (a4)                 // pred3 row1
    add         a4, a4, a5

    // Combine each pair of rows into 8-element vectors
    vsetivli    zero, 8, e8, mf2, ta, ma
    vslideup.vi v0, v1, 4
    vslideup.vi v2, v3, 4
    vslideup.vi v4, v5, 4
    vslideup.vi v6, v7, 4
    vslideup.vi v8, v9, 4

    // Initial SAD calculations (first 2 rows)
    uabdl       v16, v0, v2, v10, v12
    uabdl       v18, v0, v4, v10, v12
    uabdl       v20, v0, v6, v10, v12
    uabdl       v22, v0, v8, v10, v12

    // --- Process last two rows of all 4 predictions ---
    vsetivli    zero, 4, e8, mf4, ta, ma
    vle8.v      v0, (a0)
    add         a0, a0, t0
    vle8.v      v1, (a0)
    add         a0, a0, t0
    vle8.v      v2, (a1)
    add         a1, a1, a5
    vle8.v      v3, (a1)
    add         a1, a1, a5
    vle8.v      v4, (a2)
    add         a2, a2, a5
    vle8.v      v5, (a2)
    add         a2, a2, a5
    vle8.v      v6, (a3)
    add         a3, a3, a5
    vle8.v      v7, (a3)
    add         a3, a3, a5
    vle8.v      v8, (a4)
    add         a4, a4, a5
    vle8.v      v9, (a4)
    add         a4, a4, a5

    vsetivli    zero, 8, e8, mf2, ta, ma
    vslideup.vi v0, v1, 4
    vslideup.vi v2, v3, 4
    vslideup.vi v4, v5, 4
    vslideup.vi v6, v7, 4
    vslideup.vi v8, v9, 4
    uabal       v16, v0, v2, v10, v12
    uabal       v18, v0, v4, v10, v12
    uabal       v20, v0, v6, v10, v12
    uabal       v22, v0, v8, v10, v12

    // --- Sum results to scalars ---
    vsetivli    zero, 8, e16, m1, ta, ma
    vmv.s.x     v30, zero
    vredsum.vs  v31, v16, v30
    vmv.x.s     t2, v31
    vredsum.vs  v31, v18, v30
    vmv.x.s     t3, v31
    vredsum.vs  v31, v20, v30
    vmv.x.s     t4, v31
    vredsum.vs  v31, v22, v30
    vmv.x.s     t5, v31

    sw          t2, 0(a6)
    sw          t3, 4(a6)
    sw          t4, 8(a6)
    sw          t5, 12(a6)
    ret
endfunc

function pixel_sad_x4_4x8_rvv
    li          t0, FENC_STRIDE
    vsetivli    zero, 4, e8, mf4, ta, ma
    vle8.v      v0, (a0)
    add         a0, a0, t0
    vle8.v      v1, (a0)
    add         a0, a0, t0
    vle8.v      v2, (a1)
    add         a1, a1, a5
    vle8.v      v3, (a1)
    add         a1, a1, a5
    vle8.v      v4, (a2)
    add         a2, a2, a5
    vle8.v      v5, (a2)
    add         a2, a2, a5
    vle8.v      v6, (a3)
    add         a3, a3, a5
    vle8.v      v7, (a3)
    add         a3, a3, a5
    vle8.v      v8, (a4)
    add         a4, a4, a5
    vle8.v      v9, (a4)
    add         a4, a4, a5

    vsetivli    zero, 8, e8, mf2, ta, ma
    vslideup.vi v0, v1, 4
    vslideup.vi v2, v3, 4
    vslideup.vi v4, v5, 4
    vslideup.vi v6, v7, 4
    vslideup.vi v8, v9, 4
    uabdl       v16, v0, v2, v10, v12
    uabdl       v18, v0, v4, v10, v12
    uabdl       v20, v0, v6, v10, v12
    uabdl       v22, v0, v8, v10, v12
.rept 3
    vsetivli    zero, 4, e8, mf4, ta, ma
    vle8.v      v0, (a0)
    add         a0, a0, t0
    vle8.v      v1, (a0)
    add         a0, a0, t0
    vle8.v      v2, (a1)
    add         a1, a1, a5
    vle8.v      v3, (a1)
    add         a1, a1, a5
    vle8.v      v4, (a2)
    add         a2, a2, a5
    vle8.v      v5, (a2)
    add         a2, a2, a5
    vle8.v      v6, (a3)
    add         a3, a3, a5
    vle8.v      v7, (a3)
    add         a3, a3, a5
    vle8.v      v8, (a4)
    add         a4, a4, a5
    vle8.v      v9, (a4)
    add         a4, a4, a5

    vsetivli    zero, 8, e8, mf2, ta, ma
    vslideup.vi v0, v1, 4
    vslideup.vi v2, v3, 4
    vslideup.vi v4, v5, 4
    vslideup.vi v6, v7, 4
    vslideup.vi v8, v9, 4
    uabal       v16, v0, v2, v10, v12
    uabal       v18, v0, v4, v10, v12
    uabal       v20, v0, v6, v10, v12
    uabal       v22, v0, v8, v10, v12
.endr
    vsetivli    zero, 8, e16, m1, ta, ma
    vmv.s.x     v30, zero
    vredsum.vs  v31, v16, v30
    vmv.x.s     t2, v31
    vredsum.vs  v31, v18, v30
    vmv.x.s     t3, v31
    vredsum.vs  v31, v20, v30
    vmv.x.s     t4, v31
    vredsum.vs  v31, v22, v30
    vmv.x.s     t5, v31

    sw          t2, 0(a6)
    sw          t3, 4(a6)
    sw          t4, 8(a6)
    sw          t5, 12(a6)
    ret
endfunc

function pixel_sad_x4_8x4_rvv
    li          t0, FENC_STRIDE
    vsetivli    zero, 8, e8, mf2, ta, ma
    vle8.v      v0, (a0)
    add         a0, a0, t0
    vle8.v      v1, (a0)
    add         a0, a0, t0
    vle8.v      v2, (a1)
    add         a1, a1, a5
    vle8.v      v3, (a1)
    add         a1, a1, a5
    vle8.v      v4, (a2)
    add         a2, a2, a5
    vle8.v      v5, (a2)
    add         a2, a2, a5
    vle8.v      v6, (a3)
    add         a3, a3, a5
    vle8.v      v7, (a3)
    add         a3, a3, a5
    vle8.v      v8, (a4)
    add         a4, a4, a5
    vle8.v      v9, (a4)
    add         a4, a4, a5

    vsetivli    zero, 16, e8, m1, ta, ma
    vslideup.vi v0, v1, 8
    vslideup.vi v2, v3, 8
    vslideup.vi v4, v5, 8
    vslideup.vi v6, v7, 8
    vslideup.vi v8, v9, 8
    uabdl       v16, v0, v2, v10, v12
    uabdl       v18, v0, v4, v10, v12
    uabdl       v20, v0, v6, v10, v12
    uabdl       v22, v0, v8, v10, v12

    vsetivli    zero, 8, e8, mf2, ta, ma
    vle8.v      v0, (a0)
    add         a0, a0, t0
    vle8.v      v1, (a0)
    add         a0, a0, t0
    vle8.v      v2, (a1)
    add         a1, a1, a5
    vle8.v      v3, (a1)
    add         a1, a1, a5
    vle8.v      v4, (a2)
    add         a2, a2, a5
    vle8.v      v5, (a2)
    add         a2, a2, a5
    vle8.v      v6, (a3)
    add         a3, a3, a5
    vle8.v      v7, (a3)
    add         a3, a3, a5
    vle8.v      v8, (a4)
    add         a4, a4, a5
    vle8.v      v9, (a4)
    add         a4, a4, a5

    vsetivli    zero, 16, e8, m1, ta, ma
    vslideup.vi v0, v1, 8
    vslideup.vi v2, v3, 8
    vslideup.vi v4, v5, 8
    vslideup.vi v6, v7, 8
    vslideup.vi v8, v9, 8
    uabal       v16, v0, v2, v10, v12
    uabal       v18, v0, v4, v10, v12
    uabal       v20, v0, v6, v10, v12
    uabal       v22, v0, v8, v10, v12
    vsetivli    zero, 16, e16, m2, ta, ma
    vmv.s.x     v30, zero
    vredsum.vs  v31, v16, v30
    vmv.x.s     t2, v31
    vredsum.vs  v31, v18, v30
    vmv.x.s     t3, v31
    vredsum.vs  v31, v20, v30
    vmv.x.s     t4, v31
    vredsum.vs  v31, v22, v30
    vmv.x.s     t5, v31

    sw          t2, 0(a6)
    sw          t3, 4(a6)
    sw          t4, 8(a6)
    sw          t5, 12(a6)
    ret
endfunc

function pixel_sad_x4_8x8_rvv
    li          t0, FENC_STRIDE

    vsetivli    zero, 8, e8, mf2, ta, ma
    vle8.v      v0, (a0)
    add         a0, a0, t0
    vle8.v      v1, (a0)
    add         a0, a0, t0

    vle8.v      v2, (a1)
    add         a1, a1, a5
    vle8.v      v3, (a1)
    add         a1, a1, a5

    vle8.v      v4, (a2)
    add         a2, a2, a5
    vle8.v      v5, (a2)
    add         a2, a2, a5

    vle8.v      v6, (a3)
    add         a3, a3, a5
    vle8.v      v7, (a3)
    add         a3, a3, a5

    vle8.v      v8, (a4)
    add         a4, a4, a5
    vle8.v      v9, (a4)
    add         a4, a4, a5

    vsetivli    zero, 16, e8, m1, ta, ma
    vslideup.vi v0, v1, 8
    vslideup.vi v2, v3, 8
    vslideup.vi v4, v5, 8
    vslideup.vi v6, v7, 8
    vslideup.vi v8, v9, 8
    uabdl       v16, v0, v2, v10, v12
    uabdl       v18, v0, v4, v10, v12
    uabdl       v20, v0, v6, v10, v12
    uabdl       v22, v0, v8, v10, v12
.rept 3
    vsetivli    zero, 8, e8, mf2, ta, ma
    vle8.v      v0, (a0)
    add         a0, a0, t0
    vle8.v      v1, (a0)
    add         a0, a0, t0

    vle8.v      v2, (a1)
    add         a1, a1, a5
    vle8.v      v3, (a1)
    add         a1, a1, a5

    vle8.v      v4, (a2)
    add         a2, a2, a5
    vle8.v      v5, (a2)
    add         a2, a2, a5

    vle8.v      v6, (a3)
    add         a3, a3, a5
    vle8.v      v7, (a3)
    add         a3, a3, a5

    vle8.v      v8, (a4)
    add         a4, a4, a5
    vle8.v      v9, (a4)
    add         a4, a4, a5

    vsetivli    zero, 16, e8, m1, ta, ma
    vslideup.vi v0, v1, 8
    vslideup.vi v2, v3, 8
    vslideup.vi v4, v5, 8
    vslideup.vi v6, v7, 8
    vslideup.vi v8, v9, 8
    uabal       v16, v0, v2, v10, v12
    uabal       v18, v0, v4, v10, v12
    uabal       v20, v0, v6, v10, v12
    uabal       v22, v0, v8, v10, v12
.endr
    vsetivli    zero, 16, e16, m2, ta, ma
    vmv.s.x     v30, zero
    vredsum.vs  v31, v16, v30
    vmv.x.s     t2, v31
    vredsum.vs  v31, v18, v30
    vmv.x.s     t3, v31
    vredsum.vs  v31, v20, v30
    vmv.x.s     t4, v31
    vredsum.vs  v31, v22, v30
    vmv.x.s     t5, v31

    sw          t2, 0(a6)
    sw          t3, 4(a6)
    sw          t4, 8(a6)
    sw          t5, 12(a6)
    ret
endfunc

function pixel_sad_x4_8x16_rvv
    li          t0, FENC_STRIDE
    vsetivli    zero, 8, e8, mf2, ta, ma
    vle8.v      v0, (a0)
    add         a0, a0, t0
    vle8.v      v1, (a0)
    add         a0, a0, t0
    vle8.v      v2, (a1)
    add         a1, a1, a5
    vle8.v      v3, (a1)
    add         a1, a1, a5
    vle8.v      v4, (a2)
    add         a2, a2, a5
    vle8.v      v5, (a2)
    add         a2, a2, a5
    vle8.v      v6, (a3)
    add         a3, a3, a5
    vle8.v      v7, (a3)
    add         a3, a3, a5
    vle8.v      v8, (a4)
    add         a4, a4, a5
    vle8.v      v9, (a4)
    add         a4, a4, a5

    vsetivli    zero, 16, e8, m1, ta, ma
    vslideup.vi v0, v1, 8
    vslideup.vi v2, v3, 8
    vslideup.vi v4, v5, 8
    vslideup.vi v6, v7, 8
    vslideup.vi v8, v9, 8
    uabdl       v16, v0, v2, v10, v12
    uabdl       v18, v0, v4, v10, v12
    uabdl       v20, v0, v6, v10, v12
    uabdl       v22, v0, v8, v10, v12
.rept 7
    vsetivli    zero, 8, e8, mf2, ta, ma
    vle8.v      v0, (a0)
    add         a0, a0, t0
    vle8.v      v1, (a0)
    add         a0, a0, t0
    vle8.v      v2, (a1)
    add         a1, a1, a5
    vle8.v      v3, (a1)
    add         a1, a1, a5
    vle8.v      v4, (a2)
    add         a2, a2, a5
    vle8.v      v5, (a2)
    add         a2, a2, a5
    vle8.v      v6, (a3)
    add         a3, a3, a5
    vle8.v      v7, (a3)
    add         a3, a3, a5
    vle8.v      v8, (a4)
    add         a4, a4, a5
    vle8.v      v9, (a4)
    add         a4, a4, a5

    vsetivli    zero, 16, e8, m1, ta, ma
    vslideup.vi v0, v1, 8
    vslideup.vi v2, v3, 8
    vslideup.vi v4, v5, 8
    vslideup.vi v6, v7, 8
    vslideup.vi v8, v9, 8
    uabal       v16, v0, v2, v10, v12
    uabal       v18, v0, v4, v10, v12
    uabal       v20, v0, v6, v10, v12
    uabal       v22, v0, v8, v10, v12
.endr
    vsetivli    zero, 16, e16, m2, ta, ma
    vmv.s.x     v30, zero
    vredsum.vs  v31, v16, v30
    vmv.x.s     t2, v31
    vredsum.vs  v31, v18, v30
    vmv.x.s     t3, v31
    vredsum.vs  v31, v20, v30
    vmv.x.s     t4, v31
    vredsum.vs  v31, v22, v30
    vmv.x.s     t5, v31

    sw          t2, 0(a6)
    sw          t3, 4(a6)
    sw          t4, 8(a6)
    sw          t5, 12(a6)
    ret
endfunc

function pixel_sad_x4_16x8_rvv
    li          t0, FENC_STRIDE
    vsetivli    zero, 16, e8, m1, ta, ma
    vle8.v      v0, (a0)
    add         a0, a0, t0
    vle8.v      v1, (a0)
    add         a0, a0, t0
    vle8.v      v2, (a1)
    add         a1, a1, a5
    vle8.v      v3, (a1)
    add         a1, a1, a5
    uabdl       v16, v0, v2, v10, v12
    uabal       v16, v1, v3, v11, v13

    vle8.v      v4, (a2)
    add         a2, a2, a5
    vle8.v      v5, (a2)
    add         a2, a2, a5
    uabdl       v18, v0, v4, v10, v12
    uabal       v18, v1, v5, v11, v13

    vle8.v      v6, (a3)
    add         a3, a3, a5
    vle8.v      v7, (a3)
    add         a3, a3, a5
    uabdl       v20, v0, v6, v10, v12
    uabal       v20, v1, v7, v11, v13

    vle8.v      v8, (a4)
    add         a4, a4, a5
    vle8.v      v9, (a4)
    add         a4, a4, a5
    uabdl       v22, v0, v8, v10, v12
    uabal       v22, v1, v9, v11, v13

 .rept 3
    vle8.v      v0, (a0)
    add         a0, a0, t0
    vle8.v      v1, (a0)
    add         a0, a0, t0
    vle8.v      v2, (a1)
    add         a1, a1, a5
    vle8.v      v3, (a1)
    add         a1, a1, a5
    uabal       v16, v0, v2, v10, v12
    uabal       v16, v1, v3, v11, v13
    
    vle8.v      v4, (a2)
    add         a2, a2, a5
    vle8.v      v5, (a2)
    add         a2, a2, a5
    uabal       v18, v0, v4, v10, v12
    uabal       v18, v1, v5, v11, v13

    vle8.v      v6, (a3)
    add         a3, a3, a5
    vle8.v      v7, (a3)
    add         a3, a3, a5
    uabal       v20, v0, v6, v10, v12
    uabal       v20, v1, v7, v11, v13

    vle8.v      v8, (a4)
    add         a4, a4, a5
    vle8.v      v9, (a4)
    add         a4, a4, a5
    uabal       v22, v0, v8, v10, v12
    uabal       v22, v1, v9, v11, v13
.endr
    vsetivli    zero, 16, e16, m2, ta, ma
    vmv.s.x     v30, zero
    vredsum.vs  v31, v16, v30
    vmv.x.s     t2, v31
    vredsum.vs  v31, v18, v30
    vmv.x.s     t3, v31
    vredsum.vs  v31, v20, v30
    vmv.x.s     t4, v31
    vredsum.vs  v31, v22, v30
    vmv.x.s     t5, v31

    sw          t2, 0(a6)
    sw          t3, 4(a6)
    sw          t4, 8(a6)
    sw          t5, 12(a6)
    ret
endfunc

function pixel_sad_x4_16x16_rvv
    li          t0, FENC_STRIDE
    vsetivli    zero, 16, e8, m1, ta, ma
    vle8.v      v0, (a0)
    add         a0, a0, t0
    vle8.v      v1, (a0)
    add         a0, a0, t0
    vle8.v      v2, (a1)
    add         a1, a1, a5
    vle8.v      v3, (a1)
    add         a1, a1, a5
    uabdl       v16, v0, v2, v10, v12
    uabal       v16, v1, v3, v11, v13

    vle8.v      v4, (a2)
    add         a2, a2, a5
    vle8.v      v5, (a2)
    add         a2, a2, a5
    uabdl       v18, v0, v4, v10, v12
    uabal       v18, v1, v5, v11, v13

    vle8.v      v6, (a3)
    add         a3, a3, a5
    vle8.v      v7, (a3)
    add         a3, a3, a5
    uabdl       v20, v0, v6, v10, v12
    uabal       v20, v1, v7, v11, v13

    vle8.v      v8, (a4)
    add         a4, a4, a5
    vle8.v      v9, (a4)
    add         a4, a4, a5
    uabdl       v22, v0, v8, v10, v12
    uabal       v22, v1, v9, v11, v13

 .rept 7
    vle8.v      v0, (a0)
    add         a0, a0, t0
    vle8.v      v1, (a0)
    add         a0, a0, t0
    vle8.v      v2, (a1)
    add         a1, a1, a5
    vle8.v      v3, (a1)
    add         a1, a1, a5
    uabal       v16, v0, v2, v10, v12
    uabal       v16, v1, v3, v11, v13
    
    vle8.v      v4, (a2)
    add         a2, a2, a5
    vle8.v      v5, (a2)
    add         a2, a2, a5
    uabal       v18, v0, v4, v10, v12
    uabal       v18, v1, v5, v11, v13

    vle8.v      v6, (a3)
    add         a3, a3, a5
    vle8.v      v7, (a3)
    add         a3, a3, a5
    uabal       v20, v0, v6, v10, v12
    uabal       v20, v1, v7, v11, v13

    vle8.v      v8, (a4)
    add         a4, a4, a5
    vle8.v      v9, (a4)
    add         a4, a4, a5
    uabal       v22, v0, v8, v10, v12
    uabal       v22, v1, v9, v11, v13
.endr
    vsetivli    zero, 16, e16, m2, ta, ma
    vmv.s.x     v30, zero
    vredsum.vs  v31, v16, v30
    vmv.x.s     t2, v31
    vredsum.vs  v31, v18, v30
    vmv.x.s     t3, v31
    vredsum.vs  v31, v20, v30
    vmv.x.s     t4, v31
    vredsum.vs  v31, v22, v30
    vmv.x.s     t5, v31

    sw          t2, 0(a6)
    sw          t3, 4(a6)
    sw          t4, 8(a6)
    sw          t5, 12(a6)
    ret
endfunc

// SSD functions

function pixel_ssd_4x4_rvv
    vsetivli    zero, 4, e32, m1, ta, ma
    vlse32.v    v0, (a0), a1
    vlse32.v    v4, (a2), a3
    vsetivli    zero, 16, e8, m1, ta, ma
    vwsubu.vv   v16, v0, v4
    vsetivli    zero, 16, e16, m2, ta, ma
    vwmul.vv    v20, v16, v16
    vsetivli    zero, 16, e32, m4, ta, ma
    vmv.s.x     v31, zero
    vredsum.vs  v31, v20, v31
    vmv.x.s     a0, v31

    ret
endfunc

function pixel_ssd_4x8_rvv
    li          t0, 32
    vsetivli    zero, 8, e32, m2, ta, ma
    vlse32.v    v0, (a0), a1
    vlse32.v    v2, (a2), a3
    vsetvli     zero, t0, e8, m2, ta, ma
    vwsubu.vv   v4, v0, v2
    vsetvli     zero, zero, e16, m4, ta, ma
    vwmul.vv    v16, v4, v4
    vsetvli     zero, zero, e32, m8, ta, ma
    vmv.s.x     v31, zero
    vredsum.vs  v31, v16, v31
    vmv.x.s     a0, v31

    ret
endfunc

function pixel_ssd_4x16_rvv
    li          t0, 32
    vsetivli    zero, 8, e32, m2, ta, ma
    vlse32.v    v0, (a0), a1
    vlse32.v    v4, (a2), a3
    slli        t1, a1, 3
    slli        t2, a3, 3
    add         a0, a0, t1
    add         a2, a2, t2
    vlse32.v    v2, (a0), a1
    vlse32.v    v6, (a2), a3
    vsetvli     zero, t0, e8, m2, ta, ma
    vwsubu.vv   v8, v0, v4
    vwsubu.vv   v12, v2, v6
    vsetvli     zero, zero, e16, m4, ta, ma
    vwmul.vv    v16, v8, v8
    vwmacc.vv   v16, v12, v12
    vsetvli     zero, zero, e32, m8, ta, ma
    vmv.s.x     v0, zero
    vredsum.vs  v0, v16, v0
    vmv.x.s     a0, v0
    ret
endfunc

function pixel_ssd_8x4_rvv
    li          t0, 32
    vsetivli    zero, 4, e64, m2, ta, ma
    vlse64.v    v0, (a0), a1
    vlse64.v    v2, (a2), a3
    vsetvli     zero, t0, e8, m2, ta, ma
    vwsubu.vv   v4, v0, v2
    vsetvli     zero, zero, e16, m4, ta, ma
    vwmul.vv    v16, v4, v4
    vsetvli     zero, zero, e32, m8, ta, ma
    vmv.s.x     v31, zero
    vredsum.vs  v31, v16, v31
    vmv.x.s     a0, v31

    ret
endfunc

function pixel_ssd_8x8_rvv
    li          t0, 32
    vsetivli    zero, 4, e64, m2, ta, ma
    vlse64.v    v0, (a0), a1
    vlse64.v    v4, (a2), a3
    slli        t1, a1, 2
    slli        t2, a3, 2
    add         a0, a0, t1
    add         a2, a2, t2
    vlse64.v    v2, (a0), a1
    vlse64.v    v6, (a2), a3

    vsetvli     zero, t0, e8, m2, ta, ma
    vwsubu.vv   v8, v0, v4
    vwsubu.vv   v12, v2, v6
    vsetvli     zero, zero, e16, m4, ta, ma
    vwmul.vv    v16, v8, v8
    vwmacc.vv   v16, v12, v12
    vsetvli     zero, zero, e32, m8, ta, ma
    vmv.s.x     v0, zero
    vredsum.vs  v0, v16, v0
    vmv.x.s     a0, v0
    ret
endfunc

function pixel_ssd_8x16_rvv
    li          t0, 32
    vsetivli    zero, 4, e64, m2, ta, ma
    vlse64.v    v0, (a0), a1
    vlse64.v    v4, (a2), a3
    slli        t1, a1, 2
    slli        t2, a3, 2
    add         a0, a0, t1
    add         a2, a2, t2
    vlse64.v    v2, (a0), a1
    vlse64.v    v6, (a2), a3
    add         a0, a0, t1
    add         a2, a2, t2

    vsetvli     zero, t0, e8, m2, ta, ma
    vwsubu.vv   v8, v0, v4
    vwsubu.vv   v12, v2, v6
    vsetvli     zero, zero, e16, m4, ta, ma
    vwmul.vv    v16, v8, v8
    vwmacc.vv   v16, v12, v12
    vsetvli     zero, zero, e32, m8, ta, ma
    vmv.s.x     v0, zero
    vredsum.vs  v0, v16, v0
    vmv.x.s     t5, v0

    vsetivli    zero, 4, e64, m2, ta, ma
    vlse64.v    v0, (a0), a1
    vlse64.v    v4, (a2), a3
    add         a0, a0, t1
    add         a2, a2, t2
    vlse64.v    v2, (a0), a1
    vlse64.v    v6, (a2), a3

    vsetvli     zero, t0, e8, m2, ta, ma
    vwsubu.vv   v8, v0, v4
    vwsubu.vv   v12, v2, v6
    vsetvli     zero, zero, e16, m4, ta, ma
    vwmul.vv    v16, v8, v8
    vwmacc.vv   v16, v12, v12
    vsetvli     zero, zero, e32, m8, ta, ma
    vmv.s.x     v0, zero
    vredsum.vs  v0, v16, v0
    vmv.x.s     t6, v0

    add         a0, t5, t6
    ret
endfunc

function pixel_ssd_16x8_rvv
    li          t0, 32
    vsetivli    zero, 4, e64, m2, ta, ma
    vlse64.v    v0, (a0), a1
    vlse64.v    v4, (a2), a3
    addi        t1, a0, 8
    addi        t2, a2, 8
    vlse64.v    v2, (t1), a1
    vlse64.v    v6, (t2), a3
    slli        t3, a1, 2
    slli        t4, a3, 2
    add         a0, a0, t3
    add         a2, a2, t4


    vsetvli     zero, t0, e8, m2, ta, ma
    vwsubu.vv   v8, v0, v4
    vwsubu.vv   v12, v2, v6
    vsetvli     zero, zero, e16, m4, ta, ma
    vwmul.vv    v16, v8, v8
    vwmacc.vv   v16, v12, v12
    vsetvli     zero, zero, e32, m8, ta, ma
    vmv.s.x     v0, zero
    vredsum.vs  v0, v16, v0
    vmv.x.s     t5, v0

    vsetivli    zero, 4, e64, m2, ta, ma
    vlse64.v    v0, (a0), a1
    vlse64.v    v4, (a2), a3
    addi        t1, a0, 8
    addi        t2, a2, 8
    vlse64.v    v2, (t1), a1
    vlse64.v    v6, (t2), a3

    vsetvli     zero, t0, e8, m2, ta, ma
    vwsubu.vv   v8, v0, v4
    vwsubu.vv   v12, v2, v6
    vsetvli     zero, zero, e16, m4, ta, ma
    vwmul.vv    v16, v8, v8
    vwmacc.vv   v16, v12, v12
    vsetvli     zero, zero, e32, m8, ta, ma
    vmv.s.x     v0, zero
    vredsum.vs  v0, v16, v0
    vmv.x.s     t6, v0

    add         a0, t5, t6
    ret
endfunc

function pixel_ssd_16x16_rvv
    li          t0, 32
    vsetivli    zero, 4, e64, m2, ta, ma
    vlse64.v    v0, (a0), a1
    vlse64.v    v4, (a2), a3
    slli        t1, a1, 2
    slli        t2, a3, 2
    add         t3, a0, t1
    add         t4, a2, t2
    vlse64.v    v2, (t3), a1
    vlse64.v    v6, (t4), a3
    add         t3, t3, t1
    add         t4, t4, t2

    vsetvli     zero, t0, e8, m2, ta, ma
    vwsubu.vv   v8, v0, v4
    vwsubu.vv   v12, v2, v6
    vsetvli     zero, zero, e16, m4, ta, ma
    vwmul.vv    v16, v8, v8
    vwmacc.vv   v16, v12, v12
    vsetvli     zero, zero, e32, m8, ta, ma
    vmv.s.x     v0, zero
    vredsum.vs  v0, v16, v0
    vmv.x.s     t5, v0

    vsetivli    zero, 4, e64, m2, ta, ma
    vlse64.v    v0, (t3), a1
    vlse64.v    v4, (t4), a3
    add         t3, t3, t1
    add         t4, t4, t2
    vlse64.v    v2, (t3), a1
    vlse64.v    v6, (t4), a3

    vsetvli     zero, t0, e8, m2, ta, ma
    vwsubu.vv   v8, v0, v4
    vwsubu.vv   v12, v2, v6
    vsetvli     zero, zero, e16, m4, ta, ma
    vwmul.vv    v16, v8, v8
    vwmacc.vv   v16, v12, v12
    vsetvli     zero, zero, e32, m8, ta, ma
    vmv.s.x     v0, zero
    vredsum.vs  v0, v16, v0
    vmv.x.s     t6, v0

    add         a7, t5, t6
    
    addi        a0, a0, 8
    addi        a2, a2, 8

    vsetivli    zero, 4, e64, m2, ta, ma
    vlse64.v    v0, (a0), a1
    vlse64.v    v4, (a2), a3
    add         a0, a0, t1
    add         a2, a2, t2
    vlse64.v    v2, (a0), a1
    vlse64.v    v6, (a2), a3
    add         t3, a0, t1
    add         t4, a2, t2

    vsetvli     zero, t0, e8, m2, ta, ma
    vwsubu.vv   v8, v0, v4
    vwsubu.vv   v12, v2, v6
    vsetvli     zero, zero, e16, m4, ta, ma
    vwmul.vv    v16, v8, v8
    vwmacc.vv   v16, v12, v12
    vsetvli     zero, zero, e32, m8, ta, ma
    vmv.s.x     v0, zero
    vredsum.vs  v0, v16, v0
    vmv.x.s     t5, v0

    vsetivli    zero, 4, e64, m2, ta, ma
    vlse64.v    v0, (t3), a1
    vlse64.v    v4, (t4), a3
    add         t3, t3, t1
    add         t4, t4, t2
    vlse64.v    v2, (t3), a1
    vlse64.v    v6, (t4), a3

    vsetvli     zero, t0, e8, m2, ta, ma
    vwsubu.vv   v8, v0, v4
    vwsubu.vv   v12, v2, v6
    vsetvli     zero, zero, e16, m4, ta, ma
    vwmul.vv    v16, v8, v8
    vwmacc.vv   v16, v12, v12
    vsetvli     zero, zero, e32, m8, ta, ma
    vmv.s.x     v0, zero
    vredsum.vs  v0, v16, v0
    vmv.x.s     t6, v0
    
    add         a0, t5, t6
    add         a0, a0, a7

    ret
endfunc

// VAR functions

function pixel_var_8x8_rvv
    vsetivli    zero, 2, e64, m1, ta, ma
    vmv.v.i     v0, 0        # sum
    vmv.v.i     v1, 0        # sum of squares
    
.rept 4
    vsetivli    zero, 8, e8, mf2, ta, ma
    vle8.v      v16, (a0)
    add         a0, a0, a1
    vle8.v      v17, (a0)
    add         a0, a0, a1

    vwmulu.vv   v24, v16, v16
    vwmulu.vv   v25, v17, v17
    vwaddu.vv   v18, v16, v17
    vsetivli    zero, 8, e16, m1, ta, ma
    vwaddu.vv   v20, v24, v25

    vwredsumu.vs v0, v18, v0
    vsetivli    zero, 8, e32, m2, ta, ma
    vredsum.vs  v1, v20, v1
.endr

    vmv.x.s     t0, v0
    vmv.x.s     t1, v1
    slli        t1, t1, 32
    or          a0, t0, t1

    ret
endfunc

function pixel_var_8x16_rvv
    vsetivli    zero, 2, e64, m1, ta, ma
    vmv.v.i     v0, 0        # sum
    vmv.v.i     v1, 0        # sum of squares
    
.rept 8
    vsetivli    zero, 8, e8, mf2, ta, ma
    vle8.v      v16, (a0)
    add         a0, a0, a1
    vle8.v      v17, (a0)
    add         a0, a0, a1

    vwmulu.vv   v24, v16, v16
    vwmulu.vv   v25, v17, v17
    vwaddu.vv   v18, v16, v17
    vsetivli    zero, 8, e16, m1, ta, ma
    vwaddu.vv   v20, v24, v25

    vwredsumu.vs v0, v18, v0
    vsetivli    zero, 8, e32, m2, ta, ma
    vredsum.vs  v1, v20, v1
.endr

    vmv.x.s     t0, v0
    vmv.x.s     t1, v1
    slli        t1, t1, 32
    or          a0, t0, t1

    ret
endfunc

function pixel_var_16x16_rvv
    vsetivli    zero, 2, e64, m1, ta, ma
    vmv.v.i     v30, 0        # sum
    vmv.v.i     v31, 0        # sum of squares
    
.rept 8
    vsetivli    zero, 16, e8, m1, ta, ma
    vle8.v      v0, (a0)
    add         a0, a0, a1
    vle8.v      v2, (a0)
    add         a0, a0, a1

    vwmulu.vv   v8, v0, v0
    vwmulu.vv   v10, v2, v2
    vwaddu.vv   v16, v0, v2
    vsetivli    zero, 16, e16, m2, ta, ma
    vwaddu.vv   v20, v8, v10

    vwredsumu.vs v30, v16, v30
    vsetivli    zero, 16, e32, m4, ta, ma
    vredsum.vs  v31, v20, v31
.endr

    vmv.x.s     t0, v30
    vmv.x.s     t1, v31
    slli        t1, t1, 32
    or          a0, t0, t1

    ret
endfunc

// VAR2 functions

.macro pixel_var2_8 h
function pixel_var2_8x\h\()_rvv
    vsetivli    zero, 2, e64, m1, ta, ma
    vmv.v.i     v28, 0        # sum_u
    vmv.v.i     v29, 0        # sum_v
    vmv.v.i     v30, 0        # sqr_u
    vmv.v.i     v31, 0        # sqr_v

    vsetivli    zero, 8, e8, mf2, ta, ma
    vle8.v      v16, (a0)
    addi        a0, a0, 8
    vle8.v      v17, (a0)
    addi        a0, a0, 8
    vle8.v      v18, (a1)
    addi        a1, a1, 16
    vle8.v      v19, (a1)
    addi        a1, a1, 16
    li          a5, \h - 2

    vwsubu.vv   v0, v16, v18        # diff_u
    vwsubu.vv   v1, v17, v19        # diff_v

    vle8.v      v16, (a0)
    addi        a0, a0, 8
    vle8.v      v18, (a1)
    addi        a1, a1, 16

    vwsubu.vv   v6, v16, v18
    
    vsetivli    zero, 8, e16, m1, ta, ma
    vwmul.vv    v2, v0, v0
    vwmul.vv    v4, v1, v1

1:
    vsetivli    zero, 8, e8, mf2, ta, ma
    addi        a5, a5, -1
    vle8.v      v17, (a0)
    addi        a0, a0, 8
    vle8.v      v19, (a1)
    addi        a1, a1, 16
    vwsubu.vv   v7, v17, v19

    vsetivli    zero, 8, e16, m1, ta, ma
    vwmacc.vv   v2, v6, v6
    vadd.vv     v0, v0, v6
    vle8.v      v16, (a0)
    addi        a0, a0, 8
    vle8.v      v18, (a1)
    addi        a1, a1, 16
    vwmacc.vv   v4, v7, v7
    vadd.vv     v1, v1, v7

    vsetivli    zero, 8, e8, mf2, ta, ma
    vwsubu.vv   v6, v16, v18
    bgtz        a5, 1b

    vle8.v      v17, (a0)
    addi        a0, a0, 8
    vle8.v      v19, (a1)
    addi        a1, a1, 16
    vwsubu.vv   v7, v17, v19

    vsetivli    zero, 8, e16, m1, ta, ma
    vwmacc.vv   v2, v6, v6
    vwmacc.vv   v4, v7, v7
    vadd.vv     v0, v0, v6
    vadd.vv     v1, v1, v7

    vwredsum.vs v28, v0, v28
    vwredsum.vs v29, v1, v29

    vsetivli    zero, 8, e32, m2, ta, ma
    vredsum.vs  v30, v2, v30
    vredsum.vs  v31, v4, v31

    vmv.x.s     t0, v28
    vmv.x.s     t1, v29
    vmv.x.s     t2, v30
    vmv.x.s     t3, v31

    sw          t0, (a2)
    sw          t1, 4(a2)

    mul         t0, t0, t0
    mul         t1, t1, t1

    srli        t4, t0, 6 + (\h >> 4)
    srli        t5, t1, 6 + (\h >> 4)
    sub         a0, t2, t4
    sub         a1, t3, t5
    add         a0, a0, a1
    sw          t2, (a2)
    sw          t3, 4(a2)

    ret
endfunc
.endm

pixel_var2_8  8
pixel_var2_8 16


function pixel_vsad_rvv
    vsetivli    zero, 16, e8, m1, ta, ma
    addi        a2, a2, -2
    vle8.v      v0, (a0)
    add         a0, a0, a1
    vle8.v      v1, (a0)
    add         a0, a0, a1
    uabdl       v6, v0, v1, v8, v9
    ble         a2, zero, 2f

1:
    addi        a2, a2, -2
    vle8.v      v0, (a0)
    add         a0, a0, a1
    uabal       v6, v1, v0, v8, v9
    vle8.v      v1, (a0)
    add         a0, a0, a1
    blt         a2, zero, 2f
    uabal       v6, v0, v1, v8, v9
    bgt         a2, zero, 1b
2:
    vsetvli     zero, zero, e32, m4, ta, ma
    vmv.s.x     v16, zero
    vsetivli    zero, 16, e16, m2, ta, ma
    vwredsumu.vs  v16, v6, v16
    vsetvli     zero, zero, e32, m4, ta, ma
    vmv.x.s     a0, v16
    ret
endfunc

function pixel_asd8_rvv
    addi        a4, a4, -2
    vsetivli    zero, 8, e8, mf2, ta, ma
    vle8.v      v0, (a0)
    add         a0, a0, a1
    vle8.v      v1, (a2)
    add         a2, a2, a3
    vle8.v      v2, (a0)
    add         a0, a0, a1
    vle8.v      v3, (a2)
    add         a2, a2, a3
    vwsubu.vv   v16, v0, v1
1:
    vsetivli    zero, 8, e8, mf2, ta, ma
    addi        a4, a4, -2
    vle8.v      v4, (a0)
    add         a0, a0, a1
    vle8.v      v5, (a2)
    add         a2, a2, a3
    vwsubu.vv   v17, v2, v3
    vwsubu.vv   v18, v4, v5
    vsetivli    zero, 8, e16, m1, ta, ma
    vadd.vv     v16, v16, v17
    vsetivli    zero, 8, e8, mf2, ta, ma
    vle8.v      v2, (a0)
    add         a0, a0, a1
    vle8.v      v3, (a2)
    add         a2, a2, a3
    vsetivli    zero, 8, e16, m1, ta, ma
    vadd.vv     v16, v16, v18
    bgtz        a4, 1b
    
    vsetivli    zero, 8, e8, mf2, ta, ma
    vwsubu.vv   v17, v2, v3
    vsetivli    zero, 8, e16, m1, ta, ma
    vadd.vv     v16, v16, v17

    vsetvli     zero, zero, e32, m2, ta, ma
    vmv.s.x     v30, zero
    vsetivli    zero, 8, e16, m1, ta, ma
    vwredsum.vs v30, v16, v30
    vsetivli     zero, 1, e32, mf2, ta, ma
    vmv.x.s     a5, v30
    sraiw   a0, a5, 31
    xor     a5, a5, a0
    subw    a0, a5, a0

    ret
endfunc

// SATD functions

.macro vtrn_8h d0, d1, s0, s1, t0, t1, t2
    vsetivli        zero, 4, e32, m1, ta, ma
    vsll.vi         \t2, \s0, 16
    vsrl.vi         \t1, \s1, 16
    vsrl.vi         \t0, \s0, 16
    vsll.vi         \d0, \s1, 16
    vsll.vi         \d1, \t1, 16
    vsrl.vi         \t2, \t2, 16
    vsetivli        zero, 8, e16, m1, ta, ma
    vor.vv          \d0, \d0, \t2
    vor.vv          \d1, \d1, \t0
.endm
.macro vtrn_4s d0, d1, s0, s1, t0, t1, t2, t3
    vsetivli        zero, 2, e64, m1, ta, ma
    li              \t3, 32
    vsll.vx         \t2, \s0, \t3
    vsrl.vx         \t1, \s1, \t3
    vsrl.vx         \t0, \s0, \t3
    vsll.vx         \d0, \s1, \t3
    vsll.vx         \d1, \t1, \t3
    vsrl.vx         \t2, \t2, \t3
    vsetivli        zero, 4, e32, m1, ta, ma
    vor.vv          \d0, \d0, \t2
    vor.vv          \d1, \d1, \t0
.endm

function pixel_satd_4x4_rvv
    vsetivli    zero, 4, e8, mf2, ta, ma
    vle8.v      v1, (a2)
    add         a2, a2, a3
    vle8.v      v28, (a0)
    add         a0, a0, a1
    vle8.v      v3, (a2)
    add         a2, a2, a3
    vle8.v      v2, (a0)
    add         a0, a0, a1
    vle8.v      v10, (a2)
    add         a2, a2, a3
    vle8.v      v8, (a0)
    add         a0, a0, a1
    vle8.v      v11, (a2)
    add         a2, a2, a3
    vle8.v      v9, (a0)
    add         a0, a0, a1
    vsetivli    zero, 2, e32, mf2, ta, ma
    vslideup.vi v1, v10, 1
    vslideup.vi v28, v8, 1
    vslideup.vi v3, v11, 1
    vslideup.vi v2, v9, 1

    vsetivli    zero, 8, e8, mf2, ta, ma
    vwsubu.vv   v8, v28, v1
    vwsubu.vv   v10, v2, v3

    vsetvli     zero, zero, e16, m1, ta, ma
    SUMSUB_AB   v2, v3, v8, v10
    vmv1r.v     v28, v2
    vslideup.vi v28, v3, 4
    vmv1r.v     v1, v3
    vsetivli    zero, 4, e16, m1, tu, ma
    vslidedown.vi v1, v2, 4

    vsetivli    zero, 8, e16, m1, ta, mu
    SUMSUB_AB   v2, v3, v28, v1

    // vtrn_8h     v28, v1, v2, v3, v8, v9, v10
    li t0, 0xaaaaaaaa
    vmv.v.x v0, t0
    vmv.v.v       v28, v2
    vslideup.vi   v28, v3, 1, v0.t
    vmnot.m v0,v0
    vmv.v.v       v1, v3
    vslidedown.vi   v1, v2, 1, v0.t

    SUMSUB_AB   v2, v3, v28, v1   
    
    // vtrn_4s     v28, v1, v2, v3, v8, v9, v10, t5
    vsetivli        zero, 4, e32, m1, ta, mu
    vmnot.m v0,v0
    vmv.v.v       v28, v2
    vslideup.vi   v28, v3, 1, v0.t
    vmnot.m v0,v0
    vmv.v.v       v1, v3
    vslidedown.vi   v1, v2, 1, v0.t
    
    vsetivli    zero, 8, e16, m1, ta, ma
    vabs        v28, v28, v8
    vabs        v1, v1, v8
    vmaxu.vv    v28, v28, v1

    vmv.s.x     v8, zero
    vredsum.vs  v8, v28, v8

    vmv.x.s     a0, v8
    ret
endfunc

function pixel_satd_4x8_rvv
    vsetivli    zero, 4, e8, mf2, ta, ma
    vle8.v      v1, (a2)
    add         a2, a2, a3
    vle8.v      v28, (a0)
    add         a0, a0, a1
    vle8.v      v3, (a2)
    add         a2, a2, a3
    vle8.v      v2, (a0)
    add         a0, a0, a1

    vle8.v      v5, (a2)
    add         a2, a2, a3
    vle8.v      v4, (a0)
    add         a0, a0, a1
    vle8.v      v7, (a2)
    add         a2, a2, a3
    vle8.v      v6, (a0)
    add         a0, a0, a1

    vle8.v      v10, (a2)
    add         a2, a2, a3
    vle8.v      v8, (a0)
    add         a0, a0, a1
    vle8.v      v11, (a2)
    add         a2, a2, a3
    vle8.v      v9, (a0)
    add         a0, a0, a1
    
    vle8.v      v13, (a2)
    add         a2, a2, a3
    vle8.v      v12, (a0)
    add         a0, a0, a1
    vle8.v      v15, (a2)
    add         a2, a2, a3
    vle8.v      v14, (a0)
    add         a0, a0, a1

    vsetivli    zero, 2, e32, mf2, ta, ma
    vslideup.vi v1, v10, 1
    vslideup.vi v28, v8, 1
    vslideup.vi v3, v11, 1
    vslideup.vi v2, v9, 1
    vslideup.vi v5, v13, 1
    vslideup.vi v4, v12, 1
    vslideup.vi v7, v15, 1
    vslideup.vi v6, v14, 1

    vsetivli    zero, 8, e8, mf2, ta, ma
    vwsubu.vv   v20, v28, v1
    vwsubu.vv   v21, v2, v3
    vwsubu.vv   v22, v4, v5
    vwsubu.vv   v23, v6, v7

    vsetivli    zero, 8, e16, m1, ta, mu
    SUMSUB_AB   v16, v17, v20, v21
    SUMSUB_AB   v18, v19, v22, v23

    SUMSUB_AB   v4, v6, v16, v18
    SUMSUB_AB   v5, v7, v17, v19

    // vtrn_8h     v28, v1, v4, v5, v8, v9, v10
    // vtrn_8h     v2, v3, v6, v7, v8, v9, v10
    li t0, 0xaaaaaaaa
    vmv.v.x v0, t0
    vmv.v.v       v28, v4
    vmv.v.v       v2, v6
    vslideup.vi   v28, v5, 1, v0.t
    vslideup.vi   v2, v7, 1, v0.t
    vmnot.m v0,v0
    vslidedown.vi v5, v4, 1, v0.t
    vslidedown.vi v7, v6, 1, v0.t
    //

    vsetivli    zero, 8, e16, m1, ta, ma
    SUMSUB_AB   v16, v17, v28, v5
    SUMSUB_AB   v18, v19, v2, v7

    // vtrn_4s     v28, v1, v16, v18, v8, v9, v10, t5
    // vtrn_4s     v2, v3, v17, v19, v8, v9, v10, t5
    
    vsetivli        zero, 4, e32, m1, ta, mu
    vmv.v.v       v1, v18
    vmv.v.v       v3, v19
    vslidedown.vi   v1, v16, 1, v0.t
    vslidedown.vi v3, v17, 1, v0.t
    vmnot.m v0,v0
    vslideup.vi   v16, v18, 1, v0.t
    vslideup.vi   v17, v19, 1, v0.t
    //

    vsetivli    zero, 8, e16, m1, ta, ma
    vabs        v28, v16, v8
    vabs        v1, v1, v9
    vabs        v2, v17, v10
    vabs        v3, v3, v11
    vmaxu.vv    v28, v28, v1
    vmaxu.vv    v1, v2, v3
    vadd.vv     v28, v28, v1
    vmv.s.x     v8, zero
    vredsum.vs  v8, v28, v8

    vmv.x.s     a0, v8
    
    ret
endfunc

function pixel_satd_8x4_rvv
    vsetivli    zero, 8, e8, mf2, ta, ma
    vle8.v      v1, (a2)
    add         a2, a2, a3
    vle8.v      v28, (a0)
    add         a0, a0, a1
    vle8.v      v3, (a2)
    add         a2, a2, a3
    vle8.v      v2, (a0)
    add         a0, a0, a1

    vle8.v      v5, (a2)
    add         a2, a2, a3
    vle8.v      v4, (a0)
    add         a0, a0, a1
    vle8.v      v7, (a2)
    add         a2, a2, a3
    vle8.v      v6, (a0)
    add         a0, a0, a1

    vsetivli    zero, 8, e8, mf2, ta, ma
    vwsubu.vv   v20, v28, v1
    vwsubu.vv   v21, v2, v3
    vwsubu.vv   v22, v4, v5
    vwsubu.vv   v23, v6, v7

    vsetivli    zero, 8, e16, m1, ta, mu
    SUMSUB_AB   v16, v17, v20, v21
    SUMSUB_AB   v18, v19, v22, v23

    SUMSUB_AB   v4, v6, v16, v18
    SUMSUB_AB   v5, v7, v17, v19

    li t0, 0xaaaaaaaa
    vmv.v.x v0, t0
    vmv.v.v       v28, v4
    vmv.v.v       v2, v6
    vslideup.vi   v28, v5, 1, v0.t // trn1
    vslideup.vi   v2, v7, 1, v0.t  // trn1
    vmnot.m v0,v0
    vslidedown.vi v5, v4, 1, v0.t // trn2
    vslidedown.vi v7, v6, 1, v0.t // trn2
    
    vsetivli    zero, 8, e16, m1, ta, ma
    SUMSUB_AB   v16, v17, v28, v5
    SUMSUB_AB   v18, v19, v2, v7
    
    vsetivli        zero, 4, e32, m1, ta, mu
    vmv.v.v       v1, v18
    vmv.v.v       v3, v19
    vslidedown.vi   v1, v16, 1, v0.t // trn2
    vslidedown.vi v3, v17, 1, v0.t // trn2
    vmnot.m v0,v0
    vslideup.vi   v16, v18, 1, v0.t // trn1
    vslideup.vi   v17, v19, 1, v0.t // trn1
    
    vsetivli    zero, 8, e16, m1, ta, ma
    vabs        v28, v16, v8
    vabs        v1, v1, v9
    vabs        v2, v17, v10
    vabs        v3, v3, v11
    vmaxu.vv    v28, v28, v1
    vmaxu.vv    v1, v2, v3
    vadd.vv     v28, v28, v1
    vmv.s.x     v8, zero
    vredsum.vs  v8, v28, v8

    vmv.x.s     a0, v8
    
    ret
endfunc

function pixel_satd_4x16_rvv
    mv          t0, ra
    vsetivli    zero, 4, e8, mf2, ta, ma
    vle8.v      v1, (a2)
    add         a2, a2, a3
    vle8.v      v28, (a0)
    add         a0, a0, a1
    vle8.v      v3, (a2)
    add         a2, a2, a3
    vle8.v      v2, (a0)
    add         a0, a0, a1

    vle8.v      v5, (a2)
    add         a2, a2, a3
    vle8.v      v4, (a0)
    add         a0, a0, a1
    vle8.v      v7, (a2)
    add         a2, a2, a3
    vle8.v      v6, (a0)
    add         a0, a0, a1


    vle8.v      v10, (a2)
    add         a2, a2, a3
    vle8.v      v8, (a0)
    add         a0, a0, a1
    vle8.v      v11, (a2)
    add         a2, a2, a3
    vle8.v      v9, (a0)
    add         a0, a0, a1
    
    vle8.v      v13, (a2)
    add         a2, a2, a3
    vle8.v      v12, (a0)
    add         a0, a0, a1
    vle8.v      v15, (a2)
    add         a2, a2, a3
    vle8.v      v14, (a0)
    add         a0, a0, a1

    vsetivli    zero, 2, e32, mf2, ta, ma
    vslideup.vi v1, v10, 1
    vslideup.vi v28, v8, 1
    vslideup.vi v3, v11, 1
    vslideup.vi v2, v9, 1
    vslideup.vi v5, v13, 1
    vslideup.vi v4, v12, 1
    vslideup.vi v7, v15, 1
    vslideup.vi v6, v14, 1

    vsetivli    zero, 8, e8, mf2, ta, ma
    vwsubu.vv   v16, v28, v1
    vwsubu.vv   v17, v2, v3
    vwsubu.vv   v18, v4, v5
    vwsubu.vv   v19, v6, v7

    vsetivli    zero, 4, e8, mf2, ta, ma
    vle8.v      v1, (a2)
    add         a2, a2, a3
    vle8.v      v28, (a0)
    add         a0, a0, a1
    vle8.v      v3, (a2)
    add         a2, a2, a3
    vle8.v      v2, (a0)
    add         a0, a0, a1

    vle8.v      v5, (a2)
    add         a2, a2, a3
    vle8.v      v4, (a0)
    add         a0, a0, a1
    vle8.v      v7, (a2)
    add         a2, a2, a3
    vle8.v      v6, (a0)
    add         a0, a0, a1


    vle8.v      v10, (a2)
    add         a2, a2, a3
    vle8.v      v8, (a0)
    add         a0, a0, a1
    vle8.v      v11, (a2)
    add         a2, a2, a3
    vle8.v      v9, (a0)
    add         a0, a0, a1
    
    vle8.v      v13, (a2)
    add         a2, a2, a3
    vle8.v      v12, (a0)
    add         a0, a0, a1
    vle8.v      v15, (a2)
    add         a2, a2, a3
    vle8.v      v14, (a0)
    add         a0, a0, a1

    vsetivli    zero, 2, e32, mf2, ta, ma
    vslideup.vi v1, v10, 1
    vslideup.vi v28, v8, 1
    vslideup.vi v3, v11, 1
    vslideup.vi v2, v9, 1
    vslideup.vi v5, v13, 1
    vslideup.vi v4, v12, 1
    vslideup.vi v7, v15, 1
    vslideup.vi v6, v14, 1

    vsetivli    zero, 8, e8, mf2, ta, ma
    vwsubu.vv   v20, v28, v1
    vwsubu.vv   v21, v2, v3
    vwsubu.vv   v22, v4, v5
    vwsubu.vv   v23, v6, v7

    vsetivli    zero, 8, e16, m1, ta, ma
    SUMSUB_AB   v28, v1, v16, v17
    SUMSUB_AB   v2, v3, v18, v19

    jal         satd_8x4v_8x8h_rvv

    vwadd.vv    v24, v28, v1
    vwadd.vv    v30, v2, v3
    vsetivli    zero, 8, e32, m2, ta, ma
    vadd.vv     v24, v24, v30

    vmv.s.x     v8, zero
    vredsum.vs  v8, v24, v8

    vmv.x.s     a0, v8
    mv          ra, t0
    ret

endfunc

.macro load_diff_fly_8x8
    vsetivli    zero, 8, e8, mf2, ta, ma
    vle8.v      v1, (a2)
    add         a2, a2, a3
    vle8.v      v28, (a0)
    add         a0, a0, a1
    vle8.v      v3, (a2)
    add         a2, a2, a3
    vle8.v      v2, (a0)
    add         a0, a0, a1
    vwsubu.vv   v16, v28, v1

    vle8.v      v5, (a2)
    add         a2, a2, a3
    vle8.v      v4, (a0)
    add         a0, a0, a1
    vwsubu.vv   v17, v2, v3
    vle8.v      v7, (a2)
    add         a2, a2, a3
    vle8.v      v6, (a0)
    add         a0, a0, a1
    vwsubu.vv   v18, v4, v5   

    vle8.v      v1, (a2)
    add         a2, a2, a3
    vle8.v      v28, (a0)
    add         a0, a0, a1
    vwsubu.vv   v19, v6, v7
    vle8.v      v3, (a2)
    add         a2, a2, a3
    vle8.v      v2, (a0)
    add         a0, a0, a1
    vwsubu.vv   v20, v28, v1

    vle8.v      v5, (a2)
    add         a2, a2, a3
    vle8.v      v4, (a0)
    add         a0, a0, a1
    vwsubu.vv   v21, v2, v3
    vle8.v      v7, (a2)
    add         a2, a2, a3
    vle8.v      v6, (a0)
    add         a0, a0, a1
    vwsubu.vv   v22, v4, v5
    vwsubu.vv   v23, v6, v7

    vsetivli    zero, 8, e16, m1, ta, ma
    SUMSUB_AB   v28, v1, v16, v17
    SUMSUB_AB   v2, v3, v18, v19
.endm

function pixel_satd_8x8_rvv
    mv          t6, ra

    jal         satd_8x8_rvv
    vadd.vv     v28, v28, v1
    vadd.vv     v1, v2, v3
    vadd.vv     v28, v28, v1
    vmv.s.x     v8, zero
    vredsum.vs  v8, v28, v8
    vmv.x.s     a0, v8
    mv          ra, t6

    ret
endfunc

function pixel_satd_8x16_rvv
    mv          t6, ra
    jal         satd_8x8_rvv
    vadd.vv     v28, v28, v1
    vadd.vv     v1, v2, v3
    vadd.vv     v30, v28, v1

    jal         satd_8x8_rvv
    vadd.vv     v28, v28, v1
    vadd.vv     v1, v2, v3
    vadd.vv     v31, v28, v1
    vadd.vv     v28, v30, v31

    vmv.s.x     v8, zero
    vredsum.vs  v8, v28, v8
    vmv.x.s     a0, v8
    slli        a0, a0, 48
    srli        a0, a0, 48      
    mv          ra, t6

    ret
endfunc

function satd_8x8_rvv, export=0
    load_diff_fly_8x8
endfunc


// one vertical hadamard pass and two horizontal
function satd_8x4v_8x8h_rvv, export=0
    vsetivli    zero, 8, e16, m1, ta, mu
    SUMSUB_AB   v16, v18, v28, v2
    SUMSUB_AB   v17, v19, v1, v3
    HADAMARD4_V v20, v21, v22, v23, v28, v1, v2, v3
    //vtrn_8h     v28, v1, v16, v17, v8, v9, v10
    //vtrn_8h     v2, v3, v18, v19, v8, v9, v10
    //vtrn_8h     v4, v5, v20, v21, v8, v9, v10
    //vtrn_8h     v6, v7, v22, v23, v8, v9, v10

    li t5, 0xaaaaaaaa
    vmv.v.x v0, t5
    vmv.v.v       v28, v16
    vmv.v.v       v2, v18
    vmv.v.v       v4, v20
    vmv.v.v       v6, v22
    vslideup.vi   v28, v17, 1, v0.t // trn1
    vslideup.vi   v2, v19, 1, v0.t  // trn1
    vslideup.vi   v4, v21, 1, v0.t // trn1
    vslideup.vi   v6, v23, 1, v0.t  // trn1
    vmnot.m v0,v0
    vslidedown.vi v17, v16, 1, v0.t // trn2
    vslidedown.vi v19, v18, 1, v0.t // trn2
    vslidedown.vi v21, v20, 1, v0.t // trn2
    vslidedown.vi v23, v22, 1, v0.t // trn2

    vsetivli    zero, 8, e16, m1, ta, ma
    SUMSUB_AB   v16, v17, v28, v17
    SUMSUB_AB   v18, v19, v2, v19
    SUMSUB_AB   v20, v21, v4, v21
    SUMSUB_AB   v22, v23, v6, v23

    //vtrn_4s     v28, v2, v16, v18, v8, v9, v10, t5
    //vtrn_4s     v1, v3, v17, v19, v8, v9, v10, t5
    //vtrn_4s     v4, v6, v20, v22, v8, v9, v10, t5
    //vtrn_4s     v5, v7, v21, v23, v8, v9, v10, t5

    vsetivli        zero, 4, e32, m1, ta, mu
    vmv.v.v       v2, v18
    vmv.v.v       v3, v19
    vmv.v.v       v6, v22
    vmv.v.v       v7, v23
    vslidedown.vi   v2, v16, 1, v0.t // trn2
    vslidedown.vi v3, v17, 1, v0.t // trn2
    vslidedown.vi   v6, v20, 1, v0.t // trn2
    vslidedown.vi v7, v21, 1, v0.t // trn2
    vmnot.m v0,v0
    vslideup.vi   v16, v18, 1, v0.t // trn1
    vslideup.vi   v17, v19, 1, v0.t // trn1
    vslideup.vi   v20, v22, 1, v0.t // trn1
    vslideup.vi   v21, v23, 1, v0.t // trn1


    vsetivli    zero, 8, e16, m1, ta, ma
    vabs        v28, v16, v8
    vabs        v1, v17, v9
    vabs        v2, v2, v10
    vabs        v3, v3, v11
    vabs        v4, v20, v12
    vabs        v5, v21, v13
    vabs        v6, v6, v14
    vabs        v7, v7, v15

    vmaxu.vv    v28, v28, v2
    vmaxu.vv    v1, v1, v3
    vmaxu.vv    v2, v4, v6
    vmaxu.vv    v3, v5, v7

    ret
endfunc

function pixel_satd_16x8_rvv
    mv          t6, ra

    jal         satd_16x4_rvv
    vadd.vv     v30, v28, v1
    vadd.vv     v31, v2, v3

    jal         satd_16x4_rvv
    vadd.vv     v28, v28, v1
    vadd.vv     v1, v2, v3
    vadd.vv     v30, v30, v28
    vadd.vv     v31, v31, v1

    vadd.vv     v28, v30, v31
    vmv.s.x     v8, zero
    vredsum.vs  v8, v28, v8
    vmv.x.s     a0, v8
    slli        a0, a0, 48
    srli        a0, a0, 48      
    mv          ra, t6

    ret
endfunc

function pixel_satd_16x16_rvv
    mv          t6, ra

    jal         satd_16x4_rvv
    vadd.vv     v30, v28, v1
    vadd.vv     v31, v2, v3

    jal         satd_16x4_rvv
    vadd.vv     v28, v28, v1
    vadd.vv     v1, v2, v3
    vadd.vv     v30, v30, v28
    vadd.vv     v31, v31, v1

    jal         satd_16x4_rvv
    vadd.vv     v28, v28, v1
    vadd.vv     v1, v2, v3
    vadd.vv     v30, v30, v28
    vadd.vv     v31, v31, v1

    jal         satd_16x4_rvv
    vadd.vv     v28, v28, v1
    vadd.vv     v1, v2, v3
    vadd.vv     v30, v30, v28
    vadd.vv     v31, v31, v1

    vwadd.vv     v28, v30, v31
    vsetivli    zero, 8, e32, m2, ta, ma
    vmv.s.x     v8, zero

    vredsum.vs  v8, v28, v8
    
    vmv.x.s     a0, v8  
    mv          ra, t6

    ret
endfunc


function satd_16x4_rvv, export=0
    vsetivli    zero, 16, e8, m1, ta, ma
    vle8.v      v1, (a2)
    add         a2, a2, a3
    vle8.v      v28, (a0)
    add         a0, a0, a1
    vle8.v      v3, (a2)
    add         a2, a2, a3
    vle8.v      v2, (a0)
    add         a0, a0, a1

    vle8.v      v5, (a2)
    add         a2, a2, a3
    vle8.v      v4, (a0)
    add         a0, a0, a1
    vle8.v      v7, (a2)
    add         a2, a2, a3
    vle8.v      v6, (a0)
    add         a0, a0, a1
    
    vsetivli    zero, 8, e8, mf2, ta, ma
    vwsubu.vv   v16, v28, v1
    vwsubu.vv   v18, v2, v3
    vwsubu.vv   v20, v4, v5
    vwsubu.vv   v22, v6, v7
    vsetivli    zero, 16, e8, m1, ta, ma
    vslidedown.vi   v28, v28, 8
    vslidedown.vi   v1, v1, 8
    vslidedown.vi   v2, v2, 8
    vslidedown.vi   v3, v3, 8
    vslidedown.vi   v4, v4, 8
    vslidedown.vi   v5, v5, 8
    vslidedown.vi   v6, v6, 8
    vslidedown.vi   v7, v7, 8
    vsetivli    zero, 8, e8, mf2, ta, ma
    vwsubu.vv   v17, v28, v1
    vwsubu.vv   v19, v2, v3
    vwsubu.vv   v21, v4, v5
    vwsubu.vv   v23, v6, v7
    
    vsetivli    zero, 8, e16, m1, ta, mu
    SUMSUB_AB   v28, v1, v16, v18
    SUMSUB_AB   v2, v3, v20, v22

    // satd_8x4v_8x8h
    SUMSUB_AB   v16, v20, v28, v2
    SUMSUB_AB   v18, v22, v1, v3
    HADAMARD4_V v17, v19, v21, v23, v28, v1, v2, v3

    li t5, 0xaaaaaaaa
    vmv.v.x v0, t5
    vmv.v.v       v28, v16
    vmv.v.v       v2, v18
    vmv.v.v       v4, v20
    vmv.v.v       v6, v22
    vslideup.vi   v28, v17, 1, v0.t // trn1
    vslideup.vi   v2, v19, 1, v0.t  // trn1
    vslideup.vi   v4, v21, 1, v0.t // trn1
    vslideup.vi   v6, v23, 1, v0.t  // trn1
    vmnot.m v0,v0
    vslidedown.vi v17, v16, 1, v0.t // trn2
    vslidedown.vi v19, v18, 1, v0.t // trn2
    vslidedown.vi v21, v20, 1, v0.t // trn2
    vslidedown.vi v23, v22, 1, v0.t // trn2

    vsetivli    zero, 8, e16, m1, ta, ma
    SUMSUB_AB   v16, v17, v28, v17
    SUMSUB_AB   v18, v19, v2, v19
    SUMSUB_AB   v20, v21, v4, v21
    SUMSUB_AB   v22, v23, v6, v23

    //vtrn_4s     v28, v2, v16, v18, v8, v9, v10, t5
    //vtrn_4s     v1, v3, v17, v19, v8, v9, v10, t5
    //vtrn_4s     v4, v6, v20, v22, v8, v9, v10, t5
    //vtrn_4s     v5, v7, v21, v23, v8, v9, v10, t5

    vsetivli        zero, 4, e32, m1, ta, mu
    vmv.v.v       v2, v18
    vmv.v.v       v3, v19
    vmv.v.v       v6, v22
    vmv.v.v       v7, v23
    vslidedown.vi   v2, v16, 1, v0.t // trn2
    vslidedown.vi v3, v17, 1, v0.t // trn2
    vslidedown.vi   v6, v20, 1, v0.t // trn2
    vslidedown.vi v7, v21, 1, v0.t // trn2
    vmnot.m v0,v0
    vslideup.vi   v16, v18, 1, v0.t // trn1
    vslideup.vi   v17, v19, 1, v0.t // trn1
    vslideup.vi   v20, v22, 1, v0.t // trn1
    vslideup.vi   v21, v23, 1, v0.t // trn1

    vsetivli    zero, 8, e16, m1, ta, ma
    vabs        v28, v16, v8
    vabs        v1, v17, v9
    vabs        v2, v2, v10
    vabs        v3, v3, v11
    vabs        v4, v20, v12
    vabs        v5, v21, v13
    vabs        v6, v6, v14
    vabs        v7, v7, v15

    vmaxu.vv    v28, v28, v2
    vmaxu.vv    v1, v1, v3
    vmaxu.vv    v2, v4, v6
    vmaxu.vv    v3, v5, v7

    ret
endfunc

function pixel_ssd_nv12_core_rvv
    addi        t0, a4, 8
    andi        t0, t0, -16

    vsetivli    zero, 2, e64, m1, ta, ma
    vmv.v.x     v6, zero
    vmv.v.x     v7, zero
    slli        t1, t0, 1
    sub         a1, a1, t1
    sub         a3, a3, t1
1:
    addi        t3, a4, -16
    # Load interleaved U and V components from both images
    vsetivli    zero, 8, e8, mf2, ta, ma
    vlseg2e8.v  v0, (a0)
    addi        a0, a0, 16
    vlseg2e8.v  v2, (a2)
    addi        a2, a2, 16
    vlseg2e8.v  v24, (a0)
    addi        a0, a0, 16
    vlseg2e8.v  v26, (a2)
    addi        a2, a2, 16

    vwsubu.vv   v16, v0, v2
    vwsubu.vv   v17, v1, v3
    vwsubu.vv   v18, v24, v26
    vwsubu.vv   v19, v25, v27

    vsetivli    zero, 4, e16, mf2, ta, ma
    vwmul.vv    v20, v16, v16
    vwmul.vv    v21, v17, v17
    vsetivli    zero, 8, e16, m1, ta, ma
    vslidedown.vi   v28, v16, 4
    vslidedown.vi   v29, v17, 4
    vsetivli    zero, 4, e16, mf2, ta, ma
    vwmacc.vv   v20, v28, v28
    vwmacc.vv   v21, v29, v29

    blt         t3, zero, 4f
    beq         t3, zero, 3f
2:
    vsetivli    zero, 4, e16, mf2, ta, ma
    vwmacc.vv   v20, v18, v18
    vwmacc.vv   v21, v19, v19
    vsetivli    zero, 8, e8, mf2, ta, ma
    vlseg2e8.v  v0, (a0)
    addi        a0, a0, 16
    vlseg2e8.v  v2, (a2)
    addi        a2, a2, 16
    vlseg2e8.v  v24, (a0)
    addi        a0, a0, 16
    vlseg2e8.v  v26, (a2)
    addi        a2, a2, 16
    vsetivli    zero, 8, e16, m1, ta, ma
    vslidedown.vi   v28, v18, 4
    vslidedown.vi   v29, v19, 4
    vsetivli    zero, 4, e16, mf2, ta, ma
    vwmacc.vv   v20, v28, v28
    vwmacc.vv   v21, v29, v29

    addi        t3, t3, -16
    vsetivli    zero, 8, e8, mf2, ta, ma
    vwsubu.vv   v16, v0, v2
    vwsubu.vv   v17, v1, v3
    vsetivli    zero, 4, e16, mf2, ta, ma
    vwmacc.vv   v20, v16, v16
    vwmacc.vv   v21, v17, v17
    vsetivli    zero, 8, e16, m1, ta, ma
    vslidedown.vi   v28, v16, 4
    vslidedown.vi   v29, v17, 4
    vsetivli    zero, 4, e16, mf2, ta, ma
    vwmacc.vv   v20, v28, v28
    vwmacc.vv   v21, v29, v29
    blt         t3, zero, 4f

    vsetivli    zero, 8, e8, mf2, ta, ma
    vwsubu.vv   v18, v24, v26
    vwsubu.vv   v19, v25, v27
    bgt         t3, zero, 2b
3:
    vsetivli    zero, 4, e16, mf2, ta, ma
    vwmacc.vv   v20, v18, v18
    vwmacc.vv   v21, v19, v19
    vsetivli    zero, 8, e16, m1, ta, ma
    vslidedown.vi   v28, v18, 4
    vslidedown.vi   v29, v19, 4
    vsetivli    zero, 4, e16, mf2, ta, ma
    vwmacc.vv   v20, v28, v28
    vwmacc.vv   v21, v29, v29
4:
    addi        a5, a5, -1
    vsetivli    zero, 2, e32, mf2, ta, ma
    vwaddu.wv   v8, v6, v20
    vwaddu.wv   v9, v7, v21
    add         a0, a0, a1
    add         a2, a2, a3
    vsetivli    zero, 4, e32, m1, ta, ma
    vslidedown.vi   v30, v20, 2
    vslidedown.vi   v31, v21, 2
    vsetivli    zero, 2, e32, mf2, ta, ma
    vwaddu.wv   v6, v8, v30
    vwaddu.wv   v7, v9, v31

    bgt         a5, zero, 1b
    
    vsetivli    zero, 2, e64, m1, ta, ma
    vslidedown.vi   v8, v6, 1
    vslidedown.vi   v9, v7, 1

    vmv.x.s     t4, v6
    vmv.x.s     t5, v8
    add         t4, t4, t5
    vmv.x.s     t6, v7
    vmv.x.s     t0, v9
    add         t0, t6, t0

    sd          t4, (a6)
    sd          t0, (a7)
    ret
endfunc

// SA8D functions

function pixel_sa8d_8x8_rvv
    mv          t6, ra
    jal         pixel_sa8d_8x8_rvv
    vwaddu.vv   v4, v28, v1
    vsetivli    zero, 8, e32, m2, ta, ma
    vmv.v.i     v16, 0
    vwredsumu.vs    v16, v4, v16
    vmv.x.s     a0, v16
    addi        a0, a0, 1
    srli        a0, a0, 1
    
    mv          ra, t6
    ret
endfunc

function pixel_sa8d_16x16_rvv
    mv          t6, ra
    jal         pixel_sa8d_8x8_rvv
    vwaddu.vv   v12, v28, v1
    jal         pixel_sa8d_8x8_rvv
    vwaddu.wv   v12, v12, v28
    vwaddu.wv   v12, v12, v1

    slli        t5, a1, 4
    slli        t4, a3, 4
    sub         a0, a0, t5
    sub         a2, a2, t4
    addi        a0, a0, 8
    addi        a2, a2, 8
    jal         pixel_sa8d_8x8_rvv
    vwaddu.wv   v12, v12, v28
    vwaddu.wv   v12, v12, v1
    jal         pixel_sa8d_8x8_rvv
    vwaddu.wv   v12, v12, v28
    vwaddu.wv   v12, v12, v1
    vsetivli    zero, 8, e32, m2, ta, ma
    vmv.v.i     v16, 0
    vwredsumu.vs    v16, v12, v16
    vmv.x.s     a0, v16
    addi        a0, a0, 1
    srli        a0, a0, 1
    
    mv          ra, t6
    ret
endfunc

.macro sa8d_satd_8x8 satd=
function pixel_sa8d_\satd\()8x8_rvv, export=0
    load_diff_fly_8x8

    SUMSUB_AB   v16, v18, v28, v2
    SUMSUB_AB   v17, v19, v1, v3

    HADAMARD4_V v20, v21, v22, v23, v28, v1, v2, v3

    li t5, 0xaaaaaaaa
    vmv.v.x v0, t5
.ifc \satd, satd_
    // vtrn_8h     v28, v1, v16, v17, v8, v9, v10
    // vtrn_8h     v2, v3, v18, v19, v8, v9, v10
    // vtrn_8h     v4, v5, v20, v21, v8, v9, v10
    // vtrn_8h     v6, v7, v22, v23, v8, v9, v10

    vmv.v.v       v28, v16
    vsetivli    zero, 8, e16, m1, ta, mu
    vslideup.vi   v28, v17, 1, v0.t // trn1
    vmv.v.v       v2, v18
    vslideup.vi   v2, v19, 1, v0.t  // trn1
    vmv.v.v       v4, v20
    vslideup.vi   v4, v21, 1, v0.t // trn1
    vmv.v.v       v6, v22
    vslideup.vi   v6, v23, 1, v0.t  // trn1
    vmnot.m v0,v0
    vslidedown.vi v17, v16, 1, v0.t // trn2
    vslidedown.vi v19, v18, 1, v0.t // trn2
    vslidedown.vi v21, v20, 1, v0.t // trn2
    vslidedown.vi v23, v22, 1, v0.t // trn2

    SUMSUB_AB   v24, v25, v28, v17
    SUMSUB_AB   v26, v27, v2, v19
    SUMSUB_AB   v28, v1, v4, v21
    SUMSUB_AB   v2, v3, v6, v23

    // vtrn_4s     v4, v6, v24, v26, v8, v9, v10, t5
    // vtrn_4s     v5, v7, v25, v27, v8, v9, v10, t5
    // vtrn_4s     v24, v26, v28, v2, v8, v9, v10, t5
    // vtrn_4s     v25, v27, v1, v3, v8, v9, v10, t5

    vsetivli        zero, 4, e32, m1, ta, mu
    vmv.v.v       v6, v26
    vmv.v.v       v7, v27
    vmv.v.v       v26, v2
    vmv.v.v       v27, v3
    vslidedown.vi v6, v24, 1, v0.t // trn2
    vslidedown.vi v7, v25, 1, v0.t // trn2
    vslidedown.vi v26, v28, 1, v0.t // trn2
    vslidedown.vi v27, v1, 1, v0.t // trn2
    vmnot.m v0,v0
    vslideup.vi   v24, v26, 1, v0.t // trn1
    vslideup.vi   v25, v27, 1, v0.t // trn1
    vslideup.vi   v28, v2, 1, v0.t // trn1
    vslideup.vi   v1, v3, 1, v0.t // trn1

    vsetivli    zero, 8, e16, m1, ta, ma
    vabs        v28, v4, v8
    vabs        v1, v5, v8
    vabs        v2, v6, v8
    vabs        v3, v7, v8
    vabs        v4, v24, v8
    vabs        v5, v25, v8
    vabs        v6, v26, v8
    vabs        v7, v27, v8

    vmaxu.vv    v28, v28, v2
    vmaxu.vv    v1, v1, v3
    vmaxu.vv    v2, v4, v6
    vmaxu.vv    v3, v5, v7

    vadd.vv     v26, v28, v1
    vadd.vv     v27, v2, v3
.endif

    SUMSUB_AB   v28, v16, v16, v20
    SUMSUB_AB   v1, v17, v17, v21
    SUMSUB_AB   v2, v18, v18, v22
    SUMSUB_AB   v3, v19, v19, v23

//   vtrn_8h     v20, v21, v16, v17, v8, v9, v10
//   vtrn_8h     v4, v5, v28, v1, v8, v9, v10
//   vtrn_8h     v22, v23, v18, v19, v8, v9, v10
//   vtrn_8h     v6, v7, v2, v3, v8, v9, v10

    vmv.v.v       v20, v16
    vmv.v.v       v4, v28
    vmv.v.v       v22, v18
    vmv.v.v       v6, v2
    vsetivli    zero, 8, e16, m1, ta, mu
    vslideup.vi   v20, v17, 1, v0.t // trn1
    vslideup.vi   v4, v1, 1, v0.t  // trn1
    vslideup.vi   v22, v19, 1, v0.t // trn1
    vslideup.vi   v6, v3, 1, v0.t  // trn1
    vmnot.m v0,v0
    vslidedown.vi v17, v16, 1, v0.t // trn2
    vslidedown.vi v1, v28, 1, v0.t // trn2
    vslidedown.vi v19, v18, 1, v0.t // trn2
    vslidedown.vi v3, v2, 1, v0.t // trn2

   SUMSUB_AB   v14, v15, v20, v17
   SUMSUB_AB   v24, v25, v4, v1
   SUMSUB_AB   v28, v1, v22, v19
   SUMSUB_AB   v4, v5, v6, v3

//    vtrn_4s     v20, v22, v14, v28, v8, v9, v10, t5
//    vtrn_4s     v21, v23, v15, v1, v8, v9, v10, t5
//    vtrn_4s     v16, v18, v24, v4, v8, v9, v10, t5
//    vtrn_4s     v17, v19, v25, v5, v8, v9, v10, t5

    vsetivli        zero, 4, e32, m1, ta, mu
    vmv.v.v       v22, v28
    vslidedown.vi v22, v14, 1, v0.t // trn2
    vmv.v.v       v23, v1
    vslidedown.vi v23, v15, 1, v0.t // trn2
    vmv.v.v       v18, v4
    vslidedown.vi v18, v24, 1, v0.t // trn2
    vmv.v.v       v19, v5
    vslidedown.vi v19, v25, 1, v0.t // trn2
    vmnot.m v0,v0
    vslideup.vi   v14, v28, 1, v0.t // trn1
    vslideup.vi   v15, v1, 1, v0.t // trn1
    vslideup.vi   v24, v4, 1, v0.t // trn1
    vslideup.vi   v25, v5, 1, v0.t // trn1

    vsetivli    zero, 8, e16, m1, ta, ma
    SUMSUB_AB   v28, v2, v14, v22
    SUMSUB_AB   v1, v3, v15, v23
    SUMSUB_AB   v4, v6, v24, v18
    SUMSUB_AB   v5, v7, v25, v19

    vsetivli    zero, 2, e64, m1, ta, ma
    vmv1r.v     v16, v28
    vmv1r.v     v20, v4
    vmv1r.v     v17, v1
    vmv1r.v     v21, v5
    vmv1r.v     v18, v2
    vmv1r.v     v22, v6
    vmv1r.v     v19, v3
    vmv1r.v     v23, v7
    vslideup.vi v16, v4, 1
    vslideup.vi v17, v5, 1
    vslideup.vi v18, v6, 1
    vslideup.vi v19, v7, 1
    vsetivli    zero, 1, e64, m1, tu, ma
    vslidedown.vi v20, v28, 1
    vslidedown.vi v21, v1, 1
    vslidedown.vi v22, v2, 1
    vslidedown.vi v23, v3, 1

    vsetivli    zero, 8, e16, m1, ta, ma
    vabs        v16, v16, v8
    vabs        v17, v17, v8
    vabs        v18, v18, v8
    vabs        v19, v19, v8
    vabs        v20, v20, v8
    vabs        v21, v21, v8
    vabs        v22, v22, v8
    vabs        v23, v23, v8

    vmaxu.vv    v16, v16, v20
    vmaxu.vv    v17, v17, v21
    vmaxu.vv    v18, v18, v22
    vmaxu.vv    v19, v19, v23

    vadd.vv     v28, v16, v17
    vadd.vv     v1, v18, v19

    ret
endfunc
.endm

sa8d_satd_8x8
sa8d_satd_8x8 satd_

.macro HADAMARD_AC w h
function pixel_hadamard_ac_\w\()x\h\()_rvv
    movrel      a5, mask_ac_4_8
    mv          t5, ra
    vsetivli    zero, 8, e16, m1, ta, ma
    vle16.v     v30, (a5)
    addi        a5, a5, 16
    vle16.v     v31, (a5)
    vsetivli    zero, 8, e32, m2, ta, ma
    vmv.v.i     v12, 0
    vmv.v.i     v14, 0

    jal         hadamard_ac_8x8_rvv
.if \h > 8
    jal         hadamard_ac_8x8_rvv
.endif
.if \w > 8
    slli        t0, a1, 3
    sub         a0, a0, t0
    addi        a0, a0, 8
    jal         hadamard_ac_8x8_rvv
.endif
.if \w * \h == 256
    slli        t0, a1, 4
    sub         a0, a0, t0
    jal         hadamard_ac_8x8_rvv
.endif
    vsetivli    zero, 8, e32, m2, ta, ma
    vmv.s.x     v8, zero
    vmv.s.x     v9, zero
    vredsum.vs  v8, v12, v8
    vredsum.vs  v9, v14, v9
    vmv.x.s     a0, v8
    vmv.x.s     a1, v9
    srli        a1, a1, 2
    srli        a0, a0, 1
    slli        t0, a1, 32
    or          a0, a0, t0

    mv          ra, t5
    ret
endfunc
.endm

HADAMARD_AC  8, 8
HADAMARD_AC  8, 16
HADAMARD_AC 16, 8
HADAMARD_AC 16, 16

// v12-v13: satd  v14-v15: sa8d  v30: mask_ac4  v31: mask_ac8
function hadamard_ac_8x8_rvv, export=0
    vsetivli    zero, 8, e8, mf2, ta, ma
    vle8.v      v16, (a0)
    add         a0, a0, a1
    vle8.v      v17, (a0)
    add         a0, a0, a1
    vle8.v      v18, (a0)
    add         a0, a0, a1
    vle8.v      v19, (a0)
    add         a0, a0, a1
    vle8.v      v20, (a0)
    add         a0, a0, a1
    vle8.v      v21, (a0)
    add         a0, a0, a1
    vle8.v      v22, (a0)
    add         a0, a0, a1
    vle8.v      v23, (a0)
    add         a0, a0, a1

    vsetivli    zero, 8, e8, mf2, ta, ma
    SUMSUBL_AB  v28, v1, v16, v17
    SUMSUBL_AB  v2, v3, v18, v19
    SUMSUBL_AB  v4, v5, v20, v21
    SUMSUBL_AB  v6, v7, v22, v23

    vsetivli    zero, 8, e16, m1, ta, mu
    SUMSUB_ABCD v16, v18, v17, v19, v28, v2, v1, v3
    SUMSUB_ABCD v20, v22, v21, v23, v4, v6, v5, v7

    //vtrn_8h     v28, v1, v16, v17, v8, v9, v10
    //vtrn_8h     v2, v3, v18, v19, v8, v9, v10
    //vtrn_8h     v4, v5, v20, v21, v8, v9, v10
    //vtrn_8h     v6, v7, v22, v23, v8, v9, v10

    li t6, 0xaaaaaaaa
    vmv.v.x v0, t6
    vmv.v.v       v28, v16
    vmv.v.v       v2, v18
    vmv.v.v       v4, v20
    vmv.v.v       v6, v22
    vslideup.vi   v28, v17, 1, v0.t // trn1
    vslideup.vi   v2, v19, 1, v0.t  // trn1
    vslideup.vi   v4, v21, 1, v0.t // trn1
    vslideup.vi   v6, v23, 1, v0.t  // trn1
    vmnot.m v0,v0
    vmv.v.v       v1, v17
    vmv.v.v       v3, v19
    vmv.v.v       v5, v21
    vmv.v.v       v7, v23
    vslidedown.vi v1, v16, 1, v0.t // trn2
    vslidedown.vi v3, v18, 1, v0.t // trn2
    vslidedown.vi v5, v20, 1, v0.t // trn2
    vslidedown.vi v7, v22, 1, v0.t // trn2

    SUMSUB_AB   v16, v17, v28, v1
    SUMSUB_AB   v18, v19, v2, v3
    SUMSUB_AB   v20, v21, v4, v5
    SUMSUB_AB   v22, v23, v6, v7

    //vtrn_4s     v28, v2, v16, v18, v8, v9, v10, t5
    //vtrn_4s     v1, v3, v17, v19, v8, v9, v10, t5
    //vtrn_4s     v4, v6, v20, v22, v8, v9, v10, t5
    //vtrn_4s     v5, v7, v21, v23, v8, v9, v10, t5

    vsetivli        zero, 4, e32, m1, ta, mu
    vmv.v.v       v2, v18
    vslidedown.vi   v2, v16, 1, v0.t // trn2
    vmv.v.v       v3, v19
    vslidedown.vi v3, v17, 1, v0.t // trn2
    vmv.v.v       v6, v22
    vslidedown.vi   v6, v20, 1, v0.t // trn2
    vmv.v.v       v7, v23
    vslidedown.vi v7, v21, 1, v0.t // trn2
    vmnot.m v0,v0
    vmv.v.v       v28, v16
    vmv.v.v       v1, v17
    vmv.v.v       v4, v20
    vmv.v.v       v5, v21
    vslideup.vi   v28, v18, 1, v0.t // trn1
    vslideup.vi   v1, v19, 1, v0.t // trn1
    vslideup.vi   v4, v22, 1, v0.t // trn1
    vslideup.vi   v5, v23, 1, v0.t // trn1

    vsetivli    zero, 8, e16, m1, ta, ma
    SUMSUB_AB   v16, v18, v28, v2
    SUMSUB_AB   v17, v19, v1, v3
    SUMSUB_ABCD v20, v22, v21, v23, v4, v6, v5, v7

    vabs        v28, v16, v8
    vabs        v4, v20, v8
    vabs        v1, v17, v8
    vabs        v5, v21, v8
    vabs        v2, v18, v8
    vabs        v6, v22, v8
    vabs        v3, v19, v8
    vabs        v7, v23, v8

    vadd.vv     v28, v28, v4
    vadd.vv     v1, v1, v5
    
    vsetivli    zero, 16, e8, m1, ta, ma
    vand.vv     v28, v28, v30
    vsetivli    zero, 8, e16, m1, ta, ma
    vadd.vv     v2, v2, v6
    vadd.vv     v3, v3, v7
    vadd.vv     v28, v28, v2
    vadd.vv     v1, v1, v3
    vwaddu.wv   v12, v12, v28
    vwaddu.wv   v12, v12, v1

    SUMSUB_AB   v6, v7, v23, v19
    SUMSUB_AB   v4, v5, v22, v18
    SUMSUB_AB   v2, v3, v21, v17
    SUMSUB_AB   v1, v28, v16, v20

    vsetivli    zero, 2, e64, m1, ta, ma
    vmv1r.v     v16, v6
    vmv1r.v     v17, v7
    vmv1r.v     v18, v4
    vmv1r.v     v19, v5
    vmv1r.v     v20, v2
    vmv1r.v     v21, v3
    vslideup.vi v16, v7, 1
    vslideup.vi v18, v5, 1
    vslideup.vi v20, v3, 1
    vsetivli    zero, 1, e64, m1, tu, ma
    vslidedown.vi   v17, v6, 1
    vslidedown.vi   v19, v4, 1
    vslidedown.vi   v21, v2, 1

    vsetivli    zero, 8, e16, m1, ta, ma
    vabs        v16, v16, v8
    vabs        v17, v17, v8
    vabs        v18, v18, v8
    vabs        v19, v19, v8
    vabs        v20, v20, v8
    vabs        v21, v21, v8

    vsetivli    zero, 2, e64, m1, ta, ma
    vmv1r.v     v7, v1
    vmv1r.v     v6, v28
    vslideup.vi v7, v28, 1
    vsetivli    zero, 1, e64, m1, tu, ma
    vslidedown.vi   v6, v1, 1

    vsetivli    zero, 8, e16, m1, ta, ma
    vmaxu.vv    v3, v16, v17
    vmaxu.vv    v2, v18, v19
    vmaxu.vv    v1, v20, v21

    SUMSUB_AB   v4, v5, v7, v6

    vadd.vv     v2, v2, v3
    vadd.vv     v2, v2, v1
    vsetivli    zero, 16, e8, m1, ta, ma
    vand.vv     v4, v4, v31
    vsetivli    zero, 8, e16, m1, ta, ma
    vadd.vv     v2, v2, v2
    vabs        v4, v4, v8
    vabs        v5, v5, v8
    vadd.vv     v2, v2, v5
    vadd.vv     v2, v2, v4
    vwaddu.wv   v14, v14, v2

    ret
endfunc

function pixel_ssim_4x4x2_core_rvv
    vsetivli    zero, 8, e8, mf2, ta, ma
    vle8.v      v0, (a0)
    add         a0, a0, a1
    vle8.v      v1, (a2)
    add         a2, a2, a3
    vwmulu.vv   v16, v0, v0
    vwmulu.vv   v17, v0, v1
    vwmulu.vv   v18, v1, v1

    vle8.v      v2, (a0)
    add         a0, a0, a1
    vle8.v      v3, (a2)
    add         a2, a2, a3
    vwmulu.vv   v19, v2, v2
    vwmulu.vv   v20, v2, v3
    vwmulu.vv   v21, v3, v3
    vwaddu.vv   v8, v0, v2
    vwaddu.vv   v9, v1, v3

    vle8.v      v4, (a0)
    add         a0, a0, a1
    vle8.v      v5, (a2)
    add         a2, a2, a3
    vwmulu.vv   v22, v4, v4
    vwmulu.vv   v23, v4, v5
    vwmulu.vv   v24, v5, v5
    vwaddu.wv   v30, v8, v4
    vwaddu.wv   v31, v9, v5 

    vle8.v      v6, (a0)
    add         a0, a0, a1
    vle8.v      v7, (a2)
    add         a2, a2, a3
    vwmulu.vv   v25, v6, v6
    vwmulu.vv   v26, v6, v7
    vwmulu.vv   v27, v7, v7
    vwaddu.wv   v0, v30, v6
    vwaddu.wv   v1, v31, v7

    vsetivli    zero, 8, e16, m1, ta, ma
    vwaddu.vv   v8, v16, v18
    vwaddu.vv   v10, v19, v21
    vwaddu.vv   v12, v22, v24
    vwaddu.vv   v14, v25, v27

    vwaddu.vv   v16, v17, v20
    vwaddu.vv   v18, v23, v26

    vslidedown.vi   v2, v0, 4
    vslidedown.vi   v3, v1, 4

    vsetivli    zero, 4, e16, mf2, ta, ma
    vmv.v.i     v4, 0
    vmv.v.i     v5, 0
    vwredsumu.vs    v4, v0, v4
    vwredsumu.vs    v5, v2, v5
    vmv.v.i     v6, 0
    vmv.v.i     v7, 0
    vwredsumu.vs    v6, v1, v6
    vwredsumu.vs    v7, v3, v7
    
    vsetivli    zero, 8, e32, m2, ta, ma
    vmv.x.s     t0, v4
    vmv.x.s     t1, v5
    vmv.x.s     t2, v6
    vmv.x.s     t3, v7
    
    vadd.vv     v8, v8, v10
    vadd.vv     v12, v12, v14
    vadd.vv     v16, v16, v18
    vadd.vv     v8, v8, v12

    vslidedown.vi   v28, v8, 4
    vslidedown.vi   v30, v16, 4

    vsetivli    zero, 4, e32, m1, ta, ma
    vmv.s.x     v6, zero
    vmv.s.x     v7, zero
    vredsum.vs  v6, v8, v6
    vredsum.vs  v7, v28, v7
    vmv.x.s     t4, v6
    vmv.x.s     t5, v7
    
    vmv.s.x     v6, zero
    vmv.s.x     v7, zero
    vredsum.vs  v6, v16, v6
    vredsum.vs  v7, v30, v7
    vmv.x.s     a5, v6
    vmv.x.s     a6, v7

    sw          t0, (a4)
    addi        a4, a4, 4
    sw          t2, (a4)
    addi        a4, a4, 4
    sw          t4, (a4)
    addi        a4, a4, 4
    sw          a5, (a4)
    addi        a4, a4, 4
    sw          t1, (a4)
    addi        a4, a4, 4
    sw          t3, (a4)
    addi        a4, a4, 4
    sw          t5, (a4)
    addi        a4, a4, 4
    sw          a6, (a4)

    ret
endfunc

function pixel_ssim_end4_rvv
    vsetivli        zero, 4, e32, m1, ta, ma
    li  a5, 4
    vle32.v         v16, (a0)
    addi            a0, a0, 16
    vle32.v         v17, (a0)
    addi            a0, a0, 16
    vle32.v         v18, (a1)
    addi            a1, a1, 16
    vle32.v         v19, (a1)
    addi            a1, a1, 16

    li              a4, 0x99bb
    sub             a2, a5, a2
    li              a3, 0x1a0
    li              a4, 0x399bb
    vadd.vv         v28, v16, v18
    vadd.vv         v1, v17, v19
    vadd.vv         v28, v28, v1
    vle32.v         v20, (a0)
    addi            a0, a0, 16
    vle32.v         v21, (a0)
    addi            a0, a0, 16
    vle32.v         v22, (a1)
    addi            a1, a1, 16
    vle32.v         v23, (a1)
    addi            a1, a1, 16
    vadd.vv         v2, v20, v22
    vadd.vv         v3, v21, v23
    vadd.vv         v1, v1, v2
    vle32.v         v16, (a0)
    addi            a0, a0, 16
    vle32.v         v18, (a1)
    addi            a1, a1, 16
    vadd.vv         v16, v16, v18
    vadd.vv         v2, v2, v3
    vadd.vv         v3, v3, v16

    vmv.v.x         v30, a3
    vmv.v.x         v31, a4

    vtrn_4s         v4, v5, v28, v1, v8, v9, v10, t0
    vtrn_4s         v6, v7, v2, v3, v8, v9, v10, t0

    vsetivli    zero, 2, e64, m1, ta, ma
    vmv1r.v     v28, v4
    vmv1r.v     v2, v6
    vmv1r.v     v1, v5
    vmv1r.v     v3, v7
    vslideup.vi v28, v6, 1
    vslideup.vi v1, v7, 1
    vsetivli    zero, 1, e64, m1, tu, ma
    vslidedown.vi   v2, v4, 1
    vslidedown.vi   v3, v5, 1

    vsetivli    zero, 4, e32, m1, ta, ma
    vmul.vv     v16, v28, v1
    vmul.vv     v28, v28, v28
    vmacc.vv    v28, v1, v1

    vsll.vi     v3, v3, 7
    vsll.vi     v2, v2, 6
    vadd.vv     v1, v16, v16

    vsub.vv     v2, v2, v28
    vsub.vv     v3, v3, v1
    vadd.vv     v28, v28, v30
    vadd.vv     v2, v2, v31
    vadd.vv     v1, v1, v30
    vadd.vv     v3, v3, v31

    vfcvt.f.x.v     v28, v28
    vfcvt.f.x.v     v2, v2
    vfcvt.f.x.v     v1, v1
    vfcvt.f.x.v     v3, v3

    vfmul.vv        v28, v28, v2
    vfmul.vv        v1, v1, v3

    vfdiv.vv        v28, v1, v28

    beq             a2, zero, 1f
    movrel          a3, mask
    slli            t1, a2, 2
    add             a3, a3, t1
    vle32.v         v29, (a3)
    vsetivli        zero, 16, e8, m1, ta, ma
    vand.vv         v28, v28, v29
1:
    vsetivli        zero, 4, e32, m1, ta, ma
    vmv.s.x         v8, zero
    vfredusum.vs    v8, v28 , v8
    vfmv.f.s        fa0, v8

    ret
endfunc

#else /* BIT_DEPTH == 8 */


// BIT_DEPTH == 10 Unverified

function satd_16x4_rvv, export=0
    vsetivli    zero, 8, e16, m1, ta, ma
    vle16.v     v0, (a2)
    addi        t0, a2, 16
    vle16.v     v1, (t0)
    add         a2, a2, a3
    vle16.v     v2, (a0)
    addi        t1, a0, 16
    vle16.v     v3, (t1)
    add         a0, a0, a1

    vsub.vv     v16, v2, v0
    vsub.vv     v20, v3, v1
    
    vle16.v     v4, (a2)
    addi        t0, a2, 16
    vle16.v     v5, (t0)
    add         a2, a2, a3
    vle16.v     v6, (a0)
    addi        t1, a0, 16
    vle16.v     v7, (t1)
    add         a0, a0, a1

    vsub.vv     v17, v6, v4
    vsub.vv     v21, v7, v5

    vle16.v     v0, (a2)
    addi        t0, a2, 16
    vle16.v     v1, (t0)
    add         a2, a2, a3
    vle16.v     v2, (a0)
    addi        t1, a0, 16
    vle16.v     v3, (t1)
    add         a0, a0, a1

    vsub.vv     v18, v2, v0
    vsub.vv     v22, v3, v1
    
    vle16.v     v4, (a2)
    addi        t0, a2, 16
    vle16.v     v5, (t0)
    add         a2, a2, a3
    vle16.v     v6, (a0)
    addi        t1, a0, 16
    vle16.v     v7, (t1)
    add         a0, a0, a1

    vsub.vv     v19, v6, v4
    vsub.vv     v23, v7, v5
    
    SUMSUB_AB   v0, v1, v16, v17
    SUMSUB_AB   v2, v3, v18, v19

    j           satd_8x4v_8x8h_rvv
endfunc



function pixel_vsad_rvv
    vsetivli     zero, 16, e16, m2, ta, ma
    addi        a2, a2, -2
    slli        a1, a1, 1
    vmv.s.x     v30, zero

    vle16.v     v0, (a0)
    add         a0, a0, a1
    vle16.v     v2, (a0)
    add         a0, a0, a1
    uabd        v6, v0, v2, v8
    ble         a2, zero, 2f

1:
    addi        a2, a2, -2

    vle16.v     v0, (a0)
    add         a0, a0, a1
    uaba        v6, v2, v0, v8, v10
    vle16.v     v2, (a0)
    add         a0, a0, a1
    blt         a2, zero, 2f
    uaba        v6, v0, v2, v8, v10
    bgt         a2, zero, 1b
2:
    vredsum.vs  v30, v6, v30
    vmv.x.s     a0, v30

    ret
endfunc

// SA8D functions

.macro sa8d_satd_8x8 satd=
function pixel_sa8d_\satd\()8x8_rvv
    load_diff_fly_8x8

    SUMSUB_AB   v16, v18, v28, v2
    SUMSUB_AB   v17, v19, v1, v3

    HADAMARD4_V v20, v21, v22, v23, v28, v1, v2, v3
.ifc \satd, satd_
    vtrn_8h     v28, v1, v16, v17, v8, v9, v10
    vtrn_8h     v2, v3, v18, v19, v8, v9, v10
    vtrn_8h     v4, v5, v20, v21, v8, v9, v10
    vtrn_8h     v6, v7, v22, v23, v8, v9, v10

    SUMSUB_AB   v24, v25, v28, v1
    SUMSUB_AB   v26, v27, v2, v3
    SUMSUB_AB   v28, v1, v4, v5
    SUMSUB_AB   v2, v3, v6, v7

    vtrn_4s     v4, v6, v24, v26, v8, v9, v10, t5
    vtrn_4s     v5, v7, v25, v27, v8, v9, v10, t5
    vtrn_4s     v24, v26, v28, v2, v8, v9, v10, t5
    vtrn_4s     v25, v27, v1, v3, v8, v9, v10, t5

    vabs        v28, v4, v8
    vabs        v1, v5, v8
    vabs        v2, v6, v8
    vabs        v3, v7, v8
    vabs        v4, v24, v8
    vabs        v5, v25, v8
    vabs        v6, v26, v8
    vabs        v7, v27, v8

    vmaxu.vv    v28, v28, v2
    vmaxu.vv    v1, v1, v3
    vmaxu.vv    v2, v4, v6
    vmaxu.vv    v3, v5, v7

    vadd.vv     v26, v28, v1
    vadd.vv     v27, v2, v3
.endif

    SUMSUB_AB   v28, v16, v16, v20
    SUMSUB_AB   v1, v17, v17, v21
    SUMSUB_AB   v2, v18, v18, v22
    SUMSUB_AB   v3, v19, v19, v23

    vtrn_8h     v20, v21, v16, v17, v8, v9, v10
    vtrn_8h     v4, v5, v28, v1, v8, v9, v10
    vtrn_8h     v22, v23, v18, v19, v8, v9, v10
    vtrn_8h     v6, v7, v2, v3, v8, v9, v10

    SUMSUB_AB   v2, v3, v20, v21
    SUMSUB_AB   v24, v25, v4, v5
    SUMSUB_AB   v28, v1, v22, v23
    SUMSUB_AB   v4, v5, v6, v7

    vtrn_4s     v20, v22, v2, v28, v8, v9, v10, t5
    vtrn_4s     v21, v23, v3, v1, v8, v9, v10, t5
    vtrn_4s     v16, v18, v24, v4, v8, v9, v10, t5
    vtrn_4s     v17, v19, v25, v5, v8, v9, v10, t5

    SUMSUB_AB   v28, v2, v20, v22
    SUMSUB_AB   v1, v3, v21, v23
    SUMSUB_AB   v4, v6, v16, v18
    SUMSUB_AB   v5, v7, v17, v19

    vsetivli    zero, 2, e64, m1, ta, ma
    vmv1r.v v16, v28
    vmv1r.v v20, v4
    vmv1r.v v17, v1
    vmv1r.v v21, v5
    vmv1r.v v18, v2
    vmv1r.v v22, v6
    vmv1r.v v19, v3
    vmv1r.v v23, v7
    vslideup.vi v16, v4, 1
    vslideup.vi v17, v5, 1
    vslideup.vi v18, v6, 1
    vslideup.vi v19, v7, 1
    vsetivli    zero, 1, e64, m1, tu, ma
    vslidedown.vi v20, v28, 1
    vslidedown.vi v21, v1, 1
    vslidedown.vi v22, v2, 1
    vslidedown.vi v23, v3, 1

    vsetivli    zero, 8, e16, m1, ta, ma
    vabs        v16, v16, v8
    vabs        v17, v17, v8
    vabs        v18, v18, v8
    vabs        v19, v19, v8
    vabs        v20, v20, v8
    vabs        v21, v21, v8
    vabs        v22, v22, v8
    vabs        v23, v23, v8

    vmaxu.vv    v16, v16, v20
    vmaxu.vv    v17, v17, v21
    vmaxu.vv    v18, v18, v22
    vmaxu.vv    v19, v19, v23

    vadd.vv     v28, v16, v17
    vadd.vv     v1, v18, v19

    ret
endfunc
.endm


function pixel_ssd_nv12_core_rvv
    mv          t0, a4
    addi        t0, t0, 8
    andi        t0, t0, -16

    vsetivli    zero, 2, e64, m1, ta, ma
    vmv.v.x     v6, zero
    vmv.v.x     v7, zero
    slli        t1, t0, 1
    sub         a1, a1, t1
    sub         a3, a3, t1

    slli        a1, a1, 1
    slli        a3, a3, 1
    slli        a4, a4, 1
1:
    li          t2, 32
    sub         t3, a4, t2
    # Load interleaved U and V components from both images
    vsetivli    zero, 8, e16, m1, ta, ma
    vlseg2e16.v v0, (a0)
    add         a0, a0, t2
    vlseg2e16.v v2, (a2)
    add         a2, a2, t2
    vlseg2e16.v v24, (a0)
    add         a0, a0, t2
    vlseg2e16.v v26, (a2)
    add         a2, a2, t2

    vsub.vv     v16, v0, v2
    vsub.vv     v17, v1, v3
    vsub.vv     v18, v24, v26
    vsub.vv     v19, v25, v16

    vsetivli    zero, 4, e16, mf2, ta, ma
    vwmul.vv    v20, v16, v16
    vwmul.vv    v21, v17, v17
    vsetivli    zero, 8, e16, m1, ta, ma
    vslidedown.vi   v28, v16, 4
    vslidedown.vi   v29, v17, 4
    vsetivli    zero, 4, e16, mf2, ta, ma
    vwmacc.vv   v20, v28, v28
    vwmacc.vv   v21, v29, v29

    blt         t2, zero, 4f
    beq         t2, zero, 3f
2:
    vsetivli    zero, 4, e16, mf2, ta, ma
    vwmacc.vv   v20, v18, v18
    vwmacc.vv   v21, v19, v19
    vsetivli    zero, 8, e16, m1, ta, ma
    vlseg2e16.v v0, (a0)
    addi        a0, a0, 32
    vlseg2e16.v v2, (a2)
    addi        a2, a2, 32
    vlseg2e16.v v24, (a0)
    addi        a0, a0, 32
    vlseg2e16.v v26, (a2)
    addi        a2, a2, 32
    vslidedown.vi   v28, v18, 4
    vslidedown.vi   v29, v19, 4
    vsetivli    zero, 4, e16, mf2, ta, ma
    vwmacc.vv   v20, v28, v28
    vwmacc.vv   v21, v29, v29

    addi        t2, t2, -32
    vsetivli    zero, 8, e16, m1, ta, ma
    vsub.vv     v16, v0, v2
    vsub.vv     v17, v1, v3
    vsetivli    zero, 4, e16, mf2, ta, ma
    vwmacc.vv   v20, v16, v16
    vwmacc.vv   v21, v17, v17
    vsetivli    zero, 8, e16, m1, ta, ma
    vslidedown.vi   v28, v16, 4
    vslidedown.vi   v29, v17, 4
    vsetivli    zero, 4, e16, mf2, ta, ma
    vwmacc.vv   v20, v28, v28
    vwmacc.vv   v21, v29, v29
    blt         t2, zero, 4f

    vsetivli    zero, 8, e16, m1, ta, ma
    vsub.vv     v18, v24, v26
    vsub.vv     v19, v25, v27
    bgt         t2, zero, 2b
3:
    vsetivli    zero, 4, e16, mf2, ta, ma
    vwmacc.vv   v20, v18, v18
    vwmacc.vv   v21, v19, v19
    vsetivli    zero, 8, e16, m1, ta, ma
    vslidedown.vi   v28, v18, 4
    vslidedown.vi   v29, v19, 4
    vsetivli    zero, 4, e16, mf2, ta, ma
    vwmacc.vv   v20, v28, v28
    vwmacc.vv   v21, v29, v29
4:
    addi        a5, a5, -1
    vsetivli    zero, 2, e32, mf2, ta, ma
    vwaddu.wv   v8, v6, v20
    vwaddu.wv   v9, v7, v21
    add         a0, a0, a1
    add         a2, a2, a3
    vsetivli    zero, 4, e32, m1, ta, ma
    vslidedown.vi   v30, v20, 2
    vslidedown.vi   v31, v21, 2
    vsetivli    zero, 2, e32, mf2, ta, ma
    vwaddu.vv   v6, v8, v30
    vwaddu.vv   v7, v9, v31

    bgt         a5, zero, 1b
    
    vsetivli    zero, 2, e64, m1, ta, ma
    vslidedown.vi   v8, v6, 1
    vslidedown.vi   v9, v7, 1

    vmv.x.s         t4, v6
    vmv.x.s         t5, v8
    add             t4, t4, t5
    vmv.x.s         t6, v7
    vmv.x.s         t0, v9
    add             t0, t6, t0

    sd              t4, (a6)
    sd              t0, (a7)
    ret
endfunc

#endif /* BIT_DEPTH == 8 */