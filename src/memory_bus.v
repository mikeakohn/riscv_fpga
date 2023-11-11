// RISC-V FPGA Soft Processor
//  Author: Michael Kohn
//   Email: mike@mikekohn.net
//     Web: https://www.mikekohn.net/
//   Board: iceFUN iCE40 HX8K
// License: MIT
//
// Copyright 2022 by Michael Kohn

// The purpose of this module is to route reads and writes to the 4
// different memory banks. Originally the idea was to have ROM and RAM
// be SPI EEPROM (this may be changed in the future) so there would also
// need a "ready" signal that would pause the CPU until the data can be
// clocked in and out of of the SPI chips.

module memory_bus
(
  input  [15:0] address,
  input  [31:0] data_in,
  input  [3:0] write_mask,
  output reg [31:0] data_read,
  output reg data_ready,
  input bus_enable,
  input write_enable,
  input clk,
  input raw_clk,
  input double_clk,
  output speaker_p,
  output speaker_m,
  output ioport_0,
  input button_0,
  input reset
  //output reg [7:0] debug
);

wire [7:0] rom_data_out;
wire [7:0] ram_data_out;
wire [7:0] peripherals_data_out;
wire [7:0] block_ram_data_out;

wire [7:0] data_out;

wire [1:0] bank;
assign bank = address[15:14];

reg [7:0] ram_data_in;
reg [7:0] peripherals_data_in;
reg [7:0] block_ram_data_in;

reg [13:0] ea;
reg [2:0] byte_count = 0;

reg ram_write_enable;
reg peripherals_write_enable;
reg block_ram_write_enable;

wire block_ram_chip_enable;
assign block_ram_chip_enable = bus_enable & address[15] & address[14];

// Based on the selected bank of memory (address[15:14]) select if
// memory should read from ram.v, rom.v, peripherals.v or hardcoded 0.
// bank 00: ram
// bank 01: rom
// bank 10: peripherals
// bank 11: block_ram
assign data_out = bank[1] == 0 ?
  (bank[0] == 0 ? ram_data_out         : rom_data_out) :
  (bank[0] == 0 ? peripherals_data_out : block_ram_data_out);

// Based on the selected bank of memory, decided which module the
// memory write should be sent to.
always @(posedge clk) begin
  if (bus_enable) begin
    ea <= { address[13:2], byte_count[2:1] };

    if (write_enable) begin
      case (bank)
        2'b00:
          begin
            case (byte_count)
              0:
                begin
                  ram_data_in <= data_in[7:0];
                  ram_write_enable <= write_mask[0] == 0;
                end
              2:
                begin
                  ram_data_in <= data_in[15:8];
                  ram_write_enable <= write_mask[1] == 0;
                end
              4:
                begin
                  ram_data_in <= data_in[23:16];
                  ram_write_enable <= write_mask[2] == 0;
                end
              6:
                begin
                  ram_data_in <= data_in[31:24];
                  ram_write_enable <= write_mask[3] == 0;
                end
              default:
                begin
                  ram_write_enable <= 0;
                end
            endcase

            peripherals_write_enable <= 0;
            block_ram_write_enable <= 0;
          end
        2'b01:
          begin
            ram_write_enable <= 0;
            peripherals_write_enable <= 0;
            block_ram_write_enable <= 0;
          end
        2'b10:
          begin
            case (byte_count)
              0:
                begin
                  peripherals_data_in <= data_in[7:0];
                  peripherals_write_enable <= write_mask[0] == 0;
                end
              2:
                begin
                  peripherals_data_in <= data_in[15:8];
                  peripherals_write_enable <= write_mask[1] == 0;
                end
              4:
                begin
                  peripherals_data_in <= data_in[23:16];
                  peripherals_write_enable <= write_mask[2] == 0;
                end
              6:
                begin
                  peripherals_data_in <= data_in[31:24];
                  peripherals_write_enable <= write_mask[3] == 0;
                end
              default:
                begin
                  peripherals_write_enable <= 0;
                end
            endcase

            ram_write_enable <= 0;
            block_ram_write_enable <= 0;
          end
        2'b11:
          begin
            case (byte_count)
              0:
                begin
                  block_ram_data_in <= data_in[7:0];
                  block_ram_write_enable <= write_mask[0] == 0;
                end
              2:
                begin
                  block_ram_data_in <= data_in[15:8];
                  block_ram_write_enable <= write_mask[1] == 0;
                end
              4:
                begin
                  block_ram_data_in <= data_in[23:16];
                  block_ram_write_enable <= write_mask[2] == 0;
                end
              6:
                begin
                  block_ram_data_in <= data_in[31:24];
                  block_ram_write_enable <= write_mask[3] == 0;
                end
              default:
                begin
                  block_ram_write_enable <= 0;
                end
            endcase

            ram_write_enable <= 0;
            peripherals_write_enable <= 0;
          end
      endcase

      data_ready <= byte_count == 7 ? 1 : 0;
      byte_count <= byte_count + 1;
    end else begin
      case (byte_count)
        1: data_read[7:0]   <= data_out;
        3: data_read[15:8]  <= data_out;
        5: data_read[23:16] <= data_out;
        7: data_read[31:24] <= data_out;
      endcase

      data_ready <= byte_count == 7 ? 1 : 0;
      byte_count <= byte_count + 1;
    end
  end else begin
    ram_write_enable <= 0;
    peripherals_write_enable <= 0;
    block_ram_write_enable <= 0;
    data_ready <= 0;
    byte_count <= 0;
  end
end

rom rom_0(
  .address   ( { address[9:2], byte_count[2:1] } ),
  .data_out  (rom_data_out)
);

ram ram_0(
  .address      ( { address[9:2], byte_count[2:1] } ),
  .data_in      (ram_data_in),
  .data_out     (ram_data_out),
  .write_enable (ram_write_enable),
  .clk          (clk)
  //.double_clk   (double_clk)
  //.debug        (debug)
);

peripherals peripherals_0(
  .address      ( { address[5:2], byte_count[2:1] } ),
  .data_in      (peripherals_data_in),
  .data_out     (peripherals_data_out),
  .write_enable (peripherals_write_enable),
  .clk          (clk),
  .raw_clk      (raw_clk),
  .speaker_p    (speaker_p),
  .speaker_m    (speaker_m),
  .ioport_0     (ioport_0),
  .button_0     (button_0),
  .reset        (reset)
);

block_ram block_ram_0(
  .address      ( { address[13:2], byte_count[2:1] } ),
  .data_in      (block_ram_data_in),
  .data_out     (block_ram_data_out),
  .chip_enable  (block_ram_chip_enable),
  .write_enable (block_ram_write_enable),
  .clk          (clk),
  .double_clk   (double_clk)
);

endmodule

