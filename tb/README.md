# Test Plan

Run from the repository root with Linux Questa and Python 3.10+:

Run the complete regression.

```bash
bash tb/scripts/run_questa.sh all
```

Run only the standalone block tests.

```bash
bash tb/scripts/run_questa.sh blocks
```

Run the core and top system tests.

```bash
bash tb/scripts/run_questa.sh system
```

Run one named bench.

```bash
bash tb/scripts/run_questa.sh tb_acs
```

All simulations use a 5 ns clock where applicable. Tests are self-checking;
`$fatal` or a missing completion marker fails the runner. Work libraries, logs,
WLF files, oracle and hashes stay in fresh `experiment/tb_runs/questa_*` folders.
No simulator outputs are written inside the source folders.

`all` runs every bench listed below: 9 unit benches and 5 core/top benches.
It covers every 16-bit input word, all four top options, reset at E0-E12,
valid/ready stalls, credit limits, output hold, busy starts, and E10/II9.
The timed transaction sequences are directed or seeded; they are not an
exhaustive proof of every possible multi-frame timing sequence.

## Unit coverage

| ID | Bench | Cases checked |
|---|---|---|
| U01 | `tb_bmu` | All 4 received pairs, four Hamming distances |
| U02 | `tb_acs` | 676 PM/BM tuples with both sums <=7, 3-bit compare, tie A; 348 overflow tuples excluded from the contract; BM=3 included within bounds |
| U03 | `tb_pmu` | All 4096 metric words, init `[0,4,4,4]`, init over update, hold |
| U04 | `tb_piso` | All 16384 input words, pair order, load over shift, hold, zero flush, reset-independent load |
| U05 | `tb_re` | 4096 seeded model steps, compare four histories after eight-update flush, all decision bits, hold and reset-independent updates |
| U06 | `tb_controller` | Exact E0..E10 phase schedule, repeated frames, reset priority |
| U07 | `tb_iu` | Enabled/bypass paths, two-edge release, credit limits, busy gating, concurrent accept/transfer, reset |
| U08 | `tb_ou` | Two-slot FIFO scoreboard, push/pop together at occupancy 1 and 2, stall hold/order, reset and bypass |
| U09 | `tb_r_sync` | Retained standalone block: async assertion, R1/R2 release, bypass; top uses IU's integrated synchronizer |

U10 / tb_psu is retired: the user selected tail-00 termination and removed PSU.

## Core and top coverage

| ID | Bench | Cases checked |
|---|---|---|
| S01 | `tb_top` | All 64 six-bit payloads with tail 00: clean plus each single-bit channel error, 1088 generated input/output pairs in raw bypass mode |
| S02 | `tb_exhaustive` | All 65536 core received words against fixed-S0 integer oracle; tail 00, exact E10 latency, continuous II9, frame overlap, input change after accept, result hold and done pulse |
| S03 | `tb_options` | All 4 IU/OU combinations x 65536 words = 262144 output transfers; no-stall II9 window, long/toggling sink stalls, held valid, credit <=2, output hold and order |
| S04 | `tb_reset` | All 4 options, reset E0..E12, registered-core reset warmup (IU R3 / bypass R1), cancellation/restart, pending source/output, no ghost result |
| S05 | `tb_core_protocol` | 256 seeded frames, start pulses while busy ignored, input latching, E10 result and one-cycle done |

The frame contract is 6 payload bits followed by tail 00, encoded into 16 bits.
The output contains all 8 decoded bits, so data_out[1:0] must be 00. Tail zeros
apply to the source frame, not directly to the received encoded word.

Oracle generation enumerates every 16-bit received word with unlimited integer
metrics and unreachable states, using encoder equations for (7,5). It preserves
predecessor-A ties and always selects the final S0 history. A full search of the
64 legal encoded frames independently checks the decoded word's minimum Hamming
distance for all 65536 received words. It does not reuse finite-width RTL ACS
arithmetic. The runner generates oracle.hex, input.txt and output.txt inside
each fresh run. tb/data's older 1025 vectors are retained as historical inputs
and are not used by the current regression.

IU bypass requires externally synchronous reset and source capacity discipline.
OU bypass requires a sink that captures every result pulse. Tests obey these
contracts; invalid overflows or arbitrary asynchronous reset release in bypass
are not promised to work. X/Z inputs and arbitrary electrical timing violations
are outside the binary-word contract. Exhaustive words do not mean exhaustive
all possible temporal sequences; this suite is not formal or gate-level/SDF proof.

Fixed random seeds are declared in the relevant benches for reproducibility.

## Selected resetless baseline - 2026-11-14

PISO and RE data registers are intentionally not reset. PISO becomes defined
after load; RE history is checked after eight updates flush unknown prior bits.
Core result/valid/control and IU/OU remain reset. Integration reset tests still
check all E0..E12 cancellation/restart phases and prohibit ghost transactions.
RE remains the original 8-bit-history implementation; RE6 is experimental.

All 14 benches passed on WSL Questa Sim 2021.2_1 with zero compile errors and
warnings in `experiment/tb_runs/reset_re6_resetless_zhSs7qND/`. Selected RTL and
all bench hashes match this run. Current selection is recorded in
`verification/selected_baseline_20261114_resetless.json`; the earlier tail-00
and reset/RE6 experiment receipts remain historical evidence.

## Historical result

Before the tail-00 change, all 15 benches passed on Linux Questa Sim 2021.2_1, including an isolated copy
containing only the public folders and root README. Compilation reported zero
errors/warnings. See [the result receipt](results/questa_2021_2.json). This records
RTL simulation of the old free-endpoint design, not gate-level or physical
timing validation. Current-change evidence is recorded separately in
verification/tail00_s0_20261114.md.

Current ACS3/init-4/controller selection: only `tb_exhaustive` was run for this revision; PASS 65,536/65,536 on WSL Questa 2021.2_1, including widened candidate-bound checks. Updated unit benches have not been rerun. See `verification/acs3_controller_20261114_01.md`.

Current reset-FF revision: four executed benches are `tb_exhaustive`, `tb_core_protocol`, `tb_reset`, and `tb_options`; all PASS. Core protocol additionally checks the two-edge reset capture/abort, one-edge sampled release, no ghost result and restart across 11 phases. See `verification/reset_ff_20261114_01.md`.

User-adopted baseline: registered core reset, 2026-11-14. Current selection ledger: `verification/selected_baseline_20261114_reset_ff.json`. Four executed benches are listed above; promotion did not rerun tests.
