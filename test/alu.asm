.riscv

.org 0x4000

main:
  li t1, 0xc000
  slli t1, t1, 16
  srai t1, t1, 18
  ori x6, x0, 5
  ebreak

