// Ferrati F100-L FPGA Soft Processor
//  Author: Michael Kohn
//   Email: mike@mikekohn.net
//     Web: https://www.mikekohn.net/
//   Board: iceFUN iCE40 HX8K
// License: MIT
//
// Copyright 2023 by Michael Kohn

module mandelbrot
(
  input  raw_clk,
  input  start,
  input  [15:0] curr_r,
  input  [15:0] curr_i,
  output [3:0]  result,
  output busy
);

reg is_running = 0;

reg [1:0] state = 0;
reg signed [15:0] zr;
reg signed [15:0] zi;
reg signed [31:0] zr2;
reg signed [31:0] zi2;
reg signed [15:0] tr;
reg signed [31:0] ti;
reg [3:0] count;

assign result = count;
assign busy = is_running;

parameter STATE_IDLE         = 0;
parameter STATE_START        = 1;
parameter STATE_CHECK_SQUARE = 2;
parameter STATE_LAST         = 3;

always @(posedge raw_clk) begin
  case (state)
    STATE_IDLE:
      begin
        if (start) begin
          is_running <= 1;
          zr <= curr_r;
          zi <= curr_i;
          state <= STATE_START;
          count <= 15;
        end else begin
          is_running <= 0;
        end
      end
    STATE_START:
      begin
        zr2 <= (zr * zr) >> 10;
        zi2 <= (zi * zi) >> 10;
        state <= STATE_CHECK_SQUARE;
      end
    STATE_CHECK_SQUARE:
      begin
        if ((zr2[15:0] + zi2[15:0]) >= (4 << 10)) begin
          state <= STATE_IDLE;
        end else begin
          tr <= zr2[15:0] - zi2[15:0];
          ti <= (zr * zi) >> 9;
          state = STATE_LAST;
        end
      end
    STATE_LAST:
      begin
        if (count == 0) begin
          state <= STATE_IDLE;
        end else begin
          zr <= tr + curr_r;
          zi <= ti[15:0] + curr_i;
          state <= STATE_START;
          count <= count - 1;
        end
      end
  endcase
end

endmodule

