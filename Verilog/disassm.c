#include <stdio.h>
#include <stdint.h>

enum {
   UNKNOWN = 0,
   LUI,
   AUIPC,
   JAL,
   JALR,
   BEQ,
   BNE,
   BLT,
   BGE,
   BLTU,
   BGEU,
   ADDI,
   LW,
   LH,
   LB,
   LHU,
   LBU,
   SW,
   SH,
   SB,
   SLTI,
   SLTIU,
   XORI,
   ORI,
   ANDI,
   SLLI,
   SRLI,
   SRAI,
   ADD,
   SUB,
   SLL,
   SLT,
   SLTU,
   XOR,
   SRL,
   SRA,
   OR,
   AND,
   _LAST
};

char* names[] = {
   "?red?UNKN",
   "LUI",
   "AUIPC",
   "JAL",
   "JALR",
   "?red?BEG",
   "?red?BNE",
   "?red?BLT",
   "?red?BGE",
   "?red?BLTU",
   "?red?BGEU",
   "ADDI",
   "LW",
   "LH",
   "LB",
   "LHU",
   "LBU",
   "SW",
   "SH",
   "SB",
   "SLTI",
   "SLTIU",
   "XORI",
   "ORI",
   "ANDI",
   "SLLI",
   "SRLI",
   "SRAI",
   "ADD",
   "SUB",
   "SLL",
   "SLT",
   "SLTU",
   "XOR",
   "SRL",
   "SRA",
   "OR",
   "AND"
};

// 3         2         1         0
// 0987654321098765432109876543210
// X ----------------->X    >> 20
//                 FFF->FFF >> 5
//                         OOOOOOO

struct DecBits {
   int bit_30;
   int funct3;
   int opcode;
};

struct DecBits get_dec_bits(uint32_t instr) {
   struct DecBits res = {
      (instr >> 30) & 1,
      (instr >> 12) & 0x7,
       instr        & 0x7F
   };

   /*
   return (
         ((instr >> 20) & 0x400) |   // Bit 30
         ((instr >> 5)  & 0x380) |   // Funct3
         ( instr        & 0x07F)     // Opcode
         );
         */

   return res;
}

int decode(uint32_t instr) {
   struct DecBits dec_bits = get_dec_bits(instr);
   int result = UNKNOWN;

   switch (dec_bits.opcode) {
      case 0x03:
         switch (dec_bits.funct3) {
            case 0: result = LB; break;
            case 1: result = LH; break;
            case 2: result = LW; break;
            case 4: result = LBU; break;
            case 5: result = LHU; break;
            default: result = UNKNOWN; break;
         }
         break;
      case 0x13:
         switch (dec_bits.funct3 & 0x7) {
            case 0: result = ADDI; break;
            case 1: result = dec_bits.bit_30 ? UNKNOWN : SLLI; break;
            case 2: result = SLTI; break;
            case 3: result = SLTIU; break;
            case 4: result = XORI; break;
            case 5: result = dec_bits.bit_30 ? SRAI : SRLI;
            case 6: result = ORI; break;
            case 7: result = ANDI; break;
         }
         break;
      case 0x17:
         result = AUIPC; break;
      case 0x23:
         switch (dec_bits.funct3) {
            case 0: result = SB; break;
            case 1: result = SH; break;
            case 2: result = SW; break;
            default: result = UNKNOWN; break;
         }
         break;
      case 0x33:
         if (dec_bits.bit_30 == 0) {
            switch (dec_bits.funct3 & 0x7) {
               case 0: result = ADD; break;
               case 1: result = SLL; break;
               case 2: result = SLT; break;
               case 3: result = SLTU; break;
               case 4: result = XOR; break;
               case 5: result = SRL; break;
               case 6: result = OR; break;
               case 7: result = AND; break;
            }
         }
         else {
            switch (dec_bits.funct3) {
               case 0: result = SUB; break;
               case 5: result = SRA; break;
               default: result = UNKNOWN; break;
            }
         }
         break;
      case 0x37:
         result = LUI; break;
      case 0x63:
         switch (dec_bits.funct3) {
            case 0: result = BEQ; break;
            case 1: result = BNE; break;
            case 4: result = BLT; break;
            case 5: result = BGE; break;
            case 6: result = BLTU; break;
            case 7: result = BGEU; break;
            default: result = UNKNOWN; break;
         }
         break;
      case 0x67:
         if (dec_bits.funct3 == 0)
            result = JALR;
         break;
      case 0x6F:
         result = JAL; break;
      default:
         result = UNKNOWN; break;
   }

   return result;
}

int main() {
   char bufin[32];

   while (!feof(stdin)) {
      bufin[0] = '\0';
      fscanf(stdin, "%s", bufin);

      if (bufin[0]) {
         uint32_t hx;
         int index;

         sscanf(bufin, "%x", &hx);

         index = decode(hx);
         printf("%s\n", names[index]);
         fflush(stdout);
      }
   }

   return 0;
}
