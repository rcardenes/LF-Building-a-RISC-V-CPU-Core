ADDI x1 x0 'b10101           ; An operand value of 21.
ADDI x2 x0 'b111             ; An operand value of 7.
ADDI x3 x0 'b111111111100    ; An operand value of -4.
     ; Execute one of each instruction, XORing subtracting (via ADDI) the expected value.
     ; ANDI:
ANDI x5 x1 'b1011100
XORI x5 x5 'b10101
     ; ORI:
ORI x6 x1 'b1011100
XORI x6 x6 'b1011100
     ; ADDI:
ADDI x7 x1 'b111
XORI x7 x7 'b11101
     ; ADDI:
SLLI x8 x1 'b110
XORI x8 x8 'b10101000001
     ; SLLI:
SRLI x9 x1 'b10
XORI x9 x9 'b100
     ; AND:
AND x10 x1 x2
XORI x10 x10 'b100
     ; OR:
OR x11 x1 x2
XORI x11 x11 'b10110
     ; XOR:
XOR x12 x1 x2
XORI x12 x12 'b10011
     ; ADD:
ADD x13 x1 x2
XORI x13 x13 'b11101
     ; SUB:
SUB x14 x1 x2
XORI x14 x14 'b1111
     ; SLL:
SLL x15 x2 x2
XORI x15 x15 'b1110000001
     ; SRL:
SRL x16 x1 x2
XORI x16 x16 1
     ; SLTU:
SLTU x17 x2 x1
XORI x17 x17 0
     ; SLTIU:
SLTIU x18 x2 'b10101
XORI x18 x18 0
     ; LUI:
LUI x19 0
XORI x19 x19 1
     ; SRAI:
SRAI x20 x3 1
XORI x20 x20 'b111111111111
     ; SLT:
SLT x21 x3 x1
XORI x21 x21 0
     ; SLTI:
SLTI x22 x3 1
XORI x22 x22 0
     ; SRA:
SRA x23 x1 x2
XORI x23 x23 1
     ; AUIPC:
AUIPC x4 'b100
SRLI x24 x4 'b111
XORI x24 x24 'b10000000
     ; JAL:
JAL x25 'b100    ; x25 = PC of next instr // Jump to the AUIPC
ADDI x25 x25 1 ; This would make the result be off, but we're jumping over
AUIPC x4 0     ; x4 = PC
SUB x25 x4 x25 ; x25 = (PC of AUIPC) - (PC of NOP)
XORI x25 x25 'b101 ; AUIPC and JAR results should be off by 4
     ; JALR:
JALR x26 x4 'b10000
SUB x26 x26 x4        ; JALR PC+4 - AUIPC PC
ADDI x26 x26 'b111111110001  ; - 4 instrs + 1
     ; SW & LW:
ADDI x31 x0 0
SW x2 x3 1
LB x27 x2 1
XORI x27 x27 'b111111111101
MV x29 x27
LBU x27 x2 1
XORI x27 x27 'b11111101
ADD x29 x29 x27
LH x27 x2 1
XORI x27 x27 'b111111111101
ADD x29 x29 x27
LHU x27 x2 1
ADDI x30 x0 -1
SLLI x30 x30 16
XORI x27 x27 'b111111111101
XOR x27 x27 x30
ADD x29 x29 x27
LW x27 x2 1
XORI x27 x27 'b111111111101
ADD x29 x29 x27
XORI x27 x29 'b100
SH x2 x3 2
LW x28 x2 1
XORI x28 x28 'b110011111101
SB x2 x0 3
LW x29 x2 1
ADDI x30 x0 'b1111111100
SLLI x30 x30 14
ORI x30 x30 'b1100000010
NOT x30 x30
XOR x29 x29 x30
     ; Terminate with success condition (regardless of correctness of register values:
ADDI x30 x0 1
     ; Done. Jump to itself (infinite loop). (Up to 20-bit signed immediate plus implicit 0 bit (unlike JALR) provides byte address; last immediate bit should also be 0)
JAL x0 0
