module pmu (
    input            clk,
    input            init,
    input            update,
    input      [3:0] pm_new_s0,
    input      [3:0] pm_new_s1,
    input      [3:0] pm_new_s2,
    input      [3:0] pm_new_s3,

    output reg [3:0] pm_prev_s0,
    output reg [3:0] pm_prev_s1,
    output reg [3:0] pm_prev_s2,
    output reg [3:0] pm_prev_s3
);
    always @(posedge clk) begin
        if (init) begin
            pm_prev_s0 <= 4'd0;
            pm_prev_s1 <= 4'd15;
            pm_prev_s2 <= 4'd15;
            pm_prev_s3 <= 4'd15;
        end
        else if (update) begin
            pm_prev_s0 <= pm_new_s0;
            pm_prev_s1 <= pm_new_s1;
            pm_prev_s2 <= pm_new_s2;
            pm_prev_s3 <= pm_new_s3;
        end
    end

endmodule
