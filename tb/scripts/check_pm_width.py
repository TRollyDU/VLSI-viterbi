"""Exhaustive integer check of the current eight-step ACS3/init-4 model.

No simulator or third-party packages are required. This models the RTL
arithmetic contract; it does not parse RTL or prove its clock/control behavior.
"""

import argparse
import sys

# Keep this read-only check from creating __pycache__ beside the sources.
sys.dont_write_bytecode = True
from generate_oracle import decode


# For each destination: predecessor A/B, their encoded branch labels, new bit.
# State ordering and predecessor-A ties match rtl/viterbi.v and rtl/re.v.
EDGES = (
    (0, 1, 0b00, 0b11, 0),
    (2, 3, 0b10, 0b01, 0),
    (0, 1, 0b11, 0b00, 1),
    (2, 3, 0b01, 0b10, 1),
)
DISTANCE = tuple(tuple((rx ^ label).bit_count() for label in range(4))
                 for rx in range(4))


def check(penalty, references):
    pm_max = [0] * 8
    candidate_max = [0] * 8
    output_mismatches = metric_mismatches = 0
    first_mismatch = first_overflow = None

    for word, (expected_output, expected_metric) in enumerate(references):
        pm = [0, penalty, penalty, penalty]
        histories = [0] * 4
        for step, shift in enumerate(range(14, -1, -2)):
            distances = DISTANCE[(word >> shift) & 3]
            next_pm, next_histories = [], []
            for destination, (a, b, label_a, label_b, bit) in enumerate(EDGES):
                # Deliberately no &7: detect overflow before RTL truncation.
                ca = pm[a] + distances[label_a]
                cb = pm[b] + distances[label_b]
                candidate_max[step] = max(candidate_max[step], ca, cb)
                if max(ca, cb) > 7 and first_overflow is None:
                    first_overflow = (word, step + 1, destination, ca, cb)
                predecessor = b if cb < ca else a
                next_pm.append(min(ca, cb))
                next_histories.append(((histories[predecessor] << 1) | bit) & 255)
            pm, histories = next_pm, next_histories
            pm_max[step] = max(pm_max[step], *pm)

        output_bad = histories[0] != expected_output
        metric_bad = pm[0] != expected_metric
        output_mismatches += output_bad
        metric_mismatches += metric_bad
        if (output_bad or metric_bad) and first_mismatch is None:
            first_mismatch = (word, histories[0], expected_output,
                              pm[0], expected_metric)

    return {
        "penalty": penalty,
        "pm_max": pm_max,
        "candidate_max": candidate_max,
        "output_mismatches": output_mismatches,
        "metric_mismatches": metric_mismatches,
        "first_mismatch": first_mismatch,
        "first_overflow": first_overflow,
        "passed": (output_mismatches == metric_mismatches == 0
                   and max(penalty, *pm_max, *candidate_max) <= 7),
    }


def print_details(result):
    print(f"\nSelected initialization: [0, {result['penalty']}, "
          f"{result['penalty']}, {result['penalty']}]")
    print("Trellis step       " + " ".join(f"{step:>3}" for step in range(1, 9)))
    print("Max PM after min   " + " ".join(f"{n:>3}" for n in result['pm_max']))
    print("Max candidate      " + " ".join(f"{n:>3}" for n in result['candidate_max']))
    print(f"Output mismatches: {result['output_mismatches']}/65536")
    print(f"Final-S0 metric mismatches: {result['metric_mismatches']}/65536")
    oracle_ok = result['output_mismatches'] == result['metric_mismatches'] == 0
    fits = max(result['penalty'], *result['pm_max'], *result['candidate_max']) <= 7
    print(f"Matches true-infinity oracle: {'PASS' if oracle_ok else 'FAIL'}")
    print(f"Fits 3-bit PM/candidates: {'YES' if fits else 'NO'}")
    if result["first_mismatch"] is not None:
        word, actual, expected, metric, expected_metric = result["first_mismatch"]
        print(f"First mismatch: word=0x{word:04X}, output=0x{actual:02X}, "
              f"expected=0x{expected:02X}, metric={metric}, "
              f"expected_metric={expected_metric}")
    if result["first_overflow"] is not None:
        word, step, destination, ca, cb = result["first_overflow"]
        print(f"First value exceeding 3 bits (no Python overflow): word=0x{word:04X}, step={step}, "
              f"destination=S{destination}, candidate_A={ca}, candidate_B={cb}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--penalty", type=int, default=4,
                        help="any nonnegative integer penalty for S1/S2/S3 (default: 4)")
    parser.add_argument("--sweep", action="store_true",
                        help="also report all initial penalties 0..7")
    parser.add_argument("--require-3bit", action="store_true",
                        help="also require 3-bit fit for a successful exit status")
    args = parser.parse_args()
    if args.penalty < 0:
        parser.error("--penalty must be a nonnegative integer")

    print("Scope: K=3, (7,5), 8 steps, start S0, final S0, tie A.")
    print("Enumerating all 65536 received words; integer sums are not truncated.")
    print("Building independent unbounded-metric oracle...", flush=True)
    print("Oracle uses unreachable states (None), not a finite penalty of 999.")
    references = []
    for word in range(65536):
        output, _, _, metric = decode(word)
        references.append((output, metric))

    selected = None
    if args.sweep:
        print("\nInit  MaxPM  MaxCandidate  OutputMismatch  MetricMismatch  Fits3  ACS3")
        for penalty in range(8):
            result = check(penalty, references)
            fits = max(penalty, *result["pm_max"], *result["candidate_max"]) <= 7
            print(f"{penalty:>4}  {max(penalty, *result['pm_max']):>5}  "
                  f"{max(result['candidate_max']):>12}  "
                  f"{result['output_mismatches']:>14}  "
                  f"{result['metric_mismatches']:>14}  "
                  f"{'yes' if fits else 'no':>5}  "
                  f"{'PASS' if result['passed'] else 'FAIL'}", flush=True)
            if penalty == args.penalty:
                selected = result
        print("Sweep mismatches use untruncated integer arithmetic; overflow rows")
        print("do not predict the output of an actual wrapping 3-bit implementation.")
    if selected is None:
        selected = check(args.penalty, references)

    print_details(selected)
    print("This is a Python model check, not a new RTL/Questa simulation.")
    oracle_ok = selected['output_mismatches'] == selected['metric_mismatches'] == 0
    success = selected['passed'] if args.require_3bit else oracle_ok
    print("Exit status checks oracle agreement"
          + (" and 3-bit fit." if args.require_3bit else "; 3-bit fit is reported separately."))
    return 0 if success else 1


if __name__ == "__main__":
    sys.exit(main())
