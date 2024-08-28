.riscv

.org 0x4000
main:
  li t0, 0xc089
  li t5, 100

  sb t5, 1(t0)
  lb t1, 1(t0)
  ;sh t5, 0(t0)
  ;lh t1, 2(t0)

  ebreak

