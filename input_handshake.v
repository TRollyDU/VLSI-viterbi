// Optional input-side protection. Output ready/valid lives in output_register.
module input_handshake #(
    parameter ENABLE = 0
) (
    input clk,
    input rst_n,
    input in_valid,
    input out_valid,
    input out_ready,
    output in_ready,
    output accept
);
    generate
        if (ENABLE) begin : g_enabled
            reg busy;
            reg ready_q;
            assign in_ready = ready_q;
            assign accept = in_valid && ready_q;
            // One outstanding frame, including a stalled output. R1 after
            // reset release arms ready; first acceptance can occur at R2.
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    busy <= 1'b0;
                    ready_q <= 1'b0;
                end else if (accept) begin
                    busy <= 1'b1;
                    ready_q <= 1'b0;
                end else if (out_valid && out_ready) begin
                    busy <= 1'b0;
                    ready_q <= 1'b1;
                end else if (!busy) begin
                    ready_q <= 1'b1;
                end
            end
        end else begin : g_bypass
            // Zero input-handshake FF. in_valid is a ONE-CLOCK start pulse.
            // External logic waits for completion/output transfer before
            // another start. in_ready is unused/tied high, even during reset.
            // No busy protection or R1 warmup is provided in this mode.
            assign in_ready = 1'b1;
            assign accept = in_valid;
        end
    endgenerate
endmodule
