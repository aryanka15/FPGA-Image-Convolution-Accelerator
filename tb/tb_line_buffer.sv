`timescale 1ns / 1ps

module tb_line_buffer();

    // Instantiate clock and signals
    logic clk, n_rst, ren, wen;
    logic [31:0] wdata, rdata; // FIX: Updated to 32-bit to match design
    logic empty, full;
    logic rptr_rst;

    // FIX: Override SIZE parameter to 512 so the final loop works
    line_buffer #(.SIZE(512)) buffer (.*);

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
        wdata = 32'd0;
        rptr_rst = 0; // FIX: Initialize rptr_rst

        @(posedge clk);
        @(posedge clk);
        n_rst = 1;
        #(100);

        // --- Write data ---
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

        // --- Read data ---
        @(negedge clk);
        ren = 1'b1;
        
        @(negedge clk); // Cycle 1: data moves from mem to read_reg_1
        
        // Cycle 2: data moves from read_reg_1 to rdata
        for (int i = 0; i < 5; i++) begin
            @(negedge clk); // Wait for the posedge to process the data
            
            // Turn off read enable if this is the last read cycle
            if (i == 4) ren = 1'b0; 
            
            if (rdata != i + 1) begin
                $display("rdata does not match");
                $display("Expected: %d, Result: %d", i + 1, rdata);
            end
        end
        
        @(posedge clk);
        #(2);
        // Check status
        if (!empty) begin
            $display("status is not empty after writes and reads");
        end

        // --- Write 512 pieces of data ---
        @(posedge clk);
        for (int i = 1; i <= 512; i++) begin
            wen = 1'b1;
            wdata = i; // FIX: removed [7:0] truncation to match 32-bit
            @(posedge clk);
        end
        wen = 0;
        
        @(posedge clk);
        #(2);
        if (!full) begin
            $display("status is not full after 512 writes");
        end
        
        $display("Simulation finished successfully!");
        $finish;
    end

endmodule
