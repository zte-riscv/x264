/*****************************************************************************
 * asm-offsets.c: check asm offsets for riscv
 *****************************************************************************/

#include "common/common.h"
#include "asm-offsets.h"

// Static assertion macro
#define STATIC_ASSERT(name, x) int assert_##name[2 * !!(x) - 1]

// Check absolute offset against defined constant
#define X264_CHECK_OFFSET(s, m, o) struct check_##s##_##m \
{ \
    STATIC_ASSERT(offset_##m, offsetof(s, m) == o); \
}

// Check relative offset between members (ensure packing)
#define X264_CHECK_REL_OFFSET(s, a, type, b) struct check_##s##_##a##_##b \
{ \
    STATIC_ASSERT(rel_offset_##a##_##b, offsetof(s, a) + sizeof(type) == offsetof(s, b)); \
}

// Validate x264_cabac_t offsets
X264_CHECK_OFFSET(x264_cabac_t, i_low,               CABAC_I_LOW);
X264_CHECK_OFFSET(x264_cabac_t, i_range,             CABAC_I_RANGE);
X264_CHECK_OFFSET(x264_cabac_t, i_queue,             CABAC_I_QUEUE);
X264_CHECK_OFFSET(x264_cabac_t, i_bytes_outstanding, CABAC_I_BYTES_OUTSTANDING);
X264_CHECK_OFFSET(x264_cabac_t, p_start,             CABAC_P_START);
X264_CHECK_OFFSET(x264_cabac_t, p,                   CABAC_P);
X264_CHECK_OFFSET(x264_cabac_t, p_end,               CABAC_P_END);
X264_CHECK_OFFSET(x264_cabac_t, f8_bits_encoded,     CABAC_F8_BITS_ENCODED);
X264_CHECK_OFFSET(x264_cabac_t, state,               CABAC_STATE);

// Validate member packing
X264_CHECK_REL_OFFSET(x264_cabac_t, i_low,    int, i_range);
X264_CHECK_REL_OFFSET(x264_cabac_t, i_queue,  int, i_bytes_outstanding);