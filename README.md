# Viterbi Decoder

Hard-decision Viterbi, K=3, rate 1/2, generators (7,5). Each independent frame
starts in S0 and decodes 16 received bits into eight information bits, MSB pair
first. There is no mandatory tail. SMU combines RE histories and a PSU that
selects the minimum-metric final state; ties prefer S0/S1/S2/S3. ACS ties prefer A.

The current development RTL implements [FUNCTIONAL_SPEC.md](FUNCTIONAL_SPEC.md).
Historical tail-00/fixed-S0 and IU/OU receipts do not describe this interface.
Current validation and physical results belong in verification/; no new PPA
baseline selection is implied by implementation or by flow completion.
See the [latest RTL validation report](verification/merge_top_20261121.md)
and the [preceding revision's PPA report](verification/smu_pulse_20261121.md).

## Interface

Top module: `viterbi_top`.

| Port | Direction | Width |
|---|---|---:|
| clk | input | 1 |
| rstn | input | 1 |
| viterbi_enable | input | 1 |
| input_data | input | 16 |
| output_data | output | 8 |
| output_done | output | 1 |

An enable pulse while idle captures the frame at E0. Inputs and enable pulses
at E1-E10 are ignored. The registered result and one-cycle done pulse appear at
E10; the next frame may be accepted at E11. Output data holds between results.
There is no input queue, IU/OU, valid/ready interface or backpressure.

External active-low reset feeds the two-FF asynchronous-assert/synchronous-release
r_sync, then the retained core reset FF. Public done/start are masked during
reset. Hold reset low across at least two rising edges. After release, R1/R2
release the synchronizer, R3 releases core readiness and R4 is the first possible
acceptance. Reset aborts pending work. Datapaths become valid through frame load
and eight updates; only control and output registers need reset.

## Files

```text
rtl/
|-- viterbi_top.v
|-- r_sync.v
|-- controller.v
|-- piso14_7.v
|-- bmu.v
|-- acs.v
|-- butterfly.v
|-- pmu.v
|-- smu.v
tb/
|-- README.md
|-- testplan.xlsx
|-- tb_*.sv
|-- scripts/
pd_config/
|-- full/config.json
|-- full/viterbi_pnr.sdc
|-- full/viterbi_signoff.sdc
|-- run_librelane.sh
```

## Simulation

Latest canonical RTL validation (2026-11-21): **all nine Questa benches PASS**,
including all 65,536 received words, 256 clean information bytes and fixed-data
control/reset scenarios. Strict Verilator --Wall is clean; RTL/TB compilation
has zero errors/warnings. E10/II11 is retained. The new `acs` module wraps the
two original `butterfly` instances; `viterbi_top` connects only to `acs` for ACS
processing. This hierarchy supports later macro integration.

The former `viterbi` core is merged into `viterbi_top`; only one integration
module remains. Reset synchronization and the registered core-reset boundary
are retained. The legacy `pd_config/core/` configuration now targets the same
integrated top, including r_sync; it no longer measures a separate core.

Latest tested source snapshot: `smu_questa_RBfHVCxE`. Design-unit coverage is
100%; per-instance coverage is 93.50%. Source hashes and results are recorded
in [the validation receipt](verification/merge_top_20261121.json).

No layout was rerun for this merged-top revision. Earlier PPA and the separate
C|SA experiments are historical/trial evidence, not PPA for this RTL revision.

Use licensed Questa in Linux/WSL with Python 3.10+ and Bash. All nine benches
are SystemVerilog: seven leaf blocks, one exhaustive top test and one fixed-data
control test. See [the test plan](tb/README.md) and [Excel Vplan](tb/testplan.xlsx).

```bash
bash tb/scripts/run_questa.sh all
```

The runner freezes sources into a fresh experiment/tb_runs/smu_questa_* folder,
checks exits and PASS/error markers, and saves hashes, UCDB and coverage reports.
Standalone and integrated code coverage are reported with their actual scopes.
Simulation at 5 ns does not establish STA closure.

## Physical flow

Activate the LibreLane environment and select an available compatible PDK cache.
The full config targets the exact viterbi_top interface at 5 ns. Both SDC files
constrain data/enable inputs and output_data/output_done; only external rstn to
asynchronous reset pins is excepted. Internal synchronized reset paths stay timed.

```bash
bash pd_config/run_librelane.sh
```

The script freezes RTL/config/SDC under experiment/pd_runs/ and invokes:

```bash
librelane --overwrite --run-tag lastest <frozen-full-config.json>
```

Read area, worst setup/hold and power from the run's final metrics and raw reports.
The area requirement applies to core; report the integrated top scope explicitly.
Power needs a stated corner and activity model. Default-activity estimates are
not measured workload power. Historical baseline_results and Cadence scripts
are retained for traceability and are outside the current one-flow procedure.
