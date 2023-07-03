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
   logic  [31:0]     pc;

   // TODO: This is to keep verilator happy about unused signals.
   //       To be replaced with the actual design
   reg  [31:0]     instr;
   reg  [31:0]     data;
   always_ff @(posedge clk) begin
      pc <= '0;
      instr <= '0;
      data <= '0;
      if (~reset) begin
         pc <= pc + 'd4;
         instr <= imem_data;
         data <= dmem_data;
      end
   end

   assign imem_addr = pc + instr;
   assign dmem_addr = data;
   assign dmem_wen = 0;

endmodule
