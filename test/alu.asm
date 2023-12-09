.riscv

.org 0x4000
main:
  ;li t0, 100
  ;addi t0, t0, -1
  li t1, -1
  li t2, 4
  slt t0, t1, t2
  ebreak

