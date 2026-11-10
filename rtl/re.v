module re (
    input clk,
    input rst_n,
    input update,
    input dec_s0,
    input dec_s1,
    input dec_s2,
    input dec_s3,
    output reg [7:0] history_s0,
    output reg [7:0] history_s1,
    output reg [7:0] history_s2,
    output reg [7:0] history_s3
);
    wire [7:0] next_history_s0;
    wire [7:0] next_history_s1;
    wire [7:0] next_history_s2;
    wire [7:0] next_history_s3;

    assign next_history_s0 = dec_s0 ? {history_s1[6:0], 1'b0} : {history_s0[6:0], 1'b0};
    assign next_history_s1 = dec_s1 ? {history_s3[6:0], 1'b0} : {history_s2[6:0], 1'b0};
    assign next_history_s2 = dec_s2 ? {history_s1[6:0], 1'b1} : {history_s0[6:0], 1'b1};
    assign next_history_s3 = dec_s3 ? {history_s3[6:0], 1'b1} : {history_s2[6:0], 1'b1};

    always @(posedge clk) begin
        if (!rst_n) begin
            history_s0 <= 8'd0;
            history_s1 <= 8'd0;
            history_s2 <= 8'd0;
            history_s3 <= 8'd0;
        end else if (update) begin
            history_s0 <= next_history_s0;
            history_s1 <= next_history_s1;
            history_s2 <= next_history_s2;
            history_s3 <= next_history_s3;
        end
    end
endmodule
