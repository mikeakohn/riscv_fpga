.riscv

.org 0x4000
main:
  li s0, 0x4008

main_loop:
  li a0, 1
  sb a0, 0(s0)
  jal delay
  nop

  li a0, 0
  sb a0, 0(s0)
  jal delay
  nop

  j main_loop
  nop

delay:
  li t0, 65536
delay_loop:
  addi t0, t0, -1
  beq t0, zero, delay_loop
  nop
  ret
  nop

