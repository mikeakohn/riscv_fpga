.riscv

.org 0x4000

;; Registers.
BUTTON     equ 0x00
SPI_TX     equ 0x04
SPI_RX     equ 0x08
SPI_CTL    equ 0x0c
PORT0      equ 0x20
SOUND      equ 0x24
SPI_IO     equ 0x28

;; Bits in SPI_CTL.
SPI_BUSY   equ 0x01
SPI_START  equ 0x02
SPI_16     equ 0x04

;; Bits in SPI_IO.
LCD_RES    equ 0x01
LCD_DC     equ 0x02
LCD_CS     equ 0x04

;; Bits in PORT0
LED0       equ 0x01

main:
  li gp, 0x8000
  li a0, 0xaaaa
  li t0, 0
  sw t0, PORT0(gp)

;; lcd_send_data(a0)
lcd_send_data:
  li t0, LCD_DC | LCD_RES
  sw t0, SPI_IO(gp)
  sw a0, SPI_TX(gp)
  li t0, SPI_16 | SPI_START
  sw t0, SPI_CTL(gp)
lcd_send_data_wait:
  ;lw t0, SPI_CTL(gp)
  ;andi t0, t0, SPI_BUSY
  ;bnez t0, lcd_send_data_wait
  ;nop
  li t0, LCD_CS | LCD_RES
  sw t0, SPI_IO(gp)

  li t0, 1
  sw t0, PORT0(gp)

while_1:
  j while_1
  nop

delay:
  li t0, 4000
delay_loop:
  addi t0, t0, -1
  bnez t0, delay_loop
  nop
  ret
  nop

