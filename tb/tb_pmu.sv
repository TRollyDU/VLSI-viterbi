`timescale 1ns/1ps
module tb_pmu;
reg clk=0; always #2.5 clk=~clk;
reg init=0,update=0; reg [2:0] pm_new_s0,pm_new_s1,pm_new_s2,pm_new_s3;
wire [2:0] pm_prev_s0,pm_prev_s1,pm_prev_s2,pm_prev_s3;
pmu dut(.*); integer n; reg [11:0] held;
initial begin
 @(negedge clk);init=1;update=1;{pm_new_s3,pm_new_s2,pm_new_s1,pm_new_s0}=12'hfff;
 @(posedge clk);#0.1;if({pm_prev_s3,pm_prev_s2,pm_prev_s1,pm_prev_s0} !== {3'd6,3'd6,3'd6,3'd0}) $fatal(1,"PMU init priority");
 for(n=0;n<4096;n=n+1) begin
  @(negedge clk);init=0;update=1;{pm_new_s3,pm_new_s2,pm_new_s1,pm_new_s0}=n;
  @(posedge clk);#0.1;if({pm_prev_s3,pm_prev_s2,pm_prev_s1,pm_prev_s0} !== n[11:0]) $fatal(1,"PMU update");
 end
 held={pm_prev_s3,pm_prev_s2,pm_prev_s1,pm_prev_s0};
 @(negedge clk);update=0;{pm_new_s3,pm_new_s2,pm_new_s1,pm_new_s0}=0;
 repeat(3) begin @(posedge clk);#0.1;if({pm_prev_s3,pm_prev_s2,pm_prev_s1,pm_prev_s0} !== held) $fatal(1,"PMU hold");end
 $display("PASS: PMU 4096 updates, finite-penalty initialization priority, hold");$finish;
end
endmodule
