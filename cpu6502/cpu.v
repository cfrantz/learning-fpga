module cpu6502(
    input clk4x,
    input reset,
    input irq,
    input nmi,

    output [15:0] addr,
    input [7:0] idata,
    output [7:0] odata,
    output rw,
    output clk1,
    output clk2);

wire [3:0] rdreg1, rdreg2, wrreg;
wire [7:0] regout1, regout2, regdata, alu_out;
wire alu_cin, alu_c, alu_z, alu_v, alu_n;
wire [2:0] alu_op;
wire regwren, tpcl, incr_pc;
wire [15:0] pc, iaddr;
wire subreset;

regfile reg0(
    .clk(clk2),
    .reset(subreset),
    .rdsel1(rdreg1),
    .rdsel2(rdreg2),
    .wrenable(regwren),
    .wrsel(wrreg),
    .data(regdata),
    .dbus(idata),
    .tpcl(tpcl),
    .incr_pc(incr_pc),
    .read1(regout1),
    .read2(regout2),
    .pc(pc),
    .iaddr(iaddr));

alu alu0(
    .clk(clk2),
    .op(alu_op),
    .a(regout1),
    .b(regout2),
    .c_in(alu_cin),
    .result(alu_out),
    .c_out(alu_c),
    .z_out(alu_z),
    .v_out(alu_v),
    .n_out(alu_n));

control control0(
    .clk4x(clk4x),
    .clk1(clk1),
    .clk2(clk2),
    .reset(reset), .subreset(subreset), .irq(irq), .nmi(nmi),
    .pc(pc),
    .iaddr(iaddr),
    .idata(idata),
    .reg1(regout1),
    .reg2(regout2),
    .alu_result(alu_out),
    .alu_c(alu_c), .alu_z(alu_z), .alu_v(alu_v), .alu_n(alu_n),
    .alu_cin(alu_cin),
    .addr(addr),
    .odata(odata),
    .rdata(regdata),
    .alu_op(alu_op), 
    .rdreg1(rdreg1),
    .rdreg2(rdreg2),
    .wrreg(wrreg),
    .rw(rw),
    .regwren(regwren),
    .tpcl(tpcl),
    .incr_pc(incr_pc));
endmodule
