/* 
    By: Naiyar Malik
    
    Overview:
    This module acts as the Vertex ROM for the GPU pipeline. It stores 
    pre-loaded 3D vertex data. When addressed by the geometry fetch stage, 
    it supplies the requested vertex coordinates synchronously.
    
*/

module vertex_rom #(
    parameter int ADDR_WIDTH = 8,  
    parameter int DATA_WIDTH = 48  
) (
    input  logic clk, rd_en,
    input  logic [ADDR_WIDTH-1:0] addr,
    output logic [DATA_WIDTH-1:0] data_out
);


    // Depth is 2^ADDR_WIDTH, width is DATA_WIDTH
    logic [DATA_WIDTH-1:0] rom [0:(1<<ADDR_WIDTH)-1];

    always_ff @(posedge clk) 
      begin
        if (rd_en) 
          begin
            data_out <= rom[addr];
        end
    end

endmodule
