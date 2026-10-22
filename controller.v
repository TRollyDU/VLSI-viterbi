module controller (
    input clk,
    input rst_n,
    input accept, // Qualified by optional input_handshake, or external start pulse.
    output first_step,
    output reg init_en,
    output reg add_en,
    output reg step_en,
    output reg reg_ex_en,
    output reg output_en,
    output reg final_re_en,
    output reg piso_load,
    output reg piso_shift,
    output reg piso_hold,
    output pm_write_en
);
    reg [2:0] step_index;
    wire last_step;
    // Reuse the registered commit phase. E1 initialization has priority
    // inside PMU, so the former extra E1 write pulse was unnecessary.
    assign pm_write_en = step_en;

    // E0 captures pair 1; E1 initializes its two reachable PM; E2/E3 through E14/E15
    // are seven COMPARE/SELECT+ADD pairs for trellis steps 2-8.
    assign last_step = (step_index == 3'd6);
    assign first_step = (step_index == 3'd0);
    // ADD/SELECT are registered one-hot phases. Consumers see FF outputs,
    // rather than active/phase decoding on the datapath enable path.
    // last_step is decoded before the enable FFs, one edge ahead of SELECT.

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            init_en <= 1'b0;
            add_en <= 1'b0;
            step_en <= 1'b0;
            reg_ex_en <= 1'b0;
            output_en <= 1'b0;
            final_re_en <= 1'b0;
            piso_load <= 1'b1;
            piso_shift <= 1'b0;
            piso_hold <= 1'b0;
            step_index <= 3'd0;
        end else begin
            init_en <= accept;
            reg_ex_en <= step_en;
            // E16 finishes history and arms the registered output for E17.
            final_re_en <= step_en && last_step;
            output_en <= final_re_en;

            // ADD -> SELECT; non-final SELECT -> next ADD.
            step_en <= add_en;
            add_en <= init_en || (step_en && !last_step);

            // Predecode one-hot PISO operations into independent FFs.
            // Shift at E2/E4/E6/E8/E10/E12. At E13 the final pair's BM
            // is captured; PISO can preload again from E14 onward.
            // These FFs differ from add_en/step_en and cannot simply merge
            // with those markers because their final-step behavior differs.
            piso_shift <= init_en || (step_en && (step_index < 3'd5));
            piso_hold <= add_en && !last_step;
            if (step_en && step_index == 3'd5)
                piso_load <= 1'b1;

            if (accept) begin
                add_en <= 1'b0;
                step_en <= 1'b0;
                step_index <= 3'd0;
                piso_load <= 1'b0;
                piso_shift <= 1'b0;
                piso_hold <= 1'b1;
            end else if (step_en && !last_step) begin
                step_index <= step_index + 3'd1;
            end
        end
    end
endmodule
