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

COMMAND_DISPLAY_OFF     equ 0xae
COMMAND_SET_REMAP       equ 0xa0
COMMAND_START_LINE      equ 0xa1
COMMAND_DISPLAY_OFFSET  equ 0xa2
COMMAND_NORMAL_DISPLAY  equ 0xa4
COMMAND_SET_MULTIPLEX   equ 0xa8
COMMAND_SET_MASTER      equ 0xad
COMMAND_POWER_MODE      equ 0xb0
COMMAND_PRECHARGE       equ 0xb1
COMMAND_CLOCKDIV        equ 0xb3
COMMAND_PRECHARGE_A     equ 0x8a
COMMAND_PRECHARGE_B     equ 0x8b
COMMAND_PRECHARGE_C     equ 0x8c
COMMAND_PRECHARGE_LEVEL equ 0xbb
COMMAND_VCOMH           equ 0xbe
COMMAND_MASTER_CURRENT  equ 0x87
COMMAND_CONTRASTA       equ 0x81
COMMAND_CONTRASTB       equ 0x82
COMMAND_CONTRASTC       equ 0x83
COMMAND_DISPLAY_ON      equ 0xaf

.macro send_command(value)
  li a0, value
  jal lcd_send_cmd
  nop
.endm

start:
  ;; Point gp to peripherals.
  li gp, 0x8000
  ;; Clear LED.
  li t0, 1
  sw t0, PORT0(gp)

main:
  jal lcd_init
  nop
  jal lcd_clear
  nop

  li s2, 0
main_while_1:
  lw t0, BUTTON(gp)
  andi t0, t0, 1
  bnez t0, run
  nop
  xori s2, s2, 1
  sb s2, PORT0(gp)
  jal delay
  nop

  j main_while_1
  nop

run:
  jal ra, lcd_clear_2
  nop
  jal ra, mandelbrot
  nop
  j main_while_1
  nop

lcd_init:
  mv s1, ra
  li t0, LCD_CS
  sw t0, SPI_IO(gp)
  jal delay
  nop
  li t0, LCD_CS | LCD_RES
  sw t0, SPI_IO(gp)

  send_command(COMMAND_DISPLAY_OFF)
  send_command(COMMAND_SET_REMAP)
  send_command(0x72)
  send_command(COMMAND_START_LINE)
  send_command(0x00)
  send_command(COMMAND_DISPLAY_OFFSET)
  send_command(0x00)
  send_command(COMMAND_NORMAL_DISPLAY)
  send_command(COMMAND_SET_MULTIPLEX)
  send_command(0x3f)
  send_command(COMMAND_SET_MASTER)
  send_command(0x8e)
  send_command(COMMAND_POWER_MODE)
  send_command(COMMAND_PRECHARGE)
  send_command(0x31)
  send_command(COMMAND_CLOCKDIV)
  send_command(0xf0)
  send_command(COMMAND_PRECHARGE_A)
  send_command(0x64)
  send_command(COMMAND_PRECHARGE_B)
  send_command(0x78)
  send_command(COMMAND_PRECHARGE_C)
  send_command(0x64)
  send_command(COMMAND_PRECHARGE_LEVEL)
  send_command(0x3a)
  send_command(COMMAND_VCOMH)
  send_command(0x3e)
  send_command(COMMAND_MASTER_CURRENT)
  send_command(0x06)
  send_command(COMMAND_CONTRASTA)
  send_command(0x91)
  send_command(COMMAND_CONTRASTB)
  send_command(0x50)
  send_command(COMMAND_CONTRASTC)
  send_command(0x7d)
  send_command(COMMAND_DISPLAY_ON)
  jalr zero, s1, 0
  nop

lcd_clear:
  mv s1, ra
  li t1, 96 * 64
lcd_clear_loop:
  li a0, 0xff0f
  jal lcd_send_data
  nop
  addi t1, t1, -1
  bnez t1, lcd_clear_loop
  nop
  jalr zero, s1, 0
  nop

lcd_clear_2:
  mv s1, ra
  li t1, 96 * 64
lcd_clear_loop_2:
  li a0, 0xf00f
  jal lcd_send_data
  nop
  addi t1, t1, -1
  bnez t1, lcd_clear_loop_2
  nop
  jalr zero, s1, 0
  nop

multiply:
  ret
  nop

mandelbrot:
  mv s1, ra
  jalr zero, s1, 0
  nop

;; lcd_send_cmd(a0)
lcd_send_cmd:
  li t0, LCD_RES
  sw t0, SPI_IO(gp)
  sw a0, SPI_TX(gp)
  li t0, SPI_START
  sw t0, SPI_CTL(gp)
lcd_send_cmd_wait:
  lw t0, SPI_CTL(gp)
  andi t0, t0, SPI_BUSY
  bnez t0, lcd_send_cmd_wait
  nop
  li t0, LCD_CS | LCD_RES
  sw t0, SPI_IO(gp)
  ret
  nop

;; lcd_send_data(a0)
lcd_send_data:
  li t0, LCD_DC | LCD_RES
  sw t0, SPI_IO(gp)
  sw a0, SPI_TX(gp)
  li t0, SPI_16 | SPI_START
  sw t0, SPI_CTL(gp)
lcd_send_data_wait:
  lw t0, SPI_CTL(gp)
  andi t0, t0, SPI_BUSY 
  bnez t0, lcd_send_data_wait
  nop
  li t0, LCD_CS | LCD_RES
  sw t0, SPI_IO(gp)
  ret
  nop

delay:
  li t0, 4000
delay_loop:
  addi t0, t0, -1
  bnez t0, delay_loop
  nop
  ret
  nop

