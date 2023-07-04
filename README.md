RV32I minimal implementation
============================

This is a RISC-V basic core implementation following LF's course, which is centered around the MakerChip tool (TL-Verilog). It describes a 1-cycle per instruction, no I/O core.

Not a hugely useful one, but it serves as an introduction to the architecture.

Contents:

* The original TL-Verilog implementation I wrote following the course
* A pure SystemVerilog reimplementation, includes:
  * An assembler to translate the test program to a loadable hex file
  * A test bench to automate the testing with Verilator

Future plans:

* Program a few other pseudo-instructions
* Extend the rudimentary Load/Store instructions to cover more than just LW/SW
* Extend the test to cover branching instructions
* Choose a target FPGA, perform a timing analysis, see if the design needs to be tweaked to run still as monocycle.
* Extend the design to cover RV64I
* Implement the M extension
* Implement the F extension
