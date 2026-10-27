`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/27/2025 08:13:15 PM
// Design Name: 
// Module Name: tb_mac
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


module tb_mac(

    );
    
    // Instantiate clock
    logic clk, n_rst;
    logic [71:0] conv_data;
    logic [71:0] kernel;
    logic start_conv;
    logic [7:0] output_pixel;
    logic data_ready;
    
    mac #() DUT (.*); 
    
    initial begin
        clk = 1'b0;
        forever begin
            #(5);
            clk = ~clk; 
        end
    end
    
    initial begin
    
        localparam eight_bit_val_small = 8'd5;
        localparam [71:0] small_vector = 
            {9{eight_bit_val_small}}; // Replicates 8'd5 nine times
            
        localparam eight_bit_val_large = 8'd10;
        localparam [71:0] large_vector = {9{eight_bit_val_large}};

        n_rst = 0;
        conv_data = '0;
        kernel = '0; 
        start_conv = 0;
        @(posedge clk);
        @(posedge clk); 
        @(posedge clk);
        n_rst = 1; 
        @(posedge clk); 

        conv_data = small_vector;
        kernel = small_vector;
        @(posedge clk);
        start_conv = 1; // Assert start
        $display("Test Case 1 started (Expected Output: 225)");

        @(posedge clk); // Clock 1: Multiplication registered (Stage 1)
        start_conv = 0; // De-assert start
        
        repeat (3) @(posedge clk); // Clocks 2 & 3: Wait for output
    
        conv_data = large_vector;
        kernel = large_vector;
        @(posedge clk); 
        start_conv = 1; // Assert start
        $display("Test Case 2 started (Expected Output: 255)");

        @(posedge clk); // Clock 4: Multiplication registered
        start_conv = 0;
        
        repeat (3) @(posedge clk); // Clocks 5 & 6: Wait for output
        
        $finish; 
    end
    
    
endmodule
