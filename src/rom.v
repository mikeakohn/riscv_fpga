// RISC-V FPGA Processor
//  Author: Michael Kohn
//   Email: mike@mikekohn.net
//     Web: https://www.mikekohn.net/
//   Board: iceFUN iCE40 HX8K
// License: MIT
//
// Copyright 2023-2026 by Michael Kohn

// This is a hardcoded program.

module rom
(
  input  [11:0] address,
  output [31:0] data_out,
  input clk
);

reg [31:0] memory [1023:0];

initial begin
  $readmemh("rom.txt", memory);
end

/*
always @(posedge clk) begin
  data_out <= memory[address[11:2]];
end
*/

assign data_out = memory[address[11:2]];

endmodule

