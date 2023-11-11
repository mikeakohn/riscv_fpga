// RISC-V FPGA Soft Processor
//  Author: Michael Kohn
//   Email: mike@mikekohn.net
//     Web: https://www.mikekohn.net/
//   Board: iceFUN iCE40 HX8K
// License: MIT
//
// Copyright 2023 by Michael Kohn

// This creates 1024 bytes of RAM on the FPGA itself. Written this
// way makes it inferred by the IceStorm tools. It seems like it
// only infers it to BlockRam when using double_clk, which based
// on the timing chart in the Lattice documentation seems to make
// sense.

module ram
(
  input [9:0] address,
  input [7:0] data_in,
  output reg [7:0] data_out,
  input write_enable,
  input clk
  //input double_clk,
);

reg [7:0] storage [1023:0];

/*
initial begin
  storage[4] <= 8'ha0;
  storage[5] <= 8'h55;
  storage[6] <= 8'h99;
  storage[7] <= 8'h44;
end
*/

//always @(posedge double_clk) begin
always @(posedge clk) begin
  if (write_enable) begin
    storage[address] <= data_in;
  end else
    data_out = storage[address];
end

endmodule

