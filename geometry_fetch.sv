
/*
    By: Naiyar Malik

    Overview:
    Implements Geometry Fetch stage which takes the triangle index,
    looks up its vertex indices from the Index ROM, retrieves their
    3D coordinates from the Vertex ROM, and signals when the
    triangle data is ready.
*/

module geometry_fetch #(
    parameter int TRI_IDX_W   = 8,
    parameter int VERT_ADDR_W = 8,
    parameter int COORD_W     = 16,
    parameter int VERT_DATA_W = 3 * COORD_W
) (
    input  logic clk, rst_n,

    // Controller interface
    input  logic fetch_start,
    input  logic [TRI_IDX_W-1:0] triangle_idx,
    output logic fetch_done,

    // Index ROM interface
    output logic index_rd_en,
    output logic [TRI_IDX_W-1:0] index_addr,
    input  logic [3*VERT_ADDR_W-1:0] index_data_in,

    // Vertex ROM interface
    output logic vert_rd_en,
    output logic [VERT_ADDR_W-1:0] vert_addr,
    input  logic [VERT_DATA_W-1:0] vert_data_in,

    // Output data passed downstream to Transform stage
    output logic [COORD_W-1:0] v0_x, v0_y, v0_z,
    output logic [COORD_W-1:0] v1_x, v1_y, v1_z,
    output logic [COORD_W-1:0] v2_x, v2_y, v2_z
);

    // States for fetching a triangle
    typedef enum logic [3:0] {
        F_IDLE,
        F_INDEX_REQ,
        F_INDEX_WAIT,
        F_VERT_0_REQ,
        F_VERT_0_WAIT,
        F_VERT_1_REQ,
        F_VERT_1_WAIT,
        F_VERT_2_REQ,
        F_VERT_2_WAIT,
        F_DONE
    } fetch_state_t;

    fetch_state_t state, next_state;

    // Registers to hold decoded vertex indices
    logic [VERT_ADDR_W-1:0] idx0, idx1, idx2;

    // State register
    always_ff @(posedge clk or negedge rst_n)
    begin
        if (!rst_n)
        begin
            state <= F_IDLE;
        end
        else
        begin
            state <= next_state;
        end
    end

    // Capture indices when Index ROM responds
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
            // Unpack indices: [V2, V1, V0]
            {idx2, idx1, idx0} <= index_data_in;
        end
    end

    // Capture vertex coordinates after ROM read
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
            case (state)

                F_VERT_0_WAIT:
                begin
                    {v0_z, v0_y, v0_x} <= vert_data_in;
                end

                F_VERT_1_WAIT:
                begin
                    {v1_z, v1_y, v1_x} <= vert_data_in;
                end

                F_VERT_2_WAIT:
                begin
                    {v2_z, v2_y, v2_x} <= vert_data_in;
                end

                default: begin end

            endcase
        end
    end

    // Next-state and output control logic
    always_comb
    begin
        next_state  = state;
        index_rd_en = 1'b0;
        index_addr  = triangle_idx;
        vert_rd_en  = 1'b0;
        vert_addr   = '0;
        fetch_done  = 1'b0;

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
                next_state = F_VERT_0_REQ;
            end

            F_VERT_0_REQ:
            begin
                vert_rd_en = 1'b1;
                vert_addr  = idx0;
                next_state = F_VERT_0_WAIT;
            end

            F_VERT_0_WAIT:
            begin
                next_state = F_VERT_1_REQ;
            end

            F_VERT_1_REQ:
            begin
                vert_rd_en = 1'b1;
                vert_addr  = idx1;
                next_state = F_VERT_1_WAIT;
            end

            F_VERT_1_WAIT:
            begin
                next_state = F_VERT_2_REQ;
            end

            F_VERT_2_REQ:
            begin
                vert_rd_en = 1'b1;
                vert_addr  = idx2;
                next_state = F_VERT_2_WAIT;
            end

            F_VERT_2_WAIT:
            begin
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
