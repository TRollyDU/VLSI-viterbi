module bmu (
    input [1:0] data_in,
    output [1:0] bm_00,
    output [1:0] bm_11,
    output [1:0] bm_10,
    output [1:0] bm_01
);
    // The eight trellis branches share these four expected output pairs.
    assign bm_00 = {1'b0, data_in[1]} + {1'b0, data_in[0]};
    assign bm_11 = {1'b0, ~data_in[1]} + {1'b0, ~data_in[0]};
    assign bm_10 = {1'b0, ~data_in[1]} + {1'b0, data_in[0]};
    assign bm_01 = {1'b0, data_in[1]} + {1'b0, ~data_in[0]};
endmodule
// | CS   | IN| NS  | Expect |
// | `00` | 0 | `00` | `00` |
// | `00` | 1 | `10` | `11` |
// | `01` | 0 | `00` | `11` |
// | `01` | 1 | `10` | `00` |
// | `10` | 0 | `01` | `10` |
// | `10` | 1 | `11` | `01` |
// | `11` | 0 | `01` | `01` |
// | `11` | 1 | `11` | `10` |
