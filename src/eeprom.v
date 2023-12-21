// Ferrati F100-L FPGA Soft Processor
//  Author: Michael Kohn
//   Email: mike@mikekohn.net
//     Web: https://www.mikekohn.net/
//   Board: iceFUN iCE40 HX8K
// License: MIT
//
// Copyright 2023 by Michael Kohn

// This module reads from an AT93C86A EEPROM chip.
// Data format: 110 AAAAAAAAAA DDDDDDDD where:
// Binary 110 is 3 bits telling the EEPROM to go into "read" mode.
// AAAAAAAAAA is 10 bits of the memory address being requested.
// DDDDDDDD is 8 bits clocked out of the EEPROM being the data at that address.

module eeprom
(
  input [10:0] address,
  input  strobe,
  input  raw_clk,
  output reg eeprom_cs,
  output reg eeprom_clk,
  output reg eeprom_di,
  input  eeprom_do,
  output ready,
  output reg [7:0] data_out
);

// Data sheet says 2.7v to 5.5v has a max speed of 1MHz. raw_clk should be
// 12MHz, so divide by 16.
//reg [4:0] clock_div;
reg [2:0] delay = 0;
//wire clk;
//assign clk = clock_div[4];

reg [13:0] command;
reg [3:0] count;
//reg running = 0;

parameter STATE_IDLE           = 0;
parameter STATE_SEND_ADDRESS_0 = 1;
parameter STATE_SEND_ADDRESS_1 = 2;
parameter STATE_READ_START     = 3;
parameter STATE_READ_DATA_0    = 4;
parameter STATE_READ_DATA_1    = 5;
parameter STATE_FINISH         = 6;

reg [2:0] state = STATE_FINISH;

assign ready = state == STATE_IDLE;

// To run the AT93C86A at a speed slower than 2MHz, divide the clock down.
/*
always @(posedge raw_clk) begin
  clock_div <= clock_div + 1;
end
*/

// State machine for reading the SPI-like EEPROM.
always @(posedge raw_clk) begin
  case (state)
    STATE_IDLE:
      begin
        // Wait for the CPU to strobe to start a read.
        if (strobe) begin
          command[13:11] <= 3'b110;
          command[10:0] <= address;
          count <= 14;
          eeprom_cs <= 1;
          state <= STATE_SEND_ADDRESS_0;
        end else begin
          eeprom_cs <= 0;
          eeprom_di <= 0;
          eeprom_clk <= 0;
        end
      end
    STATE_SEND_ADDRESS_0:
      begin
        // Clock out 3 bits of command and 11 bits of
        // address to the EEPROM.
        case (delay)
          0:
            begin
              count <= count - 1;
              eeprom_di <= command[13];
              command[13:1] <= command[12:0];
              eeprom_clk <= 0;
            end
          7:
            state <= STATE_SEND_ADDRESS_1;
        endcase

        delay <= delay + 1;
      end
    STATE_SEND_ADDRESS_1:
      begin
        eeprom_clk <= 1;

        if (delay == 7) begin
          if (count == 0) begin
            state <= STATE_READ_START;
          end else begin
            state <= STATE_SEND_ADDRESS_0;
          end
        end

        delay <= delay + 1;
      end
    STATE_READ_START:
      begin
        eeprom_clk <= 0;
        eeprom_di <= 0;
        count <= 8;
        state <= STATE_READ_DATA_0;
      end
    STATE_READ_DATA_0:
      begin
        // Clock in 8 bits of data from the EEPROM.
        case (delay)
          1:
            begin
              count <= count - 1;
              data_out[7:1] <= data_out[6:0];
              eeprom_clk <= 1;
            end
          7:
            state <= STATE_READ_DATA_1;
        endcase

        delay <= delay + 1;
      end
    STATE_READ_DATA_1:
      begin
        eeprom_clk <= 0;

        case (delay)
          0:
            data_out[0] <= eeprom_do;
          7:
            begin
              if (count == 0) begin
                state <= STATE_FINISH;
              end else begin
                state <= STATE_READ_DATA_0;
              end
            end
        endcase

        delay <= delay + 1;
      end
    STATE_FINISH:
      begin
        // Go back to IDLE state where the ready signal will tell the
        // the CPU that data is available.
        eeprom_cs <= 0;
        eeprom_di <= 0;
        state <= STATE_IDLE;
      end
  endcase
end

endmodule

