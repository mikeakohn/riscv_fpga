.riscv

.org 0x4000
main:
  li t0, 0xc089
  li t1, 100

  sb t1, 5(t0)
  lb t2, 5(t0)
  ebreak

