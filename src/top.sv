`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/27/2025 08:35:44 PM
// Design Name: 
// Module Name: top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Top-level module for the Image Convolution Unit. 
//It integrates the rolling buffer, line buffer, shift register, controller, and MAC modules to perform image convolution operations.
// 
// Dependencies: 
// - rolling_buffer
// - line_buffer
// - shift_reg
// - controller
// - mac
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module top (
    // Essential Control Ports (Map these to FPGA pins)
    input logic clk, 
    input logic n_rst,
    input logic i_wen, i_start,
    input logic [31:0] i_wdata,
    input logic i_load_kernel,
    // Output Port (Map this to FPGA pin/LEDs)
    output logic [31:0] output_pixel,
    output logic output_valid,
    output logic err
);

    // First stage sync register
    logic [31:0] wdata_1;
    logic wen_1, start_1; 

    // Synced Signals
    logic [31:0] wdata;
    logic wen, start; 

    // Line Buffer Signals
    logic ren, buf_wen; 
    logic all_full, all_empty;
    logic [31:0] rdata_1, rdata_2, rdata_3;
    logic [31:0] buf_data; 
    
    // Kernel buffer signals
    logic kernel_wen, load_kernel, load_kernel_1; 
    logic [23:0] kernel_data; 
    logic [71:0] kernel; 
    
    // Shift Register Signals
    logic shift_en; 
    logic [63:0] sr_data1, sr_data2, sr_data3; 
    logic [71:0] conv_data1, conv_data2, conv_data3, conv_data4; 
    

    // MAC signals
    logic [7:0] output_pixel1, output_pixel2, output_pixel3, output_pixel4; 
    
    assign conv_data1 = {sr_data1[63:40], sr_data2[63:40], sr_data3[63:40]}; 
    assign conv_data2 = {sr_data1[55:32], sr_data2[55:32], sr_data3[55:32]}; 
    assign conv_data3 = {sr_data1[47:24], sr_data2[47:24], sr_data3[47:24]};
    assign conv_data4 = {sr_data1[39:16], sr_data2[39:16], sr_data3[39:16]};
    
    
    // Controller Signals
   logic start_conv;
   logic buffer_shift; 
   logic output_valid1, output_valid2, output_valid3, output_valid4; 
    
    always_ff @(posedge clk, negedge n_rst) begin: synchronizers
        if (~n_rst) begin
            wdata_1 <= '0; 
            wdata <= '0; 
            wen <= '0;
            start <= '0;
            wen_1 <= '0;
            start_1 <= '0;
            load_kernel_1 <= '0; 
            load_kernel <= '0; 
            output_pixel <= '0; 
            output_valid <= '0; 
            err <= '0; 
        end
        else begin
            wdata_1 <= i_wdata; 
            wen_1 <= i_wen; 
            start_1 <= i_start; 
            load_kernel_1 <= i_load_kernel; 
            load_kernel <= load_kernel_1; 
            wdata <= wdata_1;
            wen <= wen_1; 
            start <= start_1; 
            output_pixel <= {output_pixel1, output_pixel2, output_pixel3, output_pixel4};
            output_valid <= output_valid1 & output_valid2 & output_valid3 & output_valid4; 
            err <=
                (output_valid1 != output_valid2) || 
                (output_valid1 != output_valid3) || 
                (output_valid1 != output_valid4); // err signal Not used currently
        end
    end
    
    always_comb begin: write_logic
        if (load_kernel) begin
            buf_wen = 0; 
            kernel_wen = wen; 
            buf_data = 0; 
            kernel_data = wdata[23:0]; // Take the lower 24 bits of wdata as kernel data
        end
        else begin
            buf_wen = wen; 
            kernel_data = 0; 
            kernel_wen = 0; 
            buf_data = wdata; 
        end
    end
    
    controller control (
        .clk(clk),
        .n_rst(n_rst),
        .all_full(all_full),
        .all_empty(all_empty),
        .start(start),
        .data_valid(output_valid),
        .start_conv(start_conv),
        .shift_en(shift_en),
        .ren(ren),
        .buffer_shift
     );
     
     kernel_buffer kern_buf (
        .clk, 
        .n_rst,
        .wen(kernel_wen),
        .kernel_row(kernel_data),
        .kernel_mat(kernel)
     );
     
     rolling_buffer buf1 (
        .clk, 
        .n_rst, 
        .wen(buf_wen), 
        .ren,
        .buffer_shift,
        .wdata(buf_data), 
        .all_full, 
        .all_empty,
        .rdata_1, .rdata_2, .rdata_3 
     );
     
     shift_reg reg1 (
        .clk(clk), .n_rst(n_rst),
        .shift_en(shift_en),
        .serial_in(rdata_1),
        .buffer_shift,
        .o_data(sr_data1)
     );
     
     shift_reg reg2 (
        .clk(clk), .n_rst(n_rst),
        .shift_en(shift_en),
        .serial_in(rdata_2),
        .buffer_shift,
        .o_data(sr_data2)
     );
     
     shift_reg reg3 (
        .clk(clk), .n_rst(n_rst),
        .shift_en(shift_en),
        .serial_in(rdata_3),
        .buffer_shift,
        .o_data(sr_data3)
     );
    
     mac conv_block1 (
        .clk(clk),
        .n_rst(n_rst),
        .conv_data(conv_data1),
        .kernel(kernel),
        .start_conv(start_conv),
        .output_pixel(output_pixel1),
        .data_ready(output_valid1)
     );
     
     mac conv_block2 (
        .clk(clk),
        .n_rst(n_rst),
        .conv_data(conv_data2),
        .kernel(kernel),
        .start_conv(start_conv),
        .output_pixel(output_pixel2),
        .data_ready(output_valid2)
     );
     
     mac conv_block3 (
        .clk(clk),
        .n_rst(n_rst),
        .conv_data(conv_data3),
        .kernel(kernel),
        .start_conv(start_conv),
        .output_pixel(output_pixel3),
        .data_ready(output_valid3)
     );
     
     mac conv_block4 (
        .clk(clk),
        .n_rst(n_rst),
        .conv_data(conv_data4),
        .kernel(kernel),
        .start_conv(start_conv),
        .output_pixel(output_pixel4),
        .data_ready(output_valid4)
     );

endmodule
