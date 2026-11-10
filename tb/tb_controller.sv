`timescale 1ns/1ps
module tb_controller;
reg clk=0;always #2.5 clk=~clk;
reg rst_n=0,start=0;wire ready,step_en,re_en,pm_capture_en,finish_en,piso_shift;
controller dut(.*);integer frame,e;
initial begin
 repeat(2) @(negedge clk);rst_n=1;
 for(frame=0;frame<20;frame=frame+1) begin
  @(negedge clk);if(!ready) $fatal(1,"CTRL idle");start=1;
  for(e=0;e<=10;e=e+1) begin
   @(posedge clk);#0.1;
   if(step_en !== (e<8) || re_en !== (e>=1 && e<=8) || pm_capture_en !== (e==8) || finish_en !== (e==9) || piso_shift !== (e<7) || ready !== (e>=8)) $fatal(1,"CTRL phase E%0d",e);
   @(negedge clk);start=0;
  end
 end
 rst_n=0;start=1;@(posedge clk);#0.1;
 if({ready,step_en,re_en,pm_capture_en,finish_en,piso_shift} !== 0) $fatal(1,"CTRL reset priority");
 $display("PASS: controller E0..E10 schedule, repeat, reset priority");$finish;
end
endmodule
