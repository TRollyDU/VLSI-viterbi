module pmu (
    input clk,
    input init,
    input [3:0] prefix_in,
    input [2:0] pm_new_s0,
    input [2:0] pm_new_s1,
    input [2:0] pm_new_s2,
    input [2:0] pm_new_s3,
    output reg [1:0] pm_prev_s0,
    output reg [1:0] pm_prev_s1,
    output reg [1:0] pm_prev_s2,
    output reg [1:0] pm_prev_s3
);
    // PM storage intentionally keeps the low 2 bits (modulo 4).
    // Acceptance is the fixed 1025-vector set; no global normalization.
    // E0: three two-bit distances, updated every clock without a load mux.
    // Complementary expected pairs have distance 2 minus the stored distance.
    reg [1:0] prefix_hi_00, prefix_lo_00, prefix_lo_10;
    wire [1:0] prefix_hi_11 = {~(prefix_hi_00[1] | prefix_hi_00[0]), prefix_hi_00[0]};
    wire [1:0] prefix_lo_11 = {~(prefix_lo_00[1] | prefix_lo_00[0]), prefix_lo_00[0]};
    wire [1:0] prefix_lo_01 = {~(prefix_lo_10[1] | prefix_lo_10[0]), prefix_lo_10[0]};
    function [1:0] hamming2;
        input [1:0] mismatch;
        begin
            hamming2 = {1'b0, mismatch[1]} + {1'b0, mismatch[0]};
        end
    endfunction
    // Both operands are Hamming distances in 0..2. A carry into bit 2
    // occurs only for 2+2, so that bit does not need a generic carry chain.
    function [2:0] add_distances;
        input [1:0] a, b;
        begin
            add_distances[0] = a[0] ^ b[0];
            add_distances[1] = a[1] ^ b[1] ^ (a[0] & b[0]);
            add_distances[2] = a[1] & b[1];
        end
    endfunction
    always @(posedge clk) begin
        prefix_hi_00 <= hamming2(prefix_in[3:2]);
        prefix_lo_00 <= hamming2(prefix_in[1:0]);
        prefix_lo_10 <= hamming2(prefix_in[1:0] ^ 2'b10);
    end

    // E1: init is delayed one clock from input acceptance. Sum the E0
    // partials to initialize finite PM after trellis steps 1 and 2.
    // Reset aborts the transaction in the controller; these internal registers
    // need no hardware reset. PM is valid after init and SELECT; intervening
    // updates may wrap or propagate X and are never consumed by valid ADD.
    always @(posedge clk) begin
        if (init) begin
            pm_prev_s0 <= add_distances(prefix_hi_00, prefix_lo_00);
            pm_prev_s1 <= add_distances(prefix_hi_11, prefix_lo_10);
            pm_prev_s2 <= add_distances(prefix_hi_00, prefix_lo_11);
            pm_prev_s3 <= add_distances(prefix_hi_11, prefix_lo_01);
        end else begin
            pm_prev_s0 <= pm_new_s0;
            pm_prev_s1 <= pm_new_s1;
            pm_prev_s2 <= pm_new_s2;
            pm_prev_s3 <= pm_new_s3;
        end
    end
endmodule
