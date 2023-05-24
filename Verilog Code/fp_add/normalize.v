`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/06/2023 05:29:56 PM
// Design Name: 
// Module Name: normalize
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module normalize(exp_overflow, in_f, out_f, normAdd);

    // Key Notes, The max function previously will mean that exp_overflow will be larger than all the other overflow
    // Values, hence when we subtract the overflow with the largest minifloat, it will remain unchanged and all other
    // Minifloats will either be untouched, have their exponent decremented or significand shifted.  
    // When normAdd is 1, we add the exp_overflow to all exponents and due to prior computation, we will add it without
    // Incurring any additional overflow as that value is calculated to be the difference between EMAX and largest minifloat
    
    `include "ieee-754-flags.v"
    input [NEXP-1:0] exp_overflow; //2 bit exponent overflow
    input [(NEXP+SIZE)-1:0] in_f; // 8 bit minifloat and 2 bit exponent overflow for specified minifloat
    input normAdd; // Whether we are subtracting the exp_overflow or adding it to the exponents
    output reg [SIZE-1:0] out_f; // 8 bit output minifloat 
    
    reg [NEXP-1:0] overflow_diff, overflow_in; // overflow exponent for input minifloat and differences of overflow exponents
    reg [NEXP-1:0] exp_diff, exp; // 2 bit exponent field of the minifloat
    reg [NSIG-1:0] sig, sig_new; // significand potentially needed to be shift
    reg sign; // Sign bit
    
    always @(*) begin
    
        sign = in_f[NSIG+NEXP];
        exp = in_f[NEXP+NSIG-1:NSIG];
        sig = in_f[NSIG-1:0];
    
        if (normAdd == 1) begin // If we are normalizing by increasing the exponent, then we add to the exponent
            exp = exp + exp_overflow;
        
        end else begin
            overflow_in = in_f[2*NEXP+NSIG:NEXP+NSIG+1]; // Extract the key features from the input minifloat 
            
            overflow_diff = exp_overflow - overflow_in; // Obtain the overflow differences
            
            if (overflow_diff >= exp) begin // Of the overflow difference is bigger than the exponent
                exp_diff = overflow_diff - exp; // Find the difference then shift the remaining bits of the significand
                sig_new = sig >> exp_diff;
                sig = sig_new; // Set the variables we'll concatenate for the final results
                exp = 0;
            end else begin
                exp_diff = exp - overflow_diff; // Otherwise find the difference of the exponent 
                exp = exp_diff;
            end
            
        end
        
        out_f = {sign, exp, sig_new}; // Combine the final information together
    end
    
endmodule
