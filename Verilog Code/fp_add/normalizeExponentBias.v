module normalizeExponentBias(exp_overflow, in_f, out_f);
    `include "ieee-754-flags.v"
    input [EXP_BIAS-1:0] exp_overflow; //Exponent overflow based on the difference between exponent biases
    input [2*SIZE-1:0] in_f; // 8 bit minifloat and 2 bit exponent overflow for specified minifloat
    output reg [NEXP+NSIG:0] out_f; // 8 bit output minifloat 
    
    reg [NEXP-1:0] exp_diff, exp; // 2 bit exponent field of the minifloat
    reg [NSIG-1:0] sig, sig_new; // significand potentially needed to be shift
    reg sign; // Sign bit
    
    always @(*) begin
        // Extract the key features from the input minifloat 
        sign = in_f[NSIG+NEXP];
        exp = in_f[NEXP+NSIG-1:NSIG];
        sig = in_f[NSIG-1:0];
        
        if (exp_overflow >= exp) begin // Of the overflow difference is bigger than the exponent
            exp_diff = exp_overflow - exp; // Find the difference then shift the remaining bits of the significand
            sig_new = sig >> exp_diff;
            sig = sig_new; // Set the variables we'll concatenate for the final results
            exp = 0;
        end else begin
            exp_diff = exp - exp_overflow; // Otherwise find the difference of the exponent 
            exp = exp_diff;
        end
        
        out_f = {sign, exp, sig_new}; // Combine the final information together
    end
    
endmodule