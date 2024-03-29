module vdc(
    input clk,
    input phi2,
    input reset,
    input vram_cs,
    input vreg_cs,
    input [11:0] addr,
    input rw,
    input [7:0] idata,
    output [7:0] odata,
    output [3:0] vga_r,
    output [3:0] vga_g,
    output [3:0] vga_b,
    output vga_hs,
    output vga_vs,
    output [7:0] led);

wire [11:0] vga_addr;   // VGA requested address
wire [7:0] rdata;       // Register file read data
wire [7:0] vdata;       // VRAM read data for vga
wire [3:0] color;       // VGA color selection

wire [1:0] sel;
assign sel = {vram_cs, vreg_cs};

assign odata = rdata;
//assign odata = (sel == 2'b01) ? rdata : 
//               (sel == 2'b10) ? vdata : 8'bz;

vreg vreg0(
    .clk(clk),
    .address(addr[5:0]),
    .wdata(idata),
    .color(color),
    .rw(rw),
    .ce(vreg_cs),
    .rdata(rdata),
    .cdata({vga_r, vga_g, vga_b}),
    .led(led));

vga vga0(
    .CLK12MHz(clk),
    .phi2(phi2),
    .reset(reset),
    .rw(rw),
    .ce(vram_cs),
    .idata(idata),
    .addr(addr),
    .odata(rdata),
    .color(color),
    .hsync(vga_hs),
    .vsync(vga_vs));

endmodule
