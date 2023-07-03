ADDI x1 x0 'b10101           ; An operand value of 21.                                             01
ADDI x2 x0 'b111             ; An operand value of 7.                                              02
ADDI x3 x0 'b111111111100    ; An operand value of -4.                                             03
     ; Execute one of each instruction, XORing subtracting (via ADDI) the expected value.
     ; ANDI:
ANDI x5 x1 'b1011100                                                                       ;       04
XORI x5 x5 'b10101                                                                         ;       05
     ; ORI:
ORI x6 x1 'b1011100                                                                        ;       06
XORI x6 x6 'b1011100                                                                       ;       07
     ; ADDI:
ADDI x7 x1 'b111                                                                           ;       08
XORI x7 x7 'b11101                                                                         ;       09
     ; ADDI:
SLLI x8 x1 'b110                                                                           ;       10
XORI x8 x8 'b10101000001                                                                   ;       11
     ; SLLI:
SRLI x9 x1 'b10                                                                            ;       12
XORI x9 x9 'b100                                                                           ;       13
     ; AND:
AND x10 x1 x2                                                                              ;       14
XORI x10 x10 'b100                                                                         ;       15
     ; OR:
OR x11 x1 x2                                                                               ;       16
XORI x11 x11 'b10110                                                                       ;       17
     ; XOR:
XOR x12 x1 x2                                                                              ;       18
XORI x12 x12 'b10011                                                                       ;       19
     ; ADD:
ADD x13 x1 x2                                                                              ;       20
XORI x13 x13 'b11101                                                                       ;       21
     ; SUB:
SUB x14 x1 x2                                                                              ;       22
XORI x14 x14 'b1111                                                                        ;       23
     ; SLL:
SLL x15 x2 x2                                                                              ;       24
XORI x15 x15 'b1110000001                                                                  ;       25
     ; SRL:
SRL x16 x1 x2                                                                              ;       26
XORI x16 x16 1                                                                             ;       27
     ; SLTU:
SLTU x17 x2 x1                                                                             ;       28
XORI x17 x17 0                                                                             ;       29
     ; SLTIU:
SLTIU x18 x2 'b10101                                                                       ;       30
XORI x18 x18 0                                                                             ;       31
     ; LUI:
LUI x19 0                                                                                  ;       32
XORI x19 x19 1                                                                             ;       33
     ; SRAI:
SRAI x20 x3 1                                                                              ;       34
XORI x20 x20 'b111111111111                                                                ;       35
     ; SLT:
SLT x21 x3 x1                                                                              ;       36
XORI x21 x21 0                                                                             ;       37
     ; SLTI:
SLTI x22 x3 1                                                                              ;       38
XORI x22 x22 0                                                                             ;       39
     ; SRA:
SRA x23 x1 x2                                                                              ;       40
XORI x23 x23 1                                                                             ;       41
     ; AUIPC:
AUIPC x4 'b100                                                                             ;       42
SRLI x24 x4 'b111                                                                          ;       43
XORI x24 x24 'b10000000                                                                    ;       44
     ; JAL:
JAL x25 'b10     ; x25 = PC of next instr                                                  ;       45
AUIPC x4 0     ; x4 = PC                                                                   ;       46
XOR x25 x25 x4  ; AUIPC and JAR results are the same.                                      ;       47
XORI x25 x25 1                                                                             ;       48
     ; JALR:
JALR x26 x4 'b10000                                                                        ;       49
SUB x26 x26 x4        ; JALR PC+4 - AUIPC PC                                               ;       50
ADDI x26 x26 'b111111110001  ; - 4 instrs + 1                                              ;       51
     ; SW & LW:
SW x2 x1 1                                                                                 ;       52
LW x27 x2 1                                                                                ;       53
XORI x27 x27 'b10100                                                                       ;       54
     ; Write 1 to remaining registers prior to x30 just to avoid concern.
ADDI x28 x0 1                                                                              ;       55
ADDI x29 x0 1                                                                              ;       56
     ; Terminate with success condition (regardless of correctness of register values:
ADDI x30 x0 1                                                                              ;       57
     ; Done. Jump to itself (infinite loop). (Up to 20-bit signed immediate plus implicit 0 bit (unlike JALR) provides byte address; last immediate bit should also be 0)
JAL x0 0                                                                                   ;       58
