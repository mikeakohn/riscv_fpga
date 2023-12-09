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

This is still a work in progress.

Features
========

IO, Button input, speaker tone generator, SPI, and Mandelbrot acceleration.

Registers
=========

Instructions
============

Memory Map
==========

This implementation of the RISC-V has 4 banks of memory. Each address
contains a 16 bit word instead of 8 bit byte like a typical CPU.

* Bank 0: 0x0000 RAM (1024 words) Implicit BlockRam.
* Bank 1: 0x4000 ROM
* Bank 2: 0x8000 Peripherals
* Bank 3: 0xc000 RAM (1024 words)

On start-up by default, the chip will load a program from a AT93C86A
2kB EEPROM with a 3-Wire (SPI-like) interface but wll run the code
from the ROM. To start the program loaded to RAM, the program select
button needs to be held down while the chip is resetting.

The peripherals area contain the following:

* 0x8000: input from push button
* 0x8004: SPI TX buffer
* 0x8008: SPI RX buffer
* 0x800c: SPI control: bit 2: 8/16, bit 1: start strobe, bit 0: busy
* 0x8018: ioport_A output (in my test case only 1 pin is connected)
* 0x8024: MIDI note value (60-96) to play a tone on the speaker or 0 to stop
* 0x8028: ioport_B output (3 pins)
* 0x802c: mandelbrot real value
* 0x8030: mandelbrot imaginary value
* 0x8034: mandelbrot control: bit 1: start, bit 0: busy
* 0x8038: mandelbrot result (bottom 4 bits)

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

