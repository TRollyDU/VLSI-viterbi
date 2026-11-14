`timescale 1ns/1ps
module tb_piso;
reg clk=0;always #2.5 clk=~clk;
reg rst_n=0,load=0,shift=0;reg [13:0] data_i=0;wire [1:0] data_o;
piso14_7 dut(.*);integer word,k;reg [13:0] expected;
initial begin
 // No reset-value contract: the first load establishes valid data.
 for(word=0;word<16384;word=word+1) begin
  @(negedge clk);rst_n=1;load=1;shift=1;data_i=word;expected=word;
  @(posedge clk);#0.1;if(data_o !== expected[13:12]) $fatal(1,"PISO load priority");
  @(negedge clk);load=0;shift=0;data_i=~word;
  @(posedge clk);#0.1;if(data_o !== expected[13:12]) $fatal(1,"PISO hold");
  for(k=0;k<8;k=k+1) begin
   @(negedge clk);shift=1;expected=expected<<2;
   @(posedge clk);#0.1;if(data_o !== expected[13:12]) $fatal(1,"PISO shift word=%h",word);
  end
 end
 @(negedge clk);rst_n=0;load=1;data_i=14'h3fff;
 @(posedge clk);#0.1;if(data_o !== 2'b11) $fatal(1,"PISO load independent of reset");
 $display("PASS: PISO all 16384 words, load/shift priority, hold, zero flush, resetless load");$finish;
end
endmodule
