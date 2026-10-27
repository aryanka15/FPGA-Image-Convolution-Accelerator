`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Aryan Karani
// 
// Create Date: 11/28/2025 12:13:37 AM
// Design Name: 
// Module Name: controller
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
//  Controller module for the image convolution unit
//  Manages the flow of data between line buffers and the MAC unit
//  Generates control signals for starting convolution, shifting buffers, and reading data
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module controller(
    input logic clk, n_rst, all_full, all_empty, start, data_valid,
    output logic start_conv, shift_en, ren, buffer_shift
    );
        
    typedef enum logic [3:0] {IDLE, READ_INIT, SHIFT_INIT, START_CONV, WAIT_DATA, LAST_DATA, LAST_DATA_1, LAST_DATA_2, WAIT_READ, LAST_DATA_3} state_t;
    
    state_t state, next_state; // State signals
    
    logic [2:0] cnt_3, nxt_cnt; // 3-bit counter for tracking shifts
    logic cnt_en;
    
    logic [8:0] buffer_shift_counter; // 9-bit counter for tracking buffer shifts
    
    always_ff @(posedge clk, negedge n_rst) begin // state and shift counter
        if (~n_rst) begin
            state <= IDLE;
            cnt_3 <= '0;  
        end
        else begin
            state <= next_state;
            cnt_3 <= nxt_cnt; 
        end  
    end
    
    always_comb begin: count_logic // 3-bit counter logic
        nxt_cnt = cnt_3; 
        if (cnt_en) begin
            nxt_cnt = cnt_3 == 3'd3 ? 3'd0 : cnt_3 + 1; 
        end
    end
    
    always_comb begin: output_logic // Output signals logic FSM
        start_conv = 0; 
        shift_en = 0;
        ren = 0; 
        cnt_en = 0; 
        case (state)
            READ_INIT: begin
                ren = 1; 
                cnt_en = 0; 
            end
            WAIT_READ: begin
                ren = 1; 
                cnt_en = 1; 
            end
            SHIFT_INIT: begin
                shift_en = 1;
                ren = 1;
                cnt_en = 1;  
            end
            START_CONV: begin
                start_conv = 1;
                shift_en = 1;
                ren = 1; 
            end
            WAIT_DATA: begin
                start_conv = 0;
                shift_en = 0;
                ren = 0; 
            end
            LAST_DATA: begin
                start_conv = 1;
                shift_en = 1;
                ren = 1; 
            end
            LAST_DATA_1: begin
                start_conv = 1;
                shift_en = 0;
                ren = 0; 
            end
            LAST_DATA_2: begin
                start_conv = 1; 
                shift_en = 0;
                ren = 0; 
            end
            LAST_DATA_3: begin
                start_conv = 1; 
                shift_en = 0;
                ren = 0; 
            end
            default: begin
                start_conv = 0; 
                shift_en = 0;
                ren = 0; 
                cnt_en = 0;
            end
        endcase
    end
    
    always_comb begin: next_state_logic // Next state logic FSM
        next_state = state; 
        case (state) 
            IDLE: begin
                if (start & all_full) begin
                    next_state = READ_INIT; 
                end
            end
            READ_INIT: begin
                next_state = WAIT_READ; 
            end
            WAIT_READ: begin
                next_state = SHIFT_INIT; 
            end
            SHIFT_INIT: begin
                if (cnt_3 == 3'd3) begin
                    next_state = START_CONV; 
                end
            end
            START_CONV: begin
                if (all_empty) begin
                    next_state = LAST_DATA; 
                end 
            end
            LAST_DATA: begin
                next_state = LAST_DATA_1; 
            end
            LAST_DATA_1: begin
                next_state = LAST_DATA_2;
            end
            LAST_DATA_2: begin
                next_state = LAST_DATA_3;
            end
            LAST_DATA_3: begin
                next_state = WAIT_DATA; 
            end
            WAIT_DATA: begin
                next_state = data_valid ? WAIT_DATA : IDLE; 
            end
            default: begin
                next_state = state;  
            end
        endcase
    end
    
    always_ff @(posedge clk, negedge n_rst) begin: buffer_counter // Buffer shift counter FF
        if (~n_rst) begin
            buffer_shift_counter <= '0; 
        end
        else begin
            if (data_valid) begin
                buffer_shift_counter <= buffer_shift_counter == 9'd127 ? '0 : buffer_shift_counter + 1; 
            end
            else buffer_shift_counter <= '0;
        end
    end
    
    always_comb begin: shift_logic // Buffer shift logic
        buffer_shift = buffer_shift_counter == 9'd127;
    end
    
endmodule
