module pmu (
    input clk,
    input init,
    input update,
    input [2:0] pm_new_s0,
    input [2:0] pm_new_s1,
    input [2:0] pm_new_s2,
    input [2:0] pm_new_s3,
    output reg [2:0] pm_prev_s0,
    output reg [2:0] pm_prev_s1,
    output reg [2:0] pm_prev_s2,
    output reg [2:0] pm_prev_s3
);
    localparam [2:0] INITIAL_PENALTY = 3'd6;

    always @(posedge clk) begin
        if (init) begin
            pm_prev_s0 <= 3'd0;
            pm_prev_s1 <= INITIAL_PENALTY;
            pm_prev_s2 <= INITIAL_PENALTY;
            pm_prev_s3 <= INITIAL_PENALTY;
        end else if (update) begin
            pm_prev_s0 <= pm_new_s0;
            pm_prev_s1 <= pm_new_s1;
            pm_prev_s2 <= pm_new_s2;
            pm_prev_s3 <= pm_new_s3;
        end
    end
endmodule
