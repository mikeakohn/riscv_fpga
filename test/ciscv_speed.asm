.riscv

.org 0xc000

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

.define mandel mulw

.macro send_command(value)
  li a0, value
  jal lcd_send_cmd
.endm

.macro square_fixed(result, var)
.scope
  mv a1, var
  li t1, 0x8000
  and t1, t1, a1
  beqz t1, not_signed
  li t1, 0xffff
  xor a1, a1, t1
  addi a1, a1, 1
  and a1, a1, t1
not_signed:
  mv a2, a1
  jal multiply
  mv result, a3
.ends
.endm

.macro multiply_signed(var_0, var_1)
.scope
  mv a1, var_0
  mv a2, var_1
  li t2, 0x0000
  li t1, 0x8000
  and t1, t1, a1
  beqz t1, not_signed_0
  xor t2, t2, t1
  xor a1, a1, t3
  addi a1, a1, 1
  and a1, a1, t3
not_signed_0:
  li t1, 0x8000
  and t1, t1, a2
  beqz t1, not_signed_1
  xor t2, t2, t1
  xor a2, a2, t3
  addi a2, a2, 1
  and a2, a2, t3
not_signed_1:
  jal multiply
  beqz t2, dont_add_sign
  xor a3, a3, t3
  addi a3, a3, 1
  and a3, a3, t3
dont_add_sign:
.ends
.endm

start:
  ;; Point gp to peripherals.
  li gp, 0x8000
  ;; Clear LED.
  li t0, 1
  sw t0, PORT0(gp)
  li s11, 0

main:
  jal lcd_init
  jal lcd_clear
  ;jal lcd_clear_2

  li s2, 0
main_while_1:
  lw t0, BUTTON(gp)
  andi t0, t0, 1
  bnez t0, run
  xori s2, s2, 1
  sb s2, PORT0(gp)
  jal delay

  j main_while_1

run:
  jal lcd_clear_3

  ;; Copy memory using RISC-V only.
  li t0, 300
run_riscv_outer_loop:
  li t1, 0x4000
  li t2, 0xc000
  li t3, 4096
run_riscv_copy_loop:
  lb t4, 0(t1)
  sb t4, 0(t2)
  addi t1, t1, 1
  addi t2, t2, 1
  addi t3, t3, -1
  bne zero, t3, run_riscv_copy_loop
  addi t0, t0, -1
  bne zero, t0, run_riscv_outer_loop

  jal lcd_clear_2

  ;; Copy memory using CISC-V extra instructions.
  li t0, 300
run_ciscv_outer_loop:
  li t1, 0x4000
  li t2, 0xc000
  li t3, 4096
run_ciscv_copy_loop:
  lb.post t4, 1(t1)
  sb.post t4, 1(t2)
  addi t3, t3, -1
  bne zero, t3, run_ciscv_copy_loop
  addi t0, t0, -1
  bne zero, t0, run_ciscv_outer_loop

  jal lcd_clear
  j main_while_1

lcd_init:
  mv s1, ra
  li t0, LCD_CS
  sw t0, SPI_IO(gp)
  jal delay
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

lcd_clear:
  mv s1, ra
  li t1, 96 * 64
  li a0, 0xff0f
lcd_clear_loop:
  jal lcd_send_data
  addi t1, t1, -1
  bnez t1, lcd_clear_loop
  jalr zero, s1, 0

lcd_clear_2:
  mv s1, ra
  li t1, 96 * 64
  li a0, 0xf00f
lcd_clear_loop_2:
  jal lcd_send_data
  addi t1, t1, -1
  bnez t1, lcd_clear_loop_2
  jalr zero, s1, 0

lcd_clear_3:
  mv s1, ra
  li t1, 96 * 64
  li a0, 0xf0ff
lcd_clear_loop_3:
  jal lcd_send_data
  addi t1, t1, -1
  bnez t1, lcd_clear_loop_3
  jalr zero, s1, 0

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
  li t0, LCD_CS | LCD_RES
  sw t0, SPI_IO(gp)
  ret

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
  li t0, LCD_CS | LCD_RES
  sw t0, SPI_IO(gp)
  ret

delay:
  li t0, 65536
delay_loop:
  addi t0, t0, -1
  bnez t0, delay_loop
  ret

