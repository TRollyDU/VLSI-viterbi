module piso14_7 (
    input clk, 
    input load, 
    input shift, 
    input hold,
    input [13:0] data_i, 
    output [1:0] data_o
);
    reg [13:0] shift_reg;
    // Controller operations are one-hot. Each term contributes data only
    // when its operation is active; OR combines the mutually exclusive terms.
    // This spelling tests whether synthesis avoids the hold-priority guard
    // inferred from a self-assignment case branch. Same reachable behavior.
    wire [13:0] load_data = {14{load}} & data_i;
    wire [13:0] shifted_data = {14{shift}} & {shift_reg[11:0], 2'b00};
    wire [13:0] held_data = {14{hold}} & shift_reg;
    always @(posedge clk)
        shift_reg <= load_data | shifted_data | held_data;
    assign data_o = shift_reg[13:12];
endmodule
