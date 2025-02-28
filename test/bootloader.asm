; XMODEM Bootloader for Michael Kohn's RISC-V FPGA Core
; Written by Joe Davisson

; Tested with:
; - iceFUN iCE40 HX8K FPGA
; - Adafruit USB to TTL serial cable
; - Minicom 2.9 (9600 baud, 8N2, no handshaking)

; cable connnections:
;  - RED   - 5V (not connected)
;  - BLACK - GND
;  - WHITE - RX (goes to H3)
;  - GREEN - TX (goes to G3)

; packet format:
;  - start of header (1 byte)
;  - packet number (1 byte)
;  - inverse packet_number (1 byte)
;  - data (128 bytes)
;  - checksum (1 byte)

.riscv

.include "test/registers.inc"

SOH equ 0x01  ; start of header
EOT equ 0x04  ; end of transmission
ACK equ 0x06  ; acknowledged
NAK equ 0x15  ; not acknowledged

address equ s10
packet_count equ s11

; program is loaded into RAM here
ram_start equ 0x0000

; program loader
.org 0x4000

start:
  ; UART base
  li gp, 0x8000

message:
  li s0, message_text
message_loop:
  lbu a0, (s0)
  beqz a0, button_press
  jal write_uart
  addi s0, s0, 1
  j message_loop

button_press:
  lbu s0, BUTTON(gp)
  andi s0, s0, 1
  beqz s0, button_press

button_release:
  lbu s0, BUTTON(gp)
  andi s0, s0, 1
  bnez s0, button_release

begin_transfer:
  li address, ram_start
  li packet_count, 1

  li a0, NAK
  jal write_uart

get_next_packet:
  jal read_uart
  li s0, SOH
  beq a0, s0, check_packet_count
  li s0, EOT
  bne a0, s0, get_next_packet_error
  j done
get_next_packet_error:
  j error

check_packet_count:
  jal read_uart
  beq a0, packet_count, check_packet_count_inverse
  j error

check_packet_count_inverse:
  mv s0, a0
  jal read_uart
  add s0, s0, a0
  li s1, 0xff
  beq s0, s1, get_packet_data
  j error

get_packet_data:
  mv s0, address
  mv s1, address
  addi s1, s1, 128
get_packet_data_loop:
  jal read_uart
  sb a0, (s0)
  addi s0, s0, 1
  bne s0, s1, get_packet_data_loop

test_checksum:
  jal read_uart
  mv s0, address
  mv s1, address
  addi s1, s1, 128
  li s2, 0
test_checksum_loop:
  lbu s4, (s0)
  add s2, s2, s4
  addi s0, s0, 1
  bne s0, s1, test_checksum_loop
  andi s2, s2, 0xff
  beq s2, a0, update_address
  j error

update_address:
  addi address, address, 128
  addi packet_count, packet_count, 1
  andi packet_count, packet_count, 0xff

  li a0, ACK
  jal write_uart
  j get_next_packet

done:
  li a0, ACK
  jal write_uart

  ; run program
  j ram_start

error:
  li a0, NAK
  jal write_uart
  j get_next_packet

read_uart:
  lbu t0, UART_CTL(gp)
  andi t0, t0, UART_RX_READY
  beqz t0, read_uart
  lbu a0, UART_RX(gp)
  ret

write_uart:
  sb a0, UART_TX(gp)
write_uart_wait:
  lbu t0, UART_CTL(gp)
  andi t0, t0, UART_TX_BUSY
  bnez t0, write_uart_wait
  ret

message_text:
  .ascii "Ready.\r\n\0\0\0\0"

