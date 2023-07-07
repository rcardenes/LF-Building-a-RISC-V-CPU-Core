#include <iostream>
#include <iomanip>
#include <verilated.h>
#include <verilated_vcd_c.h>
#include "Vtop.h"
#include "Vtop_top.h"
#include "Vtop_core.h"
#include "Vtop_regfile.h"

const auto RESET_CYCLES = 2;
const auto MAX_CYCLES = 100;
const auto FINAL_PC = 0x150;

const char* test_names[] = {
	"ANDI",   //x5
	"ORI",    //x6
	"ADDI",   //x7
	"SLLI",   //x8
	"SRLI",   //x9
	"AND",    //x10
	"OR",     //x11
	"XOR",    //x12
	"ADD",    //x13
	"SUB",    //x14
	"SLL",    //x15
	"SRL",    //x16
	"SLTU",   //x17
	"SLTIU",  //x18
	"LUI",    //x19
	"SRAI",   //x20
	"SLT",    //x21
	"SLTI",   //x22
	"SRA",    //x23
	"AUIPC",  //x24
	"JAL",    //x25
	"JALR",   //x26
	"SW/LW/LH/LB/LHU/LBU",  //x27
	"SH",	  //x28
	"SB"	  //x29
};

class Model {
	int sim_time;
	int after_reset_cycles;
	VerilatedContext *contextp;
	Vtop* top;
	VerilatedVcdC* tracer;

public:
	Model(int, char**);
	virtual ~Model();
	void tick();
	void eval();
	void advance(bool verbose=false);
	void reset();
	bool done() const;
	bool test_passed(bool print_failed=false) const;
	void dump_regs() const;
};

Model::Model(int argc, char** argv)
	: sim_time{0},
	  after_reset_cycles{0}
{
	contextp = new VerilatedContext;
	contextp->commandArgs(argc, argv);
	top = new Vtop{contextp};

	Verilated::traceEverOn(true);
	tracer = new VerilatedVcdC;
	top->trace(tracer, 10);
	tracer->open("waveform.vcd");
	top->clock = 0;
}

Model::~Model() {
	top->final();

	delete tracer;
	delete top;
	delete contextp;
}

bool
Model::done() const {
	return (after_reset_cycles >= MAX_CYCLES) || test_passed();
}

bool
Model::test_passed(bool print_failed) const {
	static int cycles_at_target = 0;
	Vtop_core* core = top->top->c0;
	Vtop_regfile* rf = core->rf;

	// The last instruction is a JAL x0 0, which puts the program on an infinite loop
	// This is part of the test. If JAL doesn't work properly, this won't happen
	if ((core->pc) == FINAL_PC) {
		cycles_at_target++;
	}

	bool all_good = true;
	/* We're testing x5-x29, but the regfile implementation skips
	 * r0, so indices to be tested are 4-27
	 */
	for (int i = 4; i < 29; i++) {
		if (rf->file[i] != 1) {
			all_good = false;
			if (print_failed) {
				std::cerr << "Failed: " << test_names[i - 4] << '\n';
			}
		}
	}

	return all_good && (cycles_at_target > 2);
}

void
Model::tick() {
	sim_time++;
	top->clock = !top->clock;
	contextp->timeInc(1);
	if (!top->clock)
		after_reset_cycles++;
}

void
Model::eval() {
	top->eval();
	tracer->dump(contextp->time());
}

void
Model::advance(bool verbose) {
	tick();
	eval();
	if (verbose && (after_reset_cycles > 0) && ((after_reset_cycles % 10) == 0)) {
		std::cerr << "Cycles: " << after_reset_cycles
			<< "\n--------\n";
		dump_regs();
	}
}

void
Model::reset() {
	top->reset = 1;

	if (top->clock) {
		advance();
	}

	int cycles = 0;
	while (cycles < RESET_CYCLES) {
		advance();
		if (!top->clock)
			cycles++;
	}

	top->reset = 0;
	after_reset_cycles = 0;
}

void
Model::dump_regs() const {
	const Vtop_core* c0 = top->top->c0;

	std::cerr << "Register  PC: "
		  << std::setw(8) << (c0->pc >> 2)
		  << '\n';
	for (int i = 0; i < 31; i++) {
		std::cerr << "Register x" << std::setw(2) << std::setfill('0') << (i + 1) << ": "
			  << std::hex << std::setw(8) << std::setfill('0')
			  << c0->rf->file[i]
			  << std::dec
			  << '\n';
	}
}

int main(int argc, char **argv) {
	Model model{argc, argv};

	model.reset();
	while (!model.done()) {
		model.advance();
	}

	if (!model.test_passed(true)) {
		model.dump_regs();
	}

	return 0;
}
