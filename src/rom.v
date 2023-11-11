// RISC-V FPGA Soft Processor
//  Author: Michael Kohn
//   Email: mike@mikekohn.net
//     Web: https://www.mikekohn.net/
//   Board: iceFUN iCE40 HX8K
// License: MIT
//
// Copyright 2023 by Michael Kohn

// This is a hardcoded program that blinks an external LED.

module rom
(
  input  [9:0] address,
  output [7:0] data_out
);

reg [7:0] data;
assign data_out = data;

always @(address) begin
  case (address)
    // lui x5, 0x000000
    0: data <= 8'hb7;
    1: data <= 8'h02;
    2: data <= 8'h00;
    3: data <= 8'h00;
    // ori x5, 0x8
    4: data <= 8'h93;
    5: data <= 8'he2;
    6: data <= 8'h82;
    7: data <= 8'h00;
    // addi x6, x0, 137 (0x000089)
    8: data <= 8'h13;
    9: data <= 8'h03;
    10: data <= 8'h90;
    11: data <= 8'h08;
    // sb x6, 5(x5)
    12: data <= 8'ha3;
    13: data <= 8'h82;
    14: data <= 8'h62;
    15: data <= 8'h00;
    // lb x7, 5(x5)
    16: data <= 8'h83;
    17: data <= 8'h83;
    18: data <= 8'h52;
    19: data <= 8'h00;
    // ebreak
    20: data <= 8'h73;
    21: data <= 8'h00;
    22: data <= 8'h10;
    23: data <= 8'h00;
    default: data <= 0;
  endcase
end

endmodule

