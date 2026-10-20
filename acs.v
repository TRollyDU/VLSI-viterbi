module acs (
    input [1:0] bm_A,
    input [1:0] bm_B,

    input [2:0] pm_prev_A,
    input [2:0] pm_prev_B,

    output [2:0] pm_new,
    output dec_out
);
    wire [2:0] sum_A;
    wire [2:0] sum_B;
    wire choose_B;

    // PMU initializes after two steps: every predecessor is reachable.
    // During the remaining six steps, finite PM <=5 and candidate <=7.
    assign sum_A = pm_prev_A + {1'b0, bm_A};
    assign sum_B = pm_prev_B + {1'b0, bm_B};
    assign choose_B = (sum_A > sum_B);

    assign dec_out = choose_B;
    assign pm_new = choose_B ? sum_B : sum_A;
endmodule
