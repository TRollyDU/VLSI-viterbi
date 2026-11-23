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
    wire hi_ge;
    wire low_gt;
    wire gap_ab;
    wire gap_ba;
    wire gt_zero;
    wire gt_plus2;
    wire gt_minus2;
    wire select_zero;
    wire select_plus2;
    wire select_minus2;
    wire compare_0;
    wire compare_1;
    wire [1:0] complement;
    wire [2:0] selected_pm_0;
    wire [2:0] selected_pm_1;
    wire [1:0] selected_metric_0;
    wire [1:0] selected_metric_1;

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
    assign hi_ge = ~hi_lt;
    assign low_gt = pm_a[0] & ~pm_b[0];
    assign gap_ab = pm_a[2] && !pm_b[2] && (pm_a[1] || !pm_b[1]);
    assign gap_ba = pm_b[2] && !pm_a[2] && (pm_b[1] || !pm_a[1]);
    assign gt_zero = hi_gt | (hi_ge & low_gt);
    assign gt_plus2 = gap_ab | (hi_gt & low_gt);
    assign gt_minus2 = hi_ge | (~gap_ba & low_gt);
    assign select_zero = metric[0];
    assign select_plus2 = ~metric[0] & ~metric[1];
    assign select_minus2 = ~metric[0] & metric[1];
    assign compare_0 = (select_zero & gt_zero) | (select_plus2 & gt_plus2) |
                   (select_minus2 & gt_minus2);
    assign compare_1 = (select_zero & gt_zero) | (select_plus2 & gt_minus2) |
                   (select_minus2 & gt_plus2);

    assign complement = {!(metric[1] || metric[0]), metric[0]};
    assign selected_pm_0 = dec_0 ? pm_b : pm_a;
    assign selected_pm_1 = dec_1 ? pm_b : pm_a;
    assign selected_metric_0 = dec_0 ? complement : metric;
    assign selected_metric_1 = dec_1 ? metric : complement;
    assign next_0 = add_hamming(selected_pm_0, selected_metric_0);
    assign next_1 = add_hamming(selected_pm_1, selected_metric_1);

    assign dec_0 = compare_0;
    assign dec_1 = compare_1;
endmodule
