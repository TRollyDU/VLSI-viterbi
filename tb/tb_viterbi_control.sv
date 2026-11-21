`timescale 1ns/1ps
module tb_viterbi_control;
    localparam logic [15:0] FIXED_CODEWORD = 16'he2f6;
    localparam logic [7:0] FIXED_RESULT = 8'ha7;
    logic clk = 0;
    always #2.5 clk = ~clk;
    logic rstn = 0, viterbi_enable = 0;
    wire [15:0] input_data = FIXED_CODEWORD;
    wire [7:0] output_data;
    wire output_done;
    int completed = 0;
    int reset_edges = 0;
    bit reset_seen = 0;
    viterbi_top dut(.*);

    always @(posedge clk) begin
        if (!rstn) reset_edges++;
        if (reset_edges >= 2) reset_seen = 1;
        #0.1;
        if (reset_seen && !rstn && output_done !== 0) $fatal(1, "done escaped during reset propagation");
    end

    always @(negedge rstn) begin
        #0.01;
        if (reset_seen && output_done !== 0) $fatal(1, "done not masked on asynchronous reset assertion");
    end

    task automatic idle_check(input int clocks);
        repeat (clocks) begin
            @(posedge clk); #0.1;
            if (output_done !== 0) $fatal(1, "ghost done while idle");
        end
    endtask

    task automatic release_reset;
        @(negedge clk); viterbi_enable = 0; rstn = 0;
        repeat (4) @(negedge clk);
        rstn = 1;
        // Pulses during R1/R2/R3 must not start a transaction.
        for (int r = 1; r <= 3; r++) begin
            viterbi_enable = (r != 2);
            @(posedge clk); #0.1;
            if (output_done !== 0) $fatal(1, "warmup done R%0d", r);
            @(negedge clk);
        end
        viterbi_enable = 0;
        idle_check(12);
    endtask

    task automatic normal_frame(input int busy_pulse);
        logic [7:0] held;
        @(negedge clk); held = output_data; viterbi_enable = 1;
        @(posedge clk); #0.1;
        if (output_done !== 0) $fatal(1, "accept done");
        for (int e = 1; e <= 10; e++) begin
            @(negedge clk); viterbi_enable = (e == busy_pulse);
            @(posedge clk); #0.1;
            if (output_done !== (e == 10)) $fatal(1, "control latency E%0d", e);
            if (e < 10 && output_data !== held) $fatal(1, "control hold");
            if (e == 10 && output_data !== FIXED_RESULT) $fatal(1, "control result");
        end
        completed++;
    endtask

    initial begin
        release_reset();
        idle_check(20);
        for (int phase = 1; phase <= 10; phase++) begin
            normal_frame(phase);
            @(negedge clk); viterbi_enable = 0;
            idle_check(12);
        end
        // Consecutive tasks accept at exactly E11, immediately after done.
        repeat (8) normal_frame(-1);
        @(negedge clk); viterbi_enable = 0;
        idle_check(12);
        for (int phase = 0; phase <= 10; phase++) begin
            @(negedge clk); viterbi_enable = 1;
            @(posedge clk); #0.1;
            for (int e = 1; e <= phase; e++) begin
                @(negedge clk); viterbi_enable = 0;
                @(posedge clk); #0.1;
            end
            #0.3; rstn = 0;
            release_reset();
            normal_frame(-1);
            @(negedge clk); viterbi_enable = 0;
            idle_check(12);
        end
        $display("PASS: fixed e2f6 -> a7; busy pulses E1-E10, E11 restart, reset E0-E10, R1-R3 ignored, no ghost done; completed=%0d", completed);
        $finish;
    end
    initial begin #100000; $fatal(1, "control watchdog"); end
endmodule
