"""Integer Viterbi oracle derived from encoder equations, without RTL helpers."""
import json
import sys
from pathlib import Path


def decode(word):
    metrics = [0, None, None, None]
    histories = [0] * 4
    survivor_max = candidate_max = 0
    for shift in range(14, -1, -2):
        received = (word >> shift) & 3
        new_metrics = [None] * 4
        new_histories = [0] * 4
        # Ascending predecessor order and strict improvement implement tie A.
        for state in range(4):
            if metrics[state] is None:
                continue
            m1, m2 = state >> 1, state & 1
            for bit in (0, 1):
                expected = ((bit ^ m1 ^ m2) << 1) | (bit ^ m2)
                destination = (bit << 1) | m1
                cost = metrics[state] + (received ^ expected).bit_count()
                candidate_max = max(candidate_max, cost)
                if new_metrics[destination] is None or cost < new_metrics[destination]:
                    new_metrics[destination] = cost
                    new_histories[destination] = ((histories[state] << 1) | bit) & 255
        metrics, histories = new_metrics, new_histories
        survivor_max = max(survivor_max, *(cost for cost in metrics if cost is not None))
    best = min(range(4), key=lambda state: metrics[state])
    return histories[best], survivor_max, candidate_max, metrics[best]


def main():
    data = Path(__file__).resolve().parents[1] / "data"
    output = Path(sys.argv[1])
    output.mkdir(parents=True, exist_ok=True)
    answers = []
    max_survivor = max_candidate = max_final_minimum = 0
    for word in range(65536):
        answer, survivor, candidate, final_minimum = decode(word)
        answers.append(answer)
        max_survivor = max(max_survivor, survivor)
        max_candidate = max(max_candidate, candidate)
        max_final_minimum = max(max_final_minimum, final_minimum)
    (output / "oracle.hex").write_text("".join(f"{value:02x}\n" for value in answers), encoding="ascii")
    inputs = [int(line, 2) for line in (data / "input.txt").read_text().splitlines() if line.strip()]
    expected = [int(line, 2) for line in (data / "output.txt").read_text().splitlines() if line.strip()]
    assert len(inputs) == len(expected) == 1025
    mismatches = sum(answers[word] != value for word, value in zip(inputs, expected))
    result = {
        "words": 65536,
        "vector_pairs": len(inputs),
        "vector_mismatches_against_oracle": mismatches,
        "max_finite_survivor": max_survivor,
        "max_finite_candidate": max_candidate,
        "max_final_minimum": max_final_minimum,
        "initial_state": 0,
        "endpoint": "free; minimum metric; lowest state wins ties",
        "acs_tie": "lowest predecessor state (A)",
    }
    (output / "oracle_summary.json").write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(result))
    assert mismatches == 0


if __name__ == "__main__":
    main()
