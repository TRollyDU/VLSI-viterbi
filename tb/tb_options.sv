`timescale 1ns/1ps
module option_check #(
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
    reg out_ready=1;
    wire in_ready, out_valid;
    wire [7:0] data_out;
    reg [7:0] expected[0:65535];
    reg previous_stall=0;
    reg [7:0] held;
    integer sent=0, received=0, cycle=0, last_accept=-100;
    integer outstanding;
    integer ii9_count=0;
    top #(.ENABLE_IU(IU),.ENABLE_OU(OU)) dut(.*);

    always @(posedge clk) begin
        if(rst_n) begin
            if(previous_stall && (out_valid !== 1 || data_out !== held))
                $fatal(1,"Stalled output changed mode=%0d",MODE);
            previous_stall=OU && out_valid && !out_ready;
            held=data_out;
            if(out_valid && out_ready) begin
                if(received>=sent || data_out !== expected[received] || data_out[1:0] !== 2'b00)
                    $fatal(1,"Option oracle mode=%0d word=%h got=%h expected=%h sent=%0d",MODE,received,data_out,expected[received],sent);
                received=received+1;
            end
            if(in_valid && in_ready) begin
                if(cycle-last_accept<9) $fatal(1,"Launch too early mode=%0d",MODE);
                if(cycle-last_accept==9) ii9_count=ii9_count+1;
                last_accept=cycle;
                sent=sent+1;
            end
            if(cycle<200 && sent>0 && sent<65536 && cycle-last_accept>9)
                $fatal(1,"No-stall II9 bubble mode=%0d",MODE);
            outstanding=sent-received;
            if(outstanding<0 || outstanding>2) $fatal(1,"Credits mode=%0d count=%0d",MODE,outstanding);
            cycle=cycle+1;
        end
    end

    initial begin
        finished=0;
        $readmemh("oracle.hex",expected);
        repeat(3) @(negedge clk);
        rst_n=1;
        while(received<65536) begin
            @(negedge clk);
            // Include long stalls, frequent toggles, and a no-stall II9 window.
            out_ready=(!OU || cycle<200 || ((cycle%97)>=45 && (cycle%7)!=0));
            if(IU) begin
                in_valid=(sent<65536);
                codeword_in=sent;
            end else begin
                in_valid=(sent<65536 && in_ready && (sent-received)<2 && cycle-last_accept>=9);
                codeword_in=sent;
            end
        end
        in_valid=0;
        repeat(15) @(negedge clk);
        if(out_valid !== 0 || sent!=65536 || received!=65536 || ii9_count<10)
            $fatal(1,"Option completion mode=%0d ii9_count=%0d",MODE,ii9_count);
        $display("PASS: option mode=%0d 65536/65536, II9 intervals=%0d, stalls/credits/hold",MODE,ii9_count);
        finished=1;
    end
endmodule

module tb_options;
    wire [3:0] finished;
    genvar mode;
    generate
        for(mode=0;mode<4;mode=mode+1) begin : gen_mode
            option_check #(.MODE(mode)) check_mode(.finished(finished[mode]));
        end
    endgenerate
    initial begin
        wait(&finished);
        $display("PASS: all 4 top options, 262144 oracle transactions at 200 MHz functional clock");
        $finish;
    end
    initial begin #30000000; $fatal(1,"Options watchdog"); end
endmodule
