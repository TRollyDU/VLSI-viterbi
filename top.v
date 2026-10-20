// K=3, R=1/2, (7,5), two precomputed steps, known zero-tail final S0.
module top (
    input clk, 
    input rst_n,
    input in_valid,
    input [15:0] codeword_in,
    output reg out_valid,
    output reg [7:0] data_out
);

    // Source protocol: pulse in_valid for one clock. After out_valid rises,
    // the next pulse may be accepted on the third following rising edge.

    // Control signals.
    wire step_en;
    wire reg_ex_en;
    wire output_en;

    // Received pair and branch metrics.
    wire [1:0] queued_pair;
    wire [1:0] prefetch_pair;
    wire [1:0] bm_00_next, bm_11_next, bm_10_next, bm_01_next;
    // Eight trellis branches use four distinct Hamming distances.
    reg [1:0] bm_00, bm_11, bm_10, bm_01;

    // Current and selected path metrics.
    wire [2:0] pm_s0;
    wire [2:0] pm_s1;
    wire [2:0] pm_s2;
    wire [2:0] pm_s3;
    wire [2:0] next_s0;
    wire [2:0] next_s1;
    wire [2:0] next_s2;
    wire [2:0] next_s3;

    wire d0;
    wire d1;
    wire d2;
    wire d3;
    reg [3:0] decisions_q;

    // Survivor histories; the known two-bit zero tail fixes final state S0.
    wire [7:0] history_s0;
    wire [7:0] history_s1;
    wire [7:0] history_s2;
    wire [7:0] history_s3;

    controller controller_ins (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(in_valid),
        .step_en(step_en),
        .reg_ex_en(reg_ex_en),
        .output_en(output_en),
        .piso_shift()
    );

    piso10_5 piso (
        .clk(clk),
        .load(in_valid),
        // Only E0 load and the first five shifts are consumed. Idle shifts
        // are harmless and eliminate the top-level shift/hold mux control.
        .shift(1'b1),
        .data_i(codeword_in[9:0]),
        .data_o(queued_pair)
    );

    // Steps 1-2 initialize PM directly; BM prefetch starts at pair 3.
    assign prefetch_pair = in_valid ? codeword_in[11:10] : queued_pair;
    bmu bmu_ins(
        .data_in(prefetch_pair),
        .bm_00(bm_00_next),
        .bm_11(bm_11_next),
        .bm_10(bm_10_next),
        .bm_01(bm_01_next)
    );
    // BM is consumed only during trellis steps; idle values need not be held.
    always @(posedge clk) begin
        bm_00 <= bm_00_next;
        bm_11 <= bm_11_next;
        bm_10 <= bm_10_next;
        bm_01 <= bm_01_next;
    end

    // ACS destinations: S0, S1, S2 and S3.
    acs acs0 (
        .bm_A(bm_00),
        .bm_B(bm_11),
        .pm_prev_A(pm_s0),
        .pm_prev_B(pm_s1),
        .pm_new(next_s0),
        .dec_out(d0)
    );

    acs acs1 (
        .bm_A(bm_10),
        .bm_B(bm_01),
        .pm_prev_A(pm_s2),
        .pm_prev_B(pm_s3),
        .pm_new(next_s1),
        .dec_out(d1)
    );

    acs acs2 (
        .bm_A(bm_11),
        .bm_B(bm_00),
        .pm_prev_A(pm_s0),
        .pm_prev_B(pm_s1),
        .pm_new(next_s2),
        .dec_out(d2)
    );

    acs acs3 (
        .bm_A(bm_01),
        .bm_B(bm_10),
        .pm_prev_A(pm_s2),
        .pm_prev_B(pm_s3),
        .pm_new(next_s3),
        .dec_out(d3)
    );

    always @(posedge clk)
        if (step_en)
            decisions_q <= {d3, d2, d1, d0};

    pmu pmu_ins (
        .clk(clk),
        .init(in_valid),
        .prefix_in(codeword_in[15:12]),
        // E0 initializes after two steps; E1-E6 consume the six remaining pairs.
        // With fixed final S0, metric updates after E6 are unobserved.
        .update(1'b1),
        .pm_new_s0(next_s0),
        .pm_new_s1(next_s1),
        .pm_new_s2(next_s2),
        .pm_new_s3(next_s3),
        .pm_prev_s0(pm_s0),
        .pm_prev_s1(pm_s1),
        .pm_prev_s2(pm_s2),
        .pm_prev_s3(pm_s3)
    );
    
    reg_ex reg_ex_ins (
        .clk(clk),
        .update(reg_ex_en),
        .dec_s0(decisions_q[0]),
        .dec_s1(decisions_q[1]),
        .dec_s2(decisions_q[2]),
        .dec_s3(decisions_q[3]),
        .history_s0(history_s0),
        .history_s1(history_s1),
        .history_s2(history_s2),
        .history_s3(history_s3)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_valid <= 1'b0;
            data_out <= 8'd0;
        end else begin
            // E7 completes S0 history; E8 registers the terminated byte.
            out_valid <= output_en;
            if (output_en)
                data_out <= history_s0;
        end
    end

endmodule
