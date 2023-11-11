#!/usr/bin/env python3

import sys

print("// RISC-V FPGA Soft Processor")
print("//  Author: Michael Kohn")
print("//   Email: mike@mikekohn.net")
print("//     Web: https://www.mikekohn.net/")
print("//   Board: iceFUN iCE40 HX8K")
print("// License: MIT")
print("//")
print("// Copyright 2023 by Michael Kohn\n")

print("// This is a hardcoded program that blinks an external LED.\n")

print("module rom")
print("(")
print("  input  [9:0] address,")
print("  output [7:0] data_out")
print(");\n")

print("reg [7:0] data;")
print("assign data_out = data;\n")

print("always @(address) begin")
print("  case (address)")

indent = "    "
address = 0

fp = open(sys.argv[1], "r")

for line in fp:
  if not "cycles" in line: continue
  line = line.strip()
  opcodes = line[:22].strip().split()[1]
  code = line[22:line.find("cycles")].strip()
  print(indent + "// " + code)

  opcodes = [
    opcodes[8:10],
    opcodes[6:8],
    opcodes[4:6],
    opcodes[2:4],
  ]

  for opcode in opcodes:
    print(indent + str(address) + ": data <= 8'h" + opcode + ";")
    address += 1

fp.close()

print("    default: data <= 0;")
print("  endcase")
print("end\n")

print("endmodule\n")

