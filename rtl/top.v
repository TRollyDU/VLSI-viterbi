module top #(
    parameter integer ENABLE_IU = 1,
    parameter integer ENABLE_OU = 1
) (
    input clk,
    input rst_n,
    input in_valid,
    input [15:0] codeword_in,
    input out_ready,
    output wire in_ready,
    output wire out_valid,
    output wire [7:0] data_out
);
    wire reset_n;
    wire core_start;
    wire core_ready;
    wire core_done;
    wire output_transfer;
    wire [15:0] core_word;
    wire [7:0] core_result;

    assign output_transfer = out_valid && ((ENABLE_OU == 0) || out_ready);

    generate
        if (ENABLE_IU != 0) begin : gen_iu_enabled
            iu iu_ins (
                .clk(clk),
                .rst_n(rst_n),
                .reset_n(reset_n),
                .in_valid(in_valid),
                .word_in(codeword_in),
                .core_ready(core_ready),
                .output_transfer(output_transfer),
                .in_ready(in_ready),
                .start(core_start),
                .word_out(core_word)
            );
        end else begin : gen_iu_disabled
            iu #(
                .ENABLE(0)
            ) iu_ins (
                .clk(clk),
                .rst_n(rst_n),
                .reset_n(reset_n),
                .in_valid(in_valid),
                .word_in(codeword_in),
                .core_ready(core_ready),
                .output_transfer(output_transfer),
                .in_ready(in_ready),
                .start(core_start),
                .word_out(core_word)
            );
        end
    endgenerate

    viterbi core_ins (
        .clk(clk),
        .rst_n(reset_n),
        .start(core_start),
        .word_in(core_word),
        .ready(core_ready),
        .done(core_done),
        .result(core_result)
    );

    generate
        if (ENABLE_OU != 0) begin : gen_ou_enabled
            ou ou_ins (
                .clk(clk),
                .rst_n(reset_n),
                .core_done(core_done),
                .core_result(core_result),
                .out_ready(out_ready),
                .out_valid(out_valid),
                .data_out(data_out)
            );
        end else begin : gen_ou_disabled
            ou #(
                .ENABLE(0)
            ) ou_ins (
                .clk(clk),
                .rst_n(reset_n),
                .core_done(core_done),
                .core_result(core_result),
                .out_ready(out_ready),
                .out_valid(out_valid),
                .data_out(data_out)
            );
        end
    endgenerate

endmodule
