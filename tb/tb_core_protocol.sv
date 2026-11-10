`timescale 1ns/1ps
module tb_core_protocol;
reg clk=0;always #2.5 clk=~clk;
reg rst_n=0,start=0;reg [15:0] word_in=0;wire ready,done;wire [7:0] result;
viterbi dut(.*);reg [7:0] oracle[0:65535];integer frame,e,seed=32'h7654321;reg [15:0] accepted;
initial begin
 $readmemh("oracle.hex",oracle);
 repeat(3) @(negedge clk);rst_n=1;
 for(frame=0;frame<256;frame=frame+1) begin
  @(negedge clk);accepted=$random(seed);word_in=accepted;start=1;
  @(posedge clk);#0.1;
  for(e=1;e<=10;e=e+1) begin
   @(negedge clk);word_in=$random(seed);start=(e<=7);
   @(posedge clk);#0.1;
   if(e<10 && done !==0) $fatal(1,"Core early done");
   if(e==10 && (done !==1 || result !== oracle[accepted])) $fatal(1,"Core busy ignored/start input latch");
  end
  @(negedge clk);start=0;
  @(posedge clk);#0.1;if(done !==0) $fatal(1,"Core done pulse");
 end
 $display("PASS: core busy start rejection, latched input, 256 independent frames, E10 done pulse");$finish;
end
endmodule
