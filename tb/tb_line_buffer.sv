`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Aryan Karani
// 
// Create Date: 11/26/2025 09:48:09 PM
// Design Name: 
// Module Name: tb_line_buffer
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments: Deprecated - created for 8-bit line buffer, new design uses 32 bit line buffer
// 
//////////////////////////////////////////////////////////////////////////////////


//input  logic clk, n_rst, ren, wen, logic [7:0] wdata,
//    output logic [1:0] status,
//    output logic [7:0] rdata

module tb_line_buffer();

    // Instantiate clock
    logic clk, n_rst, ren, wen; 
    logic [7:0] wdata, rdata;
    logic empty, full; 
    
    line_buffer #() buffer (.*); 
    
    initial begin
        clk = 1'b0;
        forever begin
            #(5);
            clk = ~clk; 
        end
    end
    
    initial begin
        n_rst = 0;
        ren = 0;
        wen = 0;
        wdata = 8'd0; 
        @(posedge clk);
        @(posedge clk); 
        n_rst = 1; 
        #(100);
        // Write data
        @(negedge clk);
        for (int i = 1; i <= 5; i++) begin
            wen = 1'b1; 
            wdata = i; 
            @(negedge clk);
        end
        wen = 0; 
        
        if (empty | full) begin
            $display("Status is not NONE when data left to read");
        end
        
        // Read data
        @(negedge clk);
        for (int i = 0; i < 5; i++) begin
            ren = 1'b1; 
            @(negedge clk); 
            if (rdata != i + 1) begin
                $display("rdata does not match");
                $display("Expected: %d, Result: %d", i + 1, rdata); 
            end
        end
        
        ren = 0; 
        @(posedge clk); 
        #(2);
        // Check status
        if (!empty) begin
            $display("status is not empty after writes and reads"); 
        end
        
        // Write 512 pieces of data
        @(posedge clk);
        for (int i = 1; i <= 512; i++) begin
            wen = 1'b1; 
            wdata = i[7:0]; 
            @(posedge clk);
        end
        wen = 0; 
        @(posedge clk);
        #(2); 
        if (!full) begin
            $display("status is not full after 512 writes"); 
        end
        $finish; 
    end

endmodule
