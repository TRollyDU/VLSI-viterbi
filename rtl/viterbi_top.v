module viterbi_top (
    input clk,
    input rstn,
    input viterbi_enable,
    input [15:0] input_data,
    output wire [7:0] output_data,
    output wire output_done
);

    wire reset_n;
    wire core_start;
    reg core_done;
    wire step_en;
    wire ready;
    wire re_en;
    wire finish_en;
    wire accept;
    wire piso_load;
    wire piso_shift;
    reg core_reset_n;

    wire [1:0] queued_pair;
    wire [1:0] prefetch_pair;
    wire bm_parity_next;
    wire bm_00_carry_next;
    wire bm_10_carry_next;
    reg bm_parity;
    reg bm_00_carry;
    reg bm_10_carry;
    wire [1:0] bm_00;
    wire [1:0] bm_10;

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


    assign core_start = viterbi_enable && reset_n;
    assign output_done = core_done && reset_n;

    r_sync reset_ins (
        .clk(clk),
        .rst_n(rstn),
        .reset_n(reset_n)
    );

    assign accept = core_start && ready;
    // Idle preloading keeps reset/handshake logic off the PISO load path.
    assign piso_load = !step_en;

    // Register the core reset boundary; reset must span two rising edges.
    always @(posedge clk) begin
        core_reset_n <= reset_n;
    end

    controller controller_ins (
        .clk(clk),
        .rst_n(core_reset_n),
        .start(core_start),
        .ready(ready),
        .step_en(step_en),
        .re_en(re_en),
        .finish_en(finish_en),
        .piso_shift(piso_shift)
    );

    piso14_7 piso (
        .clk(clk),
        .load(piso_load),
        .shift(piso_shift),
        .data_i(input_data[13:0]),
        .data_o(queued_pair)
    );

    assign prefetch_pair = accept ? input_data[15:14] : queued_pair;
    bmu bmu_ins (
        .data_in(prefetch_pair),
        .parity(bm_parity_next),
        .carry_00(bm_00_carry_next),
        .carry_10(bm_10_carry_next)
    );
    // Two metrics share parity; decode both carries before the pipeline FFs.
    always @(posedge clk) begin
        bm_parity <= bm_parity_next;
        bm_00_carry <= bm_00_carry_next;
        bm_10_carry <= bm_10_carry_next;
    end
    assign bm_00 = {bm_00_carry, bm_parity};
    assign bm_10 = {bm_10_carry, ~bm_parity};

    acs acs_ins (
        .pm_s0(pm_s0),
        .pm_s1(pm_s1),
        .pm_s2(pm_s2),
        .pm_s3(pm_s3),
        .bm_00(bm_00),
        .bm_10(bm_10),
        .next_s0(next_s0),
        .next_s1(next_s1),
        .next_s2(next_s2),
        .next_s3(next_s3),
        .decision_s0(decision_s0),
        .decision_s1(decision_s1),
        .decision_s2(decision_s2),
        .decision_s3(decision_s3)
    );

    always @(posedge clk) begin
        decisions_q <= {decision_s3, decision_s2, decision_s1, decision_s0};
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

    smu smu_ins (
        .clk(clk),
        .rst_n(core_reset_n),
        .update(re_en),
        .finish(finish_en),
        .decisions(decisions_q),
        .pm_s0(pm_s0),
        .pm_s1(pm_s1),
        .pm_s2(pm_s2),
        .pm_s3(pm_s3),
        .result(output_data)
    );

    always @(posedge clk) begin
        if (!core_reset_n) begin
            core_done <= 1'b0;
        end else begin
            core_done <= finish_en;
        end
    end
endmodule
