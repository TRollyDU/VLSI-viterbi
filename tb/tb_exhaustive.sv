`timescale 1ns/1ps
module tb_exhaustive;
    reg clk=0;
    always #2.5 clk=~clk;
    reg rst_n=0;
    reg start=0;
    reg [15:0] word_in=0;
    wire ready, done;
    wire [7:0] result;
    reg [7:0] expected[0:65535];
    reg [7:0] held;
    integer word, stage;
    viterbi dut(.*);
    initial begin
        $readmemh("oracle.hex",expected);
        repeat(3) @(negedge clk);
        rst_n=1;
        for(word=0;word<65536;word=word+1) begin
            @(negedge clk);
            if(ready !== 1) $fatal(1,"Core not ready for II9 word=%h",word);
            start=1; word_in=word;
            @(posedge clk); #0.1;
            if(done !== 0) $fatal(1,"Unexpected output on E9 overlap word=%h",word);
            held=result;
            @(negedge clk); start=0; word_in=~word;
            for(stage=1;stage<=8;stage=stage+1) begin
                @(posedge clk); #0.1;
                if(stage==1 && word!=0) begin
                    if(done !== 1 || result !== expected[word-1])
                        $fatal(1,"Pipelined PM/history mismatch word=%h got=%h expected=%h",word-1,result,expected[word-1]);
                    held=result;
                end else if(done !== 0 || result !== held) begin
                    $fatal(1,"Core latency/hold word=%h stage=%0d",word,stage);
                end
            end
        end
        @(posedge clk); #0.1;
        if(done !== 0) $fatal(1,"Early final core result at E9");
        @(posedge clk); #0.1;
        if(done !== 1 || result !== expected[65535]) $fatal(1,"Final core result");
        @(posedge clk); #0.1;
        if(done !== 0) $fatal(1,"Done is not a pulse");
        $display("PASS: independent integer oracle 65536/65536; PMU-to-PSU pipeline core E10 and continuous II9; changed word after E0; stable result");
        $finish;
    end
    initial begin #4000000; $fatal(1,"Core watchdog"); end
endmodule
