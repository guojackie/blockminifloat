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


module block_mul(b1, b2, bout);
    `include "ieee-754-flags.v"
    input [EXP_BIAS+LENGTH*SIZE-1:0] b1, b2; // Size if the blocks and output based on the exponent bias and minifloat
    output wire [EXP_BIAS+LENGTH*SIZE-1:0] bout;
    
    wire [LENGTH*SIZE-1:0] floatArray, floatArray1, floatArray2; // Array of minifloats as results and from blocks 1 and 2
    wire [EXP_BIAS-1:0] expBias, expBias1, expBias2; // Exponent bias result and from blocks 1 and 2
    wire [LENGTH*NEXP-1:0] overflowArray; // Array of all the overflow values per index
    wire [NEXP-1:0] maxOverflow; // Larged overflow value
    wire [LENGTH*FLAGS-1:0] flags; // List of all the flags stored in an array 
    reg [LENGTH*(NEXP+SIZE)-1:0] normArray; // List of all values needed to be normalized 
    
    //Assign the exponents and array of minifloats
    assign {expBias1, floatArray1} = b1;
    assign {expBias2, floatArray2} = b2;
    
    // Generate multiple blocks for multiplication based on the number of minifloats and compute results
    genvar i;
    generate 
        for (i = 0; i < LENGTH; i = i + 1) begin
            fp_mul u(.a(floatArray1[i*SIZE +: SIZE]), 
                      .b(floatArray2[i*SIZE +: SIZE]), 
                      .p(floatArray[i*SIZE +: SIZE]), 
                      .exp_overflow(overflowArray[i*NEXP +: NEXP]), 
                      .pFlags(flags[i*FLAGS +: FLAGS]));
        end
    endgenerate
    
    // Obtain the maximum overflow value  
    max bias_max(.exp_array(overflowArray), .max_exponent(maxOverflow));
    
    // Format result and normalize the minifloat values
    integer j;
    always @(*) begin
        for (j = 0; j < LENGTH; j = j + 1) begin 
            normArray[j*(NEXP+SIZE) +: NEXP+SIZE] = {overflowArray[j*NEXP +: NEXP], floatArray[j*SIZE +: SIZE]};
        end
    end
    
    // Normalize works for single floating points and their respective overflow values
    generate 
        for (i = 0; i < LENGTH; i = i + 1) begin
            normalize n(.exp_overflow(maxOverflow), 
                        .in_f(normArray[i*(NEXP+SIZE) +: NEXP+SIZE]), 
                        .out_f(floatArray[i*SIZE +: SIZE]));
        end
    endgenerate
    
    // Once normalize, combine the final result to get the resulting block
    assign expBias = expBias1 + expBias2 + maxOverflow;
    assign bout = {expBias, floatArray};
    
endmodule
