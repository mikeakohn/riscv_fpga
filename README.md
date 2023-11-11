RISC-V
======

This is an implementation of a RISC-V CPU implemented in Verilog
to be run on an FPGA. The board being used here is an iceFUN with
a Lattice iCE40 HX8K FPGA.

This project was created by forking the Intel 8008 FPGA project
changing the memory_bus.v module to take a 32 bit databus and
changing the core processor to decode RISC-V instructions.

https://www.mikekohn.net/micro/intel_8008_fpga.php

This is still a work in progress.

