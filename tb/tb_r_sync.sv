`timescale 1ns/1ps
module tb_r_sync;
reg clk=0;always #2.5 clk=~clk;reg rst_n=0;wire reset_n;wire bypass;
r_sync dut(.clk(clk),.rst_n(rst_n),.reset_n(reset_n));
r_sync #(.ENABLE(0)) raw(.clk(clk),.rst_n(rst_n),.reset_n(bypass));
initial begin
 #0.1;rst_n=1;#0.1;rst_n=0;#0.1;if(reset_n !== 0 || bypass !==0) $fatal(1,"RS async assert");
 @(negedge clk);rst_n=1;
 @(posedge clk);#0.1;if(reset_n !== 0 || bypass !==1) $fatal(1,"RS R1");
 @(posedge clk);#0.1;if(reset_n !== 1) $fatal(1,"RS R2");
 #0.2;rst_n=0;#0.1;if(reset_n !== 0) $fatal(1,"RS reassert");
 $display("PASS: legacy standalone reset synchronizer assert/release/bypass");$finish;
end
endmodule
