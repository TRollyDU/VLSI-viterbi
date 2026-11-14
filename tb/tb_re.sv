`timescale 1ns/1ps
module tb_re;
reg clk=0;always #2.5 clk=~clk;
reg rst_n=0,update=0;reg dec_s0=0,dec_s1=0,dec_s2=0,dec_s3=0;
wire [7:0] history_s0,history_s1,history_s2,history_s3;
re dut(.*);reg [7:0] model[0:3];reg [7:0] next_model[0:3];integer updates=0;integer n,j,seed=32'h13579bdf;reg [3:0] decisions;
initial begin
 for(j=0;j<4;j=j+1) model[j]=0;
 for(n=0;n<4096;n=n+1) begin
  @(negedge clk);rst_n=(n%131!=0);update=(n%5!=0);decisions=$random(seed);{dec_s3,dec_s2,dec_s1,dec_s0}=decisions;
  next_model[0]={model[dec_s0?1:0][6:0],1'b0};next_model[1]={model[dec_s1?3:2][6:0],1'b0};
  next_model[2]={model[dec_s2?1:0][6:0],1'b1};next_model[3]={model[dec_s3?3:2][6:0],1'b1};
  for(j=0;j<4;j=j+1) if(update) model[j]=next_model[j];
  if(update) updates=updates+1;
  @(posedge clk);#0.1;
  if(updates>=8 && {history_s3,history_s2,history_s1,history_s0} !== {model[3],model[2],model[1],model[0]}) $fatal(1,"RE n=%0d",n);
 end
 $display("PASS: RE 4096 resetless model steps after eight-update flush, independent four-state histories");$finish;
end
endmodule
