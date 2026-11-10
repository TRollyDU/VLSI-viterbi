module psu (
    input clk,
    input rst_n,
    input output_en,
    input [2:0] pm_s0,
    input [2:0] pm_s1,
    input [2:0] pm_s2,
    input [2:0] pm_s3,
    input [7:0] history_s0,
    input [7:0] history_s1,
    input [7:0] history_s2,
    input [7:0] history_s3,
    output reg [7:0] data_o
);
    wire s0_before_s1;
    wire s0_before_s2;
    wire s0_before_s3;
    wire s1_before_s2;
    wire s1_before_s3;
    wire s2_before_s3;
    wire select_s0;
    wire select_s1;
    wire select_s2;
    wire select_s3;
    wire [7:0] selected_history;

    // Parallel comparisons shorten the endpoint-to-output path; ties favor S0..S3.
    assign s0_before_s1 = (pm_s0 <= pm_s1);
    assign s0_before_s2 = (pm_s0 <= pm_s2);
    assign s0_before_s3 = (pm_s0 <= pm_s3);
    assign s1_before_s2 = (pm_s1 <= pm_s2);
    assign s1_before_s3 = (pm_s1 <= pm_s3);
    assign s2_before_s3 = (pm_s2 <= pm_s3);
    assign select_s0 = s0_before_s1 && s0_before_s2 && s0_before_s3;
    assign select_s1 = !s0_before_s1 && s1_before_s2 && s1_before_s3;
    assign select_s2 = !s0_before_s2 && !s1_before_s2 && s2_before_s3;
    assign select_s3 = !s0_before_s3 && !s1_before_s3 && !s2_before_s3;
    assign selected_history = ({8{select_s0}} & history_s0) |
                              ({8{select_s1}} & history_s1) |
                              ({8{select_s2}} & history_s2) |
                              ({8{select_s3}} & history_s3);

    always @(posedge clk) begin
        if (!rst_n) begin
            data_o <= 8'd0;
        end else if (output_en) begin
            data_o <= selected_history;
        end
    end
endmodule
