
/* 
    By: Naiyar Malik
    
    Overview:
    Framebuffer: Stores monochrome pixel data.
    Receives valid white pixels from the pixel processor,
    provides pixel data to the display controller,
    and clears the framebuffer before rendering a new frame.
*/

module framebuffer #(
    parameter int SCREEN_X = 9,
    parameter int SCREEN_Y = 9,
    parameter int COLOR_W  = 1
) (
    input logic clk, rst_n,

    // Clear interface from Render Controller
    input  logic clear_start,
    output logic clear_done,

    // Write interface from Pixel Processor
    input logic wr_en,
    input logic [SCREEN_X-1:0] wr_x,
    input logic [SCREEN_Y-1:0] wr_y,
    input logic [COLOR_W-1:0]  wr_color,

    // Read interface for Display Controller
    input  logic [SCREEN_X-1:0] rd_x,
    input  logic [SCREEN_Y-1:0] rd_y,
    output logic [COLOR_W-1:0]  rd_color
);

    // Memory dimensions
    localparam int ADDR_W = SCREEN_X + SCREEN_Y;
    localparam int DEPTH  = 1 << ADDR_W;

    // Framebuffer memory
    logic [COLOR_W-1:0] mem [0:DEPTH-1];

    // Read and write addresses
    logic [ADDR_W-1:0] wr_addr, rd_addr;

    assign wr_addr = {wr_y, wr_x};
    assign rd_addr = {rd_y, rd_x};

    // Clear FSM
    typedef enum logic [1:0] {
        FB_IDLE,
        FB_CLEAR,
        FB_DONE
    } fb_state_t;

    fb_state_t state;

    logic [ADDR_W-1:0] clear_addr;

    // Clear control
    always_ff @(posedge clk or negedge rst_n)
    begin
        if (!rst_n)
        begin
            state      <= FB_IDLE;
            clear_addr <= '0;
        end
        else
        begin
            case (state)

                FB_IDLE:
                begin
                    if (clear_start)
                    begin
                        clear_addr <= '0;
                        state <= FB_CLEAR;
                    end
                end

                FB_CLEAR:
                begin
                    if (clear_addr == DEPTH - 1)
                        state <= FB_DONE;
                    else
                        clear_addr <= clear_addr + 1'b1;
                end

                FB_DONE:
                begin
                    state <= FB_IDLE;
                end

                default: state <= FB_IDLE;

            endcase
        end
    end

    assign clear_done = (state == FB_DONE);

    // Synchronous memory write
    always_ff @(posedge clk)
    begin
        if (rst_n)
        begin
            if (state == FB_CLEAR)
                mem[clear_addr] <= '0;

            else if (state == FB_IDLE && !clear_start && wr_en)
                mem[wr_addr] <= wr_color;
        end
    end

    // Synchronous memory read
    always_ff @(posedge clk)
    begin
        rd_color <= mem[rd_addr];
    end

endmodule
