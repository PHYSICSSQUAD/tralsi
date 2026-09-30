# =============================================================================
# mul_smoke.s - directed RV32IM program for the multiplier smoke test
# -----------------------------------------------------------------------------
# Assembled by tb/scripts/rv32_asm.py at boot address 0x80.
# Data memory model window: 0x0001_0000 .. 0x0001_0FFF, end-of-test store to
# 0x0001_0FFC (magic address watched by tb_smoke.sv).
#
# Scenarios (see notes/mul_plan.md 2.5 / 2.7):
#   S1 corner operands for MUL / MULH / MULHSU / MULHU
#   S2 back-to-back MULH x MULH, MULH -> MUL, MUL -> MULH (FSM re-entry)
#   S3 rd = x0, rs1 == rs2, rd == rs1
#   S4 dependency: MULH result consumed by the next MUL-unit op (EX forwarding)
#   S5 DIV/REM in the same stream (ALU side, must not disturb the MUL agent)
#   S6 external stalls: MUL / MULH in EX while an older load waits for rvalid
#   S7 MULH followed by a taken branch (older multicycle op completes)
#   S8 load-use into a MULH (ID stall, then normal 5-cycle MULH)
# =============================================================================
_start:
    li   x1,  0x80000000        # INT_MIN
    li   x2,  0xFFFFFFFF        # -1
    li   x3,  0x7FFFFFFF        # INT_MAX
    li   x4,  2
    li   x5,  0x12345678
    li   x6,  0x9ABCDEF0
    li   x7,  0xAAAAAAAA
    li   x8,  0x55555555
    li   x24, 0x10000           # data base

# ---- S1: corners --------------------------------------------------------------
    mul    x10, x1, x4          # INT_MIN * 2      -> 0x00000000 (low word overflow)
    mulh   x11, x1, x2          # INT_MIN * -1     -> 0x00000000
    mulhsu x12, x1, x2          # INT_MIN * 2^32-1 -> 0x80000000
    mulhu  x13, x2, x2          # (2^32-1)^2       -> 0xFFFFFFFE
    mul    x14, x5, x6
    mulh   x15, x5, x6
    mulhsu x16, x5, x6
    mulhu  x17, x5, x6
    mulh   x18, x3, x3          # INT_MAX^2 high   -> 0x3FFFFFFF
    mulhu  x19, x1, x1          # 2^62 high        -> 0x40000000
    mul    x20, x7, x8
    mulhsu x21, x2, x3
    mul    x22, x0, x5          # x0 operand
    mulh   x23, x2, x0

# ---- S2 / S3 / S4: sequences, register overlaps, dependency ---------------------
    mulh   x25, x5, x6          # MULH -> MULH back-to-back
    mulh   x26, x6, x5
    mul    x27, x25, x26        # MULH -> MUL, consumes both previous results
    mulh   x28, x27, x27        # MUL -> MULH, rs1 == rs2, consumer at distance 1
    mulh   x0,  x1, x1          # rd = x0 (5 cycles for nothing)
    mul    x28, x28, x4         # rd == rs1
    mulhu  x29, x28, x2

# ---- S5: divider in the same stream ----------------------------------------------
    div    x30, x1, x2          # overflow -> INT_MIN
    rem    x31, x1, x2          # overflow -> 0
    divu   x9,  x2, x4
    remu   x9,  x5, x0          # /0 -> dividend
    mul    x9,  x9, x4          # MUL right after a 35-cycle REMU

# ---- S6: external stalls (data responses may be delayed by the memory model) ----
    sw     x5, 0(x24)
    sw     x6, 4(x24)
    lw     x10, 0(x24)          # load in WB waiting for rvalid ...
    mul    x11, x5, x6          # ... MUL in EX: mult_ready=1 but ex_valid waits (stall_cycles > 0)
    lw     x12, 4(x24)
    mulh   x13, x5, x6          # MULH FSM runs during the wait, FINISH held until rvalid
    lw     x14, 0(x24)
    lw     x15, 4(x24)          # two outstanding loads
    mulhu  x16, x14, x15        # load-use: ID stall until data returns, then 5 cycles
    sw     x16, 8(x24)
    mul    x17, x16, x16        # MUL while the store is outstanding

# ---- S7: MULH older than a taken branch ------------------------------------------
    mulh   x18, x5, x6
    beq    x0, x0, s7_target    # taken: kills the MUL below (it never reaches EX)
    mul    x19, x1, x1          # must not execute
    mul    x19, x1, x1
s7_target:
    addi   x19, x0, 7
    mulh   x20, x5, x6
    bne    x19, x0, s7_target2  # branch right after a MULH, taken
    mul    x21, x2, x2          # must not execute
s7_target2:
    mul    x21, x19, x19        # 49

# ---- S8: load-use into MULH, then a MUL with a pending store ---------------------
    lw     x22, 8(x24)
    mulh   x23, x22, x6
    sw     x23, 12(x24)
    mul    x25, x23, x4

# ---- S9 (ALU agent): branch leaving EX while WB waits for a load (ex_ready=1, ex_valid=0),
#      not-taken branches, DIV followed by a dependent branch, misaligned lw/sw (2 ALU passes)
    lw     x27, 0(x24)          # in WB waiting for rvalid (needs +drw) ...
    beq    x0, x0, s9_a         # ... branch in EX: ex_ready by branch_in_ex, ex_valid=0
    mul    x28, x1, x1          # must not execute
s9_a:
    lw     x27, 4(x24)
    bne    x0, x0, s9_bad       # not taken, WB busy
    blt    x4, x1, s9_bad       # 2 < INT_MIN signed? no -> not taken
    bltu   x1, x4, s9_bad       # INT_MIN <u 2? no -> not taken
    bge    x1, x4, s9_bad       # INT_MIN >= 2 signed? no
    bgeu   x4, x1, s9_bad       # 2 >=u INT_MIN? no
    div    x28, x3, x4          # INT_MAX / 2 = 0x3FFFFFFF (latency 33)
    bne    x28, x0, s9_b        # depends on the DIV result (forwarded), taken
s9_bad:
    li     x29, 0xBAD
s9_b:
    sw     x5, 1(x24)           # misaligned store: 2 ALU passes in EX (addr, addr+4)
    lw     x30, 1(x24)          # misaligned load: 0x12345678 back
    lh     x31, 3(x24)          # misaligned halfword

# ---- end of test ------------------------------------------------------------------
    li     x26, 0x10FFC
    sw     x0, 0(x26)           # magic end-of-test store
done:
    j      done
