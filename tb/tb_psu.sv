`timescale 1ns/1ps
module tb_psu;
    reg clk = 0;
    always #2.5 clk = ~clk;
    reg rst_n = 0;
    reg output_en = 0;
    reg [2:0] pm_s0, pm_s1, pm_s2, pm_s3;
    reg [7:0] history_s0 = 8'h96;
    reg [7:0] history_s1 = 8'h69;
    reg [7:0] history_s2 = 8'hc3;
    reg [7:0] history_s3 = 8'h3c;
    wire [7:0] data_o;
    reg [7:0] expected;
    reg [7:0] held;
    integer vector, best, minimum;
    psu dut (.*);
    initial begin
        repeat (2) @(negedge clk);
        if (data_o !== 0) $fatal(1,"PSU reset");
        rst_n = 1;
        for (vector=0; vector<4096; vector=vector+1) begin
            pm_s0=vector[2:0]; pm_s1=vector[5:3];
            pm_s2=vector[8:6]; pm_s3=vector[11:9];
            minimum=pm_s0; best=0;
            if (pm_s1<minimum) begin minimum=pm_s1; best=1; end
            if (pm_s2<minimum) begin minimum=pm_s2; best=2; end
            if (pm_s3<minimum) begin minimum=pm_s3; best=3; end
            case(best)
                0: expected=history_s0;
                1: expected=history_s1;
                2: expected=history_s2;
                3: expected=history_s3;
            endcase
            output_en=1;
            @(posedge clk); #0.1;
            if(data_o !== expected) $fatal(1,"PSU vector=%h got=%h expected=%h",vector,data_o,expected);
            @(negedge clk);
        end
        output_en=0; held=data_o;
        repeat(3) begin @(posedge clk); #0.1; if(data_o !== held) $fatal(1,"PSU hold"); end
        @(negedge clk); rst_n=0; output_en=1;
        @(posedge clk); #0.1;
        if(data_o !== 0) $fatal(1,"PSU reset priority");
        $display("PASS: PSU 4096 metric combinations, lowest-state ties, registered output, hold and synchronous reset");
        $finish;
    end
endmodule
