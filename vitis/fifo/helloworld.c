#include <stdint.h>
#include "platform.h"
#include "xil_printf.h"
#include "xil_io.h"

#define FIFO_BASE_ADDR  0x43C10000

#define FPGA_REV_REG    (FIFO_BASE_ADDR + 0x00)
#define FIFO_RST_REG    (FIFO_BASE_ADDR + 0x04)
#define WR_DATA_REG     (FIFO_BASE_ADDR + 0x08)
#define RD_REQ_REG      (FIFO_BASE_ADDR + 0x0C)
#define RD_DATA_REG     (FIFO_BASE_ADDR + 0x10)
#define STATUS_REG      (FIFO_BASE_ADDR + 0x14)
#define DATA_COUNT_REG  (FIFO_BASE_ADDR + 0x18)
#define CONFIG_REG      (FIFO_BASE_ADDR + 0x1C)
#define THRESHOLD_REG   (FIFO_BASE_ADDR + 0x20)

#define EMPTY_MASK      0x01
#define VALID_MASK      0x10
#define POLL_LIMIT      100000

int main()
{
    uint32_t status;
    uint32_t data;
    int i;
    int timeout;

    init_platform();

    xil_printf("\r\nCuestas, Roberto - AXI FIFO Test\r\n");

    // Reset the FIFO.
    Xil_Out32(FIFO_RST_REG, 1);

    xil_printf("FPGA revision: 0x%08x\r\n",
               Xil_In32(FPGA_REV_REG));

    xil_printf("Configuration: 0x%08x\r\n",
               Xil_In32(CONFIG_REG));

    xil_printf("Thresholds:    0x%08x\r\n",
               Xil_In32(THRESHOLD_REG));

    xil_printf("Initial status: 0x%08x\r\n",
               Xil_In32(STATUS_REG));

    // Write three values to the FIFO.
    xil_printf("\r\nWriting to FIFO:\r\n");

    Xil_Out32(WR_DATA_REG, 0x1234);
    xil_printf("Wrote: 0x1234\r\n");

    Xil_Out32(WR_DATA_REG, 0xABCD);
    xil_printf("Wrote: 0xABCD\r\n");

    Xil_Out32(WR_DATA_REG, 0x5678);
    xil_printf("Wrote: 0x5678\r\n");

    xil_printf("FIFO count: %d\r\n",
               Xil_In32(DATA_COUNT_REG));

    // Read the three values back in order.
    xil_printf("\r\nReading from FIFO:\r\n");

    for (i = 0; i < 3; i = i + 1)
        {
            status = Xil_In32(STATUS_REG);

            if ((status & EMPTY_MASK) != 0)
                {
                    xil_printf("ERROR: FIFO is empty.\r\n");
                    cleanup_platform();
                    return 1;
                }

            // Request one read.
            Xil_Out32(RD_REQ_REG, 1);

            // Wait for the read-data valid flag.
            timeout = 0;

            do
                {
                    status = Xil_In32(STATUS_REG);
                    timeout = timeout + 1;
                }
            while (((status & VALID_MASK) == 0) &&
                   (timeout < POLL_LIMIT));

            if ((status & VALID_MASK) == 0)
                {
                    xil_printf("ERROR: Read timed out.\r\n");
                    cleanup_platform();
                    return 1;
                }

            data = Xil_In32(RD_DATA_REG);

            xil_printf("Read: 0x%04x\r\n", data);
        }

    xil_printf("\r\nFinal count: %d\r\n",
               Xil_In32(DATA_COUNT_REG));

    xil_printf("Final status: 0x%08x\r\n",
               Xil_In32(STATUS_REG));

    xil_printf("FIFO test complete.\r\n");

    cleanup_platform();

    return 0;
}
