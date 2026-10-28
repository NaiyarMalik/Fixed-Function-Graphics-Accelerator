/* 
    By: Naiyar Malik
    
    Overview:
    This module applies real 3D rotation (Y-axis rotation via Sin/Cos LUT) 
    and translation to the vertex coordinates, sequencing through each vertex 
    and signaling completion when done.
*/

module transform_engine #(
    parameter int COORD_W = 16,
    parameter int ANGLE_W = 16,
    parameter int FRAC_W  = 8   // Fractional bits for fixed-point math
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


    typedef enum logic [2:0] {
        T_IDLE,
        T_FETCH_TRIG, // Look up sine/cosine values
        T_CALC_V0,    // Transform Vertex 0
        T_CALC_V1,    // Transform Vertex 1
        T_CALC_V2,    // Transform Vertex 2
        T_DONE
    } transform_state_t;

    transform_state_t state, next_state;

    // Sine and Cosine values from LUT (signed fixed-point: 1 sign, 7 integer, 8 fractional)
    logic signed [COORD_W-1:0] sin_val, cos_val;

    // Use top bits of angle to index into a 256-entry Sin/Cos table
    logic [7:0] lut_addr;
    assign lut_addr = angle[ANGLE_W-1 -: 8];

    // Simple Sine/Cosine LUT generation 
    always_comb begin
        case (lut_addr[7:6])
            2'b00: 
              begin 
                sin_val =  {8'h00, lut_addr}; 
                cos_val =  {8'h00, 8'hFF - lut_addr}; 
              end
            2'b01: 
              begin 
                sin_val =  {8'h00, 8'hFF - lut_addr}; 
                cos_val = -{8'h00, lut_addr}; 
              end
            2'b10: 
              begin 
                sin_val = -{8'h00, lut_addr}; 
                cos_val = -{8'h00, 8'hFF - lut_addr}; 
              end
            default: 
              begin 
                sin_val = -{8'h00, 8'hFF - lut_addr}; 
                cos_val =  {8'h00, lut_addr}; 
              end
        endcase
    end


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

  always_comb begin
        next_state = state;
        transform_done = 1'b0;

        case (state)
            T_IDLE: 
              begin
                if (transform_start)
                    next_state = T_FETCH_TRIG;
              end

            T_FETCH_TRIG: 
              begin
                next_state = T_CALC_V0;
              end

            T_CALC_V0: 
              begin
                next_state = T_CALC_V1;
              end

            T_CALC_V1: 
              begin
                next_state = T_CALC_V2;
              end

            T_CALC_V2: 
              begin
                next_state = T_DONE;
              end

            T_DONE: 
              begin
                transform_done = 1'b1;
                next_state     = T_IDLE;
              end

            default: next_state = T_IDLE;
        endcase
    end

    // Transformation calculation logic (Y-axis rotation: X' = X*cos + Z*sin, Y' = Y, Z' = -X*sin + Z*cos)
    always_ff @(posedge clk or negedge rst_n) begin
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
                    t0_x <= $signed(v0_x) * cos_val[7:0] + $signed(v0_z) * sin_val[7:0];
                    t0_y <= v0_y;
                    t0_z <= -($signed(v0_x) * sin_val[7:0]) + $signed(v0_z) * cos_val[7:0];
                  end
                T_CALC_V1: 
                  begin
                    t1_x <= $signed(v1_x) * cos_val[7:0] + $signed(v1_z) * sin_val[7:0];
                    t1_y <= v1_y;
                    t1_z <= -($signed(v1_x) * sin_val[7:0]) + $signed(v1_z) * cos_val[7:0];
                  end
                T_CALC_V2: 
                  begin
                    t2_x <= $signed(v2_x) * cos_val[7:0] + $signed(v2_z) * sin_val[7:0];
                    t2_y <= v2_y;
                    t2_z <= -($signed(v2_x) * sin_val[7:0]) + $signed(v2_z) * cos_val[7:0];
                  end
                
            endcase
        end
    end

endmodule
