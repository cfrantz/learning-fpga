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
    output [7:0] leds);

reg [7:0] counter = 0;
reg [1:0] arb;
reg cpu;

// Arbitrate who talks to VRAM:
// clk | phi2 | who
// ----|------|----------
//   0 |    0 | vga
//   1 |    0 | cpu
//   2 |    1 | cpu
//   3 |    0 | vga

always @(posedge clk)
begin
    if (reset)
        arb <= 2'b11;
    else if (phi2)
        arb[1:0] <= 2'b10;
    else
        arb <= arb + 1;

    cpu <= (arb == 2'b00 || arb == 2'b01);
end

always @(posedge vga_vs)
    counter <= counter + 1;
    
wire [15:0] vramstart;  // Vram start relative to beginning of VRAM
wire [15:0] cramstart;  // CHR RAM start relative to beginning of VRAM
wire [11:0] vga_addr;   // VGA requested address
wire [7:0] rdata;       // Register file read data
wire [7:0] vdata;       // VRAM read data for vga
wire [3:0] color;       // VGA color selection

assign leds = counter;
assign odata = vreg_cs ? rdata :
               vram_cs ? vdata : 8'bz;

vreg vreg0(
    .clk(clk),
    .address(addr[5:0]),
    .wdata(idata),
    .color(color),
    .rw(rw),
    .ce(vreg_cs),
    .rdata(rdata),
    .cdata({vga_r, vga_g, vga_b}),
    .vramstart(vramstart),
    .cramstart(cramstart));

vga vga0(
    .CLK12MHz(clk),
    .phi2(phi2),
    .reset(reset),
    .rw(rw),
    .ce(vram_cs),
    .idata(idata),
    .addr(addr),
    .odata(vdata),
    .color(color),
    .hsync(vga_hs),
    .vsync(vga_vs));

endmodule
