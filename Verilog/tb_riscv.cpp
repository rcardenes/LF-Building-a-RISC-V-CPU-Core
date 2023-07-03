#include <iostream>
#include <verilated.h>
#include <verilated_vcd_c.h>
#include "Vtop.h"

const auto RESET_CYCLES = 2;
const auto RUNNING_TICKS = 10;

class Model {
	int sim_time;
	VerilatedContext *contextp;
	Vtop* top;
	VerilatedVcdC* tracer;

public:
	Model(int, char**);
	virtual ~Model();
	void tick();
	void eval();
	void advance();
	void reset();
	bool done() const;
};

Model::Model(int argc, char** argv)
	: sim_time{0}
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
	return sim_time >= RUNNING_TICKS;
}

void
Model::tick() {
	sim_time++;
	top->clock = !top->clock;
	contextp->timeInc(1);
}

void
Model::eval() {
	top->eval();
	tracer->dump(contextp->time());
}

void
Model::advance() {
	tick();
	eval();
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
}

int main(int argc, char **argv) {
	Model model{argc, argv};

	model.reset();
	while (!model.done()) {
		model.advance();
	}

	return 0;
}
