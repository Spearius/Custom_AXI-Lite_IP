`timescale 1ns / 1ps

module multiplier_16_bit
    (
        input logic clk,
        input logic rst_n,
        input logic [15:0] a,
        input logic [15:0] b,
        
        output logic [31:0] prod
    );
    
    always_ff @(posedge clk)
        begin
            if (rst_n == 1'b0)
                begin
                    prod <= 32'd0;
                end
            
            else
                begin
                    prod <= a * b;
                end
        end
    
endmodule
