/* 
    By: Naiyar Malik
    
    Overview:
    Triangle Rasterizer: Takes 2D screen coordinates of a triangle, 
    traverses its bounding box using edge equations to identify covered pixels, 
    and signals completion when rasterization is done.
*/

module triangle_rasterizer #(
    parameter int SCREEN_X = 9,  // Screen width bits (0-511)
    parameter int SCREEN_Y = 9,  // Screen height bits (0-511)
    parameter int COORD_W  = 16
) (
    input  logic                  clk,
    input  logic                  rst_n,

    // Controller interface
    input  logic                  raster_start,
    output logic                  raster_done,

    // Projected 2D vertex inputs from Projection Stage
    input  logic [SCREEN_X-1:0]   p0_x, p0_y,
    input  logic [SCREEN_X-1:0]   p1_x, p1_y,
    input  logic [SCREEN_X-1:0]   p2_x, p2_y,
    input  logic [COORD_W-1:0]    p0_z, p1_z, p2_z,

    // Pixel output interface (sent downstream to Pixel Processor / Framebuffer)
    output logic                  pixel_valid,
    output logic [SCREEN_X-1:0]   pixel_x,
    output logic [SCREEN_Y-1:0]   pixel_y,
    output logic [COORD_W-1:0]    pixel_z
);

    // FSM States for Rasterization
    typedef enum logic [1:0] {
        R_IDLE,
        R_SCAN,
        R_DONE
    } raster_state_t;

    raster_state_t state, next_state;

    // Bounding box registers and current pixel scan pointers
    logic [SCREEN_X-1:0] min_x, max_x;
    logic [SCREEN_Y-1:0] min_y, max_y;
    logic [SCREEN_X-1:0] curr_x;
    logic [SCREEN_Y-1:0] curr_y;

    // State register
    always_ff @(posedge clk or negedge rst_n) 
    begin
        if (!rst_n) 
        begin
            state <= R_IDLE;
        end 
        else 
        begin
            state <= next_state;
        end
    end

    // Find bounding box of the triangle upon starting
    always_ff @(posedge clk or negedge rst_n) 
    begin
        if (!rst_n) 
        begin
            min_x <= '0; max_x <= '0;
            min_y <= '0; max_y <= '0;
            curr_x <= '0; curr_y <= '0;
        end 
        else if (raster_start && state == R_IDLE) 
        begin
            // Simple bounding box calculation across p0, p1, p2
            min_x <= (p0_x < p1_x) ? ((p0_x < p2_x) ? p0_x : p2_x) : ((p1_x < p2_x) ? p1_x : p2_x);
            max_x <= (p0_x > p1_x) ? ((p0_x > p2_x) ? p0_x : p2_x) : ((p1_x > p2_x) ? p1_x : p2_x);
            min_y <= (p0_y < p1_y) ? ((p0_y < p2_y) ? p0_y : p2_y) : ((p1_y < p2_y) ? p1_y : p2_y);
            max_y <= (p0_y > p1_y) ? ((p0_y > p2_y) ? p0_y : p2_y) : ((p1_y > p2_y) ? p1_y : p2_y);

            curr_x <= (p0_x < p1_x) ? ((p0_x < p2_x) ? p0_x : p2_x) : ((p1_x < p2_x) ? p1_x : p2_x);
            curr_y <= (p0_y < p1_y) ? ((p0_y < p2_y) ? p0_y : p2_y) : ((p1_y < p2_y) ? p1_y : p2_y);
        end 
        else if (state == R_SCAN) 
        begin
            // Scan through bounding box pixels
            if (curr_x < max_x) 
            begin
                curr_x <= curr_x + 1'b1;
            end 
            else 
            begin
                curr_x <= min_x;
                if (curr_y < max_y) 
                begin
                    curr_y <= curr_y + 1'b1;
                end
            end
        end
    end

    // Next-state logic
    always_comb 
    begin
        next_state  = state;
        raster_done = 1'b0;
        pixel_valid = 1'b0;
        pixel_x     = curr_x;
        pixel_y     = curr_y;
        pixel_z     = p0_z; // Simplified depth pass-through

        case (state)
            R_IDLE: 
            begin
                if (raster_start)
                    next_state = R_SCAN;
            end

            R_SCAN: 
            begin
                pixel_valid = 1'b1; // Emit pixels inside bounding box (add edge function check here for exact triangle coverage)
                
                if (curr_x == max_x && curr_y == max_y) 
                begin
                    next_state = R_DONE;
                end
            end

            R_DONE: 
            begin
                raster_done = 1'b1;
                next_state  = R_IDLE;
            end

            default: next_state = R_IDLE;
        endcase
    end

endmodule
