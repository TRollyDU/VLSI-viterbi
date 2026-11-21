# Test plan: pulse interface, free endpoint

Contract: [FUNCTIONAL_SPEC.md](../FUNCTIONAL_SPEC.md), K=3, (7,5), initial S0,
eight information bits, no required tail, minimum-metric endpoint. ACS tie A;
endpoint ties prefer S0/S1/S2/S3. Top is `viterbi_top` with exactly `clk`, `rstn`,
`viterbi_enable`, `input_data[15:0]`, `output_data[7:0]`, `output_done`.

Nine SystemVerilog benches: seven leaf-block benches and two top-level benches.
The `viterbi` integration is exercised through the exact public top interface.
No IU/OU options or old architecture experiments are in the active suite.

| ID | Bench | Checked behavior |
|---|---|---|
| B01 | `tb_r_sync.sv` | Asynchronous assertion, two-clock release and reassertion |
| B02 | `tb_controller.sv` | E0-E10 enables, exactly eight metric/history updates, ignore busy starts E1-E10, reset priority |
| B03 | `tb_piso.sv` | All 16,384 stored words, pair order, load priority, hold and zero flush |
| B04 | `tb_bmu.sv` | All four input pairs; reconstruct metrics from parity/carries and compare against independent Hamming counts |
| B05 | `tb_butterfly.sv` | All 192 PM3/Hamming tuples, decisions, predecessor-A ties, sums; frame bounds checked separately |
| B06 | `tb_pmu.sv` | All 4,096 metric words, init `[0,4,4,4]` priority, update and hold |
| B07 | `tb_smu.sv` | Independent history model, eight-update flush, 4,096 final metric tuples, all endpoint/tie choices, result hold/reset |
| N01 | `tb_viterbi_exhaustive.sv` | All 65,536 received words plus 256 clean information bytes, E10, adjacent frames II11, changed input after accept, all eight widened candidate bounds, result hold and done pulse |
| N02 | `tb_viterbi_control.sv` | Fixed codeword **E2F6 -> A7** throughout: idle, busy enable at every E1-E10, immediate E11 restart, reset E0-E10, enable during R1-R3 warmup, no queued/ghost results |

The integer oracle uses true unreachable states and ascending-predecessor ties.
An independent search of all 256 encoded bytes checks minimum Hamming distance
for every received word. A separate init-bound audit compares the finite penalty
4 against the integer oracle over all 65,536 words; this is mathematical evidence,
not RTL simulation. Channel errors are tested against the decoder oracle: arbitrary
noise is not guaranteed to recover the original source byte.

## Commands

In a licensed Linux/WSL Questa environment, from this folder's parent:

```bash
bash tb/scripts/run_questa.sh all
bash tb/scripts/run_questa.sh blocks
bash tb/scripts/run_questa.sh exhaustive
bash tb/scripts/run_questa.sh control
```

The runner creates a fresh `experiment/tb_runs/smu_questa_*` directory and freezes
RTL, all nine TBs, scripts and oracle. It runs sequentially, requires simulator
success plus PASS markers and no fatal/error, and saves source hashes, UCDB,
merged DUT statement/branch/condition/expression/FSM coverage and HTML reports.
Functional PASS and code coverage percentages are separate results; report any
uncovered code explicitly. No SVA or UVM is required.

Hold external reset low across at least two rising edges. After release, R1/R2
release the synchronizer, R3 releases core readiness, and R4 is the earliest
acceptance. Reset cancels the current frame. Inputs during busy are discarded;
no enable queue exists. A result is registered at E10, with a one-cycle done
pulse. The next accepted frame is no earlier than E11. Temporal scenarios are
directed; this is not a formal proof of all possible timing sequences.

The old TBs and runner are preserved under
`experiment/smu_pulse_20261121/before/tb/` and `retired_tb/`. Historical receipts
remain unchanged; none are relabeled as evidence for this interface.
