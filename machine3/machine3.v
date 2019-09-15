module machine3(
    input hwclk,
    input ftdi_rx,
    output ftdi_tx,
    output [2:0] vga_r,
    output [2:0] vga_g,
    output [2:0] vga_b,
    output vga_hs,
    output vga_vs,
    output [7:0] led);

wire vgaclk2x;
reg vgaclk = 0;
reg reset = 1;
reg [31:0] counter = 0;
reg [7:0] ledreg = 0;

wire [23:0] vaddr;
wire [7:0] vdata;

wire [15:0] cpuaddr;
wire [19:0] addr;
wire [7:0] idata;
wire [7:0] ram_idata;
wire [7:0] odata;
wire rw;
wire nmi = 1;
wire irq = 1;
wire clk1;
wire clk2;
wire mmucs;
wire ramcs;

wire xr, xg, xb;

assign led = ~ledreg;

vgapll pll0(
    .clkin(hwclk),
    .clkout0(vgaclk2x));

// Reset circuit: hold in reset for 100 clocks.
always @(posedge vgaclk2x)
begin
    vgaclk <= ~vgaclk;
    counter <= counter + 1;
    if (reset == 1 && counter == 100)
        reset <= 0;

    if (addr == 20'hfb000 && rw == 0)
        ledreg <= odata;
end

cpu6502 cpu(
    .clk4x(hwclk),
    .reset(reset),
    .irq(irq),
    .nmi(nmi),
    .addr(cpuaddr),
    .idata(idata),
    .odata(odata),
    .rw(rw),
    .clk1(clk1),
    .clk2(clk2));

// MMU is always at cpu address $FFE0 - $FFEF.
assign mmucs = (cpuaddr[15:4] == 12'b1111_1111_1110);
mapper mmu0(
    .clk(hwclk),
    .cpuaddr(cpuaddr),
    .wdata(odata),
    .rw(rw),
    .cs(mmucs),
    .rdata(idata),
    .address(addr));

dual_port_ram ram0(
    .clk2x(vgaclk2x),
    // The CPU is on the A side of the RAM.
    .addr_a(addr[16:0]),
    .wdata_a(odata),
    .rdata_a(idata),
    .cs_a(addr[19:17] == 3'b000),
    .rw_a(rw),


    // The Video Controller is on the B side of the RAM.
    .addr_b(vaddr[16:0]),
    .rdata_b(vdata),
    .cs_b(1'b1),
    .rw_b(1'b1)
);

/*
// The ROM monitor is located at $F000-$FFFF
ewoz_ram monitor(
    .clk(hwclk),
    .address(addr[11:0]),
    .wdata(odata),
    .rw(rw),
    .ce(addr[19:12] == 8'b1111_1111 && ~mmucs),
    .rdata(idata));
*/

basic_rom rom0(
    .clk(hwclk),
    .address(addr[13:0]),
    .wdata(odata),
    .rw(rw),
    .ce(addr[19:14] == 8'b1111_11 && ~mmucs),
    .rdata(idata));

// The Serial port is located at $FB000-$FB003
uart serial_port(
    .clk(hwclk),
    .rst(reset),
    .rx_line(ftdi_rx),
    .tx_line(ftdi_tx),
    .cs(addr[19:2] == 18'b1111_1011_0000_0000_00),
    .addr(addr[1:0]),
    .rw(rw),
    .idata(odata),
    .odata(idata));

// The VDC regs are ampped at $FB100 - $FB13F.
vdc vdc0(
    .clk(vgaclk),
    .reset(reset),
    .vreg_cs(addr[19:8] == 12'b1111_1011_0001),
    .rw(rw),
    .addr(addr[5:0]),
    .idata(odata),
    .odata(idata),
    .vaddr(vaddr),
    .vdata(vdata),
    .vga_r({vga_r, xr}),
    .vga_g({vga_g, xg}),
    .vga_b({vga_b, xb}),
    .vga_hs(vga_hs),
    .vga_vs(vga_vs));

endmodule
