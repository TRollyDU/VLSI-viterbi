module bmu (
    input [1:0] data_in,
    output wire parity,
    output wire carry_00,
    output wire carry_10
);
    assign parity = data_in[1] ^ data_in[0];
    assign carry_00 = data_in[1] & data_in[0];
    assign carry_10 = ~data_in[1] & data_in[0];
endmodule

