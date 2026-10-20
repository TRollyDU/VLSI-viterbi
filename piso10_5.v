// Five queued pairs (trellis steps 4-8); pair 3 bypasses this register.
module piso10_5 (
    input clk,
    input load,
    input shift,
    input [9:0] data_i,
    output [1:0] data_o
);
    reg [9:0] shift_reg;

    always @(posedge clk) begin
        if (load)
            shift_reg <= data_i;
        else if (shift)
            shift_reg <= {shift_reg[7:0], 2'b00};
    end

    assign data_o = shift_reg[9:8];
endmodule
