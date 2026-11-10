`timescale 1ns/1ps
module tb_bmu;
reg [1:0] data_in; wire [1:0] bm_00,bm_11,bm_10,bm_01;
bmu dut(.*);
integer x;
initial begin
 for(x=0;x<4;x=x+1) begin
  data_in=x; #1;
  if(bm_00 !== ((x>>1)+(x&1)) || bm_11 !== (2-((x>>1)+(x&1))) ||
     bm_10 !== ((1-(x>>1))+(x&1)) || bm_01 !== ((x>>1)+(1-(x&1)))) $fatal(1,"BMU input %0d",x);
 end
 $display("PASS: BMU all four received pairs"); $finish;
end
endmodule
