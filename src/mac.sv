`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/27/2025 06:59:29 PM
// Design Name: 
// Module Name: mac
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


module mac(
    input logic clk, n_rst,
    input logic [71:0] conv_data,
    input logic signed [71:0] kernel, 
    input logic start_conv, 
    output logic [7:0] output_pixel,
    output logic data_ready
    );
        
    (* use_dsp = "yes" *) logic signed [15:0] mul_data [2:0][2:0]; // Ensures DSP is used for multiplcation, reduces logic levels
    logic signed [15:0] sum_rows [2:0]; // Sum of each row of the 3x3 multiplication results
    logic signed [15:0] sum_rows_reg [2:0]; // Registered sum of each row
    logic signed [15:0] sum_reg; // Registered sum of all rows
    logic [7:0] sum_output;  // Output pixel after truncating the sum to 8 bits
        
    logic signed [7:0] kernel_array [0:2][0:2]; // Registered kernel array in MAC

    logic [7:0] pixel_array [0:2][0:2]; // Registered pixel array in MAC
    
    logic mul_valid, sum_valid, sum_valid1; // Valid signals (sum is two-stage)
    
    always_ff @(posedge clk) begin: kernel_array_ff
        if (~n_rst) begin
            kernel_array <= '{default: 0};
        end
        else begin
            kernel_array[0][0] <= kernel[71:64];
            kernel_array[0][1] <= kernel[63:56];
            kernel_array[0][2] <= kernel[55:48];
            kernel_array[1][0] <= kernel[47:40];
            kernel_array[1][1] <= kernel[39:32];
            kernel_array[1][2] <= kernel[31:24];
            kernel_array[2][0] <= kernel[23:16];
            kernel_array[2][1] <= kernel[15:8];
            kernel_array[2][2] <= kernel[7:0];
        end
    end
    
    always_ff @(posedge clk) begin: pixel_array_ff
        if (~n_rst) begin
            pixel_array <= '{default: 0}; 
        end
        else begin
            pixel_array[0][0] <= conv_data[71:64];
            pixel_array[0][1] <= conv_data[63:56];
            pixel_array[0][2] <= conv_data[55:48];
            pixel_array[1][0] <= conv_data[47:40];
            pixel_array[1][1] <= conv_data[39:32];
            pixel_array[1][2] <= conv_data[31:24];
            pixel_array[2][0] <= conv_data[23:16];
            pixel_array[2][1] <= conv_data[15:8];
            pixel_array[2][2] <= conv_data[7:0];
        end
    end
        
    always_ff @(posedge clk) begin: valid_ff
        if (~n_rst) begin
            mul_valid <= '0;
            sum_valid <= '0;
            sum_valid1 <= '0; 
            data_ready <= '0;
        end
        else begin
            mul_valid <= start_conv; 
            sum_valid1 <= mul_valid; 
            sum_valid <= sum_valid1; 
            data_ready <= sum_valid; 
        end
    end
    
     
    genvar i, j; 
    generate
        for (i = 0; i < 3; i++) begin: gen_row
            for (j = 0; j < 3; j++) begin: gen_col
                localparam index = 72 - 8*(3*i + j + 1); 
                always_ff @(posedge clk) begin: ff_mul // Multiply pixel and kernel (3x3 parallel, so 9 multipliers)
                    if (~n_rst) begin
                        mul_data[i][j] <= '0; 
                    end
                    else if (start_conv) begin
                        mul_data[i][j] <= $signed({1'b0,pixel_array[i][j]}) * kernel_array[i][j];
                    end
                end
            end
        end
    endgenerate
    
    genvar k;
    generate
        for (k = 0; k < 3; k++) begin
            always_comb begin: sum_logic // Sum each row of the 3x3 multiplication results
                sum_rows[k] = 16'd0;
                if (mul_valid) begin
                    for (int z = 0; z < 3; z++) begin
                        sum_rows[k] = sum_rows[k] + mul_data[k][z];
                    end
                end
            end
            
            always_ff @(posedge clk) begin: sum_rows_reg_logic // Register sum of each row
                if (~n_rst) begin
                    sum_rows_reg[k] <= 16'd0; 
                end
                else begin
                    if (mul_valid) begin
                        sum_rows_reg[k] <= sum_rows[k];
                    end
                end
            end
        end
    endgenerate
    
    always_ff @(posedge clk) begin: sum_reg_ff
        if (~n_rst) begin
            sum_reg <= 16'd0; 
            output_pixel <= 8'd0; 
        end
        else begin
            sum_reg <= sum_rows_reg[0] + sum_rows_reg[1] + sum_rows_reg[2]; // Sum of all rows
            if (sum_valid) 
                output_pixel <= sum_output; 
        end
    end
    
    always_comb begin: output_pixel_logic // Generate output pixel based on sum_reg
        if (sum_reg < 0) begin // Take absolute value of negative values
            sum_output = ~sum_reg + 1'b1; 
        end
        else if (sum_reg > 255) begin // Clamp to 255
            sum_output = 8'd255; 
        end
        else begin // Truncate to 8 bits
            sum_output = sum_reg[7:0]; 
        end
    end
        
    
endmodule
