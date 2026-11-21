module viterbi_top (
    input clk,
    input rstn,
    input viterbi_enable,
    input [15:0] input_data,
    output wire [7:0] output_data,
    output wire output_done
);
    wire reset_n;
    wire core_done;
    wire core_start;

    assign core_start = viterbi_enable && reset_n;
    assign output_done = core_done && reset_n;

    r_sync reset_ins (
        .clk(clk),
        .rst_n(rstn),
        .reset_n(reset_n)
    );

    viterbi core_ins (
        .clk(clk),
        .rst_n(reset_n),
        .start(core_start),
        .word_in(input_data),
        .done(core_done),
        .result(output_data)
    );
endmodule
