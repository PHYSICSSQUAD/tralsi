#!/usr/bin/env python3
"""vcd_to_html.py — render a VCD dump as a self-contained HTML waveform.

Usage: python3 tb/scripts/vcd_to_html.py <in.vcd> <out.html> [--scope NAME]
Default scope: the VCD's top scope (only that scope's signals are drawn —
keeps the view clean when the dump also contains checker/DUT internals).
The output HTML has inline SVG + CSS, no external JS — open it in any
browser (or serve it and watch it from the Arena preview).
"""
import re
import sys
import html as _html

# display plan: (name, kind) — kind: "bit" | "bus"
SHOW = [
    ("clk", "bit"), ("rst_n", "bit"),
    ("id_valid", "bit"), ("is_decoding", "bit"),
    ("mult_en", "bit"), ("mult_ready", "bit"), ("mult_multicycle", "bit"),
    ("mulh_active", "bit"),
    ("alu_en", "bit"), ("alu_ready", "bit"),
    ("ex_valid", "bit"), ("ex_ready", "bit"),
    ("branch_in_ex", "bit"), ("rf_alu_we", "bit"),
    ("lsu_en", "bit"), ("data_misaligned_ex", "bit"),
    ("wb_ready", "bit"), ("lsu_ready_ex", "bit"),
    ("pc_id", "bus"), ("instr_id", "bus"),
    ("alu_operand_a", "bus"), ("alu_operand_b", "bus"), ("alu_result", "bus"),
    ("mult_operand_a", "bus"), ("mult_operand_b", "bus"),
    ("mult_result", "bus"),
    ("rf_alu_waddr", "bus"), ("rf_alu_wdata", "bus"),
]

LANE_H = 42          # pixels per lane
LANE_PAD = 6
NAME_W = 170         # left column
WIDTH = 1500         # wave area
MARGIN_T = 26
MARGIN_B = 18


def parse_vcd(path, scope):
    ids = {}          # id -> (name, width)
    times = []
    cur = {}
    # id -> list of (time, value_str)
    changes = {}
    t = 0
    in_defs = True
    scopes = []
    with open(path) as fh:
        for line in fh:
            line = line.strip()
            if in_defs:
                if line.startswith("$scope"):
                    scopes.append(line.split()[2])
                elif line.startswith("$upscope"):
                    scopes.pop()
                elif line.startswith("$var"):
                    m = re.match(r"\$var\s+\w+\s+(\d+)\s+(\S+)\s+(.+?)\s+\$end", line)
                    if m:
                        width, vid, name = int(m.group(1)), m.group(2), m.group(3)
                        # drop the range suffix: "pc_id [31:0]" -> "pc_id"
                        name = re.sub(r"\s*\[[^\]]*\]$", "", name).strip()
                        path_s = ".".join(scopes)
                        if path_s == scope:
                            ids.setdefault(vid, (name, width))
                elif line.startswith("$enddefinitions"):
                    in_defs = False
                continue
            if not line:
                continue
            if line[0] == "#":
                t = int(line[1:])
                times.append(t)
            elif line[0] in "01xXzZ":
                vid = line[1:]
                if vid in ids:
                    changes.setdefault(vid, []).append((t, line[0].lower()))
            elif line[0] in "bB":      # bVALUE id
                parts = line.split()
                if len(parts) == 2 and parts[1] in ids:
                    changes.setdefault(parts[1], []).append((t, parts[0][1:].lower()))
    return ids, changes


def fmt_bus(val, width):
    if any(c in val for c in "xz"):
        return "x" * max(1, (width + 3) // 4)
    try:
        return f"{int(val, 2):0{(width + 3) // 4}x}"
    except ValueError:
        return "?"


def render(ids, changes, tmax, title):
    lanes = []
    for name, kind in SHOW:
        vid = None
        for v, (n, _w) in ids.items():
            if n == name:
                vid = v
                break
        if vid is None or vid not in changes or not changes[vid]:
            continue
        lanes.append((name, kind, vid, changes[vid]))

    n = len(lanes)
    height = MARGIN_T + n * LANE_H + MARGIN_B
    sx = WIDTH / max(tmax, 1)

    def x_of(t):
        return NAME_W + t * sx

    # ---- time axis -------------------------------------------------------
    axis = [f'<line x1="{NAME_W}" y1="{MARGIN_T-8}" x2="{NAME_W+WIDTH}" '
            f'y2="{MARGIN_T-8}" stroke="#888"/>']
    # ticks every 50 ns (50000 fs? vcd time unit here = 1ps precision)
    step = 50000 if tmax > 120000 else 10000
    tt = 0
    while tt <= tmax:
        x = x_of(tt)
        axis.append(f'<line x1="{x:.1f}" y1="{MARGIN_T-12}" x2="{x:.1f}" '
                    f'y2="{height-MARGIN_B}" stroke="#ddd"/>')
        axis.append(f'<text x="{x+3:.1f}" y="{MARGIN_T-12}" class="tick">'
                    f'{tt//1000}ns</text>')
        tt += step

    body = []
    for li, (name, kind, vid, ch) in enumerate(lanes):
        y0 = MARGIN_T + li * LANE_H + LANE_PAD
        y1 = y0 + (LANE_H - 2 * LANE_PAD)
        yh, yl = y0 + 6, y1 - 6
        body.append(f'<text x="6" y="{(y0+y1)//2+4}" class="sig">'
                    f'{_html.escape(name)}</text>')
        body.append(f'<rect x="{NAME_W}" y="{y0}" width="{WIDTH}" '
                    f'height="{y1-y0}" class="lane"/>')
        if kind == "bit":
            pts = []
            prev_v, prev_t = None, 0
            # extend from time 0 with the first known value's predecessor = x
            seq = ch[:]
            start_v = seq[0][1]
            if seq[0][0] > 0:
                seq = [(0, "x" if start_v in "xz" else ("1" if start_v == "0" else "0"))] + seq \
                    if False else [(0, seq[0][1])] + seq
            else:
                seq = [(0, seq[0][1])] + seq
            # build step polyline
            last_v = seq[0][1]
            for (ct, cv) in seq[1:] + [(tmax, seq[-1][1])]:
                y_from = yh if last_v == "1" else yl
                y_to = yh if cv == "1" else yl
                pts.append((x_of(prev_t if prev_t else ct), y_from))
                pts.append((x_of(ct), y_from))
                if y_to != y_from:
                    pts.append((x_of(ct), y_to))
                prev_t = ct
                last_v = cv
            # simpler robust rebuild:
            pts = []
            last_v = seq[0][1]
            last_t = 0
            yv = lambda v: yh if v == "1" else (yl if v == "0" else (yh + yl) / 2)
            pts.append((x_of(0), yv(last_v)))
            for (ct, cv) in seq[1:]:
                if cv != last_v:
                    pts.append((x_of(ct), yv(last_v)))
                    pts.append((x_of(ct), yv(cv)))
                    last_v = cv
                last_t = ct
            pts.append((x_of(tmax), yv(last_v)))
            d = " ".join(f"{x:.1f},{y:.1f}" for x, y in pts)
            color = "#1a7f37" if name == "clk" else "#0b57d0"
            body.append(f'<polyline points="{d}" fill="none" stroke="{color}" '
                        f'stroke-width="1.6"/>')
        else:
            # bus: rectangles per value interval
            seq = [(0, ch[0][1])] + ch + [(tmax, ch[-1][1])]
            width_bits = None
            for v, (nm, w) in ids.items():
                if nm == name:
                    width_bits = w
                    break
            for i in range(len(seq) - 1):
                ct, cv = seq[i]
                nt = seq[i + 1][0]
                x0, x1 = x_of(ct), x_of(nt)
                if x1 - x0 < 1:
                    continue
                val = fmt_bus(cv, width_bits or 32)
                body.append(f'<rect x="{x0:.1f}" y="{y0+2}" width="{x1-x0-1:.1f}" '
                            f'height="{y1-y0-4}" class="bus"/>')
                if x1 - x0 > 26:
                    body.append(f'<text x="{(x0+x1)/2:.1f}" y="{(y0+y1)//2+4}" '
                                f'class="busval">{val}</text>')

    svg = (f'<svg width="{NAME_W+WIDTH}" height="{height}" '
           f'xmlns="http://www.w3.org/2000/svg">\n'
           + "\n".join(axis) + "\n" + "\n".join(body) + "\n</svg>")
    doc = f"""<!DOCTYPE html>
<html><head><meta charset="utf-8"><title>{_html.escape(title)}</title>
<style>
 body {{ font-family: ui-monospace, Menlo, Consolas, monospace; background:#fafafa;
        margin: 16px; color:#222; }}
 h1 {{ font-size: 16px; font-weight: 600; }}
 .sub {{ color:#666; font-size: 12px; margin-bottom: 10px; }}
 .sig {{ font-size: 12px; fill:#222; }}
 .tick {{ font-size: 10px; fill:#666; }}
 .lane {{ fill:#fff; stroke:#e2e2e2; }}
 .bus {{ fill:#eef3ff; stroke:#9db7f0; }}
 .busval {{ font-size: 11px; fill:#0b3d91; text-anchor: middle; }}
</style></head><body>
<h1>{_html.escape(title)}</h1>
<div class="sub">mini_plain_tb — 3 instructions (MUL, MULH, ALU_ADD), 10 ns clock.
 Generated by tb/scripts/vcd_to_html.py from the +vcd dump.</div>
{svg}
</body></html>"""
    return doc


def main():
    if len(sys.argv) < 3:
        print(__doc__, file=sys.stderr)
        return 2
    vcd, out = sys.argv[1], sys.argv[2]
    scope = None
    if "--scope" in sys.argv:
        scope = sys.argv[sys.argv.index("--scope") + 1]
    if scope is None:
        # prefer the testbench top scope (Verilator also dumps package
        # localparams and DUT/checker internals under their own scopes)
        names = []
        with open(vcd) as fh:
            for line in fh:
                line = line.strip()
                if line.startswith("$scope"):
                    names.append(line.split()[2])
        for pref in ("mini_plain_tb", "mini_tb", "tb_smoke"):
            if pref in names:
                scope = pref
                break
        if scope is None and names:
            scope = names[0]
    ids, changes = parse_vcd(vcd, scope)
    tmax = 0
    for ch in changes.values():
        if ch:
            tmax = max(tmax, ch[-1][0])
    # also times array (changes end may lag final $dumpflush)
    with open(vcd) as fh:
        for line in fh:
            if line.startswith("#"):
                tmax = max(tmax, int(line[1:]))
    doc = render(ids, changes, tmax, f"waveform: {vcd}")
    with open(out, "w") as fh:
        fh.write(doc)
    n = sum(1 for name, _k in SHOW if any(n2 == name for _v, (n2, _w) in ids.items()))
    print(f"vcd_to_html: scope={scope} signals={n} tmax={tmax} -> {out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
