/* 
    By: Naiyar Malik
    
    Overview:
    This module acts as the Index ROM for the GPU pipeline. It stores 
    pre-loaded index data defining the triangles (triplets of vertex indices). 
    When addressed by the geometry fetch stage, it supplies the vertex indices 
    synchronously.
*/

module index_rom #(
    parameter int ADDR_WIDTH = 8,  
    parameter int DATA_WIDTH = 48 
) (
    input  logic clk, rd_en,
    input  logic [ADDR_WIDTH-1:0] addr,
    output logic [DATA_WIDTH-1:0] data_out
);

  
    // Depth is 2^ADDR_WIDTH, width is DATA_WIDTH
    logic [DATA_WIDTH-1:0] rom [0:(1<<ADDR_WIDTH)-1];
  
    always_ff @(posedge clk) begin
        if (rd_en) begin
            data_out <= rom[addr];
        end
    end

endmodule
