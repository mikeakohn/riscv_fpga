.riscv

main:
  lui x5, 0x000
  ori x5, x5, 0x008

  addi x6, x0, 0x89
  sb x6, 5(x5)

  lb x7, 5(x5)
  ebreak

