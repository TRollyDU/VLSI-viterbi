module piso12_6 (
    input clk, input load, input shift, input hold,
    input [11:0] data_i, output [1:0] data_o
);
    reg [11:0] shift_reg;
    always @(posedge clk) begin
        // Registered one-hot controls from controller: no local hold decode
        // or load/shift priority logic on the control-to-D path.
        shift_reg <= ({12{load}} & data_i) |
                     ({12{shift}} & {shift_reg[9:0],2'b00}) |
                     ({12{hold}} & shift_reg);
    end
    assign data_o = shift_reg[11:10];
endmodule
