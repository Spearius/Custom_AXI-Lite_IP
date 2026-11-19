//#include <stdio.h>
//#include <stdint.h>
//#include "platform.h"
//#include "xil_printf.h"
//#include "xparameters.h"
//#include "xil_io.h"
//
//#define MULT_BASE_ADDR  (0x43C00000)
//#define A_REG_ADDR      (MULT_BASE_ADDR + 0x00)
//#define B_REG_ADDR      (MULT_BASE_ADDR + 0x04)
//#define P_REG_ADDR      (MULT_BASE_ADDR + 0x08)

//int main()
//	{
//		init_platform();
//
//		xil_printf("Start of Multiplier Test\n");
//
//		Xil_Out32(A_REG_ADDR, 8);
//		Xil_Out32(B_REG_ADDR, 8);
//
//		uint32_t a_val = Xil_In32(A_REG_ADDR);
//		uint32_t b_val = Xil_In32(B_REG_ADDR);
//		uint32_t p_val = Xil_In32(P_REG_ADDR);
//
//		xil_printf("A: %d\n", a_val);
//		xil_printf("B: %d\n", b_val);
//		xil_printf("P: %d\n", p_val);
//
//		xil_printf("End of Multiplier Test\n");
//
//		cleanup_platform();
//
//		return 0;
//	}
//

#include <stdint.h>
#include "platform.h"
#include "xil_printf.h"
#include "xil_io.h"
#include "sleep.h"

#define MULT_BASE_ADDR  0x43C00000
#define BRAM_BASE_ADDR  0x40000000

#define A_REG_ADDR      (MULT_BASE_ADDR + 0x00)
#define B_REG_ADDR      (MULT_BASE_ADDR + 0x04)
#define P_REG_ADDR      (MULT_BASE_ADDR + 0x08)

int main()
	{
		int i;
		uint32_t product;

		init_platform();

		xil_printf("ECE 520/L - Custom AXI IP Lab - Roberto Cuestas\r\n");
		xil_printf("Start of Multiplier + BRAM Test\r\n");

		// Multiply numbers 1 through 32 and store each result.
		for (i = 1; i <= 32; i = i + 1)
			{
				Xil_Out32(A_REG_ADDR, i);
				Xil_Out32(B_REG_ADDR, i);

				usleep(1);

				product = Xil_In32(P_REG_ADDR);

				Xil_Out32(BRAM_BASE_ADDR + ((i - 1) * 4), product);

				xil_printf("%d * %d = %d\r\n", i, i, product);
			}

		xil_printf("\r\nProducts stored in BRAM:\r\n");

		// Read and print all 32 stored results.
		for (i = 0; i < 32; i = i + 1)
			{
				product = Xil_In32(BRAM_BASE_ADDR + (i * 4));

				xil_printf("Entry %d: %d\r\n", i, product);
			}

		cleanup_platform();

		return 0;
	}
