#include <verilated.h>
#include <verilated_vcd_c.h>
#include "Vtop.h"

int main(int argc, char **argv) {
	VerilatedContext *contextp = new VerilatedContext;
	contextp->commandArgs(argc, argv);

	Vtop* top = new Vtop{contextp};

	bool done = true;
	while (!done) {
		top->eval();
	}

	delete top;
	delete contextp;
	return 0;
}
