`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Aryan Karani
// 
// Create Date: 11/27/2025 11:35:15 PM
// Design Name: 
// Module Name: shift_reg
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Shift register module that shifts in serial data and outputs parallel data. 
// It supports enabling/disabling the shift operation and resetting the register when the buffer shifts.
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module shift_reg #(parameter WIDTH=64) (
    input logic clk, n_rst, 
    input logic shift_en, buffer_shift, // Buffer shift signal says when o_data needs to be reset
    input logic [31:0] serial_in, // 32 bit input
    (* keep = "true", MAX_FANOUT = 10 *) output logic [WIDTH-1:0] o_data
    );
    
    always_ff @(posedge clk, negedge n_rst) begin
        if (~n_rst) begin
            o_data <= '0; 
        end
        else begin
            if (buffer_shift) begin
                o_data <= '0; 
            end
            else if (shift_en) begin
                o_data <= {o_data[WIDTH-33:0], serial_in};
            end
        end
    end
    
endmodule
