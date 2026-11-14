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
    task check_candidate;
        input [2:0] pm;
        input [1:0] bm;
        reg [3:0] sum;
        begin
            sum = {1'b0, pm} + {2'b00, bm};
            if (sum > 4'd7 || (^sum) === 1'bx)
                $fatal(1,"ACS candidate overflow/unknown word=%h pm=%d bm=%d",word,pm,bm);
        end
    endtask
    always @(posedge clk) begin
        if (rst_n && dut.step_en) begin
            check_candidate(dut.pm_s0, dut.bm_00);
            check_candidate(dut.pm_s1, dut.bm_11);
            check_candidate(dut.pm_s2, dut.bm_10);
            check_candidate(dut.pm_s3, dut.bm_01);
            check_candidate(dut.pm_s0, dut.bm_11);
            check_candidate(dut.pm_s1, dut.bm_00);
            check_candidate(dut.pm_s2, dut.bm_01);
            check_candidate(dut.pm_s3, dut.bm_10);
        end
    end
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
                        $fatal(1,"Terminated S0 mismatch word=%h got=%h expected=%h",word-1,result,expected[word-1]);
                    if(result[1:0] !== 2'b00) $fatal(1,"Decoded tail is not 00");
                    held=result;
                end else if(done !== 0 || result !== held) begin
                    $fatal(1,"Core latency/hold word=%h stage=%0d",word,stage);
                end
            end
        end
        @(posedge clk); #0.1;
        if(done !== 0) $fatal(1,"Early final core result at E9");
        @(posedge clk); #0.1;
        if(done !== 1 || result !== expected[65535] || result[1:0] !== 2'b00) $fatal(1,"Final core result");
        @(posedge clk); #0.1;
        if(done !== 0) $fatal(1,"Done is not a pulse");
        $display("PASS: fixed-S0 integer oracle 65536/65536; tail 00; core E10 and continuous II9; changed word after E0; stable result");
        $finish;
    end
    initial begin #4000000; $fatal(1,"Core watchdog"); end
endmodule
