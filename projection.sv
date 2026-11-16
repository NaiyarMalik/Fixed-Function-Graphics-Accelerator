
/*
    By: Naiyar Malik

    Overview:
    Projection Stage: Converts 3D transformed vertex coordinates
    into 2D screen coordinates using orthographic projection,
    passes depth, and signals completion when done.
*/

module projection #(
    parameter int COORD_W  = 16,
    parameter int SCREEN_X = 9,
    parameter int SCREEN_Y = 9,
    parameter int FRAC_W   = 8,
    parameter int SCALE    = 64
) (
    input logic clk, rst_n,

    // Controller interface
    input  logic projection_start,
    output logic projection_done,

    // Transformed vertex inputs from Transform Engine
    input logic [COORD_W-1:0] t0_x, t0_y, t0_z,
    input logic [COORD_W-1:0] t1_x, t1_y, t1_z,
    input logic [COORD_W-1:0] t2_x, t2_y, t2_z,

    // Projected coordinates passed to Rasterizer
    output logic [SCREEN_X-1:0] p0_x, p1_x, p2_x,
    output logic [SCREEN_Y-1:0] p0_y, p1_y, p2_y,
    output logic [COORD_W-1:0] p0_z, p1_z, p2_z
);

    // Screen dimensions and center
    localparam int WIDTH    = 1 << SCREEN_X;
    localparam int HEIGHT   = 1 << SCREEN_Y;

    localparam int CENTER_X = WIDTH / 2;
    localparam int CENTER_Y = HEIGHT / 2;

    // FSM states
    typedef enum logic [2:0] {
        P_IDLE,
        P_CALC_V0,
        P_CALC_V1,
        P_CALC_V2,
        P_DONE
    } projection_state_t;

    projection_state_t state, next_state;

    // Selected vertex
    logic signed [COORD_W-1:0] x, y, z;

    // Intermediate screen coordinates
    logic signed [63:0] screen_x, screen_y;

    logic [SCREEN_X-1:0] projected_x;
    logic [SCREEN_Y-1:0] projected_y;

    // Select the current vertex
    always_comb
    begin
        x = '0;
        y = '0;
        z = '0;

        case (state)

            P_CALC_V0:
            begin
                x = $signed(t0_x);
                y = $signed(t0_y);
                z = $signed(t0_z);
            end

            P_CALC_V1:
            begin
                x = $signed(t1_x);
                y = $signed(t1_y);
                z = $signed(t1_z);
            end

            P_CALC_V2:
            begin
                x = $signed(t2_x);
                y = $signed(t2_y);
                z = $signed(t2_z);
            end

            default: begin end

        endcase
    end

    // Orthographic projection and fixed-point conversion
    assign screen_x = CENTER_X + ((x * SCALE) >>> FRAC_W);
    assign screen_y = CENTER_Y - ((y * SCALE) >>> FRAC_W);

    // Clamp coordinates to screen boundaries
    always_comb
    begin
        if (screen_x < 0)
            projected_x = '0;
        else if (screen_x >= WIDTH)
            projected_x = '1;
        else
            projected_x = screen_x[SCREEN_X-1:0];

        if (screen_y < 0)
            projected_y = '0;
        else if (screen_y >= HEIGHT)
            projected_y = '1;
        else
            projected_y = screen_y[SCREEN_Y-1:0];
    end

    // State register
    always_ff @(posedge clk or negedge rst_n)
    begin
        if (!rst_n)
            state <= P_IDLE;
        else
            state <= next_state;
    end

    // Next-state and control logic
    always_comb
    begin
        next_state      = state;
        projection_done = 1'b0;

        case (state)

            P_IDLE:
            begin
                if (projection_start)
                    next_state = P_CALC_V0;
            end

            P_CALC_V0:
                next_state = P_CALC_V1;

            P_CALC_V1:
                next_state = P_CALC_V2;

            P_CALC_V2:
                next_state = P_DONE;

            P_DONE:
            begin
                projection_done = 1'b1;
                next_state      = P_IDLE;
            end

            default: next_state = P_IDLE;

        endcase
    end

    // Store projected coordinates
    always_ff @(posedge clk or negedge rst_n)
    begin
        if (!rst_n)
        begin
            p0_x <= '0; p0_y <= '0; p0_z <= '0;
            p1_x <= '0; p1_y <= '0; p1_z <= '0;
            p2_x <= '0; p2_y <= '0; p2_z <= '0;
        end
        else
        begin
            case (state)

                P_CALC_V0:
                begin
                    p0_x <= projected_x;
                    p0_y <= projected_y;
                    p0_z <= z;
                end

                P_CALC_V1:
                begin
                    p1_x <= projected_x;
                    p1_y <= projected_y;
                    p1_z <= z;
                end

                P_CALC_V2:
                begin
                    p2_x <= projected_x;
                    p2_y <= projected_y;
                    p2_z <= z;
                end

                default: begin end

            endcase
        end
    end

endmodule
