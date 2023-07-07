module rwmemory(clk, en, wen, addr, data_in_w, data_in, data_out);
   parameter int MEMSIZE = 'h400;
   parameter int DWIDTH = 32;
   localparam int WIDTH = $clog2(MEMSIZE);
   localparam int BYTESPERW = DWIDTH / 8;

   input logic clk;
   input logic en;
   input logic wen;
   input logic [WIDTH-1:0] addr;

   input  logic [2:0] data_in_w;
   input  logic [DWIDTH-1:0] data_in;
   output logic [DWIDTH-1:0] data_out;

   logic [7:0] data[MEMSIZE-1:0];

   bit [WIDTH-1:0] i;

   always_comb begin
      data_out = '0;
      if (en == 1'b1 && wen == 1'b0) begin
         for (i = 0; i < BYTESPERW[WIDTH-1:0]; i++) begin
            data_out[i*8 +: 8] = data[addr + i];
         end
      end
   end

   always_ff @(posedge clk) begin
      if (en == 1'b1 && wen == 1'b1) begin
         if (data_in_w == '0) begin
            for (i = 0; i < 'd1; i++) begin
               data[addr + i] <= data_in[i*8 +: 8];
            end
         end
         else if (data_in_w == 'b1) begin
            for (i = 0; i < 'd2; i++) begin
               data[addr + i] <= data_in[i*8 +: 8];
            end
         end
         else if (data_in_w == 'b10) begin
            for (i = 0; i < 'd4; i++) begin
               data[addr + i] <= data_in[i*8 +: 8];
            end
         end
      end
   end
endmodule
