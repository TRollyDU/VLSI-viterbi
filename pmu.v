module pmu (
    input clk,
    input init,
    input update,
    input [3:0] prefix_in,
    input [2:0] pm_new_s0,
    input [2:0] pm_new_s1,
    input [2:0] pm_new_s2,
    input [2:0] pm_new_s3,
    output reg [2:0] pm_prev_s0,
    output reg [2:0] pm_prev_s1,
    output reg [2:0] pm_prev_s2,
    output reg [2:0] pm_prev_s3
);
    // Each state has one unique path from S0 after the first two bits.
    // Balanced popcount keeps the four-bit input-to-PM path shallow.
    function [2:0] hamming4;
        input [3:0] mismatch;
        reg [1:0] hi, lo;
        begin
            hi = {1'b0, mismatch[3]} + {1'b0, mismatch[2]};
            lo = {1'b0, mismatch[1]} + {1'b0, mismatch[0]};
            hamming4 = {1'b0, hi} + {1'b0, lo};
        end
    endfunction

    // E0 initializes finite metrics after trellis steps 1 and 2.
    // Reset aborts the transaction in the controller; these internal registers
    // need no hardware reset and are unspecified until init is sampled.
    always @(posedge clk) begin
        if (init) begin
            pm_prev_s0 <= hamming4(prefix_in ^ 4'b0000);
            pm_prev_s1 <= hamming4(prefix_in ^ 4'b1110);
            pm_prev_s2 <= hamming4(prefix_in ^ 4'b0011);
            pm_prev_s3 <= hamming4(prefix_in ^ 4'b1101);
        end else if (update) begin
            pm_prev_s0 <= pm_new_s0;
            pm_prev_s1 <= pm_new_s1;
            pm_prev_s2 <= pm_new_s2;
            pm_prev_s3 <= pm_new_s3;
        end
    end
endmodule
