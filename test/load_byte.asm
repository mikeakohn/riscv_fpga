.riscv

.org 0x4000
main:
  lui x6, 0x12345
  ori x6, x6, 0x678

  li x5, 0x4008

  lb t1, 5(x5)
  ;lh t1, -2(x5)
  ebreak

