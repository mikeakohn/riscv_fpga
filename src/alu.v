// RISC-V FPGA Soft Processor
//  Author: Michael Kohn
//   Email: mike@mikekohn.net
//     Web: https://www.mikekohn.net/
//   Board: iceFUN iCE40 HX8K
// License: MIT
//
// Copyright 2023-2025 by Michael Kohn

module alu
(
  input [31:0] source,
  input signed [31:0] arg_1,
  input [2:0] alu_op,
  input is_alt,
  output reg [31:0] result
);

parameter ALU_OP_ADD   = 0;
parameter ALU_OP_SLL   = 1;
parameter ALU_OP_SLT   = 2;
parameter ALU_OP_SLTU  = 3;
parameter ALU_OP_XOR   = 4;
parameter ALU_OP_SRL   = 5;
parameter ALU_OP_OR    = 6;
parameter ALU_OP_AND   = 7;

always @ * begin
  case (alu_op)
    ALU_OP_ADD:
      if (is_alt == 0)
        result <= $signed(source) + arg_1;
      else
        result <= $signed(source) - arg_1;
    ALU_OP_SLL:  result <= source << arg_1;
    ALU_OP_SLT:  result <= $signed(source) < arg_1;
    ALU_OP_SLTU: result <= source < $unsigned(arg_1);
    ALU_OP_XOR:  result <= source ^ arg_1;
    ALU_OP_SRL:
      if (is_alt == 0)
        result <= source >> arg_1;
      else
        result <= $signed(source) >>> arg_1;
    ALU_OP_OR:   result <= source | arg_1;
    ALU_OP_AND:  result <= source & arg_1;
  endcase
end

endmodule

