module reg_ex (
    input clk,
    input update,
    input dec_s0,
    input dec_s1,
    input dec_s2,
    input dec_s3,
    output [7:0] history_s0,
    output [7:0] history_s1,
    output [7:0] history_s2,
    output [7:0] history_s3
);
    reg [5:0] history6_s0, history6_s1, history6_s2, history6_s3;

    // The most recent two decoded bits are fixed by state {newest, older}.
    // Shift the selected predecessor's older bit (its low state bit, i.e.
    // the ACS decision) into the six variable history bits. Six updates
    // flush arbitrary old history, with no init or hardware reset.
    assign history_s0 = {history6_s0, 2'b00};
    assign history_s1 = {history6_s1, 2'b10};
    assign history_s2 = {history6_s2, 2'b01};
    assign history_s3 = {history6_s3, 2'b11};

    always @(posedge clk) begin
        if (update) begin
            history6_s0 <= dec_s0 ? {history6_s1[4:0], 1'b1}
                                  : {history6_s0[4:0], 1'b0};
            history6_s2 <= dec_s2 ? {history6_s1[4:0], 1'b1}
                                  : {history6_s0[4:0], 1'b0};
            history6_s1 <= dec_s1 ? {history6_s3[4:0], 1'b1}
                                  : {history6_s2[4:0], 1'b0};
            history6_s3 <= dec_s3 ? {history6_s3[4:0], 1'b1}
                                  : {history6_s2[4:0], 1'b0};
        end
    end
endmodule
