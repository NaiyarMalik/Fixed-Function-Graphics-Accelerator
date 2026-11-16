
/*
    By: Naiyar Malik

    Overview:
    This module applies 3D Y-axis rotation to vertex coordinates
    using a fixed-point Sine/Cosine Lookup Table, sequencing
    through each vertex and signaling completion when done.
*/

module transform_engine #(
    parameter int COORD_W = 16,
    parameter int ANGLE_W = 16,
    parameter int FRAC_W  = 8
) (
    input  logic clk, rst_n,

    // Controller interface
    input  logic transform_start,
    output logic transform_done,

    // Rotation angle input
    input  logic [ANGLE_W-1:0] angle,

    // Raw vertex inputs from Geometry Fetch
    input  logic [COORD_W-1:0] v0_x, v0_y, v0_z,
    input  logic [COORD_W-1:0] v1_x, v1_y, v1_z,
    input  logic [COORD_W-1:0] v2_x, v2_y, v2_z,

    // Transformed vertex outputs passed to Projection
    output logic [COORD_W-1:0] t0_x, t0_y, t0_z,
    output logic [COORD_W-1:0] t1_x, t1_y, t1_z,
    output logic [COORD_W-1:0] t2_x, t2_y, t2_z
);

    // FSM states
    typedef enum logic [2:0] {
        T_IDLE,
        T_FETCH_TRIG,
        T_CALC_V0,
        T_CALC_V1,
        T_CALC_V2,
        T_DONE
    } transform_state_t;

    transform_state_t state, next_state;

    // Sine Lookup Table
    logic signed [COORD_W-1:0] sin_lut [0:255];

    initial begin
        $readmemh("sin_lut.mem", sin_lut);
    end

    // Lookup addresses and registered coefficients
    logic [7:0] lut_addr, cos_addr;
    logic signed [COORD_W-1:0] sin_val, cos_val;

    assign cos_addr = lut_addr + 8'd64;

    // Capture angle and retrieve sine/cosine values
    always_ff @(posedge clk or negedge rst_n)
    begin
        if (!rst_n)
        begin
            lut_addr <= '0;
            sin_val  <= '0;
            cos_val  <= '0;
        end
        else
        begin
            if (state == T_IDLE && transform_start)
            begin
                lut_addr <= angle[ANGLE_W-1 -: 8];
            end
            else if (state == T_FETCH_TRIG)
            begin
                sin_val <= sin_lut[lut_addr];
                cos_val <= sin_lut[cos_addr];
            end
        end
    end

    // Selected vertex coordinates
    logic signed [COORD_W-1:0] x, y, z;

    // Select the current vertex
    always_comb
    begin
        x = '0;
        y = '0;
        z = '0;

        case (state)

            T_CALC_V0:
            begin
                x = $signed(v0_x);
                y = $signed(v0_y);
                z = $signed(v0_z);
            end

            T_CALC_V1:
            begin
                x = $signed(v1_x);
                y = $signed(v1_y);
                z = $signed(v1_z);
            end

            T_CALC_V2:
            begin
                x = $signed(v2_x);
                y = $signed(v2_y);
                z = $signed(v2_z);
            end

            default: begin end

        endcase
    end

    // Intermediate multiplication results
    logic signed [2*COORD_W-1:0] x_cos, x_sin;
    logic signed [2*COORD_W-1:0] z_cos, z_sin;

    assign x_cos = x * cos_val;
    assign x_sin = x * sin_val;
    assign z_cos = z * cos_val;
    assign z_sin = z * sin_val;

    // Intermediate sums
    logic signed [2*COORD_W:0] x_sum, z_sum;

    assign x_sum = x_cos + z_sin;
    assign z_sum = z_cos - x_sin;

    // Restore fixed-point scaling
    logic signed [COORD_W-1:0] x_rot, y_rot, z_rot;

    assign x_rot = x_sum >>> FRAC_W;
    assign y_rot = y;
    assign z_rot = z_sum >>> FRAC_W;

    // State register
    always_ff @(posedge clk or negedge rst_n)
    begin
        if (!rst_n)
        begin
            state <= T_IDLE;
        end
        else
        begin
            state <= next_state;
        end
    end

    // Next-state and control logic
    always_comb
    begin
        next_state     = state;
        transform_done = 1'b0;

        case (state)

            T_IDLE:
            begin
                if (transform_start)
                    next_state = T_FETCH_TRIG;
            end

            T_FETCH_TRIG:
                next_state = T_CALC_V0;

            T_CALC_V0:
                next_state = T_CALC_V1;

            T_CALC_V1:
                next_state = T_CALC_V2;

            T_CALC_V2:
                next_state = T_DONE;

            T_DONE:
            begin
                transform_done = 1'b1;
                next_state     = T_IDLE;
            end

            default: next_state = T_IDLE;

        endcase
    end

    // Store transformed vertex coordinates
    always_ff @(posedge clk or negedge rst_n)
    begin
        if (!rst_n)
        begin
            t0_x <= '0; t0_y <= '0; t0_z <= '0;
            t1_x <= '0; t1_y <= '0; t1_z <= '0;
            t2_x <= '0; t2_y <= '0; t2_z <= '0;
        end
        else
        begin
            case (state)

                T_CALC_V0:
                begin
                    t0_x <= x_rot;
                    t0_y <= y_rot;
                    t0_z <= z_rot;
                end

                T_CALC_V1:
                begin
                    t1_x <= x_rot;
                    t1_y <= y_rot;
                    t1_z <= z_rot;
                end

                T_CALC_V2:
                begin
                    t2_x <= x_rot;
                    t2_y <= y_rot;
                    t2_z <= z_rot;
                end

                default: begin end

            endcase
        end
    end

endmodule
