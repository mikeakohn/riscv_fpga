.riscv

.org 0x4000
main:
  lui x6, 0x12345
  ori x6, x6, 0x678
  lui x5, 0x4
  ori x5, x5, 0x008
  lb x7, 5(x5)
  lb x8, -3(x5)
  ebreak

