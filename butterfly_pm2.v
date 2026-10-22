module butterfly_pm2 (
    input [1:0] pm_a, 
    input [1:0] pm_b,  
    input [1:0] metric, //d
    output dec_0, dec_1
);

    wire gt_plus2 = (&pm_a) & (~|pm_b); // delta>+2: A=3, B=0 
    wire gt_zero = pm_a > pm_b; // delta>0
    
    // delta>-2 : A>=2: pm_a[1] == 1
    //            B<=1: pm_b[1] == 0
    //            A = 1, B = 2
    wire gt_minus2 = pm_a[1] | ~pm_b[1] | (pm_a[0] & ~pm_b[0]); 
        
    // metric=01 → gt_zero.
    // metric=10 → gt_minus2.
    // metric=00 → gt_plus2.

    assign dec_0 = metric[0] ? gt_zero : 
                    (metric[1] ? gt_minus2 : gt_plus2);
    assign dec_1 = metric[0] ? gt_zero : 
                    (metric[1] ? gt_plus2 : gt_minus2);


                    
    //for sim only(will detele in final version
    wire [2:0] sum_A = {1'b0,pm_a} + {1'b0,metric};
endmodule
