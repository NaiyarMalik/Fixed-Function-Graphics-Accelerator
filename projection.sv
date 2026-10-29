/* 
    By: Naiyar Malik
    
    Overview:
    Projection Stage: Converts 3D transformed vertex coordinates into 
    2D screen coordinates (and passes depth), sequencing through each vertex 
    and signaling completion when done.
*/

module projection #(
    parameter int COORD_W  = 16,
    parameter int SCREEN_X = 9,  // Screen width bits (e.g., 0-511)
    parameter int SCREEN_Y = 9   // Screen height bits (e.g., 0-511)
) (
    
    input logic clk, rst_n,

    // Controller interface
    input logic projection_start,
    output logic projection_done,

    // Transformed vertex inputs from Transform Engine
    input  logic [COORD_W-1:0] t0_x, t0_y, t0_z,
    input  logic [COORD_W-1:0] t1_x, t1_y, t1_z,
    input  logic [COORD_W-1:0] t2_x, t2_y, t2_z,

    // Projected 2D screen coordinate outputs passed to Rasterizer
    output logic [SCREEN_X-1:0]   p0_x, p0_y,
    output logic [SCREEN_X-1:0]   p1_x, p1_y,
    output logic [SCREEN_X-1:0]   p2_x, p2_y,
    output logic [COORD_W-1:0]    p0_z, p1_z, p2_z 
);

    typedef enum logic [2:0] {
        P_IDLE,
        P_CALC_V0,
        P_CALC_V1,
        P_CALC_V2,
        P_DONE
    } projection_state_t;

    projection_state_t state, next_state;

    always_ff @(posedge clk or negedge rst_n) 
      begin
        if (!rst_n) 
          begin
            state <= P_IDLE;
          end 
          else 
            begin
              state <= next_state;
            end
      end

    
    always_comb 
      begin
        next_state = state;
        projection_done = 1'b0;

        case (state)
            P_IDLE: 
              begin
                if (projection_start)
                    next_state = P_CALC_V0;
              end

            P_CALC_V0: 
              begin
                next_state = P_CALC_V1;
              end

            P_CALC_V1: 
              begin
                next_state = P_CALC_V2;
              end

            P_CALC_V2: 
              begin
                next_state = P_DONE;
              end

            P_DONE: 
              begin
                projection_done = 1'b1;
                next_state = P_IDLE;
              end

            default: next_state = P_IDLE;
        endcase
    end


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
                    p0_x <= 9'd256 + ($signed(t0_x[COORD_W-1:0]) >>> 1);
                    p0_y <= 9'd256 + ($signed(t0_y[COORD_W-1:0]) >>> 1);
                    p0_z <= t0_z;
                  end
                P_CALC_V1: 
                  begin
                    p1_x <= 9'd256 + ($signed(t1_x[COORD_W-1:0]) >>> 1);
                    p1_y <= 9'd256 + ($signed(t1_y[COORD_W-1:0]) >>> 1);
                    p1_z <= t1_z;
                  end
                P_CALC_V2: 
                  begin
                    p2_x <= 9'd256 + ($signed(t2_x[COORD_W-1:0]) >>> 1);
                    p2_y <= 9'd256 + ($signed(t2_y[COORD_W-1:0]) >>> 1);
                    p2_z <= t2_z;
                  end
           endcase
        end
    end

endmodule
