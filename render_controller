/* 
	By: Naiyar Malik
	
	Overview:

	This module (render_controller) coordinates the GPU's rendering by controlling the order in which each processing stage executes for every triangle in a 3D model.

	The controller begins when a render request is received through the start input. It then coordinates the following stages:

		1. Geometry Fetch: Retrieves the vertex data for the current triangle.
		2. Transform: Transforms the vertices into the required coordinate space.
		3. Projection: Converts 3D vertex coordinates into 2D screen coordinates.
		4. Rasterization: Determines which screen pixels are covered by the triangle.

	After a triangle completes all stages, the controller advances to the next triangle until all triangles in the model have been processed.

	The render_busy output indicates that rendering is in progress, while render_done indicates that all triangles have completed processing.

	The controller uses a finite state machine (FSM) to sequence the stages and waits for each stage's corresponding done signal before advancing. 
	
	Note: This controller coordinates the pipeline but does not perform the geometry calculations itself. The calculations are done by seperate submodules

*/


module render_controller #(
    parameter int TRI_IDX_W = 16
) (
    input  logic                  clk,
    input  logic                  rst_n,

    // Frame-level interface
    input  logic                  start,
    input  logic [TRI_IDX_W-1:0]  num_triangles,

    output logic                  render_busy,
    output logic                  render_done,

    // Geometry fetch stage
    output logic                  fetch_start,
    input  logic                  fetch_done,

    // Transform stage
    output logic                  transform_start,
    input  logic                  transform_done,

    // Projection stage
    output logic                  projection_start,
    input  logic                  projection_done,

    // Rasterization stage
    output logic                  raster_start,
    input  logic                  raster_done,

    // Current triangle index
    output logic [TRI_IDX_W-1:0]  triangle_idx
);

    typedef enum logic [2:0] {
        IDLE,
        FETCH,
        TRANSFORM,
        PROJECT,
        RASTERIZE,
        NEXT_TRIANGLE,
        FINISH
    } state_t;
	 

    state_t state, next_state;

    logic [TRI_IDX_W-1:0] triangle_count;

    // State register and triangle counter
    always_ff @(posedge clk or negedge rst_n) 
		begin
			if (!rst_n) 
				begin
					state	<= IDLE;
					triangle_count <= '0;
				end 
				
			else
				begin
					state <= next_state;

					if (state == IDLE && start) 
						begin
							triangle_count <= '0;
						end 
					
					else if (state == NEXT_TRIANGLE) 
						begin
							triangle_count <= triangle_count + 1'b1;
						end
				end
		end

    // Next-state logic
    always_comb begin
        next_state = state;

        case (state)
            IDLE: 
					begin
						if (start)
							next_state = (num_triangles == 0) ? FINISH : FETCH; // If user fails in sending the number of triangles 
					end

            FETCH:
					begin
						if (fetch_done)
                    next_state = TRANSFORM;
						end

            TRANSFORM: 
					begin
						if (transform_done)
							next_state = PROJECT;
					end

            PROJECT: 
					begin
						if (projection_done)
							next_state = RASTERIZE;
					end

            RASTERIZE: begin
					if (raster_done)
						next_state = NEXT_TRIANGLE;
					end

            NEXT_TRIANGLE: 
					begin
						if (triangle_count + 1'b1 >= num_triangles)
							next_state = FINISH;
						else
							next_state = FETCH;
					end

            FINISH:
					begin
						next_state = IDLE;
					end

            default: next_state = IDLE;
        endcase
    end

    // Outputs
    always_comb 
		begin
        fetch_start     = 1'b0;  // Since this is a combinational block these get over written depending on the state
        transform_start = 1'b0;
        projection_start = 1'b0;
        raster_start    = 1'b0;

        render_busy = (state != IDLE && state != FINISH);
        render_done = (state == FINISH);

        triangle_idx = triangle_count;

        case (state)
            FETCH:     fetch_start = 1'b1;
            TRANSFORM: transform_start = 1'b1;
            PROJECT:   projection_start = 1'b1;
            RASTERIZE: raster_start = 1'b1;
        endcase
		end

endmodule
