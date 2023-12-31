module core(clk, reset, imem_data, imem_addr, dmem_data, dmem_addr, dmem_wen, dmem_width);
/* verilator lint_on WIDTH */
   parameter  XLEN   = 32;
   parameter  NREG   = 32;
   localparam MSB    = XLEN - 1;
   localparam XLEN2  = XLEN * 2;
   localparam MSB2   = XLEN2 - 1;
   localparam XTEN   = XLEN - 32;
   localparam ZERO   = {XLEN{1'b0}};

   input             clk;
   input             reset;
   output            dmem_wen;

   input  [31:0]      imem_data;
   output [MSB:0]     imem_addr;
   inout  [MSB:0]     dmem_data;
   output [MSB:0]     dmem_addr;
   output [2:0]       dmem_width;

   // Register file
   regfile #(.WIDTH(XLEN), .SIZE(NREG))
   rf (
      .clk(clk),
      .reset(reset),
      .wr_en(writing_to_reg),
      .wr_index(rd),
      .wr_data(result_mx),
      .rd1_en(rs1_valid),
      .rd1_index(rs1),
      .rd1_data(src1_value),
      .rd2_en(rs2_valid),
      .rd2_index(rs2),
      .rd2_data(src2_value)
   );

   // Internal signals and FF
   logic  [MSB:0]    next_pc;
   logic  [MSB:0]    pc /* verilator public */;
   logic             taken_br;
   logic  [MSB:0]    br_tgt_pc;
   logic  [MSB:0]    jalr_tgt_pc;
   logic  [MSB:0]    src1_value;
   logic  [MSB:0]    src2_value;
   logic             writing_to_reg;
   logic  [MSB:0]    result;
   logic  [MSB:0]    result_mx;
   logic  [31:0]     instr;
   logic  [6:0]      opcode;
   logic  [2:0]      funct3;
   // logic  [6:0]      funct7;
   logic  [4:0]      rd;
   logic  [4:0]      rs1;
   logic  [4:0]      rs2;
   logic  [MSB:0]    imm;
   logic  [10:0]     dec_bits;

   logic             is_r_instr;
   logic             is_i_instr;
   logic             is_s_instr;
   logic             is_b_instr;
   logic             is_u_instr;
   logic             is_j_instr;

   logic             rs1_valid;
   logic             rs2_valid;

   logic             is_lui;
   logic             is_auipc;
   logic             is_jal;
   logic             is_jalr;
   logic             is_beq;
   logic             is_bne;
   logic             is_blt;
   logic             is_bge;
   logic             is_bltu;
   logic             is_bgeu;
   logic             is_addi;
   logic             is_slti;
   logic             is_sltiu;
   logic             is_xori;
   logic             is_ori;
   logic             is_andi;
   logic             is_slli;
   logic             is_srli;
   logic             is_srai;
   logic             is_add;
   logic             is_sub;
   logic             is_sll;
   logic             is_slt;
   logic             is_sltu;
   logic             is_xor;
   logic             is_srl;
   logic             is_sra;
   logic             is_or;
   logic             is_and;
   logic             is_load;
   logic             is_lw;
   logic             is_lh;
   logic             is_lb;
   logic             is_lhu;
   logic             is_lbu;
   logic             is_sw;
   logic             is_sh;
   logic             is_sb;

   logic  [MSB:0]    sltu_rslt;
   logic  [MSB:0]    sltiu_rslt;
   logic  [XLEN2-1:0] sext_src1;
   logic  [XLEN2-1:0] sra_rslt;
   logic  [XLEN2-1:0] srai_rslt;

   // NOTE: Instructions are fixed 32 bit values across RV32I, RV64I, and
   //       RV128I. This would change in case of implementing the C extension
   //       though (Compressed Instructions), which allows for 16 bit
   //       instructions.
   //
   //       Implementing the C extension has more extensive implications,
   //       though, as it changes the alignment for the instruction memory
   //       addressing. If we ever implement it, we'll deal with this.
   assign instr[31:0]     = imem_data[31:0];
   assign dec_bits[10:0]  = {instr[30], funct3, opcode};

   assign next_pc =
      reset ?
         0 :
      is_jal ?
         br_tgt_pc :
      is_jalr ?
         jalr_tgt_pc :
      taken_br ?
         br_tgt_pc :     // We're performing a branch
         pc + 'd4;  // Simple increment


   always_ff @(posedge clk) begin
      pc <= 0;

      if (~reset) begin
         pc <= next_pc;
      end
   end

   // Instruction decoding
   always_comb begin
      opcode[6:0] = instr[6:0];
      rd[4:0]     = instr[11:7];
      funct3[2:0] = instr[14:12];
      rs1[4:0]    = instr[19:15];
      rs2[4:0]    = instr[24:20];

      is_r_instr  = instr[6:2] ==? 5'b011x0 ||
                    instr[6:2] ==  5'b01011 ||
                    instr[6:2] ==  5'b10100;
      is_i_instr  = instr[6:2] ==? 5'b0000x ||
                    instr[6:2] ==? 5'b001x0 ||
                    instr[6:2] ==  5'b11001;
      is_s_instr  = instr[6:2] ==? 5'b0100x;
      is_b_instr  = instr[6:2] ==? 5'b11000;
      is_u_instr  = instr[6:2] ==? 5'b0x101;
      is_j_instr  = instr[6:2] ==  5'b11011;

      is_lui      = dec_bits ==? 11'bx_xxx_0110111;
      is_auipc    = dec_bits ==? 11'bx_xxx_0010111;
      is_jal      = dec_bits ==? 11'bx_xxx_1101111;
      is_jalr     = dec_bits ==? 11'bx_000_1100111;
      is_beq      = dec_bits ==? 11'bx_000_1100011;
      is_bne      = dec_bits ==? 11'bx_001_1100011;
      is_blt      = dec_bits ==? 11'bx_100_1100011;
      is_bge      = dec_bits ==? 11'bx_101_1100011;
      is_bltu     = dec_bits ==? 11'bx_110_1100011;
      is_bgeu     = dec_bits ==? 11'bx_111_1100011;
      is_addi     = dec_bits ==? 11'bx_000_0010011;
      is_load     = dec_bits ==? 11'bx_xxx_0000011;
      is_lw       = dec_bits ==? 11'bx_010_0000011;
      is_lh       = dec_bits ==? 11'bx_001_0000011;
      is_lb       = dec_bits ==? 11'bx_000_0000011;
      is_lhu      = dec_bits ==? 11'bx_101_0000011;
      is_lbu      = dec_bits ==? 11'bx_100_0000011;
      is_sw       = dec_bits ==? 11'bx_010_0100011;
      is_sh       = dec_bits ==? 11'bx_001_0100011;
      is_sb       = dec_bits ==? 11'bx_000_0100011;
      is_slti     = dec_bits ==? 11'bx_010_0010011;
      is_sltiu    = dec_bits ==? 11'bx_011_0010011;
      is_xori     = dec_bits ==? 11'bx_100_0010011;
      is_ori      = dec_bits ==? 11'bx_110_0010011;
      is_andi     = dec_bits ==? 11'bx_111_0010011;
      is_slli     = dec_bits ==  11'b0_001_0010011;
      is_srli     = dec_bits ==  11'b0_101_0010011;
      is_srai     = dec_bits ==  11'b1_101_0010011;
      is_add      = dec_bits ==  11'b0_000_0110011;
      is_sub      = dec_bits ==  11'b1_000_0110011;
      is_sll      = dec_bits ==  11'b0_001_0110011;
      is_slt      = dec_bits ==  11'b0_010_0110011;
      is_sltu     = dec_bits ==  11'b0_011_0110011;
      is_xor      = dec_bits ==  11'b0_100_0110011;
      is_srl      = dec_bits ==  11'b0_101_0110011;
      is_sra      = dec_bits ==  11'b1_101_0110011;
      is_or       = dec_bits ==  11'b0_110_0110011;
      is_and      = dec_bits ==  11'b0_111_0110011;

      rs1_valid   = ~(is_u_instr || is_j_instr);
      rs2_valid   = is_r_instr || is_s_instr || is_b_instr;

      // Most immediate operands need sign extended
      imm[MSB:0]  = is_i_instr ? { {(XLEN-11){instr[31]}}, instr[30:20] } :
                    is_s_instr ? { {(XLEN-11){instr[31]}}, instr[30:25], instr[11:7] } :
                    // Branch immediates are encoded as multiples of 2
                    is_b_instr ? { {(XLEN-12){instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0 } :
                    // U-Type immediates are encoded as multiples of 4096
                    is_u_instr ? { {(XTEN+1){instr[31]}}, instr[30:12], 12'b0 } :
                    // J-Type immediates are encoded as multiples of 2
                    is_j_instr ? { {(XLEN-20){instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0 } :
                       ZERO;  // Default, in case of R-Type instruction
   end

   // ALU

   // SLTU/SLTIU (Set if less than, unsigned) results:
   assign sltu_rslt[MSB:0]  = {ZERO[MSB:1], src1_value < src2_value};
   assign sltiu_rslt[MSB:0] = {ZERO[MSB:1], src1_value < imm};

   // SRA and SRAI (shift right, arithmetic) results:
   // TODO: Modify to make these less sensitive to XLEN
   assign sext_src1[MSB2:0] = { {XLEN{src1_value[MSB]}}, src1_value };
   assign sra_rslt[MSB2:0]  = sext_src1 >> src2_value[4:0];
   assign srai_rslt[MSB2:0] = sext_src1 >> imm[4:0];
   assign result[MSB:0] =
      is_lui   ? {imm[MSB:12], 12'b0} :
      is_auipc ? pc + imm :
      is_jal   ? pc + 'd4 :
      is_jalr  ? pc + 'd4 :
      (is_addi || is_load || is_s_instr)  ?
                 src1_value + imm :
      is_slti  ? ( (src1_value[MSB] == imm[MSB]) ?
                        sltiu_rslt[MSB:0]       :
                        {ZERO[MSB:1], src1_value[MSB]} ) :
      is_sltiu ? sltiu_rslt[MSB:0] :
      is_xori  ? src1_value ^ imm :
      is_ori   ? src1_value | imm :
      is_andi  ? src1_value & imm :
      is_slli  ? src1_value << imm :
      is_srli  ? src1_value >> imm :
      is_srai  ? srai_rslt[MSB:0] :
      is_add   ? src1_value + src2_value :
      is_sub   ? src1_value - src2_value :
      is_sll   ? src1_value << src2_value[4:0] :
      is_slt   ? ( (src1_value[MSB] == src2_value[MSB]) ?
                        sltiu_rslt[MSB:0]       :
                        {ZERO[MSB:1], src1_value[31]} ) :
      is_sltu  ? sltu_rslt[MSB:0] :
      is_srl   ? src1_value >> src2_value[4:0] :
      is_xor   ? src1_value ^ src2_value :
      is_sra   ? sra_rslt[MSB:0] :
      is_or    ? src1_value | src2_value :
      is_and   ? src1_value & src2_value :
                ZERO;
   assign result_mx[MSB:0] =
      is_lw ?
         dmem_data :
      is_lh ?
         { {(XLEN-15){dmem_data[15]}}, dmem_data[14:0] } :
      is_lb ?
         { {(XLEN-7){dmem_data[7]}}, dmem_data[6:0] } :
      is_lhu ?
         { ZERO[MSB:16], dmem_data[15:0] } :
      is_lbu ?
         { ZERO[MSB:8], dmem_data[7:0] } :
         result;
   assign writing_to_reg = ~(is_s_instr || is_b_instr) && (rd != 'b0);

   // Branching
   assign taken_br =
      is_beq ?
         (src1_value == src2_value) :
      is_bne ?
         (src1_value != src2_value) :
      is_blt ?
         ((src1_value < src2_value) ^ (src1_value[MSB] != src2_value[MSB])) :
      is_bge ?
         ((src1_value >= src2_value) ^ (src1_value[MSB] != src2_value[MSB])) :
      is_bltu ?
         (src1_value < src2_value) :
      is_bgeu ?
         (src1_value >= src2_value) :
         0;     // Default value, as we're not dealing with a branching instruction
   assign br_tgt_pc = pc + imm;
   assign jalr_tgt_pc[MSB:0] = src1_value + imm;

   // Other signals
   assign imem_addr = pc;
   assign dmem_addr[MSB:0] = {ZERO[MSB:5], result[4:0]};
   assign dmem_wen = is_s_instr;
   assign dmem_width =
      is_s_instr ?
         funct3 :
         'z;
   assign dmem_data =
      is_sw ?
         src2_value :
      is_sh ?
         { ZERO[MSB:16], src2_value[15:0] } :
      is_sb ?
         { ZERO[MSB:8], src2_value[7:0] } :
         'z;

   wire _unused_ok = &{1'b0,
      sra_rslt[MSB2:XLEN],
      srai_rslt[MSB2:XLEN],
      1'b0};

endmodule
