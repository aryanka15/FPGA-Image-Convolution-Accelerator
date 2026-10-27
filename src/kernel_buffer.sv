`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Aryan Karani
// 
// Create Date: 12/30/2025 04:24:33 PM
// Design Name: 
// Module Name: kernel_buffer
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Kernel buffer module for the image convolution unit
//  Stores the 3x3 kernel matrix by shifting in 24-bit rows
//  Provides the complete 72-bit kernel matrix as output
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module kernel_buffer(
    input logic clk, n_rst,
    input logic [23:0] kernel_row, 
    input logic wen,
    (* keep = "true", MAX_FANOUT = 10 *) output logic [71:0] kernel_mat // Max Fanout to reduce net delay
    );
    
    always_ff @(posedge clk, negedge n_rst) begin
        if (~n_rst) begin
            kernel_mat <= '0; 
        end
        else begin
            if (wen) begin
                kernel_mat <= {kernel_mat[47:0], kernel_row}; // Shift in new 24-bit row
            end
        end
    end
    
endmodule
