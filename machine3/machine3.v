module machine3(
    input hwclk,
    input ftdi_rx,
    output ftdi_tx,
    output [2:0] vga_r,
    output [2:0] vga_g,
    output [2:0] vga_b,
    output vga_hs,
    output vga_vs,
    inout [7:0] extdata,
    output [16:0] extaddr,
    output extram_cs,
    output extram_we,
    output extram_oe,
    output [7:0] led);

reg reset = 1;
reg [31:0] counter = 0;
reg [7:0] ledreg = 0;

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

// Reset circuit: hold in reset for 100 clocks.
always @(posedge hwclk)
begin
    counter <= counter + 1;
    if (reset == 1 && counter == 100)
        reset <= 0;
end

// Map the external RAM at address $00000 - $10000.
assign extaddr = addr[16:0];
assign ramcs = (addr[19:17] == 3'b000);
// All of these external signals are active low.
assign extram_cs = ~ramcs;
assign extram_we = rw;
assign extram_oe = ~rw;

// Assign output and inputs to the extdata bus.
assign extdata = (ramcs && ~rw) ? odata : 8'bz;
assign ram_idata = (ramcs && rw) ? extdata : 8'bz;

cpu6502 cpu(
    .clk4x(hwclk),
    .reset(reset),
    .irq(irq),
    .nmi(nmi),
    .addr(cpuaddr),
    .idata((ramcs && rw) ? ram_idata : idata),
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

// RAM bank0 is located at $FD000-$FDFFF
ram bank0(
    .clk(hwclk),
    .address(addr[11:0]),
    .wdata(odata),
    .rw(rw),
    .ce(addr[19:12] == 8'b1111_1101 && ~mmucs),
    .rdata(idata));

// The ROM monitor is located at $F000-$FFFF
ewoz_ram monitor(
    .clk(hwclk),
    .address(addr[11:0]),
    .wdata(odata),
    .rw(rw),
    .ce(addr[19:12] == 8'b1111_1111 && ~mmucs),
    .rdata(idata));

// The Serial port is located at $FC000-$FC003
uart serial_port(
    .clk(hwclk),
    .rst(reset),
    .rx_line(ftdi_rx),
    .tx_line(ftdi_tx),
    .cs(addr[19:2] == 18'b1111_1100_0000_0000_00),
    .addr(addr[1:0]),
    .rw(rw),
    .idata(odata),
    .odata(idata));

vdc vdc0(
    .clk(hwclk),
    .phi2(clk2),
    .reset(reset),
    .vram_cs(addr[19:12] == 8'b1111_1010),
    .vreg_cs(addr[19:8] == 12'b1111_1100_0001),
    .rw(rw),
    .addr(addr[11:0]),
    .idata(odata),
    .odata(idata),
    .vga_r({vga_r, xr}),
    .vga_g({vga_g, xg}),
    .vga_b({vga_b, xb}),
    .vga_hs(vga_hs),
    .vga_vs(vga_vs),
    .led(led));

endmodule
