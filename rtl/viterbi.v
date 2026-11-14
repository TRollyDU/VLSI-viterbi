module viterbi (
    input clk,
    input rst_n,
    input start,
    input [15:0] word_in,
    output wire ready,
    output reg done,
    output reg [7:0] result
);

    wire step_en;
    wire re_en;
    wire finish_en;
    wire accept;
    wire piso_load;
    wire piso_shift;
    reg core_reset_n;

    wire [1:0] queued_pair;
    wire [1:0] prefetch_pair;
    wire [1:0] bm_00_next;
    wire [1:0] bm_11_next;
    wire [1:0] bm_10_next;
    wire [1:0] bm_01_next;

    reg [1:0] bm_00;
    reg [1:0] bm_11;
    reg [1:0] bm_10;
    reg [1:0] bm_01;

    wire [2:0] pm_s0;
    wire [2:0] pm_s1;
    wire [2:0] pm_s2;
    wire [2:0] pm_s3;
    wire [2:0] next_s0;
    wire [2:0] next_s1;
    wire [2:0] next_s2;
    wire [2:0] next_s3;

    wire decision_s0;
    wire decision_s1;
    wire decision_s2;
    wire decision_s3;
    reg [3:0] decisions_q;


    wire [7:0] history_s0;

    assign accept = start && ready;
    // Idle preloading keeps reset/handshake logic off the PISO load path.
    assign piso_load = !step_en;

    // Register the core reset boundary; reset must span two rising edges.
    always @(posedge clk) begin
        core_reset_n <= rst_n;
    end

    controller controller_ins (
        .clk(clk),
        .rst_n(core_reset_n),
        .start(accept),
        .ready(ready),
        .step_en(step_en),
        .re_en(re_en),
        .finish_en(finish_en),
        .piso_shift(piso_shift)
    );

    piso14_7 piso (
        .clk(clk),
        .rst_n(core_reset_n),
        .load(piso_load),
        .shift(piso_shift),
        .data_i(word_in[13:0]),
        .data_o(queued_pair)
    );

    assign prefetch_pair = accept ? word_in[15:14] : queued_pair;
    bmu bmu_ins (
        .data_in(prefetch_pair),
        .bm_00(bm_00_next),
        .bm_11(bm_11_next),
        .bm_10(bm_10_next),
        .bm_01(bm_01_next)
    );
    always @(posedge clk) begin
        if (accept || piso_shift) begin
            bm_00 <= bm_00_next;
            bm_11 <= bm_11_next;
            bm_10 <= bm_10_next;
            bm_01 <= bm_01_next;
        end
    end

    acs acs0 (
        .bm_a(bm_00),
        .bm_b(bm_11),
        .pm_prev_a(pm_s0),
        .pm_prev_b(pm_s1),
        .pm_new(next_s0),
        .dec_out(decision_s0)
    );

    acs acs1 (
        .bm_a(bm_10),
        .bm_b(bm_01),
        .pm_prev_a(pm_s2),
        .pm_prev_b(pm_s3),
        .pm_new(next_s1),
        .dec_out(decision_s1)
    );

    acs acs2 (
        .bm_a(bm_11),
        .bm_b(bm_00),
        .pm_prev_a(pm_s0),
        .pm_prev_b(pm_s1),
        .pm_new(next_s2),
        .dec_out(decision_s2)
    );

    acs acs3 (
        .bm_a(bm_01),
        .bm_b(bm_10),
        .pm_prev_a(pm_s2),
        .pm_prev_b(pm_s3),
        .pm_new(next_s3),
        .dec_out(decision_s3)
    );

    always @(posedge clk) begin
        if (step_en) begin
            decisions_q <= {decision_s3, decision_s2, decision_s1, decision_s0};
        end
    end

    pmu pmu_ins (
        .clk(clk),
        .init(accept),
        .update(step_en),
        .pm_new_s0(next_s0),
        .pm_new_s1(next_s1),
        .pm_new_s2(next_s2),
        .pm_new_s3(next_s3),
        .pm_prev_s0(pm_s0),
        .pm_prev_s1(pm_s1),
        .pm_prev_s2(pm_s2),
        .pm_prev_s3(pm_s3)
    );

    re re_ins (
        .clk(clk),
        .rst_n(core_reset_n),
        .update(re_en),
        .dec_s0(decisions_q[0]),
        .dec_s1(decisions_q[1]),
        .dec_s2(decisions_q[2]),
        .dec_s3(decisions_q[3]),
        .history_s0(history_s0),
        .history_s1(),
        .history_s2(),
        .history_s3()
    );

    always @(posedge clk) begin
        if (!core_reset_n) begin
            done <= 1'b0;
            result <= 8'd0;
        end else begin
            done <= finish_en;
            // Tail 00 terminates in S0; E10 samples the completed RE history.
            if (finish_en) begin
                result <= history_s0;
            end
        end
    end

endmodule
