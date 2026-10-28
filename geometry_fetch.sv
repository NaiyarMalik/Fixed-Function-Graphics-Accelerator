/* 
    By: Naiyar Malik
    
    Overview:
    Implements Geometry Fetch stage which takes the triangle index, looks up its vertex indices 
    from the Index ROM, retrieves their 3D coordinates from the Vertex ROM, 
    and signals when the triangle data is ready.
*/

module geometry_fetch #(
    parameter int TRI_IDX_W   = 16,
    parameter int VERT_ADDR_W = 8,
    parameter int COORD_W = 16,
    parameter int VERT_DATA_W = 48 
) (
    input  logic clk, rst_n,

    // Controller interface
    input  logic fetch_start,
    input  logic [TRI_IDX_W-1:0] triangle_idx,
    output logic fetch_done,

    // Index ROM interface
    output logic index_rd_en,
    output logic [TRI_IDX_W-1:0] index_addr,
    input logic [47:0] index_data_in, // Assumes 3 x 16-bit indices packed: [V2, V1, V0]

    // Vertex ROM interface
    output logic vert_rd_en,
    output logic [VERT_ADDR_W-1:0] vert_addr,
    input  logic [VERT_DATA_W-1:0] vert_data_in,

    // Output data passed downstream to Transform stage
    output logic [COORD_W-1:0] v0_x, v0_y, v0_z,
    output logic [COORD_W-1:0] v1_x, v1_y, v1_z,
    output logic [COORD_W-1:0] v2_x, v2_y, v2_z
);

    // States for fetching a triangle (Index lookup -> Vertex 0 -> Vertex 1 -> Vertex 2)
    typedef enum logic [2:0] {
        F_IDLE,
        F_INDEX_REQ,
        F_INDEX_WAIT,
        F_VERT_0,
        F_VERT_1,
        F_VERT_2,
        F_DONE
    } fetch_state_t;

    fetch_state_t state, next_state;

    // Registers to hold decoded vertex indices
    logic [VERT_ADDR_W-1:0] idx0, idx1, idx2;


    always_ff @(posedge clk or negedge rst_n) 
      begin
        if (!rst_n) begin
            state <= F_IDLE;
        end else begin
            state <= next_state;
        end
    end

    // Capture indices when index ROM responds
    always_ff @(posedge clk or negedge rst_n) 
      begin
        if (!rst_n) 
          begin
            idx0 <= '0;
            idx1 <= '0;
            idx2 <= '0;
          end
        else if (state == F_INDEX_WAIT)
          begin
            // Unpack index data (assuming 16 bits per index: [V2, V1, V0])
            idx0 <= index_data_in[15:0];
            idx1 <= index_data_in[31:16];
            idx2 <= index_data_in[47:32];
          end
    end

    // Capture vertex coordinate data as they arrive from Vertex ROM
    always_ff @(posedge clk or negedge rst_n)
      begin
        if (!rst_n) 
          begin
            v0_x <= '0; v0_y <= '0; v0_z <= '0;
            v1_x <= '0; v1_y <= '0; v1_z <= '0;
            v2_x <= '0; v2_y <= '0; v2_z <= '0;
          end 
        else 
          begin
            if (state == F_VERT_0 && vert_rd_en) 
              begin
                // Assuming vert_data_in packs Z, Y, X (e.g., [Z, Y, X])
                v0_x <= vert_data_in[15:0];
                v0_y <= vert_data_in[31:16];
                v0_z <= vert_data_in[47:32];
              end 
            else if (state == F_VERT_1 && vert_rd_en) 
              begin
                v1_x <= vert_data_in[15:0];
                v1_y <= vert_data_in[31:16];
                v1_z <= vert_data_in[47:32];
              end 
            else if (state == F_VERT_2 && vert_rd_en) 
              begin
                v2_x <= vert_data_in[15:0];
                v2_y <= vert_data_in[31:16];
                v2_z <= vert_data_in[47:32];
              end
          end
    end

    always_comb 
      begin
        next_state   = state;
        index_rd_en  = 1'b0;
        index_addr   = triangle_idx[VERT_ADDR_W-1:0];
        vert_rd_en   = 1'b0;
        vert_addr    = '0;
        fetch_done   = 1'b0;

        case (state)
            F_IDLE: 
              begin
                if (fetch_start)
                    next_state = F_INDEX_REQ;
              end

            F_INDEX_REQ: 
              begin
                index_rd_en = 1'b1;
                next_state  = F_INDEX_WAIT;
              end

            F_INDEX_WAIT: 
              begin
                // Synchronous ROM read latency of 1 cycle assumed here
                next_state = F_VERT_0;
              end

            F_VERT_0: 
              begin
                vert_rd_en = 1'b1;
                vert_addr  = idx0;
                next_state = F_VERT_1;
              end

            F_VERT_1: 
                begin
                vert_rd_en = 1'b1;
                vert_addr  = idx1;
                next_state = F_VERT_2;
              end

            F_VERT_2: 
              begin
                vert_rd_en = 1'b1;
                vert_addr  = idx2;
                next_state = F_DONE;
              end

            F_DONE: 
              begin
                fetch_done = 1'b1;
                next_state = F_IDLE;
              end

            default: next_state = F_IDLE;
        endcase
    end

endmodule
