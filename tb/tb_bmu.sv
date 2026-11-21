`timescale 1ns/1ps
module tb_bmu;
reg [1:0] data_in;
wire parity,carry_00,carry_10;
wire [1:0] bm_00 = {carry_00,parity};
wire [1:0] bm_10 = {carry_10,~parity};
bmu dut(.*);
integer x;
initial begin
 for(x=0;x<4;x=x+1) begin
  data_in=x; #1;
  if(bm_00 !== ((x>>1)+(x&1)) ||
     bm_10 !== ((1-(x>>1))+(x&1))) $fatal(1,"BMU input %0d",x);
 end
 $display("PASS: BMU all four received pairs"); $finish;
end
endmodule
