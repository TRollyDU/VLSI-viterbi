module iu #(
    parameter integer ENABLE = 1
) (
    input clk,
    input rst_n,
    input in_valid,
    input [15:0] word_in,
    input core_ready,
    input output_transfer,
    output wire reset_n,
    output wire in_ready,
    output wire start,
    output wire [15:0] word_out
);
    localparam [1:0] MAX_OUTSTANDING = 2'd2;

    assign start = in_valid && in_ready;
    assign word_out = word_in;

    generate
        if (ENABLE != 0) begin : gen_handshake
            (* ASYNC_REG = "TRUE" *) reg meta_n;
            (* ASYNC_REG = "TRUE" *) reg sync_n;
            reg [1:0] outstanding;

            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    meta_n <= 1'b0;
                    sync_n <= 1'b0;
                end else begin
                    meta_n <= 1'b1;
                    sync_n <= meta_n;
                end
            end
            assign reset_n = sync_n;

            assign in_ready = reset_n && core_ready && (outstanding < MAX_OUTSTANDING);

            always @(posedge clk) begin
                if (!reset_n) begin
                    outstanding <= 2'd0;
                end else begin
                    case ({start, output_transfer})
                        2'b10: outstanding <= outstanding + 2'd1;
                        2'b01: outstanding <= outstanding - 2'd1;
                        default: outstanding <= outstanding;
                    endcase
                end
            end
        end else begin : gen_bypass
            assign reset_n = rst_n;
            assign in_ready = rst_n && core_ready;
        end
    endgenerate
endmodule
