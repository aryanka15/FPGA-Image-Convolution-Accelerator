`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Aryan Karani
// 
// Create Date: 12/13/2025 12:53:34 AM
// Design Name: 
// Module Name: rolling_buffer
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Rolling buffer module that manages four line buffers in a circular fashion. 
//It handles writing to and reading from the buffers, and shifts the buffers when needed.
// 
// Dependencies: line_buffer
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module rolling_buffer(
    input logic clk, n_rst, wen, ren, buffer_shift,
    input logic [31:0] wdata, 
    output logic all_full, all_empty,
    output logic [31:0] rdata_1, rdata_2, rdata_3
    );
    
    logic [1:0] wptr, rptr;  
    
    logic write_full;     

    // Wen/Ren/Full/Empty/rptr_rst/wdata signals for each buffer
    logic wen_buf_1, wen_buf_2, wen_buf_3, wen_buf_4, ren_buf_1, ren_buf_2, ren_buf_3, ren_buf_4; 
    logic full_buf_1, full_buf_2, full_buf_3, full_buf_4, empty_buf_1, empty_buf_2, empty_buf_3, empty_buf_4;
    logic rptr_rst_1, rptr_rst_2, rptr_rst_3, rptr_rst_4;
    logic [31:0] wdata_buf_1, wdata_buf_2, wdata_buf_3, wdata_buf_4, rdata_buf_1, rdata_buf_2, rdata_buf_3, rdata_buf_4;
    
    line_buffer buffer1 (
        .clk(clk), 
        .n_rst(n_rst), 
        .ren(ren_buf_1), 
        .wen(wen_buf_1), 
        .rptr_rst(rptr_rst_1),
        .wdata(wdata_buf_1), 
        .empty(empty_buf_1), 
        .full(full_buf_1), 
        .rdata(rdata_buf_1)
     );
     
     line_buffer buffer2 (
        .clk(clk), 
        .n_rst(n_rst), 
        .ren(ren_buf_2), 
        .wen(wen_buf_2), 
        .rptr_rst(rptr_rst_2),
        .wdata(wdata_buf_2), 
        .empty(empty_buf_2), 
        .full(full_buf_2), 
        .rdata(rdata_buf_2)
     );
     
     line_buffer buffer3 (
        .clk(clk), 
        .n_rst(n_rst), 
        .ren(ren_buf_3), 
        .wen(wen_buf_3), 
        .wdata(wdata_buf_3), 
        .rptr_rst(rptr_rst_3),
        .empty(empty_buf_3), 
        .full(full_buf_3), 
        .rdata(rdata_buf_3)
     );
     
     line_buffer buffer4 (
        .clk(clk), 
        .n_rst(n_rst), 
        .ren(ren_buf_4), 
        .wen(wen_buf_4), 
        .rptr_rst(rptr_rst_4),
        .wdata(wdata_buf_4), 
        .empty(empty_buf_4), 
        .full(full_buf_4), 
        .rdata(rdata_buf_4)
     );
     
     // Logic to determine if all buffers being read from are empty/full or need to be rptr_rst
     always_comb begin: empty_full_logic
        all_full = 0;
        all_empty = 0;
        rptr_rst_1 = 0; 
        rptr_rst_2 = 0;
        rptr_rst_3 = 0; 
        rptr_rst_4 = 0;
        case (rptr)
            0: begin
                all_full = full_buf_1 & full_buf_2 & full_buf_3;
                all_empty = empty_buf_1 & empty_buf_2 & empty_buf_3;
                rptr_rst_1 = 0; 
                rptr_rst_2 = all_empty && buffer_shift;
                rptr_rst_3 = all_empty && buffer_shift; 
                rptr_rst_4 = 0;
            end
            1: begin
                all_full = full_buf_2 & full_buf_3 & full_buf_4;
                all_empty = empty_buf_2 & empty_buf_3 & empty_buf_4;
                rptr_rst_1 = 0; 
                rptr_rst_2 = 0;
                rptr_rst_3 = all_empty && buffer_shift; 
                rptr_rst_4 = all_empty && buffer_shift; 
            end
            2: begin
                all_full = full_buf_3 & full_buf_4 & full_buf_1;
                all_empty = empty_buf_3 & empty_buf_4 & empty_buf_1;
                rptr_rst_1 = all_empty && buffer_shift; 
                rptr_rst_2 = 0;
                rptr_rst_3 = 0; 
                rptr_rst_4 = all_empty && buffer_shift;
            end
            3: begin
                all_full = full_buf_4 & full_buf_1 & full_buf_2;
                all_empty = empty_buf_4 & empty_buf_1 & empty_buf_2;
                rptr_rst_1 = all_empty && buffer_shift; 
                rptr_rst_2 = all_empty && buffer_shift;
                rptr_rst_3 = 0; 
                rptr_rst_4 = 0;
            end
            default: begin
                all_full = 0;
                all_empty = 0;
                rptr_rst_1 = 0; 
                rptr_rst_2 = 0;
                rptr_rst_3 = 0; 
                rptr_rst_4 = 0;
            end
        endcase     
     end
     
     // Determines the wen, wdata, and full signal based on the buffer being written to currently
     always_comb begin: wen_logic
        wen_buf_1 = 0;
        wen_buf_2 = 0;
        wen_buf_3 = 0;
        wen_buf_4 = 0; 
        wdata_buf_1 = '0;
        wdata_buf_2 = '0;
        wdata_buf_3 = '0;
        wdata_buf_4 = '0;
        write_full = 0;
        case (wptr)
            0: begin
                wen_buf_1 = wen;     
                wdata_buf_1 = wdata; 
                write_full = full_buf_1; 
            end
            1: begin
                wen_buf_2 = wen;     
                wdata_buf_2 = wdata;
                write_full = full_buf_2;  
            end
            2: begin
                wen_buf_3 = wen;     
                wdata_buf_3 = wdata; 
                write_full = full_buf_3;    
            end
            3: begin
                wen_buf_4 = wen; 
                wdata_buf_4 = wdata; 
                write_full = full_buf_4; 
            end
            default: begin
                wen_buf_1 = 0;
                wen_buf_2 = 0;
                wen_buf_3 = 0;
                wen_buf_4 = 0; 
                wdata_buf_1 = '0;
                wdata_buf_2 = '0;
                wdata_buf_3 = '0;
                wdata_buf_4 = '0;
                write_full = 0; 
            end
        endcase
     end
     
     // Determines the ren and rdata signals based on the buffer being read from currently
     always_comb begin: ren_logic
        ren_buf_1 = 0; 
        ren_buf_2 = 0; 
        ren_buf_3 = 0;
        ren_buf_4 = 0;
        rdata_1 = '0; 
        rdata_2 = '0;
        rdata_3 = '0;
        case (rptr) 
            0: begin
                ren_buf_1 = ren; 
                ren_buf_2 = ren; 
                ren_buf_3 = ren; 
                rdata_1 = rdata_buf_1; 
                rdata_2 = rdata_buf_2;
                rdata_3 = rdata_buf_3; 
            end
            1: begin
                ren_buf_2 = ren; 
                ren_buf_3 = ren; 
                ren_buf_4 = ren; 
                rdata_1 = rdata_buf_2; 
                rdata_2 = rdata_buf_3;
                rdata_3 = rdata_buf_4; 
            end
            2: begin
                ren_buf_3 = ren; 
                ren_buf_4 = ren; 
                ren_buf_1 = ren; 
                rdata_1 = rdata_buf_3; 
                rdata_2 = rdata_buf_4;
                rdata_3 = rdata_buf_1; 
            end
            3: begin
                ren_buf_4 = ren; 
                ren_buf_1 = ren; 
                ren_buf_2 = ren; 
                rdata_1 = rdata_buf_4; 
                rdata_2 = rdata_buf_1;
                rdata_3 = rdata_buf_2; 
            end
            default: begin
                ren_buf_1 = 0; 
                ren_buf_2 = 0; 
                ren_buf_3 = 0;
                ren_buf_4 = 0;
                rdata_1 = '0; 
                rdata_2 = '0;
                rdata_3 = '0;
            end
        endcase
     end
     
     // Logic to update the write and read pointers based on buffer shift and write_full signals
     always_ff @(posedge clk, negedge n_rst) begin: pointer_logic
        if (~n_rst) begin
            wptr <= '0;
            rptr <= '0;
        end
        else begin 
            if (buffer_shift) begin
                rptr <= rptr + 1; 
            end
            if (write_full) begin
                wptr <= wptr + 1; 
            end
        end
     end
     
endmodule
