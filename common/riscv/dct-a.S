/****************************************************************************
 * dct-a.S: riscv transform and zigzag
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

const   scan4x4_frame, align=4
    .byte    0,1,   8,9,   2,3,   4,5
    .byte   10,11, 16,17, 24,25, 18,19
    .byte   12,13,  6,7,  14,15, 20,21
    .byte   26,27, 28,29, 22,23, 30,31
endconst

# sum = a + (b>>shift) sub = (a>>shift) - b
.macro      SUMSUB_SHR shift sum sub a b t0 t1
    vsra.vi         \t0, \b, \shift
    vsra.vi         \t1, \a, \shift
    vadd.vv         \sum, \a, \t0
    vsub.vv         \sub, \t1, \b
.endm

# sum = (a>>shift) + b sub = a - (b>>shift)
.macro SUMSUB_SHR2 shift sum sub a b t0 t1
    vsra.vi         \t0, \a, \shift
    vsra.vi         \t1, \b, \shift
    vadd.vv         \sum, \t0, \b
    vsub.vv         \sub, \a, \t1
.endm

# a += 1.5*ma b -= 1.5*mb
.macro SUMSUB_15 a b ma mb t0 t1
    vsra.vi         \t0, \ma, 1
    vsra.vi         \t1, \mb, 1
    vadd.vv         \t0, \t0, \ma
    vadd.vv         \t1, \t1, \mb
    vadd.vv         \a, \a, \t0
    vsub.vv         \b, \b, \t1
.endm

function dct4x4dc_rvv
    mv              t2, a0
    vsetivli        zero, 4, e16, mf2, ta, ma
    li              t1, 8
    vlsseg4e16.v    v2, (a0), t1
    SUMSUB_ABCD     v6, v7, v8, v9, v2, v3, v4, v5
    SUMSUB_ABCD     v2, v3, v5, v4, v6, v8, v7, v9
    vse16.v         v2, (t2)
    add             t2, t2, t1
    vse16.v         v3, (t2)
    add             t2, t2, t1
    vse16.v         v4, (t2)
    add             t2, t2, t1
    vse16.v         v5, (t2)
    vlsseg4e16.v    v2, (a0), t1
    SUMSUB_ABCD     v6, v7, v8, v9, v2, v3, v4, v5
    vwadd.vv        v2, v6, v8
    vwsub.vv        v3, v6, v8
    vwadd.vv        v5, v7, v9
    vwsub.vv        v4, v7, v9

    csrwi           vxrm, 0
    vnclip.wi       v2, v2, 1
    vnclip.wi       v3, v3, 1
    vnclip.wi       v4, v4, 1
    vnclip.wi       v5, v5, 1

    vssseg4e16.v    v2, (a0), t1
    ret
endfunc

function idct4x4dc_rvv
    add             t2, zero, a0
    vsetivli        zero, 4, e16, mf2, ta, ma
    li t1, 8
    vlsseg4e16.v    v2, (a0), t1
    SUMSUB_ABCD     v6, v7, v8, v9, v2, v3, v4, v5
    SUMSUB_ABCD     v2, v3, v5, v4, v6, v8, v7, v9
    vse16.v         v2, (t2)
    add t2,         t2, t1
    vse16.v         v3, (t2)
    add t2,         t2, t1
    vse16.v         v4, (t2)
    add t2,         t2, t1
    vse16.v         v5, (t2)
    vlsseg4e16.v    v2, (a0), t1
    SUMSUB_ABCD     v6, v7, v8, v9, v2, v3, v4, v5
    SUMSUB_ABCD     v2, v3, v5, v4, v6, v8, v7, v9
    vssseg4e16.v    v2, (a0), t1
    ret
endfunc

.macro DCT_1D d0 d1 d2 d3 d4 d5 d6 d7
    SUMSUB_AB       \d1, \d6, \d5, \d6
    SUMSUB_AB       \d3, \d7, \d4, \d7
    vadd.vv         \d0, \d3, \d1
    vadd.vv         \d4, \d7, \d7
    vadd.vv         \d5, \d6, \d6
    vsub.vv         \d2, \d3, \d1
    vadd.vv         \d1, \d4, \d6
    vsub.vv         \d3, \d7, \d5
.endm

function sub4x4_dct_rvv
    vsetivli        zero, 4, e8, mf4, ta, ma
    li              t1, FENC_STRIDE
    li              t2, FDEC_STRIDE
      
    vle8.v          v0, (a1)
    add             a1, a1, t1   
    vle8.v          v1, (a2)
    add             a2, a2, t2
    vle8.v          v2, (a1)
    add             a1, a1, t1
    vwsubu.vv       v8, v0, v1
    vle8.v          v3, (a2)
    add             a2, a2, t2
    vle8.v          v4, (a1)  
    add             a1, a1, t1
    vwsubu.vv       v9, v2, v3
    vle8.v          v5, (a2)
    add             a2, a2, t2
    vle8.v          v6, (a1)
    add             a1, a1, t1
    vwsubu.vv       v10, v4, v5
    vle8.v          v7, (a2)
    add             a2, a2, t2
    vwsubu.vv       v11, v6, v7

    vsetvli         zero, zero, e16, mf2, ta, ma
    DCT_1D          v0, v1, v2, v3, v8, v9, v10, v11

    // TRANSPOSE4x4_16 v0, v1, v2, v3
    // zip way
     li t5, 32
     vsetivli zero, 4, e32, m1, ta, ma
     vslideup.vi v0, v1, 2
     vslideup.vi v2, v3, 2

     vsetivli zero, 8, e32, m2, ta, ma
     vslideup.vi v0, v2, 4
     vsetivli zero, 4, e32, m1, ta, ma
     // vmv1r.v v1, v2
     
     vnsrl.wi v4, v0, 0
     vnsrl.wx v6, v0, t5
     vsetivli zero, 4, e16, mf2, ta, ma
     vnsrl.wi v0, v4, 0
     vnsrl.wi v1, v4, 16
     vnsrl.wi v2, v6, 0
     vnsrl.wi v3, v6, 16

    DCT_1D          v4, v5, v6, v7, v0, v1, v2, v3

    vse16.v         v4, (a0)
    addi             a0, a0, 8
    vse16.v         v5, (a0)
    addi             a0, a0, 8
    vse16.v         v6, (a0)
    addi             a0, a0, 8
    vse16.v         v7, (a0)
    ret
endfunc

function sub8x4_dct_rvv, export=0
    vsetivli        zero, 8, e8, mf2, ta, ma
    vle8.v          v4, (a1)
    add             a1, a1, t1   
    vle8.v          v5, (a2)
    add             a2, a2, t2
    vwsubu.vv       v16, v4, v5
    vle8.v          v6, (a1)
    add             a1, a1, t1
    vle8.v          v7, (a2)
    add             a2, a2, t2
    vwsubu.vv       v17, v6, v7
    vle8.v          v4, (a1)  
    add             a1, a1, t1
    vle8.v          v5, (a2)
    add             a2, a2, t2
    vwsubu.vv       v18, v4, v5
    vle8.v          v6, (a1)
    add             a1, a1, t1
    vle8.v          v7, (a2)
    add             a2, a2, t2
    vwsubu.vv       v19, v6, v7

    vsetvli         zero, zero, e16, m1, ta, ma
    DCT_1D          v4, v5, v6, v7, v16, v17, v18, v19

    TRANSPOSE4x8_16 t4, v4, v5, v6, v7, v23, v24, v25, v26

    SUMSUB_AB       v16, v19, v4, v7
    SUMSUB_AB       v17, v18, v5, v6

    vadd.vv         v22, v19, v19
    vadd.vv         v21, v18, v18
    vadd.vv         v0, v16, v17
    vsub.vv         v1, v16, v17

    vadd.vv         v2, v22, v18
    vsub.vv         v3, v19, v21

    // zip
    vsetivli        zero, 2, e64, m1, ta, ma
    vmv1r.v         v4, v0
    vslideup.vi     v4, v2, 1
    vmv1r.v         v5, v1
    vslideup.vi     v5, v3, 1
    
    vmv1r.v         v6, v2
    vmv1r.v         v7, v3
    vsetivli        zero, 1, e64, m1, ta, ma
    vslidedown.vi   v6, v0, 1
    vslidedown.vi   v7, v1, 1

    vsetivli        zero, 8, e16, m1, ta, ma
    vse16.v         v4, (a0)
    addi            a0, a0, 16
    vse16.v         v5, (a0)
    addi            a0, a0, 16
    vse16.v         v6, (a0)
    addi            a0, a0, 16
    vse16.v         v7, (a0)
    addi            a0, a0, 16
    ret
endfunc

function sub8x8_dct_rvv
    mv              t6, ra
    li              t1, FENC_STRIDE
    li              t2, FDEC_STRIDE

    jal             sub8x4_dct_rvv
    mv              ra, t6
    j               sub8x4_dct_rvv
endfunc

function sub16x16_dct_rvv
    mv              t6, ra
    li              t1, FENC_STRIDE
    li              t2, FDEC_STRIDE
    jal             sub8x4_dct_rvv
    jal             sub8x4_dct_rvv
    li              t5, 8*FENC_STRIDE-8
    sub             a1, a1, t5
    li              t5, 8*FDEC_STRIDE-8
    sub             a2, a2, t5
    jal             sub8x4_dct_rvv
    jal             sub8x4_dct_rvv
    addi            a1, a1, -8
    addi            a2, a2, -8
    jal             sub8x4_dct_rvv
    jal             sub8x4_dct_rvv
    li              t5, 8*FENC_STRIDE-8
    sub             a1, a1, t5
    li              t5, 8*FDEC_STRIDE-8
    sub             a2, a2, t5
    jal             sub8x4_dct_rvv
    mv              ra, t6
    j               sub8x4_dct_rvv
endfunc


.macro DCT8_1D type
    SUMSUB_AB       v18, v17, v3,  v4   // s34/d34
    SUMSUB_AB       v19, v16, v2,  v5   // s25/d25
    SUMSUB_AB       v22, v21, v1,  v6   // s16/d16
    SUMSUB_AB       v23, v20, v0,  v7   // s07/d07

    SUMSUB_AB       v24, v26, v23, v18  // a0/a2
    SUMSUB_AB       v25, v27, v22, v19  // a1/a3

    SUMSUB_AB       v30, v29, v20, v17  // a6/a5
    vsra.vi         v23, v21, 1
    vsra.vi         v18, v16, 1
    vadd.vv         v23, v23, v21
    vadd.vv         v18, v18, v16
    vsub.vv         v30, v30, v23
    vsub.vv         v29, v29, v18

    SUMSUB_AB       v28, v31, v21, v16   // a4/a7
    vsra.vi         v22, v20, 1
    vsra.vi         v19, v17, 1
    vadd.vv         v22, v22, v20
    vadd.vv         v19, v19, v17
    vadd.vv         v22, v28, v22
    vadd.vv         v31, v31, v19

    SUMSUB_AB       v0,  v4,  v24, v25
    SUMSUB_SHR      2, v1,  v7,  v22, v31, v16, v17
    SUMSUB_SHR      1, v2,  v6,  v26, v27, v18, v19
    SUMSUB_SHR2     2, v3,  v5,  v30, v29, v20, v21
.endm

function sub8x8_dct8_rvv
    li          t0, FENC_STRIDE
    li          t1, FDEC_STRIDE

    vsetivli    zero, 8, e8, mf2, ta, ma
    vle8.v      v16, (a1)
    add         a1, a1, t0
    vle8.v      v17, (a2)
    add         a2, a2, t1
    vle8.v      v18, (a1)
    add         a1, a1, t0
    vle8.v      v19, (a2)
    add         a2, a2, t1
    vwsubu.vv   v0, v16, v17
    vle8.v      v20, (a1)
    add         a1, a1, t0
    vle8.v      v21, (a2)
    add         a2, a2, t1
    vwsubu.vv   v1, v18, v19
    vle8.v      v22, (a1)
    add         a1, a1, t0
    vle8.v      v23, (a2)
    add         a2, a2, t1
    vwsubu.vv   v2, v20, v21
    vle8.v      v24, (a1)
    add         a1, a1, t0
    vle8.v      v25, (a2)
    add         a2, a2, t1
    vwsubu.vv   v3, v22, v23
    vle8.v      v26, (a1)
    add         a1, a1, t0
    vle8.v      v27, (a2)
    add         a2, a2, t1
    vwsubu.vv   v4, v24, v25
    vle8.v      v28, (a1)
    add         a1, a1, t0
    vle8.v      v29, (a2)
    add         a2, a2, t1
    vwsubu.vv   v5, v26, v27
    vle8.v      v30, (a1)
    add         a1, a1, t0
    vle8.v      v31, (a2)
    add         a2, a2, t1
    vwsubu.vv   v6, v28, v29
    vwsubu.vv   v7, v30, v31

    vsetivli     zero, 8, e16, m1, ta, ma
    DCT8_1D     row
    TRANSPOSE8x8_16 v0, v1, v2, v3, v4, v5, v6, v7
    DCT8_1D     col

    vsetivli    zero, 8, e16, m1, ta, ma
    vse16.v     v0, (a0)
    add         a0, a0, 16
    vse16.v     v1, (a0)
    add         a0, a0, 16
    vse16.v     v2, (a0)
    add         a0, a0, 16
    vse16.v     v3, (a0)
    add         a0, a0, 16
    vse16.v     v4, (a0)
    add         a0, a0, 16
    vse16.v     v5, (a0)
    add         a0, a0, 16
    vse16.v     v6, (a0)
    add         a0, a0, 16
    vse16.v     v7, (a0)
    add         a0, a0, 16

    ret
endfunc

function sub16x16_dct8_rvv
    mv          t6, ra

    jal         X(sub8x8_dct8_rvv)
    li          t5, 8*FENC_STRIDE-8
    li          t4, 8*FDEC_STRIDE-8
    sub         a1, a1, t5
    sub         a2, a2, t4
    jal         X(sub8x8_dct8_rvv)
    addi        a1, a1, -8
    addi        a2, a2, -8
    jal         X(sub8x8_dct8_rvv)
    mv          ra, t6
    sub         a1, a1, t5
    sub         a2, a2, t4
    j           X(sub8x8_dct8_rvv)
endfunc

// First part of IDCT (minus final SUMSUB_BA)
.macro IDCT_1D d4, d5, d6, d7, d0, d1, d2, d3
    SUMSUB_AB   \d4, \d5, \d0, \d2
    vsra.vi     \d7, \d1, 1
    vsra.vi     \d6, \d3, 1
    vsub.vv     \d7, \d7, \d3
    vadd.vv     \d6, \d6, \d1
.endm

function add4x4_idct_rvv
    li          t0, FDEC_STRIDE
    vsetivli    zero, 4, e16, mf2, ta, ma

    vle16.v     v0, (a1)
    addi        t1, a1, 8
    vle16.v     v1, (t1)
    addi        t1, t1, 8
    vle16.v     v2, (t1)
    addi        t1, t1, 8
    vle16.v     v3, (t1)

    IDCT_1D     v4, v5, v6, v7, v0, v1, v2, v3
    
    SUMSUB_AB   v0, v3, v4, v6
    SUMSUB_AB   v1, v2, v5, v7

    // TRANSPOSE4x4_16  v0, v1, v2, v3
    // zip way
     li t5, 32
     vsetivli zero, 4, e32, m1, ta, ma
     vslideup.vi v0, v1, 2
     vslideup.vi v2, v3, 2

     vsetivli zero, 8, e32, m2, ta, ma
     vslideup.vi v0, v2, 4
     vsetivli zero, 4, e32, m1, ta, ma
     // vmv1r.v v1, v2
     vnsrl.wi v4, v0, 0
     vnsrl.wx v6, v0, t5
     vsetivli zero, 4, e16, mf2, ta, ma
     vnsrl.wi v0, v4, 0
     vnsrl.wi v1, v4, 16
     vnsrl.wi v2, v6, 0
     vnsrl.wi v3, v6, 16

    IDCT_1D     v4, v5, v6, v7, v0, v1, v2, v3

    SUMSUB_AB   v0, v2, v4, v6
    SUMSUB_AB   v1, v3, v5, v7

    vssra.vi    v0, v0, 6
    vssra.vi    v1, v1, 6
    vssra.vi    v2, v2, 6
    vssra.vi    v3, v3, 6

    vsetivli    zero, 4, e8, mf4, ta, ma
    vle8.v      v28, (a0)
    add         t3, a0, t0
    vle8.v      v29, (t3)
    add         t3, t3, t0
    vle8.v      v31, (t3)
    add         t3, t3, t0
    vle8.v      v30, (t3)
    add         t3, t3, t0

    vwaddu.wv   v0, v0, v28
    vwaddu.wv   v1, v1, v29
    vwaddu.wv   v2, v2, v30
    vwaddu.wv   v3, v3, v31

    vsetivli zero, 4, e16, mf2, ta, ma
    vmax.vx   v0, v0, zero
    vmax.vx   v1, v1, zero
    vmax.vx   v2, v2, zero
    vmax.vx   v3, v3, zero


    csrwi  vxrm, 0
    vsetivli zero, 4, e8, mf4, ta, ma
    vnclipu.wi v4, v0, 0
    vnclipu.wi v5, v1, 0
    vnclipu.wi v6, v2, 0
    vnclipu.wi v7, v3, 0

    vse8.v     v4, (a0)
    add        a0, a0, t0
    vse8.v     v5, (a0)
    add        a0, a0, t0
    vse8.v     v7, (a0)
    add        a0, a0, t0
    vse8.v     v6, (a0)

    ret
endfunc

function add8x4_idct_rvv
    vsetivli    zero, 8, e16, m1, ta, ma
    mv          t1, a1

    vle16.v     v0, (a1)
    addi        a1, a1, 16
    vle16.v     v1, (a1)
    addi        a1, a1, 16
    vle16.v     v2, (a1)
    addi        a1, a1, 16
    vle16.v     v3, (a1)
    addi        a1, a1, 16

    # transpose v0, v2
    # transpose v1, v3
    vsetivli    zero, 2, e64, m1, ta, ma
    vmv1r.v     v20, v0
    vslideup.vi v0, v2, 1
    vmv1r.v     v22, v1
    vslideup.vi v1, v3, 1
    vsetivli    zero, 1, e64, m1, ta, ma
    vslidedown.vi v2, v20, 1
    vslidedown.vi v3, v22, 1

    vsetivli    zero, 8, e16, m1, ta, ma
    IDCT_1D     v16, v17, v18, v19, v0, v2, v1, v3

    SUMSUB_AB   v4,  v7,  v16, v18
    SUMSUB_AB   v5,  v6,  v17, v19

    TRANSPOSE4x8_16 t2, v4, v5, v6, v7, v8, v9, v10, v11

    IDCT_1D     v16, v17, v18, v19, v4, v5, v6, v7
    SUMSUB_AB   v0,  v3,  v16, v18
    SUMSUB_AB   v1,  v2,  v17, v19

    vssra.vi    v0, v0, 6
    vssra.vi    v1, v1, 6
    vssra.vi    v2, v2, 6
    vssra.vi    v3, v3, 6

    vsetivli    zero, 8, e8, mf2, tu, ma

    vle8.v      v28, (a0)
    add         t3, a0, t5
    vle8.v      v29, (t3)
    add         t3, t3, t5
    vle8.v      v30, (t3)
    add         t3, t3, t5
    vle8.v      v31, (t3)

    vwaddu.wv   v0, v0, v28
    vwaddu.wv   v1, v1, v29
    vwaddu.wv   v2, v2, v30
    vwaddu.wv   v3, v3, v31

    vsetvli     zero, zero, e16, m1, ta, ma
    vmax.vx     v0, v0, zero
    vmax.vx     v1, v1, zero
    vmax.vx     v2, v2, zero
    vmax.vx     v3, v3, zero

    csrwi  vxrm, 0
    vsetvli     zero, zero, e8, mf2, ta, ma
    vnclipu.wi  v4, v0, 0
    vnclipu.wi  v5, v1, 0
    vnclipu.wi  v6, v2, 0
    vnclipu.wi  v7, v3, 0
    
    vse8.v      v4, (a0)
    add         a0, a0, t5
    vse8.v      v5, (a0)
    add         a0, a0, t5
    vse8.v      v6, (a0)
    add         a0, a0, t5
    vse8.v      v7, (a0)
    add         a0, a0, t5

    ret
endfunc

function add8x8_idct_rvv
    li t5, FDEC_STRIDE
    mv t6, ra
    jal         X(add8x4_idct_rvv)
    mv ra, t6
    j           X(add8x4_idct_rvv)
endfunc

function add16x16_idct_rvv
    li t5, FDEC_STRIDE
    li t4, 8*FDEC_STRIDE-8
    mv t6, ra
    jal         X(add8x4_idct_rvv)
    jal         X(add8x4_idct_rvv)
    sub a0, a0, t4
    jal         X(add8x4_idct_rvv)
    jal         X(add8x4_idct_rvv)
    addi a0, a0, -8
    jal         X(add8x4_idct_rvv)
    jal         X(add8x4_idct_rvv)
    sub a0, a0, t4
    jal         X(add8x4_idct_rvv)
    mv ra, t6
    j           X(add8x4_idct_rvv)
endfunc

.macro IDCT8_1D type
    SUMSUB_AB   v0,  v1,  v16, v20          // a0/a2
.ifc \type, row
    vle16.v     v22, (a1)
    addi        a1, a1, 16
    vle16.v     v23, (a1)
    addi        a1, a1, 16
.endif
    SUMSUB_SHR  1, v2,  v3,  v18, v22, v16, v20   // a6/a4
    SUMSUB_AB   v16, v18, v21, v19
    SUMSUB_15   v16, v18, v17, v23, v20, v22      // a7/a1
    SUMSUB_AB   v22, v23, v23, v17
    SUMSUB_15   v23, v22, v21, v19, v20, v17      // a5/a3

    SUMSUB_SHR  2, v21, v22, v22, v23, v19, v17   // b3/b5
    SUMSUB_SHR2 2, v20, v23, v16, v18, v19, v17   // b1/b7

    SUMSUB_AB   v18, v2,  v0,  v2           // b0/b6
    SUMSUB_AB   v19, v3,  v1,  v3           // b2/b4

    SUMSUB_AB   v16, v23, v18, v23
    SUMSUB_AB   v17, v22, v19, v22
    SUMSUB_AB   v18, v21, v3,  v21
    SUMSUB_AB   v19, v20, v2,  v20
.endm

function add8x8_idct8_rvv
    li          t0, FDEC_STRIDE
    vsetivli    zero, 8, e16, m1, ta, ma
    mv          t1, a1
    vle16.v     v16, (a1)
    addi        a1, a1, 16
    vle16.v     v17, (a1)
    addi        a1, a1, 16
    vle16.v     v18, (a1)
    addi        a1, a1, 16
    vle16.v     v19, (a1)
    addi        a1, a1, 16
    vle16.v     v20, (a1)
    addi        a1, a1, 16
    vle16.v     v21, (a1)
    addi        a1, a1, 16
    

    IDCT8_1D    row

    TRANSPOSE8x8_16 v16, v17, v18, v19, v20, v21, v22, v23

    IDCT8_1D    col

    vssra.vi     v16, v16, 6
    vssra.vi     v17, v17, 6
    vssra.vi     v18, v18, 6
    vssra.vi     v19, v19, 6
    vssra.vi     v20, v20, 6
    vssra.vi     v21, v21, 6
    vssra.vi     v22, v22, 6
    vssra.vi     v23, v23, 6

    vsetivli    zero, 8, e8, mf2, ta, ma
    vle8.v      v0, (a0)
    add         t1, a0, t0
    vle8.v      v1, (t1)
    add         t1, t1, t0
    vle8.v      v2, (t1)
    add         t1, t1, t0
    vle8.v      v3, (t1)
    add         t1, t1, t0
    vle8.v      v4, (t1)
    add         t1, t1, t0
    vle8.v      v5, (t1)
    add         t1, t1, t0
    vle8.v      v6, (t1)
    add         t1, t1, t0
    vle8.v      v7, (t1)
    
    vwaddu.wv   v16, v16, v0
    vwaddu.wv   v17, v17, v1
    vwaddu.wv   v18, v18, v2
    vwaddu.wv   v19, v19, v3
    vwaddu.wv   v20, v20, v4
    vwaddu.wv   v21, v21, v5
    vwaddu.wv   v22, v22, v6
    vwaddu.wv   v23, v23, v7

    vsetvli     zero, zero, e16, m1, ta, ma
    vmax.vx     v16, v16, zero
    vmax.vx     v17, v17, zero
    vmax.vx     v18, v18, zero
    vmax.vx     v19, v19, zero
    vmax.vx     v20, v20, zero
    vmax.vx     v21, v21, zero
    vmax.vx     v22, v22, zero
    vmax.vx     v23, v23, zero

    csrwi  vxrm, 0
    vsetvli zero, zero, e8, mf2, ta, ma
    vnclipu.wi  v0, v16, 0
    vnclipu.wi  v1, v17, 0
    vnclipu.wi  v2, v18, 0
    vnclipu.wi  v3, v19, 0
    vnclipu.wi  v4, v20, 0
    vnclipu.wi  v5, v21, 0
    vnclipu.wi  v6, v22, 0    
    vnclipu.wi  v7, v23, 0

    vse8.v      v0, (a0)
    add         a0, a0, t0
    vse8.v      v1, (a0)  
    add         a0, a0, t0
    vse8.v      v2, (a0)
    add         a0, a0, t0
    vse8.v      v3, (a0)
    add         a0, a0, t0  
    vse8.v      v4, (a0)
    add         a0, a0, t0
    vse8.v      v5, (a0)
    add         a0, a0, t0
    vse8.v      v6, (a0)  
    add         a0, a0, t0
    vse8.v      v7, (a0)
    add         a0, a0, t0      
    ret
endfunc

function add16x16_idct8_rvv
    li          t5, 8*FDEC_STRIDE-8
    mv          t6, ra
    jal         X(add8x8_idct8_rvv)
    sub         a0, a0, t5
    jal         X(add8x8_idct8_rvv)
    addi        a0, a0, -8
    jal         X(add8x8_idct8_rvv)
    sub         a0, a0, t5
    mv          ra, t6
    j           X(add8x8_idct8_rvv)
endfunc

function add8x8_idct_dc_rvv
    li          t5, FDEC_STRIDE
    vsetivli    zero, 8, e8, mf2, ta, ma
    vle8.v      v0, (a0)
    add         t0, a0, t5
    vle8.v      v1, (t0)
    add         t0, t0, t5
    vle8.v      v2, (t0)
    add         t0, t0, t5
    vle8.v      v3, (t0)
    add         t0, t0, t5
    vle8.v      v4, (t0)
    add         t0, t0, t5
    vle8.v      v5, (t0)
    add         t0, t0, t5
    vle8.v      v6, (t0)
    add         t0, t0, t5
    vle8.v      v7, (t0)

    vsetivli    zero, 4, e16, mf2, ta, ma
    vle16.v     v16, (a1)
    vssra.vi    v16, v16, 6
    vsetivli    zero, 8, e16, m1, ta, ma
    vmv.x.s     a3, v16
    vmv.v.x     v20, a3
    vslidedown.vi v16, v16, 1
    vmv.x.s     a3, v16
    vmv.v.x     v21, a3
    vslidedown.vi v16, v16, 1
    vmv.x.s     a3, v16
    vmv.v.x     v22, a3
    vslidedown.vi v16, v16, 1
    vmv.x.s     a3, v16
    vmv.v.x     v23, a3

    vsetivli    zero, 2, e64, m1, ta, ma
    vslideup.vi v20, v21, 1
    vmv1r.v     v21, v22
    vslideup.vi v21, v23, 1

    vsetivli    zero, 8, e16, m1, ta, ma
    vrsub.vi    v22, v20, 0
    vrsub.vi    v23, v21, 0

    vmax.vx     v20, v20, zero
    vmax.vx     v21, v21, zero
    vmax.vx     v22, v22, zero
    vmax.vx     v23, v23, zero

    csrwi  vxrm, 0
    vsetvli     zero, zero, e8, mf2, ta, ma
    vnclipu.wi  v20, v20, 0
    vnclipu.wi  v21, v21, 0
    vnclipu.wi  v22, v22, 0    
    vnclipu.wi  v23, v23, 0

    vsaddu.vv   v0, v0, v20
    vsaddu.vv   v1, v1, v20
    vsaddu.vv   v2, v2, v20
    vsaddu.vv   v3, v3, v20
    vsaddu.vv   v4, v4, v21
    vsaddu.vv   v5, v5, v21
    vsaddu.vv   v6, v6, v21
    vsaddu.vv   v7, v7, v21

    vssubu.vv   v0, v0, v22
    vssubu.vv   v1, v1, v22
    vssubu.vv   v2, v2, v22
    vssubu.vv   v3, v3, v22
    vssubu.vv   v4, v4, v23
    vssubu.vv   v5, v5, v23
    vssubu.vv   v6, v6, v23
    vssubu.vv   v7, v7, v23

    vse8.v      v0, (a0)
    add         a0, a0, t5
    vse8.v      v1, (a0)
    add         a0, a0, t5
    vse8.v      v2, (a0)
    add         a0, a0, t5
    vse8.v      v3, (a0)
    add         a0, a0, t5
    vse8.v      v4, (a0)
    add         a0, a0, t5
    vse8.v      v5, (a0)
    add         a0, a0, t5
    vse8.v      v6, (a0)
    add         a0, a0, t5
    vse8.v      v7, (a0)

    ret
endfunc

.macro ADD16x4_IDCT_DC dc
    vsetivli    zero, 16, e8, m1, ta, ma
    vle8.v      v4, (a0)
    add         a0, a0, t5
    vle8.v      v5, (a0)
    add         a0, a0, t5
    vle8.v      v6, (a0)
    add         a0, a0, t5
    vle8.v      v7, (a0)
    add         a0, a0, t5

    vsetivli    zero, 8, e16, m1, ta, ma
    vmv.x.s     a3, \dc
    vmv.v.x     v24, a3
    vslidedown.vi \dc, \dc, 1
    vmv.x.s     a3, \dc
    vmv.v.x     v25, a3
    vslidedown.vi \dc, \dc, 1
    vmv.x.s     a3, \dc
    vmv.v.x     v26, a3
    vslidedown.vi \dc, \dc, 1
    vmv.x.s     a3, \dc
    vmv.v.x     v27, a3

    vsetivli    zero, 2, e64, m1, ta, ma
    vslideup.vi v24, v25, 1
    vmv1r.v     v25, v26
    vslideup.vi v25, v27, 1

    vsetivli    zero, 8, e16, m1, ta, ma
    vrsub.vi    v26, v24, 0
    vrsub.vi    v27, v25, 0

    vmax.vx     v24, v24, zero
    vmax.vx     v25, v25, zero
    vmax.vx     v26, v26, zero
    vmax.vx     v27, v27, zero

    csrwi  vxrm, 0
    vsetvli     zero, zero, e8, mf2, ta, ma
    vnclipu.wi  v20, v24, 0
    vnclipu.wi  v21, v26, 0
    vnclipu.wi  v22, v25, 0    
    vnclipu.wi  v23, v27, 0
    vsetivli    zero, 16, e8, m1, ta, ma
    vslideup.vi v20, v22, 8
    vslideup.vi v21, v23, 8

    vsaddu.vv   v4, v4, v20
    vsaddu.vv   v5, v5, v20
    vsaddu.vv   v6, v6, v20
    vsaddu.vv   v7, v7, v20

    vssubu.vv   v4, v4, v21
    vssubu.vv   v5, v5, v21
    vssubu.vv   v6, v6, v21
    vssubu.vv   v7, v7, v21

    vse8.v      v4, (a2)
    add         a2, a2, t5
    vse8.v      v5, (a2)
    add         a2, a2, t5
    vse8.v      v6, (a2)
    add         a2, a2, t5
    vse8.v      v7, (a2)
    add         a2, a2, t5
.endm

function add16x16_idct_dc_rvv
    mv          a2, a0
    li          t5, FDEC_STRIDE

    vsetivli     zero, 4, e16, m1, ta, ma
    vle16.v     v0, (a1)
    addi        a1, a1, 8
    vle16.v     v1, (a1)
    addi        a1, a1, 8
    vle16.v     v2, (a1)
    addi        a1, a1, 8
    vle16.v     v3, (a1)

    vssra.vi     v0, v0, 6
    vssra.vi     v1, v1, 6
    vssra.vi     v2, v2, 6
    vssra.vi     v3, v3, 6
    ADD16x4_IDCT_DC v0
    ADD16x4_IDCT_DC v1
    ADD16x4_IDCT_DC v2
    ADD16x4_IDCT_DC v3

    ret
endfunc

.macro sub4x4x2_dct_dc, dst, t0, t1, t2, t3, t4, t5, t6, t7, tmp0
    vsetivli    zero, 8, e8, mf2, ta, ma
    vle8.v      \t0, (a1)
    add         a1, a1, t3
    vle8.v      \t1, (a2)
    add         a2, a2, t4
    vle8.v      \t2, (a1)
    add         a1, a1, t3
    vle8.v      \t3, (a2)
    add         a2, a2, t4
    vwsubu.vv   \tmp0, \t0, \t1
    vle8.v      \t4, (a1)
    add         a1, a1, t3
    vle8.v      \t5, (a2)
    add         a2, a2, t4
    vwsubu.vv   \t1, \t2, \t3
    vle8.v      \t6, (a1)
    add         a1, a1, t3
    vle8.v      \t7, (a2)
    add         a2, a2, t4
    vwsubu.vv   \t2, \t4, \t5
    vwsubu.vv   \t3, \t6, \t7
    vsetivli zero, 8, e16, m1, ta, ma
    vmv1r.v     \t0, \tmp0
    vadd.vv     \dst, \t0, \t1
    vadd.vv     \dst, \dst, \t2
    vadd.vv     \dst, \dst, \t3
.endm

.macro transpose2x2, s1, s2, t0
    vsetivli    zero, 2, e64, m1, tu, ma
    vmv1r.v \t0, \s1
    vslideup.vi \s1, \s2, 1
    vsetivli    zero, 1, e64, m1, tu, ma
    vslidedown.vi \s2, \t0, 1
.endm

function sub8x8_dct_dc_rvv
    li          t3, FENC_STRIDE
    li          t4, FDEC_STRIDE

    sub4x4x2_dct_dc v0, v16, v17, v18, v19, v20, v21, v22, v23, v6
    sub4x4x2_dct_dc v1, v24, v25, v26, v27, v28, v29, v30, v31, v6

    transpose2x2 v0, v1, v20
    vsetivli    zero, 8, e16, m1, tu, ma
    SUMSUB_AB   v2, v3, v0, v1
    transpose2x2 v2, v3, v21
    vsetivli    zero, 8, e16, m1, tu, ma
    SUMSUB_AB   v4, v5, v2, v3

    vsetivli    zero, 2, e64, m1, tu, ma
    vslidedown.vi v6, v4, 1
    vslidedown.vi v7, v5, 1

    vsetivli zero, 4, e16, mf2, tu, ma
    vmv.v.i     v31, 0
    vredsum.vs  v1, v7, v31
    vslideup.vi v2, v1, 1
    vredsum.vs  v2, v6, v31
    vslideup.vi v1, v2, 1
    vredsum.vs  v1, v5, v31
    vslideup.vi v2, v1, 1
    vredsum.vs  v2, v4, v31

    vse16.v     v2, (a0)

    ret
endfunc

// s0&s1, t0&t1 should be contiguous register, mention that s0&s1 will be modified
.macro addp dst, s0, s1, t0, t1
    vmv1r.v     \t0, \s1
    vsetivli    zero, 16, e16, m2, ta, ma
    vslideup.vi \s0, \t0, 8
    vslidedown.vi \t0, \s0, 1
    vadd.vv     \t0, \s0, \t0
    vsetivli    zero, 8, e16, m1, ta, ma
    vnsrl.wi    \dst, \t0, 0
.endm

.macro transpose2x4_32 buf, bstride, t0, t1, s0, s1
    vssseg2e32.v \s0, (\buf), \bstride
    vsetivli    zero, 2, e32, m1, tu, ma
    vle32.v     \t0, (\buf)
    addi        \buf, \buf, 8
    vle32.v     \t1, (\buf)
    addi        \buf, \buf, 8
    vle32.v     \s0, (\buf)
    addi        \buf, \buf, 8
    vle32.v     \s1, (\buf)
    vsetivli    zero, 4, e32, m1, tu, ma
    vslideup.vi \t0, \s0, 2
    vslideup.vi \t1, \s1, 2
.endm

function sub8x16_dct_dc_rvv
    li          t3, FENC_STRIDE
    li          t4, FDEC_STRIDE
    sub4x4x2_dct_dc v0, v16, v17, v18, v19, v20, v21, v22, v23, v6
    sub4x4x2_dct_dc v2, v24, v25, v26, v27, v28, v29, v30, v31, v6
    sub4x4x2_dct_dc v1, v16, v17, v18, v19, v20, v21, v22, v23, v6
    sub4x4x2_dct_dc v3, v24, v25, v26, v27, v28, v29, v30, v31, v6
    
    addp        v4, v0, v1, v8, v9
    addp        v5, v2, v3, v10, v11

    mv          t0, a1
    li          t1, 8

    vsetivli    zero, 4, e32, m1, tu, ma
    transpose2x4_32 t0, t1, v2, v3, v4, v5
    vsetivli    zero, 8, e16, m1, tu, ma
    SUMSUB_AB   v0, v1, v2, v3

    vsetivli    zero, 4, e32, m1, tu, ma
    mv          t0, a1
    transpose2x4_32 t0, t1, v2, v3, v0, v1
    vsetivli    zero, 8, e16, m1, tu, ma
    SUMSUB_AB   v0, v1, v2, v3
    transpose2x2 v0, v1, v30
    vsetivli    zero, 8, e16, m1, tu, ma
    SUMSUB_AB   v8, v9, v0, v1

    vsetivli    zero, 2, e64, m1, ta, ma
    vmv1r.v     v2, v8
    vmv1r.v     v3, v8
    vslideup.vi v2, v9, 1
    vsetivli    zero, 1, e64, m1, tu, ma
    vslidedown.vi v3, v9, 1

    vsetivli    zero, 8, e16, m1, ta, ma
    addp        v0, v2, v3, v4, v5

    vse16.v     v0, (a0)
    ret
endfunc

# vrgather seems to cause bad performance
function zigzag_scan_4x4_frame_rvv
    movrel      a2, scan4x4_frame
    li          t0, 32
    vsetvli    zero, t0, e8, m2, ta, ma
    vle8.v      v0, (a1)
    vle8.v      v2, (a2)
    vrgather.vv v4, v0, v2
    vse8.v      v4, (a0)
    ret
endfunc