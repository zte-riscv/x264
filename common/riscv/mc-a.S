/*****************************************************************************
 * bitstream-a.S: riscv bitstream functions
 *****************************************************************************
 * Copyright (C) 2014-2024 x264 project
 *
 * Authors: Qian Jiayan <qianjiayan.1@bytedance.com>
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
#if BIT_DEPTH == 8

// void pixel_avg( pixel *dst,  intptr_t dst_stride,
//                 pixel *src1, intptr_t src1_stride,
//                 pixel *src2, intptr_t src2_stride, int weight );
.macro PIXEL_AVG_RVV w h
function pixel_avg_\w\()x\h\()_rvv, export=1
    csrwi vxrm, 0
    addi       t0, a6, -32
    li         t1, \h
    bnez       t0, pixel_avg_weight_w\w\()_rvv
    j       pixel_avg_w\w\()_rvv
endfunc
.endm
PIXEL_AVG_RVV 16, 16
PIXEL_AVG_RVV 16,  8
PIXEL_AVG_RVV  8, 16
PIXEL_AVG_RVV  8,  8
PIXEL_AVG_RVV  8,  4
PIXEL_AVG_RVV  4, 16
PIXEL_AVG_RVV  4,  8
PIXEL_AVG_RVV  4,  4
PIXEL_AVG_RVV  4,  2

function pixel_avg_weight_w4_rvv, export=0
    li   t0, 64
    sub  a7, t0, a6
    csrwi  vxrm, 0
    vsetivli    zero, 4, e8, mf4, ta, ma
    vmv.v.x v30, a6
    vmv.v.x v31, a7
1:
    addi  t1, t1, -2

    vle8.v    v1, (a2)
    add       a2, a2, a3
    vle8.v    v2, (a4) 
    add       a4, a4, a5
    vwmulsu.vv v16, v30, v1
    vwmaccsu.vv v16, v31, v2

    vle8.v    v3, (a2)
    add       a2, a2, a3
    vle8.v    v4, (a4) 
    add       a4, a4, a5
    vwmulsu.vv v17, v30, v3
    vwmaccsu.vv v17, v31, v4

    vsetivli    zero, 4, e16, mf2, ta, ma
    vmax.vx   v16, v16, zero
    vmax.vx   v17, v17, zero

    vsetivli    zero, 4, e8, mf4, ta, ma
    vnclipu.wi v5, v16, 6
    vnclipu.wi v6, v17, 6

    vse8.v    v5, (a0)
    add       a0, a0, a1
    vse8.v    v6, (a0)
    add       a0, a0, a1

    bgt       t1, zero, 1b
    ret
endfunc

function pixel_avg_weight_w8_rvv, export=0
    li   t0, 64
    sub  a7, t0, a6

    csrwi  vxrm, 0
    vsetivli    zero, 8, e8, mf2, ta, ma
    vmv.v.x v30, a6
    vmv.v.x v31, a7
1:
    addi  t1, t1, -4
    
    vle8.v    v1, (a2)
    add       a2, a2, a3
    vle8.v    v2, (a4) 
    add       a4, a4, a5
    vwmulsu.vv  v16, v30, v1
    vwmaccsu.vv v16, v31, v2


    vle8.v    v3, (a2)
    add       a2, a2, a3
    vle8.v    v4, (a4) 
    add       a4, a4, a5
    vwmulsu.vv  v17, v30, v3
    vwmaccsu.vv v17, v31, v4

    vle8.v    v5, (a2)
    add       a2, a2, a3
    vle8.v    v6, (a4) 
    add       a4, a4, a5
    vwmulsu.vv  v18, v30, v5
    vwmaccsu.vv v18, v31, v6

    vle8.v    v7, (a2)
    add       a2, a2, a3
    vle8.v    v8, (a4) 
    add       a4, a4, a5
    vwmulsu.vv  v19, v30, v7
    vwmaccsu.vv v19, v31, v8

    vsetivli    zero, 8, e16, m1, ta, ma
    vmax.vx   v16, v16, zero
    vmax.vx   v17, v17, zero
    vmax.vx   v18, v18, zero
    vmax.vx   v19, v19, zero

    vsetivli    zero, 8, e8, mf2, ta, ma
    vnclipu.wi v1, v16, 6
    vnclipu.wi v2, v17, 6
    vnclipu.wi v3, v18, 6
    vnclipu.wi v4, v19, 6

    vse8.v    v1, (a0)
    add       a0, a0, a1
    vse8.v    v2, (a0)
    add       a0, a0, a1
    vse8.v    v3, (a0)
    add       a0, a0, a1
    vse8.v    v4, (a0)
    add       a0, a0, a1

    bgt       t1, zero, 1b
    ret
endfunc

function pixel_avg_weight_w16_rvv, export=0
    li   t0, 64
    sub  a7, t0, a6

    csrwi  vxrm, 0
    vsetivli    zero, 16, e8, m1, ta, ma
    vmv.v.x v30, a6
    vmv.v.x v31, a7
1:
    addi  t1, t1, -2

    vle8.v    v1, (a2)
    add       a2, a2, a3
    vle8.v    v2, (a4) 
    add       a4, a4, a5
    vwmulsu.vv  v16, v30, v1
    vwmaccsu.vv v16, v31, v2

    vle8.v    v3, (a2)
    add       a2, a2, a3
    vle8.v    v4, (a4) 
    add       a4, a4, a5
    vwmulsu.vv  v18, v30, v3
    vwmaccsu.vv v18, v31, v4

    vsetivli    zero, 16, e16, m2, ta, ma
    vmax.vx   v16, v16, zero
    vmax.vx   v18, v18, zero

    vsetivli    zero, 16, e8, m1, ta, ma
    vnclipu.wi v5, v16, 6
    vnclipu.wi v6, v18, 6

    vse8.v    v5, (a0)
    add       a0, a0, a1
    vse8.v    v6, (a0)
    add       a0, a0, a1

    bgt       t1, zero, 1b
    ret
endfunc

function pixel_avg_w4_rvv, export=0
    csrwi  vxrm, 0
1:
    addi  t1, t1, -2
    vsetivli    zero, 4, e8, mf4, ta, ma
    vle8.v    v1, (a2)
    add       a2, a2, a3
    vle8.v    v2, (a4) 
    add       a4, a4, a5
    vaaddu.vv   v1, v1, v2
    vle8.v    v3, (a2)
    add       a2, a2, a3
    vle8.v    v4, (a4) 
    add       a4, a4, a5
    vaaddu.vv   v3, v3, v4

    vse8.v    v1, (a0)
    add       a0, a0, a1
    vse8.v    v3, (a0)
    add       a0, a0, a1
    bgt       t1, zero, 1b
    ret
endfunc

function pixel_avg_w8_rvv, export=0
    csrwi  vxrm, 0
1:
    addi  t1, t1, -4
    vsetivli    zero, 8, e8, mf2, ta, ma
    vle8.v    v1, (a2)
    add       a2, a2, a3
    vle8.v    v2, (a4) 
    add       a4, a4, a5
    vaaddu.vv   v1, v1, v2

    vle8.v    v3, (a2)
    add       a2, a2, a3
    vle8.v    v4, (a4) 
    add       a4, a4, a5
    vaaddu.vv   v3, v3, v4

    vle8.v    v5, (a2)
    add       a2, a2, a3
    vle8.v    v6, (a4) 
    add       a4, a4, a5
    vaaddu.vv   v5, v5, v6

    vle8.v    v7, (a2)
    add       a2, a2, a3
    vle8.v    v8, (a4) 
    add       a4, a4, a5
    vaaddu.vv   v7, v7, v8

    vse8.v    v1, (a0)
    add       a0, a0, a1
    vse8.v    v3, (a0)
    add       a0, a0, a1
    vse8.v    v5, (a0)
    add       a0, a0, a1
    vse8.v    v7, (a0)
    add       a0, a0, a1


    bgt       t1, zero, 1b
    ret
endfunc

function pixel_avg_w16_rvv, export=0
    csrwi  vxrm, 0
1:
    addi  t1, t1, -4
    vsetivli    zero, 16, e8, m1, ta, ma
    vle8.v    v1, (a2)
    add       a2, a2, a3
    vle8.v    v2, (a4) 
    add       a4, a4, a5
    vaaddu.vv   v1, v1, v2

    vle8.v    v3, (a2)
    add       a2, a2, a3
    vle8.v    v4, (a4) 
    add       a4, a4, a5
    vaaddu.vv   v3, v3, v4

    vle8.v    v5, (a2)
    add       a2, a2, a3
    vle8.v    v6, (a4) 
    add       a4, a4, a5
    vaaddu.vv   v5, v5, v6

    vle8.v    v7, (a2)
    add       a2, a2, a3
    vle8.v    v8, (a4) 
    add       a4, a4, a5
    vaaddu.vv   v7, v7, v8

    vse8.v    v1, (a0)
    add       a0, a0, a1
    vse8.v    v3, (a0)
    add       a0, a0, a1
    vse8.v    v5, (a0)
    add       a0, a0, a1
    vse8.v    v7, (a0)
    add       a0, a0, a1


    bgt       t1, zero, 1b
    ret
endfunc

function pixel_avg2_w4_rvv, export=1
    csrwi  vxrm, 0
1:
    addi  a5, a5, -2
    vsetivli    zero, 4, e8, mf4, ta, ma
    vle8.v    v1, (a2)
    add       a2, a2, a3
    vle8.v    v2, (a4) 
    add       a4, a4, a3
    vaaddu.vv   v1, v1, v2
    vle8.v    v3, (a2)
    add       a2, a2, a3
    vle8.v    v4, (a4) 
    add       a4, a4, a3
    vaaddu.vv   v3, v3, v4

    vse8.v    v1, (a0)
    add       a0, a0, a1
    vse8.v    v3, (a0)
    add       a0, a0, a1
    bgt       a5, zero, 1b
    ret
endfunc

function pixel_avg2_w8_rvv, export=1
    csrwi  vxrm, 0
1:
    addi  a5, a5, -2
    vsetivli    zero, 8, e8, mf2, ta, ma
    vle8.v    v1, (a2)
    add       a2, a2, a3
    vle8.v    v2, (a4) 
    add       a4, a4, a3
    vaaddu.vv   v1, v1, v2
    vle8.v    v3, (a2)
    add       a2, a2, a3
    vle8.v    v4, (a4) 
    add       a4, a4, a3
    vaaddu.vv   v3, v3, v4

    vse8.v    v1, (a0)
    add       a0, a0, a1
    vse8.v    v3, (a0)
    add       a0, a0, a1
    bgt       a5, zero, 1b
    ret
endfunc

function pixel_avg2_w16_rvv, export=1
    csrwi  vxrm, 0
1:
    addi  a5, a5, -2
    vsetivli    zero, 16, e8, m1, ta, ma
    vle8.v    v1, (a2)
    add       a2, a2, a3
    vle8.v    v2, (a4) 
    add       a4, a4, a3
    vaaddu.vv   v1, v1, v2
    vle8.v    v3, (a2)
    add       a2, a2, a3
    vle8.v    v4, (a4) 
    add       a4, a4, a3
    vaaddu.vv   v3, v3, v4

    vse8.v    v1, (a0)
    add       a0, a0, a1
    vse8.v    v3, (a0)
    add       a0, a0, a1
    bgt       a5, zero, 1b
    ret
endfunc

function pixel_avg2_w20_rvv, export=1
    csrwi  vxrm, 0
1:
    addi  a5, a5, -2
    vsetivli    zero, 20, e8, m2, ta, ma
    vle8.v    v0, (a2)
    add       a2, a2, a3
    vle8.v    v2, (a4) 
    add       a4, a4, a3
    vaaddu.vv   v0, v0, v2
    vle8.v    v4, (a2)
    add       a2, a2, a3
    vle8.v    v6, (a4) 
    add       a4, a4, a3
    vaaddu.vv   v4, v4, v6

    vse8.v    v0, (a0)
    add       a0, a0, a1
    vse8.v    v4, (a0)
    add       a0, a0, a1
    bgt       a5, zero, 1b
    ret
endfunc

function mc_weight_w4_rvv, export=1
    csrwi  vxrm, 0
    ld t0, 36(a4) // scale
    ld t1, 40(a4) // offset
    ld t2, 32(a4) // denom
    vsetivli    zero, 4, e16, mf2, ta, ma
    vmv.v.x   v21, t1
    vmv.v.x   v22, t2
    vsetivli    zero, 4, e8, mf4, ta, ma
    vmv.v.x   v20, t0
1:
    addi  a5, a5, -2
    vle8.v    v0, (a2)
    add       a2, a2, a3
    vle8.v    v2, (a2)
    add       a2, a2, a3

    vwmulu.vv v4, v0, v20
    vwmulu.vv v6, v2, v20

    vsetivli    zero, 4, e16, mf2, ta, ma
    vssrl.vv  v4, v4, v22
    vssrl.vv  v6, v6, v22

    vadd.vv   v4, v4, v21
    vadd.vv   v6, v6, v21

    vmax.vx   v4, v4, zero
    vmax.vx   v6, v6, zero

    vsetivli    zero, 4, e8, mf4, ta, ma
    vnclipu.wi v0, v4, 0
    vnclipu.wi v2, v6, 0

    vse8.v    v0, (a0)
    add       a0, a0, a1
    vse8.v    v2, (a0)
    add       a0, a0, a1
    bgt       a5, zero, 1b
    ret
endfunc

function mc_weight_w8_rvv, export=1
    csrwi  vxrm, 0
    ld t0, 36(a4) // scale
    ld t1, 40(a4) // offset
    ld t2, 32(a4) // denom
    vsetivli    zero, 8, e16, m1, ta, ma
    vmv.v.x   v21, t1
    vmv.v.x   v22, t2
    vsetivli    zero, 8, e8, mf2, ta, ma
    vmv.v.x   v20, t0
1:
    addi  a5, a5, -2
    vsetivli    zero, 8, e8, mf2, ta, ma
    vle8.v    v0, (a2)
    add       a2, a2, a3
    vle8.v    v2, (a2)
    add       a2, a2, a3

    vwmulu.vv v4, v0, v20
    vwmulu.vv v6, v2, v20

    vsetivli    zero, 8, e16, m1, ta, ma
    vssrl.vv  v4, v4, v22
    vssrl.vv  v6, v6, v22

    vadd.vv   v4, v4, v21
    vadd.vv   v6, v6, v21

    vmax.vx   v4, v4, zero
    vmax.vx   v6, v6, zero

    vsetivli    zero, 8, e8, mf2, ta, ma
    vnclipu.wi v0, v4, 0
    vnclipu.wi v2, v6, 0

    vse8.v    v0, (a0)
    add       a0, a0, a1
    vse8.v    v2, (a0)
    add       a0, a0, a1
    bgt       a5, zero, 1b
    ret
endfunc

function mc_weight_w16_rvv, export=1
    csrwi  vxrm, 0
    ld t0, 36(a4) // scale
    ld t1, 40(a4) // offset
    ld t2, 32(a4) // denom
    vsetivli    zero, 16, e16, m2, ta, ma
    vmv.v.x   v22, t1
    vmv.v.x   v24, t2
    vsetivli    zero, 16, e8, m1, ta, ma
    vmv.v.x   v20, t0
1:
    addi  a5, a5, -2
    vsetivli    zero, 16, e8, m1, ta, ma
    vle8.v    v0, (a2)
    add       a2, a2, a3
    vle8.v    v2, (a2)
    add       a2, a2, a3

    vwmulu.vv v4, v0, v20
    vwmulu.vv v6, v2, v20

    vsetivli    zero, 16, e16, m2, ta, ma
    vssrl.vv  v4, v4, v24
    vssrl.vv  v6, v6, v24

    vadd.vv   v4, v4, v22
    vadd.vv   v6, v6, v22

    vmax.vx   v4, v4, zero
    vmax.vx   v6, v6, zero

    vsetivli    zero, 16, e8, m1, ta, ma
    vnclipu.wi v0, v4, 0
    vnclipu.wi v2, v6, 0

    vse8.v    v0, (a0)
    add       a0, a0, a1
    vse8.v    v2, (a0)
    add       a0, a0, a1
    bgt       a5, zero, 1b
    ret
endfunc

function mc_weight_w20_rvv, export=1
    csrwi  vxrm, 0
    ld t0, 36(a4) // scale
    ld t1, 40(a4) // offset
    ld t2, 32(a4) // denom
1:
    addi  a5, a5, -2
    vsetivli    zero, 20, e8, m2, ta, ma
    vle8.v    v0, (a2)
    add       a2, a2, a3
    vle8.v    v2, (a2)
    add       a2, a2, a3

    vwmulu.vx v4, v0, t0
    vwmulu.vx v8, v2, t0

    vsetivli    zero, 20, e16, m4, ta, ma
    vssrl.vx  v4, v4, t2
    vssrl.vx  v8, v8, t2

    vadd.vx   v4, v4, t1
    vadd.vx   v8, v8, t1

    vmax.vx   v4, v4, zero
    vmax.vx   v8, v8, zero

    vsetivli    zero, 20, e8, m2, ta, ma
    vnclipu.wi v0, v4, 0
    vnclipu.wi v2, v8, 0

    vse8.v    v0, (a0)
    add       a0, a0, a1
    vse8.v    v2, (a0)
    add       a0, a0, a1
    bgt       a5, zero, 1b
    ret
endfunc

function mc_weight_w4_nodenom_rvv, export=1
    csrwi  vxrm, 0
    ld t0, 36(a4) // scale
    ld t1, 40(a4) // offset
    vsetivli    zero, 4, e8, mf4, ta, ma
    vmv.v.x   v20, t0
    vsetivli    zero, 4, e16, mf2, ta, ma
    vmv.v.x   v21, t1
1:
    addi  a5, a5, -2
    vsetivli    zero, 4, e16, mf2, ta, ma
    vmv.v.v   v4, v21
    vmv.v.v   v6, v21
    vsetivli    zero, 4, e8, mf4, ta, ma
    vle8.v    v0, (a2)
    add       a2, a2, a3
    vle8.v    v2, (a2)
    add       a2, a2, a3

    vwmaccu.vv v4, v20, v0
    vwmaccu.vv v6, v20, v2

    vsetivli    zero, 4, e16, mf2, ta, ma
    vmax.vx   v4, v4, zero
    vmax.vx   v6, v6, zero

    vsetivli    zero, 4, e8, mf4, ta, ma
    vnclipu.wi v0, v4, 0
    vnclipu.wi v2, v6, 0

    vse8.v    v0, (a0)
    add       a0, a0, a1
    vse8.v    v2, (a0)
    add       a0, a0, a1
    bgt       a5, zero, 1b
    ret
endfunc

function mc_weight_w8_nodenom_rvv, export=1
    csrwi  vxrm, 0
    ld t0, 36(a4) // scale
    ld t1, 40(a4) // offset
    vsetivli    zero, 8, e8, mf2, ta, ma
    vmv.v.x   v20, t0
    vsetivli    zero, 8, e16, m1, ta, ma
    vmv.v.x   v21, t1
1:
    addi  a5, a5, -2
    vsetivli    zero, 8, e16, m1, ta, ma
    vmv.v.v   v4, v21
    vmv.v.v   v6, v21
    vsetivli    zero, 8, e8, mf2, ta, ma
    vle8.v    v0, (a2)
    add       a2, a2, a3
    vle8.v    v2, (a2)
    add       a2, a2, a3

    vwmaccu.vv v4, v20, v0
    vwmaccu.vv v6, v20, v2

    vsetivli    zero, 8, e16, m1, ta, ma
    vmax.vx   v4, v4, zero
    vmax.vx   v6, v6, zero

    vsetivli    zero, 8, e8, mf2, ta, ma
    vnclipu.wi v0, v4, 0
    vnclipu.wi v2, v6, 0

    vse8.v    v0, (a0)
    add       a0, a0, a1
    vse8.v    v2, (a0)
    add       a0, a0, a1
    bgt       a5, zero, 1b
    ret
endfunc

function mc_weight_w16_nodenom_rvv, export=1
    csrwi  vxrm, 0
    ld t0, 36(a4) // scale
    ld t1, 40(a4) // offset
    vsetivli    zero, 16, e8, m1, ta, ma
    vmv.v.x   v20, t0
    vsetivli    zero, 16, e16, m2, ta, ma
    vmv.v.x   v22, t1
1:
    addi  a5, a5, -2
    vsetivli    zero, 16, e16, m2, ta, ma
    vmv.v.v   v4, v22
    vmv.v.v   v6, v22
    vsetivli    zero, 16, e8, m1, ta, ma
    vle8.v    v0, (a2)
    add       a2, a2, a3
    vle8.v    v2, (a2)
    add       a2, a2, a3

    vwmaccu.vv v4, v20, v0
    vwmaccu.vv v6, v20, v2

    vsetivli    zero, 16, e16, m2, ta, ma
    vmax.vx   v4, v4, zero
    vmax.vx   v6, v6, zero

    vsetivli    zero, 16, e8, m1, ta, ma
    vnclipu.wi v0, v4, 0
    vnclipu.wi v2, v6, 0

    vse8.v    v0, (a0)
    add       a0, a0, a1
    vse8.v    v2, (a0)
    add       a0, a0, a1
    bgt       a5, zero, 1b
    ret
endfunc

function mc_weight_w20_nodenom_rvv, export=1
    csrwi  vxrm, 0
    ld t0, 36(a4) // scale
    ld t1, 40(a4) // offset
1:
    addi  a5, a5, -2
    vsetivli    zero, 20, e16, m4, ta, ma
    vmv.v.x   v4, t1
    vmv.v.x   v8, t1
    vsetivli  zero, 20, e8, m2, ta, ma
    vle8.v    v0, (a2)
    add       a2, a2, a3
    vle8.v    v2, (a2)
    add       a2, a2, a3

    vwmaccu.vx v4, t0, v0
    vwmaccu.vx v8, t0, v2

    vsetivli    zero, 20, e16, m4, ta, ma
    vmax.vx   v4, v4, zero
    vmax.vx   v8, v8, zero

    vsetivli    zero, 20, e8, m2, ta, ma
    vnclipu.wi v0, v4, 0
    vnclipu.wi v2, v8, 0

    vse8.v    v0, (a0)
    add       a0, a0, a1
    vse8.v    v2, (a0)
    add       a0, a0, a1
    bgt       a5, zero, 1b
    ret
endfunc

.macro weight_simple name op
function mc_weight_w4_\name\()_rvv, export=1
    csrwi  vxrm, 0
    ld t0, 0(a4)
    vsetivli    zero, 4, e8, mf4, ta, ma
    vmv.v.x   v31, t0
1:
    addi  a5, a5, -2
    vle8.v    v1, (a2)
    add       a2, a2, a3
    vle8.v    v2, (a2)
    add       a2, a2, a3
    \op       v1, v1, v31
    \op       v2, v2, v31

    vse8.v    v1, (a0)
    add       a0, a0, a1
    vse8.v    v2, (a0)
    add       a0, a0, a1
    bgt       a5, zero, 1b
    ret
endfunc

function mc_weight_w8_\name\()_rvv, export=1
    csrwi  vxrm, 0
    ld t0, 0(a4)
    vsetivli    zero, 8, e8, mf2, ta, ma
    vmv.v.x   v31, t0
1:
    addi  a5, a5, -2
    vle8.v    v1, (a2)
    add       a2, a2, a3
    vle8.v    v2, (a2)
    add       a2, a2, a3
    \op       v1, v1, v31
    \op       v2, v2, v31

    vse8.v    v1, (a0)
    add       a0, a0, a1
    vse8.v    v2, (a0)
    add       a0, a0, a1
    bgt       a5, zero, 1b
    ret
endfunc

function mc_weight_w16_\name\()_rvv, export=1
    csrwi  vxrm, 0
    ld t0, 0(a4)
    vsetivli    zero, 16, e8, m1, ta, ma
    vmv.v.x   v31, t0
1:
    addi  a5, a5, -2
    vle8.v    v1, (a2)
    add       a2, a2, a3
    vle8.v    v2, (a2)
    add       a2, a2, a3
    \op       v1, v1, v31
    \op       v2, v2, v31

    vse8.v    v1, (a0)
    add       a0, a0, a1
    vse8.v    v2, (a0)
    add       a0, a0, a1
    bgt       a5, zero, 1b
    ret
endfunc


function mc_weight_w20_\name\()_rvv, export=1
    csrwi  vxrm, 0
    ld t0, 0(a4)
    vsetivli    zero, 20, e8, m2, ta, ma
    vmv.v.x   v30, t0
1:
    addi  a5, a5, -2
    vle8.v    v4, (a2)
    add       a2, a2, a3
    vle8.v    v2, (a2)
    add       a2, a2, a3
    \op       v4, v4, v30
    \op       v2, v2, v30

    vse8.v    v4, (a0)
    add       a0, a0, a1
    vse8.v    v2, (a0)
    add       a0, a0, a1
    bgt       a5, zero, 1b
    ret
endfunc

.endm

weight_simple offsetadd, vsaddu.vv
weight_simple offsetsub, vssubu.vv

// ============================================================================
// Main Dispatcher
// ============================================================================
// void mc_chroma( uint8_t *dst_u, uint8_t *dst_v, intptr_t i_dst_stride,
//                 uint8_t *src, intptr_t i_src_stride,
//                 int dx, int dy, int i_width, int i_height );
function mc_chroma_rvv, export=1
    ld      t6, 0(sp)           // i_height
    sra     t0, a6, 3           // dy >> 3 (signed)
    sra     t1, a5, 3           // dx >> 3 (signed)

    mul     t0, t0, a4          // dy_int * src_stride
    add     a3, a3, t0          // src += offset_y

    sll     t1, t1, 1           // dx_int * 2 (interleaved UV)
    add     a3, a3, t1          // src += offset_x

    andi    a5, a5, 7           // dx &= 7
    andi    a6, a6, 7           // dy &= 7

    li      t0, 4
    bgt     a7, t0, mc_chroma_w8_rvv
    beq     a7, t0, mc_chroma_w4_rvv
endfunc

// Helper macro to calculate weights
// Inputs: a5 = dx, a6 = dy
// Outputs: t0=cA, t1=cB, t2=cC, t3=cD
.macro CHROMA_MC_START
    mul     t3, a5, a6          // cD = dx * dy
    sll     t4, a5, 3           // dx * 8
    li      t0, 64
    sll     t5, a6, 3           // dy * 8
    
    add     t0, t0, t3          // 64 + cD
    sub     t0, t0, t4          // 64 + cD - 8dx
    sub     t0, t0, t5          // cA = (8-dx)*(8-dy)

    sub     t1, t4, t3          // cB = 8dx - dxdy
    sub     t2, t5, t3          // cC = 8dy - dxdy
.endm

// ---------------------------------------------------------------------------
// mc_chroma_w2_rvv (Scalar optimized)
// ---------------------------------------------------------------------------
function mc_chroma_w2_rvv, export=0
    CHROMA_MC_START             // t0=cA, t1=cB, t2=cC, t3=cD

    ld      t5, 0(a3)           // Row 0
    add     a3, a3, a4
    li      a7, 32              // Rounding offset

1:
    ld      t4, 0(a3)           // Row 1
    add     a3, a3, a4
    addi    t6, t6, -1

    // ---------------- U0 ----------------
    andi    a5, t5, 0xFF        // U0_r0
    mul     a5, a5, t0
    srli    a6, t5, 16          // U1_r0
    andi    a6, a6, 0xFF
    mul     a6, a6, t1
    add     a5, a5, a6

    andi    a6, t4, 0xFF        // U0_r1
    mul     a6, a6, t2
    add     a5, a5, a6
    srli    a6, t4, 16          // U1_r1
    andi    a6, a6, 0xFF
    mul     a6, a6, t3
    add     a5, a5, a6

    add     a5, a5, a7
    srai    a5, a5, 6
    sb      a5, 0(a0)           // dst_u[0]

    // ---------------- U1 ----------------
    srli    a5, t5, 16          // U1_r0
    andi    a5, a5, 0xFF
    mul     a5, a5, t0
    srli    a6, t5, 32          // U2_r0
    andi    a6, a6, 0xFF
    mul     a6, a6, t1
    add     a5, a5, a6

    srli    a6, t4, 16          // U1_r1
    andi    a6, a6, 0xFF
    mul     a6, a6, t2
    add     a5, a5, a6
    srli    a6, t4, 32          // U2_r1
    andi    a6, a6, 0xFF
    mul     a6, a6, t3
    add     a5, a5, a6

    add     a5, a5, a7
    srai    a5, a5, 6
    sb      a5, 1(a0)           // dst_u[1]
    add     a0, a0, a2

    // ---------------- V0 ----------------
    srli    a5, t5, 8           // V0_r0
    andi    a5, a5, 0xFF
    mul     a5, a5, t0
    srli    a6, t5, 24          // V1_r0
    andi    a6, a6, 0xFF
    mul     a6, a6, t1
    add     a5, a5, a6

    srli    a6, t4, 8           // V0_r1
    andi    a6, a6, 0xFF
    mul     a6, a6, t2
    add     a5, a5, a6
    srli    a6, t4, 24          // V1_r1
    andi    a6, a6, 0xFF
    mul     a6, a6, t3
    add     a5, a5, a6

    add     a5, a5, a7
    srai    a5, a5, 6
    sb      a5, 0(a1)           // dst_v[0]

    // ---------------- V1 ----------------
    srli    a5, t5, 24          // V1_r0
    andi    a5, a5, 0xFF
    mul     a5, a5, t0
    srli    a6, t5, 40          // V2_r0
    andi    a6, a6, 0xFF
    mul     a6, a6, t1
    add     a5, a5, a6

    srli    a6, t4, 24          // V1_r1
    andi    a6, a6, 0xFF
    mul     a6, a6, t2
    add     a5, a5, a6
    srli    a6, t4, 40          // V2_r1
    andi    a6, a6, 0xFF
    mul     a6, a6, t3
    add     a5, a5, a6

    add     a5, a5, a7
    srai    a5, a5, 6
    sb      a5, 1(a1)           // dst_v[1]
    add     a1, a1, a2

    mv      t5, t4
    bnez    t6, 1b
    ret
endfunc

// ---------------------------------------------------------------------------
// mc_chroma_w4_rvv
// ---------------------------------------------------------------------------
function mc_chroma_w4_rvv, export=0
    CHROMA_MC_START
    csrwi   vxrm, 0             

    // Prepare deinterleave indices
    vsetivli zero, 5, e8, mf2, ta, ma
    vid.v   v26                 // 0, 1, 2, 3, 4
    vsll.vi v26, v26, 1         // 0, 2, 4, 6, 8 (U)
    vadd.vi v27, v26, 1         // 1, 3, 5, 7, 9 (V)

    beqz    a6, 4f
    beqz    a5, 2f

    // ========================================================================
    // Case 1: 2D Interpolation (dx != 0 && dy != 0)
    // ========================================================================
    vsetivli zero, 4, e8, mf2, ta, ma
    vmv.v.x  v28, t0            // cA
    vmv.v.x  v29, t1            // cB
    vmv.v.x  v30, t2            // cC
    vmv.v.x  v31, t3            // cD
    
    // Load Row 0
    vsetivli zero, 10, e8, m1, ta, ma
    vle8.v   v12, (a3)
    add      a3, a3, a4
    
    vrgather.vv v0, v12, v26    // U0
    vrgather.vv v1, v12, v27    // V0
    vslide1down.vx v2, v0, zero // U0_next
    vslide1down.vx v3, v1, zero // V0_next

1:  // Height loop
    addi    t6, t6, -2

    // Load Row 1
    vsetivli zero, 10, e8, m1, ta, ma
    vle8.v   v12, (a3)
    add      a3, a3, a4
    
    vrgather.vv v4, v12, v26    // U1
    vrgather.vv v5, v12, v27    // V1
    vslide1down.vx v6, v4, zero // U1_next
    vslide1down.vx v7, v5, zero // V1_next

    // Calc Row 0
    vsetivli zero, 4, e8, mf2, ta, ma
    // U = U0*cA + U0n*cB + U1*cC + U1n*cD
    vwmulu.vv   v16, v0, v28
    vwmaccu.vv  v16, v29, v2
    vwmaccu.vv  v16, v30, v4
    vwmaccu.vv  v16, v31, v6

    // V = V0*cA + V0n*cB + V1*cC + V1n*cD
    vwmulu.vv   v18, v1, v28
    vwmaccu.vv  v18, v29, v3
    vwmaccu.vv  v18, v30, v5
    vwmaccu.vv  v18, v31, v7

    // Store Row 0
    vnclipu.wi  v24, v16, 6
    vnclipu.wi  v25, v18, 6
    vse8.v      v24, (a0)
    add         a0, a0, a2
    vse8.v      v25, (a1)
    add         a1, a1, a2

    // Load Row 2
    vsetivli zero, 10, e8, m1, ta, ma
    vle8.v   v12, (a3)
    add      a3, a3, a4

    vrgather.vv v0, v12, v26
    vrgather.vv v1, v12, v27
    vslide1down.vx v2, v0, zero
    vslide1down.vx v3, v1, zero

    // Calc Row 1
    vsetivli zero, 4, e8, mf2, ta, ma
    // U
    vwmulu.vv   v16, v4, v28
    vwmaccu.vv  v16, v29, v6
    vwmaccu.vv  v16, v30, v0
    vwmaccu.vv  v16, v31, v2

    // V
    vwmulu.vv   v18, v5, v28
    vwmaccu.vv  v18, v29, v7
    vwmaccu.vv  v18, v30, v1
    vwmaccu.vv  v18, v31, v3

    // Store Row 1
    vnclipu.wi  v24, v16, 6
    vnclipu.wi  v25, v18, 6
    vse8.v      v24, (a0)
    add         a0, a0, a2
    vse8.v      v25, (a1)
    add         a1, a1, a2

    bgtz    t6, 1b
    ret

    // ========================================================================
    // Case 2: Vertical Only (dx == 0)
    // ========================================================================
2:
    vsetivli zero, 4, e8, mf2, ta, ma
    vmv.v.x  v28, t0            // cA
    vmv.v.x  v30, t2            // cC

    // Load Row 0
    vsetivli zero, 8, e8, m1, ta, ma
    vle8.v   v12, (a3)
    add      a3, a3, a4
    vrgather.vv v0, v12, v26
    vrgather.vv v1, v12, v27

3:  // Vertical loop
    addi    t6, t6, -2

    // Load Row 1
    vsetivli zero, 8, e8, mf2, ta, ma
    vle8.v   v12, (a3)
    add      a3, a3, a4
    vrgather.vv v4, v12, v26
    vrgather.vv v5, v12, v27

    // Calc Row 0
    vsetivli zero, 4, e8, mf2, ta, ma
    vwmulu.vv   v16, v0, v28
    vwmaccu.vv  v16, v30, v4
    vwmulu.vv   v18, v1, v28
    vwmaccu.vv  v18, v30, v5

    vnclipu.wi  v24, v16, 6
    vnclipu.wi  v25, v18, 6
    vse8.v      v24, (a0)
    add         a0, a0, a2
    vse8.v      v25, (a1)
    add         a1, a1, a2

    // Load Row 2
    vsetivli zero, 8, e8, m1, ta, ma
    vle8.v   v12, (a3)
    add      a3, a3, a4
    vrgather.vv v0, v12, v26
    vrgather.vv v1, v12, v27

    // Calc Row 1
    vsetivli zero, 4, e8, mf2, ta, ma
    vwmulu.vv   v16, v4, v28
    vwmaccu.vv  v16, v30, v0
    vwmulu.vv   v18, v5, v28
    vwmaccu.vv  v18, v30, v1

    vnclipu.wi  v24, v16, 6
    vnclipu.wi  v25, v18, 6
    vse8.v      v24, (a0)
    add         a0, a0, a2
    vse8.v      v25, (a1)
    add         a1, a1, a2

    bgtz    t6, 3b
    ret

    // ========================================================================
    // Case 3: Horizontal Only (dy == 0)
    // ========================================================================
4:
    vsetivli zero, 4, e8, mf2, ta, ma
    vmv.v.x  v28, t0            // cA
    vmv.v.x  v29, t1            // cB
    vsetivli zero, 9, e8, m1, ta, ma

5:  // Horizontal loop
    addi    t6, t6, -2

    // Load Row 0
    vsetivli zero, 10, e8, m1, ta, ma
    vle8.v   v12, (a3)
    add      a3, a3, a4
    vrgather.vv v0, v12, v26
    vrgather.vv v1, v12, v27
    vslide1down.vx v2, v0, zero 
    vslide1down.vx v3, v1, zero 
    
    // Load Row 1
    vle8.v   v12, (a3)
    add      a3, a3, a4
    vrgather.vv v4, v12, v26
    vrgather.vv v5, v12, v27
    vslide1down.vx v6, v4, zero 
    vslide1down.vx v7, v5, zero 

    // Calc Row 0
    vsetivli zero, 4, e8, mf2, ta, ma
    vwmulu.vv   v16, v0, v28
    vwmaccu.vv  v16, v29, v2
    vwmulu.vv   v18, v1, v28
    vwmaccu.vv  v18, v29, v3

    vnclipu.wi  v24, v16, 6
    vnclipu.wi  v25, v18, 6
    vse8.v      v24, (a0)
    add         a0, a0, a2
    vse8.v      v25, (a1)
    add         a1, a1, a2

    // Calc Row 1
    vwmulu.vv   v16, v4, v28
    vwmaccu.vv  v16, v29, v6
    vwmulu.vv   v18, v5, v28
    vwmaccu.vv  v18, v29, v7

    vnclipu.wi  v24, v16, 6
    vnclipu.wi  v25, v18, 6
    vse8.v      v24, (a0)
    add         a0, a0, a2
    vse8.v      v25, (a1)
    add         a1, a1, a2

    bgtz    t6, 5b
    ret
endfunc

// ---------------------------------------------------------------------------
// mc_chroma_w8_rvv
// ---------------------------------------------------------------------------
function mc_chroma_w8_rvv, export=0
    CHROMA_MC_START
    csrwi   vxrm, 0             

    beqz    a6, 4f              // dy == 0
    beqz    a5, 2f              // dx == 0

    // =========================================================
    // Case 1: 2D Interpolation (dx != 0 && dy != 0)
    // =========================================================
    vsetivli zero, 8, e8, m1, ta, ma
    vmv.v.x  v28, t0            // cA
    vmv.v.x  v29, t1            // cB
    vmv.v.x  v30, t2            // cC
    vmv.v.x  v31, t3            // cD
    
    // Load Row 0
    vsetivli zero, 9, e8, m1, ta, ma
    vlseg2e8.v  v0, (a3)        // v0=U0, v1=V0
    add         a3, a3, a4
    vslide1down.vx v2, v0, zero // U0_next
    vslide1down.vx v3, v1, zero // V0_next

1:  // Height Loop
    addi    t6, t6, -2

    // Load Row 1
    vsetivli zero, 9, e8, m1, ta, ma
    vlseg2e8.v  v4, (a3)        // v4=U1, v5=V1
    add         a3, a3, a4
    vslide1down.vx v6, v4, zero // U1_next
    vslide1down.vx v7, v5, zero // V1_next

    // Calc Row 0
    vsetivli zero, 8, e8, m1, ta, ma
    // U
    vwmulu.vv   v16, v0, v28
    vwmaccu.vv  v16, v29, v2
    vwmaccu.vv  v16, v30, v4
    vwmaccu.vv  v16, v31, v6
    // V
    vwmulu.vv   v18, v1, v28
    vwmaccu.vv  v18, v29, v3
    vwmaccu.vv  v18, v30, v5
    vwmaccu.vv  v18, v31, v7

    // Store Row 0
    vnclipu.wi  v24, v16, 6
    vnclipu.wi  v25, v18, 6
    vse8.v      v24, (a0)
    add         a0, a0, a2
    vse8.v      v25, (a1)
    add         a1, a1, a2

    // Load Row 2
    vsetivli zero, 9, e8, m1, ta, ma
    vlseg2e8.v  v0, (a3)        
    add         a3, a3, a4
    vslide1down.vx v2, v0, zero
    vslide1down.vx v3, v1, zero

    // Calc Row 1
    vsetivli zero, 8, e8, m1, ta, ma
    // U
    vwmulu.vv   v16, v4, v28
    vwmaccu.vv  v16, v29, v6        
    vwmaccu.vv  v16, v30, v0    // Row 2 is new bottom
    vwmaccu.vv  v16, v31, v2       
    // V
    vwmulu.vv   v18, v5, v28
    vwmaccu.vv  v18, v29, v7        
    vwmaccu.vv  v18, v30, v1        
    vwmaccu.vv  v18, v31, v3       

    // Store Row 1
    vnclipu.wi  v24, v16, 6
    vnclipu.wi  v25, v18, 6
    vse8.v      v24, (a0)
    add         a0, a0, a2
    vse8.v      v25, (a1)
    add         a1, a1, a2

    bgtz    t6, 1b
    ret

    // =========================================================
    // Case 2: Vertical Only (dx == 0)
    // =========================================================
2:   
    vsetivli zero, 8, e8, m1, ta, ma
    vid.v    v26            // 0..7
    vsll.vi  v26, v26, 1    // U index
    vadd.vi  v27, v26, 1    // V index

    vmv.v.x  v28, t0        // cA
    vmv.v.x  v30, t2        // cC

    // Load Row 0
    vsetivli zero, 16, e8, m1, ta, ma
    vle8.v   v12, (a3)
    add      a3, a3, a4
    vrgather.vv v0, v12, v26
    vrgather.vv v1, v12, v27

3:  // Vertical loop
    addi    t6, t6, -2

    // Load Row 1
    vsetivli zero, 16, e8, m2, ta, ma
    vle8.v   v12, (a3)
    add      a3, a3, a4

    vsetivli zero, 8, e8, m1, ta, ma
    vrgather.vv v4, v12, v26
    vrgather.vv v5, v12, v27
    
    // Calc Row 0
    vwmulu.vv   v16, v0, v28
    vwmaccu.vv  v16, v30, v4
    vwmulu.vv   v18, v1, v28
    vwmaccu.vv  v18, v30, v5
    
    vnclipu.wi  v24, v16, 6
    vnclipu.wi  v25, v18, 6
    vse8.v      v24, (a0)
    add         a0, a0, a2
    vse8.v      v25, (a1)
    add         a1, a1, a2

    // Load Row 2
    vsetivli zero, 16, e8, m2, ta, ma
    vle8.v   v12, (a3)
    add      a3, a3, a4

    vsetivli zero, 8, e8, m1, ta, ma
    vrgather.vv v0, v12, v26
    vrgather.vv v1, v12, v27

    // Calc Row 1
    vwmulu.vv   v16, v4, v28
    vwmaccu.vv  v16, v30, v0
    vwmulu.vv   v18, v5, v28
    vwmaccu.vv  v18, v30, v1

    vnclipu.wi  v24, v16, 6
    vnclipu.wi  v25, v18, 6
    vse8.v      v24, (a0)
    add         a0, a0, a2
    vse8.v      v25, (a1)
    add         a1, a1, a2

    bgtz    t6, 3b
    ret

    // =========================================================
    // Case 3: Horizontal Only (dy == 0)
    // =========================================================
4:
    vsetivli zero, 8, e8, m1, ta, ma
    vmv.v.x  v28, t0        // cA
    vmv.v.x  v29, t1        // cB
    
    vsetivli zero, 9, e8, m1, ta, ma

5:  // Horizontal loop
    addi    t6, t6, -2

    // Load Row 0
    vlseg2e8.v  v0, (a3)
    add         a3, a3, a4
    vslide1down.vx v2, v0, zero 
    vslide1down.vx v3, v1, zero 
    
    // Load Row 1
    vlseg2e8.v  v4, (a3)
    add         a3, a3, a4
    vslide1down.vx v6, v4, zero 
    vslide1down.vx v7, v5, zero 

    // Calc Row 0
    vsetivli zero, 8, e8, m1, ta, ma
    vwmulu.vv   v16, v0, v28
    vwmaccu.vv  v16, v29, v2
    vwmulu.vv   v18, v1, v28
    vwmaccu.vv  v18, v29, v3

    vnclipu.wi  v24, v16, 6
    vnclipu.wi  v25, v18, 6
    vse8.v      v24, (a0)
    add         a0, a0, a2
    vse8.v      v25, (a1)
    add         a1, a1, a2

    // Calc Row 1
    vwmulu.vv   v16, v4, v28
    vwmaccu.vv  v16, v29, v6
    vwmulu.vv   v18, v5, v28
    vwmaccu.vv  v18, v29, v7

    vnclipu.wi  v24, v16, 6
    vnclipu.wi  v25, v18, 6
    vse8.v      v24, (a0)
    add         a0, a0, a2
    vse8.v      v25, (a1)
    add         a1, a1, a2

    vsetivli zero, 9, e8, m1, ta, ma
    bgtz    t6, 5b
    ret
endfunc

// void mc_copy( uint8_t *dst, intptr_t dst_stride, uint8_t *src, intptr_t src_stride, int height )
function mc_copy_w4_rvv, export=1
    vsetivli    zero, 4, e8, mf4, ta, ma
1:
    addi        a4, a4, -4
    vle8.v      v0, (a2)
    add         a2, a2, a3
    vle8.v      v1, (a2)
    add         a2, a2, a3
    vle8.v      v2, (a2)
    add         a2, a2, a3
    vle8.v      v3, (a2)
    add         a2, a2, a3
    vse8.v      v0, (a0)
    add         a0, a0, a1
    vse8.v      v1, (a0)
    add         a0, a0, a1
    vse8.v      v2, (a0)
    add         a0, a0, a1
    vse8.v      v3, (a0)
    add         a0, a0, a1
    bgtz        a4, 1b
    ret
endfunc

function mc_copy_w8_rvv, export=1
    vsetivli    zero, 8, e8, mf2, ta, ma
1:
    addi        a4, a4, -4
    vle8.v      v0, (a2)
    add         a2, a2, a3
    vle8.v      v1, (a2)
    add         a2, a2, a3
    vle8.v      v2, (a2)
    add         a2, a2, a3
    vle8.v      v3, (a2)
    add         a2, a2, a3
    vse8.v      v0, (a0)
    add         a0, a0, a1
    vse8.v      v1, (a0)
    add         a0, a0, a1
    vse8.v      v2, (a0)
    add         a0, a0, a1
    vse8.v      v3, (a0)
    add         a0, a0, a1
    bgtz        a4, 1b
    ret
endfunc

function mc_copy_w16_rvv, export=1
    vsetivli    zero, 16, e8, m1, ta, ma
1:
    addi        a4, a4, -4
    vle8.v      v0, (a2)
    add         a2, a2, a3
    vle8.v      v1, (a2)
    add         a2, a2, a3
    vle8.v      v2, (a2)
    add         a2, a2, a3
    vle8.v      v3, (a2)
    add         a2, a2, a3
    vse8.v      v0, (a0)
    add         a0, a0, a1
    vse8.v      v1, (a0)
    add         a0, a0, a1
    vse8.v      v2, (a0)
    add         a0, a0, a1
    vse8.v      v3, (a0)
    add         a0, a0, a1
    bgtz        a4, 1b
    ret
endfunc

function frame_init_lowres_core_rvv, export=1
    ld          t0, 0(sp)              // height
    csrwi       vxrm, 0
    sub         t1, a6, a7             // dst_stride - width
    andi        t1, t1, -16            // align to 16 bytes
    li          t6, 32
    vsetvli     zero, t6, e8, m2, ta, ma
    vid.v       v16                    // generate indices [0..31]
    vsll.vi     v12, v16, 1            // even indices [0,2,4,...]
    vadd.vi     v14, v12, 1            // odd indices [1,3,5,...]
1:  // outer loop: process each row
    mv          t2, a7
    mv          t3, a0                 // src0
    add         t4, a0, a5             // src1 = src0 + stride
    slli        t5, a5, 1
    add         t5, a0, t5             // src2 = src0 + 2*stride
    vsetvli    zero, t6, e8, m2, ta, ma
    vle8.v      v10, (t3)              // load src0[0:31]
    vle8.v      v26, (t4)              // load src1[0:31]
    vle8.v      v28, (t5)              // load src2[0:31]
    vrgather.vv v0, v10, v12           // extract even pixels from src0
    vrgather.vv v6, v10, v14           // extract odd pixels from src0
    vrgather.vv v2, v26, v12           // extract even pixels from src1
    vrgather.vv v8, v26, v14           // extract odd pixels from src1
    vrgather.vv v4, v28, v12           // extract even pixels from src2
    vrgather.vv v10, v28, v14          // extract odd pixels from src2
    addi        t3, t3, 32
    addi        t4, t4, 32
    addi        t5, t5, 32

    vsetivli    zero, 16, e8, m1, ta, ma
    vaaddu.vv   v20, v0, v2            // avg(src0_even, src1_even)
    vaaddu.vv   v22, v2, v4            // avg(src1_even, src2_even)

2:  // inner loop: process 16 output pixels
    addi        t2, t2, -16
    vaaddu.vv   v21, v6, v8            // avg(src0_odd, src1_odd)
    vaaddu.vv   v23, v8, v10           // avg(src1_odd, src2_odd)
    vsetvli zero, t6, e8, m2, ta, ma
    vle8.v      v10, (t3)              // prefetch next src0
    vle8.v      v26, (t4)              // prefetch next src1
    vle8.v      v28, (t5)              // prefetch next src2
    vrgather.vv v0, v10, v12
    vrgather.vv v6, v10, v14
    vrgather.vv v2, v26, v12
    vrgather.vv v8, v26, v14
    vrgather.vv v4, v28, v12
    vrgather.vv v10, v28, v14
    addi        t3, t3, 32
    addi        t4, t4, 32
    addi        t5, t5, 32
    vsetivli    zero, 16, e8, m1, ta, ma
    vaaddu.vv   v30, v0, v2            // next: avg(src0_even, src1_even)
    vaaddu.vv   v31, v2, v4            // next: avg(src1_even, src2_even)

    vslidedown.vi v24, v20, 1
    vslideup.vi  v24, v30, 15
    vslidedown.vi v25, v22, 1
    vslideup.vi  v25, v31, 15

    vaaddu.vv   v16, v20, v21          // dst0
    vaaddu.vv   v18, v22, v23          // dstv
    vaaddu.vv   v17, v21, v24          // dsth
    vaaddu.vv   v19, v23, v25          // dstc
    vse8.v      v16, (a1)              // store dst0
    vse8.v      v18, (a3)              // store dstv
    vse8.v      v17, (a2)              // store dsth
    vse8.v      v19, (a4)              // store dstc
    addi        a1, a1, 16
    addi        a3, a3, 16
    addi        a2, a2, 16
    addi        a4, a4, 16

    blez        t2, 3f

    addi        t2, t2, -16
    vaaddu.vv   v21, v6, v8
    vaaddu.vv   v23, v8, v10

    vsetvli zero, t6, e8, m2, ta, ma
    vle8.v      v10, (t3)
    vle8.v      v26, (t4)
    vle8.v      v28, (t5)
    vrgather.vv v0, v10, v12
    vrgather.vv v6, v10, v14
    vrgather.vv v2, v26, v12
    vrgather.vv v8, v26, v14
    vrgather.vv v4, v28, v12
    vrgather.vv v10, v28, v14
    addi        t3, t3, 32
    addi        t4, t4, 32
    addi        t5, t5, 32
    vsetivli    zero, 16, e8, m1, ta, ma
    vaaddu.vv   v20, v0, v2
    vaaddu.vv   v22, v2, v4

    vslidedown.vi v24, v30, 1
    vslideup.vi  v24, v20, 15
    vslidedown.vi v25, v31, 1
    vslideup.vi  v25, v22, 15

    vaaddu.vv   v16, v30, v21
    vaaddu.vv   v18, v31, v23
    vaaddu.vv   v17, v21, v24
    vaaddu.vv   v19, v23, v25

    vse8.v      v16, (a1)
    vse8.v      v18, (a3)
    vse8.v      v17, (a2)
    vse8.v      v19, (a4)
    addi        a1, a1, 16
    addi        a3, a3, 16
    addi        a2, a2, 16
    addi        a4, a4, 16

    bgtz        t2, 2b
3:  // end of row
    addi        t0, t0, -1
    slli        t5, a5, 1
    add         a0, a0, t5             // src0 += 2*stride
    add         a1, a1, t1             // advance output pointers
    add         a2, a2, t1
    add         a3, a3, t1
    add         a4, a4, t1
    bgtz        t0, 1b

    ret
endfunc

#endif // BIT_DEPTH == 8

