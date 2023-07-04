module regfile(clk, reset, wr_en, wr_index, wr_data, rd1_en, rd1_index, rd1_data, rd2_en, rd2_index, rd2_data);
/* verilator lint_on WIDTH */
   parameter WIDTH = 32;
   parameter SIZE = 32;
   localparam INDEX_LSB = $clog2(SIZE);

   input clk;
   input reset;
   input wr_en;
   input rd1_en;
   input rd2_en;

   input  [INDEX_LSB-1:0] wr_index;
   input  [INDEX_LSB-1:0] rd1_index;
   input  [INDEX_LSB-1:0] rd2_index;
   input  [WIDTH-1:0]     wr_data;
   output [WIDTH-1:0]     rd1_data;
   output [WIDTH-1:0]     rd2_data;

   logic  [WIDTH-1:0]     file [SIZE-1:1];

   integer i;
   always_ff @(posedge clk) begin
      if (reset) begin
         for (i = 1; i < SIZE; i = i + 1) file[i] <= 0;
      end
      else begin
         if (wr_en)
            file[wr_index] <= wr_data;
      end
   end

   assign rd1_data = (rd1_en && (rd1_index != 0)) ? file[rd1_index] : 32'b0;
   assign rd2_data = (rd2_en && (rd2_index != 0)) ? file[rd2_index] : 32'b0;

endmodule
