/* 
    By: Naiyar Malik
    
    Overview:
    Pixel Processor: Receives valid pixels from the triangle rasterizer, 
    applies shading or color generation based on coordinates and depth, 
    and outputs the final pixel data for the framebuffer.
*/

module pixel_processor #(
    parameter int SCREEN_X = 9,  // Screen width bits (0-511)
    parameter int SCREEN_Y = 9,  // Screen height bits (0-511)
    parameter int COORD_W  = 16,
    parameter int COLOR_W  = 24  // RGB 24-bit color (8 bits per channel)
) (
    input logic clk, rst_n,

    // Input from Rasterizer
    input  logic                  in_pixel_valid,
    input  logic [SCREEN_X-1:0]   in_pixel_x,
    input  logic [SCREEN_Y-1:0]   in_pixel_y,
    input  logic [COORD_W-1:0]    in_pixel_z,

    // Output to Framebuffer
    output logic                  out_pixel_valid,
    output logic [SCREEN_X-1:0]   out_pixel_x,
    output logic [SCREEN_Y-1:0]   out_pixel_y,
    output logic [COLOR_W-1:0]    out_pixel_color
);

    // Simple procedural color generation based on pixel position and depth
    always_ff @(posedge clk or negedge rst_n) 
    begin
        if (!rst_n) 
        begin
            out_pixel_valid <= 1'b0;
            out_pixel_x     <= '0;
            out_pixel_y     <= '0;
            out_pixel_color <= '0;
        end 
        else 
        begin
            out_pixel_valid <= in_pixel_valid;
            out_pixel_x     <= in_pixel_x;
            out_pixel_y     <= in_pixel_y;

            if (in_pixel_valid) 
            begin
                // Generate simple dynamic color gradient based on X, Y, and Z depth
                out_pixel_color <= {
                    in_pixel_x[7:0],                    // Red channel from X coordinate
                    in_pixel_y[7:0],                    // Green channel from Y coordinate
                    in_pixel_z[COORD_W-1 -: 8]          // Blue channel from Z depth
                };
            end
        end
    end

endmodule
