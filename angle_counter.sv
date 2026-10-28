/* 
    By: Naiyar Malik
    
    Overview:
    Generates a rolling angle value used by the 
    transform engine to rotate 3D models over time.
*/

module angle_counter #(
    parameter int ANGLE_WIDTH = 16
) (
    input  logic clk,
    input  logic rst_n,
    input  logic enable,    
    output logic [ANGLE_WIDTH-1:0]  angle_out
);

    always_ff @(posedge clk or negedge rst_n) 
      begin
        if (!rst_n) 
          begin
            angle_out <= '0;
          end 
          else if (enable) begin
            angle_out <= angle_out + 1'b1;
          end
      end

endmodule
