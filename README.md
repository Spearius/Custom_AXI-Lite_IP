# Custom AXI4-Lite IP: Multiplier, BRAM, and FIFO

## Software Tools & Languages Used

- **Vivado 2023.1**
  - SystemVerilog Hardware Description Language (HDL)
- **Vitis 2023.1**
  - C Programming Language

## Hardware Used

- ZYNQ - Zybo Z7-10 (7010 Development Board)

## Overview

The purpose of this lab was to learn how to create a custom hardware Intellectual Property (IP), connect it to an ARM processor using AXI4-Lite communication, and control the hardware through software integration.

The project has two main parts:

1. **16-bit multiplier with BRAM:** The ARM processor sends operands to a custom multiplier, reads the result, and stores 32 products in Block RAM (BRAM).
2. **Custom AXI4-Lite FIFO:** The ARM processor writes and reads data through a first-in, first-out (FIFO) buffer using memory-mapped registers.

## System Architecture Design & Simulation

Below is the complete Vivado block diagram showing the Zynq Processing System connected to the custom multiplier, BRAM, and FIFO through AXI interfaces.

![Complete Vivado Block Design](images/Complete_Block_Design.png)

## 16-Bit Multiplier and BRAM

In this part, a custom 16-bit multiplier was created and packaged as an AXI4-Lite IP. The ARM processor was then used to calculate and store multiplication results in BRAM.

**How it works:**

1. The Vitis C application writes two 16-bit operands to the multiplier's AXI4-Lite registers.
2. The custom hardware calculates the product.
3. The application reads the product from the multiplier's result register.
4. The application writes the product to BRAM at a 4-byte-spaced address.
5. After 32 operations, the application reads back and prints all 32 stored results.

### Multiplier Simulation Waveform

A SystemVerilog testbench, `tb_multiplier_16_bit.sv`, was created to test the multiplier with inputs from `1 × 1` through `32 × 32`.

Below is the behavioral simulation waveform:

![Multiplier Behavioral Simulation](images/Multiplier_Waveform.png)

The waveform shows the multiplier calculating the expected products for the test inputs.

The Vitis application then performed the 32 multiplication operations and read the results back from BRAM. The serial-terminal output confirmed the expected values, including `1 × 1 = 1` and `32 × 32 = 1024`.

Below are the outputs obtained from running the C application in Vitis.

![Multiplier and BRAM Output, Part 1](images/Multiplier_and_BRAM_Output_1.png)

![Multiplier and BRAM Output, Part 2](images/Multiplier_and_BRAM_Output_2.png)

## Custom AXI4-Lite FIFO

In this part of the lab, the custom FIFO was integrated into an AXI4-Lite IP so the ARM processor could write data, request reads, and check FIFO status through memory-mapped registers.

**FIFO** stands for **First-In, First-Out**. This means the first value written into the buffer is the first value returned when reading.

The FIFO was configured as follows:

- **Data Width:** 16 bits
- **Depth:** 32 entries
- **Read Latency:** 1 clock cycle
- **Almost-Empty Threshold:** 1 entry
- **Almost-Full Threshold:** 31 entries

**How it works:**

1. The processor writes a 16-bit value to `WR_DATA_REG`.
2. The FIFO stores the value if it is not full.
3. The processor can read `DATA_COUNT_REG` and `STATUS_REG` to check FIFO occupancy and flags.
4. The processor requests a read through `RD_REQ_REG`.
5. After the configured read latency, the oldest stored value is available through `RD_DATA_REG`. Software checks the valid status before using it.

### FIFO Write and Read Simulation

The AXI4-Lite FIFO testbench verifies write and read transactions, FIFO data count changes, and correct data ordering.

Below is the behavioral simulation waveform:

![FIFO Read and Write Simulation](images/FIFO_Read_and_Write.png)

The simulation shows data being written to and read from the FIFO.

### FIFO Full-Condition Simulation

Next, the FIFO was filled to its maximum depth of 32 entries. The simulation verified that the FIFO reports the full condition and does not accept an additional write while full.

![FIFO Full Condition](images/FIFO_Full_Condition.png)

The waveform shows the FIFO data count reaching 32 and the full flag becoming asserted.

### Complete FIFO AXI4-Lite Simulation

The AXI4-Lite testbench also covers register accesses, reset behavior, FIFO status, and read/write operations.

![Full FIFO AXI4-Lite Waveform](images/FULL_SC_FIFO_AXI_Waveform.png)

This waveform shows the overall AXI4-Lite FIFO verification sequence.

### FIFO Hardware Verification

Lastly, we integrated the hardware with Vitis and used a C application to test FIFO register access and transfer three values through the custom hardware.

The values were read back in the same order they were written.

Below is the output from the Vitis serial terminal:

![FIFO Serial Terminal Output](images/FIFO_Serial_Terminal_Output.png)

The terminal output confirms the FIFO register values, successful data transfers, and an empty FIFO after all the values were retrieved.

## Conclusion

This lab demonstrated how custom FPGA hardware can communicate with an ARM processor through AXI4-Lite.

The multiplier portion showed how software can send operands to hardware, retrieve a calculated result, and store it in BRAM. The FIFO portion showed how software can write and read buffered data while monitoring status and occupancy.

The project provided hands-on experience with custom IP packaging, AXI4-Lite registers, testbench simulation using SystemVerilog HDL, BRAM implementation, FIFO design, and hardware/software integration using Vitis.
