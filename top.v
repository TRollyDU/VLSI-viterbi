// Default zero-tail build instantiates no PSU. ZERO_TAIL=0 enables the PSU.
// Accept on in_valid && in_ready; retain output until out_valid && out_ready.
module top #(
    parameter ZERO_TAIL = 1
) (
    input clk, 
    input rst_n,
    input in_valid,
    output reg in_ready,
    input [15:0] codeword_in,
    input out_ready,
    output out_valid,
    output [7:0] data_out
);

    reg busy;
    wire accept = in_valid && in_ready;

    // One outstanding block, including a pending output. No input is accepted
    // during processing or backpressure. Earliest initiation interval is 17.
    // Ready has its own asynchronously cleared FF: reset is not in the
    // combinational accept/load cone. On reset release, R1 raises ready;
    // the first possible acceptance is R2, using ready from before the edge.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            busy <= 1'b0;
            in_ready <= 1'b0;
        end else if (accept) begin
            busy <= 1'b1;
            in_ready <= 1'b0;
        end else if (out_valid && out_ready) begin
            busy <= 1'b0;
            in_ready <= 1'b1;
        end else if (!busy) begin
            in_ready <= 1'b1;
        end
    end

    // Logical phase markers. Candidate/PM/BM/decision FFs run every clock;
    // phases qualify their use, not their hardware update.
    wire step_en;
    wire init_en;
    wire add_en;
    wire reg_ex_en;
    wire output_en;
    wire final_re_en;
    wire piso_load, piso_shift, piso_hold;

    // Received pair and branch metrics.
    wire [1:0] queued_pair;
    wire [1:0] bm_00_next, bm_11_next, bm_10_next, bm_01_next;
    // Eight trellis branches use four distinct Hamming distances.
    reg [1:0] bm_00, bm_11, bm_10, bm_01;

    // Current and selected path metrics.
    wire [1:0] pm_s0;
    wire [1:0] pm_s1;
    wire [1:0] pm_s2;
    wire [1:0] pm_s3;
    wire [2:0] next_s0;
    wire [2:0] next_s1;
    wire [2:0] next_s2;
    wire [2:0] next_s3;

    wire d0;
    wire d1;
    wire d2;
    wire d3;
    reg [3:0] decisions_q;

    // Four survivors, including their state-dependent two-bit suffixes.
    wire [7:0] history_s0;
    wire [7:0] history_s1;
    wire [7:0] history_s2;
    wire [7:0] history_s3;

    controller controller_ins (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(accept),
        .init_en(init_en),
        .add_en(add_en),
        .step_en(step_en),
        .reg_ex_en(reg_ex_en),
        .output_en(output_en),
        .final_re_en(final_re_en),
        .piso_load(piso_load),
        .piso_shift(piso_shift),
        .piso_hold(piso_hold)
    );

    piso12_6 piso (
        .clk(clk),
        .load(piso_load),
        .shift(piso_shift),
        .hold(piso_hold),
        .data_i(codeword_in[11:0]),
        .data_o(queued_pair)
    );

    // E0 loads all six remaining pairs; E1 captures BM of pair 3.
    bmu bmu_ins(
        .data_in(queued_pair),
        .bm_00(bm_00_next),
        .bm_11(bm_11_next),
        .bm_10(bm_10_next),
        .bm_01(bm_01_next)
    );
    // Capture every clock. Valid ADD reads BM written at E1 or the preceding
    // SELECT. At E12 PISO may preload: the final ADD uses the E11 BM FF.
    always @(posedge clk) begin
        bm_00 <= bm_00_next;
        bm_11 <= bm_11_next;
        bm_10 <= bm_10_next;
        bm_01 <= bm_01_next;
    end

    // ACS destinations: S0, S1, S2 and S3.
    acs acs0 (
        .clk(clk),
        .bm_A(bm_00),
        .bm_B(bm_11),
        .pm_prev_A(pm_s0),
        .pm_prev_B(pm_s1),
        .pm_new(next_s0),
        .dec_out(d0)
    );

    acs acs1 (
        .clk(clk),
        .bm_A(bm_10),
        .bm_B(bm_01),
        .pm_prev_A(pm_s2),
        .pm_prev_B(pm_s3),
        .pm_new(next_s1),
        .dec_out(d1)
    );

    acs acs2 (
        .clk(clk),
        .bm_A(bm_11),
        .bm_B(bm_00),
        .pm_prev_A(pm_s0),
        .pm_prev_B(pm_s1),
        .pm_new(next_s2),
        .dec_out(d2)
    );

    acs acs3 (
        .clk(clk),
        .bm_A(bm_01),
        .bm_B(bm_10),
        .pm_prev_A(pm_s2),
        .pm_prev_B(pm_s3),
        .pm_new(next_s3),
        .dec_out(d3)
    );

    always @(posedge clk)
        decisions_q <= {d3, d2, d1, d0};

    pmu pmu_ins (
        .clk(clk),
        .init(init_en),
        .prefix_in(codeword_in[15:12]),
        // Update every clock; only E1/E3/E5/.../E13 metrics are meaningful.
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

    // Elaboration-time choice: the default branch has no PSU instance,
    // best-state registers, metric comparisons or four-history output MUX.
    generate
        if (ZERO_TAIL) begin : g_zero_tail
            reg valid_q;
            reg [7:0] data_q;
            assign out_valid = valid_q;
            assign data_out = data_q;

            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    valid_q <= 1'b0;
                    data_q <= 8'd0;
                end else if (output_en) begin
                    valid_q <= 1'b1;
                    data_q <= history_s0;
                end else if (valid_q && out_ready) begin
                    valid_q <= 1'b0;
                end
            end
        end else begin : g_psu
            psu psu_ins (
                .clk(clk), .rst_n(rst_n),
                .final_re_en(final_re_en), .output_en(output_en),
                .out_ready(out_ready),
                .pm_s0(pm_s0), .pm_s1(pm_s1),
                .pm_s2(pm_s2), .pm_s3(pm_s3),
                .history_s0(history_s0), .history_s1(history_s1),
                .history_s2(history_s2), .history_s3(history_s3),
                .out_valid(out_valid), .data_out(data_out)
            );
        end
    endgenerate

endmodule
