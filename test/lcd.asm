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
  nop
.endm

.macro square_fixed(result, var)
.scope
  mv a1, var
  li t1, 0x8000
  and t1, t1, a1
  beqz t1, not_signed
  nop
  li t1, 0xffff
  xor a1, a1, t1
  addi a1, a1, 1
  and a1, a1, t1
not_signed:
  mv a2, a1
  jal multiply
  nop
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
  nop
  xor t2, t2, t1
  xor a1, a1, t3
  addi a1, a1, 1
  and a1, a1, t3
not_signed_0:
  li t1, 0x8000
  and t1, t1, a2
  beqz t1, not_signed_1
  nop
  xor t2, t2, t1
  xor a2, a2, t3
  addi a2, a2, 1
  and a2, a2, t3
not_signed_1:
  jal multiply
  nop
  beqz t2, dont_add_sign
  nop
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
  nop
  jal lcd_clear
  nop
  ;jal lcd_clear_2
  ;nop

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
  xori s11, s11, 1
  beqz s11, run_hw
  nop
  jal ra, mandelbrot
  nop
  li s2, 1
  j main_while_1
  nop

run_hw:
  jal ra, mandelbrot_hw
  nop
  li s2, 1
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
  li a0, 0xff0f
lcd_clear_loop:
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
  li a0, 0xf00f
lcd_clear_loop_2:
  jal lcd_send_data
  nop
  addi t1, t1, -1
  bnez t1, lcd_clear_loop_2
  nop
  jalr zero, s1, 0
  nop

;; multiply(a1, a2) -> a3
multiply:
  ;mv a3, a1
  ;srli a3, a3, 1
  ;ret
  ;nop
  li a3, 0
  li t0, 16
multiply_repeat:
  andi a4, a1, 1
  beqz a4, multiply_ignore_bit
  nop
  add a3, a3, a2
multiply_ignore_bit:
  slli a2, a2, 1
  srli a1, a1, 1
  addi t0, t0, -1
  bnez t0, multiply_repeat
  nop
  srai a3, a3, 10
  li t0, 0xffff
  and a3, a3, t0
  ret
  nop

mandelbrot:
  mv s1, ra

  ;; final int DEC_PLACE = 10;
  ;; final int r0 = (-2 << DEC_PLACE);
  ;; final int i0 = (-1 << DEC_PLACE);
  ;; final int r1 = (1 << DEC_PLACE);
  ;; final int i1 = (1 << DEC_PLACE);
  ;; final int dx = (r1 - r0) / 96; (0x0020)
  ;; final int dy = (i1 - i0) / 64; (0x0020)

  ;; Mask for 16 bit.
  li t3, 0xffff

  ;; for (y = 0; y < 64; y++)
  li s3, 64
  ;; int i = -1 << 10;
  li s5, 0xfc00
mandelbrot_for_y:

  ;; for (x = 0; x < 96; x++)
  li s2, 96
  ;; int r = -2 << 10;
  li s4, 0xf800
mandelbrot_for_x:
  ;; zr = r;
  ;; zi = i;
  mv s6, s4
  mv s7, s5

  ;; for (int count = 0; count < 15; count++)
  li a0, 15
mandelbrot_for_count:
  ;; zr2 = (zr * zr) >> DEC_PLACE;
  square_fixed(a6, s6)

  ;; zi2 = (zi * zi) >> DEC_PLACE;
  square_fixed(a7, s7)

  ;; if (zr2 + zi2 > (4 << DEC_PLACE)) { break; }
  ;; cmp does: 4 - (zr2 + zi2).. if it's negative it's bigger than 4.
  add a5, a6, a7
  li t0, 4 << 10
  slt a5, a5, t0
  beqz a5, mandelbrot_stop
  nop

  ;; tr = zr2 - zi2;
  sub a5, a6, a7
  and a5, a5, t3

  ;; ti = ((zr * zi) >> DEC_PLACE) << 1;
  multiply_signed(s6, s7)
  slli a3, a3, 1
  ;mv t1, a3

  ;; zr = tr + curr_r;
  add s6, a5, s4
  and s6, s6, t3

  ;; zi = ti + curr_i;
  add s7, a3, s5
  and s7, s7, t3

  addi a0, a0, -1
  bnez a0, mandelbrot_for_count
  nop
mandelbrot_stop:

  slli a0, a0, 1
  li t0, colors
  add a0, t0, a0
  lw a0, 0(a0)

  jal lcd_send_data
  nop

  addi s4, s4, 0x0020
  and s4, s4, t3
  addi s2, s2, -1
  bnez s2, mandelbrot_for_x
  nop

  addi s5, s5, 0x0020
  and s5, s5, t3
  addi s3, s3, -1
  bnez s3, mandelbrot_for_y
  nop

  jalr zero, s1, 0
  nop

mandelbrot_hw:
  mv s1, ra

  ;; final int DEC_PLACE = 10;
  ;; final int r0 = (-2 << DEC_PLACE);
  ;; final int i0 = (-1 << DEC_PLACE);
  ;; final int r1 = (1 << DEC_PLACE);
  ;; final int i1 = (1 << DEC_PLACE);
  ;; final int dx = (r1 - r0) / 96; (0x0020)
  ;; final int dy = (i1 - i0) / 64; (0x0020)

  ;; Mask for 16 bit.
  li t3, 0xffff

  ;; for (y = 0; y < 64; y++)
  li s3, 64
  ;; int i = -1 << 10;
  li s5, 0xfc00
mandelbrot_hw_for_y:

  ;; for (x = 0; x < 96; x++)
  li s2, 96
  ;; int r = -2 << 10;
  li s4, 0xf800
mandelbrot_hw_for_x:

  mandel a0, s4, s5

  slli a0, a0, 1
  li t0, colors
  add a0, t0, a0
  lw a0, 0(a0)

  jal lcd_send_data
  nop

  addi s4, s4, 0x0020
  and s4, s4, t3
  addi s2, s2, -1
  bnez s2, mandelbrot_hw_for_x
  nop

  addi s5, s5, 0x0020
  and s5, s5, t3
  addi s3, s3, -1
  bnez s3, mandelbrot_hw_for_y
  nop

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
  li t0, 65536
delay_loop:
  addi t0, t0, -1
  bnez t0, delay_loop
  nop
  ret
  nop

colors:
  dc16 0x0000
  dc16 0x000c
  dc16 0x0013
  dc16 0x0015
  dc16 0x0195
  dc16 0x0335
  dc16 0x04d5
  dc16 0x34c0
  dc16 0x64c0
  dc16 0x9cc0
  dc16 0x6320
  dc16 0xa980
  dc16 0xaaa0
  dc16 0xcaa0
  dc16 0xe980
  dc16 0xf800

