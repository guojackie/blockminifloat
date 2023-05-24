`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/06/2023 07:48:07 PM
// Design Name: 
// Module Name: block_mul
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


module block_add(b1, b2, addsub, bout);
    `include "ieee-754-flags.v"
    input [EXP_BIAS+LENGTH*SIZE-1:0] b1, b2; // Size if the blocks and output based on the exponent bias and minifloat
    input addsub; // Bit denoting whether we wish to perform addition or subtraction 
    output wire [EXP_BIAS+LENGTH*SIZE-1:0] bout;
    
    wire [LENGTH*SIZE-1:0] floatArray, floatArrayNorm, floatArrayBiasNorm1; // Array of minifloats as results and from blocks 1 and 2
    wire [LENGTH*NEXP-1:0] overflowArray; // Array of all the overflow values per index
    wire [LENGTH*FLAGS-1:0] flags; // List of all the flags stored in an array 
    wire [LENGTH*NEXCEPTIONS-1:0] exceptions; // List of all the exceptions from addition
    wire [NRAS-1:0] ra;
    wire [NEXP-1:0] maxOverflow;
    
    reg [EXP_BIAS-1:0] expBiasDiff, expBias, expBiasOut; // Exponent bias result and from blocks 1 and 2
    reg [LENGTH*SIZE-1:0] normArrayFromExponent; // List of all values needed to be normalized 
    reg [LENGTH*(NEXP+SIZE)-1:0] normArrayAfterAddition; // List of all values needed to be normalized
    reg [LENGTH*SIZE-1:0] floatArrayBiasNorm2; // Arrays to store the new normalized blocks adjusting for biases
    reg [NEXP-1:0] currentExponent, largestExponent; // The largest exponent in the block
    reg [NEXP-1:0] maxOverflowReal; // Largest overflow value
    reg [EXP_BIAS-1:0] expBias1, expBias2; // Exponent biases of the bloc
    reg [LENGTH*SIZE-1:0] floatArray1, floatArray2; // Arrays to store the minifloats from the block
    reg normAdd;
    
    integer j;
    integer h;
    
    // Specify the rounding strategy
    assign ra = {NRAS{1'b0}};
    assign ra[roundTowardZero] = 1'b1;
    
    // Calculate the difference between the exponent bias and normalize the smaller block
    always @(*) begin
        
        // Extact the exponent bias and vector of minifloats from the block
        {expBias1, floatArray1} = b1;
        {expBias2, floatArray2} = b2;
        
        // First flip the sign bit of all the minifloats in the second block
        for (h = 0; h < LENGTH; h = h + 1) begin // Then assign the 
            floatArray2[h*SIZE] = floatArray2[h*SIZE]^addsub;
        end
        
        if (expBias1 < expBias2)
          begin
            expBiasDiff = expBias2 - expBias1; 
            expBias = expBias2;
            floatArrayBiasNorm2 = floatArray2;
            
            for (j = 0; j < LENGTH; j = j + 1) begin // Then assign the 
                normArrayFromExponent[j*SIZE +: SIZE] = floatArray1[j*SIZE +: SIZE];
            end
          end
        else
          begin
            expBiasDiff = expBias1 - expBias2;
            expBias = expBias1;
            floatArrayBiasNorm2 = floatArray1;
            
            for (j = 0; j < LENGTH; j = j + 1) begin // Then assign the 
                normArrayFromExponent[j*SIZE +: SIZE] = floatArray2[j*SIZE +: SIZE];
            end
            
          end
    end
    
    // Normalize the entire block to make exponent bias equal 
    genvar i;
    generate 
        for (i = 0; i < LENGTH; i = i + 1) begin
            normalizeExponentBias n(.exp_overflow(expBiasDiff), 
                        .in_f(normArrayFromExponent[i*SIZE +: SIZE]), 
                        .out_f(floatArrayBiasNorm1[i*SIZE +: SIZE]));
        end
    endgenerate
    
    // Generate multiple blocks for addition based on the number of minifloats and compute results
    generate 
        for (i = 0; i < LENGTH; i = i + 1) begin
            fp_add_exact u(
            .a(floatArrayBiasNorm1[i*SIZE +: SIZE]), 
            .b(floatArrayBiasNorm2[i*SIZE +: SIZE]), 
            .ra(ra), 
            .s(floatArray[i*SIZE +: SIZE]), 
            .sFlags(flags[i*FLAGS +: FLAGS]), 
            .exception(exceptions[i*NEXCEPTIONS +: NEXCEPTIONS]));
        end
    endgenerate
    
    // Obtain the maximum overflow value from the addition
    max bias_max(.exp_array(overflowArray), .max_exponent(maxOverflow));
    
    integer l;
    always @(*) begin
        normAdd = 0;
        if (maxOverflow == 0) begin
            for (l = 0; l < LENGTH; l = l + 1) begin
                currentExponent = floatArray[l*SIZE +: NEXP + 1]; // Obtain the sign and exponent component of the minifloat
                currentExponent = currentExponent << 1; // Remove the sign bit
                
                if (currentExponent > largestExponent) begin // Do a compare and find the largest exponent
                    largestExponent = currentExponent;
                end
            end
            maxOverflowReal = EMAX - largestExponent;
            normAdd = 1;
            expBiasOut = expBias - maxOverflowReal;
        end else begin
            expBiasOut = expBias + maxOverflowReal;
            maxOverflowReal = maxOverflow;
        end
    end
    
    // Format result and normalize the minifloat values
    integer k;
    always @(*) begin
        for (k = 0; k < LENGTH; k = k + 1) begin 
            normArrayAfterAddition[k*(NEXP+SIZE) +: NEXP+SIZE] = {overflowArray[k*NEXP +: NEXP], floatArray[k*SIZE +: SIZE]};
        end
    end
    
    // Normalize works for single floating points and their respective overflow values
    generate 
        for (i = 0; i < LENGTH; i = i + 1) begin
            normalize n(.exp_overflow(maxOverflowReal), 
                        .in_f(normArrayAfterAddition[i*(NEXP+SIZE) +: NEXP+SIZE]), 
                        .out_f(floatArrayNorm[i*SIZE +: SIZE]),
                        .normAdd(normAdd));
        end
    endgenerate
    
    // Once normalize, combine the final result to get the resulting block
    assign bout = {expBiasOut, floatArrayNorm};
    
endmodule