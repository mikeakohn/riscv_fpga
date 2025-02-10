.riscv

.include "test/registers.inc"

.org 0x4000

main:
  li gp, 0x8000

  li t0, 1
  sw t0, PORT0(gp)

  li t0, 'x'
  sw t0, UART_TX(gp)
  jal delay

  li t0, 'y'
  sw t0, UART_TX(gp)
  jal delay

  li t0, 'Z'
  sw t0, UART_TX(gp)
  jal delay

  li t0, 0
  sw t0, PORT0(gp)

while_1:
  j while_1

delay:
  li t0, 4000
delay_loop:
  addi t0, t0, -1
  bnez t0, delay_loop
  ret

