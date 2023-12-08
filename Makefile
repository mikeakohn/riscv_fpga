
PROGRAM=riscv
SOURCE= \
  src/$(PROGRAM).v \
  src/block_ram.v \
  src/eeprom.v \
  src/mandelbrot.v \
  src/memory_bus.v \
  src/peripherals.v \
  src/ram.v \
  src/rom.v \
  src/spi.v

default:
	yosys -q -p "synth_ice40 -top $(PROGRAM) -json $(PROGRAM).json" $(SOURCE)
	nextpnr-ice40 -r --hx8k --json $(PROGRAM).json --package cb132 --asc $(PROGRAM).asc --opt-timing --pcf icefun.pcf
	icepack $(PROGRAM).asc $(PROGRAM).bin

program:
	iceFUNprog $(PROGRAM).bin

blink:
	naken_asm -l -type bin -o blink.bin test/blink.asm
	#python3 tools/lst2verilog.py blink.lst > src/rom.v
	python3 tools/bin2txt.py blink.bin > rom.txt

rom_0:
	naken_asm -l -type bin -o store_byte.bin test/store_byte.asm
	#python3 tools/lst2verilog.py store_byte.lst > src/rom.v
	python3 tools/bin2txt.py store_byte.bin > rom.txt

rom_1:
	naken_asm -l -type bin -o load_byte.bin test/load_byte.asm
	#python3 tools/lst2verilog.py load_byte.lst > src/rom.v
	python3 tools/bin2txt.py load_byte.bin > rom.txt

clean:
	@rm -f $(PROGRAM).bin $(PROGRAM).json $(PROGRAM).asc *.lst
	@rm -f blink.bin load_byte.bin store_byte.bin test_subroutine.bin
	@rm -f button.bin
	@echo "Clean!"

