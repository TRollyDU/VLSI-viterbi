`timescale 1ns/1ps
module tb_smu;
    logic clk = 0;
    always #2.5 clk = ~clk;
    logic rst_n = 0, update = 0, finish = 0;
    logic [3:0] decisions = 0;
    logic [2:0] pm_s0, pm_s1, pm_s2, pm_s3;
    wire [7:0] result;
    logic [7:0] history [0:3];
    logic [7:0] next_history [0:3];
    logic [7:0] held;
    int pm [0:3];
    int winner;
    int seed = 32'h16210021;
    smu dut(.*);

    task automatic history_step(input logic [3:0] decision);
        @(negedge clk);
        update = 1;
        decisions = decision;
        for (int s = 0; s < 4; s++)
            next_history[s] = {history[(s & 1) * 2 + decision[s]][6:0], (s >= 2)};
        @(posedge clk); #0.1;
        for (int s = 0; s < 4; s++) history[s] = next_history[s];
    endtask

    initial begin
        for (int s = 0; s < 4; s++) history[s] = 0;
        repeat (2) @(negedge clk);
        rst_n = 1;
        // Eight updates establish valid histories without datapath reset.
        for (int k = 0; k < 8; k++) history_step(k[3:0]);
        @(negedge clk); update = 0;
        for (int n = 0; n < 4096; n++) begin
            if ((n % 7) == 0) begin
                history_step($random(seed));
                @(negedge clk); update = 0;
            end
            {pm_s3, pm_s2, pm_s1, pm_s0} = n[11:0];
            pm[0] = pm_s0; pm[1] = pm_s1; pm[2] = pm_s2; pm[3] = pm_s3;
            winner = 0;
            for (int s = 1; s < 4; s++) if (pm[s] < pm[winner]) winner = s;
            finish = 1;
            @(posedge clk); #0.1;
            if (result !== history[winner])
                $fatal(1, "SMU endpoint/tie n=%h winner=%0d got=%h expected=%h", n, winner, result, history[winner]);
            held = result;
            @(negedge clk); finish = 0; decisions = ~decisions;
            @(posedge clk); #0.1;
            if (result !== held) $fatal(1, "SMU output hold");
            @(negedge clk);
        end
        rst_n = 0; finish = 1;
        @(posedge clk); #0.1;
        if (result !== 0) $fatal(1, "SMU result reset priority");
        $display("PASS: SMU 4096 metric tuples, history model, all endpoint ties, hold and reset");
        $finish;
    end
endmodule
