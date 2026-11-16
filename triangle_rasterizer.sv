
/* 
    By: Naiyar Malik
    
    Overview:
    Triangle Rasterizer: Takes 2D screen coordinates of a triangle, 
    traverses its bounding box using edge equations to identify covered pixels, 
    and signals completion when rasterization is done.
*/

module triangle_rasterizer #(
    parameter int SCREEN_X = 9,
    parameter int SCREEN_Y = 9,
    parameter int COORD_W  = 16
) (
    input logic clk, rst_n,

    // Controller interface
    input  logic raster_start,
    output logic raster_done,

    // Projected vertex inputs from Projection Stage
    input logic [SCREEN_X-1:0] p0_x, p1_x, p2_x,
    input logic [SCREEN_Y-1:0] p0_y, p1_y, p2_y,
    input logic [COORD_W-1:0]  p0_z, p1_z, p2_z,

    // Pixel output interface
    output logic pixel_valid,
    output logic [SCREEN_X-1:0] pixel_x,
    output logic [SCREEN_Y-1:0] pixel_y,
    output logic [COORD_W-1:0]  pixel_z
);

    // FSM States
    typedef enum logic [1:0] {
        R_IDLE,
        R_SCAN,
        R_DONE
    } raster_state_t;

    raster_state_t state, next_state;

    // Bounding box registers
    logic [SCREEN_X-1:0] min_x, max_x;
    logic [SCREEN_Y-1:0] min_y, max_y;

    // Current pixel coordinates
    logic [SCREEN_X-1:0] curr_x;
    logic [SCREEN_Y-1:0] curr_y;

    // Signed edge results
    int e0, e1, e2;

    // Edge 0: V0 -> V1
    assign e0 = (int'(p1_x) - int'(p0_x)) *
                (int'(curr_y) - int'(p0_y)) -
                (int'(p1_y) - int'(p0_y)) *
                (int'(curr_x) - int'(p0_x));

    // Edge 1: V1 -> V2
    assign e1 = (int'(p2_x) - int'(p1_x)) *
                (int'(curr_y) - int'(p1_y)) -
                (int'(p2_y) - int'(p1_y)) *
                (int'(curr_x) - int'(p1_x));

    // Edge 2: V2 -> V0
    assign e2 = (int'(p0_x) - int'(p2_x)) *
                (int'(curr_y) - int'(p2_y)) -
                (int'(p0_y) - int'(p2_y)) *
                (int'(curr_x) - int'(p2_x));

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

    // Calculate bounding box and scan through pixels
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
            // Find smallest and largest X coordinates
            min_x <= (p0_x < p1_x) ?
                     ((p0_x < p2_x) ? p0_x : p2_x) :
                     ((p1_x < p2_x) ? p1_x : p2_x);

            max_x <= (p0_x > p1_x) ?
                     ((p0_x > p2_x) ? p0_x : p2_x) :
                     ((p1_x > p2_x) ? p1_x : p2_x);

            // Find smallest and largest Y coordinates
            min_y <= (p0_y < p1_y) ?
                     ((p0_y < p2_y) ? p0_y : p2_y) :
                     ((p1_y < p2_y) ? p1_y : p2_y);

            max_y <= (p0_y > p1_y) ?
                     ((p0_y > p2_y) ? p0_y : p2_y) :
                     ((p1_y > p2_y) ? p1_y : p2_y);

            // Start at top-left corner of bounding box
            curr_x <= (p0_x < p1_x) ?
                      ((p0_x < p2_x) ? p0_x : p2_x) :
                      ((p1_x < p2_x) ? p1_x : p2_x);

            curr_y <= (p0_y < p1_y) ?
                      ((p0_y < p2_y) ? p0_y : p2_y) :
                      ((p1_y < p2_y) ? p1_y : p2_y);
        end 
        else if (state == R_SCAN) 
        begin
            // Move right to the next pixel
            if (curr_x < max_x) 
            begin
                curr_x <= curr_x + 1'b1;
            end 
            // Move down to the next row
            else if (curr_y < max_y)
            begin
                curr_x <= min_x;
                curr_y <= curr_y + 1'b1;
            end
        end
    end

    // Next-state and pixel output logic
    always_comb 
    begin
        next_state  = state;
        raster_done = 1'b0;
        pixel_valid = 1'b0;

        pixel_x = curr_x;
        pixel_y = curr_y;
        pixel_z = p0_z;

        case (state)

            R_IDLE: 
            begin
                if (raster_start)
                    next_state = R_SCAN;
            end

            R_SCAN: 
            begin
                // Only validate pixels inside the triangle
                // Reject triangles with zero area
                if ((e0 + e1 + e2 != 0) &&
                    ((e0 >= 0 && e1 >= 0 && e2 >= 0) ||
                     (e0 <= 0 && e1 <= 0 && e2 <= 0)))
                begin
                    pixel_valid = 1'b1;
                end
                
                // Check if entire bounding box is scanned
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
