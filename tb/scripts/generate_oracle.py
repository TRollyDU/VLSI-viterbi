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
    return histories[0], survivor_max, candidate_max, metrics[0]


def encode(frame):
    """Encode eight source bits MSB first, starting in S0, using (7,5)."""
    state = word = 0
    for shift in range(7, -1, -1):
        bit = (frame >> shift) & 1
        m1, m2 = state >> 1, state & 1
        pair = ((bit ^ m1 ^ m2) << 1) | (bit ^ m2)
        word = (word << 2) | pair
        state = (bit << 1) | m1
    return word, state


def main():
    output = Path(sys.argv[1])
    output.mkdir(parents=True, exist_ok=True)
    answers = []
    max_survivor = max_candidate = max_final_s0 = 0
    codebook = [encode(payload << 2)[0] for payload in range(64)]
    for word in range(65536):
        answer, survivor, candidate, final_s0 = decode(word)
        assert answer & 3 == 0, (word, answer)
        assert encode(answer)[1] == 0
        # Independent full codebook search checks optimality, without trellis helpers.
        distance = min((word ^ encoded).bit_count() for encoded in codebook)
        assert (word ^ encode(answer)[0]).bit_count() == distance == final_s0
        answers.append(answer)
        max_survivor = max(max_survivor, survivor)
        max_candidate = max(max_candidate, candidate)
        max_final_s0 = max(max_final_s0, final_s0)
    (output / "oracle.hex").write_text("".join(f"{value:02x}\n" for value in answers), encoding="ascii")
    inputs, expected = [], []
    for payload in range(64):
        frame = payload << 2
        encoded, final_state = encode(frame)
        assert final_state == 0
        # One clean frame and each of the sixteen single-bit channel errors.
        for mask in [0] + [1 << bit for bit in range(16)]:
            inputs.append(encoded ^ mask)
            expected.append(frame)
    assert len(inputs) == len(expected) == 1088
    (output / "input.txt").write_text("".join(f"{v:016b}\n" for v in inputs), encoding="ascii")
    (output / "output.txt").write_text("".join(f"{v:08b}\n" for v in expected), encoding="ascii")
    mismatches = sum(answers[word] != value for word, value in zip(inputs, expected))
    result = {
        "words": 65536,
        "vector_pairs": len(inputs),
        "vector_mismatches_against_oracle": mismatches,
        "max_finite_survivor": max_survivor,
        "max_finite_candidate": max_candidate,
        "max_final_s0": max_final_s0,
        "initial_state": 0,
        "endpoint": "fixed S0; six payload bits followed by tail 00",
        "output": "eight decoded bits including two tail zeros",
        "codebook_optimality_checks": 65536,
        "clean_payloads": 64,
        "single_bit_error_vectors": 1024,
        "acs_tie": "lowest predecessor state (A)",
    }
    (output / "oracle_summary.json").write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(result))
    assert mismatches == 0


if __name__ == "__main__":
    main()
