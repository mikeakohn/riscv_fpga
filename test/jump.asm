.riscv

.org 0x4000

main:
  li t1, 0xc000
  j blah
  ebreak

blah:
  li t1, 0xc008
  ebreak

