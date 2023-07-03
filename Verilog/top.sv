module top(clock, reset);
/* verilator lint_on WIDTH */

   input logic clock;
   input logic reset;

   reg [31:0] imem [0:255];  // 256-word instruction memory

   wire [31:0] imem_addr;
   logic [31:0] imem_data;

   always_comb begin
      imem_data = imem[imem_addr[7:0]];
   end

   wire dmem_wen;
   wire [31:0] dmem_addr;
   wire [31:0] dmem_data;
   // assign dmem_data = dmem_addr[

   core c0 (clock, reset, imem_data, imem_addr, dmem_data, dmem_addr, dmem_wen);

   wire men;
   assign men = 1'b1;

   wire [31:0] dmem_data_in;
   wire [31:0] dmem_data_out;
   assign dmem_data_in = (dmem_wen) ? dmem_data : 'z;
   assign dmem_data    = (dmem_wen) ? 'z : dmem_data_out;

   localparam int MEMSIZE = 1024;
   localparam int WIDTH = $clog2(MEMSIZE);

   rwmemory #(.MEMSIZE(1024))
   dmem (
      .clk(clock),
      .en(men),
      .wen(dmem_wen),
      .addr(dmem_addr[WIDTH-1:0]),
      .data_in(dmem_data_in),
      .data_out(dmem_data_out)
      );

   initial begin
      $readmemh("hex/program.hex", imem);
   end

   wire _unused_ok = &{1'b0,
      imem_addr[31:8],
      dmem_addr[31:10],
      1'b0};
endmodule
