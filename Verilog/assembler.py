#!/usr/bin/env python3

"""
Usage:
    assembler [-h] [-b] SOURCE

Help:
    -h         This help message
    -b         Binary output (default, hex)

    SOURCE     Source code, RISC-V assembly
"""

import os
import sys
from collections import namedtuple
from docopt import docopt

# OPCODE
LOAD   = 0b0000011
OP_IMM = 0b0010011
AUIPC  = 0b0010111
STORE  = 0b0100011
OP     = 0b0110011
LUI    = 0b0110111
BRANCH = 0b1100011
OP2IMM = 0b1100111
JAL    = 0b1101111

# FUNCT3
ADDI        = 0b000
SLLI        = 0b001
SLTI        = 0b010
SLTIU       = 0b011
XORI        = 0b100
SRLI = SRAI = 0b101
ORI         = 0b110
ANDI        = 0b111

ADD = SUB = 0b000
SLL       = 0b001
SLT       = 0b010
SLTU      = 0b011
XOR       = 0b100
SRL = SRA = 0b101
OR        = 0b110
AND       = 0b111
JALR      = 0b000

BEQ       = 0b000
BNE       = 0b001
BLT       = 0b100
BLTU      = 0b110
BGE       = 0b101
BGEU      = 0b111

LW  = 0b010
LH  = 0b001
LHU = 0b101
LB  = 0b000
LBU = 0b100

SW  = 0b010
SH  = 0b001
SB  = 0b000

InstrInfo = namedtuple('InstrInfo', 'opcode funct3 funct7 nopers sign_extended', defaults=(True,))
instr = {
        'addi':  InstrInfo(OP_IMM, ADDI, None, 3),
        'slti':  InstrInfo(OP_IMM, SLTI, None, 3),
        'sltiu': InstrInfo(OP_IMM, SLTIU, None, 3),
        'andi':  InstrInfo(OP_IMM, ANDI, None, 3),
        'ori':   InstrInfo(OP_IMM, ORI, None, 3),
        'xori':  InstrInfo(OP_IMM, XORI, None, 3),
        'slli':  InstrInfo(OP_IMM, SLLI, 0b0000000, 3),
        'srli':  InstrInfo(OP_IMM, SRLI, 0b0000000, 3),
        'srai':  InstrInfo(OP_IMM, SRAI, 0b0100000, 3),
        'lui':   InstrInfo(LUI, None, None, 2),
        'auipc': InstrInfo(AUIPC, None, None, 2),
        'add':   InstrInfo(OP, ADD, 0b0000000, 3),
        'slt':   InstrInfo(OP, SLT, 0b0000000, 3),
        'sltu':  InstrInfo(OP, SLTU, 0b0000000, 3),
        'and':   InstrInfo(OP, AND, 0b0000000, 3),
        'or':    InstrInfo(OP, OR,  0b0000000, 3),
        'xor':   InstrInfo(OP, XOR, 0b0000000, 3),
        'sll':   InstrInfo(OP, SLL, 0b0000000, 3),
        'srl':   InstrInfo(OP, SRL, 0b0000000, 3),
        'sub':   InstrInfo(OP, SUB, 0b0100000, 3),
        'sra':   InstrInfo(OP, SRA, 0b0100000, 3),

        'jal':   InstrInfo(JAL, None, None, 2),
        'jalr':  InstrInfo(OP2IMM, JALR, None, 3),

        'beq':   InstrInfo(BRANCH, BEQ, None, 3),
        'bne':   InstrInfo(BRANCH, BNE, None, 3),
        'blt':   InstrInfo(BRANCH, BLT, None, 3),
        'bltu':  InstrInfo(BRANCH, BLTU, None, 3),
        'bge':   InstrInfo(BRANCH, BGE, None, 3),
        'bgeu':  InstrInfo(BRANCH, BGEU, None, 3),

        'lw':    InstrInfo(LOAD, LW, None, 3),
        'lh':    InstrInfo(LOAD, LH, None, 3),
        'lhu':   InstrInfo(LOAD, LHU, None, 3),
        'lb':    InstrInfo(LOAD, LB, None, 3),
        'lbu':   InstrInfo(LOAD, LBU, None, 3),
        'sw':    InstrInfo(STORE, SW, None, 3),
        'sh':    InstrInfo(STORE, SH, None, 3),
        'sb':    InstrInfo(STORE, SB, None, 3),

#        'fence': (???),
#        'ecall': (i_type),    # System instructions
#        'ebreak':(i_type),

        }

pseudo_instrs = {'nop'}

class Parser:
    def __init__(self, xlen=32):
        self.xlen = xlen
        self.lineno = 0
        self.lim_max = (2**xlen - 1)
        self.lim_min = -2**(xlen - 1)

    def new_line(self):
        self.lineno += 1

    def print_error(self, message, target=sys.stderr):
        print(f"At line {self.lineno}: {message}", file=target)

    def translate_imm(self, text):
        if text.startswith("'b"):
            binary = text[2:]
            if not binary:
                raise ValueError(f"Empty binary value")
            elif len(binary) > self.xlen:
                raise ValueError(f"Literal '{binary}' is out of bounds for XLEN={self.xlen}")
            return int(binary, 2)
        elif text.isdigit():
            val = int(text)
            if val < self.lim_min or val > self.lim_max:
                raise ValueError(f"Literal '{val}' is out of bounds for XLEN={self.xlen}")
            return int(text)
        else:
            return text

    def reg_index(self, text):
        if not text.startswith('x') or len(text) == 1:
            raise ValueError(f"Expected record instead of '{text}'")
        try:
            index = int(text[1:])
        except ValueError:
            raise ValueError(f"Not a valid record index '{text}'")
        if not (0 <= index < self.xlen):
            raise ValueError(f"Index out of bounds for '{text}'")
        return index

def translate_pseudo(op, *rest):
    if op in pseudo_instrs:
        if op == 'nop':
            if len(rest) != 0:
                raise RuntimeError("'nop' takes no arguments")
            op = 'addi'
            rest = ('x0', 'x0', '0')
    return op, rest

# R-Type  [       funct7        |      rs2      |rs1| funct3 |       rd       | opcode ]
#                     a                 b         c      d            f           g
# I-Type  [              imm[11:0]              |rs1| funct3 |       rd       | opcode ]
#  - Load       offset[11:0]
# S-Type: [    offset[11:5]     |      rs2      |rs1| funct3 |   offset[4:0]  | opcode ]
# B-Type: [ imm[12] | imm[10:5] |      rs2      |rs1| funct3 |imm[4:1]|imm[11]| opcode ]
# U-Type: [                    imm[31:12]                    |       rd       | opcode ]
# J-Type: [ imm[20] | imm[10:1]    | imm[11] | imm[19:12] |       rd       | opcode ]

#   Notes:
#     * In U-Type the provided immediate is actually (>> 12)
#     * In both B and J types the provided immediate is actually (>> 1)
#       (the immediates encode multiples of 2)

def encode(parser, info, *opers):
    # Obtain the different fields as if we were working on an R-Type instruction

    # Encode 'rd'
    if info.opcode == STORE:
        rd = opers[2] & 0x1F
    elif info.opcode == BRANCH:
        rd = ((opers[2] & 0xF) << 1) | ((opers[2] >> 10) & 1)
    else:
        rd = parser.reg_index(opers[0])

    funct3 = info.funct3
    op1 = opers[1]
    if info.opcode in {LUI, AUIPC}:
        funct3 = op1 & 0x7
        rs1 = (op1 >> 3) & 0x1F
        rs2 = (op1 >> 8) & 0x1F
    elif info.opcode == JAL:
        funct3 = (op1 >> 11) & 0x7
        rs1 = (op1 >> 3) & 0x1F
        rs2 = ((op1 & 0xF) << 1) | ((op1 >> 10) & 1)
    elif info.opcode in {STORE, BRANCH}:
        rs1 = parser.reg_index(opers[0])
        rs2 = parser.reg_index(op1)
    else:
        rs1 = parser.reg_index(op1)
        if info.opcode == OP:
            rs2 = parser.reg_index(opers[2])
        else: # Immediate/Load
            rs2 = opers[2] & 0x1F

    # The default covers both R-Type instructions, and the few
    # I-type ones that have a fixed "funct7"
    funct7 = info.funct7
    if info.opcode == JAL:
        funct7 = ((op1 >> 12) & 0x40) | ((op1 >> 4) & 0x3F)
    elif info.opcode in {LUI, AUIPC}:
        funct7 = op1 >> 13
    elif info.opcode == BRANCH:
        funct7 = ((op1 >> 5) & 0x40) | ((op1 >> 4) & 0x3F)
    # The following overs I-Type that puts the upper half of imm under funct7
    elif info.opcode == STORE or funct7 is None:
        funct7 = opers[2] >> 5
    else:
        if info.opcode not in {OP, OP_IMM}:
            # Shouldn't happen
            raise RuntimeError("Unknown instruction type encoding funct7!")

    return ((funct7 << 25) |
            (rs2    << 20) |
            (rs1    << 15) |
            (funct3 << 12) |
            (rd     <<  7) |
             info.opcode   )

def asmcomp(stream, dest, format_as_binary=False):
    if format_as_binary:
        to_text = lambda num: f"{num:032b}"
    else:
        to_text = lambda num: f"{num:08x}"

    parser = Parser()
    for line in stream:
        parser.new_line()
        sline = line.partition(';')[0].strip().lower()
        if not sline:
            continue
        op, rest = translate_pseudo(*sline.split())
        try:
            info = instr[op]
        except KeyError:
            parser.print_error(f"Unknown instruction '{op}'")
            sys.exit(-1)
        opers = [parser.translate_imm(oper) for oper in rest]
        if len(opers) != info.nopers:
            parser.print_error(f"Wrong number of operands for '{op}'")
        try:
            encoded = encode(parser, info, *opers)
            print(to_text(encoded), "      //", sline, file=dest)
        except (RuntimeError, ValueError) as ex:
            parser.print_error(str(ex))
            sys.exit(-1)

def main():
    args = docopt(__doc__, argv=sys.argv[1:])
    src = args['SOURCE']
    asbin = args['-b']

    if not os.access(src, os.R_OK):
        print(f"Can't access file: {src}", file=sys.stderr)
        sys.exit(-1)

    with open(src) as source:
        asmcomp(source, sys.stdout, asbin)

if __name__ == "__main__":
    main()
