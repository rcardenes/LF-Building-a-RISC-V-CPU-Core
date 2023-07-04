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
      .wr_data(result),
      .rd1_en(1),
      .rd1_index(rs1),
      .rd1_data(src1_value),
      .rd2_en(1),
      .rd2_index(rs2),
      .rd2_data(src2_value)
   );

   // Internal signals and FF
   logic  [XLEN-1:0] next_pc;
   logic  [XLEN-1:0] pc;
   logic             taken_br;
   logic  [XLEN-1:0] br_tgt_pc;
   logic  [XLEN-1:0] src1_value;
   logic  [XLEN-1:0] src2_value;
   logic             writing_to_reg;
   logic  [XLEN-1:0] result;
   logic  [XLEN-1:0] instr;
   logic  [6:0]      opcode;
   logic  [2:0]      funct3;
   // logic  [6:0]      funct7;
   logic  [4:0]      rd;
   logic  [4:0]      rs1;
   logic  [4:0]      rs2;
   logic  [XLEN-1:0] imm;
   logic  [10:0]     dec_bits;
   /* verilator lint_off UNUSEDSIGNAL */
   logic             is_r_instr;
   logic             is_i_instr;
   logic             is_s_instr;
   logic             is_b_instr;
   logic             is_u_instr;
   logic             is_j_instr;
   logic             imm_valid;
   /* verilator lint_on UNUSEDSIGNAL */
   logic is_addi;
   logic is_add;
   logic is_beq;
   logic is_bne;
   logic is_blt;
   logic is_bge;
   logic is_bltu;
   logic is_bgeu;

   assign instr[XLEN-1:0] = imem_data[XLEN-1:0];
   assign dec_bits[10:0]  = {instr[30], funct3, opcode};

   always_ff @(posedge clk) begin
      pc <= 0;
      next_pc <= 0;

      if (~reset) begin
         next_pc <=
            taken_br ?
               br_tgt_pc :     // We're performing a branch
               next_pc + 'd4;  // Simple increment
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

      is_addi     = dec_bits ==? 11'bx_000_0010011;
      is_add      = dec_bits ==  11'b0_000_0110011;
      is_beq      = dec_bits ==? 11'bx_000_1100011;
      is_bne      = dec_bits ==? 11'bx_001_1100011;
      is_blt      = dec_bits ==? 11'bx_100_1100011;
      is_bge      = dec_bits ==? 11'bx_101_1100011;
      is_bltu     = dec_bits ==? 11'bx_110_1100011;
      is_bgeu     = dec_bits ==? 11'bx_111_1100011;

      imm_valid   = ~is_r_instr;
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
   assign result[XLEN-1:0] =
      is_addi ? src1_value + imm :
      is_add  ? src1_value + src2_value :
                32'b0;
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

   // Other signals
   assign imem_addr = pc;
   assign dmem_addr = 0;
   assign dmem_wen = 0;

endmodule
