// RISC-V FPGA Soft Processor
//  Author: Michael Kohn
//   Email: mike@mikekohn.net
//     Web: https://www.mikekohn.net/
//   Board: iceFUN iCE40 HX8K
// License: MIT
//
// Copyright 2023-2025 by Michael Kohn

module riscv
(
  output [7:0] leds,
  output [3:0] column,
  input raw_clk,
  output speaker_p,
  output speaker_m,
  output ioport_0,
  output ioport_1,
  output ioport_2,
  output ioport_3,
  input  button_reset,
  input  button_halt,
  input  button_program_select,
  input  button_0,
  output spi_clk,
  output spi_mosi,
  input  spi_miso
);

// iceFUN 8x4 LEDs used for debugging.
reg [7:0] leds_value;
reg [3:0] column_value;

assign leds = leds_value;
assign column = column_value;

// Memory bus (ROM, RAM, peripherals).
reg [15:0] mem_address = 0;
reg [31:0] mem_write = 0;
reg [3:0] mem_write_mask = 0;
wire [31:0] mem_read;
//wire mem_data_ready;
reg mem_bus_enable = 0;
reg mem_write_enable = 0;

//wire [7:0] mem_debug;

// Clock.
reg [21:0] count = 0;
reg [4:0] state = 0;
reg [3:0] clock_div;
reg [14:0] delay_loop;
wire clk;
assign clk = clock_div[0];

// Registers.
reg [31:0] registers [31:0];
reg [15:0] pc = 0;
reg [15:0] pc_current = 0;

// Instruction
reg [31:0] instruction;
wire [3:0] op;
wire [2:0] op_lo;
wire [4:0] rd;
wire [4:0] rs1;
wire [4:0] rs2;
wire [4:0] shamt;
wire [2:0] funct3;
wire [6:0] funct7;
wire signed [12:0] branch_offset;
wire [2:0] memory_size;
assign op  = instruction[6:3];
assign op_lo = instruction[2:0];
assign rd  = instruction[11:7];
assign rs1 = instruction[19:15];
assign rs2 = instruction[24:20];
assign shamt = instruction[24:20];
assign funct3 = instruction[14:12];
assign funct7 = instruction[31:25];

assign branch_offset = {
  instruction[31],
  instruction[7],
  instruction[30:25],
  instruction[11:8],
  1'b0
};

wire [31:0] upper_immediate;
assign upper_immediate = { instruction[31:12], 12'h000 };

wire [11:0] uimm;
wire signed [11:0] simm;
assign uimm = instruction[31:20];
assign simm = instruction[31:20];

wire signed [11:0] st_offset;
assign st_offset = { funct7, instruction[11:7] };

wire signed [11:0] ls_offset;
assign ls_offset = op[2] == 0 ? simm : st_offset;

wire [15:0] branch_address;
assign branch_address = $signed(pc_current) + branch_offset;
reg do_branch;

reg [31:0] source;
reg [31:0] result;
reg [31:0] arg_1;
wire [31:0] alu_result;

wire [31:0] wb_result;
assign wb_result = is_alu ? alu_result : result;

wire [2:0] alu_op;
assign alu_op = funct3;
reg is_alt;
reg is_alu;
reg [1:0] wb;

// Load / Store.
assign memory_size = instruction[14:12];
reg [31:0] ea;
//reg [31:0] ea_aligned;

// Lower 6 its of the instruction.
//wire [5:0] opcode;
//assign opcode = instruction[5:0];

// Debug.
//reg [7:0] debug_0 = 0;
//reg [7:0] debug_1 = 0;
//reg [7:0] debug_2 = 0;
//reg [7:0] debug_3 = 0;

// This block is simply a clock divider for the raw_clk.
always @(posedge raw_clk) begin
  count <= count + 1;
  clock_div <= clock_div + 1;
end

// Debug: This block simply drives the 8x4 LEDs.
always @(posedge raw_clk) begin
  case (count[9:7])
    3'b000: begin column_value <= 4'b0111; leds_value <= ~registers[6][7:0]; end
    3'b010: begin column_value <= 4'b1011; leds_value <= ~registers[6][15:8]; end
    //3'b010: begin column_value <= 4'b1011; leds_value <= ~instruction[7:0]; end
    //3'b010: begin column_value <= 4'b1011; leds_value <= ~pc[15:8]; end
    3'b100: begin column_value <= 4'b1101; leds_value <= ~pc[7:0]; end
    3'b110: begin column_value <= 4'b1110; leds_value <= ~state; end
    default: begin column_value <= 4'b1111; leds_value <= 8'hff; end
  endcase
end

parameter STATE_RESET        = 0;
parameter STATE_DELAY_LOOP   = 1;
parameter STATE_FETCH_OP_0   = 2;
parameter STATE_FETCH_OP_1   = 3;
parameter STATE_START_DECODE = 4;

parameter STATE_FETCH_LOAD   = 5;
parameter STATE_STORE        = 6;

parameter STATE_CONTROL      = 7;
parameter STATE_LUI          = 8;
parameter STATE_ALU_IMM      = 9;
parameter STATE_ALU_REG      = 10;

parameter STATE_BRANCH       = 11;
parameter STATE_WRITEBACK    = 12;

parameter STATE_DEBUG        = 13;
parameter STATE_ERROR        = 14;
parameter STATE_HALTED       = 15;

parameter ALU_OP_ADD   = 0;
parameter ALU_OP_SLL   = 1;
parameter ALU_OP_SLT   = 2;
parameter ALU_OP_SLTU  = 3;
parameter ALU_OP_XOR   = 4;
parameter ALU_OP_SRL   = 5;
parameter ALU_OP_OR    = 6;
parameter ALU_OP_AND   = 7;

parameter WB_NONE  = 0;
parameter WB_RD    = 1;
parameter WB_PC    = 2;
//parameter WB_BR    = 3;

/*
function signed [31:0] sign12(input signed [11:0] data);
  sign12 = data;
endfunction
*/

//`define sign_imm12(data) { {20{ data[31] }}, data[31:20] }

// This block is the main CPU instruction execute state machine.
always @(posedge clk) begin
  if (!button_reset)
    state <= STATE_RESET;
  else if (!button_halt)
    state <= STATE_HALTED;
  else
    case (state)
      STATE_RESET:
        begin
          mem_address <= 0;
          mem_write_enable <= 0;
          mem_write <= 0;
          instruction <= 0;
          delay_loop <= 12000;
          state <= STATE_DELAY_LOOP;
        end
      STATE_DELAY_LOOP:
        begin
          // This is probably not needed. The chip starts up fine without it.
          if (delay_loop == 0) begin
            pc <= 16'h4000;
            state <= STATE_FETCH_OP_0;
          end else begin
            delay_loop <= delay_loop - 1;
          end
        end
      STATE_FETCH_OP_0:
        begin
          registers[0] <= 0;
          wb        <= WB_RD;
          is_alt    <= 0;
          is_alu    <= 0;
          //alu_op    <= ALU_OP_NONE;
          do_branch <= 0;
          mem_bus_enable <= 1;
          mem_write_enable <= 0;
          mem_address <= pc;
          pc_current = pc;
          pc <= pc + 4;
          state <= STATE_FETCH_OP_1;
        end
      STATE_FETCH_OP_1:
        begin
          mem_bus_enable <= 0;
          instruction <= mem_read;
          state <= STATE_START_DECODE;
        end
      STATE_START_DECODE:
        begin
          case (op_lo)
            3'b011:
              if (op[3] == 0) begin
                case (op[2:0])
                  3'b000:
                    begin
                      // Load.
                      mem_bus_enable <= 1;
                      state <= STATE_FETCH_LOAD;
                    end
                  3'b010:
                    begin
                      // ALU Immediate.
                      is_alu <= 1;
                      state <= STATE_ALU_IMM;
                    end
                  3'b100:
                    begin
                      // Store.
                      state <= STATE_STORE;
                    end
                  3'b110:
                    begin
                      // ALU Reg.
                      is_alu <= 1;
                      state <= STATE_ALU_REG;
                    end
                  default:
                    begin
                      state <= STATE_ERROR;
                    end
                endcase
              end else begin
                if (op[2:0] == 3'b100)
                  // branch.
                  state <= STATE_BRANCH;
                else
                  // 3'b110 is ebreak.
                  state <= STATE_HALTED;
              end
            3'b111:
              begin
                // lui, auipc, jal, jalr
                state <= op[3] == 0 ? STATE_LUI : STATE_CONTROL;
              end
            default:
              begin
                state <= STATE_ERROR;
              end
          endcase

          source = registers[rs1];
          ea = source + ls_offset;
          mem_address = ea;
        end
      STATE_FETCH_LOAD:
        begin
            mem_bus_enable <= 0;

            case (memory_size[1:0])
              3'b00:
                begin
                  case (ea[1:0])
                    0:
                      begin
                        result[7:0]  <= mem_read[7:0];
                        result[31:8] <= { {24{ mem_read[7] & ~memory_size[2] } } };
                      end
                    1:
                      begin
                        result[7:0]  <= mem_read[15:8];
                        result[31:8] <= { {24{ mem_read[15] & ~memory_size[2] } } };
                      end
                    2:
                      begin
                        result[7:0]  <= mem_read[23:16];
                        result[31:8] <= { {24{ mem_read[23] & ~memory_size[2] } } };
                      end
                    3:
                      begin
                        result[7:0]  <= mem_read[31:24];
                        result[31:8] <= { {24{ mem_read[31] & ~memory_size[2] } } };
                      end
                  endcase
                end
              3'b01:
                begin
                  case (ea[1])
                    0:
                      begin
                        result[15:0]  <= mem_read[15:0];
                        result[31:16] <= { {16{ mem_read[15] & ~memory_size[2] } } };
                      end
                    1:
                      begin
                        result[15:0]  <= mem_read[31:16];
                        result[31:16] <= { {16{ mem_read[31] & ~memory_size[2] } } };
                      end
                  endcase
                end
              3'b10:
                begin
                  result <= mem_read;
                end
            endcase

            state <= STATE_WRITEBACK;
        end
      STATE_STORE:
        begin
          case (funct3)
            3'b000:
              begin
                mem_write[7:0]   <= registers[rs2][7:0];
                mem_write[15:8]  <= registers[rs2][7:0];
                mem_write[23:16] <= registers[rs2][7:0];
                mem_write[31:24] <= registers[rs2][7:0];

                mem_write_mask[0] <= ~(ea[1:0] == 0);
                mem_write_mask[1] <= ~(ea[1:0] == 1);
                mem_write_mask[2] <= ~(ea[1:0] == 2);
                mem_write_mask[3] <= ~(ea[1:0] == 3);
              end
            3'b001:
              begin
                mem_write[15:0]  <= registers[rs2][15:0];
                mem_write[31:16] <= registers[rs2][15:0];

                mem_write_mask[0] <= ea[1:0] == 2;
                mem_write_mask[1] <= ea[1:0] == 2;
                mem_write_mask[2] <= ea[1:0] == 0;
                mem_write_mask[3] <= ea[1:0] == 0;
              end
            3'b010:
              begin
                mem_write <= registers[rs2];
                mem_write_mask <= 4'b0000;
              end
          endcase

          wb <= WB_NONE;
          mem_write_enable <= 1;
          mem_bus_enable   <= 1;
          state <= STATE_WRITEBACK;
        end
      STATE_CONTROL:
        begin
          if (op[0] == 0)
            // jalr.
            result <= ($signed(source) + simm) & 16'hfffc;
          else
            // jal.
            result <= $signed(pc_current) + $signed( {
              instruction[31],
              instruction[19:12],
              instruction[20],
              instruction[30:21],
              1'b0
            } );

          registers[rd] <= pc;
          wb <= WB_PC;
          do_branch <= 1;
          state <= STATE_WRITEBACK;
        end
      STATE_LUI:
        begin
          if (op[2] == 0) begin
            // auipc.
            result <= pc_current + { instruction[31:12], 12'b0 };
          end else begin
            // lui.
            result <= { instruction[31:12], 12'h000 };
          end

          state <= STATE_WRITEBACK;
        end
      STATE_ALU_IMM:
        begin
          // ALU immediate.
          if (alu_op == ALU_OP_SLTU)
            arg_1 <= uimm;
          else if (alu_op == ALU_OP_SLL || alu_op == ALU_OP_SRL)
            arg_1 <= shamt;
          else
            arg_1 <= simm;

          is_alt <= funct7[5] && funct3 == ALU_OP_SRL;
          state <= STATE_WRITEBACK;
        end
      STATE_ALU_REG:
        begin
          // ALU reg, reg.
          arg_1 <= registers[rs2];
          is_alt <= funct7[5];
          state <= STATE_WRITEBACK;
        end
      STATE_BRANCH:
        begin
          case (funct3)
            3'b000:
              // beq.
              if (source == registers[rs2]) do_branch <= 1;
            3'b001:
              // bne.
              if (source != registers[rs2]) do_branch <= 1;
            3'b100:
              // blt.
              if ($signed(source) < $signed(registers[rs2])) do_branch <= 1;
            3'b101:
              // bge.
              if ($signed(source) >= $signed(registers[rs2])) do_branch <= 1;
            3'b110:
              // bltu.
              if (source < registers[rs2]) do_branch <= 1;
            3'b111:
              // bgeu.
              if (source >= registers[rs2]) do_branch <= 1;
          endcase

          result <= branch_address;
          wb     <= WB_PC;

          state <= STATE_WRITEBACK;
        end
      STATE_WRITEBACK:
        begin
          if (wb == WB_RD) registers[rd] <= wb_result;
          if (wb == WB_PC) if (do_branch) pc <= result;

          mem_bus_enable   <= 0;
          mem_write_enable <= 0;

          state <= STATE_FETCH_OP_0;
        end
      STATE_DEBUG:
        begin
          state <= STATE_DEBUG;
        end
      STATE_ERROR:
        begin
          state <= STATE_ERROR;
        end
      STATE_HALTED:
        begin
          state <= STATE_HALTED;
        end
    endcase
end

memory_bus memory_bus_0(
  .address      (mem_address),
  .data_in      (mem_write),
  .write_mask   (mem_write_mask),
  .data_out     (mem_read),
  //.debug        (mem_debug),
  //.data_ready   (mem_data_ready),
  .bus_enable   (mem_bus_enable),
  .write_enable (mem_write_enable),
  .clk          (clk),
  .raw_clk      (raw_clk),
  .speaker_p    (speaker_p),
  .speaker_m    (speaker_m),
  .ioport_0     (ioport_0),
  .ioport_1     (ioport_1),
  .ioport_2     (ioport_2),
  .ioport_3     (ioport_3),
  .button_0     (button_0),
  .reset        (~button_reset),
  .spi_clk      (spi_clk),
  .spi_mosi     (spi_mosi),
  .spi_miso     (spi_miso)
);

alu alu_0(
  .source  (source),
  .arg_1   (arg_1),
  .alu_op  (alu_op),
  .is_alt  (is_alt),
  .result  (alu_result),
);

endmodule

