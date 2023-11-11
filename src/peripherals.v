// RISC-V FPGA Soft Processor
//  Author: Michael Kohn
//   Email: mike@mikekohn.net
//     Web: https://www.mikekohn.net/
//   Board: iceFUN iCE40 HX8K
// License: MIT
//
// Copyright 2023 by Michael Kohn

module peripherals
(
  input [5:0] address,
  input [7:0] data_in,
  output reg [7:0] data_out,
  input write_enable,
  input clk,
  input raw_clk,
  output speaker_p,
  output speaker_m,
  output ioport_0,
  input button_0,
  input reset
);

reg [7:0] storage [3:0];

reg [15:0] speaker_value_high;
reg [15:0] speaker_value_curr;
reg [7:0]  buttons;

reg speaker_toggle;
reg speaker_value_p;
reg speaker_value_m;
assign speaker_p = speaker_value_p;
assign speaker_m = speaker_value_m;

reg [7:0] ioport = 0;
assign ioport_0 = ioport[0];

always @(button_0) begin
  buttons = { 7'b0, ~button_0 };
end

always @(posedge raw_clk) begin
  if (speaker_value_high == 16'b0) begin
    speaker_value_curr <= 0;
    speaker_value_p <= 0;
    speaker_value_m <= 0;
  end else begin
    speaker_value_curr <= speaker_value_curr + 1'b1;

    if (speaker_value_curr == speaker_value_high) begin
      speaker_value_curr <= 0;
      speaker_toggle <= ~speaker_toggle;

      speaker_value_p <= speaker_toggle;
      speaker_value_m <= ~speaker_toggle;
    end
  end
end

always @(posedge clk) begin
  if (reset) speaker_value_high <= 0;

  if (write_enable) begin
    case (address[5:0])
      8: ioport <= data_in;
      9:
        begin
          case (data_in)
            60: speaker_value_high <= 45866; // C4  261.63
            61: speaker_value_high <= 43293; // C#4 277.18
            62: speaker_value_high <= 40863; // D4 293.66
            63: speaker_value_high <= 38569; // D#4 311.13
            64: speaker_value_high <= 36404; // E4 329.63
            65: speaker_value_high <= 34361; // F4 349.23
            66: speaker_value_high <= 32433; // F#4 369.99
            67: speaker_value_high <= 30612; // G4 392.00
            68: speaker_value_high <= 28894; // G#4 415.30
            69: speaker_value_high <= 27272; // A4  440.00
            70: speaker_value_high <= 25742; // A#4 466.16
            71: speaker_value_high <= 24297; // B4 493.88
            72: speaker_value_high <= 22933; // C5 523.25
            73: speaker_value_high <= 21646; // C#5 554.37
            74: speaker_value_high <= 20431; // D5 587.33
            75: speaker_value_high <= 19284; // D#5 622.25
            76: speaker_value_high <= 18202; // E5 659.26
            77: speaker_value_high <= 17180; // F5 698.46
            78: speaker_value_high <= 16216; // F#5 739.99
            79: speaker_value_high <= 15306; // G5 783.99
            80: speaker_value_high <= 14447; // G#5 830.61
            81: speaker_value_high <= 13636; // A5 880.00
            82: speaker_value_high <= 12870; // A#5 932.33
            83: speaker_value_high <= 12148; // B5 987.77
            84: speaker_value_high <= 11466; // C6 1046.50
            85: speaker_value_high <= 10823; // C#6 1108.73
            86: speaker_value_high <= 10215; // D6 1174.66
            87: speaker_value_high <= 9642;  // D#6 1244.51
            88: speaker_value_high <= 9101;  // E6 1318.51
            89: speaker_value_high <= 8590;  // F6 1396.91
            90: speaker_value_high <= 8108;  // F#6 1479.98
            91: speaker_value_high <= 7653;  // G6 1567.98
            92: speaker_value_high <= 7223;  // G#6 1661.22
            93: speaker_value_high <= 6818;  // A6 1760.00
            94: speaker_value_high <= 6435;  // A#6 1864.66
            95: speaker_value_high <= 6074;  // B6 1975.53
            96: speaker_value_high <= 5733;  // C7 2093.00
            default: speaker_value_high <= 0;
          endcase
        end
    endcase
  end else begin
    case (address[5:0])
      0: data_out <= buttons;
    endcase
  end
end

endmodule

