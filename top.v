// Default zero-tail build instantiates no PSU. ZERO_TAIL=0 enables the PSU.
// INPUT_HANDSHAKE=0: external start pulse. =1: accept on valid/ready.
// Both modes retain output until out_valid && out_ready.
module top #(
    parameter ZERO_TAIL = 1,
    // 1: retain published data even while idle. 0: use live completed history;
    // data is guaranteed stable while out_valid, but may change while invalid.
    parameter OUTPUT_REGISTER = 1,
    // 0: external one-clock start; 1: protected ready/valid input.
    parameter INPUT_HANDSHAKE = 0
) (
    input clk, 
    input rst_n,
    input in_valid,
    output in_ready,
    input [15:0] codeword_in,
    input out_ready,
    output out_valid,
    output [7:0] data_out
);

    wire accept;
    wire first_step;
    wire step_en;
    wire init_en;
    wire add_en;
    wire reg_ex_en;
    wire output_en;
    wire final_re_en;
    wire piso_load, piso_shift, piso_hold;

    wire [1:0] queued_pair;

    wire [1:0] bm_00_next, bm_11_next, bm_10_next, bm_01_next;
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

    wire [3:0] decisions_q;
    wire pm_write_en;

    // Four survivors, including their state-dependent two-bit suffixes.
    wire [7:0] history_s0;
    wire [7:0] history_s1;
    wire [7:0] history_s2;
    wire [7:0] history_s3;

    input_handshake #(.ENABLE(INPUT_HANDSHAKE)) handshake_ins (
        .clk(clk), 
        .rst_n(rst_n), 
        .in_valid(in_valid),
        .out_valid(out_valid), 
        .out_ready(out_ready),
        .in_ready(in_ready), 
        .accept(accept)
    );

    controller controller_ins (
        .clk(clk),
        .rst_n(rst_n),
        .accept(accept),
        .first_step(first_step),
        .init_en(init_en),
        .add_en(add_en),
        .step_en(step_en),
        .reg_ex_en(reg_ex_en),
        .output_en(output_en),
        .final_re_en(final_re_en),
        .piso_load(piso_load),
        .piso_shift(piso_shift),
        .piso_hold(piso_hold),
        .pm_write_en(pm_write_en)
    );

    piso14_7 piso (
        .clk(clk),
        .load(piso_load),
        .shift(piso_shift),
        .hold(piso_hold),
        .data_i(codeword_in[13:0]),
        .data_o(queued_pair)
    );

    bmu bmu_ins (
        .data_in(queued_pair),
        .bm_00(bm_00_next),
        .bm_11(bm_11_next),
        .bm_10(bm_10_next),
        .bm_01(bm_01_next)
    );

    always @(posedge clk) begin
        bm_00 <= bm_00_next;
        bm_11 <= bm_11_next;
        bm_10 <= bm_10_next;
        bm_01 <= bm_01_next;
    end

    acs acs_ins (
        .clk(clk),
        .first_step(first_step),
        .pm_s0(pm_s0), .pm_s1(pm_s1),
        .pm_s2(pm_s2), .pm_s3(pm_s3),
        .bm_00(bm_00), .bm_11(bm_11),
        .bm_10(bm_10), .bm_01(bm_01),
        .next_s0(next_s0), .next_s1(next_s1),
        .next_s2(next_s2), .next_s3(next_s3),
        .decisions_q(decisions_q)
    );

    pmu pmu_ins (
        .clk(clk),
        .init(init_en),
        .pm_write_en(pm_write_en),
        .first_pair_in(codeword_in[15:14]),
        .pm_new_s0(next_s0),
        .pm_new_s1(next_s1),
        .pm_new_s2(next_s2),
        .pm_new_s3(next_s3),
        .pm_prev_s0(pm_s0),
        .pm_prev_s1(pm_s1),
        .pm_prev_s2(pm_s2),
        .pm_prev_s3(pm_s3)
    );
    
    rex rex_ins (
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
            output_register #(.REGISTER_DATA(OUTPUT_REGISTER)) output_ins (
                .clk(clk), .rst_n(rst_n),
                .output_en(output_en), .data_in(history_s0),
                .out_ready(out_ready),
                .out_valid(out_valid), .data_out(data_out)
            );
        end else begin : g_psu
            psu #(.OUTPUT_REGISTER(OUTPUT_REGISTER)) psu_ins (
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
