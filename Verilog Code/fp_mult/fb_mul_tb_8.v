`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/03/2023 01:42:14 PM
// Design Name: 
// Module Name: fb_mul_tb_8
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


module fb_mul_tb_8();

  // Parameters for testing 
  parameter NEXP = 2;
  parameter NSIG = 5;
  parameter NORMAL = 0;
  parameter SUBNORMAL = NORMAL + 1;
  parameter ZERO = SUBNORMAL + 1;
  parameter INFINITY = ZERO + 1;
  parameter QNAN = INFINITY + 1;
  parameter SNAN = QNAN + 1;
  parameter LAST_FLAG = SNAN + 1;
  
  reg [NEXP+NSIG:0] a, b;
  wire [NEXP+NSIG:0] p;
  wire [LAST_FLAG-1:0] flags;
  wire [NEXP:0] exp_overflow;

  initial
  begin
    $display("Test multiply circuit for binary%d:\n\n", NEXP+NSIG+1);
    
    #10
    assign a = 8'b01000011;
    assign b = 8'b01000001;
  end 
  
  fp_mul #(NEXP, NSIG) inst1(
  .a(a),
  .b(b),
  .p(p),
  .exp_overflow(exp_overflow),
  .pFlags(flags)
  );
endmodule
