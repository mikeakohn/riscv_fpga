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
  output [31:0] data_out
);

reg [31:0] data;
assign data_out = data;

always @(address) begin
  case (address[9:2])
    // lui t0, 0x00000c
    0: data <= 32'h0000c2b7;
    // addi t0, t0, 137 (0x000089)
    1: data <= 32'h08928293;
    // addi t1, zero, 100 (0x000064)
    2: data <= 32'h06400313;
    // sb t1, 5(t0)
    3: data <= 32'h006282a3;
    // lb t2, 5(t0)
    4: data <= 32'h00528383;
    // ebreak
    5: data <= 32'h00100073;
    default: data <= 0;
  endcase
end

endmodule

