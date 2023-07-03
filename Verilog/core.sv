module core(clk, reset, imem_data, imem_addr, dmem_data, dmem_addr, dmem_wen);
/* verilator lint_on WIDTH */

   input             clk;
   input             reset;
   output            dmem_wen;

   input  [31:0]     imem_data;
   output [31:0]     imem_addr;
   inout  [31:0]     dmem_data;
   output [31:0]     dmem_addr;

   // Internal signals and FF
   logic  [31:0]     next_pc;
   logic  [31:0]     pc;
   /* verilator lint_off UNUSEDSIGNAL */
   logic  [31:0]     instr;
   logic  [6:0]      opcode;
   logic  [2:0]      funct3;
   // logic  [6:0]      funct7;
   logic  [4:0]      rd;
   logic  [4:0]      rs1;
   logic  [4:0]      rs2;
   logic  [31:0]     imm;

   logic  [10:0]     dec_bits;
   logic             is_r_instr;
   logic             is_i_instr;
   logic             is_s_instr;
   logic             is_b_instr;
   logic             is_u_instr;
   logic             is_j_instr;
   logic             imm_valid;
   /* verilator lint_on UNUSEDSIGNAL */

   assign instr[31:0]    = imem_data[31:0];
   assign dec_bits[10:0] = {instr[30], funct3, opcode};

   always_ff @(posedge clk) begin
      pc <= 0;
      next_pc <= 0;

      if (~reset) begin
         next_pc <= next_pc + 'd4;
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

	   imm_valid   = ~is_r_instr;
	   // Most immediate operands need sign extended
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
   assign imem_addr = pc;
   assign dmem_addr = 0;
   assign dmem_wen = 0;

endmodule
