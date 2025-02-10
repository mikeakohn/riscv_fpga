
;; Registers.
BUTTON      equ 0x00
SPI_TX      equ 0x04
SPI_RX      equ 0x08
SPI_CTL     equ 0x0c
PORT0       equ 0x20
SOUND       equ 0x24
SPI_IO      equ 0x28
UART_TX     equ 0x38
UART_RX     equ 0x3c
UART_STATUS equ 0x40

;; Bits in SPI_CTL.
SPI_BUSY    equ 0x01
SPI_START   equ 0x02
SPI_16      equ 0x04

;; Bits in SPI_IO.
LCD_RES     equ 0x01
LCD_DC      equ 0x02
LCD_CS      equ 0x04

;; Bits in PORT0
LED0        equ 0x01

