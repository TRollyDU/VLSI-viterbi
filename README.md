# Viterbi Decoder

Hard-decision Viterbi decoder: **K=3, rate 1/2, generators (7,5)**.
Each independent frame accepts 16 encoded bits and returns 8 decoded bits.
Processing starts at state S0, MSB pair first, with a free final state.
ACS ties choose predecessor A; final-state ties choose S0, S1, S2, then S3.

The selected baseline uses 3-bit path metrics initialized to `[0,6,6,6]`,
ordinary 4-bit ACS candidates, the original 8-bit RE histories, and the
PMU-to-PSU pipeline. Core latency is **10 clocks**, with **II=9 clocks**.
The PSU uses parallel comparisons.

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
|-- psu.v                      # Final state and output selection
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
|-- baseline_results/          # Measured area/timing summaries
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
Reset cancels pending work and output. With IU enabled, internal reset releases
after two rising edges; first acceptance is no earlier than the third edge.
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
All 15 benches passed on Linux Questa 2021.2_1, including the upload-only copy.
See [the test plan](tb/README.md) for coverage and individual tests.

## Run physical design (Linux)

Activate a LibreLane environment containing its supported tools. The measured
baseline used **LibreLane 3.0.14, Yosys 0.62, OpenROAD 2026-02-17**, and
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

## Results

Measured after routing at 5 ns across **9 corners** (nom/min/max RC x TT/SS/FF):

| Scope | Synthesis area (um2) | Routed standard-cell area (um2) | Worst setup (ns) | Worst hold (ns) |
|---|---:|---:|---:|---:|
| Core `viterbi` | 7289.49 | 8379.29 | -0.012601 | +0.078179 |
| Full `top` | 8805.95 | 10009.60 | +0.347571 | +0.169368 |

Full setup/hold pass at 200 MHz. Core has one setup violation on external reset
to an RE register; core register-to-register paths pass. Both have zero hold,
slew and capacitance violations, zero route/Magic DRC and LVS errors, and one
remaining fanout violation. The core exceeds the 7000 um2 target: this is the
selected development baseline, not completed PPA signoff. Area excludes filler.

Receipts: [core](pd_config/baseline_results/core.json),
[full](pd_config/baseline_results/full.json).
RTL simulation at a 5 ns clock does not establish physical timing closure.
APB is not implemented. Formal, gate-level/SDF and hardware validation are not claimed.
