"""Independent integer trellis oracle, checked against all 256 encoded bytes."""
import json
from pathlib import Path
import sys


def encode(data):
    state = word = 0
    for shift in range(7, -1, -1):
        bit = data >> shift & 1
        m1, m2 = state >> 1, state & 1
        word = word << 2 | ((bit ^ m1 ^ m2) << 1) | (bit ^ m2)
        state = bit << 1 | m1
    return word


def decode(word):
    metrics, histories = [0, None, None, None], [0] * 4
    for shift in range(14, -1, -2):
        pair = word >> shift & 3
        nxt, paths = [None] * 4, [0] * 4
        for state in range(4):
            if metrics[state] is None:
                continue
            m1, m2 = state >> 1, state & 1
            for bit in (0, 1):
                expected = ((bit ^ m1 ^ m2) << 1) | (bit ^ m2)
                dest = bit << 1 | m1
                cost = metrics[state] + (pair ^ expected).bit_count()
                if nxt[dest] is None or cost < nxt[dest]:
                    nxt[dest] = cost
                    paths[dest] = (histories[state] << 1 | bit) & 255
        metrics, histories = nxt, paths
    endpoint = min(range(4), key=lambda state: metrics[state])
    return histories[endpoint], metrics[endpoint], endpoint


def main():
    out = Path(sys.argv[1])
    out.mkdir(parents=True, exist_ok=True)
    codebook = [encode(data) for data in range(256)]
    answers, endpoint_counts = [], [0] * 4
    for word in range(65536):
        answer, distance, endpoint = decode(word)
        assert (word ^ codebook[answer]).bit_count() == distance
        assert distance == min((word ^ code).bit_count() for code in codebook)
        answers.append(answer)
        endpoint_counts[endpoint] += 1
    assert all(answers[code] == data for data, code in enumerate(codebook))
    (out / 'oracle.hex').write_text(''.join(f'{data:02x}\n' for data in answers))
    (out / 'clean_codewords.hex').write_text(''.join(f'{code:04x}\n' for code in codebook))
    summary = dict(received_words=65536, clean_bytes=256, codebook_checks=65536,
                   initial_state=0, tail_required=False, endpoint='minimum metric; tie S0/S1/S2/S3',
                   predecessor_tie='A', endpoint_counts=endpoint_counts)
    (out / 'oracle_summary.json').write_text(json.dumps(summary, indent=2)+'\n')
    print(json.dumps(summary))


if __name__ == '__main__':
    main()
