/* 
    By: Naiyar Malik
    
    Overview:
    VGA Display Controller: Generates standard 640x480 @ 60Hz timing signals 
    (hsync, vsync, data_enable) and maps active-pixel coordinates to read from the framebuffer.
*/

module display_controller #(
    parameter int COLOR_W = 24
) (
    input  logic                  pixel_clk,    // ~25.175 MHz pixel clock
    input  logic                  rst_n,

    // Interface to Framebuffer (640x480 resolution)
    output logic [9:0]            rd_x,         // 0 to 639 
    output logic [9:0]            rd_y,         // 0 to 480 
    input  logic [COLOR_W-1:0]    rd_color,

    // Physical VGA Outputs
    output logic                  hsync,
    output logic                  vsync,
    output logic                  data_enable,
    output logic [COLOR_W-1:0]    rgb_out
);

    // Standard 640x480 @ 60Hz Timing Constants (in pixel clocks / lines)
    localparam int H_ACTIVE  = 640;
    localparam int H_FP      = 16;
    localparam int H_SYNC    = 96;
    localparam int H_BP      = 48;
    localparam int H_TOTAL   = H_ACTIVE + H_FP + H_SYNC + H_BP; // 800

    localparam int V_ACTIVE  = 480;
    localparam int V_FP      = 10;
    localparam int V_SYNC    = 2;
    localparam int V_BP      = 33;
    localparam int V_TOTAL   = V_ACTIVE + V_FP + V_SYNC + V_BP; // 525

    // Scan counters
    logic [9:0] h_count;
    logic [9:0] v_count;

    // Horizontal and Vertical scan counter logic
    always_ff @(posedge pixel_clk or negedge rst_n) 
    begin
        if (!rst_n) 
        begin
            h_count <= '0;
            v_count <= '0;
        end 
        else 
        begin
            if (h_count == H_TOTAL - 1) 
            begin
                h_count <= '0;
                if (v_count == V_TOTAL - 1) 
                begin
                    v_count <= '0;
                end 
                else 
                begin
                    v_count <= v_count + 1'b1;
                end
            end 
            else 
            begin
                h_count <= h_count + 1'b1;
            end
        end
    end

    // Generate Sync Pulses (Negative polarity for standard 640x480 VGA)
    always_ff @(posedge pixel_clk or negedge rst_n) 
    begin
        if (!rst_n) 
        begin
            hsync <= 1'b1;
            vsync <= 1'b1;
        end 
        else 
        begin
            hsync <= ~((h_count >= (H_ACTIVE + H_FP)) && (h_count < (H_ACTIVE + H_FP + H_SYNC)));
            vsync <= ~((v_count >= (V_ACTIVE + V_FP)) && (v_count < (V_ACTIVE + V_FP + V_SYNC)));
        end
    end

    // Active video display region check
    assign data_enable = (h_count < H_ACTIVE) && (v_count < V_ACTIVE);

    // Map scan counters to framebuffer read coordinates
    assign rd_x = data_enable ? h_count : '0;
    assign rd_y = data_enable ? v_count : '0;

    // Drive output RGB color (outputs black during porch/sync blanking intervals)
    always_ff @(posedge pixel_clk or negedge rst_n) 
    begin
        if (!rst_n) 
        begin
            rgb_out <= '0;
        end 
        else 
        begin
            if (data_enable) 
            begin
                rgb_out <= rd_color;
            end 
            else 
            begin
                rgb_out <= '0; 
            end
        end
    end

endmodule
