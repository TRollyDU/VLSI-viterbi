module acs (
    input [1:0] bm_a,
    input [1:0] bm_b,
    input [2:0] pm_prev_a,
    input [2:0] pm_prev_b,
    output wire [2:0] pm_new,
    output wire dec_out
);
    wire [3:0] candidate_a;
    wire [3:0] candidate_b;
    wire [3:0] selected_candidate;
    wire choose_b;

    assign candidate_a = {1'b0, pm_prev_a} + {2'b00, bm_a};
    assign candidate_b = {1'b0, pm_prev_b} + {2'b00, bm_b};
    assign choose_b = (candidate_b < candidate_a);
    assign selected_candidate = choose_b ? candidate_b : candidate_a;
    // Startup candidates can reach 9; the selected metric stays within 3 bits.
    assign pm_new = selected_candidate[2:0];
    assign dec_out = choose_b;
endmodule
