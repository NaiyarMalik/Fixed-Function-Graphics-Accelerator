/* 
    By: Naiyar Malik
    
    Overview:
    GPU Top-Level Wrapper: Integrates the complete modular graphics pipeline 
    from Geometry Fetch down to the Display Controller and Framebuffer.
*/

module gpu_top #(
    parameter int COORD_W  = 16,
    parameter int ANGLE_W  = 16,
    parameter int SCREEN_X = 9,
    parameter int SCREEN_Y = 9,
    parameter int COLOR_W  = 24
) (
    input  logic                  clk,
    input  logic                  rst_n,
    input  logic                  frame_enable, // Pulses once per frame to trigger angle update
    input  logic                  pixel_clk_en, // Pixel clock enable for display output

    // Physical Display Outputs
    output logic                  hsync,
    output logic                  vsync,
    output logic                  data_enable,
    output logic [COLOR_W-1:0]    rgb_out
);

    // Internal pipeline interconnect wires
    logic [ANGLE_W-1:0]    angle;
    
    // Controller signals
    logic                  fetch_start, fetch_done;
    logic                  transform_start, transform_done;
    logic                  projection_start, projection_done;
    logic                  raster_start, raster_done;
    
    // ROM signals
    logic [7:0]            vertex_addr;
    logic [COORD_W-1:0]    v_rom_x, v_rom_y, v_rom_z;
    logic [7:0]            index_addr;
    logic [7:0]            i0, i1, i2;

    // Geometry Fetch outputs (Raw Vertices)
    logic [COORD_W-1:0]    v0_x, v0_y, v0_z;
    logic [COORD_W-1:0]    v1_x, v1_y, v1_z;
    logic [COORD_W-1:0]    v2_x, v2_y, v2_z;

    // Transform Engine outputs
    logic [COORD_W-1:0]    t0_x, t0_y, t0_z;
    logic [COORD_W-1:0]    t1_x, t1_y, t1_z;
    logic [COORD_W-1:0]    t2_x, t2_y, t2_z;

    // Projection outputs
    logic [SCREEN_X-1:0]   p0_x, p0_y, p1_x, p1_y, p2_x, p2_y;
    logic [COORD_W-1:0]    p0_z, p1_z, p2_z;

    // Rasterizer outputs (Pixel stream)
    logic                  rast_pixel_valid;
    logic [SCREEN_X-1:0]   rast_pixel_x;
    logic [SCREEN_Y-1:0]   rast_pixel_y;
    logic [COORD_W-1:0]    rast_pixel_z;

    // Pixel Processor outputs (Shaded Pixels)
    logic                  proc_pixel_valid;
    logic [SCREEN_X-1:0]   proc_pixel_x;
    logic [SCREEN_Y-1:0]   proc_pixel_y;
    logic [COLOR_W-1:0]    proc_pixel_color;

    // Display Controller to Framebuffer read connections
    logic [SCREEN_X-1:0]   fb_rd_x;
    logic [SCREEN_Y-1:0]   fb_rd_y;
    logic [COLOR_W-1:0]    fb_rd_color;

    // 1. Angle Counter (Animation driver)
    angle_counter #(
        .ANGLE_WIDTH(ANGLE_W)
    ) u_angle_counter (
        .clk(clk),
        .rst_n(rst_n),
        .enable(frame_enable),
        .angle_out(angle)
    );

    // 2. Render Controller (Pipeline Sequencer)
    render_controller u_render_controller (
        .clk(clk),
        .rst_n(rst_n),
        .fetch_start(fetch_start),
        .fetch_done(fetch_done),
        .transform_start(transform_start),
        .transform_done(transform_done),
        .projection_start(projection_start),
        .projection_done(projection_done),
        .raster_start(raster_start),
        .raster_done(raster_done)
    );

    // 3. Vertex ROM
    vertex_rom u_vertex_rom (
        .clk(clk),
        .addr(vertex_addr),
        .x_out(v_rom_x),
        .y_out(v_rom_y),
        .z_out(v_rom_z)
    );

    // 4. Index ROM
    index_rom u_index_rom (
        .clk(clk),
        .addr(index_addr),
        .i0_out(i0),
        .i1_out(i1),
        .i2_out(i2)
    );

    // 5. Geometry Fetch Stage
    geometry_fetch u_geometry_fetch (
        .clk(clk),
        .rst_n(rst_n),
        .fetch_start(fetch_start),
        .fetch_done(fetch_done),
        .v_rom_x(v_rom_x), .v_rom_y(v_rom_y), .v_rom_z(v_rom_z),
        .i0(i0), .i1(i1), .i2(i2),
        .vertex_addr(vertex_addr),
        .index_addr(index_addr),
        .v0_x(v0_x), .v0_y(v0_y), .v0_z(v0_z),
        .v1_x(v1_x), .v1_y(v1_y), .v1_z(v1_z),
        .v2_x(v2_x), .v2_y(v2_y), .v2_z(v2_z)
    );

    // 6. Transform Engine (3D Rotation & Translation)
    transform_engine #(
        .COORD_W(COORD_W),
        .ANGLE_W(ANGLE_W)
    ) u_transform_engine (
        .clk(clk),
        .rst_n(rst_n),
        .transform_start(transform_start),
        .transform_done(transform_done),
        .angle(angle),
        .v0_x(v0_x), .v0_y(v0_y), .v0_z(v0_z),
        .v1_x(v1_x), .v1_y(v1_y), .v1_z(v1_z),
        .v2_x(v2_x), .v2_y(v2_y), .v2_z(v2_z),
        .t0_x(t0_x), .t0_y(t0_y), .t0_z(t0_z),
        .t1_x(t1_x), .t1_y(t1_y), .t1_z(t1_z),
        .t2_x(t2_x), .t2_y(t2_y), .t2_z(t2_z)
    );

    // 7. Projection Stage (3D to 2D Screen Conversion)
    projection #(
        .COORD_W(COORD_W),
        .SCREEN_X(SCREEN_X),
        .SCREEN_Y(SCREEN_Y)
    ) u_projection (
        .clk(clk),
        .rst_n(rst_n),
        .projection_start(projection_start),
        .projection_done(projection_done),
        .t0_x(t0_x), .t0_y(t0_y), .t0_z(t0_z),
        .t1_x(t1_x), .t1_y(t1_y), .t1_z(t1_z),
        .t2_x(t2_x), .t2_y(t2_y), .t2_z(t2_z),
        .p0_x(p0_x), .p0_y(p0_y),
        .p1_x(p1_x), .p1_y(p1_y),
        .p2_x(p2_x), .p2_y(p2_y),
        .p0_z(p0_z), .p1_z(p1_z), .p2_z(p2_z)
    );

    // 8. Triangle Rasterizer (Bounding Box Scan)
    triangle_rasterizer #(
        .SCREEN_X(SCREEN_X),
        .SCREEN_Y(SCREEN_Y),
        .COORD_W(COORD_W)
    ) u_triangle_rasterizer (
        .clk(clk),
        .rst_n(rst_n),
        .raster_start(raster_start),
        .raster_done(raster_done),
        .p0_x(p0_x), .p0_y(p0_y),
        .p1_x(p1_x), .p1_y(p1_y),
        .p2_x(p2_x), .p2_y(p2_y),
        .p0_z(p0_z), .p1_z(p1_z), .p2_z(p2_z),
        .pixel_valid(rast_pixel_valid),
        .pixel_x(rast_pixel_x),
        .pixel_y(rast_pixel_y),
        .pixel_z(rast_pixel_z)
    );

    // 9. Pixel Processor (Shading & Color Generation)
    pixel_processor #(
        .SCREEN_X(SCREEN_X),
        .SCREEN_Y(SCREEN_Y),
        .COORD_W(COORD_W),
        .COLOR_W(COLOR_W)
    ) u_pixel_processor (
        .clk(clk),
        .rst_n(rst_n),
        .in_pixel_valid(rast_pixel_valid),
        .in_pixel_x(rast_pixel_x),
        .in_pixel_y(rast_pixel_y),
        .in_pixel_z(rast_pixel_z),
        .out_pixel_valid(proc_pixel_valid),
        .out_pixel_x(proc_pixel_x),
        .out_pixel_y(proc_pixel_y),
        .out_pixel_color(proc_pixel_color)
    );

    // 10. Framebuffer (Video RAM Storage)
    framebuffer #(
        .SCREEN_X(SCREEN_X),
        .SCREEN_Y(SCREEN_Y),
        .COLOR_W(COLOR_W)
    ) u_framebuffer (
        .clk(clk),
        .rst_n(rst_n),
        .wr_en(proc_pixel_valid),
        .wr_x(proc_pixel_x),
        .wr_y(proc_pixel_y),
        .wr_color(proc_pixel_color),
        .rd_x(fb_rd_x),
        .rd_y(fb_rd_y),
        .rd_color(fb_rd_color)
    );

    // 11. Display Controller (Scanout & Sync Generation)
    display_controller #(
        .SCREEN_X(SCREEN_X),
        .SCREEN_Y(SCREEN_Y),
        .COLOR_W(COLOR_W)
    ) u_display_controller (
        .clk(clk),
        .rst_n(rst_n),
        .pixel_clk_en(pixel_clk_en),
        .rd_x(fb_rd_x),
        .rd_y(fb_rd_y),
        .rd_color(fb_rd_color),
        .hsync(hsync),
        .vsync(vsync),
        .data_enable(data_enable),
        .rgb_out(rgb_out)
    );

endmodule
