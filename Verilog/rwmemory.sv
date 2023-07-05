module rwmemory(clk, en, wen, addr, data_in, data_out);
   parameter int MEMSIZE = 'h400;
   parameter int WORDL = 32;
   localparam int MEMSIZE_BY_4 = MEMSIZE/4;
   localparam int WIDTH = $clog2(MEMSIZE);

   input logic clk;
   input logic en;
   input logic wen;
   input logic [WIDTH-1:0] addr;

   input  logic [WORDL-1:0] data_in;
   output logic [WORDL-1:0] data_out;

   logic [WORDL-1:0] data[MEMSIZE_BY_4-1:0];

   always_comb begin
      data_out = '0;
      if (en == 1'b1 && wen == 1'b0) begin
         data_out = data[addr / 4];
      end
   end

   always_ff @(posedge clk) begin
      if (en == 1'b1 && wen == 1'b1) begin
         data[addr / 4] <= data_in;
      end
   end
endmodule
