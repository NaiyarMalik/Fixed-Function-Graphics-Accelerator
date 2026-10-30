/* 
    By: Naiyar Malik
    
    Overview:
    Framebuffer: Stores the pixel color data for the display. It accepts 
    incoming shaded pixels from the pixel processor to write into memory, 
    and provides a read interface for the display controller.
*/

module framebuffer #(
    parameter int SCREEN_X = 9,  // Screen width bits (0-511 -> 512 width)
    parameter int SCREEN_Y = 9,  // Screen height bits (0-511 -> 512 height)
    parameter int COLOR_W  = 24  // RGB 24-bit color width
) (
    input  logic                  clk,
    input  logic                  rst_n,

    // Write interface from Pixel Processor
    input  logic                  wr_en,
    input  logic [SCREEN_X-1:0]   wr_x,
    input  logic [SCREEN_Y-1:0]   wr_y,
    input  logic [COLOR_W-1:0]    wr_color,

    // Read interface for Display Controller
    input  logic [SCREEN_X-1:0]   rd_x,
    input  logic [SCREEN_Y-1:0]   rd_y,
    output logic [COLOR_W-1:0]    rd_color
);

    // Calculate total memory depth (Width * Height pixels)
    // For 512x512, depth is 262,144 locations
    localparam int ADDR_W = SCREEN_X + SCREEN_Y;
    
    // Memory array storage (infers RAM/BRAM in synthesis)
    logic [COLOR_W-1:0] mem [0:(1 << ADDR_W)-1];

    // Combine 2D coordinates into a linear 1D memory address
    function automatic logic [ADDR_W-1:0] calc_addr (
        input logic [SCREEN_X-1:0] x,
        input logic [SCREEN_Y-1:0] y
    );
        begin
            calc_addr = (y << SCREEN_X) | x;
        end
    endfunction

    // Synchronous Write operation
    always_ff @(posedge clk) 
    begin
        if (wr_en) 
        begin
            mem[calc_addr(wr_x, wr_y)] <= wr_color;
        end
    end

    // Synchronous Read operation (for display scanning)
    always_ff @(posedge clk) 
    begin
        rd_color <= mem[calc_addr(rd_x, rd_y)];
    end

endmodule
