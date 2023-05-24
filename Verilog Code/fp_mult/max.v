`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/06/2023 07:03:53 PM
// Design Name: 
// Module Name: max
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


module max(exp_array, max_exponent);
    `include "ieee-754-flags.v"
    input [(LENGTH*NEXP)-1:0] exp_array;
    output [NEXP-1:0] max_exponent;
    reg [NEXP-1:0] iter, max_exponent;
    integer i;
    
    always @(*) begin
        max_exponent = NEXP*{1'b0}; // Set the initial value to be 0 based on the length of the exponent
        for (i = 0; i < LENGTH; i = i + 1) begin
            iter = exp_array[i*NEXP +: NEXP]; // Compare each exponent in the array and store the maximum one
            if (iter > max_exponent) begin
                max_exponent = iter;
            end
        end
    end
endmodule
