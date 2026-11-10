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

Run the PSU, core, and top system tests.

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

`all` runs every bench listed below: 10 unit benches and 5 core/top benches.
It covers every 16-bit input word, all four top options, reset at E0-E12,
valid/ready stalls, credit limits, output hold, busy starts, and E10/II9.
The timed transaction sequences are directed or seeded; they are not an
exhaustive proof of every possible multi-frame timing sequence.

## Unit coverage

| ID | Bench | Cases checked |
|---|---|---|
| U01 | `tb_bmu` | All 4 received pairs, four Hamming distances |
| U02 | `tb_acs` | All 1024 PM/BM tuples, 4-bit candidate compare, tie A, 3-bit selected slice; BM=3 included as an interface stress case |
| U03 | `tb_pmu` | All 4096 metric words, init `[0,6,6,6]`, init over update, hold |
| U04 | `tb_piso` | All 16384 input words, pair order, load over shift, hold, zero flush, reset priority |
| U05 | `tb_re` | 4096 seeded model checks, all decision bits, four histories, hold and reset |
| U06 | `tb_controller` | Exact E0..E10 phase schedule, repeated frames, reset priority |
| U07 | `tb_iu` | Enabled/bypass paths, two-edge release, credit limits, busy gating, concurrent accept/transfer, reset |
| U08 | `tb_ou` | Two-slot FIFO scoreboard, push/pop together at occupancy 1 and 2, stall hold/order, reset and bypass |
| U09 | `tb_r_sync` | Retained standalone block: async assertion, R1/R2 release, bypass; top uses IU's integrated synchronizer |
| U10 | `tb_psu` | All 4096 metric tuples, lowest-state ties, arbitrary history bytes, registered output, hold/reset priority |

## Core and top coverage

| ID | Bench | Cases checked |
|---|---|---|
| S01 | `tb_top` | 1025 supplied input/output vectors in raw bypass mode |
| S02 | `tb_exhaustive` | All 65536 core input words against independent integer oracle; exact E10 latency, continuous II9, frame overlap, input change after accept, result hold and done pulse |
| S03 | `tb_options` | All 4 IU/OU combinations x 65536 words = 262144 output transfers; no-stall II9 window, long/toggling sink stalls, held valid, credit <=2, output hold and order |
| S04 | `tb_reset` | All 4 options, reset E0..E12, R2 warmup, cancellation/restart, pending source/output, no ghost result |
| S05 | `tb_core_protocol` | 256 seeded frames, start pulses while busy ignored, input latching, E10 result and one-cycle done |

Oracle generation enumerates every 16-bit received word with unlimited integer
metrics and unreachable states, using encoder equations for (7,5). It preserves
predecessor-A and lowest-endpoint tie order, and checks the 1025 supplied vectors.
It does not call RTL helpers or reuse finite-width ACS arithmetic.

IU bypass requires externally synchronous reset and source capacity discipline.
OU bypass requires a sink that captures every result pulse. Tests obey these
contracts; invalid overflows or arbitrary asynchronous reset release in bypass
are not promised to work. X/Z inputs and arbitrary electrical timing violations
are outside the binary-word contract. Exhaustive words do not mean exhaustive
all possible temporal sequences; this suite is not formal or gate-level/SDF proof.

Fixed random seeds are declared in the relevant benches for reproducibility.

## Observed result

All 15 benches passed on Linux Questa Sim 2021.2_1, including an isolated copy
containing only the public folders and root README. Compilation reported zero
errors/warnings. See [the result receipt](results/questa_2021_2.json). This records
RTL simulation, not gate-level or physical timing validation.
