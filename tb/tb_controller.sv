`timescale 1ns/1ps
module tb_controller;
    logic clk = 0;
    always #2.5 clk = ~clk;
    logic rst_n = 0;
    logic start = 0;
    wire ready, step_en, re_en, finish_en, piso_shift;
    controller dut(.*);
    initial begin
        repeat (2) @(negedge clk);
        rst_n = 1;
        for (int injection = 1; injection <= 10; injection++) begin
            @(negedge clk);
            start = 1;
            for (int e = 0; e <= 10; e++) begin
                @(posedge clk); #0.1;
                if (step_en !== (e < 8) || re_en !== (e >= 1 && e <= 8) ||
                    finish_en !== (e == 9) || piso_shift !== (e < 7) || ready !== (e == 10))
                    $fatal(1, "controller phase E%0d injection=%0d", e, injection);
                @(negedge clk);
                start = (e + 1 == injection);
            end
            start = 0;
        end
        rst_n = 0;
        start = 1;
        @(posedge clk); #0.1;
        if ({ready, step_en, re_en, finish_en, piso_shift} !== 5'd0)
            $fatal(1, "controller reset priority");
        $display("PASS: controller E0-E10, busy pulses E1-E10, completion lock and reset");
        $finish;
    end
endmodule
