`timescale 1ns/1ps
module tb_viterbi_exhaustive;
    logic clk = 0;
    always #2.5 clk = ~clk;
    logic rstn = 0, viterbi_enable = 0;
    logic [15:0] input_data = 0;
    wire [7:0] output_data;
    wire output_done;
    logic [7:0] oracle [0:65535];
    logic [15:0] clean_codewords [0:255];
    int frames = 0;
    viterbi_top dut(.*);

    task automatic candidate_bound(input logic [2:0] pm, input logic [1:0] bm);
        logic [3:0] sum;
        sum = {1'b0, pm} + {2'b00, bm};
        if ((^sum) === 1'bx || sum > 7) $fatal(1, "candidate unknown/overflow pm=%0d bm=%0d", pm, bm);
    endtask

    always @(posedge clk) begin
        if (dut.core_reset_n && dut.step_en) begin
            candidate_bound(dut.pm_s0, dut.bm_00);
            candidate_bound(dut.pm_s1, 2'd2 - dut.bm_00);
            candidate_bound(dut.pm_s0, 2'd2 - dut.bm_00);
            candidate_bound(dut.pm_s1, dut.bm_00);
            candidate_bound(dut.pm_s2, dut.bm_10);
            candidate_bound(dut.pm_s3, 2'd2 - dut.bm_10);
            candidate_bound(dut.pm_s2, 2'd2 - dut.bm_10);
            candidate_bound(dut.pm_s3, dut.bm_10);
        end
    end

    task automatic frame(input logic [15:0] received, input logic [7:0] expected);
        logic [7:0] held;
        @(negedge clk);
        held = output_data;
        viterbi_enable = 1;
        input_data = received;
        @(posedge clk); #0.1;
        if (output_done !== 0 || output_data !== held) $fatal(1, "accept/hold");
        @(negedge clk);
        viterbi_enable = 0;
        input_data = ~received;
        for (int e = 1; e <= 10; e++) begin
            @(posedge clk); #0.1;
            if (output_done !== (e == 10)) $fatal(1, "done latency E%0d word=%h", e, received);
            if (e < 10 && output_data !== held) $fatal(1, "output changed before done");
            if (e == 10 && output_data !== expected)
                $fatal(1, "decode word=%h got=%h expected=%h", received, output_data, expected);
        end
        frames++;
    endtask

    initial begin
        $readmemh("oracle.hex", oracle);
        $readmemh("clean_codewords.hex", clean_codewords);
        repeat (3) @(negedge clk);
        rstn = 1;
        repeat (4) @(posedge clk);
        for (int word = 0; word < 65536; word++) frame(word[15:0], oracle[word]);
        for (int data = 0; data < 256; data++) frame(clean_codewords[data], data[7:0]);
        @(posedge clk); #0.1;
        if (output_done !== 0) $fatal(1, "done wider than one cycle");
        repeat (12) begin
            @(posedge clk); #0.1;
            if (output_done !== 0) $fatal(1, "unexpected pending frame");
        end
        $display("PASS: exhaustive 65536/65536 received words, 256/256 clean bytes, E10/II11, latched input, output hold; frames=%0d", frames);
        $finish;
    end
    initial begin #4000000; $fatal(1, "exhaustive watchdog"); end
endmodule
