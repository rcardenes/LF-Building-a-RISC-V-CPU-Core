module top(clock, reset);
/* verilator lint_on WIDTH */
   localparam XLEN = 32;

   input logic clock;
   input logic reset;

   reg [31:0] imem [0:255];  // 256-word instruction memory

   wire [XLEN-1:0] imem_addr;
   logic [31:0] imem_data;

   always_comb begin
      imem_data = imem[imem_addr[9:2]];
   end

   wire dmem_wen;
   wire [XLEN-1:0] dmem_addr;
   wire [XLEN-1:0] dmem_data;

   core #(.XLEN(XLEN))
   c0 (clock, reset, imem_data, imem_addr, dmem_data, dmem_addr, dmem_wen, dmem_width);

   wire men;
   wire [2:0] dmem_width;
   assign men = 1'b1;

   wire [XLEN-1:0] dmem_data_in;
   wire [XLEN-1:0] dmem_data_out;
   assign dmem_data_in = (dmem_wen) ? dmem_data : 'z;
   assign dmem_data    = (dmem_wen) ? 'z : dmem_data_out;

   localparam int MEMSIZE = 1024;
   localparam int WIDTH = $clog2(MEMSIZE);

   rwmemory #(.MEMSIZE(1024), .DWIDTH(XLEN))
   dmem (
      .clk(clock),
      .en(men),
      .wen(dmem_wen),
      .addr(dmem_addr[WIDTH-1:0]),
      .data_in_w(dmem_width),
      .data_in(dmem_data_in),
      .data_out(dmem_data_out)
      );

   initial begin
      $readmemh("hex/program.hex", imem);
   end

   wire _unused_ok = &{1'b0,
      imem_addr[(XLEN-1):10],
      imem_addr[1:0],
      dmem_addr[(XLEN-1):10],
      1'b0};
endmodule
