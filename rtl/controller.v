module controller (
    input clk,
    input rst_n,
    input start,
    output wire ready,
    output reg step_en,
    output reg sample_en,
    output reg re_en,
    output reg finish_en,
    output reg select_en,
    output wire piso_load,
    output wire piso_shift
);
    localparam [2:0] LAST_STEP = 3'd7;

    reg [2:0] step_index;
    reg idle;
    wire accept;
    wire last_step;

    assign ready = rst_n && idle;
    assign accept = start && ready;
    assign last_step = (step_index == LAST_STEP);
    assign piso_load = sample_en;
    assign piso_shift = step_en && !last_step;

    always @(posedge clk) begin
        if (!rst_n) begin
            step_index <= 3'd0;
            idle <= 1'b1;
            sample_en <= 1'b0;
            step_en <= 1'b0;
            re_en <= 1'b0;
            finish_en <= 1'b0;
            select_en <= 1'b0;
        end else begin
            sample_en <= accept;
            step_en <= sample_en || (step_en && !last_step);
            re_en <= step_en;
            select_en <= step_en && last_step;
            finish_en <= select_en;
            if (accept) begin
                step_index <= 3'd0;
                idle <= 1'b0;
            end else begin
                if (step_en && !last_step) begin
                    step_index <= step_index + 3'd1;
                end
                if (finish_en) begin
                    idle <= 1'b1;
                end
            end
        end
    end
endmodule
