SRCS=top.sv core.sv rwmemory.sv regfile.sv
TESTMOD=top
TESTB=tb_riscv.cpp
TESTPROG=asm/test.asm
HEXDIR=hex
TESTHEX=${HEXDIR}/program.hex
AS=./assembler.py

all:

.PHONY: sim
sim: waveform.vcd

.PHONY: build
build: obj_dir/V$(TESTMOD)

sim: waveform.vcd
waveform.vcd: obj_dir/V$(TESTMOD) ${TESTHEX}
	obj_dir/V$(TESTMOD)

.PHONY: ${HEXDIR}
${HEXDIR}:
	@mkdir -p ${HEXDIR}

${TESTHEX}: ${HEXDIR} ${TESTPROG}
	${AS} ${TESTPROG} > ${TESTHEX}

obj_dir/V$(TESTMOD): .stamp.verilate
	make -C obj_dir -f V$(TESTMOD).mk V$(TESTMOD)

.stamp.verilate: $(SRCS) $(TESTB)
	verilator -Wall --trace -cc $(SRCS) --exe $(TESTB)
	@touch .stamp.verilate

.PHONY: clean
clean:
	rm -rf obj_dir
	rm -f waveform.vcd
