/*****************************************************************************
 * predict.c: aarch64 intra prediction
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

#include "common/common.h"
#include "predict.h"
#include "pixel.h"

void x264_predict_4x4_init_rvv( uint32_t cpu, x264_predict_t pf[12] )
{
#if !HIGH_BIT_DEPTH
    if( cpu&X264_CPU_RVV )
    {
        pf[I_PRED_4x4_DC]      = x264_predict_4x4_dc_rvv;

        pf[I_PRED_4x4_DC_LEFT] = x264_predict_4x4_dc_left_rvv;
        pf[I_PRED_4x4_DC_TOP]  = x264_predict_4x4_dc_top_rvv;
        pf[I_PRED_4x4_DDL]    = x264_predict_4x4_ddl_rvv;
        pf[I_PRED_4x4_DDR]    = x264_predict_4x4_ddr_rvv;
    }
#endif // !HIGH_BIT_DEPTH
}

void x264_predict_8x8c_init_rvv( uint32_t cpu, x264_predict_t pf[7] )
{
#if !HIGH_BIT_DEPTH
    if( cpu&X264_CPU_RVV )
    {
        pf[I_PRED_CHROMA_DC]      = x264_predict_8x8c_dc_rvv;
        pf[I_PRED_CHROMA_DC_TOP]  = x264_predict_8x8c_dc_top_rvv;
        pf[I_PRED_CHROMA_DC_LEFT] = x264_predict_8x8c_dc_left_rvv;
        pf[I_PRED_CHROMA_H]      = x264_predict_8x8c_h_rvv;
    }
#endif // !HIGH_BIT_DEPTH
}

void x264_predict_8x8_init_rvv( uint32_t cpu, x264_predict8x8_t pf[12], x264_predict_8x8_filter_t *predict_filter )
{
#if !HIGH_BIT_DEPTH
    if( cpu&X264_CPU_RVV )
    {
        pf[I_PRED_8x8_DDL]    = x264_predict_8x8_ddl_rvv;
        pf[I_PRED_8x8_DDR]    = x264_predict_8x8_ddr_rvv;
        pf[I_PRED_8x8_VR]  = x264_predict_8x8_vr_rvv;
        pf[I_PRED_8x8_VL]  = x264_predict_8x8_vl_rvv;
        pf[I_PRED_8x8_DC]  = x264_predict_8x8_dc_rvv;
        pf[I_PRED_8x8_H]  = x264_predict_8x8_h_rvv;
    }
#endif // !HIGH_BIT_DEPTH
}

void x264_predict_8x16c_init_rvv( uint32_t cpu, x264_predict_t pf[7] )
{
#if !HIGH_BIT_DEPTH
    if( cpu&X264_CPU_RVV )
    {
        pf[I_PRED_CHROMA_H ]     = x264_predict_8x16c_h_rvv;
        pf[I_PRED_CHROMA_DC]     = x264_predict_8x16c_dc_rvv;
        pf[I_PRED_CHROMA_DC_LEFT]= x264_predict_8x16c_dc_left_rvv;
        pf[I_PRED_CHROMA_DC_TOP ]= x264_predict_8x16c_dc_top_rvv;
    }
#endif // !HIGH_BIT_DEPTH
}

void x264_predict_16x16_init_rvv( uint32_t cpu, x264_predict_t pf[7] )
{
#if !HIGH_BIT_DEPTH
    if( cpu&X264_CPU_RVV )
    {
        pf[I_PRED_16x16_DC ]    = x264_predict_16x16_dc_rvv;
        pf[I_PRED_16x16_DC_TOP] = x264_predict_16x16_dc_top_rvv;
        pf[I_PRED_16x16_DC_LEFT]= x264_predict_16x16_dc_left_rvv;
        pf[I_PRED_16x16_H ]     = x264_predict_16x16_h_rvv;
        pf[I_PRED_16x16_V ]     = x264_predict_16x16_v_rvv;

    }
#endif // !HIGH_BIT_DEPTH
}