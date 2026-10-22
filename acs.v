module acs (
    input clk,
    input first_step,
    input [1:0] pm_s0,
    input [1:0] pm_s1,
    input [1:0] pm_s2,
    input [1:0] pm_s3,
    input [1:0] bm_00,
    input [1:0] bm_11,
    input [1:0] bm_10,
    input [1:0] bm_01,
    output [2:0] next_s0,
    output [2:0] next_s1,
    output [2:0] next_s2,
    output [2:0] next_s3,
    output reg [3:0] decisions_q
);

    wire d0, d1, d2, d3;
    reg [3:0] select_q;

    butterfly_pm2 acs0 (.pm_a(pm_s0), 
                        .pm_b(pm_s1), 
                        .metric(bm_00), 
                        .dec_0(d0), 
                        .dec_1(d2));

    butterfly_pm2 acs1 (.pm_a(pm_s2), 
                        .pm_b(pm_s3), 
                        .metric(bm_10), 
                        .dec_0(d1), 
                        .dec_1(d3));

    always @(posedge clk) begin
        select_q <= first_step ? 4'b0000 : {d3,d2,d1,d0};
        decisions_q <= select_q;
    end

    function [2:0] add_hamming;
        input [1:0] pm, bm;
        begin
            add_hamming = {1'b0, pm} + {1'b0, bm};
        end
    endfunction

    /* 
    function [2:0] add_hamming;
        input [1:0] pm, bm;
        reg carry_hi;
        begin
            carry_hi = bm[1] | (pm[0] & bm[0]);
            add_hamming[0] = pm[0] ^ bm[0];
            add_hamming[1] = pm[1] ^ carry_hi;
            add_hamming[2] = pm[1] & carry_hi;
        end
    endfunction
    */

    assign next_s0 = add_hamming((select_q[0] ? pm_s1 : pm_s0),
                                   (select_q[0] ? bm_11 : bm_00)
                                ); 
    assign next_s1 = add_hamming((select_q[1] ? pm_s3 : pm_s2),
                                   (select_q[1] ? bm_01 : bm_10)
                                ); 
    assign next_s2 = add_hamming((select_q[2] ? pm_s1 : pm_s0),
                                   (select_q[2] ? bm_00 : bm_11)
                                ); 
    assign next_s3 = add_hamming((select_q[3] ? pm_s3 : pm_s2),
                                   (select_q[3] ? bm_10 : bm_01)
                                ); 


endmodule

