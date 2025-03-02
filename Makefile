
NAKEN_INCLUDE=../naken_asm/include
PROGRAM=riscv
SOURCE= \
  src/alu.v \
  src/memory_bus.v \
  src/peripherals.v \
  src/ram.v \
  src/rom.v \
  src/spi.v \
  src/uart.v

EXTRA_SOURCE= \
  src/eeprom.v \
  src/mandelbrot.v \

default:
	yosys -q \
	  -p "synth_ice40 -top $(PROGRAM) -json $(PROGRAM).json" \
	  $(SOURCE) src/riscv.v
	nextpnr-ice40 -r \
	  --hx8k \
	  --json $(PROGRAM).json \
	  --package cb132 \
	  --asc $(PROGRAM).asc \
	  --opt-timing \
	  --pcf icefun.pcf
	icepack $(PROGRAM).asc $(PROGRAM).bin

tang_nano:
	yosys -q \
	  -p "read_verilog $(SOURCE); synth_gowin -json $(PROGRAM).json -family gw2a"
	nextpnr-himbaechel -r \
	  --json $(PROGRAM).json \
	  --write $(PROGRAM)_pnr.json \
	  --freq 27 \
	  --vopt family=GW2A-18C \
	  --vopt cst=tangnano20k.cst \
	  --device GW2AR-LV18QN88C8/I7
	gowin_pack -d GW2A-18C -o $(PROGRAM).fs $(PROGRAM)_pnr.json

riscv_mandel:
	yosys -q -p "synth_ice40 -top $(PROGRAM) -json $(PROGRAM).json" $(SOURCE) $(EXTRA_SOURCE) src/riscv_mandel.v
	nextpnr-ice40 -r --hx8k --json $(PROGRAM).json --package cb132 --asc $(PROGRAM).asc --opt-timing --pcf icefun.pcf
	icepack $(PROGRAM).asc $(PROGRAM).bin

timing:
	icetime -t -d hx8k -p icefun.pcf $(PROGRAM).asc

ciscv:
	yosys -q -p "synth_ice40 -top $(PROGRAM) -json $(PROGRAM).json" $(SOURCE) $(EXTRA_SOURCE) src/ciscv.v
	nextpnr-ice40 -r --hx8k --json $(PROGRAM).json --package cb132 --asc $(PROGRAM).asc --opt-timing --pcf icefun.pcf
	icepack $(PROGRAM).asc $(PROGRAM).bin

program:
	iceFUNprog $(PROGRAM).bin

blink:
	naken_asm -l -type bin -o rom.bin test/blink.asm
	python3 tools/bin2txt.py rom.bin > rom.txt

lcd:
	naken_asm -l -type bin -o rom.bin -I$(NAKEN_INCLUDE) test/lcd.asm
	python3 tools/bin2txt.py rom.bin > rom.txt

lcd_mandel_hw:
	naken_asm -l -type bin -o rom.bin test/lcd_mandel_hw.asm
	python3 tools/bin2txt.py rom.bin > rom.txt

ciscv_test:
	naken_asm -l -type bin -o rom.bin test/ciscv.asm
	python3 tools/bin2txt.py rom.bin > rom.txt

ciscv_speed:
	naken_asm -l -type bin -o rom.bin test/ciscv_speed.asm
	python3 tools/bin2txt.py rom.bin > rom.txt

store_byte:
	naken_asm -l -type bin -o rom.bin test/store_byte.asm
	python3 tools/bin2txt.py rom.bin > rom.txt

load_byte:
	naken_asm -l -type bin -o rom.bin test/load_byte.asm
	python3 tools/bin2txt.py rom.bin > rom.txt

alu:
	naken_asm -l -type bin -o rom.bin test/alu.asm
	python3 tools/bin2txt.py rom.bin > rom.txt

jump:
	naken_asm -l -type bin -o rom.bin test/jump.asm
	python3 tools/bin2txt.py rom.bin > rom.txt

branch:
	naken_asm -l -type bin -o rom.bin test/branch.asm
	python3 tools/bin2txt.py rom.bin > rom.txt

spi:
	naken_asm -l -type bin -o rom.bin test/spi.asm
	python3 tools/bin2txt.py rom.bin > rom.txt

uart:
	naken_asm -l -type bin -o rom.bin test/uart.asm
	python3 tools/bin2txt.py rom.bin > rom.txt

bootloader: 
	naken_asm -l -type bin -o rom.bin test/bootloader.asm
	python3 tools/bin2txt.py rom.bin > rom.txt

clean:
	@rm -f $(PROGRAM).bin $(PROGRAM).json $(PROGRAM).asc *.lst
	@rm -f blink.bin load_byte.bin store_byte.bin test_subroutine.bin
	@rm -f button.bin
	@echo "Clean!"

