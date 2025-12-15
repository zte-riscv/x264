/*****************************************************************************
 * mc.h: riscv mc metrics
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

#ifndef X264_RISCV_MC_H
#define X264_RISCV_MC_H


#define x264_pixel_avg_16x16_rvv x264_template(pixel_avg_16x16_rvv)
void x264_pixel_avg_16x16_rvv( pixel *, intptr_t, pixel *, intptr_t, pixel *, intptr_t, int );
#define x264_pixel_avg_16x8_rvv x264_template(pixel_avg_16x8_rvv)
void x264_pixel_avg_16x8_rvv ( pixel *, intptr_t, pixel *, intptr_t, pixel *, intptr_t, int );
#define x264_pixel_avg_8x16_rvv x264_template(pixel_avg_8x16_rvv)
void x264_pixel_avg_8x16_rvv ( pixel *, intptr_t, pixel *, intptr_t, pixel *, intptr_t, int );
#define x264_pixel_avg_8x8_rvv x264_template(pixel_avg_8x8_rvv)
void x264_pixel_avg_8x8_rvv  ( pixel *, intptr_t, pixel *, intptr_t, pixel *, intptr_t, int );
#define x264_pixel_avg_8x4_rvv x264_template(pixel_avg_8x4_rvv)
void x264_pixel_avg_8x4_rvv  ( pixel *, intptr_t, pixel *, intptr_t, pixel *, intptr_t, int );
#define x264_pixel_avg_4x16_rvv x264_template(pixel_avg_4x16_rvv)
void x264_pixel_avg_4x16_rvv ( pixel *, intptr_t, pixel *, intptr_t, pixel *, intptr_t, int );
#define x264_pixel_avg_4x8_rvv x264_template(pixel_avg_4x8_rvv)
void x264_pixel_avg_4x8_rvv  ( pixel *, intptr_t, pixel *, intptr_t, pixel *, intptr_t, int );
#define x264_pixel_avg_4x4_rvv x264_template(pixel_avg_4x4_rvv)
void x264_pixel_avg_4x4_rvv  ( pixel *, intptr_t, pixel *, intptr_t, pixel *, intptr_t, int );
#define x264_pixel_avg_4x2_rvv x264_template(pixel_avg_4x2_rvv)
void x264_pixel_avg_4x2_rvv  ( pixel *, intptr_t, pixel *, intptr_t, pixel *, intptr_t, int );


#define x264_pixel_avg2_w4_rvv x264_template(pixel_avg2_w4_rvv)
void x264_pixel_avg2_w4_rvv ( pixel *, intptr_t, pixel *, intptr_t, pixel *, int );
#define x264_pixel_avg2_w8_rvv x264_template(pixel_avg2_w8_rvv)
void x264_pixel_avg2_w8_rvv ( pixel *, intptr_t, pixel *, intptr_t, pixel *, int );
#define x264_pixel_avg2_w16_rvv x264_template(pixel_avg2_w16_rvv)
void x264_pixel_avg2_w16_rvv( pixel *, intptr_t, pixel *, intptr_t, pixel *, int );
#define x264_pixel_avg2_w20_rvv x264_template(pixel_avg2_w20_rvv)
void x264_pixel_avg2_w20_rvv( pixel *, intptr_t, pixel *, intptr_t, pixel *, int );


#define x264_mc_init_rvv x264_template(mc_init_rvv)
void x264_mc_init_rvv( uint32_t cpu, x264_mc_functions_t *pf );



#endif
