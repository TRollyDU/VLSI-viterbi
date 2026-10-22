// Output support: valid always persists until transfer. Data storage is optional.
module output_register #(
    parameter REGISTER_DATA = 1
) (
    input clk,
    input rst_n,
    input output_en,
    input [7:0] data_in,
    input out_ready,
    output reg out_valid,
    output [7:0] data_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_valid <= 1'b0;
        end else if (output_en) begin
            out_valid <= 1'b1;
        end else if (out_valid && out_ready) begin
            out_valid <= 1'b0;
        end
    end

    generate
        if (REGISTER_DATA) begin : g_registered_data
            reg [7:0] data_q;
            assign data_out = data_q;
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n)
                    data_q <= 8'd0;
                else if (output_en)
                    data_q <= data_in;
            end
        end else begin : g_direct_data
            // Controller blocks a new input until output transfer; RE and the
            // PSU state therefore hold while valid. Idle/reset data is unspecified.
            assign data_out = data_in;
        end
    endgenerate
endmodule
