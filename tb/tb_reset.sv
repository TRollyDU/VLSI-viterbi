`timescale 1ns/1ps
module reset_check #(
    parameter integer MODE=0
)(output reg finished);
    localparam integer SYNC=(MODE>>1)&1;
    localparam integer IU=(MODE>>1)&1;
    localparam integer OU=MODE&1;
    reg clk=0;
    always #2.5 clk=~clk;
    reg rst_n=0;
    reg in_valid=0;
    reg [15:0] codeword_in=0;
    reg out_ready=0;
    wire in_ready,out_valid;
    wire [7:0] data_out;
    reg [7:0] expected[0:65535];
    integer phase, edge_no, delay_count;
    top #(.ENABLE_IU(IU),.ENABLE_OU(OU)) dut(.*);

    task automatic launch(input [15:0] value);
        begin
            @(negedge clk);
            while(!in_ready) @(negedge clk);
            codeword_in=value; in_valid=1;
            @(posedge clk); #0.1;
            @(negedge clk); in_valid=0;
        end
    endtask

    task automatic reset_and_release;
        begin
            #0.2 rst_n=0;
            #0.1;
            if(in_ready !== 0 || out_valid !== 0) $fatal(1,"Reset interface mask mode=%0d",MODE);
            repeat(3) @(negedge clk);
            rst_n=1;
            if(SYNC) begin
                if(in_ready !== 0) $fatal(1,"Reset warmup mode=%0d",MODE);
                @(posedge clk); #0.1;
                if(in_ready !== 0) $fatal(1,"Reset released before two edges mode=%0d",MODE);
                @(posedge clk); #0.1;
                if(in_ready !== 0) $fatal(1,"Core reset register must wait through R2 mode=%0d",MODE);
                @(posedge clk); #0.1;
                if(in_ready !== 1) $fatal(1,"Reset readiness after R3 mode=%0d",MODE);
            end else begin
                if(in_ready !== 0) $fatal(1,"Bypass core reset warmup mode=%0d",MODE);
                @(posedge clk); #0.1;
                if(in_ready !== 1) $fatal(1,"Bypass readiness after R1 mode=%0d",MODE);
            end
            repeat(14) begin
                @(posedge clk); #0.1;
                if(out_valid !== 0) $fatal(1,"Ghost result after reset mode=%0d",MODE);
            end
        end
    endtask

    initial begin
        finished=0;
        $readmemh("oracle.hex",expected);
        repeat(3) @(negedge clk);
        rst_n=1;
        for(phase=0;phase<=12;phase=phase+1) begin
            launch(16'ha596);
            for(edge_no=1;edge_no<=phase;edge_no=edge_no+1) begin
                @(posedge clk); #0.1;
            end
            reset_and_release();
            out_ready=1;
            launch(16'h1234);
            delay_count=0;
            while(!out_valid && delay_count<20) begin
                @(negedge clk); delay_count=delay_count+1;
            end
            if(!out_valid || data_out !== expected[16'h1234] || data_out[1:0] !== 2'b00) $fatal(1,"Restart/tail mode=%0d phase=%0d",MODE,phase);
            repeat(3) @(negedge clk);
            out_ready=0;
        end
        // Fill both output slots, then reset with a source waiting for capacity.
        if(IU && OU) begin
            launch(16'h1234);
            launch(16'h5678);
            repeat(14) @(negedge clk);
            in_valid=1; codeword_in=16'hffff;
            if(in_ready !== 0) $fatal(1,"Expected credit backpressure mode=%0d",MODE);
            #0.2 rst_n=0;
            @(negedge clk); in_valid=0;
            reset_and_release();
        end
        $display("PASS: reset mode=%0d phases E0..E12, registered-core reset warmup, abort/restart, pending output/source",MODE);
        finished=1;
    end
endmodule

module tb_reset;
    wire [3:0] finished;
    genvar mode;
    generate
        for(mode=0;mode<4;mode=mode+1) begin : gen_mode
            reset_check #(.MODE(mode)) check_mode(.finished(finished[mode]));
        end
    endgenerate
    initial begin
        wait(&finished);
        $display("PASS: all 4 options reset, stalled-output cancellation and no ghost transactions");
        $finish;
    end
    initial begin #200000; $fatal(1,"Reset watchdog"); end
endmodule
