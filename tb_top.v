`timescale 1ns/1ps

// Testbench doc input.txt, dua tung codeword vao top va so sanh voi output.txt.
// Moi dong input.txt: 16 bit nhi phan.
// Moi dong output.txt: 8 bit nhi phan.
module tb_top;

    reg         clk;
    reg         rst_n;
    reg         in_valid;
    reg [15:0]  codeword_in;
    wire        out_valid;
    wire        in_ready;
    wire [7:0]  data_out;

    integer fin, fout;
    integer rc_in, rc_out;
    integer total, pass, fail;
    integer timeout;
    reg [15:0] input_value;
    reg [7:0]  expected_value;

    // The supplied files require a known zero-tail endpoint.
    top #(.ZERO_TAIL(1)) dut (
        .clk         (clk),
        .rst_n       (rst_n),
        .in_valid    (in_valid),
        .in_ready    (in_ready),
        .codeword_in (codeword_in),
        .out_valid   (out_valid),
        .out_ready   (1'b1),
        .data_out    (data_out)
    );

    localparam real CLK_PERIOD_NS = 1000.0/350.0;
    always #(CLK_PERIOD_NS/2.0) clk = ~clk;

    // Hold the request until an input handshake; output is always ready.
    task automatic run_vector;
        begin
            @(negedge clk);
            codeword_in = input_value;
            in_valid    = 1'b1;
            @(posedge clk);
            while (!in_ready) @(posedge clk);
            @(negedge clk);
            in_valid    = 1'b0;

            timeout = 0;
            while (!out_valid && timeout < 100) begin
                @(posedge clk);
                #1;
                timeout = timeout + 1;
            end

            if (timeout >= 100) begin
                $display("FAIL vector %0d: timeout, input=%016b",
                         total + 1, input_value);
                fail = fail + 1;
            end
            else if (timeout != 17) begin
                $fatal(1,"Expected E17, observed E%0d",timeout);
            end
            else if (data_out !== expected_value) begin
                $display("FAIL vector %0d: input=%016b expected=%08b actual=%08b",
                         total + 1, input_value, expected_value, data_out);
                fail = fail + 1;
            end
            else begin
                pass = pass + 1;
            end
            total = total + 1;

            @(negedge clk);
            repeat (1) @(posedge clk);
        end
    endtask

    initial begin
        clk         = 1'b0;
        rst_n       = 1'b0;
        in_valid    = 1'b0;
        codeword_in = 16'd0;
        total       = 0;
        pass        = 0;
        fail        = 0;

        fin  = $fopen("input.txt",  "r");
        fout = $fopen("output.txt", "r");
        if (fin == 0 || fout == 0) begin
            $display("ERROR: khong mo duoc input.txt/output.txt");
            $fatal(1, "Cannot open vector files");
        end

        // Reset dong bo voi clock.
        repeat (3) @(posedge clk);
        @(negedge clk);
        rst_n = 1'b1;

        while (!$feof(fin)) begin
            rc_in = $fscanf(fin, "%b\n", input_value);
            if (rc_in == 1) begin
                rc_out = $fscanf(fout, "%b\n", expected_value);
                if (rc_out != 1) begin
                    $display("ERROR: output.txt thieu vector %0d", total + 1);
                    $fatal(1, "Expected vector missing");
                end
                run_vector;
            end
            else if (!$feof(fin)) begin
                $display("ERROR: input.txt co dong khong hop le");
                $fatal(1, "Malformed input vector");
            end
        end

        rc_out = $fscanf(fout, "%b\n", expected_value);
        if (rc_out == 1) begin
            $display("ERROR: output.txt co them vector");
            $fatal(1, "Extra expected vector");
        end

        $fclose(fin);
        $fclose(fout);

        $display("COMPARE SUMMARY: total=%0d pass=%0d fail=%0d",
                 total, pass, fail);
        if (total != 1025 || fail != 0)
            $fatal(1, "File comparison failed");
        $display("PASS: tb_top 1025/1025 ZERO_TAIL=1 file vectors, E17, RTL clock 350 MHz");
        $finish;
    end

endmodule
