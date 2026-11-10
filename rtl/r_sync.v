module r_sync #(
    parameter integer ENABLE = 1
) (
    input clk,
    input rst_n,
    output wire reset_n
);
    generate
        if (ENABLE != 0) begin : gen_sync
            (* ASYNC_REG = "TRUE" *) reg meta_n;
            (* ASYNC_REG = "TRUE" *) reg sync_n;

            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    meta_n <= 1'b0;
                    sync_n <= 1'b0;
                end else begin
                    meta_n <= 1'b1;
                    sync_n <= meta_n;
                end
            end

            assign reset_n = sync_n;
        end else begin : gen_bypass
            assign reset_n = rst_n;
        end
    endgenerate
endmodule
