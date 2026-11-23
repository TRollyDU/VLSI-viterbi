module smu (
    input clk,
    input rst_n,
    input update,
    input select_en,
    input finish,
    input [3:0] decisions,
    input [2:0] pm_s0,
    input [2:0] pm_s1,
    input [2:0] pm_s2,
    input [2:0] pm_s3,
    output reg [7:0] result
);
    reg [7:0] history_s0;
    reg [7:0] history_s1;
    reg [7:0] history_s2;
    reg [7:0] history_s3;
    wire choose_s1;
    wire choose_s3;
    wire choose_23;
    reg choose_s1_q;
    reg choose_s3_q;
    reg choose_23_q;
    wire [2:0] metric_01;
    wire [2:0] metric_23;
    wire [7:0] history_01;
    wire [7:0] history_23;
    wire [7:0] selected_history;

    // Strict comparisons preserve S0/S1/S2/S3 priority on endpoint ties.
    assign choose_s1 = pm_s1 < pm_s0;
    assign choose_s3 = pm_s3 < pm_s2;
    assign metric_01 = choose_s1 ? pm_s1 : pm_s0;
    assign metric_23 = choose_s3 ? pm_s3 : pm_s2;
    assign choose_23 = metric_23 < metric_01;
    assign history_01 = choose_s1_q ? history_s1 : history_s0;
    assign history_23 = choose_s3_q ? history_s3 : history_s2;
    assign selected_history = choose_23_q ? history_23 : history_01;

    // E10 samples final E9 metrics; tournament flags use current metrics.
    always @(posedge clk) begin
        if (!rst_n) begin
            choose_s1_q <= 1'b0;
            choose_s3_q <= 1'b0;
            choose_23_q <= 1'b0;
        end else if (select_en) begin
            choose_s1_q <= choose_s1;
            choose_s3_q <= choose_s3;
            choose_23_q <= choose_23;
        end
    end

    // Eight enabled RE updates flush all history from the preceding frame.
    always @(posedge clk) begin
        if (update) begin
            history_s0 <= decisions[0] ? {history_s1[6:0], 1'b0} : {history_s0[6:0], 1'b0};
            history_s1 <= decisions[1] ? {history_s3[6:0], 1'b0} : {history_s2[6:0], 1'b0};
            history_s2 <= decisions[2] ? {history_s1[6:0], 1'b1} : {history_s0[6:0], 1'b1};
            history_s3 <= decisions[3] ? {history_s3[6:0], 1'b1} : {history_s2[6:0], 1'b1};
        end
    end

    always @(posedge clk) begin
        if (!rst_n) begin
            result <= 8'd0;
        end else if (finish) begin
            result <= selected_history;
        end
    end
endmodule
