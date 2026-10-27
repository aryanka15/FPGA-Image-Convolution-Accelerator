`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Aryan Karani
// 
// Create Date: 11/27/2025 08:13:15 PM
// Design Name: 
// Module Name: tb_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
//  Testbench for the top-level image convolution module
//  Instantiates the top module and provides stimulus for image processing
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module tb_top;

    // Top level signals
    logic clk, n_rst;
    logic i_wen, i_start, output_valid, i_load_kernel; 
    logic [31:0] i_wdata;
    logic [31:0] output_pixel;
    
    // TB variables
    int i,j,z,k;
    int count_pixels;
    
    logic [71:0] kernel; 
    
    // Different kernels to be used in testbench
    localparam [71:0] kernel_sobel_x = {
        8'hFF, // -1 = 0xFF
        8'h00, // 0
        8'h01, // +1
        8'hFE, // -2 = 0xFE
        8'h00, // 0
        8'h02, // +2
        8'hFF, // -1
        8'h00, // 0
        8'h01  // +1
    }; 
    
    localparam [71:0] kernel_sobel_y = {
        8'hFF, // -1 = 0xFF
        8'hFE, // -2 = 0xFE
        8'hFF, // -1
        8'h00, // 0
        8'h00, // 0
        8'h00, // 0
        8'h01, // +1
        8'h02, // +2
        8'h01 // +1
    }; 
    
    localparam [71:0] kernel_laplacian = {
        8'hFF, 8'hFF, 8'hFF, // -1, -1, -1
        8'hFF, 8'h08, 8'hFF, // -1,  8, -1
        8'hFF, 8'hFF, 8'hFF  // -1, -1, -1
    }; 

    // Sharpening Filter (Enhances edges)
    //  0 -1  0
    // -1  5 -1
    //  0 -1  0
    localparam [71:0] kernel_sharpen = {
        8'h00, 8'hFF, 8'h00, //  0, -1,  0
        8'hFF, 8'h05, 8'hFF, // -1,  5, -1
        8'h00, 8'hFF, 8'h00  //  0, -1,  0
    };

    // Emboss (Creates 3D shadow effect)
    // -2 -1  0
    // -1  1  1
    //  0  1  2
    localparam [71:0] kernel_emboss = {
        8'hFE, 8'hFF, 8'h00, // -2, -1,  0
        8'hFF, 8'h01, 8'h01, // -1,  1,  1
        8'h00, 8'h01, 8'h02  //  0,  1,  2
    };

    localparam [71:0] kernel_identity = {
        8'h00, 8'h00, 8'h00, // -2, -1,  0
        8'h00, 8'h01, 8'h00, // -1,  1,  1
        8'h00, 8'h00, 8'h00  //  0,  1,  2
    };

    // DUT
    top DUT (
        .clk(clk),
        .n_rst(n_rst),
        .i_wen(i_wen),
        .i_start(i_start),
        .i_wdata(i_wdata),
        .i_load_kernel,
        .output_pixel(output_pixel),
        .output_valid(output_valid)
    );

    // Clock
    initial clk = 0;
    always #2.5 clk = ~clk;

    localparam int IMAGE_WIDTH  = 512;
    localparam int IMAGE_HEIGHT = 512;

    logic [7:0] image[0:IMAGE_HEIGHT-1][0:IMAGE_WIDTH-1];

    // Output file handle
    integer outfile;

    // Read image from text file
    task automatic read_image_file(input string filename);
        int i, j, c;
        int file;
        file = $fopen(filename, "r");
        if (file == 0) begin
            $display("ERROR: Cannot open file %s", filename);
            $finish;
        end
        for (i = 0; i < IMAGE_HEIGHT; i++) begin
            for (j = 0; j < IMAGE_WIDTH; j++) begin
                if ($fscanf(file, "%d", c) != 1) begin
                    $display("ERROR: Not enough pixels in %s. i: %d, j: %d\n", filename, i, j);
                    $finish;
                end
                image[i][j] = c;
            end
        end
        $fclose(file);
    endtask

    initial begin
        // Each posedge followed by a small delay to model setup time
        int a,b,c,d,e,f,g,h,jk;
        int expected;
        count_pixels = 0; 
        kernel = kernel_laplacian; 
        // Open output file
        outfile = $fopen("C:\\Users\\karan\\Documents\\GitHub\\ImageProcessor\\output\\clown_new.txt","w");
        if (outfile == 0) begin
            $display("ERROR: Cannot open output file");
            $finish;
        end

        // Reset
        n_rst = 0; i_wen = 0; i_start = 0; i_load_kernel = 0; i_wdata = 0; 
        repeat(5) @(posedge clk);
        @(posedge clk); #3;
        n_rst = 1;
        repeat(20) @(posedge clk);  
        @(posedge clk); #3;
   
        // Load image
        read_image_file("C:\\Users\\karan\\Documents\\GitHub\\ImageProcessor\\test_scripts\\clown.txt "); // replace with your path
        
        // Load kernel
        @(posedge clk); #3;
        i_wen = 1; 
        i_load_kernel = 1; 
        i_wdata = {8'd0, kernel[71:48]};
        @(posedge clk); #3;
        i_wdata = {8'd0, kernel[47:24]};
        @(posedge clk); #3;
        i_wdata = {8'd0, kernel[23:0]};
        @(posedge clk); #3;
        i_wen = 0; 
        i_load_kernel = 0; 
        @(posedge clk); 
        
        
        // Load first three lines
        for (k = 0; k < 3; k++) begin
            @(posedge clk); #3;
            for (j = 0; j < IMAGE_WIDTH; j+=4) begin
                i_wdata = {image[k][j], image[k][j+1], image[k][j+2], image[k][j+3]};
                i_wen = 1;
                @(posedge clk); #3;
            end 
            i_wen = 0; 
            @(negedge clk);
            @(posedge clk);
            @(posedge clk);
            @(posedge clk);
            @(posedge clk);
        end 

        // Stream image pixels
        for (i = 0; i < IMAGE_HEIGHT-2; i++) begin
            // Write logic
            // The fork allows concurrent execution of image streaming and convolution start
            fork 
                begin
                    @(posedge clk); #3;
                    if (i < IMAGE_HEIGHT-3) begin
                        for (j = 0; j < IMAGE_WIDTH; j+=4) begin
                            i_wdata = {image[i+3][j], image[i+3][j+1], image[i+3][j+2], image[i+3][j+3]};
                            i_wen = 1;
                            @(posedge clk); #3;
                        end 
                        i_wen = 0; 
                        @(negedge clk);
                        @(posedge clk);
                        @(posedge clk);
                        @(posedge clk); #3;
                    end 
                end   
                // Start convolution
                begin
                    @(posedge clk); #3;
                    i_start = 1;
                    @(posedge clk);
                    @(posedge clk); #3;
                    i_start = 0;
                    @(posedge output_valid); #3;
                    count_pixels+=4; 
                    $fwrite(outfile,"%0d\n%0d\n%0d\n%0d\n",output_pixel[31:24], output_pixel[23:16],output_pixel[15:8],output_pixel[7:0]);
                    // Capture output pixels
                    @(posedge clk); #3;
                    for (z = 1; z < IMAGE_WIDTH/4 - 1; z+=1) begin
                        if (output_valid) begin
                            $fwrite(outfile,"%0d\n%0d\n%0d\n%0d\n",output_pixel[31:24], output_pixel[23:16],output_pixel[15:8],output_pixel[7:0]);
                            count_pixels+=4; 
                        end
                        else begin
                            z--;
                        end
                        @(posedge clk); #3;
                    end
                    count_pixels+=2; 
                    $fwrite(outfile,"%0d\n%0d\n",output_pixel[31:24], output_pixel[23:16]); // Since 512 is not divisible by 4, write the remaining 2 pixels, rest are invalid
                end
            join
        end

        $fclose(outfile);
        $display("Finished writing %0d output pixels to conv_output.txt", count_pixels); // For 510x510 image, should write 260100 pixels
        $finish;
    end

endmodule
