.riscv

.org 0x4000
main:
  li s0, 0x8000

main_loop:
  li a0, 1
  sb a0, 0x20(s0)
  jal delay
  nop

  li a0, 0
  sb a0, 0x20(s0)
  jal delay
  nop

  j main_loop
  nop

delay:
  li t0, 4000
delay_loop:
  addi t0, t0, -1
  bne t0, zero, delay_loop
  nop
  ret
  nop

