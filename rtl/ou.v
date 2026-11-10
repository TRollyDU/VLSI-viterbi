module ou #(
    parameter integer ENABLE = 1
) (
    input clk,
    input rst_n,
    input core_done,
    input [7:0] core_result,
    input out_ready,
    output wire out_valid,
    output wire [7:0] data_out
);
    generate
        if (ENABLE != 0) begin : gen_buffer
            reg [1:0] count;
            reg [7:0] first_data;
            reg [7:0] second_data;
            wire pop;
            wire push;

            assign out_valid = rst_n && (count != 2'd0);
            assign data_out = first_data;
            assign pop = out_valid && out_ready;
            assign push = core_done && ((count < 2'd2) || pop);

            always @(posedge clk) begin
                if (!rst_n) begin
                    count <= 2'd0;
                    first_data <= 8'd0;
                    second_data <= 8'd0;
                end else begin
                    case ({push, pop})
                        2'b10: begin
                            if (count == 2'd0) begin
                                first_data <= core_result;
                            end else begin
                                second_data <= core_result;
                            end
                            count <= count + 2'd1;
                        end
                        2'b01: begin
                            if (count == 2'd2) begin
                                first_data <= second_data;
                            end
                            count <= count - 2'd1;
                        end
                        2'b11: begin
                            if (count == 2'd1) begin
                                first_data <= core_result;
                            end else begin
                                first_data <= second_data;
                                second_data <= core_result;
                            end
                        end
                        default: begin
                            count <= count;
                        end
                    endcase
                end
            end
        end else begin : gen_bypass
            assign out_valid = rst_n && core_done;
            assign data_out = core_result;
        end
    endgenerate
endmodule
