`timescale 1ns/1ps
module tb_iu;
reg clk=0;always #2.5 clk=~clk;
reg rst_n=0,in_valid=0,core_ready=0,output_transfer=0;reg [15:0] word_in=0;
wire reset_n,in_ready,start;wire [15:0] word_out;
wire raw_reset,raw_ready,raw_start;wire [15:0] raw_word;
iu dut(.*);
iu #(.ENABLE(0)) raw(.clk(clk),.rst_n(rst_n),.in_valid(in_valid),.word_in(word_in),.core_ready(core_ready),.output_transfer(output_transfer),.reset_n(raw_reset),.in_ready(raw_ready),.start(raw_start),.word_out(raw_word));
integer n,count=0,seed=32'h2468;reg meta=0,sync=0,old_meta,expected_ready;integer accepts=0,simultaneous=0;
initial begin
 #0.1;rst_n=1;#0.1;rst_n=0;
 for(n=0;n<2048;n=n+1) begin
  @(negedge clk);rst_n=(n%97>=3);in_valid=$random(seed);core_ready=$random(seed);word_in=$random(seed);
  output_transfer=(count>0 && (($random(seed)&3)!=0));
  if(!rst_n) begin meta=0;sync=0;end
  #0.1;expected_ready=sync && core_ready && count<2;
  if(reset_n !== sync || in_ready !== expected_ready || start !== (in_valid && expected_ready) || word_out !== word_in) $fatal(1,"IU interface n=%0d",n);
  if(raw_reset !== rst_n || raw_ready !== (rst_n && core_ready) || raw_start !== (rst_n && core_ready && in_valid) || raw_word !== word_in) $fatal(1,"IU bypass");
  @(posedge clk);
  if(!sync) count=0;else begin
   if(in_valid && expected_ready) begin count=count+1;accepts=accepts+1;end
   if(output_transfer) count=count-1;
   if(in_valid && expected_ready && output_transfer) simultaneous=simultaneous+1;
  end
  old_meta=meta;meta=rst_n;sync=rst_n && old_meta;
  #0.1;if(reset_n !== sync) $fatal(1,"IU sync release");
 end
 if(accepts<20 || simultaneous<5) $fatal(1,"IU coverage");
 $display("PASS: IU enabled/bypass, reset warmup, credits, busy gating, simultaneous accept/transfer");$finish;
end
endmodule
