/****************************************************************************
 * quant.S: arm quantization and level-run
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

// This is a common function for both 8 and 10 bit depth, since these two differ
// at data loading only. The distinction is based on the depth parameters that
//are passed to the macro.
.macro vabs d0, s0, t0
    vrsub.vi        \t0, \s0, 0
    vmax.vv         \d0, \s0, \t0
.endm

.macro decimate_score_1x size depth
function decimate_score\size\()_rvv

.if BIT_DEPTH == 8
    vsetivli        zero, 16, e16, m2, ta, ma
    vle16.v         v0, (a0)
    vsetivli        zero, 16, e8, m1, ta, ma
    vnclip.wi       v0, v0, 0
.else // BIT_DEPTH == 8
    vsetivli        zero, 16, e16, m2, ta, ma
    vle32.v         v0, (a0)
    vnclip.wi       v20, v0, 0
    vsetivli        zero, 16, e8, m1, ta, ma
    vnclip.wi       v0, v20, 0
.endif // BIT_DEPTH == 8
    vabs            v2, v0, v8
    movrel          a5, X264(decimate_table4)
    vmseq.vi        v1, v0, 0
    vmsleu.vi       v2, v2, 1
    vmnot.m         v1, v1
    vmnot.m         v2, v2
    vsetivli        zero, 1, e16, m1, ta, ma
    vmv.x.s         a1, v1
    vmv.x.s         a2, v2
    zext.h          a1, a1
    zext.h          a2, a2
.ifc \size, 15
    srli            a1, a1, 1
.endif
    bnez            a2, 9f
    li              a0, 0
    beqz            a1, 0f
1:
    ctzw             t0, a1
    srl             a1, a1, t0
    add             a2, a5, t0
    lbu             a3, (a2)
    srli            a1, a1, 1
    add             a0, a3, a0
    bnez            a1, 1b
    ret
9:
    li              a0, 9
0:  
    ret

endfunc
.endm

function decimate_score64_rvv
.if BIT_DEPTH == 8
    li              t0, 64
    vsetvli         zero, t0, e16, m8, ta, ma
    vle16.v         v0, (a0)
    vsetvli         zero, t0, e8, m4, ta, ma
    vnclip.wi       v0, v0, 0
.else // BIT_DEPTH == 8
    li              t0, 32
    vsetvli         zero, t0, e32, m8, ta, ma
    vle32.v         v0, (a0)
    addi            a0, a0, 128 
    vle32.v         v8, (a0)
    vsetvli         zero, t0, e16, m4, ta, ma
    vnclip.wi       v16, v0, 0
    vnclip.wi       v24, v8, 0
    vsetvli         zero, t0, e8, m2, ta, ma
    vnclip.wi       v0, v16, 0
    vnclip.wi       v8, v24, 0
    li              t1, 64
    vsetvli         zero, t1, e8, m4, ta, ma
    vslideup.vx     v0, v8, t0
.endif // BIT_DEPTH == 8
    vabs            v8, v0, v16
    movrel          a5, X264(decimate_table8)
    vmseq.vi        v20, v0, 0
    vmsleu.vi       v21, v8, 1
    vmnot.m         v20, v20
    vmnot.m         v21, v21
    vsetivli        zero, 1, e64, m2, ta, ma
    vmv.x.s         a1, v20
    vmv.x.s         a2, v21
    bnez            a2, 9f
    li              a0, 0
    beqz            a1, 0f
1:
    ctz             t0, a1
    srl             a1, a1, t0
    add             a2, a5, t0
    lbu             a3, (a2)
    srli            a1, a1, 1
    add             a0, a3, a0
    bnez            a1, 1b
    ret
9:
    li              a0, 9
0:  
    ret
endfunc

.macro COEFF_LAST_1x size, sub_factor
function coeff_last\size\()_rvv
.if \size == 15
    addi            a0, a0, -1 * \sub_factor
.endif

.if BIT_DEPTH == 8
    vsetivli        zero, 16, e16, m2, ta, ma
    vle16.v         v0, (a0)
    vsetvli         zero, zero, e8, m1, ta, ma
    vnclip.wi       v0, v0, 0
.else   // BIT_DEPTH == 8
    vsetivli        zero, 16, e32, m4, ta, ma
    vle32.v         v0, (a0)
    vsetvli         zero, zero, e16, m2, ta, ma
    vnclip.wi       v0, v0, 0
    vsetvli         zero, zero, e8, m1, ta, ma
    vnclip.wi       v0, v0, 0
.endif  // BIT_DEPTH == 8
    vand.vv         v8, v0, v0
    vmsne.vi        v0, v8, 0
    li              a3, \size - 1
    vsetivli        zero, 8, e16, m1, ta, ma
    vmv.x.s         a2, v0
.if \size == 15
    slli            a2, a2, 49
.else
    slli            a2, a2, 48
.endif
    clz             a2, a2
    sub             a0, a3, a2
    ret
endfunc
.endm


.if BIT_DEPTH == 8

.macro QUANT_TWO bias0 bias1 mf0_1 mf2_3 mask
    vsetivli        zero, 8, e16, m1, ta, ma
    vadd.vv         v18, v18, \bias0
    vadd.vv         v19, v19, \bias1
    vwmulu.vv       v20, v18, \mf0_1
    vwmulu.vv       v22, v19, \mf2_3
    vsra.vi         v16, v16, 15
    vsra.vi         v17, v17, 15
    vnsrl.wi        v18, v20, 16
    vnsrl.wi        v19, v22, 16
    vxor.vv         v18, v18, v16
    vxor.vv         v19, v19, v17
    vsub.vv         v18, v18, v16
    vsub.vv         v19, v19, v17
    vor.vv          \mask, v18, v19
    vse16.v         v18, (a0)
    addi            a0, a0, 16
    vse16.v         v19, (a0)
    addi            a0, a0, 16
.endm

.macro QUANT_END d
    li              a0, 0
    beqz            \d, 1f
    addi            a0, a0, 1
1:
    ret
.endm

// quant_2x2_dc( int16_t dct[4], int mf, int bias )
function quant_2x2_dc_rvv
    vsetivli        zero, 4, e16, mf2, ta, ma
    vle16.v         v0, (a0)
    vmv.v.x         v2, a2
    vmv.v.x         v1, a1
    vabs            v3, v0, v8
    vadd.vv         v3, v3, v2
    vwmulu.vv       v10, v3, v1
    vsra.vi         v0, v0, 15
    vnsrl.wi        v8, v10, 16
    vxor.vv         v3, v8, v0
    vsub.vv         v3, v3, v0
    vse16.v         v3, (a0)
    vsetivli        zero, 2, e64, m1, ta, ma
    vmv.x.s         a2, v3
    QUANT_END       a2
endfunc

// quant_4x4_dc( int16_t dct[16], int mf, int bias )
function quant_4x4_dc_rvv
    vsetivli        zero, 8, e16, m1, ta, ma
    vle16.v         v16, (a0)
    addi            t0, a0, 16
    vle16.v         v17, (t0)
    vabs            v18, v16, v8
    vabs            v19, v17, v8
    vmv.v.x         v0, a2
    vmv.v.x         v2, a1
    QUANT_TWO       v0, v0, v2, v2, v0
    vsetivli        zero, 8, e8, mf2, ta, ma
    vnclipu.wi      v0, v0, 0
    vsetivli        zero, 2, e64, m1, ta, ma
    vmv.x.s         a2, v0
    QUANT_END       a2
endfunc

// quant_4x4( int16_t dct[16], uint16_t mf[16], uint16_t bias[16] )
function quant_4x4_rvv
    vsetivli        zero, 8, e16, m1, ta, ma
    vle16.v         v16, (a0)
    addi            t0, a0, 16
    vle16.v         v17, (t0)
    vabs            v18, v16, v8
    vabs            v19, v17, v8
    vle16.v         v0, (a2)
    addi            t1, a2, 16
    vle16.v         v1, (t1)
    vle16.v         v2, (a1)
    addi            t2, a1, 16
    vle16.v         v3, (t2)
    QUANT_TWO       v0, v1, v2, v3, v0
    vsetivli        zero, 8, e8, mf2, ta, ma
    vnclipu.wi      v0, v0, 0
    vsetivli        zero, 2, e64, m1, ta, ma
    vmv.x.s         a2, v0
    QUANT_END       a2
endfunc

// quant_4x4x4( int16_t dct[4][16], uint16_t mf[16], uint16_t bias[16] )
function quant_4x4x4_rvv
    vsetivli        zero, 8, e16, m1, ta, ma
    vle16.v         v16, (a0)
    addi            t0, a0, 16
    vle16.v         v17, (t0)
    vabs            v18, v16, v8
    vabs            v19, v17, v8
    vle16.v         v0, (a2)
    addi            t1, a2, 16
    vle16.v         v1, (t1)
    vle16.v         v2, (a1)
    addi            t2, a1, 16
    vle16.v         v3, (t2)
    QUANT_TWO       v0, v1, v2, v3, v4
    vle16.v         v16, (a0)
    addi            t0, a0, 16
    vle16.v         v17, (t0)
    vabs            v18, v16, v8
    vabs            v19, v17, v8
    QUANT_TWO       v0, v1, v2, v3, v5
    vle16.v         v16, (a0)
    addi            t0, a0, 16
    vle16.v         v17, (t0)
    vabs            v18, v16, v8
    vabs            v19, v17, v8
    QUANT_TWO       v0, v1, v2, v3, v6
    vle16.v         v16, (a0)
    addi            t0, a0, 16
    vle16.v         v17, (t0)
    vabs            v18, v16, v8
    vabs            v19, v17, v8
    QUANT_TWO       v0, v1, v2, v3, v7
    vsetivli        zero, 8, e8, mf2, ta, ma
    vnclipu.wi      v4, v4, 0
    vnclipu.wi      v5, v5, 0
    vnclipu.wi      v6, v6, 0
    vnclipu.wi      v7, v7, 0
    vsetivli        zero, 2, e64, m1, ta, ma
    vmv.x.s         a3, v7
    vmv.x.s         a4, v6
    vmv.x.s         a5, v5
    vmv.x.s         a6, v4
    
    li              a0, 0
    beqz            a3, 1f
    addi            a0, a0, 1
1:
    slli            a0, a0, 1
    beqz            a4, 2f
    addi            a0, a0, 1
2:
    slli            a0, a0, 1
    beqz            a5, 3f
    addi            a0, a0, 1
3:
    slli            a0, a0, 1
    beqz            a6, 4f
    addi            a0, a0, 1
4:
    ret
endfunc

// quant_8x8( int16_t dct[64], uint16_t mf[64], uint16_t bias[64] )
function quant_8x8_rvv
    vsetivli        zero, 8, e16, m1, ta, ma
    vle16.v         v16, (a0)
    addi            t0, a0, 16
    vle16.v         v17, (t0)
    vabs            v18, v16, v8
    vabs            v19, v17, v8
    vle16.v         v0, (a2)
    addi            a2, a2, 16
    vle16.v         v1, (a2)
    addi            a2, a2, 16
    vle16.v         v2, (a1)
    addi            a1, a1, 16
    vle16.v         v3, (a1)
    addi            a1, a1, 16
    QUANT_TWO       v0, v1, v2, v3, v4
.rept 3
    vle16.v         v16, (a0)
    addi            t0, a0, 16
    vle16.v         v17, (t0)
    vabs            v18, v16, v8
    vabs            v19, v17, v8
    vle16.v         v0, (a2)
    addi            a2, a2, 16
    vle16.v         v1, (a2)
    addi            a2, a2, 16
    vle16.v         v2, (a1)
    addi            a1, a1, 16
    vle16.v         v3, (a1)
    addi            a1, a1, 16
    QUANT_TWO       v0, v1, v2, v3, v5
    vor.vv          v4, v4, v5
.endr
    vsetivli        zero, 8, e8, mf2, ta, ma
    vnclipu.wi      v4, v4, 0
    vsetivli        zero, 2, e64, m1, ta, ma
    vmv.x.s         a2, v4
    QUANT_END       a2
endfunc

.macro DEQUANT_START mf_size offset dc=no
    li              a3, 0x2b
    mul             a3, a3, a2
    srli            a3, a3, 8
    slli            t0, a3, 1
    add             a5, a3, t0
    slli            t1, a5, 1
    sub             a2, a2, t1
    slli            a2, a2, \mf_size
.ifc \dc,no
    add             a1, a1, a2
.else
    add             t2, a1, a2
    ld              a1, (t2)
.endif
    addi            a3, a3, -1*(\offset)
.endm

// dequant_4x4( int16_t dct[16], int dequant_mf[6][16], int i_qp )
.macro DEQUANT size bits
function dequant_\size\()_rvv
    DEQUANT_START \bits+2, \bits
.ifc \size, 8x8
    li              a2, 4
.endif
    bltz            a3, dequant_\size\()_rshift
dequant_\size\()_lshift_loop:
.ifc \size, 8x8
    addi            a2, a2, -1
.endif
    vsetivli        zero, 16, e16, m2, ta, ma
    vle16.v         v16, (a1)
    addi            a1, a1, 32
    vle16.v         v18, (a1)
    addi            a1, a1, 32
    vsetivli        zero, 8, e16, m1, ta, ma
    vnclip.wi       v2, v16, 0
    vnclip.wi       v3, v18, 0
    vle16.v         v0, (a0)
    addi            t0, a0, 16
    vle16.v         v1, (t0)
    vmul.vv         v0, v0, v2
    vmul.vv         v1, v1, v3
    vsll.vx         v0, v0, a3
    vsll.vx         v1, v1, a3
    vse16.v         v0, (a0)
    addi            a0, a0, 16
    vse16.v         v1, (a0)
    addi            a0, a0, 16
.ifc \size, 8x8
    bgtz            a2, dequant_\size\()_lshift_loop
.endif
    ret

dequant_\size\()_rshift:
    neg             a3, a3
.ifc \size, 8x8
dequant_\size\()_rshift_loop:
    addi            a2, a2, -1
.endif
    vsetivli        zero, 16, e16, m2, ta, ma
    vle16.v         v16, (a1)
    addi            a1, a1, 32
    vle16.v         v18, (a1)
    addi            a1, a1, 32
    vsetivli        zero, 8, e16, m1, ta, ma
    vnclip.wi       v2, v16, 0
    vnclip.wi       v3, v18, 0
    vle16.v         v0, (a0)
    addi            t0, a0, 16
    vle16.v         v1, (t0)
    vwmul.vv        v16, v0, v2
    vwmul.vv        v18, v1, v3
    vsetivli        zero, 8, e32, m2, ta, ma
    vssra.vx        v16, v16, a3
    vssra.vx        v18, v18, a3
    vsetivli        zero, 8, e16, m1, ta, ma
    vnclip.wi       v0, v16, 0
    vnclip.wi       v1, v18, 0
    vse16.v         v0, (a0)
    addi            a0, a0, 16
    vse16.v         v1, (a0)
    addi            a0, a0, 16
.ifc \size, 8x8
    bgtz            a2, dequant_\size\()_rshift_loop
.endif
    ret
endfunc
.endm

DEQUANT 4x4, 4
DEQUANT 8x8, 6

// dequant_4x4_dc( int16_t dct[16], int dequant_mf[6][16], int i_qp )
function dequant_4x4_dc_rvv
    DEQUANT_START 6, 6, yes
    blt             a3, zero, dequant_4x4_dc_rshift
    vsetivli        zero, 8, e16, m1, ta, ma
    sll             a1, a1, a3
    vmv.v.x         v2, a1
    vle16.v         v0, (a0)
    addi            t0, a0, 16
    vle16.v         v1, (t0)

    vmul.vv         v0, v0, v2
    vmul.vv         v1, v1, v2
    vse16.v         v0, (a0)
    vse16.v         v1, (t0)
    ret

dequant_4x4_dc_rshift:
    vsetivli        zero, 8, e16, m1, ta, ma
    vmv.v.x         v4, a1
    vle16.v         v0, (a0)
    addi            t0, a0, 16
    vle16.v          v1, (t0)

    vwmul.vv        v16, v0, v4
    vwmul.vv        v18, v1, v4

    vsetivli        zero, 8, e32, m2, ta, ma
    neg             a3, a3
    vssra.vx        v16, v16, a3
    vssra.vx        v18, v18, a3
    vsetivli        zero, 8, e16, m1, ta, ma
    vnclip.wi       v0, v16, 0
    vnclip.wi       v1, v18, 0

    vse16.v         v0, (a0)
    addi            a0, a0, 16
    vse16.v         v1, (a0)

    ret
endfunc


COEFF_LAST_1x 15, #2
COEFF_LAST_1x 16, #2

.endif


decimate_score_1x 15
decimate_score_1x 16