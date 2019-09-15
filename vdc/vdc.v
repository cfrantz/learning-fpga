module vdc(
    input clk,
    input reset,
    input vreg_cs,
    input rw,
    input [5:0] addr,
    input [7:0] idata,
    output [7:0] odata,

    output [23:0] vaddr,
    input [7:0] vdata,
    output [3:0] vga_r,
    output [3:0] vga_g,
    output [3:0] vga_b,
    output vga_hs,
    output vga_vs);

wire [3:0] color;       // VGA color selection
wire [23:0] vramstart;
wire [23:0] cramstart;


vreg vreg0(
    .clk(clk),
    .address(addr[5:0]),
    .vramstart(vramstart),
    .cramstart(cramstart),
    .wdata(idata),
    .color(color),
    .rw(rw),
    .ce(vreg_cs),
    .rdata(odata),
    .cdata({vga_r, vga_g, vga_b}));

vga vga0(
    .vga_clk(clk),
    .reset(reset),
    .vramstart(vramstart),
    .cramstart(cramstart),
    .vdata(vdata),
    .vaddr(vaddr),
    .color(color),
    .hsync(vga_hs),
    .vsync(vga_vs));

endmodule
