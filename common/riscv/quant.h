/*****************************************************************************
 * quant.h: riscv quantization and level-run
 *****************************************************************************
 * Copyright (C) 2005-2024 x264 project
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

#ifndef X264_RISCV_QUANT_H
#define X264_RISCV_QUANT_H

#define x264_quant_2x2_dc_riscv x264_template(quant_2x2_dc_riscv)
int x264_quant_2x2_dc_riscv( int16_t dct[4], int mf, int bias );

#define x264_quant_2x2_dc_rvv x264_template(quant_2x2_dc_rvv)
int x264_quant_2x2_dc_rvv( dctcoef dct[4], int mf, int bias );
#define x264_quant_4x4_dc_rvv x264_template(quant_4x4_dc_rvv)
int x264_quant_4x4_dc_rvv( dctcoef dct[16], int mf, int bias );
#define x264_quant_4x4_rvv x264_template(quant_4x4_rvv)
int x264_quant_4x4_rvv( dctcoef dct[16], udctcoef mf[16], udctcoef bias[16] );
#define x264_quant_4x4x4_rvv x264_template(quant_4x4x4_rvv)
int x264_quant_4x4x4_rvv( dctcoef dct[4][16], udctcoef mf[16], udctcoef bias[16] );
#define x264_quant_8x8_rvv x264_template(quant_8x8_rvv)
int x264_quant_8x8_rvv( dctcoef dct[64], udctcoef mf[64], udctcoef bias[64] );

#define x264_dequant_4x4_dc_rvv x264_template(dequant_4x4_dc_rvv)
void x264_dequant_4x4_dc_rvv( dctcoef dct[16], int dequant_mf[6][16], int i_qp );
#define x264_dequant_4x4_rvv x264_template(dequant_4x4_rvv)
void x264_dequant_4x4_rvv( dctcoef dct[16], int dequant_mf[6][16], int i_qp );
#define x264_dequant_8x8_rvv x264_template(dequant_8x8_rvv)
void x264_dequant_8x8_rvv( dctcoef dct[64], int dequant_mf[6][64], int i_qp );

#define x264_decimate_score15_rvv x264_template(decimate_score15_rvv)
int x264_decimate_score15_rvv( dctcoef * );
#define x264_decimate_score16_rvv x264_template(decimate_score16_rvv)
int x264_decimate_score16_rvv( dctcoef * );
#define x264_decimate_score64_rvv x264_template(decimate_score64_rvv)
int x264_decimate_score64_rvv( dctcoef * );

// BIT DEPTH = 8
#define x264_coeff_last4_riscv x264_template(coeff_last4_riscv)
int x264_coeff_last4_riscv( dctcoef * );
#define x264_coeff_last8_riscv x264_template(coeff_last8_riscv)
int x264_coeff_last8_riscv( dctcoef * );

// BIT DEPTH = 10
#define x264_coeff_last4_rvv x264_template(coeff_last4_rvv)
int x264_coeff_last4_rvv( dctcoef * );
#define x264_coeff_last8_rvv x264_template(coeff_last8_rvv)
int x264_coeff_last8_rvv( dctcoef * );

#define x264_coeff_last15_rvv x264_template(coeff_last15_rvv)
int x264_coeff_last15_rvv( dctcoef * );
#define x264_coeff_last16_rvv x264_template(coeff_last16_rvv)
int x264_coeff_last16_rvv( dctcoef * );
#define x264_coeff_last64_rvv x264_template(coeff_last64_rvv)
int x264_coeff_last64_rvv( dctcoef * );

// BIT_DEPTH = 8
#define x264_coeff_level_run4_riscv x264_template(coeff_level_run4_riscv)
int x264_coeff_level_run4_riscv( dctcoef *, x264_run_level_t * );

// BIT_DEPTH = 10
#define x264_coeff_level_run4_rvv x264_template(coeff_level_run4_rvv)
int x264_coeff_level_run4_rvv( dctcoef *, x264_run_level_t * );

#define x264_coeff_level_run8_rvv x264_template(coeff_level_run8_rvv)
int x264_coeff_level_run8_rvv( dctcoef *, x264_run_level_t * );
#define x264_coeff_level_run15_rvv x264_template(coeff_level_run15_rvv)
int x264_coeff_level_run15_rvv( dctcoef *, x264_run_level_t * );
#define x264_coeff_level_run16_rvv x264_template(coeff_level_run16_rvv)
int x264_coeff_level_run16_rvv( dctcoef *, x264_run_level_t * );

#define x264_denoise_dct_rvv x264_template(denoise_dct_rvv)
void x264_denoise_dct_rvv( dctcoef *, uint32_t *, udctcoef *, int );

#endif
