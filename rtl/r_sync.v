module r_sync (
    input clk,
    input rst_n,
    output wire reset_n
);
    (* ASYNC_REG = "TRUE" *) reg meta_n;
    (* ASYNC_REG = "TRUE" *) reg sync_n;

    assign reset_n = sync_n;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            meta_n <= 1'b0;
            sync_n <= 1'b0;
        end else begin
            meta_n <= 1'b1;
            sync_n <= meta_n;
        end
    end
endmodule
