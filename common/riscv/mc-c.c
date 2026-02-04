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
#include "mc.h"

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
#define x264_mc_chroma_rvv x264_template(mc_chroma_rvv)
void x264_mc_chroma_rvv( uint8_t *dstu, uint8_t *dstv, intptr_t i_dst_stride,
                        uint8_t *src, intptr_t i_src_stride,
                        int mvx, int mvy, int i_width, int i_height );

#define x264_mc_weight_w16_rvv x264_template(mc_weight_w16_rvv)
#define x264_mc_weight_w16_nodenom_rvv x264_template(mc_weight_w16_nodenom_rvv)
#define x264_mc_weight_w16_offsetadd_rvv x264_template(mc_weight_w16_offsetadd_rvv)
#define x264_mc_weight_w16_offsetsub_rvv x264_template(mc_weight_w16_offsetsub_rvv)
#define x264_mc_weight_w20_rvv x264_template(mc_weight_w20_rvv)
#define x264_mc_weight_w20_nodenom_rvv x264_template(mc_weight_w20_nodenom_rvv)
#define x264_mc_weight_w20_offsetadd_rvv x264_template(mc_weight_w20_offsetadd_rvv)
#define x264_mc_weight_w20_offsetsub_rvv x264_template(mc_weight_w20_offsetsub_rvv)
#define x264_mc_weight_w4_rvv x264_template(mc_weight_w4_rvv)
#define x264_mc_weight_w4_nodenom_rvv x264_template(mc_weight_w4_nodenom_rvv)
#define x264_mc_weight_w4_offsetadd_rvv x264_template(mc_weight_w4_offsetadd_rvv)
#define x264_mc_weight_w4_offsetsub_rvv x264_template(mc_weight_w4_offsetsub_rvv)
#define x264_mc_weight_w8_rvv x264_template(mc_weight_w8_rvv)
#define x264_mc_weight_w8_nodenom_rvv x264_template(mc_weight_w8_nodenom_rvv)
#define x264_mc_weight_w8_offsetadd_rvv x264_template(mc_weight_w8_offsetadd_rvv)
#define x264_mc_weight_w8_offsetsub_rvv x264_template(mc_weight_w8_offsetsub_rvv)
#define MC_WEIGHT(func)\
void x264_mc_weight_w20##func##_rvv( pixel *, intptr_t, pixel *, intptr_t, const x264_weight_t *, int );\
void x264_mc_weight_w16##func##_rvv( pixel *, intptr_t, pixel *, intptr_t, const x264_weight_t *, int );\
void x264_mc_weight_w8##func##_rvv ( pixel *, intptr_t, pixel *, intptr_t, const x264_weight_t *, int );\
void x264_mc_weight_w4##func##_rvv ( pixel *, intptr_t, pixel *, intptr_t, const x264_weight_t *, int );\
\
static void (* mc##func##_wtab_rvv[6])( pixel *, intptr_t, pixel *, intptr_t, const x264_weight_t *, int ) =\
{\
    x264_mc_weight_w4##func##_rvv,\
    x264_mc_weight_w4##func##_rvv,\
    x264_mc_weight_w8##func##_rvv,\
    x264_mc_weight_w16##func##_rvv,\
    x264_mc_weight_w16##func##_rvv,\
    x264_mc_weight_w20##func##_rvv,\
};

MC_WEIGHT()
MC_WEIGHT(_nodenom)
MC_WEIGHT(_offsetadd)
MC_WEIGHT(_offsetsub)
#define x264_mc_copy_w4_rvv x264_template(mc_copy_w4_rvv)
void x264_mc_copy_w4_rvv ( pixel *, intptr_t, pixel *, intptr_t, int );
#define x264_mc_copy_w8_rvv x264_template(mc_copy_w8_rvv)
void x264_mc_copy_w8_rvv ( pixel *, intptr_t, pixel *, intptr_t, int );
#define x264_mc_copy_w16_rvv x264_template(mc_copy_w16_rvv)
void x264_mc_copy_w16_rvv( pixel *, intptr_t, pixel *, intptr_t, int );
#define x264_frame_init_lowres_core_rvv x264_template(frame_init_lowres_core_rvv)
void x264_frame_init_lowres_core_rvv( pixel *, pixel *, pixel *, pixel *, pixel *, intptr_t, intptr_t, int, int );

static void (* const pixel_avg_wtab_rvv[6])( pixel *, intptr_t, pixel *, intptr_t, pixel *, int ) =
{
    NULL,
    x264_pixel_avg2_w4_rvv,
    x264_pixel_avg2_w8_rvv,
    x264_pixel_avg2_w16_rvv,   // no slower than w12, so no point in a separate function
    x264_pixel_avg2_w16_rvv,
    x264_pixel_avg2_w20_rvv,
};

static void (* const mc_copy_wtab_rvv[5])( pixel *, intptr_t, pixel *, intptr_t, int ) =
{
    NULL,
    x264_mc_copy_w4_rvv,
    x264_mc_copy_w8_rvv,
    NULL,
    x264_mc_copy_w16_rvv,
};

static void weight_cache_rvv( x264_t *h, x264_weight_t *w )
{
    if( w->i_scale == 1<<w->i_denom )
    {
        if( w->i_offset < 0 )
        {
            w->weightfn = mc_offsetsub_wtab_rvv;
            w->cachea[0] = -w->i_offset;
        }
        else
        {
            w->weightfn = mc_offsetadd_wtab_rvv;
            w->cachea[0] = w->i_offset;
        }
    }
    else if( !w->i_denom )
        w->weightfn = mc_nodenom_wtab_rvv;
    else
        w->weightfn = mc_wtab_rvv;
}

static void mc_copy( pixel *src, intptr_t i_src_stride, pixel *dst, intptr_t i_dst_stride, int i_width, int i_height )
{
    for( int y = 0; y < i_height; y++ )
    {
        memcpy( dst, src, i_width * SIZEOF_PIXEL );

        src += i_src_stride;
        dst += i_dst_stride;
    }
}

static void mc_luma_rvv( pixel *dst,    intptr_t i_dst_stride,
                          pixel *src[4], intptr_t i_src_stride,
                          int mvx, int mvy,
                          int i_width, int i_height, const x264_weight_t *weight )
{
    int qpel_idx = ((mvy&3)<<2) + (mvx&3);
    intptr_t offset = (mvy>>2)*i_src_stride + (mvx>>2);
    pixel *src1 = src[x264_hpel_ref0[qpel_idx]] + offset;
    if( (mvy&3) == 3 )             // explicit if() to force conditional add
        src1 += i_src_stride;

    if( qpel_idx & 5 ) /* qpel interpolation needed */
    {
        pixel *src2 = src[x264_hpel_ref1[qpel_idx]] + offset + ((mvx&3) == 3);
        pixel_avg_wtab_rvv[i_width>>2](
                dst, i_dst_stride, src1, i_src_stride,
                src2, i_height );
        if( weight->weightfn )
            weight->weightfn[i_width>>2]( dst, i_dst_stride, dst, i_dst_stride, weight, i_height );
    }
    else if( weight->weightfn )
        weight->weightfn[i_width>>2]( dst, i_dst_stride, src1, i_src_stride, weight, i_height );
    else
        mc_copy_wtab_rvv[i_width>>2]( dst, i_dst_stride, src1, i_src_stride, i_height );
}

static pixel *get_ref_rvv( pixel *dst,   intptr_t *i_dst_stride,
                              pixel *src[4], intptr_t i_src_stride,
                              int mvx, int mvy,
                              int i_width, int i_height, const x264_weight_t *weight )
{
    int qpel_idx = ((mvy&3)<<2) + (mvx&3);
    intptr_t offset = (mvy>>2)*i_src_stride + (mvx>>2);
    pixel *src1 = src[x264_hpel_ref0[qpel_idx]] + offset;
    if( (mvy&3) == 3 )             // explicit if() to force conditional add
        src1 += i_src_stride;

    if( qpel_idx & 5 ) /* qpel interpolation needed */
    {
        pixel *src2 = src[x264_hpel_ref1[qpel_idx]] + offset + ((mvx&3) == 3);
        pixel_avg_wtab_rvv[i_width>>2](
                dst, *i_dst_stride, src1, i_src_stride,
                src2, i_height );
        if( weight->weightfn )
            weight->weightfn[i_width>>2]( dst, *i_dst_stride, dst, *i_dst_stride, weight, i_height );
        return dst;
    }
    else if( weight->weightfn )
    {
        weight->weightfn[i_width>>2]( dst, *i_dst_stride, src1, i_src_stride, weight, i_height );
        return dst;
    }
    else
    {
        *i_dst_stride = i_src_stride;
        return src1;
    }
}

void x264_mc_init_rvv( uint32_t cpu, x264_mc_functions_t *pf )
{
#if !HIGH_BIT_DEPTH
    if( cpu&X264_CPU_RVV )
    {
        pf->copy_16x16_unaligned = x264_mc_copy_w16_rvv;
        pf->copy[PIXEL_16x16]    = x264_mc_copy_w16_rvv;
        pf->copy[PIXEL_8x8]      = x264_mc_copy_w8_rvv;
        pf->copy[PIXEL_4x4]      = x264_mc_copy_w4_rvv;

        pf->avg[PIXEL_16x16] = x264_pixel_avg_16x16_rvv;
        pf->avg[PIXEL_16x8]  = x264_pixel_avg_16x8_rvv;
        pf->avg[PIXEL_8x16]  = x264_pixel_avg_8x16_rvv;
        pf->avg[PIXEL_8x8]   = x264_pixel_avg_8x8_rvv;
        pf->avg[PIXEL_8x4]   = x264_pixel_avg_8x4_rvv;
        pf->avg[PIXEL_4x16]  = x264_pixel_avg_4x16_rvv;
        pf->avg[PIXEL_4x8]   = x264_pixel_avg_4x8_rvv;
        pf->avg[PIXEL_4x4]   = x264_pixel_avg_4x4_rvv;
        pf->avg[PIXEL_4x2]   = x264_pixel_avg_4x2_rvv;

        pf->weight       = mc_wtab_rvv;
        pf->offsetadd    = mc_offsetadd_wtab_rvv;
        pf->offsetsub    = mc_offsetsub_wtab_rvv;
        pf->weight_cache = weight_cache_rvv;

        pf->mc_luma = mc_luma_rvv;
        pf->get_ref = get_ref_rvv;
        pf->frame_init_lowres_core = x264_frame_init_lowres_core_rvv;
        pf->mc_chroma = x264_mc_chroma_rvv;
    }
#endif // !HIGH_BIT_DEPTH
}
