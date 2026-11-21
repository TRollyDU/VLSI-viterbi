module acs (
    input [2:0] pm_s0,
    input [2:0] pm_s1,
    input [2:0] pm_s2,
    input [2:0] pm_s3,
    input [1:0] bm_00,
    input [1:0] bm_10,
    output wire [2:0] next_s0,
    output wire [2:0] next_s1,
    output wire [2:0] next_s2,
    output wire [2:0] next_s3,
    output wire decision_s0,
    output wire decision_s1,
    output wire decision_s2,
    output wire decision_s3
);
    butterfly butterfly_02 (
        .pm_a(pm_s0),
        .pm_b(pm_s1),
        .metric(bm_00),
        .next_0(next_s0),
        .next_1(next_s2),
        .dec_0(decision_s0),
        .dec_1(decision_s2)
    );

    butterfly butterfly_13 (
        .pm_a(pm_s2),
        .pm_b(pm_s3),
        .metric(bm_10),
        .next_0(next_s1),
        .next_1(next_s3),
        .dec_0(decision_s1),
        .dec_1(decision_s3)
    );
endmodule
