// Control unit for 6502-alike

module control(
    input clk1,
    input clk2,
    input reset,
    input irq,
    input nmi,

    input [15:0] pc,
    input [15:0] iaddr,
    input [7:0] idata,
    input [7:0] reg1,
    input [7:0] reg2,
    input [7:0] alu_result,
    input alu_c,
    input alu_z,
    input alu_v,
    input alu_n,
    output reg alu_cin,

    output reg [15:0] addr,
    output wire [7:0] odata,
    output wire [7:0] rdata,
    output reg [2:0] alu_op,
    output reg [3:0] rdreg1,
    output reg [3:0] rdreg2,
    output reg [3:0] wrreg,

    output reg rw,
    output reg regwren,
    output reg incr_pc);

`include "cpu6502/alu.vh"
`include "cpu6502/regfile.vh"
reg [7:0] state = 0;   // current cpu state
reg [7:0] flags = 0;   // cpu flags
localparam FLAG_C = 0;
localparam FLAG_Z = 1;
localparam FLAG_I = 2;
localparam FLAG_D = 3;
localparam FLAG_V = 6;
localparam FLAG_N = 7;

reg [1:0] flatch = 0; // What to latch into flags
localparam FL_NONE  = 2'b00;
localparam FL_ALU   = 2'b01;
localparam FL_RDATA = 2'b10;
localparam FL_BIT   = 2'b11;

reg [7:0] full_opcode;
wire [2:0] opcode;
wire [2:0] amode;
wire [1:0] itype;
assign opcode = full_opcode[7:5];
assign amode = full_opcode[4:2];
assign itype = full_opcode[1:0];
reg [15:0] next_pc = 0; // next PC for branch/jump instructions.

reg [15:0] cycle = 0;   // cycle counter
reg rsel = 0;           // rdata mux
reg [1:0] osel = 0;     // odata mux
reg acarry = 0;         // alu carry from last address computation

localparam RSEL_IDATA = 0;
localparam RSEL_ALU = 1;
localparam OSEL_Z = 0;
localparam OSEL_REG = 1;
localparam OSEL_FLAGS = 2;

localparam RESET_0 =   8'h0;
localparam RESET_1 =   8'h1;
localparam RESET_PCL = 8'h2;
localparam RESET_PCH = 8'h3;
localparam FETCH_I =   8'h4;
localparam RMW_MODIFY =8'h5;
localparam RMW_WRITE  =8'h6;

parameter RELATIVE_0   = 8'h10;
parameter RELATIVE_1   = 8'h11;
parameter RELATIVE_2   = 8'h12;
parameter JSR_0        = 8'h20;

parameter IMPLIED   = 8'h70;
parameter PUSH_0    = 8'h72;
parameter PUSH_1    = 8'h73;
parameter PULL_0    = 8'h78;
parameter PULL_1    = 8'h79;
parameter PULL_2    = 8'h7a;

parameter IMMEDIATE = 8'h80;
parameter ZP_ADDR_0   = 8'h90;
parameter ZP_ADDR_1   = 8'h91;

parameter IX_ADDR_0   = 8'ha0;
parameter IX_ADDR_1   = 8'ha1;
parameter IX_ADDR_2   = 8'ha2;
parameter IX_ADDR_3   = 8'ha3;
parameter IX_ADDR_4   = 8'ha4;

parameter ABS_ADDR_0  = 8'hb0;
parameter ABS_ADDR_1  = 8'hb1;
parameter ABS_ADDR_2  = 8'hb2;

parameter IY_ADDR_0   = 8'hc0;
parameter IY_ADDR_1   = 8'hc1;
parameter IY_ADDR_2   = 8'hc2;
parameter IY_ADDR_3   = 8'hc3;
parameter IY_ADDR_4   = 8'hc4;

parameter ZPX_ADDR_0  = 8'hd0;
parameter ZPX_ADDR_1  = 8'hd1;
parameter ZPX_ADDR_2  = 8'hd2;

parameter ABSY_ADDR_0 = 8'he0;
parameter ABSY_ADDR_1 = 8'he1;
parameter ABSY_ADDR_2 = 8'he2;
parameter ABSY_ADDR_3 = 8'he3;

parameter ABSX_ADDR_0 = 8'hf0;
parameter ABSX_ADDR_1 = 8'hf1;
parameter ABSX_ADDR_2 = 8'hf2;
parameter ABSX_ADDR_3 = 8'hf3;

always @(posedge reset)
begin
    state <= RESET_0;
end

// Rising edge of clk1 is when addresses are driven
always @(posedge clk1)
begin
    incr_pc <= 0;
    osel <= OSEL_Z;
    flatch <= FL_NONE;
    if (reset)
    begin
        //state <= RESET_0;
    end
    else
    begin
        cycle = cycle + 1;
        case(state)
            RESET_0:
            begin
                rw <= 1;
                state <= RESET_1;
                cycle <= 0;
            end

            RESET_PCL:
                addr <= 16'hFFFC;
            RESET_PCH:
                addr <= 16'hFFFD;
            FETCH_I:
                addr <= pc;

            IMMEDIATE,      // Address of immediate operand
            ZP_ADDR_0,      // Address of zero-page addr operand
            ZPX_ADDR_0,     // Address of zero-page addr operand
            ABS_ADDR_0,     // Address of absaddr low byte
            ABS_ADDR_1,     // Address of absaddr high byte
            ABSX_ADDR_0,    // Address of absaddr low byte
            ABSX_ADDR_1,    // Address of absaddr high byte
            ABSY_ADDR_0,    // Address of absaddr low byte
            ABSY_ADDR_1,    // Address of absaddr high byte
            IX_ADDR_0,      // ZP address
            IY_ADDR_0:      // ZP address
                addr <= pc;
            ZP_ADDR_1, // Address fetched in prior state
            ZPX_ADDR_2: // Address computed in prior state
                addr <= {8'b0, reg1};
            ABS_ADDR_2,
            ABSX_ADDR_3,
            ABSY_ADDR_3,
            IX_ADDR_4,
            IY_ADDR_4:
                addr <= iaddr;

            IX_ADDR_2,
            IY_ADDR_1:
                addr <= {8'b0, reg1};
            IX_ADDR_3,
            IY_ADDR_2:
                addr <= {8'b0, reg1 + 8'h01};
            PUSH_0,         // Stack operations
            PULL_1:
                addr <= {8'b00000001, reg1};
        endcase
    end
end

// Data we drive to the register file is muxed on rsel.
assign rdata = rsel == RSEL_IDATA ? idata :
               rsel == RSEL_ALU ? alu_result : 8'bz;
// Data driven to output comes from register file.
assign odata = osel ? reg1 : 8'bz;

// Falling edge of clk2 is when registers get latched.
always @(negedge clk2)
begin
    // Latch into register file.
    regwren <= 0;
    rw <= 1;
    acarry <= alu_c;
    case(flatch)
        FL_RDATA:
        begin
            flags[FLAG_N] <= rdata[7];
            flags[FLAG_Z] <= ~|rdata;
        end
        FL_ALU:
        begin
            case (alu_op)
                ALU_OR,
                ALU_AND,
                ALU_EOR:
                    {flags[FLAG_N], flags[FLAG_Z]} <= {alu_n, alu_z};
                ALU_SHL,
                ALU_SHR,
                ALU_CMP:
                    {flags[FLAG_N], flags[FLAG_Z], flags[FLAG_C]}
                        <= {alu_n, alu_z, alu_c};
                ALU_ADC,
                ALU_SBC:
                    {flags[FLAG_N], flags[FLAG_V], flags[FLAG_Z], flags[FLAG_C]}
                        <= {alu_n, alu_v, alu_z, alu_c};
            endcase
        end
        FL_BIT:
        begin
            flags[FLAG_N] <= rdata[7];
            flags[FLAG_V] <= rdata[6];
            flags[FLAG_Z] <= alu_z;
        end
        FL_NONE:
            ;
    endcase
    case(state)
        IY_ADDR_1, // Setup reg_t for next address phase
        IY_ADDR_2:
            rdreg1 <= REG_T;
        RELATIVE_2:     // If we don't need to work on PCH, skip to fetch.
            if (alu_c == reg2[7])
                state <= FETCH_I;
    endcase

end

// clk2 is when instructions get executed
always @(posedge clk2)
begin
if (reset)
begin
end
else
begin
    case(state)
        RESET_1:
            state <= RESET_PCL;
        RESET_PCL:
        begin
            rsel <= RSEL_IDATA;
            wrreg <= REG_PCL;
            regwren <= 1;
            state <= RESET_PCH;
        end
        RESET_PCH:
        begin
            rsel <= RSEL_IDATA;
            wrreg <= REG_PCH;
            regwren <= 1;
            state <= FETCH_I;
        end

        FETCH_I: // Instruction fetch and decode
        begin
            case (idata)
                8'h0A,  // ASL A;
                8'h2A,  // ROL A;
                8'h4A,  // LSR A;
                8'h6A,  // ROR A;
                8'h8A,  // TXA;
                8'h9A,  // TXS;
                8'hAA,  // TAX;
                8'hBA,  // TSX;
                8'hCA,  // DEX;
                8'hEA,  // NOP;
                8'h88,  // DEY;
                8'hA8,  // TAY;
                8'hC8,  // INY;
                8'hE8,  // INX;
                8'h18,  // CLC;
                8'h38,  // SEC;
                8'h58,  // CLI;
                8'h78,  // SEI;
                8'h88,  // TYA;
                8'hB8,  // CLV;
                8'hD8,  // CLD;
                8'hF8,  // SED;
                8'h40,  // RTI
                8'h60:  // RTS
                begin
                    full_opcode <= idata;
                    state <= IMPLIED;
                end

                8'h08,  // PHP
                8'h48:  // PHA
                begin
                    full_opcode <= idata;
                    state <= PUSH_0;
                end
                8'h28,  // PLP
                8'h68:  // PLA
                begin
                    full_opcode <= idata;
                    state <= PULL_0;
                end

                8'h10,  // BPL
                8'h30,  // BMI
                8'h50,  // BVC
                8'h70,  // BVS
                8'h90,  // BCC
                8'hb0,  // BCS
                8'hd0,  // BNE
                8'hf0:  // BEQ
                begin
                    full_opcode <= idata;
                    state <= RELATIVE_0;
                end
                8'h20:  // JSR abs
                begin
                    full_opcode <= idata;
                    state <= JSR_0;
                end

            default:
            begin
                // Flip IX and IMM modes on itype==1 instructions so the
                // IMM state is consistent across all instructions
                if (idata[4:0] == 5'b00001)
                begin
                    full_opcode <= {idata[7:5], 5'b01001};
                    state <= IX_ADDR_0;
                end
                else if (idata[4:0] == 5'b01001)
                begin
                    full_opcode <= {idata[7:5], 5'b00001};
                    state <= IMMEDIATE;
                end
                else
                begin
                    full_opcode <= idata;
                    state <= {1'b1, idata[4:2], 4'b0000};
                end
            end
            endcase
            incr_pc <= 1;
        end

        IMPLIED:
        begin
            case(full_opcode)
                8'h0A,  // ASL
                8'h2A,  // ROL
                8'h4A,  // LSR
                8'h6A:  // ROR
                begin
                    rdreg1 <= REG_A;
                    wrreg <= REG_A;
                    rsel <= RSEL_ALU;
                    regwren <= 1;
                    flatch <= FL_ALU;
                    // Carry in depeding on rotate or shift.
                    alu_cin <= opcode[0] ? flags[FLAG_C] : 0;
                    // shift direction based on opcode.
                    alu_op <= opcode[1] ? ALU_SHR : ALU_SHL;
                end

                8'h18,  // CLC
                8'h38:  // SEC
                    flags[FLAG_C] <= full_opcode[5];
                8'h58,  // CLI
                8'h78:  // SEI
                    flags[FLAG_I] <= full_opcode[5];
                8'hB8:  // CLV
                    flags[FLAG_V] <= 0;
                8'hD8,  // CLD
                8'hF8:  // SED
                    flags[FLAG_D] <= full_opcode[5];
                8'hEA:  // NOP
                    ;
                8'hAA,  // TAX
                8'h8A,  // TXA
                8'h9A,  // TXS
                8'hBA,  // TSX
                8'hA8,  // TAY
                8'h98:  // TYA
                begin
                    rdreg1 <= full_opcode == 8'hAA ? REG_A :
                              full_opcode == 8'hA8 ? REG_A :
                              full_opcode == 8'h8A ? REG_X :
                              full_opcode == 8'h9A ? REG_X :
                              full_opcode == 8'hBA ? REG_SP :
                              full_opcode == 8'h98 ? REG_Y : REG_A;
                    rdreg2 <= REG_ZERO;
                    wrreg <= full_opcode == 8'hAA ? REG_X :
                             full_opcode == 8'hA8 ? REG_Y :
                             full_opcode == 8'h8A ? REG_A :
                             full_opcode == 8'h9A ? REG_SP :
                             full_opcode == 8'hBA ? REG_X :
                             full_opcode == 8'h98 ? REG_A : REG_A;
                    rsel <= RSEL_ALU;
                    regwren <= 1;
                    alu_cin <= 0;
                    alu_op <= ALU_ADC;
                end

                8'hC8,  // INY
                8'hE8,  // INX
                8'h88,  // DEY
                8'hCA:  // DEX
                begin
                    rdreg1 = full_opcode == 8'hC8 ? REG_X :
                           full_opcode == 8'hE8 ? REG_X :
                           full_opcode == 8'h88 ? REG_Y :
                           full_opcode == 8'hCA ? REG_Y : REG_Y;
                    rdreg2 <= REG_ZERO;
                    wrreg  <= rdreg1;
                    rsel <= RSEL_ALU;
                    regwren <= 1;
                    alu_cin = full_opcode == 8'hC8 || full_opcode == 8'hE8;
                    alu_op <= alu_cin ? ALU_ADC : ALU_SBC;
                    flatch <= FL_RDATA;
                end

            endcase
            state <= FETCH_I;
        end

        IMMEDIATE,      // Fetch immediate operand and alu op
        ZP_ADDR_1,      // Fetch data and alu op
        ZPX_ADDR_2,     // Fetch data and alu op
        ABS_ADDR_2,     // Fetch data and alu op
        ABSX_ADDR_3,    // Fetch data and alu op
        ABSY_ADDR_3,    // Fetch data and alu op
        IX_ADDR_4,      // Fetch data and alu op
        IY_ADDR_4:      // Fetch data and alu op
        begin
            case(itype)
                // Type 01 are all aluop with operand.
                2'b01:
                begin
                    case(opcode)
                        3'b000,  // ORA
                        3'b001,  // AND
                        3'b010,  // EOR
                        3'b011,  // ADC
                        3'b110,  // CMP
                        3'b111:  // SBC
                        begin
                            rdreg1 <= REG_A;
                            rdreg2 <= REG_DB;
                            wrreg <= REG_A;
                            rsel <= RSEL_ALU;
                            // CMP is a subtract, but carry_in=1 and we don't
                            // keep the result.
                            alu_op <=  opcode;
                            alu_cin <= opcode == 3'b110 ? 1 : flags[FLAG_C];
                            regwren <= opcode == 3'b110 ? 0 : 1;
                            flatch <= FL_ALU;
                        end
                        3'b100:  // STA
                        begin
                            rdreg1 <= REG_A;
                            osel <= OSEL_REG;
                            rw <= 0;
                        end
                        3'b101:  // LDA
                        begin
                            wrreg <= REG_A;
                            rsel <= RSEL_IDATA;
                            flatch <= FL_RDATA;
                            regwren <= 1;
                        end
                    endcase
                    state <= FETCH_I;
                end
                // Type 10 are all RMW except LDX/STX and accumulator modes
                // for shifts.  Accumulator modes are decoded as IMPLIED.
                2'b10:
                begin
                    case(opcode)
                        3'b100:     // STX
                        begin
                            rdreg1 <= REG_X;
                            osel <= OSEL_REG;
                            rw <= 0;
                            state <= FETCH_I;
                        end
                        default:
                        begin
                            // If LDX, then use X and latch rdata, otherwise
                            // load into T.
                            wrreg <= opcode == 3'b101 ? REG_X : REG_T;
                            flatch <= opcode == 3'b101 ? FL_RDATA : FL_NONE;
                            rsel <= RSEL_IDATA;
                            regwren <= 1;
                            state <= opcode == 3'b101 ? FETCH_I : RMW_MODIFY;
                        end
                    endcase
                end
                2'b00:
                begin
                    case(opcode)
                        3'b001:     // BIT
                        begin
                            rdreg1 <= REG_A;
                            rdreg2 <= REG_DB;
                            alu_op <=  ALU_AND;
                            flatch <= FL_BIT;
                        end
                        3'b100:     // STY
                        begin
                            rdreg1 <= REG_Y;
                            osel <= OSEL_REG;
                            rw <= 0;
                            state <= FETCH_I;
                        end
                        3'b101:     // LDY
                        begin
                            wrreg <= REG_Y;
                            flatch <= FL_RDATA;
                            rsel <= RSEL_IDATA;
                            regwren <= 1;
                            state <= FETCH_I;
                        end
                        3'b110,     // CPX
                        3'b111:     // CPX
                        begin
                            rdreg1 <= opcode[0] ? REG_X : REG_Y;
                            rdreg2 <= REG_DB;
                            // CMP is a subtract with carry_in=1 and we don't
                            // keep the result.
                            alu_op <=  ALU_CMP;
                            alu_cin <= 1;
                            regwren <= 0;
                            flatch <= FL_ALU;
                        end
                        default:
                        begin
                            $stop;
                        end
                    endcase
                end
            endcase
            incr_pc <= state == IMMEDIATE ? 1 : 0;
        end

        RMW_MODIFY:
        begin
            case(itype)
                2'b10:
                begin
                    // Operate on register T, store result back in T.
                    // Update flags based on alu result.
                    rdreg1 <= REG_T;
                    rdreg2 <= REG_ZERO;
                    wrreg <= REG_T;
                    rsel <= RSEL_ALU;
                    regwren <= 1;
                    case(opcode)
                        3'b000,  // ASL
                        3'b001,  // ROL
                        3'b010,  // LSR
                        3'b011:  // ROR
                        begin
                            // Carry in depeding on rotate or shift.
                            alu_cin <= opcode[0] ? flags[FLAG_C] : 0;
                            // shift direction based on opcode.
                            alu_op <= opcode[1] ? ALU_SHR : ALU_SHL;
                            flatch <= FL_ALU;
                        end

                        3'b110,  // DEC
                        3'b111:  // INC
                        begin
                            alu_op <= opcode[0] ? ALU_ADC : ALU_SBC;
                            alu_cin <= opcode[0] ? 1 : 0;
                            flatch <= FL_RDATA;
                        end
                    endcase
                end
            endcase
            state <= RMW_WRITE;
        end

        RMW_WRITE:
        begin
            case(itype)
                2'b10:
                begin
                    // Write T back to memory.
                    rdreg1 <= REG_T;
                    osel <= OSEL_REG;
                    rw <= 0;
                end
            endcase
            state <= FETCH_I;
        end

        ZP_ADDR_0,  // Fetch zero page address
        ZPX_ADDR_0, // Fetch zero page address
        ABS_ADDR_0, // Fetch abs addr low byte
        ABS_ADDR_1: // Fetch abs addr high byte
        begin
            wrreg <= state[0] ? REG_IH: REG_IL;
            rdreg1 <= REG_IL;
            rdreg2 <= REG_IH;
            rsel <= RSEL_IDATA;
            regwren <= 1;
            state <= state + 1;
            incr_pc <= 1;
        end

        ZPX_ADDR_1: // Add Xreg + IL
        begin
            // Its always ZP,x except LDX & LDY, which are ZP,y.
            rdreg1 <= REG_IL;
            rdreg2 <= (full_opcode == 8'h96 || full_opcode == 8'hb6) ? REG_Y
                                                                     : REG_X;
            wrreg <= REG_IL;
            rsel <= RSEL_ALU;
            alu_op <= ALU_ADC;
            alu_cin <= 0;
            regwren <= 1;
            state <= state + 1;
        end

        ABSX_ADDR_0, // Fetch abs addr low byte and add reg
        ABSX_ADDR_1, // Fetch abs addr high byte
        ABSY_ADDR_0, // Fetch abs addr low byte and add reg
        ABSY_ADDR_1: // Fetch abs addr high byte
        begin
            // state[0] tells us whether we're on low(0) or high(1) byte
            // state[4] tells us whether its ABSX(0) or ABSY(1)
            rdreg1 <= state[0] ? REG_ZERO :
                      state[4] ? REG_X : REG_Y;
            rdreg2 <= REG_DB;
            wrreg <= state[0] ? REG_IH : REG_IL;
            rsel <= RSEL_ALU;
            alu_op <= ALU_ADC;
            alu_cin <= state[0] ? acarry : 0;
            regwren <= 1;
            // In the _0 state, advance to the next state.
            // In the _1 state, stall 1 state if there was a carry.
            state <= state + (state[0]
                  ? ((acarry || 
                      full_opcode == 8'h9d ||
                      full_opcode == 8'h99) ? 1 : 2)
                  : 1);
            incr_pc <= 1;
        end

        ABSX_ADDR_2,    // stall state
        ABSY_ADDR_2,    // stall state
        IY_ADDR_3:      // stall state
            state <= state + 1;

        IX_ADDR_0,  // Fetch zp addr byte into T
        IY_ADDR_0:  // Fetch zp addr byte into T
        begin
            wrreg <= REG_T;
            rdreg1 <= REG_T;
            rsel <= RSEL_IDATA;
            regwren <= 1;
            state <= state + 1;
            incr_pc <= 1;
        end

        IX_ADDR_1:
        begin
            wrreg <= REG_T;
            rdreg1 <= REG_T;
            rdreg2 <= REG_X;
            rsel <= RSEL_ALU;
            alu_op <= ALU_ADC;
            alu_cin <= 0;
            regwren <= 1;
            state <= state + 1;
        end

        IX_ADDR_2,
        IX_ADDR_3:
        begin
            wrreg <= state[0] ? REG_IH : REG_IL;
            rsel <= RSEL_IDATA;
            regwren <= 1;
            state <= state + 1;
        end

        IY_ADDR_1, // Fetch abs addr low byte
        IY_ADDR_2: // Fetch abs addr high byte
        begin
            // state[0] tells us whether we're on low(1) or high(0) byte
            rdreg1 <= state[0] ? REG_Y : REG_ZERO;
            rdreg2 <= REG_DB;
            wrreg <=  state[0] ? REG_IL : REG_IH;
            rsel <= RSEL_ALU;
            alu_op <= ALU_ADC;
            alu_cin <= state[0] ? 0 : acarry;
            regwren <= 1;
            // In the _1 state, advance to the next state.
            // In the _2 state, stall 1 state if there was a carry.
            state <= state + (state[0]
                  ? 1
                  : ((acarry) ? 1 : 2));
        end

        PUSH_0:     // Store register value to memory
        begin
            rdreg1 <= REG_A;
            rdreg2 <= REG_SP;
            osel <= full_opcode[6] ? OSEL_REG : OSEL_FLAGS;
            rw <= 0;
            state <= state + 1;
        end

        PUSH_1:     // Decrement SP
        begin
            rdreg1 <= REG_SP;
            rdreg2 <= REG_ZERO;
            wrreg  <= REG_SP;
            rsel <= RSEL_ALU;
            regwren <= 1;
            alu_cin = 0;
            alu_op <= ALU_SBC;
            state <= FETCH_I;
        end
        PULL_0:     // Increment SP
        begin
            rdreg1 <= REG_SP;
            rdreg2 <= REG_ZERO;
            wrreg  <= REG_SP;
            rsel <= RSEL_ALU;
            regwren <= 1;
            alu_cin = 1;
            alu_op <= ALU_ADC;
            state <= state + 1;
        end
        PULL_1:     // Store memory value to register
        begin
            if (full_opcode == 8'h28)
            begin
                // PLP
                flags <= idata;
            end
            else
            begin
                wrreg <= REG_A;
                rsel <= RSEL_IDATA;
                regwren <= 1;
            end
            state <= state + 1;
        end
        PULL_2:     // Do nothing state
            state <= FETCH_I;

        RELATIVE_0:     // Take a branch or not. Capture displacement into T.
        begin
            state <=
              (opcode[0] == flags[opcode[2:1] == 2'b11 ? FLAG_Z :
                                  opcode[2:1] == 2'b10 ? FLAG_C :
                                  opcode[2:1] == 2'b01 ? FLAG_V : FLAG_N])
                ? RELATIVE_1 : FETCH_I;
            rdreg1 <= REG_T;
            wrreg <= REG_T;
            rsel <= RSEL_IDATA;
            regwren <= 1;
            incr_pc <= 1;
        end
        RELATIVE_1:
        begin
            rdreg1 <= REG_PCL;
            rdreg2 <= REG_T;
            wrreg  <= REG_PCL;
            rsel <= RSEL_ALU;
            regwren <= 1;
            alu_cin <= 0;
            alu_op <= ALU_ADC;
            state <= state + 1;
        end
        RELATIVE_2:
        begin
            rdreg1 <= REG_PCH;
            rdreg2 <= REG_ZERO;
            wrreg  <= REG_PCH;
            rsel <= RSEL_ALU;
            regwren <= 1;
            alu_cin <= alu_c;
            alu_op <= reg2[7] ? ALU_SBC : ALU_ADC;
            state <= FETCH_I;
        end


    endcase
end
end

endmodule
