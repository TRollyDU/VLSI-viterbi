module acs (
    input [1:0] bm_a,
    input [1:0] bm_b,
    input [2:0] pm_prev_a,
    input [2:0] pm_prev_b,
    output wire [2:0] pm_new,
    output wire dec_out
);
    wire [2:0] candidate_a;
    wire [2:0] candidate_b;
    wire [2:0] selected_candidate;
    wire choose_b;

    assign candidate_a = pm_prev_a + {1'b0, bm_a};
    assign candidate_b = pm_prev_b + {1'b0, bm_b};
    assign choose_b = (candidate_b < candidate_a);
    assign selected_candidate = choose_b ? candidate_b : candidate_a;
    // The eight-step PMU init-4 schedule keeps both candidates within 0..7.
    assign pm_new = selected_candidate;
    assign dec_out = choose_b;
endmodule
