module core(clk, reset, imem_data, imem_addr, dmem_data, dmem_addr, dmem_wen);
/* verilator lint_on WIDTH */
   parameter XLEN = 32;
   parameter NREG = 32;

   input             clk;
   input             reset;
   output            dmem_wen;

   input  [XLEN-1:0]     imem_data;
   output [XLEN-1:0]     imem_addr;
   inout  [XLEN-1:0]     dmem_data;
   output [XLEN-1:0]     dmem_addr;

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
   logic  [XLEN-1:0] next_pc;
   logic  [XLEN-1:0] pc /* verilator public */;
   logic             taken_br;
   logic  [XLEN-1:0] br_tgt_pc;
   logic  [XLEN-1:0] jalr_tgt_pc;
   logic  [XLEN-1:0] src1_value;
   logic  [XLEN-1:0] src2_value;
   logic             writing_to_reg;
   logic  [XLEN-1:0] result;
   logic  [XLEN-1:0] result_mx;
   logic  [XLEN-1:0] instr;
   logic  [6:0]      opcode;
   logic  [2:0]      funct3;
   // logic  [6:0]      funct7;
   logic  [4:0]      rd;
   logic  [4:0]      rs1;
   logic  [4:0]      rs2;
   logic  [XLEN-1:0] imm;
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

   logic  [XLEN-1:0] sltu_rslt;
   logic  [XLEN-1:0] sltiu_rslt;
   logic  [(XLEN*2)-1:0] sext_src1;
   logic  [(XLEN*2)-1:0] sra_rslt;
   logic  [(XLEN*2)-1:0] srai_rslt;

   assign instr[XLEN-1:0] = imem_data[XLEN-1:0];
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
                    instr[6:2] == 5'b11001;
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
      is_slti     = dec_bits ==? 11'bx_010_0010011;
      is_sltiu    = dec_bits ==? 11'bx_011_0010011;
      is_xori     = dec_bits ==? 11'bx_100_0010011;
      is_ori      = dec_bits ==? 11'bx_110_0010011;
      is_andi     = dec_bits ==? 11'bx_111_0010011;
      is_slli     = dec_bits ==? 11'b0_001_0010011;
      is_srli     = dec_bits ==? 11'b0_101_0010011;
      is_srai     = dec_bits ==? 11'b1_101_0010011;
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
      if (XLEN == 32) begin
         imm[31:0]   = is_i_instr ? { {21{instr[31]}}, instr[30:20] } :
                       is_s_instr ? { {21{instr[31]}}, instr[30:25], instr[11:7] } :
                       // Branch immediates are encoded as multiples of 2
                       is_b_instr ? { {20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0 } :
                       // U-Type immediates are encoded as multiples of 4096
                       is_u_instr ? { instr[31:12], 12'b0 } :
                       // J-Type immediates are encoded as multiples of 2
                       is_j_instr ? { {12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0 } :
                          32'b0;  // Default, in case of R-Type instruction
      end
   end

   // ALU

   // SLTU/SLTIU (Set if less than, unsigned) results:
   assign sltu_rslt[31:0]  = {31'b0, src1_value < src2_value};
   assign sltiu_rslt[31:0] = {31'b0, src1_value < imm};

   // SRA and SRAI (shift right, arithmetic) results:
   assign sext_src1[63:0] = { {32{src1_value[31]}}, src1_value };
   assign sra_rslt[63:0]  = sext_src1 >> src2_value[4:0];
   assign srai_rslt[63:0] = sext_src1 >> imm[4:0];
   assign result[XLEN-1:0] =
      is_lui   ? {imm[31:12], 12'b0} :
      is_auipc ? pc + imm :
      is_jal   ? pc + 32'd4 :
      is_jalr  ? pc + 32'd4 :
      (is_addi || is_load || is_s_instr)  ?
                 src1_value + imm :
      is_slti  ? ( (src1_value[31] == imm[31]) ?
                        sltiu_rslt[31:0]       :
                        {31'b0, src1_value[31]} ) :
      is_sltiu ? sltiu_rslt[31:0] :
      is_xori  ? src1_value ^ imm :
      is_ori   ? src1_value | imm :
      is_andi  ? src1_value & imm :
      is_slli  ? src1_value << imm :
      is_srli  ? src1_value >> imm :
      is_srai  ? srai_rslt[31:0] :
      is_add   ? src1_value + src2_value :
      is_sub   ? src1_value - src2_value :
      is_sll   ? src1_value << src2_value[4:0] :
      is_slt   ? ( (src1_value[31] == src2_value[31]) ?
                        sltiu_rslt[31:0]       :
                        {31'b0, src1_value[31]} ) :
      is_sltu  ? sltu_rslt[31:0] :
      is_srl   ? src1_value >> src2_value[4:0] :
      is_xor   ? src1_value ^ src2_value :
      is_sra   ? sra_rslt[31:0] :
      is_or    ? src1_value | src2_value :
      is_and   ? src1_value & src2_value :
                32'b0;
   assign result_mx[XLEN-1:0] = is_load ? dmem_data : result;
   assign writing_to_reg = ~(is_s_instr || is_b_instr) && (rd != 'b0);

   // Branching
   assign taken_br =
      is_beq ?
         (src1_value == src2_value) :
      is_bne ?
         (src1_value != src2_value) :
      is_blt ?
         ((src1_value < src2_value) ^ (src1_value[31] != src2_value[31])) :
      is_bge ?
         ((src1_value >= src2_value) ^ (src1_value[31] != src2_value[31])) :
      is_bltu ?
         (src1_value < src2_value) :
      is_bgeu ?
         (src1_value >= src2_value) :
         0;     // Default value, as we're not dealing with a branching instruction
   assign br_tgt_pc = pc + imm;
   assign jalr_tgt_pc[31:0] = src1_value + imm;

   // Other signals
   assign imem_addr = pc;
   assign dmem_addr[31:0] = {27'b0, result[4:0]};
   assign dmem_wen = is_s_instr;
   assign dmem_data = is_s_instr ? src2_value : 'z;

   wire _unused_ok = &{1'b0,
      sra_rslt[63:32],
      srai_rslt[63:32],
      1'b0};

endmodule
