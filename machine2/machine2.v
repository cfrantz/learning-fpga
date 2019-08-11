module machine2(
    input hwclk,
    input ftdi_rx,
    output ftdi_tx,
    output [2:0] vga_r,
    output [2:0] vga_g,
    output [2:0] vga_b,
    output vga_hs,
    output vga_vs,
    output [7:0] led);

reg reset = 1;
reg [31:0] counter = 0;
reg [7:0] ledreg = 0;

wire [15:0] addr;
wire [7:0] idata;
wire [7:0] odata;
wire rw;
wire nmi = 1;
wire irq = 1;
wire clk1;
wire clk2;

wire xr, xg, xb;

// Reset circuit: hold in reset for 100 clocks.
always @(posedge hwclk)
begin
    counter <= counter + 1;
    if (reset == 1 && counter == 100)
        reset <= 0;
    if (addr == 16'hc004 && !rw)
        ledreg <= odata;
end

cpu6502 cpu(
    .clk4x(hwclk),
    .reset(reset),
    .irq(irq),
    .nmi(nmi),
    .addr(addr),
    .idata(idata),
    .odata(odata),
    .rw(rw),
    .clk1(clk1),
    .clk2(clk2));

// RAM bank0 is located at $0000-$0FFF
ram bank0(
    .clk(hwclk),
    .address(addr[11:0]),
    .wdata(odata),
    .rw(rw),
    .ce(addr[15:12] == 0),
    .rdata(idata));

// The ROM monitor is located at $F000-$FFFF
ewoz_ram monitor(
    .clk(hwclk),
    .address(addr[11:0]),
    .wdata(odata),
    .rw(rw),
    .ce(addr[15:12] == 4'b1111),
    .rdata(idata));

// The Serial port is located at $C000-$C003
uart serial_port(
    .clk(hwclk),
    .rst(reset),
    .rx_line(ftdi_rx),
    .tx_line(ftdi_tx),
    .cs(addr[15:2] == 14'b1100_0000_0000_00),
    .addr(addr[1:0]),
    .rw(rw),
    .idata(odata),
    .odata(idata));

vdc vdc0(
    .clk(hwclk),
    .phi2(clk2),
    .reset(reset),
    .vram_cs(addr[15:12] == 4'b1010),
    .vreg_cs(addr[15:8] == 8'b1100_0001),
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
