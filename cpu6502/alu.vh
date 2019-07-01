// Arranged so that ALU ops match instruction encoding for itype=01
// instructions.  Shifts are part of itype=10 instructions and the instruction
// encodings don't match.
localparam ALU_OR = 3'b000;
localparam ALU_AND = 3'b001;
localparam ALU_EOR = 3'b010;
localparam ALU_ADC = 3'b011;
localparam ALU_SHL = 3'b100;
localparam ALU_SHR = 3'b101;
localparam ALU_CMP = 3'b110;
localparam ALU_SBC = 3'b111;
