module bmu (
    input [1:0] data_in,
    output wire [1:0] bm_00,
    output wire [1:0] bm_11,
    output wire [1:0] bm_10,
    output wire [1:0] bm_01
);

    assign bm_00 = {1'b0, data_in[1]} + {1'b0, data_in[0]};
    assign bm_11 = {1'b0, ~data_in[1]} + {1'b0, ~data_in[0]};
    assign bm_10 = {1'b0, ~data_in[1]} + {1'b0, data_in[0]};
    assign bm_01 = {1'b0, data_in[1]} + {1'b0, ~data_in[0]};
endmodule

