module controller (
    input clk,
    input rst_n,
    input in_valid,
    output step_en,
    output reg_ex_en,
    output output_en,
    output piso_shift
);
    reg step_phase;
    reg reg_ex_phase;
    reg output_phase;
    reg [2:0] step_index;
    wire last_step;

    // E1-E6 process trellis steps 3-8; E0 precomputes steps 1-2.
    assign last_step = (step_index == 3'd5);
    assign step_en = step_phase;
    assign reg_ex_en = reg_ex_phase;
    assign output_en = output_phase;
    assign piso_shift = step_en && !last_step;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            step_phase <= 1'b0;
            reg_ex_phase <= 1'b0;
            output_phase <= 1'b0;
            step_index <= 3'd0;
        end else begin
            reg_ex_phase <= step_phase;
            // E7 finishes the sixth history update and arms output for E8.
            output_phase <= reg_ex_phase && !step_phase;

            if (in_valid) begin
                step_phase <= 1'b1;
                step_index <= 3'd0;
            end else if (step_phase) begin
                if (last_step)
                    step_phase <= 1'b0;
                else
                    step_index <= step_index + 3'd1;
            end
        end
    end
endmodule
