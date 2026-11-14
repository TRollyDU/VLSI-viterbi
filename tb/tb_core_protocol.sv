`timescale 1ns/1ps
module tb_core_protocol;
reg clk=0;always #2.5 clk=~clk;
reg rst_n=0,start=0;reg [15:0] word_in=0;wire ready,done;wire [7:0] result;
viterbi dut(.*);reg [7:0] oracle[0:65535];integer frame,e,phase,seed=32'h7654321;reg [15:0] accepted;
initial begin
 $readmemh("oracle.hex",oracle);
 repeat(2) @(negedge clk);
 start=1;word_in=16'he800;
 repeat(3) begin
  @(posedge clk);#0.1;
  if(ready !== 0 || done !== 0 || result !== 0) $fatal(1,"Core reset suppresses start");
  @(negedge clk);word_in=~word_in;
 end
 start=0;rst_n=1;
 repeat(12) begin
  @(posedge clk);#0.1;
  if(ready !== 1 || done !== 0 || result !== 0) $fatal(1,"Idle preload created a frame");
  @(negedge clk);word_in=~word_in;
 end
 for(frame=0;frame<256;frame=frame+1) begin
  @(negedge clk);accepted=$random(seed);word_in=accepted;start=1;
  @(posedge clk);#0.1;
  for(e=1;e<=10;e=e+1) begin
   @(negedge clk);word_in=$random(seed);start=(e<=7);
   @(posedge clk);#0.1;
   if(e<10 && done !==0) $fatal(1,"Core early done");
   if(e==10 && (done !==1 || result !== oracle[accepted] || result[1:0] !== 2'b00)) $fatal(1,"Core busy ignored/start input latch/tail 00");
  end
  @(negedge clk);start=0;
  @(posedge clk);#0.1;if(done !==0) $fatal(1,"Core done pulse");
 end
 for(phase=0;phase<=10;phase=phase+1) begin
  @(negedge clk);word_in=16'he800;start=1;
  @(posedge clk);#0.1;
  @(negedge clk);start=0;
  repeat(phase) @(negedge clk);
  rst_n=0;start=1;
  @(posedge clk);#0.1;
  if(dut.core_reset_n !== 0 || ready !== 0) $fatal(1,"Reset capture phase=%0d",phase);
  @(negedge clk);word_in=~word_in;
  @(posedge clk);#0.1;
  if(done !== 0 || result !== 0 || ready !== 0 || dut.step_en !== 0) $fatal(1,"Registered reset abort phase=%0d",phase);
  @(negedge clk);rst_n=1;start=0;
  if(ready !== 0) $fatal(1,"Early reset release phase=%0d",phase);
  @(posedge clk);#0.1;
  if(dut.core_reset_n !== 1 || ready !== 1 || done !== 0) $fatal(1,"Registered reset release phase=%0d",phase);
  repeat(12) begin
   @(negedge clk);word_in=~word_in;
   @(posedge clk);#0.1;
   if(done !== 0 || result !== 0) $fatal(1,"Ghost after registered reset phase=%0d",phase);
  end
  @(negedge clk);accepted=16'he800;word_in=accepted;start=1;
  @(posedge clk);#0.1;
  @(negedge clk);start=0;
  for(e=1;e<=10;e=e+1) begin
   @(posedge clk);#0.1;
   if(e<10 && done !==0) $fatal(1,"Early restart result phase=%0d",phase);
   if(e==10 && (done !==1 || result !== oracle[accepted])) $fatal(1,"Reset restart result phase=%0d",phase);
   @(negedge clk);
  end
 end
 $display("PASS: core busy start rejection, latched input, 256 independent frames, E10 done pulse");$finish;
end
endmodule
