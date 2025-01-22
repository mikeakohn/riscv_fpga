RISC-V
======

This is an implementation of a RISC-V CPU implemented in Verilog
to be run on an FPGA. The board being used here is an iceFUN with
a Lattice iCE40 HX8K FPGA.

This project was created by forking the Intel 8008 FPGA project
changing the memory_bus.v module to take a 32 bit databus and
changing the core processor to decode RISC-V instructions.

https://www.mikekohn.net/micro/riscv_fpga.php
https://www.mikekohn.net/micro/intel_8008_fpga.php

Features
========

IO, Button input, speaker tone generator, SPI, and Mandelbrot acceleration.

Instructions
============

    lb rd, offset(rs1)      iiii iiii iiii sssss 000 ddddd 0000 011
    lh rd, offset(rs1)      iiii iiii iiii sssss 001 ddddd 0000 011
    lw rd, offset(rs1)      iiii iiii iiii sssss 010 ddddd 0000 011
    lbu rd, offset(rs1)     iiii iiii iiii sssss 100 ddddd 0000 011
    lhu rd, offset(rs1)     iiii iiii iiii sssss 101 ddddd 0000 011

    addi rd, rs1, imm       iiii iiii iiii sssss 000 ddddd 0010 011
    slti rd, rs1, imm       iiii iiii iiii sssss 010 ddddd 0010 011
    sltiu rd, rs1, imm      iiii iiii iiii sssss 011 ddddd 0010 011
    xori rd, rs1, imm       iiii iiii iiii sssss 100 ddddd 0010 011
    ori rd, rs1, imm        iiii iiii iiii sssss 110 ddddd 0010 011
    andi rd, rs1, imm       iiii iiii iiii sssss 111 ddddd 0010 011
    slli rd, rs1, imm       0000 000 shamt sssss 001 ddddd 0010 011
    srli rd, rs1, imm       0000 000 shamt sssss 101 ddddd 0010 011
    srai rd, rs1, imm       0100 000 shamt sssss 101 ddddd 0010 011

    sb rd, offset(rs1)      iiii iii rrrrr sssss 000 iiiii 0100 011
    sh rd, offset(rs1)      iiii iii rrrrr sssss 001 iiiii 0100 011
    sw rd, offset(rs1)      iiii iii rrrrr sssss 010 iiiii 0100 011

    add rd, rs1, rs2        0000 000 rrrrr sssss 000 ddddd 0110 011
    sub rd, rs1, rs2        0100 000 rrrrr sssss 000 ddddd 0110 011
    sll rd, rs1, rs2        0000 000 rrrrr sssss 001 ddddd 0110 011
    slt rd, rs1, rs2        0000 000 rrrrr sssss 010 ddddd 0110 011
    sltu rd, rs1, rs2       0000 000 rrrrr sssss 011 ddddd 0110 011
    xor rd, rs1, rs2        0000 000 rrrrr sssss 100 ddddd 0110 011
    srl rd, rs1, rs2        0000 000 rrrrr sssss 101 ddddd 0110 011
    sra rd, rs1, rs2        0100 000 rrrrr sssss 101 ddddd 0110 011
    or rd, rs1, rs2         0000 000 rrrrr sssss 110 ddddd 0110 011
    and rd, rs1, rs2        0000 000 rrrrr sssss 111 ddddd 0110 011

    beq rs1, rs2, offset    iiii iii rrrrr sssss 000 iiiii 1100 011
    bne rs1, rs2, offset    iiii iii rrrrr sssss 001 iiiii 1100 011
    blt rs1, rs2, offset    iiii iii rrrrr sssss 100 iiiii 1100 011
    bge rs1, rs2, offset    iiii iii rrrrr sssss 101 iiiii 1100 011
    bltu rs1, rs2, offset   iiii iii rrrrr sssss 110 iiiii 1100 011
    bgeu rs1, rs2, offset   iiii iii rrrrr sssss 111 iiiii 1100 011

    ebreak                  0000 0000 0000 00000 000 00000 1110 011

    auipc rd, imm           iiii iiii iiii iiii iiii ddddd 0010 111
    lui rd, imm             iiii iiii iiii iiii iiii ddddd 0110 111
    jalr rd, rs1, offset    iiii iiii iiii sssss 000 ddddd 1100 111
    jal rd, offset          iiii iiii iiii iiii iiii ddddd 1101 111

For src/riscv_mandel.v, this instruction is encoded as mulw.

    mandel rd, rs1, rs2     0000 001 rrrrr sssss 000 ddddd 0111011

Registers
=========
    x0         zero
    x1         ra
    x2         sp
    x3         gp
    x4         tp
    x5 - x7    t0 - t2
    x8         s0 / fp
    x9         s1
    x10 - x17  a0 - a7
    x18 - x27  s2 - s11
    x28 - x31  t3 - t6

Memory Map
==========

This implementation of the RISC-V has 4 banks of memory. Each address
contains a 16 bit word instead of 8 bit byte like a typical CPU.

* Bank 0: 0x0000 RAM (4096 bytes)
* Bank 1: 0x4000 ROM
* Bank 2: 0x8000 Peripherals
* Bank 3: 0xc000 RAM (4096 bytes)

On start-up by default, the chip will load a program from a AT93C86A
2kB EEPROM with a 3-Wire (SPI-like) interface but wll run the code
from the ROM. To start the program loaded to RAM, the program select
button needs to be held down while the chip is resetting.

The peripherals area contain the following:

* 0x8000: input from push button
* 0x8004: SPI TX buffer
* 0x8008: SPI RX buffer
* 0x800c: SPI control: bit 2: 8/16, bit 1: start strobe, bit 0: busy
* 0x8020: ioport_A output (in my test case only 1 pin is connected)
* 0x8024: MIDI note value (60-96) to play a tone on the speaker or 0 to stop
* 0x8028: ioport_B output (3 pins)

IO
--

iport_A is just 1 output in my test circuit to an LED.
iport_B is 3 outputs used in my test circuit for SPI (RES/CS/DC) to the LCD.

MIDI
----

The MIDI note peripheral allows the iceFUN board to play tones at specified
frequencies based on MIDI notes.

SPI
---

The SPI peripheral has 3 memory locations. One location for reading
data after it's received, one location for filling the transmit buffer,
and one location for signaling.

For signaling, setting bit 1 to a 1 will cause whatever is in the TX
buffer to be transmitted. Until the data is fully transmitted, bit 0
will be set to 1 to let the user know the SPI bus is busy.

There is also the ability to do 16 bit transfers by setting bit 2 to 1.

Mandelbrot
----------

The mulw instruction opcode is implemented as a mandelbrot instruction
and is tied to the mandelbrot.v module.

    mandel t0, t1, t2

In this case t1 should contain a 16 bit fixed point value in 6.10 format
representing the real value, t2 will have the fixed point imaginary value,
and after something like 2 to 45 CPU cycles, t0 will contain a number between
0 to 15 with the value of that coordinate in the Mandelbrot set.

An example of its use is in lcd.asm and a video of the speed difference is
shown on the project website.

