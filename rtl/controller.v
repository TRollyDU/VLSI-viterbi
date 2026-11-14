module controller (
    input clk,
    input rst_n,
    input start,
    output wire ready,
    output wire step_en,
    output wire re_en,
    output wire finish_en,
    output wire piso_shift
);
    localparam [2:0] LAST_STEP = 3'd7;

    reg step_phase;
    reg finish_phase;
    reg output_phase;
    reg [2:0] step_index;
    wire last_step;

    assign last_step = (step_index == LAST_STEP);
    assign ready = rst_n && !step_phase;
    assign step_en = step_phase;
    assign re_en = (step_phase && (|step_index)) || finish_phase;
    assign finish_en = output_phase;
    assign piso_shift = step_phase && !last_step;

    always @(posedge clk) begin
        if (!rst_n) begin
            step_phase <= 1'b0;
            finish_phase <= 1'b0;
            output_phase <= 1'b0;
            step_index <= 3'd0;
        end else begin
            finish_phase <= step_phase && last_step;
            output_phase <= finish_phase;
            if (start) begin
                step_phase <= 1'b1;
                step_index <= 3'd0;
            end else if (step_phase) begin
                if (last_step) begin
                    step_phase <= 1'b0;
                end else begin
                    step_index <= step_index + 3'd1;
                end
            end
        end
    end
endmodule
