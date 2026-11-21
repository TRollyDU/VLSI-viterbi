module butterfly (
    input [2:0] pm_a,
    input [2:0] pm_b,
    input [1:0] metric,
    output wire [2:0] next_0,
    output wire [2:0] next_1,
    output wire dec_0,
    output wire dec_1
);
    wire hi_gt;
    wire hi_lt;
    wire gap_ab;
    wire gap_ba;
    wire gt_zero;
    wire gt_plus2;
    wire gt_minus2;
    wire [1:0] complement;
    wire [2:0] candidate_a0;
    wire [2:0] candidate_b0;
    wire [2:0] candidate_a1;
    wire [2:0] candidate_b1;

    function [2:0] add_hamming;
        input [2:0] pm;
        input [1:0] bm;
        reg carry_0;
        begin
            // Hamming 0/1/2 has mutually exclusive bm[1] and bm[0].
            carry_0 = pm[0] & bm[0];
            add_hamming[0] = pm[0] ^ bm[0];
            add_hamming[1] = pm[1] ^ bm[1] ^ carry_0;
            add_hamming[2] = pm[2] ^ (pm[1] & (bm[1] | carry_0));
        end
    endfunction

    assign hi_gt = pm_a[2:1] > pm_b[2:1];
    assign hi_lt = pm_a[2:1] < pm_b[2:1];
    assign gap_ab = pm_a[2] && !pm_b[2] && (pm_a[1] || !pm_b[1]);
    assign gap_ba = pm_b[2] && !pm_a[2] && (pm_b[1] || !pm_a[1]);
    assign gt_zero = hi_gt || (!hi_lt && pm_a[0] && !pm_b[0]);
    assign gt_plus2 = gap_ab || (hi_gt && pm_a[0] && !pm_b[0]);
    assign gt_minus2 = !hi_lt || (!gap_ba && pm_a[0] && !pm_b[0]);
    assign dec_0 = metric[0] ? gt_zero :
                   (metric[1] ? gt_minus2 : gt_plus2);
    assign dec_1 = metric[0] ? gt_zero :
                   (metric[1] ? gt_plus2 : gt_minus2);

    assign complement = {!(metric[1] || metric[0]), metric[0]};
    assign candidate_a0 = add_hamming(pm_a, metric);
    assign candidate_b0 = add_hamming(pm_b, complement);
    assign candidate_a1 = add_hamming(pm_a, complement);
    assign candidate_b1 = add_hamming(pm_b, metric);
    assign next_0 = dec_0 ? candidate_b0 : candidate_a0;
    assign next_1 = dec_1 ? candidate_b1 : candidate_a1;
endmodule
