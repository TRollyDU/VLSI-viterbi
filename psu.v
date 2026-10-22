// Optional Path Selection Unit. Owns endpoint selection and final output.
// E14: latch the best final PM state while RE writes the final histories.
// E15: publish that state's completed history; retain it under backpressure.
module psu #(
    parameter OUTPUT_REGISTER = 1
) (
    input clk,
    input rst_n,
    input final_re_en,
    input output_en,
    input out_ready,
    input [1:0] pm_s0,
    input [1:0] pm_s1,
    input [1:0] pm_s2,
    input [1:0] pm_s3,
    input [7:0] history_s0,
    input [7:0] history_s1,
    input [7:0] history_s2,
    input [7:0] history_s3,
    output out_valid,
    output [7:0] data_out
);
    wire [1:0] best_state;
    reg [1:0] best_state_q;
    reg [7:0] selected_history;
    // Three comparisons; ties prefer S0, then S1, S2 and S3.
    wire right_01 = pm_s1 < pm_s0;
    wire right_23 = pm_s3 < pm_s2;
    wire [1:0] min_01 = right_01 ? pm_s1 : pm_s0;
    wire [1:0] min_23 = right_23 ? pm_s3 : pm_s2;
    assign best_state = (min_23 < min_01) ? {1'b1, right_23}
                                            : {1'b0, right_01};

    // No reset required: every valid output follows a valid state capture.
    // PMU runs continuously, so the state must be latched at final_re_en.
    always @(posedge clk)
        if (final_re_en)
            best_state_q <= best_state;

    always @* begin
        case (best_state_q)
            2'd0: selected_history = history_s0;
            2'd1: selected_history = history_s1;
            2'd2: selected_history = history_s2;
            default: selected_history = history_s3;
        endcase
    end

    output_register #(.REGISTER_DATA(OUTPUT_REGISTER)) output_ins (
        .clk(clk), .rst_n(rst_n),
        .output_en(output_en), .data_in(selected_history),
        .out_ready(out_ready), .out_valid(out_valid), .data_out(data_out)
    );
endmodule
