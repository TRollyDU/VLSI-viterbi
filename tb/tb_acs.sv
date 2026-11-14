`timescale 1ns/1ps
module tb_acs;
reg [1:0] bm_a,bm_b; reg [2:0] pm_prev_a,pm_prev_b; wire [2:0] pm_new; wire dec_out;
acs dut(.*);
integer a,b,x,y,ca,cb,selected,checked=0,excluded=0;
initial begin
 for(a=0;a<8;a=a+1) for(b=0;b<8;b=b+1) for(x=0;x<4;x=x+1) for(y=0;y<4;y=y+1) begin
  pm_prev_a=a;pm_prev_b=b;bm_a=x;bm_b=y;ca=a+x;cb=b+y;selected=(cb<ca)?cb:ca; #1;
  if(ca<=7 && cb<=7) begin
   checked=checked+1;
   if(dec_out !== (cb<ca) || pm_new !== selected[2:0]) $fatal(1,"ACS %0d %0d %0d %0d",a,b,x,y);
  end else excluded=excluded+1;
 end
 $display("PASS: ACS bounded candidates, ties A; checked=%0d overflow tuples outside contract=%0d",checked,excluded); $finish;
end
endmodule
