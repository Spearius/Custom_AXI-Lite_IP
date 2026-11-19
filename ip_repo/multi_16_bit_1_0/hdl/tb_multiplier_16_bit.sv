`timescale 1ns / 1ps

module tb_multiplier_16_bit();

    logic clk = 1'b0;
    logic rst_n;
    logic [15:0] a;
    logic [15:0] b;
    logic [31:0] prod;
    
    
    multiplier_16_bit DUT
        (
            .clk(clk),
            .rst_n(rst_n),
            .a(a),
            .b(b),
            .prod(prod)
        );
    
    integer i;            
    localparam int CLK_PERIOD = 8;      // 125 MHz
    
    always #(CLK_PERIOD / 2) clk = ~clk;
    
    initial
        begin
            // Start with reset active and inputs at zero.
            rst_n = 1'b0;
            a = 16'd0;
            b = 16'd0;
        
            // Wait two clock cycles, then release reset.
            repeat (2) @(negedge clk);
            rst_n = 1'b1;
        
            // Multiply each number from 1 to 32 by itself.
            for (i = 1; i <= 32; i = i + 1)
                begin
                    a = i;
                    b = i;
        
                    // Wait for the multiplier to update its output.
                    @(posedge clk);
                    #1;
        
                    if (prod == (i * i))
                        begin
                            $display("PASS: %0d * %0d = %0d", a, b, prod);
                        end
                    else
                        begin
                            $display("FAIL: %0d * %0d produced %0d", a, b, prod);
                            $finish;
                        end
        
                    // Wait before changing the inputs.
                    @(negedge clk);
                end
        
            a = 16'd0;
            b = 16'd0;
        
            repeat (2) @(negedge clk);
        
            $display("All 32 multiplication tests passed.");
            
            $finish;
        end

endmodule
