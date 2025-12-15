/*****************************************************************************
 * predict.h: riscv predict metrics
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

#ifndef X264_RISCV_PREDICT_H
#define X264_RISCV_PREDICT_H


#define x264_predict_4x4_dc_rvv x264_template(predict_4x4_dc_rvv)
void x264_predict_4x4_dc_rvv( uint8_t *src );

#define x264_predict_4x4_dc_left_rvv x264_template(predict_4x4_dc_left_rvv)
void x264_predict_4x4_dc_left_rvv( uint8_t *src );
#define x264_predict_4x4_dc_top_rvv x264_template(predict_4x4_dc_top_rvv)
void x264_predict_4x4_dc_top_rvv( uint8_t *src );
#define x264_predict_4x4_ddl_rvv x264_template(predict_4x4_ddl_rvv)
void x264_predict_4x4_ddl_rvv( uint8_t *src );
#define x264_predict_4x4_ddr_rvv x264_template(predict_4x4_ddr_rvv)
void x264_predict_4x4_ddr_rvv( uint8_t *src );

#define x264_predict_8x8_ddl_rvv x264_template(predict_8x8_ddl_rvv)
void x264_predict_8x8_ddl_rvv( uint8_t *src, uint8_t edge[36] );
#define x264_predict_8x8_ddr_rvv x264_template(predict_8x8_ddr_rvv)
void x264_predict_8x8_ddr_rvv( uint8_t *src, uint8_t edge[36] );
#define x264_predict_8x8_vl_rvv x264_template(predict_8x8_vl_rvv)
void x264_predict_8x8_vl_rvv( uint8_t *src, uint8_t edge[36] );
#define x264_predict_8x8_vr_rvv x264_template(predict_8x8_vr_rvv)
void x264_predict_8x8_vr_rvv( uint8_t *src, uint8_t edge[36] );
#define x264_predict_8x8_dc_rvv x264_template(predict_8x8_dc_rvv)
void x264_predict_8x8_dc_rvv( uint8_t *src, uint8_t edge[36] );
#define x264_predict_8x8_hd_rvv x264_template(predict_8x8_hd_rvv)
void x264_predict_8x8_hd_rvv( uint8_t *src, uint8_t edge[36] );
#define x264_predict_8x8_hu_rvv x264_template(predict_8x8_hu_rvv)
void x264_predict_8x8_hu_rvv( uint8_t *src, uint8_t edge[36] );
#define x264_predict_8x8_h_rvv x264_template(predict_8x8_h_rvv)
void x264_predict_8x8_h_rvv( uint8_t *src, uint8_t edge[36] );


#define x264_predict_8x8c_dc_rvv x264_template(predict_8x8c_dc_rvv)
void x264_predict_8x8c_dc_rvv( uint8_t *src );
#define x264_predict_8x8c_dc_top_rvv x264_template(predict_8x8c_dc_top_rvv)
void x264_predict_8x8c_dc_top_rvv( uint8_t *src );
#define x264_predict_8x8c_dc_left_rvv x264_template(predict_8x8c_dc_left_rvv)
void x264_predict_8x8c_dc_left_rvv( uint8_t *src );
#define x264_predict_8x8c_h_rvv x264_template(predict_8x8c_h_rvv)
void x264_predict_8x8c_h_rvv( uint8_t *src );

#define x264_predict_8x16c_dc_left_rvv x264_template(predict_8x16c_dc_left_rvv)
void x264_predict_8x16c_dc_left_rvv( uint8_t *src );
#define x264_predict_8x16c_dc_top_rvv x264_template(predict_8x16c_dc_top_rvv)
void x264_predict_8x16c_dc_top_rvv( uint8_t *src );
#define x264_predict_8x16c_v_rvv x264_template(predict_8x16c_v_rvv)
void x264_predict_8x16c_v_rvv( uint8_t *src );
#define x264_predict_8x16c_h_rvv x264_template(predict_8x16c_h_rvv)
void x264_predict_8x16c_h_rvv( uint8_t *src );
#define x264_predict_8x16c_dc_rvv x264_template(predict_8x16c_dc_rvv)
void x264_predict_8x16c_dc_rvv( uint8_t *src );

#define x264_predict_16x16_dc_rvv x264_template(predict_16x16_dc_rvv)
void x264_predict_16x16_dc_rvv( uint8_t *src );
#define x264_predict_16x16_dc_top_rvv x264_template(predict_16x16_dc_top_rvv)
void x264_predict_16x16_dc_top_rvv( uint8_t *src );
#define x264_predict_16x16_dc_left_rvv x264_template(predict_16x16_dc_left_rvv)
void x264_predict_16x16_dc_left_rvv( uint8_t *src );
#define x264_predict_16x16_h_rvv x264_template(predict_16x16_h_rvv)
void x264_predict_16x16_h_rvv( uint8_t *src );
#define x264_predict_16x16_v_rvv x264_template(predict_16x16_v_rvv)
void x264_predict_16x16_v_rvv( uint8_t *src );
#define x264_predict_16x16_p_rvv x264_template(predict_16x16_p_rvv)
void x264_predict_16x16_p_rvv( uint8_t *src );


#define x264_predict_4x4_init_rvv x264_template(predict_4x4_init_rvv)
void x264_predict_4x4_init_rvv( uint32_t cpu, x264_predict_t pf[12] );
#define x264_predict_8x8_init_rvv x264_template(predict_8x8_init_rvv)
void x264_predict_8x8_init_rvv( uint32_t cpu, x264_predict8x8_t pf[12], x264_predict_8x8_filter_t *predict_filter );
#define x264_predict_8x8c_init_rvv x264_template(predict_8x8c_init_rvv)
void x264_predict_8x8c_init_rvv( uint32_t cpu, x264_predict_t pf[7] );
#define x264_predict_8x16c_init_rvv x264_template(predict_8x16c_init_rvv)
void x264_predict_8x16c_init_rvv( uint32_t cpu, x264_predict_t pf[7] );
#define x264_predict_16x16_init_rvv x264_template(predict_16x16_init_rvv)
void x264_predict_16x16_init_rvv( uint32_t cpu, x264_predict_t pf[7] );
#endif