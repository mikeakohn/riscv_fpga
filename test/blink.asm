.riscv

.org 0x4000
main:
  li s0, 0x8000

main_loop:
  li a0, 1
  sb a0, 0x20(s0)
  jal delay

  li a0, 0
  sb a0, 0x20(s0)
  jal delay

  j main_loop

delay:
  li t0, 0x30000
delay_loop:
  addi t0, t0, -1
  bne t0, zero, delay_loop
  ret

