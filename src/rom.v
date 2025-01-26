// RISC-V FPGA Soft Processor
//  Author: Michael Kohn
//   Email: mike@mikekohn.net
//     Web: https://www.mikekohn.net/
//   Board: iceFUN iCE40 HX8K
// License: MIT
//
// Copyright 2023-2025 by Michael Kohn

// This is a hardcoded program that blinks an external LED.

module rom
(
  input  [11:0] address,
  output reg [31:0] data_out,
  input clk
);

reg [31:0] memory [1023:0];

initial begin
  $readmemh("rom.txt", memory);
end

always @(posedge clk) begin
  data_out <= memory[address[11:2]];
end

endmodule

