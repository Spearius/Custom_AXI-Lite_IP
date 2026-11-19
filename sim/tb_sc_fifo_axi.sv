`timescale 1ns / 1ps

module tb_sc_fifo_axi();

    logic clk = 1'b0;
    logic rst_n = 1'b0;

    // AXI write address channel
    logic [5:0] awaddr = 0;
    logic [2:0] awprot = 0;
    logic awvalid = 0;
    wire awready;

    // AXI write data channel
    logic [31:0] wdata = 0;
    logic [3:0] wstrb = 0;
    logic wvalid = 0;
    wire wready;

    // AXI write response channel
    wire [1:0] bresp;
    wire bvalid;
    logic bready = 0;

    // AXI read address channel
    logic [5:0] araddr = 0;
    logic [2:0] arprot = 0;
    logic arvalid = 0;
    wire arready;

    // AXI read data channel
    wire [31:0] rdata;
    wire [1:0] rresp;
    wire rvalid;
    logic rready = 0;

    logic [31:0] read_value;

    localparam int CLK_PERIOD = 8;

    // Register offsets
    localparam [5:0] FPGA_REV_REG   = 6'h00;
    localparam [5:0] FIFO_RST_REG   = 6'h04;
    localparam [5:0] WR_DATA_REG    = 6'h08;
    localparam [5:0] RD_REQ_REG     = 6'h0C;
    localparam [5:0] RD_DATA_REG    = 6'h10;
    localparam [5:0] STATUS_REG     = 6'h14;
    localparam [5:0] DATA_COUNT_REG = 6'h18;
    localparam [5:0] CONFIG_REG     = 6'h1C;
    localparam [5:0] THRESHOLD_REG  = 6'h20;
    
    integer i;

    always #(CLK_PERIOD / 2) clk = ~clk;

    sc_fifo_axi_v1_0_S00_AXI DUT
        (
            .S_AXI_ACLK(clk),
            .S_AXI_ARESETN(rst_n),

            .S_AXI_AWADDR(awaddr),
            .S_AXI_AWPROT(awprot),
            .S_AXI_AWVALID(awvalid),
            .S_AXI_AWREADY(awready),

            .S_AXI_WDATA(wdata),
            .S_AXI_WSTRB(wstrb),
            .S_AXI_WVALID(wvalid),
            .S_AXI_WREADY(wready),

            .S_AXI_BRESP(bresp),
            .S_AXI_BVALID(bvalid),
            .S_AXI_BREADY(bready),

            .S_AXI_ARADDR(araddr),
            .S_AXI_ARPROT(arprot),
            .S_AXI_ARVALID(arvalid),
            .S_AXI_ARREADY(arready),

            .S_AXI_RDATA(rdata),
            .S_AXI_RRESP(rresp),
            .S_AXI_RVALID(rvalid),
            .S_AXI_RREADY(rready)
        );

    // Write one 32-bit value to an AXI register.
    task automatic axi_write
        (
            input logic [5:0] address,
            input logic [31:0] data
        );
        begin
            @(negedge clk);
            awaddr = address;
            wdata = data;
            wstrb = 4'b1111;
            awvalid = 1'b1;
            wvalid = 1'b1;
            bready = 1'b1;

            // Wait until both address and data are accepted.
            do
                begin
                    @(posedge clk);
                end
            while (!(awready && wready));

            @(negedge clk);
            awvalid = 1'b0;
            wvalid = 1'b0;

            // Wait for the write response.
            do
                begin
                    @(posedge clk);
                end
            while (!bvalid);

            if (bresp != 2'b00)
                begin
                    $fatal(1, "AXI write response error");
                end

            @(negedge clk);
            bready = 1'b0;
        end
    endtask

    // Read one 32-bit value from an AXI register.
    task automatic axi_read
        (
            input logic [5:0] address,
            output logic [31:0] data
        );
        begin
            @(negedge clk);
            araddr = address;
            arvalid = 1'b1;
            rready = 1'b1;

            // Wait until the read address is accepted.
            do
                begin
                    @(posedge clk);
                end
            while (!arready);

            @(negedge clk);
            arvalid = 1'b0;

            // Wait for the read data.
            do
                begin
                    @(posedge clk);
                end
            while (!rvalid);

            if (rresp != 2'b00)
                begin
                    $fatal(1, "AXI read response error");
                end

            data = rdata;

            @(negedge clk);
            rready = 1'b0;
        end
    endtask

    // Compare a read value with the expected value.
    task automatic check_value
        (
            input logic [31:0] actual,
            input logic [31:0] expected
        );
        begin
            if (actual !== expected)
                begin
                    $fatal(1, "FAIL: Expected %h, received %h", expected, actual);
                end
            else
                begin
                    $display("PASS: Received %h", actual);
                end
        end
    endtask

    initial
        begin
            // Hold reset for several clock cycles.
            repeat (4) @(negedge clk);
            rst_n = 1'b1;

            // Check the initial register values.
            axi_read(FPGA_REV_REG, read_value);
            check_value(read_value, 32'h5200_0004);

            axi_read(STATUS_REG, read_value);
            check_value(read_value, 32'h0000_0005);

            axi_read(DATA_COUNT_REG, read_value);
            check_value(read_value, 32'h0000_0000);

            axi_read(CONFIG_REG, read_value);
            check_value(read_value, 32'h0100_2010);

            axi_read(THRESHOLD_REG, read_value);
            check_value(read_value, 32'h001F_0001);

            // Write two values to the FIFO.
            axi_write(WR_DATA_REG, 32'h0000_1234);
            axi_write(WR_DATA_REG, 32'h0000_ABCD);

            axi_read(DATA_COUNT_REG, read_value);
            check_value(read_value, 32'd2);

            // Request the first value.
            axi_write(RD_REQ_REG, 32'd1);

            // Allow the registered FIFO output to arrive.
            repeat (4) @(negedge clk);

            axi_read(STATUS_REG, read_value);

            if (read_value[4] !== 1'b1)
                begin
                    $fatal(1, "FAIL: FIFO read data is not valid");
                end

            axi_read(RD_DATA_REG, read_value);
            check_value(read_value, 32'h0000_1234);

            // Request the second value.
            axi_write(RD_REQ_REG, 32'd1);
            repeat (4) @(negedge clk);

            axi_read(RD_DATA_REG, read_value);
            check_value(read_value, 32'h0000_ABCD);

            // FIFO should now be empty.
            axi_read(DATA_COUNT_REG, read_value);
            check_value(read_value, 32'd0);

            // Check software reset.
            axi_write(WR_DATA_REG, 32'h0000_5678);
            axi_write(FIFO_RST_REG, 32'd1);

            axi_read(STATUS_REG, read_value);
            check_value(read_value, 32'h0000_0005);

            axi_read(DATA_COUNT_REG, read_value);
            check_value(read_value, 32'd0);

            // Attempt to read from an empty FIFO.
            axi_write(RD_REQ_REG, 32'd1);
            repeat (4) @(negedge clk);

            axi_read(STATUS_REG, read_value);
            check_value(read_value, 32'h0000_0005);

            axi_read(DATA_COUNT_REG, read_value);
            check_value(read_value, 32'd0);

            // Write-only registers must read as zero.
            axi_read(FIFO_RST_REG, read_value);
            check_value(read_value, 32'd0);

            axi_read(WR_DATA_REG, read_value);
            check_value(read_value, 32'd0);

            axi_read(RD_REQ_REG, read_value);
            check_value(read_value, 32'd0);

            // A write to a read-only register must have no effect.
            axi_write(FPGA_REV_REG, 32'hFFFF_FFFF);
            axi_read(FPGA_REV_REG, read_value);
            check_value(read_value, 32'h5200_0004);

            // Fill all 32 FIFO locations.
            for (i = 0; i < 32; i = i + 1)
                begin
                    axi_write(WR_DATA_REG, i);
                end

            axi_read(DATA_COUNT_REG, read_value);
            check_value(read_value, 32'd32);

            // Full and almost-full should both be asserted.
            axi_read(STATUS_REG, read_value);
            check_value(read_value, 32'h0000_000A);

            // Attempt an extra write while the FIFO is full.
            axi_write(WR_DATA_REG, 32'h0000_DEAD);

            // The count must remain at 32.
            axi_read(DATA_COUNT_REG, read_value);
            check_value(read_value, 32'd32);

            // Read all 32 words and check their order.
            for (i = 0; i < 32; i = i + 1)
                begin
                    axi_write(RD_REQ_REG, 32'd1);

                    // Allow time for the FIFO read to complete.
                    repeat (4) @(negedge clk);

                    axi_read(STATUS_REG, read_value);

                    if (read_value[4] !== 1'b1)
                        begin
                            $fatal(1, "FAIL: Read data not valid for entry %0d", i);
                        end

                    axi_read(RD_DATA_REG, read_value);
                    check_value(read_value, i);
                end

            // All 32 words should now be removed.
            axi_read(DATA_COUNT_REG, read_value);
            check_value(read_value, 32'd0);

            // Reset the FIFO after the full test.
            axi_write(FIFO_RST_REG, 32'd1);

            axi_read(STATUS_REG, read_value);
            check_value(read_value, 32'h0000_0005);

            axi_read(DATA_COUNT_REG, read_value);
            check_value(read_value, 32'd0);
            
            $display("PASS: AXI FIFO tests completed.");
            
            $finish;
        end

    // Stop the simulation if an AXI transaction gets stuck.
    initial
        begin
            #100000;
            $fatal(1, "FAIL: Simulation timed out");
        end

endmodule
