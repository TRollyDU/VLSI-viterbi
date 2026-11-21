`timescale 1ns/1ps
module tb_butterfly;
    reg [2:0] pm_a, pm_b;
    reg [1:0] metric;
    wire [2:0] next_0, next_1;
    wire dec_0, dec_1;
    integer a, b, d, ca0, cb0, ca1, cb1, n0, n1;
    integer checked = 0;
    butterfly dut(.*);
    initial begin
        for (a=0; a<8; a=a+1)
            for (b=0; b<8; b=b+1)
                for (d=0; d<3; d=d+1) begin
                    pm_a=a; pm_b=b; metric=d;
                    ca0=a+d; cb0=b+2-d;
                    ca1=a+2-d; cb1=b+d;
                    n0=(cb0<ca0) ? cb0 : ca0;
                    n1=(cb1<ca1) ? cb1 : ca1;
                    #1;
                    if (dec_0 !== (cb0<ca0) || dec_1 !== (cb1<ca1))
                        $fatal(1,"Butterfly decision a=%0d b=%0d d=%0d",a,b,d);
                    if (next_0 !== n0[2:0] || next_1 !== n1[2:0])
                        $fatal(1,"Butterfly sum a=%0d b=%0d d=%0d",a,b,d);
                    checked=checked+1;
                end
        $display("PASS: butterfly all %0d PM3/Hamming tuples; ties A; sums modulo 8 outside frame bound",checked);
        $finish;
    end
endmodule
