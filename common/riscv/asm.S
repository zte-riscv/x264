/*****************************************************************************
 * asm.S: riscv utility macros
 *****************************************************************************
 * Copyright (C) 2008-2024 x264 project
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

#include "config.h"

#define GLUE(a, b) a ## b
#define JOIN(a, b) GLUE(a, b)

#ifdef PREFIX
#   define BASE _x264_
#   define SYM_PREFIX _
#else
#   define BASE x264_
#   define SYM_PREFIX
#endif

#ifdef BIT_DEPTH
#   define EXTERN_ASM JOIN(JOIN(BASE, BIT_DEPTH), _)
#else
#   define EXTERN_ASM BASE
#endif

#define X(s) JOIN(EXTERN_ASM, s)
#define X264(s) JOIN(BASE, s)
#define EXT(s) JOIN(SYM_PREFIX, s)

#ifdef __ELF__
# define ELF
#else
# define ELF #
#endif

#ifdef __MACH__
#   define MACH
#else
#   define MACH #
#endif

#if HAVE_AS_FUNC
# define FUNC
#else
# define FUNC #
#endif

.macro function name, export=1
    .macro endfunc
.if \export
ELF     .size   EXTERN_ASM\name, . - EXTERN_ASM\name
.else
ELF     .size   \name, . - \name
.endif
FUNC    .endfunc
        .purgem endfunc
    .endm
        .text
        .align  2
.if \export == 1
        .global EXTERN_ASM\name
ELF     .hidden EXTERN_ASM\name
ELF     .type   EXTERN_ASM\name, %function
FUNC    .func   EXTERN_ASM\name
EXTERN_ASM\name:
.else
ELF     .hidden \name
ELF     .type   \name, %function
FUNC    .func   \name
\name:
.endif
.endm

.macro  const   name, align=2
    .macro endconst
ELF     .size   \name, . - \name
        .purgem endconst
    .endm
ELF     .section        .rodata
MACH    .const_data
        .align          \align
\name:
.endm

.macro movrel rd, val
    la \rd, \val
.endm

.macro movrelx rd, val, got
    #if defined(PIC) && defined(__ELF__)
        lla \got, _GLOBAL_OFFSET_TABLE_
        lla t0, \val
        add t0, t0, \got
        ld \rd, 0(t0)
    #elif defined(PIC) && defined(__APPLE__)
        lla t0, 1f
        ld t0, 0(t0)
        add t0, t0, t0
        ld \rd, 0(t0)
        j 2f
        .data
        1:
        .quad 3f - 1b
        .text
        2:
        .non_lazy_symbol_pointer
        3:
        .quad \val
        .text
    #else
        movrel \rd, \val
    #endif
.endm

.macro movconst rd, val
    lui \rd, %hi(\val)
    addi \rd, \rd, %lo(\val)
    lui t0, %hi(\val + 0x800)
    addi t0, t0, %lo(\val + 0x800)
    slli t0, t0, 32
    or \rd, \rd, t0
.endm

.macro SUMSUB_AB sum, diff, a, b
    vadd.vv \sum, \a, \b
    vsub.vv \diff, \a, \b
.endm

.macro SUMSUB_ABCD s1, d1, s2, d2, a, b, c, d
    SUMSUB_AB \s1, \d1, \a, \b
    SUMSUB_AB \s2, \d2, \c, \d
.endm

#define FENC_STRIDE 16
#define FDEC_STRIDE 32

# .macro TRANSPOSE4x4_16_spec buf, bstride, t1, t2, v0, v1, v2, v3
#     mv          \t1, \buf
#     vsse16.v    \v0, (\t1), \bstride
#     addi        \t1, \t1, 2
#     vsse16.v    \v1, (\t1), \bstride
#     addi        \t1, \t1, 2
#     vsse16.v    \v2, (\t1), \bstride
#     addi        \t1, \t1, 2
#     vsse16.v    \v3, (\t1), \bstride

#     vle16.v     \v0, (\buf)
#     add         \buf, \buf, \bstride
#     vle16.v     \v1, (\buf)
#     add         \buf, \buf, \bstride
#     vle16.v     \v2, (\buf)
#     add         \buf, \buf, \bstride
#     vle16.v     \v3, (\buf)
# .endm

.macro TRANSPOSE4x4_16 v0, v1, v2, v3
    addi sp,sp,-32
    vsseg4e16.v \v0, (sp)
    vle16.v \v0, (sp)
    addi sp,sp,8
    vle16.v \v1, (sp)
    addi sp,sp,8
    vle16.v \v2, (sp)
    addi sp,sp,8
    vle16.v \v3, (sp)
    addi sp,sp,8
.endm


.macro TRANSPOSE4x8_16 t_imm, v0, v1, v2, v3, t0, t1, t2, t3
    li \t_imm, 0xaa
    vmv.v.x v0, \t_imm
    vsetivli    zero, 4, e32, m1, ta, ma
    vmv.v.v \t0, \v0
    vslideup.vi  \t0, \v2, 1, v0.t // trn1
    vmv.v.v \t1, \v1
    vslideup.vi  \t1, \v3, 1, v0.t // trn1
    vmnot.m v0,v0
    vmv.v.v \t2, \v2
    vslidedown.vi  \t2, \v0, 1, v0.t // trn2
    vmv.v.v \t3, \v3
    vslidedown.vi  \t3, \v1, 1, v0.t // trn2

    vsetivli zero, 8, e16, m1, ta, ma
    vmv.v.x v0, \t_imm
    vmv.v.v \v0, \t0
    vslideup.vi  \v0, \t1, 1, v0.t // trn1
    vmv.v.v \v2, \t2
    vslideup.vi  \v2, \t3, 1, v0.t // trn1
    vmnot.m v0,v0
    vmv.v.v \v1, \t1
    vslidedown.vi  \v1, \t0, 1, v0.t // trn2
    vmv.v.v \v3, \t3
    vslidedown.vi  \v3, \t2, 1, v0.t // trn2
.endm

.macro TRANSPOSE4x16 vl, v0, v1, v2, v3, t0, t1, t2, t3, t4, t5, t6, t7
    vsetivli zero, 16, e8, m1, ta, ma
    vid.v       \t0
    vand.vi     \t1, \t0, 3
    vmul.vx     \t1, \t1, \vl
    vand.vi     \t0, \t0, -4

    vadd.vv     \t4, \t1, \t0
    vadd.vi     \t5, \t4, 1
    vadd.vi     \t6, \t4, 2
    vadd.vi     \t7, \t4, 3
    
    li          \vl, 64
    vsetvli zero, \vl, e8, m4, ta, ma
    vrgather.vv \t0, \v0, \t4
    vmv.v.v     \v0, \t0
.endm

.macro TRANSPOSE8x8_16 v0, v1, v2, v3, v4, v5, v6, v7
    addi sp,sp,-128
    mv   a6, sp
    vse16.v \v0, (sp)
    addi sp,sp,16
    vse16.v \v1, (sp)
    addi sp,sp,16
    vse16.v \v2, (sp)
    addi sp,sp,16
    vse16.v \v3, (sp)
    addi sp,sp,16
    vse16.v \v4, (sp)
    addi sp,sp,16
    vse16.v \v5, (sp)
    addi sp,sp,16
    vse16.v \v6, (sp)
    addi sp,sp,16
    vse16.v \v7, (sp)
    addi sp,sp,16
    vlseg8e16.v \v0, (a6)
//    addi sp,sp,-128
//    vsseg8e16.v \v0, (sp)
//    vle16.v \v0, (sp)
//    addi sp,sp,16
//    vle16.v \v1, (sp)
//    addi sp,sp,16
//    vle16.v \v2, (sp)
//    addi sp,sp,16
//    vle16.v \v3, (sp)
//    addi sp,sp,16
//    vle16.v \v4, (sp)
//    addi sp,sp,16
//    vle16.v \v5, (sp)
//    addi sp,sp,16
//    vle16.v \v6, (sp)
//    addi sp,sp,16
//    vle16.v \v7, (sp)
//    addi sp,sp,16
.endm

.macro TRANSPOSE8x16 buf, bstride, tmp, v0, v1, v2, v3, v4, v5, v6, v7, t0, t1, t2, t3, t4, t5, t6, t7
    mv          \tmp, \buf
    vsse8.v     \v0, (\tmp), \bstride
    addi        \tmp, \tmp, 1
    vsse8.v     \v1, (\tmp), \bstride
    addi        \tmp, \tmp, 1
    vsse8.v     \v2, (\tmp), \bstride
    addi        \tmp, \tmp, 1
    vsse8.v     \v3, (\tmp), \bstride
    addi        \tmp, \tmp, 1
    vsse8.v     \v4, (\tmp), \bstride
    addi        \tmp, \tmp, 1
    vsse8.v     \v5, (\tmp), \bstride
    addi        \tmp, \tmp, 1
    vsse8.v     \v6, (\tmp), \bstride
    addi        \tmp, \tmp, 1
    vsse8.v     \v7, (\tmp), \bstride
    
    vsetivli zero, 8, e8, mf2, tu, ma
    vle8.v \v0, (\buf)
    add \buf, \buf, \bstride
    vle8.v \v1, (\buf)
    add \buf, \buf, \bstride
    vle8.v \v2, (\buf)
    add \buf, \buf, \bstride
    vle8.v \v3, (\buf)
    add \buf, \buf, \bstride
    vle8.v \v4, (\buf)
    add \buf, \buf, \bstride
    vle8.v \v5, (\buf)
    add \buf, \buf, \bstride
    vle8.v \v6, (\buf)
    add \buf, \buf, \bstride
    vle8.v \v7, (\buf)
    add \buf, \buf, \bstride
    vle8.v \t0, (\buf)
    add \buf, \buf, \bstride
    vle8.v \t1, (\buf)
    add \buf, \buf, \bstride
    vle8.v \t2, (\buf)
    add \buf, \buf, \bstride
    vle8.v \t3, (\buf)
    add \buf, \buf, \bstride
    vle8.v \t4, (\buf)
    add \buf, \buf, \bstride
    vle8.v \t5, (\buf)
    add \buf, \buf, \bstride
    vle8.v \t6, (\buf)
    add \buf, \buf, \bstride
    vle8.v \t7, (\buf)
    add \buf, \buf, \bstride
    vsetivli zero, 2, e64, m1, tu, ma
    vslideup.vi \v0, \t0, 1
    vslideup.vi \v1, \t1, 1
    vslideup.vi \v2, \t2, 1
    vslideup.vi \v3, \t3, 1
    vslideup.vi \v4, \t4, 1
    vslideup.vi \v5, \t5, 1
    vslideup.vi \v6, \t6, 1
    vslideup.vi \v7, \t7, 1
    vsetivli zero, 16, e8, m1, tu, ma
.endm