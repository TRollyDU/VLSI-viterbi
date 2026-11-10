`timescale 1ns/1ps
module tb_ou;
reg clk=0;always #2.5 clk=~clk;
reg rst_n=0,core_done=0,out_ready=0;reg [7:0] core_result=0;
wire out_valid;wire [7:0] data_out;wire raw_valid;wire [7:0] raw_data;
ou dut(.*);
ou #(.ENABLE(0)) raw(.clk(clk),.rst_n(rst_n),.core_done(core_done),.core_result(core_result),.out_ready(out_ready),.out_valid(raw_valid),.data_out(raw_data));
integer n,count=0,seed=32'h789abc,pop,both_one=0,both_two=0,stalls=0;
reg [7:0] first=0,second=0;
initial begin
 for(n=0;n<4096;n=n+1) begin
  @(negedge clk);rst_n=(n%149>=2);out_ready=$random(seed);
  core_done=(count<2 || out_ready) && (($random(seed)&3)!=0);core_result=$random(seed);
  #0.1;
  if(raw_valid !== (rst_n && core_done) || raw_data !== core_result) $fatal(1,"OU bypass");
  if(out_valid !== (rst_n && count!=0)) $fatal(1,"OU valid");
  if(rst_n && count>0 && data_out !== first) $fatal(1,"OU output/hold");
  pop=(count>0 && out_ready);
  @(posedge clk);
  if(!rst_n) begin count=0;first=0;second=0;end
  else begin
   if(count>0 && !out_ready) stalls=stalls+1;
   if(core_done && pop) begin
    if(count==1) begin first=core_result;both_one=both_one+1;end
    else begin first=second;second=core_result;both_two=both_two+1;end
   end else if(core_done) begin
    if(count==0) first=core_result;else second=core_result;count=count+1;
   end else if(pop) begin if(count==2) first=second;count=count-1;end
  end
  #0.1;if(out_valid !== (rst_n && count!=0) || data_out !== first) $fatal(1,"OU model n=%0d",n);
 end
 if(both_one<5 || both_two<5 || stalls<20) $fatal(1,"OU coverage");
 $display("PASS: OU two-entry queue/bypass, both simultaneous cases, stalls, ordering, reset");$finish;
end
endmodule
