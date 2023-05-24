`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Copyright: Chris Larsen 2019
// Engineer: Chris Larsen
//
// Create Date: 07/26/2019 07:05:10 PM
// Design Name: Parameterized Floating Point Multiplier
// Module Name: fp_mul
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

module fp_mul(a, b, p, exp_overflow, pFlags);
  `include "ieee-754-flags.v"
  input [NEXP+NSIG:0] a, b; // Input FP values 
  output [NEXP+NSIG:0] p; // Output FP value
  output [LAST_FLAG-1:0] pFlags; // Flags for the FP value
  output reg [NEXP:0] exp_overflow; // Temporary value for storing the overlfow values 
  reg [LAST_FLAG-1:0] pFlags; // Previouys flags experienced by the adder

  wire signed [NEXP+1:0] aExp, bExp; // Temporary exponent values for input a and b
  reg signed [NEXP+1:0] pExp, t1Exp, t2Exp; // Exponent values for the final value and two temporary values
  wire [NSIG:0] aSig, bSig; // Temporary significand values for input a and b
  reg [NSIG:0] pSig, tSig; // Significand values for the final value and temporary values

  reg [NEXP+NSIG:0] pTmp; // The final complete result

  wire [2*NSIG+1:0] rawSignificand; // Raw significand

  wire [LAST_FLAG-1:0] aFlags, bFlags; // Flags for the input values

  reg pSign; // The resulting sign from the multiplication of the two inputs a and b
    
  // Find the flags based on the input values
  fp_class #(NEXP,NSIG) aClass(a, aExp, aSig, aFlags); 
  fp_class #(NEXP,NSIG) bClass(b, bExp, bSig, bFlags);

  // Compute the raw significand via multiplication and store it into the raw significand variable
  assign rawSignificand = aSig * bSig;

  always @(*)
  begin
    // IEEE 754-2019, section 6.3 requires that "[w]hen neither the
    // inputs nor result are NaN, the sign of a product ... is the
    // exclusive OR of the operands' signs".
    pSign = a[NEXP+NSIG] ^ b[NEXP+NSIG]; // Compute the sign of the resulting vaues
    pTmp = {pSign, {NEXP{1'b1}}, 1'b0, {NSIG-1{1'b1}}};  // Initialize p to be an sNaN.
    pFlags = 6'b000000; // Currently no flags are set, SNAN, QNAN and INFINITY flags will always be 0
    exp_overflow = 0;

//    For our case, we don't consider qNan's, sNan's and Infinities, we will comment them out
//   We consider only cases for 0, normal and subnormal, based on the flags pre-computed
//   In the case that we multiply by 0, the resulting answer would be simply 0 and return.
//   Note: How does this work in regards to gradual underflow?
     if ((aFlags[ZERO] | bFlags[ZERO]) == 1'b1 ||
             (aFlags[SUBNORMAL] & bFlags[SUBNORMAL]) == 1'b1)
      begin
        pTmp = {pSign, {NEXP+NSIG-1{1'b0}}, 1'b1};
        pFlags[ZERO] = 1;
      end
      
// otherwise if (((aFlags[SUBNORMAL] | aFlags[NORMAL]) & (bFlags[SUBNORMAL] | bFlags[NORMAL])) == 1'b1) 
// and we are multiplying normal and/or subnormal numbers, then do the following
    else
      begin
        t1Exp = aExp + bExp; // First add the two exponents (before normalization)

        if (rawSignificand[2*NSIG+1] == 1'b1) // If the most significant bit is a 1 (i.e. overflow in calculation)
        
        // Then we set the temporary significand, then we get the bit values from the most significant bit 
        // Then we shift the exponent value by 1. Otherwise we keep the exponent the same and get the non-overflow values
        // Then truncate the raw significand to be the same number of bits as the required significand
          begin
            tSig = rawSignificand[2*NSIG+1:NSIG+1];
            t2Exp = t1Exp + 1;
          end
        else
          begin
            tSig = rawSignificand[2*NSIG:NSIG];
            t2Exp = t1Exp;
          end
        
        // Once we calculate the exponent, we check 
        if (t2Exp < (EMIN - NSIG))  // Too small to even be represented as a subnormal; round down and saturate to smallest value
          begin                     // A subnormals smallest representation is the smallest exponent + number of spaces the LS 1 is
//            pTmp = {pSign, {NEXP+NSIG{1'b0}}};
//            pFlags[ZERO] = 1;
            pTmp = {pSign, {NEXP+NSIG-1{1'b0}}, 1'b1};
            pFlags[ZERO] = 1;
          end
        else if (t2Exp < EMIN) // Subnormal since it cannot be represented by the lowest normal bias 
          begin
            pSig = tSig >> (EMIN - t2Exp); // Right shift and fill with 0's by the difference between EMIN and the smaller, more negative exponent
            // Remember that we can only store NSIG bits
            pTmp = {pSign, {NEXP{1'b0}}, pSig[NSIG-1:0]}; // Fill with 0's in the exponent to represent denormalized form
            pFlags[SUBNORMAL] = 1;
          end
        else if (t2Exp > EMAX) // Largest than the most representable value, therefore store original value and then perform normalizing after
          begin
//            pTmp = {pSign, {NEXP{1'b1}}, {NSIG{1'b0}}};
//            pFlags[INFINITY] = 1;
            pSig = tSig;
            pTmp = {pSign, {NEXP{1'b1}}, pSig[NSIG-1:0]};
            pFlags[INFINITY] = 1;
            exp_overflow = t2Exp - EMAX;
          end
        else // Normal, add the bias onto the number to get the final value 
          begin
            pExp = t2Exp + BIAS;
            pSig = tSig;
            // Remember that for Normals we always assume the most
            // significant bit is 1 so we only store the least
            // significant NSIG bits in the significand.
            pTmp = {pSign, pExp[NEXP-1:0], pSig[NSIG-1:0]};
	    pFlags[NORMAL] = 1;
          end
      end //
  end

  assign p = pTmp;

endmodule