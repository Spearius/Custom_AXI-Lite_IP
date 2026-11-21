#include <stdint.h>
#include "platform.h"
#include "xil_printf.h"
#include "xil_io.h"

#define FIFO_BASE_ADDR  0x43C10000					// Starting memory address

#define FPGA_REV_REG (FIFO_BASE_ADDR + 0x00)		// Hardware Revision Number
#define FIFO_RST_REG (FIFO_BASE_ADDR + 0x04)		// Reset Register
#define WR_DATA_REG (FIFO_BASE_ADDR + 0x08)			// Write Data in FIFO
#define RD_REQ_REG (FIFO_BASE_ADDR + 0x0C)			// Request READ from FIFO
#define RD_DATA_REG (FIFO_BASE_ADDR + 0x10)			// Holds data read from FIFO
#define STATUS_REG (FIFO_BASE_ADDR + 0x14)			// FIFO Status Report
#define DATA_COUNT_REG (FIFO_BASE_ADDR + 0x18)		// Report Number of Stored Values
#define CONFIG_REG (FIFO_BASE_ADDR + 0x1C)			// Report FIFO width, depth, and latency
#define THRESHOLD_REG (FIFO_BASE_ADDR + 0x20)		// Report almost empty and almost full limits

#define EMPTY_MASK          0x01		// Bit 0 (00), FIFO is EMPTY
#define FULL_MASK           0x02		// Bit 1 (01), FIFO is FULL
#define ALMOST_EMPTY_MASK   0x04		// Bit 2 (10), FIFO has 1 or less values stored
#define ALMOST_FULL_MASK    0x08		// Bit 3 (11), FIFO has 31 or more values stored
#define VALID_MASK          0x10		// Read Data is invalid

#define FIFO_DEPTH          32			// Max FIFO capacity
#define POLL_LIMIT          100000		// Max Attempts to Read Data


void print_fifo_status()
	{
		uint32_t status = Xil_In32(STATUS_REG);
		xil_printf("FIFO Count: %d\r\n", (int)Xil_In32(DATA_COUNT_REG));
		xil_printf("EMPTY: %d\r\n", (status & EMPTY_MASK) ? 1 : 0);
		xil_printf("FULL: %d\r\n", (status & FULL_MASK) ? 1 : 0);
		xil_printf("ALMOST_EMPTY: %d\r\n", (status & ALMOST_EMPTY_MASK) ? 1 : 0);
		xil_printf("ALMOST_FULL: %d\r\n", (status & ALMOST_FULL_MASK) ? 1 : 0);
		xil_printf("RD_VALID: %d\r\n", (status & VALID_MASK) ? 1 : 0);
	}

int check_fifo_state(uint32_t expected_count, uint32_t expected_flags)
	{
		uint32_t count = Xil_In32(DATA_COUNT_REG);
		uint32_t status = Xil_In32(STATUS_REG);
		uint32_t mask = EMPTY_MASK | FULL_MASK | ALMOST_EMPTY_MASK | ALMOST_FULL_MASK | VALID_MASK;

		if (count != expected_count || (status & mask) != expected_flags)
			{
				xil_printf("ERROR: FIFO state mismatch.\r\n");
				xil_printf("Expected count: %d, actual: %d\r\n", (int)expected_count, (int)count);
				xil_printf("Expected flags: 0x%02x, actual: 0x%02x\r\n", (unsigned int)expected_flags, (unsigned int)(status & mask));

				return 1;
			}

		xil_printf("PASS: FIFO state matches expected values.\r\n");

		return 0;
	}


// MAIN PROGRAM:
int main()
	{
		uint32_t status;
		uint32_t data;
		uint32_t expected;

		int i;
		int timeout;
		int errors = 0;

		init_platform();

		xil_printf("\r\nCuestas, Roberto - AXI FIFO Full Test\r\n");

		// TEST 1: RESET AND EMPTY CONDITION
		xil_printf("\r\nTEST 1: Reset FIFO\r\n");
		Xil_Out32(FIFO_RST_REG, 1);
		xil_printf("FPGA revision: 0x%08x\r\n", Xil_In32(FPGA_REV_REG));
		xil_printf("Configuration: 0x%08x\r\n", Xil_In32(CONFIG_REG));
		xil_printf("Thresholds: 0x%08x\r\n", Xil_In32(THRESHOLD_REG));
		print_fifo_status();
		errors += check_fifo_state(0, EMPTY_MASK | ALMOST_EMPTY_MASK);		// After reset, EMPTY = 1, ALMOST_EMPTY = 1

		// TEST 2: WRITE ONE VALUE
		xil_printf("\r\nTEST 2: Write one value\r\n");
		Xil_Out32(WR_DATA_REG, 0x1234);
		print_fifo_status();
		errors += check_fifo_state(1, ALMOST_EMPTY_MASK);		// ALMOST_EMPTY = 1, EMPTY = 0

		// TEST 3: FILL FIFO TO 31 ENTRIES
		xil_printf("\r\nTEST 3: Almost-full condition\r\n");

		for (i = 1; i < 31; i++)								// Already contains one value, // Add 30 more to reach 31
			{
				status = Xil_In32(STATUS_REG);

				if (status & FULL_MASK)
					{
						xil_printf("ERROR: FIFO full too early.\r\n");
						errors++;

						break;
					}

				Xil_Out32(WR_DATA_REG, (uint32_t)(i + 1));
			}

		print_fifo_status();
		errors += check_fifo_state(31, ALMOST_FULL_MASK);					// At 31 entries, ALMOST_FULL = 1, FULL = 0

		// TEST 4: FILL FIFO TO 32 ENTRIES
		xil_printf("\r\nTEST 4: Full condition\r\n");
		Xil_Out32(WR_DATA_REG, 0x5678);
		print_fifo_status();
		errors += check_fifo_state( 32, FULL_MASK | ALMOST_FULL_MASK);		// At 32 entries, FULL = 1, ALMOST_FULL = 1

		// TEST 5: WRITE WHILE FULL
		xil_printf("\r\nTEST 5: Overflow protection\r\n");
		Xil_Out32(WR_DATA_REG, 0xFFFF);										// Attempt to write an additional value, FIFO should ignore it
		print_fifo_status();
		errors += check_fifo_state(32, FULL_MASK | ALMOST_FULL_MASK);		// Count should remain 32

		// TEST 6: READ ALL 32 VALUES
		xil_printf("\r\nTEST 6: Read FIFO values\r\n");

		for (i = 0; i < FIFO_DEPTH; i++)
			{
				status = Xil_In32(STATUS_REG);

				if (status & EMPTY_MASK)
					{
						xil_printf("ERROR: FIFO empty before read %d.\r\n", i);
						errors++;

						break;
					}

				Xil_Out32(RD_REQ_REG, 1);									// Request one FIFO read
				timeout = 0;												// Wait until the hardware reports valid data

				do
					{
						status = Xil_In32(STATUS_REG);
						timeout++;
					}
					while (((status & VALID_MASK) == 0) && (timeout < POLL_LIMIT));

				if ((status & VALID_MASK) == 0)
					{
						xil_printf("ERROR: Read timeout at %d.\r\n", i);
						errors++;

						break;
					}

				data = Xil_In32(RD_DATA_REG);


				if (i == 0)			// Determine which value should be returned
					{
						expected = 0x1234;
					}
				else if (i == 31)
					{
						expected = 0x5678;
					}
				else
					{
						expected = (uint32_t)(i + 1);
					}

				if (data != expected)
					{
						xil_printf("ERROR: Read %d expected 0x%04x got 0x%04x\r\n", i, (unsigned int)expected, (unsigned int)data);
						errors++;
					}
				else
					{
						xil_printf("PASS: Read %d = 0x%04x\r\n", i, (unsigned int)data);
					}


				if (i == 30)		// At 1 entry, almost-empty must be asserted
					{
						xil_printf("\r\nChecking almost-empty condition:\r\n");
						print_fifo_status();
						errors += check_fifo_state( 1, ALMOST_EMPTY_MASK | VALID_MASK);
					}
			}

		// TEST 7: FINAL EMPTY CONDITION
		xil_printf("\r\nTEST 7: Final empty condition\r\n");
		print_fifo_status();
		errors += check_fifo_state(0, EMPTY_MASK | ALMOST_EMPTY_MASK | VALID_MASK);		// After all reads, EMPTY = 1, ALMOST_EMPTY = 1, RD_VALID = 1

		// TEST 8: RESET CLEARS VALID FLAG
		xil_printf("\r\nTEST 8: Reset clears status\r\n");
		Xil_Out32(FIFO_RST_REG, 1);
		print_fifo_status();
		errors += check_fifo_state(0, EMPTY_MASK | ALMOST_EMPTY_MASK);

		// FINAL TEST RESULT
		if (errors == 0)
			{
				xil_printf("ALL FIFO TESTS PASSED!\r\n");
			}
		else
			{
				xil_printf("FIFO TEST FAILED: %d errors\r\n", errors);
			}

		cleanup_platform();

		return (errors == 0) ? 0 : 1;
	}
