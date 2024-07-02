.riscv

.org 0x4000

main:
  ;li.w t1, 0x12345678
  ;li t3, 0x4000
  ;lw.pre t1, 4(t3)
  ;lw.post t1, 4(t3)

  li t1, 0x4000
  ;lw.pre t3, 4(t1)
  lw.post t3, 4(t1)
  ebreak

