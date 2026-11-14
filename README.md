# Viterbi Decoder

Hard-decision Viterbi decoder: **K=3, rate 1/2, generators (7,5)**.
Each independent frame accepts 16 encoded bits and returns 8 decoded bits.
Processing starts and ends at state S0, MSB pair first. Each source frame is
6 payload bits followed by tail `00`; all 8 decoded bits are returned.
ACS ties choose predecessor A. The fixed S0 endpoint replaces the PSU.

The selected baseline uses 3-bit path metrics initialized to `[0,4,4,4]`,
3-bit ACS candidates, the original 8-bit RE histories, and the
registered S0 output. Core latency is **10 clocks**, with **II=9 clocks**.

Selected on **2026-11-14**: resetless PISO/RE datapaths, idle PISO preload,
a six-FF controller, and one synchronous core reset input FF. Explicit RE6
compression is not selected. Current RTL hashes match the four passing Questa
benches and both measured P&R runs. Selection and hashes:
[baseline ledger](verification/selected_baseline_20261114_reset_ff.json).

## Files

```text
README.md
rtl/                           # Synthesizable Verilog
|-- top.v                      # IU -> core -> OU
|-- iu.v                       # Handshake, credit, reset synchronizer
|-- ou.v                       # Two-entry output buffer
|-- viterbi.v                  # Core integration
|-- controller.v               # Frame schedule
|-- piso14_7.v                 # Input pair shift register
|-- bmu.v                      # Branch metrics
|-- acs.v                      # Add, compare, select
|-- pmu.v                      # Path metrics
|-- re.v                       # Survivor histories
|-- r_sync.v                   # Legacy standalone reset block

tb/                            # Verification
|-- README.md                  # Test plan
|-- tb_*.sv, tb_top.v          # Unit and system benches
|-- data/                      # Input/output vectors
|-- results/                   # Questa result summary
|-- scripts/
    |-- run_questa.sh          # Linux regression runner
    |-- generate_oracle.py     # Independent integer oracle

pd_config/                     # LibreLane setup
|-- core/                      # Core config and 5 ns SDC
|-- full/                      # Full top config and 5 ns SDC
|-- baseline_results/          # Current selected core/full results
|-- selected_results/          # Historical resetless area/timing summaries
|-- run_librelane.sh           # Linux flow runner
|-- report_metrics.py          # Result printer
|-- genus.tcl                  # Optional Cadence Genus script
`-- script_innovus.tcl         # Optional Cadence Innovus script
```

## Interface

`top` uses `clk`, active-low `rst_n`, `in_valid/in_ready`,
`codeword_in[15:0]`, `out_valid/out_ready`, and `data_out[7:0]`.
Transfers occur at rising edges with both valid and ready high.
Hold input valid/data until accepted; buffered output remains stable until read.

Both parameters default to 1:

| Parameter | Enabled | Disabled |
|---|---|---|
| `ENABLE_IU` | Handshake/credit and two-FF async-assert/sync-release reset synchronization | Both bypassed; source must provide valid synchronous reset and one-cycle start pulses only when ready |
| `ENABLE_OU` | Two-entry output buffer with backpressure | Direct done/result pulse; sink must capture every pulse, normally with `out_ready=1` |

With IU disabled, the source must also prevent output-buffer overflow. Enable
both IU and OU for general backpressure. IU credit limits pending frames to two.
Hold reset low across at least two rising edges so the core reset register
and its consumers both reset. Reset cancels pending work and output. With IU
enabled, its synchronizer releases after R2, core readiness appears after R3,
and first acceptance is no earlier than R4. With IU disabled, core readiness
appears after the first sampled high edge R1; earliest acceptance is R2.
The added core FF is a synchronous timing stage, not an asynchronous-reset
synchronizer. Direct core reset assertion/release is sampled, not combinational.
With OU enabled, output valid appears 11 clocks after input acceptance; earliest
output transfer is at clock 12. Stalls can increase transaction intervals.

## Run simulation (Linux)

Requirements: licensed Questa with `vlib`, `vmap`, `vlog`, `vsim` on `PATH`,
Bash, and Python 3.10+. Set your license environment as required by your installation.
From the repository root:

Run all unit and system tests.

```bash
bash tb/scripts/run_questa.sh all
```

Run only the block tests.

```bash
bash tb/scripts/run_questa.sh blocks
```

Run one named test.

```bash
bash tb/scripts/run_questa.sh tb_options
```

The runner creates a fresh `experiment/tb_runs/questa_*` directory containing
logs, waveforms, source hashes, and `summary.txt`. It runs tests sequentially,
checks exit status and PASS markers, and returns nonzero on failure.
The selected revision passed four benches on WSL Questa 2021.2_1:
`tb_exhaustive`, `tb_core_protocol`, `tb_reset`, and `tb_options`, with zero
compile errors/warnings. They cover 65,536 core received words, 262,144 top
transfers across all four IU/OU modes, E10/II9, candidate bounds, stalls,
credits, output hold and registered-reset capture/abort/restart. The remaining
benches were not rerun for this revision.
See [the test plan](tb/README.md) for coverage and individual tests.

## Run physical design (Linux)

Activate a LibreLane environment containing its supported tools. The measured
baseline used **LibreLane 3.0.14, Yosys 0.62, OpenROAD dcf36133**, and
**sky130A / sky130_fd_sc_hd**, PDK revision
`0fe599b2afb6708d281543108caf8310912f54af`.
Install/select that PDK revision first; the runner uses the installed PDK and
does not download or switch it automatically.

Point LibreLane to a PDK root that contains the selected sky130A revision.

```bash
export PDK_ROOT=/path/to/pdk_root
```

Run the core and full top flows. Use `core` or `full` to run one scope.

```bash
bash pd_config/run_librelane.sh both
```

Runs are created under `experiment/pd_runs/baseline_*`. Each run freezes RTL,
config and SDC inputs before synthesis. Read `pd/<scope>/console.log`,
`pd/<scope>/runs/baseline_5ns/final/metrics.json`, and the printed metric summary.
Both configurations use **5 ns, hierarchy keep, DELAY 0**. Full enables IU/OU;
core-only excludes both wrappers. Core SDC retains the measured falling-edge
external-reset release assumption. Do not change exceptions just to hide failures.

Genus and Innovus scripts are optional user-provided scripts. They require
external library, LEF, and MMMC inputs; the measurements below use LibreLane.

## Selected baseline results - 2026-11-14

The selected core reset input register samples `rst_n` into `core_reset_n`.
All core reset consumers use that registered signal; raw `rst_n` only drives
the added FF's D input. Hold reset low over at least two rising edges. Reset
release readiness is delayed one cycle; E10/II9 from frame acceptance is retained.
Idle-preloaded PISO, ACS3/init-4 and the original resetless RE are unchanged.

WSL Questa 2021.2_1 passed four benches: all 65,536 core received words,
256 seeded core protocol frames plus registered-reset capture/abort/restart,
reset/restart in all four IU/OU modes, and 262,144 top transfers across four
modes with stalls/credits/output hold. Compilation had zero errors/warnings.
Other benches were not rerun.

LibreLane P&R at 5 ns, fanout limit 100, worst over nine RC/PVT corners:

| Scope | Synthesis area (um2) | Routed standard-cell area (um2) | Worst setup (ns) | Worst hold (ns) |
|---|---:|---:|---:|---:|
| core | 5500.28 | 6396.13 | +0.311902 | +0.082320 |
| full | 7006.72 | 7933.86 | +0.184712 | +0.134800 |

core: setup/hold violations 0/0; slew/cap/fanout 0/0/0; route/Magic DRC/LVS 0/0/0.
full: setup/hold violations 0/0; slew/cap/fanout 0/0/0; route/Magic DRC/LVS 0/0/0.

Core meets the **7000 um2** area target. Both scopes meet setup/hold at
200 MHz across all nine corners; the listed electrical/DRC/LVS checks have
zero violations. Five P&R lint warnings remain per scope. Complete
manufacturing signoff is not claimed.

Current baseline receipts: [core](pd_config/baseline_results/core.json),
[full](pd_config/baseline_results/full.json). See [validation](verification/reset_ff_20261114_01.md)
and [baseline selection](verification/selected_baseline_20261114_reset_ff.md).

Earlier results remain historical: [2026-11-10 receipts](verification/historical_baseline_results_20261110/core.json),
[resetless trial](verification/reset_re6_20261114_01.md),
[ACS3/init-4](verification/acs3_controller_pnr_20261114_01.md),
[fanout-100](verification/acs3_fanout100_pnr_20261114_01.md), and
[PISO preload without reset FF](verification/piso_preload_20261114_01.md).
Files in `pd_config/selected_results/` retain the older resetless measurements.

APB is not implemented. Formal, gate-level/SDF, activity-based power and
hardware validation are not claimed.
