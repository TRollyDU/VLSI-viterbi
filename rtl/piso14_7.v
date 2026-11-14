module piso14_7 (
    input clk,
    input rst_n,
    input load,
    input shift,
    input [13:0] data_i,
    output wire [1:0] data_o
);
    reg [13:0] shift_reg;

    always @(posedge clk) begin
        if (load) begin
            shift_reg <= data_i;
        end else if (shift) begin
            shift_reg <= {shift_reg[11:0], 2'b00};
        end
    end

    assign data_o = shift_reg[13:12];
endmodule
