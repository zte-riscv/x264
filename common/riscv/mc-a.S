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

    bnez      t1, 1b
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

    bnez      t1, 1b
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

    bnez      t1, 1b
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
    bnez      t1, 1b
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


    bnez      t1, 1b
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


    bnez      t1, 1b
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
    bnez      a5, 1b
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
    bnez      a5, 1b
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
    bnez      a5, 1b
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
    bnez      a5, 1b
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
    bnez      a5, 1b
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
    bnez      a5, 1b
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
    bnez      a5, 1b
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
    bnez      a5, 1b
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
    bnez      a5, 1b
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
    bnez      a5, 1b
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
    bnez      a5, 1b
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
    bnez      a5, 1b
    ret
endfunc

.endm

weight_simple offsetadd, vsaddu.vv
weight_simple offsetsub, vssubu.vv

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

#endif // BIT_DEPTH == 8

