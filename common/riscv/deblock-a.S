/*****************************************************************************
 * deblock.S: riscv deblocking
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

const transpose_table
    .byte 0, 4,  8, 12
    .byte 1, 5,  9, 13
    .byte 2, 6, 10, 14
    .byte 3, 7, 11, 15
endconst

.macro h264_loop_filter_start
    vsetivli        zero, 1, e32, m1, ta, ma
    lw              a6, (a4)
    vmv.s.x         v24, a6
    slli            t0, a6, 16
    and             t1, a6, t0
    beqz            a2, 1f
    beqz            a3, 1f
    slli            t1, t1, 8
    and             t1, t1, t1
    bgez            t1, 2f
1:
    ret
2:
.endm

.macro uabd d0, s0, s1, t0
    vmaxu.vv        \d0, \s0, \s1
    vminu.vv        \t0, \s0, \s1
    vsub.vv         \d0, \d0, \t0    
.endm

.macro sabd d0, s0, s1, t0
    vmax.vv         \d0, \s0, \s1
    vmin.vv         \t0, \s0, \s1
    vsub.vv         \d0, \d0, \t0   
.endm

// nearly the same performance compare with current impl
.macro rshrn_zb d0, s0, a0, t0
    addi            \t0, \a0, -1
    bset            \t0, zero, \t0
    vsetivli        zero, 8, e16, m1, ta, ma
    vadd.vx         \d0, \s0, \t0
    vsetivli        zero, 8, e8, mf2, ta, ma
    vnsrl.wx        \d0, \d0, \a0         
.endm

.macro h264_loop_filter_luma
    csrwi  vxrm, 0

    vsetivli        zero, 8, e16, m1, ta, ma
    vzext.vf2       v25, v24
    
    vsetivli        zero, 16, e8, m1, ta, ma
    vmv.v.x         v22, a2
    uabd            v21, v16, v1, v0
    uabd            v28, v18, v16, v0
    uabd            v30, v2, v1, v0
    vsetivli        zero, 4, e32, m1, ta, ma
    vzext.vf2       v24, v25
    
    // sli = shift + or
    vsetivli        zero, 8, e16, m1, ta, ma
    vsll.vi         v29, v24, 8
    vor.vv          v24, v29, v24
    vsetivli        zero, 4, e32, m1, ta, ma
    vsll.vi         v29, v24, 16
    vor.vv          v24, v29, v24

    vsetivli        zero, 16, e8, m1, ta, ma
    vmsgtu.vv       v21, v22, v21
    vmv.v.x         v22, a3
    vmslt.vx        v23, v24, zero
    vmsgtu.vv       v28, v22, v28
    vmsgtu.vv       v30, v22, v30
    vnot.v          v29, v23
    vand.vv         v21, v21, v29
    uabd            v17, v20, v16, v0
    vand.vv         v21, v21, v28
    uabd            v19, v4, v1, v0
    vmsgtu.vv       v17, v22, v17
    vand.vv         v21, v21, v30
    vmsgtu.vv       v19, v22, v19
    
    vmv.v.i         v3, 0
    vnot.v          v5, v3
    vmv1r.v         v0, v17
    vmerge.vvm      v25, v3, v5, v0
    vmv1r.v         v0, v19
    vmerge.vvm      v27, v3, v5, v0
    vmv1r.v         v0, v21
    vmerge.vvm      v21, v3, v5, v0
    
    vand.vv         v25, v25, v21
    vand.vv         v27, v27, v21
    vand.vv         v24, v24, v21

    vwaddu.vv       v28, v16, v1
    vsetivli        zero, 16, e16, m2, ta, ma
    vssrl.vi        v28, v28, 1
    vsetivli        zero, 16, e8, m1, ta, ma
    vnsrl.wi        v28, v28, 0

    vsub.vv         v21, v24, v25
    vsaddu.vv       v23, v18, v24
    vwaddu.vv       v30, v20, v28
    vnsrl.wi        v20, v30, 1
    vsub.vv         v21, v21, v27
    vwaddu.vv       v30, v4, v28
    vnsrl.wi        v28, v30, 1
    
    vminu.vv        v23, v23, v20
    vssubu.vv       v22, v18, v24
    vsaddu.vv       v4, v2, v24
    vmaxu.vv        v23, v23, v22
    vssubu.vv       v22, v2, v24
    vminu.vv        v28, v4, v28
    vmaxu.vv        v28, v28, v22

    vsetivli        zero, 16, e8, m1, ta, ma
    vslidedown.vi   v3, v1, 8
    vsetivli        zero, 8, e16, m1, ta, ma
    vzext.vf2       v20, v3
    vzext.vf2       v4, v1
    vsetivli        zero, 16, e8, m1, ta, ma
    vslidedown.vi   v3, v16, 8
    vsetivli        zero, 8, e8, m1, tu, ma
    vwsubu.wv       v4, v4, v16
    vwsubu.wv       v20, v20, v3

    vsetivli        zero, 8, e16, m1, ta, ma
    vsll.vi         v4, v4, 2
    vsll.vi         v20, v20, 2
    vsetivli        zero, 8, e8, m1, ta, ma
    vwaddu.wv       v30, v4, v18
    vwsubu.wv       v4, v30, v2
    vsetivli        zero, 16, e8, m1, ta, ma
    vslidedown.vi   v8, v18, 8
    vslidedown.vi   v9, v2, 8
    vsetivli        zero, 8, e8, mf2, ta, ma
    vwaddu.wv       v7, v20, v8
    vwsubu.wv       v10, v7, v9

    // rshrn = vssrl + vnsrl
    vsetivli        zero, 8, e16, m1, ta, ma
    vssrl.vi        v4, v4, 3
    vssrl.vi        v0, v10, 3
    vsetivli        zero, 8, e8, mf2, ta, ma
    vncvt.x.x.w     v4, v4
    vncvt.x.x.w     v0, v0
    vsetivli        zero, 16, e8, m1, ta, ma
    vslideup.vi     v4, v0, 8

    vsetivli        zero, 16, e8, m1, ta, ma
    vmv1r.v         v0, v17
    vmerge.vvm      v17, v18, v23, v0
    vmv1r.v         v0, v19
    vmerge.vvm      v19, v2, v28, v0
    vmv.v.x         v3, zero
    vsub.vv         v23, v3, v21
    vsetivli        zero, 8, e16, m1, ta, ma
    vzext.vf2       v28, v16
    vzext.vf2       v22, v1
    vsetivli        zero, 16, e8, m1, ta, ma
    vmin.vv         v4, v4, v21
    vmax.vv         v4, v4, v23
    vslidedown.vi   v3, v16, 8
    vslidedown.vi   v5, v1, 8
    vsetivli        zero, 8, e16, m1, ta, ma
    vzext.vf2       v21, v3
    vzext.vf2       v24, v5

    vsetivli        zero, 8, e8, mf2, ta, ma
    vwadd.wv        v28, v28, v4
    vwsub.wv        v22, v22, v4
    vsetivli        zero, 16, e8, m1, ta, ma
    vslidedown.vi   v3, v4, 8
    vsetivli        zero, 8, e8, mf2, ta, ma
    vwadd.wv        v21, v21, v3
    vwsub.wv        v24, v24, v3

    vsetivli        zero, 8, e16, m1, ta, ma
    vmax.vx         v21, v21, x0
    vmax.vx         v22, v22, x0
    vmax.vx         v24, v24, x0
    vmax.vx         v28, v28, x0

    vsetvli         zero, zero, e8, mf2, ta, ma
    vnclipu.wi      v21, v21, 0
    vnclipu.wi      v1, v22, 0
    vnclipu.wi      v24, v24, 0    
    vnclipu.wi      v16, v28, 0
    vsetivli        zero, 16, e8, m1, ta, ma
    vslideup.vi     v16, v21, 8
    vslideup.vi     v1, v24, 8
.endm

function deblock_v_luma_rvv
    h264_loop_filter_start

    vsetivli    zero, 16, e8, m1, ta, ma
    vle8.v      v1, (a0)
    add         a0, a0, a1
    vle8.v      v2, (a0)
    add         a0, a0, a1
    vle8.v      v4, (a0)
    add         a0, a0, a1

    slli        t0, a1, 2
    sub         a0, a0, t0
    slli        t2, a1, 1
    sub         a0, a0, t2

    vle8.v      v20, (a0)
    add         a0, a0, a1
    vle8.v      v18, (a0)
    add         a0, a0, a1
    vle8.v      v16, (a0)
    add         a0, a0, a1

    h264_loop_filter_luma

    sub         a0, a0, t2

    vse8.v      v17, (a0)
    add         a0, a0, a1
    vse8.v      v16, (a0)
    add         a0, a0, a1
    vse8.v      v1, (a0)
    add         a0, a0, a1
    vse8.v      v19, (a0)

    ret
endfunc


// this func can't work when VLEN > 128, due to LMUL=4 vrgather
// and performance is bad, so now disabaled
function deblock_h_luma_rvv
    h264_loop_filter_start
    mv          t0, a0
    mv          t2, a0
    mv          t3, a0

    vsetivli    zero, 8, e8, m1, ta, ma
    addi        a0, a0, -4
    vle8.v      v6, (a0)
    add         a0, a0, a1
    vle8.v      v20, (a0)
    add         a0, a0, a1
    vle8.v      v18, (a0)
    add         a0, a0, a1
    vle8.v      v16, (a0)
    add         a0, a0, a1
    vle8.v      v1, (a0)
    add         a0, a0, a1
    vle8.v      v2, (a0)
    add         a0, a0, a1
    vle8.v      v4, (a0)
    add         a0, a0, a1
    vle8.v      v26, (a0)
    add         a0, a0, a1

    vle8.v      v8, (a0)
    add         a0, a0, a1
    vle8.v      v9, (a0)
    add         a0, a0, a1
    vle8.v      v10, (a0)
    add         a0, a0, a1
    vle8.v      v11, (a0)
    add         a0, a0, a1
    vle8.v      v12, (a0)
    add         a0, a0, a1
    vle8.v      v13, (a0)
    add         a0, a0, a1
    vle8.v      v14, (a0)
    add         a0, a0, a1
    vle8.v      v15, (a0)
    add         a0, a0, a1

    vsetivli    zero, 2, e64, m1, ta, ma
    vslideup.vi v6, v8, 1
    vslideup.vi v20, v9, 1
    vslideup.vi v18, v10, 1
    vslideup.vi v16, v11, 1
    vslideup.vi v1, v12, 1
    vslideup.vi v2, v13, 1
    vslideup.vi v4, v14, 1
    vslideup.vi v26, v15, 1

    # prepare for transpose
    vsetivli    zero, 16, e8, m1, ta, ma
    vle8.v  v0, (t3)
    addi    t3, t3, 16
    vle8.v v3, (t3)
    addi    t3, t3, 16
    vle8.v v5, (t3)
    addi    t3, t3, 16
    vle8.v v7, (t3)
    addi    t3, t3, 16
    vle8.v v17, (t3)
    addi    t3, t3, 16
    vle8.v v19, (t3)
    addi    t3, t3, 16
    vle8.v v21, (t3)
    addi    t3, t3, 16
    vle8.v v23, (t3)

    
    vsetivli zero, 16, e8, m1, tu, ma
    li t1, 8
    TRANSPOSE8x16  t0, t1, t4, v6, v20, v18, v16, v1, v2, v4, v26, v8, v9, v10, v11, v12, v13, v14, v15

    # store back
    vsetivli zero, 16, e8, m1, ta, ma
    vse8.v v0, (t2)
    addi    t2, t2, 16
    vse8.v v3, (t2)
    addi    t2, t2, 16
    vse8.v v5, (t2)
    addi    t2, t2, 16
    vse8.v v7, (t2)
    addi    t2, t2, 16
    vse8.v v17, (t2)
    addi    t2, t2, 16
    vse8.v v19, (t2)
    addi    t2, t2, 16
    vse8.v v21, (t2)
    addi    t2, t2, 16
    vse8.v v23, (t2)

    h264_loop_filter_luma

    vmv1r.v v4, v17
    vmv1r.v v5, v16
    vmv1r.v v6, v1
    vmv1r.v v7, v19

    li      t0, 16
    TRANSPOSE4x16 t0, v4, v5, v6, v7, v16, v17, v18, v19, v20, v21, v22, v23

    slli        t0, a1, 4
    sub         a0, a0, t0
    add         a0, a0, 2

    vsetivli zero, 4, e8, m1, ta, ma
    vse8.v     v4, (a0)
    add         a0, a0, a1
    vse8.v     v5, (a0)
    add         a0, a0, a1
    vse8.v     v6, (a0)
    add         a0, a0, a1
    vse8.v     v7, (a0)
    add         a0, a0, a1
    vsetivli zero, 4, e32, m1, ta, ma
    vslidedown.vi v4, v4, 1
    vslidedown.vi v5, v5, 1
    vslidedown.vi v6, v6, 1
    vslidedown.vi v7, v7, 1

    vsetivli zero, 4, e8, m1, ta, ma
    vse8.v     v4, (a0)
    add         a0, a0, a1
    vse8.v     v5, (a0)
    add         a0, a0, a1
    vse8.v     v6, (a0)
    add         a0, a0, a1
    vse8.v     v7, (a0)
    add         a0, a0, a1
    vsetivli zero, 4, e32, m1, ta, ma
    vslidedown.vi v4, v4, 1
    vslidedown.vi v5, v5, 1
    vslidedown.vi v6, v6, 1
    vslidedown.vi v7, v7, 1

    vsetivli zero, 4, e8, m1, ta, ma
    vse8.v     v4, (a0)
    add         a0, a0, a1
    vse8.v     v5, (a0)
    add         a0, a0, a1
    vse8.v     v6, (a0)
    add         a0, a0, a1
    vse8.v     v7, (a0)
    add         a0, a0, a1
    vsetivli zero, 4, e32, m1, ta, ma
    vslidedown.vi v4, v4, 1
    vslidedown.vi v5, v5, 1
    vslidedown.vi v6, v6, 1
    vslidedown.vi v7, v7, 1

    vsetivli zero, 4, e8, m1, ta, ma
    vse8.v     v4, (a0)
    add         a0, a0, a1
    vse8.v     v5, (a0)
    add         a0, a0, a1
    vse8.v     v6, (a0)
    add         a0, a0, a1
    vse8.v     v7, (a0)

    ret
endfunc

.macro h264_loop_filter_start_intra
    or          a4, a2, a3
    bnez        a4, 1f
    ret
1:
    vsetivli    zero, 16, e8, m1, ta, ma
    vmv.v.x     v30, a2                // alpha
    vmv.v.x     v31, a3                // beta
.endm

.macro h264_loop_filter_luma_intra
    csrwi  vxrm, 0
    uabd        v16, v7, v8, v0         // abs(p0 - q0)
    uabd        v17, v6, v7, v0         // abs(p1 - p0)
    uabd        v18, v1, v8, v0         // abs(q1 - q0)
    vmsgtu.vv   v19, v30, v16       // < alpha
    vmsgtu.vv   v17, v31, v17       // < beta
    vmsgtu.vv   v18, v31, v18       // < beta

    vmv.v.i     v29, 2
    vsrl.vi     v30, v30, 2         // alpha >> 2
    vadd.vv     v30, v30, v29       // (alpha >> 2) + 2
    vmsgtu.vv   v16, v30, v16       // < (alpha >> 2) + 2

    vand.vv     v19, v19, v17
    vand.vv     v19, v19, v18
    
    vsetivli    zero, 1, e16, m1, ta, ma
    vmv.x.s     t0, v19
    beqz        t0, 9f

    vsetivli    zero, 8, e16, m1, ta, ma
    vzext.vf2   v20, v6
    vsll.vi     v20, v20, 1
    vzext.vf2   v22, v1
    vsll.vi     v22, v22, 1
    
    vsetivli    zero, 16, e8, m1, ta, ma
    vslidedown.vi   v9, v6, 8
    vslidedown.vi   v10, v1, 8
    vslidedown.vi   v11, v7, 8
    vslidedown.vi   v12, v8, 8
    
    vsetivli    zero, 8, e16, m1, ta, ma
    vzext.vf2   v21, v9
    vsll.vi     v21, v21, 1
    vzext.vf2   v23, v10
    vsll.vi     v23, v23, 1

    vsetivli    zero, 8, e8, mf2, ta, ma
    vwaddu.wv   v20, v20, v7
    vwaddu.wv   v22, v22, v8
    vwaddu.wv   v21, v21, v11
    vwaddu.wv   v23, v23, v12
    vwaddu.wv   v20, v20, v1
    vwaddu.wv   v22, v22, v6
    vwaddu.wv   v21, v21, v10
    vwaddu.wv   v23, v23, v9

    # rshrn = vssrl + vnsrl
    vsetivli    zero, 8, e16, m1, ta, ma
    vssrl.vi    v14, v20, 2
    vssrl.vi    v13, v21, 2
    vssrl.vi    v29, v22, 2
    vssrl.vi    v28, v23, 2
    vsetivli    zero, 8, e8, mf2, ta, ma
    vnsrl.wi    v13, v13, 0
    vnsrl.wi    v24, v14, 0
    vnsrl.wi    v28, v28, 0
    vnsrl.wi    v25, v29, 0

    vsetivli    zero, 16, e8, m1, ta, ma
    vslideup.vi v24, v13, 8
    vslideup.vi v25, v28, 8


    vsetivli    zero, 16, e8, m1, ta, ma
    uabd        v17, v5, v7, v0
    uabd        v18, v2, v8, v0
    vmsgtu.vv   v17, v31, v17
    vmsgtu.vv   v18, v31, v18

    vand.vv     v17, v16, v17
    vand.vv     v18, v16, v18

    vnot.v      v30, v17
    vnot.v      v31, v18

    vand.vv     v30, v30, v19
    vand.vv     v31, v31, v19

    vand.vv     v17, v19, v17
    vand.vv     v18, v19, v18   
    
    //calc            p, v7, v6, v5, v4, v17, v7, v6, v5, v4
    vsetivli    zero, 16, e8, m1, ta, ma
    vslidedown.vi v13, v5, 8
    vslidedown.vi v14, v4, 8

    vsetivli    zero, 8, e8, mf2, ta, ma
    vwaddu.vv   v26, v5, v7
    vwaddu.vv   v27, v13, v11
    vwaddu.wv   v26, v26, v8
    vwaddu.wv   v27, v27, v12

    vsetivli    zero, 8, e16, m1, ta, ma
    vadd.vv     v20, v20, v26
    vadd.vv     v21, v21, v27

    vsetivli    zero, 8, e8, mf2, ta, ma
    vwaddu.wv   v20, v20, v8
    vwaddu.wv   v21, v21, v12

    # rshrn = vssrl + vnsrl
    vsetivli    zero, 8, e16, m1, ta, ma
    vssrl.vi    v20, v20, 3
    vssrl.vi    v21, v21, 3
    vsetivli    zero, 8, e8, mf2, ta, ma
    vncvt.x.x.w v20, v20
    vncvt.x.x.w v21, v21
    vsetivli    zero, 16, e8, m1, ta, ma
    vslideup.vi v20, v21, 8

    vsetivli    zero, 8, e8, mf2, ta, ma
    vwaddu.wv   v26, v26, v6
    vwaddu.wv   v27, v27, v9

    vsetivli    zero, 8, e16, m1, ta, ma
    vssrl.vi    v21, v26, 2
    vssrl.vi    v0, v27, 2
    vsetivli    zero, 8, e8, mf2, ta, ma
    vncvt.x.x.w v21, v21
    vncvt.x.x.w v0, v0
    vsetivli    zero, 16, e8, m1, ta, ma
    vslideup.vi v21, v0, 8

    vsetivli    zero, 8, e8, mf2, ta, ma
    vwaddu.vv   v28, v4, v5
    vwaddu.vv   v29, v13, v14

    vsetivli    zero, 8, e16, m1, ta, ma
    vsll.vi     v28, v28, 1
    vsll.vi     v29, v29, 1

    vadd.vv     v28, v28, v26
    vadd.vv     v29, v29, v27

    vsetivli    zero, 8, e16, m1, ta, ma
    vssrl.vi    v19, v28, 3
    vssrl.vi    v29, v29, 3
    vsetivli    zero, 8, e8, mf2, ta, ma
    vncvt.x.x.w v19, v19
    vncvt.x.x.w v29, v29
    vsetivli    zero, 16, e8, m1, ta, ma
    vslideup.vi v19, v29, 8

    //calc            q, v8, v1, v2, v3, v18, v8, v1, v2, v3
    vsetivli    zero, 16, e8, m1, ta, ma
    vslidedown.vi v13, v2, 8
    vslidedown.vi v14, v3, 8

    vsetivli    zero, 8, e8, mf2, ta, ma
    vwaddu.vv   v26, v2, v8
    vwaddu.vv   v27, v13, v12
    vwaddu.wv   v26, v26, v7
    vwaddu.wv   v27, v27, v11

    vsetivli    zero, 8, e16, m1, ta, ma
    vadd.vv     v22, v22, v26
    vadd.vv     v23, v23, v27

    vsetivli    zero, 8, e8, mf2, ta, ma
    vwaddu.wv   v22, v22, v7
    vwaddu.wv   v23, v23, v11

    # rshrn = vssrl + vnsrl
    vsetivli    zero, 8, e16, m1, ta, ma
    vssrl.vi    v22, v22, 3
    vssrl.vi    v23, v23, 3
    vsetivli    zero, 8, e8, mf2, ta, ma
    vncvt.x.x.w v22, v22
    vncvt.x.x.w v23, v23
    vsetivli    zero, 16, e8, m1, ta, ma
    vslideup.vi v22, v23, 8

    vsetivli    zero, 8, e8, mf2, ta, ma
    vwaddu.wv   v26, v26, v1
    vwaddu.wv   v27, v27, v10

    vsetivli    zero, 8, e16, m1, ta, ma
    vssrl.vi    v23, v26, 2
    vssrl.vi    v0, v27, 2
    vsetivli    zero, 8, e8, mf2, ta, ma
    vncvt.x.x.w v23, v23
    vncvt.x.x.w v0, v0
    vsetivli    zero, 16, e8, m1, ta, ma
    vslideup.vi v23, v0, 8

    vsetivli    zero, 8, e8, mf2, ta, ma
    vwaddu.vv   v28, v2, v3
    vwaddu.vv   v29, v13, v14

    vsetivli    zero, 8, e16, m1, ta, ma
    vsll.vi     v28, v28, 1
    vsll.vi     v29, v29, 1

    vadd.vv     v28, v28, v26
    vadd.vv     v29, v29, v27

    vsetivli    zero, 8, e16, m1, ta, ma
    vssrl.vi    v26, v28, 3
    vssrl.vi    v29, v29, 3
    vsetivli    zero, 8, e8, mf2, ta, ma
    vncvt.x.x.w v26, v26
    vncvt.x.x.w v29, v29
    vsetivli    zero, 16, e8, m1, ta, ma
    vslideup.vi v26, v29, 8

    vmv1r.v     v0, v30
    vmerge.vvm  v7, v7, v24, v0
    vmv1r.v     v0, v31
    vmerge.vvm  v8, v8, v25, v0
    vmv1r.v     v0, v17
    vmerge.vvm  v7, v7, v20, v0
    vmerge.vvm  v6, v6, v21, v0
    vmerge.vvm  v5, v5, v19, v0
    vmv1r.v     v0, v18
    vmerge.vvm  v8, v8, v22, v0
    vmerge.vvm  v1, v1, v23, v0
    vmerge.vvm  v2, v2, v26, v0
.endm

function deblock_v_luma_intra_rvv
    h264_loop_filter_start_intra

    vle8.v      v8, (a0)
    add         a0, a0, a1
    vle8.v      v1, (a0)
    add         a0, a0, a1
    vle8.v      v2, (a0)
    add         a0, a0, a1
    vle8.v      v3, (a0)
    add         a0, a0, a1

    slli        t0, a1, 3
    sub         a0, a0, t0

    vle8.v      v4, (a0)
    add         a0, a0, a1
    vle8.v     v5, (a0)
    add         a0, a0, a1
    vle8.v      v6, (a0)
    add         a0, a0, a1
    vle8.v      v7, (a0)

    h264_loop_filter_luma_intra
    
    slli        t0, a1, 1
    sub         a0, a0, t0

    vse8.v      v5, (a0)
    add         a0, a0, a1
    vse8.v      v6, (a0)
    add         a0, a0, a1
    vse8.v      v7, (a0)
    add         a0, a0, a1
    vse8.v      v8, (a0)
    add         a0, a0, a1
    vse8.v      v1, (a0)
    add         a0, a0, a1
    vse8.v      v2, (a0)

9:
    ret
endfunc

.macro h264_loop_filter_chroma
    csrwi           vxrm, 0
    
    vmv.v.x         v22, a2              // alpha
    vslidedown.vi   v9, v8, 8
    vslidedown.vi   v10, v16, 8
    vslidedown.vi   v11, v18, 8
    vslidedown.vi   v12, v2, 8

    uabd        v26, v16, v8, v0    // abs(p0 - q0)
    uabd        v28, v18, v16, v0  // abs(p1 - p0)
    uabd        v30, v2, v8, v0   // abs(q1 - q0)

    vmsgtu.vv   v26, v22, v26
    
    vsetivli    zero, 8, e16, m1, ta, ma
    vzext.vf2   v14, v24
    vzext.vf2   v4, v8
    vzext.vf2   v5, v9
    
    vsetivli    zero, 8, e8, mf2, ta, ma
    vwsubu.wv   v4, v4, v16
    vwsubu.wv   v5, v5, v10   

    vsetivli    zero, 8, e16, m1, ta, ma
    vsll.vi     v0, v14, 8
    vor.vv      v24, v14, v0
    vsll.vi     v4, v4, 2
    vsll.vi     v5, v5, 2

    vsetivli    zero, 4, e32, m1, ta, ma
    vzext.vf2   v14, v24
    vsll.vi     v0, v14, 16
    vor.vv      v24, v14, v0

    vsetivli    zero, 8, e8, mf2, ta, ma
    vwaddu.wv   v4, v4, v18
    vwaddu.wv   v5, v5, v11   
    vwsubu.wv   v4, v4, v2
    vwsubu.wv   v5, v5, v12

    vsetivli    zero, 16, e8, m1, ta, ma
    vmv.v.x     v22, a3              // beta

    // rshrn = vssrl + vnsrl
    vsetivli    zero, 8, e16, m1, ta, ma
    vssrl.vi    v4, v4, 3
    vssrl.vi    v0, v5, 3
    vsetivli    zero, 8, e8, mf2, ta, ma
    vncvt.x.x.w v4, v4
    vncvt.x.x.w v0, v0
    vsetivli    zero, 16, e8, m1, ta, ma
    vslideup.vi v4, v0, 8

    vmsgtu.vv   v28, v22, v28  // < beta
    vmsgtu.vv   v30, v22, v30  // < beta
    vmin.vv     v4, v4, v24
    vmv.v.x     v14, zero
    vsub.vv     v25, v14, v24
    vand.vv     v26, v26, v28
    vmax.vv     v4, v4, v25
    vand.vv     v0, v26, v30
    
    vmerge.vvm  v4, v14, v4, v0

    vsetivli    zero, 8, e16, m1, ta, ma
    vzext.vf2   v22, v8
    vzext.vf2   v23, v9
    vzext.vf2   v28, v16
    vzext.vf2   v29, v10

    vsetivli    zero, 16, e8, m1, ta, ma
    vslidedown.vi   v13, v4, 8

    vsetivli    zero, 8, e8, mf2, ta, ma
    vwadd.wv    v28, v28, v4
    vwadd.wv    v29, v29, v13
    vwsub.wv    v22, v22, v4
    vwsub.wv    v23, v23, v13

    vsetivli    zero, 8, e16, m1, ta, ma
    vmax.vx     v28, v28, x0
    vmax.vx     v29, v29, x0
    vmax.vx     v22, v22, x0
    vmax.vx     v23, v23, x0

    vsetvli     zero, zero, e8, mf2, ta, ma
    vnclipu.wi  v16, v28, 0
    vnclipu.wi  v9, v29, 0
    vnclipu.wi  v8, v22, 0  
    vnclipu.wi  v10, v23, 0
    vsetivli    zero, 16, e8, m1, ta, ma
    vslideup.vi v16, v9, 8
    vslideup.vi v8, v10, 8
.endm

function deblock_v_chroma_rvv
    h264_loop_filter_start

    slli        t0, a1, 1
    sub         a0, a0, t0
    vsetivli    zero, 16, e8, m1, ta, ma
    vle8.v      v18, (a0)
    add         a0, a0, a1
    vle8.v      v16, (a0)
    add         a0, a0, a1
    vle8.v      v8, (a0)
    add         a0, a0, a1
    vle8.v      v2, (a0)

    h264_loop_filter_chroma

    sub         a0, a0, t0
    vse8.v      v16, (a0)
    add         a0, a0, a1
    vse8.v      v8, (a0)

    ret
endfunc

.macro h264_loop_filter_chroma_intra width=16
    uabd        v26, v16, v17, v0  // abs(p0 - q0)
    uabd        v27, v18, v16, v0  // abs(p1 - p0)
    uabd        v28, v19, v17, v0  // abs(q1 - q0)
    vmsgtu.vv   v26, v30, v26  // < alpha
    vmsgtu.vv   v27, v31, v27  // < beta
    vmsgtu.vv   v28, v31, v28  // < beta
    vand.vv     v26, v26, v27
    vand.vv     v26, v26, v28

    vslidedown.vi   v8, v18, 8
    vslidedown.vi   v9, v19, 8
    vslidedown.vi   v10, v16, 8
    vslidedown.vi   v11, v17, 8

    vsetivli    zero, 8, e16, m1, ta, ma
    vzext.vf2   v4, v18
    vsll.vi     v4, v4, 1
    vzext.vf2   v6, v19
    vsll.vi     v6, v6, 1
.ifc \width, 16
    vzext.vf2   v5, v8
    vsll.vi     v5, v5, 1
    vzext.vf2   v7, v9
    vsll.vi     v7, v7, 1

    vsetivli    zero, 8, e8, mf2, ta, ma
    vwaddu.vv   v21, v10, v9
    vwaddu.vv   v23, v11, v8
.endif
    vsetvli     zero, zero, e8, mf2, ta, ma
    vwaddu.vv   v20, v16, v19
    vwaddu.vv   v22, v17, v18
    
    vsetivli    zero, 8, e16, m1, ta, ma
    vadd.vv     v20, v20, v4
    vadd.vv     v22, v22, v6
.ifc \width, 16
    vadd.vv     v21, v21, v5
    vadd.vv     v23, v23, v7
.endif
    vsetivli    zero, 8, e8, mf2, ta, ma
    vnclipu.wi  v24, v20, 2
    vnclipu.wi  v25, v22, 2
.ifc \width, 16
    vnclipu.wi  v4, v21, 2
    vnclipu.wi  v5, v23, 2
    vsetivli    zero, 16, e8, m1, ta, ma
    vslideup.vi v24, v4, 8
    vslideup.vi v25, v5, 8
.endif
    vsetivli    zero, 16, e8, m1, ta, ma
    vmv1r.v     v0, v26
    vmerge.vvm  v16, v16, v24, v0
    vmerge.vvm  v17, v17, v25, v0
.endm

function deblock_v_chroma_intra_rvv
    h264_loop_filter_start_intra

    slli        t0, a1, 1
    sub         a0, a0, t0

    vle8.v      v18, (a0)
    add         a0, a0, a1
    vle8.v      v16, (a0)
    add         a0, a0, a1
    vle8.v      v17, (a0)
    add         a0, a0, a1
    vle8.v      v19, (a0)

    h264_loop_filter_chroma_intra

    sub         a0, a0, t0
    vse8.v      v16, (a0)
    add         a0, a0, a1
    vse8.v      v17, (a0)

    ret
endfunc

function deblock_strength_rvv
    vsetivli    zero, 16, e8, m1, ta, ma
    vmv.v.i     v4, 0
    slli        a4, a4, 8
    addi        a3, a3, 32
    li          t0, (1<<8)-3
    sub         a4, a4, t0
    vmv.v.i     v5, 0
    vsetivli    zero, 8, e16, m1, ta, ma
    vmv.v.x     v6, a4
    li          a6, -32
    csrwi  vxrm, 0

bframe:
    // load bytes ref
    addi        a2, a2, 16
    vsetivli    zero, 1, e64, m1, ta, ma
    vle64.v     v30, (a1)
    addi        a1, a1, 8
    vsetivli    zero, 16, e8, m1, ta, ma
    vslideup.vi v31, v30, 8
    vle8.v      v0, (a1)
    addi        a1, a1, 16
    vmv.v.i     v3, 0
    vle8.v      v1, (a1)
    addi        a1, a1, 16

    vslidedown.vi v2, v3, 15
    vslideup.vi   v2, v0, 1
    vslidedown.vi v3, v3, 15
    vslideup.vi   v3, v1, 1
    
    // unzip
    vmv1r.v     v8, v1
    vmv1r.v     v10, v3
    vsetivli    zero, 8, e32, m2, ta, ma
    vslideup.vi v0, v8, 4
    vslideup.vi v2, v10, 4
    vsetivli    zero, 4, e32, m1, ta, ma
    li          t0, 32
    vnsrl.wi    v21, v0, 0
    vnsrl.wx    v22, v0, t0
    vnsrl.wi    v23, v2, 0
    vnsrl.wx    v20, v2, t0

    vsetivli    zero, 16, e8, m1, ta, ma
    vslidedown.vi v21, v31, 12
    vslideup.vi   v21, v22, 4

    vxor.vv     v0, v20, v22
    vxor.vv     v1, v21, v22
    vor.vv      v4, v4, v0
    vor.vv      v5, v5, v1

    vle8.v      v21, (a2)
    addi        a2, a2, 16      // mv + 0x10
    vle8.v      v19, (a2)
    addi        a2, a2, 16
    vle8.v      v22, (a2)
    addi        a2, a2, 16
    vle8.v      v18, (a2)
    addi        a2, a2, 16
    vle8.v      v23, (a2)
    addi        a2, a2, 16

    vslidedown.vi v19, v19, 12
    vslideup.vi   v19, v22, 4
    vslidedown.vi v18, v18, 12
    vslideup.vi   v18, v23, 4

    vsetivli    zero, 8, e16, m1, ta, ma
    sabd        v0, v22, v19, v8
    vle16.v     v19, (a2)
    addi        a2, a2, 16      // mv + 0x60
    sabd        v1, v23, v18, v8
    vle16.v     v24, (a2)
    addi        a2, a2, 16      // mv + 0x70
    vle16.v     v18, (a2)
    addi        a2, a2, 16      // mv + 0x80
    vle16.v     v25, (a2)
    addi        a2, a2, 16      // mv + 0x90
    
    vsetivli    zero, 8, e8, mf2, ta, ma
    vnclipu.wi  v0, v0, 0
    vnclipu.wi  v1, v1, 0  
    vsetivli    zero, 16, e8, m1, ta, ma
    vslideup.vi v0, v1, 8

    vslidedown.vi v19, v19, 12
    vslideup.vi   v19, v24, 4
    vslidedown.vi v18, v18, 12
    vslideup.vi   v18, v25, 4

    vsetivli    zero, 8, e16, m1, ta, ma
    sabd        v1, v24, v19, v8
    sabd        v2, v25, v18, v8

    vsetivli    zero, 8, e8, mf2, ta, ma
    vnclipu.wi  v1, v1, 0
    vnclipu.wi  v2, v2, 0  
    vsetivli    zero, 16, e8, m1, ta, ma
    vslideup.vi v1, v2, 8

    vssubu.vv   v0, v0, v6
    vssubu.vv   v1, v1, v6

    vsetivli    zero, 8, e8, mf2, ta, ma
    vnclipu.wi  v0, v0, 0
    vnclipu.wi  v1, v1, 0  
    vsetivli    zero, 16, e8, m1, ta, ma
    vslideup.vi v0, v1, 8

    vor.vv      v4, v4, v0
    
    vsetivli    zero, 8, e16, m1, ta, ma
    sabd        v1, v22, v23, v8
    sabd        v0, v21, v22, v8
    sabd        v2, v23, v24, v8
    sabd        v3, v24, v25, v8

    vsetivli    zero, 8, e8, mf2, ta, ma
    vnclipu.wi  v0, v0, 0
    vnclipu.wi  v1, v1, 0
    vnclipu.wi  v2, v2, 0
    vnclipu.wi  v3, v3, 0
    vsetivli    zero, 16, e8, m1, ta, ma
    vslideup.vi v0, v1, 8
    vslideup.vi v2, v3, 8

    vssubu.vv   v0, v0, v6
    vssubu.vv   v1, v2, v6

    vsetivli    zero, 8, e8, mf2, ta, ma
    vnclipu.wi  v0, v0, 0
    vnclipu.wi  v1, v1, 0
    vsetivli    zero, 16, e8, m1, ta, ma
    vslideup.vi v0, v1, 8
    
    addi        a5, a5, -1
    vor.vv      v5, v5, v0
    beqz        a5, bframe

    vmv.v.i     v6, 1
    // load bytes nnz
    vsetivli    zero, 1, e64, m1, ta, ma
    vle64.v      v30, (a0)
    addi        a0, a0, 8
    vsetivli    zero, 16, e8, m1, ta, ma
    vslideup.vi v31, v30, 8
    vle8.v      v0, (a0)
    addi        a0, a0, 16
    vmv.v.i     v3, 0
    vle8.v      v1, (a0)
    addi        a0, a0, 16

    vslidedown.vi v2, v3, 15
    vslideup.vi   v2, v0, 1
    vslidedown.vi v3, v3, 15
    vslideup.vi   v3, v1, 1

    // unzip
    vmv1r.v v8, v1
    vmv1r.v v10, v3
    vsetivli    zero, 8, e32, m2, ta, ma
    vslideup.vi v0, v8, 4
    vslideup.vi v2, v10, 4
    vsetivli    zero, 4, e32, m1, ta, ma
    li          t0, 32
    vnsrl.wi    v21, v0, 0
    vnsrl.wx    v22, v0, t0
    vnsrl.wi    v23, v2, 0
    vnsrl.wx    v20, v2, t0

    vsetivli    zero, 16, e8, m1, ta, ma
    vslidedown.vi v21, v31, 12
    vslideup.vi   v21, v22, 4

    movrel      t0, transpose_table
    vle8.v      v7, (t0)
    vor.vv      v0, v20, v22
    vor.vv      v1, v21, v22
    vminu.vv    v0, v0, v6
    vminu.vv    v1, v1, v6
    vminu.vv    v4, v4, v6
    vminu.vv    v5, v5, v6
    vadd.vv     v0, v0, v0
    vadd.vv     v1, v1, v1
    vmaxu.vv    v4, v4, v0
    vmaxu.vv    v5, v5, v1
    vrgather.vv v6, v4, v7
    vse8.v      v5, (a3)
    add         a3, a3, a6
    vse8.v      v6, (a3)

    ret
endfunc