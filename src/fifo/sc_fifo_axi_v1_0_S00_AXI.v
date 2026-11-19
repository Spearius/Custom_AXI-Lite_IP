
`timescale 1 ns / 1 ps

module sc_fifo_axi_v1_0_S00_AXI #
	(
		// Users to add parameters here

		// User parameters ends
		// Do not modify the parameters beyond this line

		// Width of S_AXI data bus
		parameter integer C_S_AXI_DATA_WIDTH	= 32,
		// Width of S_AXI address bus
		parameter integer C_S_AXI_ADDR_WIDTH	= 6
	)
	(
		// Users to add ports here

		// User ports ends
		// Do not modify the ports beyond this line

		// Global Clock Signal
		input wire  S_AXI_ACLK,
		// Global Reset Signal. This Signal is Active LOW
		input wire  S_AXI_ARESETN,
		// Write address (issued by master, acceped by Slave)
		input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
		// Write channel Protection type. This signal indicates the
    		// privilege and security level of the transaction, and whether
    		// the transaction is a data access or an instruction access.
		input wire [2 : 0] S_AXI_AWPROT,
		// Write address valid. This signal indicates that the master signaling
    		// valid write address and control information.
		input wire  S_AXI_AWVALID,
		// Write address ready. This signal indicates that the slave is ready
    		// to accept an address and associated control signals.
		output wire  S_AXI_AWREADY,
		// Write data (issued by master, acceped by Slave) 
		input wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
		// Write strobes. This signal indicates which byte lanes hold
    		// valid data. There is one write strobe bit for each eight
    		// bits of the write data bus.    
		input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
		// Write valid. This signal indicates that valid write
    		// data and strobes are available.
		input wire  S_AXI_WVALID,
		// Write ready. This signal indicates that the slave
    		// can accept the write data.
		output wire  S_AXI_WREADY,
		// Write response. This signal indicates the status
    		// of the write transaction.
		output wire [1 : 0] S_AXI_BRESP,
		// Write response valid. This signal indicates that the channel
    		// is signaling a valid write response.
		output wire  S_AXI_BVALID,
		// Response ready. This signal indicates that the master
    		// can accept a write response.
		input wire  S_AXI_BREADY,
		// Read address (issued by master, acceped by Slave)
		input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
		// Protection type. This signal indicates the privilege
    		// and security level of the transaction, and whether the
    		// transaction is a data access or an instruction access.
		input wire [2 : 0] S_AXI_ARPROT,
		// Read address valid. This signal indicates that the channel
    		// is signaling valid read address and control information.
		input wire  S_AXI_ARVALID,
		// Read address ready. This signal indicates that the slave is
    		// ready to accept an address and associated control signals.
		output wire  S_AXI_ARREADY,
		// Read data (issued by slave)
		output wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
		// Read response. This signal indicates the status of the
    		// read transfer.
		output wire [1 : 0] S_AXI_RRESP,
		// Read valid. This signal indicates that the channel is
    		// signaling the required read data.
		output wire  S_AXI_RVALID,
		// Read ready. This signal indicates that the master can
    		// accept the read data and response information.
		input wire  S_AXI_RREADY
	);

	// AXI4LITE signals
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_awaddr;
	reg  	axi_awready;
	reg  	axi_wready;
	reg [1 : 0] 	axi_bresp;
	reg  	axi_bvalid;
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_araddr;
	reg  	axi_arready;
	reg [C_S_AXI_DATA_WIDTH-1 : 0] 	axi_rdata;
	reg [1 : 0] 	axi_rresp;
	reg  	axi_rvalid;

	// Example-specific design signals
	// local parameter for addressing 32 bit / 64 bit C_S_AXI_DATA_WIDTH
	// ADDR_LSB is used for addressing 32/64 bit registers/memories
	// ADDR_LSB = 2 for 32 bits (n downto 2)
	// ADDR_LSB = 3 for 64 bits (n downto 3)
	localparam integer ADDR_LSB = (C_S_AXI_DATA_WIDTH/32) + 1;
	localparam integer OPT_MEM_ADDR_BITS = 3;
	//----------------------------------------------
	//-- Signals for user logic register space example
	//------------------------------------------------
	//-- Number of Slave Registers 16
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg0;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg1;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg2;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg3;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg4;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg5;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg6;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg7;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg8;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg9;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg10;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg11;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg12;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg13;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg14;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg15;
	wire	 slv_reg_rden;
	wire	 slv_reg_wren;
	reg [C_S_AXI_DATA_WIDTH-1:0]	 reg_data_out;
	integer	 byte_index;
	reg	 aw_en;

    // FIFO parameters
    localparam integer FIFO_WIDTH = 16;
    localparam integer FIFO_DEPTH = 32;
    localparam integer FIFO_ALMOST_EMPTY_THRESHOLD = 1;
    localparam integer FIFO_ALMOST_FULL_THRESHOLD = 31;
    localparam integer FIFO_READ_LATENCY = 1;

    // Signals connected to the FIFO
    wire fifo_srst;
    reg [FIFO_WIDTH - 1:0] fifo_data_in;
    reg fifo_write_enable;
    reg fifo_read_enable;

    wire [$clog2(FIFO_DEPTH + 1) - 1:0] fifo_data_count;
    wire [FIFO_WIDTH - 1:0] fifo_data_out;
    wire fifo_valid;
    wire fifo_almost_full;
    wire fifo_almost_empty;
    wire fifo_full;
    wire fifo_empty;

    // Captured FIFO output and its valid flag
    reg [FIFO_WIDTH - 1:0] fifo_read_data;
    reg fifo_read_valid;
    
	// I/O Connections assignments

	assign S_AXI_AWREADY	= axi_awready;
	assign S_AXI_WREADY	= axi_wready;
	assign S_AXI_BRESP	= axi_bresp;
	assign S_AXI_BVALID	= axi_bvalid;
	assign S_AXI_ARREADY	= axi_arready;
	assign S_AXI_RDATA	= axi_rdata;
	assign S_AXI_RRESP	= axi_rresp;
	assign S_AXI_RVALID	= axi_rvalid;
	// Implement axi_awready generation
	// axi_awready is asserted for one S_AXI_ACLK clock cycle when both
	// S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_awready is
	// de-asserted when reset is low.

	always @( posedge S_AXI_ACLK )
        begin
          if ( S_AXI_ARESETN == 1'b0 )
            begin
              axi_awready <= 1'b0;
              aw_en <= 1'b1;
            end 
          else
            begin    
              if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
                begin
                  // slave is ready to accept write address when 
                  // there is a valid write address and write data
                  // on the write address and data bus. This design 
                  // expects no outstanding transactions. 
                  axi_awready <= 1'b1;
                  aw_en <= 1'b0;
                end
                else if (S_AXI_BREADY && axi_bvalid)
                    begin
                      aw_en <= 1'b1;
                      axi_awready <= 1'b0;
                    end
              else           
                begin
                  axi_awready <= 1'b0;
                end
            end 
        end       

	// Implement axi_awaddr latching
	// This process is used to latch the address when both 
	// S_AXI_AWVALID and S_AXI_WVALID are valid. 

	always @( posedge S_AXI_ACLK )
        begin
          if ( S_AXI_ARESETN == 1'b0 )
            begin
              axi_awaddr <= 0;
            end 
          else
            begin    
              if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
                begin
                  // Write Address latching 
                  axi_awaddr <= S_AXI_AWADDR;
                end
            end 
        end       

	// Implement axi_wready generation
	// axi_wready is asserted for one S_AXI_ACLK clock cycle when both
	// S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_wready is 
	// de-asserted when reset is low. 

	always @( posedge S_AXI_ACLK )
        begin
          if ( S_AXI_ARESETN == 1'b0 )
            begin
              axi_wready <= 1'b0;
            end 
          else
            begin    
              if (~axi_wready && S_AXI_WVALID && S_AXI_AWVALID && aw_en )
                begin
                  // slave is ready to accept write data when 
                  // there is a valid write address and write data
                  // on the write address and data bus. This design 
                  // expects no outstanding transactions. 
                  axi_wready <= 1'b1;
                end
              else
                begin
                  axi_wready <= 1'b0;
                end
            end 
        end       

	// Implement memory mapped register select and write logic generation
	// The write data is accepted and written to memory mapped registers when
	// axi_awready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted. Write strobes are used to
	// select byte enables of slave registers while writing.
	// These registers are cleared when reset (active low) is applied.
	// Slave register write enable is asserted when valid address and data are available
	// and the slave is ready to accept the write address and write data.
	assign slv_reg_wren = axi_wready && S_AXI_WVALID && axi_awready && S_AXI_AWVALID;

	// Implement write response logic generation
	// The write response and response valid signals are asserted by the slave 
	// when axi_wready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted.  
	// This marks the acceptance of address and indicates the status of 
	// write transaction.

	always @( posedge S_AXI_ACLK )
        begin
          if ( S_AXI_ARESETN == 1'b0 )
            begin
              axi_bvalid  <= 0;
              axi_bresp   <= 2'b0;
            end 
          else
            begin    
              if (axi_awready && S_AXI_AWVALID && ~axi_bvalid && axi_wready && S_AXI_WVALID)
                begin
                  // indicates a valid write response is available
                  axi_bvalid <= 1'b1;
                  axi_bresp  <= 2'b0; // 'OKAY' response 
                end                   // work error responses in future
              else
                begin
                  if (S_AXI_BREADY && axi_bvalid) 
                    //check if bready is asserted while bvalid is high) 
                    //(there is a possibility that bready is always asserted high)   
                    begin
                      axi_bvalid <= 1'b0; 
                    end  
                end
            end
        end   

	// Implement axi_arready generation
	// axi_arready is asserted for one S_AXI_ACLK clock cycle when
	// S_AXI_ARVALID is asserted. axi_awready is 
	// de-asserted when reset (active low) is asserted. 
	// The read address is also latched when S_AXI_ARVALID is 
	// asserted. axi_araddr is reset to zero on reset assertion.

	always @( posedge S_AXI_ACLK )
        begin
          if ( S_AXI_ARESETN == 1'b0 )
            begin
              axi_arready <= 1'b0;
              axi_araddr  <= 32'b0;
            end 
          else
            begin    
              if (~axi_arready && S_AXI_ARVALID && ~axi_rvalid)
                begin
                  // indicates that the slave has acceped the valid read address
                  axi_arready <= 1'b1;
                  // Read address latching
                  axi_araddr  <= S_AXI_ARADDR;
                end
              else
                begin
                  axi_arready <= 1'b0;
                end
            end 
        end       

	// Implement axi_arvalid generation
	// axi_rvalid is asserted for one S_AXI_ACLK clock cycle when both 
	// S_AXI_ARVALID and axi_arready are asserted. The slave registers 
	// data are available on the axi_rdata bus at this instance. The 
	// assertion of axi_rvalid marks the validity of read data on the 
	// bus and axi_rresp indicates the status of read transaction.axi_rvalid 
	// is deasserted on reset (active low). axi_rresp and axi_rdata are 
	// cleared to zero on reset (active low).  
	always @( posedge S_AXI_ACLK )
        begin
          if ( S_AXI_ARESETN == 1'b0 )
            begin
              axi_rvalid <= 0;
              axi_rresp  <= 0;
            end 
          else
            begin    
              if (axi_arready && S_AXI_ARVALID && ~axi_rvalid)
                begin
                  // Valid read data is available at the read data bus
                  axi_rvalid <= 1'b1;
                  axi_rresp  <= 2'b0; // 'OKAY' response
                end   
              else if (axi_rvalid && S_AXI_RREADY)
                begin
                  // Read data is accepted by the master
                  axi_rvalid <= 1'b0;
                end                
            end
        end    

	// Implement memory mapped register select and read logic generation
	// Slave register read enable is asserted when valid address is available
	// and the slave is ready to accept the read address.
	assign slv_reg_rden = axi_arready & S_AXI_ARVALID & ~axi_rvalid;
	    // Select the value returned to the AXI manager.
    always @(*)
        begin
            case (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB])

                // Offset 0x00: FPGA revision
                4'h0:
                    reg_data_out = 32'h5200_0004;

                // Offset 0x10: most recently read FIFO data
                4'h4:
                    reg_data_out = fifo_read_data;

                // Offset 0x14: FIFO status
                4'h5:
                    reg_data_out = {
                        27'b0,
                        fifo_read_valid,
                        fifo_almost_full,
                        fifo_almost_empty,
                        fifo_full,
                        fifo_empty
                    };

                // Offset 0x18: number of words in the FIFO
                4'h6:
                    reg_data_out = fifo_data_count;

                // Offset 0x1C: FIFO configuration
                4'h7:
                    reg_data_out =
                        ((FIFO_READ_LATENCY & 32'hF) << 24) |
                        ((FIFO_DEPTH & 32'hFFFF) << 8) |
                        (FIFO_WIDTH & 32'hFF);

                // Offset 0x20: FIFO thresholds
                4'h8:
                    reg_data_out =
                        ((FIFO_ALMOST_FULL_THRESHOLD & 32'hFFFF) << 16) |
                        (FIFO_ALMOST_EMPTY_THRESHOLD & 32'hFFFF);

                // Write-only and unused offsets read as zero.
                default:
                    reg_data_out = 32'b0;

            endcase
        end

	// Output register or memory read data
	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_rdata  <= 0;
	    end 
	  else
	    begin    
	      // When there is a valid read address (S_AXI_ARVALID) with 
	      // acceptance of read address by the slave (axi_arready), 
	      // output the read dada 
	      if (slv_reg_rden)
	        begin
	          axi_rdata <= reg_data_out;     // register read data
	        end   
	    end
	end    

	// Add user logic here
	
	// Software reset command for the FIFO
    reg fifo_reset_command;

    // Reset when AXI reset is active or software requests a reset.
    assign fifo_srst = (S_AXI_ARESETN == 1'b0) || fifo_reset_command;

    // Generate one-clock FIFO commands from AXI writes.
    always @(posedge S_AXI_ACLK)
        begin
            if (S_AXI_ARESETN == 1'b0)
                begin
                    fifo_reset_command <= 1'b0;
                    fifo_write_enable <= 1'b0;
                    fifo_read_enable <= 1'b0;
                    fifo_data_in <= 0;
                end
            else
                begin
                    // Clear commands unless a new write requests one.
                    fifo_reset_command <= 1'b0;
                    fifo_write_enable <= 1'b0;
                    fifo_read_enable <= 1'b0;

                    if (slv_reg_wren)
                        begin
                            case (axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB])

                                // Offset 0x04: reset the FIFO.
                                4'h1:
                                    begin
                                        if (S_AXI_WSTRB[0] && S_AXI_WDATA[0])
                                            begin
                                                fifo_reset_command <= 1'b1;
                                            end
                                    end

                                // Offset 0x08: write one word to the FIFO.
                                4'h2:
                                    begin
                                        fifo_data_in <= 0;

                                        if (S_AXI_WSTRB[0])
                                            begin
                                                fifo_data_in[7:0] <= S_AXI_WDATA[7:0];
                                            end

                                        if (S_AXI_WSTRB[1])
                                            begin
                                                fifo_data_in[15:8] <= S_AXI_WDATA[15:8];
                                            end

                                        fifo_write_enable <= 1'b1;
                                    end

                                // Offset 0x0C: request one FIFO read.
                                4'h3:
                                    begin
                                        if (S_AXI_WSTRB[0] && S_AXI_WDATA[0])
                                            begin
                                                fifo_read_enable <= 1'b1;
                                            end
                                    end

                            endcase
                        end
                end
        end
        
        always @(posedge S_AXI_ACLK)
            begin
                if (fifo_srst)
                    begin
                        fifo_read_data <= 0;
                        fifo_read_valid <= 1'b0;
                    end
                else if (fifo_read_enable)
                    begin
                        // Clear the previous result's valid flag
                        // when a new read is requested.
                        fifo_read_valid <= 1'b0;
                    end
                else if (fifo_valid)
                    begin
                        // Store the data when the FIFO says it is ready.
                        fifo_read_data <= fifo_data_out;
                        fifo_read_valid <= 1'b1;
                    end
            end
        
    // Create an instance of the FIFO.
    sc_fifo #(
                .WIDTH(FIFO_WIDTH),
                .DEPTH(FIFO_DEPTH),
                .ALMOST_EMPTY_THRESHOLD(FIFO_ALMOST_EMPTY_THRESHOLD),
                .ALMOST_FULL_THRESHOLD(FIFO_ALMOST_FULL_THRESHOLD),
                .READ_LATENCY(FIFO_READ_LATENCY)
             ) fifo_inst
            (
                .clk(S_AXI_ACLK),
                .srst(fifo_srst),
                .data_in(fifo_data_in),
                .write_enable(fifo_write_enable),
                .read_enable(fifo_read_enable),
    
                .data_count(fifo_data_count),
                .data_out(fifo_data_out),
                .valid(fifo_valid),
                .almost_full(fifo_almost_full),
                .almost_empty(fifo_almost_empty),
                .full(fifo_full),
                .empty(fifo_empty)
            );
	// User logic ends

	endmodule
