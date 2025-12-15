/*****************************************************************************
 * deblock.h: riscv deblocking
 *****************************************************************************
 * Copyright (C) 2017-2024 x264 project
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

#ifndef X264_RISCV_DEBLOCK_H
#define X264_RISCV_DEBLOCK_H

#define x264_deblock_v_luma_rvv x264_template(deblock_v_luma_rvv)
void x264_deblock_v_luma_rvv  ( uint8_t *pix, intptr_t stride, int alpha, int beta, int8_t *tc0 );
// #define x264_deblock_h_luma_rvv x264_template(deblock_h_luma_rvv)
// void x264_deblock_h_luma_rvv  ( uint8_t *pix, intptr_t stride, int alpha, int beta, int8_t *tc0 );
#define x264_deblock_v_chroma_rvv x264_template(deblock_v_chroma_rvv)
void x264_deblock_v_chroma_rvv( uint8_t *pix, intptr_t stride, int alpha, int beta, int8_t *tc0 );
// #define x264_deblock_h_chroma_rvv x264_template(deblock_h_chroma_rvv)
// void x264_deblock_h_chroma_rvv( uint8_t *pix, intptr_t stride, int alpha, int beta, int8_t *tc0 );
#define x264_deblock_strength_rvv x264_template(deblock_strength_rvv)
void x264_deblock_strength_rvv( uint8_t nnz[X264_SCAN8_SIZE], int8_t ref[2][X264_SCAN8_LUMA_SIZE],
                                 int16_t mv[2][X264_SCAN8_LUMA_SIZE][2], uint8_t bs[2][8][4],
                                 int mvy_limit, int bframe );
// #define x264_deblock_h_chroma_422_rvv x264_template(deblock_h_chroma_422_rvv)
// void x264_deblock_h_chroma_422_rvv( uint8_t *pix, intptr_t stride, int alpha, int beta, int8_t *tc0 );
// #define x264_deblock_h_chroma_mbaff_rvv x264_template(deblock_h_chroma_mbaff_rvv)
// void x264_deblock_h_chroma_mbaff_rvv( uint8_t *pix, intptr_t stride, int alpha, int beta, int8_t *tc0 );
// #define x264_deblock_h_chroma_intra_mbaff_rvv x264_template(deblock_h_chroma_intra_mbaff_rvv)
// void x264_deblock_h_chroma_intra_mbaff_rvv( uint8_t *pix, intptr_t stride, int alpha, int beta );
// #define x264_deblock_h_chroma_intra_rvv x264_template(deblock_h_chroma_intra_rvv)
// void x264_deblock_h_chroma_intra_rvv( uint8_t *pix, intptr_t stride, int alpha, int beta );
// #define x264_deblock_h_chroma_422_intra_rvv x264_template(deblock_h_chroma_422_intra_rvv)
// void x264_deblock_h_chroma_422_intra_rvv( uint8_t *pix, intptr_t stride, int alpha, int beta );
#define x264_deblock_v_chroma_intra_rvv x264_template(deblock_v_chroma_intra_rvv)
void x264_deblock_v_chroma_intra_rvv( uint8_t *pix, intptr_t stride, int alpha, int beta );
// #define x264_deblock_h_luma_intra_rvv x264_template(deblock_h_luma_intra_rvv)
// void x264_deblock_h_luma_intra_rvv( uint8_t *pix, intptr_t stride, int alpha, int beta );
#define x264_deblock_v_luma_intra_rvv x264_template(deblock_v_luma_intra_rvv)
void x264_deblock_v_luma_intra_rvv( uint8_t *pix, intptr_t stride, int alpha, int beta );

// #define x264_deblock_v_chroma_rvv x264_template(deblock_v_chroma_rvv)
// void x264_deblock_v_chroma_rvv( uint8_t *pix, intptr_t stride, int alpha, int beta, int8_t *tc0 );

#endif
