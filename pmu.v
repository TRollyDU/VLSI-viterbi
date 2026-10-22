module pmu (
    input clk,
    input init,
    input pm_write_en,
    input [1:0] first_pair_in, // codeword_in[15:14]
    input [2:0] pm_new_s0,
    input [2:0] pm_new_s1,
    input [2:0] pm_new_s2,
    input [2:0] pm_new_s3,
    output reg [1:0] pm_prev_s0,
    output reg [1:0] pm_prev_s1,
    output reg [1:0] pm_prev_s2,
    output reg [1:0] pm_prev_s3
);
    // E0 samples pair 1. E1 initializes the two states reachable from S0.
    // S1/S3 are placeholders; ACS forces valid predecessors on trellis step 2.
    reg [1:0] first_pair_q;
    always @(posedge clk)
        first_pair_q <= first_pair_in;

    wire [1:0] first_pm0 = {1'b0, first_pair_q[1]} + {1'b0, first_pair_q[0]};
    wire [1:0] first_pm2 = {1'b0, ~first_pair_q[1]} + {1'b0, ~first_pair_q[0]};
    always @(posedge clk) begin
        if (init) begin
            pm_prev_s0 <= first_pm0;
            pm_prev_s1 <= 2'b00;
            pm_prev_s2 <= first_pm2;
            pm_prev_s3 <= 2'b00;
        end else if (pm_write_en) begin
            pm_prev_s0 <= pm_new_s0[1:0];
            pm_prev_s1 <= pm_new_s1[1:0];
            pm_prev_s2 <= pm_new_s2[1:0];
            pm_prev_s3 <= pm_new_s3[1:0];
        end
    end
endmodule
