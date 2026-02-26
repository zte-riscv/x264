#include "asm.S"
#include "asm-offsets.h"

// ===========================================================================
// RISC-V CABAC Implementation
// Arch: RV64IM + Zbb (clzw, andn)
// ===========================================================================

.text

// ---------------------------------------------------------------------------
// cabac_encode_decision_asm
// a0 = cb, a1 = i_ctx, a2 = b
// ---------------------------------------------------------------------------
function cabac_encode_decision_asm, export=1
    // Stack setup deferred to slow path (Shrink-wrapping)

    add     t0, a0, a1
    lbu     t1, CABAC_STATE(t0)     // i_state
    lw      t2, CABAC_I_RANGE(a0)   // i_range
    
    // Preload low/queue to hide load-use latency of state/range
    lw      t3, CABAC_I_LOW(a0)     // i_low
    lw      t5, CABAC_I_QUEUE(a0)   // i_queue

    // Calc range_lps index: (state >> 1)*4 + ((range >> 6) - 4)
    srliw   t4, t1, 1
    srliw   a4, t2, 6
    addiw   a4, a4, -4
    slliw   t6, t4, 2
    add     a4, a4, t6

    // Load range_lps
    lla     t6, x264_cabac_range_lps
    add     t6, t6, a4
    lbu     t4, 0(t6)               // range_lps

    // Calc new state index: (state << 1) | b
    slliw   t6, t1, 1
    or      t6, t6, a2

    // Lookup and update state
    lla     a3, x264_cabac_transition
    add     a3, a3, t6
    lbu     a3, 0(a3)
    sb      a3, CABAC_STATE(t0)

    // --- Branchless Update ---
    
    // range_mps = range - range_lps
    subw    a4, t2, t4

    // mask = -((b ^ state) & 1)
    xor     t6, a2, t1
    andi    t6, t6, 1
    neg     t6, t6

    // low += (range_mps & mask)
    and     a5, a4, t6
    addw    t3, t3, a5

    // range = (range_mps & ~mask) | (range_lps & mask)
    andn    t2, a4, t6
    and     t4, t4, t6
    or      t2, t2, t4

    // --- Renormalization ---

    // shift = clz(range) - 23 (Zbb)
    clzw    t6, t2
    addiw   t6, t6, -23

    // Apply shift
    sllw    t3, t3, t6
    sllw    t2, t2, t6
    addw    t5, t5, t6

    // Check queue full
    bgez    t5, .L_decision_putbyte

    // Fast path return
    sw      t3, CABAC_I_LOW(a0)
    sw      t2, CABAC_I_RANGE(a0)
    sw      t5, CABAC_I_QUEUE(a0)
    ret

.L_decision_putbyte:
    addi    sp, sp, -16
    sd      ra, 0(sp)
    j       .L_cabac_putbyte
endfunc

// ---------------------------------------------------------------------------
// cabac_encode_bypass_asm
// a0 = cb, a1 = b
// ---------------------------------------------------------------------------
function cabac_encode_bypass_asm, export=1
    lw      t2, CABAC_I_RANGE(a0)
    lw      t3, CABAC_I_LOW(a0)
    lw      t5, CABAC_I_QUEUE(a0)

    // low = (low << 1) + (b & range)
    and     a1, a1, t2
    slliw   t3, t3, 1
    addw    t3, t3, a1

    addiw   t5, t5, 1

    bgez    t5, .L_bypass_putbyte

    sw      t3, CABAC_I_LOW(a0)
    sw      t5, CABAC_I_QUEUE(a0)
    ret

.L_bypass_putbyte:
    addi    sp, sp, -16
    sd      ra, 0(sp)
    j       .L_cabac_putbyte
endfunc

// ---------------------------------------------------------------------------
// cabac_encode_terminal_asm
// a0 = cb
// ---------------------------------------------------------------------------
function cabac_encode_terminal_asm, export=1
    lw      t2, CABAC_I_RANGE(a0)

    // range -= 2
    addiw   t2, t2, -2

    // Check renorm (range < 0x100)
    li      t6, 0x100
    bge     t2, t6, .L_terminal_done

    // Renormalize 1 bit
    lw      t3, CABAC_I_LOW(a0)
    lw      t5, CABAC_I_QUEUE(a0)

    slliw   t2, t2, 1
    slliw   t3, t3, 1
    addiw   t5, t5, 1

    bgez    t5, .L_terminal_putbyte

    sw      t2, CABAC_I_RANGE(a0)
    sw      t3, CABAC_I_LOW(a0)
    sw      t5, CABAC_I_QUEUE(a0)
    ret

.L_terminal_done:
    sw      t2, CABAC_I_RANGE(a0)
    ret

.L_terminal_putbyte:
    addi    sp, sp, -16
    sd      ra, 0(sp)
    j       .L_cabac_putbyte
endfunc

// ---------------------------------------------------------------------------
// Helper: .L_cabac_putbyte
// t3 = low, t2 = range, t5 = queue
// Expects stack frame ready
// ---------------------------------------------------------------------------
.align 2
.L_cabac_putbyte:
    lw      t6, CABAC_I_BYTES_OUTSTANDING(a0)

    // out = low >> (queue + 10)
    addiw   t4, t5, 10
    srlw    a4, t3, t4

    // low &= (1 << (queue + 10)) - 1
    li      a5, 1
    sllw    a5, a5, t4
    addiw   a5, a5, -1
    and     t3, t3, a5

    addiw   t5, t5, -8

    // Check 0xff (outstanding bytes)
    andi    a6, a4, 0xff
    li      a7, 0xff
    beq     a6, a7, .L_pb_add_outstanding

    // Handle carry
    srliw   a6, a4, 8               // carry bit
    ld      t4, CABAC_P(a0)         // p_ptr

    // *p_ptr[-1] += carry
    lbu     a7, -1(t4)
    add     a7, a7, a6
    sb      a7, -1(t4)

    beqz    t6, .L_pb_write_cur

    // Propagate carry to pending 0xff bytes
    addi    a6, a6, -1              // carry ? 0 : -1 (0xff)

.L_pb_loop:
    sb      a6, 0(t4)
    addi    t4, t4, 1
    addiw   t6, t6, -1
    bnez    t6, .L_pb_loop

    sw      zero, CABAC_I_BYTES_OUTSTANDING(a0)

.L_pb_write_cur:
    sb      a4, 0(t4)
    addi    t4, t4, 1
    sd      t4, CABAC_P(a0)

    j       .L_pb_finish

.L_pb_add_outstanding:
    addiw   t6, t6, 1
    sw      t6, CABAC_I_BYTES_OUTSTANDING(a0)

.L_pb_finish:
    sw      t3, CABAC_I_LOW(a0)
    sw      t2, CABAC_I_RANGE(a0)
    sw      t5, CABAC_I_QUEUE(a0)

    ld      ra, 0(sp)
    addi    sp, sp, 16
    ret