module acs (
    input clk,
    input [1:0] bm_A,
    input [1:0] bm_B,

    input [1:0] pm_prev_A,
    input [1:0] pm_prev_B,

    output [2:0] pm_new,
    output dec_out
);
    reg [2:0] sum_A;
    reg [2:0] sum_B;
    wire choose_B;

    // PMU initializes after two steps: every predecessor is reachable.
    // User acceptance: the 1025 input.txt/output.txt pairs, ZERO_TAIL=1.
    // Stored PM is 2 bits; ADD candidates remain 3 bits (PM+BM <=5).
    // Run every clock: candidates from intervening phases are discarded.
    // The first valid ADD overwrites old/X candidates before valid SELECT.
    always @(posedge clk) begin
        sum_A <= pm_prev_A + {1'b0, bm_A};
        sum_B <= pm_prev_B + {1'b0, bm_B};
    end
    // SELECT stage terminates at the PMU and decision registers in top.
    // Direct unsigned min: upper PM bits do not depend on candidate bit 0.
    wire hi_lt = sum_A[2:1] < sum_B[2:1];
    wire hi_gt = sum_A[2:1] > sum_B[2:1];
    wire hi_eq = sum_A[2:1] == sum_B[2:1];
    assign choose_B = hi_gt | (hi_eq & sum_A[0] & ~sum_B[0]);
    assign dec_out = choose_B;
    assign pm_new[2] = sum_A[2] & sum_B[2];
    assign pm_new[1] = (sum_A[1] & sum_B[1]) |
                      (sum_A[1] & ~sum_A[2] & sum_B[2]) |
                      (sum_B[1] & sum_A[2] & ~sum_B[2]);
    assign pm_new[0] = (sum_A[0] & sum_B[0]) |
                      (sum_A[0] & hi_lt) | (sum_B[0] & hi_gt);
endmodule
