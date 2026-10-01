# tb/task_mul/ — فولدر التاسك بتاعي (MUL slice) — دليل المذاكرة

This folder is **the MUL slice only** — the code the MUL owner contributes to
the team's single environment (we are 5 owners; everything gets merged later
into ONE environment). Everything here compiles stand-alone; the other tasks
(ALU, sequences, predictor, ...) live with their owners.

> **ملاحظة مهمة:** الـ sequences مش تاسك خالص — اتشالت من الفولدَر ده بالكامل
> وفضلت **على جنب** في `tb/sequences/` لو احتجتها مستقبلاً (شغّالة أصلاً في
> البيئة). الفولدَر ده بقى = الانترفاس + الاجينت + المونيتور + السكور بورد +
> الريفرنس موديل + الكافر جروبس + الـ SVA + تعريفات الـ tests بس.

| Piece | File(s) | What it is |
|---|---|---|
| Interface | `interfaces/alu_mul_if.sv` | shared EX-stage probe interface (#6 of `tb_architecture/arch.jpg`), 46 input signals + `mon_cb` |
| Agent + monitor | `agents/mul_agent/*.sv` | `mul_txn`, `mul_agent_cfg`, `mul_monitor` (the brain), passive `mul_agent`, `mul_agent_pkg` |
| Scoreboard part | `env/mul_scoreboard_pkg.sv` | MUL-only scoreboard (result / latency / write-port / tag checks) — extracted from `tb/env/alu_mul_scoreboard.sv` |
| Reference model | `common/rv32m_ref_pkg.sv` + `common/rv32m_ref_selftest.sv` | golden RV32M functions (`rv32m_ref`, decode helpers) + self-test |
| Covergroups | `fcov/mul_cov.sv` + `fcov/mul_cov_pkg.sv` | the 6 MUL covergroups (op/operands, result, timing, regs, sequence, reset) |
| Assertions | `assertions/mul_sva.sv` | 17 MUL SVA + 8 covers (bind into the core during integration) |
| Tests doc | `tests/README_mul_tests.md` | MUL test definitions for the team env |

**Not in this folder (on purpose):** `alu_mul_bind.sv` (integration glue, added
when merging with the real RTL), the plain smoke checkers (RTL-bench only),
sequences (على جنب في `tb/sequences/`), and every ALU/DIV piece (other task).

---

# ١) شرح الفلو من الداتا بوك (ابدأ من هنا)

المصدر الرسمي موجود جوه الريبو نفسه:
- نص خام: `databook/_sources/pipeline.rst.txt`
- صفحة HTML: `databook/pipeline.html`
- صورة الخطيب: `databook/_images/CV32E40P_Pipeline.png`

## ١.١ المراحل الأربعة (4-stage in-order pipeline)

الداتا بوك بيقول حرفياً: **"CV32E40P has a 4-stage in-order completion
pipeline"** — كل تعليمة بتعدي بالترتيب من غير قفز:

```
   IF ──────► ID ──────► EX ──────► WB
  (جيب      (فك        (نفّذ)     (ارجع
  التعليمة)  التشفير)              الداتا)
```

- **IF (Instruction Fetch):** بيجيب التعليمة من الذاكرة عن طريق prefetch
  buffer (سعتها تعليمة واحدة كل cycle لو الذاكرة سابتة).
- **ID (Instruction Decode):** بيفك تشفير التعليمة **وبيقرأ operands من
  الريجستر فايل**. الكوميتمينت بتاع الجامبات بيحصل من هنا.
- **EX (Execute):** القلب بتاع التاسك بتاعنا — الداتا بوك: **"The EX stage
  contains the ALU, Multiplier and Divider"** + **"Multi-cycle instructions
  will stall this stage until they are complete"**. يعني المضاعف/القاسم
  كلهم هنا، وأي تعليمة multi-cycle بتعمل stall للـ EX لحد ما تخلص.
- **WB (Writeback):** الداتا بوك: **"Writes the result of Load instructions
  back to the register file"** — أي ردّ على التعليمة بتاعتنا بيتكتب من EX
  مباشرة (سطر تاني في الداتا بوك: **"The ALU, Multiplier and Divider
  instructions write back their result to the register file from the EX
  stage"**) — مش لازم تروح WB.

**Forwarding:** الداتا بوك: في path من نتايج ALU/Multiplier/Divider في EX
لعند flip-flops بتاعة ID → عشان كده تعليمة بعد المضاعف تستلم نتيجتها
**بدون أي cycle penalty** (مهمة لمربع hazard).

## ١.٢ جدول اللااتنسية الرسمي (من نفس الداتا بوك)

| النوع | الدورات | ملاحظة الداتا بوك |
|---|---|---|
| Integer (ADD/SUB/...) | 1 | RV32I base |
| **Multiplication — MUL** | **1** | "single-cycle 32-bit × 32-bit multiplier" |
| **Multiplication — MULH/MULHSU/MULHU** | **5** | "multiplications with **upper-word result** take 5 cycles" |
| **Division / Remainder** | **3..35** | بتعتمد على operand b (عدد leading zeros)؛ **أقصر حالة 3**، **أطول حالة 35 لما القاسم = 0** |

→ قياساتنا في التستبنك **مطابقة** لدول حرفياً (MUL_LATENCY=1,
MULH_LATENCY=5, div ∈ [3..35] — راجع `notes/mul_plan.md`).

## ١.٣ رحلة تعليمة MUL من أول ما تتنفذ لحد ما تخلص (cycle-by-cycle)

```
المرحلة   cycle    إيه اللي بيحصل على الـ wires
────────  ─────    ───────────────────────────────────────────────────
ID        N        id_valid=1 && is_decoding=1  ← ده الـ "TAG pulse":
                            pc_id + instr_id للتعليمتين دلوقتي معروفين
                            الديكودر بيولّد mult_en=1 + mult_operand_a/b
                            (بس في ID/EX register — لسه مش في EX)
EX        N+1      ← أول دورة لتعملتنا في EX (الـ monitor بيعمل start هنا
                            لأن mult_en اتكتب في الـ ID/EX reg)
  - MUL:  N+1      mult_ready=1 و ex_valid=1 في نفس الدورة (دورة واحدة!)
                            → rf_alu_we/waddr/wdata بتكتب x[rd] من EX
  - MULH*:N+1      dورة 1 من 5: mult_ready=0 (multicycle=1) → EX مقفول
           N+2..N+3           STEP0..STEP2: mult_multicycle=1 (3 دورات)
           N+5      FINISH: mult_ready=1 + ex_valid=1 → الكتابة بتحصل
```

- **التاب:** الـ pulse بتاع ID في الدورة N بيتبع التعليمة اللي **هتدخل EX في
  N+1** → عشان كده المونيتور بيسرّج pulse الدورة بعد ما يلقط التعليمة
  (الترتيب ده موضح في `mul_monitor.sv` — step 3 في `sample_cycle`).
- **الستال الخارجي:** لو `mult_ready=1` بس `ex_valid=0` → المضاعف خلص بس
  الـ EX ماسكها LSU/WB → ده `stall_cycles` (المونيتور بيفصله عن اللااتنسية
  الحقيقية: `mult_cycles = total - stall`).
- **ملاحظة MULH والريجستر فايل:** نتايج MUL بس اللي بيتكتب x[rd] (32 bit
  سفلية) — MULH* بياخد الـ upper word، والـ write-port في EX واحد.

## ١.٤ إشارة إن المضاعف اشتغل خالص (الـ tag/write rules اللي بنفحصها)

من الـ RTL والداتا بوك مع بعض، تعليمة RV32M بتكتب للريجستر فايل لما:
1. `ex_valid=1` (النتيجة valid في الدورة دي)، و
2. `rf_alu_we=1` و `waddr != 0` (كتابة لـ x0 بتنط)، و
3. `instr_rd == rf_alu_waddr[4:0]` (الريجستر المكتوب هو نفس اللي في
   التعليمتين — عشان نمسك أي bug في الـ tagging/forwarding)، و
4. الـ tag نفسه: `id_valid && is_decoding` في الدورة اللي قبل EX.

دي بالظبط الـ 4 عائلات فحوص في `env/mul_scoreboard_pkg.sv`.

---

# ٢) خطة المذاكرة ملف ملف (reading order)

| # | الملف | بتجاوب على إيه |
|---|---|---|
| ١ | `interfaces/alu_mul_if.sv` | كل إشارة في الـ interface ومعناها ومصدرها في الـ DUT (سجّل فيه table كامل) |
| ٢ | `common/rv32m_ref_pkg.sv` | تعريف الـ ISA نفسها: كل فيونكشن MUL/DIV إيه بيعمل + `rv32m_ref` = الـ golden model |
| ٣ | `common/rv32m_ref_selftest.sv` | تأكيد إن الريفرنس موديل نفسه صح (زوايا صعبة: ÷0، overflow، الأرقام السالبة) قبل ما نحاسب الداتا بوك بتاع الداتا بوك |
| ٤ | `agents/mul_agent/mul_txn.sv` | شكل الـ transaction: كل فليد إيه معناه (op/rs1/rs2/result/timing/tag) |
| ٥ | `agents/mul_agent/mul_monitor.sv` | **القلب**: إمتى يبدأ txn، إمتى يمشيه، إمتى يقفله، وقواعد الـ protocol (نفس شرح §١.٣ كود) |
| ٦ | `agents/mul_agent/mul_agent.sv` + `mul_agent_cfg.sv` | الاجينت = موصّل (passive): vif/cfg يوصلوا للمونيتور، `ap` يخرج للـ scoreboard/coverage |
| ٧ | `env/mul_scoreboard_pkg.sv` | الفحوص الأربعة (نتيجة، لااتنسية، write port، تاب) + القواعد اللي فوق بالظبط |
| ٨ | `fcov/mul_cov.sv` | إيه اللي لازم يتحقق تغطيته (op×نوعها، اللااتنسية، الريجسترات، تتابع التعليمات، reset) |
| ٩ | `assertions/mul_sva.sv` | نفس القواعد كـ assertions دائمة تشتغل في أي بناء (للمراجعة الشاملة) |
| ١٠ | `tests/README_mul_tests.md` | تعريفات الـ tests اللي الفريق هيكتبها |

(الترتيب ده = من "إيه هي نفس الحاجة" → "إزاي بتشتغل" → "إزاي بنفحصها" →
"إزاي بنقيس تغطيتها" → "إزاي بنثبتها أبديكتurally".)

---

# ٣) تشغيل البيئة (working environment)

```
tb/scripts/run_task_mul.sh          # Verilator: build (~4 min first time) + run -> PASS
```
The runner uses `tb/task_mul_env/` (demo env + top + `.f`), which compiles the
files **of this folder** directly — so what runs is exactly what you submit.

# ٤) Source of truth / sync

`interfaces/`, `agents/`, `common/`, `fcov/mul_cov.sv`, `assertions/`,
`tests/` are kept byte-identical to the integrated tree (`tb/interfaces`,
`tb/agents/mul_agent`, ...). Refresh them any time with:
```
tb/scripts/sync_task_mul.sh
```
(The script also **enforces** that `sequences/` stays OUT of this folder.)
(`env/mul_scoreboard_pkg.sv` and `fcov/mul_cov_pkg.sv` are deliverable-only
extractions — keep them in sync with the MUL half of
`tb/env/alu_mul_scoreboard.sv` by hand; the checks are documented in the file
header.)
