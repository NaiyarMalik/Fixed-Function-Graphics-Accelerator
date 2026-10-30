/* 
    By: Naiyar Malik
    
    Overview:
    Display Controller: Generates screen scanning coordinates and video sync 
    signals to read pixel color data sequentially from the framebuffer and drive 
    the physical display interface.
*/

module display_controller #(
    parameter int SCREEN_X = 9,  // Screen width bits (0-511)
    parameter int SCREEN_Y = 9,  // Screen height bits (0-511)
    parameter int COLOR_W  = 24  // RGB 24-bit color width
) (
    input  logic                  clk,
    input  logic                  rst_n,
    input  logic                  pixel_clk_en, // Clock enable for pixel tick

    // Interface to Framebuffer
    output logic [SCREEN_X-1:0]   rd_x,
    output logic [SCREEN_Y-1:0]   rd_y,
    input  logic [COLOR_W-1:0]    rd_color,

    // Physical Display Outputs
    output logic                  hsync,
    output logic                  vsync,
    output logic                  data_enable,
    output logic [COLOR_W-1:0]    rgb_out
);

    // Scan counters for screen traversal
    logic [SCREEN_X-1:0] x_count;
    logic [SCREEN_Y-1:0] y_count;

    // Horizontal and vertical screen scanning logic
    always_ff @(posedge clk or negedge rst_n) 
    begin
        if (!rst_n) 
        begin
            x_count <= '0;
            y_count <= '0;
        end 
        else if (pixel_clk_en) 
        begin
            if (x_count == (1 << SCREEN_X) - 1) 
            begin
                x_count <= '0;
                if (y_count == (1 << SCREEN_Y) - 1) 
                begin
                    y_count <= '0;
                end 
                else 
                begin
                    y_count <= y_count + 1'b1;
                end
            end 
            else 
            begin
                x_count <= x_count + 1'b1;
            end
        end
    end

    // Map scan counters directly to framebuffer read addresses
    assign rd_x = x_count;
    assign rd_y = y_count;

    // Video timing synchronization and output pipeline
    always_ff @(posedge clk or negedge rst_n) 
    begin
        if (!rst_n) 
        begin
            hsync       <= 1'b0;
            vsync       <= 1'b0;
            data_enable <= 1'b0;
            rgb_out     <= '0;
        end 
        else if (pixel_clk_en) 
        begin
            // Active display flags and sync pulses (simplified raster timing)
            data_enable <= 1'b1; 
            hsync       <= (x_count == '0); 
            vsync       <= (y_count == '0 && x_count == '0); 
            rgb_out     <= rd_color;
        end
    end

endmodule
