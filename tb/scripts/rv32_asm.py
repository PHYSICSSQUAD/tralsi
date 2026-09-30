#!/usr/bin/env python3
"""Minimal RV32IM assembler + reference executor used by the smoke test.

* assemble(src) -> list of 32-bit words   (RV32I subset + all RV32M ops, labels,
  `li` pseudo-instruction, `j`/`nop`)
* execute(words, ...) -> final register file (dict) computed with the same
  spec definitions as tb/common/rv32m_ref_pkg.sv (independent Python code)

Usage:
  python3 tb/scripts/rv32_asm.py <prog.s> <out.mem> <exp_regs.txt> [--base 0x80] [--end-addr 0x10FFC]
      assemble + execute; out.mem = $readmemh image ('@wordaddr' header, one word per line),
      exp_regs.txt = "N hexval" lines with the expected final architectural register file
  python3 tb/scripts/rv32_asm.py <image.mem> - <exp_regs.txt> --exec-mem [--end-addr ...]
      execute an existing image (e.g. written by mul_program_gen) and dump the expected registers
  python3 tb/scripts/rv32_asm.py --compare <exp_regs.txt> <rtl_regs.txt>
      compare two register dumps (exit code 1 on mismatch)
"""
import re
import sys

M32 = 0xFFFFFFFF


def s32(x):
    x &= M32
    return x - (1 << 32) if x & 0x80000000 else x


def u32(x):
    return x & M32


REGS = {f"x{i}": i for i in range(32)}
ABI = ["zero", "ra", "sp", "gp", "tp", "t0", "t1", "t2", "s0", "s1", "a0", "a1", "a2", "a3", "a4", "a5",
       "a6", "a7", "s2", "s3", "s4", "s5", "s6", "s7", "s8", "s9", "s10", "s11", "t3", "t4", "t5", "t6"]
REGS.update({n: i for i, n in enumerate(ABI)})
REGS["fp"] = 8

R_TYPE = {  # name: (funct7, funct3)
    "add": (0x00, 0), "sub": (0x20, 0), "sll": (0x00, 1), "slt": (0x00, 2), "sltu": (0x00, 3),
    "xor": (0x00, 4), "srl": (0x00, 5), "sra": (0x20, 5), "or": (0x00, 6), "and": (0x00, 7),
    "mul": (0x01, 0), "mulh": (0x01, 1), "mulhsu": (0x01, 2), "mulhu": (0x01, 3),
    "div": (0x01, 4), "divu": (0x01, 5), "rem": (0x01, 6), "remu": (0x01, 7),
}
I_TYPE = {"addi": 0, "slti": 2, "sltiu": 3, "xori": 4, "ori": 6, "andi": 7}
SHIFT_I = {"slli": (0x00, 1), "srli": (0x00, 5), "srai": (0x20, 5)}
LOADS = {"lb": 0, "lh": 1, "lw": 2, "lbu": 4, "lhu": 5}
STORES = {"sb": 0, "sh": 1, "sw": 2}
BRANCHES = {"beq": 0, "bne": 1, "blt": 4, "bge": 5, "bltu": 6, "bgeu": 7}


def reg(t):
    t = t.strip()
    if t not in REGS:
        raise ValueError(f"bad register '{t}'")
    return REGS[t]


def imm(t, labels=None):
    t = t.strip()
    if labels and t in labels:
        return labels[t]
    return int(t, 0)


def enc_r(f7, f3, rd, rs1, rs2):
    return (f7 << 25) | (rs2 << 20) | (rs1 << 15) | (f3 << 12) | (rd << 7) | 0x33


def enc_i(opc, f3, rd, rs1, im):
    return ((im & 0xFFF) << 20) | (rs1 << 15) | (f3 << 12) | (rd << 7) | opc


def enc_s(f3, rs1, rs2, im):
    return (((im >> 5) & 0x7F) << 25) | (rs2 << 20) | (rs1 << 15) | (f3 << 12) | ((im & 0x1F) << 7) | 0x23


def enc_b(f3, rs1, rs2, off):
    assert off % 2 == 0 and -4096 <= off < 4096
    o = off & 0x1FFF
    return (((o >> 12) & 1) << 31) | (((o >> 5) & 0x3F) << 25) | (rs2 << 20) | (rs1 << 15) | (f3 << 12) | \
           (((o >> 1) & 0xF) << 8) | (((o >> 11) & 1) << 7) | 0x63


def enc_u(opc, rd, im20):
    return ((im20 & 0xFFFFF) << 12) | (rd << 7) | opc


def enc_j(rd, off):
    assert off % 2 == 0 and -(1 << 20) <= off < (1 << 20)
    o = off & 0x1FFFFF
    return (((o >> 20) & 1) << 31) | (((o >> 1) & 0x3FF) << 21) | (((o >> 11) & 1) << 20) | \
           (((o >> 12) & 0xFF) << 12) | (rd << 7) | 0x6F


def parse_mem(t):
    m = re.match(r"\s*(-?\w+)\s*\(\s*(\w+)\s*\)\s*$", t)
    if not m:
        raise ValueError(f"bad memory operand '{t}'")
    return int(m.group(1), 0), reg(m.group(2))


def expand_li(rd, val):
    """li rd, imm32 -> [lui, addi] (or a single instruction when possible)."""
    val = u32(val)
    lo = val & 0xFFF
    if lo & 0x800:
        lo -= 0x1000
    hi = u32(val - lo) >> 12
    out = []
    if hi == 0:
        out.append(("addi", rd, 0, lo))
    else:
        out.append(("lui", rd, hi))
        if lo != 0:
            out.append(("addi", rd, rd, lo))
    return out


def assemble(src, base=0):
    # pass 1: expand pseudo ops, collect labels
    items = []          # (kind, fields)
    labels = {}
    pc = base
    for raw in src.splitlines():
        line = raw.split("#")[0].split(";")[0].strip()
        if not line:
            continue
        while ":" in line:
            lab, line = line.split(":", 1)
            labels[lab.strip()] = pc
            line = line.strip()
        if not line:
            continue
        parts = re.split(r"[\s,]+", line, maxsplit=1)
        op = parts[0].lower()
        args = [a.strip() for a in re.split(r",", parts[1])] if len(parts) > 1 else []
        if op == "li":
            for e in expand_li(reg(args[0]), imm(args[1])):
                items.append(("raw", e, pc))
                pc += 4
            continue
        if op == "nop":
            items.append(("raw", ("addi", 0, 0, 0), pc))
            pc += 4
            continue
        if op == "j":
            items.append(("j", ("jal", "x0", args[0]), pc))
            pc += 4
            continue
        items.append(("asm", (op, args), pc))
        pc += 4

    # pass 2: encode
    words = []
    for kind, f, at in items:
        if kind == "raw":
            if f[0] == "lui":
                words.append(enc_u(0x37, f[1], f[2]))
            else:
                words.append(enc_i(0x13, 0, f[1], f[2], f[3]))
            continue
        if kind == "j":
            words.append(enc_j(0, imm(f[2], labels) - at))
            continue
        op, a = f
        if op in R_TYPE:
            f7, f3 = R_TYPE[op]
            words.append(enc_r(f7, f3, reg(a[0]), reg(a[1]), reg(a[2])))
        elif op in I_TYPE:
            words.append(enc_i(0x13, I_TYPE[op], reg(a[0]), reg(a[1]), imm(a[2])))
        elif op in SHIFT_I:
            f7, f3 = SHIFT_I[op]
            words.append(enc_i(0x13, f3, reg(a[0]), reg(a[1]), (f7 << 5) | (imm(a[2]) & 0x1F)))
        elif op in LOADS:
            off, rs1 = parse_mem(a[1])
            words.append(enc_i(0x03, LOADS[op], reg(a[0]), rs1, off))
        elif op in STORES:
            off, rs1 = parse_mem(a[1])
            words.append(enc_s(STORES[op], rs1, reg(a[0]), off))
        elif op in BRANCHES:
            words.append(enc_b(BRANCHES[op], reg(a[0]), reg(a[1]), imm(a[2], labels) - at))
        elif op == "lui":
            words.append(enc_u(0x37, reg(a[0]), imm(a[1])))
        elif op == "auipc":
            words.append(enc_u(0x17, reg(a[0]), imm(a[1])))
        elif op == "jal":
            if len(a) == 1:
                words.append(enc_j(1, imm(a[0], labels) - at))
            else:
                words.append(enc_j(reg(a[0]), imm(a[1], labels) - at))
        elif op == "jalr":
            off, rs1 = parse_mem(a[1])
            words.append(enc_i(0x67, 0, reg(a[0]), rs1, off))
        else:
            raise ValueError(f"unsupported instruction '{op}' at 0x{at:08x}")
    return words, labels


# ---------------------------------------------------------------------------
# Reference executor (independent of the SV package: plain Python integers)
# ---------------------------------------------------------------------------
def m_ref(op, a, b):
    if op == "mul":
        return u32(a * b)
    if op == "mulh":
        return u32((s32(a) * s32(b)) >> 32)
    if op == "mulhsu":
        return u32((s32(a) * u32(b)) >> 32)
    if op == "mulhu":
        return u32((u32(a) * u32(b)) >> 32)
    if op == "div":
        sa, sb = s32(a), s32(b)
        if sb == 0:
            return M32
        if sa == -2**31 and sb == -1:
            return 0x80000000
        q = abs(sa) // abs(sb)
        return u32(-q if (sa < 0) != (sb < 0) else q)
    if op == "divu":
        return M32 if b == 0 else u32(a // b)
    if op == "rem":
        sa, sb = s32(a), s32(b)
        if sb == 0:
            return u32(sa)
        if sa == -2**31 and sb == -1:
            return 0
        r = abs(sa) % abs(sb)
        return u32(-r if sa < 0 else r)
    if op == "remu":
        return u32(a) if b == 0 else u32(a % b)
    raise ValueError(op)


def execute(words, base, data_base, data_words, max_steps=100000, end_addr=None):
    x = [0] * 32
    imem = {base + 4 * i: w for i, w in enumerate(words)}
    dmem = {}  # byte addressed
    pc = base
    steps = 0

    def ld(addr, n):
        v = 0
        for i in range(n):
            v |= dmem.get(addr + i, 0) << (8 * i)
        return v

    def st(addr, n, v):
        for i in range(n):
            dmem[addr + i] = (v >> (8 * i)) & 0xFF

    while steps < max_steps:
        steps += 1
        if pc not in imem:
            break
        w = imem[pc]
        opc = w & 0x7F
        rd = (w >> 7) & 0x1F
        f3 = (w >> 12) & 7
        rs1 = (w >> 15) & 0x1F
        rs2 = (w >> 20) & 0x1F
        f7 = (w >> 25) & 0x7F
        i_imm = s32(w) >> 20
        npc = pc + 4
        res = None
        if opc == 0x37:
            res = u32(w & 0xFFFFF000)
        elif opc == 0x17:
            res = u32(pc + (w & 0xFFFFF000))
        elif opc == 0x6F:
            off = (((w >> 31) & 1) << 20) | (((w >> 12) & 0xFF) << 12) | (((w >> 20) & 1) << 11) | (((w >> 21) & 0x3FF) << 1)
            if off & (1 << 20):
                off -= (1 << 21)
            res = u32(pc + 4)
            npc = u32(pc + off)
            if npc == pc:
                x[rd] = res if rd else 0
                break  # j . -> end
        elif opc == 0x67:
            res = u32(pc + 4)
            npc = u32(x[rs1] + i_imm) & ~1
        elif opc == 0x63:
            off = (((w >> 31) & 1) << 12) | (((w >> 7) & 1) << 11) | (((w >> 25) & 0x3F) << 5) | (((w >> 8) & 0xF) << 1)
            if off & (1 << 12):
                off -= (1 << 13)
            a, b = x[rs1], x[rs2]
            take = {0: a == b, 1: a != b, 4: s32(a) < s32(b), 5: s32(a) >= s32(b), 6: a < b, 7: a >= b}[f3]
            if take:
                npc = u32(pc + off)
        elif opc == 0x03:
            addr = u32(x[rs1] + i_imm)
            if f3 == 0:
                res = u32(s32(ld(addr, 1) << 24) >> 24)
            elif f3 == 1:
                res = u32(s32(ld(addr, 2) << 16) >> 16)
            elif f3 == 2:
                res = ld(addr, 4)
            elif f3 == 4:
                res = ld(addr, 1)
            elif f3 == 5:
                res = ld(addr, 2)
        elif opc == 0x23:
            s_imm = ((s32(w) >> 25) << 5) | ((w >> 7) & 0x1F)
            addr = u32(x[rs1] + s_imm)
            st(addr, {0: 1, 1: 2, 2: 4}[f3], x[rs2])
            if end_addr is not None and addr == end_addr:
                break
        elif opc == 0x13:
            a = x[rs1]
            sh = rs2
            if f3 == 0:
                res = u32(a + i_imm)
            elif f3 == 2:
                res = int(s32(a) < i_imm)
            elif f3 == 3:
                res = int(a < u32(i_imm))
            elif f3 == 4:
                res = u32(a ^ i_imm)
            elif f3 == 6:
                res = u32(a | i_imm)
            elif f3 == 7:
                res = u32(a & i_imm)
            elif f3 == 1:
                res = u32(a << sh)
            elif f3 == 5:
                res = u32(s32(a) >> sh) if f7 == 0x20 else a >> sh
        elif opc == 0x33:
            a, b = x[rs1], x[rs2]
            if f7 == 0x01:
                res = m_ref(["mul", "mulh", "mulhsu", "mulhu", "div", "divu", "rem", "remu"][f3], a, b)
            else:
                sh = b & 0x1F
                res = {
                    (0x00, 0): u32(a + b), (0x20, 0): u32(a - b), (0x00, 1): u32(a << sh),
                    (0x00, 2): int(s32(a) < s32(b)), (0x00, 3): int(a < b), (0x00, 4): a ^ b,
                    (0x00, 5): a >> sh, (0x20, 5): u32(s32(a) >> sh), (0x00, 6): a | b, (0x00, 7): a & b,
                }[(f7, f3)]
        else:
            raise ValueError(f"executor: unsupported opcode 0x{opc:02x} at 0x{pc:08x}")
        if res is not None and rd != 0:
            x[rd] = u32(res)
        pc = npc
    return x, dmem, steps


def read_mem_image(path):
    """Parse a $readmemh image (optional '@wordaddr' lines). Returns (base_byte_addr, words)."""
    words = []
    base = None
    addr = 0
    for line in open(path):
        line = line.split("//")[0].strip()
        if not line:
            continue
        for tok in line.split():
            if tok.startswith("@"):
                addr = int(tok[1:], 16)
                if base is None:
                    base = addr
                continue
            if base is None:
                base = addr
            while len(words) < addr - base:
                words.append(0x0000006F)  # fill gaps with 'j .'
            words.append(int(tok, 16))
            addr += 1
    return (base or 0) * 4, words


def compare_regs(exp_path, got_path):
    """Compare two 'N hexval' register dumps; returns the number of mismatches."""
    def load(p):
        d = {}
        for line in open(p):
            parts = line.split()
            if len(parts) >= 2:
                d[int(parts[0])] = int(parts[1], 16)
        return d
    exp, got = load(exp_path), load(got_path)
    bad = 0
    for r in range(1, 32):
        if exp.get(r, 0) != got.get(r, 0):
            bad += 1
            print(f"REG MISMATCH x{r}: rtl 0x{got.get(r, 0):08x} expected 0x{exp.get(r, 0):08x}")
    print(f"register compare: 31 registers, {bad} mismatches")
    return bad


def main(argv):
    if len(argv) >= 2 and argv[0] == "--compare":
        return 1 if compare_regs(argv[1], argv[2]) else 0
    if len(argv) < 3:
        print(__doc__)
        return 2
    src_path, mem_path, exp_path = argv[0], argv[1], argv[2]
    base = 0x80
    data_base = 0x10000
    end_addr = None
    exec_mem = False
    for i, a in enumerate(argv):
        if a == "--base":
            base = int(argv[i + 1], 0)
        if a == "--data-base":
            data_base = int(argv[i + 1], 0)
        if a == "--end-addr":
            end_addr = int(argv[i + 1], 0)
        if a == "--exec-mem":
            exec_mem = True
    if exec_mem:
        # argv[0] is a .mem image produced elsewhere (e.g. mul_program_gen); argv[1] is ignored
        base, words = read_mem_image(src_path)
        labels = {}
    else:
        src = open(src_path).read()
        words, labels = assemble(src, base)
        with open(mem_path, "w") as f:
            f.write(f"@{base >> 2:08x}\n")
            for w in words:
                f.write(f"{w:08x}\n")
    x, dmem, steps = execute(words, base, data_base, 1024, end_addr=end_addr)
    with open(exp_path, "w") as f:
        for i in range(32):
            f.write(f"{i} {x[i]:08x}\n")
    print(f"{'loaded' if exec_mem else 'assembled'} {len(words)} words at 0x{base:08x}, executed {steps} instructions")
    for k, v in labels.items():
        print(f"  label {k:<12} 0x{v:08x}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
