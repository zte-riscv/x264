/*****************************************************************************
 * predict.S: riscv intra prediction
 *****************************************************************************
 * Copyright (C) 2009-2024 x264 project
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


function predict_4x4_dc_rvv
    li          t0, 32
    addi        a1, a0, -1
    addi        a2, a0, -32
    vsetivli    zero, 4, e8, mf4, ta, ma
    vmv.v.i     v4, 0
    vlse8.v     v1, (a1), t0
    vle8.v      v2, (a2)
    vsetivli    zero, 8, e8, mf2, ta, ma
    vslideup.vi v2, v1, 4
    vwredsumu.vs v4, v2, v4
    csrwi vxrm, 0
    vnclipu.wi    v5, v4, 3
    vsetivli    zero, 16, e8, m1, ta, ma
    vrgather.vi    v6, v5, 0

    vsetivli    zero, 4, e32, m1, ta, ma
    vsse32.v    v6, (a0), t0
    ret
endfunc

function predict_4x4_dc_top_rvv
    li          t0, 32
    addi        a2, a0, -32
    vsetivli    zero, 4, e8, mf4, ta, ma
    vmv.v.i     v4, 0
    vle8.v      v2, (a2)
    vwredsumu.vs v4, v2, v4
    csrwi vxrm, 0
    vnclipu.wi   v5, v4, 2
    vsetivli    zero, 16, e8, m1, ta, ma
    vrgather.vi v6, v5, 0
    vsetivli    zero, 4, e32, m1, ta, ma
    vsse32.v    v6, (a0), t0
    ret
endfunc


function predict_4x4_dc_left_rvv
    li          t0, 32
    addi        a1, a0, -1
    vsetivli    zero, 4, e8, mf4, ta, ma
    vmv.v.i     v4, 0
    vlse8.v     v1, (a1), t0
    vwredsumu.vs v4, v1, v4
    csrwi vxrm, 0
    vnclipu.wi   v5, v4, 2
    vsetivli    zero, 16, e8, m1, ta, ma
    vrgather.vi v6, v5, 0
    vsetivli    zero, 4, e32, m1, ta, ma
    vsse32.v    v6, (a0), t0
    ret
endfunc

function predict_4x4_ddl_rvv
    addi        a1, a0, -32
    vsetivli    zero, 8, e8, mf2, ta, ma
    vle8.v      v1, (a1)     // 7 6 5 4 3 2 1 0
    vrgather.vi v4, v1, 7    // 7 7 7 7 7 7 7 7
    vslidedown.vi v2, v1, 1  // 0 7 6 5 4 3 2 1
    vslidedown.vi v3, v1, 2  // 0 0 7 6 5 4 3 2
    vslideup.vi   v3, v4, 6  // 7 7 7 6 5 4 3 2
    csrwi vxrm, 2
    vaaddu.vv v1, v1, v3
    csrwi vxrm, 0
    vaaddu.vv v1, v1, v2
    vslidedown.vi v2, v1, 1
    vslidedown.vi v3, v1, 2
    vslidedown.vi v4, v1, 3

    vsetivli    zero, 4, e8, mf4, ta, ma
    vse8.v      v1, (a0)
    addi        a1, a0, 32
    vse8.v      v2, (a1)
    addi        a2, a0, 64
    vse8.v      v3, (a2)
    addi        a3, a0, 96
    vse8.v      v4, (a3)
    ret
endfunc


function predict_4x4_ddr_rvv
    addi        a1, a0, -33
    lbu         t0, -1(a0) //l0
    lbu         t1, 31(a0) //l1
    lbu         t2, 63(a0) //l2
    lbu         t3, 95(a0) //l3
    vsetivli    zero, 8, e8, mf2, ta, ma
    vle8.v      v1, (a1)     //  x  x  x t3 t2 t1 t0 lt
    vslide1up.vx v2, v1, t0  //  x  x t3 t2 t1 t0 lt l0
    vslide1up.vx v3, v2, t1  //  x t3 t2 t1 t0 lt l0 l1
    vslide1up.vx v4, v3, t2  // t3 t2 t1 t0 lt l0 l1 l2
    vslide1up.vx v5, v4, t3  // t2 t1 t0 lt l0 l1 l2 l3
    csrwi vxrm, 2
    vaaddu.vv v1, v3, v5
    csrwi vxrm, 0
    vaaddu.vv v1, v1, v4
    vslidedown.vi v2, v1, 1
    vslidedown.vi v3, v1, 2
    vslidedown.vi v4, v1, 3

    addi        a1, a0, 96 
    addi        a2, a0, 64 
    addi        a3, a0, 32 
    vsetivli    zero, 4, e8, mf4, ta, ma
    vse8.v      v1, (a1)
    vse8.v      v2, (a2)
    vse8.v      v3, (a3)
    vse8.v      v4, (a0)
    ret
endfunc

function predict_8x8_ddl_rvv
    addi        a1, a1, 16
    vsetivli    zero, 16, e8, m1, ta, ma
    vle8.v      v1, (a1)     
    vrgather.vi v4, v1, 15   
    vslidedown.vi v2, v1, 1  
    vslidedown.vi v3, v1, 2  
    vslideup.vi   v3, v4, 14  
    csrwi vxrm, 2
    vaaddu.vv v1, v1, v3
    csrwi vxrm, 0
    vaaddu.vv v1, v1, v2
    vslidedown.vi v2, v1, 1
    vslidedown.vi v3, v1, 2
    vslidedown.vi v4, v1, 3
    vslidedown.vi v5, v1, 4
    vslidedown.vi v6, v1, 5
    vslidedown.vi v7, v1, 6
    vslidedown.vi v8, v1, 7

    vsetivli    zero, 8, e8, mf2, ta, ma
    addi        a1, a0, 32
    vse8.v      v1, (a0)
    addi        a2, a0, 64
    vse8.v      v2, (a1)
    addi        a3, a0, 96
    vse8.v      v3, (a2)
    addi        a4, a0, 128
    vse8.v      v4, (a3)
    addi        a5, a0, 160
    vse8.v      v5, (a4)
    addi        a6, a0, 192
    vse8.v      v6, (a5)
    addi        a7, a0, 224
    vse8.v      v7, (a6)
    vse8.v      v8, (a7)
    ret
endfunc

function predict_8x8_ddr_rvv
    addi        a2, a1, 7
    addi        a3, a1, 8
    vsetivli    zero, 16, e8, m1, ta, ma
    vle8.v      v2, (a3)
    vle8.v      v3, (a2)
    vslidedown.vi v1, v2, 1

    csrwi vxrm, 2
    vaaddu.vv v1, v1, v3
    csrwi vxrm, 0
    vaaddu.vv v1, v1, v2

    vslidedown.vi v2, v1, 1
    vslidedown.vi v3, v1, 2
    vslidedown.vi v4, v1, 3
    vslidedown.vi v5, v1, 4
    vslidedown.vi v6, v1, 5
    vslidedown.vi v7, v1, 6
    vslidedown.vi v8, v1, 7


    addi        a1, a0, 224 
    addi        a2, a0, 192 
    addi        a3, a0, 160 
    addi        a4, a0, 128 
    addi        a5, a0, 96 
    addi        a6, a0, 64 
    addi        a7, a0, 32 
    vsetivli    zero, 8, e8, mf2, ta, ma
    vse8.v      v1, (a1)
    vse8.v      v2, (a2)
    vse8.v      v3, (a3)
    vse8.v      v4, (a4)    
    vse8.v      v5, (a5)
    vse8.v      v6, (a6)
    vse8.v      v7, (a7)
    vse8.v      v8, (a0)
    ret
endfunc

function predict_8x8_vr_rvv
    addi        a3, a1, 8
    vsetivli    zero, 16, e8, m1, ta, ma
    vle8.v      v3, (a3)
    vslidedown.vi v1, v3, 2
    vslidedown.vi v2, v3, 1

    csrwi vxrm, 2
    vaaddu.vv v1, v1, v3
    csrwi vxrm, 0
    vaaddu.vv v1, v1, v2  // F2
    vaaddu.vv v2, v2, v3  // F1

    vsetivli    zero, 8, e8, mf2, ta, ma
    vnsrl.wi    v7, v1, 0
    vnsrl.wi    v6, v1, 8

    vsetivli    zero, 16, e8, m1, ta, ma
    vslidedown.vi v9, v1, 6
    vslidedown.vi v10, v2, 7
    vslideup.vi v7, v9, 3  // 7 5 3 1
    vslideup.vi v6, v10, 3  // 6 4 2 0

    vslidedown.vi v5, v7, 1
    vslidedown.vi v3, v7, 2

    vslidedown.vi v4, v6, 1
    vslidedown.vi v2, v6, 2

    addi        a7, a0, 224 
    addi        a6, a0, 192 
    addi        a5, a0, 160 
    addi        a4, a0, 128 
    addi        a3, a0, 96 
    addi        a2, a0, 64 
    addi        a1, a0, 32 
    vsetivli    zero, 8, e8, mf2, ta, ma
    vse8.v      v7, (a7)
    vse8.v      v6, (a6)
    vse8.v      v5, (a5)
    vse8.v      v4, (a4)    
    vse8.v      v3, (a3)
    vse8.v      v2, (a2)
    vse8.v      v9, (a1)
    vse8.v      v10, (a0)
    ret
endfunc

function predict_8x8_vl_rvv
    addi        a3, a1, 16
    vsetivli    zero, 16, e8, m1, ta, ma
    vle8.v      v3, (a3)
    vslidedown.vi v1, v3, 2
    vslidedown.vi v2, v3, 1

    csrwi vxrm, 2
    vaaddu.vv v1, v1, v3
    csrwi vxrm, 0
    vaaddu.vv v1, v1, v2  // F2
    vaaddu.vv v0, v2, v3  // F1

    vslidedown.vi v3, v1, 1
    vslidedown.vi v5, v1, 2
    vslidedown.vi v7, v1, 3

    vslidedown.vi v2, v0, 1
    vslidedown.vi v4, v0, 2
    vslidedown.vi v6, v0, 3

    addi        a7, a0, 224 
    addi        a6, a0, 192 
    addi        a5, a0, 160 
    addi        a4, a0, 128 
    addi        a3, a0, 96 
    addi        a2, a0, 64 
    addi        a1, a0, 32 
    vsetivli    zero, 8, e8, mf2, ta, ma
    vse8.v      v7, (a7)
    vse8.v      v6, (a6)
    vse8.v      v5, (a5)
    vse8.v      v4, (a4)    
    vse8.v      v3, (a3)
    vse8.v      v2, (a2)
    vse8.v      v1, (a1)
    vse8.v      v0, (a0)
    ret
endfunc


function predict_8x8_dc_rvv
    addi        a2, a1, 16
    addi        a1, a1, 7
    vsetivli    zero, 8, e8, mf2, ta, ma
    vmv.v.i     v4, 0
    vle8.v      v2, (a2)
    vle8.v      v1, (a1)
    vwredsumu.vs v4, v1, v4
    vwredsumu.vs v4, v2, v4
    csrwi vxrm, 0
    vnclipu.wi   v5, v4, 4

    vrgather.vi    v6, v5, 0
    addi        a7, a0, 224 
    addi        a6, a0, 192 
    addi        a5, a0, 160 
    addi        a4, a0, 128 
    addi        a3, a0, 96 
    addi        a2, a0, 64 
    addi        a1, a0, 32     
    vse8.v      v6, (a7)
    vse8.v      v6, (a6)
    vse8.v      v6, (a5)
    vse8.v      v6, (a4)    
    vse8.v      v6, (a3)
    vse8.v      v6, (a2)
    vse8.v      v6, (a1)
    vse8.v      v6, (a0)
    ret
endfunc

function predict_8x8_h_rvv
    addi        a3, a1, 7
    vsetivli    zero, 8, e8, mf2, ta, ma
    vle8.v      v9, (a3)      // 0 1 2 3 4 5 6 7
    addi        a1, a0, 32 
    addi        a2, a0, 64   
    addi        a3, a0, 96   
    addi        a4, a0, 128 
    addi        a5, a0, 160 
    addi        a6, a0, 192 
    addi        a7, a0, 224 

    vrgather.vi v0, v9, 7
    vrgather.vi v1, v9, 6
    vse8.v      v0, (a0)
    vrgather.vi v2, v9, 5
    vse8.v      v1, (a1)
    vrgather.vi v3, v9, 4
    vse8.v      v2, (a2)
    vrgather.vi v4, v9, 3
    vse8.v      v3, (a3)
    vrgather.vi v5, v9, 2
    vse8.v      v4, (a4)
    vrgather.vi v6, v9, 1
    vse8.v      v5, (a5)
    vrgather.vi v7, v9, 0
    vse8.v      v6, (a6)
    vse8.v      v7, (a7)
    
    ret
endfunc

function predict_8x8c_dc_top_rvv
    addi        a2, a0, -32   
    vsetivli    zero, 8, e8, mf2, ta, ma
    vmv.v.i     v2, 0
    vmv.v.i     v3, 0
    vle8.v      v0, (a2)
    vslidedown.vi  v1, v0, 4
    vsetivli    zero, 4, e8, mf4, ta, ma
    vwredsumu.vs v2, v0, v2
    vwredsumu.vs v3, v1, v3
    csrwi vxrm, 0
    vnclipu.wi   v4, v2, 2
    vnclipu.wi   v5, v3, 2
    vrgather.vi  v0, v4, 0
    vrgather.vi  v1, v5, 0
    vsetivli    zero, 8, e8, mf2, ta, ma
    vslideup.vi  v0, v1, 4
    .rept 8
        vse8.v    v0, (a0)
        addi      a0, a0, 32
    .endr
    ret
endfunc

function predict_8x8c_dc_left_rvv
    li          t0, 32
    addi        a2, a0, -1   
    vsetivli    zero, 8, e8, mf2, ta, ma
    vmv.v.i     v2, 0
    vmv.v.i     v3, 0
    vlse8.v     v0, (a2), t0
    vslidedown.vi  v1, v0, 4
    vsetivli    zero, 4, e8, mf4, ta, ma
    vwredsumu.vs v2, v0, v2
    vwredsumu.vs v3, v1, v3
    csrwi vxrm, 0
    vnclipu.wi   v4, v2, 2
    vnclipu.wi   v5, v3, 2
    vsetivli    zero, 8, e8, mf2, ta, ma
    vrgather.vi  v0, v4, 0
    vrgather.vi  v1, v5, 0
.rept 4
    vse8.v    v0, (a0)
    addi      a0, a0, 32
.endr
.rept 4
    vse8.v    v1, (a0)
    addi      a0, a0, 32
.endr
    ret
endfunc

function predict_8x8c_dc_rvv
    li          t0, 32
    addi        a1, a0, -32   
    addi        a2, a0, -1   
    vsetivli    zero, 8, e8, mf2, ta, ma
    vmv.v.i     v4, 0
    vmv.v.i     v5, 0
    vmv.v.i     v6, 0
    vmv.v.i     v7, 0
    vle8.v      v0, (a1)       // s0
    vslidedown.vi  v1, v0, 4   // s1
    vlse8.v     v2, (a2), t0   // s2
    vslidedown.vi  v3, v2, 4   // s3
    vsetivli    zero, 4, e8, mf4, ta, ma
    vwredsumu.vs v4, v0, v4
    vwredsumu.vs v4, v2, v4   // dc0
    vwredsumu.vs v5, v1, v5   // dc1
    vwredsumu.vs v6, v3, v6   // dc2
    vwredsumu.vs v7, v3, v5   // dc3
    csrwi vxrm, 0
    vnclipu.wi   v8, v4, 3
    vnclipu.wi   v9, v5, 2
    vnclipu.wi   v10, v6, 2
    vnclipu.wi   v11, v7, 3
    vrgather.vi  v0, v8, 0
    vrgather.vi  v1, v9, 0
    vrgather.vi  v2, v10, 0
    vrgather.vi  v3, v11, 0
    vsetivli    zero, 8, e8, mf2, ta, ma
    vslideup.vi  v0, v1, 4
    vslideup.vi  v2, v3, 4
.rept 4
    vse8.v    v0, (a0)
    addi      a0, a0, 32
.endr
.rept 4
    vse8.v    v2, (a0)
    addi      a0, a0, 32
.endr
    ret
endfunc

function predict_8x8c_h_rvv
    li          t0, 32
    addi        a1, a0, -1
    vsetivli    zero, 8, e8, mf2, ta, ma
    vlse8.v     v5, (a1), t0
    addi        a1, a0, 32

    vrgather.vi v0, v5, 0
    vrgather.vi v1, v5, 1
    vse8.v      v0, (a0)
    vse8.v      v1, (a1)
    addi        a0, a0, 64
    addi        a1, a1, 64
    vrgather.vi v0, v5, 2
    vrgather.vi v1, v5, 3
    vse8.v      v0, (a0)
    vse8.v      v1, (a1)
    addi        a0, a0, 64
    addi        a1, a1, 64
    vrgather.vi v0, v5, 4
    vrgather.vi v1, v5, 5
    vse8.v      v0, (a0)
    vse8.v      v1, (a1)
    addi        a0, a0, 64
    addi        a1, a1, 64
    vrgather.vi v0, v5, 6
    vrgather.vi v1, v5, 7
    vse8.v      v0, (a0)
    vse8.v      v1, (a1)

    ret
endfunc

function predict_8x16c_dc_top_rvv
    addi        a2, a0, -32   
    vsetivli    zero, 8, e8, mf2, ta, ma
    vmv.v.i     v2, 0
    vmv.v.i     v3, 0
    vle8.v      v0, (a2)
    vslidedown.vi  v1, v0, 4
    vsetivli    zero, 4, e8, mf4, ta, ma
    vwredsumu.vs v2, v0, v2
    vwredsumu.vs v3, v1, v3
    csrwi vxrm, 0
    vnclipu.wi   v4, v2, 2
    vnclipu.wi   v5, v3, 2
    vrgather.vi  v0, v4, 0
    vrgather.vi  v1, v5, 0
    vsetivli    zero, 8, e8, mf2, ta, ma
    vslideup.vi  v0, v1, 4
    .rept 16
        vse8.v    v0, (a0)
        addi      a0, a0, 32
    .endr
    ret
endfunc

function predict_8x16c_dc_left_rvv
    li          t0, 32
    addi        a2, a0, -1   
    vsetivli    zero, 16, e8, m1, ta, ma
    vlse8.v     v0, (a2), t0
    vmv.v.i     v4, 0
    vmv.v.i     v5, 0
    vmv.v.i     v6, 0
    vmv.v.i     v7, 0
    vslidedown.vi  v1, v0, 4
    vslidedown.vi  v2, v0, 8
    vslidedown.vi  v3, v0, 12
    vsetivli    zero, 4, e8, mf4, ta, ma
    vwredsumu.vs v4, v0, v4
    vwredsumu.vs v5, v1, v5
    vwredsumu.vs v6, v2, v6
    vwredsumu.vs v7, v3, v7
    csrwi vxrm, 0
    vnclipu.wi   v8, v4, 2
    vnclipu.wi   v9, v5, 2
    vnclipu.wi   v10, v6, 2
    vnclipu.wi   v11, v7, 2
    vsetivli    zero, 8, e8, mf2, ta, ma
    vrgather.vi  v0, v8, 0
    vrgather.vi  v1, v9, 0
    vrgather.vi  v2, v10, 0
    vrgather.vi  v3, v11, 0
.rept 4
    vse8.v    v0, (a0)
    addi      a0, a0, 32
.endr
.rept 4
    vse8.v    v1, (a0)
    addi      a0, a0, 32
.endr
.rept 4
    vse8.v    v2, (a0)
    addi      a0, a0, 32
.endr
.rept 4
    vse8.v    v3, (a0)
    addi      a0, a0, 32
.endr
    ret
endfunc

function predict_8x16c_dc_rvv
    li          t0, 32
    addi        a1, a0, -32   
    addi        a2, a0, -1   
    vsetivli    zero, 16, e8, m1, ta, ma   
    vmv.v.i     v8, 0
    vmv.v.i     v9, 0
    vmv.v.i     v10, 0
    vmv.v.i     v12, 0
    vmv.v.i     v14, 0
    vle8.v      v0, (a1)       // s0
    vslidedown.vi  v1, v0, 4   // s1
    vlse8.v     v2, (a2), t0   // s2
    vslidedown.vi  v3, v2, 4   // s3
    vslidedown.vi  v4, v2, 8   // s4
    vslidedown.vi  v5, v2, 12  // s5
    vsetivli    zero, 4, e8, mf4, ta, ma
    vwredsumu.vs v8, v0, v8
    vwredsumu.vs v8 , v2, v8   // dc0
    vwredsumu.vs v9 , v1, v9   // dc1
    vwredsumu.vs v10, v3, v10   // dc2
    vwredsumu.vs v11, v3, v9   // dc3
    vwredsumu.vs v12, v4, v12   // dc4
    vwredsumu.vs v13, v4, v9   // dc5
    vwredsumu.vs v14, v5, v14   // dc6
    vwredsumu.vs v15, v5, v9   // dc7
    csrwi vxrm, 0
    vnclipu.wi   v0, v8 , 3
    vnclipu.wi   v1, v9 , 2
    vnclipu.wi   v2, v10, 2
    vnclipu.wi   v3, v11, 3
    vnclipu.wi   v4, v12, 2
    vnclipu.wi   v5, v13, 3
    vnclipu.wi   v6, v14,  2
    vnclipu.wi   v7, v15,  3
    vrgather.vi  v8 , v0, 0
    vrgather.vi  v9 , v1, 0
    vrgather.vi  v10, v2, 0
    vrgather.vi  v11, v3, 0
    vrgather.vi  v12, v4, 0
    vrgather.vi  v13, v5, 0
    vrgather.vi  v14, v6, 0
    vrgather.vi  v15, v7, 0
    vsetivli    zero, 8, e8, mf2, ta, ma
    vslideup.vi  v8, v9, 4
    vslideup.vi  v10, v11, 4
    vslideup.vi  v12, v13, 4
    vslideup.vi  v14, v15, 4
.rept 4
    vse8.v    v8, (a0)
    addi      a0, a0, 32
.endr
.rept 4
    vse8.v    v10, (a0)
    addi      a0, a0, 32
.endr
.rept 4
    vse8.v    v12, (a0)
    addi      a0, a0, 32
.endr
.rept 4
    vse8.v    v14, (a0)
    addi      a0, a0, 32
.endr
    ret
endfunc


function predict_8x16c_h_rvv
    li          t0, 32
    addi        a1, a0, -1
    vsetivli    zero, 16, e8, m1, ta, ma
    vlse8.v     v5, (a1), t0
    addi        a1, a0, 32

    vsetivli    zero, 8, e8, m1, ta, ma
    vrgather.vi v0, v5, 0
    vrgather.vi v1, v5, 1
    vse8.v      v0, (a0)
    vse8.v      v1, (a1)
    addi        a0, a0, 64
    addi        a1, a1, 64
    vrgather.vi v0, v5, 2
    vrgather.vi v1, v5, 3
    vse8.v      v0, (a0)
    vse8.v      v1, (a1)
    addi        a0, a0, 64
    addi        a1, a1, 64
    vrgather.vi v0, v5, 4
    vrgather.vi v1, v5, 5
    vse8.v      v0, (a0)
    vse8.v      v1, (a1)
    addi        a0, a0, 64
    addi        a1, a1, 64
    vrgather.vi v0, v5, 6
    vrgather.vi v1, v5, 7
    vse8.v      v0, (a0)
    vse8.v      v1, (a1)
    addi        a0, a0, 64
    addi        a1, a1, 64
    vrgather.vi v0, v5, 8
    vrgather.vi v1, v5, 9
    vse8.v      v0, (a0)
    vse8.v      v1, (a1)
    addi        a0, a0, 64
    addi        a1, a1, 64
    vrgather.vi v0, v5, 10
    vrgather.vi v1, v5, 11
    vse8.v      v0, (a0)
    vse8.v      v1, (a1)
    addi        a0, a0, 64
    addi        a1, a1, 64
    vrgather.vi v0, v5, 12
    vrgather.vi v1, v5, 13
    vse8.v      v0, (a0)
    vse8.v      v1, (a1)
    addi        a0, a0, 64
    addi        a1, a1, 64
    vrgather.vi v0, v5, 14
    vrgather.vi v1, v5, 15
    vse8.v      v0, (a0)
    vse8.v      v1, (a1)
    
    ret
endfunc

function predict_16x16_dc_rvv
    li          t0, 32
    addi        a2, a0, -32    
    addi        a3, a0, -1
    vsetivli    zero, 16, e8, m1, ta, ma
    vmv.v.i     v4, 0
    vle8.v      v2, (a2)
    vlse8.v     v3, (a3), t0
    vwredsumu.vs v4, v2, v4
    vwredsumu.vs v4, v3, v4
    vsetivli    zero, 8, e8, mf2, ta, ma
    csrwi vxrm, 0
    vnclipu.wi  v5, v4, 5
    vsetivli    zero, 16, e8, m1, ta, ma
    vrgather.vi v0, v5, 0
.rept 16
    vse8.v    v0, (a0)
    addi      a0, a0, 32
.endr

    ret
endfunc

function predict_16x16_dc_top_rvv
    addi        a2, a0, -32
    vsetivli    zero, 16, e8, m1, ta, ma
    vmv.v.i     v4, 0
    vle8.v      v2, (a2)
    vwredsumu.vs v4, v2, v4
    vsetivli    zero, 8, e8, mf2, ta, ma
    csrwi vxrm, 0
    vnclipu.wi  v5, v4, 4
    vsetivli    zero, 16, e8, m1, ta, ma
    vrgather.vi v0, v5, 0
.rept 16
    vse8.v    v0, (a0)
    addi      a0, a0, 32
.endr

    ret
endfunc

function predict_16x16_dc_left_rvv
    li          t0, 32
    addi        a2, a0, -1
    vsetivli    zero, 16, e8, m1, ta, ma
    vmv.v.i     v4, 0
    vlse8.v     v2, (a2), t0
    vwredsumu.vs v4, v2, v4
    vsetivli    zero, 8, e8, mf2, ta, ma
    csrwi vxrm, 0
    vnclipu.wi  v5, v4, 4
    vsetivli    zero, 16, e8, m1, ta, ma
    vrgather.vi v0, v5, 0
.rept 16
    vse8.v    v0, (a0)
    addi      a0, a0, 32
.endr

    ret
endfunc


function predict_16x16_v_rvv
    addi        a2, a0, -32
    vsetivli    zero, 16, e8, m1, ta, ma
    vle8.v      v0, (a2)

.rept 16
    vse8.v    v0, (a0)
    addi      a0, a0, 32
.endr

    ret
endfunc

function predict_16x16_h_rvv

    vsetivli    zero, 16, e8, m1, ta, ma
.rept 16
    lbu	        t0,-1(a0)
    vmv.v.x     v0, t0

    vse8.v    v0, (a0)
    addi      a0, a0, 32
.endr

    ret
endfunc